extends Node3D
## Tamka from F's photos (F, 2026-11-08: "Tamka should feel alive"; 18 photos in the Mac folder
## warsaw-needed-photos/powisle, sources in its SOURCES.md; spec docs/landmarks/specs/tamka.md).
## What the photos show and the map had no layer for:
##  - **The houses** (static `house`, read by map_builder's Dobra/Tamka dress on both city paths):
##    Tamka is mostly post-war blocks in cream, sand and pale yellow with columns of balconies on dark
##    steel rails, not the pre-war pastels; Tamka 10/12's attic of small square openings, Tamka 16's
##    red-brick ground floor, Tamka 20's tower of balconies, Tamka 34's salmon corner, the ornate
##    white tenements of 45-49 by Kopernika.
##  - **The bollards**: black steel posts with a small cap every ~2 m along both kerbs of the whole
##    street, the first thing every photo shows; since pass 2 (2026-11-09, F's street photos) along
##    Powiśle's side streets too (BOLLARD_STREETS), in cells of BOLLARD_CELL m, a mesh each.
##  - **The footbridge** (kładka) from the Ostrogski castle's terrace over Tamka to the bank on the
##    south side: a concrete deck on a square pier, steel railings, the 3.9 m clearance sign.
##  - **KEBONAFIDE** (F's ask, 2026-11-08 22:46): a parody rap star who lives on Tamka walks his
##    dalmatian along the north pavement by day and says lines from his own made-up lore to a slow
##    car (`kebonafide` in data/dialogue.json). A parody: own name, own lines, no lyrics.
## Built at runtime on both city paths, as plac_pieciu_rogow.gd: the bollards and the footbridge one
## mesh in the actors' material (one draw call in view), the footbridge's deck and pier a collider;
## the walker one more small mesh moved each frame (+1 draw call near him). Add-ons: Beehave /
## Dialogue Manager not used (one walker on a fixed path and single lines, like wellness.gd).

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")

## The houses from the photos: [x, z (the address point, inside the house), plaster, style].
## style: "balc" rail colour, "base" ground-floor facing, "shops" false for none, "crenel" attic.
const HOUSES := [
	# Tamka 10/12 (C-Tamka-1-01): five storeys of cream plaster, the attic's row of small square
	# openings, shops behind white piers (a bistro, a beauty clinic).
	[261.2, -469.0, "#e4dbbd", {"crenel": "#4a4a44"}],
	# Tamka 16 (tamka-16-2021-2): cream with dark glass bay towers, the ground floor in red brick
	# with a gateway, a bank and a butcher's.
	[210.0, -436.6, "#dcd0b6", {"base": "#a5503a"}],
	# Tamka 20 (tamka-20-2021-2): a ten-storey cream-yellow tower, balconies up the corner.
	[165.1, -402.4, "#e3d5a6", {"balc": "#5d6c63"}],
	# Tamka 34 (tamka-34-2021-1): the rounded corner, cream with salmon panels, black rails.
	[37.6, -345.8, "#ddc8b4", {"balc": "#2b2b2d"}],
	# Tamka 34A, its brown-salmon neighbour with a balcony on every floor.
	[18.0, -337.8, "#b98466", {"balc": "#2b2b2d"}],
	# Tamka 45-49 by Kopernika (C-Tamka-1-07, 1-09): pre-war tenements in white ornate plaster,
	# iron balconies, shops on the ground floor.
	[-130.0, -265.4, "#ebe6dc", {"balc": "#26272a"}],
	[-151.6, -260.0, "#e8e2d6", {"balc": "#26272a"}],
	[-174.1, -257.2, "#ece7de", {"balc": "#26272a"}],
	[-188.8, -257.0, "#e4ddcf", {}],
]
## The rest of Tamka's houses: the photos' cream, sand, pale yellow, warm grey and salmon-cream.
const PASTELS := ["#e2d6b8", "#d8c69c", "#e6d79f", "#cfc7b9", "#dcc0a8", "#e9e4d8", "#d6cdb4", "#cbb79a"]
## A share of them take balconies on dark rails (most post-war blocks in the photos do).
const BALC_SHARE := 0.5
const RAILS := ["#2b2b2d", "#3a3d40", "#5d6c63"]
## Tamka's centre lines as mapped (centrum.json, 2026-11-08), each a flat [x, z, x, z...]: the houses
## are matched against these, not the sector's own roads (a sector may hold the houses but not the street).
const CENTRE := [
	[-194.6, -275.5, -213.7, -277.0, -225.5, -281.5],
	[303.6, -480.4, 350.2, -520.5, 371.9, -538.6, 411.3, -572.5],
	[140.9, -370.8, 161.2, -380.9, 166.3, -383.7, 179.0, -390.8],
	[411.3, -572.5, 434.0, -591.4],
	[179.0, -390.8, 191.0, -395.3, 201.1, -400.6, 203.3, -401.7, 205.5, -402.9, 207.7, -404.1, 209.5, -405.0, 209.9, -405.2, 212.1, -406.5, 214.2, -407.8, 216.4, -409.1, 218.5, -410.4, 220.7, -411.6, 222.1, -412.5],
	[239.5, -429.3, 281.2, -462.2, 292.3, -471.0],
	[127.1, -364.0, 129.6, -365.2, 140.9, -370.8],
	[-232.4, -270.5, -213.0, -271.1],
	[-194.6, -275.5, -141.9, -280.8, -130.4, -282.1, -123.0, -283.0, -110.9, -285.1, -94.1, -289.4, -65.1, -298.0, -57.1, -300.4, -49.3, -302.6, -43.9, -304.2, -36.0, -306.1, -28.8, -307.6, -26.9, -308.0],
	[443.5, -599.3, 445.7, -601.3, 449.4, -605.3, 451.7, -608.6, 453.2, -611.4],
	[292.3, -471.0, 303.6, -480.4],
	[208.5, -410.9, 199.4, -404.9, 196.1, -402.8, 189.6, -398.7, 183.6, -394.4, 179.0, -390.8],
	[222.1, -412.5, 231.2, -421.3, 235.1, -425.1, 239.5, -429.3],
	[239.5, -429.3, 233.5, -427.3, 228.8, -424.7, 227.0, -423.7, 223.4, -421.2, 221.3, -419.8, 219.3, -418.4, 217.6, -417.2, 217.2, -416.9, 215.2, -415.5, 213.1, -414.1, 211.1, -412.7, 209.0, -411.3, 208.5, -410.9],
	[-213.0, -271.1, -194.6, -275.5],
	[104.8, -353.0, 120.5, -360.7, 127.1, -364.0],
	[-22.9, -308.8, -9.9, -311.4, 37.7, -322.6, 42.8, -324.2, 53.1, -328.2, 63.6, -332.9, 104.8, -353.0],
	[-26.9, -308.0, -22.9, -308.8],
	[434.0, -591.4, 441.0, -597.3, 443.5, -599.3],
]
## Tamka's houses: within this of its centre line, from Kopernika to Wybrzeże.
const REACH := 26.0


## The photo look of the house `poly` if it is one of HOUSES; otherwise, for a house on Tamka
## (`on_tamka`), a seeded plaster from PASTELS and maybe balconies; {} otherwise.
## Returns {"plaster": Color, "style": Dictionary}.
static func house(poly: PackedVector2Array, on_tamka: bool, seed: int) -> Dictionary:
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	for h: Array in HOUSES:
		var at := Vector2(float(h[0]), float(h[1]))
		if box.grow(1.0).has_point(at) and Geometry2D.is_point_in_polygon(at, poly):
			return {"plaster": Color(h[2]), "style": h[3]}
	if not on_tamka:
		return {}
	var style := {}
	if fposmod(seed * 0.6180339887, 1.0) < BALC_SHARE:
		style["balc"] = RAILS[(seed / 3) % RAILS.size()]
	return {"plaster": Color(PASTELS[(seed / 7) % PASTELS.size()]), "style": style}

## The bollards: [kerb offset out of the carriageway's edge, spacing], and what keeps them away.
const BOLLARD_OUT := 0.45
const BOLLARD_STEP := 2.1
## F's street photos (2026-11-09, Mac powisle/C-*, D03): the same black posts line the kerbs of
## Powiśle's side streets too, so the posts go along these as well as Tamka; the box they are
## looked for in, and the cell size the posts are split by (one mesh a cell, so the camera draws
## only the cells near it).
const BOLLARD_STREETS := ["Tamka", "Lipowa", "Radna", "Cicha", "Topiel", "Leszczyńska", "Browarna", "Dobra",
		"Zajęcza", "Dynasy", "Oboźna", "Wiślana", "Solec", "Kruczkowskiego", "Smulikowskiego", "Gęsta", "Karowa"]
const BOLLARD_AREA := Rect2(-300.0, -1150.0, 1150.0, 1000.0)
const BOLLARD_CELL := 300.0
const BOLLARD_MIN_W := 6.0
const JUNCTION_CLEAR := 2.5
const ZEBRA_CLEAR := 3.0
const BOLLARD := Color("#1f2124")
const BOLLARD_CAP := Color("#2d3035")

## The footbridge from the castle's terrace (north) over Tamka to the bank (south): the mapped
## footway's two ends, the clearance under it over the road (the photo's sign: 3.9 m), the deck.
const BRIDGE_A := Vector2(-17.0, -285.0)
const BRIDGE_B := Vector2(-31.0, -328.0)
const BRIDGE_CLEAR := 4.3
const BRIDGE_DEPTH := 0.7
const BRIDGE_W := 3.0
const CONCRETE := Color("#b9b6ae")
const RAIL := Color("#d8dadb")

## KEBONAFIDE's walk: the north pavement from by the footbridge to Tamka 18 (7 m off the centre
## line, clear of every house), his hours on the game clock, his pace, how near a slow car must be.
const WALK := [Vector2(36.3, -329.8), Vector2(40.8, -330.6), Vector2(50.2, -334.4), Vector2(61.0, -339.3),
		Vector2(101.9, -359.3), Vector2(116.9, -367.3), Vector2(124.0, -370.3), Vector2(137.9, -377.3),
		Vector2(157.8, -387.2), Vector2(162.6, -390.1), Vector2(175.7, -397.2)]
const HOURS := Vector2(9.0, 22.5)
const PACE := 1.15
const PAUSE_EVERY := 38.0  ## m, the dog stops to sniff
const PAUSE := 4.0
const CAR_NEAR := 16.0
const CAR_KMH := 20.0
const LINE_GAP := 22.0
const AMBIENT_GAP := Vector2(35.0, 60.0)
const AMBIENT_VIEW := 70.0
const ACCENT := Color("#ff7ab8")

var map: Node3D
var dialogue: Node
## {"hour": float, "weekday": int} (TimeOfDay.local_clock).
var clock: Callable
var focus: Callable
## [position, km/h, flying].
var vehicle: Callable
var log_on := false

var bollards := 0
var lines_said := 0
var _walker: MeshInstance3D
var _s := 0.0
var _dir := 1.0
var _wait := 0.0
var _cum := PackedFloat32Array()
var _line_t := -100.0
var _ambient_t := 0.0
var _t := 0.0


## Builds the bollards and the footbridge (one mesh, the deck's collider) and the walker.
func build() -> void:
	var cells := {}
	_bollards(cells)
	for key: Vector2i in cells:
		var cell := MeshInstance3D.new()
		cell.name = "Bollards_%d_%d" % [key.x, key.y]
		cell.mesh = (cells[key] as SurfaceTool).commit()
		cell.material_override = Models.material()
		cell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(cell)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	body.name = "TamkaSolids"
	_footbridge(st, body)
	var mi := MeshInstance3D.new()
	mi.name = "TamkaProps"
	mi.mesh = st.commit()
	mi.material_override = Models.material()
	add_child(mi)
	add_child(body)
	_cum.resize(WALK.size())
	_cum[0] = 0.0
	for i in range(1, WALK.size()):
		_cum[i] = _cum[i - 1] + (WALK[i] as Vector2).distance_to(WALK[i - 1])
	_walker = MeshInstance3D.new()
	_walker.name = "Kebonafide"
	_walker.mesh = walker_mesh()
	_walker.material_override = Models.material()
	_walker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_walker)
	_s = 0.3 * _cum[_cum.size() - 1]
	_ambient_t = AMBIENT_GAP.x
	if log_on:
		print("tamka: %d bollards, walk %.0f m" % [bollards, _cum[_cum.size() - 1]])


## Bollards along both kerbs of every Tamka carriageway BOLLARD_MIN_W wide or more, BOLLARD_STEP
## apart, not across another road's mouth, a zebra or the other carriageway.
func _bollards(cells: Dictionary) -> void:
	var data: Dictionary = map.data
	var own := []
	var others := []
	for r: Dictionary in data.get("roads", []):
		var p: Array = r["p"]
		var near := false
		for i in range(0, p.size(), 2):
			if BOLLARD_AREA.has_point(Vector2(float(p[i]), float(p[i + 1]))):
				near = true
				break
		if not near or bool(r.get("bridge", false)):
			continue
		var w := float(r.get("w", 6.0))
		for i in range(0, p.size() - 3, 2):
			var sg := [Vector2(float(p[i]), float(p[i + 1])), Vector2(float(p[i + 2]), float(p[i + 3])), w]
			if BOLLARD_STREETS.has(_short(str(r.get("name", "")))):
				own.append(sg)
			else:
				others.append(sg)
	var zebras := []
	for pa: Dictionary in data.get("paths", []):
		if str(pa.get("k", "")) != "zebra":
			continue
		var p: Array = pa["p"]
		var a := Vector2(float(p[0]), float(p[1]))
		if BOLLARD_AREA.has_point(a):
			for i in range(0, p.size() - 3, 2):
				zebras.append([Vector2(float(p[i]), float(p[i + 1])), Vector2(float(p[i + 2]), float(p[i + 3]))])
	for sg: Array in own:
		var w: float = sg[2]
		if w < BOLLARD_MIN_W:
			continue
		var a: Vector2 = sg[0]
		var b: Vector2 = sg[1]
		var length := a.distance_to(b)
		if length < 1.0:
			continue
		var dir := (b - a) / length
		var side := Vector2(dir.y, -dir.x)
		var n := floori(length / BOLLARD_STEP)
		for k in n:
			for sgn: float in [-1.0, 1.0]:
				var at: Vector2 = a + dir * (BOLLARD_STEP * (k + 0.5)) + side * sgn * (w * 0.5 + BOLLARD_OUT)
				if _clear(at, own, others, zebras):
					var key := Vector2i(floori(at.x / BOLLARD_CELL), floori(at.y / BOLLARD_CELL))
					if not cells.has(key):
						var cst := SurfaceTool.new()
						cst.begin(Mesh.PRIMITIVE_TRIANGLES)
						cells[key] = cst
					_bollard(cells[key], at)


## A street's name without the first names OpenStreetMap gives some (Juliana Smulikowskiego).
static func _short(name: String) -> String:
	var parts := name.split(" ")
	return parts[parts.size() - 1] if parts.size() > 1 and not name.begins_with("Wybrzeże") else name


## Whether a bollard at `at` stands clear of every carriageway, road mouth and zebra.
func _clear(at: Vector2, own: Array, others: Array, zebras: Array) -> bool:
	for sg: Array in own:
		if Geometry2D.get_closest_point_to_segment(at, sg[0], sg[1]).distance_to(at) < float(sg[2]) * 0.5 + BOLLARD_OUT - 0.1:
			return false
	for sg: Array in others:
		if Geometry2D.get_closest_point_to_segment(at, sg[0], sg[1]).distance_to(at) < float(sg[2]) * 0.5 + JUNCTION_CLEAR:
			return false
	for sg: Array in zebras:
		if Geometry2D.get_closest_point_to_segment(at, sg[0], sg[1]).distance_to(at) < ZEBRA_CLEAR:
			return false
	if at.distance_to(BRIDGE_A.lerp(BRIDGE_B, 0.5)) < 1.5:
		return false
	return true


## One bollard: a black post 0.95 m tall and a slightly wider cap (Warsaw's standard post).
func _bollard(st: SurfaceTool, at: Vector2) -> void:
	var g: float = map.ground_height(at.x, at.y)
	Props.box(st, Vector3(at.x, g + 0.45, at.y), Vector3(0.13, 0.9, 0.13), BOLLARD)
	Props.box(st, Vector3(at.x, g + 0.93, at.y), Vector3(0.16, 0.07, 0.16), BOLLARD_CAP)
	bollards += 1


## The footbridge: a flat deck from BRIDGE_A to BRIDGE_B BRIDGE_CLEAR over the road under its
## middle, cut where the ground climbs to it; square piers where the ground is well below it at the
## two pavements; railings both sides; a flight of steps down at an end the ground stays under.
func _footbridge(st: SurfaceTool, body: StaticBody3D) -> void:
	var mid := BRIDGE_A.lerp(BRIDGE_B, 0.5)
	var road: float = map.ground_height(mid.x, mid.y)
	var bottom := road + BRIDGE_CLEAR
	var top := bottom + BRIDGE_DEPTH
	var along := (BRIDGE_B - BRIDGE_A).normalized()
	var across := Vector2(along.y, -along.x)
	var yaw := atan2(-along.x, -along.y)
	var length := BRIDGE_A.distance_to(BRIDGE_B)
	# where the deck meets the ground at each end (the castle's terrace, the bank)
	var s0 := 0.0
	var s1 := length
	var s := length * 0.5
	while s > 0.0:
		var q := BRIDGE_A + along * s
		if map.ground_height(q.x, q.y) > top - 0.15:
			s0 = s
			break
		s -= 0.5
	s = length * 0.5
	while s < length:
		var q := BRIDGE_A + along * s
		if map.ground_height(q.x, q.y) > top - 0.15:
			s1 = s
			break
		s += 0.5
	var basis := Basis(Vector3.UP, yaw)
	var c := BRIDGE_A + along * ((s0 + s1) * 0.5)
	var span := s1 - s0
	var centre := Vector3(c.x, bottom + BRIDGE_DEPTH * 0.5, c.y)
	Props.obox(st, centre, basis, Vector3(BRIDGE_W, BRIDGE_DEPTH, span + 0.6), CONCRETE)
	_solid(body, Transform3D(basis, centre - Vector3.UP * BRIDGE_DEPTH * 0.5), Vector3(BRIDGE_W, BRIDGE_DEPTH, span + 0.6))
	# railings: posts every 1.6 m, a top rail and a mid rail on each edge
	for sgn: float in [-1.0, 1.0]:
		var e := across * sgn * (BRIDGE_W * 0.5 - 0.06)
		var k := 0.0
		while k <= span:
			var q := BRIDGE_A + along * (s0 + k) + e
			Props.box(st, Vector3(q.x, top + 0.55, q.y), Vector3(0.06, 1.1, 0.06), RAIL)
			k += 1.6
		var rc := c + e
		Props.obox(st, Vector3(rc.x, top + 1.08, rc.y), basis, Vector3(0.07, 0.07, span), RAIL)
		Props.obox(st, Vector3(rc.x, top + 0.55, rc.y), basis, Vector3(0.04, 0.04, span), RAIL)
	# piers on the pavements (7.5 m either side of the crossing), where the ground is low
	var cross := _crossing()
	for off: float in [-7.5, 7.5]:
		var q := cross + along * off
		var g: float = map.ground_height(q.x, q.y)
		if bottom - g > 1.5:
			var pc := Vector3(q.x, (g + bottom) * 0.5, q.y)
			Props.obox(st, pc, basis, Vector3(0.9, bottom - g, 0.9), CONCRETE.darkened(0.08))
			_solid(body, Transform3D(basis, Vector3(q.x, g, q.y)), Vector3(0.9, bottom - g, 0.9))
	# steps down at an end the ground stays under the deck
	for end: int in [0, 1]:
		var at_s := s0 if end == 0 else s1
		var q := BRIDGE_A + along * at_s
		var drop: float = top - float(map.ground_height(q.x, q.y))
		if drop < 0.6:
			continue
		var out := -along if end == 0 else along
		var steps := ceili(drop / 0.17)
		for i in steps:
			var p := q + out * (0.3 * (i + 0.5))
			var y := top - 0.17 * (i + 1)
			var gy: float = map.ground_height(p.x, p.y)
			if y < gy - 0.1:
				break
			Props.obox(st, Vector3(p.x, (y + maxf(gy, y - 1.2)) * 0.5, p.y), basis,
					Vector3(BRIDGE_W - 0.4, y - maxf(gy, y - 1.2) + 0.02, 0.32), CONCRETE.lightened(0.05))


## Where the footbridge's line crosses Tamka's centre line (the middle of the line if it doesn't).
func _crossing() -> Vector2:
	for r: Dictionary in map.data.get("roads", []):
		if str(r.get("name", "")) != "Tamka":
			continue
		var p: Array = r["p"]
		for i in range(0, p.size() - 3, 2):
			var hit: Variant = Geometry2D.segment_intersects_segment(BRIDGE_A, BRIDGE_B,
					Vector2(float(p[i]), float(p[i + 1])), Vector2(float(p[i + 2]), float(p[i + 3])))
			if hit != null:
				return hit
	return BRIDGE_A.lerp(BRIDGE_B, 0.5)


func _solid(body: StaticBody3D, xf: Transform3D, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.transform = Transform3D(xf.basis, xf.origin + Vector3.UP * size.y * 0.5)
	body.add_child(shape)


## KEBONAFIDE and his dalmatian, facing -z, the dog 1.5 m ahead on a lead. A parody figure: platinum
## hair, round dark glasses, a few face tattoo marks, an oversized black hoodie with a pink K, a gold
## chain, wide trousers, white trainers. ~400 triangles.
static func walker_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var skin := Color("#e8c09a")
	var hoodie := Color("#1b1b1f")
	var trousers := Color("#3a3d44")
	var shoe := Color("#f3f2ee")
	for side: float in [-1.0, 1.0]:
		Props.box(st, Vector3(0.12 * side, 0.45, 0), Vector3(0.21, 0.82, 0.26), trousers)
		Props.box(st, Vector3(0.12 * side, 0.06, -0.04), Vector3(0.18, 0.12, 0.34), shoe)
	Props.box(st, Vector3(0, 1.17, 0), Vector3(0.56, 0.7, 0.34), hoodie)
	Props.box(st, Vector3(0, 1.2, -0.175), Vector3(0.18, 0.22, 0.02), Color("#ff7ab8"))  # the K
	Props.box(st, Vector3(0, 1.43, 0.13), Vector3(0.38, 0.18, 0.12), hoodie)  # the hood down
	for side: float in [-1.0, 1.0]:
		Props.box(st, Vector3(0.34 * side, 1.12, 0), Vector3(0.15, 0.62, 0.2), hoodie)
		Props.box(st, Vector3(0.34 * side, 0.78, 0), Vector3(0.1, 0.1, 0.1), skin)
	Props.box(st, Vector3(0, 1.36, -0.16), Vector3(0.22, 0.03, 0.03), Color("#e1b23c"))  # chain
	Props.box(st, Vector3(0, 1.62, 0), Vector3(0.26, 0.28, 0.26), skin)
	Props.box(st, Vector3(0, 1.79, 0.01), Vector3(0.29, 0.09, 0.3), Color("#f2e6b8"))  # platinum
	Props.box(st, Vector3(0, 1.66, -0.135), Vector3(0.24, 0.06, 0.02), Color("#141414"))  # glasses
	for m: Vector3 in [Vector3(-0.07, 1.57, -0.132), Vector3(0.08, 1.55, -0.132), Vector3(0.03, 1.6, -0.132)]:
		Props.box(st, m, Vector3(0.03, 0.03, 0.01), Color("#3b3f52"))  # tattoo marks
	# the lead, from his right hand to the collar
	var hand := Vector3(0.34, 0.8, -0.05)
	var collar := Vector3(0.05, 0.62, -1.15)
	var mid := (hand + collar) * 0.5
	var lead_basis := Basis.looking_at((collar - hand).normalized(), Vector3.UP)
	Props.obox(st, mid, lead_basis, Vector3(0.02, 0.02, hand.distance_to(collar)), Color("#c8282a"))
	# the dalmatian, 1.5 m ahead
	var o := Vector3(0.05, 0.0, -1.5)
	var white := Color("#f4f2ec")
	var black := Color("#151515")
	Props.box(st, o + Vector3(0, 0.5, 0), Vector3(0.26, 0.26, 0.72), white)
	for leg: Vector3 in [Vector3(-0.09, 0.2, -0.26), Vector3(0.09, 0.2, -0.26), Vector3(-0.09, 0.2, 0.26), Vector3(0.09, 0.2, 0.26)]:
		Props.box(st, o + leg, Vector3(0.07, 0.4, 0.07), white)
	Props.box(st, o + Vector3(0, 0.66, -0.42), Vector3(0.18, 0.18, 0.22), white)
	Props.box(st, o + Vector3(0, 0.62, -0.56), Vector3(0.1, 0.09, 0.1), white)
	Props.box(st, o + Vector3(0, 0.63, -0.615), Vector3(0.05, 0.04, 0.02), black)
	for side: float in [-1.0, 1.0]:
		Props.box(st, o + Vector3(0.1 * side, 0.68, -0.38), Vector3(0.03, 0.12, 0.08), black)
	Props.box(st, o + Vector3(0, 0.58, 0.44), Vector3(0.04, 0.04, 0.24), white)
	Props.box(st, o + Vector3(0, 0.6, -0.31), Vector3(0.2, 0.05, 0.05), Color("#c8282a"))  # collar
	for spot: Vector3 in [Vector3(0.131, 0.55, -0.15), Vector3(-0.131, 0.48, 0.1), Vector3(0.131, 0.45, 0.22),
			Vector3(-0.131, 0.57, -0.22), Vector3(0.05, 0.631, 0.05), Vector3(-0.06, 0.631, -0.2),
			Vector3(0.0, 0.631, 0.25), Vector3(0.131, 0.5, 0.02), Vector3(-0.131, 0.42, -0.05)]:
		var sz := Vector3(0.01, 0.07, 0.07) if absf(spot.x) > 0.12 else Vector3(0.07, 0.01, 0.07)
		Props.box(st, o + spot, sz, black)
	return st.commit()


## The walk: back and forth along WALK in his hours, a sniff stop every PAUSE_EVERY m; a line to a
## slow car close by (LINE_GAP apart) and now and then one to the street when the view is near.
func _process(dt: float) -> void:
	if _walker == null:
		return
	_t += dt
	var now: Dictionary = clock.call() if clock.is_valid() else {"hour": 12.0}
	var hour := float(now.get("hour", 12.0))
	var on := hour >= HOURS.x and hour < HOURS.y
	var eye: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var near := Vector2(eye.x, eye.z).distance_to(WALK[WALK.size() / 2]) < 320.0
	_walker.visible = on and near
	if not _walker.visible:
		return
	var total := _cum[_cum.size() - 1]
	if _wait > 0.0:
		_wait -= dt
	else:
		var before := _s
		_s += _dir * PACE * dt
		if floori(before / PAUSE_EVERY) != floori(_s / PAUSE_EVERY):
			_wait = PAUSE
		if _s >= total:
			_s = total
			_dir = -1.0
			_wait = PAUSE
		elif _s <= 0.0:
			_s = 0.0
			_dir = 1.0
			_wait = PAUSE
	var at := point_at(_s)
	var ahead := point_at(clampf(_s + _dir * 1.5, 0.0, total))
	var fwd := ahead - at
	var yaw := atan2(-fwd.x, -fwd.y) if fwd.length() > 0.05 else _walker.rotation.y
	var bob := 0.0 if _wait > 0.0 else absf(sin(_t * 6.0)) * 0.035
	_walker.position = Vector3(at.x, float(map.ground_height(at.x, at.y)) + bob, at.y)
	_walker.rotation = Vector3(0.0, yaw, 0.0)
	if log_on and int(_t * 2.0) != int((_t - dt) * 2.0):
		print("tamka: kebonafide at %.1f, %.1f (s %.0f)" % [at.x, at.y, _s])
	_talk(at, eye)


## A point `s` metres along WALK.
func point_at(s: float) -> Vector2:
	for i in range(1, WALK.size()):
		if s <= _cum[i] or i == WALK.size() - 1:
			var f := clampf((s - _cum[i - 1]) / maxf(_cum[i] - _cum[i - 1], 0.01), 0.0, 1.0)
			return (WALK[i - 1] as Vector2).lerp(WALK[i], f)
	return WALK[0]


func _talk(at: Vector2, eye: Vector3) -> void:
	if dialogue == null:
		return
	var anchor := func() -> Vector3: return _walker.global_position + Vector3(0, 2.2, 0)
	var veh: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF, 0.0, false]
	var vp: Vector3 = veh[0]
	if says_to_car(at, Vector2(vp.x, vp.z), float(veh[1]), bool(veh[2])) and _t - _line_t > LINE_GAP:
		if not dialogue.say_reaction(anchor, "Kebonafide", "kebonafide", "car", 4.5, ACCENT, 2.2, false).is_empty():
			_line_t = _t
			lines_said += 1
			if log_on:
				print("tamka: kebonafide car line")
		return
	_ambient_t -= get_process_delta_time()
	if _ambient_t <= 0.0 and Vector2(eye.x, eye.z).distance_to(at) < AMBIENT_VIEW:
		_ambient_t = randf_range(AMBIENT_GAP.x, AMBIENT_GAP.y)
		if not dialogue.say_ambient(anchor, "Kebonafide", "kebonafide", "", 4.5, ACCENT, 2.2).is_empty():
			lines_said += 1


## Whether he speaks to the vehicle: a car (not the helicopter) within CAR_NEAR, slower than CAR_KMH.
static func says_to_car(at: Vector2, car: Vector2, kmh: float, flying: bool) -> bool:
	return not flying and at.distance_to(car) < CAR_NEAR and kmh < CAR_KMH


## The distance from a point to Tamka's nearest centre line (CENTRE), INF beyond 80 m.
static func distance(at: Vector2) -> float:
	var best := INF
	for l: Array in CENTRE:
		for i in range(0, l.size() - 3, 2):
			var a := Vector2(float(l[i]), float(l[i + 1]))
			if absf(at.x - a.x) > 80.0 or absf(at.y - a.y) > 80.0:
				continue
			best = minf(best, Geometry2D.get_closest_point_to_segment(at, a, Vector2(float(l[i + 2]), float(l[i + 3]))).distance_to(at))
	return best
