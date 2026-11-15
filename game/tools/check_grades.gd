extends SceneTree
## The colour looks (scripts/grades.gd, F 2026-11-15) against time_of_day.gd's base looks:
##   - Settings' three looks (SETTING) and every name in NAMES resolve to day, dusk and night;
##   - a look overrides only keys the base looks or the neutral grade have, with the same type
##     (a mistyped key would be merged in and never read; a wrong type breaks the blend);
##   - "classic" overrides nothing and its grade values are the neutral ones (the picture before
##     2026-11-15, exactly); unknown names fall back to it;
##   - "warsaw" is Natural by day and night with Golden's dusk;
##   - the values stay in the range the post pass was tuned for (contrast 0.8..1.4, the pivot
##     above 0, lift under 0.06, the shoulder 0..1, glow at most 1: Low has no glow at all).
## Prints `check_grades: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_grades.gd

const TimeOfDay := preload("res://scripts/time_of_day.gd")


func _initialize() -> void:
	var problems: Array[String] = []
	var base: Array = TimeOfDay.LOOKS
	for name: String in Grades.SETTING:
		if name not in Grades.NAMES:
			problems.append("SETTING's %s is not in NAMES" % name)
	for name: String in Grades.NAMES:
		var over: Array = Grades.looks_of(name)
		if name != "warsaw" and not Grades.LOOKS.has(name):
			problems.append("%s has no entry in LOOKS" % name)
			continue
		if over.size() != 3:
			problems.append("%s has %d looks, not day, dusk and night" % [name, over.size()])
			continue
		var looks: Array = Grades.apply(base, name)
		for i in 3:
			for key: String in over[i]:
				var ref = base[i].get(key, Grades.NEUTRAL.get(key))
				if ref == null:
					problems.append("%s[%d] overrides '%s', which no look has" % [name, i, key])
				elif typeof(ref) != typeof(over[i][key]):
					problems.append("%s[%d] '%s' is not the base's type" % [name, i, key])
			var look: Dictionary = looks[i]
			if look.size() != base[i].size() + Grades.NEUTRAL.size():
				problems.append("%s[%d] has %d keys, the base and the grade have %d" % [name, i, look.size(), base[i].size() + Grades.NEUTRAL.size()])
			var lift: Vector3 = look["g_lift"]
			if look["g_contrast"] < 0.8 or look["g_contrast"] > 1.4 or look["g_pivot"] <= 0.0 \
					or maxf(lift.x, maxf(lift.y, lift.z)) > 0.06 or look["g_shoulder"] < 0.0 or look["g_shoulder"] > 1.0 \
					or look["glow"] > 1.0:
				problems.append("%s[%d] has a grade value out of range" % [name, i])
	for i in 3:
		var classic: Dictionary = Grades.apply(base, "classic")[i]
		var unknown: Dictionary = Grades.apply(base, "no such look")[i]
		for key: String in base[i]:
			if classic[key] != base[i][key] or unknown[key] != base[i][key]:
				problems.append("classic[%d] changes '%s'" % [i, key])
		for key: String in Grades.NEUTRAL:
			if classic[key] != Grades.NEUTRAL[key]:
				problems.append("classic[%d] grades the image ('%s')" % [i, key])
	if Grades.looks_of("warsaw") != [Grades.LOOKS["natural"][0], Grades.LOOKS["golden"][1], Grades.LOOKS["natural"][2]]:
		problems.append("warsaw is not Natural with Golden's dusk")
	if Grades.SETTING[0] != "warsaw":
		problems.append("the default look (SETTING[0]) is %s, not warsaw" % Grades.SETTING[0])
	for p in problems:
		printerr("check_grades: %s" % p)
	if problems.is_empty():
		print("check_grades: OK (%d looks, Settings offers %s)" % [Grades.NAMES.size(), ", ".join(Grades.SETTING)])
	quit(0 if problems.is_empty() else 1)
