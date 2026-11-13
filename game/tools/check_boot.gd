extends SceneTree
## The boot scene (tech-debt TD-15, boot.gd), with a stand-in for the game's scene (an empty
## scene saved to a scratch file) and scratch files for the settings and the session log:
## - which launch is a player's: no flag at all, or --boot among them;
## - a player's launch: the title is in the tree, under the root, within two frames, in the
##   settings' language, with its bar's first share; the trap is running and has opened the
##   session file; a language picked on the title while the scripts load is saved; when the
##   scene has loaded it takes the boot scene's place as the current scene in one step, the boot
##   scene is gone, and the title is still on screen for main.gd to take (once);
## - a run with flags: no title, the scene at once (it is the current scene one frame on), the
##   trap running in memory only (--nosave), nothing written;
## - a release build (testers' builds): no trap at all, no session file, the scene as before;
## - the scripts the first frame waits for: boot.gd, what it preloads and what those preload
##   are exactly BOOT_SCRIPTS (a preload added to any of them would bring its whole tree in
##   before the title shows); the sound engine is not among them, the title loads it when it goes;
## - a frame spent waiting for a thread under the title (`Boot.wait_frame`): with no display it
##   takes HEADLESS_WAIT_MS, and main.gd's two waits there (the map's big files, the start's
##   sectors) call it, so a headless run counts those waits in frames as a screen would (without
##   it `boot-run` spent its 8000 frames before the map's files were in).
## Not here: a scene that fails to load (the engine's own error lines would fail this step).
## Deletes its scratch files.
##   godot --headless --path game --script res://tools/check_boot.gd

const Boot := preload("res://scripts/boot.gd")
const Lang := preload("res://scripts/lang.gd")
const Settings := preload("res://scripts/settings.gd")
const ErrorTrap := preload("res://scripts/error_trap.gd")
const STUB := "user://check_boot_stub.tscn"
const SETTINGS := "user://check_boot_settings.cfg"
const SESSION := "user://check_boot_session.log"
const SESSION_PREV := "user://check_boot_session.prev.log"
const SFX := "res://scripts/sfx.gd"
## Every script loaded before the first frame (22 ms together in a release build, 2026-11-12).
## Adding one here is a decision: it and everything it preloads delay the title.
const BOOT_SCRIPTS: Array[String] = ["boot.gd", "error_trap.gd", "follow_camera.gd", "lang.gd", "release.gd",
		"safe_file.gd", "settings.gd", "tiers.gd", "title.gd"]

var _problems := 0


func _initialize() -> void:
	var lang_before := Lang.code
	await process_frame  # the tree runs: a node added from here on is ready at once
	_clean()
	_make_stub()
	_which_launch()
	_first_frame_scripts()
	_waits()
	await _player_launch()
	await _run_with_flags()
	await _release_build()
	Lang.set_code(lang_before)
	_clean()
	if _problems == 0:
		print("check_boot: OK")
		quit(0)
	else:
		print("check_boot: %d problem(s)" % _problems)
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _clean() -> void:
	for f in [STUB, SETTINGS, SESSION, SESSION_PREV]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))


## The game's stand-in: a scene of one node.
func _make_stub() -> void:
	var node := Node.new()
	node.name = "Stub"
	var packed := PackedScene.new()
	packed.pack(node)
	ResourceSaver.save(packed, STUB)
	node.free()


func _which_launch() -> void:
	_expect(Boot.player_launch(PackedStringArray()), "no flag at all is a player's launch")
	_expect(Boot.player_launch(PackedStringArray(["--nosave", "--boot"])), "--boot among the flags is a player's launch")
	_expect(not Boot.player_launch(PackedStringArray(["--nosave"])), "any other flag is a run with flags")
	_expect(not Boot.player_launch(PackedStringArray(["--headless", "--path", "."])), "the engine's own flags are a run with flags")


## boot.gd's preloads, and theirs, read from the sources.
func _first_frame_scripts() -> void:
	var found: Array[String] = []
	var todo: Array[String] = ["boot.gd"]
	var find := RegEx.create_from_string("preload\\(\"res://scripts/([^\"]+\\.gd)\"\\)")
	while not todo.is_empty():
		var f: String = todo.pop_back()
		if f in found:
			continue
		found.append(f)
		for m in find.search_all(FileAccess.get_file_as_string("res://scripts/" + f)):
			todo.append(m.get_string(1))
	found.sort()
	for f in found:
		_expect(f in BOOT_SCRIPTS, "%s is now loaded before the first frame (boot.gd's preloads reach it): load it later, or add it to BOOT_SCRIPTS on purpose" % f)
	for f in BOOT_SCRIPTS:
		_expect(f in found, "%s is in BOOT_SCRIPTS but boot.gd no longer reaches it: take it off the list" % f)


## The paced wait: this check has no display, so each call takes HEADLESS_WAIT_MS; and the two
## waits under the title in main.gd use it (read from the source: they need the whole game to run).
func _waits() -> void:
	var t0 := Time.get_ticks_usec()
	for i in 5:
		Boot.wait_frame()
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	if DisplayServer.get_name() == "headless":
		_expect(ms >= 5.0 * Boot.HEADLESS_WAIT_MS, "5 waited frames with no display took %.1f ms, under 5 x %d ms: a headless run under the title would spend thousands of frames on one load" % [ms, Boot.HEADLESS_WAIT_MS])
	else:
		_expect(ms < Boot.HEADLESS_WAIT_MS, "5 waited frames on a display took %.1f ms: the display paces them, the game must not wait as well" % ms)
	var main := FileAccess.get_file_as_string("res://scripts/main.gd")
	for fn in ["_wait_preloads", "_title_frame"]:
		var from := main.find("\nfunc %s(" % fn)
		var body := main.substr(from, main.find("\nfunc ", from + 1) - from) if from >= 0 else ""
		_expect(body.contains("Boot.wait_frame()"), "main.gd's %s no longer calls Boot.wait_frame(): with no display its wait for the threads is not paced" % fn)


func _boot(args: Array, debug := true) -> Boot:
	var boot := Boot.new()
	boot.name = "Boot"
	boot.game = STUB
	boot.args = PackedStringArray(args)
	boot.debug = debug
	boot.settings_path = SETTINGS
	boot.session_path = SESSION
	root.add_child(boot)
	current_scene = boot
	return boot


func _player_launch() -> void:
	# The settings say Polish; the default is English.
	var kept := Settings.new()
	kept.path = SETTINGS
	kept.lang = Lang.PL
	kept.save()
	Lang.set_code(Lang.EN)
	var boot := _boot(["--boot"])
	boot.set_process(false)  # the load goes on; the scene change waits for this check
	await process_frame
	await process_frame
	var title := Boot.title
	_expect(title != null and title.is_inside_tree() and title.get_parent() == root, "the title is in the tree, under the root, within two frames")
	_expect(Lang.code == Lang.PL, "in the settings' language (got %s)" % Lang.code)
	_expect(Boot.trap != null and Boot.trap.path == SESSION and FileAccess.file_exists(SESSION), "the trap is running and has opened the session file")
	_expect(Boot.title_ms >= 0, "the title's time is kept for the log")
	if title == null:
		return
	_expect(is_equal_approx(title.cap, Boot.BAR_SHARE) and title.process_mode == Node.PROCESS_MODE_ALWAYS, "the title's bar has its first share and the title runs while the tree is paused")
	# A language picked while the scripts load.
	title.choose_language(Lang.EN)
	var read := Settings.new()
	read.path = SETTINGS
	read.load_file()
	_expect(read.lang == Lang.EN and Lang.code == Lang.EN, "a language picked on the title while the scripts load is saved (got %s)" % read.lang)
	# The scene has loaded: it takes the boot scene's place.
	boot.set_process(true)
	for i in 600:
		if current_scene != boot:
			break
		await process_frame
	_expect(current_scene != null and current_scene.name == "Stub" and current_scene.get_parent() == root, "the game's scene is the current scene (got %s)" % current_scene)
	await process_frame
	_expect(not is_instance_valid(boot), "the boot scene is gone")
	_expect(Boot.load_ms >= 0, "the load's time is kept for the log")
	_expect(is_instance_valid(title) and title.is_inside_tree(), "the title is still on screen")
	_expect(title.language_chosen.get_connections().is_empty(), "and no longer tells the boot scene about a language")
	# The title's own sound (the start sound when it goes) comes from the sound engine, which is
	# not one of the boot scene's scripts: title.gd loads it when the title goes. A wrong name
	# or a missing function there is an error line, which fails this step.
	_expect(not ResourceLoader.has_cached(SFX), "the sound engine is not loaded while the title is up and the game loads")
	title.dismiss()
	_expect(ResourceLoader.has_cached(SFX), "the title going loads the sound engine for its start sound")
	_expect(Boot.take_title() == title and Boot.take_title() == null, "main.gd takes the title once")
	var trap := Boot.take_trap()
	_expect(trap != null and Boot.take_trap() == null, "and the trap once")
	if trap != null:
		trap.stop()
		OS.remove_logger(trap)
	title.free()
	current_scene.free()


func _run_with_flags() -> void:
	_clean_session()
	Lang.set_code(Lang.PL)
	var boot := _boot(["--nosave", "--at=0,0"])
	await process_frame
	await process_frame
	_expect(Boot.title == null, "a run with flags has no boot title")
	_expect(current_scene != null and current_scene.name == "Stub", "and the game's scene at once (got %s)" % current_scene)
	_expect(not is_instance_valid(boot), "the boot scene is gone")
	_expect(Lang.code == Lang.PL, "the language is left to main.gd")
	var trap := Boot.take_trap()
	_expect(trap != null and trap.path == "" and not FileAccess.file_exists(SESSION), "the trap runs in memory only under --nosave")
	if trap != null:
		OS.remove_logger(trap)
	if current_scene != null:
		current_scene.free()


## A release build (F, 2026-11-12: testers' builds run none of the trap): the boot scene makes
## no trap and no session file, with flags and in a player's launch, and the scene still comes.
func _release_build() -> void:
	_clean_session()
	var boot := _boot(["--at=0,0"], false)
	await process_frame
	await process_frame
	_expect(Boot.trap == null and Boot.take_trap() == null, "a release build's boot scene starts no trap (with flags)")
	_expect(not FileAccess.file_exists(SESSION), "and writes no session file")
	_expect(current_scene != null and current_scene.name == "Stub" and not is_instance_valid(boot), "and the game's scene comes as before (got %s)" % current_scene)
	if current_scene != null:
		current_scene.free()
	boot = _boot([], false)
	for i in 600:
		if current_scene != boot:
			break
		await process_frame
	_expect(Boot.trap == null and not FileAccess.file_exists(SESSION), "nor in a player's launch")
	_expect(current_scene != null and current_scene.name == "Stub", "where the game's scene comes too (got %s)" % current_scene)
	var title := Boot.take_title()
	_expect(title != null, "behind the title")
	if title != null:
		title.free()
	if current_scene != null:
		current_scene.free()


func _clean_session() -> void:
	for f in [SESSION, SESSION_PREV]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
