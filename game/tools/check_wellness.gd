extends SceneTree
## Wellness circles (docs/design/city-life-satire.md ideas 2, 3, 4, 8): scripts/wellness.gd's hours,
## layouts, spots on the real map, meshes, lines and drawing, headless, from the committed map data
## (map/centrum.json) and data/dialogue.json:
##   1. the hours: the Day look (Friday 14:00) has two or more spots on, the Night look (01:30)
##      none; every spot has weekday and weekend hours; the counts (--crowd scale, --wellness-now);
##   2. the layouts: a leader first, figures 0.55 m apart or more, within 4.5 m of the spot's
##      centre, the right number; the women's circle keeps its radius while it turns, the kung-fu
##      school dips on the beat of its form;
##   3. the real map: every spot is on grass, a park or a plaza, clear of buildings, roads and water;
##   4. the meshes (props ≤ 6,000 vertices, the hamster ball a sphere of rings);
##   5. the lines: the four groups, the `leader` and `car` tags, ≤ 70 characters in Polish, no real
##      brand (data/brand_denylist.json), the jokes' keywords used;
##   6. a node on the real spots with --wellness-now: drawn near the view, nothing far, the props
##      only near, the lines spoken, the cost of a worst-case animation tick.
## Prints "check_wellness: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_wellness.gd [-- --verbose]

const Wellness := preload("res://scripts/wellness.gd")
const Crowds := preload("res://scripts/crowds.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const Fakes := preload("res://tools/fakes.gd")


var problems: Array[String] = []
var now := {"hour": 14.0, "weekday": 5}
var eye := Vector3.ZERO


func _initialize() -> void:
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_hours(digest)
	_check_layouts(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	_check_real_map(data, digest)
	_check_meshes(digest)
	_check_lines(digest)
	await _check_node(digest)
	if problems.is_empty():
		print("check_wellness: OK (%s)" % "; ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("check_wellness: %s" % p)
		quit(1)


func _on_count(hour: float, weekday: int) -> int:
	var n := 0
	for id: String in Wellness.SPOTS:
		if Wellness.spot_count(Wellness.SPOTS[id], hour, weekday) > 0:
			n += 1
	return n


# 1. -------------------------------------------------------------------------------------------

func _check_hours(digest: PackedStringArray) -> void:
	var day := TimeOfDay.look_clock("Day", 0.0)
	var on := _on_count(day["hour"], day["weekday"])
	_expect(on >= 2, "the Day look (Friday 14:00) has %d wellness spots on (want 2 or more)" % on)
	var night := TimeOfDay.look_clock("Night", 0.0)
	_expect(_on_count(night["hour"], night["weekday"]) == 0, "the Night look has wellness spots out")
	var kinds := {}
	for id: String in Wellness.SPOTS:
		var spec: Dictionary = Wellness.SPOTS[id]
		kinds[spec["kind"]] = true
		var wk := false
		var we := false
		for h in range(0, 96):
			wk = wk or Wellness.spot_on(spec["hours"], h * 0.25, 2)
			we = we or Wellness.spot_on(spec["hours"], h * 0.25, 6)
		_expect(wk and we, "%s has no weekday or no weekend hours" % id)
		# Daylight only: nothing before 07:00 or after 20:00.
		for h in range(0, 96):
			var hour := h * 0.25
			for wd in [2, 6]:
				if Wellness.spot_on(spec["hours"], hour, wd):
					_expect(hour >= 7.0 and hour < 20.0, "%s is on at %.2f" % [id, hour])
		_expect(Wellness.KINDS.has(spec["kind"]), "%s: the kind '%s' has no KINDS row" % [id, spec["kind"]])
	for k in ["sound", "techno", "club", "kungfu"]:
		_expect(kinds.has(k), "no spot of kind '%s'" % k)
	var sw: Dictionary = Wellness.SPOTS["sound_swietokrzyski"]
	_expect(Wellness.spot_count(sw, 13.0, 3) == int(sw["max"]), "a lunchtime sound-healing session has %d people" % Wellness.spot_count(sw, 13.0, 3))
	_expect(Wellness.spot_count(sw, 13.0, 3, 0.5) == roundi(int(sw["max"]) * 0.5), "the Low tier doesn't halve a session")
	_expect(Wellness.spot_count(sw, 3.0, 3) == 0, "a session is on at 03:00")
	_expect(Wellness.spot_count(sw, 3.0, 3, 1.0, true) == int(sw["max"]), "--wellness-now doesn't put a session on at 03:00")
	digest.append("Day look: %d spots, Night look 0" % on)


# 2. -------------------------------------------------------------------------------------------

func _check_layouts(digest: PackedStringArray) -> void:
	for kind in ["sound", "techno", "club", "kungfu"]:
		var n := 10
		var rows := Wellness.layout(kind, n, 7)
		_expect(rows.size() == n, "%s: %d figures (want %d)" % [kind, rows.size(), n])
		var leader: Array = rows[0]
		_expect(Color(leader[3]) != Color.WHITE or kind == "sound", "%s: the leader is not set apart" % kind)
		for i in rows.size():
			var a: Vector2 = rows[i][0]
			_expect(a.length() <= 4.5, "%s: figure %d is %.1f m from the centre" % [kind, i, a.length()])
			for j in range(i + 1, rows.size()):
				var d := a.distance_to(rows[j][0])
				_expect(d >= 0.55, "%s: figures %d and %d stand %.2f m apart" % [kind, i, j, d])
		# Few people: the leader and the first two.
		_expect(Wellness.layout(kind, 3, 7).size() == 3, "%s: three figures aren't three" % kind)
		# The animation keeps the figures where they belong at any time.
		for tt in [0.0, 1.3, 6.0, 11.9, 400.0]:
			for k in rows.size():
				var ps := Wellness.pose_at(kind, rows[k], k, rows.size(), tt)
				_expect((ps[0] as Vector2).length() <= 4.5, "%s: figure %d wanders %.1f m at t=%.1f" % [kind, k, (ps[0] as Vector2).length(), tt])
				_expect(absf(float(ps[2])) < 0.5, "%s: figure %d is %.2f m off the ground at t=%.1f" % [kind, k, ps[2], tt])
	# The circle turns but keeps its radius; the school dips together mid-form.
	var circle := Wellness.layout("club", 10, 7)
	for k in range(1, 10):
		var p0: Vector2 = Wellness.pose_at("club", circle[k], k, 10, 0.0)[0]
		var p1: Vector2 = Wellness.pose_at("club", circle[k], k, 10, 9.0)[0]
		_expect(is_equal_approx(p0.length(), 2.4) and is_equal_approx(p1.length(), 2.4), "the circle changes its radius")
		_expect(p0.distance_to(p1) > 0.1, "the circle doesn't turn")
	var school := Wellness.layout("kungfu", 10, 7)
	var dip: float = Wellness.pose_at("kungfu", school[3], 3, 10, Wellness.FORM * 0.5)[2]
	_expect(dip < -0.1, "the school doesn't dip mid-form (%.2f)" % dip)
	digest.append("layouts ok for 4 kinds")


# 3. -------------------------------------------------------------------------------------------

func _poly(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in flat.size() / 2:
		out.append(Vector2(float(flat[i * 2]), float(flat[i * 2 + 1])))
	return out


func _box_near(pts: PackedVector2Array, p: Vector2, r: float) -> bool:
	var lo := pts[0]
	var hi := pts[0]
	for q in pts:
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	return p.x > lo.x - r and p.x < hi.x + r and p.y > lo.y - r and p.y < hi.y + r


func _seg_dist(p: Vector2, pts: PackedVector2Array, closed: bool) -> float:
	var best := INF
	for i in pts.size() - (0 if closed else 1):
		var q := Geometry2D.get_closest_point_to_segment(p, pts[i], pts[(i + 1) % pts.size()])
		best = minf(best, q.distance_to(p))
	return best


func _check_real_map(data: Dictionary, digest: PackedStringArray) -> void:
	var worst := 99.0
	for id: String in Wellness.SPOTS:
		var spec: Dictionary = Wellness.SPOTS[id]
		var at: Vector2 = spec["at"]
		var need := 3.5
		var open := false
		var wet := false
		for a: Dictionary in data.get("areas", []):
			var k := str(a.get("k", ""))
			if k != "grass" and k != "park" and k != "plaza" and k != "water" and k != "pitch":
				continue
			var pts := _poly(a["p"])
			if pts.size() < 3 or not _box_near(pts, at, 1.0):
				continue
			if Geometry2D.is_point_in_polygon(at, pts):
				if k == "water" or k == "pitch":
					wet = true
				else:
					open = true
		_expect(open, "%s is not on grass, a park or a plaza" % id)
		_expect(not wet, "%s is on water or a pitch" % id)
		var clear := 99.0
		for b: Dictionary in data.get("buildings", []):
			var pts := _poly(b["p"])
			if pts.size() < 3 or not _box_near(pts, at, need + 8.0):
				continue
			if Geometry2D.is_point_in_polygon(at, pts):
				clear = 0.0
			clear = minf(clear, _seg_dist(at, pts, true))
		_expect(clear >= need + 1.0, "%s is %.1f m from a building (want %.1f)" % [id, clear, need + 1.0])
		worst = minf(worst, clear)
		for r: Dictionary in data.get("roads", []):
			if bool(r.get("bridge", false)):
				continue
			var pts := _poly(r["p"])
			if pts.size() < 2 or not _box_near(pts, at, need + 12.0):
				continue
			var d := _seg_dist(at, pts, false) - float(r.get("w", 5.0)) * 0.5
			_expect(d >= need, "%s is %.1f m from the edge of a road (want %.1f)" % [id, d, need])
	digest.append("%d spots on open ground, %.1f m clear of buildings at the least" % [Wellness.SPOTS.size(), worst])


# 4. -------------------------------------------------------------------------------------------

func _check_meshes(digest: PackedStringArray) -> void:
	var biggest := 0
	for kind in ["sound", "techno", "club", "kungfu"]:
		var m := Wellness.props_mesh(kind)
		var v := 0
		for s in m.get_surface_count():
			v += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		_expect(v > 200 and v <= 6000, "%s props have %d vertices" % [kind, v])
		biggest = maxi(biggest, v)
	var ball := Wellness.ball_mesh()
	_expect(ball.get_surface_count() == 1, "the ball isn't one surface")
	var bb := ball.get_aabb()
	_expect(absf(bb.size.x - 2.0 * Wellness.BALL_R) < 0.12 and absf(bb.size.y - 2.0 * Wellness.BALL_R) < 0.12, "the ball isn't a sphere of radius %.2f (%s)" % [Wellness.BALL_R, bb.size])
	var ham := Wellness.hamster_mesh().get_aabb()
	_expect(ham.size.length() < 2.0 * Wellness.BALL_R and ham.size.length() > 0.1, "the hamster doesn't fit in its ball (%s)" % ham.size)
	digest.append("props ≤ %d vertices" % biggest)


# 5. -------------------------------------------------------------------------------------------

func _check_lines(digest: PackedStringArray) -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var names: Array = (deny["names"] as Array) + (deny["rejected"] as Array)
	var want := {"sound_healing": {"": 8, "leader": 3, "car": 2}, "techno_yoga": {"": 8, "leader": 3, "car": 2},
			"club_40": {"": 8, "leader": 3, "car": 2}, "park_kungfu": {"": 7, "leader": 3, "car": 2}}
	var all_text := ""
	for kind: String in Wellness.KINDS:
		_expect(want.has(Wellness.KINDS[kind]["group"]), "KINDS '%s' uses an unchecked group" % kind)
	for g: String in want:
		_expect(d.has(g), "dialogue.json has no '%s'" % g)
		var counts := {}
		for l: Array in d.get(g, []):
			var tag := ""
			if l.size() > 2:
				tag = str((l[2] as Dictionary).get("only", ""))
			counts[tag] = int(counts.get(tag, 0)) + 1
			_expect(str(l[0]).length() <= 70, "%s: a Polish line of %d characters" % [g, str(l[0]).length()])
			_expect(str(l[1]) != "", "%s: a line without English" % g)
			_expect(not str(l[0]).contains("&") and not str(l[1]).contains("&"), "%s: a line with '&'" % g)
			all_text += " " + str(l[0]).to_lower() + " " + str(l[1]).to_lower()
		for tag: String in want[g]:
			_expect(int(counts.get(tag, 0)) >= int(want[g][tag]), "%s has %d '%s' lines (want %d)" % [g, int(counts.get(tag, 0)), tag, want[g][tag]])
	var rx := RegEx.new()
	for n: String in names:
		rx.compile("(^|[^\\p{L}])" + n.replace(".", "\\.") + "($|[^\\p{L}])")
		_expect(rx.search(all_text) == null, "a wellness line names '%s'" % n)
	for joke in ["gong", "chomik", "dziewczynk", "gołąb", "80", "hula"]:
		_expect(all_text.contains(joke) or joke == "80", "no line uses '%s'" % joke)
	digest.append("lines: %d groups, no real brand" % want.size())


# 6. -------------------------------------------------------------------------------------------

func _check_node(digest: PackedStringArray) -> void:
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var dlg := Fakes.Dialogue.new()
	dlg.say_words = ["x", "x"]
	root.add_child(dlg)
	var w := Wellness.new()
	w.map = map
	w.dialogue = dlg
	w.force = true
	w.clock = func() -> Dictionary: return now
	w.focus = func() -> Vector3: return eye
	w.vehicle = func() -> Array: return [Vector3.INF, 0.0, false]
	root.add_child(w)
	w.setup()
	_expect(w.spots.size() == Wellness.SPOTS.size(), "%d of %d spots built" % [w.spots.size(), Wellness.SPOTS.size()])
	# Far from everything: nothing drawn, no props.
	eye = Vector3(5000, 0, 5000)
	w.tick(0.5)
	w.animate()
	_expect(not w._people_mmi.visible and not w._ball_mmi.visible, "figures drawn 5 km from the view")
	for s: Dictionary in w.spots:
		_expect(not (s["props"] as MeshInstance3D).visible, "%s: props shown 5 km away" % s["id"])
	# At each spot: its people drawn, its props shown, the others' props hidden if far.
	var worst_hamsters := 0
	for s: Dictionary in w.spots:
		var a: Vector3 = s["at"]
		eye = a
		w.tick(0.5)
		w.animate()
		var near := 0
		for o: Dictionary in w.spots:
			if bool(o["near"]):
				near += int(o["n"])
		_expect(bool(s["near"]), "%s at the view isn't near" % s["id"])
		_expect((s["props"] as MeshInstance3D).visible, "%s: props hidden at the view" % s["id"])
		_expect(w._people_mm.visible_instance_count == near, "%s: %d figures drawn (want %d)" % [s["id"], w._people_mm.visible_instance_count, near])
		_expect(int(s["n"]) == int((s["spec"] as Dictionary)["max"]), "%s has %d with --wellness-now" % [s["id"], s["n"]])
		if s["kind"] == "techno":
			_expect(w._ball_mm.visible_instance_count >= Wellness.HAMSTERS, "%s: %d hamster balls" % [s["id"], w._ball_mm.visible_instance_count])
			worst_hamsters = maxi(worst_hamsters, w._ball_mm.visible_instance_count)
		else:
			_expect(w._ball_mm.visible_instance_count == 0 or near > int(s["n"]), "%s: hamster balls at a spot with none" % s["id"])
	# The lines: on screen near the view, a spot speaks within LINE_GAP.
	eye = (w.spots[0]["at"] as Vector3)
	var before := dlg.said.size()
	for i in 120:
		w.t += 0.5
		w.tick(0.5)
	_expect(dlg.said.size() > before, "a spot at the view said nothing in a minute")
	var tags := {}
	for i in dlg.said.size():
		tags[str(dlg.tags[i])] = true
	# A slow car at a spot: the `car` lines.
	var car_at: Vector3 = (w.spots[0]["at"] as Vector3) + Vector3(4, 0, 0)
	w.vehicle = func() -> Array: return [car_at, 5.0, false]
	before = dlg.said.size()
	var car_lines := 0
	for i in 200:
		w.t += 0.5
		w.tick(0.5)
	for k in range(before, dlg.said.size()):
		if str(dlg.tags[k]) == "car":
			car_lines += 1
	_expect(car_lines > 0, "a slow car at a spot hears no `car` line in 100 s")
	_expect(w.meets >= 1, "the car at a spot meets nobody")
	# The cost: every spot near (the worst case), averaged.
	for s: Dictionary in w.spots:
		s["near"] = true
	var t0 := Time.get_ticks_usec()
	for i in 60:
		w.t += Wellness.ANIM_TICK
		w.animate()
	var us := (Time.get_ticks_usec() - t0) / 60.0
	_expect(us < 2500.0, "an animation tick of every spot takes %.0f µs" % us)
	digest.append("node: %d spots, %d hamster balls near a techno spot, %d lines, worst tick %.0f µs" % [w.spots.size(), worst_hamsters, dlg.said.size(), us])
	w.queue_free()
	map.queue_free()
