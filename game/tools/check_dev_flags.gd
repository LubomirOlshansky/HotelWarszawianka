extends SceneTree
## The command-line flags' one owner (TD-4 a): scripts/dev_flags.gd parses every flag of a debug
## run, and main.gd reads each value as `flags.NAME`. Checks that:
## - no script but dev_flags.gd assigns a field of the flags (`flags.NAME = ...`, `+=`, `[...] =`,
##   `.append(...)`), so a value is set in one place, when the command line is read;
## - every value of main's own that dev_flags.gd writes (`m.NAME`) is declared in main.gd under a
##   `##` doc comment that names dev_flags.gd, so whoever changes it later sees the flag;
## - main.gd reads no flag itself (no `arg == "--` or `arg.begins_with("--`): a new flag goes in
##   dev_flags.gd;
## - an empty flag list (a release build: `Release.game_args()` is empty) leaves every value at its
##   default except the run's own decisions, and costs next to nothing (the time is printed).
##   godot --headless --path game --script res://tools/check_dev_flags.gd

const DevFlags := preload("res://scripts/dev_flags.gd")
const DEV := "res://scripts/dev_flags.gd"
const MAIN := "res://scripts/main.gd"
## The values the parser's tail decides for every run (the governor, the timers of a normal
## launch, the cinematic moments): not flags, so an empty list may set them.
const RUN_DECISIONS := ["_governor_on", "_crash_auto", "_rave_auto", "_shisha_auto", "_meet_auto",
		"_ev_auto", "_crawl_auto", "_image_write", "cinematic_flyin", "cinematic_look", "start_station"]

var _fails: PackedStringArray = []


func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	var dev := _code(FileAccess.get_file_as_string(DEV))
	var main_src := FileAccess.get_file_as_string(MAIN)
	var fields := _fields(dev)
	var owned := _owned(dev)
	_no_outside_writes(fields)
	_owned_documented(owned, main_src)
	_main_reads_no_flag(main_src)
	var usec := _empty_list(fields)
	if _fails.is_empty():
		print("check_dev_flags: OK (%d flag values in dev_flags.gd, written there only; %d of main's own, each documented; an empty list parses in %d µs)" % [fields.size(), owned.size(), usec])
		quit(0)
	else:
		for f in _fails:
			print("check_dev_flags: FAIL " + f)
		quit(1)


## A script's text with its comments and strings blanked, so names in them do not count.
func _code(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		var s := RegEx.create_from_string("\"(?:[^\"\\\\]|\\\\.)*\"").sub(line, "\"\"", true)
		var h := s.find("#")
		out.append(s.substr(0, h) if h >= 0 else s)
	return "\n".join(out)


## dev_flags.gd's own fields (its top-level vars, but `m`).
func _fields(dev: String) -> Dictionary:
	var out := {}
	for m in RegEx.create_from_string("(?m)^var (\\w+)").search_all(dev):
		if m.get_string(1) != "m":
			out[m.get_string(1)] = true
	return out


## The values of main's own that dev_flags.gd writes.
func _owned(dev: String) -> Dictionary:
	var out := {}
	var w := RegEx.create_from_string("(?<![\\w.])m\\.(\\w+)\\s*(\\[[^\\]]*\\]\\s*)*(\\+|-|\\*|/)?=(?!=)|(?<![\\w.])m\\.(\\w+)\\.(append|clear|erase|merge|push_back|assign)\\(")
	for m in w.search_all(dev):
		var name := m.get_string(1) if m.get_string(1) != "" else m.get_string(4)
		out[name] = true
	return out


func _no_outside_writes(fields: Dictionary) -> void:
	var w := RegEx.create_from_string("\\bflags\\.(\\w+)\\s*(\\[[^\\]]*\\]\\s*)*(\\+|-|\\*|/)?=(?!=)|\\bflags\\.(\\w+)\\.(append|append_array|clear|erase|merge|push_back|assign|resize|fill|sort|remove_at|insert|pop_back|pop_front)\\(")
	for dir in ["res://scripts", "res://tools"]:
		for f in DirAccess.get_files_at(dir):
			var path := "%s/%s" % [dir, f]
			if not f.ends_with(".gd") or path == DEV:
				continue
			var code := _code(FileAccess.get_file_as_string(path))
			for m in w.search_all(code):
				var name := m.get_string(1) if m.get_string(1) != "" else m.get_string(4)
				if fields.has(name):
					var line := code.substr(0, m.get_start()).count("\n") + 1
					_fails.append("%s:%d writes flags.%s: a flag's value is set in dev_flags.gd only, when the command line is read" % [path, line, name])


func _owned_documented(owned: Dictionary, main_src: String) -> void:
	var lines := main_src.split("\n")
	for name: String in owned:
		var at := -1
		for i in lines.size():
			if RegEx.create_from_string("^(@\\w+\\s+)*(static\\s+)?var %s\\b" % name).search(lines[i]) != null:
				at = i
				break
		if at < 0:
			_fails.append("dev_flags.gd writes m.%s, which main.gd does not declare" % name)
			continue
		var doc := ""
		var k := at - 1
		while k >= 0 and lines[k].begins_with("##"):
			doc = lines[k] + "\n" + doc
			k -= 1
		if not doc.contains("dev_flags.gd"):
			_fails.append("main.gd's %s (line %d) is written by dev_flags.gd but its doc comment does not say so" % [name, at + 1])


func _main_reads_no_flag(main_src: String) -> void:
	var code := _code(main_src)
	var r := RegEx.create_from_string("\\barg\\s*==\\s*\"\"|\\barg\\.begins_with\\(\"\"\\)")
	# _code blanked the strings; look at the raw text for the flag's dashes on the same lines.
	var raw := main_src.split("\n")
	var cl := code.split("\n")
	var n := 0
	for i in cl.size():
		if r.search(cl[i]) != null and (raw[i].contains("== \"--") or raw[i].contains("begins_with(\"--")):
			n += 1
			if n <= 3:
				_fails.append("main.gd:%d reads a flag itself: parse it in dev_flags.gd" % (i + 1))


## The release build's case: an empty list keeps every flag at its default.
func _empty_list(fields: Dictionary) -> int:
	var game: Node = load(MAIN).new()
	var fresh := DevFlags.new()
	var f: DevFlags = game.get("flags")
	f.m = game
	var t0 := Time.get_ticks_usec()
	f.parse_with(PackedStringArray())
	var usec := Time.get_ticks_usec() - t0
	for name: String in fields:
		if name in RUN_DECISIONS:
			continue
		if typeof(f.get(name)) != typeof(fresh.get(name)) or f.get(name) != fresh.get(name):
			_fails.append("an empty flag list changed %s (%s, default %s)" % [name, str(f.get(name)), str(fresh.get(name))])
	game.free()
	return usec
