extends SceneTree
## The command-line flags' one owner (TD-4 a): scripts/dev_flags.gd parses every flag of a debug
## run, and main.gd reads each value as `flags.NAME`. Checks that:
## - no script but dev_flags.gd (in scripts/ and tools/, their sub-folders too) assigns a field of the
##   flags (`flags.NAME = ...`, `+=`, `[...] =`, `.append(...)`), so a value is set in one place, when
##   the command line is read;
## - every value of main's own that dev_flags.gd writes (`m.NAME`) is declared in main.gd under a
##   `##` doc comment that names dev_flags.gd, so whoever changes it later sees the flag;
## - main.gd reads no flag itself (no `arg == "--` or `arg.begins_with("--`): a new flag goes in
##   dev_flags.gd;
## - no script in scripts/ but release.gd reads the command line (`OS.get_cmdline_args()`,
##   `OS.get_cmdline_user_args()`): both parsers, and so the harness's load, read
##   `Release.game_args()`, which is empty in a release build;
## - an empty flag list (a release build) leaves every value at its default except the run's own
##   decisions, and costs next to nothing (the time is printed);
## - the test harness (TD-4 a2, scripts/dev_harness.gd) loads in one place only: in main.gd,
##   right under `if flags.wants_harness():`, after both parsers (`flags.parse()` and
##   `flags.parse_stream()`) in the same function. `wants_harness()` is false for an empty list,
##   for --nosave alone and for the flags of a whole-game run, and true for each test flag that
##   runs the harness's code. No script preloads it or names its path and it has no class_name
##   (either would load it in every build);
## - main.gd uses `harness` only in its declaration, that load, `harness.m = self` after it and
##   `harness != null` tests, and every line with `harness.` is one statement that begins
##   `if harness != null: ` (no `;`). In a release build, and in any run without a test flag, the
##   harness is null and a call on it would end the app (TD-21); this way none is made. main.gd
##   never reaches it as a member (`self.harness`) or by name (`get("harness")`), no other script
##   reaches it at all, and dev_harness.gd compiles;
## - every harness call sits under a test of a value `wants_harness()` reads (so a test flag that
##   needs the harness also loads it), or tests its flag itself (TESTS_ITSELF), or reads a value
##   only the harness sets (HARNESS_SETS); a negated test (`not flags.X`, `X.is_empty()`) does not
##   count. No script but dev_flags.gd and dev_harness.gd writes a value `wants_harness()` reads
##   (sub-folders too), so nothing turns a harness path on after the load;
## - main.gd and dev_flags.gd have no triple-quoted string (the rules read them line by line).
##   godot --headless --path game --script res://tools/check_dev_flags.gd

const DevFlags := preload("res://scripts/dev_flags.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const DEV := "res://scripts/dev_flags.gd"
const MAIN := "res://scripts/main.gd"
const HARNESS := "res://scripts/dev_harness.gd"
## This check, which names the harness in its own messages.
const SELF := "res://tools/check_dev_flags.gd"
## The values the parser's tail decides for every run (the governor, the timers of a normal
## launch, the cinematic moments): not flags, so an empty list may set them.
const RUN_DECISIONS := ["_governor_on", "_crash_auto", "_rave_auto", "_shisha_auto", "_meet_auto",
		"_ev_auto", "_crawl_auto", "_image_write", "cinematic_flyin", "cinematic_look", "start_station"]
## The lists that must play with no harness: a tester's launch and the whole-game runs of the
## proofs and of Autopilot (their flags without a test flag).
const NO_HARNESS_LISTS := [
	["--nosave"],
	["--nosave", "--notitle", "--prebuilt", "--gps-in=100000", "--parody-log", "--crawl-log", "--rave-log",
		"--shisha-log", "--padel-log", "--trend-log", "--meet-log", "--boat-log", "--dekalog-log", "--kino-log",
		"--ev-log", "--stories-log", "--clock=20:30", "--date=20261114", "--call-in=100000"],
	["--nosave", "--notitle", "--autopilot", "--clock=12:00", "--date=20261114"],
	["--nosave", "--free", "--nohud", "--prebuilt", "--no-police", "--no-traffic"],
]
## One list per test flag that runs the harness's code (parse_with's; the three of
## `parse_stream()` are set directly). {STOPS} and {EGG} are filled in.
const HARNESS_LISTS := [
	["--nosave", "--bench"], ["--nosave", "--probe"], ["--nosave", "--cam-log"],
	["--nosave", "--cam-test=classic_turn"], ["--nosave", "--lineup"], ["--nosave", "--teleport-test"],
	["--nosave", "--quest-quit=10"], ["--nosave", "--contacts=x.tsv"], ["--nosave", "--tram-watch=0"],
	["--nosave", "--drive-into-water=1015,-85"], ["--nosave", "--clicks=640:360:200"],
	["--nosave", "--drag=600:300:300:100:0:320"], ["--nosave", "--stops={STOPS}"],
	["--nosave", "--shots=300"], ["--nosave", "--ram-test"], ["--nosave", "--egg={EGG}"],
]
const STOPS_FILE := "user://check_dev_flags_stops.json"
## The harness calls with no test of a value `wants_harness()` reads above them: each reads its
## flags itself and does nothing when they are empty (callee -> those flag values, read as
## `m.flags.NAME` in its body in dev_harness.gd).
const TESTS_ITSELF := {"_inject_clicks": ["clicks", "drags"], "_stop_step": ["stops"]}
## main.gd's values that only the harness sets to what a call's test looks for (value -> those
## values): water_test is 1 or 2 only after `harness._start_water_test()`, which runs under
## `flags._water_test_at`.
const HARNESS_SETS := {"water_test": [1, 2]}

var _fails: PackedStringArray = []


func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	var dev := _code(FileAccess.get_file_as_string(DEV))
	var main_src := FileAccess.get_file_as_string(MAIN)
	for path in [MAIN, DEV]:
		var raw := FileAccess.get_file_as_string(path)
		if raw.contains("\"\"\"") or raw.contains("'''"):
			_fails.append("%s has a triple-quoted string: these rules read it line by line" % path)
	var fields := _fields(dev)
	var owned := _owned(dev)
	_no_outside_writes(fields)
	_owned_documented(owned, main_src)
	_main_reads_no_flag(main_src)
	_one_source()
	var usec := _empty_list(fields)
	var wants := _wants_names(dev, fields, owned)
	var lists := _wants_runs()
	var calls := _harness(main_src, wants)
	if _fails.is_empty():
		print("check_dev_flags: OK (%d flag values in dev_flags.gd, written there only; %d of main's own, each documented; an empty list parses in %d µs; the harness loads in one place, after both parsers and only when `wants_harness()` (%d values) is true: false for an empty list and %d lists without a test flag (--nosave alone first), true for %d test flags; %d harness calls, each behind `harness != null`: %d under a test of a value that loads the harness, %d reading their own flags)" % [fields.size(), owned.size(), usec, wants.size(), lists[0], lists[1], calls[0], calls[1], calls[0] - calls[1]])
		quit(0)
	else:
		for f in _fails:
			print("check_dev_flags: FAIL " + f)
		quit(1)


## The string literals of a script's code (not of its comments), their contents.
func _literals(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var lit := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"|'((?:[^'\\\\]|\\\\.)*)'")
	for line in text.split("\n"):
		var spans := lit.search_all(line)
		var hash := -1
		var from := 0
		while true:
			var h := line.find("#", from)
			if h < 0:
				break
			var inside := false
			for s in spans:
				if h > s.get_start() and h < s.get_end():
					inside = true
			if not inside:
				hash = h
				break
			from = h + 1
		for s in spans:
			if hash < 0 or s.get_start() < hash:
				out.append(s.get_string(1) if s.get_string(1) != "" or s.get_string(0).begins_with("\"") else s.get_string(2))
	return out


## A script's text with its comments and strings blanked, so names in them do not count.
func _code(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		var s := RegEx.create_from_string("\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'").sub(line, "\"\"", true)
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
	for path in _scripts("res://scripts") + _scripts("res://tools"):
		if path == DEV:
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


## The command line has one reader, release.gd (`Release.game_args()`: nothing in a release build).
func _one_source() -> void:
	var r := RegEx.create_from_string("\\bOS\\.get_cmdline_(user_)?args\\(")
	for path in _scripts("res://scripts"):
		if path == "res://scripts/release.gd":
			continue
		var code := _code(FileAccess.get_file_as_string(path))
		var mm := r.search(code)
		if mm != null:
			_fails.append("%s:%d reads the command line itself: flags come through Release.game_args(), empty in a release build" % [path, code.substr(0, mm.get_start()).count("\n") + 1])


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
	if f.wants_harness():
		_fails.append("after an empty list wants_harness() is true: a release build would load the harness")
	game.free()
	return usec


## The values `wants_harness()` reads (name -> "flags" for a field of dev_flags.gd, "main" for
## `m.NAME`, a value of main's that a flag sets).
func _wants_names(dev: String, fields: Dictionary, owned: Dictionary) -> Dictionary:
	var lines := dev.split("\n")
	var at := -1
	for i in lines.size():
		if lines[i].begins_with("func wants_harness() -> bool:"):
			at = i
	var out := {}
	if at < 0:
		_fails.append("dev_flags.gd has no `func wants_harness() -> bool:`")
		return out
	var body := ""
	for k in range(at + 1, lines.size()):
		if lines[k].strip_edges() != "" and not lines[k].begins_with("\t"):
			break
		body += lines[k] + "\n"
	for mm in RegEx.create_from_string("(?<![\\w.])m\\.(\\w+)").search_all(body):
		var name := mm.get_string(1)
		if not owned.has(name):
			_fails.append("wants_harness() reads m.%s, which no flag sets" % name)
		out[name] = "main"
	for mm in RegEx.create_from_string("(?<![\\w.])([A-Za-z_]\\w*)").search_all(body):
		var name := mm.get_string(1)
		if name in ["return", "or", "and", "not", "m", "Vector2", "true", "false"]:
			continue
		if fields.has(name):
			out[name] = "flags"
		else:
			_fails.append("wants_harness() reads %s, which is not a flag value" % name)
	if out.is_empty():
		_fails.append("wants_harness() reads no flag value")
	return out


## One fresh game and flags, `parse_with(list)`: does it want the harness?
func _wants_after(list: Array) -> bool:
	var game: Node = load(MAIN).new()
	var f: DevFlags = game.get("flags")
	f.m = game
	f.parse_with(PackedStringArray(list))
	var on := f.wants_harness()
	game.free()
	return on


## wants_harness() after each list. Returns [lists checked false, lists checked true].
func _wants_runs() -> Array:
	var off := 0
	var on := 0
	for list: Array in NO_HARNESS_LISTS:
		off += 1
		if _wants_after(list):
			_fails.append("wants_harness() is true after %s: that run would load the harness" % " ".join(list))
	var fa := FileAccess.open(STOPS_FILE, FileAccess.WRITE)
	fa.store_string("[[0, 0, 0, -30, 60, \"a\"]]")
	fa.close()
	var book := EggBook.new()
	var egg := ""
	if book.load_eggs() and not book.by_id.is_empty():
		egg = str(book.by_id.keys()[0])
	book.free()
	if egg == "":
		_fails.append("no egg in eggs.json for the --egg= sample")
	for list: Array in HARNESS_LISTS:
		var l := []
		for a: String in list:
			l.append(a.replace("{STOPS}", STOPS_FILE).replace("{EGG}", egg))
		on += 1
		if not _wants_after(l):
			_fails.append("wants_harness() is false after %s: its test would run with no harness" % " ".join(l))
	DirAccess.remove_absolute(STOPS_FILE)
	# parse_stream()'s three (it reads the run's own list, so they are set as it sets them)
	for name in ["_spots", "_pass_kind", "_soak_minutes"]:
		var game: Node = load(MAIN).new()
		var f: DevFlags = game.get("flags")
		f.m = game
		match name:
			"_spots": f._spots.append(Vector3(-110, -85, 90))
			"_pass_kind": f._pass_kind = "look"
			"_soak_minutes": game.set("_soak_minutes", 1.0)
		on += 1
		if not f.wants_harness():
			_fails.append("wants_harness() is false with %s set (--spots=, --stream-pass=, --stream-soak=)" % name)
		game.free()
	return [off, on]


## The harness (TD-4 a2): its one load, every use in main.gd, and every call's test.
## Returns [calls, of them under a test of a value wants_harness() reads].
func _harness(main_src: String, wants: Dictionary) -> Array:
	if not FileAccess.file_exists(HARNESS):
		_fails.append("there is no %s" % HARNESS)
		return [0, 0]
	var code := _code(main_src).split("\n")
	var raw := main_src.split("\n")
	# the one load
	var loads := []
	for i in code.size():
		if code[i].contains("load(DEV_HARNESS)"):
			loads.append(i)
	var load_at := -1
	if loads.size() != 1 or code[loads[0]].strip_edges() != "harness = load(DEV_HARNESS).new()":
		_fails.append("main.gd loads the harness %d times (one `harness = load(DEV_HARNESS).new()` expected)" % loads.size())
	else:
		load_at = loads[0]
		var k := _prev_code_at(code, load_at)
		if k < 0 or code[k].strip_edges() != "if flags.wants_harness():" or _indent(code[k]) != _indent(code[load_at]) - 1:
			_fails.append("main.gd:%d loads the harness without `if flags.wants_harness():` right above" % (load_at + 1))
		var parsed := {"flags.parse()": -1, "flags.parse_stream()": -1}
		for j in range(load_at - 1, -1, -1):
			var t := code[j].strip_edges()
			if t.begins_with("func ") or t.begins_with("static func "):
				break
			if parsed.has(t) and parsed[t] < 0:
				parsed[t] = j
		for p: String in parsed:
			if parsed[p] < 0:
				_fails.append("main.gd:%d loads the harness before `%s` in the same function: the test flags are not all read yet" % [load_at + 1, p])
	if not main_src.contains("const DEV_HARNESS := \"%s\"" % HARNESS):
		_fails.append("main.gd's DEV_HARNESS is not %s" % HARNESS)
	# nothing else loads it, reaches main's harness, or names it
	var member := RegEx.create_from_string("\\.harness\\b")
	for path in _scripts("res://scripts") + _scripts("res://tools") + _scripts("res://addons"):
		var text := FileAccess.get_file_as_string(path)
		if path != HARNESS and text.contains("preload(\"%s\")" % HARNESS):
			_fails.append("%s preloads dev_harness.gd: it would load in every build" % path)
		if not path.begins_with("res://tools/") and path != MAIN and text.contains("\"%s\"" % HARNESS):
			_fails.append("%s names dev_harness.gd's path: only main.gd loads it" % path)
		if member.search(_code(text)) != null:
			_fails.append("%s reaches main's harness as a member (`self.harness`, `main.harness`): only main.gd calls it, as `harness`, behind `if harness != null:`" % path)
		if path != SELF and "harness" in _literals(text):
			_fails.append("%s names `harness` as a string (`get(\"harness\")`, ...): a call on what it returns is not checked" % path)
	var hs: Variant = load(HARNESS)
	if not (hs is GDScript) or not (hs as GDScript).can_instantiate():
		_fails.append("dev_harness.gd does not compile")
	if RegEx.create_from_string("(?m)^class_name\\b").search(_code(FileAccess.get_file_as_string(HARNESS))) != null:
		_fails.append("dev_harness.gd has a class_name: any script naming it would load it in every build")
	var h_code := _code(FileAccess.get_file_as_string(HARNESS))
	# every use of `harness`
	var calls := 0
	var tested := 0
	var use := RegEx.create_from_string("(?<![\\w.])harness\\b")
	var test_use := RegEx.create_from_string("^harness\\s*!=\\s*null\\b")
	var call_use := RegEx.create_from_string("^harness\\s*\\.\\s*(\\w+)")
	for i in code.size():
		var t := code[i].strip_edges()
		for mm in use.search_all(code[i]):
			var rest := code[i].substr(mm.get_start())
			if t == "var harness: Object = null" and _indent(code[i]) == 0:
				continue
			if i == load_at:
				continue
			if test_use.search(rest) != null:
				continue
			var cm := call_use.search(rest)
			if cm == null:
				_fails.append("main.gd:%d uses `harness` other than in a call or a `harness != null` test" % (i + 1))
				continue
			var callee := cm.get_string(1)
			if callee == "m" and t == "harness.m = self" and load_at >= 0 and i == _next_code_at(code, load_at):
				continue
			calls += 1
			var heads := _enclosing(code, i)
			if not t.begins_with("if harness != null: ") or t.contains(";"):
				_fails.append("main.gd:%d uses harness.%s in a line that is not one statement behind `if harness != null: `: a release build would end there (TD-21)" % [i + 1, callee])
				continue
			# the test above reads a value that loads the harness
			if TESTS_ITSELF.has(callee):
				var body := _body(h_code, callee)
				for v: String in TESTS_ITSELF[callee]:
					if not wants.has(v):
						_fails.append("TESTS_ITSELF: harness.%s reads %s, which wants_harness() does not read" % [callee, v])
					if not body.contains("m.flags.%s" % v):
						_fails.append("TESTS_ITSELF: harness.%s does not read m.flags.%s" % [callee, v])
				continue
			if _reads_wanted(heads, wants):
				tested += 1
			else:
				_fails.append("main.gd:%d calls harness.%s under no test of a value wants_harness() reads: with its flag on the harness may be missing (add the flag to wants_harness(), or list the call in TESTS_ITSELF)" % [i + 1, callee])
	# main's own values that wants_harness() reads: written by the flags and the harness only
	for name: String in wants:
		if wants[name] != "main":
			continue
		var w := RegEx.create_from_string("(?<![\\w.])(self\\.)?%s\\s*(\\[[^\\]]*\\]\\s*)*(\\+|-|\\*|/)?=(?!=)|(?<![\\w.])(self\\.)?%s\\.(append|append_array|clear|erase|merge|push_back|assign|resize|fill|remove_at|insert|pop_back|pop_front)\\(" % [name, name])
		for i in code.size():
			if w.search(code[i]) != null and not code[i].begins_with("var "):
				_fails.append("main.gd:%d writes %s, which wants_harness() reads: only a flag may turn it on" % [i + 1, name])
		var ow := RegEx.create_from_string("\\.%s\\s*(\\[[^\\]]*\\]\\s*)*(\\+|-|\\*|/)?=(?!=)|\\.%s\\.(append|append_array|clear|erase|merge|push_back|assign|resize|fill|remove_at|insert|pop_back|pop_front)\\(" % [name, name])
		for path in _scripts("res://scripts") + _scripts("res://tools") + _scripts("res://addons"):
			if path in [MAIN, DEV, HARNESS]:
				continue
			var oc := _code(FileAccess.get_file_as_string(path))
			var om := ow.search(oc)
			if om != null:
				_fails.append("%s:%d writes .%s, which wants_harness() reads: only a flag may turn it on" % [path, oc.substr(0, om.get_start()).count("\n") + 1, name])
	for name: String in HARNESS_SETS:
		var w := RegEx.create_from_string("(?<![\\w.])%s\\s*=\\s*(\\d+)\\b" % name)
		for i in code.size():
			var mm := w.search(code[i])
			if mm != null and int(mm.get_string(1)) in HARNESS_SETS[name]:
				_fails.append("main.gd:%d sets %s to %s: HARNESS_SETS says only the harness does" % [i + 1, name, mm.get_string(1)])
	return [calls, tested]


## The block headers above line i, innermost first, up to its function's own.
func _enclosing(code: PackedStringArray, i: int) -> PackedStringArray:
	var out := PackedStringArray()
	var ind := _indent(code[i])
	for k in range(i - 1, -1, -1):
		var t := code[k].strip_edges()
		if t == "":
			continue
		var ik := _indent(code[k])
		if ik < ind:
			out.append(t)
			if t.begins_with("func ") or t.begins_with("static func "):
				break
			ind = ik
	return out


## True when a header above reads a value of wants_harness() (flags.NAME, or main's own NAME) or
## one of HARNESS_SETS.
func _reads_wanted(heads: PackedStringArray, wants: Dictionary) -> bool:
	for h in heads:
		if h.begins_with("func ") or h.begins_with("static func "):
			break
		for mm in RegEx.create_from_string("(?<![\\w])flags\\.(\\w+)").search_all(h):
			if wants.get(mm.get_string(1), "") == "flags" and not _negated(h, mm.get_start(), mm.get_end()):
				return true
		for mm in RegEx.create_from_string("(?<![\\w.])(\\w+)").search_all(h):
			if (wants.get(mm.get_string(1), "") == "main" or HARNESS_SETS.has(mm.get_string(1))) and not _negated(h, mm.get_start(), mm.get_end()):
				return true
	return false


## True when the value at [a, b) in a test is read as off: `not X`, `!X`, `X.is_empty()`, `X == ""`,
## `X == 0`, `X < 0`, `X == Vector2.INF`, `X == null` (two of them cancel: `not X.is_empty()` is on).
func _negated(h: String, a: int, b: int) -> bool:
	var before := h.substr(0, a).strip_edges(false, true)
	var neg := before.ends_with(" not") or before == "not" or before.ends_with("(not") or before.ends_with("!")
	var off := RegEx.create_from_string("^(\\.is_empty\\(\\)|\\s*==\\s*(\"\"|0(\\.0)?\\b|Vector2\\.INF|null)|\\s*<=?\\s*0(\\.0)?\\b)").search(h.substr(b)) != null
	return neg != off


## The body of dev_harness.gd's function `name` (its indented lines).
func _body(h_code: String, name: String) -> String:
	var lines := h_code.split("\n")
	var out := ""
	for i in lines.size():
		if lines[i].begins_with("func %s(" % name):
			for k in range(i + 1, lines.size()):
				if lines[k].strip_edges() != "" and not lines[k].begins_with("\t"):
					break
				out += lines[k] + "\n"
	return out


## Every .gd file under dir, its folders too.
func _scripts(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append("%s/%s" % [dir, f])
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts("%s/%s" % [dir, d]))
	return out


## The nearest line above i with code (comments are blanked already), or -1.
func _prev_code_at(code: PackedStringArray, i: int) -> int:
	for k in range(i - 1, -1, -1):
		if code[k].strip_edges() != "":
			return k
	return -1


## The nearest line below i with code, or -1.
func _next_code_at(code: PackedStringArray, i: int) -> int:
	for k in range(i + 1, code.size()):
		if code[k].strip_edges() != "":
			return k
	return -1


func _indent(line: String) -> int:
	return line.length() - line.lstrip("\t").length()
