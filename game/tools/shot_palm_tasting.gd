extends SceneTree
## Screenshots of the tasting at the Palm (palm_tasting_ui.gd) on its own, no city: the livestream
## plays itself and frames are saved at set moments. Needs a renderer (not --headless).
##   godot --path game --resolution 2532x1170 --script res://tools/shot_palm_tasting.gd -- --out=DIR [--lang=en|pl]
##       [--at=a,b,c] [--perfect] [--cam] [--dish=bun|wrap|box|xxl]

const Ui := preload("res://scripts/palm_tasting_ui.gd")
const Tasting := preload("res://scripts/palm_tasting.gd")
const Lang := preload("res://scripts/lang.gd")

var view: Ui
var out := "user://palm_tasting"
var at: Array[float] = [0.9, 2.6, 3.6, 4.4, 4.9, 5.5, 6.2, 6.9, 8.3, 11.5, 13.0, 14.4, 15.4, 16.6, 17.0, 17.4, 17.8, 18.4, 19.8]
var perfect := false
var cam := false
## The dish in his hand: bun, wrap, box or xxl (--dish=).
var dish := "xxl"
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
		elif a == "--perfect":
			perfect = true
		elif a == "--cam":
			cam = true
		elif a.begins_with("--dish="):
			dish = a.trim_prefix("--dish=")
	DirAccess.make_dir_recursive_absolute(out)
	view = Ui.new()
	view.auto_play = true
	view.log_on = true
	root.add_child(view)
	var g := 11.0 if perfect else 9.4
	view.open.call_deferred({
		"hello": ["„Jest! Nie mów nic. Gryzę.”", "\"There it is! Don't say a thing. I'm biting.\""],
		"caption": ["…ALE DOBRY.", "…SO GOOD."],
		"verdict": [["„Buła taka nie za sucha. Chrupie jak śnieg w styczniu. Mięsa jest z sześćdziesiąt procent. Kemal, szanuję.”", "\"The bun's not too dry. Crunches like January snow. About sixty percent meat. Kemal, respect.\""],
			["„Warzywa? Jak z Berlina. No, prawie jak z Berlina. Prawie robi różnicę.”", "\"The veg? Like in Berlin. Well, almost like Berlin. Almost matters.\""]],
		"roast": ["„Jedenaście na dziesięć. Skala pękła. Wjeżdżam w to.”", "\"Eleven out of ten. The scale broke. I'm all in.\""] if perfect else ["„Parę dziesiątych zjadł korek na Jerozolimskich. Letni, ale uczciwy.”", "\"A few tenths went to the Jerozolimskie jam. Lukewarm, but honest.\""],
		"grade": g,
		"grade_label": "11 / 10" if perfect else "9,4 / 10",
		"cam": cam,
		"order": ["XXL · CZOSNKOWY", "XXL · GARLIC"],
		"dish": dish,
		"badge": ["ZŁOTY MLASK", "GOLDEN SMACK"] if perfect else [],
	})


func _process(dt: float) -> bool:
	_t += dt
	if _k < at.size() and _t >= at[_k]:
		var img := root.get_texture().get_image()
		var ph := "none" if view.tasting == null else str(Tasting.Phase.keys()[view.tasting.phase]).to_lower()
		var path := "%s/palm_%02d_%s.png" % [out, _k, ph]
		img.save_png(path)
		print("shot_palm_tasting: %s" % path)
		_k += 1
	if _k >= at.size() or (not view.inside and _t > 1.0):
		print("shot_palm_tasting: done (%d frames)" % _k)
		quit(0)
		return true
	return false
