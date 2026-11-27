extends "res://scripts/landmarks/powisle.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, Wola: 19. Dzielnica, Asbud's
## towers, Stacja Muzeum and Nocny Targ, Kolejowa, the Rising Museum, the market halls, Osiedle Za
## Żelazną Bramą. Moved as it was from the one big file. landmarks.gd is the class the game makes;
## every file of game/scripts/landmarks/ is one link of its base chain (facade_kit.gd, common.gd,
## then the areas in the order of landmarks.gd's `extends` chain), so code here may use this file,
## common.gd and the facade kit, never another area: a helper two areas need goes to common.gd.


# --- Unique Tower, Grzybowska 51 --------------------------------------------------------------

## Two unnamed footprints share a podium. The north outline also contains the main tower's shoulder.
const UNIQUE_NORTH_AT := Vector2(-2337.0, 25.0)
const UNIQUE_SOUTH_AT := Vector2(-2322.0, 76.0)
const UNIQUE_ORIGIN := Vector2(-2358.5, 5.3)
const UNIQUE_AXIS := Vector2(0.96, -0.28)
const UNIQUE_PODIUM_TOP := 17.2
const UNIQUE_SHOULDER_TOP := 55.6
const UNIQUE_SOUTH_TOP := 57.4
const UNIQUE_TOWER_TOP := 91.3
## Daylight photos show off-white slab edges, blue glass and champagne metal against charcoal.
const UNIQUE_WHITE := Color("#f2f2ed")
const UNIQUE_BODY := Color("#393e45")
const UNIQUE_BRONZE := Color("#b7a080")
const UNIQUE_GLASS := Color("#62798b")
const UNIQUE_GUARD := Color("#536979")
const UNIQUE_ROOF := Color("#92948f")
const UNIQUE_SCREEN := Color("#41464d")
const UNIQUE_GREEN := Color("#69704c")
const UNIQUE_BAND := 0.64
const UNIQUE_BEND_EDGES := 5

## Local plans, u east along the frontage and v south. The first five edges turn the northwest
## corner. Keep the same profile up the tower so its bands line up above the shoulder.
const UNIQUE_PODIUM := [[0.0, 3.5], [0.35, 1.25], [1.25, -0.65], [2.8, -2.1], [4.5, -2.8],
		[6.5, -3.0], [30.9, -3.0], [30.9, 57.4], [27.2, 57.4], [27.2, 87.1],
		[18.8, 87.1], [18.5, 83.0], [6.5, 83.0], [6.4, 87.1], [0.0, 87.1],
		[0.0, 63.3], [16.7, 63.3], [16.7, 40.3], [0.0, 40.3]]
const UNIQUE_NORTH_FRONT := [[0.7, 3.8], [1.0, 1.75], [1.8, 0.0], [3.1, -1.35], [4.8, -2.1],
		[6.7, -2.3], [11.2, -2.3], [12.2, -1.0], [15.4, -1.0], [16.4, -2.3], [30.2, -2.3]]
const UNIQUE_SOUTH := [[0.8, 65.05], [1.75, 64.1], [25.5, 64.1], [26.4, 65.0], [26.4, 85.2],
		[25.5, 86.1], [1.7, 86.1], [0.8, 85.2]]


## Replace the OSM fallback buildings and any LoD2 runs centred in their two plots.
func _find_unique() -> void:
	var north := _outline_at(UNIQUE_NORTH_AT)
	var south := _outline_at(UNIQUE_SOUTH_AT)
	if north.size() >= 3 and south.size() >= 3:
		_add_site("unique", [_grown(north, 3.0), _grown(south, 3.0)])
	else:
		# Older streamed indexes omit both unnamed outlines. The podium follows their union.
		_o = UNIQUE_ORIGIN
		_a = UNIQUE_AXIS.normalized()
		_b = Vector2(-_a.y, _a.x)
		_add_site("unique", [_grown(_lpoly(UNIQUE_PODIUM), 3.0)])


## Use one ground datum and draw the connected base, terraced shoulder and two skyline roofs.
func _build_unique(_site: Dictionary) -> void:
	_o = UNIQUE_ORIGIN
	_a = UNIQUE_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var podium := _lpoly(UNIQUE_PODIUM)
	var shoulder := _lpoly(UNIQUE_NORTH_FRONT + [[30.2, 39.5], [0.7, 39.5]])
	var tower := _lpoly(UNIQUE_NORTH_FRONT + [[30.2, 22.2], [0.7, 22.2]])
	var south := _lpoly(UNIQUE_SOUTH)
	_g = _ground_under(podium)
	_mode = M_STONE
	_unique_terraces()
	_unique_plant()
	_unique_crown(tower)
	_unique_podium(podium)
	_unique_blocks(shoulder, UNIQUE_PODIUM_TOP, UNIQUE_SHOULDER_TOP, 12, true)
	_unique_blocks(tower, UNIQUE_SHOULDER_TOP, UNIQUE_TOWER_TOP, 11, true)
	_unique_blocks(south, UNIQUE_PODIUM_TOP, UNIQUE_SOUTH_TOP, 12, false)
	_collide(podium)


## Set tall lobby glazing between stone piers, under the four levels tying the blocks together.
func _unique_podium(ring: PackedVector2Array) -> void:
	var lobby_top := _g + 5.0
	_prism(ring, _g - 0.65, lobby_top, PAL_WARM_GRANITE, Color.TRANSPARENT, M_STONE)
	_prism(ring, lobby_top, _g + UNIQUE_PODIUM_TOP, UNIQUE_BODY, UNIQUE_ROOF, M_STONE, M_STONE)
	for i in ring.size():
		var width := kit_front(ring[(i + 1) % ring.size()], ring[i])
		if width < 3.0:
			continue
		var bays := maxi(1, roundi(width / 4.3))
		var bay := width / bays
		for j in bays:
			var u := (j + 0.5) * bay
			if i in [5, 14, 18] and j == bays / 2:
				kit_door(u, _g - 0.05, 3.4, minf(1.55, bay * 0.37), UNIQUE_BRONZE, UNIQUE_BODY)
			else:
				kit_panes([u], [_g + 0.45], bay - 0.85, 3.92, UNIQUE_GLASS)
	_unique_bands(ring, 5.0, 3.05, 4, false)
	_unique_glazing(ring, 5.0, 3.05, 4)


## Layer a glazed residential block over the roof supporting it.
func _unique_blocks(ring: PackedVector2Array, bottom: float, top: float, floors: int, rounded: bool) -> void:
	_prism(ring, _g + bottom, _g + top, UNIQUE_BODY, UNIQUE_ROOF, M_STONE, M_STONE)
	var step := (top - bottom) / floors
	_unique_bands(ring, bottom, step, floors, rounded)
	_unique_glazing(ring, bottom, step, floors)


## Wrap slab edges and soffits around the plan. Sit the glass guards just inboard of the edge
## and pick out the north bend with the champagne trim visible in the street photos.
func _unique_bands(ring: PackedVector2Array, bottom: float, step: float, floors: int, rounded: bool) -> void:
	var residential := bottom >= UNIQUE_PODIUM_TOP
	var depth := 0.78 if residential else 0.40
	var edge := _ring_out(ring, depth)
	var guard := _ring_out(ring, depth - 0.13)
	var trim := _ring_out(ring, depth + 0.045)
	for floor_index in floors:
		var y := _g + bottom + floor_index * step
		kit_ledge_ring(ring, y, UNIQUE_BAND, UNIQUE_WHITE, depth)
		_mode = M_STONE
		_soffit(edge, y, UNIQUE_WHITE.darkened(0.23))
		for i in ring.size():
			var j := (i + 1) % ring.size()
			var out := _out(ring, ring[i], ring[j])
			if residential and out.dot(UNIQUE_AXIS) < 0.48:
				_mode = M_GLASS
				_wall(guard[i], guard[j], y + UNIQUE_BAND, y + UNIQUE_BAND + 0.83, out, UNIQUE_GUARD)
			if rounded and i < UNIQUE_BEND_EDGES:
				_mode = M_STONE
				_wall(trim[i], trim[j], y + 0.13, y + 0.50, out, UNIQUE_BRONZE)
	_mode = M_STONE


## Keep the shadows of the cladding between panes. Each opening uses a single kit quad.
func _unique_glazing(ring: PackedVector2Array, bottom: float, step: float, floors: int) -> void:
	var rows: Array[float] = []
	for floor_index in floors:
		rows.append(_g + bottom + floor_index * step + UNIQUE_BAND + 0.08)
	for i in ring.size():
		var width := kit_front(ring[(i + 1) % ring.size()], ring[i])
		var bays := maxi(1, roundi(width / 3.35))
		var bay := width / bays
		var places: Array[float] = []
		for j in bays:
			places.append((j + 0.5) * bay)
		kit_panes(places, rows, bay * 0.81, step - UNIQUE_BAND - 0.26, UNIQUE_GLASS, 0.06)


## Close the tall roof's parapet on both sides, with champagne only at the rounded street corner.
func _unique_crown(ring: PackedVector2Array) -> void:
	var y := _g + UNIQUE_TOWER_TOP
	var outer := _ring_out(ring, 0.14)
	var inner := _inset_ring(ring, 0.25)
	for i in ring.size():
		var j := (i + 1) % ring.size()
		var out := _out(ring, ring[i], ring[j])
		_wall(outer[i], outer[j], y - 0.24, y + 2.0, out, UNIQUE_BRONZE if i <= UNIQUE_BEND_EDGES else UNIQUE_SCREEN)
		_wall(inner[i], inner[j], y, y + 2.0, -out, UNIQUE_SCREEN)
	_strip(inner, outer, y + 2.0, UNIQUE_SCREEN.lightened(0.10))


## Low planting on the shoulder and the podium connector reads from the overhead game camera.
func _unique_terraces() -> void:
	var y := _g + UNIQUE_SHOULDER_TOP
	_lbox(8.0, 31.6, 5.2, 2.4, y, y + 0.37, PAL_GREY_GRANITE, M_STONE, UNIQUE_GREEN)
	_lbox(15.0, 37.3, 12.3, 0.75, y, y + 0.34, PAL_GREY_GRANITE, M_STONE, UNIQUE_GREEN)
	y = _g + UNIQUE_PODIUM_TOP
	_lbox(23.0, 50.0, 4.6, 6.1, y, y + 0.35, PAL_GREY_GRANITE, M_STONE, UNIQUE_GREEN)


## Set back the broad dark equipment screen on the tower and the two smaller roof houses.
func _unique_plant() -> void:
	var y := _g + UNIQUE_TOWER_TOP
	_lbox(18.4, 11.7, 8.8, 6.9, y, y + 5.0, UNIQUE_SCREEN)
	_lbox(8.05, 12.8, 1.1, 4.15, y, y + 1.9, UNIQUE_SCREEN.lightened(0.12))
	y = _g + UNIQUE_SHOULDER_TOP
	_lbox(23.0, 29.6, 5.1, 4.6, y, y + 3.4, UNIQUE_SCREEN)
	y = _g + UNIQUE_SOUTH_TOP
	_lbox(13.8, 74.4, 8.9, 5.7, y, y + 1.9, UNIQUE_SCREEN)


# --- Osiedle Za Żelazną Bramą: eleven large-panel blocks ---------------------------------------

## F's ask (2026-11-01): the estate between Żelazna and Aleja Jana Pawła II (Jerzy Skolimowski's,
## 1965-72) as a model, as the halls are. Eleven OpenStreetMap blocks, found by a point inside
## each: five 43.9 m slabs in a row from Żelazna to Sienna, the 60.4 m high block among them, and
## the five 37-41 m slabs with the saw-toothed long faces along Sienna's east end. Each is built
## from its own outline and height in the estate's panel skin (S_ESTATE, spec zelazna.md): pale
## concrete panels, ribbon windows, a coloured loggia stack in every fourth bay; blank end walls
## with a dark stair slot; a canopy and door at each long face's middle; lift and stair houses.
const ZELAZNA_AT := [Vector2(-2085.6, 304.2), Vector2(-2034.6, 287.2), Vector2(-1979.1, 270.5),
		Vector2(-1927.2, 255.2), Vector2(-2045.6, 348.6), Vector2(-1995.5, 322.2), Vector2(-1857.0, 316.4),
		Vector2(-1857.9, 260.4), Vector2(-1843.5, 217.7), Vector2(-1873.1, 382.1), Vector2(-1842.6, 377.0)]
const ZELAZNA_PANELS := ["#d2cfc6", "#cbcdc6", "#d6cfc0", "#c8cbc9"]
const ZELAZNA_END := Color("#b9b5aa")
const ZELAZNA_ROOF := Color("#77777a")
const ZELAZNA_SLOT := Color("#3b4650")
const ZELAZNA_CANOPY := Color("#8d8b86")


func _find_zelazna() -> void:
	var zones: Array[PackedVector2Array] = []
	var rings: Array[PackedVector2Array] = []
	var heights: Array[float] = []
	for at: Vector2 in ZELAZNA_AT:
		for bld in data["buildings"]:
			var q := _pts(bld["p"])
			if q.size() >= 3 and float(bld["mh"]) < 0.5 and _box_of([q]).has_point(at) and Geometry2D.is_point_in_polygon(at, q):
				zones.append(_largest(Geometry2D.offset_polygon(q, 3.0, Geometry2D.JOIN_MITER)))
				rings.append(q)
				heights.append(float(bld["h"]))
				break
	_add_site("zelazna", zones)
	if not sites.is_empty() and sites[-1]["key"] == "zelazna":
		sites[-1]["outlines"] = rings
		sites[-1]["heights"] = heights


func _build_zelazna(site: Dictionary) -> void:
	var k := 0
	for z: PackedVector2Array in site["outlines"]:
		var poly := _simplify(z, 0.6)
		var height: float = site["heights"][k]
		var panel := Color(ZELAZNA_PANELS[k % ZELAZNA_PANELS.size()])
		if height > 55.0:
			panel = Color("#bfc4c6")  # the high block: a cooler grey
		k += 1
		if poly.size() < 3:
			continue
		_g = _ground_under(poly)
		var g := _g
		var top := g + height
		var axis := Vector2.ZERO
		for i in poly.size():
			var e := poly[(i + 1) % poly.size()] - poly[i]
			if e.length() > axis.length():
				axis = e
		axis = axis.normalized()
		var run := 0.0
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var o := _out(poly, a, b)
			var len := a.distance_to(b)
			var end_wall := absf(o.dot(axis)) > 0.8
			_mode = M_STONE if end_wall else M_SKIN + float(S_ESTATE) / 16.0
			_wall(a, b, g - 0.4, top, o, ZELAZNA_END if end_wall else panel, run)
			run += len
			var d := (b - a) / maxf(len, 0.01)
			var mid := (a + b) * 0.5
			if end_wall and len >= 6.0:
				# the stair slot: a dark glazed strip up the blank end.
				var p := mid + o * 0.05
				_mode = M_GLASS
				_wall(p - d * 0.5, p + d * 0.5, g + 3.2, top - 3.0, o, ZELAZNA_SLOT)
			elif not end_wall and len >= 14.0:
				# the entrance: a dark door and a flat canopy over it.
				var p := mid + o * 0.06
				_mode = M_GLASS
				_wall(p - d * 1.3, p + d * 1.3, g, g + 2.4, o, ZELAZNA_SLOT)
				_mode = M_STONE
				var f := mid - o * 0.1
				var c := mid + o * 1.8
				_prism(PackedVector2Array([f - d * 2.2, f + d * 2.2, c + d * 2.2, c - d * 2.2]), g + 2.7, g + 2.95,
						ZELAZNA_CANOPY, ZELAZNA_CANOPY.darkened(0.1), M_STONE, M_STONE)
		_mode = M_STONE
		_cap(poly, top, ZELAZNA_ROOF)
		# lift and stair houses at a third and two thirds of the long axis.
		var c0 := _centre(poly)
		var span := 0.0
		for q in poly:
			span = maxf(span, absf((q - c0).dot(axis)))
		var across := Vector2(-axis.y, axis.x)
		for f: float in [-0.4, 0.4]:
			var p := c0 + axis * span * f
			_prism(PackedVector2Array([p - axis * 2.8 - across * 2.0, p + axis * 2.8 - across * 2.0, p + axis * 2.8 + across * 2.0,
					p - axis * 2.8 + across * 2.0]), top, top + 3.0, panel.darkened(0.08), Color("#6a6a6d"), M_STONE, M_STONE)
		_collide(poly)


# --- Plac Małachowskiego and the Presidential Palace (2026-10-31) ------------------------------

## Hala Mirowska (Stefan Szyller and Czesław Domaniewski, 1899-1901), the western of the twin
## market halls on Plac Mirowski: a red-brick hall, 97 x 44 m, its main front to the east, to the
## square. Massing from the mapped parts (spec docs/landmarks/specs/mirowska.md): brick walls 10 m
## high round the whole hall with round-headed windows between cream pilasters, a cornice, the
## nave's gabled roof (ridge 14.5 m) with a glazed lantern on top (17 m), thin tall gable ends
## (18 m, a pinnacle each) between four corner turrets with pyramid caps, and a low arcaded
## annex at the west end under a steep red tile roof (10 m). Frame: origin at the south-west
## corner, u east along the long side, +v to the north across the hall.
const MIROWSKA := Vector2(-1857.4, -501.8)
const MIROWSKA_AXIS := Vector2(0.970, -0.242)
const MIROWSKA_HU := 97.4
const MIROWSKA_HV := 43.6
const MIROWSKA_BRICK := Color("#a85c40")

const MIROWSKA_PLINTH := Color("#857e74")
const MIROWSKA_ROOF := Color("#6d7470")
const MIROWSKA_NAVE := Color("#8b948f")
const MIROWSKA_CAP := Color("#6f7f78")
const MIROWSKA_TILE := Color("#a8493a")

const MIROWSKA_DOOR := Color("#33271f")
const MIROWSKA_SKY := Color("#a9bcc4")
## The market stalls' awnings on the square (2026-11-01).
const MIROWSKA_AWNINGS := ["#c8553a", "#3f7fa8", "#d6a53a", "#5c9a5a", "#b8607a"]


func _find_mirowska() -> void:
	var outline := _landmark("Hala Mirowska")
	if outline.size() >= 3:
		_add_site("mirowska", [outline])
		if not sites.is_empty() and sites[-1]["key"] == "mirowska":
			sites[-1]["ring"] = outline


func _build_mirowska(site: Dictionary) -> void:
	_o = MIROWSKA
	_a = MIROWSKA_AXIS.normalized()
	_b = Vector2(_a.y, -_a.x)  # to the north, across the hall
	var hu := MIROWSKA_HU
	var hv := MIROWSKA_HV
	var body := _rect(hu * 0.5, hv * 0.5, hu * 0.5, hv * 0.5)
	_g = _ground_under(body)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var nave_v := hv * 0.5
	var nave_hw := 13.3
	var bay := (85.4 - 12.5) / 16.0
	# windows first, so the walls behind them stay whole (they stand off the wall by cm)
	for side in 2:
		var v := 0.0 if side == 0 else hv
		var out := -_b if side == 0 else _b
		for k in 18:
			_arch_win(_w(12.5 + (k + 0.5) * bay, v), _a, out, 1.15, g + 2.4, g + 6.6)
		for u: float in [4.2, 8.6]:  # the annex's arcade on its long sides
			_arch_win(_w(u, v), _a, out, 0.75, g + 1.1, g + 2.6)
	# the east front: a portal in the middle bay between six windows
	var pitch := hv / 7.0
	for k in 7:
		var v := (k + 0.5) * pitch
		if k == 3:
			_arch_win(_w(hu, v), _b, _a, 1.7, g + 1.3, g + 5.6, MIROWSKA_DOOR)
		else:
			_arch_win(_w(hu, v), _b, _a, 1.3, g + 2.4, g + 6.6)
	# the west face: the arcade of the annex
	for k in 8:
		_arch_win(_w(0.0, (k + 0.5) * hv / 8.0), _b, -_a, 0.8, g + 1.1, g + 2.6)
	# the thin tall gable ends: a big window in each
	_arch_win(_w(90.1, nave_v), _b, _a, 1.8, g + 11.0, g + 13.8)
	_arch_win(_w(7.7, nave_v), _b, -_a, 1.8, g + 11.0, g + 13.8)
	# the walls: brick, 10 m, flat grey roof (the nave stands on it)
	_mode = M_STONE
	var main := _rect((12.5 + hu) * 0.5, hv * 0.5, (hu - 12.5) * 0.5, hv * 0.5)
	_prism(main, g - 0.5, g + 10.0, MIROWSKA_BRICK, MIROWSKA_ROOF, M_STONE, M_STONE)
	# the annex: low brick walls under a steep red hipped roof
	_prism(_rect(6.25, hv * 0.5, 6.25, hv * 0.5), g - 0.5, g + 4.0, MIROWSKA_BRICK, none, M_STONE, M_STONE)
	_hip(6.25, hv * 0.5, 6.4, hv * 0.5 + 0.15, g + 4.0, 6.0, MIROWSKA_TILE)
	# plinth: four thin boxes round the foot
	_lbox(hu * 0.5, -0.1, hu * 0.5 + 0.2, 0.2, g - 0.5, g + 1.2, MIROWSKA_PLINTH, M_STONE, MIROWSKA_PLINTH.lightened(0.05))
	_lbox(hu * 0.5, hv + 0.1, hu * 0.5 + 0.2, 0.2, g - 0.5, g + 1.2, MIROWSKA_PLINTH, M_STONE, MIROWSKA_PLINTH.lightened(0.05))
	_lbox(hu + 0.1, hv * 0.5, 0.2, hv * 0.5 - 0.2, g - 0.5, g + 1.2, MIROWSKA_PLINTH, M_STONE, MIROWSKA_PLINTH.lightened(0.05))
	_lbox(-0.1, hv * 0.5, 0.2, hv * 0.5 - 0.2, g - 0.5, g + 1.2, MIROWSKA_PLINTH, M_STONE, MIROWSKA_PLINTH.lightened(0.05))
	# the cornice along the main block's three outer sides
	_lbox((12.5 + hu) * 0.5, -0.17, (hu - 12.5) * 0.5 + 0.35, 0.35, g + 9.0, g + 10.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	_lbox((12.5 + hu) * 0.5, hv + 0.17, (hu - 12.5) * 0.5 + 0.35, 0.35, g + 9.0, g + 10.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	_lbox(hu + 0.17, hv * 0.5, 0.35, hv * 0.5 - 0.35, g + 9.0, g + 10.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	# pilasters between the bays: along both long sides and across the east front
	var pil: Array[float] = []
	for k in 17:
		pil.append(12.5 + k * bay)
	pil.append_array([90.0, 94.5, hu - 0.25])
	for u: float in pil:
		_lbox(u, -0.15, 0.25, 0.15, g + 1.2, g + 9.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
		_lbox(u, hv + 0.15, 0.25, 0.15, g + 1.2, g + 9.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	for k in 8:
		var v := clampf(k * pitch, 0.25, hv - 0.25)
		_lbox(hu + 0.15, v, 0.15, 0.25, g + 1.2, g + 9.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	# the glazed gallery on the east front (photo 2026-11-07, `warsaw-needed-photos`): a dark glass
	# band across the front over the market's ground floor, under a thin dark fascia
	_lbox(hu + 0.9, nave_v, 0.9, hv * 0.5 - 3.0, g + 3.6, g + 8.8, MIROWSKA_GLASS, M_GLASS, none)
	_lbox(hu + 0.95, nave_v, 1.0, hv * 0.5 - 2.9, g + 8.8, g + 9.5, Color("#4b2e29"), M_STONE, Color("#5a3a33"))
	# the portal's steps
	for k in 3:
		_lbox(hu + 0.4 + (2 - k) * 0.4, nave_v, 0.4 + (2 - k) * 0.4, 2.6, g - 0.5, g + 0.4 * (k + 1), MIROWSKA_PLINTH, M_STONE,
				MIROWSKA_PLINTH.lightened(0.05))
	# the nave's gabled roof and its tall gable ends
	_gable(88.7, 9.1, nave_v, nave_hw, g + 10.0, 4.5, MIROWSKA_BRICK, MIROWSKA_NAVE)
	_gable(90.1, 88.7, nave_v, nave_hw, g + 10.0, 8.0, MIROWSKA_BRICK, MIROWSKA_TRIM)
	_gable(7.7, 9.1, nave_v, nave_hw, g + 10.0, 8.0, MIROWSKA_BRICK, MIROWSKA_TRIM)
	_pinnacle(89.4, nave_v, 0.9, g + 17.8, 2.2, MIROWSKA_TRIM)
	_pinnacle(8.4, nave_v, 0.9, g + 17.8, 2.2, MIROWSKA_TRIM)
	# four corner turrets with pyramid caps
	for cu: float in [10.1, 88.0]:
		for cv: float in [11.3, hv - 11.3]:
			_lbox(cu, cv, 2.5, 2.4, g + 10.0, g + 14.4, MIROWSKA_BRICK, M_STONE, none)
			_lbox(cu, cv, 2.65, 2.55, g + 14.2, g + 15.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
			_mode = M_STONE
			_pyramid(_rect(cu, cv, 2.7, 2.6), g + 15.0, g + 18.8, MIROWSKA_CAP)
	# the lantern along the ridge: glass sides on the slope, a glass roof
	_lbox(49.45, nave_v, 31.05, 5.5, g + 12.4, g + 16.0, MIROWSKA_SKY, M_GLASS, none)
	_mode = M_GLASS_ROOF
	_frustum(_rect(49.45, nave_v, 31.05, 5.5), g + 16.0, _rect(49.45, nave_v, 31.05, 0.3), g + 17.4, MIROWSKA_SKY, MIROWSKA_SKY)
	_mode = M_STONE
	# the market on the square (2026-11-01): ten trestle stalls under striped awnings in a row
	# along the east front, a lane's width off the wall, a bench-high counter and a thin awning
	# on each, in the stalls' mixed colours
	for k in 10:
		var sv := 3.4 + k * 4.1
		var cl := Color(MIROWSKA_AWNINGS[k % MIROWSKA_AWNINGS.size()])
		_lbox(hu + 5.0, sv, 0.8, 1.1, g + 0.0, g + 0.95, MIROWSKA_PLINTH.darkened(0.1), M_STONE, MIROWSKA_TRIM)
		_lbox(hu + 5.0, sv, 1.0, 1.4, g + 2.2, g + 2.32, cl, M_STONE, cl.lightened(0.1))
		for pv: float in [-1.2, 1.2]:
			_lbox(hu + 5.9, sv + pv, 0.05, 0.05, g, g + 2.2, Color("#4a4d52"), M_STONE)
	_collide(site["ring"])


## Hala Gwardii (Stefan Szyller and Czesław Domaniewski, 1899-1901), the eastern twin of Hala
## Mirowska on the other side of Plac Mirowski, 96.8 x 44.1 m, long axis the same as its twin's.
## OSM maps only the outline (no 3D parts) but maps it down to the pilasters, so the bays here are
## measured from it (spec docs/landmarks/specs/gwardii.md): the hall is symmetric end to end, a
## portal in the middle of both short ends, 15 pilasters on each long side. It reuses Mirowska's
## helpers, colours and massing (nave, lantern, gable ends, turrets) and drops the annex.
## Frame: origin at the south-west corner, u east along the long side, +v to the north.
const GWARDII := Vector2(-1712.77, -537.24)
const GWARDII_HU := 96.8
const GWARDII_HV := 44.1
## Pilaster centres along a long side, from the west end to the middle; the east half mirrors them.
const GWARDII_PILASTERS: Array[float] = [1.0, 7.5, 11.1, 18.3, 24.95, 31.65, 38.25, 45.1]
## Window centres along a long side, west half; the east half mirrors them, plus one at the middle.
const GWARDII_BAYS: Array[float] = [14.7, 21.6, 28.3, 35.0, 41.7]
## Pilaster centres across a short end, from the south to the middle; the north half mirrors them.
const GWARDII_END_PILASTERS: Array[float] = [1.0, 7.4, 18.1]


func _find_gwardii() -> void:
	var outline := _landmark("Hala Gwardii")
	if outline.size() >= 3:
		_add_site("gwardii", [outline])
		if not sites.is_empty() and sites[-1]["key"] == "gwardii":
			sites[-1]["ring"] = outline


func _build_gwardii(site: Dictionary) -> void:
	_o = GWARDII
	_a = MIROWSKA_AXIS.normalized()
	_b = Vector2(_a.y, -_a.x)  # to the north, across the hall
	var hu := GWARDII_HU
	var hv := GWARDII_HV
	var body := _rect(hu * 0.5, hv * 0.5, hu * 0.5, hv * 0.5)
	_g = _ground_under(body)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var nave_v := hv * 0.5
	var nave_hw := 13.3
	var mid := hu * 0.5
	# window and pilaster positions along a long side, mirrored about the middle
	var wins: Array[float] = []
	for u in GWARDII_BAYS:
		wins.append(u)
		wins.append(hu - u)
	wins.append(mid)
	var pils: Array[float] = []
	for u in GWARDII_PILASTERS:
		pils.append(u)
		pils.append(hu - u)
	var end_pils: Array[float] = []
	for v in GWARDII_END_PILASTERS:
		end_pils.append(v)
		end_pils.append(hv - v)
	# windows first, so the walls behind them stay whole (they stand off the wall by cm)
	for side in 2:
		var v := 0.0 if side == 0 else hv
		var out := -_b if side == 0 else _b
		for u in wins:
			_arch_win(_w(u, v), _a, out, 1.15, g + 2.4, g + 6.6)
		for u: float in [4.25, hu - 4.25]:  # the corner bays are narrower
			_arch_win(_w(u, v), _a, out, 0.9, g + 2.4, g + 6.6)
	# both short ends: a portal in the middle bay between two windows each side
	for end in 2:
		var u := 0.0 if end == 0 else hu
		var out := -_a if end == 0 else _a
		for cv: float in [4.2, 12.75, 31.35, hv - 4.2]:
			var small := cv < 6.0 or cv > hv - 6.0
			_arch_win(_w(u, cv), _b, out, 0.9 if small else 1.3, g + 2.4, g + 6.6)
		_arch_win(_w(u, nave_v), _b, out, 1.7, g + 1.3, g + 5.6, MIROWSKA_DOOR)
	# the thin tall gable ends: a big window in each
	_arch_win(_w(89.1, nave_v), _b, _a, 1.8, g + 11.0, g + 13.8)
	_arch_win(_w(7.7, nave_v), _b, -_a, 1.8, g + 11.0, g + 13.8)
	# the walls: brick, 10 m, flat grey roof (the nave stands on it)
	_mode = M_STONE
	_prism(body, g - 0.5, g + 10.0, MIROWSKA_BRICK, MIROWSKA_ROOF, M_STONE, M_STONE)
	# plinth: four thin boxes round the foot
	_lbox(mid, -0.1, mid + 0.2, 0.2, g - 0.5, g + 1.2, MIROWSKA_PLINTH, M_STONE, MIROWSKA_PLINTH.lightened(0.05))
	_lbox(mid, hv + 0.1, mid + 0.2, 0.2, g - 0.5, g + 1.2, MIROWSKA_PLINTH, M_STONE, MIROWSKA_PLINTH.lightened(0.05))
	_lbox(hu + 0.1, nave_v, 0.2, nave_v - 0.2, g - 0.5, g + 1.2, MIROWSKA_PLINTH, M_STONE, MIROWSKA_PLINTH.lightened(0.05))
	_lbox(-0.1, nave_v, 0.2, nave_v - 0.2, g - 0.5, g + 1.2, MIROWSKA_PLINTH, M_STONE, MIROWSKA_PLINTH.lightened(0.05))
	# the cornice round all four sides
	_lbox(mid, -0.17, mid + 0.35, 0.35, g + 9.0, g + 10.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	_lbox(mid, hv + 0.17, mid + 0.35, 0.35, g + 9.0, g + 10.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	_lbox(hu + 0.17, nave_v, 0.35, nave_v - 0.35, g + 9.0, g + 10.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	_lbox(-0.17, nave_v, 0.35, nave_v - 0.35, g + 9.0, g + 10.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	# pilasters between the bays (the outline's own jogs): both long sides and both ends
	for u in pils:
		_lbox(u, -0.15, 0.6, 0.15, g + 1.2, g + 9.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
		_lbox(u, hv + 0.15, 0.6, 0.15, g + 1.2, g + 9.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	for v in end_pils:
		_lbox(-0.15, v, 0.15, 0.6, g + 1.2, g + 9.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
		_lbox(hu + 0.15, v, 0.15, 0.6, g + 1.2, g + 9.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
	# the portals' steps, both ends
	for k in 3:
		var e := 0.4 + (2 - k) * 0.4
		_lbox(hu + e, nave_v, e, 2.6, g - 0.5, g + 0.4 * (k + 1), MIROWSKA_PLINTH, M_STONE, MIROWSKA_PLINTH.lightened(0.05))
		_lbox(-e, nave_v, e, 2.6, g - 0.5, g + 0.4 * (k + 1), MIROWSKA_PLINTH, M_STONE, MIROWSKA_PLINTH.lightened(0.05))
	# the nave's gabled roof and its two tall gable ends
	_gable(87.7, 9.1, nave_v, nave_hw, g + 10.0, 4.5, MIROWSKA_BRICK, MIROWSKA_NAVE)
	_gable(89.1, 87.7, nave_v, nave_hw, g + 10.0, 8.0, MIROWSKA_BRICK, MIROWSKA_TRIM)
	_gable(7.7, 9.1, nave_v, nave_hw, g + 10.0, 8.0, MIROWSKA_BRICK, MIROWSKA_TRIM)
	_pinnacle(88.4, nave_v, 0.9, g + 17.8, 2.2, MIROWSKA_TRIM)
	_pinnacle(8.4, nave_v, 0.9, g + 17.8, 2.2, MIROWSKA_TRIM)
	# four corner turrets with pyramid caps
	for cu: float in [10.1, hu - 10.1]:
		for cv: float in [11.3, hv - 11.3]:
			_lbox(cu, cv, 2.5, 2.4, g + 10.0, g + 14.4, MIROWSKA_BRICK, M_STONE, none)
			_lbox(cu, cv, 2.65, 2.55, g + 14.2, g + 15.0, MIROWSKA_TRIM, M_STONE, MIROWSKA_TRIM)
			_mode = M_STONE
			_pyramid(_rect(cu, cv, 2.7, 2.6), g + 15.0, g + 18.8, MIROWSKA_CAP)
	# the lantern along the ridge: glass sides on the slope, a glass roof
	_lbox(mid, nave_v, 31.05, 5.5, g + 12.4, g + 16.0, MIROWSKA_SKY, M_GLASS, none)
	_mode = M_GLASS_ROOF
	_frustum(_rect(mid, nave_v, 31.05, 5.5), g + 16.0, _rect(mid, nave_v, 31.05, 0.3), g + 17.4, MIROWSKA_SKY, MIROWSKA_SKY)
	_mode = M_STONE
	_collide(site["ring"])


# --- Muzeum Powstania Warszawskiego (2026-11-02, spec docs/landmarks/specs/mpw.md) ------------

## The Warsaw Rising Museum, Grzybowska 79 / Przyokopowa 28: the tram power station of 1904-1908
## (OSM "Elektrownia Tramwajów Miejskich"), the museum since 2004. Built from F's Mac photo pass
## (refs/mpw/: 25 Commons photos, the GUGiK ortho and REPORT.md/PARTS.md in game coordinates) and
## LoD2's heights. On Przyokopowa the west leg in orange-red brick: two corner blocks (W1, W3)
## under cream attics and between them the long arcade hall (W2): brick piers, eleven tall
## round-arched windows with a blind fourth bay, paired small arches under them, a cream frieze
## and attic. Behind it the halls in pale render under grey-blue metal gables (ridges N-S in the
## middle, E-W with red steel grids on the gables facing Freedom Park), the low yard wing with
## the museum doors, and at the halls' south-east corner the observation tower: a steel frame,
## a concrete shaft whose east face tapers out as a wedge carrying the white Kotwica, the black
## mesh platform and cabin at 28-31.5 m, the flag. Around it: the hipped brick office block, the
## gatehouse with its pinnacles, the KASA pavilion, the brick fence with railings on Przyokopowa,
## the Tobruk bunker, and in the park the curved black granite Wall of Remembrance with the bell.
## Frame: u east, v south from the outline's NW corner, turned with its west wall (2.4 degrees).
const MPW_O := Vector2(-2955.1, 160.4)
const MPW_B := Vector2(0.0422, 1.0)                 # along the west wall, to the south
const MPW_BRICK := Color("#b4553f")
const MPW_BAND := Color("#8a4a3c")                  # archivolts and shaded brick
const MPW_CREAM := Color("#d9cdb5")
const MPW_RENDER := Color("#a09b94")                # the yard-side halls
const MPW_METAL := Color("#8394a0")                 # standing-seam gables (lit a5b5c0, shaded 596577)
const MPW_FLAT := Color("#8f9396")
const MPW_GLASS := Color("#3a4248")
const MPW_RED := Color("#9a2a25")                   # the steel grids on the east gables
const MPW_CONCRETE := Color("#8a8a88")
const MPW_STEEL := Color("#2a2523")
const MPW_WHITE := Color("#f2f0ea")
const MPW_GRANITE := Color("#3a3b3d")
const MPW_TILE := Color("#b5683f")
const MPW_ROOF_DARK := Color("#4a4e52")
## The west leg's blocks and the halls: [u0, u1, v0, v1, eaves, top] in the frame.
const MPW_W1 := [-0.8, 9.5, 0.0, 12.0, 15.0, 19.0]
const MPW_W2 := [0.0, 18.0, 12.0, 63.5, 14.0, 15.5]
const MPW_W2N := [9.5, 18.0, 4.5, 12.0, 14.0, 15.5]
const MPW_W3 := [-0.8, 18.3, 63.5, 73.5, 15.0, 17.0]
const MPW_LOW := [9.5, 52.3, 0.3, 4.5, 12.5, 12.5]   # the pale bannered wing (look check: 3 storeys)
## [u0, u1, v0, v1, eaves, ridge, ridge along u]
const MPW_HALLS := [
	[18.0, 40.6, 4.5, 23.0, 12.0, 16.5, false],   # M1
	[18.0, 40.6, 27.0, 44.5, 12.0, 16.0, false],  # M2
	[40.6, 57.7, 4.5, 23.0, 12.0, 17.0, true],    # E1, its gable to the park
	[40.6, 57.7, 27.0, 45.0, 11.0, 15.0, true],   # E2
	[18.0, 57.7, 23.0, 27.0, 12.0, 14.0, true],   # the cross gable between them
]
const MPW_TOWER := [48.8, 55.8, 32.7, 40.7]
## The Wall of Remembrance (world x, z), from the ortho; its south end under the trees is a guess.
const MPW_WALL := [Vector2(-2903.0, 141.0), Vector2(-2891.0, 167.0), Vector2(-2879.0, 192.0),
		Vector2(-2866.0, 218.0), Vector2(-2858.0, 236.0), Vector2(-2848.0, 255.0)]
const MPW_BELL := Vector2(-2873.0, 204.0)
const MPW_OFFICE := Vector2(-2931.0, 130.0)         # the hipped office block's centre
const MPW_OFFICE_AXIS := Vector2(0.9673, -0.2543)
const MPW_GATEHOUSE := Rect2(-2959.0, 142.3, 9.4, 6.1)
const MPW_KASA := Rect2(-2911.5, 139.5, 7.0, 11.5)
const MPW_TOBRUK := Vector2(-2926.0, 117.0)


func _mpw_a() -> Vector2:
	var b := MPW_B.normalized()
	return Vector2(b.y, -b.x)


func _mpw_frame() -> void:
	_o = MPW_O
	_b = MPW_B.normalized()
	_a = Vector2(_b.y, -_b.x)


func _mpw_rect(u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	return _rect((u0 + u1) * 0.5, (v0 + v1) * 0.5, (u1 - u0) * 0.5, (v1 - v0) * 0.5)


## The office block's plan in its own frame (25 x 14 m, turned 15 degrees).
func _mpw_office() -> PackedVector2Array:
	var a := MPW_OFFICE_AXIS.normalized()
	var b := Vector2(-a.y, a.x)
	var c := MPW_OFFICE
	return PackedVector2Array([c - a * 11.0 - b * 6.6, c + a * 11.0 - b * 6.6, c + a * 11.0 + b * 6.6, c - a * 11.0 + b * 6.6])


## The Wall of Remembrance as one mitred band `half` either side of its line.
func _mpw_wall_band(half: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := MPW_WALL.size()
	for i in n:
		var p: Vector2 = MPW_WALL[i]
		var d0: Vector2 = (p - MPW_WALL[i - 1]).normalized() if i > 0 else (MPW_WALL[1] - p).normalized()
		var d1: Vector2 = (MPW_WALL[i + 1] - p).normalized() if i < n - 1 else d0
		var t := (d0 + d1).normalized()
		var m := Vector2(-t.y, t.x)
		var s := half / maxf(m.dot(Vector2(-d0.y, d0.x)), 0.5)
		left.append(p + m * s)
		right.append(p - m * s)
	right.reverse()
	left.append_array(right)
	return left


func _find_mpw() -> void:
	var outline := _landmark("Elektrownia Tramwajów Miejskich")
	if outline.size() < 3:
		return
	var gate := MPW_GATEHOUSE
	var kasa := MPW_KASA
	var zone: Array = [outline, _mpw_office(), _mpw_wall_band(3.0),
		PackedVector2Array([gate.position, Vector2(gate.end.x, gate.position.y), gate.end, Vector2(gate.position.x, gate.end.y)]),
		PackedVector2Array([kasa.position, Vector2(kasa.end.x, kasa.position.y), kasa.end, Vector2(kasa.position.x, kasa.end.y)]),
		_circle(MPW_TOBRUK, 4.0, 8)]
	_add_site("mpw", zone)
	if not sites.is_empty() and sites[-1]["key"] == "mpw":
		sites[-1]["ring"] = outline


## A round-headed window on a wall: a rim (an archivolt) behind its pane; `glass` transparent
## (alpha 0) leaves the rim alone (a blind arch).
func _mpw_win(at: Vector2, along: Vector2, out: Vector2, hw: float, sill: float, spring: float, glass: Color,
		rim := MPW_BAND) -> void:
	_arch_panel(at, along, out, hw + 0.25, _g + sill - 0.2, _g + spring, rim, 0.04, M_STONE)
	if glass.a > 0.0:
		_arch_panel(at, along, out, hw, _g + sill, _g + spring, glass, 0.08, M_GLASS)


## A block of the west leg: brick to the eaves, a cream attic to its top, a flat roof.
func _mpw_block(b: Array) -> void:
	var g := _g
	var none := Color(0, 0, 0, 0)
	_prism(_mpw_rect(b[0], b[1], b[2], b[3]), g - 0.6, g + float(b[4]), MPW_BRICK, none, M_STONE, M_STONE)
	_prism(_mpw_rect(b[0], b[1], b[2], b[3]), g + float(b[4]), g + float(b[5]), MPW_CREAM, MPW_FLAT, M_STONE, M_STONE)


## A hall in pale render under a metal gable. Ridge along u: its gables face east and west.
func _mpw_hall(h: Array) -> void:
	var g := _g
	var u0: float = h[0]
	var u1: float = h[1]
	var v0: float = h[2]
	var v1: float = h[3]
	var eave: float = h[4]
	var rise: float = float(h[5]) - eave
	_prism(_mpw_rect(u0, u1, v0, v1), g - 0.6, g + eave, MPW_RENDER, Color(0, 0, 0, 0), M_STONE, M_STONE)
	if h[6]:
		_gable(u1, u0, (v0 + v1) * 0.5, (v1 - v0) * 0.5, g + eave, rise, MPW_RENDER, MPW_METAL)
	else:
		var ka := _a
		var kb := _b
		_a = kb
		_b = ka
		_gable(v0, v1, (u0 + u1) * 0.5, (u1 - u0) * 0.5, g + eave, rise, MPW_RENDER, MPW_METAL)
		_a = ka
		_b = kb


## The red steel grid on an east gable at u: six posts, four rails, clipped by the roof's slope.
func _mpw_grid(u: float, v0: float, v1: float, eave: float, ridge: float) -> void:
	var g := _g
	var mid := (v0 + v1) * 0.5
	var half := (v1 - v0) * 0.5
	var height := func(v: float) -> float:
		return eave + (ridge - eave) * (1.0 - absf(v - mid) / half)
	for k in 6:
		var v := lerpf(v0 + 0.6, v1 - 0.6, k / 5.0)
		var p := _w(u + 0.15, v)
		_beam(Vector3(p.x, g + 0.4, p.y), Vector3(p.x, g + float(height.call(v)) - 0.4, p.y), 0.25, MPW_RED)
	for k in 4:
		var y := 2.0 + (eave - 2.0) * k / 3.0
		var a := _w(u + 0.15, v0 + 0.6)
		var b := _w(u + 0.15, v1 - 0.6)
		_beam(Vector3(a.x, g + y, a.y), Vector3(b.x, g + y, b.y), 0.25, MPW_RED)


func _build_mpw(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_mpw_frame()
	_g = _ground_under(ring)
	var g := _g
	var east := _a
	var south := _b
	_mode = M_STONE
	# The west leg on Przyokopowa: the arcade hall between the two corner blocks.
	for blk: Array in [MPW_W1, MPW_W2, MPW_W2N, MPW_W3]:
		_mpw_block(blk)
	# W2's street front: eleven bays between brick piers (the fourth from the north blind), the
	# paired small arches of the ground floor under one archivolt, a small arch over them, the
	# tall fan windows, and the cream frieze under the attic.
	for i in 11:
		var v := 14.1 + 4.6 * i
		var at := _w(0.0, v)
		# F's look check (2026-11-03): deeper arches. A wide brick archivolt, then a dark reveal
		# round the window, between piers that stand out 0.6 m.
		# The reveal is the window's rim here: layers 2.5 cm apart so none of them flickers.
		_arch_panel(at, south, -east, 1.75, g + 5.8, g + 9.4, MPW_BAND, 0.025, M_STONE)
		_arch_panel(at, south, -east, 1.5, g + 6.0, g + 9.4, MPW_BAND.darkened(0.45), 0.05, M_STONE)
		if i == 3:
			_arch_panel(at, south, -east, 1.2, g + 6.2, g + 9.4, MPW_CREAM, 0.075, M_STONE)
		else:
			_arch_panel(at, south, -east, 1.2, g + 6.2, g + 9.4, MPW_GLASS, 0.08, M_GLASS)
		_arch_panel(at, south, -east, 1.4, g + 0.6, g + 2.3, MPW_BAND, 0.04, M_STONE)
		for s: float in [-0.7, 0.7]:
			_arch_panel(_w(0.0, v + s), south, -east, 0.42, g + 0.8, g + 2.3, MPW_GLASS, 0.08, M_GLASS)
		_mpw_win(at, south, -east, 0.4, 4.0, 4.8, MPW_GLASS)
	for i in 12:
		var v := 11.8 + 4.6 * i
		if v < 12.3:
			continue
		_prism(_mpw_rect(-0.6, 0.0, v - 0.35, v + 0.35), g - 0.6, g + 14.0, MPW_BRICK, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_wall(_w(-0.05, 12.0), _w(-0.05, 63.5), g + 12.2, g + 13.6, -east, MPW_CREAM)
	# W2's yard side to the gravel court: tall windows.
	for v: float in [47.0, 51.6, 56.2, 60.8]:
		_mpw_win(_w(18.0, v), south, east, 1.1, 5.4, 9.0, MPW_GLASS)
	# W1 (north corner): three floors of arched windows, a pair and a single to the street, one to
	# Grzybowska's side; the city's arms on the street face.
	for sill: float in [1.0, 5.4, 9.6]:
		for v: float in [2.8, 7.1, 8.9]:
			_mpw_win(_w(-0.8, v), south, -east, 0.55, sill, sill + 1.65, MPW_GLASS)
		_mpw_win(_w(4.3, 0.0), east, -south, 0.55, sill, sill + 1.65, MPW_GLASS)
		# W3 (south corner): three narrow windows to the street, two to the south.
		for v: float in [66.0, 68.5, 71.0]:
			_mpw_win(_w(-0.8, v), south, -east, 0.45, sill, sill + 1.7, MPW_GLASS)
		for u: float in [5.0, 12.0]:
			_mpw_win(_w(u, 73.5), east, south, 0.45, sill, sill + 1.7, MPW_GLASS)
	var arms := _w(-0.85, 5.1)
	_disc(Vector3(arms.x, g + 12.4, arms.y), Vector3(-east.x, 0.0, -east.y), 0.8, 8, MPW_CREAM)
	arms = _w(-0.9, 5.1)
	_disc(Vector3(arms.x, g + 12.4, arms.y), Vector3(-east.x, 0.0, -east.y), 0.5, 8, MPW_RED)
	# The pale yard wing north of the first hall (F's look check, 2026-11-03: "add the pale
	# bannered wing"): three storeys in pale render to MPW_LOW's eaves under a cornice, the
	# museum's doors under a cream arch, tall windows over a row of small arched ones, and the
	# white-and-red banners: two hung down its face and four flags on poles before it.
	var low := _mpw_rect(MPW_LOW[0], MPW_LOW[1], MPW_LOW[2], MPW_LOW[3])
	var eave: float = MPW_LOW[4]
	_prism(low, g - 0.6, g + eave, MPW_WHITE.darkened(0.06), Color("#55585c"), M_STONE, M_STONE)
	_prism(_mpw_rect(MPW_LOW[0], MPW_LOW[1], MPW_LOW[2] - 0.3, MPW_LOW[3]), g + eave - 0.6, g + eave, MPW_CREAM,
			Color(0, 0, 0, 0), M_STONE)
	_arch_panel(_w(14.5, 0.3), east, -south, 3.6, g + 0.0, g + 3.4, MPW_CREAM.lightened(0.05), 0.04, M_STONE)
	for u: float in [12.4, 14.5, 16.6]:
		_arch_panel(_w(u, 0.3), east, -south, 0.7, g + 0.0, g + 2.1, MIROWSKA_DOOR, 0.08, M_GLASS)
	for k in 9:
		var wu := 22.0 + 3.5 * k
		_mpw_win(_w(wu, 0.3), east, -south, 0.35, 3.0, 4.2, MPW_GLASS, MPW_CREAM.darkened(0.12))
		for sill: float in [5.6, 8.9]:
			_mpw_win(_w(wu, 0.3), east, -south, 0.55, sill, sill + 2.0, MPW_GLASS, MPW_CREAM.darkened(0.12))
	for bu: float in [20.2, 51.0]:
		_lbox(bu + 0.45, 0.22, 0.45, 0.04, g + 4.6, g + eave - 0.9, MPW_WHITE, M_STONE, MPW_WHITE)
		_lbox(bu - 0.45, 0.22, 0.45, 0.04, g + 4.6, g + eave - 0.9, MPW_RED.lightened(0.15), M_STONE, MPW_RED)
	for k in 4:
		var fp := _w(26.0 + 6.0 * k, -2.6)
		_beam(Vector3(fp.x, g, fp.y), Vector3(fp.x, g + 9.5, fp.y), 0.12, MPW_WHITE)
		_mpw_flag(fp, g + 9.2, 2.2)
	# The halls behind, the red grids on their park gables, their windows and doors.
	for h: Array in MPW_HALLS:
		_mpw_hall(h)
	_mpw_grid(57.7, 4.5, 23.0, 12.0, 17.0)
	_mpw_grid(57.7, 27.0, 45.0, 11.0, 15.0)
	_mode = M_GLASS
	_wall(_w(57.75, 12.5), _w(57.75, 15.5), g, g + 4.0, east, MIROWSKA_DOOR)
	_mode = M_STONE
	for v: float in [8.5, 18.5]:
		_mpw_win(_w(57.7, v), south, east, 0.4, 6.5, 8.5, MPW_GLASS, MPW_CREAM)
	for u: float in [21.0, 26.4, 31.8, 37.2, 46.0, 52.0]:
		_mpw_win(_w(u, 44.5 if u < 40.6 else 45.0), east, south, 0.7, 3.2, 6.8, MPW_GLASS, MPW_CREAM)
	# The light strip on W2's flat roof.
	_prism(_mpw_rect(8.0, 11.0, 14.0, 61.0), g + 15.5, g + 15.8, Color("#b8bcbf"), Color("#b8bcbf"), M_STONE, M_STONE)
	_mpw_tower()
	_collide(ring)
	# The grounds.
	_mpw_office_block()
	_mpw_gatehouse()
	_mpw_kasa()
	_mpw_fence()
	_mpw_tobruk()
	_mpw_wall_of_remembrance()


## A white-over-red flag hanging from a pole at `p`, its top at `y`, flown along east.
func _mpw_flag(p: Vector2, y: float, flen: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var q := p + _a * flen
	var h := flen * 0.3
	var n := Vector3(-_b.x, 0.0, -_b.y)
	for side: float in [1.0, -1.0]:
		_quad(Vector3(p.x, y, p.y), Vector3(q.x, y, q.y), Vector3(q.x, y - h, q.y), Vector3(p.x, y - h, p.y), n * side, MPW_WHITE)
		_quad(Vector3(p.x, y - h, p.y), Vector3(q.x, y - h, q.y), Vector3(q.x, y - 2.0 * h, q.y), Vector3(p.x, y - 2.0 * h, p.y),
				n * side, MPW_RED.lightened(0.15))
	_mode = keep


## The observation tower (2004): a steel frame to 14 m, the concrete shaft to the platform at
## 28 m, its east face a wedge leaning out to 1.5 m with the white Kotwica; the black mesh
## platform, the cabin to 31.5 m and the flag at 36 m. Lit blue-white under the platform at night.
func _mpw_tower() -> void:
	_mpw_frame()
	var g := _g
	var east := _a
	var t: Array = MPW_TOWER
	var u0: float = t[0]
	var u1: float = t[1]
	var v0: float = t[2]
	var v1: float = t[3]
	var vc := (v0 + v1) * 0.5
	# the steel frame: four corner columns, crossed braces on the two open faces above the roofs
	for c: Vector2 in [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]:
		var p := _w(c.x, c.y)
		_beam(Vector3(p.x, g, p.y), Vector3(p.x, g + 14.2, p.y), 0.4, Color("#4a4846"))
	for f: Array in [[Vector2(u1, v0), Vector2(u1, v1)], [Vector2(u0, v0), Vector2(u1, v0)], [Vector2(u0, v1), Vector2(u1, v1)]]:
		var a := _w(f[0].x, f[0].y)
		var b := _w(f[1].x, f[1].y)
		# the two braces of a cross a beam's width apart, so their faces never share a plane
		var off := (a + b) * 0.5 - _w((u0 + u1) * 0.5, vc)
		off = off.normalized() * 0.3
		_beam(Vector3(a.x + off.x, g + 10.5, a.y + off.y), Vector3(b.x + off.x, g + 14.0, b.y + off.y), 0.22, Color("#4a4846"))
		_beam(Vector3(b.x + off.x * 2.0, g + 10.5, b.y + off.y * 2.0), Vector3(a.x + off.x * 2.0, g + 14.0, a.y + off.y * 2.0), 0.22,
				Color("#4a4846"))
	_prism(_mpw_rect(u0 + 2.0, u1 - 2.0, v0 + 2.0, v1 - 2.0), g, g + 14.0, MPW_CONCRETE.darkened(0.15), Color(0, 0, 0, 0), M_STONE, M_STONE)
	# the shaft and the wedge on its east face
	_prism(_mpw_rect(u0, u1, v0, v1), g + 14.0, g + 27.5, MPW_CONCRETE, MPW_CONCRETE, M_STONE, M_STONE)
	var w0 := _mpw_rect(u1, u1 + 0.05, vc - 3.5, vc + 3.5)
	var w1 := _mpw_rect(u1, u1 + 1.5, vc - 3.5, vc + 3.5)
	_frustum(w0, g + 12.0, w1, g + 27.5, MPW_CONCRETE.lightened(0.04), MPW_CONCRETE)
	# the Kotwica on the wedge: the P on the stem, the W of the anchor's arms below
	var n3 := Vector3(east.x * 15.5, -1.5, east.y * 15.5).normalized()
	var face := func(s: float, y: float, proud: float) -> Vector3:
		var lean := 1.5 * (y - 12.0) / 15.5
		var p := _w(u1 + lean, vc - s)
		return Vector3(p.x, g + y, p.y) + n3 * proud
	var strokes := [
		[Vector2(0.0, -1.0), Vector2(0.0, 2.1), 0.04],
		[Vector2(0.0, 2.1), Vector2(0.8, 2.0), 0.07], [Vector2(0.8, 2.0), Vector2(1.05, 1.5), 0.1],
		[Vector2(1.05, 1.5), Vector2(0.8, 1.0), 0.07], [Vector2(0.8, 1.0), Vector2(0.0, 0.9), 0.1],
		[Vector2(-1.5, -0.6), Vector2(-0.8, -2.1), 0.07], [Vector2(-0.8, -2.1), Vector2(0.0, -1.0), 0.1],
		[Vector2(0.0, -1.0), Vector2(0.8, -2.1), 0.07], [Vector2(0.8, -2.1), Vector2(1.5, -0.6), 0.1],
	]
	for st_: Array in strokes:
		var p: Vector2 = st_[0] * 1.3
		var q: Vector2 = st_[1] * 1.3
		var pr: float = st_[2]
		var d := (q - p).normalized()
		var side := Vector2(-d.y, d.x) * 0.26
		var ext := d * 0.12
		var a := p - ext
		var b := q + ext
		_quad(face.call(a.x + side.x, 20.0 + a.y + side.y, pr), face.call(b.x + side.x, 20.0 + b.y + side.y, pr),
				face.call(b.x - side.x, 20.0 + b.y - side.y, pr), face.call(a.x - side.x, 20.0 + a.y - side.y, pr), n3, MPW_WHITE)
	# the platform on its cantilever, the mesh rail, the cabin, the light under it, the flag
	var pu0 := u0 - 2.0
	var pv1 := v1 + 1.0
	_prism(_mpw_rect(pu0, u1, v0, pv1), g + 27.5, g + 28.0, MPW_STEEL, MPW_STEEL.lightened(0.1), M_STONE, M_STONE)
	_parapet(_mpw_rect(pu0, u1, v0, pv1), g + 28.0, 1.1, MPW_STEEL)
	var cu := (pu0 + u1) * 0.5
	var cv := (v0 + pv1) * 0.5
	_prism(_mpw_rect(cu - 2.5, cu + 2.5, cv - 2.5, cv + 2.5), g + 28.0, g + 31.5, MPW_STEEL, MPW_STEEL.darkened(0.1), M_STONE, M_STONE)
	_mode = M_LAMP
	_prism(_mpw_rect(pu0 + 1.0, u1 - 1.0, v0 + 1.0, pv1 - 1.0), g + 27.2, g + 27.5, Color("#bfd8ff"), Color(0, 0, 0, 0), M_LAMP, M_LAMP)
	_mode = M_STONE
	var pole := _w(cu, cv)
	_beam(Vector3(pole.x, g + 31.5, pole.y), Vector3(pole.x, g + 36.0, pole.y), 0.15, Color("#d8d8d4"))
	var f0 := _w(cu, cv + 0.08)
	var f1 := _w(cu, cv + 2.6)
	for k in 2:
		var y0 := g + 35.2 - 0.8 * k
		var col := Color.WHITE if k == 0 else Color("#d4213d")
		for nn: Vector2 in [east, -east]:
			_quad(Vector3(f0.x, y0 - 0.8, f0.y), Vector3(f1.x, y0 - 0.8, f1.y), Vector3(f1.x, y0, f1.y), Vector3(f0.x, y0, f0.y),
					Vector3(nn.x, 0.0, nn.y), col)


## The power station's office block (now the museum's offices): four storeys in brick with cream
## pilaster strips between the window columns, an orange tiled hipped roof, two chimneys.
func _mpw_office_block() -> void:
	_o = MPW_OFFICE
	_a = MPW_OFFICE_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var ring := _mpw_office()
	_g = _ground_under(ring)
	var g := _g
	_prism(ring, g - 0.6, g + 12.5, MPW_BRICK, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_hip(0.0, 0.0, 11.3, 6.9, g + 12.5, 4.5, MPW_TILE)
	for side: Array in [[11.0, 6.6, _b, _a], [11.0, -6.6, -_b, _a], [6.6, 11.0, _a, _b], [6.6, -11.0, -_a, _b]]:
		var half: float = side[0]
		var at: float = side[1]
		var out: Vector2 = side[2]
		var along: Vector2 = side[3]
		var base := _o + out * absf(at)
		var cols := floori(half * 2.0 / 3.2)
		var t0 := -cols * 1.6
		for k in cols + 1:
			var s := t0 + 3.2 * k
			var p := base + out * 0.03 + along * s
			_wall(p - along * 0.6, p + along * 0.6, g + 0.4, g + 12.3, out, Color("#a8a29a"))
		_mode = M_GLASS
		for k in cols:
			var s := t0 + 3.2 * k + 1.6
			var p := base + out * 0.06 + along * s
			for sill: float in [1.0, 4.3, 7.6, 10.4]:
				_wall(p - along * 0.5, p + along * 0.5, g + sill, g + sill + 1.6, out, Color("#4a3a32"))
		_mode = M_STONE
	for s: float in [-6.0, 6.0]:
		_lbox(s, 1.5, 0.45, 0.45, g + 14.0, g + 17.8, MPW_BRICK, M_STONE, MPW_BAND)
	_collide(ring)


## The gatehouse at the gate: brick, a dark metal gable, three stepped pinnacles with tile caps.
func _mpw_gatehouse() -> void:
	var r := MPW_GATEHOUSE
	_o = Vector2.ZERO
	_a = Vector2.RIGHT
	_b = Vector2.DOWN
	var ring := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	_g = _ground_under(ring)
	var g := _g
	var cz := r.get_center().y
	_prism(ring, g - 0.6, g + 3.5, MPW_BRICK, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_gable(r.end.x, r.position.x, cz, r.size.y * 0.5, g + 3.5, 3.0, MPW_BRICK, MPW_ROOF_DARK)
	for p: Vector2 in [Vector2(r.position.x + 0.3, cz), Vector2(r.end.x - 0.3, cz), Vector2(r.get_center().x, r.position.y + 0.3)]:
		_pinnacle(p.x, p.y, 0.55, g + 3.0, 4.5, MPW_BRICK)
	_collide(ring)


## The KASA (ticket) pavilion in the yard: brick, a grey metal gable, three blind arches round
## the door on its yard (north) end.
func _mpw_kasa() -> void:
	var r := MPW_KASA
	_o = Vector2.ZERO
	_a = Vector2.DOWN
	_b = Vector2.RIGHT
	var ring := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	_g = _ground_under(ring)
	var g := _g
	var cx := r.get_center().x
	_prism(ring, g - 0.6, g + 3.2, MPW_BRICK, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_gable(r.position.y, r.end.y, cx, r.size.x * 0.5, g + 3.2, 2.3, MPW_BRICK, Color("#7e8790"))
	for s: float in [-2.2, 0.0, 2.2]:
		_arch_panel(Vector2(cx + s, r.position.y), Vector2.RIGHT, Vector2.UP, 0.75, g + 0.2, g + 2.4,
				MPW_CREAM if s != 0.0 else MPW_CREAM.darkened(0.05), 0.04, M_STONE)
	_arch_panel(Vector2(cx, r.position.y), Vector2.RIGHT, Vector2.UP, 0.55, g + 0.0, g + 2.0, MIROWSKA_DOOR, 0.08, M_GLASS)
	_collide(ring)


## The brick fence on Przyokopowa: a low wall with a cream coping, pinnacled posts every 6.5 m,
## black railings; the black steel gate north of the museum and the line north of the gatehouse.
func _mpw_fence() -> void:
	_o = Vector2.ZERO
	_a = Vector2.RIGHT
	_b = Vector2.DOWN
	var west := func(z: float) -> Vector2:
		return Vector2(MPW_O.x - 3.0 + (z - MPW_O.y) * MPW_B.x, z)
	for run: Array in [[155.0, 235.0], [114.0, 142.0]]:
		var p0: Vector2 = west.call(run[0])
		var p1: Vector2 = west.call(run[1])
		_g = _ground_under(PackedVector2Array([p0, p1]))
		var g := _g
		var d := (p1 - p0).normalized()
		var n := Vector2(-d.y, d.x)
		var band := PackedVector2Array([p0 - n * 0.2, p1 - n * 0.2, p1 + n * 0.2, p0 + n * 0.2])
		_prism(band, g - 0.4, g + 1.2, MPW_BRICK, MPW_CREAM, M_STONE, M_STONE)
		var length := p0.distance_to(p1)
		var posts := ceili(length / 6.5)
		for k in posts + 1:
			var p := p0 + d * (length * k / posts)
			_prism(_square(p, 0.25), g - 0.4, g + 2.0, MPW_BRICK, Color(0, 0, 0, 0), M_STONE, M_STONE)
			_pyramid(_square(p, 0.3), g + 2.0, g + 2.5, MPW_BRICK.darkened(0.08))
		_beam(Vector3(p0.x, g + 2.35, p0.y), Vector3(p1.x, g + 2.35, p1.y), 0.08, MPW_STEEL)
		var bars := floori(length / 1.6)
		for k in range(1, bars):
			var p := p0 + d * (length * k / bars)
			for side: float in [-1.0, 1.0]:
				_wall(p - d * 0.03, p + d * 0.03, g + 1.2, g + 2.35, n * side, MPW_STEEL)
		_collide(PackedVector2Array([p0, p1]))
	# the gate between the two runs, on its brick posts
	var q0: Vector2 = west.call(148.0)
	var q1: Vector2 = west.call(155.0)
	_g = _ground_under(PackedVector2Array([q0, q1]))
	var gg := _g
	for p: Vector2 in [q0, q1]:
		_prism(_square(p, 0.35), gg - 0.4, gg + 3.5, MPW_BRICK, Color(0, 0, 0, 0), M_STONE, M_STONE)
		_pyramid(_square(p, 0.42), gg + 3.5, gg + 4.1, MPW_BRICK.darkened(0.08))
	var e := (q1 - q0).normalized()
	var m := Vector2(-e.y, e.x)
	_prism(PackedVector2Array([q0 + e * 0.35 - m * 0.08, q1 - e * 0.35 - m * 0.08, q1 - e * 0.35 + m * 0.08, q0 + e * 0.35 + m * 0.08]),
			gg, gg + 2.5, Color("#313133"), Color("#313133"), M_STONE, M_STONE)


## The Tobruk (Ringstand 58c) in the park: a low round concrete shell with its gun opening.
func _mpw_tobruk() -> void:
	_g = _ground_under(_circle(MPW_TOBRUK, 1.8, 8))
	var g := _g
	_frustum(_circle(MPW_TOBRUK, 1.8, 8), g - 0.2, _circle(MPW_TOBRUK, 1.0, 8), g + 0.7, Color("#8d8b84"), Color("#8d8b84"))
	_prism(_circle(MPW_TOBRUK, 0.45, 8), g + 0.7, g + 0.72, Color("#2a2a28"), Color("#2a2a28"), M_STONE, M_STONE)


## The Wall of Remembrance (Mur Pamięci) in Freedom Park: a gently curved black granite wall,
## 4 m high and about 120 m long, the names of the fallen on it; the bell "Monter" in its recess.
func _mpw_wall_of_remembrance() -> void:
	var band := _mpw_wall_band(0.3)
	_g = _ground_under(band)
	var g := _g
	_prism(band, g - 0.5, g + 4.0, MPW_GRANITE, MPW_GRANITE.lightened(0.1), M_STONE, M_STONE)
	_collide(band)
	# the recess on the museum (west) side and the bell in it
	var p2: Vector2 = MPW_WALL[2]
	var p3: Vector2 = MPW_WALL[3]
	var d := (p3 - p2).normalized()
	var n := Vector2(-d.y, d.x)
	if n.x > 0.0:
		n = -n
	var c := p2 + d * (MPW_BELL - p2).dot(d)
	_mode = M_GLASS
	_wall(c + n * 0.33 - d * 0.9, c + n * 0.33 + d * 0.9, g + 1.1, g + 3.3, n, Color("#141516"))
	_mode = M_STONE
	var b := c + n * 0.75
	_frustum(_circle(b, 0.22, 8), g + 2.35, _circle(b, 0.42, 8), g + 1.45, Color("#4a3f36"), Color("#4a3f36"))
	_prism(_circle(b, 0.1, 6), g + 2.35, g + 3.0, MPW_STEEL, Color(0, 0, 0, 0), M_STONE, M_STONE)


# --- Wola's "19. Dzielnica": the Kolejowa estate, Asbud's towers, the old drug works' building site ---

## The building site's frame: u along Kasprzaka (east), v into the plot (south).
const D19_O := Vector2(-3089.0, 552.0)
const D19_A := Vector2(0.9856, -0.1705)
const D19_B := Vector2(0.1705, 0.9856)
## The drug works' plot (OpenStreetMap's `construction` outline, simplified) and the strip south of
## it where the estate's last stage stands as frames (to the diagonal street's kerb).
const NOHO_PLOT := [Vector2(-3089.0, 552.0), Vector2(-2904.0, 520.0), Vector2(-2878.0, 650.0), Vector2(-2924.0, 665.0),
		Vector2(-2983.0, 684.0), Vector2(-3026.0, 719.0), Vector2(-3062.0, 726.0)]
const NOHO_STRIP := [Vector2(-2880.0, 653.0), Vector2(-2873.0, 694.0), Vector2(-2990.0, 744.0), Vector2(-3024.0, 723.0),
		Vector2(-2983.0, 688.0), Vector2(-2944.0, 676.0), Vector2(-2924.0, 669.0)]
## Gates in the hoarding: [ring (0 plot, 1 strip), edge index, from, to] in metres along the edge.
const NOHO_GATES := [[0, 0, 92.0, 104.0], [0, 1, 60.0, 70.0], [1, 0, 16.0, 24.0]]
## Frames: [u0, u1, v0, v1, floors, glazed floors, cascade floors, slab overhang].
const NOHO_FRAMES := [
	# F's Kasprzaka photos (2026-10-26): both blocks topped out at 11 storeys, the cascade's stepped
	# terraces on top, windows in, wrapped in scaffolding with red and white boards.
	[150.0, 182.0, 22.0, 118.0, 11, 10, 3, 0.0, true],   # the long block on the east street
	[70.0, 138.0, 9.0, 27.0, 11, 10, 3, 0.0, true],      # the block on Kasprzaka, its cores ahead
	[70.0, 120.0, 161.0, 187.0, 8, 3, 0, 1.4],    # the estate's last stage (Street View): balconies
	[136.0, 180.0, 149.0, 172.0, 8, 3, 0, 1.4],
]
## The Kasprzaka block's two cores, rising past its floors: [u, v, half size, floors].
const NOHO_CORES := [[86.0, 18.0, 3.2, 12], [122.0, 18.0, 3.2, 12]]
## Cranes: [u, v, mast height, jib angle (deg, from +u), jib length, counter-jib length, colour].
const NOHO_CRANES := [[143.0, 72.0, 46.0, 200.0, 46.0, 12.0, "#4f8a3c"], [104.0, 38.0, 42.0, 110.0, 40.0, 11.0, "#c8322e"],
		[127.0, 167.0, 38.0, 330.0, 36.0, 10.0, "#d9d6cf"]]
## The yard: pallet blocks [u, v, half u, half v, height, colour].
const NOHO_STACKS := [
	[66.0, 58.0, 3.0, 2.2, 1.9, "#eef0f1"], [74.0, 58.0, 3.0, 2.2, 2.3, "#eef0f1"], [82.0, 58.0, 3.0, 2.2, 1.6, "#e9a3ae"],
	[90.0, 58.0, 3.0, 2.2, 2.2, "#eef0f1"], [66.0, 66.0, 3.0, 2.2, 2.4, "#eef0f1"], [74.0, 66.0, 3.0, 2.2, 1.7, "#e48a3c"],
	[82.0, 66.0, 3.0, 2.2, 2.1, "#eef0f1"], [90.0, 66.0, 3.0, 2.2, 1.8, "#eef0f1"],
	[104.0, 78.0, 2.6, 2.0, 1.6, "#7cc0ea"], [110.0, 78.0, 2.6, 2.0, 2.0, "#7cc0ea"], [116.0, 78.0, 2.6, 2.0, 1.4, "#7cc0ea"],
	[104.0, 85.0, 2.6, 2.0, 1.2, "#7cc0ea"], [110.0, 85.0, 2.6, 2.0, 1.8, "#7cc0ea"],
	[128.0, 52.0, 2.4, 1.6, 1.5, "#a9a6a0"], [128.0, 57.0, 2.4, 1.6, 1.1, "#a9a6a0"], [128.0, 62.0, 2.4, 1.6, 1.4, "#e8d8a8"],
	[96.0, 96.0, 3.5, 1.2, 0.6, "#5f6266"], [96.0, 100.0, 3.5, 1.2, 0.9, "#8a6a4c"],
	[140.0, 108.0, 1.6, 1.6, 2.2, "#eef0f1"], [144.0, 103.0, 1.6, 1.6, 1.7, "#7cc0ea"],
]
## Sand and spoil heaps: [u, v, half u, half v, height].
const NOHO_HEAPS := [[40.0, 128.0, 9.0, 6.0, 3.6], [62.0, 138.0, 6.0, 5.0, 2.6], [22.0, 104.0, 5.0, 4.0, 2.0]]
const NOHO_SAND := Color("#c9b083")
const NOHO_CONCRETE := Color("#b8b5ae")
const NOHO_SLAB_EDGE := Color("#a9a69f")
const NOHO_GLASS := Color("#3e5560")
const NOHO_RAIL := Color("#d8c23a")      # the yellow edge barriers and their tags
const NOHO_HOARD := Color("#454c53")     # the navy boards with the name
const NOHO_FENCE := Color("#8e9497")     # galvanised mesh panels elsewhere
const NOHO_CABIN := Color("#eceeef")
const NOHO_CABIN_RED := Color("#c8322e")
const NOHO_FLOOR := 3.2                  # storey height of the frames
const NOHO_BAY := 8.0                    # column spacing round a frame's edge
const NOHO_CAR_COLS := ["#e9ebed", "#2b2d31", "#8e9499", "#3b5f8f", "#a33a32", "#c9ccd0", "#4b4f55"]

## The estate (spec dzielnica19.md): everything mapped inside D19_ESTATE is rebuilt here.
const D19_ESTATE := [Vector2(-3082.0, 775.0), Vector2(-2995.0, 770.0), Vector2(-2870.0, 714.0), Vector2(-2805.0, 690.0),
		Vector2(-2790.0, 705.0), Vector2(-2770.0, 760.0), Vector2(-2745.0, 800.0), Vector2(-2752.0, 840.0),
		Vector2(-2880.0, 882.0), Vector2(-3000.0, 915.0), Vector2(-3045.0, 905.0), Vector2(-3045.0, 830.0), Vector2(-3085.0, 815.0)]
## The dark grid look: blocks whose middle lies east of this x and south of this z (the east green).
const D19_GRID_FROM := Vector2(-2880.0, 735.0)
const D19_CREAM := Color("#dfcdb0")
const D19_RUST := Color("#94573a")
const D19_PANE := Color("#2c343b")
const D19_BRONZE := Color("#7b6450")
const D19_CHARCOAL := Color("#3f4245")
const D19_WHITE := Color("#eceae4")
const D19_ROOF := Color("#b9b7b1")
const D19_GARDEN := Color("#7f9b58")
const D19_SHOP := Color("#2f383f")
## Asbud's quarter by the towers (spec dzielnica19.md): everything mapped inside is rebuilt.
const ASBUD_ZONE := [Vector2(-2882.0, 528.0), Vector2(-2776.0, 526.0), Vector2(-2770.0, 560.0), Vector2(-2738.0, 617.0),
		Vector2(-2740.0, 656.0), Vector2(-2808.0, 656.0), Vector2(-2870.0, 640.0), Vector2(-2884.0, 600.0)]
const ASBUD_GLASS := Color("#2f4d6c")
const ASBUD_GOLD := Color("#c9a24c")
const ASBUD_ORANGE := Color("#d5562a")
const ASBUD_STONE := Color("#e4e1da")
const ASBUD_SIGN := Color(0.35, 1.0, 0.45)
## The pattern of the estate's punched windows (building.gdshader S_PUNCHED): one every 3.2 m along
## the front, 2.95 m storeys, the pane from 0.3 to 0.775 of the storey.
const D19_BAY := 3.2
const D19_STOREY := 2.95


func _d19_frame_set() -> void:
	_o = D19_O
	_a = D19_A
	_b = D19_B


## The ground under a spot of the building site's frame (the plot is not flat: the laser scan's
## ground rises a few metres in its middle, so each piece stands on its own spot).
func _gy(u: float, v: float) -> float:
	var p := D19_O + D19_A * u + D19_B * v
	return map.terrain_height(p.x, p.y)


## The lowest ground under a rectangle of the frame (its corners and middle).
func _gy_rect(u0: float, u1: float, v0: float, v1: float) -> float:
	var g := _gy((u0 + u1) * 0.5, (v0 + v1) * 0.5)
	for u: float in [u0, u1]:
		for v: float in [v0, v1]:
			g = minf(g, _gy(u, v))
	return g


func _find_dzielnica19() -> void:
	var plot := PackedVector2Array(NOHO_PLOT)
	var strip := PackedVector2Array(NOHO_STRIP)
	_add_site("noho", [plot, strip])
	# The laser scan's self-sown trees on the cleared plot stay out of the yard and the frames.
	for r: PackedVector2Array in [plot, strip]:
		tree_free.append([r, 0.0, _box_of([r])])
	for spec: Array in [["d19", D19_ESTATE], ["asbud", ASBUD_ZONE]]:
		var zone := PackedVector2Array(spec[1])
		var parts: Array = []
		for bld in data["buildings"]:
			var q := _pts(bld["p"])
			if q.size() < 3:
				continue
			var c := _centre(q)
			if not _box_of([zone]).has_point(c) or not Geometry2D.is_point_in_polygon(c, zone):
				continue
			parts.append([q, float(bld["h"]), float(bld["mh"]), str(bld["kind"])])
		if parts.is_empty():
			continue
		_add_site(spec[0], [zone])
		if not sites.is_empty() and sites[-1]["key"] == spec[0]:
			sites[-1]["parts"] = parts


# --- the building site ---

func _build_noho(_site: Dictionary) -> void:
	_d19_frame_set()
	var rings: Array[PackedVector2Array] = [PackedVector2Array(NOHO_PLOT), PackedVector2Array(NOHO_STRIP)]
	_g = minf(_ground_under(rings[0]), _ground_under(rings[1]))
	var g := _g
	# The ground stays the map's (OpenStreetMap's `construction` earth); the pieces stand on it.
	# The hoarding: navy boards along Kasprzaka (the first edge) and the east street, galvanised
	# panels elsewhere; gates left open.
	for ri in rings.size():
		var r := rings[ri]
		for i in r.size():
			var a := r[i]
			var b := r[(i + 1) % r.size()]
			var cuts: Array = []
			for gt: Array in NOHO_GATES:
				if gt[0] == ri and gt[1] == i:
					cuts.append(Vector2(gt[2], gt[3]))
			var navy := ri == 0 and (i == 0 or i == 1)
			_noho_fence(r, a, b, cuts, NOHO_HOARD if navy else NOHO_FENCE, g)
		_collide(r)
	# The name on the navy boards, every 45 m along Kasprzaka and once on the east street.
	var k := 0.9 / (Neon.ROW_H * Neon.PIXEL)
	var plot := rings[0]
	for edge: Array in [[0, [30.0, 75.0, 140.0]], [1, [30.0, 95.0]]]:
		var a := plot[edge[0]]
		var b := plot[edge[0] + 1]
		var d := (b - a).normalized()
		var o := _out(plot, a, b)
		for t: float in edge[1]:
			var p := a + d * t + o * 0.25
			var gs: float = map.terrain_height(p.x, p.y)
			signs.append(["OHO ONE", Vector3(p.x, gs + 1.3, p.y), Vector3(o.x, 0.0, o.y), k, Color(0.95, 0.96, 1.0)])
	# The frames, the cores, the foundation slab.
	for f: Array in NOHO_FRAMES:
		_noho_frame(f)
	for c: Array in NOHO_CORES:
		var gc := _gy_rect(c[0] - c[2], c[0] + c[2], c[1] - c[2], c[1] + c[2])
		_lbox(c[0], c[1], c[2], c[2], gc - 0.3, gc + NOHO_FLOOR * c[3] + 1.2, NOHO_CONCRETE.darkened(0.06), M_STONE, NOHO_CONCRETE)
	_noho_slab()
	_noho_yard()
	for c: Array in NOHO_CRANES:
		_noho_crane(c)
	_d19_frame_set()
	_mode = M_STONE


## One side of the hoarding, a→b of `ring`, 2.4 m boards 15 cm inside the edge, less the gates
## (`cuts`, metres along the edge).
func _noho_fence(ring: PackedVector2Array, a: Vector2, b: Vector2, cuts: Array, col: Color, _g0: float) -> void:
	var length := a.distance_to(b)
	var d := (b - a) / maxf(length, 0.01)
	var o := _out(ring, a, b)
	var runs: Array[Vector2] = [Vector2(0.0, length)]
	for c: Vector2 in cuts:
		var next: Array[Vector2] = []
		for r in runs:
			if c.y <= r.x or c.x >= r.y:
				next.append(r)
				continue
			if c.x > r.x:
				next.append(Vector2(r.x, c.x))
			if c.y < r.y:
				next.append(Vector2(c.y, r.y))
		runs = next
	for r in runs:
		if r.y - r.x < 0.5:
			continue
		# in pieces of up to 12 m, each on its own ground
		var n := ceili((r.y - r.x) / 12.0)
		for k in n:
			var t0 := r.x + (r.y - r.x) * k / n
			var t1 := r.x + (r.y - r.x) * (k + 1) / n
			var p0 := a + d * t0 - o * 0.15
			var p1 := a + d * t1 - o * 0.15
			var g0: float = map.terrain_height(p0.x, p0.y)
			var g1: float = map.terrain_height(p1.x, p1.y)
			var t := o * 0.06
			_prism(PackedVector2Array([p0 - t, p1 - t, p1 + t, p0 + t]), minf(g0, g1) - 0.3, maxf(g0, g1) + 2.4, col,
					col.darkened(0.15), M_STONE, M_STONE)


## A frame under construction: bare slabs on columns round the edge, yellow edge barriers, the
## lowest `glazed` floors closed in dark glass; the top `cascade` floors step back 3.5 m a floor
## on the west (the cascade's terraces); `over` lets the long sides' slabs run out as balconies.
func _noho_frame(f: Array) -> void:
	_d19_frame_set()
	var u0: float = f[0]
	var u1: float = f[1]
	var v0: float = f[2]
	var v1: float = f[3]
	var g := _gy_rect(u0, u1, v0, v1)
	_g = g
	var floors: int = f[4]
	var glazed: int = f[5]
	var cascade: int = f[6]
	var over: float = f[7]
	var none := Color(0, 0, 0, 0)
	for n in floors + 1:
		var y := g + n * NOHO_FLOOR
		# the slab of floor n steps back with the cascade; what stands on it (columns, glass) steps
		# back with the slab over it, so each step leaves a terrace
		var back := _noho_back(n, floors, cascade)
		var cu0 := u0 + back
		var cu := (cu0 + u1) * 0.5
		var cv := (v0 + v1) * 0.5
		var hu := (u1 - cu0) * 0.5
		var hv := (v1 - v0) * 0.5
		# the slab (the ground floor's is the ground itself)
		if n > 0:
			_lbox(cu, cv, hu, hv + over, y - 0.3, y, NOHO_SLAB_EDGE, M_STONE, NOHO_CONCRETE)
		if n == floors:
			break
		var top := y + NOHO_FLOOR - 0.3
		var bottom := y if n > 0 else g - 0.2
		var rail_u0 := cu0
		cu0 = u0 + _noho_back(n + 1, floors, cascade)
		cu = (cu0 + u1) * 0.5
		hu = (u1 - cu0) * 0.5
		if n < glazed:
			# closed in: a dark glazed box set 0.6 m in from the slab's edge
			_lbox(cu, cv, hu - 0.6, hv - 0.6, bottom, top, NOHO_GLASS, M_GLASS, none)
		# columns round the edge, 0.5 m in (behind the glass and the scaffolding they don't show)
		if n < glazed:
			continue
		var nu := maxi(1, roundi((hu * 2.0 - 1.0) / NOHO_BAY))
		var nv := maxi(1, roundi((hv * 2.0 - 1.0) / NOHO_BAY))
		for i in nu + 1:
			var cu_i := cu0 + 0.5 + (hu * 2.0 - 1.0) * i / nu
			for vv: float in [v0 + 0.5, v1 - 0.5]:
				_lbox(cu_i, vv, 0.25, 0.25, bottom, top, NOHO_CONCRETE, M_STONE, none)
		for j in range(1, nv):
			var cv_j := v0 + 0.5 + (hv * 2.0 - 1.0) * j / nv
			for uu: float in [cu0 + 0.5, u1 - 0.5]:
				_lbox(uu, cv_j, 0.25, 0.25, bottom, top, NOHO_CONCRETE, M_STONE, none)
		# the edge barriers on the floors still open: a 1 m mesh screen with a yellow top rail
		if n >= glazed and n > 0:
			var e := 0.15
			var ru := (rail_u0 + u1) * 0.5
			var rh := (u1 - rail_u0) * 0.5
			for vv: float in [v0 - over + e, v1 + over - e]:
				_lbox(ru, vv, rh - e, 0.04, y, y + 1.08, NOHO_RAIL.darkened(0.35), M_STONE, NOHO_RAIL)
			for uu: float in [rail_u0 + e, u1 - e]:
				_lbox(uu, cv, 0.04, hv + over - 2.0 * e, y, y + 1.08, NOHO_RAIL.darkened(0.35), M_STONE, NOHO_RAIL)
	if f.size() > 8 and f[8]:
		_noho_scaffold(u0, u1, v0, v1, g, floors + 1 - cascade)
	_collide(_rect((u0 + u1) * 0.5, (v0 + v1) * 0.5, (u1 - u0) * 0.5, (v1 - v0) * 0.5))


## Scaffolding round a block up to `levels` floors: galvanised posts every 5 m, 0.9 m out, and a
## board at each floor in red or white (the photos' scaffolding).
func _noho_scaffold(u0: float, u1: float, v0: float, v1: float, g: float, levels: int) -> void:
	var out := 0.9
	var top := g + levels * NOHO_FLOOR + 1.0
	var a0 := u0 - out
	var a1 := u1 + out
	var b0 := v0 - out
	var b1 := v1 + out
	var none := Color(0, 0, 0, 0)
	for side in 4:
		var p0: Vector2 = [Vector2(a0, b0), Vector2(a1, b0), Vector2(a1, b1), Vector2(a0, b1)][side]
		var p1: Vector2 = [Vector2(a1, b0), Vector2(a1, b1), Vector2(a0, b1), Vector2(a0, b0)][side]
		var ln := p0.distance_to(p1)
		var n := maxi(1, roundi(ln / 5.0))
		for i in n:
			var q := p0.lerp(p1, float(i) / n)
			var w := _w(q.x, q.y)
			_beam(Vector3(w.x, g - 0.2, w.y), Vector3(w.x, top, w.y), 0.08, NOHO_FENCE.lightened(0.15))
	for lv in range(1, levels + 1):
		var y := g + lv * NOHO_FLOOR + 0.7
		var col := Color("#b8473a") if lv % 2 == 1 else Color("#dcd8cf")
		_lbox((a0 + a1) * 0.5, b0, (a1 - a0) * 0.5, 0.03, y, y + 0.3, col, M_STONE, none)
		_lbox((a0 + a1) * 0.5, b1, (a1 - a0) * 0.5, 0.03, y, y + 0.3, col, M_STONE, none)
		_lbox(a0, (b0 + b1) * 0.5, 0.03, (b1 - b0) * 0.5 - 0.04, y, y + 0.3, col, M_STONE, none)
		_lbox(a1, (b0 + b1) * 0.5, 0.03, (b1 - b0) * 0.5 - 0.04, y, y + 0.3, col, M_STONE, none)


## How far the slab of floor n (0 the ground, `floors` the roof) steps back with the cascade.
func _noho_back(n: int, floors: int, cascade: int) -> float:
	return maxf(0.0, float(n - (floors + 1 - cascade))) * 3.5


## The foundation slab in the plot's south-west: a raft with starter columns and their bars.
func _noho_slab() -> void:
	var g := _gy_rect(8.0, 40.0, 116.0, 156.0)
	var none := Color(0, 0, 0, 0)
	_lbox(24.0, 136.0, 16.0, 20.0, g - 0.2, g + 0.6, NOHO_CONCRETE.darkened(0.05), M_STONE, NOHO_CONCRETE)
	for i in 5:
		for j in 6:
			var u := 10.0 + i * 7.0
			var v := 119.0 + j * 6.8
			_lbox(u, v, 0.25, 0.25, g + 0.6, g + 2.0, NOHO_CONCRETE, M_STONE, none)
			_lbox(u, v, 0.08, 0.08, g + 2.0, g + 3.1, Color("#6d4b36"), M_STONE, none)  # the bars


## The yard: pallets, cabins with the contractor's parody name, a container, a silo, cars, heaps,
## a skip and a digger.
func _noho_yard() -> void:
	var none := Color(0, 0, 0, 0)
	var g := 0.0
	for s: Array in NOHO_STACKS:
		g = _gy_rect(s[0] - s[2], s[0] + s[2], s[1] - s[3], s[1] + s[3]) + 0.1
		var c := Color(s[5])
		_lbox(s[0], s[1], s[2], s[3], g, g + s[4], c, M_STONE, c.lightened(0.05))
		_lbox(s[0], s[1], s[2] - 0.1, s[3] - 0.1, g - 0.05, g + 0.15, Color("#8a6a4c"), M_STONE, none)  # the pallets
	# The site office: two storeys of cabins along the gate road, white with a red band.
	g = _gy_rect(52.0, 80.0, 35.0, 41.0) + 0.1
	for i in 10:
		var u := 54.0 + i * 2.6
		for lv in 2:
			var y := g + lv * 2.8
			_lbox(u, 38.0, 1.25, 3.0, y, y + 2.75, NOHO_CABIN, M_STONE, NOHO_CABIN.darkened(0.08))
		_lbox(u, 38.0, 1.27, 3.02, g + 5.0, g + 5.5, NOHO_CABIN_RED, M_STONE, NOHO_CABIN_RED)
	var face := _w(67.0, 34.9)
	var k := 0.6 / (Neon.ROW_H * Neon.PIXEL)
	signs.append(["ATLAS WIATR", Vector3(face.x, g + 4.4, face.y), Vector3(-_b.x, 0.0, -_b.y), k, Color(1.0, 0.25, 0.2)])
	# A blue container, a silo on legs by the long frame, a skip.
	g = _gy_rect(126.8, 129.2, 89.0, 95.0) + 0.1
	_lbox(128.0, 92.0, 1.2, 3.0, g, g + 2.6, Color("#2f5e9e"), M_STONE)
	var silo := _w(146.0, 122.0)
	g = _gy_rect(144.0, 148.0, 120.0, 124.0) + 0.1
	for q: Vector2 in [Vector2(-1.1, -1.1), Vector2(1.1, -1.1), Vector2(1.1, 1.1), Vector2(-1.1, 1.1)]:
		_prism(_square(silo + q, 0.12), g, g + 3.2, Color("#9aa0a4"), none, M_STONE)
	_prism(_circle(silo, 1.5, 8), g + 3.2, g + 11.0, Color("#e9ebe8"), Color("#d9dbd8"), M_STONE, M_STONE)
	_mode = M_STONE
	_pyramid(_circle(silo, 1.5, 8), g + 1.6, g + 3.2, Color("#d4d6d3"))
	g = _gy_rect(97.0, 103.0, 118.0, 122.0) + 0.1
	_prism(_rect(100.0, 120.0, 2.8, 1.3), g, g + 1.6, Color("#d8692e"), none, M_STONE)
	_lbox(100.0, 120.0, 2.6, 1.1, g, g + 1.2, NOHO_SAND.darkened(0.2), M_STONE, NOHO_SAND.darkened(0.2))
	# Heaps of sand and spoil.
	for h: Array in NOHO_HEAPS:
		g = _gy_rect(h[0] - h[2], h[0] + h[2], h[1] - h[3], h[1] + h[3])
		_mode = M_STONE
		_frustum(_rect(h[0], h[1], h[2], h[3]), g, _rect(h[0], h[1], h[2] * 0.3, h[3] * 0.3), g + h[4], NOHO_SAND, NOHO_SAND.lightened(0.05))
	# The workers' cars, nose to the fence in four rows (the yard photo).
	for row in 4:
		for i in 9:
			if (row * 9 + i) % 7 == 3:
				continue  # a gap now and then
			var u := 14.0 + i * 2.6
			var v := 48.0 + row * 12.0
			g = _gy_rect(u - 0.9, u + 0.9, v - 2.2, v + 2.2) + 0.05
			var c := Color(NOHO_CAR_COLS[(row * 5 + i * 3) % NOHO_CAR_COLS.size()])
			_lbox(u, v, 0.88, 2.2, g, g + 0.85, c, M_STONE, c)
			_lbox(u, v + 0.2, 0.78, 1.2, g + 0.85, g + 1.45, c.darkened(0.25), M_STONE, c)
	_noho_digger(Vector2(52.0, 150.0), 210.0)


## A small excavator by the heaps: tracks, the turning body, the cab and the boom.
func _noho_digger(at: Vector2, deg: float) -> void:
	var g := _gy_rect(at.x - 2.0, at.x + 2.0, at.y - 2.0, at.y + 2.0) + 0.05
	var p := _w(at.x, at.y)
	_o = p
	_a = Vector2.from_angle(deg_to_rad(deg) + D19_A.angle())
	_b = Vector2(-_a.y, _a.x)
	var yellow := Color("#e2b33a")
	for side: float in [-1.1, 1.1]:
		_lbox(0.0, side, 1.9, 0.4, g, g + 0.7, Color("#2f3033"), M_STONE)
	_lbox(-0.2, 0.0, 1.5, 1.2, g + 0.7, g + 1.75, yellow, M_STONE)
	_lbox(0.6, 0.6, 0.6, 0.55, g + 1.75, g + 2.95, yellow.darkened(0.1), M_STONE, Color("#3a4046"))
	_lbox(2.6, -0.4, 1.4, 0.2, g + 1.45, g + 2.05, yellow, M_STONE)
	_lbox(4.0, -0.4, 0.2, 0.2, g, g + 2.05, Color("#4a4d52"), M_STONE)
	_d19_frame_set()


## A tower crane (like TR's): a mast on a concrete foot, the slewing deck and cab, the jib and the
## counter-jib with its weights, the A-frame and its ties, a red lamp on top (lit at night).
func _noho_crane(c: Array) -> void:
	_d19_frame_set()
	var g := _gy_rect(c[0] - 2.2, c[0] + 2.2, c[1] - 2.2, c[1] + 2.2)
	var base := _w(c[0], c[1])
	var h: float = c[2]
	var col := Color(c[6])
	var steel := col if col.v < 0.8 else Color("#c8322e")  # the white crane's jib in red
	_o = base
	_a = Vector2.from_angle(deg_to_rad(c[3]) + D19_A.angle())
	_b = Vector2(-_a.y, _a.x)
	var none := Color(0, 0, 0, 0)
	_lbox(0.0, 0.0, 2.2, 2.2, g - 0.3, g + 1.2, NOHO_CONCRETE, M_STONE)
	_prism(_rect(0.0, 0.0, 0.8, 0.8), g + 1.2, g + h, col, none, M_STONE)
	_lbox(0.0, 0.0, 1.3, 1.3, g + h, g + h + 1.0, col.darkened(0.15), M_STONE)
	_lbox(1.6, -1.6, 0.9, 0.8, g + h - 1.2, g + h + 1.0, NOHO_CABIN, M_STONE)
	var jl: float = c[4]
	var cl: float = c[5]
	_lbox(jl * 0.5, 0.0, jl * 0.5, 0.5, g + h + 1.0, g + h + 2.2, steel, M_STONE)
	_lbox(-cl * 0.5, 0.0, cl * 0.5, 0.6, g + h + 1.0, g + h + 1.8, steel, M_STONE)
	_lbox(-cl + 1.6, 0.0, 1.5, 1.1, g + h - 0.6, g + h + 1.0, NOHO_CONCRETE.darkened(0.15), M_STONE)
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 0.7, 0.7), g + h + 2.2, _rect(0.0, 0.0, 0.25, 0.25), g + h + 8.0, steel, steel)
	for tie: Vector2 in [Vector2(jl * 0.7, g + h + 2.2), Vector2(-cl + 0.5, g + h + 1.8)]:
		var top := _w(0.0, 0.0)
		var end := _w(tie.x, 0.0)
		var side := _b * 0.12
		var y_top := g + h + 7.6
		var n := Vector3(end.x - top.x, tie.y - y_top, end.y - top.y).cross(Vector3(side.x, 0.0, side.y)).normalized()
		_quad(Vector3(top.x - side.x, y_top, top.y - side.y), Vector3(top.x + side.x, y_top, top.y + side.y),
				Vector3(end.x + side.x, tie.y, end.y + side.y), Vector3(end.x - side.x, tie.y, end.y - side.y),
				n if n.y > 0.0 else -n, steel.darkened(0.1))
	# The hook block, hanging two thirds out.
	var hook := _w(jl * 0.66, 0.0)
	_prism(_square(hook, 0.05), g + h - 12.0, g + h + 1.0, Color("#2c2f33"), none, M_STONE)
	_prism(_square(hook, 0.45), g + h - 13.0, g + h - 12.0, Color("#e2b33a"), Color("#e2b33a"), M_STONE, M_STONE)
	_prism(_rect(0.0, 0.0, 0.25, 0.25), g + h + 8.0, g + h + 8.6, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	_mode = M_STONE
	_d19_frame_set()


# --- the estate and Asbud's quarter ---

func _build_d19(site: Dictionary) -> void:
	_d19_blocks(site, false)


func _build_asbud(site: Dictionary) -> void:
	_d19_blocks(site, true)


## Every mapped part of the site in its look. Parts 5 m high or less from the ground are podiums
## (glazed shop fronts, a garden on top) or, mapped as `roof`, canopies; the rest are blocks.
func _d19_blocks(site: Dictionary, asbud: bool) -> void:
	_d19_seen.clear()
	_d19_fronts.clear()
	var parts: Array = site["parts"]
	var rings: Array = []
	for p: Array in parts:
		rings.append(_simplify(p[0], 0.05))
	_d19_index(rings)
	var zone: PackedVector2Array = site["zone"][0]
	_g = _ground_under(zone)
	for p: Array in parts:
		var raw: PackedVector2Array = p[0]
		# barely simplified: the parts share fronts, and only identical edges are told apart
		var ring := _simplify(raw, 0.05)
		if ring.size() < 3 or absf(_area(ring)) < 4.0:
			continue
		var g := _ground_under(ring)
		_g = g
		var h: float = p[1]
		var mh: float = p[2]
		var kind: String = p[3]
		var none := Color(0, 0, 0, 0)
		if kind == "roof":
			_prism(ring, g + h - 0.4, g + h, D19_ROOF.darkened(0.1), D19_ROOF, M_STONE, M_STONE)
			continue
		var y0 := g + (mh if mh > 3.6 else 0.0)
		var y1 := g + h
		if h <= 5.0:
			# a podium: dark shop glass, a light fascia, a garden (or the plain roof) on top
			_prism(ring, g - 0.3, y1 - 0.6, D19_SHOP, none, M_GLASS)
			_prism(ring, y1 - 0.6, y1, D19_WHITE, D19_GARDEN if absf(_area(ring)) > 600.0 else D19_ROOF, M_STONE, M_STONE)
			_collide(raw)
			pocket_rings.append(raw)
			continue
		if asbud and h > 60.0:
			_asbud_tower(ring, g, y1)
		else:
			var c := _centre(ring)
			var look := 2 if asbud else (1 if c.x > D19_GRID_FROM.x and c.y > D19_GRID_FROM.y else 0)
			_d19_block(ring, g, y0, y1, look)
		if mh <= 3.6:
			_collide(raw)
			pocket_rings.append(raw)
	_mode = M_STONE


## A block from y0 to y1 in one of the looks: 0 cream with rust window frames scattered over it,
## 1 the dark grid over bronze glass (white ends), 2 white with orange balcony stacks. A shop
## band of dark glass on the ground floor when the block stands on the ground.
func _d19_block(ring: PackedVector2Array, g: float, y0: float, y1: float, look: int) -> void:
	var none := Color(0, 0, 0, 0)
	var on_ground := y0 <= g + 0.5
	var wall_from := g + 3.6 if on_ground else y0
	if on_ground:
		# the shop fronts, 40 cm in under the floors above (and clear of a podium's own glass)
		var shop := _largest(Geometry2D.offset_polygon(ring, -0.4, Geometry2D.JOIN_MITER))
		if shop.size() >= 3:
			_prism(shop, g - 0.3, wall_from, D19_SHOP, none, M_GLASS)
	var wall := D19_CREAM if look == 0 else (D19_BRONZE if look == 1 else D19_WHITE)
	var mode := M_SKIN + float(S_PUNCHED if look != 1 else S_GOLD) / 16.0
	var run := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		var o := _out(ring, a, b)
		var d := (b - a) / maxf(length, 0.01)
		var end_wall := look == 1 and length < 14.0
		_mode = M_STONE if end_wall else mode
		_wall(a, b, wall_from, y1, o, D19_WHITE if end_wall else wall, run)
		if length >= 6.0 and not end_wall and not _d19_decorated(a, b, o):
			if look == 1:
				_d19_grid(a, d, o, length, wall_from, y1)
			else:
				_d19_frames(a, d, o, length, run, g, wall_from, y1, look)
		run += length
	_mode = M_STONE
	_cap(ring, y1, D19_ROOF)
	# a parapet line and a plant room on a big roof
	if absf(_area(ring)) > 500.0:
		var c := _centre(ring)
		if Geometry2D.is_point_in_polygon(c, ring):
			_prism(_square(c, 2.4), y1, y1 + 2.2, Color("#9b9a95"), Color("#8a8984"), M_STONE, M_STONE)


## Look 0 and 2: frames round some of S_PUNCHED's windows, 4 cm proud, the pane 8 cm proud in the
## frame. Look 0 scatters rust frames (a third of the windows); look 2 runs orange balcony panels up
## whole columns (one in six).
func _d19_frames(a: Vector2, d: Vector2, o: Vector2, length: float, run: float, g: float, y0: float, y1: float, look: int) -> void:
	var first := ceilf((run - D19_BAY * 0.5) / D19_BAY)
	var k := first
	while true:
		var centre := k * D19_BAY + D19_BAY * 0.5 - run   # along this edge
		k += 1.0
		if centre > length - 1.4:
			break
		if centre < 1.4:
			continue
		var col_hash := absi(int(k * 7919.0 + a.x * 13.0 + a.y * 7.0)) % 97
		if look == 2 and col_hash % 6 != 0:
			continue
		var lvl0 := ceili((y0 - g) / D19_STOREY)
		var lvl1 := floori((y1 - g) / D19_STOREY) - 1
		for lvl in range(lvl0, lvl1 + 1):
			if look == 0 and (col_hash * 31 + lvl * 17) % 97 > 32:
				continue
			var yb := g + lvl * D19_STOREY
			var p := a + d * centre
			if look == 0:
				_d19_plate(p, d, o, 1.45, yb + 0.4, yb + 2.7, 0.04, D19_RUST)
				_d19_plate(p, d, o, 0.95, yb + 0.88, yb + 2.29, 0.08, D19_PANE)
			else:
				_d19_plate(p, d, o, 1.5, yb + 0.15, yb + 1.05, 0.04, ASBUD_ORANGE)


## Plates already on a front (by 1.6 m cell, storey and facing): two mapped parts can share a
## front, and plates of both on one spot would flicker.
var _d19_seen := {}
## The fronts already dressed with frames or a grid, [a, b, out]: a second mapped part on the same
## front (the estate's parts overlap: a 27 m and a 31 m part on one outline) leaves it as it is.
var _d19_fronts: Array = []


## Every front of the site's parts, [a, b, out], by 8 m cell of the points along it: a plate or a
## grid band that would lie in another part's front (a neighbour standing a few cm proud) is left out.
var _d19_edges := {}


func _d19_index(rings: Array) -> void:
	_d19_edges.clear()
	for ring: PackedVector2Array in rings:
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			var length := a.distance_to(b)
			if length < 0.05:
				continue
			var e := [a, b, _out(ring, a, b)]
			var t := 0.0
			while true:
				var p := a.lerp(b, minf(t / length, 1.0))
				var key := Vector2i(floori(p.x / 8.0), floori(p.y / 8.0))
				if not _d19_edges.has(key):
					_d19_edges[key] = []
				if not (_d19_edges[key] as Array).has(e):
					_d19_edges[key].append(e)
				if t >= length:
					break
				t = minf(t + 4.0, length)


## True when the face q0-q1 (facing o) lies in some part's front (within 4 cm, same facing).
func _d19_clash(q0: Vector2, q1: Vector2, o: Vector2) -> bool:
	var d := (q1 - q0).normalized()
	var mid := (q0 + q1) * 0.5
	var key := Vector2i(floori(mid.x / 8.0), floori(mid.y / 8.0))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for e: Array in _d19_edges.get(key + Vector2i(dx, dz), []):
				if (e[2] as Vector2).dot(o) < 0.99:
					continue
				var ea: Vector2 = e[0]
				var eb: Vector2 = e[1]
				if absf((ea - q0).dot(o)) > 0.04 or absf((eb - q0).dot(o)) > 0.04:
					continue
				var t0 := minf((ea - q0).dot(d), (eb - q0).dot(d))
				var t1 := maxf((ea - q0).dot(d), (eb - q0).dot(d))
				if t1 > 0.0 and t0 < q0.distance_to(q1):
					return true
	return false


## True when another part stands back to back with the front a-b (a party wall, within 35 cm,
## facing the other way): nothing to dress, it is inside.
func _d19_party(a: Vector2, b: Vector2, o: Vector2) -> bool:
	var d := (b - a).normalized()
	var length := a.distance_to(b)
	var t := 0.0
	while t <= length:
		var p := a + d * t
		var key := Vector2i(floori(p.x / 8.0), floori(p.y / 8.0))
		for e: Array in _d19_edges.get(key, []):
			if (e[2] as Vector2).dot(o) > -0.99:
				continue
			var ea: Vector2 = e[0]
			var eb: Vector2 = e[1]
			if absf((ea - a).dot(o)) > 0.35 or absf((eb - a).dot(o)) > 0.35:
				continue
			var t0 := minf((ea - a).dot(d), (eb - a).dot(d))
			var t1 := maxf((ea - a).dot(d), (eb - a).dot(d))
			if minf(t1, length) - maxf(t0, 0.0) > 0.5 * minf(length, t1 - t0):
				return true
		t += 8.0
	return false


func _d19_decorated(a: Vector2, b: Vector2, o: Vector2) -> bool:
	if _d19_party(a, b, o):
		return true
	for f: Array in _d19_fronts:
		var fa: Vector2 = f[0]
		var fb: Vector2 = f[1]
		var fo: Vector2 = f[2]
		if fo.dot(o) < 0.995:
			continue
		# this front's ends against the dressed one's line: near it, and overlapping along it
		var fd := (fb - fa).normalized()
		var lo := minf((a - fa).dot(fd), (b - fa).dot(fd))
		var hi := maxf((a - fa).dot(fd), (b - fa).dot(fd))
		var near_a := absf((a - fa).dot(fo)) <= 0.35
		var near_b := absf((b - fa).dot(fo)) <= 0.35
		if (near_a or near_b) and hi > 0.5 and lo < fa.distance_to(fb) - 0.5:
			return true
	_d19_fronts.append([a, b, o])
	return false


## A flat plate on a front: `half` m each side of p along d, from y0 to y1, `proud` m out along o.
func _d19_plate(p: Vector2, d: Vector2, o: Vector2, half: float, y0: float, y1: float, proud: float, col: Color) -> void:
	var key := Vector4i(roundi(p.x / 1.6), roundi(p.y / 1.6), roundi(y0 / D19_STOREY), roundi(o.angle() * 4.0) * 10 + roundi(proud * 100.0))
	if _d19_seen.has(key):
		return
	_d19_seen[key] = true
	var q0 := p - d * half + o * proud
	var q1 := p + d * half + o * proud
	if _d19_clash(q0, q1, o):
		return
	var keep := _mode
	_mode = M_STONE
	var n := Vector3(o.x, 0.0, o.y)
	_quad(Vector3(q0.x, y0, q0.y), Vector3(q1.x, y0, q1.y), Vector3(q1.x, y1, q1.y), Vector3(q0.x, y1, q0.y), n, col)
	_mode = keep


## A fin on a front: `half` m each side of p along d, from y0 to y1, `proud` m out along o, with
## its two sides and its top (so it reads as a solid strip from the side).
func _d19_fin(p: Vector2, d: Vector2, o: Vector2, half: float, y0: float, y1: float, proud: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var w0 := p - d * half
	var w1 := p + d * half
	var q0 := w0 + o * proud
	var q1 := w1 + o * proud
	if _d19_clash(q0, q1, o):
		_mode = keep
		return
	_quad(Vector3(q0.x, y0, q0.y), Vector3(q1.x, y0, q1.y), Vector3(q1.x, y1, q1.y), Vector3(q0.x, y1, q0.y), Vector3(o.x, 0.0, o.y), col)
	_quad(Vector3(w0.x, y0, w0.y), Vector3(q0.x, y0, q0.y), Vector3(q0.x, y1, q0.y), Vector3(w0.x, y1, w0.y), Vector3(-d.x, 0.0, -d.y), col.darkened(0.12))
	_quad(Vector3(q1.x, y0, q1.y), Vector3(w1.x, y0, w1.y), Vector3(w1.x, y1, w1.y), Vector3(q1.x, y1, q1.y), Vector3(d.x, 0.0, d.y), col.darkened(0.12))
	_quad(Vector3(w0.x, y1, w0.y), Vector3(w1.x, y1, w1.y), Vector3(q1.x, y1, q1.y), Vector3(q0.x, y1, q0.y), Vector3.UP, col.lightened(0.06))
	_mode = keep


## Look 1: the charcoal grid over the bronze glass: a floor band every 3 m and a pier every 6 m,
## 25 cm proud (fronts and tops; the band's underside is in shadow).
func _d19_grid(a: Vector2, d: Vector2, o: Vector2, length: float, y0: float, y1: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var y := y0 + 3.0
	var band_ok := not _d19_clash(a + o * 0.25, a + d * length + o * 0.25, o)
	while y < y1 - 1.0 and band_ok:
		var q0 := a + o * 0.25
		var q1 := a + d * length + o * 0.25
		_quad(Vector3(q0.x, y, q0.y), Vector3(q1.x, y, q1.y), Vector3(q1.x, y + 0.45, q1.y), Vector3(q0.x, y + 0.45, q0.y),
				Vector3(o.x, 0.0, o.y), D19_CHARCOAL)
		# the top, kept 26 cm short of each corner so two fronts' tops never overlap there
		var b0 := a + d * 0.26
		var b1 := a + d * (length - 0.26)
		var c0 := b0 + o * 0.25
		var c1 := b1 + o * 0.25
		_quad(Vector3(b0.x, y + 0.45, b0.y), Vector3(b1.x, y + 0.45, b1.y), Vector3(c1.x, y + 0.45, c1.y),
				Vector3(c0.x, y + 0.45, c0.y), Vector3.UP, D19_CHARCOAL.lightened(0.08))
		y += 3.0
	var n := maxi(1, roundi(length / 6.0))
	for i in range(1, n):
		var p := a + d * (length * i / n)
		_d19_fin(p, d, o, 0.22, y0, y1, 0.34, D19_CHARCOAL)
	_mode = keep


## A Towarowa Tower: dark blue glass, an orange base, a white stone spine on its longest front,
## staggered frames (orange low, gold high) that run 4.5 m past the roof as an open crown, and
## the parody ASBUDKA on the crown.
func _asbud_tower(raw: PackedVector2Array, g: float, y1: float) -> void:
	var ring := _simplify(raw, 1.5)
	var none := Color(0, 0, 0, 0)
	_prism(ring, g - 0.3, g + 5.4, D19_SHOP, none, M_GLASS)
	_prism(ring, g + 5.4, g + 7.6, ASBUD_ORANGE, none, M_STONE)
	_prism(ring, g + 7.6, y1, ASBUD_GLASS, Color("#4a4d52"), M_SKIN + float(S_DARK) / 16.0, M_STONE)
	var longest := 0
	for i in ring.size():
		if ring[i].distance_to(ring[(i + 1) % ring.size()]) > ring[longest].distance_to(ring[(longest + 1) % ring.size()]):
			longest = i
	var crown := y1 + 4.5
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 6.0:
			continue
		var o := _out(ring, a, b)
		var d := (b - a) / length
		if i == longest:
			# the spine: a stone band a fifth of the way along, full height
			var s := a + d * length * 0.22
			_d19_plate(s, d, o, 2.2, g + 7.6, y1 + 0.6, 0.06, ASBUD_STONE)
		var n := maxi(2, roundi(length / 4.2))
		for j in range(1, n):
			var p := a + d * (length * j / n)
			if i == longest and absf(length * j / n - length * 0.22) < 3.0:
				continue
			# frames in 3-storey pieces, every other piece shifted, orange up to 40 %
			var y := g + 7.6 + (3.2 if j % 2 == 0 else 0.0)
			while y < y1 - 1.0:
				var top := minf(y + 9.6, y1)
				var col := ASBUD_ORANGE if (y - g) < (y1 - g) * 0.4 else ASBUD_GOLD
				_d19_fin(p, d, o, 0.22, y, top - 0.4, 0.3, col)
				y += 12.8
			_d19_fin(p, d, o, 0.22, y1, crown, 0.3, ASBUD_GOLD)
	_crown_signs(ring, crown + 1.0, "ASBUDKA", ASBUD_SIGN, 3.6, 0.45)


# --- Stacja Muzeum (Warszawa Główna's railway museum, Towarowa 3) and Nocny Targ on its old platform ---

## From the Mac's 19 Commons photos (~/Documents/warsaw-needed-photos/stacja-muzeum{,-claude}/,
## spec docs/landmarks/specs/stacja_muzeum.md). The hall is OpenStreetMap's L at Towarowa: the
## barrel-roofed hall at its north end shows Towarowa a cream gable with a segmental-arch top,
## eight pilasters and gold WARSZAWA GŁÓWNA letters over a red-brown canopy and wide steps; a long
## low wing under a dark hipped roof runs south along the street. The museum's four sidings hold
## its locomotives: black steam engines on red wheels, green tank engines, the streamlined green
## Pm3, a green electric and a row of grey coaches; a water crane and lamps on the platform.
## Frame: u along Towarowa from the hall's north corner (south), v into the yard (west).
const SM_O := Vector2(-2508.0, 832.0)
const SM_A := Vector2(0.419, 0.908)
const SM_B := Vector2(-0.908, 0.419)
## The four sidings from their museum ends (Trains.MUSEUM_ENDS) west, in world metres.
const SM_SIDINGS := [
	[Vector2(-2531.6, 870.1), Vector2(-2635.1, 916.3)],
	[Vector2(-2529.9, 874.5), Vector2(-2633.5, 920.5)],
	[Vector2(-2638.9, 933.1), Vector2(-2736.2, 977.1)],
	[Vector2(-2636.8, 936.9), Vector2(-2699.9, 965.5), Vector2(-2739.7, 983.4)],
]
## What stands on each siding, from its end: kinds of SM_STOCK, in order.
const SM_TRAINS := [
	["eu20", "tank", "ty2", "tank", "ol49"],
	["tank", "coach", "coach", "coach"],
	["ty2", "ol49", "tank", "ty2"],
	["pm3", "ty2", "tank", "eu20"],
]
## Kinds: [engine length, tender length (0 none), body colour, cab colour].
const SM_STOCK := {
	"ty2": [13.0, 9.0, "#1c1e20", "#1c1e20"],
	"ol49": [12.0, 8.0, "#202224", "#2b4a3c"],
	"tank": [10.0, 0.0, "#1c1e20", "#3f8a6a"],
	"pm3": [14.0, 9.0, "#2f6b4f", "#2f6b4f"],
	"eu20": [15.5, 0.0, "#4d7f6c", "#4d7f6c"],
	"coach": [24.0, 0.0, "#d6d1c3", "#d6d1c3"],
}
const SM_CREAM := Color("#e6dcbf")
const SM_CREAM_DARK := Color("#d3c8a6")
const SM_ROOF := Color("#55595d")
const SM_GLASS := Color("#353c40")
const SM_CANOPY := Color("#6e3026")
const SM_RED := Color("#a8312a")
const SM_FENCE := Color("#e9e9e4")
const SM_IRON := Color("#3a3f3c")
const SM_GOLD := Color(1.0, 0.78, 0.32)
## The hall: barrel over u 0..19, v -1..25; walls to 9 m, the arch rises 3.5 m more.
const SM_HALL_U := 19.0
const SM_HALL_V := Vector2(-1.0, 25.0)
const SM_HALL_WALL := 9.0
const SM_HALL_RISE := 3.5
## Nocny Targ (F's 11 photos, 2026-11-07): the old Główna platforms west of the hall, two long
## canopies of rusty corrugated roofing with the old track bed between them as the court. The south
## one (OpenStreetMap's strip off the hall) leans its single pitch over a back wall of kiosks; the
## north one (the `warehouse` outlines) has two gables side by side on two rows of posts, stalls down
## its middle. Coloured tubes under both roofs, painted benches, tables, a food truck.
## Frame: u west along the platforms from the hall's end, v north across them.
const NT_O := Vector2(-2551.0, 856.0)
const NT_A := Vector2(-0.8924, 0.4512)
const NT_B := Vector2(-0.4512, -0.8924)
const NT_RING := [Vector2(-2555.0, 847.0), Vector2(-2547.0, 865.0), Vector2(-2632.0, 903.0), Vector2(-2637.0, 892.0),
		Vector2(-2624.0, 886.0), Vector2(-2626.0, 880.0)]
## The north canopy's span and rows (local metres).
const NT_NORTH := Vector2(62.0, 226.0)
const NT_NORTH_V := Vector2(31.0, 59.0)
## The south canopy's span (u) and its back wall (v).
const NT_SOUTH := Vector2(1.0, 92.0)
const NT_SOUTH_V := Vector2(-7.0, 10.0)
const NT_RUST := Color("#86492f")
const NT_RUST_UNDER := Color("#4a3a32")
const NT_TUBES := [Color(0.2, 0.5, 1.0), Color(0.2, 1.0, 0.5), Color(1.0, 0.45, 0.15), Color(1.0, 0.25, 0.6), Color(0.95, 0.95, 1.0)]
const NT_GRAFFITI := ["#e8407a", "#2fb5c9", "#f2c230", "#7a4fc9", "#3fae5a", "#ef7a2c", "#d9d9d9", "#2b6fd6"]
const NT_STALLS := ["#c8432f", "#2f6f8f", "#e0a02a", "#3d8a4f", "#8a3f8a", "#d9d2c0"]


func _sm_frame() -> void:
	_o = SM_O
	_a = SM_A
	_b = SM_B


func _sm_local_ring(pts: Array) -> PackedVector2Array:
	var r := PackedVector2Array()
	for q: Vector2 in pts:
		r.append(_o + _a * q.x + _b * q.y)
	return r


func _find_stacja_muzeum() -> void:
	_sm_frame()
	# The hall's L (front block and the yard arm) is replaced; the yard and its sidings are the site.
	var hall := _sm_local_ring([Vector2(-7, -6), Vector2(60, -6), Vector2(60, 27), Vector2(14, 27), Vector2(14, 49.5), Vector2(-7, 49.5)])
	var yard := _sm_local_ring([Vector2(18, 28), Vector2(36, 28), Vector2(36, 150), Vector2(46, 150), Vector2(46, 275), Vector2(31, 275), Vector2(31, 158), Vector2(18, 158)])
	_add_site("stacja_muzeum", [hall, yard])
	tree_free.append([yard, 0.0, _box_of([yard])])
	# One zone over both canopies and the court (LoD2's old sheds there go too); the waiting room
	# building in the middle stays.
	_nt_frame()
	var zone := _nt_ring(-3.0, 230.0, -10.0, 64.0)
	var keep: Array = []
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		var c := _centre(q)
		if Geometry2D.is_point_in_polygon(c, zone) and float(bld["h"]) > 5.0:
			keep.append(q)
	var rings: Array = [zone]
	_add_site("nocny", rings, keep)


## A round bar from a to b (a boiler, a pipe), `sides` faces round.
func _sm_tube(a: Vector3, b: Vector3, r: float, sides: int, col: Color) -> void:
	var z := (b - a).normalized()
	var x := Vector3.UP.cross(z)
	if x.length_squared() < 0.001:
		x = Vector3.RIGHT
	x = x.normalized()
	var y := z.cross(x).normalized()
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var d0 := x * cos(a0) + y * sin(a0)
		var d1 := x * cos(a1) + y * sin(a1)
		var n := (d0 + d1).normalized()
		_quad(a + d0 * r, a + d1 * r, b + d1 * r, b + d0 * r, n, col)


func _build_stacja_muzeum(_site: Dictionary) -> void:
	_sm_frame()
	_g = map.terrain_height(SM_O.x + SM_A.x * 10.0, SM_O.y + SM_A.y * 10.0)
	var g := _g
	_sm_hall(g)
	# The long wing south along Towarowa: cream walls, a row of shop windows, a dark hipped roof.
	_sm_frame()
	_lbox(38.6, 12.5, 19.4, 12.5, g - 0.3, g + 5.6, SM_CREAM, M_STONE)
	_hip(38.6, 12.5, 19.6, 12.7, g + 5.6, 3.0, SM_ROOF)
	_mode = M_STONE
	var u := 21.0
	while u < 56.5:
		_sm_window(u, -0.05, 0.75, g + 1.0, g + 3.0, -1.0)
		_sm_window(u, -0.05, 0.6, g + 3.9, g + 4.9, -1.0)
		u += 3.3
	# The yard arm behind the hall (the photo of the courtyard: cream walls, a dark roof on
	# brackets, red-framed windows).
	_lbox(3.5, 37.3, 10.5, 12.2, g - 0.3, g + 4.6, SM_CREAM_DARK, M_STONE)
	_hip(3.5, 37.3, 11.0, 12.6, g + 4.6, 2.2, SM_ROOF)
	_mode = M_STONE
	var v := 28.0
	while v < 48.0:
		_sm_window_v(14.05, v, 0.8, g + 1.0, g + 2.9)
		v += 4.0
	var hall := _sm_local_ring([Vector2(0, -1), Vector2(58, -1), Vector2(58, 25), Vector2(14, 25), Vector2(14, 49.5), Vector2(-6.8, 49.5), Vector2(-6.8, 25), Vector2(0, 25)])
	_collide(hall)
	pocket_rings.append(hall)
	# The rolling stock on the sidings.
	for i in SM_SIDINGS.size():
		_sm_siding(SM_SIDINGS[i], SM_TRAINS[i])
	_sm_frame()
	# The water crane at the far platform's end, lamps along the platform between the rows, a white
	# fence between the museum and the live line.
	var wc := _w(33.5, 164.0)
	var gw: float = map.terrain_height(wc.x, wc.y)
	_mode = M_STONE
	_sm_tube(Vector3(wc.x, gw, wc.y), Vector3(wc.x, gw + 4.2, wc.y), 0.28, 8, SM_IRON)
	var arm := _w(33.5, 164.0) + _a * 3.2
	_sm_tube(Vector3(wc.x, gw + 3.9, wc.y), Vector3(arm.x, gw + 3.6, arm.y), 0.16, 6, SM_IRON)
	_sm_tube(Vector3(arm.x, gw + 3.6, arm.y), Vector3(arm.x, gw + 2.6, arm.y), 0.12, 6, SM_IRON)
	v = 170.0
	while v < 268.0:
		var lp := _w(33.6, v)
		var gl: float = map.terrain_height(lp.x, lp.y)
		_beam(Vector3(lp.x, gl, lp.y), Vector3(lp.x, gl + 4.6, lp.y), 0.14, SM_IRON)
		_mode = M_LAMP
		_prism(_square(lp, 0.22), gl + 4.6, gl + 4.9, Color(1.0, 0.92, 0.7), Color(1.0, 0.92, 0.7), M_LAMP, M_LAMP)
		_mode = M_STONE
		v += 16.0
	var d_pts: Array = SM_SIDINGS[3]
	for k in d_pts.size() - 1:
		var p0: Vector2 = d_pts[k]
		var p1: Vector2 = d_pts[k + 1]
		var dir := (p1 - p0).normalized()
		var side := Vector2(-dir.y, dir.x)
		if side.dot(_a) < 0.0:
			side = -side
		var f0 := p0 + side * 3.0
		var f1 := p1 + side * 3.0
		var gf := minf(map.terrain_height(f0.x, f0.y), map.terrain_height(f1.x, f1.y))
		_wall(f0, f1, gf - 0.2, gf + 1.9, side, SM_FENCE)
		_wall(f1, f0, gf - 0.2, gf + 1.9, -side, SM_FENCE)
	_sm_frame()
	_mode = M_STONE


## The barrel hall and its arched front on Towarowa.
func _sm_hall(g: float) -> void:
	var v0 := SM_HALL_V.x
	var v1 := SM_HALL_V.y
	var top := g + SM_HALL_WALL
	_mode = M_STONE
	# Side walls and the plain lower front and back.
	_wall(_w(0, v0), _w(0, v1), g - 0.3, top, -_a, SM_CREAM)
	_wall(_w(SM_HALL_U, v1), _w(SM_HALL_U, v0), g - 0.3, top, _a, SM_CREAM)
	_wall(_w(SM_HALL_U, v0), _w(0, v0), g - 0.3, top, -_b, SM_CREAM)
	_wall(_w(0, v1), _w(SM_HALL_U, v1), g - 0.3, top, _b, SM_CREAM)
	# The segmental arch: chord 19 m, rise 3.5 m.
	var c := SM_HALL_U * 0.5
	var rr := (c * c + SM_HALL_RISE * SM_HALL_RISE) / (2.0 * SM_HALL_RISE)
	var cy := top + SM_HALL_RISE - rr
	var steps := 10
	var arc: Array[Vector2] = []
	for k in steps + 1:
		var uu := SM_HALL_U * k / steps
		arc.append(Vector2(uu, cy + sqrt(maxf(rr * rr - (uu - c) * (uu - c), 0.0))))
	for side: Array in [[v0, -_b], [v1, _b]]:
		var vv: float = side[0]
		var o2: Vector2 = side[1]
		var n := Vector3(o2.x, 0.0, o2.y)
		var mid := _w(c, vv)
		for k in steps:
			var p0 := _w(arc[k].x, vv)
			var p1 := _w(arc[k + 1].x, vv)
			_tri(Vector3(mid.x, top, mid.y), Vector3(p0.x, arc[k].y, p0.y), Vector3(p1.x, arc[k + 1].y, p1.y), n, SM_CREAM,
					Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# The barrel roof, a little over the walls.
	for k in steps:
		var a0 := arc[k]
		var a1 := arc[k + 1]
		var nn := Vector2(((a0.x + a1.x) * 0.5) - c, ((a0.y + a1.y) * 0.5) - cy).normalized()
		var n3 := Vector3(_a.x * nn.x, nn.y, _a.y * nn.x)
		var q0 := _w(a0.x, v0 - 0.3)
		var q1 := _w(a1.x, v0 - 0.3)
		var q2 := _w(a1.x, v1 + 0.3)
		var q3 := _w(a0.x, v1 + 0.3)
		_quad(Vector3(q0.x, a0.y + 0.05, q0.y), Vector3(q1.x, a1.y + 0.05, q1.y), Vector3(q2.x, a1.y + 0.05, q2.y),
				Vector3(q3.x, a0.y + 0.05, q3.y), n3, SM_ROOF)
	# The front: pilasters (the outer two from the ground, the rest above the canopy), the upper
	# windows, the ground floor's windows and door, the canopy, the letters, the steps.
	for k in 8:
		var pu := 0.7 + k * 2.51
		var h := cy + sqrt(maxf(rr * rr - (pu - c) * (pu - c), 0.0)) - 0.25
		var y0 := g if k == 0 or k == 7 else g + 4.5
		_lbox(pu, v0 - 0.18, 0.3, 0.18, y0, h, SM_CREAM.lightened(0.06), M_STONE)
	_mode = M_STONE
	for uu: float in [7.2, 9.5, 11.8]:
		_sm_window(uu, v0 - 0.04, 0.9, g + 6.0, g + 7.7, -1.0)
	for uu: float in [2.6, 5.0, 14.0, 16.4]:
		_sm_window(uu, v0 - 0.04, 0.9, g + 1.2, g + 3.3, -1.0)
	_sm_window(9.5, v0 - 0.04, 1.0, g + 0.7, g + 3.2, -1.0)
	_lbox(9.5, v0 - 2.0, 6.6, 2.0, g + 4.0, g + 4.45, SM_CANOPY, M_STONE, SM_CREAM_DARK)
	for s in 4:
		_lbox(9.5, v0 - 2.4 - (3 - s) * 0.45 + 0.45 * 1.5, 7.2 - s * 0.3, 0.45 * (4 - s) * 0.5 + 0.35, g - 0.3, g + 0.17 * (s + 1),
				Color("#c9c4b8"), M_STONE)
	var k_sign := 0.95 / (Neon.ROW_H * Neon.PIXEL)
	var sp := _w(9.5, v0 - 0.45)
	signs.append(["WARSZAWA GŁÓWNA", Vector3(sp.x, g + 4.95, sp.y), Vector3(-_b.x, 0.0, -_b.y), k_sign, SM_GOLD])


## A dark window on a face of constant v (the hall's front: `facing` -1 looks out of the yard).
func _sm_window(cu: float, v: float, hw: float, y0: float, y1: float, facing: float) -> void:
	var n2 := _b * facing
	var a := _w(cu - hw, v)
	var b := _w(cu + hw, v)
	_mode = M_STONE
	_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), Vector3(n2.x, 0.0, n2.y), SM_GLASS)


## A red-framed window on a face of constant u facing +u (the yard arm's courtyard side).
func _sm_window_v(u: float, cv: float, hw: float, y0: float, y1: float) -> void:
	var a := _w(u, cv - hw - 0.12)
	var b := _w(u, cv + hw + 0.12)
	var n := Vector3(_a.x, 0.0, _a.y)
	_quad(Vector3(a.x, y0 - 0.12, a.y), Vector3(b.x, y0 - 0.12, b.y), Vector3(b.x, y1 + 0.12, b.y), Vector3(a.x, y1 + 0.12, a.y), n, SM_CANOPY)
	var a2 := _w(u + 0.04, cv - hw)
	var b2 := _w(u + 0.04, cv + hw)
	_quad(Vector3(a2.x, y0, a2.y), Vector3(b2.x, y0, b2.y), Vector3(b2.x, y1, b2.y), Vector3(a2.x, y1, a2.y), n, SM_GLASS)


## The vehicles on one siding, from its museum end west, 1.5 m apart.
func _sm_siding(pts: Array, kinds: Array) -> void:
	var line := PackedVector2Array(pts)
	var at := 2.0
	for kind: String in kinds:
		var spec: Array = SM_STOCK[kind]
		var length: float = spec[0] + (spec[1] + 0.6 if spec[1] > 0.0 else 0.0)
		var p0 := _sm_along(line, at)
		var p1 := _sm_along(line, at + length)
		if p0.distance_to(p1) < length * 0.5:
			break
		var dir := (p1 - p0).normalized()
		var y: float = minf(map.terrain_height(p0.x, p0.y), map.terrain_height(p1.x, p1.y)) + 0.05
		_sm_vehicle(kind, p0, dir, y)
		# The car stops at an engine or a coach: its footprint (3.1 m wide, as the stock's
		# buffers) collides, and goes to the pocket bridging so two neighbours leave no slit.
		var side := Vector2(-dir.y, dir.x) * 1.55
		var p_end := p0 + dir * length
		var foot := PackedVector2Array([p0 - side, p_end - side, p_end + side, p0 + side])
		_collide(foot)
		pocket_rings.append(foot)
		at += length + 1.5


func _sm_along(line: PackedVector2Array, s: float) -> Vector2:
	var left := s
	for i in line.size() - 1:
		var seg := line[i].distance_to(line[i + 1])
		if left <= seg:
			return line[i].lerp(line[i + 1], left / seg)
		left -= seg
	var last := line[line.size() - 1]
	return last + (last - line[line.size() - 2]).normalized() * left


## One engine (with its tender) or coach, its front at p, its length along dir, on rails at y.
func _sm_vehicle(kind: String, p: Vector2, dir: Vector2, y: float) -> void:
	_o = p
	_a = dir
	_b = Vector2(-dir.y, dir.x)
	var spec: Array = SM_STOCK[kind]
	var ln: float = spec[0]
	var body := Color(spec[2])
	var cab := Color(spec[3])
	var black := Color("#1c1e20")
	_mode = M_STONE
	if kind == "coach":
		_lbox(ln * 0.5, 0.0, ln * 0.5 - 0.3, 1.45, y + 1.1, y + 3.9, body, M_STONE, Color("#9a9c9a"))
		var u := 2.0
		while u < ln - 2.0:
			for s: float in [-1.0, 1.0]:
				var a := _w(u, s * 1.5)
				var b := _w(u + 1.3, s * 1.5)
				_quad(Vector3(a.x, y + 2.3, a.y), Vector3(b.x, y + 2.3, b.y), Vector3(b.x, y + 3.3, b.y), Vector3(a.x, y + 3.3, a.y),
						Vector3(_b.x * s, 0.0, _b.y * s), SM_GLASS)
			u += 2.0
		for bu: float in [3.0, ln - 3.0]:
			_lbox(bu, 0.0, 1.4, 1.1, y + 0.15, y + 1.1, black, M_STONE)
		return
	if kind == "eu20":
		_lbox(ln * 0.5, 0.0, ln * 0.5, 1.45, y + 1.3, y + 4.1, body, M_STONE, Color("#8a6a52"))
		for s: float in [-1.0, 1.0]:
			var e := 0.0 if s < 0.0 else ln
			var a := _w(e + s * 0.05, -1.1)
			var b := _w(e + s * 0.05, 1.1)
			_quad(Vector3(a.x, y + 2.9, a.y), Vector3(b.x, y + 2.9, b.y), Vector3(b.x, y + 3.6, b.y), Vector3(a.x, y + 3.6, a.y),
					Vector3(_a.x * s, 0.0, _a.y * s), SM_GLASS)
		for bu: float in [3.2, ln - 3.2]:
			_lbox(bu, 0.0, 1.6, 1.15, y + 0.15, y + 1.3, black, M_STONE)
		var p0 := _w(ln * 0.35, 0.0)
		var p1 := _w(ln * 0.5, 0.0)
		_beam(Vector3(p0.x, y + 4.1, p0.y), Vector3(p1.x, y + 5.1, p1.y), 0.1, SM_IRON)
		return
	# A steam engine: red frame and wheels, a black boiler, a chimney and a dome, the cab; a tender.
	_lbox(ln * 0.5, 0.0, ln * 0.5, 1.1, y + 0.9, y + 1.45, SM_RED, M_STONE, black)
	var wheels := 4 if ln >= 12.0 else 3
	for k in wheels:
		var wu := 3.0 + k * (ln - 5.0) / maxf(wheels - 1, 1)
		for s: float in [-1.0, 1.0]:
			var c := _w(wu, s * 1.16)
			_disc(Vector3(c.x, y + 0.85, c.y), Vector3(_b.x * s, 0.0, _b.y * s), 0.78, 10, SM_RED)
	var b0 := _w(0.4, 0.0)
	var b1 := _w(ln * 0.7, 0.0)
	if kind == "pm3":
		# The streamlined casing over everything: a green box with a sloping nose.
		_lbox(ln * 0.5 + 1.2, 0.0, ln * 0.5 - 1.2, 1.4, y + 1.45, y + 4.2, body, M_STONE)
		_lbox(1.2, 0.0, 1.2, 1.3, y + 1.45, y + 2.9, body.darkened(0.08), M_STONE)
		var n0 := _w(0.0, -1.3)
		var n1 := _w(0.0, 1.3)
		var t0 := _w(2.4, -1.3)
		var t1 := _w(2.4, 1.3)
		var nrm := Vector3(-_a.x, 1.0, -_a.y).normalized()
		_quad(Vector3(n0.x, y + 2.9, n0.y), Vector3(n1.x, y + 2.9, n1.y), Vector3(t1.x, y + 4.2, t1.y), Vector3(t0.x, y + 4.2, t0.y), nrm, body.lightened(0.05))
	else:
		_sm_tube(Vector3(b0.x, y + 2.5, b0.y), Vector3(b1.x, y + 2.5, b1.y), 0.92, 8, body)
		_disc(Vector3(b0.x, y + 2.5, b0.y) - Vector3(_a.x, 0.0, _a.y) * 0.02, Vector3(-_a.x, 0.0, -_a.y), 0.9, 8, black.lightened(0.05))
		var ch := _w(1.6, 0.0)
		_prism(_circle(ch, 0.3, 8), y + 3.3, y + 4.4, black, black, M_STONE, M_STONE)
		var dm := _w(ln * 0.4, 0.0)
		_prism(_circle(dm, 0.42, 8), y + 3.3, y + 3.85, black, black, M_STONE, M_STONE)
		if kind == "tank":
			_lbox(ln * 0.42, 0.0, ln * 0.24, 1.35, y + 1.45, y + 2.9, cab, M_STONE)
		_lbox(ln * 0.84, 0.0, ln * 0.16, 1.4, y + 1.45, y + 4.15, cab, M_STONE)
		_lbox(ln * 0.84, 0.0, ln * 0.16 + 0.15, 1.5, y + 4.15, y + 4.3, black, M_STONE)
	for s: float in [-1.0, 1.0]:
		_lbox(-0.25, s * 0.85, 0.25, 0.18, y + 1.0, y + 1.35, black, M_STONE)
	var tl: float = spec[1]
	if tl > 0.0:
		var t0u := ln + 0.6
		_lbox(t0u + tl * 0.5, 0.0, tl * 0.5, 1.4, y + 0.95, y + 3.5, body if kind == "pm3" else black, M_STONE)
		for k in 3:
			var wu := t0u + 1.6 + k * (tl - 3.2) * 0.5
			for s: float in [-1.0, 1.0]:
				var c := _w(wu, s * 1.46)
				_disc(Vector3(c.x, y + 0.55, c.y), Vector3(_b.x * s, 0.0, _b.y * s), 0.5, 8, SM_RED.darkened(0.25))


# --- Nocny Targ: the old platforms' two canopies and the court between them ---

func _nt_frame() -> void:
	_o = NT_O
	_a = NT_A
	_b = NT_B


func _nt_gy(u: float, v: float) -> float:
	var p := NT_O + NT_A * u + NT_B * v
	return map.terrain_height(p.x, p.y)


## A coloured tube light across under a roof: a thin lit bar from v0 to v1 at u, height y.
func _nt_tube(u: float, v0: float, v1: float, y: float, col: Color) -> void:
	_mode = M_LAMP
	var a := _w(u, v0)
	var b := _w(u, v1)
	_beam(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), 0.12, col, true, M_LAMP)
	_mode = M_STONE


func _build_nocny(_site: Dictionary) -> void:
	_nt_frame()
	var ring := PackedVector2Array(NT_RING)
	_g = _ground_under(ring)
	_mode = M_STONE
	_nt_south()
	_nt_north()
	_nt_court()
	_collide(_nt_ring(NT_SOUTH.x, NT_SOUTH.y, NT_SOUTH_V.x, NT_SOUTH_V.x + 3.0))
	_collide(_nt_ring(NT_NORTH.x, NT_NORTH.y, 43.5, 46.5))
	var k_sign := 0.9 / (Neon.ROW_H * Neon.PIXEL)
	var sp := _w(-0.6, 5.5)
	var gs := _nt_gy(-0.6, 5.5)
	_beam(Vector3(sp.x, gs, sp.y), Vector3(sp.x, gs + 3.2, sp.y), 0.25, SM_IRON)
	signs.append(["NOCNY TARG", Vector3(sp.x, gs + 3.9, sp.y), Vector3(-_a.x, 0.0, -_a.y), k_sign, Color(0.4, 0.75, 1.0)])
	_sm_frame()
	_mode = M_STONE


func _nt_ring(u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([_w(u0, v0), _w(u1, v0), _w(u1, v1), _w(u0, v1)])


## The south canopy: a back wall of kiosks (graffiti outside), posts, one pitch falling to the court.
func _nt_south() -> void:
	var u0 := NT_SOUTH.x
	var u1 := NT_SOUTH.y
	var vb := NT_SOUTH_V.x
	var vf := NT_SOUTH_V.y
	var gi := 0
	var u := u0
	while u < u1 - 0.5:
		var w := minf(4.0, u1 - u)
		var g := _nt_gy(u + w * 0.5, vb + 1.5)
		# The kiosk: graffiti on its back, a lit hatch on the court side.
		var col := Color(NT_GRAFFITI[gi % NT_GRAFFITI.size()])
		_lbox(u + w * 0.5, vb + 1.5, w * 0.5, 1.5, g - 0.3, g + 3.0, col, M_STONE, Color("#3a3a3a"))
		if gi % 4 != 3:
			var ha := _w(u + 0.6, vb + 3.05)
			var hb := _w(u + w - 0.6, vb + 3.05)
			_mode = M_LAMP
			_quad(Vector3(ha.x, g + 1.1, ha.y), Vector3(hb.x, g + 1.1, hb.y), Vector3(hb.x, g + 2.4, hb.y), Vector3(ha.x, g + 2.4, ha.y),
					Vector3(_b.x, 0.0, _b.y), Color(1.0, 0.86, 0.6))
			_mode = M_STONE
		gi += 3
		u += w
	u = u0 + 1.0
	var ti := 0
	while u < u1:
		var g := _nt_gy(u, 1.0)
		for v: float in [vb + 3.4, 5.0]:
			var p := _w(u, v)
			_beam(Vector3(p.x, g - 0.2, p.y), Vector3(p.x, g + 4.3 - (v - vb) * 0.06, p.y), 0.26, SM_IRON)
		_nt_tube(u + 3.0, vb + 3.6, vf - 1.0, g + 3.55, NT_TUBES[ti % NT_TUBES.size()])
		ti += 1
		u += 6.0
	# The pitch: from the back (4.5 m) to the court's edge (3.6 m), rusty above, dark below; a
	# string of coloured tubes along the edge over the court.
	var g0 := _nt_gy((u0 + u1) * 0.5, 1.0)
	_nt_roof(u0 - 0.5, u1 + 0.5, vb - 0.5, g0 + 4.5, vf, g0 + 3.5)
	_nt_edge(u0, u1, vf + 0.1, g0 + 3.35)


## A flat pitched sheet from v0 (height y0) to v1 (height y1), u0..u1: a top and an underside.
func _nt_roof(u0: float, u1: float, v0: float, y0: float, v1: float, y1: float, edges := true) -> void:
	var a0 := _w(u0, v0)
	var a1 := _w(u1, v0)
	var b1 := _w(u1, v1)
	var b0 := _w(u0, v1)
	var slope := (y1 - y0) / (v1 - v0)
	var up := Vector3(-_b.x * slope, 1.0, -_b.y * slope).normalized()
	_mode = M_STONE
	_quad(Vector3(a0.x, y0 + 0.12, a0.y), Vector3(a1.x, y0 + 0.12, a1.y), Vector3(b1.x, y1 + 0.12, b1.y), Vector3(b0.x, y1 + 0.12, b0.y), up, NT_RUST)
	_quad(Vector3(a0.x, y0, a0.y), Vector3(a1.x, y0, a1.y), Vector3(b1.x, y1, b1.y), Vector3(b0.x, y1, b0.y), -up, NT_RUST_UNDER)
	if not edges:
		return
	# The edges, so the sheet has a thickness from the side.
	var e := Vector3(-_b.x, 0.0, -_b.y)
	_quad(Vector3(a0.x, y0, a0.y), Vector3(a1.x, y0, a1.y), Vector3(a1.x, y0 + 0.12, a1.y), Vector3(a0.x, y0 + 0.12, a0.y), e, NT_RUST_UNDER)
	_quad(Vector3(b0.x, y1, b0.y), Vector3(b1.x, y1, b1.y), Vector3(b1.x, y1 + 0.12, b1.y), Vector3(b0.x, y1 + 0.12, b0.y), -e, NT_RUST_UNDER)


## A canopy's edge lit in coloured tubes, 6 m each, along u at v.
func _nt_edge(u0: float, u1: float, v: float, y: float) -> void:
	var u := u0
	var k := 0
	while u < u1 - 0.5:
		var e := minf(u + 6.0, u1)
		var a := _w(u + 0.3, v)
		var b := _w(e - 0.3, v)
		_beam(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), 0.16, NT_TUBES[k % NT_TUBES.size()], true, M_LAMP)
		k += 1
		u = e


## The north canopy: two gables side by side on two rows of posts, stalls down the middle.
func _nt_north() -> void:
	var u0 := NT_NORTH.x
	var u1 := NT_NORTH.y
	var v0 := NT_NORTH_V.x
	var v1 := NT_NORTH_V.y
	var vm := (v0 + v1) * 0.5
	var g := _nt_gy((u0 + u1) * 0.5, vm)
	var ridge1 := (v0 + vm) * 0.5
	var ridge2 := (vm + v1) * 0.5
	for k in 2:
		var ra: float = [v0, vm][k]
		var rr: float = [ridge1, ridge2][k]
		var rb: float = [vm, v1][k]
		_nt_roof(u0, u1, ra, g + 3.7, rr, g + 5.4, false)
		_nt_roof(u0, u1, rb, g + 3.7, rr, g + 5.4, false)
	var u := u0 + 2.0
	var ti := 0
	while u < u1 - 1.0:
		var gp := _nt_gy(u, vm)
		for v: float in [ridge1, ridge2]:
			var p := _w(u, v)
			_beam(Vector3(p.x, gp - 0.2, p.y), Vector3(p.x, g + 5.4, p.y), 0.26, SM_IRON)
		_nt_tube(u + 3.0, v0 + 1.0, vm - 0.5, g + 3.6, NT_TUBES[ti % NT_TUBES.size()])
		_nt_tube(u + 3.0, vm + 0.5, v1 - 1.0, g + 3.6, NT_TUBES[(ti + 2) % NT_TUBES.size()])
		ti += 1
		u += 6.0
	_nt_edge(u0, u1, v0 - 0.1, g + 3.55)
	_nt_edge(u0, u1, v1 + 0.1, g + 3.55)
	# Bulb strings across the court to the south canopy's edge.
	var gs0 := _nt_gy(70.0, 20.0)
	u = u0 + 2.0
	while u < NT_SOUTH.y - 2.0:
		var a := _w(u, NT_SOUTH_V.y + 0.1)
		var b := _w(u, v0 - 0.1)
		var ya := gs0 + 3.3
		var yb := g + 3.55
		_beam(Vector3(a.x, ya, a.y), Vector3(b.x, yb, b.y), 0.04, SM_IRON)
		_mode = M_LAMP
		for k in range(1, 12):
			var f := k / 12.0
			var q := a.lerp(b, f)
			var y := lerpf(ya, yb, f) - 0.09
			_prism(_square(q, 0.08), y, y + 0.12, Color(1.0, 0.85, 0.5), Color(1.0, 0.85, 0.5), M_LAMP, M_LAMP)
		_mode = M_STONE
		u += 6.0
	# Stalls along the middle, back to back, hatches out to both sides.
	var si := 0
	u = u0 + 4.0
	while u < u1 - 4.0:
		if si % 6 != 5:
			var gs := _nt_gy(u, vm)
			var col := Color(NT_STALLS[si % NT_STALLS.size()])
			_lbox(u, vm, 2.0, 1.5, gs - 0.3, gs + 2.8, col, M_STONE, col.darkened(0.25))
			for s: float in [-1.0, 1.0]:
				var ha := _w(u - 1.4, vm + s * 1.53)
				var hb := _w(u + 1.4, vm + s * 1.53)
				var n := _b * s
				_mode = M_LAMP
				_quad(Vector3(ha.x, gs + 1.1, ha.y), Vector3(hb.x, gs + 1.1, hb.y), Vector3(hb.x, gs + 2.3, hb.y), Vector3(ha.x, gs + 2.3, ha.y),
						Vector3(n.x, 0.0, n.y), Color(1.0, 0.86, 0.6))
				_mode = M_STONE
		si += 1
		u += 6.0


## The court on the old track bed: painted benches along it, tables, a food truck at the gate.
func _nt_court() -> void:
	var bench := ["#e8407a", "#2fb5c9", "#f2c230", "#3fae5a", "#7a4fc9", "#ef7a2c"]
	var k := 0
	var u := 6.0
	while u < 90.0:
		var g := _nt_gy(u, 12.0)
		_lbox(u, 12.0, 1.6, 0.45, g - 0.2, g + 0.85, Color(bench[k % bench.size()]), M_STONE)
		var gt := _nt_gy(u + 4.0, 20.0)
		_lbox(u + 4.0, 20.0, 0.7, 0.7, gt - 0.2, gt + 0.75, Color("#2e3235"), M_STONE)
		k += 1
		u += 8.0
	var gf := _nt_gy(4.0, 22.0)
	_lbox(4.0, 22.0, 3.2, 1.2, gf + 0.3, gf + 3.0, Color("#eeeeea"), M_STONE)
	for wu: float in [2.0, 6.2]:
		_lbox(wu, 22.0, 0.45, 1.25, gf - 0.1, gf + 0.6, Color("#1c1e20"), M_STONE)
	var ha := _w(2.6, 20.78)
	var hb := _w(5.4, 20.78)
	_mode = M_LAMP
	_quad(Vector3(ha.x, gf + 1.5, ha.y), Vector3(hb.x, gf + 1.5, hb.y), Vector3(hb.x, gf + 2.5, hb.y), Vector3(ha.x, gf + 2.5, ha.y),
			Vector3(-_b.x, 0.0, -_b.y), Color(1.0, 0.86, 0.6))
	_mode = M_STONE


# --- Kolejowa: the old railway warehouses at 8/10, the pinball museum at 8a, the teal club ---

## From F's photos (2026-11-07, ~/Documents/warsaw-needed-photos/kolejowa/): long low warehouses
## of dark brick under grey roofs on brackets along the street (KOLEJOWA 8/10 on the front); the
## grey plastered one with blind arches where the pinball museum is (parody FLIPEROWNIA); the teal
## club box with a black banner (parody ODESSKA). Found by their OpenStreetMap outlines' middles.
const KJ_PARTS := [
	[Vector2(-3002.0, 964.0), "brick"],
	[Vector2(-3037.0, 1014.0), "brick"],
	[Vector2(-3043.0, 983.0), "pinball"],
	[Vector2(-3093.0, 997.0), "club"],
]
## Kolejowa's line here, for which side of each warehouse looks at the street.
const KJ_STREET := [Vector2(-3136.0, 986.0), Vector2(-3059.0, 961.0), Vector2(-3023.0, 949.0), Vector2(-2915.0, 912.0)]
const KJ_BRICK := Color("#6e3d2e")
const KJ_PLASTER := Color("#a6a49e")
const KJ_TEAL := Color("#1d9da3")
const KJ_ROOF := Color("#5d6164")
const KJ_DOOR := Color("#3a2c26")


func _find_kolejowa() -> void:
	var rings: Array = []
	var parts: Array = []
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		var c := _centre(q)
		for kp: Array in KJ_PARTS:
			if c.distance_to(kp[0]) < 3.0:
				rings.append(q)
				parts.append([q, kp[1]])
	if rings.is_empty():
		return
	_add_site("kolejowa", rings)
	if not sites.is_empty() and sites[-1]["key"] == "kolejowa":
		sites[-1]["parts"] = parts


func _kj_street_side(ring: PackedVector2Array) -> int:
	var best := 0
	var bd := INF
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if a.distance_to(b) < 6.0:
			continue
		var m := (a + b) * 0.5 + _out(ring, a, b) * 2.0
		var d := INF
		for k in KJ_STREET.size() - 1:
			d = minf(d, Geometry2D.get_closest_point_to_segment(m, KJ_STREET[k], KJ_STREET[k + 1]).distance_to(m))
		var d_in := INF
		for k in KJ_STREET.size() - 1:
			d_in = minf(d_in, Geometry2D.get_closest_point_to_segment((a + b) * 0.5, KJ_STREET[k], KJ_STREET[k + 1]).distance_to((a + b) * 0.5))
		if d < d_in and d < bd:
			bd = d
			best = i
	return best


func _build_kolejowa(site: Dictionary) -> void:
	for part: Array in site.get("parts", []):
		var raw: PackedVector2Array = part[0]
		var ring := _simplify(raw, 0.6)
		if ring.size() < 3:
			ring = raw
		_g = _ground_under(ring)
		var g := _g
		var kind: String = part[1]
		var wall := KJ_BRICK if kind == "brick" else (KJ_PLASTER if kind == "pinball" else KJ_TEAL)
		var h := 4.6 if kind != "club" else 4.2
		_mode = M_STONE
		_prism(ring, g - 0.3, g + h, wall, KJ_ROOF, M_STONE, M_STONE)
		# The roof standing out over the walls (on brackets, in the photos), a shallow ridge cap.
		var eave: Array = Geometry2D.offset_polygon(ring, 0.7 if kind != "club" else 0.35)
		if not eave.is_empty():
			var er: PackedVector2Array = eave[0]
			_prism(er, g + h, g + h + 0.25, KJ_ROOF.darkened(0.1), KJ_ROOF, M_STONE, M_STONE)
		# The car's walls on the mapped outline (8/10 shares a party wall: a simplified edge
		# would open a slit), handed to the pocket bridging as `_collide_raw` does.
		_collide(raw)
		pocket_rings.append(raw)
		var si := _kj_street_side(ring)
		var a := ring[si]
		var b := ring[(si + 1) % ring.size()]
		var d := (b - a).normalized()
		var o := _out(ring, a, b)
		var ln := a.distance_to(b)
		var n3 := Vector3(o.x, 0.0, o.y)
		if kind == "brick":
			var t := 4.0
			while t < ln - 3.0:
				var p0 := a + d * (t - 1.4) + o * 0.05
				var p1 := a + d * (t + 1.4) + o * 0.05
				_quad(Vector3(p0.x, g, p0.y), Vector3(p1.x, g, p1.y), Vector3(p1.x, g + 3.0, p1.y), Vector3(p0.x, g + 3.0, p0.y), n3, KJ_DOOR)
				t += 9.0
		elif kind == "pinball":
			var t := 3.0
			var k := 0
			while t < ln - 2.0:
				var at := a + d * t
				if k % 3 == 1:
					_arch_panel(at, d, o, 0.9, g, g + 2.2, Color("#2f3a40"), 0.06, M_STONE)
				else:
					_arch_panel(at, d, o, 1.1, g + 0.9, g + 2.6, KJ_PLASTER.darkened(0.12), 0.04, M_STONE)
				k += 1
				t += 3.6
			var sp := a + d * (ln * 0.5) + o * 0.3
			var ks := 0.6 / (Neon.ROW_H * Neon.PIXEL)
			signs.append(["FLIPEROWNIA", Vector3(sp.x, g + 3.6, sp.y), n3, ks, Color(1.0, 0.3, 0.75)])
		else:
			# The black banner over most of the street side, the name on it.
			var p0 := a + d * (ln * 0.15) + o * 0.06
			var p1 := a + d * (ln * 0.85) + o * 0.06
			_quad(Vector3(p0.x, g + 0.6, p0.y), Vector3(p1.x, g + 0.6, p1.y), Vector3(p1.x, g + 3.7, p1.y), Vector3(p0.x, g + 3.7, p0.y), n3, Color("#1a1c1d"))
			var sp := a + d * (ln * 0.5) + o * 0.3
			var ks := 0.7 / (Neon.ROW_H * Neon.PIXEL)
			signs.append(["ODESSKA", Vector3(sp.x, g + 2.2, sp.y), n3, ks, Color(0.45, 1.0, 0.75)])
	_mode = M_STONE


# --- Generation Park X and Z (Towarowa 28 / Prosta 36, Rondo Daszyńskiego) ---------------------

## Generation Park X (11 storeys, 37.3 m) and Generation Park Z (13 storeys / 43.9 m stepping to
## 16 storeys / 53.8 m), the two 2017-2019 light-stone-grid office blocks flanking Generation Park
## Y (which keeps its own TOWERS entry `gpy` and draws the decked roof terraces on X and Z roofs).
## Spec: docs/landmarks/specs/generation_park_xz.md; references: Street View frames and 3D Tiles.
## Shared plan frame: GPXZ_U along Prosta/Łucka (ENE), GPXZ_V along Wronia/Towarowa (SSE).
const GPXZ_U := Vector2(0.963, -0.268)
const GPXZ_V := Vector2(0.268, 0.963)
const GPXZ_Z_TOP_AT := Vector2(-2687.0, 286.0)
const GPXZ_Z_TOP_H := 53.8
const GPXZ_X_H := 37.3
const GPXZ_Z_H := 43.9
const GPXZ_GROUND_H := 4.3
const GPXZ_FIRST_H := 7.6
const GPXZ_STOREY := 3.3
const GPXZ_BAY := 4.8
const GPXZ_BAND_H := 0.72
const GPXZ_BAND_PROUD := 0.22
const GPXZ_PIER_W := 0.62
const GPXZ_PIER_PROUD := 0.27
const GPXZ_CORNER_R := 0.34
const GPXZ_PARAPET_H := 1.0
const GPXZ_PARAPET_IN := 0.35
const GPXZ_PARAPET_OUT := 0.28
## Palette constants measured from docs/landmarks/specs/generation_park_xz.md and Street View refs.
const GPXZ_STONE := Color("#d3d4d0")        # light grey stone grid: piers, bands, parapets
const GPXZ_BACK := Color("#232a32")         # dark recessed backing and thin mullions behind panes
const GPXZ_GLASS := Color("#33506f")        # office glazing for X and Z body (matches Y)
const GPXZ_GLASS_TOP := Color("#2b4560")    # darker office glazing on Z's 53.8 m top
const GPXZ_BAND1 := Color("#4f6f64")        # X first-floor green-tinted glass band
const GPXZ_GROUND := Color("#3d4146")       # X recessed dark grey ground floor
const GPXZ_DOOR := Color("#5a5f64")         # X grey garage and service doors
const GPXZ_ROOF := Color("#8d969c")         # flat light grey roof membrane (matches Y)
const GPXZ_PLANT := Color("#6f767b")        # low rooftop plant boxes
const GPXZ_CANOPY := Color("#c9ccce")       # Z lobby thin flat canopy
const GPXZ_SHOP := Color("#2e4860")         # ground-floor shopfront and double-height lobby glass
const GPXZ_SIGN_BG := Color("#1e2328")      # dark fascia panel behind roof and café signs
const GPXZ_WHITE := Color("#f4f6f8")        # white parody bank name `cyti` (M_LAMP)
const GPXZ_CAFE_TXT := Color("#ffe6b8")     # warm cream parody café sign `KAWKA` (M_LAMP)
## Terrace centres drawn by `gpy` (skyline.gd): rooftop plant boxes stay well clear (> 3 m).
const GPXZ_TERRACES := [Vector2(-2605.0, 300.0), Vector2(-2654.0, 268.0), Vector2(-2687.0, 286.0)]
## Simplified stroke definitions for lowercase `cyti` and uppercase `KAWKA` built in M_LAMP geometry
## so letters read cleanly by day, glow at night, and add zero extra nodes or neon-atlas rows.
## Each glyph: [advance_in_h, Array of [x0, y0, x1, y1]] in multiples of letter height.
const GPXZ_GLYPHS := {
	"c": [0.68, [[0.0, 0.0, 0.20, 0.72], [0.0, 0.52, 0.58, 0.72], [0.0, 0.0, 0.58, 0.20]]],
	"y": [0.68, [[0.0, 0.26, 0.20, 0.72], [0.38, -0.20, 0.58, 0.72], [0.0, 0.22, 0.58, 0.40], [0.02, -0.20, 0.58, -0.02]]],
	"t": [0.58, [[0.14, 0.0, 0.34, 1.00], [0.0, 0.54, 0.50, 0.72], [0.14, 0.0, 0.50, 0.18]]],
	"i": [0.28, [[0.0, 0.0, 0.20, 0.68], [0.0, 0.80, 0.20, 0.98]]],
	"K": [0.72, [[0.0, 0.0, 0.20, 1.0], [0.16, 0.40, 0.40, 0.60], [0.34, 0.52, 0.58, 1.0], [0.34, 0.0, 0.58, 0.48]]],
	"A": [0.74, [[0.0, 0.0, 0.20, 1.0], [0.42, 0.0, 0.62, 1.0], [0.0, 0.80, 0.62, 1.0], [0.0, 0.36, 0.62, 0.54]]],
	"W": [0.94, [[0.0, 0.0, 0.18, 1.0], [0.32, 0.0, 0.50, 0.66], [0.64, 0.0, 0.82, 1.0], [0.0, 0.0, 0.82, 0.20]]],
}


## Finds Generation Park X, Generation Park Z, and Z's 53.8 m top part from centrum.json and
## registers them as one site `gpxz` whose zone is both outlines offset 1.0 m (clear of Y).
func _find_gpxz() -> void:
	var x_raw := _landmark("Generation Park X")
	if x_raw.size() < 3:
		push_error("gpxz: landmark outline 'Generation Park X' is missing from centrum.json")
	var z_raw := _landmark("Generation Park Z")
	if z_raw.size() < 3:
		push_error("gpxz: landmark outline 'Generation Park Z' is missing from centrum.json")
	var z_top_raw := PackedVector2Array()
	for bld: Dictionary in data.get("buildings", []):
		if absf(float(bld["h"]) - GPXZ_Z_TOP_H) > 0.3:
			continue
		var q := _pts(bld["p"])
		if q.size() >= 3 and Geometry2D.is_point_in_polygon(GPXZ_Z_TOP_AT, q):
			z_top_raw = q
			break
	if z_top_raw.size() < 3:
		push_error("gpxz: 53.8 m top building holding (-2687, 286) is missing from centrum.json")
	var zones: Array = []
	if x_raw.size() >= 3:
		var zx := _largest(Geometry2D.offset_polygon(x_raw, 1.0, Geometry2D.JOIN_MITER))
		if zx.size() >= 3:
			zones.append(zx)
	if z_raw.size() >= 3:
		var zz := _largest(Geometry2D.offset_polygon(z_raw, 1.0, Geometry2D.JOIN_MITER))
		if zz.size() >= 3:
			zones.append(zz)
	if zones.is_empty():
		return
	_add_site("gpxz", zones)
	if not sites.is_empty() and sites[-1]["key"] == "gpxz":
		sites[-1]["x_raw"] = x_raw
		sites[-1]["z_raw"] = z_raw
		sites[-1]["z_top_raw"] = z_top_raw


## Starts a kit_front along edge a->b oriented so _b points along outward normal `out`.
func _gpxz_front_edge(a: Vector2, b: Vector2, out: Vector2) -> float:
	var dir := (b - a).normalized()
	if Vector2(-dir.y, dir.x).dot(out) < 0.0:
		return kit_front(b, a)
	return kit_front(a, b)


## Simplifies an OSM outline into clean rectilinear edges without small revolving-door bumps.
func _gpxz_clean(raw: PackedVector2Array, tol := 1.35) -> PackedVector2Array:
	var ring := _simplify(raw, tol)
	return ring if ring.size() >= 3 else raw


## Places full-height stone corner posts aligned to the site's (GPXZ_U, GPXZ_V) frame at every
## vertex of `ring` from `y0` to `y1`, slightly prouder than piers and bands to prevent z-fighting.
func _gpxz_corners(ring: PackedVector2Array, y0: float, y1: float) -> void:
	var ua := GPXZ_U.normalized()
	var vb := GPXZ_V.normalized()
	var r := GPXZ_CORNER_R
	for p in ring:
		var sq := PackedVector2Array([
			p - ua * r - vb * r,
			p + ua * r - vb * r,
			p + ua * r + vb * r,
			p - ua * r + vb * r,
		])
		_prism(sq, y0, y1, GPXZ_STONE, GPXZ_STONE.darkened(0.08), M_STONE, M_STONE)


## Draws the characteristic stone-grid facade on one edge: full-height stone piers every ~GPXZ_BAY m
## and two kit_panes glazing strips per bay per storey with a thin dark mullion gap between them.
## `skip_u` (if x < y) leaves an opening (e.g. a double-height lobby or tall entrance) clear for
## heights below `skip_y`.
func _gpxz_face_grid(a: Vector2, b: Vector2, out: Vector2, y_sills: Array[float], pane_h: float,
		pier_y0: float, pier_y1: float, glass: Color, skip_u := Vector2(-1.0, -1.0), skip_y := -INF,
		pier_full_ground := false, ground_y0 := 0.0) -> void:
	var w := _gpxz_front_edge(a, b, out)
	if w < 1.8:
		return
	var margin := 0.55
	var usable := w - 2.0 * margin
	if usable < 0.8:
		return
	var bays := maxi(1, roundi(usable / GPXZ_BAY))
	var step := usable / float(bays)
	var half_gap := 0.06
	# Intermediate vertical stone piers (proud 0.27 m > 0.22 m bands so front faces never share a plane).
	for k in range(1, bays):
		var pu := margin + float(k) * step
		var in_skip := skip_u.x < skip_u.y and pu > skip_u.x + 0.15 and pu < skip_u.y - 0.15
		var py0 := ground_y0 if (pier_full_ground and not in_skip) else (skip_y if in_skip else pier_y0)
		if pier_y1 - py0 > 0.5:
			_kbox(pu - GPXZ_PIER_W * 0.5, pu + GPXZ_PIER_W * 0.5, -0.02, GPXZ_PIER_PROUD, py0, pier_y1, GPXZ_STONE)
	# Two glass panes per bay on every storey, separated by a thin 12 cm dark mullion reveal.
	var clear_w := step - GPXZ_PIER_W - 0.08
	var pane_w := maxf(0.4, (clear_w - 2.0 * half_gap) * 0.5)
	var all_cols: Array[float] = []
	var unskipped_cols: Array[float] = []
	for k in bays:
		var bc := margin + (float(k) + 0.5) * step
		var p_lo := bc - (pane_w * 0.5 + half_gap)
		var p_hi := bc + (pane_w * 0.5 + half_gap)
		all_cols.append(p_lo)
		all_cols.append(p_hi)
		if not (skip_u.x < skip_u.y and bc > skip_u.x - 0.1 and bc < skip_u.y + 0.1):
			unskipped_cols.append(p_lo)
			unskipped_cols.append(p_hi)
	var low_rows: Array[float] = []
	var high_rows: Array[float] = []
	for sy in y_sills:
		if skip_u.x < skip_u.y and sy < skip_y - 0.1:
			low_rows.append(sy)
		else:
			high_rows.append(sy)
	if not high_rows.is_empty():
		kit_panes(all_cols, high_rows, pane_w, pane_h, glass, 0.05)
	if not low_rows.is_empty() and not unskipped_cols.is_empty():
		kit_panes(unskipped_cols, low_rows, pane_w, pane_h, glass, 0.05)


## Draws the green-tinted first-floor glass band (4.3-7.6 m) on one edge of X in M_STONE so it
## keeps its green tint (#4f6f64) with the piers and thin mullions reading cleanly across it.
func _gpxz_x_band1(a: Vector2, b: Vector2, out: Vector2, y0: float, y1: float, skip_u := Vector2(-1.0, -1.0)) -> void:
	var w := _gpxz_front_edge(a, b, out)
	if w < 1.8:
		return
	var margin := 0.55
	var usable := w - 2.0 * margin
	if usable < 0.8:
		return
	var bays := maxi(1, roundi(usable / GPXZ_BAY))
	var step := usable / float(bays)
	var half_gap := 0.06
	var pane_w := maxf(0.4, (step - GPXZ_PIER_W - 0.08 - 2.0 * half_gap) * 0.5)
	var keep := _mode
	_mode = M_STONE
	for k in bays:
		var bc := margin + (float(k) + 0.5) * step
		if skip_u.x < skip_u.y and bc > skip_u.x - 0.1 and bc < skip_u.y + 0.1:
			continue
		for s: float in [-1.0, 1.0]:
			var u := bc + s * (pane_w * 0.5 + half_gap)
			_wall(_w(u - pane_w * 0.5, 0.05), _w(u + pane_w * 0.5, 0.05), y0, y1, _b, GPXZ_BAND1)
	_mode = keep


## Builds a 1.0 m solid stone parapet with a crisp coping along every outer edge of `ring` at
## `roof_y` (extending GPXZ_PARAPET_OUT over the piers so the roofline reads razor-straight with
## no pier teeth, and GPXZ_PARAPET_IN inward so it stays clear of Y's 1.5 m-inset roof terraces).
## When `clip_against` is non-empty, only outer edges outside `clip_against` receive a parapet.
func _gpxz_parapet(ring: PackedVector2Array, roof_y: float, clip_against := PackedVector2Array()) -> void:
	var top := roof_y + GPXZ_PARAPET_H
	var keep := _mode
	_mode = M_STONE
	if clip_against.size() < 3:
		var outer := _ring_out(ring, GPXZ_PARAPET_OUT)
		var inner := _inset_ring(ring, GPXZ_PARAPET_IN)
		_prism(outer, roof_y, top, GPXZ_STONE, Color(0, 0, 0, 0), M_STONE)
		for i in inner.size():
			var a := inner[i]
			var b := inner[(i + 1) % inner.size()]
			_wall(a, b, roof_y, top, -_out(inner, a, b), GPXZ_STONE.darkened(0.08))
		_strip(inner, outer, top, GPXZ_STONE.lightened(0.05))
		kit_ledge_ring(outer, top - 0.16, 0.16, GPXZ_STONE.lightened(0.08), 0.08)
		_mode = keep
		return
	# Exposed edges of `ring` minus `clip_against` (Z's 43.9 m east/north wing around the 53.8 m top).
	for piece: PackedVector2Array in Geometry2D.clip_polygons(ring, clip_against):
		if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
			continue
		for i in piece.size():
			var a := piece[i]
			var b := piece[(i + 1) % piece.size()]
			var ln := a.distance_to(b)
			if ln < 0.8:
				continue
			var out := _out(piece, a, b)
			var mid := (a + b) * 0.5
			# Only outer perimeter edges (just outside `ring`), never the seam against `clip_against`.
			if Geometry2D.is_point_in_polygon(mid + out * 0.4, ring):
				continue
			var w := _gpxz_front_edge(a, b, out)
			var u0 := 0.1 if Geometry2D.is_point_in_polygon(_w(0.0, 0.0) - _a * 0.3, clip_against) else -GPXZ_PARAPET_OUT
			var u1 := w - 0.1 if Geometry2D.is_point_in_polygon(_w(w, 0.0) + _a * 0.3, clip_against) else w + GPXZ_PARAPET_OUT
			if u1 - u0 < 0.5:
				continue
			_kbox(u0, u1, -GPXZ_PARAPET_IN, GPXZ_PARAPET_OUT, roof_y, top, GPXZ_STONE)
			kit_ledge(u0, u1, top - 0.16, 0.16, GPXZ_STONE.lightened(0.08), GPXZ_PARAPET_OUT + 0.08)
	_mode = keep


## Places a low grey rooftop plant box (size_u x size_v x h) centred at `world_c` aligned to
## (GPXZ_U, GPXZ_V), after verifying it sits at least 3.0 m clear of every `gpy` terrace point.
func _gpxz_plant(world_c: Vector2, roof_y: float, size_u: float, size_v: float, h: float) -> void:
	var hu := size_u * 0.5
	var hv := size_v * 0.5
	var ua := GPXZ_U.normalized()
	var vb := GPXZ_V.normalized()
	var poly := PackedVector2Array([
		world_c - ua * hu - vb * hv,
		world_c + ua * hu - vb * hv,
		world_c + ua * hu + vb * hv,
		world_c - ua * hu + vb * hv,
	])
	for tp: Vector2 in GPXZ_TERRACES:
		if _dist_to_ring(tp, poly) < 3.0 or Geometry2D.is_point_in_polygon(tp, poly):
			return
	_prism(poly, roof_y, roof_y + h, GPXZ_PLANT, GPXZ_PLANT.darkened(0.14), M_STONE, M_STONE)
	kit_ledge_ring(poly, roof_y + h - 0.18, 0.18, GPXZ_PLANT.lightened(0.08), 0.08)


## Draws a word of built M_LAMP letters on the current kit_front, centred at `u_mid` with baseline
## `y_base`, letter height `h`, standing on a thin dark backing panel anchored to the wall so no
## letter stroke floats or z-fights. Readers looking from +v see left-to-right along -u.
func _gpxz_word(word: String, u_mid: float, y_base: float, h: float, col: Color, face_v: float,
		with_backing := true) -> void:
	var total := 0.0
	for i in word.length():
		var g: Array = GPXZ_GLYPHS.get(word[i], [])
		if not g.is_empty():
			total += float(g[0]) * h
			if i > 0:
				total += 0.12 * h
	if total <= 0.0:
		return
	var back_v := face_v + 0.03
	if with_backing:
		_kbox(u_mid - total * 0.5 - 0.45, u_mid + total * 0.5 + 0.45, face_v - 0.04, back_v,
				y_base - 0.25 * h, y_base + 1.15 * h, GPXZ_SIGN_BG, M_STONE)
	var cursor := u_mid + total * 0.5
	var keep := _mode
	_mode = M_LAMP
	for i in word.length():
		var g: Array = GPXZ_GLYPHS.get(word[i], [])
		if g.is_empty():
			continue
		var adv := float(g[0]) * h
		var x_left := cursor
		for box: Array in g[1]:
			var u1 := x_left - float(box[0]) * h
			var u0 := x_left - float(box[2]) * h
			var y0 := y_base + float(box[1]) * h
			var y1 := y_base + float(box[3]) * h
			_kbox(u0, u1, back_v - 0.02, back_v + 0.09, y0, y1, col, M_LAMP)
		cursor -= adv + 0.12 * h
	_mode = keep


## Draws a glazed shop bay using kit_shop_bay plus an M_PAVILION glass face 3 cm proud so the
## ground floor and lobby glow warmly at night while staying on the facade kit.
func _gpxz_shop(u: float, y0: float, y1: float, hw: float, trim: Color, glass: Color) -> void:
	kit_shop_bay(u, y0, y1, hw, trim, glass)
	var keep := _mode
	_mode = M_PAVILION
	_wall(_w(u - hw + 0.04, _face + 0.08), _w(u + hw - 0.04, _face + 0.08), y0 + 0.04, y1 - 0.02, _b, glass)
	_mode = keep


## Main builder for Generation Park X and Z (`gpxz`).
func _build_gpxz(site: Dictionary) -> void:
	var x_raw: PackedVector2Array = site.get("x_raw", PackedVector2Array())
	var z_raw: PackedVector2Array = site.get("z_raw", PackedVector2Array())
	var z_top_raw: PackedVector2Array = site.get("z_top_raw", PackedVector2Array())
	if x_raw.size() >= 3:
		_gpxz_build_x(x_raw)
		_collide(x_raw)
	if z_raw.size() >= 3:
		_gpxz_build_z(z_raw, z_top_raw)
		_collide(z_raw)
	_mode = M_STONE


## Builds Generation Park X: inset dark ground floor with garage doors every ~9 m and tall glazed
## entrances, flush green-tinted first-floor glass band, nine storeys of light stone grid over
## paired blue-grey panes, top-storey SE corner `cyti` signs on both faces, flat roof at +37.3 m
## with 1.0 m stone parapet and low plant boxes clear of Y's terrace.
func _gpxz_build_x(x_raw: PackedVector2Array) -> void:
	var ring := _gpxz_clean(x_raw, 1.35)
	var g := _ground_under(x_raw)
	_g = g
	var ua := GPXZ_U.normalized()
	var vb := GPXZ_V.normalized()
	var roof_y := g + GPXZ_X_H
	var g_top := g + GPXZ_GROUND_H
	var f1_top := g + GPXZ_FIRST_H
	# Ground floor inset 1.2 m in dark grey (#3d4146) under the overhanging first-floor soffit.
	var ground_ring := _largest(Geometry2D.offset_polygon(ring, -1.2, Geometry2D.JOIN_MITER))
	if ground_ring.size() < 3:
		ground_ring = ring
	_mode = M_STONE
	_prism(ground_ring, g - 0.5, g_top, GPXZ_GROUND, Color(0, 0, 0, 0), M_STONE)
	_soffit(ring, g_top, GPXZ_STONE.darkened(0.24))
	# Upper body prism (4.3-37.3 m): dark charcoal backing wall so recessed panes and thin mullions pop,
	# capped cleanly at exact roof slab top g + 37.3 m in roof membrane #8d969c.
	_prism(ring, g_top, roof_y, GPXZ_BACK, GPXZ_ROOF, M_STONE, M_STONE)
	# Upper corner stone posts (4.3 m to just under roof cap) and solid full-depth ground-floor
	# corner blocks anchoring the 1.2 m overhang cleanly to the pavement (no skinny stilt corners).
	_gpxz_corners(ring, g_top + 0.02, roof_y - 0.08)
	# Identify key faces: south Prosta end (out ~ +v, len ~17.5 m) and long east Wronia face (out ~ +u, len ~90 m).
	var south_i := _edge_facing(ring, vb, 12.0)
	var east_i := _edge_facing(ring, ua, 60.0)
	# Storey bands: full kit_ledge_ring on floors 2..10 (7.6 to 34.0 m) plus top edge band.
	var office_sills: Array[float] = []
	for fl in 9:
		var y_line := f1_top + float(fl) * GPXZ_STOREY
		kit_ledge_ring(ring, y_line, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
		office_sills.append(y_line + GPXZ_BAND_H + 0.05)
	kit_ledge_ring(ring, roof_y - GPXZ_BAND_H, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
	var pane_h := GPXZ_STOREY - GPXZ_BAND_H - 0.1
	# Ground-floor band at 4.3 m drawn per edge so the 6 m tall south entrance passes cleanly through it.
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var out := _out(ring, a, b)
		var ln := a.distance_to(b)
		if ln < 1.5:
			continue
		var w := _gpxz_front_edge(a, b, out)
		var ent_skip := Vector2(-1.0, -1.0)
		if i == south_i:
			# Tall 6 m x 8 m glazed entrance at the south end (Prosta face).
			var ec := w * 0.5
			ent_skip = Vector2(ec - 4.0, ec + 4.0)
			# Flush stone portal cheeks back to the recessed ground wall so the entrance sits solid.
			_kbox(ec - 4.45, ec - 4.0, -1.25, 0.2, g - 0.5, g + 6.3, GPXZ_STONE)
			_kbox(ec + 4.0, ec + 4.45, -1.25, 0.2, g - 0.5, g + 6.3, GPXZ_STONE)
			_kbox(ec - 4.45, ec + 4.45, -1.25, 0.2, g + 6.0, g + 6.3, GPXZ_STONE)
			_gpxz_shop(ec, g, g + 6.0, 3.9, GPXZ_STONE, GPXZ_SHOP)
			# Split 4.3 m band either side of the entrance.
			if ec - 4.45 > 0.45:
				kit_ledge(0.35, ec - 4.45, g_top, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
			if w - (ec + 4.45) > 0.45:
				kit_ledge(ec + 4.45, w - 0.35, g_top, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
		else:
			if w > 0.9:
				kit_ledge(0.35, w - 0.35, g_top, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
		# First-floor green-tinted glass band (4.3-7.6 m) and 9 office storeys above (7.6-37.3 m).
		_gpxz_x_band1(a, b, out, g_top + GPXZ_BAND_H + 0.04, f1_top - 0.04, ent_skip)
		_gpxz_face_grid(a, b, out, office_sills, pane_h, g_top + 0.05, roof_y - 0.05, GPXZ_GLASS, ent_skip, f1_top)
		# Ground-floor substantial full-depth stone piers framing recessed garage bays (sv_x bottom row).
		if ln >= 8.0:
			var n_sup := maxi(2, roundi(w / 9.0))
			for k in range(1, n_sup):
				var su := w * float(k) / float(n_sup)
				if ent_skip.x < ent_skip.y and su > ent_skip.x - 1.2 and su < ent_skip.y + 1.2:
					continue
				_kbox(su - 0.55, su + 0.55, -1.24, 0.25, g - 0.5, g_top - 0.03, GPXZ_STONE)
			# End return piers anchoring the recessed corners cleanly back to the ground wall.
			if i != south_i:
				_kbox(0.05, 1.15, -1.24, 0.25, g - 0.5, g_top - 0.03, GPXZ_STONE)
				_kbox(w - 1.15, w - 0.05, -1.24, 0.25, g - 0.5, g_top - 0.03, GPXZ_STONE)
		# East (Wronia) face: wide recessed grey garage doors every 9 m plus a glazed north-end lobby bay.
		if i == east_i:
			var n_gar := maxi(1, floori((w - 14.0) / 9.0))
			kit_face(-1.2)
			for k in n_gar:
				var du := 5.5 + float(k) * 9.0
				if du + 3.4 < w - 10.0:
					kit_door(du, g, 3.2, 2.9, GPXZ_GROUND.darkened(0.18), GPXZ_DOOR)
			# Glazed north-end street entrance on Wronia (Street View sv_x bottom-right).
			if w > 18.0:
				_gpxz_shop(w - 6.0, g, g_top - 0.2, 3.4, GPXZ_STONE, GPXZ_SHOP)
			kit_face(0.0)
	# Parody bank name `cyti` (white, lowercase, M_LAMP, 1.75 m tall) on a dark top-storey frieze
	# panel at the SE corner (both Prosta south face and Wronia east face, sv_x top & 3D Tiles h315).
	var sign_y := roof_y - 2.25
	if south_i >= 0:
		var sa := ring[south_i]
		var sb := ring[(south_i + 1) % ring.size()]
		var sw := _gpxz_front_edge(sa, sb, _out(ring, sa, sb))
		# Dark top-storey frieze across the south end (as in sv_x top-right) with bold white `cyti`.
		_kbox(0.45, sw - 0.45, 0.06, 0.24, roof_y - 2.55, roof_y - GPXZ_BAND_H - 0.03, GPXZ_SIGN_BG, M_STONE)
		_gpxz_word("cyti", minf(5.0, sw * 0.36), sign_y, 1.75, GPXZ_WHITE, 0.26, false)
	if east_i >= 0:
		var ea := ring[east_i]
		var eb := ring[(east_i + 1) % ring.size()]
		var ew := _gpxz_front_edge(ea, eb, _out(ring, ea, eb))
		var se_near_start := _w(0.0, 0.0).dot(vb) > _w(ew, 0.0).dot(vb)
		var su := 5.2 if se_near_start else ew - 5.2
		_kbox(su - 4.4, su + 4.4, 0.06, 0.24, roof_y - 2.55, roof_y - GPXZ_BAND_H - 0.03, GPXZ_SIGN_BG, M_STONE)
		_gpxz_word("cyti", su, sign_y, 1.75, GPXZ_WHITE, 0.26, false)
	# Roof parapet (1.0 m) and low plant boxes on the north head and south end (> 20 m from Y's terrace).
	_gpxz_parapet(ring, roof_y)
	var base_o := Vector2(-2650.0, 280.0)
	_gpxz_plant(base_o + ua * 35.0 + vb * -16.0, roof_y, 7.0, 3.5, 2.2)
	_gpxz_plant(base_o + ua * 48.5 + vb * 56.0, roof_y, 3.5, 6.5, 2.0)


## Builds Generation Park Z: 13-storey body (43.9 m) stepping to 16 storeys (53.8 m) at the west
## part, light stone grid over paired blue panes (darker on the top 3 storeys), clear M_PAVILION
## shopfronts all round, double-height glazed lobby with thin flat canopy and tie-rods on the plaza
## corner, `KAWKA` café sign, flat roofs at +43.9 m and +53.8 m with parapets and plant boxes.
func _gpxz_build_z(z_raw: PackedVector2Array, z_top_raw: PackedVector2Array) -> void:
	var ring := _gpxz_clean(z_raw, 1.35)
	var top_ring := _gpxz_clean(z_top_raw, 0.5) if z_top_raw.size() >= 3 else PackedVector2Array()
	var g := _ground_under(z_raw)
	_g = g
	var ua := GPXZ_U.normalized()
	var vb := GPXZ_V.normalized()
	var g_top := g + GPXZ_GROUND_H
	var f1_top := g + GPXZ_FIRST_H
	var roof_y := g + GPXZ_Z_H
	var top_g := _ground_under(z_top_raw) if z_top_raw.size() >= 3 else g
	var top_roof_y := top_g + GPXZ_Z_TOP_H
	# Main Z prism (0-43.9 m) capped cleanly at exact roof slab top g + 43.9 m.
	_mode = M_STONE
	_prism(ring, g - 0.5, roof_y, GPXZ_BACK, GPXZ_ROOF, M_STONE, M_STONE)
	_gpxz_corners(ring, g - 0.5, roof_y - 0.08)
	# Identify main street/plaza faces: west Towarowa face (out ~ -u, len ~33 m) and south plaza
	# lobby face (longest south-facing edge with largest v, i.e. the SW plaza front ~25.6 m).
	var west_i := _edge_facing(ring, -ua, 20.0)
	var lobby_i := -1
	var lobby_v := -INF
	var south_cafe_i := -1
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var ln := a.distance_to(b)
		if ln < 12.0:
			continue
		var out := _out(ring, a, b)
		if out.dot(vb) > 0.8:
			var mv := ((a + b) * 0.5).dot(vb)
			if mv > lobby_v:
				lobby_v = mv
				lobby_i = i
	for i in ring.size():
		if i == lobby_i:
			continue
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if a.distance_to(b) >= 18.0 and _out(ring, a, b).dot(vb) > 0.8:
			south_cafe_i = i
	# Storey bands for Z body (floors 2..12: 7.6 to 40.6 m) plus the 43.9 m roof edge band.
	var body_sills: Array[float] = [g_top + GPXZ_BAND_H + 0.05]
	for fl in range(1, 12):
		var y_line := g_top + float(fl) * GPXZ_STOREY
		kit_ledge_ring(ring, y_line, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
		body_sills.append(y_line + GPXZ_BAND_H + 0.05)
	var pane_h := GPXZ_STOREY - GPXZ_BAND_H - 0.1
	# Dress every face of Z body: ground-floor shopfronts, double-height lobby + canopy, café sign, grid.
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var out := _out(ring, a, b)
		var ln := a.distance_to(b)
		if ln < 1.5:
			continue
		var w := _gpxz_front_edge(a, b, out)
		var lobby_skip := Vector2(-1.0, -1.0)
		if i == lobby_i:
			# Double-height (0-7.6 m) glazed lobby across the central/west 16 m of the plaza face,
			# with a thin 1.5 m deep, 0.3 m thick flat canopy and diagonal tie-rods over the doors.
			var l0 := maxf(1.2, w * 0.5 - 8.0)
			var l1 := minf(w - 1.2, w * 0.5 + 8.0)
			lobby_skip = Vector2(l0, l1)
			var lb_bays := 3
			var lb_step := (l1 - l0) / float(lb_bays)
			for k in lb_bays:
				var uc := l0 + (float(k) + 0.5) * lb_step
				_gpxz_shop(uc, g, f1_top - 0.05, lb_step * 0.46, GPXZ_STONE, GPXZ_SHOP)
			# Thin flat canopy (#c9ccce, 1.8 m deep, 0.32 m thick) and diagonal tie-rods (sv_z top row).
			var c0 := l0 + 0.3
			var c1 := l1 - 0.3
			_kbox(c0, c1, 0.02, 1.82, g + 3.8, g + 4.12, GPXZ_CANOPY, M_STONE)
			var n_rods := 6
			for k in n_rods:
				var ru := lerpf(c0 + 0.6, c1 - 0.6, float(k) / float(n_rods - 1))
				var p_out := _w(ru, 1.66)
				var p_wall := _w(ru, 0.04)
				_beam(Vector3(p_out.x, g + 4.12, p_out.y), Vector3(p_wall.x, g + 6.0, p_wall.y), 0.07, GPXZ_CANOPY, false)
			# Split 4.3 m storey band on the non-lobby portions of this face.
			if l0 > 0.5:
				kit_ledge(0.35, l0 - 0.05, g_top, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
			if w - l1 > 0.5:
				kit_ledge(l1 + 0.05, w - 0.35, g_top, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
		else:
			if i == west_i and w > 14.0:
				# Towarowa face: double-height lobby return on its southmost bay, shopfronts & café on the rest.
				var south_at_start := _w(0.0, 0.0).dot(vb) > _w(w, 0.0).dot(vb)
				var r0 := 0.55 if south_at_start else w - 7.5
				var r1 := 7.5 if south_at_start else w - 0.55
				lobby_skip = Vector2(r0, r1)
				_gpxz_shop((r0 + r1) * 0.5, g, f1_top - 0.05, (r1 - r0) * 0.46, GPXZ_STONE, GPXZ_SHOP)
				_kbox(r0 + 0.3, r1 - 0.3, 0.02, 1.52, g + 3.8, g + 4.12, GPXZ_CANOPY, M_STONE)
				if south_at_start:
					kit_ledge(r1 + 0.05, w - 0.35, g_top, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
				else:
					kit_ledge(0.35, r0 - 0.05, g_top, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
			elif w > 0.9:
				kit_ledge(0.35, w - 0.35, g_top, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
		# Ground-floor glazed shopfronts (kit_shop_bay + M_PAVILION) in every non-lobby bay.
		var margin := 0.55
		var usable := w - 2.0 * margin
		if usable >= 1.4:
			var bays := maxi(1, roundi(usable / GPXZ_BAY))
			var step := usable / float(bays)
			for k in bays:
				var bc := margin + (float(k) + 0.5) * step
				if lobby_skip.x < lobby_skip.y and bc > lobby_skip.x - 0.1 and bc < lobby_skip.y + 0.1:
					continue
				_gpxz_shop(bc, g, g_top - 0.25, maxf(0.4, (step - GPXZ_PIER_W - 0.12) * 0.5), GPXZ_STONE, GPXZ_SHOP)
		# Parody café sign `KAWKA` over a bay on Towarowa (sv_z bottom) and on the south Prosta-side face.
		if i == west_i and w > 16.0:
			var mid_u := w * 0.55 if _w(0.0, 0.0).dot(vb) > _w(w, 0.0).dot(vb) else w * 0.45
			_gpxz_word("KAWKA", mid_u, g + 3.35, 0.9, GPXZ_CAFE_TXT, GPXZ_BAND_PROUD)
		elif i == south_cafe_i:
			_gpxz_word("KAWKA", w * 0.5, g + 3.35, 0.9, GPXZ_CAFE_TXT, GPXZ_BAND_PROUD)
		# Office grid (4.3-43.9 m) with piers running down to ground between shop bays.
		_gpxz_face_grid(a, b, out, body_sills, pane_h, g_top + 0.05, roof_y - 0.05, GPXZ_GLASS,
				lobby_skip, f1_top, true, g - 0.5)
	# Parapet on Z's exposed 43.9 m roof edges (clipped against Z's 53.8 m top so nothing z-fights).
	_gpxz_parapet(ring, roof_y, top_ring)
	# Z's 53.8 m top part (storeys 14-16, 43.9-53.8 m) with the same stone grid and darker glass #2b4560.
	if top_ring.size() < 3:
		return
	_mode = M_STONE
	_prism(top_ring, roof_y, top_roof_y, GPXZ_BACK.darkened(0.18), GPXZ_ROOF, M_STONE, M_STONE)
	_gpxz_corners(top_ring, roof_y + 0.06, top_roof_y - 0.08)
	var top_sills: Array[float] = []
	for fl in 3:
		var y_line := roof_y + float(fl) * GPXZ_STOREY
		kit_ledge_ring(top_ring, y_line, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
		top_sills.append(y_line + GPXZ_BAND_H + 0.05)
	kit_ledge_ring(top_ring, top_roof_y - GPXZ_BAND_H, GPXZ_BAND_H, GPXZ_STONE, GPXZ_BAND_PROUD)
	for i in top_ring.size():
		var a := top_ring[i]
		var b := top_ring[(i + 1) % top_ring.size()]
		var out := _out(top_ring, a, b)
		if a.distance_to(b) < 1.5:
			continue
		_gpxz_face_grid(a, b, out, top_sills, pane_h, roof_y + 0.06, top_roof_y - 0.05, GPXZ_GLASS_TOP)
	_gpxz_parapet(top_ring, top_roof_y)
	# Three low grey plant boxes (3 x 6 m, 2.2 m tall) on Z's 53.8 m roof, > 12 m clear of (-2687, 286).
	var base_o := Vector2(-2650.0, 280.0)
	_gpxz_plant(base_o + ua * -52.0 + vb * 2.0, top_roof_y, 6.0, 3.0, 2.2)
	_gpxz_plant(base_o + ua * -52.0 + vb * -9.5, top_roof_y, 6.0, 3.0, 2.2)
	_gpxz_plant(base_o + ua * -21.0 + vb * -8.0, top_roof_y, 6.0, 3.0, 2.2)
