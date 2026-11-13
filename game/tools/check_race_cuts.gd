extends SceneTree
## Human rivals (docs/design/street-races.md section 9, F 2026-11-05: "they never take the
## skróty"): the racers' shortcuts. Checks that:
## - game/data/race_cuts.json (tools/race_cuts.py) loads and at least MIN_CUTS cuts snap to the
##   committed map's lane graph, with at most MAX_MISSED of them unmatched (a centrum.json re-bake
##   that moves junctions: re-run tools/race_cuts.py); every cut is MIN_LEN-MAX_LEN m between two
##   different junctions;
## - knowledge (race_cuts.gd `knows`): none at 0, all at 1, about half at 0.5, the same every call;
##   the ladder's personalities: Słoik knows none, Zbyszek all, the share rises Halina -> Zbyszek;
## - the routing with every cut never makes a node further from a finish and makes some nearer;
## - races from ROUTES start edges to the race finishes' nodes, driven decision by decision with
##   traffic.gd's own `best_cut` (the junction ahead, RaceCuts.GAIN): a racer knowing
##   every cut takes at least one on MIN_SHARE of the routes and arrives every time;
## - the rivals' human lines (rivals.gd HUMAN_LINES) are Polish and English, at most 70 characters.
##   godot --headless --path game --script res://tools/check_race_cuts.gd

const LaneGraph := preload("res://scripts/lane_graph.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Rivals := preload("res://scripts/rivals.gd")
const Ladder := preload("res://scripts/ladder.gd")

const MIN_CUTS := 200
const MAX_MISSED := 0.05
const MIN_LEN := 20.0
const MAX_LEN := 165.0
const ROUTES := 60
## Races start and end within this many metres of the map's middle (the races' finishes are all
## central; at the map's edge the roadworks close the way out and a race uses the off-map links).
const CENTRE := 1500.0
const MIN_SHARE := 0.2
const MAX_WORDS := 70


class FakeMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0
	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0
	func roof_height(_x: float, _z: float) -> float:
		return -1000.0
	func top_height(_x: float, _z: float, _r := 0.0) -> float:
		return 0.0


var _problems := 0
var _summary := {}


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_knowledge()
	_words()
	if FileAccess.file_exists("res://map/centrum.json"):
		_map()
	else:
		_summary["map"] = "no map data: routes skipped"
	if _problems == 0:
		print("race_cuts: OK (%s)" % ", ".join(PackedStringArray(_summary.values())))
		quit(0)
	else:
		print("check_race_cuts: %d problem(s)" % _problems)
		quit(1)


func _knowledge() -> void:
	var half := 0
	for i in 1000:
		_expect(not RaceCuts.knows(i, 0.0, 7), "cut %d known at share 0" % i)
		_expect(RaceCuts.knows(i, 1.0, 7), "cut %d not known at share 1" % i)
		if RaceCuts.knows(i, 0.5, 7):
			half += 1
		_expect(RaceCuts.knows(i, 0.5, 7) == RaceCuts.knows(i, 0.5, 7), "cut %d known differently twice" % i)
	_expect(half > 380 and half < 620, "share 0.5 knows %d of 1000" % half)
	var shares := {}
	for i in Ladder.RUNGS.size():
		shares[Ladder.RUNGS[i]["id"]] = float(Ladder.racer(i)["cuts"])
	_expect(shares["sloik"] == 0.0, "Słoik knows shortcuts (he follows his satnav)")
	_expect(shares["zbyszek"] == 1.0, "Zbyszek doesn't know every shortcut")
	_expect(shares["halina"] < shares["seba"] and shares["seba"] < shares["zbyszek"], "the shortcut share doesn't rise Halina -> Seba -> Zbyszek")
	_summary["knowledge"] = "share 0.5 knows %d/1000" % half


func _words() -> void:
	var n := 0
	for kind: String in Rivals.HUMAN_LINES:
		for line: Array in Rivals.HUMAN_LINES[kind]:
			n += 1
			_expect(line.size() == 2 and String(line[0]) != "" and String(line[1]) != "", "%s: a line without Polish and English" % kind)
			for w: String in line:
				_expect(w.length() <= MAX_WORDS, "%s: '%s' is over %d characters" % [kind, w, MAX_WORDS])
	_summary["words"] = "%d lines" % n


func _map() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary or not (data as Dictionary).has("graph"):
		_expect(false, "map/centrum.json has no lane graph")
		return
	var map := FakeMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	var cuts := RaceCuts.new()
	cuts.load_cuts(g)
	_expect(cuts.first_link >= MIN_CUTS, "only %d shortcuts snap to the graph (at least %d)" % [cuts.first_link, MIN_CUTS])
	_expect(cuts.missed <= int(cuts.total * MAX_MISSED), "%d of %d shortcuts find no junction: re-run tools/race_cuts.py" % [cuts.missed, cuts.total])
	for i in cuts.first_link:  # (the race links after them: check_race_links.gd)
		_expect(cuts.a[i] != cuts.b[i], "cut %d joins a junction to itself" % i)
		_expect(cuts.length[i] >= MIN_LEN and cuts.length[i] <= MAX_LEN, "cut %d is %.0f m" % [i, cuts.length[i]])
	var both := cuts.links(1.0, 0)
	var table: Dictionary = both[0]
	var extra: Dictionary = both[1]
	# Targets: core junctions spread over the map (a fixed draw), as the race finishes are.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1944
	var core := PackedInt32Array()
	for n in g.node_pos.size():
		if g.node_scc[n] != 0 and not g.node_in[n].is_empty() and g.node_pos[n].length() < CENTRE:
			core.append(n)
	var starts := PackedInt32Array()
	for e in g.e_a.size():
		if g.node_scc[g.e_a[e]] != 0 and g.node_scc[g.e_b[e]] != 0 and g.e_class[e] <= 2 and g.e_bridge[e] == 0 and g.e_tn[e] < 0 \
				and g.node_pos[g.e_a[e]].length() < CENTRE:
			starts.append(e)
	var routes := 0
	var with_cut := 0
	var taken := 0
	var arrived := 0
	var saved := 0.0
	var tries := 0
	while routes < ROUTES and tries < ROUTES * 6:
		tries += 1
		var target := core[rng.randi() % core.size()]
		var e0 := starts[rng.randi() % starts.size()]
		var plain := g.distances_to(target, INF, false)
		var dist := g.distances_to(target, INF, false, extra)
		var left := g.remaining(plain, e0, g.e_s0[e0])
		if left < 600.0 or left > 1800.0:
			continue  # a race is 600-1800 m by road (rivals.gd _pick_finish)
		routes += 1
		var worse := 0
		var nearer := 0
		for n in dist.size():
			if dist[n] > plain[n] + 0.01:
				worse += 1
			elif dist[n] < plain[n] - 30.0:
				nearer += 1
		_expect(worse == 0, "route %d: shortcuts make %d junctions further from the finish" % [routes, worse])
		saved += left - g.remaining(dist, e0, g.e_s0[e0])
		var n_cuts := _drive(g, table, dist, e0, target)
		if n_cuts < 0 and OS.is_stdout_verbose():
			print("  no arrival: e%d (%.0f, %.0f) -> node %d (%.0f, %.0f)" % [e0, g.node_pos[g.e_a[e0]].x, g.node_pos[g.e_a[e0]].y, target, g.node_pos[target].x, g.node_pos[target].y])
		if n_cuts >= 0:
			arrived += 1
			taken += n_cuts
			if n_cuts > 0:
				with_cut += 1
	_expect(routes == ROUTES, "only %d races of 600-1800 m found" % routes)
	_expect(arrived == routes, "%d of %d racers never reached the finish" % [routes - arrived, routes])
	_expect(with_cut >= int(routes * MIN_SHARE), "a racer knowing every cut takes one on only %d of %d routes (at least %d %%)" % [with_cut, routes, int(MIN_SHARE * 100)])
	_summary["map"] = "%d shortcuts (%d unmatched), %d races: %d with a shortcut, %d taken, %.0f m saved on average" % [
			cuts.first_link, cuts.missed, routes, with_cut, taken, saved / maxf(routes, 1)]
	map.free()


## Drives from the start of edge e0 to `target` junction by junction as traffic.gd's racer chooses
## (the best road, or a shortcut by `best_cut`); the shortcuts taken, or -1 if it never arrives.
func _drive(g: LaneGraph, table: Dictionary, dist: PackedFloat32Array, e0: int, target: int) -> int:
	var e := e0
	var n_cuts := 0
	for step in 400:
		var n := g.e_b[e]
		if n == target:
			return n_cuts
		var best := -1
		var best_d := INF
		for f in g.node_out[n]:
			var cost: float = g.e_len[f] + dist[g.e_b[f]] + (60.0 if f == g.e_reverse[e] else 0.0)
			if cost < best_d:
				best_d = cost
				best = f
		if table.has(n):
			var cut := Traffic.best_cut(g, table[n], dist, best_d)
			if cut >= 0:
				n_cuts += 1
				e = cut
				continue
		if best < 0:
			return -1
		e = best
	return -1
