extends "res://scripts/landmarks/srodmiescie.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, the skyline's towers (TOWERS,
## Varso, Varso Place, the Rondo Daszyńskiego towers, Centrum LIM), Wola's office blocks, Arkadia
## and the north. Moved as it was from the one big file. landmarks.gd is the class the game makes;
## every file of game/scripts/landmarks/ is one link of its base chain (facade_kit.gd, common.gd,
## then the areas in the order of landmarks.gd's `extends` chain), so code here may use this file,
## common.gd and the facade kit, never another area: a helper two areas need goes to common.gd.


# --- Varso Tower ------------------------------------------------------------------------------

## Rebuilt 2026-11-15 from photos (refs/varso: seven Commons photos and F's seven in top-50 T01;
## spec docs/landmarks/specs/varso.md). The mapped parts give the massing: a parallelogram plan
## in three slabs stepping 177 / 205 / 230 m from Chmielna to the tracks, the 230 m top an L that
## wraps the sky garden on the 205 m roof, silver-grey piers at the steps rising past the roofs,
## and the crown strips (193-234 m) round the L's outer edges. Built over them: deep blue glass in
## a proud grey frame (a post every ~4.6 m, a transom every two storeys, 8.3 m, over the 12 m
## lobby), the crown's silver louvre bands with a glass band between, the glass parapets, the lit
## observation box at the far end of the top, the lobby's warm glass under its dark canopy, and the
## spire: a lattice mast from the crown with four round dish platforms, a pole to 310 m with its
## ring and lamp, floodlit white at night (the platforms glow).
const VARSO_GLASS := Color("#2a5c93")
const VARSO_FRAME := Color("#565c63")
const VARSO_PIER := Color("#959ba1")
const VARSO_LOUVRE := Color("#d3d8dc")
const VARSO_ROOF := Color("#5d6369")
const VARSO_STEEL := Color("#b9c0c8")
const VARSO_DISH := Color("#dfe4e9")
const VARSO_LOBBY := 12.0
const VARSO_STOREY2 := 8.3     # the frame's transom: every two storeys
const VARSO_BAY := 4.6         # the frame's posts
const VARSO_SPIRE_TOP := 310.0


func _build_varso(site: Dictionary) -> void:
	var zone: PackedVector2Array = site["zone"][0]
	_g = _ground_under(zone)
	var g := _g
	var spire := Vector2.INF
	var spire_h := 0.0
	var parts := _parts_in(zone, func(_b: Dictionary) -> bool: return true)
	var glass: Array[Dictionary] = []   # {"p": ring, "y0", "y1"} the blue curtain-wall masses
	var piers: Array[Dictionary] = []
	var crowns: Array[Dictionary] = []
	var low: Array[Dictionary] = []      # the lobby and the parapets
	for b in parts:
		var poly := _pts(b["p"])
		var lo := poly[0]
		var hi := poly[0]
		for q in poly:
			lo = lo.min(q)
			hi = hi.max(q)
		var h := float(b["h"])
		var mh := float(b["mh"])
		if (hi - lo).length() < 8.0 and h >= 230.0:
			# A piece of the spire or one of its rings: the tallest one marks where it stands.
			if h > spire_h:
				spire_h = h
				spire = _centre(poly)
			continue
		if h < 3.0:
			continue
		var ring := _varso_clean(poly)
		var item := {"p": ring, "y0": g + mh, "y1": g + h}
		if str(b["c"]).to_lower() == "#3f4140" and mh < 0.5 and h > 100.0:
			piers.append(item)
		elif mh >= 190.0 and mh < 200.0:
			crowns.append(item)
		elif h - mh > 20.0 and h > 100.0:
			# The small mapped slabs inside the facade (4 by 7 m) stay glass with no frame of their own.
			item["framed"] = _area(ring) > 80.0
			glass.append(item)
		else:
			low.append(item)
		if mh < 0.5 and h > 30.0:
			_collide(poly)
	# The piers first (drawn first, their faces win where a slab's wall shares the plane).
	for p: Dictionary in piers:
		_prism(p["p"], p["y0"] - 0.4, p["y1"], VARSO_PIER, VARSO_PIER.darkened(0.15), M_STONE, M_STONE)
		_varso_pier_light(p["p"], _centre(zone), p["y0"], p["y1"])
	# The crown strips: inside the slabs' outline, so only their screen over the top roof shows
	# (the louvre bands on the faces under it are the frame's, `_varso_crown_face`).
	var roof_top := 0.0
	for m: Dictionary in glass:
		roof_top = maxf(roof_top, float(m["y1"]))
	for c: Dictionary in crowns:
		var top: float = c["y1"]
		if top - roof_top > 0.5:
			_prism(c["p"], roof_top - 0.3, top, VARSO_LOUVRE, VARSO_LOUVRE.darkened(0.12), M_STONE, M_STONE)
			_mullions(c["p"], roof_top, top - 0.3, 1.2, 0.03, VARSO_LOUVRE.darkened(0.28))
	# The glass masses and their frame.
	for m: Dictionary in glass:
		_prism(m["p"], float(m["y0"]) - (0.4 if float(m["y0"]) - g < 0.5 else 0.0), m["y1"], VARSO_GLASS, VARSO_ROOF, M_GLASS, M_STONE)
	for m: Dictionary in glass:
		if m["framed"]:
			_varso_frame(m, glass, crowns)
	# The lobby (warm glass under a dark canopy) and the glass parapets on the roofs.
	for l: Dictionary in low:
		var y0: float = l["y0"]
		var y1: float = l["y1"]
		if y0 - g < 0.5 and y1 - g > 8.0:
			_prism(l["p"], y0 - 0.4, y1, VARSO_GLASS.lightened(0.15), VARSO_ROOF.darkened(0.2), M_PAVILION, M_STONE)
			kit_ledge_ring(l["p"], y1 - 0.5, 0.7, PAL_IRON, 1.4)
		elif y0 - g < 0.5:
			_prism(l["p"], y0 - 0.4, y1, PAL_DARK_STEEL, PAL_DARK_STEEL.darkened(0.1), M_STONE, M_STONE)
		else:
			_prism(l["p"], y0, y1, VARSO_GLASS.lightened(0.3), VARSO_ROOF, M_GLASS, M_STONE)
	# Krajobraz K3: the sky garden on the 205 m roof, round the 230 m top (varso_place.md G1-G4).
	for b in parts:
		if float(b["mh"]) < 0.5 and absf(float(b["h"]) - VARSO_GARDEN_H) < 0.5:
			for piece in _varso_open_roof(b, parts):
				_varso_garden(piece, g + VARSO_GARDEN_H, VARSO_GARDEN)
	if spire == Vector2.INF:
		return
	_varso_deck(spire, glass, g)
	_varso_spire(spire, g)


## A mapped outline without its small notches (Visvalingam: a corner whose triangle with its
## neighbours is under 3 m² goes), so the glass reads as the photos' clean planes and the frame
## runs straight along them.
func _varso_clean(poly: PackedVector2Array) -> PackedVector2Array:
	var pts := poly.duplicate()
	while pts.size() > 4:
		var best := -1
		var least := 3.0
		for i in pts.size():
			var a := pts[(i + pts.size() - 1) % pts.size()]
			var b := pts[i]
			var c := pts[(i + 1) % pts.size()]
			var area := absf((b - a).cross(c - a)) * 0.5
			if area < least:
				least = area
				best = i
		if best < 0:
			break
		pts.remove_at(best)
	return pts


## The grey frame over one glass mass: a post every ~VARSO_BAY m and at each corner, a transom
## every two storeys over the lobby, on every face (and every stretch of height) no other part of
## the tower stands in front of.
func _varso_frame(m: Dictionary, all: Array[Dictionary], crowns: Array[Dictionary]) -> void:
	var ring: PackedVector2Array = m["p"]
	var y0: float = m["y0"]
	var y1: float = m["y1"]
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 2.0:
			continue
		var out := _out(ring, a, b)
		# The heights of this face something else covers: a slab in front of it, or a crown strip
		# on it (the strips hug the outline just inside it), which dresses that stretch instead.
		var probe := (a + b) * 0.5 + out * 0.6
		var inner: Array[Vector2] = []
		for t: float in [0.25, 0.5, 0.75]:
			for depth: float in [0.3, 0.6, 1.0, 1.6]:
				inner.append(a.lerp(b, t) - out * depth)
		var spans: Array[Vector2] = [Vector2(y0, y1)]
		var crowned: Array[Vector2] = []
		for o: Dictionary in all + crowns:
			if o == m:
				continue
			var c0: float = o["y0"]
			var c1: float = o["y1"]
			if not Geometry2D.is_point_in_polygon(probe, o["p"]):
				if not crowns.has(o) or not inner.any(func(q: Vector2) -> bool: return Geometry2D.is_point_in_polygon(q, o["p"])):
					continue
				if minf(c1, y1) - maxf(c0, y0) > 0.5:
					crowned.append(Vector2(maxf(c0, y0), minf(c1, y1)))
			var next: Array[Vector2] = []
			for s in spans:
				if c1 <= s.x or c0 >= s.y:
					next.append(s)
					continue
				if c0 > s.x:
					next.append(Vector2(s.x, c0))
				if c1 < s.y:
					next.append(Vector2(c1, s.y))
			spans = next
		var d := (b - a) / length
		if Vector2(-d.y, d.x).dot(out) > 0.0:
			kit_front(a, b)
		else:
			kit_front(b, a)
		var n := maxi(1, roundi(length / VARSO_BAY))
		var keep := _mode
		_mode = M_STONE
		for s in spans:
			if s.y - s.x < 2.0:
				continue
			for k in n:
				_varso_post(length * float(k) / float(n), s.x, s.y)
			var y := _g + VARSO_LOBBY
			while y < s.y - 1.0:
				if y > s.x + 0.5:
					_varso_transom(length, y)
				y += VARSO_STOREY2
		for c in crowned:
			_varso_crown_face(length, c.x, c.y)
		_mode = keep


## One post of the frame at u on the current front: its face 0.34 m out, 0.44 m wide, and its
## two sides (no back, no top: the glass and the transoms close it).
func _varso_post(u: float, y0: float, y1: float) -> void:
	_wall(_w(u - 0.22, 0.34), _w(u + 0.22, 0.34), y0, y1, _b, VARSO_FRAME)
	_wall(_w(u - 0.22, -0.02), _w(u - 0.22, 0.34), y0, y1, -_a, VARSO_FRAME.darkened(0.12))
	_wall(_w(u + 0.22, 0.34), _w(u + 0.22, -0.02), y0, y1, _a, VARSO_FRAME.darkened(0.12))


## A transom of the frame across the current front at height y: its face 0.26 m out and 0.5 m
## tall (no top: two slabs' ends in one plane would give two tops in one place).
func _varso_transom(length: float, y: float) -> void:
	_wall(_w(0.0, 0.26), _w(length, 0.26), y - 0.25, y + 0.25, _b, VARSO_FRAME)


## The crown on the current front between y0 and y1 (absolute): the photos' silver louvre bands
## (193-204 m and 213.5 m to the top) as plates 0.12 m out with a rib every 1.2 m, the glass band
## between them left to the slab's own glass.
func _varso_crown_face(length: float, y0: float, y1: float) -> void:
	for band: Vector2 in [Vector2(_g + 193.0, _g + 204.0), Vector2(_g + 213.5, _g + 240.0)]:
		var b0 := maxf(band.x, y0)
		var b1 := minf(band.y, y1)
		if b1 - b0 < 0.5:
			continue
		_wall(_w(0.0, 0.12), _w(length, 0.12), b0, b1, _b, VARSO_LOUVRE)
		var n := maxi(1, roundi(length / 1.2))
		for k in range(1, n):
			var u := length * float(k) / float(n)
			_wall(_w(u - 0.07, 0.16), _w(u + 0.07, 0.16), b0 + 0.3, b1 - 0.3, _b, VARSO_LOUVRE.darkened(0.28))
		# The plate's ends and top.
		_wall(_w(0.0, -0.02), _w(0.0, 0.12), b0, b1, -_a, VARSO_LOUVRE.darkened(0.1))
		_wall(_w(length, 0.12), _w(length, -0.02), b0, b1, _a, VARSO_LOUVRE.darkened(0.1))


## The piers are floodlit at night (F's night photo: a white band up the step's edge): a lamp
## strip over the pier's outer end, the short face farthest from the tower's middle.
func _varso_pier_light(ring: PackedVector2Array, mid: Vector2, y0: float, y1: float) -> void:
	var best := -1
	var far := -1.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if a.distance_to(b) > 2.5:
			continue
		var d := ((a + b) * 0.5).distance_to(mid)
		if d > far:
			far = d
			best = i
	if best < 0:
		return
	var a := ring[best]
	var b := ring[(best + 1) % ring.size()]
	var out := _out(ring, a, b)
	var keep := _mode
	_mode = M_LAMP
	_wall(a + out * 0.04, b + out * 0.04, y0 + 3.0, y1 - 0.3, out, VARSO_DISH)
	_mode = keep


## The observation box at the far end of the top from the spire (F's photos: a glass room at the
## crown, lit cool at night): 5 by 5 m on the 230 m roof, 6 m tall, a dark lid.
func _varso_deck(spire: Vector2, glass: Array[Dictionary], g: float) -> void:
	var top: Dictionary = {}
	for m: Dictionary in glass:
		if top.is_empty() or float(m["y1"]) > float(top["y1"]):
			top = m
	if top.is_empty():
		return
	var ring: PackedVector2Array = top["p"]
	var far := 0
	for i in ring.size():
		if ring[i].distance_to(spire) > ring[far].distance_to(spire):
			far = i
	var p := ring[far]
	var e1 := (ring[(far + 1) % ring.size()] - p).normalized()
	var e2 := (ring[(far + ring.size() - 1) % ring.size()] - p).normalized()
	var box := PackedVector2Array([p + e1 * 1.2 + e2 * 1.2, p + e1 * 6.2 + e2 * 1.2, p + e1 * 6.2 + e2 * 6.2, p + e1 * 1.2 + e2 * 6.2])
	var y: float = top["y1"]
	_prism(box, y, y + 6.0, VARSO_GLASS.lightened(0.35), Color(0, 0, 0, 0), M_PAVILION + 0.5)
	_prism(_ring_out(box, 0.15), y + 6.0, y + 6.5, PAL_IRON, PAL_IRON, M_STONE, M_STONE)


## The spire (photos 2, 4, 7 and F's night shot): a square lattice mast from the crown to 274 m,
## its four legs and a zigzag brace on each face, round dish platforms at the mapped rings (240,
## 250, 260, 274 m) that glow white at night, a pole on to the top with a small ring at 294 m, the
## red aviation lamp.
func _varso_spire(at: Vector2, g: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var foot := g + 228.0
	var head := g + 274.0
	var corners := func(y: float) -> Array:
		var r := lerpf(1.5, 0.95, (y - foot) / (head - foot))
		var out := []
		for k in 4:
			var q := at + Vector2.from_angle(TAU * k / 4.0 + PI * 0.25) * r * 1.41
			out.append(Vector3(q.x, y, q.y))
		return out
	var lo: Array = corners.call(foot)
	var hi: Array = corners.call(head)
	for k in 4:
		_beam(lo[k], hi[k], 0.4, VARSO_STEEL)
	var panels := 11
	for j in panels:
		var ya := lerpf(foot, head, float(j) / panels)
		var yb := lerpf(foot, head, float(j + 1) / panels)
		var ca: Array = corners.call(ya)
		var cb: Array = corners.call(yb)
		for k in 4:
			var k2 := (k + 1) % 4
			if j % 2 == 0:
				_beam(ca[k], cb[k2], 0.2, VARSO_STEEL)
			else:
				_beam(ca[k2], cb[k], 0.2, VARSO_STEEL)
	for h: float in [240.0, 250.0, 260.0, 274.0]:
		var dish := _circle(at, 3.0 if h < 270.0 else 2.6, 12)
		_prism(dish, g + h - 0.7, g + h, VARSO_DISH, VARSO_DISH.darkened(0.08), M_LAMP, M_LAMP)
		_soffit(dish, g + h - 0.7, VARSO_DISH.darkened(0.25))
	_frustum(_circle(at, 0.45, 8), head, _circle(at, 0.18, 8), g + VARSO_SPIRE_TOP - 2.0, VARSO_STEEL)
	_prism(_circle(at, 1.1, 10), g + 293.5, g + 294.0, VARSO_DISH, VARSO_DISH, M_LAMP, M_STONE)
	_prism(_square(at, 0.3), g + VARSO_SPIRE_TOP - 2.0, g + VARSO_SPIRE_TOP - 0.7, Color("#ff3b30"), Color("#ff6a5c"), M_LAMP, M_LAMP)
	# The dusk loop: the aviation light on the spire's very top.
	_prism(_square(at, 0.25), g + VARSO_SPIRE_TOP - 0.7, g + VARSO_SPIRE_TOP, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	_mode = keep


# --- Varso Place (Krajobraz K3, docs/landmarks/specs/varso_place.md) -----------------------------

## Chmielna 69-73: the planting is RS Architektura Krajobrazu's (ZinCo: ~4,000 m² of green on the
## garage slabs and the roofs). The sky garden is on the tower's 205 m roof (16 hawthorns up to
## 6 m, perennials, dwarf pines, timber benches; HB Reavis, 2021); Varso 2 has green terraces and
## Varso 1 a roof terrace; a 60 t glacial erratic from the dig stands by the tower's entrance.
## The tower's garden is built with the tower (its card); the rest is the site `varso_place`, a
## 0.2 m zone at the erratic (nothing stands there) with a box over the three buildings, so Varso
## I and II stay the map's own extrusions and a sector that holds any of it builds it.
const VARSO_GARDEN_H := 205.0
const VARSO_BOX := Rect2(-1822.0, 530.0, 236.0, 178.0)
const VARSO_ROCK_AT := Vector2(-1600.5, 541.5)
const VARSO_SIGN_AT := Vector2(-1597.5, 553.5)
const VARSO_SIGN_ALONG := Vector2(0.35, 0.94)   # parallel to Al. Jana Pawła II, the letters face it

const VARSO_PINE := Color("#3d5b3b")
const VARSO_BEDS: Array[Color] = [Color("#7b8c4e"), Color("#6c8f4f"), Color("#8a8a58")]  # perennials, lawn, grasses

const VARSO_GRANITE := Color("#8e8a82")

const VARSO_RAIL := Color("#c9dcdc")
const VARSO_ROCK := Color("#867f74")
const VARSO_SIGN := Color(0.97, 0.94, 0.86)
## Each roof's planting: trees (at most), their height and crown radius, dwarf pines, benches,
## whether the edge has planters (the terrace kind) or one big bed (the garden kind).
const VARSO_GARDEN := {"trees": 16, "h": 5.8, "r": 2.0, "pines": 10, "benches": 4, "step": 4.6}
const VARSO_TERRACE := {"trees": 9, "h": 4.6, "r": 1.6, "pines": 4, "benches": 2, "step": 5.2}


func _find_varso_place() -> void:
	if _landmark("Varso I").size() < 3 or _landmark("Varso II").size() < 3:
		return
	var c := VARSO_ROCK_AT
	_add_site("varso_place", [PackedVector2Array([c, c + Vector2(0.2, 0), c + Vector2(0.2, 0.2), c + Vector2(0, 0.2)])])
	sites[-1]["box"] = VARSO_BOX


## The plaza's sign and the erratic (P1, P2), then the roof terraces on Varso 1 and 2 (T1-T3). No
## card: off the picking grid, a tap on the roofs finds what it found before.
func _build_varso_place(_site: Dictionary) -> void:
	_id = 0
	_varso_wings()
	_varso_sign()
	_varso_rock()
	for name: String in ["Varso I", "Varso II"]:
		var outline := _landmark(name)
		if outline.size() < 3:
			continue
		var g := _ground_under(outline)
		var parts := _parts_in(outline, func(b: Dictionary) -> bool: return float(b["h"]) > float(b["mh"]) + 0.5)
		for b in parts:
			if float(b["mh"]) > 0.5 or float(b["h"]) < 40.0:
				continue
			for piece in _varso_open_roof(b, parts):
				_varso_garden(piece, g + float(b["h"]), VARSO_TERRACE)


# --- Varso Place's office wings (F's photos, 2026-11-17; spec varso_place.md W1-W6) ---------------

## Varso 1 and 2 are each a glass tower on a lower office wing (HB Reavis, Foster + Partners,
## 2020-22): eight storeys in a cream stone frame (deep windows between square piers and
## spandrel bands), a set-back ninth storey of dark glass, roof terraces with planters and small
## trees behind a glass balustrade. OpenStreetMap maps the towers' parts but not the wings: the
## outline's area that no part covers is the wing (Varso 1's east of its tower, towards Varso
## Tower; Varso 2's west of its tower, round the glass-roofed atrium against the tower's face).
const VARSO_WING_STONE := Color("#e4ddcd")   # the warm cream stone (photos 2, 4, 6)
const VARSO_WING_GLASS := Color("#2c3946")   # the deep windows' dark blue-grey glass
const VARSO_WING_TOP := Color("#2a3038")     # the set-back top storey's dark glass
const VARSO_WING_ROOF := Color("#d3d4cf")    # its pale roof (photo 7)
const VARSO_ATRIUM := Color("#9fc0d8")       # the atrium's glass roof (photo 7)
const VARSO_WING_GF := 5.0      # the glazed ground floor
const VARSO_WING_FH := 3.9      # each office storey
const VARSO_WING_FLOORS := 8    # ground + 7 (the photos count eight rows of windows)
const VARSO_WING_BAY := 3.3     # pier to pier
## Per wing: the top storey's set-back from the faces, and whether it holds the atrium.
const VARSO_WINGS := {
	"Varso I": {"inset": 7.0, "atrium": 0.0},
	"Varso II": {"inset": 7.0, "atrium": 80.0},  # the atrium stands against the 80 m part's face
}


## W1-W6: each outline less every mapped part (5 m tall or more) standing in or by it, its
## small jogs smoothed, then the wing on each piece of 150 m² or more.
func _varso_wings() -> void:
	var tall: Array[PackedVector2Array] = []
	var tall_h: Array[float] = []
	var near := VARSO_BOX.grow(20.0)
	for b in data["buildings"]:
		if float(b["h"]) < 5.0 or float(b["mh"]) > 1.0:
			continue
		var q := _pts(b["p"])
		if q.size() >= 3 and near.has_point(_centre(q)):
			tall.append(q)
			tall_h.append(float(b["h"]))
	for name: String in VARSO_WINGS:
		var outline := _landmark(name)
		if outline.size() < 3:
			continue
		var whole := absf(_area(outline))
		var open: Array[PackedVector2Array] = [outline]
		for q in tall:
			if absf(_area(q)) > 0.8 * whole:
				continue
			var next: Array[PackedVector2Array] = []
			var cutter := _grown(q, 0.05)
			if cutter.size() < 3:
				continue
			for piece in open:
				for r in Geometry2D.clip_polygons(piece, cutter):
					if r.size() >= 3 and not Geometry2D.is_polygon_clockwise(r):
						next.append(r)
			open = next
		for piece in open:
			if absf(_area(piece)) >= 150.0:
				_varso_wing(_simplify(piece, 0.6), VARSO_WINGS[name], tall, tall_h)


## One wing: the glass body, its stone frame, the top storey, the terrace and (Varso 2) the atrium.
func _varso_wing(piece: PackedVector2Array, look: Dictionary, tall: Array[PackedVector2Array], tall_h: Array[float]) -> void:
	if Geometry2D.is_polygon_clockwise(piece):
		piece.reverse()
	var g := _ground_under(piece)
	_g = g
	var h := VARSO_WING_GF + VARSO_WING_FH * (VARSO_WING_FLOORS - 1)
	var body := piece
	var atrium := PackedVector2Array()
	if float(look["atrium"]) > 0.0:
		atrium = _varso_atrium(piece, float(look["atrium"]), tall, tall_h)
		if not atrium.is_empty():
			var best := 0.0
			for r in Geometry2D.clip_polygons(piece, atrium):
				if r.size() >= 3 and not Geometry2D.is_polygon_clockwise(r) and _area(r) > best:
					best = _area(r)
					body = r
	# W1 the body: dark glass (its lit bays at night), the timber deck on top.
	_prism(body, g - 0.4, g + h, VARSO_WING_GLASS, VARSO_DECK, M_SKIN + float(S_DARK) / 16.0, M_STONE)
	_collide(body)
	# W2 the stone frame: the spandrel bands round the whole ring (mitred, so no two tops
	# overlap), then the piers on every face that shows (not in the atrium, not inside a tower).
	var bands: Array[Vector2] = []
	for j in VARSO_WING_FLOORS - 1:
		var y := g + VARSO_WING_GF + VARSO_WING_FH * j
		bands.append(Vector2(y - 0.45, y + 0.8))
	bands.append(Vector2(g + h - 0.45, g + h + 0.3))
	for band in bands:
		# The parapet stands 0.5 m proud, over the piers' heads (0.45): they need no tops.
		_ring_slab(body, band.x, band.y, 0.5 if band == bands[-1] else 0.4, VARSO_WING_STONE)
	for i in body.size():
		var a := body[i]
		var b := body[(i + 1) % body.size()]
		if a.distance_to(b) < 2.0:
			continue
		var out := _out(body, a, b)
		var probe := (a + b) * 0.5 + out * 0.9
		if not atrium.is_empty() and Geometry2D.is_point_in_polygon(probe, atrium):
			continue
		var hidden := 0.0
		for k in tall.size():
			if Geometry2D.is_point_in_polygon(probe, tall[k]):
				hidden = maxf(hidden, tall_h[k])
		if hidden >= h:
			continue
		var prev := body[(i + body.size() - 1) % body.size()]
		var straight := _out(body, prev, a).dot(out) > 0.95  # the last face's end pier stands here
		_varso_piers(a, b, out, maxf(g, g + hidden - 0.5), g + h - 0.45, straight)
	# W3 the glass balustrade round the terrace, lit like the towers' terraces at night.
	var keep := _no_roof
	_no_roof = true
	var rail := _ring_out(body, 0.2)
	var rev := PackedVector2Array(rail)
	rev.reverse()
	_prism(rail, g + h + 0.3, g + h + 1.2, VARSO_RAIL, Color(0, 0, 0, 0), M_PAVILION + 0.5)
	_prism(rev, g + h + 0.3, g + h + 1.2, VARSO_RAIL, Color(0, 0, 0, 0), M_PAVILION + 0.5)
	_no_roof = keep
	# W4 the set-back top storey: dark glass under a stone cornice, a pale roof, a plant box.
	var tops: Array[PackedVector2Array] = []
	for r in Geometry2D.offset_polygon(body, -float(look["inset"]), Geometry2D.JOIN_MITER):
		if r.size() >= 3 and not Geometry2D.is_polygon_clockwise(r) and _area(r) >= 80.0:
			tops.append(_simplify(r, 0.4))
			var pent := tops[-1]
			_prism(pent, g + h, g + h + 3.6, VARSO_WING_TOP, Color(0, 0, 0, 0), M_SKIN + float(S_DARK) / 16.0)
			_prism(pent, g + h + 3.6, g + h + 4.1, VARSO_WING_STONE, VARSO_WING_ROOF, M_STONE, M_STONE)
			var c := _centre(pent)
			if Geometry2D.is_point_in_polygon(c, pent):
				_prism(_square(c, 2.2), g + h + 4.1, g + h + 5.6, VARSO_WING_ROOF.darkened(0.25), VARSO_WING_ROOF.darkened(0.1), M_STONE, M_STONE)
	# W5 the terrace's planters and small trees.
	_varso_wing_planters(body, tops, atrium, g + h, float(look["inset"]))
	# W6 the atrium's glass roof, a low pyramid just under the parapet.
	if not atrium.is_empty():
		var roof := PackedVector2Array()
		for r in Geometry2D.intersect_polygons(atrium, piece):
			if r.size() >= 3 and not Geometry2D.is_polygon_clockwise(r) and _area(r) > _area(roof):
				roof = r
		if roof.size() >= 3:
			_mode = M_GLASS_ROOF
			_pyramid(roof, g + h - 1.6, g + h + 0.6, VARSO_ATRIUM)
			_mode = M_STONE


## The atrium (photo 7): a rectangle against the face of the `part_h` part that looks into the
## wing, 26 m along it (less where the face is shorter) and 21 m into the wing; a metre into
## the tower so the cut leaves the wing a C, not a ring.
func _varso_atrium(piece: PackedVector2Array, part_h: float, tall: Array[PackedVector2Array], tall_h: Array[float]) -> PackedVector2Array:
	for k in tall.size():
		if absf(tall_h[k] - part_h) > 1.0:
			continue
		var part := tall[k]
		var i := _edge_facing(part, (_centre(piece) - _centre(part)).normalized(), 10.0)
		if i < 0:
			continue
		var a := part[i]
		var b := part[(i + 1) % part.size()]
		var t := (b - a).normalized()
		var o := _out(part, a, b)
		var m := (a + b) * 0.5
		var half := minf(13.0, a.distance_to(b) * 0.5 - 1.5)
		if half < 6.0:
			continue
		return PackedVector2Array([m - t * half - o, m + t * half - o, m + t * half + o * 21.0, m - t * half + o * 21.0])
	return PackedVector2Array()


## One face's piers from a to b (`out` its outward normal): square, 0.9 m wide and 0.45 m proud
## (the bands are 0.4), one every bay or so from y0 to y1, the ends at the corners; `straight`
## leaves out the first where the last face runs on in line (its own end pier stands there).
func _varso_piers(a: Vector2, b: Vector2, out: Vector2, y0: float, y1: float, straight: bool) -> void:
	var length := a.distance_to(b)
	var t := (b - a) / length
	var n := maxi(1, roundi(length / VARSO_WING_BAY))
	var last := -INF
	for k in n + 1:
		var c := clampf(length * k / n, 0.45, length - 0.45)
		if (k == 0 and straight) or c - last < 0.95:
			continue
		last = c
		_varso_box(a + t * (c - 0.45), a + t * (c + 0.45), out, 0.45, y0, y1)


## A pier standing on a face: from p to q along it, `depth` out, y0 to y1; its front and its two
## sides (the back is the wall, its head is under the parapet, its foot never shows).
func _varso_box(p: Vector2, q: Vector2, out: Vector2, depth: float, y0: float, y1: float) -> void:
	_mode = M_STONE
	var col := VARSO_WING_STONE
	var p1 := p + out * depth
	var q1 := q + out * depth
	var t := (q - p).normalized()
	var w := p.distance_to(q)
	var hy0 := y0 - _g
	var hy1 := y1 - _g
	var side := col.darkened(0.08)
	for f: Array in [[p1, q1, out, col, w], [p, p1, -t, side, depth], [q1, q, t, side, depth]]:
		var u: Vector2 = f[0]
		var v: Vector2 = f[1]
		var nn: Vector2 = f[2]
		var len_f: float = f[4]
		_quad(Vector3(u.x, y0, u.y), Vector3(v.x, y0, v.y), Vector3(v.x, y1, v.y), Vector3(u.x, y1, u.y), Vector3(nn.x, 0.0, nn.y), f[3],
				Vector2(0, hy0), Vector2(len_f, hy0), Vector2(len_f, hy1), Vector2(0, hy1), hy1)


## W5: planters in two rows round the terrace (photo 7), 2.4 m in from the parapet and 2 m
## short of the top storey, one every 5.5 m where the top storey, the atrium and the towers
## leave room: a granite box 4 x 1.8 m (perennials, lawn or grasses on top), a small
## round-crowned tree in every other one, a dwarf pine in the rest.
func _varso_wing_planters(body: PackedVector2Array, tops: Array[PackedVector2Array], atrium: PackedVector2Array, y: float, inset: float) -> void:
	var keep := _no_roof
	_no_roof = true
	var lines := Geometry2D.offset_polygon(body, -2.4, Geometry2D.JOIN_MITER)
	lines.append_array(Geometry2D.offset_polygon(body, -(inset - 2.0), Geometry2D.JOIN_MITER))
	var room := Geometry2D.offset_polygon(body, -0.9, Geometry2D.JOIN_MITER)
	var k := 0
	for line: PackedVector2Array in lines:
		if line.size() < 3 or Geometry2D.is_polygon_clockwise(line):
			continue
		var ring := _simplify(line, 0.4)
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			var length := a.distance_to(b)
			if length < 5.0:
				continue
			var t := (b - a) / length
			var o := Vector2(t.y, -t.x)
			var n := floori((length - 1.0) / 5.5)
			for j in n:
				var c := a + t * (length - (n - 1) * 5.5) * 0.5 + t * (j * 5.5)
				if not _varso_free(c, room, tops, atrium):
					continue
				var box := PackedVector2Array([c - t * 2.0 - o * 0.9, c + t * 2.0 - o * 0.9, c + t * 2.0 + o * 0.9, c - t * 2.0 + o * 0.9])
				_prism(box, y, y + 0.6, VARSO_GRANITE, VARSO_BEDS[k % VARSO_BEDS.size()], M_STONE, M_STONE)
				if k % 2 == 0:
					var jit := 0.9 + 0.2 * fposmod(sin(c.x * 12.9898 + c.y * 78.233) * 43758.5453, 1.0)
					_varso_tree(c, y + 0.6, 4.2 * jit, 1.6 * jit)
				else:
					_pyramid(_circle(c, 0.6, 5), y + 0.6, y + 1.8, VARSO_PINE)
				k += 1
	_no_roof = keep


## True where a planter at c stands clear: on the terrace, off the top storey (with a metre
## to walk) and off the atrium.
func _varso_free(c: Vector2, room: Array[PackedVector2Array], tops: Array[PackedVector2Array], atrium: PackedVector2Array) -> bool:
	var on := false
	for r in room:
		if not Geometry2D.is_polygon_clockwise(r) and Geometry2D.is_point_in_polygon(c, r):
			on = true
	if not on:
		return false
	for r in tops:
		if Geometry2D.is_point_in_polygon(c, r) or _dist_to_ring(c, r) < 1.4:
			return false
	return atrium.is_empty() or not (Geometry2D.is_point_in_polygon(c, atrium) or _dist_to_ring(c, atrium) < 1.5)


## The part of a flat roof nothing taller stands on or rises through (every part that starts
## no more than a metre above it and ends higher is cut away), as pieces of at least 60 m².
func _varso_open_roof(roof: Dictionary, parts: Array) -> Array[PackedVector2Array]:
	var h := float(roof["h"])
	var out: Array[PackedVector2Array] = [_pts(roof["p"])]
	for b: Dictionary in parts:
		if b == roof or float(b["mh"]) > h + 1.0 or float(b["h"]) <= h + 0.5:
			continue
		var over := _pts(b["p"])
		var next: Array[PackedVector2Array] = []
		for piece in out:
			for q in Geometry2D.clip_polygons(piece, over):
				if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
					next.append(q)
		out = next
	return out.filter(func(q: PackedVector2Array) -> bool: return _area(q) >= 60.0)


## A planted roof (G1-G4, T1-T3): a timber deck inside a glass balustrade, a raised bed of
## perennials and lawn 2.5 m in from the edge, trees with round crowns in it on a grid, dwarf
## pines between them, timber benches along the bed. Out of the roof grid (the helicopter and the
## crowds keep reading the roof itself).
func _varso_garden(roof: PackedVector2Array, y: float, look: Dictionary) -> void:
	var rims := Geometry2D.offset_polygon(roof, -0.5)
	if rims.is_empty():
		return
	var none := Color(0, 0, 0, 0)
	var keep := _no_roof
	_no_roof = true
	_mode = M_STONE
	for rim: PackedVector2Array in rims:
		if rim.size() < 3 or Geometry2D.is_polygon_clockwise(rim):
			continue
		var rev := PackedVector2Array(rim)
		rev.reverse()
		_cap(rim, y + 0.12, VARSO_DECK)
		_prism(rim, y, y + 1.1, VARSO_RAIL, none, M_PAVILION + 0.5)
		_prism(rev, y, y + 1.1, VARSO_RAIL, none, M_PAVILION + 0.5)
	var trees := 0
	var pines := 0
	var benches := 0
	var step: float = look["step"]
	var k := 0
	for bed: PackedVector2Array in Geometry2D.offset_polygon(roof, -2.5):
		if bed.size() < 3 or Geometry2D.is_polygon_clockwise(bed) or _area(bed) < 12.0:
			continue
		_prism(bed, y + 0.12, y + 0.55, VARSO_GRANITE, VARSO_BEDS[k % VARSO_BEDS.size()], M_STONE, M_STONE)
		k += 1
		# Benches: timber seats on the deck along the bed's longest edges.
		var edges: Array = []
		for i in bed.size():
			edges.append([bed[i].distance_to(bed[(i + 1) % bed.size()]), i])
		edges.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
		for e: Array in edges:
			if benches >= int(look["benches"]) or float(e[0]) < 4.0:
				break
			var a := bed[int(e[1])]
			var b := bed[(int(e[1]) + 1) % bed.size()]
			var t := (b - a).normalized()
			var o := _out(bed, a, b)
			var m := (a + b) * 0.5 + o * 0.75
			_prism(PackedVector2Array([m - t * 1.0 - o * 0.25, m + t * 1.0 - o * 0.25, m + t * 1.0 + o * 0.25, m - t * 1.0 + o * 0.25]),
					y + 0.12, y + 0.55, VARSO_DECK.darkened(0.25), VARSO_DECK, M_STONE, M_STONE)
			benches += 1
		# The trees on a grid inside the bed (a metre in), then pines in the gaps.
		var inner := Geometry2D.offset_polygon(bed, -1.0)
		if inner.is_empty():
			continue
		var area: PackedVector2Array = inner[0]
		var lo := Vector2(INF, INF)
		var hi := -lo
		for q in area:
			lo = lo.min(q)
			hi = hi.max(q)
		var spots: Array[Vector2] = []
		var gaps: Array[Vector2] = []
		var nx := floori((hi.x - lo.x) / step) + 1
		var nz := floori((hi.y - lo.y) / step) + 1
		var off := (hi - lo - Vector2(nx - 1, nz - 1) * step) * 0.5
		for iz in nz:
			for ix in nx:
				var p := lo + off + Vector2(ix, iz) * step
				if Geometry2D.is_point_in_polygon(p, area):
					spots.append(p)
				var q := p + Vector2(step, step) * 0.5
				if Geometry2D.is_point_in_polygon(q, area):
					gaps.append(q)
		for p in spots:
			if trees >= int(look["trees"]):
				break
			var j := 0.9 + 0.2 * fposmod(sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453, 1.0)
			_varso_tree(p, y + 0.55, float(look["h"]) * j, float(look["r"]) * j)
			trees += 1
		for p in gaps:
			if pines >= int(look["pines"]):
				break
			_pyramid(_circle(p, 0.7, 5), y + 0.55, y + 1.9, VARSO_PINE)
			pines += 1
	_no_roof = keep


## P1 the plaza's name sign: a granite plinth along Al. Jana Pawła II by the tower's north-east
## corner, VERSO PLACE (the parody name, never the real mark) in 0.7 m letters on its avenue face.
func _varso_sign() -> void:
	var c := VARSO_SIGN_AT
	var t := VARSO_SIGN_ALONG.normalized()
	var o := Vector2(t.y, -t.x)  # out of the face, towards the avenue (east-north-east)
	_g = map.terrain_height(c.x, c.y)
	var word := "VERSO PLACE"
	var k := 0.7 / (Neon.ROW_H * Neon.PIXEL)  # 0.7 m letters
	var half := 0.5 * k * Neon.length_of(word) + 0.5
	var plinth := PackedVector2Array([c - t * half - o * 0.45, c + t * half - o * 0.45, c + t * half + o * 0.45, c - t * half + o * 0.45])
	_prism(plinth, _g - 0.3, _g + 1.2, VARSO_GRANITE, VARSO_GRANITE.lightened(0.08), M_STONE, M_STONE)
	_collide(plinth)
	# map_builder sets the letters 0.4 m out from this point: 2 cm off the plinth's face.
	var at := c + o * 0.07
	signs.append([word, Vector3(at.x, _g + 0.25, at.y), Vector3(o.x, 0.0, o.y), k, VARSO_SIGN])


## P2 the glacial erratic: about 60 t (some 22 m³), a rounded grey block 4.2 x 3.2 x 2.1 m on the
## plaza by the tower's north-east corner; the car stops at it.
func _varso_rock() -> void:
	var c := VARSO_ROCK_AT
	_g = map.terrain_height(c.x, c.y)
	var ring := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 + 0.3
		ring.append(c + Vector2(cos(a) * 2.1, sin(a) * 1.6).rotated(0.5))
	var mid := PackedVector2Array()
	var top := PackedVector2Array()
	for q in ring:
		mid.append(c + (q - c) * 0.92)
		top.append(c + (q - c) * 0.5)
	_mode = M_STONE
	_frustum(ring, _g - 0.2, mid, _g + 1.2, VARSO_ROCK)
	_frustum(mid, _g + 1.2, top, _g + 2.1, VARSO_ROCK.lightened(0.06), VARSO_ROCK.lightened(0.1))
	_collide(ring)


func _osm(value, fallback: Color) -> Color:
	var s := str(value).strip_edges().to_lower()
	if s == "":
		return fallback
	var c := Color.from_string(s, Color(0, 0, 0, 0))
	return fallback if c.a == 0.0 else c


# --- the skyline's towers (the landmarks loop) ------------------------------------------------

## A tower from its mapped parts, in its skin (TOWERS). The outline itself (named like the
## tower, or the one part that holds all the others) is left out when parts are mapped; a part
## that starts in the air with nothing mapped under it stands on the ground.
func _build_tower(site: Dictionary) -> void:
	var spec: Dictionary = site["tower"]
	var zone: PackedVector2Array = site["zone"][0]
	if spec.get("novotel", false):
		_build_novotel(zone)
		return
	if spec["key"] == "plater49":
		_build_interkonti(zone, spec)
		return
	if spec["key"] == "wcf":
		_build_wcf(zone, spec)
		return
	if spec["key"] == "cosmopolitan":
		_build_cosmopolitan(zone, spec)
		return
	if spec["key"] == "q22":
		_build_q22(zone, spec)
		return
	if spec["key"] == "rondo1":
		_build_rondo1(zone, spec)
		return
	if spec["key"] == "spektrum":
		_build_spektrum(zone, spec)
		return
	if spec["key"] == "widok":
		_build_widok(zone)
		return
	_g = _ground_under(zone)
	var g := _g
	if spec.has("on_block"):
		# A modelled street block draws the body (check_sites: no second model of one building);
		# the tower keeps its card, its tap cells (landmarks.gd build marks its zone) and the sign.
		_dusk_details(spec, zone, g, float(spec["on_block"]))
		return
	var glass := Color(spec["glass"])
	var roof := Color(spec["roof"])
	var skin := M_SKIN + float(spec["style"]) / 16.0
	var parts := _parts_in(zone, func(b: Dictionary) -> bool: return float(b["h"]) > float(b["mh"]) + 0.5)
	if parts.is_empty() and spec.has("h"):
		# An office the LoD2 data covers is no longer in the OSM building list: the outline itself, at `h`.
		var flat: Array = []
		for q in zone:
			flat.append(q.x)
			flat.append(q.y)
		parts.append({"p": flat, "h": float(spec["h"]), "mh": 0.0, "c": "", "rc": "", "kind": "office", "name": str(spec.get("osm", ""))})
	if spec["key"] == "lim":
		# Centrum LIM: the podium is built from F's photos (_lim_podium), not in the tower's glass
		# (its ground floor is the part named like the outline, so before the filter below).
		parts = _lim_parts(parts, g)
	if parts.size() > 1:
		parts = parts.filter(func(b: Dictionary) -> bool: return str(b.get("name", "")) != spec.get("osm", ""))
	var boxes: Array[Rect2] = []
	var top_h := 0.0
	var top_poly := PackedVector2Array()
	var sign_poly := PackedVector2Array()
	var sign_h := 0.0
	for b in parts:
		boxes.append(_box_of([_pts(b["p"])]))
		if float(b["h"]) > top_h:
			top_h = float(b["h"])
			top_poly = _pts(b["p"])
	# RD-1 the taper (Warsaw Unit): every part from `taper.x` up is narrowed towards the shaft's
	# centre, linearly to `taper.z` at `taper.y` and held there above it (the crown).
	var tp: Vector3 = spec.get("taper", Vector3.ZERO)
	var taper_c := Vector2.ZERO
	for b in parts:
		if tp.z > 0.0 and absf(float(b["mh"]) - tp.x) < 0.5 and float(b["h"]) > tp.y - 0.5:
			taper_c = _centre(_pts(b["p"]))
	var shrink := func(y: float) -> float:
		return 1.0 if tp.z <= 0.0 else lerpf(1.0, tp.z, clampf((y - g - tp.x) / (tp.y - tp.x), 0.0, 1.0))
	var lifted: Array[PackedVector2Array] = []
	var lift_h := 0.0
	if spec["key"] == "zlota44":
		# Złota 44: the tower is lofted (_zlota_sail); only the podium is built from its parts,
		# with its roof garden.
		_zlota_sail(g, glass, roof, skin)
		_zlota_garden(parts, g)
		_zlota_pool(parts, g)
		_zlota_foot(parts, g)
	elif spec["key"] == "spire":
		# Warsaw Spire: the leaf-shaped tower lofted and tapering (_spire); the two lower
		# office buildings beside it are built from their parts.
		var masts: Array = []
		for b in parts:
			if float(b["h"]) >= 200.0:
				masts.append(_centre(_pts(b["p"])))
		_spire(zone, g, glass, roof, skin, masts)
		for w in range(1, (site["zone"] as Array).size()):
			_spire_wing(site["zone"][w])
		_g = g
	var blek_vault: Array[PackedVector2Array] = []
	for k in parts.size():
		var b: Dictionary = parts[k]
		var poly := _pts(b["p"])
		var h := float(b["h"])
		var mh := float(b["mh"])
		if spec["key"] == "blekitny" and str(b.get("c", "")) == "darkslategray":
			blek_vault.append(poly)  # the glass barrel-vaulted hall, built whole (_blekitny_vault)
			_collide(poly)  # the strips stand on the ground: they stop cars as before
			continue
		if spec["key"] == "zlota44" and h > 40.0 or spec["key"] == "spire" and h > 100.0:
			continue
		if mh > 0.5:
			var held := false
			for j in parts.size():
				if j != k and float(parts[j]["mh"]) < mh - 0.5 and float(parts[j]["h"]) >= mh - 1.5 \
						and boxes[j].grow(-0.5).intersects(boxes[k].grow(-0.5)):
					held = true
					break
			if not held:
				if spec.has("hall") and mh < 15.0:
					lifted.append(poly)  # RD-1: a wing lifted over the gate's glass hall
					lift_h = mh
				else:
					mh = 0.0
		var small := boxes[k].size.length() < 9.0
		var base := g + mh - (0.4 if mh < 0.5 else 0.0)
		if small and spec.has("arcade") and h <= float(spec["arcade"]) + 0.5:
			# RD-2 Mennica's arcade: a mapped post is a round stainless column, 0.9 m across.
			var cc := Color(spec["columns"])
			_prism(_circle(_centre(poly), 0.45, 10), g - 0.4, g + h, cc, cc, M_STONE, M_STONE)
			continue
		if small and spec.has("hall"):
			base = g - 0.4  # Unit's gate posts stand on the ground
		if small and spec["key"] == "wtt" and h > 200.0:
			_wtt_mast(poly, g + mh, g + h)  # stands in front of the crown's flat face from its mapped foot
			continue
		if small:
			# A mast, a spire's piece or a ring: plain painted steel in its mapped colour. It starts on
			# the roof of the part it stands on (Skyliner's mast on its crown block: no faces inside).
			var foot := _centre(poly)
			for j in parts.size():
				if j != k and not boxes[j].size.length() < 9.0 and boxes[j].has_point(foot) \
						and Geometry2D.is_point_in_polygon(foot, _pts(parts[j]["p"])) and float(parts[j]["h"]) < h:
					base = maxf(base, g + float(parts[j]["h"]) - 0.4)
			var c := _osm(b["c"], roof)
			_prism(poly, base, g + h, c, c.lightened(0.1), M_STONE, M_STONE)
			continue
		if spec.has("top"):
			h = minf(h, float(spec["top"]))
		var wall := glass
		var part_skin := skin
		if spec["key"] == "lim" and h > 100.0:
			part_skin = M_GLASS  # LIM's tower: the shader's mullions and lit rooms (lim.md)
		var crown := spec.has("crown_from") and mh >= float(spec["crown_from"]) - 0.5
		if crown:
			wall = Color(spec["crown"])
			part_skin = M_SKIN + float(S_DARK) / 16.0
			# Cladding 6 cm proud of the shaft's plane, so where the block's face runs on in the
			# shaft's (Skyliner's north face) the two never share a plane.
			var proud := Geometry2D.offset_polygon(poly, 0.06)
			if proud.size() == 1:
				poly = proud[0]
		elif spec.get("mapped", false):
			wall = _osm(b["c"], glass)  # mapped in its own colours (Chałubińskiego 8's white ribs)
		elif h < top_h * 0.3 and h < 40.0:
			# The podium: the tower's glass, a step warmer and darker (Unit's: dark sloped glass).
			wall = Color(spec["podium"]) if spec.has("podium") \
					else glass.darkened(0.12).lerp(Color("#b8a88c"), 0.0 if spec.get("cool", false) else 0.15)
			if spec.has("podium_style"):
				part_skin = M_SKIN + float(spec["podium_style"]) / 16.0
		if spec.has("skins") and (spec["skins"] as Dictionary).has(str(b.get("c", "")).to_lower()):
			# A part's own cladding by its mapped colour (WTT's stone slab, silver crown, dark glass).
			var sk: Array = spec["skins"][str(b.get("c", "")).to_lower()]
			wall = Color(sk[1])
			part_skin = M_SKIN + float(sk[0]) / 16.0
		if spec.has("scales") and str(b.get("c", "")).to_lower() in UNIT_SKIN_COLOURS:
			# Warsaw UNIT's Dragon Skin (F's photos, 2026-11-19): the podium box from the first floor
			# up wears the plate skin; the mapped piece under it is the glazed ground floor.
			wall = Color(spec["scales"]) if mh >= 8.5 else glass
			part_skin = M_SKIN + float(S_SCALES) / 16.0 if mh >= 8.5 else skin
		elif spec.has("scales") and mh > 20.0 and h - mh < 3.0:
			# the thin slab between the podium and the shaft: a silver fascia (Street View)
			wall = UNIT_FASCIA
			part_skin = M_STONE
		if spec.has("arcade") and absf(h - float(spec["arcade"])) < 0.5 and mh < 0.5:
			# RD-2 the arcade's lobby: copper-tinted glass 5 m in from the column line, lit warm.
			var lobby := Geometry2D.offset_polygon(poly, -5.0)
			if lobby.size() == 1:
				_prism(lobby[0], g - 0.4, g + h, Color(spec["lobby"]), Color(0, 0, 0, 0), M_PAVILION, M_STONE)
			_collide(poly)
			continue
		if spec.has("arcade") and absf(mh - float(spec["arcade"])) < 0.5:
			_soffit(poly, g + mh, roof.darkened(0.25))  # the shaft's underside over the arcade
		if tp.z > 0.0 and mh >= tp.x - 0.5:
			var s0: float = shrink.call(g + mh)
			var s1: float = shrink.call(g + h)
			if absf(s0 - s1) < 0.0005:
				poly = _scaled(poly, taper_c, s0)
			else:
				var p0 := _scaled(poly, taper_c, s0)
				var p1 := _scaled(poly, taper_c, s1)
				var keep_m := _mode
				_mode = part_skin
				_frustum(p0, base, p1, g + h, wall)
				_mode = keep_m
				_cap(p1, g + h, roof)
				if spec.has("strips") and not crown and h >= 100.0:
					_tower_strips(poly, base + 2.0, g + h, Color(spec["strips"]), taper_c, s0, s1)
				continue
		if spec.get("crest", "") == "slope" and h >= top_h - 0.5:
			_sloped(poly, base, g + h, g + h - 24.0, wall, roof, skin)
		elif spec.has("slope_to") and not crown and h >= 100.0:
			_tower_cut(poly, base, g + h, spec, wall, roof, part_skin)
		else:
			_prism(poly, base, g + h, wall, roof, part_skin, M_SKIN)
			if crown and spec.get("crown_sign", false) and h > sign_h and not small:
				sign_poly = poly  # the crown block's highest part (Skyliner's mast is taller)
				sign_h = h
			if spec.has("strips") and not crown and h >= 100.0:
				_tower_strips(poly, base + 2.0, g + h, Color(spec["strips"]))
			if spec.has("band") and h >= top_h - 0.5:
				_tower_band(poly, g + 8.5, g + 11.5, Color(spec["band"]))
				if spec.has("band_signs"):
					_ring_signs(poly, g, spec["band_signs"])
			if spec.get("crest", "") == "frame" and h >= top_h - 0.5:
				# Rondo 1: an open frame round the top, from the roof to 192 m.
				_prism(poly, g + h, g + 192.0, wall, Color(0, 0, 0, 0), M_SKIN + float(S_FRAME) / 16.0)
			if spec.get("chamfer", false) and h >= top_h - 0.5:
				_chamfered_top(poly, g + h, wall)
			if spec.has("patches") and h >= 100.0:
				_tower_patches(poly, base, g + h, Color(spec["patches"]))
			if spec.has("parapet") and h >= minf(top_h, float(spec.get("top", INF))) - 0.5:
				_tower_roof(poly, g + h, Color(spec["parapet"]), spec.get("plant", Vector2.ZERO),
						float(spec.get("screen", 0.0)), wall)
			if spec.get("the_roof", false) and h >= top_h - 0.5:
				_the_roof(poly, g + h)
		if mh < 2.0:
			_collide(poly)
	if spec.has("top"):
		top_h = minf(top_h, float(spec["top"]))
	if tp.z > 0.0:
		top_poly = _scaled(top_poly, taper_c, shrink.call(g + top_h))
	if not lifted.is_empty():
		_gate_hall(lifted, g, lift_h, float(spec["hall"]), Color("#2e4560"))
	if spec.has("skylight"):
		_podium_skylight(spec["skylight"][0], float(spec["skylight"][1]))
	for t: Array in site.get("terraces", []):
		_roof_terrace(t[0], float(t[1]), t[2])
	if spec["key"] == "wtt":
		_wtt_crown_slits(parts, g)
	if spec.has("scales"):
		_unit_skin_dress(parts, g)
	if spec.has("shops"):
		_shop_signs(parts, g, spec["shops"], spec.get("shops_dir", Vector2.ZERO))
	if sign_poly.size() >= 3:
		# The sign on the crown block, not on the shaft (_dusk_details skips it); a name of two
		# words on a narrow block goes in two rows, so the letters stay readable from the street.
		var words := str(spec["sign"]).split(" ")
		var narrow := _box_of([sign_poly]).size.length() < 40.0
		if words.size() > 1 and narrow:
			for n in words.size():
				_crown_signs(sign_poly, g + sign_h, words[n], spec.get("sign_col", DUSK_WARM), 4.0 + 7.0 * n, 0.85)
		else:
			_crown_signs(sign_poly, g + sign_h, str(spec["sign"]), spec.get("sign_col", DUSK_WARM), 4.0, 0.8)
	if spec["key"] == "blekitny":
		_blekitny_vault(blek_vault, g)
		_blekitny_roof(top_poly, g + top_h)
	if spec.get("babka", false) and (site["zone"] as Array).size() > 1:
		_babka_block(site["zone"][1], top_poly)
		_g = g
	_dusk_details(spec, top_poly, g, top_h)


# --- InterContinental and the Warsaw Financial Centre (F's photos, 2026-11-08) ---------------

## The hotel tower on Emilii Plater 49 (2003), rebuilt from F's four photos (front from the
## Palace at dusk, the north view up Emilii Plater, the aerial over Osiedle Emilia, the night
## view with the Palace; spec docs/landmarks/specs/plater49.md). The parts are OpenStreetMap's:
## a square shaft turned like the street grid on a four-storey glass podium; from the podium to
## the 20th floor the shaft's north-east half is missing, so the hotel stands over a 53 m high
## gap open to the Palace, its back wall stone, its ceiling warm, the whole hole floodlit white
## at night; a one-bay glass column runs down the north corner. The roof is cut on a slope, high
## over the south-west face (164 m) and 10 m lower over the north-east one. Two dark bands: the
## storey over the gap and the top two storeys, under the hotel's name (the parody INTERKONTI).
const IC_SHAFT := [Vector2(-1455.3, 157.9), Vector2(-1445.6, 187.6), Vector2(-1474.6, 198.4), Vector2(-1485.5, 169.0)]
## The shaft under the gap: its south-west half, cut on the diagonal from the north-west face to
## the east corner.
const IC_LOWER := [Vector2(-1471.2, 163.7), Vector2(-1445.6, 187.6), Vector2(-1474.6, 198.4), Vector2(-1485.5, 169.0)]
## The glass column at the north corner, one bay (5 m) along each face.
const IC_COLUMN := [Vector2(-1455.3, 157.9), Vector2(-1453.6, 162.6), Vector2(-1460.0, 159.6)]
const IC_PODIUM := 16.5    ## the podium's roof, where the shaft and the gap start (OSM)
const IC_GAP_TOP := 69.3   ## the gap's ceiling (OSM)
const IC_ROOF := 164.0
const IC_DROP := 10.0      ## the roof's slope, from the south-west face to the north-east one
const IC_GLASS := Color("#7f98ab")      ## silver-blue glass in a white grid (photos 1, 3)
const IC_STONE := Color("#d2cbbb")      ## the gap's back wall: pale grey stone (photo 3, sunlit)
const IC_CEILING := Color("#e6cf9e")    ## the gap's ceiling, lit warm (photos 1, 4)
const IC_BAND := Color("#2a3440")       ## the dark storeys
const IC_PODIUM_GLASS := Color("#9db3bd")


func _ic_ring(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q: Vector2 in pts:
		out.append(q)
	return out


func _build_interkonti(zone: PackedVector2Array, spec: Dictionary) -> void:
	_g = _ground_under(zone)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var shaft := _ic_ring(IC_SHAFT)
	var lower := _ic_ring(IC_LOWER)
	var column := _ic_ring(IC_COLUMN)
	var grid := M_SKIN + float(S_GRID) / 16.0
	var dark := M_SKIN + float(S_DARK) / 16.0
	# The podium: four storeys of glass in light bands over the whole plot, its roof pale.
	_prism(zone, g - 0.4, g + IC_PODIUM, IC_PODIUM_GLASS, Color("#b9bec0"), M_SKIN + float(S_BANDS) / 16.0, M_STONE)
	_collide(zone)
	# Under the gap: the shaft's south-west half and the north corner's column, in the grid; the
	# half's diagonal face (the gap's back wall) in stone, lit white at night (M_LAMP glows).
	var cut_a: Vector2 = IC_LOWER[0]
	var cut_b: Vector2 = IC_LOWER[1]
	var back_out := _out(lower, cut_a, cut_b)
	_mode = M_LAMP
	_wall(cut_a, cut_b, g + IC_PODIUM, g + IC_GAP_TOP, back_out, IC_STONE)
	_mode = grid
	for i in lower.size():
		var a := lower[i]
		var b := lower[(i + 1) % lower.size()]
		if i == 0:
			continue  # the back wall, done above
		_wall(a, b, g + IC_PODIUM, g + IC_GAP_TOP, _out(lower, a, b), IC_GLASS)
	_prism(column, g + IC_PODIUM, g + IC_GAP_TOP, IC_GLASS, none, grid)
	# The gap's ceiling: the underside of the shaft over the missing half, lit warm.
	var gap := PackedVector2Array([shaft[0], shaft[1], cut_a])
	_mode = M_LAMP
	_soffit(gap, g + IC_GAP_TOP, IC_CEILING)
	# Over the gap: the whole shaft to the cut roof; the dark storey right over the gap and the
	# dark top storeys as rings 0.1 m proud of the glass.
	var cut_spec := {"slope_to": Vector2(-0.94, 0.35), "cut_drop": IC_DROP}
	_tower_cut(shaft, g + IC_GAP_TOP, g + IC_ROOF, cut_spec, IC_GLASS, Color("#c3c7c9"), grid)
	var proud := Geometry2D.offset_polygon(shaft, 0.1, Geometry2D.JOIN_MITER)
	if proud.size() == 1:
		_prism(proud[0], g + IC_GAP_TOP, g + IC_GAP_TOP + 3.8, IC_BAND, none, dark)
		_prism(proud[0], g + IC_ROOF - IC_DROP - 7.6, g + IC_ROOF - IC_DROP - 0.4, IC_BAND, none, dark)
	_mode = M_STONE
	# The name on the top's dark band, on the faces seen from the Palace and Emilii Plater.
	_crown_signs(shaft, g + IC_ROOF - IC_DROP, str(spec["sign"]), DUSK_WARM, 3.0, 0.7)
	var roof_y := func(q: Vector2) -> float:
		return g + IC_ROOF - IC_DROP * (1.0 - clampf(inverse_lerp(-14.0, 14.0, (q - _centre(shaft)).dot(Vector2(-0.94, 0.35))), 0.0, 1.0))
	_aviation(shaft, roof_y)


## Warsaw Financial Centre (Emilii Plater 53, 1998, 144 m), rebuilt from F's five photos (the
## whole tower from Varso, its crown, the street elevation, the corner from Emilii Plater; spec
## docs/landmarks/specs/wcf.md). Two slabs on a stone-and-glass podium, split on a curve: the
## taller north-west slab (144 m) in white cladding with punched windows, its concave face turned
## south-east; the lower south-east slab (130 m) in ribbon glazing, dark teal glass between white
## bands, a dark set-back top storey. On the white slab's roof the plant behind a parapet and the
## red-and-white mast.
const WCF_HIGH := [Vector2(-1501.2, 38.5), Vector2(-1502.0, 41.0), Vector2(-1504.5, 46.1), Vector2(-1507.3, 50.9),
		Vector2(-1510.3, 55.1), Vector2(-1514.7, 60.7), Vector2(-1519.1, 65.2), Vector2(-1523.3, 69.1),
		Vector2(-1528.5, 73.2), Vector2(-1531.9, 75.7), Vector2(-1535.8, 78.1), Vector2(-1543.1, 81.4),
		Vector2(-1554.4, 85.4), Vector2(-1562.9, 60.3), Vector2(-1545.1, 54.6), Vector2(-1546.0, 52.0),
		Vector2(-1500.8, 37.0)]
const WCF_LOW := [Vector2(-1501.6, 41.9), Vector2(-1492.9, 66.5), Vector2(-1542.7, 82.8), Vector2(-1543.1, 81.4),
		Vector2(-1535.8, 78.1), Vector2(-1531.9, 75.7), Vector2(-1528.5, 73.2), Vector2(-1523.3, 69.1),
		Vector2(-1519.1, 65.2), Vector2(-1514.7, 60.7), Vector2(-1510.3, 55.1), Vector2(-1507.3, 50.9),
		Vector2(-1504.5, 46.1), Vector2(-1502.0, 41.0)]
const WCF_PODIUM := 19.8
const WCF_HIGH_ROOF := 144.0
const WCF_LOW_ROOF := 130.0
const WCF_WHITE := Color("#d8d9d4")        ## the white slab's cladding (photos 2, 3)
const WCF_RIBBON := Color("#2f5d60")       ## the south-east slab's teal glass (photos 1, 3)
const WCF_STONE := Color("#bba595")        ## the podium's pink-beige granite (photos 1, 3)
const WCF_PODIUM_GLASS := Color("#7ea29e") ## the podium's green glass (photo 4)


func _build_wcf(zone: PackedVector2Array, _spec: Dictionary) -> void:
	_g = _ground_under(zone)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var high := _ic_ring(WCF_HIGH)
	var low := _ic_ring(WCF_LOW)
	var base := _largest(Geometry2D.merge_polygons(high, low))
	# The podium: green glass in a fine grid over a granite ground floor 0.2 m proud.
	_prism(base, g - 0.4, g + WCF_PODIUM, WCF_PODIUM_GLASS, Color("#9a9f9c"), M_SKIN + float(S_GRID) / 16.0, M_STONE)
	var plinth := Geometry2D.offset_polygon(base, 0.2, Geometry2D.JOIN_MITER)
	if plinth.size() == 1:
		_prism(plinth[0], g - 0.4, g + 5.2, WCF_STONE, WCF_STONE.lightened(0.1), M_STONE, M_STONE)
		_prism(plinth[0], g + WCF_PODIUM - 1.2, g + WCF_PODIUM + 0.3, WCF_STONE, WCF_STONE.lightened(0.1), M_STONE, M_STONE)
	_collide(base)
	_wcf_street(base, g)
	_wcf_terrace(low, g + WCF_LOW_ROOF - 3.6)
	# The ribbon slab first (its curved face is inside the white slab), then the white slab.
	_prism(low, g + WCF_PODIUM + 0.3, g + WCF_LOW_ROOF - 3.6, WCF_RIBBON, none, M_SKIN + float(S_RIBBON) / 16.0)
	var top_floor := Geometry2D.offset_polygon(low, -1.6, Geometry2D.JOIN_MITER)
	_prism(low, g + WCF_LOW_ROOF - 3.6, g + WCF_LOW_ROOF - 3.3, WCF_WHITE, Color("#a9adab"), M_STONE, M_STONE)
	if top_floor.size() == 1:
		_prism(top_floor[0], g + WCF_LOW_ROOF - 3.3, g + WCF_LOW_ROOF, WCF_RIBBON.darkened(0.3), Color("#a9adab"), M_SKIN + float(S_DARK) / 16.0, M_STONE)
	_prism(high, g + WCF_PODIUM + 0.3, g + WCF_HIGH_ROOF, WCF_WHITE, none, M_SKIN + float(S_PUNCHED) / 16.0)
	_tower_roof(high, g + WCF_HIGH_ROOF, Color("#cfd1cf"), Vector2.ZERO)
	# The plant (photo 2): two grey blocks on the roof's straight west half, clear of the curve.
	var y := g + WCF_HIGH_ROOF
	var west: Vector2 = WCF_HIGH[13]
	var north: Vector2 = WCF_HIGH[16]
	for t: float in [0.3, 0.55]:
		var p := west.lerp(north, t).lerp(_centre(high), 0.5)
		_prism(_square(p, 4.0), y, y + 4.2, Color("#a4a9ad"), Color("#8f9599"), M_STONE, M_STONE)
	# The mast: red and white segments on the roof's west half, a red lamp on top.
	var foot := west.lerp(_centre(high), 0.35)
	for k in 6:
		var c := Color("#c8302a") if k % 2 == 0 else Color("#ecebe6")
		var w := 0.9 - 0.1 * k
		_prism(_square(foot, w), y + 4.0 * k, y + 4.0 * (k + 1), c, c, M_STONE, M_STONE)
	_prism(_square(foot, 0.3), y + 24.0, y + 24.8, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	var roof_hi := func(_q: Vector2) -> float: return g + WCF_HIGH_ROOF + 1.5
	_aviation(high, roof_hi)
	var roof_lo := func(_q: Vector2) -> float: return g + WCF_LOW_ROOF
	_aviation(low, roof_lo)


# --- Spektrum Tower and the rooftop club (F's photos, 2026-11-13) ------------------------------

## Spektrum Tower (Twarda 18, 2003, 128 m), rebuilt from F's eleven photos (spec
## docs/landmarks/specs/spektrum.md). The mapped parts give the shape: the round drum (122 m)
## between the dark square-grid slabs (106 and 118 m), the podium round its foot (12 to 36 m).
## On top of that, from the photos: the drum ends in a ring of tall glass screens with a blue
## LED rail, and inside the ring stands the rooftop club (here THE WJU, the parody of the real
## one): a lower grey deck, then a round raised deck behind a glass railing, its edge a lit
## ring at night, full of white lounge chairs, poufs and cube tables round a white bar, with
## palms in white pots and white parasols. Up the drum's south face, in the notch between the
## grid slab and the banded volume, the slanted glass fin: wide over the podium, it leans in
## and meets the drum near the top. The podium: a glazed ground floor, grey ribbon storeys and
## a white roof edge. Every piece is in the city's one building surface (no new draw call).
const SPEKTRUM_DRUM_COL := Color("#5f86a3")
const SPEKTRUM_SLAB_COL := Color("#26384a")
const SPEKTRUM_ROOF := Color("#7c878c")
const SPEKTRUM_SCREEN := Color("#a8cbcb")      ## the crown's glass screens (the mapped #A2B5AF ring)
const SPEKTRUM_DECK := Color("#5c6469")        ## the lower deck round the club, dark grey
const SPEKTRUM_CLUB_WALL := Color("#a3a9ad")   ## the club drum's grey metal wall
const SPEKTRUM_CLUB_DECK := Color("#cfd1cd")
const SPEKTRUM_RAIL := Color("#c3dad9")        ## glass railing, read as pale glass
const SPEKTRUM_WHITE := Color("#f1eee6")       ## the lounge furniture's white leather
const SPEKTRUM_CUBE := Color("#fff3dc")        ## the cube tables, white by day and lit from inside at night
const SPEKTRUM_FIN := Color("#9cc6c2")
const SPEKTRUM_PODIUM := Color("#8a959b")
const SPEKTRUM_HALL := Color("#9cb8c4")
const SPEKTRUM_EDGE := Color("#e9ecec")
const SPEKTRUM_SCREEN_TOP := 2.4     ## the screens stand this far over the drum's roof (the club peeks over them)
const SPEKTRUM_CLUB_UP := 3.4        ## the raised deck over the drum's roof
const SPEKTRUM_FIN_FOOT := Vector2(-1672.9, -55.5)  ## the fin's outer foot, on the podium roof
const SPEKTRUM_FIN_LOW := 32.0       ## the podium roof under it
const SPEKTRUM_FIN_TOP := 117.0      ## where it meets the drum
const SPEKTRUM_FIN_HALF := 1.25       ## half its thickness
const SPEKTRUM_SIGN := "SPEKTRAL"    ## the tower's name on the crown, as a parody
const SPEKTRUM_CLUB := "THE WJU"     ## the club's name, the parody of the real one (F OK'd, 2026-11-13)


func _build_spektrum(zone: PackedVector2Array, spec: Dictionary) -> void:
	_g = _ground_under(zone)
	var g := _g
	var bands := M_SKIN + float(S_BANDS) / 16.0
	var grid := M_SKIN + float(S_GRID) / 16.0
	var ribbon := M_SKIN + float(S_RIBBON) / 16.0
	var parts := _parts_in(zone, func(b: Dictionary) -> bool: return float(b["h"]) > float(b["mh"]) + 0.5)
	if parts.size() > 1:
		parts = parts.filter(func(b: Dictionary) -> bool: return str(b.get("name", "")) != spec.get("osm", ""))
	var drum := PackedVector2Array()
	var drum_h := 0.0
	for b in parts:
		var poly := _pts(b["p"])
		var h := float(b["h"])
		var mh := float(b["mh"])
		var col := str(b.get("c", "")).to_lower()
		if mh > 100.0:
			continue  # the mapped crown ring and roof box: the screens and the club stand there now
		var y0 := g + mh if mh > 0.5 else g - 0.4
		if h > 40.0:
			if col == "#274754":
				_prism(poly, y0, g + h, SPEKTRUM_SLAB_COL, SPEKTRUM_ROOF, grid, M_STONE)
			else:
				_prism(poly, y0, g + h, SPEKTRUM_DRUM_COL, SPEKTRUM_ROOF, bands, M_STONE)
				if h > drum_h:
					drum_h = h
					drum = poly
		else:
			_spektrum_podium(poly, y0, g + h, mh < 0.5, ribbon, grid)
		if mh < 0.5:
			_collide(poly)
	if drum.size() < 3:
		push_warning("landmarks: Spektrum's mapped drum is missing")
		return
	var c := _centre(drum)
	var r := 0.0
	for q in drum:
		r += q.distance_to(c)
	r /= float(drum.size())
	var top := g + drum_h
	_spektrum_fin(c, r, g)
	_spektrum_crown(c, r, top)
	_spektrum_club(c, r * 0.72, top + SPEKTRUM_CLUB_UP)
	_spektrum_signs(c, r, top)


## A podium part: a glazed ground floor, grey ribbon storeys over it and a white roof edge.
func _spektrum_podium(poly: PackedVector2Array, y0: float, y1: float, ground: bool, ribbon: float, grid: float) -> void:
	var none := Color(0, 0, 0, 0)
	var hall := y0 + 5.4 if ground else y0
	if ground and y1 - y0 <= 7.0:
		_prism(poly, y0, y1, SPEKTRUM_HALL, SPEKTRUM_ROOF, grid, M_STONE)
		return
	if hall > y0:
		_prism(poly, y0, hall, SPEKTRUM_HALL, none, grid)
	_prism(poly, hall, y1 - 1.1, SPEKTRUM_PODIUM, none, ribbon)
	_prism(poly, y1 - 1.1, y1, SPEKTRUM_EDGE, SPEKTRUM_ROOF.lightened(0.08), M_STONE, M_STONE)


## The slanted glass fin: a wedge in the notch on the drum's south face, from the podium roof at
## its outer foot up and in to the drum at SPEKTRUM_FIN_TOP; a pale lit edge up its slope.
func _spektrum_fin(c: Vector2, r: float, g: float) -> void:
	var foot := SPEKTRUM_FIN_FOOT
	var u := Vector2(0.0, signf(foot.y - c.y))
	var v := Vector2(-u.y, u.x)
	# Where the fin's plane meets the drum, 0.6 m inside it.
	var dx := foot.x - c.x
	var inner_t := sqrt(maxf(r * r - dx * dx, 0.0)) - 0.6
	var inner := Vector2(foot.x, c.y + u.y * inner_t)
	var y_lo := g + SPEKTRUM_FIN_LOW
	var y_hi := g + SPEKTRUM_FIN_TOP
	var keep := _mode
	_mode = M_GLASS
	for s: float in [-1.0, 1.0]:
		var o := v * SPEKTRUM_FIN_HALF * s
		var a := Vector3(inner.x + o.x, y_lo, inner.y + o.y)
		var b := Vector3(foot.x + o.x, y_lo, foot.y + o.y)
		var t := Vector3(inner.x + o.x, y_hi, inner.y + o.y)
		var l := inner.distance_to(foot)
		_tri(a, b, t, Vector3(v.x * s, 0.0, v.y * s), SPEKTRUM_FIN, Vector2(0.0, SPEKTRUM_FIN_LOW), Vector2(l, SPEKTRUM_FIN_LOW),
				Vector2(0.0, SPEKTRUM_FIN_TOP), SPEKTRUM_FIN_TOP)
	# The sloping outer face.
	var slope := Vector3(inner.x - foot.x, y_hi - y_lo, inner.y - foot.y)
	var side := Vector3(v.x, 0.0, v.y)
	var n := slope.cross(side).normalized()
	if n.dot(Vector3(u.x, 0.0, u.y)) < 0.0:
		n = -n
	var w := SPEKTRUM_FIN_HALF
	var len3 := slope.length()
	_quad(Vector3(foot.x - v.x * w, y_lo, foot.y - v.y * w), Vector3(foot.x + v.x * w, y_lo, foot.y + v.y * w),
			Vector3(inner.x + v.x * w, y_hi, inner.y + v.y * w), Vector3(inner.x - v.x * w, y_hi, inner.y - v.y * w), n,
			SPEKTRUM_FIN.lightened(0.08), Vector2(0.0, 0.0), Vector2(w * 2.0, 0.0), Vector2(w * 2.0, len3), Vector2(0.0, len3), SPEKTRUM_FIN_TOP)
	_mode = keep
	# The lit edge: a thin pale tube up the slope (glows at night).
	var lift := n * 0.12
	_beam(Vector3(foot.x, y_lo, foot.y) + lift, Vector3(inner.x, y_hi, inner.y) + lift, 0.22, Color("#d6f1ff"), false, M_LAMP)


## The crown: the grey deck on the drum's roof, then the ring of tall glass screens round its
## edge (both faces, as the camera looks down into the ring), a steel post every few metres,
## the top rail lit blue at night and the red aviation lamps on it.
func _spektrum_crown(c: Vector2, r: float, top: float) -> void:
	var n := 32
	var rs := r + 0.2
	var outer := _circle(c, rs, n)
	var inner := _circle(c, rs - 0.15, n)
	var y0 := top - 3.2
	var y1 := top + SPEKTRUM_SCREEN_TOP
	var keep := _mode
	_mode = M_GLASS
	var run := 0.0
	for k in n:
		var k1 := (k + 1) % n
		var mid := (outer[k] + outer[k1]) * 0.5
		_wall(outer[k], outer[k1], y0, y1, mid - c, SPEKTRUM_SCREEN, run)
		_wall(inner[k1], inner[k], top, y1, c - mid, SPEKTRUM_SCREEN.darkened(0.18), run)
		run += outer[k].distance_to(outer[k1])
	_mode = M_STONE
	# The screen's ring top, the deck inside it.
	_cap_holes(outer, [inner], y1, Color("#c9ced2"))
	_cap(_circle(c, rs - 0.16, n), top + 0.05, SPEKTRUM_DECK)
	# Posts every second panel, proud of the glass, and the lit rail on top.
	for k in range(0, n, 2):
		var p := c + Vector2.from_angle(TAU * float(k) / float(n)) * (rs + 0.12)
		_beam(Vector3(p.x, y0, p.y), Vector3(p.x, y1 + 0.1, p.y), 0.16, Color("#b9bfc4"), false)
	var rail_o := _circle(c, rs + 0.06, n)
	var rail_i := _circle(c, rs - 0.21, n)
	_mode = M_LAMP + 0.5
	for k in n:
		var k1 := (k + 1) % n
		var mid := (rail_o[k] + rail_o[k1]) * 0.5
		_wall(rail_o[k], rail_o[k1], y1 + 0.1, y1 + 0.35, mid - c, Color("#c7d4de"))
	_cap_holes(rail_o, [rail_i], y1 + 0.35, Color("#c7d4de"))
	_mode = keep
	# Three red aviation lamps on the rail (south-west, south-east, north-east, as _aviation).
	for d: Vector2 in [Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1)]:
		var p := c + d.normalized() * (rs - 0.08)
		_prism(_square(p, 0.3), y1 + 0.35, y1 + 0.95, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)


## The club: a round grey drum on the deck, its top edge a lit band (the ring F sees at night),
## a pale deck behind a glass railing, and the white lounge on it.
func _spektrum_club(c: Vector2, rc: float, deck: float) -> void:
	var n := 28
	var base := deck - SPEKTRUM_CLUB_UP + 0.05
	var ring := _circle(c, rc, n)
	_prism(ring, base, deck - 0.55, SPEKTRUM_CLUB_WALL, Color(0, 0, 0, 0), M_STONE)
	_prism(ring, deck - 0.55, deck, Color("#ffe6b0"), SPEKTRUM_CLUB_DECK, M_LAMP, M_STONE)
	# The glass railing (both faces) and its steel top rail.
	var ro := _circle(c, rc - 0.15, n)
	var keep := _mode
	_mode = M_STONE
	for k in n:
		var k1 := (k + 1) % n
		var mid := (ro[k] + ro[k1]) * 0.5
		_wall(ro[k], ro[k1], deck, deck + 1.1, mid - c, SPEKTRUM_RAIL)
		_wall(ro[k1], ro[k], deck, deck + 1.1, c - mid, SPEKTRUM_RAIL.darkened(0.1))
	_cap_holes(_circle(c, rc - 0.1, n), [_circle(c, rc - 0.2, n)], deck + 1.15, Color("#b5bbc0"))
	# The round bar in the middle: a white counter ring round the barmen's dark floor.
	var bar_o := _circle(c, 2.2, 12)
	var bar_i := _circle(c, 1.5, 12)
	_prism(bar_o, deck, deck + 1.1, SPEKTRUM_WHITE, Color(0, 0, 0, 0), M_STONE)
	_mode = M_STONE
	for k in bar_i.size():
		var k1 := (k + 1) % bar_i.size()
		_wall(bar_i[k1], bar_i[k], deck, deck + 1.1, c - (bar_i[k] + bar_i[k1]) * 0.5, SPEKTRUM_WHITE.darkened(0.1))
	_cap_holes(bar_o, [bar_i], deck + 1.1, Color("#3a3f43"))
	_mode = keep
	# The lounge (spektrum_layout, shared with the crowd that sits in it): armchairs round a cube
	# table and curved sofas by turns, the DJ's booth to the north, palms, parasols.
	var lay := spektrum_layout(c, rc)
	for gr: Array in lay["groups"]:
		if int(gr[2]) == 0:
			_spektrum_chairs(gr[0], float(gr[1]), deck)
		else:
			_spektrum_sofa(gr[0], float(gr[1]), deck, c)
	_spektrum_dj(lay["dj"], lay["dj_face"], deck)
	var k := 0
	for pp: Vector2 in lay["palms"]:
		_spektrum_palm(pp, deck, k)
		k += 1
	for p: Vector2 in lay["parasols"]:
		_prism(_circle(p, 0.06, 4), deck, deck + 2.3, Color("#c9ced2"), Color(0, 0, 0, 0), M_STONE)
		_mode = M_STONE
		_pyramid(_circle(p, 1.5, 8), deck + 1.95, deck + 2.55, SPEKTRUM_WHITE.lightened(0.04))
		_mode = keep


## The club's plan on its deck round `c` (radius `rc`), for the model and the crowd (crowds.gd
## sites `spektrum_view` and `spektrum_dj`): six lounge groups [middle, turn, 0 armchairs / 1
## sofa] (the two by the DJ left out), the DJ's spot and the way they face (south, to the bar
## and the camera), the seats [spot, facing] of every armchair and sofa piece, the dancers'
## spots in a crescent before the booth facing it, the palms and the parasols.
static func spektrum_layout(c: Vector2, rc: float) -> Dictionary:
	var north := Vector2(0.0, -1.0)
	var groups: Array = []
	var seats: Array = []
	for k in 8:
		var t := TAU * (float(k) + 0.5) / 8.0
		var dir := Vector2.from_angle(t)
		if dir.dot(north) > 0.7:
			continue  # the DJ's side
		var p := c + dir * (rc * 0.6)
		var sofa := k % 2
		groups.append([p, t, sofa])
		if sofa == 0:
			for s in 4:
				var d := Vector2.from_angle(t + TAU * float(s) / 4.0)
				seats.append([p + d * 0.95, -d])
		else:
			var face := (c - p).normalized()
			for s in 5:
				var ang := face.angle() + PI + (float(s) - 2.0) * 0.45
				var d := Vector2.from_angle(ang)
				seats.append([p + d * 1.25, -d])
	var dj := c + north * (rc * 0.45)
	var dancers: Array = []
	for i in 14:
		var ang := -PI * 0.5 + (float(i) - 6.5) * 0.19
		var at := c + Vector2.from_angle(ang) * (2.9 + 0.55 * float(i % 2))
		dancers.append([at, (dj - at).normalized()])
	var palms: Array = []
	for k in 6:
		palms.append(c + Vector2.from_angle(TAU * float(k) / 6.0 + 0.3) * (rc - 1.4))
	var parasols: Array = []
	for t: float in [0.9, 3.0]:
		parasols.append(c + Vector2.from_angle(t) * (rc * 0.38))
	return {"groups": groups, "seats": seats, "dj": dj, "dj_face": -north, "dancers": dancers,
			"palms": palms, "parasols": parasols}


## The club for the crowd (crowds.gd): the deck's middle, its height over the ground under the
## outline (as the model's), the layout. {} without the tower in `data` (the streamed index has
## the parts as `site_parts`: bake_sectors.py SITE_NAMES has Spektrum Tower).
static func spektrum_plan(data: Dictionary) -> Dictionary:
	var outline := PackedVector2Array()
	for l: Dictionary in data.get("landmarks", []):
		if str(l.get("name", "")) == "Spektrum Tower":
			var flat: Array = l["p"]
			for i in range(0, flat.size() - 1, 2):
				outline.append(Vector2(float(flat[i]), float(flat[i + 1])))
	if outline.size() < 3:
		return {}
	var drum := PackedVector2Array()
	var drum_h := 0.0
	for bld: Dictionary in plan_parts_of(data):  # the prebuilt game's are `plan_parts` (bake_city.gd)
		var flat: Array = bld["p"]
		if flat.size() < 6 or str(bld.get("c", "")).to_lower() != "#637780" or float(bld.get("mh", 0.0)) > 0.5:
			continue
		var q := PackedVector2Array()
		var mid := Vector2.ZERO
		for i in range(0, flat.size() - 1, 2):
			q.append(Vector2(float(flat[i]), float(flat[i + 1])))
			mid += q[q.size() - 1]
		mid /= float(q.size())
		var h := float(bld.get("h", 0.0))
		if h > drum_h and Geometry2D.is_point_in_polygon(mid, outline):
			drum_h = h
			drum = q
	if drum.size() < 3 or drum_h < 40.0:
		return {}
	var c := Vector2.ZERO
	for q in drum:
		c += q
	c /= float(drum.size())
	var r := 0.0
	for q in drum:
		r += q.distance_to(c)
	r /= float(drum.size())
	var rc := r * 0.72
	return {"outline": outline, "centre": c, "rc": rc, "deck_h": drum_h + SPEKTRUM_CLUB_UP,
			"layout": spektrum_layout(c, rc)}


## The DJ's booth: a black desk with a lit front panel towards the dance floor, a speaker stack
## at each end and a lit truss bar over it on two posts.
func _spektrum_dj(p: Vector2, face: Vector2, deck: float) -> void:
	_o = p + face * 0.75
	_a = face
	_b = Vector2(-face.y, face.x)
	_lbox(0.0, 0.0, 0.35, 1.0, deck, deck + 1.0, Color("#1c1d20"), M_STONE, Color("#2a2c30"))
	_lbox(0.37, 0.0, 0.02, 0.95, deck + 0.15, deck + 0.9, Color("#ff3fb4"), M_LAMP)
	for v: float in [-1.45, 1.45]:
		_lbox(0.0, v, 0.32, 0.32, deck, deck + 1.7, Color("#161719"), M_STONE)
	for v: float in [-1.45, 1.45]:
		_lbox(-0.6, v, 0.06, 0.06, deck, deck + 2.8, Color("#9aa0a5"), M_STONE)
	_lbox(-0.6, 0.0, 0.08, 1.55, deck + 2.8, deck + 2.95, Color("#9fe8ff"), M_LAMP)


## Four white armchairs round a white cube table that glows at night (the photos' lounge
## corners), turned by `t`.
func _spektrum_chairs(p: Vector2, t: float, deck: float) -> void:
	_o = p
	_a = Vector2.from_angle(t)
	_b = Vector2(-_a.y, _a.x)
	_prism(_rect(0.0, 0.0, 0.32, 0.32), deck, deck + 0.5, SPEKTRUM_CUBE, SPEKTRUM_CUBE, M_LAMP, M_LAMP)
	for s in 4:
		var d := Vector2.from_angle(t + TAU * float(s) / 4.0)
		_o = p + d * 0.95
		_a = d
		_b = Vector2(-d.y, d.x)
		_lbox(0.0, 0.0, 0.36, 0.36, deck, deck + 0.42, SPEKTRUM_WHITE, M_STONE)
		_lbox(0.3, 0.0, 0.1, 0.36, deck + 0.42, deck + 0.82, SPEKTRUM_WHITE.darkened(0.04), M_STONE)


## A curved white sofa: five segments on an arc round a cube table and two poufs, its open side
## towards the bar.
func _spektrum_sofa(p: Vector2, t: float, deck: float, c: Vector2) -> void:
	var face := (c - p).normalized()
	var keep := _mode
	for s in 5:
		var ang := face.angle() + PI + (float(s) - 2.0) * 0.45
		var at := p + Vector2.from_angle(ang) * 1.25
		_o = at
		_a = Vector2.from_angle(ang)
		_b = Vector2(-_a.y, _a.x)
		_lbox(0.0, 0.0, 0.32, 0.26, deck, deck + 0.42, SPEKTRUM_WHITE, M_STONE)
		_lbox(0.27, 0.0, 0.1, 0.26, deck + 0.42, deck + 0.8, SPEKTRUM_WHITE.darkened(0.04), M_STONE)
	_prism(_circle(p, 0.3, 4), deck, deck + 0.48, SPEKTRUM_CUBE, SPEKTRUM_CUBE, M_LAMP, M_LAMP)
	for s: float in [-1.0, 1.0]:
		var q := p + face * 0.7 + Vector2(-face.y, face.x) * 0.55 * s
		_prism(_circle(q, 0.25, 6), deck, deck + 0.4, SPEKTRUM_WHITE, SPEKTRUM_WHITE, M_STONE, M_STONE)
	_mode = keep


## A palm in a tall white pot (the photos' terrace palms): a slim trunk and seven fronds.
func _spektrum_palm(p: Vector2, deck: float, k: int) -> void:
	var keep := _mode
	_mode = M_STONE
	_frustum(_circle(p, 0.42, 8), deck, _circle(p, 0.55, 8), deck + 0.95, Color("#efede6"), Color("#4a3a2c"))
	var h := 3.0 + 0.4 * float(k % 3)
	var lean := Vector2.from_angle(float(k) * 1.7) * 0.25
	var crown := Vector3(p.x + lean.x, deck + h, p.y + lean.y)
	_beam(Vector3(p.x, deck + 0.9, p.y), crown, 0.24, Color("#6b5a44"))
	for f in 7:  # odd: two opposite fronds would share a side plane and flicker
		var a := TAU * float(f) / 7.0 + float(k) * 0.5
		var tip := crown + Vector3(cos(a) * 1.5, -0.6 - 0.15 * float(f % 2), sin(a) * 1.5)
		_beam(crown, tip, 0.38, Color("#4f7a3a").lightened(0.05 * float(f % 3)))
	_mode = keep


## The names: the tower's (parody) on the crown's screens to the south and north, the club's on
## the screens to the east and west, the neon lit at night.
func _spektrum_signs(c: Vector2, r: float, top: float) -> void:
	var rs := r + 0.45
	var mid_y := top + SPEKTRUM_SCREEN_TOP * 0.5 - 0.2
	for d: Vector2 in [Vector2(0, 1), Vector2(0, -1)]:
		var k := 10.0 / Neon.length_of(SPEKTRUM_SIGN)
		var y := mid_y - Neon.ROW_H * Neon.PIXEL * k * 0.5
		var at := c + d * rs
		signs.append([SPEKTRUM_SIGN, Vector3(at.x, y, at.y), Vector3(d.x, 0.0, d.y), k, Color(0.88, 0.97, 1.0)])
	for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0)]:
		var k := 7.0 / Neon.length_of(SPEKTRUM_CLUB)
		var y := mid_y - Neon.ROW_H * Neon.PIXEL * k * 0.5
		var at := c + d * rs
		signs.append([SPEKTRUM_CLUB, Vector3(at.x, y, at.y), Vector3(d.x, 0.0, d.y), k, Color(1.0, 0.35, 0.8)])


# --- Q22 and Rondo 1 (the top-50 photo pass, 2026-11-08) ---------------------------------------

## Q22 (Al. Jana Pawła II 22, 2016, 155 m), rebuilt from the top-50 photo set (T02: the tower
## from Rondo ONZ, two views from Varso, its crown close, the skyline from the west; spec
## docs/landmarks/specs/q22.md). The mapped parts: the shaft (the five-sided outline, 155 m), the
## 60 m wing on its south-east side, a two-storey glass base and the roof's mast. The shaft is
## dark green glass in fine floor bands; its top four storeys (141 to 155 m) are a solid
## graphite crown 0.15 m proud of the glass, with the tenant's name (the parody DELOJT) on it in
## white. The wing's roof is one sloping glass plane, high against the shaft and 9 m lower at its
## south-east edge. On the roof the plant behind a parapet, a grey lattice mast (155 to 172 m)
## and over it the red-and-white antenna to 195 m.
const Q22_SHAFT_H := 155.0
const Q22_CROWN := 14.0             ## the graphite crown's height (T02-02, about four storeys)
const Q22_WING_H := 60.0
const Q22_WING_DROP := 9.0          ## the wing's glass roof falls this much away from the shaft
const Q22_LATTICE := 172.0          ## the lattice mast's top (T02-02)
const Q22_ANTENNA := 195.0          ## the antenna's tip (OSM)
const Q22_GLASS := Color("#3f5e5c")     ## dark green glass, a step paler than the photos
const Q22_CROWN_COL := Color("#40464b") ## the crown's graphite panels (T02-02)
const Q22_BASE_GLASS := Color("#526a6c")
const Q22_ROOF := Color("#9ea4a6")
const Q22_WING_ROOF := Color("#33464c") ## the wing's glass roof, dark (T02-01, T02-06)
const Q22_SIGN := Color(0.96, 0.97, 1.0)


func _build_q22(zone: PackedVector2Array, spec: Dictionary) -> void:
	_g = _ground_under(zone)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var bands := M_SKIN + float(S_BANDS) / 16.0
	var dark := M_SKIN + float(S_DARK) / 16.0
	var parts := _parts_in(zone, func(b: Dictionary) -> bool: return float(b["h"]) > float(b["mh"]) + 0.5)
	var shaft := PackedVector2Array()
	var wing := PackedVector2Array()
	var mast_at := Vector2.INF
	for b in parts:
		var poly := _pts(b["p"])
		var h := float(b["h"])
		var small := _box_of([poly]).size.length() < 9.0
		if small:
			# The mast's mapped pieces: only where it stands is used (the lattice's footprint).
			if absf(h - 159.0) < 0.5 and float(b["mh"]) > 150.0:
				mast_at = _centre(poly)
			continue
		if absf(h - Q22_SHAFT_H) < 0.5:
			shaft = poly
		elif absf(h - Q22_WING_H) < 0.5:
			wing = poly
		elif h < 12.0:
			# The glass base: one or two storeys round the shaft and the wing.
			_prism(poly, g - 0.4, g + h, Q22_BASE_GLASS, Q22_ROOF, bands, M_STONE)
			_collide(poly)
	if shaft.size() < 3 or wing.size() < 3:
		push_warning("landmarks: Q22's mapped shaft or wing is missing")
		return
	# The wing: glass to a roof that slopes away from the shaft (the high side `slope_to`).
	var to_shaft := (_centre(shaft) - _centre(wing)).normalized()
	_tower_cut(wing, g - 0.4, g + Q22_WING_H, {"slope_to": to_shaft, "cut_drop": Q22_WING_DROP},
			Q22_GLASS, Q22_WING_ROOF, bands)
	_collide(wing)
	# The shaft: glass to the crown, the crown proud of it, the roof and its parapet.
	var top := g + Q22_SHAFT_H
	_prism(shaft, g - 0.4, top - Q22_CROWN, Q22_GLASS, none, bands)
	var proud := Geometry2D.offset_polygon(shaft, 0.15, Geometry2D.JOIN_MITER)
	var crown: PackedVector2Array = proud[0] if proud.size() == 1 else shaft
	_prism(crown, top - Q22_CROWN, top, Q22_CROWN_COL, Q22_ROOF, dark, M_STONE)
	_collide(shaft)
	_tower_roof(crown, top, Q22_CROWN_COL.lightened(0.1), Vector2.ZERO)
	# The plant: a low grey box on the roof's middle, under the mast.
	var plant := Geometry2D.offset_polygon(shaft, -6.0)
	if plant.size() == 1:
		_prism(plant[0], top, top + 3.5, Color("#8d9396"), Color("#a3a8aa"), M_STONE, M_STONE)
	# The mast: the grey lattice (an open frame on a 3.6 m square) and the antenna in red and white.
	if mast_at == Vector2.INF:
		mast_at = _centre(shaft)
	_prism(_square(mast_at, 1.8), top + 3.5, g + Q22_LATTICE, Color("#9aa0a4"), none, M_SKIN + float(S_FRAME) / 16.0)
	_prism(_square(mast_at, 1.8), g + Q22_LATTICE, g + Q22_LATTICE + 0.4, Color("#9aa0a4"), Color("#9aa0a4"), M_STONE, M_STONE)
	var seg := (Q22_ANTENNA - Q22_LATTICE - 0.4) / 5.0
	for k in 5:
		var c := Color("#c8302a") if k % 2 == 0 else Color("#ecebe6")
		var y0 := g + Q22_LATTICE + 0.4 + seg * k
		_prism(_square(mast_at, 0.45 - 0.05 * k), y0, y0 + seg, c, c, M_STONE, M_STONE)
	_prism(_square(mast_at, 0.3), g + Q22_ANTENNA, g + Q22_ANTENNA + 0.8, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	# The name in white on the crown, on the faces seen from Rondo ONZ and from Varso.
	_crown_signs(crown, top, str(spec["sign"]), Q22_SIGN, 4.0, 0.6)
	var roof_y := func(_q: Vector2) -> float: return top + 1.5
	_aviation(shaft, roof_y)


## Rondo 1 (Rondo ONZ 1, 2006, 159 m, 192 m to the antenna), rebuilt from the top-50 photo set
## (T03: the tower from Rondo ONZ by day and by night, two views from Varso, the stepped back
## from Śliska, the roof from the Palace; spec docs/landmarks/specs/rondo1.md). The long slab
## with its rounded north end, towards the roundabout, is silver-blue glass in floor bands; its
## glass runs on over the roof as a screen of open framing, 12 m tall over the rounded end and
## 4 m at the south end. The narrow west block is a graphite slab, flat-topped at 159 m, the
## tenant's name (the parody EJ under a yellow stroke) on its north and south faces. Behind it
## the glass steps down to the south-west (146, 125 and 80 m). On the roof the plant, a lattice
## and the red-and-white antenna to 192 m.
const R1_TOP := 159.0
const R1_ANTENNA := 192.0
const R1_SCREEN_HI := 12.0     ## the screen over the rounded north end (T03-05)
const R1_SCREEN_LO := 4.0      ## and over the south end
const R1_GLASS := Color("#8aa3b5")     ## silver-blue glass in light floor bands (T03-05, T03-08)
const R1_SLAB := Color("#3b4147")      ## the west block's graphite panels (T03-02, T03-05)
const R1_SCREEN := Color("#b9c2c8")    ## the screen's silver framing
const R1_ROOF := Color("#a9b3b9")
const R1_BASE := Color("#7c8e9a")
const R1_STROKE := Color(1.0, 0.86, 0.1)


func _build_rondo1(zone: PackedVector2Array, spec: Dictionary) -> void:
	_g = _ground_under(zone)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var bands := M_SKIN + float(S_BANDS) / 16.0
	var dark := M_SKIN + float(S_DARK) / 16.0
	var parts := _parts_in(zone, func(b: Dictionary) -> bool: return float(b["h"]) > float(b["mh"]) + 0.5)
	parts = parts.filter(func(b: Dictionary) -> bool: return str(b.get("name", "")) != spec.get("osm", ""))
	var main := PackedVector2Array()
	var slab := PackedVector2Array()
	for b in parts:
		var poly := _pts(b["p"])
		var h := float(b["h"])
		var mh := float(b["mh"])
		if _box_of([poly]).size.length() < 9.0:
			continue  # the roof's mapped bits (the mast is built below)
		if absf(h - R1_TOP) < 0.5:
			# The three parts at 159 m: the slab with the rounded end (the largest), the west block,
			# and a white sliver along the block's north face (taken into the block's cladding).
			var area := absf(_area(poly))
			if area > 600.0:
				main = poly
			elif area > 40.0:
				slab = poly
			continue
		var base := g + mh - (0.4 if mh < 0.5 else 0.0)
		if h >= 40.0:
			# The steps down to the south-west: the slab's glass, a parapet on each roof.
			_prism(poly, base, g + h, R1_GLASS, R1_ROOF, bands, M_STONE)
			_tower_roof(poly, g + h, R1_ROOF.darkened(0.1), Vector2.ZERO)
		else:
			# The base and the neighbours in the outline, in their mapped colours where mapped
			# (the car park's teal); Rondo 1's own base a darker glass.
			var col := R1_BASE if str(b.get("c", "")).to_upper() == "#87CEEB" else _osm(b["c"], R1_BASE)
			_prism(poly, base, g + h, col, R1_ROOF, bands, M_STONE)
		if mh < 2.0:
			_collide(poly)
	if main.size() < 3 or slab.size() < 3:
		push_warning("landmarks: Rondo 1's mapped slab or west block is missing")
		return
	var top := g + R1_TOP
	# The slab: glass to the roof, then the screen of open framing over its edge, falling from the
	# rounded north end to the south end (the high side `slope_to`, along the slab).
	_prism(main, g - 0.4, top, R1_GLASS, R1_ROOF, bands, M_STONE)
	_collide(main)
	var north := Vector2(0.0, -1.0)
	_tower_cut(main, top, top + R1_SCREEN_HI, {"slope_to": north, "cut_drop": R1_SCREEN_HI - R1_SCREEN_LO},
			R1_SCREEN, none, M_SKIN + float(S_FRAME) / 16.0)
	var plant := Geometry2D.offset_polygon(main, -5.0)
	if plant.size() >= 1:
		_prism(plant[0], top, top + 3.0, Color("#8f979b"), Color("#a6adb0"), M_STONE, M_STONE)
	# The west block: graphite, 0.15 m proud where it meets the slab's glass.
	var proud := Geometry2D.offset_polygon(slab, 0.15, Geometry2D.JOIN_MITER)
	var block: PackedVector2Array = proud[0] if proud.size() == 1 else slab
	_prism(block, g - 0.4, top + 1.0, R1_SLAB, R1_SLAB.lightened(0.15), dark, M_STONE)
	_collide(slab)
	# The name on the block's north and south faces: EJ, a yellow stroke over it.
	for i in block.size():
		var a := block[i]
		var b := block[(i + 1) % block.size()]
		var o := _out(block, a, b)
		if absf(o.y) < 0.7 or a.distance_to(b) < 6.0:
			continue
		_face_sign(a, b, o, top - 9.0, "EJ", Color(0.95, 0.95, 0.93), 0.55)
		_face_sign(a, b, o, top - 3.0, "--", R1_STROKE, 0.4)
	# The mast: a lattice on the plant, then the antenna in red and white to 192 m; it stands on
	# the slab's middle, a little south of the centre (T03-02).
	var c := _centre(main)
	var foot := c + (c - _centre(PackedVector2Array([main[0], main[main.size() - 1]]))).normalized() * 6.0
	if not Geometry2D.is_point_in_polygon(foot, main):
		foot = c
	_prism(_square(foot, 1.5), top + 3.0, top + 12.0, Color("#9aa0a4"), none, M_SKIN + float(S_FRAME) / 16.0)
	var seg := (g + R1_ANTENNA - top - 12.0) / 6.0
	for k in 6:
		var col := Color("#c8302a") if k % 2 == 0 else Color("#ecebe6")
		_prism(_square(foot, 0.5 - 0.05 * k), top + 12.0 + seg * k, top + 12.0 + seg * (k + 1), col, col, M_STONE, M_STONE)
	_prism(_square(foot, 0.3), g + R1_ANTENNA, g + R1_ANTENNA + 0.8, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	# The clinic's name over the ground floor (kept from the tower table).
	if spec.has("base_sign"):
		_crown_signs(main, g + 5.2, str(spec["base_sign"]), Color(0.75, 1.0, 0.95), 0.0, 0.3)
	var roof_y := func(_q: Vector2) -> float: return top + 3.0
	_aviation(main, roof_y)


## A sign on one face (a→b, outward `o`), its letters' middle `y`, as wide as `share` of the face.
func _face_sign(a: Vector2, b: Vector2, o: Vector2, y: float, word: String, colour: Color, share: float) -> void:
	var mid := (a + b) * 0.5
	var k := share * a.distance_to(b) / Neon.length_of(word)
	signs.append([word, Vector3(mid.x, y - Neon.ROW_H * Neon.PIXEL * k * 0.5, mid.y), Vector3(o.x, 0.0, o.y), k, colour])


## Emilii Plater 53 at street level, from F's photos (2026-11-08, /mnt/project-files/shisha-lounge/
## photos/07-13): the podium's granite in bands over its glass, with thin sun fins over each glass
## ribbon (photos 7, 8); a black granite base band and granite piers along both street faces
## (photos 12, 13); on the Emilii Plater face the porte-cochère: a steel canopy with a curved front
## on one round steel column, the revolving door's glass drum under it, the black plinth with the
## address in silver, the parody coffee shop's name on the glass beside it and SENATOREK in gold on
## the canopy's fascia (the shisha lounge upstairs, docs/design/shisha-lounge.md).
const WCF_DOOR_T := 0.45       ## where the portico stands along the east face (WCF_LOW's first edge)
const WCF_STEEL := Color("#b9bdc1")
const WCF_BLACK := Color("#1d1d20")
const WCF_GOLD := Color("#e2bf7a")


func _wcf_street(base: PackedVector2Array, g: float) -> void:
	# The base band: black granite 0.8 m, just proud of the plinth.
	var band := Geometry2D.offset_polygon(base, 0.35, Geometry2D.JOIN_MITER)
	if band.size() == 1:
		_prism(band[0], g - 0.4, g + 0.8, WCF_BLACK, WCF_BLACK, M_STONE, M_STONE)
	# Granite bands over the podium's glass, a thin fin over each glass ribbon.
	var skin := Geometry2D.offset_polygon(base, 0.25, Geometry2D.JOIN_MITER)
	var fin := Geometry2D.offset_polygon(base, 1.1, Geometry2D.JOIN_MITER)
	if skin.size() == 1 and fin.size() == 1:
		for b: Vector2 in [Vector2(8.4, 10.6), Vector2(13.6, 15.8)]:
			_prism(skin[0], g + b.x, g + b.y, WCF_STONE, WCF_STONE.lightened(0.1), M_STONE, M_STONE)
		for y: float in [5.4, 10.8, 16.0]:
			_prism(fin[0], g + y, g + y + 0.16, WCF_STEEL, WCF_STEEL, M_STONE, M_STONE)
	# The east face (to Emilii Plater) and the north face (to Świętokrzyska): granite piers.
	var a0: Vector2 = WCF_LOW[0]
	var a1: Vector2 = WCF_LOW[1]
	var n := _out(base, a0, a1)
	var t_len := a0.distance_to(a1)
	var along := (a1 - a0) / t_len
	_o = a0
	_a = n
	_b = along
	for k in int(t_len / 4.6):
		if absf((2.3 + 4.6 * k) / t_len - WCF_DOOR_T) < 0.16:
			continue  # the portico's opening
		_lbox(0.55, 2.3 + 4.6 * k, 0.6, 0.6, g - 0.4, g + 5.2, WCF_STONE.lightened(0.04), M_STONE)
	var b0: Vector2 = WCF_HIGH[15]
	var b1: Vector2 = WCF_HIGH[16]
	var nb := _out(base, b0, b1)
	var b_len := b0.distance_to(b1)
	_o = b0
	_a = nb
	_b = (b1 - b0) / b_len
	for k in int(b_len / 4.6):
		_lbox(0.55, 2.3 + 4.6 * k, 0.6, 0.6, g - 0.4, g + 5.2, WCF_STONE.lightened(0.04), M_STONE)
	# The porte-cochère.
	var door := a0.lerp(a1, WCF_DOOR_T)
	_o = door
	_a = n
	_b = along
	# The canopy: 0.5 m thick at 5.6 m, 7 m out, its front a shallow curve (photo 13).
	var canopy := PackedVector2Array([_w(0.0, -4.8), _w(0.0, 4.8)])
	for k in 9:
		var s := 1.0 - 2.0 * k / 8.0
		canopy.append(_w(6.2 + 0.8 * (1.0 - s * s), 4.8 * s))
	_prism(canopy, g + 5.6, g + 6.1, WCF_STEEL, WCF_STEEL.lightened(0.08), M_STONE, M_STONE)
	# Its soffit's downlights, lit at night.
	for u: float in [1.5, 3.5, 5.5]:
		for v: float in [-2.8, 0.0, 2.8]:
			_lbox(u, v, 0.12, 0.12, g + 5.5, g + 5.6, Color("#fff1c8"), M_LAMP)
	# The round steel column with its black foot, under the canopy's middle.
	var col := _w(4.6, 0.0)
	_prism(_circle(col, 0.42, 10), g - 0.4, g + 0.9, WCF_BLACK, WCF_BLACK, M_STONE, M_STONE)
	_prism(_circle(col, 0.36, 10), g + 0.9, g + 5.6, WCF_STEEL, WCF_STEEL, M_STONE, M_STONE)
	_collide(_circle(col, 0.5, 6))
	# The revolving door: a lit glass drum and its steel cap, glass doors either side.
	var drum := _w(0.9, 0.0)
	_prism(_circle(drum, 1.5, 12), g, g + 2.7, Color("#a8c4c8"), Color(0, 0, 0, 0), M_PAVILION + 0.5)
	_prism(_circle(drum, 1.6, 12), g + 2.7, g + 3.0, WCF_STEEL, WCF_STEEL, M_STONE, M_STONE)
	for v: float in [-3.0, 3.0]:
		_lbox(0.35, v, 0.12, 1.0, g, g + 2.6, Color("#a8c4c8"), M_PAVILION + 0.5)
	# The plinth with the address (photo 13): black granite right of the door, silver letters.
	_lbox(0.45, 4.4, 0.25, 1.2, g, g + 1.4, WCF_BLACK, M_STONE)
	var plate := _w(0.72, 4.4)
	signs.append(["EMILII PLATER 53", Vector3(plate.x, g + 0.9, plate.y), Vector3(n.x, 0.0, n.y), 0.06, Color("#d8dade")])
	# The lounge's name in gold on the canopy's fascia, and the coffee shop on the glass left of the door.
	var fascia := _w(7.05, 0.0)
	signs.append(["SENATOREK", Vector3(fascia.x, g + 5.63, fascia.y), Vector3(n.x, 0.0, n.y), 0.21, WCF_GOLD])
	var cafe := _w(0.45, -6.4)
	signs.append(["COFFEECHAIR", Vector3(cafe.x, g + 3.6, cafe.y), Vector3(n.x, 0.0, n.y), 0.12, Color("#e9f2ea")])


## The lounge's roof terrace on the glass slab's set-back (F's photos 1, 4 and 10: lit
## setbacks, a glass balustrade, the Palace beyond): a glass rail round the ledge and warm lamps
## along it, lit at night.
func _wcf_terrace(low: PackedVector2Array, y: float) -> void:
	for i in low.size():
		var a := low[i]
		var b := low[(i + 1) % low.size()]
		var length := a.distance_to(b)
		if length < 2.0:
			continue
		var n := _out(low, a, b)
		var rail := PackedVector2Array([a - n * 0.05, b - n * 0.05, b - n * 0.18, a - n * 0.18])
		_prism(rail, y + 0.3, y + 1.4, Color("#9fc0c4"), Color(0, 0, 0, 0), M_PAVILION + 0.5)
		for k in int(length / 6.0):
			var p := a.lerp(b, (k + 0.5) * 6.0 / length) - n * 0.9
			_prism(_square(p, 0.14), y + 0.3, y + 0.9, Color("#ffd89a"), Color("#ffd89a"), M_LAMP, M_LAMP)


## Skyliner's cut roof (the photo report, 2026-11-03): the shaft's top falls 24 m from the side
## `slope_to` points at to the far side, and a glass fin stands on the high edge, rising 20 m over
## it. Walls from `y0`; the roof is the sloped plane.
func _tower_cut(poly: PackedVector2Array, y0: float, hi: float, spec: Dictionary, wall: Color, roof: Color, skin: float) -> void:
	var axis: Vector2 = (spec["slope_to"] as Vector2).normalized()
	var c := _centre(poly)
	var lo_d := INF
	var hi_d := -INF
	for q in poly:
		lo_d = minf(lo_d, (q - c).dot(axis))
		hi_d = maxf(hi_d, (q - c).dot(axis))
	var drop: float = spec.get("cut_drop", 24.0)
	var top := func(q: Vector2) -> float:
		return lerpf(hi - drop, hi, inverse_lerp(lo_d, hi_d, (q - c).dot(axis)))
	var keep := _mode
	_mode = skin
	var run := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var ta: float = top.call(a)
		var tb: float = top.call(b)
		var n := _out(poly, a, b)
		var nv := Vector3(n.x, 0.0, n.y)
		var l := a.distance_to(b)
		# The straight part through _wall (it clips what the site's other walls already cover in
		# the plane: the mast's and the crown's), the sloped strip over it as one triangle or two.
		var low := minf(ta, tb)
		_wall(a, b, y0, low, n, wall, run)
		if absf(ta - tb) > 0.01:
			if ta > tb:
				_tri(Vector3(a.x, low, a.y), Vector3(b.x, low, b.y), Vector3(a.x, ta, a.y), nv, wall,
						Vector2(run, low - _g), Vector2(run + l, low - _g), Vector2(run, ta - _g), ta - _g)
			else:
				_tri(Vector3(a.x, low, a.y), Vector3(b.x, low, b.y), Vector3(b.x, tb, b.y), nv, wall,
						Vector2(run, low - _g), Vector2(run + l, low - _g), Vector2(run + l, tb - _g), tb - _g)
		run += l
	_mode = M_STONE
	# The sloped roof over the outline, untangled first (a mapped outline that doubles back would
	# triangulate into overlapping triangles: _cap does the same). A clear roof colour leaves it
	# open (Rondo 1's screen: walls only).
	if roof.a > 0.0:
		for flat in Geometry2D.merge_polygons(poly, PackedVector2Array()):
			if flat.size() >= 3 and not Geometry2D.is_polygon_clockwise(flat):
				_cut_roof(flat, top, roof)
	if spec.has("fin"):
		_cut_fin(poly, c, axis, hi, top, Color(spec["fin"]))
	_mode = keep


func _cut_roof(poly: PackedVector2Array, top: Callable, roof: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	for i in range(0, idx.size(), 3):
		var p0 := poly[idx[i]]
		var p1 := poly[idx[i + 1]]
		var p2 := poly[idx[i + 2]]
		var v0 := Vector3(p0.x, top.call(p0), p0.y)
		var v1 := Vector3(p1.x, top.call(p1), p1.y)
		var v2 := Vector3(p2.x, top.call(p2), p2.y)
		var nrm := (v1 - v0).cross(v2 - v0).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		_tri(v0, v1, v2, nrm, roof, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## Skyliner's glass fin: a plate along the cut's high edge, 0.6 m thick, 20 m over the cut.
func _cut_fin(poly: PackedVector2Array, c: Vector2, axis: Vector2, hi: float, top: Callable, col: Color) -> void:
	var best := 0
	var best_dot := -INF
	for i in poly.size():
		var d := ((poly[i] + poly[(i + 1) % poly.size()]) * 0.5 - c).dot(axis)
		if d > best_dot and poly[i].distance_to(poly[(i + 1) % poly.size()]) > 10.0:
			best_dot = d
			best = i
	var a := poly[best]
	var b := poly[(best + 1) % poly.size()]
	var inward := -_out(poly, a, b)
	# 0.1 m in from the face, so the plate never shares the shaft's plane.
	var f0 := a.lerp(b, 0.15) + inward * 0.1
	var f1 := a.lerp(b, 0.6) + inward * 0.1
	var fin := PackedVector2Array([f0, f1, f1 + inward * 0.6, f0 + inward * 0.6])
	_prism(fin, minf(top.call(f0), top.call(f1)) - 1.0, hi + 20.0, col, col.lightened(0.2), M_PAVILION + 0.5, M_STONE)


## Warsaw Unit's black strips (the photo report): a 4.5 m strip at each end and in the middle of
## every long face, 0.15 m proud of the glass, from `y0` to `y1`.
func _tower_strips(poly: PackedVector2Array, y0: float, y1: float, col: Color, c := Vector2.ZERO, s0 := 1.0, s1 := 1.0) -> void:
	var longest := 0.0
	for i in poly.size():
		longest = maxf(longest, poly[i].distance_to(poly[(i + 1) % poly.size()]))
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var l := a.distance_to(b)
		if l < longest * 0.5 or l < 20.0:
			continue
		var e := (b - a) / l
		var o := _out(poly, a, b) * 0.15
		for t: float in [0.0, 0.5 * l - 2.25, l - 4.5]:
			var p0 := a + e * t
			var p1 := a + e * (t + 4.5)
			var strip := PackedVector2Array([p0, p1, p1 + o, p0 + o])
			if absf(s0 - 1.0) < 0.0005 and absf(s1 - 1.0) < 0.0005:
				_prism(strip, y0, y1, col, col, M_SKIN + float(S_DARK) / 16.0, M_STONE)
			else:
				# RD-1: on the tapering shaft the strip leans in with the glass.
				var keep := _mode
				_mode = M_SKIN + float(S_DARK) / 16.0
				_frustum(_scaled(strip, c, s0), y0, _scaled(strip, c, s1), y1, col)
				_mode = keep


## Warsaw UNIT's Dragon Skin box: the OpenStreetMap colours of its parts (the box and its corner
## piece), the silver fascia over it, the green wall's leaves and the box's tenant sign.
const UNIT_SKIN_COLOURS := ["#485477", "#647481"]
const UNIT_FASCIA := Color("#c3c8cd")
const UNIT_LEAVES: Array[Color] = [Color("#3f6b34"), Color("#557d3a"), Color("#2f5a2e"), Color("#6b8a45")]
const UNIT_TENANT := "MODERATO"   ## the red name on the skin's top (a parody of the tenant's logo)
const UNIT_TENANT_COL := Color(1.0, 0.16, 0.14)


## Warsaw UNIT's Dragon Skin box (F's photos and notes, Mapillary 2020-26, 2026-11-19): the plates
## are the skin (building.gdshader S_SCALES); here the green wall, a planted strip 4.5 m wide in a
## recess at the south end of the box's east face (the night photo, the notes' third picture),
## its leaves in clumps, and the tenant's red name across the top of that face.
func _unit_skin_dress(parts: Array, g: float) -> void:
	var box := PackedVector2Array()
	var top := 0.0
	for b: Dictionary in parts:
		if str(b.get("c", "")).to_lower() == UNIT_SKIN_COLOURS[0] and float(b["mh"]) >= 8.5:
			box = _pts(b["p"])
			top = float(b["h"])
	if box.size() < 3:
		return
	# the east face: the longest edge whose outward normal points most to +x
	var best := -1
	var score := -INF
	for i in box.size():
		var a := box[i]
		var b := box[(i + 1) % box.size()]
		var l := a.distance_to(b)
		var sc := _out(box, a, b).x * l
		if l > 12.0 and sc > score:
			score = sc
			best = i
	if best < 0:
		return
	var a := box[best]
	var b := box[(best + 1) % box.size()]
	var o := _out(box, a, b)
	var e := (b - a).normalized()
	var l := a.distance_to(b)
	# the south end of the face (the larger z)
	var t0 := l - 6.0 if b.y > a.y else 1.5
	var p0 := a + e * t0
	var p1 := a + e * (t0 + 4.5)
	var y0 := g + 9.6
	var y1 := g + top - 0.4
	var keep := _mode
	_mode = M_STONE
	# the planted panel, 0.25 m proud, then the clumps on it (a fixed hash picks size and green)
	_prism(PackedVector2Array([p0, p1, p1 + o * 0.25, p0 + o * 0.25]), y0, y1, UNIT_LEAVES[2], UNIT_LEAVES[0], M_STONE, M_STONE)
	var rows := int((y1 - y0) / 1.3)
	for r in rows:
		for c in 3:
			var hsh := hash(Vector2i(r, c + 31))
			var w := 0.9 + 0.5 * float(hsh % 7) / 6.0
			var at := 0.4 + c * 1.45 + float(hsh % 5) * 0.08
			var q0 := p0 + e * at
			var q1 := p0 + e * minf(at + w, 4.4)
			var y := y0 + r * 1.3 + float(hsh % 3) * 0.2
			var col: Color = UNIT_LEAVES[hsh % UNIT_LEAVES.size()]
			_prism(PackedVector2Array([q0, q1, q1 + o * 0.6, q0 + o * 0.6]), y, minf(y + 1.1, y1), col, col.lightened(0.12), M_STONE, M_STONE)
	_mode = keep
	# the tenant's name: centred on the rest of the face, 3 m letters a little under the top
	var mid := a + e * ((l - 6.0) * 0.5 if b.y > a.y else 6.0 + (l - 6.0) * 0.5) + o * 0.05
	var k := 3.0 / (Neon.ROW_H * Neon.PIXEL)
	signs.append([UNIT_TENANT, Vector3(mid.x, y1 - 3.4, mid.y), Vector3(o.x, 0.0, o.y), k, UNIT_TENANT_COL])


## The Rondo Daszyńskiego towers' shop signs (F, 2026-11-19: "signs to bring life"): each entry
## [word, colour, t, inset] goes on the ground-floor face of the site that looks most towards the
## Rondo (or along `dir`, where the Rondo-facing face looks into a narrow gap), `t` of the way along it, `inset` m in (Mennica's lobby stands behind its columns): a dark
## fascia board 0.12 m proud with the lit word 0.9 m tall on it, 3.4 m over the pavement.
const RONDO_D := Vector2(-2697.0, 406.0)


func _shop_signs(parts: Array, g: float, shops: Array, dir := Vector2.ZERO) -> void:
	var best_a := Vector2.ZERO
	var best_b := Vector2.ZERO
	var best_o := Vector2.ZERO
	var score := -INF
	for b: Dictionary in parts:
		if float(b["mh"]) > 0.5 or float(b["h"]) < 5.0:
			continue
		var poly := _pts(b["p"])
		for i in poly.size():
			var a := poly[i]
			var c := poly[(i + 1) % poly.size()]
			var l := a.distance_to(c)
			if l < 10.0:
				continue
			var o := _out(poly, a, c)
			var to := dir if dir != Vector2.ZERO else (RONDO_D - (a + c) * 0.5).normalized()
			var sc := o.dot(to) * minf(l, 30.0)
			if sc > score:
				score = sc
				best_a = a
				best_b = c
				best_o = o
	if score <= 0.0:
		return
	var e := (best_b - best_a).normalized()
	var keep := _mode
	_mode = M_STONE
	for s: Array in shops:
		var word := str(s[0])
		var inset := float(s[3]) if s.size() > 3 else 0.0
		var y := g + (float(s[4]) if s.size() > 4 else 3.2)  # the board's foot over the ground
		var tall := float(s[5]) if s.size() > 5 else 0.9  # the letters' height
		var k := tall / (Neon.ROW_H * Neon.PIXEL)
		var mid := best_a.lerp(best_b, float(s[2])) - best_o * inset
		var half := 0.5 * k * Neon.length_of(word) + 0.4
		var board := PackedVector2Array([mid - e * half, mid + e * half, mid + e * half + best_o * 0.12, mid - e * half + best_o * 0.12])
		_prism(board, y, y + tall + 0.4, SHOP_BOARD, SHOP_BOARD, M_STONE, M_STONE)
		var at := mid + best_o * (0.12 - 0.38)  # map_builder puts the letters 0.4 m out: 2 cm off the board
		signs.append([word, Vector3(at.x, y + 0.2, at.y), Vector3(best_o.x, 0.0, best_o.y), k, Color(str(s[1]))])
	_mode = keep


const SHOP_BOARD := Color("#23272c")


## The hotel's dark band over its glazed ground floors (the HUB photo report), 0.2 m proud.
func _tower_band(poly: PackedVector2Array, y0: float, y1: float, col: Color) -> void:
	var wide := Geometry2D.offset_polygon(poly, 0.2)
	if wide.size() == 1:
		_prism(wide[0], y0, y1, col, col, M_STONE, M_STONE)


## A plan scaled by `k` about `c` (RD-1's taper).
func _scaled(poly: PackedVector2Array, c: Vector2, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in poly:
		out.append(c + (q - c) * k)
	return out


## RD-1 Warsaw Unit's gate (the report, street photos 2026-11-06): the base wings lifted 9 m stand
## over a glass hall set `inset` in, lit cool at night, under the wings' dark soffit.
func _gate_hall(lifted: Array[PackedVector2Array], g: float, lift: float, inset: float, col: Color) -> void:
	# The wings overlap (OpenStreetMap maps the base twice): one outline, their union's outer ring.
	var acc := lifted[0]
	for i in range(1, lifted.size()):
		acc = _largest(Geometry2D.merge_polygons(acc, lifted[i]))
	for m: PackedVector2Array in [acc]:
		_soffit(m, g + lift, col.darkened(0.35))
		var hall := Geometry2D.offset_polygon(m, -inset)
		for h in hall:
			if not Geometry2D.is_polygon_clockwise(h):
				_prism(h, g - 0.4, g + lift, Color("#9fb9cc"), Color(0, 0, 0, 0), M_PAVILION + 0.5, M_STONE)
		_collide(m)


## RD-3 Generation Park Y's black spandrels (the report, photo 1): on each face 3 m bays a storey
## (3.9 m) tall; every few storeys a row holds a patch a bay or two wide, and the top two storeys
## are dark under a 1.2 m white parapet. Panels 0.1 m proud of the glass, picked by a fixed hash.
func _tower_patches(poly: PackedVector2Array, y0: float, y1: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var white := Color("#e3e1da")
	var run := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var l := a.distance_to(b)
		var o := _out(poly, a, b)
		var e := (b - a) / maxf(l, 0.01)
		var lo := a + o * 0.1
		if l >= 6.0:
			var bays := int(l / 3.0)
			var pad := (l - bays * 3.0) * 0.5
			for lv in range(2, int((y1 - y0) / 3.9) - 2):
				var row := hash(Vector2i(lv, 7)) % 100
				if row >= 24:
					continue
				for bay in bays:
					var r := hash(Vector3i(bay + int(run), lv, i)) % 100
					if r >= 22:
						continue
					var w := 6.0 if r < 8 and bay < bays - 1 else 3.0
					var t := pad + bay * 3.0
					_wall(lo + e * t, lo + e * (t + w), y0 + lv * 3.9, y0 + (lv + 1) * 3.9, o, col)
		# the dark top storeys and the white parapet over them, all round
		_wall(lo, lo + e * l, y1 - 7.8, y1 - 1.2, o, col)
		_wall(lo, lo + e * l, y1 - 1.2, y1 + 0.3, o, white)
		run += l
	_mode = keep


## RD-4 the HUB's roofs (the report's ortho): a 1.5 m parapet with a silver edge, its inner face
## too, and a grey plant block of `plant` metres (along the longest edge, across) in the middle.
## With `screen` (F's HUB photos, 2026-11-19) the curtain wall runs on that far over the roof in the
## tower's own glass, hiding the plant, under a dark crown band and a silver coping.
func _tower_roof(poly: PackedVector2Array, y: float, col: Color, plant: Vector2, screen := 0.0,
		glass := Color.WHITE) -> void:
	var keep := _mode
	_mode = M_STONE
	var top := y + (screen if screen > 0.0 else 1.5)
	if screen > 0.0:
		# plain glass: the skin would light rooms in it at night, and there are none up there
		_prism(poly, y, top, glass.darkened(0.08), Color(0, 0, 0, 0), M_STONE)
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var o := _out(poly, a, b)
			_wall(a + o * 0.08, b + o * 0.08, top - 1.8, top - 0.4, o, HUB_CROWN)
			_wall(a + o * 0.1, b + o * 0.1, top - 0.4, top, o, col)  # the silver coping
	else:
		_prism(poly, y, top, col, Color(0, 0, 0, 0), M_STONE)
		# The deck inside the parapet: without it the tower's top was an open box (F, 2026-11-24:
		# Cosmopolitan and the Warsaw Financial Centre showed the podium through their roofs).
		_cap(poly, y - 0.05, col.darkened(0.05))
	var inner := Geometry2D.offset_polygon(poly, -0.3)
	if inner.size() == 1:
		var r := inner[0]
		for i in r.size():
			var a := r[i]
			var b := r[(i + 1) % r.size()]
			_wall(a, b, y, top, -_out(r, a, b), col.darkened(0.15))
	if plant.x > 0.0:
		var c := _centre(poly)
		var e := Vector2.RIGHT
		var longest := 0.0
		for i in poly.size():
			var d := poly[(i + 1) % poly.size()] - poly[i]
			if d.length() > longest:
				longest = d.length()
				e = d.normalized()
		var n := Vector2(-e.y, e.x)
		var hx := e * plant.x * 0.5
		var hz := n * plant.y * 0.5
		var box := PackedVector2Array([c - hx - hz, c + hx - hz, c + hx + hz, c - hx + hz])
		_prism(box, y, y + 4.5, Color("#a4a9ad"), Color("#8f9599"), M_STONE, M_STONE)
		for k in 3:
			# fan units along the block's long side
			var f := c - hx * 0.6 + hx * 0.6 * k + n * (plant.y * 0.5 + 2.0)
			_prism(_square(f, 1.1), y, y + 1.6, Color("#9aa0a4"), Color("#5f6569"), M_STONE, M_STONE)
	_mode = keep


const HUB_CROWN := Color("#1f252c")
const ROOF_RAIL := Color("#c9dbe2")
const ROOF_DECK := Color("#8a7a6c")
const ROOF_STEEL := Color("#cfd1cc")
const ROOF_SOFA := Color("#3e4044")
const ROOF_TABLE := Color("#d9d3c7")
const ROOF_CYPRESS := Color("#2f4a2c")


## The Roof, the bar on the HUB hotel's top (F's photo, 2026-11-19; the hotel's own pages): a
## pale glass screen round the edge, grey timber decking, a glazed lounge lit warm on the half
## away from the Rondo, and on the Rondo's round end an open pale steel pergola strung with
## festoon lights over pale tables and dark wicker sofas, olives and cypresses along the rail. The bar's name, "NA DACHU" ("on
## the roof"), sits over the lounge's door; the hotel's (a parody) on the screen's long side.
func _the_roof(poly: PackedVector2Array, y: float) -> void:
	var none := Color(0, 0, 0, 0)
	var keep := _mode
	_mode = M_STONE
	var rail := 2.4
	_prism(poly, y, y + rail, ROOF_RAIL, none, M_STONE)
	var inner := Geometry2D.offset_polygon(poly, -0.15)
	if inner.size() != 1:
		_mode = keep
		return
	var r := inner[0]
	for i in r.size():
		var a := r[i]
		var b := r[(i + 1) % r.size()]
		_wall(a, b, y, y + rail, -_out(r, a, b), ROOF_RAIL.darkened(0.2))
	_prism(r, y, y + 0.25, ROOF_DECK, ROOF_DECK.lightened(0.1), M_STONE, M_STONE)
	var d := y + 0.25
	# The plan's long axis (the two points furthest apart: the round ends' tips), its middle and
	# half-width; the round end nearer the Rondo carries the pergola, the other the lounge.
	var p0 := poly[0]
	var p1 := poly[0]
	for a in poly:
		for b in poly:
			if a.distance_squared_to(b) > p0.distance_squared_to(p1):
				p0 = a
				p1 = b
	var c := (p0 + p1) * 0.5
	var ax := (p1 - p0).normalized()
	if ax.dot(RONDO_D - c) < 0.0:
		ax = -ax
	var side := Vector2(-ax.y, ax.x)
	var half_l := 0.5 * p0.distance_to(p1)
	var half_w := 0.0
	for a in poly:
		half_w = maxf(half_w, absf((a - c).dot(side)))
	# the lounge: the far half, 2.5 m in from the rail, 4 m of warm-lit glass under a dark roof
	var far := PackedVector2Array([c - ax * (half_l + 5.0) - side * (half_w + 5.0), c - ax * (half_l + 5.0) + side * (half_w + 5.0),
			c - ax * 2.0 + side * (half_w + 5.0), c - ax * 2.0 - side * (half_w + 5.0)])
	var shrunk := Geometry2D.offset_polygon(poly, -2.5)
	if shrunk.size() == 1:
		for lounge in Geometry2D.intersect_polygons(shrunk[0], far):
			if Geometry2D.is_polygon_clockwise(lounge):
				continue
			_prism(lounge, d, d + 3.8, Color("#e4cfa6"), Color("#7f8388"), M_PAVILION, M_STONE)
			_mode = M_STONE
			var door := c - ax * 2.0
			signs.append(["NA DACHU", Vector3(door.x, d + 2.6, door.y) + Vector3(ax.x, 0.0, ax.y) * -0.3,
					Vector3(ax.x, 0.0, ax.y), 0.95 / (Neon.ROW_H * Neon.PIXEL), Color("#ffb46b")])
	# the pergola: posts on a 5 m by 6.5 m grid over the near end, beams both ways at 3 m
	var xs := [-10.0, -5.0, 0.0, 5.0, 10.0]
	var zs := [4.0, 10.5, 17.0]
	var ph := 3.0
	var at := func(u: float, v: float) -> Vector2: return c + side * u + ax * v
	for u: float in xs:
		for v: float in zs:
			_prism(_square(at.call(u, v), 0.12), d, d + ph, ROOF_STEEL, ROOF_STEEL, M_STONE, M_STONE)
	for v: float in zs:
		var p: Vector2 = at.call(xs[0], v)
		var q: Vector2 = at.call(xs[-1], v)
		_beam(Vector3(p.x, d + ph, p.y), Vector3(q.x, d + ph, q.y), 0.22, ROOF_STEEL)
	for u: float in xs:
		var p: Vector2 = at.call(u, zs[0])
		var q: Vector2 = at.call(u, zs[-1])
		_beam(Vector3(p.x, d + ph + 0.2, p.y), Vector3(q.x, d + ph + 0.2, q.y), 0.14, ROOF_STEEL)
	# festoons zig-zag under the beams, a bulb every metre or so
	for i in xs.size() - 1:
		for j in zs.size() - 1:
			var p: Vector2 = at.call(xs[i], zs[j] if i % 2 == 0 else zs[j + 1])
			var q: Vector2 = at.call(xs[i + 1], zs[j + 1] if i % 2 == 0 else zs[j])
			_pow_festoon(Vector3(p.x, d + ph - 0.1, p.y), Vector3(q.x, d + ph - 0.1, q.y), 0.45, 6)
	_mode = M_STONE
	# pale tables with two dark wicker sofas each, in the pergola's bays
	for u: float in [-7.5, -2.5, 2.5, 7.5]:
		for v: float in [7.25, 13.75]:
			var t: Vector2 = at.call(u, v)
			_prism(_square(t, 0.45), d, d + 0.75, ROOF_TABLE.darkened(0.2), ROOF_TABLE, M_STONE, M_STONE)
			for sd: float in [-1.3, 1.3]:
				var sofa := PackedVector2Array([t + side * (sd - 0.4) - ax * 0.9, t + side * (sd + 0.4) - ax * 0.9,
						t + side * (sd + 0.4) + ax * 0.9, t + side * (sd - 0.4) + ax * 0.9])
				_prism(sofa, d, d + 0.55, ROOF_SOFA, ROOF_SOFA.lightened(0.15), M_STONE, M_STONE)
	# olives and cypresses in planters 2 m in from the rail, every 5 m round the near end
	var ring := Geometry2D.offset_polygon(poly, -2.0)
	if ring.size() == 1:
		var last := Vector2(INF, INF)
		var n := 0
		for p: Vector2 in ring[0]:
			if (p - c).dot(ax) < 3.0 or p.distance_to(last) < 5.0:
				continue
			last = p
			_prism(_square(p, 0.5), d, d + 0.7, Color("#8b8f90"), Color("#5a4a3c"), M_STONE, M_STONE)
			if n % 2 == 0:
				_varso_tree(p, d + 0.7, 2.8, 1.0)
			else:
				_mode = M_STONE
				_frustum(_circle(p, 0.55, 6), d + 0.7, _circle(p, 0.08, 6), d + 4.2, ROOF_CYPRESS, ROOF_CYPRESS)
			n += 1
	_mode = keep
	# the hotel's name on the screen's long side, as on the real one
	_crown_signs(poly, y + rail, "KORONA PLAZA", Color(0.94, 0.95, 1.0), 1.2, 0.45)


## Letters on a round tower's band with no board (the HUB hotel's grey band, F's street photo):
## each [word, colour, direction, height over the ground, letter height] stands where the outline
## reaches furthest that way, square to that direction, so a round end carries a name too.
func _ring_signs(poly: PackedVector2Array, g: float, list: Array) -> void:
	for s: Array in list:
		var dir := (s[2] as Vector2).normalized()
		var far := poly[0]
		for q in poly:
			if q.dot(dir) > far.dot(dir):
				far = q
		var k := float(s[4]) / (Neon.ROW_H * Neon.PIXEL)
		# the band stands 0.2 m proud; map_builder puts letters 0.4 m out from this point
		var at := far + dir * 0.3  # clear of a round end's curve under the word's ends
		signs.append([str(s[0]), Vector3(at.x, g + float(s[3]), at.y), Vector3(dir.x, 0.0, dir.y), k, Color(str(s[1]))])


## RD-4 the HUB podium's skylight (the report's ortho): a glazed ridge over a steel kerb on the
## 10.9 m podium between the two towers, lit cool at night, and green plant strips either side.
func _podium_skylight(r: Rect2, podium_h: float) -> void:
	var ring := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var gy := _ground_under(ring)
	var y := gy + podium_h
	_prism(ring, y, y + 0.6, Color("#3a3f44"), Color("#3a3f44"), M_STONE, M_STONE)
	var cx := r.get_center().x
	var ridge := PackedVector2Array([Vector2(cx - 0.15, r.position.y + 0.8), Vector2(cx + 0.15, r.position.y + 0.8),
			Vector2(cx + 0.15, r.end.y - 0.8), Vector2(cx - 0.15, r.end.y - 0.8)])
	var keep := _mode
	_mode = M_PAVILION + 0.5
	_frustum(ring, y + 0.6, ridge, y + 2.6, Color("#9fc3d6"), Color("#9fc3d6"))
	_mode = keep
	for side: float in [-1.0, 1.0]:
		var x0 := (r.position.x - 4.0) if side < 0.0 else (r.end.x + 2.0)
		var strip := PackedVector2Array([Vector2(x0, r.position.y), Vector2(x0 + 2.0, r.position.y),
				Vector2(x0 + 2.0, r.end.y), Vector2(x0, r.end.y)])
		_prism(strip, y, y + 0.45, Color("#6c7a5c"), Color("#6f8f4e"), M_STONE, M_STONE)


## RD-3 the terraces' roofs, found once with the whole map (a sector's build sees only its own
## buildings): for each (x, roof height, z) the outline at that height holding the point, and the
## higher blocks standing on it.
func _find_terraces(points: Array) -> Array:
	var out: Array = []
	for t: Vector3 in points:
		var at := Vector2(t.x, t.z)
		var roof := PackedVector2Array()
		var over: Array[PackedVector2Array] = []
		for bld in data["buildings"]:
			var q := _pts(bld["p"])
			if q.size() >= 3 and absf(float(bld["h"]) - t.y) < 0.3 and Geometry2D.is_point_in_polygon(at, q):
				roof = q
		if roof.size() < 3:
			push_warning("landmarks: no %.1f m roof at %s for a terrace" % [t.y, at])
			continue
		# Only blocks whose middle stands on this roof (the parts bake_sectors.py keeps for the
		# wing's named outline, so both city paths find the same).
		var box := _box_of([roof])
		for bld in data["buildings"]:
			var q := _pts(bld["p"])
			if q.size() < 3 or float(bld["h"]) <= t.y + 1.0 or float(bld["mh"]) >= t.y + 1.0:
				continue
			var c := _centre(q)
			if box.has_point(c) and Geometry2D.is_point_in_polygon(c, roof):
				over.append(q)
		out.append([roof, t.y, over])
	return out


## RD-3 a decked roof terrace on one of Generation Park's low wings (the report, ortho_wide): on
## the roof at `h` that holds `at`, timber decking 1.5 m in from the edge, red café tables and
## small trees in planters, none where a higher block stands on the roof.
func _roof_terrace(roof: PackedVector2Array, h: float, over: Array) -> void:
	var gy := _ground_under(roof)
	var y := gy + h
	var deck := Geometry2D.offset_polygon(roof, -1.5)
	if deck.size() != 1:
		return
	var keep := _mode
	_mode = M_STONE
	_prism(deck[0], y, y + 0.2, Color("#7a5c44"), Color("#9a7556"), M_STONE, M_STONE)
	var box := _box_of([deck[0]])
	var n := 0
	var x := box.position.x + 3.0
	while x < box.end.x - 2.0:
		var z := box.position.y + 3.0
		while z < box.end.y - 2.0:
			var p := Vector2(x, z)
			var free := Geometry2D.is_point_in_polygon(p, deck[0])
			for q in over:
				if free and Geometry2D.is_point_in_polygon(p, q) or free and _dist_to_ring(p, q) < 2.5:
					free = false
			if free:
				if (n % 2) == 0:
					_prism(_square(p, 0.6), y + 0.2, y + 0.75, Color("#6a6f72"), Color("#5a6b3e"), M_STONE, M_STONE)
					_varso_tree(p, y + 0.75, 3.6, 1.3)
				else:
					_prism(_square(p, 0.45), y + 0.2, y + 0.95, Color("#b5342c"), Color("#c23c32"), M_STONE, M_STONE)
				n += 1
			z += 9.0
		x += 9.0
	_mode = keep


## Novotel's cut-off top (the Rondo photos): the shaft ends in two setbacks, 1.4 m in and 2.8 m
## in, each 2.2 m tall, so the corners read chamfered from the street, in the shaft's white.
func _chamfered_top(poly: PackedVector2Array, roof_y: float, wall: Color) -> void:
	var y := roof_y
	for inset: float in [1.4, 2.8]:
		var shrunk := Geometry2D.offset_polygon(poly, -inset)
		if shrunk.is_empty():
			return
		_prism(shrunk[0], y, y + 2.2, wall, wall.darkened(0.1), M_SKIN + float(S_TILE) / 16.0, M_STONE)
		y += 2.2


## The dusk loop (2026-10-31): what lights up a tower's crown after dark. The tallest part
## `poly` (roof at g + top_h): the Marriott's bands and mast, a hotel's name, and red
## aviation lights on a roof of 100 m or more (the Spire and Złota 44 do theirs in their own
## builders).
func _dusk_details(spec: Dictionary, poly: PackedVector2Array, g: float, top_h: float) -> void:
	if poly.size() < 3:
		return
	if spec.get("marriott", false):
		_marriott(poly, g, top_h)
	if spec.get("babka", false):
		_babka(poly, g, top_h)
	if spec.has("sign") and not spec.get("crown_sign", false):
		_crown_signs(poly, g + top_h, str(spec["sign"]), spec.get("sign_col", DUSK_WARM), 3.0,
				0.75 if spec.get("marriott", false) else 0.7)
	if spec.has("base_sign"):
		# A shop's name over the ground floor on the south and east faces (Rondo 1's clinic).
		_crown_signs(poly, g + 5.2, str(spec["base_sign"]), Color(0.75, 1.0, 0.95), 0.0, 0.3)
	if spec.has("vsign"):
		_crown_signs(poly, g + top_h, str(spec["vsign"]), VSIGN_BLUE, 5.0, 0.5, true)
		_vsign_tail(poly, g + top_h - 5.0 - 7.04 * str(spec["vsign"]).length())
	if top_h >= 100.0 and spec["key"] != "zlota44" and spec["key"] != "spire":
		var roof_y := func(_q: Vector2) -> float: return g + top_h
		if spec.get("crest", "") == "slope":
			roof_y = _slope_roof(poly, g + top_h, g + top_h - 24.0)
		_aviation(poly, roof_y)


const DUSK_WARM := Color(1.0, 0.95, 0.86)

## NOWOTEL's name: blue neon, letter over letter down the shaft (the Rondo photos).
const VSIGN_BLUE := Color(0.18, 0.42, 1.0)


## The Nowotel's tail under its stacked name (the Rondo night photos): an orange rule, the
## chain's parody line (ACORN over HOTELS) in the same blue, on the faces the name is on.
func _vsign_tail(poly: PackedVector2Array, y: float) -> void:
	_crown_signs(poly, y - 1.0, "--", Color(1.0, 0.5, 0.15), 0.0, 0.3)
	_crown_signs(poly, y - 3.5, "ACORN", VSIGN_BLUE, 0.0, 0.3)
	_crown_signs(poly, y - 6.5, "HOTELS", VSIGN_BLUE, 0.0, 0.26)


## Centrum LIM's tower, the Presidential hotel (docs/landmarks/specs/lim.md, 2026-11-15 from 25
## photos): the mapped 140 m square with its corners cut 3 m back. The cut corners are white
## panelled piers with grooves, each glass face ends in a white edge strip with a thin light up
## it at night; two dark bands on the glass faces only (the top 7 m under the hotel's name, 4 m
## at 62% under the electronics maker's parody SAMSONG), a white parapet, a plant box and a red
## and white lattice mast to 170 m with two platforms. The glass itself is the parts loop's
## (M_GLASS). The name on the crown goes up with the `sign` key (_dusk_details).
const LIM_PIER := Color("#e4e6e3")
const LIM_DARK_BAND := Color("#14191c")
const LIM_MAST_RED := Color("#c8322b")
const LIM_MAST_WHITE := Color("#e8e8e4")
const LIM_TOWER_FOOT := 15.0   ## the podium's roof, where the tower's white piers start


func _marriott(poly: PackedVector2Array, g: float, h: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var y0 := g + LIM_TOWER_FOOT
	var roof := g + h
	var mid := g + 0.62 * h
	var along := Vector2.RIGHT
	var longest := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var length := kit_front(a, b)
		if _b.dot(_out(poly, a, b)) < 0.0:
			length = kit_front(b, a)
		if length > longest:
			longest = length
			along = _a
		if length < 6.0:
			# A corner pier's face: white panels 4 cm proud, two grooves.
			_wall(_w(0.0, 0.04), _w(length, 0.04), y0, roof, _b, LIM_PIER)
			for k in range(1, 3):
				var u := length * float(k) / 3.0
				_wall(_w(u - 0.04, 0.08), _w(u + 0.04, 0.08), y0, roof - 0.3, _b, LIM_PIER.darkened(0.22))
			continue
		# A glass face: a white edge strip at each end, 0.5 m wide and 0.12 m proud.
		for e: Vector2 in [Vector2(0.0, 0.5), Vector2(length - 0.5, length)]:
			_wall(_w(e.x, 0.12), _w(e.y, 0.12), y0, roof, _b, LIM_PIER)
			_wall(_w(e.x, -0.02), _w(e.x, 0.12), y0, roof, -_a, LIM_PIER.darkened(0.1))
			_wall(_w(e.y, 0.12), _w(e.y, -0.02), y0, roof, _a, LIM_PIER.darkened(0.1))
		# The night light up the corner (F's night photos), on the strip at the face's start.
		_mode = M_LAMP
		_wall(_w(0.12, 0.16), _w(0.32, 0.16), y0 + 1.0, roof - 0.5, _b, LIM_PIER)
		_mode = M_STONE
		# The two dark bands between the strips, 0.15 m proud, with their tops and undersides.
		for band: Vector2 in [Vector2(roof - 7.0, roof), Vector2(mid - 2.0, mid + 2.0)]:
			_wall(_w(0.5, 0.15), _w(length - 0.5, 0.15), band.x, band.y, _b, LIM_DARK_BAND)
			var p0 := _w(0.5, 0.0)
			var p1 := _w(length - 0.5, 0.0)
			var q0 := _w(0.5, 0.15)
			var q1 := _w(length - 0.5, 0.15)
			_quad(Vector3(p0.x, band.y, p0.y), Vector3(q0.x, band.y, q0.y), Vector3(q1.x, band.y, q1.y),
					Vector3(p1.x, band.y, p1.y), Vector3.UP, LIM_DARK_BAND.lightened(0.1))
			_quad(Vector3(p1.x, band.x, p1.y), Vector3(q1.x, band.x, q1.y), Vector3(q0.x, band.x, q0.y),
					Vector3(p0.x, band.x, p0.y), Vector3.DOWN, LIM_DARK_BAND)
	_tower_roof(poly, roof, LIM_PIER, Vector2.ZERO)
	var c := _centre(poly)
	var side := Vector2(-along.y, along.x)
	var sq := func(r: float) -> PackedVector2Array:
		return PackedVector2Array([c + (along + side) * r, c + (-along + side) * r, c + (-along - side) * r, c + (along - side) * r])
	_prism(sq.call(4.0), roof, roof + 3.0, Color("#4a4f53"), Color("#3e4245"), M_STONE, M_STONE)
	_lim_mast(c, along, side, roof + 3.0, g + 170.0)
	_crown_signs(poly, mid, "SAMSONG", DUSK_WARM, 0.0, 0.75)
	_mode = keep


## The mast (photos 1 and 3): a square lattice 2.4 m wide at the foot and 1.2 m at the head, in
## eight panels painted red and white by turns, two platforms, a pole and the red lamp.
func _lim_mast(c: Vector2, along: Vector2, side: Vector2, foot: float, head: float) -> void:
	var corners := func(y: float) -> Array:
		var r := lerpf(1.2, 0.6, (y - foot) / (head - foot))
		var out := []
		for q: Vector2 in [along + side, -along + side, -along - side, along - side]:
			var p := c + q * r
			out.append(Vector3(p.x, y, p.y))
		return out
	var panels := 8
	for j in panels:
		var ya := lerpf(foot, head, float(j) / panels)
		var yb := lerpf(foot, head, float(j + 1) / panels)
		var col := LIM_MAST_RED if j % 2 == 0 else LIM_MAST_WHITE
		var ca: Array = corners.call(ya)
		var cb: Array = corners.call(yb)
		for k in 4:
			var k2 := (k + 1) % 4
			_beam(ca[k], cb[k], 0.25, col)
			if j % 2 == 0:
				_beam(ca[k], cb[k2], 0.12, col)
			else:
				_beam(ca[k2], cb[k], 0.12, col)
	var steel := Color("#8a8f93")
	for y: float in [foot + 9.0, foot + 18.0]:
		var r := lerpf(1.2, 0.6, (y - foot) / (head - foot)) + 0.6
		var deck := PackedVector2Array([c + (along + side) * r, c + (-along + side) * r, c + (-along - side) * r, c + (along - side) * r])
		_prism(deck, y - 0.4, y, steel, steel.lightened(0.1), M_STONE, M_STONE)
		_soffit(deck, y - 0.4, steel.darkened(0.25))
	_frustum(_circle(c, 0.2, 6), head, _circle(c, 0.08, 6), head + 1.6, steel)
	_prism(_square(c, 0.25), head + 1.6, head + 2.2, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)


# --- Babka Tower (Rondo Babka; spec docs/landmarks/specs/babka.md) ---------------------------

## Rebuilt 2026-11-15 from F's photos (top-50 T42, and his four of the same morning): the tower
## and the office block that wraps its foot are one pale grey stone complex. The tower is the
## kit's punched skin (small windows in the stone) with a glazed loggia column down the middle
## of each face, a stone string course where the block's roof meets it, the parody name on the
## top floor and a red mast. The 34 m block (the TOWERS `with` outline) is the same stone with
## its rows of blue office windows, a cornice, and the planters of its roof garden at the
## tower's foot.
const BABKA_LOGGIA := Color("#a9b8c4")
const BABKA_STONE := Color("#d9d8d3")
const BABKA_BLOCK := Color("#c9cac7")
const BABKA_ROOF := Color("#8f918f")
const BABKA_GREEN := Color("#5f7f45")
const BABKA_RED := Color("#c8322b")
const BABKA_BLOCK_TOP := 34.0


func _babka(poly: PackedVector2Array, g: float, h: float) -> void:
	var keep := _mode
	var roof := g + h
	# The glazed loggia column: the middle 45 % of every face 12 m or longer, from over the
	# block's roof to under the top floor, 0.1 m proud.
	_mode = M_SKIN + float(S_EASTWALL) / 16.0
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var length := kit_front(a, b)
		if _b.dot(_out(poly, a, b)) < 0.0:
			length = kit_front(b, a)
		if length < 12.0:
			continue
		var w := length * 0.225
		_wall(_w(length * 0.5 - w, 0.1), _w(length * 0.5 + w, 0.1), g + BABKA_BLOCK_TOP + 1.2, roof - 3.2, _b, BABKA_LOGGIA)
	_mode = M_STONE
	# The string course where the block's roof meets the tower.
	var course := Geometry2D.offset_polygon(poly, 0.3)
	if course.size() == 1:
		_prism(course[0], g + BABKA_BLOCK_TOP + 0.6, g + BABKA_BLOCK_TOP + 1.2, BABKA_STONE, BABKA_STONE, M_STONE, M_STONE)
		_soffit(course[0], g + BABKA_BLOCK_TOP + 0.6, BABKA_STONE.darkened(0.3))
	# The top floor, 0.1 m proud in the same stone: the name goes on it.
	var crown := Geometry2D.offset_polygon(poly, 0.1)
	if crown.size() == 1:
		_prism(crown[0], roof - 3.2, roof, BABKA_STONE, Color(0, 0, 0, 0), M_STONE)
	# The red lattice mast on the roof (T42 photos 1 and 4), a lamp on top.
	var c := _centre(poly) + (poly[0] - _centre(poly)).normalized() * 4.0
	_prism(_square(c, 0.7), roof, roof + 12.0, BABKA_RED, BABKA_RED, M_STONE, M_STONE)
	_prism(_square(c, 0.75), roof + 4.0, roof + 5.0, BABKA_STONE, BABKA_STONE, M_STONE, M_STONE)
	_prism(_square(c, 0.75), roof + 8.5, roof + 9.5, BABKA_STONE, BABKA_STONE, M_STONE, M_STONE)
	_prism(_square(c, 0.2), roof + 12.0, roof + 12.4, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	_mode = keep


## The office block round the tower's foot (34 m, one U-shaped outline): stone with punched
## windows, a cornice that is its roof, its car collision, and the roof garden's planters on the
## block next to the tower.
func _babka_block(block: PackedVector2Array, tower: PackedVector2Array) -> void:
	var g := _ground_under(block)
	_g = g
	var none := Color(0, 0, 0, 0)
	_prism(block, g - 0.4, g + BABKA_BLOCK_TOP - 0.8, BABKA_BLOCK, none, M_SKIN + float(S_PUNCHED) / 16.0, M_STONE)
	var eave := Geometry2D.offset_polygon(block, 0.2)
	if eave.size() == 1:
		_prism(eave[0], g + BABKA_BLOCK_TOP - 0.8, g + BABKA_BLOCK_TOP, BABKA_STONE, BABKA_ROOF, M_STONE, M_STONE)
	else:
		_prism(block, g + BABKA_BLOCK_TOP - 0.8, g + BABKA_BLOCK_TOP, BABKA_STONE, BABKA_ROOF, M_STONE, M_STONE)
	_collide(block)
	# Planters 3 m out from the tower's corners, where that lands on the block's roof.
	var tc := _centre(tower)
	for q in tower:
		var at := q + (q - tc).normalized() * 3.0
		if Geometry2D.is_point_in_polygon(at, block) and not Geometry2D.is_point_in_polygon(at, tower):
			_prism(_square(at, 0.9), g + BABKA_BLOCK_TOP, g + BABKA_BLOCK_TOP + 1.4, BABKA_GREEN.darkened(0.2), BABKA_GREEN, M_STONE, M_STONE)


# --- Warsaw Trade Tower (Chłodna 51; spec docs/landmarks/specs/wtt.md) ------------------------

## Reworked 2026-11-15 from photos (refs/wtt: three Commons photos and the ortho; F's T05 set).
## The mapped parts carry the massing and their own claddings (TOWERS `skins`): the dark glass
## drum in floor bands, the beige stone slab, the silver crown with its flat west screen. Here: the
## crown's horizontal slits round its curved side, and the mast standing in front of the screen
## from its mapped foot (137 m) to 208 m, grey with red and white bands at the top.
const WTT_SLIT := Color("#3a4248")
const WTT_MAST := Color("#8e959b")
const WTT_RED := Color("#c8322b")
const WTT_WHITE := Color("#e8e8e4")


## Four dark slits, 0.6 m tall and 14 cm proud of the crown's cladding, round the crown's curved
## side (the flat west screen, where the name and the mast are, stays plain).
func _wtt_crown_slits(parts: Array[Dictionary], g: float) -> void:
	var crown := PackedVector2Array()
	var best := 0.0
	for b in parts:
		if str(b.get("c", "")).to_lower() != "#839099" or float(b["mh"]) < 160.0:
			continue
		var q := _pts(b["p"])
		var size := _box_of([q]).size.length()
		if size > best:
			best = size
			crown = q
	if crown.size() < 3:
		return
	var ring := Geometry2D.offset_polygon(crown, 0.2)  # the crown block is clad 6 cm proud (crown_from)
	if ring.size() != 1:
		return
	var p: PackedVector2Array = ring[0]
	# The flat face: the crown's longest straight edge.
	var flat := Vector2.ZERO
	var longest := 0.0
	for i in p.size():
		var e := p[(i + 1) % p.size()] - p[i]
		if e.length() > longest:
			longest = e.length()
			flat = e.normalized()
	var keep := _mode
	_mode = M_STONE
	for y in [170.5, 173.5, 176.5, 179.5]:
		for i in p.size():
			var a := p[i]
			var b := p[(i + 1) % p.size()]
			if a.distance_to(b) < 0.05 or absf((b - a).normalized().dot(flat)) > 0.97:
				continue
			_wall(a, b, g + y, g + y + 0.6, _out(p, a, b), WTT_SLIT)
	_mode = keep


## The mast: a grey steel shaft from its mapped foot, the top 14 m in red and white bands, the
## red lamp on top.
func _wtt_mast(poly: PackedVector2Array, y0: float, y1: float) -> void:
	var c := _centre(poly)
	var band := y1 - 14.0
	_prism(_square(c, 0.6), y0, band, WTT_MAST, WTT_MAST, M_STONE, M_STONE)
	var y := band
	var red := true
	while y < y1 - 0.1:
		var top := minf(y + 3.5, y1)
		var col := WTT_RED if red else WTT_WHITE
		_prism(_square(c, 0.45), y, top, col, col, M_STONE, M_STONE)
		y = top
		red = not red
	_prism(_square(c, 0.2), y1, y1 + 0.4, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)


# --- Błękitny Wieżowiec (Plac Bankowy 2; spec docs/landmarks/specs/blekitny.md) ---------------

## Rebuilt 2026-11-15 from photos (refs/blekitny: three Commons photos and the ortho; F's three
## in top-50 T21). The tower and its stepped podium stay the mapped parts, in the silver-blue
## mirror glass (M_GLASS). The glass hall on the podium's east side is mapped as seven strips:
## it is a barrel vault (the ortho's glass tube, the arched glass end in the photo down the side
## street), built whole here. On the roof: the white plant box with the helipad's H inside a dark
## steel screen, and the antennas (two red and white, one grey) at the back.
const BLEK_VAULT_GLASS := Color("#3d5f80")
const BLEK_RIB := Color("#c9d2d8")
const BLEK_BOX := Color("#e6e8e6")
const BLEK_SCREEN := Color("#2c3136")
const BLEK_RED := Color("#c8322b")
const BLEK_WHITE := Color("#ececea")


## The barrel vault over the mapped strips: its axis across the strips, glass walls from the
## ground to the springing and glass ends with the arch, a half cylinder of eight glass panels
## on top with a light rib over every joint, to the strips' height (27.4 m).
func _blekitny_vault(strips: Array[PackedVector2Array], g: float) -> void:
	if strips.is_empty():
		return
	# The strips run across the hall: their long edge gives the cross direction.
	var s0 := strips[0]
	var across := Vector2.ZERO
	var best := 0.0
	for i in s0.size():
		var e := s0[(i + 1) % s0.size()] - s0[i]
		if e.length() > best:
			best = e.length()
			across = e.normalized()
	var axis := Vector2(across.y, -across.x)
	var pts: Array[Vector2] = []
	for s in strips:
		for q in s:
			pts.append(q)
	var c := Vector2.ZERO
	for q in pts:
		c += q
	c /= float(pts.size())
	var u0 := INF
	var u1 := -INF
	var v0 := INF
	var v1 := -INF
	for q in pts:
		u0 = minf(u0, (q - c).dot(axis))
		u1 = maxf(u1, (q - c).dot(axis))
		v0 = minf(v0, (q - c).dot(across))
		v1 = maxf(v1, (q - c).dot(across))
	var length := kit_front(c + axis * u0 + across * v0, c + axis * u1 + across * v0)
	# kit_front's _b is left of the axis; keep v running towards `across`.
	var sv := 1.0 if _b.dot(across) > 0.0 else -1.0
	var width := v1 - v0
	var r := width * 0.5
	var top := g + 27.4
	var spring := top - r
	var keep := _mode
	_mode = M_GLASS
	var p := func(u: float, v: float, y: float) -> Vector3:
		var q := _w(u, v * sv)
		return Vector3(q.x, y, q.y)
	# The long walls above the podium (it closes them below 17 m).
	_wall(_w(length, 0.0), _w(0.0, 0.0), g + 17.0, spring, -_b * sv, BLEK_VAULT_GLASS)
	_wall(_w(0.0, width * sv), _w(length, width * sv), g + 17.0, spring, _b * sv, BLEK_VAULT_GLASS)
	# The half cylinder.
	var n := 8
	for k in n:
		var a0 := PI * float(k) / n
		var a1 := PI * float(k + 1) / n
		var va := r - r * cos(a0)
		var vb := r - r * cos(a1)
		var ya := spring + r * sin(a0)
		var yb := spring + r * sin(a1)
		var mid := (a0 + a1) * 0.5
		var nn := Vector3(0, sin(mid), 0) + Vector3(-_b.x, 0, -_b.y) * sv * cos(mid)
		_quad(p.call(0.0, va, ya), p.call(length, va, ya), p.call(length, vb, yb), p.call(0.0, vb, yb), nn.normalized(), BLEK_VAULT_GLASS)
	# The arched ends, from the ground: a rectangle to the springing and a fan over it.
	for e: Array in [[0.0, Vector3(-_a.x, 0, -_a.y)], [length, Vector3(_a.x, 0, _a.y)]]:
		var u: float = e[0]
		var en: Vector3 = e[1]
		_quad(p.call(u, 0.0, g - 0.4), p.call(u, width, g - 0.4), p.call(u, width, spring), p.call(u, 0.0, spring), en, BLEK_VAULT_GLASS)
		var hub: Vector3 = p.call(u, r, spring)
		for k in n:
			var a0 := PI * float(k) / n
			var a1 := PI * float(k + 1) / n
			_tri(hub, p.call(u, r - r * cos(a0), spring + r * sin(a0)), p.call(u, r - r * cos(a1), spring + r * sin(a1)), en, BLEK_VAULT_GLASS,
					Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_mode = M_STONE
	# Light ribs over the joints, 0.12 m proud, every 3 m along the hall.
	var ribs := maxi(2, roundi(length / 3.0))
	for j in range(1, ribs):
		var u := length * float(j) / ribs
		for k in n:
			var a0 := PI * float(k) / n
			var a1 := PI * float(k + 1) / n
			var ra := r + 0.12
			var qa: Vector3 = p.call(u, r - ra * cos(a0), spring + ra * sin(a0))
			var qb: Vector3 = p.call(u, r - ra * cos(a1), spring + ra * sin(a1))
			_beam(qa, qb, 0.18, BLEK_RIB)
	_mode = keep


## The roof (the ortho): a white plant box with the helipad's H on it, a dark steel screen round
## the roof's edge, and the antennas at the box's back (photos: two red and white lattice masts,
## about 20 m, and a thinner grey one).
func _blekitny_roof(poly: PackedVector2Array, roof: float) -> void:
	if poly.size() < 3:
		return
	var keep := _mode
	_mode = M_STONE
	_prism(poly, roof, roof + 2.2, BLEK_SCREEN, Color(0, 0, 0, 0), M_SKIN + float(S_FRAME) / 16.0)
	var inner := Geometry2D.offset_polygon(poly, -0.25)
	if inner.size() == 1:
		var ring: PackedVector2Array = inner[0]
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			_wall(a, b, roof, roof + 2.2, -_out(ring, a, b), BLEK_SCREEN.darkened(0.2))
	# The long axis of the roof.
	var along := Vector2.RIGHT
	var longest := 0.0
	for i in poly.size():
		var e := poly[(i + 1) % poly.size()] - poly[i]
		if e.length() > longest:
			longest = e.length()
			along = e.normalized()
	var side := Vector2(-along.y, along.x)
	var c := _centre(poly)
	var box := func(cc: Vector2, hu: float, hv: float) -> PackedVector2Array:
		return PackedVector2Array([cc + along * hu + side * hv, cc - along * hu + side * hv, cc - along * hu - side * hv, cc + along * hu - side * hv])
	_prism(box.call(c, 9.0, 5.5), roof, roof + 4.0, BLEK_BOX, BLEK_BOX.darkened(0.05), M_STONE, M_STONE)
	# The H, two posts and a bar 8 cm over the box's roof.
	var y := roof + 4.08
	for r: Rect2 in [Rect2(-2.0, -2.2, 0.7, 4.4), Rect2(1.3, -2.2, 0.7, 4.4), Rect2(-1.3, -0.35, 2.6, 0.7)]:
		var q0 := c + along * r.position.x + side * r.position.y
		var q1 := c + along * r.end.x + side * r.position.y
		var q2 := c + along * r.end.x + side * r.end.y
		var q3 := c + along * r.position.x + side * r.end.y
		_quad(Vector3(q0.x, y, q0.y), Vector3(q1.x, y, q1.y), Vector3(q2.x, y, q2.y), Vector3(q3.x, y, q3.y), Vector3.UP, BLEK_SCREEN)
	for m: Array in [[Vector2(7.0, 3.5), 22.0, true], [Vector2(4.5, 3.8), 17.0, true], [Vector2(-6.0, 3.6), 12.0, false]]:
		var at: Vector2 = c + along * m[0].x + side * m[0].y
		_blekitny_mast(at, roof + 4.0, roof + 4.0 + float(m[1]), m[2])
	_mode = keep


## One antenna: a slim square lattice painted red and white by turns (or a grey pole) and a red
## lamp on top.
func _blekitny_mast(at: Vector2, y0: float, y1: float, painted: bool) -> void:
	if not painted:
		_frustum(_circle(at, 0.18, 6), y0, _circle(at, 0.08, 6), y1, Color("#9aa0a4"))
		return
	var bands := 6
	for j in bands:
		var ya := lerpf(y0, y1, float(j) / bands)
		var yb := lerpf(y0, y1, float(j + 1) / bands)
		var col := BLEK_RED if j % 2 == 0 else BLEK_WHITE
		_prism(_square(at, 0.35 - 0.03 * j), ya, yb, col, col, M_STONE, M_STONE)
	_prism(_square(at, 0.18), y1, y1 + 0.5, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)


# --- Centrum LIM's podium (F's night photos, 2026-11-06) ----------------------------------------

## Centrum LIM's podium on Aleje Jerozolimskie 65/79 (1989), opposite Warszawa Centralna, rebuilt
## from F's six night photos (docs/landmarks/specs/lim-podium.md). Until now it was the tower's
## dark glass in three boxes. Base to top: the ground floor's shop glass behind an arcade of round
## columns (the map's ground-floor part stands 5-9 m in from the upper floors); a band of
## silver-white panels (LIM_GROUND to LIM_BAND_A); a glazed gallery floor 2 m in
## (restaurants: warm, a pink-lit stretch west of the tower, green glass at the east end); a
## second panel band with a dark ribbon window; the top band with the tenants' signs (parodies,
## LIM_SIGNS); on the west roof the black louvred plant screen (the map's 15-18 m part). Two LED
## screens stand on the roof and one hangs on the tower's north face (LIM_SCREENS).
const LIM_PANEL := Color("#d9d8d1")
const LIM_SHOP := Color("#8fa2a6")
const LIM_GALLERY_GLASS := Color("#7f989a")
const LIM_RIBBON_GLASS := Color("#1f262b")
const LIM_LOUVRE := Color("#1b1d20")
const LIM_ROOF := Color("#9a9c9c")
const LIM_COLUMN := Color("#e4e2dc")
const LIM_GROUND := 4.6     # the ground floor's top: the first panel band's underside
const LIM_BAND_A := 7.6     # the first panel band's top: the gallery's floor
const LIM_GALLERY := 10.6   # the gallery's top
const LIM_RIBBON := Vector2(12.2, 13.1)  # the dark window strip under the top band
const LIM_TOP := 15.0       # the roof (the map's upper part)
const LIM_LOUVRE_TOP := 18.0
## Colours of the parodied signs (lit at night; F's photos).
const LIM_GOLD := Color(1.0, 0.8, 0.42)
const LIM_WHITE := Color(1.0, 0.98, 0.94)
const LIM_RED := Color(1.0, 0.12, 0.1)
const LIM_ORANGE := Color(1.0, 0.42, 0.08)
## The tenants' signs on the north (street) face, east to west in F's photos: the hotel's name
## with its crown at both ends, the casino chain, the airline, the clinic, the bank with its bison,
## the frozen-food maker, the small casino, then the shops' names lower down. Each row: word, u
## (metres from the face's west end), band ("top" 13.1-15 m, "mid" the band under the ribbon,
## "a" the first panel band, "gf" the shop glass), letter-row height (m), colour, extra.
const LIM_SIGNS := [
	["PREZYDENT", 16.0, "top", 1.5, LIM_GOLD, "crown"],
	["WAWKA", 31.0, "top", 1.2, LIM_RED, "box"],
	["KASYNKO", 41.0, "top", 1.3, LIM_WHITE, "redbox"],
	["MROSTA", 57.0, "top", 1.5, Color(0.3, 0.42, 1.0), ""],
	["PEPEO ŻUBR", 78.0, "top", 1.4, LIM_WHITE, "bison"],
	["LINIE LODOWE", 93.0, "top", 0.9, LIM_WHITE, ""],
	["LOD", 104.0, "top", 1.9, LIM_WHITE, ""],
	["LUZMED", 97.0, "mid", 1.3, Color(0.3, 1.0, 0.35), "plus"],
	["KASYNOS", 119.0, "top", 1.5, Color(0.25, 0.45, 1.0), "chip"],
	["PREZYDENT", 138.0, "top", 1.5, LIM_GOLD, "crown"],
	["TYGRYS", 70.0, "a", 1.3, LIM_WHITE, "kopenhaga"],
	["ROSZMAN", 88.0, "gf", 0.9, LIM_RED, ""],
	["MILENIUSZ", 116.0, "gf", 0.9, Color(0.9, 0.2, 0.45), ""],
]
## The LED screens: [u (m from the face's west end), metres back from the face, width, height,
## panel colour, the advert's word, its colour, "louvre" (stands on the plant screen) / "roof" /
## "tower" (hangs on the tower's north face)]. The adverts are the game's own parodies of those
## in the photos (a fashion chain, a box of pretzel sticks, a car).
const LIM_SCREENS := [
	[48.0, 7.0, 12.0, 7.5, Color("#e8661a"), "PALUSZKI", LIM_WHITE, "louvre"],
	[90.0, 8.0, 11.0, 7.5, Color("#6a3fc4"), "HYM", LIM_WHITE, "roof"],
	[0.0, 0.0, 11.0, 8.5, Color("#c8284a"), "LEKSUS", LIM_WHITE, "tower"],
]
## The flat lit marks beside the words (x along the wall, y up, metres; drawn centred).
const LIM_CROWN := [Vector2(-0.8, 0.0), Vector2(0.8, 0.0), Vector2(0.8, 0.9), Vector2(0.45, 0.45), Vector2(0.0, 1.1),
		Vector2(-0.45, 0.45), Vector2(-0.8, 0.9)]
## The clinic's plus, one outline (two crossed bars would overlap in one plane).
const LIM_PLUS := [Vector2(-0.18, 0.0), Vector2(0.18, 0.0), Vector2(0.18, 0.42), Vector2(0.6, 0.42), Vector2(0.6, 0.78),
		Vector2(0.18, 0.78), Vector2(0.18, 1.2), Vector2(-0.18, 1.2), Vector2(-0.18, 0.78), Vector2(-0.6, 0.78), Vector2(-0.6, 0.42),
		Vector2(-0.18, 0.42)]
## The bison, facing west (left, seen from the street): head low with its beard, the hump, a horn.
const LIM_BISON := [Vector2(0.0, 0.3), Vector2(0.05, 0.2), Vector2(0.18, 0.12), Vector2(0.28, 0.25), Vector2(0.32, 0.03),
		Vector2(0.4, 0.03), Vector2(0.43, 0.3), Vector2(1.03, 0.3), Vector2(1.07, 0.03), Vector2(1.15, 0.03), Vector2(1.2, 0.45),
		Vector2(1.22, 0.62), Vector2(1.05, 0.72), Vector2(0.7, 0.8), Vector2(0.45, 0.98), Vector2(0.25, 0.88), Vector2(0.14, 0.72),
		Vector2(0.1, 0.8), Vector2(0.07, 0.66), Vector2(0.02, 0.55)]


## The podium (see LIM_PANEL): `outer` the upper floors' outline (5-15 m), `ground` the ground
## floor's, `louvre` the plant screen's (15-18 m), `tower` the hotel tower's, from the map's parts.
func _lim_podium(outer: PackedVector2Array, ground: PackedVector2Array, louvre: PackedVector2Array,
		tower: PackedVector2Array, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var panels := M_STONE
	_prism(ground, g - 0.4, g + LIM_GROUND, LIM_SHOP, none, M_PAVILION)
	# The arcade's columns: 0.9 m round, about every 7.5 m, 1.1 m in from the panel bands' face,
	# from the pavement up through the gallery floor.
	for i in outer.size():
		var a := outer[i]
		var b := outer[(i + 1) % outer.size()]
		var l := a.distance_to(b)
		if l < 6.0:
			continue
		var o := _out(outer, a, b)
		var n := maxi(1, roundi(l / 7.5))
		for k in n:
			var c := a.lerp(b, (k + 0.5) / n) - o * 1.1
			if Geometry2D.is_point_in_polygon(c, ground) or Geometry2D.is_point_in_polygon(c, tower):
				continue
			_prism(_circle(c, 0.45, 8), g - 0.4, g + LIM_GALLERY, LIM_COLUMN, none, M_STONE)
	_prism(outer, g + LIM_GROUND, g + LIM_BAND_A, LIM_PANEL, none, panels)
	_mode = M_STONE
	_cap(outer, g + LIM_BAND_A, LIM_PANEL.darkened(0.2))
	var gallery := _largest(Geometry2D.offset_polygon(outer, -2.0, Geometry2D.JOIN_MITER))
	_prism(gallery, g + LIM_BAND_A, g + LIM_GALLERY, LIM_GALLERY_GLASS, none, M_PAVILION)
	_prism(outer, g + LIM_GALLERY, g + LIM_RIBBON.x, LIM_PANEL, none, panels)
	_mode = M_STONE
	_cap(outer, g + LIM_RIBBON.x, LIM_PANEL.darkened(0.2))
	var ribbon := _largest(Geometry2D.offset_polygon(outer, -0.3, Geometry2D.JOIN_MITER))
	_prism(ribbon, g + LIM_RIBBON.x, g + LIM_RIBBON.y, LIM_RIBBON_GLASS, none, M_SKIN + float(S_DARK) / 16.0)
	_prism(outer, g + LIM_RIBBON.y, g + LIM_TOP, LIM_PANEL, LIM_ROOF, panels, M_STONE)
	if louvre.size() >= 3:
		_prism(louvre, g + LIM_TOP, g + LIM_LOUVRE_TOP, LIM_LOUVRE, Color("#5c5f62"), M_SKIN + float(S_FINS) / 16.0, M_STONE)
	_collide(outer)
	# The street face: the longest edge facing north-west to north (Aleje Jerozolimskie), measured
	# from its west end.
	var fi := _edge_facing(outer, Vector2(-0.33, -0.94), 40.0)
	if fi < 0:
		return
	var fa := outer[fi]
	var fb := outer[(fi + 1) % outer.size()]
	var n := _out(outer, fa, fb)
	var d := (fb - fa).normalized()
	var west := fa
	if d.x < 0.0:
		d = -d
		west = fb
	var span := fa.distance_to(fb) + 6.0  # the short stretch round the corner runs on in line
	_lim_gallery_tints(west, d, n, g)
	for s: Array in LIM_SIGNS:
		_lim_sign(s, west, d, n, minf(float(s[1]), span - 3.0), ground, g)
	# The hotel's name on the east (Emilii Plater) face's top band too.
	var ei := _edge_facing(outer, Vector2(0.94, -0.33), 30.0)
	if ei >= 0 and ei != fi:
		var ea := outer[ei]
		var eb := outer[(ei + 1) % outer.size()]
		var en := _out(outer, ea, eb)
		# Near the corner with the street face (F's photo from the corner), the crown towards it.
		var corner := west + d * span
		var near := ea if ea.distance_to(corner) < eb.distance_to(corner) else eb
		var far := eb if near == ea else ea
		_lim_sign(["PREZYDENT", 0.0, "top", 1.5, LIM_GOLD, "crown"], near.lerp(far, 0.35), (near - far).normalized(), en, 0.0,
				ground, g)
	for sc: Array in LIM_SCREENS:
		if sc[7] == "tower":
			var ti := _edge_facing(tower, n, 15.0)
			if ti < 0:
				continue
			var ta := tower[ti]
			var tb := tower[(ti + 1) % tower.size()]
			var tn := _out(tower, ta, tb)
			var td := (tb - ta).normalized()
			if td.dot(d) < 0.0:
				td = -td
			var at := (ta + tb) * 0.5 + td * 0.18 * ta.distance_to(tb) + tn * 0.65
			_lim_screen(at, td, tn, float(sc[2]), float(sc[3]), g + LIM_TOP + 2.5, g + LIM_TOP + 2.5, sc[4], sc[5], sc[6])
		else:
			var foot := g + (LIM_LOUVRE_TOP if sc[7] == "louvre" else LIM_TOP)
			var at := west + d * float(sc[0]) - n * float(sc[1])
			_lim_screen(at, d, n, float(sc[2]), float(sc[3]), foot, foot + 0.8, sc[4], sc[5], sc[6])


## Centrum LIM's parts: builds the podium from the upper floors' part (5-15 m), the ground
## floor's and the plant screen's (15-18 m), and gives back the rest (the tower, the small boxes).
func _lim_parts(parts: Array[Dictionary], g: float) -> Array[Dictionary]:
	var outer := PackedVector2Array()
	var ground := PackedVector2Array()
	var louvre := PackedVector2Array()
	var tower := PackedVector2Array()
	var rest: Array[Dictionary] = []
	for b in parts:
		var q := _pts(b["p"])
		var h := float(b["h"])
		var mh := float(b["mh"])
		var big := _box_of([q]).size.length() > 60.0
		if big and mh > 3.0 and h < 17.0:
			outer = q
		elif big and mh < 0.5 and h < 10.0:
			ground = q
		elif big and mh > 13.0 and h < 25.0:
			louvre = q
		else:
			if h > 100.0:
				tower = q
			rest.append(b)
	if outer.size() < 3 or ground.size() < 3:
		return parts
	_lim_podium(outer, ground, louvre, tower, g)
	return rest


## The gallery's tints on the street face (F's photos): a pink-lit restaurant west of the tower
## and green-grey glass at the east end, panels 6 cm out from the gallery glass.
func _lim_gallery_tints(west: Vector2, d: Vector2, n: Vector2, g: float) -> void:
	var keep := _mode
	for t: Array in [[80.0, 103.0, Color("#8a5a72"), M_LAMP], [124.0, 146.0, Color("#5f7c74"), M_STONE]]:
		var p0 := west + d * float(t[0]) - n * 1.94
		var p1 := west + d * float(t[1]) - n * 1.94
		_mode = float(t[3])
		_quad(Vector3(p0.x, g + LIM_BAND_A + 0.3, p0.y), Vector3(p1.x, g + LIM_BAND_A + 0.3, p1.y),
				Vector3(p1.x, g + LIM_GALLERY - 0.3, p1.y), Vector3(p0.x, g + LIM_GALLERY - 0.3, p0.y), Vector3(n.x, 0.0, n.y), t[2])
	_mode = keep


## One of LIM_SIGNS at `u` m along the face from `west` (direction `d`, outward `n`), with its mark.
func _lim_sign(s: Array, west: Vector2, d: Vector2, n: Vector2, u: float, ground: PackedVector2Array, g: float) -> void:
	var word := str(s[0])
	var tall := float(s[3])
	var col: Color = s[4]
	var mark := str(s[5])
	var at := west + d * u
	var y := 0.0
	match str(s[2]):
		"top":
			y = LIM_RIBBON.y + 0.5 * (LIM_TOP - LIM_RIBBON.y) - 0.5 * tall
		"mid":
			y = LIM_GALLERY + 0.5 * (LIM_RIBBON.x - LIM_GALLERY) - 0.5 * tall
		"a":
			y = LIM_GROUND + 0.62 * (LIM_BAND_A - LIM_GROUND) - 0.5 * tall
		"gf":
			# Over the shop doors on the glass, back under the arcade: walk in to the ground floor.
			var best := INF
			for i in ground.size():
				var hit: Variant = Geometry2D.segment_intersects_segment(at, at - n * 15.0, ground[i], ground[(i + 1) % ground.size()])
				if hit != null and at.distance_to(hit) < best:
					best = at.distance_to(hit)
			if best == INF:
				return
			at -= n * (best - 0.08)
			y = LIM_GROUND - 0.35 - tall
	var k := tall / (Neon.ROW_H * Neon.PIXEL)
	var half := 0.5 * k * Neon.length_of(word)
	var p := at + n * 0.08
	if mark == "box" or mark == "redbox":
		# A lit panel behind the word: white for the small casino's red name, red for its white one.
		var box := LIM_WHITE if mark == "box" else LIM_RED.darkened(0.3)
		_lim_flat(PackedVector2Array([Vector2(-half - 0.3, -0.1), Vector2(half + 0.3, -0.1), Vector2(half + 0.3, tall + 0.1),
				Vector2(-half - 0.3, tall + 0.1)]), at, d, n, g + y, box, 0.05)
		p = at + n * 0.12
	signs.append([word, Vector3(p.x, g + y, p.y), Vector3(n.x, 0.0, n.y), k, col])
	# Marks: on the east side of the word (larger u) unless said otherwise.
	match mark:
		"crown":
			_lim_flat(_shape(LIM_CROWN, 0.9), at + d * (half + 1.0), d, n, g + y + 0.15 * tall, col)
		"bison":
			var bison := _shape(LIM_BISON, 1.25)
			for i in bison.size():
				bison[i] -= Vector2(0.75, 0.0)
			_lim_flat(bison, at + d * (half + 1.2), d, n, g + y, LIM_ORANGE)
			# The bank's red-orange rule under its name.
			_lim_flat(PackedVector2Array([Vector2(-half, 0.0), Vector2(half + 2.0, 0.0), Vector2(half + 2.0, 0.14),
					Vector2(-half, 0.14)]), at + d * 0.9, d, n, g + y - 0.3, LIM_RED)
		"plus":
			_lim_flat(_shape(LIM_PLUS, 1.0), at + d * (half + 0.9), d, n, g + y, Color(0.1, 0.8, 0.9))
		"chip":
			# The casino chain's red emblem: a disc with a light rim, to the word's east.
			_lim_flat(_circle(Vector2(0.0, 0.75), 0.75, 12), at + d * (half + 1.1), d, n, g + y, LIM_RED)
			_lim_flat(PackedVector2Array([Vector2(-half, -0.25), Vector2(half, -0.25), Vector2(half, -0.12), Vector2(-half, -0.12)]),
					at, d, n, g + y, LIM_RED)
		"kopenhaga":
			var k2 := 0.55 / (Neon.ROW_H * Neon.PIXEL)
			signs.append(["KOPENHAGA", Vector3(p.x, g + y - 0.6, p.y), Vector3(n.x, 0.0, n.y), k2, col])


## `pts` scaled by `k`, as a polygon.
func _shape(pts: Array, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q: Vector2 in pts:
		out.append(q * k)
	return out


## A flat lit shape on a wall: `shape` (x along `d`, y up, metres) round `at`, `off` m out along
## `n`, from height `y`. Drawn in M_LAMP: its colour by day, glowing at night.
func _lim_flat(shape: PackedVector2Array, at: Vector2, d: Vector2, n: Vector2, y: float, col: Color, off := 0.08) -> void:
	var tris := Geometry2D.triangulate_polygon(shape)
	var n3 := Vector3(n.x, 0.0, n.y)
	var keep := _mode
	_mode = M_LAMP
	var base := at + n * off
	for i in range(0, tris.size(), 3):
		var v: Array[Vector3] = []
		for j in 3:
			var q := shape[tris[i + j]]
			var p := base + d * q.x
			v.append(Vector3(p.x, y + q.y, p.y))
		_tri(v[0], v[1], v[2], n3, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
	_mode = keep


## An LED screen: a dark box `w` × `h` × 0.6 m from `y0` with its lit face towards `n` and the
## advert's word on it, on two legs down to `foot` when it stands above it.
func _lim_screen(c: Vector2, d: Vector2, n: Vector2, w: float, h: float, foot: float, y0: float, panel: Color, word: String,
		ink: Color) -> void:
	var frame := Color("#1a1c1f")
	var l := c - d * w * 0.5
	var r := c + d * w * 0.5
	_prism(PackedVector2Array([l, r, r - n * 0.6, l - n * 0.6]), y0, y0 + h, frame, frame, M_STONE, M_STONE)
	if y0 > foot + 0.1:
		for s: float in [-0.3, 0.3]:
			_prism(_square(c + d * w * s - n * 0.3, 0.2), foot, y0, frame, frame, M_STONE, M_STONE)
	var f0 := c - d * (w * 0.5 - 0.25) + n * 0.06
	var f1 := c + d * (w * 0.5 - 0.25) + n * 0.06
	var keep := _mode
	_mode = M_LAMP
	_quad(Vector3(f0.x, y0 + 0.25, f0.y), Vector3(f1.x, y0 + 0.25, f1.y), Vector3(f1.x, y0 + h - 0.25, f1.y),
			Vector3(f0.x, y0 + h - 0.25, f0.y), Vector3(n.x, 0.0, n.y), panel)
	_mode = keep
	var k := minf(0.85 * (w - 0.5) / Neon.length_of(word), 0.6 * h / (Neon.ROW_H * Neon.PIXEL))
	var rh := Neon.ROW_H * Neon.PIXEL * k
	var p := c + n * 0.12
	signs.append([word, Vector3(p.x, y0 + 0.5 * h - 0.5 * rh, p.y), Vector3(n.x, 0.0, n.y), k, ink])


## The roof height of a part cut on a slope (_sloped): `hi` at the north end of its longest
## axis, `lo` at the other.
func _slope_roof(poly: PackedVector2Array, hi: float, lo: float) -> Callable:
	var c := _centre(poly)
	var axis := Vector2.ZERO
	var reach := 0.0
	for q in poly:
		if (q - c).length() > reach:
			reach = (q - c).length()
			axis = (q - c).normalized()
	if axis.y > 0.0:
		axis = -axis
	var lo_d := INF
	var hi_d := -INF
	for q in poly:
		lo_d = minf(lo_d, (q - c).dot(axis))
		hi_d = maxf(hi_d, (q - c).dot(axis))
	return func(q: Vector2) -> float: return lerpf(lo, hi, inverse_lerp(lo_d, hi_d, (q - c).dot(axis)))


## Złota 44 (rebuilt 2026-11-02 from F's two photos, the street view from the east and the aerial
## from the Palace; spec docs/landmarks/specs/zlota44.md). The plan is the mapped core (a
## four-sided tower 30 x 37 m); what makes it Libeskind's "sail":
##   - the WING: the south-east corner leans out as it climbs. It starts as a thin glass wedge
##     at the foot (ZLOTA_WEDGE out), pinches in to the plain plan at ZLOTA_WAIST, then flares
##     out ever faster to ZLOTA_FLARE at the top, so the corner draws a long concave curve; the
##     east face is gently convex (ZLOTA_CURVE), as mapped;
##   - the TIP: the roof is cut on one plane from the sharp south-east corner at ZLOTA_TIP down
##     to ZLOTA_LOW at the north face, so the corner ends in a point;
##   - the CROWN: a glazed box (ZLOTA_CROWN high) on the north and west part of the roof, set
##     back from the east face, in dark glass with fine mullions (the crown screen);
##   - the facade (S_SAIL): silver-white aluminium cassettes in floor bands with glass between,
##     broken and staggered panel by panel (building.gdshader);
##   - the podium's roof garden in front of the east face (`_zlota_garden`).
## The tower is lofted through ZLOTA_RINGS (fractions of each corner's own height), so the
## flare and the cut top stay one closed surface.
const ZLOTA_NE := Vector2(-1469.5, 291.8)
const ZLOTA_SE := Vector2(-1462.1, 325.6)
const ZLOTA_SW := Vector2(-1488.5, 334.8)
const ZLOTA_NW := Vector2(-1501.1, 298.5)
const ZLOTA_TIP := 192.0
const ZLOTA_LOW := 150.0
const ZLOTA_CROWN := 184.0
const ZLOTA_CROWN_FROM := 0.45   # the crown box covers the roof from this share of the slope on
const ZLOTA_CROWN_SET := 4.5     # and stands this far back from the east face
const ZLOTA_WEDGE := 2.6
const ZLOTA_WAIST := 64.0
const ZLOTA_FLARE := 9.0
const ZLOTA_CURVE := 2.5
const ZLOTA_EAST_SEGS := 10
const ZLOTA_SOUTH_SEGS := 6
const ZLOTA_RINGS := [0.0, 0.04, 0.1, 0.17, 0.25, 0.33, 0.42, 0.52, 0.62, 0.72, 0.81, 0.89, 0.95, 1.0]
const ZLOTA_CROWN_GLASS := Color("#58788c")
# Update 2026-11-26 (spec "3D Tiles + Street View pass"): all in the site's one building mesh.
const ZLOTA_BLUE := Color("#4f78b0")      # z26_blue: the glass patches along the wing's crease
const ZLOTA_LID := 181.0                  # z26_well: the crown box's floor, 3 m under its walls' top
const ZLOTA_COPING := Color("#e4e8ea")
const ZLOTA_LOBBY_AT := 0.35              # z26_lobby: share of the south face from the SE end
const ZLOTA_LOBBY_W := 12.0
const ZLOTA_LOBBY_H := 8.1               # the portal head sits on it (8.1-8.7), over the blade at 8.0-8.5
const ZLOTA_BLADE_LEN := 18.0
const ZLOTA_BLADE_OUT := 3.0
const ZLOTA_PLINTH_H := 4.2
## The LED line on the sharp south-east corner (F's photos, 2026-11-08): a thin blue light up the
## whole wing edge to the tip, lit at night (M_LAMP). A strip ZLOTA_EDGE_W wide, standing
## ZLOTA_EDGE_OUT off the corner along its bisector, through the same rings as the tower.
const ZLOTA_EDGE := Color("#7d96ff")
const ZLOTA_EDGE_W := 1.6
const ZLOTA_EDGE_OUT := 0.25

func _zlota_edge_light(rings: Array[PackedVector2Array], tops: PackedFloat32Array, g: float) -> void:
	var keep := _mode
	_mode = M_LAMP
	var c := ZLOTA_EAST_SEGS
	var pts: Array[Vector3] = []
	var outs: Array[Vector2] = []
	for k in ZLOTA_RINGS.size():
		var r: PackedVector2Array = rings[k]
		var n := r.size()
		var p := r[c]
		var a := (p - r[(c - 1 + n) % n]).normalized()
		var b := (p - r[(c + 1) % n]).normalized()
		var o := (a + b).normalized()
		var y := g + float(ZLOTA_RINGS[k]) * tops[c] if k > 0 else g + 1.0
		pts.append(Vector3(p.x + o.x * ZLOTA_EDGE_OUT, y, p.y + o.y * ZLOTA_EDGE_OUT))
		outs.append(o)
	for k in pts.size() - 1:
		var s0 := Vector2(-outs[k].y, outs[k].x) * (ZLOTA_EDGE_W * 0.5)
		var s1 := Vector2(-outs[k + 1].y, outs[k + 1].x) * (ZLOTA_EDGE_W * 0.5)
		var a0 := pts[k] + Vector3(s0.x, 0.0, s0.y)
		var b0 := pts[k] - Vector3(s0.x, 0.0, s0.y)
		var a1 := pts[k + 1] + Vector3(s1.x, 0.0, s1.y)
		var b1 := pts[k + 1] - Vector3(s1.x, 0.0, s1.y)
		var nrm := Vector3(outs[k].x, 0.0, outs[k].y)
		var none := Vector2(-1, -1)
		_tri(a0, b0, b1, nrm, ZLOTA_EDGE, none, none, none, -1.0, false)
		_tri(a0, b1, a1, nrm, ZLOTA_EDGE, none, none, none, -1.0, false)
	_mode = keep


## The podium's roof garden: smaller trees than Varso's sky garden, a lawn bed, a few benches.
const ZLOTA_TERRACE := {"trees": 10, "h": 4.8, "r": 1.7, "pines": 6, "benches": 3, "step": 4.8}


## How far the south-east corner stands out of the plan at height h (metres over the ground).
func _zlota_flare(h: float) -> float:
	if h < ZLOTA_WAIST:
		return ZLOTA_WEDGE * (1.0 - smoothstep(0.0, ZLOTA_WAIST, h))
	return ZLOTA_FLARE * pow((h - ZLOTA_WAIST) / (ZLOTA_TIP - ZLOTA_WAIST), 1.7)


func _zlota_out(a: Vector2, b: Vector2, away: Vector2) -> Vector2:
	var e := (b - a).normalized()
	var o := Vector2(-e.y, e.x)
	return -o if o.dot(away - a) > 0.0 else o


## Point i of the plan at height h. The order: the east face from the north-east corner to the
## sharp south-east one, the south face, the soft south-west corner, the straight west face, the
## soft north-west corner, the north face back to the start.
func _zlota_point(i: int, h: float) -> Vector2:
	var e_out := _zlota_out(ZLOTA_NE, ZLOTA_SE, ZLOTA_NW)
	var s_out := _zlota_out(ZLOTA_SE, ZLOTA_SW, ZLOTA_NE)
	var flare := (e_out + s_out * 0.4) * _zlota_flare(h)
	var r := 4.0
	if i <= ZLOTA_EAST_SEGS:
		var u := float(i) / float(ZLOTA_EAST_SEGS)
		return ZLOTA_NE.lerp(ZLOTA_SE, u) + e_out * ZLOTA_CURVE * sin(PI * u) + flare * pow(u, 1.6)
	i -= ZLOTA_EAST_SEGS
	var v_end := 1.0 - r / ZLOTA_SE.distance_to(ZLOTA_SW)
	if i <= ZLOTA_SOUTH_SEGS:
		var v := v_end * float(i) / float(ZLOTA_SOUTH_SEGS)
		return ZLOTA_SE.lerp(ZLOTA_SW, v) + flare * pow(1.0 - v, 1.6)
	i -= ZLOTA_SOUTH_SEGS
	var corners := [[ZLOTA_SE, ZLOTA_SW, ZLOTA_NW], [ZLOTA_SW, ZLOTA_NW, ZLOTA_NE]]
	var k := 0 if i <= 2 else 1
	var a: Vector2 = corners[k][0]
	var c: Vector2 = corners[k][1]
	var b: Vector2 = corners[k][2]
	var p0 := c + (a - c).normalized() * r
	var p1 := c + (b - c).normalized() * r
	var j := i if k == 0 else i - 3  # the south face's last point is the south-west corner's first
	match j:
		0:
			return p0
		1:
			return p0.lerp(c, 0.5).lerp(p1.lerp(c, 0.5), 0.5)
		_:
			return p1


func _zlota_count() -> int:
	return ZLOTA_EAST_SEGS + ZLOTA_SOUTH_SEGS + 2 + 3 + 1


## The plan at height h (closed, ZLOTA_EAST_SEGS + ZLOTA_SOUTH_SEGS + 6 points).
func _zlota_ring(h: float) -> PackedVector2Array:
	var ring := PackedVector2Array()
	for i in _zlota_count():
		ring.append(_zlota_point(i, h))
	return ring


func _zlota_sail(g: float, glass: Color, roof: Color, skin: float) -> void:
	var n := _zlota_count()
	# The cut roof: one plane, ZLOTA_TIP over the tip (the south-east corner at the top), falling
	# to ZLOTA_LOW at the far side of the plan, towards the north face's middle.
	var tip := _zlota_point(ZLOTA_EAST_SEGS, ZLOTA_TIP)
	var axis := ((ZLOTA_NE + ZLOTA_NW) * 0.5 - tip).normalized()
	var span := 0.0
	for q in _zlota_ring(ZLOTA_LOW):
		span = maxf(span, (q - tip).dot(axis))
	var fall := (ZLOTA_TIP - ZLOTA_LOW) / span
	var plane := func(q: Vector2) -> float: return ZLOTA_TIP - clampf((q - tip).dot(axis), 0.0, span) * fall
	# Each point's own height: where its column meets the roof plane (two passes settle it).
	var tops := PackedFloat32Array()
	for i in n:
		var h: float = plane.call(_zlota_point(i, 182.0))
		h = plane.call(_zlota_point(i, h))
		tops.append(plane.call(_zlota_point(i, h)))
	var rings: Array[PackedVector2Array] = []
	for f: float in ZLOTA_RINGS:
		var ring := PackedVector2Array()
		for i in n:
			ring.append(_zlota_point(i, f * tops[i]))
		rings.append(ring)
	var y0 := g - 0.4
	var keep := _mode
	_mode = skin
	var top_ring: PackedVector2Array = rings[-1]
	var cw := Geometry2D.is_polygon_clockwise(top_ring)
	for k in ZLOTA_RINGS.size() - 1:
		var f0: float = ZLOTA_RINGS[k]
		var f1: float = ZLOTA_RINGS[k + 1]
		var r0 := rings[k]
		var r1 := rings[k + 1]
		var run := 0.0
		for i in n:
			var j := (i + 1) % n
			var ya0 := g + f0 * tops[i] if k > 0 else y0
			var yb0 := g + f0 * tops[j] if k > 0 else y0
			var a0 := Vector3(r0[i].x, ya0, r0[i].y)
			var b0 := Vector3(r0[j].x, yb0, r0[j].y)
			var a1 := Vector3(r1[i].x, g + f1 * tops[i], r1[i].y)
			var b1 := Vector3(r1[j].x, g + f1 * tops[j], r1[j].y)
			var e := (r1[j] - r1[i]).normalized()
			var o := Vector2(e.y, -e.x) if cw else Vector2(-e.y, e.x)
			var nrm := (b0 - a0).cross(a1 - a0).normalized()
			if Vector2(nrm.x, nrm.z).dot(o) < 0.0:
				nrm = -nrm
			var length := r0[i].distance_to(r0[j])
			var hi := maxf(tops[i], tops[j])
			# z26_blue: saturated blue panes in patches up the wing's crease (the east face's last
			# segment and the south face's first), from ring 2 up.
			var pane := glass
			if k >= 2 and (i == ZLOTA_EAST_SEGS - 1 or i == ZLOTA_EAST_SEGS):
				pane = glass.lerp(ZLOTA_BLUE, 0.8 if k % 2 == 0 else 0.6)
			_quad(a0, b0, b1, a1, nrm, pane, Vector2(run, ya0 - _g), Vector2(run + length, yb0 - _g),
					Vector2(run + length, b1.y - _g), Vector2(run, a1.y - _g), hi)
			run += length
	_zlota_edge_light(rings, tops, g)
	# The sloped roof: glazed like the walls (a white slab facing the camera blew out).
	_mode = M_SKIN
	var up := Vector3(axis.x * fall, 1.0, axis.y * fall).normalized()
	var idx := Geometry2D.triangulate_polygon(top_ring)
	if idx.is_empty():
		idx = Geometry2D.triangulate_delaunay(top_ring)
	for t in range(0, idx.size(), 3):
		var a := top_ring[idx[t]]
		var b := top_ring[idx[t + 1]]
		var d := top_ring[idx[t + 2]]
		_tri(Vector3(a.x, g + tops[idx[t]], a.y), Vector3(b.x, g + tops[idx[t + 1]], b.y),
				Vector3(d.x, g + tops[idx[t + 2]], d.y), up, glass.lerp(roof, 0.3),
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# The crown: the roof's north and west part, set back from the east face, walled from the
	# slope up to ZLOTA_CROWN in the crown screen's dark glass.
	var far := 400.0
	var side := Vector2(-axis.y, axis.x)
	var start := tip + axis * span * ZLOTA_CROWN_FROM
	var half := PackedVector2Array([start - side * far, start + side * far,
			start + side * far + axis * far, start - side * far + axis * far])
	var e_out := _zlota_out(ZLOTA_NE, ZLOTA_SE, ZLOTA_NW)
	var east_line := ZLOTA_NE - e_out * ZLOTA_CROWN_SET
	var along := (ZLOTA_SE - ZLOTA_NE).normalized()
	var back := PackedVector2Array([east_line - along * far, east_line + along * far,
			east_line + along * far - e_out * far, east_line - along * far - e_out * far])
	var box := PackedVector2Array()
	for p1 in Geometry2D.intersect_polygons(top_ring, half):
		for p2 in Geometry2D.intersect_polygons(p1, back):
			if p2.size() >= 3 and not Geometry2D.is_polygon_clockwise(p2) and _area(p2) > _area(box):
				box = p2
	if box.size() >= 3:
		_mode = M_SKIN + float(S_FINS) / 16.0
		var run := 0.0
		for i in box.size():
			var a := box[i]
			var b := box[(i + 1) % box.size()]
			var o := _out(box, a, b)
			var length := a.distance_to(b)
			var ya: float = g + plane.call(a)
			var yb: float = g + plane.call(b)
			_quad(Vector3(a.x, ya, a.y), Vector3(b.x, yb, b.y), Vector3(b.x, g + ZLOTA_CROWN, b.y),
					Vector3(a.x, g + ZLOTA_CROWN, a.y), Vector3(o.x, 0.0, o.y), ZLOTA_CROWN_GLASS,
					Vector2(run, ya - _g), Vector2(run + length, yb - _g), Vector2(run + length, ZLOTA_CROWN),
					Vector2(run, ZLOTA_CROWN), ZLOTA_CROWN)
			run += length
		_mode = M_STONE
		_cap(box, g + ZLOTA_LID, ZLOTA_CROWN_GLASS.lerp(roof, 0.6))
		_zlota_well(box, g, axis, side)
		_aviation(box, func(_q: Vector2) -> float: return g + ZLOTA_CROWN)
	# A red light on the tip itself.
	var inward := tip + (_centre(top_ring) - tip).normalized() * 1.2
	var tip_y: float = g + plane.call(inward)
	_prism(_square(inward, 0.35), tip_y - 0.2, tip_y + 0.7, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	_mode = keep
	_collide(rings[0])


## The podium's roof garden (the aerial photo: lawn, trees and benches on the low block in front
## of the east face): every low part of the site (20 to 40 m, from the ground), its roof less
## what the tower covers.
func _zlota_garden(parts: Array, g: float) -> void:
	for b: Dictionary in parts:
		var h := float(b["h"])
		if h < 20.0 or h > 40.0 or float(b["mh"]) > 0.5:
			continue
		var grown := Geometry2D.offset_polygon(_zlota_ring(h), 0.6)
		var pieces: Array[PackedVector2Array] = [_pts(b["p"])]
		if not grown.is_empty():
			pieces = []
			for q in Geometry2D.clip_polygons(_pts(b["p"]), grown[0]):
				if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q) and _area(q) >= 60.0:
					pieces.append(q)
		for piece in pieces:
			_varso_garden(piece, g + h, ZLOTA_TERRACE)


## z26_well, z26_coping, z26_plant: the crown box is an open well (its floor ZLOTA_LID, its dark
## glass walls keep their top at ZLOTA_CROWN): the walls' inner faces, a pale coping on their top,
## one plant block on the floor and four duct runs round it (top view: a pale frame round an open
## roof full of plant). `axis` is the slope's long axis, `side` across it.
func _zlota_well(box: PackedVector2Array, g: float, axis: Vector2, side: Vector2) -> void:
	var keep := _mode
	_mode = M_SKIN + float(S_FINS) / 16.0
	var inset := _ring_out(box, -0.05)
	var run := 0.0
	for i in inset.size():
		var j := (i + 1) % inset.size()
		var a := inset[i]
		var b := inset[j]
		var o := -_out(box, box[i], box[j])
		var length := a.distance_to(b)
		_quad(Vector3(a.x, g + ZLOTA_LID, a.y), Vector3(b.x, g + ZLOTA_LID, b.y),
				Vector3(b.x, g + ZLOTA_CROWN, b.y), Vector3(a.x, g + ZLOTA_CROWN, a.y),
				Vector3(o.x, 0.0, o.y), ZLOTA_CROWN_GLASS.darkened(0.2),
				Vector2(run, ZLOTA_LID), Vector2(run + length, ZLOTA_LID),
				Vector2(run + length, ZLOTA_CROWN), Vector2(run, ZLOTA_CROWN), ZLOTA_CROWN)
		run += length
	_mode = M_STONE
	kit_ledge_ring(box, g + ZLOTA_CROWN - 0.4, 0.4, ZLOTA_COPING, 0.05)
	# The plant block 12 x 18 m, long side along the slope axis, and the ducts round it.
	var c := _centre(box)
	var hx := axis * 9.0
	var hy := side * 6.0
	_prism(PackedVector2Array([c - hx - hy, c + hx - hy, c + hx + hy, c - hx + hy]), g + ZLOTA_LID, g + 183.5,
			PAL_PALE_CONCRETE, PAL_ROOF_GRAVEL, M_STONE, M_STONE)
	# The long runs cover the corners; the end runs stop at their inner faces (no overlap).
	var ex := axis * 10.5
	var ey := side * 7.5
	var corner := axis * 11.0
	var inner := side * 7.0
	var lines: Array[PackedVector2Array] = [
		PackedVector2Array([c - corner - ey, c + corner - ey]), PackedVector2Array([c - corner + ey, c + corner + ey]),
		PackedVector2Array([c - ex - inner, c - ex + inner]), PackedVector2Array([c + ex - inner, c + ex + inner])]
	for room in Geometry2D.offset_polygon(box, -1.0):
		for line in lines:
			for seg in Geometry2D.intersect_polyline_with_polygon(line, room):
				for k in seg.size() - 1:
					_beam(Vector3(seg[k].x, g + ZLOTA_LID + 0.53, seg[k].y),
							Vector3(seg[k + 1].x, g + ZLOTA_LID + 0.53, seg[k + 1].y), 1.0, PAL_ALUMINIUM)
	_mode = keep


## Samples [point, outward normal] along the open run ring[i0..i1] from arc distance s0 to s1:
## both ends and every ring vertex between them (normals blended at the vertices).
func _zlota_run(ring: PackedVector2Array, i0: int, i1: int, s0: float, s1: float) -> Array:
	var cnt := i1 - i0
	var arcs := PackedFloat32Array([0.0])
	for k in cnt:
		arcs.append(arcs[k] + ring[i0 + k].distance_to(ring[i0 + k + 1]))
	var vn: Array[Vector2] = []
	for k in cnt + 1:
		var n := Vector2.ZERO
		if k > 0:
			n += _out(ring, ring[i0 + k - 1], ring[i0 + k])
		if k < cnt:
			n += _out(ring, ring[i0 + k], ring[i0 + k + 1])
		vn.append(n.normalized())
	var stops: Array[float] = [s0]
	for k in range(1, cnt):
		if arcs[k] > s0 + 0.3 and arcs[k] < s1 - 0.3:
			stops.append(arcs[k])
	if s1 > s0:
		stops.append(s1)
	var out: Array = []
	for s in stops:
		var k := 0
		while k < cnt - 1 and s > arcs[k + 1]:
			k += 1
		var t := clampf((s - arcs[k]) / maxf(arcs[k + 1] - arcs[k], 0.001), 0.0, 1.0)
		out.append([ring[i0 + k].lerp(ring[i0 + k + 1], t), vn[k].lerp(vn[k + 1], t).normalized()])
	return out


## z26_lobby, z26_portal, z26_blade, z26_plinth: the south entrance on Złota and the dark foot.
## All on the foot ring (`_zlota_ring(0.0)`); the south face is its run SE (index
## ZLOTA_EAST_SEGS) to the soft south-west corner.
func _zlota_foot(parts: Array, g: float) -> void:
	var keep := _mode
	var none := Vector2(-1, -1)
	var ring := _zlota_ring(0.0)
	var i0 := ZLOTA_EAST_SEGS
	var i1 := ZLOTA_EAST_SEGS + ZLOTA_SOUTH_SEGS
	var sc := ZLOTA_LOBBY_AT * ZLOTA_SE.distance_to(ZLOTA_SW)
	var l0 := sc - ZLOTA_LOBBY_W * 0.5
	var l1 := sc + ZLOTA_LOBBY_W * 0.5
	# z26_lobby: a dark double-height glass quad, 0.08 m out of the skin (warm at night).
	_mode = M_PAVILION
	var run := _zlota_run(ring, i0, i1, l0, l1)
	for k in run.size() - 1:
		var a: Array = run[k]
		var b: Array = run[k + 1]
		var pa: Vector2 = (a[0] as Vector2) + (a[1] as Vector2) * 0.08
		var pb: Vector2 = (b[0] as Vector2) + (b[1] as Vector2) * 0.08
		var n: Vector2 = ((a[1] as Vector2) + (b[1] as Vector2)).normalized()
		_quad(Vector3(pa.x, g, pa.y), Vector3(pb.x, g, pb.y), Vector3(pb.x, g + ZLOTA_LOBBY_H, pb.y),
				Vector3(pa.x, g + ZLOTA_LOBBY_H, pa.y), Vector3(n.x, 0.0, n.y), Color("#2c3a44"))
	# z26_portal: two jambs and a head, 0.6 m, black, 0.25 m proud of the skin.
	for s in [l0 - 0.3, l1 + 0.3]:
		var at: Array = _zlota_run(ring, i0, i1, s, s)[0]
		var p: Vector2 = (at[0] as Vector2) - (at[1] as Vector2) * 0.05
		_beam(Vector3(p.x, g, p.y), Vector3(p.x, g + ZLOTA_LOBBY_H + 0.3, p.y), 0.6, PAL_IRON)
	var head := _zlota_run(ring, i0, i1, l0 - 0.6, l1 + 0.6)
	for k in head.size() - 1:
		var a: Array = head[k]
		var b: Array = head[k + 1]
		var pa: Vector2 = (a[0] as Vector2) - (a[1] as Vector2) * 0.05
		var pb: Vector2 = (b[0] as Vector2) - (b[1] as Vector2) * 0.05
		_beam(Vector3(pa.x, g + ZLOTA_LOBBY_H + 0.3, pa.y), Vector3(pb.x, g + ZLOTA_LOBBY_H + 0.3, pb.y), 0.6, PAL_IRON)
	# z26_blade: a thin white canopy at 8 m, 18 m along the face from the SE corner, 3 m out, its
	# east end cut at 45 degrees; under its front edge a warm strip (lit at night).
	var plan := PackedVector2Array()
	for s: Array in _zlota_run(ring, i0, i1, 0.0, ZLOTA_BLADE_LEN):
		plan.append((s[0] as Vector2) + (s[1] as Vector2) * 0.1)
	var front: Array = []
	var cut := ZLOTA_BLADE_OUT - 0.1
	for s in [ZLOTA_BLADE_LEN, (cut + ZLOTA_BLADE_LEN) * 0.5, cut]:
		var at: Array = _zlota_run(ring, i0, i1, s, s)[0]
		front.append(at)
		plan.append((at[0] as Vector2) + (at[1] as Vector2) * ZLOTA_BLADE_OUT)
	var blade := Color("#e9ecee")
	_prism(plan, g + 8.0, g + 8.5, blade, blade, M_STONE, M_STONE)
	_soffit(plan, g + 8.0, blade.darkened(0.15))
	for k in front.size() - 1:
		var fa: Array = front[k]
		var fb: Array = front[k + 1]
		var a2: Vector2 = (fa[0] as Vector2) + (fa[1] as Vector2) * ZLOTA_BLADE_OUT
		var b2: Vector2 = (fb[0] as Vector2) + (fb[1] as Vector2) * ZLOTA_BLADE_OUT
		_prism(PackedVector2Array([a2, b2, b2 - (fb[1] as Vector2) * 0.15, a2 - (fa[1] as Vector2) * 0.15]),
				g + 7.85, g + 8.0, Color("#f6e7c2"), Color(0, 0, 0, 0), M_LAMP, M_LAMP)
	# z26_plinth: 4.6 m of dark granite panels (diagonal joints) on every foot-ring edge whose
	# front is not the podium's, except across the lobby.
	_mode = M_STONE
	var podium: Array[PackedVector2Array] = []
	for b: Dictionary in parts:
		var h := float(b["h"])
		if h >= 20.0 and h <= 40.0 and float(b["mh"]) <= 0.5:
			podium.append(_pts(b["p"]))
	var outer := _ring_out(ring, 0.25)
	var dark := PAL_DARK_GRANITE
	var arc := 0.0
	var y0 := g - 0.4
	var y1 := g + ZLOTA_PLINTH_H
	for i in ring.size():
		var j := (i + 1) % ring.size()
		var a := ring[i]
		var b := ring[j]
		var length := a.distance_to(b)
		var s_mid := arc + length * 0.5
		if i >= i0 and i < i1:
			arc += length
		var o := _out(ring, a, b)
		var skip := i >= i0 and i < i1 and s_mid > l0 and s_mid < l1
		for q in podium:
			if Geometry2D.is_point_in_polygon((a + b) * 0.5 + o * 0.3, q):
				skip = true
		if skip:
			continue
		var nrm := Vector3(o.x, 0.0, o.y)
		var cnt := maxi(1, ceili(length / 4.5))
		for q in cnt:
			var p0 := outer[i].lerp(outer[j], float(q) / cnt)
			var p1 := outer[i].lerp(outer[j], float(q + 1) / cnt)
			var v00 := Vector3(p0.x, y0, p0.y)
			var v10 := Vector3(p1.x, y0, p1.y)
			var v11 := Vector3(p1.x, y1, p1.y)
			var v01 := Vector3(p0.x, y1, p0.y)
			_tri(v00, v10, v11, nrm, dark, none, none, none, -1.0)
			_tri(v00, v11, v01, nrm, dark.lightened(0.06), none, none, none, -1.0)
		_quad(Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), Vector3(outer[j].x, y1, outer[j].y),
				Vector3(outer[i].x, y1, outer[i].y), Vector3.UP, dark.lightened(0.12))
	_mode = keep


## z26_pool and z26_path on the 32 m podium's roof garden, after its deck (out of the roof grid):
## a small pool with a pale coping and a diagonal paved path across the lawn. The deck top is
## 0.12 m over the part's roof (`_varso_garden`).
func _zlota_pool(parts: Array, g: float) -> void:
	var at := Vector2(-1457.0, 288.2)  # spec 289.0, moved north out of the lawn bed (F: option a)
	var keep := _mode
	var keep_roof := _no_roof
	_no_roof = true
	for b: Dictionary in parts:
		var h := float(b["h"])
		if h < 20.0 or h > 40.0 or float(b["mh"]) > 0.5:
			continue
		var poly := _pts(b["p"])
		if not Geometry2D.is_point_in_polygon(at, poly):
			continue
		var pieces: Array[PackedVector2Array] = [poly]
		var grown := Geometry2D.offset_polygon(_zlota_ring(h), 0.6)
		if not grown.is_empty():
			pieces = []
			for q in Geometry2D.clip_polygons(poly, grown[0]):
				if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q) and _area(q) >= 60.0:
					pieces.append(q)
		var deck := g + h + 0.12
		for piece in pieces:
			for rim: PackedVector2Array in Geometry2D.offset_polygon(piece, -0.5):
				if rim.size() < 3 or Geometry2D.is_polygon_clockwise(rim) or not Geometry2D.is_point_in_polygon(at, rim):
					continue
				# The pool: 5.0 x 3.6 m, long side east-west.
				var pool := PackedVector2Array([at + Vector2(-2.5, -1.8), at + Vector2(2.5, -1.8),
						at + Vector2(2.5, 1.8), at + Vector2(-2.5, 1.8)])
				var edge := _ring_out(pool, 0.25)
				# Raised 0.43 m: the lawn bed's top is that high over the deck, and would bury the pool.
				var top := deck + 0.43 + 0.3
				var wet := deck + 0.43 + 0.05
				_mode = M_STONE
				_prism(edge, deck, top, PAL_PALE_CONCRETE, Color(0, 0, 0, 0), M_STONE)
				_strip(pool, edge, top, PAL_PALE_CONCRETE.darkened(0.1))
				for i in 4:
					var a := pool[i]
					var c := pool[(i + 1) % 4]
					var o := -_out(pool, a, c)
					_quad(Vector3(a.x, wet, a.y), Vector3(c.x, wet, c.y), Vector3(c.x, top, c.y),
							Vector3(a.x, top, a.y), Vector3(o.x, 0.0, o.y), PAL_PALE_CONCRETE.darkened(0.2))
				_mode = M_LAMP + 0.5
				_cap(pool, wet, Color("#7fc4c0"))
				# The path: 2 m wide, over the deck, under any bed it crosses.
				var from := Vector2(-1455.0, 292.0)
				var to := Vector2(-1450.0, 322.0)
				var across := (to - from).normalized().orthogonal()
				var strip := PackedVector2Array([from - across, from + across, to + across, to - across])
				_mode = M_STONE
				for q in Geometry2D.intersect_polygons(strip, rim):
					if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q) and _area(q) > 1.0:
						_cap(q, deck + 0.04, PAL_PALE_CONCRETE)
				break
	_no_roof = keep_roof
	_mode = keep


## Warsaw Spire (rebuilt 2026-11-06 from F's ten photos; spec docs/landmarks/specs/spire.md).
## OpenStreetMap maps the 180 m tower only as its outline (its widest plan) with the crown and
## masts as floating parts. The real tower is a vase (F's photos IMG_7349-7352): a waist low down,
## then sides curving in as they flare out to the full plan at the roof (concave, not convex), where the glass runs on past the roof into a
## saddle crown, high at the two narrow ends (photos IMG_7329, 7333). So the outline is lofted
## through SPIRE_RINGS with SpireMotion.k_at (spire_motion.gd: the same rings carry the LED band and
## the night's lines of light); the shaft is grey-blue mirror glass with a fine silver line at each
## floor and a glass fin out of each narrow end (IMG_7332, F's night photos 2026-11-14); the lobby stands back under the shaft behind a ring of polished
## steel columns in pairs (IMG_7337); a mirrored canopy with upswept wing tips shades the north
## entrance (IMG_7336, 7337). The two 55 m crescents flanking the plaza, Spire B and C, are
## `_spire_wing`; the plaza's pools, channel and trees `_spire_water`.
const SpireMotion := preload("res://scripts/spire_motion.gd")
const SPIRE_TOP := SpireMotion.ROOF
const SPIRE_LOBBY := 10.0
## Ring heights: spire_motion.gd's, so its LED band and lines of light lie on the glass.
const SPIRE_RINGS := SpireMotion.RINGS
const SPIRE_CROWN := Vector2(6.0, 12.0)  # the crown's open steel ring over the roof: at the wide faces, extra up the horns
const SPIRE_LOBBY_GLASS := Color("#2c4656")
const SPIRE_STEEL := Color("#c3ccd3")      # polished steel (M_GOLD + 0.5: no warm glow)
const SPIRE_MIRROR := Color("#d3dde4")     # the canopy's top
const SPIRE_MIRROR_UNDER := Color("#8e9aa3")  # its underside, mirroring the plaza
const SPIRE_SPINE := Color("#9fbfd8")      # the fins' pale glass
const SPIRE_MAST_RED := Color("#c8322c")
const SPIRE_DRUM := Color("#d9dcdc")       # the roof drum's pale ribbed cladding (IMG_7351)      # the lit strip up each narrow end
const SPIRE_WING_GLASS := Color("#2f4a6a")  # dark navy like the tower (F, 2026-11-17)
const SPIRE_WING_LOBBY := Color("#28404e")
const SPIRE_WING_CROWN := Color("#c4b69c")  # the top storey's pale stone panels (IMG_7331)
const SPIRE_WING_EAVE := Color("#dfe4e7")   # the thin white roof edge (IMG_7330)
const SPIRE_WING_STONE := Color("#aab4ba")
const SPIRE_PAVING := Color("#c9c4b6")
const SPIRE_GRANITE := Color("#9a9a96")
const SPIRE_CHANNEL := Color("#6f8f95")    # clear shallow water over pebbles (IMG_7330)
const SPIRE_SOIL := Color("#56703a")
const SPIRE_LOCUST := Color("#8daa48")     # honey locusts, light yellow-green (IMG_7330)
const SPIRE_CYPRESS := Color("#5f7f36")    # the slim conical swamp cypresses (IMG_7330, 7332)
const SPIRE_TRUNK := Color("#4a3f35")


func _spire(outline: PackedVector2Array, g: float, glass: Color, roof: Color, skin: float, masts: Array) -> void:
	var base := SpireMotion.plan(outline)
	if base.size() < 3:
		return
	var c := SpireMotion.centre(base)
	# The long axis, towards the north end (the entrance).
	var axis := Vector2.ZERO
	for q in base:
		if (q - c).length() > axis.length():
			axis = q - c
	axis = axis.normalized()
	if axis.y > 0.0:
		axis = -axis
	var keep := _mode
	var cw := Geometry2D.is_polygon_clockwise(base)
	# The lobby: dark lit glass standing back under the shaft.
	var foot := SpireMotion.ring(base, SPIRE_LOBBY)
	var lobby := PackedVector2Array()
	for q in foot:
		lobby.append(c + (q - c) * 0.9)
	_prism(lobby, g - 0.4, g + SPIRE_LOBBY, SPIRE_LOBBY_GLASS, Color(0, 0, 0, 0), M_PAVILION + 0.5, M_STONE)
	# The shaft.
	for s in SPIRE_RINGS.size() - 1:
		var h0: float = SPIRE_RINGS[s]
		var h1: float = SPIRE_RINGS[s + 1]
		var r0 := SpireMotion.ring(base, h0)
		var r1 := SpireMotion.ring(base, h1)
		_mode = skin
		var run := 0.0
		for i in base.size():
			var j := (i + 1) % base.size()
			var e := (r0[j] - r0[i]).normalized()
			var o := Vector2(e.y, -e.x) if cw else Vector2(-e.y, e.x)
			var length := r0[i].distance_to(r0[j])
			_quad(Vector3(r0[i].x, g + h0, r0[i].y), Vector3(r0[j].x, g + h0, r0[j].y), Vector3(r1[j].x, g + h1, r1[j].y),
					Vector3(r1[i].x, g + h1, r1[i].y), Vector3(o.x, 0.0, o.y), glass, Vector2(run, h0),
					Vector2(run + length, h0), Vector2(run + length, h1), Vector2(run, h1), SPIRE_TOP)
			run += length
	_mode = keep
	_spire_fins(base, c, axis, g)
	_spire_crown(base, c, axis, g, glass, skin)
	var top := SpireMotion.ring(base, SPIRE_TOP)
	# The roof inside the ring (IMG_7351): a gravel walk, then a pale ribbed drum in two tiers with
	# the plant on top, the masts rising from it.
	_cap(top, g + SPIRE_TOP, roof)
	var drum := PackedVector2Array()
	var drum2 := PackedVector2Array()
	for q in top:
		drum.append(c + (q - c) * 0.74)
		drum2.append(c + (q - c) * 0.5)
	var ribs := M_SKIN + float(S_FINS) / 16.0
	_prism(drum, g + SPIRE_TOP, g + SPIRE_TOP + 7.0, SPIRE_DRUM, Color("#b4ab98"), ribs, M_STONE)
	_prism(drum2, g + SPIRE_TOP + 7.0, g + SPIRE_TOP + 11.0, SPIRE_DRUM, roof, ribs, M_STONE)
	_prism(_square(c + axis * 3.0, 3.5), g + SPIRE_TOP + 11.0, g + SPIRE_TOP + 13.0, Color("#c9cdd0"), Color("#dfe2e4"), M_STONE, M_STONE)
	_prism(_square(c - axis * 4.0, 3.0), g + SPIRE_TOP + 11.0, g + SPIRE_TOP + 12.6, Color("#c9cdd0"), Color("#dfe2e4"), M_STONE, M_STONE)
	# The masts (the two OSM parts' spots), the beacons' posts.
	for m: Vector2 in masts:
		var post := PackedVector2Array([m + Vector2(-0.5, -0.5), m + Vector2(0.5, -0.5), m + Vector2(0.5, 0.5), m + Vector2(-0.5, 0.5)])
		# white with a red tip in aviation bands (F's night photos: the two masts' red tips), a
		# red lamp on top that glows at night
		_prism(post, g + SPIRE_TOP + 11.0, g + 212.0, Color("#d5dade"), Color("#e8ecef"), M_STONE, M_STONE)
		for k in 4:
			var tip := SPIRE_MAST_RED if k % 2 == 0 else Color("#e8ecef")
			_prism(post, g + 212.0 + k * 2.0, g + 214.0 + k * 2.0, tip, tip, M_STONE, M_STONE)
		_prism(_square(m, 0.45), g + 220.0, g + 221.0, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	_collide(foot)
	_aviation(top, func(_q: Vector2) -> float: return g + SPIRE_TOP + SPIRE_CROWN.x)  # the dusk loop
	_spire_columns(foot, c, g)
	_spire_canopy(foot, c, axis, g)
	var front := INF
	for q in foot:
		if absf(q.x - c.x) < 6.0:
			front = minf(front, q.y)
	if front < INF:
		_spire_plaza(c, g, front)
	_spire_water()


## The fins (F's night photos IMG_7977, 7979 and the street photos: a glass blade stands out of
## each narrow end the whole height and runs on past the roof into the crown's horns): a blade
## SpireMotion.FIN_OUT deep and 0.6 m thick from FIN_FROM (over the canopy's tips) to FIN_TOP, pale
## glass lit cool at night; its front edge carries spire_motion.gd's line of light.
func _spire_fins(base: PackedVector2Array, c: Vector2, axis: Vector2, g: float) -> void:
	var keep := _mode
	for d: Vector2 in [axis, -axis]:
		var side := Vector2(-d.y, d.x) * 0.3
		var hs: Array[float] = [SpireMotion.FIN_FROM]
		for r: float in SPIRE_RINGS:
			if r > SpireMotion.FIN_FROM:
				hs.append(r)
		hs.append(SpireMotion.FIN_TOP)
		for s in hs.size() - 1:
			var h0 := hs[s]
			var h1 := hs[s + 1]
			var e0 := SpireMotion.fin_edge(base, d, h0)
			var e1 := SpireMotion.fin_edge(base, d, h1)
			# the blade's root a little inside the glass so no seam shows
			var b0 := e0 - d * (SpireMotion.FIN_OUT + 0.3)
			var b1 := e1 - d * (SpireMotion.FIN_OUT + 0.3)
			var uv := [Vector2(0, h0), Vector2(SpireMotion.FIN_OUT, h0), Vector2(SpireMotion.FIN_OUT, h1), Vector2(0, h1)]
			_mode = M_PAVILION + 0.5
			for sg in [-1.0, 1.0]:
				var o: Vector2 = side * sg
				_quad(Vector3(b0.x + o.x, g + h0, b0.y + o.y), Vector3(e0.x + o.x, g + h0, e0.y + o.y),
						Vector3(e1.x + o.x, g + h1, e1.y + o.y), Vector3(b1.x + o.x, g + h1, b1.y + o.y),
						Vector3(o.x, 0.0, o.y).normalized(), SPIRE_SPINE, uv[0], uv[1], uv[2], uv[3], SPIRE_TOP)
			_mode = M_STONE
			_quad(Vector3(e0.x - side.x, g + h0, e0.y - side.y), Vector3(e0.x + side.x, g + h0, e0.y + side.y),
					Vector3(e1.x + side.x, g + h1, e1.y + side.y), Vector3(e1.x - side.x, g + h1, e1.y - side.y),
					Vector3(d.x, 0.0, d.y), SPIRE_STEEL)
			if h0 >= SPIRE_TOP:
				# over the roof the blade's back is in the air
				_quad(Vector3(b0.x - side.x, g + h0, b0.y - side.y), Vector3(b0.x + side.x, g + h0, b0.y + side.y),
						Vector3(b1.x + side.x, g + h1, b1.y + side.y), Vector3(b1.x - side.x, g + h1, b1.y - side.y),
						Vector3(-d.x, 0.0, -d.y), SPIRE_STEEL.darkened(0.1))
		# the blade's top and its foot
		for at: Array in [[hs[hs.size() - 1], Vector3.UP], [hs[0], Vector3.DOWN]]:
			var h: float = at[0]
			var e := SpireMotion.fin_edge(base, d, h)
			var bb := e - d * (SpireMotion.FIN_OUT + 0.3)
			_mode = M_STONE
			_quad(Vector3(bb.x - side.x, g + h, bb.y - side.y), Vector3(e.x - side.x, g + h, e.y - side.y),
					Vector3(e.x + side.x, g + h, e.y + side.y), Vector3(bb.x + side.x, g + h, bb.y + side.y), at[1], SPIRE_STEEL)
	_mode = keep


## The crown: an open steel ring standing on the roof's rim (IMG_7351), low over the wide faces and
## rising to a horn at each narrow end (IMG_7349, 7352), seen from both sides.
func _spire_crown(base: PackedVector2Array, c: Vector2, axis: Vector2, g: float, glass: Color, skin: float) -> void:
	var top := SpireMotion.ring(base, SPIRE_TOP)
	var y0 := g + SPIRE_TOP
	var hi := func(q: Vector2) -> float:
		var w := absf((q - c).normalized().dot(axis))
		return y0 + SPIRE_CROWN.x + SPIRE_CROWN.y * pow(w, 10.0)
	var keep := _mode
	var cw := Geometry2D.is_polygon_clockwise(base)
	var run := 0.0
	for i in top.size():
		var j := (i + 1) % top.size()
		var a := top[i]
		var b := top[j]
		var e := (b - a).normalized()
		var o := Vector2(e.y, -e.x) if cw else Vector2(-e.y, e.x)
		var ya: float = hi.call(a)
		var yb: float = hi.call(b)
		var length := a.distance_to(b)
		_mode = M_SKIN + float(S_FRAME) / 16.0
		_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, yb, b.y), Vector3(a.x, ya, a.y), Vector3(o.x, 0.0, o.y), SPIRE_STEEL,
				Vector2(run, SPIRE_TOP), Vector2(run + length, SPIRE_TOP), Vector2(run + length, yb - g), Vector2(run, ya - g), SPIRE_TOP + SPIRE_CROWN.y)
		_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, yb, b.y), Vector3(a.x, ya, a.y), Vector3(-o.x, 0.0, -o.y), SPIRE_STEEL.darkened(0.15),
				Vector2(run, SPIRE_TOP), Vector2(run + length, SPIRE_TOP), Vector2(run + length, yb - g), Vector2(run, ya - g), SPIRE_TOP + SPIRE_CROWN.y)
		_mode = M_STONE
		# the top edge: a steel coping
		var ca := Vector3(a.x, ya, a.y)
		var cb := Vector3(b.x, yb, b.y)
		var cd := Vector3(a.x + o.x * 0.3, ya + 0.25, a.y + o.y * 0.3)
		var cn := (cb - ca).cross(cd - ca).normalized()
		if cn.dot(Vector3(o.x, 1.0, o.y)) < 0.0:
			cn = -cn
		_quad(ca, cb, Vector3(b.x + o.x * 0.3, yb + 0.25, b.y + o.y * 0.3), cd, cn, SPIRE_STEEL)
		run += length
	_mode = keep


## The ring of polished steel columns round the lobby (IMG_7337): pairs leaning together into a
## Λ, their heads meeting under the shaft's edge at 10 m, about every 6 m round.
func _spire_columns(foot: PackedVector2Array, c: Vector2, g: float) -> void:
	var cum: Array[float] = [0.0]
	for i in foot.size():
		cum.append(cum[-1] + foot[i].distance_to(foot[(i + 1) % foot.size()]))
	var total: float = cum[-1]
	var at := func(s: float) -> Vector2:
		s = fposmod(s, total)
		for i in foot.size():
			if s <= cum[i + 1]:
				var t := (s - cum[i]) / maxf(cum[i + 1] - cum[i], 0.001)
				return foot[i].lerp(foot[(i + 1) % foot.size()], t)
		return foot[0]
	var pairs := maxi(8, int(round(total / 6.0)))
	for k in pairs:
		var s := total * (k + 0.5) / pairs
		var head: Vector2 = at.call(s)
		head = head + (c - head).normalized() * 0.4
		for side in [-1.0, 1.0]:
			var f: Vector2 = at.call(s + side * 2.4)
			f = f + (f - c).normalized() * 0.6
			_beam(Vector3(f.x, g - 0.2, f.y), Vector3(head.x, g + SPIRE_LOBBY, head.y), 0.75, SPIRE_STEEL, true, M_STEEL)


## The mirrored canopy over the north entrance (IMG_7336, 7337): a wide bow of polished steel
## growing out of the shaft's narrow end at 11 m, its two wing tips swept up and out to 17 m, the
## middle reaching 16 m out towards the plaza; mirror on top and below, a white rim, four legs.
func _spire_canopy(foot: PackedVector2Array, c: Vector2, axis: Vector2, g: float) -> void:
	var tip := foot[0]
	for q in foot:
		if (q - c).dot(axis) > (tip - c).dot(axis):
			tip = q
	var side := Vector2(-axis.y, axis.x)
	var root := tip - axis * 2.0
	var nu := 8
	var nv := 3
	var pt := func(u: float, v: float, under: bool) -> Vector3:
		var w := lerpf(8.0, 21.0, v)
		var out := v * 16.0 * (1.0 - 0.6 * u * u)
		var p := root + side * u * w + axis * out
		var y := g + 11.0 + v * (1.2 + 5.8 * pow(absf(u), 3.0)) - (0.9 if under else 0.0)
		return Vector3(p.x, y, p.y)
	var keep := _mode
	_mode = M_STEEL
	for iu in nu:
		for iv in nv:
			var u0 := -1.0 + 2.0 * iu / nu
			var u1 := -1.0 + 2.0 * (iu + 1) / nu
			var v0 := float(iv) / nv
			var v1 := float(iv + 1) / nv
			for under in [false, true]:
				var a: Vector3 = pt.call(u0, v0, under)
				var b: Vector3 = pt.call(u1, v0, under)
				var cc: Vector3 = pt.call(u1, v1, under)
				var d: Vector3 = pt.call(u0, v1, under)
				var n := (cc - a).cross(d - b).normalized()
				if (n.y < 0.0) != under:
					n = -n
				_quad(a, b, cc, d, n, SPIRE_MIRROR_UNDER if under else SPIRE_MIRROR)
	# the rim round the outer edge and the two ends
	var edge: Array[Vector2] = []
	edge.append(Vector2(-1.0, 0.0))
	for iu in nu + 1:
		edge.append(Vector2(-1.0 + 2.0 * iu / nu, 1.0))
	edge.append(Vector2(1.0, 0.0))
	_mode = M_STONE
	for k in edge.size() - 1:
		var a: Vector3 = pt.call(edge[k].x, edge[k].y, false)
		var b: Vector3 = pt.call(edge[k + 1].x, edge[k + 1].y, false)
		var a2: Vector3 = pt.call(edge[k].x, edge[k].y, true)
		var b2: Vector3 = pt.call(edge[k + 1].x, edge[k + 1].y, true)
		var mid := Vector2((a.x + b.x) * 0.5, (a.z + b.z) * 0.5) - root
		var n := (b2 - a2).cross(a - a2).normalized()
		if n.dot(Vector3(mid.x, 0.0, mid.y)) < 0.0:
			n = -n
		_quad(a2, b2, b, a, n, Color("#f0f3f4"))
	_mode = keep
	# four slender legs, two Λ's, under the middle of the bow
	for su in [-1.0, 1.0]:
		for u in [0.18, 0.5]:
			var head: Vector3 = pt.call(su * u, 0.55, true)
			var f: Vector2 = Vector2(head.x, head.z) + side * su * 2.2
			_beam(Vector3(f.x, g - 0.2, f.y), head, 0.6, SPIRE_STEEL, true, M_STEEL)


## Spire B and C (IMG_7330, 7331, 7334): the mapped 55 m crescents in blue mirror glass with a silver
## line at each floor, over a dark lit ground floor; a top storey of pale stone panels and slim
## posts; a thin white roof edge standing out 1 m all round; plant screens on the roof.
func _spire_wing(poly: PackedVector2Array) -> void:
	var p := PackedVector2Array()
	for q in poly:
		if p.is_empty() or (q.distance_to(p[-1]) > 1.8 and q.distance_to(p[0]) > 1.8):
			p.append(q)
	if p.size() < 3:
		return
	var g := _ground_under(p)
	_g = g
	var none := Color(0, 0, 0, 0)
	_prism(p, g - 0.4, g + 5.0, SPIRE_WING_LOBBY, none, M_PAVILION + 0.5, M_STONE)
	_prism(p, g + 5.0, g + 51.0, SPIRE_WING_GLASS, none, M_SKIN + float(S_MIRROR) / 16.0, M_SKIN)
	_prism(p, g + 51.0, g + 55.0, SPIRE_WING_CROWN, SPIRE_WING_STONE, M_SKIN + float(S_FINS) / 16.0, M_STONE)
	var eave := Geometry2D.offset_polygon(p, 1.0)
	if not eave.is_empty():
		_prism(eave[0], g + 55.0, g + 55.45, SPIRE_WING_EAVE, SPIRE_WING_EAVE.darkened(0.04), M_STONE, M_STONE)
	var inner := Geometry2D.offset_polygon(p, -3.5)
	if not inner.is_empty():
		_prism(inner[0], g + 55.45, g + 58.0, SPIRE_WING_STONE, SPIRE_WING_STONE.lightened(0.1), M_STONE, M_STONE)
	_collide(p)


## The plaza in front of the tower: pale paving over a half-disc on the north side and a row of
## low black bollards along its edge.
func _spire_plaza(c: Vector2, g: float, front: float) -> void:
	var edge := Vector2(c.x, front)
	var slab := PackedVector2Array()
	for k in 13:
		var a := PI * float(k) / 12.0
		slab.append(edge + Vector2(-cos(a) * 26.0, -sin(a) * 22.0))
	_prism(slab, g - 0.5, g + 0.03, SPIRE_PAVING, SPIRE_PAVING.lightened(0.04), M_STONE, M_STONE)
	for k in range(1, 12):
		var a := PI * float(k) / 12.0
		var at := edge + Vector2(-cos(a) * 25.0, -sin(a) * 21.0)
		var post := PackedVector2Array([at + Vector2(-0.13, -0.13), at + Vector2(0.13, -0.13), at + Vector2(0.13, 0.13), at + Vector2(-0.13, 0.13)])
		_prism(post, g, g + 0.9, Color("#26282b"), Color("#3a3d41"), M_STONE, M_STONE)


## The plaza's water and trees (F's photos IMG_7330, 7332, 7334): granite kerbs round the mapped
## pools and the fountain's basin, three round planted islands in the big pool, the pebble channel
## down Spire B's west face, a honey locust on each mapped planter and slim swamp cypresses by the
## big pool. The jets that play in them are spire_motion.gd's.
const SPIRE_ISLANDS := [Vector2(-2702.5, 151.5), Vector2(-2687.0, 147.5), Vector2(-2696.5, 155.8)]
const SPIRE_CYPRESSES := [Vector2(-2678.5, 140.5), Vector2(-2677.0, 147.0), Vector2(-2678.5, 153.5),
		Vector2(-2711.5, 131.0), Vector2(-2710.0, 125.0)]
const SPIRE_PLAZA_BOX := Rect2(-2730.0, 112.0, 60.0, 126.0)


func _spire_water() -> void:
	for a in data.get("areas", []) + data.get("surfaces", []):
		var k := str(a.get("k", ""))
		if k != "water" and k != "fountain" and k != "park":
			continue
		var poly := _pts(a["p"])
		var c := _centre(poly)
		if not SPIRE_PLAZA_BOX.has_point(c):
			continue
		var y: float = map.terrain_height(c.x, c.y)
		if k == "park":
			if _area(poly) < 60.0:
				_spire_tree(c, y + 0.1, 6.5 + fposmod(c.x * 1.7, 2.0), 2.4, false)
			continue
		_spire_kerb(poly, y, 0.55 if k == "fountain" else 0.35)
		if k == "water":
			tree_free.append([poly, 0.0, _box_of([poly])])
	for p: Vector2 in SPIRE_ISLANDS:
		var y: float = map.terrain_height(p.x, p.y)
		var ring := _circle(p, 1.8, 12)
		_prism(ring, y - 0.2, y + 0.45, SPIRE_GRANITE, SPIRE_SOIL, M_STONE, M_STONE)
		_spire_tree(p, y + 0.45, 7.5, 2.6, false)
	for p: Vector2 in SPIRE_CYPRESSES:
		_spire_tree(p, map.terrain_height(p.x, p.y), 11.0, 1.9, true)
	# The pebble channel: its water over the pebbles, a granite kerb round it.
	var line := SpireMotion.channel_line()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in line.size():
		var d := (line[mini(i + 1, line.size() - 1)] - line[maxi(i - 1, 0)]).normalized()
		var n := Vector2(-d.y, d.x) * SpireMotion.CHANNEL_W * 0.5
		left.append(line[i] + n)
		right.append(line[i] - n)
	right.reverse()
	var chan := left + right
	var cy: float = map.terrain_height(line[0].x, line[0].y)
	for q in line:
		cy = minf(cy, map.terrain_height(q.x, q.y))
	_cap(chan, cy + 0.06, SPIRE_CHANNEL)
	_spire_kerb(chan, cy, 0.3)


## A granite kerb `h` high and 0.45 m wide round a pool, its inner face down to the water.
func _spire_kerb(poly: PackedVector2Array, y: float, h: float) -> void:
	if Geometry2D.is_polygon_clockwise(poly):
		poly = PackedVector2Array(poly)
		poly.reverse()
	var grown := Geometry2D.offset_polygon(poly, 0.45)
	if grown.is_empty():
		return
	var outer: PackedVector2Array = grown[0]
	var rev := PackedVector2Array(poly)
	rev.reverse()
	_prism(outer, y - 0.2, y + h, SPIRE_GRANITE, Color(0, 0, 0, 0), M_STONE)
	_prism(rev, y - 0.2, y + h, SPIRE_GRANITE.darkened(0.12), Color(0, 0, 0, 0), M_STONE)
	_cap_holes(outer, [poly], y + h, SPIRE_GRANITE.lightened(0.12))


## A plaza tree: a honey locust (a rounded crown of two cones) or a swamp cypress (`slim`: one
## tall narrow cone).
func _spire_tree(p: Vector2, y: float, h: float, r: float, slim: bool) -> void:
	_prism(_square(p, 0.14), y, y + h * 0.4, SPIRE_TRUNK, Color(0, 0, 0, 0), M_STONE)
	_mode = M_STONE
	if slim:
		_frustum(_circle(p, r, 6), y + h * 0.18, _circle(p, 0.15, 6), y + h, SPIRE_CYPRESS, SPIRE_CYPRESS.lightened(0.05))
		return
	var leaf := SPIRE_LOCUST.darkened(0.08 * fposmod(p.x + p.y, 2.0))
	_frustum(_circle(p, r * 0.35, 6), y + h * 0.36, _circle(p, r, 6), y + h * 0.66, leaf.darkened(0.12))
	_frustum(_circle(p, r, 6), y + h * 0.66, _circle(p, r * 0.4, 6), y + h, leaf, leaf.lightened(0.08))


## A tower's top cut on a slope: the walls rise to `hi` at the outline's far end (its longest
## axis, towards the north) and fall to `lo` at the other, and a sloping roof closes it.
func _sloped(poly: PackedVector2Array, y0: float, hi: float, lo: float, wall: Color, roof: Color, skin: float) -> void:
	var c := _centre(poly)
	var axis := Vector2.ZERO
	var reach := 0.0
	for q in poly:
		if (q - c).length() > reach:
			reach = (q - c).length()
			axis = (q - c).normalized()
	if axis.y > 0.0:
		axis = -axis  # the high end towards the north (-z)
	var lo_d := INF
	var hi_d := -INF
	for q in poly:
		lo_d = minf(lo_d, (q - c).dot(axis))
		hi_d = maxf(hi_d, (q - c).dot(axis))
	var top := func(q: Vector2) -> float:
		return lerpf(lo, hi, inverse_lerp(lo_d, hi_d, (q - c).dot(axis)))
	var keep := _mode
	_mode = skin
	var run := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var length := a.distance_to(b)
		if length < 0.02:
			continue
		var o := _out(poly, a, b)
		var n := Vector3(o.x, 0.0, o.y).normalized()
		var ta: float = top.call(a)
		var tb: float = top.call(b)
		# The rectangle up to the lower end goes through _wall (so a podium wall flush with it
		# is cut back, not drawn over it); the wedge above it is a triangle.
		var lowest := minf(ta, tb)
		_wall(a, b, y0, lowest, o, wall, run)
		if absf(ta - tb) > 0.01:
			var a_high := ta > tb
			var p_hi := (a if a_high else b)
			var p_lo := (b if a_high else a)
			var t_hi := maxf(ta, tb)
			var r_hi := run if a_high else run + length
			var r_lo := run + length if a_high else run
			_tri(Vector3(p_lo.x, lowest, p_lo.y), Vector3(p_hi.x, lowest, p_hi.y), Vector3(p_hi.x, t_hi, p_hi.y), n, wall,
					Vector2(r_lo, lowest - _g), Vector2(r_hi, lowest - _g), Vector2(r_hi, t_hi - _g), t_hi - _g)
		run += length
	_mode = M_SKIN
	var idx := Geometry2D.triangulate_polygon(poly)
	if idx.is_empty():
		idx = Geometry2D.triangulate_delaunay(poly)
	var up := Vector3(-axis.x * (hi - lo), absf(hi_d - lo_d), -axis.y * (hi - lo)).normalized()
	for i in range(0, idx.size(), 3):
		var a := poly[idx[i]]
		var b := poly[idx[i + 1]]
		var d := poly[idx[i + 2]]
		# Glazed like the walls: a pale slab tilted to the camera blew out (the landmarks loop).
		_tri(Vector3(a.x, top.call(a), a.y), Vector3(b.x, top.call(b), b.y), Vector3(d.x, top.call(d), d.y), up,
				wall.lerp(roof, 0.3), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_mode = keep


# --- Map north: Arkadia, the Forest tower, Rondo Radosława's flag (the landmarks loop) -----------

## Arkadia (2004), the city's biggest mall, by Rondo Radosława, rebuilt from F's ten photos
## (2026-11-03, spec docs/landmarks/specs/arkadia.md): the round fountain plaza in front of the
## south-west entrance; the square sign tower with ZACHODNIE POLE on its crown, the shops' logo
## panels and a big screen; the glass entrance between four stone piers with canopies and the fan
## of glass gables behind it; the dark glass office wing on the left; the brick and render wing
## with the rotunda corner and its yellow café awnings on the right; the roof car park; the big
## letter sign by the lawns. All names are parodies (ZACHODNIE POLE is "Westfield" in Polish).
const ARKADIA_TOWER := Vector2(-2779.0, -2466.0)
const ARKADIA_R := 29.5                                # the entrance arc round the plaza (OSM)
const ARKADIA_ARC := Vector2(-104.0, 4.0)             # its ends, degrees round the fountain
const ARKADIA_FOUNTAIN := Vector2(-2761.0, -2443.0)   # OSM's fountain, the plaza's middle
const ARKADIA_ROTUNDA := Vector2(-2705.0, -2413.0)
const ARKADIA_SIGN := Vector2(-2797.0, -2361.0)       # the big letters on the lawns' flowerbed, towards the rondo
const ARKADIA_TOP := 21.0
const ARKADIA_SHOP := 5.6
const ARKADIA_PANEL := Color("#dcdbd5")
const ARKADIA_STONE := Color("#cbb38e")
const ARKADIA_BRICK := Color("#a9583c")
const ARKADIA_RENDER := Color("#dcc9a6")
const ARKADIA_DARK := Color("#2d3a44")
const ARKADIA_YELLOW := Color("#f2c230")
const ARKADIA_STRIP_GAP := 70.0
const ARKADIA_DECK_REACH := 200.0
const ARKADIA_CARS_MAX := 1500
const ARKADIA_ROOF := Color("#77797a")
const ARKADIA_RED := Color(1.0, 0.18, 0.22)
const ARKADIA_WHITE := Color(0.97, 0.97, 1.0)
func _find_arkadia() -> void:
	var outline := _landmark("Westfield Arkadia")
	if outline.size() >= 3:
		_add_site("arkadia", [outline])
		# The letter sign stands on the lawns 40 m off the outline: the box reaches it, so the
		# sector that holds the sign builds the site.
		var box: Rect2 = sites[-1]["box"]
		sites[-1]["box"] = box.expand(ARKADIA_SIGN + Vector2(8.0, 8.0)).expand(ARKADIA_SIGN - Vector2(8.0, 8.0))


func _build_arkadia(site: Dictionary) -> void:
	var raw: PackedVector2Array = site["zone"][0]
	# The plaza: the mapped outline wraps round it; nothing of the mall stands inside its circle.
	var court := _circle(ARKADIA_FOUNTAIN, ARKADIA_R, 48)
	var poly := _arkadia_cut(_simplify(raw, 1.5), court)
	_g = _ground_under(poly)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# Three masses: the office wing (west, along Jana Pawła II), the brick wing with the rotunda
	# (the south-east face), and the main block behind them.
	var office_box := _box_poly(Rect2(-2860.0, -2600.0, 64.0, 160.0))
	var sd := (Vector2(-2545.0, -2517.0) - Vector2(-2700.0, -2404.0)).normalized()
	var r0 := Vector2(-2700.0, -2404.0)
	var sn := Vector2(-sd.y, sd.x)
	if sn.dot(Vector2(-2690.0, -2570.0) - r0) < 0.0:
		sn = -sn  # into the mall
	# (Deeper at its west end: the low stair block between the rotunda and the entrance.)
	var wing_strip := PackedVector2Array([r0 - sd * 45.0 - sn * 12.0, r0 + sd * 210.0 - sn * 12.0,
			r0 + sd * 210.0 + sn * 26.0, r0 + sd * 12.0 + sn * 26.0, r0 - sd * 45.0 + sn * 52.0])
	var office: Array = Geometry2D.intersect_polygons(poly, office_box)
	var wing: Array = Geometry2D.intersect_polygons(poly, wing_strip)
	var main: Array = [poly]
	for cut: PackedVector2Array in [office_box, wing_strip]:
		var next: Array = []
		for p: PackedVector2Array in main:
			next.append_array(Geometry2D.clip_polygons(p, cut))
		main = next
	var deck := poly
	var deck_area := -1.0
	# The main block: lit shop glass, pale panels with a row of windows, a grey cornice, the deck.
	for p: PackedVector2Array in main:
		if Geometry2D.is_polygon_clockwise(p) != Geometry2D.is_polygon_clockwise(poly):
			continue  # a hole piece
		_prism(p, g - 0.5, g + ARKADIA_SHOP, Color("#a9c6d2"), none, M_PAVILION)
		_prism(p, g + ARKADIA_SHOP, g + ARKADIA_TOP - 1.0, ARKADIA_PANEL, none, M_SKIN + S_PUNCHED / 16.0)
		_prism(p, g + ARKADIA_TOP - 1.0, g + ARKADIA_TOP, Color("#b9bab6"), ARKADIA_ROOF, M_STONE, M_STONE)
		_arkadia_parapet(p, g)
		if absf(_area(p)) > deck_area:
			deck_area = absf(_area(p))
			deck = p
	# The roof car park keeps off the entrance hall's glass gables.
	deck = _arkadia_cut(deck, _arkadia_sector(0.0, 66.0, ARKADIA_ARC.x - 8.0, ARKADIA_ARC.y + 8.0))
	for p: PackedVector2Array in office:
		_arkadia_office(p, g)
	for p: PackedVector2Array in wing:
		_arkadia_wing(p, g, r0, sd, sn)
	var c := _centre(poly)
	var sxx := 0.0
	var szz := 0.0
	var sxz := 0.0
	for q in poly:
		sxx += (q.x - c.x) * (q.x - c.x)
		szz += (q.y - c.y) * (q.y - c.y)
		sxz += (q.x - c.x) * (q.y - c.y)
	var axis := Vector2.from_angle(0.5 * atan2(2.0 * sxz, sxx - szz))
	var across := Vector2(-axis.y, axis.x)
	# The malls' glass roofs: three long skylights over the deck, each a row of glass pyramids.
	for k: int in [-1, 0, 1]:
		var m := c + across * (k * ARKADIA_STRIP_GAP)
		var strip := PackedVector2Array([m - axis * 200.0 - across * 5.0, m + axis * 200.0 - across * 5.0,
				m + axis * 200.0 + across * 5.0, m - axis * 200.0 + across * 5.0])
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(strip, deck):
			var inner := PackedVector2Array()
			var pc := _centre(piece)
			for q in piece:
				inner.append(q + (pc - q).normalized() * 6.0)  # off the deck's edge
			_prism(inner, g + ARKADIA_TOP, g + ARKADIA_TOP + 0.8, Color("#9fc0cf"), Color("#8fb3c4"), M_PAVILION, M_GLASS_ROOF)
			var ic := _centre(inner)
			var n_pyr := maxi(int(_span(inner, axis) / 18.0), 1)
			for i in n_pyr:
				var t := (i + 0.5) / n_pyr - 0.5
				var pm := ic + axis * (t * _span(inner, axis))
				if Geometry2D.is_point_in_polygon(pm, inner):
					var ring := PackedVector2Array([pm - axis * 7.0 - across * 3.6, pm + axis * 7.0 - across * 3.6,
							pm + axis * 7.0 + across * 3.6, pm - axis * 7.0 + across * 3.6])
					_mode = M_GLASS_ROOF
					_pyramid(ring, g + ARKADIA_TOP + 0.8, g + ARKADIA_TOP + 4.6, Color("#a7c8d6"))
	# The roof car park (the deck holds the city's biggest car park): cars in back-to-back rows.
	_mode = M_STONE
	_arkadia_cars(deck, g, c, axis, across)
	# Four stair and lift cores at the deck's corners and a mast of floodlights every 45 m.
	_arkadia_cores(deck, g, c)
	_arkadia_entrance(g)
	_arkadia_tower(g)
	_arkadia_rotunda(g)
	_arkadia_plaza(g)
	# The car stops at the mapped outline less the forecourt, the tower and the rotunda.
	_collide(_arkadia_cut(raw, court))
	_collide(_circle(ARKADIA_ROTUNDA, 13.0, 12))


## `poly` less `cut`, the biggest piece (the outline stays one ring).
func _arkadia_cut(poly: PackedVector2Array, cut: PackedVector2Array) -> PackedVector2Array:
	var best := poly
	var area := -1.0
	for p: PackedVector2Array in Geometry2D.clip_polygons(poly, cut):
		if Geometry2D.is_polygon_clockwise(p) != Geometry2D.is_polygon_clockwise(poly):
			continue
		var a := absf(_area(p))
		if a > area:
			area = a
			best = p
	return best


## The office wing (photos 3, 9): four storeys of dark glass to 18 m along Jana Pawła II, pale
## floor slabs showing at each storey, a dark cornice; its south face lined with cypresses (OSM).
func _arkadia_office(p: PackedVector2Array, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	_prism(p, g - 0.5, g + 18.0, ARKADIA_DARK, none, M_SKIN + S_DARK / 16.0)
	var out := Geometry2D.offset_polygon(p, 0.35, Geometry2D.JOIN_MITER)
	if out.size() == 1:
		for y: float in [4.6, 9.0, 13.4]:
			_prism(out[0], g + y, g + y + 0.35, Color("#c9ccce"), none, M_STONE)
		_prism(out[0], g + 18.0, g + 18.9, Color("#22292f"), Color("#5f6468"), M_STONE, M_STONE)


## The brick and render wing on the south-east face (photos 4, 8): shop glass, terracotta brick
## boxes between pale render pilasters every 22 m, a pale cornice at 13 m, under the main deck.
func _arkadia_wing(p: PackedVector2Array, g: float, r0: Vector2, sd: Vector2, sn: Vector2) -> void:
	var none := Color(0, 0, 0, 0)
	_prism(p, g - 0.5, g + 4.8, Color("#b7cbd2"), none, M_PAVILION)
	_prism(p, g + 4.8, g + 12.6, ARKADIA_BRICK, none, M_STONE)
	_prism(p, g + 12.6, g + 13.6, ARKADIA_RENDER, Color("#8d8f8e"), M_STONE, M_STONE)
	_arkadia_parapet_at(p, g + 13.6, 0.9)
	# On the street face's long edges: render pilasters every 22 m between the brick boxes, and
	# yellow awnings over the shop fronts nearest the rotunda.
	for i in p.size():
		var a := p[i]
		var b := p[(i + 1) % p.size()]
		var on := _out(p, a, b)
		var elen := a.distance_to(b)
		if on.dot(-sn) < 0.9 or elen < 12.0:
			continue
		var e := (b - a) / elen
		var s := 8.0
		while s < elen - 4.0:
			var at := a + e * s + on * 0.35
			_prism(PackedVector2Array([at - e * 2.2, at + e * 2.2, at + e * 2.2 - on * 1.2, at - e * 2.2 - on * 1.2]),
					g, g + 13.9, ARKADIA_RENDER, ARKADIA_RENDER, M_STONE, M_STONE)
			var mid := a + e * (s + 11.0)
			var dr := mid.distance_to(ARKADIA_ROTUNDA)
			if dr > 15.0 and dr < 60.0 and s + 15.0 < elen:
				_arkadia_awning(mid + on * 0.2, e, on, 7.6, g + 4.2)
			s += 22.0


## A sloped café awning: `w` wide along `along`, 3 m out along `out` from `at`, dropping 0.9 m.
func _arkadia_awning(at: Vector2, along: Vector2, out: Vector2, w: float, y: float) -> void:
	var a := at - along * (w * 0.5)
	var b := at + along * (w * 0.5)
	var c := b + out * 3.0
	var d := a + out * 3.0
	var up := Vector3(out.x * 0.3, 1.0, out.y * 0.3).normalized()
	_mode = M_STONE
	_quad(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y - 0.9, c.y), Vector3(d.x, y - 0.9, d.y), up, ARKADIA_YELLOW)
	_quad(Vector3(a.x, y - 0.05, a.y), Vector3(b.x, y - 0.05, b.y), Vector3(c.x, y - 0.95, c.y), Vector3(d.x, y - 0.95, d.y), -up, ARKADIA_YELLOW.darkened(0.25))
	_quad(Vector3(d.x, y - 0.9, d.y), Vector3(c.x, y - 0.9, c.y), Vector3(c.x, y - 1.3, c.y), Vector3(d.x, y - 1.3, d.y),
			Vector3(out.x, 0.0, out.y), ARKADIA_YELLOW.darkened(0.08))


## A ring sector round the fountain: radii r0..r1, angles d0..d1 (degrees, plan).
func _arkadia_sector(r0: float, r1: float, d0: float, d1: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(int((d1 - d0) / 6.0), 2)
	for i in n + 1:
		out.append(ARKADIA_FOUNTAIN + Vector2.from_angle(deg_to_rad(lerpf(d0, d1, float(i) / n))) * r1)
	if r0 <= 0.01:
		out.append(ARKADIA_FOUNTAIN)
		return out
	for i in n + 1:
		out.append(ARKADIA_FOUNTAIN + Vector2.from_angle(deg_to_rad(lerpf(d1, d0, float(i) / n))) * r0)
	return out


## The main entrance (photos 4, 6, 10): a curved glass wall round the plaza between four stone
## piers, three bays, each with a low canopy (planted on top) at 5 m and a deep pale cornice at
## 19 m; the name over the middle bay; behind it six glass gables fanning back over the mall.
func _arkadia_entrance(g: float) -> void:
	var r := ARKADIA_R
	var d0 := ARKADIA_ARC.x
	var d1 := ARKADIA_ARC.y
	_prism(_arkadia_sector(r - 0.4, r + 2.0, d0, d1), g - 0.5, g + 20.0, Color("#a3c2cf"), Color("#8d9090"), M_PAVILION, M_STONE)
	var bay := (d1 - d0) / 3.0
	for k in 4:
		var dk := d0 + k * bay
		var w := rad_to_deg(1.5 / r)
		_prism(_arkadia_sector(r - 1.2, r + 2.4, dk - w, dk + w), g - 0.5, g + 21.6, ARKADIA_STONE, ARKADIA_STONE.darkened(0.1), M_STONE, M_STONE)
	for k in 3:
		var a0 := d0 + k * bay + 3.5
		var a1 := d0 + (k + 1) * bay - 3.5
		_prism(_arkadia_sector(r - 4.6, r, a0, a1), g + 5.0, g + 5.6, Color("#3a3f44"), Color("#6f9a4a"), M_STONE, M_STONE)
		_prism(_arkadia_sector(r - 5.0, r, a0, a1), g + 18.4, g + 19.6, Color("#ece9e1"), Color("#c9c7c0"), M_STONE, M_STONE)
	var mid := Vector2.from_angle(deg_to_rad((d0 + d1) * 0.5))
	var at := ARKADIA_FOUNTAIN + mid * (r - 0.15)
	# (Two words: the neon atlas holds about eleven letters a word.)
	signs.append(["ZACHODNIE", Vector3(at.x, g + 14.0, at.y), Vector3(-mid.x, 0.0, -mid.y), 0.62, ARKADIA_RED])
	signs.append(["POLE", Vector3(at.x, g + 12.4, at.y), Vector3(-mid.x, 0.0, -mid.y), 0.62, ARKADIA_RED])
	signs.append(["ARKADKA", Vector3(at.x, g + 11.0, at.y), Vector3(-mid.x, 0.0, -mid.y), 0.42, ARKADIA_WHITE])
	# The glass gables over the entrance hall, radial like a fan.
	for k in 6:
		var d := Vector2.from_angle(deg_to_rad(d0 + 10.0 + k * (d1 - d0 - 20.0) / 5.0))
		_arkadia_gable(ARKADIA_FOUNTAIN + d * (r + 3.0), ARKADIA_FOUNTAIN + d * (r + 34.0), Vector2(-d.y, d.x), 3.0, g + ARKADIA_TOP, 4.2)


## A pitched glass roof: ridge from p0 to p1 at y + h, eaves `hw` out each side along `side`.
func _arkadia_gable(p0: Vector2, p1: Vector2, side: Vector2, hw: float, y: float, h: float) -> void:
	var l0 := p0 - side * hw
	var r0 := p0 + side * hw
	var l1 := p1 - side * hw
	var r1 := p1 + side * hw
	var glass := Color("#a7c8d6")
	_mode = M_GLASS_ROOF
	var nl := Vector3(-side.x, 1.4, -side.y).normalized()
	var nr := Vector3(side.x, 1.4, side.y).normalized()
	_quad(Vector3(l0.x, y, l0.y), Vector3(l1.x, y, l1.y), Vector3(p1.x, y + h, p1.y), Vector3(p0.x, y + h, p0.y), nl, glass)
	_quad(Vector3(r0.x, y, r0.y), Vector3(p0.x, y + h, p0.y), Vector3(p1.x, y + h, p1.y), Vector3(r1.x, y, r1.y), nr, glass.darkened(0.08))
	_mode = M_STONE
	var f := (p0 - p1).normalized()
	_tri(Vector3(l0.x, y, l0.y), Vector3(r0.x, y, r0.y), Vector3(p0.x, y + h, p0.y), Vector3(f.x, 0.0, f.y), Color("#ece9e1"),
			Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_tri(Vector3(l1.x, y, l1.y), Vector3(r1.x, y, r1.y), Vector3(p1.x, y + h, p1.y), Vector3(-f.x, 0.0, -f.y), Color("#ece9e1"),
			Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## The sign tower (photos 2, 4, 10): a pale rendered base with the big screen, a shaft of grey
## corner piers round dark louvres carrying the shops' logo panels, and the sign box on top with
## ZACHODNIE POLE over ARKADKA on all four faces, 49 m up. Square to the office wing.
func _arkadia_tower(g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var t := ARKADIA_TOWER
	_o = t
	_a = Vector2.RIGHT
	_b = Vector2.DOWN
	_lbox(0.0, 0.0, 6.0, 6.0, g - 0.5, g + 14.0, Color("#c8c9c6"), M_STONE, Color("#a9aba8"))
	_lbox(0.0, 0.0, 5.3, 5.3, g + 14.0, g + 41.0, Color("#30353a"), M_SKIN + S_FINS / 16.0, Color("#555a5e"))
	for cu: float in [-5.3, 5.3]:
		for cv: float in [-5.3, 5.3]:
			_lbox(cu, cv, 0.75, 0.75, g + 14.0, g + 41.0, Color("#9a9da0"), M_STONE, Color("#8a8d90"))
	for cu: float in [-5.0, 5.0]:
		for cv: float in [-5.0, 5.0]:
			_lbox(cu, cv, 0.25, 0.25, g + 41.0, g + 42.6, Color("#6d7174"), M_STONE)
	_lbox(0.0, 0.0, 7.6, 7.6, g + 42.6, g + 49.4, Color("#d7d8d6"), M_STONE, Color("#bfc1c0"))
	for d: Vector2 in [Vector2(0.0, 1.0), Vector2(1.0, 0.0), Vector2(0.0, -1.0), Vector2(-1.0, 0.0)]:
		var at := t + d * 7.7
		var n3 := Vector3(d.x, 0.0, d.y)
		signs.append(["ZACHODNIE", Vector3(at.x, g + 46.3, at.y), n3, 0.72, ARKADIA_RED])
		signs.append(["POLE", Vector3(at.x, g + 44.6, at.y), n3, 0.72, ARKADIA_RED])
		signs.append(["ARKADKA", Vector3(at.x, g + 43.2, at.y), n3, 0.5, ARKADIA_WHITE])
	# Logo panels on the plaza (south) and entrance (east) faces: KARFUREK (the hypermarket's
	# parody), then where the real tower has the DIY store's green roof and the cinema's name (F's
	# night photos, 2026-11-21), the GeoBent mark over its name and the NOSE AGENCY's blue word.
	for d: Vector2 in [Vector2(0.0, 1.0), Vector2(1.0, 0.0)]:
		var n3 := Vector3(d.x, 0.0, d.y)
		var side := Vector2(-d.y, d.x)
		var at := t + d * 5.6
		var pan := PackedVector2Array([at - side * 4.4, at + side * 4.4, at + side * 4.4 + d * 0.3, at - side * 4.4 + d * 0.3])
		_prism(pan, g + 33.0, g + 37.6, Color("#f4f4f2"), Color("#f4f4f2"), M_STONE, M_STONE)
		var lo := at + d * 0.32
		signs.append(["KARFUREK", Vector3(lo.x, g + 34.6, lo.y), n3, 0.55, Color(0.15, 0.35, 1.0)])
		_arkadia_geobent(at + d * 0.35, side, n3, g + 29.2)
		signs.append(["GEOBENT", Vector3(lo.x, g + 25.4, lo.y), n3, 0.5, SpireMotion.GEO_BLUE])
		signs.append(["NOSE AGENCY", Vector3(lo.x, g + 20.4, lo.y), n3, 0.5, Color(0.3, 0.55, 1.0)])
	# The big screen on the base's plaza face: a dark box the screen hangs on; the screen itself,
	# the game's AROUND WARSAW promo, is arkadia_screen.gd (its own shader, built at runtime).
	# On the plaza's own ground (the mall's `g` is the lowest point under its whole outline, metres
	# below the plaza), the ground arkadia_screen.gd stands the screen on.
	var sc := t + Vector2(1.2, 6.2)
	var gs: float = map.ground_height(sc.x, sc.y + 0.65)
	_prism(PackedVector2Array([sc + Vector2(-6.7, 0.0), sc + Vector2(6.7, 0.0), sc + Vector2(6.7, 0.6), sc + Vector2(-6.7, 0.6)]),
			gs + 4.4, gs + 12.9, Color("#1c1d24"), Color("#333333"), M_STONE, M_STONE)
	_collide(_rect(0.0, 0.0, 6.0, 6.0))


## The GeoBent mark in lit panels (spire_motion.gd's LOGO, F's screenshot of geobent.pl): a flat
## open diamond, orange on its upper left and navy on its right, over an orange chevron and a navy
## one, the three layers of a stack; `at` its middle, `side` along the face, 6 m across.
func _arkadia_geobent(at: Vector2, side: Vector2, n3: Vector3, y: float) -> void:
	var orange := SpireMotion.GEO_ORANGE
	var navy := SpireMotion.GEO_BLUE
	var none := Vector2(-1, -1)
	_mode = M_LAMP
	var pt := func(u: float, v: float) -> Vector3:
		var q := at + side * u
		return Vector3(q.x, y + v, q.y)
	# The diamond: a top half (orange left, navy right) and the front half in navy.
	_tri(pt.call(-3.0, 0.0), pt.call(0.0, 0.0), pt.call(0.0, 1.6), n3, orange, none, none, none, -1.0, false)
	_tri(pt.call(0.0, 0.0), pt.call(3.0, 0.0), pt.call(0.0, 1.6), n3, navy, none, none, none, -1.0, false)
	_tri(pt.call(-3.0, 0.0), pt.call(0.0, -1.2), pt.call(0.0, 0.0), n3, navy, none, none, none, -1.0, false)
	_tri(pt.call(0.0, -1.2), pt.call(3.0, 0.0), pt.call(0.0, 0.0), n3, navy.darkened(0.2), none, none, none, -1.0, false)
	# The two chevrons under it, each a band 0.4 m thick.
	for k in 2:
		var v0 := -1.7 - k * 0.75
		var col := orange if k == 0 else navy
		_tri(pt.call(-3.0, v0 + 1.2), pt.call(0.0, v0), pt.call(-3.0, v0 + 0.8), n3, col, none, none, none, -1.0, false)
		_tri(pt.call(-3.0, v0 + 0.8), pt.call(0.0, v0), pt.call(0.0, v0 - 0.4), n3, col, none, none, none, -1.0, false)
		_tri(pt.call(0.0, v0), pt.call(3.0, v0 + 1.2), pt.call(3.0, v0 + 0.8), n3, col, none, none, none, -1.0, false)
		_tri(pt.call(0.0, v0), pt.call(3.0, v0 + 0.8), pt.call(0.0, v0 - 0.4), n3, col, none, none, none, -1.0, false)


## The rotunda on the brick wing's corner (photos 4, 8): a glass ground floor under yellow café
## awnings, a rendered drum with windows, a pale cornice ring and a parapet round its roof plant.
func _arkadia_rotunda(g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var r := ARKADIA_ROTUNDA
	_prism(_circle(r, 13.0, 20), g - 0.5, g + 4.6, Color("#b7cbd2"), none, M_PAVILION)
	_prism(_circle(r, 13.0, 20), g + 4.6, g + 12.4, ARKADIA_RENDER, none, M_SKIN + S_PUNCHED / 16.0)
	_prism(_circle(r, 13.7, 20), g + 12.4, g + 13.4, Color("#ece6d8"), Color("#9a9c9b"), M_STONE, M_STONE)
	_arkadia_parapet_at(_circle(r, 13.6, 20), g + 13.4, 1.0)
	_prism(_circle(r, 6.0, 12), g + 13.4, g + 15.6, Color("#c9cbc9"), Color("#b0b2b1"), M_STONE, M_STONE)
	# Awnings on the faces towards the plaza and the street (west round to south-east).
	for k in 6:
		var ang := deg_to_rad(40.0 + k * 30.0)
		var d := Vector2(cos(ang), sin(ang))
		_arkadia_awning(r + d * 13.05, Vector2(-d.y, d.x), d, 6.4, g + 4.3)


## The plaza (photos 4, 5): jets in the paved fountain and the big letter sign on its plinth by
## the lawns (ZACHODNIE POLE in red over ARKADKA in white).
func _arkadia_plaza(g: float) -> void:
	# Fountain jets: a ring of eight and one in the middle.
	var f := ARKADIA_FOUNTAIN
	var fg: float = map.terrain_height(f.x, f.y)
	for k in 9:
		var p := f if k == 8 else f + Vector2.from_angle(TAU * k / 8.0) * 6.5
		_prism(_circle(p, 0.3, 6), fg, fg + (3.2 if k == 8 else 1.8), Color("#e6f3fa"), Color("#f4fbff"), M_STONE, M_STONE)
	# The letter sign: a grey plinth square to the way to the rondo.
	var s := ARKADIA_SIGN
	var sg: float = map.terrain_height(s.x, s.y)
	var face := (Vector2(-2850.0, -2295.0) - s).normalized()
	var side := Vector2(-face.y, face.x)
	var plinth := PackedVector2Array([s - side * 5.2 - face * 1.0, s + side * 5.2 - face * 1.0,
			s + side * 5.2 + face * 1.0, s - side * 5.2 + face * 1.0])
	_prism(plinth, sg - 0.3, sg + 1.9, Color("#5b5f63"), Color("#6a6e72"), M_STONE, M_STONE)
	var right := Vector2(face.y, -face.x)  # neon_signs.gd place(): the word's left-to-right
	var w1 := s + right * -1.6 + face * 0.2
	var w2 := s + right * 3.05 + face * 0.2
	signs.append(["ZACHODNIE", Vector3(w1.x, sg + 1.9, w1.y), Vector3(face.x, 0.0, face.y), 0.48, ARKADIA_RED])
	signs.append(["POLE", Vector3(w2.x, sg + 1.9, w2.y), Vector3(face.x, 0.0, face.y), 0.48, ARKADIA_RED])
	var low := s + face * 1.05
	signs.append(["ARKADKA", Vector3(low.x, sg + 0.35, low.y), Vector3(face.x, 0.0, face.y), 0.34, ARKADIA_WHITE])
	_collide(plinth)


## Arkadia's width of a plan polygon along `dir`.
func _span(poly: PackedVector2Array, dir: Vector2) -> float:
	var lo := INF
	var hi := -INF
	for q in poly:
		var d := q.dot(dir)
		lo = minf(lo, d)
		hi = maxf(hi, d)
	return hi - lo


## The roof deck's parapet: a 1.1 m wall round it, seen from the street and from above.
func _arkadia_parapet(poly: PackedVector2Array, g: float) -> void:
	var inset := Geometry2D.offset_polygon(poly, -0.4)
	if inset.size() != 1:
		return
	var inner: PackedVector2Array = inset[0]
	var rev := PackedVector2Array(inner)
	rev.reverse()
	_arkadia_ring(poly, inner, rev, g + ARKADIA_TOP, 1.1)


## A parapet `h` high round `poly` standing on height `y` (the lower wings' roofs).
func _arkadia_parapet_at(poly: PackedVector2Array, y: float, h: float) -> void:
	var inset := Geometry2D.offset_polygon(poly, -0.4)
	if inset.size() != 1:
		return
	var inner: PackedVector2Array = inset[0]
	var rev := PackedVector2Array(inner)
	rev.reverse()
	_arkadia_ring(poly, inner, rev, y, h)


func _arkadia_ring(poly: PackedVector2Array, inner: PackedVector2Array, rev: PackedVector2Array, y: float, h: float) -> void:
	_prism(poly, y, y + h, Color("#e9e4d8"), Color(0, 0, 0, 0), M_STONE)
	_prism(rev, y, y + h, Color("#d6d1c4"), Color(0, 0, 0, 0), M_STONE)
	_cap_holes(poly, [inner], y + h, Color("#f2eee4"))


## Parked cars on the deck: back-to-back rows of bays 2.7 m wide, 4.6 m long, a 5.9 m drive aisle
## between each pair, a seeded half of the bays filled in muted colours. Straight into the mesh
## (not the roof grid): `_prism` would test every car against all walls.
func _arkadia_cars(poly: PackedVector2Array, g: float, c: Vector2, axis: Vector2, across: Vector2) -> void:
	var inset := Geometry2D.offset_polygon(poly, -5.0)
	if inset.is_empty():
		return
	var deck: PackedVector2Array = inset[0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2004
	var paints: Array[Color] = [Color("#c9ccd0"), Color("#2f3438"), Color("#e6e6e2"), Color("#6c7a8a"), Color("#8f2f2f"),
			Color("#394a63"), Color("#a9a49a"), Color("#4d5a4a")]
	_no_roof = true
	var y := g + ARKADIA_TOP
	var made := 0
	var s := -ARKADIA_DECK_REACH
	while s < ARKADIA_DECK_REACH and made < ARKADIA_CARS_MAX:
		var blk := -ARKADIA_DECK_REACH
		while blk < ARKADIA_DECK_REACH:
			for row in 2:
				var v := blk + 2.4 + row * 4.8
				var near_strip := false
				for k: int in [-1, 0, 1]:
					if absf(v - k * ARKADIA_STRIP_GAP) < 9.0:
						near_strip = true
				var p := c + axis * s + across * v
				if not near_strip and rng.randf() < 0.55 and Geometry2D.is_point_in_polygon(p, deck) \
						and p.distance_to(ARKADIA_TOWER) > 16.0 and made < ARKADIA_CARS_MAX:
					_car(p, axis, across, y, paints[rng.randi() % paints.size()])
					made += 1
			blk += 15.5
		s += 2.7
	_no_roof = false


## A parked car: a 1.8 x 4.2 m box, 1.45 m high, its long side along `across`, cabin a darker lid.
func _car(p: Vector2, axis: Vector2, across: Vector2, y: float, col: Color) -> void:
	var hw := axis * 0.9
	var hl := across * 2.1
	var q := [p - hw - hl, p + hw - hl, p + hw + hl, p - hw + hl]
	for i in 4:
		var a: Vector2 = q[i]
		var b: Vector2 = q[(i + 1) % 4]
		var mid := (a + b) * 0.5
		var n2 := (mid - p).normalized()
		_quad(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(b.x, y + 1.45, b.y), Vector3(a.x, y + 1.45, a.y),
				Vector3(n2.x, 0.0, n2.y), col)
	_quad(Vector3(q[0].x, y + 1.45, q[0].y), Vector3(q[1].x, y + 1.45, q[1].y), Vector3(q[2].x, y + 1.45, q[2].y),
			Vector3(q[3].x, y + 1.45, q[3].y), Vector3.UP, col.darkened(0.25))


## Four cores (stair and lift boxes, 8 x 8 m, 3.6 m over the deck) pulled in from the deck's extreme
## corners, and floodlight masts (6.5 m, a lit head) on a 45 m grid along the deck.
func _arkadia_cores(poly: PackedVector2Array, g: float, c: Vector2) -> void:
	var inset := Geometry2D.offset_polygon(poly, -14.0)
	if inset.is_empty():
		return
	var deck: PackedVector2Array = inset[0]
	var y := g + ARKADIA_TOP
	var picks: Array[Vector2] = []
	for dir: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var best := deck[0]
		for q in deck:
			if q.dot(dir) > best.dot(dir):
				best = q
		picks.append(best)
	for p in picks:
		if p.distance_to(ARKADIA_TOWER) > 24.0:
			_prism(PackedVector2Array([p + Vector2(-4, -4), p + Vector2(4, -4), p + Vector2(4, 4), p + Vector2(-4, 4)]),
					y, y + 3.6, Color("#e2ddd0"), Color("#9b9d9e"), M_STONE, M_STONE)
	var gx := floorf(_span(deck, Vector2.RIGHT) / 45.0)
	var lo := Vector2(INF, INF)
	for q in deck:
		lo = lo.min(q)
	_no_roof = true
	var n := 0
	for ix in int(gx) + 1:
		for iz in int(floorf(_span(deck, Vector2.DOWN) / 45.0)) + 1:
			var p := lo + Vector2(ix * 45.0, iz * 45.0)
			if Geometry2D.is_point_in_polygon(p, deck) and p.distance_to(ARKADIA_TOWER) > 20.0 and n < 40:
				_prism(_circle(p, 0.14, 4), y, y + 6.5, Color("#8d9296"), Color("#8d9296"), M_STONE, M_STONE)
				_prism(PackedVector2Array([p + Vector2(-0.7, -0.25), p + Vector2(0.7, -0.25), p + Vector2(0.7, 0.25), p + Vector2(-0.7, 0.25)]),
						y + 6.5, y + 6.8, Color("#fff4d6"), Color("#fff4d6"), M_LAMP, M_LAMP)
				n += 1
	_no_roof = false


# --- Prosta 32, Prosta 28 and Łucka City (F's photos, 2026-11-06) ---------------------------

## Prosta 32 (2012; spec docs/landmarks/specs/prosta32.md), from F's photos: a 74 m office tower
## of deep blue glass whose Prosta front wears a white concrete diamond lattice. The lattice's
## members swell out from the glass and back again up the height, so the face's edge waves in
## profile; its lowest diamonds open as arches onto the pavement. MARZYPOL (the developer's red
## roof letters as a parody) stands on the roof edge over the lattice and over the east face; a
## four-storey glass podium joins it on the east. The lattice is triangles in the one landmark
## mesh: three faces a member (front and two sides), no new draw call.
const P32_H := 74.0
const P32_GLASS := Color("#3d6c9c")
const P32_ROOF := Color("#8e979e")
const P32_LATTICE := Color("#e9e7e1")
const P32_PODIUM := Color("#6f8ea6")
const P32_RED := Color(0.92, 0.12, 0.12)
const P32_DIAMONDS := 7     # whole diamonds across the front (photos: seven, half ones at the ends)
const P32_ROW := 4.6        # one diamond's height (sixteen up the 74 m)
const P32_MEMBER := 1.0     # a member's width on the face (white about half the front, as the photos)
const P32_WAVE := 26.0      # the lattice swells out and back every 26 m of height


func _find_prosta32() -> void:
	var outline := _landmark("Prosta Tower")
	if outline.size() < 3:
		return
	var parts := _parts_in(outline, func(b: Dictionary) -> bool: return float(b["h"]) >= 10.0)
	_add_site("prosta32", [outline])
	if not sites.is_empty() and sites[-1]["key"] == "prosta32":
		sites[-1]["parts"] = parts
		sites[-1]["ring"] = outline


func _build_prosta32(site: Dictionary) -> void:
	var tower := PackedVector2Array()
	var low: Array[PackedVector2Array] = []
	for bld: Dictionary in site["parts"]:
		var q := _pts(bld["p"])
		if float(bld["h"]) >= 40.0:
			tower = q
		else:
			low.append(q)
	if tower.size() < 3:
		return
	_g = _ground_under(site["ring"])
	var g := _g
	# The podium: four storeys of glass in floor bands, a plain grey roof.
	for q in low:
		_prism(q, g - 0.5, g + 14.2, P32_PODIUM, P32_ROOF, M_SKIN + float(S_BANDS) / 16.0, M_STONE)
		_parapet(q, g + 14.2, 0.8, P32_ROOF.lightened(0.2))
	# The tower: blue mirror glass all round, a grey roof with a parapet and a plant box.
	_prism(tower, g - 0.5, g + P32_H, P32_GLASS, P32_ROOF, M_SKIN + float(S_MIRROR) / 16.0, M_STONE)
	_parapet(tower, g + P32_H, 1.1, P32_ROOF.lightened(0.25))
	_no_roof = true
	var c := _centre(tower)
	_prism(_square(c + Vector2(-2.0, -1.5), 3.0), g + P32_H, g + P32_H + 2.6, Color("#6c7277"), Color("#7a8085"), M_STONE, M_STONE)
	_no_roof = false
	# The front: the tower's edge that faces Prosta (south, +z) the most, by its length.
	var fa := Vector2.ZERO
	var fb := Vector2.ZERO
	var best := -INF
	for i in tower.size():
		var a := tower[i]
		var b := tower[(i + 1) % tower.size()]
		var score := _out(tower, a, b).y * a.distance_to(b)
		if score > best:
			best = score
			fa = a
			fb = b
	var out := _out(tower, fa, fb)
	_p32_lattice(fa, fb, out, g, g + P32_H)
	# MARZYPOL on the roof edge: over the lattice (south), and over the east face.
	var mid := (fa + fb) * 0.5 + out * 0.4
	signs.append(["MARZYPOL", Vector3(mid.x, g + P32_H + 0.6, mid.y), Vector3(out.x, 0.0, out.y), 1.4, P32_RED])
	var ea := Vector2.ZERO
	var eb := Vector2.ZERO
	best = -INF
	for i in tower.size():
		var a := tower[i]
		var b := tower[(i + 1) % tower.size()]
		var score := _out(tower, a, b).x * a.distance_to(b)
		if score > best:
			best = score
			ea = a
			eb = b
	var eo := _out(tower, ea, eb)
	var em := (ea + eb) * 0.5 + eo * 0.4
	signs.append(["MARZYPOL", Vector3(em.x, g + P32_H + 0.6, em.y), Vector3(eo.x, 0.0, eo.y), 0.95, P32_RED])
	for q in low:
		_collide(q)
		pocket_rings.append(q)
	_collide(tower)
	pocket_rings.append(tower)


## How far the lattice stands out of the glass at height h over the ground (0.45 to 1.3 m).
func _p32_proud(h: float) -> float:
	return 0.45 + 0.85 * (0.5 + 0.5 * sin(TAU * h / P32_WAVE + 0.6))


## The diamond lattice over the front a→b: nodes every half-diamond across and up, two families
## of diagonal members between them (the "\" family 6 cm proud of the "/", so their crossings
## don't z-fight), a white band along the top.
func _p32_lattice(a: Vector2, b: Vector2, out: Vector2, y0: float, y1: float) -> void:
	var length := a.distance_to(b)
	if length < 4.0:
		return
	var e := (b - a) / length
	var cols := 2 * P32_DIAMONDS
	var hw := length / float(cols)
	var hh := P32_ROW * 0.5
	var rows := floori((y1 - y0 - 0.8) / hh)
	var keep := _mode
	_mode = M_STONE
	for j in rows:
		for i in range(0, cols + 1):
			if (i + j) % 2 != 0:
				continue
			for s: int in [-1, 1]:
				var k := i + s
				if k < 0 or k > cols:
					continue
				var lift := 0.06 if s < 0 else 0.0
				_p32_member(a + e * (i * hw), j * hh, a + e * (k * hw), (j + 1) * hh, e, out, y0, lift)
	# The top band: the lattice's head, over its last row of nodes.
	var top_h := rows * hh
	var p := _p32_proud(top_h) + 0.06
	var ta := a + out * p
	var tb := b + out * p
	_wall(ta, tb, y0 + top_h - 0.5, y1, out, P32_LATTICE)
	_mode = keep


## One member from (p, h0) to (q, h1) on the face (plan points on the glass, heights over y0):
## its front `lift` metres further out, its two sides back to the glass.
func _p32_member(p: Vector2, h0: float, q: Vector2, h1: float, e: Vector2, out: Vector2, y0: float, lift: float) -> void:
	var o3 := Vector3(out.x, 0.0, out.y)
	var e3 := Vector3(e.x, 0.0, e.y)
	var d2 := Vector2((q - p).dot(e), h1 - h0).normalized()
	var w3 := (e3 * -d2.y + Vector3.UP * d2.x) * (P32_MEMBER * 0.5)
	var pp := _p32_proud(h0) + lift
	var pq := _p32_proud(h1) + lift
	var fp := Vector3(p.x, y0 + h0, p.y) + o3 * pp
	var fq := Vector3(q.x, y0 + h1, q.y) + o3 * pq
	var bp := Vector3(p.x, y0 + h0, p.y) + o3 * 0.05
	var bq := Vector3(q.x, y0 + h1, q.y) + o3 * 0.05
	if h0 <= 0.0:
		# A foot on the pavement: no arm under the ground.
		fp.y = y0 - 0.3
		bp.y = y0 - 0.3
	var front := (fq - fp).cross(w3).normalized()
	if front.dot(o3) < 0.0:
		front = -front
	_quad(fp - w3, fq - w3, fq + w3, fp + w3, front, P32_LATTICE)
	for sd: float in [-1.0, 1.0]:
		var n := w3.normalized() * sd
		_quad(fp + w3 * sd, fq + w3 * sd, bq + w3 * sd, bp + w3 * sd, n, P32_LATTICE.darkened(0.08))


## Łucka City (Łucka 15; spec docs/landmarks/specs/lucka.md), from F's photos: a white residential
## block stepping up from Łucka and from Prosta to its 100 m tower, whose top five storeys are clad
## dark grey; white cladding with punched windows in bands all over; on the roof a
## blue board with INTERBRUK (the printer's sign as a parody: paving setts instead of print)
## between two red lattice masts.
const LUCKA_WHITE := Color("#e7e7e3")
const LUCKA_GREY := Color("#62676b")
const LUCKA_ROOF := Color("#c4c6c6")
const LUCKA_BLUE := Color("#1d4b96")
const LUCKA_TOWER_H := 100.0   # the tower's roof (LoD2 97.6 m, OSM 103.3 with the sign)
const LUCKA_GREY_FROM := 83.0  # the dark top storeys (photos: about the top sixth)


func _find_lucka() -> void:
	var outline := _landmark("Łucka City")
	if outline.size() < 3:
		return
	var parts := _parts_in(outline, func(b: Dictionary) -> bool: return float(b["h"]) >= 20.0)
	_add_site("lucka", [outline])
	if not sites.is_empty() and sites[-1]["key"] == "lucka":
		sites[-1]["parts"] = parts
		sites[-1]["ring"] = outline


func _build_lucka(site: Dictionary) -> void:
	_g = _ground_under(site["ring"])
	var g := _g
	var none := Color(0, 0, 0, 0)
	for bld: Dictionary in site["parts"]:
		var q := _pts(bld["p"])
		var h := float(bld["h"])
		if h >= 95.0:
			_prism(q, g - 0.5, g + LUCKA_GREY_FROM, LUCKA_WHITE, none, M_SKIN + float(S_PUNCHED) / 16.0)
			_prism(q, g + LUCKA_GREY_FROM, g + LUCKA_TOWER_H, LUCKA_GREY, LUCKA_ROOF, M_SKIN + float(S_PUNCHED) / 16.0, M_STONE)
			_parapet(q, g + LUCKA_TOWER_H, 1.0, LUCKA_GREY.lightened(0.15))
			_lucka_sign(q, g + LUCKA_TOWER_H)
		else:
			_prism(q, g - 0.5, g + h, LUCKA_WHITE, LUCKA_ROOF, M_SKIN + float(S_PUNCHED) / 16.0, M_STONE)
			_parapet(q, g + h, 1.0, LUCKA_WHITE)
		_collide(q)
		pocket_rings.append(q)


## The roof sign: the tower's long axis by its outline's spread; the board stands across it on
## steel legs, INTERBRUK on both faces (south to Prosta, north to Łucka), a red-and-white lattice
## mast at each end.
func _lucka_sign(q: PackedVector2Array, top: float) -> void:
	var c := _centre(q)
	var sxx := 0.0
	var szz := 0.0
	var sxz := 0.0
	for p in q:
		var d := p - c
		sxx += d.x * d.x
		szz += d.y * d.y
		sxz += d.x * d.y
	var ang := 0.5 * atan2(2.0 * sxz, sxx - szz)
	var long := Vector2(cos(ang), sin(ang))
	var across := Vector2(-long.y, long.x)
	_no_roof = true
	var half := 7.0
	for s: float in [-1.0, 1.0]:
		var leg := c + across * (half - 1.0) * s
		_prism(_square(leg, 0.2), top, top + 1.2, Color("#4a4f54"), Color("#4a4f54"), M_STONE, M_STONE)
	var board := PackedVector2Array([c - across * half - long * 0.3, c + across * half - long * 0.3,
			c + across * half + long * 0.3, c - across * half + long * 0.3])
	_prism(board, top + 1.2, top + 4.4, LUCKA_BLUE, LUCKA_BLUE.lightened(0.1), M_STONE, M_STONE)
	for s: float in [-1.0, 1.0]:
		var face := c + long * (0.3 * s)
		signs.append(["INTERBRUK", Vector3(face.x, top + 1.7, face.y), Vector3(long.x * s, 0.0, long.y * s), 0.95, Color(1.0, 1.0, 1.0)])
		# The masts: red with white bands, as the photos' two lattice masts either side.
		var m := c + across * (half + 2.5) * s
		for k in 4:
			var col := Color("#c8312b") if k % 2 == 0 else Color("#eeeeea")
			_beam(Vector3(m.x, top + k * 3.0, m.y), Vector3(m.x, top + (k + 1) * 3.0, m.y), 0.5, col, false)
	_no_roof = false


## Prosta 28 (finished 2025; spec docs/landmarks/specs/prosta28.md), from F's photos: a green
## glass office tower on Prosta, about 92 m to its crown (OSM still has it at 80 m), standing on a
## double-height base of dark steel columns with silver X braces; a grey stone-clad stack on its
## west end; its top stepping down to the north in terraces planted with trees, under a pale stone
## crown; PROSTO (a tenant's small red logo as a parody) high on the east face; a 41 m green glass
## annex towards Łucka with stepped planted terraces, and 24 m wings.
const P28_BOX := Rect2(-2410.0, 160.0, 65.0, 105.0)
const P28_GLASS := Color("#5b8a82")
const P28_ANNEX := Color("#4f7c78")
const P28_STONE := Color("#8f8a84")
const P28_CROWN := Color("#c9bca5")
const P28_STEEL := Color("#2c3034")
const P28_BRACE := Color("#c4c8cc")
const P28_LOBBY := Color("#33424a")
const P28_ROOF := Color("#8c9294")
const P28_GREEN := Color("#5f8f45")
const P28_LEAF: Array[Color] = [Color("#6f9a45"), Color("#5f8a3c"), Color("#86a94e")]
const P28_BASE := 13.2       # the X-braced base (OSM's tower part starts there)
const P28_LOW := 82.0        # the north terrace's level (OSM 73.6, scaled to the photos)
const P28_HIGH := 89.0       # the main glass top (OSM 80.2)
const P28_TOP := 93.5        # the stone crown
const P28_STACK := [76.0, 72.0]  # the stone stack's inner and outer steps
const P28_ANNEX_H := 40.6


func _find_prosta28() -> void:
	var zone: Array = []
	var parts: Array = []
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() >= 3 and P28_BOX.has_point(_centre(q)) and float(bld["h"]) >= 3.0:
			zone.append(q)
			parts.append(bld)
	_add_site("prosta28", zone)
	if not sites.is_empty() and sites[-1]["key"] == "prosta28":
		sites[-1]["parts"] = parts


func _p28_area(q: PackedVector2Array) -> float:
	var s := 0.0
	for i in q.size():
		s += q[i].cross(q[(i + 1) % q.size()])
	return absf(s) * 0.5


func _build_prosta28(site: Dictionary) -> void:
	var tower := PackedVector2Array()
	var upper := PackedVector2Array()
	var annex := PackedVector2Array()
	var wings: Array[PackedVector2Array] = []
	for bld: Dictionary in site["parts"]:
		var q := _pts(bld["p"])
		var h := float(bld["h"])
		var area := _p28_area(q)
		if h >= 70.0 and h < 76.0 and area > 800.0:
			tower = q
		elif h >= 78.0 and float(bld["mh"]) < 75.0 and area > 400.0:
			upper = q
		elif h >= 38.0 and h < 45.0 and area > 800.0:
			annex = q
		elif h >= 20.0 and h < 30.0 and area > 300.0 and bld.get("kind", "") != "roof":
			wings.append(q)
	if tower.size() < 3:
		return
	var g := INF
	for bld: Dictionary in site["parts"]:
		g = minf(g, _ground_under(_pts(bld["p"])))
	_g = g
	var none := Color(0, 0, 0, 0)
	# The tower's frame: u along the Prosta face (its southmost long edge), v into the block.
	var fa := Vector2.ZERO
	var fb := Vector2.ZERO
	var best := -INF
	for i in tower.size():
		var a := tower[i]
		var b := tower[(i + 1) % tower.size()]
		var score := _out(tower, a, b).y * a.distance_to(b)
		if score > best:
			best = score
			fa = a
			fb = b
	var u := (fb - fa).normalized()
	if u.x < 0.0:
		u = -u
		var t := fa
		fa = fb
		fb = t
	# fa is the face's west end: the stone stack lies west of it.
	var north := -_out(tower, fa, fb)
	var far := 200.0
	var west_half := PackedVector2Array([fa - u * far - north * far, fa - north * far, fa + north * far, fa - u * far + north * far])
	var stack := _largest(Geometry2D.intersect_polygons(tower, west_half))
	var glass := _largest(Geometry2D.clip_polygons(tower, west_half))
	if glass.size() < 3:
		glass = tower
		stack = PackedVector2Array()
	# The base: the lobby's dark glass 1.2 m in, the columns and X braces on the line of the glass above.
	var lobby := _largest(Geometry2D.offset_polygon(tower, -1.2, Geometry2D.JOIN_MITER))
	_prism(lobby, g - 0.5, g + P28_BASE, P28_LOBBY, none, M_SKIN + float(S_DARK) / 16.0)
	_p28_base(glass, g)
	# The glass shaft: to the north terrace's level all round, the upper part (OSM's) on to the top.
	var u_ring := _largest(Geometry2D.intersect_polygons(upper, glass)) if upper.size() >= 3 else PackedVector2Array()
	_prism(glass, g + P28_BASE, g + P28_LOW, P28_GLASS, P28_ROOF, M_SKIN + float(S_FINS) / 16.0, M_STONE)
	if u_ring.size() >= 3:
		_prism(u_ring, g + P28_LOW, g + P28_HIGH, P28_GLASS, P28_ROOF, M_SKIN + float(S_FINS) / 16.0, M_STONE)
		_p28_terrace(glass, u_ring, g + P28_LOW)
		# The stone crown, set back 3 m on the north (a second planted step) and 1.5 m elsewhere.
		var crown := _largest(Geometry2D.offset_polygon(u_ring, -1.5, Geometry2D.JOIN_MITER))
		var keep_south := PackedVector2Array([fa - u * far - north * far, fb + u * far - north * far, fb + u * far + north * 24.0,
				fa - u * far + north * 24.0])
		crown = _largest(Geometry2D.intersect_polygons(crown, keep_south))
		if crown.size() >= 3:
			_prism(crown, g + P28_HIGH, g + P28_TOP, P28_CROWN, P28_ROOF.lightened(0.1), M_STONE, M_STONE)
			_p28_terrace(u_ring, crown, g + P28_HIGH)
	else:
		_prism(glass, g + P28_LOW, g + P28_HIGH, P28_GLASS, P28_ROOF, M_SKIN + float(S_FINS) / 16.0, M_STONE)
	_parapet(glass, g + P28_LOW, 1.1, Color("#c9dcdc"))
	# The stone stack on the west end, in two steps (the outer one lower).
	if stack.size() >= 3:
		_prism(stack, g + P28_BASE, g + float(P28_STACK[1]), P28_STONE, P28_ROOF, M_SKIN + float(S_PUNCHED) / 16.0, M_STONE)
		var inner := _largest(Geometry2D.intersect_polygons(stack, PackedVector2Array([fa - u * 4.5 - north * far,
				fa - north * far, fa + north * far, fa - u * 4.5 + north * far])))
		if inner.size() >= 3:
			_prism(inner, g + float(P28_STACK[1]), g + float(P28_STACK[0]), P28_STONE, P28_ROOF, M_SKIN + float(S_PUNCHED) / 16.0, M_STONE)
	# PROSTO, small and red, high on the east face.
	var ea := Vector2.ZERO
	var eb := Vector2.ZERO
	best = -INF
	for i in glass.size():
		var a := glass[i]
		var b := glass[(i + 1) % glass.size()]
		var score := _out(glass, a, b).x * a.distance_to(b)
		if score > best:
			best = score
			ea = a
			eb = b
	var eo := _out(glass, ea, eb)
	var em := ea.lerp(eb, 0.3)
	signs.append(["PROSTO", Vector3(em.x, g + P28_LOW - 4.0, em.y), Vector3(eo.x, 0.0, eo.y), 0.6, Color(0.92, 0.12, 0.14)])
	# The annex towards Łucka: green glass to 34 m, then two planted steps.
	if annex.size() >= 3:
		var body := _largest(Geometry2D.clip_polygons(annex, tower))
		if body.size() >= 3:
			_prism(body, g - 0.5, g + P28_ANNEX_H - 6.6, P28_ANNEX, P28_GREEN, M_SKIN + float(S_BANDS) / 16.0, M_STONE)
			var step1 := _largest(Geometry2D.offset_polygon(body, -3.5, Geometry2D.JOIN_MITER))
			if step1.size() >= 3:
				_prism(step1, g + P28_ANNEX_H - 6.6, g + P28_ANNEX_H - 3.3, P28_ANNEX, P28_GREEN, M_SKIN + float(S_BANDS) / 16.0, M_STONE)
				_p28_hedge(body, g + P28_ANNEX_H - 6.6)
				var step2 := _largest(Geometry2D.offset_polygon(step1, -3.5, Geometry2D.JOIN_MITER))
				if step2.size() >= 3:
					_prism(step2, g + P28_ANNEX_H - 3.3, g + P28_ANNEX_H, P28_ANNEX, P28_ROOF, M_SKIN + float(S_BANDS) / 16.0, M_STONE)
					_p28_hedge(step1, g + P28_ANNEX_H - 3.3)
					_no_roof = true
					var c := _centre(step2)
					_prism(_square(c, 2.5), g + P28_ANNEX_H, g + P28_ANNEX_H + 2.2, Color("#7a8085"), Color("#868c90"), M_STONE, M_STONE)
					_no_roof = false
			_collide(body)
			pocket_rings.append(body)
	# The 24 m wings: what of them the tower and the annex don't already stand on.
	for w in wings:
		var rest := _largest(Geometry2D.clip_polygons(w, tower))
		if annex.size() >= 3 and rest.size() >= 3:
			rest = _largest(Geometry2D.clip_polygons(rest, annex))
		if rest.size() < 3 or _p28_area(rest) < 60.0:
			continue
		_prism(rest, g - 0.5, g + 24.1, P28_ANNEX.lightened(0.08), P28_GREEN.darkened(0.05), M_SKIN + float(S_BANDS) / 16.0, M_STONE)
		_parapet(rest, g + 24.1, 1.0, Color("#c9dcdc"))
		_collide(rest)
		pocket_rings.append(rest)
	_collide(tower)
	pocket_rings.append(tower)


## The base's frame on the glass shaft's line: dark steel columns about every 4.8 m on the faces
## to the street (south and east), a silver X brace in each bay, a dark beam over them.
func _p28_base(ring: PackedVector2Array, g: float) -> void:
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var o := _out(ring, a, b)
		var length := a.distance_to(b)
		if length < 6.0 or (o.y < 0.5 and o.x < 0.5):
			continue
		var n := maxi(1, roundi(length / 4.8))
		var e := (b - a) / length
		for k in n + 1:
			var p := a + e * (length * k / n) + o * 0.05
			_prism(_square(p - o * 0.35, 0.4), g - 0.3, g + P28_BASE, P28_STEEL, Color(0, 0, 0, 0), M_STONE)
			if k == n:
				break
			var p1 := a + e * (length * (k + 1) / n) + o * 0.05
			var lo := g + 0.4
			var hi := g + P28_BASE - 0.8
			_beam(Vector3(p.x, lo, p.y), Vector3(p1.x, hi, p1.y), 0.3, P28_BRACE, false)
			var q0 := p + o * 0.12
			var q1 := p1 + o * 0.12
			_beam(Vector3(q1.x, lo, q1.y), Vector3(q0.x, hi, q0.y), 0.3, P28_BRACE, false)
		_wall(a + o * 0.1, b + o * 0.1, g + P28_BASE - 0.8, g + P28_BASE, o, P28_STEEL)


## A planted terrace on `lower` round the foot of `upper` at y: a glass balustrade on its edge,
## a hedge of planters and a small tree every ~6 m along the open edge.
func _p28_terrace(lower: PackedVector2Array, upper: PackedVector2Array, y: float) -> void:
	_no_roof = true
	_p28_hedge(lower, y)
	var rim := _largest(Geometry2D.offset_polygon(lower, -1.4, Geometry2D.JOIN_MITER))
	if rim.size() < 3:
		_no_roof = false
		return
	var grown := Geometry2D.offset_polygon(upper, 0.8, Geometry2D.JOIN_MITER)
	var block: PackedVector2Array = grown[0] if not grown.is_empty() else upper
	var n := 0
	for i in rim.size():
		var a := rim[i]
		var b := rim[(i + 1) % rim.size()]
		var length := a.distance_to(b)
		var steps := floori(length / 6.0)
		for k in steps:
			var p := a.lerp(b, (k + 0.5) / steps)
			if Geometry2D.is_point_in_polygon(p, block):
				continue
			var leaf: Color = P28_LEAF[n % P28_LEAF.size()]
			n += 1
			_prism(_square(p, 0.6), y, y + 0.7, Color("#6d6a64"), P28_GREEN, M_STONE, M_STONE)
			_prism(_square(p, 0.08), y + 0.7, y + 2.0, Color("#6b5a48"), Color(0, 0, 0, 0), M_STONE)
			_mode = M_STONE
			_frustum(_circle(p, 0.6, 5), y + 1.6, _circle(p, 1.3, 5), y + 2.6, leaf.darkened(0.1))
			_pyramid(_circle(p, 1.3, 5), y + 2.6, y + 4.0, leaf)
	_no_roof = false


## A low planter hedge just inside a ring's edge at y (the terraces' green line) and a glass rail.
func _p28_hedge(ring: PackedVector2Array, y: float) -> void:
	var keep := _no_roof
	_no_roof = true
	var hedge := _largest(Geometry2D.offset_polygon(ring, -0.5, Geometry2D.JOIN_MITER))
	if hedge.size() >= 3:
		_prism(hedge, y, y + 0.7, P28_GREEN.darkened(0.12), Color(0, 0, 0, 0), M_STONE, M_STONE)
	_no_roof = keep


## The Forest (HRA Architekci, 2022; spec docs/landmarks/specs/forest.md), rebuilt from F's seven
## photos (2026-11-03): a 120 m tower of dark green-black glass in three slabs that step up to
## the east, each topped by a dark crown band, the east slab hung with orange, red and green
## vertical fins and wearing PEPEO ŻUBR (F's parody) in its crown; low wings of glass behind the
## same multicoloured fins, a black-clad top storey set back over a planted ledge, roof gardens
## with corten planters, timber decks and copper-clad stair houses; and between the wings an open
## courtyard of young trees, curved grass steps (an amphitheatre) and a corten pavilion.
## Built from the mapped parts (bake_sectors.py SITE_AREAS has the box).
const FOREST_BOX := Rect2(-3105.0, -2455.0, 185.0, 120.0)
const FOREST_GLASS := Color("#35504a")      # the tower's dark green-black glass
const FOREST_LOW := Color("#55707a")        # the wings' blue-green glass
const FOREST_BLACK := Color("#2b2d2f")      # the black-clad top storeys
const FOREST_CROWN_COL := Color("#2e2925")  # the slabs' crown bands, dark with a brown cast
const FOREST_GREEN := Color("#5d8f45")
const FOREST_CORTEN := Color("#8e4a24")
const FOREST_COPPER := Color("#9b5b36")
const FOREST_BANK := Color(1.0, 0.97, 0.9)  # PEPEO ŻUBR in white, as the photos' crown letters
const FOREST_TIMBER := Color("#a98457")
const FOREST_PARASOL: Array[Color] = [Color("#f1ece0"), Color("#d9a441"), Color("#e8e2d2"), Color("#5f8f8a")]
## The fins' colours from the photos, orange most of all, then red, green, mustard and brown.
const FOREST_FINS: Array[Color] = [Color("#e07a2a"), Color("#d0601f"), Color("#e8923a"), Color("#b8322a"),
		Color("#c4452a"), Color("#6f8f3a"), Color("#86a046"), Color("#d9a32b"), Color("#7a4a2a"), Color("#e07a2a")]
## The tower's frame: u along its south face west to east, v north to south (metres from the
## south-west corner). The mapped outline's east end steps out twice (u 44.6, 47.8, 51.5): three
## slabs side by side, split at v -22.2 and -12, their tops stepping 110, 115.5 and 120 m from
## north to south, so the tallest faces Rondo Radosława.
const FOREST_O := Vector2(-2990.2, -2350.9)
const FOREST_U := Vector2(0.99633, 0.08562)
const FOREST_SLABS := [[-40.0, -22.2, 110.0], [-22.2, -12.0, 115.5], [-12.0, 5.0, 120.0]]
const FOREST_CROWN := 6.0   # the dark crown band on each slab
## The low wings' height from F's photos (F, 2026-11-03: "estimate it from the photos"): eight
## storeys, seven of glass over the lobby and the black top one, about 31 m where OSM says 20.8.
## The 27.4 m wing keeps OSM's height: its terrace crowd stands at 27.4 (crowds.gd DECKS).
const FOREST_WING_H := 31.0
## The courtyard, from the mapped paths and grass (clear of both by 1.8 m): the amphitheatre's
## centre (its steps open to the east, to the fountain), the pavilion, the young trees.
const FOREST_AMPH := Vector2(-3051.0, -2403.5)
const FOREST_PAVILION := Vector2(-2973.5, -2398.5)
const FOREST_TREES := [Vector2(-3034.5, -2390.5), Vector2(-2967.5, -2404.5), Vector2(-2992.5, -2392.5), Vector2(-2992.5, -2400.5),
		Vector2(-2997.5, -2405.5), Vector2(-2978.5, -2404.5), Vector2(-3055.5, -2394.5), Vector2(-3026.5, -2392.5),
		Vector2(-2976.5, -2391.5), Vector2(-2998.5, -2395.5), Vector2(-3054.5, -2412.5), Vector2(-2988.5, -2381.5),
		Vector2(-3016.5, -2386.5), Vector2(-3005.5, -2406.5), Vector2(-3040.5, -2397.5), Vector2(-3043.5, -2387.5),
		Vector2(-2985.5, -2404.5), Vector2(-3041.5, -2403.5), Vector2(-3034.5, -2412.5), Vector2(-2965.5, -2395.5),
		Vector2(-3022.5, -2407.5), Vector2(-3026.5, -2385.5), Vector2(-3060.5, -2403.5), Vector2(-3062.5, -2410.5),
		Vector2(-2986.5, -2397.5), Vector2(-3012.5, -2394.5), Vector2(-3012.5, -2400.5), Vector2(-3046.5, -2394.5),
		Vector2(-3005.5, -2388.5), Vector2(-2974.5, -2384.5), Vector2(-3010.5, -2383.5), Vector2(-2980.5, -2380.5),
		Vector2(-2979.5, -2398.5), Vector2(-3045.5, -2411.5), Vector2(-3030.5, -2407.5), Vector2(-2995.5, -2385.5),
		Vector2(-2969.5, -2390.5), Vector2(-2991.5, -2407.5), Vector2(-3019.5, -2392.5), Vector2(-2985.5, -2389.5),
		Vector2(-3018.5, -2400.5), Vector2(-3041.5, -2416.5), Vector2(-3032.5, -2384.5)]
const FOREST_LEAF: Array[Color] = [Color("#6f9a45"), Color("#5f8a3c"), Color("#86a94e"), Color("#7aa048")]
func _find_forest() -> void:
	var zone: Array = []
	var parts: Array = []
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() >= 3 and FOREST_BOX.has_point(_centre(q)) and float(bld["h"]) >= 20.0:
			zone.append(q)
			# The U-shaped west wing's centre falls in the courtyard: its hull, so the plain
			# block (or LoD2's) under it goes too (Piano House's pitfall).
			zone.append(Geometry2D.convex_hull(q))
			parts.append(bld)
	_add_site("forest", zone)
	if not sites.is_empty() and sites[-1]["key"] == "forest":
		sites[-1]["parts"] = parts


func _build_forest(site: Dictionary) -> void:
	var parts: Array = site["parts"]
	var tallest := 0.0
	for bld in parts:
		tallest = maxf(tallest, float(bld["h"]))
	_g = INF
	for bld in parts:
		_g = minf(_g, _ground_under(_pts(bld["p"])))
	var g := _g
	for bld in parts:
		var poly := _pts(bld["p"])
		var h := float(bld["h"])
		if h >= tallest - 0.5:
			_forest_tower(poly, g)
		else:
			_forest_wing(poly, g, FOREST_WING_H if h < 25.0 else h, h >= 25.0)
		# The car's walls on the mapped outline, handed to the pocket bridging too.
		_collide(poly)
		pocket_rings.append(poly)
	_forest_courtyard()


## Strip fins: one flat coloured blade every `step` m, `proud` out of each face of `ring` from y0
## to y1, `w` wide, its colour by a hash of where it stands (the photos' irregular rhythm). One
## quad each: from the street the blades read as the facade's colour stripes.
func _forest_fins(ring: PackedVector2Array, y0: float, y1: float, step: float, w: float, proud: float, salt: float) -> void:
	var keep := _mode
	_mode = M_STONE
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < step:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		var n := floori(length / step)
		var pad := (length - (n - 1) * step) * 0.5
		for k in n:
			var p := a + e * (pad + k * step) + out * proud
			var hsh := fposmod(sin(p.x * 12.9898 + p.y * 78.233 + salt) * 43758.5453, 1.0)
			var col: Color = FOREST_FINS[int(hsh * FOREST_FINS.size()) % FOREST_FINS.size()]
			_wall(p - e * w * 0.5, p + e * w * 0.5, y0, y1, out, col)
	_mode = keep


## The tower: three slabs of the mapped outline, each glass to its crown band, then the band.
func _forest_tower(poly: PackedVector2Array, g: float) -> void:
	var v := Vector2(-FOREST_U.y, FOREST_U.x)
	for s: Array in FOREST_SLABS:
		var strip := PackedVector2Array([FOREST_O - FOREST_U * 5.0 + v * float(s[0]), FOREST_O + FOREST_U * 60.0 + v * float(s[0]),
				FOREST_O + FOREST_U * 60.0 + v * float(s[1]), FOREST_O - FOREST_U * 5.0 + v * float(s[1])])
		var slab := _largest(Geometry2D.intersect_polygons(poly, strip))
		if slab.size() < 3:
			continue
		var top := g + float(s[2])
		_prism(slab, g, top - FOREST_CROWN, FOREST_GLASS, Color(0, 0, 0, 0), M_SKIN + S_DARK / 16.0, M_STONE)
		_prism(slab, top - FOREST_CROWN, top, FOREST_CROWN_COL, FOREST_BLACK.lightened(0.08), M_STONE, M_STONE)
		if float(s[2]) >= 119.0:
			# The south slab: the colour fins on all its faces, then the name in its crown.
			_forest_fins(slab, g + 4.5, top - FOREST_CROWN, 1.25, 0.32, 0.12, 7.0)
			_forest_sign(slab, top)
		else:
			# The lower slabs: a sparser run of fins (the photos' faint colour in the dark glass).
			_forest_fins(slab, g + 4.5, top - FOREST_CROWN, 3.6, 0.26, 0.12, float(s[2]))
		# A roof plant box on each slab (the photos' crown kit), out of the roof grid.
		var c := _centre(slab)
		_no_roof = true
		_prism(_square(c, 2.2), top, top + 2.4, Color("#5b5f60"), Color("#6a6e6f"), M_STONE, M_STONE)
		_no_roof = false
		if float(s[2]) >= 119.0:
			_forest_boat(slab, c, top)


## PEPEO ŻUBR (F, 2026-11-03), F's parody of the tenant's name, in the south slab's crown band:
## big on its long south face (towards Rondo Radosława), smaller on its narrow east end (towards
## Aleja Jana Pawła II), as the photos show it over the narrow face. Placed in the tower's frame
## on the slab's own faces (the outline's steps make a ray from the centre miss them).
func _forest_sign(slab: PackedVector2Array, top: float) -> void:
	var v := Vector2(-FOREST_U.y, FOREST_U.x)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in slab:
		var l := Vector2((q - FOREST_O).dot(FOREST_U), (q - FOREST_O).dot(v))
		lo = lo.min(l)
		hi = hi.max(l)
	var y := top - FOREST_CROWN + 0.6
	# The south face: centred on the east half, 1.9 (about 23 m of letters).
	var south := FOREST_O + FOREST_U * lerpf(lo.x, hi.x, 0.62) + v * (hi.y + 0.1)
	signs.append(["PEPEO ŻUBR", Vector3(south.x, y, south.y), Vector3(v.x, 0.0, v.y), 1.9, FOREST_BANK])
	# The east end: 0.85 (about 10 m), on the slab's own 12 m end.
	var east := FOREST_O + FOREST_U * (hi.x + 0.1) + v * ((lo.y + hi.y) * 0.5)
	signs.append(["PEPEO ŻUBR", Vector3(east.x, y + 1.2, east.y), Vector3(FOREST_U.x, 0.0, FOREST_U.y), 0.85, FOREST_BANK])


## F's joke (2026-11-06): a cobalt-blue motor bowrider on a cradle on the tallest slab's roof, well
## clear of the crown band that carries PEPEO ŻUBR and of the plant box. Ten metres long, white
## hull with a cobalt sheer and stripe, a swept windshield, bow and stern seats, a sun pad over
## the engine, a chrome rail. Two metres beside the slab's axis and turned 25 degrees, as if it
## were being lifted.
const FOREST_BOAT_BLUE := Color("#0b3d91")
func _forest_boat(slab: PackedVector2Array, c: Vector2, top: float) -> void:
	var none := Color(0, 0, 0, 0)
	var a := Vector2(FOREST_U.x, FOREST_U.y).rotated(deg_to_rad(25.0))
	var b := Vector2(-a.y, a.x)
	var m := c + FOREST_U * 9.0
	var hl := 5.0
	var hb := 1.35
	var hull := PackedVector2Array([m + a * hl, m + a * hl * 0.4 + b * hb * 0.85, m - a * hl * 0.85 + b * hb,
			m - a * hl + b * hb * 0.9, m - a * hl - b * hb * 0.9, m - a * hl * 0.85 - b * hb, m + a * hl * 0.4 - b * hb * 0.85])
	for q in hull:
		if not Geometry2D.is_point_in_polygon(q, slab):
			return
	_no_roof = true
	_mode = M_STONE
	# Cradle: two steel skids and a keel block.
	for sd: float in [-0.9, 0.9]:
		_prism(PackedVector2Array([m - a * 3.6 + b * (sd - 0.12), m + a * 3.2 + b * (sd - 0.12), m + a * 3.2 + b * (sd + 0.12),
				m - a * 3.6 + b * (sd + 0.12)]), top, top + 0.55, Color("#4a4f54"), Color("#4a4f54"), M_STONE, M_STONE)
	var y := top + 0.55
	_prism(hull, y, y + 0.55, FOREST_BOAT_BLUE, none, M_STONE)
	_prism(hull, y + 0.55, y + 1.0, Color("#f4f5f2"), none, M_STONE)
	var sheer := _largest(Geometry2D.offset_polygon(hull, -0.12, Geometry2D.JOIN_MITER))
	if sheer.size() >= 3:
		_prism(sheer, y + 1.0, y + 1.12, FOREST_BOAT_BLUE, Color("#e8dcc0"), M_STONE, M_STONE)
	var d := y + 1.12
	# Bow seat, dash console, stern bench and the engine-cover sun pad.
	_prism(PackedVector2Array([m + a * 3.3 + b * 0.9, m + a * 2.2 + b * 1.0, m + a * 2.2 - b * 1.0, m + a * 3.3 - b * 0.9]),
			d, d + 0.35, Color("#f1efe8"), Color("#f1efe8"), M_STONE, M_STONE)
	_prism(PackedVector2Array([m + a * 1.0 + b * 1.0, m + a * 0.3 + b * 1.0, m + a * 0.3 - b * 1.0, m + a * 1.0 - b * 1.0]),
			d, d + 0.8, Color("#e9e8e2"), Color("#2b2d2f"), M_STONE, M_STONE)
	_prism(PackedVector2Array([m - a * 2.0 + b * 1.15, m - a * 3.0 + b * 1.15, m - a * 3.0 - b * 1.15, m - a * 2.0 - b * 1.15]),
			d, d + 0.4, Color("#f1efe8"), Color("#f1efe8"), M_STONE, M_STONE)
	_prism(PackedVector2Array([m - a * 3.2 + b * 1.2, m - a * 4.3 + b * 1.2, m - a * 4.3 - b * 1.2, m - a * 3.2 - b * 1.2]),
			d, d + 0.45, Color("#0b3d91"), Color("#f1efe8"), M_STONE, M_STONE)
	# Windshield: a tinted glass quad, leaning back.
	var w0 := m + a * 1.1 + b * 0.95
	var w1 := m + a * 1.1 - b * 0.95
	var t0 := m + a * 0.4 + b * 0.95
	var t1 := m + a * 0.4 - b * 0.95
	_mode = M_PAVILION
	_quad(Vector3(w0.x, d + 0.8, w0.y), Vector3(w1.x, d + 0.8, w1.y), Vector3(t1.x, d + 1.5, t1.y), Vector3(t0.x, d + 1.5, t0.y),
			Vector3(a.x, 0.5, a.y).normalized(), Color("#6b8794"))
	_mode = M_STONE
	# Chrome rail round the bow and a flag staff at the stern.
	var bow := m + a * 4.6
	_beam(Vector3(bow.x, d, bow.y), Vector3(bow.x, d + 0.5, bow.y), 0.05, Color("#c9ced2"), false)
	var st := m - a * 4.6
	_beam(Vector3(st.x, d, st.y), Vector3(st.x, d + 1.6, st.y), 0.05, Color("#c9ced2"), false)
	_no_roof = false


## A wing: glass behind the colour fins up to a planted ledge, the black-clad top storey set
## back 1.6 m, and on its roof the garden (or, on the 27.4 m wing, the terrace with its crowd).
func _forest_wing(poly: PackedVector2Array, g: float, h: float, terrace: bool) -> void:
	var glass_top := g + h - 4.0
	_prism(poly, g, glass_top, FOREST_LOW, FOREST_GREEN.darkened(0.1), M_SKIN + S_FINS / 16.0, M_STONE)
	_forest_fins(poly, g + 4.0, glass_top, 1.5, 0.34, 0.12, h)
	var top_ring := _largest(Geometry2D.offset_polygon(poly, -1.6, Geometry2D.JOIN_MITER))
	if top_ring.size() < 3:
		return
	_prism(top_ring, glass_top, g + h, FOREST_BLACK, FOREST_GREEN, M_SKIN + S_DARK / 16.0, M_STONE)
	# The planted ledge's hedge along the glass edge (the photos' green line over the fins).
	_no_roof = true
	var hedge := _largest(Geometry2D.offset_polygon(poly, -0.5, Geometry2D.JOIN_MITER))
	if hedge.size() >= 3:
		# The ledge is a low carpet of sedum and white flowers (the photos), not a hedge.
		_prism(hedge, glass_top, glass_top + 0.25, Color("#8fae6c"), Color("#a9c27f"), M_STONE, M_STONE)
	_no_roof = false
	if terrace:
		_forest_terrace(top_ring, g + h)
	else:
		_forest_garden(top_ring, g + h)


## The roof gardens as they are (F, 2026-11-15, four photos of the public green roof): over the
## black louvred top storey a black railing with corten posts runs round the edge; inside it a
## lawn, a dark paved walk along the railing, long wavy beds of clipped shrub in corten edging
## (silver-green and deep green) with young trees, and corten pavilions with a glass front, a dark
## coping and a gravel roof. The terrace wing adds a grey deck, a white stretch tent, patio
## heaters and high tables. Spec docs/landmarks/specs/forest.md section 4.
const FOREST_LAWN := Color("#6fa04a")
const FOREST_PATH := Color("#5b5e61")
const FOREST_SAGE := Color("#a3b592")
const FOREST_SHRUB := Color("#5f8f43")
const FOREST_GRAVEL := Color("#908c85")
const FOREST_TENT := Color("#f1efe8")
const FOREST_DECK := Color("#756f68")


## The black railing round a roof edge: corten posts every `post` m, a black top rail and a black
## foot, each one flat face towards the street (single quads, the photos' dark band of balusters).
func _forest_rail(ring: PackedVector2Array, y: float, post := 4.0) -> void:
	_mode = M_STONE
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 1.0:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		_wall(a, b, y + 1.0, y + 1.1, out, FOREST_BLACK)
		_wall(a, b, y, y + 0.14, out, FOREST_BLACK)
		var n := maxi(1, floori(length / post))
		for k in n + 1:
			var p := a + e * (length * float(k) / float(n))
			_wall(p - e * 0.05, p + e * 0.05, y, y + 1.1, out, FOREST_CORTEN.darkened(0.25))


## Long wavy beds of clipped shrub in corten edging along the edges of `ring` (itself already
## inside the roof by `inset`), 1.7 m wide, a sage and a deep-green one in turn, a young tree
## every ~9 m. `bound` is the roof's inner outline: a bed that would leave it is dropped.
func _forest_beds(ring: PackedVector2Array, bound: PackedVector2Array, y: float, salt: float) -> void:
	var idx := 0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 12.0:
			continue
		var e := (b - a) / length
		var inward := -_out(ring, a, b)
		var pad := 2.5
		var run := length - pad * 2.0
		var n := maxi(3, roundi(run / 4.0))
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for k in n + 1:
			var t := float(k) / float(n)
			var base := a + e * (pad + run * t)
			var amp := 0.9 * sin(t * run / 7.0 + salt + float(i))
			base += inward * amp
			left.append(base + inward * 0.85)
			right.append(base - inward * 0.85)
		right.reverse()
		var bed := left + right
		var ok := true
		for q in bed:
			if not Geometry2D.is_point_in_polygon(q, bound):
				ok = false
				break
		if not ok:
			continue
		var sage := (idx % 2 == 0)
		_prism(bed, y + 0.1, y + 0.6, FOREST_CORTEN, FOREST_CORTEN.darkened(0.2), M_STONE, M_STONE)
		var top := _largest(Geometry2D.offset_polygon(bed, -0.2, Geometry2D.JOIN_MITER))
		if top.size() >= 3:
			_prism(top, y + 0.6, y + 1.3, FOREST_SAGE if sage else FOREST_SHRUB, (FOREST_SAGE if sage else FOREST_SHRUB).lightened(0.12), M_STONE, M_STONE)
		var q := 1
		while q < n:
			if (q + idx) % 2 == 0:
				var t2 := float(q) / float(n)
				var p := a + e * (pad + run * t2) + inward * 0.9 * sin(t2 * run / 7.0 + salt + float(i))
				_mode = M_STONE
				_pyramid(_circle(p, 0.9, 6), y + 1.2, y + 4.0, FOREST_LEAF[(q + idx) % FOREST_LEAF.size()])
			q += 2
		idx += 1


## A corten pavilion, `c` its centre, `d` its long axis: 5.6 x 3.6 m, 3.2 m high, a dark coping
## round a gravel roof and a glass front on one long side (the photos' pavilions).
func _forest_pavilion(c: Vector2, d: Vector2, y: float, bound: PackedVector2Array) -> void:
	var n := Vector2(-d.y, d.x)
	var box := PackedVector2Array([c - d * 2.8 - n * 1.8, c + d * 2.8 - n * 1.8, c + d * 2.8 + n * 1.8, c - d * 2.8 + n * 1.8])
	for q in box:
		if not Geometry2D.is_point_in_polygon(q, bound):
			return
	_prism(box, y + 0.1, y + 3.3, FOREST_CORTEN, FOREST_BLACK, M_STONE, M_STONE)
	var gr := _largest(Geometry2D.offset_polygon(box, -0.4, Geometry2D.JOIN_MITER))
	if gr.size() >= 3:
		_cap(gr, y + 3.36, FOREST_GRAVEL)
	var f0 := c - d * 2.2 + n * 1.84
	var f1 := c + d * 2.2 + n * 1.84
	_mode = M_PAVILION
	_quad(Vector3(f0.x, y + 0.2, f0.y), Vector3(f1.x, y + 0.2, f1.y), Vector3(f1.x, y + 3.0, f1.y), Vector3(f0.x, y + 3.0, f0.y),
			Vector3(n.x, 0.0, n.y), Color("#6b8794"))
	_mode = M_STONE


## The longest edge's direction of a ring (the wing's long axis).
func _forest_axis(ring: PackedVector2Array) -> Vector2:
	var best := 0.0
	var d := Vector2.RIGHT
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if a.distance_to(b) > best:
			best = a.distance_to(b)
			d = (b - a).normalized()
	return d


## The interior pieces of a roof (the ring pulled in `in_m`), the biggest first, at most `most`.
func _forest_pieces(ring: PackedVector2Array, in_m: float, most: int) -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array] = []
	for pc in Geometry2D.offset_polygon(ring, -in_m, Geometry2D.JOIN_MITER):
		if absf(_area(pc)) >= 60.0:
			pieces.append(pc)
	pieces.sort_custom(func(p: PackedVector2Array, q: PackedVector2Array) -> bool: return absf(_area(p)) > absf(_area(q)))
	return pieces.slice(0, most)


## A roof garden on a wing: the lawn, the paved walk along the railing, the wavy corten beds, the
## railing and a corten pavilion in the middle of each wide piece.
func _forest_garden(ring: PackedVector2Array, y: float) -> void:
	var lawn := _largest(Geometry2D.offset_polygon(ring, -0.6, Geometry2D.JOIN_MITER))
	if lawn.size() < 3:
		return
	_no_roof = true
	_mode = M_STONE
	_cap(lawn, y + 0.1, FOREST_LAWN)
	var walk := _largest(Geometry2D.offset_polygon(ring, -1.7, Geometry2D.JOIN_MITER))
	if walk.size() >= 3:
		for i in walk.size():
			var a := walk[i]
			var b := walk[(i + 1) % walk.size()]
			var e := (b - a).normalized()
			var nn := Vector2(-e.y, e.x) * 0.9
			_cap(PackedVector2Array([a - nn, b - nn, b + nn, a + nn]), y + 0.16, FOREST_PATH)
	var beds := _largest(Geometry2D.offset_polygon(ring, -4.2, Geometry2D.JOIN_MITER))
	if beds.size() >= 3:
		_forest_beds(beds, lawn, y, y * 0.37)
	# A second run of beds through the middle of a wide roof (the photos' swirling hedges).
	var mid_beds := _largest(Geometry2D.offset_polygon(ring, -9.5, Geometry2D.JOIN_MITER))
	if mid_beds.size() >= 3:
		_forest_beds(mid_beds, lawn, y, y * 0.61 + 2.0)
	_forest_rail(_largest(Geometry2D.offset_polygon(ring, -0.25, Geometry2D.JOIN_MITER)), y)
	for pc in _forest_pieces(ring, 6.5, 2):
		_forest_pavilion(_centre(pc), _forest_axis(pc), y, lawn)
	_no_roof = false


## The Forest's public roof terrace (F, 2026-11-01; the green roof of the photos, 2026-11-15), on
## the 27 m wing: a grey deck inside the black railing, wavy corten beds along it, a corten
## pavilion with a glass front at the south end, a white stretch tent over high tables and patio
## heaters at the north end, a strip of lawn between. All of it out of the roof grid, so the
## crowd's spots (crowds.gd DECKS `forest_terrace`) still read the block's roof.
func _forest_terrace(poly: PackedVector2Array, y: float) -> void:
	var none := Color(0, 0, 0, 0)
	var rim := _largest(Geometry2D.offset_polygon(poly, -0.5, Geometry2D.JOIN_MITER))
	if rim.size() < 3:
		return
	_no_roof = true
	_mode = M_STONE
	_cap(rim, y + 0.1, FOREST_DECK)
	var beds := _largest(Geometry2D.offset_polygon(poly, -3.4, Geometry2D.JOIN_MITER))
	if beds.size() >= 3:
		_forest_beds(beds, rim, y, 2.1)
	_forest_rail(_largest(Geometry2D.offset_polygon(poly, -0.25, Geometry2D.JOIN_MITER)), y)
	var pieces := _forest_pieces(poly, 6.0, 1)
	if not pieces.is_empty():
		var pc := pieces[0]
		var d := _forest_axis(poly)
		var n := Vector2(-d.y, d.x)
		var lo := INF
		var hi := -INF
		for q in pc:
			lo = minf(lo, q.dot(d))
			hi = maxf(hi, q.dot(d))
		var mid := _centre(pc)
		var mid_s := mid.dot(d)
		# Lawn strip in the middle, between the deck's two ends.
		var lawn := PackedVector2Array([mid - d * 3.0 - n * 40.0, mid + d * 3.0 - n * 40.0, mid + d * 3.0 + n * 40.0, mid - d * 3.0 + n * 40.0])
		var cut := Geometry2D.intersect_polygons(lawn, pc)
		if not cut.is_empty():
			_cap(cut[0], y + 0.16, FOREST_LAWN)
		var ends: Array[float] = [lo + 5.0, hi - 5.0]
		var south := mid + d * (ends[0] - mid_s)
		var north := mid + d * (ends[1] - mid_s)
		# Pavilion (long side across the roof's width) at one end.
		_forest_pavilion(south, n, y, rim)
		# The tent: two peaks over high tables and heaters at the other end.
		for k in 2:
			var tc := north + n * (float(k) * 7.0 - 3.5)
			var sq := PackedVector2Array([tc + (d + n) * 3.5, tc + (d - n) * 3.5, tc - (d + n) * 3.5, tc - (d - n) * 3.5])
			var inside := true
			for q in sq:
				if not Geometry2D.is_point_in_polygon(q, rim):
					inside = false
			if not inside:
				continue
			_mode = M_STONE
			_pyramid(sq, y + 2.7, y + 4.5, FOREST_TENT)
			for q in sq:
				_prism(_circle(q, 0.05, 4), y + 0.1, y + 2.7, Color("#c9cdd0"), none, M_STONE)
			var tp := tc + d * 0.5
			_prism(_circle(tp, 0.35, 6), y + 0.1, y + 1.1, Color("#25272a"), Color("#25272a"), M_STONE, M_STONE)
		# Patio heaters (a pole and a round hood) scattered down the deck.
		for k in 6:
			var hp := mid + d * (lerpf(lo + 4.0, hi - 4.0, float(k) / 5.0) - mid_s) + n * (3.0 if k % 2 == 0 else -3.0)
			if not Geometry2D.is_point_in_polygon(hp, rim):
				continue
			_prism(_circle(hp, 0.05, 4), y + 0.1, y + 2.3, Color("#c9cdd0"), none, M_STONE)
			_prism(_circle(hp, 0.4, 6), y + 2.3, y + 2.4, Color("#d9d3c6"), Color("#d9d3c6"), M_STONE, M_STONE)
	_no_roof = false


# --- Towarowa 22 (the Wola superblock, built as it will look) ----------------------------------

## Towarowa 22 (F, 2026-11-03): the "superkwartał" between Towarowa, Pańska and Miedziana, on the
## old Dom Słowa Polskiego printing works. Today mostly a building site; the game builds it as
## finished, from the developers' masterplan renders and the photos F attached (JEMS Architekci's
## plan; docs/landmarks/specs/towarowa22.md): a row of towers along Towarowa (a 150 m office tower
## on an 85 m podium at the Pańska corner, a white terraced tower, a terracotta tower with a wavy
## crown, a dark tower, a low teal office), the round-tanked block and Apartamenty Gutenberga on
## Nowa Wronia, the old printing hall turned into a yellow steel frame over a garden with its
## pavilion, and Park Słowa. What stands already (the Office House and its pergola, M7, the
## octagon) stays the map's. The "Warsaw of the future" jokes: a drone port on the big tower
## (WARSZAWA 2050 on its crown) and, in the park, a gilded monument to Wola's last tower crane.
## Frame: u along Towarowa's east carriageway (south-south-east, from about Pańska), v across it
## (east-north-east, towards Miedziana), metres.
const T22_O := Vector2(-2635.5, 470.0)
const T22_A := Vector2(0.4719, 0.8815)
const T22_B := Vector2(0.8815, -0.4719)
## Footprints [u0, u1, v0, v1, height] in that frame (the render's massing, the map's free ground:
## the car park at the Srebrna end and the paths along it stay).
const T22_AFI := [18.0, 56.0, 16.0, 50.0, 150.0]
const T22_PODIUM := [18.0, 62.0, 52.0, 92.0, 85.0]
const T22_WHITE := [70.0, 100.0, 20.0, 54.0, 124.0]
const T22_PINK := [112.0, 140.0, 20.0, 54.0, 112.0]
const T22_PINK_LOW := [108.0, 146.0, 60.0, 92.0, 34.0]
const T22_DARK := [156.0, 184.0, 20.0, 54.0, 96.0]
const T22_DUO := [196.0, 250.0, 16.0, 58.0, 36.0]
const T22_DUO_B := [196.0, 250.0, 64.0, 92.0, 26.0]
const T22_TANKS := [106.0, 172.0, 108.0, 136.0, 28.0]
const T22_GUT := [205.0, 282.0, 108.0, 178.0, 20.0]
const T22_HALL := [118.0, 198.0, 146.0, 200.0, 15.0]
const T22_PAVILION := [108.0, 200.0, 204.0, 218.0, 6.0]
const T22_PARK := [125.0, 208.0, 224.0, 276.0, 0.0]
## The octagon office at Pańska and Miedziana (the plan's ring with a court): its box in the frame
## (the map has it as the building site's cores and slabs, F's 2026-11-03 screenshot), centre,
## half size, corner cut, the court's half size and cut, height. The renders: white bands, a
## set-back top storey, a planted court.
const T22_OCT := [40.0, 124.0, 218.0, 302.0, 31.0]
const T22_OCT_C := Vector2(82.0, 259.5)
## The old printing hall's whole mapped outline (u 108..201, v 141..220) goes: the frame, the
## garden and the pavilion stand in it.
const T22_DSP := [106.0, 203.0, 139.0, 222.0, 0.0]
const T22_GREEN := Color("#6f9a4a")
const T22_YELLOW := Color("#e9c21c")
const T22_PAVING := Color("#b9806a")
const T22_NEON := Color(0.35, 1.0, 0.85)
const T22_GOLD := Color("#d9ae3c")


func _t22_rect(r: Array, grow := 0.0) -> PackedVector2Array:
	var u0: float = r[0] - grow
	var u1: float = r[1] + grow
	var v0: float = r[2] - grow
	var v1: float = r[3] + grow
	return PackedVector2Array([T22_O + T22_A * u0 + T22_B * v0, T22_O + T22_A * u1 + T22_B * v0,
			T22_O + T22_A * u1 + T22_B * v1, T22_O + T22_A * u0 + T22_B * v1])


## Ground over a rect of the frame that follows the terrain (the plot falls about a metre or two):
## 10 m cells, each corner `dy` over the ground there. A cell the terrain's own triangles (10 m
## cells in the world frame, not this rotated one) bend away from its flat quad by more than 2 cm
## is cut in four, down to 1.25 m: the quads used to sag under the OpenStreetMap `construction`
## earth and the brown poked through the paving and the lawn in patches (F, 2026-11-16).
func _t22_ground(r: Array, dy: float, col: Color) -> void:
	var nu := maxi(1, ceili((float(r[1]) - float(r[0])) / 10.0))
	var nv := maxi(1, ceili((float(r[3]) - float(r[2])) / 10.0))
	for i in nu:
		for j in nv:
			_t22_cell(lerpf(r[0], r[1], float(i) / nu), lerpf(r[0], r[1], float(i + 1) / nu),
					lerpf(r[2], r[3], float(j) / nv), lerpf(r[2], r[3], float(j + 1) / nv), dy, col, 0)


func _t22_cell(u0: float, u1: float, v0: float, v1: float, dy: float, col: Color, depth: int) -> void:
	var c: Array[Vector2] = [_w(u0, v0), _w(u1, v0), _w(u1, v1), _w(u0, v1)]
	var hs: Array[float] = []
	for p: Vector2 in c:
		hs.append(map.terrain_height(p.x, p.y))
	if depth < 3:
		var worst := 0.0
		for t: Vector2 in [Vector2(0.5, 0.5), Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75),
				Vector2(0.75, 0.75), Vector2(0.5, 0.0), Vector2(1.0, 0.5), Vector2(0.5, 1.0), Vector2(0.0, 0.5)]:
			var p := _w(lerpf(u0, u1, t.x), lerpf(v0, v1, t.y))
			var flat := lerpf(lerpf(hs[0], hs[1], t.x), lerpf(hs[3], hs[2], t.x), t.y)
			worst = maxf(worst, absf(map.terrain_height(p.x, p.y) - flat))
		if worst > 0.02:
			var um := (u0 + u1) * 0.5
			var vm := (v0 + v1) * 0.5
			_t22_cell(u0, um, v0, vm, dy, col, depth + 1)
			_t22_cell(um, u1, v0, vm, dy, col, depth + 1)
			_t22_cell(um, u1, vm, v1, dy, col, depth + 1)
			_t22_cell(u0, um, vm, v1, dy, col, depth + 1)
			return
	var q: Array[Vector3] = []
	for k in 4:
		q.append(Vector3(c[k].x, hs[k] + dy, c[k].y))
	_tri(q[0], q[1], q[2], Vector3.UP, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_tri(q[0], q[2], q[3], Vector3.UP, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


func _find_towarowa22() -> void:
	var zone: Array = []
	for r: Array in [T22_AFI, T22_PODIUM, T22_WHITE, T22_PINK, T22_PINK_LOW, T22_DARK, T22_DUO, T22_DUO_B,
			T22_TANKS, T22_GUT, T22_DSP, T22_PARK, T22_OCT]:
		zone.append(_t22_rect(r))
	_add_site("towarowa22", zone)
	# The 2023 laser scan's trees on the building site stay out of the new blocks.
	for r: Array in [T22_AFI, T22_PODIUM, T22_WHITE, T22_PINK, T22_PINK_LOW, T22_DARK, T22_DUO, T22_DUO_B,
			T22_TANKS, T22_GUT, T22_DSP]:
		var poly := _t22_rect(r, 1.5)
		tree_free.append([poly, 0.0, _box_of([poly])])
	var oct := _t22_rect(T22_OCT, 1.0)
	tree_free.append([oct, 0.0, _box_of([oct])])


func _build_towarowa22(_site: Dictionary) -> void:
	_o = T22_O
	_a = T22_A
	_b = T22_B
	var g := INF
	for r: Array in [T22_AFI, T22_DUO, T22_GUT, T22_DSP, T22_PARK]:
		g = minf(g, _ground_under(_t22_rect(r)))
	_g = g
	# The Towarowa row.
	var afi := _t22_box(T22_AFI, g, Color("#9db3c3"), Color("#7d8a94"), S_GRID)
	var podium := _t22_box(T22_PODIUM, g, Color("#a9bccb"), T22_GREEN, S_GRID)
	_t22_garden(podium, g + T22_PODIUM[4])
	_t22_dronport(afi, g + T22_AFI[4])
	_t22_box(T22_WHITE, g, Color("#ece8e0"), Color("#d8d4cc"), S_PUNCHED)
	_t22_steps(T22_WHITE, g + T22_WHITE[4])
	var pink := _t22_box(T22_PINK, g, Color("#c97a70"), T22_GREEN, S_PUNCHED)
	_t22_waves(pink, g + T22_PINK[4], Color("#c97a70"))
	_t22_garden(_t22_box(T22_PINK_LOW, g, Color("#ece7dc"), T22_GREEN, S_SLAB), g + T22_PINK_LOW[4])
	var dark := _t22_box(T22_DARK, g, Color("#3c444c"), T22_GREEN, S_FINS)
	_t22_garden(dark, g + T22_DARK[4])
	_t22_garden(_t22_box(T22_DUO, g, Color("#5e9196"), T22_GREEN, S_BANDS), g + T22_DUO[4])
	_t22_garden(_t22_box(T22_DUO_B, g, Color("#a7c2c2"), T22_GREEN, S_BANDS), g + T22_DUO_B[4])
	# Nowa Wronia: the block with the four round tanks on its roof, and Apartamenty Gutenberga
	# (two towers on a planted podium).
	var tanks := _t22_box(T22_TANKS, g, Color("#f0eee8"), Color("#cfd2d0"), S_SLAB)
	for k in 4:
		var c := _w(lerpf(T22_TANKS[0], T22_TANKS[1], (k + 0.5) / 4.0), (T22_TANKS[2] + T22_TANKS[3]) * 0.5)
		_prism(_circle(c, 4.2, 12), g + T22_TANKS[4], g + T22_TANKS[4] + 4.5, Color("#dfe9ee"), Color("#eef2f2"), M_PAVILION + 0.5, M_STONE)
	_t22_garden(_t22_box(T22_GUT, g, Color("#e8e2d6"), T22_GREEN, S_SLAB), g + T22_GUT[4])
	for t: Array in [[214.0, 238.0, 114.0, 142.0, 58.0], [252.0, 276.0, 146.0, 172.0, 50.0]]:
		_t22_garden(_t22_box(t, g + T22_GUT[4], Color("#efeae0"), T22_GREEN, S_PUNCHED), g + T22_GUT[4] + t[4])
	# Nowa Wronia's brick paving, the walk between the rows; under all of it, the finished
	# quarter's light paving where the building site's bare ground was.
	_no_roof = true
	_mode = M_STONE
	_t22_ground([0.0, 260.0, 0.0, 95.0], 0.15, Color("#cfc6b6"))
	_t22_ground([88.0, 292.0, 100.0, 222.0], 0.15, Color("#cfc6b6"))
	_t22_ground([122.0, 211.0, 222.0, 280.0], 0.15, Color("#cfc6b6"))
	_t22_ground([8.0, 122.0, 222.0, 310.0], 0.15, Color("#cfc6b6"))
	_t22_ground([8.0, 88.0, 212.0, 222.0], 0.15, Color("#cfc6b6"))
	_t22_ground([122.0, 215.0, 280.0, 314.0], 0.15, Color("#cfc6b6"))
	_t22_ground([0.0, 8.0, 95.0, 312.0], 0.15, Color("#cfc6b6"))
	_t22_ground([97.0, 282.0, 95.0, 106.0], 0.18, T22_PAVING)
	_t22_ground([102.0, 108.0, 136.0, 222.0], 0.21, T22_PAVING)
	_no_roof = false
	_t22_hall(g)
	_t22_park(g)
	_t22_octagon()
	_t22_crane(g)
	_mode = M_STONE


## A block of the superblock: walls in its skin from `y0` up its height, a flat top; the car's
## wall at street level. Returns its plan.
func _t22_box(r: Array, y0: float, wall: Color, roof: Color, style: int) -> PackedVector2Array:
	var poly := _t22_rect(r)
	_prism(poly, y0, y0 + float(r[4]), wall, roof, M_SKIN + style / 16.0, M_STONE)
	if y0 <= _g + 0.5:
		_collide(poly)
	return poly


## A green roof: the planted top and a low hedge just inside the edge.
func _t22_garden(poly: PackedVector2Array, y: float) -> void:
	var rim := Geometry2D.offset_polygon(poly, -0.8)
	if rim.size() != 1:
		return
	_mode = M_STONE
	_cap(rim[0], y + 0.15, T22_GREEN.lightened(0.06))
	var inner := Geometry2D.offset_polygon(poly, -1.6)
	if inner.size() == 1:
		_prism(inner[0], y, y + 0.9, T22_GREEN.darkened(0.15), Color(0, 0, 0, 0), M_STONE)


## The white tower's stepped top: two smaller boxes set back on the roof, as the render has.
func _t22_steps(r: Array, y: float) -> void:
	_lbox(r[0] + 9.0, r[2] + 11.0, 8.0, 9.0, y, y + 6.6, Color("#ece8e0"), M_SKIN + S_PUNCHED / 16.0, T22_GREEN)
	_lbox(r[1] - 8.0, r[3] - 9.0, 6.0, 7.0, y, y + 9.9, Color("#ece8e0"), M_SKIN + S_PUNCHED / 16.0, Color("#d8d4cc"))


## The terracotta tower's wavy crown: a parapet that rises and falls in round scallops 5 m
## apart round the roof garden (both faces, so it reads from inside the roof too).
func _t22_waves(poly: PackedVector2Array, y: float, col: Color) -> void:
	_mode = M_STONE
	var rev := PackedVector2Array(poly)
	rev.reverse()
	for ring: PackedVector2Array in [poly, rev]:
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			var n := ceili(a.distance_to(b) / 0.8)
			var out := _out(ring, a, b)
			for k in n:
				var t := (k + 0.5) / n * a.distance_to(b)
				var f := fposmod(t, 5.0) / 5.0 * 2.0 - 1.0
				var h := 1.4 + 3.2 * sqrt(maxf(0.0, 1.0 - f * f))
				_wall(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), y, y + h, out, col.darkened(0.06))
	_t22_garden(poly, y)


## The drone port on the 150 m tower (the "Warsaw of the future"): a dark pad with an amber
## ring, a drone taxi hovering over it with its rotor discs and a red light, and WARSZAWA 2050
## on the crown's two street faces (towards Rondo Daszyńskiego and towards Pańska).
func _t22_dronport(poly: PackedVector2Array, y: float) -> void:
	var c := _centre(poly)
	_mode = M_STONE
	_prism(_circle(c, 11.0, 16), y, y + 0.4, Color("#5a6066"), Color("#33383d"), M_STONE, M_STONE)
	_prism(_circle(c, 9.6, 16), y + 0.4, y + 0.45, Color("#e8a42c"), Color("#e8a42c"), M_STONE, M_STONE)
	_prism(_circle(c, 9.0, 16), y + 0.45, y + 0.5, Color("#33383d"), Color("#33383d"), M_STONE, M_STONE)
	# The pad's D, in two strokes of paint.
	_cap(PackedVector2Array([c + _a * -3.0 + _b * -3.5, c + _a * -1.6 + _b * -3.5, c + _a * -1.6 + _b * 3.5, c + _a * -3.0 + _b * 3.5]), y + 0.55, Color("#f2efe6"))
	var arc := PackedVector2Array()
	for k in 9:
		var ang := -PI * 0.5 + PI * k / 8.0
		arc.append(c + _a * (-1.6 + cos(ang) * 4.0) + _b * (sin(ang) * 3.5))
	for k in 9:
		var ang := PI * 0.5 - PI * k / 8.0
		arc.append(c + _a * (-1.6 + cos(ang) * 2.6) + _b * (sin(ang) * 2.2))
	_cap(arc, y + 0.56, Color("#f2efe6"))
	# The drone taxi, 7 m over the pad: a white cab, four arms, four rotor discs.
	var hy := y + 7.0
	_prism(_square(c, 1.4), hy, hy + 1.3, Color("#f4f4f2"), Color("#e0e2e4"), M_STONE, M_STONE)
	_prism(_square(c, 1.0), hy + 1.3, hy + 1.8, Color("#4a6b86"), Color("#4a6b86"), M_PAVILION + 0.5, M_STONE)
	for d: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		var tip := c + d.normalized() * 4.2
		_prism(PackedVector2Array([c + Vector2(-d.y, d.x).normalized() * 0.18, tip + Vector2(-d.y, d.x).normalized() * 0.18,
				tip - Vector2(-d.y, d.x).normalized() * 0.18, c - Vector2(-d.y, d.x).normalized() * 0.18]), hy + 0.9, hy + 1.15,
				Color("#2c2f33"), Color("#2c2f33"), M_STONE, M_STONE)
		_prism(_circle(tip, 1.9, 10), hy + 1.25, hy + 1.32, Color("#9aa3aa"), Color("#c3c9ce"), M_STONE, M_STONE)
	_prism(_square(c + _b * 1.45, 0.2), hy + 0.5, hy + 0.9, Color("#ff2a2a"), Color("#ff2a2a"), M_LAMP, M_LAMP)
	var k := 2.6 / (Neon.ROW_H * Neon.PIXEL)
	var west := c - _b * (T22_AFI[3] - T22_AFI[2]) * 0.5
	signs.append(["WARSZAWA 2050", Vector3(west.x, y - 5.0, west.y), Vector3(-_b.x, 0.0, -_b.y), k, T22_NEON])
	var north := c - _a * (T22_AFI[1] - T22_AFI[0]) * 0.5
	signs.append(["DRONOPORT", Vector3(north.x, y - 5.0, north.y), Vector3(-_a.x, 0.0, -_a.y), k * 0.8, T22_NEON])
	# The podium's name over Pańska.
	var front := _w(T22_PODIUM[0], (T22_PODIUM[2] + T22_PODIUM[3]) * 0.5)
	signs.append(["TOWAROWA 22", Vector3(front.x, _g + float(T22_PODIUM[4]) - 4.0, front.y), Vector3(-_a.x, 0.0, -_a.y), k * 0.7, Color(1.0, 0.82, 0.55)])


## The old printing hall (Dom Słowa Polskiego, 1950s): its steel frame kept as a yellow
## lattice over a garden (the render), and the low pavilion beside it with its round skylights.
func _t22_hall(g: float) -> void:
	var r := T22_HALL
	var top := g + float(r[4])
	_mode = M_STONE
	_no_roof = true
	# The garden under the frame: lawn and a ring of trees.
	_t22_ground([r[0] + 0.5, r[1] - 0.5, r[2] + 0.5, r[3] - 0.5], 0.26, Color("#6d8f4c"))
	for iu in 6:
		for iv in 3:
			var p := _w(lerpf(r[0] + 7.0, r[1] - 7.0, iu / 5.0), lerpf(r[2] + 9.0, r[3] - 9.0, iv / 2.0))
			var tp := p + _a * (3.0 if iv == 1 else 0.0)
			_varso_tree(tp, map.terrain_height(tp.x, tp.y), 9.0 + float((iu * 3 + iv) % 3), 3.2)
	_no_roof = false
	# Columns every 10 m along the long sides, 8 m on the ends; a top chord all round; trusses
	# across every 10 m with diagonals.
	var nu := int((r[1] - r[0]) / 10.0)
	for k in nu + 1:
		var u: float = lerpf(r[0], r[1], float(k) / nu)
		for v: float in [r[2], r[3]]:
			_lbox(u, v, 0.45, 0.45, g, top, T22_YELLOW, M_STONE, T22_YELLOW)
		# The cross truss: two chords and diagonals.
		_t22_bar(_w(u, r[2]), _w(u, r[3]), top - 0.5, top, 0.3)
		_t22_bar(_w(u, r[2]), _w(u, r[3]), top - 3.0, top - 2.5, 0.3)
		var nv := 6
		for j in nv:
			var v0: float = lerpf(r[2], r[3], float(j) / nv)
			var v1: float = lerpf(r[2], r[3], float(j + 1) / nv)
			_t22_diag(_w(u, v0), _w(u, v1), top - 2.75 if j % 2 == 0 else top - 0.25, top - 0.25 if j % 2 == 0 else top - 2.75)
	for v: float in [r[2], r[3], (r[2] + r[3]) * 0.5]:
		_t22_bar(_w(r[0], v), _w(r[1], v), top - 0.5, top, 0.3)
	_collide(_t22_rect(r))
	# The pavilion: one glazed storey under a green roof with four round skylights.
	var p := T22_PAVILION
	var pav := _t22_rect(p)
	_prism(pav, g, g + float(p[4]), Color("#8fb0bd"), T22_GREEN, M_GLASS, M_STONE)
	_collide(pav)
	for k in 4:
		var c := _w(lerpf(p[0] + 18.0, p[1] - 18.0, k / 3.0), (p[2] + p[3]) * 0.5)
		_mode = M_PAVILION + 0.5
		_frustum(_circle(c, 3.4, 12), g + float(p[4]), _circle(c, 2.6, 12), g + float(p[4]) + 1.6, Color("#d7e4ea"), Color("#e6eef0"))
	_mode = M_STONE


## A straight steel bar from a to b (plan) between two heights, `w` wide.
func _t22_bar(a: Vector2, b: Vector2, y0: float, y1: float, w: float) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * w * 0.5
	_prism(PackedVector2Array([a + n, b + n, b - n, a - n]), y0, y1, T22_YELLOW, T22_YELLOW.darkened(0.08), M_STONE, M_STONE)


## A diagonal bar in a vertical plane from (a, ya) to (b, yb).
func _t22_diag(a: Vector2, b: Vector2, ya: float, yb: float) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * 0.1  # inside the chords' 0.3 m: no shared face
	var dy := 0.25
	for s: float in [1.0, -1.0]:
		var o := n * s
		var nrm := Vector3(o.x, 0.0, o.y).normalized()
		_quad(Vector3(a.x + o.x, ya - dy, a.y + o.y), Vector3(b.x + o.x, yb - dy, b.y + o.y),
				Vector3(b.x + o.x, yb + dy, b.y + o.y), Vector3(a.x + o.x, ya + dy, a.y + o.y), nrm, T22_YELLOW)


## Park Słowa: a lawn with a looping path, a playground's soft disc and trees.
## The octagon office (see T22_OCT): a rounded octagon ring of white bands round a planted
## court, the top storey set back 2.5 m. Built on its own ground (the plot's corner sits lower).
func _t22_octagon() -> void:
	var outer := _t22_oct_ring(40.0, 13.0)
	var court := _t22_oct_ring(16.0, 6.0)
	var g0 := _ground_under(outer)
	_g = g0
	var top := g0 + float(T22_OCT[4])
	var step := top - 3.5
	var white := Color("#eeece6")
	var skin := M_SKIN + S_SLAB / 16.0
	_mode = skin
	var run := 0.0
	for i in outer.size():
		var a := outer[i]
		var b := outer[(i + 1) % outer.size()]
		_wall(a, b, g0 - 0.5, step, _out(outer, a, b), white, run)
		run += a.distance_to(b)
	var upper: PackedVector2Array = Geometry2D.offset_polygon(outer, -2.5)[0]
	run = 0.0
	for i in upper.size():
		var a := upper[i]
		var b := upper[(i + 1) % upper.size()]
		_wall(a, b, step, top, _out(upper, a, b), white, run)
		run += a.distance_to(b)
	run = 0.0
	for i in court.size():
		var a := court[i]
		var b := court[(i + 1) % court.size()]
		_wall(a, b, g0 - 0.5, top, -_out(court, a, b), white, run)
		run += a.distance_to(b)
	_mode = M_STONE
	_cap_holes(outer, [upper], step, Color("#d9d7d0"))
	_cap_holes(upper, [court], top, Color("#d9d7d0"))
	_collide(outer)
	# The court: a lawn and a ring of young trees.
	_cap(court, g0 + 0.3, T22_GREEN.lightened(0.05))
	for k in 6:
		var p := _wl(T22_OCT_C + Vector2.from_angle(TAU * k / 6.0) * 10.0)
		var gt: float = map.terrain_height(p.x, p.y)
		_prism(_square(p, 0.15), maxf(gt, g0 + 0.3) - 0.2, maxf(gt, g0 + 0.3) + 2.5, Color("#6b5a48"), Color(0, 0, 0, 0))
		_pyramid(_circle(p, 1.8, 5), maxf(gt, g0 + 0.3) + 2.2, maxf(gt, g0 + 0.3) + 6.5, T22_GREEN.darkened(0.1 * (k % 2)))


## A rounded octagon in the plan round T22_OCT_C: `half` to each side, the corners cut by `cut`
## and rounded with one extra point.
func _t22_oct_ring(half: float, cut: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 4:
		var ang := TAU * k / 4.0
		var d := Vector2.from_angle(ang)
		var s := Vector2(-d.y, d.x)
		var corner := d + s
		out.append(_wl(T22_OCT_C + d * half - s * (half - cut)))
		out.append(_wl(T22_OCT_C + d * half + s * (half - cut)))
		out.append(_wl(T22_OCT_C + corner * (half - cut * 0.42)))
	return out


func _t22_park(g: float) -> void:
	var r := T22_PARK
	_no_roof = true
	_mode = M_STONE
	_t22_ground(r, 0.26, Color("#79a052"))
	var loop := PackedVector2Array()
	var loop_in := PackedVector2Array()
	var c := _w((r[0] + r[1]) * 0.5, (r[2] + r[3]) * 0.5)
	for k in 24:
		var ang := TAU * k / 24.0
		loop.append(c + _a * cos(ang) * 30.0 + _b * sin(ang) * 18.0)
	for k in range(23, -1, -1):
		var ang := TAU * k / 24.0
		loop_in.append(c + _a * cos(ang) * 27.6 + _b * sin(ang) * 15.6)
	for k in 24:
		var k1 := (k + 1) % 24
		var mid := (loop[k] + loop_in[23 - k]) * 0.5
		_cap(PackedVector2Array([loop[k], loop[k1], loop_in[23 - k1], loop_in[23 - k]]), map.terrain_height(mid.x, mid.y) + 0.29, Color("#d8c9a8"))
	var play := c - _a * 12.0
	_cap(_circle(play, 7.0, 16), map.terrain_height(play.x, play.y) + 0.29, Color("#d0603f"))
	var pool := c + _a * 10.0 + _b * 3.0
	_cap(_circle(pool, 5.0, 16), map.terrain_height(pool.x, pool.y) + 0.29, Color("#4f8fb8"))
	for k in 14:
		var ang := TAU * k / 14.0 + 0.2
		var p := c + _a * cos(ang) * 36.0 + _b * sin(ang) * 22.0
		if Geometry2D.is_point_in_polygon(p, _t22_rect(r, -2.0)):
			_varso_tree(p, map.terrain_height(p.x, p.y), 8.0 + float(k % 3) * 1.5, 3.0)
	_no_roof = false


## The joke of the future: the last tower crane of Wola, gilded on a plinth in Park Słowa, its
## jib over the lawn; the plaque says OSTATNI ŻURAW WOLI ("the last crane of Wola").
func _t22_crane(g: float) -> void:
	var at := _w(T22_PARK[1] - 10.0, T22_PARK[2] + 9.0)
	_mode = M_STONE
	var plinth := _square(at, 2.6)
	_prism(plinth, g, g + 1.2, Color("#8d8a84"), Color("#a3a09a"), M_STONE, M_STONE)
	_collide(plinth)
	var mast := 26.0
	_prism(_square(at, 0.8), g + 1.2, g + 1.2 + mast, T22_GOLD, T22_GOLD, M_GOLD, M_GOLD)
	var y := g + 1.2 + mast
	# The cab and the slewing ring.
	_prism(_square(at + _b * 1.1, 1.0), y - 2.6, y, Color("#f2efe6"), T22_GOLD, M_STONE, M_GOLD)
	# The jib (towards the lawn, -u) and the counter-jib with its weights.
	var tip := at - _a * 22.0
	_t22_gold_bar(at + _a * 0.8, tip, y, y + 1.0)
	var back := at + _a * 8.0
	_t22_gold_bar(at, back, y, y + 0.8)
	_prism(PackedVector2Array([back - _a * 2.6 + _b * 1.0, back + _b * 1.0, back - _b * 1.0, back - _a * 2.6 - _b * 1.0]), y - 1.6, y,
			Color("#8d8a84"), Color("#8d8a84"), M_STONE, M_STONE)
	# The tower head and its ties.
	_prism(_square(at, 0.5), y, y + 4.5, T22_GOLD, T22_GOLD, M_GOLD, M_GOLD)
	# The hook block, hanging.
	var hook := at - _a * 15.0
	_prism(_square(hook, 0.06), y - 9.0, y, Color("#2c2f33"), Color(0, 0, 0, 0), M_STONE)
	_prism(_square(hook, 0.45), y - 10.0, y - 9.0, T22_GOLD, T22_GOLD, M_GOLD, M_GOLD)
	var k := 0.45 / (Neon.ROW_H * Neon.PIXEL)
	var face := at - _b * 2.65
	signs.append(["OSTATNI ŻURAW WOLI", Vector3(face.x, g + 0.35, face.y), Vector3(-_b.x, 0.0, -_b.y), k, T22_GOLD.lightened(0.3)])


func _t22_gold_bar(a: Vector2, b: Vector2, y0: float, y1: float) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * 0.55
	_prism(PackedVector2Array([a + n, b + n, b - n, a - n]), y0, y1, T22_GOLD, T22_GOLD, M_GOLD, M_GOLD)


## The courtyard between the wings (F's photo from above): the grass amphitheatre, four curved
## steps with timber edges opening east to the paved circle and the fountain, benches on the
## circle, a round corten pavilion with a planted roof, and young trees with slim crowns.
func _forest_courtyard() -> void:
	_no_roof = true
	var ga: float = map.terrain_height(FOREST_AMPH.x, FOREST_AMPH.y)
	_g = ga
	# Steps: arcs from 110 to 250 degrees (the west half; east = 0), each 1.2 m deep, 0.4 m up.
	for i in 4:
		var r0 := 4.0 + i * 1.2
		var r1 := r0 + 1.2
		var band := PackedVector2Array()
		for k in 11:
			band.append(FOREST_AMPH + Vector2.from_angle(deg_to_rad(110.0 + 14.0 * k)) * r1)
		for k in range(10, -1, -1):
			band.append(FOREST_AMPH + Vector2.from_angle(deg_to_rad(110.0 + 14.0 * k)) * r0)
		_prism(band, ga - 0.3, ga + 0.4 * (i + 1), FOREST_TIMBER.darkened(0.1), FOREST_GREEN.lightened(0.04 * i), M_STONE, M_STONE)
		if i == 3:
			_collide(band)
	# Benches on the circle in front, facing the steps.
	for k in 3:
		var p := FOREST_AMPH + Vector2.from_angle(deg_to_rad(160.0 + 20.0 * k)) * 2.2
		var t := Vector2.from_angle(deg_to_rad(250.0 + 20.0 * k))
		var o := Vector2(t.y, -t.x)
		_prism(PackedVector2Array([p - t * 0.9 - o * 0.25, p + t * 0.9 - o * 0.25, p + t * 0.9 + o * 0.25, p - t * 0.9 + o * 0.25]),
				ga, ga + 0.45, Color("#7a5a3a"), FOREST_TIMBER, M_STONE, M_STONE)
	# The pavilion: eight corten sides, a planted roof.
	var gp: float = map.terrain_height(FOREST_PAVILION.x, FOREST_PAVILION.y)
	_g = gp
	var pav := _circle(FOREST_PAVILION, 3.2, 8)
	_prism(pav, gp - 0.3, gp + 3.2, FOREST_CORTEN, FOREST_GREEN, M_STONE, M_STONE)
	_collide(pav)
	# The young trees: a slim trunk, a crown of a widening frustum and a pointed top.
	for i in FOREST_TREES.size():
		var p: Vector2 = FOREST_TREES[i]
		var gt: float = map.terrain_height(p.x, p.y)
		_g = gt
		var hsh := fposmod(sin(p.x * 3.17 + p.y * 7.31) * 43758.5453, 1.0)
		var h := 5.0 + hsh * 2.5
		var r := 1.3 + hsh * 0.6
		var leaf: Color = FOREST_LEAF[i % FOREST_LEAF.size()]
		_prism(_square(p, 0.1), gt - 0.2, gt + h * 0.4, Color("#6b5a48"), Color(0, 0, 0, 0), M_STONE)
		_mode = M_STONE
		_frustum(_circle(p, r * 0.45, 5), gt + h * 0.3, _circle(p, r, 5), gt + h * 0.6, leaf.darkened(0.1))
		_pyramid(_circle(p, r, 5), gt + h * 0.6, gt + h, leaf)
		_collide(_square(p, 0.15))
	_no_roof = false


## Gdański Business Center (Inflancka, by Dworzec Gdański; spec docs/landmarks/specs/gbc.md):
## a 74 m glass tower whose crown is cut on a slant, and the 45 m and 31 m blocks beside it,
## built from their mapped parts (the box is also bake_sectors.py SITE_AREAS). The tower is blue
## glass in a fine grid; the blocks are ten storeys of glass between white floor bands, a dark
## top floor that overhangs a little, and the tenants' logos on it (parodies: AWIWA, NIELZEN).
const GBC_BOX := Rect2(-2175.0, -2520.0, 230.0, 185.0)
const GBC_GLASS := Color("#5f86ae")
const GBC_BLOCK := Color("#7f9fa6")
const GBC_DARK := Color("#2a2d33")
const GBC_ROOF := Color("#9ba1a5")
func _find_gbc() -> void:
	var zone: Array = []
	var parts: Array = []
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() >= 3 and GBC_BOX.has_point(_centre(q)) and float(bld["h"]) >= 25.0:
			zone.append(q)
			parts.append(bld)
	_add_site("gbc", zone)
	if not sites.is_empty() and sites[-1]["key"] == "gbc":
		sites[-1]["parts"] = parts


func _build_gbc(site: Dictionary) -> void:
	var parts: Array = site["parts"]
	var tallest := 0.0
	_g = INF
	for bld in parts:
		tallest = maxf(tallest, float(bld["h"]))
		_g = minf(_g, _ground_under(_pts(bld["p"])))
	var g := _g
	var none := Color(0, 0, 0, 0)
	for bld in parts:
		var poly := _pts(bld["p"])
		var h := float(bld["h"])
		if h >= tallest - 0.5:
			# The tower: a lit lobby, blue glass in a fine grid, a crown cut on a slant with a
			# dark band under its high edge.
			var drop := 7.5
			var shoulder := g + h - drop - 3.0
			_prism(poly, g - 0.4, g + 5.0, GBC_GLASS.lightened(0.15), none, M_PAVILION)
			_prism(poly, g + 5.0, shoulder, GBC_GLASS, GBC_DARK, M_SKIN + S_GRID / 16.0, M_STONE)
			var band := Geometry2D.offset_polygon(poly, 0.35)
			var ring: PackedVector2Array = band[0] if not band.is_empty() else poly
			_sloped(_simplify(ring, 0.6), shoulder, g + h, g + h - drop, GBC_DARK, GBC_ROOF, M_STONE)
			_crown_signs(poly, g + h - drop, "AWIWA", Color(0.96, 0.97, 1.0), 2.6, 0.45)
		else:
			# A ten-storey block: lit lobby, glass between white floor bands, a dark top floor
			# that overhangs 0.5 m, a pale roof, one logo on the long faces facing the camera.
			var crown := 3.8
			_prism(poly, g - 0.4, g + 5.0, GBC_BLOCK.lightened(0.2), none, M_PAVILION)
			_prism(poly, g + 5.0, g + h - crown, GBC_BLOCK, none, M_SKIN + S_RIBBON / 16.0)
			var top := Geometry2D.offset_polygon(poly, 0.5)
			var ring: PackedVector2Array = top[0] if not top.is_empty() else poly
			_prism(ring, g + h - crown, g + h, GBC_DARK, GBC_ROOF, M_STONE, M_STONE)
			_crown_signs(ring, g + h, "NIELZEN", Color(0.9, 0.96, 1.0), 1.0, 0.4)
		_collide(poly)


## Rondo Radosława's flag (not in OpenStreetMap; the surface model's 57.8 m column in the
## island's west part): a steel mast and a big white-and-red flag in a light wind.
const FLAG_MAST := Vector2(-2850.0, -2295.0)
const FLAG_HEIGHT := 57.8
const FLAG_W := 16.0
const FLAG_H := 10.0
func _find_flag() -> void:
	_add_site("flaga", [_circle(FLAG_MAST, 2.5, 8)])


func _build_flag(_site: Dictionary) -> void:
	var c := FLAG_MAST
	_g = _ground_under(_circle(c, 1.5, 6))
	var g := _g
	var steel := Color("#c9cdd0")
	_prism(_circle(c, 1.6, 8), g - 0.3, g + 0.6, Color("#8d8a86"), Color("#8d8a86"), M_STONE, M_STONE)
	_mode = M_STONE
	_frustum(_circle(c, 0.42, 10), g + 0.6, _circle(c, 0.2, 10), g + FLAG_HEIGHT, steel, steel)
	_prism(_circle(c, 0.32, 8), g + FLAG_HEIGHT, g + FLAG_HEIGHT + 0.5, Color("#d9b24a"), Color("#d9b24a"), M_STONE, M_STONE)
	# The flag flies east from the mast in folds: strips across, each turned a little.
	var top := g + FLAG_HEIGHT - 0.6
	var strips := 8
	for k in strips:
		var x0 := 0.25 + FLAG_W * k / strips
		var x1 := 0.25 + FLAG_W * (k + 1) / strips
		var z0 := sin(k * 1.1) * 0.9 * k / strips
		var z1 := sin((k + 1) * 1.1) * 0.9 * (k + 1) / strips
		var a := Vector2(c.x + x0, c.y + z0)
		var b := Vector2(c.x + x1, c.y + z1)
		var droop0 := 0.35 * k / strips
		var droop1 := 0.35 * (k + 1) / strips
		var n := Vector3(-(b - a).y, 0.0, (b - a).x).normalized()
		for side: Vector3 in [n, -n]:
			_quad(Vector3(a.x, top - FLAG_H * 0.5 - droop0, a.y), Vector3(b.x, top - FLAG_H * 0.5 - droop1, b.y),
					Vector3(b.x, top - droop1, b.y), Vector3(a.x, top - droop0, a.y), side, Color("#f4f4f2"))
			_quad(Vector3(a.x, top - FLAG_H - droop0, a.y), Vector3(b.x, top - FLAG_H - droop1, b.y),
					Vector3(b.x, top - FLAG_H * 0.5 - droop1, b.y), Vector3(a.x, top - FLAG_H * 0.5 - droop0, a.y), side, Color("#d4213d"))
	_collide(_circle(c, 1.6, 8))


# --- Novotel Warszawa Centrum (the 1974 Forum hotel) --------------------------------------------

## F's five photos (2026-11-07: by day from the rondo, the entrance, three at night) over the mapped
## outlines (centrum.json: the tower part and the podium) and the LoD2 heights (the map pack: the
## podium's roof 8.8 m, the shaft's 92.2 m, the sign's frame to about 100 m). A white tiled slab
## 55.8 x 15.6 m, its long faces in nine 6.2 m bays of paired small windows (S_TILE's cool
## variant) with a blank strip in the middle (the lift core), its narrow ends blank round a
## projecting core bay that carries the name in blue neon, letter over letter, an orange rule and
## the chain's line under it (parodies: NOWOTEL, ACORN HOTELS); the top storey's blue glass band
## at the north end; on the roof a dark plant room and two white light boxes, one over each long
## face, with the name and the chain's line. Under it the two-storey glazed podium out to
## Marszałkowska with its canopies and lit fascia, and on the east face the entrance: a long
## cream canopy, the bowed two-step bay over the revolving door, the blue board with the name,
## a stone pier and two box planters. Local frame: u along the shaft (north, Al. Jerozolimskie,
## to south), v out of the east face; the shaft's centre is the origin.
const NV_O := Vector2(-726.0028, 509.8392)
const NV_A := Vector2(0.3328, 0.94292)
const NV_HU := 27.9          # the long faces' half length: nine bays of 6.2 m
const NV_HV := 7.8           # the shaft's half depth
const NV_PODIUM := 8.8       # LoD2: the podium's roof over the pavement
const NV_ROOF := 92.2        # LoD2: the shaft's roof (31 floors of 2.95 m from the pavement, no row cut)
const NV_DOOR := 9.0         # the entrance's middle along the east face (u)
const NV_WALL := Color("#d9dcdf")    # cool: S_TILE draws the punched windows
const NV_BLANK := Color("#dcdcdc")   # neutral: the same tiles, no windows
const NV_COPING := Color("#e9e9e6")
const NV_GLASS := Color("#5b6a73")
const NV_FASCIA := Color("#d6d4cd")
const NV_ROOF_COL := Color("#6b6e70")
const NV_PLANT := Color("#4e5357")
const NV_BOX := Color("#eef0f1")
const NV_CREAM := Color("#e4dccb")
const NV_BOARD := Color("#1d3a80")
const NV_STONE := Color("#cdbd9f")
const NV_TOP_BAND := Color("#3d6eae")
const NV_GLOW := Color("#f1e3c4")
## The shaft's plan: the slab with a core bay on each narrow end, its corners cut (the tower part).
const NV_SHAFT := [Vector2(-27.9, -7.8), Vector2(27.9, -7.8), Vector2(27.9, -6.6), Vector2(31.0, -4.3), Vector2(31.0, 4.3),
		Vector2(27.9, 6.6), Vector2(27.9, 7.8), Vector2(-27.9, 7.8), Vector2(-27.9, 6.6), Vector2(-31.0, 4.3), Vector2(-31.0, -4.3),
		Vector2(-27.9, -6.6)]
## The podium's plan (the mapped part, straightened), round the shaft's foot.
const NV_PODIUM_RING := [Vector2(-38.0, -35.1), Vector2(-38.0, -5.3), Vector2(-39.2, -5.3), Vector2(-39.2, 10.3),
		Vector2(-30.3, 10.3), Vector2(-30.3, 9.0), Vector2(-2.8, 9.0), Vector2(-2.8, 7.8), Vector2(26.2, 7.8), Vector2(26.2, 7.2),
		Vector2(31.0, 7.2), Vector2(31.0, -6.0), Vector2(30.0, -8.0), Vector2(30.0, -50.6), Vector2(-10.5, -50.4),
		Vector2(-10.5, -47.5), Vector2(-24.8, -47.9)]


func _nv_ring(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q: Vector2 in pts:
		out.append(_w(q.x, q.y))
	return out


func _build_novotel(zone: PackedVector2Array) -> void:
	_o = NV_O
	_a = NV_A
	_b = Vector2(_a.y, -_a.x)   # out of the east face
	_g = _ground_under(zone)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var skin := M_SKIN + float(S_TILE) / 16.0
	var y0 := g + NV_PODIUM
	var top := g + NV_ROOF
	# The shaft: the long faces in three pieces (windows, the core's blank 6.2 m strip, windows),
	# their run counted from the north corner so the bays line up; every other edge blank.
	var shaft := _nv_ring(NV_SHAFT)
	_mode = skin
	for side: float in [-1.0, 1.0]:
		var v := NV_HV * side
		for piece: Vector3 in [Vector3(-NV_HU, -3.1, 1.0), Vector3(-3.1, 3.1, 0.0), Vector3(3.1, NV_HU, 1.0)]:
			_wall(_w(piece.x, v), _w(piece.y, v), y0, top, _b * side, NV_WALL if piece.z > 0.5 else NV_BLANK, piece.x + NV_HU)
	_prism(shaft, y0, top, NV_BLANK, none, skin, M_STONE)
	# The top storey's blue glass band over the north end's three bays (lit cool at night), and
	# the pale coping round the roof.
	for side: float in [-1.0, 1.0]:
		var v := (NV_HV + 0.08) * side
		_mode = M_PAVILION + 0.5
		_wall(_w(-NV_HU + 0.6, v), _w(-9.3, v), top - 2.85, top - 1.55, _b * side, NV_TOP_BAND)
	_mode = M_STONE
	var coping := Geometry2D.offset_polygon(shaft, 0.12, Geometry2D.JOIN_MITER)
	if coping.size() == 1:
		_prism(coping[0], top - 0.3, top + 0.35, NV_COPING, NV_ROOF_COL, M_STONE, M_STONE)
	# The roof: the dark plant room, a lift head, the two light boxes with the name.
	_lbox(0.0, 0.0, 12.0, 4.4, top + 0.35, top + 4.6, NV_PLANT, M_STONE, NV_PLANT.darkened(0.1))
	_lbox(-17.0, 1.5, 2.6, 2.2, top + 0.35, top + 3.2, NV_PLANT, M_STONE, NV_PLANT.darkened(0.1))
	for side: float in [-1.0, 1.0]:
		var vf := (NV_HV - 0.7) * side
		_lbox(0.0, vf - 0.18 * side, 13.0, 0.18, top + 0.35, top + 8.4, NV_BOX, M_STONE, NV_BOX.darkened(0.08))
		var n := _b * side
		var n3 := Vector3(n.x, 0.0, n.y)
		var right := Vector2(n.y, -n.x)   # the way the text reads from outside
		var c := _w(0.0, vf)
		var k := 22.0 / Neon.length_of("NOWOTEL")
		signs.append(["NOWOTEL", Vector3(c.x, top + 2.6, c.y), n3, k, VSIGN_BLUE])
		var small := 0.62
		for w: Array in [["ACORN", -3.0], ["HOTELS", 2.9]]:
			var p: Vector2 = c + right * float(w[1])
			signs.append([w[0], Vector3(p.x, top + 0.9, p.y), n3, small, VSIGN_BLUE])
	# The name down each narrow end's core bay, letter over letter from two floors under the roof;
	# the orange rule and the chain's line under it (F's night photos).
	for end: float in [-1.0, 1.0]:
		var n := _a * end
		var n3 := Vector3(n.x, 0.0, n.y)
		var c := _w(31.0 * end, 0.0)
		var kv := 2.5
		var step := Neon.ROW_H * Neon.PIXEL * kv
		var y := top - 3.0
		for letter in "NOWOTEL":
			y -= step
			signs.append([letter, Vector3(c.x, y, c.y), n3, kv, VSIGN_BLUE])
		signs.append(["--", Vector3(c.x, y - 1.3, c.y), n3, 1.1, Color(1.0, 0.35, 0.15)])
		signs.append(["ACORN", Vector3(c.x, y - 3.6, c.y), n3, 0.85, VSIGN_BLUE])
		signs.append(["HOTELS", Vector3(c.x, y - 5.6, c.y), n3, 0.62, VSIGN_BLUE])
	# The podium: two glazed storeys under a pale fascia with a lit strip, its roof and plant.
	var podium := _nv_ring(NV_PODIUM_RING)
	_prism(podium, g - 0.6, y0, NV_GLASS, none, M_GLASS, M_STONE)
	var wide := Geometry2D.offset_polygon(podium, 0.2, Geometry2D.JOIN_MITER)
	if wide.size() == 1:
		_prism(wide[0], y0 - 1.1, y0 + 0.5, NV_FASCIA, NV_ROOF_COL, M_STONE, M_STONE)
		var lit := Geometry2D.offset_polygon(podium, 0.27, Geometry2D.JOIN_MITER)
		if lit.size() == 1:
			_prism(lit[0], y0 - 1.3, y0 - 1.15, NV_GLOW, none, M_LAMP)
	_mode = M_STONE
	for box: Rect2 in [Rect2(-5.9, -16.9, 14.4, 2.2), Rect2(-17.6, -22.7, 4.7, 6.9), Rect2(-31.0, -28.0, 5.0, 4.0),
			Rect2(-26.0, -41.0, 4.0, 4.0), Rect2(10.0, -42.0, 4.5, 3.5), Rect2(15.5, -12.5, 4.0, 3.5)]:
		_prism(_lrect(box), y0 + 0.5, y0 + 2.4, NV_PLANT.lightened(0.2), NV_PLANT, M_STONE, M_STONE)
	# The canopies along Marszałkowska, Al. Jerozolimskie and the south side (1.3 m, the mapped
	# roofs), and the long cream one down the east face, broken by the entrance's.
	for r: Rect2 in [Rect2(-10.5, -51.9, 40.5, 1.3), Rect2(-39.9, -35.0, 0.7, 29.7), Rect2(30.0, -50.6, 1.0, 42.6)]:
		_prism(_lrect(r), g + 4.2, g + 4.6, NV_CREAM, NV_FASCIA, M_STONE, M_STONE)
	for span: Vector2 in [Vector2(-30.3, NV_DOOR - 7.6), Vector2(NV_DOOR + 7.6, 31.0)]:
		_prism(_lrect(Rect2(span.x, NV_HV, span.y - span.x, 10.3 - NV_HV)), g + 3.9, g + 4.25, NV_CREAM, NV_FASCIA, M_STONE, M_STONE)
	# The entrance: the stone pier on its north side, the revolving door, the bowed bay over it in
	# two cream steps, the flat canopy and the blue board with the name in white, two planters.
	var fv := NV_HV
	_lbox(NV_DOOR - 6.3, fv + 0.55, 1.5, 0.55, g - 0.3, g + 4.6, NV_STONE, M_STONE, NV_STONE.darkened(0.08))
	var door := _w(NV_DOOR, fv + 0.9)
	_prism(_circle(door, 1.6, 10), g - 0.2, g + 3.0, Color("#8ea2ad"), NV_CREAM, M_PAVILION, M_STONE)
	var arcs: Array = [[Vector2(4.6, 2.9), 3.0, 3.75], [Vector2(5.8, 3.9), 3.75, 4.55]]
	for arc: Array in arcs:
		var r: Vector2 = arc[0]
		var bay := PackedVector2Array()
		for i in 9:
			var t := PI * float(i) / 8.0
			bay.append(_w(NV_DOOR + r.x * cos(t), fv + 0.05 + r.y * sin(t)))
		_prism(bay, g + float(arc[1]), g + float(arc[2]), NV_CREAM, NV_CREAM.darkened(0.04), M_STONE, M_STONE)
	_lbox(NV_DOOR, fv + 2.6, 7.6, 2.6, g + 4.55, g + 4.95, NV_CREAM, M_STONE, NV_FASCIA)
	_lbox(NV_DOOR, fv + 5.05, 7.6, 0.15, g + 4.75, g + 7.0, NV_BOARD, M_STONE, NV_BOARD.darkened(0.1))
	var bp := _w(NV_DOOR, fv + 5.2)
	var bk := 6.4 / Neon.length_of("NOWOTEL")
	signs.append(["NOWOTEL", Vector3(bp.x, g + 5.25, bp.y), Vector3(_b.x, 0.0, _b.y), bk, Color(0.96, 0.97, 1.0)])
	for u: float in [NV_DOOR - 4.2, NV_DOOR + 4.2]:
		_lbox(u, fv + 2.4, 0.5, 0.5, g - 0.2, g + 0.8, Color("#c3c4c2"), M_STONE, Color("#c3c4c2"))
		_lbox(u, fv + 2.4, 0.42, 0.42, g + 0.8, g + 1.55, Color("#3f5a34"), M_STONE, Color("#4b6a3c"))
	_mode = M_STONE
	_collide(_simplify(zone, 0.3))


# --- Cosmopolitan (Twarda 2/4; F's photos, 2026-11-08) ---------------------------------------

## Helmut Jahn's 160 m tower (2014) on Twarda, rebuilt from F's photos (refs/cosmopolitan, report
## docs/landmarks/photo-reports/cosmopolitan.md): a square shaft of dark blue-black glass in a fine
## storey grid with bronze fins at its corners; the north-west strip of it overhangs the street
## from 44 m up, and the overhang's underside is cherry red (the tower's signature, photos 2 and 4);
## under and beside it a glass podium of four storeys with a terrace roof, a long glass canopy over
## the east wing's forecourt, and a glass box set back on the overhang's corner; the top three storeys
## are an open louvred screen over the glass, with plant and a small crane on the roof.
## The plan is OpenStreetMap's: the shaft (3968), the overhanging strip (5563, 44-160 m) and the
## podium (outline and the east wing).
const CS_SHAFT := [Vector2(-1537.4, -144.5), Vector2(-1548.1, -175.5), Vector2(-1523.5, -183.9), Vector2(-1512.8, -152.8)]
## The strip that hangs out over the street, 44 m up.
const CS_STRIP := [Vector2(-1512.8, -152.8), Vector2(-1511.1, -148.2), Vector2(-1508.8, -141.2),
		Vector2(-1533.4, -132.9), Vector2(-1533.7, -134.0), Vector2(-1537.4, -144.5)]
const CS_PODIUM := 17.5     ## the podium's roof (4 storeys, OSM)
const CS_SOFFIT := 44.0     ## the overhang's red underside (OSM)
const CS_TOP := 160.0
const CS_CROWN := 13.5      ## the louvred top storeys
const CS_GLASS := Color("#3c566e")      ## dark blue-black float glass (photos 1, 2, 4)
const CS_FIN := Color("#8d7a58")        ## the bronze corner fins (photo 2, 4)
const CS_RED := Color("#c8102e")        ## the overhang's soffit: flat bright red, lit at night (F-IMG_7537, 7538)
const CS_PODIUM_GLASS := Color("#6f8d89")  ## the podium's green-grey glass, dark mullions (photos 2, 4)
const CS_LOUVRE := Color("#58564f")     ## the crown's louvres (photo 3)
const CS_CANOPY := Color("#a9c4c4")     ## the canopy's pale glass (photo 2)


func _build_cosmopolitan(zone: PackedVector2Array, spec: Dictionary) -> void:
	_g = _ground_under(zone)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var grid := M_SKIN + float(S_GRID) / 16.0
	var bands := M_SKIN + float(S_BANDS) / 16.0
	var dark := M_SKIN + float(S_DARK) / 16.0
	var frame := M_SKIN + float(S_FRAME) / 16.0
	var ribbon := M_SKIN + float(S_RIBBON) / 16.0
	var shaft := _ic_ring(CS_SHAFT)
	var strip := _ic_ring(CS_STRIP)
	# The podium: the whole mapped plot and the east wing, four glass storeys in bands, a pale terrace roof.
	_prism(zone, g - 0.4, g + CS_PODIUM, CS_PODIUM_GLASS, Color("#b6bbb9"), bands, M_STONE)
	_collide(zone)
	# The podium roof's glass parapet, 1.1 m (F-IMG_7537).
	for i in zone.size():
		var pa := zone[i]
		var pb := zone[(i + 1) % zone.size()]
		if pa.distance_to(pb) > 2.0:
			_wall(pa, pb, g + CS_PODIUM, g + CS_PODIUM + 1.1, _out(zone, pa, pb), CS_CANOPY)
	# The glass box on the terrace under the overhang, set back from the podium's edge.
	var box := Geometry2D.offset_polygon(strip, -1.4)
	if box.size() == 1:
		_prism(box[0], g + CS_PODIUM, g + CS_PODIUM + 5.0, Color("#7e9a98"), Color("#b6bbb9"), M_PAVILION + 0.5, M_STONE)
	# The shaft over the podium and the strip over the street, one glass skin; the strip's red soffit.
	_prism(shaft, g + CS_PODIUM, g + CS_TOP - CS_CROWN, CS_GLASS, none, ribbon, M_STONE)
	_prism(strip, g + CS_SOFFIT, g + CS_TOP - CS_CROWN, CS_GLASS, none, ribbon, M_STONE)
	# The shaft and the overhang are solid to the helicopter as well; the collision faces want the same
	# winding as the mapped outline's.
	for pair: Array in [[shaft, g], [strip, g + CS_SOFFIT]]:
		var ring: PackedVector2Array = pair[0]
		if Geometry2D.is_polygon_clockwise(ring) != Geometry2D.is_polygon_clockwise(zone):
			ring = PackedVector2Array(Array(ring).duplicate()); ring.reverse()
		_collide_span(ring, float(pair[1]), g + CS_TOP)
	_mode = M_LAMP
	_soffit(strip, g + CS_SOFFIT - 0.02, CS_RED)
	# A dark spandrel band at the soffit so the red reads as a deep underside, not a floor.
	var rim := Geometry2D.offset_polygon(strip, 0.08, Geometry2D.JOIN_MITER)
	if rim.size() == 1:
		_prism(rim[0], g + CS_SOFFIT, g + CS_SOFFIT + 3.4, Color("#1d2630"), none, dark, M_STONE)
	# Bronze fin pairs up the long south-west face, every 2.5 m (F-IMG_7536: gold-edged strips between black bands).
	var fa: Vector2 = CS_SHAFT[1]
	var fb: Vector2 = CS_SHAFT[2]
	var fl := fa.distance_to(fb)
	var fo := _out(shaft, fa, fb)
	var fe := (fb - fa) / fl
	for t in range(1, int(fl / 2.5)):
		var fc := fa + fe * (t * 2.5) + fo * 0.15
		_prism(_square(fc, 0.12), g + CS_PODIUM, g + CS_TOP - CS_CROWN, CS_FIN, CS_FIN, dark, M_STONE)
	# The crown: three storeys of pale silver glass, and on the east face only an open louvre cage (F-IMG_7536).
	var crown_poly := PackedVector2Array(_poly_union_box(shaft, strip))
	_prism(crown_poly, g + CS_TOP - CS_CROWN, g + CS_TOP, CS_CANOPY.lightened(0.15), none, ribbon, M_STONE)
	var ea: Vector2 = CS_SHAFT[2]
	var eb: Vector2 = CS_SHAFT[3]
	var eo := _out(shaft, ea, eb)
	var cage := PackedVector2Array([ea + eo * 0.12, eb + eo * 0.12, eb + eo * 0.6, ea + eo * 0.6])
	_prism(cage, g + CS_TOP - 6.0, g + CS_TOP, CS_LOUVRE, CS_LOUVRE, dark, M_STONE)
	_tower_roof(crown_poly, g + CS_TOP, CS_LOUVRE.lightened(0.15), Vector2(10.0, 6.0))
	# The roof's window-cleaning crane: a short mast and an arm (photo 3).
	var rc := _centre(shaft)
	_prism(_square(rc + Vector2(-3.0, 2.0), 0.4), g + CS_TOP + 1.5, g + CS_TOP + 4.2, Color("#9aa0a4"), Color("#9aa0a4"), M_STONE, M_STONE)
	_prism(PackedVector2Array([rc + Vector2(-3.4, 1.8), rc + Vector2(3.6, 1.8), rc + Vector2(3.6, 2.2), rc + Vector2(-3.4, 2.2)]),
			g + CS_TOP + 4.2, g + CS_TOP + 4.6, Color("#9aa0a4"), Color("#9aa0a4"), M_STONE, M_STONE)
	_dusk_details(spec, shaft, g, CS_TOP)


## The crown's outline: the shaft and the strip together (their shared edge is the shaft's north side).
func _poly_union_box(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	var u := Geometry2D.merge_polygons(a, b)
	return u[0] if u.size() >= 1 else a


## Widok Towers (Al. Jerozolimskie 44, 2021, 95 m), rebuilt from F's photos and night refs
## (2026-11-22, refs/widok): not one box but two slabs of dark reflective glass in a white
## aluminium grid, turned a little to each other, the north-west one to 95 m and the south-east
## one lower (~84 m), with the circulation core between them as a recessed silver slot a storey
## over the lower slab. The upper floors overhang a dark glass ground floor lit warm at night;
## both roofs carry a white parapet and grey plant, red aviation lights on the high one; the
## low podium wings keep their mapped shapes with a green roof on the Jerozolimskie corner.
const WIDOK_HIGH := 95.0
const WIDOK_LOW := 84.0
const WIDOK_CORE := 87.0
const WIDOK_LIFT := 7.0                    ## the overhang's underside
const WIDOK_GLASS := Color("#4f6878")      ## dark reflective glass (the article: black panes)
const WIDOK_CORE_GLASS := Color("#93a1aa") ## the core's slot, silver
const WIDOK_ROOF := Color("#c9ccce")
const WIDOK_BASE := Color("#2e3a42")
const WIDOK_PODIUM := Color("#56656e")
const WIDOK_GREEN := Color("#5d7247")
## The slot's two edges on the map (the outline's notches, east and west).
const WIDOK_SLOT_N := [Vector2(-750.2, 372.4), Vector2(-768.9, 378.5)]
const WIDOK_SLOT_S := [Vector2(-749.4, 378.5), Vector2(-767.0, 383.3)]


func _build_widok(zone: PackedVector2Array) -> void:
	_g = _ground_under(zone)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var grid := M_SKIN + float(S_GRID) / 16.0
	var parts := _parts_in(zone, func(b: Dictionary) -> bool: return float(b["h"]) > float(b["mh"]) + 0.5)
	var body := PackedVector2Array()
	var base := PackedVector2Array()
	for b in parts:
		var poly := _pts(b["p"])
		var h := float(b["h"])
		if h > 90.0:
			if float(b["mh"]) < 0.5:
				base = poly
			body = poly if body.is_empty() else _widok_merge(body, poly)
			continue
		if h > 20.0:
			continue  # a sliver of the core, built whole below
		if _box_of([poly]).size.length() < 3.0:
			# the canopy's slim posts along the front
			_prism(_circle(_centre(poly), 0.25, 8), g - 0.4, g + h, WIDOK_ROOF, WIDOK_ROOF, M_STONE, M_STONE)
			continue
		var top := WIDOK_GREEN if h > 14.0 else WIDOK_ROOF.darkened(0.2)
		var mode := M_STONE if str(b.get("kind", "")) == "service" else M_SKIN + float(S_DARK) / 16.0
		_prism(poly, g + float(b["mh"]) - (0.4 if float(b["mh"]) < 0.5 else 0.0), g + h, WIDOK_PODIUM, top, mode, M_STONE)
		_collide(poly)
	if body.size() < 3:
		push_warning("landmarks: Widok Towers' mapped tower is missing")
		return
	# The ground floor under the overhang: dark glass a metre in, lit warm at night.
	if base.size() >= 3:
		var lobby := Geometry2D.offset_polygon(base, -1.0)
		_prism(lobby[0] if lobby.size() == 1 else base, g - 0.4, g + WIDOK_LIFT, WIDOK_BASE, none, M_PAVILION, M_STONE)
		_collide(base)
	var n_side := _widok_half(WIDOK_SLOT_N[0], WIDOK_SLOT_N[1], true)
	var s_side := _widok_half(WIDOK_SLOT_S[0], WIDOK_SLOT_S[1], false)
	var high := _widok_cut(body, n_side)
	var low := _widok_cut(body, s_side)
	var core := _widok_cut(_widok_cut(body, _widok_half(WIDOK_SLOT_N[0], WIDOK_SLOT_N[1], false)),
			_widok_half(WIDOK_SLOT_S[0], WIDOK_SLOT_S[1], true))
	_soffit(body, g + WIDOK_LIFT, WIDOK_ROOF.darkened(0.3))
	for slab: Array in [[high, WIDOK_HIGH, Vector2(16.0, 9.0)], [low, WIDOK_LOW, Vector2(11.0, 7.0)]]:
		var poly: PackedVector2Array = slab[0]
		if poly.size() < 3:
			continue
		var top := g + float(slab[1])
		_prism(poly, g + WIDOK_LIFT, top, WIDOK_GLASS, WIDOK_ROOF, grid, M_STONE)
		_tower_roof(poly, top, WIDOK_ROOF, slab[2])
	if core.size() >= 3:
		var inset := Geometry2D.offset_polygon(core, -1.2, Geometry2D.JOIN_MITER)
		var c: PackedVector2Array = inset[0] if inset.size() == 1 else core
		_prism(c, g + WIDOK_LIFT, g + WIDOK_CORE, WIDOK_CORE_GLASS, WIDOK_ROOF, M_SKIN + float(S_BANDS) / 16.0, M_STONE)
	_collide(body)
	if high.size() >= 3:
		var roof_y := func(_q: Vector2) -> float: return g + WIDOK_HIGH + 1.5
		_aviation(high, roof_y)


## The two outlines joined (the tower's mapped part and its overhanging strips).
func _widok_merge(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	var m := Geometry2D.merge_polygons(Geometry2D.offset_polygon(a, 0.05)[0], Geometry2D.offset_polygon(b, 0.05)[0])
	var best := a
	var area := 0.0
	for r in m:
		if not Geometry2D.is_polygon_clockwise(r) or m.size() == 1:
			var ar := absf(_area(r))
			if ar > area:
				area = ar
				best = r
	return best


## A big square on one side of the line a-b: `north` the side towards -z.
func _widok_half(a: Vector2, b: Vector2, north: bool) -> PackedVector2Array:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	if (n.y < 0.0) != north:
		n = -n
	return PackedVector2Array([a - d * 200.0, b + d * 200.0, b + d * 200.0 + n * 200.0, a - d * 200.0 + n * 200.0])


## `poly` clipped to `half`, the largest piece.
func _widok_cut(poly: PackedVector2Array, half: PackedVector2Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var area := 0.0
	for r in Geometry2D.intersect_polygons(poly, half):
		var ar := absf(_area(r))
		if ar > area:
			area = ar
			best = r
	return best
