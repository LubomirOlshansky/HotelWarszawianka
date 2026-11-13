extends Node
## The boot scene (tech-debt TD-15): the first thing the engine loads, and all it needs is this
## script and the title's. The game's own scene, main.tscn, pulls in every other script, and
## loading them takes seconds (about 3.5 s in a release build on a cloud core, 2026-11-12): until
## this scene existed the player looked at the engine's plain blue screen for that long.
##
## A player's launch (no flags, which is every release build): the title is on screen in the
## first frames, the game's scene loads on a thread behind it, and main.gd takes the same title
## over (`take_title`), so nothing blinks. A run with flags (the checks, the shots, the bench):
## the game's scene at once, as before this scene existed, so no frame goes by first and a run's
## --quit-after and --shots frames mean what they did. `--boot` makes a run with flags start as
## a player's launch does.
##
## The error trap (error_trap.gd) starts here too, so a script of the game that fails to load is
## in a debug run's report. A release build has no trap (`ErrorTrap.make`), here or later.

const Release := preload("res://scripts/release.gd")
const Lang := preload("res://scripts/lang.gd")
const Settings := preload("res://scripts/settings.gd")
const Title := preload("res://scripts/title.gd")
const ErrorTrap := preload("res://scripts/error_trap.gd")

const GAME := "res://main.tscn"
## With no display (a headless run with --boot) nothing paces the frames, and thousands would go
## by while a thread loads: the run's --quit-after would end it before the game began. So a frame
## spent waiting for a thread waits this long there (about 120 frames a second): `wait_frame`.
const HEADLESS_WAIT_MS := 8
## The share of the title's loading bar the scripts' load may fill (main.gd's shares come after).
const BAR_SHARE := 0.04

## What main.gd takes over: the title that is on screen, the trap that is running.
static var title: Title
static var trap: ErrorTrap
## When the title went up and how long the game's scene took, for the log (ms).
static var title_ms := -1
static var load_ms := -1

## The scene to load: the game's, or a check's stand-in.
var game := GAME
## The game's flags: the engine's, or a check's.
var args := PackedStringArray()
## The kept files this scene touches (a check gives its scratch files).
var settings_path := Settings.PATH
var session_path := ErrorTrap.PATH
## A debug build, which gets the error trap (a check asks for either).
var debug := OS.is_debug_build()
var _settings: Settings
var _t0 := 0
var _frames := 0
var _failed := false


## True when the launch is a player's: no flag at all, or --boot among them.
static func player_launch(flags: PackedStringArray) -> bool:
	return flags.is_empty() or "--boot" in flags


func _init() -> void:
	args = Release.game_args()


func _ready() -> void:
	if trap == null:
		trap = ErrorTrap.make(debug) as ErrorTrap  # none in a release build
		if trap != null:
			trap.start("" if "--nosave" in args else session_path)
			OS.add_logger(trap)
	if not player_launch(args):
		set_process(false)
		_enter_game.call_deferred(null)
		return
	_t0 = Time.get_ticks_msec()
	_settings = Settings.new()
	_settings.path = settings_path
	_settings.persistent = not "--nosave" in args
	_settings.load_file()
	Lang.set_code(Lang.resolve(_settings.lang))
	title = Title.new()
	title.process_mode = Node.PROCESS_MODE_ALWAYS  # main.gd pauses the tree while the city builds
	title.cap = BAR_SHARE
	title.language_chosen.connect(_on_language_chosen)
	# Under the root, not under this scene: the title stays when this scene goes.
	get_tree().root.add_child.call_deferred(title)
	title_ms = _t0
	ResourceLoader.load_threaded_request(game)


func _process(_dt: float) -> void:
	_frames += 1
	if _failed:
		return
	if ResourceLoader.load_threaded_get_status(game) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		wait_frame()
		return
	var scene := ResourceLoader.load_threaded_get(game) as PackedScene
	if scene == null:
		# The game's scene did not load (a script that does not compile, a missing file): the
		# title says so and stays, and the trap's session file has the engine's errors.
		_failed = true
		push_error("boot: %s did not load" % game)
		title.problem = Lang.pick("Nie udało się wczytać gry. Zainstaluj ją ponownie.", "The game could not be loaded. Please install it again.")
		title.refresh()
		return
	load_ms = Time.get_ticks_msec() - _t0
	print("boot: the title up %d ms after the engine started, the game's scene loaded in %d ms on a thread (%d frames drawn meanwhile)" % [title_ms, load_ms, _frames])
	_enter_game(scene)


## A frame spent waiting for a thread under the title: the scripts' load here, and in main.gd the
## map's big files and the start's sectors. On a screen the display paces it; with no display it
## waits HEADLESS_WAIT_MS, so a headless run counts the wait in frames as a screen would.
static func wait_frame() -> void:
	if DisplayServer.get_name() == "headless":
		OS.delay_msec(HEADLESS_WAIT_MS)


## A language picked while the scripts load: kept as main.gd keeps it later.
func _on_language_chosen(code: String) -> void:
	_settings.lang = code
	_settings.save()


## The game's scene takes this one's place in one step, so the tree always has a current scene.
func _enter_game(scene: PackedScene) -> void:
	if scene == null:
		scene = load(game) as PackedScene
	if scene == null:
		push_error("boot: %s did not load" % game)
		get_tree().quit(1)
		return
	if title != null and title.language_chosen.is_connected(_on_language_chosen):
		title.language_chosen.disconnect(_on_language_chosen)
	var tree := get_tree()
	var main := scene.instantiate()
	tree.root.add_child(main)
	tree.current_scene = main
	queue_free()


## main.gd's side: the title that is already on screen, or null (a run with flags, a check).
static func take_title() -> Title:
	var t := title
	title = null
	return t


## main.gd's side when a flag turned the title off: the one on screen goes.
static func drop_title() -> void:
	if title != null:
		title.queue_free()
		title = null


## main.gd's side: the trap this scene started, or null.
static func take_trap() -> ErrorTrap:
	var t := trap
	trap = null
	return t
