extends SceneTree
## Operation Unslop's barrier overrides (game/data/road_objects.json, tools/street_pass.py --apply):
## every id names a barrier line that exists in the map data (city_barriers.gd barrier_id, the same
## stable id the Python tools compute), every style is a placed barrier type of the palette
## (game/data/object_palette.json "types", city_barriers.gd is_style), every verdict a known one.
## Step 7: every `hard_lines` id (soft lines kept hard by hand) names a fence or hedge the bake
## classed S (`sc`), with a reason. W3: every `types` id (a line's type by id, tools/object_types.py
## fix_types) names a line that carries that type, a type with a looks row, with a reason. A stale id (the line moved more than its 2 m cell after a re-bake) fails here.
##   godot --headless --path game --script res://tools/check_object_overrides.gd

const CityBarriers := preload("res://scripts/city_barriers.gd")
const Solidity := preload("res://scripts/solidity.gd")
## HARD (step 7): a fence or hedge the bake classed S kept solid (city_barriers.gd _is_soft).
const VERDICTS := ["REMOVE", "RETEXTURE", "REPLACE", "SOFTEN", "KEEP", "HARD"]

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _init() -> void:
	var path := CityBarriers.OBJECT_OVERRIDES
	if not FileAccess.file_exists(path):
		print("check_object_overrides: OK (no overrides file)")
		quit(0)
		return
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(j is Dictionary and (j as Dictionary).get("items") is Dictionary, "road_objects.json has no items")
	var items: Dictionary = j["items"] if j is Dictionary else {}
	var map: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	_expect(map is Dictionary, "no map data (res://map/centrum.json)")
	var ids := {}
	if map is Dictionary:
		for l in (map as Dictionary).get("lines", []):
			if l["k"] != "platform":
				ids[CityBarriers.barrier_id(l["k"], l["p"])] = l
	var counts := {}
	for id: String in items:
		var o: Array = items[id]
		_expect(ids.has(id), "%s: no barrier with this id in the map" % id)
		_expect(str(o[0]) in VERDICTS, "%s: unknown verdict %s" % [id, o[0]])
		if str(o[0]) != "REMOVE" and str(o[0]) != "HARD":
			_expect(CityBarriers.is_style(str(o[1])), "%s: unknown style %s" % [id, o[1]])
		counts[str(o[1]) if o.size() > 1 and str(o[1]) != "" else str(o[0])] = int(counts.get(str(o[1]) if o.size() > 1 and str(o[1]) != "" else str(o[0]), 0)) + 1
	var hard: Dictionary = j.get("hard_lines", {}) if j is Dictionary else {}
	for id: String in hard:
		var l: Variant = ids.get(id)
		_expect(l is Dictionary, "hard_lines %s: no barrier with this id in the map" % id)
		if l is Dictionary:
			_expect(str(l["k"]) in ["fence", "hedge"] and str(l.get("sc", "")) == "S",
					"hard_lines %s: not an S fence or hedge (k %s, sc %s): nothing to keep hard" % [id, l["k"], l.get("sc", "")])
		_expect(str(hard[id]).length() > 10, "hard_lines %s: no reason" % id)
	# W3: every `types` id names one barrier line that carries that type (tools/object_types.py
	# fix_types wrote it), the type has a looks row, and there is a reason.
	var types: Dictionary = j.get("types", {}) if j is Dictionary else {}
	for id: String in types:
		var t: Array = types[id]
		var l2: Variant = ids.get(id)
		_expect(l2 is Dictionary, "types %s: no barrier with this id in the map" % id)
		_expect(not Solidity.look_row(StringName(str(t[0]))).is_empty(), "types %s: %s has no looks row" % [id, t[0]])
		if l2 is Dictionary:
			_expect(str(l2.get("ty", "")) == str(t[0]), "types %s: the map's line is %s, not %s (run tools/object_types.py apply)" % [id, l2.get("ty", ""), t[0]])
		_expect(t.size() > 1 and str(t[1]).length() > 10, "types %s: no reason" % id)
	print("check_object_overrides counts: %d overrides %s, %d hard lines, %d types" % [items.size(), counts, hard.size(), types.size()])
	if _problems > 0:
		print("check_object_overrides: FAIL (%d problems)" % _problems)
		quit(1)
		return
	print("check_object_overrides: OK")
	quit(0)
