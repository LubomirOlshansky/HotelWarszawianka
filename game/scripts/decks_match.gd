extends Node
## Za deckami, the DJ beat-matching game in Smoła (docs/design/smola-decks.md sections 3-7, 11.3,
## 11.4 and section 12, which wins where they differ): the view, the touch and the two decks' sound.
## The rules are decks_sim.gd, ticked here at a fixed 60 Hz from an accumulator (at most MAX_TICKS a
## frame). Built in the smola-decks loop, stage B; club.gd owns it (start, pay, the room's mood).
##
## The look: padel's and the Tapczan pong's pixel art (pong_match.gd's structure): a 216-row canvas
## in a SubViewport on a CanvasLayer of the root viewport (club.gd is main's child), nearest-filtered
## over the whole screen, drawn through pixel_kit.gd. W = max(MIN_W, 216 * screen aspect): 467 on a
## 19.5:9 phone, 288 on a 4:3 iPad (MIN_W is 288, not pong's 384, so the iPad sees the whole desk).
## Top: the floor seen from the booth (the truss, the back wall and its pillars, the bar's glow, four
## rows of people, Mati front left, Pan Kołek by the right pillar, the monitors' backs); the crowd's
## band is the score (cold: phones up and two walk to the bar; polite: every third nods; moving:
## everyone bobs, arms up on the bar; hot: jumping, lasers, a strobe on the beat; PIEC: Kołek nods,
## once his sunglasses come off). Middle: two lanes scrolling through the NOW line a third from the
## left, lane A cyan (the room's deck), lane B orange (gold when locked), drawn from the beat grid
## and decks_tracks.json's `loud` (columns) and `kick` (the beat blocks' strength), the blend zone a
## gold tint, its two phrase bars the landing marks. Bottom: the desk: deck B's platter (the jog),
## the four-box phase meter and the crossfader in the middle, the pitch fader on the right. No BAS
## button and no bass cut (section 12 point 2).
##
## Touch: zones in screen points of the safe area (`zones()`, measured by check_decks.gd): the jog in
## the left 40 %, the crossfader in the bottom strip between 40 and 84 % (12 pt over the home
## indicator), the pitch on the right from 30 % down, the ✕ top right (it leaves at once: no
## receipt, no pay, the set not counted). Each finger keeps the zone it pressed in (two thumbs).
## Keys for the Mac and the checks: A/D jog, W/S pitch, Left/Right fader, Esc the ✕, Enter NA PARKIET.
## The first set of a save shows a ghost hand on the jog, the fader and (mix 2) the pitch with its
## chip; later sets the chip alone.
##
## Sound (11.4 with section 12): two AudioStreamPlayers on the bus the club's own loop uses (SFX), the
## OGGs duplicated at runtime with `loop = true` (their .import has it off); pitch_scale is the deck's
## speed (vinyl: the sound and the lane are one thing) times a small nudge that keeps the heard
## position on the sim's (within 4 ms nothing, then at most 0.6 %, a seek past 60 ms for 3 frames).
## Deck B is on the pre-listen at -12 dB while the fader is under the both-in zone; then both follow
## the equal-power fader. No bus, no effect. One-shots and cues come through `sound` and `cue`; none
## headless (no players either). The lanes are drawn AudioServer.get_output_latency() behind the sim
## so what is seen at NOW is what is heard (section 12 point 7: one constant for the phone to trim).
##
## Cost: nothing while no set is on (no process, the layer hidden, the sim null). During a set the
## city's 3D is off (club.gd, GameCtx.city_drawn); the frame is one canvas of about 467 x 216 px,
## at most 1100 untextured rects (check_decks.gd reads `Kit.rects`), one small native Control (the
## ✕), two Vorbis decodes. Nothing allocated per frame but the sim's event dictionaries.

const Sim := preload("res://scripts/decks_sim.gd")
const Kit := preload("res://scripts/pixel_kit.gd")
const Room := preload("res://scripts/tapczan_room.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")
const Access := preload("res://scripts/access.gd")

const H := 216
const MIN_W := 288
const BEAT_PX := 24.0
const LANE_A := 121.0
const LANE_B := 136.0
const LANE_H := 13.0
const DESK_Y := 152.0
const MAX_TICKS := 6
const RESULT_AFTER := 1.2
const AUTO_DONE := 2.5
## The club's loop level (club.gd MUSIC_DB) for the room's deck; deck B on the pre-listen under it.
const MUSIC_DB := -6.0
const THIN_DB := -12.0
## The sync rule (11.4): seconds.
const SYNC_OK := 0.004
const SYNC_GAIN := 0.6
const SYNC_MAX := 0.006
const SYNC_SEEK := 0.060
const LOOP_S := float(Sim.TRACK_BEATS) * 60.0 / Sim.BPM
const TOUCH_PT := 44.0
## The crowd: people a row, the rows' feet (canvas rows) and their size.
const ROWS_N := [10, 11, 10, 9]
const ROWS_FOOT := [58.0, 72.0, 88.0, 104.0]
const ROWS_S := [0.9, 1.1, 1.35, 1.6]
const MATI_GAP := 7.0
const SHIRTS := [Color("#1a1a1e"), Color("#232327"), Color("#2e2e34"), Color("#3ad8ff"), Color("#ff3ad0"), Color("#141416"), Color("#5a2a6a")]
const MATI := Color("#7a3aa8")
const VIOLET := Color("#b44cff")
const WALL := Color("#1d3a48")
const FLOOR := Color("#29282d")
## Grade ids (decks_sim.gd) -> club_decks_ui tags.
const GRADE_TAGS := {"czysto": "g_clean", "dobrze": "g_good", "krzywo": "g_wonky", "galop": "g_gallop", "-": "g_none"}

## A set ended with a result (as the receipt shows; never for the ✕): decks_sim.gd `result()`.
signal finished(result: Dictionary)
## The view handed back (NA PARKIET, the ✕, the auto run's end).
signal closed

## Set by club.gd: screen px a point, a bot's skill for test runs ("" the player), the log.
var pt := 1.0
var auto_skill := ""
var log_on := false
## (group, tag) -> String: a line in the one language on screen (club.gd, dialogue.json).
var words := Callable()
## (name) -> void: a one-shot (sfx.gd play); (name) -> void: a UI cue (hud.gd cue).
var sound := Callable()
var cue := Callable()
## This visit already paid a set (the receipt says WIZYTA OPŁACONA); club.gd sets it.
var visit_paid := false
## The name on Pan Kołek's bubble (club.gd hands its own people's name in).
var kolek_name := ""
var inside := false
var sim: Sim
## The first set of a save: the ghost hand shows.
var first := false
var W := MIN_W

var _layer: CanvasLayer
var _vp: SubViewport
var _canvas: Node2D
var _tex: TextureRect
var _pad: Control
var _pen: Kit
var _players: Array[AudioStreamPlayer] = []
var _streams := {}
var _rows: Array = []
## Each track's lane picture as bytes (loud, kick).
var _loud: Array[PackedByteArray] = []
var _kick: Array[PackedByteArray] = []
var _acc := 0.0
var _t := 0.0
var _paused := false
var _done_t := -1.0
var _shown := false
var _shown_paid := false
var _result := {}
var _seed := 0
var _rng := RandomNumberGenerator.new()
# input gathered between ticks (points) and the held keys
var _zone_of := {}
var _jog_acc := 0.0
var _pitch_acc := 0.0
var _xf_acc := 0.0
var _key_jog := 0
var _key_pitch := 0
var _key_xf := 0
var _again_rect := Rect2()
var _floor_rect := Rect2()
# the audio sync per deck: smoothed error, frames far off, frames not measured
var _eb := PackedFloat64Array([0.0, 0.0])
var _far := PackedInt32Array([0, 0])
var _skip := PackedInt32Array([0, 0])
# the crowd (fixed per set): x, row, phase, shirt
var _cx := PackedFloat32Array()
var _crow := PackedInt32Array()
var _cph := PackedFloat32Array()
var _cshirt: Array[Color] = []
var _disp := 50.0
var _band := 2
var _beat_t := 0.0
var _bar_t := 0.0
var _cold_t := 0.0
var _shades_t := 0.0
var _nod_on := false
# words on screen
var _call := ""
var _call_t := 0.0
var _call_c := Kit.GOLD
var _bub_who := ""
var _bub := PackedStringArray()
var _bub_t := 0.0
var _bub_x := 0.0
var _mati_last := -100.0
var _cheer_last := -100.0
# the ghost hand's lessons done (jog: a lock, fader: a landing, pitch: the tempo right)
var _done_jog := false
var _done_fader := false
var _done_pitch := false
var _frame_noted := false


func _ready() -> void:
	set_process(false)


# --- in and out ---------------------------------------------------------------------------------

## A set from `seed_value`; `first_set` shows the ghost hand.
func start(seed_value: int, first_set := false) -> void:
	if _layer == null:
		_build()
	_seed = seed_value
	first = first_set
	sim = Sim.new(seed_value)
	if auto_skill != "":
		sim.bot_setup(auto_skill, seed_value * 7919 + 13)
	_rng.seed = seed_value
	_rows = Sim.tracks()
	_lanes_from_rows()
	_acc = 0.0
	_t = 0.0
	_paused = false
	_done_t = -1.0
	_shown = false
	_result = {}
	_zone_of.clear()
	_jog_acc = 0.0
	_pitch_acc = 0.0
	_xf_acc = 0.0
	_key_jog = 0
	_key_pitch = 0
	_key_xf = 0
	_disp = sim.hype
	_band = Sim.band_of(_disp, sim.bands)
	_call = ""
	_bub_t = 0.0
	_mati_last = -100.0
	_cheer_last = -100.0
	_shades_t = 0.0
	_nod_on = false
	_cold_t = 0.0
	_done_jog = false
	_done_fader = false
	_done_pitch = false
	for d in 2:
		_eb[d] = 0.0
		_far[d] = 0
		_skip[d] = 0
	inside = true
	_layer.visible = true
	_resize()
	_crowd_setup()
	_drain()
	set_process(true)
	_log("start, seed %d, tracks %s%s" % [seed_value, _order_ids(), (", bot " + auto_skill) if auto_skill != "" else ""])
	if log_on and is_inside_tree() and not _frame_noted:
		_frame_noted = true
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if inside:
				_log("frame: " + Room.frame_note()))


## The ✕: out at once, the set not counted (section 12 point 4).
func leave() -> void:
	if not inside:
		return
	if sim != null:
		sim.abort()
	_log("left (the ✕)")
	_close()


func _close() -> void:
	inside = false
	_layer.visible = false
	set_process(false)
	for p in _players:
		p.stop()
		p.stream = null
	sim = null
	_zone_of.clear()
	_log("closed")
	closed.emit()


func _order_ids() -> String:
	var ids := PackedStringArray()
	for i: int in sim.order:
		ids.append(str((_rows[i] as Dictionary).get("id", i)) if i < _rows.size() else str(i))
	return ",".join(ids)


func _lanes_from_rows() -> void:
	if _loud.size() == _rows.size():
		return
	_loud.clear()
	_kick.clear()
	for row: Dictionary in _rows:
		var l := PackedByteArray()
		var k := PackedByteArray()
		for v: Variant in row.get("loud", []):
			l.append(int(v))
		for v: Variant in row.get("kick", []):
			k.append(int(v))
		l.resize(Sim.TRACK_BEATS * 8)
		k.resize(Sim.TRACK_BEATS * 8)
		_loud.append(l)
		_kick.append(k)


func _w(tag: String) -> String:
	if words.is_valid():
		var s := str(words.call("club_decks_ui", tag))
		if s != "":
			return s
	return tag


func _line(group: String, tag: String) -> String:
	return str(words.call(group, tag)) if words.is_valid() else ""


func _snd(n: String) -> void:
	if sound.is_valid():
		sound.call(n)


func _cue(n: String) -> void:
	if cue.is_valid():
		cue.call(n)


func _log(text: String) -> void:
	if log_on:
		print("decks: " + text)


func _track_name(i: int) -> String:
	return str((_rows[i] as Dictionary).get("name", "")) if i >= 0 and i < _rows.size() else ""


# --- building -----------------------------------------------------------------------------------

func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 30
	add_child(_layer)
	_vp = SubViewport.new()
	_vp.size = Vector2i(MIN_W, H)
	_vp.disable_3d = true
	_vp.transparent_bg = false
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vp.snap_2d_transforms_to_pixel = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_scene)
	_vp.add_child(_canvas)
	_pen = Kit.new(_canvas)
	_tex = TextureRect.new()
	_tex.texture = _vp.get_texture()
	_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_tex)
	_pad = Control.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	_layer.add_child(_pad)
	_layer.visible = false
	# Two decks on the club loop's bus (no players headless, as club.gd's _music_on).
	if DisplayServer.get_name() != "headless":
		for d in 2:
			var p := AudioStreamPlayer.new()
			p.bus = &"SFX"
			add_child(p)
			_players.append(p)
	get_viewport().size_changed.connect(_resize)


func _resize() -> void:
	if _vp == null:
		return
	var s := get_viewport().get_visible_rect().size
	W = maxi(MIN_W, int(round(H * s.x / maxf(s.y, 1.0))))
	_vp.size = Vector2i(W, H)


func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size


## Screen px per canvas px (KEEP_ASPECT_COVERED: the height fills unless W hit its minimum).
func _scale() -> float:
	var s := _screen()
	return maxf(s.y / float(H), s.x / float(W))


func _to_canvas(p: Vector2) -> Vector2:
	var s := _screen()
	var k := _scale()
	return Vector2((p.x - (s.x - W * k) * 0.5) / k, (p.y - (s.y - H * k) * 0.5) / k)


func _rect_to_canvas(r: Rect2) -> Rect2:
	var a := _to_canvas(r.position)
	var b := _to_canvas(r.end)
	return Rect2(a, b - a)


## The touch zones in screen px for a screen of `size_px` at `pt_px` px a point (11.3): "quit", "jog",
## "pitch", "xf". Fractions are of the safe area; the jog runs to the left edge, the pitch to the
## right one; the crossfader ends 12 pt above the bottom inset (the home indicator).
static func zones(size_px: Vector2, pt_px: float) -> Dictionary:
	var safe: Rect2 = ScreenPoints.measure(size_px)["safe"]
	var sx := safe.position.x
	var sw := safe.size.x
	var sy := safe.position.y
	var sh := safe.size.y
	var qc := Vector2(minf(size_px.x - 34.0 * pt_px, safe.end.x - 26.0 * pt_px), 34.0 * pt_px)
	var half := TOUCH_PT * 0.5 * pt_px + 4.0 * pt_px
	var jog := Rect2(0.0, 0.0, sx + 0.40 * sw, size_px.y)
	var pitch_x := sx + 0.84 * sw
	var pitch := Rect2(pitch_x, sy + 0.30 * sh, size_px.x - pitch_x, size_px.y - (sy + 0.30 * sh))
	var xf_top := sy + 0.80 * sh
	var xf := Rect2(jog.end.x, xf_top, pitch_x - jog.end.x, safe.end.y - 12.0 * pt_px - xf_top)
	return {"quit": Rect2(qc - Vector2(half, half), Vector2(half, half) * 2.0), "jog": jog, "pitch": pitch, "xf": xf}


func _zones() -> Dictionary:
	return zones(_screen(), pt)


## The zone a press at screen `p` falls in ("" none).
func _zone_at(p: Vector2) -> String:
	var z := _zones()
	for k: String in ["quit", "xf", "pitch", "jog"]:
		if (z[k] as Rect2).has_point(p):
			return k
	return ""


# --- the frame ----------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not inside or sim == null:
		return
	_t += dt
	if sim.phase != Sim.DONE:
		if not _paused:
			_acc += dt
			var n := 0
			while _acc >= Sim.DT and n < MAX_TICKS:
				_acc -= Sim.DT
				n += 1
				_feed()
				sim.tick()
				_drain()
				if sim.phase == Sim.DONE:
					break
			if _acc > Sim.DT * MAX_TICKS:
				_acc = 0.0
	if sim.phase == Sim.DONE:
		_done_t = maxf(_done_t, 0.0) + dt
		if _done_t >= RESULT_AFTER and not _shown:
			_show_result()
		if auto_skill != "" and _done_t >= RESULT_AFTER + AUTO_DONE:
			_close()
			return
	_audio()
	_fx(dt)
	_canvas.queue_redraw()
	_pad.queue_redraw()


## This tick's input into the sim: the points dragged since the last tick and the held keys (a bot's
## instead in test runs).
func _feed() -> void:
	if auto_skill != "":
		sim.bot_input()
		return
	sim.in_jog_pt = _jog_acc
	sim.in_pitch_pt = _pitch_acc
	sim.in_xf_pt = _xf_acc
	_jog_acc = 0.0
	_pitch_acc = 0.0
	_xf_acc = 0.0
	sim.in_jog_key = _key_jog
	sim.in_pitch_key = _key_pitch
	sim.in_xf_key = _key_xf
	sim.in_pitch_touch = "pitch" in _zone_of.values()


func _fx(dt: float) -> void:
	_call_t = maxf(0.0, _call_t - dt)
	_bub_t = maxf(0.0, _bub_t - dt)
	_beat_t = maxf(0.0, _beat_t - dt)
	_bar_t = maxf(0.0, _bar_t - dt)
	_shades_t = maxf(0.0, _shades_t - dt)
	_disp += (sim.hype - _disp) * (1.0 - exp(-2.0 * dt))
	# The band with 2 points of hysteresis either way.
	var up := Sim.band_of(_disp - 2.0, sim.bands)
	var down := Sim.band_of(_disp + 2.0, sim.bands)
	if up > _band:
		_band = up
	elif down < _band:
		_band = down
	_cold_t = _cold_t + dt if _band == 0 else maxf(0.0, _cold_t - dt * 2.0)
	if not _done_pitch and sim.mix == 1 and sim.playing[sim.deck_b()] and absf(sim.tempo_residual()) < sim.magnet:
		_done_pitch = true


func _say(text: String, c := Kit.GOLD, life := 1.0) -> void:
	_call = text
	_call_c = c
	_call_t = life


func _bubble(who: String, text: String, x: float, life := 3.2) -> void:
	if text == "":
		return
	_bub_who = who
	# The 5x7 font has no ellipsis: three dots instead.
	_bub = Kit.wrap(text.replace("…", "..."), 150)
	_bub_x = x
	_bub_t = life


# --- the sim's events ---------------------------------------------------------------------------

func _drain() -> void:
	if sim.events.is_empty():
		return
	for e: Dictionary in sim.events:
		_on_event(str(e["name"]), e)
	sim.events.clear()


func _on_event(n: String, e: Dictionary) -> void:
	match n:
		"cue":
			_deck_play(int(e["deck"]), int(e["track"]), float(e["pos"]))
		"beat":
			_beat_t = 0.12
			if bool(e["bar"]):
				_bar_t = 0.25
			if bool(e["phrase"]) and _band >= 3 and _t - _cheer_last > 6.0:
				_cheer_last = _t
				_snd("crowd_cheer")
		"locked":
			_cue("tick")
			Access.buzz(15, 0.5)
			_done_jog = true
		"eee":
			_snd("crowd_eee")
		"ending":
			_say(_w("ending"), Kit.ALERT, 1.5)
		"landed":
			_done_fader = true
			if bool(e["clean"]):
				_say(_w("g_clean"), Kit.GOLD, 1.4)
				_snd("crowd_cheer")
				_cheer_last = _t
			elif bool(e["hard"]):
				_say(_w("g_gallop"), Kit.ALERT, 1.2)
		"handover":
			var old := 1 - int(e["room"])
			if old < _players.size():
				_players[old].stop()
		"band":
			if _t - _mati_last >= MATI_GAP:
				_mati_last = _t
				_bubble("MATI", _line("club_decks_mati", Sim.BAND_IDS[clampi(int(e["to"]), 0, 4)]), _mati_x())
		"kolek_nod":
			if not _nod_on:
				_bubble(kolek_name, _line("club_decks_kolek", ""), W * 0.88)
			_nod_on = true
		"shades":
			_shades_t = 1.0
		"dj_back":
			_snd("vinyl_spinback")
			_cue("fail")
			for p in _players:
				p.stop()
		"mix_done":
			_log("mix %d: %s" % [int(e["i"]) + 1, str(e["grade"])])
		"over":
			_done_t = 0.0
			_log("set over: %s avg %.1f%s" % [Sim.TIER_IDS[clampi(int(e["tier"]), 0, 3)], float(e["avg"]), " (the DJ back)" if bool(e["early"]) else ""])


## The receipt is up: the result goes to club.gd (which pays once a visit).
func _show_result() -> void:
	_shown = true
	_result = sim.result()
	_shown_paid = visit_paid
	if int(_result["tier"]) >= 2:
		_cue("win")
	if int(_result["tier"]) == 3:
		_snd("crowd_cheer")
	finished.emit(_result)


## JESZCZE RAZ: a new set at once (the club pays it nothing this visit).
func _again() -> void:
	start(_seed * 31 + 7, false)


# --- the two decks' sound ----------------------------------------------------------------------

func _stream(track: int) -> AudioStream:
	if _streams.has(track):
		return _streams[track]
	var file := str((_rows[track] as Dictionary).get("file", "")) if track < _rows.size() else ""
	if file == "" or not ResourceLoader.exists(file):
		return null
	var s: AudioStream = load(file)
	if s is AudioStreamOggVorbis:
		var o := (s as AudioStreamOggVorbis).duplicate() as AudioStreamOggVorbis
		o.loop = true
		o.loop_offset = 0.0
		o.bpm = Sim.BPM
		o.beat_count = Sim.TRACK_BEATS
		s = o
	_streams[track] = s
	return s


## Deck d starts track `track` at `beats` in (a cue).
func _deck_play(d: int, track: int, beats: float) -> void:
	if d >= _players.size():
		return
	var p := _players[d]
	var s := _stream(track)
	if s == null:
		return
	p.stream = s
	p.pitch_scale = maxf(0.05, sim.speed[d] if sim.speed[d] > 0.0 else 1.0)
	p.volume_db = MUSIC_DB + (THIN_DB if d != sim.room else 0.0)
	p.play(fposmod(beats * 60.0 / Sim.BPM + AudioServer.get_time_to_next_mix(), LOOP_S))
	_eb[d] = 0.0
	_far[d] = 0
	_skip[d] = 6


## Each frame: the speed, the level and the sync of both decks (11.4).
func _audio() -> void:
	if _players.is_empty():
		return
	var done := sim.phase == Sim.DONE
	for d in 2:
		var p := _players[d]
		if not p.playing:
			continue
		if not sim.playing[d]:
			p.stop()
			continue
		if _paused:
			continue
		var g := sim.gain(d)
		if d != sim.room and sim.thin():
			p.volume_db = MUSIC_DB + THIN_DB
		else:
			p.volume_db = MUSIC_DB + linear_to_db(maxf(g, 0.001))
		var speed := 1.0 if done else sim.speed[d]
		if speed <= 0.0:
			p.stop()
			continue
		if done:
			p.pitch_scale = 1.0
			continue
		var heard := p.get_playback_position() + AudioServer.get_time_since_last_mix() * p.pitch_scale
		var sim_s := sim.pos[d] * 60.0 / Sim.BPM + _acc * speed
		var e := wrapf(sim_s - heard, -LOOP_S * 0.5, LOOP_S * 0.5)
		var nudge := 0.0
		if _skip[d] > 0:
			_skip[d] -= 1
		else:
			_eb[d] = 0.8 * _eb[d] + 0.2 * e
			_far[d] = _far[d] + 1 if absf(e) > SYNC_SEEK else 0
			if _far[d] >= 3:
				p.seek(fposmod(sim_s + AudioServer.get_time_to_next_mix(), LOOP_S))
				_far[d] = 0
				_skip[d] = 6
				_eb[d] = 0.0
			elif absf(_eb[d]) > SYNC_OK:
				nudge = clampf(SYNC_GAIN * _eb[d], -SYNC_MAX, SYNC_MAX)
		p.pitch_scale = maxf(0.05, speed * (1.0 + nudge))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_paused = true
		for p in _players:
			p.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_paused = false
		_acc = 0.0
		for p in _players:
			p.stream_paused = false


# --- touch --------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not inside or sim == null:
		return
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			var z := _zone_at(e.position)
			if z == "quit":
				leave()
			elif _shown:
				var c := _to_canvas(e.position)
				if _again_rect.has_point(c):
					_again()
				elif _floor_rect.has_point(c):
					_close()
			elif z != "":
				_zone_of[e.index] = z
		else:
			_zone_of.erase(e.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		var rel := d.relative / maxf(pt, 0.1)
		match str(_zone_of.get(d.index, "")):
			"jog":
				_jog_acc += rel.x
			"pitch":
				_pitch_acc += rel.y
			"xf":
				_xf_acc += rel.x
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.echo:
			get_viewport().set_input_as_handled()
			return
		var on := 1 if k.pressed else 0
		match k.keycode:
			KEY_A:
				_key_jog = -on
			KEY_D:
				_key_jog = on
			KEY_W:
				_key_pitch = on
			KEY_S:
				_key_pitch = -on
			KEY_LEFT:
				_key_xf = -on
			KEY_RIGHT:
				_key_xf = on
			KEY_ESCAPE:
				if k.pressed:
					leave()
			KEY_ENTER:
				if k.pressed and _shown:
					_close()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


func _draw_pad() -> void:
	var q: Rect2 = _zones()["quit"]
	var qc := q.get_center()
	_pad.draw_circle(qc, 20.0 * pt, Color(0, 0, 0, 0.45))
	var r := 7.0 * pt
	_pad.draw_line(qc - Vector2(r, r), qc + Vector2(r, r), Color(1, 1, 1, 0.95), 2.5 * pt)
	_pad.draw_line(qc + Vector2(-r, r), qc + Vector2(r, -r), Color(1, 1, 1, 0.95), 2.5 * pt)


# --- where things are (canvas px) ---------------------------------------------------------------

func _mati_x() -> float:
	return maxf(30.0, W * 0.1)


func _now_x() -> float:
	return roundf(W / 3.0)


## The desk's controls, centred in their touch zones: {jog: centre, xf: [x0, x1, y], pitch: [x, y0, y1],
## meter: centre}.
func _desk() -> Dictionary:
	var z := _zones()
	var jog := _rect_to_canvas(z["jog"])
	var xf := _rect_to_canvas(z["xf"])
	var pitch := _rect_to_canvas(z["pitch"])
	var ins := _safe_canvas()
	var jx := clampf((maxf(jog.position.x, ins.x) + jog.end.x) * 0.5, 30.0, jog.end.x - 30.0)
	var px_end := minf(pitch.end.x, W - ins.y)
	var pxc := clampf((pitch.position.x + px_end) * 0.5, pitch.position.x + 8.0, W - 10.0)
	var xfy := clampf(xf.get_center().y, DESK_Y + 20.0, H - 10.0)
	return {"jog": Vector2(jx, 184.0), "xf": [xf.position.x + 10.0, xf.end.x - 10.0, xfy],
			"pitch": [pxc, maxf(DESK_Y + 4.0, pitch.position.y + 4.0), H - 8.0], "meter": Vector2(xf.get_center().x, DESK_Y + 6.0)}


## The safe area's left and right insets in canvas px.
func _safe_canvas() -> Vector2:
	var s := _screen()
	var safe: Rect2 = ScreenPoints.measure(s)["safe"]
	var a := _to_canvas(safe.position)
	var b := _to_canvas(safe.end)
	return Vector2(maxf(0.0, a.x), maxf(0.0, W - b.x))


## The latency offset in beats for deck d (what is seen at NOW is what is heard).
func _lat_beats(d: int) -> float:
	return AudioServer.get_output_latency() * Sim.BPM / 60.0 * maxf(0.0, sim.speed[d])


## The room's beat now as drawn (the latency behind).
func _room_beat() -> float:
	return sim.rb - _lat_beats(sim.room)


# --- the crowd ------------------------------------------------------------------------------------

func _crowd_setup() -> void:
	_cx.clear()
	_crow.clear()
	_cph.clear()
	_cshirt.clear()
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for row in ROWS_N.size():
		var n: int = ROWS_N[row]
		for i in n:
			var x := (float(i) + 0.5 + r.randf_range(-0.3, 0.3) + (0.5 if row % 2 == 1 else 0.0)) * W / float(n + 0.5)
			_cx.append(x)
			_crow.append(row)
			_cph.append(r.randf())
			_cshirt.append(SHIRTS[r.randi() % SHIRTS.size()])


# --- drawing --------------------------------------------------------------------------------------

func _draw_scene() -> void:
	if sim == null:
		return
	_pen.o = Vector2.ZERO
	_draw_floor()
	if _shown:
		_draw_result()
		return
	_draw_lanes()
	_draw_desk()
	_draw_chips()
	_draw_words()
	_draw_ghost()


## Every rect of one frame drawn on a dry pen (check_decks.gd: the budget), the count.
func count_rects() -> int:
	var keep := _pen.ci
	_pen.ci = null
	_pen.rects = 0
	_draw_scene()
	var n := _pen.rects
	_pen.ci = keep
	return n


func _draw_floor() -> void:
	var p := _pen
	var w := float(W)
	var beat := fposmod(_room_beat(), 1.0)
	var hot := _band >= 3
	p.rect(0, 0, w, DESK_Y, Kit.VOID)
	# The back wall and its cyan top line, the floor.
	p.rect(0, 8, w, 36, WALL)
	p.rect(0, 8, w, 1, Color("#3ad8ff"))
	p.rect(0, 44, w, 74, FLOOR)
	p.rect(0, 44, w, 2, FLOOR.darkened(0.3))
	# The bar's glow at the back right, brighter with the room.
	var glow := 0.10 + 0.08 * float(_band)
	p.rect(w * 0.62, 30, w * 0.33, 14, Color(Kit.AMBER, glow))
	p.rect(w * 0.64, 34, w * 0.29, 10, Color(Kit.AMBER_L, glow * 0.8))
	p.rect(w * 0.62, 42, w * 0.33, 3, Kit.WOOD_D)
	# Red LED bars on the wall, the pillars.
	p.rect(w * 0.08, 14, 2, 24, Color("#ff2a2a"))
	p.rect(w * 0.36, 14, 2, 24, Color("#ff2a2a"))
	for f: float in [0.18, 0.5, 0.82]:
		p.rect(w * f - 5, 8, 10, 100, Color("#323a46"))
		p.rect(w * f - 5, 8, 3, 100, Color("#3d4757"))
	# The truss and its six heads (lit on the beat when the room moves).
	p.rect(0, 4, w, 4, Color("#4a4a52"))
	var cols := [VIOLET, Color("#3ad8ff"), Color("#ff3ad0"), Color.WHITE, Color("#3ad8ff"), VIOLET]
	for i in 6:
		var lit := _band >= 2 and (int(_room_beat()) + i) % 3 == 0
		p.rect(w * (i + 0.5) / 6.0 - 2, 6, 5, 4, cols[i] if lit else (cols[i] as Color).darkened(0.6))
	# Lasers in the hot bands: six green lines fanning down from the truss over the heads, swinging
	# (not behind the receipt; dimmer with reduced flashing).
	if hot and not _shown:
		var lc := Color(0.35, 1.0, 0.45, 0.8 if not Access.calm else 0.4)
		for i in 4:
			var a := (float(i) / 3.0 - 0.5) * 2.2 + sin(_t * 1.3 + i * 0.7) * 0.25
			var dx := sin(a) * 36.0
			for k in 6:
				# A stair of one-pixel steps: across, then down.
				var lx := w * 0.5 + dx * k
				var ly := 9.0 + k * 7.0
				p.rect(minf(lx, lx + dx), ly, maxf(1.0, absf(dx)), 1, lc)
				p.rect(lx + dx, ly, 1, 7, lc)
	if _shown:
		# Behind the receipt the floor is only its room (the rect budget: the card's words).
		p.rect(0, 44, w, 74, Color(Kit.VOID, 0.5))
		p.rect(0, 118, w, H - 118, Kit.VOID)
		return
	_draw_crowd(beat)
	# Pan Kołek by the right pillar, arms folded, the shades.
	_draw_kolek(w * 0.88, 100.0, beat)
	# The monitors' backs.
	for f: float in [0.3, 0.7]:
		p.rect(w * f - 20, 108, 40, 10, Color("#141416"))
		p.rect(w * f - 20, 108, 40, 1, Kit.SLATE_L)
	_draw_mati(_mati_x(), 118.0, beat)
	# The strobe on the beat, hot only, never with reduced flashing (access.gd).
	if hot and not Access.calm and _beat_t > 0.06:
		p.rect(0, 0, w, DESK_Y, Color(1, 1, 1, 0.25))


func _draw_crowd(beat: float) -> void:
	var p := _pen
	var band := _band
	for i in _cx.size():
		var row := _crow[i]
		var s: float = ROWS_S[row]
		var foot: float = ROWS_FOOT[row]
		var x := _cx[i]
		var ph := fposmod(beat + _cph[i] * 0.3, 1.0)
		var bump := 1.0 - absf(ph * 2.0 - 1.0)
		var lift := 0.0
		var arms := false
		var phone := false
		match band:
			0:
				phone = i % 13 == 4
				# Two drift toward the bar while it stays cold.
				if i == 3 or i == 15:
					x = lerpf(x, W * 0.8, clampf(_cold_t / 12.0, 0.0, 1.0))
			1:
				lift = bump if i % 3 == 0 else 0.0
			2:
				lift = 2.0 * bump
				arms = _bar_t > 0.0 and i % 2 == 0
			_:
				lift = 3.0 * bump
				arms = i % 3 != 2 or _bar_t > 0.0
		_person(x, foot - roundf(lift), s, _cshirt[i], Kit.SKIN[i % 4], [Kit.HAIR_BK, Kit.HAIR_BR, Kit.HAIR_BL][i % 3], arms, phone)


## One of the crowd, facing the booth: legs, body, head, hair (s its size; about 17 px at 1).
func _person(x: float, foot: float, s: float, shirt: Color, skin: Color, hair: Color, arms: bool, phone: bool) -> void:
	var p := _pen
	p.rect(x - 2.0 * s, foot - 5.0 * s, 4.0 * s, 5.0 * s, Kit.JEANS)
	p.rect(x - 3.0 * s, foot - 12.0 * s, 6.0 * s, 7.0 * s, shirt)
	p.rect(x - 2.5 * s, foot - 17.0 * s, 5.0 * s, 5.0 * s, skin)
	p.rect(x - 2.5 * s, foot - 17.5 * s, 5.0 * s, 1.5 * s, hair)
	if arms:
		p.rect(x - 4.0 * s, foot - 19.0 * s, 1.0 * s, 7.0 * s, skin)
		p.rect(x + 3.0 * s, foot - 19.0 * s, 1.0 * s, 7.0 * s, skin)
	if phone:
		p.rect(x + 3.0 * s, foot - 22.0 * s, 2.0 * s, 3.0 * s, Color.WHITE)


## Mati front left in his violet shirt: hands over his eyes when cold, arms up when hot.
func _draw_mati(x: float, foot: float, beat: float) -> void:
	var p := _pen
	var s := 2.2
	var hop := (3.0 if _band >= 3 else (1.0 if _band >= 2 else 0.0)) * (1.0 - absf(fposmod(beat, 1.0) * 2.0 - 1.0))
	foot -= roundf(hop)
	var skin: Color = Kit.SKIN[1]
	p.rect(x - 2.0 * s, foot - 5.0 * s, 4.0 * s, 5.0 * s, Kit.JEANS)
	p.rect(x - 3.0 * s, foot - 12.0 * s, 6.0 * s, 7.0 * s, MATI)
	p.rect(x - 3.0 * s, foot - 12.0 * s, 2.0 * s, 7.0 * s, MATI.darkened(0.25))
	p.rect(x - 2.5 * s, foot - 17.0 * s, 5.0 * s, 5.0 * s, skin)
	p.rect(x - 2.5 * s, foot - 17.5 * s, 5.0 * s, 1.5 * s, Kit.HAIR_BR)
	if _band == 0:
		# A hand over his eyes.
		p.rect(x - 3.0 * s, foot - 15.5 * s, 6.0 * s, 1.5 * s, skin.darkened(0.1))
		p.rect(x + 3.0 * s, foot - 15.0 * s, 1.0 * s, 4.0 * s, MATI)
	else:
		p.rect(x - 1.5 * s, foot - 15.0 * s, 1.0 * s, 1.0 * s, Kit.INK)
		p.rect(x + 0.5 * s, foot - 15.0 * s, 1.0 * s, 1.0 * s, Kit.INK)
		if _band >= 3 or (_band == 2 and _bar_t > 0.0):
			p.rect(x - 4.0 * s, foot - 20.0 * s, 1.0 * s, 8.0 * s, MATI)
			p.rect(x + 3.0 * s, foot - 20.0 * s, 1.0 * s, 8.0 * s, MATI)


## Pan Kołek: the long black coat, a pale face, the sunglasses (off for a second on `shades`); he
## nods on the beat once the room is an oven.
func _draw_kolek(x: float, foot: float, beat: float) -> void:
	var p := _pen
	var s := 1.7
	var nod := 1.0 if (_nod_on and _band >= 4 and fposmod(beat, 1.0) < 0.3) else 0.0
	p.rect(x - 3.5 * s, foot - 13.0 * s, 7.0 * s, 13.0 * s, Color("#0b0b0d"))
	p.rect(x - 3.5 * s, foot - 9.0 * s, 7.0 * s, 1.5 * s, Color("#1d1d22"))
	var hy := foot - 18.0 * s + nod
	p.rect(x - 2.5 * s, hy, 5.0 * s, 5.0 * s, Color("#d8c8b8"))
	p.rect(x - 2.5 * s, hy - 1.0 * s, 5.0 * s, 1.5 * s, Color("#0b0b0d"))
	if _shades_t > 0.0:
		p.rect(x - 1.5 * s, hy + 2.0 * s, 1.0 * s, 1.0 * s, Kit.INK)
		p.rect(x + 0.5 * s, hy + 2.0 * s, 1.0 * s, 1.0 * s, Kit.INK)
	else:
		p.rect(x - 2.5 * s, hy + 1.5 * s, 5.0 * s, 1.5 * s, Color("#050505"))


func _draw_lanes() -> void:
	var p := _pen
	var w := float(W)
	var now := _now_x()
	p.rect(0, DESK_Y - 33, w, 33, Color("#0e0f13"))
	p.rect(0, LANE_A, w, LANE_H, Color("#17191f"))
	p.rect(0, LANE_B, w, LANE_H, Color("#17191f"))
	var rbv := _room_beat()
	# The blend zone: a gold tint behind both lanes, its two phrase bars the landing marks.
	if sim.phase == Sim.CUE or sim.phase == Sim.BLEND or sim.phase == Sim.ENDING:
		var x0 := now + (float(sim.blend_from()) - rbv) * BEAT_PX
		var x1 := now + (float(sim.blend_to()) - rbv) * BEAT_PX
		var a := clampf(x0, 0.0, w)
		var b := clampf(x1, 0.0, w)
		if b > a:
			p.rect(a, LANE_A - 1, b - a, LANE_B + LANE_H - LANE_A + 2, Color(Kit.GOLD, 0.2))
		for bar: int in sim.phrase_bars():
			var bx := now + (float(bar) - rbv) * BEAT_PX
			if bx >= 0.0 and bx < w:
				p.rect(bx - 1, LANE_A - 2, 2, LANE_B + LANE_H - LANE_A + 4, Kit.GOLD)
	var room := sim.room
	var b_deck := sim.deck_b()
	var ending := sim.phase == Sim.ENDING
	var a_col := Kit.THEM
	if ending and int(_t * 4.0) % 2 == 0:
		a_col = Kit.ALERT
	_lane(LANE_A, room, a_col)
	_lane(LANE_B, b_deck, Kit.GOLD if sim.locked else Kit.US)
	# The NOW line.
	p.rect(now - 1, LANE_A - 3, 2, LANE_B + LANE_H - LANE_A + 6, Kit.LINE)
	if ending:
		var t := _w("ending")
		var tw := Kit.text_w(t)
		p.rect(now + 6, LANE_A + 1, tw + 6, 11, Kit.INK)
		p.text(t, now + 9, LANE_A, Kit.ALERT)


## One deck's lane: its track's loudness in 3 px columns, a block on every beat (taller on the bar's
## "1"), a gold line on every phrase; spacing by the deck's tempo (a wrong tempo spreads from NOW).
func _lane(y: float, d: int, c: Color) -> void:
	var p := _pen
	var w := float(W)
	if not sim.playing[d]:
		return
	var tr := sim.track[d]
	if tr < 0 or tr >= _loud.size():
		return
	var loud := _loud[tr]
	var kick := _kick[tr]
	var now := _now_x()
	var td := maxf(0.5, sim.tempo(d))
	var px_beat := BEAT_PX / td
	var pos := sim.pos[d] - _lat_beats(d)
	var j0 := floori((pos - now / px_beat) * 8.0)
	var j1 := ceili((pos + (w - now) / px_beat) * 8.0)
	var dim := Color(c, 0.45)
	var mid := y + LANE_H * 0.5
	for j in range(j0, j1 + 1):
		var x := now + (float(j) / 8.0 - pos) * px_beat
		if x < -3.0 or x >= w:
			continue
		var i := posmod(j, Sim.TRACK_BEATS * 8)
		if j % 8 == 0:
			var beat_i := posmod(j / 8, Sim.TRACK_BEATS)
			var tall := beat_i % 4 == 0
			var kc := c if kick[i] >= 40 else c.darkened(0.3)
			var kh := LANE_H if tall else 7.0
			p.rect(x, mid - kh * 0.5, 3, kh, kc)
			if beat_i % 16 == 0:
				p.rect(x - 2, y - 1, 1, LANE_H + 2, Kit.GOLD)
		else:
			var h := maxf(1.0, roundf(float(loud[i]) / 99.0 * (LANE_H - 2.0)))
			p.rect(x, mid - h * 0.5, 3, h, dim)


func _draw_desk() -> void:
	var p := _pen
	var w := float(W)
	var k := _desk()
	p.rect(0, DESK_Y, w, H - DESK_Y, Color("#1a1c21"))
	p.rect(0, DESK_Y, w, 1, Kit.SLATE_L)
	# The three units' plates: the deck, the mixer, the pitch.
	var xfa: Array = k["xf"]
	var pfa: Array = k["pitch"]
	var jcc: Vector2 = k["jog"]
	p.card(jcc.x - 32, DESK_Y + 4, 64, H - DESK_Y - 7, Color("#23262d"), Kit.SLATE_L)
	p.card(float(xfa[0]) - 8, DESK_Y + 2, float(xfa[1]) - float(xfa[0]) + 16, H - DESK_Y - 5, Color("#23262d"), Kit.SLATE_L)
	p.card(float(pfa[0]) - 10, float(pfa[1]) - 4, 21, float(pfa[2]) - float(pfa[1]) + 7, Color("#23262d"), Kit.SLATE_L)
	# The platter: a dark disc in 2-row bands, the label, a groove mark turned by deck B's position.
	var jc: Vector2 = k["jog"]
	var r := 26.0
	var b_on := sim.playing[sim.deck_b()]
	var yy := -r
	while yy <= r:
		var hw := r * sqrt(maxf(0.0, 1.0 - (yy / r) * (yy / r)))
		p.rect(jc.x - hw, jc.y + yy, hw * 2.0, 2, Color("#0c0c0e") if int(yy) % 4 == 0 else Color("#141418"))
		yy += 2.0
	var lc := Kit.GOLD if sim.locked else (Kit.US if b_on else Kit.SLATE_L)
	p.rect(jc.x - 5, jc.y - 6, 11, 13, lc)
	p.rect(jc.x - 7, jc.y - 4, 15, 9, lc)
	var ang := TAU * fposmod(sim.pos[sim.deck_b()] if b_on else 0.0, 1.0) * 0.5
	p.rect(jc.x + cos(ang) * 20.0 - 1, jc.y + sin(ang) * 20.0 - 1, 3, 3, Kit.LINE)
	# The phase meter: four boxes, early or late beside them.
	var mc: Vector2 = k["meter"]
	var lit := sim.meter()
	for i in 4:
		var on := i < lit
		p.rect(mc.x - 19 + i * 10, mc.y, 8, 6, (Kit.GOLD if lit == 4 else Kit.US) if on else Kit.SLATE_L)
	if b_on and lit < 4:
		var early := sim.err > 0.0
		p.rect(mc.x + (24 if early else -27), mc.y + 1, 3, 4, Kit.LINE)
	# The crossfader: A at the left, B at the right.
	var xf: Array = k["xf"]
	var x0 := float(xf[0])
	var x1 := float(xf[1])
	var fy := float(xf[2])
	p.rect(x0, fy - 2, x1 - x0, 5, Kit.VOID)
	p.rect(x0 + 1, fy, x1 - x0 - 2, 1, Kit.SLATE_L)
	p.rect(x0, fy - 6, 3, 13, Kit.THEM)
	p.rect(x1 - 3, fy - 6, 3, 13, Kit.US)
	for q in range(1, 4):
		p.rect(lerpf(x0, x1, q / 4.0), fy + 5, 1, 3, Kit.CHALK_D)
	var kx := lerpf(x0 + 4, x1 - 4, sim.xf)
	p.rect(kx - 4, fy - 7, 8, 14, Kit.CHROME)
	p.rect(kx - 1, fy - 7, 2, 14, Kit.INK)
	# The pitch fader: up is faster, a detent in the middle.
	var pf: Array = k["pitch"]
	var px := float(pf[0])
	var py0 := float(pf[1])
	var py1 := float(pf[2])
	var pc := (py0 + py1) * 0.5
	p.rect(px - 2, py0, 5, py1 - py0, Kit.VOID)
	p.rect(px, py0 + 1, 1, py1 - py0 - 2, Kit.SLATE_L)
	p.rect(px - 7, pc, 15, 1, Kit.CHALK_D)
	var ky := pc - sim.pitch / maxf(0.001, sim.pitch_max) * (py1 - py0) * 0.5
	var right := b_on and absf(sim.tempo_residual()) < sim.magnet
	p.rect(px - 6, ky - 3, 13, 6, Kit.GOLD if right else Kit.CHROME)


func _draw_chips() -> void:
	var p := _pen
	var ins := _safe_canvas()
	var left := maxf(4.0, ins.x + 2.0)
	var a := _track_name(sim.track[sim.room])
	var b := _track_name(sim.track[sim.deck_b()]) if sim.playing[sim.deck_b()] else ""
	var names := a if b == "" else "%s → %s" % [a, b]
	var x := left
	x += p.chip(x, 12, names, Kit.LINE) + 3.0
	p.chip(x, 12, "%s %d/%d" % [_w("mix"), mini(sim.mix + 1, Sim.MIXES), Sim.MIXES], Kit.GOLD)


func _draw_words() -> void:
	var p := _pen
	if _call_t > 0.0 and _call != "":
		var cw := Kit.text_w(_call, 2)
		p.rect(W * 0.5 - cw * 0.5 - 4, 61, cw + 9, 20, Color(Kit.INK, 0.72))
		p.text(_call, W * 0.5, 60, _call_c, 2, true, true)
	if _bub_t > 0.0 and not _bub.is_empty():
		var bw := 160.0
		var h := 6.0 + _bub.size() * 10.0
		var bx := clampf(_bub_x - 20.0, 4.0, W - bw - 4.0)
		p.bubble(bx, 74.0 - h, bw, _bub_who, _bub, clampf(_bub_x, bx + 6.0, bx + bw - 8.0), VIOLET)


## The help chip (at most four words) over the control it is about, and on the first set of a save a
## ghost hand moving along it, until the control is first used right.
func _draw_ghost() -> void:
	var tag := ""
	var k := _desk()
	var at := Vector2.ZERO
	var path := Vector2.ZERO
	var ph := sim.phase
	if sim.mix == 0 and ph == Sim.CUE and not _done_jog:
		tag = "h_jog"
		at = k["jog"]
		path = Vector2(18, 0)
	elif sim.mix == 0 and (ph == Sim.BLEND or ph == Sim.ENDING) and not _done_fader:
		tag = "h_fader"
		var xf: Array = k["xf"]
		at = Vector2((float(xf[0]) + float(xf[1])) * 0.5, float(xf[2]))
		path = Vector2((float(xf[1]) - float(xf[0])) * 0.45, 0)
	elif sim.mix == 1 and (ph == Sim.CUE or ph == Sim.BLEND) and not _done_pitch:
		tag = "h_pitch"
		var pf: Array = k["pitch"]
		at = Vector2(float(pf[0]), (float(pf[1]) + float(pf[2])) * 0.5)
		path = Vector2(0, 16)
	if tag == "":
		return
	var p := _pen
	var t := _w(tag)
	var tw := Kit.text_w(t)
	var cx := clampf(at.x - tw * 0.5 - 4.0, 4.0, W - tw - 12.0)
	p.chip(cx, DESK_Y - 47, t, Kit.GOLD, "", 0.0, Kit.GOLD)
	if not first:
		return
	var s := sin(_t * 3.0)
	var hx := at.x + path.x * s
	var hy := at.y + path.y * s
	# A pointing hand: a finger and a palm.
	p.rect(hx - 1, hy - 6, 3, 7, Color(Kit.LINE, 0.9))
	p.rect(hx - 4, hy, 10, 7, Color(Kit.LINE, 0.9))
	p.rect(hx - 4, hy + 6, 10, 1, Color(Kit.CHALK_D, 0.9))


## The receipt: SET, the three mixes and their grades, the longest lock in bars, the floor's
## average, the tier in gold, the tip and the respect (or WIZYTA OPŁACONA), then JESZCZE RAZ and NA
## PARKIET.
func _draw_result() -> void:
	var p := _pen
	var cw := 200.0
	var ch := 134.0
	var x := roundf((W - cw) * 0.5)
	var y := 34.0
	var r := _result
	p.card(x, y, cw, ch, Color(Kit.INK, 0.95), Kit.SLATE_L)
	p.text(_w("r_set"), x + cw * 0.5, y + 4, Kit.LINE, 1, true)
	var grades: Array = r.get("grades", [])
	for i in Sim.MIXES:
		var g := str(grades[i]) if i < grades.size() else "-"
		var gc := Kit.GOLD if g == "czysto" else (Kit.LINE if g == "dobrze" else Kit.CHALK_D)
		p.text("%s %d" % [_w("r_mix"), i + 1], x + 10, y + 18 + i * 11, Kit.CHALK_D)
		var gt := _w(GRADE_TAGS.get(g, "g_none"))
		p.text(gt, x + cw - 10 - Kit.text_w(gt), y + 18 + i * 11, gc)
	p.rect(x + 8, y + 52, cw - 16, 1, Kit.SLATE_L)
	var bars := "%s %s" % [_num(float(r.get("longest_bars", 0.0))), _w("r_bars")]
	p.text(_w("r_lock"), x + 10, y + 56, Kit.CHALK_D)
	p.text(bars, x + cw - 10 - Kit.text_w(bars), y + 56, Kit.LINE)
	var avg := str(int(round(float(r.get("avg", 0.0)))))
	p.text(_w("r_floor"), x + 10, y + 67, Kit.CHALK_D)
	p.text(avg, x + cw - 10 - Kit.text_w(avg), y + 67, Kit.LINE)
	var tier := clampi(int(r.get("tier", 0)), 0, 3)
	p.text(_w("tier%d" % tier), x + cw * 0.5, y + 82, Kit.GOLD, 2, true, true)
	if _shown_paid:
		p.text(_w("r_paid"), x + cw * 0.5, y + 108, Kit.CHALK_D, 1, true)
	else:
		var tip := "+" + Room.say("wallet_chip", [int(r.get("tip", 0))])
		var rs := "+%d" % int(r.get("respect", 0))
		p.text(_w("r_tip"), x + 10, y + 106, Kit.CHALK_D)
		p.text(tip, x + cw - 10 - Kit.text_w(tip), y + 106, Kit.GO)
		p.text(_w("r_respect"), x + 10, y + 117, Kit.CHALK_D)
		p.text(rs, x + cw - 10 - Kit.text_w(rs), y + 117, Kit.GO)
	var bw := 84.0
	var by := y + ch + 8.0
	_again_rect = Rect2(W * 0.5 - bw - 6, by, bw, 25).grow(4)
	_floor_rect = Rect2(W * 0.5 + 6, by, bw, 25).grow(4)
	p.button(W * 0.5 - bw - 6, by, bw, _w("b_again"), false)
	p.button(W * 0.5 + 6, by, bw, _w("b_floor"), true)


## A number of bars as the receipt shows it: whole, or with a half or quarter.
func _num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(v))
	return ("%.2f" % v).rstrip("0").replace(".", ",")
