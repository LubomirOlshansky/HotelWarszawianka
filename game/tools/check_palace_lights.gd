extends SceneTree
## The Palace of Culture's event lighting (palace_lights.gd, data/palace_lights.json, F 2026-11-07):
## every row parses (a known pattern, two colours, a date range or nth weekday), the calendar picks
## the right row on known dates (11 November white over red, 31 October Halloween over Pink October,
## New Year across the year's end, the parade on the third Saturday of June 2027, gold on an
## ordinary night), a night after midnight still belongs to the evening's date, and the shader
## has the uniforms main.gd sets. Prints `check_palace_lights: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_palace_lights.gd

const Lights := preload("res://scripts/palace_lights.gd")


func _init() -> void:
	var bad: Array[String] = []
	for e: Dictionary in Lights.events():
		var id := str(e.get("id", "?"))
		if not Lights.MODES.has(str(e.get("pattern", ""))):
			bad.append("%s: unknown pattern %s" % [id, e.get("pattern")])
		for k: String in ["a", "b"]:
			if not Color.html_is_valid(str(e.get(k, ""))):
				bad.append("%s: colour %s is not a colour" % [id, k])
		if not e.has("nth_weekday") and (str(e.get("from", "")).length() != 5 or str(e.get("to", "")).length() != 5):
			bad.append("%s: no MM-DD range" % id)
	if Lights.events().size() < 10:
		bad.append("only %d events" % Lights.events().size())
	var want := {
		[2026, 11, 11]: "independence", [2026, 10, 31]: "halloween", [2026, 10, 12]: "pink_october",
		[2026, 12, 31]: "new_year", [2027, 1, 1]: "new_year", [2027, 6, 19]: "parade", [2027, 6, 12]: "",
		[2026, 7, 10]: "", [2026, 8, 1]: "uprising", [2026, 12, 24]: "christmas",
	}
	for d: Array in want:
		var got := str(Lights.for_date(int(d[0]), int(d[1]), int(d[2])).get("id", ""))
		if got != str(want[d]):
			bad.append("%d-%02d-%02d: %s, want %s" % [d[0], d[1], d[2], got if got != "" else "gold", want[d] if want[d] != "" else "gold"])
	var late: Array = Lights.night_of({"year": 2026, "month": 11, "day": 12, "hour": 2, "minute": 30, "second": 0})
	if late != [2026, 11, 11]:
		bad.append("02:30 on 12 November belongs to %s, want 2026-11-11" % [late])
	var src := FileAccess.get_file_as_string("res://shaders/building.gdshader")
	for u: String in ["flood_mode", "flood_a", "flood_b", "flood_cycle"]:
		if not ("uniform" in src and src.contains(u)):
			bad.append("building.gdshader has no %s" % u)
	print("palace lights: %d events" % Lights.events().size())
	if bad.is_empty():
		print("check_palace_lights: OK")
		quit(0)
	else:
		for b in bad:
			print("  " + b)
		print("check_palace_lights: FAIL")
		quit(1)
