extends Logger
## The error trap (tech-debt TD-14): what went wrong in this run, kept for our own test runs (a
## debug build: Autopilot on the Mac, a device run on the phone). Godot gives every error,
## warning and printed line to a Logger (`OS.add_logger`, done by main.gd). This one keeps:
##  - the errors and warnings, each kind once with a count, where it happened and what the game
##    was doing then (`context`, which main.gd refreshes about once a second);
##  - the trail: the last TRAIL printed lines;
##  - in a debug build's kept run (not --nosave) the session file, `user://session.log`: every
##    line as it comes, flushed, so the lines before a crash are on the disk. `mark()` ends the file with
##    MARK when the app goes to the background or closes; a file that does not end with it is a
##    run that ended by itself, which the next launch reads as `last_crashed` (the file is
##    `session.prev.log` by then).
## `report()` is the text the Settings' RAPORT button copies (a debug build has the button).
##
## Why debug builds only (F, 2026-11-12). A debug build reports every script mistake as an
## error, so it is here with its line. A release build (the TestFlight archive, the Play AAB)
## does not: a call on a null typed value or a freed object, or an integer division by zero,
## ends the app, and the other mistakes carry on with a wrong value and no line (measured with
## the 4.7.2 release template). Testers' builds stay on the release engine, for speed, and
## testers would not send a report: so a release build keeps the trap in memory and nothing
## else, with no file, no button and no note.
##
## Rules. The engine calls a Logger from any thread: every entry takes the lock. It never prints
## and never pushes an error (the engine would hand the line straight back). The session file is
## the one kept file written in place, not through safe_file.gd: it is a log that only grows,
## and a cut one loses its last line.

const PATH := "user://session.log"
## The last line of a session that went to the background or closed.
const MARK := "-- closed --"
const KINDS: Array[String] = ["error", "warning", "script error", "shader error"]
## Kinds of error kept. The first ones stay: the first is most often the cause of the rest.
const MAX_ERRORS := 50
## Printed lines kept in memory.
const TRAIL := 40
## Lines a session file takes before it starts again from the trail (a print in a loop must not
## fill the phone).
const FILE_LINES := 2000
## The end of a crashed session shown in the next one's report.
const PREV_LINES := 15
## Characters of one line kept.
const LINE_MAX := 300

## Kinds of error: {kind, text, where, count, first, last, context}.
var errors: Array[Dictionary] = []
## Every error and warning, repeats counted.
var total := 0
## Kinds that came after MAX_ERRORS were kept.
var dropped := 0
var trail := PackedStringArray()
## The session file, or "" when nothing is written (--nosave, the checks).
var path := ""
## True when the last session's file did not end with MARK.
var last_crashed := false
## The end of that file.
var last_lines := PackedStringArray()

var _context := "starting"
var _index := {}
var _lock := Mutex.new()
var _file: FileAccess
var _written := 0
var _start_ms := 0
## The real paths of user:// and of the home folder: taken out of every kept line.
var _user_dir := ""
var _home_dir := ""
## When the app's own file was made: the nearest thing to a build number the game can read.
var _app_date := "unknown"


## The session file of this run, or "": only a debug build that keeps its files writes one.
static func session_path(kept: bool) -> String:
	return PATH if kept and OS.is_debug_build() else ""


## Starts the trap; with `file_path` it also reads how the last session ended, keeps that file
## as <name>.prev.log and opens this session's.
func start(file_path := "") -> void:
	_start_ms = Time.get_ticks_msec()
	_user_dir = ProjectSettings.globalize_path("user://").trim_suffix("/")
	_home_dir = OS.get_environment("HOME").trim_suffix("/")
	var app := OS.get_executable_path()
	if app != "" and FileAccess.file_exists(app):
		_app_date = Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(app), true)
	if file_path == "":
		return
	_lock.lock()
	path = file_path
	var real := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var lines := tail(path, 8192)
		last_crashed = not lines.is_empty() and lines[lines.size() - 1] != MARK
		if last_crashed:
			last_lines = lines.slice(maxi(0, lines.size() - PREV_LINES))
		DirAccess.rename_absolute(real, ProjectSettings.globalize_path(prev_path()))
	_file = FileAccess.open(path, FileAccess.WRITE)
	_put("session %s" % Time.get_datetime_string_from_system(false, true))
	_lock.unlock()


func prev_path() -> String:
	return path.get_basename() + ".prev.log"


## What the game is doing now, for the errors that come next.
func set_context(text: String) -> void:
	_lock.lock()
	_context = text
	_lock.unlock()


func context() -> String:
	return _context


## The app went to the background or its window closed: so far this session ended in order.
## Any line after this takes that back.
func mark() -> void:
	_lock.lock()
	_put(MARK)
	_lock.unlock()


## The scene is leaving the tree (a quit, or NOWA GRA's reload): the file ends in order and takes
## no more lines (what the engine prints while it shuts down is not a crash). `resume` opens it again.
func stop() -> void:
	_lock.lock()
	_put(MARK)
	_file = null
	_lock.unlock()


func resume() -> void:
	_lock.lock()
	if path != "" and _file == null:
		_file = FileAccess.open(path, FileAccess.READ_WRITE)
		if _file != null:
			_file.seek_end()
	_lock.unlock()


func _log_message(message: String, error: bool) -> void:
	var lines := message.split("\n", false)
	_lock.lock()
	for i in range(maxi(0, lines.size() - TRAIL), lines.size()):
		_keep(("! " if error else "") + lines[i])
	_lock.unlock()


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	var where := "%s:%d in %s" % [file.get_file(), line, function]
	for b in script_backtraces:
		if b.get_frame_count() > 0:
			where = "%s:%d in %s" % [b.get_frame_file(0), b.get_frame_line(0), b.get_frame_function(0)]
			# An engine error raised by a script's call: the engine's function says which call.
			if error_type != 2 and not function.begins_with("push_"):
				where += " (%s)" % function
			break
	_lock.lock()
	_error(clampi(error_type, 0, KINDS.size() - 1), _clean(rationale if rationale != "" else code), _clean(where))
	_lock.unlock()


## One error (the lock is held): a kind seen before only counts.
func _error(kind: int, text: String, where: String) -> void:
	total += 1
	var key := "%d|%s|%s" % [kind, text, where]
	if _index.has(key):
		var e: Dictionary = errors[int(_index[key])]
		e["count"] = int(e["count"]) + 1
		e["last"] = clock()
		return
	if errors.size() >= MAX_ERRORS:
		dropped += 1
		return
	_index[key] = errors.size()
	errors.append({"kind": kind, "text": text, "where": where, "count": 1, "first": clock(), "last": clock(), "context": _context})
	_keep("%s: %s  at %s  [%s]" % [KINDS[kind].to_upper(), text, where, _context])


## One line into the trail and the session file (the lock is held).
func _keep(line: String) -> void:
	line = _clean(line)
	trail.append(line)
	if trail.size() > TRAIL:
		trail.remove_at(0)
	if _file == null:
		return
	if _written >= FILE_LINES:
		# The file starts again with the lines still in memory, so it stays small and its end is
		# always the latest.
		_file = FileAccess.open(path, FileAccess.WRITE)
		_written = 0
		_put("-- earlier lines dropped --")
		for i in trail.size() - 1:
			_put(trail[i])
	_put("[%s] %s" % [clock(), line])


func _put(line: String) -> void:
	if _file == null:
		return
	_written += 1
	_file.store_line(line)
	_file.flush()


func _clean(text: String) -> String:
	if _user_dir != "":
		text = text.replace(_user_dir, "user:/")
	if _home_dir != "":
		text = text.replace(_home_dir, "~")
	return text.left(LINE_MAX)


## Minutes and seconds since the trap started.
func clock() -> String:
	var s := (Time.get_ticks_msec() - _start_ms) / 1000
	return "%02d:%02d" % [s / 60, s % 60]


## The whole lines in the last `bytes` of a file. A first line cut by `bytes` is dropped; a last
## line with no line end (a write that was cut) comes back as "(a cut line)", so such a file
## never reads as one that closed in order.
static func tail(file_path: String, bytes: int) -> PackedStringArray:
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return PackedStringArray()
	var size := f.get_length()
	var from := maxi(0, size - bytes)
	f.seek(from)
	var data := f.get_buffer(size - from)
	var end := data.rfind(10)
	if end < 0:
		return PackedStringArray()
	var begin := 0
	if from > 0:
		begin = data.find(10) + 1
	var out := PackedStringArray()
	if begin < end:
		out = data.slice(begin, end).get_string_from_utf8().split("\n", false)
	if end < data.size() - 1:
		out.append("(a cut line)")
	return out


## The text to hand over: `header` (the caller's lines on the device), this run's errors with
## their counts, the trail, and the end of the last session when it closed by itself.
func report(header := PackedStringArray()) -> String:
	_lock.lock()
	var out := PackedStringArray()
	out.append("report · %s · running %s" % [Time.get_datetime_string_from_system(false, true), clock()])
	out.append("engine %s · %s build · app file %s" % [Engine.get_version_info().get("string", "?"),
			"debug" if OS.is_debug_build() else "release", _app_date])
	out.append_array(header)
	out.append("now: %s" % _context)
	if not OS.is_debug_build():
		out.append("a release build: the engine reports its own errors here, not a script's mistakes")
	if errors.is_empty():
		out.append("errors: none")
	else:
		out.append("errors: %s, %d in all%s" % [_kinds(), total,
				"" if dropped == 0 else " (%d more kinds came later and were not kept)" % dropped])
	for i in errors.size():
		var e: Dictionary = errors[i]
		out.append("%2d. %s ×%d: %s" % [i + 1, KINDS[int(e["kind"])], int(e["count"]), e["text"]])
		out.append("    at %s" % e["where"])
		out.append("    first %s%s [%s]" % [e["first"], "" if int(e["count"]) == 1 else ", last %s" % e["last"], e["context"]])
	out.append("last lines:")
	for l in trail:
		out.append("  " + l)
	if last_crashed:
		out.append("the session before this one closed by itself; its last lines:")
		for l in last_lines:
			out.append("  " + l)
	_lock.unlock()
	return "\n".join(out)


## One line for the log: how many errors so far.
func summary() -> String:
	return "%s of error, %d in all%s" % [_kinds(), total, ", the last session closed by itself" if last_crashed else ""]


func _kinds() -> String:
	return "1 kind" if errors.size() == 1 else "%d kinds" % errors.size()
