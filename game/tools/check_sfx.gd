extends SceneTree
## Checks the sound effects from tools/make_sfx.py as imported: the loops are seamless
## Forward loops (begin 0, end = the full length) with no jump in the decoded audio
## across the loop point (the step at the seam against the typical step elsewhere,
## like check_radio.gd), and the one-shots don't loop; each vehicle mode (sfx.gd `speaks`) plays
## only its own loops (no car engine on the bike, in a room or the helicopter). Also prints each file's
## import format and length.
##   godot --headless --path game --script res://tools/check_sfx.gd

## Loop MW-5: club_leak and busker are the city sounds' loops (city_sounds.gd); loop MW-3: crowd_murmur and
## steps_guitar the crowds' (crowds.gd).
const Sfx := preload("res://scripts/sfx.gd")
const LOOPS := ["engine_idle", "engine_mid", "engine_high", "tyre_roll", "tyre_wet", "tyre_squeal", "rotor",
		"city_day", "city_night", "rain", "police_siren", "club_leak", "busker", "crowd_murmur", "steps_guitar",
		"queue_chatter", "amb_river", "amb_park", "amb_square", "amb_yard", "fan_chant", "gong_bowls", "techno_thump",
		"jazz_trio", "bike_roll", "bike_freewheel", "lift_hum"]


func _initialize() -> void:
	var ok := true
	var dir := DirAccess.open("res://audio/sfx")
	var names: Array[String] = []
	for f in dir.get_files():
		if f.ends_with(".wav"):
			names.append(f.get_basename())
	names.sort()
	for n in names:
		var s: AudioStreamWAV = load("res://audio/sfx/%s.wav" % n)
		var frames := int(round(s.get_length() * s.mix_rate))
		var line := "%s: format %d, %d Hz, %s, loop mode %d, begin %d, end %d (%d frames, %.2f s)" % [
				n, s.format, s.mix_rate, "stereo" if s.stereo else "mono", s.loop_mode, s.loop_begin, s.loop_end, frames, s.get_length()]
		if n in LOOPS:
			if s.loop_mode != AudioStreamWAV.LOOP_FORWARD or s.loop_begin != 0 or s.loop_end != frames:
				ok = false
				line += "  <-- NOT a full forward loop"
			elif s.format != AudioStreamWAV.FORMAT_QOA:
				ok = false
				line += "  <-- not QOA"
			else:
				var r := _seam(s)
				line += "\n    " + r[1]
				ok = ok and r[0]
		elif s.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			ok = false
			line += "  <-- a one-shot that loops"
		print(line)
	# Every vehicle swap silences what does not belong (PT 2026-11-08: on the coffee run's bike the
	# car's engine kept on): [engine, car tyres, bike] per sfx.gd mode, and nothing in the helicopter.
	var want := {"car": [true, true, false], "bike": [false, false, true], "boat": [true, false, false],
			"electric": [false, false, false], "foot": [false, false, false]}
	for m in want:
		for heli in [false, true]:
			var got: Array[bool] = Sfx.speaks(m, heli)
			var exp: Array = [false, false, false] if heli else want[m]
			if got != exp:
				ok = false
				print("mode %s%s: speaks %s, want %s  <-- wrong loops" % [m, " (heli)" if heli else "", got, exp])
	print("sfx: %d files, %s" % [names.size(), "OK" if ok else "PROBLEM"])
	quit(0 if ok else 1)


## Decodes the last second, the seam and the first second after it.
func _seam(s: AudioStreamWAV) -> Array:
	var pb: AudioStreamPlayback = s.instantiate_playback()
	if not pb.has_method("mix_audio"):
		return [true, "(no mix_audio in this build; decode check skipped)"]
	var span := minf(1.0, s.get_length() * 0.45)
	pb.start(s.get_length() - span)
	var buf: PackedVector2Array = pb.call("mix_audio", 1.0, int(s.mix_rate * span * 2.0))
	var steps := PackedFloat32Array()
	for i in range(1, buf.size()):
		steps.append((buf[i] - buf[i - 1]).length())
	var sorted := steps.duplicate()
	sorted.sort()
	var p99 := sorted[int(sorted.size() * 0.999)]
	var seam_at := int(s.mix_rate * span)
	var near := 0.0
	for i in range(seam_at - 64, seam_at + 64):
		if i > 0 and i < buf.size():
			near = maxf(near, (buf[i] - buf[i - 1]).length())
	var silent := 0
	var run := 0
	for v in buf:
		run = run + 1 if v.length() < 0.0005 else 0
		silent = maxi(silent, run)
	var good := near <= p99 * 1.5 + 0.01 and silent <= 64
	return [good, "seam window max step %.4f, 99.9th pct step %.4f, longest near-silent run %d samples, loops %d%s" % [
			near, p99, silent, pb.get_loop_count(), "" if good else "  <-- seam jump or gap"]]
