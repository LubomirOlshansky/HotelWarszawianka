extends SceneTree
## The University guards' cart (scripts/campus_cart.gd, F's ask 2026-11-15) headless, on a flat map
## and the fakes (tools/fakes.gd), seeded, no clock of its own:
##   1. the ring: closed, about 330 m round the campus lawn, every corner within the campus box,
##      the kiosk's stop on it (within 8 m of PAUSE_AT);
##   2. the rules on synthetic inputs: `blocked` (a car GAP m ahead in its lane stops it; beside,
##      behind or farther out does not), `speed_at` (full on the straight, slower in a bend, never
##      under half);
##   3. the look: one surface, under 1,500 vertices, on the one actor material; one body, one box
##      collider;
##   4. a run: 200 s with the view on the campus: it laps and stops at the kiosk; a car parked ahead
##      holds it (it does not move) and the guard says a "blocked" line; the view 1 km away hides
##      it, turns its collider off and stops it;
##   5. the words: dialogue.json's `uw_guard` has 3 or more lines each for "blocked" and "fast",
##      `students` 8 or more plus 3 tagged "walk", none over 70 characters a side.
## Prints "check_campus: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_campus.gd [-- --verbose]

const CampusCart := preload("res://scripts/campus_cart.gd")
const Models := preload("res://scripts/models.gd")
const Fakes := preload("res://tools/fakes.gd")

var problems: Array[String] = []
var verbose := false
var view := Vector3(-335.0, 0.0, -702.0)
var car := Vector3(5000.0, 0.0, 5000.0)


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	await process_frame
	# 1. The ring.
	var pts := CampusCart.ring()
	var cum := CampusCart.cumulative(pts)
	var total := cum[cum.size() - 1]
	_expect(pts[0] == pts[pts.size() - 1], "the ring is closed")
	_expect(total > 280.0 and total < 400.0, "the ring is %.0f m (want 280-400)" % total)
	var campus := Rect2(-470.0, -790.0, 260.0, 160.0)
	for p in pts:
		_expect(campus.has_point(p), "a ring corner outside the campus: %s" % p)
	var ps := CampusCart.nearest_s(pts, cum, CampusCart.PAUSE_AT)
	var at_pause: Vector2 = CampusCart.point_at(pts, cum, ps)[0]
	_expect(at_pause.distance_to(CampusCart.PAUSE_AT) < 8.0, "the kiosk stop is %.1f m off the ring" % at_pause.distance_to(CampusCart.PAUSE_AT))
	# 2. The rules.
	var o := Vector2.ZERO
	var d := Vector2(0.0, -1.0)
	_expect(CampusCart.blocked(o, d, Vector2(0.0, -4.0)), "a car 4 m ahead blocks it")
	_expect(not CampusCart.blocked(o, d, Vector2(3.0, -4.0)), "a car 3 m beside its line does not block it")
	_expect(not CampusCart.blocked(o, d, Vector2(0.0, 4.0)), "a car behind does not block it")
	_expect(not CampusCart.blocked(o, d, Vector2(0.0, -12.0)), "a car 12 m ahead does not block it")
	var straight := PackedVector2Array([Vector2(0, 0), Vector2(0, -100), Vector2(1, -100), Vector2(0, 0)])
	var sc := CampusCart.cumulative(straight)
	_expect(is_equal_approx(CampusCart.speed_at(straight, sc, 10.0), CampusCart.SPEED), "full speed on the straight")
	var slow := CampusCart.speed_at(straight, sc, 97.0)
	_expect(slow < CampusCart.SPEED and slow >= CampusCart.SPEED * 0.5 - 0.001, "slower in the bend (%.2f m/s)" % slow)
	# 3. The look.
	var mesh := CampusCart.cart_mesh()
	var verts := (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_expect(mesh.get_surface_count() == 1 and verts < 1500, "the cart: %d surfaces, %d vertices (want 1, under 1,500)" % [mesh.get_surface_count(), verts])
	# 4. A run.
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var dlg := Fakes.Dialogue.new()
	dlg.say_words = ["…", "…"]
	root.add_child(dlg)
	var cart := CampusCart.new()
	cart.map = map
	cart.dialogue = dlg
	cart.focus = func() -> Vector3: return view
	cart.vehicle = func() -> Array: return [car, 0.0, false]
	root.add_child(cart)
	cart.setup()
	_expect(cart.body != null and cart.body.get_child_count() == 2, "one body with a mesh and a collider")
	_expect(cart.body.get_child(0) is MeshInstance3D and (cart.body.get_child(0) as MeshInstance3D).material_override == Models.material(),
			"the cart is on the actor material")
	_frames(cart, 200.0)
	var laps := cart.laps
	_expect(laps >= 1, "laps in 200 s: %d (want 1 or more)" % laps)
	# A car parked across its way: it holds, and the guard speaks.
	var p: Array = CampusCart.point_at(pts, cum, cart.s + 4.5)
	car = Vector3((p[0] as Vector2).x, 0.0, (p[0] as Vector2).y)
	cart.pause_left = 0.0
	_frames(cart, 0.5)
	var held := cart.s
	_frames(cart, 6.0)
	_expect(absf(cart.s - held) < 0.05, "a parked car ahead holds it (it moved %.2f m)" % absf(cart.s - held))
	_expect(dlg.count("uw_guard", "blocked") >= 1, "the guard says a blocked line")
	car = Vector3(5000.0, 0.0, 5000.0)
	cart.pause_left = 0.0
	_frames(cart, 2.0)
	_expect(absf(cart.s - held) > 1.0, "it drives on once the car is gone")
	# The view far away: hidden, no collider, still.
	view = Vector3(800.0, 0.0, 300.0)
	_frames(cart, 1.0)
	var away := cart.s
	_frames(cart, 5.0)
	_expect(not cart.body.visible and (cart.body.get_child(1) as CollisionShape3D).disabled and cart.s == away,
			"far from the view it hides, drops its collider and stands still")
	# 5. The words.
	var lines: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var groups: Dictionary = lines if lines is Dictionary else {}
	var count := func(group: String, tag: String) -> int:
		var n := 0
		for l: Array in groups.get(group, []):
			var notes: Dictionary = l[2] if l.size() > 2 and l[2] is Dictionary else {}
			n += int(str(notes.get("only", "")) == tag)
		return n
	_expect(count.call("uw_guard", "blocked") >= 3 and count.call("uw_guard", "fast") >= 3, "uw_guard lines: 3 or more for blocked and fast")
	_expect(count.call("students", "") >= 8 and count.call("students", "walk") >= 3, "students lines: 8 or more, 3 tagged walk")
	for g: String in ["uw_guard", "students"]:
		for l: Array in groups.get(g, []):
			_expect(str(l[0]).length() <= 70 and str(l[1]).length() <= 70, "%s line over 70 characters: %s" % [g, l[0]])
	var summary := cart.summary()
	cart.queue_free()
	dlg.queue_free()
	map.queue_free()
	await process_frame
	if problems.is_empty():
		print("check_campus: OK (ring %.0f m, %d laps in 200 s, %d vertices, held by a parked car; %s)" % [total, laps, verts, summary])
		quit(0)
	else:
		for q in problems:
			print("check_campus: PROBLEM " + q)
		quit(1)


## `secs` seconds of frames at 60 fps (the cart's _process by hand).
func _frames(cart: CampusCart, secs: float) -> void:
	var n := roundi(secs * 60.0)
	for i in n:
		cart._process(1.0 / 60.0)
