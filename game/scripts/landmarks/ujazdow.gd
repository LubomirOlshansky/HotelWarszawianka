extends "res://scripts/landmarks/fronts.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, Ujazdów and Łazienkowska:
## Zamek Ujazdowski, Legia's ground, WTS DeSki, the Sejm, Stacja Filtrów. Moved as it was from the
## one big file. landmarks.gd is the class the game makes; every file of game/scripts/landmarks/ is
## one link of its base chain (facade_kit.gd, common.gd, then the areas in the order of
## landmarks.gd's `extends` chain), so code here may use this file, common.gd and the facade kit,
## never another area: a helper two areas need goes to common.gd.


# --- Filharmonia Narodowa and Teatr Polski ----------------------------------------------------

## The Sejm (Sejm RP; Skórewicz and Pniewski, 1925-1928): the mass of the complex stays LoD2's (a
## kept skin); the model adds the plenary hall's colonnade, the famous semicircle. The mapped
## outline of the hall is an arc 21.75 m in radius (fitted), bulging south toward Wiejska.
## The model puts a stone plinth ring, fifteen columns under a curved entablature, and a cornice
## at the eave round that arc. Spec docs/landmarks/specs/sejm.md.
## Frame: origin at the arc's centre, u south (the axis of the bulge), +v west; a point at angle
## t off the axis and radius r is (r cos t, r sin t).
const SEJM := Vector2(277.1, 967.5)
const SEJM_R := 21.75
const SEJM_WALL := Color("#e2e0d8")
const SEJM_TRIM := Color("#efece2")
const SEJM_BASE := Color("#b4b0a4")
const SEJM_DARK := Color("#3a3d40")


## One slice of the arc: the ring between radii r0 and r1 from angle t0 to t1 (degrees), as a
## prism between two heights.
func _sejm_slice(t0: float, t1: float, r0: float, r1: float, y0: float, y1: float, col: Color, top: Color) -> void:
	var pts := PackedVector2Array()
	for t: float in [t0, t1]:
		pts.append(_w(r1 * cos(deg_to_rad(t)), r1 * sin(deg_to_rad(t))))
	for t: float in [t1, t0]:
		pts.append(_w(r0 * cos(deg_to_rad(t)), r0 * sin(deg_to_rad(t))))
	_prism(pts, y0, y1, col, top, M_STONE, M_STONE)


func _build_sejm(_site: Dictionary) -> void:
	_o = SEJM
	_a = Vector2(0.0, 1.0)
	_b = Vector2(-_a.y, _a.x)  # (-1, 0)
	_g = map.terrain_height(_w(SEJM_R, 0.0).x, _w(SEJM_R, 0.0).y)
	var g := _g
	_mode = M_STONE
	var half := 84.0  # the colonnade spans 168 degrees of the arc
	var step := 12.0
	var n := int(half * 2.0 / step)  # 14 bays, 15 columns
	# the plinth ring and a step, then the entablature and the eave cornice, in 12-degree slices
	for k in n:
		var t0 := -half + step * k
		var t1 := t0 + step
		_sejm_slice(t0, t1, SEJM_R - 0.4, SEJM_R + 3.0, g - 0.6, g + 0.9, SEJM_BASE, SEJM_BASE.lightened(0.05))
		_sejm_slice(t0, t1, SEJM_R - 0.4, SEJM_R + 2.6, g + 9.4, g + 10.9, SEJM_TRIM, SEJM_TRIM.lightened(0.03))
		_sejm_slice(t0, t1, SEJM_R - 0.4, SEJM_R + 0.25, g + 10.9, g + 16.2, SEJM_WALL, SEJM_WALL)  # the attic wall
		_sejm_slice(t0, t1, SEJM_R - 0.2, SEJM_R + 0.9, g + 16.2, g + 17.2, SEJM_TRIM, SEJM_TRIM.lightened(0.03))
	# the colonnade
	for k in n + 1:
		var t := deg_to_rad(-half + step * k)
		_column(( SEJM_R + 1.6) * cos(t), (SEJM_R + 1.6) * sin(t), 0.5, g + 0.9, g + 9.4, SEJM_TRIM)
	# the door in the middle bay, dark between the columns
	_mode = M_GLASS
	var d0 := deg_to_rad(-6.0)
	var d1 := deg_to_rad(6.0)
	_wall(_w(SEJM_R * cos(d0), SEJM_R * sin(d0)), _w(SEJM_R * cos(d1), SEJM_R * sin(d1)), g + 0.9, g + 6.4, _a, SEJM_DARK)
	_mode = M_STONE
	# the car meets the plinth along the arc
	var ring := PackedVector2Array()
	for k in n + 1:
		var t := deg_to_rad(-half + step * k)
		ring.append(_w((SEJM_R + 3.0) * cos(t), (SEJM_R + 3.0) * sin(t)))
	_collide(ring)


# --- WTS DeSki: the tennis club with the padel courts (F, 2026-11-01) -----------------------------

## WTS DESKA, the parody of WTS DeSki (Zaruskiego 8, by Most Łazienkowski). F (2026-11-02): the real
## club has closed tennis courts and one outdoor padel court. The model: a hipped-roof tennis hall
## over the four western mapped pitches (OSM `pitch` quads), one outdoor glass padel court beside
## it (lit at night, four players, floodlights) and the DESKA neon on the clubhouse, which keeps its
## mapped box. The other mapped pitches stay as the map draws them. docs/design/padel.md. F's photos
## of the real court (2026-11-08): a dark charcoal surface with white lines (not blue), frameless
## glass back walls with black mesh above, black mesh sides on a black steel frame, white padded
## net posts, black floodlight poles, beige deckchairs on the lawn beside it.
const DESKI_PITCHES := [
	[1508.6, 966.3, 1516.4, 963.7, 1521.8, 979.9, 1514.1, 982.5],
	[1500.1, 979.7, 1507.4, 976.0, 1515.2, 991.3, 1508.0, 995.0],
	[1500.4, 927.3, 1507.4, 923.1, 1516.3, 937.7, 1509.3, 942.0],
	[1518.6, 963.5, 1526.3, 961.0, 1531.6, 977.3, 1523.8, 979.8],
	[1467.8, 947.1, 1474.8, 942.9, 1483.8, 957.5, 1476.8, 961.8],
	[1478.3, 941.0, 1485.3, 936.8, 1494.2, 951.4, 1487.3, 955.7],
	[1489.5, 959.6, 1496.7, 955.8, 1504.7, 970.9, 1497.5, 974.7],
	[1478.6, 965.5, 1485.8, 961.8, 1493.9, 976.9, 1486.6, 980.7],
	[1510.5, 945.1, 1517.5, 940.8, 1526.5, 955.5, 1519.5, 959.7],
]
const DESKI_PADEL := Vector2(1519.0, 965.0)
const DESKI_HALL_PITCHES := [4, 5, 6, 7]
const DESKI_HALL_WALL := Color("#cfd4d8")
const DESKI_HALL_ROOF := Color("#8d99a3")
const DESKI_AXIS := Vector2(0.322, 0.947)
const DESKI_CLUBHOUSE := [Vector2(1491.7, 913.2), Vector2(1498.8, 909.0), Vector2(1503.2, 920.8), Vector2(1499.3, 923.0),
		Vector2(1491.5, 925.8), Vector2(1486.8, 917.4)]
const DESKI_CLUBHOUSE_H := 7.6
const DESKI_CLAY := Color("#b5573a")
const DESKI_HARD := Color("#3e7396")
const DESKI_PADEL_BLUE := Color("#3a3f44")
const DESKI_LINE := Color("#f1efe6")
const DESKI_GLASS := Color("#a9c7d4")
const DESKI_FRAME := Color("#16191d")
const DESKI_SHIRTS := [Color("#e8e04a"), Color("#ef5a8a"), Color("#f4f4f0"), Color("#3fb6a8"), Color("#ff8a2a"), Color("#8a6ae0")]
const DESKI_SKIN := Color("#d9a984")


func _find_deski() -> void:
	# A 0.2 m zone at the clubhouse's corner: the mapped box stays; the courts are only drawn on.
	var c := Vector2(1503.2, 920.8)
	_add_site("deski", [PackedVector2Array([c, c + Vector2(0.2, 0), c + Vector2(0.2, 0.2), c + Vector2(0, 0.2)])])
	sites[-1]["box"] = Rect2(1460.0, 905.0, 85.0, 100.0)


func _deski_frame(c: Vector2, axis: Vector2) -> void:
	_o = c
	_a = axis
	_b = Vector2(-axis.y, axis.x)


func _build_deski(_site: Dictionary) -> void:
	_no_roof = true
	_mode = M_STONE
	# The closed tennis hall over the four western pitches: walls 7 m, a hipped roof.
	var hall_c := Vector2.ZERO
	for k in DESKI_HALL_PITCHES:
		var q: Array = DESKI_PITCHES[k]
		for j in 4:
			hall_c += Vector2(q[j * 2], q[j * 2 + 1]) * (0.25 / DESKI_HALL_PITCHES.size())
	_deski_frame(hall_c, DESKI_AXIS)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for k in DESKI_HALL_PITCHES:
		var q: Array = DESKI_PITCHES[k]
		for j in 4:
			var l := _local(Vector2(q[j * 2], q[j * 2 + 1]))
			lo = Vector2(minf(lo.x, l.x), minf(lo.y, l.y))
			hi = Vector2(maxf(hi.x, l.x), maxf(hi.y, l.y))
	var cu := (lo.x + hi.x) * 0.5
	var cv := (lo.y + hi.y) * 0.5
	var hu := (hi.x - lo.x) * 0.5 + 3.0
	var hv := (hi.y - lo.y) * 0.5 + 3.0
	var gh := _ground_under(_rect(cu, cv, hu, hv))
	var wall := DESKI_HALL_WALL
	_prism(_rect(cu, cv, hu, hv), gh - 0.3, gh + 7.0, wall, Color(0, 0, 0, 0), M_STONE)
	# A dark window band under the eaves and a lit door bay on the south-east end.
	_lbox(cu, cv, hu + 0.06, hv + 0.06, gh + 4.6, gh + 5.8, Color("#38424d"), M_STONE)
	_frustum(_rect(cu, cv, hu + 0.4, hv + 0.4), gh + 7.0, _rect(cu, cv, hu * 0.55, hv * 0.55), gh + 9.6, DESKI_HALL_ROOF, DESKI_HALL_ROOF.lightened(0.05))
	_lbox(cu + hu, cv, 0.3, 2.2, gh, gh + 3.2, Color("#ffe9b0"), M_LAMP)
	var hall_ring := _rect(cu, cv, hu, hv)
	_collide(hall_ring)
	# The one outdoor padel court beside the hall, with four players and four floodlights.
	_deski_frame(DESKI_PADEL, DESKI_AXIS)
	var gp: float = map.terrain_height(DESKI_PADEL.x, DESKI_PADEL.y)
	_deski_padel(gp, 0)
	_collide(_rect(0.0, 0.0, 10.0, 5.0))
	for su: float in [-1.0, 1.0]:
		for sv: float in [-1.0, 1.0]:
			var u := su * 11.2
			var v := sv * 6.4
			_lbox(u, v, 0.12, 0.12, gp, gp + 7.0, DESKI_FRAME.lightened(0.08), M_STONE)
			_lbox(u, v - sv * 0.35, 0.5, 0.4, gp + 7.0, gp + 7.3, Color("#fff4cf"), M_LAMP)
	# The club's tube on the clubhouse.
	var ring := PackedVector2Array(DESKI_CLUBHOUSE)
	var gc := _ground_under(ring)
	_crown_signs(ring, gc + DESKI_CLUBHOUSE_H + 0.6, "DESKA", Color(0.25, 0.85, 1.0), 0.0, 0.6)
	_no_roof = false


## One padel court in the current frame: 10 x 20 m of blue, white lines, glass back walls and
## glass on the first 4 m of the sides, a mesh fence between (posts and a top rail), the net.
func _deski_padel(g: float, idx: int) -> void:
	_lbox(0.0, 0.0, 10.3, 5.3, g - 0.2, g + 0.04, DESKI_PADEL_BLUE.darkened(0.3), M_STONE, DESKI_PADEL_BLUE.darkened(0.3))
	# The surface is lit: the court is open round the clock, its floodlights glow at night.
	_prism(_rect(0.0, 0.0, 10.0, 5.0), g + 0.04, g + 0.06, DESKI_PADEL_BLUE.darkened(0.25), DESKI_PADEL_BLUE.darkened(0.25), M_LAMP, M_LAMP)
	var lc := DESKI_LINE
	for sv: float in [-1.0, 1.0]:
		_lbox(0.0, sv * 4.85, 9.9, 0.05, g + 0.06, g + 0.075, lc, M_STONE, lc)
	for su: float in [-1.0, 1.0]:
		_lbox(su * 9.85, 0.0, 0.05, 5.0, g + 0.06, g + 0.075, lc, M_STONE, lc)
		_lbox(su * 6.95, 0.0, 0.04, 4.9, g + 0.06, g + 0.075, lc, M_STONE, lc)
	_lbox(0.0, 0.0, 6.95, 0.04, g + 0.06, g + 0.075, lc, M_STONE, lc)
	# The net: black, a white tape, white padded posts.
	_lbox(0.0, 0.0, 0.03, 5.0, g + 0.15, g + 0.92, Color("#15171a"), M_STONE)
	_lbox(0.0, 0.0, 0.04, 5.0, g + 0.9, g + 0.95, DESKI_LINE, M_STONE)
	for sv: float in [-1.0, 1.0]:
		_lbox(0.0, sv * 5.15, 0.09, 0.09, g, g + 1.05, DESKI_LINE, M_STONE)
	# Glass: the back walls (10 m), the sides' first 4 m at each end; 3 m high, a dark frame on top.
	var gl := DESKI_GLASS
	for su: float in [-1.0, 1.0]:
		_lbox(su * 10.1, 0.0, 0.05, 5.2, g, g + 3.0, gl, M_STONE, DESKI_FRAME)
		for sv: float in [-1.0, 1.0]:
			_lbox(su * 8.0, sv * 5.2, 2.0, 0.04, g, g + 3.0, gl, M_STONE, DESKI_FRAME)
			# the mesh above and between: three posts and a rail
			_lbox(su * 3.5, sv * 5.2, 0.05, 0.05, g, g + 3.0, DESKI_FRAME, M_STONE)
			_lbox(0.0, sv * 5.2, 5.0, 0.03, g + 2.9, g + 3.0, DESKI_FRAME, M_STONE)
		_lbox(su * 10.1, 0.0, 0.07, 5.25, g + 3.0, g + 3.08, DESKI_FRAME, M_STONE)
		# The black mesh above the back glass to 4 m, on a top rail.
		_lbox(su * 10.1, 0.0, 0.02, 5.2, g + 3.08, g + 3.95, Color("#22262b"), M_STONE)
		_lbox(su * 10.1, 0.0, 0.07, 5.25, g + 3.95, g + 4.03, DESKI_FRAME, M_STONE)
	# Two beige DESKA deckchairs on the lawn by the side glass (F's photos): a sling on a black frame.
	if idx == 0:
		for k in 2:
			var cu := -7.5 + k * 1.4
			_lbox(cu, -6.3, 0.32, 0.03, g + 0.25, g + 0.9, Color("#e9dfc6"), M_STONE)
			_lbox(cu, -6.05, 0.32, 0.25, g + 0.3, g + 0.36, Color("#e9dfc6"), M_STONE)
			_lbox(cu, -6.2, 0.34, 0.03, g, g + 0.3, DESKI_FRAME, M_STONE)
	# The players: padel court 0 has four, court 1 two.
	var spots := [Vector2(-6.0, -2.4), Vector2(-5.5, 2.5), Vector2(6.0, -2.4), Vector2(5.5, 2.5)]
	for k in (4 if idx == 0 else 2):
		var sp: Vector2 = spots[k] if idx == 0 else spots[k * 2]
		_deski_player(sp, 0.0 if sp.x < 0.0 else PI, g + 0.06, idx * 4 + k, true)


## A player standing at local (u, v) facing the net (yaw 0: towards +u), racket arm out. 1.75 m,
## about 50 triangles. `padel`: a short racket, otherwise a longer one.
func _deski_player(at: Vector2, yaw: float, y: float, seed_n: int, padel: bool) -> void:
	var fwd := _a * cos(yaw) + _b * sin(yaw)
	var side := Vector2(-fwd.y, fwd.x)
	var pos := _w(at.x, at.y)
	var shirt: Color = DESKI_SHIRTS[seed_n % DESKI_SHIRTS.size()]
	var shorts := Color("#232a3a")
	for sd: float in [-1.0, 1.0]:
		var foot := pos + side * 0.14 * sd + fwd * 0.1 * sd
		_beam(Vector3(pos.x + side.x * 0.1 * sd, y + 0.95, pos.y + side.y * 0.1 * sd), Vector3(foot.x, y + 0.04, foot.y), 0.15, shorts)
	var torso_c := pos + fwd * 0.05
	_beam(Vector3(torso_c.x, y + 0.95, torso_c.y), Vector3(torso_c.x, y + 1.5, torso_c.y), 0.34, shirt)
	_beam(Vector3(pos.x, y + 1.52, pos.y), Vector3(pos.x, y + 1.75, pos.y), 0.2, DESKI_SKIN)
	# Arms: the left down, the right out front holding the racket.
	var hand := pos + fwd * 0.55 + side * 0.25
	_beam(Vector3(pos.x + side.x * 0.2, y + 1.45, pos.y + side.y * 0.2), Vector3(hand.x, y + 1.15, hand.y), 0.1, DESKI_SKIN)
	var lh := pos - side * 0.3
	_beam(Vector3(pos.x - side.x * 0.2, y + 1.45, pos.y - side.y * 0.2), Vector3(lh.x, y + 0.9, lh.y), 0.1, DESKI_SKIN)
	var tip := hand + fwd * (0.3 if padel else 0.5)
	_beam(Vector3(hand.x, y + 1.15, hand.y), Vector3(tip.x, y + 1.3, tip.y), 0.35 if padel else 0.28, Color("#e8483c") if padel else Color("#2b2f36"))


# --- Stadion Leguminy (Legia's ground, Łazienkowska) -----------------------------------------

## Stadion Wojska Polskiego on ul. Łazienkowska, home of the capital's football legion (rebuilt
## 2008-2010, about 31,000 seats), under the parody name "Stadion Leguminy" (spec
## docs/landmarks/specs/legia.md). First built 2026-11-01 with no photos; rebuilt 2026-11-15 from
## twelve Mapillary street photos of its Łazienkowska fronts (refs/legia/street/, never shipped).
## The map has it as one 27 m outline (the bowl), a 20 m west stand and a 5.4 m footprint; the
## model is built from that outline: a light grey concrete podium with a row of windows, the open
## concourse behind tall columns above it with green banners between them, glass at the cut
## corners, and the roof's signature: a row of white membrane tents along the edge, peak after
## peak over a dark steel truss, overhanging the facade. Inside, three rings of seats round a
## striped pitch (105 x 68 m along the bowl's long axis), the floodlights in a lit strip under the
## roof's inner edge (no corner masts: the photos show none), LEGUMINA in neon on the south and
## east fronts.
const LEGIA_AT := Vector2(1139.0, 1500.0)
const LEGIA_GREEN := Color("#2b6e3f")
const LEGIA_RED := Color("#b8212a")
const LEGIA_CONCRETE := Color("#c9cccb")
const LEGIA_RECESS := Color("#2c3136")
const LEGIA_STEEL := Color("#4b5259")
const LEGIA_PODIUM := 8.5
const LEGIA_TOP := 24.5
const LEGIA_EAVE := 26.0
const LEGIA_PEAK := 31.5
const LEGIA_BAY := 12.0


func _find_legia() -> void:
	var outline := _tallest_at(LEGIA_AT)
	if outline.size() < 8:
		return
	var box := _box_of([outline])
	# The mapped bowl is about 165 x 205 m and 27 m high; anything else is another building.
	if box.size.x < 140.0 or box.size.x > 200.0 or box.size.y < 170.0 or box.size.y > 240.0:
		return
	var ring := _simplify(outline, 0.6)
	if Geometry2D.is_polygon_clockwise(ring):
		ring.reverse()
	var c := box.get_center()
	# The pitch's long axis: the outline's principal axis (south-pointing).
	var sxx := 0.0
	var sxy := 0.0
	var syy := 0.0
	for v in ring:
		var d := v - c
		sxx += d.x * d.x
		sxy += d.x * d.y
		syy += d.y * d.y
	var axis := Vector2.from_angle(0.5 * atan2(2.0 * sxy, sxx - syy))
	if axis.y < 0.0:
		axis = -axis
	_add_site("legia", [outline])
	if sites.is_empty() or sites[-1]["key"] != "legia":
		return
	sites[-1]["ring"] = ring
	sites[-1]["centre"] = c
	sites[-1]["axis"] = axis


func _build_legia(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	var c: Vector2 = site["centre"]
	var axis: Vector2 = site["axis"]
	var across := Vector2(axis.y, -axis.x)
	_o = c
	_b = axis
	_a = across
	var n := ring.size()
	var g := _ground_under(ring)
	_g = g
	var pitch: float = map.terrain_height(c.x, c.y)
	var none := Color(0, 0, 0, 0)
	var dirs: Array[Vector2] = []
	for v in ring:
		dirs.append((v - c).normalized())
	# A rounded rectangle round the pitch (half-sizes along and across the axis), sampled at the
	# outline's vertex angles so every ring meets the next one quad by quad.
	var oblong := func(half_a: float, half_b: float, power: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for d: Vector2 in dirs:
			var x := absf(d.dot(axis)) / half_a
			var y := absf(d.dot(across)) / half_b
			out.append(c + d * pow(pow(x, power) + pow(y, power), -1.0 / power))
		return out
	var scaled := func(s: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for v in ring:
			out.append(c + (v - c) * s)
		return out
	# A flat band between two rings of the same corners (k to k), facing up or down.
	var band := func(r0: PackedVector2Array, r1: PackedVector2Array, y: float, col: Color, up: bool) -> void:
		for k in n:
			var k1 := (k + 1) % n
			_quad(Vector3(r0[k].x, y, r0[k].y), Vector3(r0[k1].x, y, r0[k1].y), Vector3(r1[k1].x, y, r1[k1].y),
					Vector3(r1[k].x, y, r1[k].y), Vector3.UP if up else Vector3.DOWN, col)
	# The cut corners (short edges at a slant to the bowl's axes) are glass from the ground to the
	# roof (the photo from the north-east); the long fronts are podium, concourse and columns.
	var corner: Array[bool] = []
	for i in n:
		var e := ring[(i + 1) % n] - ring[i]
		var d := absf(e.normalized().dot(axis))
		corner.append(e.length() < 45.0 and d > 0.3 and d < 0.95)
	# The paved apron round the foot: its sides and a band out from the outline (not a full cap:
	# a full one 15 cm under the pitch won over it in the game's depth buffer, hiding the grass).
	var apron := PackedVector2Array()
	for k in n:
		apron.append(ring[k] + dirs[k] * 4.0)
	_mode = M_STONE
	_prism(apron, g - 1.5, g + 0.25, Color("#a9a79f"), none, M_STONE)
	band.call(ring, apron, g + 0.25, Color("#b6b4ac"), true)
	_collide(ring)
	# The facade: on the long fronts a light grey concrete podium with a row of windows (the kit's
	# punched skin), a ledge, then the open concourse set back 3 m in shadow up to the roof.
	var inset: PackedVector2Array = scaled.call(0.97)
	for i in n:
		var i1 := (i + 1) % n
		var a := ring[i]
		var b := ring[i1]
		var out := _out(ring, a, b)
		if corner[i]:
			_mode = M_GLASS
			_wall(a, b, g - 1.0, g + LEGIA_TOP, out, Color("#3a4652"))
			continue
		_mode = M_SKIN + S_PUNCHED / 16.0
		_wall(a, b, g - 1.0, g + LEGIA_PODIUM, out, LEGIA_CONCRETE)
		_mode = M_STONE
		_quad(Vector3(a.x, g + LEGIA_PODIUM, a.y), Vector3(b.x, g + LEGIA_PODIUM, b.y), Vector3(inset[i1].x, g + LEGIA_PODIUM, inset[i1].y),
				Vector3(inset[i].x, g + LEGIA_PODIUM, inset[i].y), Vector3.UP, LEGIA_CONCRETE.darkened(0.08))
		_wall(inset[i], inset[i1], g + LEGIA_PODIUM, g + LEGIA_TOP, out, LEGIA_RECESS)
		# The recess's ends, where it meets a glass corner.
		for end: Array in [[a, inset[i], corner[(i + n - 1) % n], (b - a).normalized()], [b, inset[i1], corner[i1], (a - b).normalized()]]:
			if end[2]:
				var p: Vector2 = end[0]
				var q: Vector2 = end[1]
				var f: Vector2 = end[3]
				_quad(Vector3(p.x, g + LEGIA_PODIUM, p.y), Vector3(q.x, g + LEGIA_PODIUM, q.y), Vector3(q.x, g + LEGIA_TOP, q.y),
						Vector3(p.x, g + LEGIA_TOP, p.y), Vector3(f.x, 0.0, f.y), LEGIA_CONCRETE.darkened(0.2))
	# The roof: a dark steel truss at the eave, 1.035 x the outline out (about 4 m over the
	# facade), and on it a row of white membrane tents, one a bay (about 12 m), each a low
	# pyramid peaking at 31.5 m 30 % of the way in from the eave to the valley line (0.9 x the
	# outline), its sides meeting the next tent's in a valley at the eave's height.
	var eave: PackedVector2Array = scaled.call(1.035)
	var inner: PackedVector2Array = scaled.call(0.9)
	_mode = M_STONE
	band.call(ring, eave, g + LEGIA_TOP, LEGIA_STEEL.darkened(0.3), false)
	_mode = M_MEMBRANE
	for k in n:
		var k1 := (k + 1) % n
		var out := _out(ring, ring[k], ring[k1])
		_mode = M_STONE
		_wall(eave[k], eave[k1], g + LEGIA_TOP, g + LEGIA_EAVE, out, LEGIA_STEEL)
		_mode = M_MEMBRANE
		var bays := maxi(int(round(eave[k].distance_to(eave[k1]) / LEGIA_BAY)), 1)
		for j in bays:
			var t0 := float(j) / bays
			var t1 := float(j + 1) / bays
			var e0 := eave[k].lerp(eave[k1], t0)
			var e1 := eave[k].lerp(eave[k1], t1)
			var i0 := inner[k].lerp(inner[k1], t0)
			var i1 := inner[k].lerp(inner[k1], t1)
			var top2 := ((e0 + e1) * 0.5).lerp((i0 + i1) * 0.5, 0.3)
			var pk := Vector3(top2.x, g + LEGIA_PEAK, top2.y)
			var y := g + LEGIA_EAVE
			var faces := [[Vector3(e0.x, y, e0.y), Vector3(e1.x, y, e1.y), Color("#f6f6f3")],
					[Vector3(i1.x, y, i1.y), Vector3(i0.x, y, i0.y), Color("#e3e5e4")],
					[Vector3(i0.x, y, i0.y), Vector3(e0.x, y, e0.y), Color("#eceeeb")],
					[Vector3(e1.x, y, e1.y), Vector3(i1.x, y, i1.y), Color("#eceeeb")]]
			for f: Array in faces:
				var p0: Vector3 = f[0]
				var p1: Vector3 = f[1]
				var nr := (p1 - p0).cross(pk - p0).normalized()
				if nr.y < 0.0:
					nr = -nr
				_tri(p0, p1, pk, nr, f[2], Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# The tall columns of the concourse, one at each tent's valley on the long fronts, and green
	# and white banners hung between them on every third bay.
	_mode = M_STONE
	var bay_no := 0
	for k in n:
		if corner[k]:
			continue
		var k1 := (k + 1) % n
		var a := ring[k]
		var b := ring[k1]
		var out := _out(ring, a, b)
		var along := (b - a).normalized()
		var bays := maxi(int(round(eave[k].distance_to(eave[k1]) / LEGIA_BAY)), 1)
		for j in range(0, bays + 1):
			var p := a.lerp(b, float(j) / bays)
			if (j == 0 and corner[(k + n - 1) % n]) or (j == bays and corner[k1]):
				continue  # the glass corner's edge
			var s0 := p - along * 0.6
			var s1 := p + along * 0.6
			_wall(s0 + out * 0.6, s1 + out * 0.6, g + LEGIA_PODIUM, g + LEGIA_TOP, out, Color("#d9dbda"))
			_wall(s0 - out * 0.6, s0 + out * 0.6, g + LEGIA_PODIUM, g + LEGIA_TOP, -along, Color("#b9bcbc"))
			_wall(s1 + out * 0.6, s1 - out * 0.6, g + LEGIA_PODIUM, g + LEGIA_TOP, along, Color("#b9bcbc"))
		for j in bays:
			bay_no += 1
			if bay_no % 3 != 1:
				continue
			var q0 := a.lerp(b, float(j) / bays) + along * 1.4 + out * 0.15
			var q1 := a.lerp(b, float(j + 1) / bays) - along * 1.4 + out * 0.15
			_wall(q0, q1, g + 11.0, g + 19.0, out, LEGIA_GREEN if bay_no % 2 == 1 else Color("#eef0ec"))
	# The membrane inside the tents, from the valley line down to the open middle; its last 5 m
	# grey-blue (the polycarbonate edge), the floodlights in a strip under it.
	var hole: PackedVector2Array = oblong.call(80.0, 61.0, 4.0)
	var hole_y := g + 24.0
	for k in n:
		var k1 := (k + 1) % n
		var p0 := Vector3(inner[k].x, g + LEGIA_EAVE, inner[k].y)
		var p1 := Vector3(inner[k1].x, g + LEGIA_EAVE, inner[k1].y)
		var p2 := Vector3(hole[k1].x, hole_y, hole[k1].y)
		var p3 := Vector3(hole[k].x, hole_y, hole[k].y)
		var g0 := p3 + (p0 - p3) * (5.0 / p0.distance_to(p3))
		var g1 := p2 + (p1 - p2) * (5.0 / p1.distance_to(p2))
		var nr := (p1 - p0).cross(p3 - p0).normalized()
		if nr.y < 0.0:
			nr = -nr
		_mode = M_MEMBRANE
		_quad(p0, p1, g1, g0, nr, Color("#f4f4f1") if k % 2 == 0 else Color("#e9eae7"))
		_quad(g0, g1, p2, p3, nr, Color("#8f9aa3") if k % 2 == 0 else Color("#98a2aa"))
		var face := Vector3(c.x - (hole[k].x + hole[k1].x) * 0.5, 0.0, c.y - (hole[k].y + hole[k1].y) * 0.5).normalized()
		_mode = M_LAMP
		_quad(p3 + Vector3(0.0, -1.0, 0.0), p2 + Vector3(0.0, -1.0, 0.0), p2 + Vector3(0.0, -0.3, 0.0), p3 + Vector3(0.0, -0.3, 0.0),
				face, Color("#fff1c9"))
	# The bowl, from the pitch out: boards, the lower tier, a gangway, the dark glass of the
	# boxes, the upper tier up under the roof. Seats in blocks of white, green and red.
	_mode = M_STONE
	var seat_cols := [Color("#e9ebe8"), LEGIA_GREEN.lightened(0.18), LEGIA_RED.lightened(0.12), Color("#e9ebe8"), LEGIA_GREEN.lightened(0.18)]
	var bowl := [
		[oblong.call(58.0, 41.0, 8.0), pitch + 0.4, Color("#2d3138"), false],
		[oblong.call(58.0, 41.0, 8.0), pitch + 1.2, Color("#d0d3d6"), true],
		[oblong.call(78.0, 61.0, 6.0), pitch + 10.0, Color("#8e8a88"), false],
		[oblong.call(81.0, 64.0, 6.0), pitch + 10.0, Color("#3d4652"), false],
		[oblong.call(81.0, 64.0, 6.0), pitch + 14.0, Color("#d0d3d6"), true],
		[inner, pitch + 23.5, Color(), false]]
	for t in range(1, bowl.size()):
		var r0: PackedVector2Array = bowl[t - 1][0]
		var y0: float = bowl[t - 1][1]
		var col: Color = bowl[t - 1][2]
		var seats: bool = bowl[t - 1][3]
		var r1: PackedVector2Array = bowl[t][0]
		var y1: float = bowl[t][1]
		for k in n:
			var k1 := (k + 1) % n
			var p0 := Vector3(r0[k].x, y0, r0[k].y)
			var p1 := Vector3(r0[k1].x, y0, r0[k1].y)
			var p2 := Vector3(r1[k1].x, y1, r1[k1].y)
			var p3 := Vector3(r1[k].x, y1, r1[k].y)
			var nr := (p1 - p0).cross(p3 - p0).normalized()
			if absf(nr.y) < 0.2:
				var mid := (r0[k] + r0[k1]) * 0.5 - c
				if Vector2(nr.x, nr.z).dot(mid) > 0.0:
					nr = -nr
			elif nr.y < 0.0:
				nr = -nr
			var tone := col
			if seats:
				tone = seat_cols[(k * 7 + t * 3) % seat_cols.size()]
			_quad(p0, p1, p2, p3, nr, tone)
	# The pitch: grass out to the boards, mown in stripes, white lines.
	_cap(bowl[0][0], pitch + 0.4, Color("#4f8a3a"))
	var flat := func(a: Vector2, b: Vector2, w: float, y: float, col: Color) -> void:
		var s := (b - a).normalized().orthogonal() * w * 0.5
		_quad(Vector3(a.x - s.x, y, a.y - s.y), Vector3(b.x - s.x, y, b.y - s.y), Vector3(b.x + s.x, y, b.y + s.y),
				Vector3(a.x + s.x, y, a.y + s.y), Vector3.UP, col)
	var at := func(x: float, y: float) -> Vector2: return c + axis * x + across * y
	for b in 12:
		if b % 2 == 0:
			var x0 := -52.5 + b * 8.75
			flat.call(at.call(x0, 0.0), at.call(x0 + 8.75, 0.0), 68.0, pitch + 0.43, Color("#5a9643"))
	var line := Color("#f2f2ee")
	var y_long := pitch + 0.47
	var y_short := pitch + 0.50
	for side: float in [-1.0, 1.0]:
		flat.call(at.call(-52.5, side * 34.0), at.call(52.5, side * 34.0), 0.6, y_long, line)
		flat.call(at.call(side * 52.5, -34.3), at.call(side * 52.5, 34.3), 0.6, y_short, line)
	flat.call(at.call(0.0, -34.3), at.call(0.0, 34.3), 0.6, y_short, line)
	# LEGUMINA in neon on the two fronts the game's camera sees most (the longest edge facing
	# south, the longest facing east): the sign's width is 0.55 of the front's.
	var word := "LEGUMINA"
	for want: Vector2 in [Vector2(0.0, 1.0), Vector2(1.0, 0.0)]:
		var best_i := -1
		var best_len := 0.0
		for i in n:
			var a := ring[i]
			var b := ring[(i + 1) % n]
			var len := a.distance_to(b)
			if len > best_len and _out(ring, a, b).dot(want) > 0.8:
				best_len = len
				best_i = i
		if best_i < 0:
			continue
		var ea := ring[best_i]
		var eb := ring[(best_i + 1) % n]
		var eo := _out(ring, ea, eb)
		var mid_e := (ea + eb) * 0.5 + eo * 0.6
		signs.append([word, Vector3(mid_e.x, g + 15.0, mid_e.y), Vector3(eo.x, 0.0, eo.y),
				minf(60.0, best_len * 0.55) / Neon.length_of(word), Color(0.35, 1.0, 0.55)])


# --- Zamek Ujazdowski ---------------------------------------------------------------------------

## Ujazdowski Castle (F, 2026-11-01: "improve Ujazdów and the castle on it"). Baroque, built for
## Sigismund III in 1619-24, razed in 1944, rebuilt from 1975 as the Centre for Contemporary Art.
## Four steep-roofed wings round a square courtyard, a round tower with a copper cap at each
## outer corner, a forward portal in the west wing and a wide projecting bay in the east one,
## over the escarpment. OSM maps the outline (towers as bumps), the eaves (8.8 m), the ridges
## (15 m) and the copper roofs; the courtyard, the portal and the tower caps are our estimates
## (no photo from the cloud). Frame: u along the north wall (2.25 degrees off east), +v south.
## Spec docs/landmarks/specs/ujazdowski.md.
const UJ_O := Vector2(460.5, 1601.7)
const UJ_ANGLE := 0.03927
const UJ_WALL := Color("#ece4d0")
const UJ_STONE := Color("#bdb4a0")
const UJ_TRIM := Color("#f5efe0")
const UJ_COPPER := Color("#8fae9b")
const UJ_EAVE := 9.0
const UJ_TOWERS := [Vector2(-28.2, -26.5), Vector2(24.0, -26.5), Vector2(24.0, 26.5), Vector2(-28.2, 26.5)]
## The four wings: u centre, v centre, half u, half v (west, east, north, south).
const UJ_WINGS := [Vector4(-22.4, 0.25, 5.0, 25.75), Vector4(18.6, 0.25, 5.0, 25.75),
		Vector4(-1.9, -20.75, 15.5, 4.75), Vector4(-1.9, 21.25, 15.5, 4.75)]


func _find_ujazdowski() -> void:
	var ring := _landmark("Zamek Ujazdowski")
	if ring.size() >= 3:
		_add_site("ujazdowski", [ring])


func _build_ujazdowski(site: Dictionary) -> void:
	var ring: PackedVector2Array = (site["zone"] as Array)[0]
	var none := Color(0, 0, 0, 0)
	_o = UJ_O
	_a = Vector2(cos(UJ_ANGLE), sin(UJ_ANGLE))
	_b = Vector2(-_a.y, _a.x)
	_g = _ground_under(ring)
	var g := _g
	var copper_dark := UJ_COPPER.darkened(0.12)
	for wi in UJ_WINGS.size():
		var w: Vector4 = UJ_WINGS[wi]
		var e := UJ_EAVE + 0.01 * wi  # a hair apart, so the wings' coplanar eaves don't z-fight
		_lbox(w.x, w.y, w.z, w.w, g - 0.6, g + e - 0.4, UJ_WALL, M_MONUMENT, none)
		_lbox(w.x, w.y, w.z + 0.25, w.w + 0.25, g - 0.6, g + 1.1, UJ_STONE, M_STONE)  # the plinth
		_lbox(w.x, w.y, w.z + 0.4, w.w + 0.4, g + e - 0.8, g + e, UJ_TRIM, M_STONE)  # the cornice
		_mode = M_STONE
		_hip(w.x, w.y, w.z + 0.7, w.w + 0.7, g + e, 6.2, UJ_COPPER)
	# The east wing's wide bay and its lower roof.
	_lbox(26.45, 0.25, 2.85, 12.25, g - 0.6, g + UJ_EAVE, UJ_WALL, M_MONUMENT, none)
	_lbox(26.45, 0.25, 3.1, 12.5, g - 0.6, g + 1.1, UJ_STONE, M_STONE)
	_lbox(26.45, 0.25, 3.25, 12.65, g + UJ_EAVE - 0.8, g + UJ_EAVE, UJ_TRIM, M_STONE)
	_mode = M_STONE
	_hip(26.45, 0.25, 3.55, 13.0, g + UJ_EAVE, 3.4, UJ_COPPER)
	# The round towers: plinth, shaft, cornice, then a flared bell, a lantern and a spire.
	for t: Vector2 in UJ_TOWERS:
		var c := _w(t.x, t.y)
		_mode = M_STONE
		_prism(_circle(c, 3.65, 8), g - 0.6, g + 1.3, UJ_STONE, none, M_STONE)
		_prism(_circle(c, 3.35, 8), g - 0.6, g + 16.0, UJ_WALL, none, M_MONUMENT)
		_prism(_circle(c, 3.8, 8), g + 15.1, g + 16.0, UJ_TRIM, UJ_TRIM.darkened(0.06), M_STONE, M_STONE)
		_mode = M_STONE
		_frustum(_circle(c, 3.9, 8), g + 16.0, _circle(c, 4.1, 8), g + 17.0, UJ_COPPER)
		_frustum(_circle(c, 4.1, 8), g + 17.0, _circle(c, 2.3, 8), g + 19.8, UJ_COPPER)
		_frustum(_circle(c, 2.3, 8), g + 19.8, _circle(c, 1.3, 8), g + 21.6, copper_dark)
		_prism(_circle(c, 1.0, 8), g + 21.6, g + 23.0, UJ_TRIM, none, M_STONE)
		_pyramid(_circle(c, 1.25, 8), g + 23.0, g + 26.5, copper_dark)
	_portal(g)
	_dormers(g)
	_o = UJ_O  # the portal and the dormers turned the frame: back to the castle's own
	_a = Vector2(cos(UJ_ANGLE), sin(UJ_ANGLE))
	_b = Vector2(-_a.y, _a.x)
	_mode = M_STONE
	for ch: Vector2 in [Vector2(-22.4, -12.0), Vector2(-22.4, 13.0), Vector2(18.6, -14.0), Vector2(18.6, 14.0),
			Vector2(-8.0, -20.75), Vector2(6.0, 21.25)]:  # six chimneys on the ridges
		_lbox(ch.x, ch.y, 0.45, 0.45, g + 13.2, g + 16.8, UJ_STONE.darkened(0.15), M_STONE, UJ_STONE.darkened(0.3))
	_collide(ring)


## The west portal: three steps, a bay standing 1.2 m out, a lit door between trimmed posts and a
## pediment over the eave, in a frame turned to face out of the wall.
func _portal(g: float) -> void:
	_b = -Vector2(cos(UJ_ANGLE), sin(UJ_ANGLE))  # out of the west wall
	_a = Vector2(-_b.y, _b.x)
	_o = _w_main(-27.4, 0.25)
	_mode = M_STONE
	for k in 3:
		var d := 0.9 * (3 - k)
		_lbox(0.0, 1.2 + d * 0.5, 3.4, d * 0.5, g - 0.4, g + 0.2 * (k + 1), UJ_STONE.lightened(0.04), M_STONE)
	_lbox(0.0, 0.6, 4.0, 0.6, g - 0.6, g + UJ_EAVE + 1.4, UJ_WALL, M_MONUMENT, UJ_TRIM)
	_mode = M_PAVILION
	_wall(_w(-1.1, 1.23), _w(1.1, 1.23), g + 0.8, g + 4.6, _b, Color("#f3d9a8"))
	_mode = M_STONE
	for sd: float in [-1.0, 1.0]:
		_lbox(sd * 1.5, 1.25, 0.3, 0.08, g + 0.6, g + 5.2, UJ_TRIM, M_STONE)
		_mode = M_LAMP
		_lbox(sd * 2.8, 1.3, 0.1, 0.1, g + 2.6, g + 3.0, HOTEL_LAMP, M_LAMP)
		_mode = M_STONE
	_lbox(0.0, 1.25, 1.9, 0.08, g + 4.6, g + 5.2, UJ_TRIM, M_STONE)
	_a = _b  # the pediment's frame: u out of the wall, v across
	_b = Vector2(-_a.y, _a.x)
	_lbox(0.4, 0.0, 0.8, 4.3, g + UJ_EAVE + 1.4, g + UJ_EAVE + 2.0, UJ_TRIM, M_STONE)
	_gable(1.2, -0.4, 0.0, 4.3, g + UJ_EAVE + 2.0, 2.2, UJ_TRIM, UJ_COPPER)


## A point in the castle's own frame (the portal turns the working frame, so this one doesn't).
func _w_main(u: float, v: float) -> Vector2:
	var a := Vector2(cos(UJ_ANGLE), sin(UJ_ANGLE))
	return UJ_O + a * u + Vector2(-a.y, a.x) * v


## Hipped dormers on the four outer roof faces, one every 6 m, clear of the portal.
func _dormers(g: float) -> void:
	var a0 := Vector2(cos(UJ_ANGLE), sin(UJ_ANGLE))
	var b0 := Vector2(-a0.y, a0.x)
	# [start, end] of each face and its outward normal, in the castle frame.
	var faces := [
		[Vector2(-27.4, -22.0), Vector2(-27.4, 22.0), -a0],  # west
		[Vector2(-22.0, -25.5), Vector2(19.0, -25.5), -b0],  # north
		[Vector2(-22.0, 26.0), Vector2(19.0, 26.0), b0],     # south
		[Vector2(23.6, -24.0), Vector2(23.6, -13.5), a0],    # east, north of the bay
		[Vector2(23.6, 14.0), Vector2(23.6, 24.0), a0],      # east, south of the bay
	]
	for f in faces:
		var p0 := _w_main((f[0] as Vector2).x, (f[0] as Vector2).y)
		var p1 := _w_main((f[1] as Vector2).x, (f[1] as Vector2).y)
		var out: Vector2 = f[2]
		var flen := p0.distance_to(p1)
		var cnt := floori(flen / 6.0) + 1
		_o = p0
		_b = out
		_a = (p1 - p0) / flen
		for j in cnt:
			var u := flen * (j + 0.5) / cnt
			if f[0] == Vector2(-27.4, -22.0) and absf(u - flen * 0.5) < 5.5:
				continue  # the portal's pediment
			var y := g + UJ_EAVE + 2.2
			_mode = M_STONE
			_lbox(u, -2.2, 0.55, 0.6, y, y + 2.1, UJ_WALL, M_STONE, UJ_WALL)
			_hip(u, -2.2, 0.7, 0.75, y + 2.1, 0.8, UJ_COPPER.lightened(0.05))
			_mode = M_GLASS
			_wall(_w(u - 0.32, -1.59), _w(u + 0.32, -1.59), y + 0.4, y + 1.7, out, Color("#353a40"))
const SOBIESKI_H := 31.0
## The postmodern bands of the hotel on Plac Zawiszy: salmon, butter yellow, mint, teal, one magenta stripe.
const SOBIESKI_BANDS := [Color("#e59a86"), Color("#f0d27a"), Color("#8fd0b4"), Color("#2f8f9a")]
const SOBIESKI_MAGENTA := Color("#c2287a")


## Radisson Blu Sobieski (Plac Zawiszy 1) as "Radysław Blu": the OSM outline is a plain extrusion,
## the real hotel is a block in colourful postmodern bands. Built whole from the outline's `ring`:
## three set-back tiers in salmon, yellow and mint under a teal crown, a magenta stripe, coloured
## fins on every public front, and a canopy with the name on the longest one. Spec sobieski.md.
func _build_sobieski(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	var g := _ground_under(ring)
	_g = g
	var none := Color(0, 0, 0, 0)
	var n := ring.size()
	var salmon: Color = SOBIESKI_BANDS[0]
	var yellow: Color = SOBIESKI_BANDS[1]
	var mint: Color = SOBIESKI_BANDS[2]
	var teal: Color = SOBIESKI_BANDS[3]
	var glass := Color("#3a4650")
	_mode = M_STONE
	_prism(_inset_ring(ring, -0.3), g - 0.6, g + 4.6, teal.darkened(0.25), none, M_STONE)  # the plinth
	_bays(ring, 0.9, 4.0, 4.0, 2.2, glass, PackedVector2Array())
	_prism(ring, g + 4.6, g + 13.0, salmon, none, M_MONUMENT)
	_prism(_inset_ring(ring, -0.35), g + 13.0, g + 13.7, _magenta_dark(), none, M_STONE)  # the stripe
	var t2 := _inset_ring(ring, 1.4)
	_prism(t2, g + 13.7, g + 22.0, yellow, none, M_MONUMENT)
	_prism(_inset_ring(t2, -0.3), g + 22.0, g + 22.6, SOBIESKI_MAGENTA, none, M_STONE)
	var t3 := _inset_ring(ring, 2.8)
	_prism(t3, g + 22.6, g + SOBIESKI_H - 2.2, mint, none, M_MONUMENT)
	_prism(_inset_ring(t3, -0.25), g + SOBIESKI_H - 2.2, g + SOBIESKI_H, teal, teal.lightened(0.1), M_STONE, M_STONE)  # the crown
	var avoid_front := -1
	var front_len := 0.0
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var el := a.distance_to(b)
		if el > front_len:
			front_len = el
			avoid_front = i
		if el < 10.0:
			continue
		_o = a
		_b = _out(ring, a, b)
		_a = (b - a) / el
		var cnt := floori((el - 3.0) / 6.0)
		var u0 := (el - (cnt - 1) * 6.0) * 0.5
		for j in cnt:  # coloured fins up the salmon and yellow tiers
			var u := u0 + j * 6.0
			var col: Color = SOBIESKI_BANDS[(j + i) % 4]
			_lbox(u, 0.2, 0.28, 0.3, g + 4.6, g + 13.0, col.darkened(0.08), M_STONE, col)
			_lbox(u, -1.2, 0.28, 0.3, g + 13.7, g + 22.0, col.lightened(0.05), M_STONE, col)
	if avoid_front < 0 or front_len < 16.0:
		_collide(ring)
		return
	var a2 := ring[avoid_front]
	var b2 := ring[(avoid_front + 1) % n]
	var out := _out(ring, a2, b2)
	_o = (a2 + b2) * 0.5
	_b = out
	_a = (b2 - a2) / front_len
	_mode = M_PAVILION
	_wall(_w(-3.2, 0.62), _w(3.2, 0.62), g + 0.05, g + 4.0, out, Color("#f3d9a8"))
	_mode = M_STONE
	_lbox(0.0, 2.2, 4.2, 1.6, g + 4.2, g + 4.5, SOBIESKI_MAGENTA, M_STONE, SOBIESKI_MAGENTA.lightened(0.12))
	for sd: float in [-1.0, 1.0]:
		_column(sd * 3.8, 3.4, 0.14, g - 0.2, g + 4.2, Color("#f2ebd8"))
	_lbox(0.0, 0.55, 5.0, 0.12, g + 4.8, g + 6.4, Color("#1f2a33"), M_STONE, Color("#2a3844"))
	var word := "RADYSŁAW BLU"
	var face := _w(0.0, 0.7)
	signs.append([word, Vector3(face.x, g + 5.05, face.y), Vector3(out.x, 0.0, out.y),
			minf(0.2, 8.6 / Neon.length_of(word)), Color(0.3, 0.85, 1.0)])
	_collide(ring)


func _magenta_dark() -> Color:
	return SOBIESKI_MAGENTA.darkened(0.15)


# Powiśle's boulevards (Bulwary Wiślane, rebuilt 2017-2020) between Most Śląsko-Dąbrowski and
# Tamka: OpenStreetMap maps the six concrete bar pavilions set into Bulwar Grzymały-Siedleckiego
# as 4.3 m boxes, and the boulevard's bar containers and kiosks at Karowa, by the Marina barge
# and by Kaskada as blocks up to 14 m tall. Here the pavilions get glass river fronts, green
# roofs, terraces with umbrellas and bulbs; the containers are corrugated shipping boxes with a
# lit hatch, an awning and deck chairs; timber deck strips with leżaki line the water's edge.
# Parody names only (no real bar's name on a sign or a card).


# --- Stacja Filtrów (F, 2026-11-06): spec docs/landmarks/specs/filtry.md -----------------------

const FT_C := Vector2(-1951.0, 1206.0)  # the tower's centre, on the orthophoto
const FT_R := 7.0  # the shaft's radius at the plinth
const FT_BRICK := Color("#a84a32")
const FT_BRICK_DARK := Color("#8a3a28")
const FT_STONE := Color("#c9bda6")
const FT_BUST := Vector2(-1937.0, 1226.0)  # Starynkiewicz, south-east of the tower


## One ring of the tower: a round prism from y0 to y1 at radius r.
func _ft_ring(r: float, y0: float, y1: float, col: Color, top := Color(0, 0, 0, 0)) -> void:
	_prism(_circle(FT_C, r, 28), _g + y0, _g + y1, col, top, M_STONE, M_STONE)


## A flat panel on the round wall at angle a: width w, from y0 to y1, standing at radius r.
func _ft_panel(a: float, r: float, w: float, y0: float, y1: float, depth: float, col: Color) -> void:
	var o := Vector2.from_angle(a)
	var s := Vector2(-o.y, o.x) * (w * 0.5)
	var p := FT_C + o * r
	var q := o * depth
	_prism(PackedVector2Array([p - s, p + s, p + s + q, p - s + q]), _g + y0, _g + y1, col, col, M_STONE, M_STONE)


## The water tower (Lindley, 1885-86), about 42 m: a brick shaft with slim pilasters and string
## courses, then the wider tank drum on a corbel table, its round-headed windows, a parapet and a
## low cap with a mast. Beside it the bust of Starynkiewicz (1907) on its plinth.
func _build_filtry(site: Dictionary) -> void:
	_g = _ground_under(site["raw"])
	var none := Color(0, 0, 0, 0)
	_ft_ring(FT_R + 0.5, -0.3, 1.6, FT_BRICK_DARK, FT_STONE)
	_ft_ring(FT_R, 1.6, 12.0, FT_BRICK)
	_ft_ring(FT_R + 0.14, 12.0, 12.5, FT_STONE)
	_ft_ring(FT_R - 0.15, 12.5, 23.0, FT_BRICK)
	_ft_ring(FT_R - 0.01, 23.0, 23.5, FT_STONE)
	_ft_ring(FT_R - 0.3, 23.5, 31.0, FT_BRICK)
	# The corbel table carries the tank, which overhangs the shaft.
	_ft_ring(FT_R + 0.1, 31.0, 31.7, FT_BRICK_DARK)
	_ft_ring(FT_R + 0.55, 31.7, 32.4, FT_STONE)
	_ft_ring(FT_R + 0.7, 32.4, 38.6, FT_BRICK, none)
	_ft_ring(FT_R + 1.0, 38.6, 39.3, FT_STONE)
	_ft_ring(FT_R + 0.85, 39.3, 40.4, FT_BRICK, Color("#5f665f"))
	_ft_ring(2.6, 40.4, 41.6, Color("#5f665f"), Color("#4e5552"))
	_ft_ring(0.08, 41.6, 47.0, Color("#3c4044"), none)
	var bays := 16
	for k in bays:
		var a := TAU * k / bays
		_ft_panel(a, FT_R - 0.02, 0.5, 1.6, 12.0, 0.12, FT_BRICK_DARK)
		_ft_panel(a, FT_R - 0.17, 0.5, 12.5, 23.0, 0.12, FT_BRICK_DARK)
		_ft_panel(a, FT_R - 0.32, 0.5, 23.5, 31.0, 0.12, FT_BRICK_DARK)
		var w := a + PI / bays
		_ft_panel(w, FT_R + 0.68, 1.0, 33.4, 37.2, 0.05, Color("#2f3a42"))
		_ft_panel(w, FT_R + 0.7, 1.4, 37.2, 37.6, 0.08, FT_STONE)
	for k in 4:  # the stair's slit windows, a quarter round apart
		var a := TAU * k / 4 + 0.4
		for y in [6.0, 17.0, 27.0]:
			_ft_panel(a, FT_R - 0.32 if y > 24.0 else (FT_R - 0.17 if y > 12.5 else FT_R), 0.8, y, y + 2.4, 0.36, Color("#2f3a42"))
	_ft_panel(1.2, FT_R, 2.0, 0.0, 2.6, 0.55, Color("#3a2a22"))  # the door
	# The bust: a pale plinth, a dark bronze head and shoulders.
	var keep := _g
	var pl := _circle(FT_BUST, 0.8, 8)
	_g = _ground_under(pl)
	_prism(pl, _g - 0.2, _g + 1.9, FT_STONE, FT_STONE, M_STONE, M_STONE)
	_prism(_circle(FT_BUST, 0.45, 8), _g + 1.9, _g + 2.5, Color("#3e4a44"), Color("#3e4a44"), M_STONE, M_STONE)
	_prism(_circle(FT_BUST, 0.26, 8), _g + 2.5, _g + 2.95, Color("#3e4a44"), Color("#3e4a44"), M_STONE, M_STONE)
	_g = keep
	_collide_raw(site)


# --- Polskie Radio (Myśliwiecka 3/5/7, docs/landmarks/specs/polskie_radio.md) -------------------

## Polskie Radio headquarters on Myśliwiecka: a ~130 m pale-cream three-storey block with a wider
## cross-wing in the middle, regular tall window rhythm, steep grey hipped roofs with small dormers
## on both long slopes, two chimneys, and a simple stone-framed east entrance with a flat canopy,
## flagpole pair and white RADIO sign. Colours measured from refs/polskie_radio/ and the spec.
const PR_NAME := "Polskie Radio"
const PR_WALL := Color("#d8d0bd")       # pale cream render
const PR_PLINTH := Color("#a9a394")     # ground plinth band
const PR_CORNICE := Color("#e3ddcd")    # plain eave cornice
const PR_SURROUND := Color("#cfc6b1")   # entrance stone surround
const PR_FRAME := Color("#e6e3db")      # white window frames and sills
const PR_GLASS := Color("#4a5660")      # tall office window glass
const PR_ROOF := Color("#6c7277")       # steep grey slate hipped roof
const PR_CHIMNEY := Color("#8a7f74")    # roof chimney blocks
const PR_CANOPY := Color("#bfc3c6")     # flat entrance canopy
const PR_ENTRANCE_GLOW := Color("#e8d4a2")  # warm entrance glazing (M_PAVILION at night)
const PR_SIGN_WHITE := Color("#ffffff") # plain white RADIO letters (M_LAMP)
const PR_PLINTH_H := 0.8
const PR_EAVE_H := 10.9
const PR_ROOF_RISE := 3.6
const PR_BAY := 2.8


## Finds Polskie Radio's OSM landmark outline by name and registers a 0.5 m outward zone so the
## map's 10.9 m office prisms under the outline are replaced while outside sheds stay as they are.
func _find_polskie_radio() -> void:
	var raw := _landmark(PR_NAME)
	if raw.size() < 3:
		push_error("polskie_radio: landmark outline '%s' is missing from centrum.json" % PR_NAME)
		return
	var zone := _largest(Geometry2D.offset_polygon(raw, 0.5, Geometry2D.JOIN_MITER))
	if zone.size() < 3:
		zone = raw
	_add_site("polskie_radio", [zone])
	if not sites.is_empty() and sites[-1]["key"] == "polskie_radio":
		sites[-1]["raw"] = raw


## Simplifies `raw` to its main straight runs: rotates to an extreme corner so Douglas-Peucker
## keeps all true wing corners while dropping small bumps, merges near-collinear edges, and ensures
## counter-clockwise winding.
func _pr_simplify(raw: PackedVector2Array) -> PackedVector2Array:
	var c := _centre(raw)
	var start := 0
	var best_d := -1.0
	for i in raw.size():
		var d := raw[i].distance_squared_to(c)
		if d > best_d:
			best_d = d
			start = i
	var rot := PackedVector2Array()
	for i in raw.size():
		rot.append(raw[(start + i) % raw.size()])
	var cur := _simplify(rot, 1.9)
	if cur.size() < 3:
		cur = rot
	var changed := true
	while changed and cur.size() > 3:
		changed = false
		var next := PackedVector2Array()
		var n := cur.size()
		for i in n:
			var prev := cur[(i + n - 1) % n]
			var p := cur[i]
			var nxt := cur[(i + 1) % n]
			var d0 := p - prev
			var d1 := nxt - p
			if d0.length() < 0.2 or d1.length() < 0.2:
				changed = true
				continue
			if d0.normalized().dot(d1.normalized()) > 0.996:
				changed = true
				continue
			next.append(p)
		cur = next
	if Geometry2D.is_polygon_clockwise(cur):
		cur.reverse()
	return cur if cur.size() >= 3 else raw


## Starts a kit_front along edge a->b oriented so _b matches the outward normal `out`.
func _pr_front_edge(a: Vector2, b: Vector2, out: Vector2) -> float:
	var dir := (b - a).normalized()
	if Vector2(-dir.y, dir.x).dot(out) < 0.0:
		return kit_front(b, a)
	return kit_front(a, b)


## Builds Polskie Radio's headquarters: cream three-storey block with plinth and cornice rings,
## regular window grids on all faces, stone-framed east entrance with canopy, flagpoles and RADIO
## sign, steep grey hipped main and cross roofs with dormers and two chimneys, and full collision.
func _build_polskie_radio(site: Dictionary) -> void:
	var raw: PackedVector2Array = site.get("raw", PackedVector2Array())
	if raw.size() < 3:
		return
	var ring := _pr_simplify(raw)
	var g := _ground_under(raw)
	_g = g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	# Establish the block's main frame: _a pointing north along the long axis, _b pointing east.
	var axis := Vector2(0.0, -1.0)
	var longest := 0.0
	for i in ring.size():
		var e := ring[(i + 1) % ring.size()] - ring[i]
		if e.length() > longest:
			longest = e.length()
			axis = e.normalized()
	if axis.y > 0.0:
		axis = -axis
	var east := Vector2(-axis.y, axis.x)
	var block_o := _centre(ring)
	_o = block_o
	_a = axis
	_b = east
	# Measure main bar and wider middle cross-wing extents in local (u north, v east).
	var u0 := INF
	var u1 := -INF
	for p in ring:
		var l := _local(p)
		u0 = minf(u0, l.x)
		u1 = maxf(u1, l.x)
	var vm0 := INF
	var vm1 := -INF
	var vw0 := INF
	var vw1 := -INF
	var um0 := INF
	var um1 := -INF
	for p in ring:
		var l := _local(p)
		vw0 = minf(vw0, l.y)
		vw1 = maxf(vw1, l.y)
		if absf(l.x) > (u1 - u0) * 0.35:
			vm0 = minf(vm0, l.y)
			vm1 = maxf(vm1, l.y)
	for p in ring:
		var l := _local(p)
		if l.y < vm0 - 1.5 or l.y > vm1 + 1.5:
			um0 = minf(um0, l.x)
			um1 = maxf(um1, l.x)
	# Main three-storey body prism, dark attic floor cap (5 cm below cornice top), plinth and cornice.
	_prism(ring, g - 0.5, g + PR_EAVE_H, PR_WALL, none, M_STONE)
	_cap(ring, g + PR_EAVE_H - 0.05, PR_ROOF.darkened(0.25))
	kit_ledge_ring(ring, g - 0.4, PR_PLINTH_H + 0.4, PR_PLINTH, 0.10)
	kit_cornice_ring(ring, g + PR_EAVE_H - 0.35, PR_CORNICE, 0.35, 0.40)
	# Dress every face of the simplified outline: entrance front, long wings, short ends and returns.
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var ln := a.distance_to(b)
		if ln < 2.5:
			continue
		var out := _out(ring, a, b)
		var mid_l := _local((a + b) * 0.5)
		var is_ew_face := absf(out.dot(east)) > 0.7
		var kind := "return"
		if is_ew_face and out.dot(east) > 0.7 and mid_l.y > vm1 + 1.5:
			kind = "entrance"
		elif is_ew_face and ln > 25.0:
			kind = "long"
		elif is_ew_face:
			kind = "west_wing"
		elif ln > 10.0:
			kind = "end"
		_pr_dress_face(a, b, out, g, kind)
		_o = block_o
		_a = axis
		_b = east
	# Steep grey hipped roof over the main bar and cross-wing, dormers along both long slopes, chimneys.
	_pr_roof(g, u0, u1, vm0, vm1, um0, um1, vw0, vw1)
	_collide(raw)
	_mode = M_STONE


## Dresses one straight facade of Polskie Radio with three rows of tall windows (1.3 x 2.0 m) using
## kit parts: hero entrance front and short ends use `kit_window_grid`, long wings use `kit_panes`
## with continuous pale sill ledges to stay within the 3,000-triangle L2 budget.
func _pr_dress_face(a: Vector2, b: Vector2, out: Vector2, g: float, kind: String) -> void:
	var w := _pr_front_edge(a, b, out)
	var sills := [g + 1.40, g + 4.75, g + 8.10]
	match kind:
		"entrance":
			var bays := maxi(3, roundi((w - 1.2) / PR_BAY))
			if bays % 2 == 0:
				bays += 1
			var mid_bay := bays / 2
			kit_window_grid(0.8, w - 0.8, bays, sills, 2.0, Win.SILL, PR_FRAME, PR_GLASS, 0.65,
					[Vector2i(mid_bay, 0)])
			_pr_entrance(w * 0.5, g)
		"end":
			var bays := clampi(roundi((w - 4.0) / 5.5), 2, 4)
			kit_window_grid(2.4, w - 2.4, bays, sills, 2.0, Win.SILL, PR_FRAME, PR_GLASS, 0.65)
		"long", "west_wing":
			var margin := 0.9 if kind == "west_wing" else 1.2
			var bays := maxi(3, roundi((w - 2.0 * margin) / PR_BAY))
			var cols := _spread(margin, w - margin, bays)
			kit_panes(cols, sills, 1.3, 2.0, PR_GLASS, 0.06)
		_:
			var bays := maxi(1, roundi((w - 1.2) / PR_BAY))
			kit_panes(_spread(0.8, w - 0.8, bays), sills, 1.3, 2.0, PR_GLASS, 0.06)


## Builds the main entrance on Myśliwiecka: stone step and surround standing proud of the plinth,
## double-leaf kit_door with warm night-glowing glass (M_PAVILION), flat 2.0 m canopy on slim
## posts, twin flagpoles framing the risalit, and the white RADIO sign over the canopy.
func _pr_entrance(cu: float, g: float) -> void:
	var keep := _mode
	_mode = M_STONE
	# Entrance step and flanking stone surround jambs + lintel (#cfc6b1) standing clear of the plinth.
	_kbox(cu - 2.05, cu + 2.05, 0.14, 1.75, g - 0.4, g + 0.16, PR_PLINTH)
	_kbox(cu - 1.92, cu - 1.28, -0.02, 0.34, g - 0.3, g + 3.44, PR_SURROUND)
	_kbox(cu + 1.28, cu + 1.92, -0.02, 0.34, g - 0.3, g + 3.44, PR_SURROUND)
	_kbox(cu - 1.96, cu + 1.96, -0.02, 0.36, g + 3.45, g + 3.92, PR_SURROUND)
	# Double-leaf door (2.4 x 3.0 m) on a 0.18 m face proud of the 0.10 m plinth.
	kit_face(0.18)
	kit_door(cu, g + 0.16, 3.0, 1.20, PR_SURROUND, PAL_DARK_DOOR)
	# Warm glowing entrance glass panels (double leaf, M_PAVILION) 4 cm proud of the door leaf.
	_mode = M_PAVILION
	_wall(_w(cu - 1.06, 0.27), _w(cu - 0.08, 0.27), g + 0.36, g + 2.96, _b, PR_ENTRANCE_GLOW)
	_wall(_w(cu + 0.08, 0.27), _w(cu + 1.06, 0.27), g + 0.36, g + 2.96, _b, PR_ENTRANCE_GLOW)
	kit_face(0.0)
	_mode = M_STONE
	# Thin flat canopy 2.0 m deep (#bfc3c6) resting on two slender steel posts.
	_kbox(cu - 2.60, cu + 2.60, 0.02, 2.08, g + 3.94, g + 4.20, PR_CANOPY)
	for s: float in [-1.0, 1.0]:
		var pu := cu + s * 2.35
		_kbox(pu - 0.07, pu + 0.07, 1.80, 1.94, g - 0.2, g + 3.94, PAL_DARK_STEEL)
	# Dark signboard fascia on the canopy front and 0.7 m white RADIO letters (_usign, the shared sign helper).
	_kbox(cu - 2.00, cu + 2.00, 1.86, 2.00, g + 4.20, g + 5.14, PAL_DARK_STEEL)
	_usign("RADIO", cu, 2.08, g + 4.28, _b, 3.0, 0.72, PR_SIGN_WHITE)
	# Flagpole pair framing the outer edges of the entrance risalit, clear of the windows.
	for s: float in [-1.0, 1.0]:
		var fu := cu + s * 5.4
		var fv := 2.6
		_lbox(fu, fv, 0.22, 0.22, g - 0.3, g + 0.36, PR_PLINTH)
		_lbox(fu, fv, 0.05, 0.05, g + 0.36, g + 8.6, PAL_ALUMINIUM)
		_kbox(fu + 0.05, fu + 1.25, fv - 0.02, fv + 0.02, g + 8.05, g + 8.50, PAL_WHITE_STONE)
		_kbox(fu + 0.05, fu + 1.25, fv - 0.02, fv + 0.02, g + 7.60, g + 8.05, PAL_SIGNAL_RED)
	_mode = keep


## Builds Polskie Radio's steep grey hipped roofs (main N-S ridge and intersecting cross-wing
## ridge tucked cleanly into it), rows of kit_dormer along both long slopes, and two chimneys.
func _pr_roof(g: float, u0: float, u1: float, vm0: float, vm1: float,
		um0: float, um1: float, vw0: float, vw1: float) -> void:
	var eave := g + PR_EAVE_H
	var over := 0.35
	var cu := (u0 + u1) * 0.5
	var cv := (vm0 + vm1) * 0.5
	var hu := (u1 - u0) * 0.5 + over
	var hv := (vm1 - vm0) * 0.5 + over
	_mode = M_STONE
	# Main north-south hipped roof rising 3.6 m to its ridge.
	_hip(cu, cv, hu, hv, eave, PR_ROOF_RISE, PR_ROOF)
	# Cross hipped roof over the wider middle transept (8 cm below the main ridge so it tucks cleanly
	# into the main ridge with zero coplanar ridge-cap z-fighting).
	if um1 > um0 + 4.0 and vw1 > vw0 + 16.0:
		_hip((um0 + um1) * 0.5, (vw0 + vw1) * 0.5, (um1 - um0) * 0.5 + over,
				(vw1 - vw0) * 0.5 + over, eave, PR_ROOF_RISE - 0.08, PR_ROOF)
	# Rows of small dormers (kit_dormer) sitting low on both long slopes (5 on the longer south wing,
	# 4 on the north wing per side = 18 total), clear of the hip ends and cross-roof.
	var d_in := 1.95
	var slope_y := eave + PR_ROOF_RISE * (d_in / maxf(hv - 0.15, 1.0))
	var spans := [[u0 + hv + 2.5, um0 - 3.5, 5], [um1 + 3.5, u1 - hv - 2.5, 4]]
	for sp: Array in spans:
		var sa: float = sp[0]
		var sb: float = sp[1]
		var cnt: int = sp[2]
		if sb <= sa + 4.0:
			continue
		for du: float in _spread(sa, sb, cnt):
			for side: float in [-1.0, 1.0]:
				var at := _w(du, cv + side * (hv - d_in))
				kit_dormer(at, _b * side, slope_y, PR_ROOF.lightened(0.06), PR_FRAME, PR_GLASS)
	# Two masonry chimney blocks (#8a7f74) rising cleanly through the roof ridge on north and south wings.
	for ch_u: float in [lerpf(u0, um0, 0.5), lerpf(um1, u1, 0.5)]:
		_lbox(ch_u, cv, 0.65, 0.55, eave + PR_ROOF_RISE - 0.9, eave + PR_ROOF_RISE + 1.25, PR_CHIMNEY)
		_lbox(ch_u, cv, 0.78, 0.68, eave + PR_ROOF_RISE + 1.25, eave + PR_ROOF_RISE + 1.42, PR_CHIMNEY.darkened(0.18))


# --- Dom Poselski and Stary Dom Poselski (Wiejska 4/6/8, docs/landmarks/specs/dom_poselski.md) --

## Dom Poselski (the deputies' hotel, 1970s-80s): a stepped seven-storey grey concrete block
## (24.1 m) with long dark ribbon windows between pale spandrel bands, blank lighter-grey stair
## towers rising 2.5 m above the roof at outer corners, an inset dark-glazed ground floor with a
## south entrance canopy toward the Sejm, and a flat roof with a 0.8 m parapet and plant boxes.
## Colours from docs/landmarks/specs/dom_poselski.md and refs/dp_new/3dtiles/.
const DP_NAME := "Dom Poselski"
const DP_CONCRETE := Color("#a9aaa6")       # main concrete body
const DP_TOWER := Color("#b9b9b4")          # blank concrete service towers
const DP_SPANDREL := Color("#c3c4bf")       # pale horizontal spandrel bands
const DP_GLASS := Color("#2e3236")          # dark ribbon window glass
const DP_ROOF := Color("#8d969c")           # flat roof membrane
const DP_PLANT := Color("#6f767b")          # roof plant boxes
const DP_CANOPY := Color("#bfc3c6")         # south entrance flat canopy
const DP_ENTRANCE_GLOW := Color("#e8d4a2")  # warm entrance glazing (M_PAVILION at night)
const DP_PLINTH_H := 1.0
const DP_STOREY := 3.3
const DP_GROUND_H := 4.3                    # 1.0 m plinth + 3.3 m ground storey
const DP_H := 24.1                          # 1.0 + 7 * 3.3 m
const DP_TOWER_H := 26.6                    # 2.5 m above the 24.1 m main roof
const DP_PARAPET_H := 0.8

## Stary Dom Poselski (1930s, built with the Sejm): six storeys of cream stone (22.5 m) over a
## two-storey rusticated base (7.0 m), dense vertical windows on 2.6 m bays round both straight
## faces and curved corners, a big rounded west corner on Wiejska, a round east drum rising to
## 24.5 m by the Sejm hall, a Wiejska double-leaf entrance, and a low grey hipped roof (2.5 m)
## with dormers and three chimneys. Colours from docs/landmarks/specs/dom_poselski.md and refs/dp_old/.
const SDP_NAME := "Stary Dom Poselski"
const SDP_STONE := Color("#ddd6c6")         # upper cream stone body and cornice
const SDP_BASE := Color("#cfc7b5")          # rusticated two-storey base
const SDP_FRAME := Color("#ece8de")         # white window frames and sills
const SDP_GLASS := Color("#4a5660")         # vertical window glass
const SDP_ROOF := Color("#74797b")          # low grey hipped roof and drum cap
const SDP_CHIMNEY := Color("#8a7f74")       # masonry chimney stacks
const SDP_ENTRANCE_GLOW := Color("#e8d4a2") # warm Wiejska entrance glass (M_PAVILION at night)
const SDP_BASE_H := 7.0
const SDP_EAVE_H := 22.5
const SDP_ROOF_RISE := 2.5
const SDP_DRUM_TOP := 24.5
const SDP_BAY := 2.6


## Finds Dom Poselski's OSM landmark outline by name and registers a 0.5 m outward zone so the
## map's 24.1 m hotel prism under it is replaced while the Sejm and neighbours stay untouched.
func _find_dom_poselski() -> void:
	var raw := _landmark(DP_NAME)
	if raw.size() < 3:
		push_error("dom_poselski: landmark outline '%s' is missing from centrum.json" % DP_NAME)
		return
	var zone := _largest(Geometry2D.offset_polygon(raw, 0.5, Geometry2D.JOIN_MITER))
	if zone.size() < 3:
		zone = raw
	_add_site("dom_poselski", [zone])
	if not sites.is_empty() and sites[-1]["key"] == "dom_poselski":
		sites[-1]["raw"] = raw


## Cleans `raw` into straight runs by dropping edges shorter than `min_edge` and collinear nodes
## (dot > `col_dot`), then ensures counter-clockwise winding. Preserves curved arcs when `col_dot`
## is strict (0.9985 drops < 3 deg bends while keeping ~9 deg quarter-circle segments intact).
func _dp_clean_ring(raw: PackedVector2Array, min_edge: float, col_dot: float) -> PackedVector2Array:
	var cur := PackedVector2Array(raw)
	var changed := true
	while changed and cur.size() > 3:
		changed = false
		var next := PackedVector2Array()
		var n := cur.size()
		for i in n:
			var prev := cur[(i + n - 1) % n]
			var p := cur[i]
			var nxt := cur[(i + 1) % n]
			var d0 := p - prev
			var d1 := nxt - p
			if d0.length() < min_edge:
				changed = true
				continue
			if d1.length() > 0.001 and d0.normalized().dot(d1.normalized()) > col_dot:
				changed = true
				continue
			next.append(p)
		cur = next
	if Geometry2D.is_polygon_clockwise(cur):
		cur.reverse()
	return cur if cur.size() >= 3 else raw


## Starts a kit_front along edge a->b oriented so _b matches the outward normal `out`.
func _dp_front_edge(a: Vector2, b: Vector2, out: Vector2) -> float:
	var dir := (b - a).normalized()
	if Vector2(-dir.y, dir.x).dot(out) < 0.0:
		return kit_front(b, a)
	return kit_front(a, b)


## Computes Dom Poselski's five 6 x 6 m blank concrete service towers as local Rect2 footprints
## (u, v) measured directly from `ring` (never hardcoded offsets) and anchored slightly proud of the
## outer wing corners and stair-core projections so they never z-fight and cleanly cut the ribbons.
func _dp_tower_rects(ring: PackedVector2Array) -> Array[Rect2]:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in ring:
		var l := _local(p)
		lo = lo.min(l)
		hi = hi.max(l)
	# Measure the north-central step (east end of the v == lo.y edge), NE wing north edge,
	# west spine stair bump (its exact min/max v), and SE spine corner directly from `ring`.
	var nc_u1 := -INF
	var ne_v0 := INF
	var wb_u0 := INF
	var wb_v0 := INF
	var wb_v1 := -INF
	var se_u := -INF
	var se_v := -INF
	for p in ring:
		var l := _local(p)
		if l.y < lo.y + 1.0:
			nc_u1 = maxf(nc_u1, l.x)
		if l.x > hi.x - 15.0:
			ne_v0 = minf(ne_v0, l.y)
		if l.x > lo.x + 10.0 and l.x < hi.x - 20.0 and l.y > lo.y + 30.0 and l.y < hi.y - 25.0:
			wb_u0 = minf(wb_u0, l.x)
		if l.x > hi.x - 35.0 and l.y > hi.y - 12.0 and l.y < hi.y - 3.0:
			se_u = maxf(se_u, l.x)
			se_v = maxf(se_v, l.y)
	for p in ring:
		var l := _local(p)
		if wb_u0 < INF and absf(l.x - wb_u0) < 0.8 and l.y > lo.y + 30.0 and l.y < hi.y - 25.0:
			wb_v0 = minf(wb_v0, l.y)
			wb_v1 = maxf(wb_v1, l.y)
	var towers: Array[Rect2] = []
	# 1. North-west wing outer corner.
	towers.append(Rect2(lo.x - 0.22, lo.y - 0.22, 6.2, 6.2))
	# 2. North-central stair projection (measured at the east end of the north-most edge).
	if nc_u1 > lo.x + 10.0:
		towers.append(Rect2(nc_u1 - 6.0, lo.y - 0.22, 6.22, 6.2))
	# 3. North-east wing outer corner.
	if ne_v0 < INF:
		towers.append(Rect2(hi.x - 5.98, ne_v0 - 0.22, 6.2, 6.2))
	# 4. West central spine stair core projection (measured from its actual bump vertices).
	if wb_u0 < INF and wb_v1 > wb_v0 + 2.0:
		towers.append(Rect2(wb_u0 - 0.22, wb_v0 - 0.22, 5.8, (wb_v1 - wb_v0) + 0.44))
	# 5. South-east spine corner facing the Sejm courtyard.
	if se_u > -INF and se_v > -INF:
		towers.append(Rect2(se_u - 5.8, se_v - 5.98, 6.02, 6.2))
	return towers


## Splits face span [0, w] along world edge a->b into sub-intervals clear of `towers` (grown by
## `pad`), so ribbons and spandrels stop cleanly against every blank service tower.
func _dp_free_spans(a: Vector2, b: Vector2, out: Vector2, w: float, towers: Array[Rect2],
		block_o: Vector2, block_a: Vector2, block_b: Vector2, pad := 0.35) -> Array[Vector2]:
	var spans: Array[Vector2] = [Vector2(0.35, w - 0.35)]
	if w <= 0.7:
		return []
	var dir := (b - a) / w
	for tr in towers:
		var grown := tr.grow(pad)
		var next: Array[Vector2] = []
		for sp in spans:
			var t0 := sp.x
			var t1 := sp.y
			# Sample along the span to find where the face passes through or along this tower box.
			var steps := maxi(8, ceili((t1 - t0) / 0.5))
			var in_free := false
			var seg_start := t0
			for k in steps + 1:
				var t := lerpf(t0, t1, float(k) / float(steps))
				var wp := a + dir * t + out * 0.08
				var d := wp - block_o
				var lp := Vector2(d.dot(block_a), d.dot(block_b))
				var blocked := grown.has_point(lp)
				if not blocked and not in_free:
					seg_start = t
					in_free = true
				elif blocked and in_free:
					if t - seg_start > 1.2:
						next.append(Vector2(seg_start, t))
					in_free = false
			if in_free and t1 - seg_start > 1.2:
				next.append(Vector2(seg_start, t1))
		spans = next
		if spans.is_empty():
			break
	return spans


## Builds Dom Poselski: inset dark-glazed ground floor with south Sejm entrance and flat canopy,
## six upper storeys of dark ribbon windows (kit_panes) over pale spandrel ledges (kit_ledge),
## five blank concrete service towers rising to 26.6 m with cap ledges, flat roof with 0.8 m
## parapet and rooftop plant boxes, and full outline collision.
func _build_dom_poselski(site: Dictionary) -> void:
	var raw: PackedVector2Array = site.get("raw", PackedVector2Array())
	if raw.size() < 3:
		return
	var ring := _dp_clean_ring(raw, 0.5, 0.996)
	var g := _ground_under(raw)
	_g = g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	# Align block frame to the building's dominant east-west axis (+u east, +v south).
	var axis := Vector2(1.0, 0.0)
	var longest := 0.0
	for i in ring.size():
		var e := ring[(i + 1) % ring.size()] - ring[i]
		if e.length() > longest and absf(e.x) > absf(e.y):
			longest = e.length()
			axis = e.normalized()
	if axis.x < 0.0:
		axis = -axis
	var south := Vector2(-axis.y, axis.x)
	var block_o := _centre(ring)
	_o = block_o
	_a = axis
	_b = south
	var towers := _dp_tower_rects(ring)
	var g_top := g + DP_GROUND_H
	var roof_y := g + DP_H
	# Ground floor set back 1.0 m under the overhanging upper body, sealed by a concrete soffit.
	var inset := _largest(Geometry2D.offset_polygon(ring, -1.0, Geometry2D.JOIN_MITER))
	if inset.size() < 3:
		inset = ring
	_prism(inset, g - 0.5, g_top, DP_CONCRETE.darkened(0.08), none, M_STONE)
	kit_ledge_ring(inset, g - 0.4, DP_PLINTH_H + 0.4, DP_CONCRETE.darkened(0.20), 0.08)
	_soffit(ring, g_top, DP_CONCRETE.darkened(0.24))
	# Upper body (4.3 - 24.1 m) in light grey concrete, capped at roof membrane height.
	_prism(ring, g_top, roof_y, DP_CONCRETE, DP_ROOF, M_STONE, M_STONE)
	# Identify the south-most entrance face toward the Sejm complex.
	var south_i := -1
	var best_v := -INF
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if a.distance_to(b) < 12.0:
			continue
		if _out(ring, a, b).dot(south) > 0.8:
			var mv := _local((a + b) * 0.5).y
			if mv > best_v:
				best_v = mv
				south_i = i
	# Build the five blank concrete service towers (0 - 26.6 m) with thin cap ledges.
	for tr in towers:
		var t_ring := _lrect(tr)
		_prism(t_ring, g - 0.5, g + DP_TOWER_H, DP_TOWER, DP_ROOF.darkened(0.06), M_STONE, M_STONE)
		kit_ledge_ring(t_ring, g + DP_TOWER_H - 0.35, 0.35, DP_TOWER.lightened(0.06), 0.14)
	# Dress every straight face of the upper body with 6 storeys of pale spandrels + dark ribbons.
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var ln := a.distance_to(b)
		if ln < 2.2:
			continue
		var out := _out(ring, a, b)
		var w := _dp_front_edge(a, b, out)
		var fa := _o
		var fb := _o + _a * w
		var spans := _dp_free_spans(fa, fb, out, w, towers, block_o, axis, south)
		for sp in spans:
			var u0 := sp.x
			var u1 := sp.y
			var slen := u1 - u0
			var cols := _spread(u0 + 0.08, u1 - 0.08, maxi(1, roundi((slen - 0.16) / 1.5)))
			var pane_w := clampf((slen - 0.16) / float(cols.size()) - 0.09, 0.70, 1.42)
			var win_rows: Array[float] = []
			for fl in 6:
				var fy := g_top + float(fl) * DP_STOREY
				kit_ledge(u0, u1, fy, 1.32, DP_SPANDREL, 0.09)
				win_rows.append(fy + 1.44)
			kit_panes(cols, win_rows, pane_w, 1.54, DP_GLASS, 0.06)
			# Ground floor dark glass and structural overhang piers on street faces.
			if i == south_i:
				_dp_entrance(u0, u1, g)
			else:
				kit_face(-1.0)
				kit_panes(cols, [g + DP_PLINTH_H + 0.35], pane_w, 2.55, DP_GLASS, 0.06)
				kit_face(0.0)
				if slen >= 8.0:
					var n_piers := maxi(2, roundi(slen / 11.0))
					for k in range(1, n_piers):
						var pu := lerpf(u0, u1, float(k) / float(n_piers))
						_kbox(pu - 0.32, pu + 0.32, -1.04, -0.04, g - 0.4, g_top - 0.02, DP_CONCRETE.darkened(0.06))
		_o = block_o
		_a = axis
		_b = south
	# Flat roof parapet (0.8 m tall) and rooftop plant boxes clear of the service towers.
	_dp_roof(ring, towers, g, roof_y)
	_collide(raw)
	_mode = M_STONE


## Builds Dom Poselski's south ground-floor entrance toward the Sejm: three kit_shop_bay openings
## on the inset ground wall with warm night-glowing M_PAVILION glass, flanked by concrete piers,
## and a thin flat 2.5 m deep canopy (#bfc3c6) on two slender steel posts.
func _dp_entrance(u0: float, u1: float, g: float) -> void:
	var keep := _mode
	var cu := (u0 + u1) * 0.5
	var avail := u1 - u0
	var bay_hw := clampf(avail * 0.14, 1.1, 1.65)
	var step := bay_hw * 2.0 + 0.55
	kit_face(-1.0)
	for k: int in [-1, 0, 1]:
		var bu := cu + float(k) * step
		if bu - bay_hw < u0 + 0.3 or bu + bay_hw > u1 - 0.3:
			continue
		kit_shop_bay(bu, g + 0.15, g + 3.45, bay_hw, DP_SPANDREL, DP_GLASS)
		# Warm entrance glass (M_PAVILION) 4 cm proud of kit_shop_bay's pane so it glows at night.
		_mode = M_PAVILION
		_wall(_w(bu - bay_hw + 0.12, -0.91), _w(bu + bay_hw - 0.12, -0.91), g + 0.25, g + 3.35, _b, DP_ENTRANCE_GLOW)
		_mode = M_STONE
	kit_face(0.0)
	# Thin flat canopy projecting 2.5 m from the inset ground wall (v = -1.0 to +1.5) on slim posts.
	var cw := minf(avail * 0.46, 5.8)
	_kbox(cu - cw, cu + cw, -1.02, 1.50, g + 3.70, g + 4.02, DP_CANOPY)
	_kbox(cu - cw - 0.06, cu + cw + 0.06, -1.02, 1.56, g + 4.02, g + 4.12, DP_CANOPY.darkened(0.18))
	for s: float in [-1.0, 1.0]:
		var pu := cu + s * (cw - 0.40)
		_kbox(pu - 0.12, pu + 0.12, 1.16, 1.40, g - 0.3, g + 3.70, PAL_DARK_STEEL)
	_mode = keep


## Builds Dom Poselski's 0.8 m perimeter roof parapet with pale coping and rooftop plant boxes
## (2 x 4 m, 1.8 m tall, #6f767b) plus low vent housings strictly inside the roof and clear of towers.
func _dp_roof(ring: PackedVector2Array, towers: Array[Rect2], g: float, roof_y: float) -> void:
	_mode = M_STONE
	var inner := _largest(Geometry2D.offset_polygon(ring, -0.35, Geometry2D.JOIN_MITER))
	_prism(ring, roof_y, roof_y + DP_PARAPET_H, DP_SPANDREL, Color(0, 0, 0, 0), M_STONE)
	if inner.size() >= 3:
		# Inner face of parapet and thin coping ring on top (reversed winding turns walls inward).
		var rev := PackedVector2Array(inner)
		rev.reverse()
		_prism(rev, roof_y + 0.02, roof_y + DP_PARAPET_H, DP_CONCRETE.darkened(0.10), Color(0, 0, 0, 0), M_STONE)
	kit_ledge_ring(ring, roof_y + DP_PARAPET_H - 0.14, 0.14, DP_SPANDREL.lightened(0.04), 0.12)
	# Six plant boxes (2 x 4 m, 1.8 m tall) and three low vent housings across the roof.
	var candidates := [
		[Vector4(-15.5, -24.5, 2.0, 1.0), 1.8, DP_PLANT],   # NW wing plant box
		[Vector4(11.0, -21.0, 2.0, 1.0), 1.8, DP_PLANT],    # N central bar plant box
		[Vector4(23.5, -18.5, 2.0, 1.0), 1.8, DP_PLANT],    # NE wing plant box
		[Vector4(-0.5, -12.0, 1.0, 2.0), 1.8, DP_PLANT],    # central spine north plant box
		[Vector4(-0.5, 10.5, 1.0, 2.0), 1.8, DP_PLANT],     # central spine south plant box
		[Vector4(-5.5, 27.5, 2.0, 1.0), 1.8, DP_PLANT],     # south wing plant box
		[Vector4(-15.5, -19.5, 1.1, 0.7), 1.0, DP_PLANT.lightened(0.08)],  # NW vent housing
		[Vector4(16.5, -13.5, 1.2, 0.7), 1.0, DP_PLANT.lightened(0.08)],   # NE vent housing
		[Vector4(-4.0, 20.5, 0.8, 1.2), 1.1, DP_PLANT.lightened(0.08)],    # south spine vent
	]
	for item: Array in candidates:
		var cb: Vector4 = item[0]
		var bh: float = item[1]
		var col: Color = item[2]
		var box_r := Rect2(cb.x - cb.z, cb.y - cb.w, cb.z * 2.0, cb.w * 2.0)
		var blocked := false
		for tr in towers:
			if tr.grow(0.6).intersects(box_r):
				blocked = true
				break
		if blocked:
			continue
		var corners := _rect(cb.x, cb.y, cb.z + 0.6, cb.w + 0.6)
		var ok := true
		for c_pt in corners:
			if not Geometry2D.is_point_in_polygon(c_pt, ring):
				ok = false
				break
		if not ok:
			continue
		_lbox(cb.x, cb.y, cb.z, cb.w, roof_y, roof_y + bh, col, M_STONE, col.darkened(0.12))
		_lbox(cb.x, cb.y, cb.z + 0.08, cb.w + 0.08, roof_y + bh, roof_y + bh + 0.14, col.lightened(0.08))


## Finds Stary Dom Poselski's OSM landmark outline by name and registers a 0.5 m outward zone so
## the map's 22.5 m block and 22-24.5 m east drum under it are replaced while the Sejm stays clear.
func _find_stary_dom_poselski() -> void:
	var raw := _landmark(SDP_NAME)
	if raw.size() < 3:
		push_error("stary_dom_poselski: landmark outline '%s' is missing from centrum.json" % SDP_NAME)
		return
	var zone := _largest(Geometry2D.offset_polygon(raw, 0.5, Geometry2D.JOIN_MITER))
	if zone.size() < 3:
		zone = raw
	# Find the east-corner round drum (min_height >= 20 m) dynamically inside the outline, not by index.
	var drum_parts := _parts_in(zone, func(b: Dictionary) -> bool:
			return float(b.get("mh", 0.0)) >= 20.0 and float(b.get("h", 0.0)) >= 23.0)
	var drum_ring := PackedVector2Array()
	if not drum_parts.is_empty():
		drum_ring = _pts(drum_parts[0]["p"])
	_add_site("stary_dom_poselski", [zone])
	if not sites.is_empty() and sites[-1]["key"] == "stary_dom_poselski":
		sites[-1]["raw"] = raw
		sites[-1]["drum"] = drum_ring


## Builds Stary Dom Poselski: cream stone six-storey block on its round-cornered outline with a
## two-storey rusticated base (kit_bands) and 7.0 m string course, dense vertical windows on every
## face and round both curved corners, double-leaf Wiejska entrance with warm night glow, 22.5 m
## cornice ring, low grey hipped roof with dormers and three chimneys, east round drum to 24.5 m,
## and full outline collision.
func _build_stary_dom_poselski(site: Dictionary) -> void:
	var raw: PackedVector2Array = site.get("raw", PackedVector2Array())
	if raw.size() < 3:
		return
	# Keep round corners round (>= 8 segments per quarter circle) while merging straight runs.
	var ring := _dp_clean_ring(raw, 0.35, 0.9985)
	var g := _ground_under(raw)
	_g = g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	# Main north-bar frame: +u east along the longest north edge, +v south into the courtyard.
	var axis := Vector2(1.0, 0.0)
	var longest := 0.0
	for i in ring.size():
		var e := ring[(i + 1) % ring.size()] - ring[i]
		if e.length() > longest and absf(e.x) > absf(e.y):
			longest = e.length()
			axis = e.normalized()
	if axis.x < 0.0:
		axis = -axis
	var south := Vector2(-axis.y, axis.x)
	var block_o := _centre(ring)
	_o = block_o
	_a = axis
	_b = south
	# Two-storey rusticated base (0 - 7.0 m), upper cream stone body (7.0 - 22.5 m), attic floor cap.
	_prism(ring, g - 0.5, g + SDP_BASE_H, SDP_BASE, none, M_STONE)
	_prism(ring, g + SDP_BASE_H, g + SDP_EAVE_H, SDP_STONE, none, M_STONE)
	_cap(ring, g + SDP_EAVE_H - 0.05, SDP_ROOF.darkened(0.18))
	# Ground plinth lip, 7.0 m string course ring, and 22.5 m main cornice ring.
	kit_ledge_ring(ring, g - 0.4, 0.95, SDP_BASE.darkened(0.10), 0.08)
	kit_ledge_ring(ring, g + SDP_BASE_H - 0.16, 0.32, SDP_FRAME, 0.14)
	kit_cornice_ring(ring, g + SDP_EAVE_H - 0.40, SDP_STONE, 0.40, 0.45)
	# Identify the long angled Wiejska street face (facing SW, length > 20 m) and the north central risalit.
	var wiejska_dir := Vector2(-0.78, 0.62).normalized()
	var wiejska_i := _edge_facing(ring, wiejska_dir, 20.0)
	var sills := [g + 1.15, g + 4.20, g + 8.05, g + 11.60, g + 15.15, g + 18.70]
	var win_h := [2.20, 2.05, 2.20, 2.20, 2.15, 1.95]
	# Group consecutive short curved edges into arcs so curved corners get evenly spaced windows
	# and continuous base rustication bands without overlapping sills.
	var n := ring.size()
	var is_curve: Array[bool] = []
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var ln := a.distance_to(b)
		var prev_e := (a - ring[(i + n - 1) % n]).normalized()
		var cur_e := (b - a).normalized()
		var next_e := (ring[(i + 2) % n] - b).normalized()
		var d0 := prev_e.dot(cur_e)
		var d1 := cur_e.dot(next_e)
		is_curve.append(ln >= 0.3 and ln <= 2.3 and ((d0 > 0.78 and d0 < 0.998) or (d1 > 0.78 and d1 < 0.998)))
	# Dress every straight edge (length >= 4.5 m) with kit_window_grid or kit_panes + sill ledges.
	for i in n:
		if is_curve[i]:
			continue
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var ln := a.distance_to(b)
		if ln < 4.5:
			continue
		var out := _out(ring, a, b)
		var mid_l := _local((a + b) * 0.5)
		var kind := "courtyard"
		if i == wiejska_i:
			kind = "wiejska"
		elif out.dot(-south) > 0.8 and mid_l.y < -12.0:
			kind = "north_risalit"
		elif out.dot(-south) > 0.8 or out.dot(axis) > 0.8:
			kind = "outer_long"
		elif ln > 12.0 and (mid_l.y > 16.0 or mid_l.x < -25.0):
			kind = "end"
		_sdp_dress_face(a, b, out, g, sills, win_h, kind)
		_o = block_o
		_a = axis
		_b = south
	# Dress the two outer rounded corners (west Wiejska corner and east drum corner).
	_sdp_dress_curves(ring, is_curve, g, sills, win_h, block_o, axis, south)
	_o = block_o
	_a = axis
	_b = south
	# Low hipped grey roof (2.5 m), dormers on street slopes, three chimney stacks, and east drum.
	var drum_ring: PackedVector2Array = site.get("drum", PackedVector2Array())
	_sdp_roof_and_drum(ring, drum_ring, wiejska_i, g, block_o, axis, south)
	_collide(raw)
	_mode = M_STONE


## Dresses one straight face of Stary Dom Poselski: base rustication via kit_bands on outer faces,
## dense 2.6 m bay windows (hero Wiejska and north risalit use kit_window_grid with Win.SILL,
## other faces use kit_panes with crisp white kit_ledge sill bands to stay under 7,000 triangles),
## and the double-leaf Wiejska entrance door.
func _sdp_dress_face(a: Vector2, b: Vector2, out: Vector2, g: float, sills: Array, win_h: Array,
		kind: String) -> void:
	var w := _dp_front_edge(a, b, out)
	var margin := 1.1
	var bays := maxi(2, roundi((w - 2.0 * margin) / SDP_BAY))
	if kind == "wiejska":
		if bays % 2 == 0:
			bays += 1
		var mid_bay := bays / 2
		var centres := _spread(margin, w - margin, bays)
		var cu: float = centres[mid_bay]
		# Rusticated two-storey base grooves (kit_bands) split cleanly around the entrance surround.
		if cu - 2.1 > 0.4:
			kit_bands(0.15, cu - 2.05, g + 0.4, g + SDP_BASE_H - 0.25, 1.8, SDP_BASE)
		if w - (cu + 2.1) > 0.4:
			kit_bands(cu + 2.05, w - 0.15, g + 0.4, g + SDP_BASE_H - 0.25, 1.8, SDP_BASE)
		# Hero Wiejska windows with white sills and crisp white sash crosses.
		for fl in sills.size():
			var sy: float = sills[fl]
			var sh: float = win_h[fl]
			for k in bays:
				if fl == 0 and k == mid_bay:
					continue
				kit_window(centres[k], sy, sh, Win.SILL, SDP_FRAME, SDP_GLASS, 0.65, SDP_FRAME)
		_sdp_entrance(cu, g)
		return
	if kind == "north_risalit" or kind == "outer_long" or kind == "end":
		kit_bands(0.15, w - 0.15, g + 0.4, g + SDP_BASE_H - 0.25, 1.8, SDP_BASE)
	var cols := _spread(margin, w - margin, bays)
	for fl in sills.size():
		var sy: float = sills[fl]
		var sh: float = win_h[fl]
		kit_ledge(margin - 0.5, w - margin + 0.5, sy - 0.20, 0.16, SDP_FRAME, 0.13)
		kit_panes(cols, [sy], 1.30, sh, SDP_GLASS, 0.06)


## Places windows and rustication grooves around Stary Dom Poselski's outer curved corners
## (west Wiejska quarter drum and east corner drum), skipping the tight concave courtyard corner.
func _sdp_dress_curves(ring: PackedVector2Array, is_curve: Array[bool], g: float, sills: Array,
		win_h: Array, block_o: Vector2, axis: Vector2, south: Vector2) -> void:
	var n := ring.size()
	# Find contiguous runs of curved edges.
	var start := 0
	while start < n and is_curve[start]:
		start += 1
	if start == n:
		return
	var idx := 0
	while idx < n:
		var e_i := (start + idx) % n
		if not is_curve[e_i]:
			idx += 1
			continue
		var arc: Array[int] = []
		while idx < n and is_curve[(start + idx) % n]:
			arc.append((start + idx) % n)
			idx += 1
		if arc.size() < 4:
			continue
		# Measure total arc length and check convexity (skip the tight inner courtyard curve).
		var total_len := 0.0
		var cum: Array[float] = [0.0]
		for ai in arc:
			total_len += ring[ai].distance_to(ring[(ai + 1) % n])
			cum.append(total_len)
		if total_len < 6.0:
			continue
		# Base rustication grooves wrapping smoothly along each curve segment.
		for ai in arc:
			var ea := ring[ai]
			var eb := ring[(ai + 1) % n]
			var out := _out(ring, ea, eb)
			var seg_w := _dp_front_edge(ea, eb, out)
			kit_bands(0.0, seg_w, g + 0.4, g + SDP_BASE_H - 0.25, 2.1, SDP_BASE)
		# Evenly spaced windows (~2.2-2.4 m arc pitch) centred on local curve chords.
		var n_wins := clampi(roundi(total_len / 2.3), 3, 5)
		var is_west := (_local(ring[arc[0]]).x < 0.0)
		for wk in n_wins:
			var target_s := total_len * (float(wk) + 0.5) / float(n_wins)
			var seg_k := 0
			while seg_k < arc.size() - 1 and cum[seg_k + 1] < target_s:
				seg_k += 1
			var ai := arc[seg_k]
			var ea := ring[ai]
			var eb := ring[(ai + 1) % n]
			var seg_l := ea.distance_to(eb)
			var t := clampf((target_s - cum[seg_k]) / maxf(seg_l, 0.01), 0.0, 1.0)
			var pos := ea.lerp(eb, t)
			var out := _out(ring, ea, eb)
			var tang := Vector2(-out.y, out.x)
			_o = pos
			_a = tang
			_b = out
			kit_face(0.03)
			var hw := 0.54 if is_west else 0.50
			for fl in sills.size():
				kit_window(0.0, float(sills[fl]), float(win_h[fl]), Win.SILL, SDP_FRAME, SDP_GLASS,
						hw, SDP_FRAME if is_west else Color(0, 0, 0, 0))
			kit_face(0.0)
		_o = block_o
		_a = axis
		_b = south


## Builds Stary Dom Poselski's Wiejska entrance: stone surround standing proud of the rusticated
## base, double-leaf kit_door (2.4 x 3.2 m), and warm night-glowing entrance glass (M_PAVILION).
func _sdp_entrance(cu: float, g: float) -> void:
	var keep := _mode
	_mode = M_STONE
	_kbox(cu - 1.95, cu + 1.95, 0.12, 1.30, g - 0.4, g + 0.16, SDP_BASE.darkened(0.12))
	_kbox(cu - 1.80, cu - 1.24, -0.02, 0.28, g - 0.3, g + 3.50, SDP_FRAME)
	_kbox(cu + 1.24, cu + 1.80, -0.02, 0.28, g - 0.3, g + 3.50, SDP_FRAME)
	_kbox(cu - 1.86, cu + 1.86, -0.02, 0.32, g + 3.50, g + 3.92, SDP_FRAME)
	kit_face(0.14)
	kit_door(cu, g + 0.16, 3.2, 1.20, SDP_FRAME, PAL_DARK_DOOR)
	# Warm glowing entrance door glass (M_PAVILION) 4 cm proud of the door leaf.
	_mode = M_PAVILION
	_wall(_w(cu - 1.04, 0.23), _w(cu - 0.08, 0.23), g + 0.42, g + 3.12, _b, SDP_ENTRANCE_GLOW)
	_wall(_w(cu + 0.08, 0.23), _w(cu + 1.04, 0.23), g + 0.42, g + 3.12, _b, SDP_ENTRANCE_GLOW)
	kit_face(0.0)
	_mode = keep


## Builds Stary Dom Poselski's low grey hipped roofs over its three wings and rounded west corner,
## kit_dormer rows on the street slopes, three masonry chimney stacks, and the round east drum
## rising to 24.5 m with its flat round cap and cap ledge.
func _sdp_roof_and_drum(ring: PackedVector2Array, drum_ring: PackedVector2Array, wiejska_i: int,
		g: float, block_o: Vector2, axis: Vector2, south: Vector2) -> void:
	_mode = M_STONE
	var eave := g + SDP_EAVE_H
	# Measure main north bar, projecting north/south bays, and east wing directly from `ring`
	# in the current local frame (never hardcoded offsets relative to _centre(ring)).
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in ring:
		var l := _local(p)
		lo = lo.min(l)
		hi = hi.max(l)
	var u_north0 := INF
	var u_north1 := -INF
	var v_north := lo.y + 2.4
	var v_court := lo.y + 17.9
	var nr_u0 := INF
	var nr_u1 := -INF
	var sb_u0 := INF
	var sb_u1 := -INF
	var sb_v1 := -INF
	var u_east0 := INF
	var u_east1 := -INF
	var v_east1 := -INF
	for p in ring:
		var l := _local(p)
		if l.y < lo.y + 1.0:
			nr_u0 = minf(nr_u0, l.x)
			nr_u1 = maxf(nr_u1, l.x)
		elif l.y < lo.y + 3.2:
			u_north0 = minf(u_north0, l.x)
			u_north1 = maxf(u_north1, l.x)
			v_north = minf(v_north, l.y)
		if l.x > nr_u0 - 2.0 and l.x < nr_u1 + 2.0 and l.y > lo.y + 19.0 and l.y < lo.y + 23.0:
			sb_u0 = minf(sb_u0, l.x)
			sb_u1 = maxf(sb_u1, l.x)
			sb_v1 = maxf(sb_v1, l.y)
		if l.x > hi.x - 18.0 and l.y > lo.y + 26.0:
			u_east0 = minf(u_east0, l.x)
			u_east1 = maxf(u_east1, l.x)
			v_east1 = maxf(v_east1, l.y)
	# Second pass for south courtyard projection once nr_u0/nr_u1 are known.
	if sb_u0 == INF:
		for p in ring:
			var l := _local(p)
			if l.x > nr_u0 - 1.0 and l.x < nr_u1 + 1.0 and l.y > v_north + 16.5 and l.y < v_north + 21.0:
				sb_u0 = minf(sb_u0, l.x)
				sb_u1 = maxf(sb_u1, l.x)
				sb_v1 = maxf(sb_v1, l.y)
	# 1. Main north bar hipped roof (rise 2.50 m -> ridge at g + 25.0 m).
	var n_cu := (u_north0 + u_north1) * 0.5
	var n_cv := (v_north + v_court) * 0.5
	var n_hu := (u_north1 - u_north0) * 0.5
	var n_hv := (v_court - v_north) * 0.5
	_hip(n_cu, n_cv, n_hu, n_hv, eave, SDP_ROOF_RISE, SDP_ROOF)
	# Tucked hips over the north central risalit and south courtyard bay, aligned to measured walls.
	if nr_u1 > nr_u0 + 6.0:
		_hip((nr_u0 + nr_u1) * 0.5, (lo.y + n_cv) * 0.5, (nr_u1 - nr_u0) * 0.5, (n_cv - lo.y) * 0.5,
				eave, SDP_ROOF_RISE - 0.08, SDP_ROOF)
	if sb_u1 > sb_u0 + 4.0 and sb_v1 > n_cv + 4.0:
		_hip((sb_u0 + sb_u1) * 0.5, (n_cv + sb_v1) * 0.5, (sb_u1 - sb_u0) * 0.5, (sb_v1 - n_cv) * 0.5,
				eave, SDP_ROOF_RISE - 0.14, SDP_ROOF)
	# 2. East wing hipped roof (tucked 5 cm under main bar ridge).
	var e_cu := (u_east0 + u_east1) * 0.5
	var e_cv := (n_cv + v_east1) * 0.5
	var e_hu := (u_east1 - u_east0) * 0.5
	var e_hv := (v_east1 - n_cv) * 0.5
	_hip(e_cu, e_cv, e_hu, e_hv, eave, SDP_ROOF_RISE - 0.05, SDP_ROOF)
	# 3. West rounded corner conical hip cap joining the north bar and Wiejska wing cleanly.
	var west_c := _w(u_north0 + 0.4, n_cv + 0.2)
	_frustum(_circle(west_c, 7.55, 16), eave, _circle(west_c, 0.50, 16), eave + SDP_ROOF_RISE - 0.16,
			SDP_ROOF, SDP_ROOF.darkened(0.08))
	# 4. East corner round drum (22.0 - 24.5 m) with crisp cream rim and darker flat round cap.
	var drum_c := _centre(drum_ring) if drum_ring.size() >= 3 else _w(e_cu, n_cv)
	var drum_r := 6.05
	if drum_ring.size() >= 3:
		drum_r = 0.0
		for dp in drum_ring:
			drum_r += dp.distance_to(drum_c)
		drum_r /= float(drum_ring.size())
	var drum_poly := _circle(drum_c, drum_r, 16)
	_prism(drum_poly, eave - 0.5, g + SDP_DRUM_TOP, SDP_STONE, SDP_ROOF.darkened(0.22), M_STONE, M_STONE)
	kit_ledge_ring(drum_poly, g + SDP_DRUM_TOP - 0.30, 0.36, SDP_FRAME, 0.20)
	# 5. Dormers (kit_dormer) on the North (Sejm) and East slopes, ~7.8 m apart.
	var d_in := 2.1
	var n_slope_y := eave + SDP_ROOF_RISE * (d_in / maxf(n_hv - 0.15, 1.0))
	if nr_u0 > u_north0 + 10.0:
		for du: float in _spread(u_north0 + 5.5, nr_u0 - 2.0, 3):
			kit_dormer(_w(du, v_north + d_in), -south, n_slope_y, SDP_ROOF.lightened(0.06), SDP_FRAME, SDP_GLASS)
	if u_north1 > nr_u1 + 12.0:
		for du: float in _spread(nr_u1 + 2.5, u_north1 - 7.5, 3):
			kit_dormer(_w(du, v_north + d_in), -south, n_slope_y, SDP_ROOF.lightened(0.06), SDP_FRAME, SDP_GLASS)
	var e_slope_y := eave + (SDP_ROOF_RISE - 0.05) * (d_in / maxf(e_hu - 0.15, 1.0))
	for dv: float in _spread(n_cv + 6.5, v_east1 - 5.5, 2):
		kit_dormer(_w(u_east1 - d_in, dv), axis, e_slope_y, SDP_ROOF.lightened(0.06), SDP_FRAME, SDP_GLASS)
	# 6. Two chimney stacks on the North bar and East wing ridges.
	for ch: Vector2 in [Vector2(lerpf(u_north0, nr_u0, 0.55), n_cv), Vector2(e_cu, lerpf(n_cv, v_east1, 0.6))]:
		_lbox(ch.x, ch.y, 0.65, 0.55, eave + SDP_ROOF_RISE - 0.7, eave + SDP_ROOF_RISE + 1.35, SDP_CHIMNEY)
		_lbox(ch.x, ch.y, 0.78, 0.68, eave + SDP_ROOF_RISE + 1.35, eave + SDP_ROOF_RISE + 1.52, SDP_CHIMNEY.darkened(0.18))
	# 7. West angled Wiejska wing hipped roof, three street-slope dormers, and third chimney stack.
	if wiejska_i >= 0:
		var wa := ring[wiejska_i]
		var wb := ring[(wiejska_i + 1) % ring.size()]
		var wlen := wa.distance_to(wb)
		var w_out := _out(ring, wa, wb)
		var w_dir := (wb - wa) / wlen
		_o = wa
		_a = w_dir
		_b = -w_out  # +v points into the west wing
		var w_depth := 14.5
		_hip(wlen * 0.5, w_depth * 0.5, wlen * 0.5, w_depth * 0.5, eave, SDP_ROOF_RISE - 0.10, SDP_ROOF)
		var w_slope_y := eave + (SDP_ROOF_RISE - 0.10) * (d_in / maxf(w_depth * 0.5 - 0.15, 1.0))
		for du: float in _spread(4.0, wlen - 5.0, 3):
			kit_dormer(_w(du, d_in), w_out, w_slope_y, SDP_ROOF.lightened(0.06), SDP_FRAME, SDP_GLASS)
		_lbox(wlen * 0.45, w_depth * 0.5, 0.65, 0.55, eave + SDP_ROOF_RISE - 0.8, eave + SDP_ROOF_RISE + 1.25, SDP_CHIMNEY)
		_lbox(wlen * 0.45, w_depth * 0.5, 0.78, 0.68, eave + SDP_ROOF_RISE + 1.25, eave + SDP_ROOF_RISE + 1.42, SDP_CHIMNEY.darkened(0.18))
		_o = block_o
		_a = axis
		_b = south

