extends SceneTree
## Loop 3h slice 2: the 20 Syrenki (syrenki.gd, data/syrenki.json; DEMO 6.3 and F4), map-free.
## Checks that:
## - syrenki.json parses: 20 entries, unique ids, each in a district of districts.json, with an
##   anchor that resolves (a place of places.json, or `near`) and, projected without a map, lies
##   inside its own district; the words (names, lines, rewards' texts) are at most 70 characters;
## - a find on a fresh in-memory wallet: the record, +5 respect, the card "SYRENKA n/20 · MERMAID"
##   with the name and both lines; a repeat does nothing; flying high above it finds nothing;
## - the 5th find opens the "scale" paint (garage.gd `rule`: locked at 4, switch at 5) with its
##   reward card after the find's; the 10th pays 150 zł and 50 respect once; the 20th opens
##   "silver" and pays 300 zł; no reward repeats;
## - the finds survive a save and a load (a scratch file in user://, never the real save);
## - the figurines count in their districts' completion (districts.gd);
## - the look is cheap (µs a look at 5 Hz).
##   godot --headless --path game --script res://tools/check_syrenki.gd

const Districts := preload("res://scripts/districts.gd")
const Garage := preload("res://scripts/garage.gd")
const Syrenki := preload("res://scripts/syrenki.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Fakes := preload("res://tools/fakes.gd")
const SCRATCH := "user://check_syrenki_scratch.cfg"
const MAX_WORDS := 70


var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	var d := Districts.new()
	_expect(d.setup({}), "districts setup")
	var s := Syrenki.new()
	s.districts = d
	_expect(s.load_data(), "syrenki.json loads")
	_data(s, d)
	_flow()
	_save()
	_completion()
	_cost()
	s.free()
	d.free()
	if _problems == 0:
		print("syrenki: OK")
		quit(0)
	else:
		print("check_syrenki: %d problem(s)" % _problems)
		quit(1)


func _data(s: Syrenki, d: Districts) -> void:
	_expect(s.entries.size() == 20, "%d entries, not 20" % s.entries.size())
	_expect(s.by_id.size() == s.entries.size(), "ids not unique")
	_expect(s.near == 7.0 and s.respect == 5, "near %s, respect %d" % [s.near, s.respect])
	for e in s.entries:
		var id := str(e["id"])
		_expect(d.by_id.has(str(e["district"])), "%s: district %s not in districts.json" % [id, e["district"]])
		var anchor: Vector2 = e["anchor"]
		_expect(anchor != Vector2.INF, "%s: the anchor does not resolve" % id)
		_expect(d.district_at(anchor) == str(e["district"]), "%s: the anchor lies in %s, not %s" % [id, d.district_at(anchor), e["district"]])
		for key in ["name", "line"]:
			var pair: Array = e[key]
			_expect(pair.size() == 2 and str(pair[0]) != "" and str(pair[1]) != "", "%s: %s needs Polish and English" % [id, key])
			for t in pair:
				_expect(str(t).length() <= MAX_WORDS, "%s: %s is %d characters" % [id, key, str(t).length()])
	for r: Dictionary in s.rewards:
		for t in r["text"]:
			_expect(str(t).length() <= MAX_WORDS, "reward at %s: a text of %d characters" % [r["at"], str(t).length()])
	_expect(s.rewards.size() == 3, "%d rewards" % s.rewards.size())
	# They are all listed under their districts for the completion.
	var listed := 0
	for dd in d.districts:
		listed += (dd["syrenki"] as Array).size()
	_expect(listed == 20, "%d listed under districts, not 20" % listed)


## A fresh record, the stub card: every Syrenka stands at its anchor (no map here).
func _make(w: Node, hud: CanvasLayer) -> Syrenki:
	var s := Syrenki.new()
	s.wallet = w
	s.hud = hud
	s.load_data()
	for e in s.entries:
		e["pos"] = e["anchor"]
	return s


func _at(s: Syrenki, i: int) -> Vector3:
	var a: Vector2 = s.entries[i]["anchor"]
	return Vector3(a.x, 0.0, a.y)


func _flush(s: Syrenki) -> void:
	for i in 1000:
		s.tick(Vector3(1.0e6, 0.0, 1.0e6))


func _flow() -> void:
	var w := Wallet.new()
	w.persistent = false
	var hud := Fakes.Hud.new()
	var s := _make(w, hud)
	# Flying high: not found. Near on the ground: found.
	s.tick(_at(s, 0), true, 60.0)
	_expect(w.syrenki.is_empty(), "found from 60 m up")
	s.tick(_at(s, 0) + Vector3(6.0, 0.0, 0.0))
	_expect(w.syrenki.has("s01_palac") and w.respect == 5, "6 m away: record %s, respect %d" % [w.syrenki, w.respect])
	_expect(hud.notes.size() == 1, "%d cards for the first find" % hud.notes.size())
	if hud.notes.size() == 1:
		var body := str(hud.note_texts[0]).split("\n")
		_expect(hud.note_titles[0] == "SYRENKA 1/20" and body.size() == 2 and body[0] == s.entries[0]["name"][0]
				and body[1] == s.entries[0]["line"][0], "the card: %s" % [hud.notes[0]])
	s.tick(_at(s, 0))
	_expect(w.syrenki.size() == 1 and w.respect == 5 and hud.notes.size() == 1, "a repeat find counted")
	s.tick(_at(s, 1) + Vector3(8.0, 0.0, 0.0))
	_expect(not w.syrenki.has(str(s.entries[1]["id"])), "found from 8 m")
	# The ladder.
	for i in range(1, 4):
		s.collect(str(s.entries[i]["id"]))
	_expect(w.syrenki.size() == 4 and w.zl == 0, "4 finds: %d, %d zł" % [w.syrenki.size(), w.zl])
	_expect(Garage.rule("scale", "red", 0, {}, 0, 4) == "locked", "scale open at 4")
	_flush(s)
	var cards := hud.notes.size()
	s.collect(str(s.entries[4]["id"]))
	_expect(Garage.rule("scale", "red", 0, {}, 0, 5) == "switch", "scale still locked at 5")
	_expect(Garage.rule("scale", "red", 0, {}, 0) == "locked", "rule()'s default count is not 0")
	_flush(s)
	_expect(hud.notes.size() == cards + 2, "5th find: %d new cards, not 2 (the find and its reward)" % (hud.notes.size() - cards))
	_expect(str(hud.note_titles[hud.notes.size() - 1]).contains("NAGRODA") and str(hud.note_texts[hud.notes.size() - 1]).contains("Łuska Syreny"),
			"the reward card: %s" % [hud.notes[hud.notes.size() - 1]])
	_expect(w.zl == 0, "the 5th reward paid %d zł" % w.zl)
	for i in range(5, 9):
		s.collect(str(s.entries[i]["id"]))
	_expect(w.zl == 0, "paid before the 10th")
	var respect := w.respect
	s.collect(str(s.entries[9]["id"]))
	_expect(w.zl == 150 and w.respect == respect + 5 + 50, "10th: %d zł, respect %d -> %d" % [w.zl, respect, w.respect])
	_expect(not s.collect(str(s.entries[9]["id"])) and w.zl == 150, "the 10th reward repeated")
	_expect(Garage.rule("silver", "red", 0, {}, 0, 19) == "locked", "silver open at 19")
	for i in range(10, 19):
		s.collect(str(s.entries[i]["id"]))
	_expect(w.zl == 150, "paid before the 20th (%d)" % w.zl)
	s.collect(str(s.entries[19]["id"]))
	_expect(w.zl == 450 and w.syrenki.size() == 20, "20th: %d zł, %d found" % [w.zl, w.syrenki.size()])
	_expect(Garage.rule("silver", "red", 0, {}, 0, 20) == "switch", "silver still locked at 20")
	_expect(w.respect == 20 * 5 + 50, "respect %d" % w.respect)
	# A paint locked by Syrenki is not bought with money.
	_expect(Garage.rule("silver", "red", 9999, {}, 99, 3) == "locked", "silver bought with money")
	_flush(s)
	var before := hud.notes.size()
	for e in s.entries:
		s.tick(Vector3(e["anchor"].x, 0.0, e["anchor"].y))
	_expect(hud.notes.size() == before and w.zl == 450, "finds after the last")
	s.free()
	hud.free()
	w.free()


func _save() -> void:
	DirAccess.remove_absolute(SCRATCH)
	var w := Wallet.new()
	w.path = SCRATCH
	var hud := Fakes.Hud.new()
	var s := _make(w, hud)
	for i in 3:
		s.collect(str(s.entries[i]["id"]))
	_expect(FileAccess.file_exists(SCRATCH), "no file saved")
	var again := Wallet.new()
	again.path = SCRATCH
	again.load_save()
	_expect(again.syrenki == w.syrenki and again.syrenki.size() == 3, "reloaded: %s vs %s" % [again.syrenki, w.syrenki])
	_expect(again.respect == 15, "reloaded respect %d" % again.respect)
	# A second run knows what is found.
	var s2 := _make(again, hud)
	var n := hud.notes.size()
	s2.tick(_at(s2, 0))
	_expect(hud.notes.size() == n, "a found Syrenka found again after a reload")
	for f in [SCRATCH, again.backup_path(1)]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	s.free()
	s2.free()
	hud.free()
	w.free()
	again.free()


func _completion() -> void:
	var w := Wallet.new()
	w.persistent = false
	var d := Districts.new()
	d.wallet = w
	d.setup({})
	var s := Syrenki.new()
	s.wallet = w
	s.districts = d
	s.load_data()
	var before := d.progress("powisle")
	s.collect("s04_elektrownia")
	var after := d.progress("powisle")
	_expect(after.y == before.y and after.x == before.x + 1, "powisle %s -> %s" % [before, after])
	_expect(after.y > 0 and d.percent("powisle") > 0, "powisle %d%%" % d.percent("powisle"))
	s.free()
	d.free()
	w.free()


func _cost() -> void:
	var w := Wallet.new()
	w.persistent = false
	var s := _make(w, null)
	var t0 := Time.get_ticks_usec()
	for i in 1000:
		s.tick(Vector3(5000.0, 0.0, 5000.0))
	var us := float(Time.get_ticks_usec() - t0) / 1000.0
	print("syrenki: a look %.1f µs (5 a second)" % us)
	_expect(us < 100.0, "a look takes %.1f µs" % us)
	s.free()
	w.free()
