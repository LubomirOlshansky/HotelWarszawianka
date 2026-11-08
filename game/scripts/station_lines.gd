extends RefCounted
## The railway platforms' centre lines (F, 2026-11-06: "the infrastructure for all the stations,
## with people"): map_builder.gd stands the station furniture along them, trains.gd the people
## waiting for a train. Both city paths build them the same from the index's `platforms`,
## `rails` and the yard (rail_yard.gd), so the prebuilt city's waiting people stand on the
## platforms its sectors drew.
##
## OSM's 0.9 m platforms beside a track are cut across every 2 m along their long axis; where a
## track runs inside the outline (Stadion's: OSM's polygon spans its own track) the cut keeps the
## free part, TRACK_CLEAR from each track's centre. Rail_yard.gd's islands at Warszawa Główna
## come as they are. Each line: [points, tops, half widths, from the yard].

const RailYard := preload("res://scripts/rail_yard.gd")

## A 0.9 m platform whose middle lies this close to a track is a railway's (not a tram's).
const RAIL_NEAR := 10.0
## A platform's edge from the centre of the track beside it.
const TRACK_CLEAR := 1.75
## The cuts' spacing along a platform.
const STEP := 2.0
## A cut narrower than this is left out.
const MIN_WIDTH := 1.5


## The tracks: [box grown by RAIL_NEAR, points] each (the trimmed rails, trains.gd trim_rails).
static func tracks(rails: Array) -> Array:
	var out := []
	for r in rails:
		var flat: Array = r["p"]
		var pts := PackedVector2Array()
		for k in range(0, flat.size() - 1, 2):
			pts.append(Vector2(flat[k], flat[k + 1]))
		if pts.size() < 2:
			continue
		var box := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			box = box.expand(q)
		out.append([box.grow(RAIL_NEAR + 2.0), pts])
	return out


static func near_track(p: Vector2, tracks_: Array) -> float:
	var best := INF
	for t: Array in tracks_:
		if not (t[0] as Rect2).has_point(p):
			continue
		var pts: PackedVector2Array = t[1]
		for i in pts.size() - 1:
			best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1])))
	return best


## `height` is the map's ground at (x, z).
static func lines(platforms: Array, tracks_: Array, yard: RailYard, height: Callable) -> Array:
	var out := []
	for a in platforms:
		if float(a["h"]) < 0.7:
			continue
		var flat: Array = a["p"]
		var poly := PackedVector2Array()
		for k in range(0, flat.size() - 1, 2):
			poly.append(Vector2(flat[k], flat[k + 1]))
		if poly.size() < 3:
			continue
		var c := Vector2.ZERO
		for q in poly:
			c += q
		c /= poly.size()
		if near_track(c, tracks_) > RAIL_NEAR:
			continue
		var near := []
		var reach := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			reach = reach.expand(q)
		for t: Array in tracks_:
			if (t[0] as Rect2).intersects(reach):
				near.append(t[1])
		# The long axis (the outline's principal direction), then a cut across it every STEP.
		var sxx := 0.0
		var szz := 0.0
		var sxz := 0.0
		var ground := INF
		for q in poly:
			var e := q - c
			sxx += e.x * e.x
			szz += e.y * e.y
			sxz += e.x * e.y
			ground = minf(ground, float(height.call(q.x, q.y)))
		var ang := 0.5 * atan2(2.0 * sxz, sxx - szz)
		var d := Vector2(cos(ang), sin(ang))
		var nm := Vector2(-d.y, d.x)
		var lo := INF
		var hi := -INF
		for q in poly:
			lo = minf(lo, (q - c).dot(d))
			hi = maxf(hi, (q - c).dot(d))
		var top := ground + float(a["h"]) + 0.1
		var pts := PackedVector2Array()
		var tops := PackedFloat32Array()
		var halves := PackedFloat32Array()
		var last := INF
		var s := lo + 1.0
		while s < hi - 1.0:
			var base := c + d * s
			var cut := _cut(poly, base, nm)
			if cut.y - cut.x > MIN_WIDTH:
				var free := _free(cut, base, nm, near, last)
				if free.y - free.x > MIN_WIDTH:
					last = (free.x + free.y) * 0.5
					pts.append(base + nm * last)
					tops.append(top)
					halves.append((free.y - free.x) * 0.5)
			s += STEP
		if pts.size() >= 2:
			out.append([pts, tops, halves, false])
	if yard != null:
		for pl: Dictionary in yard.platforms:
			var pp: PackedVector2Array = pl["p"]
			var hl: PackedFloat32Array = pl["l"]
			var hr: PackedFloat32Array = pl["r"]
			var pts := PackedVector2Array()
			var tops := PackedFloat32Array()
			var halves := PackedFloat32Array()
			for k in pp.size():
				var n := RailYard._normal(pp, k)
				pts.append(pp[k] + n * (hl[k] - hr[k]) * 0.5)
				tops.append(float(height.call(pp[k].x, pp[k].y)) + RailYard.HEIGHT)
				halves.append((hl[k] + hr[k]) * 0.5)
			out.append([pts, tops, halves, true])
	return out


## The outline's extent across at `base` (min, max along nm).
static func _cut(poly: PackedVector2Array, base: Vector2, nm: Vector2) -> Vector2:
	var a0 := base - nm * 200.0
	var a1 := base + nm * 200.0
	var lo := INF
	var hi := -INF
	for i in poly.size():
		var hit: Variant = Geometry2D.segment_intersects_segment(a0, a1, poly[i], poly[(i + 1) % poly.size()])
		if hit != null:
			var t := ((hit as Vector2) - base).dot(nm)
			lo = minf(lo, t)
			hi = maxf(hi, t)
	return Vector2(lo, hi)


## The part of the cut no track runs over (TRACK_CLEAR each side of one): the widest, or the one
## holding the last cut's middle (`last`), so the line doesn't jump from side to side.
static func _free(cut: Vector2, base: Vector2, nm: Vector2, near: Array, last: float) -> Vector2:
	var a0 := base + nm * (cut.x - TRACK_CLEAR)
	var a1 := base + nm * (cut.y + TRACK_CLEAR)
	var hits := PackedFloat32Array()
	for pts: PackedVector2Array in near:
		for i in pts.size() - 1:
			var hit: Variant = Geometry2D.segment_intersects_segment(a0, a1, pts[i], pts[i + 1])
			if hit != null:
				hits.append(((hit as Vector2) - base).dot(nm))
	if hits.is_empty():
		return cut
	hits.sort()
	var parts: Array[Vector2] = []
	var from := cut.x
	for t in hits:
		if t - TRACK_CLEAR > from:
			parts.append(Vector2(from, minf(t - TRACK_CLEAR, cut.y)))
		from = maxf(from, t + TRACK_CLEAR)
	if from < cut.y:
		parts.append(Vector2(from, cut.y))
	var best := Vector2.ZERO
	for p in parts:
		if last != INF and last >= p.x and last <= p.y:
			return p
		if p.y - p.x > best.y - best.x:
			best = p
	return best
