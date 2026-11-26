extends SceneTree
## Za deckami, the DJ game in Smoła (docs/design/smola-decks.md 11.9 with section 12's changes):
## the rules (decks_sim.gd), the tracks (data/decks_tracks.json, audio/club/decks_*.ogg) and the
## tuning numbers (data/decks.json), without the club or the view. Built in the smola-decks loop,
## stage A:
##  1. the tracks: four ids, each with a name and a file; the OGG loads and is 64 beats at 132 BPM
##     to the millisecond; `loud` and `kick` have 512 ints 0..99; every beat's kick is in the
##     picture's first quarter beat (its first two eighths peak at or above the track's median) on
##     at least 56 of 64 beats;
##  2. the constants: 64 beats at BPM is the loop's length, CUE + BLEND = 64, decks.json has every
##     tuning key;
##  3. determinism: the same seed and bot give the same digest (hype every beat and every event); a
##     different seed gives a different track order;
##  4-6. the bots against section 12 point 8 (SEEDS seeds each): perfect always PIEC with three clean
##     hand-overs, no early return and `shades` at most once; mid in ROZGRZEWKA or DOBRY SET in at
##     least 80 % and PIEC in at most 10 %; poor below DOBRY SET in at least 90 % and never sent off
##     before mix 2; none always ŚWIETLICA, the DJ back within 50 s;
##  7. bounds: on every tick of every bot run 0 <= hype <= 100 and 0 <= avg <= 100;
##  8. the forced rules: a locked beat +1.5 with the streak bonus reaching +2.5 at 8; a gallop -3,
##     the streak reset, `eee` on the 4th; ENDING -2 a beat; a clean hand-over +8 only at 48 or 64
##     within 0.5 and nothing at 32; a hard cut -8; the magnet snaps at 0.0014 and not at 0.002; a
##     200 pt jog moves one beat (1 %) and keeps its place; the pitch clamped at 4 %; abort() ends
##     the set with no result;
##  9. the early return at 8 cold beats, not 7;
## 10. an early return is tier 0 whatever the average, and the average counts only played beats.
## TODO stage B (decks_match.gd, club.gd wiring, dialogue.json, dev_flags.gd), not written here:
##  - club with stand-ins (Fakes.Wallet, Hud, Dialogue): the invite once 6 s in, the tile after it,
##    a perfect set pays +120 zl / +50 once a visit, best and sets saved, city_drawn false then
##    true, the club duck held; the ✕ pays nothing and does not count; the hot crowd group after;
##  - words: every club_decks_* group and tag the scripts ask for, [pl, en] pairs, <= 90 chars,
##    help chips <= 4 words, no denylisted brand, every UI letter in the 5x7 font;
##  - flags: parse_with(["--decks", "--decks-bot=mid", "--decks-log"]) and rave_flag == "club";
##  - view: decks_match with auto_skill = perfect emits finished then closed headless; every touch
##    zone >= 44 pt with no overlap at 2532x1170 @3 and 2048x1536 @2; Kit.rects <= 1100 a frame.
## Prints `check_decks: OK`, or the problems and their count (exit 1). A few seconds.
##   godot --headless --path game --script res://tools/check_decks.gd
## Tuning mode (prints the table per bot, checks nothing but the targets' verdicts):
##   godot --headless --path game --script res://tools/check_decks.gd -- --tune=200 [--tune-set=key=value,...]

const Sim := preload("res://scripts/decks_sim.gd")
const SEEDS := 30
const SKILLS := ["perfect", "mid", "poor", "none"]
## Section 12 point 8: the DJ comes back within this many seconds for the no-input bot.
const DJ_BACK_S := 50.0

var _bad := 0


func _initialize() -> void:
	var n := 0
	var tune := {}
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tune="):
			n = int(a.trim_prefix("--tune="))
		elif a.begins_with("--tune-set="):
			for kv: String in a.trim_prefix("--tune-set=").split(",", false):
				var p := kv.split("=")
				if p.size() == 2:
					tune[p[0]] = _value(p[1])
	if n > 0:
		_tune(n, tune)
		quit(0)
		return
	_tracks()
	_constants()
	_determinism()
	_bots()
	_forced()
	_early()
	if _bad == 0:
		print("check_decks: OK")
		quit(0)
	else:
		print("check_decks: %d problem(s)" % _bad)
		quit(1)


func _fail(msg: String) -> void:
	_bad += 1
	print("check_decks: " + msg)


## A tune value: a number, or numbers split by "/" for an array.
func _value(s: String) -> Variant:
	if s.contains("/"):
		var out: Array = []
		for x: String in s.split("/"):
			out.append(float(x))
		return out
	return float(s)


# ---- 1, 2: the tracks and the constants ----

func _tracks() -> void:
	var rows := Sim.tracks()
	if rows.size() != 4:
		_fail("tracks: %d rows, want 4" % rows.size())
	var ids := {}
	var want := float(Sim.TRACK_BEATS) * 60.0 / Sim.BPM
	for row: Dictionary in rows:
		var id := str(row.get("id", ""))
		if id == "" or ids.has(id):
			_fail("tracks: an empty or repeated id: '%s'" % id)
		ids[id] = true
		if str(row.get("name", "")).strip_edges() == "":
			_fail("tracks: %s has no name" % id)
		if int(row.get("beats", 0)) != Sim.TRACK_BEATS or absf(float(row.get("bpm", 0.0)) - Sim.BPM) > 1e-6:
			_fail("tracks: %s is not %d beats at %.1f BPM" % [id, Sim.TRACK_BEATS, Sim.BPM])
		var file := str(row.get("file", ""))
		var stream := load(file) as AudioStream if ResourceLoader.exists(file) else null
		if stream == null:
			_fail("tracks: %s: %s does not load" % [id, file])
		elif absf(stream.get_length() - want) > 0.001:
			_fail("tracks: %s is %.4f s, want %.4f" % [id, stream.get_length(), want])
		for key: String in ["loud", "kick"]:
			var v: Variant = row.get(key)
			if not (v is Array) or (v as Array).size() != Sim.TRACK_BEATS * 8:
				_fail("tracks: %s.%s is not 512 values" % [id, key])
				continue
			for x: Variant in v:
				if not (x is float or x is int) or float(x) != floorf(float(x)) or float(x) < 0.0 or float(x) > 99.0:
					_fail("tracks: %s.%s has %s, not an int 0..99" % [id, key, x])
					break
		var kick: Variant = row.get("kick")
		if kick is Array and (kick as Array).size() == 512:
			var sorted := (kick as Array).duplicate()
			sorted.sort()
			var median := (float(sorted[255]) + float(sorted[256])) * 0.5
			var on := 0
			for i in Sim.TRACK_BEATS:
				if maxf(float(kick[8 * i]), float(kick[8 * i + 1])) >= median:
					on += 1
			if on < 56:
				_fail("tracks: %s has its kick in the first quarter beat on %d of 64 beats, want 56" % [id, on])


func _constants() -> void:
	if Sim.CUE_BEATS + Sim.BLEND_BEATS != Sim.TRACK_BEATS:
		_fail("constants: CUE + BLEND = %d, not %d" % [Sim.CUE_BEATS + Sim.BLEND_BEATS, Sim.TRACK_BEATS])
	if absf(Sim.TICK_BEATS - 132.0 / 3600.0) > 1e-12:
		_fail("constants: TICK_BEATS %f" % Sim.TICK_BEATS)
	var rows := Sim.tracks()
	if not rows.is_empty():
		var frames := int((rows[0] as Dictionary).get("frames", 0))
		var rate := int((rows[0] as Dictionary).get("rate", 44100))
		if absf(float(frames) / float(rate) - float(Sim.TRACK_BEATS) * 60.0 / Sim.BPM) > 0.001:
			_fail("constants: %d frames at %d Hz is not 64 beats" % [frames, rate])
	var tab := Sim.table()
	for key: String in Sim.TUNABLES:
		if not tab.has(key):
			_fail("constants: decks.json has no '%s'" % key)
	for skill: String in SKILLS:
		if not (tab.get("bots", {}) as Dictionary).has(skill):
			_fail("constants: decks.json has no bot '%s'" % skill)
	if (tab.get("tiers", []) as Array).size() != 3 or (tab.get("tips", []) as Array).size() != 4 or (tab.get("respect", []) as Array).size() != 4:
		_fail("constants: tiers want 3 edges, tips and respect 4 values")


# ---- 3: determinism ----

func _determinism() -> void:
	var a := Sim.play_bot("mid", 5)
	var b := Sim.play_bot("mid", 5)
	if str(a["digest"]) != str(b["digest"]):
		_fail("determinism: mid seed 5 gave two digests")
	var c := Sim.play_bot("mid", 6)
	if str(a["digest"]) == str(c["digest"]):
		_fail("determinism: seeds 5 and 6 gave one digest")
	var first: Array = Sim.new(1).order
	var differs := false
	for s in range(2, 12):
		if Sim.new(s).order != first:
			differs = true
	if not differs:
		_fail("determinism: ten seeds gave one track order")


# ---- 4-7: the bots and the bounds ----

## Every skill's results over `n` seeds.
func _runs(n: int, tune: Dictionary) -> Dictionary:
	var out := {}
	for skill: String in SKILLS:
		var rs: Array[Dictionary] = []
		for s in range(1, n + 1):
			rs.append(Sim.play_bot(skill, s, tune))
		out[skill] = rs
	return out


## Section 12 point 8 (and 11.9's 4-7) over the runs: the problems, empty when every target holds.
func _targets(runs: Dictionary) -> PackedStringArray:
	var bad := PackedStringArray()
	for skill: String in SKILLS:
		for r: Dictionary in runs[skill]:
			if not bool(r["done"]):
				bad.append("%s: a set did not end" % skill)
			if float(r["hype_lo"]) < 0.0 or float(r["hype_hi"]) > 100.0 or float(r["avg_lo"]) < 0.0 or float(r["avg_hi"]) > 100.0:
				bad.append("%s: out of bounds (hype %.2f..%.2f, avg %.2f..%.2f)" % [skill, r["hype_lo"], r["hype_hi"], r["avg_lo"], r["avg_hi"]])
	var n := float((runs["perfect"] as Array).size())
	var piec := 0
	for r: Dictionary in runs["perfect"]:
		if int(r["tier"]) == 3:
			piec += 1
		if bool(r["early"]) or int(r["clean"]) != 3 or int((r["stats"] as Dictionary).get("shades", 0)) > 1:
			bad.append("perfect: early %s, %d clean, %d shades" % [r["early"], r["clean"], (r["stats"] as Dictionary).get("shades", 0)])
	if piec < int(n):
		bad.append("perfect: PIEC in %d of %d" % [piec, int(n)])
	var mid_ok := 0
	var mid_piec := 0
	for r: Dictionary in runs["mid"]:
		var tr := int(r["tier"])
		if tr == 1 or tr == 2:
			mid_ok += 1
		if tr == 3:
			mid_piec += 1
	if float(mid_ok) < 0.8 * n:
		bad.append("mid: ROZGRZEWKA or DOBRY in %d of %d, want 80 %%" % [mid_ok, int(n)])
	if float(mid_piec) > 0.1 * n:
		bad.append("mid: PIEC in %d of %d, want at most 10 %%" % [mid_piec, int(n)])
	var poor_low := 0
	for r: Dictionary in runs["poor"]:
		if int(r["tier"]) <= 1:
			poor_low += 1
		if bool(r["early"]) and int(r["mix_at_dj"]) < 1:
			bad.append("poor: sent off in mix 1 (%.1f s)" % float(r["dj_back_s"]))
	if float(poor_low) < 0.9 * n:
		bad.append("poor: below DOBRY in %d of %d, want 90 %%" % [poor_low, int(n)])
	for r: Dictionary in runs["none"]:
		if int(r["tier"]) != 0 or not bool(r["early"]) or int((r["stats"] as Dictionary).get("dj_back", 0)) != 1:
			bad.append("none: tier %d, early %s" % [r["tier"], r["early"]])
		elif float(r["dj_back_s"]) > DJ_BACK_S:
			bad.append("none: the DJ back at %.1f s, want %.0f" % [float(r["dj_back_s"]), DJ_BACK_S])
	return bad


func _bots() -> void:
	for p: String in _targets(_runs(SEEDS, {})):
		_fail("bots: " + p)


# ---- 8: the forced rules ----

## A sim in mix 1's blend with deck B playing, both in the room, locked, hype 50.
func _blend(tune: Dictionary = {}) -> Sim:
	var s := Sim.new(3, tune)
	s.keep_events = true
	s.phase = Sim.BLEND
	s.mix_start = 0
	s.playing[1] = true
	s.xf = 0.5
	s.err = 0.0
	s.hype = 50.0
	return s


func _near(a: float, b: float, eps := 1e-6) -> bool:
	return absf(a - b) <= eps


func _has(s: Sim, name: String) -> bool:
	for e: Dictionary in s.events:
		if str(e.get("name", "")) == name:
			return true
	return false


## A sim ticked to mix 1's cue (no input).
func _to_cue(seed_value := 3) -> Sim:
	var s := Sim.new(seed_value)
	s.keep_events = false
	while s.phase != Sim.CUE:
		s.tick()
	return s


func _forced() -> void:
	# A locked beat: +1.5, the bonus growing to +2.5 at a streak of 8 and no further (the design's
	# numbers through the tune), then the shipped bonus at a full streak.
	var s := _blend({"lock_gain": 1.5, "streak_bonus": 2.5, "streak_full": 8})
	s._judge(40)
	if not _near(s.hype, 51.5):
		_fail("forced: a locked beat gave %+.3f, want +1.5" % (s.hype - 50.0))
	s.hype = 50.0
	s.streak = 8
	s._judge(41)
	if not _near(s.hype, 54.0):
		_fail("forced: a locked beat at a streak of 8 gave %+.3f, want +4.0" % (s.hype - 50.0))
	s.hype = 50.0
	s.streak = 20
	s._judge(42)
	if not _near(s.hype, 54.0):
		_fail("forced: the streak bonus passed +2.5 (%+.3f)" % (s.hype - 50.0))
	s = _blend()
	s.streak = s.streak_full
	s._judge(43)
	if not _near(s.hype, 50.0 + s.lock_gain + s.streak_bonus):
		_fail("forced: decks.json's full streak gave %+.3f, want %+.3f" % [s.hype - 50.0, s.lock_gain + s.streak_bonus])
	# A gallop: -3, the streak reset, `eee` on the 4th.
	s = _blend()
	s.streak = 5
	s.err = 0.3
	s._judge(40)
	if not _near(s.hype, 47.0) or s.streak != 0:
		_fail("forced: a gallop gave %+.3f, streak %d" % [s.hype - 50.0, s.streak])
	for i in 2:
		s._judge(41 + i)
	if _has(s, "eee"):
		_fail("forced: `eee` before the 4th gallop beat")
	s._judge(43)
	if not _has(s, "eee"):
		_fail("forced: no `eee` on the 4th gallop beat")
	# A loose beat: nothing.
	s = _blend()
	s.err = 0.12
	s._judge(40)
	if not _near(s.hype, 50.0):
		_fail("forced: a loose beat gave %+.3f" % (s.hype - 50.0))
	# ENDING: -2 a beat with the fader on A.
	s = _blend()
	s.phase = Sim.ENDING
	s.xf = 0.0
	s._judge(65)
	s._judge(66)
	if not _near(s.hype, 46.0):
		_fail("forced: two ENDING beats gave %+.3f, want -4" % (s.hype - 50.0))
	# Clean hand-overs: +8 within 0.5 of beat 48 or 64 when locked, nothing at 32 or 0.6 off.
	for c: Array in [[48.3, 8.0], [47.6, 8.0], [48.6, 0.0], [63.6, 8.0], [32.2, 0.0], [56.0, 0.0]]:
		s = _blend()
		s.rb = float(c[0])
		s.xf = 1.0
		s._hand_over()
		if not _near(s.hype, 50.0 + float(c[1])):
			_fail("forced: a locked landing at %.1f gave %+.3f, want %+.1f" % [c[0], s.hype - 50.0, c[1]])
	s = _blend()
	s.phase = Sim.ENDING
	s.rb = 64.4
	s._hand_over()
	if not _near(s.hype, 58.0):
		_fail("forced: a locked landing in ENDING at 64.4 gave %+.3f, want +8" % (s.hype - 50.0))
	# A hard cut: -8; a loose cut on the bar: nothing.
	s = _blend()
	s.rb = 48.0
	s.err = 0.2
	s._hand_over()
	if not _near(s.hype, 42.0):
		_fail("forced: a galloping landing gave %+.3f, want -8" % (s.hype - 50.0))
	s = _blend()
	s.rb = 48.0
	s.err = 0.1
	s._hand_over()
	if not _near(s.hype, 50.0):
		_fail("forced: a loose landing on the bar gave %+.3f, want 0" % (s.hype - 50.0))
	# The hand-over: B is the room, the fader back to A, the tempo glides to 1.0 over 8 beats.
	s = _blend()
	s.native[1] = 1.02
	s.rb = 48.0
	s._hand_over()
	if s.room != 1 or s.xf != 0.0 or s.playing[0] or s.phase != Sim.SOLO or s.next_start != 64:
		_fail("forced: after a hand-over room %d xf %.2f phase %s next %d" % [s.room, s.xf, s.phase_name(), s.next_start])
	var ticks := 0
	var top := 0.0
	while absf(s.speed[1] - 1.0) > 1e-9 or ticks == 0:
		s.tick()
		top = maxf(top, s.speed[1])
		ticks += 1
		if ticks > 600:
			break
	var glide := float(ticks) * Sim.TICK_BEATS
	if top > 1.02 + 1e-9 or top < 1.01 or absf(glide - 8.0) > 0.1:
		_fail("forced: the glide took %.2f beats, want 8" % glide)
	# The magnet: 0.0014 snaps to exactly the room's tempo, 0.002 does not move.
	for c: Array in [[0.0014, true], [0.002, false]]:
		s = _to_cue()
		s.pitch = (1.0 + float(c[0])) / s.native[1] - 1.0
		for i in 180:
			s.tick()
		var res := s.tempo_residual()
		if bool(c[1]) and absf(res) > 1e-9:
			_fail("forced: the magnet left %.6f of %.4f" % [res, c[0]])
		if not bool(c[1]) and not _near(res, float(c[0]), 1e-9):
			_fail("forced: the magnet moved %.4f to %.6f" % [c[0], res])
	# A finger on the pitch holds the magnet off.
	s = _to_cue()
	s.pitch = 0.001
	for i in 60:
		s.in_pitch_touch = true
		s.tick()
	if not _near(s.tempo_residual(), 0.001, 1e-9):
		_fail("forced: the magnet pulled under a finger")
	# The jog: 200 pt dragged (0.5 pt a tick) moves B one beat within 1 %, and it keeps its place.
	s = _to_cue()
	var d0 := s.pos[1] - s.pos[0]
	for i in 400:
		s.in_jog_pt = 0.5
		s.tick()
	for i in 60:
		s.tick()
	var moved := fposmod(s.pos[1] - s.pos[0] - d0 + 32.0, 64.0) - 32.0
	if absf(moved - 1.0) > 0.01:
		_fail("forced: a 200 pt jog moved %.4f beats, want 1" % moved)
	for i in 120:
		s.tick()
	var later := fposmod(s.pos[1] - s.pos[0] - d0 + 32.0, 64.0) - 32.0
	if absf(later - moved) > 1e-6:
		_fail("forced: the jog did not keep its place (%.6f then %.6f)" % [moved, later])
	# The pitch clamped at 4 %.
	s = _to_cue()
	s.in_pitch_pt = -100000.0
	s.tick()
	if not _near(s.pitch, 0.04):
		_fail("forced: the pitch went to %.4f, want 0.04" % s.pitch)
	s.in_pitch_pt = 100000.0
	s.tick()
	if not _near(s.pitch, -0.04):
		_fail("forced: the pitch went to %.4f, want -0.04" % s.pitch)
	# Mix 3: B's tempo the other way from mix 2, its cue further out.
	for seed_value in range(1, 21):
		s = Sim.new(seed_value)
		var e2 := s.tempo_sign * 0.015
		var e3 := -s.tempo_sign * 0.025
		if absf(s.cue_off[2]) < 0.35 - 1e-9 or absf(s.cue_off[2]) > 0.5 + 1e-9 or absf(s.cue_off[0]) < 0.25 - 1e-9 or absf(s.cue_off[1]) > 0.45 + 1e-9:
			_fail("forced: seed %d cue offsets %s" % [seed_value, s.cue_off])
		s.mix = 1
		s._start_cue(64)
		var n2 := s.native[1]
		s.room = 1
		s.mix = 2
		s._start_cue(128)
		var n3 := s.native[0]
		if not _near(n2 - 1.0, e2) or not _near(n3 - 1.0, e3):
			_fail("forced: seed %d mix tempos %+.4f %+.4f" % [seed_value, n2 - 1.0, n3 - 1.0])
	# The ✕: done at once, no `over`, no result.
	s = _to_cue()
	s.keep_events = true
	s.abort()
	s.tick()
	if s.phase != Sim.DONE or not s.aborted or _has(s, "over") or s.tier != -1:
		_fail("forced: abort() left phase %s, over %s, tier %d" % [s.phase_name(), _has(s, "over"), s.tier])


# ---- 9, 10: the early return and the average ----

func _early() -> void:
	# Hype under 10: 7 beats keep the set on, the 8th sends the DJ back.
	var s := _blend()
	s.phase = Sim.CUE
	s.xf = 0.0
	s.hype = 3.0
	for i in 7:
		s._judge(i)
	if s.phase == Sim.DONE or _has(s, "dj_back"):
		_fail("early: 7 cold beats ended the set")
	s._judge(7)
	if s.phase != Sim.DONE or not _has(s, "dj_back") or not s.early or s.tier != 0:
		_fail("early: 8 cold beats left phase %s, early %s, tier %d" % [s.phase_name(), s.early, s.tier])
	# A warm set taken back is still tier 0, and the average is over the beats played only.
	s = _blend()
	s.hype_sum = 70.0 * 100.0
	s.judged = 100
	s.hype = 9.0
	s.phase = Sim.ENDING
	s.xf = 0.0
	s.cold_run = 7
	s._judge(100)
	if s.phase != Sim.DONE or s.tier != 0 or not _near(s.avg(), (7000.0 + s.hype) / 101.0):
		_fail("early: a set at avg %.1f taken back got tier %d (avg %.2f)" % [s.avg(), s.tier, s.avg()])
	var r := Sim.play_bot("none", 4)
	var played := 0
	var sim := Sim.new(4)
	sim.keep_events = false
	while sim.phase != Sim.DONE:
		sim.tick()
	played = sim.last_n + 1
	if sim.judged != played or not _near(float(r["avg"]), sim.hype_sum / float(played)):
		_fail("early: the average over %d judged of %d beats played (%.2f)" % [sim.judged, played, float(r["avg"])])


# ---- the tuning mode ----

func _tune(n: int, tune: Dictionary) -> void:
	var runs := _runs(n, tune)
	print("decks tune: %d seeds a bot%s" % [n, (", " + str(tune)) if not tune.is_empty() else ""])
	print("bot      | SWIE  ROZG  DOBR  PIEC | avg mean  p10   p90 | early | secs mean  max | locked mix1 mix2 mix3")
	for skill: String in SKILLS:
		var rs: Array = runs[skill]
		var tiers := [0, 0, 0, 0]
		var avgs: Array[float] = []
		var early := 0
		var secs := 0.0
		var secs_max := 0.0
		var lk := [0.0, 0.0, 0.0]
		var lk_n := [0, 0, 0]
		for r: Dictionary in rs:
			tiers[clampi(int(r["tier"]), 0, 3)] += 1
			avgs.append(float(r["avg"]))
			if bool(r["early"]):
				early += 1
			secs += float(r["seconds"])
			secs_max = maxf(secs_max, float(r["seconds"]))
			var g: Array = r["grades"]
			for i in 3:
				if str(g[i]) != Sim.NOT_REACHED:
					lk[i] += float((r["locked"] as Array)[i])
					lk_n[i] += 1
		avgs.sort()
		var mean := 0.0
		for a: float in avgs:
			mean += a
		mean /= float(maxi(1, avgs.size()))
		var p10 := avgs[int(0.1 * (avgs.size() - 1))]
		var p90 := avgs[int(0.9 * (avgs.size() - 1))]
		var f := float(maxi(1, rs.size()))
		print("%-8s | %4.0f%% %4.0f%% %4.0f%% %4.0f%% | %8.1f %5.1f %5.1f | %4.0f%% | %9.1f %4.0f | %11s %4s %4s" % [skill,
				100.0 * tiers[0] / f, 100.0 * tiers[1] / f, 100.0 * tiers[2] / f, 100.0 * tiers[3] / f, mean, p10, p90,
				100.0 * early / f, secs / f, secs_max, _share(lk[0], lk_n[0]), _share(lk[1], lk_n[1]), _share(lk[2], lk_n[2])])
	var bad := _targets(runs)
	if bad.is_empty():
		print("decks tune: every section 12 point 8 target holds")
	else:
		var seen := {}
		for p: String in bad:
			if not seen.has(p):
				seen[p] = true
				print("decks tune: MISS " + p)


func _share(sum: float, n: int) -> String:
	return "%3.0f%%" % (100.0 * sum / float(n)) if n > 0 else "  - "
