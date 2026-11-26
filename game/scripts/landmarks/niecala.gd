extends "res://scripts/landmarks/mirek.gd"
## Rezydencja Opera, Niecała 7 (F, 2026-11-26: "model Niecała 7 and the houses round it"; spec
## docs/landmarks/specs/niecala7.md). Dom Development's luxury block of 2003-05 on the east side of
## Niecała, behind Ogród Saski: a pre-war-tenement pastiche by Kaliszewski and Napieralski, eight
## storeys of cream plaster on a honey-sandstone base, with a stack of round balconies on iron
## brackets up the curved garden face and the street corner, a zinc mansard and, over the garden's
## arc, a pergola on slim white columns. One link of landmarks.gd's base chain (TD-10): it uses
## this file, common.gd and the facade kit, never another area. The houses round it (Niecała 5, 8,
## 9, 10, 12) are not here: they are rows of game/data/photo_fronts.json (fronts.gd).
##
## The plan is OpenStreetMap's outline simplified to 23 corners (N7_RING, from centrum.json building
## 5544, so the site stands on the mapped footprint). Its edges, by index: 17..22 the street front on
## Niecała (west), 16 the blank south-west gable, 0 and 1..7 the north-east end and the back (party
## walls, plain), 8..11 the concave garden arc and 12..15 the south face. The round balconies stand in
## stacks with plain windows between (Nemo5576's photo from the south: stack, windows, stack ...),
## so only every other edge of the arc carries one (N7_BALCONY_EDGES); the Mac look check of
## 2026-11-26 found a stack on every edge read as one dark wall of glass.

const N7_AT := Vector2(-1043.0, -892.0)
const N7_RING: Array[float] = [-1039.7, -916.2, -1029.7, -906.9, -1034.2, -901.2, -1019.1, -889.5, -1017.8, -892.9,
		-1016.7, -892.6, -1020.0, -883.1, -1023.4, -870.4, -1027.7, -869.2, -1029.5, -873.7, -1033.1, -878.3,
		-1037.9, -881.4, -1043.6, -882.9, -1043.4, -884.7, -1047.4, -884.7, -1051.6, -883.7, -1052.7, -883.3,
		-1060.0, -890.0, -1056.0, -895.1, -1052.4, -897.5, -1049.0, -901.1, -1046.0, -905.6, -1044.3, -910.3]
const N7_FRONT_EDGES: Array[int] = [17, 18, 19, 20, 21, 22]
const N7_GABLE_EDGE := 16
const N7_BALCONY_EDGES: Array[int] = [8, 9, 10, 11, 14, 17, 22]
const N7_ENTRANCE_EDGE := 20
const N7_BASE := 5.0          # the sandstone base's height over the ground
const N7_FLOOR := 3.2         # a storey of the cream plaster
const N7_FLOORS := 6          # storeys on the base (floors 2 to 7)
const N7_ROOF_STOREY := 3.2   # the zinc storey and the pergola's terrace under it
const N7_SETBACK := 1.9       # the top storey stands this far in from the plaster
const N7_CREAM := Color("#eadfc5")
const N7_CREAM_L := Color("#f2ead6")
const N7_SAND := Color("#c9a56c")
const N7_SAND_L := Color("#dcc08a")
const N7_ZINC := Color("#656d74")
const N7_ZINC_ROOF := Color("#7c8388")
const N7_RAIL := Color("#76828d")   # the pergola's iron rail
const N7_BRAIL := Color("#c4c9cd")  # the balconies' rails read grey-white on F's photos
const N7_WOOD := Color("#9a6a3c")
const N7_GLASS := Color("#2c3640")
const N7_DECK := Color("#b9b7b1")
const N7_IVY := Color("#3e5a2b")
const N7_IVY_L := Color("#56773a")
const N7_GERANIUM := Color("#c8323a")
const N7_BOWL := Color("#e2d3b2")   # the balconies' cream-sandstone bowls


func _find_niecala7() -> void:
	var q := _tallest_at(N7_AT)
	if q.size() < 40:
		return
	_add_site("niecala7", [_largest(Geometry2D.offset_polygon(q, 1.0, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "niecala7":
		sites[-1]["ring"] = _n7_ring()
		sites[-1]["raw"] = sites[-1]["ring"]


func _n7_ring() -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, N7_RING.size() - 1, 2):
		out.append(Vector2(N7_RING[i], N7_RING[i + 1]))
	return out


## Starts the front of ring edge `i` with its outside on +v (u runs the way that makes it so);
## returns the edge's length.
func _n7_front(ring: PackedVector2Array, i: int) -> float:
	var a := ring[i]
	var b := ring[(i + 1) % ring.size()]
	var e := (b - a).normalized()
	var left := Vector2(-e.y, e.x)
	if _out(ring, a, b).dot(left) >= 0.0:
		return kit_front(a, b)
	return kit_front(b, a)


func _build_niecala7(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	var g := _ground_under(ring)
	_g = g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	var y_plaster := g + N7_BASE
	var y_eave := y_plaster + N7_FLOOR * float(N7_FLOORS)
	var y_top := y_eave + N7_ROOF_STOREY
	# The mass: the honey-sandstone base, the cream plaster over it, the terrace deck at the eave.
	_prism(ring, g - 0.8, y_plaster, N7_SAND, none, M_STONE, M_STONE)
	_prism(ring, y_plaster, y_eave, N7_CREAM, none, M_STONE, M_STONE)
	kit_ledge_ring(ring, y_plaster, 0.4, N7_SAND_L, 0.22)
	kit_cornice_ring(ring, y_eave, N7_CREAM_L, 0.4, 0.45)
	_cap(ring, y_eave + 0.4, N7_DECK)
	# The zinc storey, set back all round; its flat roof and the chimneys.
	var top := _largest(Geometry2D.offset_polygon(ring, -N7_SETBACK, Geometry2D.JOIN_MITER))
	if top.size() >= 3:
		_prism(top, y_eave + 0.4, y_top, N7_ZINC, N7_ZINC_ROOF, M_STONE, M_STONE)
		_n7_chimneys(top, y_top)
	_n7_gable(ring, y_eave, y_top)
	for i in ring.size():
		_n7_edge(ring, i, g, y_plaster, y_eave)
	_collide(ring)
	pocket_rings.append(ring)


## One edge of the plan: what it carries by its index (the class comment above).
func _n7_edge(ring: PackedVector2Array, i: int, g: float, y_plaster: float, y_eave: float) -> void:
	var le := _n7_front(ring, i)
	if le < 3.0:
		return
	var front := N7_FRONT_EDGES.has(i)
	var balcony := N7_BALCONY_EDGES.has(i)
	var windowed := front or balcony or (i >= 8 and i <= 15)
	if i == N7_GABLE_EDGE or not windowed:
		return
	# Storeys 2 to 7: a window between the balcony columns, or a grid of them on a plain stretch.
	var sills: Array = []
	for k in N7_FLOORS:
		sills.append(y_plaster + 0.95 + N7_FLOOR * float(k))
	var nb := maxi(1, roundi(le / 4.2)) if balcony else 0
	if balcony:
		for j in range(1, nb):
			var u := le * float(j) / float(nb)
			for y: float in sills:
				kit_window(u, y, 1.7, Win.SILL_HEAD, N7_SAND_L, N7_GLASS, 0.55)
		var hw := minf(1.45, le / float(nb) * 0.34)
		if nb == 1 and le - 2.0 * hw >= 2.4:
			# A lone stack: a window beside it (one side on the arc, so stacks and windows
			# alternate round it as on F's garden photo; both sides elsewhere).
			var side := (le * 0.5 - hw) * 0.5
			var us: Array = [le - side] if i >= 8 and i <= 11 else [side, le - side]
			for u: float in us:
				for y: float in sills:
					kit_window(u, y, 1.7, Win.SILL_HEAD, N7_SAND_L, N7_GLASS, 0.5)
		for j in nb:
			var uc := le * (float(j) + 0.5) / float(nb)
			for y: float in sills:
				# The balcony door behind: tall glass, then the round slab and its iron rail.
				kit_window(uc, y - 0.05, 2.1, Win.PLAIN, N7_SAND_L, N7_GLASS, hw * 0.5)
				kit_balcony(uc, y, hw, Balcony.ROUND, N7_BRAIL, N7_BOWL, 1.9)
			_n7_stack_posts(uc, hw, sills)
			_n7_flowers(uc, hw, sills, i * 7 + j)
			if i >= 8 and i <= 14:
				_n7_ivy(uc, hw, sills, i * 3 + j)
	else:
		var bays := maxi(1, roundi(le / 2.9))
		kit_window_grid(0.0, le, bays, sills, 1.7, Win.SILL_HEAD, N7_SAND_L, N7_GLASS, 0.55)
	# The ground floor: dark shop glass between sandstone piers; the hall on the entrance edge.
	if front:
		var gb := maxi(1, roundi(le / 2.6))
		for u: float in _spread(0.0, le, gb):
			kit_shop_bay(u, g + 0.5, g + 4.2, 0.85, N7_SAND_L, N7_GLASS)
		if i == N7_ENTRANCE_EDGE:
			_n7_entrance(le, g)
	else:
		var gb := maxi(1, roundi(le / 3.2))
		for u: float in _spread(0.0, le, gb):
			kit_window(u, g + 1.0, 2.6, Win.SILL, N7_SAND_L, N7_GLASS, 0.8)
	# The pergola and its columns over the garden's arc.
	if i >= 8 and i <= 11:
		_n7_pergola(le, y_eave + 0.4, y_eave + 0.4 + N7_ROOF_STOREY)


## The slim columns either side of each balcony door, from one bowl's rim up under the next, and over
## the top balcony the iron half-hoop (F's garden photos). The hoop is drawn as short boxes round
## the arc: at the game's distance they read as one bent bar.
func _n7_stack_posts(uc: float, hw: float, sills: Array) -> void:
	var v := _face + 0.32
	for k in sills.size():
		var y: float = sills[k]
		var top := y + 2.35 if k == sills.size() - 1 else float(sills[k + 1]) - 0.8
		for s: float in [-1.0, 1.0]:
			_lbox(uc + s * hw * 0.62, v, 0.07, 0.07, y - 0.06, top, N7_CREAM_L)
	var yt: float = sills[-1] + 0.9
	var r := hw * 0.92
	var vh := _face + 0.9
	var prev := Vector2(uc - r, yt)
	for t in range(1, 8):
		var ang := PI * float(t) / 7.0
		var p := Vector2(uc - cos(ang) * r, yt + sin(ang) * r * 1.1)
		_lbox((prev.x + p.x) * 0.5, vh, maxf(absf(p.x - prev.x) * 0.5, 0.035), 0.035,
				minf(prev.y, p.y) - 0.035, maxf(prev.y, p.y) + 0.035, N7_BRAIL)
		prev = p


## Window boxes of red geraniums on the balcony rails (F's photos): a green band and a red one round
## the rail's curve, on about half the balconies of a stack, picked by `seed` so stacks differ.
func _n7_flowers(uc: float, hw: float, sills: Array, seed: int) -> void:
	var c := _w(uc, _face)
	var keep := _mode
	_mode = M_STONE
	for k in sills.size():
		if (seed + k * 5) % 3 == 0:
			continue
		var y: float = sills[k]
		var ring := PackedVector2Array()
		for t in 7:
			var ang := PI * float(t) / 6.0
			ring.append(_w(uc - cos(ang) * (hw + 0.06), _face + 0.03 + sin(ang) * 1.96))
		for t in 6:
			var a := ring[t]
			var b := ring[t + 1]
			var out := ((a + b) * 0.5 - c).normalized()
			_wall(a, b, y + 0.6, y + 0.74, out, N7_IVY_L)
			_wall(a, b, y + 0.74, y + 0.9, out, N7_GERANIUM)
	_mode = keep


## Ivy climbing the plaster beside a balcony stack (F's photos of the garden arc): ragged green
## panels just proud of the wall, each storey a different width, to a height that differs by stack.
func _n7_ivy(uc: float, hw: float, sills: Array, seed: int) -> void:
	var widths: Array[float] = [1.1, 1.5, 0.9, 1.3, 1.7, 1.0]
	var top := 3 + seed % 4
	for side: float in [-1.0, 1.0]:
		var reach := top if side > 0.0 else maxi(2, top - 1 - seed % 2)
		for k in mini(reach, sills.size()):
			var y: float = sills[k]
			var w: float = widths[(seed + k * 2 + (1 if side > 0.0 else 0)) % widths.size()]
			var u := uc + side * (hw * 0.55 + w * 0.5)
			var col := N7_IVY if (k + seed) % 2 == 0 else N7_IVY_L
			var y0 := _g + 0.3 if k == 0 else y - 1.1
			_lbox(u, _face + 0.1, w * 0.5, 0.06, y0, y + 2.1, col)


## The entrance hall on the street front: two stone columns, a dark wood door and the glass canopy.
func _n7_entrance(le: float, g: float) -> void:
	var mid := le * 0.5
	kit_door(mid, g + 0.1, 3.6, 1.1, N7_SAND_L, N7_WOOD, false)
	for s: float in [-1.0, 1.0]:
		kit_column(mid + s * 2.1, 1.7, g, g + N7_BASE - 0.4, N7_SAND_L, 0.42)
	var canopy := PackedVector2Array()
	for t in 9:
		var ang := PI * float(t) / 8.0
		canopy.append(_w(mid - cos(ang) * 2.6, 0.1 + sin(ang) * 2.2))
	_prism(canopy, g + 3.9, g + 4.05, N7_GLASS, Color("#5b6c78"), M_STONE, M_STONE)
	_soffit(canopy, g + 3.9, N7_GLASS)


## The pergola on the garden's arc: slim white columns on the deck, an iron rail between them, and
## timber slats across the top running back over the setback.
func _n7_pergola(le: float, y0: float, y1: float) -> void:
	kit_face(-0.35)
	var n := maxi(2, roundi(le / 1.9) + 1)
	kit_colonnade(0.25, le - 0.25, n, 0.0, y0, y1 - 0.15, N7_CREAM_L, 0.14)
	kit_attic(0.0, le, y0, N7_RAIL, 0.95, Attic.WALL)
	kit_face(0.0)
	var slats := maxi(2, roundi(le / 0.9))
	for u: float in _spread(0.1, le - 0.1, slats):
		_lbox(u, -0.6, 0.05, 0.95, y1 - 0.15, y1 - 0.02, N7_WOOD)
	_lbox(le * 0.5, -0.35, le * 0.5, 0.08, y1 - 0.02, y1 + 0.1, N7_CREAM_L)


## The blank south-west gable: a firewall that rises past the set-back zinc storey to a coping over
## it (Nemo5576's photo), instead of stepping back with the roof.
func _n7_gable(ring: PackedVector2Array, y_eave: float, y_top: float) -> void:
	var a := ring[N7_GABLE_EDGE]
	var b := ring[(N7_GABLE_EDGE + 1) % ring.size()]
	var d := -_out(ring, a, b) * (N7_SETBACK + 0.45)
	var slab := PackedVector2Array([a, b, b + d, a + d])
	_prism(slab, y_eave + 0.4, y_top + 0.9, N7_CREAM, N7_ZINC_ROOF, M_STONE, M_STONE)


## Three chimney stacks over the zinc roof, kept inside it.
func _n7_chimneys(top: PackedVector2Array, y: float) -> void:
	var c := _centre(top)
	for d: Vector2 in [Vector2(-6.0, -2.0), Vector2(2.5, -6.0), Vector2(7.0, 3.0)]:
		var p := c + d
		if Geometry2D.is_point_in_polygon(p, top):
			_prism(_circle(p, 0.55, 4), y, y + 2.0, N7_CREAM_L, N7_ZINC, M_STONE, M_STONE)
