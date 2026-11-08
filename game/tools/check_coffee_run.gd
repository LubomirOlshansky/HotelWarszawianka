extends SceneTree
## "Kawowy rajd" · the coffee run (docs/design/coffee-run.md, scripts/coffee_run.gd, trend_job.gd
## kind "kawa", car.gd model "bike"), headless, from the committed map data (map/centrum.json):
##   1. the words: no real brand (data/brand_denylist.json, whole words, lower case) anywhere in
##      coffee_run.gd or trend_job.gd's coffee-run section; every ride and stamp line PL + EN, the
##      Polish ≤ 70 characters; the quest map's in-person lines (HELLO, CLOSED) PL + EN;
##   2. the places: the dock is a real ROWERILO dock (pois `bicycle_rental`, within 1 m), each café
##      door a real address door (pois `address`, within 2 m) or its notebook place, each within
##      30 m of a road or a path, every leg ≤ 600 m and the loop ≤ 2.2 km (the stops close
##      together, F's ask), and the clock fair: the loop by road (×1.4) at the bike's top speed
##      plus the stamps fits in 85 % of COFFEE_LIMIT;
##   3. the money: the four coffees overpriced (each 24-40 zł), the on-time BLIK returns the bill
##      plus THANKS, late half the bill and no respect;
##   4. the bike: car.gd model "bike" caps the top speed at BIKE_TOP (below a third of the car's)
##      and back to the car's after; the player's bike meshes (3, the body ≤ 800 triangles, about
##      2.9 m tall at 1.6x).
## Prints "check_coffee_run: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_coffee_run.gd

const CoffeeRun := preload("res://scripts/coffee_run.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Models := preload("res://scripts/models.gd")
const Car := preload("res://scripts/car.gd")

var problems: Array[String] = []


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	_words()
	var loop := _places()
	_money()
	_bike()
	if problems.is_empty():
		print("check_coffee_run: OK (%d stops, loop %.0f m, bill %d zł, %d ms)" % [CoffeeRun.STOPS.size(), loop, CoffeeRun.bill(),
				Time.get_ticks_msec() - t0])
		quit(0)
	else:
		for p in problems:
			print("check_coffee_run: " + p)
		quit(1)


func _words() -> void:
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var names: Array = deny.get("names", []) + deny.get("rejected", [])
	var src := FileAccess.get_file_as_string("res://scripts/coffee_run.gd")
	var tj := FileAccess.get_file_as_string("res://scripts/trend_job.gd")
	var a := tj.find("# --- \"Kawowy rajd\"")
	var b := tj.find("## --autopilot: the car slides")
	if a < 0 or b < a:
		problems.append("trend_job.gd has no coffee-run section")
	else:
		src += tj.substr(a, b - a)
	var low := src.to_lower()
	for n: String in names:
		var re := RegEx.create_from_string("(?<![\\p{L}\\p{N}])" + _escape(n.to_lower()) + "(?![\\p{L}\\p{N}])")
		var m := re.search(low)
		if m != null:
			problems.append("real brand \"%s\" in the coffee run's text" % n)
	var lines: Array = CoffeeRun.RIDE_LINES.duplicate()
	for st: Dictionary in CoffeeRun.STOPS:
		lines.append(st["line"])
		lines.append(st["drink"])
	for l: Array in lines:
		if l.size() != 2 or str(l[0]).is_empty() or str(l[1]).is_empty():
			problems.append("a line without PL + EN: %s" % [l])
		elif str(l[0]).length() > 70:
			problems.append("Polish line over 70 characters: %s" % l[0])
	for l: Array in [CoffeeRun.HELLO, CoffeeRun.CLOSED]:
		if l.size() != 2 or str(l[0]).is_empty() or str(l[1]).is_empty():
			problems.append("Zuzia's in-person line without PL + EN: %s" % [l])
	if CoffeeRun.call_text().size() != 3:
		problems.append("the call card needs a title and both bodies")


static func _escape(s: String) -> String:
	var out := ""
	for c in s:
		out += ("\\" + c) if ".^$*+?()[]{}|\\/-".contains(c) else c
	return out


func _places() -> float:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var pois: Array = data.get("pois", [])
	var docks: Array[Vector2] = []
	var doors: Array[Vector2] = []
	for p: Dictionary in pois:
		if p.get("k") == "bicycle_rental":
			docks.append(Vector2(float(p["x"]), float(p["z"])))
		elif p.get("k") == "address" and p.has("door"):
			doors.append(Vector2(float(p["door"][0]), float(p["door"][1])))
	if not docks.any(func(d: Vector2) -> bool: return d.distance_to(CoffeeRun.DOCK) < 1.0):
		problems.append("the dock %s is no ROWERILO dock on the map" % CoffeeRun.DOCK)
	var nb := Notebook.new()
	var places := {}
	if nb.setup(data):
		for p: Dictionary in nb.places:
			places[str(p["id"])] = p["at"]
	nb.free()
	var lines: Array[PackedVector2Array] = []
	for key in ["roads", "paths"]:
		for r: Dictionary in data.get(key, []):
			var pts: Array = r["p"]
			var pl := PackedVector2Array()
			for i in range(0, pts.size() - 1, 2):
				pl.append(Vector2(float(pts[i]), float(pts[i + 1])))
			lines.append(pl)
	var route: Array[Vector2] = [CoffeeRun.DOCK]
	for i in CoffeeRun.STOPS.size():
		var st: Dictionary = CoffeeRun.STOPS[i]
		var at := CoffeeRun.stop_at(i, places)
		if at == Vector2.INF:
			problems.append("%s has no position" % st["name"])
			continue
		if st["door"] != Vector2.INF and not doors.any(func(d: Vector2) -> bool: return d.distance_to(at) < 2.0):
			problems.append("%s's door %s is no address door" % [st["name"], at])
		var near := INF
		for pl in lines:
			for k in pl.size() - 1:
				near = minf(near, at.distance_to(Geometry2D.get_closest_point_to_segment(at, pl[k], pl[k + 1])))
		if near > 30.0:
			problems.append("%s is %.0f m from any road or path" % [st["name"], near])
		route.append(at)
	route.append(CoffeeRun.DOCK)
	var total := 0.0
	for i in route.size() - 1:
		var leg := route[i].distance_to(route[i + 1])
		total += leg
		if leg > 600.0:
			problems.append("leg %d is %.0f m (the stops should be close)" % [i, leg])
	if total > 2200.0:
		problems.append("the loop is %.0f m" % total)
	var stamps_leg := total - route[route.size() - 2].distance_to(CoffeeRun.DOCK)
	var need := stamps_leg * 1.4 / Car.BIKE_TOP + CoffeeRun.STOPS.size() * (CoffeeRun.STAMP_HOLD + 4.0)
	if need > CoffeeRun.COFFEE_LIMIT * 0.85:
		problems.append("the clock is unfair: ~%.0f s needed of %.0f" % [need, CoffeeRun.COFFEE_LIMIT])
	return total


func _money() -> void:
	for st: Dictionary in CoffeeRun.STOPS:
		var p := int(st["price"])
		if p < 24 or p > 40:
			problems.append("%s's coffee at %d zł is not overpriced the right way" % [st["name"], p])
	var bill := CoffeeRun.bill()
	var good := CoffeeRun.pay(bill, true)
	if int(good["zl"]) != bill + CoffeeRun.THANKS or int(good["respect"]) != CoffeeRun.RESPECT:
		problems.append("on-time pay %s" % good)
	var late := CoffeeRun.pay(bill, false)
	if int(late["zl"]) != roundi(bill * 0.5) or int(late["respect"]) != 0:
		problems.append("late pay %s" % late)
	if CoffeeRun.stamps(2) != "2/%d" % CoffeeRun.STOPS.size():
		problems.append("stamps text %s" % CoffeeRun.stamps(2))


func _bike() -> void:
	var car: CharacterBody3D = Car.new()
	var car_top: float = car.top_speed()
	car.set_model("bike")
	if not is_equal_approx(car.top_speed(), Car.BIKE_TOP) or Car.BIKE_TOP > car_top / 3.0:
		problems.append("the bike's top speed %.1f (car %.1f)" % [car.top_speed(), car_top])
	car.set_model("tt")
	if car.model != "tt" or car.top_speed() < car_top * 0.99:
		problems.append("off the bike the car's speed is not back")
	car.free()
	var m := Models.player_meshes(Models.fin(Color.RED, Models.HERO), Models.fin(Color.WHITE, Models.HERO), "player_bike")
	if m.size() != 3:
		problems.append("the bike has %d meshes" % m.size())
		return
	var tris := 0
	for s in m[0].get_surface_count():
		tris += (m[0].surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	if tris > 800:
		problems.append("the bike's body has %d triangles" % tris)
	var h := m[0].get_aabb().size.y
	if h < 2.6 or h > 3.2:
		problems.append("the bike is %.2f m tall" % h)
