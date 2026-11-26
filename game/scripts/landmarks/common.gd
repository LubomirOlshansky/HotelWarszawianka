extends "res://scripts/facade_kit.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, what two or more areas share
## (and the core's site helpers): the site list and the map data, the ground, the colliders and the
## small parts every area calls. Moved as it was from the one big file. landmarks.gd is the class
## the game makes; every file of game/scripts/landmarks/ is one link of its base chain
## (facade_kit.gd, common.gd, then the areas in the order of landmarks.gd's `extends` chain), so
## code here may use this file, common.gd and the facade kit, never another area: a helper two areas
## need goes to common.gd.
const TarasyScreen := preload("res://scripts/tarasy_screen.gd")  # the screen block over the entrance
const Neon := preload("res://scripts/neon_signs.gd")  # the dusk loop: sign sizes
const PixelFont := preload("res://scripts/pixel_font.gd")  # the Powiśle letters' strokes

const GOLD := Color("#e8b632")

var data: Dictionary
## Replaced zones: {"key", "zone": Array[PackedVector2Array] (drop what stands inside),
## "keep": Array[PackedVector2Array] (but not inside these), "box": Rect2}.
var sites: Array[Dictionary] = []

## The landmarks loop: big signs on the landmarks for map_builder's _build_landmark_signs:
## [word (neon_signs.gd LANDMARK_WORDS), bottom middle, outward normal, scale, tube colour].
var signs: Array = []
## Collision outlines a site hands to map_builder's `_bridge_pockets`, so the slits and notches
## between it and the kept buildings next door get the same low collider walls as two kept
## buildings would (Jabłkowski's corner by the glass block on the Chmielna square, PT-7). Opt-in:
## a site appends its own ring; filled anew by each `build`.
var pocket_rings: Array[PackedVector2Array] = []
## The city objects plan, step 4: the site being built, the hint its colliders hand map_builder's
## `_solid` (game/tools/check_colliders.gd names the site in a finding).
var _r2 := {}
## Circles ([centre, radius]) no tree may grow in: a landmark's overhang (Powiśle's saucer).
var tree_free: Array = []
## Laser-scanned trees a landmark re-sizes ([centre, near, top, radius, kind], world x, z, metres
## over the ground): the one tree within `near` of `centre` takes this height, crown radius and
## kind, and turns the latest of its kind in autumn. The oak on Plac Zamkowy in its stone bench,
## which the 2023 scan caught as a 15 m tree with a 4 m crown (F's photo, 2026-11-26).
var tree_set: Array = []
## Plans ([ring, its box], world x, z) no parked car stands in: a market or a fair on a car park
## (Jarmark Warszawski on Plac Defilad), read by map_builder's parked cars on both city paths.
var parked_free: Array = []
## F's look check (2026-11-03): kept LoD2 parts a model replaces above a height, for map_builder
## `_top_lod2`: [ring (world x, z), metres over the ground at `at`, at]. Set while finding the
## sites, so the LoD2 pass (before `build`) sees them.
var lod2_tops: Array = []


func _pts(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(flat[i], flat[i + 1]))
	return out


## The landmarks loop: the outline of the tallest building (or part) standing on `at`, for a
## tower OpenStreetMap leaves unnamed (The Warsaw HUB).
func _tallest_at(at: Vector2) -> PackedVector2Array:
	var best := PackedVector2Array()
	var top := 0.0
	for b in data.get("buildings", []):
		if float(b["h"]) <= top:
			continue
		var q := _pts(b["p"])
		if q.size() >= 3 and Geometry2D.is_point_in_polygon(at, q):
			best = q
			top = float(b["h"])
	return best


func _landmark(name: String) -> PackedVector2Array:
	for l in data.get("landmarks", []):
		if l["name"] == name:
			return _pts(l["p"])
	return PackedVector2Array()


func _box_of(polys: Array) -> Rect2:
	var box := Rect2()
	var first := true
	for poly: PackedVector2Array in polys:
		for q in poly:
			if first:
				box = Rect2(q, Vector2.ZERO)
				first = false
			else:
				box = box.expand(q)
	return box.grow(2.0)


func _add_site(key: String, zone: Array, keep: Array = []) -> void:
	var z: Array[PackedVector2Array] = []
	for p: PackedVector2Array in zone:
		if p.size() >= 3:
			z.append(p)
	if z.is_empty():
		return
	var k: Array[PackedVector2Array] = []
	for p: PackedVector2Array in keep:
		if p.size() >= 3:
			k.append(p)
	sites.append({"key": key, "zone": z, "keep": k, "box": _box_of(z)})


## OpenStreetMap buildings (or parts) whose centre lies inside `poly` and that `test` accepts.
func _parts_in(poly: PackedVector2Array, test: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var box := _box_of([poly])
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		var c := _centre(q)
		# A bent footprint (Equator II's curve) can have its centroid outside itself: the outline's own building still counts.
		var own := q.size() == poly.size() and q[0].is_equal_approx(poly[0])
		if (own or box.has_point(c) and Geometry2D.is_point_in_polygon(c, poly)) and test.call(bld):
			out.append(bld)
	return out


# --- emitting ----------------------------------------------------------------------------

## Car collision along a ring at street level (like map_builder's buildings).
func _collide(ring: PackedVector2Array) -> void:
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		# An edge over a tunnel goes in 4 m pieces, each foot kept out of the traffic below.
		var steps := 1
		var n := ceili(a.distance_to(b) / 4.0)
		for k in range(1, n):
			if not is_nan(map.tunnel_floor_under(lerpf(a.x, b.x, float(k) / n), lerpf(a.y, b.y, float(k) / n))):
				steps = n
				break
		var p0 := a
		var g0: float = _collide_foot(a)
		for k in range(1, steps + 1):
			var p1 := a.lerp(b, float(k) / steps)
			var g1: float = _collide_foot(p1)
			map._solid(&"landmark", [Vector3(p0.x, g0, p0.y), Vector3(p1.x, g1, p1.y), Vector3(p1.x, g1 + 6.0, p1.y),
					Vector3(p0.x, g0, p0.y), Vector3(p1.x, g1 + 6.0, p1.y), Vector3(p0.x, g0 + 6.0, p0.y)], _r2)
			p0 = p1
			g0 = g1


## The foot of a landmark's collision ring: a metre under the ground, but never down into a
## tunnel's traffic (the Copernicus Science Centre stands over Tunel Wisłostrady: its ring's
## edges from the river side's lower ground reached the buses' roofs, check_drive 2026-11-01).
func _collide_foot(p: Vector2) -> float:
	var foot: float = map.terrain_height(p.x, p.y) - 1.0
	var floor_y: float = map.tunnel_floor_under(p.x, p.y)
	return foot if is_nan(floor_y) else maxf(foot, floor_y + 4.6)


## Loop 3b: car collision along a ring between two heights.
func _collide_span(ring: PackedVector2Array, y0: float, y1: float) -> void:
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		map._solid(&"landmark", [Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y),
				Vector3(a.x, y0, a.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y)], _r2)


func _ground_under(poly: PackedVector2Array) -> float:
	var g := INF
	for q in poly:
		g = minf(g, map.terrain_height(q.x, q.y))
	return g if g < INF else 0.0


# --- The Palace's venues (F, 2026-11-07: "add the entertainment the Palace has, Bar Studio and the others")

## A clock dial facing `n` (plan, unit) centred at plan point c, height y: a cream disc
## with a gold rim and hour marks (it lights up at night). Loop 1: the hands are drawn by
## building.gdshader from the disc's UV (the point on the dial in radii, x to the right as
## seen from outside, y up, both minus 10 so the shader takes it for a roof) and show the
## time in Warsaw (main.gd sets `clock_hands` once a minute).
func _dial(c: Vector2, y: float, n: Vector2, r: float, face := Color("#f4ecd6"), ink := Color("#26232a")) -> void:
	var side := Vector2(-n.y, n.x)
	var n3 := Vector3(n.x, 0.0, n.y)
	var centre := Vector3(c.x, y, c.y) + n3 * 0.05
	var seg := 20
	_mode = M_GOLD
	for k in seg:
		var t0 := TAU * k / seg
		var t1 := TAU * (k + 1) / seg
		var e0 := Vector3(side.x * cos(t0), sin(t0), side.y * cos(t0))
		var e1 := Vector3(side.x * cos(t1), sin(t1), side.y * cos(t1))
		_quad(centre + e0 * r * 1.12, centre + e1 * r * 1.12, centre + e1 * r, centre + e0 * r, n3, GOLD)
	_mode = M_DIAL
	var disc := centre + n3 * 0.04
	# `side` points to the left of someone looking at the dial from outside.
	for k in seg:
		var t0 := TAU * k / seg
		var t1 := TAU * (k + 1) / seg
		_tri(disc, disc + Vector3(side.x * cos(t0), sin(t0), side.y * cos(t0)) * r,
				disc + Vector3(side.x * cos(t1), sin(t1), side.y * cos(t1)) * r, n3, face,
				Vector2(-10, -10), Vector2(-cos(t0) - 10.0, sin(t0) - 10.0), Vector2(-cos(t1) - 10.0, sin(t1) - 10.0), -1.0)
	_mode = M_STONE
	var front := disc + n3 * 0.05
	for k in 12:
		var t := TAU * k / 12.0
		var dir := Vector3(side.x * cos(t), sin(t), side.y * cos(t))
		var across := Vector3(side.x * -sin(t), cos(t), side.y * -sin(t)) * (0.16 if k % 3 == 0 else 0.09)
		var p0 := front + dir * r * 0.78
		var p1 := front + dir * r * 0.93
		_quad(p0 - across, p1 - across, p1 + across, p0 + across, n3, ink)


# --- Złote Tarasy -----------------------------------------------------------------------------

## The mean ground height under a plan outline's corners.
func _mean_ground(poly: PackedVector2Array) -> float:
	var sum := 0.0
	for q in poly:
		sum += map.terrain_height(q.x, q.y)
	return sum / maxf(poly.size(), 1.0)


# --- Varso Place (Krajobraz K3, docs/landmarks/specs/varso_place.md) -----------------------------

const VARSO_LEAF := Color("#5f7f45")

const VARSO_DECK := Color("#a58a69")

const VARSO_TRUNK := Color("#5b4b3d")


## A small tree with a round crown (the hawthorns' spheres): a trunk, then two six-sided frusta
## widening to the crown's waist and closing over it.
func _varso_tree(p: Vector2, y: float, h: float, r: float) -> void:
	_prism(_square(p, 0.12), y, y + h * 0.42, VARSO_TRUNK, Color(0, 0, 0, 0), M_STONE)
	_mode = M_STONE
	_frustum(_circle(p, r * 0.3, 6), y + h * 0.32, _circle(p, r, 6), y + h * 0.62, VARSO_LEAF.darkened(0.12))
	_frustum(_circle(p, r, 6), y + h * 0.62, _circle(p, r * 0.4, 6), y + h, VARSO_LEAF, VARSO_LEAF.lightened(0.08))


# --- Q22 and Rondo 1 (the top-50 photo pass, 2026-11-08) ---------------------------------------

func _dist_to_ring(p: Vector2, ring: PackedVector2Array) -> float:
	var best := INF
	for i in ring.size():
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])))
	return best


const DUSK_RED := Color(1.0, 0.12, 0.1)


# --- Centrum LIM's podium (F's night photos, 2026-11-06) ----------------------------------------

## The dusk loop: a lit name on the two faces of `poly` that face the camera most, south and
## east, centred `drop` m under `top_y`, the word spanning `share` of the face's width. Only
## the long faces count (at least half the longest edge), so a corner chamfer never carries one.
func _crown_signs(poly: PackedVector2Array, top_y: float, word: String, colour: Color, drop := 3.0, share := 0.7,
		vertical := false) -> void:
	var longest := 0.0
	for i in poly.size():
		longest = maxf(longest, poly[i].distance_to(poly[(i + 1) % poly.size()]))
	var picked: Array[int] = []
	for d: Vector2 in [Vector2(0, 1), Vector2(1, 0)]:
		var best := -1
		var best_dot := 0.3
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			if a.distance_to(b) < longest * 0.5:
				continue
			var dot := _out(poly, a, b).dot(d)
			if dot > best_dot:
				best_dot = dot
				best = i
		if best >= 0 and not picked.has(best):
			picked.append(best)
	for i in picked:
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var o := _out(poly, a, b)
		var mid := (a + b) * 0.5
		if vertical:
			# One letter per sign, stacked: each 1.8 m glyph box grown by k, `drop` under the top.
			var kv := 3.2
			var step := Neon.ROW_H * Neon.PIXEL * kv
			for n in word.length():
				var top := top_y - drop - step * n
				signs.append([word[n], Vector3(mid.x, top - step, mid.y), Vector3(o.x, 0.0, o.y), kv, colour])
			continue
		var k := share * a.distance_to(b) / Neon.length_of(word)
		var base_y := top_y - drop - Neon.ROW_H * Neon.PIXEL * k * 0.5
		signs.append([word, Vector3(mid.x, base_y, mid.y), Vector3(o.x, 0.0, o.y), k, colour])


## The dusk loop: red aviation lights, 0.7 m lamp boxes, on a roof's outline at the south-west,
## south-east and north-east corners of its bounding box (each clamped into the outline, then
## drawn in a little); three, to keep to 30 triangles. `roof_y` gives the roof's height at a point.
func _aviation(poly: PackedVector2Array, roof_y: Callable) -> void:
	var lo := poly[0]
	var hi := poly[0]
	for q in poly:
		lo = lo.min(q)
		hi = hi.max(q)
	var c := _centre(poly)
	for corner: Vector2 in [Vector2(lo.x, hi.y), hi, Vector2(hi.x, lo.y)]:
		var p := corner
		if not Geometry2D.is_point_in_polygon(p, poly):
			var near := p
			var best := INF
			for i in poly.size():
				var q := Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()])
				if q.distance_to(p) < best:
					best = q.distance_to(p)
					near = q
			p = near
		p += (c - p).normalized() * minf(0.8, p.distance_to(c))
		var y: float = roof_y.call(p)
		_prism(_square(p, 0.35), y, y + 0.7, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)


# --- the low-rise landmarks (the landmarks loop) -----------------------------------------------

## Buildings kept as LoD2 draws them (their real massing) but in their own stone, brick and roof
## colours (like the museum, `skin_at`), each with a card: what a player passes most, from the
## theatre and the castle to the churches on the royal route. `mode` M_MONUMENT draws tall
## windows between piers (plastered and stone fronts), M_STONE a plain wall (brick, the science
## centre's dark slabs). Colours from photographs, a step paler than life.
const ZAMEK_WALL := "#cf9580"  # salmon plaster (was #c87560: it read brick-red and loud)
const ZAMEK_ROOF := "#a9534a"  # tile, a coral red (fix round 1; was #ad5c3f, read orange)


# --- Rynek Starego Miasta and its Syrenka (F, 2026-11-01) -------------------------------------

const RYNEK_FOUNTAIN := Vector2(-806.5, -1745.5)

const RYNEK_FENCE := Color("#4f3424")

const RYNEK_STONE_HI := Color("#e0dac8")
const RYNEK_BRONZE := Color("#7ba892")
const RYNEK_BRONZE_SHADE := Color("#5a8873")
const RYNEK_BRONZE_DEEP := Color("#3f6656")
const RYNEK_BRONZE_HI := Color("#a8d0bb")
const RYNEK_TABLE := Color("#ece6d8")
const RYNEK_CHAIR := Color("#5a3b26")


## One café set: a round-ish table on a pole, two chairs, a square umbrella 3.4 m across on
## the pole (its canopy a low pyramid in `col`). 52 triangles; with `fence`, the garden's low
## dark-wood fence on the square's side (12 more).
func _umbrella(p: Vector2, yaw: float, y: float, col: Color, fence := false) -> void:
	_o = p
	_a = Vector2(sin(yaw), cos(yaw))
	_b = Vector2(-_a.y, _a.x)
	_mode = M_STONE
	if fence:
		# The garden's fence, 1.9 m out towards the fountain, one umbrella's length.
		var v := 1.9 if _b.dot(RYNEK_FOUNTAIN - p) > 0.0 else -1.9
		_lbox(0.0, v, 1.6, 0.05, y, y + 0.85, RYNEK_FENCE, M_STONE, RYNEK_FENCE.lightened(0.15))
	_lbox(0.0, 0.0, 0.04, 0.04, y, y + 2.75, RYNEK_STONE_HI.darkened(0.45), M_STONE)
	_lbox(0.0, 0.0, 0.4, 0.4, y + 0.72, y + 0.77, RYNEK_TABLE, M_STONE)
	for v: float in [-0.8, 0.8]:
		_lbox(0.0, v, 0.2, 0.2, y, y + 0.45, RYNEK_CHAIR, M_STONE)
	_pyramid(_rect(0.0, 0.0, 1.7, 1.7), y + 2.25, y + 2.9, col)


# --- Muzeum Narodowe and Plac Piłsudskiego (the museum and Plac loop, 2026-10-31) ----------------

## A closed outline with the steps under `tol` metres dropped (Douglas-Peucker), so walls run
## straight between the mapped corners (the museum's outline has 481 points: every pier).
func _simplify(ring: PackedVector2Array, tol: float) -> PackedVector2Array:
	var far := 0
	for i in ring.size():
		if ring[i].distance_squared_to(ring[0]) > ring[far].distance_squared_to(ring[0]):
			far = i
	if far == 0:
		return ring
	var back := ring.slice(far)
	back.append(ring[0])
	var out := _dp(ring.slice(0, far + 1), tol)
	out.resize(out.size() - 1)
	var rest := _dp(back, tol)
	rest.resize(rest.size() - 1)
	out.append_array(rest)
	return out if out.size() >= 3 else ring


func _dp(pts: PackedVector2Array, tol: float) -> PackedVector2Array:
	var best := -1.0
	var at := 0
	for i in range(1, pts.size() - 1):
		var d := pts[i].distance_to(Geometry2D.get_closest_point_to_segment(pts[i], pts[0], pts[-1]))
		if d > best:
			best = d
			at = i
	if best <= tol:
		return PackedVector2Array([pts[0], pts[-1]])
	var out := _dp(pts.slice(0, at + 1), tol)
	out.resize(out.size() - 1)
	out.append_array(_dp(pts.slice(at), tol))
	return out


# --- Behind the Eastern Wall: the re-clad tower and the 1960s slabs ---------------------------

## Faces the game's camera sees most (south and east): signs face the one nearest this.
const BEHIND_FACE := Vector2(0.349, 0.937)


## The OpenStreetMap outline standing at a point (the first outline holding it).
func _outline_at(at: Vector2) -> PackedVector2Array:
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() >= 3 and float(bld["mh"]) < 0.5 and _box_of([q]).has_point(at) and Geometry2D.is_point_in_polygon(at, q):
			return q
	return PackedVector2Array()


## The edge of `poly` whose outward normal is nearest `want`, among the longer edges.
func _edge_facing(poly: PackedVector2Array, want: Vector2, min_len: float) -> int:
	var best := -1
	var score := -INF
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.distance_to(b) < min_len:
			continue
		var sc := _out(poly, a, b).dot(want)
		if sc > score:
			score = sc
			best = i
	return best


# --- TR Warszawa's building site ----------------------------------------------------------

## A round arch's spandrel in the plane v = `v` of the local frame: the wall between y_spring
## and y_top from u0 to u1, less a half circle over the opening (six steps).
func _arch(u0: float, u1: float, v: float, y_spring: float, y_top: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var r := (u1 - u0) * 0.5
	var cu := (u0 + u1) * 0.5
	var n2 := _b * signf(v)
	var n := Vector3(n2.x, 0.0, n2.y)
	var steps := 6
	var at := func(u: float, y: float) -> Vector3:
		var p := _w(u, v)
		return Vector3(p.x, y, p.y)
	var uv := func(u: float, y: float) -> Vector2: return Vector2(u - u0, y - _g)
	var top := y_top - _g
	var prev := Vector2(u0, y_spring)
	for k in range(1, steps + 1):
		var ang := PI - PI * k / steps
		var cur := Vector2(cu + cos(ang) * r, y_spring + sin(ang) * r)
		var corner := Vector2(u0 if k * 2 <= steps else u1, y_top)
		_tri(at.call(corner.x, corner.y), at.call(prev.x, prev.y), at.call(cur.x, cur.y), n, col,
				uv.call(corner.x, corner.y), uv.call(prev.x, prev.y), uv.call(cur.x, cur.y), top)
		prev = cur
	_tri(at.call(u0, y_top), at.call(cu, y_spring + r), at.call(u1, y_top), n, col,
			uv.call(u0, y_top), uv.call(cu, y_spring + r), uv.call(u1, y_top), top)
	_mode = keep


# --- Plac Piłsudskiego, part 2 (2026-10-31) ---------------------------------------------------

const LOR_NAME := "Puro Warszawa Centrum"
const LOR_HEIGHT := 27.4  # OSM's height of the hotel, its street block's `cap`


## LORETKA's terrace plan, read by this model and by crowds.gd's couples (one source, so they
## sit on its poufs): from HOTEL PIURE's outline in `data` (empty without it, or under 15 m) the
## frame (`o` a corner of the longest front, `a` along it, `b` inwards), the hotel's height `h`
## over its lowest ground, the deck's span (`u0`..`u1` along, `v0`..`v1` across), the tables
## (local [u, v]) and the seats [world point, yaw facing the table], two to a table, table by table.
static func loretka_plan(data: Dictionary) -> Dictionary:
	var outline := PackedVector2Array()
	for l: Dictionary in data.get("landmarks", []):
		if str(l.get("name", "")) == LOR_NAME:
			var flat: Array = l["p"]
			for i in range(0, flat.size() - 1, 2):
				outline.append(Vector2(float(flat[i]), float(flat[i + 1])))
	if outline.size() < 3:
		return {}
	var n := outline.size()
	var best := 0
	var longest := 0.0
	var c := Vector2.ZERO
	for i in n:
		c += outline[i]
		var l := outline[i].distance_to(outline[(i + 1) % n])
		if l > longest:
			longest = l
			best = i
	c /= float(n)
	var o := outline[best]
	var a := (outline[(best + 1) % n] - o).normalized()
	var b := Vector2(-a.y, a.x)
	if (c - o).dot(b) < 0.0:
		b = -b
	# The hotel's height: its tallest mapped part whose middle is inside the outline (the
	# streamed city's index has the parts as `site_parts` only: bake_sectors.py SITE_NAMES).
	var h := 0.0
	for bld: Dictionary in data.get("buildings", data.get("site_parts", [])):
		var flat: Array = bld["p"]
		if flat.size() < 6:
			continue
		var m := Vector2.ZERO
		for i in range(0, flat.size() - 1, 2):
			m += Vector2(float(flat[i]), float(flat[i + 1]))
		m /= float(flat.size() / 2)
		if m.distance_to(c) < longest and Geometry2D.is_point_in_polygon(m, outline):
			h = maxf(h, float(bld["h"]))
	if h <= 0.0 and not data.has("buildings") and not data.has("site_parts"):
		# The prebuilt city's index (map/index.res) carries neither: the hotel's mapped height, which
		# is also its street block's roof (street_blocks/index.json `cap`), so the terrace and its
		# couples are there on both city paths.
		h = LOR_HEIGHT
	if h < 15.0:
		return {}
	# The deck on the front's first half, as deep as the slab is where it is thinnest there.
	var u0 := 1.4
	var u1 := minf(26.0, longest * 0.55)
	var depth := INF
	for u: float in [u0 + 0.5, (u0 + u1) * 0.5, u1 - 0.5]:
		var from := o + a * u + b * 0.05
		for i in n:
			if i == best:
				continue
			var hit: Variant = Geometry2D.segment_intersects_segment(from, from + b * 60.0, outline[i], outline[(i + 1) % n])
			if hit != null:
				depth = minf(depth, from.distance_to(hit) + 0.05)
	if depth == INF or depth < 8.0:
		return {}
	var v0 := 1.3
	var v1 := depth - 1.3
	var tables: Array = []
	var seats: Array = []
	var cols := 4
	for k in cols:
		var u := lerpf(u0 + 2.6, u1 - 4.6, float(k) / float(cols - 1))
		for v: float in [lerpf(v0, v1, 0.3), lerpf(v0, v1, 0.72)]:
			tables.append(Vector2(u, v))
			for side: float in [-1.0, 1.0]:
				var p := o + a * (u + side * 0.8) + b * v
				var face := -a * side
				seats.append([p, atan2(-face.x, -face.y)])
	return {"o": o, "a": a, "b": b, "h": h, "outline": outline, "u0": u0, "u1": u1, "v0": v0, "v1": v1,
			"tables": tables, "seats": seats}


func _box_poly(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


# --- Plac Małachowskiego and the Presidential Palace (2026-10-31) ------------------------------

const MIROWSKA_TRIM := Color("#d6ccb4")

const MIROWSKA_GLASS := Color("#323a40")


## A round-headed window: a cream surround behind a dark glass pane.
func _arch_win(at: Vector2, along: Vector2, out: Vector2, hw: float, y0: float, spring: float,
		glass := MIROWSKA_GLASS) -> void:
	_arch_panel(at, along, out, hw + 0.3, y0 - 0.25, spring, MIROWSKA_TRIM, 0.04, M_STONE)
	_arch_panel(at, along, out, hw, y0, spring, glass, 0.08, M_GLASS)


const ZAMEK_VISTULA := Color("#ede6d8")   # the Vistula (Saxon) front, a warm cream-white (Fable 2026-11-26)

## The Clock Tower (Wieża Zegarowa) in the middle of the west front, and the front's way north.
const ZAMEK_CLOCK := Vector2(-671.0, -1519.3)
const ZAMEK_FRONT := Vector2(0.0605, -0.9982)


# --- Arkady Kubickiego and the castle gardens ---------------------------------------------------

## A pointed (equilateral) panel on a wall: a rectangle to the spring line and a lancet head of
## two arcs meeting at the apex, three steps a side. `at` is the foot centre in plan, `along` the
## wall's direction, `out` its outward normal, `proud` how far it stands off the wall.
func _lancet_panel(at: Vector2, along: Vector2, out: Vector2, hw: float, y0: float, spring: float, col: Color,
		proud: float, mode: float) -> void:
	var keep := _mode
	_mode = mode
	var p := at + out * proud
	_wall(p - along * hw, p + along * hw, y0, spring, out, col)
	var n := Vector3(out.x, 0.0, out.y)
	var t := Vector3(along.x, 0.0, along.y)
	var c := Vector3(p.x, spring, p.y)
	var r := hw * 2.0
	var steps := 3
	for s: float in [-1.0, 1.0]:
		# the arc on this side is centred at the other spring point
		var prev: Vector3 = c + t * (hw * s)
		for k in range(1, steps + 1):
			var ang: float = PI / 3.0 * k / steps
			var q: Vector3 = c + t * (s * (r * cos(ang) - hw)) + Vector3.UP * (r * sin(ang))
			_tri(c, prev, q, n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
			prev = q
	_mode = keep


## A thin square post at world point c (a finial).
func _lbox_at(c: Vector2, half: float, y0: float, y1: float, col: Color) -> void:
	_prism(_circle(c, half, 4), y0, y1, col, col, M_STONE, M_STONE)


# --- Filharmonia Narodowa and Teatr Polski ----------------------------------------------------

const ZB_LAMP := Color("#ffe9bd")


# --- The Cepelia pavilion and Zodiak (F's photos, 2026-11-08) ---------------------------------

## Puts the local frame on a pavilion: _o the outline's centre, _a along `along`, _b turned to
## `front`. Returns the outline's extent in (u, v).
func _pav_frame(outline: PackedVector2Array, along: Vector2, front: Vector2) -> Rect2:
	var c := Vector2.ZERO
	for q in outline:
		c += q
	_o = c / outline.size()
	_a = along.normalized()
	_b = Vector2(-_a.y, _a.x)
	if _b.dot(front) < 0.0:
		_b = -_b
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in outline:
		var l := _local(q)
		lo = lo.min(l)
		hi = hi.max(l)
	return Rect2(lo, hi - lo)


## A box between u0..u1 and v0..v1 in the local frame.
func _ubox(u0: float, u1: float, v0: float, v1: float, y0: float, y1: float, col: Color, mode := M_STONE,
		top_col := Color(0, 0, 0, 0)) -> void:
	_lbox((u0 + u1) * 0.5, (v0 + v1) * 0.5, (u1 - u0) * 0.5, (v1 - v0) * 0.5, y0, y1, col, mode, top_col)


func _urect(u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	return _rect((u0 + u1) * 0.5, (v0 + v1) * 0.5, (u1 - u0) * 0.5, (v1 - v0) * 0.5)


## A sign word at local (u, v), height y, facing `face` (a plan direction), about `w` m long.
func _usign(word: String, u: float, v: float, y: float, face: Vector2, w: float, h: float, col: Color) -> void:
	var p := _w(u, v)
	var k := minf(w / Neon.length_of(word), h / (Neon.ROW_H * Neon.PIXEL))
	signs.append([word, Vector3(p.x, y, p.y), Vector3(face.x, 0.0, face.y), k, col])


# --- Warszawa Powiśle (S2 of docs/design/railway.md, 2026-11-01) -------------------------------

const POW_DARK := Color("#2f3236")


## A box on the ground plan: centre `p`, its u axis `d` (unit), half sizes hu along and hv across.
func _pow_box(p: Vector2, d: Vector2, hu: float, hv: float, y0: float, y1: float, wall: Color, top: Color, mode := M_STONE) -> void:
	var e := Vector2(-d.y, d.x)
	var poly := PackedVector2Array([p - d * hu - e * hv, p + d * hu - e * hv, p + d * hu + e * hv, p - d * hu + e * hv])
	_prism(poly, y0, y1, wall, top, mode, mode)


## A letter's lit pixels (x, row; rows as PixelFont's, the body from row BODY): the neon atlas's
## own font where it has the letter (so the glow at night sits on the tubes), else PixelFont's.
static func _pow_glyph(ch: String) -> Array[Vector2i]:
	if not Neon.FONT.has(ch):
		return PixelFont.pixels(ch)
	var out: Array[Vector2i] = []
	var rows: Array = Neon.FONT[ch]
	for y in rows.size():
		var line: String = rows[y]
		for x in line.length():
			if line[x] == "#":
				out.append(Vector2i(x, PixelFont.BODY + y))
	return out


static func _pow_glyph_w(ch: String) -> int:
	return (Neon.FONT[ch][0] as String).length() if Neon.FONT.has(ch) else PixelFont.char_width(ch)


func _pow_festoon(p: Vector3, q: Vector3, sag: float, n: int) -> void:
	var prev := p
	for k in range(1, n + 1):
		var t := float(k) / n
		var at := p.lerp(q, t) - Vector3.UP * sag * 4.0 * t * (1.0 - t)
		_beam(prev, at, 0.03, POW_DARK, false)
		var keep := _mode
		_mode = M_LAMP
		var col := BARGE_BULB if k % 2 == 0 else BARGE_BULB_2
		var sq := PackedVector2Array([Vector2(at.x - 0.1, at.z - 0.1), Vector2(at.x + 0.1, at.z - 0.1),
				Vector2(at.x + 0.1, at.z + 0.1), Vector2(at.x - 0.1, at.z + 0.1)])
		_prism(sq, at.y - 0.22, at.y - 0.02, col, col, M_LAMP, M_LAMP)
		_mode = keep
		prev = at


# --- The river's barges (2026-11-01, docs/landmarks/specs/barki.md) ---------------------------

const BARGE_BULB := Color(1.0, 0.78, 0.42)
const BARGE_BULB_2 := Color(1.0, 0.55, 0.3)
const BARGE_POST := Color("#2b2c2f")


## A café umbrella over a small table at a local spot: the table, the pole, an eight-sided canopy.
func _barge_umbrella(u: float, v: float, y: float, r: float, col: Color) -> void:
	var none := Color(0, 0, 0, 0)
	_lbox(u, v, 0.35, 0.35, y, y + 0.75, Color("#3a3029"), M_STONE, Color("#5a4a3c"))
	_prism(_rect(u, v, 0.04, 0.04), y + 0.75, y + 2.3, BARGE_POST, none, M_STONE)
	_mode = M_STONE
	var ring := _circle(_w(u, v), r, 8)
	_pyramid(ring, y + 2.15, y + 2.6, col)


# --- The brick works: Norblin, Browary Warszawskie, Hala Koszyki, Elektrownia Powiśle -------------

## The landmark `name` whose outline lies near `at` (OSM repeats a name elsewhere in the city).
func _landmark_near(name: String, at: Vector2, reach: float) -> PackedVector2Array:
	for l in data.get("landmarks", []):
		if l["name"] == name:
			var q := _pts(l["p"])
			if q.size() >= 3 and _centre(q).distance_to(at) < reach:
				return q
	return PackedVector2Array()


## A ring grown by `d` (shrunk when negative): its largest piece, or empty.
func _grown(ring: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := Geometry2D.offset_polygon(ring, d, Geometry2D.JOIN_MITER)
	var best := PackedVector2Array()
	var a := 0.0
	for q: PackedVector2Array in out:
		var s := absf(_area(q))
		if s > a and not Geometry2D.is_polygon_clockwise(q):
			a = s
			best = q
	return best


# --- Krakowskie Przedmieście from photos (2026-11-02; first pass K1-K5 2026-11-01) -------------

const KP_GOLD := Color("#c9a24a")
const KP_DARK := Color("#3a3d40")

const KP_WOOD := Color("#4a3328")


## A balustrade in the local frame from (u0, v0) to (u1, v1): a plinth, a rail and a die every
## `step` metres (the balusters themselves are too small to read from the game's camera).
func _kp_balustrade(u0: float, v0: float, u1: float, v1: float, y: float, h: float, col: Color, step: float) -> void:
	var cu := (u0 + u1) * 0.5
	var cv := (v0 + v1) * 0.5
	var hu := maxf(absf(u1 - u0) * 0.5, 0.12)
	var hv := maxf(absf(v1 - v0) * 0.5, 0.12)
	_lbox(cu, cv, hu, hv, y, y + 0.18, col.darkened(0.06), M_STONE, col)
	_lbox(cu, cv, hu, hv, y + h - 0.16, y + h, col, M_STONE, col.lightened(0.04))
	var n := maxi(int(round(maxf(absf(u1 - u0), absf(v1 - v0)) / step)), 1)
	for k in n + 1:
		var t := float(k) / n
		_lbox(lerpf(u0, u1, t), lerpf(v0, v1, t), 0.14, 0.14, y + 0.18, y + h - 0.16, col, M_STONE, col)


## A standing figure on the local spot (cu, cv) from y, h tall, facing +v: the coat, the chest,
## the head a little forward.
func _kp_figure(cu: float, cv: float, y: float, h: float, col: Color) -> void:
	var c := _w(cu, cv)
	_frustum(_circle(c, h * 0.13, 8), y, _circle(c, h * 0.1, 8), y + h * 0.56, col)
	_frustum(_circle(c, h * 0.1, 8), y + h * 0.56, _circle(c, h * 0.075, 8), y + h * 0.84, col, col)
	_prism(_circle(_w(cu, cv + h * 0.012), h * 0.05, 8), y + h * 0.84, y + h, col, col, M_STONE, M_STONE)


## A round-headed opening drawn on a face at v (facing +_b): a rectangle up to the spring, a half
## disc over it.
func _kp_arch_open(cu: float, v: float, y0: float, y_spring: float, hw: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var n := Vector3(_b.x, 0.0, _b.y)
	var at := func(u: float, y: float) -> Vector3:
		var p := _w(u, v)
		return Vector3(p.x, y, p.y)
	var top := y_spring + hw - _g
	var none := Vector2(-1, -1)
	_quad(at.call(cu - hw, y0), at.call(cu + hw, y0), at.call(cu + hw, y_spring), at.call(cu - hw, y_spring), n, col,
			none, none, none, none, top)
	var centre: Vector3 = at.call(cu, y_spring)
	for k in 6:
		var a0 := PI * k / 6.0
		var a1 := PI * (k + 1) / 6.0
		_tri(centre, at.call(cu + cos(a0) * hw, y_spring + sin(a0) * hw), at.call(cu + cos(a1) * hw, y_spring + sin(a1) * hw),
				n, col, none, none, none, top)
	_mode = keep


# --- Old Town hotels -----------------------------------------------------------------------

const HOTEL_LAMP := Color("#ffd9a0")


## The ring pushed in by `d` metres at every vertex (a mitre; out when d < 0), same vertex count.
func _inset_ring(ring: PackedVector2Array, d: float) -> PackedVector2Array:
	var n := ring.size()
	var out := PackedVector2Array()
	for i in n:
		var a := ring[(i + n - 1) % n]
		var p := ring[i]
		var b := ring[(i + 1) % n]
		var n0 := _out(ring, a, p)
		var n1 := _out(ring, p, b)
		var den := maxf(1.0 + n0.dot(n1), 0.5)
		out.append(p - (n0 + n1) * (d / den))
	return out


## A pitched roof between two same-count rings (m0 at y0 up to m1 at y1), each face turned out of
## `ring` by its own edge, so an L-shaped plan keeps all its faces lit (`_frustum` turns them by
## the centre, which a concave plan fools).
func _slope(ring: PackedVector2Array, m0: PackedVector2Array, y0: float, m1: PackedVector2Array, y1: float, col: Color) -> void:
	var n := ring.size()
	for i in n:
		var j := (i + 1) % n
		var out := _out(ring, ring[i], ring[j])
		var p0 := Vector3(m0[i].x, y0, m0[i].y)
		var p1 := Vector3(m0[j].x, y0, m0[j].y)
		var p2 := Vector3(m1[j].x, y1, m1[j].y)
		var p3 := Vector3(m1[i].x, y1, m1[i].y)
		var nrm := (p1 - p0).cross(p3 - p0).normalized()
		if Vector2(nrm.x, nrm.z).dot(out) < 0.0:
			nrm = -nrm
		var l := m0[i].distance_to(m0[j])
		_quad(p0, p1, p2, p3, nrm, col, Vector2(0, y0 - _g), Vector2(l, y0 - _g), Vector2(l, y1 - _g), Vector2(0, y1 - _g), y1 - _g)


# --- The Vistula boulevards' dressing (2026-11-02, docs/landmarks/specs/bulwary.md) -----------

## A quad seen from both sides (canvas, a flap, a leg): its own normal and the reverse.
func _two_sided(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	var n := (b - a).cross(d - a).normalized()
	_quad(a, b, c, d, n, col)
	_quad(a, b, c, d, -n, col.darkened(0.12))


## A leżak, the striped deck chair of the boulevards, at a local spot on height y, facing +v
## (the river) or -v (face -1): a canvas sling from the foot rail to the raised back, a back leg.
func _bulwar_lezak(u: float, v: float, y: float, col: Color, face := 1.0) -> void:
	var hw := 0.28
	var foot := v + face * 0.55
	var mid := v
	var back := v - face * 0.6
	var p := func(du: float, dv: float, h: float) -> Vector3:
		var w := _w(u + du, dv)
		return Vector3(w.x, y + h, w.y)
	_two_sided(p.call(-hw, foot, 0.38), p.call(hw, foot, 0.38), p.call(hw, mid, 0.22), p.call(-hw, mid, 0.22), col)
	_two_sided(p.call(-hw, mid, 0.22), p.call(hw, mid, 0.22), p.call(hw, back, 0.86), p.call(-hw, back, 0.86), col)
	_two_sided(p.call(-hw, back, 0.86), p.call(hw, back, 0.86), p.call(hw, back - face * 0.3, 0.0), p.call(-hw, back - face * 0.3, 0.0),
			Color("#7a5a3e"))


# --- Bracka and Plac Trzech Krzyży: Vitkac, Jabłkowski's, the Sheraton (photo reports, 2026-11-03) ---

## The car's walls along a site's mapped outline (not the simplified ring the model is drawn
## from: a straightened edge would open a slit along a shared party wall), and the outline handed
## to the pocket bridging.
func _collide_raw(site: Dictionary) -> void:
	var raw: PackedVector2Array = site.get("raw", site["ring"])
	_collide(raw)
	pocket_rings.append(raw)


# --- Plac Centralny (F's photos, 2026-11-05; the tribune and the field's place, 2026-11-08) ---------

## The new square in front of the Palace of Culture (2024-25): the old parade tribune (`trybuna`),
## and before it, towards Marszałkowska, the striped field (granite slabs with grass joints) round a
## pale paved heart, the red WARSZAWA letters, the green deckchairs and the lamps. The trees, beds and
## benches are tools/plac_centralny.py's (map data); the lawns, plazas and the pool are
## OpenStreetMap's. Spec docs/landmarks/specs/plac_centralny.md. The frame: local u north, v east,
## from the square's axis (Marszałkowska's frame s 64, t -130; first_scene.gd FRAME_*).
## 2026-11-08 (F's photos of the tribune and the aerial render): the 2026-11-05 build had the field
## west of the tribune and the tribune itself as a low "seat-wall" 38 m further west; OSM's walls on
## its real spot were drawn as low grey walls and a ramp. The field now lies east of the tribune.
const PCZ_O := Vector2(-937.0 + 64.0 * -0.34917 + -130.0 * 0.93706, 210.1 + 64.0 * -0.93706 + -130.0 * -0.34917)
const PCZ_N := Vector2(-0.34917, -0.93706)
const PCZ_E := Vector2(0.93706, -0.34917)

## The striped field (u0, u1, v0, v1) and its pale heart: from the tribune's east face to the
## cross path, between the two rows of trees along the axis (tools/plac_centralny.py ROWS).
const PCZ_FIELD := Rect2(-15.0, 10.4, 34.0, 37.6)

## The lamps, [s, t] in Marszałkowska's frame (tools/plac_centralny.py keeps its trees off them).
const PCZ_LAMPS := [[64.0, -205.0], [64.0, -190.0], [64.0, -76.0], [64.0, -64.0], [42.0, -200.0], [86.0, -200.0],
		[42.0, -120.0], [86.0, -120.0], [42.0, -160.0], [86.0, -160.0]]


func _pcz_frame() -> void:
	_o = PCZ_O
	_a = PCZ_N
	_b = PCZ_E
	_g = map.terrain_height(PCZ_O.x, PCZ_O.y)


func _pcz_world(s: float, t: float) -> Vector2:
	return PCZ_O + PCZ_N * (s - 64.0) + PCZ_E * (t + 130.0)


# --- Built letters: serif capitals and a wave mark (Muzeum Narodowe's roof sign, 2026-11-26) -----

## Serif capitals drawn as strokes, for a lit roof sign of built letters (the neon atlas has only a
## 5×7 sans font). Each glyph: [width, strokes], width in cap heights, a stroke [x0, y0, x1, y1,
## weight] in cap heights (y up), weight 1 a stem, 0.55 a hairline (the bars, the diagonals'
## thin side, the serifs). The serifs are short hairlines across a stem's ends. Only the letters a
## sign needs so far; add more as signs need them.
const SERIF_GLYPHS := {
	"M": [0.92, [[0.0, 0.0, 0.0, 1.0, 0.55], [0.92, 0.0, 0.92, 1.0, 1.0], [0.0, 1.0, 0.46, 0.08, 1.0],
			[0.46, 0.08, 0.92, 1.0, 0.55], [-0.13, 0.0, 0.13, 0.0, 0.55], [0.79, 0.0, 1.05, 0.0, 0.55],
			[-0.1, 1.0, 0.04, 1.0, 0.55], [0.88, 1.0, 1.02, 1.0, 0.55]]],
	"U": [0.76, [[0.0, 1.0, 0.0, 0.26, 1.0], [0.76, 1.0, 0.76, 0.22, 0.55], [0.0, 0.26, 0.17, 0.03, 1.0],
			[0.17, 0.03, 0.58, 0.03, 0.75], [0.58, 0.03, 0.76, 0.22, 0.55], [-0.13, 1.0, 0.13, 1.0, 0.55],
			[0.65, 1.0, 0.87, 1.0, 0.55]]],
	"Z": [0.7, [[0.0, 1.0, 0.7, 1.0, 0.55], [0.7, 1.0, 0.0, 0.0, 1.0], [0.0, 0.0, 0.7, 0.0, 0.55],
			[0.0, 1.0, 0.0, 0.84, 0.55], [0.7, 0.0, 0.7, 0.18, 0.55]]],
	"E": [0.66, [[0.0, 0.0, 0.0, 1.0, 1.0], [0.0, 1.0, 0.64, 1.0, 0.55], [0.0, 0.52, 0.48, 0.52, 0.55],
			[0.0, 0.0, 0.66, 0.0, 0.55], [0.64, 1.0, 0.64, 0.84, 0.55], [0.66, 0.0, 0.66, 0.18, 0.55],
			[0.46, 0.44, 0.46, 0.6, 0.55], [-0.13, 0.0, 0.0, 0.0, 0.55], [-0.13, 1.0, 0.0, 1.0, 0.55]]],
	"O": [0.86, [[0.26, 0.0, 0.6, 0.0, 0.55], [0.6, 0.0, 0.86, 0.26, 0.75], [0.86, 0.26, 0.86, 0.74, 1.0],
			[0.86, 0.74, 0.6, 1.0, 0.75], [0.6, 1.0, 0.26, 1.0, 0.55], [0.26, 1.0, 0.0, 0.74, 0.75],
			[0.0, 0.74, 0.0, 0.26, 1.0], [0.0, 0.26, 0.26, 0.0, 0.75]]],
	"N": [0.8, [[0.0, 0.0, 0.0, 1.0, 0.55], [0.8, 0.0, 0.8, 1.0, 0.55], [0.0, 1.0, 0.8, 0.0, 1.0],
			[-0.13, 0.0, 0.13, 0.0, 0.55], [-0.1, 1.0, 0.04, 1.0, 0.55], [0.67, 1.0, 0.93, 1.0, 0.55]]],
	"A": [0.86, [[0.0, 0.0, 0.43, 1.0, 0.55], [0.43, 1.0, 0.86, 0.0, 1.0], [0.2, 0.34, 0.66, 0.34, 0.55],
			[-0.12, 0.0, 0.12, 0.0, 0.55], [0.72, 0.0, 1.0, 0.0, 0.55]]],
	"R": [0.76, [[0.0, 0.0, 0.0, 1.0, 1.0], [0.0, 1.0, 0.52, 1.0, 0.55], [0.52, 1.0, 0.7, 0.86, 0.75],
			[0.7, 0.86, 0.7, 0.66, 1.0], [0.7, 0.66, 0.52, 0.52, 0.75], [0.52, 0.52, 0.0, 0.52, 0.55],
			[0.34, 0.52, 0.76, 0.0, 1.0], [-0.13, 0.0, 0.13, 0.0, 0.55], [-0.13, 1.0, 0.0, 1.0, 0.55],
			[0.66, 0.0, 0.88, 0.0, 0.55]]],
	"D": [0.82, [[0.0, 0.0, 0.0, 1.0, 1.0], [0.0, 1.0, 0.46, 1.0, 0.55], [0.46, 1.0, 0.82, 0.7, 0.75],
			[0.82, 0.7, 0.82, 0.3, 1.0], [0.82, 0.3, 0.46, 0.0, 0.75], [0.46, 0.0, 0.0, 0.0, 0.55],
			[-0.13, 0.0, 0.0, 0.0, 0.55], [-0.13, 1.0, 0.0, 1.0, 0.55]]],
	"W": [1.12, [[0.0, 1.0, 0.26, 0.0, 1.0], [0.26, 0.0, 0.56, 0.86, 0.55], [0.56, 0.86, 0.86, 0.0, 1.0],
			[0.86, 0.0, 1.12, 1.0, 0.55], [-0.12, 1.0, 0.12, 1.0, 0.55], [1.0, 1.0, 1.24, 1.0, 0.55]]],
}
const SERIF_GAP := 0.22    # between letters, in cap heights
const SERIF_SPACE := 0.5   # a word space
const SERIF_STEM := 0.13   # a stem's width, in cap heights


## How wide `word` is in cap heights (SERIF_GLYPHS; an unknown letter counts as a space).
func _serif_width(word: String) -> float:
	var w := 0.0
	for i in word.length():
		if i > 0:
			w += SERIF_GAP
		var g: Array = SERIF_GLYPHS.get(word[i], [])
		w += SERIF_SPACE if g.is_empty() else float(g[0])
	return w


## A word of built serif capitals standing on a vertical plane: `at` the bottom of its first letter,
## `right` the reading direction (unit, level), cap height `h` m, strokes `h` × SERIF_STEM wide and
## as deep. Each stroke is a beam in `mode` (M_LAMP: its colour by day, glowing at night), out of
## the roof grid. Returns the word's length in metres.
func _serif_word(word: String, at: Vector3, right: Vector3, h: float, col: Color, mode := M_LAMP) -> float:
	var x := 0.0
	# Strokes that meet would share a face's plane and flicker: every other stroke stands 7.5 cm
	# deeper and 2.5 cm higher. The step clears the gaps between the three stroke widths' faces
	# (2.1, 2.7 and 4.8 cm), so no two faces of meeting strokes come within check_mesh_quality's 2 cm.
	var depth := right.cross(Vector3.UP).normalized() * 0.075
	var k := 0
	for i in word.length():
		if i > 0:
			x += SERIF_GAP
		var g: Array = SERIF_GLYPHS.get(word[i], [])
		if g.is_empty():
			x += SERIF_SPACE
			continue
		for s: Array in g[1]:
			var nudge := (depth + Vector3.UP * 0.025) * float(k % 2)
			k += 1
			var p0 := at + right * (x + float(s[0])) * h + Vector3.UP * float(s[1]) * h + nudge
			var p1 := at + right * (x + float(s[2])) * h + Vector3.UP * float(s[3]) * h + nudge
			_beam(p0, p1, h * SERIF_STEM * float(s[4]), col, false, mode)
		x += float(g[0])
	return x * h
