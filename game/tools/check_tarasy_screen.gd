extends SceneTree
## The 3D corner screen at Złote Tarasy (tarasy_screen.gd): the strip builds as one surface, is
## 40-60 m long, stands within 2 m of the block's mapped plate wall, starts above the 17 m entrance roof and
## its shader loads. No map needed (flat ground).
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
	_expect(s.length > 40.0 and s.length < 60.0, "length %.1f m" % s.length)
	var o := TarasyScreen.outline()
	for i in o[0].size():
		_expect((o[0][i] as Vector2).distance_to(TarasyScreen.WALL[i]) < 2.0, "point %d off the wall" % i)
		_expect((o[1][i] as Vector2).length() > 0.99, "normal %d" % i)
	_expect(TarasyScreen.BOTTOM >= 17.0 and TarasyScreen.BOTTOM + TarasyScreen.HEIGHT < TarasyScreen.BLOCK_TOP, "screen outside the block")
	var aabb := s.mesh_instance.mesh.get_aabb()
	_expect(aabb.size.y > 20.0 and aabb.size.y < 25.0, "height %s" % aabb)
	_expect(load(TarasyScreen.SHADER) is Shader, "shader missing")
	var len := s.length
	s.free()  # no leaked render objects at exit (verify counts every ERROR line)
	print("tarasy_screen: %s (%.1f m)" % ["OK" if _problems == 0 else "FAIL", len])
	quit(1 if _problems > 0 else 0)
