extends Node
## Promo Mode (F 2026-11-20: "the easiest way to choose the view for the promo video"): a DEV tool
## for framing trailer and Reels shots on the phone. Settings → DEV → "Promo mode" turns it on
## (settings.gd `promo`, off by default; --promo for a test run). While it is off nothing is built
## and nothing runs. While it is on it owns the main camera (main.gd `_update_camera` asks `frame`
## first), so the sectors stream round its focus and the post pass stays the game's:
## - CAR: the camera rides with the car (or the helicopter) at its own yaw, tilt and view height;
##   the yaw turns with the car plus an offset (side, front and three-quarter shots) or, LOCKed,
##   stays on its compass heading (and SPIN turns it slowly).
## - FREE: the camera leaves the car, which waits parked (main.gd `_read_input` asks `holds_car`),
##   and flies: one finger drags the ground (a flick glides on), two fingers pinch the view, twist
##   the yaw and slide up and down to tilt; on a Mac the left mouse drags, the right one turns and
##   tilts, the wheel zooms. GLIDE and SPIN give the smooth, eased moves a video needs (dolly,
##   truck, orbit). CAM TO CAR brings the camera back to the car, CAR HERE puts the car on the lane
##   nearest the camera (main.gd `_teleport_from_map`), so a drive can start in the frame. A far
##   jump: hold the full map where the car should go, then CAM TO CAR.
## - The clock: -15 / +15 minutes (game_time.gd `nudge`, time_of_day.gd `shift_clock`) and its
##   speed (pause, 1x, the game's 30x, 120x, 600x for a time-lapse; back to the game's when off).
## - Reading the frame: the readout (world X / Y / Z, latitude and longitude, yaw and compass,
##   tilt, the view's height in metres, game day, time and date, the sun's height, the weather),
##   frame guides (16:9, 9:16, 4:5, 1:1 inside the phone's ~19.5:9 screen), a rule-of-thirds grid
##   with the centre, and the HUD shown, GHOST (invisible, its controls still work: drive with no
##   buttons in the picture) or hidden. CLEAN hides the promo panel too; three quick taps in the
##   top-left corner bring it back.
## - Shots: SAVE keeps the frame (camera, clock) in the settings (`promo_shots`, MAX_SHOTS), NEXT
##   goes to the next saved one, COPY (or a tap on the readout) puts the game flags that render the
##   same frame on the clipboard (`--cam=X,Y,Z --yaw= --pitch= --size= --game-clock --clock=
##   --date=`), for tools/shots.sh or a Movie Maker clip at 1080x1920 on the Mac.
## - VERTICAL / HORIZONTAL (F 2026-11-20: "for vertical reels all the interface ... can change to
##   horizontal or vertical"): the screen itself turns to portrait and back (`set_portrait`), the
##   panel moves to the bottom, the guide goes to 9:16 and the view keeps its metres per pixel (the
##   view's height grows with the screen's); PROMO OFF turns it back. The phone's image keeps its
##   landscape sharpness (main.gd `_apply_style` measures the short side). On the iPhone it needs a
##   build that allows portrait (tools/export_ios.sh --portrait, the `promo_portrait` feature):
##   iOS stops an app that turns to an orientation its Info.plist does not list, and the players'
##   builds stay landscape only. On a Mac the window turns.
## The camera is orthographic (docs/architecture/decisions.md): there is no field of view; the
## view's height in metres is its zoom (the readout's VIEW, the copied --size).

const UiKit := preload("res://scripts/ui_kit.gd")
const Lang := preload("res://scripts/lang.gd")
const GameTime := preload("res://scripts/game_time.gd")
const Pacer := preload("res://scripts/pacer.gd")
const Heli := preload("res://scripts/heli.gd")
const DevFlags := preload("res://scripts/dev_flags.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Trams := preload("res://scripts/trams.gd")

enum Cam { CAR, FREE }
enum HudShow { SHOW, GHOST, HIDE }

## The frame guides: a name and the frame's width over its height (0: the whole screen).
const GUIDES := [["FULL", 0.0], ["16:9", 16.0 / 9.0], ["9:16", 9.0 / 16.0], ["4:5", 0.8], ["1:1", 1.0]]
## The clock's speeds (game seconds a real second); index 2 is the game's own (pacing.json time.speed).
const SPEEDS := [0.0, 1.0, 30.0, 120.0, 600.0]
const GAME_SPEED := 2
## Tilt over the ground (degrees) and the view's height (metres).
const PITCH := Vector2(5.0, 90.0)
const SIZE := Vector2(10.0, 900.0)
const LIFT := Vector2(-40.0, 400.0)
const MAX_SHOTS := 12
## main.gd CAMERA_DISTANCE: the camera sits this far back (or the view's 1.6 x), as the game's.
const DISTANCE := 500.0
## The map's flat projection (tools/bake_osm.py ORIGIN, M_PER_DEG_*): x east, z south.
const ORIGIN := Vector2(52.234, 21.024)
const M_PER_DEG_LAT := 110574.0
## Held buttons: one step at once, then this rate a second after HOLD_DELAY.
const HOLD_DELAY := 0.25
const YAW_RATE := 40.0
const PITCH_RATE := 20.0
const ZOOM_RATE := 0.9
const LIFT_RATE := 25.0
## GLIDE's step (a share of the view's height a second) and SPIN's (degrees a second); the moves
## ease in and out at EASE per second.
const GLIDE_STEP := 0.025
const SPIN_STEP := 2.0
const EASE := 1.2
## The corner that brings CLEAN back: three taps within TAP_GAP s.
const CORNER := 90.0
const TAP_GAP := 0.6

## main.gd (the camera, the car, the helicopter, the map, the clock, the HUD, the settings).
var game: Node
var on := false
var cam_mode := Cam.CAR
var focus := Vector3.ZERO
var lift := 0.0
var yaw := 45.0
var pitch := 30.0
var size := 80.0
var yaw_offset := 0.0
var yaw_lock := false
var hud_show := HudShow.SHOW
var guide := 0
var grid := false
var clean := false
var speed_i := GAME_SPEED
## GLIDE and SPIN as set: x forward and y right (shares of the view a second), z spin (deg/s).
var move := Vector3.ZERO
var shot_i := -1
var log_on := true
## The screen turned to portrait (`set_portrait`).
var portrait := false

var _move_now := Vector3.ZERO
var _glide := Vector2.ZERO
var _snap := true
var _layer: CanvasLayer
var _capture: Control
var _overlay: Control
var _readout: Label
var _readout_box: PanelContainer
var _strip: HBoxContainer
var _panel: PanelContainer
var _panel_open := false
var _buttons := {}
var _held := {}
var _touches := {}
var _mouse_button := 0
var _ghost: CanvasModulate
var _readout_t := 0.0
var _corner_taps := 0
var _corner_ms := 0
var _pt := 1.0
var _last_h := 0.0


## Promo Mode on or off (settings.gd `promo`); the camera starts on the car either way.
func set_on(value: bool) -> void:
	if value == on:
		return
	on = value
	if on:
		_build()
		var c: Camera3D = game.cam
		focus = game.cam_focus
		yaw = game.cam_yaw
		pitch = -float(game.camera_pitch) if not game.top_down else 90.0
		size = c.size
		lift = 0.0
		_snap = true
		_layer.visible = true
		_apply_hud()
		_apply_speed()
		_refresh()
	else:
		set_portrait(false)
		if _layer != null:
			_layer.visible = false
		_held.clear()
		_touches.clear()
		move = Vector3.ZERO
		_move_now = Vector3.ZERO
		cam_mode = Cam.CAR
		_apply_hud_off()
		if game.tod != null and game.tod.game_clock:
			game.tod.speed = Pacer.num("time", "speed")
		speed_i = GAME_SPEED
		game.camera_pitch = -float(game.settings.pitch)
		game._cut_camera()
	set_process(on)
	set_process_input(on)
	_log("promo: %s" % ("on" if on else "off"))


## --promo=free,grid,...: the switches a test run or a screenshot starts with (dev_flags.gd).
func use_flag(text: String) -> void:
	if not on or text == "":
		return
	for w in text.split(","):
		match w.strip_edges():
			"free": _set_cam(Cam.FREE)
			"lock": yaw_lock = true
			"grid": grid = true
			"ghost": hud_show = HudShow.GHOST
			"nohud": hud_show = HudShow.HIDE
			"clean": clean = true
			"panel": _panel_open = true
			"vertical": set_portrait(true)
			var g:
				for i in GUIDES.size():
					if GUIDES[i][0] == g:
						guide = i
	_apply_hud()
	_refresh()


## Whether this build may turn the screen: a phone build only with the `promo_portrait` feature
## (tools/export_ios.sh --portrait, which also lists portrait in the Info.plist, or iOS stops the
## app), so the players' iPhone and Android builds never turn; a Mac turns its window.
static func can_turn() -> bool:
	return not OS.has_feature("mobile") or OS.has_feature("promo_portrait")


## VERTICAL (true) or HORIZONTAL: the phone's screen turns (DisplayServer orientation; back to the
## game's sensor landscape), a Mac's window turns (fitted to the screen); a headless run only
## lays the panel out for the new screen when its size changes. The guide follows: 9:16 for
## portrait, the full screen back.
func set_portrait(value: bool) -> void:
	if value == portrait or (value and not can_turn()):
		return
	portrait = value
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT if portrait else DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	elif DisplayServer.get_name() != "headless":
		var w := Vector2(DisplayServer.window_get_size())
		if (w.y > w.x) != portrait:
			var turned := Vector2(w.y, w.x)
			var room := Vector2(DisplayServer.screen_get_usable_rect().size) * 0.95
			var fit := minf(1.0, minf(room.x / turned.x, room.y / turned.y))
			DisplayServer.window_set_size(Vector2i(turned * fit))
	if portrait and guide == 0:
		guide = 2  # 9:16
	elif not portrait and guide == 2:
		guide = 0
	_log("promo: %s" % ("vertical" if portrait else "horizontal"))
	_place_panel()
	_refresh()


## main.gd `_read_input`: the free camera parks the car (and holds the helicopter).
func holds_car() -> bool:
	return on and cam_mode == Cam.FREE


## main.gd `_update_camera`, every frame: true when Promo Mode placed the camera.
func frame(dt: float) -> bool:
	if not on:
		return false
	if cam_mode == Cam.CAR:
		_ride(dt)
	else:
		_fly(dt)
	_snap = false
	pitch = clampf(pitch, PITCH.x, PITCH.y)
	size = clampf(size, SIZE.x, SIZE.y)
	game.cam_focus = focus
	game.cam_yaw = yaw
	game.cam_yaw_target = yaw
	game.camera_pitch = -pitch
	var c: Camera3D = game.cam
	var basis := Basis.from_euler(Vector3(deg_to_rad(-pitch), deg_to_rad(yaw), 0.0))
	var distance := maxf(DISTANCE, size * 1.6)
	c.size = size
	c.global_transform = Transform3D(basis, _pixel_snap(focus + basis.z * distance, basis))
	# The far plane just past the ground at the screen's top edge (an orthographic ray up the
	# screen by half the view meets the focus's ground `cot(tilt)` of it further on), and the
	# river or a lower street below it.
	var s := sin(deg_to_rad(maxf(pitch, PITCH.x)))
	c.far = c.near + distance + 0.5 * size * cos(deg_to_rad(pitch)) / s + (maxf(lift, 0.0) + 60.0) / s + 80.0
	return true


## CAR: the focus follows the vehicle; the yaw follows its heading plus the offset, or stays.
func _ride(dt: float) -> void:
	var v: Node3D = game.heli if game.flying else game.car
	var at := v.get_global_transform_interpolated().origin
	at.y += lift
	focus = at if _snap else focus.lerp(at, 1.0 - exp(-8.0 * dt))
	_move_now = _move_now.lerp(Vector3(0.0, 0.0, move.z), 1.0 - exp(-EASE * dt))
	if yaw_lock:
		yaw += _move_now.z * dt
	else:
		var want := rad_to_deg(v.rotation.y) + yaw_offset
		var err := wrapf(want - yaw, -180.0, 180.0)
		yaw += err if _snap else err * (1.0 - exp(-2.5 * dt))
	_hold_frame(dt)


## FREE: the eased GLIDE and SPIN, the finger's glide, the held buttons; the focus keeps to the
## ground under it plus the lift.
func _fly(dt: float) -> void:
	_move_now = _move_now.lerp(move, 1.0 - exp(-EASE * dt))
	var fwd := _forward()
	var right := _right()
	focus += (fwd * _move_now.x + right * _move_now.y) * size * dt
	focus += (right * _glide.x + fwd * _glide.y) * dt
	yaw += _move_now.z * dt
	if _touches.is_empty() and _mouse_button == 0:
		_glide *= exp(-2.5 * dt)
	_hold_frame(dt)
	var ground: float = game.map.ground_height(focus.x, focus.z) if game.map != null else 0.0
	var want := ground + lift
	focus.y = want if _snap else lerpf(focus.y, want, 1.0 - exp(-6.0 * dt))


func _forward() -> Vector3:
	var r := deg_to_rad(yaw)
	return Vector3(-sin(r), 0.0, -cos(r))


func _right() -> Vector3:
	var r := deg_to_rad(yaw)
	return Vector3(cos(r), 0.0, -sin(r))


## A point moved onto the view's pixel grid (main.gd `_snap_to_pixels`): no shimmer as it moves.
func _pixel_snap(p: Vector3, basis: Basis) -> Vector3:
	var lines := 720
	if game.sv != null:
		lines = maxi(game.sv.size.y, 1)
	var texel := size / float(lines)
	var r := p.dot(basis.x)
	var u := p.dot(basis.y)
	return p - basis.x * (r - snappedf(r, texel)) - basis.y * (u - snappedf(u, texel))


func _process(dt: float) -> void:
	_readout_t -= dt
	if _readout_t <= 0.0:
		_readout_t = 0.1
		_refresh()


# --- the clock ---------------------------------------------------------------------------------

func _nudge(minutes: float) -> void:
	GameTime.nudge(game.tod, minutes)
	_log("promo: clock %+d min -> %s" % [int(minutes), _clock_text()])
	_refresh()


func _apply_speed() -> void:
	if game.tod != null and game.tod.game_clock:
		game.tod.speed = SPEEDS[speed_i] if speed_i != GAME_SPEED else Pacer.num("time", "speed")


func _clock_text() -> String:
	if game.tod == null:
		return "--:--"
	return str(GameTime.label(game.tod.local_clock())[1])


## The game clock's date, YYYYMMDD (Warsaw), 0 without the game clock.
func _date() -> int:
	if game.tod == null or not game.tod.game_clock:
		return 0
	var t: float = game.tod.now_utc()
	var d := Time.get_datetime_dict_from_unix_time(int(t) + game.tod.warsaw_offset(t))
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])


# --- the HUD -----------------------------------------------------------------------------------

func _apply_hud() -> void:
	var hud: CanvasLayer = game.hud
	if hud == null:
		return
	if _ghost == null:
		_ghost = CanvasModulate.new()
		_ghost.name = "PromoGhost"
		hud.add_child(_ghost)
	_ghost.color = Color(Color.WHITE, 0.0) if hud_show == HudShow.GHOST else Color.WHITE
	_ghost.visible = hud_show == HudShow.GHOST
	hud.visible = hud_show != HudShow.HIDE


func _apply_hud_off() -> void:
	if _ghost != null:
		_ghost.visible = false
	if game.hud != null:
		game.hud.visible = true
	hud_show = HudShow.SHOW
	clean = false


# --- shots -------------------------------------------------------------------------------------

## The game flags that render this frame (dev_flags.gd: --cam, --yaw, --pitch, --size, --clock,
## --date, --weather).
func shot_flags() -> String:
	var parts := PackedStringArray()
	parts.append("--cam=%.1f,%.1f,%.1f" % [focus.x, focus.y, focus.z])
	parts.append("--yaw=%.1f" % fposmod(yaw, 360.0))
	parts.append("--pitch=%.1f" % -pitch)
	parts.append("--size=%.1f" % size)
	if game.tod != null:
		var h := float(game.tod.local_clock()["hour"])
		parts.append("--game-clock")
		parts.append("--clock=%02d:%02d" % [int(h), int(fmod(h, 1.0) * 60.0)])
		var d := _date()
		if d > 0:
			parts.append("--date=%d" % d)
	if game.weather != null and game.weather.state != 0:
		parts.append("--weather=rain")
	return " ".join(parts)


func _copy() -> void:
	var text := shot_flags()
	DisplayServer.clipboard_set(text)
	_log("promo: shot %s" % text)
	if game.hud != null:
		game.hud.toast("Kadr skopiowany do schowka", "Shot copied to the clipboard")


## A saved shot: "x,y,z,yaw,pitch,size,hour,date".
func _save_shot() -> void:
	var h := float(game.tod.local_clock()["hour"]) if game.tod != null else -1.0
	var line := "%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.3f,%d" % [focus.x, focus.y, focus.z, fposmod(yaw, 360.0), pitch, size, h, _date()]
	var shots: PackedStringArray = game.settings.promo_shots
	shots.append(line)
	while shots.size() > MAX_SHOTS:
		shots.remove_at(0)
	game.settings.promo_shots = shots
	shot_i = shots.size() - 1
	_save_settings()
	_log("promo: saved shot %d: %s" % [shot_i + 1, line])
	if game.hud != null:
		game.hud.toast("Kadr %d zapisany" % (shot_i + 1), "Shot %d saved" % (shot_i + 1))
	_refresh()


func _next_shot() -> void:
	var shots: PackedStringArray = game.settings.promo_shots
	if shots.is_empty():
		if game.hud != null:
			game.hud.toast("Brak kadrow: SAVE", "No shots yet: SAVE one")
		return
	shot_i = (shot_i + 1) % shots.size()
	var f := shots[shot_i].split(",")
	if f.size() < 6:
		return
	cam_mode = Cam.FREE
	focus = Vector3(float(f[0]), float(f[1]), float(f[2]))
	yaw = float(f[3])
	pitch = float(f[4])
	size = float(f[5])
	move = Vector3.ZERO
	_move_now = Vector3.ZERO
	_glide = Vector2.ZERO
	var ground: float = game.map.ground_height(focus.x, focus.z) if game.map != null else focus.y
	lift = focus.y - ground
	if f.size() > 6 and float(f[6]) >= 0.0 and game.tod != null:
		game.tod.set_hour(float(f[6]), true)
	_snap = true
	_log("promo: shot %d of %d" % [shot_i + 1, shots.size()])
	_refresh()


func _drop_shot() -> void:
	var shots: PackedStringArray = game.settings.promo_shots
	if shot_i < 0 or shot_i >= shots.size():
		return
	shots.remove_at(shot_i)
	game.settings.promo_shots = shots
	shot_i = mini(shot_i, shots.size() - 1)
	_save_settings()
	_refresh()


func _save_settings() -> void:
	game.settings.save()  # settings.gd writes nothing on a --nosave run


# --- the panel ---------------------------------------------------------------------------------

func _build() -> void:
	if _layer != null:
		return
	_pt = float(game.hud.pt) if game.hud != null else 1.0
	_layer = CanvasLayer.new()
	_layer.name = "PromoMode"
	_layer.layer = 4  # over the HUD (and Fotka's 3)
	add_child(_layer)
	var safe: Rect2 = game.hud.safe_rect() if game.hud != null else Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)

	_overlay = Control.new()
	_overlay.name = "promo_guides"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_guides)
	_layer.add_child(_overlay)

	_capture = Control.new()
	_capture.name = "promo_capture"
	_capture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capture.mouse_filter = Control.MOUSE_FILTER_STOP
	_capture.gui_input.connect(_gesture)
	_layer.add_child(_capture)

	_readout_box = PanelContainer.new()
	_readout_box.name = "promo_readout"
	_readout_box.add_theme_stylebox_override("panel", UiKit.card(_pt, 6.0, UiKit.R_SMALL))
	_readout_box.position = safe.position + Vector2(8.0, 8.0) * _pt  # `_place_panel` centres it
	_readout_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_readout_box.gui_input.connect(func(e: InputEvent) -> void:
		# A touch arrives as a touch and as its mouse copy: take the mouse one only (once).
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_copy())
	_layer.add_child(_readout_box)
	_readout = Label.new()
	UiKit.style_label(_readout, "body", _pt, UiKit.T_LABEL)
	_readout.add_theme_font_override("font", _mono())
	_readout_box.add_child(_readout)

	_strip = HBoxContainer.new()
	_strip.name = "promo_strip"
	_strip.add_theme_constant_override("separation", UiKit.px(6.0, _pt))
	_layer.add_child(_strip)
	_button(_strip, "minus15", "-15 MIN", func() -> void: _nudge(-15.0))
	_button(_strip, "plus15", "+15 MIN", func() -> void: _nudge(15.0), UiKit.Kind.PRIMARY)
	_button(_strip, "rotate", "VERTICAL", func() -> void: set_portrait(not portrait))
	(_buttons["rotate"] as Button).visible = can_turn()
	_button(_strip, "panel", "PROMO", func() -> void:
		_panel_open = not _panel_open
		_refresh())
	_strip.position = Vector2(safe.get_center().x - 120.0 * _pt, safe.position.y + 8.0 * _pt)

	_panel = PanelContainer.new()
	_panel.name = "promo_panel"
	_panel.add_theme_stylebox_override("panel", UiKit.card(_pt, 8.0))
	_layer.add_child(_panel)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", UiKit.px(10.0, _pt))
	_panel.add_child(cols)
	var a := VBoxContainer.new()
	var b := VBoxContainer.new()
	for col in [a, b]:
		col.add_theme_constant_override("separation", UiKit.px(5.0, _pt))
		cols.add_child(col)
	var r := _row(a, "CAM")
	_button(r, "car", "CAR", func() -> void: _set_cam(Cam.CAR))
	_button(r, "free", "FREE", func() -> void: _set_cam(Cam.FREE))
	_button(r, "lock", "LOCK", func() -> void:
		yaw_lock = not yaw_lock
		_refresh())
	r = _row(a, "YAW")
	_hold(r, "yaw_l", "◀", func(k: float) -> void: _turn(-k))
	_hold(r, "yaw_r", "▶", func(k: float) -> void: _turn(k))
	_button(r, "yaw_0", "0°", func() -> void:
		if cam_mode == Cam.CAR and not yaw_lock:
			yaw_offset = 0.0
		else:
			yaw = 0.0
		_refresh())
	r = _row(a, "TILT")
	_hold(r, "tilt_d", "▼", func(k: float) -> void: pitch = clampf(pitch - k * PITCH_RATE, PITCH.x, PITCH.y))
	_hold(r, "tilt_u", "▲", func(k: float) -> void: pitch = clampf(pitch + k * PITCH_RATE, PITCH.x, PITCH.y))
	_button(r, "tilt_30", "30°", func() -> void: pitch = 30.0)
	r = _row(a, "VIEW")
	_hold(r, "zoom_in", "+", func(k: float) -> void: size = clampf(size * exp(-k * ZOOM_RATE), SIZE.x, SIZE.y))
	_hold(r, "zoom_out", "-", func(k: float) -> void: size = clampf(size * exp(k * ZOOM_RATE), SIZE.x, SIZE.y))
	_button(r, "view_80", "80 M", func() -> void: size = 80.0)
	r = _row(a, "LIFT")
	_hold(r, "lift_d", "DOWN", func(k: float) -> void: lift = clampf(lift - k * LIFT_RATE, LIFT.x, LIFT.y))
	_hold(r, "lift_u", "UP", func(k: float) -> void: lift = clampf(lift + k * LIFT_RATE, LIFT.x, LIFT.y))
	_button(r, "lift_0", "0 M", func() -> void: lift = 0.0)
	r = _row(a, "GLIDE")
	_button(r, "glide_f", "▲", func() -> void: _glide_step(Vector3(GLIDE_STEP, 0.0, 0.0)))
	_button(r, "glide_b", "▼", func() -> void: _glide_step(Vector3(-GLIDE_STEP, 0.0, 0.0)))
	_button(r, "glide_l", "◀", func() -> void: _glide_step(Vector3(0.0, -GLIDE_STEP, 0.0)))
	_button(r, "glide_r", "▶", func() -> void: _glide_step(Vector3(0.0, GLIDE_STEP, 0.0)))
	r = _row(a, "SPIN")
	_button(r, "spin_l", "LEFT", func() -> void: _glide_step(Vector3(0.0, 0.0, SPIN_STEP)))
	_button(r, "spin_r", "RIGHT", func() -> void: _glide_step(Vector3(0.0, 0.0, -SPIN_STEP)))
	_button(r, "stop", "STOP", _stop_moves, UiKit.Kind.DANGER)

	r = _row(b, "CLOCK")
	_button(r, "speed", "30x", func() -> void:
		speed_i = (speed_i + 1) % SPEEDS.size()
		_apply_speed()
		_refresh())
	_button(r, "m60", "-1 H", func() -> void: _nudge(-60.0))
	_button(r, "p60", "+1 H", func() -> void: _nudge(60.0))
	r = _row(b, "LOOK")
	_button(r, "hud", "HUD", func() -> void:
		hud_show = ((hud_show + 1) % 3) as HudShow
		_apply_hud()
		_refresh())
	_button(r, "grid", "GRID", func() -> void:
		grid = not grid
		_refresh())
	_button(r, "guide", "FULL", func() -> void:
		guide = (guide + 1) % GUIDES.size()
		_refresh())
	r = _row(b, "")
	_button(r, "clean", "CLEAN", func() -> void:
		clean = true
		if hud_show == HudShow.SHOW:
			hud_show = HudShow.GHOST
			_apply_hud()
		_refresh())
	r = _row(b, "SHOT")
	_button(r, "save", "SAVE", _save_shot, UiKit.Kind.PRIMARY)
	_button(r, "next", "NEXT", _next_shot)
	_button(r, "copy", "COPY", _copy)
	r = _row(b, "")
	_button(r, "drop", "DELETE", _drop_shot, UiKit.Kind.DANGER)
	r = _row(b, "PLACE")
	_button(r, "to_car", "CAM TO CAR", func() -> void:
		cam_mode = Cam.CAR
		_snap = true
		_refresh())
	r = _row(b, "")
	_button(r, "car_here", "CAR HERE", func() -> void:
		game._teleport_from_map(Vector2(focus.x, focus.z))
		_log("promo: car to %.0f, %.0f" % [focus.x, focus.z]))
	r = _row(b, "")
	_button(r, "off", "PROMO OFF", _turn_off, UiKit.Kind.DANGER)
	_place_panel()
	get_viewport().size_changed.connect(_place_panel)


func _place_panel() -> void:
	if _panel == null:
		return
	var safe: Rect2 = game.hud.safe_rect() if game.hud != null else Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	# The screen turned (VERTICAL): the view's height in metres grows with the screen's, so a
	# metre keeps its pixels and the frame its scale.
	var h := get_viewport().get_visible_rect().size.y
	if _last_h > 0.0 and absf(h - _last_h) > 1.0:
		size = clampf(size * h / _last_h, SIZE.x, SIZE.y)
	_last_h = h
	_panel.reset_size()
	_panel.scale = Vector2.ONE
	var s := _panel.get_combined_minimum_size()
	if safe.size.y > safe.size.x:
		# Portrait: the panel at the bottom, centred, shrunk to the width if it must be.
		var k := minf(1.0, (safe.size.x - 8.0 * _pt) / s.x)
		_panel.scale = Vector2(k, k)
		_panel.position = Vector2(safe.get_center().x - s.x * k * 0.5, safe.end.y - s.y * k - 8.0 * _pt)
	else:
		_panel.position = Vector2(safe.end.x - s.x - 8.0 * _pt, maxf(safe.position.y + 8.0 * _pt, safe.get_center().y - s.y * 0.5))
	# The readout top left (over the minimap: the panel takes the right), the clock's strip under it.
	_readout_box.reset_size()
	var r := _readout_box.get_combined_minimum_size()
	_readout_box.position = safe.position + Vector2(4.0, 4.0) * _pt
	_strip.reset_size()
	_strip.position = Vector2(_readout_box.position.x, _readout_box.position.y + r.y + 4.0 * _pt)


func _row(parent: Control, title: String) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", UiKit.px(5.0, _pt))
	parent.add_child(r)
	var l := Label.new()
	UiKit.style_label(l, "label", _pt)
	l.text = title
	l.custom_minimum_size = Vector2(40.0 * _pt, 0.0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r.add_child(l)
	return r


func _button(parent: Control, key: String, text: String, pressed: Callable, kind := UiKit.Kind.SECONDARY) -> Button:
	var b := Button.new()
	b.name = "promo_" + key
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(36.0 * _pt, 32.0 * _pt)
	UiKit.style_button(b, kind, _pt, UiKit.T_LABEL)
	b.pressed.connect(pressed)
	b.set_meta("kind", kind)
	parent.add_child(b)
	_buttons[key] = b
	return b


## A button that steps once when pressed and keeps going while held (`act` takes the share of the
## rate: a small step at the press, rate x dt after HOLD_DELAY).
func _hold(parent: Control, key: String, text: String, act: Callable) -> void:
	var b := _button(parent, key, text, func() -> void: pass)
	b.button_down.connect(func() -> void:
		act.call(0.05)
		_held[key] = [act, 0.0])
	b.button_up.connect(func() -> void: _held.erase(key))


func _hold_frame(dt: float) -> void:
	for key: String in _held:
		var h: Array = _held[key]
		h[1] = float(h[1]) + dt
		if float(h[1]) > HOLD_DELAY:
			(h[0] as Callable).call(dt)


func _turn(k: float) -> void:
	if cam_mode == Cam.CAR and not yaw_lock:
		yaw_offset = wrapf(yaw_offset + k * YAW_RATE, -180.0, 180.0)
	else:
		yaw += k * YAW_RATE


func _stop_moves() -> void:
	move = Vector3.ZERO
	_glide = Vector2.ZERO
	_refresh()


func _turn_off() -> void:
	game.settings.promo = false
	_save_settings()
	set_on(false)


func _glide_step(d: Vector3) -> void:
	move += d
	_refresh()


func _set_cam(m: Cam) -> void:
	cam_mode = m
	_glide = Vector2.ZERO
	if m == Cam.FREE:
		lift = 0.0
		move.x = 0.0
		move.y = 0.0
	else:
		_snap = true
	_refresh()


func _mono() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Menlo", "Courier New", "DejaVu Sans Mono", "monospace"])
	return f


## The readout and the buttons' states.
func _refresh() -> void:
	if _layer == null or not on:
		return
	var c: Dictionary = game.tod.local_clock() if game.tod != null else {}
	var lat := ORIGIN.x - focus.z / M_PER_DEG_LAT
	var lon := ORIGIN.y + focus.x / (111320.0 * cos(deg_to_rad(ORIGIN.x)))
	var ground: float = game.map.ground_height(focus.x, focus.z) if game.map != null else 0.0
	var screen := get_viewport().get_visible_rect().size
	var lines := PackedStringArray()
	lines.append("X %8.1f  Y %6.1f  Z %8.1f" % [focus.x, focus.y, focus.z])
	lines.append("%.5f N  %.5f E  ground %.1f" % [lat, lon, ground])
	lines.append("YAW %5.1f° (%s)  TILT %4.1f°  VIEW %5.1f m" % [fposmod(yaw, 360.0), _compass(yaw), pitch, size])
	var sun := "sun %+.1f°" % float(game.tod.sun_elevation) if game.tod != null and game.tod.game_clock else "fixed look"
	lines.append("%s  %s  %s  %s" % [_clock_text(), _date_text(), sun,
			"rain" if game.weather != null and game.weather.state != 0 else "dry"])
	var cam_word := ("VERT " if portrait else "") + ("FREE" if cam_mode == Cam.FREE else ("CAR LOCK" if yaw_lock else "CAR %+.0f°" % yaw_offset))
	lines.append("%s  clock %s  %s  %dx%d" % [cam_word, _speed_word(), GUIDES[guide][0], int(screen.x), int(screen.y)])
	if move != Vector3.ZERO:
		lines.append("GLIDE %+.3f %+.3f  SPIN %+.1f°/s" % [move.x, move.y, move.z])
	var shots: PackedStringArray = game.settings.promo_shots
	lines.append("shots %d/%d  tap here = COPY" % [shot_i + 1 if shot_i >= 0 else 0, shots.size()])
	_readout.text = "\n".join(lines)
	if _readout_box.size.x < _readout_box.get_combined_minimum_size().x - 0.5 or _readout_box.size.y != _readout_box.get_combined_minimum_size().y:
		_place_panel()
	_capture.visible = cam_mode == Cam.FREE and not clean
	_panel.visible = _panel_open and not clean
	_strip.visible = not clean
	_readout_box.visible = not clean
	_mark("car", cam_mode == Cam.CAR)
	_mark("free", cam_mode == Cam.FREE)
	_mark("lock", yaw_lock)
	_mark("grid", grid)
	_mark("panel", _panel_open)
	_mark("hud", hud_show != HudShow.SHOW)
	_mark("guide", guide != 0)
	(_buttons["hud"] as Button).text = ["HUD", "GHOST", "NO HUD"][hud_show]
	(_buttons["guide"] as Button).text = str(GUIDES[guide][0])
	(_buttons["speed"] as Button).text = _speed_word()
	(_buttons["rotate"] as Button).text = "HORIZONTAL" if portrait else "VERTICAL"
	_overlay.queue_redraw()


func _mark(key: String, chosen: bool) -> void:
	var b: Button = _buttons.get(key)
	if b == null:
		return
	var kind: int = UiKit.Kind.SELECTED if chosen else int(b.get_meta("kind", UiKit.Kind.SECONDARY))
	var text := b.text
	UiKit.style_button(b, kind, _pt, UiKit.T_LABEL)
	b.text = text


func _speed_word() -> String:
	return "PAUSE" if speed_i == 0 else "%dx" % int(SPEEDS[speed_i])


func _date_text() -> String:
	var d := _date()
	return "" if d == 0 else "%04d-%02d-%02d" % [d / 10000, (d / 100) % 100, d % 100]


static func _compass(y: float) -> String:
	# The camera looks along its forward: yaw 0 looks north (-z), 90 west (+x is east).
	var heading := fposmod(-y, 360.0)
	return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][int(round(heading / 45.0)) % 8]


## The frame guide (outside it dimmed) and the thirds.
func _draw_guides() -> void:
	var screen := _overlay.size
	var frame := Rect2(Vector2.ZERO, screen)
	var ratio: float = GUIDES[guide][1]
	if ratio > 0.0:
		var w := minf(screen.x, screen.y * ratio)
		var h := w / ratio
		frame = Rect2((screen - Vector2(w, h)) * 0.5, Vector2(w, h))
		var dim := Color(UiKit.CARD_SOLID, 0.72)
		_overlay.draw_rect(Rect2(0.0, 0.0, frame.position.x, screen.y), dim)
		_overlay.draw_rect(Rect2(frame.end.x, 0.0, screen.x - frame.end.x, screen.y), dim)
		_overlay.draw_rect(Rect2(frame.position.x, 0.0, frame.size.x, frame.position.y), dim)
		_overlay.draw_rect(Rect2(frame.position.x, frame.end.y, frame.size.x, screen.y - frame.end.y), dim)
		_overlay.draw_rect(frame, Color(UiKit.GOLD, 0.8), false, maxf(1.0, _pt))
	if grid:
		var line := Color(UiKit.INK, 0.45)
		for k in [1.0 / 3.0, 2.0 / 3.0]:
			var x: float = frame.position.x + frame.size.x * k
			var y: float = frame.position.y + frame.size.y * k
			_overlay.draw_line(Vector2(x, frame.position.y), Vector2(x, frame.end.y), line, maxf(1.0, _pt * 0.6))
			_overlay.draw_line(Vector2(frame.position.x, y), Vector2(frame.end.x, y), line, maxf(1.0, _pt * 0.6))
		var m := frame.get_center()
		var arm := 10.0 * _pt
		_overlay.draw_line(m - Vector2(arm, 0.0), m + Vector2(arm, 0.0), Color(UiKit.GOLD, 0.8), maxf(1.0, _pt * 0.6))
		_overlay.draw_line(m - Vector2(0.0, arm), m + Vector2(0.0, arm), Color(UiKit.GOLD, 0.8), maxf(1.0, _pt * 0.6))


# --- touch and mouse ---------------------------------------------------------------------------

## FREE: one finger drags the ground, two pinch (view), twist (yaw) and slide (tilt); the mouse
## on a Mac: left drags, right turns and tilts, the wheel zooms.
func _gesture(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var t := e as InputEventScreenTouch
		if t.pressed:
			_touches[t.index] = t.position
			_glide = Vector2.ZERO
		else:
			_touches.erase(t.index)
		return
	if e is InputEventScreenDrag:
		var d := e as InputEventScreenDrag
		if _touches.size() >= 2 and _touches.has(d.index):
			var keys := _touches.keys()
			var other: int = keys[0] if keys[0] != d.index else keys[1]
			var o: Vector2 = _touches[other]
			var before: Vector2 = _touches[d.index]
			var v0 := before - o
			var v1 := d.position - o
			if v0.length() > 4.0 and v1.length() > 4.0:
				size = clampf(size * v0.length() / v1.length(), SIZE.x, SIZE.y)
				yaw += rad_to_deg(v0.angle_to(v1))
			pitch = clampf(pitch + d.relative.y * 0.5 * 0.25, PITCH.x, PITCH.y)
		elif _touches.size() == 1:
			_pan(d.relative)
			_glide = _ground_move(d.velocity) * 0.8
		_touches[d.index] = d.position
		return
	if DisplayServer.is_touchscreen_available():
		return  # the touches came above; the mouse events are their copies
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			size = clampf(size / 1.1, SIZE.x, SIZE.y)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			size = clampf(size * 1.1, SIZE.x, SIZE.y)
		elif mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_mouse_button = mb.button_index if mb.pressed else 0
			if mb.pressed:
				_glide = Vector2.ZERO
	elif e is InputEventMouseMotion and _mouse_button != 0:
		var mm := e as InputEventMouseMotion
		if _mouse_button == MOUSE_BUTTON_LEFT:
			_pan(mm.relative)
			_glide = _ground_move(mm.velocity) * 0.8
		else:
			yaw -= mm.relative.x * 0.3
			pitch = clampf(pitch + mm.relative.y * 0.2, PITCH.x, PITCH.y)


## Screen pixels moved by the finger as ground metres (x right, y forward): the ground under the
## finger follows it.
func _ground_move(px: Vector2) -> Vector2:
	var mpp := size / maxf(get_viewport().get_visible_rect().size.y, 1.0)
	return Vector2(-px.x * mpp, px.y * mpp / maxf(sin(deg_to_rad(pitch)), 0.1))


func _pan(px: Vector2) -> void:
	var m := _ground_move(px)
	focus += _right() * m.x + _forward() * m.y


## CLEAN: three quick taps in the top-left corner bring the panel back (the touch goes on to the
## game as ever).
func _input(e: InputEvent) -> void:
	if not clean:
		return
	var at := Vector2.INF
	if e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed:
		at = (e as InputEventScreenTouch).position
	elif e is InputEventMouseButton and (e as InputEventMouseButton).pressed and not DisplayServer.is_touchscreen_available():
		at = (e as InputEventMouseButton).position
	if at == Vector2.INF or at.x > CORNER * _pt or at.y > CORNER * _pt:
		return
	var now := Time.get_ticks_msec()
	_corner_taps = _corner_taps + 1 if now - _corner_ms < int(TAP_GAP * 1000.0) else 1
	_corner_ms = now
	if _corner_taps >= 3:
		_corner_taps = 0
		clean = false
		_refresh()


func _log(line: String) -> void:
	if log_on:
		print(line)




## --promo-heli=X0,Z0,X1,Z1,UP[,SHARE[,SCALE]] (teaser 5, F 2026-11-21): a second helicopter that
## flies itself from X0,Z0 toward X1,Z1, UP m over the ground, at SHARE of full speed, with nav
## lights and no searchlight; SCALE draws it bigger, because a wide night frame shows a 12 m
## helicopter as a few dark pixels. Null when the flag is not given. main.gd keeps the node to
## switch its lights with the clock.
static func make_heli(ph: PackedFloat32Array, map: Node3D, world: Node3D) -> Node3D:
	if ph.size() < 5:
		return null
	var h := Heli.new()
	h.name = "PromoHeli"
	h.ground_height = map.ground_height
	h.top_height = map.top_height
	h.tallest_near = map.tallest_near
	h.set_map(map)
	world.add_child(h)
	var go := Vector2(ph[2] - ph[0], ph[3] - ph[1])
	h.place(Vector3(ph[0], map.ground_height(ph[0], ph[1]) + ph[4], ph[1]), atan2(-go.x, -go.y), ph[4])
	h.auto_to = Vector2(ph[2], ph[3])
	h.searchlight = false
	h.add_nav_lights()
	if ph.size() >= 6:
		h.auto_share = ph[5]
	if ph.size() >= 7:
		h.scale = Vector3.ONE * ph[6]
	print("promo heli: from %s to %s, %.0f m up, %.0f%% speed" % [h.global_position, h.auto_to, ph[4], h.auto_share * 100.0])
	return h


## --promo-at=X,Z,T (videos): with --promo-parts, trams[0] up Marszałkowska, trams[1] east along
## the Aleje two seconds later, a bus and a patrol car east along the Aleje, each placed so it passes
## X,Z about T s after the start (buses keep their lane). --promo-delay=S places them S s after the
## start instead of at once, for a clip with a long skip (the east tram otherwise waits at its stop).
const PROMO_TRAM_V := 8.0
const PROMO_BUS_V := 9.0
const PROMO_POLICE_V := 11.0
const ALEJE_EAST := Vector2(0.937, -0.349)
const MARSZALKOWSKA_NORTH := Vector2(-0.349, -0.937)


static func traffic_on_cue(f: DevFlags, tree: SceneTree, trams: Trams, traffic: Traffic, graph: LaneGraph) -> void:
	if f.promo_delay > 0.0:
		tree.create_timer(f.promo_delay, false).timeout.connect(
				func() -> void: place_traffic(f, trams, traffic, graph))
	else:
		place_traffic(f, trams, traffic, graph)


static func place_traffic(f: DevFlags, trams: Trams, traffic: Traffic, graph: LaneGraph) -> void:
	var at := f.promo_at
	if at == Vector2.INF or trams == null or trams.trams.size() < 2:
		return
	var t := f.promo_t
	traffic.steady_buses = true
	var parts := f.promo_parts
	var up := false
	var east := false
	if "tram-up" in parts:
		up = trams.place_near(trams.trams[0], at, -PROMO_TRAM_V * t, MARSZALKOWSKA_NORTH, PROMO_TRAM_V)
	if "tram-east" in parts:
		east = trams.place_near(trams.trams[1], at, -PROMO_TRAM_V * (t + 2.0), ALEJE_EAST, PROMO_TRAM_V)
	var bus := false
	# F (2026-11-21): the bus east along the Aleje behind the patrol car (up Nowy Świat it changed
	# its line at the rondo at the end of the take).
	var lane := graph.snap(at - ALEJE_EAST * (PROMO_BUS_V * (t + 4.0)), 30.0, ALEJE_EAST, true, true, true)
	if not lane.is_empty() and "bus" in parts:
		var d := traffic.add_bus(int(lane[0]), int(lane[1]), float(lane[2]))
		if d != null:
			d.v = PROMO_BUS_V
			bus = true
	# F (2026-11-21, the palm teaser): a patrol car driving through too, east along the Aleje.
	var patrol := false
	var pl := graph.snap(at - ALEJE_EAST * (PROMO_POLICE_V * (t + 1.5)), 30.0, ALEJE_EAST, true, true, true)
	if not pl.is_empty() and "police" in parts:
		var p := traffic.add_police(int(pl[0]), int(pl[1]), float(pl[2]))
		if p != null:
			p.patrol = true
			p.persistent = false
			p.v = PROMO_POLICE_V
			patrol = true
	print("promo: at %s in %.1f s: tram up %s, tram east %s, bus %s, patrol %s" % [at, t, up, east, bus, patrol])
