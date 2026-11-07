extends RefCounted
## Roadworks at the map's edge (2026-11-02, F's ask "roadworks at the ends of the city"): every
## road that leaves the playable map is closed a little inside the outline by believable Warsaw
## roadworks, so a street no longer just runs into the invisible edge wall. Each closure is a line
## of red and white barriers across the road (its amber lamps blink at dusk and at night, with a
## halo each), a B-1 "no entry" disc, cones in front; on the bigger streets a yellow ROBOTY DROGOWE
## board and an OBJAZD → detour board, the A-14 roadworks triangle 18 m ahead, and behind the
## barriers the works themselves: a dug trench, a sand heap, a corrugated pipe, a small excavator
## (on the widest roads a site cabin or a TOJ TOJ, our parody of the blue portable toilet) and a
## 2 m site fence with a tarp that hides the road running on past the edge (map_edge.gd). Service
## roads get a short line of barriers and a cone.
##
## The barrier line stands CLOSE_IN m inside the outline, so it is the barriers the car meets, not
## the invisible wall 5 m in (map_builder.gd `_add_edge_walls`): one box collider per closure on its
## own static body. The traffic stops at the same line (lane_graph.gd `e_shut` and `e_open`).
##
## Cost: everything is one mesh per CHUNK square in the models' material (models.gd, actor.gdshader)
## plus one MultiMesh of halos per square (night only), so a map edge in view adds 1-2 draw calls
## (+ the shadow pass) and the middle of the city nothing. Built in map_builder.setup_streamed (both
## city paths) from the index's roads; `closures` is the same placement for the check
## (game/tools/check_edge_roadworks.gd).
##
## The boards speak the player's language (lang.gd, 2026-11-02): ROBOTY DROGOWE / OBJAZD → in
## Polish, ROAD WORKS / DETOUR → in English (the British board's words, as wide as the Polish so
## the board keeps its size). The text is in the meshes, so a language change in Settings builds
## the roadworks again (`rebuild`).
##
## The prebuilt city (2026-11-05): the bake never yields to the worker thread, so map/index.res holds
## the colliders alone and the phone had invisible barriers. The streamer calls `rebuild` on opening
## it; the boards need the player's language anyway, which a bake can't know.

const Models := preload("res://scripts/models.gd")
const Props := preload("res://scripts/props.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const Lang := preload("res://scripts/lang.gd")

## The barrier line, metres inside the map's outline (the invisible edge wall is 5 m in).
const CLOSE_IN := 12.0
## A road (or a lane) that ends this close to the outline (m) runs on past the edge: the bake cut it
## at the outline, or a few metres short of it.
const EDGE_END := CLOSE_IN - 1.0
## A road that runs along the edge (no crossing of the CLOSE_IN line within WALK m) is closed where it
## comes within ALONG_IN m of the outline instead, just before the wall: barriers across the road.
const ALONG_IN := 6.5
## Each end of such a line stays ALONG_END m inside the outline (the wall is 5 m in), stepping back
## at most ALONG_BACK_STEPS half metres.
const ALONG_END := 6.0
const ALONG_BACK_STEPS := 5
## A small road's barriers that would stand within TIGHT_GAP m of a street's carriageway move out to
## TIGHT_IN m from the outline (or go, the wall closing the road).
const TIGHT_GAP := 2.5
const TIGHT_IN := 8.0
## How far along a road from its end at the outline the barrier line is looked for (m); a road
## that stays inside the band longer runs along the edge, not out of it, and is left to the wall.
const WALK := 90.0
## Pieces of road closer than this (beyond their half widths, m) and about parallel share one closure
## (the two carriageways of an avenue, a road split into several ways at the edge).
const MERGE_GAP := 7.0
## The barrier line runs this far past the carriageway on each side (the kerb, a bit of pavement).
const MARGIN := 0.75
## One mesh per CHUNK x CHUNK square, so only the squares in view are drawn.
const CHUNK := 512.0
## Closure sizes: SMALL a few barriers (service roads, lanes), MEDIUM a street, BIG an avenue.
enum Tier { SMALL, MEDIUM, BIG }

const RED := Color("#d8262b")
const WHITE := Color("#f6f3ec")
const POST := Color("#c9ccd0")
const FOOT := Color("#2f3034")
const AMBER := Color("#ffb21e")
const CONE := Color("#ff6a13")
const SIGN_YELLOW := Color("#f2c12e")
const INK := Color("#1d1b19")
const DIGGER := Color("#f0b41c")
const DIGGER_DARK := Color("#c48d12")
const TRACK := Color("#2f3033")
const GLASS := Color("#3a4552")
const EARTH := Color("#4a3a2c")
const EARTH_DARK := Color("#2f251c")
const SAND := Color("#d8b77a")
const PIPE := Color("#e2742b")
const CONCRETE := Color("#9c9a94")
const FENCE_FRAME := Color("#b8bcc0")
const TARPS: Array[Color] = [Color("#3f6b4a"), Color("#2f5d8a"), Color("#d9d6cc")]


## Where the map's roads are closed: an Array of Dictionaries {at: Vector2 (the barrier line's
## middle), dir: Vector2 (along the road, out of the map), half: float (half the barrier line,
## MARGIN included), tier: Tier, y: float (the road's top there), name: String, ends: int (road
## ends it closes)}, sorted by position. `mb` is the map builder (or one with its in_map, bounds,
## data/index_data, ground_height and terrain_height).
static func closures(mb) -> Array:
	# Worked out once per map (the city and the lane graph both ask).
	if mb.has_meta(&"edge_closures"):
		return mb.get_meta(&"edge_closures")
	var out := _closures(mb)
	mb.set_meta(&"edge_closures", out)
	return out


static func _closures(mb) -> Array:
	var idx: Dictionary = mb.index_data if not mb.index_data.is_empty() else mb.data
	var roads: Array = idx.get("roads", [])
	var joins := _joins(roads)
	var segs := _segments(roads)
	var raw: Array = []
	for ri in roads.size():
		var r: Dictionary = roads[ri]
		if (r["p"] as Array).size() < 4:
			continue
		for first in [true, false]:
			var c := crossing(mb, roads, joins, ri, first)
			if c.is_empty():
				c = crossing(mb, roads, joins, ri, first, ALONG_IN)
				if c.is_empty():
					continue
				c["along"] = true
			var cr: Dictionary = roads[int(c["road"])]
			c["w"] = maxf(float(cr.get("w", 3.0)), 2.5)
			c["kind"] = String(cr.get("k", ""))
			c["name"] = String(cr.get("name", ""))
			c["deck"] = bool(cr.get("bridge", false)) or int(cr.get("dk", -1)) >= 0
			if _tier_of(c["kind"], c["w"]) == Tier.SMALL and _tight(roads, segs, c):
				# A lane or a yard's way in right beside a street: its barriers would stand in the
				# street's lanes. Closed further out instead, or left to the edge wall.
				var out := crossing(mb, roads, joins, ri, first, TIGHT_IN)
				if out.is_empty():
					continue
				out["w"] = c["w"]
				out["kind"] = c["kind"]
				out["name"] = c["name"]
				out["deck"] = c["deck"]
				if _tight(roads, segs, out):
					continue
				c = out
			raw.append(c)
	return _merge(mb, raw)


## The roads' pieces by 16 m cell: [road, a, b] each, for `_tight`.
static func _segments(roads: Array) -> Dictionary:
	var out := {}
	for ri in roads.size():
		var flat: Array = (roads[ri] as Dictionary)["p"]
		for k in range(0, flat.size() / 2 - 1):
			var a := Vector2(flat[k * 2], flat[k * 2 + 1])
			var b := Vector2(flat[k * 2 + 2], flat[k * 2 + 3])
			var lo := Vector2i(floori(minf(a.x, b.x) / 16.0), floori(minf(a.y, b.y) / 16.0))
			var hi := Vector2i(floori(maxf(a.x, b.x) / 16.0), floori(maxf(a.y, b.y) / 16.0))
			for x in range(lo.x, hi.x + 1):
				for z in range(lo.y, hi.y + 1):
					var key := Vector2i(x, z)
					if not out.has(key):
						out[key] = []
					out[key].append([ri, a, b])
	return out


## Whether a small road's crossing c lies so close to another, bigger road that its barriers would
## reach into that road's lanes (TIGHT_GAP past both half widths).
static func _tight(roads: Array, segs: Dictionary, c: Dictionary) -> bool:
	var at: Vector2 = c["at"]
	var cell := Vector2i(floori(at.x / 16.0), floori(at.y / 16.0))
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			for sg: Array in segs.get(cell + Vector2i(dx, dz), []):
				var r: Dictionary = roads[int(sg[0])]
				if int(sg[0]) == int(c["road"]) or _tier_of(String(r.get("k", "")), float(r.get("w", 3.0))) == Tier.SMALL:
					continue
				var q := Geometry2D.get_closest_point_to_segment(at, sg[1], sg[2])
				if at.distance_to(q) < float(r.get("w", 3.0)) * 0.5 + float(c["w"]) * 0.5 + TIGHT_GAP:
					return true
	return false


## The roads' ends by where they lie (1 m cells): [road, its first end?] pairs.
static func _joins(roads: Array) -> Dictionary:
	var out := {}
	for ri in roads.size():
		var r: Dictionary = roads[ri]
		var flat: Array = r["p"]
		var n := flat.size() / 2
		if n < 2:
			continue
		for first in [true, false]:
			var i := 0 if first else n - 1
			var key := Vector2i(roundi(float(flat[i * 2])), roundi(float(flat[i * 2 + 1])))
			if not out.has(key):
				out[key] = []
			out[key].append([ri, first])
	return out


## A road's points from one end (`first`: its first point) to the other.
static func _points(r: Dictionary, first: bool) -> Array[Vector2]:
	var flat: Array = r["p"]
	var n := flat.size() / 2
	var pts: Array[Vector2] = []
	for k in n:
		var i := k if first else n - 1 - k
		pts.append(Vector2(flat[i * 2], flat[i * 2 + 1]))
	return pts


## Where a road's end at the outline meets the barrier line, walking in from that end and on along
## the roads that continue it (a way split near the edge; the straightest one at a fork): {at, dir
## (out of the map), road (the index of the road crossing it)}, or {} when the end is not at the
## outline or the road runs along the edge (no crossing within WALK m).
static func crossing(mb, roads: Array, joins: Dictionary, ri: int, first: bool, inset := CLOSE_IN) -> Dictionary:
	var pts := _points(roads[ri], first)
	if mb.in_map(pts[0], -EDGE_END):
		return {}
	var walked := 0.0
	var road := ri
	var seen := {ri: true}
	while true:
		for k in range(1, pts.size()):
			var a := pts[k - 1]
			var b := pts[k]
			if mb.in_map(b, -inset):
				# Bisect the piece for the crossing.
				var lo := 0.0
				var hi := 1.0
				for _i in 18:
					var m := (lo + hi) * 0.5
					if mb.in_map(a.lerp(b, m), -inset):
						hi = m
					else:
						lo = m
				var dir := (a - b).normalized()
				if dir == Vector2.ZERO:
					return {}
				return {"at": a.lerp(b, hi), "dir": dir, "road": road}
			walked += a.distance_to(b)
			if walked > WALK:
				return {}
		# On along the road that continues this one at its inner end.
		var tail := pts[pts.size() - 1]
		var here := (tail - pts[pts.size() - 2]).normalized()
		var best: Array[Vector2] = []
		var best_dot := -0.2
		var best_road := -1
		var near: Array = []
		var cell := Vector2i(roundi(tail.x), roundi(tail.y))
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				near.append_array(joins.get(cell + Vector2i(dx, dz), []))
		for j: Array in near:
			if seen.has(int(j[0])):
				continue
			var next := _points(roads[int(j[0])], bool(j[1]))
			if next[0].distance_to(tail) > 1.2:
				continue
			var d := (next[1] - next[0]).normalized().dot(here)
			if d > best_dot:
				best_dot = d
				best = next
				best_road = int(j[0])
		if best_road < 0:
			return {}
		seen[best_road] = true
		road = best_road
		pts = best
	return {}


## The outward normal of the outline's side at a barrier crossing p (the outline is axis-aligned:
## one of the four axes; at a corner the one nearest the road's way out `dir`).
static func _normal(mb, p: Vector2, dir: Vector2) -> Vector2:
	var best := dir
	var best_dot := -INF
	for n: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if mb.in_map(p - n * 1.5, -CLOSE_IN) and not mb.in_map(p + n * 1.5, -CLOSE_IN) and n.dot(dir) > best_dot:
			best_dot = n.dot(dir)
			best = n
	return best


## How far a road w wide crossing the barrier line at `dir` reaches along it, each side, MARGIN
## included (m): a road that meets the edge at a slant cuts the line over a longer stretch.
static func _reach(w: float, dir: Vector2, n: Vector2) -> float:
	return (w * 0.5 + MARGIN) / maxf(absf(dir.dot(n)), 0.7)


## The crossings as closures: each barrier line runs along the outline's side (parallel to the edge,
## CLOSE_IN in); crossings on the same side close together share one (the two carriageways of an
## avenue, a slip road beside it, a road split into several ways at the edge).
static func _merge(mb, raw: Array) -> Array:
	for c: Dictionary in raw:
		# A road along the edge: its own barrier line, across the road.
		c["n"] = c["dir"] if c.has("along") else _normal(mb, c["at"], c["dir"])
		# One meeting the edge at a shallow slant too (a line along the edge would run along it).
		if absf((c["n"] as Vector2).dot(c["dir"])) < 0.7:
			c["n"] = c["dir"]
		c["reach"] = _reach(float(c["w"]), c["dir"], c["n"])
		if _tier_of(String(c["kind"]), float(c["w"])) == Tier.SMALL:
			# A lane or a yard's way in, often right beside a street: the barriers stop at its kerbs.
			c["reach"] = float(c["reach"]) - MARGIN / maxf(absf((c["dir"] as Vector2).dot(c["n"])), 0.7)
	var group := range(raw.size())
	for i in raw.size():
		for j in range(i + 1, raw.size()):
			var a: Dictionary = raw[i]
			var b: Dictionary = raw[j]
			var n: Vector2 = a["n"]
			if n.dot(b["n"]) < 0.99 or a.has("along") != b.has("along"):
				continue
			var rel: Vector2 = (b["at"] as Vector2) - (a["at"] as Vector2)
			if absf(rel.dot(n)) > 2.0 or absf(rel.dot(Vector2(n.y, -n.x))) > float(a["reach"]) + float(b["reach"]) + MERGE_GAP:
				continue
			var gi: int = _root(group, i)
			var gj: int = _root(group, j)
			if gi != gj:
				group[maxi(gi, gj)] = mini(gi, gj)
	var sets := {}
	for i in raw.size():
		var g: int = _root(group, i)
		if not sets.has(g):
			sets[g] = []
		sets[g].append(raw[i])
	var out: Array = []
	for g in sets:
		var parts: Array = sets[g]
		var dir: Vector2 = (parts[0] as Dictionary)["n"]
		var mid := Vector2.ZERO
		for p: Dictionary in parts:
			mid += p["at"]
		mid /= parts.size()
		var side := Vector2(dir.y, -dir.x)
		var lo := INF
		var hi := -INF
		var along := 0.0
		var tier: int = Tier.SMALL
		var name := ""
		var deck := false
		var widest := 0.0
		var along_edge := false
		for p: Dictionary in parts:
			along_edge = along_edge or p.has("along")
			var rel: Vector2 = p["at"] - mid
			var x := rel.dot(side)
			var r := float(p["reach"])
			lo = minf(lo, x - r)
			hi = maxf(hi, x + r)
			along += rel.dot(dir)
			var w := float(p["w"])
			tier = maxi(tier, _tier_of(String(p["kind"]), w))
			deck = deck or bool(p["deck"])
			if w > widest and String(p["name"]) != "":
				widest = w
				name = p["name"]
		var at := mid + side * (lo + hi) * 0.5 + dir * (along / parts.size())
		var half := (hi - lo) * 0.5
		if half * 2.0 >= 12.0 and tier == Tier.MEDIUM:
			tier = Tier.BIG
		if along_edge:
			# No room for the works behind the barriers before the wall.
			tier = mini(tier, Tier.MEDIUM)
			# An outline slanting across the road brings the wall nearer on one side: step the line
			# back until both its ends stand in front of the wall (Bonifraterska's lane 0, PT W3).
			var back := 0
			while back < ALONG_BACK_STEPS and not (mb.in_map(at + side * half, -ALONG_END) and mb.in_map(at - side * half, -ALONG_END)):
				at -= dir * 0.5
				back += 1
		var y: float = mb.ground_height(at.x, at.y) if deck else mb.terrain_height(at.x, at.y)
		out.append({"at": at, "dir": dir, "half": half, "tier": tier, "y": y, "name": name, "ends": parts.size(),
				"along": along_edge})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: Vector2 = a["at"]
		var pb: Vector2 = b["at"]
		return pa.x < pb.x or (pa.x == pb.x and pa.y < pb.y))
	return out


## PT-28 (2026-11-07): a tram strip between two closed carriageways (Grochowska at the east edge)
## was an open way out: the car drove up it level with the barriers. The strip gets a collider
## across it on the barrier line, from one closure's end to the other's, and barriers drawn on it
## wherever a tram's sides (TRAM_CLEAR m from its track: half a 2.4 m car and a little) leave room:
## the trams still run out over the line (trams.gd, no physics), so their own way stays clear.
## {at, dir, half, y, rails (the tracks' offsets along the line)} each, in the closures' frame
## (`frame`). A tram crossing with a closure on one side only, or none within RAIL_REACH m, is left
## to the edge wall.
const RAIL_REACH := 12.0
const TRAM_CLEAR := 1.4


static func rail_gaps(mb) -> Array:
	if mb.has_meta(&"edge_rail_gaps"):
		return mb.get_meta(&"edge_rail_gaps")
	var out: Array = []
	var list := closures(mb)
	var idx: Dictionary = mb.index_data if not mb.index_data.is_empty() else mb.data
	var trams: Array = idx.get("trams", [])
	var joins := _joins(trams)
	var seen := {}
	for ti in trams.size():
		if (trams[ti]["p"] as Array).size() < 4:
			continue
		for first in [true, false]:
			var c := crossing(mb, trams, joins, ti, first)
			if c.is_empty():
				continue
			var at: Vector2 = c["at"]
			var n := _normal(mb, at, c["dir"])
			var side := Vector2(n.y, -n.x)
			var left := -INF
			var right := INF
			var line := 0.0
			var covered := false
			for k: Dictionary in list:
				if (k["dir"] as Vector2).dot(n) < 0.99 or bool(k.get("along", false)):
					continue
				var rel: Vector2 = (k["at"] as Vector2) - at
				if absf(rel.dot(n)) > 2.5:
					continue
				var x := rel.dot(side)
				var half := float(k["half"])
				if x - half < 0.0 and x + half > 0.0:
					covered = true
					break
				if x + half <= 0.0 and x + half > -RAIL_REACH and x + half > left:
					left = x + half
					line = rel.dot(n)
				elif x - half >= 0.0 and x - half < RAIL_REACH and x - half < right:
					right = x - half
			if covered or left == -INF or right == INF:
				continue
			var mid := at + n * line + side * (left + right) * 0.5
			var key := Vector2i(roundi(mid.x), roundi(mid.y))
			if not seen.has(key):
				seen[key] = {"at": mid, "dir": n, "half": (right - left) * 0.5 + 0.3, "y": mb.terrain_height(mid.x, mid.y), "rails": []}
				out.append(seen[key])
			(seen[key]["rails"] as Array).append((at - mid).dot(side))
	mb.set_meta(&"edge_rail_gaps", out)
	return out


static func _root(group: Array, i: int) -> int:
	while group[i] != i:
		i = group[i]
	return i


static func _tier_of(kind: String, w: float) -> int:
	if kind in ["primary", "secondary", "trunk", "primary_link", "secondary_link"] and w >= 6.0:
		return Tier.BIG
	if kind in ["service", "track"] or w < 4.5:
		return Tier.SMALL
	return Tier.MEDIUM


## The closures as a node: "EdgeRoadworks" with the colliders ("Barriers", at once), the meshes and
## the halos ("Halos", night only). The meshes (~0.45 M triangles over the whole map edge, 1-2 s of
## GDScript on the cloud CPU) are put together on a worker thread and join the node when ready, so
## the city's start doesn't wait for them; `now` builds them at once (the check). Null when the map
## has no bounds or no road leaves it.
static func build(mb, now := false) -> Node3D:
	if mb.bounds.size == Vector2.ZERO:
		return null
	var t0 := Time.get_ticks_msec()
	var list := closures(mb)
	if list.is_empty():
		return null
	var b = (load("res://scripts/edge_roadworks.gd") as GDScript).new()
	b._en = Lang.is_en()  # read here, not on the worker thread
	var gaps := rail_gaps(mb)
	var root: Node3D = b._colliders(list + gaps)
	print("edge roadworks: %d closures (%d big, %d medium), placed in %d ms" % [list.size(),
			b._count(list, Tier.BIG), b._count(list, Tier.MEDIUM), Time.get_ticks_msec() - t0])
	if now:
		b._attach(weakref(root) as WeakRef, b._shapes(list + gaps), false)
	else:
		var ref: WeakRef = weakref(root)
		b._task = WorkerThreadPool.add_task(func() -> void:
			var shapes: Dictionary = b._shapes(list + gaps)
			b._attach.bind(ref, shapes, true).call_deferred())
		# Quitting (or a tool's quick run) before the meshes are ready: wait for the thread first.
		root.tree_exiting.connect(b._finish)
		# The node keeps the builder alive while it adds the meshes over several frames (a coroutine
		# whose object is freed never resumes).
		root.set_meta(&"builder", b)
	return root


## The roadworks board's lines in the player's language (`en` asks for English whatever is set).
static func works_lines(en := Lang.is_en()) -> Array:
	return ["ROAD", "WORKS"] if en else ["ROBOTY", "DROGOWE"]


## The detour board's line in the player's language.
static func detour_lines(en := Lang.is_en()) -> Array:
	return ["DETOUR →"] if en else ["OBJAZD →"]


## The language changed (main.gd `_set_language`): the boards' words are in the meshes, so the
## node is made again in the new language (the placement is cached on the map; the colliders come
## back at once, the meshes over the next frames). Nothing when the map has no roadworks
## (--no-edge-roadworks frees them, an empty map never had them).
static func rebuild(mb) -> void:
	var old := mb.get_node_or_null("EdgeRoadworks") as Node3D
	if old == null:
		return
	mb.remove_child(old)
	old.queue_free()
	var works := build(mb)
	if works != null:
		mb.add_child(works)


var _tris := 0
var _task := -1
## The boards in English: the language when `build` was called.
var _en := false
## Main-thread time a frame spends adding the meshes (µs).
const ATTACH_BUDGET_US := 3000


## Waits for the worker's task (at once when it is done); every task is waited for once.
func _finish() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _count(list: Array, tier: int) -> int:
	var n := 0
	for c: Dictionary in list:
		if int(c["tier"]) == tier:
			n += 1
	return n


## The node with the collider: a wall along each barrier line, as tall as a van, a little deeper
## than the barriers' feet.
func _colliders(list: Array) -> Node3D:
	var root := Node3D.new()
	root.name = "EdgeRoadworks"
	var body := StaticBody3D.new()
	body.name = "Barriers"
	root.add_child(body)
	for c: Dictionary in list:
		var xf := frame(c)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(float(c["half"]) * 2.0, 3.0, 0.9)
		cs.shape = box
		cs.transform = Transform3D(xf.basis, xf * Vector3(0, 1.5, 0))
		body.add_child(cs)
	return root


## The meshes' arrays and the lamps per CHUNK square: {Vector2i: [arrays, lamps]}. No scene or
## server calls, so it runs on a worker thread.
func _shapes(list: Array) -> Dictionary:
	var tools := {}
	var lamps := {}
	for c: Dictionary in list:
		var key := Vector2i(floori((c["at"] as Vector2).x / CHUNK), floori((c["at"] as Vector2).y / CHUNK))
		if not tools.has(key):
			var st0 := SurfaceTool.new()
			st0.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[key] = st0
			lamps[key] = []
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector2i(roundi((c["at"] as Vector2).x), roundi((c["at"] as Vector2).y)))
		if c.has("rails"):
			_rail_gap(tools[key], frame(c), c, lamps[key])
		else:
			_closure(tools[key], frame(c), c, rng, lamps[key])
	var out := {}
	for k: Vector2i in tools:
		out[k] = [(tools[k] as SurfaceTool).commit_to_arrays(), lamps[k]]
	return out


## Adds the meshes (one per square, the models' material) and the halos (one MultiMesh per square)
## to the node, unless it is gone (--no-edge-roadworks frees it); `spread`: at most ATTACH_BUDGET_US
## of a frame on it, so no frame uploads them all.
func _attach(ref: WeakRef, shapes: Dictionary, spread: bool) -> void:
	_finish()
	var root := ref.get_ref() as Node3D
	if root == null:
		return
	var t0 := Time.get_ticks_msec()
	var halos := Node3D.new()
	halos.name = "Halos"
	# Lit or not as the city's other night lights are now (main.gd shows the group when the lights
	# come on; these arrive later).
	halos.visible = false
	if root.is_inside_tree():
		var other := root.get_tree().get_first_node_in_group("night_lights") as Node3D
		if other != null:
			halos.visible = other.visible
	halos.add_to_group("night_lights", true)
	root.add_child(halos)
	var halo_mesh := Props.halo(1.3, Color(1.0, 0.62, 0.12, 0.85))
	var halo_mat := Props.glow_material(true, 0.8)
	halo_mat.set_shader_parameter("blink", true)
	var keys := shapes.keys()
	keys.sort()
	var frame_t0 := Time.get_ticks_usec()
	for k: Vector2i in keys:
		if spread and root.is_inside_tree() and Time.get_ticks_usec() - frame_t0 > ATTACH_BUDGET_US:
			await root.get_tree().process_frame
			if ref.get_ref() == null:
				return
			frame_t0 = Time.get_ticks_usec()
		var arrays: Array = shapes[k][0]
		var lamps: Array = shapes[k][1]
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_tris += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		var mi := MeshInstance3D.new()
		mi.name = "Works_%d_%d" % [k.x, k.y]
		mi.mesh = mesh
		mi.material_override = Models.material()
		root.add_child(mi)
		if lamps.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = halo_mesh
		mm.instance_count = lamps.size()
		for i in lamps.size():
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, lamps[i]))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Halos_%d_%d" % [k.x, k.y]
		mmi.multimesh = mm
		mmi.material_override = halo_mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halos.add_child(mmi)
	print("edge roadworks: %d triangles in %d pieces, %d halo sets, attached in %d ms" % [_tris, keys.size(),
			halos.get_child_count(), Time.get_ticks_msec() - t0])
	if root.has_meta(&"builder"):
		root.tree_exiting.disconnect(_finish)
		root.remove_meta(&"builder")


## A closure's frame: origin on the road at the barrier line's middle, x across the road, y up,
## z along the road out of the map (so -z faces the driver coming up to it, like the props' fronts).
static func frame(c: Dictionary) -> Transform3D:
	var d: Vector2 = c["dir"]
	var z := Vector3(d.x, 0, d.y)
	var x := Vector3(d.y, 0, -d.x)
	var at: Vector2 = c["at"]
	return Transform3D(Basis(x, Vector3.UP, z), Vector3(at.x, float(c["y"]), at.y))


func _closure(st: SurfaceTool, xf: Transform3D, c: Dictionary, rng: RandomNumberGenerator, lamps: Array) -> void:
	var half: float = c["half"]
	var tier: int = c["tier"]
	# The barrier line: 2 m barriers edge to edge (a short overlap when the span doesn't divide).
	var n := maxi(2, ceili(half * 2.0 / 2.0))
	var step := (half * 2.0 - 2.0) / (n - 1)
	for i in n:
		var x := -half + 1.0 + step * i
		_barrier(st, xf, Vector3(x, 0, 0), lamps, i % 2 == 0 or tier == Tier.SMALL)
	if tier == Tier.SMALL:
		_cone(st, xf, Vector3(rng.randf_range(-0.4, 0.4) * half, 0, -1.6))
		return
	# The B-1 disc (no entry) on a post in front of the middle barrier.
	_no_entry(st, xf, Vector3(0, 0, -0.75))
	# Cones: a row in front of the barriers, and on a big road a taper closing in from the right.
	var k := 0
	var x0 := -half + 1.5
	while x0 < half - 1.0:
		if absf(x0) > 0.9:
			_cone(st, xf, Vector3(x0, 0, -2.2 - (k % 2) * 0.5))
		x0 += 2.6
		k += 1
	var right := -1.0 if rng.randf() < 0.5 else 1.0
	if tier == Tier.BIG:
		for j in 5:
			_cone(st, xf, Vector3(right * (half - 1.2 - j * 0.9), 0, -5.0 - j * 3.2))
		_triangle_sign(st, xf, Vector3(-(half + 0.6), 0, -18.0))
	# Boards: ROBOTY DROGOWE on the left (as the driver sees it), OBJAZD → on the right.
	_board(st, xf, Vector3(minf(half - 1.4, 3.6), 0, -1.3), works_lines(_en), 0.08)
	if tier == Tier.BIG or half >= 4.0:
		_board(st, xf, Vector3(-minf(half - 1.3, 3.6), 0, -1.3), detour_lines(_en), 0.08)
	var tarp: Color = TARPS[rng.randi() % TARPS.size()]
	if bool(c.get("along", false)):
		# A road along the edge, closed just before the wall: only the fence close behind.
		_fence_line(st, xf, half, 1.8, tarp)
		return
	# Behind the barriers: the works, then the site fence (it hides the road running on past the edge).
	var trench := minf(half * 1.2, 9.0)
	_xbox(st, xf, Vector3(rng.randf_range(-0.2, 0.2) * half, 0.04, 3.6), Vector3(trench, 0.08, 2.6), EARTH)
	_xbox(st, xf, Vector3(0, 0.09, 3.6), Vector3(trench * 0.8, 0.06, 1.2), EARTH_DARK)
	var heap := Vector3(-right * half * 0.45, 0, 6.2)
	_xbox(st, xf, heap + Vector3(0, 0.3, 0), Vector3(2.6, 0.6, 2.0), SAND)
	_xbox(st, xf, heap + Vector3(0.2, 0.75, 0.1), Vector3(1.5, 0.35, 1.2), SAND.darkened(0.06))
	_xbeam(st, xf, Vector3(-half * 0.6, 0.3, 1.6), Vector3(-half * 0.6 + 3.6, 0.3, 1.9), 0.55, 0.55, PIPE)
	if tier == Tier.BIG:
		var dig := Vector3(right * half * 0.35, 0, 6.6)
		_excavator(st, xf, dig, right * rng.randf_range(0.2, 0.5), lamps)
		if half > 6.5:
			var spot := Vector3(-right * (half - 1.6), 0, 6.8)
			if rng.randf() < 0.5:
				_cabin(st, xf, spot)
			else:
				_toilet(st, xf, spot)
	_fence_line(st, xf, half + 2.5, 10.0 if tier == Tier.BIG else 7.0, tarp)


## PT-28: a tram strip's barriers, wherever a tram's sides leave room for one (2 m each).
func _rail_gap(st: SurfaceTool, xf: Transform3D, c: Dictionary, lamps: Array) -> void:
	var half: float = c["half"]
	var x := -half + 1.0
	while x <= half - 1.0 + 0.01:
		var clear := true
		for r: float in c["rails"]:
			if absf(x - r) < TRAM_CLEAR + 1.0:
				clear = false
		if clear:
			_barrier(st, xf, Vector3(x, 0, 0), lamps, true)
			x += 2.0
		else:
			x += 0.25


## The site fence across the road at z, `span` m each side of the middle, in panels of about 3.5 m.
func _fence_line(st: SurfaceTool, xf: Transform3D, span: float, z: float, tarp: Color) -> void:
	var panels := ceili(span * 2.0 / 3.5)
	var pw := span * 2.0 / panels
	for i in panels:
		_fence(st, xf, Vector3(-span + pw * (i + 0.5), 0, z), pw, tarp)


# --- the pieces (local to the closure's frame) ------------------------------------------------

## The roadworks barrier (props.gd `barrier`, the same look) at `at`; its lamp joins `lamps` when `lit`.
func _barrier(st: SurfaceTool, xf: Transform3D, at: Vector3, lamps: Array, lit: bool) -> void:
	for k in 5:
		_xbox(st, xf, at + Vector3(-0.8 + k * 0.4, 0.95, 0), Vector3(0.4, 0.46, 0.14), RED if k % 2 == 0 else WHITE)
		_xbox(st, xf, at + Vector3(-0.8 + k * 0.4, 0.39, 0), Vector3(0.4, 0.22, 0.12), WHITE if k % 2 == 0 else RED)
	for x in [-0.93, 0.93]:
		_xbox(st, xf, at + Vector3(x, 0.6, 0), Vector3(0.1, 1.2, 0.1), POST)
		_xbox(st, xf, at + Vector3(x, 0.05, 0), Vector3(0.2, 0.1, 0.85), FOOT)
	_xbox(st, xf, at + Vector3(-0.78, 1.24, 0), Vector3(0.08, 0.1, 0.08), FOOT)
	_xbox(st, xf, at + Vector3(-0.78, 1.4, 0), Vector3(0.28, 0.24, 0.2), AMBER, Models.BLINK)
	if lit:
		lamps.append(xf * (at + Vector3(-0.78, 1.4, 0)))


func _cone(st: SurfaceTool, xf: Transform3D, at: Vector3) -> void:
	_xbox(st, xf, at + Vector3(0, 0.03, 0), Vector3(0.6, 0.06, 0.6), Color("#2b2c2f"))
	_xbox(st, xf, at + Vector3(0, 0.18, 0), Vector3(0.44, 0.24, 0.44), CONE)
	_xbox(st, xf, at + Vector3(0, 0.38, 0), Vector3(0.34, 0.16, 0.34), WHITE)
	_xbox(st, xf, at + Vector3(0, 0.6, 0), Vector3(0.22, 0.28, 0.22), CONE)


## B-1 (zakaz ruchu): a white disc in a red ring, as two crossed plates each, on a grey post.
func _no_entry(st: SurfaceTool, xf: Transform3D, at: Vector3) -> void:
	_xbox(st, xf, at + Vector3(0, 0.9, 0), Vector3(0.07, 1.8, 0.07), POST)
	var c := at + Vector3(0, 2.05, -0.05)
	_xbox(st, xf, c, Vector3(0.78, 0.52, 0.04), RED)
	_xbox(st, xf, c, Vector3(0.52, 0.78, 0.04), RED)
	_xbox(st, xf, c + Vector3(0, 0, -0.025), Vector3(0.56, 0.36, 0.02), WHITE)
	_xbox(st, xf, c + Vector3(0, 0, -0.025), Vector3(0.36, 0.56, 0.02), WHITE)


## A-14 (roboty drogowe): the red-edged white triangle with a black digging figure, on a post.
func _triangle_sign(st: SurfaceTool, xf: Transform3D, at: Vector3) -> void:
	_xbox(st, xf, at + Vector3(0, 0.95, 0), Vector3(0.07, 1.9, 0.07), POST)
	var n := xf.basis * Vector3(0, 0, -1)
	var c := at + Vector3(0, 2.25, -0.05)
	_tri_local(st, xf, c + Vector3(-0.5, -0.36, 0), c + Vector3(0.5, -0.36, 0), c + Vector3(0, 0.5, 0), n, RED)
	var w := c + Vector3(0, 0, -0.01)
	_tri_local(st, xf, w + Vector3(-0.36, -0.27, 0), w + Vector3(0.36, -0.27, 0), w + Vector3(0, 0.36, 0), n, WHITE)
	# The figure: a body, a head and the spade on a small heap.
	var f := c + Vector3(0, 0, -0.02)
	_xbox(st, xf, f + Vector3(0.03, -0.05, 0), Vector3(0.08, 0.2, 0.01), INK)
	_xbox(st, xf, f + Vector3(0.03, 0.09, 0), Vector3(0.07, 0.07, 0.01), INK)
	_xbox(st, xf, f + Vector3(-0.1, -0.08, 0), Vector3(0.16, 0.03, 0.01), INK)
	_xbox(st, xf, f + Vector3(-0.14, -0.2, 0), Vector3(0.16, 0.06, 0.01), INK)


## A yellow board on two posts with black pixel lines, facing the driver (-z).
func _board(st: SurfaceTool, xf: Transform3D, at: Vector3, lines: Array, px: float) -> void:
	var tw := 0.0
	for l: String in lines:
		tw = maxf(tw, PixelFont.width(l) * px)
	var w := tw + 0.4
	var lh := PixelFont.LINE * px
	var h := lines.size() * lh + 0.25
	var y0 := 1.0
	for x in [-w * 0.5 + 0.18, w * 0.5 - 0.18]:
		_xbox(st, xf, at + Vector3(x, (y0 + 0.1) * 0.5, 0.04), Vector3(0.07, y0 + 0.1, 0.07), POST)
	_xbox(st, xf, at + Vector3(0, y0 + h * 0.5, 0), Vector3(w, h, 0.05), SIGN_YELLOW)
	_xbox(st, xf, at + Vector3(0, y0 + h * 0.5, 0.01), Vector3(w + 0.1, h + 0.1, 0.03), INK)
	var top := y0 + h - 0.12 - PixelFont.BODY * px * 0.5
	for i in lines.size():
		var l: String = lines[i]
		var lw := PixelFont.width(l) * px
		var o := at + Vector3(lw * 0.5, top - i * lh, -0.03)
		PixelFont.add_quads(st, l, xf * o, xf.basis * Vector3.LEFT, xf.basis * Vector3.DOWN, px, INK, Models.FIXED)
	# An amber lamp on the board's top corner, blinking with the barriers'.
	_xbox(st, xf, at + Vector3(w * 0.5 - 0.15, y0 + h + 0.13, 0), Vector3(0.18, 0.18, 0.14), AMBER, Models.BLINK)


## A small tracked excavator turned `yaw` about its own centre (front, the arm, towards -z),
## its bucket down in the trench; an amber beacon on the cab.
func _excavator(st: SurfaceTool, xf: Transform3D, at: Vector3, yaw: float, lamps: Array) -> void:
	var m := xf * Transform3D(Basis(Vector3.UP, yaw), at)
	for x in [-1.0, 1.0]:
		_xbox(st, m, Vector3(x, 0.35, 0), Vector3(0.5, 0.7, 3.2), TRACK)
	_xbox(st, m, Vector3(0, 0.8, 0), Vector3(1.4, 0.3, 2.0), TRACK.lightened(0.1))
	_xbox(st, m, Vector3(0, 1.45, 0.2), Vector3(2.2, 1.0, 2.4), DIGGER)
	_xbox(st, m, Vector3(0, 1.3, 1.55), Vector3(2.2, 0.75, 0.5), DIGGER_DARK)
	_xbox(st, m, Vector3(-0.55, 2.6, -0.45), Vector3(1.0, 1.3, 1.1), DIGGER)
	_xbox(st, m, Vector3(-0.55, 2.7, -1.01), Vector3(0.85, 0.8, 0.04), GLASS)
	_xbox(st, m, Vector3(-1.06, 2.7, -0.45), Vector3(0.04, 0.8, 0.9), GLASS)
	_xbox(st, m, Vector3(0.75, 2.3, 0.9), Vector3(0.1, 0.7, 0.1), TRACK)
	_xbeam(st, m, Vector3(0.45, 1.9, -0.8), Vector3(0.45, 3.7, -3.0), 0.4, 0.45, DIGGER)
	_xbeam(st, m, Vector3(0.45, 3.7, -3.0), Vector3(0.45, 1.1, -4.2), 0.3, 0.3, DIGGER_DARK)
	_xbox(st, m, Vector3(0.45, 0.65, -4.3), Vector3(0.9, 0.6, 0.7), TRACK)
	_xbox(st, m, Vector3(-0.55, 3.33, -0.45), Vector3(0.2, 0.16, 0.2), AMBER, Models.BLINK)
	lamps.append(m * Vector3(-0.55, 3.33, -0.45))


## A blue site cabin (a container office) with a window and a door.
func _cabin(st: SurfaceTool, xf: Transform3D, at: Vector3) -> void:
	_xbox(st, xf, at + Vector3(0, 1.3, 0), Vector3(2.4, 2.6, 5.8), Color("#3466a8"))
	_xbox(st, xf, at + Vector3(0, 2.65, 0), Vector3(2.5, 0.1, 5.9), Color("#d9d6cc"))
	_xbox(st, xf, at + Vector3(0, 0.08, 0), Vector3(2.5, 0.16, 5.9), CONCRETE)
	for s in [-1.0, 1.0]:
		_xbox(st, xf, at + Vector3(s * 1.21, 1.6, -1.2), Vector3(0.03, 0.8, 1.3), GLASS)
		_xbox(st, xf, at + Vector3(s * 1.21, 1.05, 1.4), Vector3(0.03, 1.9, 0.85), Color("#2a4f80"))


## TOJ TOJ: our parody of the blue portable toilet, its name on the door.
func _toilet(st: SurfaceTool, xf: Transform3D, at: Vector3) -> void:
	_xbox(st, xf, at + Vector3(0, 1.15, 0), Vector3(1.15, 2.3, 1.15), Color("#2f6fd0"))
	_xbox(st, xf, at + Vector3(0, 2.36, 0), Vector3(1.25, 0.12, 1.25), WHITE)
	_xbox(st, xf, at + Vector3(0, 1.1, -0.59), Vector3(0.8, 1.9, 0.03), Color("#2a5fb4"))
	var px := 0.045
	var word := "TOJ TOJ"
	var lw := PixelFont.width(word) * px
	PixelFont.add_quads(st, word, xf * (at + Vector3(lw * 0.5, 1.95, -0.61)), xf.basis * Vector3.LEFT,
			xf.basis * Vector3.DOWN, px, WHITE, Models.FIXED)


## One panel of the 2 m site fence: steel frame and tarp on two concrete feet.
func _fence(st: SurfaceTool, xf: Transform3D, at: Vector3, w: float, tarp: Color) -> void:
	for x in [-w * 0.5 + 0.05, w * 0.5 - 0.05]:
		_xbox(st, xf, at + Vector3(x, 0.08, 0), Vector3(0.24, 0.16, 0.6), CONCRETE)
		_xbox(st, xf, at + Vector3(x, 1.05, 0), Vector3(0.05, 1.9, 0.05), FENCE_FRAME)
	_xbox(st, xf, at + Vector3(0, 1.98, 0), Vector3(w, 0.05, 0.05), FENCE_FRAME)
	_xbox(st, xf, at + Vector3(0, 1.1, 0), Vector3(w - 0.1, 1.6, 0.03), tarp)


func _xbox(st: SurfaceTool, xf: Transform3D, centre: Vector3, size: Vector3, colour: Color, part := Models.FIXED) -> void:
	Props._xbox(st, xf, centre, size, colour, part)


func _xbeam(st: SurfaceTool, xf: Transform3D, a: Vector3, b: Vector3, w: float, t: float, colour: Color) -> void:
	Props._xbeam(st, xf, a, b, w, t, colour)


func _tri_local(st: SurfaceTool, xf: Transform3D, a: Vector3, b: Vector3, c: Vector3, n: Vector3, colour: Color) -> void:
	Props.tri(st, xf * a, xf * b, xf * c, n, colour)
