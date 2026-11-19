extends Node
## Loop MW-6 (docs/design/vision.md 4.2): Fotka, the photo mode. Opened from the settings card
## (OBRAZ · picture: FOTKA) or --fotka. The HUD goes, the car stops (main.gd holds it), the
## traffic and the people keep moving, and a camera of its own (an orthographic Camera3D, made
## current while Fotka is open; the follow camera, follow_camera.gd, is not touched) orbits the
## car with one finger: yaw all the way round, pitch 20-70 degrees, the view 30-250 m tall (−
## and +, a pinch or the mouse wheel). The style and the VHS overlay apply as set (they are the
## view's). The shutter saves the screen as a PNG to user://photos/ (sharing waits for the
## Share plugin: BACKLOG). A shot with a Kadr spot's subject (data/kadr.json, 15 spots) inside
## the frame's central 60 %, the camera's focus within 300 m of it and at the spot's time of day
## is a KADR: +20 respect, the notebook's stamp and the photo on the spot's card (wallet.gd
## `kadr`, `kadr_photos`).
##
## Cost: nothing while closed. The UI (a CanvasLayer of a few Controls) is built at the first
## open and hidden after; the camera is not current, so it draws nothing; no _process.

const UiKit := preload("res://scripts/ui_kit.gd")  # the one look (docs/design/ui-kit.md)
const Lang := preload("res://scripts/lang.gd")

signal opened
signal closed

const KADR_PATH := "res://data/kadr.json"
const PHOTOS := "user://photos"
const YAW_PER_PT := 0.45
const PITCH_PER_PT := 0.3
const PITCH := Vector2(20.0, 70.0)
const ZOOM := Vector2(30.0, 250.0)
const DISTANCE := 500.0
## A Kadr: the subject inside the frame's central share, the focus within this many metres.
const CENTRAL := 0.6
const KADR_REACH := 300.0
const KADR_RESPECT := 20
## The subject's point above the ground (m): the middle of a view of it.
const SUBJECT_LIFT := 8.0
const ACCENT := UiKit.GOLD
const INK := UiKit.INK
const SUB := UiKit.SUB
const CARD_BG := UiKit.CARD
const KADR_COLOUR := Color("#1ae6ff")
const T_TITLE := 17.0
const T_BODY := 15.0
const T_SUB := 13.0
const T_LABEL := 11.0

## The Kadr spots: kadr.json's fields plus `at` (Vector2: the place's point; INF if unknown).
var spots: Array[Dictionary] = []
var wallet: Node
var hud: CanvasLayer
var map: Node3D
## The 3D world (the camera goes in it) and the main camera (its far plane and cull mask).
var world: Node3D
var main_cam: Camera3D
## main.gd: the time of day's look now ("Day", "Dusk", "Night"; Live by the sun) for a Kadr.
var look: Callable
## The game's post pass (a MeshInstance3D on the main camera): it moves to Fotka's camera while
## open and back after.
var post_quad: Node3D
var blip: Callable
## --photo-log: `fotka:` and `kadr:` lines.
var log_on := false
var pt := 1.0
var safe := Rect2()
## The orbit: its centre (the car), yaw and pitch in degrees, the view's height in metres.
var focus := Vector3.ZERO
var yaw := 45.0
var pitch := 40.0
var zoom := 110.0
## The last photo's path and its Kadr ("" for none).
var last_path := ""
var last_kadr := ""
var cam: Camera3D
var layer: CanvasLayer
var _root: Control
var _saved: Label
var _hint_pl: Label
var _hint_en: Label
var _buttons := {}
var _open := false
var _touches := {}
var _pinch := 0.0
var _saved_left := 0.0


## Reads kadr.json. False if missing.
func load_spots() -> bool:
	if not FileAccess.file_exists(KADR_PATH):
		return false
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(KADR_PATH))
	if not json is Dictionary:
		push_error("fotka: %s does not parse" % KADR_PATH)
		return false
	spots.clear()
	for k: Dictionary in json.get("kadr", []):
		var spot := k.duplicate(true)
		spot["at"] = Vector2.INF
		spots.append(spot)
	return true


## The spots on the map: `places` (notebook.gd: id -> Vector2), `eggs` (eggs.gd spots: id -> Vector3).
func setup(places: Dictionary, eggs_spots: Dictionary) -> void:
	if spots.is_empty():
		load_spots()
	for s in spots:
		var pid := str(s["place"])
		if places.has(pid):
			s["at"] = places[pid]
		elif eggs_spots.has(pid):
			var v: Vector3 = eggs_spots[pid]
			s["at"] = Vector2(v.x, v.z)
	set_process(false)


func is_open() -> bool:
	return _open


## The spot's time of day in words, Polish and English ("o zmierzchu", "at dusk").
static func look_text(spot: Dictionary) -> Array:
	match str(spot.get("look", "")):
		"Day":
			return ["Za dnia.", "By day."]
		"Dusk":
			return ["O zmierzchu.", "At dusk."]
		"Night":
			return ["Nocą.", "At night."]
	return ["O każdej porze.", "At any time."]


## Opened from a spot's lock: the egg it waits for is found.
func spot_open(spot: Dictionary) -> bool:
	var by := str(spot.get("locked_by", ""))
	return by == "" or (wallet != null and wallet.eggs.has(by))


# --- open and close ----------------------------------------------------------------------

## Opens Fotka round `at` (the car), starting from the follow camera's yaw and pitch.
func open(at: Vector3, from_yaw: float, from_pitch: float, from_size: float) -> void:
	if _open:
		return
	focus = at
	yaw = from_yaw
	pitch = clampf(absf(from_pitch), PITCH.x, PITCH.y)
	zoom = clampf(from_size, ZOOM.x, ZOOM.y)
	if layer == null:
		build_ui()
	if cam == null and world != null:
		cam = Camera3D.new()
		cam.name = "FotkaCamera"
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.near = 1.0
		world.add_child(cam)
	_open = true
	layer.visible = true
	_saved.visible = false
	if hud != null:
		hud.visible = false
	if cam != null:
		if main_cam != null:
			cam.cull_mask = main_cam.cull_mask
			cam.environment = main_cam.environment
		if post_quad != null:
			post_quad.reparent(cam, false)
		cam.make_current()
		_place_camera()
	set_process(true)
	if log_on:
		print("fotka: open at %.0f, %.0f (yaw %.0f, pitch %.0f, %.0f m)" % [at.x, at.z, yaw, pitch, zoom])
	opened.emit()


func close() -> void:
	if not _open:
		return
	_open = false
	layer.visible = false
	set_process(false)
	_touches.clear()
	if post_quad != null and main_cam != null:
		post_quad.reparent(main_cam, false)
	if main_cam != null:
		main_cam.make_current()
	if hud != null:
		hud.visible = true
	if log_on:
		print("fotka: closed")
	closed.emit()


func _place_camera() -> void:
	if cam == null:
		return
	var basis := Basis.from_euler(Vector3(deg_to_rad(-pitch), deg_to_rad(yaw), 0.0))
	cam.size = zoom
	cam.global_transform = Transform3D(basis, focus + basis.z * maxf(DISTANCE, zoom * 1.6))
	cam.far = maxf(DISTANCE, zoom * 1.6) + zoom * 2.0 + 300.0


func orbit(d_yaw: float, d_pitch: float) -> void:
	yaw = fposmod(yaw + d_yaw, 360.0)
	pitch = clampf(pitch + d_pitch, PITCH.x, PITCH.y)
	_place_camera()


func zoom_by(factor: float) -> void:
	zoom = clampf(zoom * factor, ZOOM.x, ZOOM.y)
	_place_camera()


func _process(dt: float) -> void:
	if _saved_left > 0.0:
		_saved_left -= dt
		if _saved_left <= 0.0:
			_saved.visible = false


# --- the UI ------------------------------------------------------------------------------

func _px(points: float) -> int:
	return maxi(1, roundi(points * pt))


func _label(text: String, points: float, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", _px(points))
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	l.add_theme_constant_override("outline_size", _px(2.5))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(name: String, pl: String, en: String, size_pt: Vector2, round := false) -> Button:
	var b := Button.new()
	b.name = name
	b.custom_minimum_size = size_pt * pt
	b.size = size_pt * pt
	b.focus_mode = Control.FOCUS_NONE
	for st: String in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxFlat.new()
		s.bg_color = CARD_BG if st != "pressed" else Color(0.2, 0.18, 0.1, 0.96)
		s.set_corner_radius_all(_px(size_pt.y * 0.5 if round else 10.0))
		s.border_color = ACCENT if round else Color(1, 1, 1, 0.22)
		s.set_border_width_all(_px(3.0 if round else 1.0))
		b.add_theme_stylebox_override(st, s)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.add_theme_constant_override("separation", 0)
	var a := _label(Lang.pick(pl, en), T_BODY, INK)  # one language (lang.gd)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_child(a)
	b.add_child(words)
	_buttons[name] = b
	return b


## The UI: the orbit pad (the whole screen), ✕ WRÓĆ at the top right, − and + at the left, the
## shutter at the bottom right, a line saying what the finger does at the top left. In points,
## inside the safe area; every target at least 44 pt.
func build_ui() -> void:
	layer = CanvasLayer.new()
	layer.name = "Fotka"
	layer.layer = 3
	add_child(layer)
	_root = Control.new()
	_root.name = "orbit"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_pad)
	layer.add_child(_root)
	if not safe.has_area():
		safe = Rect2(Vector2.ZERO, _root.get_viewport_rect().size)
	var m := 12.0 * pt
	var close_b := _button("fotka_close", "WRÓĆ", "BACK", Vector2(76, 48))
	close_b.position = Vector2(safe.end.x - m - close_b.size.x, safe.position.y + m)
	close_b.pressed.connect(close)
	_root.add_child(close_b)
	var shutter := _button("fotka_shutter", "FOTKA", "PHOTO", Vector2(84, 84), true)
	shutter.position = Vector2(safe.end.x - m - shutter.size.x, safe.end.y - m - shutter.size.y)
	shutter.pressed.connect(func() -> void: shoot())
	_root.add_child(shutter)
	var zin := _button("fotka_zoom_in", "+", "", Vector2(52, 52))
	zin.position = Vector2(safe.position.x + m, safe.end.y - m - 2.0 * 52.0 * pt - 8.0 * pt)
	zin.pressed.connect(func() -> void: zoom_by(1.0 / 1.25))
	_root.add_child(zin)
	var zout := _button("fotka_zoom_out", "−", "", Vector2(52, 52))
	zout.position = Vector2(safe.position.x + m, safe.end.y - m - 52.0 * pt)
	zout.pressed.connect(func() -> void: zoom_by(1.25))
	_root.add_child(zout)
	var plate := PanelContainer.new()
	plate.name = "fotka_hint"
	var ps := StyleBoxFlat.new()
	ps.bg_color = CARD_BG
	ps.set_corner_radius_all(_px(10))
	ps.set_content_margin_all(8.0 * pt)
	ps.border_color = ACCENT
	ps.border_width_left = _px(3)
	plate.add_theme_stylebox_override("panel", ps)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(lines)
	lines.add_child(_label(Lang.pick("FOTKA", "PHOTO"), T_TITLE, ACCENT))
	_hint_pl = _label(Lang.pick("Przeciągnij palcem, by obrócić widok.", "Drag one finger to turn the view."), T_SUB, INK)
	_hint_en = _label("", T_LABEL, SUB)
	_hint_en.visible = false
	lines.add_child(_hint_pl)
	lines.add_child(_hint_en)
	plate.position = Vector2(safe.position.x + m, safe.position.y + m)
	_root.add_child(plate)
	_saved = _label("", T_SUB, INK)
	_saved.name = "fotka_saved"
	_saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_saved.position = Vector2(safe.position.x, safe.end.y - m - 52.0 * pt)
	_saved.size = Vector2(safe.size.x, 44.0 * pt)
	_saved.visible = false
	_root.add_child(_saved)
	layer.visible = false


## Touch targets and panels in pixels, by name (tools/check_hud.gd).
func ui_rects() -> Dictionary:
	var out := {}
	for n: String in _buttons:
		var b: Control = _buttons[n]
		out[n] = b.get_global_rect()
	var plate := _root.get_node_or_null("fotka_hint") as Control
	if plate != null:
		out["fotka_hint"] = plate.get_global_rect()
	return out


func _on_pad(e: InputEvent) -> void:
	var touch := e as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_touches[touch.index] = touch.position
		else:
			_touches.erase(touch.index)
		_pinch = 0.0
		return
	var drag := e as InputEventScreenDrag
	if drag != null:
		_touches[drag.index] = drag.position
		if _touches.size() >= 2:
			var k: Array = _touches.keys()
			var d: float = (_touches[k[0]] as Vector2).distance_to(_touches[k[1]])
			if _pinch > 0.0 and d > 1.0:
				zoom_by(_pinch / d)
			_pinch = d
		else:
			orbit(-drag.relative.x / pt * YAW_PER_PT, drag.relative.y / pt * PITCH_PER_PT)
		return
	var motion := e as InputEventMouseMotion
	if motion != null and motion.button_mask & MOUSE_BUTTON_MASK_LEFT and DisplayServer.is_touchscreen_available() == false:
		orbit(-motion.relative.x / pt * YAW_PER_PT, motion.relative.y / pt * PITCH_PER_PT)
		return
	var wheel := e as InputEventMouseButton
	if wheel != null and wheel.pressed:
		if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(1.0 / 1.12)
		elif wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.12)


# --- the shutter -------------------------------------------------------------------------

## Takes the photo: the UI off for a frame, the screen saved as a PNG, a Kadr checked. Returns
## the path ("" when the screen gave no image: the headless runs).
func shoot() -> String:
	if not _open:
		return ""
	layer.visible = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := _root.get_viewport().get_texture().get_image()
	layer.visible = true
	var path := ""
	if img != null and not img.is_empty():
		DirAccess.make_dir_recursive_absolute(PHOTOS)
		var t := Time.get_datetime_dict_from_system()
		path = "%s/fotka_%04d%02d%02d_%02d%02d%02d_%03d.png" % [PHOTOS, t["year"], t["month"], t["day"], t["hour"],
				t["minute"], t["second"], Time.get_ticks_msec() % 1000]
		if img.save_png(path) != OK:
			path = ""
	last_path = path
	if blip.is_valid():
		blip.call()
	var k := kadr_in_view()
	last_kadr = str(k.get("id", ""))
	if log_on:
		print("fotka: saved %s (%dx%d)" % [ProjectSettings.globalize_path(path) if path != "" else "nothing (no image here)",
				img.get_width() if img != null else 0, img.get_height() if img != null else 0])
	var said := [Lang.pick("ZAPISANO", "SAVED"), ""]
	if not k.is_empty():
		said = _kadr(k, path)
	elif log_on:
		print("kadr: none (%s)" % kadr_miss())
	_saved.text = said[0] if said[1] == "" else Lang.pick(said[0], said[1])
	_saved.visible = true
	_saved_left = 2.5
	return path


## A Kadr: the first time +20 respect, the stamp and the photo on the card. [Polish, English].
func _kadr(k: Dictionary, path: String) -> Array:
	var id := str(k["id"])
	var n := spots.find(k) + 1
	var first: bool = wallet != null and not wallet.kadr.has(id)
	if wallet != null:
		if first:
			var d := Time.get_date_dict_from_system()
			wallet.kadr[id] = int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])
			wallet.pay(0, KADR_RESPECT)
		if path != "":
			wallet.kadr_photos[id] = path
		wallet.save()
	if hud != null:
		hud.notebook_changed()
	print("kadr: %d ok (%s%s)" % [n, id, ", first: +%d respect" % KADR_RESPECT if first else ""])
	var name: Array = k["name"]
	return ["KADR! %s%s" % [name[0], " · +%d ★" % KADR_RESPECT if first else ""], "Got the shot! %s%s" % [name[1], " · +%d ★" % KADR_RESPECT if first else ""]]


## The Kadr spot in this view now ({} for none): open, at its time of day, its subject inside the
## central 60 % of the frame and within 300 m of the focus; the nearest to the frame's middle.
func kadr_in_view() -> Dictionary:
	if cam == null:
		return {}
	var vp := _root.get_viewport_rect().size
	var best: Dictionary = {}
	var best_d := INF
	for s in spots:
		if not _fits(s, vp):
			continue
		var c := _screen(s)
		var d := c.distance_to(vp * 0.5)
		if d < best_d:
			best_d = d
			best = s
	return best


func _subject(s: Dictionary) -> Vector3:
	var at: Vector2 = s["at"]
	var g: float = map.ground_height(at.x, at.y) if map != null else 0.0
	return Vector3(at.x, g + SUBJECT_LIFT, at.y)


## The subject on screen, in the root viewport's pixels.
func _screen(s: Dictionary) -> Vector2:
	var vp := _root.get_viewport_rect().size
	var p := cam.unproject_position(_subject(s))
	var svp := cam.get_viewport().get_visible_rect().size
	return p * vp / svp


func _fits(s: Dictionary, vp: Vector2) -> bool:
	if s["at"] == Vector2.INF or not spot_open(s):
		return false
	var at: Vector2 = s["at"]
	if Vector2(focus.x, focus.z).distance_to(at) > KADR_REACH:
		return false
	var want := str(s.get("look", ""))
	if want != "" and look.is_valid() and str(look.call()) != want:
		return false
	if cam.is_position_behind(_subject(s)):
		return false
	var c := _screen(s)
	var m := (1.0 - CENTRAL) * 0.5
	return c.x >= vp.x * m and c.x <= vp.x * (1.0 - m) and c.y >= vp.y * m and c.y <= vp.y * (1.0 - m)


## Why the nearest spot is not a Kadr now (the log).
func kadr_miss() -> String:
	var near: Dictionary = {}
	var nd := INF
	for s in spots:
		if s["at"] == Vector2.INF:
			continue
		var d := Vector2(focus.x, focus.z).distance_to(s["at"])
		if d < nd:
			nd = d
			near = s
	if near.is_empty():
		return "no spot"
	var why := PackedStringArray()
	if nd > KADR_REACH:
		why.append("%.0f m away" % nd)
	if not spot_open(near):
		why.append("locked by %s" % near["locked_by"])
	var want := str(near.get("look", ""))
	if want != "" and look.is_valid() and str(look.call()) != want:
		why.append("wants %s, it is %s" % [want, look.call()])
	if cam != null and not cam.is_position_behind(_subject(near)):
		var vp := _root.get_viewport_rect().size
		var c := _screen(near) / vp
		why.append("subject at %.2f, %.2f of the frame" % [c.x, c.y])
	return "%s: %s" % [near["id"], ", ".join(why)]


## Aims the orbit at Kadr spot `i` (--kadr=n): the focus on its subject, its look's yaw kept.
func aim_at(i: int) -> void:
	if i < 0 or i >= spots.size() or spots[i]["at"] == Vector2.INF:
		return
	var at: Vector2 = spots[i]["at"]
	focus = Vector3(at.x, _subject(spots[i]).y - SUBJECT_LIFT, at.y)
	_place_camera()
