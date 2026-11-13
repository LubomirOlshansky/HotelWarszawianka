extends SceneTree
## The free camera (--cam=X,Y,Z, follow_camera.gd parse_free and free_view): the flag's text
## ("X,Z" the ground point, "X,Y,Z" a height, anything else refused) and the view it gives: the
## point lies on the camera's axis, the camera is the follow camera's distance back along its own
## backwards, turned by yaw and pitch (so a before and an after shot with one --cam differ only
## in what changed). main.gd's flag, the hidden car and the streaming are run by `tools/shots.sh`.
##   godot --headless --path game --script res://tools/check_free_cam.gd

const FollowCamera := preload("res://scripts/follow_camera.gd")

var _problems := 0


func _init() -> void:
	var a := FollowCamera.parse_free("-1290,170")
	_expect(a.size() == 3 and is_equal_approx(a[0], -1290.0) and is_nan(a[1]) and is_equal_approx(a[2], 170.0), "X,Z is a ground point, got %s" % [a])
	var b := FollowCamera.parse_free("10,45.5,-20")
	_expect(b.size() == 3 and is_equal_approx(b[0], 10.0) and is_equal_approx(b[1], 45.5) and is_equal_approx(b[2], -20.0), "X,Y,Z has the height in the middle, got %s" % [b])
	for bad in ["", "1", "1,2,3,4", "a,b", "1,,3", "5,x,6"]:
		_expect(FollowCamera.parse_free(bad).is_empty(), "'%s' is refused" % bad)
	var cams := FollowCamera.parse_cams("front:-100,,340,90,-30,40+top:5,60,6")
	_expect(cams.size() == 2 and cams[0]["name"] == "front" and is_nan(cams[0]["at"].y) and is_equal_approx(cams[0]["yaw"], 90.0) \
			and is_equal_approx(cams[0]["size"], 40.0) and is_equal_approx(cams[1]["at"].y, 60.0) and is_nan(cams[1]["yaw"]), "--cams: two cameras, ground and height, what is left out is NAN, got %s" % [cams])
	for bad in ["", "a:1,2", "a:1,2,3,4,5,6,7", "1,2,3", "x/y:1,2,3", "a:1,b,3"]:
		_expect(FollowCamera.parse_cams(bad).is_empty(), "--cams '%s' is refused" % bad)
	for yaw in [0.0, 45.0, 135.0, 270.0]:
		for pitch in [-30.0, -50.0, -90.0]:
			for size in [20.0, 80.0, 400.0]:
				var focus := Vector3(-100.0, 12.0, 340.0)
				var xf := FollowCamera.free_view(focus, yaw, pitch, size, 500.0)
				var axis := -xf.basis.z
				var to := focus - xf.origin
				_expect(to.normalized().dot(axis) > 0.99999, "the point is on the axis (yaw %s, pitch %s, size %s)" % [yaw, pitch, size])
				_expect(is_equal_approx(to.length(), maxf(500.0, size * 1.6)), "the follow camera's distance (size %s)" % size)
				_expect(absf(rad_to_deg(asin(axis.y)) - pitch) < 0.01, "the pitch is %s over the ground" % pitch)
				var flat := Vector2(axis.x, axis.z).angle_to(Vector2(0.0, -1.0))
				_expect(pitch == -90.0 or absf(wrapf(rad_to_deg(flat) - yaw, -180.0, 180.0)) < 0.01 or absf(wrapf(rad_to_deg(-flat) - yaw, -180.0, 180.0)) < 0.01, "the yaw turns the view (yaw %s)" % yaw)
	print("check_free_cam: %s" % ("OK" if _problems == 0 else "FAIL (%d)" % _problems))
	quit(0 if _problems == 0 else 1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		printerr("check_free_cam: ", what)
