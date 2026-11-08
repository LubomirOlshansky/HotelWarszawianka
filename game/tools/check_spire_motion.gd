extends SceneTree
## The Warsaw Spire's moving parts (spire_motion.gd): the tower's vase shape (a waist, then a concave
## flare to the widest plan at the roof), the crown's LED ticker (one surface, a band of the right height
## wrapped round the crown just proud of the glass, a whole number of text laps so it has no seam)
## and the plaza jets (one surface, each jet in the fountain's basin, a small pool or the channel);
## both shaders load. No map needed: a stand-in map with an oval like the tower's mapped outline.
##   godot --headless --path game --script res://tools/check_spire_motion.gd

const SpireMotion := preload("res://scripts/spire_motion.gd")


class FakeMap extends Node3D:
	var data := {}

	func terrain_height(_x: float, _z: float) -> float:
		return 0.0


var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _init() -> void:
	# The vase: a waist, then a concave flare to the widest plan at the roof.
	_expect(is_equal_approx(SpireMotion.k_at(0.0), SpireMotion.K_FOOT), "k at the lobby")
	_expect(is_equal_approx(SpireMotion.k_at(SpireMotion.H_WAIST), SpireMotion.K_WAIST), "k at the waist")
	_expect(is_equal_approx(SpireMotion.k_at(SpireMotion.ROOF), 1.0), "k at the roof")
	var last := 0.0
	for h in range(int(SpireMotion.H_WAIST), int(SpireMotion.ROOF) + 1, 5):
		var k := SpireMotion.k_at(h)
		_expect(k >= last, "k falls at %d m above the waist" % h)
		# concave: the flare grows faster the higher it goes
		if h >= int(SpireMotion.H_WAIST) + 10:
			_expect(k - SpireMotion.k_at(h - 5) >= SpireMotion.k_at(h - 5) - SpireMotion.k_at(h - 10) - 1e-6, "convex at %d m" % h)
		last = k
	# A stand-in outline: the tower's oval, 45 x 61 m.
	var c := Vector2(-2720.5, 201.6)
	var pts: Array = []
	for k in 48:
		var d := Vector2.from_angle(TAU * k / 48.0)
		pts.append_array([c.x + d.x * 22.5, c.y + d.y * 30.5])
	var fake := FakeMap.new()
	fake.data = {"landmarks": [{"name": SpireMotion.TOWER, "p": pts}]}
	var s := SpireMotion.new()
	s.map = fake
	s.build()
	_expect(s.ticker != null and s.ticker.mesh.get_surface_count() == 1, "ticker not one surface")
	if s.ticker != null:
		var aabb := s.ticker.mesh.get_aabb()
		_expect(absf(aabb.size.y - (SpireMotion.TICK_Y1 - SpireMotion.TICK_Y0)) < 0.01, "ticker band %.2f m" % aabb.size.y)
		_expect(s.tick_length > 120.0 and s.tick_length < 200.0, "ticker %.1f m round" % s.tick_length)
		var arr: Array = s.ticker.mesh.surface_get_arrays(0)
		for v: Vector3 in arr[Mesh.ARRAY_VERTEX]:
			var k := SpireMotion.k_at(v.y)
			var q := Vector2(v.x, v.z) - c
			# on the oval scaled by k, TICK_OUT proud of it
			var r := Vector2(q.x / (22.5 * k), q.y / (30.5 * k)).length()
			if r < 1.0 or r > 1.03:
				_expect(false, "ticker vertex off the glass (%.3f)" % r)
				break
		var mat := s.ticker.material_override as ShaderMaterial
		var px: Vector2 = mat.get_shader_parameter("px_m")
		var wpx: Vector2 = mat.get_shader_parameter("words_px")
		var laps := s.tick_length / (px.x * wpx.x)
		_expect(absf(laps * roundf(1.0 / laps) - 1.0) < 0.001 or absf(laps - roundf(laps)) < 0.001, "the text's laps %.3f leave a seam" % laps)
		_expect(px.x > 0.35 and px.x < 0.7, "LEDs %.2f m wide" % px.x)
	_expect(s.jet_mesh != null and s.jet_mesh.mesh.get_surface_count() == 1, "jets not one surface")
	var line := SpireMotion.channel_line()
	for j: Array in SpireMotion.jets():
		var p := Vector2(float(j[0]), float(j[1]))
		var ok := p.distance_to(SpireMotion.FOUNTAIN) < 5.0
		for pool: Vector2 in SpireMotion.POOLS:
			ok = ok or p.distance_to(pool) < 2.0
		for q in line:
			ok = ok or p.distance_to(q) < SpireMotion.CHANNEL_W * 0.5
		_expect(ok, "jet at %s is not in the water" % p)
	_expect(load("res://shaders/spire_ticker.gdshader") is Shader, "ticker shader missing")
	_expect(load("res://shaders/spire_jets.gdshader") is Shader, "jets shader missing")
	var jets := SpireMotion.jets().size()
	var length := s.tick_length
	s.free()
	fake.free()
	print("spire_motion: %s (ticker %.1f m, %d jets)" % ["OK" if _problems == 0 else "FAIL", length, jets])
	quit(1 if _problems > 0 else 0)
