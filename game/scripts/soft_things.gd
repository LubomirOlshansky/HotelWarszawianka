extends Node
## The city objects plan, step 7 (docs/design/drivable-city-build.md item 3 and section 5): the
## things that break. Fences and hedges the bake classed S (tools/object_types.py `sc`) are drawn
## as ever but file no collider faces (city_barriers.gd `_is_soft`); this node is what they are to
## the car instead: data, not physics (no second physics layer: a dozen places write the car's
## collision_mask as a literal).
##
## Its data: every loaded sector's soft list (the sector root's "soft" meta, made by the builder
## from the sector file's lines and saved with the prebuilt scene, so both city paths read the same
## list when the sector loads; the whole city's map node with --monolithic), fed by the streamer's
## `sector_ready` (main.gd `_on_sector_ready`) and dropped when the sector's root leaves the tree.
## Segments go into an 8 m cell hash per sector.
##
## Each physics frame, after the car's own step (process_physics_priority), only when the car
## moves faster than MIN_SPEED and its collision_mask is not 0 (the boat, the helicopter and the
## testing autopilots set it to 0): the car's box swept over this frame's motion (the hull of its
## box where it was and where it is) against the segments in the cells it covers, at the car's
## height (a fence under a deck is not hit from the deck). A segment's 2 m panels it overlaps break:
## - crossing: each panel takes Solidity.smash_cost of the speed (fence 6 %, hedge 10 %), at most
##   Solidity.SMASH_CAP within SMASH_CAP_TIME s however many panels go; a broken panel costs
##   nothing again;
## - grinding along (the car's way within GRIND_ANGLE deg of the line): GRIND_COST of the speed a
##   second and a nudge out of the line at GRIND_NUDGE m/s; the panels it touches go down too.
## The cost scales the car's own `vel` (car.gd is not changed: its next step drives on from it).
##
## Out: `broke(id, panel, kind, at, direction, speed)` and `repaired(id, panel)` (main.gd turns
## them into a sound, a light buzz, now and then a bubble, the wallet's counters); one pooled
## GPUParticles3D of debris (bars, boards or leaves), hidden at rest (no draw call); the contact
## log (contact_log.gd `soft_touch`, `contacts`) when one runs. Queries: `is_broken(id, panel)`,
## `repair_near(point, r)` (an activity making its scene whole), `reset()` (a new game).
##
## Memory, rule B (section 5.2): a broken panel is remembered (at most MEMORY entries; over that the
## oldest out of sight is repaired first) and repaired, unseen, once it is more than REPAIR_FAR m
## from the car, out of the camera's view, and REPAIR_AFTER s of play (or a dawn) have passed since
## it broke. Nothing is saved: a new launch starts with a whole city. Version 1 look: the debris
## flies and the fence stays drawn (section 5.5, way 1).
##
## `no_soft` on (main.gd: Settings → Łamliwe płoty off, the default since 2026-11-14, or `--no-soft`):
## nothing is swept, and every loaded sector's soft lines get their colliders back (`harden`: the very
## faces the builder would have filed, city_barriers.gd `slab_faces` / `rail_faces`), so both paths
## collide exactly as before step 7. `set_soft` turns it over live on the sectors already loaded (the
## restored bodies go, or come), so the setting needs no restart.

signal broke(id: String, panel: int, kind: StringName, at: Vector3, direction: Vector3, speed: float)
signal repaired(id: String, panel: int)

const Solidity := preload("res://scripts/solidity.gd")
const CityBarriers := preload("res://scripts/city_barriers.gd")

## The cell hash's cell (m).
const CELL := 8.0
## The sector size (map_builder.gd SECTOR).
const SECTOR := 512.0
## Nothing is swept slower than this (m/s).
const MIN_SPEED := 2.0
## A frame's motion longer than this is a jump (a tow, a teleport): nothing is swept (m).
const JUMP := 4.0
## The car's box, if its shape can't be read: half width, half length (m), and its height band over
## the car's origin (car.gd: a 1.8 x 1.2 x 4.0 box 0.8 m up).
const HALF := Vector2(0.9, 2.0)
const BODY_LOW := 0.2
const BODY_HIGH := 1.4
## A segment is hit at heights from its foot - FOOT_SLACK to its top + TOP_SLACK.
const FOOT_SLACK := 0.5
const TOP_SLACK := 0.3
## Rule B.
const MEMORY := 600
const REPAIR_FAR := 150.0
const REPAIR_AFTER := 600.0
const REPAIR_EVERY := 1.0
## The debris: particles a burst, their life (s), at most one burst this often (s).
const DEBRIS_AMOUNT := 18
const DEBRIS_LIFE := 1.1
const DEBRIS_GAP := 0.08
const DEBRIS_COLOUR := {"metal": Color("#3b3f44"), "wood": Color("#8a6a43"), "hedge": Color("#4d7a35")}

## The player's car (car.gd) this node watches; main.gd swaps it with the vehicle.
var car: CharacterBody3D
## The camera, for rule B's "out of view" (none: everything counts as out of view).
var camera: Camera3D
## Where the player is for rule B (the car, or the helicopter while flying); the car's position
## when not set.
var focus_at := Callable()
## Rule B's "in view" for a point, instead of the camera's frustum (check_soft_things.gd: a headless
## run's camera has no frustum to speak of).
var view_test := Callable()
## contact_log.gd when a run logs contacts (main.gd --contacts, check_lane_drive).
var contacts: RefCounted
## Nothing breaks; loaded sectors get their soft lines' colliders back (set before the first sector,
## then through `set_soft`).
var no_soft := false
## Microseconds spent restoring colliders (`harden`, on the main thread when a sector comes in with
## the fences hard, or at a toggle), for the bench and the check.
var harden_usec := 0
## Microseconds spent in the physics step (the bench's systems table).
var spent_usec := 0
## Panels broken this session, and the sweeps run (frames the car was tested).
var panels_broken := 0
var sweeps := 0

var _clock := 0.0
var _dawns := 0
## Sector key -> {"root", "soft": the soft list, "cells": {Vector2i: PackedInt32Array of segment
## indices}}: the sectors being swept (none while `no_soft`).
var _sectors := {}
## Sector key -> its root, every loaded sector with a soft list (swept or hardened), so `set_soft`
## can turn the ones already loaded over.
var _roots := {}
## Line id -> its material ("metal", "wood", "hedge"), for the sound and the debris.
var _mat_of := {}
## "id#panel" -> [clock, dawns, at, id, panel], oldest first.
var _broken := {}
## The cap's window: [time, share] of each cost taken lately.
var _window: Array[Vector2] = []
var _prev := Transform3D()
var _have_prev := false
var _repair_wait := REPAIR_EVERY
var _debris: GPUParticles3D
var _debris_left := 0.0
var _debris_wait := 0.0


func _ready() -> void:
	# After the car's own step (car.gd runs at the default 0): its motion this frame is done.
	process_physics_priority = 100


## A sector is in (the streamer's sector_ready, twice per sector: once is enough): its soft list
## into the hash; with `no_soft`, its colliders back instead (the runtime builder makes the soft list
## either way; with --no-soft it files them itself with CityBarriers.soft_off and has no list).
func add_sector(root: Node3D) -> void:
	if root == null or not root.has_meta(&"soft"):
		return
	var key := _key_of(root)
	if _roots.has(key) and is_same(_roots[key], root):
		return
	_roots[key] = root
	if not root.tree_exiting.is_connected(_on_root_gone):
		root.tree_exiting.connect(_on_root_gone.bind(root), CONNECT_ONE_SHOT)
	if no_soft:
		_harden_root(key, root)
	else:
		_watch(key, root)


## Step 7's settings row (F 2026-11-14): the fences and hedges break (`on`) or are hard, on every
## sector loaded now and every one that comes in after. Hard: the swept list is dropped, every broken
## panel stands again and the sectors get their colliders back; breakable: those bodies go and the
## sectors are swept again. Returns the sectors turned over.
func set_soft(on: bool) -> int:
	if on == not no_soft:
		return 0
	no_soft = not on
	_have_prev = false
	var n := 0
	for key: Vector2i in _roots.keys():
		var root: Node3D = _roots[key]
		if not is_instance_valid(root):
			_roots.erase(key)
			continue
		if no_soft:
			_harden_root(key, root)
		else:
			soften(root)
			_watch(key, root)
		n += 1
	if no_soft:
		reset()
		_sectors.clear()
	return n


## A sector's soft list into the sweep's hash.
func _watch(key: Vector2i, root: Node3D) -> void:
	var soft: Dictionary = root.get_meta(&"soft")
	_sectors[key] = {"root": root, "soft": soft, "cells": _cells_of(soft)}
	var ids: PackedStringArray = soft["ids"]
	var mats: PackedStringArray = soft["mats"]
	for i in ids.size():
		_mat_of[ids[i]] = mats[i]


## A sector's soft lines hard (once: the root's "soft_hard" meta says it has them).
func _harden_root(key: Vector2i, root: Node3D) -> void:
	_sectors.erase(key)
	if root.has_meta(&"soft_hard"):
		return
	var t0 := Time.get_ticks_usec()
	root.set_meta(&"soft_hard", true)
	harden(root, root.get_meta(&"soft"), Rect2(Vector2(key) * SECTOR, Vector2(SECTOR, SECTOR)) if root.name.begins_with("s_") else Rect2())
	harden_usec += Time.get_ticks_usec() - t0


## The sector's soft list is gone with its root (an unload).
func remove_sector(key: Vector2i) -> void:
	_sectors.erase(key)


func _on_root_gone(root: Node3D) -> void:
	var key := _key_of(root)
	if _sectors.has(key) and is_same(_sectors[key]["root"], root):
		_sectors.erase(key)
	if _roots.has(key) and is_same(_roots[key], root):
		_roots.erase(key)


static func _key_of(root: Node) -> Vector2i:
	var parts := String(root.name).split("_")
	if parts.size() == 3 and parts[0] == "s":
		return Vector2i(int(parts[1]), int(parts[2]))
	return Vector2i(1 << 20, 1 << 20)  # the whole city (--monolithic)


## Each segment the sector owns (`own`) in every 8 m cell its box meets.
static func _cells_of(soft: Dictionary) -> Dictionary:
	var cells := {}
	var segs: PackedFloat64Array = soft["segs"]
	var n := CityBarriers.SOFT_STRIDE
	for s in segs.size() / n:
		var o := s * n
		if segs[o + 10] < 0.5:
			continue
		var r := maxf(segs[o + 7], 0.05)
		var x0 := floori((minf(segs[o + 1], segs[o + 3]) - r) / CELL)
		var x1 := floori((maxf(segs[o + 1], segs[o + 3]) + r) / CELL)
		var z0 := floori((minf(segs[o + 2], segs[o + 4]) - r) / CELL)
		var z1 := floori((maxf(segs[o + 2], segs[o + 4]) + r) / CELL)
		for cz in range(z0, z1 + 1):
			for cx in range(x0, x1 + 1):
				var c := Vector2i(cx, cz)
				# (A packed array read out of a Dictionary is a copy: it goes back in.)
				var list: PackedInt32Array = cells.get(c, PackedInt32Array())
				list.append(s)
				cells[c] = list
	return cells


## A sector with its fences hard: its soft lines' collider faces, one body per class (`Solid_<class>`
## meta, as the builder's own), the faces whose centre lies in `rect` (an empty rect: all of them).
static func harden(root: Node3D, soft: Dictionary, rect: Rect2) -> void:
	var by := hard_faces(soft, rect)
	for cls: StringName in by:
		var body := StaticBody3D.new()
		body.name = "SoftHard_" + String(cls)
		body.set_meta(&"solid", cls)
		var shape := CollisionShape3D.new()
		var concave := ConcavePolygonShape3D.new()
		concave.backface_collision = true
		concave.set_faces(by[cls])
		shape.shape = concave
		body.add_child(shape)
		root.add_child(body)


## `harden` undone: the restored bodies (`SoftHard_<class>`) leave the sector, its soft lines break
## again. Returns the bodies taken out.
static func soften(root: Node3D) -> int:
	var n := 0
	for c in root.get_children():
		if String(c.name).begins_with("SoftHard_"):
			root.remove_child(c)
			c.queue_free()
			n += 1
	root.remove_meta(&"soft_hard")
	return n


## The faces the builder would have filed for the soft list's segments ({class: faces}), cut to the
## faces whose centre lies in `rect` as the sectors' colliders are (an empty rect: all).
static func hard_faces(soft: Dictionary, rect: Rect2) -> Dictionary:
	var out := {}
	var segs: PackedFloat64Array = soft["segs"]
	var kinds: PackedStringArray = soft["kinds"]
	var n := CityBarriers.SOFT_STRIDE
	for s in segs.size() / n:
		var o := s * n
		var a := Vector2(segs[o + 1], segs[o + 2])
		var b := Vector2(segs[o + 3], segs[o + 4])
		var faces := CityBarriers.slab_faces(a, b, segs[o + 7], segs[o + 5], segs[o + 6], segs[o + 8]) if segs[o + 7] > 0.0 \
				else CityBarriers.rail_faces(a, b, segs[o + 5], segs[o + 6], segs[o + 8])
		var cls := StringName(kinds[int(segs[o])])
		var kept: PackedVector3Array = out.get(cls, PackedVector3Array())
		for i in range(0, faces.size() - 2, 3):
			var c := (faces[i] + faces[i + 1] + faces[i + 2]) / 3.0
			if rect.size == Vector2.ZERO or rect.has_point(Vector2(c.x, c.z)):
				kept.append_array([faces[i], faces[i + 1], faces[i + 2]])
		if not kept.is_empty():
			out[cls] = kept
	return out


func _physics_process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	step(dt)
	spent_usec += Time.get_ticks_usec() - t0


## One physics frame (the checks call it themselves).
func step(dt: float) -> void:
	_clock += dt
	_debris_wait -= dt
	if _debris != null and _debris.visible:
		_debris_left -= dt
		if _debris_left <= 0.0:
			_debris.visible = false
			_debris.emitting = false
	_repair_wait -= dt
	if _repair_wait <= 0.0:
		_repair_wait = REPAIR_EVERY
		_repair_tick()
	if car == null or not is_instance_valid(car) or no_soft:
		_have_prev = false
		return
	var xf := car.global_transform
	var v := Vector2(car.vel.x, car.vel.z)
	if not _have_prev or car.collision_mask == 0 or v.length() < MIN_SPEED or _sectors.is_empty() \
			or Vector2(xf.origin.x - _prev.origin.x, xf.origin.z - _prev.origin.z).length() > JUMP:
		_prev = xf
		_have_prev = true
		return
	sweeps += 1
	_sweep(_prev, xf, v, dt)
	_prev = xf


## The car's box (half width, half length) from its CollisionShape3D, else HALF.
func _half() -> Vector2:
	for c in car.get_children():
		var cs := c as CollisionShape3D
		if cs != null and cs.shape is BoxShape3D:
			var size: Vector3 = (cs.shape as BoxShape3D).size
			return Vector2(size.x * 0.5, size.z * 0.5)
	return HALF


## The hull (convex, counter-clockwise) of the car's box at `a` and at `b` on the map (x, z).
static func swept_hull(a: Transform3D, b: Transform3D, half: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for xf in [a, b]:
		var t: Transform3D = xf
		var right := Vector2(t.basis.x.x, t.basis.x.z).normalized() * half.x
		var back := Vector2(t.basis.z.x, t.basis.z.z).normalized() * half.y
		var o := Vector2(t.origin.x, t.origin.z)
		pts.append_array([o + right + back, o + right - back, o - right - back, o - right + back])
	return Geometry2D.convex_hull(pts)


## The part of segment p..q inside convex polygon `hull` (Cyrus-Beck): Vector2(t0, t1) along the
## segment, or Vector2(-1, -1) when it misses.
static func clip(p: Vector2, q: Vector2, hull: PackedVector2Array) -> Vector2:
	var t0 := 0.0
	var t1 := 1.0
	var d := q - p
	var n := hull.size()
	if n < 3:
		return Vector2(-1, -1)
	# The hull's winding decides which side of each edge is in.
	var area := 0.0
	for i in n:
		area += hull[i].cross(hull[(i + 1) % n])
	var w := 1.0 if area > 0.0 else -1.0
	for i in n:
		var e0 := hull[i]
		var e1 := hull[(i + 1) % n]
		var edge := e1 - e0
		# Inward when edge.cross(x - e0) * w >= 0.
		var num := edge.cross(p - e0) * w
		var den := edge.cross(d) * w
		if absf(den) < 1e-9:
			if num < 0.0:
				return Vector2(-1, -1)
			continue
		var t := -num / den
		if den > 0.0:
			t0 = maxf(t0, t)
		else:
			t1 = minf(t1, t)
		if t0 > t1:
			return Vector2(-1, -1)
	return Vector2(t0, t1)


## The share of the speed a cost may take now under the cap (`window`: what was taken lately, as
## [time, share]; trimmed here), and the window with it added.
static func cap_take(window: Array[Vector2], now: float, cost: float) -> float:
	while not window.is_empty() and now - window[0].x > Solidity.SMASH_CAP_TIME:
		window.pop_front()
	var used := 0.0
	for e in window:
		used += e.y
	var take := clampf(cost, 0.0, maxf(Solidity.SMASH_CAP - used, 0.0))
	if take > 0.0:
		window.append(Vector2(now, take))
	return take


func _sweep(from: Transform3D, to: Transform3D, v: Vector2, dt: float) -> void:
	var hull := swept_hull(from, to, _half())
	var lo := hull[0]
	var hi := hull[0]
	for q in hull:
		lo = lo.min(q)
		hi = hi.max(q)
	var y := to.origin.y
	var speed := v.length()
	var way := v / speed
	var keep := 1.0
	var grind := false
	var nudge := Vector2.ZERO
	var touched := ""
	var touched_at := Vector3.ZERO
	var touched_n := 0
	var angle_seen := 0.0
	var own := Vector2i(floori(to.origin.x / SECTOR), floori(to.origin.z / SECTOR))
	var c0 := Vector2i(floori(lo.x / CELL), floori(lo.y / CELL))
	var c1 := Vector2i(floori(hi.x / CELL), floori(hi.y / CELL))
	var seen := {}
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var sec: Variant = _sectors.get(own + Vector2i(dx, dz))
			if sec == null:
				continue
			var cells: Dictionary = sec["cells"]
			var soft: Dictionary = sec["soft"]
			var segs: PackedFloat64Array = soft["segs"]
			for cz in range(c0.y, c1.y + 1):
				for cx in range(c0.x, c1.x + 1):
					var list: Variant = cells.get(Vector2i(cx, cz))
					if list == null:
						continue
					for s: int in list:
						var tag := Vector2i(dx * 3 + dz, s)
						if seen.has(tag):
							continue
						seen[tag] = true
						var o := s * CityBarriers.SOFT_STRIDE
						var a := Vector2(segs[o + 1], segs[o + 2])
						var b := Vector2(segs[o + 3], segs[o + 4])
						var hit := clip(a, b, hull)
						if hit.x < 0.0:
							continue
						var tm := (hit.x + hit.y) * 0.5
						var foot := lerpf(segs[o + 5], segs[o + 6], tm)
						if y + BODY_LOW > foot + segs[o + 8] + TOP_SLACK or y + BODY_HIGH < foot - FOOT_SLACK:
							continue
						var line := int(segs[o])
						var id := String((soft["ids"] as PackedStringArray)[line])
						var kind := StringName((soft["kinds"] as PackedStringArray)[line])
						var length := a.distance_to(b)
						var dir := (b - a) / maxf(length, 0.001)
						var along := absf(way.dot(dir))
						var is_grind := along > cos(deg_to_rad(Solidity.GRIND_ANGLE))
						var p0 := floori((segs[o + 9] + hit.x * length) / CityBarriers.PANEL)
						var p1 := floori((segs[o + 9] + hit.y * length) / CityBarriers.PANEL)
						p1 = mini(p1, int((soft["panels"] as PackedInt32Array)[line]) - 1)
						if is_grind:
							grind = true
							var side := Vector2(-dir.y, dir.x)
							var mid := a.lerp(b, tm)
							if side.dot(Vector2(to.origin.x, to.origin.z) - mid) < 0.0:
								side = -side
							nudge = side
						for panel in range(p0, p1 + 1):
							var key := "%s#%d" % [id, panel]
							if _broken.has(key):
								continue
							var t := clampf(((panel + 0.5) * CityBarriers.PANEL - segs[o + 9]) / maxf(length, 0.001), 0.0, 1.0)
							var at2 := a.lerp(b, t)
							var at := Vector3(at2.x, lerpf(segs[o + 5], segs[o + 6], t), at2.y)
							if not is_grind:
								keep *= 1.0 - cap_take(_window, _clock, Solidity.smash_cost(kind))
							_remember(key, id, panel, at)
							panels_broken += 1
							touched = String(kind)
							touched_at = at
							touched_n += 1
							angle_seen = rad_to_deg(acos(clampf(along, 0.0, 1.0)))
							_burst(at, Vector3(way.x, 0.0, way.y), String(_mat_of.get(id, "metal")))
							broke.emit(id, panel, kind, at, Vector3(way.x, 0.0, way.y), speed)
	if grind:
		keep *= 1.0 - cap_take(_window, _clock, Solidity.GRIND_COST * dt)
	# WORKAROUND(arch): the smash's cost and the grind's nudge are written into the car's `vel` from
	# here, because car.gd (the controls lane) was not to change in step 7; see TD-24.
	if keep < 1.0:
		car.vel *= keep
	if grind and nudge != Vector2.ZERO:
		var out := Vector2(car.vel.x, car.vel.z).dot(nudge)
		if out < Solidity.GRIND_NUDGE:
			car.vel += Vector3(nudge.x, 0.0, nudge.y) * (Solidity.GRIND_NUDGE - out)
	if touched != "" and contacts != null and contacts.has_method("soft_touch"):
		contacts.soft_touch(touched, touched_at, angle_seen, touched_n)


func _remember(key: String, id: String, panel: int, at: Vector3) -> void:
	if _broken.size() >= MEMORY:
		_evict()
	_broken[key] = [_clock, _dawns, at, id, panel]


## Over MEMORY: the oldest entry out of sight goes (the oldest of all when everything is in view).
func _evict() -> void:
	for key: String in _broken:
		if not _in_view(_broken[key][2]):
			_repair(key)
			return
	for key: String in _broken:
		_repair(key)
		return


func _repair(key: String) -> void:
	var e: Array = _broken[key]
	_broken.erase(key)
	repaired.emit(String(e[3]), int(e[4]))


func _in_view(at: Vector3) -> bool:
	if view_test.is_valid():
		return view_test.call(at)
	return camera != null and is_instance_valid(camera) and camera.is_inside_tree() and camera.is_position_in_frustum(at + Vector3(0, 1.0, 0))


func _player_at() -> Vector3:
	if focus_at.is_valid():
		return focus_at.call()
	return car.global_position if car != null and is_instance_valid(car) else Vector3.INF


## Rule B, once a REPAIR_EVERY s: every entry far, out of view and old enough (or a dawn ago) goes.
func _repair_tick() -> void:
	if _broken.is_empty():
		return
	var me := _player_at()
	for key: String in _broken.keys():
		var e: Array = _broken[key]
		var old := _clock - float(e[0]) >= REPAIR_AFTER or _dawns > int(e[1])
		if not old:
			continue
		var at: Vector3 = e[2]
		if me != Vector3.INF and Vector2(at.x - me.x, at.z - me.z).length() <= REPAIR_FAR:
			continue
		if _in_view(at):
			continue
		_repair(key)


## A dawn passed (time_of_day.gd's lights going off): everything broken before it may be repaired.
func on_dawn() -> void:
	_dawns += 1


## Whether panel `panel` of line `id` is down (the look thread rebuilding a sector while it lives).
func is_broken(id: String, panel: int) -> bool:
	return _broken.has("%s#%d" % [id, panel])


## Every broken panel within `r` m of `point` stands again (an activity making its scene whole).
func repair_near(point: Vector3, r: float) -> int:
	var n := 0
	for key: String in _broken.keys():
		var at: Vector3 = _broken[key][2]
		if Vector2(at.x - point.x, at.z - point.z).length() <= r:
			_repair(key)
			n += 1
	return n


## A new game (or Continue): the city whole again, the clock and the cap from zero.
func reset() -> void:
	for key: String in _broken.keys():
		_repair(key)
	_window.clear()
	_have_prev = false


## The car was put somewhere new (a tow, a new route's car): its next frame sweeps nothing.
func reset_motion() -> void:
	_have_prev = false


## How many panels are down now.
func broken_count() -> int:
	return _broken.size()


## The material of line `id` ("metal", "wood", "hedge"), for its sound.
func material_of(id: String) -> String:
	return String(_mat_of.get(id, "metal"))


## Seconds of play this node has counted (rule B's clock).
func clock() -> float:
	return _clock


## The segments loaded now (the check and the bench).
func segment_count() -> int:
	var n := 0
	for k: Vector2i in _sectors:
		n += (_sectors[k]["soft"]["segs"] as PackedFloat64Array).size() / CityBarriers.SOFT_STRIDE
	return n


## One burst of debris at `at`, thrown along `dir` (one pooled GPUParticles3D: made on the first
## burst, hidden again when its particles are gone, so the city at rest draws nothing more).
func _burst(at: Vector3, dir: Vector3, mat: String) -> void:
	if _debris_wait > 0.0 or not is_inside_tree():
		return
	_debris_wait = DEBRIS_GAP
	if _debris == null:
		_debris = _make_debris()
		add_child(_debris)
	var pm := _debris.process_material as ParticleProcessMaterial
	pm.color = DEBRIS_COLOUR.get(mat, DEBRIS_COLOUR["metal"])
	pm.direction = (dir + Vector3(0, 0.9, 0)).normalized()
	_debris.global_position = at + Vector3(0, 0.6, 0)
	_debris.visible = true
	_debris.restart()
	_debris.emitting = true
	_debris_left = DEBRIS_LIFE + 0.2


static func _make_debris() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "SmashDebris"
	p.amount = DEBRIS_AMOUNT
	p.lifetime = DEBRIS_LIFE
	p.one_shot = true
	p.explosiveness = 0.92
	p.emitting = false
	p.visible = false
	p.visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 8, 16))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.spread = 55.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 7.0
	pm.gravity = Vector3(0, -12.0, 0)
	pm.angular_velocity_min = -360.0
	pm.angular_velocity_max = 360.0
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.9, 0.4, 0.2)
	p.process_material = pm
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.06, 0.42, 0.04)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	mesh.material = m
	p.draw_pass_1 = mesh
	return p
