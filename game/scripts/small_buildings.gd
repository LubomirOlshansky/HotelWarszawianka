## Small buildings drawn as what they are (F, 2026-11-07: "classify them and rebuild them as
## what they really are"). OpenStreetMap gives a metro lift, a kiosk or a bin shelter only an
## outline; with no height the bake stood each up as a 14 m windowed block. Each one was
## researched (its tags, the map points inside it, the aerial photo, Mapillary street photos:
## game/data/small_buildings.json) and the bake writes its use into the building as `u`
## (tools/building_heights.py). map_builder.gd hands such a building here instead of drawing a
## block: a glass lift with a roof slab, a kiosk with a lit window band and a sign strip, a
## louvred metro vent, a substation, a slatted bin shelter, a booth, a canopy on posts, a boat.
## Everything goes into the buildings' own surface (no new draw call), coloured and moded through
## the building shader's landmark material codes (UV2.x: 3 plain stone, 8 lit glass, 12 glass).

const M_STONE := 3.0
const M_PAVILION := 8.0
const M_GLASS := 12.0

## [walls colour, roof colour, height m] per use; height is the default when the research
## gave none.
const LOOK := {
	"lift": [Color(0.55, 0.66, 0.70), Color(0.30, 0.32, 0.35), 3.6],
	"metro_vent": [Color(0.62, 0.62, 0.60), Color(0.40, 0.41, 0.42), 4.0],
	"metro_vent_tower": [Color(0.50, 0.36, 0.26), Color(0.30, 0.26, 0.24), 5.5],
	"metro_entrance_roof": [Color(0.70, 0.72, 0.74), Color(0.36, 0.38, 0.42), 3.2],
	"kiosk": [Color(0.86, 0.84, 0.78), Color(0.32, 0.34, 0.38), 2.8],
	"pavilion": [Color(0.80, 0.80, 0.78), Color(0.34, 0.35, 0.38), 3.6],
	"bin_shelter": [Color(0.33, 0.40, 0.33), Color(0.28, 0.30, 0.30), 2.0],
	"substation": [Color(0.78, 0.74, 0.64), Color(0.42, 0.40, 0.38), 2.7],
	"toilet": [Color(0.42, 0.50, 0.46), Color(0.30, 0.32, 0.32), 2.8],
	"guard_booth": [Color(0.80, 0.80, 0.80), Color(0.34, 0.35, 0.38), 2.6],
	"ticket_booth": [Color(0.80, 0.80, 0.80), Color(0.34, 0.35, 0.38), 2.6],
	"garage": [Color(0.62, 0.62, 0.60), Color(0.36, 0.36, 0.38), 2.5],
	"shed": [Color(0.58, 0.54, 0.48), Color(0.34, 0.32, 0.30), 2.6],
	"canopy": [Color(0.40, 0.42, 0.45), Color(0.40, 0.42, 0.45), 3.0],
	"bus_tram_shelter": [Color(0.40, 0.42, 0.45), Color(0.40, 0.42, 0.45), 2.6],
	"houseboat": [Color(0.92, 0.92, 0.90), Color(0.30, 0.30, 0.32), 3.2],
	"boathouse": [Color(0.55, 0.42, 0.30), Color(0.32, 0.30, 0.30), 4.2],
	"chapel_shrine": [Color(0.88, 0.86, 0.80), Color(0.45, 0.30, 0.25), 3.5],
	"monument_structure": [Color(0.70, 0.68, 0.64), Color(0.60, 0.58, 0.55), 3.0],
	"staircase_or_lift_head": [Color(0.66, 0.66, 0.64), Color(0.34, 0.35, 0.38), 3.2],
	"historic": [Color(0.80, 0.74, 0.62), Color(0.45, 0.32, 0.26), 4.0],
	"unknown": [Color(0.62, 0.60, 0.56), Color(0.36, 0.36, 0.38), 2.8],
}
## Uses drawn as a roof on posts (no walls the car hits).
const OPEN := ["canopy", "bus_tram_shelter", "metro_entrance_roof"]


## Whether `use` is one this file draws (map_builder.gd skips the block for it).
static func draws(use: String) -> bool:
	return LOOK.has(use)


## Whether the car hits walls here (canopies only have posts).
static func solid(use: String) -> bool:
	return not OPEN.has(use)


## Builds the use's model on the footprint `poly` standing on `ground`, `h` metres tall (the
## researched height), into the map builder's buildings surface `st`. `hsh` varies colours.
static func build(mb, st, use: String, poly: PackedVector2Array, ground: float, h: float, hsh: int) -> void:
	var look: Array = LOOK.get(use, LOOK["unknown"])
	var wall: Color = look[0]
	var roof: Color = look[1]
	var jitter := 0.94 + 0.12 * fposmod(hsh * 0.6180339887, 1.0)
	wall = Color(wall.r * jitter, wall.g * jitter, wall.b * jitter)
	if h <= 0.5:
		h = float(look[2])
	var saved: Vector2 = mb._uv2
	match use:
		"lift", "guard_booth", "ticket_booth", "staircase_or_lift_head":
			# A glazed box on a thin plinth under an overhanging slab (the metro lifts' glass shafts).
			_prism(mb, st, poly, ground - 0.4, ground + 0.3, Color(0.42, 0.43, 0.45), M_STONE, h)
			_prism(mb, st, poly, ground + 0.3, ground + h - 0.35, wall, M_GLASS, h)
			_slab(mb, st, poly, 0.25, ground + h - 0.35, ground + h, roof)
		"kiosk", "pavilion":
			# A low solid base, a lit window band all round, a sign strip, a thin roof lip.
			var sill := 0.9 if use == "kiosk" else 0.4
			var sign := 0.5
			_prism(mb, st, poly, ground - 0.4, ground + sill, wall, M_STONE, h)
			_prism(mb, st, poly, ground + sill, ground + h - sign, Color(0.50, 0.56, 0.58), M_PAVILION, h)
			var tone := Color.from_hsv(fposmod(hsh * 0.137, 1.0), 0.55, 0.75)
			_prism(mb, st, poly, ground + h - sign, ground + h, tone, M_STONE, h)
			_slab(mb, st, poly, 0.3, ground + h, ground + h + 0.12, roof)
		"metro_vent":
			# Line 2's vent boxes: stone-clad walls with a dark grille band under a thin cap.
			_prism(mb, st, poly, ground - 0.4, ground + h - 1.3, wall, M_STONE, h)
			_bands(mb, st, poly, ground + h - 1.3, ground + h - 0.25, wall.darkened(0.45), wall.darkened(0.2), 0.16, h)
			_slab(mb, st, poly, 0.08, ground + h - 0.25, ground + h, roof)
		"metro_vent_tower":
			# The louvred vent towers (the round slatted ones by Stadion Narodowy): slats all the way up.
			_prism(mb, st, poly, ground - 0.4, ground + 0.4, wall.darkened(0.3), M_STONE, h)
			_bands(mb, st, poly, ground + 0.4, ground + h - 0.2, wall, wall.darkened(0.35), 0.22, h)
			_slab(mb, st, poly, 0.05, ground + h - 0.2, ground + h, roof)
		"bin_shelter":
			# Slatted walls (alternating bands) under a flat roof.
			_bands(mb, st, poly, ground - 0.4, ground + h - 0.2, wall.darkened(0.2), wall, 0.25, h)
			_slab(mb, st, poly, 0.2, ground + h - 0.2, ground + h, roof)
		"canopy", "bus_tram_shelter", "metro_entrance_roof":
			_posts(mb, st, poly, ground, ground + h - 0.2, Color(0.30, 0.31, 0.33))
			_slab(mb, st, poly, 0.1, ground + h - 0.2, ground + h, roof)
		"houseboat":
			# A dark hull and a white cabin set in from it.
			_prism(mb, st, poly, ground - 0.6, ground + 1.0, Color(0.22, 0.26, 0.32), M_STONE, h)
			var cabin := _inset(poly, 0.6)
			_prism(mb, st, cabin, ground + 1.0, ground + h - 0.15, wall, M_PAVILION, h)
			_slab(mb, st, cabin, 0.15, ground + h - 0.15, ground + h, roof)
		"chapel_shrine":
			_prism(mb, st, poly, ground - 0.4, ground + h * 0.65, wall, M_STONE, h)
			_pyramid(mb, st, poly, ground + h * 0.65, ground + h, roof)
		_:
			# Garages, sheds, substations, toilets, boathouses, historic bits, the unknown ones:
			# plain walls with a darker base and an overhanging roof slab.
			_prism(mb, st, poly, ground - 0.4, ground + 0.35, wall.darkened(0.2), M_STONE, h)
			_prism(mb, st, poly, ground + 0.35, ground + h - 0.2, wall, M_STONE, h)
			_slab(mb, st, poly, 0.15, ground + h - 0.2, ground + h, roof)
	mb._uv2 = saved


## Walls of `poly` from y0 to y1 in one material (UV = metres along / up, UV2 = (mode, top)).
static func _prism(mb, st, poly: PackedVector2Array, y0: float, y1: float, col: Color, mode: float, top: float) -> void:
	if y1 <= y0 + 0.01 or poly.size() < 3:
		return
	mb._uv2 = Vector2(mode, top)
	var run := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var e := b - a
		var length := e.length()
		if length < 0.05:
			continue
		var n := Vector3(e.y, 0.0, -e.x).normalized()
		mb._tri(st, Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), n, col,
				Vector2(run, y0), Vector2(run + length, y0), Vector2(run + length, y1))
		mb._tri(st, Vector3(a.x, y0, a.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), n, col,
				Vector2(run, y0), Vector2(run + length, y1), Vector2(run, y1))
		run += length


## Horizontal bands of two colours from y0 to y1, `step` metres each (slats, louvres, grilles).
static func _bands(mb, st, poly: PackedVector2Array, y0: float, y1: float, a: Color, b: Color, step: float, top: float) -> void:
	var y := y0
	var k := 0
	while y < y1 - 0.01:
		_prism(mb, st, poly, y, minf(y + step, y1), a if k % 2 == 0 else b, M_STONE, top)
		y += step
		k += 1


## A roof slab over `poly` grown by `over` metres, from y0 to y1 (edges and top).
static func _slab(mb, st, poly: PackedVector2Array, over: float, y0: float, y1: float, col: Color) -> void:
	var grown := _inset(poly, -over)
	_prism(mb, st, grown, y0, y1, col.lightened(0.08), M_STONE, y1)
	mb._uv2 = Vector2(M_STONE, -1.0)
	mb._fill(st, grown, y1, col)
	# The underside, seen from below the overhang.
	var idx := Geometry2D.triangulate_polygon(grown)
	for i in range(0, idx.size(), 3):
		var a := grown[idx[i]]
		var b := grown[idx[i + 1]]
		var c := grown[idx[i + 2]]
		mb._tri(st, Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(c.x, y0, c.y), Vector3.DOWN, col.darkened(0.3))


## Thin posts at the footprint's corners (at most 8; a long outline gets them every ~4 m).
static func _posts(mb, st, poly: PackedVector2Array, y0: float, y1: float, col: Color) -> void:
	var spots := PackedVector2Array()
	var inner := _inset(poly, 0.25)
	for i in inner.size():
		var a := inner[i]
		var b := inner[(i + 1) % inner.size()]
		spots.append(a)
		var steps := int(a.distance_to(b) / 4.0)
		for k in range(1, steps):
			spots.append(a.lerp(b, float(k) / steps))
		if spots.size() > 16:
			break
	mb._uv2 = Vector2(M_STONE, y1)
	for p in spots:
		mb._box(st, Vector3(p.x, (y0 + y1) * 0.5 - 0.2, p.y), Vector3(0.12, y1 - y0 + 0.4, 0.12), col)


## A pyramid roof over `poly` from its eave y0 to an apex y1.
static func _pyramid(mb, st, poly: PackedVector2Array, y0: float, y1: float, col: Color) -> void:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= poly.size()
	var grown := _inset(poly, -0.2)
	mb._uv2 = Vector2(M_STONE, -1.0)
	var apex := Vector3(c.x, y1, c.y)
	for i in grown.size():
		var a := grown[i]
		var b := grown[(i + 1) % grown.size()]
		var pa := Vector3(a.x, y0, a.y)
		var pb := Vector3(b.x, y0, b.y)
		var n := (pb - pa).cross(apex - pa).normalized()
		if n.y < 0.0:
			n = -n
		mb._tri(st, pa, pb, apex, n, col)


## `poly` moved in by `d` metres (out for a negative d); the polygon itself when that fails.
static func _inset(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := Geometry2D.offset_polygon(poly, -d, Geometry2D.JOIN_MITER)
	if out.is_empty() or (out[0] as PackedVector2Array).size() < 3:
		return poly
	var best: PackedVector2Array = out[0]
	if not Geometry2D.is_polygon_clockwise(poly) == Geometry2D.is_polygon_clockwise(best):
		best.reverse()
	return best
