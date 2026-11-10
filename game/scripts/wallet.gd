extends Node
## The player's wallet and record, shared by every activity and kept between
## sessions in user://save.cfg (a ConfigFile): złoty and respect, jobs done by kind,
## best times, and the easter eggs found. Races pay the rival's stake, rescues and
## side jobs pay their fares and tips. The garage loop: the złoty buy paint jobs at Warsztat u
## Mirka (garage.gd: `spend`, `paint`, `paints`; the save's [garage] section).
##
## Loop 3h slice 1, save v2: the file carries `[save] version` (VERSION). A file without it is
## version 1 (every save before loop 3h): `migrate` brings it up to date in memory, a copy of the
## old file is kept beside it once (`user://save.v1.cfg`, BACKUP), and the next save writes v2.
## Nothing is renamed from v1 to v2, so every section of v1 (wallet, jobs, best, eggs, police,
## keep, notes, chapters, PÓŁNOC FM, tapes, Kadr, the garage) loads as it was; v2 adds the
## districts (discovered, jobs done in each) and the Syrenki. A section this build does not know
## (a newer build's) is kept and written back as it was. A file from a newer version is read but
## never overwritten (`newer`). `--nosave` (persistent false) neither reads nor writes anything.

signal changed(zl: int, respect: int, gained: int)

const PATH := "user://save.cfg"
## Loop 3h slice 1: the save's format version (1: before loop 3h, no `[save]` section).
const VERSION := 2
## The sections this version reads and writes; any other is kept as it was (`_extra`).
const SECTIONS := ["save", "wallet", "jobs", "best", "eggs", "police", "keep", "notes", "notes_chapters",
		"polnoc", "tapes", "kadr", "kadr_photos", "garage", "districts", "district_jobs", "syrenki", "ladder", "intro", "cassettes", "session"]
## The easter eggs that count towards "found x/5".
const EGGS := {"palma": "The Palm on Rondo de Gaulle'a", "pigeons": "Pigeons on Plac Defilad",
		"barriers": "The wandering roadworks", "patelnia": "Patelnia by Metro Centrum",
		"syrenka": "The Mermaid on the boulevard"}
## Loop 3h slice 4: the job kinds that are not jobs for the end card's count (`jobs_done`): a race
## is a race, and the courier's bonus rides on a kebab delivery that counts already.
const NOT_JOBS := ["race", "courier"]

var zl := 0
var respect := 0
## Kind ("kebab", "sloik", "rescue", "race") -> how many done.
var jobs := {}
## Key -> best time in seconds.
var best := {}
## Egg id -> true once found (v0.65); loop MW-6: the day it was found (yyyymmdd), or 1 for a find
## saved before MW-6 (its day unknown). Every egg card of data/eggs.json (egg_book.gd) counts.
var eggs := {}
## Loop 3g-1 (police.md section 8.4): the joke notebook ("Zeszyt pouczeń"): cautions written
## today and the day they belong to (yyyymmdd; a new day starts it again), and escapes ever (for
## a later achievement). Never money: nothing the police do takes złoty or respect.
var cautions_today := 0
var cautions_day := 0
var escapes_total := 0
## Loop 2d-1: other things kept by name (rides.gd: "podwozka_ratings", the last 20 rides' stars,
## and "podwozka_streak", the 5-star rides in a row; ladder.gd: "race_lost_<rung id>", the races
## lost in a row to a rival, for the easier rematch).
var keep := {}
## Loop MW-1: the MOJA WARSZAWA notebook (notebook.gd): place id -> the day it was first found
## (yyyymmdd), and chapter id -> the day it was completed (its reward paid; MW-5's track unlock
## reads it).
var notes := {}
var chapters_done := {}
## Loop MW-5: PÓŁNOC FM's unlocked tracks (radio.gd): track number (1 = the first) -> the day it
## opened (yyyymmdd; the free ones are not listed), and how many finished chapters have been
## turned into tracks already (radio.gd `sync_chapters`).
var tracks := {}
var track_chapters := 0
## Loop MW-6: KASETA's then cards played (tape.gd): card id -> the day (yyyymmdd); and Fotka's Kadr
## spots shot (fotka.gd): spot id -> the day, with the photo's file under user://photos/ in
## `kadr_photos` (spot id -> path).
var tapes := {}
var kadr := {}
var kadr_photos := {}
## Loop MW-6: the egg cards in all (egg_book.gd sets it from data/eggs.json; the five of v0.65 alone
## without it).
var eggs_total := 0
## The garage loop: the paint on the car (garage.gd PAINTS id; "red", the factory paint, by
## default) and the paints bought (id -> the day, yyyymmdd; the factory red is never listed).
var paint := "red"
var paints := {}
## G13 (the upgrade shop, upgrades.gd): the car on the road ("hatch" by default, "tt" the Ołdi TT),
## the cars bought (id -> the day), the parts' levels (tyres, engine: 1-3) and whether the nitro is
## owned. The same [garage] section (keys car, ownc_<id>, tune_<part>, nitro); a save without them
## loads as the hatch, untuned, no nitro, so no version bump (an older build ignores the keys).
var car := "hatch"
var cars := {}
var tune := {}
var nitro := false
## Loop 3h slice 1 (save v2): the districts discovered (districts.gd: id -> the day, yyyymmdd),
## the jobs done in each (id -> count; `pay` counts a job in `district`, the one the vehicle is in),
## and the Syrenki found (the later slice's collectibles: id -> the day).
var districts := {}
var district_jobs := {}
var syrenki := {}
## The first-10 polish (cassettes.gd): the mixtapes taken, id -> the day (YYYYMMDD).
var cassettes := {}
## Loop 3h slice 3: the rival ladder (ladder.gd): rung id ("halina" ... "mike", and "trzy_mosty" for
## the final race) -> the day it was first beaten (yyyymmdd). The save's [ladder] section; a v2 file
## without it (slices 1-2) loads as nothing beaten (no version bump: the section is only added).
var ladder := {}
## Loop 3h slice 4: the guided first 10 minutes and the end card (first10.gd): beat id ("finger",
## "order", "race", ... "garage", "done") -> the day it happened (yyyymmdd), and "end_seen" once the
## end card was shown. The save's [intro] section; a v2 file without it loads as nothing seen (no
## version bump: the section is only added).
var intro := {}
## Save and resume (2026-10-31): where the last session's car was, for "KONTYNUUJ" on the next
## launch: x, z, yaw (radians), tunnel (1 when it was on a tunnel's floor) and at (unix seconds).
## main.gd `_remember_spot` keeps it every few seconds and when the app goes to the background.
## The save's [session] section; a file without it resumes at the start (no version bump: the
## section is only added, and an older build keeps it as an unknown section).
var session := {}
## The district the vehicle is in now (districts.gd sets it; not saved).
var district := ""
## False with --nosave: nothing is read or written.
var persistent := true
## Loop MW-5: the save's file (check_radio.gd points it at a scratch file of its own).
var path := PATH
## Loop 3h slice 1: the version of the file as loaded (0: no file), the version it was migrated
## from (0: none), and true when the file is from a newer build (then it is never overwritten).
var loaded_version := 0
var migrated_from := 0
var newer := false
## Sections of the file this version does not know: section -> {key: value}, written back.
var _extra := {}


func _ready() -> void:
	load_save()


func load_save() -> void:
	if not persistent:
		return
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	loaded_version = int(cfg.get_value("save", "version", 1))
	newer = loaded_version > VERSION
	if newer:
		print("wallet: %s is save version %d, newer than this build's %d: read, never overwritten" % [path, loaded_version, VERSION])
	elif loaded_version < VERSION:
		migrated_from = loaded_version
		if persistent:
			DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup_path(loaded_version)))
		migrate(cfg, loaded_version)
		print("wallet: save version %d migrated to %d (the old file kept as %s)" % [migrated_from, VERSION, backup_path(migrated_from)])
	_extra.clear()
	for section in cfg.get_sections():
		if not section in SECTIONS:
			_extra[section] = {}
			for key in cfg.get_section_keys(section):
				_extra[section][key] = cfg.get_value(section, key)
	zl = int(cfg.get_value("wallet", "zl", 0))
	respect = int(cfg.get_value("wallet", "respect", 0))
	for key in (cfg.get_section_keys("jobs") if cfg.has_section("jobs") else PackedStringArray()):
		jobs[key] = int(cfg.get_value("jobs", key, 0))
	for key in (cfg.get_section_keys("best") if cfg.has_section("best") else PackedStringArray()):
		best[key] = float(cfg.get_value("best", key, 0.0))
	for key in (cfg.get_section_keys("eggs") if cfg.has_section("eggs") else PackedStringArray()):
		var v: Variant = cfg.get_value("eggs", key, false)
		if v is int and int(v) > 0:
			eggs[key] = int(v)
		elif v is bool and v:
			eggs[key] = 1
	cautions_today = int(cfg.get_value("police", "cautions_today", 0))
	cautions_day = int(cfg.get_value("police", "cautions_day", 0))
	escapes_total = int(cfg.get_value("police", "escapes_total", 0))
	for key in (cfg.get_section_keys("keep") if cfg.has_section("keep") else PackedStringArray()):
		keep[key] = cfg.get_value("keep", key)
	for key in (cfg.get_section_keys("notes") if cfg.has_section("notes") else PackedStringArray()):
		notes[key] = int(cfg.get_value("notes", key, 0))
	for key in (cfg.get_section_keys("notes_chapters") if cfg.has_section("notes_chapters") else PackedStringArray()):
		chapters_done[key] = int(cfg.get_value("notes_chapters", key, 0))
	for key in (cfg.get_section_keys("polnoc") if cfg.has_section("polnoc") else PackedStringArray()):
		if key.begins_with("track_"):
			tracks[int(key.trim_prefix("track_"))] = int(cfg.get_value("polnoc", key, 0))
	track_chapters = int(cfg.get_value("polnoc", "chapters", 0))
	for key in (cfg.get_section_keys("tapes") if cfg.has_section("tapes") else PackedStringArray()):
		tapes[key] = int(cfg.get_value("tapes", key, 0))
	for key in (cfg.get_section_keys("kadr") if cfg.has_section("kadr") else PackedStringArray()):
		kadr[key] = int(cfg.get_value("kadr", key, 0))
	for key in (cfg.get_section_keys("kadr_photos") if cfg.has_section("kadr_photos") else PackedStringArray()):
		kadr_photos[key] = str(cfg.get_value("kadr_photos", key, ""))
	paint = str(cfg.get_value("garage", "paint", "red"))
	for key in (cfg.get_section_keys("garage") if cfg.has_section("garage") else PackedStringArray()):
		if key.begins_with("own_"):
			paints[key.trim_prefix("own_")] = int(cfg.get_value("garage", key, 1))
		elif key.begins_with("ownc_"):
			cars[key.trim_prefix("ownc_")] = int(cfg.get_value("garage", key, 1))
		elif key.begins_with("tune_"):
			tune[key.trim_prefix("tune_")] = clampi(int(cfg.get_value("garage", key, 0)), 0, 3)
	car = str(cfg.get_value("garage", "car", "hatch"))
	if car != "hatch" and not cars.has(car):
		car = "hatch"  # a car not owned (an edited file): back to the hatch
	nitro = bool(cfg.get_value("garage", "nitro", false))
	for key in (cfg.get_section_keys("districts") if cfg.has_section("districts") else PackedStringArray()):
		districts[key] = int(cfg.get_value("districts", key, 1))
	for key in (cfg.get_section_keys("district_jobs") if cfg.has_section("district_jobs") else PackedStringArray()):
		district_jobs[key] = int(cfg.get_value("district_jobs", key, 0))
	for key in (cfg.get_section_keys("syrenki") if cfg.has_section("syrenki") else PackedStringArray()):
		syrenki[key] = int(cfg.get_value("syrenki", key, 1))
	for key in (cfg.get_section_keys("ladder") if cfg.has_section("ladder") else PackedStringArray()):
		ladder[key] = int(cfg.get_value("ladder", key, 1))
	for key in (cfg.get_section_keys("intro") if cfg.has_section("intro") else PackedStringArray()):
		intro[key] = int(cfg.get_value("intro", key, 1))
	for key in (cfg.get_section_keys("cassettes") if cfg.has_section("cassettes") else PackedStringArray()):
		cassettes[key] = int(cfg.get_value("cassettes", key, 1))
	for key in (cfg.get_section_keys("session") if cfg.has_section("session") else PackedStringArray()):
		session[key] = cfg.get_value("session", key)


## Loop 3h slice 1: where the copy of a version-`version` file goes before it is migrated
## (beside the save: user://save.v1.cfg).
func backup_path(version: int) -> String:
	return path.get_basename() + ".v%d.cfg" % version


## Loop 3h slice 1: brings a save of version `from` up to VERSION in place, one step at a time.
## Returns the version it ends at. Each step only adds or reshapes: progress is never dropped.
static func migrate(cfg: ConfigFile, from: int) -> int:
	var v := from
	if v < 2:
		# 1 -> 2 (loop 3h): an egg saved as `true` (v0.65, before MW-6 kept the day) becomes 1
		# (found, the day unknown), as load_save always read it; the districts, their jobs and
		# the Syrenki start empty (districts.gd discovers, quietly, the districts of the places
		# and eggs already found).
		for key in (cfg.get_section_keys("eggs") if cfg.has_section("eggs") else PackedStringArray()):
			var e: Variant = cfg.get_value("eggs", key, false)
			if e is bool:
				if e:
					cfg.set_value("eggs", key, 1)
				else:
					cfg.erase_section_key("eggs", key)
		v = 2
	cfg.set_value("save", "version", v)
	return v


func save() -> void:
	if not persistent or newer:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("save", "version", VERSION)
	cfg.set_value("wallet", "zl", zl)
	cfg.set_value("wallet", "respect", respect)
	for key in jobs:
		cfg.set_value("jobs", key, jobs[key])
	for key in best:
		cfg.set_value("best", key, best[key])
	for key in eggs:
		cfg.set_value("eggs", key, int(eggs[key]))
	cfg.set_value("police", "cautions_today", cautions_today)
	cfg.set_value("police", "cautions_day", cautions_day)
	cfg.set_value("police", "escapes_total", escapes_total)
	for key in keep:
		cfg.set_value("keep", key, keep[key])
	for key in notes:
		cfg.set_value("notes", key, notes[key])
	for key in chapters_done:
		cfg.set_value("notes_chapters", key, chapters_done[key])
	for n in tracks:
		cfg.set_value("polnoc", "track_%d" % n, tracks[n])
	cfg.set_value("polnoc", "chapters", track_chapters)
	for key in tapes:
		cfg.set_value("tapes", key, tapes[key])
	for key in kadr:
		cfg.set_value("kadr", key, kadr[key])
	for key in kadr_photos:
		cfg.set_value("kadr_photos", key, kadr_photos[key])
	cfg.set_value("garage", "paint", paint)
	for key in paints:
		cfg.set_value("garage", "own_" + str(key), int(paints[key]))
	cfg.set_value("garage", "car", car)
	for key in cars:
		cfg.set_value("garage", "ownc_" + str(key), int(cars[key]))
	for key in tune:
		cfg.set_value("garage", "tune_" + str(key), int(tune[key]))
	cfg.set_value("garage", "nitro", nitro)
	for key in districts:
		cfg.set_value("districts", key, int(districts[key]))
	for key in district_jobs:
		cfg.set_value("district_jobs", key, int(district_jobs[key]))
	for key in syrenki:
		cfg.set_value("syrenki", key, int(syrenki[key]))
	for key in ladder:
		cfg.set_value("ladder", key, int(ladder[key]))
	for key in intro:
		cfg.set_value("intro", key, int(intro[key]))
	for key in cassettes:
		cfg.set_value("cassettes", key, int(cassettes[key]))
	for key in session:
		cfg.set_value("session", key, session[key])
	for section in _extra:
		for key in _extra[section]:
			cfg.set_value(section, key, _extra[section][key])
	cfg.save(path)


## Wipes the record (--reset-save).
func reset() -> void:
	zl = 0
	respect = 0
	jobs.clear()
	best.clear()
	eggs.clear()
	cautions_today = 0
	cautions_day = 0
	escapes_total = 0
	keep.clear()
	notes.clear()
	chapters_done.clear()
	tracks.clear()
	track_chapters = 0
	tapes.clear()
	kadr.clear()
	kadr_photos.clear()
	paint = "red"
	paints.clear()
	car = "hatch"
	cars.clear()
	tune.clear()
	nitro = false
	districts.clear()
	district_jobs.clear()
	syrenki.clear()
	ladder.clear()
	intro.clear()
	cassettes.clear()
	session.clear()
	save()
	changed.emit(zl, respect, 0)


## Save and resume: the path of the copy `start_over` keeps of the old save (user://save.prev.cfg).
func previous_path() -> String:
	return path.get_basename() + ".prev.cfg"


## Save and resume: anything worth resuming (money, respect, a job, a find, a beaten rival, a
## guide beat, or a spot of the last session). A fresh save offers only "tap to drive".
func has_progress() -> bool:
	return zl != 0 or respect != 0 or not (jobs.is_empty() and eggs.is_empty() and notes.is_empty()
			and districts.is_empty() and syrenki.is_empty() and ladder.is_empty() and intro.is_empty()
			and paints.is_empty() and cars.is_empty() and tune.is_empty() and not nitro and kadr.is_empty() and tapes.is_empty() and session.is_empty())


## Save and resume: "NOWA GRA" confirmed. The old file is copied to previous_path() first (one
## copy, the last one replaced), then the record is wiped as --reset-save does. Not with --nosave
## (nothing is written) or a newer build's file (never overwritten: false, nothing done).
func start_over() -> bool:
	if newer:
		return false
	if persistent and FileAccess.file_exists(path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(previous_path()))
	reset()
	print("wallet: a new game%s" % (" (the old save kept as %s)" % previous_path() if persistent else " (not saved)"))
	return true


## Save and resume: the car's spot for the next launch, saved only when it moved more than
## `min_move` metres from the one kept (a parked car writes nothing). True when it was written.
func remember_spot(pos: Vector3, yaw: float, tunnel: bool, now: int, min_move := 5.0) -> bool:
	if session.has("x") and Vector2(float(session["x"]), float(session["z"])).distance_to(Vector2(pos.x, pos.z)) < min_move \
			and bool(int(session.get("tunnel", 0))) == tunnel:
		return false
	session["x"] = snappedf(pos.x, 0.01)
	session["z"] = snappedf(pos.z, 0.01)
	session["yaw"] = snappedf(yaw, 0.001)
	session["tunnel"] = 1 if tunnel else 0
	session["at"] = now
	save()
	return true


## Save and resume: the kept spot as [Vector3(x, 0, z), yaw, tunnel], or [] (none).
func resume_spot() -> Array:
	if not session.has("x") or not session.has("z"):
		return []
	return [Vector3(float(session["x"]), 0.0, float(session["z"])), float(session.get("yaw", 0.0)), int(session.get("tunnel", 0)) == 1]


## Pays `amount` złoty and `gain` respect, counts a finished job of `kind` (if any)
## and saves.
func pay(amount: int, gain := 0, kind := "") -> void:
	zl += amount
	respect += gain
	if kind != "":
		jobs[kind] = int(jobs.get(kind, 0)) + 1
		if district != "":
			district_jobs[district] = int(district_jobs.get(district, 0)) + 1
	save()
	changed.emit(zl, respect, amount)
	print("wallet: +%d zł, +%d respect (%s) -> %d zł, respect %d" % [amount, gain, kind if kind != "" else "-", zl, respect])


## Loop 3h slice 4: the jobs finished, of every paid kind but NOT_JOBS (a kebab, słoiki, a rescue,
## a Podwózka ride, the round-up, "Na czasie"...). Old saves count from the totals they kept by kind.
func jobs_done() -> int:
	var n := 0
	for k in jobs:
		if not str(k) in NOT_JOBS:
			n += int(jobs[k])
	return n


## The garage loop: pays `amount` złoty out of the wallet (a paint job, a car or a part) and saves; false (nothing
## paid) when there are not that many.
func spend(amount: int) -> bool:
	if amount < 0 or amount > zl:
		return false
	zl -= amount
	save()
	changed.emit(zl, respect, -amount)
	print("wallet: -%d zł (garage) -> %d zł, respect %d" % [amount, zl, respect])
	return true


## Loop 3g-1: respect only (an escape from the police, +15); the złoty are never touched.
func add_respect(gain: int) -> void:
	respect += gain
	save()
	changed.emit(zl, respect, 0)
	print("wallet: +%d respect (police) -> %d zł, respect %d" % [gain, zl, respect])


## Loop 3g-1: a caution in the joke notebook on day `today` (yyyymmdd); returns today's count.
func add_caution(today: int) -> int:
	if cautions_day != today:
		cautions_day = today
		cautions_today = 0
	cautions_today += 1
	save()
	return cautions_today


## Loop 3g-1: the notebook's count for `today` (0 if the last caution was on another day).
func cautions_on(today: int) -> int:
	return cautions_today if cautions_day == today else 0


## Loop 3g-1: an escape counted (never money).
func add_escape() -> void:
	escapes_total += 1
	save()


## Records a time under `key`; true if it beats the best (or is the first).
func record(key: String, seconds: float) -> bool:
	if best.has(key) and float(best[key]) <= seconds:
		return false
	best[key] = snappedf(seconds, 0.1)
	save()
	return true


func best_time(key: String) -> float:
	return float(best.get(key, -1.0))


## Marks an easter egg found (loop MW-6: on day `date`, yyyymmdd); true the first time.
func find_egg(id: String, date := 1) -> bool:
	if eggs.has(id):
		return false
	eggs[id] = maxi(1, date)
	save()
	return true


## Loop MW-6: every egg card found (the save's ids; the five of v0.65 are cards too).
func eggs_found() -> int:
	return eggs.size()


## Loop MW-6: the egg cards in all (EGGS' five until egg_book.gd says).
func egg_count() -> int:
	return eggs_total if eggs_total > 0 else EGGS.size()


func summary() -> String:
	return "%d zł, respect %d, jobs %s, best %s, eggs %d/%d, notebook %d, tapes %d, kadr %d, paint %s (%d bought), districts %d, syrenki %d, ladder %d, intro %d, resume %s, save v%d" % [zl, respect,
			jobs, best, eggs_found(), egg_count(), notes.size(), tapes.size(), kadr.size(), paint, paints.size(), districts.size(),
			syrenki.size(), ladder.size(), intro.size(), "yes" if session.has("x") else "no", loaded_version]


## "1 240 zł": thousands apart with a space, the Polish way.
static func money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if amount < 0 else "") + digits + out + " zł"
