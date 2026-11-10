class_name Trailer
extends Node
## The beta trailer's scripted takes (--trailer=TAKE, F 2026-11-10: the 38 s and 30 s cuts, the
## plan in the beta trailer doc). Each take runs on its own clock, summed from the frames' dt, so a
## Movie Maker capture (--write-movie with --fixed-fps) plays it the same at any render speed. The
## HUD is hidden; the camera, the light and the car follow the take, nothing else changes.
##
## palace_time   14 s: the camera circles the Palace and pushes in while the light runs day ->
##               golden hour -> dusk -> night (time_of_day.gd scrub).
## heli_dive     10 s: the helicopter from the Palace over the skyline, down to the Vistula and
##               round to the lit Stadion Narodowy (dusk by default).
## palace_drift  10 s: donuts on Plac Defilad under the Palace; a police raid sets off at 1.5 s and
##               the follow camera widens to show the patrols closing in (main.gd raid_view_extra).
## old_town       6 s (day): Zygmunt's Column and Plac Zamkowy up to the Old Town Market Square.
## card           5 s: the Palace at night, slowly, and the end card JOIN THE BETA.
## Every take: the Palace in its everyday gold light and no quest or job markers (F 2026-11-10).

const CameraShots := preload("res://scripts/camera_shots.gd")
const Beacon := preload("res://scripts/beacon.gd")
const TAKES := ["palace_time", "heli_dive", "palace_drift", "card", "old_town"]
const PALACE := Vector2(-1227.0, 244.0)
## The donut spot on Plac Defilad (the first street meet's square), the car's start for palace_drift.
const DRIFT_AT := Vector3(-1030.0, 0.0, 186.0)
const DRIFT_HEADING := 300.0
const RAID_AT := 1.5
const RAID_CARS := 4
## Seeded so every render of a take places the same patrols.
const SEED := 2026
## palace_time's light: day until SCRUB_FROM s, then one look further every SCRUB_STEP s.
const SCRUB_FROM := 3.0
const SCRUB_STEP := 3.0
## Each take's length (s). The game quits TAIL s after it ends, so a capture needs no --quit-after
## sum (keep one as a safety cap).
const LENGTH := {"palace_time": 14.0, "heli_dive": 10.0, "palace_drift": 10.0, "card": 5.0, "old_town": 6.0}
const TAIL := 0.5
## palace_drift's own camera (the first Mac render's follow camera sat wide over the square and
## lost the car): the car in the middle of a DRIFT_VIEW m view, turning slowly round it, widened
## by main.gd raid_view_extra while the patrols close in.
const DRIFT_VIEW := 70.0
const DRIFT_YAW := 140.0
const DRIFT_SPIN := 5.0
const DRIFT_PITCH := -32.0
## The takes' far plane (m): far enough that the view never ends in the clip plane's straight line.
const FAR := 6000.0
const CARD_IN := 0.6
const CARD_FADE := 0.8
## The end card's lines (F 2026-11-10: "not Free beta, but just join beta").
const CARD := ["JOIN THE BETA", "Around Warsaw", "iPhone and Android · aroundwarsaw.app"]

## Keys as camera_shots.gd EVENT_KEYS: t, ground point, height over it, view size, yaw, pitch.
const PALACE_KEYS: Array[Dictionary] = [
	{"t": 0.0, "at": PALACE, "up": 100.0, "size": 390.0, "yaw": 120.0, "pitch": -33.0},
	{"t": 4.0, "at": PALACE, "up": 100.0, "size": 340.0, "yaw": 158.0, "pitch": -32.0},
	{"t": 8.0, "at": PALACE, "up": 100.0, "size": 295.0, "yaw": 198.0, "pitch": -31.0},
	{"t": 11.0, "at": PALACE, "up": 95.0, "size": 262.0, "yaw": 230.0, "pitch": -30.0},
	{"t": 14.0, "at": PALACE, "up": 90.0, "size": 236.0, "yaw": 258.0, "pitch": -29.0},
]
const HELI_KEYS: Array[Dictionary] = [
	{"t": 0.0, "at": PALACE, "up": 180.0, "size": 190.0, "yaw": 135.0, "pitch": -30.0},
	{"t": 2.5, "at": Vector2(-1450.0, 380.0), "up": 60.0, "size": 150.0, "yaw": 160.0, "pitch": -28.0},
	{"t": 5.0, "at": Vector2(-200.0, 150.0), "up": 60.0, "size": 170.0, "yaw": 250.0, "pitch": -26.0},
	{"t": 7.0, "at": Vector2(950.0, -260.0), "up": 8.0, "size": 90.0, "yaw": 280.0, "pitch": -26.0},
	{"t": 10.0, "at": Vector2(1486.0, -611.0), "up": 30.0, "size": 200.0, "yaw": 240.0, "pitch": -26.0},
]
## old_town (day): from Zygmunt's Column on Plac Zamkowy up the Old Town to the Market Square.
const OLD_TOWN_KEYS: Array[Dictionary] = [
	{"t": 0.0, "at": Vector2(-702.0, -1471.0), "up": 25.0, "size": 110.0, "yaw": 200.0, "pitch": -34.0},
	{"t": 3.0, "at": Vector2(-750.0, -1600.0), "up": 20.0, "size": 120.0, "yaw": 215.0, "pitch": -34.0},
	{"t": 6.0, "at": Vector2(-796.0, -1736.0), "up": 15.0, "size": 95.0, "yaw": 230.0, "pitch": -36.0},
]
const CARD_KEYS: Array[Dictionary] = [
	{"t": 0.0, "at": PALACE, "up": 110.0, "size": 420.0, "yaw": 100.0, "pitch": -30.0},
	{"t": 5.0, "at": PALACE, "up": 110.0, "size": 400.0, "yaw": 112.0, "pitch": -30.0},
]

var take := ""
## The 3D image's MSAA for the capture (--trailer-aa=0|2|4|8).
var aa := Viewport.MSAA_4X
## Seconds into the take (the sum of dt).
var t := 0.0
var playing := false
var host: Node
var _last_view := Vector3(INF, 0.0, 0.0)
var _last_fill := -INF
var _raided := false
var _heli_yaw := 0.0
var _card_box: Control
var _drift_size := DRIFT_VIEW


static func valid(name: String) -> bool:
	return name in TAKES


## Starts the take. `host` is main.gd (its camera, car, helicopter, HUD, police, streamer, light).
func begin(main: Node) -> void:
	host = main
	t = 0.0
	playing = true
	seed(SEED)
	Beacon.hide_all = true
	# The capture's extras (F 2026-11-10, the graphics research's "High" list, with no phone frame
	# budget to keep): every mesh at full detail, an 8192 sun shadow map with soft edges, 16x
	# anisotropic filtering on the slanted roads and facades, and MSAA on the 3D image
	# (--trailer-aa=0 turns it off if the depth outlines suffer).
	var sv: SubViewport = host.sv
	sv.mesh_lod_threshold = 0.0
	sv.anisotropic_filtering_level = Viewport.ANISOTROPY_16X
	sv.msaa_3d = aa
	RenderingServer.directional_shadow_atlas_set_size(8192, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	host.hud.visible = false
	if take != "palace_drift":
		host.car.visible = false
	else:
		_place_car()
	if take == "heli_dive":
		var heli: Node3D = host.heli
		heli.visible = true
		heli.process_mode = Node.PROCESS_MODE_DISABLED
		heli.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if take == "card":
		_make_card()
	# The movie frame the take starts on (Movie Maker writes one frame per process frame), so the
	# loading frames before it can be cut off the capture.
	print("trailer: %s starts at frame %d" % [take, Engine.get_process_frames()])
	_frame(0.0)


func _process(dt: float) -> void:
	if playing:
		_frame(dt)


var _log_next := 0.0

func _frame(dt: float) -> void:
	t += dt
	if take == "palace_drift" and t >= _log_next:
		_log_next += 1.0
		var c: Vector3 = host.car.global_position
		print("trailer: t %.0f car (%.0f, %.0f) %.1f m/s view %.0f m" % [t, c.x, c.z, absf(host.car.forward_speed), _drift_size])
	if t >= float(LENGTH[take]) + TAIL:
		playing = false
		print("trailer: %s done at frame %d" % [take, Engine.get_process_frames()])
		if take == "palace_drift":
			var p: Vector3 = host.car.global_position
			print("trailer: the car ends %.0f m from its start, %.1f m/s, view %.0f m" % [
					Vector2(p.x, p.z).distance_to(Vector2(DRIFT_AT.x, DRIFT_AT.z)), absf(host.car.forward_speed), _drift_size])
		host.get_tree().quit()
		return
	match take:
		"palace_time":
			host.tod.scrub(clampf((t - SCRUB_FROM) / SCRUB_STEP, 0.0, 3.0))
			_fly(PALACE_KEYS)
		"heli_dive":
			var v: Dictionary = _fly(HELI_KEYS)
			_place_heli(v["focus"], dt)
		"old_town":
			_fly(OLD_TOWN_KEYS)
		"card":
			_fly(CARD_KEYS)
			if _card_box != null:
				_card_box.modulate.a = clampf((t - CARD_IN) / CARD_FADE, 0.0, 1.0)
		"palace_drift":
			control_car(host.car)
			if not _raided and t >= RAID_AT and host.police != null:
				_raided = true
				var n: int = host.police.raid(host.car.global_position, RAID_CARS, 2)
				print("trailer: raid, %d patrols" % n)
			_chase(dt)


## The camera along `keys` at the take's second; the sectors under it built at once when it has
## moved on or once a second (a capture: a stall costs a movie frame, not a hitch).
func _fly(keys: Array) -> Dictionary:
	var v: Dictionary = CameraShots.path_view(keys, t, func(x: float, z: float) -> float: return host.map.ground_height(x, z))
	var cam: Camera3D = host.cam
	cam.size = v["size"]
	cam.global_transform = v["xf"]
	# F (2026-11-10): the follow camera's far plane cut the city off in a straight line under the
	# sky; the takes look further, so the ground runs to the top of the frame.
	cam.far = FAR
	var focus: Vector3 = v["focus"]
	host.cam_focus = focus
	if host.streamer != null and (focus.distance_to(_last_view) > 120.0 or t - _last_fill >= 1.0):
		_last_view = focus
		_last_fill = t
		host.streamer.finish_view(focus, cam)
	return v


## heli_dive: the helicopter flies the camera's focus, nose along the path, rotors turning.
func _place_heli(at: Vector3, dt: float) -> void:
	var heli: Node3D = host.heli
	var next: Dictionary = CameraShots.path_view(HELI_KEYS, t + 0.15, func(x: float, z: float) -> float: return host.map.ground_height(x, z))
	var ahead: Vector3 = next["focus"]
	var d := ahead - at
	if Vector2(d.x, d.z).length() > 0.5:
		var want := atan2(-d.x, -d.z)
		_heli_yaw = want if dt == 0.0 else lerp_angle(_heli_yaw, want, minf(1.0, dt * 4.0))
	heli.global_position = at
	heli.rotation = Vector3(-0.12, _heli_yaw, 0.0)
	if heli.get("_rotor") != null:
		heli._rotor.rotate_y(27.0 * dt)
		heli._tail_rotor.rotate_x(40.0 * dt)


## palace_drift drives the car (main.gd calls it before the police's own drivers): a run-up, then
## full lock on full gas with the brake stabbed, so the tail goes and the car turns donuts round
## the square. True while the take holds the car.
func control_car(car: CharacterBody3D) -> bool:
	if not playing or take != "palace_drift":
		return false
	car.target_dir = Vector3.ZERO
	car.throttle = 1.0
	if t < 1.2:
		car.steer = 0.0
		car.braking = false
		return true
	car.steer = 1.0
	# A stab of brake every 0.8 s breaks the rear loose (car.gd: drift grip under braking at speed).
	car.braking = fmod(t - 1.2, 0.8) < 0.22
	return true


## palace_drift: the car set down on the square, nose along DRIFT_HEADING, visible and free to move.
func _place_car() -> void:
	var car: CharacterBody3D = host.car
	var y: float = host.map.ground_height(DRIFT_AT.x, DRIFT_AT.z)
	car.global_position = Vector3(DRIFT_AT.x, y + 0.3, DRIFT_AT.z)
	car.rotation = Vector3(0.0, deg_to_rad(DRIFT_HEADING), 0.0)
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	car.visible = true
	car.parked = false


## palace_drift's camera: on the car, turning slowly, wider while the raid's patrols come in.
func _chase(dt: float) -> void:
	var car: Node3D = host.car
	var cam: Camera3D = host.cam
	var yaw := DRIFT_YAW + DRIFT_SPIN * t
	var b := Basis.from_euler(Vector3(deg_to_rad(DRIFT_PITCH), deg_to_rad(yaw), 0.0))
	var want: float = DRIFT_VIEW + float(host.raid_view_extra(b, DRIFT_VIEW))
	_drift_size = want if dt == 0.0 else lerpf(_drift_size, want, minf(1.0, dt * 1.5))
	var focus := car.global_position
	cam.size = _drift_size
	cam.global_transform = CameraShots._view(focus, _drift_size, yaw, DRIFT_PITCH)
	cam.far = FAR
	host.cam_focus = focus
	car.visible = true
	if host.streamer != null and t - _last_fill >= 1.0:
		_last_fill = t
		host.streamer.finish_view(focus, cam)


func _make_card() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var h := get_viewport().get_visible_rect().size.y
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(centre)
	# A dark band behind the text: the Palace's lit spire sits right behind it (first Mac render).
	var panel := PanelContainer.new()
	var band := StyleBoxFlat.new()
	band.bg_color = Color(0.03, 0.03, 0.08, 0.55)
	band.set_content_margin_all(h * 0.04)
	band.set_corner_radius_all(int(h * 0.01))
	panel.add_theme_stylebox_override("panel", band)
	panel.modulate.a = 0.0
	centre.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", int(h * 0.014))
	panel.add_child(box)
	_card_box = panel
	var big := FontVariation.new()
	big.base_font = ThemeDB.fallback_font
	big.variation_embolden = 1.1
	big.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.2, 1.0), Vector2.ZERO)
	big.spacing_glyph = int(h * 0.012)
	box.add_child(_label(CARD[0], big, h * 0.12, Color.WHITE))
	box.add_child(_label(CARD[1], big, h * 0.055, Color("#ffd23f")))
	box.add_child(_label(CARD[2], ThemeDB.fallback_font, h * 0.04, Color("#ffd2d2")))


func _label(text: String, font: Font, px: float, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", int(px))
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", int(px * 0.05))
	l.add_theme_constant_override("shadow_offset_y", int(px * 0.05))
	return l
