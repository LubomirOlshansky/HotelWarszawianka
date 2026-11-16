extends SceneTree
## The opening flyover (camera_shots.gd `open_view`, docs/design/opening-flyover.md), without the
## map. Samples the flight at 60 frames a second for a car at the guide's start (First10.START,
## facing START_HEADING, the follow camera at -30°, 80 m) and checks that:
## - it is short: OPEN_TIME between 5 and 13 s (the morning, 2026-11-16: as long as the host's
##   line), the caption inside it;
## - it starts on the first key (the Palace, its size) and ends exactly on the follow view (the
##   same transform and size: no cut at the hand-off);
## - it is smooth: no frame moves the view's centre more than MAX_STEP m, turns it more than
##   MAX_TURN degrees or zooms it more than MAX_ZOOM; the first and last frames barely move
##   (eased at both ends);
## - the zoom only goes in (the size never grows), and the view's centre never dips under the
##   ground;
## - a start facing the other way still turns the short way round (no spin);
## - the morning (time_of_day.gd `morning`, F 2026-11-16), for every colour look: it starts on the
##   Night look and ends exactly on the Day look; the lights only go down and the daylight only up;
##   no frame changes the lights by more than MAX_LIGHT_STEP (a pop); the shadows are off while the
##   view is wider than SHADOW_WIDE m (no costlier frame than the old day flight had) and fully on
##   from the sunrise; the stages come in the host's order (night through her greeting, the lamps
##   going down by the end of her weather line, the sunrise during the Marszałkowska line, the day
##   by her last sentence).
##   godot --headless --path game --script res://tools/check_opening.gd

const Shots := preload("res://scripts/camera_shots.gd")
const First10 := preload("res://scripts/first10.gd")
const FPS := 60.0
const MAX_STEP := 6.0
const MAX_TURN := 1.5
const MAX_ZOOM := 0.03
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const Grades := preload("res://scripts/grades.gd")
const MAX_LIGHT_STEP := 0.02
## The old flight ran the day's shadows at its widest view, 420 m: the morning's never come on wider.
const SHADOW_WIDE := 420.0
## The host's line (opening_audio.gd): her greeting ends at 1.6 s, the weather at 5.0, the
## Marszałkowska line at 9.3.
const GREETING_END := 1.6
const WEATHER_END := 5.0
const MARSZ_END := 9.3

var _problems := 0


func _init() -> void:
	if Shots.OPEN_TIME < 5.0 or Shots.OPEN_TIME > 13.0:
		_fail("OPEN_TIME %.1f s is outside 5-13 s" % Shots.OPEN_TIME)
	if Shots.CAPTION_IN < 0.0 or Shots.CAPTION_OUT > Shots.OPEN_TIME - 1.0 or Shots.CAPTION_IN >= Shots.CAPTION_OUT:
		_fail("the caption (%.1f-%.1f s) must sit inside the flight and go a second before it ends"
				% [Shots.CAPTION_IN, Shots.CAPTION_OUT])
	_fly(First10.START_HEADING, "the guide's start")
	_fly(First10.START_HEADING + 180.0, "a start facing south")
	_fly(First10.START_HEADING - 360.0, "the same heading a turn round")
	for g in Grades.SETTING:
		_morning(g)
	if _problems == 0:
		print("opening: OK (%.1f s, %d frames, %.0f m → 80 m)" % [Shots.OPEN_TIME,
				int(Shots.OPEN_TIME * FPS), float(Shots.OPEN_KEYS[0]["size"])])
		quit(0)
	else:
		print("opening: %d problem(s)" % _problems)
		quit(1)


func _fly(heading: float, label: String) -> void:
	var ground := 2.0
	var car := Vector3(First10.START.x, ground, First10.START.y)
	var follow_size := 80.0
	var basis := Basis.from_euler(Vector3(deg_to_rad(-30.0), deg_to_rad(heading), 0.0))
	var follow_xf := Transform3D(basis, car + basis.z * Shots._distance(follow_size))
	var frames := int(ceil(Shots.OPEN_TIME * FPS))
	var first: Dictionary = Shots.open_view(0.0, ground, heading, follow_xf, follow_size)
	var key: Dictionary = Shots.OPEN_KEYS[0]
	var at: Vector2 = key["at"]
	var f0: Vector3 = first["focus"]
	if Vector2(f0.x, f0.z).distance_to(at) > 0.01 or absf(float(first["size"]) - float(key["size"])) > 0.01:
		_fail("%s: the first frame is not on the first key (%s, %.1f m)" % [label, f0, first["size"]])
	var last: Dictionary = Shots.open_view(1.0, ground, heading, follow_xf, follow_size)
	var lxf: Transform3D = last["xf"]
	if lxf.origin.distance_to(follow_xf.origin) > 0.01 or absf(float(last["size"]) - follow_size) > 0.01 \
			or not _same_basis(lxf.basis, follow_xf.basis):
		_fail("%s: the last frame is not the follow view (a cut at the hand-off)" % label)
	var prev := first
	var worst_step := 0.0
	var worst_turn := 0.0
	var worst_zoom := 0.0
	for i in range(1, frames + 1):
		var v: Dictionary = Shots.open_view(float(i) / frames, ground, heading, follow_xf, follow_size)
		var pf: Vector3 = prev["focus"]
		var vf: Vector3 = v["focus"]
		var step := pf.distance_to(vf)
		var pxf: Transform3D = prev["xf"]
		var vxf: Transform3D = v["xf"]
		var turn := rad_to_deg((-pxf.basis.z).angle_to(-vxf.basis.z))
		var zoom := absf(log(float(v["size"]) / float(prev["size"])))
		worst_step = maxf(worst_step, step)
		worst_turn = maxf(worst_turn, turn)
		worst_zoom = maxf(worst_zoom, zoom)
		if float(v["size"]) > float(prev["size"]) + 0.001:
			_fail("%s: frame %d zooms out (%.1f → %.1f m)" % [label, i, prev["size"], v["size"]])
		if vf.y < ground - 0.5:
			_fail("%s: frame %d's centre is under the ground (%.1f)" % [label, i, vf.y])
		if (i == 1 or i == frames) and step > 0.5:
			_fail("%s: frame %d moves %.2f m (not eased at the ends)" % [label, i, step])
		prev = v
	if worst_step > MAX_STEP:
		_fail("%s: a frame moves the view %.1f m (at most %.1f)" % [label, worst_step, MAX_STEP])
	if worst_turn > MAX_TURN:
		_fail("%s: a frame turns the view %.2f° (at most %.1f)" % [label, worst_turn, MAX_TURN])
	if worst_zoom > MAX_ZOOM:
		_fail("%s: a frame zooms %.1f%% (at most %.0f%%)" % [label, worst_zoom * 100.0, MAX_ZOOM * 100.0])
	print("opening: %s: at most %.2f m, %.2f°, %.1f%% a frame" % [label, worst_step, worst_turn, worst_zoom * 100.0])


func _morning(grade: String) -> void:
	var looks := TimeOfDay.build_looks(grade, -50.0)
	var day: Dictionary = looks[TimeOfDay.DAY]
	var night: Dictionary = looks[TimeOfDay.NIGHT]
	var frames := int(ceil(Shots.OPEN_TIME * FPS))
	var first := TimeOfDay.morning(looks, 0.0)
	var last := TimeOfDay.morning(looks, 1.0)
	for key in day:
		if not _same_value(last[key], day[key]):
			_fail("%s: the morning's last frame is not the Day look (%s: %s, not %s)" % [grade, key, last[key], day[key]])
		if not _same_value(first[key], night[key]):
			_fail("%s: the morning's first frame is not the Night look (%s)" % [grade, key])
	var ground := 2.0
	var car := Vector3(First10.START.x, ground, First10.START.y)
	var basis := Basis.from_euler(Vector3(deg_to_rad(-30.0), deg_to_rad(First10.START_HEADING), 0.0))
	var follow_xf := Transform3D(basis, car + basis.z * Shots._distance(80.0))
	var prev := first
	var worst := 0.0
	for i in range(1, frames + 1):
		var e := float(i) / frames
		var t := e * Shots.OPEN_TIME
		var v := TimeOfDay.morning(looks, e)
		var dl := float(v["lights_on"]) - float(prev["lights_on"])
		worst = maxf(worst, absf(dl))
		if dl > 0.0001:
			_fail("%s: at %.2f s the lights come back on (%.3f → %.3f)" % [grade, t, prev["lights_on"], v["lights_on"]])
		if float(v["daylight"]) < float(prev["daylight"]) - 0.0001:
			_fail("%s: at %.2f s the daylight goes down" % [grade, t])
		var size := float(Shots.open_view(e, ground, First10.START_HEADING, follow_xf, 80.0)["size"])
		if float(v["shadows"]) > 0.02 and size > SHADOW_WIDE + 0.5:
			_fail("%s: at %.2f s the shadows are on (%.2f) at a %.0f m view (wider than %.0f)" % [grade, t, v["shadows"], size, SHADOW_WIDE])
		if t <= GREETING_END and float(v["lights_on"]) < float(night["lights_on"]) - 0.001:
			_fail("%s: the night is gone at %.2f s, during the host's greeting" % [grade, t])
		prev = v
	if worst > MAX_LIGHT_STEP:
		_fail("%s: a frame changes the lights by %.3f (at most %.2f)" % [grade, worst, MAX_LIGHT_STEP])
	var weather := TimeOfDay.morning(looks, WEATHER_END / Shots.OPEN_TIME)
	if float(weather["lights_on"]) > 0.85:
		_fail("%s: the lamps are still on (%.2f) when the weather line ends" % [grade, weather["lights_on"]])
	var sunrise := TimeOfDay.morning(looks, (WEATHER_END + MARSZ_END) * 0.5 / Shots.OPEN_TIME)
	if float(sunrise["shadows"]) < 0.5:
		_fail("%s: no sunrise shadows during the Marszałkowska line (%.2f)" % [grade, sunrise["shadows"]])
	var landing := TimeOfDay.morning(looks, (Shots.OPEN_TIME - 0.5) / Shots.OPEN_TIME)
	if float(landing["lights_on"]) > 0.001 or float(landing["daylight"]) < 0.999:
		_fail("%s: half a second before the landing it is not day yet" % grade)
	print("opening: morning (%s): lights at most %.3f a frame, lamps %.2f after the weather line, shadows %.2f at the sunrise" % [
			grade, worst, weather["lights_on"], sunrise["shadows"]])


func _same_value(a: Variant, b: Variant) -> bool:
	if a is float:
		return absf(float(a) - float(b)) < 0.0001
	if a is Color:
		return (a as Color).is_equal_approx(b)
	if a is Vector3:
		return (a as Vector3).is_equal_approx(b)
	return a == b


func _same_basis(a: Basis, b: Basis) -> bool:
	return a.x.distance_to(b.x) < 0.001 and a.y.distance_to(b.y) < 0.001 and a.z.distance_to(b.z) < 0.001


func _fail(why: String) -> void:
	_problems += 1
	print("opening: " + why)
