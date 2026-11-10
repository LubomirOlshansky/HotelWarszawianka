extends SceneTree
## Screenshots of the arcade padel match (padel_match.gd) on its own, no city: the match plays
## itself and frames are saved at set moments. Needs a renderer (not --headless).
##   godot --path game --resolution 2532x1170 --script res://tools/shot_padel.gd -- --out=DIR [--hour=H] [--lang=en|pl] [--at=a,b,c]

const PadelMatch := preload("res://scripts/padel_match.gd")
const Lang := preload("res://scripts/lang.gd")

var match_node: PadelMatch
var out := "user://padel"
var at: Array[float] = [2.0, 9.0, 16.0, 24.0, 33.0]
var hour := 12.0
var _t := 0.0
var _k := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--lang="):
			Lang.set_code(a.trim_prefix("--lang="))
		elif a.begins_with("--hour="):
			hour = float(a.trim_prefix("--hour="))
		elif a.begins_with("--at="):
			at.clear()
			for s in a.trim_prefix("--at=").split(","):
				at.append(float(s))
	DirAccess.make_dir_recursive_absolute(out)
	match_node = PadelMatch.new()
	match_node.auto_play = true
	match_node.log_on = true
	root.add_child(match_node)
	match_node.enter.call_deferred({"partner": "Kuba", "rivals": ["Prezes", "Zbyszek"], "hour": hour, "seed": 3})


func _process(dt: float) -> bool:
	_t += 1.0 / 60.0
	if _k < at.size() and _t >= at[_k]:
		var img := root.get_texture().get_image()
		var p := "%s/padel_h%02d_%02d.png" % [out, int(hour), _k]
		img.save_png(p)
		print("shot: " + p)
		_k += 1
	return _k >= at.size() or (_t > 1.0 and not match_node.inside)
