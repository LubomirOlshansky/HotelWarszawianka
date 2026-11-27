extends "res://scripts/landmarks/centre.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, the Old Town and the Royal
## Route's north end: the Castle and Plac Zamkowy, the Rynek, the Barbican, the hotels, Krakowskie
## Przedmieście, Plac Bankowy, Plac Teatralny, Plac Krasińskich. Moved as it was from the one big
## file. landmarks.gd is the class the game makes; every file of game/scripts/landmarks/ is one link
## of its base chain (facade_kit.gd, common.gd, then the areas in the order of landmarks.gd's
## `extends` chain), so code here may use this file, common.gd and the facade kit, never another
## area: a helper two areas need goes to common.gd.


# --- the low-rise landmarks (the landmarks loop) -----------------------------------------------

const ZAMEK_STONE := Color("#e2d8c4")


# --- Kolumna Zygmunta (the landmarks loop, Old Town) ---------------------------------------------

## Sigismund's Column on Plac Zamkowy (1644, rebuilt 1949): OpenStreetMap maps it in a dozen
## tiny 3D parts the builder drops as specks, so the square had a dark cube. Built here: the
## stepped granite base, the pedestal, the 12 m shaft, the capital and the king in bronze with
## his cross raised and his sabre. A circle zone round it; the same on both city paths.
const ZYGMUNT := Vector2(-724.2, -1465.4)
const ZYGMUNT_GRANITE := Color("#a39e96")  # steps (photo report zygmunt.md)
const ZYGMUNT_STONE := Color("#9a9186")  # the shaft, grey-brown granite
const ZYGMUNT_PLINTH := Color("#77746f")  # the pedestal, dark grey granite
const ZYGMUNT_CAPITAL := Color("#4a443a")
const ZYGMUNT_BRONZE := Color("#4f4a40")
func _find_zygmunt() -> void:
	_add_site("zygmunt", [_circle(ZYGMUNT, 4.0, 16)])


func _build_zygmunt(_site: Dictionary) -> void:
	var c := ZYGMUNT
	_g = _ground_under(_circle(c, 3.4, 8))
	var g := _g
	var none := Color(0, 0, 0, 0)
	# Four broad low granite steps, the dark granite pedestal with bronze plaques, then the shaft
	# with its bronze ring and Corinthian capital and the square abacus (photo report zygmunt.md).
	for k in 4:
		_prism(_circle(c, 3.8 - k * 0.45, 8), g - 0.4 + k * 0.15, g + 0.15 + k * 0.15, ZYGMUNT_GRANITE, ZYGMUNT_GRANITE, M_STONE, M_STONE)
	_prism(_circle(c, 1.9, 4), g + 0.3, g + 1.5, ZYGMUNT_PLINTH.darkened(0.12), none, M_STONE)
	_prism(_circle(c, 1.5, 4), g + 1.5, g + 4.6, ZYGMUNT_PLINTH, none, M_STONE)
	_prism(_circle(c, 1.58, 4), g + 4.0, g + 4.6, ZYGMUNT_BRONZE, none, M_STONE)  # the bronze inscription band
	_prism(_circle(c, 1.7, 4), g + 4.6, g + 5.0, ZYGMUNT_PLINTH, ZYGMUNT_PLINTH.lightened(0.05), M_STONE, M_STONE)
	# The shaft, tapering a little, over a bronze sculpted ring; then the capital and the abacus.
	_mode = M_STONE
	_prism(_circle(c, 0.8, 8), g + 5.0, g + 6.0, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	_frustum(_circle(c, 0.6, 16), g + 6.0, _circle(c, 0.45, 16), g + 16.2, ZYGMUNT_STONE)
	_frustum(_circle(c, 0.5, 12), g + 16.2, _circle(c, 0.85, 12), g + 17.8, ZYGMUNT_CAPITAL)
	_prism(_circle(c, 0.95, 4), g + 17.8, g + 18.6, ZYGMUNT_STONE, ZYGMUNT_STONE, M_STONE, M_STONE)
	# The king (facing south, down Krakowskie Przedmieście): robe, body, head; the cross held
	# high in his left hand, the sabre in his right.
	_prism(_circle(c, 0.42, 8), g + 18.6, g + 19.9, ZYGMUNT_BRONZE, none, M_STONE)
	_prism(_circle(c, 0.3, 8), g + 19.9, g + 20.9, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	_prism(_circle(c, 0.16, 6), g + 20.9, g + 21.3, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	var hand := c + Vector2(0.38, 0.05)
	_prism(_circle(hand, 0.07, 4), g + 20.2, g + 22.9, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	var bar := PackedVector2Array([hand + Vector2(-0.36, -0.05), hand + Vector2(0.36, -0.05), hand + Vector2(0.36, 0.05), hand + Vector2(-0.36, 0.05)])
	_prism(bar, g + 22.25, g + 22.39, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	var sabre := PackedVector2Array([c + Vector2(-0.34, 0.1), c + Vector2(-0.3, 0.1), c + Vector2(-0.3, 0.95), c + Vector2(-0.34, 0.95)])
	_prism(sabre, g + 19.55, g + 19.65, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	_collide(_circle(c, 3.4, 8))


# --- Rynek Starego Miasta and its Syrenka (F, 2026-11-01) -------------------------------------

## The Old Town Market Square (about 90 x 73 m, rebuilt from rubble after the war) and the
## mermaid in its fountain. The houses round it are the map's (LoD2 on the Mac, the historic
## tenement dress of `map_builder._tenement_facades` and `OldTownRoofs`); this adds what the map
## lacks (docs/landmarks/specs/rynek.md): the cobbled paving (a border band, a field, a pale disc
## round the fountain, laid round the mapped footways), the café gardens along all four sides
## (58 umbrellas with a table and two chairs each, one colour per restaurant), and the fountain:
## a stone rim wall round the mapped pond, an octagonal pedestal and the Syrenka in bronze with
## her raised sword and round shield. Two sites: `rynek` (paving and gardens, one card) and
## `syrenka` (the statue, its own card, built later so its picking cells win).
## The square's corners are the open area's edge lines 7 m off the facades (found from the
## OSM outlines: the flood fill of what is more than 7 m from a building), the umbrellas stand
## on those lines where a facade is within 5-10 m (not in the street mouths).
const RYNEK_QUAD := [Vector2(-854.2, -1756.1), Vector2(-811.2, -1796.6), Vector2(-758.2, -1735.9), Vector2(-799.7, -1695.4)]

## Paving: how far past the 7 m line it reaches (so it stops 6.5 m off the facades, inside the
## mapped footways' 5 m strip), the border band's width, and the disc round the fountain.
const RYNEK_REACH := 0.5
const RYNEK_BAND := 1.3
const RYNEK_DISC := 11.0
## The trailer pass (F, 2026-11-08, Mapillary photos in refs/oldtown_rynek_*): the square is
## blue-grey granite setts, not sand, with pale granite bands in rings round the fountain (F's
## drone photo E05); the cafe gardens are mostly cream umbrellas inside low dark fences.
const RYNEK_FIELD := Color("#9d9b95")
const RYNEK_BORDER := Color("#86847f")
const RYNEK_LIGHT := Color("#b9b5ab")
const RYNEK_PATH := Color("#c6c2b8")
const RYNEK_PATH_W := 0.8
const RYNEK_RINGS := [17.0, 25.0, 33.0]

const RYNEK_RIM := Color("#ddd5c1")
const RYNEK_STONE := Color("#cfc8b5")

## One restaurant's umbrellas share a colour: runs of this many along a side.
const RYNEK_RUN := 5
const RYNEK_CANOPY := [Color("#efe8d6"), Color("#f3efe6"), Color("#2f5e45"), Color("#e6dcc2"), Color("#8c2f36"),
		Color("#f0eadb"), Color("#ddd2b6"), Color("#efe3c0"), Color("#f2eee4")]
## x, z, yaw (the side's direction), side: the umbrellas' places.
const RYNEK_UMBRELLAS := [
	-851.1, -1759, 2.33, 0, -847.7, -1762.2, 2.33, 0, -844.4, -1765.3, 2.33, 0,
	-841, -1768.5, 2.33, 0, -837.7, -1771.6, 2.33, 0, -834.3, -1774.8, 2.33, 0,
	-831, -1777.9, 2.33, 0, -827.6, -1781.1, 2.33, 0, -824.3, -1784.2, 2.33, 0,
	-821, -1787.4, 2.33, 0, -817.6, -1790.6, 2.33, 0, -814.3, -1793.7, 2.33, 0,
	-808.9, -1794, 0.72, 1, -805.8, -1790.5, 0.72, 1, -802.8, -1787.1, 0.72, 1,
	-799.8, -1783.6, 0.72, 1, -796.8, -1780.1, 0.72, 1, -793.7, -1776.7, 0.72, 1,
	-790.7, -1773.2, 0.72, 1, -787.7, -1769.7, 0.72, 1, -784.7, -1766.3, 0.72, 1,
	-781.6, -1762.8, 0.72, 1, -778.6, -1759.4, 0.72, 1, -775.6, -1755.9, 0.72, 1,
	-772.6, -1752.4, 0.72, 1, -769.5, -1749, 0.72, 1, -766.5, -1745.5, 0.72, 1,
	-763.5, -1742, 0.72, 1, -760.5, -1738.6, 0.72, 1, -760.8, -1733.3, -0.8, 2,
	-764.1, -1730.1, -0.8, 2, -767.4, -1726.9, -0.8, 2, -770.7, -1723.7, -0.8, 2,
	-774, -1720.5, -0.8, 2, -777.3, -1717.3, -0.8, 2, -780.6, -1714.1, -0.8, 2,
	-783.9, -1710.9, -0.8, 2, -787.2, -1707.6, -0.8, 2, -790.5, -1704.4, -0.8, 2,
	-793.8, -1701.2, -0.8, 2, -797.1, -1698, -0.8, 2, -802.4, -1698.4, -2.41, 3,
	-805.5, -1701.8, -2.41, 3, -808.5, -1705.2, -2.41, 3, -811.6, -1708.6, -2.41, 3,
	-814.7, -1712, -2.41, 3, -817.7, -1715.5, -2.41, 3, -820.8, -1718.9, -2.41, 3,
	-823.9, -1722.3, -2.41, 3, -827, -1725.7, -2.41, 3, -830, -1729.2, -2.41, 3,
	-833.1, -1732.6, -2.41, 3, -836.2, -1736, -2.41, 3, -839.3, -1739.4, -2.41, 3,
	-842.3, -1742.9, -2.41, 3, -845.4, -1746.3, -2.41, 3, -848.5, -1749.7, -2.41, 3,
	-851.5, -1753.1, -2.41, 3
]
## The fountain's rim wall: outer and inner radius, height over the ground.
const SYRENKA_RIM_OUT := 4.5
const SYRENKA_RIM_IN := 3.9
const SYRENKA_RIM_H := 0.5


func _find_rynek() -> void:
	_add_site("rynek", [_rynek_paving()])
	_add_site("syrenka", [_circle(RYNEK_FOUNTAIN, SYRENKA_RIM_OUT, 16)])


## The paving's outline: the square's quad grown RYNEK_REACH, wound the way `_cap` wants.
func _rynek_paving() -> PackedVector2Array:
	var quad := PackedVector2Array(RYNEK_QUAD)
	var grown := Geometry2D.offset_polygon(quad, RYNEK_REACH, Geometry2D.JOIN_MITER)
	var out: PackedVector2Array = grown[0] if not grown.is_empty() else quad
	if Geometry2D.is_polygon_clockwise(out):
		out.reverse()
	return out


func _build_rynek(site: Dictionary) -> void:
	var poly: PackedVector2Array = site["zone"][0]
	var low := INF
	var high := -INF
	var box := _box_of([poly])
	for k in 36:
		var q := box.position + Vector2((k % 6) / 5.0 * box.size.x, (k / 6) / 5.0 * box.size.y)
		if Geometry2D.is_point_in_polygon(q, poly):
			var h: float = map.terrain_height(q.x, q.y)
			low = minf(low, h)
			high = maxf(high, h)
	if low == INF:
		return
	_g = low
	_no_roof = true
	_mode = M_STONE
	# The paving, over the highest ground in it, as a thick slab (its sides sink into the
	# ground where the square dips): border, field, then the pale disc round the fountain. The
	# mapped pond and its rim stay open.
	var top := high + 0.03
	var hole := _circle(RYNEK_FOUNTAIN, SYRENKA_RIM_OUT + 0.3, 16)
	_prism(poly, low - 0.3, top, RYNEK_BORDER, RYNEK_BORDER, M_STONE, M_STONE)
	var inner := Geometry2D.offset_polygon(poly, -RYNEK_BAND, Geometry2D.JOIN_MITER)
	if not inner.is_empty():
		_cap_holes(inner[0], [hole], top + 0.015, RYNEK_FIELD)
	_cap(_circle(RYNEK_FOUNTAIN, RYNEK_DISC + 0.5, 28), top + 0.03, RYNEK_BORDER)
	_cap_holes(_circle(RYNEK_FOUNTAIN, RYNEK_DISC, 28), [hole], top + 0.045, RYNEK_LIGHT)
	# The pale granite bands in the setts (F's drone photo E05): rings round the fountain, each
	# drawn in short pieces, a piece left out where it would leave the field.
	var field: PackedVector2Array = inner[0] if not inner.is_empty() else poly
	for r: float in RYNEK_RINGS:
		var pieces := 72
		for k in pieces:
			var t0 := TAU * k / pieces
			var t1 := TAU * (k + 1) / pieces
			var d0 := Vector2(cos(t0), sin(t0))
			var d1 := Vector2(cos(t1), sin(t1))
			var mid := RYNEK_FOUNTAIN + (d0 + d1) * 0.5 * r
			if not Geometry2D.is_point_in_polygon(mid, field):
				continue
			var w := RYNEK_PATH_W * 0.5
			var piece := PackedVector2Array([RYNEK_FOUNTAIN + d0 * (r - w), RYNEK_FOUNTAIN + d1 * (r - w),
					RYNEK_FOUNTAIN + d1 * (r + w), RYNEK_FOUNTAIN + d0 * (r + w)])
			if Geometry2D.is_polygon_clockwise(piece):
				piece.reverse()
			_cap(piece, top + 0.025, RYNEK_PATH)
	# The café gardens: the umbrellas on their lines, a colour to each run, a low fence on the
	# square's side of each run with a gap at the run's start (the garden's way in).
	var u := RYNEK_UMBRELLAS
	var run := 0
	var last_side := -1
	for k in range(0, u.size(), 4):
		var side := int(u[k + 3])
		if side != last_side:
			last_side = side
			run = 0
		var col: Color = RYNEK_CANOPY[(side * 3 + run / RYNEK_RUN) % RYNEK_CANOPY.size()]
		var gate := run % RYNEK_RUN == 0
		run += 1
		_umbrella(Vector2(u[k], u[k + 1]), float(u[k + 2]), top, col, not gate)
	_no_roof = false


func _build_syrenka(_site: Dictionary) -> void:
	var c := RYNEK_FOUNTAIN
	_g = map.terrain_height(c.x, c.y)
	var g := _g
	_mode = M_STONE
	# The rim: a low stone wall round the pond (so a car meets a wall, not the water), its top
	# an annulus, then the pedestal in the middle on a round footing.
	var outer := _circle(c, SYRENKA_RIM_OUT, 16)
	var inner := _circle(c, SYRENKA_RIM_IN, 16)
	for k in outer.size():
		var k1 := (k + 1) % outer.size()
		_wall(outer[k], outer[k1], g - 0.3, g + SYRENKA_RIM_H, (outer[k] + outer[k1]) * 0.5 - c, RYNEK_STONE)
		_wall(inner[k1], inner[k], g - 0.3, g + SYRENKA_RIM_H, c - (inner[k] + inner[k1]) * 0.5, RYNEK_STONE.darkened(0.08))
	_cap_holes(outer, [inner], g + SYRENKA_RIM_H, RYNEK_RIM)
	var stone := RYNEK_STONE
	_prism(_circle(c, 1.9, 8), g - 0.3, g + 0.35, stone.darkened(0.06), stone, M_STONE, M_STONE)
	_prism(_circle(c, 1.45, 8), g + 0.35, g + 0.6, stone, RYNEK_STONE_HI, M_STONE, M_STONE)
	_prism(_circle(c, 1.05, 8), g + 0.6, g + 2.4, stone.darkened(0.04), stone, M_STONE, M_STONE)
	_prism(_circle(c, 1.3, 8), g + 2.4, g + 2.6, RYNEK_STONE_HI, RYNEK_STONE_HI.lightened(0.05), M_STONE, M_STONE)
	_frustum(_circle(c, 0.95, 8), g + 2.6, _circle(c, 0.5, 8), g + 2.95, RYNEK_BRONZE_SHADE, RYNEK_BRONZE_SHADE)
	_o = c
	_a = Vector2(0.0, 1.0)
	_b = Vector2(-_a.y, _a.x)
	_syrenka_figure(g + 2.95)
	_collide(outer)


# --- Plac Zamkowy for the trailer (F, 2026-11-10) ----------------------------------------------

## The square round Sigismund's Column, for the Old Town take of the beta trailer (photos F sent:
## the column's raised granite plaza with its two curved flights of steps, the cafe gardens
## under cream umbrellas along the houses, the setts crowded with tourists). The column itself is
## `zygmunt` above. This adds the plaza (a low granite fan round the column from the north-east,
## round the east and south, to the south-west) with three treads down to the setts all along its
## curved edge, and two cafe gardens (the north houses' one, and the one at Kamienica Johna's
## front). The tourists and the pigeons are `plac_zamkowy_life.gd`.
const ZAMKOWY_ZONE := [Vector2(-738.0, -1530.0), Vector2(-684.0, -1530.0), Vector2(-684.0, -1433.0), Vector2(-738.0, -1433.0)]
## The plaza: radius to the first tread, the arc's two ends (degrees, 0 east, 90 south), the tread
## width and the risers' height; the plaza's top is 0.36 over the setts (the column's
## own steps top out at 0.15, 0.30, 0.45 and 0.60, so no top is coplanar with theirs).
const ZAMKOWY_R := 10.0
const ZAMKOWY_FROM := -65.0
const ZAMKOWY_TO := 150.0
const ZAMKOWY_TREAD := 0.66
## Treads down from the plaza: its top is (this + 1) risers over the setts.
const ZAMKOWY_TREADS := 3
const ZAMKOWY_RISER := 0.09
const ZAMKOWY_GRANITE := Color("#b3aea4")
const ZAMKOWY_GRANITE_DARK := Color("#9c978e")
## The cafe gardens: [x, z, yaw] of each set. The north garden runs along the footway under
## the north houses, the south one along Kamienica Johna's north front.
const ZAMKOWY_SETS := [
	-735.6, -1508.4, 0.97, -733.4, -1512.0, 0.97, -731.2, -1515.6, 0.97, -729.0, -1519.2, 0.97,
	-726.8, -1522.8, 0.97, -730.6, -1506.4, 0.97, -728.4, -1510.0, 0.97, -726.2, -1513.6, 0.97,
	-740.0, -1441.6, 0.0, -736.0, -1441.6, 0.0, -732.0, -1441.6, 0.0, -728.0, -1441.8, 0.0
]


func _find_zamkowy() -> void:
	_add_site("zamkowy", [PackedVector2Array(ZAMKOWY_ZONE)])
	# the oak in its bench: a big spreading crown, 14 m tall and 12 m across (F's photo)
	tree_set.append([ZAMKOWY_OAK, 4.0, 14.5, 6.0, 5])  # 5: TreeKind.OAK


## A ring sector round the column between two radii and two angles (degrees), wound for `_cap`.
func _zamkowy_ring(r0: float, r1: float, d0: float, d1: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(4, ceili((d1 - d0) / 6.0))
	for k in n + 1:
		out.append(ZYGMUNT + Vector2.from_angle(deg_to_rad(d0 + (d1 - d0) * k / n)) * r1)
	if r0 <= 0.01:
		out.append(ZYGMUNT)
	else:
		for k in range(n, -1, -1):
			out.append(ZYGMUNT + Vector2.from_angle(deg_to_rad(d0 + (d1 - d0) * k / n)) * r0)
	if Geometry2D.is_polygon_clockwise(out):
		out.reverse()
	return out


## The lowest and highest ground under the plaza and its treads (x, y of the result), INF, -INF
## when the terrain is not there.
static func zamkowy_span(m: Object) -> Vector2:
	var low := INF
	var high := -INF
	for r: float in [4.0, ZAMKOWY_R, ZAMKOWY_R + ZAMKOWY_TREADS * ZAMKOWY_TREAD]:
		for d in range(int(ZAMKOWY_FROM), int(ZAMKOWY_TO) + 1, 15):
			var q := ZYGMUNT + Vector2.from_angle(deg_to_rad(float(d))) * r
			var h: float = m.terrain_height(q.x, q.y)
			low = minf(low, h)
			high = maxf(high, h)
	return Vector2(low, high)


## True when p lies on the plaza or its treads (the people and the pigeons use this to stand on them).
static func zamkowy_on(p: Vector2) -> bool:
	var d := p - ZYGMUNT
	if d.length() > ZAMKOWY_R + ZAMKOWY_TREADS * ZAMKOWY_TREAD:
		return false
	var a := rad_to_deg(d.angle())
	return a >= ZAMKOWY_FROM and a <= ZAMKOWY_TO


## The floor at p: the plaza's top or tread when p is on it (`high` from `zamkowy_span`), else
## the ground.
static func zamkowy_floor(m: Object, p: Vector2, high: float) -> float:
	var g: float = m.ground_height(p.x, p.y)
	if not zamkowy_on(p):
		return g
	var r := p.distance_to(ZYGMUNT)
	var k := ZAMKOWY_TREADS + 1
	if r > ZAMKOWY_R:
		k = maxi(0, ZAMKOWY_TREADS - int((r - ZAMKOWY_R) / ZAMKOWY_TREAD))
	return maxf(g, high + k * ZAMKOWY_RISER)


func _build_zamkowy(_site: Dictionary) -> void:
	_mode = M_STONE
	_no_roof = true
	# The plaza and its three treads, over the highest ground they cover (their sides sink into
	# the ground where the setts dip), like the Rynek's slab.
	var span := zamkowy_span(map)
	var low: float = span.x
	var high: float = span.y
	if low == INF:
		_no_roof = false
		return
	var y := high
	var plaza := _zamkowy_ring(0.0, ZAMKOWY_R, ZAMKOWY_FROM, ZAMKOWY_TO)
	_prism(plaza, low - 0.3, y + (ZAMKOWY_TREADS + 1) * ZAMKOWY_RISER, ZAMKOWY_GRANITE_DARK, ZAMKOWY_GRANITE, M_STONE, M_STONE)
	var r := ZAMKOWY_R
	for k in ZAMKOWY_TREADS:
		var ring := _zamkowy_ring(r, r + ZAMKOWY_TREAD, ZAMKOWY_FROM, ZAMKOWY_TO)
		_prism(ring, low - 0.3, y + (ZAMKOWY_TREADS - k) * ZAMKOWY_RISER, ZAMKOWY_GRANITE_DARK, ZAMKOWY_GRANITE.lightened(0.04 * (k + 1)), M_STONE, M_STONE)
		r += ZAMKOWY_TREAD
	# The cars stop at the plaza's edge (as they do at the real steps).
	_collide(_zamkowy_ring(0.0, r, ZAMKOWY_FROM, ZAMKOWY_TO))
	# The cafe gardens: cream umbrellas with a red one now and then, four chairs to a table.
	var u := ZAMKOWY_SETS
	var canopy: Array[Color] = [Color("#efe8d6"), Color("#f3efe6"), Color("#efe8d6"), Color("#8c2f36"), Color("#f0eadb")]
	for k in range(0, u.size(), 3):
		var p := Vector2(u[k], u[k + 1])
		var gy: float = map.terrain_height(p.x, p.y)
		_umbrella(p, float(u[k + 2]), gy, canopy[(k / 3) % canopy.size()])
		for v: float in [-0.8, 0.8]:
			_lbox(v, 0.0, 0.2, 0.2, gy, gy + 0.45, RYNEK_CHAIR, M_STONE)
	_zamkowy_oak()
	_no_roof = false


## The oak by the castle's west wing (F's photo, 2026-11-26): it stands in a round bench of
## granite blocks in two tiers, about 7.4 m across: a low step for the feet (0.42 m) and the seat
## ring (0.88 m) people sit on all round, each tier of 24 blocks in slightly different browns
## with a dark joint between them, a rounded coping on the seat, the soil on top behind an iron
## railing. F's second look (2026-11-26, "the laweczki near the tree"): the flat grey rings read as
## a fountain basin, not a bench. The tree itself is the laser scan's, made big by `tree_set`.
const ZAMKOWY_OAK := Vector2(-682.4, -1552.2)
const ZAMKOWY_BENCH := Color("#8f8170")   # the photo's warm grey-brown granite
const ZAMKOWY_JOINT := Color("#4f463d")
const ZAMKOWY_BLOCKS := 24
func _zamkowy_oak() -> void:
	var c := ZAMKOWY_OAK
	var g: float = map.terrain_height(c.x, c.y)
	# [inner r, outer r, foot, top] of the step and the seat
	for tier: Array in [[3.05, 3.75, g - 0.4, g + 0.42], [2.55, 3.15, g + 0.42, g + 0.88]]:
		var r0: float = tier[0]
		var r1: float = tier[1]
		var y0: float = tier[2]
		var y1: float = tier[3]
		for k in ZAMKOWY_BLOCKS:
			var t0 := TAU * float(k) / ZAMKOWY_BLOCKS + 0.012
			var t1 := TAU * float(k + 1) / ZAMKOWY_BLOCKS - 0.012
			var shade := ZAMKOWY_BENCH.darkened(0.07) if k % 3 == 0 else (ZAMKOWY_BENCH.lightened(0.05) if k % 3 == 1 else ZAMKOWY_BENCH)
			var blk := PackedVector2Array([c + Vector2(cos(t0), sin(t0)) * r0, c + Vector2(cos(t1), sin(t1)) * r0,
					c + Vector2(cos(t1), sin(t1)) * r1, c + Vector2(cos(t0), sin(t0)) * r1])
			if Geometry2D.is_polygon_clockwise(blk):
				blk.reverse()
			_prism(blk, y0, y1, shade.darkened(0.1), shade.lightened(0.06), M_STONE, M_STONE)
		# the joints: one dark ring just inside the blocks shows through the 2.4 cm gaps
		_prism(_circle(c, r1 - 0.06, ZAMKOWY_BLOCKS), y0, y1 - 0.02, ZAMKOWY_JOINT, Color(0, 0, 0, 0), M_STONE, M_STONE)
	# the seat's coping, a little proud of the seat ring
	_frustum(_circle(c, 3.2, ZAMKOWY_BLOCKS), g + 0.88, _circle(c, 3.12, ZAMKOWY_BLOCKS), g + 0.95,
			ZAMKOWY_BENCH.lightened(0.08))
	_prism(_circle(c, 2.55, 18), g + 0.88, g + 1.02, ZAMKOWY_BENCH.darkened(0.04), Color("#4a3b2c"), M_STONE, M_STONE)
	# the railing: posts round the soil, a top rail and a middle one
	var posts := _circle(c, 2.65, 16)
	for k in posts.size():
		var p := posts[k]
		var q := posts[(k + 1) % posts.size()]
		_prism(_square(p, 0.04), g + 0.95, g + 1.78, ANNA_IRON, ANNA_IRON, M_STONE, M_STONE)
		var d := (q - p).normalized()
		var n := Vector2(-d.y, d.x) * 0.03
		for y: float in [g + 1.3, g + 1.72]:
			_prism(PackedVector2Array([p - n, q - n, q + n, p + n]), y, y + 0.06, ANNA_IRON, ANNA_IRON, M_STONE, M_STONE)
	_collide(_circle(c, 3.75, 12))


## The Mansjonaria (Plac Zamkowy at Świętojańska, the house by the oak), modelled whole (F,
## 2026-11-26: "fix this building and roof"; it was street block 101331240's fronts on LoD2's
## mass, which read its ground-floor buttresses as walls leaning out the whole height). From F's
## oak photo and the Google 3D views (refs/mansjonaria, reference only): a three-storey house of
## pale yellow-grey plaster, the square front's ground floor held by three big sloped buttresses
## (and a fourth at the north corner), a red-brick arched door between the south ones, windows
## in dark stone surrounds (pedimented on the first floor), a band over the buttresses, a cream cornice and a steep red tile hip
## roof with dormers and white chimneys. Frame: from the square front's north corner (by
## Świętojańska) to its south corner (by the castle), u south along it (15.2 m), +v out to the
## square. Spec docs/landmarks/specs/mansjonaria.md.
const MJ_N := Vector2(-689.81, -1564.41)
const MJ_S := Vector2(-679.35, -1575.45)
const MJ_WALL := Color("#dccf9f")
const MJ_BUTTRESS := Color("#c9bb8c")   # a shade darker than the wall (F's photo)
const MJ_TRIM := Color("#e8dfc2")
const MJ_STONE := Color("#77736a")   # the window surrounds, dark stone
const MJ_GLASS := Color("#353a3c")
const MJ_BRICK := Color("#9a4b38")
const MJ_TILE := Color("#b0583d")
const MJ_ZINC := Color("#868b8b")   # the dormers' sheet-metal cheeks and fronts (3D views)
const MJ_EAVE := 12.4
const MJ_RISE := 6.2
## The plan (u, v) of the mass without its buttresses, round from the square front's north corner.
const MJ_RING := [[0.0, 0.0], [15.2, 0.0], [15.21, -0.21], [15.55, -7.84], [15.78, -13.71], [16.01, -17.1],
		[12.27, -17.13], [0.59, -16.8], [0.12, -4.65], [0.06, -2.53]]
## The buttresses on the square front: [u0, u1], all 1.48 m deep at the foot.
const MJ_BUTTRESSES := [[0.1, 2.08], [4.15, 7.23], [8.3, 11.2]]


func _find_mansjonaria() -> void:
	var outline := _landmark("Mansjonaria")
	if outline.size() < 3:
		return
	_add_site("mansjonaria", [outline])


func _build_mansjonaria(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["zone"][0]
	var length := kit_front(MJ_S, MJ_N)
	# kit_front's +v is left of S->N, out to the square; u from the south corner. Re-base on the
	# north corner so u runs south (the plan above).
	_o = MJ_N
	_a = (MJ_S - MJ_N).normalized()
	_b = Vector2(-_a.y, _a.x)
	if _b.dot(Vector2(0.726, 0.688)) < 0.0:
		_b = -_b
	var mid := _w(length * 0.5, 2.0)
	_g = map.terrain_height(mid.x, mid.y)
	var g := _g
	var eave := g + MJ_EAVE
	_mode = M_STONE
	var ring := PackedVector2Array()
	for q: Array in MJ_RING:
		ring.append(_w(float(q[0]), float(q[1])))
	if Geometry2D.is_polygon_clockwise(ring):
		ring.reverse()
	var foot := _ground_under(outline) - 0.6
	_prism(ring, foot, eave, MJ_WALL, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_prism(_ring_out(ring, 0.06), foot, g + 0.55, MJ_STONE.lightened(0.25), MJ_STONE.lightened(0.25), M_STONE, M_STONE)
	kit_cornice_ring(ring, eave, MJ_TRIM, 0.35, 0.4)
	kit_ledge_ring(ring, g + 4.55, 0.25, MJ_TRIM, 0.1)  # the band over the buttresses
	# the buttresses: sloped from 1.48 m out at the foot to 0.3 m under a stone cap at 4.3 m
	for bt: Array in MJ_BUTTRESSES:
		var u0: float = bt[0]
		var u1: float = bt[1]
		var cu := (u0 + u1) * 0.5
		var hu := (u1 - u0) * 0.5
		_frustum(_rect(cu, 0.85, hu, 1.0), foot, _rect(cu, 0.075, hu - 0.04, 0.225), g + 4.3, MJ_BUTTRESS)
		_lbox(cu, 0.16, hu + 0.04, 0.3, g + 4.3, g + 4.48, MJ_BUTTRESS.darkened(0.08))
		_collide(_rect(cu, 0.85, hu, 1.0))
	# the square front: the brick-arched door and a small window on the ground floor, four axes above
	kit_face(0.0)
	kit_door(13.2, g + 0.1, 3.0, 0.75, MJ_BRICK, MJ_GLASS.darkened(0.2), true)
	kit_window(3.1, g + 1.5, 1.7, Win.FRAMED, MJ_STONE, MJ_GLASS, 0.45)
	for u: float in [3.1, 5.7, 9.75, 13.2]:
		kit_window(u, g + 5.1, 2.1, Win.PEDIMENT, MJ_STONE, MJ_GLASS, 0.55)
		kit_window(u, g + 8.7, 1.85, Win.FRAMED, MJ_STONE, MJ_GLASS, 0.52)
	# the south front (to the castle) and the north one (to Świętojańska): three rows each
	var fronts := [[_w(15.21, -0.21), _w(16.01, -17.1), 4], [_w(0.59, -16.8), _w(0.0, 0.0), 5]]
	var keep_o := _o
	var keep_a := _a
	var keep_b := _b
	for f: Array in fronts:
		var flen := kit_front(f[0], f[1])
		if _b.dot((f[0] + f[1]) * 0.5 - _centre(ring)) < 0.0:
			_b = -_b
		var n: int = f[2]
		for u in _spread(1.0, flen - 1.0, n):
			kit_window(u, g + 1.5, 1.9, Win.FRAMED, MJ_STONE, MJ_GLASS, 0.5)
			kit_window(u, g + 5.1, 2.1, Win.PEDIMENT, MJ_STONE, MJ_GLASS, 0.55)
			kit_window(u, g + 8.7, 1.85, Win.FRAMED, MJ_STONE, MJ_GLASS, 0.52)
	_o = keep_o
	_a = keep_a
	_b = keep_b
	_face = 0.0
	# the roof: a steep hip over the whole plan (0.3 m over the walls), a short ridge along v
	var base := PackedVector2Array([_w(-0.3, 0.3), _w(15.5, 0.3), _w(16.3, -17.4), _w(0.3, -17.4)])
	var crest := PackedVector2Array([_w(7.5, -7.6), _w(8.3, -7.6), _w(8.3, -9.6), _w(7.5, -9.6)])
	_frustum(base, eave + 0.3, crest, eave + 0.3 + MJ_RISE, MJ_TILE, MJ_TILE.darkened(0.06))
	# dormers: two over the square, two on each side slope; [u, v, out u, out v, slope run]
	for dm: Array in [[5.7, -1.5, 0.0, 1.0, 7.9], [9.75, -1.5, 0.0, 1.0, 7.9], [1.6, -6.0, -1.0, 0.0, 7.7],
			[1.7, -11.5, -1.0, 0.0, 7.7], [14.3, -6.0, 1.0, 0.0, 7.5], [14.5, -11.5, 1.0, 0.0, 7.5]]:
		_mansjonaria_dormer(Vector2(dm[0], dm[1]), Vector2(dm[2], dm[3]), eave + 0.3 + MJ_RISE * 1.5 / float(dm[4]))
	# two white chimneys by the ridge
	for c: Vector2 in [Vector2(5.0, -9.0), Vector2(10.8, -8.0)]:
		_lbox(c.x, c.y, 0.45, 0.35, eave + 2.5, eave + 0.3 + MJ_RISE + 0.8, MJ_TRIM.lightened(0.1))
		_lbox(c.x, c.y, 0.55, 0.45, eave + 0.3 + MJ_RISE + 0.8, eave + 0.3 + MJ_RISE + 1.0, MJ_TRIM)
	_collide(ring)


## A dormer on the Mansjonaria's roof: `at` the front's middle (u, v), `out` the way it faces
## (a unit plan step along u or v), `y` the roof's height at the front: a wide box in grey sheet
## metal (the 3D views: big zinc dormers) with a dark window and a small tile gable roof whose
## ridge runs back into the slope.
func _mansjonaria_dormer(at: Vector2, out: Vector2, y: float) -> void:
	var side := Vector2(-out.y, out.x)
	var back := at - out * 2.0
	var c := (at + back) * 0.5
	var hs := 0.95
	var hd := 1.0
	var hu := absf(side.x) * hs + absf(out.x) * hd
	var hv := absf(side.y) * hs + absf(out.y) * hd
	_lbox(c.x, c.y, hu, hv, y - 0.6, y + 1.25, MJ_ZINC)
	var f := at + out * 0.02
	_mode = _lit(at.x + at.y, y)
	var wa := _w(f.x - side.x * 0.62, f.y - side.y * 0.62)
	var wb := _w(f.x + side.x * 0.62, f.y + side.y * 0.62)
	var wo := (_a * out.x + _b * out.y).normalized()
	_wall(wa, wb, y - 0.25, y + 0.95, wo, MJ_GLASS)
	_mode = M_STONE
	var ru := absf(side.x) * (hs + 0.12) + absf(out.x) * (hd + 0.1)
	var rv := absf(side.y) * (hs + 0.12) + absf(out.y) * (hd + 0.1)
	var tu := absf(out.x) * (hd + 0.1) + 0.02
	var tv := absf(out.y) * (hd + 0.1) + 0.02
	_frustum(_rect(c.x, c.y, ru, rv), y + 1.25, _rect(c.x, c.y, tu, tv), y + 2.05, MJ_ZINC.darkened(0.1))


## The mermaid, bronze: the tail coiled on the rock with its fin flicked up, the torso, the
## head with its long hair, the right arm raising the sword over her head, the left raising the
## round shield (F's photo, 2026-11-08). `y` is the rock's top; the local frame is _o/_a/_b (u forward).
func _syrenka_figure(y: float) -> void:
	var bz := RYNEK_BRONZE
	var none := Color(0, 0, 0, 0)
	var pt := func(u: float, v: float, h: float) -> Vector3:
		var w := _w(u, v)
		return Vector3(w.x, y + h, w.y)
	# The tail: four turns of a coil rising to the hips, then two flukes.
	_beam(pt.call(0.35, -0.35, 0.12), pt.call(0.15, -0.75, 0.32), 0.46, RYNEK_BRONZE_SHADE)
	_beam(pt.call(0.15, -0.75, 0.32), pt.call(-0.3, -0.55, 0.62), 0.44, bz)
	_beam(pt.call(-0.3, -0.55, 0.62), pt.call(-0.25, -0.05, 0.95), 0.4, RYNEK_BRONZE_SHADE)
	_beam(pt.call(-0.25, -0.05, 0.95), pt.call(0.0, 0.0, 1.25), 0.36, bz)
	_beam(pt.call(0.35, -0.35, 0.12), pt.call(0.8, -0.15, 0.66), 0.13, RYNEK_BRONZE_DEEP)
	_beam(pt.call(0.35, -0.35, 0.12), pt.call(0.62, -0.7, 0.74), 0.13, RYNEK_BRONZE_DEEP)
	# The torso (a little wider at the shoulders), the neck, the head and the hair.
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 0.2, 0.26), y + 1.2, _rect(0.0, 0.0, 0.22, 0.3), y + 1.55, bz)
	_frustum(_rect(0.0, 0.0, 0.22, 0.3), y + 1.55, _rect(0.0, 0.0, 0.17, 0.25), y + 1.78, bz.lightened(0.04), bz)
	_prism(_rect(0.0, 0.0, 0.06, 0.06), y + 1.78, y + 1.88, bz, none, M_STONE)
	_prism(_rect(0.02, 0.0, 0.11, 0.1), y + 1.88, y + 2.14, bz.lightened(0.05), bz, M_STONE, M_STONE)
	_prism(_rect(-0.1, 0.0, 0.09, 0.14), y + 1.9, y + 2.2, RYNEK_BRONZE_DEEP, RYNEK_BRONZE_DEEP, M_STONE, M_STONE)
	_beam(pt.call(-0.14, 0.0, 2.0), pt.call(-0.42, 0.0, 1.3), 0.2, RYNEK_BRONZE_DEEP)
	# F's photo (2026-11-08): the right arm raised high over her head, the sword held across above
	# it, blade out to her left and a little up; the left arm raised too, the round shield up at
	# head height to her left, turned half forward.
	_beam(pt.call(0.0, -0.3, 1.68), pt.call(0.02, -0.42, 2.12), 0.14, bz)
	var fist: Vector3 = pt.call(0.04, -0.22, 2.5)
	_beam(pt.call(0.02, -0.42, 2.12), fist, 0.13, bz)
	_beam(fist + Vector3.UP * 0.02, pt.call(0.0, -0.36, 2.48), 0.1, RYNEK_BRONZE_SHADE)
	_beam(fist, pt.call(-0.04, 0.82, 2.7), 0.07, RYNEK_BRONZE_HI)
	_beam(pt.call(0.0, 0.3, 1.68), pt.call(0.14, 0.58, 1.82), 0.14, bz)
	var hand: Vector3 = pt.call(0.22, 0.6, 2.05)
	_beam(pt.call(0.14, 0.58, 1.82), hand, 0.13, bz)
	var face := Vector3(_a.x * 0.75 + _b.x * 0.66, 0.0, _a.y * 0.75 + _b.y * 0.66).normalized()
	var boss := hand + face * 0.08 + Vector3.UP * 0.05
	_disc(boss, face, 0.52, 12, RYNEK_BRONZE_SHADE)
	_disc(boss + face * 0.03, face, 0.4, 12, RYNEK_BRONZE_HI)
	_disc(boss + face * 0.06, face, 0.13, 8, RYNEK_BRONZE_DEEP)


# --- Plac Małachowskiego and the Presidential Palace (2026-10-31) ------------------------------

## Teatr Wielki (Antonio Corazzi, 1825-1833): the opera's mass stays LoD2's (a kept skin), and the
## model adds what LoD2 flattens, the front on Plac Teatralny: a high rusticated base with wide
## steps, the portico of eight Ionic columns under a heavy entablature and an attic crowned by a
## sculpture group. Spec docs/landmarks/specs/teatr.md.
## Frame: origin at the front's west end on the outline (the front runs 96.4 m), u along the
## front, +v out of it (south-east, to the square).
const TEATR := Vector2(-903.1, -952.5)
const TEATR_AXIS := Vector2(0.7956, -0.6058)
const TEATR_MID := 48.2
const TEATR_STONE := Color("#eee6d0")
const TEATR_BASE := Color("#cdc3a9")
const TEATR_COLUMN := Color("#f1ead7")
const TEATR_SCULPT := Color("#d9d2bf")
## Portico column centres across the front, u from the middle: ten (T06-04, 2026-11-08).
const TEATR_COLS := [-15.3, -11.9, -8.5, -5.1, -1.7, 1.7, 5.1, 8.5, 11.9, 15.3]
const TEATR_HALF := 17.0          ## the portico's half width over its columns
const TEATR_ARCADE := 8.6         ## the arcaded ground storey under the columns (F's photo, 2026-11-08)
const TEATR_COL_H := 11.2         ## the columns' height
const TEATR_ARCH := Color("#4a4136")    ## the arcade's openings in shade, lamp-lit at night
const TEATR_PED_HALF := 15.0      ## the raised middle block and its pediment, half width
const TEATR_RELIEF := Color("#cfc6ae")   ## the tympanum's relief, in the stone's shade
const TEATR_BRONZE := Color("#4d5a52")   ## the quadriga's dark green-bronze (T06-04)
const TEATR_COPPER := Color("#7fa894")   ## the green copper roofs (T06-08)


## The Royal Castle (Zamek Królewski). Pass 1 kept LoD2's mass in its skin and added the stone
## plinth; pass 2 (2026-11-02, from 13 Commons photos and the GUGiK orthophoto, refs/zamek/ on the
## Mac) adds what makes it read as the castle: the Clock Tower's shaft with its cream quoins, the
## gate, the iron balcony, four clock dials, and its green copper helm with the lantern, a second
## onion and the spire; the two square corner turrets of the west front with their bulbous caps;
## the cream-white Vistula front over a rusticated ground floor with its cornice; the oval central
## risalit with its copper dome and gilt figures; and the row of tubbed ball trees on the terrace
## in front of it. Spec docs/landmarks/specs/zamek.md.
func _build_zamek(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["zone"][0]
	if ring.size() < 3:
		return
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_mode = M_STONE
	var n := ring.size()
	for i in n:
		var p := ring[i]
		var q := ring[(i + 1) % n]
		var len := p.distance_to(q)
		if len < 0.5:
			continue
		var out := _out(ring, p, q)
		var steps := maxi(ceili(len / 6.0), 1)
		for k in steps:
			var a := p.lerp(q, float(k) / steps) + out * 0.7
			var b := p.lerp(q, float(k + 1) / steps) + out * 0.7
			_g = minf(map.terrain_height(a.x, a.y), map.terrain_height(b.x, b.y))
			_wall(a, b, _g - 1.0, _g + 2.2, out, ZAMEK_STONE, p.distance_to(a))
	var yard: float = map.terrain_height(ZAMEK_YARD.x, ZAMEK_YARD.y)
	_zamek_mass(yard)
	_zamek_river_front()
	_zamek_square_front(ring)
	_zamek_e_front(yard)
	_zamek_clock_tower()
	for c: Vector2 in ZAMEK_TURRETS:
		_zamek_turret(c)
	_zamek_towers(yard)
	_zamek_roof_details(yard)
	_zamek_tubs()


## Pass 2's colours (the photos' hues, calmed to the palette) and places (the orthophoto and the
## mapped parts, world x and z).
const ZAMEK_CREAM := Color("#e6dbc0")     # quoins, cornices, the gate's surround, the lantern

const ZAMEK_RUSTIC := Color("#cbb6a6")    # its rusticated ground floor, pinkish grey
const ZAMEK_COPPER := Color("#6f9e86")    # the helms and the dome, green copper
const ZAMEK_GILT := Color("#d6b04c")
const ZAMEK_DIAL := Color("#1f2a3a")      # the clock faces: dark blue, gilt numerals
const ZAMEK_IRON := Color("#2b2a2a")
const ZAMEK_GATE := Color("#2f2a26")

## The square corner turrets at the two ends of the west front.
const ZAMEK_TURRETS := [Vector2(-675.0, -1476.7), Vector2(-669.6, -1565.7)]
## The courtyard (the ground the Vistula front's storeys count from) and that front's eave.
const ZAMEK_YARD := Vector2(-632.0, -1517.0)
const ZAMEK_EAVE := 17.0
## The row of tubs on the terrace in front of the Vistula front, 7 m out, one every 4 m.
const ZAMEK_TUBS := [Vector2(-590.4, -1580.2), Vector2(-572.4, -1530.2)]


## The Vistula front, rebuilt whole (F, 2026-11-26, his garden photo and PAP's aerial diagram: "this
## green kupol is like off"). Pass 2 laid one cream wall over every east edge and stood a round drum
## with a squat dome on it; the real front (Merlini and Fontana, rebuilt 1971-1984) is a composition:
## from the north, a gabled side risalit, a loggia of four round arches under a balustraded balcony,
## the convex oval central risalit under its tall bell-shaped copper roof with the gilt sculpture
## group, a second loggia and the second gabled risalit. Three storeys over a rusticated ground floor:
## tall pedimented windows on the piano nobile, square ones above, green-grey glazing in cream
## surrounds, a cream cornice. Frame: origin (-609.6, -1596.8) on the outline's main front line,
## u south along it (the outline's steps: the north risalit u -16..0, 5 m proud; the loggias
## u 0..18 and 41..59; the oval u 18..41, 6.4 m out; the south risalit u 59..75.3, 5.9 m proud),
## +v out of it towards the river. Spec docs/landmarks/specs/zamek.md "Vistula front".
const ZV_O := Vector2(-609.6, -1596.8)
const ZV_A := Vector2(0.347, 0.938)
## [u0, u1, face v, bays, kind]: 0 a risalit (pediment, three bays), 1 a loggia (four arches).
const ZV_PARTS := [[-16.0, 0.0, 5.3, 3, 0], [0.0, 18.0, 1.0, 4, 1], [41.0, 59.0, 1.0, 4, 1], [59.0, 75.3, 7.2, 3, 0]]
## The oval: its middle on the front line, its half width along u and its depth out of it.
const ZV_OVAL := Vector3(29.6, 11.6, 6.9)
const ZV_GLASS := Color("#5e6f6a")   # the photos' grey-green glazing and frames
const ZV_RUSTIC := Color("#d8cfbf")  # the rusticated ground floor, a warm pale stone
const ZV_COPPER := Color("#8db8a6")  # the oval roof, a pale old patina (F's garden photo)
const ZV_TILE := Color("#a9534a")  # the same as ZAMEK_ROOF (fix round 1)


func _zamek_river_front() -> void:
	var yard: float = map.terrain_height(ZAMEK_YARD.x, ZAMEK_YARD.y)
	var top := yard + ZAMEK_EAVE
	_o = ZV_O
	_a = ZV_A.normalized()
	_b = Vector2(_a.y, -_a.x)  # out of the front, east to the river
	_g = yard
	_mode = M_STONE
	for part: Array in ZV_PARTS:
		_zv_part(float(part[0]), float(part[1]), float(part[2]), int(part[3]), int(part[4]), yard, top)
	# the risalits' and the oval's return walls back to the loggias' face
	for r: Array in [[0.0, 5.3], [59.0, 7.2]]:
		var u := float(r[0])
		_zv_return(u, 1.0, float(r[1]), yard, top)
	_zv_oval(yard, top)


## The foot of the front at u, v: the terrace in front of it (the Upper Garden), never above the yard.
func _zv_foot(u: float, v: float) -> float:
	var p := _w(u, v + 1.5)
	return minf(float(map.terrain_height(p.x, p.y)), _g) - 0.6


## One straight part of the front from u0 to u1 with its face `v`: the wall, the rustication, the
## string courses and the cornice, then its windows (`bays` of them a storey) and, by `kind`, a
## loggia of four arches under a balcony (1) or a pediment over the cornice (0).
func _zv_part(u0: float, u1: float, v: float, bays: int, kind: int, yard: float, top: float) -> void:
	var foot := minf(_zv_foot(u0, v), _zv_foot(u1, v))
	kit_face(v)
	_kbox(u0, u1, v - 1.2, v, foot, yard + 4.6, ZV_RUSTIC)
	kit_bands(u0, u1, yard + 0.2, yard + 4.4, 0.55, ZV_RUSTIC)
	_kbox(u0, u1, v - 1.2, v, yard + 4.6, top, ZAMEK_VISTULA)
	kit_ledge(u0, u1, yard + 4.45, 0.4, ZAMEK_CREAM, 0.14)
	kit_ledge(u0, u1, yard + 10.7, 0.3, ZAMEK_CREAM, 0.1)
	kit_cornice(u0, u1, top, ZAMEK_CREAM, 0.6, 0.7)
	# corner quoins: cream strips at both ends from the rustication to the cornice
	for e: float in [u0 + 0.45, u1 - 0.45]:
		_kbox(e - 0.45, e + 0.45, v - 0.04, v + 0.1, yard + 4.6, top - 0.4, ZAMEK_CREAM)
	var centres := _spread(u0 + 0.6, u1 - 0.6, bays)
	for i in bays:
		var u: float = centres[i]
		var mid := kind == 0 and i == 1
		kit_window(u, yard + 5.7, 3.3, Win.PEDIMENT if mid or kind == 1 else Win.SILL_HEAD, ZAMEK_CREAM, ZV_GLASS, 0.72)
		kit_window(u, yard + 11.7, 2.4, Win.SILL_HEAD, ZAMEK_CREAM, ZV_GLASS, 0.66)
		if kind == 0:
			# the risalit's ground floor: arched windows, the middle one a door under a balcony
			kit_window(u, yard + 1.0, 2.2, Win.ARCHED, ZAMEK_CREAM, ZV_GLASS, 0.62)
			if mid:
				kit_balcony(u, yard + 5.7, 1.6, Balcony.STONE, ZAMEK_CREAM, ZAMEK_CREAM, 0.9)
	if kind == 1:
		# the loggia: four open round arches on rusticated piers, dark inside
		var arch := _spread(u0, u1, 4)
		for au: float in arch:
			# (0.06 and 0.12 proud: clear of the rustication's lines at 0.03)
			_arch_panel(_w(au, v), _a, _b, 1.75, foot + 0.4, yard + 2.6, ZAMEK_CREAM, 0.06, M_STONE)
			_arch_panel(_w(au, v), _a, _b, 1.5, foot + 0.4, yard + 2.6, ZAMEK_GATE, 0.12, M_STONE)
		# the balcony over it: a slab and a balustrade along the whole loggia
		_kbox(u0 + 0.3, u1 - 0.3, v, v + 0.9, yard + 4.6, yard + 4.9, ZAMEK_CREAM)
		kit_face(v + 0.75)
		kit_attic(u0 + 0.4, u1 - 0.4, yard + 4.9, ZAMEK_CREAM, 1.0, Attic.BALUSTRADE)
		kit_face(v)
		return
	# the risalit's pediment over the cornice, a relief in its field and three statues on it
	var um := (u0 + u1) * 0.5
	var hw := (u1 - u0) * 0.5 - 0.3
	var py := top + 0.6
	var ph := 3.4
	kit_pediment(um, hw, py, ph, ZAMEK_CREAM, ZV_TILE, 0.7, ZAMEK_VISTULA.darkened(0.12))
	_kbox(um - 1.1, um + 1.1, v + 0.55, v + 0.8, py + 0.5, py + 2.3, ZAMEK_CREAM.darkened(0.06))  # the cartouche
	for s: float in [-1.0, 0.0, 1.0]:
		var su := um + s * (hw - 0.5)
		var sy := py + (ph - 0.3 if s == 0.0 else 0.15)  # the middle one sunk into the apex, not hung over it
		_lbox(su, v + 0.3, 0.35, 0.3, sy, sy + 0.5, ZAMEK_CREAM)
		_lbox(su, v + 0.3, 0.22, 0.2, sy + 0.5, sy + 2.1, ZAMEK_GILT.darkened(0.1), M_GOLD)
	# the risalit's own gable roof running back from the pediment into the castle's roof
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(v + 0.65, v - 9.0, um, hw + 0.2, py, ph, ZAMEK_CREAM, ZV_TILE, false)
	_a = ka
	_b = kb


## A short wall at u from face v0 out to v1 (a risalit's side), the ground floor rusticated.
func _zv_return(u: float, v0: float, v1: float, yard: float, top: float) -> void:
	var foot := _zv_foot(u, v1)
	var a := _w(u, v0)
	var b := _w(u, v1)
	# the north risalit (ending at u 0) shows its side to the south, the south one (from u 59) to the north
	var out := _a if u < 1.0 else -_a
	_wall(a, b, foot, yard + 4.6, out, ZV_RUSTIC)
	_wall(a, b, yard + 4.6, top, out, ZAMEK_VISTULA)


## The oval central risalit: a convex half ellipse of three storeys (arched French windows on the
## ground floor, tall ones on the piano nobile, round oculi above), its cornice, and the tall
## bell-shaped copper roof (a flared eave, a convex shoulder, a full ellipse whose back half stands in
## the castle's roof) crowned by a small lantern and a thin gilt spire, two statues on its rim.
func _zv_oval(yard: float, top: float) -> void:
	var c := ZV_OVAL.x
	var ha := ZV_OVAL.y
	var hb := ZV_OVAL.z
	var n := 10
	var pts: Array[Vector2] = []  # local (u, v), from the south end round to the north end
	for k in n + 1:
		var t := PI * float(k) / float(n)
		# a superellipse, fuller at the ends than an ellipse: the oval meets the loggias squarely
		pts.append(Vector2(c + ha * signf(cos(t)) * pow(absf(cos(t)), 0.75), hb * pow(sin(t), 0.75) + 0.4))
	for k in n:
		_mode = M_STONE
		var p: Vector2 = pts[k]
		var q: Vector2 = pts[k + 1]
		var a := _w(p.x, p.y)
		var b := _w(q.x, q.y)
		var mid := (p + q) * 0.5
		var d2 := (q - p).normalized()
		var nrm2 := Vector2(d2.y, -d2.x)  # the facet's outward normal in the local plan
		var out := (_a * nrm2.x + _b * nrm2.y).normalized()
		var foot := _zv_foot(mid.x, mid.y)
		_wall(a, b, foot, yard + 4.6, out, ZV_RUSTIC)
		_wall(a, b, yard + 4.6, top + 0.6, out, ZAMEK_VISTULA)
		# the window bay of this facet: a frame of local axes on the facet
		var along := (b - a).normalized()
		var fc := (a + b) * 0.5
		var fy := [[yard + 0.9, 2.7, 0.62, true], [yard + 5.7, 3.4, 0.7, false]]
		for w: Array in fy:
			var y0 := float(w[0])
			var hh := float(w[1])
			var hw := float(w[2])
			_arch_panel(fc + out * 0.02, along, out, hw + 0.2, y0 - 0.15, y0 + hh - hw, ZAMEK_CREAM, 0.02, M_STONE)
			_arch_panel(fc + out * 0.02, along, out, hw, y0, y0 + hh - hw, ZV_GLASS, 0.07, _lit(float(k) * 3.1, y0))
		_mode = M_STONE
		# the oculus on the second floor, in a cream ring
		var oc := fc + out * 0.06
		_disc(Vector3(oc.x, yard + 13.2, oc.y), Vector3(out.x, 0.0, out.y), 0.95, 10, ZAMEK_CREAM)
		var oi := fc + out * 0.1
		_disc(Vector3(oi.x, yard + 13.2, oi.y), Vector3(out.x, 0.0, out.y), 0.65, 10, ZV_GLASS)
		# string courses
		_wall(a + out * 0.1, b + out * 0.1, yard + 4.45, yard + 4.85, out, ZAMEK_CREAM)
		_wall(a + out * 0.08, b + out * 0.08, yard + 10.7, yard + 11.0, out, ZAMEK_CREAM)
	_mode = M_STONE
	# the cornice and the copper roof, full ellipses round the oval's middle
	var cw := _w(c, 0.4)
	var ring := func(sa: float, sb: float) -> PackedVector2Array:
		var r := PackedVector2Array()
		for k in 20:
			var t := TAU * (float(k) + 0.5) / 20.0
			r.append(cw + _a * (sa * signf(cos(t)) * pow(absf(cos(t)), 0.75)) + _b * (sb * signf(sin(t)) * pow(absf(sin(t)), 0.75)))
		return r
	var y := top + 0.6
	_prism(ring.call(ha + 0.55, hb + 0.55), y, y + 0.7, ZAMEK_CREAM, Color(0, 0, 0, 0), M_STONE)
	_prism(ring.call(ha + 0.2, hb + 0.2), y + 0.7, y + 1.1, ZAMEK_CREAM.darkened(0.05), Color(0, 0, 0, 0), M_STONE)
	# the bell (Fable 2026-11-26): a flared eave just past the drum, a concave kick, a convex
	# shoulder rising to a small lantern, about 0.55 of the oval's width tall with the spire
	var eave: PackedVector2Array = ring.call(ha + 0.4, hb + 0.4)
	var prof := [[0.97, 1.9], [0.92, 3.1], [0.83, 4.9], [0.68, 6.8], [0.5, 8.3], [0.32, 9.5], [0.18, 10.3], [0.12, 10.6]]
	_frustum(eave, y + 1.1, ring.call(ha * 0.97, hb * 0.97), y + 1.9, ZV_COPPER.darkened(0.04))
	for k in prof.size() - 1:
		var s0 := float(prof[k][0])
		var s1 := float(prof[k + 1][0])
		_frustum(ring.call(ha * s0, hb * s0), y + float(prof[k][1]), ring.call(ha * s1, hb * s1), y + float(prof[k + 1][1]),
				ZV_COPPER.lightened(0.04 * float(k % 2)), ZV_COPPER if k == prof.size() - 2 else Color(0, 0, 0, 0))
	# the dormer-oculi in the copper: one each side of the front
	var ry := y + 3.4
	for s: float in [-0.45, 0.0, 0.45]:
		var t := PI * 0.5 + s
		var at := cw + _a * (ha * 0.92 * cos(t)) + _b * (hb * 0.92 * sin(t))
		var o3 := (_a * cos(t) / ha + _b * sin(t) / hb).normalized()
		_disc(Vector3(at.x, ry, at.y) + Vector3(o3.x, 0.0, o3.y) * 0.15, Vector3(o3.x, 0.25, o3.y).normalized(), 0.7, 8, ZAMEK_CREAM)
	# the crown: a small open lantern, its cap, and a thin gilt spire with a ball
	var top_y := y + 10.6
	_prism(_circle(cw, 1.0, 8), top_y, top_y + 1.7, ZAMEK_CREAM, Color(0, 0, 0, 0), M_STONE)
	for k in 8:
		var t := TAU * (float(k) + 0.5) / 8.0
		var dir := Vector2(cos(t), sin(t))
		_disc(Vector3(cw.x + dir.x * 1.01, top_y + 0.85, cw.y + dir.y * 1.01), Vector3(dir.x, 0.0, dir.y), 0.32, 6, ZV_GLASS.darkened(0.3))
	_frustum(_circle(cw, 1.25, 8), top_y + 1.7, _circle(cw, 0.25, 8), top_y + 3.0, ZV_COPPER)
	_mode = M_GOLD
	_prism(_circle(cw, 0.08, 6), top_y + 3.0, top_y + 6.4, ZAMEK_GILT, ZAMEK_GILT, M_GOLD, M_GOLD)
	_prism(_circle(cw, 0.3, 6), top_y + 4.0, top_y + 4.5, ZAMEK_GILT, ZAMEK_GILT, M_GOLD, M_GOLD)
	# two statues on the cornice where the oval meets the loggias
	for s: float in [-1.0, 1.0]:
		var at := cw + _a * (s * (ha - 0.3)) + _b * 0.8
		_prism(_square(at, 0.4), y + 0.7, y + 1.2, ZAMEK_CREAM, ZAMEK_CREAM, M_STONE, M_STONE)
		_prism(_square(at, 0.25), y + 1.2, y + 3.0, ZAMEK_GILT.darkened(0.12), ZAMEK_GILT, M_GOLD, M_GOLD)
	_mode = M_STONE


## The square front (F, 2026-11-10, the trailer's Old Town take: "from the side of Plac Zamkowy it had
## no facade"; photos F sent, 14 of the castle): the red plaster wall of the west wing and of the
## south wing's end, as the castle shows it to the square: a pale stone plinth, the plaster to the eave,
## three thin cream string courses and the cornice, and four rows of windows (`ZAMEK_ROWS`,
## `_zamek_window`: 2026-11-26 rework), one to a 3.6 m bay. The Clock Tower and the two corner turrets keep their own bays.
## It stands 0.3 m proud of LoD2's wall (which still shows above the eave and round the tower).
const ZAMEK_PLASTER := Color("#d98568")
const ZAMEK_PLINTH := Color("#c9bea8")
const ZAMEK_PANE := Color("#334048")   # deep blue-grey glass (the reviewer: it must read as glass, not holes)
## The south front's gate: its middle (39 m east of the SW corner), the round-arched opening 3.6 x 4.6 m in a
## cream surround 5.6 x 6.6 m, 0.25 m proud, under a small cornice.
const ZAMEK_GATE_X := -636.5
const ZAMEK_SASH := Color("#eeeae0")   # the white sash cross
## The window rows over a bay's ground: [sill, head, half width, a cornice over the head] (the
## photos 01_west_square and 02_west_column: ground floor, piano nobile, second floor, the top
## floor's square windows under the eave).
const ZAMEK_ROWS := [[1.3, 3.2, 0.55, false], [4.7, 7.5, 0.62, true], [8.8, 11.0, 0.6, false],
		[12.2, 13.7, 0.55, false]]
const ZAMEK_BAY := 3.6
## Fix round 1 (2026-11-26): the square front's bays are 4.7 m, the south front's 5.6 m and it has three rows
## (a small square window, a tall hooded one, a small square one) with courses between.
const ZAMEK_SQUARE_BAY := 4.7
const ZAMEK_SOUTH_BAY := 5.6
const ZAMEK_ROWS_S := [[2.9, 4.5, 0.6, false], [6.6, 9.4, 0.68, true], [12.4, 14.0, 0.6, false]]
const ZAMEK_COURSES_S := [5.3, 10.9]
## Absolute eave of the square front over the courtyard's ground, and its string courses over a bay's ground.
const ZAMEK_SQUARE_EAVE := 15.5
const ZAMEK_COURSES := [4.15, 8.3, 11.75]


func _zamek_square_front(ring: PackedVector2Array) -> void:
	var yard: float = map.terrain_height(ZAMEK_YARD.x, ZAMEK_YARD.y)
	var top := yard + ZAMEK_SQUARE_EAVE
	var n := ring.size()
	var run := 0.0
	_mode = M_STONE
	for i in n:
		var p := ring[i]
		var q := ring[(i + 1) % n]
		var len := p.distance_to(q)
		if len < 0.2:
			continue
		# a short edge (the gate's two pilaster steps in the outline) gets the wall but no window, so
		# the front has no gap showing the mass behind it (the first gate shot: two dark strips)
		var short := len < 3.0
		var out := _out(ring, p, q)
		# the west front (A's north-west face and the tower's own faces are the mass pass's), and the
		# south front to the SE tower's west face (x -604.7)
		var west := not short and out.x < -0.55 and (p.x + q.x) * 0.5 < -660.0 and (p.y + q.y) * 0.5 < -1473.6
		var south := (out.y > 0.55 or (short and absf(out.x) > 0.55 and (p.y + q.y) * 0.5 > -1474.8)) \
				and (p.x + q.x) * 0.5 < -604.7 and (p.x + q.x) * 0.5 > -677.0
		if not (west or south):
			continue
		var d := (q - p) / len
		var bays := 1 if short else maxi(1, roundi(len / (ZAMEK_SOUTH_BAY if south else ZAMEK_SQUARE_BAY)))
		var bay := len / bays
		var rows: Array = ZAMEK_ROWS_S if south else ZAMEK_ROWS
		var courses: Array = ZAMEK_COURSES_S if south else ZAMEK_COURSES
		for k in bays:
			var a := p + d * (bay * k) + out * 0.3
			var b := p + d * (bay * (k + 1)) + out * 0.3
			var mid := (a + b) * 0.5
			var g := minf(map.terrain_height(a.x, a.y), map.terrain_height(b.x, b.y))
			var h := top - g
			if h < 6.0:
				continue
			# The wall: plinth, plaster, courses, cornice.
			_wall(a, b, g - 0.6, g + 1.1, out, ZAMEK_PLINTH, run)
			_wall(a, b, g + 1.1, top, out, ZAMEK_PLASTER, run)
			var o2 := out * 0.04
			for c: float in courses:
				_wall(a + o2, b + o2, g + c, g + c + 0.22, out, ZAMEK_CREAM, run)
			_wall(a + out * 0.45, b + out * 0.45, top - 0.35, top + 0.5, out, ZAMEK_CREAM, run)
			_ledge(a, b, a + out * 0.45, b + out * 0.45, top + 0.5, ZAMEK_CREAM)
			run += bay
			if short:
				continue
			# The windows, not where the tower or a turret stands.
			var near_tower := absf(mid.y - ZAMEK_CLOCK.y) < 6.4 and west
			var near_turret := false
			for t: Vector2 in ZAMEK_TURRETS:
				if mid.distance_to(t) < 4.4:
					near_turret = true
			# the south gate's bay and the one over it carry no window
			var near_gate := south and absf(mid.x - ZAMEK_GATE_X) < 3.0
			if near_tower or near_turret:
				continue
			# rows: [sill, head, half width, hooded] (the photos: four storeys of windows, the
			# piano nobile's tallest under a hood, the top floor's square), kit windows in cream
			# surrounds with the white sash cross (F, 2026-11-26, "those windows look bad": flush
			# surrounds were cut away by `_wall`'s coplanar check, leaving bare dark holes)
			_o = mid
			_a = d
			_b = out
			_face = 0.0
			for r: Array in rows:
				# the gate's bay has no window below the middle row
				if near_gate and float(r[0]) < 6.0:
					continue
				var y0: float = g + float(r[0])
				var y1: float = g + float(r[1])
				if y1 > top - 0.9:
					continue
				# the reviewer's fixes (2026-11-26): frames 15 % wider, brighter cream, glass towards blue-grey
				kit_window(0.0, y0, y1 - y0, Win.HOODED if bool(r[3]) else Win.FRAMED, ZAMEK_CREAM.lightened(0.08), ZAMEK_PANE,
						float(r[2]) * 1.15, ZAMEK_SASH)
	_zamek_south_gate()
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_mode = M_STONE


## The south front's gate: a round-arched dark opening 3.6 x 4.6 m in a cream stone surround 5.6 x 6.6 m
## standing 0.25 m proud, under a small cornice (spec section 3). On the front's wall plane, 0.3 m out of
## the outline, facing south.
func _zamek_south_gate() -> void:
	var at := Vector2(ZAMEK_GATE_X, -1473.7 + 0.3)
	var g: float = minf(map.terrain_height(at.x - 2.0, at.y), map.terrain_height(at.x + 2.0, at.y))
	var along := Vector2(1, 0)
	var out := Vector2(0, 1)
	_g = g
	_mode = M_STONE
	_arch_panel(at, along, out, 2.8, g - 0.2, g - 0.2 + 3.8, ZAMEK_CREAM, 0.25, M_STONE)
	_arch_panel(at, along, out, 1.8, g, g + 2.8, ZAMEK_GATE, 0.3, M_STONE)
	_o = at
	_a = along
	_b = out
	_lbox(0.0, 0.2, 3.2, 0.3, g + 6.4, g + 6.8, ZAMEK_CREAM)


# --- Pass 3 (2026-11-26): the whole castle as one model, LoD2 gone ---------------------------------

## The courtyard, a pentagon that stays open ground; wing A (the Saxon, Vistula wing); the U of the
## other four wings as two matched polylines of six points (outer on the mapped outline, inner on the
## yard). Spec docs/landmarks/specs/zamek.md section 2.
const ZAMEK_COURT := [Vector2(-658.0, -1549.5), Vector2(-614.0, -1549.5), Vector2(-604.0, -1528.0),
		Vector2(-605.0, -1490.0), Vector2(-658.5, -1490.0)]
const ZAMEK_SAXON := [Vector2(-635.0, -1604.2), Vector2(-610.6, -1613.5), Vector2(-578.0, -1528.2),
		Vector2(-605.0, -1527.0)]
const ZAMEK_U_OUT := [Vector2(-604.0, -1567.8), Vector2(-671.7, -1568.0), Vector2(-677.6, -1474.6),
		Vector2(-594.4, -1473.6), Vector2(-583.4, -1519.7), Vector2(-589.5, -1544.0)]
const ZAMEK_U_IN := [Vector2(-604.0, -1549.5), Vector2(-658.0, -1549.5), Vector2(-658.5, -1490.0),
		Vector2(-605.0, -1490.0), Vector2(-604.0, -1528.0), Vector2(-601.0, -1544.0)]
## Heights over the yard: the U's eave and ridge, A's crest (its eave is `ZAMEK_EAVE`).
const ZAMEK_U_EAVE := 15.9
const ZAMEK_U_RIDGE := 22.8
const ZAMEK_CREST := 25.0
## A's crest, a thin quad on its midline.
const ZAMEK_CREST_A := Vector2(-618.85, -1598.6)
const ZAMEK_CREST_B := Vector2(-595.45, -1537.9)
## The towers: the south-east corner tower's plan, the Grodzka Tower (square to wing E) and the north wing tower.
const ZAMEK_SE_TOWER := Rect2(-601.7, -1469.9, 9.5, 9.5)
const ZAMEK_GRODZKA := Vector2(-600.5, -1518.0)
const ZAMEK_NORTH_TOWER := Vector2(-635.5, -1553.5)
const ZAMEK_DORMER := Color("#7f948b")
const ZAMEK_CHIMNEY := Color("#eeeae0")


## Where a wall's foot goes: the lowest ground along a to b, a metre under it.
func _zamek_foot(a: Vector2, b: Vector2) -> float:
	var lo := INF
	for k in 5:
		var p := a.lerp(b, float(k) / 4.0)
		lo = minf(lo, float(map.terrain_height(p.x, p.y)))
	return lo - 1.0


## The cream cornice at an eave along a to b (0.35 m tall, 0.45 m proud): its front and its top, through
## `_ledge` so the strips of two edges meeting at a corner don't overlap.
func _zamek_eave_band(a: Vector2, b: Vector2, out: Vector2, y: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var o := out * 0.45
	_wall(a + o, b + o, y - 0.35, y, out, ZAMEK_CREAM)
	_ledge(a, b, a + o, b + o, y, ZAMEK_CREAM)
	_mode = keep


## A wall face with the building shader's own windows (`M_MONUMENT`, no mesh per window): the cream
## plinth band to 1.1 m over the ground, the plaster `col` to the eave, the cornice. Never on a face
## that carries kit windows (the Roesslera lesson: two grids on one face).
func _zamek_face(a: Vector2, b: Vector2, out: Vector2, eave: float, col: Color) -> void:
	var foot := _zamek_foot(a, b)
	_g = foot + 1.0
	_mode = M_STONE
	_wall(a, b, foot, _g + 1.1, out, ZAMEK_PLINTH)
	_mode = M_MONUMENT
	_wall(a, b, _g + 1.1, eave, out, col)
	_mode = M_STONE
	_zamek_eave_band(a, b, out, eave)


## A's plan: the spec's quad with its river face 0.5 m inside the Vistula front's line, so it is never
## coplanar with the front's walls.
func _zamek_saxon_ring() -> PackedVector2Array:
	var fa := ZV_A.normalized()
	var fb := Vector2(fa.y, -fa.x)
	var line_o := ZV_O - fb * 0.5
	var s0: Vector2 = ZAMEK_SAXON[0]
	var s1: Vector2 = ZAMEK_SAXON[1]
	var s2: Vector2 = ZAMEK_SAXON[2]
	var s3: Vector2 = ZAMEK_SAXON[3]
	var ne: Vector2 = Geometry2D.line_intersects_line(s0, s1 - s0, line_o, fa)
	var se: Vector2 = Geometry2D.line_intersects_line(s2, s3 - s2, line_o, fa)
	return PackedVector2Array([s0, ne, se, s3])


## A polyline's points moved `d` metres away from its twin `other` (mitred at the corners): the
## roof's eave grown out of the wall.
func _zamek_grow(poly: Array, other: Array, d: float) -> PackedVector2Array:
	var res := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var dir := Vector2.ZERO
		var first := Vector2.ZERO
		for e in [i - 1, i]:
			if e < 0 or e > n - 2:
				continue
			var pa: Vector2 = poly[e]
			var pb: Vector2 = poly[e + 1]
			var t := (pb - pa).normalized()
			var nn := Vector2(-t.y, t.x)
			var away: Vector2 = (pa + pb) * 0.5 - ((other[e] as Vector2) + (other[e + 1] as Vector2)) * 0.5
			if nn.dot(away) < 0.0:
				nn = -nn
			if first == Vector2.ZERO:
				first = nn
			dir += nn
		dir = dir.normalized()
		res.append((poly[i] as Vector2) + dir * (d / maxf(dir.dot(first), 0.3)))
	return res


## A roof slope a-b-c-d (two triangles, facing up) in the tile colour.
func _zamek_slope(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	for t: Array in [[a, b, c], [a, c, d]]:
		var p: Vector3 = t[0]
		var q: Vector3 = t[1]
		var r: Vector3 = t[2]
		var n := (q - p).cross(r - p).normalized()
		if n.y < 0.0:
			n = -n
		_tri(p, q, r, n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## The mass: wing A's walls and hip roof, the U's walls (the courtyard faces, B's north face; the west,
## south and east faces are the front passes') and its matched-polyline roof ring, and the collision.
func _zamek_mass(yard: float) -> void:
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_mode = M_STONE
	_g = yard
	var tile := Color(ZAMEK_ROOF)
	var saxon := _zamek_saxon_ring()
	var a_eave := yard + ZAMEK_EAVE
	var u_eave := yard + ZAMEK_U_EAVE
	# A: the north end and the west face north of B in cream with shader windows, the river face plain
	# behind the front, the south end plain (it stands inside wing E)
	_zamek_face(saxon[0], saxon[1], _out(saxon, saxon[0], saxon[1]), a_eave, ZAMEK_VISTULA)
	var west_b := Vector2(-621.0, -1567.7)
	_zamek_face(west_b, saxon[0], _out(saxon, west_b, saxon[0]), a_eave, ZAMEK_VISTULA)
	_g = yard
	_wall(saxon[1], saxon[2], _zamek_foot(saxon[1], saxon[2]), a_eave, _out(saxon, saxon[1], saxon[2]), ZAMEK_VISTULA)
	_wall(saxon[2], saxon[3], _zamek_foot(saxon[2], saxon[3]), a_eave, _out(saxon, saxon[2], saxon[3]), ZAMEK_PLASTER)
	# the courtyard: its five faces, salmon with shader windows (A's, the NE edge, to A's eave)
	# the NE corner is where B's yard face meets A's west wall line (NW to the E corner): fix round 1
	var court := PackedVector2Array(ZAMEK_COURT)
	var e_court: Vector2 = court[2]
	var west_line: Vector2 = Geometry2D.line_intersects_line(saxon[0], e_court - saxon[0], Vector2(0.0, ZAMEK_COURT[1].y), Vector2(1.0, 0.0))
	court[1] = west_line
	for i in court.size():
		var ca := court[i]
		var cb := court[(i + 1) % court.size()]
		# B's yard face is cream (fix round 1), the others salmon
		_zamek_face(ca, cb, -_out(court, ca, cb), a_eave if i == 1 else u_eave, ZAMEK_VISTULA if i == 0 else ZAMEK_PLASTER)
	# B's north face from the turret's corner to A's west face
	_zamek_face(Vector2(-672.0, -1568.05), Vector2(-621.0, -1567.8), Vector2(0.0, -1.0), u_eave, ZAMEK_PLASTER)
	# A's hip roof: the quad grown 0.4 m, 17.0 m to a thin crest at 25.0 m
	_mode = M_STONE
	var cd := (ZAMEK_CREST_B - ZAMEK_CREST_A).normalized()
	var ce := Vector2(cd.y, -cd.x) * 0.1
	var crest := PackedVector2Array([ZAMEK_CREST_A - ce, ZAMEK_CREST_A + ce, ZAMEK_CREST_B + ce, ZAMEK_CREST_B - ce])
	# the roof's base: the quad with its SW corner at the courtyard's E corner, grown 0.4 m, so the west eave
	# never stands more than 0.4 m past the courtyard's NE to E wall
	var roof_base := PackedVector2Array([saxon[0], saxon[1], saxon[2], e_court])
	_frustum(_ring_out(roof_base, 0.4), a_eave, crest, yard + ZAMEK_CREST, tile, tile.darkened(0.06))
	_zamek_u_roof(yard, tile)
	# the collision: A, then the U's five wings (the courtyard stays open)
	_collide(saxon)
	for i in 5:
		_collide(PackedVector2Array([ZAMEK_U_OUT[i], ZAMEK_U_OUT[i + 1], ZAMEK_U_IN[i + 1], ZAMEK_U_IN[i]]))


## The U's roof: one ring of slopes from the matched polylines, the ridge at R_i = (outer_i + inner_i) / 2,
## the outer edge grown 0.4 m out and the inner 0.4 m into the yard; hips at the outer corners, valleys
## at the courtyard's, and two closed end gables that stand under A's roof.
func _zamek_u_roof(yard: float, tile: Color) -> void:
	_mode = M_STONE
	var n := ZAMEK_U_OUT.size()
	var ey := yard + ZAMEK_U_EAVE
	var ry := yard + ZAMEK_U_RIDGE
	var outer := _zamek_grow(ZAMEK_U_OUT, ZAMEK_U_IN, 0.4)
	var inner := _zamek_grow(ZAMEK_U_IN, ZAMEK_U_OUT, 0.4)
	var ridge: Array[Vector3] = []
	for i in n:
		var r := ((ZAMEK_U_OUT[i] as Vector2) + (ZAMEK_U_IN[i] as Vector2)) * 0.5
		ridge.append(Vector3(r.x, ry, r.y))
	for i in n - 1:
		_zamek_slope(Vector3(outer[i].x, ey, outer[i].y), Vector3(outer[i + 1].x, ey, outer[i + 1].y), ridge[i + 1], ridge[i], tile)
		_zamek_slope(Vector3(inner[i + 1].x, ey, inner[i + 1].y), Vector3(inner[i].x, ey, inner[i].y), ridge[i], ridge[i + 1], tile.darkened(0.03))
	for end: Array in [[0, 1], [n - 1, n - 2]]:
		var i: int = end[0]
		var o: Vector2 = ZAMEK_U_OUT[i]
		var inn: Vector2 = ZAMEK_U_IN[i]
		var po := Vector3(o.x, ey, o.y)
		var pi := Vector3(inn.x, ey, inn.y)
		var toward: Vector3 = ridge[i] - ridge[end[1]]
		var nrm := (pi - po).cross(ridge[i] - po).normalized()
		if nrm.dot(toward) < 0.0:
			nrm = -nrm
		_tri(po, pi, ridge[i], nrm, tile.darkened(0.08), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## Wing E's river face (O3 to O4, south of the Vistula front), in the Vistula front's colours: a
## rusticated ground floor to 4.6 m, a cream band, cream walls to the eave under a cream cornice, and
## three rows of kit windows over the ground floor's (spec section 3). Kit windows, so the wall is
## plain (M_STONE, never the shader's grid on it).
func _zamek_e_front(yard: float) -> void:
	# The face runs on past O4 to the Saxon wing's south end, where the Vistula front's south risalit
	# stands, so no notch opens between them (F 2026-11-26, "the hole" by the rotunda: O4 to O5 turns
	# in to the yard and had no wall, so A's plain south end showed through).
	var saxon := _zamek_saxon_ring()
	var o3: Vector2 = ZAMEK_U_OUT[3]
	var o4: Vector2 = ZAMEK_U_OUT[4]
	# never null: the ring's corners are constants and the two lines cross at about 75 degrees
	var end: Vector2 = Geometry2D.line_intersects_line(o3, o4 - o3, saxon[2], saxon[3] - saxon[2])
	var len := kit_front(o3, end)
	# the notch's roof: the east slope carried on from O4 to the new end, up to the ridge over O4
	var ey := yard + ZAMEK_U_EAVE
	var rr := (o4 + (ZAMEK_U_IN[4] as Vector2)) * 0.5
	var ga: Vector2 = _zamek_grow(ZAMEK_U_OUT, ZAMEK_U_IN, 0.4)[4]  # the ring's own eave corner: one shared edge
	var gb := end + _b * 0.4
	_mode = M_STONE
	var pa := Vector3(ga.x, ey, ga.y)
	var pb := Vector3(gb.x, ey, gb.y)
	var pc := Vector3(rr.x, yard + ZAMEK_U_RIDGE, rr.y)
	var nrm := (pb - pa).cross(pc - pa).normalized()
	if nrm.y < 0.0:
		nrm = -nrm
	_tri(pa, pb, pc, nrm, Color(ZAMEK_ROOF), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_mode = M_STONE
	_g = yard
	var top := yard + ZAMEK_U_EAVE
	var a := _w(0.0, 0.0)
	var b := _w(len, 0.0)
	var foot := _zamek_foot(a, b)
	_wall(a, b, foot, yard + 4.6, _b, ZV_RUSTIC)
	_wall(a, b, yard + 4.6, top, _b, ZAMEK_VISTULA)
	kit_face(0.0)
	kit_bands(0.0, len, foot, yard + 4.4, 0.55, ZV_RUSTIC)
	kit_ledge(0.0, len, yard + 4.45, 0.4, ZAMEK_CREAM, 0.14)
	kit_ledge(0.0, len, yard + 10.7, 0.3, ZAMEK_CREAM, 0.1)
	kit_cornice(0.0, len, top, ZAMEK_CREAM, 0.6, 0.7)
	for u: float in _spread(0.0, len, roundi(len / ZAMEK_BAY)):
		kit_window(u, yard + 1.4, 1.6, Win.SILL, ZAMEK_CREAM, ZV_GLASS, 0.55)
		kit_window(u, yard + 5.2, 2.6, Win.PEDIMENT, ZAMEK_CREAM, ZV_GLASS, 0.62)
		kit_window(u, yard + 9.0, 2.2, Win.SILL_HEAD, ZAMEK_CREAM, ZV_GLASS, 0.58)
		kit_window(u, yard + 12.4, 1.5, Win.FRAMED, ZAMEK_CREAM, ZV_GLASS, 0.5)
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_face = 0.0


## The three smaller towers seen over the roofs: the south-east corner tower (shader windows, cream
## quoins, a copper square bell, a lantern, a gilt spire), the Grodzka Tower (a bulb, an open lantern,
## an onion, a spire) and the north wing tower (a copper pyramid and a gilt ball).
func _zamek_towers(yard: float) -> void:
	var none := Color(0, 0, 0, 0)
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_mode = M_STONE
	# the SE tower (fix round 1: 9.5 m square, east and south faces of the projection, to 11.0 m over the
	# yard: it stands on the low slope), from the low ground. The south wing's outer wall east of the
	# south front (x -604.7 to O3) is the mass's, a shader face, since the tower no longer hides it.
	_zamek_face(Vector2(-604.7, -1473.5), ZAMEK_U_OUT[3], Vector2(0, 1), yard + ZAMEK_U_EAVE, ZAMEK_PLASTER)
	var r := ZAMEK_SE_TOWER
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	var top := yard + 11.0
	var ring := PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])
	_zamek_face(Vector2(x1, z0), Vector2(x1, z1), Vector2(1, 0), top, ZAMEK_PLASTER)
	_zamek_face(Vector2(x1, z1), Vector2(x0, z1), Vector2(0, 1), top, ZAMEK_PLASTER)
	_zamek_face(Vector2(x0, z1), Vector2(x0, z0), Vector2(-1, 0), top, ZAMEK_PLASTER)
	_zamek_face(Vector2(x0, z0), Vector2(x1, z0), Vector2(0, -1), top, ZAMEK_PLASTER)
	_mode = M_STONE
	var foot := _zamek_foot(Vector2(x0, z1), Vector2(x1, z1))
	for c: Vector2 in ring:
		_lbox(c.x, c.y, 0.35, 0.35, foot, top, ZAMEK_CREAM)
	kit_cornice_ring(ring, top, ZAMEK_CREAM, 0.35, 0.45)
	var cx := r.get_center().x
	var cz := r.get_center().y
	var tile := Color(ZAMEK_COPPER)
	var sq := func(h: float) -> PackedVector2Array:
		return PackedVector2Array([Vector2(cx - h, cz - h), Vector2(cx + h, cz - h), Vector2(cx + h, cz + h), Vector2(cx - h, cz + h)])
	var bell := PackedVector2Array([Vector2(x0 - 0.3, z0 - 0.3), Vector2(x1 + 0.3, z0 - 0.3), Vector2(x1 + 0.3, z1 + 0.3), Vector2(x0 - 0.3, z1 + 0.3)])
	_frustum(bell, top, sq.call(3.6), yard + 13.2, tile)
	_frustum(sq.call(3.6), yard + 13.2, sq.call(0.9), yard + 16.0, tile.lightened(0.03), tile.darkened(0.05))
	_mode = M_GOLD
	var cc := Vector2(cx, cz)
	_prism(_circle(cc, 0.5, 6), yard + 16.0, yard + 16.9, ZAMEK_GILT, ZAMEK_GILT, M_GOLD, M_GOLD)
	_prism(_circle(cc, 0.07, 6), yard + 16.8, yard + 17.2, ZAMEK_GILT, ZAMEK_GILT, M_GOLD, M_GOLD)
	_mode = M_STONE
	_collide(ring)
	# the Grodzka Tower: a 7 m shaft square to wing E, to 25.0 m
	var ga: Vector2 = ((ZAMEK_U_IN[4] as Vector2) - (ZAMEK_U_IN[3] as Vector2)).normalized()
	_o = ZAMEK_GRODZKA
	_a = ga
	_b = Vector2(-ga.y, ga.x)
	var gtop := yard + 25.0
	_lbox(0.0, 0.0, 3.5, 3.5, yard + 15.4, gtop, ZAMEK_PLASTER)
	for su: float in [-1.0, 1.0]:
		for sv: float in [-1.0, 1.0]:
			_lbox(su * 3.5, sv * 3.5, 0.35, 0.35, yard + 15.4, gtop, ZAMEK_CREAM)
	kit_cornice_ring(_rect(0.0, 0.0, 3.5, 3.5), gtop, ZAMEK_CREAM, 0.35, 0.45)
	_zamek_shaft_lights(ZAMEK_GRODZKA, ga, 3.5, [yard + 18.0, yard + 21.5], 1.8, 0.5)
	_frustum(_circle(ZAMEK_GRODZKA, 3.7, 8), gtop + 0.35, _circle(ZAMEK_GRODZKA, 3.9, 8), yard + 25.6, tile.darkened(0.04))
	for prof: Array in [[3.9, 25.6, 4.2, 26.8], [4.2, 26.8, 1.4, 29.0]]:
		_frustum(_circle(ZAMEK_GRODZKA, float(prof[0]), 8), yard + float(prof[1]), _circle(ZAMEK_GRODZKA, float(prof[2]), 8),
				yard + float(prof[3]), tile, tile.lightened(0.04) if float(prof[3]) > 28.0 else none)
	_prism(_circle(ZAMEK_GRODZKA, 1.2, 8), yard + 29.0, yard + 31.6, ZAMEK_CREAM, ZAMEK_CREAM.darkened(0.08), M_MONUMENT, M_STONE)
	_mode = M_STONE
	var onion := [[1.5, 31.6], [1.9, 32.1], [1.2, 32.6], [0.3, 33.0]]
	for k in onion.size() - 1:
		_frustum(_circle(ZAMEK_GRODZKA, float(onion[k][0]), 8), yard + float(onion[k][1]),
				_circle(ZAMEK_GRODZKA, float(onion[k + 1][0]), 8), yard + float(onion[k + 1][1]), tile)
	_prism(_circle(ZAMEK_GRODZKA, 0.08, 6), yard + 32.9, yard + 35.5, ZAMEK_GILT, ZAMEK_GILT, M_GOLD, M_GOLD)
	_prism(_circle(ZAMEK_GRODZKA, 0.3, 6), yard + 34.2, yard + 34.7, ZAMEK_GILT, ZAMEK_GILT, M_GOLD, M_GOLD)
	# the north wing tower, a cream gabled risalit on B's yard face (fix round 1): the 4.5 m shaft out of
	# the roof to 18.9 m, a copper pyramid to 22.0 m under the 22.8 m ridge, a small gilt ball
	_mode = M_STONE
	_o = ZAMEK_NORTH_TOWER
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	var ntop := yard + 18.9
	_lbox(0.0, 0.0, 2.25, 2.25, yard + 15.0, ntop, ZAMEK_VISTULA)
	for su: float in [-1.0, 1.0]:
		for sv: float in [-1.0, 1.0]:
			_lbox(su * 2.25, sv * 2.25, 0.3, 0.3, yard + 15.0, ntop, ZAMEK_CREAM)
	kit_cornice_ring(_rect(0.0, 0.0, 2.25, 2.25), ntop - 0.5, ZAMEK_CREAM, 0.3, 0.4)
	_zamek_shaft_lights(ZAMEK_NORTH_TOWER, Vector2(1, 0), 2.25, [yard + 17.4], 0.9, 0.3)
	_mode = M_STONE
	_pyramid(_rect(0.0, 0.0, 2.5, 2.5), ntop, yard + 22.0, tile)
	_mode = M_GOLD
	_prism(_circle(ZAMEK_NORTH_TOWER, 0.3, 6), yard + 22.0, yard + 22.5, ZAMEK_GILT, ZAMEK_GILT, M_GOLD, M_GOLD)
	_mode = M_STONE
	_o = Vector2.ZERO
	_face = 0.0


## One framed kit window per face of a square tower of half width `half` round `c`, its first axis
## along `a`, at each sill in `sills`.
func _zamek_shaft_lights(c: Vector2, a: Vector2, half: float, sills: Array, h: float, hw: float) -> void:
	var b := Vector2(-a.y, a.x)
	for n: Vector2 in [a, b, -a, -b]:
		_o = c + n * half
		_b = n
		_a = Vector2(-n.y, n.x)
		_face = 0.0
		for y: float in sills:
			kit_window(0.0, y, h, Win.FRAMED, ZAMEK_CREAM, ZAMEK_PANE, hw)
	_face = 0.0


## The roof's small things: white chimneys (one every 8 m along A's crest and the U's ridge, 1.2 m off it
## on alternate sides, 1.4 m over the ridge, the base 1.5 m under the slope) and 18 dormers on the
## courtyard slopes of the north and south wings.
func _zamek_roof_details(yard: float) -> void:
	_mode = M_STONE
	var saxon := _zamek_saxon_ring()
	var keep_out: Array[Vector2] = [ZAMEK_GRODZKA, ZAMEK_NORTH_TOWER, ZAMEK_SE_TOWER.get_center(), ZAMEK_CLOCK]
	for t: Vector2 in ZAMEK_TURRETS:
		keep_out.append(t)
	var ridges: Array = [[ZAMEK_CREST_A, ZAMEK_CREST_B, ZAMEK_CREST, 0.75, false]]
	for i in 4:
		ridges.append([((ZAMEK_U_OUT[i] as Vector2) + (ZAMEK_U_IN[i] as Vector2)) * 0.5,
				((ZAMEK_U_OUT[i + 1] as Vector2) + (ZAMEK_U_IN[i + 1] as Vector2)) * 0.5, ZAMEK_U_RIDGE, 0.9, true])
	var k := 0
	for rd: Array in ridges:
		var p0: Vector2 = rd[0]
		var p1: Vector2 = rd[1]
		var len := p0.distance_to(p1)
		var d := (p1 - p0) / len
		var s := 4.0
		while s < len - 3.0:
			var q := p0 + d * s + Vector2(-d.y, d.x) * (1.2 if k % 2 == 0 else -1.2)
			k += 1
			s += 8.0
			var blocked := bool(rd[4]) and Geometry2D.is_point_in_polygon(q, saxon)
			for t: Vector2 in keep_out:
				if q.distance_to(t) < 4.0 + (4.0 if t == ZAMEK_SE_TOWER.get_center() else 0.0):
					blocked = true
			if blocked:
				continue
			var ridge_y: float = yard + float(rd[2])
			_o = q
			_a = d
			_b = Vector2(-d.y, d.x)
			_lbox(0.0, 0.0, 0.65, 0.35, ridge_y - float(rd[3]) - 1.5, ridge_y + 1.4, ZAMEK_CHIMNEY)
			_lbox(0.0, 0.0, 0.78, 0.48, ridge_y + 1.4, ridge_y + 1.58, ZAMEK_CHIMNEY.darkened(0.08))
	# the dormers: 9 on each yard slope, from 6 m in from the wing's ends, 40 % up the slope
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	for wing: Array in [[0, 1, 44.0], [2, 3, 53.5]]:
		var ia := wing[0] as int
		var ib := wing[1] as int
		var i_a: Vector2
		var i_b: Vector2
		var r_a: Vector2
		var r_b: Vector2
		if ia == 0:  # the north wing: from the yard's NW corner along the inner edge towards A
			i_a = ZAMEK_U_IN[1]
			i_b = ZAMEK_U_IN[0]
			r_a = ((ZAMEK_U_OUT[1] as Vector2) + (ZAMEK_U_IN[1] as Vector2)) * 0.5
			r_b = ((ZAMEK_U_OUT[0] as Vector2) + (ZAMEK_U_IN[0] as Vector2)) * 0.5
		else:  # the south wing: from the SW corner east
			i_a = ZAMEK_U_IN[2]
			i_b = ZAMEK_U_IN[3]
			r_a = ((ZAMEK_U_OUT[2] as Vector2) + (ZAMEK_U_IN[2] as Vector2)) * 0.5
			r_b = ((ZAMEK_U_OUT[3] as Vector2) + (ZAMEK_U_IN[3] as Vector2)) * 0.5
		var edge_len := i_a.distance_to(i_b)
		var run := float(wing[2])
		for m in 9:
			var dist := 6.0 + (run - 12.0) * float(m) / 8.0
			var s := dist / edge_len
			var pin := i_a.lerp(i_b, s)
			var pr := r_a.lerp(r_b, s)
			var out := (pin - pr).normalized()
			var at := (pin + out * 0.4).lerp(pr, 0.4)
			if at.distance_to(ZAMEK_NORTH_TOWER) < 3.4:
				# the one the north tower stands on is left out: any other spot on B's slope runs into the
				# valleys of A's roof or the wing's end (a coplanar hip), so B keeps 8 (escalated)
				continue
			kit_dormer(at, out, yard + ZAMEK_U_EAVE + 0.4 * (ZAMEK_U_RIDGE - ZAMEK_U_EAVE), ZAMEK_DORMER, ZAMEK_CREAM.lightened(0.05), ZAMEK_PANE)
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_face = 0.0


## A flat strip between two parallel segments (a cornice's top), through `_cap` so the strips of
## two edges meeting at a corner don't overlap (z-fight).
func _ledge(a: Vector2, b: Vector2, c: Vector2, d: Vector2, y: float, col: Color) -> void:
	var quad := PackedVector2Array([a, b, d, c])
	if Geometry2D.is_polygon_clockwise(quad):
		quad.reverse()
	_cap(quad, y, col)


## The Clock Tower: the shaft (0.3 m proud of the mapped one) with cream quoins and string
## courses, the gate to the courtyard, the balcony (stone slab, iron rail) two thirds up, a dial on every face, the
## cornice with a gilt frieze, then the helm: the copper onion, the open lantern, a second onion,
## the spire with two gilt balls and a flag (56 m).
func _zamek_clock_tower() -> void:
	_o = ZAMEK_CLOCK
	_a = ZAMEK_FRONT
	_b = Vector2(_a.y, -_a.x)  # out of the front, west to Plac Zamkowy
	var sq := _w(0.0, 9.0)
	var g: float = map.terrain_height(sq.x, sq.y)
	_g = g
	var wall := Color(ZAMEK_WALL)
	var h := 4.6
	# the shaft plain, then the shader's windows on the three faces that carry no kit windows (the
	# west face has its own kit windows: never two grids on one face, the Roesslera lesson)
	_lbox(0.0, 0.0, h, h, g - 0.6, g + 29.5, wall, M_STONE, wall)
	_mode = M_MONUMENT
	_wall(_w(h + 0.02, -h), _w(h + 0.02, h), g + 6.4, g + 29.5, _a, wall)
	_wall(_w(-h - 0.02, h), _w(-h - 0.02, -h), g + 6.4, g + 29.5, -_a, wall)
	_wall(_w(h, -h - 0.02), _w(-h, -h - 0.02), g + 6.4, g + 29.5, -_b, wall)
	for su: float in [-1.0, 1.0]:
		for sv: float in [-1.0, 1.0]:
			_lbox(su * h, sv * h, 0.45, 0.45, g + 0.3, g + 29.5, ZAMEK_CREAM, M_STONE, ZAMEK_CREAM)
	for y: float in [12.6, 19.0]:
		_lbox(0.0, 0.0, h + 0.2, h + 0.2, g + y, g + y + 0.45, ZAMEK_CREAM, M_STONE, ZAMEK_CREAM)
	# the gate: a cream rusticated surround, the dark passage
	_mode = M_STONE
	_wall(_w(-2.8, h + 0.05), _w(2.8, h + 0.05), g - 0.3, g + 6.4, _b, ZAMEK_CREAM)
	_wall(_w(-2.0, h + 0.1), _w(2.0, h + 0.1), g - 0.3, g + 5.0, _b, ZAMEK_GATE)
	_lbox(0.0, h + 0.15, 0.7, 0.15, g + 5.4, g + 6.2, ZAMEK_GILT, M_STONE, ZAMEK_GILT)
	# the balcony on the square's side: a cream stone slab resting on the upper string course (its
	# underside at the course's top, so it reads as part of the shaft, not stuck on), the iron railing
	# over it (F 2026-11-26: the old black slab floated half a metre over the course)
	kit_face(h)
	kit_balcony(0.0, g + 19.71, 1.5, Balcony.IRON, ZAMEK_IRON, ZAMEK_CREAM, 0.8)
	# the west face's windows (the reviewer's fix): one per stage between the string courses, over the
	# gate's cornice, 1.0 x 2.0 m framed, and a door window over the balcony
	for sill: float in [8.4, 14.8]:
		kit_window(0.0, g + sill, 2.0, Win.FRAMED, ZAMEK_CREAM.lightened(0.08), ZAMEK_PANE, 0.5)
	kit_window(0.0, g + 20.3, 1.1, Win.FRAMED, ZAMEK_CREAM.lightened(0.08), ZAMEK_PANE, 0.5)
	kit_face(0.0)
	# the dials, one on each face
	for f: Vector2 in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
		var nrm := _a * f.x + _b * f.y
		_zamek_clock(_w(f.x * (h + 0.02), f.y * (h + 0.02)), g + 24.0, nrm)
	_lbox(0.0, 0.0, h + 0.4, h + 0.4, g + 29.5, g + 30.3, ZAMEK_CREAM, M_STONE, ZAMEK_CREAM)
	_lbox(0.0, 0.0, h + 0.15, h + 0.15, g + 30.3, g + 30.7, ZAMEK_GILT, M_STONE, ZAMEK_GILT)
	# the helm
	var c := ZAMEK_CLOCK
	_mode = M_STONE
	var prof := [[4.4, 30.7], [4.4, 32.0], [5.0, 33.6], [4.6, 35.2], [3.2, 37.0], [1.9, 38.4]]
	for k in prof.size() - 1:
		_frustum(_circle(c, float(prof[k][0]), 8), g + float(prof[k][1]), _circle(c, float(prof[k + 1][0]), 8),
				g + float(prof[k + 1][1]), ZAMEK_COPPER.lightened(0.03 * k), ZAMEK_COPPER)
	_prism(_circle(c, 1.8, 8), g + 38.4, g + 42.0, ZAMEK_CREAM, Color(0, 0, 0, 0), M_MONUMENT)
	_prism(_circle(c, 2.05, 8), g + 42.0, g + 42.4, ZAMEK_CREAM, ZAMEK_COPPER, M_STONE, M_STONE)
	_mode = M_STONE
	var cap := [[1.6, 42.4], [2.1, 43.4], [1.6, 44.6], [0.6, 45.8], [0.2, 46.4]]
	for k in cap.size() - 1:
		_frustum(_circle(c, float(cap[k][0]), 8), g + float(cap[k][1]), _circle(c, float(cap[k + 1][0]), 8),
				g + float(cap[k + 1][1]), ZAMEK_COPPER, ZAMEK_COPPER)
	_prism(_circle(c, 0.14, 4), g + 46.4, g + 55.6, ZAMEK_COPPER, ZAMEK_COPPER, M_STONE, M_STONE)
	for y: float in [49.6, 55.6]:
		_prism(_circle(c, 0.42, 6), g + y, g + y + 0.75, ZAMEK_GILT, ZAMEK_GILT, M_STONE, M_STONE)
	_wall(c + _a * 0.15, c + _a * 1.6, g + 53.6, g + 54.6, _b, ZAMEK_COPPER)
	_wall(c + _a * 1.6, c + _a * 0.15, g + 53.6, g + 54.6, -_b, ZAMEK_COPPER)
	_o = ZAMEK_CLOCK
	_collide(_rect(0.0, 0.0, h, h))


## One face of the Clock Tower's clock (Zegar Wieży Zygmuntowskiej, the oldest in Warsaw's public
## spaces): a square cream stone panel on the plaster so it reads from the square, a gilt rim, a
## cream face with dark numerals, and the hands at ten past ten. `n` points out of the face.
func _zamek_clock(c: Vector2, y: float, n: Vector2) -> void:
	var side := Vector2(-n.y, n.x)
	_mode = M_STONE
	var pa := c - side * 2.5 + n * 0.06
	var pb := c + side * 2.5 + n * 0.06
	_wall(pa, pb, y - 2.5, y + 2.5, n, ZAMEK_CREAM)
	var pa2 := c - side * 2.1 + n * 0.11
	var pb2 := c + side * 2.1 + n * 0.11
	_wall(pa2, pb2, y - 2.1, y + 2.1, n, ZAMEK_GILT.darkened(0.15))
	_dial(c + n * 0.14, y, n, 1.95, Color("#f4ecd6"), Color("#2a2220"))
	# the hands: hour towards ten, minute towards two, as thin dark bars from the middle
	var n3 := Vector3(n.x, 0.0, n.y)
	var s3 := Vector3(side.x, 0.0, side.y)
	var mid := Vector3(c.x, y, c.y) + n3 * 0.36
	for hand: Array in [[0.55, 0.83, 1.0, 0.1], [-0.5, 0.87, 1.55, 0.07]]:
		var dir := s3 * float(hand[0]) + Vector3.UP * float(hand[1])
		var wide := dir.cross(n3).normalized() * float(hand[3])
		var lift := n3 * (0.04 if float(hand[0]) < 0.0 else 0.0)  # the minute hand over the hour hand
		var tip := mid + lift + dir.normalized() * float(hand[2])
		_quad(mid + lift - wide, mid + lift + wide, tip + wide * 0.4, tip - wide * 0.4, n3, Color("#2a2220"))


## A corner turret of the west front: a square shaft out of the roof with cream quoins, a
## cornice, a bulbous copper cap, a small open lantern, a cap and a spire with a gilt ball (31 m).
func _zamek_turret(c: Vector2) -> void:
	_o = c
	_a = ZAMEK_FRONT
	_b = Vector2(_a.y, -_a.x)
	var sq := _w(0.0, 7.0)
	var g: float = map.terrain_height(sq.x, sq.y)
	_g = g
	var wall := Color(ZAMEK_WALL)
	_lbox(0.0, 0.0, 2.25, 2.25, g - 0.5, g + 20.5, wall, M_MONUMENT, wall)  # from the ground, inside the mass
	_collide(_rect(0.0, 0.0, 2.25, 2.25))
	for su: float in [-1.0, 1.0]:
		for sv: float in [-1.0, 1.0]:
			_lbox(su * 2.25, sv * 2.25, 0.3, 0.3, g + 11.0, g + 20.5, ZAMEK_CREAM, M_STONE, ZAMEK_CREAM)
	_lbox(0.0, 0.0, 2.55, 2.55, g + 20.5, g + 21.1, ZAMEK_CREAM, M_STONE, ZAMEK_CREAM)
	_mode = M_STONE
	var prof := [[2.1, 21.1], [2.6, 22.3], [2.2, 23.4], [1.2, 24.5], [0.75, 25.0]]
	for k in prof.size() - 1:
		_frustum(_circle(c, float(prof[k][0]), 8), g + float(prof[k][1]), _circle(c, float(prof[k + 1][0]), 8),
				g + float(prof[k + 1][1]), ZAMEK_COPPER.lightened(0.03 * k), ZAMEK_COPPER)
	_prism(_circle(c, 0.7, 6), g + 25.0, g + 26.6, ZAMEK_CREAM, Color(0, 0, 0, 0), M_STONE)
	_frustum(_circle(c, 0.9, 6), g + 26.6, _circle(c, 0.15, 6), g + 28.2, ZAMEK_COPPER)
	_prism(_circle(c, 0.08, 4), g + 28.2, g + 30.6, ZAMEK_COPPER, ZAMEK_COPPER, M_STONE, M_STONE)
	_prism(_circle(c, 0.3, 6), g + 29.2, g + 29.8, ZAMEK_GILT, ZAMEK_GILT, M_STONE, M_STONE)


## The tubs of the Upper Garden's terrace (Krajobraz's design: "a row of tubs with spherical trees
## marks the terrace edges"): one every 4 m along the Vistula front.
func _zamek_tubs() -> void:
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	var a: Vector2 = ZAMEK_TUBS[0]
	var b: Vector2 = ZAMEK_TUBS[1]
	var n := maxi(int(a.distance_to(b) / 4.0), 1)
	for k in n + 1:
		var p := a.lerp(b, float(k) / n)
		_tub(p, float(map.terrain_height(p.x, p.y)), k)


## A garden tub with a ball-headed tree (a clipped maple on a bare stem): a painted barrel with a
## white rim, the stem, the ball.
const TUB_PAINT := [Color("#b8473a"), Color("#4c6b4a"), Color("#4c6b4a")]
const TUB_RIM := Color("#efece4")
const TUB_LEAF := Color("#4f7f36")
const TUB_BARK := Color("#5a4636")


func _tub(p: Vector2, g: float, k: int) -> void:
	_g = g
	var none := Color(0, 0, 0, 0)
	_prism(_square(p, 0.45), g, g + 0.6, TUB_PAINT[k % TUB_PAINT.size()], none, M_STONE)
	_prism(_square(p, 0.48), g + 0.6, g + 0.78, TUB_RIM, TUB_BARK, M_STONE, M_STONE)
	_prism(_square(p, 0.06), g + 0.78, g + 2.0, TUB_BARK, none, M_STONE)
	_mode = M_STONE
	_frustum(_circle(p, 0.35, 6), g + 1.9, _circle(p, 0.78, 6), g + 2.45, TUB_LEAF.darkened(0.08))
	_frustum(_circle(p, 0.78, 6), g + 2.45, _circle(p, 0.32, 6), g + 3.05, TUB_LEAF, TUB_LEAF.lightened(0.06))


# --- Arkady Kubickiego and the castle gardens ---------------------------------------------------

## Kubicki's Arcades (Jakub Kubicki, 1818-1821) under the castle's Vistula terrace, and the gardens
## Ogród Park Krajobraz restored on and below them (krajobraz.com.pl/projekt/zamek-krolewski: the
## Upper Garden on the arcades' vault, 2015; the Lower Garden down to Wisłostrada, 2019). The
## mapped building stood as a grey box; the model is the arcade wall facing the Lower Garden in
## terracotta plaster with cream-ringed round arches every 12 m, a cream cornice and an iron
## railing, the white stone portal block in the middle, and the Upper Garden's lawn on its top at
## the terrace's level; then tubbed ball trees along the terrace edge and white vases on pedestals
## round the Lower Garden's sunken lawn carpet (its grass is map_builder's LAWN_CARPETS). The
## gardens' hedges, paths and flowerbeds are the map's own; the fountains are park_details'.
## Spec docs/landmarks/specs/zamek.md "Gardens".
const ARK_PLASTER := Color("#c8693f")
const ARK_STONE := Color("#e4dfd2")
const ARK_LAWN := Color("#74a24c")
const ARK_DARK := Color("#3a2c26")
const ARK_GRAVEL := Color("#cfcbc0")
const ARK_WATER := Color("#5ea8d8")
## The Upper Garden's big fountain (a tulip bowl in a round basin), on the vault.
const ARK_FOUNTAIN := Vector2(-556.8, -1585.8)
## The portal block's middle (the mapped outline's bump on its east side).
const ARK_PORTAL := Vector2(-546.9, -1590.0)
## The Lower Garden's white vases, both long sides of the lawn carpet: on the round beds the map
## has there (map_builder draws their rings low, GARDEN_RINGS).
const ARK_VASES := [Vector2(-520.4, -1580.7), Vector2(-507.6, -1585.8), Vector2(-492.3, -1591.9),
		Vector2(-478.1, -1597.4), Vector2(-463.5, -1603.2), Vector2(-449.0, -1608.9), Vector2(-534.4, -1614.5),
		Vector2(-521.6, -1619.5), Vector2(-506.2, -1625.6), Vector2(-492.0, -1631.2), Vector2(-477.5, -1637.0),
		Vector2(-462.8, -1642.7)]
## Fountains on the ground (in the map's basin rings): the Upper Garden's small one by the castle
## and the one in the Lower Garden's west hedge quarter; centre, water radius.
const ARK_POOLS := [[Vector2(-585.5, -1574.5), 1.0], [Vector2(-537.5, -1656.4), 2.0]]
## The site's reach: the arcades and both gardens (the sectors build what lies in it).
const ARK_BOX := Rect2(-612.0, -1700.0, 162.0, 215.0)


func _find_arkady() -> void:
	var outline := _landmark("Arkady Kubickiego")
	if outline.size() < 3:
		return
	_add_site("arkady", [outline])
	if not sites.is_empty() and sites[-1]["key"] == "arkady":
		sites[-1]["box"] = (sites[-1]["box"] as Rect2).merge(ARK_BOX)


func _build_arkady(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["zone"][0]
	if ring.size() < 3:
		return
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	var n := ring.size()
	# the two levels: the Lower Garden at the wall's foot, the terrace on its top
	var low := INF
	var up := -INF
	for i in n:
		var p := ring[i]
		var q := ring[(i + 1) % n]
		if p.distance_to(q) < 0.5:
			continue
		var out := _out(ring, p, q)
		var m := (p + q) * 0.5
		if out.x > 0.3:
			low = minf(low, map.terrain_height(m.x + out.x * 3.0, m.y + out.y * 3.0))
		elif out.x < -0.3:
			up = maxf(up, map.terrain_height(m.x + out.x * 6.0, m.y + out.y * 6.0))
	if low == INF:
		low = _ground_under(ring)
	if up == -INF:
		up = low
	var top := maxf(up + 0.15, low + 7.5)
	_g = low
	var run := 0.0
	for i in n:
		var p := ring[i]
		var q := ring[(i + 1) % n]
		var len := p.distance_to(q)
		if len < 0.3:
			continue
		var out := _out(ring, p, q)
		var foot: float = minf(map.terrain_height(p.x + out.x, p.y + out.y), map.terrain_height(q.x + out.x, q.y + out.y)) - 0.5
		var portal := ((p + q) * 0.5).distance_to(ARK_PORTAL) < 9.5
		var face := ARK_STONE if portal else ARK_PLASTER
		_mode = M_STONE
		_wall(p, q, foot, top - 0.7, out, face if out.x > 0.3 else ARK_PLASTER.darkened(0.06), run)
		_wall(p + out * 0.25, q + out * 0.25, top - 0.7, top, out, ARK_STONE, run)
		_ledge(p, q, p + out * 0.25, q + out * 0.25, top, ARK_STONE)
		if out.x > 0.3:
			# the arches: round-headed, ringed in cream, one every 12 m (a big one in the portal)
			if portal and len > 4.0:
				_ark_arch(p, q, out, len * 0.5, 3.5, foot + 0.5, minf(top - 1.2, foot + 6.8))
			elif len >= 8.0:
				var count := maxi(floori(len / 12.0), 1)
				for k in count:
					_ark_arch(p, q, out, (k + 0.5) * len / count, 3.0, foot + 0.5, minf(top - 1.5, foot + 5.5))
			# the railing on the edge, a post at each end
			var ra := p + out * 0.1
			var rb := q + out * 0.1
			for post: Vector2 in [ra, rb]:
				_prism(_square(post, 0.05), top, top + 1.0, ZAMEK_IRON, ZAMEK_IRON, M_STONE, M_STONE)
			for side: float in [1.0, -1.0]:
				_wall(ra if side > 0.0 else rb, rb if side > 0.0 else ra, top + 0.9, top + 1.0, out * side, ZAMEK_IRON)
				_wall(ra if side > 0.0 else rb, rb if side > 0.0 else ra, top, top + 0.12, out * side, ZAMEK_IRON)
		run += len
	# the Upper Garden on the vault: where the terrain has no terrace (the cloud's flat ground) the
	# vault gets a lawn of its own; the gravel walk along the edge always (it hides the terrain's
	# slope down to the wall's top)
	if top > up + 1.0:
		_cap(ring, top + 0.01, ARK_LAWN)
	for i in n:
		var p := ring[i]
		var q := ring[(i + 1) % n]
		if p.distance_to(q) < 0.3:
			continue
		var out := _out(ring, p, q)
		if out.x > 0.3:
			_ledge(p, q, p - out * 3.5, q - out * 3.5, top + 0.06, ARK_GRAVEL)
	_ark_fountain(ARK_FOUNTAIN, top)
	# tubs along the terrace edge, 3 m in from the railing, one every 10 m
	var tub_k := 0
	for i in n:
		var p := ring[i]
		var q := ring[(i + 1) % n]
		var len := p.distance_to(q)
		var out := _out(ring, p, q)
		if out.x <= 0.3 or len < 10.0 or ((p + q) * 0.5).distance_to(ARK_PORTAL) < 9.5:
			continue
		var count := floori(len / 10.0)
		for j in count:
			var t := (j + 0.5) / count
			_tub(p.lerp(q, t) - out * 3.0, top, tub_k)
			tub_k += 1
	# the Lower Garden's vases round the lawn carpet, the fountains' water
	for v: Vector2 in ARK_VASES:
		_vase(v, float(map.terrain_height(v.x, v.y)))
	for pool: Array in ARK_POOLS:
		var pc: Vector2 = pool[0]
		var pr: float = pool[1]
		var py: float = map.terrain_height(pc.x, pc.y)
		_g = py
		_cap(_circle(pc, pr, 10), py + 0.38, ARK_WATER)
		_prism(_circle(pc, 0.07, 4), py + 0.38, py + 1.6, ARK_WATER.lightened(0.5), ARK_WATER.lightened(0.6), M_STONE, M_STONE)
	_g = low
	_collide(ring)


## A round-headed arch on the wall p→q: a cream ring and the dark opening inside it, `at` metres
## along the wall, half as wide as `half`, from y0 to the crown at y1 (the head a half circle).
func _ark_arch(p: Vector2, q: Vector2, out: Vector2, at: float, half: float, y0: float, y1: float) -> void:
	var d := (q - p).normalized()
	var mid := p + d * at
	var n3 := Vector3(out.x, 0.0, out.y)
	for layer in 2:
		var push := 0.04 if layer == 0 else 0.08
		var hw := half + 0.45 if layer == 0 else half
		var crown := y1 + 0.45 if layer == 0 else y1
		var col := ARK_STONE if layer == 0 else ARK_DARK
		var spring := crown - hw
		var l := mid - d * hw + out * push
		var r := mid + d * hw + out * push
		_quad(Vector3(l.x, y0, l.y), Vector3(r.x, y0, r.y), Vector3(r.x, spring, r.y), Vector3(l.x, spring, l.y), n3, col)
		var c := Vector3(mid.x + out.x * push, spring, mid.y + out.y * push)
		var seg := 6
		for s in seg:
			var t0 := PI * s / seg
			var t1 := PI * (s + 1) / seg
			var e0 := Vector3(d.x * cos(t0), sin(t0), d.y * cos(t0)) * hw
			var e1 := Vector3(d.x * cos(t1), sin(t1), d.y * cos(t1)) * hw
			_tri(c, c + e0, c + e1, n3, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## The Upper Garden's fountain: a round stone basin 6 m across with its water, a tulip bowl on a
## stem in the middle, a jet.
func _ark_fountain(c: Vector2, y: float) -> void:
	_g = y
	_prism(_circle(c, 3.6, 10), y, y + 0.15, ARK_GRAVEL.darkened(0.05), ARK_GRAVEL, M_STONE, M_STONE)
	_prism(_circle(c, 3.1, 10), y + 0.15, y + 0.6, ARK_STONE, ARK_STONE, M_STONE, M_STONE)
	_cap(_circle(c, 2.8, 10), y + 0.62, ARK_WATER)
	_mode = M_STONE
	_frustum(_circle(c, 0.25, 6), y + 0.6, _circle(c, 0.3, 6), y + 1.3, ARK_STONE)
	_frustum(_circle(c, 0.3, 8), y + 1.3, _circle(c, 1.1, 8), y + 1.8, ARK_STONE, ARK_WATER)
	_prism(_circle(c, 0.07, 4), y + 1.8, y + 2.7, ARK_WATER.lightened(0.5), ARK_WATER.lightened(0.6), M_STONE, M_STONE)


## A white garden vase on a square pedestal.
func _vase(p: Vector2, g: float) -> void:
	_g = g
	_prism(_square(p, 0.32), g - 0.1, g + 1.0, ARK_STONE.darkened(0.04), ARK_STONE, M_STONE, M_STONE)
	_mode = M_STONE
	_frustum(_circle(p, 0.16, 6), g + 1.0, _circle(p, 0.4, 6), g + 1.5, ARK_STONE)
	_frustum(_circle(p, 0.4, 6), g + 1.5, _circle(p, 0.3, 6), g + 1.85, ARK_STONE, ARK_DARK.lightened(0.2))


## The Barbican (Barbakan; Gianbattista of Venice's brick outwork of 1548 in front of the Nowomiejska
## gate, burned down in 1944 and rebuilt in 1952-1954): a model instead of a skin. The mapped
## outline is a C of wall 3.5 m thick opening to the east; it is drawn as one brick-Gothic wall
## (`M_GOTHIC`: buttresses and lancets) with a crenellated parapet and four octagonal turrets with
## conical roofs on its curve. Spec docs/landmarks/specs/barbakan.md. Heights are estimates (no LoD2
## in the cloud).
const BARB_WALL := Color("#b2604a")  # F's photos 2026-11-08: a warmer orange-red brick
const BARB_ROOF := Color("#a9502f")   # photos 1-2 and the ortho: terracotta tile
const BARB_STONE := Color("#c4b69a")
const BARB_HEIGHT := 9.5
const BARB_TOWER_H := 13.0
const BARB_TOWER_R := 2.2
## The turrets' centres on the wall's mid-line, world x and z.
## F's photos (2026-11-08): the four towers stand in two pairs on the arms toward the city, at
## the mapped 13 m tower outlines (the 2026-11-02 spots were guesses), radius 2.2 m.
const BARB_TOWERS := [Vector2(-946.8, -1827.5), Vector2(-938.4, -1825.1), Vector2(-939.4, -1841.6), Vector2(-930.5, -1836.5)]
## The round bastion's centre (the C's west end); the arms' centre lines, tower to tower; the
## arms' half thickness; the passage's middle; the grille and passage colours.
const BARB_BASTION := Vector2(-949.4, -1837.2)
const BARB_ARMS := [[Vector2(-950.5, -1831.3), Vector2(-934.5, -1826.2)], [Vector2(-947.5, -1843.6), Vector2(-931.5, -1835.3)]]
const BARB_ARM_HALF := 1.75
const BARB_PASSAGE_MID := Vector2(-941.0, -1833.5)
const BARB_GRILLE := Color("#1d1b19")
const BARB_PASSAGE := Color("#2a211d")
const BARB_MERLON := 1.45
## The gates: [foot in plan, outward normal]: the bastion's front toward Freta and its inner face.
const BARB_GATES := [[Vector2(-955.95, -1836.6), Vector2(-1.0, 0.05)], [Vector2(-952.85, -1837.0), Vector2(1.0, 0.25)]]
## The gate wall across the C's open east end, between the eastern towers (photo 4).
const BARB_GATE_WALL := [Vector2(-934.6, -1826.6), Vector2(-929.4, -1832.9)]


func _find_barbakan() -> void:
	var outline := _landmark("Barbakan")
	if outline.size() >= 3:
		_add_site("barbakan", [outline])
		if not sites.is_empty() and sites[-1]["key"] == "barbakan":
			sites[-1]["ring"] = _simplify(outline, 0.35)


func _build_barbakan(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	if ring.size() < 3:
		return
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_g = _ground_under(ring)
	var g := _g
	var top := g + BARB_HEIGHT
	# the curtain: plain brick to the walk under a stone course (the photos show loopholes, not
	# the Gothic shader's tall lancets)
	_prism(ring, g - 1.5, top, BARB_WALL, BARB_STONE, M_STONE, M_STONE)
	var centre := BARB_BASTION
	# F's photos (2026-11-08): only the round bastion wears the crown; the arms carry tiled roofs
	var outer: Array = []  # the bastion's outer face, as [a, b, out]
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var m := (a + b) * 0.5
		var out := _out(ring, a, b)
		if m.x < centre.x + 0.5 and out.dot(m - centre) > 0.0 and a.distance_to(b) > 0.2:
			outer.append([a, b, out])
	for e: Array in outer:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var out: Vector2 = e[2]
		# a corbel band 0.6 m under the crown, standing 0.18 m proud, then the parapet
		var band := PackedVector2Array([a + out * 0.18, b + out * 0.18, b - out * 0.2, a - out * 0.2])
		_prism(band, top - 0.75, top, BARB_WALL.darkened(0.1), BARB_WALL.darkened(0.06), M_STONE, M_STONE)
		var par := PackedVector2Array([a + out * 0.1, b + out * 0.1, b - out * 0.35, a - out * 0.35])
		_prism(par, top, top + 0.9, BARB_WALL, BARB_WALL.darkened(0.05), M_STONE, M_STONE)
	# loopholes: two rows of slits and a row of round holes under the crown (photo 3)
	var hole := 0.0
	for e: Array in outer:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var out: Vector2 = e[2]
		var len := a.distance_to(b)
		var d := (b - a) / len
		var t := fposmod(-hole, 2.6)
		while t < len:
			var c := a + d * t + out * 0.04
			var row := int(hole + t) / 3 % 2
			for y: float in ([g + 3.2, g + 7.6] if row == 0 else [g + 5.4]):
				var slit := PackedVector2Array([c - d * 0.14, c + d * 0.14, c + d * 0.14 - out * 0.08, c - d * 0.14 - out * 0.08])
				_prism(slit, y, y + (0.28 if y > g + 7.0 else 0.6), BARB_GRILLE, Color(0, 0, 0, 0), M_STONE, M_STONE)
			t += 2.6
		hole += len
	# the merlons: brick posts every BARB_MERLON along the outer face, each under a grey stone
	# pyramid, a little pointed gable between each pair (photos 2, 3 and 5)
	var walked := 0.0
	var next := 0.6
	for e: Array in outer:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var out: Vector2 = e[2]
		var len := a.distance_to(b)
		var d := (b - a) / len
		while next < walked + len:
			var c := a + d * (next - walked) - out * 0.12
			var post := PackedVector2Array([c - d * 0.3 - out * 0.25, c + d * 0.3 - out * 0.25, c + d * 0.3 + out * 0.25, c - d * 0.3 + out * 0.25])
			_prism(post, top + 0.9, top + 1.75, BARB_WALL, Color(0, 0, 0, 0), M_STONE, M_STONE)
			_pyramid(post, top + 1.75, top + 2.25, BARB_STONE.darkened(0.15))
			var gc := c + d * (BARB_MERLON * 0.5)
			if next + BARB_MERLON * 0.5 < walked + len:
				var l := gc - d * (BARB_MERLON * 0.5 - 0.3) + out * 0.13
				var r := gc + d * (BARB_MERLON * 0.5 - 0.3) + out * 0.13
				var n3 := Vector3(out.x, 0.0, out.y)
				_tri(Vector3(l.x, top + 0.9, l.y), Vector3(r.x, top + 0.9, r.y), Vector3(gc.x + out.x * 0.13, top + 1.55, gc.y + out.y * 0.13),
						n3, BARB_WALL.lightened(0.04), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
			next += BARB_MERLON
		walked += len
	# the four towers: round brick drums with a tile cone swelling out over a deep eave
	for c: Vector2 in BARB_TOWERS:
		var th := g + BARB_TOWER_H
		_prism(_circle(c, BARB_TOWER_R, 12), g - 1.5, th, BARB_WALL, BARB_STONE, M_STONE, M_STONE)
		for y: float in [g + 4.0, g + 7.5, g + 10.5]:  # a slit window a storey, on the outer side
			var o := (c - BARB_PASSAGE_MID).normalized()
			var sc := c + o * (BARB_TOWER_R + 0.03)
			var sd := Vector2(-o.y, o.x)
			_prism(PackedVector2Array([sc - sd * 0.13, sc + sd * 0.13, sc + sd * 0.13 - o * 0.1, sc - sd * 0.13 - o * 0.1]), y, y + 0.6, BARB_GRILLE, Color(0, 0, 0, 0), M_STONE, M_STONE)
		_frustum(_circle(c, BARB_TOWER_R + 0.55, 12), th - 0.1, _circle(c, BARB_TOWER_R - 0.1, 12), th + 0.6, BARB_ROOF, BARB_ROOF)
		_frustum(_circle(c, BARB_TOWER_R - 0.1, 12), th + 0.6, _circle(c, 0.15, 12), th + 5.2, BARB_ROOF.lightened(0.04), BARB_ROOF)
		_lbox_at(c, 0.06, th + 5.2, th + 6.4, BARB_STONE.darkened(0.3))
	# the arms between each pair of towers: a tiled ridge roof over the walk (photo 2)
	for arm: Array in BARB_ARMS:
		var p0: Vector2 = arm[0]
		var p1: Vector2 = arm[1]
		var d := (p1 - p0).normalized()
		var n := Vector2(-d.y, d.x)
		var foot := PackedVector2Array([p0 - n * 1.9, p1 - n * 1.9, p1 + n * 1.9, p0 + n * 1.9])
		var ridge := PackedVector2Array([p0 - n * 0.06, p1 - n * 0.06, p1 + n * 0.06, p0 + n * 0.06])
		_frustum(foot, top - 0.1, ridge, top + 1.5, BARB_ROOF, BARB_ROOF)
		# the bridge's two pointed arches over the moat on the arm's outer face, iron grilles in
		# brick fans (photos 1, 2 and 5)
		var side := n if n.dot((p0 + p1) * 0.5 - centre) > 0.0 else -n
		side = side if (((p0 + p1) * 0.5 + side * 3.0) - BARB_PASSAGE_MID).length() > (((p0 + p1) * 0.5) - BARB_PASSAGE_MID).length() else -side
		for f: float in [0.3, 0.7]:
			var at := p0.lerp(p1, f) + side * BARB_ARM_HALF
			_lancet_panel(at, d, side, 2.2, g - 0.5, g + 1.9, BARB_WALL.lightened(0.07), 0.04, M_STONE)
			_lancet_panel(at, d, side, 1.6, g - 0.5, g + 1.9, BARB_GRILLE, 0.09, M_STONE)
	# the gates: a pointed arch through the bastion's front (photo 3) and its inner face, and the
	# gate wall between the eastern towers toward Nowomiejska (photo 4)
	for gate: Array in BARB_GATES:
		var at: Vector2 = gate[0]
		var out: Vector2 = (gate[1] as Vector2).normalized()
		var along := Vector2(-out.y, out.x)
		_lancet_panel(at, along, out, 2.3, g - 0.5, g + 3.4, BARB_STONE.darkened(0.05), 0.04, M_STONE)
		_lancet_panel(at, along, out, 1.75, g - 0.5, g + 3.4, BARB_PASSAGE, 0.09, M_STONE)
	_o = BARB_GATE_WALL[0]
	_a = (BARB_GATE_WALL[1] - BARB_GATE_WALL[0]).normalized()
	_b = Vector2(-_a.y, _a.x)
	var span: float = BARB_GATE_WALL[0].distance_to(BARB_GATE_WALL[1])
	var u0 := span * 0.5 - 1.8
	var u1 := span * 0.5 + 1.8
	_lbox(u0 * 0.5, 0.0, u0 * 0.5, 0.45, g - 0.5, top - 1.0, BARB_WALL, M_STONE, BARB_STONE)
	_lbox((u1 + span) * 0.5, 0.0, (span - u1) * 0.5, 0.45, g - 0.5, top - 1.0, BARB_WALL, M_STONE, BARB_STONE)
	_arch(u0, u1, 0.45, g + 3.6, top - 1.0, BARB_WALL)
	_arch(u0, u1, -0.45, g + 3.6, top - 1.0, BARB_WALL)
	_lbox(span * 0.5, 0.0, span * 0.5, 0.45, top - 1.0, top - 0.6, BARB_STONE.darkened(0.1), M_STONE, BARB_STONE)
	var k := 0.4
	while k < span - 0.3:
		_lbox(k, 0.0, 0.32, 0.4, top - 0.6, top + 0.5, BARB_WALL, M_STONE, BARB_STONE.darkened(0.15))
		k += 1.3
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_collide(ring)


func _build_teatr(_site: Dictionary) -> void:
	_o = TEATR
	_a = TEATR_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)  # (0.606, 0.796): out of the front, to the square
	var m := TEATR_MID
	_g = map.terrain_height(_w(m, 3.0).x, _w(m, 3.0).y)
	var g := _g
	var light := TEATR_STONE.lightened(0.04)
	var hw := TEATR_HALF
	var y0 := g + TEATR_ARCADE      # the columns' floor, over the arcaded ground storey
	var y1 := y0 + TEATR_COL_H      # their tops
	_mode = M_STONE
	# the ground storey (F's dusk photo, 2026-11-08): a rusticated arcade as deep as the portico,
	# square piers with dark arched openings between them, two low steps along its front
	_lbox(m, 3.5, hw + 1.6, 3.5, g - 0.6, y0 - 1.0, TEATR_BASE, M_STONE, light)
	_lbox(m, 3.6, hw + 1.8, 3.6, y0 - 1.0, y0, light, M_STONE, light)
	for k in 2:
		_lbox(m, 7.2 + 0.4 * k, hw + 1.0 - k, 0.2 + 0.4 * k, g - 0.6, g + 0.3 - 0.15 * k, TEATR_BASE, M_STONE,
				TEATR_BASE.lightened(0.04))
	_mode = M_GLASS
	for u: float in TEATR_COLS:
		# an arch between each pair of the columns' bays: a dark opening with a round head (a
		# pointed pair of triangles reads as one from the game's distance)
		var c := m + u
		var wa := _w(c - 1.15, 7.03)
		var wb := _w(c + 1.15, 7.03)
		_wall(wa, wb, g + 0.3, y0 - 3.2, _b, TEATR_ARCH)
		var top := _w(c, 7.03)
		_tri(Vector3(wa.x, y0 - 3.2, wa.y), Vector3(wb.x, y0 - 3.2, wb.y), Vector3(top.x, y0 - 2.0, top.y),
				Vector3(_b.x, 0.0, _b.y), TEATR_ARCH, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), y0 - 2.0 - g)
	_mode = M_STONE
	# the balustrade round the columns' floor
	for side: Array in [[m, 7.0, hw + 1.6, 0.15], [m - hw - 1.45, 3.5, 0.15, 3.5], [m + hw + 1.45, 3.5, 0.15, 3.5]]:
		_lbox(float(side[0]), float(side[1]), float(side[2]), float(side[3]), y0, y0 + 1.1, light, M_STONE, light)
	# ten columns across the front on the arcade (T06-04, F's photo)
	for u: float in TEATR_COLS:
		_column(m + u, 4.6, 0.62, y0, y1, TEATR_COLUMN)
	# the entablature, back to the wall (architrave, the carved frieze a shade darker, cornice)
	_lbox(m, 3.0, hw + 0.5, 3.2, y1, y1 + 1.4, light, M_STONE, light)
	_lbox(m, 3.0, hw + 0.8, 3.4, y1 + 1.4, y1 + 2.6, TEATR_SCULPT, M_STONE, light)
	_lbox(m, 3.0, hw + 1.1, 3.7, y1 + 2.6, y1 + 3.1, light, M_STONE, light)
	var ya := y1 + 3.1
	# the attic over the portico: a plain block, the quadriga at its front edge
	_lbox(m, 2.6, hw - 0.2, 2.6, ya, ya + 2.0, TEATR_STONE, M_STONE, light)
	_lbox(m, 2.6, hw + 0.2, 2.9, ya + 2.0, ya + 2.4, light, M_STONE, light)
	_teatr_quadriga(m, 3.4, ya + 2.4)
	# behind the attic, the raised middle block with its windows (three a side), its cornice and
	# the pediment with the relief in the tympanum (T06-04, T06-08, F's photo)
	var pv0 := -0.5
	var pv1 := -9.0
	var pc := (pv0 + pv1) * 0.5
	var ph := (pv0 - pv1) * 0.5
	var yc := ya + 7.6
	_lbox(m, pc, TEATR_PED_HALF, ph, y1, yc, TEATR_STONE, M_MONUMENT, light)
	_lbox(m, pc, TEATR_PED_HALF + 0.5, ph + 0.5, yc, yc + 0.6, TEATR_SCULPT, M_STONE, light)
	_lbox(m, pc, TEATR_PED_HALF + 0.8, ph + 0.8, yc + 0.6, yc + 1.2, light, M_STONE, light)
	_teatr_pediment(m, pv0 + 0.8, pv1 - 0.8, TEATR_PED_HALF + 0.8, yc + 1.2, yc + 6.4)
	# the portico's back wall (proud of LoD2's) on the columns' floor, and its doors in shade
	_lbox(m, -0.1, hw - 1.6, 0.2, y0, y1, TEATR_STONE.darkened(0.06), M_STONE, TEATR_STONE)
	_mode = M_GLASS
	for u: float in [-10.2, -6.8, -3.4, 0.0, 3.4, 6.8, 10.2]:
		_wall(_w(m + u - 1.0, 0.13), _w(m + u + 1.0, 0.13), y0 + 0.2, y0 + 4.6, _b, Color("#3a3d40"))
	_mode = M_STONE
	_collide(_rect(m, 3.5, hw + 1.6, 3.6))


## The pediment over the middle block: a triangular gable from v0 (front) to v1 (back), half
## width `hw`, from y0 to the ridge y1; two green copper slopes, stone ends, and the tympanum's
## relief a shade darker, 0.15 m proud of the front.
func _teatr_pediment(m: float, v0: float, v1: float, hw: float, y0: float, y1: float) -> void:
	var l := _w(m - hw, v0)
	var r := _w(m + hw, v0)
	var t := _w(m, v0)
	var lb := _w(m - hw, v1)
	var rb := _w(m + hw, v1)
	var tb := _w(m, v1)
	var out := Vector3(_b.x, 0.0, _b.y)
	var top := y1 - _g
	_mode = M_STONE
	_tri(Vector3(l.x, y0, l.y), Vector3(r.x, y0, r.y), Vector3(t.x, y1, t.y), out, TEATR_STONE,
			Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), top)
	_tri(Vector3(lb.x, y0, lb.y), Vector3(rb.x, y0, rb.y), Vector3(tb.x, y1, tb.y), -out, TEATR_STONE,
			Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), top)
	# the relief: a smaller triangle just proud of the tympanum
	var k := 0.78
	var f := _b * 0.15
	var rl := _w(m - hw * k, v0) + f
	var rr := _w(m + hw * k, v0) + f
	var rt := _w(m, v0) + f
	var ry0 := y0 + 0.4
	_tri(Vector3(rl.x, ry0, rl.y), Vector3(rr.x, ry0, rr.y), Vector3(rt.x, ry0 + (y1 - y0) * k - 0.4, rt.y), out,
			TEATR_RELIEF, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), top)
	# the two slopes, green copper
	for side: float in [-1.0, 1.0]:
		var a0 := _w(m + side * hw, v0)
		var a1 := _w(m + side * hw, v1)
		var n2 := _a * side * (y1 - y0) / hw
		var nrm := Vector3(n2.x, 1.0, n2.y).normalized()
		_quad(Vector3(a0.x, y0, a0.y), Vector3(a1.x, y0, a1.y), Vector3(tb.x, y1, tb.y), Vector3(t.x, y1, t.y), nrm,
				TEATR_COPPER, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), top)


## The Apollo quadriga (T06-04): a plinth, four horses abreast rearing out to the square, the
## chariot and the god behind them, all in dark bronze; low boxes, read from above.
func _teatr_quadriga(m: float, v: float, y: float) -> void:
	_lbox(m, v, 4.6, 1.6, y, y + 0.9, TEATR_STONE, M_STONE, TEATR_STONE.lightened(0.04))
	var b := y + 0.9
	for u: float in [-2.7, -0.95, 0.95, 2.7]:
		var lean := 0.5 if absf(u) > 2.0 else 0.2  # the outer pair rear higher
		_lbox(m + u * 1.05, v + 0.3, 0.32, 1.1, b + 0.9, b + 1.9, TEATR_BRONZE)       # body
		_lbox(m + u * 1.1, v + 1.3, 0.25, 0.35, b + 1.6, b + 2.9 + lean, TEATR_BRONZE)  # neck and head
		_lbox(m + u * 1.05, v - 0.6, 0.25, 0.25, b, b + 0.9, TEATR_BRONZE)             # hind legs
		_lbox(m + u * 1.1, v + 1.0, 0.2, 0.3, b + 0.6, b + 1.3, TEATR_BRONZE)          # raised forelegs
	_lbox(m, v - 1.0, 1.0, 0.5, b, b + 1.2, TEATR_BRONZE)       # the chariot
	_lbox(m, v - 1.0, 0.35, 0.3, b + 1.2, b + 3.4, TEATR_BRONZE)  # Apollo
	_lbox(m + 0.5, v - 0.8, 0.12, 0.12, b + 2.6, b + 3.9, TEATR_BRONZE)  # his raised arm


# --- Plac Bankowy: Corazzi's palaces and the Bank Polski rotunda -----------------------------

## Plac Bankowy's west side (Antonio Corazzi, 1825-1830; spec docs/landmarks/specs/bankowy.md,
## from the Mac's Commons photos and GUGiK ortho in docs/landmarks/photo-reports/ratusz.md,
## 2026-11-02). The masses stay LoD2's in their skins, now in the photos' pale ochre-cream under
## green copper; the models add what LoD2 squashes into stubs. The Ratusz (Pałac Komisji
## Rządowej Przychodów i Skarbu): the cour d'honneur open to the square, both wings ending in
## colonnades of free-standing white columns two storeys tall under an entablature, the small
## four-column porches in the court, and at the court's back the giant portico of six Corinthian
## columns on an arcaded base under an attic with no pediment. The Bank Polski and Exchange
## (Gmach Giełdy i Banku Polskiego) at Bielańska: the rounded corner's upper tier of round
## arches over the open arcade, the drum and its shallow green dome. Column positions and the
## rotunda's rings are OpenStreetMap's (building parts with heights), which match the ortho.
const BANK_WALL := Color("#e6d6ae")
const BANK_COLUMN := Color("#f2eee3")
const BANK_TRIM := Color("#ece4cc")
const BANK_BASE := Color("#cdbf98")
const BANK_ROOF := Color("#7da894")
const BANK_DARK := Color("#27303a")
const BANK_LEAD := Color("#a3aaa8")
## Columns closer than this (m) carry one entablature (the colonnades' ~2.7 m, the porches' ~3.3 m).
const BANK_SPAN := 3.45
## The giant portico: its six front columns (OSM) run from BANK_PORTICO_A to _B, it reaches
## BANK_PORTICO_DEPTH m back to the wall, the columns stand on the arcaded base's top.
const BANK_PORTICO_A := Vector2(-1587.6, -995.69)
const BANK_PORTICO_B := Vector2(-1595.27, -1010.9)
const BANK_PORTICO_DEPTH := 5.2
const BANK_PORTICO_BASE := 6.6
const BANK_PORTICO_TOP := 16.8
## The rotunda (OSM's round parts): centre, the drum's radius and its top, the dome's rise; the
## rounded corner's upper face (radius), and the open arcade's piers round the corner (the map's
## own 1.3-2.3 m piers, kept by LoD2; ours stand over them), an arched window over each opening.
const BANK_ROT := Vector2(-1479.7, -894.85)
const BANK_ROT_R := 12.05
const BANK_ROT_DRUM := Vector2(13.2, 17.5)
const BANK_ROT_RISE := 4.0
const BANK_ROT_FACE := 15.75
const BANK_ROT_PIERS := [Vector2(-1466.8, -904.6), Vector2(-1465.2, -900.8), Vector2(-1464.5, -896.9),
		Vector2(-1464.7, -893.0), Vector2(-1465.8, -889.2), Vector2(-1467.5, -885.8), Vector2(-1470.2, -882.9),
		Vector2(-1473.4, -879.9)]


## The Ratusz: what stands on the mapped columns and the giant portico (`_bank_portico`).
func _build_ratusz(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["zone"][0]
	var grown := Geometry2D.offset_polygon(outline, 3.0, Geometry2D.JOIN_MITER)
	if grown.is_empty():
		return
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	# the colonnades and porches: the mapped columns two storeys tall (the giant ones are the portico's)
	var cols: Array[Dictionary] = []
	for bld in _parts_in(grown[0], func(b: Dictionary) -> bool:
			return str(b["kind"]) == "column" and float(b["h"]) < 12.0):
		var q := _pts(bld["p"])
		var c := _centre(q)
		var r := 0.0
		for p in q:
			r = maxf(r, p.distance_to(c))
		cols.append({"c": c, "r": r, "y0": float(bld["mh"]), "y1": float(bld["h"])})
	_bank_colonnades(cols)
	_bank_portico()


## Columns and their entablatures: every chain of columns closer than BANK_SPAN gets one
## stylobate under it and one entablature (a cornice on top) over it, as single polygons so
## the corners do not double up.
func _bank_colonnades(cols: Array[Dictionary]) -> void:
	var n := cols.size()
	var links: Array = []
	for i in n:
		links.append([])
	for i in n:
		for j in range(i + 1, n):
			if (cols[i]["c"] as Vector2).distance_to(cols[j]["c"]) < BANK_SPAN:
				links[i].append(j)
				links[j].append(i)
	var seen := {}
	for i in n:
		var c: Vector2 = cols[i]["c"]
		var g: float = map.terrain_height(c.x, c.y)
		var r: float = cols[i]["r"] + 0.06
		_column(c.x, c.y, r, g + float(cols[i]["y0"]), g + float(cols[i]["y1"]), BANK_COLUMN)
	# walk each chain from an end (or any column of a ring)
	for start in n:
		if seen.has(start) or (links[start] as Array).size() > 1 and _bank_has_end(start, links, seen):
			continue
		var chain := PackedVector2Array()
		var at := start
		var prev := -1
		var y1: float = cols[start]["y1"]
		var y0: float = cols[start]["y0"]
		var r: float = cols[start]["r"]
		while at >= 0 and not seen.has(at):
			seen[at] = true
			chain.append(cols[at]["c"])
			var nxt := -1
			for j: int in links[at]:
				if j != prev and not seen.has(j):
					nxt = j
					break
			prev = at
			at = nxt
		if chain.size() < 2:
			continue
		var g: float = map.terrain_height(chain[0].x, chain[0].y)
		for p in chain:
			g = minf(g, map.terrain_height(p.x, p.y))
		var keep := _mode
		_mode = M_STONE
		for poly in _bank_band(chain, r + 0.55, 0.9, g - 0.5, g + minf(y0, 1.6), BANK_BASE, BANK_TRIM):
			_collide(poly)
		_bank_band(chain, r + 0.15, 0.3, g + y1, g + y1 + 1.0, BANK_TRIM, BANK_TRIM)
		_bank_band(chain, r + 0.35, 0.5, g + y1 + 1.0, g + y1 + 1.4, BANK_TRIM.lightened(0.04), BANK_LEAD)
		_mode = keep


## Whether column i's chain still has an unwalked end (so the walk starts there, not mid-chain).
func _bank_has_end(i: int, links: Array, seen: Dictionary) -> bool:
	var todo := [i]
	var met := {i: true}
	while not todo.is_empty():
		var k: int = todo.pop_back()
		if (links[k] as Array).size() <= 1 and not seen.has(k):
			return true
		for j: int in links[k]:
			if not met.has(j):
				met[j] = true
				todo.append(j)
	return false


## A band `half` m each side of the polyline `chain`, run on `ext` m past both ends, y0 to y1.
## Returns the band's outlines (the stylobate's are the car's).
func _bank_band(chain: PackedVector2Array, half: float, ext: float, y0: float, y1: float, col: Color, top: Color) -> Array[PackedVector2Array]:
	var line := chain.duplicate()
	line[0] = chain[0] + (chain[0] - chain[1]).normalized() * ext
	var last := chain.size() - 1
	line[last] = chain[last] + (chain[last] - chain[last - 1]).normalized() * ext
	var out: Array[PackedVector2Array] = []
	for poly: PackedVector2Array in Geometry2D.offset_polyline(line, half, Geometry2D.JOIN_MITER, Geometry2D.END_BUTT):
		if poly.size() >= 3:
			_prism(poly, y0, y1, col, top, M_STONE, M_STONE)
			out.append(poly)
	return out


## The giant portico at the court's back: the rusticated arcaded base, six columns, the
## entablature and the plain attic, the dark back wall with its tall windows between.
## Frame: u from the north-east column along the row, +v out of the portico into the court.
func _bank_portico() -> void:
	_o = BANK_PORTICO_A
	_a = (BANK_PORTICO_B - BANK_PORTICO_A).normalized()
	_b = Vector2(-_a.y, _a.x)
	if _b.dot(Vector2(0.893, -0.45)) < 0.0:
		_b = -_b
	var span := BANK_PORTICO_A.distance_to(BANK_PORTICO_B)
	var m := span * 0.5
	var d := BANK_PORTICO_DEPTH
	_g = map.terrain_height(_w(m, 0.0).x, _w(m, 0.0).y)
	var g := _g
	var base := g + BANK_PORTICO_BASE
	var top := g + BANK_PORTICO_TOP
	var bay := span / 5.0
	# the back wall inside the portico, its tall windows (the arches go first: they stand off it)
	for k in 5:
		_arch_panel(_w((k + 0.5) * bay, -d + 0.3), _a, _b, 0.85, base + 1.2, base + 5.6, BANK_DARK, 0.04, M_GLASS)
	_lbox(m, -d + 0.15, m + 1.0, 0.15, base, top, BANK_WALL.darkened(0.08), M_STONE, BANK_WALL)
	# the base: rusticated, a round arch under each bay, a string course on top
	for k in 5:
		_arch_panel(_w((k + 0.5) * bay, 1.0), _a, _b, 1.05, g + 0.4, g + 4.2, BANK_DARK, 0.04, M_STONE)
	_lbox(m, -d * 0.5 + 0.5, m + 1.0, d * 0.5 + 0.5, g - 0.6, base - 0.4, BANK_BASE, M_STONE, BANK_BASE)
	_lbox(m, -d * 0.5 + 0.55, m + 1.1, d * 0.5 + 0.55, base - 0.4, base, BANK_TRIM, M_STONE, BANK_TRIM.darkened(0.04))
	# six Corinthian columns
	for k in 6:
		_column(k * bay, 0.0, 0.74, base, top, BANK_COLUMN)
	# the entablature, its cornice, and the attic over the portico (no pediment)
	_lbox(m, -d * 0.5 + 0.35, m + 0.95, d * 0.5 + 0.35, top, top + 1.4, BANK_TRIM, M_STONE, BANK_TRIM)
	_lbox(m, -d * 0.5 + 0.5, m + 1.2, d * 0.5 + 0.5, top + 1.4, top + 1.9, BANK_TRIM.lightened(0.04), M_STONE, BANK_LEAD)
	_lbox(m, -d * 0.5 + 0.2, m + 0.7, d * 0.5 + 0.2, top + 1.9, top + 4.1, BANK_WALL, M_STONE, BANK_LEAD)
	_lbox(m, -d * 0.5 + 0.3, m + 0.8, d * 0.5 + 0.3, top + 4.1, top + 4.4, BANK_TRIM, M_STONE, BANK_LEAD)
	_collide(_rect(m, -d * 0.5 + 0.5, m + 1.0, d * 0.5 + 0.5))


## The Bank Polski's rounded corner: the upper tier's round arches over the open arcade (whose
## piers are the map's), a cornice, the drum ringed by small windows and the shallow green dome.
func _build_gielda(_site: Dictionary) -> void:
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	var c := BANK_ROT
	_g = map.terrain_height(c.x + BANK_ROT_FACE, c.y)  # the corner's foot, on the street
	var g := _g
	var none := Color(0, 0, 0, 0)
	# the arcade's piers round the corner, the cornice band over them, an arched window over each
	# opening in the upper tier, the cornice under the drum
	var angles: Array[float] = []
	for pc: Vector2 in BANK_ROT_PIERS:
		var out := (pc - c).normalized()
		var along := Vector2(-out.y, out.x)
		var h := 1.2
		_prism(PackedVector2Array([pc + (out + along) * h, pc + (out - along) * h, pc - (out + along) * h,
				pc - (out - along) * h]), g - 0.5, g + 7.1, BANK_WALL, none, M_STONE, M_STONE)
		angles.append(atan2(out.y, out.x))
	for k in angles.size() - 1:
		var t := (angles[k] + angles[k + 1]) * 0.5
		var out := Vector2(cos(t), sin(t))
		var along := Vector2(-out.y, out.x)
		_arch_panel(c + out * BANK_ROT_FACE, along, out, 1.25, g + 7.5, g + 11.2, BANK_TRIM, 0.04, M_STONE)
		_arch_panel(c + out * BANK_ROT_FACE, along, out, 0.95, g + 8.15, g + 11.2, BANK_DARK, 0.1, M_GLASS)
	var a0: float = angles[0] - 0.08
	var a1: float = angles[angles.size() - 1] + 0.08
	var ring := PackedVector2Array()
	var steps := 12
	for k in steps + 1:
		var t := a0 + (a1 - a0) * k / steps
		ring.append(c + Vector2(cos(t), sin(t)) * (BANK_ROT_FACE + 0.35))
	for k in range(steps, -1, -1):
		var t := a0 + (a1 - a0) * k / steps
		ring.append(c + Vector2(cos(t), sin(t)) * (BANK_ROT_FACE - 1.4))
	_prism(ring, g + 7.1, g + 7.5, BANK_TRIM, BANK_TRIM, M_STONE, M_STONE)
	_prism(ring, g + 13.6, g + 14.4, BANK_TRIM, BANK_LEAD, M_STONE, M_STONE)
	# the drum over the roofs: the wall a hand proud of LoD2's, a window per bay, the cornice
	var r := BANK_ROT_R
	for k in 16:
		var t := TAU * (k + 0.5) / 16.0
		var out := Vector2(cos(t), sin(t))
		_arch_panel(c + out * (r + 0.12), Vector2(-out.y, out.x), out, 0.6, g + BANK_ROT_DRUM.x + 1.0,
				g + BANK_ROT_DRUM.y - 1.9, BANK_DARK, 0.05, M_GLASS)
	_prism(_circle(c, r + 0.12, 32), g - 0.5, g + BANK_ROT_DRUM.y, BANK_WALL, none, M_STONE, M_STONE)
	_prism(_circle(c, r + 0.55, 32), g + BANK_ROT_DRUM.y, g + BANK_ROT_DRUM.y + 0.6, BANK_TRIM, BANK_LEAD, M_STONE, M_STONE)
	# the shallow dome: a spherical cap in four rings, a small round light on top
	var y0 := g + BANK_ROT_DRUM.y + 0.6
	var rings := 4
	_mode = M_STONE
	for k in rings:
		var s0 := float(k) / rings
		var s1 := float(k + 1) / rings
		var r0 := (r + 0.2) * cos(s0 * PI * 0.5)
		var r1 := maxf((r + 0.2) * cos(s1 * PI * 0.5), 1.4)
		_frustum(_circle(c, r0, 32), y0 + BANK_ROT_RISE * sin(s0 * PI * 0.5), _circle(c, r1, 32),
				y0 + BANK_ROT_RISE * sin(s1 * PI * 0.5), BANK_ROOF.darkened(0.03 * k),
				BANK_ROOF if k == rings - 1 else none)
	_prism(_circle(c, 1.2, 12), y0 + BANK_ROT_RISE, y0 + BANK_ROT_RISE + 0.9, BANK_TRIM, BANK_ROOF.lightened(0.08), M_STONE, M_STONE)


# --- Filharmonia Narodowa and Teatr Polski ----------------------------------------------------

## Filharmonia Narodowa (Jasna 5; Karol Kozłowski's hall of 1901, rebuilt in 1955; spec
## docs/landmarks/specs/filharmonia.md, from the Mac's photos and ortho in
## docs/landmarks/photo-reports/filharmonia.md, 2026-11-02). The mass stays LoD2's in its skin
## of pale cream stone; the model adds the Jasna front: a rusticated base, the giant order of
## smooth cream-white columns with Ionic capitals, a French door in each bay behind the balcony's
## iron railing, two composers on the balcony (Chopin and Moniuszko), FILHARMONIA NARODOWA cut in
## the frieze, the cornice and the attic's balustrade; below, the rusticated arcade of round-headed
## openings; on the Sienkiewicza wall the round "fn" sign on its bracket (red ring, green letters)
## and SALA KONCERTOWA (the institution's own words, not a brand). Reworked 2026-11-24 from the
## Commons photos in refs/filharmonia (4-14): the tall arched windows and ten composers were wrong.
## Frame: u along the mapped Jasna front from its north end, +v out of it to the street (east).
const FIL_A := Vector2(-860.7, -77.7)
const FIL_B := Vector2(-837.6, -27.0)
const FIL_WALL := Color("#e3ded2")
const FIL_COLUMN := Color("#ede9de")
const FIL_BASE := Color("#c9c3b5")
const FIL_STATUE := Color("#f1efe9")
const FIL_DARK := Color("#232a33")
const FIL_IRON := Color("#2b2c2e")
const FIL_LEAD := Color("#a2a7a8")
const FIL_NEON := Color(0.2, 1.0, 0.45)
const FIL_RING := Color("#ff4a2a")        # the roundel's red neon ring
const FIL_DOOR := Color("#5e3a26")        # the French doors' brown frames
const FIL_INSCRIPTION := Color("#5f5a50") # the letters cut in the frieze
const FIL_COLS := 11
const FIL_END := 4.8       # the solid corner bays at both ends of the colonnade
const FIL_BASE_TOP := 4.5
const FIL_TOP := 15.0


func _build_filharmonia(_site: Dictionary) -> void:
	_o = FIL_A
	_a = (FIL_B - FIL_A).normalized()
	_b = Vector2(_a.y, -_a.x)    # east, to Jasna
	var span := FIL_A.distance_to(FIL_B)
	var m := span * 0.5
	_g = minf(map.terrain_height(FIL_A.x, FIL_A.y), map.terrain_height(FIL_B.x, FIL_B.y))
	var g := _g
	var base := g + FIL_BASE_TOP
	var top := g + FIL_TOP
	var bay := (span - 2.0 * FIL_END) / float(FIL_COLS - 1)
	# The rusticated base (2026-11-24, refs/filharmonia 5, 7, 9): an arcade of round-headed openings,
	# one per bay, dark behind their grilles, on a step; the piers between them banded with grooves.
	_lbox(m, 0.25, m + 0.2, 0.5, g - 0.6, base, FIL_BASE, M_STONE, FIL_BASE.lightened(0.05))
	_lbox(m, 0.95, m + 0.2, 0.2, g - 0.6, g + 0.15, FIL_BASE.darkened(0.08), M_STONE, FIL_BASE.darkened(0.04))   # the step
	var arch_hw := minf(1.35, bay * 0.3)
	for k in FIL_COLS - 1:
		var u := FIL_END + (k + 0.5) * bay
		_arch_panel(_w(u, 0.75), _a, _b, arch_hw, g + 0.15, g + 2.75, FIL_DARK, 0.02, M_GLASS)
		_lbox(u, 0.79, arch_hw, 0.01, g + 2.55, g + 2.62, FIL_IRON, M_STONE, FIL_IRON)   # the grille's transom
	# The grooves: on each pier under a column, and on the two solid end bays.
	var pier := bay * 0.5 - arch_hw - 0.1
	var ends: Array[Vector2] = [Vector2(0.2, FIL_END - pier - 0.05), Vector2(span - FIL_END + pier + 0.05, span - 0.2)]
	for row in 6:
		var y := g + 0.75 + row * 0.6
		var groove := FIL_BASE.darkened(0.14)
		for k in FIL_COLS:
			_lbox(FIL_END + k * bay, 0.765, pier, 0.015, y, y + 0.04, groove, M_STONE, groove)
		for e: Vector2 in ends:
			_lbox((e.x + e.y) * 0.5, 0.765, (e.y - e.x) * 0.5, 0.015, y, y + 0.04, groove, M_STONE, groove)
	# The balcony along the colonnade's foot (the base's cornice carries it), its iron railing
	# between the columns; behind it a rectangular French door in each bay (brown frames, a cross).
	_lbox(m, 1.3, m + 0.25, 1.15, base - 0.35, base, FIL_WALL.lightened(0.03), M_STONE, FIL_WALL)
	_lbox(m, 0.05, m, 0.3, base, top, FIL_WALL, M_STONE, FIL_WALL)
	for k in FIL_COLS - 1:
		var u := FIL_END + (k + 0.5) * bay
		_lbox(u, 0.37, 0.85, 0.02, base + 0.05, base + 3.5, FIL_DOOR, M_STONE, FIL_DOOR)
		_lbox(u, 0.4, 0.06, 0.02, base + 0.05, base + 3.5, FIL_DOOR.lightened(0.15), M_STONE, FIL_DOOR)
		_lbox(u, 0.4, 0.85, 0.02, base + 2.2, base + 2.3, FIL_DOOR.lightened(0.15), M_STONE, FIL_DOOR)
		_lbox(u, 0.36, 1.0, 0.04, base + 3.5, base + 3.75, FIL_WALL.darkened(0.05), M_STONE, FIL_WALL)   # the lintel
		# The railing: a top rail and a low dark band (a solid 1 m box read as a black slab).
		_lbox(u, 2.35, bay * 0.5 - 0.75, 0.03, base + 0.85, base + 0.92, FIL_IRON, M_STONE, FIL_IRON)
		_lbox(u, 2.35, bay * 0.5 - 0.75, 0.015, base + 0.05, base + 0.85, FIL_IRON.lightened(0.25), M_STONE, FIL_IRON)
	# Two composers, not ten (the photos): Chopin and Moniuszko on the balcony either side of the middle.
	var mid := (FIL_COLS - 1) / 2
	for k: int in [mid - 2, mid + 1]:
		_fil_composer(_w(FIL_END + (k + 0.5) * bay, 1.2), base)
	for k in FIL_COLS:
		var u := FIL_END + k * bay
		_column(u, 1.55, 0.62, base, top, FIL_COLUMN)
		# The Ionic capital: the volutes either side, wider than the shaft along the front.
		_lbox(u, 1.55, 0.95, 0.5, top - 0.55, top - 0.25, FIL_COLUMN.lightened(0.04), M_STONE, FIL_COLUMN)
		for sd in [-1.0, 1.0]:
			_lbox(u + sd * 0.85, 1.55, 0.14, 0.52, top - 0.75, top - 0.3, FIL_COLUMN.darkened(0.04), M_STONE, FIL_COLUMN)
	# The entablature with FILHARMONIA NARODOWA cut in its frieze, the cornice, and the attic's
	# balustrade (a plinth, balusters in panels between posts, the top rail).
	_lbox(m, 0.85, m + 0.2, 1.4, top, top + 1.2, FIL_COLUMN, M_STONE, FIL_COLUMN)
	_fil_word("FILHARMONIA NARODOWA", m, top + 0.3, 0.62, 0.26, 2.26, FIL_INSCRIPTION)
	_lbox(m, 1.0, m + 0.45, 1.6, top + 1.2, top + 1.65, FIL_COLUMN.lightened(0.04), M_STONE, FIL_LEAD)
	_lbox(m, 0.2, m + 0.1, 0.45, top + 1.65, top + 1.95, FIL_WALL, M_STONE, FIL_WALL)
	_lbox(m, 0.2, m + 0.1, 0.45, top + 2.75, top + 2.95, FIL_WALL.lightened(0.04), M_STONE, FIL_LEAD)
	var posts := int(span / 4.6)
	for k in posts + 1:
		_lbox(-0.1 + k * (span + 0.2) / posts, 0.2, 0.22, 0.4, top + 1.95, top + 2.75, FIL_WALL, M_STONE, FIL_WALL)
	var n_bal := int(span / 0.62)
	for k in n_bal:
		var u := 0.31 + k * span / n_bal
		_lbox(u, 0.35, 0.08, 0.08, top + 1.95, top + 2.75, FIL_COLUMN, M_STONE, FIL_COLUMN)
	# The corner at Sienkiewicza (refs/filharmonia 1, 13): the round "fn" sign on a bracket out of the
	# side wall, a red neon ring round the green letters, both faces; the hall's name lower down.
	var disc_at := _w(span + 1.5, -3.0)
	var y_fn := top - 3.2
	var nb := Vector3(_b.x, 0.0, _b.y)
	_lbox(span + 0.75, -3.0, 0.75, 0.05, y_fn + 1.05, y_fn + 1.15, FIL_IRON, M_STONE, FIL_IRON)
	_lbox(span + 0.75, -3.0, 0.75, 0.05, y_fn - 0.05, y_fn + 0.05, FIL_IRON, M_STONE, FIL_IRON)
	# A hidden plate between the two faces joins them to the bracket, and a stone strip on the side
	# wall (the corner's pilaster, from the front's face back past the bracket) carries it.
	_lbox(span + 1.5, -3.0, 0.68, 0.01, y_fn - 0.13, y_fn + 1.23, FIL_IRON, M_STONE, FIL_IRON)
	_ubox(span - 0.05, span + 0.08, -3.8, -0.2, base, top, FIL_WALL, M_STONE, FIL_WALL)
	for sd in [-1.0, 1.0]:
		var c: Vector3 = Vector3(disc_at.x, y_fn + 0.55, disc_at.y) + nb * (0.08 * sd)
		var keep := _mode
		_mode = M_LAMP
		_disc(c, nb * sd, 1.05, 18, FIL_RING)
		_mode = keep
		_disc(c + nb * (0.06 * sd), nb * sd, 0.92, 18, FIL_DARK)
		if sd > 0.0:   # one sign: the neon is seen from both sides (two overlapped from an angle)
			signs.append(["FN", c + nb * 0.09, nb, 0.85, FIL_NEON])
	var n3 := Vector3(_b.x, 0.0, _b.y)
	var name_at := _w(span - FIL_END * 0.5 - 1.0, 0.8)
	signs.append(["SALA", Vector3(name_at.x, base - 1.0, name_at.y), n3, 0.45, FIL_NEON])
	signs.append(["KONCERTOWA", Vector3(name_at.x, base - 2.1, name_at.y), n3, 0.45, FIL_NEON])
	_collide(_rect(m, 1.0, m + 0.3, 1.2))


## An inscription cut in the frieze: `text` in PixelFont's letters as dark stone runs, centred at
## u `cu`, from y `y0`, `h` high, `sx` m a pixel across, standing out to v `v` (the frieze's face).
## The reader faces -v, so the word runs along -u.
func _fil_word(text: String, cu: float, y0: float, h: float, sx: float, v: float, col: Color) -> void:
	var sy := h / 7.0
	var width := 0.0
	for ch in text:
		width += (_pow_glyph_w(ch) + 1) * sx
	width -= sx
	var at := cu - width * 0.5
	for ch in text:
		var lit := {}
		for q: Vector2i in _pow_glyph(ch):
			lit[q] = true
		for q: Vector2i in lit:
			if lit.has(q - Vector2i(1, 0)):
				continue
			var e := q
			while lit.has(e + Vector2i(1, 0)):
				e += Vector2i(1, 0)
			var row := PixelFont.BODY + 6 - q.y
			var u0 := at + q.x * sx
			var u1 := at + (e.x + 1) * sx
			_lbox(2.0 * cu - (u0 + u1) * 0.5, v, (u1 - u0) * 0.5, 0.02, y0 + row * sy, y0 + (row + 1) * sy, col, M_STONE, col)
		at += (_pow_glyph_w(ch) + 1) * sx


## A composer on a window sill: white stone, standing, a cloak to the ankles, one hand at the chest.
func _fil_composer(at: Vector2, y: float) -> void:
	var keep_o := _o
	var keep_a := _a
	var keep_b := _b
	var fwd := keep_b
	_o = at
	_a = fwd
	_b = Vector2(-fwd.y, fwd.x)
	var col := FIL_STATUE
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 0.34, 0.42), y, _rect(0.0, 0.0, 0.22, 0.3), y + 1.85, col, Color(0, 0, 0, 0))
	_frustum(_rect(0.0, 0.0, 0.22, 0.3), y + 1.85, _rect(0.0, 0.0, 0.17, 0.27), y + 2.25, col, col)
	_prism(_circle(_w(0.02, 0.0), 0.15, 6), y + 2.25, y + 2.6, col.lightened(0.03), col, M_STONE, M_STONE)
	var s := _w(0.0, 0.22)
	var h := _w(0.3, 0.0)
	_beam(Vector3(s.x, y + 2.1, s.y), Vector3(h.x, y + 1.7, h.y), 0.13, col)
	_o = keep_o
	_a = keep_a
	_b = keep_b


## Teatr Polski (Karasia 2; Czesław Przybylski, 1912-1913; spec docs/landmarks/specs/teatr_polski.md,
## from the Mac's photos and ortho in docs/landmarks/photo-reports/teatr_polski.md, 2026-11-02).
## The mass stays LoD2's in its skin (cream-grey render, the hall's green copper roof); the model
## adds the Karasia front: the two rounded corner bays (drums) at its ends with balustraded tops,
## round-arched doors and windows on the ground floor, tall windows over a long iron balcony on
## the middle storey, a row of oval windows (oculi) on the top one, the cornice and a stone
## balustrade along the roof edge, and the small green kiosk on the walk.
## Frame: u along the mapped front from its north end, +v out of it to Karasia (west).
const TP_A := Vector2(-299.0, -482.1)
const TP_B := Vector2(-306.0, -499.6)
const TP_DRUMS := [Vector2(-297.6, -479.9), Vector2(-306.6, -502.3)]
const TP_DRUM_R := 2.4
const TP_WALL := Color("#e2ddcd")
const TP_TRIM := Color("#ebe7dc")
const TP_BASE := Color("#c8c2b1")
const TP_DARK := Color("#262c33")
const TP_IRON := Color("#2a2b2c")
const TP_LEAD := Color("#a0a5a5")
const TP_KIOSK := Color("#3f7d5a")
const TP_EAVES := 16.0


func _build_teatr_polski(_site: Dictionary) -> void:
	_o = TP_A
	_a = (TP_B - TP_A).normalized()
	_b = Vector2(-_a.y, _a.x)
	if _b.x > 0.0:
		_b = -_b                  # west, to Karasia
	var span := TP_A.distance_to(TP_B)
	var m := span * 0.5
	_g = minf(map.terrain_height(TP_A.x, TP_A.y), map.terrain_height(TP_B.x, TP_B.y))
	var g := _g
	var top := g + TP_EAVES
	var bays := 5
	var bay := span / bays
	var n3 := Vector3(_b.x, 0.0, _b.y)
	# openings first (they stand off the face): arched doors below, tall windows, oculi on top
	for k in bays:
		var u := (k + 0.5) * bay
		_arch_panel(_w(u, 0.35), _a, _b, 1.05, g + 0.3, g + 3.3, TP_DARK, 0.04, M_GLASS)
		_arch_panel(_w(u, 0.35), _a, _b, 0.85, g + 5.6, g + 9.4, TP_DARK, 0.04, M_GLASS)
		var oc := _w(u, 0.4)
		_disc(Vector3(oc.x, g + 12.6, oc.y), n3, 0.75, 10, TP_TRIM)
		_disc(Vector3(oc.x, g + 12.6, oc.y) + n3 * 0.03, n3, 0.55, 10, TP_DARK)
	_lbox(m, 0.05, m, 0.3, g - 0.5, top, TP_WALL, M_STONE, TP_WALL)
	_lbox(m, 0.25, m + 0.1, 0.45, g - 0.5, g + 0.9, TP_BASE, M_STONE, TP_BASE)
	_lbox(m, 0.3, m, 0.5, g + 4.6, g + 4.9, TP_TRIM, M_STONE, TP_TRIM)        # string course
	_lbox(m, 0.3, m, 0.5, g + 10.4, g + 10.7, TP_TRIM, M_STONE, TP_TRIM)
	# the long iron balcony across the middle storey
	_lbox(m, 0.95, m - 0.6, 0.6, g + 5.2, g + 5.45, TP_TRIM, M_STONE, TP_TRIM)
	_lbox(m, 1.52, m - 0.6, 0.03, g + 5.45, g + 6.4, TP_IRON, M_STONE, TP_IRON)
	# cornice and the balustrade along the roof edge
	_lbox(m, 0.5, m, 0.7, top, top + 0.6, TP_TRIM, M_STONE, TP_LEAD)
	_lbox(m, 0.35, m, 0.12, top + 0.6, top + 1.5, TP_TRIM, M_STONE, TP_TRIM)
	# the drums: round bays to the cornice, a cornice ring and a balustraded top
	for c: Vector2 in TP_DRUMS:
		_prism(_circle(c, TP_DRUM_R, 16), g - 0.5, top, TP_WALL, Color(0, 0, 0, 0), M_STONE, M_STONE)
		_prism(_circle(c, TP_DRUM_R + 0.3, 16), top, top + 0.6, TP_TRIM, TP_LEAD, M_STONE, M_STONE)
		_prism(_circle(c, TP_DRUM_R + 0.35, 16), g - 0.5, g + 0.9, TP_BASE, TP_BASE, M_STONE, M_STONE)
		_parapet(_circle(c, TP_DRUM_R + 0.1, 16), top + 0.6, 0.9, TP_TRIM)
		for side: float in [-1.0, 1.0]:
			var out := (_b + _a * side * 0.55).normalized()
			_arch_panel(c + out * (TP_DRUM_R + 0.02), Vector2(-out.y, out.x), out, 0.55, g + 5.8, g + 9.2, TP_DARK, 0.04, M_GLASS)
	# the green kiosk on the walk
	_lbox(m + 3.0, 4.0, 1.0, 0.75, g, g + 2.5, TP_KIOSK, M_STONE, TP_KIOSK.darkened(0.15))
	_collide(_rect(m + 3.0, 4.0, 1.0, 0.75))


## The Staszic Palace (Pałac Staszica; Corazzi, 1820-1823) on Krakowskie Przedmieście, east side
## across from the University: the mass stays LoD2's (a kept skin); the model adds the plinth band
## and cornice along the street front, a portico of four columns under a pediment at the
## middle, and Thorvaldsen's seated Copernicus on his granite pedestal in front. Spec
## docs/landmarks/specs/staszic.md. Frame: origin at the front's north corner on the outline,
## u south along the front (53 m, straight), +v out of it to the street (west).
const STASZIC := Vector2(-415.8, -405.5)
const STASZIC_AXIS := Vector2(0.166, 0.986)
const STASZIC_MID := 14.0
const STASZIC_WALL := Color("#e6dcc4")
const STASZIC_TRIM := Color("#f0e9d6")
const STASZIC_BASE := Color("#b9ae96")
const STASZIC_ROOF := Color("#6a8f80")
const STASZIC_DOOR := Color("#3a3d40")
const STASZIC_GRANITE := Color("#8f8b85")
const STASZIC_BRONZE := Color("#4a4f46")
const STASZIC_GOLD := Color("#c9a24a")


func _build_staszic(_site: Dictionary) -> void:
	_o = STASZIC
	_a = STASZIC_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)  # (-0.986, 0.166): out of the front, to the street (west)
	var m := STASZIC_MID
	_g = map.terrain_height(_w(m, 3.0).x, _w(m, 3.0).y)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# the plinth band and the cornice along the whole front
	_lbox(26.75, 0.2, 26.75, 0.3, g - 0.6, g + 1.4, STASZIC_BASE, M_STONE, STASZIC_BASE.lightened(0.05))
	_lbox(27.5, 0.25, 25.5, 0.7, g + 15.2, g + 16.0, STASZIC_TRIM, M_STONE, STASZIC_TRIM)
	for pu: float in [2.6, 51.0]:  # corner pilasters carry the cornice
		_lbox(pu, 0.2, 0.7, 0.3, g + 1.4, g + 15.2, STASZIC_TRIM, M_STONE, STASZIC_TRIM)
	# the portico: stylobate, two steps, four columns, entablature, pediment, three doors
	_lbox(m, 3.0, 7.9, 3.3, g - 0.6, g + 1.2, STASZIC_BASE, M_STONE, STASZIC_BASE.lightened(0.05))
	_lbox(m, 6.7, 6.9, 0.55, g - 0.6, g + 0.65, STASZIC_BASE, M_STONE, STASZIC_BASE.lightened(0.04))
	_mode = M_GLASS
	for u: float in [-3.6, 0.0, 3.6]:
		_wall(_w(m + u - 1.1, 0.4), _w(m + u + 1.1, 0.4), g + 1.4, g + 6.2, _b, STASZIC_DOOR)
	_mode = M_STONE
	for u: float in [-5.4, -1.8, 1.8, 5.4]:
		_column(m + u, 4.3, 0.55, g + 1.2, g + 10.7, STASZIC_TRIM)
	_lbox(m, 2.8, 7.3, 2.6, g + 10.7, g + 11.7, STASZIC_WALL, M_STONE, STASZIC_TRIM)
	_lbox(m, 2.8, 7.6, 2.8, g + 11.7, g + 12.2, STASZIC_TRIM, M_STONE, STASZIC_TRIM)
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(5.4, 0.3, m, 7.4, g + 12.2, 2.4, STASZIC_WALL, STASZIC_ROOF)
	_a = ka
	_b = kb
	var oc := _w(m, 5.45)
	_disc(Vector3(oc.x, g + 13.4, oc.y), Vector3(_b.x, 0.0, _b.y), 0.6, 8, STASZIC_DOOR)
	# Copernicus: granite steps and pedestal, the robed figure seated, an armillary sphere
	var su := m
	var sv := 15.0
	_lbox(su, sv, 2.0, 2.0, g - 0.4, g + 0.3, STASZIC_GRANITE, M_STONE, STASZIC_GRANITE.lightened(0.05))
	_lbox(su, sv, 1.55, 1.55, g + 0.3, g + 0.7, STASZIC_GRANITE, M_STONE, STASZIC_GRANITE.lightened(0.05))
	_lbox(su, sv, 1.0, 1.0, g + 0.7, g + 2.6, STASZIC_GRANITE.lightened(0.1), M_STONE, none)
	_lbox(su, sv, 1.2, 1.2, g + 2.6, g + 2.9, STASZIC_GRANITE, M_STONE, STASZIC_GRANITE.lightened(0.05))
	_lbox(su, sv, 0.55, 0.45, g + 2.9, g + 3.7, STASZIC_BRONZE, M_STONE, STASZIC_BRONZE.lightened(0.05))
	_lbox(su - 0.05, sv, 0.36, 0.3, g + 3.7, g + 4.6, STASZIC_BRONZE, M_STONE, STASZIC_BRONZE.lightened(0.05))
	_lbox(su - 0.05, sv, 0.17, 0.17, g + 4.6, g + 4.95, STASZIC_BRONZE, M_STONE, STASZIC_BRONZE)
	var arm0 := _w(su - 0.1, sv + 0.3)
	var arm1 := _w(su - 0.4, sv + 1.05)
	_beam(Vector3(arm0.x, g + 4.2, arm0.y), Vector3(arm1.x, g + 4.1, arm1.y), 0.1, STASZIC_BRONZE)
	_lbox(su - 0.4, sv + 1.15, 0.2, 0.2, g + 3.95, g + 4.35, STASZIC_GOLD, M_STONE, STASZIC_GOLD)
	# the car meets the stylobate and the pedestal
	_collide(_rect(m, 3.0, 7.9, 3.3))
	_collide(_rect(su, sv, 2.0, 2.0))


# --- Krakowskie Przedmieście from photos (2026-11-02; first pass K1-K5 2026-11-01) -------------

## The street's landmarks, rebuilt from the reference set F's Mac gathered (refs/krakowskie/: 29
## Commons photos and three GUGiK orthophotos; docs/landmarks/photo-reports/krakowskie.md) where
## the first pass (2026-11-01) had only the OpenStreetMap outlines: the Carmelite church's front
## (`karmelici`, a kept skin), Mickiewicz's monument (`mickiewicz`), the University's main gate
## (`brama_uw`) and the portico of Pałac Kazimierzowski behind it (`kazimierzowski`, a kept skin),
## Pałac Czapskich (`czapski`), Pałac Potockich and its gates (`potocki`), the separate gallery
## (`kordegarda`), and Hotel Bristol's corner belvedere (`bristol`, a kept skin). Specs in
## docs/landmarks/specs/: karmelici.md, mickiewicz.md, brama_uw.md, kazimierzowski.md, czapski.md,
## potocki.md, kordegarda.md, bristol.md. Where the report's ortho reading and the mapped outline
## disagree by more than its ±3 m (Bristol's rotunda, the Potocki front), the outline wins, since
## the model must sit on the building the game draws.
const MICK := Vector2(-626.0, -1078.0)  # the plinth's centre (ortho; OSM node (-626, -1075))
const MICK_AXIS := Vector2(0.259, 0.966)  # along the street (south); +v is the street side (west)
const BRAMA := Vector2(-462.0, -642.0)  # the gate's centre on the east building line (ortho, ±4 m)
## The clear opening between the pavilions (the University's own figure, 3.8 x 4.5 m; F 2026-11-03),
## so the pavilions (4.4 m square) stand at u ±(1.9 + 2.2); side gates 3 m, piers outside them.
const BRAMA_OPEN := Vector2(3.8, 4.5)
const BRAMA_PAV := 4.1
const BRAMA_PIER := 9.8

const KAZIM := Vector2(-268.0, -730.0)  # in front of the centre risalit, facing WSW down the avenue
const KAZIM_OUT := Vector2(-0.909, 0.416)
const CZAP := Vector2(-599.3, -600.5)  # the centre risalit's face, facing east over the forecourt
const CZAP_OUT := Vector2(0.964, -0.266)
const POTOCKI := Vector2(-683.3, -919.0)
const POTOCKI_AXIS := Vector2(-0.2, -0.98)
## The mapped palace breaks in metres along the court front (u) and east toward the street (v).
## The open end of each range meets its separate street pavilion.
const POTOCKI_PLAN := [
	[-9.5, -22.0], [60.4, -22.4], [60.2, 16.45], [56.55, 16.45], [55.65, 46.0], [45.55, 46.0],
	[46.45, 15.5], [49.25, 7.9], [49.2, -2.4], [8.95, -2.4], [8.95, 0.02], [-0.95, 0.02],
	[-0.65, 14.0], [1.75, 17.0], [3.15, 48.2], [-8.05, 48.2], [-8.86, -3.5], [-8.5, -16.0],
]
## The upper hips share a continuous ridge around the court. Each point matches an eave corner.
const POTOCKI_RIDGE := [
	[-4.2, -12.4], [54.4, -12.2], [54.8, 12.0], [51.8, 15.0], [51.0, 42.0], [50.3, 42.0],
	[50.6, 16.0], [53.7, 8.0], [51.3, -10.9], [7.7, -11.1], [6.0, -10.9], [-3.8, -10.7],
	[-3.4, 13.5], [-2.6, 16.5], [-1.9, 44.5], [-3.3, 44.5], [-5.3, -4.0], [-4.7, -9.0],
]
## The main block is taller than the narrow side ranges where the roofs turn into the court.
const POTOCKI_RIDGE_Y := [18.6, 18.6, 17.0, 16.55, 16.55, 16.55, 16.55, 17.0, 18.6,
		18.6, 18.6, 18.6, 16.55, 16.55, 16.55, 16.55, 17.0, 18.6]
const POTOCKI_ENDS := [
	[[45.55, 46.0], [55.65, 46.0], [55.93, 56.01], [45.26, 56.8]],
	[[-8.05, 48.2], [3.15, 48.2], [3.69, 59.58], [-7.85, 60.45]],
]
## The two street gates of Pałac Potockich, each between a wing's end and the Kordegarda.
const POTOCKI_GATES := [[Vector2(-636.6, -974.4), Vector2(-631.6, -963.6)],
		[Vector2(-626.9, -946.6), Vector2(-625.4, -935.2)]]
const KORDEGARDA := Vector2(-626.3, -947.5)
const KORDEGARDA_NORTH := Vector2(-630.1, -962.9)
const BRISTOL_TOWER := Vector2(-557.8, -894.0)  # the rounded south-west corner at Karowa
const BRISTOL_KAROWA_END := Vector2(-504.6, -918.8)  # where the main block turns away from Karowa
const BRISTOL_KRAK_NORTH := Vector2(-583.0, -933.2)
const BRISTOL_KRAK_SOUTH := Vector2(-562.4, -893.6)
const BRISTOL_BAY := 4.4
const BRISTOL_MEZZ := 6.6  # 5.2 m ground floor and 1.4 m mezzanine
const BRISTOL_SILL := 7.28
const BRISTOL_ANNEX_TOP := 18.4
const BRISTOL_CORNICE := 25.2
const BRISTOL_MANSARD_INSET := 1.95
const BRISTOL_ROOF := 30.05
const BRISTOL_DRUM_TOP := 32.4
# K6 (2026-11-01): the two statues of Krakowskie Przedmieście's north end, spots projected from
# their published coordinates (Prus 52.24173 N 21.01636 E, Twardowski Square; Wyszyński
# 52.24112 N 21.01661 E, in front of the Visitationists' church); the facings are estimates.
const PRUS := Vector2(-519.7, -860.3)
const WYSZYNSKI := Vector2(-503.0, -792.6)
const STREET_AXIS := Vector2(0.37, 0.93)  # along Krakowskie Przedmieście here (south); +v is west
const KP_STONE := Color("#e2d8c0")
const KP_TRIM := Color("#f1eadb")
const KP_BASE := Color("#b3a994")

const KP_BRONZE := Color("#5e5c4c")
const KP_GRANITE := Color("#8d8a86")
const KP_COPPER := Color("#6f9382")
const KP_IRON := Color("#25282a")

# The photos' colours (report sections 1-6).
const MICK_GRANITE := Color("#cfcac0")
const MICK_BALUSTER := Color("#d8d4cc")
const MICK_BRONZE := Color("#3a3a32")
const MICK_PATINA := Color("#4a5048")
const MICK_FLAME := Color("#c9a13a")
const BRAMA_WHITE := Color("#f2f0ea")
const BRAMA_TRIM := Color("#dcd6c8")
const KAZIM_ROOF := Color("#b5503a")
const CZAP_WALL := Color("#d3644e")
const CZAP_SHADE := Color("#b5503f")
const CZAP_WHITE := Color("#f2efe8")
const CZAP_ROOF := Color("#a8503c")
## Palace and gallery colours from the v2 spec, with a darker hedge and plinth for depth.
const POTOCKI_WALL := Color("#ede8dc")
const POTOCKI_ROOF := Color("#d0643a")  # orange terracotta, as the 3D Tiles views read it (was #c5502f, deep red)
const POTOCKI_TRIM := Color("#f7f4ec")
const POTOCKI_IRON := Color("#1f2224")
const POTOCKI_SCULPT := Color("#e4ded0")
const POTOCKI_HEDGE := Color("#485f36")
const POTOCKI_PLINTH := Color("#b3a994")
const POTOCKI_TURF := Color("#6f8f4e")
const POTOCKI_PAVING := Color("#cfc6b4")
const POTOCKI_LAMP := Color("#ffd27a")
const POTOCKI_EAVE := 12.4
const POTOCKI_CURB := 15.2
const KORD_WHITE := Color("#efede6")
const KORD_SCULPT := Color("#c9c7c0")
const KORD_ROOF := Color("#8d8b86")
const KORD_GLASS := Color("#3a3d40")
const KORD_DOOR := Color("#4a3328")
const BRISTOL_WALL := Color("#e9e1c8")
const BRISTOL_SHADE := Color("#cfc6ac")
const BRISTOL_SLATE := Color("#5d6266")
const BRISTOL_ZINC := Color("#a9adb0")
const BRISTOL_GLASS := Color("#33383e")


func _find_krakowskie() -> void:
	_o = MICK
	_a = MICK_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_add_site("mickiewicz", [_rect(0.0, 1.4, 8.6, 6.9)])
	_add_site("prus", [_circle(PRUS, 3.2, 12)])
	_add_site("wyszynski", [_circle(WYSZYNSKI, 3.6, 12)])
	_o = BRAMA
	_a = STREET_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_add_site("brama_uw", [_rect(0.0, 0.0, BRAMA_PIER + 0.8, 2.6)])
	_find_uw_kampus()
	var guard := _landmark("Galeria Kordegarda")
	if guard.size() >= 3:
		_add_site("kordegarda", [guard])
		if not sites.is_empty() and sites[-1]["key"] == "kordegarda":
			sites[-1]["ring"] = guard
	var czap := _landmark("Pałac Czapskich")
	if czap.size() >= 3:
		_add_site("czapski", [_largest(Geometry2D.offset_polygon(czap, 0.6, Geometry2D.JOIN_MITER))])
		if not sites.is_empty() and sites[-1]["key"] == "czapski":
			sites[-1]["ring"] = _simplify(czap, 0.5)


## A gilt candelabrum on a post (Mickiewicz's terrace): a bronze stem, three arms with globes and
## the gilt flame on top.
func _kp_candelabrum(p: Vector2, y: float, h: float) -> void:
	_prism(_circle(p, 0.32, 6), y, y + 0.6, MICK_BRONZE, MICK_BRONZE, M_STONE, M_STONE)
	_frustum(_circle(p, 0.16, 6), y + 0.6, _circle(p, 0.09, 6), y + h - 1.2, MICK_BRONZE)
	_prism(_circle(p, 0.5, 6), y + h - 1.2, y + h - 1.05, MICK_BRONZE, MICK_BRONZE, M_STONE, M_STONE)
	for k in 3:
		var q := p + Vector2.from_angle(TAU * k / 3.0) * 0.42
		_prism(_circle(q, 0.17, 6), y + h - 1.05, y + h - 0.7, Color("#f0dfae"), Color("#f0dfae"), M_LAMP, M_LAMP)
	_frustum(_circle(p, 0.09, 6), y + h - 1.05, _circle(p, 0.07, 6), y + h - 0.45, MICK_BRONZE)
	_frustum(_circle(p, 0.2, 6), y + h - 0.45, _circle(p, 0.02, 6), y + h, MICK_FLAME)


## Adam Mickiewicz's monument (Cyprian Godebski, 1898), photos 1-4: in its own lawn square on the
## east side, facing the street (west). A raised granite terrace 16 x 10 m, 1.6 m high, with a
## stone balustrade on its front and sides, a wide flight of eight steps from the street and a
## second on the north side, a bronze candelabrum with gilt flames on each corner; on it the
## stepped pedestal with a cartouche and a bronze wreath at its foot, the tall shaft with a
## bronze medallion, and the poet standing (right hand on his chest, cloak), 13.5 m in all.
## Frame: origin at the plinth's centre, u south along the street, +v west (the street side).
func _build_mickiewicz(_site: Dictionary) -> void:
	_o = MICK
	_a = MICK_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(MICK.x, MICK.y)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var t := g + 1.6  # the terrace
	_mode = M_STONE
	_lbox(0.0, 0.0, 8.0, 5.0, g - 0.5, t, MICK_GRANITE.darkened(0.08), M_STONE, MICK_GRANITE.lightened(0.03))
	for k in 8:  # the street flight, 6 m wide
		_lbox(0.0, 5.0 + 0.35 * (8 - k) * 0.5, 3.0, 0.175 * (8 - k), g - 0.5, g + 0.2 * (k + 1), MICK_GRANITE,
				M_STONE, MICK_GRANITE.lightened(0.04))
	for k in 4:  # the north flight, 4 m wide
		_lbox(-8.0 - 0.35 * (4 - k) * 0.5, 0.0, 0.175 * (4 - k), 2.0, g - 0.5, g + 0.4 * (k + 1), MICK_GRANITE,
				M_STONE, MICK_GRANITE.lightened(0.04))
	# the balustrade: the front either side of the flight, the two sides (the north one broken
	# by its flight), the back
	for sd: float in [-1.0, 1.0]:
		_kp_balustrade(sd * 3.3, 4.8, sd * 7.8, 4.8, t, 0.95, MICK_BALUSTER, 2.3)
		_kp_balustrade(7.8, sd * 4.8, 7.8, sd * 0.4, t, 0.95, MICK_BALUSTER, 2.2)
		_kp_balustrade(-7.8, sd * 4.8, -7.8, sd * 2.3, t, 0.95, MICK_BALUSTER, 2.5)
	_kp_balustrade(-7.8, -4.8, 7.8, -4.8, t, 0.95, MICK_BALUSTER, 3.9)
	for su: float in [-1.0, 1.0]:
		for sv: float in [-1.0, 1.0]:
			_kp_candelabrum(_w(su * 7.2, sv * 4.2), t, 5.0)
	# the pedestal: two steps, the die with the cartouche, the bronze wreath group at its foot
	_lbox(0.0, 0.0, 2.6, 2.6, t, t + 0.5, MICK_GRANITE, M_STONE, MICK_GRANITE.lightened(0.05))
	_lbox(0.0, 0.0, 2.1, 2.1, t + 0.5, t + 1.0, MICK_GRANITE, M_STONE, MICK_GRANITE.lightened(0.05))
	_lbox(0.0, 0.0, 1.7, 1.7, t + 1.0, t + 3.2, MICK_GRANITE.lightened(0.03), M_STONE, none)
	_lbox(0.0, 1.72, 0.8, 0.05, t + 1.6, t + 2.8, MICK_GRANITE.lightened(0.1), M_STONE, MICK_GRANITE)  # cartouche
	_lbox(0.0, 2.1, 1.4, 0.35, t + 1.0, t + 1.8, MICK_PATINA, M_STONE, MICK_PATINA)  # wreath and foliage
	_lbox(0.0, 0.0, 1.9, 1.9, t + 3.2, t + 3.6, MICK_GRANITE.lightened(0.06), M_STONE, MICK_GRANITE.lightened(0.1))
	# the shaft with its medallion, a cornice
	_lbox(0.0, 0.0, 1.05, 1.05, t + 3.6, t + 9.4, MICK_GRANITE.lightened(0.08), M_STONE, none)
	var med := _w(0.0, 1.08)
	_disc(Vector3(med.x, t + 6.4, med.y), Vector3(_b.x, 0.0, _b.y), 0.65, 8, MICK_PATINA)
	_lbox(0.0, 0.0, 1.35, 1.35, t + 9.4, t + 9.9, MICK_GRANITE.lightened(0.06), M_STONE, MICK_GRANITE.lightened(0.1))
	# the poet: cloak, chest, head, the right hand on the chest
	_kp_figure(0.0, 0.0, t + 9.9, 4.5, MICK_PATINA)
	_lbox(0.3, 0.4, 0.14, 0.12, t + 9.9 + 3.0, t + 9.9 + 3.35, MICK_PATINA, M_STONE, MICK_PATINA)
	_collide(_rect(0.0, 1.4, 8.0, 6.4))


## Pałac Kazimierzowski (the rector's palace at the far end of the campus avenue), photos 16-17:
## the mass stays LoD2's (a kept skin, now in its ochre with a red tile roof); the model adds the
## centre risalit's front, which closes the vista from the gate: a rusticated ground floor with
## three round-arched doors, four white Corinthian columns over two storeys on it, an entablature
## and a triangular pediment. Frame: origin in front of the risalit, u along the front (SSE), +v out
## of it (west-south-west, down the avenue).
func _build_kazimierzowski(_site: Dictionary) -> void:
	_o = KAZIM
	_b = KAZIM_OUT.normalized()
	_a = Vector2(_b.y, -_b.x)
	_g = map.terrain_height(KAZIM.x, KAZIM.y)
	var g := _g
	var ochre := Color("#e2c77a")
	_mode = M_STONE
	_lbox(0.0, 0.5, 6.4, 0.9, g - 0.5, g + 4.6, ochre.lightened(0.12), M_STONE, ochre)  # the rusticated porch
	for k in 4:  # its courses
		_lbox(0.0, 1.42, 6.4, 0.04, g + 0.6 + k * 1.0, g + 0.72 + k * 1.0, ochre.darkened(0.1), M_STONE, ochre)
	for u: float in [-3.2, 0.0, 3.2]:
		_kp_arch_open(u, 1.5, g + 0.0, g + 2.5, 0.85, KP_WOOD)
	_lbox(0.0, 0.6, 6.5, 1.0, g + 4.6, g + 5.0, KAZIM_WHITE, M_STONE, KAZIM_WHITE)
	for u: float in [-4.5, -1.5, 1.5, 4.5]:
		_column(u, 0.9, 0.42, g + 5.0, g + 12.6, KAZIM_WHITE)
	_lbox(0.0, 0.4, 6.0, 0.9, g + 12.6, g + 13.6, KAZIM_WHITE, M_STONE, KAZIM_WHITE)
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(1.3, -0.5, 0.0, 6.0, g + 13.6, 2.4, KAZIM_WHITE, KAZIM_ROOF)
	_a = ka
	_b = kb
	_collide(_rect(0.0, 0.5, 6.4, 0.9))


const KAZIM_WHITE := Color("#f3f1ea")


# --- The University's main campus (F's 21 photos, 2026-11-15) ---------------------------------

## Kampus Centralny Uniwersytetu Warszawskiego behind the main gate, from F's photos of
## 2026-11-15 (refs/uw_campus/f_photos: the gate, Pałac Uruskich, the Old Library's front and
## flank, Pałac Kazimierzowski's garden front, the escarpment wall over Powiśle, the guards'
## kiosk and their cart, the campus board's numbered plan 1-23 and aerial), OSM outlines and LoD2
## heights. Spec docs/landmarks/specs/uw_kampus.md. The board's numbers: 1 the gate (`brama_uw`),
## 3 Pałac Czetwertyńskich-Uruskich (`uruski`, OSM "Wydział Geografii..."), 13 Pałac
## Kazimierzowski (`kazimierzowski`, its garden front added here), 17 the Old Library (`stara_buw`,
## OSM "Stary BUW"), the escarpment wall (`uw_skarpa`, OSM wall line 1629), the guards' kiosk
## (`uw_straz`, OSM kiosk "Ruch") and the campus furniture (`uw_kampus`: bollards and chains, the
## flagpoles, the howitzer in the palace garden).

const UW_CREAM := Color("#ebdcb6")      ## Pałac Uruskich's warm cream plaster (photos 8047, 8049)
const UW_CREAM_LIT := Color("#f2e7cb")  ## its pilasters, cornice and window surrounds
const UW_LIB := Color("#ede4c9")        ## the Old Library's pale stone (8056)
const UW_LIB_TRIM := Color("#f5efdc")   ## its columns, balustrades and cornice
const UW_COPPER := Color("#7aa08e")     ## the Old Library's green copper roof (8070)
const UW_YELLOW := Color("#e6cd7e")     ## Kazimierzowski's garden front (8065, 8066)
const UW_BRICK := Color("#9a4a36")      ## the escarpment wall's brick (8066-8068)
const UW_BRICK_DARK := Color("#7d3a2b")
const UW_CAP := Color("#b9b3a5")        ## its concrete coping
const UW_KIOSK := Color("#2f5a48")      ## the guards' kiosk, green panelling (8063, 8074)
const UW_KIOSK_DARK := Color("#21423a")
const UW_TILE := Color("#c4553a")       ## its red sheet-tile roof
const UW_BLIND := Color("#d6d4c8")      ## the pale blinds behind its windows

## The Old Library's front (the board's 17): the outline's west face, north end to south end,
## so +v points out (west, down the avenue to the gate). The middle (u 6.1-19.4) stands 2.9 m out.
const UW_LIB_N := Vector2(-334.9, -713.7)
const UW_LIB_S := Vector2(-324.3, -690.5)
## Pałac Uruskich's street front (the board's 3): north end to south end, +v out to the street.
const UW_URU_N := Vector2(-487.3, -691.7)
const UW_URU_S := Vector2(-469.2, -650.5)
## Kazimierzowski's garden front (east, over the escarpment): the middle risalit's face, south
## end to north end so +v points east, out over Powiśle.
const UW_KAZ_S := Vector2(-238.7, -736.0)
const UW_KAZ_N := Vector2(-244.1, -747.6)


func _find_uw_kampus() -> void:
	var kiosk := _landmark_near("Ruch", Vector2(-402.0, -691.0), 20.0)
	if kiosk.size() >= 3:
		_add_site("uw_straz", [_largest(Geometry2D.offset_polygon(kiosk, 0.5, Geometry2D.JOIN_MITER))])
		if not sites.is_empty() and sites[-1]["key"] == "uw_straz":
			sites[-1]["ring"] = kiosk


## The campus's quiet sites (no card): found with the other quiet sites at the end of the list,
## because the cards (`info`) skip quiet sites and a carded site after one gets another's tap id.
func _find_uw_kampus_quiet() -> void:
	# The escarpment wall: a thin zone along the line (no building's centre falls in it).
	var wall := _uw_skarpa_line()
	if wall.size() >= 2:
		var band := Geometry2D.offset_polyline(wall, 2.0, Geometry2D.JOIN_MITER, Geometry2D.END_BUTT)
		if not band.is_empty():
			_add_site("uw_skarpa", [_largest(band)])
			if not sites.is_empty() and sites[-1]["key"] == "uw_skarpa":
				sites[-1]["line"] = wall
				sites[-1]["quiet"] = true
	# The furniture: thin zones round each row (bollards in front of Uruski, the flagpoles).
	_o = UW_URU_N
	_a = (UW_URU_S - UW_URU_N).normalized()
	_b = Vector2(-_a.y, _a.x)
	var zones: Array = [_rect(23.0, 3.0, 22.0, 0.6)]
	_o = UW_LIB_N
	_a = (UW_LIB_S - UW_LIB_N).normalized()
	_b = Vector2(-_a.y, _a.x)
	zones.append(_rect(12.8, 13.0, 19.0, 0.8))
	_add_site("uw_kampus", zones)
	if not sites.is_empty() and sites[-1]["key"] == "uw_kampus":
		sites[-1]["quiet"] = true


## OSM's escarpment wall (way 1629 of the 2026-11-15 map), copied here: `lines` reach only the
## sectors, and the site must be found the same on both city paths.
const UW_SKARPA := [-210.5, -650.9, -214.2, -658.9, -208.4, -661.6, -214.3, -674.7, -213.2, -675.7, -212.6, -676.6, -212.3, -677.9, -212.0, -678.7, -212.4, -680.4, -213.5, -681.9, -214.7, -682.7, -216.2, -683.0, -219.4, -706.0, -219.8, -709.2, -215.7, -710.9, -221.0, -722.9, -212.4, -726.9, -231.3, -773.4, -241.6, -781.5, -292.2, -821.1, -299.0, -822.8, -317.5, -819.6, -361.8, -811.5, -365.1, -815.5]


func _uw_skarpa_line() -> PackedVector2Array:
	return _pts(UW_SKARPA)


## A segmental (curved) gable on a face in the local frame: the face at v (its out side towards
## +v when `side` is 1, -v when -1), from u - hw to u + hw, its foot at y, its crown `rise` over it;
## the face in `col`, a moulding along the curve in `trim` and its top running `depth` back in.
func _uw_arc_gable(cu: float, v: float, hw: float, y: float, rise: float, depth: float, col: Color, trim: Color,
		side := 1.0) -> void:
	var seg := 8
	var n3 := Vector3(_b.x, 0.0, _b.y) * side
	var prev_u := cu - hw
	var prev_y := y
	var c0 := _w(cu, v)
	for k in range(1, seg + 1):
		var t := float(k) / seg
		var uu := cu - hw + 2.0 * hw * t
		var yy := y + rise * sin(PI * t)
		var p0 := _w(prev_u, v)
		var p1 := _w(uu, v)
		var q0 := _w(prev_u, v + side * 0.08)
		var q1 := _w(uu, v + side * 0.08)
		var e0 := _w(prev_u, v - side * depth)
		var e1 := _w(uu, v - side * depth)
		# The face as a fan from the base's middle: a quad down to the base line has no height
		# at the ends (degenerate triangles in check_mesh_quality).
		_tri(Vector3(c0.x, y, c0.y), Vector3(p0.x, prev_y, p0.y), Vector3(p1.x, yy, p1.y), n3, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
		if side > 0.0:
			_quad(Vector3(q0.x, prev_y, q0.y), Vector3(q1.x, yy, q1.y), Vector3(q1.x, yy + 0.22, q1.y),
					Vector3(q0.x, prev_y + 0.22, q0.y), n3, trim)
			_quad(Vector3(q0.x, prev_y + 0.22, q0.y), Vector3(q1.x, yy + 0.22, q1.y), Vector3(e1.x, yy + 0.22, e1.y),
					Vector3(e0.x, prev_y + 0.22, e0.y), Vector3.UP, trim.darkened(0.05))
		else:
			_quad(Vector3(q1.x, yy, q1.y), Vector3(q0.x, prev_y, q0.y), Vector3(q0.x, prev_y + 0.22, q0.y),
					Vector3(q1.x, yy + 0.22, q1.y), n3, trim)
			_quad(Vector3(q1.x, yy + 0.22, q1.y), Vector3(q0.x, prev_y + 0.22, q0.y), Vector3(e0.x, prev_y + 0.22, e0.y),
					Vector3(e1.x, yy + 0.22, e1.y), Vector3.UP, trim.darkened(0.05))
		prev_u = uu
		prev_y = yy


## The University's main gate (Brama Główna, Krakowskie Przedmieście 26/28; Stefan Szyller,
## 1910), rebuilt from F's photos 8047-8049 (2026-11-15): two white pavilions, each on a plinth
## with a pair of banded pilasters either side of a shell-headed niche and its statue (Minerva
## north, Apollo south), garland capitals, an entablature, a broken segmental pediment round a
## big cartouche, a stepped attic with scrolls and an iron lamp on a post at the top; the three
## flags on the south pavilion. Between them the wrought-iron gate's two leaves and its scrolled
## arch with the crowned eagle; outside each pavilion a narrow iron side gate with a scrolled
## overthrow, and the outer pier, banded like the pilasters, with its carved urn.
## Frame: origin at the gate's centre on the building line, u south along the street, +v out to
## the street (west-south-west).
func _build_brama_uw(_site: Dictionary) -> void:
	_o = BRAMA
	_a = STREET_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(BRAMA.x, BRAMA.y)
	var g := _g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	var shade := BRAMA_TRIM.darkened(0.12)
	var iron := KP_IRON
	for sd: float in [-1.0, 1.0]:
		var u := sd * BRAMA_PAV
		# the pavilion: plinth, body, the banded pilaster pairs, the niche and its statue
		_lbox(u, 0.0, 2.35, 2.35, g - 0.5, g + 0.9, BRAMA_TRIM, M_STONE, BRAMA_TRIM)
		_lbox(u, 0.0, 2.2, 2.2, g + 0.9, g + 5.9, BRAMA_WHITE, M_STONE, none)
		for su: float in [-1.0, 1.0]:
			for k in 2:
				var pu := u + su * (1.85 - 0.62 * k)
				_lbox(pu, 2.26, 0.26, 0.08, g + 0.9, g + 5.4, BRAMA_WHITE.lightened(0.03), M_STONE, BRAMA_WHITE)
				for r in 6:  # the bands
					_lbox(pu, 2.35, 0.27, 0.02, g + 1.25 + 0.7 * r, g + 1.33 + 0.7 * r, shade, M_STONE, shade)
				_lbox(pu, 2.3, 0.3, 0.1, g + 5.4, g + 5.75, BRAMA_TRIM, M_STONE, BRAMA_TRIM)  # garland capital
		_kp_arch_open(u, 2.25, g + 1.7, g + 4.3, 0.62, shade.darkened(0.2))
		_lbox(u, 2.4, 0.55, 0.18, g + 1.45, g + 1.75, BRAMA_TRIM, M_STONE, BRAMA_TRIM)  # the statue's console
		_kp_figure(u, 2.3, g + 1.75, 2.5, BRAMA_WHITE.darkened(0.06))
		# the entablature, the broken segmental pediment and its cartouche
		_lbox(u, 0.0, 2.4, 2.4, g + 5.9, g + 6.5, BRAMA_TRIM, M_STONE, BRAMA_TRIM)
		_lbox(u, 0.0, 2.55, 2.55, g + 6.5, g + 6.75, BRAMA_WHITE, M_STONE, BRAMA_WHITE)
		for sv: float in [-1.0, 1.0]:  # the segmental pediment on the street and campus faces
			_uw_arc_gable(u, sv * 2.5, 2.5, g + 6.75, 1.1, 0.35, BRAMA_WHITE, BRAMA_TRIM, sv)
		var cart := _w(u, 2.66)  # clear of the pediment's trim at v 2.58 (2 cm apart z-fought)
		_lbox(u, 2.15, 0.85, 0.4, g + 6.75, g + 8.6, BRAMA_WHITE.lightened(0.02), M_STONE, BRAMA_WHITE)
		_disc(Vector3(cart.x, g + 7.65, cart.y), Vector3(_b.x, 0.0, _b.y), 0.62, 8, BRAMA_TRIM)
		_disc(Vector3(cart.x, g + 7.65, cart.y) + Vector3(_b.x, 0.0, _b.y) * 0.04, Vector3(_b.x, 0.0, _b.y), 0.42, 8, BRAMA_WHITE)
		# the stepped attic with its scrolls, its dark cap, the iron lamp on its post
		_lbox(u, 0.0, 1.9, 1.9, g + 6.75, g + 8.3, BRAMA_WHITE, M_STONE, BRAMA_WHITE)
		for su: float in [-1.0, 1.0]:
			var sc := _w(u + su * 1.3, 0.0)
			_frustum(_circle(sc, 0.5, 6), g + 8.3, _circle(sc, 0.18, 6), g + 9.0, BRAMA_TRIM, BRAMA_TRIM)
		_lbox(u, 0.0, 1.1, 1.1, g + 8.3, g + 9.4, BRAMA_WHITE, M_STONE, BRAMA_WHITE)
		_lbox(u, 0.0, 1.2, 1.2, g + 9.4, g + 9.52, Color("#77756f"), M_STONE, Color("#8a8882"))
		_lbox(u, 0.0, 0.55, 0.55, g + 9.6, g + 10.2, BRAMA_WHITE, M_STONE, BRAMA_TRIM)
		var c := _w(u, 0.0)
		_prism(_circle(c, 0.06, 6), g + 10.2, g + 12.6, iron, iron, M_STONE, M_STONE)
		_frustum(_circle(c, 0.16, 6), g + 12.6, _circle(c, 0.24, 6), g + 13.1, Color("#f0dfae"), none)
		_mode = M_LAMP
		_prism(_circle(c, 0.2, 6), g + 12.65, g + 13.05, Color("#f0dfae"), none, M_LAMP)
		_mode = M_STONE
		_frustum(_circle(c, 0.28, 6), g + 13.1, _circle(c, 0.04, 6), g + 13.45, iron, iron)
		# the outer pier: plinth, banded shaft, cornice, the carved urn
		var p := sd * BRAMA_PIER
		_lbox(p, 0.0, 0.75, 0.75, g - 0.3, g + 0.8, BRAMA_TRIM, M_STONE, BRAMA_TRIM)
		_lbox(p, 0.0, 0.62, 0.62, g + 0.8, g + 5.1, BRAMA_WHITE, M_STONE, none)
		for r in 6:
			_lbox(p, 0.0, 0.64, 0.64, g + 1.2 + 0.68 * r, g + 1.27 + 0.68 * r, shade, M_STONE, shade)
		_lbox(p, 0.0, 0.8, 0.8, g + 5.1, g + 5.55, BRAMA_TRIM, M_STONE, BRAMA_TRIM)
		_lbox(p, 0.0, 0.5, 0.5, g + 5.55, g + 6.0, BRAMA_WHITE, M_STONE, BRAMA_WHITE)
		var q := _w(p, 0.0)
		_frustum(_circle(q, 0.22, 8), g + 6.0, _circle(q, 0.58, 8), g + 6.6, BRAMA_TRIM)
		_frustum(_circle(q, 0.58, 8), g + 6.6, _circle(q, 0.4, 8), g + 7.0, BRAMA_TRIM)
		_frustum(_circle(q, 0.4, 8), g + 7.0, _circle(q, 0.1, 8), g + 7.5, BRAMA_TRIM, BRAMA_TRIM)
		# the side gate between the pavilion and the pier: frame, bars, the scrolled overthrow
		var g0 := BRAMA_PAV + 2.2
		var g1 := BRAMA_PIER - 0.62
		var gu := sd * (g0 + g1) * 0.5
		var gw := (g1 - g0) * 0.5
		_lbox(gu, 0.0, gw, 0.04, g + 0.2, g + 0.32, iron, M_STONE, iron)
		_lbox(gu, 0.0, gw, 0.04, g + 3.6, g + 3.72, iron, M_STONE, iron)
		var bars := maxi(int(gw * 2.0 / 0.32), 4)
		for k in bars + 1:
			_lbox(gu - gw + 2.0 * gw * k / bars, 0.0, 0.025, 0.025, g + 0.2, g + 3.72, iron, M_STONE, iron)
		for k in 3:  # the overthrow's scrolls, rising to the middle
			var su := gu + (float(k) - 1.0) * gw * 0.6
			var top := g + 3.72 + (0.9 if k == 1 else 0.55)
			_lbox(su, 0.0, gw * 0.28, 0.03, top - 0.08, top, iron, M_STONE, iron)
			_lbox(su, 0.0, 0.03, 0.03, g + 3.72, top, iron, M_STONE, iron)
		_disc(Vector3(_w(gu, 0.05).x, g + 2.0, _w(gu, 0.05).y), Vector3(_b.x, 0.0, _b.y), 0.35, 8, iron)
	# the flags on the south pavilion's street face (Poland, Warsaw, the EU)
	var flags: Array = [[Color("#f3f1ee"), Color("#d4213d")], [Color("#e9c331"), Color("#c8322e")], [Color("#2a4a9a"), Color("#2a4a9a")]]
	for k in 3:
		var fu := BRAMA_PAV - 0.5 + 0.5 * k
		var base := _w(fu, 2.42)
		var tip := _w(fu + 0.35 * (k - 1), 3.3)
		var n3 := Vector3(_a.x, 0.0, _a.y)
		var pole := Vector3(_a.x, 0.0, _a.y) * 0.025
		_quad(Vector3(base.x, g + 4.4, base.y) - pole, Vector3(tip.x, g + 5.9, tip.y) - pole, Vector3(tip.x, g + 5.9, tip.y) + pole,
				Vector3(base.x, g + 4.4, base.y) + pole, Vector3(_b.x, 0.0, _b.y), iron)
		var f: Array = flags[k]
		_quad(Vector3(tip.x, g + 5.85, tip.y), Vector3(base.x, g + 4.5, base.y), Vector3(base.x, g + 3.95, base.y),
				Vector3(tip.x, g + 5.3, tip.y), n3, f[0])
		_quad(Vector3(base.x, g + 4.5, base.y), Vector3(tip.x, g + 5.85, tip.y), Vector3(tip.x, g + 5.3, tip.y),
				Vector3(base.x, g + 3.95, base.y), -n3, f[0])
		_quad(Vector3(tip.x, g + 5.3, tip.y), Vector3(base.x, g + 3.95, base.y), Vector3(base.x, g + 3.4, base.y),
				Vector3(tip.x, g + 4.75, tip.y), n3, f[1])
		_quad(Vector3(base.x, g + 3.95, base.y), Vector3(tip.x, g + 5.3, tip.y), Vector3(tip.x, g + 4.75, tip.y),
				Vector3(base.x, g + 3.4, base.y), -n3, f[1])
	# the main gate: two leaves of bars with a scrolled band, the arch of scrolls, the eagle
	var hw := BRAMA_OPEN.x * 0.5  # the clear opening, 3.8 x 4.5 m (University, bgl.uw.edu.pl)
	var top := BRAMA_OPEN.y
	_lbox(0.0, 0.0, hw, 0.05, g + 0.25, g + 0.4, iron, M_STONE, iron)
	_lbox(0.0, 0.0, hw, 0.05, g + 1.9, g + 2.0, iron, M_STONE, iron)
	_lbox(0.0, 0.0, hw, 0.05, g + top - 0.15, g + top, iron, M_STONE, iron)
	_lbox(0.0, 0.0, 0.05, 0.06, g + 0.25, g + top, iron, M_STONE, iron)  # where the leaves meet
	for k in 13:
		var bu := -hw + 0.15 + (2.0 * hw - 0.3) * k / 12.0
		_lbox(bu, 0.0, 0.022, 0.022, g + 0.25, g + top, iron, M_STONE, iron)
	for sd: float in [-1.0, 1.0]:  # a ring of scrolls in each leaf
		var rc := _w(sd * hw * 0.5, 0.06)
		_disc(Vector3(rc.x, g + 1.15, rc.y), Vector3(_b.x, 0.0, _b.y), 0.55, 8, iron)
		_disc(Vector3(rc.x, g + 1.15, rc.y) + Vector3(_b.x, 0.0, _b.y) * 0.04, Vector3(_b.x, 0.0, _b.y), 0.4, 8, BRAMA_TRIM.darkened(0.55))
	for k in 7:  # the arch: scroll bars rising to the eagle
		var t := (float(k) - 3.0) / 3.0
		var au := t * hw * 0.95
		var ah := 1.35 * (1.0 - t * t)
		_lbox(au, 0.0, 0.03, 0.03, g + top, g + top + ah, iron, M_STONE, iron)
		if k < 6:
			var t1 := (float(k) - 2.0) / 3.0
			var bh := 1.35 * (1.0 - t1 * t1)
			_lbox(au + hw * 0.95 / 6.0, 0.0, hw * 0.95 / 6.0, 0.03, g + top + (ah + bh) * 0.5 - 0.05, g + top + (ah + bh) * 0.5 + 0.05,
					iron, M_STONE, iron)
	_lbox(0.0, 0.0, 0.32, 0.1, g + top + 1.35, g + top + 2.0, iron, M_STONE, iron)  # the eagle
	_lbox(0.0, 0.0, 0.85, 0.06, g + top + 1.65, g + top + 1.95, iron, M_STONE, iron)  # its wings
	for sd: float in [-1.0, 1.0]:
		_lbox(sd * 0.7, 0.0, 0.18, 0.06, g + top + 1.95, g + top + 2.25, iron, M_STONE, iron)
	_frustum(_circle(_w(0.0, 0.0), 0.16, 6), g + top + 2.0, _circle(_w(0.0, 0.0), 0.22, 6), g + top + 2.3, KP_GOLD, KP_GOLD)
	_collide(_rect(0.0, 0.0, BRAMA_PIER + 0.4, 2.3))


## Pałac Czetwertyńskich-Uruskich (Krakowskie Przedmieście 30, Andrzej Gołoński 1844-47, the
## board's 3), F's photos 8047 and 8049: its street front in warm cream. LoD2 keeps the mass (a
## kept skin); the model adds the front: a rusticated ground floor, the two end risalits a storey
## taller (three bays each, corner pilasters, a deep cornice on rows of consoles), the lower middle
## (seven bays) with its iron balcony over the door and a statue on the cornice, pedimented windows
## on the first floor, plain ones above. In front of it the bollards and chains (`uw_kampus`).
func _build_uruski(_site: Dictionary) -> void:
	kit_front(UW_URU_N, UW_URU_S)
	_g = map.terrain_height((UW_URU_N.x + UW_URU_S.x) * 0.5, (UW_URU_N.y + UW_URU_S.y) * 0.5)
	var g := _g
	_mode = M_STONE
	var wall := UW_CREAM
	var trim := UW_CREAM_LIT
	var glass := PAL_GLASS_DARK
	var mid := [11.3, 33.8]
	var base_top := g + 5.0
	# the middle: wall, rustication, the first-floor band, windows with relief panels under the
	# pedimented ones, cornice, the balcony
	kit_face(0.1)
	kit_wall(mid[0], mid[1], g - 0.4, g + 16.0, wall)
	kit_bands(mid[0], mid[1], g + 0.6, base_top, 0.55, wall)
	kit_ledge(mid[0], mid[1], base_top, 0.35, trim, 0.12)
	kit_face(0.15)  # the ground floor's openings stand clear of the rustication's grooves
	var bays := kit_window_grid(mid[0] + 0.6, mid[1] - 0.6, 7, [g + 1.3], 2.5, Win.SILL, trim, glass, 0.62, [Vector2i(1, 0)])
	kit_door(bays[1], g, 3.4, 0.75, trim, PAL_OAK)
	kit_face(0.1)
	kit_window_grid(mid[0] + 0.6, mid[1] - 0.6, 7, [g + 6.4], 2.6, Win.PEDIMENT, trim, glass, 0.62, [Vector2i(1, 0)])
	kit_window_grid(mid[0] + 0.6, mid[1] - 0.6, 7, [g + 11.3], 2.1, Win.SILL_HEAD, trim, glass, 0.58)
	kit_window(bays[1], g + 6.4, 2.9, Win.PEDIMENT, trim, glass, 0.62)  # the balcony door
	kit_balcony(bays[1], g + 6.2, 1.6, Balcony.IRON, PAL_IRON, trim, 1.1)
	for k in bays.size():
		if k != 1:
			_kbox(bays[k] - 0.55, bays[k] + 0.55, 0.1, 0.16, g + 5.55, g + 6.05, trim)  # the panel under the sill
	kit_ledge(mid[0], mid[1], g + 10.6, 0.2, trim)
	kit_cornice(mid[0], mid[1], g + 16.0, trim, 0.55, 0.9)
	_uw_uruski_group((bays[1] + bays[2]) * 0.5, g + 16.55, trim.darkened(0.08))
	# the risalits: a storey taller, four fluted giant pilasters, the frieze of paired consoles
	# under the deep cornice (photos 8047, 8049)
	for r: Array in [[0.0, 11.3], [33.8, 45.0]]:
		_uw_uruski_risalit(r[0], r[1], 0.7, g, base_top, wall, trim, glass)
	# the south risalit's side over the gate (8049): the same three bays, then plain wall back to
	# where LoD2's mass steps in
	var side := kit_front(UW_URU_S, Vector2(-456.1, -655.9))
	kit_face(0.1)  # clear of LoD2's wall on the outline
	kit_wall(-0.7, side, g - 0.4, g + 20.6, wall)
	kit_bands(-0.7, side, g + 0.6, base_top, 0.55, wall)
	kit_ledge(-0.7, side, base_top, 0.35, trim, 0.12)
	kit_cornice(11.3, side, g + 20.6, trim, 0.6, 1.0)
	_uw_uruski_risalit(-0.7, 11.3, 0.1, g, base_top, wall, trim, glass)
	kit_front(UW_URU_N, UW_URU_S)
	_collide(_lrect(Rect2(0.0, -1.0, 45.0, 2.0)))


## One face of Uruski's risalit from u0 to u1 standing at v: rusticated ground floor, three bays
## between four fluted giant pilasters with leafy capitals, pedimented first-floor windows over
## relief panels, the frieze of paired consoles and the deep cornice at g + 20.6.
func _uw_uruski_risalit(u0: float, u1: float, v: float, g: float, base_top: float, wall: Color, trim: Color, glass: Color) -> void:
	kit_face(v)
	kit_wall(u0, u1, g - 0.4, g + 20.6, wall)
	kit_bands(u0, u1, g + 0.6, base_top, 0.55, wall)
	kit_ledge(u0, u1, base_top, 0.35, trim, 0.12)
	var step := (u1 - u0 - 1.0) / 3.0
	var flute := trim.darkened(0.12)
	for i in 4:  # the giant pilasters, fluted, from the first floor to the frieze
		var pu := u0 + 0.5 + i * step
		kit_pilaster(pu, base_top + 0.35, g + 18.7, trim, 0.8, 0.16)
		for f: float in [-0.2, 0.0, 0.2]:
			_kbox(pu + f - 0.04, pu + f + 0.04, v + 0.15, v + 0.17, base_top + 0.9, g + 18.0, flute)
		_kbox(pu - 0.5, pu + 0.5, v - 0.02, v + 0.3, g + 18.0, g + 18.7, trim.lightened(0.04))  # the capital's leaves
	var centres: Array[float] = []
	for i in 3:
		centres.append(u0 + 0.5 + (i + 0.5) * step)
	kit_face(v + 0.05)
	for c: float in centres:
		kit_window(c, g + 1.3, 2.5, Win.SILL, trim, glass, 0.62)
		kit_window(c, g + 6.4, 2.6, Win.PEDIMENT, trim, glass, 0.62)
		kit_window(c, g + 11.0, 2.4, Win.SILL_HEAD, trim, glass, 0.6)
		kit_window(c, g + 15.4, 2.0, Win.SILL_HEAD, trim, glass, 0.6)
		_kbox(c - 0.55, c + 0.55, v + 0.05, v + 0.11, g + 5.55, g + 6.05, trim)  # the panel under the sill
	kit_face(v)
	kit_ledge(u0, u1, g + 10.4, 0.2, trim)
	kit_ledge(u0, u1, g + 18.7, 0.25, trim, 0.2)  # the frieze's foot
	var n := int((u1 - u0) / 0.7)
	for k in n:  # the paired consoles of the frieze
		var cu := u0 + 0.35 + k * (u1 - u0 - 0.7) / maxf(n - 1, 1)
		_kbox(cu - 0.1, cu + 0.1, v, v + 0.7, g + 19.0, g + 20.05, trim)
	kit_cornice(u0, u1, g + 20.6, trim, 0.6, 1.3)


## The sculpture group on Uruski's middle (8047, 8049): a high pedestal with scrolls at its
## sides, a rearing horse and two figures, about 4.5 m over the cornice.
func _uw_uruski_group(u: float, y: float, col: Color) -> void:
	var lit := col.lightened(0.06)
	_lbox(u, 0.5, 1.3, 0.8, y, y + 1.4, lit, M_STONE, lit)  # the pedestal
	for s: float in [-1.0, 1.0]:
		_lbox(u + s * 1.55, 0.5, 0.3, 0.5, y, y + 0.9, lit, M_STONE, lit)  # its scrolls
	var top := y + 1.4
	_lbox(u + 0.1, 0.5, 0.95, 0.32, top + 0.9, top + 1.7, col, M_STONE, col)  # the horse's body
	for s: float in [-1.0, 1.0]:
		_lbox(u + s * 0.7, 0.5, 0.12, 0.12, top, top + 0.95, col, M_STONE, col)  # its legs
	_lbox(u + 1.0, 0.5, 0.2, 0.18, top + 1.5, top + 2.6, col, M_STONE, col)  # its raised neck and head
	_kp_figure(u - 0.3, 0.5, top + 1.5, 1.8, col)  # the rider
	_kp_figure(u - 1.0, 0.75, top, 2.5, col)  # the figure holding it


## The Old Library (Stara Biblioteka, Antoni Adamski and Stefan Szyller 1891-94, the board's 17),
## F's photos 8050, 8056, 8070, 8071: its front closes the avenue from the gate. LoD2 keeps the
## mass (a kept skin, the roof in green copper); the model adds the front: a rusticated ground
## floor with the door and two statues in round-headed niches, four Corinthian half-columns over
## the first and mezzanine floors on the middle and pilasters on the ends, tall round-headed
## windows over little balustrades, the mezzanine's paired windows, the entablature, balustrades
## on the ends, and on the middle the attic with the clock (a real one: the hands show Warsaw's
## time) and the sculpture group of three. On the flanks, giant pilasters with busts between the
## windows (8070), along the 24 m nearest the front.
func _build_stara_buw(_site: Dictionary) -> void:
	kit_front(UW_LIB_N, UW_LIB_S)
	_g = map.terrain_height((UW_LIB_N.x + UW_LIB_S.x) * 0.5, (UW_LIB_N.y + UW_LIB_S.y) * 0.5)
	var g := _g
	_mode = M_STONE
	var wall := UW_LIB
	var trim := UW_LIB_TRIM
	var glass := PAL_GLASS_DARK
	var top := g + 15.4  # the entablature's foot
	for part: Array in [[0.0, 6.1, 0.12], [19.4, 25.5, 0.12], [6.1, 19.4, 3.02]]:
		var u0: float = part[0]
		var u1: float = part[1]
		var f: float = part[2]
		var middle := f > 1.0
		kit_face(f)
		kit_wall(u0, u1, g - 0.4, top + 1.3, wall)
		kit_bands(u0, u1, g + 0.5, g + 4.6, 0.5, wall)
		kit_ledge(u0, u1, g + 4.6, 0.3, trim, 0.14)
		kit_ledge(u0, u1, g + 12.2, 0.18, trim)
		kit_ledge(u0, u1, top, 1.3, trim, 0.1)  # the entablature
		kit_cornice(u0, u1, top + 1.3, trim, 0.4, 0.8)
		if middle:
			# ground floor: a niche, the door, a niche; above, three arched windows between four half-columns
			kit_face(f + 0.05)
			for k in 3:
				var cu := u0 + 2.2 + k * 4.45
				if k == 1:
					kit_door(cu, g, 4.0, 1.05, trim, PAL_DARK_DOOR, true)
				else:
					_kp_arch_open(cu, f + 0.07, g + 0.6, g + 3.0, 0.85, wall.darkened(0.2))
					_lbox(cu, f + 0.25, 0.45, 0.3, g + 0.0, g + 0.9, trim, M_STONE, trim)
					_kp_figure(cu, f + 0.25, g + 0.9, 2.5, trim.darkened(0.05))
			kit_face(f)
			for k in 4:
				kit_column(u0 + 0.75 + k * (u1 - u0 - 1.5) / 3.0, f + 0.5, g + 5.0, top, trim, 0.48, Order.CORINTHIAN)
			for k in 3:
				var wu := u0 + 0.75 + (k + 0.5) * (u1 - u0 - 1.5) / 3.0
				kit_window(wu, g + 6.4, 3.4, Win.ARCHED, trim, glass, 0.85)
				_kp_balustrade(wu - 1.2, f + 0.25, wu + 1.2, f + 0.25, g + 5.0, 0.9, trim, 0.6)
				for s: float in [-0.45, 0.45]:
					kit_window(wu + s, g + 12.7, 1.25, Win.PLAIN, trim, glass, 0.32)
			# the attic, the clock and the group
			kit_face(f - 0.3)
			kit_wall(u0 + 0.3, u1 - 0.3, top + 1.7, top + 4.4, wall)
			kit_ledge(u0 + 0.3, u1 - 0.3, top + 4.4, 0.3, trim, 0.12)
			_dial(_w((u0 + u1) * 0.5, f - 0.25), top + 3.0, _b, 0.9)
			var gu := (u0 + u1) * 0.5
			_lbox(gu, f - 1.2, 2.6, 0.9, top + 4.7, top + 5.2, trim, M_STONE, trim)
			_kp_figure(gu, f - 1.2, top + 5.2, 3.0, trim.darkened(0.08))
			for s: float in [-1.0, 1.0]:
				_kp_figure(gu + s * 1.6, f - 1.2, top + 5.2, 2.0, trim.darkened(0.08))
				_lbox(gu + s * 1.0, f - 1.2, 0.5, 0.12, top + 7.3, top + 7.5, trim.darkened(0.08), M_STONE, trim)  # the arms raised
		else:
			kit_pilaster(u0 + 0.5, g + 5.0, top, trim, 0.8, 0.2)
			kit_pilaster(u1 - 0.5, g + 5.0, top, trim, 0.8, 0.2)
			var cu := (u0 + u1) * 0.5
			kit_face(f + 0.05)
			kit_window(cu, g + 1.2, 2.4, Win.SILL, trim, glass, 0.75)
			kit_face(f)
			kit_window(cu, g + 6.4, 3.4, Win.ARCHED, trim, glass, 0.8)
			_kp_balustrade(cu - 1.2, f + 0.25, cu + 1.2, f + 0.25, g + 5.0, 0.9, trim, 0.6)
			for s: float in [-0.45, 0.45]:
				kit_window(cu + s, g + 12.7, 1.25, Win.PLAIN, trim, glass, 0.32)
			kit_attic(u0, u1, top + 1.7, trim, 1.1, Attic.BALUSTRADE)
	# the flanks: giant pilasters with busts between the tall windows (photo 8070)
	for side: Array in [[UW_LIB_N, Vector2(-318.7, -721.8)], [UW_LIB_S, Vector2(-306.4, -698.5)]]:
		var a0: Vector2 = side[0]
		var a1: Vector2 = side[1]
		var length := kit_front(a1, a0) if side[0] == UW_LIB_N else kit_front(a0, a1)
		kit_face(0.1)
		var n := int(length / 4.6)
		for k in n + 1:
			var pu := 0.6 + k * (length - 1.2) / maxf(n, 1)
			kit_pilaster(pu, g + 4.6, top + 1.3, trim, 0.8, 0.22)
		for k in n:
			var wu := 0.6 + (k + 0.5) * (length - 1.2) / maxf(n, 1)
			kit_window(wu, g + 1.2, 2.4, Win.SILL, trim, glass, 0.7)
			kit_window(wu, g + 6.0, 4.0, Win.ARCHED, trim, glass, 0.8)
			var bc := _w(wu, _face + 0.3)
			_lbox(wu, _face + 0.2, 0.32, 0.22, g + 11.0, g + 11.35, trim, M_STONE, trim)  # the bust's console
			_prism(_circle(bc, 0.26, 6), g + 11.35, g + 11.8, trim.darkened(0.06), trim.darkened(0.06), M_STONE, M_STONE)
			_prism(_circle(bc, 0.17, 6), g + 11.8, g + 12.25, trim.darkened(0.06), trim.darkened(0.06), M_STONE, M_STONE)
		kit_ledge(0.0, length, g + 4.6, 0.3, trim, 0.14)
		kit_ledge(0.0, length, top, 1.3, trim, 0.1)
		kit_cornice(0.0, length, top + 1.3, trim, 0.4, 0.8)
	kit_front(UW_LIB_N, UW_LIB_S)
	_collide(_lrect(Rect2(6.1, 0.0, 13.3, 3.1)))


## Pałac Kazimierzowski's garden front (east, over the escarpment), F's photos 8065-8068: the
## middle risalit in the palace's yellow with white trim: tall French windows on the ground floor,
## an iron balcony across the first floor's three round-headed windows, the second floor's square
## ones, the cornice and the curved gable with its sculpture on top, the dormers' red roof beside
## it (LoD2's). In the garden before it the old howitzer on its plinth (8065).
func _build_kazimierzowski_garden() -> void:
	kit_front(UW_KAZ_S, UW_KAZ_N)
	_g = map.terrain_height((UW_KAZ_S.x + UW_KAZ_N.x) * 0.5, (UW_KAZ_S.y + UW_KAZ_N.y) * 0.5)
	var g := _g
	_mode = M_STONE
	var wall := UW_YELLOW
	var trim := KAZIM_WHITE
	var glass := PAL_GLASS_DARK
	var w := UW_KAZ_S.distance_to(UW_KAZ_N)
	kit_face(0.12)
	kit_wall(0.0, w, g - 0.4, g + 13.2, wall)
	kit_pilaster(0.4, g + 0.4, g + 12.6, trim, 0.7, 0.14)
	kit_pilaster(w - 0.4, g + 0.4, g + 12.6, trim, 0.7, 0.14)
	var bays := kit_window_grid(1.4, w - 1.4, 3, [g + 0.35], 3.3, Win.FRAMED, trim, glass, 0.85)
	kit_window_grid(1.4, w - 1.4, 3, [g + 5.3], 2.9, Win.ARCHED, trim, glass, 0.8)
	kit_window_grid(1.4, w - 1.4, 3, [g + 9.6], 1.6, Win.SILL, trim, glass, 0.7)
	kit_ledge(0.0, w, g + 4.6, 0.25, trim)
	kit_balcony((bays[0] + bays[2]) * 0.5, g + 4.85, (bays[2] - bays[0]) * 0.5 + 1.3, Balcony.IRON, PAL_IRON, trim, 1.2)
	kit_ledge(0.0, w, g + 8.9, 0.18, trim)
	kit_cornice(0.0, w, g + 13.2, trim, 0.45, 0.8)
	# the curved gable: a segment of a circle over the risalit, a relief, the sculpture on top
	var seg := 8
	var ring := PackedVector2Array()
	var ys: Array[float] = []
	for k in seg + 1:
		var t := float(k) / seg
		ring.append(Vector2(lerpf(0.6, w - 0.6, t), 0.0))
		ys.append(g + 13.65 + 3.0 * sin(PI * t))
	var n3 := Vector3(_b.x, 0.0, _b.y)
	var mid := _w(w * 0.5, 0.12)
	for k in seg:
		var p0 := _w(ring[k].x, 0.12)
		var p1 := _w(ring[k + 1].x, 0.12)
		# a fan from the base's middle (a quad to the base line has no height at the ends)
		_tri(Vector3(mid.x, g + 13.65, mid.y), Vector3(p0.x, ys[k], p0.y), Vector3(p1.x, ys[k + 1], p1.y), n3, wall,
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
		var q0 := _w(ring[k].x, 0.3)
		var q1 := _w(ring[k + 1].x, 0.3)
		var e0 := _w(ring[k].x, -1.5)
		var e1 := _w(ring[k + 1].x, -1.5)
		# the moulding along the curve, and its top back to the roof
		_quad(Vector3(q0.x, ys[k], q0.y), Vector3(q1.x, ys[k + 1], q1.y), Vector3(q1.x, ys[k + 1] + 0.3, q1.y),
				Vector3(q0.x, ys[k] + 0.3, q0.y), n3, trim)
		_quad(Vector3(q0.x, ys[k] + 0.3, q0.y), Vector3(q1.x, ys[k + 1] + 0.3, q1.y), Vector3(e1.x, ys[k + 1] + 0.3, e1.y),
				Vector3(e0.x, ys[k] + 0.3, e0.y), Vector3.UP, KAZIM_ROOF)
	var rc := _w(w * 0.5, 0.18)
	_disc(Vector3(rc.x, g + 15.0, rc.y), n3, 1.1, 8, trim)
	_lbox(w * 0.5, -0.4, 0.9, 0.6, g + 16.95, g + 17.4, trim, M_STONE, trim)
	_kp_figure(w * 0.5, -0.4, g + 17.4, 1.8, trim.darkened(0.08))
	_kp_figure(w * 0.5 + 0.7, -0.4, g + 17.4, 1.3, trim.darkened(0.08))
	# the howitzer in the garden, wheels and barrel in army green, on a low stone plinth
	var hu := 2.0
	var hv := 9.0
	var olive := Color("#4d5638")
	var hg: float = map.terrain_height(_w(hu, hv).x, _w(hu, hv).y)
	_lbox(hu, hv, 1.8, 1.3, hg - 0.3, hg + 0.25, PAL_GREY_STONE, M_STONE, PAL_GREY_STONE)
	for s: float in [-1.0, 1.0]:
		var wc := _w(hu + s * 0.85, hv)
		_disc(Vector3(wc.x, hg + 0.85, wc.y), Vector3(_a.x, 0.0, _a.y) * s, 0.62, 8, olive.darkened(0.2))
	_lbox(hu, hv + 0.3, 0.6, 0.35, hg + 0.6, hg + 1.15, olive, M_STONE, olive)  # the shield
	var b0 := _w(hu, hv - 0.2)
	var b1 := _w(hu, hv - 2.4)
	var bd := (b1 - b0).normalized()
	var side := Vector2(-bd.y, bd.x) * 0.12
	_prism(PackedVector2Array([b0 - side, b1 - side, b1 + side, b0 + side]), hg + 0.95, hg + 1.25, olive, olive.lightened(0.1), M_STONE, M_STONE)
	_prism(PackedVector2Array([_w(hu - 0.1, hv + 0.4), _w(hu - 0.1, hv + 2.2), _w(hu + 0.1, hv + 2.2), _w(hu + 0.1, hv + 0.4)]),
			hg + 0.15, hg + 0.45, olive.darkened(0.1), olive, M_STONE, M_STONE)  # the trail


## The escarpment wall round the campus's Powiśle side (OSM's wall line): red brick, from the
## lower ground on the slope side up to a parapet a metre over the campus, a concrete coping,
## brick piers every ~6 m, graffiti on the slope face (F's 8066: a big magenta-and-black piece, teal
## tags) and the curved iron railing along the palace's terraces (8067, 8068). The footpath
## under it is the map's. OSM's 2 m grey wall is left out (SITE_WALLS: "").
func _build_uw_skarpa(site: Dictionary) -> void:
	var line: PackedVector2Array = site["line"]
	_mode = M_STONE
	var rng := RandomNumberGenerator.new()
	rng.seed = 1816
	var tags: Array[Color] = [Color("#b8337e"), Color("#4fb9b0"), Color("#e8e4dc"), Color("#2b2a2e"), Color("#7cc6d8"),
			Color("#d9b43c"), Color("#8c3fa3")]
	var run := 0.0
	var next_piece := 6.0
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var length := a.distance_to(b)
		if length < 0.2:
			continue
		var d := (b - a) / length
		var nrm := Vector2(-d.y, d.x)
		# the slope's side is the lower one
		var mid := (a + b) * 0.5
		var h_l: float = map.terrain_height(mid.x + nrm.x * 5.0, mid.y + nrm.y * 5.0)
		var h_r: float = map.terrain_height(mid.x - nrm.x * 5.0, mid.y - nrm.y * 5.0)
		var out := nrm if h_l < h_r else -nrm
		var up_side: float = maxf(h_l, h_r)
		var low: float = minf(h_l, h_r)
		var foot := minf(low, up_side - 0.6) - 0.5
		var top := up_side + 1.0
		var back := -out * 0.35
		var front := out * 0.25
		_prism(PackedVector2Array([a + back, b + back, b + front, a + front]), foot, top, UW_BRICK, UW_BRICK_DARK, M_STONE, M_STONE)
		_prism(PackedVector2Array([a + back * 1.25, b + back * 1.25, b + front * 1.35, a + front * 1.35]), top, top + 0.14,
				UW_CAP, UW_CAP.lightened(0.05), M_STONE, M_STONE)
		# a darker brick course every 1.5 m down the slope face
		var y := top - 1.0
		while y > foot + 0.6 and top - foot > 1.6:
			_wall(a + front * 1.08, b + front * 1.08, y, y + 0.08, out, UW_BRICK_DARK)
			y -= 1.5
		# piers
		var k0 := ceili((run) / 6.0)
		var k1 := floori((run + length) / 6.0)
		for k in range(k0, k1 + 1):
			var t := (k * 6.0 - run) / length
			var p := a.lerp(b, clampf(t, 0.0, 1.0))
			_prism(PackedVector2Array([p - d * 0.3 + back * 1.1, p + d * 0.3 + back * 1.1, p + d * 0.3 + front * 1.6,
					p - d * 0.3 + front * 1.6]), foot, top + 0.25, UW_BRICK_DARK, UW_CAP, M_STONE, M_STONE)
		# graffiti on the slope face where the wall stands tall enough
		while next_piece < run + length:
			var t := (next_piece - run) / length
			var face_h := top - foot
			if face_h > 1.8:
				var c := a.lerp(b, t) + out * 0.3
				var w := rng.randf_range(1.2, 3.2)
				var y0 := foot + 0.7 + rng.randf_range(0.0, 0.4)
				var y1 := minf(y0 + rng.randf_range(0.9, 1.9), top - 0.3)
				var col := tags[rng.randi() % tags.size()]
				var col2 := tags[rng.randi() % tags.size()]
				_wall(c - d * w * 0.5, c + d * w * 0.5, y0, y1, out, col)
				_wall(c - d * w * 0.3 + out * 0.02, c + d * w * 0.35 + out * 0.02, y0 + (y1 - y0) * 0.3, y1 - (y1 - y0) * 0.15,
						out, col2)
				_wall(c - d * w * 0.45 + out * 0.03, c + d * w * 0.2 + out * 0.03, y0 + (y1 - y0) * 0.55, y0 + (y1 - y0) * 0.65,
						out, Color("#2b2a2e"))
			next_piece += rng.randf_range(5.0, 14.0)
		# the iron railing on the palace's stretch (the first 17 points, round the terraces)
		if i < 17:
			var r0 := a + back * 0.6
			var r1 := b + back * 0.6
			_prism(PackedVector2Array([r0 - out * 0.03, r1 - out * 0.03, r1 + out * 0.03, r0 + out * 0.03]), top + 0.98, top + 1.04,
					PAL_IRON, PAL_IRON, M_STONE, M_STONE)
			_prism(PackedVector2Array([r0 - out * 0.03, r1 - out * 0.03, r1 + out * 0.03, r0 + out * 0.03]), top + 0.2, top + 0.24,
					PAL_IRON, PAL_IRON, M_STONE, M_STONE)
			var bars := maxi(int(length / 0.45), 1)
			for k in bars:
				var p := r0.lerp(r1, (k + 0.5) / bars)
				var bar := PackedVector2Array([p - d * 0.02 - out * 0.02, p + d * 0.02 - out * 0.02, p + d * 0.02 + out * 0.02,
						p - d * 0.02 + out * 0.02])
				_prism(bar, top + 0.14, top + 1.0, PAL_IRON, PAL_IRON, M_STONE, M_STONE)
		run += length


## The guards' kiosk (Straż Uniwersytecka; OSM's green kiosk "Ruch"), F's photos 8063 and 8074:
## a low pavilion in dark green panelling on a plinth, wide windows with pale blinds between green
## pilasters, a glazed door with a ramp and rail, a deep cornice, a red sheet-tile hipped roof with
## green vent boxes along its ridge, the guards' name board over the door.
func _build_uw_straz(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	_prism(ring, g - 0.4, g + 0.45, UW_KIOSK_DARK, none, M_STONE)
	_prism(ring, g + 0.45, g + 3.1, UW_KIOSK, none, M_STONE)
	# the windows and pilasters round every edge
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 1.2:
			continue
		var out := _out(ring, a, b)
		var d := (b - a) / length
		var n := maxi(int(length / 1.9), 1)
		for k in n:
			var c := a.lerp(b, (k + 0.5) / n) + out * 0.03
			var hw := minf(length / n * 0.5 - 0.22, 0.85)
			_wall(c - d * hw, c + d * hw, g + 0.95, g + 2.6, out, UW_BLIND)
			_wall(c - d * hw + out * 0.01, c + d * hw + out * 0.01, g + 0.95, g + 1.05, out, UW_KIOSK_DARK)
		for k in n + 1:
			var p := a.lerp(b, float(k) / n) + out * 0.04
			_wall(p - d * 0.12, p + d * 0.12, g + 0.45, g + 3.1, out, UW_KIOSK_DARK)
	# the cornice and the roof
	var eave := _largest(Geometry2D.offset_polygon(ring, 0.35, Geometry2D.JOIN_MITER))
	_prism(eave, g + 3.1, g + 3.45, UW_KIOSK_DARK, UW_KIOSK_DARK, M_STONE, M_STONE)
	var inner := _largest(Geometry2D.offset_polygon(ring, -1.6, Geometry2D.JOIN_MITER))
	if inner.size() >= 3:
		_frustum(_resample(eave, inner.size()), g + 3.45, inner, g + 4.25, UW_TILE, UW_TILE.darkened(0.08))
	else:
		_pyramid(eave, g + 3.45, g + 4.4, UW_TILE)
	var c0 := _centre(ring)
	for k in 3:
		var q := c0 + Vector2.from_angle(0.5 + k * 2.1) * 1.1
		_prism(_square(q, 0.28), g + 4.0, g + 4.55, UW_KIOSK, UW_KIOSK_DARK, M_STONE, M_STONE)
	# the name board on the longest edge (over the door), and the door's glass
	var best := 0
	for i in ring.size():
		if ring[i].distance_to(ring[(i + 1) % ring.size()]) > ring[best].distance_to(ring[(best + 1) % ring.size()]):
			best = i
	var a := ring[best]
	var b := ring[(best + 1) % ring.size()]
	var out := _out(ring, a, b)
	var m := (a + b) * 0.5 + out * 0.42
	var dd := (b - a).normalized()
	_wall(m - dd * 1.4, m + dd * 1.4, g + 3.0, g + 3.42, out, Color("#e9e4d6"))
	_wall(m - dd * 1.2 + out * 0.01, m + dd * 1.2 + out * 0.01, g + 3.14, g + 3.28, out, Color("#3b3f44"))
	var dm := (a + b) * 0.5 + out * 0.06
	_wall(dm - dd * 0.6, dm + dd * 0.6, g + 0.45, g + 2.7, out, PAL_GLASS_DARK)
	_collide(ring)


## A ring with `n` points (the outline's own corners first, then ones between them), so a
## frustum can join two rings of different counts.
func _resample(ring: PackedVector2Array, n: int) -> PackedVector2Array:
	if ring.size() == n:
		return ring
	var total := 0.0
	for i in ring.size():
		total += ring[i].distance_to(ring[(i + 1) % ring.size()])
	var out := PackedVector2Array()
	for k in n:
		var s := total * k / n
		for i in ring.size():
			var seg := ring[i].distance_to(ring[(i + 1) % ring.size()])
			if s <= seg:
				out.append(ring[i].lerp(ring[(i + 1) % ring.size()], s / maxf(seg, 0.001)))
				break
			s -= seg
	return out


## The campus's furniture: the cast-iron bollards with their hanging chains in front of Pałac
## Uruskich (8049), and the flagpoles before the Old Library (8056: Poland's, Warsaw's, the
## University's, the EU's flags).
func _build_uw_kampus(_site: Dictionary) -> void:
	_mode = M_STONE
	var iron := Color("#2e3236")
	# the bollards and chains
	kit_front(UW_URU_N, UW_URU_S)
	var posts: Array[Vector2] = []
	var u := 2.0
	while u < 44.0:
		posts.append(_w(u, 3.2))
		u += 2.9
	for k in posts.size():
		var p := posts[k]
		var gy: float = map.terrain_height(p.x, p.y)
		_prism(_circle(p, 0.15, 6), gy - 0.2, gy + 0.75, iron, iron, M_STONE, M_STONE)
		_frustum(_circle(p, 0.15, 6), gy + 0.75, _circle(p, 0.05, 6), gy + 0.95, iron, iron)
		_prism(_circle(p, 0.2, 6), gy + 0.0, gy + 0.12, iron, iron, M_STONE, M_STONE)
		if k > 0:  # the chain: two sagging links
			var q := posts[k - 1]
			var gq: float = map.terrain_height(q.x, q.y)
			var m := (p + q) * 0.5
			var gm := (gy + gq) * 0.5
			for s: Array in [[q, gq + 0.7, m, gm + 0.45], [m, gm + 0.45, p, gy + 0.7]]:
				var p0: Vector2 = s[0]
				var p1: Vector2 = s[2]
				var dir := (p1 - p0).normalized()
				var side := Vector2(-dir.y, dir.x) * 0.025
				var y0: float = s[1]
				var y1: float = s[3]
				_quad(Vector3(p0.x, y0 + 0.05, p0.y) + Vector3(side.x, 0, side.y), Vector3(p1.x, y1 + 0.05, p1.y) + Vector3(side.x, 0, side.y),
						Vector3(p1.x, y1, p1.y) + Vector3(side.x, 0, side.y), Vector3(p0.x, y0, p0.y) + Vector3(side.x, 0, side.y),
						Vector3(side.x, 0, side.y).normalized(), iron)
				_quad(Vector3(p1.x, y1 + 0.05, p1.y) - Vector3(side.x, 0, side.y), Vector3(p0.x, y0 + 0.05, p0.y) - Vector3(side.x, 0, side.y),
						Vector3(p0.x, y0, p0.y) - Vector3(side.x, 0, side.y), Vector3(p1.x, y1, p1.y) - Vector3(side.x, 0, side.y),
						-Vector3(side.x, 0, side.y).normalized(), iron)
	# the flagpoles on the Old Library's forecourt: two left of the front, three right
	kit_front(UW_LIB_N, UW_LIB_S)
	var flags: Array = [[Color("#f3f1ee"), Color("#d4213d")], [Color("#e9c331"), Color("#c8322e")],
			[Color("#8c2030"), Color("#8c2030")], [Color("#2a4a9a"), Color("#2a4a9a")], [Color("#f3f1ee"), Color("#d4213d")]]
	var spots := [-4.0, -0.5, 25.0, 28.5, 32.0]
	for k in spots.size():
		var p := _w(spots[k], 13.0)
		var gy: float = map.terrain_height(p.x, p.y)
		_prism(_circle(p, 0.2, 6), gy - 0.2, gy + 0.3, PAL_GREY_GRANITE, PAL_GREY_GRANITE, M_STONE, M_STONE)
		_frustum(_circle(p, 0.07, 6), gy + 0.3, _circle(p, 0.045, 6), gy + 11.0, Color("#eceef0"), Color("#eceef0"))
		var f: Array = flags[k]
		var fly := _a * (1.0 if k < 2 else -1.0)
		var n3 := Vector3(_b.x, 0.0, _b.y)
		var p1 := p + fly * 1.9
		_quad(Vector3(p.x, gy + 10.7, p.y), Vector3(p1.x, gy + 10.5, p1.y), Vector3(p1.x, gy + 9.9, p1.y), Vector3(p.x, gy + 10.1, p.y), n3, f[0])
		_quad(Vector3(p1.x, gy + 10.5, p1.y), Vector3(p.x, gy + 10.7, p.y), Vector3(p.x, gy + 10.1, p.y), Vector3(p1.x, gy + 9.9, p1.y), -n3, f[0])
		_quad(Vector3(p.x, gy + 10.1, p.y), Vector3(p1.x, gy + 9.9, p1.y), Vector3(p1.x, gy + 9.3, p1.y), Vector3(p.x, gy + 9.5, p.y), n3, f[1])
		_quad(Vector3(p1.x, gy + 9.9, p1.y), Vector3(p.x, gy + 10.1, p.y), Vector3(p.x, gy + 9.5, p.y), Vector3(p1.x, gy + 9.3, p1.y), -n3, f[1])


## Pałac Czapskich (Krasiński-Czapski palace, the Academy of Fine Arts), photos 18-19: built whole
## (the first pass kept a skin and its front's direction was unknown). It stands 90 m back from
## the street, facing east over its forecourt: three storeys in brick-red plaster with white
## pilasters, quoins and cornice, the corner pavilions stepping forward, a centre risalit under a
## white pediment with a cartouche and a balcony over the door, a red tile hipped roof with a
## row of white chimneys. Frame: origin on the risalit's face, u north along the front, +v east.
func _build_czapski(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_o = CZAP
	_b = CZAP_OUT.normalized()
	_a = Vector2(_b.y, -_b.x)
	_g = _ground_under(ring)
	var g := _g
	var h := 15.0  # the main cornice (LoD2: eaves ~17 m over the yard, ridge ~23 m)
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	_prism(ring, g - 0.5, g + 1.2, CZAP_SHADE, none, M_STONE)
	_prism(ring, g + 1.2, g + h, CZAP_WALL, none, M_MONUMENT)
	var band := _largest(Geometry2D.offset_polygon(ring, 0.15, Geometry2D.JOIN_MITER))
	_prism(band, g + 5.2, g + 5.6, CZAP_WHITE, CZAP_WHITE, M_STONE, M_STONE)
	var eave := _largest(Geometry2D.offset_polygon(ring, 0.45, Geometry2D.JOIN_MITER))
	_prism(eave, g + h, g + h + 0.7, CZAP_WHITE, CZAP_WHITE, M_STONE, M_STONE)
	# white quoins on every outer corner of the outline
	for i in ring.size():
		var p := ring[i]
		var d0 := (p - ring[(i + ring.size() - 1) % ring.size()]).normalized()
		var d1 := (ring[(i + 1) % ring.size()] - p).normalized()
		if absf(d0.cross(d1)) < 0.5:
			continue
		var lp := _local(p)
		_lbox(lp.x, lp.y, 0.45, 0.45, g + 1.2, g + h, CZAP_WHITE, M_STONE, CZAP_WHITE)
	# the front: pilasters between the bays, the risalit with its door, balcony and pediment
	for u: float in [-14.0, -10.0, 10.0, 14.6]:
		_lbox(u, 0.15, 0.35, 0.2, g + 1.2, g + h, CZAP_WHITE, M_STONE, CZAP_WHITE)
	for u: float in [-5.1, -1.8, 1.8, 5.5]:
		_lbox(u, 0.55, 0.35, 0.2, g + 1.2, g + h, CZAP_WHITE, M_STONE, CZAP_WHITE)
	_kp_arch_open(0.2, 0.76, g + 0.0, g + 3.6, 1.1, KP_WOOD)
	_lbox(0.2, 1.2, 1.8, 0.5, g + 5.6, g + 5.8, CZAP_WHITE, M_STONE, CZAP_WHITE)  # the balcony
	_lbox(0.2, 1.68, 1.8, 0.03, g + 5.8, g + 6.8, KP_IRON, M_STONE, KP_IRON)
	var ka := _a
	var kb := _b
	_a = kb
	_b = ka
	_gable(1.0, -1.0, 0.2, 5.8, g + h + 0.7, 2.6, CZAP_WHITE, CZAP_ROOF)
	_a = ka
	_b = kb
	var cart := _w(0.2, 1.02)
	_disc(Vector3(cart.x, g + h + 1.6, cart.y), Vector3(_b.x, 0.0, _b.y), 0.6, 8, CZAP_WHITE.darkened(0.12))
	_kp_figure(0.2, 0.6, g + h + 3.3, 1.6, CZAP_WHITE)
	# the roofs: the main body and the two corner wings, red tile hips; the chimney row
	var y := g + h + 0.7
	_hip(0.3, -10.0, 14.6, 9.4, y, 6.0, CZAP_ROOF)
	_hip(-19.7, -11.6, 5.5, 16.4, y, 5.0, CZAP_ROOF)
	_hip(20.4, -11.4, 5.4, 16.4, y, 5.0, CZAP_ROOF)
	for u: float in [-10.0, -4.0, 4.0, 10.0]:
		_lbox(u, -10.0, 0.5, 0.8, y + 2.0, y + 7.4, CZAP_WHITE, M_STONE, CZAP_WHITE.darkened(0.2))
	_collide(ring)


## The whole palace follows the mapped U, with the gallery as a separate site in its open end.
func _build_potocki(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["zone"][0]
	var axis := POTOCKI_AXIS.normalized()
	kit_front(POTOCKI, POTOCKI + axis)
	var ground := _w(24.0, 26.0)
	_g = map.terrain_height(ground.x, ground.y)
	_mode = M_STONE
	var palace := _lpoly(POTOCKI_PLAN)
	var ridge := _lpoly(POTOCKI_RIDGE)
	var ends: Array[PackedVector2Array] = []
	for points: Array in POTOCKI_ENDS:
		ends.append(_lpoly(points))
	_potocki_palace(palace, ridge)
	_potocki_wing_ends(ends)
	kit_front(POTOCKI, POTOCKI + axis)
	_potocki_court()
	_potocki_gates()
	_collide(outline)


## The principal ranges have three window levels, with deeper trim and rustication in the court.
func _potocki_palace(ring: PackedVector2Array, ridge: PackedVector2Array) -> void:
	var eave := _g + POTOCKI_EAVE
	var none := Color.TRANSPARENT
	_prism(ring, _g - 1.55, eave, POTOCKI_WALL, none, M_STONE)
	kit_ledge_ring(ring, _g - 1.54, 2.10, POTOCKI_PLINTH, 0.11)
	kit_ledge_ring(ring, _g + 5.60, 0.16, POTOCKI_TRIM, 0.14)
	kit_cornice_ring(ring, eave - 0.30, POTOCKI_TRIM, 0.30, 0.31)
	for i in ring.size():
		# The short returns hold each break in the plan. The end walls are mostly behind the pavilions.
		if i in [4, 14]:
			continue
		var width := _potocki_front(ring, i)
		if width < 5.3:
			continue
		var is_court := i >= 5 and i <= 13
		var bays := maxi(1, roundi(width / 3.85))
		if i == 8:
			bays = 11
		kit_face(0.0)
		var band_step := 0.80 if is_court else 1.48
		kit_bands(0.24, width - 0.24, _g + 0.63, _g + 4.60, band_step, POTOCKI_WALL)
		var centres: Array[float] = []
		for j in bays:
			if i == 8 and j >= 4 and j <= 6:
				continue
			centres.append(width * (float(j) + 0.5) / float(bays))
		kit_panes(centres, [_g + 1.37], 1.16, 2.35, PAL_GLASS_DARK, 0.079)
		kit_panes(centres, [_g + 9.74], 1.04, 1.65, PAL_GLASS_DARK)
		if i == 8:
			for u: float in centres:
				kit_window(u, _g + 6.08, 2.20, Win.SILL_HEAD, POTOCKI_TRIM, PAL_GLASS_DARK, 0.63)
		else:
			kit_panes(centres, [_g + 6.08], 1.26, 2.20, PAL_GLASS_DARK)
		if i == 8:
			for u: float in [0.49, width - 0.49]:
				kit_pilaster(u, _g + 5.78, eave - 0.34, POTOCKI_TRIM, 0.58, 0.15)
			_potocki_pavilion(width)
	_potocki_mansard(ring, ridge, POTOCKI_RIDGE_Y, eave, _g + POTOCKI_CURB, [4, 14])
	var axis := POTOCKI_AXIS.normalized()
	kit_front(POTOCKI, POTOCKI + axis)
	for u: float in [5.7, 23.5, 39.6, 52.5]:
		_lbox(u, -11.73, 0.48, 0.36, _g + 18.15, _g + 19.52, POTOCKI_WALL)


## The three central bays project over the steps, with a low pediment and stone-framed oculus.
func _potocki_pavilion(width: float) -> void:
	var mid := width * 0.5
	var eave := _g + POTOCKI_EAVE
	var front := 1.16
	_prism(_urect(mid - 5.05, mid + 5.05, -0.32, front), _g - 0.68, eave,
			POTOCKI_WALL, Color.TRANSPARENT, M_STONE)
	kit_face(front)
	kit_ledge(mid - 5.02, mid + 5.02, _g + 0.43, 0.28, POTOCKI_PLINTH, 0.10)
	kit_ledge(mid - 5.02, mid + 5.02, _g + 5.60, 0.19, POTOCKI_TRIM, 0.28)
	kit_ledge(mid - 5.02, mid + 5.02, _g + 4.73, 0.12, POTOCKI_TRIM, 0.10)
	kit_cornice(mid - 4.79, mid + 4.79, eave - 0.34, POTOCKI_TRIM, 0.34, 0.36)
	for u: float in [-4.65, -1.62, 1.62, 4.65]:
		kit_pilaster(mid + u, _g + 5.82, eave - 0.35, POTOCKI_TRIM, 0.64, 0.22)
	for u: float in [-3.16, 0.0, 3.16]:
		kit_window(mid + u, _g + 6.33, 2.15, Win.HOODED, POTOCKI_TRIM, PAL_GLASS_DARK, 0.65, POTOCKI_TRIM)
		kit_window(mid + u, _g + 9.64, 1.75, Win.SILL, POTOCKI_TRIM, PAL_GLASS_DARK, 0.55, POTOCKI_TRIM)
		if u != 0.0:
			kit_round_window(_w(mid + u, front), _a, _b, _g + 1.33, _g + 3.16, 0.65, POTOCKI_TRIM)
	kit_door(mid, _g + 0.45, 3.80, 0.94, POTOCKI_TRIM, KP_WOOD, true)
	_ubox(mid - 2.53, mid + 2.53, 0.99, 2.81, _g - 0.66, _g + 0.22, POTOCKI_PLINTH)
	_ubox(mid - 2.31, mid + 2.31, 1.02, 2.18, _g + 0.19, _g + 0.49, POTOCKI_PLINTH)
	_collide(_urect(mid - 2.53, mid + 2.53, 0.99, 2.81))
	kit_face(-0.65)
	kit_pediment(mid, 5.21, eave, 1.20, POTOCKI_TRIM, POTOCKI_ROOF, 2.06, POTOCKI_WALL.darkened(0.09))
	var eye := _w(mid, 1.49)
	var out := Vector3(_b.x, 0.0, _b.y)
	_disc(Vector3(eye.x, eave + 0.49, eye.y), out, 0.34, 10, POTOCKI_TRIM)
	_mode = M_GLASS
	eye = _w(mid, 1.54)
	_disc(Vector3(eye.x, eave + 0.49, eye.y), out, 0.24, 10, PAL_GLASS_DARK)
	_mode = M_STONE


## Face out of the solid for either winding of the plan ring.
func _potocki_front(ring: PackedVector2Array, edge: int) -> float:
	var from := ring[edge]
	var to := ring[(edge + 1) % ring.size()]
	var along := to - from
	if Vector2(-along.y, along.x).dot(_out(ring, from, to)) < 0.0:
		return kit_front(to, from)
	return kit_front(from, to)


## The two lower street pavilions have their own hips, three bays, and dressed corner edges.
func _potocki_wing_ends(ends: Array[PackedVector2Array]) -> void:
	var eave := _g + 8.58
	for ring: PackedVector2Array in ends:
		_prism(ring, _g - 1.49, eave, POTOCKI_TRIM, Color.TRANSPARENT, M_STONE)
		kit_ledge_ring(ring, _g - 1.48, 2.10, POTOCKI_PLINTH, 0.14)
		kit_ledge_ring(ring, _g + 4.60, 0.16, POTOCKI_TRIM, 0.17)
		kit_cornice_ring(ring, eave - 0.35, POTOCKI_TRIM, 0.35, 0.35)
		for edge in [1, 2, 3]:
			var width := _potocki_front(ring, edge)
			var bays := 3 if edge == 2 else 2
			for k in bays:
				var u := width * (float(k) + 0.5) / float(bays)
				kit_round_window(_w(u, 0.0), _a, _b, _g + 1.04, _g + 3.15, 0.60, POTOCKI_TRIM)
				if edge == 2:
					kit_window(u, _g + 5.49, 2.10, Win.SILL_HEAD, POTOCKI_TRIM,
							PAL_GLASS_DARK, 0.63, POTOCKI_TRIM)
				else:
					kit_panes([u], [_g + 5.49], 1.26, 2.10, PAL_GLASS_DARK)
			if edge != 2:
				continue
			for k in 7:
				var y := _g + 0.64 + 0.99 * float(k) + (0.15 if k > 4 else 0.0)
				var quoin := 0.59 if k % 2 == 0 else 0.43
				_wall(_w(0.09, 0.055), _w(quoin, 0.0), y, y + 0.67, _b, POTOCKI_WALL)
				_wall(_w(width - quoin, 0.0), _w(width - 0.09, 0.055), y, y + 0.67, _b, POTOCKI_WALL)
		var ridge := _inset_ring(ring, 4.20)
		_potocki_mansard(ring, ridge, [13.17, 13.17, 13.17, 13.17], eave, _g + 11.24, [0, 1, 3], true)


## A steep lower skirt and shallow upper hips share the curb, keeping the U open to the sky.
func _potocki_mansard(ring: PackedVector2Array, ridge: PackedVector2Array, ridge_y: Array, eave: float,
		curb: float, skip: Array, single := false) -> void:
	var saved_flood := _flood
	_flood = false
	var eaves := _ring_out(ring, 0.25)
	var inset := (curb - eave) / tan(deg_to_rad(70.0))
	var bend := _inset_ring(eaves, inset)
	_slope(ring, eaves, eave, bend, curb, POTOCKI_ROOF)
	var top := PackedVector3Array()
	for i in ridge.size():
		top.append(Vector3(ridge[i].x, _g + float(ridge_y[i]), ridge[i].y))
	var tile := POTOCKI_ROOF.lightened(0.07)
	for i in bend.size():
		var j := (i + 1) % bend.size()
		_potocki_roof_patch(PackedVector3Array([Vector3(bend[i].x, curb, bend[i].y),
				Vector3(bend[j].x, curb, bend[j].y), top[j], top[i]]), tile)
	_potocki_roof_patch(top, POTOCKI_ROOF)
	_flood = saved_flood
	_potocki_dormers(eaves, eave, skip, single)


## The upper hips fan out at the short returns, so triangulate in plan and light each face.
func _potocki_roof_patch(points: PackedVector3Array, tile: Color) -> void:
	var plan := PackedVector2Array()
	for p in points:
		plan.append(Vector2(p.x, p.z))
	var indices := Geometry2D.triangulate_polygon(plan)
	for k in range(0, indices.size(), 3):
		var a := points[indices[k]]
		var b := points[indices[k + 1]]
		var c := points[indices[k + 2]]
		var n := (b - a).cross(c - a).normalized()
		_tri(a, b, c, n if n.y > 0.0 else -n, tile, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## Small gabled dormers sit in the skirt, centered on each roof face at the specified pitch.
func _potocki_dormers(eaves: PackedVector2Array, eave: float, skip: Array, single: bool) -> void:
	for i in eaves.size():
		if i in skip:
			continue
		var length := _potocki_front(eaves, i)
		if length < 5.25:
			continue
		var count := 1 if single else 1 + floori((length - 3.70) / 3.80)
		for j in count:
			var u := length * 0.5 + (float(j) - float(count - 1) * 0.5) * 3.80
			var v := -0.19
			var box := _urect(u - 0.65, u + 0.65, v - 1.80, v)
			for edge in box.size():
				var from := box[edge]
				var to := box[(edge + 1) % box.size()]
				var out := _out(box, from, to)
				if out.dot(_b) >= -0.5:
					_wall(from, to, eave - 0.12, eave + 1.88, out, POTOCKI_WALL)
			kit_face(v)
			kit_window(u, eave + 0.68, 0.98, Win.PLAIN, POTOCKI_TRIM, PAL_GLASS_DARK, 0.34)
			kit_face(v - 1.48)
			kit_pediment(u, 0.72, eave + 1.88, 0.30, POTOCKI_TRIM, POTOCKI_ROOF, 1.53)


## The paved axis and clipped hedges sit over the mapped court grading and grass.
func _potocki_court() -> void:
	var lawn_centres: Array[Vector2] = [Vector2(24.0, 25.0), Vector2(24.0, 40.0)]
	var mapped := 0
	for area: Dictionary in data["areas"]:
		if area["k"] != "grass":
			continue
		var grass := _pts(area["p"])
		for centre in lawn_centres:
			if Geometry2D.is_point_in_polygon(_w(centre.x, centre.y), grass):
				mapped += 1
	if mapped < 2:
		for u: float in [16.0, 32.0]:
			_potocki_grade(_rect(u, 33.1, 7.0, 11.0), 0.05, POTOCKI_TURF)
	# The path continues past both lawn plots to the centre of the gallery and the palace steps.
	var stations := PackedFloat32Array([0.42, 8.0, 16.0, 24.0, 32.0, 40.0, 48.0, 54.50])
	for k in stations.size() - 1:
		var v := stations[k]
		var far := stations[k + 1]
		var from := _potocki_path_axis(v)
		var to := _potocki_path_axis(far)
		_potocki_grade(_lpoly([[from - 0.80, v], [from + 0.80, v], [to + 0.80, far], [to - 0.80, far]]),
				0.065, POTOCKI_PAVING)
	var edges: Array = [[11.57, 35.93, 19.50, 31.00], [11.64, 36.22, 33.24, 47.34]]
	if mapped < 2:
		edges = [[9.24, 22.71, 22.34, 43.86], [25.29, 38.76, 22.34, 43.86]]
	for bounds: Array in edges:
		var lo: float = bounds[0]
		var hi: float = bounds[1]
		var back: float = bounds[2]
		var front: float = bounds[3]
		for u: float in [lo, hi]:
			_potocki_hedge(u - 0.24, u + 0.24, back, front)
		for v: float in [back, front]:
			var path_u := _potocki_path_axis(v)
			var left := clampf(path_u - 1.10, lo + 0.24, hi - 0.24)
			var right := clampf(path_u + 1.10, lo + 0.24, hi - 0.24)
			_potocki_hedge(lo + 0.24, left, v - 0.24, v + 0.24)
			_potocki_hedge(right, hi - 0.24, v - 0.24, v + 0.24)


## The path joins the pavilion steps to the centre of the gallery's rear wall.
func _potocki_path_axis(v: float) -> float:
	return lerpf(29.0, 24.2, (v - 0.42) / 54.08)


## Sample the terrain at the path and lawn corners to keep the low surfaces visible on the grade.
func _potocki_grade(ring: PackedVector2Array, rise: float, col: Color) -> void:
	var points: Array[Vector3] = []
	for p in ring:
		points.append(Vector3(p.x, map.terrain_height(p.x, p.y) + rise, p.y))
	_quad(points[0], points[1], points[2], points[3], Vector3.UP, col)


## A planted edge follows the grade with a narrow, bevelled top to read as a clipped hedge.
func _potocki_hedge(u0: float, u1: float, v0: float, v1: float) -> void:
	if u1 - u0 < 0.15 or v1 - v0 < 0.15:
		return
	var ring := _urect(u0, u1, v0, v1)
	var top := _inset_ring(ring, 0.045)
	var lower: Array[Vector3] = []
	var upper: Array[Vector3] = []
	for i in ring.size():
		var g: float = map.terrain_height(ring[i].x, ring[i].y)
		lower.append(Vector3(ring[i].x, g - 0.13, ring[i].y))
		upper.append(Vector3(top[i].x, g + 0.49, top[i].y))
	for i in ring.size():
		var j := (i + 1) % ring.size()
		var out := _out(ring, ring[i], ring[j])
		_quad(lower[i], lower[j], upper[j], upper[i], Vector3(out.x, 0.0, out.y), POTOCKI_HEDGE)
	_quad(upper[0], upper[1], upper[2], upper[3], Vector3.UP, POTOCKI_HEDGE.lightened(0.12))


## Each gate has a pedestrian portal against the wing, and ironwork between the two piers.
func _potocki_gates() -> void:
	for side in POTOCKI_GATES.size():
		var pair: Array = POTOCKI_GATES[side]
		var length := kit_front(pair[1], pair[0])
		var centre := _w(length * 0.5, 0.0)
		var ground: float = map.terrain_height(centre.x, centre.y)
		var outer := length - 2.62 if side == 0 else 2.62
		var inner := 0.48 if side == 0 else length - 0.48
		var door_lo := outer + 0.47 if side == 0 else -0.76
		var door_hi := length + 0.32 if side == 0 else outer - 0.47
		var wall := _urect(door_lo, door_hi, -0.60, 0.30)
		_prism(wall, ground - 0.70, ground + 3.09, POTOCKI_WALL, POTOCKI_TRIM, M_STONE)
		kit_face(0.30)
		kit_cornice(door_lo + 0.49, door_hi - 0.49, ground + 2.99, POTOCKI_TRIM, 0.14, 0.13)
		kit_door((door_lo + door_hi) * 0.5, ground + 0.09, 2.58, 0.58, POTOCKI_TRIM, KP_WOOD, true)
		_potocki_piers(outer, ground)
		_potocki_piers(inner, ground)
		_potocki_groups(outer, signf(inner - outer), ground)
		_potocki_groups(inner, signf(outer - inner), ground)
		_potocki_lanterns(inner, ground)
		_potocki_ironwork(minf(inner, outer) + 0.55, maxf(inner, outer) - 0.55, ground)
		_collide(_urect(-0.11, length + 0.12, -0.44, 0.44))


## Rusticated piers carry a projecting entablature and the stone sculpture plinth.
func _potocki_piers(u: float, ground: float) -> void:
	var ring := _rect(u, 0.0, 0.60, 0.60)
	_prism(ring, ground - 0.72, ground + 4.20, POTOCKI_WALL, Color.TRANSPARENT, M_STONE)
	kit_ledge_ring(ring, ground - 0.70, 1.10, POTOCKI_PLINTH, 0.07)
	var origin := _o
	var along := _a
	for edge in ring.size():
		var from := ring[edge]
		var to := ring[(edge + 1) % ring.size()]
		if absf((to - from).normalized().dot(along)) < 0.9:
			continue
		_potocki_front(ring, edge)
		kit_face(0.013)
		kit_bands(0.04, 1.16, ground + 0.15, ground + 3.79, 0.86, POTOCKI_WALL)
	kit_front(origin, origin + along)
	kit_cornice_ring(ring, ground + 3.89, POTOCKI_TRIM, 0.31, 0.21)
	_lbox(u, 0.0, 0.64, 0.57, ground + 4.16, ground + 4.60, POTOCKI_SCULPT)


## A seated figure and putto share each cap. The bent knee and raised arm break the silhouette.
func _potocki_groups(u: float, side: float, ground: float) -> void:
	var col := POTOCKI_SCULPT
	var at := _w(u - side * 0.16, -0.02)
	_mode = M_STONE
	_frustum(_rect(u - side * 0.14, 0.06, 0.37, 0.35), ground + 4.57,
			_rect(u - side * 0.17, -0.04, 0.25, 0.23), ground + 5.23, col)
	_frustum(_circle(at, 0.25, 6), ground + 5.12, _circle(at - _b * 0.05, 0.18, 6), ground + 5.91, col, col)
	_prism(_circle(at - _b * 0.05, 0.14, 6), ground + 5.86, ground + 6.20, col, col, M_STONE)
	_lbox(u - side * 0.02, 0.25, 0.22, 0.20, ground + 4.70, ground + 5.12, col)
	_kp_figure(u + side * 0.37, 0.16, ground + 4.59, 1.04, col.lightened(0.04))
	_beam(_potocki_point(u + side * 0.01, 0.02, ground + 5.65), _potocki_point(u + side * 0.34, 0.18, ground + 5.43),
			0.16, col)


## Glazed street lanterns project from a gilt bracket on the gallery-side piers.
func _potocki_lanterns(u: float, ground: float) -> void:
	var base := _w(u, 0.92)
	_beam(_potocki_point(u, 0.57, ground + 2.67), _potocki_point(u, 0.93, ground + 2.89), 0.13, PAL_GOLD, true, M_GOLD)
	_mode = M_GOLD
	_frustum(_circle(base, 0.13, 6), ground + 2.85, _circle(base, 0.22, 6), ground + 3.01, PAL_GOLD)
	_prism(_circle(base, 0.22, 6), ground + 3.01, ground + 3.58, POTOCKI_LAMP, Color.TRANSPARENT, M_LAMP)
	_pyramid(_circle(base, 0.28, 6), ground + 3.58, ground + 3.82, PAL_GOLD)
	_mode = M_STONE


## The iron bars rise to the arched crest, with small gilt curls around a central cartouche.
func _potocki_ironwork(lo: float, hi: float, ground: float) -> void:
	var mid := (lo + hi) * 0.5
	_lbox(mid, 0.0, (hi - lo) * 0.5, 0.075, ground - 0.09, ground + 0.09, POTOCKI_IRON)
	_lbox(mid, 0.0, (hi - lo) * 0.5, 0.075, ground + 3.32, ground + 3.46, POTOCKI_IRON)
	for k in 13:
		var t := float(k) / 12.0
		var u := lerpf(lo, hi, t)
		var y := ground + 0.07
		var bar_top := ground + 3.60 + 0.94 * sin(PI * t)
		_two_sided(_potocki_point(u - 0.047, 0.0, y), _potocki_point(u + 0.047, 0.0, y),
				_potocki_point(u + 0.047, 0.0, bar_top), _potocki_point(u - 0.047, 0.0, bar_top), POTOCKI_IRON)
	for k in 8:
		var t0 := float(k) / 8.0
		var t1 := float(k + 1) / 8.0
		_beam(_potocki_point(lerpf(lo, hi, t0), 0.0, ground + 3.59 + 0.96 * sin(PI * t0)),
				_potocki_point(lerpf(lo, hi, t1), 0.0, ground + 3.59 + 0.96 * sin(PI * t1)), 0.11, POTOCKI_IRON)
	_beam(_potocki_point(mid, -0.014, ground + 3.68), _potocki_point(mid, 0.047, ground + 3.68), 0.08, POTOCKI_IRON)
	for flip: float in [-1.0, 1.0]:
		var from := _potocki_point(mid, 0.043, ground + 3.68)
		for k in 9:
			var t := float(k) / 8.0
			var angle := TAU * t
			var radius := 1.0 - 0.78 * t
			var to := _potocki_point(mid + flip * (1.32 - radius * cos(angle) * 0.93), 0.043,
					ground + 3.83 + sin(angle) * radius * 0.57)
			var offset := Vector3(_b.x, 0.0, _b.y).cross(to - from).normalized() * 0.033
			_mode = M_GOLD
			_two_sided(from - offset, to - offset, to + offset, from + offset, PAL_GOLD)
			from = to
	var centre := _potocki_point(mid, 0.08, ground + 4.13)
	var out := Vector3(_b.x, 0.0, _b.y)
	_beam(centre - out * 0.09, centre, 0.18, POTOCKI_IRON)
	_mode = M_GOLD
	_disc(centre, out, 0.36, 10, PAL_GOLD)
	_mode = M_STONE
	_disc(centre + out * 0.047, out, 0.245, 10, POTOCKI_IRON)


## A point in the gate frame at an absolute height.
func _potocki_point(u: float, v: float, y: float) -> Vector3:
	var p := _w(u, v)
	return Vector3(p.x, y, p.y)


## Kordegarda, the palace guardhouse and gallery, keeps its C-shaped plan and flat attic.
func _build_kordegarda(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["ring"]
	var ring := _simplify(outline, 0.32)
	_g = _ground_under(ring)
	_mode = M_STONE
	_kordegarda_walls(ring)
	var width := kit_front(KORDEGARDA, KORDEGARDA_NORTH)
	kit_face(0.0)
	_kordegarda_openings(width)
	_kordegarda_supports(width)
	_kordegarda_balustrade(width)
	_kordegarda_sculpture_groups(width)
	_collide(outline)


## The white plinth and cornice trace the C; the flat roof stops at the attic base.
func _kordegarda_walls(ring: PackedVector2Array) -> void:
	_prism(ring, _g - 0.62, _g + 6.60, KORD_WHITE, Color.TRANSPARENT, M_STONE)
	kit_ledge_ring(ring, _g - 0.61, 1.41, KORD_WHITE.darkened(0.12), 0.10)
	kit_cornice_ring(ring, _g + 6.22, KORD_WHITE, 0.38, 0.35)
	_cap(ring, _g + 6.60, KORD_ROOF)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var width := a.distance_to(b)
		if width < 5.40 or width > 13.50:
			continue
		var edge := b - a
		var out := _out(ring, a, b)
		if Vector2(-edge.y, edge.x).dot(out) > 0.0:
			kit_front(a, b)
		else:
			kit_front(b, a)
		kit_face(-0.06)
		kit_attic(0.22, width - 0.22, _g + 6.57, KORD_WHITE, 0.63, Attic.WALL)
		kit_face(0.0)
		if out.x < -0.85:
			kit_door(width * 0.50, _g + 0.11, 3.20, 0.68, KORD_WHITE.lightened(0.06), KORD_DOOR, true)
		else:
			for t: float in [0.31, 0.69]:
				kit_round_window(_w(width * t, 0.0), _a, _b, _g + 1.28, _g + 3.93, 0.54, KORD_WHITE, KORD_GLASS)


## The kit supplies the round surrounds. An aligned warm pane lights each of the gallery arches.
func _kordegarda_openings(width: float) -> void:
	var step := width / 7.0
	for k in 7:
		var u := step * (float(k) + 0.5)
		if k == 3:
			kit_door(u, _g + 0.10, 4.00, 0.80, KORD_WHITE.lightened(0.06), KORD_DOOR, true)
		else:
			var at := _w(u, 0.0)
			kit_round_window(at, _a, _b, _g + 1.20, _g + 4.20, 0.65, KORD_WHITE.lightened(0.08), KORD_GLASS)
			_arch_panel(at, _a, _b, 0.65, _g + 1.20, _g + 4.20, KORD_GLASS, 0.124, M_PAVILION)
	var mid := width * 0.5
	kit_ledge(mid - 0.98, mid + 0.98, _g + 4.96, 0.44, KORD_WHITE, 0.16)
	_mode = M_LAMP
	_wall(_w(mid - 0.86, 0.194), _w(mid + 0.86, 0.194), _g + 5.01, _g + 5.35, _b, KORD_WHITE)
	_mode = M_STONE


## Eight shallow pilasters set the rhythm of the gallery bays.
func _kordegarda_supports(width: float) -> void:
	for k in 8:
		var u := clampf(width * float(k) / 7.0, 0.20, width - 0.20)
		kit_pilaster(u, _g + 0.80, _g + 6.00, KORD_WHITE.lightened(0.035), 0.44, 0.16)


## The open stone attic has a rail and plinth from the kit, with dies at the tighter gallery spacing.
func _kordegarda_balustrade(width: float) -> void:
	kit_face(0.03)
	var base := _g + 6.60
	kit_ledge(0.08, width - 0.08, base - 0.04, 0.22, KORD_WHITE, 0.26)
	kit_ledge(0.08, width - 0.08, base + 0.73, 0.17, KORD_WHITE, 0.24)
	for k in 11:
		var u := lerpf(0.27, width - 0.27, float(k) / 10.0)
		_prism(_rect(u, 0.12, 0.13, 0.10), base + 0.15, base + 0.77,
				KORD_WHITE, Color.TRANSPARENT, M_STONE)
		if k < 10:
			var gap := (width - 0.54) / 10.0
			for fraction: float in [0.33, 0.67]:
				_frustum(_rect(u + gap * fraction, 0.12, 0.075, 0.077), base + 0.18,
						_rect(u + gap * fraction, 0.12, 0.045, 0.053), base + 0.74, KORD_WHITE)


## Three figures crown the entrance. Standing figures and urns mark the two street corners.
func _kordegarda_sculpture_groups(width: float) -> void:
	var y := _g + 6.60
	var mid := width * 0.5
	_lbox(mid, 0.05, 1.34, 0.42, y - 0.07, y + 0.71, KORD_WHITE)
	_lbox(mid, 0.04, 0.69, 0.36, y + 0.68, y + 1.07, KORD_SCULPT)
	_kordegarda_figure(mid, 0.09, y + 1.05, 1.65, 0.0)
	for side: float in [-1.0, 1.0]:
		_kordegarda_figure(mid + side * 0.79, 0.08, y + 0.69, 1.38, side)
		var u := mid + side * (mid - 0.76)
		_lbox(u, -0.05, 0.68, 0.55, y - 0.07, y + 0.72, KORD_WHITE)
		_kordegarda_figure(u + side * 0.12, 0.06, y + 0.70, 1.52, -side)
		var urn := _w(u - side * 0.43, 0.01)
		_frustum(_circle(urn, 0.13, 6), y + 0.68, _circle(urn, 0.23, 6), y + 1.02, KORD_SCULPT)
		_frustum(_circle(urn, 0.23, 6), y + 1.02, _circle(urn, 0.11, 6), y + 1.26, KORD_SCULPT, KORD_SCULPT)


## Broad shoulders, drapery and an arm make the attic figures readable from the street.
func _kordegarda_figure(u: float, v: float, y: float, h: float, lean: float) -> void:
	var hip := u - lean * 0.08
	var shoulder := u + lean * 0.17
	_frustum(_rect(hip, v, h * 0.21, h * 0.135), y,
			_rect(hip, v - 0.04, h * 0.12, h * 0.10), y + h * 0.46, KORD_SCULPT)
	_frustum(_rect(hip, v - 0.04, h * 0.12, h * 0.10), y + h * 0.46,
			_rect(shoulder, v - 0.06, h * 0.19, h * 0.105), y + h * 0.79, KORD_SCULPT, KORD_SCULPT)
	var head := _w(shoulder, v + 0.01)
	_frustum(_circle(head, h * 0.083, 6), y + h * 0.76,
			_circle(head, h * 0.067, 6), y + h, KORD_SCULPT, KORD_SCULPT)
	for side: float in [-1.0, 1.0]:
		var a := _w(shoulder + side * h * 0.155, v + 0.015)
		var b := _w(hip + side * h * 0.22, v + h * 0.12)
		_beam(Vector3(a.x, y + h * 0.73, a.y), Vector3(b.x, y + h * 0.40, b.y),
				h * 0.118, KORD_SCULPT)


## Hotel Bristol (1901), spec v2, 2026-11-27. Models the entire block around its open court,
## with pilastered street fronts, a zinc mansard and the corner drum's floodlit belvedere.
## Each street frame follows its mapped edge, with u along the wall and positive v out over the street.
func _build_bristol(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["zone"][0]
	var ring := _simplify(outline, 1.3)
	# Split the stepped service wing across the garden wall, retaining the mapped envelope.
	var karowa := ring.find(BRISTOL_KAROWA_END)
	var corner_at := ring.find(Vector2(-559.9, -890.5))
	if karowa < 0 or corner_at < 0:
		# A map re-bake moved the vertices the split and the drum hang on: say so, do not slice blind.
		push_error("bristol: outline vertex not found after _simplify (karowa %d, corner %d); the hotel is not built" % [karowa, corner_at])
		return
	var garden := ring[-1].lerp(ring[0], 0.8)
	var annex := ring.slice(0, karowa + 1)
	annex.insert(0, garden)
	ring = ring.slice(karowa)
	ring.append(garden)
	# Keep the two extra faces on the mapped corner's curve, under the drum.
	var corner := ring.find(Vector2(-559.9, -890.5))
	if corner < 0:
		push_error("bristol: the drum's corner vertex is not on the street ring; the hotel is not built")
		return
	ring.insert(corner, Vector2(-557.3, -889.7))
	ring.insert(corner + 2, BRISTOL_KRAK_SOUTH)
	_g = _ground_under(outline)
	_mode = M_STONE
	var courts: Array[PackedVector2Array] = []
	var along := Vector2(0.87, -0.49).normalized()
	for mapped in _holes:
		var court := _simplify(mapped, 0.85)
		var c := _centre(court)
		for i in court.size():
			court[i] += along * (court[i] - c).dot(along) * 0.26
		courts.append(court)
	_holes = []  # Bristol walls its own open court to the new mansard roof.
	_bristol_mass(ring, courts)
	_bristol_mansard(ring, courts)
	_bristol_annex(annex)
	_bristol_front(BRISTOL_KRAK_NORTH, BRISTOL_KRAK_SOUTH, true)
	_bristol_front(Vector2(-553.6, -891.0), BRISTOL_KAROWA_END, false)
	_bristol_drum(ring)
	_bristol_belvedere()
	_collide(outline)


## The exterior shell, with untrimmed garden windows and a continuous cornice. The court's
## cream walls use the monument material's window grid and stop flush with the roof opening.
func _bristol_mass(ring: PackedVector2Array, courts: Array[PackedVector2Array]) -> void:
	var y0 := _g + BRISTOL_MEZZ
	var y1 := _g + BRISTOL_CORNICE
	# Sample the plaster between the monument shader's window strips. The kit places the actual bays.
	var foot_uv := Vector2(2.48, BRISTOL_MEZZ)
	var eave_uv := Vector2(2.48, BRISTOL_CORNICE)
	var street_run := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var out := _out(ring, a, b)
		_mode = M_STONE
		# The last two edges face the garden and overlook the lower annex, respectively.
		if i == ring.size() - 2:
			_wall(a, b, _g - 0.6, y1, out, BRISTOL_WALL)
			var length := kit_front(b, a)
			var rows: Array[float] = [_g + 1.92]
			for storey in 4:
				rows.append(_g + BRISTOL_SILL + 3.6 * storey)
			kit_panes(_spread(0.0, length, 10), rows, 1.44, 2.35, BRISTOL_GLASS)
			continue
		if i == ring.size() - 1:
			var annex_top := _g + BRISTOL_ANNEX_TOP
			_wall(a, b, annex_top, y1, out, BRISTOL_WALL)
			var length := kit_front(b, a)
			kit_panes(_spread(0.0, length, 7), [annex_top + 0.6], 1.44, 2.35, BRISTOL_GLASS)
			continue
		_wall(a, b, _g - 0.6, y0, out, BRISTOL_SHADE, street_run)
		street_run += a.distance_to(b)
		_mode = M_MONUMENT
		_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y),
				Vector3(out.x, 0.0, out.y), BRISTOL_WALL, foot_uv, foot_uv, eave_uv, eave_uv, BRISTOL_CORNICE)
	_mode = M_STONE
	kit_ledge_ring(ring, _g + 0.28, 0.32, BRISTOL_SHADE.darkened(0.12), 0.12)
	kit_ledge_ring(ring, _g + 5.0, 0.2, KP_TRIM, 0.17)
	kit_cornice_ring(ring, _g + BRISTOL_CORNICE - 0.42, KP_TRIM, 0.42, 0.66)
	_mode = M_MONUMENT
	for court in courts:
		for i in court.size():
			var a := court[i]
			var b := court[(i + 1) % court.size()]
			_wall(a, b, _g - 0.6, _g + BRISTOL_ROOF, -_out(court, a, b), BRISTOL_WALL)
	_mode = M_STONE


## The lower service wing steps away from Karowa behind the ornate court block.
func _bristol_annex(ring: PackedVector2Array) -> void:
	_mode = M_STONE
	var top := _g + BRISTOL_ANNEX_TOP
	var rows: Array[float] = [_g + 1.92, _g + BRISTOL_SILL, _g + BRISTOL_SILL + 3.6, _g + BRISTOL_SILL + 7.2]
	# The last edge is shared by the tall block. Only the exposed walls need faces.
	for i in ring.size() - 1:
		var a := ring[i]
		var b := ring[i + 1]
		var out := _out(ring, a, b)
		_wall(a, b, _g - 0.6, top, out, BRISTOL_WALL)
		var length := kit_front(b, a)
		kit_panes(_spread(0.0, length, maxi(1, floori(length / 6.2))), rows, 1.44, 2.35, BRISTOL_GLASS)
	_cap(ring, top, BRISTOL_SLATE)


## Lay out the street bays symmetrically, keeping the first and last away from the corner returns.
func _bristol_front(from: Vector2, to: Vector2, krakowskie: bool) -> void:
	var length := kit_front(from, to)
	kit_face(0.0)
	var mid := length * 0.5
	var bays := floori(length / BRISTOL_BAY)
	if bays % 2 == 0:
		bays -= 1
	var first := mid - (bays - 1) * BRISTOL_BAY * 0.5
	var centres: Array[float] = []
	for bay in bays:
		centres.append(first + bay * BRISTOL_BAY)
	_bristol_gf(centres, mid if krakowskie else -10.0, krakowskie)
	_bristol_bays(centres)
	# The giant pairs frame every other bay from the mezzanine to the cornice.
	for bay in range(0, bays, 2):
		for side: float in [-1.0, 1.0]:
			kit_pilaster(centres[bay] + side * 1.53, _g + BRISTOL_MEZZ, _g + BRISTOL_CORNICE - 0.78, KP_TRIM, 0.6, 0.25)
	# The gallery spans five openings. Individual balconies match the width of their windows.
	kit_face(-0.045)
	kit_balcony(mid, _g + BRISTOL_SILL, 2.0 * BRISTOL_BAY + 0.79, Balcony.IRON, PAL_IRON, KP_TRIM, 1.05)
	for bay in range(0, bays, 2):
		kit_balcony(centres[bay], _g + BRISTOL_SILL + 7.2, 0.79, Balcony.IRON, PAL_IRON, KP_TRIM, 0.82)
	kit_face(0.0)
	if krakowskie:
		_bristol_gable(mid)
	_bristol_dormers(centres, mid if krakowskie else -10.0)


## Tall shop glazing and a mezzanine above it carry the storefront rhythm up to the giant order.
## Krakowskie's recessed panes use the warm-lit pavilion glass, as does the corner café.
func _bristol_gf(centres: Array[float], entrance: float, warm: bool, hw := 1.58) -> void:
	for u in centres:
		if absf(u - entrance) < BRISTOL_BAY * 0.5:
			continue
		kit_panes([u], [_g + 0.62], hw * 2.0, 4.06, PAL_IRON, 0.028)
		_mode = M_PAVILION if warm else M_GLASS
		_wall(_w(u - hw + 0.09, 0.08), _w(u + hw - 0.09, 0.08), _g + 0.72, _g + 4.58, _b, BRISTOL_GLASS)
	kit_panes(centres, [_g + 5.54], 1.4, 0.75, BRISTOL_GLASS)
	_mode = M_STONE
	if entrance >= 0.0:
		_bristol_entrance(entrance)


## The projecting doorway carries the two-post café canopy and the small gold neon board.
func _bristol_entrance(u: float) -> void:
	kit_face(0.7)
	_ubox(u - 2.18, u + 2.18, -0.05, 0.7, _g - 0.2, _g + 5.0, BRISTOL_SHADE)
	kit_door(u, _g + 0.12, 3.84, 1.56, KP_TRIM, PAL_IRON)
	_mode = M_PAVILION
	_wall(_w(u - 1.46, 0.78), _w(u + 1.46, 0.78), _g + 0.22, _g + 3.87, _b, BRISTOL_GLASS)
	_mode = M_STONE
	_lbox(u, 1.34, 2.42, 1.42, _g + 4.18, _g + 4.42, PAL_IRON)
	for side: float in [-1.0, 1.0]:
		kit_column(u + side * 2.12, 2.51, _g - 0.18, _g + 4.18, PAL_IRON, 0.10)
	_lbox(u, 0.74, 1.83, 0.08, _g + 4.46, _g + 5.02, Color("#2a2420"))
	# Batch the neon font's contiguous pixels into short runs on the board, in the site mesh.
	var word := "BRISTOL"
	_mode = M_LAMP
	var pitch := 0.065
	var left := u - Neon.word_width(word) * pitch * 0.5
	for ch in word:
		var rows: Array = Neon.FONT[ch]
		for row in rows.size():
			var line: String = rows[row]
			var start := -1
			for x in line.length() + 1:
				if x < line.length() and line[x] == "#":
					if start < 0:
						start = x
				elif start >= 0:
					var y := _g + 4.52 + (rows.size() - 1 - row) * pitch
					_wall(_w(left + start * pitch, 0.83), _w(left + x * pitch, 0.83), y, y + pitch, _b, Color("#ffd173"))
					start = -1
		left += (String(rows[0]).length() + 1) * pitch
	_mode = M_STONE
	kit_face(0.0)


## The four 3.6 m storeys have 1.4 m by 2.4 m panes and the first storey gets pedimented heads.
## Small attic panes occupy the tall frieze below the main cornice.
func _bristol_bays(centres: Array[float]) -> void:
	for storey in 4:
		var y := _g + BRISTOL_SILL + 3.6 * storey
		var style := Win.PEDIMENT if storey == 0 else Win.SILL_HEAD
		for u in centres:
			kit_window(u, y, 2.4, style, KP_TRIM, BRISTOL_GLASS)
	kit_panes(centres, [_g + 22.82], 0.83, 1.02, BRISTOL_GLASS)
	kit_ledge(centres[0] - 1.8, centres[-1] + 1.8, _g + 22.47, 0.16, KP_TRIM, 0.13)


## The three-bay segmental crown, its pale arch rim and relief cartouche above the blank frieze.
func _bristol_gable(mid: float) -> void:
	var half_width := 1.5 * BRISTOL_BAY
	var rise := 3.5
	var radius := (half_width * half_width + rise * rise) / (2.0 * rise)
	var angle := asin(half_width / radius)
	var base := _g + BRISTOL_CORNICE
	var front := Vector3(_b.x, 0.0, _b.y)
	var at := Vector3(_o.x, 0.0, _o.y)
	var along := Vector3(_a.x, 0.0, _a.y)
	var centre := at + along * mid + Vector3.UP * base
	var face := centre + front * 0.43
	var back := front * -2.5
	var rim := Vector3.UP * 0.24
	var prev := face - along * half_width
	var uv := Vector2(-1, -1)
	for k in range(1, 7):
		var theta := lerpf(-angle, angle, k / 6.0)
		var next := face + along * (radius * sin(theta)) + Vector3.UP * (radius * (cos(theta) - cos(angle)))
		_tri(face, prev, next, front, BRISTOL_WALL, uv, uv, uv, -1.0)
		_tri(face + back, prev + back + rim, next + back + rim, -front, BRISTOL_WALL, uv, uv, uv, -1.0)
		_quad(prev, next, next + rim, prev + rim, front, KP_TRIM)
		var slope := (next - prev).cross(back).normalized()
		_quad(prev + rim, next + rim, next + back + rim, prev + back + rim, slope, BRISTOL_SLATE)
		prev = next
	kit_ledge(mid - half_width, mid + half_width, _g + 24.08, 0.5, KP_TRIM, 0.21)
	var seal := face + front * 0.04 + Vector3.UP * 1.38
	_disc(seal, front, 0.84, 10, KP_TRIM)
	_disc(seal + front * 0.03, front, 0.63, 10, BRISTOL_SHADE)
	_disc(seal + front * 0.06, front, 0.39, 4, KP_TRIM)


## The steep lower zinc pitch breaks at a 30 cm curb into the shallower roof above the court.
func _bristol_mansard(ring: PackedVector2Array, courts: Array[PackedVector2Array]) -> void:
	var curb := _inset_ring(ring, BRISTOL_MANSARD_INSET)
	var top := _inset_ring(ring, 3.65)
	var flood := _flood
	_flood = false
	_slope(ring, ring, _g + BRISTOL_CORNICE, curb, _g + 28.3, BRISTOL_ZINC)
	_prism(curb, _g + 28.3, _g + 28.6, BRISTOL_ZINC.lightened(0.13), Color(0, 0, 0, 0), M_STONE)
	var upper_zinc := BRISTOL_ZINC.lightened(0.21)
	_slope(ring, curb, _g + 28.6, top, _g + BRISTOL_ROOF, upper_zinc)
	_cap_holes(top, courts, _g + BRISTOL_ROOF, upper_zinc)
	_flood = flood


## Hipped zinc dormers take every other street bay, with larger round heads at the terminals.
## The three central Krakowskie bays are taken by the gable.
func _bristol_dormers(centres: Array[float], gable: float) -> void:
	var flood := _flood
	_flood = false
	var y := _g + 26.03
	var v := -0.48
	var depth := 2.5
	var body := BRISTOL_ZINC.darkened(0.08)
	kit_face(v)
	for bay in range(0, centres.size(), 2):
		var u := centres[bay]
		if absf(u - gable) < 1.5 * BRISTOL_BAY - 0.05:
			continue
		var large := bay == 0 or bay == centres.size() - 1
		var hw := 1.09 if large else 0.85
		var top := y + (2.18 if large else 1.96)
		var box := _rect(u, v - depth * 0.5, hw, depth * 0.5)
		# The back of each dormer is inside the mansard. Draw the front and cheeks.
		for i in range(1, box.size()):
			var a := box[i]
			var b := box[(i + 1) % box.size()]
			_wall(a, b, y - 0.53, top, _out(box, a, b), body)
		_pyramid(_rect(u, v - depth * 0.5, hw + 0.11, depth * 0.5 + 0.09),
				top, top + 0.65, BRISTOL_ZINC.darkened(0.14))
		if large:
			kit_round_window(_w(u, v), _a, _b, y + 0.18, y + 1.19, 0.66, BRISTOL_ZINC.lightened(0.2), BRISTOL_GLASS)
		else:
			kit_panes([u], [y + 0.19], 1.22, 1.45, BRISTOL_GLASS)
	kit_face(0.0)
	_flood = flood


## The 12-sided drum rises through the roof. Below it, the mapped curved frontage carries the
## same shop, sill and storey bands as the streets, so the tower reads as part of the building.
func _bristol_drum(ring: PackedVector2Array) -> void:
	var none := Color(0, 0, 0, 0)
	var drum := _circle(BRISTOL_TOWER, 3.4, 12)
	_prism(drum, _g + BRISTOL_CORNICE, _g + BRISTOL_DRUM_TOP, BRISTOL_WALL, none, M_STONE)
	for k in 8:
		var at := BRISTOL_TOWER + Vector2.from_angle(TAU * (k + 0.5) / 8.0) * 3.18
		var out := (at - BRISTOL_TOWER).normalized()
		kit_front(at, at + Vector2(out.y, -out.x))
		kit_pilaster(0.0, _g + BRISTOL_CORNICE, _g + BRISTOL_DRUM_TOP - 0.04, KP_TRIM, 0.6, 0.49)
	var sills: Array[float] = []
	for storey in 4:
		sills.append(_g + BRISTOL_SILL + 3.6 * storey)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if a.distance_to(BRISTOL_TOWER) > 5.3 or b.distance_to(BRISTOL_TOWER) > 5.3:
			continue
		var length := kit_front(b, a)
		var mid := length * 0.5
		var shops: Array[float] = [mid]
		_bristol_gf(shops, -10.0, true, minf(1.58, mid - 0.2))
		kit_panes(shops, sills, 1.1, 2.4, BRISTOL_GLASS)
		for y: float in [6.46, 13.85, 21.05]:
			kit_ledge(0.12, length - 0.12, _g + y, 0.15, KP_TRIM, 0.16)


## The v1 belvedere keeps the oversailing ring, eight columns, blue core, shallow cap and finial.
func _bristol_belvedere() -> void:
	var c := BRISTOL_TOWER
	var top := _g + BRISTOL_DRUM_TOP
	var none := Color(0, 0, 0, 0)
	_prism(_circle(c, 3.9, 12), top, top + 0.5, KP_TRIM, KP_TRIM, M_STONE, M_STONE)
	_prism(_circle(c, 3.6, 12), top + 0.5, top + 1.3, BRISTOL_WALL, BRISTOL_WALL, M_STONE)
	var core := Color("#4a7ad8").darkened(0.24)  # Keep the core in shade by day.
	_prism(_circle(c, 2.6, 8), top + 0.5, top + 4.0, core, none, M_LAMP)
	kit_front(c, c + Vector2.RIGHT)
	for k in 8:
		var p := Vector2.from_angle(TAU * k / 8.0) * 3.0
		kit_column(p.x, p.y, top + 1.3, top + 4.0, KP_TRIM, 0.2)
	_prism(_circle(c, 3.5, 12), top + 4.0, top + 4.6, KP_TRIM, KP_TRIM, M_STONE, M_STONE)
	_frustum(_circle(c, 3.3, 12), top + 4.6, _circle(c, 2.0, 12), top + 5.6, BRISTOL_WALL)
	_frustum(_circle(c, 2.0, 12), top + 5.6, _circle(c, 0.5, 12), top + 6.2, BRISTOL_WALL, BRISTOL_WALL)
	_prism(_circle(c, 0.12, 4), top + 6.2, top + 7.4, Color("#c9a24a"), Color("#c9a24a"), M_STONE, M_STONE)

## Rynek Mariensztacki (BACKLOG M2): the 1949 estate's square. Its six houses on the south side
## (Mariensztat 19 to 25) each carry a relief panel on the street face (a framed terracotta
## field, a pale sun and two standing figures), the "socialist-realist" touch the estate is
## known for; the square's fountain ring stays the map's. A placeholder composition: the real
## panels' subjects and positions wait for the Mac's photos (QUESTIONS). The card is here.
## The panels' centres and the face's z (from each house's outline), the face looks north.
const MARIENSZTAT_PANELS := [
	Vector2(-522.2, -1334.4), Vector2(-506.9, -1333.9), Vector2(-494.8, -1334.05),
	Vector2(-482.8, -1334.15), Vector2(-470.9, -1334.3), Vector2(-457.3, -1334.55),
]
const MZ_FIELD := Color("#b0634a")
const MZ_FRAME := Color("#efe6d2")


func _find_mariensztat() -> void:
	var zones: Array = []
	_a = Vector2(-1.0, 0.0)
	_b = Vector2(0.0, -1.0)
	for p: Vector2 in MARIENSZTAT_PANELS:
		_o = p
		zones.append(_rect(0.0, 0.5, 2.4, 1.0))
	_add_site("mariensztat", zones)


func _build_mariensztat(_site: Dictionary) -> void:
	_a = Vector2(-1.0, 0.0)
	_b = Vector2(0.0, -1.0)
	_mode = M_STONE
	for p: Vector2 in MARIENSZTAT_PANELS:
		_o = p
		_g = map.terrain_height(p.x, p.y)
		var g := _g
		_lbox(0.0, 0.0, 2.3, 0.1, g - 0.3, g + 0.9, MZ_FRAME.darkened(0.25), M_STONE, MZ_FRAME.darkened(0.2))
		for s: float in [-1.0, 1.0]:  # a pilaster each side, from the plinth up to the panel
			_lbox(s * 1.95, 0.0, 0.1, 0.08, g + 0.9, g + 5.5, MZ_FRAME, M_STONE, MZ_FRAME)
		_lbox(0.0, 0.05, 2.0, 0.1, g + 5.5, g + 9.0, MZ_FRAME, M_STONE, MZ_FRAME)
		_lbox(0.0, 0.08, 1.7, 0.1, g + 5.8, g + 8.7, MZ_FIELD, M_STONE, MZ_FIELD)
		for s: float in [-1.0, 1.0]:  # a standing figure either side of the sun
			_lbox(s * 1.1, 0.12, 0.28, 0.12, g + 5.8, g + 7.3, MZ_FRAME, M_STONE, MZ_FRAME)
			_lbox(s * 1.1, 0.12, 0.18, 0.12, g + 7.3, g + 7.8, MZ_FRAME, M_STONE, MZ_FRAME)
		var c := _w(0.0, 0.23)
		_disc(Vector3(c.x, g + 7.8, c.y), Vector3(_b.x, 0.0, _b.y), 0.7, 8, MZ_FRAME)


## Bolesław Prus's statue (Anna Kamieńska-Łapińska, 1977) on Twardowski Square: 3.6 m of bronze,
## an old man standing slightly bent in a long coat, hands and cane behind his back, on a low
## granite base. K6; the facing (towards the street) is an estimate. Spec prus.md.
func _build_prus(_site: Dictionary) -> void:
	_o = PRUS
	_a = STREET_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(PRUS.x, PRUS.y)
	var g := _g
	_mode = M_STONE
	_lbox(0.0, 0.0, 1.5, 1.5, g - 0.3, g + 0.35, KP_GRANITE, M_STONE, KP_GRANITE.lightened(0.06))
	_lbox(0.0, 0.0, 1.2, 1.2, g + 0.35, g + 0.6, KP_GRANITE.lightened(0.05), M_STONE, KP_GRANITE.lightened(0.1))
	var c := _w(0.0, 0.0)
	var top := g + 0.6
	_frustum(_circle(c, 0.5, 8), top, _circle(c, 0.42, 8), top + 1.6, KP_BRONZE)  # the long coat
	_frustum(_circle(c, 0.42, 8), top + 1.6, _circle(c, 0.3, 8), top + 2.4, KP_BRONZE)  # the shoulders
	_frustum(_circle(c, 0.3, 8), top + 2.4, _circle(c, 0.14, 8), top + 2.6, KP_BRONZE)  # the neck
	_prism(_circle(_w(0.1, 0.0), 0.2, 8), top + 2.6, top + 3.0, KP_BRONZE, KP_BRONZE, M_STONE, M_STONE)
	_lbox(-0.45, 0.0, 0.1, 0.12, top + 0.1, top + 1.5, KP_BRONZE, M_STONE, KP_BRONZE)  # the cane behind
	_collide(_rect(0.0, 0.0, 1.5, 1.5))


## Cardinal Stefan Wyszyński's statue (Andrzej Renes, 1987) before the Visitationists' church:
## the Primate seated, bronze, on a granite pedestal with a wide slab for candles and flowers.
## K6; the facing (west, to the street) is an estimate. Spec wyszynski.md.
func _build_wyszynski(_site: Dictionary) -> void:
	_o = WYSZYNSKI
	_a = STREET_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(WYSZYNSKI.x, WYSZYNSKI.y)
	var g := _g
	_mode = M_STONE
	var robe := Color("#5e5c4c")
	for k in 2:  # two steps, the pedestal, the slab
		_lbox(0.0, 0.0, 3.2 - 0.6 * k, 3.2 - 0.6 * k, g - 0.3 + 0.2 * k, g + 0.2 * (k + 1), KP_GRANITE, M_STONE,
				KP_GRANITE.lightened(0.05))
	_lbox(0.0, 0.0, 1.9, 1.9, g + 0.4, g + 1.9, KP_GRANITE.lightened(0.06), M_STONE, KP_GRANITE.lightened(0.1))
	_lbox(0.0, 0.2, 2.6, 2.2, g + 1.9, g + 2.2, KP_GRANITE.lightened(0.04), M_STONE, KP_GRANITE.lightened(0.1))
	var top := g + 2.2
	_lbox(-0.2, 0.0, 0.5, 1.1, top, top + 1.6, robe, M_STONE, robe)  # the throne's back
	_lbox(0.2, 0.0, 1.0, 1.1, top, top + 0.8, robe, M_STONE, robe)  # the seat and robe
	_lbox(0.55, 0.0, 0.5, 0.9, top + 0.0, top + 0.5, robe, M_STONE, robe)  # the hem on the knees
	var c := _w(0.0, 0.0)
	_frustum(_circle(c, 0.5, 8), top + 0.8, _circle(c, 0.38, 8), top + 1.7, robe)  # chest
	_prism(_circle(_w(0.1, 0.0), 0.17, 8), top + 1.7, top + 2.1, robe, robe, M_STONE, M_STONE)  # head
	_lbox(0.45, 0.3, 0.4, 0.14, top + 1.2, top + 1.3, robe, M_STONE, robe)  # the hand at the chin
	_collide(_rect(0.0, 0.0, 3.2, 3.2))


# --- Old Town hotels -----------------------------------------------------------------------

## The Old Town hotels (F, 2026-11-01: "what about hotels in old town?"). OpenStreetMap maps
## none of them as a building (they are rooms in tenements), so each hotel is a **front** put on
## the street-facing facade of the tenement nearest a published spot: a portal (two pilasters,
## an architrave and a warm glass door), a flat canopy, a dark fascia board with its name in
## neon (HOTEL over the name), two flag arms and two lanterns. The house itself stays the map's
## (the zone is the strip in front of the facade, so nothing is dropped). Names are parodies:
## Castle Inn becomes KASZTEL INN, Hotel Bellotto (the painter's real surname) CANALETTO, an
## aparthotel on the Market Square STARÓWKA. The spots are estimates (no photo is reachable from
## the cloud): the Mac look check waits in QUESTIONS. Each entry: key, "o" the middle of the
## facade edge (found offline: the tenement within 45 m of the published spot, its edge nearest
## a street, from centrum.json; constants, so a streamed sector needs no building data), "out"
## the facade's outward normal, the name, the board and canopy colours, the tube colour and the
## flag's stripes from the facade out.
const HOTELS := [
	{"key": "hotel_kasztel", "o": Vector2(-705.6, -1580.7), "out": Vector2(-0.732186, 0.681105),
			"word": "KASZTEL INN", "board": "#1f2a44", "canopy": "#2b3350", "tube": Color(1.0, 0.82, 0.4),
			"flag": ["#f2efe8", "#d6283a"]},
	{"key": "hotel_canaletto", "o": Vector2(-860.7, -1774.25), "out": Vector2(-0.765613, 0.643301),
			"word": "CANALETTO", "board": "#5a1f26", "canopy": "#3b2326", "tube": Color(1.0, 0.9, 0.62),
			"flag": ["#2f8a4a", "#f2efe8", "#d6283a"]},
	{"key": "hotel_starowka", "o": Vector2(-779.85, -1769.15), "out": Vector2(-0.755688, 0.654932),
			"word": "STARÓWKA", "board": "#27443a", "canopy": "#233a32", "tube": Color(1.0, 0.7, 0.5),
			"flag": ["#f2efe8", "#d6283a"]},
]
const HOTEL_TRIM := Color("#e6dcc8")


func _find_hotels() -> void:
	var polonia := _landmark("Hotel Polonia Palace")
	if polonia.size() >= 3:
		_add_site("polonia", [polonia])
		if not sites.is_empty() and sites[-1]["key"] == "polonia":
			sites[-1]["ring"] = _simplify(polonia, 0.7)
	var sobieski := _landmark("Radisson Blu Sobieski")
	if sobieski.size() >= 3:
		_add_site("sobieski", [sobieski])
		if not sites.is_empty() and sites[-1]["key"] == "sobieski":
			sites[-1]["ring"] = _simplify(sobieski, 1.2)
	for h: Dictionary in HOTELS:
		_o = h["o"]
		_b = h["out"]
		_a = Vector2(-_b.y, _b.x)
		# The strip in front of the facade, 6 m wide: the house behind is not touched.
		_add_site(h["key"], [_rect(0.0, 0.95, 3.0, 0.95)])


## One hotel front in the frame `_find_hotels` set: u along the facade, v out of it.
func _build_hotel(site: Dictionary) -> void:
	var spec: Dictionary = {}
	for h: Dictionary in HOTELS:
		if h["key"] == site["key"]:
			spec = h
	if spec.is_empty():
		return
	_o = spec["o"]
	_b = spec["out"]
	_a = Vector2(-_b.y, _b.x)
	_g = map.terrain_height(_o.x, _o.y)
	var g := _g
	var board := Color(spec["board"])
	var canopy := Color(spec["canopy"])
	_mode = M_STONE
	# The portal: two pilasters and the architrave, 0.4 m into the facade line and out of it, so
	# a LoD2 wall a little off OSM's edge still meets them.
	for sd: float in [-1.0, 1.0]:
		_lbox(sd * 1.5, 0.0, 0.3, 0.4, g - 0.2, g + 3.4, HOTEL_TRIM, M_STONE, HOTEL_TRIM)
	_lbox(0.0, 0.0, 1.8, 0.45, g + 3.0, g + 3.4, HOTEL_TRIM, M_STONE, HOTEL_TRIM)
	# The door: warm glass between the pilasters, lit from inside at night.
	_mode = M_PAVILION
	_wall(_w(-1.2, 0.3), _w(1.2, 0.3), g + 0.05, g + 3.0, _b, Color("#f3d9a8"))
	# The canopy over it, and the board above that.
	_mode = M_STONE
	_lbox(0.0, 0.7, 2.2, 0.6, g + 3.3, g + 3.55, canopy, M_STONE, canopy.lightened(0.1))
	_lbox(0.0, 0.0, 2.3, 0.3, g + 3.5, g + 5.7, board, M_STONE, board.lightened(0.08))
	# The flag arms at the board's ends, each with its stripes hanging in the plane of the arm.
	var stripes: Array = spec["flag"]
	for sd: float in [-1.0, 1.0]:
		_lbox(sd * 2.2, 0.6, 0.04, 0.6, g + 5.7, g + 5.8, HOTEL_TRIM.darkened(0.45), M_STONE)
		var w := 0.9 / stripes.size()
		for n in stripes.size():
			_lbox(sd * 2.2, 0.2 + w * (n + 0.5), 0.02, w * 0.5, g + 4.55, g + 5.75, Color(stripes[n]), M_STONE)
		# A lantern on the pilaster's outer face.
		_mode = M_LAMP
		_lbox(sd * 1.9, 0.3, 0.12, 0.12, g + 2.5, g + 2.9, HOTEL_LAMP, M_LAMP)
		_mode = M_STONE
	# The name: HOTEL over it, in neon on the board's face (map_builder's _build_landmark_signs).
	var word: String = spec["word"]
	var o3 := Vector3(_b.x, 0.0, _b.y)
	var k := minf(0.34, 4.2 / Neon.length_of(word))
	var face := _w(0.0, 0.3 - 0.4 + 0.03)
	signs.append(["HOTEL", Vector3(face.x, g + 4.95, face.y), o3, 0.25, Color(1.0, 0.45, 0.45)])
	signs.append([word, Vector3(face.x, g + 3.85, face.y), o3, k, spec["tube"]])
	_collide(_rect(0.0, 0.0, 2.0, 0.4))
	# Tapping the house's front (12 m wide, 7 m deep behind the facade, 2 m out) opens the card.
	var pick := _rect(0.0, -2.5, 6.0, 4.5)
	var cell: float = map.ROOF_CELL
	var box := _box_of([pick])
	var i0 := maxi(floori((box.position.x - map._roof_x0) / cell), 0)
	var i1 := mini(floori((box.end.x - map._roof_x0) / cell), map._roof_nx - 1)
	var j0 := maxi(floori((box.position.y - map._roof_z0) / cell), 0)
	var j1 := mini(floori((box.end.y - map._roof_z0) / cell), map._roof_nz - 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var q := Vector2(map._roof_x0 + (i + 0.5) * cell, map._roof_z0 + (j + 0.5) * cell)
			if Geometry2D.is_point_in_polygon(q, pick):
				_pick.encode_u16((j * map._roof_nx + i) * 2, _id)


## --- The palace hotels (F, 2026-11-01: "model the Bristol and the other hotels properly") ------
## One builder for the two turn-of-the-century grand hotels, from their OSM outlines (no photos):
## a rusticated plinth under a balcony band, string courses, a stepped cornice and a slate
## mansard with a dormer every 4.4 m on the public fronts, and on the longest public front a
## forward bay with a canopied lit door, a gilded name board and a pediment. `whole` builds the
## mass too (Polonia Palace; the OSM outline is a low shed there), otherwise the mass is the
## kept skin's (Bristol). `party` is a neighbour's outline (a shared wall carries no trim).
## Specs docs/landmarks/specs/bristol.md and polonia.md.
const POLONIA_H := 25.5


func _palace_hotel(ring: PackedVector2Array, g: float, h: float, spec: Dictionary, party: PackedVector2Array) -> void:
	_g = g
	var none := Color(0, 0, 0, 0)
	var wall: Color = spec["wall"]
	var base: Color = spec["base"]
	var trim: Color = spec["trim"]
	var slate: Color = spec["slate"]
	var n := ring.size()
	var shared := PackedVector2Array()
	if party.size() >= 3:
		var grown := Geometry2D.offset_polygon(party, 0.8, Geometry2D.JOIN_MITER)
		if not grown.is_empty():
			shared = grown[0]
	var edges: Array[Dictionary] = []  # the public edges: a, b, length, out
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var out := _out(ring, a, b)
		var mid := (a + b) * 0.5
		if shared.size() >= 3 and Geometry2D.is_point_in_polygon(mid + out * 0.1, shared):
			continue
		edges.append({"a": a, "b": b, "len": a.distance_to(b), "out": out})
	_mode = M_STONE
	if spec["whole"]:
		for k in 5:  # the rusticated courses, each with its light edge
			var y0 := g - 0.6 + 6.0 * k / 5.0
			var y1 := g - 0.6 + 6.0 * (k + 1) / 5.0
			_prism(ring, y0, y1, base.darkened(0.12 if k == 0 else (0.0 if k % 2 == 1 else 0.05)), none, M_STONE)
		_bays(ring, 0.8, 4.6, 4.2, 1.9, spec["glass"], shared)
		_prism(ring, g + 5.4, g + h, wall, none, M_MONUMENT)
	else:
		var plinth := _inset_ring(ring, -0.25)
		for k in 4:
			_prism(plinth, g - 0.6 + 6.0 * k / 4.0, g - 0.6 + 6.0 * (k + 1) / 4.0,
					base.darkened(0.1 if k == 0 else (0.0 if k % 2 == 1 else 0.05)), none, M_STONE)
		_bays(ring, 0.9, 4.6, 4.2, 1.9, spec["glass"], shared)
	_prism(_inset_ring(ring, -0.45), g + 5.4, g + 5.85, trim, trim.darkened(0.06), M_STONE, M_STONE)  # the balcony band
	_prism(_inset_ring(ring, -0.2), g + h - 6.4, g + h - 6.05, trim, none, M_STONE)  # under the top floor
	_prism(_inset_ring(ring, -0.35), g + h - 2.0, g + h - 1.2, trim, none, M_STONE)  # the cornice's frieze
	_prism(_inset_ring(ring, -0.8), g + h - 1.2, g + h - 0.5, trim, trim.darkened(0.08), M_STONE, M_STONE)  # its ledge
	_prism(_inset_ring(ring, -0.3), g + h - 0.5, g + h + 0.35, trim, none, M_STONE)  # the parapet's plinth
	if spec.has("balcony_rows"):
		# Polonia's long balconies (F's photos 2, 4): a slab 0.6 m out with a dark iron railing.
		for yb: float in spec["balcony_rows"]:
			_prism(_inset_ring(ring, -0.6), g + yb, g + yb + 0.25, trim, trim.darkened(0.05), M_STONE, M_STONE)
			_prism(_inset_ring(ring, -0.58), g + yb + 0.25, g + yb + 0.85, Color("#5a5450"), Color(0, 0, 0, 0), M_STONE)
	# The mansard: slate, pitched in from the parapet to a flat top (`mansard_h` tall; Polonia's
	# is a storey and a half, steep, F's photos).
	var mh: float = spec.get("mansard_h", 3.25)
	var m0 := _inset_ring(ring, 0.9)
	var m1 := _inset_ring(ring, 2.8)
	_mode = M_STONE
	_slope(ring, m0, g + h + 0.35, m1, g + h + 0.35 + mh, slate)
	_cap(m1, g + h + 0.35 + mh, slate.lightened(0.06))
	# Dormers, one every 4.4 m on each public front, each in its edge's frame (u along, v out).
	var avoid: Vector2 = spec.get("avoid", Vector2(INF, INF))
	var avoid_r: float = spec.get("avoid_r", 0.0)
	var street_at: Vector2 = spec.get("street_at", Vector2.ZERO)  # when given, the front is within 30 m of it
	var front := -1
	var front_len := 0.0
	for k in edges.size():
		var e: Dictionary = edges[k]
		var el: float = e["len"]
		if el > front_len and (not spec.has("street_at") or ((e["a"] + e["b"]) * 0.5).distance_to(street_at) < 30.0):
			front_len = el
			front = k
		if el < 9.0:
			continue
		_o = e["a"]
		_b = e["out"]
		_a = (e["b"] - e["a"]) / el
		var cnt := floori((el - 2.0) / 4.4)
		var u0 := (el - (cnt - 1) * 4.4) * 0.5
		for j in cnt:
			var u := u0 + j * 4.4
			if _w(u, 0.0).distance_to(avoid) < avoid_r:
				continue
			var y := g + h + 0.35
			_mode = M_STONE
			var dh := 1.7 if mh < 4.0 else 2.4   # Polonia's dormers are a full storey (photo 4)
			_lbox(u, -1.7, 0.55, 0.6, y + 0.3, y + 0.3 + dh, wall, M_STONE, wall)
			_hip(u, -1.7, 0.7, 0.75, y + 0.3 + dh, 0.8, slate.lightened(0.1))
			_mode = M_GLASS
			_wall(_w(u - 0.32, -1.07), _w(u + 0.32, -1.07), y + 0.65, y + dh, e["out"], spec["glass"])
	if front < 0 or front_len < 18.0:
		return
	# The forward bay on the longest public front.
	var fe: Dictionary = edges[front]
	_o = (fe["a"] + fe["b"]) * 0.5
	_b = fe["out"]
	_a = (fe["b"] - fe["a"]) / front_len
	var board: Color = spec["board"]
	var canopy: Color = spec["canopy"]
	_mode = M_STONE
	_lbox(0.0, 0.5, 5.0, 0.5, g - 0.6, g + 5.4, base.darkened(0.04), M_STONE, base)
	_lbox(0.0, 0.45, 5.0, 0.45, g + 5.4, g + h - 1.9, wall, M_MONUMENT, wall)
	for sd: float in [-1.0, 1.0]:
		_lbox(sd * 4.8, 0.95, 0.28, 0.12, g + 5.4, g + h - 1.9, trim, M_STONE, trim)
		_lbox(sd * 2.1, 1.0, 0.22, 0.1, g - 0.2, g + 4.0, trim, M_STONE, trim)  # the door's surround
	_lbox(0.0, 1.0, 2.3, 0.1, g + 3.9, g + 4.2, trim, M_STONE, trim)
	_lbox(0.0, 0.5, 5.3, 0.55, g + h - 1.9, g + h + 0.6, trim, M_STONE, trim.darkened(0.06))
	_mode = M_PAVILION
	_wall(_w(-1.8, 1.04), _w(1.8, 1.04), g + 0.05, g + 3.9, _b, Color("#f3d9a8"))
	_mode = M_STONE
	_lbox(0.0, 2.0, 3.7, 1.1, g + 4.3, g + 4.55, canopy, M_STONE, canopy.lightened(0.12))
	for sd: float in [-1.0, 1.0]:  # the canopy's two posts
		_column(sd * 3.4, 2.9, 0.12, g - 0.2, g + 4.3, trim.darkened(0.3))
		_mode = M_LAMP
		_lbox(sd * 2.5, 1.16, 0.1, 0.1, g + 2.6, g + 3.0, HOTEL_LAMP, M_LAMP)
		_mode = M_STONE
	_lbox(0.0, 1.06, 3.2, 0.05, g + 4.6, g + 5.3, board, M_STONE, board.lightened(0.08))
	var word: String = spec["name"]
	var face := _w(0.0, 1.13)
	signs.append([word, Vector3(face.x, g + 4.78, face.y), Vector3(_b.x, 0.0, _b.y),
			minf(0.2, float(spec["name_w"]) / Neon.length_of(word)), spec["tube"]])
	if spec.has("pediment_w"):
		_wide_pediment(fe, g, h, float(spec["pediment_w"]), wall, trim, slate, spec)
		return
	# The pediment, in a frame turned to face out of the bay.
	_a = fe["out"]
	_b = Vector2(-_a.y, _a.x)
	_o = (fe["a"] + fe["b"]) * 0.5
	_mode = M_STONE
	_lbox(0.0, 0.0, 0.6, 3.6, g + h + 0.6, g + h + 2.4, wall, M_STONE, trim)
	_gable(0.62, -0.5, 0.0, 3.7, g + h + 2.4, 1.9, wall, slate.lightened(0.05))


## Polonia's crown over the entrance (F's photos 1, 3, 4): the middle five bays rise through the
## mansard as a wall `w` m either side of the bay's centre to a wide low pediment with an oval
## window in its tympanum, and the hotel's name in gold letters on the frieze under it.
func _wide_pediment(fe: Dictionary, g: float, h: float, w: float, wall: Color, trim: Color, slate: Color, spec: Dictionary) -> void:
	_o = (fe["a"] + fe["b"]) * 0.5
	_b = fe["out"]
	_a = (fe["b"] - fe["a"]) / float(fe["len"])
	var y0 := g + h + 0.35
	var yt := y0 + 0.3
	_mode = M_STONE
	_lbox(0.0, -0.8, w + 0.3, 1.85, y0 - 0.4, yt + 0.2, trim, M_STONE, trim)   # the cornice under the gable
	# The gable's two raking cornices and its face, in a frame turned to face out of the front.
	var mid: Vector2 = (fe["a"] + fe["b"]) * 0.5
	_a = fe["out"]
	_b = Vector2(-_a.y, _a.x)
	_o = mid
	_gable(1.0, -2.6, 0.0, w + 0.3, yt + 0.2, 3.8, wall, slate.lightened(0.05))
	# The oval window: a dark pane in a pale ring, on the gable's face.
	_o = mid
	_b = fe["out"]
	_a = (fe["b"] - fe["a"]) / float(fe["len"])
	var n3 := Vector3(_b.x, 0.0, _b.y)
	var oc := _w(0.0, 1.04)
	_mode = M_STONE
	_disc(Vector3(oc.x, yt + 1.7, oc.y), n3, 1.2, 12, trim.lightened(0.05))
	var og := _w(0.0, 1.08)
	_mode = M_GLASS
	_disc(Vector3(og.x, yt + 1.7, og.y), n3, 0.85, 12, spec["glass"])
	_mode = M_STONE
	var word: String = spec.get("name_high", "")
	if word != "":
		var at := _w(0.0, 0.96)
		signs.append([word, Vector3(at.x, g + h - 3.4, at.y), Vector3(_b.x, 0.0, _b.y),
				minf(0.24, w * 1.5 / Neon.length_of(word)), spec["tube"]])


## Hotel Polonia Palace (1913), Al. Jerozolimskie 45: the one grand hotel that came through the
## Uprising standing. Built whole (the OSM outline is a low shed) from the outline's `ring`.
func _build_polonia(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	var party := _landmark("Hotel Metropol")
	# F's photos (2026-11-08): warm cream stone, a pale ground floor of tall shop windows, long
	# balconies on the first and fourth floors, a steep grey-blue zinc mansard a storey and a half
	# high with a dormer at every bay, and the middle bays' wide pediment with the oval window and
	# the gold name on the frieze (spec docs/landmarks/specs/polonia.md).
	_palace_hotel(ring, _ground_under(ring), POLONIA_H, {
			"wall": Color("#e2d0aa"), "base": Color("#d3c19c"), "trim": Color("#efe5cf"), "slate": Color("#626b72"),
			"glass": Color("#353a40"), "name": "POLONIA PALACE", "name_w": 6.6, "board": Color("#3a1f24"),
			"tube": Color(1.0, 0.85, 0.5), "whole": true, "canopy": Color("#6b2a2f"),
			"mansard_h": 5.6, "pediment_w": 8.5, "name_high": "POLONIA PALACE HOTEL",
			"balcony_rows": [9.2, 20.4]}, party)
	_collide(ring)


# --- Plac Krasińskich: Pomnik Powstania Warszawskiego and Pałac Krasińskich --------------------

## The Warsaw Uprising Monument (Wincenty Kućma and Jacek Budyn, 1989; spec
## docs/landmarks/specs/pomnik_powstania.md, from the Mac's Commons photos and GUGiK ortho,
## 2026-11-02). Two bronze groups at the Supreme Court's foot, 26 m apart: "Szturmujący" (north),
## insurgents running out of a broken brick wall under two huge tilted granite slabs, on a
## granite landing beside the wide steps up to the court's colonnade; "Przejście kanałami"
## (south, on the paved square's west edge), a priest and soldiers going down a sewer manhole.
## Frame: u along the court's wall (bearing 67, ENE), +v the groups' front (SSE, to the square).
## OpenStreetMap maps only the big group's outline (way 1327606552) and a nameless 4x5 m way for
## the small one, neither a building: the zone is a 0.2 m square in front of the landing, so the
## site drops nothing of the map.
const PP := Vector2(-1235.0, -1700.0)        # the big group's centre (the OSM outline's)
const PP_AXIS := Vector2(0.9205, -0.3907)    # u: bearing 67
const PP_LANDING := 0.6                      # the landing over the ground at PP
const PP_KANALY := Vector2(-1234.5, -1674.0) # the small group's centre (ortho)
const PP_KANALY_FWD := Vector2(0.766, 0.643) # the small group faces SE, bearing ~130
const PP_GRANITE := Color("#c5c7ba")
const PP_GRANITE_TOP := Color("#d6d8d3")
const PP_GRANITE_SHADE := Color("#9a9f9b")
const PP_BRONZE := Color("#3b3628")
const PP_BRONZE_DARK := Color("#2a261f")
const PP_STEPS := Color("#cfd0ca")
const PP_SETTS := Color("#8f8a8a")
const PP_MANHOLE := Color("#1f1d1a")
const PP_LAMP := Color("#ffb066")
## The ruin's brick wall in bronze, in pieces of broken height: [cu, hu, top over the landing].
const PP_WALL := [[-6.6, 0.9, 2.6], [-5.0, 0.8, 3.6], [-3.5, 0.8, 3.1], [3.3, 0.9, 3.8], [5.0, 0.8, 2.9], [6.6, 0.8, 2.2]]
## The "rubble city" between the slabs: vertical bronze blocks [cu, cv, hu, hv, top].
const PP_RUBBLE := [[-2.2, -0.9, 0.55, 0.7, 4.6], [-1.2, -1.2, 0.45, 0.6, 5.6], [-0.2, -0.8, 0.5, 0.75, 4.1],
		[0.8, -1.3, 0.45, 0.55, 5.2], [1.8, -0.9, 0.5, 0.7, 4.4]]
## The fighters running out of the wall: [cu, cv, heading u, heading v, pose] (0 running, 1 kneeling
## with a rifle, 2 running with a rifle raised).
const PP_FIGHTERS := [[-7.0, 0.9, -0.6, 0.8, 0], [-5.6, 1.6, -0.35, 0.94, 2], [-3.4, 1.2, -0.1, 1.0, 0],
		[-2.0, 2.3, 0.0, 1.0, 1], [-0.6, 1.3, 0.05, 1.0, 2], [0.9, 2.1, 0.15, 1.0, 0], [2.3, 1.1, 0.2, 0.98, 0],
		[3.9, 1.9, 0.3, 0.95, 2], [5.4, 1.1, 0.45, 0.9, 0], [6.8, 2.0, 0.6, 0.8, 1], [7.6, 0.8, 0.7, 0.7, 2]]


func _find_pomnik_powstania() -> void:
	# Only where the square is (the start-area-sized test maps have no Plac Krasińskich).
	if _landmark("Pałac Krasińskich").size() < 3:
		return
	var p := PP + Vector2(0.39, 0.92) * 6.5
	_add_site("pomnik_powstania", [PackedVector2Array([p, p + Vector2(0.2, 0), p + Vector2(0.2, 0.2), p + Vector2(0, 0.2)])])


func _build_pomnik_powstania(_site: Dictionary) -> void:
	_o = PP
	_a = PP_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(PP.x, PP.y)
	var land := _g + PP_LANDING
	var foot := minf(_g, minf(map.terrain_height(_w(-20.0, 6.0).x, _w(-20.0, 6.0).y),
			map.terrain_height(_w(0.0, 7.0).x, _w(0.0, 7.0).y))) - 0.6
	# the landing the big group stands on, level with the top of the court's steps
	_lbox(0.0, 0.0, 9.0, 3.4, foot, land, PP_GRANITE_SHADE, M_STONE, PP_GRANITE_TOP)
	# four treads down from its front edge to the square
	for k in 4:
		var top := land - 0.17 * (k + 1)
		_lbox(0.0, 3.4 + 0.45 * k + 0.225, 9.0, 0.225, foot, top, PP_STEPS.darkened(0.05), M_STONE, PP_STEPS)
	# the wide flight west of it, rising towards the colonnade (risers along u)
	for k in 8:
		var v0 := 4.0 - 1.5 * (k + 1)
		var top := land - 0.19 * (7 - k)
		_lbox(-18.0, v0 + 0.75, 9.0, 0.75, foot, top, PP_STEPS.darkened(0.05), M_STONE, PP_STEPS)
	_collide(_rect(-9.0, -0.5, 18.0, 5.6))
	# the broken brick wall in bronze, the gap in the middle where the fighters come out
	for wpc: Array in PP_WALL:
		_lbox(wpc[0], -1.6, wpc[1], 0.55, land, land + float(wpc[2]), PP_BRONZE_DARK, M_STONE, PP_BRONZE)
	for r: Array in PP_RUBBLE:
		_lbox(r[0], r[1], r[2], r[3], land, land + float(r[4]), PP_BRONZE_DARK, M_STONE, PP_BRONZE)
	# the two tilted slabs: the short high one leaning west, the long one east, broad faces to the square
	var up := Vector3(_a.x, 0.0, _a.y)
	var front := Vector3(_b.x, 0.0, _b.y)
	var bl := _w(-4.2, -1.4)
	_pp_slab(Vector3(bl.x, land + 1.0, bl.y), (-up * 0.5 + front * 0.18 + Vector3.UP).normalized(), front, 9.0, 4.8, 1.2)
	var br := _w(4.4, -1.5)
	_pp_slab(Vector3(br.x, land + 1.2, br.y), (up * 0.46 + front * 0.15 + Vector3.UP).normalized(), front, 10.5, 5.6, 1.3)
	# the insurgents
	for f: Array in PP_FIGHTERS:
		_pp_fighter(_w(f[0], f[1]), _a * float(f[2]) + _b * float(f[3]), land, 2.3, int(f[4]))
	# up-lights at the front edge, warm on the bronze at night
	for u: float in [-5.0, 0.0, 5.0]:
		var keep := _mode
		_mode = M_LAMP
		_prism(_rect(u, 3.1, 0.18, 0.12), land, land + 0.16, PP_LAMP, PP_LAMP, M_LAMP, M_LAMP)
		_mode = keep
	# "Przejście kanałami": the low stone block, the manhole at its front, the priest, three soldiers
	var c := PP_KANALY
	var fwd := PP_KANALY_FWD.normalized()
	var side := Vector2(-fwd.y, fwd.x)
	var gk: float = map.terrain_height(c.x, c.y)
	var keep_o := _o
	var keep_a := _a
	var keep_b := _b
	_o = c
	_a = fwd
	_b = side
	_g = gk
	_lbox(0.0, 0.0, 3.4, 4.6, gk - 0.4, gk + 0.06, PP_SETTS, M_STONE, PP_SETTS)
	_lbox(-0.6, 0.0, 0.8, 1.4, gk + 0.06, gk + 0.8, PP_GRANITE_SHADE, M_STONE, PP_GRANITE)
	_mode = M_STONE
	_prism(_circle(_w(1.1, 0.4), 0.45, 8), gk + 0.06, gk + 0.12, PP_MANHOLE, PP_MANHOLE, M_STONE, M_STONE)
	# the broken stepped slab lying in the bed in front, the "sewer cover" debris
	_lbox(2.4, -2.2, 1.2, 0.8, gk + 0.06, gk + 0.38, PP_BRONZE, M_STONE, PP_BRONZE.lightened(0.08))
	_lbox(2.0, -2.0, 0.7, 0.5, gk + 0.38, gk + 0.62, PP_BRONZE, M_STONE, PP_BRONZE.lightened(0.08))
	_pp_priest(_w(-0.6, -0.9), fwd, gk + 0.8)
	_pp_fighter(_w(-0.4, 0.8), fwd, gk + 0.8, 2.3, 3)
	_pp_fighter(_w(0.5, -0.2), (fwd + side * 0.4).normalized(), gk + 0.06, 2.3, 1)
	_pp_fighter(_w(1.1, 0.4), fwd, gk - 0.75, 2.3, 4)
	_collide(_rect(0.0, 0.0, 1.6, 1.7))
	_o = keep_o
	_a = keep_a
	_b = keep_b


## A tilted granite slab: from `base` along `up` for `length`, `width` across (in the plane of
## up and the world's up), `thick` along `face` (its broad face's normal, roughly).
func _pp_slab(base: Vector3, up: Vector3, face: Vector3, length: float, width: float, thick: float) -> void:
	var t := (face - up * face.dot(up)).normalized()
	var s := up.cross(t).normalized()
	var hw := s * width * 0.5
	var ht := t * thick * 0.5
	var top := base + up * length
	var keep := _mode
	_mode = M_STONE
	var c := [base - hw - ht, base + hw - ht, base + hw + ht, base - hw + ht]
	var d := [top - hw - ht, top + hw - ht, top + hw + ht, top - hw + ht]
	var cols := [PP_GRANITE_SHADE, PP_GRANITE, PP_GRANITE, PP_GRANITE]
	for k in 4:
		var a0: Vector3 = c[k]
		var a1: Vector3 = c[(k + 1) % 4]
		var mid := (a0 + a1) * 0.5 - base
		_quad(a0, a1, d[(k + 1) % 4], d[k], mid.normalized(), cols[k])
	_quad(d[0], d[1], d[2], d[3], up, PP_GRANITE_TOP)
	_quad(c[0], c[1], c[2], c[3], -up, PP_GRANITE_SHADE)
	_mode = keep


## One bronze insurgent at `at` heading `fwd`, standing on y, `h` tall. Poses: 0 running, 1
## kneeling with a rifle, 2 running with a rifle raised, 3 bending down over the manhole,
## 4 half in the manhole (only the chest and arms show).
func _pp_fighter(at: Vector2, fwd: Vector2, y: float, h: float, pose: int) -> void:
	var keep_o := _o
	var keep_a := _a
	var keep_b := _b
	_o = at
	_a = fwd.normalized()
	_b = Vector2(-_a.y, _a.x)
	var k := h / 2.3
	var bz := PP_BRONZE
	var none := Color(0, 0, 0, 0)
	var p := func(u: float, v: float, yy: float) -> Vector3:
		var w := _w(u * k, v * k)
		return Vector3(w.x, y + yy * k, w.y)
	var hip: Vector3
	var sh: Vector3
	match pose:
		1:
			hip = p.call(0.0, 0.0, 0.62)
			sh = p.call(0.12, 0.0, 1.35)
			_beam(p.call(0.0, 0.16, 0.6), p.call(0.42, 0.16, 0.55), 0.2 * k, bz)    # thigh forward
			_beam(p.call(0.42, 0.16, 0.55), p.call(0.45, 0.16, 0.0), 0.18 * k, bz)  # shin down
			_beam(p.call(0.0, -0.16, 0.6), p.call(-0.1, -0.16, 0.08), 0.2 * k, bz)  # knee on the ground
			_beam(p.call(-0.1, -0.16, 0.08), p.call(-0.55, -0.16, 0.06), 0.16 * k, bz)
		3:
			hip = p.call(-0.2, 0.0, 1.0)
			sh = p.call(0.45, 0.0, 1.3)
			for sd: float in [1.0, -1.0]:
				_beam(p.call(-0.2, 0.15 * sd, 1.0), p.call(-0.25 + 0.15 * sd, 0.18 * sd, 0.0), 0.2 * k, bz)
		4:
			hip = p.call(0.0, 0.0, 0.5)
			sh = p.call(0.0, 0.0, 1.35)
		_:
			hip = p.call(0.1, 0.0, 1.02)
			sh = p.call(0.32, 0.0, 1.72)
			_beam(p.call(0.1, 0.14, 1.0), p.call(0.55, 0.15, 0.05), 0.2 * k, bz)    # front leg
			_beam(p.call(0.1, -0.14, 1.0), p.call(-0.45, -0.15, 0.18), 0.2 * k, bz) # back leg pushing off
			_beam(p.call(-0.45, -0.15, 0.18), p.call(-0.6, -0.15, 0.05), 0.14 * k, bz)
	# the quilted jacket: a thick torso from the hip to the shoulders
	_beam(hip, sh, 0.46 * k, bz)
	# the head and the helmet
	var head := sh + Vector3.UP * 0.2 * k + (sh - hip).normalized() * 0.05 * k
	var hp := Vector2(head.x, head.z)
	_mode = M_STONE
	_prism(_circle(hp, 0.11 * k, 6), head.y - 0.08 * k, head.y + 0.12 * k, bz.lightened(0.08), none, M_STONE)
	_prism(_circle(hp, 0.16 * k, 6), head.y + 0.08 * k, head.y + 0.2 * k, PP_BRONZE_DARK, PP_BRONZE_DARK, M_STONE, M_STONE)
	# the arms and what they hold
	var sl := sh + Vector3(_b.x, 0.0, _b.y) * 0.24 * k
	var sr := sh - Vector3(_b.x, 0.0, _b.y) * 0.24 * k
	var fw := Vector3(_a.x, 0.0, _a.y)
	match pose:
		1, 2:
			var butt := sh - Vector3(_b.x, 0.0, _b.y) * 0.08 * k + fw * 0.3 * k + Vector3.UP * (0.05 if pose == 1 else 0.25) * k
			var muzzle := butt + fw * 1.1 * k + Vector3.UP * (0.08 if pose == 1 else 0.55) * k
			_beam(sr, butt + fw * 0.35 * k, 0.11 * k, bz)
			_beam(sl, butt + fw * 0.65 * k + Vector3.UP * 0.05 * k, 0.11 * k, bz)
			_beam(butt, muzzle, 0.07 * k, PP_BRONZE_DARK)
		3, 4:
			for s: Vector3 in [sl, sr]:
				_beam(s, s + fw * 0.55 * k - Vector3.UP * 0.5 * k, 0.11 * k, bz)
		_:
			_beam(sl, sl + fw * 0.5 * k + Vector3.UP * 0.25 * k, 0.11 * k, bz)    # an arm flung forward
			_beam(sr, sr - fw * 0.35 * k - Vector3.UP * 0.4 * k, 0.11 * k, bz)    # the other swinging back
	_o = keep_o
	_a = keep_a
	_b = keep_b


## The priest of "Przejście kanałami": standing, bareheaded, in a long robe, hands joined.
func _pp_priest(at: Vector2, fwd: Vector2, y: float) -> void:
	var keep_o := _o
	var keep_a := _a
	var keep_b := _b
	_o = at
	_a = fwd.normalized()
	_b = Vector2(-_a.y, _a.x)
	var bz := PP_BRONZE
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 0.42, 0.5), y, _rect(0.0, 0.0, 0.26, 0.34), y + 1.75, bz, none)
	_frustum(_rect(0.0, 0.0, 0.26, 0.34), y + 1.75, _rect(0.0, 0.0, 0.2, 0.3), y + 2.15, bz, bz)
	_prism(_circle(_w(0.03, 0.0), 0.13, 6), y + 2.15, y + 2.45, bz.lightened(0.08), bz.lightened(0.05), M_STONE, M_STONE)
	var hands := _w(0.35, 0.0)
	for sd: float in [1.0, -1.0]:
		var s := _w(0.0, 0.3 * sd)
		_beam(Vector3(s.x, y + 2.05, s.y), Vector3(hands.x, y + 1.7, hands.y), 0.13, bz)
	_o = keep_o
	_a = keep_a
	_b = keep_b


## Pałac Krasińskich (Tylman van Gameren, 1677-1683; spec docs/landmarks/specs/krasinski.md, from
## the Mac's Commons photos and GUGiK ortho, 2026-11-02): the white baroque palace on the square,
## its long axis NNW-SSE, the street front to the ENE, the garden front to Ogród Krasińskich.
## Three storeys over a plinth under a balustrade with vases, a mint-green copper hip roof with
## dormers and chimneys, a central risalit on both fronts under a pediment full of relief with a
## statue on its apex and on its feet, four corner pavilions under pyramid roofs, the loggia arches
## of the street front's wings, the balcony porch over the main door.
## Frame (the OSM outline's minimum rectangle, 77.6 x 29.7 m): u along the axis to the SSE,
## +v to the garden (WSW), so the street front is at v = -13.8.
const KRAS := Vector2(-1374.23, -1687.33)
const KRAS_AXIS := Vector2(0.5592, 0.8290)
const KRAS_EAVES := 16.0       # LoD2: the walls' top ~16.5 m with the cornice
const KRAS_RISE := 5.2         # LoD2: the ridge ~21.5 m
const KRAS_WALL := Color("#e6e5e0")
const KRAS_TRIM := Color("#c3c5bc")
const KRAS_RELIEF := Color("#b9bbba")
const KRAS_ROOF := Color("#6ea58b")
const KRAS_LEAD := Color("#a0a7ac")
const KRAS_DARK := Color("#1d2a3a")
const KRAS_DOOR := Color("#5e432f")
const KRAS_STATUE := Color("#cfd0cb")
## The plan, in the frame above: the main block, the four corner pavilions, the two risalits:
## [cu, cv, hu, hv].
const KRAS_BODY := [0.0, -0.45, 34.3, 13.35]
const KRAS_PAVILIONS := [[-34.4, -10.2, 4.3, 4.1], [-34.4, 10.4, 4.3, 4.4], [34.4, -10.2, 4.3, 4.1], [34.4, 10.4, 4.3, 4.4]]
const KRAS_RISALITS := [[0.0, -13.9, 10.4, 0.9], [0.0, 13.6, 10.2, 0.8]]


func _find_krasinski() -> void:
	var outline := _landmark("Pałac Krasińskich")
	if outline.size() < 3:
		return
	_add_site("krasinski", [outline, Geometry2D.convex_hull(outline)])
	if not sites.is_empty() and sites[-1]["key"] == "krasinski":
		sites[-1]["ring"] = outline


func _build_krasinski(site: Dictionary) -> void:
	_o = KRAS
	_a = KRAS_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var plan: Array[PackedVector2Array] = [_rect(KRAS_BODY[0], KRAS_BODY[1], KRAS_BODY[2], KRAS_BODY[3])]
	for r: Array in KRAS_PAVILIONS + KRAS_RISALITS:
		plan.append(_rect(r[0], r[1], r[2], r[3]))
	var ring: PackedVector2Array = plan[0]
	for k in range(1, plan.size()):
		var merged := Geometry2D.merge_polygons(ring, plan[k])
		ring = _largest(merged)
	_g = _ground_under(ring)
	var g := _g
	var top := g + KRAS_EAVES
	var none := Color(0, 0, 0, 0)
	# the walls with the window rhythm, the plinth, the string course over the ground floor
	_prism(ring, g - 0.8, top, KRAS_WALL, none, M_MONUMENT, M_STONE)
	_kras_band(ring, 0.15, g - 0.8, g + 0.9, KRAS_TRIM.darkened(0.05), none)
	_kras_band(ring, 0.12, g + 5.0, g + 5.35, KRAS_TRIM, none)
	# the cornice (its top the lead walkway behind the balustrade) and the balustrade
	_kras_band(ring, 0.45, top, top + 0.5, KRAS_TRIM, KRAS_LEAD)
	var rail := Geometry2D.offset_polygon(ring, 0.3, Geometry2D.JOIN_MITER)
	if not rail.is_empty():
		_parapet(rail[0], top + 0.5, 0.85, KRAS_TRIM)
	# vases on the balustrade along both long fronts, one every ~3.3 m
	for v: float in [-14.4, 13.3]:
		var u := -32.0
		while u <= 32.01:
			if absf(u) > 11.5:
				_lbox(u, v + (-0.45 if v < 0.0 else 0.45), 0.22, 0.22, top + 1.35, top + 2.0, KRAS_TRIM.lightened(0.05), M_STONE, KRAS_TRIM)
			u += 3.3
	# the copper roof: the main hip over the block inside the walkways, pyramids on the pavilions
	_hip(0.0, -0.6, 34.0, 10.6, top + 0.5, KRAS_RISE, KRAS_ROOF)
	for pv: Array in KRAS_PAVILIONS:
		_mode = M_STONE
		_pyramid(_rect(pv[0], pv[1], float(pv[2]) - 0.2, float(pv[3]) - 0.2), top + 0.5, top + 0.5 + KRAS_RISE + 0.6, KRAS_ROOF.darkened(0.04))
	# dormers along both long slopes (dark louvres) and the white chimneys
	for side: float in [-1.0, 1.0]:
		for u: float in [-27.0, -20.0, -14.0, 14.0, 20.0, 27.0]:
			var dv := -0.6 + side * 8.0
			var y0 := top + 0.5 + KRAS_RISE * (2.6 / 10.6) - 0.3
			_lbox(u, dv, 0.65, 0.55, y0, y0 + 1.1, KRAS_ROOF.darkened(0.1), M_STONE, KRAS_ROOF.darkened(0.1))
			var face := _w(u, dv + side * 0.62)
			var e := _a * 0.45
			var n := _b * side
			_quad(Vector3(face.x - e.x, y0 + 0.25, face.y - e.y), Vector3(face.x + e.x, y0 + 0.25, face.y + e.y),
					Vector3(face.x + e.x, y0 + 0.95, face.y + e.y), Vector3(face.x - e.x, y0 + 0.95, face.y - e.y),
					Vector3(n.x, 0.0, n.y), KRAS_DARK)
		for u: float in [-24.0, -12.5, 12.5, 24.0]:
			var cv := -0.6 + side * 4.5
			_lbox(u, cv, 0.55, 0.55, top + 3.0, top + 5.6, Color("#e5e5e0"), M_STONE, KRAS_TRIM)
	# the pediments over both risalits, with the relief's recessed field and the statues
	for r: Array in KRAS_RISALITS:
		var out := signf(r[1])
		var face_v: float = float(r[1]) + out * float(r[3])
		_kras_pediment(face_v, out, float(r[2]) + 0.4, top + 0.5)
	# the street front: the loggia's round arches in the wings, the porch, the steps, the door
	for u: float in [-19.0, -16.0, -13.0, 13.0, 16.0, 19.0]:
		_kras_arch(u, -13.8, -1.0, g + 6.0, g + 9.6, 1.1)
	for u: float in [-19.0, -16.0, -13.0, 13.0, 16.0, 19.0]:
		_kras_arch(u, -13.8, -1.0, g + 1.0, g + 3.6, 0.9)
	_kras_arch(0.0, -14.8, -1.0, g + 6.2, g + 9.8, 1.0)
	_kras_door(0.0, -14.8, -1.0, g)
	for u: float in [-2.6, -1.3, 1.3, 2.6]:
		_column(u, -16.1, 0.28, g + 0.3, g + 5.0, KRAS_TRIM)
	_lbox(0.0, -15.75, 3.4, 0.95, g + 5.0, g + 5.45, KRAS_TRIM, M_STONE, KRAS_TRIM.lightened(0.05))
	_parapet(_rect(0.0, -15.75, 3.3, 0.85), g + 5.45, 0.8, KRAS_TRIM)
	for k in 3:
		_lbox(0.0, -16.9 - 0.4 * k, 4.2, 0.2 + 0.2 * k, g - 0.5, g + 0.3 - 0.1 * k, KRAS_TRIM, M_STONE, KRAS_TRIM.lightened(0.04))
	# the garden front: the garden door under a small balcony, the arches of the wings' ground floor
	_kras_door(0.0, 14.4, 1.0, g)
	_lbox(0.0, 15.0, 2.2, 0.6, g + 4.6, g + 5.0, KRAS_TRIM, M_STONE, KRAS_TRIM.lightened(0.05))
	_parapet(_rect(0.0, 15.0, 2.1, 0.5), g + 5.0, 0.75, KRAS_TRIM)
	for u: float in [13.5, 16.5, 19.5, 22.5, -13.5, -16.5, -19.5]:
		_kras_arch(u, 12.9, 1.0, g + 1.0, g + 3.6, 0.9)
	for k in 3:
		_lbox(0.0, 15.2 + 0.4 * k, 3.4, 0.2 + 0.2 * k, g - 0.5, g + 0.3 - 0.1 * k, KRAS_TRIM, M_STONE, KRAS_TRIM.lightened(0.04))
	_collide(site["ring"])


## A band round the ring grown `grow` m, from y0 to y1: a plinth, a string course, the cornice.
func _kras_band(ring: PackedVector2Array, grow: float, y0: float, y1: float, col: Color, cap: Color) -> void:
	var r := Geometry2D.offset_polygon(ring, grow, Geometry2D.JOIN_MITER)
	if not r.is_empty():
		_prism(r[0], y0, y1, col, cap, M_STONE, M_STONE)


## A pediment on the face v = `face_v` (outward sign `out`), `hw` wide each side of u = 0, from y:
## the triangle, its roof slopes back into the main roof, the recessed relief field, a statue on
## the apex and one on each foot.
func _kras_pediment(face_v: float, out: float, hw: float, y: float) -> void:
	var keep_a := _a
	var keep_b := _b
	# a frame turned so the pediment faces +u (as _gable wants): u' = out * v, v' = u
	_a = keep_b * out
	_b = keep_a
	var h := 5.4
	_gable(absf(face_v) + 0.45, absf(face_v) - 9.0, 0.0, hw, y, h, KRAS_TRIM, KRAS_ROOF, false)
	# the relief field: a darker triangle 0.12 m proud, inside the frame's mouldings
	var fu := absf(face_v) + 0.57
	var l := _w(fu, -hw + 1.2)
	var rr := _w(fu, hw - 1.2)
	var ap := _w(fu, 0.0)
	var keep := _mode
	_mode = M_STONE
	_tri(Vector3(l.x, y + 0.45, l.y), Vector3(rr.x, y + 0.45, rr.y), Vector3(ap.x, y + h - 0.85, ap.y),
			Vector3(_a.x, 0.0, _a.y), KRAS_RELIEF, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_mode = keep
	# the statues: the apex figure on a pedestal, a figure on each foot
	_kras_statue(absf(face_v) - 0.2, 0.0, y + h - 0.3, 3.6)
	for sd: float in [-1.0, 1.0]:
		_kras_statue(absf(face_v) - 0.1, sd * (hw - 0.6), y + 0.2, 2.5)
	_a = keep_a
	_b = keep_b


## A stone statue on a pedestal at (u, v), standing on y, `h` tall with the pedestal: one arm raised.
func _kras_statue(u: float, v: float, y: float, h: float) -> void:
	var col := KRAS_STATUE
	_lbox(u, v, 0.45, 0.45, y, y + h * 0.22, KRAS_TRIM, M_STONE, KRAS_TRIM.lightened(0.05))
	_mode = M_STONE
	_frustum(_rect(u, v, 0.32, 0.36), y + h * 0.22, _rect(u, v, 0.2, 0.25), y + h * 0.8, col, col)
	_prism(_circle(_w(u, v), 0.14, 6), y + h * 0.8, y + h * 0.92, col, col.lightened(0.05), M_STONE, M_STONE)
	var s := _w(u, v + 0.24)
	var hand := _w(u + 0.15, v + 0.4)
	_beam(Vector3(s.x, y + h * 0.76, s.y), Vector3(hand.x, y + h * 1.02, hand.y), 0.12, col)


## A round-headed opening drawn on the face v = `fv` (outward sign `out`): dark glass from y0 to
## the springing y1, a half disc of 6 pieces over it.
func _kras_arch(u: float, fv: float, out: float, y0: float, y1: float, hw: float) -> void:
	var v := fv + out * 0.06
	var n := Vector3(_b.x, 0.0, _b.y) * out
	var keep := _mode
	_mode = M_STONE
	var a := _w(u - hw, v)
	var b := _w(u + hw, v)
	_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), n, KRAS_DARK)
	var c := _w(u, v)
	var cc := Vector3(c.x, y1, c.y)
	for k in 6:
		var t0 := PI * k / 6.0
		var t1 := PI * (k + 1) / 6.0
		var p0 := _w(u + cos(t0) * hw, v)
		var p1 := _w(u + cos(t1) * hw, v)
		_tri(cc, Vector3(p0.x, y1 + sin(t0) * hw, p0.y), Vector3(p1.x, y1 + sin(t1) * hw, p1.y), n, KRAS_DARK,
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_mode = keep


## A carved double door in a stone portal on the face v = `fv`.
func _kras_door(u: float, fv: float, out: float, g: float) -> void:
	_lbox(u, fv + out * 0.1, 1.6, 0.1, g + 0.3, g + 4.6, KRAS_TRIM, M_STONE, KRAS_TRIM)
	var v := fv + out * 0.26
	var n := Vector3(_b.x, 0.0, _b.y) * out
	var a := _w(u - 1.1, v)
	var b := _w(u + 1.1, v)
	var keep := _mode
	_mode = M_STONE
	_quad(Vector3(a.x, g + 0.3, a.y), Vector3(b.x, g + 0.3, b.y), Vector3(b.x, g + 4.0, b.y), Vector3(a.x, g + 4.0, a.y), n, KRAS_DOOR)
	_mode = keep


# --- The monuments pass, part 2 (photo builds, 2026-11-02) ---------------------------------------

## Sąd Najwyższy's colonnade (Marek Budzyński and Zbigniew Badowski, 1999; spec
## docs/landmarks/specs/sad_najwyzszy.md, from the Mac's Plac Krasińskich photo reports, 2026-11-02).
## OpenStreetMap maps the court's columns as 2 m boxes 12 m tall under 2 m beams (12-14 m) in
## "marble #deeded", so they drew white; the photos show them green and ribbed, with dark metal
## lettering low on the shafts and relief rosettes in the capitals. The main block (LoD2, real roof)
## stays the map's: only the mapped colonnade is rebuilt, in its mapped plan and heights.
const SN_BOX := Rect2(-1345.0, -1790.0, 145.0, 100.0)
const SN_WEST_BEAM := Vector2(-1316.0, -1763.0)  # the north-west wing's beam, mapped without a colour
const SN_GREEN := Color("#738483")
const SN_RIB := Color("#83948f")
const SN_CAP := Color("#8b9b95")
const SN_ROSE := Color("#a9b5ab")
const SN_LETTERS := Color("#4f5c59")
const SN_BEAM := Color("#6f807e")
const SN_BEAM_TOP := Color("#5c6b69")


func _find_sad_najwyzszy() -> void:
	if _landmark("Sąd Najwyższy").size() < 3:
		return
	var parts := _parts_in(_box_poly(SN_BOX), func(b: Dictionary) -> bool:
			if str(b["c"]).to_lower() == "#deeded":
				return true
			return float(b["mh"]) >= 11.5 and _centre(_pts(b["p"])).distance_to(SN_WEST_BEAM) < 3.0)
	if parts.is_empty():
		return
	var zone: Array = []
	for b in parts:
		zone.append(_pts(b["p"]))
	_add_site("sad_najwyzszy", zone)
	if not sites.is_empty() and sites[-1]["key"] == "sad_najwyzszy":
		sites[-1]["parts"] = parts


func _build_sad_najwyzszy(site: Dictionary) -> void:
	var beams: Array[PackedVector2Array] = []
	var beam_y: Array[float] = []
	for b: Dictionary in site["parts"]:
		if float(b["mh"]) < 11.5:
			continue
		var poly := _pts(b["p"])
		_g = _ground_under(poly)
		var y0 := _g + float(b["mh"])
		_prism(poly, y0, _g + float(b["h"]), SN_BEAM, SN_BEAM_TOP, M_STONE, M_STONE)
		# the beam's soffit, seen from the steps
		var keep := _mode
		_mode = M_STONE
		_cap_piece(poly, y0 - 0.01, SN_BEAM.darkened(0.2))
		_mode = keep
		beams.append(poly)
		beam_y.append(y0)
	for b: Dictionary in site["parts"]:
		if float(b["mh"]) >= 11.5:
			continue
		var poly := _pts(b["p"])
		_g = _ground_under(poly)
		var top := _g + float(b["h"])
		var c := _centre(poly)
		for k in beams.size():
			if Geometry2D.is_point_in_polygon(c, beams[k]):
				top = beam_y[k]  # the shaft meets its beam whatever the ground does
				break
		_sn_column(poly, _g, top)
		_collide(poly)


## One column: a dark plinth, the band of lettering, the green shaft with its ribs, the wider
## capital with a rosette on every face.
func _sn_column(poly: PackedVector2Array, g: float, top: float) -> void:
	var none := Color(0, 0, 0, 0)
	var plinth := Geometry2D.offset_polygon(poly, 0.06, Geometry2D.JOIN_MITER)
	var cap := Geometry2D.offset_polygon(poly, 0.14, Geometry2D.JOIN_MITER)
	var band := Geometry2D.offset_polygon(poly, 0.015, Geometry2D.JOIN_MITER)
	var cap_y := top - 1.0
	_prism(plinth[0] if not plinth.is_empty() else poly, g - 0.3, g + 0.5, SN_LETTERS.darkened(0.2), SN_LETTERS, M_STONE, M_STONE)
	_prism(band[0] if not band.is_empty() else poly, g + 0.5, g + 3.0, SN_LETTERS, none, M_STONE)
	_prism(poly, g + 3.0, cap_y, SN_GREEN, none, M_STONE)
	_prism(cap[0] if not cap.is_empty() else poly, cap_y, top, SN_CAP, none, M_STONE)
	var keep := _mode
	_mode = M_STONE
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var length := a.distance_to(b)
		if length < 0.8:
			continue
		var d := (b - a) / length
		var out := _out(poly, a, b)
		# the ribs: two thin vertical fins on every face (front and sides, no tops: they end
		# under the capital and on the lettering band)
		var nrm := Vector3(out.x, 0.0, out.y)
		var side := Vector3(d.x, 0.0, d.y)
		for t: float in [length / 3.0, length * 2.0 / 3.0]:
			var m := a + d * t
			var l0 := m - d * 0.05
			var l1 := m + d * 0.05
			var f0 := l0 + out * 0.08
			var f1 := l1 + out * 0.08
			_quad(Vector3(f0.x, g + 3.0, f0.y), Vector3(f1.x, g + 3.0, f1.y), Vector3(f1.x, cap_y, f1.y), Vector3(f0.x, cap_y, f0.y), nrm, SN_RIB)
			_quad(Vector3(l0.x, g + 3.0, l0.y), Vector3(f0.x, g + 3.0, f0.y), Vector3(f0.x, cap_y, f0.y), Vector3(l0.x, cap_y, l0.y), -side, SN_RIB.darkened(0.08))
			_quad(Vector3(f1.x, g + 3.0, f1.y), Vector3(l1.x, g + 3.0, l1.y), Vector3(l1.x, cap_y, l1.y), Vector3(f1.x, cap_y, f1.y), side, SN_RIB.darkened(0.08))
		var mid := (a + b) * 0.5 + out * 0.2
		_disc(Vector3(mid.x, cap_y + 0.5, mid.y), nrm, minf(0.32, length * 0.2), 6, SN_ROSE)
	_mode = keep



## Three photo builds from the Mac gather (docs/landmarks/photo-reports/vitkac.md, jablkowskich.md,
## sheraton.md, CITY_INVENTORY 80-82). Each is built whole over its OpenStreetMap outline (the
## GUGiK LoD2 block and the mapped parts in the zone are dropped), colours and storeys from the
## photos, heights from the reports. The OSM outlines were trusted over the reports' ortho boxes
## where they disagree (Vitkac's ortho box sits ~20 m south of the outline, inside the error of the
## report's frame). Brands only as parodies: VIPKAC (a VIP's hangover), SZERATON.
## Specs docs/landmarks/specs/vitkac.md, jablkowscy.md, sheraton.md.


# --- The garden before Pałac Krasińskich (F's photos, 2026-11-06) ------------------------------

const KG_LAWN := Color("#7fbb6a")
const KG_GRAVEL := Color("#dccfb4")
const KG_FLOWER := Color("#8a4f9a")
const KG_RED := Color("#b23a52")
const KG_HEDGE := Color("#3f6b42")


## A flat bed in the garden frame: `h` metres over the highest ground under its edge and middle, so
## the slope of the lawn doesn't bury it.
func _kg_flat(poly: PackedVector2Array, h: float, col: Color, base := INF) -> float:
	var c := _centre(poly)
	var hi: float = map.terrain_height(c.x, c.y)
	for q in poly:
		hi = maxf(hi, map.terrain_height(q.x, q.y))
	if base != INF:
		hi = base
	_prism(poly, hi - 0.8, hi + h, col, col, M_STONE, M_STONE)
	return hi


## The formal garden on the palace's axis, from the aerial photos: the flower ring round the two
## fountains, then a cross of lawn on gravel with flowers in its corners, and hedged lawn panels.
func _build_kras_garden() -> void:
	_o = KRAS
	_a = KRAS_AXIS
	_b = Vector2(-_a.y, _a.x)
	var ring := _kg_flat(_circle(_w(0.0, 42.0), 13.0, 28), 0.04, KG_FLOWER)
	_kg_flat(_circle(_w(0.0, 42.0), 10.5, 28), 0.08, KG_LAWN, ring)
	var cross := _kg_flat(_circle(_w(0.0, 86.0), 16.0, 12), 0.12, KG_GRAVEL)
	_kg_flat(_rect(0.0, 86.0, 13.5, 3.0), 0.2, KG_LAWN, cross)
	_kg_flat(_rect(0.0, 86.0, 3.0, 13.5), 0.2, KG_LAWN, cross)
	for su: float in [-1.0, 1.0]:
		for sv: float in [-1.0, 1.0]:
			_kg_flat(_rect(su * 7.5, 86.0 + sv * 7.5, 3.0, 3.0), 0.2, KG_RED if su == sv else KG_FLOWER, cross)
			_pinnacle(su * 4.2, 86.0 + sv * 4.2, 1.1, cross + 0.15, 2.6, KG_HEDGE)
	for v: float in [60.0, 112.0]:  # the lawn panels, hedge all round
		_kg_flat(_rect(0.0, v, 9.0, 6.0), 0.14, KG_LAWN)
		_kg_flat(_rect(0.0, v - 6.0, 9.0, 0.4), 0.6, KG_HEDGE)
		_kg_flat(_rect(0.0, v + 6.0, 9.0, 0.4), 0.6, KG_HEDGE)
		_kg_flat(_rect(-9.0, v, 0.4, 6.0), 0.6, KG_HEDGE)
		_kg_flat(_rect(9.0, v, 0.4, 6.0), 0.6, KG_HEDGE)
