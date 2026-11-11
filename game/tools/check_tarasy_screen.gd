extends SceneTree
## The 3D corner screen at Złote Tarasy (tarasy_screen.gd): an L of two flat faces round Skylight's
## south-east corner (F, 2026-11-11). The strip builds as one surface, 22-30 m round, the wide face
## longer than the return and the two at a corner (not a curve: their normals 60-120 degrees apart),
## each point within 2 m of the tower's mapped wall, the box between 10 and 27 m up (over the
## lobby's canopy, under the glazed belt's top), and its shader loads. No map needed (flat ground).
##   godot --headless --path game --script res://tools/check_tarasy_screen.gd

const TarasyScreen := preload("res://scripts/tarasy_screen.gd")

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _init() -> void:
	var s := TarasyScreen.new()
	s.build()
	_expect(s.mesh_instance != null and s.mesh_instance.mesh.get_surface_count() == 1, "not one surface")
	_expect(s.length > 22.0 and s.length < 30.0, "length %.1f m" % s.length)
	_expect(s.corner > s.length - s.corner, "the wide face (%.1f m) is not the longer one" % s.corner)
	var o := TarasyScreen.outline()
	for i in o[0].size():
		_expect((o[0][i] as Vector2).distance_to(TarasyScreen.WALL[i]) < 2.0, "point %d off the wall" % i)
	for i in o[1].size():
		_expect((o[1][i] as Vector2).length() > 0.99, "normal %d" % i)
	var turn := rad_to_deg((o[1][0] as Vector2).angle_to(o[1][1] as Vector2))
	_expect(absf(turn) > 60.0 and absf(turn) < 120.0, "the faces turn %.0f degrees, not a corner" % turn)
	_expect(TarasyScreen.BOTTOM >= 10.0 and TarasyScreen.BOTTOM + TarasyScreen.HEIGHT <= 27.0, "screen outside the tower's band")
	var aabb := s.mesh_instance.mesh.get_aabb()
	_expect(absf(aabb.size.y - TarasyScreen.HEIGHT - TarasyScreen.MARGIN) < 0.01, "height %s" % aabb)
	_expect(s.mesh_instance.custom_aabb.encloses(aabb), "custom AABB misses the mesh")
	_expect(load(TarasyScreen.SHADER) is Shader, "shader missing")
	var len := s.length
	var corner := s.corner
	s.free()  # no leaked render objects at exit (verify counts every ERROR line)
	print("tarasy_screen: %s (%.1f m, corner at %.1f m, %.0f degrees)" % ["OK" if _problems == 0 else "FAIL", len, corner, turn])
	quit(1 if _problems > 0 else 0)
