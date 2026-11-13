extends SceneTree
## The site turntable (tools/turntable.sh): site_cams.gd's camera maths for a known site (rotunda:
## 8 + 8 + 1 cameras that parse back, the centre inside the site's box, sizes above 0, the whole box
## inside the view with margin), an unknown key gives nothing, and shot_sheet.gd pastes two small
## generated images into a sheet of the right size with the gap. The game runs themselves are
## tools/turntable.sh's (a renderer); this is the part that needs none.
##   godot --headless --path game --script res://tools/check_turntable.gd

const SiteCams := preload("res://tools/site_cams.gd")
const ShotSheet := preload("res://tools/shot_sheet.gd")
const FollowCamera := preload("res://scripts/follow_camera.gd")

var _problems := 0


func _init() -> void:
	var box := SiteCams.box_for("rotunda")
	_expect(not box.is_empty(), "rotunda builds triangles")
	if not box.is_empty():
		var lo: Vector3 = box["min"]
		var hi: Vector3 = box["max"]
		var out := SiteCams.cams_for(box, 4.0 / 3.0)
		var cams := FollowCamera.parse_cams(out["cams"])
		_expect(cams.size() == 17, "17 cameras, got %d" % cams.size())
		_expect(is_equal_approx(float(out["lift"]), (lo.y + hi.y) * 0.5), "lift is the box's mid height")
		var diag := Vector2(hi.x - lo.x, hi.z - lo.z).length()
		var names := {}
		for c: Dictionary in cams:
			names[c["name"]] = true
			var at: Vector3 = c["at"]
			_expect(at.x > lo.x and at.x < hi.x and at.z > lo.z and at.z < hi.z, "%s aims inside the box" % c["name"])
			_expect(float(c["size"]) > 0.0, "%s has a size" % c["name"])
			# The view's height shows the box's worst-case screen height with the margin.
			var p := deg_to_rad(absf(float(c["pitch"])))
			_expect(float(c["size"]) >= ((hi.y - lo.y) * cos(p) + diag * sin(p)) * 1.14, "%s shows the whole box" % c["name"])
		for n in ["lo_000", "lo_315", "hi_000", "hi_315", "top"]:
			_expect(names.has(n), "camera %s exists" % n)
	_expect(SiteCams.box_for("no_such_site_key").is_empty(), "an unknown key gives no box")
	# A tall thin box and a wide flat one both fit (view height covers the worst yaw).
	for dims: Vector3 in [Vector3(10, 200, 10), Vector3(300, 5, 300)]:
		var o := SiteCams.cams_for({"min": Vector3.ZERO, "max": dims}, 4.0 / 3.0)
		var cs := FollowCamera.parse_cams(o["cams"])
		_expect(cs.size() == 17 and float(cs[0]["size"]) >= dims.y, "%s: the view is at least as tall as the box" % [dims])
	# The sheet: two 16x12 tiles and a missing one in 2 columns = 2 rows.
	var a := Image.create(16, 12, false, Image.FORMAT_RGBA8)
	a.fill(Color.RED)
	var b := Image.create(16, 12, false, Image.FORMAT_RGBA8)
	b.fill(Color.GREEN)
	var dir := OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	a.save_png(dir + "/tt_a.png")
	b.save_png(dir + "/tt_b.png")
	var missing := PackedStringArray()
	var sheet := ShotSheet.compose(PackedStringArray([dir + "/tt_a.png", dir + "/tt_b.png", dir + "/tt_none.png"]), 2, missing)
	_expect(sheet != null and sheet.get_width() == 2 * 16 + 3 * 4 and sheet.get_height() == 2 * 12 + 3 * 4, "the sheet is 2 x 2 tiles with 4 px gaps")
	_expect(missing.size() == 1, "the missing file is named")
	if sheet != null:
		_expect(sheet.get_pixel(4 + 2, 4 + 2).is_equal_approx(Color.RED) and sheet.get_pixel(4 + 16 + 4 + 2, 4 + 2).is_equal_approx(Color.GREEN), "tiles land in their cells")
		_expect(sheet.get_pixel(2, 2) != Color.RED, "the gap is dark")
	_expect(ShotSheet.compose(PackedStringArray([dir + "/tt_none.png"]), 2, PackedStringArray()) == null, "no file loads: null")
	print("check_turntable: %s" % ("OK" if _problems == 0 else "FAIL (%d)" % _problems))
	quit(0 if _problems == 0 else 1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  PROBLEM: " + what)
