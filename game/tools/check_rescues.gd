extends SceneTree
## DEMO 6.3 (the second słoiki station and the Łazienki peacock rescue), headless, from the
## committed map data (map/centrum.json) and data/dialogue.json, no city needed:
##   - Dworzec Gdański (jobs.gd GDANSKI) lies inside the map, its hall is a mapped landmark, a
##     street of the map passes within the kerb search's 30 m of its door, and enough flats of its
##     Muranów box lie in the order's road window (the straight-line prefilter of `_pick_address`);
##     the Centralny station's Powiśle still has plenty;
##   - the peacock has a roof: one of rescue_places.gd PEACOCK_ROOFS is a mapped landmark, else a
##     landmark stands within PEACOCK_NEAR of PEACOCK_ANCHOR;
##   - the lines: each station has słoiki start lines of its own (tags centralny, gdanski) and the
##     peacock has rescue lines (tag peacock) for the pick-up and the hand-over, Polish and English.
## Prints `check_rescues: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_rescues.gd

const Jobs := preload("res://scripts/jobs.gd")
const RescuePlaces := preload("res://scripts/rescue_places.gd")

var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	await process_frame
	var path := "res://map/centrum.json"
	if not FileAccess.file_exists(path):
		path = "res://map/index.json"
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		print("check_rescues: no map data (%s)" % path)
		quit(1)
		return
	var flats := _check_stations(data)
	var roof := _check_peacock(data)
	_check_lines()
	if problems.is_empty():
		print("check_rescues: OK (Gdański: %d Muranów flats in the window; peacock: %s)" % [flats, roof])
		quit(0)
	else:
		for p in problems:
			print("check_rescues: FAIL " + p)
		quit(1)


func _check_stations(data: Dictionary) -> int:
	var g: Dictionary = Jobs.GDANSKI
	var door := Vector2(g["door"][0], g["door"][1])
	var b: Array = data["bounds"]
	_expect(door.x > b[0] and door.x < b[2] and door.y > b[1] and door.y < b[3], "Gdański's door is outside the map")
	var hall := false
	for l in data["landmarks"]:
		if String(l["name"]).begins_with("Dworzec Warszawa Gda"):
			hall = true
	_expect(hall, "no landmark for the Gdańska hall")
	var street := INF
	for r in data["roads"]:
		if r["k"] in ["service", "footway", "path", "steps"] or String(r["name"]) == "":
			continue
		var p: Array = r["p"]
		for i in range(0, p.size() - 3, 2):
			var a := Vector2(p[i], p[i + 1])
			var c := Vector2(p[i + 2], p[i + 3])
			street = minf(street, door.distance_to(Geometry2D.get_closest_point_to_segment(door, a, c)))
	_expect(street <= 30.0, "no street within 30 m of Gdański's door (%.0f m)" % street)
	var from := Vector2(g["x"], g["z"])
	var box: Array = g["box"]
	var lo: float = g["lo"]
	var hi: float = g["hi"]
	var muranow := 0
	var powisle := 0
	var centralny := Vector2(-1400.2, 639.9)
	var c_lo: float = Jobs.CENTRALNY_DEST["lo"]
	var c_hi: float = Jobs.CENTRALNY_DEST["hi"]
	for p: Dictionary in data["pois"]:
		if p["k"] != "address" or p.has("o"):
			continue
		var at := Vector2(p["x"], p["z"])
		var d := Vector2(p["door"][0], p["door"][1])
		if at.x >= box[0] and at.y >= box[1] and at.x <= box[2] and at.y <= box[3]:
			var s := d.distance_to(from)
			if s >= lo * 0.55 and s <= hi:
				muranow += 1
		if String(p.get("d", "")) == "powisle":
			var s2 := d.distance_to(centralny)
			if s2 >= c_lo * 0.55 and s2 <= c_hi:
				powisle += 1
	_expect(muranow >= 30, "only %d Muranów flats for Gdański's window" % muranow)
	_expect(powisle >= 30, "only %d Powiśle flats for Centralny's window" % powisle)
	_expect(lo < hi and String(g["tag"]) != String(Jobs.CENTRALNY_DEST["tag"]), "the stations' tags or windows are wrong")
	return muranow


func _check_peacock(data: Dictionary) -> String:
	var names := {}
	var near := ""
	for l in data["landmarks"]:
		names[String(l["name"])] = true
		var p: Array = l["p"]
		if p.size() >= 2 and Vector2(p[0], p[1]).distance_to(RescuePlaces.PEACOCK_ANCHOR) < RescuePlaces.PEACOCK_NEAR and near == "":
			near = String(l["name"])
	for n in RescuePlaces.PEACOCK_ROOFS:
		if names.has(n):
			return n
	_expect(near != "", "no landmark near the peacock's anchor and none of PEACOCK_ROOFS is mapped")
	return near


func _check_lines() -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	if not d is Dictionary:
		problems.append("data/dialogue.json unreadable")
		return
	_lines(d, "sloik_start", "centralny", 1)
	_lines(d, "sloik_start", "gdanski", 2)
	_lines(d, "rescue_person", "peacock", 2)
	_lines(d, "rescue_done", "peacock", 1)


## At least `want` lines of group `group` limited to `tag`, each with Polish and English text.
func _lines(d: Dictionary, group: String, tag: String, want: int) -> void:
	var n := 0
	for l: Array in d.get(group, []):
		if l.size() < 3 or not l[2] is Dictionary or l[2].get("only", "") != tag:
			continue
		n += 1
		_expect(String(l[0]).length() > 3 and String(l[1]).length() > 3, "%s/%s has an empty line" % [group, tag])
	_expect(n >= want, "%s has %d lines for %s, want %d" % [group, n, tag, want])
