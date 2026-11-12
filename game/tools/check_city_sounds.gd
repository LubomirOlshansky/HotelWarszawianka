extends SceneTree
## Loop MW-5: the city's sounds (scripts/city_sounds.gd) at the notebook's places, headless, from
## the committed map data (map/centrum.json, like check_places) and data/places.json:
##   1. the emitters: one per sound a place makes (its tags: a club with hours, metro, church or
##      the Old Town, the Patelnia's buskers), each exactly at its place (x, z) at its kind's height;
##   2. the hours rule: places.json's hours parse, and open/closed on synthetic times (past
##      midnight belongs to the evening it started; the looks' "always Friday");
##   3. the cap: with everything in reach, at most 8 players, held by the 8 nearest sounding
##      emitters; nothing past a kind's reach; a club only while open, the busker 19:00-22:00;
##   4. the bells strike the hour (2 tolls at 14:00) and hold players only while they toll; a
##      metro entrance's chimes come 180-240 s apart;
##   5. the 02:00 beat: at Plac Trzech Krzyży between 02:00 and 02:15, once a night, only on the
##      square; the real radio goes to PÓŁNOC FM with the music down, the engine softer;
##   6. the tick's cost (µs a tick, and a frame's share at 2 Hz and 60 fps).
## Prints "city_sounds: OK (...)" or "city_sounds: PROBLEM" and the problems.
##   godot --headless --path game --script res://tools/check_city_sounds.gd

const Notebook := preload("res://scripts/notebook.gd")
const CitySounds := preload("res://scripts/city_sounds.gd")
const Radio := preload("res://scripts/radio.gd")
const Sfx := preload("res://scripts/sfx.gd")

## Saturday 01:30 (the Night look's Friday night), Friday 14:00, Friday 19:30.
const NIGHT := {"hour": 1.5, "weekday": 6}
const DAY := {"hour": 14.0, "weekday": 5}
const DUSK := {"hour": 19.5, "weekday": 5}


class FakeRadio extends Node:
	var moments := 0

	func host_moment(_s: float) -> bool:
		moments += 1
		return true


class FakeSfx extends Node:
	var softened := 0

	func soften_engine(_s: float) -> void:
		softened += 1


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var problems: Array[String] = []
	var path := "res://map/centrum.json"
	if not FileAccess.file_exists(path):
		path = "res://map/index.json"
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var book: Notebook = Notebook.new()
	root.add_child(book)
	if not data is Dictionary or not book.setup(data):
		print("city_sounds: PROBLEM (no map data or places.json)")
		quit(1)
		return
	var cs := _sounds(book)
	# 1. the emitters, one per sound, each at its place
	var want := 0
	for place in book.places:
		want += CitySounds.kinds_of(place).size()
	var counts := {}
	for e in cs.emitters:
		counts[e["kind"]] = int(counts.get(e["kind"], 0)) + 1
		var place: Dictionary = book.places[book.by_id[e["id"]]]
		var at: Vector2 = place["at"]
		var p: Vector3 = e["at"]
		if Vector2(p.x, p.z).distance_to(at) > 0.01 or absf(p.y - float(CitySounds.KINDS[e["kind"]]["up"])) > 0.01:
			problems.append("%s %s at %s, its place at %s" % [e["kind"], e["id"], p, at])
	if cs.emitters.size() != want or counts.get("club", 0) < 1 or counts.get("metro", 0) < 1 or counts.get("bells", 0) < 1 \
			or counts.get("busker", 0) != 1:
		problems.append("%d emitters %s (want %d, with clubs, metro, bells and one busker)" % [cs.emitters.size(), counts, want])
	if cs.quiet_at == Vector3.INF:
		problems.append("no place tagged quiet (Plac Trzech Krzyży) for the 02:00 beat")
	# 2. the hours
	for place in book.places:
		if place.get("hours") != null and CitySounds.parse_hours(str(place["hours"])).is_empty():
			problems.append("%s: hours '%s' don't parse" % [place["id"], place["hours"]])
	var smola := CitySounds.parse_hours("PT–SB 23:00–08:00")
	var lusterko := CitySounds.parse_hours("PT–ND 04:00–12:00")
	var cases := [[smola, 1.5, 6, true], [smola, 22.0, 5, false], [smola, 23.5, 5, true], [smola, 3.0, 7, true],
			[smola, 3.0, 1, false], [smola, 23.5, 7, false], [smola, 9.0, 6, false], [lusterko, 1.5, 6, false],
			[lusterko, 5.0, 6, true], [lusterko, 11.9, 7, true], [lusterko, 5.0, 1, false],
			[CitySounds.parse_hours("CZ–SB 22:00–04:00"), 3.0, 5, true], [CitySounds.parse_hours("PN–ND 12:00–02:00"), 1.0, 1, true]]
	for c: Array in cases:
		if CitySounds.is_open(c[0], c[1], c[2]) != c[3]:
			problems.append("hours %s at %.1f on day %d: open should be %s" % [c[0], c[1], c[2], c[3]])
	if smola.get("days", []) != [5, 6] or float(smola.get("from", 0)) != 23.0 or float(smola.get("to", 0)) != 8.0:
		problems.append("PT–SB 23:00–08:00 parsed as %s" % smola)
	# 3. the cap, nearest first; reach; clubs by their hours; the busker
	var ear := _at(book, "swietokrzyska_metro")
	cs.reach_scale = 1000.0
	cs.tick(ear, NIGHT, 0.5)
	var sounding: Array = []
	for i in cs.emitters.size():
		if cs.sounding(cs.emitters[i], NIGHT):
			var a: Vector3 = cs.emitters[i]["at"]
			sounding.append([ear.distance_to(Vector2(a.x, a.z)), i])
	sounding.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	var nearest := {}
	for k in mini(CitySounds.MAX_LIVE, sounding.size()):
		nearest[sounding[k][1]] = true
	var held := {}
	for i in cs.emitters.size():
		if cs.emitters[i]["player"] != null:
			held[i] = true
	if sounding.size() <= CitySounds.MAX_LIVE or cs.live != CitySounds.MAX_LIVE or held.keys().size() != nearest.keys().size():
		problems.append("the cap: %d sounding, %d live (want %d)" % [sounding.size(), cs.live, CitySounds.MAX_LIVE])
	for i: int in held:
		if not nearest.has(i):
			problems.append("the cap: %s %s holds a player but isn't among the 8 nearest" % [cs.emitters[i]["kind"], cs.emitters[i]["id"]])
	var cap_line := "%d sounding at Sat 01:30, %d live" % [sounding.size(), cs.live]
	cs.reach_scale = 1.0
	cs.tick(ear + Vector2(20000.0, 0.0), NIGHT, 0.5)
	if cs.live != 0:
		problems.append("20 km from everything, %d live" % cs.live)
	_expect(problems, cs, book, "smola", DAY, "club", false)
	_expect(problems, cs, book, "smola", NIGHT, "club", true)
	_expect(problems, cs, book, "lusterko", NIGHT, "club", false)
	_expect(problems, cs, book, "patelnia", DAY, "busker", false)
	_expect(problems, cs, book, "patelnia", DUSK, "busker", true)
	_expect(problems, cs, book, "patelnia", DAY, "metro", true)
	# 4. the bells at the hour; the metro's chimes
	var rynek := _at(book, "rynek_starego_miasta")
	# (the cases above moved the clock across hours: let those tolls finish first)
	for k in 200:
		cs.tick(rynek, {"hour": 13.99, "weekday": 5}, 0.5)
		if cs._tolls_left == 0 and k > 0:
			break
	cs.tick(rynek, {"hour": 13.99, "weekday": 5}, 0.5)
	var bells_before := _live_kind(cs, "bells")
	cs.tick(rynek, {"hour": 14.0, "weekday": 5}, 0.5)
	var tolls := cs._tolls_left
	var bells_on := _live_kind(cs, "bells")
	for k in 20:
		cs.tick(rynek, {"hour": 14.0 + 0.0002 * k, "weekday": 5}, 0.5)
	if bells_before != 0 or bells_on < 1 or tolls != 1 or _live_kind(cs, "bells") != 0:
		problems.append("the bells: %d live before 14:00, %d striking (tolls left %d after the first, want 1), %d after" % [
				bells_before, bells_on, tolls, _live_kind(cs, "bells")])
	var metro: Dictionary = {}
	for e in cs.emitters:
		if e["kind"] == "metro":
			metro = e
			break
	var n0 := float(metro["next"])
	while cs._play_t < n0 + 0.6:
		cs.tick(_at(book, String(metro["id"])), DAY, 0.5)
	var gap := float(metro["next"]) - n0
	if gap < CitySounds.METRO_GAP.x or gap > CitySounds.METRO_GAP.y:
		problems.append("metro %s: a train at %.1f s, the next %.1f s later (want 180-240)" % [metro["id"], n0, gap])
	# 5. the 02:00 beat
	var fr := FakeRadio.new()
	var fs := FakeSfx.new()
	root.add_child(fr)
	root.add_child(fs)
	cs.radio = fr
	cs.sfx = fs
	var square := Vector2(cs.quiet_at.x, cs.quiet_at.z)
	cs.tick(square, {"hour": 1.9, "weekday": 6}, 0.5)
	var early := cs.beats
	cs.tick(square + Vector2(100.0, 0.0), {"hour": 2.05, "weekday": 6}, 0.5)
	var far := cs.beats
	cs.tick(square, {"hour": 2.05, "weekday": 6}, 0.5)
	cs.tick(square, {"hour": 2.1, "weekday": 6}, 0.5)
	var once := cs.beats
	cs.tick(square, {"hour": 3.0, "weekday": 6}, 0.5)
	cs.tick(square, {"hour": 2.05, "weekday": 7}, 0.5)
	if early != 0 or far != 0 or once != 1 or cs.beats != 2 or fr.moments != 2 or fs.softened != 2:
		problems.append("the 02:00 beat: before %d, 100 m off %d, on the square %d (want 1), next night %d (want 2); radio %d, engine %d" % [
				early, far, once, cs.beats, fr.moments, fs.softened])
	var radio := Radio.new()
	root.add_child(radio)
	await process_frame
	radio.picked = true
	radio.tune(radio.station_index(Radio.DAY_DEFAULT), true)
	var asked := [0]
	radio.host_wanted.connect(func() -> void: asked[0] += 1)
	var moment := radio.host_moment(10.0)
	if not moment or radio.station != radio.polnoc_index() or absf(radio.level_db() - (Radio.VOLUME_DB + float(Sfx.DUCKS["host_moment"][1]))) > 0.01 or asked[0] != 1:
		problems.append("radio.host_moment: %s, station %d (want PÓŁNOC FM %d), level %.1f dB, host asked %d" % [
				moment, radio.station, radio.polnoc_index(), radio.level_db(), asked[0]])
	radio.tune(-1, true)
	if radio.host_moment(10.0):
		problems.append("radio.host_moment with the radio Off turned it on")
	var sfx := Sfx.new()
	root.add_child(sfx)
	sfx.soften_engine(10.0)
	if not sfx.engine_softened():
		problems.append("sfx.soften_engine didn't soften the engine")
	# 6. the tick's cost
	var t0 := Time.get_ticks_usec()
	for k in 2000:
		cs.tick(ear + Vector2(float(k % 50), 0.0), NIGHT, 0.5)
	var per_tick := (Time.get_ticks_usec() - t0) / 2000.0
	var summary := "%d emitters %s; %s; tick %.1f µs (%.4f ms a frame at 2 Hz, 60 fps)" % [cs.emitters.size(), counts, cap_line,
			per_tick, per_tick * 2.0 / 60.0 / 1000.0]
	for p in problems:
		print("    PROBLEM: ", p)
	print("city_sounds: ", ("OK (%s)" % summary) if problems.is_empty() else "PROBLEM (%s)" % summary)
	for n: Node in [cs, book, fr, fs, radio, sfx]:
		n.queue_free()
	await process_frame
	quit(0 if problems.is_empty() else 1)


func _sounds(book: Notebook) -> CitySounds:
	var cs: CitySounds = CitySounds.new()
	root.add_child(cs)
	cs.setup(book.places, Callable())
	return cs


func _at(book: Notebook, id: String) -> Vector2:
	return book.places[book.by_id[id]]["at"]


func _live_kind(cs: Node, kind: String) -> int:
	var n := 0
	for e in cs.emitters:
		n += int(e["kind"] == kind and e["player"] != null)
	return n


## The ear on place `id` at `now`: its `kind` emitter holds a player (`on`) or not.
func _expect(problems: Array[String], cs: Node, book: Notebook, id: String, now: Dictionary, kind: String, on: bool) -> void:
	cs.tick(_at(book, id), now, 0.5)
	for e in cs.emitters:
		if e["id"] == id and e["kind"] == kind and (e["player"] != null) != on:
			problems.append("%s %s at %02d:%02d on day %d: %s (want %s)" % [kind, id, int(now["hour"]), int(fmod(float(now["hour"]), 1.0) * 60.0),
					now["weekday"], "live" if not on else "silent", "live" if on else "silent"])
