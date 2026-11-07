extends SceneTree
## 11 listopada (scripts/event_day.gd), headless, from the committed map data (map/centrum.json):
##   1. the hours: nobody before 10:00, rising to full by 13:00, full to 18:30, thin after 21:00;
##   2. the zone: the rondo's centre, both corridors' ends and the Palace-side kick depth are in,
##      a point past each barrier line, a side street's far end and the Palace itself are out;
##   3. the four barrier lines stand on the zone's edge, each on a mapped road of the corridor;
##   4. the crowd's roads: Al. Jerozolimskie and Marszałkowska segments exist inside the zone;
##   5. the flag mesh has both colours, the date gate is 11 November only on the live calendar
##      and `force` turns it on for any date.
## Prints "check_event_day: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_event_day.gd

const EventDay := preload("res://scripts/event_day.gd")

var _fails: Array[String] = []


func _initialize() -> void:
	_hours()
	_zone()
	var data := _load()
	_lines(data)
	_gate()
	_flag()
	if _fails.is_empty():
		print("check_event_day: OK (hours, zone, %d barrier lines, gate, flag)" % EventDay.cordon().size())
		quit(0)
	else:
		for f in _fails:
			printerr("check_event_day: " + f)
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _hours() -> void:
	_expect(EventDay.crowd_share(8.0) == 0.0, "no crowd at 08:00")
	_expect(EventDay.crowd_share(10.0) == 0.0, "crowd starts after 10:00")
	_expect(EventDay.crowd_share(11.5) > 0.3 and EventDay.crowd_share(11.5) < 0.7, "half a crowd at 11:30")
	_expect(EventDay.crowd_share(15.0) == 1.0 and EventDay.crowd_share(18.5) == 1.0, "full crowd 13:00-18:30")
	_expect(EventDay.crowd_share(21.5) <= 0.15, "thin crowd at 21:30")
	_expect(EventDay.crowd_share(23.5) == 0.0, "no crowd after 23:00")


func _zone() -> void:
	_expect(EventDay.in_zone(EventDay.C), "the rondo's centre is in the zone")
	_expect(EventDay.in_zone(EventDay.from_vu(300.0, 0.0)), "mid corridor is in")
	_expect(EventDay.in_zone(EventDay.from_vu(0.0, 60.0)), "Marszałkowska arm is in")
	_expect(not EventDay.in_zone(EventDay.from_vu(EventDay.V_EAST + 5.0, 0.0)), "past the east barrier is out")
	_expect(not EventDay.in_zone(EventDay.from_vu(EventDay.V_WEST - 5.0, 0.0)), "past the west barrier is out")
	_expect(not EventDay.in_zone(EventDay.from_vu(0.0, EventDay.ARM + 5.0)), "past the south barrier is out")
	_expect(not EventDay.in_zone(EventDay.from_vu(0.0, -EventDay.ARM - 5.0)), "past the north barrier is out")
	_expect(not EventDay.in_zone(EventDay.from_vu(300.0, 80.0)), "a side street's far end is out")
	_expect(not EventDay.in_zone(EventDay.PALACE_AT), "the Palace is out of the zone")
	var p := EventDay.from_vu(123.4, -17.0)
	var q := EventDay.to_vu(p)
	_expect(absf(q.x - 123.4) < 0.5 and absf(q.y + 17.0) < 0.5, "the corridor frame round-trips")


func _load() -> Dictionary:
	var f := FileAccess.open("res://map/centrum.json", FileAccess.READ)
	if f == null:
		_fails.append("map/centrum.json missing")
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


func _lines(data: Dictionary) -> void:
	if data.is_empty():
		return
	var road_ends := 0
	var jer := 0
	var mar := 0
	for r: Dictionary in data["roads"]:
		var nm := str(r.get("name", ""))
		var flat: Array = r["p"]
		for i in range(0, flat.size() - 1, 2):
			var p := Vector2(flat[i], flat[i + 1])
			if EventDay.in_zone(p, 4.0):
				if nm == "Aleje Jerozolimskie":
					jer += 1
				elif nm == "Marszałkowska":
					mar += 1
	_expect(jer > 20, "Al. Jerozolimskie has road points in the zone (%d)" % jer)
	_expect(mar > 5, "Marszałkowska has road points in the zone (%d)" % mar)
	for c: Dictionary in EventDay.cordon():
		var at: Vector2 = c["at"]
		var near := false
		for r: Dictionary in data["roads"]:
			var nm := str(r.get("name", ""))
			if not (nm == "Aleje Jerozolimskie" or nm == "Marszałkowska"):
				continue
			var flat: Array = r["p"]
			for i in range(0, flat.size() - 1, 2):
				if Vector2(flat[i], flat[i + 1]).distance_to(at) < 40.0:
					near = true
					break
			if near:
				break
		_expect(near, "barrier %s has the corridor's road within 40 m (%s)" % [c["id"], str(at)])
		road_ends += 1
	_expect(road_ends == 4, "four barrier lines")


func _gate() -> void:
	var e := EventDay.new()
	e.calendar = func() -> Dictionary: return {"live": true, "date": 20261111}
	_expect(e.active(), "11 November live: on")
	e.calendar = func() -> Dictionary: return {"live": true, "date": 20261110}
	_expect(not e.active(), "10 November: off")
	e.calendar = func() -> Dictionary: return {"live": false, "date": 0}
	_expect(not e.active(), "a fixed look: off")
	e.force = true
	_expect(e.active(), "--event-day forces it on")
	e.free()


func _flag() -> void:
	var m := EventDay.flag_mesh()
	var arr := m.surface_get_arrays(0)
	var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
	var white := false
	var red := false
	for c in cols:
		if c.is_equal_approx(EventDay.WHITE):
			white = true
		if c.is_equal_approx(EventDay.RED):
			red = true
	_expect(white and red, "the flag has a white and a red half")
