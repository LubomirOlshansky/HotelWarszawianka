extends SceneTree
## Zebra crossings drawn full width (2026-11-26). The bake gives every OSM crossing the footway
## default width (bake_osm.py PATHS, 2.2 m); only road design's zebras carry their real width
## (4-10 m). From #474 to 2026-11-26 map_builder.gd `_zebra_bar` read the default as the crossing's
## width and drew 2,021 of 2,117 zebras with 2.0 m bars. Checks, map-free and on centrum.json:
## - `_zebra_bar` is never under TACTILE_WIDE (3.6 m): no `w`, the footway default, a path's 2.0;
## - a designed width keeps its bars 0.4 m short of it (8 m gives 7.6 m);
## - every zebra on the committed map draws bars of at least TACTILE_WIDE.
## Prints `check_zebras: OK` and exits 0, else the problems and exit 1.
##   godot --headless --path game --script res://tools/check_zebras.gd

const MapBuilder := preload("res://scripts/map_builder.gd")
const MAP_PATH := "res://map/centrum.json"

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	var wide: float = MapBuilder.TACTILE_WIDE
	_expect(is_equal_approx(MapBuilder._zebra_bar({"k": "zebra"}), wide), "no w gives %.1f m" % wide)
	_expect(is_equal_approx(MapBuilder._zebra_bar({"k": "zebra", "w": 2.2}), wide), "the footway default gives %.1f m" % wide)
	_expect(is_equal_approx(MapBuilder._zebra_bar({"k": "zebra", "w": 2.0}), wide), "a path's 2.0 m gives %.1f m" % wide)
	_expect(is_equal_approx(MapBuilder._zebra_bar({"k": "zebra", "w": 8.0}), 7.6), "a designed 8 m zebra gives 7.6 m")
	var zebras := 0
	var narrow := 0
	var text := FileAccess.get_file_as_string(MAP_PATH)
	var data = JSON.parse_string(text) if text != "" else null
	if data is Dictionary:
		for p in data.get("paths", []):
			if str(p.get("k", "")) != "zebra":
				continue
			zebras += 1
			if MapBuilder._zebra_bar(p) < wide - 0.001:
				narrow += 1
		_expect(zebras > 0, "the map has zebras")
		_expect(narrow == 0, "%d of %d zebras on the map draw bars under %.1f m" % [narrow, zebras, wide])
	else:
		_expect(false, "%s parses" % MAP_PATH)
	print("check_zebras: %d zebras on the map" % zebras)
	if _problems == 0:
		print("check_zebras: OK")
	quit(0 if _problems == 0 else 1)
