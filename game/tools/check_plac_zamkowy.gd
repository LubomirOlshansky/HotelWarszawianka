extends SceneTree
## Plac Zamkowy's life (2026-11-10, plac_zamkowy_life.gd; the plaza and cafe gardens are checked
## in check_sites.gd): on a stub map with flat open ground, the node builds its 72 standing and 16
## strolling tourists and 24 pigeons, sleeps (hidden, not processing) while the player is far,
## wakes within ACTIVE_R, leaves the flock alone for a car parked a long way off, flushes it
## (signal `flushed`, pigeons in the air) when a car comes within 13 m, and sends it home again
## after the car has gone (pecking again within 2 m of their spots); a helicopter 25 m up over the flock flushes it too. No map files needed.
## Prints `check_plac_zamkowy: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_plac_zamkowy.gd

const Life := preload("res://scripts/plac_zamkowy_life.gd")

var problems: Array[String] = []
var _flushes := 0


## Flat open ground: nothing solid anywhere.
class StubMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0

	func terrain_height(_x: float, _z: float) -> float:
		return 0.0

	func top_height(_x: float, _z: float, _r := 0.0) -> float:
		return 0.0


func _initialize() -> void:
	var map := StubMap.new()
	root.add_child(map)
	var life: Node3D = Life.new()
	root.add_child(life)
	life.flushed.connect(func(_at: Vector3) -> void: _flushes += 1)
	life.setup(map)
	var far := Vector3(Life.CENTRE.x + 900.0, 0.0, Life.CENTRE.y)
	life.tick(far, Vector3.ZERO, false)
	if life.visible or life.is_processing():
		problems.append("awake with the player 900 m away")
	var flock := Vector3(Life.FLOCK_AT.x, 0.0, Life.FLOCK_AT.y)
	# A parked car at the flock does nothing (a car must be moving), and the node wakes.
	life.tick(flock + Vector3(5.0, 0.0, 0.0), Vector3.ZERO, false)
	if not life.visible or not life.is_processing():
		problems.append("asleep with the player on the square")
	for i in 30:
		life._process(1.0 / 60.0)
		life.tick(flock + Vector3(5.0, 0.0, 0.0), Vector3.ZERO, false)
	if _flushes != 0:
		problems.append("a parked car flushed the pigeons")
	# A moving car at 5 m: up they go.
	for i in 20:
		life.tick(flock + Vector3(5.0, 0.0, 0.0), Vector3(6.0, 0.0, 0.0), false)
		life._process(1.0 / 60.0)
	var up := 0
	for p: Vector3 in life._pos:
		if p.y > 0.5:
			up += 1
	if _flushes != 1 or up < Life.PIGEONS - 2:
		problems.append("a car at 5 m: %d flushes, %d of %d pigeons up" % [_flushes, up, Life.PIGEONS])
	# The car goes away: after the circle the flock lands on its own spots again.
	for i in 60 * 30:
		life.tick(flock + Vector3(150.0, 0.0, 0.0), Vector3.ZERO, false)
		life._process(1.0 / 60.0)
	var home := 0
	for i in Life.PIGEONS:
		if (life._pos[i] as Vector3).y < 0.3 and Vector2(life._pos[i].x - life._home[i].x, life._pos[i].z - life._home[i].z).length() < 2.0:
			home += 1
	if life._flock != 0 or home < Life.PIGEONS:
		problems.append("only %d of %d pigeons landed again" % [home, Life.PIGEONS])
	# The helicopter low over them.
	for i in 20:
		life.tick(flock + Vector3(0.0, 25.0, 0.0), Vector3(2.0, 0.0, 0.0), true)
		life._process(1.0 / 60.0)
	if _flushes != 2:
		problems.append("the helicopter at 25 m did not flush the flock (%d flushes)" % _flushes)
	# Nobody stands inside a cafe set.
	var u: Array = Life.Landmarks.ZAMKOWY_SETS
	for k in range(0, u.size(), 3):
		var c := Vector2(u[k], u[k + 1])
		for i in Life.STANDING:
			var o: Vector3 = (life._stand_mm as MultiMesh).get_instance_transform(i).origin
			if o.length() > 0.01 and Vector2(o.x, o.z).distance_to(c) < 1.0:
				problems.append("a tourist stands in the cafe set at %s" % c)
				break
	if problems.is_empty():
		print("check_plac_zamkowy: OK (%d standing, %d strolling, %d pigeons; flush, landing and the helicopter)" % [
				Life.STANDING, Life.STROLLING, Life.PIGEONS])
	else:
		for p in problems:
			print("check_plac_zamkowy: ", p)
	quit(0 if problems.is_empty() else 1)
