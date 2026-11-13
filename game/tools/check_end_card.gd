extends SceneTree
## Loop 3h slice 4: the end card's trigger (first10.gd `end_due`) and the save's [intro], without
## the map. Fixture wallets: "Trzy mosty" won and 9 jobs -> no card; 10 jobs -> the card; seen
## (`end_seen`) -> no card; 10 jobs without the final -> none; races and the courier's bonus are
## not jobs (wallet.gd `jobs_done`); an old save's totals by kind count (a v2 file without [intro]
## loads as nothing seen, its jobs counted). The card's words (Polish above English, the credits,
## the repo's name) and its button; the card shown on a stand-in HUD, `end_seen` kept, the button
## closes it (free roam). The [intro] section round-trips through a scratch file; --nosave writes
## nothing.
##   godot --headless --path game --script res://tools/check_end_card.gd

const First10 := preload("res://scripts/first10.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Fakes := preload("res://tools/fakes.gd")
const SCRATCH := "user://check_end_card_scratch.cfg"
const SCRATCH_OFF := "user://check_end_card_off.cfg"


var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_fixtures()
	_old_save()
	_card()
	_save()
	for p in [SCRATCH, SCRATCH_OFF]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	if _problems == 0:
		print("end_card: OK (final + 9 jobs no, + 10 yes, seen no, races and couriers aren't jobs, old saves count, the card and free roam, [intro] saved)")
		quit(0)
	else:
		print("check_end_card: %d problem(s)" % _problems)
		quit(1)


func _wallet(final: bool, jobs: Dictionary) -> Wallet:
	var w := Wallet.new()
	w.persistent = false
	if final:
		for i in Ladder.FINAL + 1:
			w.ladder[Ladder.id_of(i)] = 20261031
	w.jobs = jobs.duplicate()
	return w


func _fixtures() -> void:
	var nine := _wallet(true, {"kebab": 5, "rescue": 2, "sloik": 1, "podwozka": 1})
	_expect(nine.jobs_done() == 9 and not First10.end_due(nine), "final + 9 jobs: no card (%d jobs)" % nine.jobs_done())
	var ten := _wallet(true, {"kebab": 5, "rescue": 2, "sloik": 1, "podwozka": 1, "roundup": 1})
	_expect(ten.jobs_done() == 10 and First10.end_due(ten), "final + 10 jobs: the card")
	ten.intro["end_seen"] = 20261031
	_expect(not First10.end_due(ten), "seen: no card again")
	var no_final := _wallet(false, {"kebab": 12})
	_expect(not First10.end_due(no_final), "10+ jobs without the final: no card")
	var races := _wallet(true, {"kebab": 5, "rescue": 2, "sloik": 1, "trend": 1, "race": 9, "courier": 4})
	_expect(races.jobs_done() == 9 and not First10.end_due(races), "races and the courier's bonus are not jobs: %d" % races.jobs_done())
	var only_final := _wallet(false, {"kebab": 10})
	only_final.ladder[Ladder.FINAL_ID] = 20261031
	_expect(First10.end_due(only_final), "the record is the final's key (trzy_mosty)")
	_expect(not First10.end_due(null), "no wallet: no card")
	for w in [nine, ten, no_final, races, only_final]:
		w.free()


## A save from before slice 4 (v2, no [intro]): its jobs by kind count, nothing seen.
func _old_save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "version", 2)
	cfg.set_value("wallet", "zl", 2400)
	cfg.set_value("jobs", "kebab", 7)
	cfg.set_value("jobs", "rescue", 3)
	cfg.set_value("jobs", "race", 8)
	cfg.set_value("ladder", "trzy_mosty", 20261031)
	cfg.save(SCRATCH)
	var w := Wallet.new()
	w.path = SCRATCH
	w.load_save()
	_expect(w.intro.is_empty() and w.jobs_done() == 10 and w.zl == 2400, "an old save: intro %s, %d jobs, %d zł" % [w.intro, w.jobs_done(), w.zl])
	_expect(First10.end_due(w), "an old save that has done it all gets the card")
	_expect(not First10.guide_due(w), "an old save with progress never gets the guide")
	w.free()


func _card() -> void:
	var w := _wallet(true, {"kebab": 10})
	var hud := Fakes.Hud.new()
	var f := First10.new()
	f.wallet = w
	f.hud = hud
	f.hud.card_pressed.connect(f._on_card)
	f.show_end_card()
	_expect(hud.card != "" and hud.card == First10.END_TITLE[0] and First10.REPO in hud.body, "the card is up: %s" % hud.card)
	_expect(hud.button_words.size() == 1 and hud.button_words[0] == First10.END_BUTTON, "one button, Jedź dalej · Free roam: %s" % [hud.button_words])
	_expect(w.intro.has("end_seen") and not First10.end_due(w), "end_seen kept")
	_expect(f.end_card_shown(), "the director knows the card is up")
	hud.card_pressed.emit(0)
	_expect(hud.card == "" and not f.end_card_shown(), "the button closes it: free roam")
	var lines := First10.end_words()[1].split("\n")
	_expect(lines.size() == 2 and lines[0].begins_with(First10.END_BODY[0]) and First10.REPO in lines[1], "the Polish body, line by line: %s" % [lines])
	f.free()
	hud.free()
	w.free()


func _save() -> void:
	if FileAccess.file_exists(SCRATCH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	var w := Wallet.new()
	w.path = SCRATCH
	w.load_save()
	w.intro = {"finger": 20261031, "race": 20261031, "end_seen": 20261101}
	w.save()
	var b := Wallet.new()
	b.path = SCRATCH
	b.load_save()
	_expect(b.intro == w.intro, "[intro] round trip: %s" % b.intro)
	b.reset()
	_expect(b.intro.is_empty(), "reset() clears [intro]")
	var off := Wallet.new()
	off.persistent = false
	off.path = SCRATCH_OFF
	off.intro["done"] = 1
	off.save()
	_expect(not FileAccess.file_exists(SCRATCH_OFF), "--nosave wrote %s" % SCRATCH_OFF)
	w.free()
	b.free()
	off.free()
