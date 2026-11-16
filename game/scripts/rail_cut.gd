extends RefCounted
## The cross-city line's cutting from the tunnel mouth west of Centralna past Warszawa Ochota to
## where the tracks climb out by Warszawa Główna (F, 2026-11-06: "rework the rails from Centralny
## to Ochota, it looks too bad"). The 10 m GUGiK grid blurs a 6 m deep cutting into soft slopes
## 15-20 m wide: the outer tracks climbed them (one 6 m up the south side), the ballast sheets ran
## up the banks and the floor rippled between the grid's points.
##
## This holds the cutting the tracks themselves describe: each track (OSM rails in BOX, not on a
## deck) sampled every STEP m; its floor is the lowest grid near it, smoothed along the track and
## evened out across neighbouring tracks; a sample is in the cutting when the ground beside it
## stands DEEP over that floor. The ground then lies flat at the floor within FLOOR_W of every
## track in the cutting, rises in a straight bank (BANK_MIN..BANK_MAX wide, from the grid's own
## rim) on each outer side, and blends back to the grid over SHOULDER. Between two tracks of the
## cutting the floor runs on (no bank between them). map_builder's terrain_height and drawn ground
## read `at`; it draws the walls, banks and fences from `edges`.
##
## Built from the whole map's rails (the index in streamed mode), so every sector agrees.

const BOX := Rect2(-3140.0, 740.0, 1250.0, 460.0)
const STEP := 4.0
const FLOOR_W := 3.6         ## flat floor this far either side of a track's centre line
const BANK_MIN := 3.0
const BANK_MAX := 12.0
const SHOULDER := 4.0
const DEEP := 1.8            ## a sample is in the cutting when a side's rim stands this far over its floor
const LAT_LOW := 9.0         ## the floor: the lowest grid this far either side of the track
const SCAN := 28.0           ## the rim: the highest grid this far out
const NEAR_TRACK := 26.0     ## another track of the cutting this near on a side: no bank there
const SAME_FLOOR := 1.5      ## ... when its floor is within this of ours
const CELL := 16.0
const WALL_BELOW := 5.5      ## a bank narrower than this ...
const WALL_DEEP := 2.5       ## ... and deeper than this is a vertical retaining wall instead
const WALL_FLAT := 1.6       ## behind a wall's face the floor runs on this far (under its top) ...
const WALL_W := 3.0          ## ... then the ground climbs to the rim by here, all under the wall's top
const SUB_WALL := 10         ## the drawn ground's sub-cells by a wall (1 m: the step stays behind its face)
## Walled whatever the bank's width: the approach to the cross-city tunnel's west mouth.
const WALLED: Array[Vector2] = [Vector2(-1964.0, 812.0)]
const WALLED_R := 150.0
## Walled too, in a smaller radius: the cutting's ends under Plac Zawiszy's junction (trains.gd
## TUNNEL_ZAWISZY_PLAC), where the banks stop at a retaining wall.
const WALLED_NEAR: Array[Vector3] = [Vector3(-2440.7, 970.5, 45.0), Vector3(-2375.8, 944.5, 45.0)]
const SUB := 5               ## the drawn ground's sub-cells a 10 m cell (2 m) over the cutting

## Per track: {"p": PackedVector2Array samples, "f": floors, "cut": PackedByteArray,
## "b": PackedVector2Array bank widths (x left, y right: >0 a bank, 0 open, -1 another track),
## "r": PackedVector2Array rims (left, right)}. Left is +normal (-d.y, d.x).
var tracks: Array[Dictionary] = []
var box := Rect2()
var _cells := {}
var _grid: Callable


## What `at` reads, for the prebuilt city to keep (map_builder.gd `_rail_state`): the tracks, the box
## and the cells. `_grid` is only read while `setup` runs.
func state() -> Dictionary:
	return {"tracks": tracks, "box": box, "cells": _cells}


## The cutting as `state` gave it, with no grid sampled again.
func restore(s: Dictionary) -> void:
	tracks.assign(s.get("tracks", []))
	box = s.get("box", Rect2())
	_cells = s.get("cells", {})


func setup(rails: Array, grid: Callable) -> void:
	_grid = grid
	tracks.clear()
	_cells.clear()
	box = Rect2()
	for r: Dictionary in rails:
		if r.has("dk") and int(r["dk"]) >= 0:
			continue
		var flat: Array = r["p"]
		var poly := PackedVector2Array()
		var inside := false
		for i in range(0, flat.size() - 1, 2):
			var q := Vector2(flat[i], flat[i + 1])
			poly.append(q)
			inside = inside or BOX.has_point(q)
		if not inside or poly.size() < 2:
			continue
		var pts := _resample(poly)
		if pts.size() < 2:
			continue
		tracks.append({"p": pts})
	if tracks.is_empty():
		return
	for t in tracks:
		_floor(t)
	# Even the floor out across the tracks: each sample takes the lowest floor of the other
	# tracks' samples beside it (twice, so a group of four agrees).
	for pass_ in 2:
		_index(false)
		for t in tracks:
			var pts: PackedVector2Array = t["p"]
			var f: PackedFloat32Array = t["f"]
			for k in pts.size():
				var o := _nearest_other(t, pts[k], 12.0, false)
				if o.x < INF and o.y < f[k] and f[k] - o.y < 2.5:
					f[k] = o.y
			t["f"] = f
	for t in tracks:
		_mark(t)
	_index(false)
	for t in tracks:
		_banks(t)
	_index(true)


## Samples every STEP m along the polyline (its own vertices' corners rounded off).
func _resample(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array([poly[0]])
	var carry := 0.0
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var l := a.distance_to(b)
		if l < 0.01:
			continue
		var s := STEP - carry
		while s < l:
			out.append(a.lerp(b, s / l))
			s += STEP
		carry = l - (s - STEP)
	if out[out.size() - 1].distance_to(poly[poly.size() - 1]) > 0.3:
		out.append(poly[poly.size() - 1])
	return out


static func _normal(pts: PackedVector2Array, k: int) -> Vector2:
	var d := (pts[mini(k + 1, pts.size() - 1)] - pts[maxi(k - 1, 0)]).normalized()
	return Vector2(-d.y, d.x)


func _floor(t: Dictionary) -> void:
	var pts: PackedVector2Array = t["p"]
	var n := pts.size()
	var raw := PackedFloat32Array()
	raw.resize(n)
	var grown := BOX.grow(40.0)
	for k in n:
		if not grown.has_point(pts[k]):
			raw[k] = _grid.call(pts[k].x, pts[k].y)
			continue
		var nm := _normal(pts, k)
		var lo := INF
		var o := -LAT_LOW
		while o <= LAT_LOW + 0.01:
			var q := pts[k] + nm * o
			lo = minf(lo, _grid.call(q.x, q.y))
			o += 1.5
		raw[k] = lo
	# The lowest over 20 m either way (a cutting's floor, not the grid's ripples), then smoothed.
	var low := PackedFloat32Array()
	low.resize(n)
	for k in n:
		var m := INF
		for j in range(maxi(0, k - 5), mini(n, k + 6)):
			m = minf(m, raw[j])
		low[k] = m
	t["f"] = _blur(_blur(low, 4), 4)


static func _blur(v: PackedFloat32Array, r: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(v.size())
	for k in v.size():
		var s := 0.0
		var c := 0
		for j in range(maxi(0, k - r), mini(v.size(), k + r + 1)):
			s += v[j]
			c += 1
		out[k] = s / c
	return out


## In the cutting: inside BOX and a side's rim DEEP over the floor; closed over gaps of 2 samples.
func _mark(t: Dictionary) -> void:
	var pts: PackedVector2Array = t["p"]
	var f: PackedFloat32Array = t["f"]
	var n := pts.size()
	var raw := PackedByteArray()
	raw.resize(n)
	for k in n:
		if not BOX.has_point(pts[k]):
			continue
		var nm := _normal(pts, k)
		var top := -INF
		for sgn in [1.0, -1.0]:
			var o := FLOOR_W
			while o <= SCAN:
				var q: Vector2 = pts[k] + nm * sgn * o
				top = maxf(top, _grid.call(q.x, q.y))
				o += 2.0
		raw[k] = 1 if top - f[k] > DEEP else 0
	var cut := raw.duplicate()
	for k in n:
		if raw[k] == 1:
			continue
		var before := false
		var after := false
		for j in range(maxi(0, k - 2), k):
			before = before or raw[j] == 1
		for j in range(k + 1, mini(n, k + 3)):
			after = after or raw[j] == 1
		if before and after:
			cut[k] = 1
	t["cut"] = cut


## Each side's bank: none where another track of the cutting lies within NEAR_TRACK on that
## side at about our floor (the floor runs on to it); else from the floor's edge up to where
## the grid reaches its rim, BANK_MIN..BANK_MAX wide, and short of any track up there.
func _banks(t: Dictionary) -> void:
	var pts: PackedVector2Array = t["p"]
	var f: PackedFloat32Array = t["f"]
	var cut: PackedByteArray = t["cut"]
	var n := pts.size()
	var bl := PackedFloat32Array()
	var br := PackedFloat32Array()
	var rl := PackedFloat32Array()
	var rr := PackedFloat32Array()
	for arr in [bl, br, rl, rr]:
		arr.resize(n)
	for k in n:
		if cut[k] == 0 and (k == 0 or cut[k - 1] == 0) and (k == n - 1 or cut[k + 1] == 0):
			continue  # no bank needed (its neighbours' smoothing reads zeros)
		var nm := _normal(pts, k)
		for side in 2:
			var sgn := 1.0 if side == 0 else -1.0
			var rim := -INF
			var o := FLOOR_W
			while o <= SCAN:
				var q: Vector2 = pts[k] + nm * sgn * o
				rim = maxf(rim, _grid.call(q.x, q.y))
				o += 2.0
			var b := 0.0
			var inner := false
			var other := INF
			o = 2.0
			while o <= NEAR_TRACK:
				var q: Vector2 = pts[k] + nm * sgn * o
				var hit := _track_at(t, q, 1.6)
				if hit.x < INF:
					if absf(hit.y - f[k]) < SAME_FLOOR:
						inner = true
					other = minf(other, o)
					break
				o += 1.0
			if inner:
				b = -1.0
			elif rim - f[k] > 1.0:
				o = FLOOR_W
				while o <= SCAN:
					var q: Vector2 = pts[k] + nm * sgn * o
					if _grid.call(q.x, q.y) >= rim - 0.6:
						break
					o += 1.0
				b = clampf(o - FLOOR_W, BANK_MIN, BANK_MAX)
				if other < INF:
					b = clampf(other - 3.0 - FLOOR_W, 0.5, b)
			if side == 0:
				bl[k] = b
				rl[k] = rim
			else:
				br[k] = b
				rr[k] = rim
	# Smooth the banks' widths and rims along the track (an inner side stays inner).
	var sbl := _blur(_clean(bl), 3)
	var sbr := _blur(_clean(br), 3)
	var srl := _blur(rl, 3)
	var srr := _blur(rr, 3)
	var b2 := PackedVector2Array()
	var r2 := PackedVector2Array()
	var walls := PackedVector2Array()
	for k in n:
		var b := Vector2(-1.0 if bl[k] < 0.0 else sbl[k], -1.0 if br[k] < 0.0 else sbr[k])
		var r := Vector2(srl[k], srr[k])
		# Too narrow for a bank this deep: a concrete retaining wall (by the tunnel's mouth).
		var wall := Vector2.ZERO
		var below := WALL_BELOW
		for q: Vector2 in WALLED:
			if pts[k].distance_to(q) < WALLED_R:
				below = INF  # the tunnel's approach is walled all along (Mapillary, Feb 2026)
		for q: Vector3 in WALLED_NEAR:
			if pts[k].distance_to(Vector2(q.x, q.y)) < q.z:
				below = INF
		if b.x > 0.25 and b.x < below and r.x - f[k] > WALL_DEEP:
			b.x = WALL_W
			wall.x = 1.0
		if b.y > 0.25 and b.y < below and r.y - f[k] > WALL_DEEP:
			b.y = WALL_W
			wall.y = 1.0
		b2.append(b)
		r2.append(r)
		walls.append(wall)
	t["b"] = b2
	t["r"] = r2
	t["w"] = walls
	t["cut"] = cut


## Widths for smoothing: an inner side (-1) counts as no bank.
static func _clean(v: PackedFloat32Array) -> PackedFloat32Array:
	var out := v.duplicate()
	for k in out.size():
		out[k] = maxf(out[k], 0.0)
	return out


func _key(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))


## Every segment in the cells its reach covers: (track << 16) | segment. `cut_only`: only the
## cutting's segments, grown by their banks (for `at`); else all, grown by NEAR_TRACK.
func _index(cut_only: bool) -> void:
	_cells.clear()
	box = Rect2()
	for ti in tracks.size():
		var t: Dictionary = tracks[ti]
		var pts: PackedVector2Array = t["p"]
		var cut: PackedByteArray = t.get("cut", PackedByteArray())
		for k in pts.size() - 1:
			var reach := 2.0
			if cut_only:
				if cut[k] == 0 and cut[k + 1] == 0:
					continue
				var b: PackedVector2Array = t["b"]
				reach = FLOOR_W + maxf(maxf(b[k].x, b[k].y), maxf(b[k + 1].x, b[k + 1].y)) + SHOULDER + 1.0
			var lo := pts[k].min(pts[k + 1]) - Vector2.ONE * reach
			var hi := pts[k].max(pts[k + 1]) + Vector2.ONE * reach
			box = Rect2(lo, hi - lo) if not box.has_area() else box.merge(Rect2(lo, hi - lo))
			for cz in range(floori(lo.y / CELL), floori(hi.y / CELL) + 1):
				for cx in range(floori(lo.x / CELL), floori(hi.x / CELL) + 1):
					var key := Vector2i(cx, cz)
					var list: PackedInt32Array = _cells.get(key, PackedInt32Array())
					list.append((ti << 16) | k)
					_cells[key] = list


## The nearest sample segment of another track to p within `reach`: (distance, its floor).
func _nearest_other(own: Dictionary, p: Vector2, reach: float, _unused: bool) -> Vector2:
	var best := Vector2(INF, INF)
	for code: int in _near_codes(p, reach):
		var t: Dictionary = tracks[code >> 16]
		if t == own:
			continue
		var pts: PackedVector2Array = t["p"]
		var k := code & 0xffff
		var a := pts[k]
		var ab := pts[k + 1] - a
		var u := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var d := p.distance_to(a + ab * u)
		if d < best.x and d <= reach:
			var f: PackedFloat32Array = t["f"]
			best = Vector2(d, lerpf(f[k], f[k + 1], u))
	return best


## Another track within `reach` of p: (distance, its floor), or INF.
func _track_at(own: Dictionary, p: Vector2, reach: float) -> Vector2:
	return _nearest_other(own, p, reach, false)


## The segments indexed in the cells within `reach` of p (a segment may come twice).
func _near_codes(p: Vector2, reach: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var lo := _key(p - Vector2.ONE * reach)
	var hi := _key(p + Vector2.ONE * reach)
	for cz in range(lo.y, hi.y + 1):
		for cx in range(lo.x, hi.x + 1):
			out.append_array(_cells.get(Vector2i(cx, cz), PackedInt32Array()))
	return out


## The cutting at plan point p: Vector3(height, kind, lateral distance past the floor's edge);
## kind 0 outside, 1 the floor, 2 a bank, 3 the shoulder back to the grid (g: the grid there).
func at(x: float, z: float, g: float) -> Vector3:
	var p := Vector2(x, z)
	if not box.has_point(p):
		return Vector3(g, 0.0, 0.0)
	var codes: PackedInt32Array = _cells.get(_key(p), PackedInt32Array())
	if codes.is_empty():
		return Vector3(g, 0.0, 0.0)
	var best := INF
	var bt := -1
	var bk := 0
	var bu := 0.0
	var blat := 0.0
	for code in codes:
		var t: Dictionary = tracks[code >> 16]
		var pts: PackedVector2Array = t["p"]
		var k := code & 0xffff
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.0001:
			continue
		var u := (p - a).dot(ab) / l2
		# Butt ends: nothing past a track's first or last sample (the tunnel's mouth).
		if (u < 0.0 and k == 0) or (u > 1.0 and k == pts.size() - 2):
			continue
		u = clampf(u, 0.0, 1.0)
		var lat := ab.cross(p - a) / sqrt(l2)
		var d := absf(lat)
		if d < best:
			best = d
			bt = code >> 16
			bk = k
			bu = u
			blat = lat
	if bt < 0:
		return Vector3(g, 0.0, 0.0)
	var t: Dictionary = tracks[bt]
	var cut: PackedByteArray = t["cut"]
	var f: PackedFloat32Array = t["f"]
	var floor_h := lerpf(f[bk], f[bk + 1], bu)
	# Cut weight: 1 where both ends are in, fading over the segment where one is.
	var w := lerpf(float(cut[bk]), float(cut[bk + 1]), bu)
	if w <= 0.0:
		return Vector3(g, 0.0, 0.0)
	var past := best - FLOOR_W
	var h := floor_h
	var kind := 1.0
	if past > 0.0:
		var bv: Vector2 = (t["b"] as PackedVector2Array)[bk].lerp((t["b"] as PackedVector2Array)[bk + 1], bu)
		var rv: Vector2 = (t["r"] as PackedVector2Array)[bk].lerp((t["r"] as PackedVector2Array)[bk + 1], bu)
		var left := blat > 0.0
		var b := bv.x if left else bv.y
		var rim := rv.x if left else rv.y
		var wv: Vector2 = (t["w"] as PackedVector2Array)[bk].lerp((t["w"] as PackedVector2Array)[bk + 1], bu)
		var walled := (wv.x if left else wv.y) > 0.5
		if walled and past < b:
			h = floor_h if past < WALL_FLAT else lerpf(floor_h, maxf(rim, floor_h), (past - WALL_FLAT) / (b - WALL_FLAT))
			kind = 2.0
		elif b < 0.0:
			h = floor_h  # another track's floor beyond: the floor runs on
		elif b < 0.25:
			# An open side: from the floor back to the grid over the shoulder.
			if past >= SHOULDER:
				return Vector3(g, 0.0, 0.0)
			h = lerpf(floor_h, g, past / SHOULDER)
			kind = 3.0
		elif past < b:
			h = lerpf(floor_h, maxf(rim, floor_h), past / b)
			kind = 2.0
		elif past < b + SHOULDER:
			h = lerpf(maxf(rim, g), g, (past - b) / SHOULDER)
			kind = 3.0
		else:
			return Vector3(g, 0.0, 0.0)
	if w < 1.0:
		h = lerpf(g, h, w)
	return Vector3(h, kind, past)


## The outer edges of the cutting, as polylines: [{"toe": PackedVector2Array (the floor's edge),
## "top": PackedVector2Array (the bank's top), "fh": PackedFloat32Array floors, "rh": rims}].
## One run per stretch of a track side that has a bank at least 1.2 m high.
func edges() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t in tracks:
		var pts: PackedVector2Array = t["p"]
		var f: PackedFloat32Array = t["f"]
		var cut: PackedByteArray = t["cut"]
		var bs: PackedVector2Array = t["b"]
		var rs: PackedVector2Array = t["r"]
		var ws: PackedVector2Array = t["w"]
		for side in 2:
			var toe := PackedVector2Array()
			var top := PackedVector2Array()
			var fh := PackedFloat32Array()
			var rh := PackedFloat32Array()
			var outs := PackedVector2Array()
			var wall := PackedByteArray()
			for k in pts.size() + 1:
				var ok := false
				if k < pts.size():
					var b := bs[k].x if side == 0 else bs[k].y
					var rim := rs[k].x if side == 0 else rs[k].y
					var w := (ws[k].x if side == 0 else ws[k].y) > 0.5
					ok = cut[k] == 1 and (b >= BANK_MIN - 0.01 or w) and rim - f[k] > 1.2
					if ok:
						var nm := _normal(pts, k) * (1.0 if side == 0 else -1.0)
						toe.append(pts[k] + nm * FLOOR_W)
						top.append(pts[k] + nm * (FLOOR_W + b))
						fh.append(f[k])
						rh.append(maxf(rim, f[k]))
						outs.append(nm)
						wall.append(1 if w else 0)
				if not ok and toe.size() > 0:
					if toe.size() >= 3:
						out.append({"toe": toe, "top": top, "fh": fh, "rh": rh, "out": outs, "wall": wall})
					toe = PackedVector2Array()
					top = PackedVector2Array()
					fh = PackedFloat32Array()
					rh = PackedFloat32Array()
					outs = PackedVector2Array()
					wall = PackedByteArray()
	return out


## The 10 m grid cells (i, j of a grid from x0, z0 with `step`) the cutting's ground reaches, and
## their sub-cells a side: SUB_WALL by a retaining wall, SUB elsewhere.
func cells(x0: float, z0: float, step: float) -> Dictionary:
	var seen := {}
	for t in tracks:
		var pts: PackedVector2Array = t["p"]
		var cut: PackedByteArray = t["cut"]
		var bs: PackedVector2Array = t["b"]
		var ws: PackedVector2Array = t["w"]
		for k in pts.size():
			if cut[k] == 0 and (k == 0 or cut[k - 1] == 0) and (k == pts.size() - 1 or cut[k + 1] == 0):
				continue
			var reach := FLOOR_W + maxf(maxf(bs[k].x, bs[k].y), 0.0) + SHOULDER + 1.0
			var sub := SUB_WALL if ws[k].x > 0.5 or ws[k].y > 0.5 else SUB
			for cz in range(floori((pts[k].y - reach - z0) / step), floori((pts[k].y + reach - z0) / step) + 1):
				for cx in range(floori((pts[k].x - reach - x0) / step), floori((pts[k].x + reach - x0) / step) + 1):
					var c := Vector2i(cx, cz)
					seen[c] = maxi(int(seen.get(c, 0)), sub)
	return seen
