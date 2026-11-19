extends "res://scripts/landmarks/railway.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, the Vistula: the bridges'
## towers, Most Świętokrzyski, the boulevards and their dressing, the barges, the marina and Port
## Czerniakowski. Moved as it was from the one big file. landmarks.gd is the class the game makes;
## every file of game/scripts/landmarks/ is one link of its base chain (facade_kit.gd, common.gd,
## then the areas in the order of landmarks.gd's `extends` chain), so code here may use this file,
## common.gd and the facade kit, never another area: a helper two areas need goes to common.gd.
## Most Poniatowskiego's four towers, two at each end of the river span: OpenStreetMap
## maps their outlines (no heights), each twice. Loop 3b (R7): the bake seats them
## (tools/bake_structures.py `towers`: the outline by the deck, trimmed clear of the road
## corridors and lanes, base at the boulevard, deck height from the solved profile, and a
## zone of both outlines grown 6 m, so the second outline is no longer drawn as a building
## fused into the tower); the search below is the fallback for a map baked before that.
func _find_towers() -> void:
	var seated: Array = data.get("towers", [])
	if seated.size() == 4:
		var zones: Array = []
		for t: Dictionary in seated:
			zones.append(_pts(t["zone"]))
		_add_site("poniatowski", zones)
		sites[-1]["towers"] = seated
		return
	var found: Array[PackedVector2Array] = []
	for area in [Rect2(910, -165, 40, 60), Rect2(1398, -332, 45, 65)]:
		for bld in data["buildings"]:
			var q := _pts(bld["p"])
			if q.size() < 3 or not area.has_point(_centre(q)):
				continue
			var lo := q[0]
			var hi := q[0]
			for v in q:
				lo = lo.min(v)
				hi = hi.max(v)
			var span := (hi - lo).length()
			if span < 7.0 or span > 24.0:
				continue
			var same := false
			for f in found:
				if _centre(f).distance_to(_centre(q)) < 9.0:
					same = true
					break
			if not same:
				found.append(q)
	if found.size() == 4:
		var zone: Array = []
		for f in found:
			zone.append(Geometry2D.offset_polygon(f, 3.0)[0])
		_add_site("poniatowski", zone)


# --- The Powiśle boulevards: the riverside Syrenka, Dworzec Wodny, Kaskada (2026-11-01) -----------

## The Powiśle Syrenka (spec docs/landmarks/specs/syrenka_powisle.md): the baked "syrenka" point
## is where the egg stands (the boulevard footway nearest the foot of Tamka, stepped towards the
## water as eggs.gd does: 600, -697), facing the Vistula. The statue is hers now; eggs.gd keeps
## only the trigger and the floodlight.
const POWISLE_SYRENKA := Vector2(600.0, -697.0)
const POWISLE_SYRENKA_YAW := -0.861
const POWISLE_PLINTH := Color("#b9b2a2")
const POWISLE_PLINTH_HI := Color("#d3ccbb")
const WODNY_REACH := 60.0
const WODNY_AT := Vector2(632.0, -680.0)
const KASKADA_AT := Vector2(755.0, -521.0)
const BOAT_TIMBER := Color("#8e6b47")
const BOAT_TIMBER_HI := Color("#a98259")
const BOAT_GLASS := Color("#9dc0cc")


func _find_bulwary() -> void:
	_add_site("syrenka_powisle", [_circle(POWISLE_SYRENKA, 1.6, 8)])
	var wodny := _landmark_near("Dworzec Wodny", WODNY_AT, WODNY_REACH)
	if wodny.size() >= 3:
		_add_site("dworzec_wodny", [wodny])
	var kaskada := _landmark_near("Kaskada", KASKADA_AT, WODNY_REACH)
	if kaskada.size() >= 3:
		_add_site("kaskada", [kaskada])


## The statue on a low stone plinth: a footing slab, a block, a cap, then the bronze mermaid
## 1.6 times life size (it must read from the camera), sword and shield both raised.
func _build_syrenka_powisle(_site: Dictionary) -> void:
	var c := POWISLE_SYRENKA
	_g = map.terrain_height(c.x, c.y)
	var g := _g
	_mode = M_STONE
	_o = c
	_a = Vector2(-sin(POWISLE_SYRENKA_YAW), -cos(POWISLE_SYRENKA_YAW))
	_b = Vector2(-_a.y, _a.x)
	_lbox(0.0, 0.0, 1.25, 1.05, g - 0.3, g + 0.22, POWISLE_PLINTH.darkened(0.08), M_STONE, POWISLE_PLINTH)
	_lbox(0.0, 0.0, 0.85, 0.7, g + 0.22, g + 1.15, POWISLE_PLINTH, M_STONE, POWISLE_PLINTH_HI)
	_lbox(0.0, 0.0, 1.0, 0.85, g + 1.15, g + 1.38, POWISLE_PLINTH_HI, M_STONE, POWISLE_PLINTH_HI.lightened(0.04))
	_syrenka_powisle_figure(g + 1.38)
	_collide(_rect(0.0, 0.0, 1.25, 1.05))


## The bronze: the tail coiled and rising to the hips with its flukes thrown up behind, the
## torso, the head with long hair, the right arm (v negative) raising the sword high and
## a little back, the left arm lifting the round shield to her shoulder, facing out.
## `y` is the plinth's top; the local frame is _o/_a/_b (u forward, towards the water).
func _syrenka_powisle_figure(y: float) -> void:
	var bz := RYNEK_BRONZE
	var none := Color(0, 0, 0, 0)
	var pt := func(u: float, v: float, h: float) -> Vector3:
		var w := _w(u, v)
		return Vector3(w.x, y + h, w.y)
	_beam(pt.call(0.1, 0.35, 0.05), pt.call(0.3, 0.5, 0.38), 0.5, RYNEK_BRONZE_SHADE)
	_beam(pt.call(0.3, 0.5, 0.38), pt.call(-0.1, 0.3, 0.72), 0.46, bz)
	_beam(pt.call(-0.1, 0.3, 0.72), pt.call(-0.2, -0.1, 1.0), 0.42, RYNEK_BRONZE_SHADE)
	_beam(pt.call(-0.2, -0.1, 1.0), pt.call(0.0, 0.0, 1.3), 0.36, bz)
	_beam(pt.call(0.1, 0.35, 0.05), pt.call(-0.5, 0.7, 0.85), 0.13, RYNEK_BRONZE_DEEP)
	_beam(pt.call(0.1, 0.35, 0.05), pt.call(-0.6, 0.2, 0.95), 0.13, RYNEK_BRONZE_DEEP)
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 0.2, 0.26), y + 1.25, _rect(0.0, 0.0, 0.22, 0.3), y + 1.6, bz)
	_frustum(_rect(0.0, 0.0, 0.22, 0.3), y + 1.6, _rect(0.0, 0.0, 0.17, 0.25), y + 1.82, bz.lightened(0.04), bz)
	_prism(_rect(0.0, 0.0, 0.06, 0.06), y + 1.82, y + 1.92, bz, none, M_STONE)
	_prism(_rect(0.02, 0.0, 0.11, 0.1), y + 1.92, y + 2.18, bz.lightened(0.05), bz, M_STONE, M_STONE)
	_prism(_rect(-0.1, 0.0, 0.09, 0.14), y + 1.94, y + 2.24, RYNEK_BRONZE_DEEP, RYNEK_BRONZE_DEEP, M_STONE, M_STONE)
	_beam(pt.call(-0.14, 0.0, 2.05), pt.call(-0.45, 0.05, 1.35), 0.2, RYNEK_BRONZE_DEEP)
	# The sword arm: up past the head, the blade leaning back, a guard under it.
	_beam(pt.call(0.0, -0.3, 1.72), pt.call(0.04, -0.55, 2.1), 0.14, bz)
	_beam(pt.call(0.04, -0.55, 2.1), pt.call(0.0, -0.5, 2.6), 0.13, bz)
	_lbox(0.0, -0.5, 0.05, 0.3, y + 2.56, y + 2.64, RYNEK_BRONZE_SHADE, M_STONE)
	_beam(pt.call(0.0, -0.5, 2.6), pt.call(-0.2, -0.5, 3.75), 0.07, RYNEK_BRONZE_HI)
	# The shield arm: bent up, the shield at her shoulder, turned out to the water.
	_beam(pt.call(0.0, 0.3, 1.72), pt.call(0.25, 0.55, 1.88), 0.14, bz)
	var hand: Vector3 = pt.call(0.45, 0.5, 2.15)
	_beam(pt.call(0.25, 0.55, 1.88), hand, 0.13, bz)
	var face := Vector3(_a.x, 0.0, _a.y)
	_disc(hand, face, 0.5, 12, RYNEK_BRONZE_SHADE)
	_disc(hand + face * 0.03, face, 0.39, 12, RYNEK_BRONZE_HI)
	_disc(hand + face * 0.06, face, 0.12, 8, RYNEK_BRONZE_DEEP)


## A mapped outline's long axis: the local frame (_o centre, _a along the long side, _b across)
## and the half sizes (x along, y across), from its principal axis, so a rotated strip builds
## square to itself.
func _long_frame(poly: PackedVector2Array) -> Vector2:
	var c := _centre(poly)
	var best := 0.0
	var dir := Vector2.RIGHT
	for i in poly.size():
		var e := poly[(i + 1) % poly.size()] - poly[i]
		if e.length() > best:
			best = e.length()
			dir = e.normalized()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var perp := Vector2(-dir.y, dir.x)
	for q in poly:
		var d := q - c
		lo = Vector2(minf(lo.x, d.dot(dir)), minf(lo.y, d.dot(perp)))
		hi = Vector2(maxf(hi.x, d.dot(dir)), maxf(hi.y, d.dot(perp)))
	_o = c + dir * (lo.x + hi.x) * 0.5 + perp * (lo.y + hi.y) * 0.5
	_a = dir
	_b = perp
	return (hi - lo) * 0.5


## Dworzec Wodny: the Vistula's water station, a low glass-and-timber pavilion on its landing
## stage. The mapped outline (about 40 x 11 m) is the stage: a timber deck on a dark skirt, the
## glass hall on it with timber ends, posts along the water side, a flat timber-edged roof that
## overhangs, a railing round the open deck.
func _build_dworzec_wodny(site: Dictionary) -> void:
	var poly: PackedVector2Array = site["zone"][0]
	_g = _ground_under(poly)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var half := _long_frame(poly)
	var hu := half.x - 0.3
	var hv := half.y - 0.3
	_mode = M_STONE
	_prism(poly, g - 1.5, g + 0.5, Color("#4c5559"), BOAT_TIMBER, M_STONE, M_STONE)
	# The hall, a little off the middle towards the land (+v): glass between timber ends.
	var hall_u := hu - 4.5
	_lbox(0.0, 0.6, hall_u - 0.6, hv - 3.2, g + 0.5, g + 3.5, BOAT_GLASS, M_PAVILION, none)
	for s in [-1.0, 1.0]:
		_lbox(s * (hall_u - 0.3), 0.6, 0.35, hv - 3.1, g + 0.5, g + 3.55, BOAT_TIMBER, M_STONE, BOAT_TIMBER_HI)
	# The posts of the waterside front (-v) and the mullions of the hall.
	for k in 7:
		var u := lerpf(-hall_u + 0.6, hall_u - 0.6, k / 6.0)
		_lbox(u, -hv + 2.6, 0.12, 0.12, g + 0.5, g + 3.55, BOAT_TIMBER_HI, M_STONE, none)
	# The flat roof, overhanging to the water, a timber fascia, a dark membrane.
	_lbox(0.0, -0.4, hall_u + 1.2, hv - 1.4, g + 3.5, g + 3.85, BOAT_TIMBER, M_STONE, Color("#808a89"))
	# The deck's railing round its open edge (the water side and both ends), a post every 4 m.
	for s in [-1.0, 1.0]:
		_lbox(s * (hu - 0.15), 0.0, 0.05, hv, g + 0.5, g + 1.2, Color("#c9ccc9"), M_STONE, none)
	_lbox(0.0, -hv + 0.15, hu, 0.05, g + 0.5, g + 1.2, Color("#c9ccc9"), M_STONE, none)
	for k in 9:
		_lbox(lerpf(-hu, hu, k / 8.0), -hv + 0.15, 0.06, 0.06, g + 0.5, g + 1.25, BOAT_TIMBER_HI, M_STONE, none)
	_collide(poly)


## Kaskada: a vessel moored along the boulevard. The mapped outline (about 46 x 10 m, round at
## both ends) is the hull: a dark skirt under a white top strake, a timber deck, a glazed
## lounge amidships inside a rail, a flat roof with a sun deck and its awning on posts.
func _build_kaskada(site: Dictionary) -> void:
	var poly: PackedVector2Array = site["zone"][0]
	_g = _ground_under(poly)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var half := _long_frame(poly)
	_mode = M_STONE
	_prism(poly, g - 1.6, g + 0.55, Color("#2c3d4f"), none, M_STONE)
	_prism(poly, g + 0.55, g + 1.5, Color("#e5e6e2"), BOAT_TIMBER, M_STONE, M_STONE)
	var deck := Geometry2D.offset_polygon(poly, -0.9, Geometry2D.JOIN_MITER)
	if deck.is_empty():
		_collide(poly)
		return
	var lounge: PackedVector2Array = deck[0]
	var inner := Geometry2D.offset_polygon(lounge, -2.2, Geometry2D.JOIN_MITER)
	if not inner.is_empty():
		lounge = inner[0]
	_prism(lounge, g + 1.5, g + 4.4, BOAT_GLASS, none, M_PAVILION)
	_prism(Geometry2D.offset_polygon(lounge, 0.5, Geometry2D.JOIN_MITER)[0], g + 4.4, g + 4.7, Color("#e5e6e2"), Color("#6a716f"), M_STONE, M_STONE)
	# The sun deck's posts and awning over the stern half, its rail along the roof's edge.
	var hv := minf(half.y - 2.6, 3.0)
	for s in [-1.0, 1.0]:
		for k in 3:
			_lbox(-6.0 - k * 4.0, s * (hv - 0.4), 0.07, 0.07, g + 4.7, g + 6.9, BOAT_TIMBER_HI, M_STONE, none)
	_lbox(-10.0, 0.0, 6.4, hv, g + 6.9, g + 7.05, Color("#f0ede4"), M_STONE, Color("#c8282a"))
	# The bow's mast and the deck's rail posts.
	_lbox(9.0, 0.0, 0.1, 0.1, g + 4.7, g + 9.0, Color("#c9ccc9"), M_STONE, none)
	_collide(poly)


# --- Most Świętokrzyski (the landmarks loop, the user's ask 2026-10-31) --------------------------

## The cable-stayed bridge (2000): one concrete pylon on the Praga bank, in the 2.6 m median
## between the carriageways, leaning back east, and its stays in one plane along the median: a
## fan of 12 over the main span west across the river and 9 back to the east. The decks are
## map_builder's; the deck's height along the axis is its profile from the bake (a parabola
## through its crown, within about a metre). The site is the median strip under the stays, so
## every sector they cross builds them.
const SWIETO_PYLON := Vector2(737.5, -898.4)
const SWIETO_WEST := Vector2(-0.8142, 0.5806)  # along the deck, towards the Old Town bank
const SWIETO_TOP := 70.0                       # the pylon's top (map y)
const SWIETO_LEAN := 7.0                       # its top stands this far back east
const SWIETO_GREY := Color("#cfcdc6")
const SWIETO_STAY := Color("#eef0f0")
func _find_swieto() -> void:
	var across := Vector2(-SWIETO_WEST.y, SWIETO_WEST.x)
	var a := SWIETO_PYLON - SWIETO_WEST * 120.0
	var b := SWIETO_PYLON + SWIETO_WEST * 175.0
	_add_site("swieto", [PackedVector2Array([a - across * 1.2, b - across * 1.2, b + across * 1.2, a + across * 1.2])])


## The deck's top on the median at `s` metres west of the pylon.
func _swieto_deck(s: float) -> float:
	return -7.89 - 0.00007 * (s - 72.0) * (s - 72.0)


func _build_swieto(_site: Dictionary) -> void:
	var w := SWIETO_WEST
	var across := Vector2(-w.y, w.x)
	var deck := _swieto_deck(0.0)
	_g = _ground_under(_circle(SWIETO_PYLON, 2.0, 6))
	# The pylon: a tapering shaft from the ground through the deck to its top, leaning east.
	var ring := func(at: Vector2, half_along: float, half_across: float) -> PackedVector2Array:
		return PackedVector2Array([at - w * half_along - across * half_across, at + w * half_along - across * half_across,
				at + w * half_along + across * half_across, at - w * half_along + across * half_across])
	var foot: PackedVector2Array = ring.call(SWIETO_PYLON, 3.6, 1.15)
	_prism(foot, _g - 1.0, deck, SWIETO_GREY, Color(0, 0, 0, 0), M_STONE)
	var top_at := SWIETO_PYLON - w * SWIETO_LEAN
	_mode = M_STONE
	_frustum(foot, deck, ring.call(top_at, 2.0, 0.85), SWIETO_TOP, SWIETO_GREY, SWIETO_GREY.darkened(0.1))
	# The aviation light on its top, red at night.
	_prism(_circle(top_at, 0.35, 6), SWIETO_TOP, SWIETO_TOP + 0.6, Color(1.0, 0.15, 0.1), Color(1.0, 0.15, 0.1), M_LAMP, M_LAMP)
	# Solid from the ground to the top for the car under the deck, on it and the helicopter: one
	# column round the foot and the leaning top together.
	_collide_span(ring.call(SWIETO_PYLON.lerp(top_at, 0.5), 3.6 + SWIETO_LEAN * 0.5, 1.15), _g - 1.0, SWIETO_TOP)
	# The stays: anchored up the pylon's top 30 m, landing along the median.
	var shaft := func(y: float) -> Vector3:
		var t := (y - deck) / (SWIETO_TOP - deck)
		var p := SWIETO_PYLON.lerp(top_at, t)
		return Vector3(p.x, y, p.y)
	for k in 12:
		var s := 30.0 + k * 11.5
		var land := SWIETO_PYLON + w * s
		# Each stay sits a few cm to the side of the others (z-fighting fix: stays in one plane
		# share their side faces where they cross near the top).
		var off := Vector3(across.x, 0.0, across.y) * (((k * 5) % 13 - 6) * 0.035)
		_beam(shaft.call(SWIETO_TOP - 3.0 - k * 2.3) + off, Vector3(land.x, _swieto_deck(s) + 1.0, land.y) + off, 0.22, SWIETO_STAY, false)
	for k in 9:
		var s := -(22.0 + k * 10.5)
		var land := SWIETO_PYLON + w * s
		var off := Vector3(across.x, 0.0, across.y) * (((k * 5 + 4) % 13 - 6) * 0.035)
		_beam(shaft.call(SWIETO_TOP - 4.0 - k * 2.6) + off, Vector3(land.x, _swieto_deck(s) + 1.0, land.y) + off, 0.26, SWIETO_STAY, false)


# --- Most Poniatowskiego's towers ---------------------------------------------------------------

## Built from the Mac photo set (refs/poniatowski, report docs/landmarks/photo-reports/
## poniatowski.md; spec docs/landmarks/specs/poniatowski.md). Each of the four groups on the
## abutments: a crenellated arcaded pavilion along the deck's outer edge (the bake's seat, ~15 x
## 4-5 m), a square shaft at its land end standing out over the lower road, and on the south
## groups a stair turret. Heights over the deck walk: the pavilion's merlons 7.5 m, the shaft's
## cornice 16 m, the belfry's crown 19 m, the corner balls 20 m; below the deck the stone base
## runs down to the boulevard (~9.6 m).
const PT_CREAM := Color("#e8dfc8")
const PT_SHADE := Color("#cfc4a8")
const PT_BASE := Color("#b9b2a2")
const PT_DARK := Color("#3a3640")
const PT_GLASS := Color("#4a5560")
const PT_ROOF := Color("#8f8a80")
## The shaft: half size, and how far its centre stands landwards past the pavilion's land end
## (along) and out from its deck-side face (across). check_roads.py C10 mirrors these.
const PT_SHAFT := 3.5
const PT_SHAFT_U := 0.5
const PT_SHAFT_V := 3.5
## The south groups' stair turret: centre in the seat's frame (land +u, out +v), radius.
const PT_TURRET := Vector3(3.5, 9.5, 2.5)
## The north groups' switchback stair down to the boulevard (OpenStreetMap maps it on both:
## the steps out from the walk, the walls round the stair with their rounded end at v ~11.5,
## the steps back to the shaft's foot; the report's "curved ramp/stair"): a straight flight from
## the pavilion's outer face out to PT_RAMP_C.y, a ramp turning round a half circle (centre
## PT_RAMP_C, radii PT_RAMP_R, the flights as wide as the ring) and a short flight back to
## v = PT_RAMP_END by the shaft, inside parapets PT_RAMP_WALL thick that take in the mapped
## walls. check_roads.py C10 mirrors its collider (PT_RAMP_BOX: u0, u1, v1; v0 = hv).
const PT_RAMP_C := Vector2(3.0, 8.2)
const PT_RAMP_R := Vector2(0.3, 2.95)
const PT_RAMP_WALL := 0.6
const PT_RAMP_END := 5.6
const PT_RAMP_BOX := Vector3(-0.6, 6.6, 11.8)


func _build_towers(site: Dictionary) -> void:
	var seats: Array = site.get("towers", [])
	var count: int = seats.size() if not seats.is_empty() else (site["zone"] as Array).size()
	var cs: Array[Vector2] = []
	var axes: Array[Vector2] = []
	var hus: Array[float] = []
	var hvs: Array[float] = []
	var gs: Array[float] = []
	var decks: Array[float] = []
	for n in count:
		if not seats.is_empty():
			# Loop 3b (R7): the bake's seat.
			var t: Dictionary = seats[n]
			cs.append(Vector2(float(t["c"][0]), float(t["c"][1])))
			axes.append(Vector2(float(t["a"][0]), float(t["a"][1])))
			hus.append(float(t["hu"]))
			hvs.append(float(t["hv"]))
			gs.append(float(t["base"]))
			decks.append(float(t["deck"]))
			continue
		var poly: PackedVector2Array = Geometry2D.offset_polygon(site["zone"][n], -3.0)[0]
		var c := _centre(poly)
		var best := 0.0
		var ax := Vector2.RIGHT
		for i in poly.size():
			var e := poly[(i + 1) % poly.size()] - poly[i]
			if e.length() > best:
				best = e.length()
				ax = e.normalized()
		var hu := 0.0
		var hv := 0.0
		for q in poly:
			hu = maxf(hu, absf((q - c).dot(ax)))
			hv = maxf(hv, absf((q - c).dot(Vector2(-ax.y, ax.x))))
		var deck: float = map.terrain_height(c.x, c.y)
		for d in [Vector2(14, 0), Vector2(-14, 0), Vector2(0, 14), Vector2(0, -14)]:
			deck = maxf(deck, map.ground_height(c.x + d.x, c.y + d.y))
		cs.append(c)
		axes.append(ax)
		hus.append(minf(hu, 8.0))
		hvs.append(minf(hv, 3.0))
		gs.append(map.terrain_height(c.x, c.y))
		decks.append(deck)
	var mid := Vector2.ZERO
	for c in cs:
		mid += c / maxf(cs.size(), 1)
	for n in count:
		var c: Vector2 = cs[n]
		# The frame: +u towards the land, +v out away from the deck (from the pair's middle).
		var pair := c
		var near := INF
		for m in count:
			if m != n and cs[m].distance_to(c) < near:
				near = cs[m].distance_to(c)
				pair = (cs[m] + c) * 0.5
		_a = axes[n] * (1.0 if (c - mid).dot(axes[n]) > 0.0 else -1.0)
		_b = Vector2(-_a.y, _a.x)
		if (c - pair).dot(_b) < 0.0:
			_b = -_b
		_o = c
		_g = gs[n]
		_pt_group(hus[n], hvs[n], gs[n], decks[n], c.y > pair.y)


## One tower group in the frame _pt_group's caller set: the pavilion u -hu..hu, v -hv..hv
## (v = -hv the deck side), the shaft and, on a south group, the stair turret.
func _pt_group(hu: float, hv: float, g: float, deck: float, south: bool) -> void:
	var d := deck
	# The pavilion: grey stone base to the deck, cream walls, a string course, merlons to 7.5 m.
	_lbox(0.0, 0.0, hu + 0.3, hv + 0.3, g - 0.5, d, PT_BASE, M_STONE)
	_lbox(0.0, 0.0, hu, hv, d, d + 5.6, PT_CREAM, M_STONE, PT_ROOF)
	_lbox(0.0, 0.0, hu + 0.15, hv + 0.15, d + 4.5, d + 4.9, PT_SHADE, M_STONE)
	_attic(_rect(0.0, 0.0, hu, hv), d + 5.6, 1.9, PT_CREAM)
	# The arcade: round arches on short columns open to the walk; glazed arched windows to the river.
	# F's look check (2026-11-03): "strengthen the pavilion arcades": the bays read flat, so each
	# bay now stands between piers 0.35 m proud on both faces (photo 14's square piers), the walk's
	# arches open taller and wider with a keystone, and an impost band and a plinth run along.
	var bays := maxi(3, roundi(2.0 * hu / 3.0))
	var bay := 2.0 * hu / bays
	for k in bays:
		var u := -hu + (k + 0.5) * bay
		_arch_panel(_w(u, -hv), _a, -_b, bay * 0.4, d, d + 3.7 - bay * 0.4, PT_DARK, 0.04, M_STONE)
		_arch_panel(_w(u, hv), _a, _b, bay * 0.32, d + 0.9, d + 3.5 - bay * 0.32, PT_GLASS, 0.04, M_PAVILION)
		for side: float in [-1.0, 1.0]:
			_lbox(u, side * (hv + 0.12), 0.18, 0.12, d + 3.55, d + 4.15, PT_SHADE, M_STONE)
	for k in bays + 1:
		var u := -hu + k * bay
		for side: float in [-1.0, 1.0]:
			_lbox(u, side * (hv + 0.17), 0.3, 0.17, d, d + 4.5, PT_SHADE, M_STONE)
	_lbox(0.0, 0.0, hu + 0.12, hv + 0.12, d, d + 0.45, PT_BASE, M_STONE)
	_lbox(0.0, 0.0, hu + 0.08, hv + 0.08, d + 2.95, d + 3.15, PT_SHADE, M_STONE)
	for k in 2:
		var u := hu * (1.0 if k == 0 else -1.0)
		var o := _a * (1.0 if k == 0 else -1.0)
		_arch_panel(_w(u, 0.0), _b, o, minf(hv * 0.5, 1.2), d + 0.9, d + 2.8, PT_GLASS, 0.04, M_PAVILION)
	# The shaft at the land end: stone base with an arched portal to the lower road, the cream
	# shaft with small arched windows and a cornice at 16 m, the belfry with three slits a face,
	# its merlon crown to 19 m and corner balls to 20 m.
	var su := hu + PT_SHAFT_U
	var sv := -hv + PT_SHAFT_V
	var r := PT_SHAFT
	_lbox(su, sv, r + 0.3, r + 0.3, g - 0.5, d + 0.4, PT_BASE, M_STONE)
	_lbox(su, sv, r, r, d + 0.4, d + 15.3, PT_CREAM, M_STONE)
	# F's look check (2026-11-03): "strengthen the shafts". Corner piers 0.25 m proud the whole
	# height, two string courses, a corbel table under the cornice, a taller belfry and crown.
	for cu: float in [-1.0, 1.0]:
		for cv: float in [-1.0, 1.0]:
			_lbox(su + cu * (r - 0.3), sv + cv * (r - 0.3), 0.55, 0.55, d + 0.4, d + 15.3, PT_SHADE, M_STONE)
	for y: float in [d + 6.6, d + 10.9]:
		_lbox(su, sv, r + 0.32, r + 0.32, y, y + 0.35, PT_SHADE, M_STONE)
	for f in 4:
		var nu: float = [1.0, -1.0, 0.0, 0.0][f]
		var nv: float = [0.0, 0.0, 1.0, -1.0][f]
		for k in 4:
			var a := -r + 1.3 + k * (2.0 * r - 2.6) / 3.0
			var cu := su + nu * (r + 0.18) + absf(nv) * a
			var cv := sv + nv * (r + 0.18) + absf(nu) * a
			_lbox(cu, cv, 0.3, 0.3, d + 14.55, d + 15.3, PT_SHADE, M_STONE)
	_lbox(su, sv, r + 0.45, r + 0.45, d + 15.3, d + 16.0, PT_SHADE, M_STONE, PT_ROOF)
	_lbox(su, sv, r - 0.5, r - 0.5, d + 16.0, d + 18.3, PT_CREAM, M_STONE, PT_ROOF)
	_attic(_rect(su, sv, r - 0.5, r - 0.5), d + 18.3, 1.3, PT_CREAM)
	for f in 4:
		var nu: float = [1.0, -1.0, 0.0, 0.0][f]
		var nv: float = [0.0, 0.0, 1.0, -1.0][f]
		var out := _a * nu + _b * nv
		var along := Vector2(-out.y, out.x)
		var face := _w(su + nu * r, sv + nv * r)
		var belfry := _w(su + nu * (r - 0.5), sv + nv * (r - 0.5))
		for k in 3:
			_arch_panel(belfry + along * (k - 1) * 1.6, along, out, 0.36, d + 16.25, d + 17.6, PT_DARK, 0.04, M_STONE)
		_arch_panel(face, along, out, 0.7, d + 7.4, d + 9.8, PT_DARK, 0.04, M_STONE)
		for k in [-1.0, 1.0]:
			_arch_panel(face + along * k * 0.85, along, out, 0.36, d + 11.6, d + 13.0, PT_DARK, 0.04, M_STONE)
		if nv >= 0.0 and nu >= 0.0:
			_arch_panel(face, along, out, 0.42, d + 3.0, d + 4.6, PT_DARK, 0.04, M_STONE)
		if nv > 0.0 or nu > 0.0:
			# The portals under the deck, to the boulevard.
			_arch_panel(_w(su + nu * (r + 0.3), sv + nv * (r + 0.3)), along, out, 1.5, g, g + 3.0, PT_DARK, 0.04, M_STONE)
		for side in [-1.0, 1.0]:
			if f < 2:
				var ball := _w(su + nu * (r - 0.5), sv + side * (r - 0.5))
				_prism(_circle(ball, 0.32, 4), d + 19.3, d + 19.8, PT_CREAM, PT_CREAM, M_STONE, M_STONE)
				_mode = M_STONE
				_pyramid(_circle(ball, 0.32, 4), d + 19.8, d + 20.4, PT_CREAM)
	# The iron lantern on the shaft's walk-side face.
	var lamp := _w(su, sv - r - 0.4)
	_prism(_circle(lamp, 0.22, 4), d + 3.2, d + 3.8, Color("#ffd27a"), Color("#1e1e22"), M_LAMP, M_STONE)
	if south:
		# The stair turret at the foot of the flight down to the lower road.
		var tc := _w(PT_TURRET.x, PT_TURRET.y)
		_prism(_circle(tc, PT_TURRET.z, 8), g - 0.5, d + 2.0, PT_CREAM, PT_ROOF, M_STONE, M_STONE)
		_attic(_circle(tc, PT_TURRET.z, 8), d + 2.0, 1.0, PT_CREAM)
		# An iron lantern on a post on the turret's crown, over the stair's turn.
		_prism(_circle(tc, 0.1, 4), d + 2.0, d + 3.6, Color("#1e1e22"), Color("#1e1e22"), M_STONE, M_STONE)
		_prism(_circle(tc, 0.24, 4), d + 3.6, d + 4.2, Color("#ffd27a"), Color("#1e1e22"), M_LAMP, M_STONE)
		# The flight from the pavilion's outer face out to the turret (its walls and landing).
		_prism(_rect(PT_TURRET.x, (hv + PT_TURRET.y - PT_TURRET.z) * 0.5, 2.5,
				(PT_TURRET.y - PT_TURRET.z - hv) * 0.5), g - 0.5, d - 0.4, PT_BASE, PT_SHADE, M_STONE, M_STONE)
	if not south:
		_pt_ramp(hv, g, d)
	# Solid from the boulevard to over the deck (a car on either level stops at it).
	_collide_span(_rect(0.0, 0.0, hu + 0.6, hv + 0.6), g - 1.0, d + 6.0)
	_collide_span(_rect(su, sv, r + 0.3, r + 0.3), g - 1.0, d + 6.0)
	if south:
		_collide_span(_circle(_w(PT_TURRET.x, PT_TURRET.y), PT_TURRET.z, 8), g - 1.0, d + 3.0)


## A north group's switchback stair (PT_RAMP_*), in the frame _pt_group's caller set: grey stone
## treads stepping down from the walk (d) to the boulevard (g) evenly along the way, cream
## parapets a metre over them on the outer sides and a cream wall between the two flights, solid.
func _pt_ramp(hv: float, g: float, d: float) -> void:
	var c := PT_RAMP_C
	var r0 := PT_RAMP_R.x
	var r1 := PT_RAMP_R.y
	var pw := PT_RAMP_WALL * 0.5
	var w := (r1 - r0) * 0.5
	var first := c.y - hv
	var turn := PI * (r0 + r1) * 0.5
	var last := c.y - PT_RAMP_END
	var total := first + turn + last
	var drop := d - g
	# The first flight, out from the walk.
	var n1 := 8
	for k in n1:
		var v0 := hv + first * k / n1
		var v1 := hv + first * (k + 1) / n1
		var top := d - drop * (first * (k + 0.5) / n1) / total
		_prism(_rect(c.x - r0 - w, (v0 + v1) * 0.5, w, (v1 - v0) * 0.5), g - 0.5, top, PT_BASE, PT_SHADE, M_STONE, M_STONE)
		_prism(_rect(c.x - r1 - pw, (v0 + v1) * 0.5, pw, (v1 - v0) * 0.5), g - 0.5, top + 1.0, PT_CREAM, PT_SHADE, M_STONE, M_STONE)
	# The turn: a ramp round the half circle, its outer parapet following it.
	var n2 := 10
	for k in n2:
		var a0 := PI * (1.0 - float(k) / n2)
		var a1 := PI * (1.0 - float(k + 1) / n2)
		var top := d - drop * (first + turn * (k + 0.5) / n2) / total
		for ring in [[r0, r1, top, PT_BASE], [r1, r1 + PT_RAMP_WALL, top + 1.0, PT_CREAM]]:
			var ri: float = ring[0]
			var ro: float = ring[1]
			_prism(PackedVector2Array([_w(c.x + cos(a0) * ri, c.y + sin(a0) * ri), _w(c.x + cos(a0) * ro, c.y + sin(a0) * ro),
					_w(c.x + cos(a1) * ro, c.y + sin(a1) * ro), _w(c.x + cos(a1) * ri, c.y + sin(a1) * ri)]),
					g - 0.5, ring[2], ring[3], PT_SHADE, M_STONE, M_STONE)
	# The last flight, back towards the shaft's foot.
	var n3 := 4
	for k in n3:
		var v0 := c.y - last * k / n3
		var v1 := c.y - last * (k + 1) / n3
		var top := d - drop * (first + turn + last * (k + 0.5) / n3) / total
		_prism(_rect(c.x + r0 + w, (v0 + v1) * 0.5, w, (v0 - v1) * 0.5), g - 0.5, top, PT_BASE, PT_SHADE, M_STONE, M_STONE)
		_prism(_rect(c.x + r1 + pw, (v0 + v1) * 0.5, pw, (v0 - v1) * 0.5), g - 0.5, top + 1.0, PT_CREAM, PT_SHADE, M_STONE, M_STONE)
	# The wall between the flights, from the walk's height down to the turn.
	_prism(_rect(c.x, (hv + c.y) * 0.5, r0, (c.y - hv) * 0.5), g - 0.5, d - drop * first / total + 1.0, PT_CREAM, PT_SHADE, M_STONE, M_STONE)
	# Two iron lanterns light the way down (photos 14, 25: black bracket lamps on the stonework):
	# on posts on the parapet at the turn's outermost point and at the foot of the last flight.
	var apex := d - drop * (first + turn * 0.5) / total + 1.0
	var foot := d - drop * (first + turn + last) / total + 1.0
	for at in [Vector3(c.x, c.y + r1 + pw, apex), Vector3(c.x + r1 + pw, PT_RAMP_END + 0.3, foot)]:
		var lp := _w(at.x, at.y)
		_prism(_circle(lp, 0.08, 4), at.z, at.z + 1.6, Color("#1e1e22"), Color("#1e1e22"), M_STONE, M_STONE)
		_prism(_circle(lp, 0.2, 4), at.z + 1.6, at.z + 2.1, Color("#ffd27a"), Color("#1e1e22"), M_LAMP, M_STONE)
	_collide_span(_rect((PT_RAMP_BOX.x + PT_RAMP_BOX.y) * 0.5, (hv + PT_RAMP_BOX.z) * 0.5,
			(PT_RAMP_BOX.y - PT_RAMP_BOX.x) * 0.5, (PT_RAMP_BOX.z - hv) * 0.5), g - 1.0, d + 1.2)


# --- Most Poniatowskiego's towers over the railway at Warszawa Powiśle -------------------------

## The viaduct's second set of gate towers (1904-1914, the same neo-Renaissance hand as the
## river towers), where Al. Jerozolimskie starts over the cross-city line's cutting by
## Warszawa Powiśle. Built from street-level photos (Mapillary 2025-2026, refs/powisle_towers,
## refs/powisle_stw, refs/powisle_kiosk; F's Google views 2026-11-13) and GUGiK LoD2 for the
## places and heights (the footprints and tops of LoD2 2454, 2995-2997, 3318; the models drew
## them as plain blocks with flat windows). North of the deck: a slender tower by the station's
## glass pavilion and, on the square west of it, the little toilet kiosk with a Baroque scroll
## gable. South: a tower with a crenellated arcade pavilion along the walk to its west and a
## crenellated stone wing running south down the escarpment. Over the walk: the arcade's
## merlons 6.4 m, the towers' crown 16.6 m (LoD2: 19.6-19.9 m over a walk at ~3.1 m).
const PWT_AXIS := Vector2(0.947, -0.321)   # along the deck, east (towards the river)
## A tower: centre, +1 south of the deck (-1 north), half width. The north one sits 1.1 m off its
## LoD2 footprint, away from the Aleje: there the footprint reached into the kerb lane (check_drive).
const PWT_TOWERS := [[Vector2(181.94, 96.83), -1.0, 2.6], [Vector2(190.4, 124.4), 1.0, 2.8]]
const PWT_RISE := 16.6       # the crown's top over the walk
const PWT_ARCADE := Vector2(181.25, 127.3)   # centre
const PWT_ARCADE_HALF := Vector2(6.3, 2.3)    # half length (along the walk), half depth
const PWT_ARCADE_H := 5.2    # its walls over the walk (the merlons on top to PWT_ARCADE_H + 1.2)
const PWT_WING := Vector2(194.3, 136.4)      # centre
const PWT_WING_HALF := Vector2(9.4, 2.3)     # half length (south), half width
const PWT_WING_H := 6.2      # the wing's parapet over the walk (LoD2 10.1-10.8 m)
const PWT_KIOSK := Vector2(142.4, 77.7)
const PWT_KIOSK_R := 1.75    # its half width; walls to 3.6 m, the scroll gable to 5.4 m
const PWT_NEON := Color(1.0, 0.3, 0.75)   # the club's sign on the south tower ("WIEŻYCZKA", a parody)


func _find_powisle_towers() -> void:
	var zone: Array = []
	_o = Vector2.ZERO
	_a = PWT_AXIS
	_b = Vector2(-_a.y, _a.x)
	for t: Array in PWT_TOWERS:
		_o = t[0]
		zone.append(_rect(0.0, 0.0, float(t[2]) + 0.6, float(t[2]) + 0.6))
	_o = PWT_ARCADE
	zone.append(_rect(0.0, 0.0, PWT_ARCADE_HALF.x + 0.6, PWT_ARCADE_HALF.y + 0.6))
	_o = PWT_WING
	zone.append(_rect(0.0, 0.0, PWT_WING_HALF.y + 0.6, PWT_WING_HALF.x + 0.6))
	zone.append(_circle(PWT_KIOSK, PWT_KIOSK_R + 1.2, 8))
	_add_site("powisle_towers", zone)


## The walk's height by a tower or pavilion: the highest ground or deck a few metres from it
## towards the road (side = +1 when the road lies north of it).
func _pwt_walk(c: Vector2, side: float, reach: float) -> float:
	var across := Vector2(-PWT_AXIS.y, PWT_AXIS.x)   # south
	var d := -INF
	for k: float in [-1.0, 0.0, 1.0]:
		var p := c - across * side * (reach + 1.5) + PWT_AXIS * k * 2.0
		d = maxf(d, map.ground_height(p.x, p.y))
	return d


func _build_powisle_towers(_site: Dictionary) -> void:
	var south_d := 0.0
	for t: Array in PWT_TOWERS:
		var c: Vector2 = t[0]
		var side: float = t[1]
		var r: float = t[2]
		_o = c
		_a = PWT_AXIS
		# +v away from the deck.
		_b = Vector2(-_a.y, _a.x) * side
		_g = map.terrain_height(c.x, c.y)
		var d := _pwt_walk(c, side, r)
		if side > 0.0:
			south_d = d
		_pwt_tower(r, _g, d, side > 0.0)
	# The south arcade pavilion, west of the tower along the walk.
	_o = PWT_ARCADE
	_a = PWT_AXIS
	_b = Vector2(-_a.y, _a.x)
	_g = _ground_under(_rect(0.0, 0.0, PWT_ARCADE_HALF.x, PWT_ARCADE_HALF.y))
	_pwt_arcade(PWT_ARCADE_HALF.x, PWT_ARCADE_HALF.y, _g, south_d)
	# The wing down the escarpment: its own frame, +u south, +v west.
	_o = PWT_WING
	_a = Vector2(-PWT_AXIS.y, PWT_AXIS.x)
	_b = Vector2(-_a.y, _a.x)
	_g = _ground_under(_rect(0.0, 0.0, PWT_WING_HALF.x, PWT_WING_HALF.y))
	_pwt_wing(PWT_WING_HALF.x, PWT_WING_HALF.y, _g, south_d)
	_pwt_kiosk()


## One gate tower in the frame set by the caller (+v away from the deck): a stone base from the
## ground to the walk, the cream shaft with corner piers, an arched lattice portal on the walk,
## a small window, two string courses, a corbelled cornice, the belfry with three slit arches a
## face and the crown of merlons between four corner pinnacles (the photos).
func _pwt_tower(r: float, g: float, d: float, club: bool) -> void:
	var top := d + PWT_RISE
	var cor := top - 3.6      # the cornice's underside
	_lbox(0.0, 0.0, r + 0.25, r + 0.25, g - 0.5, d + 0.5, PT_BASE, M_STONE)
	_lbox(0.0, 0.0, r, r, d + 0.5, cor, PT_CREAM, M_STONE)
	for cu: float in [-1.0, 1.0]:
		for cv: float in [-1.0, 1.0]:
			_lbox(cu * (r - 0.25), cv * (r - 0.25), 0.45, 0.45, d + 0.5, cor, PT_SHADE, M_STONE)
	for y: float in [d + 5.2, d + 9.0]:
		_lbox(0.0, 0.0, r + 0.22, r + 0.22, y, y + 0.3, PT_SHADE, M_STONE)
	# The cornice on a corbel table, the belfry stage set in, its merlon crown and pinnacles.
	_lbox(0.0, 0.0, r + 0.4, r + 0.4, cor, cor + 0.55, PT_SHADE, M_STONE, PT_ROOF)
	_lbox(0.0, 0.0, r - 0.3, r - 0.3, cor + 0.55, top - 1.0, PT_CREAM, M_STONE, PT_ROOF)
	_attic(_rect(0.0, 0.0, r - 0.3, r - 0.3), top - 1.0, 1.0, PT_CREAM)
	for cu: float in [-1.0, 1.0]:
		for cv: float in [-1.0, 1.0]:
			_pinnacle(cu * (r - 0.3), cv * (r - 0.3), 0.55, top - 1.0, 1.6, PT_CREAM)
	for f in 4:
		var nu: float = [1.0, -1.0, 0.0, 0.0][f]
		var nv: float = [0.0, 0.0, 1.0, -1.0][f]
		var out := _a * nu + _b * nv
		var along := Vector2(-out.y, out.x)
		var face := _w(nu * r, nv * r)
		var belfry := _w(nu * (r - 0.3), nv * (r - 0.3))
		for k in 3:
			_arch_panel(belfry + along * (k - 1) * 1.15, along, out, 0.26, cor + 1.0, cor + 2.1, PT_DARK, 0.04, M_STONE)
		# The corbels under the cornice.
		for k in 4:
			var a := -r + 0.9 + k * (2.0 * r - 1.8) / 3.0
			_lbox(nu * (r + 0.15) + absf(nv) * a, nv * (r + 0.15) + absf(nu) * a, 0.18, 0.18, cor - 0.45, cor, PT_SHADE, M_STONE)
		# A small window over the portal stage and an arched one under the cornice.
		_lbox(nu * (r + 0.02), nv * (r + 0.02), 0.3 if nu == 0.0 else 0.04, 0.04 if nu == 0.0 else 0.3,
				d + 6.4, d + 7.6, PT_DARK, M_STONE)
		_arch_panel(face, along, out, 0.35, d + 10.4, d + 11.6, PT_DARK, 0.04, M_STONE)
		if nv < 0.0 or nu != 0.0:
			# The arched portals with their iron lattice, on the walk and through the tower.
			_arch_panel(face, along, out, minf(1.0, r - 0.9), d, d + 3.3, PT_DARK, 0.04, M_STONE)
			_arch_panel(face + out * 0.01, along, out, minf(1.0, r - 0.9) - 0.12, d + 0.03, d + 3.25, Color("#55525a"), 0.06, M_STONE)
	# Two iron lanterns on the walk face, either side of the portal, set against the wall.
	for cu: float in [-1.0, 1.0]:
		var lamp := _w(cu * (r - 0.5), -r - 0.15)
		_prism(_circle(lamp, 0.2, 4), d + 4.3, d + 4.9, Color("#ffd27a"), Color("#1e1e22"), M_LAMP, M_STONE)
	if club:
		# The club in the tower: its pink sign over the walk's portal.
		var at := _w(0.0, -r - 0.12)
		signs.append(["WIEŻYCZKA", Vector3(at.x, d + 4.2, at.y), Vector3(-_b.x, 0.0, -_b.y), 0.22, PWT_NEON])
	# The walk side's collider stops at the shaft (the base's plinth is 0.25 m proud): a bus in the
	# Aleje's kerb lane brushes the plinth's line by the north tower (check_drive).
	_collide_span(_rect(0.0, 0.15, r + 0.3, r + 0.15), g - 1.0, d + 6.0)


## The south arcade pavilion (+u along the walk, +v away from it): a stone base down to the
## ground, five round arches with dark lattice between square piers on the walk side, blind
## arches behind, an impost band, a cornice and the crenellation on top.
func _pwt_arcade(hu: float, hv: float, g: float, d: float) -> void:
	var h := d + PWT_ARCADE_H
	_lbox(0.0, 0.0, hu + 0.2, hv + 0.2, g - 0.5, d + 0.4, PT_BASE, M_STONE)
	_lbox(0.0, 0.0, hu, hv, d + 0.4, h, PT_CREAM, M_STONE, PT_ROOF)
	_lbox(0.0, 0.0, hu + 0.18, hv + 0.18, h - 0.55, h - 0.15, PT_SHADE, M_STONE)
	_attic(_rect(0.0, 0.0, hu + 0.1, hv + 0.1), h, 1.2, PT_CREAM)
	var bays := 5
	var bay := 2.0 * hu / bays
	for k in bays:
		var u := -hu + (k + 0.5) * bay
		_arch_panel(_w(u, -hv), _a, -_b, bay * 0.33, d + 0.6, d + 3.6 - bay * 0.33, PT_DARK, 0.04, M_STONE)
		_arch_panel(_w(u, hv), _a, _b, bay * 0.3, d + 1.0, d + 3.4 - bay * 0.3, PT_GLASS, 0.04, M_PAVILION)
	for k in bays + 1:
		var u := -hu + k * bay
		for side: float in [-1.0, 1.0]:
			_lbox(u, side * (hv + 0.14), 0.28, 0.14, d + 0.4, h - 0.55, PT_SHADE, M_STONE)
	_lbox(0.0, 0.0, hu + 0.08, hv + 0.08, d + 2.85, d + 3.05, PT_SHADE, M_STONE)
	_collide_span(_rect(0.0, 0.0, hu + 0.4, hv + 0.4), g - 1.0, d + 6.0)


## The wing down the escarpment along the station's cutting (+u south, away from the deck): a
## cream stone block from the ground to PWT_WING_H over the walk, arched windows in two rows
## on its long faces, string courses and the crenellation.
func _pwt_wing(hu: float, hv: float, g: float, d: float) -> void:
	var h := d + PWT_WING_H
	_lbox(0.0, 0.0, hu, hv, g - 0.5, h, PT_CREAM, M_STONE, PT_ROOF)
	_lbox(0.0, 0.0, hu + 0.15, hv + 0.15, g - 0.5, g + 1.2, PT_BASE, M_STONE)
	_lbox(0.0, 0.0, hu + 0.15, hv + 0.15, h - 0.5, h - 0.15, PT_SHADE, M_STONE)
	_attic(_rect(0.0, 0.0, hu + 0.05, hv + 0.05), h, 1.0, PT_CREAM)
	var n := maxi(3, roundi(2.0 * hu / 3.2))
	var bay := 2.0 * hu / n
	for k in n:
		var u := -hu + (k + 0.5) * bay
		for side: float in [-1.0, 1.0]:
			var out := _b * side
			_arch_panel(_w(u, side * hv), _a, out, 0.55, d + 0.8, d + 3.0, PT_DARK, 0.04, M_STONE)
			if d - g > 5.0:
				_arch_panel(_w(u, side * hv), _a, out, 0.45, g + 2.2, g + 3.8, PT_DARK, 0.04, M_STONE)
	_collide_span(_rect(0.0, 0.0, hu + 0.3, hv + 0.3), g - 1.0, d + 6.0)


## The toilet kiosk on the square west of the station (Mapillary 2025): a cream cube with an
## arched doorway, a cornice and a Baroque scroll gable on its two street faces with a
## cartouche on top.
func _pwt_kiosk() -> void:
	_o = PWT_KIOSK
	_a = PWT_AXIS
	_b = Vector2(-_a.y, _a.x)
	var r := PWT_KIOSK_R
	_g = _ground_under(_circle(PWT_KIOSK, r, 8))
	var g := _g
	_lbox(0.0, 0.0, r + 0.1, r + 0.1, g - 0.3, g + 0.4, PT_BASE, M_STONE)
	_lbox(0.0, 0.0, r, r, g + 0.4, g + 3.4, PT_CREAM, M_STONE, PT_ROOF)
	_lbox(0.0, 0.0, r + 0.22, r + 0.22, g + 3.4, g + 3.75, PT_SHADE, M_STONE, PT_ROOF)
	for cu: float in [-1.0, 1.0]:
		for cv: float in [-1.0, 1.0]:
			_lbox(cu * (r - 0.15), cv * (r - 0.15), 0.25, 0.25, g + 0.4, g + 3.4, PT_SHADE, M_STONE)
	# The scroll gables: a stepped curve of three slabs, the cartouche and a ball on top.
	for f in 2:
		var nv: float = -1.0 if f == 0 else 1.0
		for s in 3:
			var hw := r * (0.95 - s * 0.27)
			var y0 := g + 3.75 + s * 0.45
			_lbox(0.0, nv * (r - 0.15), hw, 0.15, y0, y0 + 0.45, PT_CREAM, M_STONE)
		_lbox(0.0, nv * (r - 0.05), 0.42, 0.06, g + 3.9, g + 4.6, PT_SHADE, M_STONE)
		var out := _b * nv
		_arch_panel(_w(0.0, nv * r), _a, out, 0.55, g + 0.4, g + 2.4, PT_DARK, 0.04, M_STONE)
	_lbox(0.0, 0.0, r - 0.3, r - 0.3, g + 3.75, g + 4.1, PT_ROOF, M_STONE)
	var ball := _w(0.0, 0.0)
	_lbox(0.0, 0.0, 0.1, 0.1, g + 4.1, g + 5.1, PT_SHADE, M_STONE)   # the ball's stem
	_prism(_circle(ball, 0.2, 4), g + 5.1, g + 5.4, PT_CREAM, PT_CREAM, M_STONE, M_STONE)
	_collide(_rect(0.0, 0.0, r + 0.1, r + 0.1))


# --- The river's barges (2026-11-01, docs/landmarks/specs/barki.md) ---------------------------

## OSM name (or "" for the unnamed one) -> site key; the unnamed white barge is told apart by
## where it lies (the northernmost "boat" by the Old Town, at river km 512).
const BARGE_NAMES := {"Wieczór nad Wisłą": "barka_wieczor", "Marina Warszawa": "barka_marina", "Kaskada": "barka_kaskada"}
const BARGE_WHITE_AT := Vector2(-465.0, -1848.0)
## Per barge: hull, antifouling band, deck timber, the deckhouse's frame, its glass, the roof,
## the umbrellas, the neon word and tube, where the deckhouse sits along the hull (u0, u1 as
## fractions of the length from the -u end), and whether its roof is a terrace with umbrellas.
const BARGE_STYLE := {
	"barka_wieczor": {"hull": Color("#1f2f4a"), "band": Color("#7a2a22"), "deck": Color("#9a7451"),
			"frame": Color("#eef0ee"), "glass": Color("#5d7f8f"), "roof": Color("#b48a62"),
			"brella": Color("#efe6cf"), "word": "WIECZOREK", "tube": Color(1.0, 0.62, 0.25),
			"house": Vector2(0.38, 0.86), "terrace": true, "stalls": 0},
	"barka_biala": {"hull": Color("#ecebe6"), "band": Color("#3c4148"), "deck": Color("#a07a55"),
			"frame": Color("#f4f4f1"), "glass": Color("#6a8894"), "roof": Color("#d8d6cf"),
			"brella": Color("#ffffff"), "word": "BARKA", "tube": Color(0.25, 0.85, 1.0),
			"house": Vector2(0.70, 0.95), "terrace": true, "stalls": 3},
	# The two-deck white party barge below Most Świętokrzyski (F's photo, 2026-11-02): a white
	# lower storey with warm windows, an open upper deck behind a railing under a canopy, bulbs.
	"barka_marina": {"hull": Color("#f1f2ef"), "band": Color("#1d3557"), "deck": Color("#b08a60"),
			"frame": Color("#f5f4ee"), "glass": Color("#b9805a"), "roof": Color("#e9e7e1"),
			"brella": Color("#22406b"), "word": "MARINKA", "tube": Color(1.0, 0.55, 0.3),
			"house": Vector2(0.14, 0.92), "terrace": true, "stalls": 0, "canopy": true},
	# Majami Wawa's floating pontoon (F's photos, 2026-11-07): a white two-storey pontoon, glass
	# below, an open upper deck with navy planks behind a white tube railing, orange lifebuoys.
	"port_majami": {"hull": Color("#f3f3f0"), "band": Color("#1d2f52"), "deck": Color("#23324f"),
			"frame": Color("#f7f7f4"), "glass": Color("#7d98a4"), "roof": Color("#24345a"),
			"brella": Color("#f2f0ea"), "word": "MAJAMI", "tube": Color(1.0, 0.45, 0.35),
			"house": Vector2(0.12, 0.78), "terrace": true, "stalls": 0},
	"barka_kaskada": {"hull": Color("#1c1d1f"), "band": Color("#5b2320"), "deck": Color("#6f5a46"),
			"frame": Color("#e6e6e2"), "glass": Color("#3d4f58"), "roof": Color("#2a2b2e"),
			"brella": Color("#26272a"), "word": "KASKADKA", "tube": Color(1.0, 1.0, 1.0),
			"house": Vector2(0.08, 0.72), "terrace": false, "stalls": 0},
}
const BARGE_FREEBOARD := 1.0   # the deck over the water
const BARGE_DRAFT := 0.5       # the hull's bottom under the water (into the river bed's drape)
const BARGE_BAND := 0.3        # the antifouling band's top over the water
const BARGE_HOUSE_H := 2.8     # the deckhouse's glass storey
const BARGE_ROOF := 0.25       # its roof slab
const BARGE_RAIL := 1.0        # bulwarks and railings
const BARGE_GANG_W := 1.4      # the gangway's width

const BARGE_FLAG_W := Color("#f2f2f2")
const BARGE_FLAG_R := Color("#d4213d")
const BARGE_STALLS := [Color("#e8b431"), Color("#d4483b"), Color("#3f9a76")]
## The houseboats' cabins: painted timber.
const HOUSEBOAT_WALLS := [Color("#6e4f3a"), Color("#4b6b7a"), Color("#c9c1ad"), Color("#7b8a5e"), Color("#9a4d3c")]


func _find_barges() -> void:
	var homes: Array[PackedVector2Array] = []
	var white_d := INF
	var white := PackedVector2Array()
	var named := {}
	for bld in data.get("buildings", []):
		var kind := str(bld.get("kind", ""))
		if kind != "boat" and kind != "houseboat":
			continue
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		if kind == "houseboat":
			homes.append(q)
			continue
		var name := str(bld.get("name", ""))
		if BARGE_NAMES.has(name):
			named[BARGE_NAMES[name]] = q
		elif name == "" and _centre(q).distance_to(BARGE_WHITE_AT) < white_d:
			white_d = _centre(q).distance_to(BARGE_WHITE_AT)
			white = q
	if white_d < 30.0:
		named["barka_biala"] = white
	for key: String in ["barka_wieczor", "barka_biala", "barka_marina", "barka_kaskada"]:
		if not named.has(key):
			continue
		var q: PackedVector2Array = named[key]
		_add_site(key, [_largest(Geometry2D.offset_polygon(q, 1.0, Geometry2D.JOIN_MITER))])
		if not sites.is_empty() and sites[-1]["key"] == key:
			sites[-1]["frame"] = _barge_frame(q)
	if not homes.is_empty():
		var zone: Array = []
		var frames: Array = []
		for q in homes:
			zone.append(_largest(Geometry2D.offset_polygon(q, 0.8, Geometry2D.JOIN_MITER)))
			frames.append(_barge_frame(q))
		_add_site("houseboats", zone)
		if not sites.is_empty() and sites[-1]["key"] == "houseboats":
			sites[-1]["frames"] = frames


## An outline's smallest oriented box: [centre, u axis (the long one), v axis, half u, half v].
func _barge_frame(poly: PackedVector2Array) -> Array:
	var best := INF
	var out: Array = []
	for i in poly.size():
		var e := poly[(i + 1) % poly.size()] - poly[i]
		if e.length() < 0.5:
			continue
		var a := e.normalized()
		var b := Vector2(-a.y, a.x)
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for p in poly:
			var l := Vector2(p.dot(a), p.dot(b))
			lo = Vector2(minf(lo.x, l.x), minf(lo.y, l.y))
			hi = Vector2(maxf(hi.x, l.x), maxf(hi.y, l.y))
		var size := hi - lo
		if size.x * size.y >= best:
			continue
		best = size.x * size.y
		var c := a * (lo.x + hi.x) * 0.5 + b * (lo.y + hi.y) * 0.5
		if size.x >= size.y:
			out = [c, a, b, size.x * 0.5, size.y * 0.5]
		else:
			out = [c, b, -a, size.y * 0.5, size.x * 0.5]
	return out


## Set the local frame from a barge's box and return the water's level under it (the lowest
## ground under its corners and centre: the river's drape, not the bank's).
func _barge_set(f: Array) -> float:
	_o = f[0]
	_a = f[1]
	_b = f[2]
	var hu: float = f[3]
	var hv: float = f[4]
	var g := INF
	for p in [_w(0.0, 0.0), _w(-hu, -hv), _w(hu, -hv), _w(hu, hv), _w(-hu, hv)]:
		g = minf(g, map.terrain_height(p.x, p.y))
	_g = g
	return g


## The hull's plan: the box with its ends raked (chamfered corners).
func _barge_hull(hu: float, hv: float, r: float) -> PackedVector2Array:
	return PackedVector2Array([_w(-hu, -hv + r), _w(-hu + r, -hv), _w(hu - r, -hv), _w(hu, -hv + r),
			_w(hu, hv - r), _w(hu - r, hv), _w(-hu + r, hv), _w(-hu, hv - r)])


## Which long side faces the bank (+1 or -1): the side whose points lie less far into the water.
func _barge_shore_side(hu: float, hv: float) -> float:
	if not map.has_method("shore_distance"):
		return 1.0
	var plus := 0.0
	var minus := 0.0
	for u in [-hu * 0.5, 0.0, hu * 0.5]:
		var p := _w(u, hv + 4.0)
		var m := _w(u, -hv - 4.0)
		plus += map.shore_distance(p.x, p.y)
		minus += map.shore_distance(m.x, m.y)
	return 1.0 if plus <= minus else -1.0


## A low wall (a bulwark, a railing) round a local rectangle, `t` thick, with a gap from gu0 to
## gu1 on the side v = gs * v1 (gs 0: none). The long sides run the whole length, the ends fit
## between them, so no two tops overlap.
func _barge_rail(u0: float, u1: float, v0: float, v1: float, y: float, h: float, t: float, col: Color,
		gs := 0.0, gu0 := 0.0, gu1 := 0.0) -> void:
	var top := col.lightened(0.1)
	for side: float in [-1.0, 1.0]:
		var vc := (v1 - t * 0.5) if side > 0.0 else (v0 + t * 0.5)
		if gs != 0.0 and signf(gs) == side and gu1 > gu0:
			if gu0 - u0 > 0.3:
				_lbox((u0 + gu0) * 0.5, vc, (gu0 - u0) * 0.5, t * 0.5, y, y + h, col, M_STONE, top)
			if u1 - gu1 > 0.3:
				_lbox((gu1 + u1) * 0.5, vc, (u1 - gu1) * 0.5, t * 0.5, y, y + h, col, M_STONE, top)
		else:
			_lbox((u0 + u1) * 0.5, vc, (u1 - u0) * 0.5, t * 0.5, y, y + h, col, M_STONE, top)
	for end: float in [-1.0, 1.0]:
		var uc := (u1 - t * 0.5) if end > 0.0 else (u0 + t * 0.5)
		_lbox(uc, (v0 + v1) * 0.5, t * 0.5, (v1 - v0) * 0.5 - t, y, y + h, col, M_STONE, top)


## A bar counter at a local spot (half sizes hu, hv): dark timber under a light top.
func _barge_bar(u: float, v: float, hu: float, hv: float, y: float, wood: Color) -> void:
	_lbox(u, v, hu, hv, y, y + 1.1, wood.darkened(0.35), M_STONE, wood.lightened(0.25))


## A festoon of warm bulbs from p to q, sagging `sag` in the middle: the wire in short pieces
## and a bulb at every joint (they glow at night: M_LAMP).
func _barge_festoon(p: Vector3, q: Vector3, sag: float, n: int) -> void:
	var prev := p
	for k in range(1, n + 1):
		var t := float(k) / n
		var at := p.lerp(q, t) - Vector3.UP * sag * 4.0 * t * (1.0 - t)
		_beam(prev, at, 0.03, BARGE_POST, false)
		if k < n:
			var keep := _mode
			_mode = M_LAMP
			var col := BARGE_BULB if k % 2 == 0 else BARGE_BULB_2
			var sq := PackedVector2Array([Vector2(at.x - 0.07, at.z - 0.07), Vector2(at.x + 0.07, at.z - 0.07),
					Vector2(at.x + 0.07, at.z + 0.07), Vector2(at.x - 0.07, at.z + 0.07)])
			_prism(sq, at.y - 0.16, at.y - 0.02, col, col, M_LAMP, M_LAMP)
			_mode = keep
		prev = at


## A post for the festoons at a local spot, from y up h.
func _barge_post(u: float, v: float, y: float, h: float) -> Vector3:
	_prism(_rect(u, v, 0.05, 0.05), y, y + h, BARGE_POST, BARGE_POST, M_STONE, M_STONE)
	var p := _w(u, v)
	return Vector3(p.x, y + h, p.y)


## The gangway from the deck's edge at u on side s out to the bank: a timber ramp with two
## handrails, from the first dry point the water map knows (4 m when it knows none).
func _barge_gangway(u: float, s: float, hv: float, deck: float) -> void:
	var reach := 4.0
	var bank := deck
	if map.has_method("shore_distance"):
		var t := 0.5
		while t <= 24.0:
			var p := _w(u, s * (hv + t))
			if map.shore_distance(p.x, p.y) <= 0.05:
				reach = t + 1.0
				var e := _w(u, s * (hv + reach))
				bank = clampf(map.terrain_height(e.x, e.y) + 0.05, deck - 1.5, deck + 2.5)
				break
			t += 0.5
	var w := BARGE_GANG_W * 0.5
	var a0 := _w(u - w, s * hv)
	var a1 := _w(u + w, s * hv)
	var b0 := _w(u - w, s * (hv + reach))
	var b1 := _w(u + w, s * (hv + reach))
	var p0 := Vector3(a0.x, deck + 0.05, a0.y)
	var p1 := Vector3(a1.x, deck + 0.05, a1.y)
	var q0 := Vector3(b0.x, bank, b0.y)
	var q1 := Vector3(b1.x, bank, b1.y)
	var up := (q0 - p0).cross(p1 - p0).normalized()
	if up.y < 0.0:
		up = -up
	var down := Vector3.UP * 0.18
	var wood := Color("#8a6a4c")
	_mode = M_STONE
	_quad(p0, p1, q1, q0, up, wood)
	var side := Vector3(_a.x, 0.0, _a.y)
	_quad(p0 - down, q0 - down, q0, p0, -side, wood.darkened(0.3))
	_quad(p1 - down, q1 - down, q1, p1, side, wood.darkened(0.3))
	for e: Array in [[p0, q0], [p1, q1]]:
		var ps: Vector3 = e[0]
		var qs: Vector3 = e[1]
		_beam(ps, ps + Vector3.UP * 1.0, 0.05, BARGE_POST)
		_beam(qs, qs + Vector3.UP * 1.0, 0.05, BARGE_POST)
		_beam(ps + Vector3.UP * 1.0, qs + Vector3.UP * 1.0, 0.05, Color("#c9ccd0"))


func _build_barge(site: Dictionary) -> void:
	var f: Array = site["frame"]
	var sty: Dictionary = BARGE_STYLE[site["key"]]
	var g := _barge_set(f)
	var hu: float = f[3]
	var hv: float = f[4]
	var none := Color(0, 0, 0, 0)
	var deck := g + BARGE_FREEBOARD
	var r := minf(1.6, hv * 0.4)
	# The hull: the antifouling band at the waterline, the hull's paint, the timber deck.
	var hull := _barge_hull(hu, hv, r)
	_prism(hull, g - BARGE_DRAFT, g + BARGE_BAND, sty["band"], none, M_STONE)
	_prism(hull, g + BARGE_BAND, deck, sty["hull"], sty["deck"], M_STONE, M_STONE)
	_collide(hull)
	var s := _barge_shore_side(hu, hv)
	# The deckhouse: glass between the frame's mullions, the roof slab on a small overhang.
	var hs: Vector2 = sty["house"]
	var u0 := -hu + 2.0 * hu * hs.x
	var u1 := -hu + 2.0 * hu * hs.y
	var hvh := hv - 0.8
	var house := _rect((u0 + u1) * 0.5, 0.0, (u1 - u0) * 0.5, hvh)
	var top := deck + BARGE_HOUSE_H
	_prism(house, deck, top, sty["glass"], none, M_PAVILION)
	_mode = M_STONE
	_mullions(house, deck, top, 1.8, 0.05, sty["frame"])
	var roof := _rect((u0 + u1) * 0.5, 0.0, (u1 - u0) * 0.5 + 0.25, hvh + 0.25)
	_prism(roof, top, top + BARGE_ROOF, sty["frame"], sty["roof"], M_STONE, M_STONE)
	var terr := top + BARGE_ROOF
	# The open deck's bulwark round the hull, a gap for the gangway on the bank's side.
	var gu := (-hu + r + u0) * 0.5 if u0 + hu > 5.0 else (u1 + hu - r) * 0.5
	var gw := BARGE_GANG_W * 0.5 + 0.1
	var rail: Color = (sty["hull"] as Color).lightened(0.06) if (sty["hull"] as Color).v < 0.5 else sty["band"]
	_barge_rail(-hu + r, hu - r, -hv + 0.05, hv - 0.05, deck, BARGE_RAIL, 0.12, rail,
			s, gu - gw, gu + gw)
	_barge_gangway(gu, s, hv, deck)
	# The open decks either side of the deckhouse: tables under umbrellas, a bar on the longer one.
	var fore := Vector2(-hu + r + 0.6, u0 - 0.5)
	var aft := Vector2(u1 + 0.5, hu - r - 0.6)
	var big := fore if fore.y - fore.x >= aft.y - aft.x else aft
	for span: Vector2 in [fore, aft]:
		var length := span.y - span.x
		if length < 3.5:
			continue
		var stalls: int = sty["stalls"] if span == big else 0
		if span == big:
			# The bar across the open deck's house end, its back to the deckhouse.
			var bu := span.y - 0.8 if span == fore else span.x + 0.8
			_barge_bar(bu, 0.0, 0.35, minf(hv - 1.6, 2.4), deck, sty["deck"])
		# Food stalls along the bank's side (the white barge): coloured kiosks with a lit hatch.
		for k in stalls:
			var su := span.x + 1.6 + k * 3.6
			if su + 1.4 > span.y - 2.0:
				break
			var col: Color = BARGE_STALLS[k % BARGE_STALLS.size()]
			_lbox(su, -s * (hv - 1.4), 1.3, 0.9, deck, deck + 2.4, col, M_STONE, col.darkened(0.15))
			var h0 := _w(su - 0.8, -s * (hv - 2.35))
			var h1 := _w(su + 0.8, -s * (hv - 2.35))
			var keep := _mode
			_mode = M_LAMP
			_quad(Vector3(h0.x, deck + 1.0, h0.y), Vector3(h1.x, deck + 1.0, h1.y), Vector3(h1.x, deck + 1.9, h1.y),
					Vector3(h0.x, deck + 1.9, h0.y), Vector3(_b.x, 0.0, _b.y) * s, BARGE_BULB)
			_mode = keep
		# Tables under umbrellas in a row or two.
		var start := span.x + (1.6 + stalls * 3.6 if stalls > 0 else 1.6)
		var stop := span.y - (2.2 if span == big else 1.4)
		var rows: Array = [0.0] if hv < 4.0 else [-hv * 0.45, hv * 0.45]
		if stalls > 0:
			rows = [s * hv * 0.3]
		var u := start
		while u <= stop:
			for v: float in rows:
				_barge_umbrella(u, v, deck, minf(1.3, hv * 0.38), sty["brella"])
			u += 3.2
		# The festoons over this deck: posts at its outer corners, strings to the deckhouse.
		var outer := span.x + 0.3 if span == fore else span.y - 0.3
		var inner := span.y if span == fore else span.x
		var pa := _barge_post(outer, -hv + 0.35, deck + BARGE_RAIL, 2.2)
		var pb := _barge_post(outer, hv - 0.35, deck + BARGE_RAIL, 2.2)
		var ia := _w(inner, -hvh)
		var ib := _w(inner, hvh)
		_barge_festoon(pa, pb, 0.35, 6)
		_barge_festoon(pa, Vector3(ib.x, top - 0.1, ib.y), 0.5, 7)
		_barge_festoon(pb, Vector3(ia.x, top - 0.1, ia.y), 0.5, 7)
	# The roof: a sun terrace behind a railing (umbrellas and a bar), or a plain roof with the
	# festoons strung over it on four posts.
	var tu0 := u0 - 0.15
	var tu1 := u1 + 0.15
	var tv := hvh + 0.15
	var canopy_top := terr
	if sty["terrace"]:
		_barge_rail(tu0, tu1, -tv, tv, terr, BARGE_RAIL, 0.08, sty["frame"])
		_barge_bar(tu1 - 1.0, 0.0, 0.3, minf(tv - 1.0, 2.0), terr, sty["deck"])
		var u := tu0 + 1.8
		while u <= tu1 - 2.8 and not sty.get("canopy", false):
			for v: float in ([0.0] if hv < 4.0 else [-tv * 0.5, tv * 0.5]):
				_barge_umbrella(u, v, terr, minf(1.2, tv * 0.42), sty["brella"])
			u += 3.4
		if sty.get("canopy", false):
			# The upper deck's canopy: slim posts every 2.6 m along both long sides, a pale roof
			# slab with a small overhang, and bulbs strung along its eaves; tables under it.
			var ch := 2.6
			canopy_top = terr + ch + 0.2
			var pu := tu0 + 0.4
			while pu <= tu1 - 0.3:
				for sd: float in [-1.0, 1.0]:
					_prism(_rect(pu, sd * (tv - 0.12), 0.05, 0.05), terr, terr + ch, sty["frame"], sty["frame"], M_STONE, M_STONE)
				pu += 2.6
			_prism(_rect((tu0 + tu1) * 0.5, 0.0, (tu1 - tu0) * 0.5 + 0.4, tv + 0.3), terr + ch, canopy_top,
					sty["frame"], sty["roof"], M_STONE, M_STONE)
			for sd: float in [-1.0, 1.0]:
				_barge_festoon(Vector3(_w(tu0, sd * (tv + 0.2)).x, terr + ch - 0.05, _w(tu0, sd * (tv + 0.2)).y),
						Vector3(_w(tu1, sd * (tv + 0.2)).x, terr + ch - 0.05, _w(tu1, sd * (tv + 0.2)).y), 0.3, maxi(6, roundi((tu1 - tu0) / 1.8)))
			var tu := tu0 + 2.0
			while tu <= tu1 - 3.2:
				for v: float in [-tv * 0.5, tv * 0.5]:
					_lbox(tu, v, 0.45, 0.45, terr, terr + 0.75, Color("#3a3029"), M_STONE, Color("#5a4a3c"))
				tu += 2.8
	if not sty.get("canopy", false):
		var posts: Array[Vector3] = []
		for c: Vector2 in [Vector2(tu0 + 0.3, -tv + 0.3), Vector2(tu1 - 0.3, -tv + 0.3), Vector2(tu1 - 0.3, tv - 0.3), Vector2(tu0 + 0.3, tv - 0.3)]:
			posts.append(_barge_post(c.x, c.y, terr, 2.6))
		var n := maxi(5, roundi((tu1 - tu0) / 2.5))
		_barge_festoon(posts[0], posts[1], 0.45, n)
		_barge_festoon(posts[3], posts[2], 0.45, n)
		_barge_festoon(posts[0], posts[2], 0.6, n + 1)
	# A flagpole at the -u end with the white-and-red flag.
	var fp := _barge_post(-hu + r + 0.4, 0.0, deck, 4.2)
	var fd := Vector3(_b.x, 0.0, _b.y) * 1.2
	_mode = M_STONE
	var nf := Vector3(_a.x, 0.0, _a.y)
	_quad(fp - Vector3.UP * 0.4, fp - Vector3.UP * 0.4 + fd, fp + fd, fp, nf, BARGE_FLAG_W)
	_quad(fp - Vector3.UP * 0.8, fp - Vector3.UP * 0.8 + fd, fp - Vector3.UP * 0.4 + fd, fp - Vector3.UP * 0.4, nf, BARGE_FLAG_R)
	# The name in neon standing on the roof's edge, on the face the game's camera sees most
	# (BEHIND_FACE, as the other landmarks' signs): on the river's north-south run that is the
	# deckhouse's southern end, read by whoever drives up the boulevard.
	var word: String = sty["word"]
	var best := -INF
	var at := Vector2.ZERO
	var out := Vector2.ZERO
	var room := 0.0
	for face: Array in [[_a, _w(u1 + 0.11, 0.0), 2.0 * hvh], [-_a, _w(u0 - 0.11, 0.0), 2.0 * hvh],
			[_b, _w((u0 + u1) * 0.5, hvh + 0.11), u1 - u0], [-_b, _w((u0 + u1) * 0.5, -hvh - 0.11), u1 - u0]]:
		var d := (face[0] as Vector2).dot(BEHIND_FACE)
		if d > best:
			best = d
			out = face[0]
			at = face[1]
			room = face[2]
	var k := minf(0.5, (room - 1.0) / Neon.length_of(word))
	var nrm := Vector3(out.x, 0.0, out.y)
	var base := canopy_top + 0.3 if sty.get("canopy", false) else terr + (BARGE_RAIL if sty["terrace"] else 0.0)
	signs.append([word, Vector3(at.x, base + 0.02, at.y), nrm, k, sty["tube"]])


## The houseboats: a short steel hull, a timber cabin with a band of windows and a flat roof on a
## small overhang, a railing round the open deck at one end.
func _build_houseboats(site: Dictionary) -> void:
	var none := Color(0, 0, 0, 0)
	var i := 0
	for f: Array in site["frames"]:
		var g := _barge_set(f)
		_walls.clear()
		_caps.clear()
		var hu: float = f[3]
		var hv: float = f[4]
		var deck := g + 0.6
		var r := minf(0.9, hv * 0.35)
		var hull := _barge_hull(hu, hv, r)
		_prism(hull, g - 0.4, g + 0.15, Color("#3a2b26"), none, M_STONE)
		_prism(hull, g + 0.15, deck, Color("#2d3238"), Color("#8f7255"), M_STONE, M_STONE)
		_collide(hull)
		var wall: Color = HOUSEBOAT_WALLS[i % HOUSEBOAT_WALLS.size()]
		i += 1
		var c0 := -hu + r + maxf(1.5, hu * 0.5)
		var c1 := hu - r * 0.5
		var cv := hv - 0.35
		var cab := _rect((c0 + c1) * 0.5, 0.0, (c1 - c0) * 0.5, cv)
		_prism(cab, deck, deck + 2.5, wall, none, M_STONE)
		# The windows: a glass band proud of the long walls (lit at night).
		for sd: float in [-1.0, 1.0]:
			var w0 := _w(c0 + 0.6, sd * (cv + 0.03))
			var w1 := _w(c1 - 0.6, sd * (cv + 0.03))
			var keep := _mode
			_mode = M_PAVILION
			_quad(Vector3(w0.x, deck + 0.9, w0.y), Vector3(w1.x, deck + 0.9, w1.y), Vector3(w1.x, deck + 2.0, w1.y),
					Vector3(w0.x, deck + 2.0, w0.y), Vector3(_b.x, 0.0, _b.y) * sd, Color("#6b8794"))
			_mode = keep
		_prism(_rect((c0 + c1) * 0.5, 0.0, (c1 - c0) * 0.5 + 0.3, cv + 0.3), deck + 2.5, deck + 2.7,
				wall.darkened(0.3), Color("#3b3f44"), M_STONE, M_STONE)
		_barge_rail(-hu + r, c0 - 0.05, -hv + 0.05, hv - 0.05, deck, 0.9, 0.06, Color("#c9ccd0"))


# --- The sailing marina in Port Czerniakowski (2026-11-02, spec docs/landmarks/specs/przystan.md) ---

## F's ask: the "przystań dla żaglówek" at the harbour on the Czerniakowska bank. OpenStreetMap
## maps its club house as an unnamed 14 m "building" standing in the water at the dam's west end,
## and the finger piers of the small south basin only as footpaths. The model: the club house on
## its outline (white walls, a glazed upper floor, a red hipped roof, a flagpole, a neon name),
## lit pier-end lamps, sailboats berthed between the fingers and along the dam, and more on
## buoys in the big basin, all bows to the wind. Built from the map's own outline and the water
## map (no photos in the cloud: the Mac check settles colours and the berth count).
const MARINA_AT := Vector2(1588.5, 1589.0)  # inside the unnamed club house
const MARINA_BOX := Rect2(1535.0, 1480.0, 130.0, 215.0)
## Berths between the fingers: centre z of each slip, and the x of its boats' centres.
const MARINA_SLIPS := [[1641.2, [1601.0, 1611.5]], [1647.2, [1601.0, 1611.0]], [1652.8, [1601.5, 1610.5]], [1658.5, [1601.5, 1608.0]]]
## Boats lying along the dam's north face (z, x) and on buoys in the basin (x, z).
const MARINA_DAM := [Vector2(1593.0, 1614.2), Vector2(1604.5, 1614.2), Vector2(1616.0, 1614.2), Vector2(1627.5, 1614.2), Vector2(1639.0, 1614.4)]
const MARINA_BUOYS := [Vector2(1618.0, 1470.0), Vector2(1640.0, 1492.0), Vector2(1620.0, 1515.0), Vector2(1645.0, 1535.0),
		Vector2(1624.0, 1556.0), Vector2(1598.0, 1530.0), Vector2(1636.0, 1572.0), Vector2(1604.0, 1580.0)]
const MARINA_LAMPS := [Vector2(1621.0, 1638.6), Vector2(1620.0, 1644.8), Vector2(1615.0, 1650.1), Vector2(1617.0, 1655.9), Vector2(1611.0, 1661.7)]
const MARINA_HULLS := [Color("#f2f2ee"), Color("#1f3a5f"), Color("#f2f2ee"), Color("#a3262a"), Color("#e8e0c8"), Color("#2e6e6a"), Color("#f2f2ee"), Color("#3b3f46")]
const MARINA_WALL := Color("#efeee8")
const MARINA_ROOF := Color("#a4412e")
const MARINA_TRIM := Color("#1f3a5f")
const MARINA_NEON := Color(0.3, 0.75, 1.0)
const MARINA_WIND := Vector2(0.45, -0.89)  # the boats' bows: into the wind from the north-north-east


func _find_marina() -> void:
	var q := _tallest_at(MARINA_AT)
	if q.size() < 3:
		return
	var zone: Array = [_largest(Geometry2D.offset_polygon(q, 1.0, Geometry2D.JOIN_MITER))]
	# Tiny zones at the corners of the marina's extent keep the site's box over every boat (a
	# site's zone drops what stands in it, and nothing's centre stands in a 0.2 m square).
	for c: Vector2 in [MARINA_BOX.position, MARINA_BOX.end, Vector2(MARINA_BOX.position.x, MARINA_BOX.end.y),
			Vector2(MARINA_BOX.end.x, MARINA_BOX.position.y)]:
		zone.append(PackedVector2Array([c, c + Vector2(0.2, 0.0), c + Vector2(0.2, 0.2), c + Vector2(0.0, 0.2)]))
	_add_site("marina", zone)
	if not sites.is_empty() and sites[-1]["key"] == "marina":
		sites[-1]["club"] = q


# --- Port Czerniakowski: the spit and the basin (F, 2026-11-07, his photos port-czerniakowski) ---

## F's ask: design the spit and the harbour properly. Photos: GUGiK aerials, the club's terrace
## and pontoon, WTW's gate and boathouse, the basin, its boats and houseboats
## (/mnt/project-files/port-czerniakowski/). OpenStreetMap draws every building on the spit as a
## default 14 m block. Here:
## - The tip's block becomes MAJAMI WAWA, the parody of the open-air club: a dark timber deck
##   behind a heavy railing under the willows, a red-orange stretch tent and a beige one,
##   festoons, two fire pits, a bar with thatched umbrellas, and its white floating pontoon on
##   the river side.
## - WTW's boathouse is long, white and low under a shallow cobalt roof, with the white hexagon
##   sign and a blue gate on Zaruskiego.
## - The other blocks become low halls with pitched roofs, white or grey under blue-grey and grey
##   metal, as the aerials show.
## - The basin gets boats moored stern-to along both quays between finger piers, motorboats with a
##   few sailboats, and houseboats along the west quay.
const PORT_TIP := Vector2(1404.0, 687.0)
const PORT_WTW := Vector2(1420.0, 794.0)
## The other blocks on the spit (a point in each): eaves height, wall, roof. The order follows the
## aerial from north to south: the white kayak hangar with the blue ridge, then the halls.
const PORT_HALLS := [
	[Vector2(1395.0, 755.0), 4.3, Color("#efefea"), Color("#e9ebee")],
	[Vector2(1420.0, 805.0), 4.5, Color("#d9d6cf"), Color("#7f93a6")],
	[Vector2(1429.0, 825.0), 4.0, Color("#cfcac0"), Color("#8d949b")],
	[Vector2(1425.0, 835.0), 4.8, Color("#d4d0c6"), Color("#76889a")],
	[Vector2(1450.0, 864.0), 5.0, Color("#e2dfd6"), Color("#7a8fa3")],
	[Vector2(1456.0, 890.0), 4.2, Color("#d9d3c6"), Color("#8b9198")],
	[Vector2(1468.0, 883.0), 4.6, Color("#e6e3dc"), Color("#6f8396")],
]
const PORT_WTW_WALL := Color("#f1f1ec")
const PORT_WTW_ROOF := Color("#1f4fb0")
const PORT_WTW_BLUE := Color("#2457b8")
## WTW's gate on Zaruskiego (the service road east of the boathouse) and the street's run there.
const PORT_WTW_GATE := Vector2(1437.5, 789.0)
const PORT_WTW_ALONG := Vector2(0.43, 0.9)
## The basin's run (z) and the strip of x to search for its water.
const PORT_BASIN_Z := Vector2(728.0, 992.0)
const PORT_BASIN_X := Vector2(1318.0, 1400.0)
const PORT_SLIP := 4.6          # stern-to berths: one boat per this many metres of quay
const PORT_TIMBER := Color("#8a6a4c")
const PORT_DECK := Color("#4e3a2c")       # Majami's dark terrace planks
const PORT_TENT_RED := Color("#d2492c")
const PORT_TENT_BEIGE := Color("#cdbf9f")
const PORT_STRAW := Color("#c9a764")
const PORT_HOUSEBOATS := [Color("#3a3d42"), Color("#8f969c"), Color("#2c2f33")]
const PORT_COPPER := Color("#b26a3a")


func _find_port() -> void:
	var tip := _tallest_at(PORT_TIP)
	if tip.size() >= 3:
		var zone: Array = [_largest(Geometry2D.offset_polygon(tip, 1.0, Geometry2D.JOIN_MITER))]
		_add_site("port_majami", zone)
		if not sites.is_empty() and sites[-1]["key"] == "port_majami":
			sites[-1]["tip"] = tip
			sites[-1]["box"] = (sites[-1]["box"] as Rect2).grow(45.0)
	var wtw := _tallest_at(PORT_WTW)
	if wtw.size() >= 3:
		_add_site("port_wtw", [_largest(Geometry2D.offset_polygon(wtw, 1.0, Geometry2D.JOIN_MITER))])
		if not sites.is_empty() and sites[-1]["key"] == "port_wtw":
			sites[-1]["hall"] = wtw
			sites[-1]["box"] = (sites[-1]["box"] as Rect2).grow(12.0)
	var zone: Array = []
	var halls: Array = []
	for h: Array in PORT_HALLS:
		var q := _tallest_at(h[0])
		if q.size() < 3 or q == wtw:
			continue
		zone.append(_largest(Geometry2D.offset_polygon(q, 0.8, Geometry2D.JOIN_MITER)))
		halls.append([q, h[1], h[2], h[3]])
	if not zone.is_empty():
		_add_site("port_halls", zone)
		if not sites.is_empty() and sites[-1]["key"] == "port_halls":
			sites[-1]["halls"] = halls
	# The basin: tiny zones at the corners of its extent keep the site's box over every boat.
	var b := Rect2(PORT_BASIN_X.x, PORT_BASIN_Z.x, PORT_BASIN_X.y - PORT_BASIN_X.x, PORT_BASIN_Z.y - PORT_BASIN_Z.x)
	var corners: Array = []
	for c: Vector2 in [b.position, b.end, Vector2(b.position.x, b.end.y), Vector2(b.end.x, b.position.y)]:
		corners.append(PackedVector2Array([c, c + Vector2(0.2, 0.0), c + Vector2(0.2, 0.2), c + Vector2(0.0, 0.2)]))
	_add_site("port_basin", corners)


## A low hall on a mapped outline: walls up to `h`, a pitched metal roof along its long side
## with a small overhang, the gable ends in the wall's colour.
func _port_hall(q: PackedVector2Array, h: float, wall: Color, roof: Color, rise := 1.6) -> float:
	var none := Color(0, 0, 0, 0)
	var f := _barge_frame(q)
	if f.is_empty():
		return -INF
	_barge_set(f)
	var hu: float = f[3]
	var hv: float = f[4]
	var g := INF
	var top := -INF
	for p in q:
		var t: float = map.terrain_height(p.x, p.y)
		g = minf(g, t)
		top = maxf(top, t)
	_g = g
	var eave := top + h
	_prism(q, g - 0.3, eave, wall, none, M_STONE)
	_collide(q)
	# The plinth band and a band of windows along the long sides.
	_prism(_largest(Geometry2D.offset_polygon(q, 0.06, Geometry2D.JOIN_MITER)), g - 0.3, top + 0.45, wall.darkened(0.35), none, M_STONE)
	_gable(hu + 0.35, -hu - 0.35, 0.0, hv + 0.45, eave, minf(rise, hv * 0.5), wall, roof)
	return eave


func _build_port_halls(site: Dictionary) -> void:
	for h: Array in site["halls"]:
		var eave := _port_hall(h[0], h[1], h[2], h[3])
		# The kayak hangar's blue ridge stripe (the aerial's white roof with a blue line).
		if h == site["halls"][0] and eave > -INF:
			var f := _barge_frame(h[0])
			var hu: float = f[3]
			var hv: float = f[4]
			var rise := minf(1.6, (hv + 0.45) * 0.5)
			_mode = M_STONE
			_prism(_rect(0.0, 0.0, hu + 0.35, 0.35), eave + rise - 0.05, eave + rise + 0.08, PORT_WTW_BLUE, PORT_WTW_BLUE, M_STONE, M_STONE)


## WTW's boathouse: long, white and low under a shallow cobalt roof with a raised middle; a band of
## windows; on Zaruskiego the white hexagon sign on two posts, the blue gate and two blue anchors.
func _build_port_wtw(site: Dictionary) -> void:
	var q: PackedVector2Array = site["hall"]
	var eave := _port_hall(q, 3.6, PORT_WTW_WALL, PORT_WTW_ROOF, 0.9)
	if eave == -INF:
		return
	var f := _barge_frame(q)
	var hu: float = f[3]
	var hv: float = f[4]
	_mode = M_STONE
	# The arch over the middle of the roof (the club's raised entrance bay).
	_prism(_rect(0.0, 0.0, minf(4.0, hu * 0.25), hv + 0.5), eave, eave + 1.6, PORT_WTW_WALL, PORT_WTW_ROOF, M_STONE, M_STONE)
	# Windows: a dark band on both long sides.
	for sd: float in [-1.0, 1.0]:
		var a := _w(-hu + 1.0, sd * (hv + 0.03))
		var b := _w(hu - 1.0, sd * (hv + 0.03))
		_mode = M_PAVILION
		_quad(Vector3(a.x, eave - 2.2, a.y), Vector3(b.x, eave - 2.2, b.y), Vector3(b.x, eave - 0.9, b.y), Vector3(a.x, eave - 0.9, a.y),
				Vector3(_b.x, 0.0, _b.y) * sd, Color("#5f7c8c"))
	_mode = M_STONE
	# The gate on Zaruskiego, in a frame of its own: u along the street, +v towards it.
	_o = PORT_WTW_GATE
	_a = PORT_WTW_ALONG
	_b = Vector2(PORT_WTW_ALONG.y, -PORT_WTW_ALONG.x)
	var g: float = map.terrain_height(_o.x, _o.y)
	_g = g
	for k in 14:
		var u := -4.5 + k * 0.7
		_lbox(u, 0.0, 0.06, 0.06, g, g + 1.9, PORT_WTW_BLUE, M_STONE)
	_lbox(0.0, 0.0, 4.6, 0.05, g + 1.75, g + 1.9, PORT_WTW_BLUE, M_STONE)
	_lbox(0.0, 0.0, 4.6, 0.05, g + 0.2, g + 0.32, PORT_WTW_BLUE, M_STONE)
	# The hexagon sign on two posts beside the gate, facing the street.
	var su := 6.8
	for du: float in [-0.9, 0.9]:
		_lbox(su + du, 0.0, 0.08, 0.08, g, g + 3.4, Color("#e8e8e4"), M_STONE)
	var sp := _w(su, 0.12)
	var n := Vector3(_b.x, 0.0, _b.y)
	_disc(Vector3(sp.x, g + 3.6, sp.y), n, 1.6, 6, Color("#f6f6f2"))
	_disc(Vector3(sp.x, g + 3.6, sp.y) + n * 0.08, n, 1.35, 6, PORT_WTW_BLUE)
	signs.append(["WTW", Vector3(sp.x, g + 3.25, sp.y) + n * 0.14, n, 0.36, Color(0.95, 0.97, 1.0)])
	# Two big blue anchors on slabs either side of the gate: a shank, a stock, two flukes.
	for du: float in [-6.4, 9.6]:
		var c := 1.2
		_lbox(du, c, 0.9, 0.6, g, g + 0.2, Color("#9c9a94"), M_STONE)
		_lbox(du, c, 0.12, 0.12, g + 0.2, g + 2.3, PORT_WTW_BLUE, M_STONE)
		_lbox(du, c, 0.75, 0.1, g + 2.0, g + 2.15, PORT_WTW_BLUE, M_STONE)
		for side: float in [-1.0, 1.0]:
			var a0 := _w(du, c)
			var a1 := _w(du + side * 0.75, c)
			_beam(Vector3(a0.x, g + 0.3, a0.y), Vector3(a1.x, g + 0.9, a1.y), 0.14, PORT_WTW_BLUE)


## MAJAMI WAWA at the spit's tip: the dark timber terrace on the mapped outline, its railing,
## the two tents, festoons on posts, two fire pits on the grass, a bar under thatched umbrellas,
## and the white floating pontoon on the river side (a BARGE_STYLE barge on a frame of its own).
func _build_port_majami(site: Dictionary) -> void:
	var q: PackedVector2Array = site["tip"]
	var pf := _port_pontoon_frame(q)
	if not pf.is_empty():
		_build_barge({"key": "port_majami", "frame": pf})
	var f := _barge_frame(q)
	if f.is_empty():
		return
	_barge_set(f)
	var hu: float = f[3]
	var hv: float = f[4]
	var top := -INF
	for p in q:
		top = maxf(top, map.terrain_height(p.x, p.y))
	var deck := top + 0.6
	_prism(q, _g - 0.3, deck, PORT_DECK.darkened(0.25), PORT_DECK, M_STONE, M_STONE)
	_barge_rail(-hu + 0.2, hu - 0.2, -hv + 0.2, hv - 0.2, deck, 1.0, 0.14, Color("#5b4434"), 1.0, -1.5, 1.5)
	# The red-orange stretch tent over the north half, the beige one over the south half: low
	# pyramids on four slim poles.
	for t: Array in [[-hu * 0.45, PORT_TENT_RED, 4.2], [hu * 0.45, PORT_TENT_BEIGE, 5.4]]:
		var cu: float = t[0]
		var tu := minf(4.5, hu * 0.42)
		var tv := minf(3.8, hv * 0.7)
		for c: Vector2 in [Vector2(cu - tu, -tv), Vector2(cu + tu, -tv), Vector2(cu + tu, tv), Vector2(cu - tu, tv)]:
			_lbox(c.x, c.y, 0.06, 0.06, deck, deck + 2.6, Color("#d8d4cc"), M_STONE)
		_mode = M_STONE
		_frustum(_rect(cu, 0.0, tu + 0.3, tv + 0.3), deck + 2.5, _rect(cu, 0.0, 0.5, 0.5), deck + float(t[2]), t[1], t[1])
		# Tables and wicker sofas under it.
		for k in 3:
			_lbox(cu - tu * 0.6 + k * tu * 0.6, 0.0, 0.45, 0.45, deck, deck + 0.72, Color("#3a3029"), M_STONE, Color("#6b5a48"))
	# The bar with thatched umbrellas at the deck's west end.
	_barge_bar(0.0, -hv + 1.4, minf(3.0, hu * 0.3), 0.4, deck, Color("#7a5a3e"))
	for k in 3:
		_barge_umbrella(-hu * 0.6 + k * hu * 0.6, hv - 1.8, deck, 1.3, PORT_STRAW)
	# Festoons over the deck on six posts round its edge.
	var posts: Array[Vector3] = []
	for c: Vector2 in [Vector2(-hu + 0.5, -hv + 0.5), Vector2(0.0, -hv + 0.5), Vector2(hu - 0.5, -hv + 0.5),
			Vector2(hu - 0.5, hv - 0.5), Vector2(0.0, hv - 0.5), Vector2(-hu + 0.5, hv - 0.5)]:
		posts.append(_barge_post(c.x, c.y, deck, 3.4))
	for k in 6:
		_barge_festoon(posts[k], posts[(k + 1) % 6], 0.5, 7)
	_barge_festoon(posts[1], posts[4], 0.7, 8)
	# Two round steel fire pits on the grass beyond the deck's river end, glowing at night.
	for k in 2:
		var fp := _w(hu + 3.0, (k - 0.5) * 4.0)
		var fg: float = map.terrain_height(fp.x, fp.y)
		_g = fg
		_prism(_circle(fp, 0.45, 8), fg, fg + 0.45, Color("#2e2b28"), Color("#2e2b28"), M_STONE, M_STONE)
		var keep := _mode
		_mode = M_LAMP
		_prism(_circle(fp, 0.3, 6), fg + 0.45, fg + 0.6, Color(1.0, 0.5, 0.2), Color(1.0, 0.55, 0.25), M_LAMP, M_LAMP)
		_mode = keep
		for d: float in [-1.0, 1.0]:
			var ch := fp + Vector2(d * 1.4, 0.4)
			_g = map.terrain_height(ch.x, ch.y)
			_prism(_circle(ch, 0.35, 6), _g, _g + 0.4, Color("#d9cdb4"), Color("#e6dcc4"), M_STONE, M_STONE)
	_collide(q)
	_g = top
	# The name in neon on the deck's railing towards the camera.
	var best := -INF
	var at := Vector2.ZERO
	var out := Vector2.ZERO
	for face: Array in [[_a, _w(hu + 0.1, 0.0)], [-_a, _w(-hu - 0.1, 0.0)], [_b, _w(0.0, hv + 0.1)], [-_b, _w(0.0, -hv - 0.1)]]:
		var d := (face[0] as Vector2).dot(BEHIND_FACE)
		if d > best:
			best = d
			out = face[0]
			at = face[1]
	signs.append(["MAJAMI WAWA", Vector3(at.x, deck + 1.05, at.y), Vector3(out.x, 0.0, out.y), 0.42, Color(1.0, 0.45, 0.35)])


## Where Majami's pontoon floats: off the tip on the river side, its long side along the bank, in
## water at least 2 m deep in the water map's sense (shore_distance), clear of the race pontoon.
func _port_pontoon_frame(q: PackedVector2Array) -> Array:
	if not map.has_method("shore_distance"):
		return []
	var c := _centre(q)
	var hu := 7.0
	var hv := 2.8
	for ang_deg: float in [-35.0, -55.0, -15.0, -75.0, 5.0]:
		var d := Vector2(cos(deg_to_rad(ang_deg)), sin(deg_to_rad(ang_deg)))
		var t := 8.0
		while t < 70.0:
			var p := c + d * t
			if map.shore_distance(p.x, p.y) > hv + 1.5:
				# The long side along the bank: across the way out.
				var a := Vector2(-d.y, d.x)
				var ok := true
				for k: Vector2 in [Vector2(-hu, -hv), Vector2(hu, -hv), Vector2(hu, hv), Vector2(-hu, hv)]:
					var w := p + a * k.x + d * k.y
					if map.shore_distance(w.x, w.y) < 1.0 or w.distance_to(Vector2(1464.0, 703.0)) < 14.0:
						ok = false
				if ok:
					return [p + d * 1.0, a, d, hu, hv]
				break
			t += 1.0
	return []


## The basin's boats: along both quays, stern-to between finger piers, every PORT_SLIP m; along
## the west quay's north end three houseboats instead. Each quay is found from the water map:
## for each slip's z, the first and last wet x across PORT_BASIN_X.
func _build_port_basin(_site: Dictionary) -> void:
	if not map.has_method("shore_distance"):
		return
	var n := 0
	var z := PORT_BASIN_Z.x
	var homes := 0
	while z <= PORT_BASIN_Z.y:
		var lo := INF
		var hi := -INF
		var x := PORT_BASIN_X.x
		while x <= PORT_BASIN_X.y:
			if map.shore_distance(x, z) > 0.4:
				lo = minf(lo, x)
				hi = maxf(hi, x)
			x += 0.5
		if hi - lo >= 14.0 and hi - lo <= 90.0:
			for side: float in [-1.0, 1.0]:
				var quay := lo if side < 0.0 else hi
				var into := -side  # from the quay into the water
				if side < 0.0 and z < PORT_BASIN_Z.x + 60.0 and homes < 3 and n % 3 == 0:
					var hc := Vector2(quay + into * 3.2, z)
					if map.shore_distance(hc.x, hc.y) > 1.6:
						_port_houseboat(hc, homes)
						homes += 1
						n += 1
						continue
				# An empty berth now and then, and lengths that don't repeat in step with the colours.
				if (n * 7 + int(z)) % 11 == 0:
					n += 1
					continue
				var blen := 5.2 + 0.9 * float((n * 5) % 4) + (2.5 if n % 13 == 6 else 0.0)
				var c := Vector2(quay + into * (0.8 + blen * 0.5), z)
				if hi - lo < 2.0 * blen + 8.0 or map.shore_distance(c.x, c.y) < 0.9:
					continue
				_port_finger(Vector2(quay, z + PORT_SLIP * 0.5), Vector2(into, 0.0), blen * 0.8)
				if n % 5 == 2:
					_sailboat(c, Vector2(into, 0.0), blen + 1.0, n)
				else:
					_port_motorboat(c, Vector2(into, 0.0), blen, n)
				n += 1
		z += PORT_SLIP


## A finger pier: a narrow timber walk on posts from the quay into the water.
func _port_finger(at: Vector2, d: Vector2, length: float) -> void:
	var g: float = map.terrain_height(at.x + d.x * 2.0, at.y)
	_g = g
	var a := at
	var b := at + Vector2(d.x * length, 0.0)
	var poly := PackedVector2Array([a + Vector2(0, -0.45), b + Vector2(0, -0.45), b + Vector2(0, 0.45), a + Vector2(0, 0.45)])
	_prism(poly, g + 0.25, g + 0.45, PORT_TIMBER.darkened(0.3), PORT_TIMBER, M_STONE, M_STONE)


## A small motorboat moored at `c`, bow towards `d`: a hull with a dark boot top, a pale deck, a
## console with a windscreen, a cover over the stern on every other one.
func _port_motorboat(c: Vector2, d: Vector2, length: float, i: int) -> void:
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	var a := d.normalized()
	var b := Vector2(-a.y, a.x)
	var hl := length * 0.5
	var hb := length * 0.19
	var hull := PackedVector2Array([c + a * hl, c + a * hl * 0.4 + b * hb, c - a * hl + b * hb * 0.9,
			c - a * hl - b * hb * 0.9, c + a * hl * 0.4 - b * hb])
	var col: Color = MARINA_HULLS[(i * 3) % MARINA_HULLS.size()]
	_prism(hull, g - 0.3, g + 0.2, Color("#2b2f36"), Color(0, 0, 0, 0), M_STONE)
	_prism(hull, g + 0.2, g + 0.75, col, Color("#e4ded0"), M_STONE, M_STONE)
	var cs := c + a * hl * 0.05
	var con := PackedVector2Array([cs + a * 0.5 + b * hb * 0.5, cs - a * 0.6 + b * hb * 0.5, cs - a * 0.6 - b * hb * 0.5, cs + a * 0.5 - b * hb * 0.5])
	_prism(con, g + 0.75, g + 1.15, Color("#e9e8e2"), Color("#d6d4cc"), M_STONE, M_STONE)
	var w0 := cs + a * 0.5 + b * hb * 0.55
	var w1 := cs + a * 0.5 - b * hb * 0.55
	_quad(Vector3(w0.x, g + 1.15, w0.y), Vector3(w1.x, g + 1.15, w1.y), Vector3(w1.x, g + 1.55, w1.y), Vector3(w0.x, g + 1.55, w0.y),
			Vector3(a.x, 0.3, a.y).normalized(), Color("#4b6470"))
	if i % 2 == 1:
		var cov := PackedVector2Array([c - a * hl * 0.25 + b * hb * 0.8, c - a * hl * 0.9 + b * hb * 0.75,
				c - a * hl * 0.9 - b * hb * 0.75, c - a * hl * 0.25 - b * hb * 0.8])
		_prism(cov, g + 0.75, g + 1.05, Color("#1f3a5f"), Color("#24426b"), M_STONE, M_STONE)


## A houseboat along the west quay (F's photos: an anthracite box with a glazed front, a grey
## converted barge with railings on its flat roof, one with a copper standing-seam gable).
func _port_houseboat(c: Vector2, i: int) -> void:
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	_o = c
	_a = Vector2(0.0, 1.0)
	_b = Vector2(1.0, 0.0)
	var hu := 6.0 + 2.0 * float(i % 2)
	var hv := 2.2
	var col: Color = PORT_HOUSEBOATS[i % PORT_HOUSEBOATS.size()]
	_prism(_rect(0.0, 0.0, hu, hv), g - 0.4, g + 0.6, Color("#3b3e43"), Color("#6c5a48"), M_STONE, M_STONE)
	_prism(_rect(-0.6, 0.0, hu - 1.6, hv - 0.3), g + 0.6, g + 3.2, col, Color(0, 0, 0, 0), M_STONE)
	_mode = M_PAVILION
	var f0 := _w(hu - 2.2, -hv + 0.3)
	var f1 := _w(hu - 2.2, hv - 0.3)
	_quad(Vector3(f0.x, g + 0.8, f0.y), Vector3(f1.x, g + 0.8, f1.y), Vector3(f1.x, g + 3.0, f1.y), Vector3(f0.x, g + 3.0, f0.y),
			Vector3(_a.x, 0.0, _a.y), Color("#6e8b96"))
	_mode = M_STONE
	if i % 3 == 2:
		_gable(hu - 1.8, -hu + 0.6, 0.0, hv, g + 3.2, 1.4, col, PORT_COPPER)
	else:
		_prism(_rect(-0.6, 0.0, hu - 1.5, hv - 0.2), g + 3.2, g + 3.4, col.lightened(0.1), col.darkened(0.15), M_STONE, M_STONE)
		if i % 3 == 1:
			_barge_rail(-hu + 1.0, hu - 2.2, -hv + 0.3, hv - 0.3, g + 3.4, 0.9, 0.05, Color("#c9ccd0"))
	_collide(_rect(0.0, 0.0, hu, hv))


## Monkey Love's garden at Bulwar Flotylli Pińskiej 1A, south of Most Łazienkowski (F, 2026-11-07,
## his photos IMG_7476-7477), as the parody "Małpi Love": dark vertical-board timber cabins under
## low black metal gables, one end wall painted yolk yellow, a grey-roofed kiosk, and between them a
## gravel garden of plank tables and benches under white market umbrellas, with festoons. The OSM
## outline (one block, 4.3 m) is the whole garden: the cabins take its two ends and its two bumps.
const MONKEY_AT := Vector2(1736.0, 1320.0)
const MONKEY_WALL := Color("#5c3d28")
const MONKEY_BATTEN := Color("#3f291b")
const MONKEY_ROOF := Color("#2a2d30")
const MONKEY_KIOSK_ROOF := Color("#8b9095")
const MONKEY_YELLOW := Color("#f0ac1c")
const MONKEY_GRAVEL := Color("#cdc3ae")
const MONKEY_UMBRELLA := Color("#ecebe4")
const MONKEY_PLANK := Color("#9a7552")


func _find_monkey() -> void:
	var q := _tallest_at(MONKEY_AT)
	if q.size() < 3:
		return
	_add_site("monkey_love", [_largest(Geometry2D.offset_polygon(q, 0.8, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "monkey_love":
		sites[-1]["garden"] = q


## A timber cabin at a local spot: board walls (dark battens every 0.6 m on the long sides), a
## low gable along u with an overhang, and its ring for the cars. Returns the eaves height.
func _monkey_cabin(cu: float, cv: float, hu: float, hv: float, g: float, h: float, roof: Color) -> float:
	var none := Color(0, 0, 0, 0)
	var eave := g + h
	_prism(_rect(cu, cv, hu, hv), g - 0.3, eave, MONKEY_WALL, none, M_STONE)
	_collide(_rect(cu, cv, hu, hv))
	for sd: float in [-1.0, 1.0]:
		var k := 0
		var u := cu - hu + 0.3
		while u < cu + hu - 0.2:
			if k % 2 == 1:
				_lbox(u, cv + sd * (hv + 0.03), 0.04, 0.03, g, eave - 0.05, MONKEY_BATTEN, M_STONE)
			u += 0.6
			k += 1
	var keep := _o
	_o = _w(cu, cv)
	_gable(hu + 0.4, -hu - 0.4, 0.0, hv + 0.45, eave, minf(0.9, hv * 0.3), MONKEY_WALL, roof)
	_o = keep
	return eave


func _build_monkey_love(site: Dictionary) -> void:
	var q: PackedVector2Array = site["garden"]
	var f := _barge_frame(q)
	if f.is_empty():
		return
	_barge_set(f)
	var hu: float = f[3]
	var hv: float = f[4]
	var g := INF
	for p in q:
		g = minf(g, map.terrain_height(p.x, p.y))
	_g = g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	# The gravel garden over the strip between the cabins.
	var mid := minf(7.5, hu * 0.45)
	_prism(_rect(0.0, 0.0, mid, hv - 0.3), g - 0.3, g + 0.05, MONKEY_GRAVEL.darkened(0.2), MONKEY_GRAVEL, M_STONE, M_STONE)
	# The cabins at both ends of the strip (the north one with the yellow end wall and door).
	var cab := minf(4.0, (hu - mid) * 0.5 + 0.3)
	var n_u := -hu + cab + 0.3
	var s_u := hu - cab - 0.3
	var cv := minf(4.5, hv - 0.6)
	var eave := _monkey_cabin(n_u, 0.0, cab, cv, g, 3.0, MONKEY_ROOF)
	_monkey_cabin(s_u, 0.0, cab, cv, g, 2.8, MONKEY_ROOF)
	# The yellow bay on the north cabin's garden end: the painted wall and a dark door in it.
	_lbox(n_u + cab + 0.04, -cv * 0.35, 0.04, cv * 0.45, g, eave - 0.1, MONKEY_YELLOW, M_STONE)
	_lbox(n_u + cab + 0.08, -cv * 0.35, 0.03, 0.55, g, g + 2.1, Color("#2c2620"), M_STONE)
	# The kiosk on the river-side bump (grey roof, as behind the cabins in IMG_7476) and the bar
	# hut on the land-side bump, if the outline has them (the strip is half as wide as the box).
	if hv > 8.0:
		var bump := hv - 5.6
		_monkey_cabin(3.6, -hv + bump * 0.5 + 0.2, 2.9, bump * 0.45, g, 2.6, MONKEY_KIOSK_ROOF)
		_monkey_cabin(-3.7, hv - bump * 0.5 - 0.2, 2.9, bump * 0.45, g, 2.6, MONKEY_ROOF)
	# Plank tables with two benches each, under white market umbrellas: two rows down the garden.
	var k := 0
	for row: float in [-1.0, 1.0]:
		var uu := -mid + 2.4
		while uu <= mid - 2.0:
			var v := row * minf(2.6, hv * 0.3)
			_lbox(uu, v, 0.9, 0.4, g, g + 0.75, MONKEY_PLANK.darkened(0.2), M_STONE, MONKEY_PLANK)
			for sd: float in [-1.0, 1.0]:
				_lbox(uu, v + sd * 0.75, 0.9, 0.16, g, g + 0.45, MONKEY_PLANK.darkened(0.3), M_STONE, MONKEY_PLANK.darkened(0.1))
			if k % 2 == 0:
				_prism(_rect(uu, v, 0.04, 0.04), g + 0.75, g + 2.4, BARGE_POST, none, M_STONE)
				_mode = M_STONE
				_pyramid(_circle(_w(uu, v), 1.7, 8), g + 2.25, g + 2.75, MONKEY_UMBRELLA)
			uu += 3.4
			k += 1
	# Festoons between the cabins' garden corners over the tables.
	var posts: Array[Vector3] = []
	for c: Vector2 in [Vector2(n_u + cab, -cv), Vector2(s_u - cab, -cv), Vector2(s_u - cab, cv), Vector2(n_u + cab, cv)]:
		posts.append(_barge_post(c.x, c.y, g, 3.1))
	_barge_festoon(posts[0], posts[1], 0.6, 9)
	_barge_festoon(posts[3], posts[2], 0.6, 9)
	_barge_festoon(posts[0], posts[2], 0.8, 10)
	# The name on the north cabin's garden end, above the yellow bay, in warm neon.
	var at := _w(n_u + cab + 0.12, cv * 0.3)
	signs.append(["MAŁPI LOVE", Vector3(at.x, eave - 0.55, at.y), Vector3(_a.x, 0.0, _a.y), 0.34, Color(1.0, 0.72, 0.3)])
	_g = g


## True where the water map says there is open water (a boat's centre wants a metre of it).
func _marina_wet(p: Vector2, margin: float) -> bool:
	return not map.has_method("shore_distance") or map.shore_distance(p.x, p.y) > margin


func _build_marina(site: Dictionary) -> void:
	_marina_club(site["club"])
	var n := 0
	# Berths: boats along x with the bow to the east, two to a slip where the water goes on.
	for slip: Array in MARINA_SLIPS:
		for x: float in slip[1]:
			var c := Vector2(x, slip[0])
			if _marina_wet(c, 1.2) and _marina_wet(c + Vector2(4.0, 0.0), 0.6) and _marina_wet(c - Vector2(4.0, 0.0), 0.6):
				_sailboat(c, Vector2.RIGHT, 8.4 + 0.3 * (n % 3), n)
				n += 1
	# Alongside the dam, bows to the west, the head of the harbour.
	for c: Vector2 in MARINA_DAM:
		if _marina_wet(c, 0.8):
			_sailboat(c, Vector2.LEFT, 9.0 + 0.4 * (n % 3), n)
			n += 1
	# On buoys in the big basin, all bows into the wind, each a little off the next.
	for c: Vector2 in MARINA_BUOYS:
		if _marina_wet(c, 8.0):
			var d := MARINA_WIND.rotated(0.18 * float(n % 5 - 2)).normalized()
			_sailboat(c, d, 8.6 + 0.8 * (n % 4), n)
			_marina_buoy(c + d * 7.5)
			n += 1
	for c: Vector2 in MARINA_LAMPS:
		_marina_lamp(c)


## One sailboat on the water at `c`, bow towards `d`: a hull with a dark sheer band and a deck, a
## doghouse, a mast with a forestay and a furled sail on the boom.
func _sailboat(c: Vector2, d: Vector2, length: float, i: int) -> void:
	var g: float = map.terrain_height(c.x, c.y)
	_g = g
	var none := Color(0, 0, 0, 0)
	var a := d.normalized()
	var b := Vector2(-a.y, a.x)
	var hl := length * 0.5
	var hb := length * 0.15
	var hull := PackedVector2Array([c + a * hl, c + a * hl * 0.45 + b * hb, c - a * hl * 0.8 + b * hb, c - a * hl + b * hb * 0.7,
			c - a * hl - b * hb * 0.7, c - a * hl * 0.8 - b * hb, c + a * hl * 0.45 - b * hb])
	var col: Color = MARINA_HULLS[i % MARINA_HULLS.size()]
	_prism(hull, g - 0.35, g + 0.35, col.darkened(0.25), none, M_STONE)
	_prism(hull, g + 0.35, g + 0.85, col, Color("#c9a77a"), M_STONE, M_STONE)
	var cab := PackedVector2Array([c + a * hl * 0.15 + b * hb * 0.6, c - a * hl * 0.5 + b * hb * 0.6,
			c - a * hl * 0.5 - b * hb * 0.6, c + a * hl * 0.15 - b * hb * 0.6])
	_prism(cab, g + 0.85, g + 1.35, Color("#e9e8e2"), Color("#d9d8d0"), M_STONE, M_STONE)
	var m0 := c + a * hl * 0.12
	var top := Vector3(m0.x, g + length * 1.15, m0.y)
	_beam(Vector3(m0.x, g + 0.85, m0.y), top, 0.1, Color("#c9ced2"))
	var bow := c + a * hl * 0.92
	_beam(Vector3(bow.x, g + 0.85, bow.y), top, 0.03, Color("#8a9096"), false)
	var boom_end := c - a * hl * 0.85
	_beam(Vector3(m0.x, g + 1.5, m0.y), Vector3(boom_end.x, g + 1.55, boom_end.y), 0.1, Color("#c9ced2"))
	_beam(Vector3(m0.x, g + 1.75, m0.y), Vector3(boom_end.x, g + 1.75, boom_end.y), 0.34, Color("#f0eadb"))


## A mooring buoy: a small red drum on the water.
func _marina_buoy(p: Vector2) -> void:
	_g = map.terrain_height(p.x, p.y)
	var ring := _circle(p, 0.35, 6)
	_prism(ring, _g - 0.1, _g + 0.35, Color("#d4483b"), Color("#d4483b"), M_STONE, M_STONE)


## A pier-end lamp: a post with a warm lantern (it glows at night).
func _marina_lamp(p: Vector2) -> void:
	var g: float = map.terrain_height(p.x, p.y)
	_g = g
	var sq := PackedVector2Array([p + Vector2(-0.05, -0.05), p + Vector2(0.05, -0.05), p + Vector2(0.05, 0.05), p + Vector2(-0.05, 0.05)])
	_prism(sq, g, g + 2.2, BARGE_POST, BARGE_POST, M_STONE, M_STONE)
	var lan := PackedVector2Array([p + Vector2(-0.14, -0.14), p + Vector2(0.14, -0.14), p + Vector2(0.14, 0.14), p + Vector2(-0.14, 0.14)])
	var keep := _mode
	_mode = M_LAMP
	_prism(lan, g + 2.2, g + 2.55, BARGE_BULB, BARGE_BULB, M_LAMP, M_LAMP)
	_mode = keep


## The club house on its mapped outline: piles into the water, white walls with a glazed upper
## band, a red hipped roof, a flagpole, and the name in neon on the face the camera sees.
func _marina_club(outline: PackedVector2Array) -> void:
	var none := Color(0, 0, 0, 0)
	var f := _barge_frame(outline)
	if f.is_empty():
		return
	_barge_set(f)
	var hu: float = f[3]
	var hv: float = f[4]
	var low := INF
	var quay := -INF
	for p in outline:
		var h: float = map.terrain_height(p.x, p.y)
		low = minf(low, h)
		quay = maxf(quay, h)
	quay = maxf(quay, low + 0.8)
	_g = low
	_prism(outline, low - 0.8, quay, Color("#5b5650"), Color("#8a7a62"), M_STONE, M_STONE)
	var walls := _largest(Geometry2D.offset_polygon(outline, -0.3, Geometry2D.JOIN_MITER))
	if walls.size() < 3:
		walls = outline
	var eave := quay + 5.4
	_prism(walls, quay, quay + 2.7, MARINA_WALL, none, M_STONE)
	_prism(walls, quay + 2.7, eave, Color("#6e8a96"), none, M_PAVILION)
	_mullions(walls, quay + 2.7, eave, 1.6, 0.05, MARINA_WALL)
	_mode = M_STONE
	_prism(_rect(0.0, 0.0, hu + 0.5, hv + 0.5), eave, eave + 0.25, MARINA_TRIM, MARINA_ROOF, M_STONE, M_STONE)
	_hip(0.0, 0.0, hu + 0.45, hv + 0.45, eave + 0.25, 2.6, MARINA_ROOF)
	var fp := _w(-hu + 0.8, -hv + 0.8)
	var base := Vector3(fp.x, quay + 0.2, fp.y)
	_beam(base, base + Vector3.UP * 9.0, 0.12, Color("#c9ced2"))
	var nf := Vector3(_a.x, 0.0, _a.y)
	var fd := Vector3(_b.x, 0.0, _b.y) * 1.5
	_quad(base + Vector3.UP * 8.0, base + Vector3.UP * 8.0 + fd, base + Vector3.UP * 9.0 + fd, base + Vector3.UP * 9.0, nf, BARGE_FLAG_W)
	_quad(base + Vector3.UP * 7.0, base + Vector3.UP * 7.0 + fd, base + Vector3.UP * 8.0 + fd, base + Vector3.UP * 8.0, nf, BARGE_FLAG_R)
	var best := -INF
	var at := Vector2.ZERO
	var out := Vector2.ZERO
	var room := 0.0
	for face: Array in [[_a, _w(hu + 0.55, 0.0), 2.0 * hv], [-_a, _w(-hu - 0.55, 0.0), 2.0 * hv],
			[_b, _w(0.0, hv + 0.55), 2.0 * hu], [-_b, _w(0.0, -hv - 0.55), 2.0 * hu]]:
		var d := (face[0] as Vector2).dot(BEHIND_FACE)
		if d > best:
			best = d
			out = face[0]
			at = face[1]
			room = face[2]
	var word := "PRZYSTAŃ"
	var k := minf(0.5, (room - 1.0) / Neon.length_of(word))
	signs.append([word, Vector3(at.x, quay + 3.0, at.y), Vector3(out.x, 0.0, out.y), k, MARINA_NEON])
	_collide(outline)


# The cross-city line's underground station by the Palace (1963): above ground only two long
# pavilions by Romanowicz and Szymaniak, "oversized shelters" over the stairs down to the
# platforms. Built from their two OSM outlines as glass halls under a deep light fascia and a
# thin roof, the station's name on the side the camera sees.


# --- The Vistula boulevards' dressing (2026-11-02, docs/landmarks/specs/bulwary.md) -----------

## Where each group's outlines lie (the bake's buildings, found by position and kind).
const BULWAR_PAW_BOX := Rect2(-270.0, -1510.0, 250.0, 250.0)
const BULWAR_BAR_BOXES := [Rect2(25.0, -1110.0, 40.0, 45.0), Rect2(195.0, -1068.0, 50.0, 43.0), Rect2(670.0, -575.0, 42.0, 50.0)]
## Roughly towards the river on the left bank's run past Powiśle (plan).
const BULWAR_RIVER := Vector2(0.747, -0.665)
## The timber deck strips by the water: centre x, z and the shore's direction there (measured
## from the bake's shore runs, 4.5 m in from the edge, clear of buildings, steps, roads and
## the children's pool at BULWARY_POOL).
const BULWAR_DECKS := [
	[-457.4, -1814.1, -0.532, -0.847], [-427.2, -1766.0, -0.532, -0.847], [-349.3, -1645.1, -0.552, -0.834],
	[-315.1, -1596.7, -0.579, -0.815], [28.2, -1237.2, -0.772, -0.635],
	[84.1, -1191.1, -0.762, -0.647], [127.1, -1154.6, -0.762, -0.647], [206.9, -1086.5, -0.749, -0.662],
	[283.7, -1018.6, -0.742, -0.671], [339.4, -968.2, -0.742, -0.671], [388.0, -921.8, -0.680, -0.733],
	[640.1, -645.1, -0.621, -0.784], [696.9, -572.0, -0.593, -0.805], [761.4, -483.3, -0.582, -0.814],
	[808.8, -416.6, -0.575, -0.818], [840.4, -369.3, -0.583, -0.812], [880.5, -308.8, -0.573, -0.819],
]
const BULWAR_DECK_HU := 5.0    # a strip's half length along the shore
const BULWAR_DECK_HV := 1.6    # its half depth
const BULWAR_DECK_H := 0.25    # its top over the ground
const BULWAR_CONCRETE := Color("#c3c0b8")
const BULWAR_TIMBER := Color("#a37a52")
const BULWAR_GREEN := Color("#6d8b4b")
const BULWAR_GLASS := Color("#6f8c96")
const BULWAR_PAW_H := 3.6
## Per pavilion, north-west to south-east: its neon word ("" none), the umbrellas' canvas, and
## whether it is open (a lit glass front and a terrace) or shuttered for the season.
const BULWAR_PAWS := [
	["CUDAK", Color("#f2efe6"), true],
	["", Color("#2f6fb0"), true],
	["POMOSTEK", Color("#e9b23c"), true],
	["", Color("#d9483b"), false],
	["RZECZKA", Color("#3f9a76"), true],
	["BAR", Color("#efe6cf"), true],
]
## The containers' paint, in turn.
const BULWAR_BOXES := [Color("#2f6f8f"), Color("#c8452f"), Color("#e2b23a"), Color("#3f7a4f"), Color("#e8e4da"), Color("#38404a")]
## Per group (BULWAR_BAR_BOXES order): the neon word on its first box.
const BULWAR_BAR_WORDS := ["PIWO", "LEMONIADA", "ZAPIEKANKI"]
## Per group: which side of the boxes the chairs go, +1 the river's, -1 inland (measured in
## the shots: Karowa's containers stand in the park, the others with the road behind them).
const BULWAR_BAR_FRONT := [-1.0, 1.0, 1.0]
## The deck chairs' canvas, in turn.
const BULWAR_CANVAS := [Color("#2f6fb0"), Color("#ece6d4"), Color("#d9483b"), Color("#f0b429"), Color("#3f9a76")]


func _find_bulwar_dress() -> void:
	var paws: Array = []
	var bars: Array = []
	for bld in data.get("buildings", []):
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		var c := _centre(q)
		var kind := str(bld.get("kind", ""))
		if kind == "pavilion" and BULWAR_PAW_BOX.has_point(c):
			paws.append(q)
			continue
		for i in BULWAR_BAR_BOXES.size():
			if (BULWAR_BAR_BOXES[i] as Rect2).has_point(c) and kind in ["pavilion", "service", "yes"]:
				bars.append([i, q])
				break
	# North-west to south-east along the river, so each keeps its style on both city paths.
	var along := func(a: PackedVector2Array, b: PackedVector2Array) -> bool:
		return _centre(a).dot(Vector2(0.665, 0.747)) < _centre(b).dot(Vector2(0.665, 0.747))
	paws.sort_custom(along)
	bars.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0] if a[0] != b[0] else along.call(a[1], b[1]))
	if not paws.is_empty():
		var zone: Array = []
		var frames: Array = []
		for q: PackedVector2Array in paws:
			zone.append(_largest(Geometry2D.offset_polygon(q, 0.8, Geometry2D.JOIN_MITER)))
			frames.append(_barge_frame(q))
		_add_site("bulwary_pawilony", zone)
		if not sites.is_empty() and sites[-1]["key"] == "bulwary_pawilony":
			sites[-1]["frames"] = frames
	if not bars.is_empty():
		var zone: Array = []
		var items: Array = []
		for e: Array in bars:
			zone.append(_largest(Geometry2D.offset_polygon(e[1], 0.8, Geometry2D.JOIN_MITER)))
			items.append([e[0], _barge_frame(e[1])])
		_add_site("bulwary_bary", zone)
		if not sites.is_empty() and sites[-1]["key"] == "bulwary_bary":
			sites[-1]["items"] = items
	# The deck strips: no building stands there, the zone is just their own plan.
	var decks: Array = []
	for d: Array in BULWAR_DECKS:
		var c := Vector2(d[0], d[1])
		var t := Vector2(d[2], d[3])
		var n := Vector2(-t.y, t.x)
		decks.append(PackedVector2Array([c - t * BULWAR_DECK_HU - n * BULWAR_DECK_HV, c + t * BULWAR_DECK_HU - n * BULWAR_DECK_HV,
				c + t * BULWAR_DECK_HU + n * BULWAR_DECK_HV, c - t * BULWAR_DECK_HU + n * BULWAR_DECK_HV]))
	_add_site("bulwary_pomosty", decks)


## Set the local frame on an outline's box (u along it, v across) with its v axis turned so
## +v points to the river; returns the ground (the lowest under the box).
func _bulwar_set(f: Array) -> float:
	_o = f[0]
	_a = f[1]
	_b = f[2]
	if _b.dot(BULWAR_RIVER) < 0.0:
		_a = -_a
		_b = -_b
	var hu: float = f[3]
	var hv: float = f[4]
	_g = _ground_under(PackedVector2Array([_w(-hu, -hv), _w(hu, -hv), _w(hu, hv), _w(-hu, hv)]))
	return _g


func _build_bulwar_pavilions(site: Dictionary) -> void:
	var i := 0
	for f: Array in site["frames"]:
		var g := _bulwar_set(f)
		_walls.clear()
		_caps.clear()
		var sty: Array = BULWAR_PAWS[i % BULWAR_PAWS.size()]
		i += 1
		var hu: float = f[3]
		var hv: float = f[4]
		var top := g + BULWAR_PAW_H
		var body := _rect(0.0, 0.0, hu, hv)
		# The concrete box, its roof a lawn behind a low concrete rim.
		_prism(body, g, top, BULWAR_CONCRETE, BULWAR_GREEN, M_STONE, M_STONE)
		_collide(body)
		_barge_rail(-hu, hu, -hv, hv, top, 0.35, 0.25, BULWAR_CONCRETE.lightened(0.05))
		# The river front: a glass band between concrete ends, mullions every 2.4 m; lit warm
		# at night when the bar is open, dark grey shutters when it is not.
		var open: bool = sty[2]
		var gu := hu - 1.2
		var fy0 := g + 0.3
		var fy1 := top - 0.45
		var fv := hv + 0.04
		var a0 := _w(-gu, fv)
		var a1 := _w(gu, fv)
		var nr := Vector3(_b.x, 0.0, _b.y)
		_mode = M_PAVILION if open else M_STONE
		_quad(Vector3(a0.x, fy0, a0.y), Vector3(a1.x, fy0, a1.y), Vector3(a1.x, fy1, a1.y), Vector3(a0.x, fy1, a0.y), nr,
				BULWAR_GLASS if open else Color("#5d6166"))
		_mode = M_STONE
		var n := maxi(2, roundi(2.0 * gu / 2.4))
		for k in range(0, n + 1):
			var m0 := _w(-gu + 2.0 * gu * k / n - 0.06, fv + 0.05)
			var m1 := _w(-gu + 2.0 * gu * k / n + 0.06, fv + 0.05)
			_quad(Vector3(m0.x, fy0, m0.y), Vector3(m1.x, fy0, m1.y), Vector3(m1.x, fy1, m1.y), Vector3(m0.x, fy1, m0.y), nr, Color("#3b3f44"))
		# The back (the embankment's side): timber slats over the concrete, a dark door.
		var b0 := _w(-gu, -hv - 0.04)
		var b1 := _w(gu, -hv - 0.04)
		_quad(Vector3(b0.x, fy0, b0.y), Vector3(b1.x, fy0, b1.y), Vector3(b1.x, fy1, b1.y), Vector3(b0.x, fy1, b0.y), -nr, BULWAR_TIMBER)
		_lbox(gu * 0.5, -hv - 0.1, 0.6, 0.05, g, g + 2.3, Color("#2e2f31"))
		if not open:
			continue
		# The terrace before the glass: a timber deck, tables under umbrellas, deck chairs at
		# its ends, bulbs strung along the eave.
		var dv := 1.6
		_lbox(0.0, hv + dv, gu, dv - 0.05, g, g + 0.2, BULWAR_TIMBER, M_STONE, BULWAR_TIMBER.lightened(0.08))
		var u := -gu + 2.4
		var k := 0
		while u <= gu - 2.4:
			if k % 3 == 2:
				_bulwar_lezak(u - 0.4, hv + dv, g + 0.2, BULWAR_CANVAS[(i + k) % BULWAR_CANVAS.size()])
				_bulwar_lezak(u + 0.4, hv + dv, g + 0.2, BULWAR_CANVAS[(i + k + 1) % BULWAR_CANVAS.size()])
			else:
				_barge_umbrella(u, hv + dv, g + 0.2, 1.2, sty[1])
			u += 3.8
			k += 1
		var e0 := _w(-gu, hv + 0.15)
		var e1 := _w(gu, hv + 0.15)
		var pieces := maxi(1, roundi(2.0 * gu / 12.0))
		for p in pieces:
			var t0 := float(p) / pieces
			var t1 := float(p + 1) / pieces
			_barge_festoon(Vector3(lerpf(e0.x, e1.x, t0), top - 0.3, lerpf(e0.y, e1.y, t0)),
					Vector3(lerpf(e0.x, e1.x, t1), top - 0.3, lerpf(e0.y, e1.y, t1)), 0.35, 5)
		# The bar's name in neon on its rim, on the face the game's camera sees most.
		var word: String = sty[0]
		if word != "":
			_bulwar_sign(word, hu, hv, top + 0.35, Neon.colour_for(word, float(i) / 7.0))


## A neon word standing on a box's top edge (half sizes hu, hv in the current frame), on the
## face that looks most towards the game's camera (BEHIND_FACE), sized to fit that face.
func _bulwar_sign(word: String, hu: float, hv: float, y: float, tube: Color) -> void:
	var best := -INF
	var at := Vector2.ZERO
	var out := Vector2.ZERO
	var room := 0.0
	for face: Array in [[_a, _w(hu + 0.05, 0.0), 2.0 * hv], [-_a, _w(-hu - 0.05, 0.0), 2.0 * hv],
			[_b, _w(0.0, hv + 0.05), 2.0 * hu], [-_b, _w(0.0, -hv - 0.05), 2.0 * hu]]:
		var d := (face[0] as Vector2).dot(BEHIND_FACE)
		if d > best:
			best = d
			out = face[0]
			at = face[1]
			room = face[2]
	var k := minf(0.4, maxf(0.15, (room - 0.6) / Neon.length_of(word)))
	signs.append([word, Vector3(at.x, y + 0.02, at.y), Vector3(out.x, 0.0, out.y), k, tube])


func _build_bulwar_bars(site: Dictionary) -> void:
	var i := 0
	var signed := {}
	for e: Array in site["items"]:
		var grp: int = e[0]
		var f: Array = e[1]
		var g := _bulwar_set(f)
		_walls.clear()
		_caps.clear()
		var hu: float = f[3]
		var hv: float = f[4]
		var col: Color = BULWAR_BOXES[i % BULWAR_BOXES.size()]
		i += 1
		var body := _rect(0.0, 0.0, hu, hv)
		var shipping := hv < 1.6
		# Neighbours side by side sit 6 cm apart in height so their roofs never share a plane.
		var top := g + (2.6 if shipping else 2.8) + 0.06 * (i % 2)
		if shipping:
			# A shipping container: corrugated sides (ribs every 0.45 m), a darker top rail.
			_prism(body, g, top, col, col.darkened(0.15), M_STONE, M_STONE)
			_mullions(body, g + 0.12, top - 0.12, 0.45, 0.04, col.darkened(0.2))
		else:
			# A timber kiosk under a flat roof on a small overhang.
			_prism(body, g, top, BULWAR_TIMBER.darkened(0.1), Color(0, 0, 0, 0), M_STONE)
			_prism(_rect(0.0, 0.0, hu + 0.3, hv + 0.3), top, top + 0.2, col, col.darkened(0.1), M_STONE, M_STONE)
		_collide(body)
		# The hatch on the long face the camera sees most: lit inside, a flap propped over it, a
		# counter under it, a stool or two; deck chairs and an umbrella out in front.
		var s := 1.0 if _b.dot(BEHIND_FACE) >= 0.0 else -1.0
		var long_u := hu >= hv
		var hw := (hu if long_u else hv) * 0.6
		var depth := hv if long_u else hu
		var fn := (_b if long_u else _a) * s
		var side := (_a if long_u else _b)
		var c := _o + fn * (depth + 0.08)
		var h0 := c - side * hw
		var h1 := c + side * hw
		var nrm := Vector3(fn.x, 0.0, fn.y)
		_mode = M_LAMP
		_quad(Vector3(h0.x, g + 1.05, h0.y), Vector3(h1.x, g + 1.05, h1.y), Vector3(h1.x, g + 2.0, h1.y), Vector3(h0.x, g + 2.0, h0.y),
				nrm, Color(1.0, 0.82, 0.55))
		_mode = M_STONE
		var f0 := h0 + fn * 0.9
		var f1 := h1 + fn * 0.9
		_two_sided(Vector3(h0.x, g + 2.1, h0.y), Vector3(h1.x, g + 2.1, h1.y), Vector3(f1.x, g + 2.45, f1.y), Vector3(f0.x, g + 2.45, f0.y),
				col.lightened(0.1))
		var cc := _o + fn * (depth + 0.18)
		_prism(PackedVector2Array([cc - side * hw - fn * 0.15, cc + side * hw - fn * 0.15, cc + side * hw + fn * 0.15, cc - side * hw + fn * 0.15]),
				g, g + 1.0, col.darkened(0.3), BULWAR_TIMBER.lightened(0.1), M_STONE, M_STONE)
		# Out on the promenade's side (BULWAR_BAR_FRONT: the river's side or the park's, away
		# from the roads), at every other box: one umbrella and two deck chairs facing the box
		# (side by side boxes would share the spot).
		var sign_now := not signed.has(grp)
		if i % 2 == 0 and not sign_now:
			continue
		var ps: float = BULWAR_BAR_FRONT[grp]
		var fr := f[0] as Vector2 + _b * ps * (hv + 2.8)
		var keep_a := _a
		var keep_b := _b
		_o = fr
		_b = keep_b * ps
		_a = Vector2(-_b.y, _b.x)
		_barge_umbrella(-1.2, 0.0, g, 1.1, BULWAR_CANVAS[i % BULWAR_CANVAS.size()])
		_bulwar_lezak(0.5, 0.2, g, BULWAR_CANVAS[(i + 1) % BULWAR_CANVAS.size()], -1.0)
		_bulwar_lezak(1.3, 0.2, g, BULWAR_CANVAS[(i + 2) % BULWAR_CANVAS.size()], -1.0)
		_o = f[0]
		_a = keep_a
		_b = keep_b
		if sign_now:
			signed[grp] = true
			_bulwar_sign(BULWAR_BAR_WORDS[grp], hu, hv, top + (0.0 if shipping else 0.2), Neon.colour_for(BULWAR_BAR_WORDS[grp], float(grp) / 3.0))


## The deck strips: a low timber platform on the boulevard's edge, leżaki in a row facing the
## water, an umbrella at one end of every other strip.
func _build_bulwar_decks(site: Dictionary) -> void:
	var k := 0
	for q: PackedVector2Array in site["zone"]:
		_walls.clear()
		_caps.clear()
		_o = (q[0] + q[2]) * 0.5
		_a = (q[1] - q[0]).normalized()
		_b = (q[3] - q[0]).normalized()
		if _b.dot(BULWAR_RIVER) < 0.0:
			_b = -_b
			_a = -_a
		var g := _ground_under(q)
		_g = g
		var y := g + BULWAR_DECK_H
		_lbox(0.0, 0.0, BULWAR_DECK_HU, BULWAR_DECK_HV, g, y, BULWAR_TIMBER.darkened(0.25), M_STONE, BULWAR_TIMBER)
		var n := 4 if k % 3 != 1 else 3
		for c in n:
			var u := -BULWAR_DECK_HU + 1.2 + c * 1.5
			_bulwar_lezak(u, 0.05, y, BULWAR_CANVAS[(k + c) % BULWAR_CANVAS.size()])
		if k % 2 == 0:
			_barge_umbrella(BULWAR_DECK_HU - 1.6, 0.0, y, 1.2, BULWAR_CANVAS[(k + 3) % BULWAR_CANVAS.size()])
		k += 1


# --- Bulwary Wiślane, stage 2: the splash pool and the fish (K7) ---------------------------------

## Krajobraz places K7 (docs/design/krajobraz-places.md, 2026-11-02; spec docs/landmarks/specs/bulwary_basen.md).
## The 2017 stage of the boulevards has a children's corner by the plaza between the third and
## fourth bar pavilions: a splash pool with jets and Vistula fish sculptures. (The pavilions
## themselves are `bulwary_pawilony`, the boulevard dressing lane.) Built here: the pool, its
## paving and three fish (sturgeon, pike, perch) leaping from stone plinths. No building
## stands there, so the site is its own paving. No photo in the cloud: the Mac look check
## settles the exact spot and colours. No new draw call (the city's one surface).
const BULWARY_POOL := Vector2(-124.0, -1365.0)
const BULWARY_AXIS := Vector2(0.665, 0.747)  # along the boulevard there
const BULWARY_POOL_HALF := Vector2(4.2, 2.6)
const BULWARY_STONE := Color("#8d8f8c")
const BULWARY_WATER := Color("#2fb3dd")
const BULWARY_JET := Color("#e3f6fa")
const BULWARY_PAVING := Color("#cfc7b2")
const BULWARY_FISH := [Color("#a97a45"), Color("#8fa2ab"), Color("#6f9a8a")]


func _find_bulwary_pool() -> void:
	var pa := BULWARY_AXIS
	var pb := Vector2(-pa.y, pa.x)
	_add_site("bulwary_basen", [PackedVector2Array([BULWARY_POOL - pa * 6.4 - pb * 4.6, BULWARY_POOL + pa * 6.4 - pb * 4.6,
			BULWARY_POOL + pa * 6.4 + pb * 4.6, BULWARY_POOL - pa * 6.4 + pb * 4.6])])


## The splash pool: a paved apron, a low granite rim, shallow water, a row of jets, and three
## Vistula fish leaping on plinths round it (the children's corner of the 2017 stage).
func _build_bulwary_pool(_site: Dictionary) -> void:
	var axis := BULWARY_AXIS
	_o = BULWARY_POOL
	_a = axis
	_b = Vector2(-axis.y, axis.x)
	_walls.clear()
	_caps.clear()
	var ring := _rect(0.0, 0.0, 6.4, 4.6)
	_g = _ground_under(ring)
	var g := _g
	_mode = M_STONE
	_cap(ring, g + 0.04, BULWARY_PAVING)
	var hp := BULWARY_POOL_HALF
	var rim := _rect(0.0, 0.0, hp.x + 0.4, hp.y + 0.4)
	# The rim is four boxes round the water (a solid slab would cover it).
	var rl := BULWARY_STONE.lightened(0.1)
	_lbox(0.0, -hp.y - 0.2, hp.x + 0.4, 0.2, g - 0.2, g + 0.32, BULWARY_STONE, M_STONE, rl)
	_lbox(0.0, hp.y + 0.2, hp.x + 0.4, 0.2, g - 0.2, g + 0.32, BULWARY_STONE, M_STONE, rl)
	_lbox(-hp.x - 0.2, 0.0, 0.2, hp.y, g - 0.2, g + 0.32, BULWARY_STONE, M_STONE, rl)
	_lbox(hp.x + 0.2, 0.0, 0.2, hp.y, g - 0.2, g + 0.32, BULWARY_STONE, M_STONE, rl)
	_prism(_rect(0.0, 0.0, hp.x, hp.y), g - 0.2, g + 0.2, BULWARY_WATER, BULWARY_WATER, M_STONE, M_STONE)
	for k in 7:
		var u := lerpf(-hp.x + 0.9, hp.x - 0.9, float(k) / 6.0)
		for v: float in [-0.9, 0.9]:
			var j := _w(u, v)
			var jh := 0.7 + 0.5 * float((k + (1 if v > 0.0 else 0)) % 3) / 2.0
			_beam(Vector3(j.x, g + 0.2, j.y), Vector3(j.x, g + 0.2 + jh, j.y), 0.07, BULWARY_JET)
	_collide(rim)
	# The fish: a leaping sturgeon at the east end, a pike and a perch at the other corners.
	_bulwary_fish(-(hp.x + 1.9), 0.0, 3.4, 0.0, BULWARY_FISH[0], g)
	_bulwary_fish(hp.x + 1.7, 0.9, 2.2, PI, BULWARY_FISH[1], g)
	_bulwary_fish(0.4, hp.y + 1.6, 1.7, -PI * 0.5, BULWARY_FISH[2], g)


## One fish leaping from a stone plinth at a local spot: a beam chain along an arc, thick at
## the shoulder, a head, a forked tail and a dorsal fin. `len` its length, `yaw` where it heads
## (0 is local +u), the arc rising over its first half and falling.
func _bulwary_fish(u: float, v: float, flen: float, yaw: float, col: Color, g: float) -> void:
	_lbox(u, v, 0.45, 0.45, g - 0.2, g + 0.55, BULWARY_STONE, M_STONE, BULWARY_STONE.lightened(0.1))
	var dir := _a * cos(yaw) + _b * sin(yaw)
	var pt := func(t: float) -> Vector3:
		var w := _w(u, v) + dir * (t - 0.5) * flen
		var rise := sin(t * PI) * flen * 0.28 + (1.0 - t) * flen * 0.05
		return Vector3(w.x, g + 1.05 + rise, w.y)
	# A stem from the plinth to the belly, so the leap rests on its stand.
	var belly: Vector3 = pt.call(0.45)
	_beam(Vector3(belly.x, g + 0.55, belly.z), belly, 0.1 * flen, BULWARY_STONE)
	var width := [0.12, 0.34, 0.42, 0.34, 0.2, 0.1]
	for k in 5:
		_beam(pt.call(float(k) / 5.0), pt.call(float(k + 1) / 5.0), width[k] * flen * 0.8, col if k % 2 == 0 else col.darkened(0.12))
	# The head, a blunt snout past the last joint, and the tail's two flukes.
	var head: Vector3 = pt.call(1.0)
	var fore: Vector3 = pt.call(0.92)
	_beam(fore, head + (head - fore) * 0.9, 0.1 * flen, col.lightened(0.1))
	var tail: Vector3 = pt.call(0.0)
	var side := Vector3(-dir.y, 0.0, dir.x)
	var back: Vector3 = (tail - (pt.call(0.1) as Vector3)).normalized()
	for sd: float in [-1.0, 1.0]:
		_beam(tail, tail + back * flen * 0.16 + side * sd * flen * 0.1 + Vector3.UP * flen * 0.06 * sd, 0.035 * flen, col.darkened(0.08))
	# The dorsal fin over the shoulder, a small raised sail.
	var sh: Vector3 = pt.call(0.4)
	_beam(sh + Vector3.UP * flen * 0.06, sh + Vector3.UP * flen * 0.2 + (tail - head).normalized() * flen * 0.05, 0.025 * flen, col.darkened(0.15))


# --- Schodki nad Wisłą: the concrete seating steps along the left bank (2026-11-19) ---------------

## Spec docs/landmarks/specs/schodki_wisla.md, plan /schodki/PLAN.md. The ground is map_builder.gd's SUNKEN
## entries `schodki_wisla` (east of the shore's turn at u -36) and `schodki_wisla_w` (west of it): their floor
## is the plane from the top edge (`a`) to the quay (`b`), `rows` treads over it. This site draws what stands
## on it, all in the city's one stone material (no draw call of its own): the seat steps, the walking stairs
## cut into them, the timber seat boards, the coping and lamps on the top edge, the granite quay.
## The corners of the band's box (a tiny square each, as `_find_sunken`: nothing mapped is replaced).
const SCHODKI_BOX := [Vector2(371.0, -936.0), Vector2(526.0, -781.0)]
## The OSM walking flights inside the band (centrum.json `steps`, the two ends of each, measured 2026-11-19),
## frozen here so the builder and the crowd's seats plan (static, no map) cut the same gaps.
const SCHODKI_FLIGHTS := [
	[Vector2(475.1, -842.5), Vector2(468.6, -830.2)], [Vector2(382.5, -929.6), Vector2(374.6, -923.1)],
	[Vector2(443.5, -874.5), Vector2(434.2, -865.4)], [Vector2(503.4, -814.0), Vector2(499.4, -808.4)],
	[Vector2(492.8, -824.5), Vector2(488.3, -819.9)], [Vector2(484.1, -833.4), Vector2(473.6, -825.2)],
	[Vector2(463.0, -854.6), Vector2(456.5, -842.7)], [Vector2(452.7, -865.0), Vector2(441.4, -858.1)],
	[Vector2(512.6, -803.6), Vector2(499.4, -798.0)], [Vector2(488.3, -819.9), Vector2(483.3, -815.1)],
	[Vector2(499.4, -808.4), Vector2(495.3, -802.4)], [Vector2(521.2, -794.3), Vector2(510.4, -786.3)],
]
const SCHODKI_CUT_W := 2.4     # a walking stair's width
const SCHODKI_CUT_RISE := 0.15
const SCHODKI_LAMP_GAP := 25.0
const SCHODKI_SEAT := Color("#b9b6ae")
const SCHODKI_RISER := Color("#a29f98")
const SCHODKI_NOSE := Color("#cdcac2")
const SCHODKI_BOARD := Color("#a37a52")
const SCHODKI_QUAY := Color("#a9a59c")
const SCHODKI_CUT := Color("#a7a49d")
const SCHODKI_CUT_RISER := Color("#8f8c86")
const SCHODKI_COPING := Color("#c4c1b9")
const SCHODKI_POST := Color("#4a4e53")


func _find_schodki_wisla() -> void:
	if map._sunk.is_empty():
		return
	var zone: Array = []
	for a: Vector2 in SCHODKI_BOX:
		zone.append(PackedVector2Array([a, a + Vector2(0.2, 0), a + Vector2(0.2, 0.2), a + Vector2(0, 0.2)]))
	_add_site("schodki_wisla", zone)


## The walking stairs' outlines: each OSM flight a 2.4 m wide strip along its line, 3 m past both ends,
## flights that overlap (a concrete foot and a wooden top) merged into one.
static func schodki_cuts() -> Array[PackedVector2Array]:
	var merged: Array[PackedVector2Array] = []
	for f: Array in SCHODKI_FLIGHTS:
		var p0: Vector2 = f[0]
		var p1: Vector2 = f[1]
		var d := (p1 - p0).normalized()
		var half := Vector2(-d.y, d.x) * SCHODKI_CUT_W * 0.5
		var a := p0 - d * 3.0
		var b := p1 + d * 3.0
		var cur := PackedVector2Array([a - half, b - half, b + half, a + half])
		var rest: Array[PackedVector2Array] = []
		for m: PackedVector2Array in merged:
			var u := Geometry2D.merge_polygons(cur, m)
			if u.size() == 1 and not Geometry2D.is_polygon_clockwise(u[0]):
				cur = u[0]
			else:
				rest.append(m)
		rest.append(cur)
		merged = rest
	return merged


static func _schodki_area(poly: PackedVector2Array) -> float:
	var s := 0.0
	for i in poly.size():
		s += poly[i].cross(poly[(i + 1) % poly.size()])
	return absf(s) * 0.5


## `poly` less every cut, as polygons (slivers dropped).
static func _schodki_minus(poly: PackedVector2Array, cuts: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array] = [poly]
	for c: PackedVector2Array in cuts:
		var next: Array[PackedVector2Array] = []
		for pc: PackedVector2Array in pieces:
			for q: PackedVector2Array in Geometry2D.clip_polygons(pc, c):
				if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q) and _schodki_area(q) > 0.3:
					next.append(q)
		pieces = next
	return pieces


## `a` ∩ `b` as polygons (holes and slivers dropped).
static func _schodki_meet(a: PackedVector2Array, b: PackedVector2Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for q: PackedVector2Array in Geometry2D.intersect_polygons(a, b):
		if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q) and _schodki_area(q) > 0.05:
			out.append(q)
	return out


## The band's frame for one SUNKEN entry: a, d (the way down, a to b), side, the ring's lateral reach.
static func _schodki_frame(ring: PackedVector2Array, a: Vector2, b: Vector2) -> Dictionary:
	var d := (b - a).normalized()
	var side := Vector2(-d.y, d.x)
	var lo := INF
	var hi := -INF
	for q in ring:
		lo = minf(lo, (q - a).dot(side))
		hi = maxf(hi, (q - a).dot(side))
	return {"a": a, "d": d, "side": side, "lo": lo - 2.0, "hi": hi + 2.0, "reach": a.distance_to(b)}


## The strip of the band between `s0` and `s1` metres down from `a` (all its width).
static func _schodki_strip(f: Dictionary, s0: float, s1: float) -> PackedVector2Array:
	var a: Vector2 = f["a"]
	var d: Vector2 = f["d"]
	var side: Vector2 = f["side"]
	return PackedVector2Array([a + d * s0 + side * float(f["lo"]), a + d * s1 + side * float(f["lo"]),
			a + d * s1 + side * float(f["hi"]), a + d * s0 + side * float(f["hi"])])


func _build_schodki_wisla(_site: Dictionary) -> void:
	_no_roof = true
	_mode = M_STONE
	var cuts := schodki_cuts()
	for sk: Dictionary in map._sunk:
		if str(sk.get("site", "")) == "schodki_wisla":
			_schodki_band(sk, cuts)
	_no_roof = false


## One entry's band: the quay, the coping and lamps along the top, then each tread row between the
## walking stairs, each stair as small steps.
func _schodki_band(sk: Dictionary, cuts: Array[PackedVector2Array]) -> void:
	var ring: PackedVector2Array = sk["ring"]
	var f := _schodki_frame(ring, sk["a"], sk["b"])
	var a: Vector2 = f["a"]
	var d: Vector2 = f["d"]
	var side: Vector2 = f["side"]
	var length: float = f["reach"]
	var ha := float(sk["ha"])
	var hb := float(sk["hb"])
	var n := int(sk["rows"])
	var tread := length / n
	# The quay: the ring past the foot line, flat at the floor's end.
	for q in _schodki_meet(_schodki_strip(f, length, length + 40.0), ring):
		var c := _centre(q)
		var g := minf(_ground_under(q), map.terrain_height(c.x, c.y))
		_schodki_slab(q, minf(hb - 0.3, g - 0.05), hb, SCHODKI_QUAY.darkened(0.12), SCHODKI_QUAY)
	_schodki_top(ring, f, ha)
	var count := 0
	for k in n:
		var s0 := -1.5 if k == 0 else tread * k
		var s1 := tread * (k + 1)
		var top := lerpf(ha, hb, float(k) / n)
		for poly in _schodki_meet(_schodki_strip(f, s0, s1), ring):
			for piece in _schodki_minus(poly, cuts):
				_schodki_row(piece, f, top, s1)
				if k in [2, 3, 5, 6] and count % 3 == 0:
					_schodki_boards(piece, f, top, s1, count)
				count += 1
	# The walking stairs: small steps over the same depth, a shade darker.
	var m := maxi(4, roundi((ha - hb) / SCHODKI_CUT_RISE))
	for c: PackedVector2Array in cuts:
		for cp in _schodki_meet(c, ring):
			for j in m:
				var s0 := -1.5 if j == 0 else length * j / m
				var s1 := length * (j + 1) / m
				var y0 := lerpf(ha, hb, float(j) / m)
				var y1 := lerpf(ha, hb, float(j + 1) / m)
				for tp in _schodki_meet(_schodki_strip(f, s0, s1), cp):
					_cap_piece(tp, y0, SCHODKI_CUT)
				var line := PackedVector2Array([a + d * s1 + side * float(f["lo"]), a + d * s1 + side * float(f["hi"])])
				for h: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(line, cp):
					if h.size() >= 2:
						var p := h[0]
						var q := h[h.size() - 1]
						_quad(Vector3(p.x, y1, p.y), Vector3(q.x, y1, q.y), Vector3(q.x, y0, q.y), Vector3(p.x, y0, p.y),
								Vector3(d.x, 0.0, d.y), SCHODKI_CUT_RISER)


## A tread block: walls (the riser face a shade darker) from the ground up to `top`, the tread's top
## with a lighter nosing along its front (s = `s_front` down from `a`).
func _schodki_row(piece: PackedVector2Array, f: Dictionary, top: float, s_front: float) -> void:
	var c := _centre(piece)
	var g := minf(_ground_under(piece), map.terrain_height(c.x, c.y))
	_schodki_slab(piece, minf(top - 0.5, g - 0.05), top, SCHODKI_RISER, Color(0, 0, 0, 0))
	for q in _schodki_meet(piece, _schodki_strip(f, s_front - 0.14, s_front + 2.0)):
		_cap_piece(q, top, SCHODKI_NOSE)
	for q in _schodki_meet(piece, _schodki_strip(f, s_front - 40.0, s_front - 0.14)):
		_cap_piece(q, top, SCHODKI_SEAT)


## A timber seat board, 0.45 m deep and 0.06 m thick, along 6-8 m of the tread's front.
func _schodki_boards(piece: PackedVector2Array, f: Dictionary, top: float, s_front: float, count: int) -> void:
	var a: Vector2 = f["a"]
	var d: Vector2 = f["d"]
	var side: Vector2 = f["side"]
	var lo := INF
	var hi := -INF
	for q in piece:
		lo = minf(lo, (q - a).dot(side))
		hi = maxf(hi, (q - a).dot(side))
	if hi - lo < 3.0:
		return
	var span := minf(6.0 + float(count % 3), hi - lo - 1.0)
	var mid := lerpf(lo + span * 0.5 + 0.5, hi - span * 0.5 - 0.5, fposmod(count * 0.37, 1.0))
	var s0 := s_front - 0.57
	var s1 := s_front - 0.12
	var w := PackedVector2Array([a + d * s0 + side * (mid - span * 0.5), a + d * s1 + side * (mid - span * 0.5),
			a + d * s1 + side * (mid + span * 0.5), a + d * s0 + side * (mid + span * 0.5)])
	for q in _schodki_meet(w, piece):
		_schodki_slab(q, top, top + 0.06, SCHODKI_BOARD.darkened(0.12), SCHODKI_BOARD)


## Walls round `poly` from y0 to y1, then a flat top (when `top_col` has alpha).
func _schodki_slab(poly: PackedVector2Array, y0: float, y1: float, wall: Color, top_col: Color) -> void:
	if y1 <= y0:
		return
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		if p.distance_to(q) < 0.02:
			continue
		var o := _out(poly, p, q)
		_quad(Vector3(p.x, y0, p.y), Vector3(q.x, y0, q.y), Vector3(q.x, y1, q.y), Vector3(p.x, y1, p.y),
				Vector3(o.x, 0.0, o.y).normalized(), wall)
	if top_col.a > 0.0:
		_cap_piece(poly, y1, top_col)


## The top edge: a 0.5 m coping along it and a low lamp post every ~25 m just behind it.
func _schodki_top(ring: PackedVector2Array, f: Dictionary, ha: float) -> void:
	var a: Vector2 = f["a"]
	var d: Vector2 = f["d"]
	var side: Vector2 = f["side"]
	# The two corners nearest the promenade (least way down), west to east along the band.
	var order: Array = []
	for q in ring:
		order.append(q)
	order.sort_custom(func(p: Vector2, q: Vector2) -> bool: return (p - a).dot(d) < (q - a).dot(d))
	var t0: Vector2 = order[0]
	var t1: Vector2 = order[1]
	if (t0 - a).dot(side) > (t1 - a).dot(side):
		var sw := t0
		t0 = t1
		t1 = sw
	var coping := PackedVector2Array([t0, t1, t1 - d * 0.5, t0 - d * 0.5])
	var g := minf(_ground_under(coping), ha - 0.4)
	_schodki_slab(coping, g - 0.05, ha + 0.12, SCHODKI_COPING.darkened(0.1), SCHODKI_COPING)
	var span := t0.distance_to(t1)
	var lamps := maxi(1, roundi(span / SCHODKI_LAMP_GAP))
	for i in lamps:
		var p := t0.lerp(t1, (i + 0.5) / lamps) - d * 1.0
		var y: float = map.terrain_height(p.x, p.y)
		var head := p + d * 0.7
		_mode = M_STONE
		_beam(Vector3(p.x, y - 0.1, p.y), Vector3(p.x, y + 3.5, p.y), 0.12, SCHODKI_POST)
		_beam(Vector3(p.x, y + 3.45, p.y), Vector3(head.x, y + 3.45, head.y), 0.07, SCHODKI_POST)
		_prism(_circle(head, 0.2, 4), y + 3.2, y + 3.45, Color("#ffd27a"), Color("#1e1e22"), M_LAMP, M_STONE)


## The seats plan for crowds.gd, one SUNKEN entry (`schodki_wisla`, `schodki_wisla_w`): {"seats": [[point, yaw,
## tread k, group]], "standing": [[point, yaw]] on the quay, "centre", "stair": key, "n": rows, "guitar": a seat
## on a middle row}. Groups of 2-7 about 0.6 m apart with 1-3 m between them on every tread row, none within
## 1 m of a walking stair, facing the water; tread k's top is lerp(ha, hb, k / n) (`_schodki_band`).
static func schodki_plan(e: Dictionary) -> Dictionary:
	if e.is_empty():
		return {"seats": [], "standing": [], "centre": Vector2.ZERO, "stair": "", "n": 1, "guitar": Vector2.ZERO}
	var ring := PackedVector2Array(e["ring"])
	var a: Vector2 = e["a"]
	var b: Vector2 = e["b"]
	var f := _schodki_frame(ring, a, b)
	var d: Vector2 = f["d"]
	var side: Vector2 = f["side"]
	var length: float = f["reach"]
	var n := int(e["rows"])
	var tread := length / n
	var yaw := atan2(-d.x, -d.y)
	var grown: Array[PackedVector2Array] = []
	for c: PackedVector2Array in schodki_cuts():
		var g := Geometry2D.offset_polygon(c, 1.0, Geometry2D.JOIN_MITER)
		grown.append(g[0] if not g.is_empty() else c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1968 + int(absf(a.x))
	var seats: Array = []
	var gid := 0
	for k in n:
		var line := PackedVector2Array([a + d * ((k + 0.62) * tread) + side * float(f["lo"]),
				a + d * ((k + 0.62) * tread) + side * float(f["hi"])])
		for run: Array in _schodki_runs(line, ring, grown):
			var origin: Vector2 = run[0]
			var way: Vector2 = (run[1] as Vector2) - origin
			var reach := way.length()
			way /= maxf(reach, 0.001)
			var x := rng.randf_range(0.3, 1.5)
			while x < reach - 0.6:
				var size := mini([2, 2, 3, 3, 4, 4, 5, 6, 7][rng.randi() % 9], int((reach - x) / 0.6))
				if size < 2:
					break
				if rng.randf() < 0.7:
					for i in size:
						var p := origin + way * (x + i * 0.6) + d * rng.randf_range(-0.08, 0.08)
						seats.append([p, yaw + rng.randf_range(-0.4, 0.4), k, gid])
					gid += 1
				x += size * 0.6 + rng.randf_range(1.0, 3.0)
	# The quay: small standing groups 1.1 m past the foot line.
	var standing: Array = []
	var qline := PackedVector2Array([a + d * (length + 1.1) + side * float(f["lo"]), a + d * (length + 1.1) + side * float(f["hi"])])
	for run: Array in _schodki_runs(qline, ring, grown):
		var origin: Vector2 = run[0]
		var way: Vector2 = (run[1] as Vector2) - origin
		var reach := way.length()
		way /= maxf(reach, 0.001)
		var x := rng.randf_range(0.5, 3.0)
		while x < reach - 0.7:
			var size := mini(rng.randi_range(2, 5), int((reach - x) / 0.7))
			if size < 2:
				break
			for i in size:
				standing.append([origin + way * (x + i * 0.7), yaw + rng.randf_range(-0.4, 0.4)])
			x += size * 0.7 + rng.randf_range(3.0, 8.0)
	# The guitarist: on the fifth row, a few metres along from the axis, clear of a stair.
	var guitar := a + d * (4.62 * tread)
	for x: float in [2.0, 3.0, 4.0, 5.0, 6.0, -3.0, -4.0, -5.0, 8.0, 10.0]:
		var cand := a + d * (4.62 * tread) + side * x
		var clear := Geometry2D.is_point_in_polygon(cand, ring)
		for c: PackedVector2Array in grown:
			if Geometry2D.is_point_in_polygon(cand, c):
				clear = false
		if clear:
			guitar = cand
			break
	return {"seats": seats, "standing": standing, "centre": (a + b) * 0.5, "stair": str(e["key"]), "n": n, "guitar": guitar}


## The parts of `line` inside `ring` and outside every cut, as [from, to] pairs of at least 1 m.
static func _schodki_runs(line: PackedVector2Array, ring: PackedVector2Array, cuts: Array[PackedVector2Array]) -> Array:
	var runs: Array = []
	var inside: Array = Geometry2D.intersect_polyline_with_polygon(line, ring)
	for seg: PackedVector2Array in inside:
		var pieces: Array = [seg]
		for c: PackedVector2Array in cuts:
			var next: Array = []
			for pc: PackedVector2Array in pieces:
				next.append_array(Geometry2D.clip_polyline_with_polygon(pc, c))
			pieces = next
		for pc: PackedVector2Array in pieces:
			if pc.size() >= 2 and pc[0].distance_to(pc[pc.size() - 1]) >= 1.0:
				runs.append([pc[0], pc[pc.size() - 1]])
	return runs
