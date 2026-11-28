extends "res://scripts/landmarks/churches.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, the streets of Śródmieście:
## MDM and Plac Zbawiciela's colonnades, Nowy Świat and Bracka, Foksal, Świętokrzyska,
## Marszałkowska, Nowogrodzka, Próżna and Plac Grzybowski, the modernism collection, the hotels and
## the rooftop bars. Moved as it was from the one big file. landmarks.gd is the class the game
## makes; every file of game/scripts/landmarks/ is one link of its base chain (facade_kit.gd,
## common.gd, then the areas in the order of landmarks.gd's `extends` chain), so code here may use
## this file, common.gd and the facade kit, never another area: a helper two areas need goes to
## common.gd.


# --- MDM (the landmarks loop, street furniture) --------------------------------------------------

## Marszałkowska Dzielnica Mieszkaniowa: the tall blocks round Plac Konstytucji (MDM_SQUARE,
## within MDM_SQUARE_R) and along Marszałkowska to Plac Zbawiciela (within MDM_REACH of the
## axis), kept as LoD2 draws them but in their pale sandstone with tall windows between piers
## and grey sheet roofs; one card for the lot. The square's candelabras are map_builder's.
const MDM_SQUARE := Vector2(-533.8, 1282.4)
const MDM_SOUTH := Vector2(-413.9, 1565.2)
const MDM_SQUARE_R := 95.0
const MDM_REACH := 60.0
const MDM_STONE := Color("#e6dfcc")
const MDM_ROOF := Color("#7f7b74")
func _find_mdm() -> void:
	var zone: Array = []
	for bld in data["buildings"]:
		if float(bld["h"]) < 15.0 or str(bld.get("name", "")) != "":
			continue
		var q := _pts(bld["p"])
		if q.size() < 4:
			continue
		var c := _box_of([q]).get_center()
		var axis := Geometry2D.get_closest_point_to_segment(c, MDM_SQUARE, MDM_SOUTH)
		if c.distance_to(MDM_SQUARE) < MDM_SQUARE_R or c.distance_to(axis) < MDM_REACH:
			zone.append(q)
	if zone.is_empty():
		return
	_add_site("mdm", zone)
	if not sites.is_empty() and sites[-1]["key"] == "mdm":
		sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": MDM_STONE, "roof": MDM_ROOF}


## MDM as it stands (spec docs/landmarks/specs/mdm.md, LANDMARKS 2.8; F's Street View shots,
## 2026-11-05): cream plaster above, a sand-coloured stone-clad base three storeys high with big
## shopfronts between stone piers, a cornice on every street face; deep arcades only on the
## square's own ring; at the four corners a stepped attic pavilion with finials; on the roofs
## the red MDM neon, the parody Xiaomi (XIAOMY) and BYD (BYDŁO), and the hotel's own sign.
## The blocks stay LoD2's in their skin. The frame is the street's grid: u along Marszałkowska
## (SSE), v across (WSW).
const MDM_A := Vector2(0.349, 0.937)
const MDM_TRIM := Color("#ece4d0")
const MDM_PIER := Color("#d3c39a")
const MDM_SAND := Color("#cdb98d")
const MDM_DARK := Color("#34383b")
const MDM_RED := Color(1.0, 0.16, 0.12)
const MDM_ORANGE := Color(1.0, 0.45, 0.05)
const MDM_SILVER := Color(0.88, 0.92, 0.97)
const MDM_ARCADE_DEPTH := 2.9
const MDM_BAY := 5.4
const MDM_BAND := 11.0
const MDM_RING := 80.0
## Corner pavilions: [centre, block height, half size along the street, half size across].
const MDM_CROWNS := [
	[Vector2(-458.6, 1286.5), 30.7, 5.8, 7.5],   # east block's south end
	[Vector2(-588.8, 1334.4), 30.7, 5.8, 8.5],   # west block's south end
	[Vector2(-499.5, 1388.5), 27.4, 7.5, 5.8],   # the south gate, west
	[Vector2(-462.0, 1374.3), 27.4, 7.5, 5.8],   # the south gate, east
]
## Roof and hotel signs, all on the Hotel MDM (Plac Konstytucji 1, the south-west block, 27.4 m; the
## real MDM and BYD neons share its roof, read from the square): [word, spot, outward direction, roof height above ground, width m, colour].
## The direction is the sign's front, as Neon.place wants it: the quad is cull_disabled, so a sign
## whose direction points away from the viewer reads mirrored (the HOTEL MDM bug, 2026-11-26).
## From the square a sign on the hotel's roof looks along -MDM_A; XIAOMY is on the east block.
const MDM_SIGNS := [
	["MDM", Vector2(-512.0, 1388.5), Vector2(-0.349, -0.937), 32.2, 8.0, MDM_RED],
	["BYDŁO", Vector2(-527.0, 1394.5), Vector2(-0.349, -0.937), 31.0, 12.0, MDM_SILVER],
	["XIAOMY", Vector2(-447.0, 1366.0), Vector2(-0.349, -0.937), 27.8, 11.0, MDM_ORANGE],
	["HOTEL MDM", Vector2(-509.8, 1382.2), Vector2(-0.349, -0.937), 5.9, 5.2, MDM_RED],
]


func _build_mdm(site: Dictionary) -> void:
	_a = MDM_A
	_b = Vector2(-MDM_A.y, MDM_A.x)
	_mode = M_STONE
	var zone: Array = site["zone"]
	for poly: PackedVector2Array in zone:
		_mdm_facades(_simplify(poly, 0.8), zone)
	for t: Array in MDM_CROWNS:
		_mdm_crown(t[0], float(t[1]), float(t[2]), float(t[3]))
	for s: Array in MDM_SIGNS:
		var at: Vector2 = s[1]
		var d: Vector2 = s[2]
		var k: float = float(s[4]) / Neon.length_of(s[0])
		signs.append([s[0], Vector3(at.x, map.terrain_height(at.x, at.y) + float(s[3]), at.y), Vector3(d.x, 0.0, d.y), k, s[5]])


## The street faces of one block: those that look at the square or the axis get the stone base;
## the ones on the square's ring get a deep arcade as well.
func _mdm_facades(poly: PackedVector2Array, zone: Array) -> void:
	var n := poly.size()
	for i in n:
		var p0 := poly[i]
		var p1 := poly[(i + 1) % n]
		var length := p0.distance_to(p1)
		if length < 14.0:
			continue
		var out := _out(poly, p0, p1)
		var mid := (p0 + p1) * 0.5
		var target := Geometry2D.get_closest_point_to_segment(mid, MDM_SQUARE, MDM_SOUTH)
		if mid.distance_to(target) > 100.0 or out.dot((target - mid).normalized()) < 0.55:
			continue
		var blocked := false
		for z: PackedVector2Array in zone:
			if Geometry2D.is_point_in_polygon(mid + out * 3.0, z):
				blocked = true
				break
		if blocked:
			continue
		_mdm_facade(p0, p1, out, mid.distance_to(MDM_SQUARE) < MDM_RING)


## One facade p0 → p1 reaching `out`. Frame: u along it, v out. The base stands 0.6 m proud of
## the wall (LoD2's wall may stand a little off the OpenStreetMap outline).
func _mdm_facade(p0: Vector2, p1: Vector2, out: Vector2, arcade: bool) -> void:
	var length := p0.distance_to(p1)
	_o = p0
	_a = (p1 - p0) / length
	_b = out
	_g = minf(map.terrain_height(p0.x, p0.y), map.terrain_height(p1.x, p1.y))
	var g := _g
	var bays := maxi(int(round(length / MDM_BAY)), 2)
	var step := length / bays
	var base := 0.6
	_mode = M_MONUMENT
	_wall(_w(0.2, base), _w(length - 0.2, base), g - 0.3, g + MDM_BAND, _b, MDM_SAND)
	_mode = M_STONE
	# the ledge over the base
	_lbox(length * 0.5, base + 0.5, length * 0.5 - 0.1, 0.5, g + MDM_BAND, g + MDM_BAND + 0.7, MDM_TRIM, M_STONE, MDM_TRIM)
	# stone piers between the shopfronts, a cornice over the ground floor
	for k in range(0, bays + 1):
		var u := clampf(k * step, 0.7, length - 0.7)
		_lbox(u, base + 0.2, 0.5, 0.2, g - 0.3, g + 5.8, MDM_PIER, M_STONE, MDM_TRIM)
	_lbox(length * 0.5, base + 0.3, length * 0.5 - 0.1, 0.3, g + 5.6, g + 6.2, MDM_TRIM, M_STONE, MDM_TRIM)
	# shopfronts: dark glass in each bay
	_mode = M_GLASS
	for k in bays:
		_wall(_w(k * step + 0.9, base + 0.45), _w((k + 1) * step - 0.9, base + 0.45), g + 0.3, g + 5.2, _b, MDM_DARK)
	_mode = M_STONE
	if arcade:
		# a deep arcade over the pavement: square piers under a flat entablature
		for k in range(1, bays):
			_lbox(k * step, MDM_ARCADE_DEPTH - 0.4, 0.7, 0.7, g - 0.5, g + 5.8, MDM_PIER, M_STONE, MDM_TRIM)
		_lbox(length * 0.5, MDM_ARCADE_DEPTH * 0.5 + 0.3, length * 0.5 - 0.3, MDM_ARCADE_DEPTH * 0.5 - 0.1, g + 5.8, g + 6.4, MDM_TRIM, M_STONE, MDM_TRIM)
		_lbox(length * 0.5, MDM_ARCADE_DEPTH + 0.1, length * 0.5 - 0.3, 0.2, g + 6.4, g + 6.9, MDM_TRIM, M_STONE, MDM_TRIM)
	_collide(PackedVector2Array([_w(0.4, 0.0), _w(length - 0.4, 0.0), _w(length - 0.4, MDM_ARCADE_DEPTH if arcade else base + 1.0), _w(0.4, MDM_ARCADE_DEPTH if arcade else base + 1.0)]))


## A corner pavilion on a block's end (base sunk 1.5 m into the roof): a cornice, a recessed
## windowed attic one storey high, a cornice with a finial on every corner and along the parapet.
func _mdm_crown(c: Vector2, block_h: float, ha: float, hb: float) -> void:
	_o = c
	_a = MDM_A
	_b = Vector2(-MDM_A.y, MDM_A.x)
	_g = map.terrain_height(c.x, c.y)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var y0 := g + block_h - 1.5
	_mode = M_STONE
	# a hidden core inside the block ties the pavilion to the ground (the mesh check's floating-parts rule)
	_lbox(0.0, 0.0, ha - 0.8, hb - 0.8, g - 0.5, y0 + 2.0, MDM_SAND, M_STONE, MDM_SAND)
	_lbox(0.0, 0.0, ha + 0.4, hb + 0.4, y0 + 1.5, y0 + 2.5, MDM_TRIM, M_STONE, MDM_TRIM)
	_prism(_rect(0.0, 0.0, ha - 0.9, hb - 0.9), y0 + 2.5, y0 + 7.0, MDM_STONE, none, M_MONUMENT)
	_lbox(0.0, 0.0, ha - 0.3, hb - 0.3, y0 + 7.0, y0 + 8.0, MDM_TRIM, M_STONE, MDM_TRIM)
	_lbox(0.0, 0.0, ha - 1.3, hb - 1.3, y0 + 8.0, y0 + 8.4, MDM_ROOF, M_STONE, MDM_ROOF)
	for su: float in [-1.0, 1.0]:
		for sv: float in [-1.0, 1.0]:
			_pinnacle(su * (ha - 0.5), sv * (hb - 0.5), 0.7, y0 + 8.0, 2.4, MDM_TRIM)
	for sv: float in [-1.0, 1.0]:
		for su: float in [-0.5, 0.5]:
			_pinnacle(su * (ha - 0.5), sv * (hb - 0.5), 0.5, y0 + 8.0, 1.6, MDM_TRIM)
	_mode = M_STONE


# --- The de Gaulle statue by Rondo de Gaulle'a (F's photo, 2026-11-01) ---------------------------

## Jean Cardot's marching general (a copy of the Paris one, unveiled 15 May 2005) in front of the
## Party House, north-west of its north wing, where the lawn's curved cut-out is mapped. OSM has
## no 3D parts for it, so it is built by hand like Sigismund's Column (spec
## docs/design/gaulle-and-food-hype.md G1, from F's photo): curved granite steps with cobbled
## rings between them, a low granite cone, the tall dark granite plinth (its long side along the
## walk) and the general in dark bronze, 3.3 m, walking west in his long coat and kepi.
const GAULLE := Vector2(-171.0, 273.0)
const GAULLE_WALK := Vector2(-1.0, 0.0)
const GAULLE_STEP := Color("#b3b5b6")
const GAULLE_COBBLE := Color("#76777a")
const GAULLE_CONE := Color("#77777a")
const GAULLE_GRANITE := Color("#4c4d51")
const GAULLE_BRONZE := Color("#4a463d")
const GAULLE_PLINTH_H := 4.2
func _find_gaulle() -> void:
	_add_site("gaulle", [_circle(GAULLE, 4.4, 16)])


func _build_gaulle(_site: Dictionary) -> void:
	var c := GAULLE
	_g = _ground_under(_circle(c, 6.0, 8))
	var g := _g
	# The rings, outside in: three steps up, a cobbled band, one more step, a cobbled band.
	var rings := [[8.0, 0.15, GAULLE_STEP], [7.6, 0.3, GAULLE_STEP], [7.2, 0.45, GAULLE_STEP], [6.8, 0.47, GAULLE_COBBLE],
			[5.9, 0.62, GAULLE_STEP], [5.5, 0.64, GAULLE_COBBLE]]
	for r: Array in rings:
		var col: Color = r[2]
		_prism(_circle(c, float(r[0]), 32), g - 0.3, g + float(r[1]), col.darkened(0.06), col, M_STONE, M_STONE)
	# The low cone, cobbled on top.
	_mode = M_STONE
	_frustum(_circle(c, 4.4, 24), g + 0.64, _circle(c, 3.2, 24), g + 1.1, GAULLE_CONE, GAULLE_COBBLE.darkened(0.1))
	# The plinth in the walk's frame (u along the walk, v to his left), a faint joint at a third.
	_o = c
	_a = GAULLE_WALK
	_b = Vector2(-_a.y, _a.x)
	var top := g + 1.1 + GAULLE_PLINTH_H
	_lbox(0.0, 0.0, 1.35, 0.9, g + 1.0, g + 2.45, GAULLE_GRANITE, M_STONE, GAULLE_GRANITE)
	_lbox(0.0, 0.0, 1.33, 0.88, g + 2.45, top, GAULLE_GRANITE.lightened(0.03), M_STONE, GAULLE_GRANITE.darkened(0.05))
	_gaulle_figure(top, 3.3)
	_collide(_circle(c, 4.4, 16))


## The general, `h` m tall from his soles at `y`, in the frame _o/_a/_b (u forward): legs apart
## in mid-stride, the coat to the knee, the near arm forward, the other back, the kepi.
func _gaulle_figure(y: float, h: float) -> void:
	var k := h / 3.3
	var bz := GAULLE_BRONZE
	var none := Color(0, 0, 0, 0)
	# Legs: the front foot ahead, the back one pushing off; a shoe each.
	for side: float in [1.0, -1.0]:
		var hip := _w(0.0, 0.14 * side)
		var foot := _w(0.5 * side * k, 0.15 * side)
		var lift := 0.0 if side > 0.0 else 0.08 * k
		_beam(Vector3(hip.x, y + 1.62 * k, hip.y), Vector3(foot.x, y + lift + 0.08 * k, foot.y), 0.24 * k, bz)
		var toe := _w((0.5 * side + 0.16) * k, 0.15 * side)
		_beam(Vector3(foot.x, y + lift + 0.06 * k, foot.y), Vector3(toe.x, y + 0.06 * k, toe.y), 0.15 * k, bz.darkened(0.1))
	# The long coat: a flared skirt, the body, the shoulders.
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 0.34 * k, 0.33 * k), y + 1.0 * k, _rect(0.0, 0.0, 0.23 * k, 0.27 * k), y + 1.75 * k, bz)
	_prism(_rect(0.0, 0.0, 0.2 * k, 0.27 * k), y + 1.75 * k, y + 2.5 * k, bz, none, M_STONE)
	_frustum(_rect(0.0, 0.0, 0.2 * k, 0.29 * k), y + 2.5 * k, _rect(0.0, 0.0, 0.14 * k, 0.18 * k), y + 2.66 * k, bz, bz)
	# Arms swing against the legs: the right forward, the left back, from the shoulders.
	for side: float in [1.0, -1.0]:
		var sh := _w(0.0, 0.31 * side * k)
		var hand := _w(-0.32 * side * k, 0.36 * side * k)
		_beam(Vector3(sh.x, y + 2.55 * k, sh.y), Vector3(hand.x, y + 1.72 * k, hand.y), 0.13 * k, bz)
	# The neck, the head and the kepi with its peak forward.
	_prism(_rect(0.0, 0.0, 0.06 * k, 0.06 * k), y + 2.62 * k, y + 2.72 * k, bz, none, M_STONE)
	_prism(_rect(0.02 * k, 0.0, 0.11 * k, 0.1 * k), y + 2.72 * k, y + 2.98 * k, bz, none, M_STONE)
	_prism(_circle(_w(0.0, 0.0), 0.12 * k, 8), y + 2.98 * k, y + 3.16 * k, bz.darkened(0.08), bz.darkened(0.12), M_STONE, M_STONE)
	_prism(_rect(0.15 * k, 0.0, 0.07 * k, 0.1 * k), y + 2.98 * k, y + 3.0 * k, bz.darkened(0.15), bz.darkened(0.15), M_STONE, M_STONE)


# --- Dom Partii, today Centrum Bankowo-Finansowe (F's photos, 2026-11-01 and 2026-11-11) ---------

## The Party House (1948-1952, Nowy Świat 6/12, today Centrum Bankowo-Finansowe), modelled whole
## from F's photos (2026-11-11: the front from the plaza, the corner from Rondo de Gaulle'a, Nowy
## Świat's Street View, the courtyard by night; spec docs/landmarks/specs/dom_partii.md). A ring of
## white stone round a courtyard, every rectangle from the mapped parts (centrum.json):
## - two side wings 14.2 m deep (along Nowy Świat and along the back) to LoD2's 30 m, a storey over
##   the middle bodies, so from the avenue their ends read as corner towers: a ledge at every
##   storey, three windows a storey on the towers' fronts, pairs of windows between, an attic of
##   small square windows under a cornice, shop windows on the street side's ground floor and
##   portals with lamps on the courtyard's;
## - two middle bodies (the front on Al. Jerozolimskie, 2 m back from the towers, and the back) on
##   an open colonnade 6.6 m high (OSM's min_height): five bays between square piers, two glass
##   lobbies (OSM's 7.6 m parts), the middle bay open through to the courtyard; over them a pilaster
##   grid, a row of tall French windows, three rows of paired windows and a frieze of small square
##   ones under the cornice; a long balcony with an iron railing over the front colonnade;
## - the courtyard: pale granite slabs with a dark key border, the wavy fountain round the mapped
##   pool (a granite rim lit underneath by a warm strip at night, five jets), planters;
## - the roof signs (parodies): ŻUBR on a white board over the north-west tower (F, 2026-11-20),
##   ROBUR (the oak in Latin) on the north-east tower, WISTULA in letters on the front body.
## The car drives through the colonnade into the courtyard (the piers, the lobbies, the wings and
## the fountain's rim collide). Frame: u east along the front from the north-west corner, v south
## into the block.
const DOM_NW := Vector2(-161.1, 294.6)     # the outline's north-west corner
const DOM_A := Vector2(0.95898, -0.28346)  # along the front (Al. Jerozolimskie's side)
const DOM_LEN := 75.5                      # the front (u)
const DOM_DEPTH := 90.6                    # Nowy Świat's front (v)
const DOM_WING := 14.2                     # the side wings: u 0..14.2 and 61.3..75.5
const DOM_BODY_V := [Vector2(2.0, 16.4), Vector2(74.2, 88.4)]  # the middle bodies (v)
const DOM_GF := 6.6                        # the ground floor (OSM min_height of the bodies)
const DOM_STOREY := 3.8
const DOM_WING_EAVE := 28.8                # five storeys and the attic
const DOM_WING_TOP := 30.0                 # LoD2's 30 m roof
const DOM_BODY_EAVE := 25.0                # four storeys and the frieze
const DOM_BODY_TOP := 26.0                 # a storey under the wings (the photos)
const DOM_PIERS := [24.3, 33.3, 42.3, 51.2]  # the colonnade's square piers (u)
const DOM_LOBBIES := [Vector2(25.0, 32.5), Vector2(43.0, 50.5)]  # the glass lobbies (u), OSM parts
const DOM_FOUNTAIN_UV := Vector2(37.7, 45.2)  # the mapped pool's middle, its long axis along v
const DOM_STONE := Color("#ebe8df")
const DOM_LEDGE := Color("#f4f1ea")
const DOM_SHADE := Color("#cfcbc1")
const DOM_ROOF := Color("#8e9091")
const DOM_GLASS := Color("#36414b")
const DOM_LOBBY := Color("#4a5a63")
const DOM_IRON := Color("#55595e")
const DOM_DOOR := Color("#2c2b2a")
const DOM_PAVING := Color("#cfcbc2")
const DOM_KEY := Color("#8c8983")
const DOM_FIELD := Color("#bfbab0")
const DOM_GRANITE := Color("#c9c6bf")
const DOM_POOL := Color("#3f6670")
const DOM_JET := Color("#e6f4f8")
const DOM_LED := Color("#f6dc9a")
const DOM_HALO := Color("#d8cdb0")
const DOM_LAMP := Color("#f3e2b0")
const DOM_LEAF := Color("#3f6a3a")
const DOM_BOARD := Color("#f2f2ee")
const DOM_SIGN := Color(0.95, 0.97, 1.0)
const DOM_ZUBR := Color(0.86, 0.13, 0.2)
const DOM_WISTULA := Color(0.22, 0.3, 0.62)
const DOM_NAVY := Color(0.14, 0.18, 0.36)
const DOM_SOFFIT := Color("#a9a59c")
const DOM_TABLE := Color("#3b3a38")
const DOM_CHAIR := Color("#c9a24a")
const DOM_TERRACE := 0.75                  # the arcade's terrace over the plaza: five steps
const DOM_STEPS := Vector2(21.0, 53.0)     # the steps' span (u), between the two stone drums
const DOM_TERRACE_V := -6.5                # the terrace's edge (v), in front of the towers' fronts
const DOM_LOGGIAS := [Vector2(DOM_WING, 24.3), Vector2(51.2, DOM_LEN - DOM_WING)]  # the deep end bays (u)
const DOM_LOGGIA_BACK := 9.0               # their back wall (v)


func _find_dom_partii() -> void:
	var outline := _landmark("Centrum Bankowo-Finansowe")
	if outline.size() < 3:
		return
	_add_site("dom_partii", [_largest(Geometry2D.offset_polygon(outline, 0.5, Geometry2D.JOIN_MITER))])
	# The front's terrace and steps (`_dp_arcade`) stay clear of the plaza's mapped trees.
	var a := DOM_A.normalized()
	var b := Vector2(-a.y, a.x)
	var t := PackedVector2Array()
	for q: Vector2 in [Vector2(-1.0, DOM_TERRACE_V - 3.0), Vector2(DOM_LEN + 1.0, DOM_TERRACE_V - 3.0),
			Vector2(DOM_LEN + 1.0, DOM_BODY_V[0].x), Vector2(-1.0, DOM_BODY_V[0].x)]:
		t.append(DOM_NW + a * q.x + b * q.y)
	tree_free.append([t, 0.0, _box_of([t])])


## Evenly spaced bay middles from a to b, `n` bays, each giving `per` windows `gap` apart.
func _dp_cols(a: float, b: float, n: int, per: int, gap: float) -> Array:
	var out := []
	for c: float in _spread(a, b, n):
		for k in per:
			out.append(c + (k - (per - 1) * 0.5) * gap)
	return out


## Panes on the local face p0→p1 (u, v) facing `out` (local): at `cols` (metres from p0), sills
## `rows` over the ground, each w × h and `proud` out, each lit on its own at night (`_lit`).
## Straight quads, not `_wall`s: there are some 1,700, and `_wall`'s coplanar cut is quadratic
## in a site's walls.
func _dp_panes(p0: Vector2, p1: Vector2, out: Vector2, cols: Array, rows: Array, w: float, h: float, col: Color,
		proud := 0.05) -> void:
	var a := _wl(p0)
	var d := (_wl(p1) - a).normalized()
	var o := (_a * out.x + _b * out.y).normalized()
	var n := Vector3(o.x, 0.0, o.y)
	var keep := _mode
	for t: float in cols:
		var q0 := a + d * (t - w * 0.5) + o * proud
		var q1 := a + d * (t + w * 0.5) + o * proud
		for s: float in rows:
			var y0 := _g + s
			_mode = _lit(t + p0.x * 7.0 + p0.y * 3.0, y0)
			_quad(Vector3(q0.x, y0, q0.y), Vector3(q1.x, y0, q1.y), Vector3(q1.x, y0 + h, q1.y), Vector3(q0.x, y0 + h, q0.y), n, col,
					Vector2(t, s), Vector2(t + w, s), Vector2(t + w, s + h), Vector2(t, s + h), s + h)
	_mode = keep


## A pier `w` wide and `proud` out of the local face p0→p1 at t (metres from p0), from y0 to y1
## over the ground: its front and its two sides.
func _dp_strip(p0: Vector2, p1: Vector2, out: Vector2, t: float, w: float, proud: float, y0: float, y1: float,
		col: Color) -> void:
	var a := _wl(p0)
	var d := (_wl(p1) - a).normalized()
	var o := (_a * out.x + _b * out.y).normalized()
	var b0 := a + d * (t - w * 0.5)
	var b1 := a + d * (t + w * 0.5)
	var f0 := b0 + o * proud
	var f1 := b1 + o * proud
	var ya := _g + y0
	var yb := _g + y1
	var side := col.darkened(0.07)
	_quad(Vector3(f0.x, ya, f0.y), Vector3(f1.x, ya, f1.y), Vector3(f1.x, yb, f1.y), Vector3(f0.x, yb, f0.y), Vector3(o.x, 0.0, o.y), col,
			Vector2(t, y0), Vector2(t + w, y0), Vector2(t + w, y1), Vector2(t, y1), y1)
	_quad(Vector3(b0.x, ya, b0.y), Vector3(f0.x, ya, f0.y), Vector3(f0.x, yb, f0.y), Vector3(b0.x, yb, b0.y), Vector3(-d.x, 0.0, -d.y), side,
			Vector2(0, y0), Vector2(proud, y0), Vector2(proud, y1), Vector2(0, y1), y1)
	_quad(Vector3(f1.x, ya, f1.y), Vector3(b1.x, ya, b1.y), Vector3(b1.x, yb, b1.y), Vector3(f1.x, yb, f1.y), Vector3(d.x, 0.0, d.y), side,
			Vector2(0, y0), Vector2(proud, y0), Vector2(proud, y1), Vector2(0, y1), y1)


## A ledge along the local face p0→p1: its front `proud` out from y0 to y1 over the ground, and
## its top.
func _dp_ledge(p0: Vector2, p1: Vector2, out: Vector2, proud: float, y0: float, y1: float, col: Color) -> void:
	var a := _wl(p0)
	var b := _wl(p1)
	var o := (_a * out.x + _b * out.y).normalized()
	var fa := a + o * proud
	var fb := b + o * proud
	var ya := _g + y0
	var yb := _g + y1
	var run := a.distance_to(b)
	_quad(Vector3(fa.x, ya, fa.y), Vector3(fb.x, ya, fb.y), Vector3(fb.x, yb, fb.y), Vector3(fa.x, yb, fa.y), Vector3(o.x, 0.0, o.y),
			col.darkened(0.05), Vector2(0, y0), Vector2(run, y0), Vector2(run, y1), Vector2(0, y1), y1)
	_quad(Vector3(a.x, yb, a.y), Vector3(b.x, yb, b.y), Vector3(fb.x, yb, fb.y), Vector3(fa.x, yb, fa.y), Vector3.UP, col)


## A storey ledge round a whole wing (walls and top), `proud` out, y0..y1 over the ground.
func _dp_ring_ledge(r: Rect2, proud: float, y0: float, y1: float, col: Color) -> void:
	var ring := _lrect(r)
	var grown := _lrect(r, proud)
	_band(ring, proud, _g + y0, _g + y1, col.darkened(0.05))
	_strip(ring, grown, _g + y1, col)


## A café table with two chairs at (u, v) on the floor y (absolute).
func _dp_table(u: float, v: float, y: float) -> void:
	_lbox(u, v, 0.05, 0.05, y, y + 0.72, DOM_TABLE, M_STONE)
	_lbox(u, v, 0.38, 0.38, y + 0.72, y + 0.77, DOM_TABLE, M_STONE)
	for s: float in [-1.0, 1.0]:
		_lbox(u + s * 0.72, v, 0.22, 0.22, y + 0.2, y + 0.46, DOM_CHAIR, M_STONE)
		_lbox(u + s * 0.92, v, 0.03, 0.22, y + 0.46, y + 0.95, DOM_CHAIR, M_STONE)
	_dp_guests(u, v, y)


## F (2026-11-21, teaser 4: "some sitting at the Zamieszanie tables, some with dogs"): most chairs
## taken, the guests leaning in over the table, and a dog lying by one table in three. Picked by
## the table's place (the same guests every bake), boxes in the landmark's own mesh (+0 draw calls).
func _dp_guests(u: float, v: float, y: float) -> void:
	var h := absf(fposmod(sin(u * 12.9898 + v * 78.233) * 43758.5453, 1.0))
	var shirts := [Color("#f2efe8"), Color("#2f6fb5"), Color("#e0b23a"), Color("#3b8f5a"), Color("#e57aa0"),
			Color("#d8432f"), Color("#5aa9c9"), Color("#2b2c2f"), Color("#c96b2c"), Color("#7a4fa8")]
	var legs := [Color("#2b3a55"), Color("#3a3a3d"), Color("#c9b38c"), Color("#5a6a7a")]
	var skins := [Color("#e9c4a6"), Color("#d8a684"), Color("#b98262"), Color("#f0d2b8")]
	var hairs := [Color("#3a2a20"), Color("#1e1a18"), Color("#d9c27a"), Color("#8a5a3a")]
	var k := 0
	for s: float in [-1.0, 1.0]:
		k += 1
		var r := fposmod(h * (7.0 + k * 3.0), 1.0)
		if r > 0.78:
			continue  # an empty chair
		var shirt: Color = shirts[int(r * 97.0) % shirts.size()]
		var leg: Color = legs[int(r * 53.0) % legs.size()]
		var skin: Color = skins[int(r * 31.0) % skins.size()]
		var hair: Color = hairs[int(r * 71.0) % hairs.size()]
		for side: float in [-0.09, 0.09]:
			_lbox(u + s * 0.48, v + side, 0.05, 0.06, y, y + 0.46, leg, M_STONE)
		_lbox(u + s * 0.6, v, 0.16, 0.15, y + 0.46, y + 0.6, leg, M_STONE)
		_lbox(u + s * 0.77, v, 0.11, 0.19, y + 0.6, y + 1.14, shirt, M_STONE)
		for side: float in [-0.19, 0.19]:
			_lbox(u + s * 0.7, v + side, 0.045, 0.045, y + 0.8, y + 1.1, shirt, M_STONE)
			_lbox(u + s * 0.54, v + side * 0.8, 0.14, 0.04, y + 0.77, y + 0.83, skin, M_STONE)
		_lbox(u + s * 0.75, v, 0.1, 0.1, y + 1.17, y + 1.39, skin, M_STONE)
		_lbox(u + s * 0.78, v, 0.105, 0.105, y + 1.36, y + 1.43, hair, M_STONE)
	if h < 0.36:
		# A dog lying by the table, its head up towards the guests.
		var dogs := [Color("#c9a26a"), Color("#2b2522"), Color("#8a5a3a"), Color("#e8e2d6")]
		var dc: Color = dogs[int(h * 40.0) % dogs.size()]
		var du := u + (0.35 if h < 0.18 else -0.35)
		var dv := v - 0.72
		var f := 1.0 if h < 0.18 else -1.0
		_lbox(du, dv, 0.3, 0.12, y, y + 0.24, dc, M_STONE)
		_lbox(du - f * 0.36, dv, 0.09, 0.08, y + 0.14, y + 0.36, dc, M_STONE)
		_lbox(du - f * 0.44, dv, 0.06, 0.05, y + 0.18, y + 0.28, dc.darkened(0.25), M_STONE)
		_lbox(du + f * 0.34, dv, 0.1, 0.03, y + 0.16, y + 0.2, dc, M_STONE)


## F (2026-11-21, teaser 4, his photos of the courtyard at night): the courtyard lives. Rows of
## deckchairs either side of the fountain, most taken, facing a low stage with a screen and a
## row of blue lights before the far body's middle bay (the summer bar's events; its parody name
## OLDTWICE in neon over it), and people standing about in twos and threes. Boxes and beams in
## the landmark's mesh (+0 draw calls), the same guests every bake (picked by place).
func _dp_courtyard_life(y: float) -> void:
	var shirts := [Color("#f2efe8"), Color("#2f6fb5"), Color("#e0b23a"), Color("#3b8f5a"), Color("#e57aa0"),
			Color("#d8432f"), Color("#5aa9c9"), Color("#2b2c2f"), Color("#c96b2c"), Color("#7a4fa8")]
	var legs := [Color("#2b3a55"), Color("#3a3a3d"), Color("#c9b38c"), Color("#5a6a7a")]
	var skins := [Color("#e9c4a6"), Color("#d8a684"), Color("#b98262"), Color("#f0d2b8")]
	var slings := [Color("#e8742a"), Color("#26365a"), Color("#e8742a"), Color("#d9d6cf")]
	var frame_c := Color("#c9a26a")
	var up := Vector3.UP
	# The stage before the far body (v ~ 70), its screen and blue lights, and the bar's neon.
	var su := DOM_FOUNTAIN_UV.x
	_lbox(su, 70.2, 4.5, 1.6, y, y + 0.6, Color("#1e1f22"), M_STONE)
	_lbox(su, 71.5, 1.6, 0.12, y + 0.6, y + 4.2, Color("#26292e"), M_STONE)
	_mode = M_LAMP
	for k in 9:
		_lbox(su - 4.0 + k, 68.55, 0.18, 0.05, y + 0.35, y + 0.5, Color(0.35, 0.45, 1.0), M_LAMP)
	_mode = M_STONE
	var mid := _w(su, DOM_BODY_V[1].x - 0.3)
	signs.append(["OLDTWICE", Vector3(mid.x, y + 6.4, mid.y), Vector3(_b.x, 0.0, _b.y), 5.0 / Neon.length_of("OLDTWICE"), Color(0.55, 0.62, 1.0)])
	# The deckchairs: rows either side of the fountain, facing the stage (+v).
	var n := 0
	for side: float in [-1.0, 1.0]:
		for row in 7:
			for col in 3:
				var u := su + side * (7.5 + col * 2.4 + (row % 2) * 0.6)
				var v := 26.0 + row * 5.4
				var h := absf(fposmod(sin(u * 12.9898 + v * 78.233) * 43758.5453, 1.0))
				if h > 0.86:
					continue
				n += 1
				var f := func(du: float, dy: float, dv: float) -> Vector3:
					var q := _w(u + du, v + dv)
					return Vector3(q.x, y + dy, q.y)
				var sl: Color = slings[int(h * 37.0) % slings.size()]
				for x: float in [-0.3, 0.3]:
					_beam(f.call(x, 0.0, -0.55), f.call(x, 0.95, 0.15), 0.06, frame_c)
				_beam(f.call(0.0, 0.92, 0.12), f.call(0.0, 0.3, -0.45), 0.58, sl)
				if h > 0.7:
					continue  # an empty chair
				var shirt: Color = shirts[int(h * 97.0) % shirts.size()]
				var leg: Color = legs[int(h * 53.0) % legs.size()]
				var skin: Color = skins[int(h * 31.0) % skins.size()]
				_beam(f.call(0.0, 0.5, -0.25), f.call(0.0, 1.0, 0.08), 0.44, shirt)
				_lbox(u, v + 0.12, 0.12, 0.12, y + 1.05, y + 1.3, skin, M_STONE)
				for x: float in [-0.11, 0.11]:
					_beam(f.call(x, 0.45, -0.25), f.call(x, 0.5, -0.78), 0.16, leg)
					_beam(f.call(x, 0.5, -0.78), f.call(x, 0.05, -1.0), 0.13, leg)
	# People standing in twos and threes between the rows and by the stage.
	var groups := [Vector2(su - 3.5, 30.0), Vector2(su + 3.5, 38.0), Vector2(su - 3.0, 58.5), Vector2(su + 3.2, 62.0),
			Vector2(su - 9.0, 66.0), Vector2(su + 9.5, 66.5), Vector2(su - 16.0, 24.0), Vector2(su + 16.5, 47.0)]
	for gi in groups.size():
		var gc: Vector2 = groups[gi]
		for j in 2 + gi % 2:
			var a := TAU * j / (2.0 + gi % 2) + gi
			var pu := gc.x + cos(a) * 0.55
			var pv := gc.y + sin(a) * 0.55
			var h := absf(fposmod(sin(pu * 7.13 + pv * 3.77) * 43758.5453, 1.0))
			var shirt: Color = shirts[int(h * 97.0) % shirts.size()]
			var leg: Color = legs[int(h * 53.0) % legs.size()]
			var skin: Color = skins[int(h * 31.0) % skins.size()]
			_lbox(pu, pv, 0.16, 0.1, y, y + 0.86, leg, M_STONE)
			_lbox(pu, pv, 0.21, 0.13, y + 0.86, y + 1.48, shirt, M_STONE)
			_lbox(pu, pv, 0.11, 0.11, y + 1.5, y + 1.75, skin, M_STONE)
	print("dom_partii: %d deckchairs in the courtyard" % n)


## A clipped ball tree in a square granite planter at (u, v) on the floor y (the towers' fronts).
func _dp_topiary(u: float, v: float, y: float) -> void:
	_lbox(u, v, 0.5, 0.5, y, y + 0.8, DOM_GRANITE, M_STONE, DOM_SHADE)
	_lbox(u, v, 0.04, 0.04, y + 0.8, y + 2.0, DOM_DOOR, M_STONE)
	var c := _w(u, v)
	_frustum(_circle(c, 0.15, 6), y + 1.85, _circle(c, 0.62, 6), y + 2.3, DOM_LEAF)
	_frustum(_circle(c, 0.62, 6), y + 2.3, _circle(c, 0.18, 6), y + 2.85, DOM_LEAF.lightened(0.08), DOM_LEAF.lightened(0.12))


## The front's ground floor from F's photos (2026-11-19: the front from the plaza, the terrace at
## dusk, the corner from the statue): the colonnade stands on a stone terrace five steps over the
## plaza, edged by a low wall that ends in two round drums by the steps; the two glass bays are
## cafés (parodies: SZARLOTKA and the cocktail bar's neon Z, ZAMIESZAJ), the two end bays deep
## loggias whose back walls hold a beer bar (CUDA NA PATYKU) and a door; the middle bay goes
## through to the courtyard down steps. A dark soffit with lamps, lanterns on the piers, café
## tables in the loggias and along the terrace, planters, and clipped ball trees before the
## towers' stone-panelled ground floors. The terrace collides: cars stay on the plaza.
func _dp_arcade(g: float, pave: float) -> void:
	var tt := g + DOM_TERRACE
	var foot := g - 4.5
	var u0 := DOM_WING
	var u1 := DOM_LEN - DOM_WING
	var body: Vector2 = DOM_BODY_V[0]
	_mode = M_STONE
	# The terrace and the arcade's floor: one slab from the plaza's edge into the courtyard's mouth.
	var terrace := Rect2(-0.3, DOM_TERRACE_V, DOM_LEN + 0.6, body.x - DOM_TERRACE_V)
	_prism(_lrect(terrace), foot, tt, DOM_SHADE, DOM_PAVING, M_STONE, M_STONE)
	var deck := Rect2(u0, body.x, u1 - u0, body.y - body.x)
	_prism(_lrect(deck), foot, tt, DOM_SHADE, DOM_FIELD.darkened(0.12), M_STONE, M_STONE)
	_collide(_lrect(terrace))
	_collide(_lrect(deck))
	# The low wall on the terrace's edge either side of the steps, ending in the round drums.
	var lip := DOM_TERRACE_V + 0.2
	for span: Vector2 in [Vector2(-0.3, DOM_STEPS.x - 1.5), Vector2(DOM_STEPS.y + 1.5, DOM_LEN + 0.3)]:
		_lbox((span.x + span.y) * 0.5, lip, (span.y - span.x) * 0.5, 0.2, tt - 0.05, tt + 0.4, DOM_LEDGE, M_STONE, DOM_STONE)
	for du: float in [DOM_STEPS.x - 1.5, DOM_STEPS.y + 1.5]:
		var c := _w(du, DOM_TERRACE_V + 1.2)
		_prism(_circle(c, 1.5, 12), foot, tt + 0.55, DOM_LEDGE, DOM_STONE, M_STONE, M_STONE)
		_collide(_circle(c, 1.5, 8))
	# The steps down to the plaza, five of 15 cm, each 40 cm deep.
	for k in 5:
		var d := 0.4 * (5 - k)
		var top := g + DOM_TERRACE * (k + 1) / 6.0
		_prism(_lrect(Rect2(DOM_STEPS.x, DOM_TERRACE_V - d, DOM_STEPS.y - DOM_STEPS.x, d)), foot, top,
				DOM_SHADE, DOM_PAVING.darkened(0.03 * (k % 2)), M_STONE, M_STONE)
	_collide(_lrect(Rect2(DOM_STEPS.x, DOM_TERRACE_V - 2.0, DOM_STEPS.y - DOM_STEPS.x, 2.0)))
	# The middle bay's steps down into the courtyard (when the courtyard is lower).
	var drop := tt - pave
	if drop > 0.2:
		var n := clampi(roundi(drop / 0.15), 2, 8)
		for k in n:
			var d := 0.4 * (n - k)
			_prism(_lrect(Rect2(DOM_PIERS[1] + 0.7, body.y, DOM_PIERS[2] - DOM_PIERS[1] - 1.4, d)), pave - 0.3,
					tt - drop * (n - k) / (n + 1.0), DOM_SHADE, DOM_PAVING, M_STONE, M_STONE)
	# The soffit: the bodies' undersides, shaded, with a lamp in each bay (warm at night).
	for bv: Vector2 in DOM_BODY_V:
		var r := _lrect(Rect2(u0, bv.x, u1 - u0, bv.y - bv.x))
		var y := g + DOM_GF - 0.01
		_quad(Vector3(r[0].x, y, r[0].y), Vector3(r[1].x, y, r[1].y), Vector3(r[2].x, y, r[2].y), Vector3(r[3].x, y, r[3].y),
				Vector3.DOWN, DOM_SOFFIT)
	_mode = M_LAMP
	var bays := [u0] + DOM_PIERS + [u1]
	for k in bays.size() - 1:
		var mu := (float(bays[k]) + float(bays[k + 1])) * 0.5
		for lv: float in [body.x + 2.5, body.x + 7.0]:
			var c := _rect(mu, lv, 0.4, 0.4)
			var y := g + DOM_GF - 0.04
			_quad(Vector3(c[0].x, y, c[0].y), Vector3(c[1].x, y, c[1].y), Vector3(c[2].x, y, c[2].y), Vector3(c[3].x, y, c[3].y),
					Vector3.DOWN, DOM_LAMP)
	# A lantern on each pier's plaza face.
	for pu: float in DOM_PIERS:
		_lbox(pu, body.x - 0.05, 0.14, 0.1, g + 3.3, g + 3.85, DOM_LAMP, M_LAMP, DOM_IRON)
	_mode = M_STONE
	# The cafés: mullions on the glass, the signs, planters before them.
	var front_v := body.x + 1.6
	for i in DOM_LOBBIES.size():
		var lb: Vector2 = DOM_LOBBIES[i]
		var p0 := Vector2(lb.x, front_v)
		var p1 := Vector2(lb.y, front_v)
		var w := lb.y - lb.x
		for k in range(0, 4):
			_dp_strip(p0, p1, Vector2(0.0, -1.0), w * k / 3.0, 0.14, 0.06, DOM_TERRACE, DOM_GF, DOM_IRON)
		_dp_strip(p0, p1, Vector2(0.0, -1.0), w * 0.5, w, 0.06, DOM_TERRACE + 2.9, DOM_TERRACE + 3.0, DOM_IRON)
		for pu: float in [lb.x + 1.0, lb.y - 1.0]:
			_lbox(pu, body.x + 0.9, 0.45, 0.45, tt, tt + 0.7, DOM_GRANITE, M_STONE, DOM_SHADE)
			var c := _w(pu, body.x + 0.9)
			_frustum(_circle(c, 0.6, 6), tt + 0.7, _circle(c, 0.1, 6), tt + 2.4, DOM_LEAF, DOM_LEAF)
		var mid := _w((lb.x + lb.y) * 0.5, front_v)
		var out := Vector3(-_b.x, 0.0, -_b.y)
		if i == 0:
			# The cocktail bar: its tall neon Z behind the glass, the name over it.
			signs.append(["Z", Vector3(mid.x, tt + 1.2, mid.y), out, 0.95, DOM_SIGN])
			signs.append(["ZAMIESZAJ", Vector3(mid.x, g + DOM_GF - 1.55, mid.y), out, 5.6 / Neon.length_of("ZAMIESZAJ"), DOM_SIGN])
		else:
			signs.append(["SZARLOTKA", Vector3(mid.x, g + DOM_GF - 1.55, mid.y), out, 6.0 / Neon.length_of("SZARLOTKA"),
					Color(1.0, 0.82, 0.55)])
	# The loggias: a back wall with a door and two windows, a lantern each side; tables.
	for i in DOM_LOGGIAS.size():
		var lg: Vector2 = DOM_LOGGIAS[i]
		var span := Rect2(lg.x, DOM_LOGGIA_BACK, lg.y - lg.x, body.y - DOM_LOGGIA_BACK)
		_prism(_lrect(span), tt - 0.1, g + DOM_GF, DOM_STONE.darkened(0.06), Color(0, 0, 0, 0), M_STONE)
		var p0 := Vector2(lg.x, DOM_LOGGIA_BACK)
		var p1 := Vector2(lg.y, DOM_LOGGIA_BACK)
		var w := lg.y - lg.x
		_dp_panes(p0, p1, Vector2(0.0, -1.0), [w * 0.5], [DOM_TERRACE], 1.8, 2.9, DOM_DOOR, 0.05)
		_dp_panes(p0, p1, Vector2(0.0, -1.0), [w * 0.2, w * 0.8], [DOM_TERRACE + 0.5], 1.6, 2.6, DOM_LOBBY, 0.05)
		_mode = M_LAMP
		for s: float in [-1.6, 1.6]:
			_dp_strip(p0, p1, Vector2(0.0, -1.0), w * 0.5 + s, 0.22, 0.25, DOM_TERRACE + 2.3, DOM_TERRACE + 2.8, DOM_LAMP)
		_mode = M_STONE
		if i == 1:
			# Its name hangs in the bay's mouth, under the balcony, where the plaza sees it.
			var mid := _w(lg.x + w * 0.5, body.x - 0.3)
			signs.append(["CUDA NA PATYKU", Vector3(mid.x, g + DOM_GF - 1.45, mid.y), Vector3(-_b.x, 0.0, -_b.y),
					8.0 / Neon.length_of("CUDA NA PATYKU"), Color(1.0, 0.68, 0.22)])
		for tu: float in [lg.x + w * 0.27, lg.x + w * 0.73]:
			for tv: float in [body.x + 1.6, body.x + 4.6]:
				_dp_table(tu, tv, tt)
	# Café tables along the terrace before the arcade, leaving the steps' middle free.
	for tu: float in [16.5, 20.0, 23.5, 27.0, 30.5, 45.0, 48.5, 52.0, 55.5, 59.0]:
		_dp_table(tu, body.x - 2.2, tt)
	# Clipped ball trees before the towers.
	for tu: float in [2.2, 5.5, 8.8, 12.1, DOM_LEN - 12.1, DOM_LEN - 8.8, DOM_LEN - 5.5, DOM_LEN - 2.2]:
		_dp_topiary(tu, -1.3, tt)


func _build_dom_partii(_site: Dictionary) -> void:
	_o = DOM_NW
	_a = DOM_A.normalized()
	_b = Vector2(-_a.y, _a.x)
	# The ground floor's level: the plaza before the front's middle (the east side falls ~3 m to
	# the escarpment, so the walls reach down past it).
	var front := _w(DOM_LEN * 0.5, -1.0)
	_g = map.terrain_height(front.x, front.y)
	var g := _g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	var foot := g - 4.5
	var wings := [Rect2(0.0, 0.0, DOM_WING, DOM_DEPTH), Rect2(DOM_LEN - DOM_WING, 0.0, DOM_WING, DOM_DEPTH)]
	var u0 := DOM_WING
	var u1 := DOM_LEN - DOM_WING
	var storeys := []   # the wings' window sills over the ground
	for k in 5:
		storeys.append(DOM_GF + DOM_STOREY * k + 0.85)
	var body_rows := [DOM_GF + DOM_STOREY + 0.9, DOM_GF + DOM_STOREY * 2.0 + 0.9, DOM_GF + DOM_STOREY * 3.0 + 0.9]
	var attic := [DOM_GF + DOM_STOREY * 5.0 + 1.2]
	var frieze := [DOM_GF + DOM_STOREY * 4.0 + 1.25]

	# --- the side wings -------------------------------------------------------------------
	for r: Rect2 in wings:
		var west := r.position.x < 1.0
		var outer_u := 0.0 if west else DOM_LEN
		var inner_u := DOM_WING if west else DOM_LEN - DOM_WING
		var o_out := Vector2(-1.0, 0.0) if west else Vector2(1.0, 0.0)
		var o_in := -o_out
		# The long street face (Nowy Świat's, or the back's): tower zones of three windows at both
		# ends, twenty bays of paired windows between, shop windows on the ground floor there.
		var s0 := Vector2(outer_u, 0.0)
		var s1 := Vector2(outer_u, DOM_DEPTH)
		var cols := [2.9, 7.1, 11.3]
		for c: float in [2.9, 7.1, 11.3]:
			cols.append(DOM_DEPTH - c)
		cols.append_array(_dp_cols(DOM_WING, DOM_DEPTH - DOM_WING, 20, 2, 1.45))
		_dp_panes(s0, s1, o_out, cols, storeys, 1.15, 2.3, DOM_GLASS)
		_dp_panes(s0, s1, o_out, cols, attic, 0.75, 0.75, DOM_GLASS)
		_dp_panes(s0, s1, o_out, _spread(DOM_WING, DOM_DEPTH - DOM_WING, 20), [1.0], 2.3, 4.2, DOM_LOBBY)
		# The towers' fronts (north and south): three windows a storey, the attic's five.
		for v: float in [0.0, DOM_DEPTH]:
			var f0 := Vector2(r.position.x, v)
			var f1 := Vector2(r.position.x + DOM_WING, v)
			var fo := Vector2(0.0, -1.0) if v < 1.0 else Vector2(0.0, 1.0)
			_dp_panes(f0, f1, fo, [2.9, 7.1, 11.3], storeys, 1.3, 2.3, DOM_GLASS)
			_dp_panes(f0, f1, fo, _spread(0.0, DOM_WING, 5), attic, 0.75, 0.75, DOM_GLASS)
			if v > 1.0:
				_dp_panes(f0, f1, fo, [7.1], [0.0], 2.4, 3.2, DOM_DOOR, 0.12)
			else:
				# The plaza's towers have no door: their ground floor is big stone panels, four
				# across and two high (F's photos, 2026-11-19).
				for k in range(1, 4):
					_dp_strip(f0, f1, fo, DOM_WING * k / 4.0, 0.1, 0.03, 0.9, DOM_GF - 0.35, DOM_SHADE)
				_dp_strip(f0, f1, fo, DOM_WING * 0.5, DOM_WING - 0.2, 0.03, DOM_GF * 0.5 + 0.2, DOM_GF * 0.5 + 0.3, DOM_SHADE)
		# The courtyard face: eighteen bays of paired windows; on the ground floor a portal in every
		# third bay (a dark door in a stone frame, a lamp each side), a window in the rest.
		var c0 := Vector2(inner_u, DOM_BODY_V[0].y)
		var c1 := Vector2(inner_u, DOM_BODY_V[1].x)
		var span := DOM_BODY_V[1].x - DOM_BODY_V[0].y
		_dp_panes(c0, c1, o_in, _dp_cols(0.0, span, 18, 2, 1.45), storeys, 1.15, 2.3, DOM_GLASS)
		_dp_panes(c0, c1, o_in, _dp_cols(0.0, span, 18, 2, 1.45), attic, 0.75, 0.75, DOM_GLASS)
		var bays := _spread(0.0, span, 18)
		var doors := []
		var wins := []
		for k in bays.size():
			if k % 3 == 1:
				doors.append(bays[k])
			else:
				wins.append(bays[k])
		_dp_panes(c0, c1, o_in, wins, [1.2], 1.6, 3.4, DOM_GLASS)
		_dp_panes(c0, c1, o_in, doors, [0.0], 1.9, 3.7, DOM_DOOR, 0.12)
		for t: float in doors:
			for side: float in [-1.0, 1.0]:
				_dp_strip(c0, c1, o_in, t + side * 1.2, 0.4, 0.16, 0.0, 4.2, DOM_LEDGE)
				_mode = M_LAMP
				_dp_strip(c0, c1, o_in, t + side * 1.75, 0.22, 0.3, 3.0, 3.5, DOM_LAMP)
				_mode = M_STONE
		# The mass, a darker plinth, the ledges, the cornice, the parapet and the roof.
		_prism(_lrect(r), foot, g + DOM_WING_EAVE, DOM_STONE, none, M_STONE)
		_band(_lrect(r), 0.08, foot, g + 0.9, DOM_SHADE)
		_dp_ring_ledge(r, 0.4, DOM_GF - 0.35, DOM_GF, DOM_LEDGE)
		for k in range(1, 6):
			var y := DOM_GF + DOM_STOREY * k
			_dp_ring_ledge(r, 0.22, y - 0.25, y, DOM_LEDGE)
		_prism(_lrect(r, 0.6), g + DOM_WING_EAVE, g + DOM_WING_EAVE + 0.5, DOM_LEDGE, DOM_LEDGE, M_STONE, M_STONE)
		_prism(_lrect(r), g + DOM_WING_EAVE + 0.5, g + DOM_WING_TOP, DOM_STONE, DOM_ROOF, M_STONE, M_STONE)
		# Two lift houses on the roof.
		var cu := r.position.x + DOM_WING * 0.5
		for v: float in [24.0, 66.0]:
			_lbox(cu, v, 2.2, 3.0, g + DOM_WING_TOP, g + DOM_WING_TOP + 2.6, DOM_SHADE, M_STONE, DOM_ROOF)
		_collide(_lrect(r))

	# --- the middle bodies ----------------------------------------------------------------
	for i in DOM_BODY_V.size():
		var bv: Vector2 = DOM_BODY_V[i]
		var r := Rect2(u0, bv.x, u1 - u0, bv.y - bv.x)
		var street_v := bv.x if i == 0 else bv.y
		var court_v := bv.y if i == 0 else bv.x
		var s_out := Vector2(0.0, -1.0) if i == 0 else Vector2(0.0, 1.0)
		for face: Array in [[street_v, s_out], [court_v, -s_out]]:
			var v: float = face[0]
			var o: Vector2 = face[1]
			var p0 := Vector2(u0, v)
			var p1 := Vector2(u1, v)
			var w := u1 - u0
			# The first row's French windows, one a bay; three rows of pairs; the frieze's squares.
			_dp_panes(p0, p1, o, _spread(0.0, w, 15), [DOM_GF + 0.35], 1.5, 3.0, DOM_GLASS)
			_dp_panes(p0, p1, o, _dp_cols(0.0, w, 15, 2, 1.5), body_rows, 0.95, 2.2, DOM_GLASS)
			_dp_panes(p0, p1, o, _dp_cols(0.0, w, 15, 2, 1.5), frieze, 0.7, 0.7, DOM_GLASS)
			# The pilaster grid between the bays, a ledge over the first row and under the frieze.
			for k in range(1, 15):
				_dp_strip(p0, p1, o, w * k / 15.0, 0.45, 0.12, DOM_GF + 0.3, DOM_GF + DOM_STOREY * 4.0, DOM_LEDGE)
			# (stopping short of the wings, whose own ledges at these heights reach 0.22 m out)
			var e0 := p0 + Vector2(0.25, 0.0)
			var e1 := p1 - Vector2(0.25, 0.0)
			_dp_ledge(e0, e1, o, 0.2, DOM_GF + DOM_STOREY - 0.2, DOM_GF + DOM_STOREY, DOM_LEDGE)
			_dp_ledge(e0, e1, o, 0.28, DOM_GF + DOM_STOREY * 4.0 - 0.3, DOM_GF + DOM_STOREY * 4.0, DOM_LEDGE)
			# The colonnade's piers on this face.
			var pv := v - o.y * 0.7
			for pu: float in DOM_PIERS:
				_lbox(pu, pv, 0.65, 0.65, g - 0.5, g + DOM_GF, DOM_STONE, M_STONE)
				_collide(_rect(pu, pv, 0.65, 0.65))
		# The mass over the colonnade, its cornice, parapet and roof.
		_prism(_lrect(r), g + DOM_GF, g + DOM_BODY_EAVE, DOM_STONE, none, M_STONE)
		_prism(_lrect(r, 0.6), g + DOM_BODY_EAVE, g + DOM_BODY_EAVE + 0.45, DOM_LEDGE, DOM_LEDGE, M_STONE, M_STONE)
		_prism(_lrect(r), g + DOM_BODY_EAVE + 0.45, g + DOM_BODY_TOP, DOM_STONE, DOM_ROOF, M_STONE, M_STONE)
		# The glass lobbies, lit from inside at night.
		for lb: Vector2 in DOM_LOBBIES:
			var lr := Rect2(lb.x, bv.x + 1.6, lb.y - lb.x, bv.y - bv.x - 3.2)
			_prism(_lrect(lr), g - 0.3, g + DOM_GF, DOM_LOBBY, none, M_PAVILION)
			_collide(_lrect(lr))
	# The balcony over the front colonnade: a stone slab and an iron railing.
	var bal := Rect2(u0 + 0.3, DOM_BODY_V[0].x - 0.85, u1 - u0 - 0.6, 0.85)
	_prism(_lrect(bal), g + DOM_GF, g + DOM_GF + 0.25, DOM_LEDGE, DOM_LEDGE, M_STONE, M_STONE)
	_prism(_lrect(Rect2(bal.position.x, bal.position.y, bal.size.x, 0.06)), g + DOM_GF + 0.25, g + DOM_GF + 1.25,
			DOM_IRON, DOM_IRON, M_STONE, M_STONE)

	# --- the courtyard ----------------------------------------------------------------------
	# Pale slabs over the colonnades and the courtyard at its highest ground, a dark key border
	# and a lighter field in the courtyard.
	var yard := Rect2(u0, DOM_BODY_V[0].x, u1 - u0, DOM_BODY_V[1].y - DOM_BODY_V[0].x)
	var court := Rect2(u0, DOM_BODY_V[0].y, u1 - u0, DOM_BODY_V[1].x - DOM_BODY_V[0].y)
	var top := g
	for k in 30:
		var q := _w(u0 + (k % 6 + 0.5) / 6.0 * (u1 - u0), yard.position.y + (k / 6 + 0.5) / 5.0 * yard.size.y)
		top = maxf(top, map.terrain_height(q.x, q.y))
	var pave := top + 0.06
	_prism(_lrect(yard), g - 0.6, pave, DOM_SHADE, DOM_PAVING, M_STONE, M_STONE)
	_cap(_lrect(court, -1.6), pave + 0.035, DOM_KEY)
	_cap(_lrect(court, -2.4), pave + 0.07, DOM_FIELD)
	# The fountain: a rounded long pool whose sides swing in one wave (the photos), round the
	# mapped one; its granite rim, the water, the warm strip under the rim, five jets.
	var pool := PackedVector2Array()
	for k in 40:
		var t := TAU * k / 40.0
		var c := cos(t)
		var s := sin(t)
		var y := 10.0 * signf(s) * pow(absf(s), 0.5)
		var x := 3.6 * signf(c) * pow(absf(c), 0.5) + 0.9 * sin(PI * y / 10.0)
		pool.append(_w(DOM_FOUNTAIN_UV.x + x, DOM_FOUNTAIN_UV.y + y))
	if Geometry2D.is_polygon_clockwise(pool):
		pool.reverse()
	# The rim's outer edge: each point pushed 0.5 m out along its corner's bisector (the same
	# count as the pool's, so the top strip pairs them).
	var rim := PackedVector2Array()
	for k in pool.size():
		var p0 := pool[(k + pool.size() - 1) % pool.size()]
		var p1 := pool[k]
		var p2 := pool[(k + 1) % pool.size()]
		var n := (_out(pool, p0, p1) + _out(pool, p1, p2)).normalized()
		rim.append(p1 + n * 0.5)
	var ground := pave + 0.07
	_prism(rim, ground - 0.1, ground + 0.6, DOM_GRANITE, none, M_STONE)
	_strip(pool, rim, ground + 0.6, DOM_GRANITE.lightened(0.08))
	for k in pool.size():
		var a := pool[k]
		var b := pool[(k + 1) % pool.size()]
		_wall(a, b, ground + 0.4, ground + 0.6, -_out(pool, a, b), DOM_GRANITE.darkened(0.08))
	_cap(pool, ground + 0.4, DOM_POOL)
	# The warm strip under the rim and its light on the slabs (a pale warm ring by day, aglow
	# at night, as F's night photo).
	_band(rim, 0.06, ground, ground + 0.18, DOM_LED, M_LAMP)
	var halo := PackedVector2Array()
	for k in rim.size():
		halo.append(rim[k] + (rim[k] - pool[k]).normalized() * 0.75)
	_mode = M_LAMP
	_strip(rim, halo, ground + 0.03, DOM_HALO)
	_mode = M_STONE
	for j: Vector2 in [Vector2(0.0, 3.0), Vector2(-5.0, 4.0), Vector2(5.0, 4.0), Vector2(-2.5, 2.2), Vector2(2.5, 2.2)]:
		var p := _w(DOM_FOUNTAIN_UV.x + 0.9 * sin(PI * j.x / 10.0), DOM_FOUNTAIN_UV.y + j.x)
		_beam(Vector3(p.x, ground + 0.4, p.y), Vector3(p.x, ground + 0.4 + j.y, p.y), 0.24 if j.y > 3.0 else 0.16, DOM_JET, true, M_LAMP)
	_collide(rim)
	# Planters with clipped shrubs by the colonnades' courtyard mouths.
	_mode = M_STONE
	for pl: Vector2 in [Vector2(20.0, 19.5), Vector2(55.5, 19.5), Vector2(20.0, 71.1), Vector2(55.5, 71.1)]:
		_lbox(pl.x, pl.y, 0.6, 0.6, pave - 0.1, pave + 0.75, DOM_GRANITE, M_STONE, DOM_SHADE)
		var c := _w(pl.x, pl.y)
		_frustum(_circle(c, 0.55, 6), pave + 0.75, _circle(c, 0.08, 6), pave + 2.3, DOM_LEAF, DOM_LEAF)

	_dp_courtyard_life(pave + 0.07)
	_dp_arcade(g, pave)

	# --- the roof signs (parodies) ------------------------------------------------------------
	var wing_top := g + DOM_WING_TOP
	# PEPEO ŻUBR in red letters on a white board over the Nowy Świat tower, on its plaza and
	# street fronts (F, 2026-11-20: "make Bank Pekao": the bank's white board with the red bison
	# stands on this tower, his Street View photos).
	# F 2026-11-21: "Bank Pepeo" was too big; "maybe only Żubr", smaller, as his phone shot.
	var top_sign := "ŻUBR"
	var k_r := 1.4
	var r_len := Neon.length_of(top_sign) * k_r
	var r_h := Neon.ROW_H * Neon.PIXEL * k_r
	_lbox(r_len * 0.5 + 2.5, 0.35, r_len * 0.5 + 0.4, 0.1, wing_top, wing_top + r_h + 0.9, DOM_BOARD, M_STONE, DOM_SHADE)
	_lbox(0.35, r_len * 0.5 + 2.5, 0.1, r_len * 0.5 + 0.4, wing_top, wing_top + r_h + 0.9, DOM_BOARD, M_STONE, DOM_SHADE)
	for f: Array in [[_a, -_b], [_b, -_a]]:
		var along: Vector2 = f[0]
		var o: Vector2 = f[1]
		var mid := DOM_NW + along * (r_len * 0.5 + 2.5) - o * 0.6
		signs.append([top_sign, Vector3(mid.x, wing_top + 0.45, mid.y), Vector3(o.x, 0.0, o.y), k_r, DOM_ZUBR])
	# ROBUR (the oak in Latin) in navy letters on a white board over the north-east tower's front.
	var bu := DOM_LEN - DOM_WING * 0.5
	_lbox(bu, 1.2, 6.0, 0.25, wing_top, wing_top + 3.4, DOM_BOARD, M_STONE, DOM_SHADE)
	var k_z := minf(1.5, 10.6 / Neon.length_of("ROBUR"))
	var zp := _w(bu, 0.9)
	signs.append(["ROBUR", Vector3(zp.x, wing_top + 0.5, zp.y), Vector3(-_b.x, 0.0, -_b.y), k_z, DOM_NAVY])
	# WISTULA in letters on the front body's roof.
	var k_w := 11.0 / Neon.length_of("WISTULA")
	var wp := _w(DOM_LEN * 0.5, DOM_BODY_V[0].x + 1.2)
	signs.append(["WISTULA", Vector3(wp.x, g + DOM_BODY_TOP, wp.y), Vector3(-_b.x, 0.0, -_b.y), k_w, DOM_WISTULA])


# --- Nowy Świat 4A, the glass corner south of Dom Partii (F's night photo, 2026-11-26) -----------

## The office block at Nowy Świat 4A (OpenStreetMap's "Nowy Świat 2.0"), modelled whole from F's
## night photo from Rondo de Gaulle'a, Street View (2026-08) and the 3D Tiles render: a 78 m wedge
## along the lane south of Dom Partii, its west end rounded onto Nowy Świat. From the mapped parts:
## - a recessed glass lobby 6.6 m high (OSM's min_height of the overhang) on slim round columns,
##   lit pink-violet at night (the photo; M_PAVILION + 0.375, SOWA CLUB's tone): PRZEGRYWKI, the
##   board-game and arcade bar (the Zagrywki parody, F's "zGrywki"; storefronts.gd's venue stands
##   at this corner);
## - a copper-brown fascia and soffit over it (Street View), then four storeys of silvery glass
##   lit cool white at night (to OSM's 20.8 m) with dark frame bands at every floor and vertical fins every 1.6 m that glow
##   white at night (the photo's lit fins);
## - a white band with the flag's red stripe under it (20.8-22.3 m) wearing the tenant's sign as a
##   parody: PGR (the state farm, for the arms group's three letters), then the set-back glass top
##   storey to 24.6 m behind a glass rail;
## - on the roof a white plant box and, at the rounded end, an 11 m white pole with the Polish
##   flag caught mid-wave (a fixed ripple in the city mesh: no extra draw call).
const NS4A_STOREY := 3.55
const NS4A_LOBBY := 6.6
const NS4A_FASCIA := 7.4
const NS4A_GLASS_TOP := 20.8
const NS4A_BAND_RED := 21.25
const NS4A_BAND_TOP := 22.3
const NS4A_TOP := 24.6
const NS4A_FIN_STEP := 1.6
const NS4A_LOBBY_GLASS := Color("#3f3a62")
const NS4A_COPPER := Color("#8a4a2f")
const NS4A_GLASS := Color("#b4c6ca")
const NS4A_TOP_GLASS := Color("#5d7277")
const NS4A_FRAME := Color("#2a2c30")
const NS4A_FIN := Color("#d3dadd")
const NS4A_WHITE := Color("#f1f1ee")
const NS4A_RED := Color("#d4213d")
const NS4A_ROOF := Color("#8f9294")
const NS4A_RAIL := Color("#c6d3d7")
const NS4A_SIGN := Color(0.14, 0.17, 0.28)


func _find_ns4a() -> void:
	var outline := _landmark("Nowy Świat 2.0")
	if outline.size() < 3:
		return
	# The overhang (OSM's part from 6.6 m) stands up to 1.6 m proud of the outline: the zone takes it.
	_add_site("ns4a", [_largest(Geometry2D.offset_polygon(outline, 1.8, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "ns4a":
		sites[-1]["ring"] = _simplify(outline, 0.25)


func _build_ns4a(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var lobby := _largest(Geometry2D.offset_polygon(ring, -1.0, Geometry2D.JOIN_MITER))
	var fascia := _largest(Geometry2D.offset_polygon(ring, 0.5, Geometry2D.JOIN_MITER))
	var body := _largest(Geometry2D.offset_polygon(ring, 0.3, Geometry2D.JOIN_MITER))
	var top := _largest(Geometry2D.offset_polygon(ring, -1.6, Geometry2D.JOIN_MITER))
	# The lobby: violet-lit glass behind the columns, the copper fascia and its soffit over it.
	_prism(lobby, g - 0.5, g + NS4A_LOBBY, NS4A_LOBBY_GLASS, Color(0, 0, 0, 0), M_PAVILION + 0.375)
	_prism(fascia, g + NS4A_LOBBY, g + NS4A_FASCIA, NS4A_COPPER, Color(0, 0, 0, 0), M_STONE)
	_soffit(fascia, g + NS4A_LOBBY, NS4A_COPPER.darkened(0.25))
	var cols := _ns4a_along(_largest(Geometry2D.offset_polygon(ring, -0.3, Geometry2D.JOIN_MITER)), 9.0)
	for c: Vector2 in cols:
		_prism(_circle(c, 0.32, 8), g - 0.3, g + NS4A_LOBBY, NS4A_FRAME.lightened(0.5), Color(0, 0, 0, 0), M_STONE)
	# Four storeys of glass, lit cool white floor to ceiling at night as in the photo (M_PAVILION +
	# 0.5, Varso's crown's tone), a dark frame band at every floor, the fins in front of the glass.
	_prism(body, g + NS4A_FASCIA, g + NS4A_GLASS_TOP, NS4A_GLASS, Color(0, 0, 0, 0), M_PAVILION + 0.5)
	for k in 4:
		var y := g + NS4A_FASCIA + k * NS4A_STOREY
		_band(ring, 0.6, y - 0.05, y + 0.42, NS4A_FRAME)
	var fins := _largest(Geometry2D.offset_polygon(ring, 0.42, Geometry2D.JOIN_MITER))
	_mode = M_LAMP
	for i in fins.size():
		var a := fins[i]
		var b := fins[(i + 1) % fins.size()]
		var length := a.distance_to(b)
		if length < 0.3:
			continue
		var e := (b - a) / length
		var o := _out(fins, a, b)
		var n := maxi(1, roundi(length / NS4A_FIN_STEP))
		for k in n:
			var c := a + e * length * (k + 0.5) / n
			var p0 := c - e * 0.15
			var p1 := c + e * 0.15
			_quad(Vector3(p0.x, g + NS4A_FASCIA, p0.y), Vector3(p1.x, g + NS4A_FASCIA, p1.y),
					Vector3(p1.x, g + NS4A_GLASS_TOP, p1.y), Vector3(p0.x, g + NS4A_GLASS_TOP, p0.y),
					Vector3(o.x, 0.0, o.y), NS4A_FIN)
	_mode = M_STONE
	# The flag-coloured band, the terrace round the top storey, its glass rail, the top storey.
	_band(ring, 0.6, g + NS4A_GLASS_TOP, g + NS4A_BAND_RED, NS4A_RED)
	var deck := _largest(Geometry2D.offset_polygon(ring, 0.6, Geometry2D.JOIN_MITER))
	_prism(deck, g + NS4A_BAND_RED, g + NS4A_BAND_TOP, NS4A_WHITE, Color("#b8bbbe"), M_STONE, M_STONE)
	_parapet(_largest(Geometry2D.offset_polygon(ring, 0.45, Geometry2D.JOIN_MITER)), g + NS4A_BAND_TOP, 1.0, NS4A_RAIL)
	_prism(top, g + NS4A_BAND_TOP, g + NS4A_TOP, NS4A_TOP_GLASS, NS4A_ROOF, M_GLASS, M_STONE)
	_parapet(top, g + NS4A_TOP, 0.5, NS4A_WHITE)
	# The roof: the white plant box and the flagpole near the rounded end (the long axis from it).
	var west := Vector2.ZERO
	var east := Vector2.ZERO
	for q in ring:
		if q.x < west.x or west == Vector2.ZERO:
			west = q
		if q.x > east.x or east == Vector2.ZERO:
			east = q
	_o = _centre(top)
	_a = (east - west).normalized()
	_b = Vector2(-_a.y, _a.x)
	var lw := _local(west)
	_lbox(lw.x + 16.0, 0.0, 5.0, 2.6, g + NS4A_TOP, g + NS4A_TOP + 3.2, NS4A_WHITE, M_STONE, Color("#dcdcd8"))
	var pole := _w(lw.x + 6.5, 0.0)
	var pole_top := g + NS4A_TOP + 11.0
	_beam(Vector3(pole.x, g + NS4A_TOP, pole.y), Vector3(pole.x, pole_top + 0.3, pole.y), 0.18, NS4A_WHITE)
	_ns4a_flag(Vector3(pole.x, pole_top, pole.y), Vector3(_a.x, 0.0, _a.y), 2.7, 1.7)
	_collide(lobby)
	# PGR on the white band's north face near the rounded corner (the photo's sign).
	var best := INF
	var at := Vector2.ZERO
	var face := Vector2.ZERO
	for i in deck.size():
		var a := deck[i]
		var b := deck[(i + 1) % deck.size()]
		var o := _out(deck, a, b)
		var mid := (a + b) * 0.5
		var d := mid.distance_to(west + _a * 9.0)
		if o.dot(-_b if _b.y > 0.0 else _b) > 0.8 and a.distance_to(b) > 2.0 and d < best:
			best = d
			at = mid
			face = o
	if best < 12.0:
		var k_s := 0.42
		signs.append(["PGR", Vector3(at.x, g + NS4A_BAND_RED + 0.06, at.y), Vector3(face.x, 0.0, face.y), k_s, NS4A_SIGN])


## Points every `step` m round a ring (the lobby's columns).
func _ns4a_along(ring: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var carry := step * 0.5
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		var t := carry
		while t < length:
			out.append(a.lerp(b, t / length))
			t += step
		carry = t - length
	return out


## The Polish flag on its pole, caught mid-wave: `top` the pole's top (the hoist's upper corner),
## `fly` the way it streams (level, unit), `w` × `h` m; six strips that swing in and out of the
## plane, white over red, both faces drawn.
func _ns4a_flag(top: Vector3, fly: Vector3, w: float, h: float) -> void:
	var side := Vector3.UP.cross(fly).normalized()
	var n := 6
	for k in n:
		var t0 := float(k) / n
		var t1 := float(k + 1) / n
		var s0 := side * sin(t0 * TAU * 1.1) * 0.28 * t0
		var s1 := side * sin(t1 * TAU * 1.1) * 0.28 * t1
		var d0 := Vector3.DOWN * 0.18 * t0 * t0
		var d1 := Vector3.DOWN * 0.18 * t1 * t1
		var a0 := top + fly * w * t0 + s0 + d0
		var a1 := top + fly * w * t1 + s1 + d1
		var nrm := (a1 - a0).cross(Vector3.UP).normalized()
		for half in 2:
			var col := NS4A_WHITE if half == 0 else NS4A_RED
			var y0 := -h * 0.5 * half
			var y1 := y0 - h * 0.5
			var p0 := a0 + Vector3.UP * y0
			var p1 := a1 + Vector3.UP * y0
			var p2 := a1 + Vector3.UP * y1
			var p3 := a0 + Vector3.UP * y1
			_quad(p0, p1, p2, p3, nrm, col)
			_quad(p1, p0, p3, p2, -nrm, col)


# --- The Bridge and Grzybowska 77 (F's photos, 2026-11-06) -----------------------------------

## The Bridge (Plac Europejski, by Towarowa; spec docs/landmarks/specs/bridge.md), rebuilt from
## F's nine photos (2026-11-06): a 174 m glass shaft whose faces fold along long diagonal seams
## into big triangular facets, each tilted a little so it catches the sky differently; the south
## end steps down to 149 m with a dark notched crown block (149-168 m) set in over it; the bank's
## blue name on the top of the long faces as a parody, ERZATZ; a 12 m glazed atrium lobby set
## back under the tower, its soffit timber, leaning concrete columns along the street faces.
## The tower's frame: u along the long west face from its north end to the south, v across to
## the east (metres from the west face's north corner).
const BR_O := Vector2(-2778.8, 80.8)
const BR_U := Vector2(0.2095, 0.9778)
const BR_TOP := 174.0      ## the north part's roof (OSM's 174 m)
const BR_STEP := 149.0     ## the south part's glass top (F's aerial: 25 m under the roof)
const BR_CROWN := 168.0    ## the dark crown block's top
const BR_CUT := 30.0       ## u of the step: the south 13 m of the tower is the low part
const BR_LOBBY := 12.0     ## the atrium's height; the facets start over it
const BR_GLASS := Color("#34506f")  # dark navy like its Rondo neighbours (F, 2026-11-17)
const BR_SEAM := Color("#1e252c")
const BR_DARK := Color("#24282c")
const BR_ROOF := Color("#646b70")
const BR_LOBBY_GLASS := Color("#9a8c76")  # warm: the timber slats behind the atrium's glass
const BR_TIMBER := Color("#b0824e")
const BR_CONCRETE := Color("#5e6266")
const BR_SIGN := Color(0.2, 0.55, 1.0)  # the bank's blue
## The folds, from F's aerial and the street photos: seams as polylines in (s, t), s along a face
## from its north (or west) end, t up the tower's 174 m. They start and end beyond a face's edge
## or on another seam, so each splits the face into whole facets.
const BR_FOLDS_LONG := [
	[Vector2(0.07, 1.03), Vector2(0.25, 0.51), Vector2(0.28, -0.03)],
	[Vector2(0.72, 0.88), Vector2(0.48, 0.48), Vector2(0.29, 0.02)],
	[Vector2(0.48, 0.50), Vector2(0.48, 0.09)],
	[Vector2(0.26, 0.04), Vector2(0.70, 0.18), Vector2(1.03, 0.18)],
	[Vector2(0.86, 0.47), Vector2(1.03, 0.22)],
]
const BR_FOLDS_SHORT := [
	[Vector2(0.12, 1.03), Vector2(0.88, 0.32), Vector2(1.03, 0.26)],
	[Vector2(-0.03, 0.40), Vector2(0.55, 0.12), Vector2(0.60, -0.03)],
]
## The facets' shading: a colour step and a turn of the normal (degrees about the vertical).
const BR_SHADE := [[0.0, 0.0], [0.13, 11.0], [-0.11, -9.0], [0.07, 15.0], [-0.06, -13.0]]


func _find_bridge() -> void:
	var outline := _landmark("The Bridge")
	if outline.size() >= 3:
		_add_site("bridge", [outline])
		if not sites.is_empty() and sites[-1]["key"] == "bridge":
			sites[-1]["raw"] = outline
	var g77 := _landmark("Bellona")
	if g77.size() >= 3:
		_add_site("grzybowska77", [g77])
		if not sites.is_empty() and sites[-1]["key"] == "grzybowska77":
			sites[-1]["raw"] = g77


func _br_u(p: Vector2) -> float:
	return (p - BR_O).dot(BR_U)


func _build_bridge(site: Dictionary) -> void:
	var raw: PackedVector2Array = site["raw"]
	var ring := _simplify(raw, 1.6)
	_g = _ground_under(raw)
	var g := _g
	var v := Vector2(BR_U.y, -BR_U.x)
	var big := 200.0
	var north_half := PackedVector2Array([BR_O - BR_U * big - v * big, BR_O + BR_U * BR_CUT - v * big,
			BR_O + BR_U * BR_CUT + v * big, BR_O - BR_U * big + v * big])
	var south_half := PackedVector2Array([BR_O + BR_U * BR_CUT - v * big, BR_O + BR_U * big - v * big,
			BR_O + BR_U * big + v * big, BR_O + BR_U * BR_CUT + v * big])
	var north := _largest(Geometry2D.intersect_polygons(ring, north_half))
	var south := _largest(Geometry2D.intersect_polygons(ring, south_half))
	var longest := 0.0
	for i in ring.size():
		longest = maxf(longest, ring[i].distance_to(ring[(i + 1) % ring.size()]))
	# The shaft: every face of the outline, faceted along its folds.
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var l := a.distance_to(b)
		if l < 0.5:
			continue
		var folds: Array = []
		if l >= longest * 0.6:
			folds = BR_FOLDS_LONG
		elif l >= 12.0:
			folds = BR_FOLDS_SHORT
		_br_face(ring, a, b, g, folds)
	# The step's inner face: the north part's glass from the low part's top to the roof.
	_mode = M_SKIN + float(S_FINS) / 16.0
	for i in north.size():
		var a := north[i]
		var b := north[(i + 1) % north.size()]
		if absf(_br_u(a) - BR_CUT) < 0.05 and absf(_br_u(b) - BR_CUT) < 0.05:
			_wall(a, b, g + BR_STEP, g + BR_TOP, _out(north, a, b), BR_GLASS)
	# Roofs: the north part's flat top with a plant box; the low part's ledge and its dark crown.
	_mode = M_STONE
	_cap(north, g + BR_TOP, BR_ROOF)
	_no_roof = true
	_prism(_square(_centre(north), 3.0), g + BR_TOP, g + BR_TOP + 3.0, BR_ROOF.darkened(0.15), BR_ROOF, M_STONE, M_STONE)
	_no_roof = false
	if south.size() >= 3:
		_cap(south, g + BR_STEP, BR_ROOF)
		var box := _largest(Geometry2D.offset_polygon(south, -0.9))
		if box.size() >= 3:
			_prism(box, g + BR_STEP, g + BR_CROWN, BR_DARK, BR_DARK.lightened(0.1), M_SKIN + float(S_DARK) / 16.0, M_STONE)
	_br_lobby(ring, g)
	_br_sign(north, g)
	_aviation(north, func(_q: Vector2) -> float: return g + BR_TOP)
	_collide(raw)
	pocket_rings.append(raw)


## One face a→b of the shaft, from the lobby's top to its roof (the step where it crosses BR_CUT),
## split along `folds` into facets, each a shade lighter or darker and turned a few degrees; dark
## seams over the folds.
func _br_face(ring: PackedVector2Array, a: Vector2, b: Vector2, g: float, folds: Array) -> void:
	var l := a.distance_to(b)
	var e := (b - a) / l
	var out := _out(ring, a, b)
	var ua := _br_u(a)
	var ub := _br_u(b)
	# s runs from the face's north end (smaller u); for a face across the tower (u nearly the
	# same at both ends), from its west end.
	var flip := ua > ub + 0.5 if absf(ua - ub) > 0.5 else (a.x > b.x)
	var top_at := func(x: float) -> float:
		var q := a + e * x
		return BR_TOP if _br_u(q) < BR_CUT else BR_STEP
	var y0 := BR_LOBBY
	var face := PackedVector2Array()
	face.append(Vector2(0.0, y0))
	face.append(Vector2(l, y0))
	var ta: float = top_at.call(0.02)
	var tb: float = top_at.call(l - 0.02)
	face.append(Vector2(l, tb))
	if absf(ta - tb) > 0.1:
		var xc := clampf((BR_CUT - ua) / (ub - ua) * l, 0.0, l)
		face.append(Vector2(xc, tb))
		face.append(Vector2(xc, ta))
	face.append(Vector2(0.0, ta))
	var pieces: Array = [face]
	var face_cw := Geometry2D.is_polygon_clockwise(face)
	var seams: Array = []
	for f: Array in folds:
		var pts: Array[Vector2] = []
		for q: Vector2 in f:
			var x := (1.0 - q.x) * l if flip else q.x * l
			pts.append(Vector2(x, q.y * BR_TOP))
		seams.append(pts)
		for k in range(pts.size() - 1):
			var p0: Vector2 = pts[k]
			var p1: Vector2 = pts[k + 1]
			var d := (p1 - p0).normalized()
			var nn := Vector2(-d.y, d.x) * 0.04
			p0 -= d * 0.3
			p1 += d * 0.3
			var strip := PackedVector2Array([p0 - nn, p1 - nn, p1 + nn, p0 + nn])
			var next: Array = []
			for pc: PackedVector2Array in pieces:
				# A seam ending inside a facet cuts a hole (the other winding): not a facet.
				for r in Geometry2D.clip_polygons(pc, strip):
					if r.size() >= 3 and Geometry2D.is_polygon_clockwise(r) == face_cw:
						next.append(r)
			pieces = next
	var keep := _mode
	_mode = M_SKIN + float(S_FINS) / 16.0
	var nv := Vector3(out.x, 0.0, out.y)
	for pc: PackedVector2Array in pieces:
		var c := _centre(pc)
		var hsh := fposmod(sin(c.x * 0.731 + c.y * 0.173 + a.x * 0.01) * 43758.5453, 1.0)
		var sh: Array = BR_SHADE[int(hsh * BR_SHADE.size()) % BR_SHADE.size()] if folds.size() > 0 else BR_SHADE[0]
		var col := BR_GLASS.lightened(float(sh[0])) if float(sh[0]) >= 0.0 else BR_GLASS.darkened(-float(sh[0]))
		var n := nv.rotated(Vector3.UP, deg_to_rad(float(sh[1])))
		var idx := Geometry2D.triangulate_polygon(pc)
		for t in range(0, idx.size() - 2, 3):
			var q0 := pc[idx[t]]
			var q1 := pc[idx[t + 1]]
			var q2 := pc[idx[t + 2]]
			var w0 := a + e * q0.x
			var w1 := a + e * q1.x
			var w2 := a + e * q2.x
			var top := maxf(ta, tb)
			_tri(Vector3(w0.x, g + q0.y, w0.y), Vector3(w1.x, g + q1.y, w1.y), Vector3(w2.x, g + q2.y, w2.y), n, col,
					Vector2(q0.x, q0.y), Vector2(q1.x, q1.y), Vector2(q2.x, q2.y), top)
	# The seams: dark mullion-thick lines 0.1 to 0.35 m proud, clipped to the face's top.
	_mode = M_STONE
	for si in seams.size():
		var pts: Array = seams[si]
		# Each seam, and each leg of one, a little prouder than the last: where two meet their beams
		# never share a plane.
		for k in range(pts.size() - 1):
			var proud := 0.1 + 0.05 * si + 0.025 * k
			var p0: Vector2 = pts[k]
			var p1: Vector2 = pts[k + 1]
			var lim0: float = top_at.call(clampf(p0.x, 0.02, l - 0.02))
			var lim1: float = top_at.call(clampf(p1.x, 0.02, l - 0.02))
			p0 = Vector2(clampf(p0.x, 0.0, l), clampf(p0.y, y0, lim0))
			p1 = Vector2(clampf(p1.x, 0.0, l), clampf(p1.y, y0, lim1))
			if p0.distance_to(p1) < 0.5:
				continue
			var w0 := a + e * p0.x + out * proud
			var w1 := a + e * p1.x + out * proud
			_beam(Vector3(w0.x, g + p0.y, w0.y), Vector3(w1.x, g + p1.y, w1.y), 0.5, BR_SEAM, false)
	_mode = keep


## The atrium: warm glass set 1.6 m back under the tower (the timber slats show through), the
## timber soffit, and leaning concrete columns in V pairs every 9 m along the faces.
func _br_lobby(ring: PackedVector2Array, g: float) -> void:
	var inner := _largest(Geometry2D.offset_polygon(ring, -1.6))
	if inner.size() < 3:
		return
	_prism(inner, g - 0.4, g + BR_LOBBY, BR_LOBBY_GLASS, Color(0, 0, 0, 0), M_PAVILION)
	_soffit(ring, g + BR_LOBBY, BR_TIMBER)
	var keep := _mode
	_mode = M_STONE
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var l := a.distance_to(b)
		if l < 10.0:
			continue
		var e := (b - a) / l
		var o := _out(ring, a, b)
		var n := floori(l / 9.0)
		var pad := (l - (n - 1) * 9.0) * 0.5
		for k in n:
			var p := a + e * (pad + 9.0 * k) - o * 0.8
			var lean := e * (2.2 if k % 2 == 0 else -2.2)
			_beam(Vector3(p.x - lean.x, g - 0.2, p.y - lean.y), Vector3(p.x + lean.x, g + BR_LOBBY, p.y + lean.y), 0.8, BR_CONCRETE)
	_mode = keep


## ERZATZ, the bank's parody (the tower's new tenant, F 2026-11-06), in blue at the top of the two long faces of the north part
## (F's aerial: high on the long face, over the north end), 4 m under the roof.
func _br_sign(north: PackedVector2Array, g: float) -> void:
	var v := Vector2(BR_U.y, -BR_U.x)
	for i in north.size():
		var a := north[i]
		var b := north[(i + 1) % north.size()]
		var l := a.distance_to(b)
		var o := _out(north, a, b)
		if l < 20.0 or absf(o.dot(v)) < 0.8:
			continue
		var mid := (a + b) * 0.5 + o * 0.15
		var k := 0.62 * l / Neon.length_of(BR_WORD)
		var base_y := g + BR_TOP - 4.0 - Neon.ROW_H * Neon.PIXEL * k
		signs.append([BR_WORD, Vector3(mid.x, base_y, mid.y), Vector3(o.x, 0.0, o.y), k, BR_SIGN])


const BR_WORD := "ERZATZ"


## Grzybowska 77 (spec docs/landmarks/specs/bridge.md, part 2), from F's photos: a post-war office
## block in warm tan brick over a pale stone ground floor of square piers (dark glazing and brown
## spandrels between them), a stone band with a long balcony and a black rail over the street,
## four storeys of windows in stone frames, a stone cornice, a set-back pale attic storey and roof
## plant. The wall it shares with The Bridge has no windows.
const G77_GROUND := 5.6
const G77_FLOOR := 3.35
const G77_TOP := 19.4      ## the cornice (G77_GROUND + 4 storeys)
const G77_ATTIC := 3.0
const G77_BRICK := Color("#b08a6a")
const G77_STONE := Color("#d9d2c3")
const G77_PANE := Color("#4a5560")
const G77_SPANDREL := Color("#7a5038")
const G77_ROOF := Color("#8f9396")
const G77_RAIL := Color("#25282a")
const G77_BAY := 3.3


func _build_bellona(site: Dictionary) -> void:
	var raw: PackedVector2Array = site["raw"]
	var ring := _simplify(raw, 0.8)
	_g = _ground_under(raw)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	var tower := _landmark("The Bridge")
	var shared := PackedVector2Array()
	if tower.size() >= 3:
		shared = _largest(Geometry2D.offset_polygon(tower, 1.5))
	# Windows and piers first (proud of the walls), then the walls.
	_g77_ground(ring, g, shared)
	for k in 4:
		var y0 := G77_GROUND + 0.6 + G77_FLOOR * k + 0.85
		_g77_windows(ring, g, y0, y0 + 1.85, shared)
	_prism(ring, g - 0.4, g + G77_GROUND, G77_STONE.darkened(0.25), none, M_STONE)
	_prism(ring, g + G77_GROUND, g + G77_GROUND + 0.6, G77_STONE, none, M_STONE)
	_prism(ring, g + G77_GROUND + 0.6, g + G77_TOP, G77_BRICK, none, M_STONE)
	var cornice := _largest(Geometry2D.offset_polygon(ring, 0.35, Geometry2D.JOIN_MITER))
	_prism(cornice, g + G77_TOP, g + G77_TOP + 0.7, G77_STONE, G77_ROOF, M_STONE, M_STONE)
	_g77_balcony(ring, g, shared)
	# The attic, 2 m back, pale, a row of small windows; roof plant on it.
	var attic := _largest(Geometry2D.offset_polygon(ring, -2.0))
	if attic.size() >= 3:
		var ay := G77_TOP + 0.7
		_g77_windows(attic, g, ay + 0.8, ay + 2.2, PackedVector2Array())
		_prism(attic, g + ay, g + ay + G77_ATTIC, G77_STONE.darkened(0.05), G77_ROOF, M_STONE, M_STONE)
		_parapet(ring, g + ay, 0.9, G77_STONE)
		var c := _centre(attic)
		_no_roof = true
		for d: Vector2 in [Vector2(-6.0, 3.0), Vector2(5.0, -4.0)]:
			_prism(_square(c + d, 1.8), g + ay + G77_ATTIC, g + ay + G77_ATTIC + 1.6, G77_ROOF.darkened(0.2), G77_ROOF, M_STONE, M_STONE)
		_no_roof = false
	_collide(raw)
	pocket_rings.append(raw)


## Stone-framed windows on every face not shared with the tower: a pale frame 0.04 m proud, the
## pane (curtain-wall glass, lit at night) 0.08 m proud, one per bay.
func _g77_windows(ring: PackedVector2Array, g: float, y0: float, y1: float, shared: PackedVector2Array) -> void:
	var keep := _mode
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var l := a.distance_to(b)
		var n := floori((l - 1.0) / G77_BAY)
		if n < 1:
			continue
		var e := (b - a) / l
		var o := _out(ring, a, b)
		var pad := (l - n * G77_BAY) * 0.5 + G77_BAY * 0.5
		for k in n:
			var p := a + e * (pad + k * G77_BAY)
			if shared.size() >= 3 and Geometry2D.is_point_in_polygon(p, shared):
				continue
			_mode = M_STONE
			_wall(p - e * 0.95 + o * 0.04, p + e * 0.95 + o * 0.04, g + y0 - 0.25, g + y1 + 0.25, o, G77_STONE)
			_mode = M_GLASS
			_wall(p - e * 0.7 + o * 0.08, p + e * 0.7 + o * 0.08, g + y0, g + y1, o, G77_PANE)
	_mode = keep


## The ground floor: square stone piers 0.9 m wide, 0.4 m proud, one per bay; between them dark
## glazing over a brown spandrel.
func _g77_ground(ring: PackedVector2Array, g: float, shared: PackedVector2Array) -> void:
	var keep := _mode
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var l := a.distance_to(b)
		var n := floori(l / G77_BAY)
		if n < 1:
			continue
		var e := (b - a) / l
		var o := _out(ring, a, b)
		var pad := (l - n * G77_BAY) * 0.5
		for k in n + 1:
			var p := a + e * (pad + k * G77_BAY)
			if shared.size() >= 3 and Geometry2D.is_point_in_polygon(p, shared):
				continue
			var pier := PackedVector2Array([p - e * 0.45, p + e * 0.45, p + e * 0.45 + o * 0.4, p - e * 0.45 + o * 0.4])
			_prism(pier, g - 0.4, g + G77_GROUND, G77_STONE, G77_STONE, M_STONE, M_STONE)
			if k < n:
				var m := p + e * G77_BAY * 0.5 + o * 0.06
				_mode = M_STONE
				_wall(m - e * 1.15, m + e * 1.15, g + 0.6, g + 1.5, o, G77_SPANDREL)
				_mode = M_GLASS
				_wall(m - e * 1.15, m + e * 1.15, g + 1.5, g + G77_GROUND - 0.4, o, G77_PANE)
	_mode = keep


## The long balcony over the ground floor on the street face (F's photo from Towarowa): a stone
## slab 1.1 m deep along the longest face, a black rail on its edge.
func _g77_balcony(ring: PackedVector2Array, g: float, shared: PackedVector2Array) -> void:
	var best := -1
	var longest := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var mid := (a + b) * 0.5
		if shared.size() >= 3 and Geometry2D.is_point_in_polygon(mid, shared):
			continue
		if a.distance_to(b) > longest:
			longest = a.distance_to(b)
			best = i
	if best < 0:
		return
	var a := ring[best]
	var b := ring[(best + 1) % ring.size()]
	var e := (b - a) / longest
	var o := _out(ring, a, b)
	var p0 := a + e * 0.6
	var p1 := b - e * 0.6
	var y := g + G77_GROUND + 0.6
	_prism(PackedVector2Array([p0, p1, p1 + o * 1.1, p0 + o * 1.1]), y - 0.25, y, G77_STONE, G77_STONE, M_STONE, M_STONE)
	var r0 := p0 + o * 1.05
	var r1 := p1 + o * 1.05
	_beam(Vector3(r0.x, y + 1.0, r0.y), Vector3(r1.x, y + 1.0, r1.y), 0.08, G77_RAIL, false)
	var steps := floori(longest / 1.6)
	for k in steps + 1:
		var p := p0.lerp(p1, float(k) / float(steps)) + o * 1.05
		_beam(Vector3(p.x, y, p.y), Vector3(p.x, y + 1.0, p.y), 0.05, G77_RAIL, false)


# --- Plac Piłsudskiego, part 2 (2026-10-31) ---------------------------------------------------

## Hotel Metropol, Marszałkowska 99a (F's four photos, 2026-11-07: "rebuild this metropol"). Before: the
## map's plain extrusion with the parody name METROPOLKA floating on an edge's middle. Now: the mapped
## parts rebuilt whole. The slab's long faces take the S_SLAB loggia skin in cream (a balustrade and a dark
## recess on every floor, as in the photos), the ends and the courtyard wings stay plain plaster; the ground
## floor on the street side is dark glazing under a cream canopy with a lit strip; the roof structures stay
## the map's; and the name stands on the roof over the east face as a white light box with green letters
## (the parody METROPOLKA), facing Marszałkowska. A site with no card, so it is not on the picking grid.
const MP_WALL := Color("#d9cfb9")
const MP_END := Color("#c9bfa9")
const MP_ROOF := Color("#7b7a76")
const MP_PLANT := Color("#a9a8a2")
const MP_GLASS := Color("#2f3a42")
const MP_CREAM := Color("#e6dfcf")
## The light box: M_LAMP glows its colour x2.4 at night, so a light grey reads as a lit white panel
## without blooming over the green letters (#f2f2ee blew out and the letters went pale).
const MP_BOX := Color("#a8aca6")
const MP_GREEN := Color(0.18, 1.0, 0.36)
## The street block (game/data/street_blocks, #495) that is this hotel: it stood in the same outline as a
## second model, and its triangles (a white frame round a dark green panel at the roof edge, among others)
## stood in front of the light box's lower half and over the letters, in both city paths (F, 2026-11-19:
## "fixed so many times, still wrong"). This site builds the hotel whole, so `_find_blocks` skips it.
const MP_BLOCK := "28759009"
## How far the light box's bottom stands over the main roof (clear of the 2 m roof structures).
const MP_SIGN_LIFT := 2.4


func _build_metropol_sign(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	var g := _ground_under(outline)
	_g = g
	var hull: PackedVector2Array = site["hull"]
	var parts := _parts_in(hull, func(_b: Dictionary) -> bool: return true)
	var skin := M_SKIN + float(S_SLAB) / 16.0
	var main_top := 0.0
	var main: PackedVector2Array
	var main_area := 0.0
	for bld in parts:
		var ring := _simplify(_pts(bld["p"]), 0.4)
		if ring.size() < 3:
			continue
		var h := float(bld["h"])
		var mh := float(bld["mh"])
		if mh >= 20.0:
			# A roof structure (lift and plant rooms): plain, from the main roof up.
			_prism(ring, g + mh, g + h, MP_PLANT, MP_ROOF, M_STONE, M_STONE)
			continue
		if h < 12.0:
			if mh < 0.5 and str(bld.get("c", "")).to_upper() == "#5D6768":
				# The ground floor the slab stands on (mapped 3.5 m, dark): glazing.
				_prism(ring, g - 0.4, g + h, MP_GLASS, MP_ROOF, M_GLASS, M_STONE)
			else:
				_prism(ring, g - 0.4, g + h, MP_END, MP_ROOF, M_STONE, M_STONE)
			continue
		var y0 := g + mh if mh > 0.5 else g - 0.4
		var area := absf(_area(ring))
		if area > main_area:
			main_area = area
			main = ring
			main_top = h
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			var long_face := a.distance_to(b) >= 7.0
			_mode = skin if long_face else M_STONE
			_wall(a, b, y0, g + h, _out(ring, a, b), MP_WALL if long_face else MP_END)
		_mode = M_STONE
		_cap(ring, g + h, MP_ROOF)
	_mode = M_STONE
	if main.size() < 3:
		return
	var top := g + main_top
	# The street side: dark glazing and a canopy with a lit strip along the main block's outermost
	# long faces (the ones on the street line, not the courtyard's), and the name over the middle one.
	# The street line: the mapped outline's longest edge (Marszałkowska's side).
	var ref_i := 0
	var ref_len := 0.0
	for i in outline.size():
		var l := outline[i].distance_to(outline[(i + 1) % outline.size()])
		if l > ref_len:
			ref_len = l
			ref_i = i
	var ref_out := _out(outline, outline[ref_i], outline[(ref_i + 1) % outline.size()])
	var max_proj := -INF
	for i in main.size():
		var a := main[i]
		var b := main[(i + 1) % main.size()]
		if _out(main, a, b).dot(ref_out) > 0.9 and a.distance_to(b) >= 8.0:
			max_proj = maxf(max_proj, ((a + b) * 0.5).dot(ref_out))
	var faces: Array[int] = []
	for i in main.size():
		var a := main[i]
		var b := main[(i + 1) % main.size()]
		var o := _out(main, a, b)
		var el := a.distance_to(b)
		if el < 8.0 or o.dot(ref_out) < 0.9 or ((a + b) * 0.5).dot(ref_out) < max_proj - 3.0:
			continue
		faces.append(i)
		_mode = M_GLASS
		_wall(a + o * 0.12, b + o * 0.12, g, g + 4.5, o, MP_GLASS)
		_mode = M_STONE
		var d := (b - a) / el
		var slab := PackedVector2Array([a, b, b + o * 1.8, a + o * 1.8])
		if Geometry2D.is_polygon_clockwise(slab) != Geometry2D.is_polygon_clockwise(main):
			slab.reverse()
		_prism(slab, g + 4.5, g + 4.85, MP_CREAM, MP_CREAM, M_STONE, M_STONE)
		var strip := PackedVector2Array([a + o * 0.2, b + o * 0.2, b + o * 0.3, a + o * 0.3])
		if Geometry2D.is_polygon_clockwise(strip) != Geometry2D.is_polygon_clockwise(main):
			strip.reverse()
		_prism(strip, g + 4.3, g + 4.5, Color("#fff1d0"), Color("#fff1d0"), M_LAMP, M_LAMP)
	# The name: a white light box on the roof edge over the middle street face, green letters.
	if not faces.is_empty():
		var mi := faces[faces.size() / 2]
		var e0 := main[mi]
		var e1 := main[(mi + 1) % main.size()]
		var out := _out(main, e0, e1)
		_b = out
		_a = Vector2(-out.y, out.x)
		_o = (e0 + e1) * 0.5
		var width := minf(e0.distance_to(e1) + 4.0, 20.0)
		var k := (width - 1.5) / Neon.length_of("METROPOLKA")
		var th := Neon.ROW_H * Neon.PIXEL * k
		var board_h := th * 1.5
		# On two posts over the roof structures (up to 2 m above the main roof) and flush with the face.
		# The box is a light box (M_LAMP): white by day, lit from inside at night, so the green
		# letters stand on a white panel as in F's photos and never float on the dark (2026-11-19:
		# in M_STONE it went as dark as the roof at night and only the letters showed).
		var base := top + MP_SIGN_LIFT
		_lbox(0.0, 0.2, width * 0.5, 0.25, base, base + board_h, MP_BOX, M_LAMP, Color("#e6e6e0"))
		for pu: float in [-width * 0.35, width * 0.35]:
			_lbox(pu, 0.0, 0.2, 0.2, top, base, MP_PLANT, M_STONE, MP_PLANT)
		# A landmark sign's point is the middle of the letters' BOTTOM edge (map_builder
		# _build_landmark_signs adds half their height and 0.4 m out): the letters' row (th tall)
		# sits in the box's middle, 0.03 m in front of its face (0.45 m out).
		var c := _w(0.0, 0.08)
		signs.append(["METROPOLKA", Vector3(c.x, base + (board_h - th) * 0.5, c.y), Vector3(out.x, 0.0, out.y), k, MP_GREEN])
	_collide(_simplify(outline, 0.3))
	_mode = M_STONE


## LORETKA's summer terrace (F, 2026-11-01; the real rooftop bar's: a deck, greenery, low
## seats, cocktails, pink neon). Colours: the deck's wood, the planters and their shrubs, the
## poufs, the tables, the parasols, the bar's counter and its pink strip, the lift's housing,
## the string lights' poles and bulbs.
const LOR_DECK := Color("#8a6a4c")
const LOR_PLANTER := Color("#3d3b38")
const LOR_GREEN := Color("#4f7a3a")
const LOR_POUF := Color("#e9dccb")
const LOR_TABLE := Color("#f2efe8")
const LOR_PARASOL := Color("#ff9fd6")
const LOR_COUNTER := Color("#2b2a2c")
const LOR_STRIP := Color("#ff6fc0")
const LOR_HOUSING := Color("#e6e1d6")
const LOR_POLE := Color("#202022")
const LOR_BULB := Color("#ffd08a")


## LORETKA in bubblegum pink on HOTEL PIURE's roof (the rooftop bar's neon), on its long fronts,
## and (F, 2026-11-01) its summer terrace on the roof: a wooden deck, planters of shrubs on its
## three open edges, eight low tables with a pouf each side, four pink parasols, the bar's
## counter with a pink strip, the lift's housing behind it, and string lights on six poles. Out
## of the roof grid (the crowd stands on the hotel's roof height, not the poufs).
func _build_loretka(_site: Dictionary) -> void:
	var outline := _landmark(LOR_NAME)
	var g := _ground_under(outline)
	var top := 0.0
	for bld in _parts_in(outline, func(_b: Dictionary) -> bool: return true):
		top = maxf(top, float(bld["h"]))
	if top < 15.0:
		return
	_crown_signs(outline, g + top + 2.2, "LORETKA", Color(1.0, 0.45, 0.78), 0.0, 0.45)
	var plan := loretka_plan(data)
	if plan.is_empty():
		return
	_o = plan["o"]
	_a = plan["a"]
	_b = plan["b"]
	var y := g + float(plan["h"])
	var u0: float = plan["u0"]
	var u1: float = plan["u1"]
	var v0: float = plan["v0"]
	var v1: float = plan["v1"]
	var none := Color(0, 0, 0, 0)
	var keep_roof := _no_roof
	_no_roof = true
	var d := y + 0.12  # the deck's top
	_lbox((u0 + u1) * 0.5, (v0 + v1) * 0.5, (u1 - u0) * 0.5, (v1 - v0) * 0.5, y, d, LOR_DECK.darkened(0.2), M_STONE, LOR_DECK)
	# Planters on the deck's open edges (the front, the back, the west end), shrubs on top.
	var runs := [[u0 + 0.45, v0 + 0.4, u1 - 2.2, v0 + 0.4], [u0 + 0.45, v1 - 0.4, u1 - 2.2, v1 - 0.4],
			[u0 + 0.4, v0 + 1.4, u0 + 0.4, v1 - 1.4]]
	for r: Array in runs:
		var along_u := absf(float(r[2]) - float(r[0])) > 0.1
		var length := absf(float(r[2]) - float(r[0])) if along_u else absf(float(r[3]) - float(r[1]))
		var pieces := maxi(1, roundi(length / 6.0))
		var step := length / pieces
		for k in pieces:
			var cu := float(r[0]) + (step * (k + 0.5) if along_u else 0.0)
			var cv := float(r[1]) + (0.0 if along_u else step * (k + 0.5))
			var hu := step * 0.5 - 0.3 if along_u else 0.35
			var hv := 0.35 if along_u else step * 0.5 - 0.3
			_lbox(cu, cv, hu, hv, d, d + 0.55, LOR_PLANTER, M_STONE, LOR_PLANTER.darkened(0.2))
			_lbox(cu, cv, hu - 0.08, hv - 0.08, d + 0.55, d + 1.05, LOR_GREEN, M_STONE, LOR_GREEN.lightened(0.08))
	# The tables (a pedestal and a top) and their poufs.
	for t: Vector2 in plan["tables"]:
		_lbox(t.x, t.y, 0.1, 0.1, d, d + 0.42, LOR_POLE, M_STONE, none)
		_lbox(t.x, t.y, 0.38, 0.38, d + 0.42, d + 0.48, LOR_TABLE, M_STONE, LOR_TABLE)
		for side: float in [-1.0, 1.0]:
			_lbox(t.x + side * 0.8, t.y, 0.24, 0.24, d, d + 0.36, LOR_POUF.darkened(0.08), M_STONE, LOR_POUF)
	# Four parasols over the middle of each pair of tables: a pole and a low pink cone.
	var tabs: Array = plan["tables"]
	for k in range(0, tabs.size(), 2):
		var m: Vector2 = (tabs[k] + tabs[k + 1]) * 0.5
		var w := _w(m.x, m.y)
		_beam(Vector3(w.x, d, w.y), Vector3(w.x, d + 2.55, w.y), 0.07, LOR_POLE)
		_mode = M_STONE
		_frustum(_circle(w, 1.7, 8), d + 2.2, _circle(w, 0.12, 8), d + 2.6, LOR_PARASOL.darkened(0.1), LOR_PARASOL)
	# The bar: a counter across the deck's east end with a pink strip on its front, the lift's
	# housing behind it (white render, a dark door).
	var bu := u1 - 1.6
	_lbox(bu, (v0 + v1) * 0.5, 0.4, (v1 - v0) * 0.5 - 2.0, d, d + 1.05, LOR_COUNTER, M_STONE, LOR_COUNTER.lightened(0.15))
	_mode = M_LAMP
	_lbox(bu - 0.44, (v0 + v1) * 0.5, 0.04, (v1 - v0) * 0.5 - 2.3, d + 0.75, d + 0.9, LOR_STRIP, M_LAMP, LOR_STRIP)
	_mode = M_STONE
	_lbox(u1 + 2.0, (v0 + v1) * 0.5, 2.0, 2.4, y, y + 3.1, LOR_HOUSING, M_STONE, LOR_HOUSING.darkened(0.1))
	_lbox(u1 - 0.02, (v0 + v1) * 0.5, 0.04, 0.6, d, d + 2.2, LOR_COUNTER, M_STONE, none)
	# String lights: three poles each side, a wire zig-zagging across between them, warm bulbs.
	var ps: Array = []
	for k in 3:
		var u := lerpf(u0 + 1.2, u1 - 2.6, float(k) / 2.0)
		ps.append([_w(u, v0 + 1.0), _w(u, v1 - 1.0)])
	for pr: Array in ps:
		for q: Vector2 in pr:
			_beam(Vector3(q.x, d, q.y), Vector3(q.x, d + 3.0, q.y), 0.06, LOR_POLE)
	var wires: Array = []
	for k in 2:
		wires.append([ps[k][0], ps[k + 1][1]])
		wires.append([ps[k][1], ps[k + 1][0]])
	for wr: Array in wires:
		var p0: Vector2 = wr[0]
		var p1: Vector2 = wr[1]
		var a3 := Vector3(p0.x, d + 2.95, p0.y)
		var b3 := Vector3(p1.x, d + 2.95, p1.y)
		_beam(a3, b3, 0.025, LOR_POLE, false)
		for j in range(1, 6):
			var q := a3.lerp(b3, j / 6.0) + Vector3(0, -0.12, 0)
			_mode = M_LAMP
			_prism(PackedVector2Array([Vector2(q.x - 0.06, q.z - 0.06), Vector2(q.x + 0.06, q.z - 0.06),
					Vector2(q.x + 0.06, q.z + 0.06), Vector2(q.x - 0.06, q.z + 0.06)]), q.y - 0.06, q.y + 0.1,
					LOR_BULB, LOR_BULB, M_LAMP, M_LAMP)
	_mode = M_STONE
	_no_roof = keep_roof


## Level 26 (the parody of the real Level 27; F 2026-11-01, rebuilt from F's photos 2026-11-22,
## docs/landmarks/specs/level26.md), the club on the Atlas Tower, Al. Jerozolimskie 123A. Not on
## the crown's top as before: the terrace runs round the round club room (the crown drum, 112 to
## 116 m, the club's indoor part) on the main roof, out to the glass railing at the tower's edge
## and its round end. On it: a timber deck, the glass railing with an orange light strip at its
## foot, festoon strings from the drum's top to posts at the railing with orange paper lanterns
## hung under them, white deck chairs round white cube tables, birches in white planters, the DJ
## stage under an aluminium truss in the round end with its dance floor before it, the bar along
## the drum; the drum dressed in dark glass with a red light band and a white fascia, the
## red-and-white mast on its roof and the name LEVEL 26 in copper on the fascia. `level26_plan`
## is the one layout for the model and for crowds.gd (the loungers in the chairs, the DJ and the
## dancers). Everything is drawn with `_no_roof`: the roof grid stays the tower's own.
const L26_TOWER := "Atlas Tower"
const L26_REACH := 13.5          ## the terrace's reach out from the drum's wall (m)
const L26_DECK_T := 0.12         ## the deck's thickness over the mapped roof
## The tower's round end from the drum (OSM: the arc's centre north-north-west of the drum's):
## the terrace is that half of the main roof (the real one is about 450 m2, the aerial photo's
## white railing runs round the round end), the DJ stands in it; the roof's far half stays plant.
const L26_ROUND_END := Vector2(-0.46, -0.89)
const L26_BACK := 0.3            ## the terrace reaches this many drum radii past the drum's centre
const L26_DECK := Color("#6f5b4b")
const L26_DECK_TOP := Color("#7d6754")
const L26_GLASS := Color("#cfe2e6")
const L26_STEEL := Color("#c9ccd0")
const L26_GLOW := Color("#ff7a2e")    ## the railing's foot strip and the lanterns: orange at night
const L26_LANTERN := Color("#ff9446")
const L26_RED := Color("#ff4a32")     ## the drum's light band (red at night, copper by day)
const L26_WHITE := Color("#c4c8cb")   ## the fascia: a step under white, so it does not blaze at night
const L26_DRUM_GLASS := Color("#34485f")
const L26_CANVAS := Color("#f3f1ea")
const L26_WOOD := Color("#b08a5e")
const L26_BIRCH := Color("#e9e5dc")
const L26_LEAVES := Color("#8db35a")
const L26_COPPER := Color(1.0, 0.62, 0.32)


## The terrace's plan, from the map data (the tower's outline and parts, or the streamed index's
## `site_parts`): the drum's centre and radius, the heights over the ground (the roof, the drum's
## top), the deck polygon (the main roof's part round the drum, cut at L26_REACH from its wall),
## its outer edges (where the railing stands) and the layout. {} when the tower is not there.
static func level26_plan(data: Dictionary) -> Dictionary:
	var outline := PackedVector2Array()
	for l: Dictionary in data.get("landmarks", []):
		if str(l.get("name", "")) == L26_TOWER:
			outline = _l26_pts(l["p"])
	if outline.size() < 3:
		return {}
	var parts := plan_parts_of(data)
	var drum := PackedVector2Array()
	var drum_h := 0.0
	var best := 0.0
	var cands: Array = []
	for bld: Dictionary in parts:
		var q := _l26_pts(bld["p"])
		if q.size() < 3:
			continue
		var mid := Vector2.ZERO
		for p in q:
			mid += p
		mid /= float(q.size())
		if not Geometry2D.is_point_in_polygon(mid, outline):
			continue
		var a := absf(_l26_area(q))
		cands.append([q, float(bld.get("h", 0.0)), float(bld.get("mh", 0.0)), a])
		if float(bld.get("mh", 0.0)) >= 60.0 and float(bld.get("h", 0.0)) >= 60.0 and a > best:
			best = a
			drum = q
			drum_h = float(bld.get("h", 0.0))
	if drum.size() < 3 or best < 150.0:
		return {}
	# The main roof: the largest part under the drum's top that rises from low down; the walls:
	# the parts standing as high as the drum (the tower's east block), no deck against them.
	var roof := PackedVector2Array()
	var roof_h := 0.0
	best = 0.0
	var walls: Array = []
	for cd: Array in cands:
		if float(cd[2]) >= 60.0 or float(cd[3]) < 30.0:
			continue
		if float(cd[1]) >= drum_h - 0.5:
			walls.append(cd[0])
		elif float(cd[1]) >= drum_h - 12.0 and float(cd[3]) > best:
			best = float(cd[3])
			roof = cd[0]
			roof_h = float(cd[1])
	if roof.size() < 3:
		return {}
	var c := Vector2.ZERO
	for q in drum:
		c += q
	c /= float(drum.size())
	var r := 0.0  # the outermost point: the dressing goes round the drum, never into it
	for q in drum:
		r = maxf(r, q.distance_to(c))
	var deck := PackedVector2Array()
	var shrunk := Geometry2D.offset_polygon(roof, -0.35, Geometry2D.JOIN_MITER)
	var fwd := L26_ROUND_END.normalized()
	var across := Vector2(-fwd.y, fwd.x)
	var cut := c - fwd * (r * L26_BACK)
	var half := PackedVector2Array([cut - across * 80.0, cut + across * 80.0, cut + across * 80.0 + fwd * 80.0,
			cut - across * 80.0 + fwd * 80.0])
	for s: PackedVector2Array in shrunk:
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(s, _l26_circle(c, r + L26_REACH, 48)):
			for part: PackedVector2Array in Geometry2D.intersect_polygons(piece, half):
				if absf(_l26_area(part)) > absf(_l26_area(deck)):
					deck = part
	if absf(_l26_area(deck)) < 150.0:
		return {}
	# The railing's edges: not along the drum, not along the walls.
	var rail: Array = []
	for i in deck.size():
		var a := deck[i]
		var b := deck[(i + 1) % deck.size()]
		var mid := (a + b) * 0.5
		if mid.distance_to(c) < r + 1.0:
			continue
		var e := (b - a).normalized()
		var n := Vector2(-e.y, e.x)
		if Geometry2D.is_point_in_polygon(mid + n * 0.2, deck):
			n = -n
		var walled := false
		for w: PackedVector2Array in walls:
			if Geometry2D.is_point_in_polygon(mid + n * 0.8, w):
				walled = true
		if not walled:
			rail.append([a, b, n])
	# `outline` is the roof part's: the map stands every part on the lowest ground under itself
	# (map_builder), so the deck's height is its, not the tower outline's.
	return {"outline": roof, "tower": outline, "drum": drum, "centre": c, "r": r, "roof_h": roof_h, "drum_h": drum_h,
			"deck": deck, "rail": rail,
			"deck_h": roof_h + L26_DECK_T, "layout": level26_layout(c, r, deck, rail)}


## Where things stand on the deck (shared by the model and the crowd): the DJ in the deepest part
## (the round end) facing the drum, the dancers between the DJ and the drum facing the DJ, the bar
## along the drum on the far side, lounge groups (a cube table, three deck chairs facing it) round
## the rest, the birches and the string posts along the railing. Seats and dancers are [spot,
## facing].
static func level26_layout(c: Vector2, r: float, deck: PackedVector2Array, rail: Array) -> Dictionary:
	var clear := func(p: Vector2, rad: float) -> bool:
		if not Geometry2D.is_point_in_polygon(p, deck):
			return false
		for i in deck.size():
			var q := Geometry2D.get_closest_point_to_segment(p, deck[i], deck[(i + 1) % deck.size()])
			if q.distance_to(p) < rad:
				return false
		return true
	# How far out the deck goes in each direction (36 rays), from the drum's wall.
	var reach: Array[float] = []
	for k in 36:
		var d := Vector2.from_angle(TAU * float(k) / 36.0)
		var out := 0.0
		var seen := false
		for s in 64:
			var p := c + d * (r + 0.3 + 0.25 * float(s))
			if Geometry2D.is_point_in_polygon(p, deck):
				seen = true
				out = 0.3 + 0.25 * float(s)
			elif seen:
				break
		reach.append(out)
	var deep := posmod(int(roundf(L26_ROUND_END.angle() / TAU * 36.0)), 36)
	var dj_dir := Vector2.from_angle(TAU * float(deep) / 36.0)
	var dj := c + dj_dir * (r + maxf(reach[deep] - 2.4, 3.0))
	var dj_face := -dj_dir
	var side := Vector2(-dj_face.y, dj_face.x)
	var dancers: Array = []
	for row in 4:
		for col in 7:
			var p := dj + dj_face * (2.3 + 0.95 * float(row)) + side * (float(col) - 3.0) * 0.9 \
					+ side * (0.3 if row % 2 == 1 else 0.0)
			if p.distance_to(c) > r + 0.9 and clear.call(p, 0.45):
				dancers.append([p, (dj - p).normalized()])
	# The bar: on the side away from the DJ where the deck is at least 5 m deep.
	var bar_k := -1
	var far := -1.0
	for k in 36:
		var off := absf(angle_difference(TAU * float(k) / 36.0, TAU * float(deep) / 36.0))
		if reach[k] >= 5.0 and reach[(k + 1) % 36] >= 4.0 and reach[(k + 35) % 36] >= 4.0 and off > far:
			far = off
			bar_k = k
	var bar_t := TAU * float(bar_k) / 36.0 if bar_k >= 0 else TAU * float(deep) / 36.0 + PI
	var drinkers: Array = []
	for j in 7:
		var t := bar_t + (float(j) - 3.0) * 0.07
		var p := c + Vector2.from_angle(t) * (r + 2.9 + 0.35 * float(j % 2))
		if clear.call(p, 0.4):
			drinkers.append([p, (c - p).normalized()])
	# The lounge: groups on a 3.4 m grid turned to the round end, wherever one fits clear of the
	# edges, the drum, the dance floor and the bar (the day photo's deck chairs fill the deck).
	var groups: Array = []
	var seats: Array = []
	var bar_at := c + Vector2.from_angle(bar_t) * (r + 1.6)
	var gu := -dj_face
	var gv := Vector2(-gu.y, gu.x)
	for iu in range(-9, 10):
		for iv in range(-9, 10):
			var p := c + gu * (3.4 * float(iu)) + gv * (3.4 * float(iv) + (1.7 if iu % 2 != 0 else 0.0))
			if p.distance_to(c) < r + 2.2 or p.distance_to(dj) < 6.5 or p.distance_to(bar_at) < 3.5:
				continue
			if not clear.call(p, 1.25):
				continue
			var crowded := false
			for st: Array in dancers:
				if (st[0] as Vector2).distance_to(p) < 1.8:
					crowded = true
			if crowded:
				continue
			var t := (p - c).angle()
			groups.append([p, t])
			for k in 3:
				var a := t + PI + (float(k) - 1.0) * 1.15
				var q := p + Vector2.from_angle(a) * 1.0
				seats.append([q, (p - q).normalized()])
	# Along the railing: the string posts every 8 m, a birch half way between.
	var posts: Array = []
	var birches: Array = []
	var walked := 0.0
	var next := 2.0
	for e: Array in rail:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var n: Vector2 = e[2]
		var el := a.distance_to(b)
		while next <= walked + el:
			var p := a.lerp(b, (next - walked) / maxf(el, 0.001)) - n * 0.35
			if posts.size() % 2 == 0:
				posts.append(p)
			else:
				var bp: Vector2 = p - n * 0.6
				if bp.distance_to(dj) > 4.5 and clear.call(bp, 0.4):
					birches.append(bp)
				posts.append(p)
			next += 4.0
		walked += el
	var keep: Array = []
	for k in posts.size():
		if k % 2 == 0:
			keep.append(posts[k])
	return {"dj": dj, "dj_face": dj_face, "dancers": dancers + drinkers, "bar_t": bar_t, "groups": groups,
			"seats": seats, "posts": keep, "birches": birches}


## The building parts a club's plan reads: the whole map's, the streamed index's `site_parts`,
## or in the prebuilt game the few `plan_parts` tools/bake_city.gd keeps (`plan_parts`).
static func plan_parts_of(data: Dictionary) -> Array:
	for key: String in ["buildings", "site_parts", "plan_parts"]:
		var list: Array = data.get(key, [])
		if not list.is_empty():
			return list
	return []


## The parts standing in the rooftop clubs' towers (Level 26's Atlas Tower, THE WJU's Spektrum
## Tower), for the prebuilt index (tools/bake_city.gd drops `site_parts`).
static func plan_parts(data: Dictionary) -> Array:
	var boxes: Array[Rect2] = []
	for l: Dictionary in data.get("landmarks", []):
		if str(l.get("name", "")) in [L26_TOWER, "Spektrum Tower"]:
			var q := _l26_pts(l["p"])
			var box := Rect2(q[0], Vector2.ZERO)
			for p in q:
				box = box.expand(p)
			boxes.append(box.grow(2.0))
	var out: Array = []
	for bld: Dictionary in data.get("site_parts", data.get("buildings", [])):
		var flat: Array = bld["p"]
		if flat.size() < 6:
			continue
		var at := Vector2(float(flat[0]), float(flat[1]))
		for box in boxes:
			if box.has_point(at):
				out.append(bld)
				break
	return out


static func _l26_pts(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(float(flat[i]), float(flat[i + 1])))
	return out


static func _l26_area(q: PackedVector2Array) -> float:
	var a := 0.0
	for i in q.size():
		a += q[i].cross(q[(i + 1) % q.size()])
	return a * 0.5


static func _l26_circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		out.append(c + Vector2.from_angle(TAU * float(k) / float(n)) * r)
	return out


func _build_level26_club(_site: Dictionary) -> void:
	var plan := level26_plan(data)
	if plan.is_empty():
		return
	var g := _ground_under(plan["outline"])
	var gd := _ground_under(plan["drum"])
	var c: Vector2 = plan["centre"]
	var r: float = plan["r"]
	var deck: PackedVector2Array = plan["deck"]
	var y0 := g + float(plan["roof_h"])
	var y := g + float(plan["deck_h"])
	var top := gd + float(plan["drum_h"])
	var lay: Dictionary = plan["layout"]
	var keep_roof := _no_roof
	var keep := _mode
	_no_roof = true
	_mode = M_STONE
	# The deck: timber tiles on the mapped roof.
	_prism(deck, y0, y, L26_DECK, L26_DECK_TOP, M_STONE, M_STONE)
	# The drum: dark glass, the light band, the white fascia; the mast on its roof.
	var n := 36
	var ring := _circle(c, r + 0.12, n)
	var fas := _circle(c, r + 0.3, n)
	for k in n:
		var a := ring[k]
		var b := ring[(k + 1) % n]
		var out := ((a + b) * 0.5 - c).normalized()
		_mode = M_GLASS
		_wall(a, b, y, top - 1.3, out, L26_DRUM_GLASS, float(k) * a.distance_to(b))
		_mode = M_LAMP
		_wall(a, b, top - 1.3, top - 0.8, out, L26_RED)
	_prism(fas, top - 0.8, top + 1.0, L26_WHITE, Color(0, 0, 0, 0), M_STONE, M_STONE)
	var fas_in := _circle(c, r - 0.15, n)
	for k in n:
		var a := fas_in[k]
		var b := fas_in[(k + 1) % n]
		_wall(b, a, top - 0.1, top + 1.0, (c - (a + b) * 0.5).normalized(), Color("#3d4247"))
	_cap_holes(fas, [fas_in], top + 1.0, Color("#3d4247"))  # a dark coping: a pale top blazed at night
	_mode = M_STONE
	var mast := c + (c - (lay["dj"] as Vector2)).normalized() * (r * 0.35)
	for s in 8:
		var col := Color("#d8382c") if s % 2 == 0 else Color("#f2f2ef")
		_beam(Vector3(mast.x, top + 1.3 * s, mast.y), Vector3(mast.x, top + 1.3 * (s + 1), mast.y), 0.32 - 0.02 * s, col)
	_prism(_square(mast, 0.12), top + 10.4, top + 10.65, Color("#ff3020"), Color("#ff3020"), M_LAMP, M_LAMP)
	# The glass railing on the outer edges: posts every 2 m, glass both sides, a steel top rail,
	# the orange strip at its foot.
	for e: Array in plan["rail"]:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var o: Vector2 = e[2]
		var el := a.distance_to(b)
		if el < 0.05:
			continue
		var pa := a - o * 0.15
		var pb := b - o * 0.15
		_wall(pa, pb, y, y + 1.25, o, L26_GLASS)
		_wall(pb, pa, y, y + 1.25, -o, L26_GLASS.darkened(0.12))
		_mode = M_LAMP
		_wall(pa - o * 0.03, pb - o * 0.03, y, y + 0.14, -o, L26_GLOW)
		_wall(pa + o * 0.03, pb + o * 0.03, y, y + 0.14, o, L26_GLOW)
		_mode = M_STONE
		_beam(Vector3(pa.x, y + 1.28, pa.y), Vector3(pb.x, y + 1.28, pb.y), 0.07, L26_STEEL)
		var steps := maxi(int(el / 2.0), 1)
		for s in steps + 1:
			if s == steps and el < 0.6:
				break
			var p := pa.lerp(pb, float(s) / float(steps))
			_prism(_square(p, 0.045), y, y + 1.28, L26_STEEL, Color(0, 0, 0, 0), M_STONE)
	# The bar along the drum: a dark counter in an arc with a lit front, the lit shelves behind.
	var bar_t: float = lay["bar_t"]
	for j in 6:
		var t0 := bar_t + (float(j) - 3.0) * 0.075
		var t1 := t0 + 0.075
		var a := c + Vector2.from_angle(t0) * (r + 1.9)
		var b := c + Vector2.from_angle(t1) * (r + 1.9)
		var i0 := c + Vector2.from_angle(t0) * (r + 1.3)
		var i1 := c + Vector2.from_angle(t1) * (r + 1.3)
		_prism(PackedVector2Array([i0, a, b, i1]), y, y + 1.1, Color("#3a2b22"), Color("#e8e2d6"), M_STONE, M_STONE)
		var o := ((a + b) * 0.5 - c).normalized()
		_mode = M_LAMP
		_wall(a + o * 0.02, b + o * 0.02, y + 0.15, y + 0.3, o, L26_GLOW)
		var s0 := c + Vector2.from_angle(t0) * (r + 0.2)
		var s1 := c + Vector2.from_angle(t1) * (r + 0.2)
		_wall(s0, s1, y + 1.0, y + 2.3, o, Color("#ffb35c"))
		_mode = M_STONE
	# The DJ's stage in the round end: a low platform, the desk with its lit front, speakers on
	# stands, the aluminium truss over it with coloured heads.
	_o = lay["dj"]
	_a = lay["dj_face"]
	_b = Vector2(-_a.y, _a.x)
	_lbox(-0.3, 0.0, 1.5, 2.6, y, y + 0.3, Color("#232326"), M_STONE, Color("#2c2c30"))
	_lbox(0.4, 0.0, 0.35, 1.0, y + 0.3, y + 1.3, Color("#18181b"), M_STONE, Color("#2a2a2e"))
	_lbox(0.76, 0.0, 0.02, 0.9, y + 0.45, y + 1.15, L26_GLOW, M_LAMP)
	for v: float in [-2.3, 2.3]:
		_lbox(-1.4, v, 0.17, 0.17, y + 0.3, y + 4.2, L26_STEEL, M_STONE)
		_lbox(0.6, v, 0.17, 0.17, y + 0.3, y + 4.2, L26_STEEL, M_STONE)
		_lbox(-0.4, v, 1.17, 0.17, y + 4.2, y + 4.5, L26_STEEL, M_STONE)
		_lbox(0.9, v * 1.15, 0.3, 0.3, y + 0.3, y + 1.9, Color("#161618"), M_STONE)
	_lbox(-1.4, 0.0, 0.17, 2.47, y + 4.2, y + 4.5, L26_STEEL, M_STONE)
	_lbox(0.6, 0.0, 0.17, 2.47, y + 4.2, y + 4.5, L26_STEEL, M_STONE)
	var heads := [Color("#ff3fb4"), Color("#4fd8ff"), Color("#ffb04a"), Color("#a35cff"), Color("#ff3fb4")]
	for h in heads.size():
		_lbox(0.6, -1.8 + 0.9 * float(h), 0.14, 0.14, y + 3.85, y + 4.2, heads[h], M_LAMP)
	# The lounge: white deck chairs on wooden frames round white cube tables with a candle.
	for gr: Array in lay["groups"]:
		var p: Vector2 = gr[0]
		_prism(_square(p, 0.28), y, y + 0.48, L26_CANVAS, L26_CANVAS, M_STONE, M_STONE)
		_prism(_square(p, 0.06), y + 0.48, y + 0.6, Color("#ffd27a"), Color("#ffd27a"), M_LAMP, M_LAMP)
	for st: Array in lay["seats"]:
		_l26_deckchair(st[0], st[1], y)
	# Birches in white planters along the railing.
	var bk := 0
	for bp: Vector2 in lay["birches"]:
		_prism(_square(bp, 0.45), y, y + 0.8, Color("#f2f1ec"), Color("#4a3a2c"), M_STONE, M_STONE)
		var h := 3.3 + 0.35 * float(bk % 3)
		_beam(Vector3(bp.x, y + 0.75, bp.y), Vector3(bp.x + 0.1, y + h, bp.y + 0.05), 0.12, L26_BIRCH)
		_frustum(_circle(bp, 0.95, 7), y + 1.5, _circle(bp, 0.45, 7), y + h + 0.3, L26_LEAVES.darkened(0.05 * float(bk % 3)),
				L26_LEAVES.lightened(0.08))
		bk += 1
	# The festoon strings from the drum's fascia to posts at the railing, the lanterns under them.
	var lk := 0
	for pp: Vector2 in lay["posts"]:
		_prism(_square(pp, 0.05), y, y + 3.0, Color("#3a3b3e"), Color(0, 0, 0, 0), M_STONE)
		var d := (pp - c).normalized()
		var from := c + d * (r + 0.32)
		var p0 := Vector3(from.x, top - 0.5, from.y)
		var p1 := Vector3(pp.x, y + 3.0, pp.y)
		_pow_festoon(p0, p1, 0.5, 6)
		for t: float in [0.38, 0.68]:
			var at := p0.lerp(p1, t) - Vector3.UP * 0.5 * 4.0 * t * (1.0 - t)
			var drop := 0.5 + 0.35 * float(lk % 3)
			_beam(at, at - Vector3.UP * drop, 0.02, POW_DARK, false)
			var lc := Vector2(at.x, at.z)
			var ly := at.y - drop
			var rad := 0.28 + 0.06 * float(lk % 2)
			_prism(_circle(lc, rad, 6), ly - rad * 1.6, ly, L26_LANTERN, L26_LANTERN, M_LAMP, M_LAMP)
			_prism(_circle(lc, rad * 0.6, 6), ly - rad * 1.6 - 0.12, ly - rad * 1.6, L26_LANTERN, L26_LANTERN, M_LAMP, M_LAMP)
			lk += 1
	# The name in copper on the fascia, facing the deck's round end and the other way.
	var dj_dir := -(lay["dj_face"] as Vector2)
	for d: Vector2 in [dj_dir, -dj_dir]:
		var kk := 7.0 / Neon.length_of("LEVEL 26")
		var sy := top + 0.1 - Neon.ROW_H * Neon.PIXEL * kk * 0.5
		var at := c + d * (r + 0.36)
		signs.append(["LEVEL 26", Vector3(at.x, sy, at.y), Vector3(d.x, 0.0, d.y), kk, L26_COPPER])
	_mode = keep
	_no_roof = keep_roof


## A deck chair: a white canvas sling between two wooden side rails, the foot on the deck and the
## back raised, its sitter facing `face`.
func _l26_deckchair(p: Vector2, face: Vector2, y: float) -> void:
	var s := Vector2(-face.y, face.x) * 0.27
	var foot := p + face * 0.5
	var mid := p
	var back := p - face * 0.45
	var v := func(q: Vector2, h: float) -> Vector3:
		return Vector3(q.x, y + h, q.y)
	_two_sided(v.call(foot - s, 0.32), v.call(foot + s, 0.32), v.call(mid + s, 0.2), v.call(mid - s, 0.2), L26_CANVAS)
	_two_sided(v.call(mid - s, 0.2), v.call(mid + s, 0.2), v.call(back + s, 0.82), v.call(back - s, 0.82), L26_CANVAS)
	for side: float in [-1.0, 1.0]:
		var q := s * side * 1.12
		_beam(v.call(foot + face * 0.12 + q, 0.0), v.call(back - face * 0.08 + q, 0.88), 0.05, L26_WOOD)
		_beam(v.call(back - face * 0.35 + q, 0.0), v.call(mid + q, 0.36), 0.05, L26_WOOD)


## Plac Zbawiciela's colonnades (MDM, 1950s; F's photos 2026-11-13: the curved arcades round the
## roundabout with the cafés under them): OpenStreetMap maps each as a 7.6 m "roof" part, which the
## map drew as a solid block. Built instead: cream Tuscan columns about every 3 m along the side that
## faces the street (the side whose nearest road lies ahead of it), the roof slab over them and the
## green balustrade of the terrace on top; lanterns under the slab at night. The frontage round the
## square is MDM's already (`_find_mdm`'s skin).
const ZBP_CENTRE := Vector2(-411.2, 1566.0)  ## the roundabout's middle
const ZBP_REACH := 75.0                     ## colonnade parts within this of the middle
const ZBP_COLUMN := Color("#ece4d0")
const ZBP_TERRACE := Color("#cfc8b8")
const ZBP_RAIL := Color("#4f7a5f")          ## the terrace's green balustrade (F's rainy photo)
const ZBP_SLAB := 6.7                        ## the slab's underside; its top is the part's height
const ZBP_PITCH := 3.0


func _find_zbawiciela_plac() -> void:
	var parts: Array[PackedVector2Array] = []
	var zone: Array = []
	for bld in data["buildings"]:
		if str(bld.get("kind", "")) != "roof" or float(bld["h"]) > 10.0:
			continue
		var q := _pts(bld["p"])
		if q.size() < 4 or _centre(q).distance_to(ZBP_CENTRE) > ZBP_REACH:
			continue
		parts.append(q)
		zone.append(q)
		zone.append(Geometry2D.convex_hull(q))  # a curved strip's centre lies outside it
	if parts.is_empty():
		return
	_add_site("zbawiciela_plac", zone)
	if not sites.is_empty() and sites[-1]["key"] == "zbawiciela_plac":
		sites[-1]["parts"] = parts
		sites[-1]["h"] = 7.6


## The nearest point of a mapped road to p within `reach` (p itself when none).
func _zbp_road_near(p: Vector2, reach: float) -> Vector2:
	var best := p
	var best_d := reach
	for r in data.get("roads", []):
		var q := _pts(r["p"])
		for i in q.size() - 1:
			var a := q[i]
			var b := q[i + 1]
			if minf(a.x, b.x) > p.x + reach or maxf(a.x, b.x) < p.x - reach \
					or minf(a.y, b.y) > p.y + reach or maxf(a.y, b.y) < p.y - reach:
				continue
			var c := Geometry2D.get_closest_point_to_segment(p, a, b)
			var d := c.distance_to(p)
			if d < best_d:
				best_d = d
				best = c
	return best


func _build_zbawiciela_plac(site: Dictionary) -> void:
	var lamp := 0
	for q: PackedVector2Array in site["parts"]:
		var ring := _simplify(q, 0.25)
		if ring.size() < 3:
			continue
		_g = _ground_under(ring)
		var g := _g
		var top := g + float(site["h"])
		var ccw := _area(ring) > 0.0
		# the slab and the terrace's floor
		_prism(ring, g + ZBP_SLAB, top, ZBP_COLUMN, ZBP_TERRACE, M_STONE, M_STONE)
		_mode = M_STONE
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			var length := a.distance_to(b)
			if length < 1.2:
				continue
			var along := (b - a) / length
			var n := Vector2(along.y, -along.x) if ccw else Vector2(-along.y, along.x)  # outward
			var mid := (a + b) * 0.5
			# the open side faces the street: its nearest road lies ahead of the edge
			var road := _zbp_road_near(mid, 30.0)
			if road == mid:
				road = ZBP_CENTRE
			if n.dot((road - mid).normalized()) < 0.35:
				continue
			# the terrace's balustrade along the edge, just inside it
			var strip := PackedVector2Array([a, b, b - n * 0.2, a - n * 0.2])
			_prism(strip, top, top + 0.95, ZBP_RAIL, ZBP_RAIL.lightened(0.12), M_STONE, M_STONE)
			# columns at even steps, set in from the slab's edge
			var count := maxi(roundi(length / ZBP_PITCH), 1)
			for k in count:
				var p := a.lerp(b, (k + 0.5) / count) - n * 0.75
				_lbox_at(p, 0.62, g - 0.3, g + 0.45, ZBP_COLUMN.darkened(0.06))
				_prism(_circle(p, 0.4, 8), g + 0.45, g + ZBP_SLAB - 0.4, ZBP_COLUMN, Color(0, 0, 0, 0), M_STONE)
				_lbox_at(p, 0.62, g + ZBP_SLAB - 0.4, g + ZBP_SLAB, ZBP_COLUMN.lightened(0.04))
				_collide(_circle(p, 0.5, 4))
				lamp += 1
				if lamp % 2 == 0:  # a lantern under the slab between every other pair
					var l := p - n * 1.6
					_prism(_circle(l, 0.16, 4), g + ZBP_SLAB - 0.75, g + ZBP_SLAB, ZB_LAMP, ZB_LAMP, M_LAMP, M_LAMP)


# --- Pawilony (Nowy Świat 22/28, 2026-10-31) -------------------------------------------------

## The Pawilony: the maze of tiny one-storey bar pavilions behind the gate at Nowy Świat 22/28
## (docs/landmarks/specs/pawilony.md). OpenStreetMap maps them as two strips named "Pawilony za
## Nowym Światem"; each strip is cut along its length into pavilions 3.4-5.6 m wide and
## 2.7-3.6 m tall (seeded by position, the same every run), the 12 m west strip into two rows
## back to back. Each pavilion: its own patched colour, a flat tar roof with an eave over the
## front, a fascia, a dark door, a lit window or a closed shutter; a small neon word on most
## fronts, warm bulbs under the others' eaves; PAWILONY over the gate on Nowy Świat.
const PAW_OSM := "Pawilony za Nowym Światem"
const PAW_WALLS := ["#b84a3a", "#d9a441", "#3f6e8c", "#5d8a5a", "#e5ddcc", "#7a5a8c", "#c96f4a", "#4a4f55"]
## Roofs: tar paper, grey felt, rusty sheet, mossy felt, so from above the strip is a patchwork.
const PAW_ROOFS := ["#3b3a38", "#5f5d57", "#7a5f4c", "#4f5c50", "#6e6a64"]
const PAW_PLINTH := Color("#2c2c2c")
const PAW_DOOR := Color("#1f2124")
const PAW_SHUTTER := Color("#8e9196")
const PAW_GLASS := Color(1.0, 0.82, 0.55)
const PAW_BULB := Color(1.0, 0.86, 0.55)
const PAW_MIN_W := 3.4
const PAW_MAX_W := 5.6
const PAW_MIN_H := 2.7
const PAW_MAX_H := 3.6
const PAW_ROW := 8.0          # a strip wider than this is two rows back to back
const PAW_EAVE := 0.3
const PAW_WORDS := ["PIWO", "BAR", "SHOTY", "KLUB", "DISCO", "KARAOKE", "OTWARTE"]
const PAW_TUBES := [Color(1.0, 0.1, 0.55), Color(0.1, 0.9, 1.0), Color(0.62, 0.25, 1.0),
		Color(1.0, 0.72, 0.12), Color(0.2, 1.0, 0.45)]
const PAW_SIGN_K := 0.4       # a word's scale: 0.88 m tall (less on a narrow front)
## The gate: the tenement's front on Nowy Świat where the passage goes in (the footpath through
## it), its outward normal (west, to the street), the sign's height and scale.
const PAW_GATE := Vector2(-285.0, 111.5)
const PAW_GATE_OUT := Vector2(-0.94, 0.34)
const PAW_GATE_UP := 5.5   # over the ground floor's shop signs (the tenement has a KEBAB 24H)
const PAW_GATE_K := 0.55


func _find_pawilony() -> void:
	var strips: Array = []
	for l in data.get("landmarks", []):
		if l["name"] == PAW_OSM:
			var q := _pts(l["p"])
			if q.size() >= 3:
				strips.append(q)
	if strips.is_empty():
		return
	_add_site("pawilony", strips)
	if not sites.is_empty() and sites[-1]["key"] == "pawilony":
		sites[-1]["strips"] = strips


## A seeded 0..1 from a strip, a pavilion and a salt (the same every run and every sector).
func _paw_rand(strip: int, unit: int, salt: int) -> float:
	var x := sin(float(unit) * 12.9898 + float(strip) * 78.233 + float(salt) * 37.719) * 43758.5453
	return x - floorf(x)


func _build_pawilony(site: Dictionary) -> void:
	var strips: Array = site["strips"]
	for k in strips.size():
		var poly: PackedVector2Array = strips[k]
		# The strip's frame: u along its longest edge, v across.
		var longest := 0.0
		for i in poly.size():
			var e := poly[(i + 1) % poly.size()] - poly[i]
			if e.length() > longest:
				longest = e.length()
				_a = e.normalized()
		_b = Vector2(-_a.y, _a.x)
		_o = _centre(poly)
		var lo := Vector2(INF, INF)
		var hi := -lo
		for q in poly:
			lo = lo.min(_local(q))
			hi = hi.max(_local(q))
		# Rows: [v of the back, v of the front, which way the front faces (+1: +v)].
		var rows: Array = []
		if hi.y - lo.y > PAW_ROW:
			var mid := (lo.y + hi.y) * 0.5
			rows.append([mid, lo.y, -1.0])
			rows.append([mid, hi.y, 1.0])
		else:
			# One row: its front to the north (the footpath along the south-east strip).
			var s := -1.0 if _b.y > 0.0 else 1.0
			rows.append([hi.y if s < 0.0 else lo.y, lo.y if s < 0.0 else hi.y, s])
		for r in rows.size():
			_paw_row(k * 2 + r, lo.x, hi.x, rows[r][0], rows[r][1], rows[r][2])
		_collide(poly)
	# The gate's sign on Nowy Świat.
	var gy: float = map.terrain_height(PAW_GATE.x, PAW_GATE.y) + PAW_GATE_UP
	signs.append(["PAWILONY", Vector3(PAW_GATE.x, gy, PAW_GATE.y), Vector3(PAW_GATE_OUT.x, 0.0, PAW_GATE_OUT.y),
			PAW_GATE_K, Color(1.0, 0.92, 0.8)])


## One row of pavilions from u0 to u1, back at v = vb, front at v = vf facing `side` (+-v).
func _paw_row(strip: int, u0: float, u1: float, vb: float, vf: float, side: float) -> void:
	var cuts: Array[float] = [u0]
	var u := u0
	var n := 0
	while true:
		var w := lerpf(PAW_MIN_W, PAW_MAX_W, _paw_rand(strip, n, 1))
		if u1 - (u + w) < PAW_MIN_W:
			break
		u += w
		cuts.append(u)
		n += 1
	cuts.append(u1)
	var out := _b * side
	var n3 := Vector3(out.x, 0.0, out.y)
	for i in cuts.size() - 1:
		var a := cuts[i]
		var b := cuts[i + 1]
		var plan := PackedVector2Array([_w(a, vb), _w(b, vb), _w(b, vf), _w(a, vf)])
		var g := _ground_under(plan)
		_g = g
		var top := g + lerpf(PAW_MIN_H, PAW_MAX_H, _paw_rand(strip, i, 2))
		var wall := Color(PAW_WALLS[int(_paw_rand(strip, i, 3) * PAW_WALLS.size()) % PAW_WALLS.size()])
		var roof := Color(PAW_ROOFS[int(_paw_rand(strip, i, 10) * PAW_ROOFS.size()) % PAW_ROOFS.size()])
		var none := Color(0, 0, 0, 0)
		_prism(plan, g - 0.3, g, PAW_PLINTH, none, M_STONE)
		_prism(plan, g, top, wall, roof, M_STONE, M_STONE)
		# The eave over the front.
		var eave := PackedVector2Array([_w(a, vf), _w(b, vf), _w(b, vf + side * PAW_EAVE), _w(a, vf + side * PAW_EAVE)])
		_prism(eave, top - 0.12, top + 0.05, roof.darkened(0.15), roof.lightened(0.05), M_STONE, M_STONE)
		# The fascia, then the door and the window (or shutter) below it, a little proud of the wall.
		var f := vf + side * 0.09
		var p := vf + side * 0.05
		# A bar with a sign has its fascia lit (a light box), the others a plain board.
		var signed := _paw_rand(strip, i, 7) < 0.67
		_mode = M_PAVILION if signed else M_STONE
		_wall(_w(a + 0.2, f), _w(b - 0.2, f), top - 0.52, top - 0.14, out,
				wall.lerp(Color.WHITE, 0.45) if signed else wall.darkened(0.25))
		_mode = M_STONE
		var left := _paw_rand(strip, i, 4) < 0.5
		var d0 := a + 0.5 if left else b - 1.5
		_wall(_w(d0, p), _w(d0 + 1.0, p), g, g + 2.0, out, PAW_DOOR)
		var ww := minf(lerpf(1.4, 2.4, _paw_rand(strip, i, 5)), (b - a) - 2.6)
		var w0 := d0 + 1.4 if left else d0 - 0.4 - ww
		var lit := _paw_rand(strip, i, 6) < 0.7
		_mode = M_PAVILION if lit else M_STONE
		_wall(_w(w0, p), _w(w0 + ww, p), g + 0.9, g + 2.0, out, PAW_GLASS if lit else PAW_SHUTTER)
		_mode = M_STONE
		# A neon word on most fronts, standing on the eave's front edge (under the eave the
		# game's camera, 30-40 degrees down, can't see it), warm bulbs under the others' eaves.
		var mid := (a + b) * 0.5
		if signed:
			var word: String = PAW_WORDS[int(_paw_rand(strip, i, 8) * PAW_WORDS.size()) % PAW_WORDS.size()]
			var tube: Color = PAW_TUBES[int(_paw_rand(strip, i, 9) * PAW_TUBES.size()) % PAW_TUBES.size()]
			var k := minf(PAW_SIGN_K, (b - a - 0.4) / Neon.length_of(word))
			var at := _w(mid, vf + side * (PAW_EAVE + 0.02 - 0.4))
			signs.append([word, Vector3(at.x, top + 0.05, at.y), n3, k, tube])
			# The sign's board behind it, so from behind the word isn't seen backwards.
			var half := Neon.length_of(word) * k * 0.5
			var board := PackedVector2Array([_w(mid - half, vf + side * 0.05), _w(mid + half, vf + side * 0.05),
					_w(mid + half, vf + side * PAW_EAVE), _w(mid - half, vf + side * PAW_EAVE)])
			_prism(board, top + 0.05, top + 0.05 + Neon.ROW_H * Neon.PIXEL * k, PAW_DOOR, PAW_DOOR, M_STONE, M_STONE)
		else:
			_mode = M_LAMP
			for t: float in [0.25, 0.5, 0.75]:
				var c := lerpf(a, b, t)
				_prism(_rect(c, vf + side * 0.17, 0.08, 0.08), top - 0.28, top - 0.12, PAW_BULB, PAW_BULB, M_LAMP, M_LAMP)
			_mode = M_STONE


# --- PIJANA CZEREŚNIA (F's photos, 2026-11-08) -----------------------------------------------

## The cherry-liqueur kiosk in the park by Emilii Plater (OSM "Pijana Wiśnia"), from F's photos
## and a Commons shot: a dark octagonal glass pavilion on a low plinth, a shallow glazed roof under
## a barrel-like brown drum with two darker bands, the red cherry cartouche on the drum, painted
## front windows (a man in a flat cap with his dog, a woman with cherries), bottle shelves in the
## side bays, a timber deck in front with dark X-braced railings and planters, and string lights.
## The name is the parody PIJANA CZEREŚNIA (cherry, not sour cherry: the same drunk fruit).
## Frame: _o the outline's middle, _b out of the front (the path side, east), _a along it.
const PIJ_OSM := "Pijana Wiśnia"
const PIJ_FRONT := Vector2(0.98, 0.2)
const PIJ_R := 5.3             # the octagon's corner radius (about 10 m across the flats)
const PIJ_KNEE := 0.9          # the dark knee wall's height over the floor
const PIJ_WALL := 3.1          # the glass wall's top over the floor
const PIJ_FASCIA := 0.45
const PIJ_DRUM_R := 3.9
const PIJ_DRUM_H := 2.9
const PIJ_DECK_V0 := 3.3
const PIJ_DECK_V1 := 8.2
const PIJ_DECK_U := 6.4
const PIJ_DARK := Color("#1f1a1c")
const PIJ_PLINTH := Color("#4a4744")
const PIJ_GLASS := Color("#2e3c3e")
const PIJ_ROOF := Color("#5c554c")
const PIJ_BARREL := Color("#523a2e")
const PIJ_BAND := Color("#2f221c")
const PIJ_WOOD := Color("#6b5238")
const PIJ_CHERRY := Color("#c3202b")
const PIJ_LEAF := Color("#4f7a2c")
const PIJ_CREAM := Color("#e7d9b6")
const PIJ_SKIN := Color("#d9a47a")
const PIJ_FUR := Color("#b8641c")
const PIJ_HAIR := Color("#8a3b1f")
const PIJ_CYAN := Color(0.35, 0.8, 1.0)
const PIJ_CREAM_T := Color(1.0, 0.93, 0.78)
const PIJ_WORD_A := "PIJANA"
const PIJ_WORD_B := "CZEREŚNIA"


func _find_pijana() -> void:
	var q := _landmark(PIJ_OSM)
	if q.size() < 3:
		return
	_add_site("pijana", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "pijana":
		sites[-1]["outline"] = _simplify(q, 0.4)


## The octagon (or any even n-gon) of corner radius r in the local plan; face k faces angle k*TAU/n.
func _pij_poly(r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		var a := TAU * (k + 0.5) / n
		out.append(_w(r * cos(a), r * sin(a)))
	return out


## A world point on octagon face k: `s` along the face, `d` out of it (the apothem is the zero).
func _pij_pt(k: int, s: float, d: float) -> Vector2:
	var th := k * PI / 4.0
	var n := Vector2(cos(th), sin(th))
	var t := Vector2(-sin(th), cos(th))
	var l := n * (PIJ_R * cos(PI / 8.0) + d) + t * s
	return _w(l.x, l.y)


## A thin painted panel on octagon face k, from s0 to s1 and y0 to y1, `proud` m out of the glass.
func _pij_panel(k: int, s0: float, s1: float, y0: float, y1: float, col: Color, proud := 0.04, mode := M_STONE) -> void:
	var poly := PackedVector2Array([_pij_pt(k, s0, 0.0), _pij_pt(k, s1, 0.0), _pij_pt(k, s1, proud), _pij_pt(k, s0, proud)])
	_prism(poly, y0, y1, col, Color(0, 0, 0, 0), mode)


func _build_pijana(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_pav_frame(outline, Vector2(-PIJ_FRONT.y, PIJ_FRONT.x), PIJ_FRONT)
	var none := Color(0, 0, 0, 0)
	var foot := _pij_poly(PIJ_R + 0.6, 8)
	var g := _ground_under(foot)
	var top := g
	for q in _pij_poly(PIJ_R + 6.0, 8):
		top = maxf(top, map.terrain_height(q.x, q.y))
	var f := minf(top, g + 0.6) + 0.25   # the floor, a little over the park's ground
	_g = f
	_mode = M_STONE
	var ap := PIJ_R * cos(PI / 8.0)
	# The plinth and the dark knee wall, the glass wall lit warm at night, the corner posts.
	_prism(foot, g - 0.5, f, PIJ_PLINTH, PIJ_PLINTH.darkened(0.05), M_STONE, M_STONE)
	var shell := _pij_poly(PIJ_R, 8)
	_prism(shell, f, f + PIJ_KNEE, PIJ_DARK, none, M_STONE)
	var glass := _pij_poly(PIJ_R - 0.04, 8)
	_prism(glass, f + PIJ_KNEE, f + PIJ_WALL, PIJ_GLASS.lightened(0.12), none, M_PAVILION)
	_mullions(glass, f + PIJ_KNEE, f + PIJ_WALL, 1.4, 0.05, PIJ_DARK)
	for v in shell:
		var l := _local(v)
		_ubox(l.x - 0.11, l.x + 0.11, l.y - 0.11, l.y + 0.11, f, f + PIJ_WALL + PIJ_FASCIA, PIJ_DARK)
	# The fascia ring with the chalk-blue name, a shallow glazed roof and the drum on it.
	var fascia := _pij_poly(PIJ_R + 0.14, 8)
	_prism(fascia, f + PIJ_WALL, f + PIJ_WALL + PIJ_FASCIA, PIJ_DARK, PIJ_DARK.lightened(0.05), M_STONE, M_STONE)
	_mode = M_STONE
	var ry := f + PIJ_WALL + PIJ_FASCIA
	_pyramid(_pij_poly(PIJ_R + 0.3, 8), ry, ry + 1.1, PIJ_ROOF)
	var d0 := ry + 0.3
	var drum := _pij_poly(PIJ_DRUM_R, 16)
	_prism(drum, d0, d0 + PIJ_DRUM_H, PIJ_BARREL, PIJ_BAND, M_STONE, M_STONE)
	for by: float in [0.5, 2.0]:
		_prism(_pij_poly(PIJ_DRUM_R + 0.1, 16), d0 + by, d0 + by + 0.22, PIJ_BAND, none, M_STONE)
	_prism(_pij_poly(PIJ_DRUM_R - 0.3, 16), d0 + PIJ_DRUM_H, d0 + PIJ_DRUM_H + 0.25, PIJ_BAND, PIJ_BAND.lightened(0.08), M_STONE, M_STONE)
	_ubox(-1.4, -0.2, -2.2, -1.2, d0 + PIJ_DRUM_H + 0.25, d0 + PIJ_DRUM_H + 0.95, Color("#9a9fa3"))   # the air handler
	# The red cherry cartouche on the drum's front: PIJANA over CZEREŚNIA, a pair of cherries below.
	var py := d0 + 0.7
	_ubox(-1.75, 1.75, 3.5, 3.9, py, py + 1.65, PIJ_CHERRY, M_STONE, PIJ_CHERRY.darkened(0.1))
	_ubox(-1.6, 1.6, 3.9, 3.94, py + 0.08, py + 1.57, PIJ_CHERRY.lightened(0.12))
	_usign(PIJ_WORD_A, 0.0, 3.97, py + 1.0, _b, 2.6, 0.48, PIJ_CREAM_T)
	_usign(PIJ_WORD_B, 0.0, 3.97, py + 0.45, _b, 3.0, 0.45, PIJ_CREAM_T)
	_ubox(-0.9, 0.9, 3.92, 3.99, py + 0.02, py + 0.3, PIJ_LEAF)
	for cu: float in [-0.35, 0.35]:
		_ubox(cu - 0.17, cu + 0.17, 3.9, 4.2, py - 0.3, py + 0.04, PIJ_CHERRY.lightened(0.05), M_LAMP)
	_usign(PIJ_WORD_B, 0.0, ap + 0.18, f + PIJ_WALL + 0.06, _b, 3.0, 0.33, PIJ_CYAN)
	# The painted front windows (k = 2 faces the front): the man in a flat cap with his dog, the
	# woman with cherries, the door between them; the flanking faces hold the bottle shelves.
	_pij_panel(2, -1.95, -0.65, f + 0.2, f + 2.9, PIJ_DARK.lightened(0.06), 0.06)
	_pij_panel(2, -1.4, -1.0, f + 0.5, f + 2.0, PIJ_CREAM, 0.10)     # his coat
	_pij_panel(2, -1.35, -1.05, f + 2.0, f + 2.35, PIJ_SKIN, 0.11)   # head
	_pij_panel(2, -1.45, -0.95, f + 2.35, f + 2.5, Color("#a8896a"), 0.11)   # flat cap
	_pij_panel(2, -0.9, -0.68, f + 0.5, f + 1.4, PIJ_FUR, 0.11)      # the dog
	_pij_panel(2, -0.95, -0.7, f + 1.4, f + 1.7, PIJ_FUR.darkened(0.15), 0.11)
	_pij_panel(2, 0.65, 1.95, f + 0.2, f + 2.9, PIJ_DARK.lightened(0.06), 0.06)
	_pij_panel(2, 0.7, 1.9, f + 0.25, f + 0.7, PIJ_LEAF, 0.10)       # leaves
	_pij_panel(2, 0.95, 1.55, f + 0.7, f + 1.8, PIJ_CREAM, 0.11)     # her dress
	_pij_panel(2, 1.05, 1.45, f + 1.8, f + 2.2, PIJ_SKIN, 0.11)
	_pij_panel(2, 0.95, 1.55, f + 2.2, f + 2.55, PIJ_HAIR, 0.11)
	_pij_panel(2, 1.1, 1.4, f + 1.25, f + 1.6, PIJ_CHERRY, 0.14, M_LAMP)   # the cherries
	_pij_panel(2, -0.45, 0.45, f + 0.1, f + 2.6, PIJ_DARK, 0.08)   # the door frame
	_pij_panel(2, 0.3, 0.36, f + 1.1, f + 1.6, Color("#c9c9c9"), 0.11)
	for k: int in [1, 3]:
		for sy: float in [1.35, 2.05]:
			_pij_panel(k, -1.3, 1.3, f + sy, f + sy + 0.06, PIJ_DARK, 0.05)
			for i in 6:
				var s := -1.1 + i * 0.44
				_pij_panel(k, s, s + 0.14, f + sy + 0.06, f + sy + 0.42, PIJ_CHERRY if i % 2 == 0 else PIJ_BAND, 0.06)
	# The timber deck in front, its dark X-braced rail with planters, two posts of string lights.
	var dk := _urect(-PIJ_DECK_U, PIJ_DECK_U, PIJ_DECK_V0, PIJ_DECK_V1)
	_prism(dk, g - 0.5, f, PIJ_WOOD.darkened(0.15), PIJ_WOOD, M_STONE, M_STONE)
	_ubox(-0.95, 0.95, PIJ_DECK_V1, PIJ_DECK_V1 + 0.6, g - 0.5, f - 0.17, PIJ_WOOD, M_STONE, PIJ_WOOD)
	var runs: Array = []   # rail runs as [u0, v0, u1, v1]
	runs.append([-PIJ_DECK_U, PIJ_DECK_V1, -0.95, PIJ_DECK_V1])
	runs.append([0.95, PIJ_DECK_V1, PIJ_DECK_U, PIJ_DECK_V1])
	runs.append([-PIJ_DECK_U, PIJ_DECK_V0 + 0.2, -PIJ_DECK_U, PIJ_DECK_V1])
	runs.append([PIJ_DECK_U, PIJ_DECK_V0 + 0.2, PIJ_DECK_U, PIJ_DECK_V1])
	var planter := 0
	for r: Array in runs:
		var a := Vector2(r[0], r[1])
		var b := Vector2(r[2], r[3])
		var len := a.distance_to(b)
		var n := maxi(2, roundi(len / 0.9))
		for i in n + 1:
			var c := a.lerp(b, float(i) / n)
			_ubox(c.x - 0.05, c.x + 0.05, c.y - 0.05, c.y + 0.05, f, f + 1.05, PIJ_DARK)
		var mid := (a + b) * 0.5
		var hu := maxf(absf(b.x - a.x) * 0.5, 0.04)
		var hv := maxf(absf(b.y - a.y) * 0.5, 0.04)
		for ry2: float in [0.12, 0.55, 1.0]:
			_ubox(mid.x - hu, mid.x + hu, mid.y - hv, mid.y + hv, f + ry2, f + ry2 + 0.07, PIJ_DARK)
		for i in n:
			var c2 := a.lerp(b, (i + 0.5) / n)
			planter += 1
			if planter % 2 == 0:
				_ubox(c2.x - 0.3, c2.x + 0.3, c2.y - 0.16, c2.y + 0.16, f + 1.05, f + 1.3, PIJ_BAND, M_STONE, PIJ_CHERRY)
	# String lights: two black posts at the deck's front corners and a sagging line of warm lamps.
	for pu: float in [-PIJ_DECK_U + 0.1, PIJ_DECK_U - 0.1]:
		_ubox(pu - 0.06, pu + 0.06, PIJ_DECK_V1 - 0.16, PIJ_DECK_V1 - 0.04, f, f + 3.6, PIJ_DARK)
	var wy := f + 3.6
	_ubox(-PIJ_DECK_U + 0.1, PIJ_DECK_U - 0.1, PIJ_DECK_V1 - 0.12, PIJ_DECK_V1 - 0.08, wy - 0.05, wy, PIJ_DARK)
	var nl := 14
	for i in nl + 1:
		var t := float(i) / nl
		var lu := lerpf(-PIJ_DECK_U + 0.1, PIJ_DECK_U - 0.1, t)
		var ly := wy - 0.1 - 0.5 * sin(t * PI)
		_ubox(lu - 0.015, lu + 0.015, PIJ_DECK_V1 - 0.115, PIJ_DECK_V1 - 0.085, ly + 0.1, wy - 0.05, PIJ_DARK)
		_prism(_rect(lu, PIJ_DECK_V1 - 0.1, 0.06, 0.06), ly, ly + 0.12, Color(1.0, 0.85, 0.5), Color(1.0, 0.85, 0.5), M_LAMP, M_LAMP)
	_collide(_pij_poly(PIJ_R + 0.3, 8))
	_collide(dk)


# --- SOWA CLUB and CITY 25 (F's photos, 2026-11-06) ------------------------------------------

## The neon glass pavilion on Al. Jerozolimskie 2-6, on the lawn between the 1950s block and the
## street east of Rondo de Gaulle'a, from F's three photos (two at night, one by day): a white
## two-storey box on the west end with the restaurant's roof sign (RESTAURANT / CITY 24 / GRILL&BAR
## round a blue crescent), a glass box for the club east of it (a glass shop storey, an upper
## storey of printed glass, a pink-and-white scalloped valance), pink tubes on every edge, a violet
## band at the first floor, the club's name in red and white letters on the roof, and a terrace on
## a plinth in front with a glass rail, beer banners and four umbrellas. Every name is a parody:
## SOGO CLUB is SOWA CLUB (the night owls'), CITY 24 is CITY 25 (an hour more than the others),
## the soda is PEPSZY ("lepszy"), the beer KACBERG (kac: the hangover). The 2026 street photos
## (refs/sogo/) show a lawn there now: the game keeps the pavilion. Placed from the OpenStreetMap
## outlines of the block (nos. 4, 6) and its glass ground-floor strip (no. 2): SOWA_O is the
## strip's west front corner, u runs east along it, v out to the street.
const SOWA_O := Vector2(19.0, 131.0)
const SOWA_A := Vector2(0.933, -0.358)
const SOWA_TOWER := Vector4(14.0, 1.0, 23.0, 10.0)    # u0, v0, u1, v1 of the restaurant's box
const SOWA_BOX := Vector4(23.0, 0.5, 50.0, 10.0)      # the club's glass box
const SOWA_DECK := Vector4(23.5, 10.0, 50.0, 13.8)    # the terrace (an advertising column stands at v 14.7)
const SOWA_TOWER_H := 8.5
const SOWA_LOW := 3.4          # the glass shop storey's top
const SOWA_H := 7.6            # the glass box's top
const SOWA_WHITE := Color("#eceae4")
const SOWA_GLASS := Color("#4d5a68")
const SOWA_PRINT := Color("#5a4560")   # the upper storey's printed glass
const SOWA_FRAME := Color("#26252b")
const SOWA_BOARD := Color("#1b1a2c")
const SOWA_PLINTH := Color("#b9b2a2")
const SOWA_MURAL := Color("#d48a3c")   # the printed banner on the terrace's front wall
const SOWA_DECK_TOP := Color("#6e5d4c")
const SOWA_RAIL := Color("#a9bcc6")
const SOWA_BRELLA := Color("#1e3a34")
const SOWA_VALANCE := [Color("#e0417f"), Color("#f2eeea")]
const SOWA_PINK := Color(1.0, 0.22, 0.82)
const SOWA_VIOLET := Color(0.55, 0.3, 1.0)
const SOWA_LIT := M_PAVILION + 0.375   # the glass box lit pink from inside at night (building.gdshader)
const SOWA_BLUE := Color(0.2, 0.55, 1.0)
const SOWA_RED := Color(1.0, 0.16, 0.18)
const SOWA_WHITE_T := Color(0.95, 0.95, 1.0)
const SOWA_ORANGE := Color(1.0, 0.5, 0.12)
const SOWA_GREEN := Color(0.25, 1.0, 0.45)


func _sowa_frame() -> void:
	_o = SOWA_O
	_a = SOWA_A
	_b = Vector2(-SOWA_A.y, SOWA_A.x)


func _sowa_rect(r: Vector4) -> PackedVector2Array:
	return _rect((r.x + r.z) * 0.5, (r.y + r.w) * 0.5, (r.z - r.x) * 0.5, (r.w - r.y) * 0.5)


func _find_sowa() -> void:
	_sowa_frame()
	var all := Vector4(SOWA_TOWER.x - 3.0, SOWA_BOX.y, SOWA_DECK.z, SOWA_DECK.w)
	_add_site("sowa", [_sowa_rect(all)])


## A neon tube: a thin lit box in the local plan.
func _sowa_tube(cu: float, cv: float, hu: float, hv: float, y0: float, y1: float, col: Color) -> void:
	_prism(_rect(cu, cv, hu, hv), y0, y1, col, col, M_LAMP, M_LAMP)


## A sign word on the face at local v, its bottom middle at (u, y), facing the street.
func _sowa_sign(word: String, u: float, v: float, y: float, k: float, col: Color) -> void:
	var at := _w(u, v)
	signs.append([word, Vector3(at.x, y, at.y), Vector3(_b.x, 0.0, _b.y), k, col])


## A sign word on a face whose outward normal is `out` (in plan), its bottom middle at local (u, v).
func _sowa_sign_out(word: String, u: float, v: float, y: float, k: float, col: Color, out: Vector2) -> void:
	var at := _w(u, v)
	signs.append([word, Vector3(at.x, y, at.y), Vector3(out.x, 0.0, out.y), k, col])


func _build_sowa(_site: Dictionary) -> void:
	_sowa_frame()
	var none := Color(0, 0, 0, 0)
	var all := _sowa_rect(Vector4(SOWA_TOWER.x, SOWA_BOX.y, SOWA_DECK.z, SOWA_DECK.w))
	var g := _ground_under(all)
	var top := g
	for q in all:
		top = maxf(top, map.terrain_height(q.x, q.y))
	var f := top + 0.3           # the floor: on a plinth over the slope
	_g = f
	_mode = M_STONE
	# The plinth under everything, its street face the terrace's printed banner.
	_prism(_sowa_rect(Vector4(SOWA_TOWER.x, SOWA_BOX.y, SOWA_BOX.z, SOWA_BOX.w)), g - 0.4, f, SOWA_PLINTH, none, M_STONE)
	_prism(_sowa_rect(SOWA_DECK), g - 0.4, f, SOWA_MURAL, SOWA_DECK_TOP, M_STONE, M_STONE)
	# The restaurant's white box, its edges in pink tubes.
	var t := SOWA_TOWER
	_prism(_sowa_rect(t), f, f + SOWA_TOWER_H, SOWA_WHITE, SOWA_WHITE.darkened(0.15), M_STONE, M_STONE)
	# F (2026-11-06): the restaurant's neon faces the Palm, west down Jerozolimskie: its door, the
	# soda's panel, the menu words, the canopy and the roof sign are on the box's west face (local
	# -u; a word on it reads towards the street, +v).
	var west := Vector2(-SOWA_A.x, -SOWA_A.y)
	var wu := t.x
	var tv := (t.y + t.w) * 0.5
	_lbox(wu - 0.02, tv + 1.6, 0.03, 1.6, f, f + 2.5, SOWA_GLASS.lightened(0.1), M_PAVILION)  # the door's glass
	for v: float in [t.y, t.w]:
		_sowa_tube(wu - 0.05, v, 0.06, 0.06, f + 0.3, f + SOWA_TOWER_H, SOWA_PINK)
	_sowa_tube(wu - 0.05, tv, 0.06, (t.w - t.y) * 0.5, f + SOWA_TOWER_H - 0.12, f + SOWA_TOWER_H, SOWA_PINK)
	_sowa_tube((t.x + t.z) * 0.5, t.w + 0.05, (t.z - t.x) * 0.5, 0.06, f + SOWA_TOWER_H - 0.12, f + SOWA_TOWER_H, SOWA_PINK)
	# The soda's panel and the menu words on the west face.
	_lbox(wu - 0.04, t.y + 2.4, 0.04, 1.3, f + 3.0, f + 5.4, SOWA_BOARD, M_STONE)
	_sowa_tube(wu - 0.1, t.y + 2.4, 0.02, 0.45, f + 4.75, f + 5.05, SOWA_RED)
	_sowa_tube(wu - 0.1, t.y + 2.4, 0.02, 0.45, f + 4.45, f + 4.75, SOWA_BLUE)
	_sowa_sign_out("PEPSZY", wu - 0.08, t.y + 2.4, f + 3.3, 0.32, SOWA_BLUE, west)
	_sowa_sign_out("STEKI", wu, t.y + 6.2, f + 6.6, 0.3, SOWA_ORANGE, west)
	_sowa_sign_out("PIZZA", wu, t.y + 6.2, f + 5.7, 0.3, SOWA_RED, west)
	_sowa_sign_out("BURGERY", wu, t.y + 6.2, f + 4.8, 0.3, SOWA_GREEN, west)
	# The roof sign along the west edge: a dark board, RESTAURANT / CITY 25 / GRILL BAR and the
	# blue crescent, facing the Palm.
	var bu := t.x + 0.6
	var bv := tv
	_lbox(bu, bv, 0.12, 5.0, f + SOWA_TOWER_H, f + SOWA_TOWER_H + 4.2, SOWA_BOARD, M_STONE)
	for y: float in [f + SOWA_TOWER_H + 0.05, f + SOWA_TOWER_H + 4.1]:
		_sowa_tube(bu - 0.15, bv, 0.04, 5.0, y, y + 0.08, SOWA_PINK)
	var k := 0.85
	var lc := Neon.length_of("CITY") * k
	var l25 := Neon.length_of("25") * k
	var v0 := bv - (lc + 0.3 + l25) * 0.5 - 0.4
	var face := bu - 0.13
	_sowa_sign_out("RESTAURANT", face, bv - 0.6, f + SOWA_TOWER_H + 3.05, 0.42, SOWA_PINK, west)
	_sowa_sign_out("CITY", face, v0 + lc * 0.5, f + SOWA_TOWER_H + 1.1, k, SOWA_WHITE_T, west)
	_sowa_sign_out("25", face, v0 + lc + 0.3 + l25 * 0.5, f + SOWA_TOWER_H + 1.1, k, SOWA_ORANGE, west)
	_sowa_sign_out("GRILL BAR", face, bv - 0.6, f + SOWA_TOWER_H + 0.2, 0.4, SOWA_PINK, west)
	var cc := Vector2(bv + 2.4, f + SOWA_TOWER_H + 2.2)
	for n in 15:
		var ang := deg_to_rad(-70.0 + 150.0 * n / 14.0)
		var cv := cc.x + cos(ang) * 2.1
		var cy := cc.y + sin(ang) * 1.9
		_sowa_tube(face - 0.1, cv, 0.05, 0.11, cy - 0.09, cy + 0.09, SOWA_BLUE)
	# The entrance canopy over the west door: white, a pink tube on its edge, its name.
	_lbox(wu - 1.4, tv + 1.6, 1.4, 2.2, f + 2.6, f + 3.0, SOWA_WHITE, M_STONE)
	_sowa_tube(wu - 2.83, tv + 1.6, 0.04, 2.2, f + 2.6, f + 2.7, SOWA_PINK)
	for v: float in [tv - 0.4, tv + 3.6]:
		_lbox(wu - 2.7, v, 0.05, 0.05, g - 0.3, f + 2.6, SOWA_FRAME, M_STONE)
	_sowa_sign_out("CITY 25", wu - 2.84, tv + 1.6, f + 2.62, 0.22, SOWA_PINK, west)
	_sowa_sign("24H", (t.x + t.z) * 0.5, t.w, f + 5.6, 0.5, SOWA_RED)
	# The club's glass box: the shop storey, the printed upper storey, the frames.
	var bx := SOWA_BOX
	var box := _sowa_rect(bx)
	_prism(box, f, f + SOWA_LOW, SOWA_GLASS, none, SOWA_LIT)
	_mullions(box, f, f + SOWA_LOW, 2.5, 0.05, SOWA_FRAME)
	_prism(box, f + SOWA_LOW, f + SOWA_LOW + 0.3, SOWA_FRAME, none, M_STONE)
	_prism(box, f + SOWA_LOW + 0.3, f + SOWA_H - 0.6, SOWA_PRINT, none, SOWA_LIT)
	_mullions(box, f + SOWA_LOW + 0.3, f + SOWA_H - 0.6, 2.2, 0.05, SOWA_FRAME)
	_prism(box, f + SOWA_H - 0.6, f + SOWA_H, SOWA_WHITE, SOWA_WHITE.darkened(0.25), M_STONE, M_STONE)
	# The scalloped valance under the roof edge: pink and white stripes on the front and the sides.
	_mode = M_STONE
	var cols: Array = SOWA_VALANCE
	var nf := roundi((bx.z - bx.x) / 0.9)
	for i in nf:
		var cu := bx.x + (i + 0.5) * (bx.z - bx.x) / nf
		_lbox(cu, bx.w + 0.18, (bx.z - bx.x) / nf * 0.5, 0.06, f + SOWA_H - 1.15, f + SOWA_H - 0.55, cols[i % 2], M_STONE)
	var ns := roundi((bx.w - bx.y) / 0.9)
	for i in ns:
		var cv := bx.y + (i + 0.5) * (bx.w - bx.y) / ns
		_lbox(bx.z + 0.18, cv, 0.06, (bx.w - bx.y) / ns * 0.5, f + SOWA_H - 1.15, f + SOWA_H - 0.55, cols[i % 2], M_STONE)
	# The pink tubes: the roof edge, the floor line and every corner; the violet band.
	var mu := (bx.x + bx.z) * 0.5
	var hu := (bx.z - bx.x) * 0.5
	var mv := (bx.y + bx.w) * 0.5
	var hv := (bx.w - bx.y) * 0.5
	for y: float in [f + SOWA_H - 0.1, f + 0.35]:
		_sowa_tube(mu, bx.w + 0.26, hu + 0.26, 0.05, y, y + 0.12, SOWA_PINK)
		_sowa_tube(bx.z + 0.26, mv, 0.05, hv + 0.26, y, y + 0.12, SOWA_PINK)
	for c: Vector2 in [Vector2(bx.z + 0.26, bx.w + 0.26), Vector2(bx.x + 0.1, bx.w + 0.26), Vector2(bx.z + 0.26, bx.y + 0.1)]:
		_sowa_tube(c.x, c.y, 0.06, 0.06, f + 0.35, f + SOWA_H, SOWA_PINK)
	_sowa_tube(mu, bx.w + 0.2, hu, 0.05, f + SOWA_LOW + 0.12, f + SOWA_LOW + 0.22, SOWA_VIOLET)
	_sowa_tube(bx.z + 0.2, mv, 0.05, hv, f + SOWA_LOW + 0.12, f + SOWA_LOW + 0.22, SOWA_VIOLET)
	_sowa_sign("ZAPRASZAMY", mu, bx.w + 0.2, f + SOWA_LOW + 0.32, 0.36, SOWA_VIOLET)
	_sowa_sign("24H", bx.z - 3.0, bx.w + 0.1, f + 4.6, 0.55, SOWA_RED)
	# The club's name on the roof: red and white letters on a slim dark rail at the back.
	var lw := Neon.length_of("SOWA")
	var nu := mu + 4.0
	_lbox(nu, bx.y + 1.0, lw + 0.6, 0.06, f + SOWA_H, f + SOWA_H + 0.25, SOWA_FRAME, M_STONE)
	for u: float in [nu - lw, nu, nu + lw]:
		_lbox(u, bx.y + 1.0, 0.06, 0.06, f + SOWA_H, f + SOWA_H + 1.8, SOWA_FRAME, M_STONE)
	_sowa_sign("SOWA", nu - lw * 0.5 - 0.15, bx.y + 1.1, f + SOWA_H + 0.25, 1.0, SOWA_RED)
	_sowa_sign("CLUB", nu + lw * 0.5 + 0.15, bx.y + 1.1, f + SOWA_H + 0.25, 1.0, SOWA_WHITE_T)
	# The terrace: a glass rail with the beer's banners, a gap for the steps at the west end.
	var d := SOWA_DECK
	_lbox((d.x + 2.0 + d.z) * 0.5, d.w - 0.06, (d.z - d.x - 2.0) * 0.5, 0.04, f, f + 1.0, SOWA_RAIL, M_STONE)
	_lbox(d.z - 0.06, (d.y + d.w) * 0.5, 0.04, (d.w - d.y) * 0.5, f, f + 1.0, SOWA_RAIL, M_STONE)
	_lbox((d.x + 2.0 + d.z) * 0.5, d.w - 0.03, (d.z - d.x - 2.0) * 0.5, 0.05, f + 0.98, f + 1.06, SOWA_FRAME, M_STONE)
	for u: float in [d.x + 6.5, d.x + 14.5]:
		_lbox(u, d.w, 1.6, 0.03, f + 0.2, f + 0.85, Color("#1f6a3c"), M_STONE)
		_sowa_sign("KACBERG", u, d.w, f + 0.3, 0.32, SOWA_GREEN)
	# The steps down to the pavement in the rail's gap, one 0.45 m tread each.
	for i in 4:
		_lbox(d.x + 1.0, d.w + 0.2 + i * 0.45, 0.9, 0.24, g - 0.3, lerpf(f, g, (i + 1) / 5.0), SOWA_PLINTH, M_STONE)
	_collide(_sowa_rect(Vector4(SOWA_TOWER.x, SOWA_BOX.y, SOWA_BOX.z, SOWA_BOX.w)))
	_collide(_sowa_rect(Vector4(d.x + 2.0, d.y, d.z, d.w)))
	# The umbrellas (each sets its own frame, so they come last).
	var spots: Array[Vector2] = []
	for i in 4:
		spots.append(_w(d.x + 4.5 + i * 6.2, (d.y + d.w) * 0.5 + 0.2))
	var yaw := atan2(SOWA_A.x, SOWA_A.y)
	for p: Vector2 in spots:
		_umbrella(p, yaw, f, SOWA_BRELLA)


# --- Ministerstwo Finansów (the landmarks lane, 2026-11-01, spec docs/landmarks/specs/mf.md) -----

## The Ministry of Finance, Świętokrzyska 12 (Stanisław Bieńkuński and Stanisław Rychłowski,
## 1953-1956; socialist realism with art déco, "Renaissance and Baroque palace principles" in
## pale pink-grey Suchedniów sandstone and terrazzo plaster; a monument since 2012). Its mapped
## outline is a comb: two wings reaching south to Świętokrzyska round a court with a round
## fountain, the 83 m central block with its entrance in the middle of the south face, the long
## north-west wing. The model lifts that outline (`_simplify`d) on a rusticated ground floor,
## three storeys of tall bays, a cornice, an attic parapet and a dark flat roof; the central
## entrance is a risalit with six pilasters, three doors, steps and a raised attic; each wing
## ends in a hipped-roof pavilion; the court's fountain is the map's own. Heights are the
## map's (17.5 m); the pavilions' roofs, the risalit's rise and the colours are a first pass
## for the Mac photo check.
const MF_TOP := 17.5
const MF_FACE_E := Vector2(-506.7, -409.1)   # the central block's south face, east end
const MF_FACE_W := Vector2(-586.1, -384.4)   # ... and west end
const MF_BARS := [[Vector2(-464.2, -336.0), Vector2(-497.5, -325.0)], [Vector2(-545.4, -310.1), Vector2(-578.8, -300.1)]]
const MF_BAR_DEPTH := 13.0
const MF_WALL := Color("#d9ccc4")
const MF_BASE := Color("#b9aca3")
const MF_LIGHT := Color("#e7ded8")
const MF_ROOF := Color("#6b716f")
const MF_GLASS := Color("#3b4650")
const MF_DOOR := Color("#34393d")
func _find_mf() -> void:
	var outline := _landmark("Ministerstwo Finansów")
	if outline.size() < 3:
		return
	_add_site("mf", [outline])
	if not sites.is_empty() and sites[-1]["key"] == "mf":
		sites[-1]["ring"] = _simplify(outline, 1.8)


func _build_mf(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var h := MF_TOP
	var none := Color(0, 0, 0, 0)
	# The central entrance's frame: u along the south face (east to west), +v out into the court.
	_o = (MF_FACE_E + MF_FACE_W) * 0.5
	_a = (MF_FACE_W - MF_FACE_E).normalized()
	_b = Vector2(_a.y, -_a.x)
	var porch := _rect(0.0, 1.2, 13.0, 3.0)
	# windows first (7 cm proud), so the walls behind them stay whole
	_bays(ring, 1.0, 4.1, 3.6, 1.4, MF_GLASS, porch)
	_bays(ring, 5.5, 14.0, 3.6, 1.7, MF_GLASS, porch)
	_mode = M_STONE
	_prism(ring, g - 0.6, g + 4.6, MF_BASE, none, M_STONE)
	_prism(ring, g + 4.6, g + h, MF_WALL, MF_ROOF, M_STONE, M_STONE)
	# the string course over the rusticated floor, the cornice and the attic parapet
	var course := _largest(Geometry2D.offset_polygon(ring, 0.15, Geometry2D.JOIN_MITER))
	_prism(course, g + 4.6, g + 5.0, MF_LIGHT, MF_LIGHT, M_STONE, M_STONE)
	var eave := _largest(Geometry2D.offset_polygon(ring, 0.45, Geometry2D.JOIN_MITER))
	_prism(eave, g + h - 2.3, g + h - 1.6, MF_LIGHT, MF_LIGHT, M_STONE, M_STONE)
	_parapet(ring, g + h, 1.1, MF_LIGHT)
	# the central risalit: rusticated below, six pilasters, three doors, a raised attic
	_lbox(0.0, 0.45, 12.0, 1.95, g - 0.6, g + 4.6, MF_BASE, M_STONE, none)
	_lbox(0.0, 0.45, 12.0, 1.95, g + 4.6, g + h + 2.0, MF_WALL, M_STONE, none)
	_lbox(0.0, 0.5, 12.5, 2.45, g + h + 2.0, g + h + 2.8, MF_LIGHT, M_STONE, MF_LIGHT)
	_mode = M_GLASS
	for u: float in [-9.0, -4.5, 0.0, 4.5, 9.0]:
		_wall(_w(u - 0.85, 2.43), _w(u + 0.85, 2.43), g + 5.5, g + 14.0, _b, MF_GLASS, 0.1)
	for u: float in [-9.0, 9.0]:
		_wall(_w(u - 0.7, 2.43), _w(u + 0.7, 2.43), g + 1.0, g + 4.1, _b, MF_GLASS, 0.1)
	_mode = M_STONE
	for u: float in [-4.5, 0.0, 4.5]:
		_wall(_w(u - 1.2, 2.43), _w(u + 1.2, 2.43), g + 0.4, g + 4.0, _b, MF_DOOR)
	for u: float in [-11.25, -6.75, -2.25, 2.25, 6.75, 11.25]:
		_lbox(u, 2.75, 0.45, 0.35, g + 4.6, g + h + 2.0, MF_LIGHT, M_STONE, MF_LIGHT)
	for k in 3:
		_lbox(0.0, 2.4 + (3 - k) * 0.5, 10.0, (3 - k) * 0.5, g - 0.6, g + 0.18 * (k + 1), MF_LIGHT, M_STONE, MF_LIGHT)
	# the wings' south pavilions: hipped dark roofs over the transverse bars
	for bar: Array in MF_BARS:
		var a: Vector2 = bar[0]
		var b: Vector2 = bar[1]
		var e := (b - a).normalized()
		_a = e
		_b = Vector2(e.y, -e.x)
		_o = (a + b) * 0.5 - _b * (MF_BAR_DEPTH * 0.5)
		_hip(0.0, 0.0, a.distance_to(b) * 0.5 - 0.7, MF_BAR_DEPTH * 0.5 - 0.7, g + h + 1.1, 3.4, MF_ROOF.lightened(0.15))
	_collide(ring)


# --- Dom pod Orłami (F's photo, 2026-11-02) --------------------------------------------------------

## Dom pod Orłami, Jasna 1 (Jan Heurich, 1912-17, rebuilt 1948-50; the national cooperative council
## sits there): six storeys in mottled sandstone at the corner of Jasna and Zgoda, its front over
## the square that Złota's linear park opened in 2026. F's photo from the square: the front of seven
## bays between two round corner towers, each tower stepping up in three drums over the cornice to a
## bronze eagle with spread wings; a tall ground floor with big windows and two portals, four floors
## of mullioned windows, an attic band with a round window in a carved panel by each tower and the
## name in metal letters in the middle (a parody here), a low pediment with a flagpole. Built over
## the OpenStreetMap outline (the front wing on Zgoda, the Jasna wing, the west wing); heights
## from the photo's proportions (the towers' centres 31 m apart).
## Frame: u along the front from the west tower (u < 0) to the Jasna corner, +v out of the front.
const ORLY_O := Vector2(-824.9, 48.35)
const ORLY_A := Vector2(0.93706, -0.34917)
const ORLY_FRONT := 4.3         # the front wall's v (the outline's front wavers from 3.2 to 4.4)
const ORLY_TOWER_U := 15.6      # the towers' centres at u = ±this, v = 0
const ORLY_TOWER_R := 3.7
const ORLY_GROUND := 7.0        # the ground floor's top (the string course)
const ORLY_FLOOR := 3.9         # the four upper floors
const ORLY_CORNICE := 24.0      # the main cornice
const ORLY_WALL := Color("#cdb48a")
const ORLY_BASE := Color("#b99d72")
const ORLY_LIGHT := Color("#ddcca8")
const ORLY_ROOF := Color("#77706a")
const ORLY_GLASS := Color("#353b42")
const ORLY_DOOR := Color("#3a332c")
const ORLY_BRONZE := Color("#5e5548")
const ORLY_LETTERS := Color(0.3, 0.28, 0.25)   # dark metal letters (signs are lit day and night: kept dark)
const ORLY_WORDS := ["KRAJOWA", "RADA SPÓŁDZIELNI ORŁÓW"]


func _find_orly() -> void:
	var q := _landmark("Dom pod Orłami")
	if q.size() < 3:
		return
	_add_site("orly", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER)), Geometry2D.convex_hull(q)])
	if not sites.is_empty() and sites[-1]["key"] == "orly":
		sites[-1]["ring"] = _simplify(q, 0.3)


func _build_orly(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_o = ORLY_O
	_a = ORLY_A
	_b = Vector2(-_a.y, _a.x)   # out of the front (Zgoda, the square)
	# The front between the towers is one plane (the outline wavers 1 m there): a slab to v
	# ORLY_FRONT with its windows drawn by hand, seven bays; the outline's own windows skip it.
	var slab := _rect(0.0, ORLY_FRONT - 1.0, 12.0, 1.0)
	var skip := _rect(0.0, ORLY_FRONT - 1.0, 12.2, 3.0)
	# Windows first (7 cm proud), so the walls behind them stay whole.
	_bays(ring, 1.0, 6.0, 3.5, 2.2, ORLY_GLASS, skip)
	for k in 4:
		var y0 := ORLY_GROUND + ORLY_FLOOR * k + 0.6
		_bays(ring, y0, y0 + 2.5, 3.5, 1.9, ORLY_GLASS, skip)
	_prism(ring, g - 0.6, g + ORLY_GROUND, ORLY_BASE, none, M_STONE)
	_prism(ring, g + ORLY_GROUND, g + ORLY_CORNICE, ORLY_WALL, none, M_STONE, M_STONE)
	# The string course over the ground floor and the cornice.
	var course := _largest(Geometry2D.offset_polygon(ring, 0.15, Geometry2D.JOIN_MITER))
	_prism(course, g + ORLY_GROUND - 0.1, g + ORLY_GROUND + 0.3, ORLY_LIGHT, ORLY_LIGHT, M_STONE, M_STONE)
	var eave := _largest(Geometry2D.offset_polygon(ring, 0.45, Geometry2D.JOIN_MITER))
	_prism(eave, g + ORLY_CORNICE - 0.5, g + ORLY_CORNICE, ORLY_LIGHT, ORLY_LIGHT, M_STONE, M_STONE)
	# The roof a little over the cornice's top (a cap over a cap at one height keeps no hole).
	_mode = M_STONE
	_cap(ring, g + ORLY_CORNICE + 0.08, ORLY_ROOF)
	_parapet(ring, g + ORLY_CORNICE, 0.6, ORLY_LIGHT)
	# The front slab: its windows, then its base, wall, string course and cornice.
	var front := ORLY_FRONT + 0.07
	_mode = M_GLASS
	for u: float in [-10.5, -7.0, 0.0, 7.0, 10.5]:
		_wall(_w(u - 1.15, front), _w(u + 1.15, front), g + 0.9, g + 6.2, _b, ORLY_GLASS, 10.5 + u)
	for k in 4:
		var y0 := g + ORLY_GROUND + ORLY_FLOOR * k + 0.6
		for j in 7:
			var u := -10.5 + 3.5 * j
			_wall(_w(u - 0.95, front), _w(u + 0.95, front), y0, y0 + 2.5, _b, ORLY_GLASS, 10.5 + u)
	_mode = M_STONE
	_prism(slab, g - 0.6, g + ORLY_GROUND, ORLY_BASE, none, M_STONE)
	_prism(slab, g + ORLY_GROUND, g + ORLY_CORNICE - 0.5, ORLY_WALL, ORLY_LIGHT, M_STONE, M_STONE)
	_lbox(0.0, ORLY_FRONT - 0.9, 12.05, 1.05, g + ORLY_GROUND - 0.1, g + ORLY_GROUND + 0.3, ORLY_LIGHT, M_STONE, ORLY_LIGHT)
	_lbox(0.0, ORLY_FRONT - 0.85, 12.1, 1.15, g + ORLY_CORNICE - 0.5, g + ORLY_CORNICE + 0.05, ORLY_LIGHT, M_STONE, ORLY_LIGHT)
	# Two portals with their stone frames between the ground floor's windows.
	for u: float in [-3.5, 3.5]:
		_lbox(u, ORLY_FRONT + 0.25, 1.55, 0.25, g, g + 5.4, ORLY_LIGHT, M_STONE, ORLY_LIGHT)
		_wall(_w(u - 1.0, ORLY_FRONT + 0.58), _w(u + 1.0, ORLY_FRONT + 0.58), g, g + 4.4, _b, ORLY_DOOR)
	# The pediment over the seven bays and its flagpole.
	_orly_pediment(g)
	# The attic: a round window in a carved panel by each tower.
	for u: float in [-10.5, 10.5]:
		_mode = M_STONE
		_wall(_w(u - 1.6, front), _w(u + 1.6, front), g + 21.95, g + 23.45, _b, ORLY_BASE.darkened(0.08))
		var c := _w(u, front + 0.03)
		_disc(Vector3(c.x, g + 22.7, c.y), Vector3(_b.x, 0, _b.y), 0.66, 10, ORLY_LIGHT)
		c = _w(u, front + 0.06)
		_disc(Vector3(c.x, g + 22.7, c.y), Vector3(_b.x, 0, _b.y), 0.5, 10, ORLY_GLASS)
	# The name in two rows of metal letters over the middle bays.
	for k in ORLY_WORDS.size():
		var word: String = ORLY_WORDS[k]
		var mid := _w(0.0, ORLY_FRONT + 0.12)
		var scale := 0.65 / (Neon.ROW_H * Neon.PIXEL)
		signs.append([word, Vector3(mid.x, g + 22.75 - k * 0.8, mid.y), Vector3(_b.x, 0.0, _b.y), scale, ORLY_LETTERS])
	# The corner towers: windows round their fronts, then three drums over the cornice and the eagle.
	for side: float in [-1.0, 1.0]:
		_orly_tower(Vector2(side * ORLY_TOWER_U, 0.0), side, g, ring)
	_collide(ring)


## Where a ray from `from` along `dir` leaves the outline (the tower's real wall), or 3.7 m out.
func _orly_wall_at(from: Vector2, dir: Vector2, ring: PackedVector2Array) -> Vector2:
	var best := from + dir * ORLY_TOWER_R
	var far := 0.0
	for i in ring.size():
		var hit: Variant = Geometry2D.segment_intersects_segment(from, from + dir * 8.0, ring[i], ring[(i + 1) % ring.size()])
		if hit != null and (hit as Vector2).distance_to(from) > far:
			far = (hit as Vector2).distance_to(from)
			best = hit
	return best


func _orly_pediment(g: float) -> void:
	_mode = M_STONE
	var hw := 11.0
	var y := g + ORLY_CORNICE
	var at := func(u: float, yy: float) -> Vector3:
		var p := _w(u, ORLY_FRONT + 0.36)
		return Vector3(p.x, yy, p.y)
	var n := Vector3(_b.x, 0.0, _b.y)
	_tri(at.call(-hw, y), at.call(hw, y), at.call(0.0, y + 1.7), n, ORLY_WALL, Vector2(0, y - g), Vector2(hw * 2.0, y - g),
			Vector2(hw, y + 1.7 - g), y + 1.7 - g)
	for side: float in [-1.0, 1.0]:
		var e: Vector3 = at.call(side * hw, y)
		var apex: Vector3 = at.call(0.0, y + 1.7)
		var back := Vector3(-_b.x, 0.0, -_b.y) * 6.0
		var slope := (Vector3(_a.x, 0.0, _a.y) * side * 1.7 + Vector3.UP * hw).normalized()
		_quad(e, e + back, apex + back, apex, slope, ORLY_ROOF)
	var top: Vector3 = at.call(0.0, y + 1.7)
	_prism(_circle(Vector2(top.x, top.z) - _b * 0.4, 0.07, 5), top.y, top.y + 6.5, Color("#d9d9d4"), Color("#d9d9d4"), M_STONE, M_STONE)


func _orly_tower(c: Vector2, side: float, g: float, ring: PackedVector2Array) -> void:
	var at := _w(c.x, c.y)
	var r := ORLY_TOWER_R
	# Windows on the tower's outer three-quarter: from the front round to the side street.
	_mode = M_GLASS
	for k in 4:
		var y0 := g + ORLY_GROUND + ORLY_FLOOR * k + 0.5
		for deg: float in [20.0, 50.0, 80.0]:
			var ang := deg_to_rad(deg)
			var dir := (_a * side * cos(ang) + _b * sin(ang)).normalized()
			var p := _orly_wall_at(at, dir, ring) + dir * 0.07
			var tan := Vector2(-dir.y, dir.x)
			_wall(p - tan * 0.55, p + tan * 0.55, y0, y0 + 2.7, dir, ORLY_GLASS, deg)
	_mode = M_STONE
	# The drums over the cornice, each smaller, with a light rim; the eagle's plinth.
	var steps := [[r, ORLY_CORNICE, ORLY_CORNICE + 1.2], [r * 0.82, ORLY_CORNICE + 1.2, ORLY_CORNICE + 2.1],
			[r * 0.62, ORLY_CORNICE + 2.1, ORLY_CORNICE + 2.8], [r * 0.34, ORLY_CORNICE + 2.8, ORLY_CORNICE + 3.4]]
	for s: Array in steps:
		_prism(_circle(at, float(s[0]), 14), g + float(s[1]), g + float(s[2]), ORLY_WALL.lightened(0.04), ORLY_LIGHT, M_STONE, M_STONE)
	# The bronze eagle: body, head, and wings spread along the front, raised at the tips.
	var y := g + ORLY_CORNICE + 3.4
	var body := _circle(at, 0.55, 6)
	_prism(body, y, y + 1.6, ORLY_BRONZE, ORLY_BRONZE, M_STONE, M_STONE)
	_prism(_circle(at + _b * 0.45, 0.28, 5), y + 1.6, y + 2.1, ORLY_BRONZE, ORLY_BRONZE, M_STONE, M_STONE)
	for w: float in [-1.0, 1.0]:
		var root := at + _a * w * 0.35
		var tip := at + _a * w * 2.7 - _b * 0.3
		var n := Vector3(_b.x, 0.0, _b.y)
		_quad(Vector3(root.x, y + 0.7, root.y), Vector3(tip.x, y + 1.8, tip.y), Vector3(tip.x, y + 2.7, tip.y),
				Vector3(root.x, y + 1.55, root.y), n, ORLY_BRONZE)


# --- Hotel Warszawa (the 1933 Prudential) -------------------------------------------------------

## City inventory item 4 (2026-11-02; spec docs/landmarks/specs/hotel_warszawa.md, from the Mac's
## photos and orthophoto in refs/hotel_warszawa). Marcin Weinfeld's stone tower on Plac
## Powstańców: a wide shaft of eight full-height pilasters and seven columns of small deep
## windows, a heavy cornice, a set-back two-storey crown with masts, a low two-storey base with a
## three-opening portal under the word WARSZAWA, and two six-storey wings flush with the front.
## Behind it a U of 25 m wings round a low glass-roofed hall. Local frame: u along the front
## (north, towards Świętokrzyska), v out of the front (east, onto the square); the shaft's front
## is v = 0, the outline's parts (centrum.json) give every rectangle below.
const HW_O := Vector2(-770.5, -190.0)
const HW_A := Vector2(-0.33035, -0.94386)   # along the front, south to north
const HW_SHAFT := Rect2(-10.5, -15.6, 21.7, 15.6)   # u0, v0, width, depth (part 3482)
const HW_CROWN := Rect2(-8.0, -14.4, 17.2, 13.0)    # the set-back crown box (part 3483)
const HW_WING_N := Rect2(11.2, -5.5, 6.1, 6.4)      # the front wings (parts 11860, 11865)
const HW_WING_S := Rect2(-16.5, -5.0, 6.0, 5.6)
const HW_COURT := Rect2(-8.6, -47.4, 11.8, 31.8)    # the low hall in the middle (part 11857)
const HW_BASE_TOP := 8.6     # the ground floor (5 m) and the low base storey
const HW_STOREY := 3.8
const HW_ROWS := 12          # the shaft's storeys over the base
const HW_CORNICE := 54.2     # HW_BASE_TOP + 12 storeys
const HW_CROWN_TOP := 66.2
const HW_BACK := 25.0
const HW_STONE := Color("#dccaa6")
const HW_PIER := Color("#ebdfc4")
const HW_SHADE := Color("#cdbd9e")
const HW_GLASS := Color("#5f7079")
const HW_DARK := Color("#3c3733")
const HW_COPPER := Color("#a5583f")
const HW_ROOF := Color("#55504a")
const HW_MEMBRANE := Color("#cfcbc4")
const HW_HALL_GLASS := Color("#7f9faf")
const HW_GLOW := Color("#dcc59a")    # the pilasters' and cornices' floodlight strips (M_LAMP)
const HW_LETTERS := Color(0.45, 0.43, 0.4)


func _find_hotel_warszawa() -> void:
	var q := _landmark("Hotel Warszawa")
	if q.size() < 3:
		return
	_add_site("hotel_warszawa", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "hotel_warszawa":
		sites[-1]["ring"] = _simplify(q, 0.3)


## Punched windows on one local face: the face runs along u (dir 1) at v = `v` facing +v (or −v
## with out = −1), or along v at u = `v` facing ±u when `side`; `cols` centres, `rows` sill
## heights over the ground, each pane w × h, 7 cm proud.
func _hw_panes(side: bool, at: float, out: float, cols: Array, rows: Array, w: float, h: float, col: Color) -> void:
	var keep := _mode
	_mode = M_GLASS
	var n := _b * out if not side else _a * out
	for c: float in cols:
		for y0: float in rows:
			var p0: Vector2
			var p1: Vector2
			if side:
				p0 = _w(at + out * 0.07, c - w * 0.5)
				p1 = _w(at + out * 0.07, c + w * 0.5)
			else:
				p0 = _w(c - w * 0.5, at + out * 0.07)
				p1 = _w(c + w * 0.5, at + out * 0.07)
			_wall(p0, p1, _g + y0, _g + y0 + h, n, col, c * 3.0)
	_mode = keep


func _build_hotel_warszawa(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_o = HW_O
	_a = HW_A
	_b = Vector2(-_a.y, _a.x)   # east, onto the square
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var s := HW_SHAFT
	var u0 := s.position.x
	var u1 := s.position.x + s.size.x
	var vb := s.position.y
	# Windows first (7 cm proud), so the walls behind them stay whole.
	var rows := []
	for r in HW_ROWS:
		rows.append(HW_BASE_TOP + 0.9 + HW_STOREY * r)
	var high := []   # the rows over the back wings' roofs (the side and back faces)
	for y: float in rows:
		if y > HW_BACK + 0.3:
			high.append(y)
	var front_cols := _spread(u0, u1, 7)
	_hw_panes(false, 0.0, 1.0, front_cols, rows, 1.4, 1.8, HW_GLASS)
	_hw_panes(false, 0.0, 1.0, front_cols, [5.7], 1.3, 1.6, HW_GLASS)   # the base storey's small row
	_hw_panes(false, vb, -1.0, front_cols, high, 1.4, 1.8, HW_GLASS)
	_hw_panes(true, u1, 1.0, _spread(vb, 0.0, 6), high, 1.4, 1.8, HW_GLASS)
	_hw_panes(true, u0, -1.0, _spread(vb, 0.0, 6), high, 1.4, 1.8, HW_GLASS)
	# The shaft.
	_prism(_lrect(s), g - 0.6, g + HW_CORNICE, HW_STONE, none, M_STONE)
	# The eight front pilasters (0.6 m wide, 0.3 m proud), base to cornice, each with a floodlight
	# strip down its face; the doubled strips at the corners on the sides.
	var pitch := s.size.x / 7.0
	for k in 8:
		var u := u0 + pitch * k
		_lbox(u, 0.2, 0.45, 0.2, g + HW_BASE_TOP - 3.6, g + HW_CORNICE, HW_PIER, M_STONE, HW_PIER)
		_hw_glow_strip(Vector2(u, 0.42), Vector2(0.0, 1.0), g + HW_BASE_TOP, g + HW_CORNICE - 0.4)
	for side: float in [-1.0, 1.0]:
		var uf := u1 if side > 0.0 else u0
		for k in 7:
			var v := vb + s.size.y * k / 6.0
			_lbox(uf + side * 0.15, v, 0.15, 0.3, g + HW_BACK, g + HW_CORNICE, HW_PIER, M_STONE, HW_PIER)
	# The string course over the base, the heavy cornice and its lit edge. F's look check
	# (2026-11-03): the cornice projects clearly, so it steps out twice (a fascia, then the slab
	# 1.5 m proud) over a dark shadow line under the slab.
	_prism(_lrect(s, 0.32), g + HW_BASE_TOP - 0.25, g + HW_BASE_TOP + 0.2, HW_SHADE, HW_SHADE, M_STONE, M_STONE)
	_hw_cornice(s, g + HW_CORNICE, 1.5, 1.6)
	_mode = M_LAMP
	_prism(_lrect(s, 1.58), g + HW_CORNICE + 1.35, g + HW_CORNICE + 1.55, HW_GLOW, none, M_LAMP)
	_mode = M_STONE
	# The crown: two storeys of five bays between six pilasters, an attic, the top cornice.
	var c := HW_CROWN
	var cy := HW_CORNICE + 1.6
	var crows := [cy + 1.0, cy + 4.8]
	var cc := _spread(c.position.x, c.position.x + c.size.x, 5)
	var cv := _spread(c.position.y, c.position.y + c.size.y, 4)
	_hw_panes(false, c.position.y + c.size.y, 1.0, cc, crows, 1.4, 1.9, HW_GLASS)
	_hw_panes(false, c.position.y, -1.0, cc, crows, 1.4, 1.9, HW_GLASS)
	_hw_panes(true, c.position.x + c.size.x, 1.0, cv, crows, 1.4, 1.9, HW_GLASS)
	_hw_panes(true, c.position.x, -1.0, cv, crows, 1.4, 1.9, HW_GLASS)
	_prism(_lrect(c), g + cy, g + HW_CROWN_TOP, HW_STONE, none, M_STONE)
	var cf := c.position.y + c.size.y
	for k in 6:
		var u := c.position.x + c.size.x * k / 5.0
		_lbox(u, cf + 0.12, 0.28, 0.12, g + cy, g + HW_CROWN_TOP, HW_PIER, M_STONE, HW_PIER)
		_hw_glow_strip(Vector2(u, cf + 0.31), Vector2(0.0, 1.0), g + cy + 0.3, g + HW_CROWN_TOP - 0.3)
	_hw_cornice(c, g + HW_CROWN_TOP, 1.1, 1.2)
	_prism(_lrect(c, 1.18), g + HW_CROWN_TOP + 0.95, g + HW_CROWN_TOP + 1.15, HW_GLOW, none, M_LAMP)
	_mode = M_STONE
	# The roof: the lift head, two white masts and the flagpole with the white-and-red flag.
	var top := g + HW_CROWN_TOP + 1.2
	_lbox(2.5, -9.0, 2.2, 1.8, top, top + 2.6, HW_SHADE, M_STONE, HW_ROOF)
	for m: Vector2 in [Vector2(-5.5, -4.0), Vector2(6.5, -12.0)]:
		var p := _w(m.x, m.y)
		_beam(Vector3(p.x, top, p.y), Vector3(p.x, top + 8.0, p.y), 0.22, Color("#e6e6e2"))
	var fp := _w(0.6, -2.6)
	_beam(Vector3(fp.x, top, fp.y), Vector3(fp.x, top + 6.5, fp.y), 0.12, Color("#e6e6e2"))
	_hw_flag(fp, top + 5.0, 2.4)
	# The two front wings, six storeys, one column of tall narrow windows by their outer edges.
	# F's look check (2026-11-03): the wings and the shaft stand on one stone base. The wings rise
	# to the back wings' height (one mass with them, no step), and a granite plinth, the ground
	# floor's stone band and its string course run unbroken across the whole front, wings and
	# shaft; each wing's top cornice turns the corner onto its side.
	var fu0 := HW_WING_S.position.x
	var fu1 := HW_WING_N.position.x + HW_WING_N.size.x
	var fv := 1.0
	_lbox((fu0 + fu1) * 0.5, fv * 0.5 - 0.05, (fu1 - fu0) * 0.5 + 0.15, fv * 0.5 + 0.05, g - 0.6, g + 0.9,
			Color("#b9b09f"), M_STONE, Color("#c4bba9"))
	for side: Array in [[fu0, -10.5], [11.2, fu1]]:
		# The ground floor's stone face over each wing up to the string course, flush with the
		# portal's frame, and the course itself, both carried across the joint into the shaft.
		var su0: float = side[0]
		var su1: float = side[1]
		_lbox((su0 + su1) * 0.5, fv * 0.5, (su1 - su0) * 0.5 + 0.6, fv * 0.5, g + 0.9, g + 5.2, HW_PIER, M_STONE, HW_SHADE)
	_lbox((fu0 + fu1) * 0.5, fv * 0.5 + 0.1, (fu1 - fu0) * 0.5 + 0.2, fv * 0.5 + 0.1, g + 5.2, g + 5.65, HW_SHADE,
			M_STONE, HW_SHADE.darkened(0.05))
	for w: Rect2 in [HW_WING_N, HW_WING_S]:
		var outer := w.position.x + w.size.x - 1.6 if w.position.x > 0.0 else w.position.x + 1.6
		var wf := w.position.y + w.size.y
		var tall := []
		for k in 4:
			tall.append(HW_BASE_TOP + 0.6 + HW_STOREY * k)
		_hw_panes(false, wf, 1.0, [outer], tall, 1.1, 2.6, HW_GLASS)
		_hw_panes(false, 1.0, 1.0, [outer], [1.4], 1.6, 3.0, HW_GLASS)   # on the base's stone face
		_prism(_lrect(w), g - 0.6, g + HW_BACK, HW_STONE, HW_MEMBRANE, M_STONE, M_STONE)
		_prism(_lrect(w, 0.35), g + HW_BACK - 0.7, g + HW_BACK, HW_PIER, none, M_STONE)
		_parapet(_lrect(w, 0.35), g + HW_BACK, 0.45, HW_SHADE)
	# The portal: a stone frame proud of the base with three openings, each in a darker reveal,
	# under a projecting cornice slab with its shadow line, WARSZAWA cut over it, a copper door
	# either side, the shop-tall ground-floor windows beyond (F's look check: refine the portal).
	var pf := 1.3
	_mode = M_STONE
	for op: Vector3 in [Vector3(0.4, 1.6, 4.2), Vector3(-3.0, 0.8, 3.5), Vector3(3.8, 0.8, 3.5)]:
		_wall(_w(op.x - op.y - 0.25, pf + 0.03), _w(op.x + op.y + 0.25, pf + 0.03), g, g + op.z + 0.25, _b, HW_SHADE.darkened(0.25))
		_wall(_w(op.x - op.y, pf + 0.07), _w(op.x + op.y, pf + 0.07), g, g + op.z, _b, HW_DARK)
	_lbox(0.4, pf * 0.5, 4.7, pf * 0.5, g - 0.6, g + 5.0, HW_PIER, M_STONE, HW_SHADE)
	_lbox(0.4, pf * 0.5 + 0.25, 5.1, pf * 0.5 + 0.25, g + 5.0, g + 5.5, HW_PIER, M_STONE, HW_SHADE)
	_wall(_w(-4.7, pf + 0.52), _w(5.5, pf + 0.52), g + 4.86, g + 5.0, _b, HW_DARK.lightened(0.15))
	# F's photos (2026-11-08): the end doors are tall copper-framed panels (about 2.3 m wide and 5 m
	# high, the 2018 restoration) around a dark glass door with a bronze handle, and the centre
	# opening holds a slim copper door with a lit slit.
	for d: float in [-6.6, 7.6]:
		_wall(_w(d - 1.15, 0.08), _w(d + 1.15, 0.08), g, g + 5.0, _b, HW_COPPER)
		_wall(_w(d - 0.7, 0.14), _w(d + 0.7, 0.14), g, g + 3.4, _b, HW_DARK)
		_wall(_w(d - 0.05, 0.17), _w(d + 0.05, 0.17), g + 0.9, g + 2.1, _b, HW_COPPER.lightened(0.3))
	_wall(_w(-0.2, pf + 0.1), _w(1.0, pf + 0.1), g, g + 3.9, _b, HW_COPPER)
	_mode = M_LAMP
	_wall(_w(0.3, pf + 0.13), _w(0.5, pf + 0.13), g + 0.6, g + 3.4, _b, HW_GLOW)
	_mode = M_STONE
	_hw_panes(false, 0.0, 1.0, [-8.9, 9.7], [0.9], 1.8, 3.4, HW_GLASS)
	var scale := 0.42 / (Neon.ROW_H * Neon.PIXEL)
	var mid := _w(0.4, pf + 0.1)
	signs.append(["WARSZAWA", Vector3(mid.x, g + 4.55, mid.y), Vector3(_b.x, 0.0, _b.y), scale, HW_LETTERS])
	# A granite step before the portal and three flagpoles on the square, north of it.
	_lbox(0.4, pf + 1.2, 6.0, 1.2, g - 0.3, g + 0.14, Color("#bdb6a8"), M_STONE, Color("#c9c2b3"))
	for k in 3:
		var p := _w(12.5 + 1.6 * k, 4.0)
		_beam(Vector3(p.x, g, p.y), Vector3(p.x, g + 9.0, p.y), 0.12, Color("#e6e6e2"))
		_hw_flag(p, g + 7.6, 1.25)
	# Behind: the U of 25 m wings (Świętokrzyska's, the west end, the south one) round the low hall.
	var back := PackedVector2Array()
	for q: Vector2 in [Vector2(-16.1, -5.0), Vector2(-10.5, -5.0), Vector2(-10.5, -15.6), Vector2(-8.6, -15.6),
			Vector2(-8.6, -47.4), Vector2(3.2, -47.4), Vector2(3.2, -15.6), Vector2(11.2, -15.6), Vector2(11.2, -5.5),
			Vector2(17.4, -5.5), Vector2(18.8, -54.4), Vector2(-16.1, -54.5)]:
		back.append(_w(q.x, q.y))
	var back_rows := []
	for k in 6:
		back_rows.append(3.6 + 3.6 * k)
	_hw_back_panes(back, back_rows)
	_prism(back, g - 0.6, g + HW_BACK, HW_STONE, HW_MEMBRANE, M_STONE, M_STONE)
	_parapet(back, g + HW_BACK, 0.5, HW_SHADE)
	for h: Vector2 in [Vector2(14.5, -20.0), Vector2(14.5, -32.0), Vector2(-12.5, -26.0), Vector2(-3.0, -51.0)]:
		var hp := _w(h.x, h.y)
		_prism(_circle(hp, 0.9, 8), g + HW_BACK, g + HW_BACK + 1.3, Color("#9a9a96"), Color("#7d7d79"), M_STONE, M_STONE)
	# The hall: low stone walls under a glass ridge roof.
	var ct := HW_COURT
	_prism(_lrect(ct), g - 0.6, g + 7.5, HW_SHADE, none, M_STONE)
	var cu0 := ct.position.x
	var cu1 := ct.position.x + ct.size.x
	var cm := (cu0 + cu1) * 0.5
	var v0 := ct.position.y
	var v1 := ct.position.y + ct.size.y
	for half: Array in [[cu0, cm], [cu1, cm]]:
		var ea: Vector2 = _w(half[0], v0)
		var eb: Vector2 = _w(half[0], v1)
		var ra: Vector2 = _w(half[1], v0)
		var rb: Vector2 = _w(half[1], v1)
		# The slope rises towards the ridge: its normal leans back the other way.
		var lean := -1.0 if half[0] < cm else 1.0
		var up := Vector3(_a.x * lean * 0.3, 1.0, _a.y * lean * 0.3).normalized()
		_mode = M_GLASS_ROOF
		_quad(Vector3(ea.x, g + 7.5, ea.y), Vector3(eb.x, g + 7.5, eb.y), Vector3(rb.x, g + 9.3, rb.y),
				Vector3(ra.x, g + 9.3, ra.y), up, HW_HALL_GLASS)
	# The hall roof's two gable ends.
	_mode = M_STONE
	for v: float in [v0, v1]:
		var l := _w(cu0, v)
		var r := _w(cu1, v)
		var m := _w(cm, v)
		var nv := -_b if v == v0 else _b
		_tri(Vector3(l.x, g + 7.5, l.y), Vector3(r.x, g + 7.5, r.y), Vector3(m.x, g + 9.3, m.y), Vector3(nv.x, 0.0, nv.y), HW_SHADE,
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_mode = M_STONE
	_collide(ring)


## A projecting stone cornice round a local rectangle at y: a fascia half out, then the slab
## `out` m proud and `h` tall, a dark shadow line under the slab's lip so it reads from the street.
func _hw_cornice(r: Rect2, y: float, out: float, h: float) -> void:
	var none := Color(0, 0, 0, 0)
	_prism(_lrect(r, out * 0.45), y, y + h * 0.4, HW_SHADE, none, M_STONE)
	_prism(_lrect(r, out), y + h * 0.4, y + h, HW_PIER, HW_SHADE, M_STONE, M_STONE)
	_prism(_lrect(r, out - 0.05), y + h * 0.4 - 0.18, y + h * 0.4, HW_DARK.lightened(0.2), none, M_STONE)
	_mode = M_STONE


## A floodlight strip (M_LAMP) down a pilaster's face: 0.3 m wide at local `at`, facing `out`.
func _hw_glow_strip(at: Vector2, out: Vector2, y0: float, y1: float) -> void:
	var keep := _mode
	_mode = M_LAMP
	var n := _a * out.x + _b * out.y
	var t := Vector2(-n.y, n.x)
	var c := _w(at.x, at.y)
	_wall(c - t * 0.15, c + t * 0.15, y0, y1, n, HW_GLOW)
	_mode = keep


## A small white-over-red flag off a pole at `p`, its top at `y`.
func _hw_flag(p: Vector2, y: float, flen: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var d := _a
	var n := Vector3(_b.x, 0.0, _b.y)
	var q := p + d * flen
	var h := flen * 0.32
	_quad(Vector3(p.x, y, p.y), Vector3(q.x, y, q.y), Vector3(q.x, y - h, q.y), Vector3(p.x, y - h, p.y), n, Color("#f2f2ee"))
	_quad(Vector3(p.x, y - h, p.y), Vector3(q.x, y - h, q.y), Vector3(q.x, y - 2.0 * h, q.y), Vector3(p.x, y - 2.0 * h, p.y), n,
			Color("#c8203a"))
	_mode = keep


## Rows of small windows round the back wings' ring, on every edge that faces the street or the
## hall (an edge against the shaft or a front wing is skipped; over the hall, from its roof up).
func _hw_back_panes(back: PackedVector2Array, rows: Array) -> void:
	var keep := _mode
	_mode = M_GLASS
	var hidden := [_lrect(HW_SHAFT, 0.5), _lrect(HW_WING_N, 0.5), _lrect(HW_WING_S, 0.5)]
	var hall := _lrect(HW_COURT, 0.5)
	var along := 0.0
	for i in back.size():
		var a := back[i]
		var b := back[(i + 1) % back.size()]
		var length := a.distance_to(b)
		var e := (b - a) / length
		var out := _out(back, a, b)
		var probe := (a + b) * 0.5 + out * 1.0
		var skip := false
		for r: PackedVector2Array in hidden:
			if Geometry2D.is_point_in_polygon(probe, r):
				skip = true
		var n := floori((length - 1.0) / 3.2)
		if skip or n < 1:
			along += length
			continue
		var over_hall := Geometry2D.is_point_in_polygon(probe, hall)
		var t0 := (length - n * 3.2) * 0.5 + 1.6
		for k in n:
			var p := a + e * (t0 + k * 3.2) + out * 0.07
			for y0: float in rows:
				if over_hall and y0 < 8.2:
					continue
				_wall(p - e * 0.65, p + e * 0.65, _g + y0, _g + y0 + 1.8, out, HW_GLASS, along + t0 + k * 3.2)
		along += length
	_mode = keep


# --- Cedet (the 1951 Central Department Store) --------------------------------------------------

## City inventory item 4 (2026-11-02; spec docs/landmarks/specs/cedet.md, from the Mac's photos and
## orthophoto in refs/cedet). Ihnatowicz and Romański's department store at Al. Jerozolimskie and
## Krucza, rebuilt in 2018: a tall open ground floor of granite piers and recessed shop glass, five
## storeys of continuous ribbon glass between cream rounded floor slabs, rounded street corners, a
## ribbed cream cornice, a set-back glass pavilion on the roof whose roof plate sweeps up into two
## wings at its ends, and the steel loop with its arrow on the avenue front (blue neon at night).
## Local frame: u along Jerozolimskie (west to east), v out of the front (south, onto the avenue);
## the corners are the mapped outline's (centrum.json "Cedet"), straightened.
const CD_O := Vector2(-480.85, 314.3)
const CD_A := Vector2(0.94992, -0.31249)
## The outline's corners (local); a third value rounds that corner to that radius.
const CD_RING := [Vector3(-36.0, 1.8, 11.0), Vector3(36.4, 0.9, 4.0), Vector3(32.2, -26.6, 0.0), Vector3(31.0, -28.6, 0.0),
		Vector3(16.0, -28.6, 0.0), Vector3(15.8, -40.3, 0.0), Vector3(19.5, -40.4, 0.0), Vector3(-2.4, -67.2, 0.0),
		Vector3(-26.3, -67.1, 0.0), Vector3(-30.1, -39.6, 0.0), Vector3(-16.6, -39.8, 0.0), Vector3(-16.0, -28.0, 0.0),
		Vector3(-31.0, -27.7, 0.0), Vector3(-32.3, -26.0, 0.0)]
## Heights (F's look check, 2026-11-03: 3.7 m glazed storeys over a taller ground floor; the LoD2
## eave is 26.7 m over the pavement, so 6.7 + 5 x 3.7 + the 1.5 m cornice meets it).
const CD_GROUND := 6.7       # the open ground floor's height
const CD_STOREY := 3.7       # five glazed department-store storeys
const CD_FLOORS := 5
const CD_CORNICE := 1.5
const CD_PIER_STEP := 7.2
## The crown (local u, v; LoD2: the roof storey to ~29.5 m, the wings' tips ~31.5 m at u +-30).
const CD_PAV := Rect2(-17.0, -25.6, 34.0, 25.0)    # the recessed pavilion's glass
const CD_PLATE_R := Rect2(-19.0, -27.4, 38.0, 28.6)  # its roof plate, 2 m over the glass
const CD_PAV_H := 2.9        # the pavilion's glass storey over the roof deck
const CD_PLATE_T := 0.45     # the plate's (and the wings') thickness
const CD_WING := 11.0        # each wing's reach beyond the plate (to u +-30)
const CD_WING_RISE := 2.4    # how far its tip sweeps up over the plate
const CD_SLAB := Color("#e6dfcf")
const CD_SLAB_SHADE := Color("#cfc8b8")
const CD_GLASS := Color("#2e4660")
const CD_SHOP := Color("#28303a")
const CD_FRAME := Color("#4a4742")
const CD_GRANITE := Color("#b9b2a4")
const CD_ROOF := Color("#6a6f76")
const CD_PAVILION := Color("#2a3340")
const CD_PLATE := Color("#d9d4c8")
const CD_UNDER := Color("#2f3033")   # the plate's and wings' undersides, in their own shadow
const CD_SHADOW := Color("#3e4248")  # the deck under the wings
const CD_PLANT := Color("#a9adb0")
const CD_LOOP := Color("#7a7264")    # muted metallic grey-bronze by day (F, 2026-11-03); blue neon at night


func _find_cedet() -> void:
	var q := _landmark("Cedet")
	if q.size() < 3:
		return
	_add_site("cedet", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "cedet":
		sites[-1]["outline"] = q


## A ring from local corners, each Vector3(u, v, r) rounded to radius r (an arc of 6 pieces).
func _rounded_ring(corners: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := corners.size()
	for i in n:
		var c3: Vector3 = corners[i]
		var c := Vector2(c3.x, c3.y)
		if c3.z <= 0.0:
			out.append(_w(c.x, c.y))
			continue
		var p3: Vector3 = corners[(i - 1 + n) % n]
		var n3: Vector3 = corners[(i + 1) % n]
		var d1 := (Vector2(p3.x, p3.y) - c).normalized()
		var d2 := (Vector2(n3.x, n3.y) - c).normalized()
		var half := d1.angle_to(d2) * 0.5
		var t := c3.z / tan(absf(half))
		var centre := c + (d1 + d2).normalized() * c3.z / sin(absf(half))
		var a0 := c + d1 * t
		var a1 := c + d2 * t
		var ang0 := (a0 - centre).angle()
		var sweep := wrapf((a1 - centre).angle() - ang0, -PI, PI)
		for k in 7:
			var p := centre + Vector2.from_angle(ang0 + sweep * k / 6.0) * c3.z
			out.append(_w(p.x, p.y))
	return out


## The ring moved `d` metres out (in when negative), corner by corner (a mitre at each), so its
## corners stay matched with the ring's.
func _miter(ring: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := ring.size()
	for i in n:
		var p := ring[(i - 1 + n) % n]
		var c := ring[i]
		var q := ring[(i + 1) % n]
		var n1 := _out(ring, p, c)
		var n2 := _out(ring, c, q)
		var m := (n1 + n2).normalized()
		var k := maxf(m.dot(n1), 0.35)
		out.append(c + m * d / k)
	return out


func _build_cedet(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_o = CD_O
	_a = CD_A
	_b = Vector2(-_a.y, _a.x)   # south, onto the avenue
	var ring := _rounded_ring(CD_RING)
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var top := CD_GROUND + CD_STOREY * CD_FLOORS
	# The ground floor: shop glass two metres back under the first slab, granite piers on the line.
	var shop := _miter(ring, -1.8)
	_prism(shop, g - 0.6, g + CD_GROUND, CD_SHOP, none, M_GLASS)
	_mode = M_STONE
	_strip(shop, ring, g + CD_GROUND - 0.02, CD_SLAB_SHADE, true)
	# Piers and bay mullions along the store's walls (the south wing's: the avenue, Krucza and the
	# east end), one every 7.2 m.
	var bays: Array[Vector3] = []   # x, z of a bay line and its edge's index
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 6.0 or _local((a + b) * 0.5).y < -29.0:
			continue
		var e := (b - a) / length
		var o := _out(ring, a, b)
		var n := floori(length / CD_PIER_STEP)
		var t0 := (length - n * CD_PIER_STEP) * 0.5
		for k in n + 1:
			var p := a + e * (t0 + CD_PIER_STEP * k)
			var c := p - o * 0.55
			var pier := PackedVector2Array([c - e * 0.5 - o * 0.5, c + e * 0.5 - o * 0.5, c + e * 0.5 + o * 0.5, c - e * 0.5 + o * 0.5])
			_prism(pier, g - 0.6, g + CD_GROUND - 0.02, CD_GRANITE, none, M_STONE)
			# The mullion between bays over it, 0.3 m wide and 8 cm proud of the glass.
			_wall(p - e * 0.15 + o * 0.08, p + e * 0.15 + o * 0.08, g + CD_GROUND, g + top, o, CD_FRAME)
	# The glass storeys, then a cream rounded slab at every floor (0.35 m proud, 0.5 m tall).
	_prism(ring, g + CD_GROUND, g + top, CD_GLASS, none, M_GLASS)
	var lip := _miter(ring, 0.35)
	for k in CD_FLOORS:
		var y := g + CD_GROUND + CD_STOREY * k
		_prism(lip, y - 0.12, y + 0.4, CD_SLAB, none, M_STONE)
		_strip(ring, lip, y + 0.4, CD_SLAB)
		_strip(ring, lip, y - 0.12, CD_SLAB_SHADE, true)
	# The ribbed cornice and the roof.
	var crown := _miter(ring, 0.25)
	_prism(crown, g + top, g + top + CD_CORNICE, CD_SLAB, CD_ROOF, M_STONE, M_STONE)
	var roof := g + top + CD_CORNICE
	# The recessed pavilion (F, 2026-11-03): its dark glass storey 2 m back under a cream roof plate,
	# whose shaded soffit reads as the recess from the street.
	var pc := CD_PAV.get_center()
	var pav := _rect(pc.x, pc.y, CD_PAV.size.x * 0.5, CD_PAV.size.y * 0.5)
	_prism(pav, roof, roof + CD_PAV_H, CD_PAVILION, none, M_GLASS)
	var y_pl := roof + CD_PAV_H
	var r0 := CD_PLATE_R.position
	var r1 := CD_PLATE_R.end
	var plate := _rect(CD_PLATE_R.get_center().x, CD_PLATE_R.get_center().y, CD_PLATE_R.size.x * 0.5, CD_PLATE_R.size.y * 0.5)
	_prism(plate, y_pl, y_pl + CD_PLATE_T, CD_PLATE, CD_PLATE, M_STONE, M_STONE)
	_mode = M_STONE
	_strip(pav, plate, y_pl - 0.01, CD_UNDER, true)
	# The two wings: the plate's ends sweep up (flat at first, then steeper) to u +-30, open
	# underneath. Top, a dark underside and the tip's edge, in four pieces each.
	for side: float in [-1.0, 1.0]:
		var u_in := r1.x if side > 0.0 else r0.x
		var prev_u := u_in
		var prev_y := y_pl + CD_PLATE_T
		for k in range(1, 5):
			var t := float(k) / 4.0
			var u := u_in + side * CD_WING * t
			var y := y_pl + CD_PLATE_T + CD_WING_RISE * pow(t, 1.7)
			var ia := _w(prev_u, r0.y)
			var ib := _w(prev_u, r1.y)
			var oa := _w(u, r0.y)
			var ob := _w(u, r1.y)
			var slope := Vector2(u - prev_u, y - prev_y).normalized()
			var up := Vector3(-_a.x * slope.y * side, absf(slope.x), -_a.y * slope.y * side).normalized()
			var dt := CD_PLATE_T
			_quad(Vector3(ia.x, prev_y, ia.y), Vector3(ib.x, prev_y, ib.y), Vector3(ob.x, y, ob.y), Vector3(oa.x, y, oa.y), up, CD_PLATE)
			_quad(Vector3(ia.x, prev_y - dt, ia.y), Vector3(ib.x, prev_y - dt, ib.y), Vector3(ob.x, y - dt, ob.y),
					Vector3(oa.x, y - dt, oa.y), -up, CD_UNDER)
			# The wing's two long edges (front and back), so it has a thickness from the avenue.
			for e: int in 2:
				var vv := r1.y if e == 0 else r0.y
				var pa := _w(prev_u, vv)
				var pb := _w(u, vv)
				var n2 := _b if e == 0 else -_b
				_quad(Vector3(pa.x, prev_y - dt, pa.y), Vector3(pb.x, y - dt, pb.y), Vector3(pb.x, y, pb.y), Vector3(pa.x, prev_y, pa.y),
						Vector3(n2.x, 0.0, n2.y), CD_SLAB_SHADE)
			prev_u = u
			prev_y = y
		var ta := _w(prev_u, r0.y)
		var tb := _w(prev_u, r1.y)
		_quad(Vector3(ta.x, prev_y - CD_PLATE_T, ta.y), Vector3(tb.x, prev_y - CD_PLATE_T, tb.y), Vector3(tb.x, prev_y, tb.y),
				Vector3(ta.x, prev_y, ta.y), Vector3(_a.x * side, 0.0, _a.y * side), CD_PLATE)
		# The wing's shadow on the roof deck below it (the sun's from the south, so it falls a
		# little north), a shade that reads from the helicopter as well as from the street.
		var s0 := minf(u_in, prev_u)
		var s1 := maxf(u_in, prev_u)
		var sh := _rect((s0 + s1) * 0.5, (r0.y + r1.y) * 0.5 - 1.0, (s1 - s0) * 0.5, (r1.y - r0.y) * 0.5 - 0.6)
		_quad(Vector3(sh[0].x, roof + 0.06, sh[0].y), Vector3(sh[1].x, roof + 0.06, sh[1].y), Vector3(sh[2].x, roof + 0.06, sh[2].y),
				Vector3(sh[3].x, roof + 0.06, sh[3].y), Vector3.UP, CD_SHADOW)
	# Roof plant (LoD2: a screened box at the back of the pavilion to ~35 m; the orthophoto's fans
	# on the north wing).
	_lbox(0.0, -22.6, 14.0, 3.6, y_pl + CD_PLATE_T, roof + 8.3, CD_PLANT, M_STONE, Color("#8e9296"))
	for k in 6:
		var fp := _w(-16.0 + 3.2 * (k % 3), -50.0 - 3.2 * (k / 3))
		_prism(_circle(fp, 1.0, 8), roof, roof + 0.8, Color("#8e9298"), Color("#55595f"), M_STONE, M_STONE)
	# The loop on the avenue front: three coils of steel tube and an arrowhead pointing west, 35 m
	# across, over the second to fifth storeys: grey-bronze by day, blue neon at night (M_LAMP + 0.5).
	var lc := Vector2(4.0, 2.3)
	var yc := g + 15.8
	var span := 26.0
	var r := 4.5
	var prev := Vector3.ZERO
	for k in 49:
		var t := float(k) / 48.0
		var th := TAU * 3.0 * t
		# The coil leans in and out (0.6 m) so where it crosses itself the tubes pass, not merge.
		var p := _w(lc.x - span * 0.5 + span * t - r * cos(th), lc.y + 0.6 * cos(th))
		var cur := Vector3(p.x, yc + r * sin(th), p.y)
		if k > 0:
			_beam(prev, cur, 0.35, CD_LOOP, false, M_LAMP + 0.5)
		prev = cur
	for s: float in [-1.0, 1.0]:
		var dv := 1.2 + 0.2 * s   # the two barbs a little apart in depth: they meet at the tip
		var tip := _w(lc.x - span * 0.5 - r - 0.6, lc.y + dv)
		var back := _w(lc.x - span * 0.5 - r + 1.8, lc.y + dv)
		_beam(Vector3(tip.x, yc, tip.y), Vector3(back.x, yc + 1.9 * s, back.y), 0.35, CD_LOOP, false, M_LAMP + 0.5)
	_mode = M_STONE
	# Car collision on the mapped outline, but round the Krucza corner on the model's 11 m curve
	# (OSM barely rounds it: the car would stop 3.7 m short of the glass).
	var wedge := Geometry2D.clip_polygons(_rect(-33.0, -1.0, 9.0, 9.0), ring)
	var body := outline
	for wpoly: PackedVector2Array in wedge:
		var left := Geometry2D.clip_polygons(body, wpoly)
		if not left.is_empty():
			body = _largest(left)
	# Hand it to map_builder's slit/notch bridging too (pocket_rings, as `_collide_raw` does).
	_collide(body)
	pocket_rings.append(body)


# --- Bracka and Plac Trzech Krzyży: Vitkac, Jabłkowski's, the Sheraton (photo reports, 2026-11-03) ---

## Vitkac (Bracka 9): six storeys in a dark grey stone and metal skin with horizontal bands and big
## flush square windows, a fully glazed ground floor of shop windows, a set-back glass top storey
## with a planted terrace on the Bracka side; the long block's ends are rounded.
const VITKAC_GROUND := 5.0     # the shop-window storey's top
const VITKAC_FLOOR := 4.2      # the five storeys over it
const VITKAC_EAVE := 26.0      # the stone body's top (OSM: 26 m, the glass top to 31)
const VITKAC_TOP := 30.4       # the set-back glass storey's roof
const VITKAC_WALL := Color("#4e4f52")   # the speckled dark granite (F's photo, 2026-11-20)
const VITKAC_CORNER_R := 7.0   # the big curves of its corners
const VITKAC_BAND := Color("#5d5e61")
const VITKAC_BASE := Color("#3f4042")
const VITKAC_GLASS := Color("#2c3238")
const VITKAC_SHOP := Color("#c9b48c")   # warm-lit shop windows behind the glass
const VITKAC_TOP_GLASS := Color("#4a5a66")
const VITKAC_ROOF := Color("#6c6353")
## The Bracka front's two ends (game coords, from the outline): the terrace's trees stand along it.
const VITKAC_BRACKA := [Vector2(-358.7, 327.4), Vector2(-337.9, 391.8)]

## Dom Towarowy Braci Jabłkowskich (Bracka 25, 1914): the front on Bracka in warm ochre render over
## a two-storey base of round-arched shop windows in grey-brown stone, a balustraded balcony band,
## four storeys of tall windows with small relief panels, a cornice with the founders' cartouche,
## an attic storey; the entrance between two fat white Doric columns; a glazed atrium roof.
const JAB_FRONT_MID := Vector2(-579.2, 202.3)   # the middle of the Bracka front (the outline's edge)
const JAB_BASE_TOP := 8.4      # the two-storey base's top (the balcony band)
const JAB_FLOOR := 3.7         # the four storeys over it
const JAB_CORNICE := 24.6
const JAB_ATTIC := 28.2
const JAB_BAYS := 9
const JAB_DOOR := 4        # the middle bay: the entrance
const JAB_WALL := Color("#d9c3a0")
const JAB_BASE := Color("#7d6b5a")
const JAB_TRIM := Color("#e8dcc2")
const JAB_GLASS := Color("#3a3f45")
const JAB_SHOP := Color("#d8c08a")
const JAB_COLUMN := Color("#f0ece2")
const JAB_ROOF := Color("#7d7468")
const JAB_ATRIUM := Color("#9fb3bd")
const JAB_GILT := Color("#c9a24a")

## Sheraton Grand Warsaw (Bolesława Prusa 2) as "Szeraton": seven storeys in white render, the two
## lower ones banded in grey, ribbon windows above, a set-back top storey under an overhanging flat
## roof; three wings run north from the Prusa block with low glass-roofed halls between them; at
## the Plac Trzech Krzyży corner a drum banded in glass and white, crowned by a steel ring frame
## that carries the name. Courts and the west wing from the mapped parts (7.6 m and 10.9 m).
const SHER_BODY := 21.6
const SHER_TOP := 24.6
const SHER_DRUM_C := Vector2(6.0, 681.0)
const SHER_DRUM_R := 6.8
const SHER_DRUM_H := 28.0
const SHER_COURTS := [
	[Vector2(30.4, 646.4), Vector2(32.5, 669.4), Vector2(55.2, 666.7), Vector2(53.2, 649.6), Vector2(49.7, 652.2),
			Vector2(47.1, 649.3), Vector2(43.8, 645.5), Vector2(49.5, 640.8)],
	[Vector2(74.1, 637.3), Vector2(75.6, 664.0), Vector2(95.5, 661.3), Vector2(93.2, 638.8), Vector2(90.3, 641.1),
			Vector2(84.2, 634.4)],
]
const SHER_COURT_H := 7.6
const SHER_WEST := [Vector2(-8.8, 662.0), Vector2(-9.4, 662.2), Vector2(-13.5, 654.8), Vector2(-15.3, 651.3),
		Vector2(-10.6, 649.8), Vector2(-4.0, 647.8), Vector2(-2.0, 651.5), Vector2(0.0, 655.0), Vector2(2.3, 658.8)]
const SHER_WEST_H := 10.9
const SHER_WHITE := Color("#ecebe6")
const SHER_GREY := Color("#9a9c9e")
const SHER_GLASS := Color("#5e6a74")
const SHER_COURT_GLASS := Color("#a9bcc6")
const SHER_STEEL := Color("#b8bec4")
const SHER_ROOF := Color("#a8a9a6")


func _find_bracka() -> void:
	for pair: Array in [["vitkac", "Vitkac"], ["jablkowscy", "Dom Towarowy Braci Jabłkowskich"],
			["sheraton", "Sheraton Grand Warsaw"]]:
		var q := _landmark(pair[1])
		if q.size() < 3:
			continue
		var zone: Array = [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))]
		if pair[0] == "sheraton":
			zone.append(_circle(SHER_DRUM_C, SHER_DRUM_R + 1.0, 12))
		_add_site(pair[0], zone)
		if not sites.is_empty() and sites[-1]["key"] == pair[0]:
			sites[-1]["ring"] = _simplify(q, 0.4)
			sites[-1]["raw"] = q  # the car's walls: the mapped outline, flush with the houses next door


func _build_vitkac(site: Dictionary) -> void:
	# F, 2026-11-20 ("Vitkac built bad, build it from photos, and the roof with the bar"; his
	# Street View from Al. Jerozolimskie, Apr 2026): a speckled dark granite block whose corners
	# are big curves, its storeys ribbons of dark glass wrapping round them between stone bands,
	# stone fins every few metres across the ribbons, a few big framed windows stacked at the
	# Jerozolimskie corner, a ground floor all shop glass, and on the roof a set-back glass storey
	# behind a glass balustrade, with the roof bar's terrace (parasols, sofas, planters) on the
	# Jerozolimskie end and small trees along Bracka.
	var raw: PackedVector2Array = site["ring"]
	_g = _ground_under(raw)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The rounded body: the outline pulled in and pushed out again with round joins, which turns
	# every convex corner into a curve of VITKAC_CORNER_R.
	var ring := raw
	var shrunk := Geometry2D.offset_polygon(raw, -VITKAC_CORNER_R, Geometry2D.JOIN_MITER)
	if not shrunk.is_empty():
		var rounded := Geometry2D.offset_polygon(_largest(shrunk), VITKAC_CORNER_R, Geometry2D.JOIN_ROUND)
		if not rounded.is_empty():
			ring = _simplify(_largest(rounded), 0.25)
	# The Jerozolimskie end: the ring's points facing north, for the corner windows and the bar.
	var north := Vector2(-0.30855, -0.95123)
	var c := _centre(ring)
	var far := c
	for q in ring:
		if (q - c).dot(north) > (far - c).dot(north):
			far = q
	# The ground floor: shop glass set 0.4 m back under the stone, warm shop windows on it, slim
	# dark mullions.
	var shop := _largest(Geometry2D.offset_polygon(ring, -0.4, Geometry2D.JOIN_ROUND))
	_prism(shop, g - 0.6, g + VITKAC_GROUND, VITKAC_GLASS, none, M_GLASS)
	# Bays on the simplified ring: on the round join's short, nearly straight pieces two neighbouring
	# bays overlapped in one plane (check_mesh_quality zfight at the Bracka corner).
	_bays(_simplify(shop, 0.4), 0.4, VITKAC_GROUND - 0.5, 4.0, 3.5, VITKAC_SHOP)
	_mullions(shop, g, g + VITKAC_GROUND, 2.0, 0.15, VITKAC_BASE)  # in front of the 0.07-proud shop windows (0.09 fought them)
	_soffit(ring, g + VITKAC_GROUND, VITKAC_BASE)
	# The stone body over it, and per storey a glass ribbon 2 m tall, a hair proud, with stone
	# fins across it every 3.6 m (the photos' panels).
	_prism(ring, g + VITKAC_GROUND, g + VITKAC_EAVE, VITKAC_WALL, none, M_STONE)
	for k in 5:
		var y0 := g + VITKAC_GROUND + VITKAC_FLOOR * k + 1.0
		_band(ring, 0.05, y0, y0 + 2.1, VITKAC_GLASS, M_GLASS)
		_bays(ring, y0 - g - 0.05, y0 - g + 2.15, 3.6, 0.45, VITKAC_WALL)
	# The big framed windows stacked by the Jerozolimskie corner: three storeys of one tall pane
	# each, in a lighter frame (the photo's right-hand bays).
	for side: float in [-1.0, 1.0]:
		var tangent := Vector2(-north.y, north.x) * side
		var at := far + tangent * 9.0
		var o := _nearest_out(ring, at)
		var p := _nearest_on(ring, at) + o * 0.12
		var e := Vector2(-o.y, o.x)
		for k in range(1, 4):
			var y0 := g + VITKAC_GROUND + VITKAC_FLOOR * k + 0.5
			_mode = M_STONE
			_wall(p - e * 2.6, p + e * 2.6, y0 - 0.2, y0 + 3.4, o, VITKAC_BAND)
			_mode = M_GLASS
			_wall(p - e * 2.3 + o * 0.03, p + e * 2.3 + o * 0.03, y0, y0 + 3.2, o, VITKAC_TOP_GLASS)
	_mode = M_STONE
	# The roof: the stone body's top, a parapet with a glass balustrade on it.
	_cap(ring, g + VITKAC_EAVE, VITKAC_ROOF)
	_parapet(ring, g + VITKAC_EAVE, 0.6, VITKAC_BAND)
	_mode = M_GLASS
	_band(_largest(Geometry2D.offset_polygon(ring, -0.15, Geometry2D.JOIN_ROUND)), 0.0, g + VITKAC_EAVE + 0.6,
			g + VITKAC_EAVE + 1.5, VITKAC_TOP_GLASS.lightened(0.25), M_GLASS)
	_mode = M_STONE
	# The set-back glass storey (the restaurant and bar), lit warm at night, its flat roof
	# overhanging a little.
	var top := _simplify(_largest(Geometry2D.offset_polygon(ring, -4.0, Geometry2D.JOIN_ROUND)), 0.4)
	if top.size() >= 3:
		_prism(top, g + VITKAC_EAVE, g + VITKAC_TOP, VITKAC_TOP_GLASS, none, M_PAVILION)
		_mullions(top, g + VITKAC_EAVE, g + VITKAC_TOP, 1.8, 0.05, VITKAC_BASE)
		var lid := _largest(Geometry2D.offset_polygon(top, 0.6, Geometry2D.JOIN_ROUND))
		_prism(lid, g + VITKAC_TOP, g + VITKAC_TOP + 0.45, VITKAC_BASE, VITKAC_ROOF.darkened(0.1), M_STONE, M_STONE)
	# The bar's terrace on the Jerozolimskie end, between the glass storey and the balustrade:
	# cream parasols over low tables, dark sofas, square planters.
	var deck := far - north * 2.2
	var tdir := Vector2(-north.y, north.x)
	for k in range(-3, 4):
		var q := deck + tdir * k * 3.4
		if not Geometry2D.is_point_in_polygon(q, ring) or (top.size() >= 3 and Geometry2D.is_point_in_polygon(q, top)):
			continue
		var y := g + VITKAC_EAVE
		_beam(Vector3(q.x, y, q.y), Vector3(q.x, y + 2.3, q.y), 0.08, VITKAC_BASE)
		_frustum(_circle(q, 1.4, 8), y + 2.2, _circle(q, 0.1, 8), y + 2.7, Color("#efe9dc"), Color("#efe9dc"))
		_prism(_circle(q, 0.4, 8), y, y + 0.7, Color("#3a3a3c"), Color("#d9d2c4"), M_STONE, M_STONE)
		var sofa := q + north * 1.0
		_prism(_rect_at(sofa, tdir, 1.9, 0.8), y, y + 0.45, Color("#2b2b2e"), Color("#3a3a3e"), M_STONE, M_STONE)
		if k % 2 == 0:
			var pl := q - tdir * 1.7
			_prism(_rect_at(pl, tdir, 0.8, 0.8), y, y + 0.7, VITKAC_BASE, Color("#4f3f2f"), M_STONE, M_STONE)
			_frustum(_circle(pl, 0.5, 6), y + 0.7, _circle(pl, 0.1, 6), y + 1.9, DOM_LEAF, DOM_LEAF)
	# The terrace's small trees along the Bracka side.
	var a: Vector2 = VITKAC_BRACKA[0]
	var b: Vector2 = VITKAC_BRACKA[1]
	var e2 := (b - a).normalized()
	var inward := -_out(raw, a, b)
	var length := a.distance_to(b)
	var t := 12.0
	while t < length - 8.0:
		_varso_tree(a + e2 * t + inward * 2.0, g + VITKAC_EAVE, 2.8, 0.9)
		t += 7.5
	# The name on the Bracka front, high up.
	var word := "VIPKAC"
	var out := _out(raw, a, b)
	var mid := (a + b) * 0.5 + out * 0.15
	var k2 := 9.0 / Neon.length_of(word)
	signs.append([word, Vector3(mid.x, g + VITKAC_EAVE - 3.6, mid.y), Vector3(out.x, 0.0, out.y), k2, Color(1.0, 0.92, 0.75)])
	_collide_raw(site)


## The outward normal of `ring`'s edge nearest to p.
func _nearest_out(ring: PackedVector2Array, p: Vector2) -> Vector2:
	var best := INF
	var o := Vector2.UP
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		if q.distance_to(p) < best and a.distance_to(b) > 0.3:
			best = q.distance_to(p)
			o = _out(ring, a, b)
	return o


## The point of `ring`'s outline nearest to p.
func _nearest_on(ring: PackedVector2Array, p: Vector2) -> Vector2:
	var best := INF
	var r := p
	for i in ring.size():
		var q := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])
		if q.distance_to(p) < best:
			best = q.distance_to(p)
			r = q
	return r


## A rectangle `l` long along `dir` and `w` across, centred at c.
func _rect_at(c: Vector2, dir: Vector2, l: float, w: float) -> PackedVector2Array:
	var d := dir.normalized()
	var n := Vector2(-d.y, d.x)
	var hl := d * l * 0.5
	var hw := n * w * 0.5
	return PackedVector2Array([c - hl - hw, c + hl - hw, c + hl + hw, c - hl + hw])


func _build_jablkowscy(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The Bracka front: the ring's edge nearest JAB_FRONT_MID.
	var n := ring.size()
	var fi := 0
	var best := INF
	for i in n:
		var d := JAB_FRONT_MID.distance_to(Geometry2D.get_closest_point_to_segment(JAB_FRONT_MID, ring[i], ring[(i + 1) % n]))
		if ring[i].distance_to(ring[(i + 1) % n]) > 20.0 and d < best:
			best = d
			fi = i
	var fa := ring[fi]
	var fb := ring[(fi + 1) % n]
	var flen := fa.distance_to(fb)
	_o = fa
	_a = (fb - fa) / flen
	_b = _out(ring, fa, fb)
	var pitch := flen / JAB_BAYS
	var door := JAB_DOOR
	var skip := _rect(flen * 0.5, 0.0, flen * 0.5 + 0.3, 1.5)
	# The other fronts' windows first, then the mass: the stone base, the render, the cornice, the attic.
	_bays(ring, 1.0, 6.4, 4.0, 2.4, JAB_GLASS, skip)
	for k in 4:
		var y0 := JAB_BASE_TOP + JAB_FLOOR * k + 0.9
		_bays(ring, y0, y0 + 2.3, 2.8, 1.2, JAB_GLASS, skip)
	# The front's windows: in each bay two tall windows a floor, a relief panel under each pair.
	var front := 0.07
	_mode = M_GLASS
	for k in 4:
		var y0 := g + JAB_BASE_TOP + JAB_FLOOR * k + 0.9
		for j in JAB_BAYS:
			var u := (j + 0.5) * pitch
			for sd: float in [-1.0, 1.0]:
				var wu := u + sd * pitch * 0.23
				_wall(_w(wu - 0.6, front), _w(wu + 0.6, front), y0, y0 + 2.3, _b, JAB_GLASS, wu)
	_mode = M_STONE
	for k in 3:
		var y0 := g + JAB_BASE_TOP + JAB_FLOOR * (k + 1) + 0.15
		for j in JAB_BAYS:
			var u := (j + 0.5) * pitch
			_wall(_w(u - pitch * 0.36, 0.04), _w(u + pitch * 0.36, 0.04), y0, y0 + 0.55, _b, JAB_TRIM)
	# The base's round-arched shop windows (the middle bay is the entrance), a frame behind each.
	for j in JAB_BAYS:
		if j == door:
			continue
		var at := _w((j + 0.5) * pitch, 0.0)
		_arch_panel(at, _a, _b, pitch * 0.38 + 0.25, g + 0.4, g + 6.0, JAB_TRIM, 0.04, M_STONE)
		_arch_panel(at, _a, _b, pitch * 0.38, g + 0.6, g + 6.0, JAB_SHOP, 0.08, M_GLASS)
	_prism(ring, g - 0.6, g + JAB_BASE_TOP, JAB_BASE, none, M_STONE)
	_prism(ring, g + JAB_BASE_TOP, g + JAB_CORNICE, JAB_WALL, none, M_STONE)
	var eave := _largest(Geometry2D.offset_polygon(ring, 0.5, Geometry2D.JOIN_MITER))
	_prism(eave, g + JAB_CORNICE, g + JAB_CORNICE + 0.8, JAB_TRIM, JAB_TRIM.darkened(0.1), M_STONE, M_STONE)
	var attic := _largest(Geometry2D.offset_polygon(ring, -0.9, Geometry2D.JOIN_MITER))
	if attic.size() >= 3:
		_bays(attic, JAB_CORNICE + 1.3, JAB_ATTIC - 0.6, 2.8, 1.0, JAB_GLASS)
		_prism(attic, g + JAB_CORNICE + 0.8, g + JAB_ATTIC, JAB_WALL.lightened(0.06), JAB_ROOF, M_STONE, M_STONE)
	# The slim piers between the shop windows and the balcony band with its balustrade.
	for j in JAB_BAYS + 1:
		_lbox(j * pitch, 0.15, 0.28, 0.15, g - 0.6, g + JAB_BASE_TOP, JAB_BASE.lightened(0.08), M_STONE)
	_lbox(flen * 0.5, 0.45, flen * 0.5, 0.45, g + JAB_BASE_TOP - 0.1, g + JAB_BASE_TOP + 0.25, JAB_TRIM, M_STONE)
	for j in JAB_BAYS * 2 + 1:
		_lbox(j * pitch * 0.5, 0.8, 0.12, 0.12, g + JAB_BASE_TOP + 0.25, g + JAB_BASE_TOP + 1.05, JAB_TRIM, M_STONE)
	_lbox(flen * 0.5, 0.8, flen * 0.5, 0.15, g + JAB_BASE_TOP + 1.05, g + JAB_BASE_TOP + 1.2, JAB_TRIM, M_STONE)
	# The entrance: a dark door with a fanlight between two fat white Doric columns under a lintel.
	var du := (door + 0.5) * pitch
	_mode = M_GLASS
	_wall(_w(du - 1.3, 0.07), _w(du + 1.3, 0.07), g + 0.05, g + 3.8, _b, JAB_GLASS.darkened(0.2), du)
	_arch_panel(_w(du, 0.0), _a, _b, 1.3, g + 3.8, g + 4.6, JAB_SHOP, 0.07, M_GLASS)
	_mode = M_STONE
	for sd: float in [-1.0, 1.0]:
		_column(du + sd * 2.0, 0.75, 0.45, g - 0.2, g + 6.6, JAB_COLUMN)
	_lbox(du, 0.7, 2.8, 0.65, g + 6.6, g + 7.3, JAB_COLUMN, M_STONE)
	# The shop's name over the entrance (a generic word, no brand) and the cartouche on the cornice.
	var word := "DOM MODY"
	var at := _w(du, 1.4)
	signs.append([word, Vector3(at.x, g + 6.9, at.y), Vector3(_b.x, 0.0, _b.y), 4.2 / Neon.length_of(word), Color(1.0, 0.88, 0.62)])
	_lbox(flen * 0.5, 0.2, 1.1, 0.25, g + JAB_CORNICE + 0.8, g + JAB_CORNICE + 2.6, JAB_TRIM, M_STONE)
	var cart := _w(flen * 0.5, 0.47)
	_disc(Vector3(cart.x, g + JAB_CORNICE + 1.7, cart.y), Vector3(_b.x, 0.0, _b.y), 0.6, 8, JAB_GILT)
	# The atrium's glass roof in the middle of the block (the ortho's x -600..-575, z 200..220).
	_hip(16.0, -11.5, 7.0, 5.0, g + JAB_ATTIC, 1.6, JAB_ATRIUM)
	_collide_raw(site)


func _build_sheraton(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The tall body: the outline less the two low halls and the lower west wing.
	var body := ring
	var lows: Array[PackedVector2Array] = []
	for c: Array in SHER_COURTS:
		lows.append(PackedVector2Array(c))
	lows.append(PackedVector2Array(SHER_WEST))
	for low in lows:
		var grown := _largest(Geometry2D.offset_polygon(low, 0.2, Geometry2D.JOIN_MITER))
		var cut := Geometry2D.clip_polygons(body, grown)
		if not cut.is_empty():
			body = _largest(cut)
	body = _simplify(body, 0.5)
	# The ribbon windows of the five upper storeys and the grey bands of the two lower ones.
	for k in 5:
		var y := g + 8.2 + 2.7 * k
		_band(body, 0.07, y, y + 1.45, SHER_GLASS, M_GLASS)
	for k in 4:
		var y := g + 1.0 + 1.6 * k
		_band(body, 0.06, y, y + 0.7, SHER_GREY)
	_prism(body, g - 0.6, g + SHER_BODY, SHER_WHITE, none, M_STONE)
	_mode = M_STONE
	_cap(body, g + SHER_BODY, SHER_ROOF)
	# The set-back top storey under its overhanging flat roof.
	var top := _simplify(_largest(Geometry2D.offset_polygon(body, -1.4, Geometry2D.JOIN_MITER)), 0.5)
	if top.size() >= 3:
		_prism(top, g + SHER_BODY, g + SHER_TOP, SHER_GLASS.lightened(0.1), none, M_GLASS)
		var lid := _largest(Geometry2D.offset_polygon(top, 1.8, Geometry2D.JOIN_MITER))
		_prism(lid, g + SHER_TOP, g + SHER_TOP + 0.6, SHER_WHITE, SHER_ROOF, M_STONE, M_STONE)
	# The low halls between the wings under glass, and the west wing.
	for k in SHER_COURTS.size():
		var c := lows[k]
		_bays(c, 1.0, 5.6, 3.0, 2.2, SHER_GLASS)
		_prism(c, g - 0.6, g + SHER_COURT_H, SHER_WHITE, SHER_COURT_GLASS, M_STONE, M_STONE)
	var west := lows[lows.size() - 1]
	_bays(west, 1.2, 3.4, 3.0, 1.8, SHER_GLASS)
	_bays(west, 4.6, 6.6, 3.0, 1.8, SHER_GLASS)
	_bays(west, 7.8, 9.8, 3.0, 1.8, SHER_GLASS)
	_prism(west, g - 0.6, g + SHER_WEST_H, SHER_WHITE, SHER_ROOF, M_STONE, M_STONE)
	# The corner drum: bands of glass and white, its cap, then the steel ring frame with the name.
	var drum := _circle(SHER_DRUM_C, SHER_DRUM_R, 16)
	var y := g - 0.6
	var lv := 0
	while y < g + SHER_DRUM_H - 0.5:
		var glass := lv % 2 == 1
		var h := 2.0 if glass else 1.4
		var y1 := minf(y + h, g + SHER_DRUM_H)
		_prism(drum, y, y1, SHER_GLASS if glass else SHER_WHITE, none, M_GLASS if glass else M_STONE)
		y = y1
		lv += 1
	_mode = M_STONE
	_cap(drum, g + SHER_DRUM_H, SHER_ROOF)
	var hoop := _circle(SHER_DRUM_C, SHER_DRUM_R - 0.4, 16)
	for k in 8:
		_lbox_at(hoop[k * 2], 0.12, g + SHER_DRUM_H, g + SHER_DRUM_H + 4.2, SHER_STEEL)
	_parapet(hoop, g + SHER_DRUM_H + 3.4, 0.8, SHER_STEEL)
	var word := "SZERATON"
	for d: Vector2 in [Vector2(0, 1), Vector2(-1, 0)]:
		var at := SHER_DRUM_C + d * (SHER_DRUM_R - 0.3)
		signs.append([word, Vector3(at.x, g + SHER_DRUM_H + 0.5, at.y), Vector3(d.x, 0.0, d.y),
				8.0 / Neon.length_of(word), Color(1.0, 0.95, 0.85)])
	# Three flag poles on the Prusa side, by the drum.
	for k in 3:
		var p := SHER_DRUM_C + Vector2(10.0 + 3.0 * k, 9.0)
		_lbox_at(p, 0.08, g - 0.2, g + 9.0, SHER_STEEL)
		var cols := [Color("#f2efe8"), Color("#d6283a"), Color("#2a4d8f")]
		_mode = M_STONE
		_wall(p + Vector2(0.08, 0.0), p + Vector2(1.9, 0.0), g + 7.4, g + 8.7, Vector2(0, 1), cols[k])
	_collide_raw(site)
	_collide(drum)


# --- Świętokrzyska's big three: Poczta Główna and PAST-a (2026-11-03, from the Mac photo reports

## Poczta Główna, Świętokrzyska 31/33: the eight-storey block from Świętokrzyska back to the
## street behind, round a glazed central hall. The mass stays LoD2's (a kept skin in its pale
## salmon plaster, SKINS); the model adds what the photo shows from the street: the round corner
## tower at Jasna under a grey-silver dome and lantern, a colonnade of six white columns two
## storeys high before the glazed entrance under a red band with POCZTA (a parody of the
## operator's band), a recessed white window strip beside it, the tall arched windows of the
## corner's ground floor, a cornice under the top storey, and the hall's roof (LoD2's hip) glazed.
## Frame: u west along the Świętokrzyska face from its east end, +v out to the street.
const POCZTA_O := Vector2(-906.2, -164.7)
const POCZTA_AXIS := Vector2(-0.9493, 0.3146)
const POCZTA_FACE := 54.4                  # the straight face's length (u)
const POCZTA_DOME := Vector2(-0.5, -4.5)   # the corner tower's centre (u, v): ortho (-905, -159)
const POCZTA_ENTRY := 26.5                 # the colonnade's middle (u): on the hall's axis
const POCZTA_HALL := Rect2(11.5, -31.2, 30.5, 15.8)  # LoD2's hall (u, v), eaves ~8 m, ridge 13.2 m
const POCZTA_WALL := "#ecd2c2"   # F's look check (2026-11-03): pale warm stone with a pink cast
const POCZTA_ROOF := "#77706b"
const POCZTA_WHITE := Color("#f0ece4")
const POCZTA_RED := Color("#c0262d")
const POCZTA_SILVER := Color("#a7acb0")
const POCZTA_GLASS := Color("#3a454e")
const POCZTA_HALL_GLASS := Color("#7a8d98")
const POCZTA_SIGN := Color(1.0, 0.86, 0.35)


func _build_poczta(site: Dictionary) -> void:
	_o = POCZTA_O
	_a = POCZTA_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = _ground_under((site["zone"] as Array)[0])
	var g := _g
	var wall := Color(POCZTA_WALL)
	var none := Color(0, 0, 0, 0)
	var e := POCZTA_ENTRY
	# the entrance (F's look check, 2026-11-03): a shallow recess in the front, framed by two
	# piers in the wall's stone, its back the dark glazing; the six columns stand in it, half in
	# the front's plane, under a white entablature flush with the front; over them the red band
	# with the name is a canopy reaching out over the pavement, white underneath
	_mode = M_GLASS
	_wall(_w(e + 8.6, 0.08), _w(e - 8.6, 0.08), g + 0.2, g + 8.2, _b, POCZTA_GLASS)
	_mode = M_STONE
	for sd: float in [-1.0, 1.0]:
		_lbox(e + sd * 9.25, 0.45, 0.65, 0.45, g - 0.4, g + 8.2, wall, M_STONE, wall.darkened(0.05))
	_lbox(e, 0.55, 8.6, 0.55, g - 0.4, g + 0.25, POCZTA_WHITE.darkened(0.12), M_STONE, POCZTA_WHITE.darkened(0.06))
	for k in 6:
		_column(e - 8.0 + k * 3.2, 0.55, 0.42, g + 0.25, g + 8.2, POCZTA_WHITE)
	_lbox(e, 0.5, 9.9, 0.5, g + 8.2, g + 9.0, POCZTA_WHITE, M_STONE, POCZTA_WHITE.darkened(0.05))
	_lbox(e, 1.5, 9.9, 1.5, g + 9.0, g + 10.4, POCZTA_RED, M_STONE, POCZTA_RED.darkened(0.25))
	_soffit(_rect(e, 1.5, 9.9, 1.5), g + 8.98, POCZTA_WHITE.darkened(0.08))
	var at := _w(e, 3.0)
	signs.append(["POCZTA", Vector3(at.x, g + 9.1, at.y), Vector3(_b.x, 0.0, _b.y), 0.55, POCZTA_SIGN])
	_collide(_rect(e, 0.55, 9.9, 0.55))
	# the recessed white window strip east of the entrance, from the pavement to the cornice
	var su := e - 12.0
	_lbox(su, 0.1, 1.1, 0.12, g - 0.2, g + 27.5, POCZTA_WHITE, M_STONE, POCZTA_WHITE)
	_mode = M_GLASS
	_wall(_w(su + 0.5, 0.26), _w(su - 0.5, 0.26), g + 3.6, g + 26.8, _b, POCZTA_GLASS)
	_mode = M_STONE
	# the corner's tall arched windows at street level, and the cornice under the top storey
	for u: float in [4.2, 7.8, 11.4]:
		_arch_win(_w(u, 0.0), -_a, _b, 1.05, g + 0.4, g + 4.4, POCZTA_GLASS)
	_lbox((4.5 + POCZTA_FACE - 0.5) * 0.5, 0.2, (POCZTA_FACE - 0.5 - 4.5) * 0.5, 0.45, g + 26.2, g + 26.7,
			POCZTA_WHITE.darkened(0.08), M_STONE, POCZTA_WHITE.darkened(0.12))
	# the corner tower: a drum from the ground (hidden in the mass below the roof) up past the
	# roof, a ring cornice, the dome in four bands, a lantern and its point
	var c := _w(POCZTA_DOME.x, POCZTA_DOME.y)
	_prism(_circle(c, 3.6, 14), g - 0.5, g + 33.0, wall, none, M_MONUMENT)
	_prism(_circle(c, 4.0, 14), g + 30.0, g + 30.6, POCZTA_WHITE, POCZTA_WHITE, M_STONE, M_STONE)
	_prism(_circle(c, 3.95, 14), g + 33.0, g + 33.6, POCZTA_WHITE, POCZTA_WHITE, M_STONE, M_STONE)
	var angles := [0.0, 0.45, 0.85, 1.2, 1.45]
	for k in 4:
		var a0: float = angles[k]
		var a1: float = angles[k + 1]
		_mode = M_STONE
		_frustum(_circle(c, 3.75 * cos(a0), 14), g + 33.6 + 4.0 * sin(a0),
				_circle(c, 3.75 * cos(a1), 14), g + 33.6 + 4.0 * sin(a1), POCZTA_SILVER,
				POCZTA_SILVER if k == 3 else none)
	var top := g + 33.6 + 4.0 * sin(1.45)
	_prism(_circle(c, 0.45, 8), top, top + 1.1, POCZTA_WHITE, POCZTA_SILVER, M_STONE, M_STONE)
	_frustum(_circle(c, 0.55, 8), top + 1.1, _circle(c, 0.08, 8), top + 1.8, POCZTA_SILVER, POCZTA_SILVER)
	# the central hall: LoD2's hipped roof glazed (a little over it), on walls hidden in LoD2's
	var hc := POCZTA_HALL.get_center()
	var hu := POCZTA_HALL.size.x * 0.5
	var hv := POCZTA_HALL.size.y * 0.5
	_prism(_rect(hc.x, hc.y, hu - 0.4, hv - 0.4), g - 0.5, g + 8.0, wall, none, M_STONE)
	_mode = M_GLASS_ROOF
	_frustum(_rect(hc.x, hc.y, hu + 0.3, hv + 0.3), g + 8.0, _rect(hc.x, hc.y, hu + 0.3 - (hv + 0.15), 0.15),
			g + 13.5, POCZTA_HALL_GLASS, POCZTA_HALL_GLASS)
	_mode = M_STONE


## PAST-a, Zielna 37/39 (1904-1908, the Swedish telephone company's exchange; in the Uprising the
## German strongpoint taken by the Kiliński Battalion on 20 August 1944). OpenStreetMap maps it as
## one 54 m block and LoD2 has no model of it, so this is a model on its outline: a grey base
## with the door, the Uprising plaque and nothing funny (warsaw-tone), the grey-brown tower of
## pilaster strips (M_MONUMENT) to a cornice, the top storey an open loggia of tall round arches
## (five on the long faces), a crenellated parapet like a castle's, and on the roof the gilt
## anchor sign; two long white-and-red banners hang on the Zielna face. Its lower wings north and
## south along Zielna stay LoD2's. Frame: u south along the Zielna face, +v out to the street.
const PASTA_O := Vector2(-1201.5, -267.9)
const PASTA_AXIS := Vector2(0.3543, 0.9353)
const PASTA_LOGGIA := 43.0   # the cornice under the loggia storey (over the ground)
const PASTA_TOP := 49.5      # the loggia's top, where the merlons start (~51.5 m with them)
const PASTA_WALL := Color("#877667")   # F's look check (2026-11-03): darker weathered grey-brown
const PASTA_BASE := Color("#5b534c")
const PASTA_TRIM := Color("#9c9083")
const PASTA_DARK := Color("#2b2826")
const PASTA_ROOF := Color("#5d5955")
const PASTA_STONE := Color("#ece7dc")
const PASTA_RED := Color("#c8303a")


func _find_pasta() -> void:
	var outline := _landmark("PAST-a")
	if outline.size() < 3:
		return
	_add_site("pasta", [outline])
	if not sites.is_empty() and sites[-1]["key"] == "pasta":
		sites[-1]["ring"] = _simplify(outline, 0.8)


func _build_pasta(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# the loggia's arches first (they stand off the wall by cm, so the wall behind stays whole)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var l := a.distance_to(b)
		if l < 4.5:
			continue
		var n := clampi(roundi(l / 4.6), 1, 5)
		var e := (b - a) / l
		var out := _out(ring, a, b)
		var pitch := l / n
		var hw := minf(1.25, pitch * 0.3)
		for k in n:
			var p := a + e * (pitch * (k + 0.5))
			_arch_panel(p, e, out, hw + 0.3, g + PASTA_LOGGIA + 0.9, g + PASTA_TOP - 1.2 - hw, PASTA_TRIM, 0.04, M_STONE)
			_arch_panel(p, e, out, hw, g + PASTA_LOGGIA + 1.2, g + PASTA_TOP - 1.2 - hw, PASTA_DARK, 0.08, M_STONE)
	var base := _largest(Geometry2D.offset_polygon(ring, 0.3, Geometry2D.JOIN_MITER))
	_prism(base, g - 0.6, g + 4.2, PASTA_BASE, PASTA_BASE.lightened(0.05), M_STONE, M_STONE)
	_prism(ring, g + 4.2, g + PASTA_LOGGIA, PASTA_WALL, none, M_MONUMENT)
	var ledge := _largest(Geometry2D.offset_polygon(ring, 0.35, Geometry2D.JOIN_MITER))
	_prism(ledge, g + PASTA_LOGGIA, g + PASTA_LOGGIA + 0.6, PASTA_TRIM, PASTA_TRIM, M_STONE, M_STONE)
	_prism(ring, g + PASTA_LOGGIA + 0.6, g + PASTA_TOP, PASTA_WALL, PASTA_ROOF, M_STONE, M_STONE)
	_attic(ring, g + PASTA_TOP, 2.0, PASTA_WALL.lightened(0.04))
	_collide(ring)
	# the Zielna face: the door, the plaque, the banners (white on the viewer's left when hung)
	_o = PASTA_O
	_a = PASTA_AXIS.normalized()
	_b = Vector2(_a.y, -_a.x)
	_lbox(10.6, 0.3, 1.8, 0.08, g - 0.2, g + 4.0, PASTA_TRIM, M_STONE, PASTA_TRIM)
	_lbox(10.6, 0.35, 1.3, 0.08, g - 0.2, g + 3.5, PASTA_DARK, M_STONE, PASTA_DARK)
	_lbox(14.6, 0.33, 0.75, 0.05, g + 1.4, g + 2.4, PASTA_STONE, M_STONE, PASTA_STONE)
	for u: float in [4.5, 16.7]:
		_lbox(u + 0.45, 0.06, 0.45, 0.04, g + 12.0, g + 36.0, PASTA_STONE, M_STONE, PASTA_STONE)
		_lbox(u - 0.45, 0.06, 0.45, 0.04, g + 12.0, g + 36.0, PASTA_RED, M_STONE, PASTA_RED)
	# the gilt anchor on the roof, facing Zielna, on a low plinth
	var lc := _local(_centre(ring))
	var y0 := g + PASTA_TOP + 0.6
	_lbox(lc.x, lc.y, 0.8, 0.8, g + PASTA_TOP, y0, PASTA_BASE, M_STONE, PASTA_BASE.lightened(0.05))
	var pt := func(s: float, h: float, d: float) -> Vector3:
		var q := _w(lc.x + s, lc.y + d)
		return Vector3(q.x, y0 + h, q.y)
	var line := [[0.0, 0.1, 0.0, 4.2], [0.0, 4.2, 0.9, 4.2], [0.9, 4.2, 1.25, 3.75], [1.25, 3.75, 0.9, 3.3],
			[0.9, 3.3, 0.0, 3.3], [-1.45, 1.8, -1.0, 0.7], [-1.0, 0.7, 0.0, 0.3], [0.0, 0.3, 1.0, 0.7],
			[1.0, 0.7, 1.45, 1.8]]
	for k in line.size():
		var seg: Array = line[k]
		var d := 0.06 * (k % 2)  # every other stroke a little forward, so joints do not z-fight
		_beam(pt.call(seg[0], seg[1], d), pt.call(seg[2], seg[3], d), 0.28, KP_GOLD)


# --- Gmach Banku Gospodarstwa Krajowego (photo report, 2026-11-03) --------------------------------

## The BGK building, Al. Jerozolimskie 7 (Rudolf Świerczyński, 1928-31), next to Vitkac towards
## Nowy Świat, from the Mac photo gather (docs/landmarks/photo-reports/bgk.md: 8 Commons photos, the
## ortho, the OSM outline checked on it). OpenStreetMap leaves the outline unnamed (an 'office',
## 27.4 m): found by a point in it. A grey granite block: a darker 5.5 m base of grouped tall
## windows, four rusticated storeys of paired windows in stone bays, a string course, two smooth
## storeys, the heavy cornice at 26 m and a set-back attic of small windows; the two corner blocks
## (the Bracka end and the Nowy Świat corner) rise two storeys more, the east one with the relief
## frieze under its top; the gilded monogram over the middle of the Jerozolimskie front between two
## pilasters. On the roof the energy group's signs, as the parody PEGE (F, 2026-11-20).
## Frame: u along the Jerozolimskie front from its west end, +v out of it (north). Spec bgk.md.
const BGK_AT := Vector2(-262.0, 312.0)       # a point in the outline (OSM relation 71489)
const BGK_O := Vector2(-298.0, 301.0)        # the front's west end
const BGK_A := Vector2(0.95123, -0.30855)    # along the front, to (-229.6, 278.9)
const BGK_FRONT := 71.9
const BGK_BASE := 5.5
const BGK_FLOOR := 3.3
const BGK_STRING := 18.7     # the string course over the four rusticated storeys
const BGK_CORNICE := 25.6
const BGK_ATTIC := 29.0
const BGK_TOWER := 34.0      # the corner blocks
const BGK_STONE := Color("#9a9c99")
const BGK_STONE_DARK := Color("#78797a")
const BGK_BASE_COL := Color("#6b6d6e")
const BGK_FRIEZE := Color("#b3b0a6")
const BGK_WINDOW := Color("#4a3a36")   # dark brown frames and glass, seen together
const BGK_GILT := Color("#c8b070")
const BGK_ROOF := Color("#6f7173")
## Points in the two stray roof parts (min height 23.1 m) by the Bracka-Mysia corner.
const BGK_STRAY_PARTS := [Vector2(-289.0, 357.0), Vector2(-312.0, 364.0)]


func _find_bgk() -> void:
	var q := _tallest_at(BGK_AT)
	if q.size() < 3 or not Geometry2D.is_point_in_polygon(BGK_O.lerp(BGK_O + BGK_A * BGK_FRONT, 0.5) + Vector2(-BGK_A.y, BGK_A.x) * 3.0, q):
		return
	var zone: Array = [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))]
	# F, 2026-11-20 ("two towers on Bracka between the bank and Vitkac, what is that?"): two small
	# OpenStreetMap parts mapped 23-27 m up at the Bracka-Mysia corner, which the city drew as
	# whole towers from the ground. The site replaces them (nothing is built there).
	for at: Vector2 in BGK_STRAY_PARTS:
		for bd in data.get("buildings", []):
			var part := _pts(bd["p"])
			if float(bd.get("mh", 0.0)) > 20.0 and part.size() >= 3 and Geometry2D.is_point_in_polygon(at, part):
				zone.append(_largest(Geometry2D.offset_polygon(part, 0.3, Geometry2D.JOIN_MITER)))
	_add_site("bgk", zone)
	if not sites.is_empty() and sites[-1]["key"] == "bgk":
		sites[-1]["ring"] = _simplify(q, 0.4)
		sites[-1]["raw"] = q


## Paired windows along a ring's walls: a bay every `step` metres holding two panes `w` wide,
## `gap` apart, from h0 to h1 over the ground, 7 cm proud (the BGK's stone bays).
func _pair_bays(ring: PackedVector2Array, h0: float, h1: float, step: float, w: float, gap: float, col: Color) -> void:
	var keep := _mode
	_mode = M_GLASS
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		var n := floori((length - 1.0) / step)
		if n < 1:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		var t0 := (length - n * step) * 0.5 + step * 0.5
		for k in n:
			for sd: float in [-1.0, 1.0]:
				var p := a + e * (t0 + k * step + sd * (gap + w) * 0.5) + out * 0.07
				_wall(p - e * w * 0.5, p + e * w * 0.5, _g + h0, _g + h1, out, col, t0 + k * step)
	_mode = keep


func _build_bgk(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_o = BGK_O
	_a = BGK_A
	_b = Vector2(BGK_A.y, -BGK_A.x)   # out of the front, north
	# Windows first (7 cm proud): the base's grouped tall windows, four rusticated storeys and two
	# smooth ones of paired windows.
	_bays(ring, 0.9, BGK_BASE - 0.6, 3.9, 2.6, BGK_WINDOW)
	for k in 6:
		var y0 := BGK_BASE + BGK_FLOOR * k + 0.7 + (0.4 if k >= 4 else 0.0)
		_pair_bays(ring, y0, y0 + 2.0, 3.9, 1.1, 0.5, BGK_WINDOW)
	# The mass: the darker base, the stone, the string course, the cornice.
	_prism(ring, g - 0.6, g + BGK_BASE, BGK_BASE_COL, none, M_STONE)
	_prism(ring, g + BGK_BASE, g + BGK_CORNICE, BGK_STONE, none, M_STONE)
	_band(ring, 0.25, g + BGK_BASE - 0.3, g + BGK_BASE + 0.2, BGK_STONE_DARK)
	_band(ring, 0.3, g + BGK_STRING - 0.1, g + BGK_STRING + 0.5, BGK_STONE_DARK)
	var eave := _largest(Geometry2D.offset_polygon(ring, 0.6, Geometry2D.JOIN_MITER))
	_prism(eave, g + BGK_CORNICE, g + BGK_CORNICE + 0.9, BGK_STONE.lightened(0.05), BGK_ROOF, M_STONE, M_STONE)
	# The set-back attic storey of small square windows.
	var attic := _simplify(_largest(Geometry2D.offset_polygon(ring, -1.6, Geometry2D.JOIN_MITER)), 0.4)
	if attic.size() >= 3:
		_bays(attic, BGK_CORNICE + 1.5, BGK_CORNICE + 2.5, 3.9, 1.0, BGK_WINDOW)
		_prism(attic, g + BGK_CORNICE + 0.9, g + BGK_ATTIC, BGK_STONE.lightened(0.03), BGK_ROOF, M_STONE, M_STONE)
	# The two corner blocks, two storeys over the attic, cut from the outline less 1.2 m.
	var inner := _largest(Geometry2D.offset_polygon(ring, -1.2, Geometry2D.JOIN_MITER))
	var corners := [_rect(6.0, -9.0, 10.0, 11.0), _rect(66.0, -10.0, 12.0, 12.0)]
	for c in corners.size():
		var cut := Geometry2D.intersect_polygons(inner, corners[c])
		if cut.is_empty():
			continue
		var blk := _simplify(_largest(cut), 0.3)
		if blk.size() < 3:
			continue
		var top := BGK_TOWER - (1.0 if c == 0 else 0.0)
		_bays(blk, BGK_ATTIC + 0.8, BGK_ATTIC + 2.6, 3.9, 1.1, BGK_WINDOW)
		_prism(blk, g + BGK_CORNICE + 0.9, g + top, BGK_STONE, BGK_ROOF, M_STONE, M_STONE)
		_parapet(blk, g + top, 0.7, BGK_STONE_DARK)
		if c == 1:  # the relief frieze under the east block's top
			_band(blk, 0.15, g + top - 3.2, g + top - 1.0, BGK_FRIEZE)
	# The middle of the Jerozolimskie front: two pilasters, a tall window between, the gilded
	# monogram on the pier over it.
	var mu := BGK_FRONT * 0.5
	for sd: float in [-1.0, 1.0]:
		_lbox(mu + sd * 2.1, 0.3, 0.45, 0.3, g - 0.6, g + BGK_STRING, BGK_STONE.lightened(0.06), M_STONE)
	_mode = M_GLASS
	_wall(_w(mu - 1.2, 0.07), _w(mu + 1.2, 0.07), g + 0.4, g + 9.0, _b, BGK_WINDOW.darkened(0.1), mu)
	_mode = M_STONE
	var mono := _w(mu, 0.1)
	_disc(Vector3(mono.x, g + 11.2, mono.y), Vector3(_b.x, 0.0, _b.y), 1.0, 10, BGK_GILT)
	# The roof signs (F, 2026-11-20: "add some sign to the bank like real"; his Street View, Apr
	# 2026): the energy group's mark in blue italic capitals with its red and blue swoosh over
	# them on the Bracka corner block, its full name in blue along the attic beside it. As a
	# parody: PEGE, Polska Grupa Energiczna.
	var out3 := Vector3(_b.x, 0.0, _b.y)
	var blue := Color(0.16, 0.32, 0.72)
	var k_m := 7.5 / Neon.length_of("PEGE")
	var mp := _w(6.0, -0.4)
	var y_m := g + BGK_TOWER - 1.0
	signs.append(["PEGE", Vector3(mp.x, y_m + 0.3, mp.y), out3, k_m, blue])
	var arc_h := y_m + 0.3 + Neon.ROW_H * Neon.PIXEL * k_m + 0.4
	for band: Array in [[0.0, Color(0.86, 0.13, 0.2)], [0.45, blue]]:
		var prev := Vector3.INF
		for k in 9:
			var t := float(k) / 8.0
			var q := _w(6.0 - 4.2 + 8.4 * t, -0.5)
			var p3 := Vector3(q.x, arc_h + float(band[0]) + 1.3 * sin(PI * (0.15 + 0.8 * t)), q.y)
			if prev != Vector3.INF:
				_beam(prev, p3, 0.32, band[1], true, M_LAMP)
			# The swoosh's ends stand on slim posts from the roof (no floating sign): one post per end,
			# up to the upper band, through the lower band's end.
			if (k == 0 or k == 8) and float(band[0]) > 0.0:
				_beam(Vector3(p3.x, y_m - 0.4, p3.z), p3, 0.12, Color(0.18, 0.19, 0.21))
			prev = p3
	# The full name is wider than the neon atlas's row (ATLAS_W), so it is two words side by side,
	# laid out along the sign's own reading direction at one scale, 22 m in all.
	var k_n := 22.0 / Neon.length_of("POLSKA GRUPA ENERGICZNA")
	var np := _w(30.0, -1.7)
	var mid := Vector3(np.x, g + BGK_ATTIC + 0.1, np.y)
	var read := Neon.place("POLSKA GRUPA", mid, out3).basis.x.normalized()
	var half := 0.5 * k_n * Neon.length_of("POLSKA GRUPA ENERGICZNA")
	var w1 := k_n * Neon.length_of("POLSKA GRUPA")
	var w2 := k_n * Neon.length_of("ENERGICZNA")
	signs.append(["POLSKA GRUPA", mid - read * (half - 0.5 * w1), out3, k_n, blue])
	signs.append(["ENERGICZNA", mid + read * (half - 0.5 * w2), out3, k_n, blue])
	_collide_raw(site)


# --- Ufficio Primo, Wspólna 62 (spec docs/landmarks/specs/ufficio_primo.md, 2026-11-26) -------------

## The former Presidium of the Government office (Marek Leykam, 1952; offices since 2010-12): a stone
## cube, the same front on all four sides, rusticated all over, eight bays of paired narrow windows
## on six storeys, a deep cornice under a flat roof with the rotunda's drum in the middle, a tall
## bronze door between two bronze guardians on the north and east fronts. OpenStreetMap maps it 17.5 m
## high; the site replaces that block and builds the whole cube from its four corners.
const UP_AT := Vector2(-1026.8, 816.1)       # a point in the OSM outline
## The four corners (game x, z), north-west first, walked north, east, south, west.
const UP_RING := [Vector2(-1051.4, 810.7), Vector2(-1011.3, 796.1), Vector2(-996.7, 835.9), Vector2(-1036.9, 850.5)]
## Measured from the 2021 Street View east face in sun, calmed to the palette (near PAL_CREAM_STONE).
const UP_STONE := Color("#d8d4c9")  # cooled a step after the art-director pass (the sunlit model read tan)
const UP_CORNICE := 22.9     # the cornice slab's foot; its top, the roof, is 1.1 m higher (a slab deep enough to throw a shadow band)
const UP_ROOF := 24.0
## The street block (game/data/street_blocks) that stood in for it: the pilot's first city shot showed
## that block's dome and windows over this model (the turntable builds the site alone and could not), so
## `_find_blocks` skips it and check_sites fails on any new landmark over a block.
const UP_BLOCK := "25911097"
## The dome's slate-blue sheet under the white bubbles (3D Tiles orbit views in sun; a paler grey
## lost the bubbles' contrast, Fable's review 2026-11-26).
const UP_DOME := Color("#707785")


func _find_ufficio_primo() -> void:
	var q := _tallest_at(UP_AT)
	if q.size() < 3 or not Geometry2D.is_point_in_polygon(UP_AT, q):
		return
	_add_site("ufficio_primo", [_largest(Geometry2D.offset_polygon(q, 1.0, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "ufficio_primo":
		sites[-1]["ring"] = PackedVector2Array(UP_RING)


func _build_ufficio_primo(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var trim := UP_STONE.lightened(0.04)
	# cube: the prism from 0.8 m under the ground to the cornice's foot.
	_prism(ring, g - 0.8, g + UP_CORNICE, UP_STONE, Color(0, 0, 0, 0), M_STONE)
	# The ledges that run round the whole cube (one ring each, so no two overlap at a corner).
	kit_ledge_ring(ring, g, 0.9, UP_STONE.darkened(0.12), 0.12)                    # plinth
	kit_ledge_ring(ring, g + 5.2, 0.25, trim, 0.12)                                # ground_ledge
	kit_ledge_ring(ring, g + 8.6, 0.45, trim, 0.30)                                # string_course
	for y: float in [9.4, 13.4, 17.4]:
		kit_ledge_ring(ring, g + y, 0.15, trim, 0.08)                              # sill_bands
	kit_cornice_ring(ring, g + UP_CORNICE, trim, 1.1, 1.6)                         # cornice
	# The cornice's top is grey sheet metal, not stone (3D Tiles top view): a strip 4 cm over it.
	_strip(ring, _ring_out(ring, 1.6), g + UP_ROOF + 0.04, PAL_ROOF_PALE)
	# roof: the dark membrane inside the cornice slab and the pale parapet band (1.2 m, 0.3 m up).
	_cap(ring, g + UP_ROOF, PAL_ROOF_DARK)
	var inner := _ring_out(ring, -1.2)
	_prism(ring, g + UP_ROOF, g + UP_ROOF + 0.3, PAL_ROOF_PALE, Color(0, 0, 0, 0), M_STONE)
	_strip(inner, ring, g + UP_ROOF + 0.3, PAL_ROOF_PALE)
	for i in inner.size():
		var ia := inner[i]
		var ib := inner[(i + 1) % inner.size()]
		_wall(ia, ib, g + UP_ROOF, g + UP_ROOF + 0.3, -_out(inner, ia, ib), PAL_ROOF_PALE.darkened(0.1))
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var out := _out(ring, a, b)
		# kit_front's v is to the left of from→to: walk the edge so that is the way out.
		var left := Vector2(-(b - a).y, (b - a).x)
		var w := kit_front(a, b) if left.dot(out) > 0.0 else kit_front(b, a)
		_up_face(g, w, i < 2, trim)   # the north (0) and east (1) fronts have the door
		_up_roof_lights(g, w)
	_up_dome(g, _centre(ring))
	_collide_raw(site)


## roof_lights on the current face: 11 boxes 4.0 m long (across the edge, v) x 2.4 m x 0.5 m, a tan
## frame round a pale glass top inset 0.35 m, 2.7 m apart (nearly touching, the 3D Tiles top view),
## 1.6 m in from the parapet band; 11 is the most that clears the next face's at the corners.
func _up_roof_lights(g: float, w: float) -> void:
	for k in 11:
		var u := w * 0.5 + (k - 5) * 2.7
		_lbox(u, -3.6, 1.2, 2.0, g + UP_ROOF, g + UP_ROOF + 0.5, PAL_SANDSTONE, M_STONE)
		_cap(_rect(u, -3.6, 0.85, 1.65), g + UP_ROOF + 0.53, PAL_GLASS_PALE)


## The dome's profile: (radius, height over the drum's top) from the foot to the crown, a 7 m rise
## in five frustums (the orbit views: a clear cap over the roofline, not a pancake; Fable's review).
const UP_DOME_PROFILE := [Vector2(14.0, 0.0), Vector2(12.5, 1.9), Vector2(10.5, 3.7), Vector2(8.0, 5.25),
		Vector2(5.0, 6.4), Vector2(2.0, 7.0)]


## The height of the dome's surface over the drum's top at radius r (UP_DOME_PROFILE, linear between).
func _up_dome_y(r: float) -> float:
	for i in UP_DOME_PROFILE.size() - 1:
		var a: Vector2 = UP_DOME_PROFILE[i]
		var b: Vector2 = UP_DOME_PROFILE[i + 1]
		if r >= b.x:
			return lerpf(a.y, b.y, clampf((a.x - r) / (a.x - b.x), 0.0, 1.0))
	return 7.0


## drum, dome, bubbles: the pale drum 28 m across and 1.2 m tall with 24 pale vents, the slate dome
## in five frustums (UP_DOME_PROFILE), 71 white bubble skylights 2.1 m across (20 pairs at r 10, a
## staggered ring of 12 at r 7.2, a 1 + 6 + 12 cluster on top), from the 3D Tiles views.
## Ducts (optional in the spec) are left out.
func _up_dome(g: float, c: Vector2) -> void:
	var y0 := g + UP_ROOF
	_prism(_circle(c, 14.0, 16), y0, y0 + 1.2, PAL_PALE_CONCRETE, Color(0, 0, 0, 0), M_STONE)
	for k in 24:
		var ang := TAU * (k + 0.5) / 24.0
		var pa := c + Vector2.from_angle(ang - 0.036) * 13.93
		var pb := c + Vector2.from_angle(ang + 0.036) * 13.93
		_wall(pa, pb, y0 + 0.4, y0 + 0.9, Vector2.from_angle(ang), PAL_WHITE_STONE)  # pale vent boxes (top view)
	var yb := y0 + 1.2
	_mode = M_STONE
	for i in UP_DOME_PROFILE.size() - 1:
		var a: Vector2 = UP_DOME_PROFILE[i]
		var b: Vector2 = UP_DOME_PROFILE[i + 1]
		if i == UP_DOME_PROFILE.size() - 2:
			_frustum(_circle(c, a.x, 16), yb + a.y, _circle(c, b.x, 16), yb + b.y, UP_DOME, UP_DOME)
		else:
			_frustum(_circle(c, a.x, 16), yb + a.y, _circle(c, b.x, 16), yb + b.y, UP_DOME)
	var spots: Array[Vector2] = []
	for k in 20:
		var ang := TAU * k / 20.0
		var radial := Vector2.from_angle(ang)
		var tang := Vector2(-radial.y, radial.x)
		spots.append(c + radial * 10.0 + tang * 1.25)
		spots.append(c + radial * 10.0 - tang * 1.25)
	for k in 12:  # the second, staggered ring (the orbit views)
		spots.append(c + Vector2.from_angle(TAU * (k + 0.5) / 12.0) * 7.2)
	spots.append(c)
	for k in 6:
		spots.append(c + Vector2.from_angle(TAU * k / 6.0) * 2.3)
	for k in 12:
		spots.append(c + Vector2.from_angle(TAU * (k + 0.5) / 12.0) * 4.5)
	for p: Vector2 in spots:
		var y := yb + _up_dome_y(p.distance_to(c)) - 0.05
		_pyramid(_circle(p, 1.05, 6), y, y + 0.7, PAL_WHITE_STONE)   # a 6-sided low cone, 2.1 m across (top view): 6 triangles


## One face of Ufficio Primo in the frame kit_front has set: width `w`, v out. Parts as the spec's
## table: rustication, basement_lights, ground_windows, first_frames + first_pairs, tall_pairs,
## top_pairs, then (north and east) doors, door_frames, pedestals and guardians.
func _up_face(g: float, w: float, door: bool, trim: Color) -> void:
	# rustication: grooves 0.75 m to the string course, 1.0 m above it to the frieze.
	# Flat dark quads (two triangles a groove) instead of kit_bands' boxes (ten): 92 grooves a
	# face would take 3,700 triangles of the 4,200.
	_mode = M_STONE
	for band: Array in [[0.9, 8.6, 0.75], [8.6, 22.4, 1.0]]:
		var y := g + float(band[0]) + float(band[2])
		while y + 0.15 < g + float(band[1]):
			_wall(_w(0.05, 0.03), _w(w - 0.05, 0.03), y, y + 0.15, _b, UP_STONE.darkened(0.2))
			y += float(band[2])
	var bays := _spread(2.2, w - 2.2, 8)
	var open: Array = []
	for k in bays.size():
		if not (door and (k == 3 or k == 4)):
			open.append(bays[k])
	# basement_lights under each ground window (past the plinth's 0.12 proud).
	kit_panes(open, [g + 0.3], 0.9, 0.4, PAL_GLASS_DARK, 0.14)
	# ground_windows: one per bay, sill 1.5 m, pane 1.2 x 2.6 m.
	for u: float in open:
		kit_window(u, g + 1.5, 2.6, Win.SILL, trim, PAL_GLASS_DARK, 0.6)
	# first_frames: one raised stone frame round each pair (2.3 x 1.9 m, 0.10 proud), panes in front.
	for u: float in bays:
		kit_ledge(u - 1.15, u + 1.15, g + 6.15, 1.9, trim, 0.10)
	var pair := []
	for u: float in bays:
		pair.append(u - 0.6)
		pair.append(u + 0.6)
	kit_panes(pair, [g + 6.3], 0.8, 1.5, PAL_GLASS_DARK, 0.12)                 # first_pairs
	kit_panes(pair, [g + 9.6, g + 13.6, g + 17.6], 0.75, 2.4, PAL_GLASS_DARK)   # tall_pairs
	var top := []
	for u: float in bays:
		top.append(u - 0.5)
		top.append(u + 0.5)
	kit_panes(top, [g + 21.6], 0.6, 0.6, PAL_GLASS_DARK)                       # top_pairs
	if not door:
		return
	var m := w * 0.5
	# doors: the leaf 2.2 m wide (hw 1.1), 0.9 m up on the plinth, head under the frame's lintel.
	kit_door(m, g + 0.9, 3.8, 1.1, trim, PAL_BRONZE)
	# door_frames: a stone frame 0.4 m wide, 0.25 m proud, 3.0 x 5.0 m round the door.
	kit_ledge(m - 1.5, m - 1.1, g, 5.0, trim, 0.25)
	kit_ledge(m + 1.1, m + 1.5, g, 5.0, trim, 0.25)
	kit_ledge(m - 1.1, m + 1.1, g + 4.6, 0.4, trim, 0.25)
	# pedestals and guardians: 2.6 m out of the frame, 3.2 m each side of the middle.
	for sd: float in [-1.0, 1.0]:
		var pu := m + sd * 3.2
		_lbox(pu, 2.85, 0.45, 0.45, g, g + 1.2, UP_STONE.darkened(0.08))
		_kp_figure(pu, 2.85, g + 1.2, 2.2, PAL_BRONZE)


# --- Foksal 13 and 15 (F's photos, 2026-11-05; spec docs/landmarks/specs/foksal.md) ------------

## Two restored tenements on Foksal. The masses, courtyards and zinc mansards stay LoD2's, in a
## kept skin (cream plaster behind, zinc on the roofs); the street fronts are ours, from F's
## photos. Foksal 13: salmon brick framed in white stone, eleven bays (two in each end bay under
## a crested gable, seven between), a white rusticated ground floor round an arched gate with two
## atlantes, stone balconies on the first floor, iron ones above. Foksal 15 (west): ochre brick,
## cream stone, red window frames, arched top-floor windows, and a forward bay at its east end
## with stacked iron balconies under a small gable. Frames: u along the front from its west end,
## +v out to the street (north-north-west). LoD2's front walls stand 0.3 m behind the outline.
const FK13_W := Vector2(-184.2, 27.8)    # Foksal 13's front, west end
const FK13_E := Vector2(-160.2, 18.6)    # east end
const FK15_W := Vector2(-206.5, 38.3)    # Foksal 15's front, west end (the party wall with 17)
const FK15_J := Vector2(-188.6, 31.7)    # where its front steps out to the bay
const FK15_BW := Vector2(-189.3, 29.8)   # the bay's front, west end
const FK15_BE := Vector2(-184.2, 27.8)   # east end (Foksal 13's corner)
const FK13_EAVES := 22.4
const FK15_EAVES := 20.6
const FK_BRICK13 := Color("#dc9c7a")     # salmon brick (F's street photo)
const FK_WHITE := Color("#eeebe4")
const FK_BRICK15 := Color("#c39a72")     # ochre brick (F's close-up)
const FK_CREAM := Color("#e9dfc8")
const FK_RED := Color("#8c2b2b")         # Foksal 15's window frames
const FK_GLASS := Color("#3d4652")
const FK_IRON := Color("#3f4247")
const FK_GATE := Color("#2c2a2b")
const FK_PLASTER := "#e3d6bd"            # the kept skin: courtyard and back walls
const FK_ZINC := "#6f7882"               # the mansards


func _find_foksal() -> void:
	var zone: Array = []
	for at: Vector2 in [Vector2(-161.4, 60.1), Vector2(-187.7, 51.1)]:  # the address points of 13 and 15
		var q := _tallest_at(at)
		if q.size() < 3 or not Geometry2D.is_point_in_polygon(at, q):
			return
		zone.append(q)
	_add_site("foksal", zone)
	if not sites.is_empty() and sites[-1]["key"] == "foksal":
		sites[-1]["skin"] = {"mode": 0.37, "wall": Color(FK_PLASTER), "roof": Color(FK_ZINC), "steep": 0.3}


## The frame of a front from its west end `w` to `e`, +v out to the street.
func _fk_frame(w: Vector2, e: Vector2) -> float:
	_o = w
	_a = (e - w).normalized()
	_b = Vector2(_a.y, -_a.x)
	return w.distance_to(e)


## A window in the local frame: a stone surround proud of the wall at `v`, the glass 5 cm before it
## (a red frame between the two when `frame` is opaque), and a round head when `arched`.
func _fk_window(u: float, v: float, y0: float, h: float, hw: float, stone: Color, frame := Color(0, 0, 0, 0), arched := false) -> void:
	var at := _w(u, v)
	if arched:
		var spring := y0 + h - hw
		_arch_panel(at, _a, _b, hw + 0.24, y0 - 0.2, spring, stone, 0.04, M_STONE)
		if frame.a > 0.0:
			_arch_panel(at, _a, _b, hw + 0.08, y0 - 0.06, spring, frame, 0.09, M_STONE)
		_arch_panel(at, _a, _b, hw, y0, spring, FK_GLASS, 0.14, M_GLASS)
		return
	_lbox(u, v + 0.06, hw + 0.24, 0.06, y0 - 0.22, y0 + h + 0.24, stone, M_STONE, stone)
	var keep := _mode
	if frame.a > 0.0:
		_mode = M_STONE
		_wall(_w(u - hw - 0.08, v + 0.165), _w(u + hw + 0.08, v + 0.165), y0 - 0.08, y0 + h + 0.08, _b, frame)
	_mode = M_GLASS
	# each window its own column of the glass shader's lit rooms (one every 4.5 m of `run`)
	_wall(_w(u - hw, v + 0.21), _w(u + hw, v + 0.21), y0, y0 + h, _b, FK_GLASS, u * 2.0 + 0.2)
	_mode = keep


## A balcony on the local frame: a slab from the wall at `v` out `depth`, `hw` each side of `u`,
## its floor at `y`, and a railing round its front and sides (stone balusters or iron).
func _fk_balcony(u: float, v: float, hw: float, depth: float, y: float, rail: Color, slab: Color, rail_h := 1.0) -> void:
	_lbox(u, v + depth * 0.5, hw, depth * 0.5, y - 0.28, y, slab, M_STONE, slab)
	_lbox(u, v + depth - 0.07, hw, 0.07, y, y + rail_h, rail, M_STONE, rail)
	for sd: float in [-1.0, 1.0]:
		_lbox(u + sd * (hw - 0.07), v + (depth - 0.14) * 0.5, 0.07, (depth - 0.14) * 0.5, y, y + rail_h, rail, M_STONE, rail)
	for sd: float in [-0.6, 0.6]:  # two brackets under it
		_lbox(u + sd * hw, v + depth * 0.3, 0.12, depth * 0.3, y - 0.75, y - 0.28, slab.darkened(0.08), M_STONE, slab)


## A crested gable over an end bay: a stone face from the cornice up, a pointed crest, a finial
## and an attic window.
func _fk_gable(u: float, hw: float, v: float, y: float, h: float, stone: Color) -> void:
	_lbox(u, v + 0.25, hw, 0.25, y, y + h, stone, M_STONE, stone)
	_mode = M_STONE
	_pyramid(_rect(u, v + 0.25, hw, 0.25), y + h, y + h + hw * 0.7, stone.darkened(0.04))
	_lbox(u, v + 0.25, 0.14, 0.14, y + h + hw * 0.55, y + h + hw * 0.7 + 0.9, stone, M_STONE, stone)
	_arch_panel(_w(u, v + 0.5), _a, _b, 0.5, y + 0.4, y + h - 0.6, FK_GLASS, 0.05, M_GLASS)


func _build_foksal(site: Dictionary) -> void:
	_g = _ground_under((site["zone"] as Array)[0])
	var g := _g
	var none := Color(0, 0, 0, 0)
	_build_foksal13(g, none)
	_build_foksal15(g, none)


func _build_foksal13(g: float, none: Color) -> void:
	var length := _fk_frame(FK13_W, FK13_E)
	var top := g + FK13_EAVES
	var mid := length * 0.5
	var bay := 4.8   # each end bay's width
	var ground := 6.4
	# the brick between the end bays, the end bays 0.25 m forward
	_mode = M_STONE
	_wall(_w(bay, 0.0), _w(length - bay, 0.0), g + ground, top - 0.4, _b, FK_BRICK13, bay)
	for c: float in [bay * 0.5, length - bay * 0.5]:
		_lbox(c, 0.125, bay * 0.5, 0.125, g + ground, top - 0.4, FK_BRICK13, M_STONE, FK_BRICK13)
	# the white rusticated ground floor in four courses
	for k in 4:
		var y0 := g - 0.3 + (ground + 0.3) * k / 4.0
		var y1 := g - 0.3 + (ground + 0.3) * (k + 1) / 4.0
		_lbox(mid, 0.17, mid, 0.17, y0, y1, FK_WHITE.darkened(0.05 if k % 2 == 0 else 0.0), M_STONE, FK_WHITE)
	# string courses at every floor, the cornice's frieze and its ledge
	_lbox(mid, 0.3, mid + 0.1, 0.3, g + ground, g + ground + 0.45, FK_WHITE, M_STONE, FK_WHITE.darkened(0.04))
	for y: float in [10.55, 14.45, 18.35]:
		_lbox(mid, 0.33, mid, 0.08, g + y, g + y + 0.25, FK_WHITE, M_STONE, FK_WHITE)
	_lbox(mid, 0.38, mid + 0.1, 0.13, top - 0.4, top, FK_WHITE, M_STONE, FK_WHITE)
	_lbox(mid, 0.45, mid + 0.25, 0.45, top, top + 0.5, FK_WHITE.darkened(0.03), M_STONE, FK_WHITE.darkened(0.08))
	# the windows: eleven bays over four floors (two in each end bay, seven between), pediments on
	# the first floor
	var us: Array[float] = [1.4, 3.4]
	for k in 7:
		us.append(bay + 1.15 + k * 2.3)
	us.append(length - 3.4)
	us.append(length - 1.4)
	for f in 4:
		var y := g + 6.9 + f * 3.9
		for u: float in us:
			var v := 0.25 if (u < bay or u > length - bay) else 0.0
			_fk_window(u, v, y, 2.6, 0.62, FK_WHITE)
			if f == 0:
				_lbox(u, v + 0.15, 0.95, 0.15, y + 2.86, y + 3.3, FK_WHITE, M_STONE, FK_WHITE.darkened(0.05))
	# the ground floor's windows each side of the gate
	for u: float in [1.4, 3.4, 6.1, 8.5, length - 8.5, length - 6.1, length - 3.4, length - 1.4]:
		_fk_window(u, 0.34, g + 1.3, 3.0, 0.58, FK_WHITE.darkened(0.06))
	# the gate: a dark arched door in a white surround, an atlas each side carrying the balcony
	_arch_panel(_w(mid, 0.34), _a, _b, 1.75, g - 0.1, g + 3.5, FK_WHITE.darkened(0.1), 0.04, M_STONE)
	_arch_panel(_w(mid, 0.34), _a, _b, 1.35, g, g + 3.3, FK_GATE, 0.09, M_STONE)
	for sd: float in [-1.0, 1.0]:
		_lbox(mid + sd * 2.15, 0.5, 0.32, 0.16, g + 3.0, g + 5.7, FK_WHITE, M_STONE, FK_WHITE)
		_lbox(mid + sd * 2.15, 0.5, 0.2, 0.14, g + 5.7, g + 6.1, FK_WHITE.darkened(0.04), M_STONE, FK_WHITE)
	# balconies: stone on the first floor (both end bays, the middle), iron above
	for c: float in [bay * 0.5, mid, length - bay * 0.5]:
		var v := 0.0 if c == mid else 0.25
		_fk_balcony(c, v + 0.34 if c == mid else v, 2.3, 0.95, g + 6.9, FK_WHITE, FK_WHITE.darkened(0.04))
	for c: float in [bay * 0.5, length - bay * 0.5]:
		_fk_balcony(c, 0.25, 2.1, 0.8, g + 10.8, FK_IRON, FK_IRON.lightened(0.25), 0.9)
	for c: float in [bay * 0.5, mid, length - bay * 0.5]:
		_fk_balcony(c, 0.0 if c == mid else 0.25, 2.1, 0.8, g + 14.7, FK_IRON, FK_IRON.lightened(0.25), 0.9)
	# the crested gables over the end bays
	for c: float in [bay * 0.5, length - bay * 0.5]:
		_fk_gable(c, 2.0, 0.0, top + 0.5, 3.4, FK_WHITE)


func _build_foksal15(g: float, none: Color) -> void:
	var length := _fk_frame(FK15_W, FK15_J)
	var top := g + FK15_EAVES
	var mid := length * 0.5
	var ground := 5.6
	_mode = M_STONE
	_wall(_w(0.0, 0.0), _w(length, 0.0), g + ground, top - 0.4, _b, FK_BRICK15)
	for k in 3:
		var y0 := g - 0.3 + (ground + 0.3) * k / 3.0
		_lbox(mid, 0.14, mid, 0.14, y0, y0 + (ground + 0.3) / 3.0, FK_CREAM.darkened(0.06 if k % 2 == 0 else 0.0), M_STONE, FK_CREAM)
	_lbox(mid, 0.25, mid, 0.25, g + ground, g + ground + 0.4, FK_CREAM, M_STONE, FK_CREAM.darkened(0.04))
	for y: float in [9.35, 13.05]:
		_lbox(mid, 0.06, mid, 0.06, g + y, g + y + 0.22, FK_CREAM, M_STONE, FK_CREAM)
	_lbox(mid, 0.35, mid, 0.12, top - 0.4, top, FK_CREAM, M_STONE, FK_CREAM)
	_lbox(mid, 0.4, mid, 0.4, top, top + 0.45, FK_CREAM.darkened(0.04), M_STONE, FK_CREAM.darkened(0.08))
	# six bays: arched openings on the ground floor, framed windows over four floors (red frames,
	# the top floor's round-headed)
	for k in 6:
		var u := 1.85 + k * 3.1
		_fk_window(u, 0.28, g + 0.7, 3.4, 0.7, FK_CREAM.darkened(0.08), Color(0, 0, 0, 0), true)
		for f in 4:
			_fk_window(u, 0.0, g + 6.0 + f * 3.7, 2.5, 0.65, FK_CREAM, FK_RED, f == 3)
	for u: float in [1.85 + 3.1, 1.85 + 3.1 * 4.0]:
		_fk_balcony(u, 0.0, 1.3, 0.75, g + 13.4, FK_IRON, FK_IRON.lightened(0.25), 0.9)
	# the bay's west side, in brick over the stone
	var side := _fk_frame(FK15_J, FK15_BW)
	_b = Vector2(-_a.y, _a.x) if Vector2(-_a.y, _a.x).dot(FK15_W - FK15_J) > 0.0 else Vector2(_a.y, -_a.x)
	_lbox(side * 0.5, 0.07, side * 0.5, 0.07, g - 0.3, g + ground, FK_CREAM.darkened(0.04), M_STONE, FK_CREAM)
	_mode = M_STONE
	_wall(_w(0.0, 0.03), _w(side, 0.03), g + ground, top - 0.4, _b, FK_BRICK15)
	# the bay: two windows a floor, an iron balcony across it on three floors, a small gable
	var bl := _fk_frame(FK15_BW, FK15_BE)
	var bm := bl * 0.5
	var btop := top + 0.6
	_mode = M_STONE
	_wall(_w(0.0, 0.0), _w(bl, 0.0), g + ground, btop - 0.4, _b, FK_BRICK15)
	for k in 3:
		var y0 := g - 0.3 + (ground + 0.3) * k / 3.0
		_lbox(bm, 0.14, bm, 0.14, y0, y0 + (ground + 0.3) / 3.0, FK_CREAM.darkened(0.06 if k % 2 == 0 else 0.0), M_STONE, FK_CREAM)
	_lbox(bm, 0.25, bm, 0.25, g + ground, g + ground + 0.4, FK_CREAM, M_STONE, FK_CREAM.darkened(0.04))
	_lbox(bm, 0.35, bm, 0.12, btop - 0.4, btop, FK_CREAM, M_STONE, FK_CREAM)
	_lbox(bm, 0.4, bm, 0.4, btop, btop + 0.45, FK_CREAM.darkened(0.04), M_STONE, FK_CREAM.darkened(0.08))
	_fk_window(bm, 0.28, g + 0.7, 3.4, 0.9, FK_CREAM.darkened(0.08), Color(0, 0, 0, 0), true)
	for f in 4:
		for u: float in [bm - 1.25, bm + 1.25]:
			_fk_window(u, 0.0, g + 6.0 + f * 3.7, 2.5, 0.6, FK_CREAM, FK_RED, f >= 2)
		if f >= 1:
			_fk_balcony(bm, 0.0, bl * 0.5 - 0.3, 0.85, g + 6.0 + f * 3.7, FK_IRON, FK_IRON.lightened(0.25), 0.9)
	_fk_gable(bm, bl * 0.5 - 0.4, 0.0, btop + 0.45, 2.0, FK_CREAM)


# --- Al. Jerozolimskie, the south side between Emilii Plater and Poznańska (F's six photos, 2026-11-15; spec docs/landmarks/specs/jerozolimskie57.md) ---

## The row across from the Palace of Culture where Nowa Jerozolima was (no. 57): from the
## Poznańska end, the freshly restored red tenement under its steep orange tile roof, the plain
## white house with the big white wrap over its roof, the white house with the arched gate and the
## ornate one with the zinc mansard at the Emilii Plater corner (Centrum LIM stands beyond). The five
## OpenStreetMap outlines (116, 117, 849, 847, 848 of centrum.json) are cut into the four houses by
## the party walls read off the photos and built whole. Frame: u runs from the east end west along
## the front line, v out to the street (north-north-west). Arcade canopies, the building site's
## barriers and scaffold stand in front of the row.
const JR_E := Vector2(-1115.5, 581.2)      # the front line's east end
const JR_A := Vector2(-0.9447, 0.3296)     # along it, to the west
const JR_LEN := 148.7
const JR_CUT: Array[float] = [0.0, 26.2, 70.0, 104.3, 148.7]    # red | plain | arched | ornate
const JR_AT: Array[Vector2] = [Vector2(-1240.0, 642.0), Vector2(-1219.0, 635.0), Vector2(-1197.0, 615.0),
		Vector2(-1166.0, 604.0), Vector2(-1133.0, 596.0)]       # a point in each outline
const JR_DEPTH := 13.0                     # the front range's depth; behind it the plan stays lower
const JR_RED := Color("#a0463d")           # the restored tenement's red (photo 2, calmed)
const JR_RED_L := Color("#b9604f")
const JR_PLASTER := Color("#ddd8de")       # its upper floors: a pale lilac grey
const JR_WHITE := Color("#e7e6ec")         # the three white houses
const JR_BASE := Color("#c9c9cf")          # their rusticated ground floors
const JR_ZINC := Color("#5b5f64")
const JR_TILE := Color("#c4602f")          # the orange roof tile
const JR_GREEN := Color("#2d5846")         # the arcade canopies' painted steel
const JR_SCREEN := Color("#eef0f4")        # the white wrap
const JR_BOARD := Color("#b8975e")         # the hoarding boards
const JR_FRAME := Color("#5a4a34")         # the arched house's brown window frames


func _find_jerozolimskie57() -> void:
	var parts: Array[PackedVector2Array] = []
	var zone: Array = []
	for at: Vector2 in JR_AT:
		var q := _tallest_at(at)
		if q.size() < 3 or not Geometry2D.is_point_in_polygon(at, q):
			return
		parts.append(q)
		zone.append(q)
	kit_front(JR_E, JR_E + JR_A * JR_LEN)
	zone.append(_urect(-9.0, JR_LEN, 0.1, 5.0))   # the pavement strip with the canopies and the barriers
	_add_site("jerozolimskie57", zone)
	if not sites.is_empty() and sites[-1]["key"] == "jerozolimskie57":
		sites[-1]["parts"] = parts


## One house's plan: the outlines cut to its strip of the front, with a rim along the front line so the
## outline's small jogs leave no gap (v < 0 is inside).
func _jr_mass(parts: Array, u0: float, u1: float) -> PackedVector2Array:
	var cur := _urect(u0, u1, -2.5, 0.0)
	var box := _urect(u0, u1, -80.0, 0.0)
	for q: PackedVector2Array in parts:
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(q, box):
			if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
				continue
			cur = _largest(Geometry2D.merge_polygons(cur, piece))
	return cur


func _jr_axes(u0: float, u1: float, n: int) -> Array[float]:
	var out: Array[float] = []
	for i in n:
		out.append(u0 + (float(i) + 0.5) * (u1 - u0) / float(n))
	return out


## Plain panes on every wall that is neither the front nor a party wall: the sides and the yards.
func _jr_sides(mass: PackedVector2Array, g: float, rows: Array, trim: Color) -> void:
	var n := mass.size()
	for k in n:
		var p := mass[k]
		var q := mass[(k + 1) % n]
		kit_front(JR_E, JR_E + JR_A * JR_LEN)
		var lp := _local(p)
		var lq := _local(q)
		if absf(lp.y) < 0.3 and absf(lq.y) < 0.3:
			continue
		var party := false
		for cut: float in [JR_CUT[1], JR_CUT[2], JR_CUT[3]]:
			if absf(lp.x - cut) < 0.3 and absf(lq.x - cut) < 0.3:
				party = true
		if party:
			continue
		var le := kit_front(p, q) if Geometry2D.is_polygon_clockwise(mass) else kit_front(q, p)
		if le < 3.0:
			continue
		var m := maxi(1, floori(le / 4.6))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		kit_panes(cs, rows, 1.3, 1.9, trim, 0.03)
		kit_panes(cs, rows, 1.05, 1.7, PAL_GLASS_DARK, 0.06)
	kit_front(JR_E, JR_E + JR_A * JR_LEN)


func _build_jerozolimskie57(site: Dictionary) -> void:
	var parts: Array = site["parts"]
	_mode = M_STONE
	_jr_red(parts)
	_jr_plain(parts)
	_jr_arched(parts)
	_jr_ornate(parts)
	_jr_street()


## The mass of a house: the whole plan to a lower flat roof, the front range up to its eaves in
## `layers` (pairs of [top above ground, colour] from the foot up). Returns the front range.
func _jr_body(mass: PackedVector2Array, g: float, u0: float, u1: float, eave: float, layers: Array,
		rear: Color) -> PackedVector2Array:
	var none := Color(0, 0, 0, 0)
	_prism(mass, g - 1.0, g + eave - 2.4, rear, PAL_ROOF_GRAVEL.darkened(0.1), M_STONE, M_STONE)
	var rng := _largest(Geometry2D.intersect_polygons(mass, _urect(u0, u1, -JR_DEPTH, 0.0)))
	var y0 := g - 1.0
	for layer: Array in layers:
		_prism(rng, y0, g + float(layer[0]), layer[1], none, M_STONE)
		y0 = g + float(layer[0])
	_collide(mass)
	pocket_rings.append(mass)
	return rng


# --- no. 57, the red tenement (photos 1, 2, 3) -----------------------------------------------------

func _jr_red(parts: Array) -> void:
	var u0: float = JR_CUT[0]
	var u1: float = JR_CUT[1]
	kit_front(JR_E, JR_E + JR_A * JR_LEN)
	var mass := _jr_mass(parts, u0, u1)
	var g := _ground_under(mass)
	_g = g
	var eave := 23.0
	var bay0 := 17.6      # the forward bay on the west side: red to the first balcony, plaster, red crown
	var none := Color(0, 0, 0, 0)
	_jr_body(mass, g, u0, bay0, eave, [[8.0, JR_RED], [18.0, JR_PLASTER], [eave, JR_RED]], JR_PLASTER)
	var bay := _urect(bay0, u1, -JR_DEPTH, 0.9)
	_prism(bay, g - 1.0, g + 8.0, JR_RED, none, M_STONE)
	_prism(bay, g + 8.0, g + 17.4, JR_PLASTER, none, M_STONE)
	_prism(bay, g + 17.4, g + eave + 0.9, JR_RED, JR_RED.darkened(0.1), M_STONE, M_STONE)
	_jr_sides(mass, g, [g + 3.0, g + 9.0], JR_PLASTER.lightened(0.05))
	# the roof: a hip over the range, a stepped gable at the east end, three zinc dormers
	_hip((u0 + bay0) * 0.5, -JR_DEPTH * 0.5, (bay0 - u0) * 0.5, JR_DEPTH * 0.5, g + eave, 9.5, JR_TILE)
	kit_front(_w(2.9, 0.0), _w(2.9, 1.0))
	_gable(0.05, -4.5, 0.0, 2.4, g + eave, 4.4, JR_PLASTER, JR_TILE, true)
	kit_front(JR_E, JR_E + JR_A * JR_LEN)
	for u: float in [8.6, 11.8, 15.0]:
		_kbox(u - 0.95, u + 0.95, -4.8, -2.0, g + eave + 2.3, g + eave + 5.0, JR_ZINC)
		kit_face(-2.0)
		kit_panes([u], [g + eave + 3.0], 1.1, 1.5, PAL_GLASS_DARK, 0.05)
		kit_face(0.0)
	# the lower floors: banded red, windows in lighter red frames, the gabled entrance
	var ground := _jr_axes(0.4, bay0 - 0.3, 6)
	for u: float in ground:
		if absf(u - 13.4) > 1.6:   # the entrance stands here
			kit_window(u, g + 1.0, 2.4, Win.SILL, JR_RED_L, PAL_GLASS_DARK, 0.62)
		kit_window(u, g + 4.5, 2.4, Win.SILL, JR_RED_L, PAL_GLASS_DARK, 0.62)
	kit_ledge(0.0, bay0, g + 7.4, 0.25, JR_RED_L, 0.1)
	for y: float in [8.9, 12.2, 15.5]:
		for u: float in ground:
			kit_window(u, g + y, 2.3, Win.SILL_HEAD, JR_RED, PAL_GLASS_DARK, 0.6)
	# the balconies: a red balustrade across the left part under the white floors and under the top
	# floor, two white iron ones between
	kit_balcony((u0 + bay0) * 0.5, g + 8.9, (bay0 - u0) * 0.5 - 0.3, Balcony.STONE, JR_RED, JR_RED, 1.1)
	kit_balcony((u0 + bay0) * 0.5, g + 18.6, (bay0 - u0) * 0.5 - 0.3, Balcony.STONE, JR_RED, JR_RED, 1.1)
	for y: float in [12.2, 15.5]:
		kit_balcony(5.8, g + y, 1.5, Balcony.IRON, PAL_ALUMINIUM, JR_RED, 0.9)
	# the top floor: red piers between tall windows
	for u: float in ground:
		kit_window(u, g + 18.6, 2.4, Win.PLAIN, JR_RED, PAL_GLASS_DARK, 0.65)
	for k in 7:
		kit_pilaster(0.2 + float(k) * (bay0 - 0.4) / 6.0, g + 17.5, g + eave, JR_RED, 0.5, 0.35)
	kit_cornice(0.0, bay0, g + eave, JR_RED, 0.45, 0.7)
	# the entrance: a carved red gable over an arched door
	kit_face(0.0)
	kit_door(13.4, g, 3.4, 1.2, JR_RED_L, PAL_DARK_DOOR, true)
	kit_pediment(13.4, 1.9, g + 3.95, 1.6, JR_RED_L, JR_TILE, 0.5)
	# the bay: three windows a floor, the big arch under it
	kit_face(0.9)
	var wb := _jr_axes(bay0 + 0.3, u1 - 0.3, 3)
	for u: float in wb:
		kit_window(u, g + 4.5, 2.4, Win.SILL, JR_RED_L, PAL_GLASS_DARK, 0.6)
		for y: float in [8.9, 12.2, 15.5]:
			kit_window(u, g + y, 2.3, Win.SILL_HEAD, JR_RED, PAL_GLASS_DARK, 0.6)
		kit_window(u, g + 18.6, 2.4, Win.PLAIN, JR_RED, PAL_GLASS_DARK, 0.6)
	kit_door((bay0 + u1) * 0.5, g, 3.2, 1.3, JR_RED_L, PAL_DARK_DOOR, true)
	kit_cornice(bay0, u1, g + eave + 0.9, JR_RED, 0.5, 0.6)
	kit_face(0.0)


# --- no. 59, the plain white house under its wrap (photos 1, 3, 5) --------------------------------

func _jr_plain(parts: Array) -> void:
	var u0: float = JR_CUT[1]
	var u1: float = JR_CUT[2]
	kit_front(JR_E, JR_E + JR_A * JR_LEN)
	var mass := _jr_mass(parts, u0, u1)
	var g := _ground_under(mass)
	_g = g
	var eave := 18.2
	_jr_body(mass, g, u0, u1, eave, [[5.2, JR_BASE], [eave, JR_WHITE]], JR_WHITE)
	_jr_sides(mass, g, [g + 3.0, g + 9.0], JR_WHITE.darkened(0.04))
	kit_ledge(u0, u1, g + 5.3, 0.35, JR_WHITE.lightened(0.05), 0.12)
	var gate := 42.4
	var axes: Array[float] = []
	for k in range(-5, 10):
		axes.append(gate + float(k) * 2.75)
	for u: float in axes:
		for y: float in [5.9, 9.2, 12.5]:
			if absf(u - gate) < 0.1 and y < 6.0:
				continue
			kit_window(u, g + y, 2.2, Win.SILL, JR_WHITE.lightened(0.05), PAL_GLASS_DARK, 0.55)
		kit_window(u, g + 15.7, 1.4, Win.PLAIN, JR_WHITE, PAL_GLASS_DARK, 0.5)
	# the arched gate with its iron balcony and the tall door over it
	kit_door(gate, g, 3.7, 1.3, JR_WHITE.lightened(0.05), PAL_DARK_DOOR, true)
	kit_window(gate, g + 5.9, 2.8, Win.SILL_HEAD, JR_WHITE.lightened(0.05), PAL_GLASS_DARK, 0.7)
	kit_balcony(gate, g + 5.9, 1.7, Balcony.IRON, PAL_IRON, JR_WHITE, 0.9)
	# the shops: dark glass between pilasters, east of the gate and west of it
	for u: float in [29.2, 33.6, 38.0, 47.8, 52.2, 56.6, 61.0, 65.4]:
		kit_shop_bay(u, g + 0.5, g + 4.0, 1.7, JR_WHITE.lightened(0.05), PAL_GLASS_DARK)
	kit_cornice(u0, u1, g + eave, JR_WHITE.lightened(0.04), 0.45, 0.8)
	kit_attic(u0, u1, g + eave, JR_WHITE, 0.9, Attic.WALL)
	# the wrap: a white screen behind the parapet, seams every 7 m
	_ubox(u0 + 0.5, u1 - 0.5, -3.2, -2.7, g + eave, g + eave + 10.4, JR_SCREEN, M_STONE, JR_SCREEN)
	for k in range(1, 6):
		var us := u0 + 0.5 + float(k) * (u1 - u0 - 1.0) / 6.0
		_ubox(us - 0.04, us + 0.04, -2.7, -2.64, g + eave, g + eave + 10.4, JR_SCREEN.darkened(0.08), M_STONE)


# --- the arched house (photos 4, 5, 6) -------------------------------------------------------------

func _jr_arched(parts: Array) -> void:
	var u0: float = JR_CUT[2]
	var u1: float = JR_CUT[3]
	kit_front(JR_E, JR_E + JR_A * JR_LEN)
	var mass := _jr_mass(parts, u0, u1)
	var g := _ground_under(mass)
	_g = g
	var eave := 22.4
	_jr_body(mass, g, u0, u1, eave, [[5.3, JR_BASE], [eave, JR_WHITE]], JR_WHITE)
	_jr_sides(mass, g, [g + 3.0, g + 9.0], JR_WHITE.darkened(0.04))
	kit_ledge(u0, u1, g + 5.4, 0.35, JR_WHITE.lightened(0.05), 0.12)
	var axes := _jr_axes(u0, u1, 7)
	var trim := JR_WHITE.lightened(0.05)
	for u: float in axes:
		kit_window(u, g + 5.9, 2.5, Win.SILL, trim, JR_FRAME, 0.85)
		kit_window(u, g + 9.3, 2.7, Win.ARCHED, trim, JR_FRAME, 0.85)
		kit_window(u, g + 12.9, 2.5, Win.SILL, trim, JR_FRAME, 0.85)
		kit_window(u, g + 16.3, 2.5, Win.SILL, trim, JR_FRAME, 0.85)
		kit_window(u, g + 19.7, 1.5, Win.PLAIN, trim, JR_FRAME, 0.7)
	for i: int in [0, 3, 6]:
		kit_balcony(axes[i], g + 5.9, 1.4, Balcony.STONE, trim, trim, 0.9)
	# the arched gate on the middle axis, the lounge's door and shop window beside it
	kit_door(axes[3], g, 3.7, 1.3, trim, PAL_DARK_DOOR, true)
	for i: int in [0, 1, 2, 4, 6]:
		kit_shop_bay(axes[i], g + 0.5, g + 4.0, 1.7, trim, PAL_GLASS_DARK)
	kit_door(axes[5], g + 0.3, 3.0, 0.8, trim, PAL_OAK)
	_usign("TUTAJ", axes[5], 0.14, g + 4.1, _b, 3.4, 0.55, Color("#e8892b"))
	kit_cornice(u0, u1, g + eave, trim, 0.5, 0.9)
	kit_attic(u0, u1, g + eave, JR_WHITE, 0.8, Attic.WALL)


# --- the ornate house at the Emilii Plater corner (photos 4, 5, 6) -------------------------------

func _jr_ornate(parts: Array) -> void:
	var u0: float = JR_CUT[3]
	var u1: float = JR_CUT[4]
	kit_front(JR_E, JR_E + JR_A * JR_LEN)
	var mass := _jr_mass(parts, u0, u1)
	var g := _ground_under(mass)
	_g = g
	var eave := 22.6
	_jr_body(mass, g, u0, u1, eave, [[5.4, JR_BASE], [eave, JR_WHITE]], JR_WHITE)
	_jr_sides(mass, g, [g + 3.0, g + 9.0], JR_WHITE.darkened(0.04))
	kit_ledge(u0, u1, g + 5.5, 0.4, JR_WHITE.lightened(0.06), 0.14)
	var axes := _jr_axes(u0, u1, 12)
	var trim := JR_WHITE.lightened(0.06)
	for u: float in axes:
		kit_window(u, g + 5.9, 2.5, Win.SILL, trim, PAL_GLASS_DARK, 0.62)
		kit_window(u, g + 9.3, 2.6, Win.PEDIMENT, trim, PAL_GLASS_DARK, 0.62)
		kit_window(u, g + 12.7, 2.7, Win.ARCHED, trim, PAL_GLASS_DARK, 0.62)
		kit_window(u, g + 16.1, 2.5, Win.SILL, trim, PAL_GLASS_DARK, 0.62)
		kit_window(u, g + 19.4, 2.2, Win.PLAIN, trim, PAL_GLASS_DARK, 0.62)
	# long stone balconies on the first floor, a small iron one on the third
	for i: int in [2, 9]:
		kit_balcony(axes[i], g + 5.9, 5.4, Balcony.STONE, trim, trim, 1.0)
	kit_balcony(axes[6], g + 12.7, 1.3, Balcony.IRON, PAL_IRON, trim, 0.8)
	for u: float in [u0 + 0.6, u1 - 0.6]:
		kit_pilaster(u, g + 5.5, g + eave, trim, 0.7, 0.14)
	# the shops under the canopy, the coffee house's glass and sign
	for i: int in range(1, 12, 2):
		kit_shop_bay(axes[i], g + 0.5, g + 4.0, 2.4, trim, PAL_GLASS_DARK)
	_usign("PARZYBUDA", (axes[3] + axes[8]) * 0.5, 0.14, g + 4.3, _b, 9.0, 0.7, Color("#d8b85a"))
	kit_cornice(u0, u1, g + eave, trim, 0.55, 1.0)
	# the zinc mansard over the range, big dormers, the raised box at the west end
	_mode = M_STONE
	_frustum(_urect(u0, u1, -JR_DEPTH, 0.0), g + eave + 0.5, _urect(u0 + 2.6, u1 - 2.6, -JR_DEPTH + 2.6, -2.6),
			g + eave + 4.4, JR_ZINC, JR_ZINC.darkened(0.06))
	_ubox(u0, u1, -JR_DEPTH, 0.0, g + eave, g + eave + 0.5, JR_ZINC, M_STONE)
	for k in 6:
		var u := u0 + 3.2 + float(k) * 6.2
		_kbox(u - 1.2, u + 1.2, -3.6, -1.1, g + eave + 1.5, g + eave + 4.0, JR_ZINC)
		kit_face(-1.1)
		kit_panes([u], [g + eave + 1.9], 1.5, 1.6, PAL_GLASS_DARK, 0.05)
		kit_face(0.0)
	_ubox(u1 - 9.2, u1 - 0.4, -JR_DEPTH + 0.8, -0.4, g + eave + 0.5, g + eave + 6.8, JR_ZINC, M_STONE, JR_ZINC.darkened(0.06))
	kit_face(-0.4)
	kit_panes([u1 - 4.8, u1 - 7.4, u1 - 2.2], [g + eave + 2.2], 1.6, 2.4, PAL_GLASS_DARK, 0.05)
	kit_face(0.0)


# --- the pavement: canopies, showcases, barriers, scaffold -------------------------------------

## A green steel arcade over the pavement from u0 to u1, 3 m deep, posts every 5 m, a deep front beam.
func _jr_canopy(u0: float, u1: float, g: float) -> void:
	_mode = M_STONE
	_ubox(u0, u1, 0.0, 3.2, g + 4.5, g + 4.75, JR_GREEN.darkened(0.15), M_STONE, JR_GREEN)
	_ubox(u0, u1, 3.0, 3.2, g + 4.0, g + 4.5, JR_GREEN, M_STONE)
	var n := maxi(2, roundi((u1 - u0) / 5.0))
	for i in n + 1:
		var u := u0 + 0.1 + (u1 - u0 - 0.2) * float(i) / float(n)
		_ubox(u - 0.09, u + 0.09, 3.0, 3.18, g, g + 4.0, JR_GREEN, M_STONE)
		if i < n:
			var um := u + (u1 - u0 - 0.2) / float(n) * 0.5
			_ubox(um - 0.05, um + 0.05, 0.1, 3.0, g + 4.2, g + 4.4, JR_GREEN, M_STONE)


## Lit ad showcases on the wall under a canopy: `cols` are the posters' colours (parodies, no text).
func _jr_showcases(u0: float, cols: Array, g: float) -> void:
	var w := 2.7
	for i in cols.size():
		var a := u0 + float(i) * (w + 0.25)
		_ubox(a, a + w, 0.0, 0.35, g + 0.7, g + 3.3, PAL_DARK_STEEL, M_STONE)
		_ubox(a + 0.15, a + w - 0.15, 0.35, 0.4, g + 0.85, g + 3.15, cols[i], M_LAMP)


func _jr_street() -> void:
	kit_front(JR_E, JR_E + JR_A * JR_LEN)
	var g := _ground_under(_urect(0.0, JR_LEN, -6.0, 0.0))
	_g = g
	_jr_canopy(50.5, 83.5, g)
	_jr_showcases(54.3, [Color("#2b8fa3"), Color("#d4542c"), Color("#7a5236"), Color("#3a5ca8")], g)
	_jr_canopy(110.7, 140.7, g)
	_jr_showcases(125.8, [Color("#e2662e"), Color("#c23a2f"), Color("#d8b92c")], g)
	# the building site at the red house: striped barriers on the pavement, a low scaffold on the wall
	_mode = M_STONE
	for i in 15:
		var a := -9.0 + float(i) * 2.4
		_ubox(a, a + 2.4, 3.2, 3.36, g, g + 1.15, PAL_SIGNAL_RED if i % 2 == 0 else Color("#f0eeea"), M_STONE, PAL_PALE_CONCRETE)
	for i in 12:
		var u := 0.8 + float(i) * 2.3
		_ubox(u - 0.05, u + 0.05, 1.15, 1.25, g, g + 4.2, PAL_DARK_STEEL, M_STONE)
	for y: float in [2.0, 4.0]:
		_ubox(0.6, 25.6, 1.15, 1.25, g + y, g + y + 0.1, PAL_DARK_STEEL, M_STONE)
	_ubox(0.6, 25.6, 0.3, 1.25, g + 4.0, g + 4.1, JR_BOARD, M_STONE, JR_BOARD)
	for u: float in [2.8, 8.4]:
		_ubox(u, u + 3.4, 0.4, 0.46, g + 0.3, g + 3.2, JR_BOARD, M_STONE)


# --- Warsaw modernism: Młotek, Kozia 9, Karowa 18a (F, 2026-11-03; docs/design/modernism-collection.md) ---

## A window on a wall's plane a→b: a white frame 4 cm proud, the glass 9 cm proud and 10 cm inside it
## (under 3 cm apart, _wall takes the two for one plane and cuts the glass away).
func _framed(a: Vector2, b: Vector2, y0: float, y1: float, out: Vector2, frame: Color, glass: Color, run := 0.0) -> void:
	var keep := _mode
	var e := (b - a).normalized()
	_mode = M_STONE
	_wall(a + out * 0.04, b + out * 0.04, y0, y1, out, frame, run)
	_mode = M_GLASS
	_wall(a + e * 0.1 + out * 0.09, b - e * 0.1 + out * 0.09, y0 + 0.1, y1 - 0.1, out, glass, run)
	_mode = keep


## A hanging volume: `poly`'s walls and top, and its underside, which the street sees.
func _hang(poly: PackedVector2Array, y0: float, y1: float, wall: Color, top: Color, under: Color) -> void:
	_prism(poly, y0, y1, wall, top, M_STONE, M_STONE)
	_mode = M_STONE
	_soffit(poly, y0, under)


## A flat roof from above: `poly` in a pale rim, the deck 40 cm inside it and 5 cm over it.
func _rimmed(poly: PackedVector2Array, y: float, rim: Color, deck: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	_cap(poly, y, rim)
	var inner := _largest(Geometry2D.offset_polygon(poly, -0.4, Geometry2D.JOIN_MITER))
	if inner.size() >= 3:
		_prism(inner, y, y + 0.05, deck, deck, M_STONE, M_STONE)
	_mode = keep


## Młotek, Smolna 8 (1964-76, Jan Bogusławski and Bohdan Gniewiewski), from the Mac photo gather
## (docs/landmarks/photo-reports/mlotek.md: 17 Commons photos and the GUGiK ortho). The slab of
## grey-brown roughcast with its strip windows, the balconies with yellow edges stacked up both
## ends, and on top the hammer's head: two storeys wider and 7.5 m longer than the slab, jutting
## out over the east end on a dark soffit, a glazed band round it, its end face leaning out. The
## concrete pergola stands at the east foot. Frame: u along the slab from its west end, v from
## the north side to the south side. Spec mlotek.md.
const ML_AT := Vector2(83.0, 32.0)
const ML_O := Vector2(63.36, 31.27)
const ML_A := Vector2(0.9252, -0.3794)
const ML_LEN := 35.5
const ML_WID := 17.1
const ML_GROUND := 3.0       # the ground storey
const ML_FLOOR := 2.8
const ML_FLOORS := 19
const ML_NECK := 56.2        # the slab's top, over the ground
const ML_NOTCH := 54.5       # the dark notch over the west balconies starts here
const ML_LEDGE := 57.0       # the head's underside
const ML_BAND := 58.0        # the glazed band's sill
const ML_BAND_TOP := 60.2
const ML_TOP := 62.8         # the head's roof, flat: photo 3 shows a straight top, LoD2's deck averages map height 67.8
const ML_JAW := 43.0         # the head's east end, in u (the ortho's roof length)
const ML_JAW_ROOT := 54.5    # the underside where it leaves the slab, a storey under the ledge (photos 3, 13)
const ML_WALL := Color("#8f877a")
const ML_HEAD := Color("#8a857c")
const ML_SOFFIT := Color("#4a4743")
const ML_YELLOW := Color("#d8bb45")
const ML_DARK := Color("#3a3d40")
const ML_RAIL := Color("#6e6b65")
const ML_FRAME := Color("#e8e8e4")
const ML_GLASS := Color("#2e3640")
const ML_BASE := Color("#8c8a86")
const ML_CONCRETE := Color("#7f7b74")
const ML_ROOF := Color("#6d6f72")
const ML_RIM := Color("#c8c6bf")
## The long faces' four strip windows and the column of single ones, in u.
const ML_STRIPS := [Vector2(5.3, 9.5), Vector2(9.9, 14.1), Vector2(14.5, 18.7), Vector2(19.1, 23.7), Vector2(25.7, 28.1)]


func _find_mlotek() -> void:
	var q := _tallest_at(ML_AT)
	if q.size() < 3 or not Geometry2D.is_point_in_polygon(ML_O + ML_A * 18.0 + Vector2(-ML_A.y, ML_A.x) * 8.0, q):
		return
	_add_site("mlotek", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "mlotek":
		sites[-1]["ring"] = _simplify(q, 0.4)
		sites[-1]["raw"] = q


func _build_mlotek(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_o = ML_O
	_a = ML_A
	_b = Vector2(-ML_A.y, ML_A.x)   # from the north side to the south side
	_mode = M_STONE
	# window_bands, stair_column: 19 storeys on both long faces.
	for k in ML_FLOORS:
		var y := g + ML_GROUND + ML_FLOOR * k + 0.85
		for s: Vector2 in ML_STRIPS:
			_framed(_w(s.x, ML_WID), _w(s.y, ML_WID), y, y + 1.5, _b, ML_FRAME, ML_GLASS, s.x + 4.5 * k)
			_framed(_w(s.x, 0.0), _w(s.y, 0.0), y, y + 1.5, -_b, ML_FRAME, ML_GLASS, s.x + 13.5 * k)
	# shaft: the slab, narrower behind the west balconies, the end walls behind both stacks.
	_lbox(19.25, ML_WID * 0.5, 13.75, ML_WID * 0.5, g - 0.8, g + ML_NECK, ML_WALL, M_STONE, ML_SOFFIT)
	_lbox(4.15, ML_WID * 0.5, 1.35, 6.35, g - 0.8, g + ML_NOTCH, ML_WALL, M_STONE, ML_SOFFIT)
	for v: float in [0.25, ML_WID - 0.25]:
		_lbox(34.25, v, 1.25, 0.25, g - 0.8, g + ML_NECK, ML_WALL, M_STONE, ML_SOFFIT)
	# base: the ground storey's lobby glass and the plinth on the south front.
	_framed(_w(8.0, ML_WID), _w(24.0, ML_WID), g + 0.6, g + ML_GROUND - 0.3, _b, ML_BASE, ML_GLASS, 8.0)
	_framed(_w(26.0, ML_WID), _w(30.0, ML_WID), g + 0.3, g + ML_GROUND - 0.3, _b, ML_BASE, ML_GLASS, 26.0)
	_band(_rect(19.25, ML_WID * 0.5, 13.75, ML_WID * 0.5), 0.12, g - 0.6, g + 0.6, ML_BASE)
	# balcony_strip: a slab with a yellow edge on every storey up both ends, a dark balustrade on
	# it, the glass doors behind.
	for k in ML_FLOORS + 1:
		var y := g + ML_GROUND + ML_FLOOR * k - 0.1
		if k == ML_FLOORS:
			continue
		_hang(_rect(34.0, ML_WID * 0.5, 1.5, 8.05), y - 0.6, y, ML_YELLOW, ML_CONCRETE, ML_SOFFIT)
		_hang(_rect(2.75, ML_WID * 0.5, 2.75, 7.5), y - 0.6, y, ML_YELLOW, ML_CONCRETE, ML_SOFFIT)
		_mode = M_STONE
		_wall(_w(ML_LEN, 0.5), _w(ML_LEN, ML_WID - 0.5), y + 0.1, y + 1.0, Vector2(_a), ML_RAIL, 0.0)
		_wall(_w(0.0, 1.0), _w(0.0, 16.0), y + 0.1, y + 1.0, -_a, ML_RAIL, 0.0)
		_wall(_w(0.0, 16.0), _w(5.5, 16.0), y + 0.1, y + 1.0, _b, ML_RAIL, 0.0)
		_wall(_w(0.0, 1.0), _w(5.5, 1.0), y + 0.1, y + 1.0, -_b, ML_RAIL, 0.0)
		_framed(_w(33.0, 1.0), _w(33.0, ML_WID - 1.0), y + 0.2, y + 2.3, _a, ML_FRAME, ML_GLASS, 0.0)
		if y + 2.3 < g + ML_NOTCH:
			_framed(_w(2.8, 2.6), _w(2.8, 14.5), y + 0.2, y + 2.3, -_a, ML_FRAME, ML_GLASS, 0.0)
	_build_mlotek_head(g, none)
	_build_mlotek_foot(g)
	_collide_raw(site)


## crown_slab, crown_glaze, roof_plant: the hammer's head on its dark neck, the underside sloping
## up from a storey below the ledge to the head's east end, the end face leaning out.
func _build_mlotek_head(g: float, none: Color) -> void:
	var v0 := -0.6
	var v1 := ML_WID + 0.6
	var u0 := -0.3
	var ue := ML_JAW - 0.9
	var tip := ML_JAW - 0.6
	# The neck: a dark recess between the slab and the head, a deep notch over the west balconies.
	_lbox(19.25, ML_WID * 0.5, 13.75, ML_WID * 0.5 - 0.9, g + ML_NECK, g + ML_LEDGE, ML_SOFFIT, M_STONE, ML_SOFFIT)
	_lbox(2.75, ML_WID * 0.5, 2.75, 6.0, g + ML_NOTCH, g + ML_LEDGE, ML_SOFFIT, M_STONE, ML_SOFFIT)
	# The ledge over the slab, and the jaw east of it.
	_hang(PackedVector2Array([_w(u0, v0), _w(35.5, v0), _w(35.5, v1), _w(u0, v1)]), g + ML_LEDGE, g + ML_BAND, ML_HEAD, ML_SOFFIT, ML_SOFFIT)
	_mode = M_STONE
	var yr := g + ML_JAW_ROOT
	var yt := g + ML_LEDGE
	var yb := g + ML_BAND
	for c: Array in [[v1, _b], [v0, -_b]]:
		var v: float = c[0]
		var n := Vector3(c[1].x, 0.0, c[1].y)
		var p0 := _w(35.5, v)
		var p1 := _w(tip, v)
		_quad(Vector3(p0.x, yr, p0.y), Vector3(p1.x, yt, p1.y), Vector3(p1.x, yb, p1.y), Vector3(p0.x, yb, p0.y), n, ML_HEAD)
	var j0 := _w(35.5, v0)
	var j1 := _w(35.5, v1)
	var t0 := _w(tip, v0)
	var t1 := _w(tip, v1)
	_quad(Vector3(j0.x, yr, j0.y), Vector3(j1.x, yr, j1.y), Vector3(t1.x, yt, t1.y), Vector3(t0.x, yt, t0.y),
			(Vector3(_a.x, 0.0, _a.y) * (yt - yr) + Vector3.DOWN * (tip - 35.5)).normalized(), ML_SOFFIT)
	_wall(t0, t1, yt, yb, _a, ML_HEAD, 0.0)
	_wall(_w(35.5, v1), _w(35.5, v0), yr, g + ML_LEDGE, -_a, ML_SOFFIT, 0.0)
	var over := PackedVector2Array([_w(35.5, v0), _w(tip, v0), _w(tip, v1), _w(35.5, v1)])
	_cap(over, yb, ML_SOFFIT)
	# The glazed band, 30 cm in: glass from the middle of the long faces round the east end, the
	# slit vents on the west half.
	var i0 := v0 + 0.3
	var i1 := v1 - 0.3
	_lbox((u0 + 0.3 + ue) * 0.5, (i0 + i1) * 0.5, (ue - u0 - 0.3) * 0.5, (i1 - i0) * 0.5, g + ML_BAND, g + ML_BAND_TOP, ML_SOFFIT, M_STONE, ML_SOFFIT)
	_framed(_w(19.0, i1), _w(ue, i1), g + ML_BAND + 0.1, g + ML_BAND_TOP - 0.1, _b, ML_FRAME, ML_GLASS, 0.0)
	_framed(_w(19.0, i0), _w(ue, i0), g + ML_BAND + 0.1, g + ML_BAND_TOP - 0.1, -_b, ML_FRAME, ML_GLASS, 0.0)
	_framed(_w(ue, i0), _w(ue, i1), g + ML_BAND + 0.1, g + ML_BAND_TOP - 0.1, _a, ML_FRAME, Color("#a9b4b8"), 0.0)
	for y: float in [ML_BAND + 0.5, ML_BAND + 1.3]:
		_mode = M_STONE
		_wall(_w(1.0, i1 + 0.06), _w(18.5, i1 + 0.06), g + y, g + y + 0.35, _b, ML_HEAD.darkened(0.25), 0.0)
	# The head: flat on top, its east end leaning out 1.5 m.
	var ub := ML_JAW - 1.0
	var ut := ML_JAW + 0.5
	var y0 := g + ML_BAND_TOP
	var y1 := g + ML_TOP
	_soffit(PackedVector2Array([_w(u0, v0), _w(ub, v0), _w(ub, v1), _w(u0, v1)]), y0, ML_SOFFIT)
	_mode = M_STONE
	_wall(_w(u0, v1), _w(u0, v0), y0, y1, -_a, ML_HEAD, 0.0)
	for c: Array in [[v1, _b], [v0, -_b]]:
		var v: float = c[0]
		var p0 := _w(u0, v)
		var p1 := _w(ub, v)
		var p2 := _w(ut, v)
		_quad(Vector3(p0.x, y0, p0.y), Vector3(p1.x, y0, p1.y), Vector3(p2.x, y1, p2.y), Vector3(p0.x, y1, p0.y), Vector3(c[1].x, 0.0, c[1].y), ML_HEAD)
	var e0 := _w(ub, v0)
	var e1 := _w(ub, v1)
	var e2 := _w(ut, v1)
	var e3 := _w(ut, v0)
	_quad(Vector3(e0.x, y0, e0.y), Vector3(e1.x, y0, e1.y), Vector3(e2.x, y1, e2.y), Vector3(e3.x, y1, e3.y),
			(Vector3(_a.x, 0.0, _a.y) * (y1 - y0) + Vector3.DOWN * (ut - ub)).normalized(), ML_HEAD.darkened(0.08))
	var top := PackedVector2Array([_w(u0, v0), _w(ut, v0), _w(ut, v1), _w(u0, v1)])
	# The roof: the pale rim, the raised middle, the plant.
	_rimmed(top, y1, ML_RIM, ML_ROOF)
	var deck := y1 + 0.05
	var mid := _rect(21.0, ML_WID * 0.5, 14.0, 5.6)
	_prism(mid, deck, deck + 0.35, ML_ROOF, none, M_STONE)
	_rimmed(mid, deck + 0.35, ML_RIM, ML_ROOF.lightened(0.08))
	for p: Vector3 in [Vector3(9.0, 6.0, 2.2), Vector3(17.0, 11.0, 1.6), Vector3(26.0, 6.5, 2.0), Vector3(33.0, 10.5, 1.6), Vector3(39.0, 8.5, 1.4)]:
		_lbox(p.x, p.y, 1.3, 1.3, deck - 0.05, deck + p.z, ML_BASE, M_STONE, ML_BASE)
	for p: Vector2 in [Vector2(40.5, 3.0), Vector2(0.8, 14.5)]:
		_lbox(p.x, p.y, 0.1, 0.1, deck - 0.05, deck + 3.0, ML_DARK, M_STONE, ML_DARK)


## canopy: the concrete pergola on pilotis at the east foot, slats between its beams.
func _build_mlotek_foot(g: float) -> void:
	var u0 := 36.0
	var u1 := 50.0
	var v0 := 1.5
	var v1 := 15.5
	var y0 := g + 3.1
	var y1 := g + 4.3
	_hang(_rect((u0 + u1) * 0.5, v1, (u1 - u0) * 0.5, 0.3), y0, y1, ML_CONCRETE, ML_CONCRETE.lightened(0.05), ML_SOFFIT)
	_hang(_rect((u0 + u1) * 0.5, v0, (u1 - u0) * 0.5, 0.3), y0, y1, ML_CONCRETE, ML_CONCRETE.lightened(0.05), ML_SOFFIT)
	_hang(_rect(u1, (v0 + v1) * 0.5, 0.3, (v1 - v0) * 0.5 - 0.3), y0, y1, ML_CONCRETE, ML_CONCRETE.lightened(0.05), ML_SOFFIT)
	for k in 9:
		_hang(_rect(u0 + 1.2 + k * 1.45, (v0 + v1) * 0.5, 0.09, (v1 - v0) * 0.5 - 0.3), y0 + 0.3, y1 - 0.15, ML_DARK, ML_DARK, ML_DARK)
	for p: Vector2 in [Vector2(u0 + 1.0, v0), Vector2(u0 + 1.0, v1), Vector2(u1 - 0.3, v0), Vector2(u1 - 0.3, v1), Vector2(43.0, v0), Vector2(43.0, v1)]:
		_lbox(p.x, p.y, 0.25, 0.25, g - 0.6, y0, ML_CONCRETE, M_STONE, ML_CONCRETE)


## Kozia 9 (1974-76, Jerzy Kuźmienko and Piotr Sembrat), from the Mac photo gather
## (docs/landmarks/photo-reports/kozia9.md). A slab of cream-grey roughcast that climbs a storey
## at a time from five floors at its north-west end to nine at its south-east end, ending in a
## round stair tower. Both long sides are saw-toothed in plan (the mapped outline's teeth): flat
## plates of plain wall, with every window turned sideways into the jogs between them. Frame: u
## along the slab from the low end, +v out of the south-west (car park) side. Spec kozia9.md.
const KZ_AT := Vector2(-805.0, -1174.0)
const KZ_O := Vector2(-832.7, -1189.3)
const KZ_A := Vector2(0.69, 0.724)
const KZ_FLOOR := 3.1
const KZ_CUTS := [-12.0, 16.0, 29.0, 42.0, 53.5, 80.0]    # the five sections, in u
const KZ_TOPS := [14.4, 17.5, 20.6, 23.7, 26.8]           # their roofs over the ground (LoD2)
const KZ_JOG := Vector2(0.93, -0.37)                      # the direction of a jog between two plates
const KZ_WALL := Color("#b8b1a0")
const KZ_SHADE := Color("#8f897a")
const KZ_FRAME := Color("#eeeeea")
const KZ_GLASS := Color("#2e3640")
const KZ_ROOF := Color("#70716f")
const KZ_RIM := Color("#e0ded6")
const KZ_DOOR := Color("#8c5a32")
const KZ_GREY := Color("#8e8e8c")


func _find_kozia9() -> void:
	var q := _tallest_at(KZ_AT)
	if q.size() < 40:
		return
	_add_site("kozia9", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "kozia9":
		sites[-1]["ring"] = _simplify(q, 0.15)
		sites[-1]["raw"] = q


func _build_kozia9(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_o = KZ_O
	_a = KZ_A
	_b = Vector2(-KZ_A.y, KZ_A.x)
	_mode = M_STONE
	for s in KZ_TOPS.size():
		var u0: float = KZ_CUTS[s]
		var u1: float = KZ_CUTS[s + 1]
		# Each section runs 5 cm into the next, taller one: their cut faces would meet back to back.
		var cut := Geometry2D.intersect_polygons(ring, _rect((u0 + u1) * 0.5 + 0.025, -10.0, (u1 - u0) * 0.5 + 0.025, 30.0))
		if cut.is_empty():
			continue
		var poly := _largest(cut)
		var top := float(KZ_TOPS[s])
		_kozia9_jogs(poly, top, g)
		_prism(poly, g - 0.8, g + top + 0.45, KZ_WALL, Color(0, 0, 0, 0), M_STONE, M_STONE)
		_rimmed(poly, g + top + 0.45, KZ_RIM, KZ_ROOF)
	# stair_tower: the round end, a storey over the tallest roof.
	var tower := _circle(_w(61.5, -4.5), 5.0, 14)
	_prism(tower, g - 0.8, g + 27.3, KZ_WALL.darkened(0.05), KZ_ROOF, M_STONE, M_STONE)
	# roof_plant: the lift head on the middle section, the dishes.
	for p: Vector3 in [Vector3(10.0, -6.5, 14.85), Vector3(33.0, -6.5, 20.65), Vector3(44.0, -6.5, 23.75), Vector3(51.5, -7.0, 23.75)]:
		_lbox(p.x, p.y, 2.2, 2.2, g + p.z, g + p.z + 2.2, KZ_WALL, M_STONE, KZ_ROOF)
	for p: Vector3 in [Vector3(24.0, -3.0, 17.5), Vector3(50.0, -3.0, 23.7)]:
		var c := _w(p.x, p.y)
		_mode = M_STONE
		_disc(Vector3(c.x, g + p.z + 1.3, c.y), Vector3(_b.x, 0.7, _b.y).normalized(), 0.7, 10, KZ_FRAME)
		_lbox(p.x, p.y, 0.06, 0.06, g + p.z, g + p.z + 1.3, KZ_SHADE, M_STONE, KZ_SHADE)
	# entrance: the two flat canopies, doors and steps on the car park side.
	for u: float in [27.0, 53.0]:
		_hang(_rect(u, 1.6, 2.4, 1.0), g + 2.7, g + 3.0, KZ_FRAME, Color("#d8d6cf"), KZ_SHADE)
		_lbox(u, 0.9, 1.2, 1.1, g - 0.5, g + 2.5, KZ_DOOR, M_STONE, KZ_SHADE)
		_lbox(u, 3.3, 1.8, 1.1, g - 0.5, g + 0.3, KZ_GREY, M_STONE, KZ_GREY)
	# garage_ramp: the retaining walls and the dark mouth by the tower.
	for v: float in [55.6, 61.2]:
		_lbox(v, 7.5, 0.2, 5.5, g - 0.5, g + 1.2, KZ_GREY, M_STONE, KZ_GREY.lightened(0.1))
	_lbox(58.4, 2.6, 2.6, 0.5, g - 0.5, g + 2.7, Color("#232527"), M_STONE, KZ_GREY)
	_hang(_rect(58.4, 3.6, 3.0, 1.5), g + 2.7, g + 3.0, KZ_GREY, KZ_GREY.lightened(0.1), KZ_SHADE)
	_collide_raw(site)


## window_strips, balcony_boxes: a window on every jog of the saw-tooth, a storey at a time, with
## the white sill that catches the light; on the deep jogs of the north-east side the staggered
## balcony boxes.
func _kozia9_jogs(poly: PackedVector2Array, top: float, g: float) -> void:
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var length := a.distance_to(b)
		var e := (b - a) / length
		if length < 0.7 or length > 4.0 or absf(e.dot(KZ_JOG)) < 0.9:
			continue
		var out := _out(poly, a, b)
		var m := (a + b) * 0.5
		# A jog over 2.6 m holds two bays.
		var spots: Array[Vector2] = [m]
		var w := minf(length - 0.25, 1.2) * 0.5
		if length > 2.6:
			spots = [m - e * length * 0.25, m + e * length * 0.25]
			w = 0.55
		var rows := floori((top - 2.0) / KZ_FLOOR)
		for k in rows:
			var y := g + 1.1 + KZ_FLOOR * k
			for c: Vector2 in spots:
				# Each jog its own stretch of the shader's room grid, or the block goes dark at night.
				_framed(c - e * w, c + e * w, y, y + 1.4, out, KZ_FRAME, KZ_GLASS, (float(i) + 0.5 * spots.find(c)) * 4.5 + float(k) * 13.5)
				_mode = M_STONE
				_hang(PackedVector2Array([c - e * (w + 0.1), c + e * (w + 0.1), c + e * (w + 0.1) + out * 0.5, c - e * (w + 0.1) + out * 0.5]),
						y - 0.14, y, KZ_FRAME, KZ_FRAME, KZ_SHADE)
				_hang(PackedVector2Array([c - e * (w + 0.1), c + e * (w + 0.1), c + e * (w + 0.1) + out * 0.35, c - e * (w + 0.1) + out * 0.35]),
						y + 1.4, y + 1.55, KZ_SHADE, KZ_SHADE, KZ_SHADE.darkened(0.2))
			if out.dot(_b) >= 0.0 or (k + i) % 2 == 0:
				continue
			var hw := 1.2 if length > 2.2 else 0.75
			var depth := 2.1 if length > 2.2 else 1.3
			var p := m + out * 0.05
			_hang(PackedVector2Array([p - e * hw, p + e * hw, p + e * hw + out * depth, p - e * hw + out * depth]),
					y - 1.45, y - 0.15, KZ_WALL, KZ_RIM, KZ_SHADE.darkened(0.3))


## Smolna 38 (a pre-war tenement, the Smoła club's house), from F's own photos of 2026-11-08
## (refs/smolna38/: the street front by day, the gate, the club door at night). Four storeys: a
## grey rusticated ground floor with a deep gate, three cream-plaster floors with grey stone
## window surrounds, and over the gate a big fluted stone cartouche carrying a two-storey oriel
## and a third-floor balcony. The street front is detailed, the other faces plain. On the
## pavement the club's dressing: a plank awning, two black pop-up tents, steel crowd barriers and
## a "GUEST LIST" banner. Frame: origin at the front's west end on the outline, u along it to the
## east (25.08 m), +v out to Smolna. Spec smolna38.md.
const S38_AT := Vector2(-157.0, 135.0)
const S38_O := Vector2(-164.4, 158.1)
const S38_A := Vector2(0.94504, -0.32697)
const S38_LEN := 25.08
const S38_GATE_U := 15.0
const S38_GATE_HW := 1.6
const S38_GATE_H := 3.9
const S38_GROUND := 4.2        # the ground floor's top over the ground
const S38_FLOOR := 3.1
const S38_TOP := 14.2
const S38_AXES := [1.8, 5.1, 8.4, 11.7, 18.3, 21.6]   # the window axes either side of the bay
const S38_CREAM := Color("#d6c6a6")
const S38_STONE := Color("#a8a49c")
const S38_STONE_L := Color("#b9b5ad")
const S38_PLINTH := Color("#7d7a74")
const S38_GROOVE := Color("#8a867f")
const S38_FRAME := Color("#ece9e2")
const S38_GLASS := Color("#2e3640")
const S38_ROOF := Color("#7a7874")
const S38_WOOD := Color("#35271c")
const S38_PLANK := Color("#8b6b46")
const S38_RED := Color("#d42a1c")
const S38_PIPE := Color("#7b3f2f")
const S38_IRON := Color("#2a2c2e")
const S38_BLUE := Color("#1c4fa0")
const S38_TENT := Color("#17171a")
const S38_STEEL := Color("#9fa2a6")
const S38_FONT := {
	"G": ["###", "#..", "#.#", "#.#", "###"], "U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"E": ["###", "#..", "##.", "#..", "###"], "S": ["###", "#..", "###", "..#", "###"],
	"T": ["###", ".#.", ".#.", ".#.", ".#."], "L": ["#..", "#..", "#..", "#..", "###"],
	"I": ["###", ".#.", ".#.", ".#.", "###"], "3": ["###", "..#", "###", "..#", "###"],
	"8": ["###", "#.#", "###", "#.#", "###"],
	# THE TAPCZAN's umbrellas (KOLKA-KOLA).
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"], "O": ["###", "#.#", "#.#", "#.#", "###"],
	"A": ["###", "#.#", "###", "#.#", "#.#"], "-": ["...", "...", "###", "...", "..."],
}
var _sm_run := 0.0


func _find_smolna38() -> void:
	var q := _tallest_at(S38_AT)
	if q.size() < 10:
		return
	_add_site("smolna38", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "smolna38":
		# 0.35 m: the street front's two 0.2 m jogs (the OSM outline's) would bury the windows.
		sites[-1]["ring"] = _simplify(q, 0.35)
		sites[-1]["raw"] = q


func _build_smolna38(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_o = S38_O
	_a = S38_A.normalized()
	_b = Vector2(-_a.y, _a.x)
	_mode = M_STONE
	_sm_run = 0.0
	var none := Color(0, 0, 0, 0)
	# body: the ground floor with the gate notched out of it, the lintel course over the gate,
	# three plaster floors, the stepped cornice.
	var gated := _largest(Geometry2D.clip_polygons(ring, _rect(S38_GATE_U, -1.5, S38_GATE_HW, 2.5)))
	_prism(gated, g - 0.8, g + S38_GATE_H, S38_STONE, none, M_STONE, M_STONE)
	_prism(ring, g + S38_GATE_H, g + S38_GROUND, S38_STONE, none, M_STONE, M_STONE)
	_prism(ring, g + S38_GROUND, g + 13.55, S38_CREAM, none, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(ring, 0.15, Geometry2D.JOIN_MITER)), g + 13.35, g + 13.55, S38_STONE_L, none, M_STONE, M_STONE)
	_prism(_largest(Geometry2D.offset_polygon(ring, 0.4, Geometry2D.JOIN_MITER)), g + 13.55, g + S38_TOP, S38_STONE_L, S38_ROOF, M_STONE, M_STONE)
	for p: Vector2 in [Vector2(4.0, -6.0), Vector2(20.0, -6.0)]:
		_lbox(p.x, p.y, 0.5, 0.5, g + S38_TOP, g + S38_TOP + 1.8, Color("#8a5a48"), M_STONE, S38_ROOF)
	_sm_ground(g)
	_sm_upper(g)
	_sm_gate(g)
	_sm_cartouche(g)
	_sm_oriel(g)
	_sm_street(g)
	_collide_raw(site)


## rustication, plinth, ground windows: grooves every 0.45 m, the dark plinth with its basement
## windows, the flat splayed lintels, the cornice band, the number plate, the drainpipe.
func _sm_ground(g: float) -> void:
	_mode = M_STONE
	# plinth in two pieces, the gate between them
	var l0 := S38_GATE_U - S38_GATE_HW
	var r0 := S38_GATE_U + S38_GATE_HW
	_lbox(l0 * 0.5, 0.06, l0 * 0.5, 0.06, g - 0.5, g + 0.9, S38_PLINTH, M_STONE, S38_STONE_L)
	_lbox((r0 + S38_LEN) * 0.5, 0.06, (S38_LEN - r0) * 0.5, 0.06, g - 0.5, g + 0.9, S38_PLINTH, M_STONE, S38_STONE_L)
	# grooves: the stones' bed joints, broken round the windows and the gate
	for k in range(1, 8):
		var y := g + 0.9 + 0.45 * k
		var spans: Array[Vector2] = [Vector2(0.1, S38_LEN - 0.1)]
		var gaps: Array[Vector2] = []
		if y < g + S38_GATE_H + 0.05:
			gaps.append(Vector2(l0 - 0.05, r0 + 0.05))
		if y > g + 1.2 and y < g + 3.8:
			for u: float in S38_AXES:
				gaps.append(Vector2(u - 0.98, u + 0.98))
		for gp in gaps:
			var next: Array[Vector2] = []
			for s in spans:
				if gp.y <= s.x or gp.x >= s.y:
					next.append(s)
					continue
				if gp.x > s.x + 0.05:
					next.append(Vector2(s.x, gp.x))
				if gp.y < s.y - 0.05:
					next.append(Vector2(gp.y, s.y))
			spans = next
		for s in spans:
			_wall(_w(s.x, 0.04), _w(s.y, 0.04), y, y + 0.05, _b, S38_GROOVE, s.x)
	for u: float in S38_AXES:
		_sm_win(u, g + 1.35, g + 3.15, 0.0, 0.6)
		_sm_sill(u, g + 1.35, 0.0, 0.6)
		_sm_lintel(u, g + 3.2)
		_sm_win(u, g + 0.18, g + 0.66, 0.12, 0.35)
	# the cornice band over the ground floor
	_lbox(S38_LEN * 0.5, 0.17, S38_LEN * 0.5, 0.17, g + S38_GROUND, g + 4.55, S38_STONE_L, M_STONE, S38_STONE_L.lightened(0.08))
	# the blue number plate right of the gate
	_wall(_w(17.15, 0.08), _w(17.6, 0.08), g + 2.35, g + 2.65, _b, S38_BLUE, 17.15)
	_sm_text("38", 17.24, 0.12, g + 2.6, 0.04, 0.04, 0.17, S38_FRAME)
	# the red-brown drainpipe
	_lbox(24.2, 0.1, 0.07, 0.07, g - 0.3, g + 13.7, S38_PIPE, M_STONE, S38_PIPE)


## The three plaster floors: a window per axis with its grey surround and sill, the pediments
## on the first floor either side of the bay.
func _sm_upper(g: float) -> void:
	for f in 3:
		var fb := g + S38_GROUND + S38_FLOOR * f
		for u: float in S38_AXES:
			_sm_win(u, fb + 0.85, fb + 2.6, 0.0, 0.62)
			_sm_surround(u, fb + 0.85, fb + 2.6, 0.0, 0.62)
			_sm_sill(u, fb + 0.85, 0.0, 0.62)
			if f == 0 and (u == 11.7 or u == 18.3):
				_sm_pediment(u, fb + 2.85, 0.0)
	# the bay's door onto the balcony, third floor
	var y3 := g + S38_GROUND + S38_FLOOR * 2.0
	_sm_win(S38_GATE_U, y3 + 0.25, y3 + 2.5, 0.0, 0.5)
	_sm_surround(S38_GATE_U, y3 + 0.25, y3 + 2.5, 0.0, 0.5)


## The gate: the passage glows red (M_LAMP, lit after dark), the two dark leaves folded back on its sides.
func _sm_gate(g: float) -> void:
	var l0 := S38_GATE_U - S38_GATE_HW
	var r0 := S38_GATE_U + S38_GATE_HW
	_mode = M_LAMP
	_wall(_w(l0, -3.96), _w(r0, -3.96), g, g + S38_GATE_H, _b, S38_RED, 0.0)
	_wall(_w(l0 + 0.04, -3.96), _w(l0 + 0.04, 0.0), g, g + S38_GATE_H, _a, S38_RED.darkened(0.15), 0.0)
	_wall(_w(r0 - 0.04, -3.96), _w(r0 - 0.04, 0.0), g, g + S38_GATE_H, -_a, S38_RED.darkened(0.15), 0.0)
	_cap(_rect(S38_GATE_U, -2.0, S38_GATE_HW - 0.04, 2.0), g + 0.03, S38_RED.darkened(0.5))
	_mode = M_STONE
	for s: float in [-1.0, 1.0]:
		_lbox(S38_GATE_U + s * (S38_GATE_HW - 0.2), -0.9, 0.05, 0.8, g, g + 3.2, S38_WOOD, M_STONE, S38_WOOD.lightened(0.1))
	# plank awning under the cartouche, hung off the wall over the gate
	for k in 6:
		_lbox(S38_GATE_U, 0.4 + 0.3 * k, 1.9, 0.13, g + 3.0, g + 3.1, S38_PLANK.darkened(0.08 * float(k % 2)), M_STONE, S38_PLANK)


## The curved stone console: five stacked bowls, wide at the top, narrowing to the tip, fluted
## and garlanded, carrying the oriel.
func _sm_cartouche(g: float) -> void:
	_mode = M_STONE
	var hws := [1.75, 1.6, 1.35, 1.0, 0.6]
	var ps := [1.15, 1.05, 0.9, 0.7, 0.45]
	for i in 5:
		var hw: float = hws[i]
		var p: float = ps[i]
		var poly := PackedVector2Array()
		for c: Vector2 in [Vector2(-hw, 0.05), Vector2(hw, 0.05), Vector2(hw, 0.4 * p), Vector2(0.82 * hw, 0.8 * p),
				Vector2(0.5 * hw, p), Vector2(-0.5 * hw, p), Vector2(-0.82 * hw, 0.8 * p), Vector2(-hw, 0.4 * p)]:
			poly.append(_w(S38_GATE_U + c.x, c.y))
		var y1 := g + 4.55 - 0.2 * i
		_prism(poly, y1 - 0.2, y1, S38_STONE_L if i % 2 == 0 else S38_STONE, S38_STONE_L if i == 0 else Color(0, 0, 0, 0), M_STONE, M_STONE)
		if i == 4:
			_soffit(poly, y1 - 0.2, S38_STONE.darkened(0.2))
		if i < 3:
			var u := -0.45 * hw
			while u <= 0.451 * hw:
				_wall(_w(S38_GATE_U + u - 0.03, p + 0.04), _w(S38_GATE_U + u + 0.03, p + 0.04), y1 - 0.18, y1 - 0.02, _b, S38_GROOVE.darkened(0.1), u)
				u += 0.28
	# garlands: two lighter swags at the bowl's shoulders
	for s: float in [-1.0, 1.0]:
		_lbox(S38_GATE_U + s * 1.3, 0.75, 0.22, 0.18, g + 3.75, g + 4.25, S38_STONE_L.lightened(0.1), M_STONE, S38_STONE_L.lightened(0.15))


## The oriel on floors 1 and 2 and the third-floor balcony with its thin iron railing.
func _sm_oriel(g: float) -> void:
	_mode = M_STONE
	var y0 := g + 4.55
	var y1 := g + S38_GROUND + S38_FLOOR * 2.0
	_lbox(S38_GATE_U, 0.35, 1.7, 0.35, y0, y1, S38_STONE, M_STONE, S38_STONE)
	# rusticated piers either side of the windows
	for k in 13:
		var y := y0 + 0.2 + 0.45 * k
		if y + 0.05 >= y1:
			break
		_wall(_w(S38_GATE_U - 1.7, 0.74), _w(S38_GATE_U - 0.86, 0.74), y, y + 0.05, _b, S38_GROOVE, 0.0)
		_wall(_w(S38_GATE_U + 0.86, 0.74), _w(S38_GATE_U + 1.7, 0.74), y, y + 0.05, _b, S38_GROOVE, 0.0)
	for f in 2:
		var fb := g + S38_GROUND + S38_FLOOR * f
		_sm_win(S38_GATE_U, fb + 0.85, fb + 2.6, 0.7, 0.62)
		_sm_surround(S38_GATE_U, fb + 0.85, fb + 2.6, 0.7, 0.62)
		_sm_sill(S38_GATE_U, fb + 0.85, 0.7, 0.62)
	# balcony slab and railing
	_hang(_rect(S38_GATE_U, 0.6, 1.9, 0.6), y1, y1 + 0.2, S38_STONE_L, S38_STONE_L.lightened(0.1), S38_STONE.darkened(0.2))
	var ry := y1 + 0.2
	for k in 9:
		_lbox(S38_GATE_U - 1.8 + 0.45 * k, 1.12, 0.018, 0.018, ry, ry + 0.95, S38_IRON, M_STONE, S38_IRON)
	for s: float in [-1.0, 1.0]:
		for v: float in [0.35, 0.75]:
			_lbox(S38_GATE_U + s * 1.8, v, 0.018, 0.018, ry, ry + 0.95, S38_IRON, M_STONE, S38_IRON)
		_lbox(S38_GATE_U + s * 1.8, 0.62, 0.02, 0.52, ry + 0.93, ry + 1.0, S38_IRON, M_STONE, S38_IRON)
	_lbox(S38_GATE_U, 1.12, 1.82, 0.02, ry + 0.93, ry + 1.0, S38_IRON, M_STONE, S38_IRON)


## The club's dressing on the pavement: two black pop-up tents east of the gate, steel crowd
## barriers along their kerb side and one left of the gate carrying the "GUEST LIST" banner.
func _sm_street(g: float) -> void:
	_mode = M_STONE
	_sm_tent(19.6, 2.0, g, true, false)
	_sm_tent(22.7, 2.0, g, false, true)
	for u: float in [18.0, 20.1, 22.2]:
		_sm_barrier(u, u + 2.1, 3.85, g)
	_sm_barrier(10.1, 12.3, 1.1, g)
	_mode = M_STONE
	_wall(_w(10.15, 1.14), _w(12.25, 1.14), g + 0.25, g + 0.95, _b, S38_TENT, 10.15)
	_sm_text("GUEST LIST", 10.3, 1.19, g + 0.85, 0.05, 0.09, 0.19, Color("#f2f2ee"))


## A 3 x 3 m pop-up tent: four thin legs, a low black canopy with a valance, black curtains on
## the street side and on one end.
func _sm_tent(u: float, v: float, g: float, west_curtain: bool, east_curtain: bool) -> void:
	_mode = M_STONE
	for du: float in [-1.5, 1.5]:
		for dv: float in [-1.5, 1.5]:
			_lbox(u + du, v + dv, 0.035, 0.035, g - 0.05, g + 2.4, S38_STEEL, M_STONE, S38_STEEL)
	_prism(_rect(u, v, 1.6, 1.6), g + 2.15, g + 2.4, S38_TENT, Color(0, 0, 0, 0), M_STONE, M_STONE)
	_pyramid(_rect(u, v, 1.6, 1.6), g + 2.4, g + 2.9, S38_TENT.lightened(0.04))
	for s: float in [1.0, -1.0]:
		_wall(_w(u - 1.5, v + 1.56), _w(u + 1.5, v + 1.56), g + 0.15, g + 2.2, _b * s, S38_TENT, u)
	if west_curtain:
		for s: float in [1.0, -1.0]:
			_wall(_w(u - 1.56, v - 1.5), _w(u - 1.56, v + 1.5), g + 0.15, g + 2.2, _a * s, S38_TENT, u)
	if east_curtain:
		for s: float in [1.0, -1.0]:
			_wall(_w(u + 1.56, v - 1.5), _w(u + 1.56, v + 1.5), g + 0.15, g + 2.2, _a * s, S38_TENT, u)


## A steel crowd barrier: two posts, two rails and seven bars.
func _sm_barrier(u0: float, u1: float, v: float, g: float) -> void:
	_mode = M_STONE
	var m := (u0 + u1) * 0.5
	var hu := (u1 - u0) * 0.5
	for u: float in [u0 + 0.03, u1 - 0.03]:
		_lbox(u, v, 0.025, 0.025, g, g + 1.05, S38_STEEL, M_STONE, S38_STEEL)
	_lbox(m, v, hu, 0.018, g + 0.93, g + 1.02, S38_STEEL, M_STONE, S38_STEEL)
	_lbox(m, v, hu, 0.018, g + 0.15, g + 0.22, S38_STEEL, M_STONE, S38_STEEL)
	for k in 7:
		var u := u0 + 0.2 + float(k) * (u1 - u0 - 0.4) / 6.0
		for s: float in [1.0, -1.0]:
			_wall(_w(u - 0.012, v), _w(u + 0.012, v), g + 0.22, g + 0.93, _b * s, S38_STEEL.darkened(0.15), 0.0)


## Pixel lettering on the facade plane: `text` from u0, its top at ytop, one `px` x `py` quad per run of a 3 x 5 glyph.
func _sm_text(text: String, u0: float, v: float, ytop: float, px: float, py: float, pitch: float, col: Color) -> void:
	_mode = M_STONE
	for ci in text.length():
		var ch := text.substr(ci, 1)
		if ch == " " or not S38_FONT.has(ch):
			continue
		var rows: Array = S38_FONT[ch]
		for r in 5:
			var row: String = rows[r]
			var c := 0
			while c < 3:
				if row[c] != "#":
					c += 1
					continue
				var c1 := c
				while c1 + 1 < 3 and row[c1 + 1] == "#":
					c1 += 1
				var ua := u0 + float(ci) * pitch + float(c) * px
				var ub := u0 + float(ci) * pitch + float(c1 + 1) * px
				_wall(_w(ua, v), _w(ub, v), ytop - float(r + 1) * py, ytop - float(r) * py, _b, col, ua)
				c = c1 + 1


## A window on the plane at v: white frame and glass, a mullion cross; each its own stretch of the shader's room grid.
func _sm_win(u: float, y0: float, y1: float, v: float, hw: float) -> void:
	_sm_run += 7.3
	_framed(_w(u - hw, v), _w(u + hw, v), y0, y1, _b, S38_FRAME, S38_GLASS, _sm_run)
	_mode = M_STONE
	_wall(_w(u - 0.025, v + 0.13), _w(u + 0.025, v + 0.13), y0 + 0.1, y1 - 0.1, _b, S38_FRAME, _sm_run)
	var ym := y0 + (y1 - y0) * 0.65
	_wall(_w(u - hw + 0.1, v + 0.13), _w(u + hw - 0.1, v + 0.13), ym, ym + 0.05, _b, S38_FRAME, _sm_run)


## Grey stone jambs and a head round a window.
func _sm_surround(u: float, y0: float, y1: float, v: float, hw: float) -> void:
	_mode = M_STONE
	_wall(_w(u - hw - 0.22, v + 0.04), _w(u - hw, v + 0.04), y0, y1 + 0.25, _b, S38_STONE, u)
	_wall(_w(u + hw, v + 0.04), _w(u + hw + 0.22, v + 0.04), y0, y1 + 0.25, _b, S38_STONE, u)
	_wall(_w(u - hw - 0.22, v + 0.04), _w(u + hw + 0.22, v + 0.04), y1, y1 + 0.25, _b, S38_STONE, u)


func _sm_sill(u: float, y: float, v: float, hw: float) -> void:
	_lbox(u, v + 0.09, hw + 0.2, 0.09, y - 0.14, y, S38_STONE_L, M_STONE, S38_STONE_L.lightened(0.1))


## A flat lintel with splayed voussoirs over a ground-floor window.
func _sm_lintel(u: float, y: float) -> void:
	_mode = M_STONE
	var n := Vector3(_b.x, 0.0, _b.y)
	var pt := func(du: float, yy: float, v: float) -> Vector3:
		var p := _w(u + du, v)
		return Vector3(p.x, yy, p.y)
	_quad(pt.call(-0.7, y, 0.08), pt.call(0.7, y, 0.08), pt.call(0.98, y + 0.5, 0.08), pt.call(-0.98, y + 0.5, 0.08), n, S38_STONE_L)
	for k in 4:
		var xb: float = -0.42 + 0.28 * k
		var xt: float = -0.64 + 0.427 * k
		_quad(pt.call(xb - 0.015, y, 0.12), pt.call(xb + 0.015, y, 0.12), pt.call(xt + 0.015, y + 0.5, 0.12), pt.call(xt - 0.015, y + 0.5, 0.12), n, S38_GROOVE)


## A triangular pediment on its cornice over a window head.
func _sm_pediment(u: float, y: float, v: float) -> void:
	_lbox(u, v + 0.09, 1.15, 0.09, y, y + 0.12, S38_STONE_L, M_STONE, S38_STONE_L.lightened(0.1))
	_mode = M_STONE
	var pa := _w(u - 1.1, v + 0.1)
	var pb := _w(u + 1.1, v + 0.1)
	var pc := _w(u, v + 0.1)
	var uvn := Vector2(-1, -1)
	_tri(Vector3(pa.x, y + 0.12, pa.y), Vector3(pb.x, y + 0.12, pb.y), Vector3(pc.x, y + 0.65, pc.y), Vector3(_b.x, 0.0, _b.y), S38_STONE, uvn, uvn, uvn, -1.0)


## Karowa 18a (1978, Dąbrowski, Kuźmienko, Nowak, Sembrat), from the Mac photo gather
## (docs/landmarks/photo-reports/karowa18a.md; the street is on the south-east side, the report's
## "rear", as the road and the ortho show). Nine columns of splayed roughcast boxes two storeys
## tall hang out of an ochre wall, each column a storey off the next like a brick bond, with wide
## white windows between them: the sculpture the block is known for. The roofline drops a few
## metres along the street, and the dark tiled ground floor runs under it all. Frame: u along the
## street front from the uphill (south-west) end, +v out of it. Spec karowa18a.md.
const KR_AT := Vector2(-463.0, -952.0)
const KR_O := Vector2(-477.2, -935.2)
const KR_A := Vector2(0.8426, -0.5398)
const KR_LEN := 43.9
const KR_WALL_V := -1.0      # the wall behind the boxes
const KR_BOX_V := 1.0        # the boxes' fronts
const KR_REAR_V := -12.6
const KR_D := 7.4            # the first floor, map height: the floors run level down the slope
const KR_FLOOR := 2.95
const KR_COLS := [1.6, 5.9, 10.8, 15.3, 19.8, 24.3, 28.8, 33.3, 37.7]
const KR_HIGH := 26.7        # the box tops over the first floor, the uphill four columns
const KR_LOW := 23.6         # and the next five
const KR_END := 19.5         # the last bay
const KR_TAN := Color("#c4a07e")
const KR_SHADE := Color("#94745a")
const KR_RECESS := Color("#8a6144")
const KR_FRAME := Color("#f0eee8")
const KR_GLASS := Color("#2e3640")
const KR_TILE := Color("#3f4448")
const KR_STONE := Color("#8c8a86")
const KR_ROOF := Color("#7a7873")
const KR_RIM := Color("#cfccc4")
const KR_WOOD := Color("#7a5534")


func _find_karowa18a() -> void:
	var q := _tallest_at(KR_AT)
	if q.size() < 20:
		return
	_add_site("karowa18a", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "karowa18a":
		sites[-1]["ring"] = _simplify(q, 0.5)
		sites[-1]["raw"] = q


func _build_karowa18a(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var d := KR_D
	_o = KR_O
	_a = KR_A
	_b = Vector2(-KR_A.y, KR_A.x)
	_mode = M_STONE
	var mid := (KR_WALL_V + KR_REAR_V) * 0.5
	var hv := (KR_WALL_V - KR_REAR_V) * 0.5
	# windows: wide white windows between the columns, a storey at a time, and strips on the rear.
	for c in KR_COLS.size() - 1:
		var u := (float(KR_COLS[c]) + float(KR_COLS[c + 1])) * 0.5
		var rows := 8 if c < 3 else 7
		for k in rows:
			var y := d + 0.75 + KR_FLOOR * k
			_framed(_w(u - 0.9, KR_WALL_V), _w(u + 0.9, KR_WALL_V), y, y + 1.6, _b, KR_FRAME, KR_GLASS, u)
			_framed(_w(u - 1.0, KR_REAR_V), _w(u + 1.0, KR_REAR_V), y, y + 1.4, -_b, KR_FRAME, KR_GLASS, u)
	# slab: the wall in three steps down the street, the last bay coming forward to the boxes' line.
	var c4 := 22.0
	var c9 := 39.7
	var none := Color(0, 0, 0, 0)
	var high := _rect(c4 * 0.5, mid, c4 * 0.5, hv)
	var low := _rect((c4 + c9) * 0.5, mid, (c9 - c4) * 0.5, hv)
	_prism(high, d, d + KR_HIGH - 1.2, KR_SHADE, none, M_STONE)
	_rimmed(high, d + KR_HIGH - 1.2, KR_RIM, KR_ROOF)
	_prism(low, d, d + KR_LOW - 1.2, KR_SHADE, none, M_STONE)
	_rimmed(low, d + KR_LOW - 1.2, KR_RIM, KR_ROOF)
	var ev := (KR_BOX_V - 0.6 + KR_REAR_V) * 0.5
	var ehv := (KR_BOX_V - 0.6 - KR_REAR_V) * 0.5
	var last := _rect((c9 + KR_LEN) * 0.5, ev, (KR_LEN - c9) * 0.5, ehv)
	_prism(last, d, d + KR_END, KR_TAN, none, M_STONE)
	_rimmed(last, d + KR_END, KR_RIM, KR_ROOF)
	for k in 6:
		var y := d + 0.75 + KR_FLOOR * k
		_framed(_w(c9 + 0.5, KR_BOX_V - 0.6), _w(c9 + 1.7, KR_BOX_V - 0.6), y, y + 1.5, _b, KR_FRAME, KR_GLASS, c9)
		_framed(_w(c9 + 2.3, KR_BOX_V - 0.6), _w(c9 + 3.9, KR_BOX_V - 0.6), y, y + 1.5, _b, KR_FRAME, KR_GLASS, c9)
	# balcony_boxes: two storeys tall, the fronts narrower than the backs, the columns a storey
	# apart; between one box and the next the dark gap of the open balcony.
	for c in KR_COLS.size():
		var u := float(KR_COLS[c])
		var top := KR_HIGH if c < 4 else KR_LOW
		var y := d + top - (0.0 if c % 2 == 0 else KR_FLOOR)
		if c % 2 == 1:   # the odd columns' top box is one storey tall
			_kr_box(u, y, d + top, KR_ROOF)
		while y > d + 0.5:
			var y0 := maxf(y - KR_FLOOR * 2.0 + 0.85, d)
			_kr_box(u, y0, y, KR_ROOF if y > d + top - 0.1 else KR_TAN.darkened(0.12))
			y -= KR_FLOOR * 2.0
	# roof_plant: three stair heads on the roof, plant at the tall end.
	for u: float in [13.0, 25.0, 36.0]:
		var y := d + (KR_HIGH if u < c4 else KR_LOW) - 1.2
		var head := _rect(u, -6.0, 3.0, 3.0)
		_prism(head, y + 0.05, y + 1.8, KR_TAN, none, M_STONE)
		_rimmed(head, y + 1.8, KR_RIM, KR_ROOF.lightened(0.1))
	_lbox(5.0, -9.0, 1.4, 1.4, d + KR_HIGH - 1.2, d + KR_HIGH + 0.6, KR_ROOF, M_STONE, KR_ROOF)
	_kr_ground(g, d)
	_collide_raw(site)


## One box of a column, from y0 to y1.
func _kr_box(u: float, y0: float, y1: float, top: Color) -> void:
	var poly := PackedVector2Array([_w(u - 1.35, KR_WALL_V), _w(u + 1.35, KR_WALL_V), _w(u + 0.95, KR_BOX_V), _w(u - 0.95, KR_BOX_V)])
	_hang(poly, y0, y1, KR_TAN, top, KR_RECESS)


## garage_base, base_cladding, entrance: the dark tiled ground floor under the boxes, its shop
## windows, the passage and the two gates, the grey stone at the low end.
func _kr_ground(g: float, d: float) -> void:
	var v := -0.15
	_lbox(KR_LEN * 0.5, (v + KR_REAR_V) * 0.5, KR_LEN * 0.5, (v - KR_REAR_V) * 0.5, g - 0.8, d, KR_TILE, M_STONE, KR_TILE)
	_mode = M_STONE
	_wall(_w(39.7, v + 0.04), _w(KR_LEN, v + 0.04), g - 0.5, d, _b, KR_STONE, 0.0)
	for s: Vector2 in [Vector2(6.2, 7.9), Vector2(8.5, 10.2), Vector2(10.8, 12.5), Vector2(13.1, 14.8), Vector2(15.4, 17.1), Vector2(17.5, 19.1),
			Vector2(23.2, 24.9), Vector2(25.5, 27.2), Vector2(27.8, 29.5), Vector2(30.0, 31.7)]:
		_mode = M_STONE
		_wall(_w(s.x, v + 0.04), _w(s.y, v + 0.04), d - 2.8, d - 0.3, _b, KR_WOOD, s.x)
		_mode = M_PAVILION
		_wall(_w(s.x + 0.1, v + 0.09), _w(s.y - 0.1, v + 0.09), d - 2.7, d - 0.4, _b, Color("#8fa3ad"), s.x)
	for s: Vector3 in [Vector3(2.0, 5.6, 0.0), Vector3(19.5, 22.8, 0.0), Vector3(32.2, 36.0, 1.0), Vector3(36.7, 40.2, 0.0)]:
		_mode = M_STONE
		_wall(_w(s.x, v + 0.06), _w(s.y, v + 0.06), g - 0.5, d - 0.2, _b, KR_WOOD.darkened(0.3) if s.z > 0.0 else Color("#1f2224"), 0.0)


## Pałac Branickich on Miodowa (Tylman van Gameren's, then Fontana's rococo remodel, 1740s):
## the long south-west front, 59.8 m, of cream plaster with dusty-pink pilaster strips, a
## cornice, a stone attic balustrade crowded with statues, three scrolled dormers with
## oculi over the tile roof, and the central gate with its iron balcony. The mass stays
## LoD2's, in its skin (SKINS `branickich`). Spec docs/landmarks/specs/miodowa.md.
## Frame: origin at the front's south-west end on the outline, u along it towards the
## north-east (59.8 m), +v out of it to Miodowa (south-west).
const BRANICKICH := Vector2(-883.7, -1420.3)
const BRANICKICH_AXIS := Vector2(0.856, 0.5167)
const BRANICKICH_LEN := 59.8
const BRK_WALL := Color("#ecd7c2")
const BRK_PINK := Color("#d6a898")
const BRK_STONE := Color("#cfc7b6")
const BRK_DARK := Color("#34383b")
const BRK_COR := 10.4  # the cornice's underside above the ground (the photo: two storeys and a mezzanine)


func _build_branickich(_site: Dictionary) -> void:
	_o = BRANICKICH
	_a = BRANICKICH_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)  # (-0.517, 0.856): out of the front, to Miodowa
	var m := BRANICKICH_LEN * 0.5
	_g = map.terrain_height(_w(m, 1.0).x, _w(m, 1.0).y)
	var g := _g
	_mode = M_STONE
	# the plinth band, then a pilaster strip on every bay (7.1 m apart, in pairs at the pavilions)
	_lbox(m, 0.15, m, 0.15, g - 0.6, g + 0.9, BRK_STONE, M_STONE, BRK_STONE.lightened(0.05))
	for k in 9:
		var u := 3.5 + 7.1 * k
		_lbox(u, 0.2, 0.35, 0.2, g + 0.9, g + BRK_COR, BRK_PINK, M_STONE, BRK_PINK)
	# the cornice and the stone attic with its balustrade
	_lbox(m, 0.35, m + 0.1, 0.45, g + BRK_COR, g + BRK_COR + 0.8, BRK_WALL.lightened(0.04), M_STONE, BRK_WALL.lightened(0.04))
	_lbox(m, 0.0, m, 0.3, g + BRK_COR + 0.8, g + BRK_COR + 2.1, BRK_STONE, M_STONE, BRK_STONE.lightened(0.04))
	# statues on the balustrade, a plinth and a figure every 5.7 m
	for k in 10:
		var u := 2.9 + 5.7 * k
		_lbox(u, 0.0, 0.3, 0.3, g + BRK_COR + 2.1, g + BRK_COR + 2.7, BRK_STONE, M_STONE, BRK_STONE)
		_lbox(u, 0.0, 0.22, 0.2, g + BRK_COR + 2.7, g + BRK_COR + 4.2, BRK_STONE.lightened(0.06), M_STONE, BRK_STONE)
	# the three scrolled dormers: stepped tiers, an oculus, two cherubs
	for u: float in [9.0, m, BRANICKICH_LEN - 9.0]:
		_lbox(u, -0.4, 3.3, 0.6, g + BRK_COR + 2.1, g + BRK_COR + 3.9, BRK_STONE, M_STONE, BRK_STONE)
		_lbox(u, -0.4, 2.3, 0.6, g + BRK_COR + 3.9, g + BRK_COR + 5.5, BRK_STONE, M_STONE, BRK_STONE)
		_lbox(u, -0.4, 1.2, 0.6, g + BRK_COR + 5.5, g + BRK_COR + 6.4, BRK_STONE, M_STONE, BRK_STONE)
		var oc := _w(u, 0.25)
		_disc(Vector3(oc.x, g + BRK_COR + 4.5, oc.y), Vector3(_b.x, 0.0, _b.y), 0.7, 8, BRK_DARK)
		for sd: float in [-1.0, 1.0]:  # the scrolls and the cherubs
			_lbox(u + sd * 3.6, -0.2, 0.5, 0.5, g + BRK_COR + 2.1, g + BRK_COR + 3.3, BRK_STONE.lightened(0.05), M_STONE, BRK_STONE)
			_lbox(u + sd * 3.6, -0.2, 0.25, 0.25, g + BRK_COR + 3.3, g + BRK_COR + 4.5, BRK_STONE.lightened(0.08), M_STONE, BRK_STONE)
	# the gate: a dark door in a stone frame under an iron balcony on two brackets
	_mode = M_GLASS
	_wall(_w(m - 1.2, 0.5), _w(m + 1.2, 0.5), g + 0.9, g + 4.0, _b, BRK_DARK)
	_mode = M_STONE
	_lbox(m, 0.55, 1.7, 0.2, g + 0.9, g + 4.3, BRK_STONE, M_STONE, BRK_STONE)
	_lbox(m, 0.75, 1.9, 0.5, g + 4.3, g + 4.7, BRK_STONE, M_STONE, BRK_STONE)
	_lbox(m, 1.2, 1.9, 0.05, g + 4.7, g + 5.7, BRK_DARK, M_STONE, BRK_DARK)
	# the car meets the front's plinth
	_collide(_rect(m, 0.15, m, 0.2))


# --- Centrum Marszałkowska (F's photos, 2026-11-08): spec docs/landmarks/specs/cmarsz.md ----------

## The glass office on Marszałkowska 126/134 at Świętokrzyska (2017), from F's four photos
## (/mnt/project-files/pkin-surroundings/photos/N1-marszalkowska: the corner by day and by night,
## the straight front from the Palace's side, the aerial): a curtain wall of pale blue-green glass in
## tiers that step back towards the top, dense upright aluminium fins on every face, some of them a
## white LED line at night, a dark shop storey with the store's parody name, two office names on the
## top tier's edge (HEJ! for the recruiter, SPACJE for the shared offices). Massed from the map's
## OpenStreetMap parts (podium 8.9 m, a tier to 17.8 m, the main tier to 34 m, the corner block to
## 40 m); the 4 m posts of the arcade are left out.
const CM_OSM := "Centrum Marszałkowska"

const CM_GLASS := Color("#6f98a4")
const CM_SHOP := Color("#2f3a42")
const CM_FIN := Color("#c9d0d4")
const CM_LED := Color("#e6eef6")
const CM_ROOF := Color("#6f7477")
const CM_FIN_STEP := 1.35
const CM_STOREY := 3.7
const CM_FRONT := Vector2(-0.94, 0.34)     # west: Marszałkowska and the Palace
const CM_NORTH := Vector2(-0.34, -0.94)    # north: Świętokrzyska


func _find_cmarsz() -> void:
	var q := _landmark(CM_OSM)
	if q.size() < 3:
		return
	var parts := _parts_in(q, func(b: Dictionary) -> bool:
			return float(b["h"]) > float(b["mh"]) and absf(_area(_pts(b["p"]))) > 30.0)
	_add_site("cmarsz", [q, Geometry2D.convex_hull(q)])
	if not sites.is_empty() and sites[-1]["key"] == "cmarsz":
		sites[-1]["raw"] = q
		sites[-1]["parts"] = parts
		sites[-1]["quiet"] = true


func _build_cmarsz(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["raw"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var top_y := g
	# The parts stack (each tier's foot is the one under it's top) but overlap a little in the map:
	# a tier starts no lower than the podium's top, and only a top no other tier stands on gets a
	# parapet (two walls or fins in one plane flicker).
	var podium := 0.0
	var feet: Array[float] = []
	for b: Dictionary in site["parts"]:
		if float(b["mh"]) < 0.5:
			podium = maxf(podium, float(b["h"]))
		else:
			feet.append(float(b["mh"]))
	for b: Dictionary in site["parts"]:
		var poly := _pts(b["p"])
		var y0 := g + maxf(float(b["mh"]), podium if float(b["mh"]) >= 0.5 else 0.0)
		var y1 := g + float(b["h"])
		if y1 <= y0 + 0.5:
			continue
		top_y = maxf(top_y, y1)
		if float(b["mh"]) < 0.5:
			if y1 < g + 6.0:
				continue  # a low piece (the arcade's posts): the podium's shop storey covers it
			# The podium: the dark shop storey, then the glass over it.
			_prism(poly, g - 0.4, g + 4.4, CM_SHOP, none, M_PAVILION)
			_prism(poly, g + 4.4, y1, CM_GLASS, CM_ROOF, M_GLASS, M_STONE)
			_mullions(poly, g + 4.6, y1 - 0.2, CM_FIN_STEP, 0.18, CM_FIN)
			_cm_leds(poly, g + 4.4, y1)
		else:
			_prism(poly, y0, y1, CM_GLASS, CM_ROOF, M_GLASS, M_STONE)
			_mullions(poly, y0 + 0.2, y1 - 0.2, CM_FIN_STEP, 0.18, CM_FIN)
			_cm_leds(poly, y0, y1)
		var covered := false
		for f in feet:
			covered = covered or absf(f - float(b["h"])) < 0.3
		if not covered:
			_prism(poly, y1, y1 + 0.6, CM_FIN, none, M_STONE)  # the parapet
	# The names: the store over the shop storey on the corner, the offices on the top tier.
	var i := _edge_facing(ring, CM_FRONT, 10.0)
	if i >= 0:
		var a := ring[i]
		var c := ring[(i + 1) % ring.size()]
		var o := _out(ring, a, c)
		var mid := (a + c) * 0.5 + o * 0.3
		var k := minf(0.35 * a.distance_to(c) / Neon.length_of("SEZON"), 1.4 / (Neon.ROW_H * Neon.PIXEL))
		signs.append(["SEZON", Vector3(mid.x, g + 5.0, mid.y), Vector3(o.x, 0.0, o.y), k, Color(0.3, 0.85, 1.0)])
		k = minf(0.3 * a.distance_to(c) / Neon.length_of("HEJ!"), 2.4 / (Neon.ROW_H * Neon.PIXEL))
		signs.append(["HEJ!", Vector3(mid.x, top_y + 0.7, mid.y), Vector3(o.x, 0.0, o.y), k, Color(0.25, 0.45, 1.0)])
	var j := _edge_facing(ring, CM_NORTH, 6.0)
	if j >= 0:
		var a := ring[j]
		var c := ring[(j + 1) % ring.size()]
		var o := _out(ring, a, c)
		var mid := (a + c) * 0.5 + o * 0.3
		var k := minf(0.7 * a.distance_to(c) / Neon.length_of("SPACJE"), 1.8 / (Neon.ROW_H * Neon.PIXEL))
		signs.append(["SPACJE", Vector3(mid.x, top_y + 0.7, mid.y), Vector3(o.x, 0.0, o.y), k, Color(0.95, 0.96, 1.0)])
	_collide(ring)


## The night photo's white LED lines: on every fourth fin a short lit stroke in each storey, the
## strokes of one storey two fins over from the one below, so the faces read as a staggered dash
## pattern rather than full-height stripes. M_LAMP glows only at night.
func _cm_leds(poly: PackedVector2Array, y0: float, y1: float) -> void:
	if y1 - y0 < 2.0:
		return
	_mode = M_LAMP
	var floors := maxi(1, floori((y1 - y0) / CM_STOREY))
	var h := (y1 - y0) / floors
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var len := a.distance_to(b)
		if len < 4.0:
			continue
		var o := _out(poly, a, b)
		var d := (b - a) / len
		var n := maxi(1, roundi(len / CM_FIN_STEP))
		for f in floors:
			var ya := y0 + f * h + 0.5
			var yb := ya + h * 0.55
			for k in range(1 + 2 * (f % 2), n, 4):
				var c := a + d * len * k / n + o * 0.26
				var p0 := c - d * 0.17
				var p1 := c + d * 0.17
				_quad(Vector3(p0.x, ya, p0.y), Vector3(p1.x, ya, p1.y), Vector3(p1.x, yb, p1.y),
						Vector3(p0.x, yb, p0.y), Vector3(o.x, 0.0, o.y), CM_LED)
	_mode = M_STONE


# --- Nowogrodzka 31 and the rooftop billboard (F's four photos and Google 3D views, 2026-11-07) -------

## The cream six-storey office block on the south side of Nowogrodzka between Marszałkowska and
## Parkingowa, across the street from the Novotel (OpenStreetMap buildings 445 and 444, LoD2 roof
## about 24 m over the pavement). A C in plan: the long front along Parkingowa (78.5 m, east), a
## wing at each end reaching west, the court between them open towards Marszałkowska 99 (the white
## balconied slab, its own site). F's photos: a long regular grid of square windows (five office
## floors and a row of small attic windows), thin floor bands and a projecting cornice, shops and
## bars on the ground floor (fairy lights, neon, violet glass), white "offices to let" banners. The
## end wall on Nowogrodzka faces the Novotel: its east 11 m bare with windows and a to-let banner,
## the rest under a huge dark ad banner from the second floor up (a cat-food advert; here the
## parody MRAU, whose slogan is the parody's own), and over that wall's roof edge stands a white
## billboard 38 m wide on a steel stand, lit at night by 15 lamps on arms along its top edge (the
## streaks of light in the night photos are the camera's, F says: no beams in the air).
## Frame: u along the Parkingowa front from Nowogrodzka (south), v east (out of that front); the
## end wall is u = 0, facing -u (north).
const N31_AT := Vector2(-699.8, 586.4)    # in OSM 445 (the north half)
const N31_AT2 := Vector2(-685.2, 625.9)   # in OSM 444 (the south half)
const N31_O := Vector2(-704.5, 556.2)
const N31_A := Vector2(0.3454, 0.9384)
const N31_LEN := 78.5        # the Parkingowa front
const N31_END := 36.8        # the end wall on Nowogrodzka
const N31_BARE := 11.2       # its east part, not under the ad banner
const N31_DEPTH := 12.9      # the slab between the wings
const N31_WING := 12.8       # the wings' depth
const N31_GROUND := 4.6      # the shops' storey
const N31_FLOOR := 3.1
const N31_TOP := 24.0        # LoD2: the roof over the Nowogrodzka pavement
const N31_BAYS := 29
const N31_END_BAYS := 14
const N31_PLAN := [Vector2(0.0, 0.0), Vector2(N31_LEN, 0.0), Vector2(N31_LEN, -N31_END), Vector2(N31_LEN - 13.8, -N31_END),
		Vector2(N31_LEN - 13.8, -N31_DEPTH), Vector2(N31_WING, -N31_DEPTH), Vector2(N31_WING, -N31_END), Vector2(0.0, -N31_END)]
const N31_WALL := Color("#dbd6c9")
const N31_BAND := Color("#efebe0")
const N31_FRAME := Color("#f1efe8")
const N31_GLASS := Color("#232b33")
const N31_BASE := Color("#7b756a")
const N31_FASCIA := Color("#4b4741")
const N31_ROOF := Color("#6d6f70")
const N31_STEEL := Color("#6b7075")
const N31_BANNER := Color("#2b2e33")
const N31_PANEL := Color("#c3c8cb")
const N31_ART := Color("#40444a")
const N31_LAMP := Color("#fff4dc")
const N31_FAIRY := Color("#ffd98a")
## The shop panes along the Parkingowa front, bay by bay from Nowogrodzka: 0 dark glass, 1 warm,
## 2 pink, 3 cool; then the end wall's, from the east corner.
const N31_SHOPS_E := [2, 1, 1, 0, 1, 2, 1, 3, 1, 1, 0, 1, 2, 1, 1, 3, 1, 0, 0, 1, 1, 2, 1, 3, 1, 1, 0, 1, 1]
const N31_SHOPS_N := [1, 1, 0, 1, 2, 0, 1, 1, 3, 1, 0, 2, 1, 1]
## The to-let banners on the Parkingowa front (bays i0..i1, the third floor).
const N31_TO_LET := [Vector2i(5, 8), Vector2i(19, 22)]


func _find_nowogrodzka31() -> void:
	var q := _tallest_at(N31_AT)
	var q2 := _tallest_at(N31_AT2)
	if q.size() < 8:
		return
	var zone: Array = [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))]
	if q2.size() >= 4:
		zone.append(_largest(Geometry2D.offset_polygon(q2, 1.5, Geometry2D.JOIN_MITER)))
	_add_site("nowogrodzka31", zone)
	if not sites.is_empty() and sites[-1]["key"] == "nowogrodzka31":
		sites[-1]["ring"] = _simplify(q, 0.15)
		sites[-1]["raw"] = q
		sites[-1]["raw2"] = q2


## A shop pane on a wall a→b: dark glass, or lit from inside (warm, pink, cool).
func _n31_pane(a: Vector2, b: Vector2, y0: float, y1: float, out: Vector2, kind: int, run: float) -> void:
	var keep := _mode
	var e := (b - a).normalized()
	_mode = M_STONE
	_wall(a - e * 0.1 + out * 0.06, b + e * 0.1 + out * 0.06, y0 - 0.12, y1 + 0.12, out, N31_FRAME.darkened(0.25), run)
	_mode = [M_GLASS, M_PAVILION, M_PAVILION + 0.375, M_PAVILION + 0.5][kind]
	_wall(a + out * 0.1, b + out * 0.1, y0, y1, out, Color("#2c3a40") if kind == 0 else Color("#4a5560"), run)
	_mode = keep


## A small bulb on a string (fairy lights): a lit square 14 cm wide.
func _n31_bulb(c: Vector2, e: Vector2, y: float, out: Vector2, col: Color) -> void:
	var keep := _mode
	_mode = M_LAMP
	_wall(c - e * 0.07, c + e * 0.07, y, y + 0.14, out, col)
	_mode = keep


## A to-let banner on a wall a→b (white, a red strip under the writing), `proud` out of it.
func _n31_to_let(a: Vector2, b: Vector2, y0: float, out: Vector2) -> void:
	_mode = M_STONE
	_wall(a + out * 0.16, b + out * 0.16, y0, y0 + 2.6, out, Color("#f1efe9"))
	_wall(a + out * 0.2, b + out * 0.2, y0, y0 + 0.7, out, Color("#c8242c"))
	var mid := (a + b) * 0.5 + out * 0.2
	signs.append(["BIURA", Vector3(mid.x, y0 + 1.75, mid.y), Vector3(out.x, 0.0, out.y), 0.34, Color(0.8, 0.08, 0.1)])
	signs.append(["DO WYNAJĘCIA", Vector3(mid.x, y0 + 0.85, mid.y), Vector3(out.x, 0.0, out.y), 0.3, Color(0.8, 0.08, 0.1)])


func _build_nowogrodzka31(site: Dictionary) -> void:
	var raw: PackedVector2Array = site["raw"]
	_g = _ground_under(raw)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_o = N31_O
	_a = N31_A
	_b = Vector2(_a.y, -_a.x)   # east, out of the Parkingowa front
	var top := g + N31_TOP
	var out_e := _b              # the Parkingowa front
	var out_n := -_a             # the end wall, onto Nowogrodzka and the Novotel
	var plan := PackedVector2Array()
	for p: Vector2 in N31_PLAN:
		plan.append(_w(p.x, p.y))
	_mode = M_STONE
	# The ground falls about 1.3 m to the south end: the walls reach down past it.
	_prism(plan, g - 2.0, top + 0.3, N31_WALL, none, M_STONE, M_STONE)
	_rimmed(plan, top + 0.3, N31_BAND, N31_ROOF)
	# The shops' plinth and fascia on the two street faces.
	_wall(_w(0.0, 0.05), _w(N31_LEN, 0.05), g - 2.0, g + 0.55, out_e, N31_BASE)
	_wall(_w(-0.05, -N31_END), _w(-0.05, 0.0), g - 2.0, g + 0.55, out_n, N31_BASE)
	_hang(_rect(N31_LEN * 0.5, 0.2, N31_LEN * 0.5, 0.2), g + 4.0, g + N31_GROUND, N31_FASCIA, N31_BASE, N31_FASCIA)
	_hang(_rect(-0.2, -N31_END * 0.5, 0.2, N31_END * 0.5), g + 4.0, g + N31_GROUND, N31_FASCIA, N31_BASE, N31_FASCIA)
	# The floor bands (the slab edges) and the cornice on both street faces; the corner pieces
	# only touch, so no two faces share a plane.
	for k in range(0, 6):
		var yb := g + N31_GROUND + N31_FLOOR * k - 0.1
		_hang(_rect(N31_LEN * 0.5, 0.08, N31_LEN * 0.5, 0.08), yb, yb + 0.32, N31_BAND, N31_BAND, N31_WALL)
		_hang(_rect(-0.08, -N31_END * 0.5, 0.08, N31_END * 0.5), yb, yb + 0.32, N31_BAND, N31_BAND, N31_WALL)
	_hang(_rect(N31_LEN * 0.5, 0.32, N31_LEN * 0.5, 0.32), top - 1.05, top + 0.05, N31_BAND, N31_BAND, N31_WALL)
	_hang(_rect(-0.32, -N31_END * 0.5 + 0.32, 0.32, N31_END * 0.5 + 0.32), top - 1.05, top + 0.05, N31_BAND, N31_BAND, N31_WALL)
	# The Parkingowa front: 29 bays of square windows over the shops.
	var bw := N31_LEN / float(N31_BAYS)
	for i in N31_BAYS:
		var uc := bw * (float(i) + 0.5)
		var let := false
		for r: Vector2i in N31_TO_LET:
			if i >= r.x and i <= r.y:
				let = true
		for k in 5:
			if let and k == 2:
				continue   # under the banner
			var y := g + N31_GROUND + N31_FLOOR * k
			_framed(_w(uc - 0.65, 0.0), _w(uc + 0.65, 0.0), y + 0.85, y + 2.3, out_e, N31_FRAME, N31_GLASS, float(i) * 4.5 + float(k) * 13.5)
		var ya := g + N31_GROUND + N31_FLOOR * 5.0
		_framed(_w(uc - 0.5, 0.0), _w(uc + 0.5, 0.0), ya + 0.6, ya + 1.5, out_e, N31_FRAME, N31_GLASS, float(i) * 4.5 + 71.0)
		_n31_pane(_w(uc - 1.1, 0.0), _w(uc + 1.1, 0.0), g + 0.6, g + 3.9, out_e, int(N31_SHOPS_E[i]), float(i) * 3.1)
	for r: Vector2i in N31_TO_LET:
		_n31_to_let(_w(bw * float(r.x) + 0.2, 0.0), _w(bw * float(r.y + 1) - 0.2, 0.0), g + N31_GROUND + N31_FLOOR * 2.0 + 0.3, out_e)
	# The end wall: shops all along; windows on every floor over its bare east part (with a to-let
	# banner), only the first floor's under the ad banner's hem.
	var ew := N31_END / float(N31_END_BAYS)
	for i in N31_END_BAYS:
		var vc := -ew * (float(i) + 0.5)
		_n31_pane(_w(0.0, vc + 1.05), _w(0.0, vc - 1.05), g + 0.6, g + 3.9, out_n, int(N31_SHOPS_N[i]), 90.0 + float(i) * 3.1)
		var rows := 5 if vc > -N31_BARE else 1
		for k in rows:
			if rows == 5 and k == 2:
				continue
			var y := g + N31_GROUND + N31_FLOOR * k
			_framed(_w(0.0, vc + 0.65), _w(0.0, vc - 0.65), y + 0.85, y + 2.3, out_n, N31_FRAME, N31_GLASS, 130.0 + float(i) * 4.5 + float(k) * 13.5)
		if rows == 5:
			var ya := g + N31_GROUND + N31_FLOOR * 5.0
			_framed(_w(0.0, vc + 0.5), _w(0.0, vc - 0.5), ya + 0.6, ya + 1.5, out_n, N31_FRAME, N31_GLASS, 200.0 + float(i) * 4.5)
	_n31_to_let(_w(0.0, -0.4), _w(0.0, -N31_BARE + 0.3), g + N31_GROUND + N31_FLOOR * 2.0 + 0.3, out_n)
	_mode = M_STONE
	var hem := g + N31_GROUND + N31_FLOOR + 0.4
	var b0 := -N31_BARE - 0.4
	var b1 := -N31_END + 0.4
	_wall(_w(-0.3, b0), _w(-0.3, b1), hem, top + 0.3, out_n, N31_BANNER)
	_wall(_w(-0.34, b0), _w(-0.34, b1), hem, hem + 0.4, out_n, N31_BANNER.darkened(0.3))
	for v: float in [-17.6, -24.0, -30.4]:
		_wall(_w(-0.32, v + 0.04), _w(-0.32, v - 0.04), hem + 0.4, top + 0.3, out_n, N31_BANNER.lightened(0.1))
	var mid_v := (b0 + b1) * 0.5
	for s: Array in [["SZTUKA", 1.3, 9.8], ["UKŁADANIA", 1.3, 7.0], ["MISKI", 1.3, 4.2]]:
		var p := _w(-0.3, mid_v)
		signs.append([s[0], Vector3(p.x, hem + float(s[2]), p.y), Vector3(out_n.x, 0.0, out_n.y), float(s[1]), Color(0.96, 0.96, 0.93)])
	var small := _w(-0.3, mid_v)
	signs.append(["DLA KOTÓW", Vector3(small.x, hem + 3.0, small.y), Vector3(out_n.x, 0.0, out_n.y), 0.5, Color(0.9, 0.9, 0.88)])
	# The lamps under the banner's hem, throwing light up its face.
	for k in 11:
		var vv := b0 - 1.2 - float(k) * 2.2
		var lp := _w(-0.9, vv)
		var arm0 := _w(-0.1, vv)
		_beam(Vector3(arm0.x, hem - 0.15, arm0.y), Vector3(lp.x, hem - 0.35, lp.y), 0.06, N31_STEEL)
		_prism(_square(lp, 0.12), hem - 0.45, hem - 0.3, N31_LAMP, N31_LAMP, M_LAMP, M_LAMP)
	# Fairy lights along the fascias, the shop names in neon.
	for k in 14:
		_n31_bulb(_w(2.0 + float(k) * 1.6, 0.22), _a, g + 3.7 + 0.12 * float(k % 2), out_e, N31_FAIRY)
	for k in 16:
		_n31_bulb(_w(-0.22, -13.0 - float(k) * 1.4), _b, g + 3.7 + 0.12 * float(k % 2), out_n, N31_FAIRY)
	var restau := _w(30.0, 0.3)
	signs.append(["RESTAURACJA", Vector3(restau.x, g + 4.0, restau.y), Vector3(out_e.x, 0.0, out_e.y), 0.5, Color(1.0, 0.14, 0.1)])
	var bar := _w(-0.3, -5.0)
	signs.append(["BUM BAR", Vector3(bar.x, g + 4.0, bar.y), Vector3(out_n.x, 0.0, out_n.y), 0.5, Color(1.0, 0.72, 0.2)])
	# The roof: a lift head and vent boxes.
	_lbox(30.0, -6.0, 2.2, 2.0, top + 0.3, top + 3.0, N31_WALL.darkened(0.04), M_STONE, N31_ROOF)
	_lbox(52.0, -5.5, 1.6, 1.4, top + 0.3, top + 1.8, N31_STEEL.lightened(0.2), M_STONE, N31_ROOF)
	_lbox(8.0, -24.0, 1.2, 0.9, top + 0.3, top + 1.5, N31_STEEL.lightened(0.15), M_STONE, N31_ROOF)
	_n31_billboard(top)
	_collide(raw)
	pocket_rings.append(raw)
	var raw2: PackedVector2Array = site.get("raw2", PackedVector2Array())
	if raw2.size() >= 3:
		_collide(raw2)
		pocket_rings.append(raw2)


## The rooftop billboard over the end wall's roof edge, facing the Novotel: a white panel 38 m
## wide and 8.6 m tall on a steel base and raking stays, with the advert on it (the bowl of food
## on the east, the cat, the parody MRAU on the west), 15 lamps on arms along its top edge that
## light its face.
func _n31_billboard(top: float) -> void:
	var u := -0.5                # the panel's face, a little out over the cornice
	var v0 := 0.4
	var v1 := -38.0              # over Marszałkowska 99's roof at its west end
	var y0 := top + 0.9
	var y1 := y0 + 8.6
	var vm := (v0 + v1) * 0.5
	var hv := (v0 - v1) * 0.5
	_mode = M_STONE
	_lbox(u + 0.7, vm, 0.4, hv, top + 0.3, top + 1.0, N31_STEEL, M_STONE, N31_STEEL)   # the base beam
	for v: float in [0.0, -5.4, -10.8, -16.2, -21.6, -27.0, -32.4, -37.4]:
		var foot := _w(u + 3.0, v)
		var head := _w(u + 0.1, v)
		_beam(Vector3(foot.x, top + 0.3, foot.y), Vector3(head.x, y1 - 1.0, head.y), 0.16, N31_STEEL)
	_lbox(u, vm, 0.14, hv, y0, y1, N31_PANEL, M_LAMP, N31_STEEL)       # the white face, lit
	var fu := u - 0.2   # the art's plane
	_lbox(fu, vm, 0.07, hv - 0.6, y0 + 0.9, y1 - 0.7, N31_ART, M_LAMP, N31_ART)
	# The bowl of food with its steam, then the cat.
	_lbox(fu - 0.2, -9.0, 0.1, 2.3, y0 + 1.7, y0 + 2.5, Color("#6b7276"), M_LAMP, Color("#6b7276"))
	_lbox(fu - 0.3, -9.2, 0.1, 1.4, y0 + 2.5, y0 + 3.6, Color("#b2432b"), M_LAMP, Color("#b2432b"))
	for v: float in [-7.8, -9.0, -10.2]:
		_lbox(fu - 0.2, v, 0.06, 0.32, y0 + 3.8, y0 + 6.6, Color("#9aa0a4"), M_LAMP, Color("#9aa0a4"))
	_lbox(fu - 0.3, -17.0, 0.1, 1.5, y0 + 1.0, y0 + 4.6, Color("#9a7448"), M_LAMP, Color("#9a7448"))   # the cat's body
	_lbox(fu - 0.3, -17.0, 0.1, 1.0, y0 + 4.6, y0 + 6.1, Color("#a9804f"), M_LAMP, Color("#a9804f"))   # its head
	_pyramid(_rect(fu - 0.3, -16.3, 0.12, 0.3), y0 + 6.1, y0 + 7.3, Color("#9a7448"))
	_pyramid(_rect(fu - 0.3, -17.7, 0.12, 0.3), y0 + 6.1, y0 + 7.3, Color("#9a7448"))
	var mark := _w(fu - 0.4, -29.0)
	signs.append(["MRAU", Vector3(mark.x, y0 + 3.3, mark.y), Vector3(-_a.x, 0.0, -_a.y), 1.8, Color(0.97, 0.97, 0.95)])
	signs.append(["DLA KOTÓW", Vector3(mark.x, y0 + 2.0, mark.y), Vector3(-_a.x, 0.0, -_a.y), 0.5, Color(0.9, 0.9, 0.88)])
	# Fifteen lamps on arms along the top edge, lighting the face (the panel glows at night).
	for k in 15:
		var vv := v0 - 1.2 - float(k) * 2.55
		var root := _w(u - 0.1, vv)
		var head := _w(u - 1.7, vv)
		_beam(Vector3(root.x, y1 - 0.15, root.y), Vector3(head.x, y1 + 0.5, head.y), 0.07, N31_STEEL)
		_prism(_square(head, 0.2), y1 + 0.38, y1 + 0.82, N31_LAMP, N31_LAMP, M_LAMP, M_LAMP)


# --- Marszałkowska 99 (F's photos and Google 3D views, 2026-11-07) ------------------------------

## The white eight-storey slab along Marszałkowska between Nowogrodzka and Żurawia, behind
## Nowogrodzka 31's west wing (OpenStreetMap building 5505, LoD2 roof 27.3 m over the pavement).
## F's night photos show its narrow north end beside the ad banner, stacked with balconies; the 3D
## views its Marszałkowska front, a grid of windows and balconies over the shops, a yellow ad
## banner near the north end. Built in Nowogrodzka 31's frame (u south, v east): the slab is
## u 0..77, v -53.8 (the Marszałkowska front) to -40.3 (the court), with the stair tower's bump
## out into the court.
const M99_AT := Vector2(-738.2, 600.6)
const M99_V0 := -53.8
const M99_V1 := -40.3
const M99_LEN := 77.0
const M99_TOP := 27.3
const M99_GROUND := 4.5
const M99_FLOOR := 2.85
const M99_BAYS := 22
const M99_WALL := Color("#e6e4dc")
const M99_SLAB := Color("#d6d4cc")
const M99_RAIL := Color("#efefea")
const M99_GLASS := Color("#2b333b")
const M99_ROOF := Color("#77797a")


func _find_marszalkowska99() -> void:
	var q := _tallest_at(M99_AT)
	if q.size() < 8:
		return
	_add_site("marszalkowska99", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "marszalkowska99":
		sites[-1]["ring"] = _simplify(q, 0.15)
		sites[-1]["raw"] = q


## A balcony: a slab 1.1 m deep on face `out` at c (plan), its solid parapet front and sides.
func _m99_balcony(c: Vector2, e: Vector2, out: Vector2, y: float, half: float) -> void:
	var p := PackedVector2Array([c - e * half, c + e * half, c + e * half + out * 1.1, c - e * half + out * 1.1])
	_hang(p, y - 0.18, y, M99_SLAB, M99_SLAB, M99_SLAB.darkened(0.15))
	var f := PackedVector2Array([c - e * half + out * 1.0, c + e * half + out * 1.0, c + e * half + out * 1.1, c - e * half + out * 1.1])
	_prism(f, y, y + 1.0, M99_RAIL, M99_RAIL, M_STONE, M_STONE)


func _build_marszalkowska99(site: Dictionary) -> void:
	var raw: PackedVector2Array = site["raw"]
	_g = _ground_under(raw)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_o = N31_O
	_a = N31_A
	_b = Vector2(_a.y, -_a.x)
	var top := g + M99_TOP
	var out_w := -_b    # Marszałkowska
	var out_c := _b     # the court
	var out_n := -_a    # Nowogrodzka
	_mode = M_STONE
	_prism(_rect(M99_LEN * 0.5, (M99_V0 + M99_V1) * 0.5, M99_LEN * 0.5, (M99_V1 - M99_V0) * 0.5), g - 1.0, top + 0.3, M99_WALL, none,
			M_STONE, M_STONE)
	_rimmed(_rect(M99_LEN * 0.5, (M99_V0 + M99_V1) * 0.5, M99_LEN * 0.5, (M99_V1 - M99_V0) * 0.5), top + 0.3, M99_RAIL, M99_ROOF)
	_lbox(40.45, -36.45, 1.85, 3.85, g - 1.0, top + 1.8, M99_WALL.darkened(0.04), M_STONE, M99_ROOF)   # the stair tower
	_lbox(20.0, -47.0, 2.4, 2.0, top + 0.3, top + 2.3, M99_WALL.darkened(0.05), M_STONE, M99_ROOF)
	_lbox(58.0, -47.0, 2.4, 2.0, top + 0.3, top + 2.3, M99_WALL.darkened(0.05), M_STONE, M99_ROOF)
	# The shops' dark base on the Marszałkowska front and the north end.
	_wall(_w(0.0, M99_V0 - 0.05), _w(M99_LEN, M99_V0 - 0.05), g - 1.0, g + 0.5, out_w, N31_BASE)
	_hang(_rect(M99_LEN * 0.5, M99_V0 - 0.25, M99_LEN * 0.5, 0.25), g + 3.9, g + M99_GROUND, N31_FASCIA, N31_BASE, N31_FASCIA)
	var bw := M99_LEN / float(M99_BAYS)
	var floors := floori((M99_TOP - M99_GROUND - 0.6) / M99_FLOOR)
	for i in M99_BAYS:
		var uc := bw * (float(i) + 0.5)
		_n31_pane(_w(uc + 1.3, M99_V0), _w(uc - 1.3, M99_V0), g + 0.6, g + 3.8, out_w, [1, 0, 1, 2, 1, 3, 0, 1][i % 8], 300.0 + float(i) * 3.1)
		for k in floors:
			var y := g + M99_GROUND + M99_FLOOR * float(k)
			# The Marszałkowska front: a window in every bay, a balcony in front of every other one.
			_framed(_w(uc + 0.7, M99_V0), _w(uc - 0.7, M99_V0), y + 0.8, y + 2.3, out_w, M99_RAIL, M99_GLASS, 400.0 + float(i) * 4.5 + float(k) * 13.5)
			if i % 2 == 1:
				_m99_balcony(_w(uc, M99_V0), _a, out_w, y + 0.2, 1.5)
			# The court side: plain windows.
			_framed(_w(uc - 0.65, M99_V1), _w(uc + 0.65, M99_V1), y + 0.85, y + 2.25, out_c, M99_RAIL, M99_GLASS, 700.0 + float(i) * 4.5 + float(k) * 13.5)
	# The north end on Nowogrodzka: two stacks of balconies (F's night photos).
	for vc: float in [-50.2, -43.9]:
		for k in floors:
			var y := g + M99_GROUND + M99_FLOOR * float(k)
			_framed(_w(0.0, vc - 0.7), _w(0.0, vc + 0.7), y + 0.8, y + 2.3, out_n, M99_RAIL, M99_GLASS, 900.0 + vc * 3.0 + float(k) * 13.5)
			_m99_balcony(_w(0.0, vc), _b, out_n, y + 0.2, 1.7)
	# The yellow ad banner on the Marszałkowska front by the north end.
	_mode = M_STONE
	_wall(_w(13.5, M99_V0 - 1.3), _w(3.0, M99_V0 - 1.3), g + M99_GROUND + 0.3, g + M99_GROUND + 2.0 * M99_FLOOR, out_w, Color("#e8c32a"))
	var ad := _w(8.25, M99_V0 - 1.3)
	signs.append(["PROMOCJA", Vector3(ad.x, g + M99_GROUND + 1.6, ad.y), Vector3(out_w.x, 0.0, out_w.y), 0.6, Color(0.12, 0.12, 0.14)])
	_collide_raw(site)


# --- Cyfrowy Parking Novotel, Nowogrodzka 27 (F's five photos, 2026-11-07) ----------------------

## The open-deck car park behind the hotel, an L of 36 x 44 m on Nowogrodzka and a 14 m wing running
## 87 m down Parkingowa (the OSM outline "parking", 30.7 m): a ground storey of shop glass, then
## eight decks whose concrete spandrels (1.75 m, a 3.45 m pitch) carry one painted mural round the
## corner: red swirls with orange patches and white roses at the Nowogrodzka end, turning green over
## teal and light blue down Parkingowa. The bar sits on the corner (parody names: KLUBOLEJNIA on
## Nowogrodzka, LEJALNIA drink bar on Parkingowa, blue neon, a red lit pier), then the dark entry
## with its red-and-white barrier and the blue P, the lit shops, and along the Nowogrodzka foot
## the poster boards. Beside it the blank corrugated wall of the next block carries a parody of the
## paint brand's wordmark (KOLORKI) and the mural's red head. Frame: u along the Parkingowa face
## from the corner (south), v out of it (west); the corner is the origin. Log docs/landmarks/cparking.md.
const CP_AT := Vector2(-660.0, 580.0)
const CP_O := Vector2(-682.5, 544.6)
const CP_A := Vector2(0.30148, 0.95354)
const CP_GH := 4.8            # the ground storey: shop glass 3.3 m under a 1.5 m fascia
const CP_PITCH := 3.45        # deck to deck
const CP_LEVELS := 8
const CP_BEAM := 0.65         # a spandrel hangs this far under its deck...
const CP_PARAPET := 1.1       # ...and stands this far over it (1.75 m together)
const CP_SETBACK := 5.0       # the lit core behind the open decks
const CP_WALL_A := Vector2(-648.6, 533.2)   # the next block's Nowogrodzka face (the corrugated wall)
const CP_WALL_B := Vector2(-627.1, 525.8)
const CP_WALL_H := 22.0
const CP_RED := Color("#b64a3e")
const CP_RED_D := Color("#9b3b36")
const CP_ORANGE := Color("#d98238")
const CP_ORANGE_L := Color("#e69b48")
const CP_WHITE := Color("#ece6d8")
const CP_GREEN := Color("#86b96a")
const CP_GREEN_L := Color("#a9cd74")
const CP_YELLOWG := Color("#cfd57c")
const CP_TEAL := Color("#4fa9a6")
const CP_BLUE := Color("#93c4d6")
const CP_CONC := Color("#bdb8ab")
const CP_FLOOR := Color("#9c9a92")
const CP_CORE := Color("#6d7573")
const CP_DARK := Color("#24282d")
const CP_NAVY := Color("#1f2f6b")
const CP_BLUE_NEON := Color(0.2, 0.5, 1.0)
const CP_POSTERS := [Color("#4b2f7a"), Color("#e08a2c"), Color("#1f2f66"), Color("#b83a7a"), Color("#2c8a8a"), Color("#2a2218"), Color("#e6e2d6")]


func _find_cparking() -> void:
	var q := _tallest_at(CP_AT)
	if q.size() < 5:
		return
	_add_site("cparking", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "cparking":
		sites[-1]["ring"] = _simplify(q, 0.15)
		sites[-1]["raw"] = q


func _cp_hash(a: float, b: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233) * 43758.5453, 1.0)


## Which face an edge is: 0 Nowogrodzka, 1 Parkingowa, 2 the north block's east face, 3 the wing's
## south end, 4 the inner faces (the wing's east side and the step), mostly hidden by neighbours.
func _cp_face(a: Vector2, b: Vector2) -> int:
	var lm := _local((a + b) * 0.5)
	if lm.x < 1.5:
		return 0
	if lm.y > -1.5:
		return 1
	if lm.x > 86.0:
		return 3
	if lm.y < -30.0:
		return 2
	return 4


## The mural's colour at `pp` metres round the corner (the Nowogrodzka face counted from its far
## end, 0 to 35.8, then down Parkingowa) on deck `k` (0 lowest).
func _cp_mural(face: int, pp: float, k: int) -> Color:
	var h := _cp_hash(pp * 0.61, float(k) * 3.7 + float(face))
	var red := CP_RED if h < 0.62 else CP_RED_D
	var orange := CP_ORANGE if h < 0.7 else CP_ORANGE_L
	var u := pp - 35.8
	match face:
		0:
			if k == 0 and pp > 12.0:
				return orange
			if (k == 1 and pp > 27.0) or (k == 2 and pp > 32.0):
				return orange
			return red
		1:
			if u < 38.0:
				if k <= 2 or (k == 4 and u > 10.0 and u < 26.0) or (k == 7 and u > 24.0):
					return orange
				return red
			var d := (u - 40.0) / 7.0
			var g_edge := 7.4 - d
			if float(k) >= g_edge:
				return CP_YELLOWG if h > 0.9 else (CP_GREEN if h < 0.5 else CP_GREEN_L)
			if float(k) >= g_edge - 2.6:
				return CP_TEAL if h < 0.6 else CP_BLUE
			return orange if k <= 1 else red
		2:
			if k >= 4:
				return CP_GREEN if h < 0.55 else CP_GREEN_L
			return CP_TEAL if h < 0.6 else CP_BLUE
		3:
			return CP_TEAL if h < 0.55 else CP_BLUE
	return Color("#a9b4a5") if k >= 4 else Color("#9fb3b0")


## A wall in the local plan (u, v) facing the local direction `out`, `proud` metres off the line.
func _cp_lw(u0: float, v0: float, u1: float, v1: float, y0: float, y1: float, out: Vector2, col: Color, mode := M_STONE, proud := 0.0) -> void:
	var o := _a * out.x + _b * out.y
	var keep := _mode
	_mode = mode
	_wall(_w(u0, v0) + o * proud, _w(u1, v1) + o * proud, y0, y1, o, col)
	_mode = keep


func _build_cparking(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_o = CP_O
	_a = CP_A
	_b = Vector2(-CP_A.y, CP_A.x)  # out of the Parkingowa face
	var none := Color(0, 0, 0, 0)
	var f_top := g + CP_GH + CP_BEAM + CP_PITCH * (CP_LEVELS - 1)
	# The base, and behind the open decks the lit core.
	_prism(ring, g - 0.6, g + CP_GH, CP_CONC, none, M_STONE)
	var core := _largest(Geometry2D.offset_polygon(ring, -CP_SETBACK, Geometry2D.JOIN_MITER))
	if core.size() >= 3:
		_prism(core, g + CP_GH, f_top, CP_CORE, none, M_LAMP, M_STONE)
	var slab := _largest(Geometry2D.offset_polygon(ring, -0.35, Geometry2D.JOIN_MITER))
	_mode = M_STONE
	for k in CP_LEVELS:
		_cap(slab, g + CP_GH + CP_BEAM + CP_PITCH * k, CP_FLOOR if k < CP_LEVELS - 1 else Color("#8a8882"))
	# The spandrels, cell by cell, in the mural's colours; columns in the openings; the parapet tops.
	var roses := 0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var ln := a.distance_to(b)
		if ln < 1.0:
			continue
		var e := (b - a) / ln
		var out := _out(ring, a, b)
		var face := _cp_face(a, b)
		var cell := 1.8 if face < 4 else 4.0
		var n := ceili(ln / cell)
		for k in CP_LEVELS:
			var f := g + CP_GH + CP_BEAM + CP_PITCH * k
			var y0 := f - CP_BEAM
			var y1 := f + CP_PARAPET
			var ym := y0 + 0.9
			for j in n:
				var p0 := a + e * (ln * float(j) / n)
				var p1 := a + e * (ln * float(j + 1) / n)
				var lm := _local((p0 + p1) * 0.5)
				var pp := lm.y + 35.8 if face == 0 else (35.8 + lm.x if face == 1 else (absf(lm.x) if face == 2 else lm.x))
				var base := _cp_mural(face, pp, k)
				var j1 := 0.92 + 0.12 * _cp_hash(pp, float(k) + 0.5)
				var j2 := 0.9 + 0.14 * _cp_hash(pp + 3.1, float(k) + 1.5)
				_mode = M_MEMBRANE + 0.5   # floodlit paint: bright at night
				if face == 4:
					_wall(p0, p1, y0, y1, out, Color(base.r * j1, base.g * j1, base.b * j1))
				else:
					_wall(p0, p1, y0, ym, out, Color(base.r * j1, base.g * j1, base.b * j1))
					_wall(p0, p1, ym, y1, out, Color(base.r * j2, base.g * j2, base.b * j2))
			# The parapet's top edge.
			_mode = M_STONE
			_cap(PackedVector2Array([a, b - e * 0.35, b - e * 0.35 - out * 0.35, a - out * 0.35]), y1, Color("#c9c4b6"))
			if face >= 4:
				continue
			# Columns in the opening above (not under the roof deck), 5.6 m apart.
			if k < CP_LEVELS - 1:
				var c := 0
				while 2.0 + 5.6 * c < ln - 1.0:
					var m := a + e * (2.0 + 5.6 * c)
					var lmm := _local(m)
					var ppm := lmm.y + 35.8 if face == 0 else 35.8 + lmm.x
					var warm := _cp_mural(face, ppm, k) == CP_ORANGE or _cp_hash(ppm, float(k) * 1.3) < 0.18
					_wall(m - e * 0.3 - out * 0.55, m + e * 0.3 - out * 0.55, f + CP_PARAPET, f + CP_PITCH - CP_BEAM, out,
							CP_ORANGE if warm and ppm < 60.0 else Color("#cfcabd"))
					c += 1
			# White roses on the red and orange: a ring of two discs, the second a darker swirl.
			var c2 := 0
			while 1.6 + 5.6 * c2 < ln - 1.0 and roses < 90:
				var h2 := _cp_hash(a.x * 0.37 + float(c2), float(k) * 2.9 + a.y * 0.11)
				var m2 := a + e * (1.6 + 5.6 * c2 + (h2 - 0.5) * 2.4)
				var lm2 := _local(m2)
				var pp2 := lm2.y + 35.8 if face == 0 else (35.8 + lm2.x if face == 1 else 99.0)
				var chance := 0.55 if pp2 < 82.0 else 0.0
				if face == 1 and pp2 > 82.0:
					chance = 0.12
				if h2 < chance and _cp_mural(face, pp2, k) in [CP_RED, CP_RED_D, CP_ORANGE, CP_ORANGE_L]:
					var r := 0.45 + 0.5 * _cp_hash(h2, float(k))
					var pos := m2 + out * 0.07
					var yc := f + 0.25 + 0.2 * (h2 - 0.3)
					_mode = M_MEMBRANE + 0.5
					_disc(Vector3(pos.x, yc, pos.y), Vector3(out.x, 0.0, out.y), r, 8, CP_WHITE)
					var pos2 := m2 + out * 0.15 + e * (r * 0.12)
					_disc(Vector3(pos2.x, yc + r * 0.1, pos2.y), Vector3(out.x, 0.0, out.y), r * 0.5, 6, CP_RED_D)
					roses += 1
				c2 += 1
	# The roof deck: two stair and lift heads and the lamp poles.
	_lbox(8.0, -9.0, 3.2, 2.6, f_top, f_top + 3.2, CP_CONC, M_STONE, Color("#77756f"))
	_lbox(76.0, -7.0, 2.6, 3.0, f_top, f_top + 3.2, CP_CONC, M_STONE, Color("#77756f"))
	for pole: Vector2 in [Vector2(14.0, -10.0), Vector2(32.0, -10.0), Vector2(14.0, -26.0), Vector2(32.0, -26.0), Vector2(56.0, -7.0), Vector2(70.0, -7.0)]:
		_lbox(pole.x, pole.y, 0.07, 0.07, f_top, f_top + 4.0, Color("#6e7378"), M_STONE)
		_lbox(pole.x, pole.y, 0.3, 0.3, f_top + 4.0, f_top + 4.2, Color(0.75, 0.68, 0.5), M_LAMP)
	_cp_ground(g)
	_cp_wall_panel(g)
	_collide_raw(site)


## The ground storey: the corner bar on both faces, the entry with its barrier, the shops down
## Parkingowa and the poster boards along Nowogrodzka.
func _cp_ground(g: float) -> void:
	var west := Vector2(0.0, 1.0)
	var north := Vector2(-1.0, 0.0)
	var glass := Color("#3b454d")
	var fascia := Color("#262a30")
	var cream := Color("#e4dccb")
	# Corner bar, Parkingowa side (LEJALNIA): glass between dark mullions, a blue tube under the fascia.
	_cp_lw(0.6, 0.0, 12.4, 0.0, g + 0.45, g + 3.3, west, glass, M_PAVILION, 0.12)
	for u: float in [3.5, 6.5, 9.5]:
		_cp_lw(u - 0.08, 0.0, u + 0.08, 0.0, g + 0.45, g + 3.3, west, CP_DARK, M_STONE, 0.17)
	_cp_lw(0.0, 0.0, 12.8, 0.0, g + 3.3, g + CP_GH, west, fascia, M_STONE, 0.18)
	_cp_lw(0.6, 0.0, 12.4, 0.0, g + 3.18, g + 3.3, west, CP_BLUE_NEON, M_LAMP + 0.5, 0.2)
	_cp_lw(0.6, 0.0, 12.4, 0.0, g + 0.38, g + 0.5, west, CP_BLUE_NEON, M_LAMP + 0.5, 0.2)
	var at := _w(6.4, 0.0) + _b * 0.2
	signs.append(["LEJALNIA", Vector3(at.x, g + 3.3, at.y), Vector3(_b.x, 0.0, _b.y), 0.7, CP_BLUE_NEON])
	var at2 := _w(6.4, 0.0) + _b * 0.2
	signs.append(["DRINK BAR", Vector3(at2.x, g + 2.55, at2.y), Vector3(_b.x, 0.0, _b.y), 0.3, CP_BLUE_NEON])
	# The same bar round the corner on Nowogrodzka (KLUBOLEJNIA).
	_cp_lw(0.0, -0.6, 0.0, -9.8, g + 0.45, g + 3.3, north, glass, M_PAVILION, 0.12)
	for v: float in [-3.5, -6.5]:
		_cp_lw(0.0, v - 0.08, 0.0, v + 0.08, g + 0.45, g + 3.3, north, CP_DARK, M_STONE, 0.17)
	_cp_lw(0.0, 0.0, 0.0, -10.2, g + 3.3, g + CP_GH, north, fascia, M_STONE, 0.18)
	_cp_lw(0.0, -0.6, 0.0, -9.8, g + 3.18, g + 3.3, north, CP_BLUE_NEON, M_LAMP + 0.5, 0.2)
	_cp_lw(0.0, -0.6, 0.0, -9.8, g + 0.38, g + 0.5, north, CP_BLUE_NEON, M_LAMP + 0.5, 0.2)
	var at3 := _w(0.0, -5.0) - _a * 0.2
	signs.append(["KLUBOLEJNIA", Vector3(at3.x, g + 3.35, at3.y), Vector3(-_a.x, 0.0, -_a.y), 0.45, CP_BLUE_NEON])
	# The piers: the cream one on the corner, one at each end, the right one lit red.
	_lbox(0.4, 0.0, 0.6, 0.6, g, g + CP_GH, cream, M_STONE)
	_lbox(0.0, -10.4, 0.5, 0.5, g, g + CP_GH, cream, M_STONE)
	_lbox(13.1, 0.0, 0.5, 0.5, g, g + 4.0, cream, M_STONE)
	_lbox(13.1, 0.55, 0.12, 0.12, g + 0.3, g + 3.5, Color(0.75, 0.1, 0.25), M_LAMP)
	# The entry: a dark mouth with a pink light, the barrier, its orange post, the blue P.
	_cp_lw(14.2, 0.0, 24.2, 0.0, g, g + 3.6, west, Color("#1b1c20"), M_STONE, 0.13)
	_cp_lw(14.2, 0.0, 24.2, 0.0, g + 3.55, g + 3.67, west, Color(1.0, 0.2, 0.62), M_LAMP, 0.15)
	_cp_lw(14.2, 0.0, 24.2, 0.0, g + 3.67, g + CP_GH, west, Color("#8d897f"), M_STONE, 0.14)
	for s in 9:
		_lbox(14.6 + 0.8 * s, 1.7, 0.4, 0.07, g + 1.1, g + 1.24, Color("#c23a32") if s % 2 == 0 else CP_WHITE, M_STONE)
	_lbox(14.0, 1.7, 0.2, 0.2, g, g + 1.25, CP_ORANGE, M_STONE)
	_lbox(22.2, 1.7, 0.1, 0.1, g, g + 1.2, Color("#6e7378"), M_STONE)
	_lbox(25.2, 2.4, 0.05, 0.05, g, g + 2.6, Color("#6e7378"), M_STONE)
	_lbox(25.2, 2.4, 0.36, 0.03, g + 2.15, g + 2.95, Color("#1d4fa0"), M_STONE)
	var pat := _w(25.2, 2.4) + _b * 0.04
	signs.append(["P", Vector3(pat.x, g + 2.2, pat.y), Vector3(_b.x, 0.0, _b.y), 0.3, Color(1, 1, 1)])
	# The shops down Parkingowa: three lit units, then a plain run with a roller door.
	var tones := [0.0, 0.5, 0.375]
	var boards := [Color("#d9cfa8"), Color("#bfc7cc"), Color("#c9a0b8")]
	for s in 3:
		var u0 := 25.5 + 12.2 * s
		_cp_lw(u0, 0.0, u0 + 11.4, 0.0, g + 0.5, g + 3.2, west, Color("#3b454d"), M_PAVILION + tones[s], 0.12)
		_cp_lw(u0, 0.0, u0 + 11.4, 0.0, g + 3.2, g + CP_GH, west, boards[s], M_STONE, 0.14)
		_cp_lw(u0 + 5.6, 0.0, u0 + 5.8, 0.0, g + 0.5, g + 3.2, west, CP_DARK, M_STONE, 0.17)
	_cp_lw(70.0, 0.0, 76.0, 0.0, g, g + 3.2, west, Color("#5b5f63"), M_STONE, 0.1)
	# The poster boards along the Nowogrodzka foot: 1.15 m sheets, a hand's gap between.
	var v := -11.0
	var p := 0
	while v > -35.4:
		_cp_lw(0.0, v, 0.0, v - 1.15, g + 0.8, g + 3.0, north, CP_POSTERS[p % CP_POSTERS.size()] if _cp_hash(float(p), 1.0) < 0.7 else CP_POSTERS[(p * 3) % CP_POSTERS.size()], M_STONE, 0.1)
		v -= 1.4
		p += 1


## The corrugated wall of the next block on Nowogrodzka, its parody wordmark and the mural's red
## head climbing it from the car park's side, and the posters along its foot.
func _cp_wall_panel(g: float) -> void:
	var a := CP_WALL_A
	var b := CP_WALL_B
	var ln := a.distance_to(b)
	var e := (b - a) / ln
	var out := Vector2(e.y, -e.x)
	var gw: float = map.terrain_height(a.x, a.y)
	var n := ceili(ln / 0.55)
	_mode = M_MEMBRANE + 0.5
	for j in n:
		var t0 := ln * float(j) / n
		var t1 := ln * float(j + 1) / n
		var tm := (t0 + t1) * 0.5
		var pa := a + e * t0 + out * 0.25
		var pb := a + e * t1 + out * 0.25
		var white := Color("#e6e8e9") if j % 2 == 0 else Color("#d8dbdc")
		var red := 0.0
		if tm < ln * 0.42:
			red = 15.0 * pow(1.0 - tm / (ln * 0.42), 0.55)
		if red > 0.5:
			var rc := Color("#c4472f") if j % 2 == 0 else Color("#a83a2c")
			_wall(pa, pb, gw, gw + red, out, rc)
			_wall(pa, pb, gw + red, gw + CP_WALL_H, out, white)
		else:
			_wall(pa, pb, gw, gw + CP_WALL_H, out, white)
	# Posters along the foot, continuing the car park's row.
	var t := 0.6
	var q := 0
	while t < ln - 1.2:
		var pa2 := a + e * t + out * 0.3
		var pb2 := a + e * (t + 1.15) + out * 0.3
		_wall(pa2, pb2, gw + 0.8, gw + 3.0, out, CP_POSTERS[(q * 2 + 1) % CP_POSTERS.size()])
		t += 1.4
		q += 1
	# The wordmark (KOLORKI) in navy pixels, a rainbow swoosh over it; read from the north, west on the right.
	var org := a + e * (ln * 0.94) + out * 0.28
	var base_y := gw + 8.6
	var px := 0.26
	var cursor := 0.0
	for ch in "KOLORKI":
		var rows: Array = Neon.FONT[ch]
		for gy in 7:
			var line: String = rows[gy]
			var gx := 0
			while gx < 5:
				if line[gx] == "#":
					var gx2 := gx
					while gx2 + 1 < 5 and line[gx2 + 1] == "#":
						gx2 += 1
					_wall(org - e * (cursor + gx * px), org - e * (cursor + (gx2 + 1) * px), base_y + (6 - gy) * px, base_y + (7 - gy) * px, out, CP_NAVY)
					gx = gx2 + 1
				else:
					gx += 1
		cursor += 6.0 * px
	var rainbow := [Color("#d94a3a"), Color("#e8963a"), Color("#e8d04a"), Color("#6fbf5a"), Color("#4a8fd0"), Color("#7a58b8")]
	for s in rainbow.size():
		var sx := 0.3 + s * 0.85
		var sy := base_y + 2.35 + sin(float(s) * 0.55) * 0.55
		_wall(org - e * sx, org - e * (sx + 0.7), sy, sy + 0.34, out, rainbow[s])


# --- Próżna and Plac Grzybowski (F's photos, 2026-11-08) ---------------------------------------

## Próżna, the one-way street of 1900s tenements between Plac Grzybowski and Marszałkowska, from F's
## photos (refs/prozna, docs/landmarks/photo-reports/prozna.md): the south side's two cream
## tenements (Próżna 9 and its neighbour: a rusticated ground floor of round arches over dark
## lattice glass, three floors of tall windows with pediment hoods and stone-balustrade balconies on
## the first, an attic of small arched windows, a heavy cornice), the two kerbs' graphite bollards
## every 4 m and the café planters. The road is granite setts and the pavements grey slabs
## (ground.gdshader PZ_*). The mass stays LoD2's, in its plaster; the north side's brick Próżna 14 is
## the photo front `b1399` (game/data/photo_fronts.json).
const PZ_LINE := [Vector2(-1371.1, -239.4), Vector2(-1361.0, -243.6), Vector2(-1279.1, -277.2),
		Vector2(-1217.2, -302.4), Vector2(-1215.1, -303.3), Vector2(-1208.1, -306.1)]
## The two south tenements' street fronts, east end to west end (the outside, the street, on the frame's +v).
const PZ_FRONTS := [[Vector2(-1317.9, -254.6), Vector2(-1356.3, -238.6), 11],
		[Vector2(-1281.8, -269.4), Vector2(-1317.9, -254.6), 10]]
const PZ_WALL := Color("#f1ecdf")       ## the 2013 restoration: near-white plaster (F-IMG_7533, 7534)
const PZ_BASE := Color("#e0d3b4")       ## the rusticated ground floor, buff
const PZ_TRIM := Color("#f2ecd8")       ## frames, hoods, balustrades
const PZ_GLOW := Color("#ffc36b")        ## the amber uplights under the hoods and balcony slabs (F-IMG_7534)
const PZ_GLASS := Color("#2b2522")      ## the dark lattice glazing of the arches (photo 3)
const PZ_PANE := Color("#35404a")
const PZ_ZINC := Color("#58595c")
const PZ_BOLLARD := Color("#3d3f43")    ## graphite posts with a pale cap (photos 1, 3)
const PZ_STOREY := 3.35   ## the photo front the street block measured put the eave at 17.7 m
const PZ_GF := 4.6
const PZ_ATTIC := 2.6


func _find_prozna() -> void:
	var one := _tallest_at(Vector2(-1334.0, -243.0))
	var two := _tallest_at(Vector2(-1300.0, -252.0))
	if one.size() >= 3 and two.size() >= 3:
		_add_site("prozna", [one, two])
		sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": PZ_WALL, "roof": PZ_ZINC}
		sites[-1]["quiet"] = true
	# The square's water garden, its terraces and benches: a small zone over the open ground.
	_add_site("plac_grzybowski", [PackedVector2Array([Vector2(-1436.0, -240.0), Vector2(-1392.0, -240.0),
			Vector2(-1392.0, -176.0), Vector2(-1436.0, -176.0)])])
	if not sites.is_empty() and sites[-1]["key"] == "plac_grzybowski":
		sites[-1]["quiet"] = true


## The point `dist` m along Próżna's centreline, with the street's direction there.
func _pz_at(dist: float) -> Array:
	var rest := dist
	for i in PZ_LINE.size() - 1:
		var a: Vector2 = PZ_LINE[i]
		var b: Vector2 = PZ_LINE[i + 1]
		var l := a.distance_to(b)
		if rest <= l:
			var d := (b - a) / l
			return [a + d * rest, d]
		rest -= l
	var last: Vector2 = PZ_LINE[PZ_LINE.size() - 1]
	return [last, Vector2.RIGHT]


func _build_prozna(site: Dictionary) -> void:
	_g = _ground_under(site["zone"][0])
	for f: Array in PZ_FRONTS:
		_pz_front(f[0], f[1], int(f[2]))
	_pz_bollards()
	_pz_planters()


## One tenement front in the photos' order: a rusticated ground floor of round arches (three
## stepped boxes make each arch's head), a string course, three floors of tall windows, pediment
## hoods and balustraded balconies on the first, an attic of small arched windows, the cornice.
func _pz_front(from: Vector2, to: Vector2, bays: int) -> void:
	_o = from
	_a = (to - from).normalized()
	_b = Vector2(-_a.y, _a.x)  # out of the front, into the street
	var width := from.distance_to(to)
	var mid := width * 0.5
	var bay := width / bays
	var g := _ground_under(PackedVector2Array([from, to, from + _b * 4.0, to + _b * 4.0]))
	var top := PZ_GF + 3.0 * PZ_STOREY + PZ_ATTIC
	_lbox(mid, 0.1, mid, 0.14, g - 0.3, g + PZ_GF, PZ_BASE)
	_lbox(mid, 0.1, mid, 0.14, g + PZ_GF, g + top, PZ_WALL)
	_lbox(mid, 0.3, mid, 0.1, g + PZ_GF - 0.45, g + PZ_GF + 0.15, PZ_TRIM)
	for k in bays + 1:  # the piers of the arcade
		_lbox(k * bay, 0.26, 0.32, 0.12, g, g + PZ_GF - 0.5, PZ_BASE.lightened(0.05))
	for k in bays:
		var u := (k + 0.5) * bay
		var w := bay * 0.5 - 0.35
		_lbox(u, 0.24, w, 0.03, g + 0.25, g + PZ_GF - 1.1, PZ_GLASS, _lit(u, 1.0))
		_lbox(u, 0.24, w * 0.86, 0.03, g + PZ_GF - 1.1, g + PZ_GF - 0.8, PZ_GLASS)
		_lbox(u, 0.24, w * 0.55, 0.03, g + PZ_GF - 0.8, g + PZ_GF - 0.55, PZ_GLASS)
		_lbox(u, 0.2, w + 0.3, 0.05, g + PZ_GF - 0.55, g + PZ_GF - 0.4, PZ_TRIM)
		for i in 3:  # the upper floors
			var y := g + PZ_GF + 0.55 + i * PZ_STOREY
			_lbox(u, 0.22, 0.55, 0.03, y, y + 2.1, PZ_PANE, _lit(u, y))
			_lbox(u, 0.26, 0.78, 0.07, y - 0.15, y - 0.03, PZ_TRIM)  # the sill
			_lbox(u, 0.28, 0.72, 0.1, y + 2.1, y + 2.45, PZ_TRIM)    # the hood
		# the first floor's balcony on every third bay (F-IMG_7534): a slab on brackets, a balustrade, its
		# amber uplight at night (M_LAMP strip under the slab)
		var by := g + PZ_GF + 0.4
		if k % 3 == 1:
			_lbox(u, 0.7, bay * 0.4, 0.5, by - 0.28, by, PZ_TRIM)
			_lbox(u, 1.1, bay * 0.4, 0.05, by, by + 0.85, PZ_TRIM.darkened(0.04))
			_lbox(u - bay * 0.4, 0.7, 0.07, 0.4, by, by + 0.85, PZ_TRIM)
			_lbox(u + bay * 0.4, 0.7, 0.07, 0.4, by, by + 0.85, PZ_TRIM)
			_lbox(u, 0.5, bay * 0.36, 0.1, by - 0.36, by - 0.28, PZ_GLOW, M_LAMP)
		# the hoods' uplights on floors 1 and 2 (the lit window heads)
		for i in 2:
			var hy := g + PZ_GF + 0.55 + i * PZ_STOREY + 2.1
			_lbox(u, 0.3, 0.6, 0.06, hy - 0.06, hy + 0.04, PZ_GLOW, M_LAMP)
		# the attic's arched window
		var ay := g + PZ_GF + 3.0 * PZ_STOREY + 0.5
		_lbox(u, 0.22, 0.4, 0.03, ay, ay + 1.5, PZ_PANE, _lit(u, ay))
		_lbox(u, 0.22, 0.25, 0.03, ay + 1.5, ay + 1.8, PZ_PANE)
	for i in 3:  # the string courses between the floors
		var cy := g + PZ_GF + 0.45 + i * PZ_STOREY - 0.7
		_lbox(mid, 0.2, mid, 0.07, cy, cy + 0.22, PZ_TRIM)
	_lbox(mid, 0.55, mid + 0.25, 0.4, g + top - 0.85, g + top, PZ_TRIM)  # the cornice
	_lbox(mid, 0.2, mid, 0.06, g + top, g + top + 0.5, PZ_TRIM.darkened(0.06))


## Graphite bollards along both kerbs every 4 m, the first and last 12 m from the junctions.
func _pz_bollards() -> void:
	var total := 0.0
	for i in PZ_LINE.size() - 1:
		total += (PZ_LINE[i] as Vector2).distance_to(PZ_LINE[i + 1])
	var d := 14.0
	while d < total - 12.0:
		var at: Array = _pz_at(d)
		var c: Vector2 = at[0]
		var dir: Vector2 = at[1]
		var side := Vector2(-dir.y, dir.x)
		for sg: float in [-1.0, 1.0]:
			var p := c + side * sg * 3.75
			var y: float = map.terrain_height(p.x, p.y)
			_prism(_square(p, 0.09), y - 0.1, y + 0.9, PZ_BOLLARD, PZ_BOLLARD.lightened(0.5), M_STONE, M_STONE)
		d += 4.2


## Café planters: long black troughs with a clipped hedge in front of the north side's ground floors
## (Próżna 12, photo 4) and white pots at the south arcade's corner (photo 2).
func _pz_planters() -> void:
	for seg: Array in [[Vector2(-1318.0, -262.0), Vector2(-1304.0, -268.0)], [Vector2(-1356.0, -243.5), Vector2(-1346.0, -247.5)]]:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var dir := (b - a).normalized()
		var side := Vector2(-dir.y, dir.x)
		var y: float = map.terrain_height(a.x, a.y)
		_prism(PackedVector2Array([a, b, b + side * 0.6, a + side * 0.6]), y - 0.1, y + 0.7, Color("#25272a"), Color("#4d7a3f"), M_STONE, M_STONE)


# --- Plac Grzybowski's water garden (Plac Grzybowski, 2013 refurbishment) ---------------------------

const PG_GRANITE := Color("#9c9a95")
const PG_DARK := Color("#46484b")
const PG_TIMBER := Color("#6a3a2a")      ## the decks and the benches' slats (photos D04, D01)
const PG_POND := Vector2(-1411.5, -215.5)


func _build_plac_grzybowski(_site: Dictionary) -> void:
	_g = map.terrain_height(PG_POND.x, PG_POND.y)
	var g := _g
	# The cascade (F's photos 7521, 7524): a field of square granite blocks at different heights stepping
	# down to the water west of the pond, a narrow rill along its edge.
	for i in 8:
		for j in 6:
			var bx := -1432.0 + i * 1.6
			var bz := -229.0 + j * 4.2
			var bh := 0.12 + 0.55 * fposmod(sin(float(i) * 12.9898 + float(j) * 78.233) * 43758.5, 1.0) + 0.08 * (7 - i)
			_prism(PackedVector2Array([Vector2(bx, bz), Vector2(bx + 1.45, bz), Vector2(bx + 1.45, bz + 3.8), Vector2(bx, bz + 3.8)]),
					g - 0.2, g + bh, PG_GRANITE.darkened(0.12), PG_GRANITE.darkened(0.04), M_STONE, M_STONE)
	_prism(PackedVector2Array([Vector2(-1433.0, -204.2), Vector2(-1419.0, -204.2), Vector2(-1419.0, -203.8), Vector2(-1433.0, -203.8)]),
			g + 0.0, g + 0.04, Color("#4a6a73"), Color("#4a6a73"), M_STONE, M_STONE)
	# The timber decks floating over the pond's edge, and the stepping stones.
	for r: Array in [[-1415.0, -226.0, 6.5, 1.1], [-1413.0, -223.0, 6.0, 1.1], [-1412.0, -219.0, 6.5, 1.1], [-1414.0, -208.0, 5.0, 1.0]]:
		var q := Vector2(r[0], r[1])
		_prism(PackedVector2Array([q, q + Vector2(r[2], 0), q + Vector2(r[2], r[3]), q + Vector2(0, r[3])]),
				g + 0.02, g + 0.14, PG_TIMBER, PG_TIMBER.lightened(0.08), M_STONE, M_STONE)
	# The memorial stone (1904 demonstration): a rough dark block on a low plinth by the walk.
	var ks := Vector2(-1424.0, -197.0)
	_prism(_square(ks, 0.9), g - 0.1, g + 0.25, PG_GRANITE, PG_GRANITE, M_STONE, M_STONE)
	_prism(PackedVector2Array([ks + Vector2(-0.6, -0.4), ks + Vector2(0.6, -0.5), ks + Vector2(0.7, 0.4), ks + Vector2(-0.5, 0.5)]),
			g + 0.25, g + 1.3, PG_DARK, PG_DARK.lightened(0.1), M_STONE, M_STONE)
	# Benches: timber slats on two grey end blocks, along the walk east of the water.
	for p: Vector2 in [Vector2(-1405.0, -228.0), Vector2(-1405.0, -222.0), Vector2(-1405.0, -210.0), Vector2(-1405.0, -204.0),
			Vector2(-1420.0, -190.0), Vector2(-1414.0, -190.0), Vector2(-1408.0, -190.0), Vector2(-1426.0, -236.0)]:
		var by: float = map.terrain_height(p.x, p.y)
		_prism(PackedVector2Array([p + Vector2(-0.45, -0.9), p + Vector2(0.45, -0.9), p + Vector2(0.45, 0.9), p + Vector2(-0.45, 0.9)]),
				by + 0.35, by + 0.5, PG_TIMBER, PG_TIMBER.lightened(0.1), M_STONE, M_STONE)
		for sy: float in [-0.75, 0.75]:
			_prism(PackedVector2Array([p + Vector2(-0.4, sy - 0.08), p + Vector2(0.4, sy - 0.08), p + Vector2(0.4, sy + 0.08), p + Vector2(-0.4, sy + 0.08)]),
					by, by + 0.35, PG_GRANITE, PG_GRANITE, M_STONE, M_STONE)
	# The planter wall (photo 7526): a long concave arc of low black granite along the road edge, meadow bed inside.
	var prev := Vector2(-1436.0, -171.0)
	for k in range(1, 13):
		var t := float(k) / 12.0
		var q := Vector2(-1436.0 + 40.0 * t, -171.0 - 16.0 * sin(t * PI) * 0.0 + 9.0 * (1.0 - cos(t * PI)) * 0.5 * 0.0 - 6.0 * sin(t * PI))
		var wy2: float = map.terrain_height(q.x, q.y)
		var dir := (q - prev).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		_prism(PackedVector2Array([prev, q, q + nrm * 0.5, prev + nrm * 0.5]), wy2 - 0.1, wy2 + 0.55, Color("#2b2d30"), Color("#3a3d41"), M_STONE, M_STONE)
		prev = q
	# Lantern bollards along the walks: short square posts that glow at night (photo 7523).
	for q: Vector2 in [Vector2(-1426.0, -240.0), Vector2(-1426.0, -232.0), Vector2(-1426.0, -214.0), Vector2(-1426.0, -196.0),
			Vector2(-1400.0, -240.0), Vector2(-1400.0, -232.0), Vector2(-1400.0, -214.0), Vector2(-1400.0, -196.0), Vector2(-1413.0, -190.0), Vector2(-1405.0, -190.0)]:
		var ly: float = map.terrain_height(q.x, q.y)
		_prism(_square(q, 0.11), ly, ly + 0.7, Color("#3a3c40"), Color("#3a3c40"), M_STONE, M_STONE)
		_prism(_square(q, 0.09), ly + 0.7, ly + 0.9, Color("#ffd9a0"), Color("#ffd9a0"), M_LAMP, M_LAMP)
	# Rough granite block seats scattered on the paving (photos 7529, P05).
	for q: Vector2 in [Vector2(-1385.0, -214.0), Vector2(-1381.0, -208.0), Vector2(-1388.0, -204.0), Vector2(-1380.0, -222.0)]:
		var sy: float = map.terrain_height(q.x, q.y)
		_prism(PackedVector2Array([q + Vector2(-0.8, -0.5), q + Vector2(0.8, -0.4), q + Vector2(0.7, 0.5), q + Vector2(-0.7, 0.45)]),
				sy - 0.05, sy + 0.45, Color("#6f6a63"), Color("#7b756d"), M_STONE, M_STONE)
	# Charlotte Menora's corner (photo D08): the café under the white block on the square's east side, a
	# red awning and its name (the parody CHARLOTTA MENORKA) over the glass, tables under the trees.
	var out := Vector2(-0.93, 0.37)
	var along := Vector2(-0.37, -0.93)
	var at := Vector2(-1346.6, -216.0)
	var cy: float = map.terrain_height(at.x, at.y)
	var strip := PackedVector2Array([at - along * 4.5, at + along * 4.5, at + along * 4.5 + out * 1.6, at - along * 4.5 + out * 1.6])
	_prism(strip, cy + 3.1, cy + 3.4, Color("#b3262c"), Color("#c0332f"), M_STONE, M_STONE)
	for e: float in [-4.4, 4.4]:  # the awning's two posts
		var pp := at + along * e + out * 1.5
		var py: float = map.terrain_height(pp.x, pp.y)
		_prism(_square(pp, 0.06), py, cy + 3.1, Color("#2d2a28"), Color("#2d2a28"), M_STONE, M_STONE)
	var word := "CHARLOTTA MENORKA"
	var k := minf(0.85 * (9.0 - 0.5) / Neon.length_of(word), 0.6 * 0.9 / (Neon.ROW_H * Neon.PIXEL))
	var rh := Neon.ROW_H * Neon.PIXEL * k
	var sp := at + out * 0.25
	signs.append([word, Vector3(sp.x, cy + 3.6 + 0.45 - 0.5 * rh, sp.y), Vector3(out.x, 0.0, out.y), k, Color(1.0, 0.93, 0.85)])
	for t in 4:
		var tp := at + out * 3.2 + along * (t * 2.6 - 3.9)
		var ty: float = map.terrain_height(tp.x, tp.y)
		_prism(_square(tp, 0.4), ty + 0.72, ty + 0.78, Color("#2d2a28"), Color("#3b3733"), M_STONE, M_STONE)
		_prism(_square(tp, 0.07), ty, ty + 0.72, Color("#2d2a28"), Color("#2d2a28"), M_STONE, M_STONE)
		for q: Vector2 in [Vector2(0.65, 0.0), Vector2(-0.65, 0.0), Vector2(0.0, 0.65), Vector2(0.0, -0.65)]:
			_prism(_square(tp + q, 0.22), ty, ty + 0.5, Color("#c9a870"), Color("#d6b982"), M_STONE, M_STONE)


# --- Gmach Główny Politechniki Warszawskiej (Plac Politechniki) ---------------------------------

## The University of Technology's main building (1899-1901, Stefan Szyller), from F's five photos
## (refs/_f/warsaw-needed-photos/top-50/T20, 2026-11-13; spec docs/landmarks/specs/politechnika.md).
## The mass is LoD2's, in cream plaster (SKINS "politechnika"; the Great Hall's glass roof keeps its
## own colour). LoD2 already has the front pavilion's plan on Plac Politechniki (east-south-east):
## a flat middle 17.5 m wide between two rounded wings, all to the 22.8 m eave. Its face is ours:
## the middle bay stands 0.6 m proud in plain stone, its three tall arched windows over three arched
## doors between paired giant columns under an entablature, a balcony; over the eave an attic with
## the name's plaque, two urn-topped pylons and the sculpture group (a standing figure with a raised
## torch between two seated ones); three steps, the round basin and two tall lamp posts in front.
## The frame: v out of the flat face (LoD2's wall normal), u along it, from its middle.
const PW_MID := Vector2(-901.85, 1501.7)
const PW_OUT := Vector2(0.902, 0.431)
const PW_HALF := 8.75          ## half the flat middle's width (LoD2's wall, -898.1,1493.8 to -905.6,1509.6)
const PW_EAVE := 22.8          ## LoD2's eave over the ground there
const PW_WALL := Color("#ece6d8")
const PW_BASE := Color("#ddd6c6")
const PW_WHITE := Color("#f4f1e9")
const PW_GLASS := Color("#2c333a")
const PW_DOOR := Color("#5b3a2a")
const PW_STATUE := Color("#d3cec4")
const PW_LAMP := Color("#5a5048")      ## the dark stone of the lamp pillars
const PW_GLOBE := Color("#fbf3dc")     ## the white globes, lit at night


func _build_politechnika(_site: Dictionary) -> void:
	_b = PW_OUT.normalized()
	_a = Vector2(_b.y, -_b.x)
	_o = PW_MID
	_g = map.terrain_height(PW_MID.x, PW_MID.y)
	var g := _g
	var e := PW_EAVE
	var hw := PW_HALF
	# The middle bay, proud of LoD2's wall: plain stone over a rusticated base.
	var face := 0.6
	_lbox(0.0, face * 0.5, hw, face * 0.5, g - 0.5, g + e - 1.4, PW_WALL, M_STONE)
	_lbox(0.0, face * 0.5 + 0.02, hw + 0.02, face * 0.5 + 0.02, g - 0.5, g + 7.2, PW_BASE, M_STONE)
	_lbox(0.0, face * 0.5 + 0.1, hw + 0.1, face * 0.5 + 0.1, g + 7.0, g + 7.5, PW_WHITE, M_STONE, PW_WHITE)
	for u: float in [-4.4, 0.0, 4.4]:
		_arch_win(_w(u, face), -_a, _b, 1.35, g + 9.2, g + 16.2, PW_GLASS)
		_arch_win(_w(u, face + 0.04), -_a, _b, 1.15, g + 0.6, g + 4.4, PW_DOOR)
	for u: float in [-7.3, -6.5, -2.6, -1.8, 1.8, 2.6, 6.5, 7.3]:
		_column(u, face + 0.45, 0.36, g + 7.5, g + e - 2.2, PW_WHITE)
	# The entablature and the cornice over the columns, the balcony under the windows.
	_lbox(0.0, face * 0.5 + 0.45, hw + 0.4, face * 0.5 + 0.45, g + e - 2.2, g + e - 1.4, PW_WHITE, M_STONE, PW_WHITE)
	_lbox(0.0, face * 0.5 + 0.7, hw + 0.7, face * 0.5 + 0.7, g + e - 1.4, g + e - 0.4, PW_WHITE, M_STONE, PW_WHITE)
	_soffit(_rect(0.0, face * 0.5 + 0.7, hw + 0.7, face * 0.5 + 0.7), g + e - 1.4, PW_WHITE.darkened(0.15))
	_lbox(0.0, face + 0.45, 6.0, 0.45, g + 8.3, g + 8.8, PW_WHITE, M_STONE, PW_WHITE)
	# The attic over the middle, on the cornice: the name's plaque, its own cornice, two pylons
	# with urns, the sculpture group on a pedestal.
	_lbox(0.0, face - 1.0, hw - 0.4, 1.5, g + e - 0.4, g + e + 4.4, PW_WALL, M_STONE, PW_WHITE)
	_lbox(0.0, face + 0.52, 4.2, 0.03, g + e + 1.0, g + e + 2.8, PW_BASE.darkened(0.05), M_STONE)
	_lbox(0.0, face - 1.0, hw - 0.1, 1.8, g + e + 4.4, g + e + 5.0, PW_WHITE, M_STONE, PW_WHITE)
	for sd: float in [-1.0, 1.0]:
		var pu := sd * (hw - 1.2)
		_lbox(pu, face - 0.6, 1.1, 1.1, g + e + 5.0, g + e + 6.6, PW_WALL, M_STONE, PW_WHITE)
		_prism(_circle(_w(pu, face - 0.6), 0.55, 8), g + e + 6.6, g + e + 8.0, PW_WHITE, PW_WHITE, M_STONE, M_STONE)
	_lbox(0.0, face - 0.9, 3.2, 1.3, g + e + 5.0, g + e + 6.2, PW_WHITE, M_STONE, PW_WHITE)
	var fig := _w(0.0, face - 0.9)
	_prism(_circle(fig, 0.7, 6), g + e + 6.2, g + e + 10.6, PW_STATUE, PW_STATUE, M_STONE, M_STONE)
	_prism(_circle(fig, 0.42, 6), g + e + 10.6, g + e + 11.4, PW_STATUE, PW_STATUE, M_STONE, M_STONE)
	var sh := _w(0.35, face - 0.9)
	var hand := _w(0.8, face - 0.6)
	_beam(Vector3(sh.x, g + e + 10.2, sh.y), Vector3(hand.x, g + e + 13.2, hand.y), 0.28, PW_STATUE)
	for sd: float in [-1.0, 1.0]:
		_prism(_circle(_w(sd * 2.0, face - 0.7), 0.75, 6), g + e + 6.2, g + e + 8.4, PW_STATUE, PW_STATUE, M_STONE, M_STONE)
	# Three steps up to the doors, held by a low curved stone kerb with a ball at each end, and
	# the two dark stone pillars on the stair cheeks with their clusters of white globes.
	for k in 3:
		var d := 0.45 * (3 - k)
		_lbox(0.0, face + d * 0.5, hw - 0.4 - k * 0.4, d * 0.5, g - 0.4, g + 0.2 + k * 0.2,
				PW_BASE.darkened(0.1), M_STONE, PW_BASE.darkened(0.05))
	var kerb := PW_BASE.darkened(0.12)
	var n := 8
	for i in n:
		var t0 := PI * float(i) / float(n)
		var t1 := PI * float(i + 1) / float(n)
		var q := PackedVector2Array([
			_w(-cos(t0) * 6.6, face + sin(t0) * 4.6), _w(-cos(t1) * 6.6, face + sin(t1) * 4.6),
			_w(-cos(t1) * 6.2, face + sin(t1) * 4.25), _w(-cos(t0) * 6.2, face + sin(t0) * 4.25)])
		_prism(q, g - 0.3, g + 0.75, kerb, kerb.lightened(0.05), M_STONE, M_STONE)
	for sd: float in [-1.0, 1.0]:
		var bp := _w(sd * 6.4, face + 0.3)
		_lbox(sd * 6.4, face + 0.3, 0.3, 0.3, g - 0.3, g + 1.0, kerb, M_STONE, kerb)
		_prism(_circle(bp, 0.28, 6), g + 1.0, g + 1.5, kerb, kerb, M_STONE, M_STONE)
	for sd: float in [-1.0, 1.0]:
		var pu := sd * 2.2
		_lbox(pu, face + 1.0, 0.35, 0.35, g - 0.3, g + 4.6, PW_LAMP, M_STONE, PW_LAMP)
		_prism(_circle(_w(pu, face + 1.0), 0.75, 6), g + 4.6, g + 5.3, PW_GLOBE, PW_GLOBE, M_LAMP, M_LAMP)
		_prism(_circle(_w(pu, face + 1.0), 0.3, 6), g + 5.3, g + 6.0, PW_GLOBE, PW_GLOBE, M_LAMP, M_LAMP)
	_collide(_rect(0.0, face * 0.5, hw, face * 0.5))


# --- THE TAPCZAN, the craft-beer pub on Sienkiewicza 4 (F's photos, 2026-11-24) -------------------
# Spec docs/landmarks/specs/tapczan.md. A parody of the real pub's name (a "tapczan" is a sofa bed:
# the pub you end up sleeping on); the real name is in data/brand_denylist.json. The house is
# LoD2's and stays; this site dresses its street level and puts the summer terrace on the pavement.

## The front of Sienkiewicza 4 on the street (OpenStreetMap's outline, west corner to east), and
## where the pub's street level runs along it (u from the west corner, m).
const TPZ_FRONT_A := Vector2(-789.1, -46.2)
const TPZ_FRONT_B := Vector2(-763.1, -56.4)
const TPZ_U0 := 0.4
const TPZ_U1 := 12.8
## The terrace (pallet deck) on the pavement: u along the front, v out of it; the kerb of the
## carriageway stands at v ~6.5 (Sienkiewicza's centreline at v 10, 7 m wide).
const TPZ_DECK := Rect2(0.3, 2.0, 12.4, 4.1)
const TPZ_DECK_H := 0.16
const TPZ_GF := 4.3          # the street level's height (the ledge over the glazing)
const TPZ_CREAM := Color("#ece7db")    # the house's cream (SK4_CREAM)
const TPZ_LEDGE := Color("#f5f2ea")
const TPZ_STONE := Color("#8e8b84")
const TPZ_STONE_D := Color("#6f6c66")
const TPZ_FRAME := Color("#5c6166")
const TPZ_GLASS := Color("#2c3338")
const TPZ_VENT := Color("#c9ccce")
const TPZ_BLACK := Color("#18181a")
const TPZ_GOLD := Color("#c9a45a")
const TPZ_NEON := Color(1.0, 0.8, 0.42)
const TPZ_PINE := Color("#e2c591")
const TPZ_PINE_D := Color("#b99a66")
const TPZ_TABLE := Color("#8a6a48")
const TPZ_CHAIR := Color("#202124")
const TPZ_UMB := Color("#2a2b30")
const TPZ_LEAF := Color("#5f8f3a")
const TPZ_LEAF_D := Color("#467a2c")
const TPZ_HERB := Color("#6fae45")
## The two square umbrellas: centre u, v, half size, the canopy's rim and apex over the deck.
const TPZ_UMBRELLAS := [[3.4, 3.9, 1.9], [9.5, 3.9, 1.9]]
const TPZ_UMB_RIM := 2.35
const TPZ_UMB_APEX := 3.0
## The tables: two rows along the front, [u, v]; four chairs round each, folding, black.
const TPZ_TABLES := [[1.6, 3.0], [4.3, 3.0], [7.1, 3.0], [10.2, 3.0],
		[2.6, 4.7], [5.6, 4.7], [8.4, 4.7]]
## The parody on the umbrellas' valances (the real ones carry a cola maker's script).
const TPZ_UMB_WORD := "KOLKA-KOLA"


func _find_tapczan() -> void:
	var a := (TPZ_FRONT_B - TPZ_FRONT_A).normalized()
	var b := Vector2(-a.y, a.x)
	var at := func(u: float, v: float) -> Vector2: return TPZ_FRONT_A + a * u + b * v
	var zone := PackedVector2Array([at.call(-0.2, -0.7), at.call(13.2, -0.7), at.call(13.2, 6.4), at.call(-0.2, 6.4)])
	_add_site("tapczan", [zone])


## The frame on the front: u east along it from the west corner, v out to the street.
func _tpz_frame() -> void:
	_o = TPZ_FRONT_A
	_a = (TPZ_FRONT_B - TPZ_FRONT_A).normalized()
	_b = Vector2(-_a.y, _a.x)


## A thin bar between two points (a leg, a brace), drawn as a slim box: square section `r`.
func _tpz_bar(p0: Vector3, p1: Vector3, r: float, col: Color) -> void:
	var d := p1 - p0
	if d.length() < 0.01:
		return
	var side := d.cross(Vector3.UP)
	if side.length() < 0.001:
		side = Vector3(_a.x, 0.0, _a.y)
	side = side.normalized() * r
	var up := side.cross(d).normalized() * r
	var c := [p0 - side - up, p0 + side - up, p0 + side + up, p0 - side + up]
	var e := [p1 - side - up, p1 + side - up, p1 + side + up, p1 - side + up]
	_mode = M_STONE
	for k in 4:
		var q0: Vector3 = c[k]
		var q1: Vector3 = c[(k + 1) % 4]
		var mid := (q0 + q1) * 0.5 - p0
		var n := (mid - d * (mid.dot(d) / d.length_squared())).normalized()
		_quad(q0, q1, e[(k + 1) % 4], e[k], n, col)


## A rough carved stone panel on the wall (the Art Deco reliefs between the bays): a flat slab
## and a field of chiselled bumps in two greys, set from a seed so it stays put.
func _tpz_relief(u0: float, u1: float, y0: float, y1: float, seed: float) -> void:
	_ubox(u0, u1, 0.02, 0.1, y0, y1, TPZ_STONE, M_STONE, TPZ_STONE)
	var cols := maxi(2, roundi((u1 - u0) / 0.32))
	var rows := maxi(2, roundi((y1 - y0) / 0.3))
	var du := (u1 - u0 - 0.12) / cols
	var dy := (y1 - y0 - 0.12) / rows
	for i in cols:
		for j in rows:
			var h := fposmod(sin(seed * 7.1 + i * 12.9898 + j * 78.233) * 43758.5453, 1.0)
			if h < 0.3:
				continue
			var cu := u0 + 0.06 + (i + 0.5) * du + (h - 0.5) * 0.08
			var cy := y0 + 0.06 + (j + 0.5) * dy
			var col := TPZ_STONE_D if h > 0.7 else TPZ_STONE.lightened(0.08)
			_ubox(cu - du * 0.36, cu + du * 0.36, 0.1, 0.13 + 0.05 * h, cy - dy * 0.34, cy + dy * 0.34, col, M_STONE, col)


## One glazed bay of the street level: a grey frame, the glass (warm inside at night), a transom of
## louvred vents over it; `open` leaves the doors folded back on the dark bar inside.
func _tpz_bay(u0: float, u1: float, g: float, open: bool) -> void:
	var top := g + TPZ_GF - 0.35
	var tr := top - 0.75
	_ubox(u0, u1, -0.25, 0.02, g, top, TPZ_FRAME, M_STONE, TPZ_FRAME)   # the reveal and frame
	if open:
		_ubox(u0 + 0.1, u1 - 0.1, 0.02, 0.04, g + 0.02, tr - 0.08, Color("#1d1a18"), M_PAVILION)
		for s: float in [u0 + 0.22, u1 - 0.22]:   # the folded doors' edges
			_ubox(s - 0.08, s + 0.08, 0.02, 0.5, g + 0.02, tr - 0.08, TPZ_FRAME.darkened(0.2))
	else:
		_ubox(u0 + 0.1, u1 - 0.1, 0.02, 0.04, g + 0.08, tr - 0.08, TPZ_GLASS, M_PAVILION)
		var m := (u0 + u1) * 0.5
		_ubox(m - 0.04, m + 0.04, 0.04, 0.08, g + 0.08, tr - 0.08, TPZ_FRAME)
	_ubox(u0 + 0.05, u1 - 0.05, 0.02, 0.09, tr - 0.08, tr, TPZ_FRAME)   # the transom bar
	var vents := 2
	var vw := (u1 - u0 - 0.3) / vents
	for k in vents:
		var vu := u0 + 0.15 + vw * k
		_ubox(vu + 0.06, vu + vw - 0.06, 0.02, 0.05, tr + 0.08, top - 0.1, TPZ_VENT)
		for s in 4:
			var sy := tr + 0.14 + s * 0.12
			_ubox(vu + 0.1, vu + vw - 0.1, 0.05, 0.08, sy, sy + 0.04, TPZ_VENT.darkened(0.25))


## A black folding chair at (u, v), facing `face` (a local unit vector towards its table).
func _tpz_chair(u: float, v: float, face: Vector2, f: float) -> void:
	var fw := _a * face.x + _b * face.y
	var sd := Vector2(-fw.y, fw.x)
	var c := _w(u, v)
	var pt := func(s: float, t: float, y: float) -> Vector3:
		var p := c + sd * s + fw * t
		return Vector3(p.x, y, p.y)
	var seat_y := f + 0.45
	_mode = M_STONE
	var seat := PackedVector2Array([c + sd * -0.2 + fw * -0.19, c + sd * 0.2 + fw * -0.19, c + sd * 0.2 + fw * 0.2, c + sd * -0.2 + fw * 0.2])
	_prism(seat, seat_y - 0.03, seat_y, TPZ_CHAIR, TPZ_CHAIR.lightened(0.08), M_STONE, M_STONE)
	for s: float in [-0.18, 0.18]:
		_tpz_bar(pt.call(s, 0.2, f), pt.call(s, -0.24, seat_y + 0.42), 0.018, TPZ_CHAIR)   # back legs into the back
		_tpz_bar(pt.call(s, -0.18, f), pt.call(s, 0.16, seat_y), 0.016, TPZ_CHAIR)        # front legs, crossed
	var back := PackedVector2Array([c + sd * -0.19 + fw * -0.25, c + sd * 0.19 + fw * -0.25, c + sd * 0.19 + fw * -0.22, c + sd * -0.19 + fw * -0.22])
	_prism(back, seat_y + 0.2, seat_y + 0.4, TPZ_CHAIR, TPZ_CHAIR, M_STONE, M_STONE)


## A slatted folding table at (u, v) with its crossed legs and a pot of herbs.
func _tpz_table(u: float, v: float, f: float) -> void:
	var ty := f + 0.74
	for k in 4:
		var su := u - 0.33 + k * 0.22
		_ubox(su - 0.09, su + 0.09, v - 0.3, v + 0.3, ty - 0.035, ty, TPZ_TABLE, M_STONE, TPZ_TABLE.lightened(0.06))
	var leg := func(s: float, t: float, y: float) -> Vector3:
		var p := _w(u + s, v + t)
		return Vector3(p.x, y, p.y)
	for s: float in [-0.3, 0.3]:   # an X of legs on each end
		_tpz_bar(leg.call(s, -0.27, f), leg.call(s, 0.27, ty - 0.04), 0.022, TPZ_TABLE.darkened(0.15))
		_tpz_bar(leg.call(s, 0.27, f), leg.call(s, -0.27, ty - 0.04), 0.022, TPZ_TABLE.darkened(0.15))
	_ubox(u - 0.06, u + 0.06, v - 0.06, v + 0.06, ty, ty + 0.1, Color("#9a9b9d"))
	_ubox(u - 0.09, u + 0.09, v - 0.09, v + 0.09, ty + 0.1, ty + 0.2, TPZ_HERB, M_STONE, TPZ_HERB.lightened(0.1))
	for d: Vector2 in [Vector2(0, -0.62), Vector2(0, 0.62), Vector2(-0.58, 0), Vector2(0.58, 0)]:
		_tpz_chair(u + d.x, v + d.y, -d.normalized(), f)


## A square black market umbrella: the pole, the shallow four-sided canopy, its valance with the
## parody on the street side, and a cap.
func _tpz_umbrella(cu: float, cv: float, h: float, f: float) -> void:
	_ubox(cu - 0.04, cu + 0.04, cv - 0.04, cv + 0.04, f, f + TPZ_UMB_APEX + 0.15, Color("#3a3b3e"))
	_ubox(cu - 0.3, cu + 0.3, cv - 0.3, cv + 0.3, f, f + 0.06, Color("#3a3b3e"))   # the base plate
	var rim := f + TPZ_UMB_RIM
	_mode = M_STONE
	_pyramid(_urect(cu - h, cu + h, cv - h, cv + h), rim, f + TPZ_UMB_APEX, TPZ_UMB)
	_cap(_urect(cu - h + 0.02, cu + h - 0.02, cv - h + 0.02, cv + h - 0.02), rim - 0.01, TPZ_UMB.darkened(0.2))
	var drop := 0.26
	_ubox(cu - h, cu + h, cv + h - 0.02, cv + h, rim - drop, rim, TPZ_UMB)
	_ubox(cu - h, cu + h, cv - h, cv - h + 0.02, rim - drop, rim, TPZ_UMB)
	_ubox(cu - h, cu - h + 0.02, cv - h, cv + h, rim - drop, rim, TPZ_UMB)
	_ubox(cu + h - 0.02, cu + h, cv - h, cv + h, rim - drop, rim, TPZ_UMB)
	var pitch := 0.15
	var px := 0.045
	var w := TPZ_UMB_WORD.length() * pitch - (pitch - 3.0 * px)
	_sm_text(TPZ_UMB_WORD, cu - w * 0.5, cv + h + 0.012, rim - 0.04, px, 0.036, pitch, Color("#f4f4f2"))
	_ubox(cu - 0.07, cu + 0.07, cv - 0.07, cv + 0.07, f + TPZ_UMB_APEX + 0.1, f + TPZ_UMB_APEX + 0.22, TPZ_UMB)


## A crate of pine slats (the planters and the bench under its cushion).
func _tpz_crate(u0: float, u1: float, v0: float, v1: float, y0: float, y1: float) -> void:
	_ubox(u0, u1, v0, v1, y0, y1, TPZ_PINE, M_STONE, TPZ_PINE)
	var n := maxi(2, roundi((y1 - y0) / 0.15))
	for k in range(1, n):
		var y := y0 + (y1 - y0) * k / n
		_ubox(u0 - 0.01, u1 + 0.01, v0 - 0.01, v1 + 0.01, y - 0.012, y + 0.012, TPZ_PINE_D)


## A planter crate with its black liner and a small tree: a trunk and a few leafy clumps.
func _tpz_planter(cu: float, cv: float, f: float, tall: float) -> void:
	_tpz_crate(cu - 0.32, cu + 0.32, cv - 0.32, cv + 0.32, f, f + 0.75)
	_ubox(cu - 0.3, cu + 0.3, cv - 0.3, cv + 0.3, f + 0.75, f + 0.85, TPZ_BLACK, M_STONE, TPZ_BLACK.lightened(0.05))
	_ubox(cu - 0.035, cu + 0.035, cv - 0.035, cv + 0.035, f + 0.85, f + tall - 0.5, Color("#6b5a48"))
	var clumps := [[0.0, 0.0, 0.0, 0.42], [-0.28, 0.1, -0.35, 0.3], [0.26, -0.12, -0.25, 0.32], [0.05, 0.25, 0.3, 0.28]]
	for c: Array in clumps:
		var y: float = f + tall - 0.5 + float(c[2])
		var r: float = c[3]
		var col := TPZ_LEAF if float(c[0]) >= 0.0 else TPZ_LEAF_D
		_ubox(cu + c[0] - r, cu + c[0] + r, cv + c[1] - r, cv + c[1] + r, y - r * 0.6, y + r * 0.8, col, M_STONE, col.lightened(0.08))


func _build_tapczan(_site: Dictionary) -> void:
	_tpz_frame()
	var deck := _urect(TPZ_DECK.position.x, TPZ_DECK.end.x, TPZ_DECK.position.y, TPZ_DECK.end.y)
	var g := _ground_under(_urect(TPZ_U0, TPZ_U1, -0.3, TPZ_DECK.end.y))
	_g = g
	# The street level: cream render, a grey plinth, the ledge, the two glazed bays and the piers
	# with their carved stone panels (a stack of three on the west pier).
	_ubox(TPZ_U0, TPZ_U1, -0.3, 0.0, g - 0.3, g + TPZ_GF, TPZ_CREAM, M_STONE, TPZ_CREAM)
	_ubox(TPZ_U0 - 0.05, TPZ_U1 + 0.05, 0.0, 0.05, g - 0.3, g + 0.25, TPZ_STONE.lightened(0.1))
	_ubox(TPZ_U0 - 0.1, TPZ_U1 + 0.1, -0.3, 0.22, g + TPZ_GF - 0.05, g + TPZ_GF + 0.2, TPZ_LEDGE, M_STONE, TPZ_LEDGE)
	_ubox(TPZ_U0 - 0.1, TPZ_U1 + 0.1, -0.3, 0.12, g + TPZ_GF - 0.32, g + TPZ_GF - 0.05, TPZ_CREAM.darkened(0.04))
	for k in 3:
		_tpz_relief(0.55, 1.6, g + 1.0 + k * 1.05, g + 1.95 + k * 1.05, 3.0 + k)
	_tpz_bay(1.75, 5.25, g, false)
	_tpz_relief(5.45, 7.35, g + 0.35, g + 1.35, 9.0)
	_tpz_bay(7.55, 11.05, g, true)
	_tpz_relief(11.25, 12.6, g + 1.6, g + 2.55, 11.0)
	_tpz_relief(11.25, 12.6, g + 0.35, g + 1.2, 12.0)
	# The sign: a black square on the middle pier, a gold bottle-cap ring and the name in gold neon.
	var sy := g + 2.55
	_ubox(5.65, 7.15, 0.05, 0.2, sy, sy + 1.45, TPZ_BLACK, M_STONE, TPZ_BLACK)
	var ring := _w(6.4, 0.23)
	var nrm := Vector3(_b.x, 0.0, _b.y)
	_disc(Vector3(ring.x, sy + 0.72, ring.y), nrm, 0.62, 20, TPZ_GOLD)
	var inner := _w(6.4, 0.255)
	_disc(Vector3(inner.x, sy + 0.72, inner.y), nrm, 0.55, 20, TPZ_BLACK)
	for k in 20:   # the cap's crimp: little gold teeth round the ring
		var t := TAU * (k + 0.5) / 20.0
		_lbox(6.4 + cos(t) * 0.655, 0.22, 0.03, 0.02, sy + 0.72 + sin(t) * 0.655 - 0.03, sy + 0.72 + sin(t) * 0.655 + 0.03, TPZ_GOLD)
	_usign("THE", 6.4, 0.29, sy + 0.98, _b, 0.4, 0.13, TPZ_NEON)
	_usign("TAPCZAN", 6.4, 0.29, sy + 0.62, _b, 1.0, 0.26, TPZ_NEON)
	_usign("CRAFT BEER", 6.4, 0.29, sy + 0.42, _b, 0.6, 0.08, TPZ_NEON)
	# The terrace: a deck of pallets (the dark gaps at the foot, boards on top).
	var f := g + TPZ_DECK_H
	_prism(deck, g - 0.15, f - 0.04, TPZ_PINE_D.darkened(0.25), TPZ_PINE_D, M_STONE, M_STONE)
	var boards := int(TPZ_DECK.size.y / 0.2)
	for k in boards:
		var v := TPZ_DECK.position.y + (k + 0.5) * TPZ_DECK.size.y / boards
		var tone := TPZ_PINE.darkened(0.06 * fposmod(k * 0.37, 1.0))
		_ubox(TPZ_DECK.position.x + 0.02, TPZ_DECK.end.x - 0.02, v - 0.085, v + 0.085, f - 0.04, f, tone, M_STONE, tone)
	var blocks := int(TPZ_DECK.size.x / 1.2)
	for k in blocks + 1:   # the pallets' blocks along the kerb side
		var bu := TPZ_DECK.position.x + 0.1 + k * (TPZ_DECK.size.x - 0.2) / blocks
		_ubox(bu - 0.08, bu + 0.08, TPZ_DECK.end.y - 0.02, TPZ_DECK.end.y + 0.01, g - 0.1, f - 0.04, TPZ_PINE_D)
	for t: Array in TPZ_TABLES:
		_tpz_table(t[0], t[1], f)
	for umb: Array in TPZ_UMBRELLAS:
		_tpz_umbrella(umb[0], umb[1], umb[2], f)
	# Along the kerb: the long crate bench with its black cushion, the planters with their trees at
	# both ends and one by the door; an A-board by the open bay.
	_tpz_crate(10.6, 12.5, 5.3, 5.85, f, f + 0.42)
	_ubox(10.62, 12.48, 5.32, 5.83, f + 0.42, f + 0.52, TPZ_BLACK, M_STONE, TPZ_BLACK.lightened(0.08))
	_tpz_planter(12.25, 4.6, f, 2.4)
	_tpz_planter(0.75, 5.55, f, 2.2)
	_tpz_planter(12.25, 2.6, f, 2.6)
	_tpz_bar(Vector3(_w(7.3, 1.2).x, g, _w(7.3, 1.2).y), Vector3(_w(7.3, 1.45).x, g + 0.9, _w(7.3, 1.45).y), 0.02, TPZ_BLACK)
	_ubox(7.0, 7.6, 1.35, 1.6, g + 0.15, g + 0.95, TPZ_BLACK, M_STONE, TPZ_BLACK)
	_collide(deck)


# --- Sienkiewicza 4, Harczyk's tenement and the block opposite (F, 2026-11-24) ----------------------
# Three full models on ul. Sienkiewicza, replacing their LoD2 and mapped outlines: the Art Nouveau
# tenement no. 4 (THE TAPCZAN's house: its street level west of u 12.9 stays the pub's), Kamienica
# Maksymiliana Harczyka on the corner of Jasna, and the 1950s block with the arcade across the street.
# Specs docs/landmarks/specs/sienkiewicza4.md, harczyk.md, sienkiewicza3.md.

## The OpenStreetMap rings holding any of `probes` (a house's parts: the block, its rear range and
## the low base), each once, so a site's zone takes the lot off the map.
func _sk_rings(probes: Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for bld in data.get("buildings", []):
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		for at: Vector2 in probes:
			if Geometry2D.is_point_in_polygon(at, q):
				out.append(q)
				break
	return out


## Plain panes (a trim pane and the glass over it) on every wall of `ring` that `skip` (given the
## edge's two ends) does not name: the sides and the yards of a modelled house, `rows` the sills.
func _sk_sides(ring: PackedVector2Array, f0: Vector2, f1: Vector2, rows: Array, trim: Color, skip: Callable) -> void:
	var n := ring.size()
	var cw := Geometry2D.is_polygon_clockwise(ring)
	for k in n:
		var p := ring[k]
		var q := ring[(k + 1) % n]
		kit_front(f0, f1)   # `skip` reads the site's own frame
		if p.distance_to(q) < 3.0 or skip.call(p, q):
			continue
		var le := kit_front(p, q) if cw else kit_front(q, p)
		var m := maxi(1, floori(le / 4.6))
		var cs: Array = []
		for i in m:
			cs.append((float(i) + 0.5) * le / float(m))
		kit_panes(cs, rows, 1.3, 1.9, trim, 0.03)
		kit_panes(cs, rows, 1.05, 1.7, PAL_GLASS_DARK, 0.06)


## True when both ends of the edge p-q lie within `tol` of the segment a-b (a party wall).
func _sk_on(p: Vector2, q: Vector2, a: Vector2, b: Vector2, tol: float) -> bool:
	return Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < tol \
			and Geometry2D.get_closest_point_to_segment(q, a, b).distance_to(q) < tol


# --- Sienkiewicza 4 -----------------------------------------------------------------------------

const SK4_AT: Array[Vector2] = [Vector2(-776.0, -58.0), Vector2(-790.0, -80.0)]
const SK4_TOP := 20.8
const SK4_REAR_TOP := 24.1
const SK4_CREAM := Color("#ece7db")    # F 2026-11-24: cream as in the photos (it read tan at #e6dcc6)
const SK4_TRIM := Color("#f5f2ea")
const SK4_FRIEZE := Color("#566259")      # the dark green-grey stone bands (leafy relief)
const SK4_LEAF := Color("#6b7a62")
const SK4_STEEL := Color("#4b5156")
const SK4_SILLS: Array[float] = [5.6, 8.6, 11.6, 14.6, 17.6]
const SK4_HEIGHTS: Array[float] = [1.9, 1.7, 1.7, 1.7, 1.7]
## The middle bays' centres (u from the west corner); the two bows stand at each end.
const SK4_BAYS: Array[float] = [6.7, 10.3, 13.9, 17.5, 21.1]
const SK4_BOWS: Array[float] = [2.6, 25.3]
## The pub's street level (TPZ_U1 + the ledge) ends here; east of it the shops and the gate.
const SK4_GATE := 14.75
const SK4_SHOPS: Array[Vector3] = [Vector3(18.5, 1.3, 0.0), Vector3(22.1, 1.5, 0.0), Vector3(25.5, 1.2, 0.0)]


func _find_sienkiewicza4() -> void:
	var rings := _sk_rings(SK4_AT)
	var main := _tallest_at(SK4_AT[0])
	var rear := _tallest_at(SK4_AT[1])
	if rings.size() < 2 or main.size() < 3 or rear.size() < 3:
		return
	_add_site("sienkiewicza4", rings)
	if not sites.is_empty() and sites[-1]["key"] == "sienkiewicza4":
		sites[-1]["main"] = main
		sites[-1]["rear"] = rear


## One of the two rounded corners: a four-sided bow standing out of the front, in three facets,
## each with its windows; curved iron balconies at the 2nd and 3rd floors.
func _sk4_bow(uc: float, g: float) -> void:
	var local: Array[Vector2] = [Vector2(uc - 2.3, 0.0), Vector2(uc - 0.85, 0.88), Vector2(uc + 0.85, 0.88),
			Vector2(uc + 2.3, 0.0)]
	var w: Array[Vector2] = []
	for p: Vector2 in local:
		w.append(_w(p.x, p.y))
	var ring := PackedVector2Array([_w(uc - 2.3, -0.2), w[0], w[1], w[2], w[3], _w(uc + 2.3, -0.2)])
	_prism(ring, g + 4.5, g + SK4_TOP, SK4_CREAM, PAL_ROOF_GRAVEL, M_STONE, M_STONE)
	_soffit(ring, g + 4.5, SK4_CREAM.darkened(0.25))
	_band(ring, 0.08, g + 10.45, g + 11.25, SK4_FRIEZE)
	_band(ring, 0.08, g + 16.45, g + 17.25, SK4_FRIEZE)
	kit_cornice_ring(ring, g + 20.2, SK4_TRIM, 0.55, 0.3)
	for k in 3:
		var le := kit_front(w[k], w[k + 1])
		for i in SK4_SILLS.size():
			var style := Win.SILL_HEAD if i == 0 else Win.SILL
			kit_window(le * 0.5, g + SK4_SILLS[i], SK4_HEIGHTS[i], style, SK4_TRIM, PAL_GLASS_DARK, 0.5)
		for i in [1, 2]:
			kit_balcony(le * 0.5, g + SK4_SILLS[i], 0.62, Balcony.IRON, PAL_PATINA_COPPER, SK4_CREAM, 0.5)
	kit_front(TPZ_FRONT_A, TPZ_FRONT_B)


## The steel truss canopy over the gate: a girder on two raking braces, a zigzag of diagonals.
func _sk4_canopy(u0: float, u1: float, g: float) -> void:
	var at := func(u: float, v: float, y: float) -> Vector3:
		var p := _w(u, v)
		return Vector3(p.x, y, p.y)
	_kbox(u0, u1, 0.0, 1.7, g + 3.95, g + 4.1, SK4_STEEL)
	_kbox(u0, u1, 1.62, 1.7, g + 4.1, g + 4.45, SK4_STEEL)
	for s: float in [u0 + 0.2, u1 - 0.2]:
		_beam(at.call(s, 0.05, g + 4.75), at.call(s, 1.65, g + 4.0), 0.1, SK4_STEEL)
	var n := 8
	for k in n:
		var ua := u0 + (u1 - u0) * float(k) / n
		var ub := u0 + (u1 - u0) * float(k + 1) / n
		var up := k % 2 == 0
		_beam(at.call(ua, 1.78, g + (4.1 if up else 4.45)), at.call(ub, 1.78, g + (4.45 if up else 4.1)), 0.06, SK4_STEEL)


## A dark green-grey frieze band with a row of leaf reliefs (the Art Nouveau stone bands).
func _sk4_frieze(u0: float, u1: float, y0: float, y1: float) -> void:
	_kbox(u0, u1, -0.02, 0.08, y0, y1, SK4_FRIEZE)
	var n := maxi(2, roundi((u1 - u0) / 0.8))
	for i in n:
		var cu := u0 + (float(i) + 0.5) * (u1 - u0) / float(n)
		var tall := 0.1 if i % 2 == 0 else 0.0
		_kbox(cu - 0.2, cu + 0.2, 0.08, 0.15, y0 + 0.1, y1 - 0.1 - tall, SK4_LEAF)


func _build_sienkiewicza4(site: Dictionary) -> void:
	var main: PackedVector2Array = site["main"]
	var rear: PackedVector2Array = site["rear"]
	var le := kit_front(TPZ_FRONT_A, TPZ_FRONT_B)
	var g := _ground_under(_urect(TPZ_U0, TPZ_U1, -0.3, TPZ_DECK.end.y))   # the pub's own ground
	_g = g
	_mode = M_STONE
	# The mass: the front recessed 0.35 m behind the skin (the pub's street level stands in the gap),
	# and the rear range to 24.1 m.
	var body := _largest(Geometry2D.intersect_polygons(main, _urect(-60.0, le + 60.0, -80.0, -0.35)))
	_prism(body, g - 1.0, g + SK4_TOP, SK4_CREAM, PAL_ROOF_GRAVEL, M_STONE, M_STONE)
	_prism(rear, g - 1.0, g + SK4_REAR_TOP, SK4_CREAM.darkened(0.04), PAL_ROOF_GRAVEL.darkened(0.05), M_STONE, M_STONE)
	_collide(main)
	_collide(rear)
	pocket_rings.append(main)
	pocket_rings.append(rear)
	# The skin: the street level east of the pub, and every floor over it.
	kit_wall(TPZ_U1 + 0.1, le, g - 0.3, g + 4.5, SK4_CREAM)
	kit_wall(0.0, le, g + 4.5, g + 20.2, SK4_CREAM)
	kit_ledge(TPZ_U1 + 0.1, le, g, 0.55, PAL_GREY_GRANITE, 0.08)
	kit_cornice(4.9, 23.0, g + 4.75, PAL_DARK_GRANITE, 0.45, 0.6)   # the bows carry their own
	kit_cornice(4.9, 23.0, g + 20.2, SK4_TRIM, 0.6, 1.0)
	# The frieze bands under the 3rd and the top floor, between the bows.
	for y: float in [10.45, 16.45]:
		_sk4_frieze(4.9, 23.0, g + y, g + y + 0.8)
	# The windows: a tall arched one on the first floor of each middle bay, then pairs.
	for u in SK4_BAYS:
		kit_window(u, g + SK4_SILLS[0], SK4_HEIGHTS[0], Win.ARCHED, SK4_TRIM, PAL_GLASS_DARK, 0.9)
		for i in range(1, SK4_SILLS.size()):
			for s: float in [-0.95, 0.95]:
				kit_window(u + s, g + SK4_SILLS[i], SK4_HEIGHTS[i], Win.SILL, SK4_TRIM, PAL_GLASS_DARK, 0.5)
	for y: float in [8.1, 14.1]:
		kit_ledge(4.9, 23.0, g + y, 0.22, SK4_TRIM, 0.12)
	# The gate with the steel canopy, and the shops east of it.
	kit_shop_bay(SK4_GATE, g + 0.05, g + 3.4, 1.15, SK4_TRIM, PAL_GLASS_DARK)
	for s: float in [-1.75, 1.75]:
		kit_pilaster(SK4_GATE + s, g + 0.2, g + 3.9, PAL_GREY_STONE, 0.5, 0.14)
	_sk4_canopy(SK4_GATE - 1.9, SK4_GATE + 1.9, g)
	for sp in SK4_SHOPS:
		kit_shop_bay(sp.x, g + 0.55, g + 3.8, sp.y, SK4_TRIM, PAL_GLASS_DARK)
	# The two bows, the 2nd and 3rd floor balconies on them.
	for uc in SK4_BOWS:
		_sk4_bow(uc, g)
	# The sides and the rear range: plain panes, but not on the party wall with Harczyk's house.
	var rows: Array = [g + 1.2, g + 5.6, g + 8.6, g + 11.6, g + 14.6, g + 17.6]
	var wall_w := Vector2(-789.1, -46.2)
	var wall_n := Vector2(-795.0, -61.6)
	var party := func(p: Vector2, q: Vector2) -> bool:
		return _sk_on(p, q, wall_w, wall_n, 1.0) or absf(_local(p).y) < 0.8 and absf(_local(q).y) < 0.8
	_sk_sides(main, TPZ_FRONT_A, TPZ_FRONT_B, rows, SK4_TRIM, party)
	_sk_sides(rear, TPZ_FRONT_A, TPZ_FRONT_B, rows, SK4_TRIM.darkened(0.03), party)
	kit_front(TPZ_FRONT_A, TPZ_FRONT_B)


# --- Kamienica Maksymiliana Harczyka --------------------------------------------------------------

const HZ_AT := Vector2(-805.0, -50.0)
const HZ_P0 := Vector2(-789.1, -46.2)       # where it meets no. 4
const HZ_J0 := Vector2(-832.1, -61.0)       # the north end of its Jasna front
const HZ_CORNER := Vector2(-820.9, -35.8)   # the mapped corner (a small jog), replaced by a wide chamfer
const HZ_CHAMFER := 5.5                     # each leg of the chamfer, along the two fronts
const HZ_EAVE := 18.85
const HZ_TOP := 20.8
const HZ_DEPTH := 2.0
const HZ_WHITE := Color("#e4d9b8")      # soiled warm cream stucco (photos 1, 4)
const HZ_TRIM := Color("#ebe2c8")
const HZ_PLINTH := Color("#b8a688")     # unpainted sandstone
const HZ_BRICK := Color("#a5523e")
const HZ_GOLD := Color("#c9ac6a")
const HZ_YELLOW := Color(1.0, 0.86, 0.3)
const HZ_SILLS: Array[float] = [5.1, 8.0, 10.9, 13.8, 16.6]
const HZ_HEIGHTS: Array[float] = [2.3, 2.1, 1.9, 1.9, 1.5]


func _find_harczyk() -> void:
	var raw := _tallest_at(HZ_AT)
	if raw.size() < 10:
		return
	var n := raw.size()
	var pi := -1
	var ji := -1
	var ci := -1
	for i in n:
		if raw[i].distance_to(HZ_P0) < 0.5:
			pi = i
		elif raw[i].distance_to(HZ_J0) < 0.5:
			ji = i
		elif raw[i].distance_to(HZ_CORNER) < 0.5:
			ci = i
	if pi < 0 or ji < 0 or ci < 0:
		return
	var f1 := raw[(pi + 1) % n]
	var jd := (raw[ci] - HZ_J0).normalized()
	var hit = Geometry2D.line_intersects_line(HZ_P0, (f1 - HZ_P0).normalized(), HZ_J0, jd)
	if not hit is Vector2:
		return
	var cc: Vector2 = hit
	var k1 := cc + (HZ_P0 - cc).normalized() * HZ_CHAMFER
	var k2 := cc + (HZ_J0 - cc).normalized() * HZ_CHAMFER
	# The ring from the Jasna end round the back to no. 4, then the chamfer: its last three edges are
	# the street fronts (Sienkiewicza, the chamfer, Jasna).
	var ring := PackedVector2Array()
	var i := ji
	while true:
		ring.append(raw[i])
		if i == pi:
			break
		i = (i + 1) % n
	ring.append(k1)
	ring.append(k2)
	_add_site("harczyk", [raw])
	if not sites.is_empty() and sites[-1]["key"] == "harczyk":
		sites[-1]["raw"] = raw
		sites[-1]["ring"] = ring


## A dormer in the current front's frame, standing on the mansard: red brick cheeks, a window, a
## white gable over it.
func _hz_dormer(u: float, g: float, wide: float, rise: float, cheek: float) -> void:
	var y := g + HZ_EAVE
	# brick panel between the gables, then a round-headed gable (a wave skyline) with an arched pane
	_kbox(u - cheek, u + cheek, -HZ_DEPTH + 0.05, -0.45, y + 0.05, y + 2.05, HZ_BRICK)
	var keep := _face
	kit_face(-0.45)
	var at := _w(u, _face)
	var spring := y + 1.7 + rise * 0.4
	_arch_panel(at, _a, _b, wide, y + 0.05, spring, HZ_WHITE, 0.06, M_STONE)
	_arch_panel(at, _a, _b, wide * 0.55, y + 0.6, spring - 0.25, PAL_GLASS_DARK, 0.1, M_STONE)
	kit_face(keep)


## The mansard along a run of the fronts `pts` (ring edges in order): the slope from the eave line
## `y0` back `depth` m and up `rise`; returns the slope's plan so the flat top can leave it out.
func _hz_mansard(ring: PackedVector2Array, pts: Array[Vector2], y0: float, rise: float, depth: float) -> PackedVector2Array:
	var m := pts.size()
	var inward: Array[Vector2] = []
	for i in m - 1:
		inward.append(-_out(ring, pts[i], pts[i + 1]))
	var q: Array[Vector2] = []
	for i in m:
		var d: Vector2
		if i == 0:
			d = inward[0] * depth
		elif i == m - 1:
			d = inward[m - 2] * depth
		else:
			d = (inward[i - 1] + inward[i]) * (depth / maxf(1.0 + inward[i - 1].dot(inward[i]), 0.2))
		q.append(pts[i] + d)
	_mode = M_STONE
	for i in m - 1:
		var o := -inward[i]
		var nrm := (Vector3(o.x, 0.0, o.y) * rise + Vector3.UP * depth).normalized()
		_quad(Vector3(pts[i].x, y0, pts[i].y), Vector3(pts[i + 1].x, y0, pts[i + 1].y),
				Vector3(q[i + 1].x, y0 + rise, q[i + 1].y), Vector3(q[i].x, y0 + rise, q[i].y), nrm, PAL_ROOF_DARK)
	var band := PackedVector2Array()
	for p in pts:
		band.append(p)
	for i in range(m - 1, -1, -1):
		band.append(q[i])
	return band


## A shop opening with a round head: a trim arch behind the dark glass, 3.05 m tall in all.
func _hz_shop(u: float, g: float, hw: float) -> void:
	var at := _w(u, _face)
	_arch_panel(at, _a, _b, hw + 0.15, g + 0.7, g + 3.8 - hw, HZ_TRIM, 0.03, M_STONE)
	_arch_panel(at, _a, _b, hw, g + 0.75, g + 3.8 - hw - 0.05, PAL_GLASS_DARK, 0.07, M_STONE)


## One front's windows, balconies and dormers; `bays` windows across, `bal` the bays with a
## balcony on the 3rd floor, `ground` what stands on the street level (called with the frame set).
func _hz_front(le: float, bays: int, bal: Array, g: float, crown := -1, mid_only := false) -> Array[float]:
	var cs: Array[float] = []
	for i in bays:
		cs.append((float(i) + 0.5) * le / float(bays))
	kit_ledge(0.0, le, g, 0.7, HZ_PLINTH, 0.1)
	kit_bands(0.0, le, g + 0.7, g + 4.3, 0.9, HZ_TRIM.darkened(0.12))
	kit_ledge(0.0, le, g + 4.4, 0.4, HZ_TRIM, 0.22)
	kit_cornice(0.0, le, g + 18.4, HZ_WHITE, 0.45, 0.9)
	for ci in cs.size():
		var u := cs[ci]
		_hz_dormer(u, g, 1.15 if ci == crown else 0.78, 1.6 if ci == crown else 0.8, minf(le / float(bays) * 0.5 - 0.1, 1.9))
		if mid_only and ci != crown:
			continue
		kit_window(u, g + HZ_SILLS[0], HZ_HEIGHTS[0], Win.HOODED, HZ_TRIM, PAL_GLASS_DARK, 0.85)
		kit_window(u, g + HZ_SILLS[1], HZ_HEIGHTS[1], Win.ARCHED, HZ_TRIM, PAL_GLASS_DARK, 0.65)
		kit_window(u, g + HZ_SILLS[2], HZ_HEIGHTS[2], Win.SILL_HEAD, HZ_TRIM, PAL_GLASS_DARK, 0.65)
		kit_window(u, g + HZ_SILLS[3], HZ_HEIGHTS[3], Win.SILL, HZ_TRIM, PAL_GLASS_DARK, 0.65)
		kit_window(u, g + HZ_SILLS[4], HZ_HEIGHTS[4], Win.SILL_HEAD, HZ_TRIM, PAL_GLASS_DARK, 0.6)
	for b: int in bal:
		kit_balcony(cs[b], g + HZ_SILLS[2], 0.95, Balcony.STONE, HZ_WHITE, HZ_TRIM, 0.95)
	return cs


func _build_harczyk(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	var raw: PackedVector2Array = site["raw"]
	var n := ring.size()
	var k1 := ring[n - 2]
	var k2 := ring[n - 1]
	var p0 := ring[n - 3]
	var j0 := ring[0]
	var g := _ground_under(ring)
	_g = g
	_mode = M_STONE
	_collide(raw)
	pocket_rings.append(raw)
	# The walls: the three street fronts to the eaves, the rest to the flat top.
	var run := 0.0
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var front := i >= n - 3
		_wall(a, b, g - 1.0, g + (HZ_EAVE if front else HZ_TOP), _out(ring, a, b), HZ_WHITE, run)
		run += a.distance_to(b)
	var fronts: Array[Vector2] = [p0, k1, k2, j0]
	var band := _hz_mansard(ring, fronts, g + HZ_EAVE, HZ_TOP - HZ_EAVE, HZ_DEPTH)
	for piece in Geometry2D.clip_polygons(ring, band):
		if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
			_cap(piece, g + HZ_TOP, PAL_ROOF_GRAVEL)
	# Sienkiewicza: the long front, the REJNA entrance and LIMONKA at the east end.
	var ls := kit_front(k1, p0)
	var cs := _hz_front(ls, 8, [1, 6], g)
	for i in cs.size():
		if i == 2:
			kit_door(cs[i], g + 0.1, 3.3, 1.0, HZ_TRIM, PAL_DARK_DOOR, true)
			_kbox(cs[i] - 1.6, cs[i] + 1.6, 0.0, 0.12, g + 3.55, g + 4.3, HZ_GOLD)
			_usign("REJNA", cs[i], 0.14, g + 3.85, _b, 2.6, 0.4, Color(0.2, 0.15, 0.08))
		else:
			_hz_shop(cs[i], g, 1.3)
	_usign("LIMONKA", cs[7], 0.2, g + 4.0, _b, 2.0, 0.34, HZ_YELLOW)
	# Jasna: the second long front.
	var lj := kit_front(j0, k2)
	var cj := _hz_front(lj, 7, [1, 5], g)
	for u in cj:
		_hz_shop(u, g, 1.3)
	# The chamfer: three narrow bays, the stack of balconies on the middle one, the crown gable.
	var lk := kit_front(k2, k1)
	var cc := _hz_front(lk, 3, [], g, 1, true)
	# One window a floor; balconies alternate: wide at floor 1, small at floors 3 and 5 (photos 1, 4).
	kit_balcony(cc[1], g + HZ_SILLS[0], 1.3, Balcony.STONE, HZ_TRIM.lightened(0.35), HZ_PLINTH, 0.9)
	kit_balcony(cc[1], g + HZ_SILLS[2], 0.85, Balcony.STONE, HZ_TRIM.lightened(0.35), HZ_PLINTH, 0.8)
	kit_balcony(cc[1], g + HZ_SILLS[4], 0.85, Balcony.STONE, HZ_TRIM.lightened(0.35), HZ_PLINTH, 0.8)
	_hz_shop(cc[0], g, 1.0)
	_hz_shop(cc[2], g, 1.0)
	kit_door(cc[1], g + 0.1, 3.4, 1.1, HZ_TRIM, PAL_DARK_DOOR, true)
	# The sides and the yards: plain panes, but not on the party walls (no. 4, the bank's office).
	var rows: Array = [g + 1.3, g + 5.1, g + 8.0, g + 10.9, g + 13.8, g + 16.6]
	var seg := func(p: Vector2, q: Vector2) -> bool:
		return _sk_on(p, q, p0, Vector2(-795.0, -61.6), 1.0) or _sk_on(p, q, Vector2(-831.6, -61.2), Vector2(-816.4, -67.2), 1.0) \
				or _sk_on(p, q, p0, k1, 1.0) or _sk_on(p, q, k1, k2, 1.0) or _sk_on(p, q, k2, j0, 1.0)
	_sk_sides(ring, k1, p0, rows, HZ_TRIM, seg)
	kit_front(k1, p0)


# --- the block opposite (Sienkiewicza 3 in OpenStreetMap's addresses) ---------------------------------

const SB_AT: Array[Vector2] = [Vector2(-765.0, -25.0), Vector2(-752.0, -30.0)]
const SB_E := Vector2(-752.5, -38.0)        # the east end of its front
const SB_W := Vector2(-778.2, -28.1)        # the west end
const SB_ARCADE := 2.2                      # how far the upper floors stand back of the balcony's edge
const SB_PITCH := 13                        # bays across
const SB_TOP := 20.8
const SB_SAND := Color("#d6c3a0")
const SB_SAND_L := Color("#e3d4b5")
const SB_PILLAR := Color("#c4ae86")
const SB_RED := Color("#b98471")
const SB_SILLS: Array[float] = [4.6, 7.9, 11.2, 14.5, 17.8]
const SB_HEIGHTS: Array[float] = [2.2, 1.7, 1.7, 1.7, 1.7]
const SB_PILLARS: Array[float] = [4.9, 10.4, 17.2, 22.0]
const SB_TUNNEL := Vector2(11.6, 16.0)      # the passage through to the south


func _find_sienkiewicza3() -> void:
	var rings := _sk_rings(SB_AT)
	var main := _tallest_at(SB_AT[0])
	if rings.size() < 2 or main.size() < 3:
		return
	_add_site("sienkiewicza3", rings)
	if not sites.is_empty() and sites[-1]["key"] == "sienkiewicza3":
		sites[-1]["main"] = main


func _build_sienkiewicza3(site: Dictionary) -> void:
	var main: PackedVector2Array = site["main"]
	var le := kit_front(SB_E, SB_W)
	var g := _ground_under(main)
	_g = g
	_mode = M_STONE
	_collide(main)
	pocket_rings.append(main)
	var none := Color(0, 0, 0, 0)
	var inner := _largest(Geometry2D.intersect_polygons(main, _urect(-60.0, le + 60.0, -80.0, -SB_ARCADE)))
	var tunnel := _urect(SB_TUNNEL.x, SB_TUNNEL.y, -80.0, -SB_ARCADE + 0.1)
	# The street level: the ground range with the passage cut through it, its ceiling over the passage.
	for piece in Geometry2D.clip_polygons(inner, tunnel):
		if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
			_prism(piece, g - 1.0, g + 4.3, SB_SAND, none, M_STONE)
	for piece in Geometry2D.intersect_polygons(inner, tunnel):
		if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
			_soffit(piece, g + 4.3, SB_PILLAR.darkened(0.2))
	# The five floors over it.
	_prism(inner, g + 4.3, g + SB_TOP, SB_SAND, PAL_ROOF_GRAVEL, M_STONE, M_STONE)
	# The arcade: the floor and the three steps up to it, the slab with its fascia, the balustrade.
	_ubox(0.0, le, -SB_ARCADE, 0.0, g - 0.2, g + 0.6, PAL_GREY_GRANITE, M_STONE, PAL_PALE_CONCRETE)
	_ubox(0.3, le - 0.3, 0.0, 1.0, g - 0.2, g + 0.2, PAL_GREY_GRANITE, M_STONE, PAL_PALE_CONCRETE)
	_ubox(0.15, le - 0.15, 0.0, 0.65, g + 0.2, g + 0.4, PAL_GREY_GRANITE, M_STONE, PAL_PALE_CONCRETE)
	_ubox(0.0, le, -SB_ARCADE, 0.0, g + 3.7, g + 4.3, SB_SAND_L, M_STONE, SB_SAND_L)
	_soffit(_urect(0.0, le, -SB_ARCADE, 0.0), g + 3.7, SB_PILLAR.darkened(0.25))
	kit_face(-0.15)
	kit_attic(0.0, le, g + 4.3, SB_SAND_L, 1.0, Attic.BALUSTRADE)
	kit_face(0.0)
	for s: float in [0.1, le - 0.1]:
		_ubox(s - 0.1, s + 0.1, -SB_ARCADE, 0.0, g + 4.5, g + 5.2, SB_SAND_L)
	# The pillars and the end blocks, the doors and the grilled windows of the ground wall.
	_ubox(0.0, 1.3, -SB_ARCADE, -0.15, g + 0.6, g + 3.7, SB_PILLAR)
	_ubox(le - 1.3, le, -SB_ARCADE, -0.15, g + 0.6, g + 3.7, SB_PILLAR)
	for u: float in SB_PILLARS:
		_ubox(u - 0.45, u + 0.45, -1.05, -0.15, g + 0.6, g + 3.7, SB_PILLAR)
	kit_face(-SB_ARCADE)
	kit_door(3.2, g + 0.6, 2.4, 0.55, SB_SAND_L, PAL_OAK)
	kit_door(le - 3.2, g + 0.6, 2.4, 0.55, SB_SAND_L, PAL_OAK)
	for u: float in [7.6, 20.0, 24.0]:
		kit_window(u, g + 1.7, 1.6, Win.SILL, SB_SAND_L, PAL_GLASS_DARK, 0.7)
	# The upper floors: piers (every third one in the reddish stone), windows in the deep bays.
	kit_face(-SB_ARCADE)
	var pitch := le / float(SB_PITCH)
	for i in SB_PITCH + 1:
		var red := i % 3 == 1
		kit_pilaster(float(i) * pitch, g + 4.3, g + 20.0, SB_RED if red else SB_SAND_L, 0.9 if 0 < i and i < SB_PITCH else 0.5, 0.3)
	for i in SB_PITCH:
		var u := (float(i) + 0.5) * pitch
		for k in SB_SILLS.size():
			kit_window(u, g + SB_SILLS[k], SB_HEIGHTS[k], Win.SILL, SB_SAND_L, PAL_GLASS_DARK, 0.55)
	for y: float in [7.4, 10.7, 14.0, 17.3]:
		kit_ledge(0.0, le, g + y, 0.25, SB_SAND_L, 0.12)
	kit_cornice(0.0, le, g + 20.2, SB_SAND_L, 0.6, 1.1)
	# The sides and the rear: plain panes, none on the party wall with the bank next door.
	kit_front(SB_E, SB_W)
	var rows: Array = [g + 1.3, g + 4.6, g + 7.9, g + 11.2, g + 14.5, g + 17.8]
	var party := func(p: Vector2, q: Vector2) -> bool:
		return (_local(p).x > le - 1.5 and _local(q).x > le - 1.5) or (_local(p).y > -SB_ARCADE + 0.5 and _local(q).y > -SB_ARCADE + 0.5)
	_sk_sides(inner, SB_E, SB_W, rows, SB_SAND_L, party)
	kit_front(SB_E, SB_W)


# --- Gmach Chemii Politechniki Warszawskiej (Noakowskiego 3) ------------------------------------
# Spec docs/landmarks/specs/gmach_chemii.md: neo-Renaissance Chemistry building (1899-1901).
# Dark ochre sandstone front with grey rusticated ground floor, three wooden doors up steps in
# a projecting three-part central entrance risalit with giant Corinthian columns and paired
# corner pilasters, two tall upper storeys of arched windows, crowning cornice at 18 m, dark
# grey hipped roofs over four wings round an inner courtyard.

const GC_NAME := "Gmach Chemii"
const GC_WALL := Color("#b3a27f")          # dark ochre sandstone front (spec)
const GC_BASE := Color("#8f8c85")          # grey rusticated ground floor (spec)
const GC_TRIM := Color("#efece4")          # white frames, string courses and cornice (spec)
const GC_COURT := Color("#c9bd9f")         # courtyard render (spec)
const GC_ROOF := Color("#5b5f63")          # dark grey hipped roofs (spec)
const GC_GLASS := Color("#4a5660")         # window glass (spec)
const GC_DOOR := Color("#5a3e2a")          # wooden entrance doors (spec)
const GC_GLOW := Color("#ffd9a0")          # warm night entrance glow (M_LAMP / M_PAVILION)
const GC_BASE_H := 5.5                     # rusticated ground floor height
const GC_WALL_H := 17.0                    # top of upper storeys
const GC_EAVE_H := 18.0                    # top of frieze and main cornice
const GC_ATTIC_H := 1.0                    # attic height over risalits and corner pavilions
const GC_ROOF_H := 1.4                     # low flat-ish dark grey roof rise over wings (3D Tiles)


## Finds Gmach Chemii's OSM outline and registers the `gmach_chemii` site with a 0.5 m outward
## zone offset so the map's plain 10.9 m prism is replaced cleanly.
func _find_gmach_chemii() -> void:
	var raw := _landmark(GC_NAME)
	if raw.size() < 3:
		push_error("gmach_chemii: landmark outline '%s' is missing from centrum.json" % GC_NAME)
		return
	var zone := _largest(Geometry2D.offset_polygon(raw, 0.5, Geometry2D.JOIN_MITER))
	if zone.size() < 3:
		zone = raw
	_add_site("gmach_chemii", [zone])
	if not sites.is_empty() and sites[-1]["key"] == "gmach_chemii":
		sites[-1]["raw"] = raw


## Builds Gmach Chemii from its mapped outline: four 18 m neo-Renaissance wings round an inner
## courtyard, rusticated grey base, three-part central entrance risalit with steps, three wooden
## doors, warm night lanterns and giant columns, four corner pavilions with paired pilasters and
## attics, round-top upper windows, crowning cornice, hipped roofs, and outline collision.
func _build_gmach_chemii(site: Dictionary) -> void:
	var raw: PackedVector2Array = site.get("raw", PackedVector2Array())
	if raw.size() < 3:
		return
	var m := _gc_frame(raw)
	if m.is_empty():
		return
	var g := _ground_under(raw)
	_g = g
	_mode = M_STONE
	_gc_set_frame(m)
	var outer := _gc_outer_ring(m)
	var court := _gc_ccw(_urect(m["cu0"], m["cu1"], m["cv0"], m["cv1"]))
	_gc_main_walls(m, outer, court, g)
	_gc_risalit(m, g)
	_gc_dress_outer(m, g)
	_gc_dress_court(m, g)
	_gc_roofs(m, g)
	_collide(raw)
	_mode = M_STONE


## Restores Gmach Chemii's main local frame (+u SE->NW along Noakowskiego, +v outward NE).
func _gc_set_frame(m: Dictionary) -> void:
	_o = m["o"]
	_a = m["a"]
	_b = m["b"]
	kit_face(0.0)


## Starts a kit_front along edge a->b oriented so _b aligns with the outward normal `out`.
func _gc_front_edge(a: Vector2, b: Vector2, out: Vector2) -> float:
	var dir := (b - a).normalized()
	if Vector2(-dir.y, dir.x).dot(out) < 0.0:
		return kit_front(b, a)
	return kit_front(a, b)


## Returns a counter-clockwise copy of `ring` for _prism, _cap, _holes and ring helpers.
func _gc_ccw(ring: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array(ring)
	if Geometry2D.is_polygon_clockwise(out):
		out.reverse()
	return out


## Derives Gmach Chemii's local symmetry frame and wing/risalit/pavilion bounds directly from
## its 56-node OSM outline, discarding sub-1.5 m corner wiggles.
func _gc_frame(raw: PackedVector2Array) -> Dictionary:
	var poly := _gc_ccw(raw)
	var n := poly.size()
	var want_ne := Vector2(0.743, -0.669).normalized()
	var front_pts: Array[Vector2] = []
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		if a.distance_to(b) > 15.0 and _out(poly, a, b).dot(want_ne) > 0.90:
			front_pts.append(a)
			front_pts.append(b)
	if front_pts.size() < 2:
		return {}
	# Extreme NW and SE endpoints of the Noakowskiego front line (smaller x+z is NW).
	var p_nw := front_pts[0]
	var p_se := front_pts[0]
	for p in front_pts:
		if p.x + p.y < p_nw.x + p_nw.y:
			p_nw = p
		if p.x + p.y > p_se.x + p_se.y:
			p_se = p
	var axis_a := (p_nw - p_se).normalized()
	var out_b := Vector2(-axis_a.y, axis_a.x)
	var origin := (p_nw + p_se) * 0.5
	_o = origin
	_a = axis_a
	_b = out_b
	var front_hw := p_nw.distance_to(p_se) * 0.5
	var u_min := INF
	var u_max := -INF
	var v_min := INF
	var ris_u0 := INF
	var ris_u1 := -INF
	var ris_v_tower := 3.6
	var ris_v_mid := 2.8
	var mid_u0 := -4.9
	var mid_u1 := 4.9
	var v_fpav_front := -6.75
	var v_fpav_back := -16.25
	var v_rpav_front := -54.95
	var v_back_wing := -63.30
	var side_se := -42.30
	var side_nw := 42.50
	var rpav_se_u := -29.10
	var rpav_nw_u := 29.50
	for p in poly:
		var l := _local(p)
		u_min = minf(u_min, l.x)
		u_max = maxf(u_max, l.x)
		v_min = minf(v_min, l.y)
		if l.y > 1.5:
			ris_u0 = minf(ris_u0, l.x)
			ris_u1 = maxf(ris_u1, l.x)
			ris_v_tower = maxf(ris_v_tower, l.y)
	# Refine side-wing, rear-wing and recessed central entrance coordinates from long edges.
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var ln := a.distance_to(b)
		var out := _out(poly, a, b)
		var ml := _local((a + b) * 0.5)
		if ln > 25.0 and out.dot(-out_b) > 0.90:
			v_back_wing = ml.y
		elif ln > 25.0 and out.dot(-axis_a) > 0.90:
			side_se = ml.x
		elif ln > 25.0 and out.dot(axis_a) > 0.90:
			side_nw = ml.x
		elif ln > 6.0 and ln < 12.0 and out.dot(out_b) > 0.90 and ml.y < -4.0 and ml.y > -10.0:
			v_fpav_front = ml.y
		elif ln > 4.0 and ln < 8.0 and out.dot(out_b) > 0.90 and absf(ml.x) < 5.5 and ml.y > 2.0 and ml.y < 3.3:
			ris_v_mid = minf(ml.y, ris_v_tower - 0.80)
	if ris_u0 >= ris_u1:
		ris_u0 = -10.9
		ris_u1 = 10.9
	mid_u0 = ris_u0 + 6.0
	mid_u1 = ris_u1 - 6.0
	var cv0 := v_back_wing + 13.3
	var cv1 := v_fpav_back
	var uc := (rpav_se_u + rpav_nw_u) * 0.5
	return {
		"o": origin, "a": axis_a, "b": out_b,
		"front_hw": front_hw,
		"u_se": u_min, "u_nw": u_max,
		"side_se": side_se, "side_nw": side_nw,
		"ris_u0": ris_u0, "ris_u1": ris_u1,
		"mid_u0": mid_u0, "mid_u1": mid_u1,
		"ris_v_tower": ris_v_tower, "ris_v_mid": ris_v_mid,
		"v_fpav_front": v_fpav_front, "v_fpav_back": v_fpav_back,
		"v_rpav_front": v_rpav_front,
		"v_back_wing": v_back_wing, "v_back_pav": v_min,
		"rpav_se_u": rpav_se_u, "rpav_nw_u": rpav_nw_u,
		"cu0": rpav_se_u, "cu1": rpav_nw_u,
		"cv0": cv0, "cv1": cv1,
		# Central inner courtyard block (3D Tiles 2026-11-28): T-wing projecting from front wing,
		# dividing the courtyard into two large SE/NW light wells and a narrow SW passage.
		"in_nu0": uc - 7.0, "in_nu1": uc + 7.0,
		"in_u0": uc - 12.8, "in_u1": uc + 12.8,
		"in_v_join": cv1 - 6.0, "in_v0": cv0 + 6.0,
	}


## Builds the clean orthogonal 28-vertex outer plan ring of Gmach Chemii matching all four wings,
## four corner pavilions and the three-part central entrance risalit (no sub-1.5 m wiggles).
func _gc_outer_ring(m: Dictionary) -> PackedVector2Array:
	var fhw: float = m["front_hw"]
	var u_se: float = m["u_se"]
	var u_nw: float = m["u_nw"]
	var s_se: float = m["side_se"]
	var s_nw: float = m["side_nw"]
	var ru0: float = m["ris_u0"]
	var ru1: float = m["ris_u1"]
	var mu0: float = m["mid_u0"]
	var mu1: float = m["mid_u1"]
	var rvt: float = m["ris_v_tower"]
	var rvm: float = m["ris_v_mid"]
	var fpf: float = m["v_fpav_front"]
	var fpb: float = m["v_fpav_back"]
	var rpf: float = m["v_rpav_front"]
	var vbw: float = m["v_back_wing"]
	var vbp: float = m["v_back_pav"]
	var rse: float = m["rpav_se_u"]
	var rnw: float = m["rpav_nw_u"]
	return _gc_ccw(_lpoly([
		[u_se, fpf], [-fhw, fpf], [-fhw, 0.0],
		[ru0, 0.0], [ru0, rvt], [mu0, rvt], [mu0, rvm],
		[mu1, rvm], [mu1, rvt], [ru1, rvt], [ru1, 0.0],
		[fhw, 0.0], [fhw, fpf], [u_nw, fpf],
		[u_nw, fpb], [s_nw, fpb], [s_nw, rpf], [u_nw, rpf], [u_nw, vbp],
		[rnw, vbp], [rnw, vbw], [rse, vbw], [rse, vbp],
		[u_se, vbp], [u_se, rpf], [s_se, rpf], [s_se, fpb], [u_se, fpb],
	]))


## Draws horizontal rustication bands (kit_bands) only on ground-floor piers between openings
## so grooves never overlap window panes or doors.
func _gc_rusticate_piers(u0: float, u1: float, centres: Array, gap_hw: float, y0: float, y1: float) -> void:
	var cur := u0
	for c_var in centres:
		var c := float(c_var)
		var stop := c - gap_hw
		if stop - cur > 0.35:
			kit_bands(cur + 0.08, stop - 0.08, y0, y1, 1.25, GC_BASE)
		cur = maxf(cur, c + gap_hw)
	if u1 - cur > 0.35:
		kit_bands(cur + 0.08, u1 - 0.08, y0, y1, 1.25, GC_BASE)


## Builds Gmach Chemii's outer perimeter walls, inward-facing courtyard walls, roof deck with
## open courtyard hole, plinth, string courses and crowning cornice ring.
func _gc_main_walls(m: Dictionary, outer: PackedVector2Array, court: PackedVector2Array, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	_prism(outer, g - 0.5, g + GC_BASE_H, GC_BASE, none, M_STONE)
	_prism(outer, g + GC_BASE_H, g + GC_WALL_H, GC_WALL, none, M_STONE)
	_prism(outer, g + GC_WALL_H, g + GC_EAVE_H, GC_WALL.lightened(0.05), none, M_STONE)
	# Inner courtyard walls facing inward toward the open court.
	var run := 0.0
	for i in court.size():
		var a := court[i]
		var b := court[(i + 1) % court.size()]
		var inward := -_out(court, a, b)
		_wall(a, b, g - 0.5, g + GC_WALL_H, inward, GC_COURT, run)
		_wall(a, b, g + GC_WALL_H, g + GC_EAVE_H, inward, GC_COURT.lightened(0.05), run)
		run += a.distance_to(b)
	_holes = [court]
	_cap(outer, g + GC_EAVE_H - 0.05, GC_ROOF.darkened(0.22))
	_holes = []
	# Courtyard ground paving inside the light wells and the central inner courtyard block (3D Tiles).
	_cap(court, g + 0.04, Color("#6e7174"))
	var nu0: float = m["in_nu0"]
	var nu1: float = m["in_nu1"]
	var iu0: float = m["in_u0"]
	var iu1: float = m["in_u1"]
	var nv_j: float = m["in_v_join"]
	var iv0: float = m["in_v0"]
	var cv1: float = m["cv1"]
	var inner_ring := _gc_ccw(_lpoly([
		[nu0, cv1], [nu1, cv1], [nu1, nv_j], [iu1, nv_j],
		[iu1, iv0], [iu0, iv0], [iu0, nv_j], [nu0, nv_j],
	]))
	_prism(inner_ring, g - 0.5, g + GC_WALL_H, GC_COURT, none, M_STONE)
	_prism(inner_ring, g + GC_WALL_H, g + GC_EAVE_H, GC_COURT.lightened(0.05), none, M_STONE)
	_cap(inner_ring, g + GC_EAVE_H - 0.05, GC_ROOF.darkened(0.22))
	# Continuous ground plinth, floor string courses and crowning cornice around the outer ring.
	kit_ledge_ring(outer, g - 0.4, 1.35, GC_BASE.darkened(0.08), 0.12)
	kit_ledge_ring(outer, g + 5.45, 0.28, GC_TRIM, 0.14)
	kit_ledge_ring(outer, g + 11.20, 0.26, GC_TRIM, 0.15)
	kit_cornice_ring(outer, g + 17.48, GC_TRIM, 0.52, 0.52)


## Builds Gmach Chemii's projecting three-part central entrance risalit on Noakowskiego: broad
## stone steps, three wooden double doors with warm night lanterns and transoms, four giant
## Corinthian columns, six round-arched upper windows, flanking projecting piers with paired
## giant pilasters, round-arched first-floor windows and flat-topped attics.
func _gc_risalit(m: Dictionary, g: float) -> void:
	_gc_set_frame(m)
	var ru0: float = m["ris_u0"]
	var ru1: float = m["ris_u1"]
	var mu0: float = m["mid_u0"]
	var mu1: float = m["mid_u1"]
	var rvt: float = m["ris_v_tower"]
	var rvm: float = m["ris_v_mid"]
	var out_ne: Vector2 = m["b"]
	# Recessed central 3-bay entrance loggia (steps, 3 doors, 4 Corinthian columns, 6 arched windows).
	var wm := _gc_front_edge(_w(mu0, rvm), _w(mu1, rvm), out_ne)
	var step_top := g + 0.66
	for k in 3:
		var run_d := 0.52 * float(3 - k)
		_kbox(-0.08, wm + 0.08, 0.0, run_d, g - 0.4 + k * 0.22, g + 0.22 * float(k + 1), GC_BASE.lightened(0.14))
	var door_cs := _spread(0.35, wm - 0.35, 3)
	for du_var in door_cs:
		var du := float(du_var)
		kit_door(du, step_top, 3.85, 1.00, GC_TRIM, GC_DOOR, false)
		# Warm night glow in the entrance transom over each wooden double door.
		_kbox(du - 0.90, du + 0.90, 0.04, 0.09, step_top + 3.15, step_top + 3.75, GC_GLOW, M_PAVILION)
	_gc_rusticate_piers(0.10, wm - 0.10, door_cs, 1.18, g + 0.95, g + 5.25)
	# Four giant Corinthian columns standing on the rusticated ground floor, plus wall lanterns.
	var col_us: Array[float] = [0.42, (float(door_cs[0]) + float(door_cs[1])) * 0.5,
			(float(door_cs[1]) + float(door_cs[2])) * 0.5, wm - 0.42]
	for cu_c in col_us:
		kit_column(cu_c, 0.48, g + 5.75, g + 17.0, GC_WALL.lightened(0.14), 0.42, Order.CORINTHIAN)
		_kbox(cu_c - 0.10, cu_c + 0.10, 0.08, 0.24, g + 3.55, g + 4.10, GC_GLOW, M_LAMP)
	for du_var in door_cs:
		var du := float(du_var)
		kit_round_window(_w(du, 0.0), _a, _b, g + 6.30, g + 9.10, 0.78, GC_TRIM, GC_GLASS)
		kit_round_window(_w(du, 0.0), _a, _b, g + 12.15, g + 14.55, 0.75, GC_TRIM, GC_GLASS)
	kit_attic(0.0, wm, g + GC_EAVE_H, GC_WALL, 0.85, Attic.WALL)
	# Two projecting flanking risalit towers (paired giant pilasters, arched 1st floor, framed 2nd).
	_gc_set_frame(m)
	for span: Array in [[ru0, mu0], [mu1, ru1]]:
		var u0: float = span[0]
		var u1: float = span[1]
		var wt := _gc_front_edge(_w(u0, rvt), _w(u1, rvt), out_ne)
		var tc := wt * 0.5
		kit_window(tc - 0.52, g + 1.45, 2.75, Win.PLAIN, GC_TRIM, GC_GLASS, 0.34)
		kit_window(tc + 0.52, g + 1.45, 2.75, Win.PLAIN, GC_TRIM, GC_GLASS, 0.34)
		_gc_rusticate_piers(0.08, wt - 0.08, [tc], 1.12, g + 0.95, g + 5.25)
		kit_round_window(_w(tc, 0.0), _a, _b, g + 6.30, g + 9.25, 0.84, GC_TRIM, GC_GLASS)
		kit_window(tc, g + 12.15, 2.95, Win.FRAMED, GC_TRIM, GC_GLASS, 0.84)
		for pu: float in [0.42, 1.05, wt - 1.05, wt - 0.42]:
			kit_pilaster(pu, g + 5.75, g + 17.0, GC_WALL.lightened(0.06), 0.48, 0.14)
		kit_attic(0.0, wt, g + GC_EAVE_H, GC_WALL, GC_ATTIC_H, Attic.WALL)
		_gc_set_frame(m)
	# Side return attics on the flanking risalit towers (so the attic wraps cleanly back to v = 0).
	for side_cfg: Array in [[ru0, 0.0, rvt, -(m["a"] as Vector2)], [ru1, 0.0, rvt, m["a"] as Vector2]]:
		var su: float = side_cfg[0]
		var out_s: Vector2 = side_cfg[3]
		var ws := _gc_front_edge(_w(su, side_cfg[1]), _w(su, side_cfg[2]), out_s)
		kit_attic(0.0, ws, g + GC_EAVE_H, GC_WALL, GC_ATTIC_H, Attic.WALL)
		_gc_set_frame(m)


## Dresses every outer facade of Gmach Chemii: Noakowskiego main wings with rusticated ground
## floors and arched upper windows, four corner pavilions with paired giant pilasters and attics,
## and side and rear wings with regular window grids.
func _gc_dress_outer(m: Dictionary, g: float) -> void:
	_gc_set_frame(m)
	var fhw: float = m["front_hw"]
	var u_se: float = m["u_se"]
	var u_nw: float = m["u_nw"]
	var s_se: float = m["side_se"]
	var s_nw: float = m["side_nw"]
	var ru0: float = m["ris_u0"]
	var ru1: float = m["ris_u1"]
	var fpf: float = m["v_fpav_front"]
	var fpb: float = m["v_fpav_back"]
	var rpf: float = m["v_rpav_front"]
	var vbw: float = m["v_back_wing"]
	var vbp: float = m["v_back_pav"]
	var rse: float = m["rpav_se_u"]
	var rnw: float = m["rpav_nw_u"]
	var a_nw: Vector2 = m["a"]
	var b_ne: Vector2 = m["b"]
	# Front Noakowskiego main wings (6 bays each, ~3.8 m spacing, round-top upper windows between giant pilasters).
	for span: Array in [[-fhw, ru0], [ru1, fhw]]:
		var wf := _gc_front_edge(_w(span[0], 0.0), _w(span[1], 0.0), b_ne)
		var g_cs := kit_window_grid(0.95, wf - 0.95, 6, [g + 1.45], 2.90, Win.SILL, GC_TRIM, GC_GLASS, 0.74)
		_gc_rusticate_piers(0.12, wf - 0.12, g_cs, 1.06, g + 0.95, g + 5.25)
		for wu: float in g_cs:
			kit_round_window(_w(wu, 0.0), _a, _b, g + 6.30, g + 9.05, 0.78, GC_TRIM, GC_GLASS)
			kit_round_window(_w(wu, 0.0), _a, _b, g + 12.10, g + 14.65, 0.76, GC_TRIM, GC_GLASS)
		for k in g_cs.size() - 1:
			var pu := (g_cs[k] + g_cs[k + 1]) * 0.5
			kit_pilaster(pu, g + 5.75, g + 17.0, GC_WALL.lightened(0.08), 0.48, 0.14)
		_gc_set_frame(m)
	# Front wing side returns stepping back to the front corner pavilions.
	for ret: Array in [[-fhw, fpf, 0.0, -a_nw], [fhw, fpf, 0.0, a_nw]]:
		var wr := _gc_front_edge(_w(ret[0], ret[1]), _w(ret[0], ret[2]), ret[3])
		kit_window_grid(1.1, wr - 1.1, 1, [g + 1.45, g + 6.30, g + 12.05], [2.8, 3.1, 3.1], Win.SILL, GC_TRIM, GC_GLASS, 0.74)
		_gc_set_frame(m)
	# Front corner pavilions (NE street-facing fronts with paired giant pilasters, round-top windows, attic).
	for fp: Array in [[u_se, -fhw], [fhw, u_nw]]:
		var wfp := _gc_front_edge(_w(fp[0], fpf), _w(fp[1], fpf), b_ne)
		var fp_cs := kit_window_grid(1.45, wfp - 1.45, 2, [g + 1.45], 2.85, Win.SILL, GC_TRIM, GC_GLASS, 0.72)
		_gc_rusticate_piers(0.12, wfp - 0.12, fp_cs, 1.04, g + 0.95, g + 5.25)
		for wu: float in fp_cs:
			kit_round_window(_w(wu, 0.0), _a, _b, g + 6.30, g + 9.05, 0.74, GC_TRIM, GC_GLASS)
			kit_round_window(_w(wu, 0.0), _a, _b, g + 12.10, g + 14.65, 0.72, GC_TRIM, GC_GLASS)
		for pu: float in [0.42, 1.02, wfp - 1.02, wfp - 0.42]:
			kit_pilaster(pu, g + 5.75, g + 17.0, GC_WALL.lightened(0.06), 0.46, 0.14)
		kit_attic(0.0, wfp, g + GC_EAVE_H, GC_WALL, GC_ATTIC_H, Attic.WALL)
		_gc_set_frame(m)
	# Front corner pavilions (NW & SE outer side faces with corner pilasters and attic).
	for fs: Array in [[u_se, fpb, fpf, -a_nw], [u_nw, fpb, fpf, a_nw]]:
		var wfs := _gc_front_edge(_w(fs[0], fs[1]), _w(fs[0], fs[2]), fs[3])
		var fs_cs := kit_window_grid(1.55, wfs - 1.55, 2, [g + 1.45], 2.80, Win.PLAIN, GC_TRIM, GC_GLASS, 0.72)
		kit_window_grid(1.55, wfs - 1.55, 2, [g + 6.30], 3.05, Win.SILL, GC_TRIM, GC_GLASS, 0.74)
		for wu: float in fs_cs:
			kit_window(wu, g + 12.05, 3.00, Win.PLAIN, GC_TRIM, GC_GLASS, 0.72, GC_TRIM)
		for pu: float in [0.45, wfs - 0.45]:
			kit_pilaster(pu, g + 5.75, g + 17.0, GC_WALL.lightened(0.06), 0.48, 0.13)
		kit_attic(0.0, wfs, g + GC_EAVE_H, GC_WALL, GC_ATTIC_H, Attic.WALL)
		_gc_set_frame(m)
	# Side wings (SE and NW outer flanks, 9 bays each).
	for sw: Array in [[s_se, rpf, fpb, -a_nw], [s_nw, rpf, fpb, a_nw]]:
		var wsw := _gc_front_edge(_w(sw[0], sw[1]), _w(sw[0], sw[2]), sw[3])
		var sw_cs := kit_window_grid(1.1, wsw - 1.1, 9, [g + 1.45], 2.75, Win.PLAIN, GC_TRIM, GC_GLASS, 0.72)
		kit_window_grid(1.1, wsw - 1.1, 9, [g + 6.35], 3.00, Win.SILL, GC_TRIM, GC_GLASS, 0.74)
		for wu: float in sw_cs:
			kit_window(wu, g + 12.10, 2.95, Win.PLAIN, GC_TRIM, GC_GLASS, 0.72, GC_TRIM)
		_gc_set_frame(m)
	# Rear corner pavilions (side faces and rear SW faces, corner pilasters and attic).
	for rs: Array in [[u_se, vbp, rpf, -a_nw], [u_nw, vbp, rpf, a_nw]]:
		var wrs := _gc_front_edge(_w(rs[0], rs[1]), _w(rs[0], rs[2]), rs[3])
		var rs_cs := kit_window_grid(1.5, wrs - 1.5, 2, [g + 1.45], 2.75, Win.PLAIN, GC_TRIM, GC_GLASS, 0.72)
		kit_window_grid(1.5, wrs - 1.5, 2, [g + 6.35], 3.00, Win.SILL, GC_TRIM, GC_GLASS, 0.74)
		for wu: float in rs_cs:
			kit_window(wu, g + 12.10, 2.95, Win.PLAIN, GC_TRIM, GC_GLASS, 0.72, GC_TRIM)
		for pu: float in [0.45, wrs - 0.45]:
			kit_pilaster(pu, g + 5.75, g + 17.0, GC_WALL.lightened(0.06), 0.50, 0.13)
		kit_attic(0.0, wrs, g + GC_EAVE_H, GC_WALL, GC_ATTIC_H, Attic.WALL)
		_gc_set_frame(m)
	for rb: Array in [[u_se, rse], [rnw, u_nw]]:
		var wrb := _gc_front_edge(_w(rb[0], vbp), _w(rb[1], vbp), -b_ne)
		var rb_cs := kit_window_grid(1.5, wrb - 1.5, 3, [g + 1.45], 2.75, Win.PLAIN, GC_TRIM, GC_GLASS, 0.72)
		kit_window_grid(1.5, wrb - 1.5, 3, [g + 6.35], 3.00, Win.SILL, GC_TRIM, GC_GLASS, 0.74)
		for wu: float in rb_cs:
			kit_window(wu, g + 12.10, 2.95, Win.PLAIN, GC_TRIM, GC_GLASS, 0.72, GC_TRIM)
		for pu: float in [0.45, wrb - 0.45]:
			kit_pilaster(pu, g + 5.75, g + 17.0, GC_WALL.lightened(0.06), 0.50, 0.13)
		kit_attic(0.0, wrb, g + GC_EAVE_H, GC_WALL, GC_ATTIC_H, Attic.WALL)
		_gc_set_frame(m)
	# Rear SW main wing (14 bays).
	var wrw := _gc_front_edge(_w(rse, vbw), _w(rnw, vbw), -b_ne)
	var rw_cs := kit_window_grid(1.2, wrw - 1.2, 14, [g + 1.45], 2.75, Win.PLAIN, GC_TRIM, GC_GLASS, 0.72)
	kit_window_grid(1.2, wrw - 1.2, 14, [g + 6.35], 3.00, Win.SILL, GC_TRIM, GC_GLASS, 0.74)
	for wu: float in rw_cs:
		kit_window(wu, g + 12.10, 2.95, Win.PLAIN, GC_TRIM, GC_GLASS, 0.72, GC_TRIM)
	_gc_set_frame(m)


## Dresses the inner courtyard walls and central inner courtyard block of Gmach Chemii with
## kit_panes and bold floor ledges.
func _gc_dress_court(m: Dictionary, g: float) -> void:
	_gc_set_frame(m)
	var cu0: float = m["cu0"]
	var cu1: float = m["cu1"]
	var cv0: float = m["cv0"]
	var cv1: float = m["cv1"]
	var nu0: float = m["in_nu0"]
	var nu1: float = m["in_nu1"]
	var iu0: float = m["in_u0"]
	var iu1: float = m["in_u1"]
	var nv_j: float = m["in_v_join"]
	var iv0: float = m["in_v0"]
	var a_nw: Vector2 = m["a"]
	var b_ne: Vector2 = m["b"]
	# Outer courtyard perimeter walls (front wing split around the inner block's connecting neck).
	var faces := [
		[_w(cu0, cv1), _w(nu0, cv1), -b_ne, 4, true],   # back of front wing SE of neck
		[_w(nu1, cv1), _w(cu1, cv1), -b_ne, 4, true],   # back of front wing NW of neck
		[_w(cu0, cv0), _w(cu1, cv0), b_ne, 13, true],   # inner face of rear wing (facing NE)
		[_w(cu0, cv0), _w(cu0, cv1), a_nw, 8, true],    # inner face of SE wing (facing NW)
		[_w(cu1, cv0), _w(cu1, cv1), -a_nw, 8, true],   # inner face of NW wing (facing SE)
		# Central inner courtyard block faces (plain courtyard panes + cornice/string courses).
		[_w(iu0, iv0), _w(iu1, iv0), -b_ne, 6, true],   # SW face of inner block
		[_w(iu0, iv0), _w(iu0, nv_j), -a_nw, 5, true],  # SE face of inner block
		[_w(iu1, iv0), _w(iu1, nv_j), a_nw, 5, true],   # NW face of inner block
		[_w(iu0, nv_j), _w(nu0, nv_j), b_ne, 1, false], # SE neck shoulder (facing NE)
		[_w(nu1, nv_j), _w(iu1, nv_j), b_ne, 1, false], # NW neck shoulder (facing NE)
		[_w(nu0, nv_j), _w(nu0, cv1), -a_nw, 1, false], # SE flank of connecting neck
		[_w(nu1, nv_j), _w(nu1, cv1), a_nw, 1, false],  # NW flank of connecting neck
	]
	var rows: Array = [g + 1.45, g + 6.40, g + 12.10]
	for cf: Array in faces:
		var wc := _gc_front_edge(cf[0], cf[1], cf[2])
		var cols := _spread(minf(1.2, wc * 0.25), wc - minf(1.2, wc * 0.25), int(cf[3]))
		var major: bool = cf[4]
		if major:
			kit_ledge(0.2, wc - 0.2, g + 5.45, 0.24, GC_TRIM, 0.13)
			kit_ledge(0.2, wc - 0.2, g + 11.20, 0.22, GC_TRIM, 0.13)
		kit_ledge(0.15, wc - 0.15, g + GC_EAVE_H - 0.35, 0.35, GC_TRIM, 0.24)
		kit_panes(cols, rows, 1.40, 2.70, GC_GLASS, 0.06)
		_gc_set_frame(m)


## Builds Gmach Chemii's flat-ish low dark grey roofs over all four outer wings and the central
## inner courtyard block, plus low flat attic tops over the central risalit and four corner pavilions.
func _gc_roofs(m: Dictionary, g: float) -> void:
	_gc_set_frame(m)
	var y0 := g + GC_EAVE_H
	var fhw: float = m["front_hw"]
	var u_se: float = m["u_se"]
	var u_nw: float = m["u_nw"]
	var s_se: float = m["side_se"]
	var s_nw: float = m["side_nw"]
	var ru0: float = m["ris_u0"]
	var ru1: float = m["ris_u1"]
	var mu0: float = m["mid_u0"]
	var mu1: float = m["mid_u1"]
	var rvt: float = m["ris_v_tower"]
	var rvm: float = m["ris_v_mid"]
	var fpf: float = m["v_fpav_front"]
	var fpb: float = m["v_fpav_back"]
	var rpf: float = m["v_rpav_front"]
	var vbw: float = m["v_back_wing"]
	var vbp: float = m["v_back_pav"]
	var cu0: float = m["cu0"]
	var cu1: float = m["cu1"]
	var cv0: float = m["cv0"]
	var cv1: float = m["cv1"]
	var nu0: float = m["in_nu0"]
	var nu1: float = m["in_nu1"]
	var iu0: float = m["in_u0"]
	var iu1: float = m["in_u1"]
	var nv_j: float = m["in_v_join"]
	var iv0: float = m["in_v0"]
	# Four outer wing flat-ish low dark grey roofs (low pitched frustum with broad flat top).
	_mode = M_STONE
	var roof_top := GC_ROOF.darkened(0.06)
	var wing_rects := [
		[-fhw + 0.25, fhw - 0.25, cv1 + 0.25, -0.25],
		[s_se + 0.25, cu0 - 0.25, rpf + 0.25, fpb - 0.25],
		[cu1 + 0.25, s_nw - 0.25, rpf + 0.25, fpb - 0.25],
		[cu0 + 0.25, cu1 - 0.25, vbw + 0.25, cv0 - 0.25],
	]
	for wr: Array in wing_rects:
		var r0 := _gc_ccw(_urect(float(wr[0]), float(wr[1]), float(wr[2]), float(wr[3])))
		var r1 := _gc_ccw(_urect(float(wr[0]) + 2.0, float(wr[1]) - 2.0, float(wr[2]) + 2.0, float(wr[3]) - 2.0))
		_frustum(r0, y0, r1, y0 + GC_ROOF_H, GC_ROOF, roof_top)
	# Central inner courtyard block flat-ish dark grey roof, connecting neck roof, and central skylight box.
	var in_r0 := _gc_ccw(_urect(iu0 + 0.25, iu1 - 0.25, iv0 + 0.25, nv_j - 0.25))
	var in_r1 := _gc_ccw(_urect(iu0 + 2.2, iu1 - 2.2, iv0 + 2.2, nv_j - 2.2))
	_frustum(in_r0, y0, in_r1, y0 + GC_ROOF_H, GC_ROOF, roof_top)
	_ubox(nu0 + 0.25, nu1 - 0.25, nv_j - 0.35, cv1 + 0.65, y0, y0 + GC_ROOF_H * 0.85, GC_ROOF, M_STONE, roof_top)
	_lbox((iu0 + iu1) * 0.5, (iv0 + nv_j) * 0.5, 1.95, 1.40, y0 + GC_ROOF_H - 0.05,
			y0 + GC_ROOF_H + 0.90, GC_ROOF.lightened(0.08), M_STONE, PAL_GLASS_PALE)
	# Small pale-grey rooftop chimney/vent stacks along the SW rear wing and NE front wing (3D Tiles).
	var vent_col := GC_TRIM.darkened(0.10)
	for vu: float in [-20.0, -7.0, 7.0, 20.0]:
		_lbox(vu, (vbw + cv0) * 0.5, 0.70, 0.55, y0 + GC_ROOF_H - 0.05, y0 + GC_ROOF_H + 1.05,
				vent_col, M_STONE, GC_ROOF)
	for vu: float in [-22.0, 22.0]:
		_lbox(vu, (cv1 + 0.0) * 0.5, 0.75, 0.55, y0 + GC_ROOF_H - 0.05, y0 + GC_ROOF_H + 0.95,
				vent_col, M_STONE, GC_ROOF)
	# Flat attic coping roofs over the projecting central risalit and four corner pavilions.
	var coping := GC_WALL.darkened(0.06)
	var flat_top := GC_ROOF.darkened(0.14)
	_ubox(ru0 + 0.22, mu0 - 0.22, 0.20, rvt - 0.22, y0, y0 + 0.82, coping, M_STONE, flat_top)
	_ubox(mu1 + 0.22, ru1 - 0.22, 0.20, rvt - 0.22, y0, y0 + 0.82, coping, M_STONE, flat_top)
	_ubox(mu0 + 0.15, mu1 - 0.15, 0.20, rvm - 0.22, y0, y0 + 0.72, coping, M_STONE, flat_top)
	# Four corner pavilion flat attic tops (each inset 0.22 m inside its attic parapet).
	_ubox(u_se + 0.22, -fhw - 0.22, fpb + 0.22, fpf - 0.22, y0, y0 + 0.82, coping, M_STONE, flat_top)
	_ubox(fhw + 0.22, u_nw - 0.22, fpb + 0.22, fpf - 0.22, y0, y0 + 0.82, coping, M_STONE, flat_top)
	_ubox(u_se + 0.22, cu0 - 0.22, vbp + 0.22, rpf - 0.22, y0, y0 + 0.82, coping, M_STONE, flat_top)
	_ubox(cu1 + 0.22, u_nw - 0.22, vbp + 0.22, rpf - 0.22, y0, y0 + 0.82, coping, M_STONE, flat_top)


# --- Instytut Techniki Cieplnej PW (Nowowiejska 21/25) ------------------------------------------
# Spec docs/landmarks/specs/instytut_techniki_cieplnej.md: 1950s socialist-realist block.
# Six-storey pale beige front block (20.5 m) on Nowowiejska with light stone rusticated ground
# floor, strict window grid, central stone portal with three wooden doors, plain frieze (no
# lettering) and broad front steps, two dark sloping canopies over side entrances, flat-roofed
# four-storey East and West back wings (14.0 m), and a low industrial hall (9.2 m) with long
# parallel skylight roof strips filling the courtyard between them.

const ITC_NAME := "Instytut Techniki Cieplnej"
const ITC_WALL := Color("#d8cfb9")         # pale beige render (spec)
const ITC_BASE := Color("#e6e1d4")         # light stone ground floor (spec)
const ITC_PORTAL := Color("#ece8de")       # tall stone portal (spec)
const ITC_TRIM := Color("#f1eee6")         # white frames, ledges and cornice (spec)
const ITC_ROOF := Color("#5d6266")         # dark grey flat roofs and industrial hall roof (3D Tiles)
const ITC_ROOF_WEST := Color("#787c80")    # slightly paler grey flat membrane on west back wing (3D Tiles)
const ITC_SKYLIGHT := Color("#8fa3ad")     # skylight glass strips over industrial hall (3D Tiles)
const ITC_FRAME := Color("#3f4448")        # dark steel skylight framing and roof monitors
const ITC_GLASS := Color("#4a5660")        # window glass (spec)
const ITC_DOOR := Color("#6b4a32")         # wooden doors (spec)
const ITC_CANOPY := Color("#3e4448")       # dark grey-glass canopies (spec)
const ITC_GLOW := Color("#ffd9a0")         # warm night portal glow (M_LAMP / M_PAVILION)
const ITC_FRONT_H := 20.5                  # front block eaves height (6 storeys)
const ITC_BACK_H := 14.0                   # back wings eaves height (4 storeys, flat-roofed)
const ITC_HALL_H := 9.2                    # courtyard industrial hall eaves height (3D Tiles)


## Finds Instytut Techniki Cieplnej's OSM outline and registers the `itc` site with a 0.5 m
## outward zone offset so the map's plain prisms under it are replaced cleanly.
func _find_itc() -> void:
	var raw := _landmark(ITC_NAME)
	if raw.size() < 3:
		push_error("itc: landmark outline '%s' is missing from centrum.json" % ITC_NAME)
		return
	var zone := _largest(Geometry2D.offset_polygon(raw, 0.5, Geometry2D.JOIN_MITER))
	if zone.size() < 3:
		zone = raw
	_add_site("itc", [zone])
	if not sites.is_empty() and sites[-1]["key"] == "itc":
		sites[-1]["raw"] = raw


## Builds Instytut Techniki Cieplnej from its mapped outline: six-storey pale beige front block
## on Nowowiejska with strict window grid, central stone portal with three wooden doors, plain
## frieze and broad steps, two dark sloping canopies over side entrances, lower four-storey back
## wings round an inner courtyard under low grey hipped roofs, and outline collision.
func _build_itc(site: Dictionary) -> void:
	var raw: PackedVector2Array = site.get("raw", PackedVector2Array())
	if raw.size() < 3:
		return
	var m := _itc_frame(raw)
	if m.is_empty():
		return
	var g := _ground_under(raw)
	_g = g
	_mode = M_STONE
	_itc_set_frame(m)
	_itc_front_block(m, g)
	_itc_portal(m, g)
	_itc_canopies(m, g)
	_itc_back_wings(m, g)
	_collide(raw)
	_mode = M_STONE


## Restores ITC's main local frame (+u E->W along Nowowiejska, +v outward North).
func _itc_set_frame(m: Dictionary) -> void:
	_o = m["o"]
	_a = m["a"]
	_b = m["b"]
	kit_face(0.0)


## Starts a kit_front along edge a->b oriented so _b aligns with the outward normal `out`.
func _itc_front_edge(a: Vector2, b: Vector2, out: Vector2) -> float:
	var dir := (b - a).normalized()
	if Vector2(-dir.y, dir.x).dot(out) < 0.0:
		return kit_front(b, a)
	return kit_front(a, b)


## Returns a counter-clockwise copy of `ring` for _prism and _cap.
func _itc_ccw(ring: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array(ring)
	if Geometry2D.is_polygon_clockwise(out):
		out.reverse()
	return out


## Derives ITC's local frame (+u along Nowowiejska E->W, +v outward North) and measures the front
## block, wider rear wings and recessed south wall directly from the 33-node OSM outline.
func _itc_frame(raw: PackedVector2Array) -> Dictionary:
	var poly := _itc_ccw(raw)
	var n := poly.size()
	var want_n := Vector2(0.052, -0.999).normalized()
	var front_pts: Array[Vector2] = []
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		if a.distance_to(b) > 20.0 and _out(poly, a, b).dot(want_n) > 0.90:
			front_pts.append(a)
			front_pts.append(b)
	if front_pts.size() < 2:
		return {}
	# Extreme West (smaller x) and East (larger x) ends of the Nowowiejska front run.
	var p_w := front_pts[0]
	var p_e := front_pts[0]
	for p in front_pts:
		if p.x < p_w.x:
			p_w = p
		if p.x > p_e.x:
			p_e = p
	var axis_a := (p_w - p_e).normalized()
	var out_b := Vector2(-axis_a.y, axis_a.x)
	var origin := (p_w + p_e) * 0.5
	_o = origin
	_a = axis_a
	_b = out_b
	var front_hw := p_w.distance_to(p_e) * 0.5
	var u_min := INF
	var u_max := -INF
	var v_min := INF
	var v_front_back := -15.35
	var south_rec_v := -74.70
	var rec_u0 := -13.80
	var rec_u1 := 13.75
	for p in poly:
		var l := _local(p)
		u_min = minf(u_min, l.x)
		u_max = maxf(u_max, l.x)
		v_min = minf(v_min, l.y)
		if l.y < -12.0 and l.y > -18.0 and absf(l.x) > front_hw - 1.0:
			v_front_back = minf(v_front_back, l.y)
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var ln := a.distance_to(b)
		var out := _out(poly, a, b)
		var ml := _local((a + b) * 0.5)
		if ln > 7.0 and out.dot(-out_b) > 0.90 and ml.y > v_min + 2.5 and ml.y < v_min + 7.5:
			south_rec_v = ml.y
	var cu0 := rec_u0
	var cu1 := rec_u1
	var cv0 := south_rec_v
	var cv1 := v_front_back
	return {
		"o": origin, "a": axis_a, "b": out_b,
		"front_hw": front_hw,
		"v_fb": v_front_back,
		"back_u_e": u_min, "back_u_w": u_max,
		"back_v_s": v_min,
		"south_rec_v": south_rec_v,
		"rec_u0": rec_u0, "rec_u1": rec_u1,
		"cu0": cu0, "cu1": cu1,
		"cv0": cv0, "cv1": cv1,
	}


## Draws horizontal stone cladding grooves (kit_bands) on ITC's ground-floor wall piers between
## window and door openings so grooves never overlap panes or portal surrounds.
func _itc_rusticate_piers(u0: float, u1: float, skips: Array, y0: float, y1: float) -> void:
	var cur := u0
	for sp: Vector2 in skips:
		if sp.x - cur > 0.35:
			kit_bands(cur + 0.08, sp.x - 0.08, y0, y1, 1.05, ITC_BASE)
		cur = maxf(cur, sp.y)
	if u1 - cur > 0.35:
		kit_bands(cur + 0.08, u1 - 0.08, y0, y1, 1.05, ITC_BASE)


## Builds ITC's six-storey Nowowiejska front block (0-20.5 m) with light stone ground floor,
## pale beige upper storeys, strict 19-bay window grid, string courses, crowning cornice, low
## 2.5 m grey hipped roof and courtyard-facing back panes.
func _itc_front_block(m: Dictionary, g: float) -> void:
	_itc_set_frame(m)
	var fhw: float = m["front_hw"]
	var v_fb: float = m["v_fb"]
	var cu0: float = m["cu0"]
	var cu1: float = m["cu1"]
	var out_n: Vector2 = m["b"]
	var a_w: Vector2 = m["a"]
	var none := Color(0, 0, 0, 0)
	var ring := _itc_ccw(_urect(-fhw, fhw, v_fb, 0.0))
	var top := g + ITC_FRONT_H
	_prism(ring, g - 0.5, g + 4.5, ITC_BASE, none, M_STONE)
	_prism(ring, g + 4.5, top, ITC_WALL, ITC_ROOF, M_STONE, M_STONE)
	kit_ledge_ring(ring, g + 7.68, 0.28, ITC_TRIM, 0.15)
	kit_cornice_ring(ring, top - 0.60, ITC_TRIM, 0.60, 0.55)
	# Low perimeter parapet and small rooftop plant boxes on the flat front block roof (3D Tiles).
	var pw := 0.45
	var para_h := 0.55
	_ubox(-fhw, fhw, -pw, 0.0, top, top + para_h, ITC_TRIM)
	_ubox(-fhw, fhw, v_fb, v_fb + pw, top, top + para_h, ITC_TRIM)
	_ubox(-fhw, -fhw + pw, v_fb + pw, -pw, top, top + para_h, ITC_TRIM)
	_ubox(fhw - pw, fhw, v_fb + pw, -pw, top, top + para_h, ITC_TRIM)
	for ux: float in [-21.0, -10.5, 0.0, 10.5, 21.0]:
		_lbox(ux, v_fb * 0.5, 2.2, 1.3, top, top + 0.90, ITC_BASE.darkened(0.08), M_STONE, ITC_ROOF.lightened(0.10))
	# Nowowiejska north front: 19 strict 3.2 m bays across 63.5 m.
	var wf := _itc_front_edge(_w(-fhw, 0.0), _w(fhw, 0.0), out_n)
	var cu := wf * 0.5
	# Split ground-floor string course around the 12 m central portal so nothing z-fights.
	kit_ledge(0.0, cu - 6.08, g + 4.44, 0.28, ITC_TRIM, 0.14)
	kit_ledge(cu + 6.08, wf, g + 4.44, 0.28, ITC_TRIM, 0.14)
	var upper_sills: Array = [g + 5.20, g + 8.40, g + 11.60, g + 14.80, g + 18.00]
	# Ground floor windows: skip the 3 portal bays (8, 9, 10) and the 2 side-door bays (3, 15).
	var gf_skip: Array = [Vector2i(3, 0), Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(15, 0)]
	var bays := kit_window_grid(1.40, wf - 1.40, 19, [g + 1.45], 2.40, Win.SILL, ITC_TRIM, ITC_GLASS, 0.65, gf_skip)
	# Five upper storeys: strict 19-bay grid with individual white sills and window sashes.
	for sy_var in upper_sills:
		var sy := float(sy_var)
		for bu: float in bays:
			kit_window(bu, sy, 1.90, Win.SILL, ITC_TRIM, ITC_GLASS, 0.65, ITC_TRIM)
	# Rustication grooves on ground-floor stone piers between openings and outside the portal.
	var band_skips: Array = []
	for k in bays.size():
		if k == 8 or k == 9 or k == 10:
			continue
		var hw_gap := 1.15 if (k == 3 or k == 15) else 0.96
		band_skips.append(Vector2(bays[k] - hw_gap, bays[k] + hw_gap))
	band_skips.append(Vector2(cu - 6.15, cu + 6.15))
	band_skips.sort_custom(func(x: Vector2, y: Vector2) -> bool: return x.x < y.x)
	_itc_rusticate_piers(0.10, wf - 0.10, band_skips, g + 1.25, g + 4.35)
	# Save the exact side-entrance bay u-positions in front-block coordinates for the two canopies.
	m["canopy_u_e"] = -fhw + bays[3]
	m["canopy_u_w"] = -fhw + bays[15]
	_itc_set_frame(m)
	# East and West ends of the six-storey front block (4 bays x 6 storeys).
	for end_cfg: Array in [[-fhw, -a_w], [fhw, a_w]]:
		var eu: float = end_cfg[0]
		var out_e: Vector2 = end_cfg[1]
		var we := _itc_front_edge(_w(eu, v_fb), _w(eu, 0.0), out_e)
		var e_cols := _spread(1.4, we - 1.4, 4)
		kit_ledge(0.0, we, g + 4.44, 0.28, ITC_TRIM, 0.14)
		kit_panes(e_cols, [g + 1.45], 1.30, 2.35, ITC_GLASS, 0.06)
		kit_panes(e_cols, upper_sills, 1.30, 1.90, ITC_GLASS, 0.06)
		_itc_set_frame(m)
	# South face of the front block: visible panes above the 9.2 m courtyard hall and 14 m side wings.
	var wc := _itc_front_edge(_w(cu0, v_fb), _w(cu1, v_fb), -out_n)
	var c_cols := _spread(1.2, wc - 1.2, 8)
	kit_panes(c_cols, [g + 11.60], 1.30, 1.90, ITC_GLASS, 0.06)
	_itc_set_frame(m)
	var w_back_top := _itc_front_edge(_w(-fhw, v_fb), _w(fhw, v_fb), -out_n)
	var top_cols := _spread(1.4, w_back_top - 1.4, 18)
	kit_panes(top_cols, [g + 14.80, g + 18.00], 1.30, 1.90, ITC_GLASS, 0.06)
	_itc_set_frame(m)


## Builds ITC's central 12 m pale stone portal on Nowowiejska (0-7.5 m, 0.6 m proud): broad
## steps rising 1.2 m over 4 m across ~30 m of the front with flanking plinth terraces, four
## stone piers, three tall wooden double doors, warm night lanterns and transoms, and a plain
## stone frieze (no lettering).
func _itc_portal(m: Dictionary, g: float) -> void:
	_itc_set_frame(m)
	var fhw: float = m["front_hw"]
	var wf := _itc_front_edge(_w(-fhw, 0.0), _w(fhw, 0.0), m["b"])
	var cu := wf * 0.5
	var proj := 0.60
	var hw := 6.0
	# Main stone portal surround box and projecting cornice cap (frieze stays completely plain).
	_kbox(cu - hw, cu + hw, -0.15, proj, g - 0.5, g + 7.05, ITC_PORTAL)
	_kbox(cu - hw - 0.22, cu + hw + 0.22, -0.15, proj + 0.32, g + 7.05, g + 7.52, ITC_TRIM)
	# Broad entrance steps rising 1.2 m over 4.0 m across the front, flanked by stone terraces.
	var step_top := g + 1.20
	for k in 6:
		var run_d := 4.0 * float(6 - k) / 6.0
		_kbox(cu - 8.2, cu + 8.2, proj - 0.05, proj + run_d, g - 0.35 + k * 0.20,
				g + 0.20 * float(k + 1), ITC_BASE.darkened(0.10))
	for s: float in [-1.0, 1.0]:
		var t0 := cu + s * 8.2
		var t1 := cu + s * 15.0
		_kbox(minf(t0, t1), maxf(t0, t1), -0.05, 3.10, g - 0.35, step_top, ITC_BASE.darkened(0.06))
		_kbox(minf(t0, t1), maxf(t0, t1), 2.85, 3.15, step_top, step_top + 0.22, ITC_TRIM)
	# Portal face: four stone piers, three tall wooden doors, warm night lanterns and transoms.
	kit_face(proj)
	for pu: float in [cu - 4.95, cu - 1.65, cu + 1.65, cu + 4.95]:
		kit_pilaster(pu, step_top, g + 5.75, ITC_PORTAL.lightened(0.03), 0.96, 0.22)
		_kbox(pu - 0.09, pu + 0.09, proj + 0.22, proj + 0.34, g + 3.70, g + 4.25, ITC_GLOW, M_LAMP)
	for du: float in [cu - 3.30, cu, cu + 3.30]:
		kit_door(du, step_top, 3.70, 0.96, ITC_TRIM, ITC_DOOR, false)
		_kbox(du - 0.86, du + 0.86, proj + 0.04, proj + 0.09, step_top + 3.05, step_top + 3.60, ITC_GLOW, M_PAVILION)
	kit_face(0.0)
	_itc_set_frame(m)


## Builds ITC's two dark sloping glass canopies (~8 x 4 m at 4.0-5.0 m) on slender steel posts
## over the side entrances near the front's ends.
func _itc_canopies(m: Dictionary, g: float) -> void:
	_itc_set_frame(m)
	var fhw: float = m["front_hw"]
	var wf := _itc_front_edge(_w(-fhw, 0.0), _w(fhw, 0.0), m["b"])
	var post_col := ITC_ROOF.darkened(0.18)
	var c_top := ITC_CANOPY.lightened(0.04)
	var c_bot := ITC_CANOPY.darkened(0.16)
	var c_edge := ITC_CANOPY.darkened(0.08)
	var out_n := Vector3(_b.x, 0.0, _b.y)
	var along_n := Vector3(_a.x, 0.0, _a.y)
	for key: String in ["canopy_u_e", "canopy_u_w"]:
		var cu_c: float = float(m.get(key, 0.0)) + fhw
		cu_c = clampf(cu_c, 5.0, wf - 5.0)
		# Stone landing slab grounding the side entrance door and the two canopy steel posts.
		_kbox(cu_c - 3.5, cu_c + 3.5, -0.05, 3.20, g - 0.35, g + 0.16, ITC_BASE.darkened(0.08))
		# Side entrance wooden door centred beneath the canopy.
		kit_door(cu_c, g + 0.16, 3.30, 0.88, ITC_TRIM, ITC_DOOR, false)
		# Thin sloping canopy slab: 8.0 m wide x 4.0 m deep, rising from 4.05 m at wall to 4.95 m out.
		var u0 := cu_c - 4.0
		var u1 := cu_c + 4.0
		var v0 := -0.05
		var v1 := 4.05
		var yb0 := g + 4.05
		var yt0 := g + 4.20
		var yb1 := g + 4.85
		var yt1 := g + 5.00
		var p_fn := func(u: float, v: float, y: float) -> Vector3:
			var q := _w(u, v)
			return Vector3(q.x, y, q.y)
		var b00: Vector3 = p_fn.call(u0, v0, yb0)
		var b10: Vector3 = p_fn.call(u1, v0, yb0)
		var b11: Vector3 = p_fn.call(u1, v1, yb1)
		var b01: Vector3 = p_fn.call(u0, v1, yb1)
		var t00: Vector3 = p_fn.call(u0, v0, yt0)
		var t10: Vector3 = p_fn.call(u1, v0, yt0)
		var t11: Vector3 = p_fn.call(u1, v1, yt1)
		var t01: Vector3 = p_fn.call(u0, v1, yt1)
		var n_top := (t10 - t00).cross(t01 - t00).normalized()
		if n_top.y < 0.0:
			n_top = -n_top
		_mode = M_STONE
		_quad(t00, t10, t11, t01, n_top, c_top)
		_quad(b00, b01, b11, b10, -n_top, c_bot)
		_quad(b01, b11, t11, t01, out_n, c_edge)
		_quad(b00, b01, t01, t00, -along_n, c_edge)
		_quad(b11, b10, t10, t11, along_n, c_edge)
		# Two slender steel posts standing cleanly on the entrance landing slab.
		for du: float in [-2.3, 2.3]:
			_lbox(cu_c + du, 2.55, 0.11, 0.11, g + 0.14, g + 4.62, post_col, M_STONE)
	_itc_set_frame(m)


## Builds ITC's flat-roofed four-storey East and West back wings (0-14.0 m) and the low industrial
## hall (0-9.2 m) with long parallel skylight roof strips filling the courtyard between them.
func _itc_back_wings(m: Dictionary, g: float) -> void:
	_itc_set_frame(m)
	var fhw: float = m["front_hw"]
	var v_fb: float = m["v_fb"]
	var u_e: float = m["back_u_e"]
	var u_w: float = m["back_u_w"]
	var v_s: float = m["back_v_s"]
	var rec_v: float = m["south_rec_v"]
	var rec_u0: float = m["rec_u0"]
	var rec_u1: float = m["rec_u1"]
	var out_n: Vector2 = m["b"]
	var a_w: Vector2 = m["a"]
	var none := Color(0, 0, 0, 0)
	var btop := g + ITC_BACK_H
	# Two flat-roofed four-storey flanking back wings (East and West), tucked 0.25 m into the front block.
	var east_ring := _itc_ccw(_lpoly([
		[u_e, v_fb], [-fhw - 0.05, v_fb], [-fhw - 0.05, v_fb + 0.25], [rec_u0, v_fb + 0.25],
		[rec_u0, v_s], [u_e, v_s],
	]))
	var west_ring := _itc_ccw(_lpoly([
		[rec_u1, v_fb + 0.25], [fhw + 0.05, v_fb + 0.25], [fhw + 0.05, v_fb], [u_w, v_fb],
		[u_w, v_s], [rec_u1, v_s],
	]))
	_prism(east_ring, g - 0.5, g + 3.8, ITC_BASE, none, M_STONE)
	_prism(east_ring, g + 3.8, btop, ITC_WALL, ITC_ROOF, M_STONE, M_STONE)
	_prism(west_ring, g - 0.5, g + 3.8, ITC_BASE, none, M_STONE)
	_prism(west_ring, g + 3.8, btop, ITC_WALL, ITC_ROOF_WEST, M_STONE, M_STONE)
	# Perimeter parapets and long central roof monitors on both flat-roofed back wings (3D Tiles top view).
	var pw := 0.45
	var para_h := 0.52
	for wing_cfg: Array in [[u_e, rec_u0, ITC_FRAME, ITC_ROOF.darkened(0.08)],
			[rec_u1, u_w, ITC_WALL.darkened(0.06), ITC_ROOF_WEST.lightened(0.08)]]:
		var wu0: float = wing_cfg[0]
		var wu1: float = wing_cfg[1]
		var mon_wall: Color = wing_cfg[2]
		var mon_top: Color = wing_cfg[3]
		_ubox(wu0, wu0 + pw, v_s, v_fb, btop, btop + para_h, ITC_TRIM)
		_ubox(wu1 - pw, wu1, v_s, v_fb, btop, btop + para_h, ITC_TRIM)
		_ubox(wu0 + pw, wu1 - pw, v_s, v_s + pw, btop, btop + para_h, ITC_TRIM)
		_lbox((wu0 + wu1) * 0.5, (v_s + v_fb) * 0.5, 3.1, (v_fb - v_s) * 0.38,
				btop, btop + 0.95, mon_wall, M_STONE, mon_top)
	var rows: Array = [g + 1.20, g + 4.40, g + 7.60, g + 10.80]
	# Outer faces of the four-storey East and West back wings: cornice, floor band and panes.
	var outer_faces := [
		[_w(u_e, v_s), _w(u_e, v_fb), -a_w, 17],         # East flank
		[_w(u_w, v_s), _w(u_w, v_fb), a_w, 17],          # West flank
		[_w(u_e, v_s), _w(rec_u0, v_s), -out_n, 5],      # South-East end face
		[_w(rec_u1, v_s), _w(u_w, v_s), -out_n, 5],      # South-West end face
		[_w(rec_u0, v_s), _w(rec_u0, rec_v), a_w, 1],    # Short inner SE south return
		[_w(rec_u1, v_s), _w(rec_u1, rec_v), -a_w, 1],   # Short inner SW south return
	]
	for of: Array in outer_faces:
		var wo := _itc_front_edge(of[0], of[1], of[2])
		var cols := _spread(minf(1.1, wo * 0.28), wo - minf(1.1, wo * 0.28), int(of[3]))
		kit_ledge(0.0, wo, g + 3.76, 0.24, ITC_TRIM, 0.13)
		kit_cornice(minf(0.50, wo * 0.15), wo - minf(0.50, wo * 0.15), btop - 0.45, ITC_TRIM, 0.45, 0.42)
		kit_panes(cols, rows, 1.30, 1.90, ITC_GLASS, 0.06)
		_itc_set_frame(m)
	# Short North-facing shoulders where the wider back wings step out past the front block.
	for sh: Array in [[u_e, -fhw], [fhw, u_w]]:
		var wsh := _itc_front_edge(_w(sh[0], v_fb), _w(sh[1], v_fb), out_n)
		kit_ledge(0.0, wsh, g + 3.76, 0.24, ITC_TRIM, 0.13)
		kit_cornice(0.45, wsh - 0.45, btop - 0.45, ITC_TRIM, 0.45, 0.42)
		_itc_set_frame(m)
	# Visible upper storey of inner courtyard walls (above the 9.2 m industrial hall).
	for cf: Array in [[_w(rec_u0, rec_v), _w(rec_u0, v_fb), a_w], [_w(rec_u1, rec_v), _w(rec_u1, v_fb), -a_w]]:
		var wc := _itc_front_edge(cf[0], cf[1], cf[2])
		var cols := _spread(1.4, wc - 1.4, 14)
		kit_ledge(0.2, wc - 0.2, btop - 0.32, 0.32, ITC_TRIM, 0.24)
		kit_panes(cols, [g + 10.80], 1.30, 1.90, ITC_GLASS, 0.06)
		_itc_set_frame(m)
	# Low industrial hall with parallel skylight strips filling the courtyard between the back wings.
	_itc_hall(m, g)


## Builds ITC's low industrial hall (0-9.2 m) filling the courtyard between the East and West back
## wings, with long parallel pitched skylight roof strips (glass #8fa3ad over dark grey #5d6266),
## a central mechanical penthouse box, and an industrial glazed south elevation.
func _itc_hall(m: Dictionary, g: float) -> void:
	_itc_set_frame(m)
	var rec_u0: float = m["rec_u0"]
	var rec_u1: float = m["rec_u1"]
	var rec_v: float = m["south_rec_v"]
	var v_fb: float = m["v_fb"]
	var out_n: Vector2 = m["b"]
	var htop := g + ITC_HALL_H
	var none := Color(0, 0, 0, 0)
	# Solid hall body spanning the full courtyard between the East and West wings (rec_u0..rec_u1).
	var hall_ring := _itc_ccw(_urect(rec_u0, rec_u1, rec_v, v_fb))
	_prism(hall_ring, g - 0.5, g + 3.8, ITC_BASE, none, M_STONE)
	_prism(hall_ring, g + 3.8, htop, ITC_WALL, ITC_ROOF, M_STONE, M_STONE)
	# Low parapet along the south edge of the industrial hall roof.
	_ubox(rec_u0, rec_u1, rec_v, rec_v + 0.45, htop, htop + 0.48, ITC_TRIM)
	# South industrial hall facade: wide factory window panes and cornice band.
	var ws := _itc_front_edge(_w(rec_u0, rec_v), _w(rec_u1, rec_v), -out_n)
	var scols := _spread(1.6, ws - 1.6, 6)
	kit_ledge(0.1, ws - 0.1, g + 3.76, 0.24, ITC_TRIM, 0.13)
	kit_ledge(0.1, ws - 0.1, htop - 0.34, 0.34, ITC_TRIM, 0.22)
	kit_panes(scols, [g + 1.35, g + 5.15], 2.55, 2.35, ITC_GLASS, 0.06)
	_itc_set_frame(m)
	# Seven full-width long parallel skylight roof strips running East-West across the main hall bay.
	var su0 := rec_u0 + 1.20
	var su1 := rec_u1 - 1.20
	var n_strips := 7
	for k in n_strips:
		var cv := lerpf(rec_v + 5.6, rec_v + 35.6, float(k) / float(n_strips - 1))
		_itc_skylight_strip(su0, su1, cv, 1.62, htop, 1.80)
	# Raised mechanical/ventilation penthouse box in the northern half of the hall, flanked by two
	# shorter skylight strips (matching the 3D Tiles top view).
	var cu := (rec_u0 + rec_u1) * 0.5
	var pent_v := rec_v + 41.6
	_lbox(cu, pent_v, 5.2, 3.8, htop, htop + 3.25, ITC_BASE.darkened(0.08), M_STONE, ITC_ROOF.lightened(0.06))
	_itc_skylight_strip(su0, cu - 6.0, pent_v, 1.48, htop, 1.55)
	_itc_skylight_strip(cu + 6.0, su1, pent_v, 1.48, htop, 1.55)
	# Two low plant units on the northern flat hall deck between the penthouse and the front block.
	for du: float in [-7.5, 7.5]:
		_lbox(cu + du, v_fb - 5.2, 2.8, 2.1, htop, htop + 1.15, ITC_FRAME.lightened(0.12), M_STONE, ITC_ROOF)


## Builds one pitched industrial skylight strip running East-West from u0 to u1 centred at cv,
## half-width hv, over a dark grey kerb at y0, rising `rise` m with glass #8fa3ad slopes and dark
## ridge/gable framing.
func _itc_skylight_strip(u0: float, u1: float, cv: float, hv: float, y0: float, rise: float) -> void:
	var kerb_h := 0.35
	var y_eave := y0 + kerb_h
	var y_top := y0 + rise
	_ubox(u0, u1, cv - hv, cv + hv, y0, y_eave, ITC_FRAME, M_STONE, ITC_ROOF)
	var at3 := func(u: float, v: float, y: float) -> Vector3:
		var p := _w(u, v)
		return Vector3(p.x, y, p.y)
	var p00: Vector3 = at3.call(u0, cv - hv, y_eave)
	var p10: Vector3 = at3.call(u1, cv - hv, y_eave)
	var p01: Vector3 = at3.call(u0, cv + hv, y_eave)
	var p11: Vector3 = at3.call(u1, cv + hv, y_eave)
	var r0: Vector3 = at3.call(u0, cv, y_top)
	var r1: Vector3 = at3.call(u1, cv, y_top)
	# Two smooth sloped glass planes (M_GLASS with roof UV = (-1,-1) so glass stays crisp #8fa3ad
	# without white diagonal shader lines, letting the parallel strips and dark ribs read cleanly).
	var keep := _mode
	_mode = M_GLASS
	var ns := (p10 - p00).cross(r0 - p00).normalized()
	if ns.y < 0.0:
		ns = -ns
	var nn := (p01 - p11).cross(r1 - p11).normalized()
	if nn.y < 0.0:
		nn = -nn
	_quad(p00, p10, r1, r0, ns, ITC_SKYLIGHT)
	_quad(p11, p01, r0, r1, nn, ITC_SKYLIGHT)
	# Dark grey gable end triangles and ridge cap beam.
	_mode = M_STONE
	var nw := Vector3(_a.x, 0.0, _a.y)
	_tri(p00, p01, r0, -nw, ITC_ROOF, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_tri(p10, p11, r1, nw, ITC_ROOF, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_beam(r0 + Vector3.UP * 0.04, r1 + Vector3.UP * 0.04, 0.14, ITC_FRAME)
	# Transverse dark framing ribs across the longer skylight strips.
	if u1 - u0 > 12.0:
		var n_ribs := 5
		for k in range(1, n_ribs):
			var u := lerpf(u0, u1, float(k) / float(n_ribs))
			var rp: Vector3 = at3.call(u, cv, y_top + 0.03)
			_beam(at3.call(u, cv - hv, y_eave + 0.03), rp, 0.09, ITC_FRAME)
			_beam(at3.call(u, cv + hv, y_eave + 0.03), rp, 0.09, ITC_FRAME)
	_mode = keep
