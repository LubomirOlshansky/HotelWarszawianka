extends Node
## Beer pong v2 "Rzut na raz" at THE TAPCZAN (docs/design/tapczan-pong-v2.md and its addendum
## tapczan-pong-v2-physics-and-fun.md): the view and the touch. The rules and the ball are
## pong_sim.gd, ticked here at a fixed 60 Hz from an accumulator (at most 4 ticks a frame).
##
## The look: padel's pixel art (padel_match.gd's structure): a 216-row canvas in a SubViewport,
## nearest-filtered over the whole screen, drawn through pixel_kit.gd. Seen from the side: you on the
## left in orange, the rival on the right in cyan, the black table between, the pub's brick behind
## (the chalk tap list, the porthole, amber lamps, BREW ENJOY EMPTY REPEAT on the concrete, the
## regulars at the back table who lean in, cheer and hang their heads).
##
## Touch: the finger anywhere is the breath: down holds it (the swing slows, the cyan lung bar
## drains, shared by the turn's balls), up throws where the gold ring is. Dragged 28 pt down (back
## above 16 pt: off) the throw is a bounce shot: two cups in clean, but the rival may swat it while
## watching. On the rival's spinner over your cup, one tap on the gold tick flicks it out. The ✕
## (a native disc top right) gives up: a loss. Keys: Space the finger, S or Down the bounce, Esc.
## Touch only (the project emulates touch from the mouse).
##
## The end: WYGRANA / PRZEGRANA / REMIS and a receipt (cups, stake, drinks, respect, total), then
## REWANŻ (the same rival at once) or DO BARU. `finished(won, stake, drinks)` as the result shows
## (a draw: false, 0, drinks), `closed` at DO BARU or the ✕.
##
## Sound (tapczan_room.gd hands `sound` and `cue` in; empty in checks): addendum 3.9 from sfx.gd's
## shots (pong_bounce, pong_rim, pong_cup, glass_clink, thump_soft, cafe_bell, coin) and the UI
## cues (tick, win, fail). The pub's bed (sfx.gd pub_bed) murmurs under it; no new audio.
##
## Cost: while it plays the city's 3D is off (GameCtx.city_drawn), so the frame is one 2D canvas of
## about 467 x 216 px, redrawn each frame (about 700 untextured rects) and one small native Control.
## Nothing allocated per frame but the sim's event dictionaries; the particles are a fixed pool.

const Sim := preload("res://scripts/pong_sim.gd")
const Kit := preload("res://scripts/pixel_kit.gd")
const Room := preload("res://scripts/tapczan_room.gd")
const Lang := preload("res://scripts/lang.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")

const H := 216
const MIN_W := 384
## The table's top row and half its length (canvas px; the sim's frame is 283 px long).
const TABLE_Y := 152.0
const TABLE_HALF := 141.5
## The sim's frame x 0 (the first cup) sits this far from the middle, each side.
const RACK_OFF := 48.5
const FIG_OFF := 168.0
const FOOT := 205.0
## The bounce gesture: down by this many points turns it on, back above the other turns it off.
const DRAG_ON := 28.0
const DRAG_OFF := 16.0
const RESULT_AFTER := 0.9
const AUTO_DONE := 2.0
const PARTS := 24
const REG_GAP := 6.0

## A match ended: won, the stake paid, the drinks it cost (the cups the rival took).
signal finished(won: bool, stake: int, drinks: int)
## The view handed back (DO BARU, the ✕).
signal closed

var pt := 1.0
var auto_play := false
var log_on := false
var rival_id := ""
var sim: Sim
var stake := 0
## Pints at the bar before the game (they widen the wobble and shorten the lung; not reported).
var start_drinks := 0
## The last result against this rival this visit: -1 none, 0 lost, 1 won (the first line says so).
var last := -1
## (name) -> void: a one-shot (sfx.gd play); (name) -> void: a UI cue (hud.gd cue).
var sound := Callable()
var cue := Callable()
var inside := false
## The match just ended in a draw.
var draw := false
var W := MIN_W

var _rival: Dictionary = {}
var _layer: CanvasLayer
var _vp: SubViewport
var _canvas: Node2D
var _tex: TextureRect
var _pad: Control
var _pen: Kit
var _acc := 0.0
var _t := 0.0
var _finger := false
var _low := false
var _key_finger := false
var _key_low := false
var _touch := -1
var _touch_y := 0.0
var _rng := RandomNumberGenerator.new()
var _done_t := -1.0
var _paid := false
var _again_rect := Rect2()
var _bar_rect := Rect2()
var _glass := "cup"
# the cups' last drawn x by id, per side; the rock timers; the lifted (taken) sprites
var _cx: Array[Dictionary] = [{}, {}]
var _rock: Dictionary = {}
var _lift: Array = []
# the ball's trail (screen px) and its blend from the figure's hand
var _trail := PackedVector2Array()
var _hand_me := Vector2.ZERO
var _hand_them := Vector2.ZERO
var _squash := 0
# callouts, bubbles, poses
var _call := ""
var _call_t := 0.0
var _call_c := Kit.GOLD
var _call_scale := 2
var _sub := ""
var _sub_t := 0.0
var _bub_who := ""
var _bub_text := ""
var _bub_t := 0.0
var _bub_x := 0.0
var _bub_c := Kit.THEM
var _reg_t := -10.0
var _reg_mood := 0
var _reg_mood_t := 0.0
var _throw_t := 0.0
var _rival_throw_t := 0.0
var _drink_t := 0.0
var _shake_t := 0.0
var _gasp_t := 0.0
var _said: Dictionary = {}
var _turns := 0
var _low_hint := false
var _hint_t := 0.0
# particles (a fixed pool): x, y, vx, vy, life, colour
var _pp := PackedFloat32Array()
var _pc: Array[Color] = []
var _pi := 0


func _ready() -> void:
	set_process(false)
	_pp.resize(PARTS * 5)
	for i in PARTS:
		_pc.append(Color.WHITE)


# --- in and out ---------------------------------------------------------------------------------

## A match against rival `id` (its data/tapczan.json table).
func start(id: String, r: Dictionary) -> void:
	rival_id = id
	_rival = r
	stake = int(r.get("stake", 0))
	_glass = str(r.get("glass", "cup"))
	if _layer == null:
		_build()
	var seed_value := randi()
	if auto_play:
		# The expert thumb with the first seed it wins with (the run's `tapczan: out: won`).
		seed_value = 1
		while seed_value < 200:
			if int(Sim.play_bot(r, "expert", seed_value, start_drinks).get("winner")) == 0:
				break
			seed_value += 1
	sim = Sim.new(seed_value, r, start_drinks)
	if auto_play:
		sim.bot_setup("expert", seed_value * 7919 + 13)
	_rng.seed = seed_value
	_acc = 0.0
	_t = 0.0
	_done_t = -1.0
	_paid = false
	draw = false
	_finger = false
	_low = false
	_touch = -1
	for side in 2:
		_cx[side].clear()
	_rock.clear()
	_lift.clear()
	_trail.clear()
	_said.clear()
	_turns = 0
	_low_hint = false
	_call = ""
	_sub = ""
	_bub_text = ""
	_reg_mood = 0
	for i in PARTS:
		_pp[i * 5 + 4] = 0.0
	inside = true
	_layer.visible = true
	_resize()
	var hello := "hello"
	if last >= 0:
		hello = "again_won" if last == 0 else "again_lost"
	_rival_says(hello)
	set_process(true)
	_log("start vs %s, seed %d, start drinks %d" % [id, seed_value, start_drinks])
	if log_on and is_inside_tree():
		get_tree().create_timer(3.0).timeout.connect(func() -> void: _log("frame: " + Room.frame_note()))


## The ✕: giving up is a loss.
func leave() -> void:
	if not inside:
		return
	if not _paid:
		_paid = true
		finished.emit(false, 0, sim.lost if sim != null else 0)
	_close()


func _close() -> void:
	inside = false
	_layer.visible = false
	set_process(false)
	_log("closed")
	closed.emit()


func _w(key: String) -> String:
	return Room.say(key)


func _rival_line(key: String) -> String:
	var lines: Array = _rival.get(key, [])
	if lines.is_empty():
		return ""
	var p: Array = lines[_rng.randi() % lines.size()]
	return Lang.pick(str(p[0]), str(p[1]))


func _short() -> String:
	var s: Array = _rival.get("short", [rival_id, rival_id])
	return Lang.pick(str(s[0]), str(s[1]))


func _rival_says(key: String) -> void:
	var line := _rival_line(key)
	if line == "":
		return
	_bub_who = _short()
	_bub_text = line
	_bub_t = 3.2
	_bub_x = W * 0.5 + FIG_OFF
	_bub_c = Kit.THEM


func _regular_says(force := false) -> void:
	if not force and _t - _reg_t < REG_GAP:
		return
	var lines: Array = Room.data().get("regulars", [])
	if lines.is_empty():
		return
	_reg_t = _t
	var p: Array = lines[_rng.randi() % lines.size()]
	_bub_who = ""
	_bub_text = Lang.pick(str(p[0]), str(p[1]))
	_bub_t = 2.2
	_bub_x = W * 0.5
	_bub_c = Kit.AMBER


func _snd(n: String) -> void:
	if sound.is_valid():
		sound.call(n)


func _cue(n: String) -> void:
	if cue.is_valid():
		cue.call(n)


func _log(text: String) -> void:
	if log_on:
		print("tapczan: pong " + text)


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
	get_viewport().size_changed.connect(_resize)


func _resize() -> void:
	if _vp == null:
		return
	var s := get_viewport().get_visible_rect().size
	W = maxi(MIN_W, int(round(H * s.x / maxf(s.y, 1.0))))
	_vp.size = Vector2i(W, H)


## Screen px per canvas px, and the canvas's left edge on screen (KEEP_ASPECT_COVERED).
func _scale() -> float:
	return get_viewport().get_visible_rect().size.y / float(H)


func _to_canvas(p: Vector2) -> Vector2:
	var s := get_viewport().get_visible_rect().size
	var k := _scale()
	return Vector2((p.x - (s.x - W * k) * 0.5) / k, p.y / k)


func _safe_canvas() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	var m := ScreenPoints.measure(s)
	var safe: Rect2 = m["safe"]
	var k := _scale()
	return Vector2(safe.position.x / k, (s.x - safe.end.x) / k)


# --- the frame ----------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not inside:
		return
	_t += dt
	if sim.phase != Sim.DONE:
		_acc += dt
		var n := 0
		while _acc >= Sim.DT and n < 4:
			_acc -= Sim.DT
			n += 1
			var f := _finger or _key_finger
			var lo := _low or _key_low
			if auto_play:
				var b := sim.bot_finger()
				f = bool(b[0])
				lo = bool(b[1])
			var lung_before := sim.lung
			sim.tick(f, lo)
			if sim.phase == Sim.AIM and sim.lung > 0.0 and sim.lung <= 0.3 and lung_before > 0.3:
				_cue("tick")
			if sim.phase == Sim.AIM and sim.aim_t == int((Sim.SHOT_CLOCK - 2.0) * Sim.HZ):
				_cue("tick")
			_drain()
		if _acc > Sim.DT * 4.0:
			_acc = 0.0
	elif _done_t >= 0.0:
		_done_t += dt
		if _done_t >= RESULT_AFTER and not _paid:
			_pay()
		if auto_play and _done_t >= RESULT_AFTER + AUTO_DONE:
			_close()
			return
	_fx(dt)
	_canvas.queue_redraw()
	_pad.queue_redraw()


func _fx(dt: float) -> void:
	for tm: String in ["_call_t", "_sub_t", "_bub_t", "_reg_mood_t", "_throw_t", "_rival_throw_t", "_drink_t", "_shake_t", "_gasp_t", "_hint_t"]:
		set(tm, maxf(0.0, float(get(tm)) - dt))
	if _reg_mood_t <= 0.0:
		_reg_mood = 0
	for k: int in _rock.keys():
		_rock[k] = float(_rock[k]) - dt
		if float(_rock[k]) <= 0.0:
			_rock.erase(k)
	var i := 0
	while i < _lift.size():
		_lift[i][2] = float(_lift[i][2]) - dt
		if float(_lift[i][2]) <= 0.0:
			_lift.remove_at(i)
		else:
			i += 1
	for p in PARTS:
		var b := p * 5
		if _pp[b + 4] > 0.0:
			_pp[b + 4] -= dt
			_pp[b] += _pp[b + 2] * dt
			_pp[b + 1] += _pp[b + 3] * dt
			_pp[b + 3] += 120.0 * dt
	if _squash > 0:
		_squash -= 1
	# The trail: the ball's last few spots.
	if sim.ball_live:
		_trail.append(_ball_px())
		if _trail.size() > 5:
			_trail.remove_at(0)
	elif not _trail.is_empty():
		_trail.clear()


func _burst(at: Vector2, c: Color, n: int, up := 40.0) -> void:
	for k in n:
		var b := _pi * 5
		_pp[b] = at.x
		_pp[b + 1] = at.y
		_pp[b + 2] = _rng.randf_range(-25.0, 25.0)
		_pp[b + 3] = -_rng.randf_range(up * 0.5, up)
		_pp[b + 4] = 0.45
		_pc[_pi] = c
		_pi = (_pi + 1) % PARTS


func _say(text: String, c := Kit.GOLD, life := 1.0, scale := 2) -> void:
	_call = text
	_call_c = c
	_call_t = life
	_call_scale = scale


func _say_sub(text: String, life := 1.2) -> void:
	_sub = text
	_sub_t = life


# --- the sim's events -----------------------------------------------------------------------

func _drain() -> void:
	if sim.events.is_empty():
		return
	for e: Dictionary in sim.events:
		_on_event(str(e["name"]), e)
	sim.events.clear()


func _on_event(n: String, e: Dictionary) -> void:
	var mine := sim.thrower == Sim.ME
	match n:
		"round":
			_turns += 1
			_say(_w("round") % int(e["n"]), Kit.LINE, 0.9, 1)
			if _turns == 2 and not _low_hint:
				_low_hint = true
				_hint_t = 3.5
		"dare":
			if not _said.has("dare"):
				_said["dare"] = true
				_bub_who = _short()
				_bub_text = _w("dare")
				_bub_t = 2.0
				_bub_x = W * 0.5 + FIG_OFF
				_bub_c = Kit.THEM
		"throw":
			_throw_t = 0.3
		"rival_throw":
			_rival_throw_t = 0.3
		"tock":
			_snd("pong_bounce")
			_squash = 1
			_burst(_ball_px() + Vector2(0, 1), Kit.SLATE_L, 1, 10.0)
		"body":
			_snd("pong_bounce")
			_rock[int(e["id"])] = 0.3
			_burst(_ball_px(), Kit.FOAM, 3, 20.0)
			if bool(e["clink"]):
				_snd("glass_clink")
		"rim":
			_snd("pong_rim")
			_reg_mood = 1
			_reg_mood_t = 1.0
			if not mine:
				_say_sub(_w("flick_hint"), 0.9)
		"rim_tick":
			_snd("pong_rim")
			_burst(_ball_px(), Color.WHITE, 1, 15.0)
		"rim_out":
			if mine:
				_say(_w("rim_out"), Kit.LINE, 0.8, 1)
		"flicked":
			_say(_w("flicked"), Kit.THEM if mine else Kit.US, 0.9)
			_snd("thump_soft")
		"clean", "in", "rim_in", "bounce_in", "fluke":
			_cup_taken(e, Sim.THEM)
			var key := {"clean": "clean", "in": "cup", "rim_in": "rim_in", "bounce_in": "bounce_in", "fluke": "fluke"}[n] as String
			_say(_w(key), Kit.GOLD, 1.0)
			if n == "bounce_in" or n == "clean":
				_reg_mood = 2
				_reg_mood_t = 1.4
				_regular_says()
			if sim.heat == 2:
				_say_sub(_w("heat2"), 1.0)
			elif sim.heat >= 3:
				_say_sub(_w("heat3"), 1.0)
			_story()
		"karniak":
			_say(_w("karniak"), Kit.GOLD, 1.3)
			_snd("glass_clink")
		"swat":
			_say(_w("swat"), Kit.THEM, 0.9)
			_snd("thump_soft")
		"miss":
			if _call_t <= 0.0:
				_say(_w("miss"), Kit.CHALK_D, 0.6, 1)
		"slip":
			_say(_w("slip"), Kit.CHALK_D, 1.0, 1)
		"gasp":
			_gasp_t = 0.6
			_say_sub(_w("gasp"), 0.8)
		"rival_cup":
			_cup_taken(e, Sim.ME)
			_say(_w("drink_up"), Kit.THEM, 0.9, 1)
			_drink_t = 0.6
			_reg_mood = 3
			_reg_mood_t = 1.2
			_story()
		"rival_miss":
			if _rng.randf() < 0.25 and _bub_t <= 0.0:
				_rival_says("miss")
		"nudge":
			_snd("thump_soft")
			if not _said.has("nudge"):
				_said["nudge"] = true
				_rival_says("nudge_says")
		"reset":
			_snd("glass_clink")
			if _bub_t <= 0.0:
				_rival_says("reset")
		"bonus":
			_rival_says("bonus")
		"wake":
			_rival_says("wake_says")
		"rerack":
			_say_sub(_w("rerack"), 1.0)
			_snd("glass_clink")
		"last_orders":
			_say(_w("last_orders"), Kit.AMBER, 1.6)
			_snd("cafe_bell")
		"sudden":
			_say_sub(_w("sudden"), 1.8)
		"over":
			_over(int(e["winner"]))


func _cup_taken(e: Dictionary, side: int) -> void:
	_snd("glass_clink" if side == Sim.THEM and _glass == "tulip" else "pong_cup")
	_shake_t = 0.15
	for id: int in e.get("ids", []):
		var x := float(_cx[side].get(id, 0.0))
		_lift.append([side, x, 0.3])
		var sx := _sx(side, x)
		_burst(Vector2(sx, TABLE_Y - 14.0), Kit.FOAM, 6, 50.0)


## The six lines of story, once each: you lead by two, they lead by two, their last cup.
func _story() -> void:
	if sim.took - sim.lost >= 2 and not _said.has("you_lead"):
		_said["you_lead"] = true
		_rival_says("you_lead")
	elif sim.lost - sim.took >= 2 and not _said.has("they_lead"):
		_said["they_lead"] = true
		_rival_says("they_lead")
	elif sim.cups_them.size() == 1 and not _said.has("last_cup"):
		_said["last_cup"] = true
		_rival_says("last_cup")


func _over(who: int) -> void:
	_done_t = 0.0
	draw = who == 2
	if who == 0:
		_say(_w("won"), Kit.GOLD, 99.0, 3)
		_reg_mood = 2
		_reg_mood_t = 99.0
		_rival_says("lose")
		_cue("win")
	elif who == 1:
		_say(_w("lost"), Kit.THEM, 99.0, 3)
		_reg_mood = 3
		_reg_mood_t = 99.0
		_rival_says("win")
		_cue("fail")
	else:
		_say(_w("draw"), Kit.LINE, 99.0, 2)
	_log("over: %s (%s), took %d, lost %d, %.0f s" % [["won", "lost", "draw"][clampi(who, 0, 2)], sim.end, sim.took, sim.lost, sim.t * Sim.DT])


func _pay() -> void:
	_paid = true
	var won := sim.winner == 0
	if won:
		_snd("coin")
	finished.emit(won, stake if won else 0, sim.lost)


## The rematch: the same rival at once; the cups lost are drunk.
func _rematch() -> void:
	start_drinks += sim.lost
	last = 1 if sim.winner == 0 else 0
	start(rival_id, _rival)


# --- touch --------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not inside:
		return
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			if e.position.distance_to(_quit_c()) <= 30.0 * pt:
				leave()
			elif sim.phase == Sim.DONE:
				if _done_t >= RESULT_AFTER:
					var c := _to_canvas(e.position)
					if _again_rect.has_point(c):
						if not _paid:
							_pay()
						_rematch()
					elif _bar_rect.has_point(c):
						if not _paid:
							_pay()
						_close()
			elif _touch < 0:
				_touch = e.index
				_touch_y = e.position.y
				_finger = true
				_low = false
		elif e.index == _touch:
			_touch = -1
			_finger = false
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch:
			var dy := (d.position.y - _touch_y) / maxf(pt, 0.1)
			if dy >= DRAG_ON:
				_low = true
			elif dy < DRAG_OFF:
				_low = false
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.echo:
			return
		match k.keycode:
			KEY_SPACE:
				_key_finger = k.pressed
			KEY_S, KEY_DOWN:
				_key_low = k.pressed
			KEY_ESCAPE:
				if k.pressed:
					leave()
			KEY_ENTER:
				if k.pressed and sim.phase == Sim.DONE and _done_t >= RESULT_AFTER:
					if not _paid:
						_pay()
					_close()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


func _quit_c() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	var m := ScreenPoints.measure(s)
	var safe: Rect2 = m["safe"]
	return Vector2(minf(s.x - 34.0 * pt, safe.end.x - 22.0 * pt), 34.0 * pt)


func _draw_pad() -> void:
	var qc := _quit_c()
	_pad.draw_circle(qc, 20.0 * pt, Color(0, 0, 0, 0.45))
	var r := 7.0 * pt
	_pad.draw_line(qc - Vector2(r, r), qc + Vector2(r, r), Color(1, 1, 1, 0.95), 2.5 * pt)
	_pad.draw_line(qc + Vector2(-r, r), qc + Vector2(r, -r), Color(1, 1, 1, 0.95), 2.5 * pt)


# --- where things are -----------------------------------------------------------------------------

## Screen x (canvas px) of a sim x on `side`'s rack (the rack `side` defends).
func _sx(side: int, x: float) -> float:
	var mid := W * 0.5
	return mid + RACK_OFF + x if side == Sim.THEM else mid - RACK_OFF - x


## The ball now (canvas px), in the thrower's frame mirrored for the rival, blended from the
## figure's hand over the first ticks (the sim's hand is a point in the air).
func _ball_px() -> Vector2:
	var side := 1 - sim.thrower
	var p := Vector2(_sx(side, sim.bx), TABLE_Y - sim.by)
	if sim.b_age < 12 and sim.b_bounces == 0 and sim.b_fresh:
		var hand := _hand_me if sim.thrower == Sim.ME else _hand_them
		p = hand.lerp(p, sim.b_age / 12.0)
	return p


# --- drawing --------------------------------------------------------------------------------------

func _draw_scene() -> void:
	var p := _pen
	var shake := Vector2.ZERO
	if _shake_t > 0.0 and sim.phase != Sim.AIM:
		shake = Vector2(_rng.randi_range(-1, 1), _rng.randi_range(-1, 1)) * (2.0 if sim.heat >= 3 else 1.0)
	p.o = shake
	_draw_backdrop()
	_draw_table()
	_draw_cups()
	_draw_figures()
	_draw_aim()
	_draw_ball()
	for i in PARTS:
		var b := i * 5
		if _pp[b + 4] > 0.0:
			p.px(_pp[b], _pp[b + 1], _pc[i])
	p.o = Vector2.ZERO
	_draw_strips()
	_draw_words()
	if sim.phase == Sim.DONE and _done_t >= RESULT_AFTER:
		_draw_result()


func _draw_backdrop() -> void:
	var p := _pen
	var w := float(W)
	p.bricks(0, 9, w, 122, 7)
	p.rect(0, 0, w, 9, Kit.FRAME)
	p.rect(0, 9, w, 2, Kit.VOID)
	var dx := 40.0
	while dx < w:
		p.rect(dx, 2, 96, 4, Kit.CONCRETE)
		p.rect(dx, 2, 96, 1, Kit.CHROME)
		var j := dx + 10.0
		while j < dx + 96.0:
			p.rect(j, 2, 1, 4, Kit.CONCRETE_D)
			j += 14.0
		dx += 150.0
	# The concrete with BREW ENJOY EMPTY REPEAT (the first letters spell BEER).
	var cx := w - 150.0
	p.rect(cx, 11, 124, 96, Kit.CONCRETE)
	p.rect(cx, 11, 124, 1, Kit.CHROME)
	p.rect(cx, 106, 124, 1, Kit.CONCRETE_D)
	for j in [cx + 41.0, cx + 82.0]:
		p.rect(j, 11, 1, 96, Kit.CONCRETE_D)
	var words := ["BREW", "ENJOY", "EMPTY", "REPEAT"]
	for i in 4:
		var word: String = words[i]
		var yy := 16.0 + i * 22.0
		p.text(word.substr(0, 1), cx + 12, yy, Kit.LINE, 2)
		p.text(word.substr(1), cx + 14 + Kit.text_w(word.substr(0, 1), 2), yy, Kit.CONCRETE_D, 2)
	# The chalk tap board on the brick: the first four on tap, their prices.
	var bx := w * 0.5 - 115.0
	p.rect(bx - 2, 30, 112, 62, Kit.WOOD_D)
	p.rect(bx, 32, 108, 58, Kit.BOARD)
	p.text(_w("taps_head"), bx + 54, 33, Kit.LINE, 1, true)
	p.rect(bx + 26, 44, 56, 1, Kit.AMBER)
	var list: Array = Room.taps()
	for i in mini(4, list.size()):
		var t: Dictionary = list[i]
		var nm: Array = t.get("name", ["", ""])
		var pr := str(int(t.get("price", 0)))
		# The name cut at a word to fit beside the price.
		var s := str(nm[0]).to_upper()
		while Kit.text_w(s) > 92 - Kit.text_w(pr) and s.contains(" "):
			s = s.substr(0, s.rfind(" ")).trim_suffix(",")
		p.text(s, bx + 5, 46 + i * 11, Kit.CHALK_D)
		p.text(pr, bx + 103 - Kit.text_w(pr), 46 + i * 11, Kit.AMBER)
	# The porthole.
	var ox := w * 0.5 - 170.0
	p.disc(ox, 60, 15, 15, Kit.COPPER)
	p.disc(ox, 60, 12, 12, Kit.NIGHT1)
	p.disc(ox - 4, 56, 4, 4, Kit.NIGHT2)
	p.rect(ox - 12, 60, 25, 1, Kit.COPPER)
	p.rect(ox, 48, 1, 25, Kit.COPPER)
	# The amber lamps, flickering by alpha.
	for k in 4:
		var lx := [w * 0.5 - 195.0, w * 0.5 - 137.0, w * 0.5 + 25.0, w * 0.5 + 59.0][k] as float
		var drop := 16.0 if k == 1 else 12.0
		var fl := 0.09 + 0.015 * sin(_t * 7.0 + k * 2.1)
		p.rect(lx, 9, 1, 14 - 9 + drop - 6, Kit.INK)
		p.glow(lx, 14 + drop, 15, Kit.AMBER_L, fl)
		p.rect(lx - 2, 14 + drop - 6, 5, 2, Kit.COPPER)
		p.rect(lx - 3, 14 + drop - 4, 7, 6, Kit.AMBER)
		p.rect(lx - 2, 14 + drop - 3, 2, 4, Kit.AMBER_L)
	# The wainscot and the slate floor.
	p.rect(0, 107, w, 24, Kit.WOOD_D)
	p.rect(0, 107, w, 2, Kit.WOOD)
	var jx := 0.0
	while jx < w:
		p.rect(jx, 109, 1, 22, Kit.MORTAR)
		jx += 23.0
	p.rect(0, 131, w, H - 131, Kit.COURT)
	p.rect(0, 131, w, 2, Kit.SLATE_D)
	for yy in [146.0, 166.0, 190.0]:
		p.rect(0, yy, w, 1, Kit.SLATE_D)
	# The regulars at the back table: sit, lean in (1), arms up (2), heads down (3).
	var mx := w * 0.5
	p.rect(mx - 57, 121, 60, 3, Kit.WOOD)
	p.rect(mx - 53, 124, 2, 9, Kit.WOOD_D)
	p.rect(mx - 3, 124, 2, 9, Kit.WOOD_D)
	var shirts := [Kit.PURPLE, Kit.CONCRETE, Kit.GO, Kit.BRICK_L]
	var hairs := [Kit.HAIR_BK, Kit.HAIR_BR, Kit.HAIR_BL, Kit.HAIR_BK]
	for i in 4:
		var rx: float = mx - 65.0 + float([0.0, 22.0, 56.0, 76.0][i])
		var up := 0.0
		var dy := 0.0
		match _reg_mood:
			1:
				dy = -1.0
			2:
				up = 2.0 + float(int(_t * 6.0 + i) % 2)
			3:
				dy = 2.0
		p.mini(rx, 134 + dy, (shirts[i] as Color).darkened(0.28), hairs[i], (Kit.SKIN[1] as Color).darkened(0.2), true, up)
	p.mug(mx - 35, 111)
	p.mug(mx - 19, 111, Kit.WOOD_D)


func _draw_table() -> void:
	var p := _pen
	var mid := W * 0.5
	var x0 := mid - TABLE_HALF
	var x1 := mid + TABLE_HALF
	p.disc(mid, 205, 150, 4, Color(0, 0, 0, 0.3))
	for lx in [x0 + 12.0, x1 - 16.0]:
		p.rect(lx, TABLE_Y + 6, 4, 50, Kit.CONCRETE_D)
		p.rect(lx, TABLE_Y + 6, 1, 50, Kit.CONCRETE)
	p.rect(x0 + 14, TABLE_Y + 30, x1 - x0 - 28, 2, Kit.CONCRETE_D)
	p.rect(x0, TABLE_Y, x1 - x0, 6, Kit.FRAME)
	p.rect(x0, TABLE_Y, x1 - x0, 1, Kit.LINE)
	p.rect(x0, TABLE_Y + 5, x1 - x0, 1, Kit.VOID)
	p.rect(mid, TABLE_Y + 1, 1, 4, Kit.LINE)


func _draw_cups() -> void:
	var p := _pen
	for side in 2:
		var xs := sim.xs(side)
		var ids := sim.ids(side)
		_cx[side].clear()
		for i in xs.size():
			var id := ids[i]
			_cx[side][id] = xs[i]
			var sx := _sx(side, xs[i])
			if _rock.has(id):
				sx += 1.0 if int(float(_rock[id]) * 20.0) % 2 == 0 else -1.0
			var rim := Kit.LINE
			if sim.phase == Sim.SPIN and sim.spin_cup == id and side == 1 - sim.thrower:
				rim = Kit.GOLD if int(_t * 10.0) % 2 == 0 else Kit.LINE
			if side == Sim.THEM and _glass == "tulip":
				p.tulip(sx, TABLE_Y - 13, 1.0, rim)
			else:
				p.cup(sx, TABLE_Y - 13, 1.0, rim)
			# The dare mark: a gold chalk "!" over the dared cup, bobbing.
			if side == Sim.THEM and id == sim.dare_id:
				var bob := roundf(sin(_t * 6.0))
				p.rect(sx, TABLE_Y - 24 + bob, 1, 3, Kit.GOLD)
				p.px(sx, TABLE_Y - 20 + bob, Kit.GOLD)
	for l: Array in _lift:
		var a := float(l[2]) / 0.3
		var sx := _sx(int(l[0]), float(l[1]))
		var ty := TABLE_Y - 13 - (1.0 - a) * 10.0
		if int(l[0]) == Sim.THEM and _glass == "tulip":
			p.tulip(sx, ty, a)
		else:
			p.cup(sx, ty, a)
	# The flick tick on your cup's near lip while the rival's ball spins on it.
	if sim.phase == Sim.SPIN and sim.thrower == Sim.THEM and not sim.spin_tapped:
		var x := sim.cup_x(Sim.ME, sim.spin_cup)
		if not is_nan(x):
			var sx := _sx(Sim.ME, x)
			var ts := sim.spin_age * Sim.DT
			var k := roundi((ts - Sim.FLICK_FIRST) / Sim.FLICK_LAP)
			var near := k >= 0 and absf(ts - (Sim.FLICK_FIRST + k * Sim.FLICK_LAP)) <= Sim.FLICK_HALF
			p.rect(sx + 5, TABLE_Y - 15, 1, 3, Kit.GOLD if near else Color(Kit.GOLD, 0.35))


func _draw_figures() -> void:
	var p := _pen
	var mid := W * 0.5
	# You: the arm follows the swing's phase; up on the throw; a drink when they hit.
	var arm := 0.3
	var pose := ""
	if sim.phase == Sim.AIM and sim.thrower == Sim.ME:
		arm = 0.25 - 0.55 * (1.0 - cos(sim.phi)) * 0.5
		if sim.held > 0.0 and (_finger or _key_finger or auto_play):
			arm -= 0.1
	if _throw_t > 0.0:
		arm = -0.9
	if _drink_t > 0.0:
		pose = "drink"
	if sim.phase == Sim.DONE:
		pose = "cheer" if sim.winner == 0 else ("slump" if sim.winner == 1 else "")
	var exhale := 1.0 if _gasp_t > 0.0 else 0.0
	_hand_me = p.figure(mid - FIG_OFF, FOOT + exhale, 1, "you", arm, pose)
	# The rival: the pose shows the tells (eyes off: phones, dozing, nose in the glass; Gienia's
	# hand on the table edge before a nudge), the wind-up and the throw, the cheer and the slump.
	var kind := {"office": "crew", "first": "gienia", "sommelier": "hubert"}.get(rival_id, "crew") as String
	var rpose := ""
	var rarm := 0.4
	if sim.thrower == Sim.ME and sim.phase != Sim.DONE:
		if sim.nudge_warned() and sim.nudge_at >= 0:
			rpose = "reach"
		elif sim.rival_busy() or (kind == "gienia" and not sim.awake):
			rpose = "away"
	elif sim.thrower == Sim.THEM:
		if sim.phase == Sim.WAIT and sim.after == Sim.After.RIVAL_THROW:
			rarm = 0.9
		if _rival_throw_t > 0.0:
			rarm = -0.9
	if sim.phase == Sim.DONE:
		rpose = "cheer" if sim.winner == 1 else ("slump" if sim.winner == 0 else "")
	if kind == "crew":
		# Two more of the crew behind, on their phones when away.
		for k in 2:
			var bx := mid + FIG_OFF + 14.0 + k * 13.0
			p.mini(bx, FOOT - 10.0, Kit.THEM_D if k == 0 else Kit.LINE, Kit.HAIR_BK if k == 0 else Kit.HAIR_BR, Kit.SKIN[2 - k], false, 2.0 if rpose == "cheer" else 0.0)
			if rpose == "away":
				p.rect(bx - 1, FOOT - 24.0, 3, 4, Kit.INK)
				p.px(bx, FOOT - 23.0, Kit.THEM.lightened(0.4))
	_hand_them = p.figure(mid + FIG_OFF, FOOT, -1, kind, rarm, rpose)


func _draw_aim() -> void:
	if sim.phase != Sim.AIM or sim.thrower != Sim.ME:
		return
	var p := _pen
	var lo := _low or _key_low or (auto_play and sim.low)
	var rx := sim.ring_x()
	var sx := _sx(Sim.THEM, rx)
	var row := TABLE_Y - Sim.RIM_Y
	var blocked := lo and sim.hop_blocked(rx)
	# The arc: the launch's one or two parabolas, 2x2 gold dots.
	var pv := sim.preview(rx, lo)
	var dots := 12
	for i in dots:
		var x := float(pv[i * 2])
		var y := float(pv[i * 2 + 1])
		if blocked and i >= 6:
			break
		p.rect(_sx(Sim.THEM, x), TABLE_Y - y, 2, 2, Color(Kit.GOLD, 0.65 if not blocked else 0.3))
	if lo:
		var xb := float(pv[10])
		var cx := _sx(Sim.THEM, xb)
		p.rect(cx - 2, TABLE_Y - 2, 5, 1, Kit.GOLD)
		p.rect(cx, TABLE_Y - 3, 1, 3, Kit.GOLD)
	# The ring: the mouth (9x4, 7x3 for a bounce), a pixel tighter at a full hold; the bright core
	# is the ball-back window (wider with heat); a faint double at the wobble's size; dim if blocked.
	var full := sim.held >= Sim.HOLD_RAMP and not sim.gasp
	var rw := (7.0 if lo else 9.0) - (2.0 if full else 0.0)
	var rh := 3.0 if lo else 4.0
	var a := 0.35 if blocked else 1.0
	var amp := sim.wobble_amp()
	if amp > 0.6:
		_ring(sx + amp, row, rw, rh, Color(Kit.GOLD, 0.22 * a))
	_ring(sx, row, rw, rh, Color(Kit.GOLD, a))
	var core := clampf(roundf(sim.clean_r() * 2.0), 2.0, 4.0)
	p.rect(sx - core * 0.5, row - 1, core, 2, Color(1, 1, 0.8, a))
	# The lung bar under the table's lip (below the rival's cups), a notch at one full hold.
	_draw_lung()


func _ring(cx: float, cy: float, w: float, h: float, c: Color) -> void:
	var p := _pen
	var hw := floorf(w * 0.5)
	p.rect(cx - hw + 1, cy - h * 0.5, w - 2, 1, c)
	p.rect(cx - hw + 1, cy + h * 0.5 - 1, w - 2, 1, c)
	p.rect(cx - hw, cy - h * 0.5 + 1, 1, h - 2, c)
	p.rect(cx + hw, cy - h * 0.5 + 1, 1, h - 2, c)


func _draw_lung() -> void:
	var p := _pen
	var x := _sx(Sim.THEM, -20.0)
	var y := TABLE_Y + 10.0
	var full := sim.lung_full() + Sim.LUNG_BACK
	var f := clampf(sim.lung / full, 0.0, 1.0)
	p.rect(x - 1, y - 1, 96, 5, Color(Kit.INK, 0.8))
	var c := Kit.THEM if _gasp_t <= 0.0 or int(_t * 12.0) % 2 == 0 else Kit.LINE
	p.rect(x, y, roundf(94.0 * f), 3, c)
	p.rect(x + roundf(94.0 * Sim.HOLD_RAMP / full), y - 1, 1, 5, Kit.LINE)
	p.text(_w("breath"), x, y + 4, Kit.CHALK_D)


func _draw_ball() -> void:
	var p := _pen
	if sim.phase == Sim.SPIN:
		var side := 1 - sim.thrower
		var x := sim.cup_x(side, sim.spin_cup)
		if is_nan(x):
			return
		# Round the mouth, the laps slowing; the far half drawn as if behind the lip (dimmer).
		var ts := sim.spin_age * Sim.DT
		var ang := TAU * (ts / 0.4) * (1.0 - 0.3 * ts)
		var bx := _sx(side, x) + 3.5 * cos(ang)
		var behind := sin(ang) > 0.0
		p.rect(bx - 1, TABLE_Y - Sim.RIM_Y - 2, 3, 2, Kit.BALL if not behind else Kit.BALL.darkened(0.3))
		return
	if not sim.ball_live:
		return
	for i in _trail.size():
		var q := _trail[i]
		p.px(q.x, q.y, Color(Kit.BALL, 0.15 + 0.15 * i))
	var bp := _ball_px()
	p.ball(bp.x, bp.y, _squash > 0)


func _draw_strips() -> void:
	var p := _pen
	var ins := _safe_canvas()
	var left := maxf(4.0, ins.x + 2.0)
	var right := W - maxf(4.0, ins.y + 2.0) - 30.0
	# The round, the balls left, the drinks.
	var rnd := (_w("round") % maxi(1, sim.round_no)) if sim.sudden == 0 else _w("sudden").get_slice("·", 0).strip_edges()
	var x := left
	x += p.chip(x, 4, rnd) + 3.0
	var bw := 8.0 + maxi(0, sim.balls) * 5.0 + 22.0
	p.rect(x, 4, bw, 13, Color(Kit.INK, 0.86))
	p.rect(x, 4, bw, 1, Kit.SLATE_L)
	var showing := sim.balls + (1 if sim.thrower == Sim.ME and sim.phase == Sim.AIM else 0)
	for i in showing:
		p.rect(x + 4 + i * 5, 8, 3, 3, Kit.BALL if sim.thrower == Sim.ME else Kit.THEM)
	var dx := x + 6 + showing * 5
	p.mug(dx, 6, Kit.BEER)
	p.text(str(sim.drinks), dx + 11, 5, Kit.AMBER)
	# The score: cups taken each side with five pips, the rival's name and its eye pip, the heat.
	var mid := W * 0.5
	var s := "%s  %d : %d  %s" % [_w("you"), sim.took, sim.lost, _short()]
	var tw := Kit.text_w(s)
	p.rect(mid - tw * 0.5 - 44, 4, tw + 88, 13, Color(Kit.INK, 0.86))
	p.rect(mid - tw * 0.5 - 44, 4, tw + 88, 1, Kit.SLATE_L)
	p.text(s, mid, 5, Kit.LINE, 1, true)
	for i in 5:
		p.rect(mid - tw * 0.5 - 30 + i * 5, 9, 3, 3, Kit.US if i < sim.took else Kit.SLATE_L)
		p.rect(mid + tw * 0.5 + 28 - i * 5, 9, 3, 3, Kit.THEM if i < sim.lost else Kit.SLATE_L)
	# Heat: three flames under the score, lit by the streak, all three pulsing at the top.
	for i in 3:
		var lit := i < sim.heat
		var c := Kit.US if lit else Kit.SLATE_L
		if sim.heat >= 3 and int(_t * 8.0) % 2 == 0:
			c = Kit.GOLD
		var fx := mid - 8.0 + i * 7.0
		p.rect(fx, 19, 3, 4, c)
		p.px(fx + 1, 18, Kit.GOLD if lit else Kit.SLATE_L)
	var busy := sim.rival_busy() or (rival_id == "first" and not sim.awake)
	var ex := mid + tw * 0.5 + 34
	if busy:
		p.rect(ex, 10, 5, 1, Kit.CHALK_D)
	else:
		p.rect(ex, 9, 5, 3, Kit.LINE)
		p.px(ex + 2, 10, Kit.INK)
	# The stake.
	var st := _w("wallet_chip") % stake
	var sw := Kit.text_w(st) + 9.0
	p.chip(right - sw, 4, st, Kit.GOLD)


func _draw_words() -> void:
	var p := _pen
	if _call_t > 0.0 and _call != "":
		var y := 52.0 if _call_scale >= 2 else 64.0
		if _call_scale >= 3:
			y = 24.0
		if _call_scale < 3:
			var cw := Kit.text_w(_call, _call_scale)
			p.rect(W * 0.5 - cw * 0.5 - 4, y + 1, cw + 9, 9 * _call_scale + 2, Color(Kit.INK, 0.72))
		p.text(_call, W * 0.5, y, _call_c, _call_scale, true, true)
	if _sub_t > 0.0 and _sub != "":
		var sw := Kit.text_w(_sub)
		p.rect(W * 0.5 - sw * 0.5 - 4, 81, sw + 9, 11, Color(Kit.INK, 0.72))
		p.text(_sub, W * 0.5, 80, Kit.LINE, 1, true, true)
	if _bub_t > 0.0 and _bub_text != "" and sim.phase != Sim.DONE:
		var lines := Kit.wrap(_bub_text, 140)
		var bw := 150.0
		var h := 6.0 + lines.size() * 10.0
		var bx := clampf(_bub_x - bw * 0.5, 4.0, W - bw - 4.0)
		var by := 96.0 - h
		p.bubble(bx, by, bw, _bub_who, lines, clampf(_bub_x, bx + 6.0, bx + bw - 8.0), _bub_c)
	# The hint strip near the bottom: the hold the first two turns, the bounce once on the second,
	# the flick while the rival's ball spins on your cup.
	var hint := ""
	if sim.phase == Sim.SPIN and sim.thrower == Sim.THEM and not sim.spin_tapped:
		hint = _w("flick_hint")
	elif _hint_t > 0.0:
		hint = _w("hint_low")
	elif _turns <= 2 and sim.thrower == Sim.ME and sim.phase == Sim.AIM:
		hint = _w("hint")
	if hint != "":
		var tw := Kit.text_w(hint)
		p.rect(W * 0.5 - tw * 0.5 - 6, H - 23, tw + 12, 12, Color(Kit.INK, 0.86))
		p.text(hint, W * 0.5, H - 24, Kit.LINE, 1, true)


## The receipt (mock 3): the rival's bust at 2x, their line, the cups, the bill of the match, then
## REWANŻ and DO BARU.
func _draw_result() -> void:
	var p := _pen
	var cw := 282.0
	var ch := 112.0
	var x := roundf((W - cw) * 0.5)
	var y := 46.0
	p.card(x, y, cw, ch, Color(Kit.INK, 0.96), Kit.SLATE_L)
	p.bust(x + 6, y + 6, rival_id, 2.0, Kit.THEM)
	p.text(_short(), x + 38, y + 74, Kit.THEM, 1, true)
	var line := _bub_text if _bub_text != "" else ""
	var lines := Kit.wrap(line, 104)
	for i in mini(4, lines.size()):
		p.text(lines[i], x + 76, y + 4 + i * 10, Kit.LINE)
	for k in 2:
		var have := sim.took if k == 0 else sim.lost
		for i in 5:
			var cx := x + 82.0 + i * 11.0
			var cy := y + 52.0 + k * 26.0
			p.cup(cx, cy, 1.0 if i < have else 0.25)
		p.text(str(have), x + 140, y + 52 + k * 26, Kit.US if k == 0 else Kit.THEM, 2)
	# The receipt.
	var rx := x + cw - 96.0
	var ry := y + 6.0
	p.rect(rx, ry, 90, ch - 12, Kit.FOAM)
	p.text("THE TAPCZAN", rx + 45, ry + 1, Kit.INK, 1, true)
	p.rect(rx + 4, ry + 12, 82, 1, Kit.PAPER_D)
	var won := sim.winner == 0
	var rows := [
		[_w("receipt_cups"), "%d:%d" % [sim.took, sim.lost]],
		[_w("receipt_stake"), _w("wallet_chip") % stake],
		[_w("receipt_drunk"), str(sim.lost)],
		[_w("receipt_respect"), "+5" if won else "0"],
	]
	for i in rows.size():
		p.text(str(rows[i][0]), rx + 4, ry + 14 + i * 11, Kit.INK)
		var v := str(rows[i][1])
		p.text(v, rx + 86 - Kit.text_w(v), ry + 14 + i * 11, Kit.INK)
	for k in range(0, 82, 3):
		p.px(rx + 4 + k, ry + 60, Kit.PAPER_D)
	var total := ("+" + _w("wallet_chip") % stake) if won else _w("wallet_chip") % 0
	p.text(_w("total"), rx + 4, ry + 64, Kit.INK)
	p.text(total, rx + 86 - Kit.text_w(total), ry + 64, Kit.US_D if won else Kit.INK)
	for k in range(0, 82, 2):
		p.rect(rx + 4 + k, ry + 80, 1, 6 if k % 6 else 8, Kit.INK)
	# The buttons.
	var bw := 66.0
	var by := y + ch + 8.0
	_again_rect = Rect2(W * 0.5 - bw - 6, by, bw, 25).grow(4)
	_bar_rect = Rect2(W * 0.5 + 6, by, bw, 25).grow(4)
	p.button(W * 0.5 - bw - 6, by, bw, _w("rematch"), true)
	p.button(W * 0.5 + 6, by, bw, _w("done"), false)
