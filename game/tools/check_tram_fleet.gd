extends SceneTree
## The tram fleet (scripts/tram_fleet.gd, 2026-11-06): the four looks on trams.gd's real tracks,
## headless, from the committed map data (map/centrum.json):
##   1. the meshes: each kind's cars are one surface each (made once: the same objects twice),
##      at most 2.6 m wide, 4.6 m tall and their car length + 0.8 m long, at most 2,400 vertices;
##   2. the fleet: the eight trams carry FLEET's looks (tram 0 the newest, tram 1 the old pair),
##      every kind runs, each tram's shown cars match its look (3 for the newest and today's, 2
##      for a pair: never more mesh nodes than before), the collision boxes are its cars' length,
##      the red tail glow hangs on its last car;
##   3. the vintage swap on a pair: the old set (2 cars of CAR m) and back to the pair's own look
##      (PAIR_CAR m cars, its meshes, its glow on car 2);
##   4. a minute of running: every tram moves, its posed cars stay on its length.
## Prints "check_tram_fleet: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_tram_fleet.gd

const Fleet := preload("res://scripts/tram_fleet.gd")
const Trams := preload("res://scripts/trams.gd")
const OldTram := preload("res://scripts/old_tram.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")


class FakeMap extends Node3D:
	func deck_height(_dk: int, _x: float, _z: float) -> float:
		return 0.0


var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_meshes(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var g := LaneGraph.new(data["graph"], null)
	var map := FakeMap.new()
	root.add_child(map)
	var trams: Trams = Trams.new()
	root.add_child(trams)
	trams.setup(g, map, data)
	trams.player_on_road = false
	_check_fleet(trams, digest)
	_check_vintage(trams, digest)
	_check_running(trams, digest)
	trams.free()
	map.free()
	if problems.is_empty():
		print("check_tram_fleet: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_tram_fleet: %d problems" % problems.size())
		quit(1)


func _check_meshes(digest: PackedStringArray) -> void:
	var vs := PackedStringArray()
	for kind in Fleet.Kind.values():
		var meshes := Fleet.meshes(kind)
		if Fleet.meshes(kind)[0] != meshes[0]:
			problems.append("%s: meshes made again" % Fleet.label(kind))
		var pair: bool = kind == Fleet.Kind.PAIR or kind == Fleet.Kind.PAIR_NEW
		var car := Fleet.PAIR_CAR if pair else Trams.CAR
		if meshes.size() != (2 if pair else 3):
			problems.append("%s: %d cars" % [Fleet.label(kind), meshes.size()])
		var most := 0
		for m: ArrayMesh in meshes:
			var v := (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			most = maxi(most, v)
			var box := m.get_aabb()
			if m.get_surface_count() != 1:
				problems.append("%s: a car of %d surfaces" % [Fleet.label(kind), m.get_surface_count()])
			if box.size.x > 2.8 or box.size.z > car + 0.8 or box.size.y > 4.6 or box.position.y < 0.0:
				problems.append("%s: a car's box %s" % [Fleet.label(kind), box])
			if v > 2400:
				problems.append("%s: %d vertices (the cap 2400)" % [Fleet.label(kind), v])
		vs.append("%s %d×%d" % [Fleet.label(kind), meshes.size(), most])
	digest.append("cars of 1 surface (%s vertices)" % ", ".join(vs))


func _check_fleet(trams: Trams, digest: PackedStringArray) -> void:
	var seen := {}
	if trams.trams.size() != Trams.COUNT:
		problems.append("fleet: %d trams" % trams.trams.size())
		return
	if trams.trams[0].kind != Fleet.Kind.SMILE or trams.trams[1].kind != Fleet.Kind.PAIR:
		problems.append("fleet: the first scene's trams are %d, %d (want the newest, the old pair)" % [
				trams.trams[0].kind, trams.trams[1].kind])
	var shown_total := 0
	for i in trams.trams.size():
		var t: Trams.Tram = trams.trams[i]
		trams._pose(t)
		seen[t.kind] = true
		if t.kind != Trams.FLEET[i]:
			problems.append("fleet: tram %d is %d, want %d" % [i, t.kind, Trams.FLEET[i]])
		var look: Array = Fleet.meshes(t.kind)
		if t.n_cars != look.size():
			problems.append("fleet: tram %d has %d cars, its look %d" % [i, t.n_cars, look.size()])
		for k in 3:
			var b := t.cars[k]
			var mi := b.get_child(0) as MeshInstance3D
			if k < t.n_cars:
				if mi.mesh != look[k]:
					problems.append("fleet: tram %d car %d without its mesh" % [i, k])
				for c in b.get_children():
					if c is CollisionShape3D and absf(((c as CollisionShape3D).shape as BoxShape3D).size.z - t.car_len) > 0.01:
						problems.append("fleet: tram %d car %d's box is not %.1f m" % [i, k, t.car_len])
			elif b.visible:
				problems.append("fleet: tram %d shows car %d past its %d" % [i, k, t.n_cars])
			shown_total += int(b.visible)
		if t.tail.get_parent() != t.cars[t.n_cars - 1]:
			problems.append("fleet: tram %d's tail glow not on its last car" % i)
	if seen.size() != Fleet.Kind.size():
		problems.append("fleet: only %d of %d kinds run" % [seen.size(), Fleet.Kind.size()])
	var names := PackedStringArray()
	for i in trams.trams.size():
		names.append(Fleet.label(trams.trams[i].kind))
	digest.append("8 trams: %s; %d car meshes shown (all modern: %d)" % [", ".join(names), shown_total, 3 * Trams.COUNT])


func _check_vintage(trams: Trams, digest: PackedStringArray) -> void:
	var t: Trams.Tram = trams.trams[1]
	var own: Array = Fleet.meshes(t.kind)
	trams.set_vintage(t, true, OldTram.vintage_meshes(), OldTram.CRUISE)
	trams._pose(t)
	if t.n_cars != 2 or absf(t.car_len - Trams.CAR) > 0.01 or t.cars[2].visible:
		problems.append("vintage on a pair: %d cars of %.1f m" % [t.n_cars, t.car_len])
	trams.set_vintage(t, false)
	trams._pose(t)
	var back := 0
	for k in 2:
		back += int((t.cars[k].get_child(0) as MeshInstance3D).mesh == own[k])
	if back != 2 or absf(t.car_len - Fleet.PAIR_CAR) > 0.01 or t.tail.get_parent() != t.cars[1] or t.cars[2].visible:
		problems.append("vintage off: the pair's look not back (%d meshes, %.1f m)" % [back, t.car_len])
	digest.append("vintage swap on a pair and back")


func _check_running(trams: Trams, digest: PackedStringArray) -> void:
	var start: Array[Vector2] = []
	for t in trams.trams:
		start.append(trams.body_point(t, 0.0))
	for f in 3600:
		trams._process(1.0 / 60.0)
	var moved := 0
	for i in trams.trams.size():
		var t: Trams.Tram = trams.trams[i]
		if trams.body_point(t, 0.0).distance_to(start[i]) > 20.0:
			moved += 1
		var len := Trams.length_of(t)
		var want := t.n_cars * t.car_len + (t.n_cars - 1) * t.joint
		if absf(len - want) > 0.01:
			problems.append("running: tram %d's length %.1f, want %.1f" % [i, len, want])
	if moved < Trams.COUNT - 2:
		problems.append("running: only %d of %d trams moved 20 m in a minute" % [moved, Trams.COUNT])
	digest.append("%d of %d moved in a minute" % [moved, Trams.COUNT])
