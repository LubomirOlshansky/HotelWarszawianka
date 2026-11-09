extends SceneTree
## Loop 3h slice 3: the rival ladder (ladder.gd) and the final race's route (trzy_mosty.gd).
## Checks that:
## - the rungs are the six rivals of rivals.gd in order of stake (Halina 60 ... Mike 300, the same
##   stakes as RIVALS), the respect thresholds are 0/100/220/340/480/640 and 850 for the final,
##   and the pace rises up the ladder (Halina 1.25 ... Mike 1.5);
## - the gating on a fresh in-memory wallet: only Halina open; a locked rung says what is missing
##   ("NAJPIERW HALINA", "SZACUNEK 220") and cannot be won; race wins alone (+100 each) are not
##   enough past the second rung; the whole ladder walked to the final and `final_won`; open_count
##   only grows; next_rung; the full map's rows (★ / → / ·, the final "w nocy" by day);
## - every rival has a refusal line and Seba's final lines are there, Polish and English, at most
##   70 characters each;
## - the save: the record round-trips through a scratch file; a v2 file without [ladder] (slices
##   1-2) and a v1 file load as nothing beaten with their money kept; --nosave writes nothing;
##   --ladder=N's preset;
## - with the committed map data (map/centrum.json; skipped without it): the three bridges are found
##   in the lane graph, going east, west, east; each leg routes; the shortest way from each span's
##   near end to its far end is the span itself; the finish is by the stadium, the start by Rondo
##   Daszyńskiego; a checkpoint counts on the deck and not 10 m under it or 30 m aside; PT-8: where
##   Halina rolls up for the first race is behind the car on a lane its way, never in front.
##   godot --headless --path game --script res://tools/check_ladder.gd

const Ladder := preload("res://scripts/ladder.gd")
const Lang := preload("res://scripts/lang.gd")
const TrzyMosty := preload("res://scripts/trzy_mosty.gd")
const Rivals := preload("res://scripts/rivals.gd")
const Wallet := preload("res://scripts/wallet.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const SCRATCH := "user://check_ladder_scratch.cfg"
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
	_data()
	_gating()
	_words()
	_race_hud()
	_save()
	await _route()
	_cleanup()
	if _problems == 0:
		print("ladder: OK (%s)" % ", ".join(PackedStringArray(_summary.values())))
		quit(0)
	else:
		print("check_ladder: %d problem(s)" % _problems)
		quit(1)


func _fresh() -> Wallet:
	var w := Wallet.new()
	w.persistent = false
	return w


func _data() -> void:
	_expect(Ladder.RUNGS.size() == 6 and Ladder.FINAL == 6, "%d rungs, final %d" % [Ladder.RUNGS.size(), Ladder.FINAL])
	var want := [0, 100, 220, 340, 480, 640]
	var stakes := []
	for i in Ladder.RUNGS.size():
		var r: Dictionary = Ladder.RUNGS[i]
		_expect(Ladder.threshold(i) == want[i], "%s: respect %d, not %d" % [r["rival"], Ladder.threshold(i), want[i]])
		stakes.append(int(r["stake"]))
		if i > 0:
			_expect(int(r["stake"]) > int(Ladder.RUNGS[i - 1]["stake"]), "%s's stake does not rise" % r["rival"])
			_expect(Ladder.pace(i).x > Ladder.pace(i - 1).x, "%s's pace does not rise" % r["rival"])
			# Street races R4: the racing share never falls up the ladder (every rival reaches the
			# player's top since 2026-11-09), the rubber band weakens.
			_expect(float(Ladder.racer(i)["share"]) >= float(Ladder.racer(i - 1)["share"]), "%s's racing share falls" % r["rival"])
			_expect(float(Ladder.racer(i)["band"]) < float(Ladder.racer(i - 1)["band"]), "%s's band does not weaken" % r["rival"])
		# The same rival and stake as rivals.gd.
		var found := false
		for rv: Dictionary in Rivals.RIVALS:
			if rv["name"] == r["rival"]:
				found = true
				_expect(int(rv["stake"]) == int(r["stake"]), "%s: stake %d in the ladder, %d in RIVALS" % [r["rival"], r["stake"], rv["stake"]])
		_expect(found, "%s is not in rivals.gd" % r["rival"])
		_expect(Ladder.rung_of(str(r["rival"])) == i, "rung_of(%s)" % r["rival"])
	_expect(stakes == [60, 90, 120, 150, 200, 300], "stakes %s" % [stakes])
	_expect(Ladder.threshold(Ladder.FINAL) == 850, "the final needs %d" % Ladder.threshold(Ladder.FINAL))
	_expect(is_equal_approx(Ladder.pace(0).x, 1.25) and is_equal_approx(Ladder.pace(5).x, 1.5), "pace Halina %.2f, Mike %.2f" % [Ladder.pace(0).x, Ladder.pace(5).x])
	_expect(Ladder.rung_of("Nobody") == -1 and is_equal_approx(Ladder.pace(-1).x, Ladder.DEFAULT_PACE), "an unknown rival")
	# The designer pass (docs/design/pay-tables.md): the full respect once per rung, a rematch less.
	_expect(Ladder.race_gain(0, true) == 100 and Ladder.race_gain(5, true) == 100, "a first win's respect")
	_expect(Ladder.race_gain(Ladder.FINAL, true) == Ladder.FINAL_GAIN, "the final's first win")
	_expect(Ladder.race_gain(0, false) == Ladder.REMATCH_GAIN and Ladder.race_gain(Ladder.FINAL, false) == Ladder.REMATCH_GAIN, "a rematch's respect")
	_expect(Ladder.REMATCH_GAIN * 3 < Ladder.WIN_GAIN, "a rematch pays %d respect, near a job's, not a rung's" % Ladder.REMATCH_GAIN)
	_summary["data"] = "stakes %s, pace %.2f-%.2f, respect +%d first win, +%d rematch" % [stakes, Ladder.pace(0).x, Ladder.pace(5).x, Ladder.WIN_GAIN, Ladder.REMATCH_GAIN]


func _gating() -> void:
	var w := _fresh()
	var l := Ladder.new()
	l.wallet = w
	_expect(l.is_open(0) and not l.is_open(1) and l.open_count() == 1, "fresh: open %d" % l.open_count())
	_expect(l.missing(1)[0] == "NAJPIERW HALINA" and l.missing(1)[1] == "beat Pani Halina first", "missing(1): %s" % [l.missing(1)])
	_expect(l.missing(0)[0] == "", "missing(0) on an open rung")
	_expect(not l.win(1), "a locked rung was won")
	_expect(l.next_rung() == 0, "next %d" % l.next_rung())
	# Race wins alone: +100 each.
	var seen := l.open_count()
	var stuck_at := -1
	for i in Ladder.RUNGS.size():
		if not l.is_open(i):
			stuck_at = i
			break
		_expect(l.win(i, 20261031), "rung %d not won" % i)
		w.respect += 100
		_expect(l.open_count() >= seen, "open_count fell")
		seen = l.open_count()
	_expect(stuck_at == 2, "race wins alone got stuck at rung %d (want 2: Bartek needs 220)" % stuck_at)
	_expect(l.missing(2)[0] == "SZACUNEK 220" and l.missing(2)[1] == "respect 220", "missing(2): %s" % [l.missing(2)])
	_expect(not l.win(2), "Bartek won at respect %d" % w.respect)
	# The rest of the way, with the respect from other activities.
	for i in range(2, Ladder.RUNGS.size()):
		w.respect = maxi(w.respect, Ladder.threshold(i))
		_expect(l.is_open(i) and l.win(i), "rung %d at respect %d" % [i, w.respect])
	_expect(l.next_rung() == Ladder.FINAL and not l.is_open(Ladder.FINAL), "the final open at respect %d" % w.respect)
	_expect(l.missing(Ladder.FINAL)[0] == "SZACUNEK 850", "missing(final): %s" % [l.missing(Ladder.FINAL)])
	var day: Array = l.rows(false)
	_expect(day.size() == 7 and str(day[6][0]).contains("szacunek") and day[6][1] == "next", "rows before the final: %s" % [day[6]])
	w.respect = 850
	_expect(l.is_open(Ladder.FINAL) and l.open_count() == 7, "the final at 850")
	day = l.rows(false)
	var night: Array = l.rows(true)
	_expect(str(day[6][0]).contains("w nocy") and not str(day[6][0]).contains("at night") and str(night[6][0]).contains("Rondo Daszyńskiego"), "the final's row: %s / %s" % [day[6][0], night[6][0]])
	Lang.set_code("en")
	_expect(str(l.rows(false)[6][0]).contains("at night") and not str(l.rows(false)[6][0]).contains("w nocy"), "the final's row in English: %s" % [l.rows(false)[6][0]])
	Lang.set_code("pl")
	_expect(str(day[0][0]).begins_with("★ ") and day[0][1] == "won", "a beaten row: %s" % [day[0]])
	_expect(not l.final_won() and l.win(Ladder.FINAL, 20261031) and l.final_won() and l.next_rung() == Ladder.FINAL + 1, "the final won")
	_expect(not l.win(Ladder.FINAL), "the final won twice")
	_expect(str(l.rows(true)[6][0]).begins_with("★ "), "the final's row once won")
	# The rows of a fresh ladder: Halina next and open, the rest locked.
	var w2 := _fresh()
	var l2 := Ladder.new()
	l2.wallet = w2
	var rows: Array = l2.rows(true)
	_expect(rows[0][1] == "next" and str(rows[0][0]).contains("otwarty") and rows[1][1] == "locked" and rows[6][1] == "locked", "fresh rows: %s" % [rows])
	# The cost of the 5 Hz look at the prompt (is_open on every rung).
	var t0 := Time.get_ticks_usec()
	for k in 1000:
		l2.open_count()
	_summary["cost"] = "open_count %.1f µs" % ((Time.get_ticks_usec() - t0) / 1000.0)
	w.free()
	w2.free()


func _words() -> void:
	for rv: Dictionary in Rivals.RIVALS:
		var no: Array = rv.get("refuse", [])
		_expect(no.size() == 2, "%s has no refusal line" % rv["name"])
		for t in no:
			_expect(str(t) != "" and str(t).length() <= MAX_WORDS, "%s: refusal of %d characters" % [rv["name"], str(t).length()])
	for key in ["wait", "challenge", "win", "lose"]:
		var pair: Array = Rivals.FINAL_LINES.get(key, [])
		_expect(pair.size() == 2, "final line %s missing" % key)
		for t in pair:
			_expect(str(t) != "" and str(t).length() <= MAX_WORDS, "final %s: %d characters" % [key, str(t).length()])


## Beta values (street races R5): the gap in seconds and its words.
func _race_hud() -> void:
	_expect(absf(Rivals.time_gap(40.0, 22.2) - 1.8) < 0.05, "40 m at 80 km/h: %.2f s (want 1.8)" % Rivals.time_gap(40.0, 22.2))
	_expect(absf(Rivals.time_gap(-40.0, 0.0) - 5.0) < 0.01, "40 m standing: %.2f s (want 5.0, the 8 m/s floor)" % Rivals.time_gap(-40.0, 0.0))
	var behind: Array = Rivals.gap_words("Pani Halina", 40.0, 2.43, true)
	_expect(behind[0] == "Pani Halina 2,4 s za tobą" and behind[1] == "Pani Halina 2.4 s behind", "gap words behind: %s" % [behind])
	var ahead: Array = Rivals.gap_words("Mordor Mike", 40.0, 1.0, false)
	_expect(String(ahead[0]).ends_with("1,0 s przed tobą"), "gap words ahead: %s" % [ahead])
	var level: Array = Rivals.gap_words("Seba z Pragi", 3.0, 0.1, true)
	_expect(String(level[0]).ends_with("łeb w łeb!"), "gap words level: %s" % [level])
	_summary["race_hud"] = "gap in seconds"


func _save() -> void:
	_cleanup()
	var w := Wallet.new()
	w.path = SCRATCH
	var l := Ladder.new()
	l.wallet = w
	_expect(l.win(0, 20261031), "win(0) on the scratch wallet")
	w.respect = 850
	for i in range(1, Ladder.RUNGS.size()):
		l.win(i, 20261031)
	l.win(Ladder.FINAL, 20261031)
	w.save()
	var b := Wallet.new()
	b.path = SCRATCH
	b.load_save()
	_expect(b.ladder == w.ladder and b.ladder.size() == 7 and int(b.ladder.get("trzy_mosty", 0)) == 20261031, "round trip: %s" % [b.ladder])
	var lb := Ladder.new()
	lb.wallet = b
	_expect(lb.final_won() and lb.next_rung() == Ladder.FINAL + 1, "the loaded ladder")
	b.reset()
	_expect(b.ladder.is_empty(), "reset() kept the ladder")
	w.free()
	b.free()
	# A v2 file of slices 1-2 (no [ladder]) and a v1 file: nothing beaten, the money kept.
	for version in [2, 1]:
		_cleanup()
		var cfg := ConfigFile.new()
		if version == 2:
			cfg.set_value("save", "version", 2)
		cfg.set_value("wallet", "zl", 777)
		cfg.set_value("wallet", "respect", 420)
		cfg.save(SCRATCH)
		var o := Wallet.new()
		o.path = SCRATCH
		o.load_save()
		var lo := Ladder.new()
		lo.wallet = o
		_expect(o.zl == 777 and o.respect == 420 and o.ladder.is_empty() and lo.next_rung() == 0 and lo.is_open(0) and not lo.is_open(1),
				"a v%d file without [ladder]: %d zł, %s" % [version, o.zl, o.ladder])
		o.free()
	# --nosave: nothing written.
	_cleanup()
	var n := Wallet.new()
	n.path = SCRATCH
	n.persistent = false
	var ln := Ladder.new()
	ln.wallet = n
	ln.win(0)
	n.respect = 400
	ln.win(1)
	_expect(n.ladder.size() == 2 and not FileAccess.file_exists(SCRATCH), "--nosave: %s, file %s" % [n.ladder, FileAccess.file_exists(SCRATCH)])
	# --ladder=N.
	ln.preset(3)
	_expect(n.ladder.size() == 3 and ln.next_rung() == 3 and n.respect == 400 and ln.is_open(3), "--ladder=3: %s, respect %d" % [n.ladder, n.respect])
	n.respect = 0
	ln.preset(6)
	_expect(ln.next_rung() == Ladder.FINAL and n.respect == 850 and ln.is_open(Ladder.FINAL), "--ladder=6: respect %d" % n.respect)
	ln.preset(0)
	_expect(n.ladder.is_empty() and ln.next_rung() == 0, "--ladder=0")
	_expect(not FileAccess.file_exists(SCRATCH), "--nosave wrote a file")
	n.free()
	_summary["save"] = "round trip, v2/v1 without [ladder], --nosave"


func _route() -> void:
	if not FileAccess.file_exists("res://map/centrum.json"):
		_summary["route"] = "no map data: route skipped"
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary or not (data as Dictionary).has("graph"):
		_expect(false, "map/centrum.json has no lane graph")
		return
	var map := FakeMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	var t := TrzyMosty.new()
	_expect(t.build(g, data), "the route does not build: %s" % t.error)
	if t.checkpoints.size() != 3:
		_expect(false, "%d checkpoints" % t.checkpoints.size())
		map.free()
		return
	var names := []
	for k in 3:
		var c: Dictionary = t.checkpoints[k]
		var e: int = c["edge"]
		names.append(str(c["pl"]))
		_expect(g.e_name[e] == TrzyMosty.BRIDGES[k]["road"] and g.e_bridge[e] == 1, "checkpoint %d is on %s" % [k, g.e_name[e]])
		var dx: float = g.node_pos[g.e_b[e]].x - g.node_pos[g.e_a[e]].x
		_expect(dx * (1 if k != 1 else -1) > 0.0, "bridge %d crossed the wrong way (dx %.0f)" % [k, dx])
		_expect(g.e_len[e] > 300.0, "%s's span is %.0f m" % [c["pl"], g.e_len[e]])
		# The shortest way from the span's near end to its far end is the span.
		var d := g.distances_to(g.e_b[e])
		_expect(absf(d[g.e_a[e]] - g.e_len[e]) < 1.0, "%s: from its near end %.0f m, the span %.0f m" % [c["pl"], d[g.e_a[e]], g.e_len[e]])
		var p: Vector3 = c["pos"]
		_expect(t.passed(k, p) and not t.passed(k, p + Vector3(30.0, 0.0, 0.0)) and not t.passed(k, p + Vector3(0.0, -10.0, 0.0)),
				"checkpoint %d: on it, 30 m aside, 10 m under" % k)
		_expect(not t.passed(k + 1 if k < 2 else 0, p), "checkpoint %d counts at the next one" % k)
		var hint: Vector2 = TrzyMosty.BRIDGES[k]["hint"]
		_expect(hint.distance_to(Vector2(p.x, p.z)) < 60.0, "bridge %d's hint is %.0f m from its checkpoint" % [k, hint.distance_to(Vector2(p.x, p.z))])
	_expect(t.legs.size() == 7, "%d legs" % t.legs.size())
	var total := 0.0
	var prev: int = g.e_b[t.start_lane[0]]
	for n in t.legs:
		var d := g.distances_to(n)
		_expect(d[prev] < INF, "leg to node %d does not route" % n)
		total += d[prev]
		prev = n
	var stadium := Vector2.INF
	for poi: Dictionary in data.get("pois", []):
		if str(poi.get("name", "")) == TrzyMosty.FINISH_POI:
			stadium = Vector2(float(poi["x"]), float(poi["z"]))
	var fp: Vector3 = t.finish["pos"]
	_expect(Vector2(fp.x, fp.z).distance_to(stadium) <= TrzyMosty.FINISH_REACH, "the finish is %.0f m from the stadium" % Vector2(fp.x, fp.z).distance_to(stadium))
	_expect(Vector2(t.start_pos.x, t.start_pos.z).distance_to(TrzyMosty.START_HINT) < 100.0, "the start is %.0f m from START_HINT" % Vector2(t.start_pos.x, t.start_pos.z).distance_to(TrzyMosty.START_HINT))
	_expect(total > 5000.0 and total < 15000.0, "the route is %.0f m" % total)
	_summary["route"] = "%s, %.1f km" % [" → ".join(PackedStringArray(names)), total / 1000.0]
	await process_frame  # the car below needs the tree (global_position)
	_first_call(g)
	map.free()


## PT-8 (docs/PLAYTEST.md): where Halina rolls up for the first race (rivals.gd `_spot_behind`).
## At the end of one-way Hoża by Mokotowska facing west she was put 12 m in FRONT of the car on the
## 3 m street and held there (the car crawled into her for the whole prompt). Each case: a spot
## [x, z, compass heading, whether a spot must be found]; a spot found must be behind the car by
## at least half the distance asked for, on a lane running the car's way.
func _first_call(g: LaneGraph) -> void:
	var cases := [
		[-125.0, 676.0, -70.0, false, "PT-8: Hoża's end facing west (two-way Hoża's lane starts 9 m ahead)"],
		[-125.0, 676.0, 110.0, true, "PT-8: Hoża's end facing east, with the one-way"],
		[-150.0, 682.0, 110.0, true, "two-way Hoża facing east"],
	]
	var r := Rivals.new()
	var c := CharacterBody3D.new()
	root.add_child(c)
	r.graph = g
	r.car = c
	var ok := 0
	for k: Array in cases:
		c.global_position = Vector3(k[0], 0.0, k[1])
		c.rotation.y = -deg_to_rad(float(k[2]))
		var heading := Vector2(-sin(c.rotation.y), -cos(c.rotation.y))
		for back: float in [Rivals.FIRST_BACK, 12.0]:
			var spot: Array = r._spot_behind(back)
			if spot.is_empty():
				_expect(not k[3] or back < Rivals.FIRST_BACK, "%s: no spot %.0f m behind" % [k[4], back])
				continue
			var e: int = spot[0]
			var q: Vector2 = g.point_at(e, float(spot[2]), g.lane_offset(e, int(spot[1])))
			var rel := q - Vector2(k[0], k[1])
			_expect(rel.dot(heading) <= -0.5 * back, "%s: the %.0f m spot is %.0f m ahead" % [k[4], back, rel.dot(heading)])
			_expect(g.direction(e, float(spot[2])).dot(heading) > 0.5, "%s: the %.0f m spot's lane runs against the car" % [k[4], back])
			ok += 1
	c.free()
	r.free()
	_summary["first_call"] = "Halina's roll-up spot: %d placed behind, PT-8 none in front" % ok


func _cleanup() -> void:
	if FileAccess.file_exists(SCRATCH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	for v in [1, 2]:
		var bak := SCRATCH.get_basename() + ".v%d.cfg" % v
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bak))
