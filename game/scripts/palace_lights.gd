class_name PalaceLights
extends RefCounted
## The Palace of Culture's night lighting by date (F, 2026-11-07, with photos of the real
## event colours: purple, rainbow, green, orange, white over red, the New Year's rainbow).
## One table, data/palace_lights.json: an event per row (a date range or the nth weekday of a
## month, a pattern, two colours); the shortest matching event wins, no match is the nightly
## gold. main.gd feeds the choice to building.gdshader's floodlight (flood_mode, flood_a,
## flood_b, flood_cycle) when the Palace's clock ticks and the night changes; --palace-lights=ID
## forces a row (shots). The clock dials and the gilt spire keep their own gold (not stone).

const FILE := "res://data/palace_lights.json"
## The shader's floodlight modes.
const MODES := {"gold": 0, "solid": 1, "split_height": 2, "rainbow": 3}
## A night belongs to the date it began: until 06:00 the lights keep the evening's colours.
const NIGHT_ENDS := 6

static var _events: Array = []


## The table's events (read once).
static func events() -> Array:
	if _events.is_empty() and FileAccess.file_exists(FILE):
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		if j is Dictionary:
			_events = (j as Dictionary).get("events", [])
	return _events


## The event lighting the night that began on y-m-d: the row, or {} for the nightly gold.
static func for_date(y: int, m: int, d: int) -> Dictionary:
	var best: Dictionary = {}
	var span := 1000
	for e: Dictionary in events():
		var n := _span_if_match(e, y, m, d)
		if n >= 0 and n < span:
			best = e
			span = n
	return best


## The event with this id, or {} (--palace-lights=ID).
static func by_id(id: String) -> Dictionary:
	for e: Dictionary in events():
		if str(e.get("id", "")) == id:
			return e
	return {}


## The date (y, m, d) whose night it is at Warsaw time `local` (a datetime dict).
static func night_of(local: Dictionary) -> Array:
	var t := Time.get_unix_time_from_datetime_dict(local)
	if int(local["hour"]) < NIGHT_ENDS:
		t -= 86400
	var d := Time.get_datetime_dict_from_unix_time(t)
	return [int(d["year"]), int(d["month"]), int(d["day"])]


## The shader's parameters for an event row ({} is the gold): mode, colour a, colour b, cycle.
static func params(e: Dictionary) -> Dictionary:
	var mode: int = MODES.get(str(e.get("pattern", "gold")), 0)
	return {"mode": mode, "a": Color(str(e.get("a", "#ffb34d"))), "b": Color(str(e.get("b", "#ffb34d"))),
			"cycle": float(e.get("cycle", 0.0))}


## Puts an event's lighting on the building material.
static func apply(mat: ShaderMaterial, e: Dictionary) -> void:
	if mat == null:
		return
	var p := params(e)
	mat.set_shader_parameter("flood_mode", int(p["mode"]))
	mat.set_shader_parameter("flood_a", p["a"])
	mat.set_shader_parameter("flood_b", p["b"])
	mat.set_shader_parameter("flood_cycle", float(p["cycle"]))


## The days an event spans if y-m-d falls in it, else -1.
static func _span_if_match(e: Dictionary, y: int, m: int, d: int) -> int:
	if e.has("nth_weekday"):
		var nw: Array = e["nth_weekday"]
		if int(nw[0]) != m:
			return -1
		return 0 if d == _nth_weekday(y, int(nw[0]), int(nw[1]), int(nw[2])) else -1
	var f: PackedStringArray = str(e.get("from", "")).split("-")
	var t: PackedStringArray = str(e.get("to", "")).split("-")
	if f.size() != 2 or t.size() != 2:
		return -1
	var a := int(f[0]) * 100 + int(f[1])
	var b := int(t[0]) * 100 + int(t[1])
	var x := m * 100 + d
	if a <= b:
		return (_day_of_year(b) - _day_of_year(a)) if x >= a and x <= b else -1
	# Wraps past New Year (12-31 to 01-01).
	return (_day_of_year(b) + 365 - _day_of_year(a)) if x >= a or x <= b else -1


## Day of a (non-leap) year for MMDD, for spans only.
static func _day_of_year(mmdd: int) -> int:
	var before := [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
	return int(before[clampi(mmdd / 100, 1, 12) - 1]) + mmdd % 100


## The day of month of the nth `weekday` (0 Sunday .. 6 Saturday) of y-m.
static func _nth_weekday(y: int, m: int, weekday: int, n: int) -> int:
	var first := Time.get_datetime_dict_from_unix_time(
			Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": 1, "hour": 12, "minute": 0, "second": 0}))
	var w := int(first["weekday"])
	return 1 + (weekday - w + 7) % 7 + 7 * (n - 1)
