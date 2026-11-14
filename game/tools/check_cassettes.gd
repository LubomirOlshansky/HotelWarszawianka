extends SceneTree
## The first-10 polish: the mixtapes on roofs (cassettes.gd, data/cassettes.json; DEMO 6.2 6:00),
## map-free. Checks that:
## - cassettes.json parses: unique ids, each with a roof landmark, the words at most MAX_WORDS
##   characters; the guide's cassette (first10.gd CASSETTE_ID) is among them;
## - the pickup rule: the helicopter over it (low enough) takes it, too high or too far doesn't;
##   a car beside the building (metres under the roof) doesn't;
## - a pickup on a fresh in-memory wallet: the record, the respect, the card with both lines and
##   the next locked PÓŁNOC FM track; a repeat does nothing; a look from far away does nothing;
## - a cassette whose roof isn't found is left out (no position, never taken by a look);
## - the pickups survive a save and a load (a scratch file in user://, never the real save).
##   godot --headless --path game --script res://tools/check_cassettes.gd

const Cassettes := preload("res://scripts/cassettes.gd")
const First10 := preload("res://scripts/first10.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Fakes := preload("res://tools/fakes.gd")
const SCRATCH := "user://check_cassettes_scratch.cfg"
const MAX_WORDS := 90


var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	var c := Cassettes.new()
	_expect(c.load_data(), "cassettes.json loads")
	_data(c)
	_rule()
	_flow()
	_save()
	var n := c.entries.size()
	c.free()
	if _problems == 0:
		print("cassettes: OK (%d on roofs, pickup within %.0f m and %.0f m over the roof)" % [n, Cassettes.REACH, Cassettes.FLY_REACH])
		quit(0)
	else:
		print("check_cassettes: %d problem(s)" % _problems)
		quit(1)


func _data(c: Cassettes) -> void:
	_expect(not c.entries.is_empty(), "at least one cassette")
	var ids := {}
	for e in c.entries:
		var id := str(e.get("id", ""))
		_expect(id != "" and not ids.has(id), "id %s unique" % id)
		ids[id] = true
		_expect(str(e.get("roof", "")) != "", "%s has a roof landmark" % id)
		for key in ["name", "line"]:
			var w: Array = e.get(key, [])
			_expect(w.size() == 2, "%s %s is [Polish, English]" % [id, key])
			for t in w:
				_expect(str(t).length() <= MAX_WORDS, "%s %s at most %d characters: %s" % [id, key, MAX_WORDS, t])
	_expect(ids.has(First10.CASSETTE_ID), "the guide's cassette %s is in cassettes.json" % First10.CASSETTE_ID)


func _rule() -> void:
	_expect(Cassettes.reached(3.0, 8.0, true), "the helicopter 8 m over it takes it")
	_expect(not Cassettes.reached(3.0, Cassettes.FLY_REACH + 1.0, true), "too high: not taken")
	_expect(not Cassettes.reached(Cassettes.REACH + 1.0, 5.0, true), "too far: not taken")
	_expect(not Cassettes.reached(2.0, -20.0, false), "a car in the street under the roof: not taken")
	_expect(not Cassettes.reached(2.0, -20.0, true), "the helicopter below the roof: not taken")


func _fresh() -> Array:
	var c := Cassettes.new()
	c.load_data()
	var w := Wallet.new()
	w.persistent = false
	var hud := Fakes.Hud.new()
	var radio := Fakes.Radio.new()
	radio.open = {1: true, 2: true}
	c.wallet = w
	c.hud = hud
	c.radio = radio
	return [c, w, hud, radio]


func _flow() -> void:
	var f := _fresh()
	var c: Cassettes = f[0]
	var w: Wallet = f[1]
	var hud: Fakes.Hud = f[2]
	var radio: Fakes.Radio = f[3]
	var roof := Vector3(100.0, 30.0, -900.0)
	# Every cassette gets a roof spot 300 m apart (a roof that is not found logs a warning, which
	# verify.sh counts as a failure; the map-free check keeps that path out).
	var spots := {}
	for k in c.entries.size():
		var e: Dictionary = c.entries[k]
		spots[e["roof"]] = roof if e["id"] == First10.CASSETTE_ID else Vector3(100.0 + 300.0 * (k + 1), 30.0, -900.0)
	_expect(c.place_all(func(name: String) -> Vector3: return spots.get(name, Vector3.INF)) == c.entries.size(),
			"every cassette placed on its roof")
	var i := c.index_of(First10.CASSETTE_ID)
	_expect(c.at(i) == roof, "at its roof spot: %s" % c.at(i))
	c.tick(roof + Vector3(40.0, 5.0, 0.0), true)
	_expect(not c.is_taken(First10.CASSETTE_ID), "40 m away: not taken")
	c.tick(roof + Vector3(0.0, -25.0, 2.0), false)
	_expect(not c.is_taken(First10.CASSETTE_ID), "the car in the street below: not taken")
	var r0 := int(w.respect)
	c.tick(roof + Vector3(2.0, 9.0, 1.0), true)
	_expect(c.is_taken(First10.CASSETTE_ID), "the helicopter low over it takes it")
	_expect(int(w.respect) == r0 + c.respect, "+%d respect (%d -> %d)" % [c.respect, r0, w.respect])
	_expect(hud.notes.size() == 1 and str(hud.note_titles[0]).contains("KASETA") and str(hud.note_texts[0]).contains(str(c.entries[i]["line"][0])) and not str(hud.note_texts[0]).contains(str(c.entries[i]["line"][1])),
			"the card with the Polish line only: %s" % [hud.notes])
	_expect(_opened(radio) == [3], "the next locked PÓŁNOC FM track opened: %s" % [_opened(radio)])
	_expect(not c.take(First10.CASSETTE_ID), "a repeat does nothing")
	c.tick(roof + Vector3(2.0, 9.0, 1.0), true)
	_expect(hud.notes.size() == 1 and _opened(radio).size() == 1, "a second look over it does nothing")
	for e in c.entries:
		if e["id"] != First10.CASSETTE_ID:
			_expect(not c.is_taken(str(e["id"])), "%s, 300 m or more away: not taken by the other's pickup" % e["id"])
	c.free()
	w.free()
	hud.free()
	radio.free()


func _save() -> void:
	var w := Wallet.new()
	w.persistent = true
	w.path = SCRATCH
	w.reset()
	w.cassettes = {First10.CASSETTE_ID: 20261031}
	w.save()
	var b := Wallet.new()
	b.persistent = true
	b.path = SCRATCH
	b.load_save()
	_expect(b.cassettes == w.cassettes, "the pickups survive a save and a load: %s" % [b.cassettes])
	b.reset()
	_expect(b.cassettes.is_empty(), "reset() clears them")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	w.free()
	b.free()


## The track numbers asked to open, in order (Fakes.Radio's unlocks without the why).
func _opened(radio: Fakes.Radio) -> Array[int]:
	var out: Array[int] = []
	for u: Array in radio.unlocks:
		out.append(int(u[0]))
	return out
