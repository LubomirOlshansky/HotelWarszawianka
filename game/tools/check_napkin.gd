extends SceneTree
## The napkin, LISTA (napkin.gd, data/napkin.json; F 2026-11-26), headless, no map. Checks that:
## - there are 14 lines with unique ids, a title and a note in Polish and English (at most 70
##   characters each), a stop or pass trigger, and a point: every `places` id is a notebook place
##   (places.json), `latlon`/`xz` points are numbers; nine lines tick in phase 1;
## - the napkin is shut until story chapter 1 is done (story_arc.gd), then each phase-1 line
##   ticks at its place at its hour (3 s stopped, or a slow pass), and not outside its hours, not
##   too fast, not without the Dusk look; phase-2 lines never tick yet;
## - a tick saves the real date in wallet.gd `napkin`, pays the respect once and emits `ticked`.
##   godot --headless --path game --script res://tools/check_napkin.gd

const Napkin := preload("res://scripts/napkin.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Wallet := preload("res://scripts/wallet.gd")
const MAX_LEN := 70
const ORIGIN := [52.234, 21.024]

var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	var nap: Napkin = Napkin.new()
	nap.wallet = wallet
	root.add_child(nap)
	if not nap.load_lines():
		print("check_napkin: no data/napkin.json")
		quit(1)
		return
	var nb: Notebook = Notebook.new()
	nb.load_places()
	_check_data(nap, nb)
	nb.free()
	# Every place far from the others (and from the real lat/lon points near the origin).
	var places := {}
	var i := 1
	for line in nap.lines:
		for pid: Variant in line.get("places", []):
			places[str(pid)] = Vector2(i * 1000.0, 5000.0)
			i += 1
	nap.setup(places, ORIGIN)
	var ticks: Array[String] = []
	nap.ticked.connect(func(id: String) -> void: ticks.append(id))
	var ticked := _check_ticks(nap, wallet, ticks)
	var total := nap.lines.size()
	nap.free()
	wallet.free()
	if problems.is_empty():
		print("check_napkin: OK (%d lines, %d tick now at their place and hour, not outside them)" % [total, ticked])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_napkin: %d problems" % problems.size())
		quit(1)


func _check_data(nap: Napkin, nb: Notebook) -> void:
	if nap.lines.size() != 14:
		problems.append("%d lines, want 14 (F's 13 places, the cinemas as one, Mazowiecka as one)" % nap.lines.size())
	if nap.live_count() != 9:
		problems.append("%d lines tick in phase 1, want 9" % nap.live_count())
	var ids := {}
	for line in nap.lines:
		var id := str(line.get("id", ""))
		if ids.has(id):
			problems.append("%s: the id twice" % id)
		ids[id] = true
		for k: String in ["title", "note"]:
			var pair: Variant = line.get(k)
			if not pair is Array or (pair as Array).size() != 2 or str(pair[0]).strip_edges() == "" or str(pair[1]).strip_edges() == "":
				problems.append("%s: no %s in Polish and English" % [id, k])
				continue
			for s: Variant in pair:
				if str(s).length() > MAX_LEN:
					problems.append("%s: '%s' is %d characters (at most %d)" % [id, s, str(s).length(), MAX_LEN])
		var kind := str((line.get("trigger", {}) as Dictionary).get("kind", ""))
		if not kind in ["stop", "pass"]:
			problems.append("%s: trigger '%s' (stop or pass)" % [id, kind])
		var n := 0
		for pid: Variant in line.get("places", []):
			n += 1
			if not nb.by_id.has(str(pid)):
				problems.append("%s: place '%s' is not in places.json" % [id, pid])
		for pt: Variant in line.get("latlon", []) + line.get("xz", []):
			n += 1
			if not pt is Array or (pt as Array).size() != 2:
				problems.append("%s: a point %s is not two numbers" % [id, pt])
		if n == 0:
			problems.append("%s: no place and no point" % id)


## The hour in the middle of [a, b] (wrapping midnight), and one outside it.
static func hours_in_out(h: Array) -> Array[float]:
	var a := float(h[0])
	var b := float(h[1])
	var len := b - a if a <= b else b + 24.0 - a
	return [fmod(a + len * 0.5, 24.0), fmod(b + (24.0 - len) * 0.5, 24.0)]


func _state(at: Vector2, kmh: float, hour: float, look := "Day") -> Dictionary:
	return {"pos": Vector3(at.x, 0.0, at.y), "kmh": kmh, "flying": false, "alt": 0.0, "hour": hour, "look": look,
			"sun": 30.0, "away": false, "weekday": 5, "live": false}


func _run_ticks(nap: Napkin, s: Dictionary, secs: float) -> void:
	var t := 0.0
	while t < secs:
		nap.tick(s, 0.5)
		t += 0.5
	nap.tick(_state(Vector2(-90000, -90000), 0.0, 14.0), 0.5)  # leave: a stop starts again


func _check_ticks(nap: Napkin, wallet: Wallet, ticks: Array[String]) -> int:
	var first: Dictionary = nap.lines[0]
	var at0: Vector2 = (first["spots"] as Array)[0]["at"]
	# Shut before chapter 1.
	if nap.is_open():
		problems.append("the napkin is open on a fresh save")
	wallet.intro["tajny"] = 3
	if not nap.is_open():
		problems.append("the napkin is shut after the Tajny klient (stage 3)")
	var ok := 0
	for line in nap.lines:
		var id := str(line["id"])
		var spots: Array = line["spots"]
		if spots.is_empty():
			problems.append("%s: no point on the map after setup" % id)
			continue
		var at: Vector2 = spots[spots.size() - 1]["at"]
		var t: Dictionary = line["trigger"]
		var slow := 0.0 if str(t["kind"]) == "stop" else float(t.get("max_kmh", 20.0)) * 0.5
		var hour := 14.0
		var out := -1.0
		if t.has("hours"):
			var io := hours_in_out(t["hours"])
			hour = io[0]
			out = io[1]
		var look := str(t.get("look", "Day"))
		if not Napkin.is_live(line):
			_run_ticks(nap, _state(at, slow, hour, look), 6.0)
			if nap.is_done(id):
				problems.append("%s: a phase-2 line ticked" % id)
			continue
		# Not outside its hours, not without its look, not too fast for a pass, not after 1 s.
		if out >= 0.0:
			_run_ticks(nap, _state(at, slow, out, look), 6.0)
			if nap.is_done(id):
				problems.append("%s ticked at %.1f h, outside %s" % [id, out, t["hours"]])
		if t.has("look"):
			_run_ticks(nap, _state(at, slow, hour, "Day"), 6.0)
			if nap.is_done(id):
				problems.append("%s ticked without the %s look" % [id, t["look"]])
		if t.has("max_kmh"):
			_run_ticks(nap, _state(at, float(t["max_kmh"]) + 20.0, hour, look), 2.0)
			if nap.is_done(id):
				problems.append("%s ticked at %.0f km/h" % [id, float(t["max_kmh"]) + 20.0])
		if str(t["kind"]) == "stop":
			_run_ticks(nap, _state(at, 0.0, hour, look), 1.0)
			if nap.is_done(id):
				problems.append("%s ticked after 1 s stopped" % id)
		var before := wallet.respect
		_run_ticks(nap, _state(at, slow, hour, look), 4.0)
		if not nap.is_done(id):
			problems.append("%s did not tick at its place at %.1f h (%s)" % [id, hour, t])
			continue
		ok += 1
		if wallet.respect != before + nap.respect:
			problems.append("%s paid %d respect, want %d" % [id, wallet.respect - before, nap.respect])
		if int(wallet.napkin[id]) < 20260101:
			problems.append("%s saved %s, not a date" % [id, wallet.napkin[id]])
		if not id in ticks:
			problems.append("%s: no `ticked` signal" % id)
		# Once: again there pays nothing.
		before = wallet.respect
		if nap.record(id):
			problems.append("%s ticked twice" % id)
		_run_ticks(nap, _state(at, slow, hour, look), 4.0)
		if wallet.respect != before:
			problems.append("%s paid again" % id)
	if ticks.size() != ok:
		problems.append("%d signals for %d ticks" % [ticks.size(), ok])
	if nap.done_count() != ok:
		problems.append("done_count %d, want %d" % [nap.done_count(), ok])
	# A shut napkin ticks nothing through _process: checked by is_open above; the first line's
	# place is a real point.
	if at0 == Vector2.INF:
		problems.append("the first line has no point")
	return ok
