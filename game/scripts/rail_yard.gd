extends RefCounted
## Platforms OpenStreetMap draws only as footways (F, 2026-11-06, Warszawa Główna's new platforms
## by the Kolejowa footbridge: thin white footpaths across the ballast, people walking on the
## track bed). A footway (not on a deck) with a track parallel to it on both sides along most of
## its length is an island platform between them: its edges stand PLATFORM_GAP from each track's
## centre (the platform edge's real offset, 1.7 m), at least MIN_HALF from the footway, its top
## HEIGHT over the ground. map_builder draws them; pedestrians.gd lifts the people on them.

const STEP := 3.0
const REACH := 11.0           ## a track this near beside the footway (OSM often draws two
                              ## footways along one island, each off its centre) ...
const PARALLEL := 0.85        ## ... and this parallel to it (|cos|)
const SHARE := 0.7            ## on this share of its samples
const MIN_LEN := 30.0
const PLATFORM_GAP := 1.7
const MIN_HALF := 0.9
const MAX_HALF := 8.0
const HEIGHT := 0.76
const MAX_WIDTH := 11.0

## Each: {"i": path index, "p": PackedVector2Array samples, "l": PackedFloat32Array half widths
## to the left (+normal), "r": to the right}.
var platforms: Array[Dictionary] = []
## Footway key (its ends rounded, `key`) -> HEIGHT, for pedestrians.gd.
var lifts := {}
## Platform outlines OSM maps as closed footways: PackedVector2Array polygons (counter-clockwise).
var rings: Array[PackedVector2Array] = []
var _cells := {}
## Per platform: the tracks' bed height at each sample (set_bases); `_pcells`: cell -> [platform,
## sample] pairs near it, for base_at.
var bases: Array[PackedFloat32Array] = []
var _pcells := {}


static func key(line: PackedVector2Array) -> Vector4i:
	var a := line[0]
	var b := line[line.size() - 1]
	return Vector4i(roundi(a.x), roundi(a.y), roundi(b.x), roundi(b.y))


## What `base_at`, the lifts and map_builder's platform drawing read, for the prebuilt city to keep
## (map_builder.gd `_rail_state`).
func state() -> Dictionary:
	return {"platforms": platforms, "lifts": lifts, "rings": rings, "cells": _cells, "bases": bases, "pcells": _pcells}


## The yard as `state` gave it, with no grid sampled again.
func restore(s: Dictionary) -> void:
	platforms.assign(s.get("platforms", []))
	lifts = s.get("lifts", {})
	rings.assign(s.get("rings", []))
	_cells = s.get("cells", {})
	bases.assign(s.get("bases", []))
	_pcells = s.get("pcells", {})


## `osm`: the platforms OSM maps as platforms ({"p": flat}); a footway on one is left to it.
func setup(paths: Array, rails: Array, osm: Array = []) -> void:
	platforms.clear()
	rings.clear()
	lifts.clear()
	_cells.clear()
	for r: Dictionary in rails:
		if r.has("dk") and int(r["dk"]) >= 0:
			continue
		var flat: Array = r["p"]
		for i in range(0, flat.size() - 3, 2):
			var a := Vector2(flat[i], flat[i + 1])
			var b := Vector2(flat[i + 2], flat[i + 3])
			var lo := a.min(b) - Vector2.ONE * REACH
			var hi := a.max(b) + Vector2.ONE * REACH
			for cz in range(floori(lo.y / 16.0), floori(hi.y / 16.0) + 1):
				for cx in range(floori(lo.x / 16.0), floori(hi.x / 16.0) + 1):
					var list: PackedVector2Array = _cells.get(Vector2i(cx, cz), PackedVector2Array())
					list.append_array(PackedVector2Array([a, b]))
					_cells[Vector2i(cx, cz)] = list
	if _cells.is_empty():
		return
	var polys: Array[PackedVector2Array] = []
	for o: Dictionary in osm:
		var f: Array = o["p"]
		var poly := PackedVector2Array()
		for k in range(0, f.size() - 1, 2):
			poly.append(Vector2(f[k], f[k + 1]))
		if poly.size() >= 3 and _cells.has(Vector2i(floori(poly[0].x / 16.0), floori(poly[0].y / 16.0))):
			polys.append(poly)
	for i in paths.size():
		var p: Dictionary = paths[i]
		if p["k"] != "foot" or (p.has("dk") and int(p["dk"]) >= 0) or p.has("tn"):
			continue
		var flat: Array = p["p"]
		var line := PackedVector2Array()
		for k in range(0, flat.size() - 1, 2):
			line.append(Vector2(flat[k], flat[k + 1]))
		var length := 0.0
		for k in line.size() - 1:
			length += line[k].distance_to(line[k + 1])
		if length < MIN_LEN:
			continue
		var c: Variant = _cells.get(Vector2i(floori(line[0].x / 16.0), floori(line[0].y / 16.0)))
		var c2: Variant = _cells.get(Vector2i(floori(line[line.size() - 1].x / 16.0), floori(line[line.size() - 1].y / 16.0)))
		if c == null and c2 == null:
			continue
		# A closed footway round a long thin area beside tracks: the platform's outline (OSM maps
		# Warszawa Główna's new platforms so). The polygon is the platform.
		if line[0].distance_to(line[line.size() - 1]) < 1.0 and line.size() >= 4:
			var ring := line.slice(0, line.size() - 1)
			if _is_platform_ring(ring):
				if Geometry2D.is_polygon_clockwise(ring):
					ring.reverse()
				rings.append(ring)
				lifts[key(line)] = HEIGHT
			continue
		var pts := _resample(line)
		var l := PackedFloat32Array()
		var r := PackedFloat32Array()
		var good := 0
		for k in pts.size():
			var d := (pts[mini(k + 1, pts.size() - 1)] - pts[maxi(k - 1, 0)]).normalized()
			var nm := Vector2(-d.y, d.x)
			var dl := _side(pts[k], nm, d)
			var dr := _side(pts[k], -nm, d)
			if dl < INF and dr < INF:
				good += 1
			l.append(clampf(dl - PLATFORM_GAP, MIN_HALF, MAX_HALF) if dl < INF else NAN)
			r.append(clampf(dr - PLATFORM_GAP, MIN_HALF, MAX_HALF) if dr < INF else NAN)
		if good < SHARE * pts.size() or _covered(pts, polys):
			continue
		_fill_gaps(l)
		_fill_gaps(r)
		var widths: Array[float] = []
		for k in l.size():
			widths.append(l[k] + r[k])
		widths.sort()
		if widths[widths.size() / 2] > MAX_WIDTH:
			continue  # a path between two tracks far apart, not an island platform
		platforms.append({"i": i, "p": pts, "l": _smooth(l), "r": _smooth(r)})
		lifts[key(line)] = HEIGHT


## The bed height under each platform sample: the lower of the grid at its two tracks.
func set_bases(grid: Callable) -> void:
	bases.clear()
	_pcells.clear()
	for i in platforms.size():
		var pl: Dictionary = platforms[i]
		var pts: PackedVector2Array = pl["p"]
		var hl: PackedFloat32Array = pl["l"]
		var hr: PackedFloat32Array = pl["r"]
		var b := PackedFloat32Array()
		for k in pts.size():
			var nm := _normal(pts, k)
			var tl := pts[k] + nm * (hl[k] + PLATFORM_GAP)
			var tr := pts[k] - nm * (hr[k] + PLATFORM_GAP)
			b.append(minf(float(grid.call(tl.x, tl.y)), float(grid.call(tr.x, tr.y))))
			var reach := maxf(hl[k], hr[k]) + STEP
			for cz in range(floori((pts[k].y - reach) / 16.0), floori((pts[k].y + reach) / 16.0) + 1):
				for cx in range(floori((pts[k].x - reach) / 16.0), floori((pts[k].x + reach) / 16.0) + 1):
					var list: PackedInt32Array = _pcells.get(Vector2i(cx, cz), PackedInt32Array())
					list.append_array(PackedInt32Array([i, k]))
					_pcells[Vector2i(cx, cz)] = list
		bases.append(_smooth(b))


## The bed height under an island platform at `p`, or NAN off every one.
func base_at(p: Vector2) -> float:
	if _pcells.is_empty():
		return NAN
	var list: PackedInt32Array = _pcells.get(Vector2i(floori(p.x / 16.0), floori(p.y / 16.0)), PackedInt32Array())
	for j in range(0, list.size(), 2):
		var pl: Dictionary = platforms[list[j]]
		var pts: PackedVector2Array = pl["p"]
		var k := list[j + 1]
		var d := (pts[mini(k + 1, pts.size() - 1)] - pts[maxi(k - 1, 0)]).normalized()
		var q := p - pts[k]
		if absf(q.dot(d)) > STEP * 0.5 + 0.01:
			continue
		var lat := q.dot(Vector2(-d.y, d.x))
		if lat <= (pl["l"] as PackedFloat32Array)[k] and lat >= -(pl["r"] as PackedFloat32Array)[k]:
			return bases[list[j]][k]
	return NAN


static func _normal(pts: PackedVector2Array, k: int) -> Vector2:
	var d := (pts[mini(k + 1, pts.size() - 1)] - pts[maxi(k - 1, 0)]).normalized()
	return Vector2(-d.y, d.x)


## Whether most of `pts` already lie on a platform: an OSM platform polygon, or an island an
## earlier footway gave (the second footway OSM draws along the same island).
func _covered(pts: PackedVector2Array, osm: Array[PackedVector2Array]) -> bool:
	var on := 0
	for q in pts:
		var hit := false
		for poly in osm:
			if Geometry2D.is_point_in_polygon(q, poly):
				hit = true
				break
		if not hit:
			for pl: Dictionary in platforms:
				var pp: PackedVector2Array = pl["p"]
				for k in pp.size() - 1:
					if Geometry2D.get_closest_point_to_segment(q, pp[k], pp[k + 1]).distance_to(q) < 6.0:
						hit = true
						break
				if hit:
					break
		if hit:
			on += 1
	return on > pts.size() / 2


## Long and thin (its area over its perimeter's half under 6 m, at least 300 m2) with a track
## beside most of its corners.
func _is_platform_ring(ring: PackedVector2Array) -> bool:
	var area := 0.0
	var perim := 0.0
	for k in ring.size():
		var a := ring[k]
		var b := ring[(k + 1) % ring.size()]
		area += a.cross(b) * 0.5
		perim += a.distance_to(b)
	area = absf(area)
	if area < 300.0 or area / (perim * 0.5) > 6.0:
		return false
	var near := 0
	for q in ring:
		var segs: PackedVector2Array = _cells.get(Vector2i(floori(q.x / 16.0), floori(q.y / 16.0)), PackedVector2Array())
		for k in range(0, segs.size(), 2):
			if Geometry2D.get_closest_point_to_segment(q, segs[k], segs[k + 1]).distance_to(q) < 5.0:
				near += 1
				break
	return near >= ring.size() * 0.6


func _resample(line: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array([line[0]])
	var carry := 0.0
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var l := a.distance_to(b)
		if l < 0.01:
			continue
		var s := STEP - carry
		while s < l:
			out.append(a.lerp(b, s / l))
			s += STEP
		carry = l - (s - STEP)
	if out[out.size() - 1].distance_to(line[line.size() - 1]) > 0.3:
		out.append(line[line.size() - 1])
	return out


## The distance from p along `out` to the nearest parallel track segment within REACH, or INF.
func _side(p: Vector2, out: Vector2, d: Vector2) -> float:
	var best := INF
	for c: Vector2i in [Vector2i(floori(p.x / 16.0), floori(p.y / 16.0))]:
		var segs: PackedVector2Array = _cells.get(c, PackedVector2Array())
		for k in range(0, segs.size(), 2):
			var a := segs[k]
			var ab := segs[k + 1] - a
			var l2 := ab.length_squared()
			if l2 < 0.01 or absf(ab.normalized().dot(d)) < PARALLEL:
				continue
			var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
			var q := a + ab * t
			var v := q - p
			var dist := v.length()
			if dist > REACH or dist < 1.0 or v.dot(out) < 0.0:
				continue
			# The perpendicular distance, not the slant one.
			best = minf(best, absf(v.dot(out)))
	return best


static func _fill_gaps(v: PackedFloat32Array) -> void:
	var last := NAN
	for k in v.size():
		if is_nan(v[k]):
			v[k] = last
		else:
			last = v[k]
	last = NAN
	for k in range(v.size() - 1, -1, -1):
		if is_nan(v[k]):
			v[k] = last if not is_nan(last) else MIN_HALF
		else:
			last = v[k]


static func _smooth(v: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(v.size())
	for k in v.size():
		var s := 0.0
		var c := 0
		for j in range(maxi(0, k - 2), mini(v.size(), k + 3)):
			s += v[j]
			c += 1
		out[k] = s / c
	return out
