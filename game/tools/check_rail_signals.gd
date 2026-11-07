extends SceneTree
## The railway's light signals (the railway audit, F 2026-11-07; map_builder.gd
## `rail_signal_spots`, `_build_rail_signals`), from the map index (map/index.json):
##   1. there are signals, and each station with open-air railway platforms (Ochota, Powiśle,
##      Stadion, Wschodnia) has at least two near it, each tunnel mouth at least one; none stands
##      on Stacja Muzeum's sidings (no trains run there: Trains.service_rails);
##   2. every signal stands clear of every track (a train's body is 1.45 m either side of its
##      track: nothing within MIN_CLEAR m of a track's centre line) and at a finite height;
##   3. the list is the same when a sector's build asks for it (both city paths read one list).
## Prints "check_rail_signals: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_rail_signals.gd

const MapBuilder := preload("res://scripts/map_builder.gd")
const Trains := preload("res://scripts/trains.gd")
const INDEX_JSON := "res://map/index.json"
## (Główna's islands are footways in OSM, rail_yard.gd's: no signals there yet, BACKLOG.)
const STATIONS := {"Ochota": Vector2(-2313.0, 929.0), "Powiśle": Vector2(290.0, 25.0),
		"Stadion": Vector2(1391.0, -1328.0), "Wschodnia": Vector2(1930.0, -1960.0)}
const MIN_CLEAR := 1.8

var problems: Array[String] = []


func _initialize() -> void:
	if not FileAccess.file_exists(INDEX_JSON):
		print("check_rail_signals: no map/index.json: run tools/setup_map.sh once")
		quit(1)
		return
	var map: Node3D = MapBuilder.new()
	root.add_child(map)
	map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	var spots: Array = map.rail_signal_spots()
	var dwarfs := 0
	var red := 0
	if spots.size() < 30:
		problems.append("only %d signals" % spots.size())
	var near := {}
	for name: String in STATIONS:
		near[name] = 0
	var mouths := [0, 0]
	var rails: Array = Trains.trim_rails(map.index_data.get("rails", []))
	var museum: Array = []
	for r in rails:
		var f: Array = r["p"]
		for e: Vector2 in Trains.MUSEUM_ENDS:
			if Vector2(f[0], f[1]).distance_to(e) < 0.5 or Vector2(f[f.size() - 2], f[f.size() - 1]).distance_to(e) < 0.5:
				museum.append(r)
				break
	for sp: Array in spots:
		var at: Vector2 = sp[0]
		dwarfs += int(sp[3])
		red += int(sp[5])
		if not is_finite(float(sp[2])):
			problems.append("a signal at %s has no height" % at)
		for name: String in STATIONS:
			if at.distance_to(STATIONS[name]) < 260.0:
				near[name] += 1
		for k in Trains.PORTALS.size():
			if at.distance_to(Trains.PORTALS[k]) < 70.0:
				mouths[k] += 1
		if at.x > Trains.MUSEUM_X and at.distance_to(Vector2(-2700.0, 960.0)) < 220.0 and _clear(museum, at) < 6.0:
			problems.append("a signal at %.0f, %.0f stands on Stacja Muzeum's sidings" % [at.x, at.y])
		var clear := _clear(rails, at)
		if clear < MIN_CLEAR:
			problems.append("the signal at %.0f, %.0f stands %.2f m from a track" % [at.x, at.y, clear])
	for name: String in STATIONS:
		if near[name] < 2:
			problems.append("%s has %d signals" % [name, near[name]])
	for k in mouths.size():
		if mouths[k] < 1:
			problems.append("no signal at the tunnel mouth %s" % Trains.PORTALS[k])
	# A sector's build reads the index's whole lists: the same signals.
	map._signal_key = -1
	map._in_sector = true
	map.data = {"rails": [], "platforms": []}
	var again: Array = map.rail_signal_spots()
	map._in_sector = false
	if again.size() != spots.size():
		problems.append("a sector finds %d signals, the whole map %d" % [again.size(), spots.size()])
	if problems.is_empty():
		print("check_rail_signals: OK (%d signals, %d dwarfs, %d at red · %s · mouths %s)" % [spots.size(), dwarfs, red, near, mouths])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_rail_signals: %d problems" % problems.size())
		quit(1)


func _clear(rails: Array, p: Vector2) -> float:
	var best := INF
	for r in rails:
		var f: PackedFloat32Array = PackedFloat32Array(r["p"])
		for i in range(0, f.size() - 2, 2):
			var q := Geometry2D.get_closest_point_to_segment(p, Vector2(f[i], f[i + 1]), Vector2(f[i + 2], f[i + 3]))
			best = minf(best, q.distance_to(p))
	return best
