extends SceneTree
## The error trap (tech-debt TD-14, error_trap.gd). Feeds the trap's two entry points by hand (a
## real error line would fail this step under tools/verify.sh) and checks that:
## - an error seen again only counts; another place or text is another kind; each kind keeps where
##   it happened and what the game was doing the first time; past MAX_ERRORS the first kinds stay
##   and the rest are counted as dropped;
## - the trail keeps the last TRAIL printed lines, a print of several lines line by line, an
##   error-stream line marked; a long line is cut; the real path of user:// is taken out;
## - registered with the engine, a print reaches the trail, and after it is removed none does;
## - the report names the errors with their counts and contexts, the trail and the caller's header;
## - with no path (--nosave, the checks) no file appears;
## - the session file: every line is on the disk as it comes; a file that does not end with the
##   mark is read by the next start as a session that closed by itself, with its last lines, and is
##   kept as .prev.log; after mark() it is not; a line after the mark takes that back; after stop()
##   nothing more is written and resume() opens it again; a last line with no line end counts as
##   closed by itself; an empty file does not; a long session's file starts again and stays small;
## - the Settings card's sound page has the RAPORT button beside LICENCJE, both inside the card at
##   a phone's size; a tap closes the card and asks main.gd for the report (`changed("report", 1)`);
##   with `report_on` off (a tester's build) the page has LICENCJE alone;
## - a release build gets no trap at all (`make`), and only a debug build that keeps its files
##   has a session file (`session_path`).
## Deletes its scratch files.
##   godot --headless --path game --script res://tools/check_error_trap.gd

const ErrorTrap := preload("res://scripts/error_trap.gd")
const SettingsPanel := preload("res://scripts/settings_panel.gd")
const SCRATCH := "user://check_error_trap.log"
const SCRATCH_PREV := "user://check_error_trap.prev.log"

var _problems := 0
var _none: Array[ScriptBacktrace] = []
var _asked: Array = []


func _initialize() -> void:
	_clean()
	_errors()
	_trail()
	_registered()
	_report()
	_session()
	_long_session()
	await _button()
	_clean()
	if _problems == 0:
		print("check_error_trap: OK")
		quit(0)
	else:
		print("check_error_trap: %d problem(s)" % _problems)
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _clean() -> void:
	for f in [SCRATCH, SCRATCH_PREV]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))


## A script error as a debug build hands it over: the function, the file and the line are the script's.
func _boom(t: ErrorTrap, text := "Cannot call method 'start' on a null value.", line := 88) -> void:
	t._log_error("start", "res://scripts/kino_tour.gd", line, text, "", false, 2, _none)


func _lines(p: String) -> PackedStringArray:
	return FileAccess.get_file_as_string(p).split("\n", false)


func _errors() -> void:
	var t := ErrorTrap.new()
	t.start()
	t.set_context("quest · srodmiescie")
	for i in 3:
		_boom(t)
	t.set_context("free · wola")
	_boom(t)
	_expect(t.errors.size() == 1 and t.total == 4, "the same error four times is one kind, four in all (got %d, %d)" % [t.errors.size(), t.total])
	var e: Dictionary = t.errors[0]
	_expect(int(e["count"]) == 4, "the kind counts its repeats (got %s)" % e["count"])
	_expect(e["where"] == "kino_tour.gd:88 in start", "where is file:line in function (got %s)" % e["where"])
	_expect(e["context"] == "quest · srodmiescie", "the context is the first time's (got %s)" % e["context"])
	_expect(int(e["kind"]) == 2, "kind 2 is a script error")
	# An engine error: the rationale is the text, the condition is not.
	t._log_error("get_node", "scene/main/node.cpp", 1877, "Method/function failed. Returning: nullptr", "Node not found: \"nope\".", false, 0, _none)
	_expect(t.errors.size() == 2 and t.errors[1]["text"] == "Node not found: \"nope\"." and t.errors[1]["where"] == "node.cpp:1877 in get_node",
			"an engine error keeps its message and its place (got %s)" % [t.errors[t.errors.size() - 1]])
	t._log_error("push_warning", "core/variant/variant_utility.cpp", 1033, "a warning", "", false, 1, _none)
	_expect(t.errors.size() == 3 and int(t.errors[2]["kind"]) == 1, "a warning is its own kind")
	_boom(t, "Cannot call method 'start' on a null value.", 91)
	_expect(t.errors.size() == 4, "the same text on another line is another kind")
	# The first error of a kind is in the trail, in order with the printed lines; its repeats are not.
	_expect(t.trail.size() == 4 and t.trail[0].begins_with("SCRIPT ERROR: Cannot call") and t.trail[0].ends_with("[quest · srodmiescie]"),
			"an error's first time is one trail line with its context (got %s)" % [t.trail])
	# The cap: the first kinds stay.
	for i in ErrorTrap.MAX_ERRORS + 10:
		_boom(t, "kind %d" % i)
	_expect(t.errors.size() == ErrorTrap.MAX_ERRORS and t.dropped == 14, "MAX_ERRORS kinds are kept, the rest counted (got %d kept, %d dropped)" % [t.errors.size(), t.dropped])
	_expect(t.errors[0]["text"].begins_with("Cannot call") and t.total == 7 + ErrorTrap.MAX_ERRORS + 10, "the first kind stays and every error is counted (got %d)" % t.total)
	_expect(not FileAccess.file_exists(SCRATCH), "with no path no file appears")
	# A release build (testers' builds) has no trap at all; this check runs in a debug build.
	_expect(ErrorTrap.make(false) == null, "a release build gets no trap")
	_expect(ErrorTrap.make(true) is ErrorTrap and ErrorTrap.make() is ErrorTrap, "a debug build gets one")
	# A kept run has the session file, --nosave has none.
	_expect(ErrorTrap.session_path(true) == ErrorTrap.PATH and ErrorTrap.session_path(false) == "", "a debug build's kept run has the session file, --nosave has none")


func _trail() -> void:
	var t := ErrorTrap.new()
	t.start()
	for i in ErrorTrap.TRAIL + 10:
		t._log_message("line %d\n" % i, false)
	_expect(t.trail.size() == ErrorTrap.TRAIL and t.trail[0] == "line 10" and t.trail[t.trail.size() - 1] == "line %d" % (ErrorTrap.TRAIL + 9),
			"the trail keeps the last TRAIL lines (got %d, first %s)" % [t.trail.size(), t.trail[0]])
	t._log_message("one\ntwo\n", false)
	_expect(t.trail[t.trail.size() - 2] == "one" and t.trail[t.trail.size() - 1] == "two", "a print of two lines is two trail lines")
	t._log_message("to the error stream\n", true)
	_expect(t.trail[t.trail.size() - 1] == "! to the error stream", "an error-stream line is marked")
	t._log_message("x".repeat(ErrorTrap.LINE_MAX * 2), false)
	_expect(t.trail[t.trail.size() - 1].length() == ErrorTrap.LINE_MAX, "a long line is cut")
	t._log_message("save: 12 zł (%s)" % ProjectSettings.globalize_path("user://save.cfg"), false)
	_expect(t.trail[t.trail.size() - 1] == "save: 12 zł (user://save.cfg)", "the real path of user:// is taken out (got %s)" % t.trail[t.trail.size() - 1])
	_expect(t.errors.is_empty(), "printed lines are not errors")


func _registered() -> void:
	var t := ErrorTrap.new()
	t.start()
	OS.add_logger(t)
	print("trap check: a printed line")
	OS.remove_logger(t)
	print("trap check: a line after the trap was removed")
	_expect(t.trail.size() == 1 and t.trail[0] == "trap check: a printed line", "the engine hands a print to the trap, and none once it is removed (got %s)" % [t.trail])


func _report() -> void:
	var t := ErrorTrap.new()
	t.start()
	t.set_context("chase · praga")
	_boom(t)
	_boom(t)
	t._log_error("push_error", "core/variant/variant_utility.cpp", 1023, "the lane graph has no node 7", "", false, 0, _none)
	t._log_message("zone: Chmielna at 31 km/h\n", false)
	var text := t.report(PackedStringArray(["device Test Phone · TestOS 1"]))
	for part in ["device Test Phone · TestOS 1", "now: chase · praga", "errors: 2 kinds, 3 in all",
			"script error ×2: Cannot call method 'start' on a null value.", "at kino_tour.gd:88 in start",
			"error ×1: the lane graph has no node 7", "[chase · praga]", "last lines:", "  zone: Chmielna at 31 km/h",
			"engine %s" % Engine.get_version_info()["string"]]:
		_expect(text.contains(part), "the report has '%s'" % part)
	_expect(not text.contains("closed by itself"), "no word of a crash when there was none")
	_expect(ErrorTrap.new().report().contains("errors: none"), "a run with no errors says so")
	_expect(t.summary() == "2 kinds of error, 3 in all", "the summary line (got %s)" % t.summary())


func _session() -> void:
	# The first session: nothing before it.
	var a := ErrorTrap.new()
	a.start(SCRATCH)
	_expect(not a.last_crashed and a.last_lines.is_empty(), "a first session has no crash before it")
	a._log_message("hello\n", false)
	_boom(a)
	var lines := _lines(SCRATCH)
	_expect(lines.size() == 3 and lines[0].begins_with("session ") and lines[1].ends_with("] hello") and lines[2].contains("SCRIPT ERROR: Cannot call"),
			"every line is on the disk as it comes (got %s)" % [lines])
	a = null  # the app is gone, with no mark
	var b := ErrorTrap.new()
	b.start(SCRATCH)
	_expect(b.last_crashed, "a file with no mark at its end is a session that closed by itself")
	_expect(b.last_lines.size() == 3 and b.last_lines[1].ends_with("] hello"), "and its last lines are kept (got %s)" % [b.last_lines])
	_expect(FileAccess.file_exists(SCRATCH_PREV) and _lines(SCRATCH_PREV).size() == 3, "the last session's file is kept as .prev.log")
	_expect(_lines(SCRATCH).size() == 1, "and this session's file starts again")
	var text := b.report()
	_expect(text.contains("closed by itself") and text.contains("] hello"), "the report shows the crashed session's end")
	_expect(b.summary().ends_with("the last session closed by itself"), "the summary says it too")
	# The app goes to the background and is closed there: in order.
	b._log_message("driving\n", false)
	b.mark()
	b = null
	var c := ErrorTrap.new()
	c.start(SCRATCH)
	_expect(not c.last_crashed and c.last_lines.is_empty(), "a file that ends with the mark closed in order")
	# Back from the background, a line, then gone: the mark is taken back.
	c.mark()
	c._log_message("back in the game\n", false)
	c = null
	var d := ErrorTrap.new()
	d.start(SCRATCH)
	_expect(d.last_crashed, "a line after the mark takes it back")
	# stop(): what the engine prints while it shuts down is not written.
	d.stop()
	d._log_message("shutting down\n", false)
	_expect(_lines(SCRATCH)[-1] == ErrorTrap.MARK and d.trail[-1] == "shutting down", "after stop() the file takes no more lines, the trail does")
	# resume(): NOWA GRA's reload goes on in the same file.
	d.resume()
	d._log_message("a new game\n", false)
	lines = _lines(SCRATCH)
	_expect(lines.size() == 3 and lines[1] == ErrorTrap.MARK and lines[2].ends_with("] a new game"), "resume() opens the same file again (got %s)" % [lines])
	d.stop()
	d = null
	var e := ErrorTrap.new()
	e.start(SCRATCH)
	_expect(not e.last_crashed, "a session that stopped in order after a reload closed in order")
	e = null
	# A last line with no line end: the write was cut.
	var f := FileAccess.open(SCRATCH, FileAccess.WRITE)
	f.store_string("session x\n[00:01] whole\n%s\n[00:02] cu" % ErrorTrap.MARK)
	f.close()
	var g := ErrorTrap.new()
	g.start(SCRATCH)
	_expect(g.last_crashed and g.last_lines[-1] == "(a cut line)" and g.last_lines[-2] == ErrorTrap.MARK, "a cut last line is a session that closed by itself (got %s)" % [g.last_lines])
	g = null
	# An empty file: nothing was running.
	FileAccess.open(SCRATCH, FileAccess.WRITE).close()
	var h := ErrorTrap.new()
	h.start(SCRATCH)
	_expect(not h.last_crashed, "an empty file is not a crash")
	h.stop()
	# tail(): only whole lines of the last bytes.
	f = FileAccess.open(SCRATCH, FileAccess.WRITE)
	for i in 100:
		f.store_line("line %03d" % i)
	f.close()
	var end := ErrorTrap.tail(SCRATCH, 20)
	_expect(end.size() == 2 and end[0] == "line 098" and end[1] == "line 099", "tail() gives the whole lines of the last bytes (got %s)" % [end])
	_expect(ErrorTrap.tail("user://check_error_trap_none.log", 100).is_empty(), "tail() of a missing file is empty")


func _long_session() -> void:
	_clean()
	var t := ErrorTrap.new()
	t.start(SCRATCH)
	var n := ErrorTrap.FILE_LINES + ErrorTrap.TRAIL + 25
	for i in n:
		t._log_message("line %d\n" % i, false)
	var lines := _lines(SCRATCH)
	_expect(lines.size() <= ErrorTrap.FILE_LINES and lines[0] == "-- earlier lines dropped --", "a long session's file starts again (got %d lines, first %s)" % [lines.size(), lines[0]])
	_expect(lines[-1].ends_with("] line %d" % (n - 1)), "and its end is the latest line (got %s)" % lines[-1])
	_expect(lines.size() >= ErrorTrap.TRAIL, "with the trail's lines before it (got %d)" % lines.size())
	t.stop()


func _button() -> void:
	var panel := SettingsPanel.new()
	panel.pt = 3.0
	panel.safe = Rect2(0, 0, 2532, 1170)
	root.add_child(panel)
	await process_frame
	panel.changed.connect(func(key: String, value: Variant): _asked.append([key, value]))
	panel.open({"controls": 0, "master": 1.0, "music": 1.0, "effects": 1.0})
	panel.set_tab(3)
	await process_frame
	await process_frame
	var report := panel.find_child("report", true, false) as Button
	var credits := panel.find_child("credits", true, false) as Button
	_expect(report != null and report.is_visible_in_tree(), "the sound page has the RAPORT button")
	if report != null and credits != null:
		var card: Rect2 = panel.card_rect()
		_expect(card.encloses(report.get_global_rect()) and card.encloses(credits.get_global_rect()),
				"RAPORT and LICENCJE are inside the card (card %s, report %s, credits %s)" % [card, report.get_global_rect(), credits.get_global_rect()])
		_expect(not report.get_global_rect().intersects(credits.get_global_rect()), "and do not overlap")
		_expect(is_equal_approx(report.get_global_rect().position.y, credits.get_global_rect().position.y), "in one row")
		report.pressed.emit()
		_expect(not panel.is_open(), "a tap on RAPORT closes the card")
		_expect(_asked == [["report", 1]], "and asks for the report (got %s)" % [_asked])
	panel.queue_free()
	# A tester's build: no RAPORT button, LICENCJE where it was.
	var plain := SettingsPanel.new()
	plain.pt = 3.0
	plain.safe = Rect2(0, 0, 2532, 1170)
	plain.report_on = false
	root.add_child(plain)
	await process_frame
	plain.open({"controls": 0, "master": 1.0, "music": 1.0, "effects": 1.0})
	plain.set_tab(3)
	await process_frame
	await process_frame
	var only := plain.find_child("credits", true, false) as Button
	_expect(plain.find_child("report", true, false) == null, "a tester's build has no RAPORT button")
	_expect(only != null and only.is_visible_in_tree() and plain.card_rect().encloses(only.get_global_rect()), "and LICENCJE is still on the page")
	plain.queue_free()
