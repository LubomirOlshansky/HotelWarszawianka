extends SceneTree
## Loop 3h slice 1: save v2 (wallet.gd, settings.gd). Builds an old-format (version 1, no
## `[save]` section) save.cfg in a scratch file with every section the game wrote before loop 3h
## (wallet, jobs, best, eggs, one saved as `true` as v0.65 did, police, keep with an array,
## notes, chapters, PÓŁNOC FM, tapes, Kadr and its photos, the garage) plus a section from "a
## newer build", and checks that:
## - loading it keeps every value, reports version 1 migrated to 2, and copies the old file beside
##   it unchanged (save.v1.cfg);
## - the next save writes version 2, keeps the unknown section, and a fresh load of it gives the
##   same record (and the v2 additions: districts, their jobs, the Syrenki round-trip; loop 3h
##   slice 4: the [intro] section too);
## - a job paid in a district counts there; reset() clears the v2 sections too;
## - a file of a newer version is read but never overwritten;
## - with persistent = false (--nosave) nothing is read or written (no file appears);
## - a missing file gives the defaults and version 0;
## - settings.cfg: a file without `[meta]` loads as version 1 and the next save writes 2; a newer
##   one is never overwritten; --nosave writes nothing.
## - save and resume (2026-10-31): the [session] spot's round trip, remember_spot's 5 m rule,
##   has_progress, start_over (a copy of the old file as save.prev.cfg, then wiped; never for a
##   newer file; nothing written under --nosave), and the title's choice: KONTYNUUJ, NOWA GRA's
##   question, NIE back, TAK emitting new_game, and the keys.
## - safer saves (tech-debt TD-8, 2026-11-12): a file this build writes is sealed (`[save]
##   sealed=true` first, `[end] ok=true` last) and no temp file is left; a file that loaded whole
##   becomes the next launch's copy (save.bak.cfg); a damaged file (empty, cut short at a line or
##   inside the first section, plain text, bytes that are not text) is moved aside byte for byte as
##   save.bad-<time>.cfg, never written over, and the copy is loaded and written back; with no
##   copy, or a damaged one, the game starts fresh and the next write makes a whole file; a write
##   that fails leaves the old file as it was; a missing file is a fresh start even with a copy;
##   an unsealed file (every save before TD-8) loads and the next write seals it; only the last
##   BAD_KEPT damaged files are kept; settings.cfg is written the same way.
## Never touches the real user://save.cfg or settings.cfg; deletes its scratch files.
##   godot --headless --path game --script res://tools/check_save.gd

const Wallet := preload("res://scripts/wallet.gd")
const Settings := preload("res://scripts/settings.gd")
const Title := preload("res://scripts/title.gd")
const SCRATCH := "user://check_save.cfg"
const SCRATCH_NEW := "user://check_save_newer.cfg"
const SCRATCH_OFF := "user://check_save_nosave.cfg"
const SCRATCH_SET := "user://check_save_settings.cfg"
const SCRATCH_BAD := "user://check_save_bad.cfg"

var _problems := 0


func _initialize() -> void:
	_clean()
	_old_save()
	_round_trip()
	_newer()
	_nosave()
	_missing()
	_damaged()
	_settings()
	_resume()
	await process_frame  # the title's _ready runs inside the tree's first frame
	_title()
	_clean()
	if _problems == 0:
		print("check_save: OK")
		quit(0)
	else:
		print("check_save: %d problem(s)" % _problems)
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


## The version-1 fixture: what wallet.gd wrote before loop 3h, section by section.
func _v1_fixture() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.set_value("wallet", "zl", 1240)
	cfg.set_value("wallet", "respect", 87)
	cfg.set_value("jobs", "kebab", 4)
	cfg.set_value("jobs", "race", 2)
	cfg.set_value("best", "race_0", 61.4)
	cfg.set_value("eggs", "palma", true)
	cfg.set_value("eggs", "e03", 20261030)
	cfg.set_value("police", "cautions_today", 2)
	cfg.set_value("police", "cautions_day", 20261031)
	cfg.set_value("police", "escapes_total", 3)
	cfg.set_value("keep", "podwozka_ratings", [5, 4, 5])
	cfg.set_value("keep", "podwozka_streak", 2)
	cfg.set_value("notes", "patelnia", 20261029)
	cfg.set_value("notes", "bulwary", 20261030)
	cfg.set_value("notes_chapters", "schodki", 20261030)
	cfg.set_value("polnoc", "track_3", 20261030)
	cfg.set_value("polnoc", "chapters", 1)
	cfg.set_value("tapes", "t01", 20261030)
	cfg.set_value("kadr", "k02", 20261030)
	cfg.set_value("kadr_photos", "k02", "user://photos/k02.png")
	cfg.set_value("garage", "paint", "teal")
	cfg.set_value("garage", "own_teal", 20261031)
	cfg.set_value("from_the_future", "thing", 42)
	return cfg


func _check_v1_values(w: Node, label: String) -> void:
	_expect(w.zl == 1240 and w.respect == 87, "%s: wallet %d zł, respect %d" % [label, w.zl, w.respect])
	_expect(w.jobs == {"kebab": 4, "race": 2}, "%s: jobs %s" % [label, w.jobs])
	_expect(is_equal_approx(float(w.best.get("race_0", 0.0)), 61.4), "%s: best %s" % [label, w.best])
	_expect(w.eggs == {"palma": 1, "e03": 20261030}, "%s: eggs %s" % [label, w.eggs])
	_expect(w.cautions_today == 2 and w.cautions_day == 20261031 and w.escapes_total == 3, "%s: police %d %d %d" % [label,
			w.cautions_today, w.cautions_day, w.escapes_total])
	_expect(w.keep.get("podwozka_ratings") == [5, 4, 5] and int(w.keep.get("podwozka_streak", 0)) == 2, "%s: keep %s" % [label, w.keep])
	_expect(w.notes == {"patelnia": 20261029, "bulwary": 20261030}, "%s: notes %s" % [label, w.notes])
	_expect(w.chapters_done == {"schodki": 20261030}, "%s: chapters %s" % [label, w.chapters_done])
	_expect(w.tracks == {3: 20261030} and w.track_chapters == 1, "%s: polnoc %s %d" % [label, w.tracks, w.track_chapters])
	_expect(w.tapes == {"t01": 20261030} and w.kadr == {"k02": 20261030}, "%s: tapes %s kadr %s" % [label, w.tapes, w.kadr])
	_expect(w.kadr_photos == {"k02": "user://photos/k02.png"}, "%s: kadr photos %s" % [label, w.kadr_photos])
	_expect(w.paint == "teal" and w.paints == {"teal": 20261031}, "%s: garage %s %s" % [label, w.paint, w.paints])


func _old_save() -> void:
	_v1_fixture().save(SCRATCH)
	var before := FileAccess.get_file_as_string(SCRATCH)
	var w := Wallet.new()
	w.path = SCRATCH
	w.load_save()
	_check_v1_values(w, "v1 loaded")
	_expect(w.loaded_version == 1 and w.migrated_from == 1 and not w.newer, "v1: version %d, migrated from %d" % [
			w.loaded_version, w.migrated_from])
	_expect(w.districts.is_empty() and w.district_jobs.is_empty() and w.syrenki.is_empty(), "v1: v2 sections not empty")
	var backup := w.backup_path(1)
	_expect(FileAccess.file_exists(backup) and FileAccess.get_file_as_string(backup) == before, "v1: the old file kept as %s" % backup)
	# The next save writes v2 and keeps the section this build does not know.
	w.save()
	var cfg := ConfigFile.new()
	_expect(cfg.load(SCRATCH) == OK, "v1 -> v2: the file reads")
	_expect(int(cfg.get_value("save", "version", 0)) == Wallet.VERSION, "v1 -> v2: version %s" % cfg.get_value("save", "version", "-"))
	_expect(int(cfg.get_value("from_the_future", "thing", 0)) == 42, "v1 -> v2: the unknown section dropped")
	_expect(cfg.get_value("eggs", "palma") is int, "v1 -> v2: the egg saved as true is still a bool")
	var again := Wallet.new()
	again.path = SCRATCH
	again.load_save()
	_check_v1_values(again, "v2 reloaded")
	_expect(again.loaded_version == 2 and again.migrated_from == 0, "v2 reloaded: version %d, migrated from %d" % [
			again.loaded_version, again.migrated_from])
	w.free()
	again.free()
	# migrate() on its own: a false egg is dropped, true becomes 1, the version is set.
	var m := ConfigFile.new()
	m.set_value("eggs", "a", true)
	m.set_value("eggs", "b", false)
	_expect(Wallet.migrate(m, 1) == 2 and m.get_value("eggs", "a") == 1 and not m.has_section_key("eggs", "b")
			and int(m.get_value("save", "version", 0)) == 2, "migrate(1): %s" % m.encode_to_text())


func _round_trip() -> void:
	var w := Wallet.new()
	w.path = SCRATCH
	w.load_save()
	w.districts = {"powisle": 20261031, "srodmiescie": 20261030}
	w.syrenki = {"s01": 20261031}
	w.intro = {"finger": 20261031, "end_seen": 20261031}  # loop 3h slice 4
	w.district = "powisle"
	w.pay(25, 1, "kebab")
	w.pay(10, 0)  # no kind: not a job
	_expect(w.district_jobs == {"powisle": 1}, "a job paid in Powiśle: %s" % w.district_jobs)
	_expect(int(w.jobs.get("kebab", 0)) == 5, "the job counted by kind too: %s" % w.jobs)
	var b := Wallet.new()
	b.path = SCRATCH
	b.load_save()
	_expect(b.districts == w.districts and b.district_jobs == w.district_jobs and b.syrenki == w.syrenki,
			"round trip of the v2 sections: %s %s %s" % [b.districts, b.district_jobs, b.syrenki])
	_expect(b.zl == 1275 and b.respect == 88 and b.notes == w.notes and b.eggs == w.eggs and b.paints == w.paints
			and b.keep == w.keep and b.tracks == w.tracks, "round trip of the v1 sections: %s" % b.summary())
	_expect(b.district == "", "the district now is not saved: %s" % b.district)
	_expect(b.intro == w.intro, "round trip of [intro] (loop 3h slice 4): %s" % b.intro)
	b.reset()
	_expect(b.districts.is_empty() and b.district_jobs.is_empty() and b.syrenki.is_empty() and b.intro.is_empty() and b.zl == 0, "reset() left %s" % b.summary())
	w.free()
	b.free()


func _newer() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "version", Wallet.VERSION + 1)
	cfg.set_value("wallet", "zl", 500)
	cfg.set_value("next_thing", "x", 1)
	cfg.save(SCRATCH_NEW)
	var before := FileAccess.get_file_as_string(SCRATCH_NEW)
	var w := Wallet.new()
	w.path = SCRATCH_NEW
	w.load_save()
	_expect(w.newer and w.zl == 500, "a newer save: newer %s, %d zł" % [w.newer, w.zl])
	w.pay(100, 1, "kebab")
	_expect(FileAccess.get_file_as_string(SCRATCH_NEW) == before, "a newer save was overwritten")
	_expect(not FileAccess.file_exists(w.backup_path(Wallet.VERSION + 1)), "a newer save got a backup")
	w.free()


func _nosave() -> void:
	var w := Wallet.new()
	w.persistent = false
	w.path = SCRATCH_OFF
	w.load_save()
	w.district = "praga"
	w.pay(50, 2, "race")
	w.find_egg("palma", 20261031)
	w.districts["praga"] = 20261031
	w.save()
	w.reset()
	_expect(not FileAccess.file_exists(SCRATCH_OFF), "--nosave wrote %s" % SCRATCH_OFF)
	# A v1 file under --nosave: not read, not migrated, no backup.
	_v1_fixture().save(SCRATCH_OFF)
	var off := Wallet.new()
	off.persistent = false
	off.path = SCRATCH_OFF
	off.load_save()
	_expect(off.zl == 0 and off.loaded_version == 0 and not FileAccess.file_exists(off.backup_path(1)), "--nosave read or backed up a v1 file")
	w.free()
	off.free()


func _missing() -> void:
	var w := Wallet.new()
	w.path = "user://check_save_missing.cfg"
	w.load_save()
	_expect(w.zl == 0 and w.loaded_version == 0 and w.migrated_from == 0 and w.paint == "red" and w.districts.is_empty(),
			"a missing file: %s" % w.summary())
	w.free()


func _settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "scheme", 1)
	cfg.set_value("world", "traffic", 3)
	cfg.set_value("world", "quality", 2)  # High before loop G1: Auto, once
	cfg.save(SCRATCH_SET)
	var s := Settings.new()
	s.path = SCRATCH_SET
	s.load_file()
	_expect(s.loaded_version == 1 and s.controls == 1 and s.traffic == 3 and s.quality == Settings.AUTO,
			"settings v1: version %d, %s" % [s.loaded_version, s.summary()])
	s.save()
	var out := ConfigFile.new()
	out.load(SCRATCH_SET)
	_expect(int(out.get_value("meta", "version", 0)) == Settings.VERSION, "settings: the save wrote version %s" % out.get_value("meta", "version", "-"))
	var t := Settings.new()
	t.path = SCRATCH_SET
	t.load_file()
	_expect(t.loaded_version == Settings.VERSION and t.controls == 1 and t.traffic == 3 and t.quality == Settings.AUTO,
			"settings v2 reloaded: version %d, %s" % [t.loaded_version, t.summary()])
	out.set_value("meta", "version", Settings.VERSION + 1)
	out.save(SCRATCH_SET)
	var before := FileAccess.get_file_as_string(SCRATCH_SET)
	var n := Settings.new()
	n.path = SCRATCH_SET
	n.load_file()
	n.controls = 2
	n.save()
	_expect(n.newer and FileAccess.get_file_as_string(SCRATCH_SET) == before, "settings: a newer file was overwritten")
	var off := Settings.new()
	off.persistent = false
	off.path = "user://check_save_settings_off.cfg"
	off.save()
	_expect(not FileAccess.file_exists(off.path), "settings: --nosave wrote a file")


func _resume() -> void:
	var w := Wallet.new()
	w.path = SCRATCH
	w.load_save()
	w.reset()
	_expect(not w.has_progress() and w.resume_spot().is_empty(), "a wiped save has progress: %s" % w.summary())
	_expect(w.remember_spot(Vector3(-696.0, 31.2, -1279.0), 1.25, false, 1793000000), "the first spot not written")
	_expect(not w.remember_spot(Vector3(-693.0, 31.2, -1279.0), 0.5, false, 1793000005), "a spot 3 m away was written")
	_expect(w.remember_spot(Vector3(-693.0, 31.2, -1279.0), 0.5, true, 1793000006), "into a tunnel (same place) not written")
	_expect(w.remember_spot(Vector3(-680.0, 31.2, -1279.0), 0.5, true, 1793000010), "a spot 13 m away not written")
	_expect(w.has_progress(), "a kept spot is not progress")
	var b := Wallet.new()
	b.path = SCRATCH
	b.load_save()
	var spot := b.resume_spot()
	_expect(spot.size() == 3 and (spot[0] as Vector3).is_equal_approx(Vector3(-680.0, 0.0, -1279.0)) and is_equal_approx(float(spot[1]), 0.5)
			and spot[2] == true and int(b.session.get("at", 0)) == 1793000010, "the spot's round trip: %s" % [spot])
	b.pay(40, 2, "kebab")
	b.free()
	w.free()
	# NOWA GRA: the old file copied to save.prev.cfg, then everything wiped and written.
	var before := FileAccess.get_file_as_string(SCRATCH)
	var c := Wallet.new()
	c.path = SCRATCH
	c.load_save()
	_expect(c.zl == 40 and c.has_progress(), "before the new game: %s" % c.summary())
	_expect(c.start_over(), "start_over refused")
	_expect(FileAccess.get_file_as_string(c.previous_path()) == before, "the old save not kept as %s" % c.previous_path())
	_expect(c.zl == 0 and not c.has_progress(), "start_over left %s" % c.summary())
	var d := Wallet.new()
	d.path = SCRATCH
	d.load_save()
	_expect(d.zl == 0 and d.resume_spot().is_empty() and d.jobs.is_empty(), "after a new game the file has %s" % d.summary())
	c.free()
	d.free()
	# A newer build's file: never wiped.
	var cfg := ConfigFile.new()
	cfg.set_value("save", "version", Wallet.VERSION + 1)
	cfg.set_value("wallet", "zl", 500)
	cfg.save(SCRATCH_NEW)
	var n := Wallet.new()
	n.path = SCRATCH_NEW
	n.load_save()
	_expect(not n.start_over() and n.zl == 500 and not FileAccess.file_exists(n.previous_path()), "a newer save was wiped")
	n.free()
	# --nosave: start_over writes nothing, remember_spot neither.
	var off := Wallet.new()
	off.persistent = false
	off.path = SCRATCH_OFF
	if FileAccess.file_exists(SCRATCH_OFF):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_OFF))
	off.remember_spot(Vector3(1.0, 0.0, 2.0), 0.0, false, 1)
	off.start_over()
	_expect(not FileAccess.file_exists(SCRATCH_OFF) and not FileAccess.file_exists(off.previous_path()), "--nosave wrote on a new game")
	off.free()


func _title() -> void:
	var t := Title.new()
	root.add_child(t)
	var asked := [0]
	t.new_game.connect(func() -> void: asked[0] += 1)
	t.can_resume = true
	t.resume_line = "1 240 zł · respekt 87"
	t.set_ready()
	_expect(t._prompt.text == "KONTYNUUJ" and t._new_btn.visible and t._line.visible and not t._yes_btn.visible,
			"the choice: '%s', NOWA GRA %s" % [t._prompt.text, t._new_btn.visible])
	_expect(t._pick(KEY_ENTER, Vector2.INF) == "continue" and t._pick(KEY_N, Vector2.INF) == "new", "the choice's keys")
	_expect(t._pick(KEY_NONE, t._new_btn.get_global_rect().get_center()) == "new", "a tap on NOWA GRA")
	_expect(t._pick(KEY_NONE, Vector2(5.0, 5.0)) == "continue", "a tap elsewhere is not continue")
	t.choose("new")
	_expect(t.screen == Title.CONFIRM and t._prompt.text.begins_with("ZACZĄĆ OD NOWA?") and t._yes_btn.visible and t._no_btn.visible
			and not t._new_btn.visible, "the question: '%s'" % t._prompt.text)
	_expect(t._pick(KEY_ENTER, Vector2.INF) == "" and t._pick(KEY_ESCAPE, Vector2.INF) == "no" and t._pick(KEY_Y, Vector2.INF) == "yes",
			"the question's keys")
	_expect(t._pick(KEY_NONE, t._yes_btn.get_global_rect().get_center()) == "yes"
			and t._pick(KEY_NONE, t._no_btn.get_global_rect().get_center()) == "no", "taps on TAK / NIE")
	_expect(t._yes_btn.get_global_rect().intersection(t._no_btn.get_global_rect()).get_area() <= 0.0, "TAK and NIE overlap")
	t.choose("no")
	_expect(t.screen == Title.CHOICE and t._new_btn.visible and asked[0] == 0, "NIE: not back to the choice")
	t.choose("new")
	t.choose("yes")
	_expect(asked[0] == 1, "TAK: new_game emitted %d times" % asked[0])
	t.free()
	# No save to resume: the old "tap to drive", no buttons.
	var f := Title.new()
	root.add_child(f)
	f.set_ready()
	_expect(f._prompt.text == "DOTKNIJ, BY JECHAĆ" and not f._new_btn.visible and not f._line.visible, "a fresh save's title: '%s'" % f._prompt.text)
	f.free()


## TD-8: a wallet on the scratch file, loaded as a launch does (the copy kept too).
func _launch() -> Node:
	var w := Wallet.new()
	w.path = SCRATCH_BAD
	w.load_save()
	w.keep_copy()
	return w


func _put(path: String, bytes: PackedByteArray) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()


func _bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()


func _drop(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Removes the scratch save, its copy, its temp files and every damaged file kept beside it.
func _clean_bad() -> void:
	for f in DirAccess.get_files_at("user://"):
		if f.begins_with("check_save_bad."):
			_drop("user://" + f)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SCRATCH_BAD + ".tmp")):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_BAD + ".tmp"))


## TD-8 (safer saves): the file's seal, the launch copy, every kind of damage, a failed write.
func _damaged() -> void:
	_clean_bad()
	var copy := "user://check_save_bad.bak.cfg"
	# A record worth losing, written by this build.
	var w := Wallet.new()
	w.path = SCRATCH_BAD
	w.notes = {"patelnia": 20261101, "bulwary": 20261102}
	w.keep = {"podwozka_ratings": [5, 4, 5]}
	w.ladder = {"halina": 20261103}
	w.pay(900, 30, "kebab")
	w.free()
	var good := _bytes(SCRATCH_BAD)
	var text := good.get_string_from_utf8()
	_expect(text.begins_with("[save]\n\nsealed=true\n") and text.ends_with("[end]\n\nok=true\n"),
			"a written file is not sealed first and ended last: %s ... %s" % [text.left(24).c_escape(), text.right(18).c_escape()])
	_expect(not FileAccess.file_exists(SCRATCH_BAD + ".tmp"), "a write left its temp file")
	var whole := ConfigFile.new()
	_expect(Wallet.read_whole(SCRATCH_BAD, whole) == "" and Wallet.damage(whole) == "", "a written file reads as damaged: %s" % Wallet.read_whole(SCRATCH_BAD, whole))
	# A launch: the file loads whole and becomes the copy.
	w = _launch()
	_expect(w.zl == 900 and w.respect == 30 and w.load_note == "" and w.bad_path == "" and not w.blocked and w._extra.is_empty(),
			"a whole file: %s, note '%s', extra %s" % [w.summary(), w.load_note, w._extra])
	_expect(_bytes(copy) == good, "a launch did not keep the copy %s" % copy)
	w.free()
	# Every kind of damage, with a good copy beside it: the copy is loaded and written back, the
	# damaged file is kept byte for byte.
	var line := text.rfind("\n", int(text.length() * 0.6)) + 1
	var kinds := {
		"empty": [PackedByteArray(), "empty"],
		"cut at a line": [good.slice(0, text.left(line).to_utf8_buffer().size()), "cut short"],
		"cut inside the first section": [good.slice(0, 10), "empty"],
		"cut after the seal": ["[save]\n\nsealed=true\nversion=2\n".to_utf8_buffer(), "cut short"],
		"plain text": ["this is not a save\nzl=5\n".to_utf8_buffer(), "not a save"],
		"not text": [PackedByteArray([91, 115, 0, 255, 13, 7, 200, 1, 2, 3]), "not text"],
	}
	for kind: String in kinds:
		var broken: PackedByteArray = kinds[kind][0]
		_put(SCRATCH_BAD, broken)
		w = _launch()
		_expect(w.load_note == "restored" and w.bad_why == str(kinds[kind][1]), "%s: note '%s', why '%s'" % [kind, w.load_note, w.bad_why])
		_expect(w.zl == 900 and w.respect == 30 and w.notes.size() == 2 and w.ladder.has("halina") and w.keep.get("podwozka_ratings") == [5, 4, 5],
				"%s: the copy's record was not loaded: %s" % [kind, w.summary()])
		_expect(w.bad_path != "" and _bytes(w.bad_path) == broken, "%s: the damaged file was not kept as it was (%s)" % [kind, w.bad_path])
		_expect(_bytes(SCRATCH_BAD) == good and _bytes(copy) == good, "%s: the copy was not written back, or was changed" % kind)
		w.pay(10, 0)
		var after := ConfigFile.new()
		_expect(Wallet.read_whole(SCRATCH_BAD, after) == "" and int(after.get_value("wallet", "zl", 0)) == 910, "%s: the next write: %s" % [kind, after.get_value("wallet", "zl", "-")])
		_drop(w.bad_path)
		w.free()
		_put(SCRATCH_BAD, good)
	# No copy: a fresh start, the damaged file kept, and the next write makes a whole file.
	_drop(copy)
	var cut: PackedByteArray = kinds["cut at a line"][0]
	_put(SCRATCH_BAD, cut)
	w = _launch()
	_expect(w.load_note == "lost" and w.zl == 0 and w.loaded_version == 0 and w.notes.is_empty(), "no copy: note '%s', %s" % [w.load_note, w.summary()])
	_expect(_bytes(w.bad_path) == cut and not FileAccess.file_exists(SCRATCH_BAD) and not FileAccess.file_exists(copy),
			"no copy: the damaged file not kept, or a file written at load")
	w.pay(5, 0)
	var fresh := ConfigFile.new()
	_expect(Wallet.read_whole(SCRATCH_BAD, fresh) == "" and int(fresh.get_value("wallet", "zl", 0)) == 5, "no copy: the first write after a fresh start")
	_drop(w.bad_path)
	w.free()
	# A damaged copy too: a fresh start, and the damaged copy is left where it is.
	_put(SCRATCH_BAD, cut)
	_put(copy, cut)
	w = _launch()
	_expect(w.load_note == "lost" and w.zl == 0 and _bytes(copy) == cut, "a damaged copy: note '%s', %d zł" % [w.load_note, w.zl])
	_drop(w.bad_path)
	w.free()
	# A missing file is a fresh start even with a copy beside it (deleting the save resets).
	_drop(SCRATCH_BAD)
	_put(copy, good)
	w = _launch()
	_expect(w.zl == 0 and w.load_note == "" and w.loaded_version == 0 and _bytes(copy) == good and not FileAccess.file_exists(SCRATCH_BAD),
			"a missing file with a copy: %d zł, note '%s'" % [w.zl, w.load_note])
	w.free()
	# A write that fails (the temp file's name is taken by a folder) leaves the old file as it was.
	_put(SCRATCH_BAD, good)
	w = _launch()
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SCRATCH_BAD + ".tmp"))
	w.pay(1, 0)
	_expect(w.save_failures == 1 and w.save_error != OK and _bytes(SCRATCH_BAD) == good, "a failed write: failures %d, error %d, file changed %s" % [
			w.save_failures, w.save_error, _bytes(SCRATCH_BAD) != good])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_BAD + ".tmp"))
	w.save()
	var later := ConfigFile.new()
	_expect(w.save_error == OK and w.save_failures == 1 and Wallet.read_whole(SCRATCH_BAD, later) == "" and int(later.get_value("wallet", "zl", 0)) == 901,
			"the write after a failed one: error %d, %s zł" % [w.save_error, later.get_value("wallet", "zl", "-")])
	w.free()
	# An unsealed file (every save before TD-8, and what an older build writes back): loads whole,
	# and the next write seals it. One cut before [wallet] is caught without the seal.
	var old := ConfigFile.new()
	old.set_value("save", "version", 2)
	old.set_value("wallet", "zl", 321)
	old.set_value("end", "ok", true)  # as an older build writes a newer file back: no seal, the end kept
	old.save(SCRATCH_BAD)
	w = _launch()
	_expect(w.zl == 321 and w.load_note == "" and not w._extra.has("end"), "an unsealed file: %d zł, note '%s', extra %s" % [w.zl, w.load_note, w._extra])
	w.save()
	_expect(_bytes(SCRATCH_BAD).get_string_from_utf8().begins_with("[save]\n\nsealed=true\n"), "an unsealed file was not sealed by the next write")
	w.free()
	_drop(copy)
	_put(SCRATCH_BAD, "[save]\n\nversion=2\n".to_utf8_buffer())
	w = _launch()
	_expect(w.load_note == "lost" and w.bad_why == "cut short", "an unsealed file cut before [wallet]: note '%s', why '%s'" % [w.load_note, w.bad_why])
	_drop(w.bad_path)
	w.free()
	# Only the last BAD_KEPT damaged files are kept.
	for i in Wallet.BAD_KEPT + 2:
		_put(SCRATCH_BAD, ("plain %d\n" % i).to_utf8_buffer())
		w = _launch()
		w.free()
	var probe := Wallet.new()
	probe.path = SCRATCH_BAD
	var kept := probe.bad_files()
	var last := ""
	for f in kept:
		last += _bytes(f).get_string_from_utf8().strip_edges() + ", "
	_expect(kept.size() == Wallet.BAD_KEPT and last == "plain 2, plain 3, plain 4, ", "damaged files kept: %d (%s)" % [kept.size(), last])
	probe.free()
	_clean_bad()


func _clean() -> void:
	_clean_bad()
	_drop(SCRATCH_SET + ".tmp")
	for p in [SCRATCH, SCRATCH_NEW, SCRATCH_OFF, SCRATCH_SET, "user://check_save.v1.cfg", "user://check_save_nosave.v1.cfg",
			"user://check_save_newer.v3.cfg", "user://check_save_settings_off.cfg", "user://check_save_missing.cfg",
			"user://check_save.prev.cfg", "user://check_save_newer.prev.cfg", "user://check_save_nosave.prev.cfg"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
