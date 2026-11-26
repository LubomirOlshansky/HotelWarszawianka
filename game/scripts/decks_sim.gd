extends RefCounted
## Za deckami, the DJ beat-matching game in Smoła (docs/design/smola-decks.md sections 4-7, 11.2 and
## section 12, which wins where they differ): the pure rules. A deterministic 60 Hz sim, seeded, no
## nodes, no engine time; decks_match.gd (stage B) draws it, plays the two tracks and feeds the touch
## in. Built in the smola-decks loop, stage A.
##
## Units: beats (132 BPM) and speed ratios. Two decks, 0 and 1, never swapped; `room` is the deck the
## room hears, `deck_b()` the other one. The room deck runs at 1.0 (after a hand-over it glides there
## over `glide_beats`); deck B runs at `native * (1 + pitch) + jog_rate`. `rb` is the room's beat
## clock (beats since mix 1's start, -INTRO_BEATS at the set's start); every phase boundary, the
## blend zone and the phrase bars are in room beats.
##
## No bass cut, no drop (section 12 point 2). An early return (the DJ back after `cold_beats` beats
## under `cold_hype`) is tier 0 whatever the average, and the average counts only the beats played
## (point 3). `abort()` is the ✕: the set ends at once with no `over` event and no result (point 4).
##
## Input: before each `tick()` the view sets `in_jog_pt`, `in_pitch_pt`, `in_xf_pt` (points dragged
## since the last tick, signed; the tick zeroes them), the held keys `in_jog_key`, `in_pitch_key`,
## `in_xf_key` (-1, 0, 1) and `in_pitch_touch`. Output: `events` (Array of {"name": ..., more}), which
## the view drains; the read-only queries below. Every tuning number is a var set from
## data/decks.json in `_init`, so check_decks.gd's tuning mode can override it.
##
## Cost: a few floats a tick and a small dictionary an event; the sim is an object only while a set
## is on.

const HZ := 60
const DT := 1.0 / 60.0
const BPM := 132.0
## Room beats a tick at speed 1.0: 132 / 60 / 60.
const TICK_BEATS := BPM / 60.0 / 60.0
const TRACK_BEATS := 64
const CUE_BEATS := 32
const BLEND_BEATS := 32
const INTRO_BEATS := 12
const OUTRO_BEATS := 12
const MIXES := 3
const BAR := 4
const PHRASE := 16
const TUNING := "res://data/decks.json"
const TRACKS := "res://data/decks_tracks.json"
## The longest a bot run may take (the check's guard): 200 s.
const BOT_MAX_TICKS := 200 * HZ

# --- the phases ---
const INTRO := 0
const CUE := 1
const BLEND := 2
const ENDING := 3
const SOLO := 4
const OUTRO := 5
const DONE := 6
const PHASE_NAMES := ["intro", "cue", "blend", "ending", "solo", "outro", "done"]

## Tier ids, 0..3 (the words come from dialogue.json in stage B).
const TIER_IDS := ["swietlica", "rozgrzewka", "dobry", "piec"]
## Mix grade ids; "-" for a mix not reached.
const GRADE_IDS := ["czysto", "dobrze", "krzywo", "galop"]
const NOT_REACHED := "-"
## Crowd band ids, 0..4.
const BAND_IDS := ["cold", "polite", "moving", "hot", "piec"]
## Every number decks.json sets (the order is the file's).
const TUNABLES := ["hype_start", "hype_rest", "rest_step", "lock_beat", "loose_beat", "lock_off", "lock_gain",
		"streak_bonus", "streak_full", "loose_loss", "gallop_loss", "eee_after", "ending_loss", "clean_bonus", "clean_window",
		"hard_loss", "cold_hype", "cold_beats", "tiers", "tips", "respect", "bands", "shades_hype", "tempo_err",
		"cue_off_lo", "cue_off_hi", "jog_beat_per_pt", "jog_max", "jog_tau", "jog_key", "pitch_per_pt", "pitch_max",
		"pitch_key_rate", "magnet", "magnet_tau", "xf_span_pt", "xf_key_rate", "xf_both", "xf_land", "glide_beats"]

## decks.json and decks_tracks.json, read once a run.
static var _table: Dictionary = {}
static var _tracks: Array = []

# --- tuning (data/decks.json; section 6 and 11.2) ---
var hype_start := 50.0
var hype_rest := 55.0
var rest_step := 0.25
var lock_beat := 0.07
var loose_beat := 0.15
var lock_off := 0.09
var lock_gain := 1.5
var streak_bonus := 2.5
var streak_full := 8
## A loose beat (between lock_beat and loose_beat) with both decks in: a small loss (stage B tune).
var loose_loss := 0.0
var gallop_loss := 3.0
var eee_after := 4
var ending_loss := 2.0
var clean_bonus := 8.0
var clean_window := 0.5
var hard_loss := 8.0
var cold_hype := 5.0
var cold_beats := 16
var tiers: Array = [35.0, 60.0, 82.0]
var tips: Array = [0, 30, 60, 120]
var respect: Array = [5, 15, 30, 50]
var bands: Array = [25.0, 50.0, 75.0, 90.0]
var shades_hype := 95.0
## Deck B's tempo error per mix (times a sign drawn per mix: mix 3 the other way from mix 2).
var tempo_err: Array = [0.0, 0.015, 0.025]
var cue_off_lo: Array = [0.25, 0.25, 0.35]
var cue_off_hi: Array = [0.45, 0.45, 0.5]
var jog_beat_per_pt := 0.005
var jog_max := 0.10
var jog_tau := 0.06
var jog_key := 0.04
var pitch_per_pt := 0.04 / 90.0
var pitch_max := 0.04
var pitch_key_rate := 0.02
var magnet := 0.0015
var magnet_tau := 0.25
var xf_span_pt := 150.0
var xf_key_rate := 1.5
var xf_both := 0.12
var xf_land := 0.98
var glide_beats := 8.0

# --- input (set by the view before each tick) ---
## Points dragged on the jog, the pitch and the crossfader since the last tick (zeroed by tick()).
var in_jog_pt := 0.0
var in_pitch_pt := 0.0
var in_xf_pt := 0.0
## Held keys: A/D, W/S, Left/Right as -1, 0 or 1 (W is faster).
var in_jog_key := 0
var in_pitch_key := 0
var in_xf_key := 0
## A finger on the pitch fader (the magnet waits for it to lift).
var in_pitch_touch := false

# --- state ---
var rng := RandomNumberGenerator.new()
## The tracks (indices into decks_tracks.json) in the set's order: mix i plays order[i] into order[i+1].
var order: Array[int] = []
var track: Array[int] = [0, 0]
## Beats into each deck's track, in [0, 64).
var pos: Array[float] = [0.0, 0.0]
## Each record's own tempo (1 + its error); the room deck's is 1.
var native: Array[float] = [1.0, 1.0]
## Each deck's speed this tick (beats a beat), the jog included.
var speed: Array[float] = [1.0, 0.0]
var playing: Array[bool] = [true, false]
var room := 0
var phase := INTRO
## The mix being played, 0..2 (the next one while in SOLO stays the last one played until its cue).
var mix := 0
## The current mix's first beat, S (room beats). The cue is [S, S+32), the blend [S+32, S+64).
var mix_start := 0
## The next mix's S while in SOLO.
var next_start := 0
var outro_end := 0
## The room's beat clock and the last whole beat judged.
var rb := -float(INTRO_BEATS)
var last_n := -INTRO_BEATS
var pitch := 0.0
var jog_rate := 0.0
var xf := 0.0
## Deck B against the room, wrapped to [-0.5, 0.5) beats; 0 while B is not playing.
var err := 0.0
var locked := false
var hype := 50.0
var streak := 0
var gallop_run := 0
var cold_run := 0
var lock_run := 0
var hype_sum := 0.0
var judged := 0
var band_now := 0
var shades_done := false
var early := false
var aborted := false
var tier := -1
var t := 0
## Per mix: beats with both decks in the room, of them locked, the longest locked run, a clean hand-over,
## handed over.
var m_both: Array[int] = [0, 0, 0]
var m_locked: Array[int] = [0, 0, 0]
var m_longest: Array[int] = [0, 0, 0]
var m_clean: Array[bool] = [false, false, false]
var m_done: Array[bool] = [false, false, false]
## Per mix: deck B cued (a mix the DJ took back before its cue is "not reached").
var m_cued: Array[bool] = [false, false, false]
## Each mix's cue offset (drawn in _init) and tempo sign.
var cue_off: Array[float] = [0.0, 0.0, 0.0]
var tempo_sign := 1.0
var _glide_from := 1.0
var _glide_done := 1.0
var _jog_a := 0.0

# --- output ---
var events: Array[Dictionary] = []
## Keep every event in `events` until the view drains it (false: the check's long runs).
var keep_events := true
## Event counts by name.
var stats: Dictionary = {}
## The digest's trace (hype every beat and every event name), kept only when on.
var trace_on := false
var trace := PackedStringArray()

# --- the bots (bot_setup, bot_input; the check and auto play only) ---
var _bot: Dictionary = {}
var _bot_skill := ""
var _bot_rng := RandomNumberGenerator.new()
var _bot_err := PackedFloat64Array()
var _bot_res := PackedFloat64Array()
var _bot_i := 0
var _bot_mix := -1
var _bot_land := 64.0
var _bot_stop := -1.0
var _bot_pitch_done := false


## decks.json, read once.
static func table() -> Dictionary:
	if _table.is_empty():
		var f := FileAccess.open(TUNING, FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_table = d
	return _table


## decks_tracks.json's rows, read once.
static func tracks() -> Array:
	if _tracks.is_empty():
		var f := FileAccess.open(TRACKS, FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary and d.get("tracks") is Array:
				_tracks = d["tracks"]
	return _tracks


## A set from `seed_value`; `tune` overrides decks.json's numbers by key ("bot.SKILL.KEY" keys are the bots').
func _init(seed_value: int, tune: Dictionary = {}) -> void:
	rng.seed = seed_value
	var tab := table()
	for key: String in TUNABLES:
		if tune.has(key):
			_set_num(key, tune[key])
		elif tab.has(key):
			_set_num(key, tab[key])
	hype = clampf(hype_start, 0.0, 100.0)
	_jog_a = 1.0 - exp(-DT / jog_tau)
	var n := maxi(MIXES + 1, tracks().size())
	for i in n:
		order.append(i)
	for i in range(n - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var k := order[i]
		order[i] = order[j]
		order[j] = k
	tempo_sign = -1.0 if rng.randf() < 0.5 else 1.0
	for i in MIXES:
		var s := -1.0 if rng.randf() < 0.5 else 1.0
		cue_off[i] = s * rng.randf_range(float(cue_off_lo[i]), float(cue_off_hi[i]))
	band_now = band_of(hype)
	# Deck A plays from the set's start, placed so that its beat 0 is mix 1's first beat.
	track[0] = order[0]
	pos[0] = fposmod(rb, TRACK_BEATS)
	_ev("cue", {"deck": 0, "track": track[0], "id": _track_id(track[0]), "pos": pos[0], "room": true})


func _set_num(key: String, v: Variant) -> void:
	var cur: Variant = get(key)
	if cur is Array:
		set(key, (v as Array).duplicate() if v is Array else cur)
	elif cur is int:
		set(key, int(v))
	else:
		set(key, float(v))


func _track_id(i: int) -> String:
	var rows := tracks()
	return str((rows[i] as Dictionary).get("id", "")) if i < rows.size() else str(i)


func _ev(name: String, more: Dictionary = {}) -> void:
	if keep_events:
		var e := more.duplicate() if not more.is_empty() else {}
		e["name"] = name
		events.append(e)
	stats[name] = int(stats.get(name, 0)) + 1
	if trace_on:
		trace.append(name)


func _add(dh: float) -> void:
	hype = clampf(hype + dh, 0.0, 100.0)


# ---- the tick ----

## One 60 Hz step.
func tick() -> void:
	if phase == DONE:
		return
	t += 1
	var b := 1 - room
	_controls(b)
	# Speeds: the room deck at 1.0 (or gliding there after a hand-over), deck B by the record, the pitch
	# and the jog.
	if _glide_done < glide_beats:
		_glide_done += TICK_BEATS
		speed[room] = lerpf(_glide_from, 1.0, clampf(_glide_done / maxf(0.001, glide_beats), 0.0, 1.0))
	else:
		speed[room] = 1.0
	speed[b] = native[b] * (1.0 + pitch) + jog_rate if playing[b] else 0.0
	for d in 2:
		if playing[d]:
			pos[d] = fposmod(pos[d] + speed[d] * TICK_BEATS, TRACK_BEATS)
	rb += speed[room] * TICK_BEATS
	if playing[b]:
		err = wrapf(pos[b] - pos[room], -0.5, 0.5)
		if not locked and absf(err) <= lock_beat:
			locked = true
			_ev("locked")
		elif locked and absf(err) > lock_off:
			locked = false
			_ev("unlocked")
	else:
		err = 0.0
	if (phase == BLEND or phase == ENDING) and xf >= xf_land:
		_hand_over()
	while phase != DONE and floori(rb) > last_n:
		last_n += 1
		_beat(last_n)
	in_jog_pt = 0.0
	in_pitch_pt = 0.0
	in_xf_pt = 0.0


## The jog, the pitch (with its magnet) and the crossfader from this tick's input.
func _controls(b: int) -> void:
	if playing[b]:
		var target := 0.0
		if in_jog_key != 0:
			target = clampf(float(in_jog_key) * jog_key, -jog_max, jog_max)
		else:
			target = clampf(in_jog_pt * jog_beat_per_pt / TICK_BEATS, -jog_max, jog_max)
		jog_rate += (target - jog_rate) * _jog_a
	else:
		jog_rate = 0.0
	pitch = clampf(pitch - in_pitch_pt * pitch_per_pt + float(in_pitch_key) * pitch_key_rate * DT, -pitch_max, pitch_max)
	if not in_pitch_touch and in_pitch_key == 0 and in_pitch_pt == 0.0 and playing[b]:
		var r := native[b] * (1.0 + pitch) - 1.0
		if r != 0.0 and absf(r) < magnet:
			r *= exp(-DT / magnet_tau)
			if absf(r) < 1e-7:
				r = 0.0
			pitch = (1.0 + r) / native[b] - 1.0
	xf = clampf(xf + in_xf_pt / xf_span_pt + float(in_xf_key) * xf_key_rate * DT, 0.0, 1.0)


## A whole room beat n crossed: the phase changes that start on it, then the judging.
func _beat(n: int) -> void:
	match phase:
		INTRO:
			if n >= mix_start:
				_start_cue(n)
		CUE:
			if n >= mix_start + CUE_BEATS:
				phase = BLEND
				_ev("blend")
		BLEND:
			if n >= mix_start + CUE_BEATS + BLEND_BEATS:
				phase = ENDING
				_ev("ending")
		SOLO:
			if n >= next_start:
				mix += 1
				_start_cue(n)
		OUTRO:
			if n >= outro_end:
				_finish(false)
				return
	var rel := posmod(n - mix_start, PHRASE)
	_ev("beat", {"n": n, "bar": posmod(n - mix_start, BAR) == 0, "phrase": rel == 0})
	if phase == CUE or phase == BLEND or phase == ENDING or phase == SOLO:
		_judge(n)


## Deck B cued at the room deck's whole beat plus the mix's offset.
func _start_cue(n: int) -> void:
	mix_start = n
	phase = CUE
	m_cued[mix] = true
	var b := 1 - room
	track[b] = order[mix + 1]
	native[b] = 1.0 + tempo_sign * float(tempo_err[mix]) * (-1.0 if mix == 2 else 1.0)
	pitch = 0.0
	jog_rate = 0.0
	var at := roundf(pos[room] - (rb - float(n)))
	pos[b] = fposmod(at + cue_off[mix] + (rb - float(n)), TRACK_BEATS)
	playing[b] = true
	speed[b] = native[b]
	err = wrapf(pos[b] - pos[room], -0.5, 0.5)
	locked = false
	_ev("cue", {"deck": b, "track": track[b], "id": _track_id(track[b]), "pos": pos[b], "room": false})


## Section 6 and 11.2's per-beat table, in its order.
func _judge(n: int) -> void:
	var b := 1 - room
	var both := playing[b] and xf >= xf_both
	if both:
		m_both[mix] += 1
		var e := absf(err)
		if e <= lock_beat:
			# No lock gain once the blend is over (stage B): staying blended past its end must not hold a
			# high average; only the ENDING loss counts then.
			if phase != ENDING:
				_add(lock_gain + streak_bonus * float(mini(streak, streak_full)) / float(maxi(1, streak_full)))
			streak += 1
			m_locked[mix] += 1
			lock_run += 1
			m_longest[mix] = maxi(m_longest[mix], lock_run)
			gallop_run = 0
		elif e <= loose_beat:
			_add(-loose_loss)
			lock_run = 0
			gallop_run = 0
		else:
			_add(-gallop_loss)
			streak = 0
			lock_run = 0
			gallop_run += 1
			if gallop_run == eee_after:
				_ev("eee")
	else:
		lock_run = 0
		gallop_run = 0
	if phase == ENDING:
		_add(-ending_loss)
	elif not both:
		hype = move_toward(hype, hype_rest, rest_step)
	hype_sum += hype
	judged += 1
	if trace_on:
		trace.append("%d:%.3f" % [n, hype])
	var nb := band_of(hype, bands)
	if nb != band_now:
		_ev("band", {"from": band_now, "to": nb})
		band_now = nb
		if nb == BAND_IDS.size() - 1:
			_ev("kolek_nod")
	if not shades_done and hype >= shades_hype:
		shades_done = true
		_ev("shades")
	cold_run = cold_run + 1 if hype < cold_hype else 0
	if cold_run >= cold_beats:
		_ev("dj_back")
		_finish(true)


## The fader landed on B in BLEND or ENDING: the bonuses, then B becomes the room's deck.
func _hand_over() -> void:
	var b := 1 - room
	var e := absf(err)
	var bars := phrase_bars()
	var on_bar := absf(rb - float(bars[0])) <= clean_window or absf(rb - float(bars[1])) <= clean_window
	var clean := on_bar and e <= lock_beat
	var hard := e > loose_beat
	if clean:
		_add(clean_bonus)
	if hard:
		_add(-hard_loss)
	m_clean[mix] = clean
	m_done[mix] = true
	_ev("landed", {"clean": clean, "hard": hard})
	var was_ending := phase == ENDING
	playing[room] = false
	speed[room] = 0.0
	_glide_from = native[b] * (1.0 + pitch)
	_glide_done = 0.0
	room = b
	native[b] = 1.0
	pitch = 0.0
	jog_rate = 0.0
	xf = 0.0
	# The room's clock follows the new room deck (keeps rb and its position the same within a beat).
	rb += err
	err = 0.0
	locked = false
	_ev("handover", {"room": room})
	_ev("mix_done", {"i": mix, "grade": grade(mix)})
	if mix == MIXES - 1:
		phase = OUTRO
		outro_end = last_n + OUTRO_BEATS
	elif was_ending:
		phase = SOLO
		next_start = ceili(rb / float(BAR)) * BAR
		if next_start <= last_n:
			next_start += BAR
	else:
		phase = SOLO
		next_start = mix_start + CUE_BEATS + BLEND_BEATS


func _finish(by_dj: bool) -> void:
	phase = DONE
	early = by_dj
	tier = 0 if early else tier_of(avg(), tiers)
	playing[1 - room] = false
	_ev("over", {"tier": tier, "avg": avg(), "grades": grades(), "longest_bars": longest_bars(), "early": early})


## The ✕: the set ends at once, with no result (no `over` event, nothing paid, not counted).
func abort() -> void:
	if phase == DONE:
		return
	phase = DONE
	aborted = true
	playing[1 - room] = false


# ---- queries for the view ----

func deck_b() -> int:
	return 1 - room


func phase_name() -> String:
	return PHASE_NAMES[phase]


## A deck's speed without the jog: the lanes' beat spacing (a wrong tempo spreads away from NOW).
func tempo(d: int) -> float:
	if not playing[d]:
		return 0.0
	if d == room:
		return speed[room]
	return native[d] * (1.0 + pitch)


## Deck B's tempo against the room's: 0 when the pitch is right.
func tempo_residual() -> float:
	var b := 1 - room
	return native[b] * (1.0 + pitch) - 1.0 if playing[b] else 0.0


## The phase meter's lit boxes: 4/3/2/1/0 at |err| <= 0.07 / 0.15 / 0.25 / 0.35 / more.
func meter() -> int:
	if not playing[1 - room]:
		return 0
	var e := absf(err)
	if e <= lock_beat:
		return 4
	if e <= loose_beat:
		return 3
	if e <= 0.25:
		return 2
	if e <= 0.35:
		return 1
	return 0


## The crowd's band now (0 cold .. 4 PIEC).
func band() -> int:
	return band_of(hype, bands)


static func band_of(h: float, edges: Array = [25.0, 50.0, 75.0, 90.0]) -> int:
	var i := 0
	for edge: Variant in edges:
		if h >= float(edge):
			i += 1
	return i


## A deck's gain in the room, equal power across the fader (the room deck alone at 1).
func gain(d: int) -> float:
	var b := 1 - room
	if not playing[d]:
		return 0.0
	if not playing[b]:
		return 1.0 if d == room else 0.0
	return cos(xf * PI * 0.5) if d == room else sin(xf * PI * 0.5)


## Deck B is only on the pre-listen (the fader under xf_both).
func thin() -> bool:
	return playing[1 - room] and xf < xf_both


func blend_from() -> int:
	return mix_start + CUE_BEATS


func blend_to() -> int:
	return mix_start + CUE_BEATS + BLEND_BEATS


## The current mix's gold phrase bars (room beats): the clean hand-over's two chances.
func phrase_bars() -> Array[int]:
	return [mix_start + CUE_BEATS + PHRASE, mix_start + CUE_BEATS + BLEND_BEATS]


## Where deck d's track will be (beats) when the room clock reads r, at today's tempo (the lanes draw
## the blend zone and the phrase bars with it).
func room_to_deck(d: int, r: float) -> float:
	return pos[d] + (r - rb) * tempo(d)


## The average over the beats played (0 before the first).
func avg() -> float:
	return hype_sum / float(judged) if judged > 0 else 0.0


static func tier_of(a: float, edges: Array = [35.0, 60.0, 82.0]) -> int:
	var i := 0
	for edge: Variant in edges:
		if a >= float(edge):
			i += 1
	return i


## A mix's locked share of its beats with both decks in.
func locked_share(i: int) -> float:
	return float(m_locked[i]) / float(maxi(1, m_both[i]))


## A mix's grade id: CZYSTO (>= 0.75 and clean), DOBRZE (>= 0.5), KRZYWO (>= 0.2), GALOP, "-" not reached.
func grade(i: int) -> String:
	if not m_cued[i]:
		return NOT_REACHED
	var share := locked_share(i)
	if share >= 0.75 and m_clean[i]:
		return GRADE_IDS[0]
	if share >= 0.5:
		return GRADE_IDS[1]
	if share >= 0.2:
		return GRADE_IDS[2]
	return GRADE_IDS[3]


func grades() -> Array[String]:
	var out: Array[String] = []
	for i in MIXES:
		out.append(grade(i))
	return out


func longest_beats() -> int:
	return maxi(m_longest[0], maxi(m_longest[1], m_longest[2]))


func longest_bars() -> float:
	return float(longest_beats()) / float(BAR)


func tip_of(tr: int) -> int:
	return int(tips[clampi(tr, 0, tips.size() - 1)])


func respect_of(tr: int) -> int:
	return int(respect[clampi(tr, 0, respect.size() - 1)])


## The set's result (valid once DONE and not aborted).
func result() -> Dictionary:
	var shares: Array[float] = []
	for i in MIXES:
		shares.append(locked_share(i))
	return {"tier": tier, "tier_id": TIER_IDS[clampi(tier, 0, 3)], "avg": avg(), "grades": grades(),
			"longest_bars": longest_bars(), "early": early, "aborted": aborted, "seconds": float(t) / HZ,
			"locked": shares, "clean": m_clean.count(true), "tip": tip_of(tier), "respect": respect_of(tier),
			"mix": mix, "order": order.duplicate()}


# ---- the bots ----

## perfect, mid, poor or none, with decks.json's "bots" numbers and the tune's "bot.SKILL.KEY" overrides.
func bot_setup(skill: String, seed_value: int, tune: Dictionary = {}) -> void:
	_bot_skill = skill
	_bot_rng.seed = seed_value
	var bots: Variant = table().get("bots", {})
	_bot = ((bots as Dictionary).get(skill, {}) as Dictionary).duplicate(true) if bots is Dictionary else {}
	var pre := "bot.%s." % skill
	for key: String in tune:
		if key.begins_with(pre):
			_bot[key.trim_prefix(pre)] = tune[key]
	var n := int(_bot.get("delay", 0)) + 1
	_bot_err.resize(n)
	_bot_err.fill(0.0)
	_bot_res.resize(n)
	_bot_res.fill(0.0)
	_bot_i = 0
	_bot_mix = -1


## Fill the in_* fields like a player of the bot's skill: it sees err and the lane spacing `delay` ticks
## late, jogs by a P-gain with a jitter, pitches until its stop residual (never, at -1), pushes the fader
## from the blend's beat 2 over 10 beats to 0.9 and lands at its drawn beat.
func bot_input() -> void:
	in_jog_pt = 0.0
	in_pitch_pt = 0.0
	in_xf_pt = 0.0
	in_pitch_touch = false
	if _bot.is_empty():
		return
	var b := 1 - room
	var n := _bot_err.size()
	_bot_err[_bot_i % n] = err
	_bot_res[_bot_i % n] = tempo_residual()
	_bot_i += 1
	var seen_err := _bot_err[_bot_i % n]
	var seen_res := _bot_res[_bot_i % n]
	if not playing[b] or not (phase == CUE or phase == BLEND or phase == ENDING):
		return
	if _bot_mix != mix:
		_bot_mix = mix
		var land: Array = _bot.get("land", [64.0, 64.0])
		_bot_land = _bot_rng.randf_range(float(land[0]), float(land[1]))
		var stop: Array = _bot.get("pitch_stop", [-1.0, -1.0])
		_bot_stop = _bot_rng.randf_range(float(stop[0]), float(stop[1])) if float(stop[0]) >= 0.0 else -1.0
		_bot_pitch_done = false
	var jitter := float(_bot.get("jitter", 0.0))
	var pt := -seen_err * float(_bot.get("gain", 0.0))
	if jitter > 0.0:
		pt += _bot_rng.randfn(0.0, jitter)
	in_jog_pt = clampf(pt, -6.0, 6.0)
	if _bot_stop >= 0.0 and not _bot_pitch_done:
		if absf(tempo_residual()) <= _bot_stop:
			_bot_pitch_done = true
		else:
			in_pitch_pt = clampf(seen_res / pitch_per_pt * 0.02, -3.0, 3.0)
			in_pitch_touch = true
	var rel := rb - float(mix_start)
	var target := 0.0
	if rel >= 34.0:
		target = clampf((rel - 34.0) / 10.0, 0.0, 1.0) * 0.9
	if rel >= _bot_land:
		target = 1.0
	in_xf_pt = clampf((target - xf) * xf_span_pt, -10.0, 10.0)


## One whole set by a bot (the check and the tuning mode): the result, plus the digest (hype every beat
## and every event), the bounds seen on every tick, and the event counts.
static func play_bot(skill: String, seed_value: int, tune: Dictionary = {}) -> Dictionary:
	var s: RefCounted = (load("res://scripts/decks_sim.gd") as GDScript).new(seed_value, tune)
	s.keep_events = false
	s.trace_on = true
	s.bot_setup(skill, seed_value * 7919 + 13, tune)
	var lo := 100.0
	var hi := 0.0
	var avg_lo := 100.0
	var avg_hi := 0.0
	var dj_s := -1.0
	var mix_at_dj := -1
	while s.phase != DONE and s.t < BOT_MAX_TICKS:
		s.bot_input()
		s.tick()
		lo = minf(lo, s.hype)
		hi = maxf(hi, s.hype)
		avg_lo = minf(avg_lo, s.avg())
		avg_hi = maxf(avg_hi, s.avg())
	if s.early:
		dj_s = float(s.t) / HZ
		mix_at_dj = s.mix
	var r: Dictionary = s.result()
	r["digest"] = "".join(s.trace).md5_text()
	r["done"] = s.phase == DONE
	r["hype_lo"] = lo
	r["hype_hi"] = hi
	r["avg_lo"] = avg_lo
	r["avg_hi"] = avg_hi
	r["dj_back_s"] = dj_s
	r["mix_at_dj"] = mix_at_dj
	r["stats"] = (s.stats as Dictionary).duplicate()
	return r
