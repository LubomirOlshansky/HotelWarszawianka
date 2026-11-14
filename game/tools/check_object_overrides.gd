extends SceneTree
## Operation Unslop's barrier overrides (game/data/road_objects.json, tools/street_pass.py --apply):
## every id names a barrier line that exists in the map data (city_barriers.gd barrier_id, the same
## stable id the Python tools compute), every style is a placed barrier type of the palette
## (game/data/object_palette.json "types", city_barriers.gd is_style), every verdict a known one. A stale id (the line moved more than its 2 m cell after a re-bake) fails here.
##   godot --headless --path game --script res://tools/check_object_overrides.gd

const CityBarriers := preload("res://scripts/city_barriers.gd")
const VERDICTS := ["REMOVE", "RETEXTURE", "REPLACE", "SOFTEN", "KEEP"]

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
				ids[CityBarriers.barrier_id(l["k"], l["p"])] = true
	var counts := {}
	for id: String in items:
		var o: Array = items[id]
		_expect(ids.has(id), "%s: no barrier with this id in the map" % id)
		_expect(str(o[0]) in VERDICTS, "%s: unknown verdict %s" % [id, o[0]])
		if str(o[0]) != "REMOVE":
			_expect(CityBarriers.is_style(str(o[1])), "%s: unknown style %s" % [id, o[1]])
		counts[str(o[1]) if o.size() > 1 and str(o[1]) != "" else str(o[0])] = int(counts.get(str(o[1]) if o.size() > 1 and str(o[1]) != "" else str(o[0]), 0)) + 1
	print("check_object_overrides counts: %d overrides %s" % [items.size(), counts])
	if _problems > 0:
		print("check_object_overrides: FAIL (%d problems)" % _problems)
		quit(1)
		return
	print("check_object_overrides: OK")
	quit(0)
