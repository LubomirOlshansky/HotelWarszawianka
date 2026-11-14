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
##
## Step 8a (drivable-city-build.md item 4): the parked cars are pushed. The builder files no collider
## faces for them; their boxes are the sector root's "soft_cars" meta (map_builder.gd `soft_cars_data`,
## saved with the prebuilt scene) in an 8 m cell hash of their bays. Each physics frame the car's box
## where it is and where this frame's speed takes it next is tested against them (a frame early, so a
## car that cannot move is a wall before the player is inside it):
## - a push: the player keeps Solidity.push_keep of the speed (a quarter lost square on, almost nothing
##   brushing along), its speed along the face's normal falling to PUSH_SHARE of what it was (the rest
##   turned along the face); the parked car takes that PUSH_SHARE along the normal and a small spin,
##   and slides with PUSH_FRICTION to a stop. One `cast_motion` of its box at the hit (and one for the
##   car it would meet) clamps the slide at a wall; a car it slides into is pushed on in turn (a chain,
##   PUSH_SHARE of its speed); a player still pushing carries it along (the speeds shared);
## - wedged (the slide clamped under PUSH_WEDGED m: a wall, a car that cannot move): a box collider of
##   class `parked` stands there while the player is near, so car.gd answers it as any wall, with the
##   preset's own rules (collide_rules.gd);
## - rest never in a lane corridor (the lane graph's lanes, `graph`): the slide is lengthened or
##   shortened to the nearest free spot; with none the car is `towed`, hidden once out of view.
## A pushed car is remembered like a broken panel (key: its id) and goes back to its bay by rule B; its
## MultiMesh instance follows it (the tile's MultiMeshInstance3D carries map_builder.PARKED_TILE), and
## is put back when its sector unloads. `no_soft` hardens the cars too (their faces as the builder
## files them, map_builder.gd `parked_faces`): one switch for every soft thing.
## Out: `pushed(id, at, dir, speed)` (main.gd: the knock, the counter, a bubble) and `car_returned(id)`.

signal broke(id: String, panel: int, kind: StringName, at: Vector3, direction: Vector3, speed: float)
signal repaired(id: String, panel: int)
## Step 8a: a parked car was pushed (`at` where, `dir` the way it slides, `speed` the player's going in),
## and one went back to its bay (rule B).
signal pushed(id: String, at: Vector3, dir: Vector3, speed: float)
signal car_returned(id: String)

const Solidity := preload("res://scripts/solidity.gd")
const CityBarriers := preload("res://scripts/city_barriers.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")

## The cell hash's cell (m).
const CELL := 8.0
## The sector size (map_builder.gd SECTOR), and the key of the whole city's map node (--monolithic).
const SECTOR := 512.0
const WHOLE := Vector2i(1 << 20, 1 << 20)
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
## Step 8a, the parked cars: half width and half length of the box (map_builder.gd PARKED_FOOT) and its
## height; nothing is pushed slower than CAR_MIN_SPEED (m/s: a creep still moves it, a little), nor by
## less than PUSH_INTO m/s into its face (a brush); the lane rule looks for a free rest in REST_STEP m
## steps, braking at most / least this hard to stop there (m/s²); a wedged car's collider stays while
## the player is within HARD_NEAR m; the cast reaches CAST_SPARE m past the friction stop (room for a
## player who keeps pushing); a push is one contact while touches come within TOUCH_GAP s.
const CAR_HALF := Vector2(0.9, 2.1)
const CAR_HIGH := 1.5
const CAR_MIN_SPEED := 0.3
const PUSH_INTO := 0.2
const REST_STEP := 0.25
const REST_BRAKE_MOST := 18.0
const REST_BRAKE_LEAST := 2.0
const HARD_NEAR := 9.0
const CAST_SPARE := 2.0
const TOUCH_GAP := 0.3
## A parked car's states: in its bay, sliding, at rest off its bay, towed (it would have rested in a
## lane: hidden once out of view, back in its bay by rule B).
enum { BAY, SLIDING, MOVED, TOWED }

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
## Step 8a: the lane graph (lane_graph.gd) for the slide's lane rule; none: a car may rest anywhere.
var graph: RefCounted
## Step 8a: this session's pushes, wedged hits, chain pushes (a sliding car into another), cars towed,
## casts made, and cars back in their bays.
var pushes := 0
var wedges := 0
var chains := 0
var towed := 0
var casts := 0
var returns := 0


## Step 8a: one parked car: its bay from the map, where it is now, its slide.
class Parked:
	var id := ""
	var bay := Transform3D()
	var xf := Transform3D()
	var root: Node3D
	var tile := Vector2i.ZERO
	var slot := -1
	var state := 0
	## The slide: its way, speed (m/s), braking (m/s²), metres gone, the most it may go (the cast),
	## where it comes to rest (the lane rule; -1 none yet), its spin (rad/s) at speed0.
	var dir := Vector2.ZERO
	var speed := 0.0
	var brake := 6.0
	var gone := 0.0
	var limit := INF
	var target := -1.0
	var spin := 0.0
	var speed0 := 0.0
	var in_lane := false
	var touched := -INF
	var hidden := false
	var hard: StaticBody3D

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
## Step 8a: sector key -> {"root", "cars": Array of Parked (its own), "cells": {Vector2i:
## PackedInt32Array of indices into cars}} (none while `no_soft`); id -> Parked for every loaded own
## car; the cars off their bays and the ones sliding; id -> [rest transform, towed] for a pushed car
## whose sector left (put back where it lay when the sector comes in again).
var _car_sectors := {}
var _car_of := {}
var _off_bay: Array = []
var _sliding: Array = []
var _car_rest := {}


func _ready() -> void:
	# After the car's own step (car.gd runs at the default 0): its motion this frame is done.
	process_physics_priority = 100


## A sector is in (the streamer's sector_ready, twice per sector: once is enough): its soft list
## into the hash; with `no_soft`, its colliders back instead (the runtime builder makes the soft list
## either way; with --no-soft it files them itself with CityBarriers.soft_off and has no list).
func add_sector(root: Node3D) -> void:
	if root == null or not (root.has_meta(&"soft") or root.has_meta(&"soft_cars")):
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


## A sector's soft list into the sweep's hash (step 8a: and its parked cars into theirs).
func _watch(key: Vector2i, root: Node3D) -> void:
	if root.has_meta(&"soft_cars"):
		_watch_cars(key, root)
	if not root.has_meta(&"soft"):
		return
	var soft: Dictionary = root.get_meta(&"soft")
	_sectors[key] = {"root": root, "soft": soft, "cells": _cells_of(soft)}
	var ids: PackedStringArray = soft["ids"]
	var mats: PackedStringArray = soft["mats"]
	for i in ids.size():
		_mat_of[ids[i]] = mats[i]


## A sector's soft lines hard (once: the root's "soft_hard" meta says it has them).
func _harden_root(key: Vector2i, root: Node3D) -> void:
	_sectors.erase(key)
	_unwatch_cars(key, false)  # hard in their bays: the pushed ones go back first
	if root.has_meta(&"soft_hard"):
		return
	var t0 := Time.get_ticks_usec()
	root.set_meta(&"soft_hard", true)
	harden(root, root.get_meta(&"soft", {}), Rect2(Vector2(key) * SECTOR, Vector2(SECTOR, SECTOR)) if root.name.begins_with("s_") else Rect2(),
			root.get_meta(&"soft_cars", {}))
	harden_usec += Time.get_ticks_usec() - t0


## The sector's soft list is gone with its root (an unload).
func remove_sector(key: Vector2i) -> void:
	_sectors.erase(key)
	_unwatch_cars(key)


func _on_root_gone(root: Node3D) -> void:
	var key := _key_of(root)
	if _sectors.has(key) and is_same(_sectors[key]["root"], root):
		_sectors.erase(key)
	if _car_sectors.has(key) and is_same(_car_sectors[key]["root"], root):
		_unwatch_cars(key)
	if _roots.has(key) and is_same(_roots[key], root):
		_roots.erase(key)


static func _key_of(root: Node) -> Vector2i:
	var parts := String(root.name).split("_")
	if parts.size() == 3 and parts[0] == "s":
		return Vector2i(int(parts[1]), int(parts[2]))
	return WHOLE  # the whole city (--monolithic)


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
## meta, as the builder's own), the faces whose centre lies in `rect` (an empty rect: all of them);
## step 8a: and its parked cars' (`cars`, the root's "soft_cars" meta) under `parked`.
static func harden(root: Node3D, soft: Dictionary, rect: Rect2, cars := {}) -> void:
	var by := hard_faces(soft, rect) if not soft.is_empty() else {}
	var parked := car_faces(cars, rect)
	if not parked.is_empty():
		by[&"parked"] = parked
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


## Step 8a: the faces the builder files for the parked cars of `cars` (a root's "soft_cars" meta) with
## --no-soft, at their bays, cut to the faces whose centre lies in `rect` (an empty rect: all).
static func car_faces(cars: Dictionary, rect: Rect2) -> PackedVector3Array:
	var out := PackedVector3Array()
	if cars.is_empty():
		return out
	var list: PackedFloat64Array = cars["cars"]
	for o in range(0, list.size(), MapBuilder.CAR_STRIDE):
		var faces := MapBuilder.parked_faces(bay_of(list, o))
		for i in range(0, faces.size() - 2, 3):
			var c := (faces[i] + faces[i + 1] + faces[i + 2]) / 3.0
			if rect.size == Vector2.ZERO or rect.has_point(Vector2(c.x, c.z)):
				out.append_array([faces[i], faces[i + 1], faces[i + 2]])
	return out


## Step 8a: the bay of the parked car at `o` in a "soft_cars" list (the builder's very transform).
static func bay_of(list: PackedFloat64Array, o: int) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, list[o + 2]), Vector3(list[o], list[o + 3], list[o + 1]))


## Step 8a: a parked car's stable id, from its bay (the same on both paths and in every sector).
static func car_id(x: float, z: float) -> String:
	return "parked:%.1f:%.1f" % [x, z]


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
	if not _sliding.is_empty():
		_slide_cars(dt)
	if car == null or not is_instance_valid(car) or no_soft:
		_have_prev = false
		return
	var xf := car.global_transform
	var v := Vector2(car.vel.x, car.vel.z)
	_drop_far_walls(xf.origin)
	var jumped := _have_prev and Vector2(xf.origin.x - _prev.origin.x, xf.origin.z - _prev.origin.z).length() > JUMP
	# Step 8a: the parked cars, where the car will be next frame (a creep still pushes).
	if _have_prev and not jumped and car.collision_mask != 0 and v.length() >= CAR_MIN_SPEED and not _car_sectors.is_empty():
		_push_test(xf, v, dt)
		v = Vector2(car.vel.x, car.vel.z)
	if not _have_prev or car.collision_mask == 0 or v.length() < MIN_SPEED or _sectors.is_empty() or jumped:
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
	if int(e[4]) < 0:
		_return_car(String(e[3]))  # step 8a: a pushed car back in its bay
		return
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
	# Step 8a: a towed car (it would have rested in a lane) goes once out of view, as if the tow took it.
	for p: Parked in _off_bay:
		if p.state == TOWED and not p.hidden and not _in_view(p.xf.origin):
			p.hidden = true
			_show(p)
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
	_car_rest.clear()
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


# --- step 8a: the parked cars -------------------------------------------------------------------

## The ground under a point for a sliding car (main.gd: the map's terrain_height); none: the bay's.
var ground_at := Callable()
## The cars with a wall standing (wedged), so the walls far from the player can go.
var _walls: Array = []


## A sector's parked cars into their hash: the ones it owns (its spot in it, drawn by its tile's
## MultiMesh), each in its bay or, pushed before the sector left, where it was left lying.
func _watch_cars(key: Vector2i, root: Node3D) -> void:
	_unwatch_cars(key)
	var list: PackedFloat64Array = (root.get_meta(&"soft_cars") as Dictionary)["cars"]
	var cars: Array = []
	var cells := {}
	for o in range(0, list.size(), MapBuilder.CAR_STRIDE):
		if list[o + 4] < 0.5:
			continue  # another sector's car whose collider reached in: that sector pushes it
		var p := Parked.new()
		p.bay = bay_of(list, o)
		p.xf = p.bay
		p.id = car_id(list[o], list[o + 1])
		p.root = root
		p.tile = Vector2i(int(list[o + 5]), int(list[o + 6]))
		p.slot = int(list[o + 7])
		var c := Vector2i(floori(list[o] / CELL), floori(list[o + 1] / CELL))
		var l: PackedInt32Array = cells.get(c, PackedInt32Array())
		l.append(cars.size())
		cells[c] = l
		cars.append(p)
		_car_of[p.id] = p
		if _car_rest.has(p.id):
			var rest: Array = _car_rest[p.id]
			_car_rest.erase(p.id)
			p.xf = rest[0]
			p.state = TOWED if bool(rest[1]) else MOVED
			p.hidden = p.state == TOWED
			_off_bay.append(p)
			_show(p)
	_car_sectors[key] = {"root": root, "cars": cars, "cells": cells}


## A sector's cars out of the hash (it left, or its cars are hard now). A pushed car's instance goes
## back to its bay (its MultiMesh may be cached and loaded again); `keep` remembers where it lay (the
## sector unloads), else it is forgotten (its cars are hard in their bays now).
func _unwatch_cars(key: Vector2i, keep := true) -> void:
	var sec: Variant = _car_sectors.get(key)
	if sec == null:
		return
	_car_sectors.erase(key)
	for p: Parked in sec["cars"]:
		_car_of.erase(p.id)
		_drop_wall(p)
		if p.state == BAY:
			continue
		if keep:
			_car_rest[p.id] = [p.xf, p.state == TOWED]
		else:
			_broken.erase(p.id)
		p.xf = p.bay
		p.hidden = false
		p.state = BAY
		_show(p)
		_off_bay.erase(p)
		_sliding.erase(p)


## The instance of `p` where the car is now (hidden: shrunk to nothing under the ground).
func _show(p: Parked) -> void:
	if p.slot < 0 or p.root == null or not is_instance_valid(p.root):
		return
	var mm := _multimesh(p)
	if mm == null or p.slot >= mm.instance_count:
		return
	if p.hidden:
		mm.set_instance_transform(p.slot, Transform3D(Basis.from_scale(Vector3(0.001, 0.001, 0.001)), p.bay.origin - Vector3(0, 20.0, 0)))
	else:
		mm.set_instance_transform(p.slot, p.xf)


## The MultiMesh drawing `p` (its tile's, under its sector root; null when there is none).
func _multimesh(p: Parked) -> MultiMesh:
	for c in p.root.get_children():
		var mmi := c as MultiMeshInstance3D
		if mmi != null and mmi.get_meta(MapBuilder.PARKED_TILE, Vector2i(1 << 30, 0)) == p.tile:
			return mmi.multimesh
	return null


## A car's box on the map (x, z), counter-clockwise from its back right, as swept_hull's corners.
static func box_of(xf: Transform3D, half: Vector2) -> PackedVector2Array:
	var right := Vector2(xf.basis.x.x, xf.basis.x.z).normalized() * half.x
	var back := Vector2(xf.basis.z.x, xf.basis.z.z).normalized() * half.y
	var o := Vector2(xf.origin.x, xf.origin.z)
	return PackedVector2Array([o + right + back, o + right - back, o - right - back, o - right + back])


## Whether convex polygons `a` and `b` overlap (separating axes).
static func polys_meet(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	for poly: PackedVector2Array in [a, b]:
		var n := poly.size()
		for i in n:
			var e := poly[(i + 1) % n] - poly[i]
			var axis := Vector2(-e.y, e.x)
			var a0 := INF
			var a1 := -INF
			var b0 := INF
			var b1 := -INF
			for q in a:
				var d := q.dot(axis)
				a0 = minf(a0, d)
				a1 = maxf(a1, d)
			for q in b:
				var d := q.dot(axis)
				b0 = minf(b0, d)
				b1 = maxf(b1, d)
			if a1 < b0 or b1 < a0:
				return false
	return true


## The outward normal of the face of the parked car at `xf` that a body centred at `at` meets (on the
## map): a side when `at` lies further out past the side than past an end, else an end.
static func face_normal(xf: Transform3D, at: Vector2) -> Vector2:
	var right := Vector2(xf.basis.x.x, xf.basis.x.z).normalized()
	var back := Vector2(xf.basis.z.x, xf.basis.z.z).normalized()
	var rel := at - Vector2(xf.origin.x, xf.origin.z)
	var u := rel.dot(right)
	var w := rel.dot(back)
	if absf(u) - CAR_HALF.x > absf(w) - CAR_HALF.y:
		return right * (1.0 if u >= 0.0 else -1.0)
	return back * (1.0 if w >= 0.0 else -1.0)


## The player's answer to a push (pure, for the check): its new velocity on the map after meeting a face
## with outward normal `n` at velocity `v`, `offset` along the face (which way a square hit turns off):
## Solidity.push_keep of the speed, PUSH_SHARE of the part into the face left going on into it (the
## parked car moves as fast that way), the rest turned along the face.
static func push_answer(v: Vector2, n: Vector2, offset: float) -> Vector2:
	var speed := v.length()
	var into := -v.dot(n)
	if speed < 0.001 or into <= 0.0:
		return v
	var t := Vector2(-n.y, n.x)
	var total := Solidity.push_keep(into / speed) * speed
	var on := into * Solidity.PUSH_SHARE
	var along := v.dot(t)
	var side := signf(along) if absf(along) > 0.05 else (1.0 if offset >= 0.0 else -1.0)
	return -n * on + t * side * sqrt(maxf(total * total - on * on, 0.0))


## Every parked car that may meet a box within `lo`..`hi` (the bays in the cells round it, in this
## sector and its neighbours, or the whole city's) and every car off its bay, not hidden.
func _cars_near(lo: Vector2, hi: Vector2, at: Vector3) -> Array:
	var out: Array = []
	var c0 := Vector2i(floori((lo.x - CAR_HALF.y) / CELL), floori((lo.y - CAR_HALF.y) / CELL))
	var c1 := Vector2i(floori((hi.x + CAR_HALF.y) / CELL), floori((hi.y + CAR_HALF.y) / CELL))
	var own := Vector2i(floori(at.x / SECTOR), floori(at.z / SECTOR))
	var keys: Array[Vector2i] = [WHOLE]  # the whole city's (--monolithic)
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			keys.append(own + Vector2i(dx, dz))
	for k in keys:
		var sec: Variant = _car_sectors.get(k)
		if sec == null:
			continue
		var cells: Dictionary = sec["cells"]
		var cars: Array = sec["cars"]
		for cz in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var list: Variant = cells.get(Vector2i(cx, cz))
				if list == null:
					continue
				for i: int in list:
					var p: Parked = cars[i]
					if p.state == BAY:
						out.append(p)
	for p: Parked in _off_bay:
		if not p.hidden:
			out.append(p)
	return out


## The player's car against the parked cars: its box now and where this frame's speed takes it.
func _push_test(xf: Transform3D, v: Vector2, dt: float) -> void:
	var ahead := xf
	ahead.origin += Vector3(v.x, 0.0, v.y) * dt
	var hull := swept_hull(xf, ahead, _half())
	var lo := hull[0]
	var hi := hull[0]
	for q in hull:
		lo = lo.min(q)
		hi = hi.max(q)
	var y := xf.origin.y
	for p: Parked in _cars_near(lo, hi, xf.origin):
		var py := p.xf.origin.y
		if y + BODY_LOW > py + CAR_HIGH + TOP_SLACK or y + BODY_HIGH < py - FOOT_SLACK:
			continue  # another level (a deck over it, a car park under)
		if not polys_meet(hull, box_of(p.xf, CAR_HALF)):
			continue
		_hit(p, xf, Vector2(car.vel.x, car.vel.z))


## The player meets parked car `p` (next frame): a wall stands (car.gd answers it), it is carried on
## (still in touch), wedged (a wall from now on), or pushed.
func _hit(p: Parked, xf: Transform3D, v: Vector2) -> void:
	if p.hard != null:
		p.touched = _clock
		return
	if p.state == TOWED and p.hidden:
		return
	var me := Vector2(xf.origin.x, xf.origin.z)
	if _clock - p.touched <= TOUCH_GAP and p.state != BAY:
		p.touched = _clock
		_carry(p, v)
		return
	var n := face_normal(p.xf, me)
	var into := -v.dot(n)
	if into < PUSH_INTO:
		return  # brushing along it, or going away
	p.touched = _clock
	var speed := v.length()
	var d := -n
	var give := into * Solidity.PUSH_SHARE
	if _room(p, d, cast_reach(give)) < Solidity.PUSH_WEDGED:
		_wall(p)
		wedges += 1
		return
	var t := Vector2(-n.y, n.x)
	var c := Vector2(p.xf.origin.x, p.xf.origin.z)
	var offset := (me - c).dot(t)
	# WORKAROUND(arch): the push's answer is written into the car's `vel` from here, as step 7's smash
	# cost is, because car.gd (the controls lane) is not to change; see TD-24.
	var nv := push_answer(v, n, offset)
	car.vel = Vector3(nv.x, car.vel.y, nv.y)
	var side_face := absf(n.dot(Vector2(p.xf.basis.x.x, p.xf.basis.x.z).normalized())) > 0.7
	var half_t := CAR_HALF.y if side_face else CAR_HALF.x
	var at := Vector3(c.x + n.x * (CAR_HALF.x if side_face else CAR_HALF.y), p.xf.origin.y + 0.7, c.y + n.y * (CAR_HALF.x if side_face else CAR_HALF.y))
	at += Vector3(t.x, 0.0, t.y) * clampf(offset, -half_t, half_t)
	_start_slide(p, d, give, clampf(offset / half_t, -1.0, 1.0))
	pushes += 1
	_remember(p.id, p.id, -1, p.xf.origin)
	pushed.emit(p.id, at, Vector3(d.x, 0.0, d.y), speed)
	if contacts != null and contacts.has_method("soft_touch"):
		contacts.soft_touch("parked", at, rad_to_deg(asin(clampf(into / maxf(speed, 0.001), 0.0, 1.0))), 1)


## How far a push at `speed` m/s may take a car (m): past the friction stop by CAST_SPARE (a player who
## keeps pushing), and as far as the lane rule may lengthen the slide (braking REST_BRAKE_LEAST).
static func cast_reach(speed: float) -> float:
	return maxf(Solidity.push_slide(speed) + CAST_SPARE, speed * speed / (2.0 * REST_BRAKE_LEAST))


## How far parked car `p` can slide along `d` (up to `want` m): one cast of its box against the
## colliders, then the first parked car in its way, which moves on only as far as its own cast allows
## (a car behind that one stands for a wall). Leaves the cast's clamp in `p.limit`.
func _room(p: Parked, d: Vector2, want: float) -> float:
	p.limit = _cast(p.xf, d, want)
	var way := _car_in_way(p, p.xf, d, p.limit)
	if way.is_empty():
		return p.limit
	var q: Parked = way[0]
	var gap: float = way[1]
	if q.hard != null:
		return gap
	var q_limit := _cast(q.xf, d, maxf(want - gap, 0.0))
	var beyond := _car_in_way(q, q.xf, d, q_limit)
	if not beyond.is_empty():
		q_limit = float(beyond[1])
	return minf(p.limit, gap + q_limit)


## The free distance (m, at most `want`) for a parked car's box at `xf` moved along `d`: one
## cast_motion against the colliders (a hair narrower than the car, so a bay touching a wall still
## moves away from it; never the player's car).
func _cast(xf: Transform3D, d: Vector2, want: float) -> float:
	if want <= 0.0:
		return 0.0
	casts += 1
	var space := _space()
	if space == null:
		return want
	var box := BoxShape3D.new()
	box.size = Vector3(CAR_HALF.x * 2.0 - 0.2, CAR_HIGH - 0.4, CAR_HALF.y * 2.0 - 0.2)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = box
	q.transform = Transform3D(xf.basis, xf.origin + Vector3(0, 0.3 + box.size.y * 0.5, 0))
	q.motion = Vector3(d.x, 0.0, d.y) * want
	q.collision_mask = 1
	if car != null and is_instance_valid(car):
		q.exclude = [car.get_rid()]
	var r := space.cast_motion(q)
	if r.size() < 2:
		return want
	return want * float(r[0])


func _space() -> PhysicsDirectSpaceState3D:
	if not is_inside_tree():
		return null
	var w := get_viewport().find_world_3d()
	return w.direct_space_state if w != null else null


## The first parked car (not `p`) that `p`'s box at `xf` meets moving along `d` within `upto` m, in
## REST_STEP m steps, and the metres it can go before: [car, gap] or []. A car it already overlaps
## (two bays drawn into each other) is no obstacle.
func _car_in_way(p: Parked, xf: Transform3D, d: Vector2, upto: float) -> Array:
	var from := Vector2(xf.origin.x, xf.origin.z)
	var to := from + d * upto
	var near := _cars_near(from.min(to), from.max(to), xf.origin)
	var box0 := box_of(xf, CAR_HALF)
	var cands: Array = []
	for q: Parked in near:
		if q != p and absf(q.xf.origin.y - xf.origin.y) < CAR_HIGH and not polys_meet(box0, box_of(q.xf, CAR_HALF)):
			cands.append(q)
	if cands.is_empty():
		return []
	var s := REST_STEP
	var last := 0.0
	while true:
		var go := minf(s, upto)
		var moved := xf
		moved.origin += Vector3(d.x, 0.0, d.y) * go
		var box := box_of(moved, CAR_HALF)
		for q: Parked in cands:
			if polys_meet(box, box_of(q.xf, CAR_HALF)):
				return [q, last]
		last = go
		if go >= upto:
			break
		s += REST_STEP
	return []


## Parked car `p` starts sliding along `d` at `speed` m/s, spinning by `lever` (-1..1: where along the
## face it was hit), toward a rest the lane rule allows.
func _start_slide(p: Parked, d: Vector2, speed: float, lever: float) -> void:
	if p.state == BAY:
		_off_bay.append(p)
	if not _sliding.has(p):
		_sliding.append(p)
	p.state = SLIDING
	p.dir = d
	p.speed = speed
	p.speed0 = speed
	p.gone = 0.0
	p.spin = clampf(-Solidity.PUSH_SPIN * speed * lever, -Solidity.PUSH_SPIN_MOST, Solidity.PUSH_SPIN_MOST)
	p.hidden = false
	_plan_rest(p)


## The player still touching `p` and closing on it: the speeds along its way shared (it is carried
## on); at its clamp it is wedged from now on.
func _carry(p: Parked, v: Vector2) -> void:
	var going := p.speed if p.state == SLIDING else 0.0
	var w := v.dot(p.dir) - going
	if w <= 0.0:
		return
	if p.gone >= p.limit - 0.05:
		_wall(p)
		wedges += 1
		return
	# WORKAROUND(arch): as in _hit (TD-24).
	car.vel -= Vector3(p.dir.x, 0.0, p.dir.y) * w * 0.5
	if p.state != SLIDING:
		if not _sliding.has(p):
			_sliding.append(p)
		p.state = SLIDING
		p.speed0 = maxf(p.speed0, 0.1)
	p.speed = going + w * 0.5
	_plan_rest(p)


## A wall where `p` stands (a box collider of class `parked`), until the player is HARD_NEAR m away.
func _wall(p: Parked) -> void:
	if p.hard != null:
		return
	var body := StaticBody3D.new()
	body.name = "WedgedCar"
	body.set_meta(&"solid", &"parked")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(CAR_HALF.x * 2.0, CAR_HIGH, CAR_HALF.y * 2.0)
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.global_transform = Transform3D(p.xf.basis, p.xf.origin + Vector3(0, CAR_HIGH * 0.5, 0))
	p.hard = body
	_walls.append(p)
	if _sliding.has(p):
		_rest(p)


func _drop_wall(p: Parked) -> void:
	if p.hard != null:
		if is_instance_valid(p.hard):
			p.hard.queue_free()
		p.hard = null
	_walls.erase(p)


## The walls of wedged cars the player has left behind go.
func _drop_far_walls(at: Vector3) -> void:
	for p: Parked in _walls.duplicate():
		if Vector2(p.xf.origin.x - at.x, p.xf.origin.z - at.z).length() > HARD_NEAR:
			_drop_wall(p)


## The sliding cars one frame on: friction (or the lane rule's braking) to their rest, never past
## their clamp; one that meets another parked car pushes it on (a chain) and loses what it gave.
func _slide_cars(dt: float) -> void:
	for p: Parked in _sliding.duplicate():
		var v0 := p.speed
		var v1 := maxf(v0 - p.brake * dt, 0.0)
		var step := (v0 + v1) * 0.5 * dt
		var stop_at := p.limit if p.target < 0.0 else minf(p.limit, p.target)
		if p.gone + step >= stop_at - 0.001:
			step = maxf(stop_at - p.gone, 0.0)
			v1 = 0.0
		var turn := p.spin * minf((v0 + v1) * 0.5 / maxf(p.speed0, 0.1), 1.0) * dt
		var next := Transform3D(Basis(Vector3.UP, turn) * p.xf.basis, p.xf.origin + Vector3(p.dir.x, 0.0, p.dir.y) * step)
		if ground_at.is_valid():
			next.origin.y = float(ground_at.call(next.origin.x, next.origin.z))
		var q := _meets_car(p, next)
		if q != null:
			_push_on(q, p)
			if p.speed <= 0.05:
				_rest(p)
			continue
		p.xf = next
		p.gone += step
		p.speed = v1
		_show(p)
		if v1 <= 0.0:
			_rest(p)


## The first parked car (not `p`) that `p`'s box at `xf` meets and did not meet where it was.
func _meets_car(p: Parked, xf: Transform3D) -> Parked:
	var box := box_of(xf, CAR_HALF)
	var lo := box[0]
	var hi := box[0]
	for v in box:
		lo = lo.min(v)
		hi = hi.max(v)
	var was := box_of(p.xf, CAR_HALF)
	for q: Parked in _cars_near(lo, hi, xf.origin):
		if q == p or absf(q.xf.origin.y - xf.origin.y) >= CAR_HIGH:
			continue
		var qb := box_of(q.xf, CAR_HALF)
		if polys_meet(box, qb) and not polys_meet(was, qb):
			return q
	return null


## Sliding car `p` meets parked car `q`: `q` takes PUSH_SHARE of `p`'s speed into its face and slides
## (unless it cannot move, or stands as a wall), `p` keeps the rest of its own.
func _push_on(q: Parked, p: Parked) -> void:
	var v := p.dir * p.speed
	var n := face_normal(q.xf, Vector2(p.xf.origin.x, p.xf.origin.z))
	var into := -v.dot(n)
	if into < PUSH_INTO or q.hard != null:
		p.speed = 0.0
		return
	var give := into * Solidity.PUSH_SHARE
	if _room(q, -n, cast_reach(give)) < Solidity.PUSH_WEDGED:
		p.speed = 0.0
		return
	p.speed = maxf(p.speed - give, 0.0)
	_plan_rest(p)
	var t := Vector2(-n.y, n.x)
	var side_face := absf(n.dot(Vector2(q.xf.basis.x.x, q.xf.basis.x.z).normalized())) > 0.7
	var lever := clampf((Vector2(p.xf.origin.x, p.xf.origin.z) - Vector2(q.xf.origin.x, q.xf.origin.z)).dot(t)
			/ (CAR_HALF.y if side_face else CAR_HALF.x), -1.0, 1.0)
	_start_slide(q, -n, give, lever)
	chains += 1
	_remember(q.id, q.id, -1, q.xf.origin)
	pushed.emit(q.id, q.xf.origin + Vector3(0, 0.7, 0), Vector3(-n.x, 0.0, -n.y), give)


## `p` has stopped: at rest off its bay, or towed when the lane rule found it no free rest.
func _rest(p: Parked) -> void:
	_sliding.erase(p)
	p.speed = 0.0
	if p.in_lane:
		if p.state != TOWED:
			towed += 1
		p.state = TOWED
	else:
		p.state = MOVED
	if _broken.has(p.id):
		_broken[p.id][2] = p.xf.origin


## The lane rule: where `p` comes to rest, never in a lane corridor. From where friction would stop
## it (never past its clamp), the nearest spot either way (REST_STEP apart, braking between
## REST_BRAKE_LEAST and REST_BRAKE_MOST) whose box is clear of every lane of the graph on its level;
## with none it rests where friction stops it and is `towed`. No graph: friction alone.
func _plan_rest(p: Parked) -> void:
	p.brake = Solidity.PUSH_FRICTION
	p.target = -1.0
	p.in_lane = false
	var v2 := p.speed * p.speed
	var natural := minf(p.gone + v2 / (2.0 * Solidity.PUSH_FRICTION), p.limit)
	if graph == null:
		return
	var lo := minf(p.gone + v2 / (2.0 * REST_BRAKE_MOST), natural)
	var hi := minf(p.limit, p.gone + v2 / (2.0 * REST_BRAKE_LEAST))
	var from := Vector2(p.xf.origin.x, p.xf.origin.z)
	var reach := hi - p.gone + CAR_HALF.y + 1.0
	var segs := corridor_segments(graph, from, reach, p.xf.origin.y)
	var turn_left := p.spin * p.speed / (2.0 * Solidity.PUSH_FRICTION) * minf(p.speed / maxf(p.speed0, 0.1), 1.0)
	var best := -1.0
	var k := 0
	while true:
		var tried := false
		for s: float in ([natural] if k == 0 else [natural + k * REST_STEP, natural - k * REST_STEP]):
			if s < lo - 0.001 or s > hi + 0.001:
				continue
			tried = true
			var at := Transform3D(Basis(Vector3.UP, turn_left) * p.xf.basis, p.xf.origin + Vector3(p.dir.x, 0.0, p.dir.y) * (s - p.gone))
			if not in_corridor(at, segs):
				best = s
				break
		if best >= 0.0 or (not tried and k > 0):
			break
		k += 1
	if best < 0.0:
		p.in_lane = true
		return
	p.target = best
	var left := best - p.gone
	p.brake = v2 / (2.0 * left) if left > 0.01 else REST_BRAKE_MOST * 10.0


## The lanes near `at` (within `reach` m, on its level: their surface within LANE_LEVEL m of `y`) of
## lane graph `g`, as [ax, az, bx, bz, from, to] per centreline segment (`from`..`to` m right of it:
## the lanes' outer edges).
const LANE_LEVEL := 2.5
static func corridor_segments(g, at: Vector2, reach: float, y: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var box := Rect2(at - Vector2(reach, reach), Vector2(reach, reach) * 2.0)
	var cell := LaneGraph.CELL
	var seen := {}
	var c0 := Vector2i(floori((at.x - reach - 30.0) / cell), floori((at.y - reach - 30.0) / cell))
	var c1 := Vector2i(floori((at.x + reach + 30.0) / cell), floori((at.y + reach + 30.0) / cell))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var list: Variant = g.grid.get(LaneGraph.cell_key(Vector2((cx + 0.5) * cell, (cz + 0.5) * cell)))
			if list == null:
				continue
			for e: int in list:
				if seen.has(e):
					continue
				seen[e] = true
				var lw: float = g.e_lw[e]
				var from: float = g.e_off0[e] - lw * 0.5
				var to: float = g.e_off0[e] + lw * (int(g.e_lanes[e]) - 0.5)
				var grow := maxf(absf(from), absf(to))
				var i0: int = g.e_first[e]
				for k in int(g.e_count[e]) - 1:
					var a: Vector2 = g.pts[i0 + k]
					var b: Vector2 = g.pts[i0 + k + 1]
					var sb := Rect2(a.min(b), (a.max(b) - a.min(b))).grow(grow)
					if not sb.intersects(box):
						continue
					if absf(float(g.height(e, (g.cum[i0 + k] + g.cum[i0 + k + 1]) * 0.5)) - y) > LANE_LEVEL:
						continue
					out.append_array([a.x, a.y, b.x, b.y, from, to])
	return out


## Whether a parked car's box at `xf` reaches into a lane of `segs` (corridor_segments): its corners,
## the middles of its sides and three points down its middle, a hair inside the lanes' edges.
static func in_corridor(xf: Transform3D, segs: PackedFloat32Array) -> bool:
	if segs.is_empty():
		return false
	var right := Vector2(xf.basis.x.x, xf.basis.x.z).normalized() * CAR_HALF.x
	var back := Vector2(xf.basis.z.x, xf.basis.z.z).normalized() * CAR_HALF.y
	var o := Vector2(xf.origin.x, xf.origin.z)
	var pts := [o + right + back, o + right - back, o - right - back, o - right + back, o + right, o - right,
			o, o + back * 0.5, o - back * 0.5]
	for i in range(0, segs.size(), 6):
		var a := Vector2(segs[i], segs[i + 1])
		var d := Vector2(segs[i + 2], segs[i + 3]) - a
		var l2 := d.length_squared()
		if l2 < 0.0001:
			continue
		var r := Vector2(-d.y, d.x) / sqrt(l2)
		for q: Vector2 in pts:
			var t := (q - a).dot(d) / l2
			if t < 0.0 or t > 1.0:
				continue
			var side := (q - a).dot(r)
			if side > segs[i + 4] + 0.05 and side < segs[i + 5] - 0.05:
				return true
	return false


## A pushed car back in its bay (rule B, `repair_near`, `reset`): drawn there again, its wall gone.
func _return_car(id: String) -> void:
	_car_rest.erase(id)
	var p: Parked = _car_of.get(id)
	if p == null:
		return
	_drop_wall(p)
	_off_bay.erase(p)
	_sliding.erase(p)
	p.state = BAY
	p.xf = p.bay
	p.hidden = false
	p.speed = 0.0
	p.touched = -INF
	_show(p)
	returns += 1
	car_returned.emit(id)


## Step 8a: the parked car `id` (the check; null when its sector is not in).
func parked(id: String) -> Parked:
	return _car_of.get(id)


## Step 8a: how many parked cars are swept now (own, in the loaded sectors), and how many off their bays.
func car_count() -> int:
	var n := 0
	for k: Vector2i in _car_sectors:
		n += (_car_sectors[k]["cars"] as Array).size()
	return n


func off_bay_count() -> int:
	return _off_bay.size()


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
