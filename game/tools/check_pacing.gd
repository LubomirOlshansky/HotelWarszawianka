extends SceneTree
## The offer pacer's numbers (TD-3): game/data/pacing.json, the one place that says when each call
## may ring and each offer may come, read by scripts/pacer.gd. Checks that:
## - the file reads, and every source in it has its `_note`;
## - every number is sane: a time above 0; a range [low, high] with low above 0 and not above high;
##   hours [from, to] inside 0 to 24, not the same (they may run past midnight);
## - every `Pacer.num`, `span` or `pair` in game/scripts names a source and key the file has, and
##   each script's own name holds the file's value (so a tuned number reaches the game);
## - every number in the file is asked by a script (nothing unused); the tours ask by their ids.
## It does not pin today's numbers: tuning one is one edit of the file.
##   godot --headless --path game --script res://tools/check_pacing.gd

const Pacer := preload("res://scripts/pacer.gd")
const Activity := preload("res://scripts/activity.gd")
const Tour := preload("res://scripts/tour.gd")

const SCRIPTS := "res://scripts"
## A script's own name filled from the file.
const OWN := "static var ([A-Z_]+): [A-Za-z0-9]+ = Pacer\\.(num|span|pair)\\(\"([a-z_]+)\", \"([a-z_]+)\"\\)"
## Any ask with a written source and key.
const ASK := "Pacer\\.(num|span|pair)\\(\"([a-z_]+)\", \"([a-z_]+)\"\\)"

var _fails: Array[String] = []
var _numbers := 0
var _names := 0
## The scripts that ask the pacer.
var _files: Dictionary = {}


func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	var d: Dictionary = Pacer.data()
	if d.is_empty():
		print("check_pacing: FAIL %s does not load" % Pacer.PATH)
		quit(1)
		return
	_sane(d)
	_asks()
	_tours()
	_unused(d)
	for e: String in Pacer.errors:
		_fails.append("pacer: " + e)
	if _fails.is_empty():
		print("check_pacing: OK (%d sources, %d numbers, %d names in %d scripts take them)" % [_sources(d), _numbers, _names, _files.size()])
		quit(0)
	else:
		for f in _fails:
			print("check_pacing: FAIL " + f)
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _sources(d: Dictionary) -> int:
	var n := 0
	for s: String in d:
		if not s.begins_with("_"):
			n += 1
	return n


## Every source has a note; every number is a time, a range or hours that make sense.
func _sane(d: Dictionary) -> void:
	_expect(str(d.get("_about", "")) != "", "the file's `_about` is missing")
	for s: String in d:
		if s.begins_with("_"):
			continue
		var src: Variant = d[s]
		if typeof(src) != TYPE_DICTIONARY:
			_fails.append("%s is not an object" % s)
			continue
		_expect(str((src as Dictionary).get("_note", "")) != "", "%s has no `_note`" % s)
		for k: String in src:
			if k.begins_with("_"):
				continue
			_numbers += 1
			var v: Variant = src[k]
			var w := "%s.%s" % [s, k]
			if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
				_expect(float(v) > 0.0, w + " must be more than 0")
			elif typeof(v) == TYPE_ARRAY and (v as Array).size() == 2 and _all_numbers(v):
				var lo := float(v[0])
				var hi := float(v[1])
				if k == "hours" or k.ends_with("_hours"):
					_expect(lo >= 0.0 and lo <= 24.0 and hi >= 0.0 and hi <= 24.0 and lo != hi, w + " are not [from, to] hours in a day")
				else:
					_expect(lo > 0.0 and lo <= hi, w + " is not a range [low, high] above 0")
			else:
				_fails.append(w + " is neither a number nor a pair of numbers")


func _all_numbers(a: Array) -> bool:
	for x: Variant in a:
		if typeof(x) != TYPE_FLOAT and typeof(x) != TYPE_INT:
			return false
	return true


## The scripts that ask, read as text and loaded: every own name holds the file's value.
func _asks() -> void:
	var own := RegEx.create_from_string(OWN)
	var ask := RegEx.create_from_string(ASK)
	for f: String in DirAccess.get_files_at(SCRIPTS):
		if not f.ends_with(".gd") or f == "pacer.gd":
			continue
		var path := "%s/%s" % [SCRIPTS, f]
		var text := FileAccess.get_file_as_string(path)
		if ask.search(text) == null:
			continue
		_files[path] = true
		var script: GDScript = load(path)
		for m: RegExMatch in own.search_all(text):
			_names += 1
			var own_name := m.get_string(1)
			var file: Variant = _wanted(m.get_string(2), m.get_string(3), m.get_string(4))
			_expect(script.get(own_name) == file, "%s %s is %s, the file says %s" % [f, own_name, str(script.get(own_name)), str(file)])
		for m: RegExMatch in ask.search_all(text):
			_wanted(m.get_string(1), m.get_string(2), m.get_string(3))
	# The kit's defaults are fields, filled when an activity is made.
	var a: Activity = Activity.new()
	_expect(a.first_call == Pacer.num("activity", "first_call") and a.call_cool == Pacer.num("activity", "call_cool"), "activity.gd's first_call and call_cool are not the file's")
	_names += 2
	a.free()


func _wanted(fn: String, source: String, key: String) -> Variant:
	match fn:
		"num":
			return Pacer.num(source, key)
		"span":
			return Pacer.span(source, key)
		_:
			return Pacer.pair(source, key)


## Each tour (data/*_tour.json) asks by its id: the file has its hours and call times.
func _tours() -> void:
	for f: String in DirAccess.get_files_at("res://data"):
		if not f.ends_with("_tour.json"):
			continue
		var id := f.trim_suffix("_tour.json")
		var t: Tour = Tour.new()
		t.configure(Tour.load_data(id))
		_expect(t.hours == Pacer.span(id, "hours") and t.first_call == Pacer.num(id, "first_call") and t.call_cool == Pacer.num(id, "call_cool"), "the %s tour's call times are not the file's" % id)
		_names += 3
		_files["res://scripts/tour.gd"] = true
		t.free()


## Nothing in the file goes unasked.
func _unused(d: Dictionary) -> void:
	for s: String in d:
		if s.begins_with("_") or typeof(d[s]) != TYPE_DICTIONARY:
			continue
		for k: String in d[s]:
			if not k.begins_with("_"):
				_expect(Pacer.asked.has("%s.%s" % [s, k]), "%s.%s is in the file but no script asks for it" % [s, k])
