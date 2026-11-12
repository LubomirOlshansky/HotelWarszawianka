extends SceneTree
## Checks the sound mixer (sfx.gd DUCKS, TD-5): every row is well formed; ducks stack (the
## deepest one held counts, and releasing one never undoes another: the old `radio.duck_db` was
## one number three scripts wrote); fades take their row's time; timed ducks end by themselves;
## the radio's level follows the mixer; the buses exist with the limiter on Master; and no
## script but sfx.gd and radio.gd sets a level of the radio or a bus.
##   godot --headless --path game --script res://tools/check_mixer.gd

const Sfx := preload("res://scripts/sfx.gd")
const Radio := preload("res://scripts/radio.gd")
## What a gameplay script must not touch (docs/architecture/extending.md, "A sound").
const FORBIDDEN := ["duck_db", "bed_db", "set_bus_volume_db", "set_bus_mute", "AudioServer.add_bus"]
const OWNERS := ["sfx.gd", "radio.gd"]

var problems: Array[String] = []


func _initialize() -> void:
	_rows()
	_stacking()
	_fades()
	_timed()
	_buses()
	_sources("res://scripts")
	await _radio()
	for p in problems:
		print("  PROBLEM: " + p)
	print("mixer: %d ducks, %s" % [Sfx.DUCKS.size(), "OK" if problems.is_empty() else "PROBLEM"])
	quit(0 if problems.is_empty() else 1)


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.01


func _rows() -> void:
	for name: String in Sfx.DUCKS:
		var row: Array = Sfx.DUCKS[name]
		if row.size() != 4 or not (row[0] is String):
			problems.append("row %s is not [target, dB, down s, up s]" % name)
			continue
		if row[0] != "radio" and not Sfx.BUSES.has(row[0]):
			problems.append("row %s turns down \"%s\": not the radio and not a bus" % [name, row[0]])
		if float(row[1]) >= 0.0 or float(row[2]) < 0.0 or float(row[3]) < 0.0:
			problems.append("row %s: %s dB, %s s, %s s (want under 0 dB, times not negative)" % [name, row[1], row[2], row[3]])


## The pull-over inside the club, in both orders: the radio stays off until the club lets go.
func _stacking() -> void:
	Sfx.mix_reset()
	Sfx.duck("club")
	Sfx.duck("police_talk")
	var both := Sfx.mix_db("radio")
	Sfx.release("police_talk")
	var club := Sfx.mix_db("radio")
	Sfx.release("club")
	var none := Sfx.mix_db("radio")
	if not _near(both, -60.0) or not _near(club, -60.0) or not _near(none, 0.0):
		problems.append("club then police: %.1f, after the talk %.1f, after the club %.1f (want -60, -60, 0)" % [both, club, none])
	Sfx.duck("police_talk")
	var talk := Sfx.mix_db("radio")
	Sfx.duck("club")
	Sfx.release("club")
	var back := Sfx.mix_db("radio")
	Sfx.release("police_talk")
	Sfx.release("police_talk")
	if not _near(talk, -6.0) or not _near(back, -6.0) or not _near(Sfx.mix_db("radio"), 0.0) or Sfx.ducked("police_talk"):
		problems.append("police then club: %.1f, after the club %.1f, after all %.1f (want -6, -6, 0)" % [talk, back, Sfx.mix_db("radio")])
	# A duck on the radio leaves the buses alone, and the other way round.
	Sfx.duck("radio_on")
	Sfx.mix_step(5.0)
	if not _near(Sfx.mix_db("Ambience"), -4.0) or not _near(Sfx.mix_db("radio"), 0.0):
		problems.append("radio_on: Ambience %.1f, radio %.1f (want -4, 0)" % [Sfx.mix_db("Ambience"), Sfx.mix_db("radio")])
	Sfx.mix_reset()
	if Sfx.ducked("radio_on") or not _near(Sfx.mix_db("Ambience"), 0.0):
		problems.append("mix_reset left a duck behind")


## The greeting: half way down after half its time, down, then back over its swell; a shallower
## duck asked meanwhile changes nothing, and a deeper one that ends hands back to the greeting.
func _fades() -> void:
	Sfx.mix_reset()
	var row: Array = Sfx.DUCKS["greeting"]
	var deep := float(row[1])
	Sfx.duck("greeting")
	Sfx.mix_step(float(row[2]) * 0.5)
	var half := Sfx.mix_db("radio")
	Sfx.mix_step(float(row[2]))
	var down := Sfx.mix_db("radio")
	Sfx.duck("police_talk")
	Sfx.mix_step(1.0)
	Sfx.release("police_talk")
	Sfx.mix_step(1.0)
	var held := Sfx.mix_db("radio")
	Sfx.release("greeting")
	Sfx.mix_step(float(row[3]) * 0.5)
	var rising := Sfx.mix_db("radio")
	Sfx.mix_step(float(row[3]))
	if not _near(half, deep * 0.5) or not _near(down, deep) or not _near(held, deep) or not _near(rising, deep * 0.5) or not _near(Sfx.mix_db("radio"), 0.0):
		problems.append("greeting fade: half %.1f, down %.1f, under a talk %.1f, rising %.1f, end %.1f (want %.1f, %.1f, %.1f, %.1f, 0)" % [
				half, down, held, rising, Sfx.mix_db("radio"), deep * 0.5, deep, deep, deep * 0.5])
	Sfx.mix_reset()


## The host's moment: down for its seconds, then up by itself; asking again makes it last longer.
func _timed() -> void:
	Sfx.mix_reset()
	Sfx.duck("host_moment", 10.0)
	Sfx.mix_step(9.5)
	var during := Sfx.mix_db("radio")
	Sfx.duck("host_moment", 4.0)
	Sfx.mix_step(3.0)
	var longer := Sfx.ducked("host_moment")
	Sfx.mix_step(1.5)
	var want := float(Sfx.DUCKS["host_moment"][1])
	if not _near(during, want) or not longer or Sfx.ducked("host_moment") or not _near(Sfx.mix_db("radio"), 0.0):
		problems.append("host_moment: during %.1f (want %.1f), held after asking again %s, at the end held %s, %.1f dB" % [
				during, want, longer, Sfx.ducked("host_moment"), Sfx.mix_db("radio")])
	Sfx.mix_reset()


func _buses() -> void:
	Sfx.setup_buses()
	Sfx.setup_buses()
	for bus: String in Sfx.BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			problems.append("no %s bus after setup_buses" % bus)
	var limiters := 0
	for i in AudioServer.get_bus_effect_count(0):
		var fx := AudioServer.get_bus_effect(0, i)
		if fx is AudioEffectHardLimiter and _near((fx as AudioEffectHardLimiter).ceiling_db, Sfx.LIMIT_DB):
			limiters += 1
	if limiters != 1:
		problems.append("%d limiters on Master after two setup_buses (want 1 at %.1f dB)" % [limiters, Sfx.LIMIT_DB])
	# The spoken clips follow the effects slider, as they did on the SFX bus.
	Sfx.set_levels(1.0, 1.0, 0.5)
	var voice := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Voice"))
	var want: float = Sfx.BUSES["Voice"] + linear_to_db(0.5)
	if not _near(voice, want):
		problems.append("Voice bus at %.1f dB with effects at half (want %.1f)" % [voice, want])
	Sfx.set_levels(1.0, 1.0, 1.0)


## The radio's own level: the station's, less what the mixer holds.
func _radio() -> void:
	Sfx.mix_reset()
	var radio := Radio.new()
	root.add_child(radio)
	await process_frame
	radio.picked = true
	radio.tune(radio.station_index(Radio.DAY_DEFAULT), true)
	var plain := radio.level_db()
	Sfx.duck("police_talk")
	await process_frame
	await process_frame
	var talk := radio.level_db()
	Sfx.release("police_talk")
	await process_frame
	await process_frame
	if not _near(plain, Radio.VOLUME_DB) or not _near(talk, Radio.VOLUME_DB - 6.0) or not _near(radio.level_db(), Radio.VOLUME_DB):
		problems.append("radio level: %.1f, in a talk %.1f, after %.1f (want %.1f, %.1f, %.1f)" % [
				plain, talk, radio.level_db(), Radio.VOLUME_DB, Radio.VOLUME_DB - 6.0, Radio.VOLUME_DB])
	radio.queue_free()
	await process_frame
	Sfx.mix_reset()


## No script but the owners writes a level of the radio or a bus.
func _sources(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		problems.append("can't list %s" % dir_path)
		return
	for d in dir.get_directories():
		_sources(dir_path + "/" + d)
	for f in dir.get_files():
		if not f.ends_with(".gd") or f in OWNERS:
			continue
		var n := 0
		for line in FileAccess.get_file_as_string(dir_path + "/" + f).split("\n"):
			n += 1
			var code := line.strip_edges()
			if code.begins_with("#"):
				continue
			for word: String in FORBIDDEN:
				if code.contains(word):
					problems.append("%s/%s:%d uses %s: ask the mixer by name (Sfx.duck) instead" % [dir_path, f, n, word])
