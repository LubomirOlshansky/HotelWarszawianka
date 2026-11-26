extends SceneTree
## Screenshots of SZYBA, the payoff at Kemal's window (kemal_window_ui.gd) on its own, no city: it
## plays itself and frames are saved at set moments. Needs a renderer (not --headless).
##   godot --path game --resolution 2532x1170 --script res://tools/shot_kemal_window.gd -- --out=DIR
##       [--lang=en|pl] [--at=a,b,c] [--lost] [--bribe] [--cam]
## --lost: Kebabulo won the race (his hand slaps it, the high five); --bribe: the bribe was taken
## (the leak line, SPRZEDAWCZYK); --cam: the camera's badge.

const Ui := preload("res://scripts/kemal_window_ui.gd")
const Win := preload("res://scripts/kemal_window.gd")
const Lang := preload("res://scripts/lang.gd")

var view: Ui
var out := "user://kemal_window"
var at: Array[float] = [0.3, 0.9, 1.6, 1.75, 1.95, 2.3, 2.8, 3.4, 4.0, 4.8, 5.6, 6.4, 7.6]
var lost := false
var bribe := false
var cam := false
var _t := 0.0
var _k := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--lang="):
			Lang.set_code(a.trim_prefix("--lang="))
		elif a.begins_with("--at="):
			at.clear()
			for s in a.trim_prefix("--at=").split(","):
				at.append(float(s))
		elif a == "--lost":
			lost = true
		elif a == "--bribe":
			bribe = true
		elif a == "--cam":
			cam = true
	DirAccess.make_dir_recursive_absolute(out)
	var words: Dictionary = {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	if d is Dictionary:
		for l: Variant in (d as Dictionary).get("tajny_klient", []):
			if l is Array and (l as Array).size() >= 3:
				words[str((l[2] as Dictionary).get("only", ""))] = [str(l[0]), str(l[1])]
	var badges: Array = []
	if not lost and not cam and not bribe:
		badges.append(words.get("badge_gold", ["", ""]))
	if cam:
		badges.append(words.get("badge_cam", ["", ""]))
	if bribe:
		badges.append(words.get("badge_sold", ["", ""]))
	view = Ui.new()
	view.auto_play = true
	view.log_on = true
	root.add_child(view)
	view.open.call_deferred({
		"won": not lost,
		"line": words.get("race_lost" if lost else "race_won", ["", ""]),
		"cry": words.get("kemal_cry", ["", ""]),
		"title": words.get("result_title", ["PARAGON", "THE RECEIPT"]),
		"order": ["XXL · CZOSNKOWY", "XXL · GARLIC"],
		"grade": "9,4 / 10",
		"pay": 120,
		"respect": 30,
		"badges": badges,
		"leak": words.get("leak", []) if bribe else [],
	})


func _process(dt: float) -> bool:
	_t += dt
	if _k < at.size() and _t >= at[_k]:
		var img := root.get_texture().get_image()
		var ph := "none" if view.win == null else str(Win.Phase.keys()[view.win.phase]).to_lower()
		var path := "%s/szyba_%02d_%s.png" % [out, _k, ph]
		img.save_png(path)
		print("shot_kemal_window: %s" % path)
		_k += 1
	if _k >= at.size() or (not view.inside and _t > 1.0):
		print("shot_kemal_window: done (%d frames)" % _k)
		quit(0)
		return true
	return false
