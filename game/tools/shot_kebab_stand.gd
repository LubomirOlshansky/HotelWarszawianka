extends SceneTree
## Screenshots of the 2D kebab stand (kebab_stand_ui.gd) on its own, no city: the order plays itself
## and frames are saved at set moments. Needs a renderer (not --headless).
##   godot --path game --resolution 2532x1170 --script res://tools/shot_kebab_stand.gd -- --out=DIR [--lang=en|pl]
##       [--at=a,b,c] [--cam] [--pour=good|dry|jacket] [--sauce=0|1|2] [--dish=0..3]
## --cam orders for the mate with the camera; --pour holds the finger to a verdict (good: auto).

const StandUi := preload("res://scripts/kebab_stand_ui.gd")
const Stand := preload("res://scripts/kebab_stand.gd")
const Lang := preload("res://scripts/lang.gd")

var view: StandUi
var out := "user://kebab_stand"
var at: Array[float] = [0.3, 1.6, 4.0, 6.5, 9.0, 11.0, 12.4, 14.0, 15.5]
var cam := false
var pour := "good"
var sauce := 0
var dish := 0
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
		elif a == "--cam":
			cam = true
		elif a.begins_with("--pour="):
			pour = a.trim_prefix("--pour=")
		elif a.begins_with("--sauce="):
			sauce = int(a.trim_prefix("--sauce="))
		elif a.begins_with("--dish="):
			dish = int(a.trim_prefix("--dish="))
	DirAccess.make_dir_recursive_absolute(out)
	view = StandUi.new()
	view.auto_play = true
	view.log_on = true
	view.zl = 50
	root.add_child(view)
	view.open.call_deferred("kemal", true)


func _process(_dt: float) -> bool:
	var dt := 1.0 / 60.0
	_t += dt
	var s: Stand = view.stand
	if s != null:
		# the scripted thumb: its own picks a breath before the autopilot's, its own pour
		if s.t >= 0.6:
			match s.phase:
				Stand.Phase.DISH:
					s.pick(dish)
				Stand.Phase.SAUCE:
					s.pick(sauce)
				Stand.Phase.WHO:
					s.pick(1 if cam else 0)
		if s.phase == Stand.Phase.POUR and pour != "good":
			s.auto_play = false
			var stop := 0.3 if pour == "dry" else 9.0
			view._finger = s.pour == "" and s.t > 0.4 and s.level < stop
	if _k < at.size() and _t >= at[_k]:
		var img := root.get_texture().get_image()
		var path := "%s/stand_%02d_%s.png" % [out, _k, _phase_name()]
		img.save_png(path)
		print("shot_kebab_stand: %s" % path)
		_k += 1
	if _k >= at.size() or (not view.inside and _t > 1.0):
		print("shot_kebab_stand: done (%d frames)" % _k)
		quit(0)
		return true
	return false


func _phase_name() -> String:
	if view.stand == null:
		return "none"
	return str(Stand.Phase.keys()[view.stand.phase]).to_lower()
