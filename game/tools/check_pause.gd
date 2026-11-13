extends SceneTree
## The game's pause has one owner (tech-debt TD-20, pause_reasons.gd).
##
## Without game flags (verify step `pause`; no map needed, CI's quick job):
##   A1 the reasons on a real tree: the tree is paused while any reason is held; of two held, the
##      one let go first does not start the game, in either order; a reason held twice is one hold;
##      letting go of one that is not held changes nothing; `release_all` ends every hold; `still`
##      names what is left for the log;
##   A2 the scripts: nothing under res://scripts writes the tree's pause but pause_reasons.gd (one
##      line of it); main.gd holds and lets go of each of the four reasons; the loading bar's hold
##      is before the city's build and its release after it; a new game lets go of everything
##      before the scene reloads.
##
## With game flags (verify step `pause-run`; the real game on the prebuilt city, the car in the
## garage's ring), the case found on 2026-11-13 and the cards one by one, through the real input:
##   B1 the garage card opens: paused, for the garage;
##   B2 a tap on the minimap opens the full map over the card: paused, for both;
##   B3 the map's ✕: the map is gone and the game is STILL paused under the garage card (before
##      TD-20 the city ran on here), and half a second later too;
##   B4 the same with Esc closing the map;
##   B5 Esc closes the garage card: the game runs;
##   B6 the map alone: paused while it is up, running after Esc;
##   B7 the settings card alone (Esc opens it, Esc closes it): paused while it is up, running after.
##
##   godot --headless --path game --script res://tools/check_pause.gd
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_pause.gd -- --nosave --notitle --prebuilt --garage

const PauseReasons := preload("res://scripts/pause_reasons.gd")
const OWNER := "res://scripts/pause_reasons.gd"
const MAIN := "res://scripts/main.gd"
## Frames the game gets to build the prebuilt city and open the garage card.
const START_FRAMES := 6000

var _facts := 0
var _problems := 0
var _game: Node


func _initialize() -> void:
	if "--garage" in OS.get_cmdline_user_args():
		_play.call_deferred()
		return
	_reasons()
	_scripts()
	_finish("the reasons on a real tree, the scripts' pause writers")


func _ok(fact: bool, what: String) -> void:
	_facts += 1
	if not fact:
		_problems += 1
		print("problem: %s" % what)


func _finish(what: String) -> void:
	if _problems == 0:
		print("check_pause: OK (%d facts: %s)" % [_facts, what])
		quit(0)
	else:
		print("check_pause: FAILED (%d of %d facts)" % [_problems, _facts])
		quit(1)


# --- A1: the reasons -------------------------------------------------------------------------

func _reasons() -> void:
	var names: Array[StringName] = [PauseReasons.LOAD, PauseReasons.SETTINGS, PauseReasons.MAP, PauseReasons.GARAGE]
	var seen := {}
	for n in names:
		seen[n] = true
	_ok(seen.size() == 4, "the four reasons are not four different names: %s" % [names])
	var p := PauseReasons.new(self)
	_ok(not paused and p.still() == "" and not p.held(PauseReasons.LOAD), "a new owner: something is held, or the tree is paused")
	# Two reasons, the first let go first (the garage card, then the map over it, the card closed first).
	p.hold(PauseReasons.GARAGE)
	_ok(paused and p.held(PauseReasons.GARAGE) and not p.held(PauseReasons.MAP), "one reason held: the tree is not paused, or the wrong reason is held")
	p.hold(PauseReasons.MAP)
	_ok(paused and p.held(PauseReasons.MAP), "two reasons held: the tree is not paused")
	p.release(PauseReasons.GARAGE)
	_ok(paused and not p.held(PauseReasons.GARAGE) and p.held(PauseReasons.MAP), "the first of two let go: the game started under the second")
	_ok(p.still() == ", the game stays paused (map)", "the log's note with the map left: '%s'" % p.still())
	p.release(PauseReasons.MAP)
	_ok(not paused and p.still() == "", "both let go: the tree is still paused")
	# The other order (the map over the garage card, the map closed first: the case found).
	p.hold(PauseReasons.GARAGE)
	p.hold(PauseReasons.MAP)
	_ok(p.still() == ", the game stays paused (garage, map)", "the log's note with two held: '%s'" % p.still())
	p.release(PauseReasons.MAP)
	_ok(paused and p.held(PauseReasons.GARAGE) and not p.held(PauseReasons.MAP), "the second of two let go: the game started under the first")
	p.release(PauseReasons.GARAGE)
	_ok(not paused, "both let go, the other order: the tree is still paused")
	# Held twice is one hold.
	p.hold(PauseReasons.SETTINGS)
	p.hold(PauseReasons.SETTINGS)
	p.release(PauseReasons.SETTINGS)
	_ok(not paused and not p.held(PauseReasons.SETTINGS), "a reason held twice needed two releases")
	# Letting go of what is not held.
	p.release(PauseReasons.MAP)
	_ok(not paused and p.still() == "", "letting go of a reason not held paused the tree")
	p.hold(PauseReasons.LOAD)
	p.release(PauseReasons.MAP)
	_ok(paused and p.held(PauseReasons.LOAD), "letting go of a reason not held started the game under another")
	# A new game.
	p.hold(PauseReasons.SETTINGS)
	p.release_all()
	_ok(not paused and p.still() == "" and not p.held(PauseReasons.LOAD) and not p.held(PauseReasons.SETTINGS), "release_all left something held, or the tree paused")
	p.hold(PauseReasons.MAP)
	_ok(paused, "a hold after release_all does not pause")
	p.release(PauseReasons.MAP)
	_ok(not paused, "the tree is left paused by this check")


# --- A2: the scripts -------------------------------------------------------------------------

func _scripts() -> void:
	# A write of the tree's pause: `get_tree().paused = ...`, `tree.paused = ...`, `set_pause(...)`.
	# (The rescue calls' `missions.paused` is another thing, tech-debt TD-3.)
	var write := RegEx.create_from_string("(?i)tree\\w*(\\(\\))?\\.paused\\s*=(?!=)|\\.set_pause\\s*\\(")
	var files: Array[String] = []
	_gather("res://scripts", files)
	_ok(files.size() > 100 and OWNER in files and MAIN in files, "the scripts were not found (%d files)" % files.size())
	var owner_writes := 0
	for path in files:
		var n := 0
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var code := line.split("#")[0]
			if write.search(code) != null:
				n += 1
				if path != OWNER:
					print("   %s: %s" % [path, line.strip_edges()])
		if path == OWNER:
			owner_writes = n
		else:
			_ok(n == 0, "%s writes the tree's pause itself (%d lines): hold a reason of main.gd's `_pause` instead" % [path, n])
	_ok(owner_writes == 1, "pause_reasons.gd writes the tree's pause in %d lines, not in its one `_apply`" % owner_writes)
	var main := FileAccess.get_file_as_string(MAIN)
	for reason: String in ["LOAD", "SETTINGS", "MAP", "GARAGE"]:
		var holds := main.count("_pause.hold(PauseReasons.%s)" % reason)
		var lets := main.count("_pause.release(PauseReasons.%s)" % reason)
		_ok(holds == 1 and lets == 1, "main.gd holds %s %d times and lets it go %d times (one each)" % [reason, holds, lets])
	_ok(main.count("_pause = PauseReasons.new(get_tree())") == 1, "main.gd does not make its one `_pause` on its tree")
	# The loading bar: held before the city is built, let go after.
	var ready := _body(main, "func _ready() -> void:")
	var hold_at := ready.find("_pause.hold(PauseReasons.LOAD)")
	var build_at := ready.find("await _build_world()")
	var free_at := ready.find("_pause.release(PauseReasons.LOAD)")
	_ok(hold_at >= 0 and build_at > hold_at and free_at > build_at, "_ready: the loading bar's hold, the build and the release are not in that order (%d, %d, %d)" % [hold_at, build_at, free_at])
	# A new game: everything let go, then the scene reloads.
	var again := _body(main, "func _on_new_game() -> void:")
	var all_at := again.find("_pause.release_all()")
	var reload_at := again.find("reload_current_scene")
	_ok(all_at >= 0 and reload_at > all_at and main.count("_pause.release_all()") == 1, "_on_new_game does not let go of every reason before the scene reloads")
	# The cards' own functions.
	_ok(_body(main, "func _open_settings() -> void:").contains("_pause.hold(PauseReasons.SETTINGS)") \
			and _body(main, "func _close_settings() -> void:").contains("_pause.release(PauseReasons.SETTINGS)"), "the settings card's hold and release are not in _open_settings and _close_settings")
	_ok(_body(main, "func _open_full_map() -> void:").contains("_pause.hold(PauseReasons.MAP)") \
			and _body(main, "func _close_full_map() -> void:").contains("_pause.release(PauseReasons.MAP)"), "the full map's hold and release are not in _open_full_map and _close_full_map")


## The text of the function that starts with `head`, up to the next top-level `func`.
func _body(src: String, head: String) -> String:
	var at := src.find("\n" + head)
	if at < 0:
		return ""
	var end := src.find("\nfunc ", at + 1)
	return src.substr(at, (end if end > 0 else src.length()) - at)


func _gather(dir: String, out: Array[String]) -> void:
	for d in DirAccess.get_directories_at(dir):
		_gather(dir.path_join(d), out)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))


# --- B: the real game ------------------------------------------------------------------------

func _play() -> void:
	var scene: PackedScene = load("res://main.tscn")
	_game = scene.instantiate()
	root.add_child(_game)
	current_scene = _game
	# B1
	var n := 0
	while n < START_FRAMES and not _garage_open():
		await process_frame
		n += 1
	_ok(_garage_open(), "B1 the garage card did not open in %d frames (--garage)" % START_FRAMES)
	if not _garage_open():
		_finish("")
		return
	await _frames(20)
	var p: PauseReasons = _game._pause
	var hud: CanvasLayer = _game.hud
	_ok(paused and p.held(PauseReasons.GARAGE) and not p.held(PauseReasons.MAP), "B1 the garage card is open and the game is not paused for it")
	# B2, B3: the map over the card, closed by its ✕.
	await _tap_minimap()
	_ok(hud.full_map_open() and _garage_open(), "B2 a tap on the minimap under the garage card did not open the full map over it")
	_ok(paused and p.held(PauseReasons.GARAGE) and p.held(PauseReasons.MAP), "B2 the map over the garage card: not paused for both")
	if hud.full_map_open():
		var cross: Rect2 = hud.full_map.rects()["close"]
		await _click(cross.get_center())
	_ok(not hud.full_map_open() and _garage_open(), "B3 the ✕ did not close the map, or the garage card went with it")
	_ok(paused and p.held(PauseReasons.GARAGE) and not p.held(PauseReasons.MAP), "B3 the map closed and the game runs on under the open garage card")
	_ok(p.still() == ", the game stays paused (garage)", "B3 the log's note after the map closed: '%s'" % p.still())
	await _frames(30)
	_ok(paused and _garage_open(), "B3 half a second later the game runs under the open garage card")
	# B4: the same, the map closed with Esc.
	await _tap_minimap()
	_ok(hud.full_map_open() and paused, "B4 the second tap on the minimap did not open the map")
	await _key(KEY_ESCAPE)
	_ok(not hud.full_map_open() and _garage_open(), "B4 Esc did not close the map alone (the map takes it first)")
	_ok(paused and p.held(PauseReasons.GARAGE) and not p.held(PauseReasons.MAP), "B4 the map closed with Esc and the game runs on under the open garage card")
	# B5: the garage card goes.
	await _key(KEY_ESCAPE)
	_ok(not _garage_open(), "B5 Esc did not close the garage card")
	_ok(not paused and p.still() == "", "B5 the garage card closed and the game does not run%s" % p.still())
	await _frames(30)
	_ok(not paused and not _garage_open(), "B5 half a second after the card closed: paused again, or the card came back")
	# B6: the map alone.
	await _tap_minimap()
	_ok(hud.full_map_open() and paused and p.held(PauseReasons.MAP) and not p.held(PauseReasons.GARAGE), "B6 the map alone: not open, or not paused for it")
	await _key(KEY_ESCAPE)
	_ok(not hud.full_map_open() and not paused and p.still() == "", "B6 the map closed and the game does not run%s" % p.still())
	# B7: the settings card alone.
	await _key(KEY_ESCAPE)
	_ok(hud.settings_open() and paused and p.held(PauseReasons.SETTINGS), "B7 Esc did not open the settings card, or the game is not paused for it")
	await _key(KEY_ESCAPE)
	_ok(not hud.settings_open() and not paused and p.still() == "", "B7 the settings card closed and the game does not run%s" % p.still())
	_finish("the garage card with the map over it, closed by the ✕ and by Esc; the map and the settings card alone")


func _garage_open() -> bool:
	return _game != null and bool(_game.get("_started")) and _game.garage != null and _game.garage.is_open()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## A finger down and up on the minimap's middle (hud.gd `_track_tap`), then a few frames.
func _tap_minimap() -> void:
	var mini: Control = _game.hud._minimap
	await _click(mini.get_global_rect().get_center())


## A click as a real one comes (the project turns it into a touch too): down, two frames, up.
func _click(at: Vector2) -> void:
	for down: bool in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = at
		e.global_position = at
		e.pressed = down
		e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		Input.parse_input_event(e)
		await _frames(2)
	await _frames(4)


func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = down
		Input.parse_input_event(e)
		await _frames(2)
	await _frames(4)
