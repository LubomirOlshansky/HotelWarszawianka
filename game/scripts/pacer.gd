## The offer pacer (TD-3): every number that says when a call may ring or an offer may come lives
## in one file, `data/pacing.json`, the place F tunes the first hour. Each source keeps its own
## countdown and its own names, filled from the file when its script loads
## (`static var FIRST_CALL: Vector2 = Pacer.span("shisha", "first_call")`), so its code and the
## checks that read `Shisha.FIRST_CALL` are as they were, and the random draws are the same calls.
## A source or key the file lacks is an error (`errors`, `check_pacing`), never a silent default.
##
## Its rules (TD-3 b, F 2026-11-15) live where the calls are decided: one offer at a time and
## variety (whoever rang last lets a waiting call go first) are the director's (`activities.gd`
## `may_start`, `my_turn`), the quiet time after a finish (`calls.quiet`) the message director's
## (`messages.gd` `call_ok`, `quiet`).
extends RefCounted

const PATH := "res://data/pacing.json"

## Every source and key asked so far, "source.key" (check_pacing: nothing in the file is unused).
static var asked: Dictionary = {}
## What went wrong reading the file or answering (check_pacing fails on any).
static var errors: PackedStringArray = []
static var _data: Dictionary = {}
static var _loaded := false


## The whole file (read once).
static func data() -> Dictionary:
	if not _loaded:
		_loaded = true
		_data = _read(PATH)
	return _data


## A number: seconds, or a rest.
static func num(source: String, key: String) -> float:
	var v: Variant = _value(source, key)
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		_fail("%s.%s is not a number" % [source, key])
		return 0.0
	return float(v)


## A [low, high] pair as a Vector2: a random time between, or hours from and to.
static func span(source: String, key: String) -> Vector2:
	var p := pair(source, key)
	return Vector2(float(p[0]), float(p[1]))


## A [low, high] pair as an Array of two floats, for the scripts that keep their hours as an Array.
static func pair(source: String, key: String) -> Array:
	var v: Variant = _value(source, key)
	if typeof(v) != TYPE_ARRAY or (v as Array).size() != 2:
		_fail("%s.%s is not a pair [low, high]" % [source, key])
		return [0.0, 0.0]
	var a: Array = v
	return [float(a[0]), float(a[1])]


## Reads a pacing file into a Dictionary; {} and an error when it is missing or broken.
static func _read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_fail("%s cannot be read" % path)
		return {}
	var v: Variant = JSON.parse_string(f.get_as_text())
	if typeof(v) != TYPE_DICTIONARY:
		_fail("%s is not a JSON object" % path)
		return {}
	return v


static func _value(source: String, key: String) -> Variant:
	asked["%s.%s" % [source, key]] = true
	var s: Variant = data().get(source)
	if typeof(s) != TYPE_DICTIONARY or not (s as Dictionary).has(key):
		_fail("%s has no %s.%s" % [PATH, source, key])
		return null
	return (s as Dictionary)[key]


static func _fail(what: String) -> void:
	errors.append(what)
	push_error("pacer: " + what)
