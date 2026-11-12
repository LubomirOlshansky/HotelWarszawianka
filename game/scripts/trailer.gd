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
## `play` is plain gameplay (F 2026-11-10, after the first cut felt slow: "the day-two version was
## way funnier"): the HUD, the car, the jokes and cards of whatever test flags start the moment
## (--police=, --kebab=, --drive-into-water=, --meet-at=, --boat-race=, --pullover=, ...), with the
## capture's picture extras, for --trailer-len= seconds.
const TAKES := ["palace_time", "heli_dive", "palace_drift", "card", "old_town", "play",
		"old_town_fly", "skyline", "time_lapse", "heli_stadium", "castle_night"]

## The second cut's flights (F 2026-11-11, on the first cloud cut: "all the shots are very close up,
## no Palace, no centre, no Old Town"; "showcase the time and weather change on a landmark"; "the
## heli should approach the stadium"). Wide views a director would open on, each one landmark held
## in frame the whole take. Each: its length (s), the light (day, dusk, night), the camera keys
## (as PALACE_KEYS), and optionally `scrub` [from s, s per step] (time_of_day.gd scrub, day ->
## golden -> dusk -> night), `rain` (s: the rain blends in, weather.gd's 4 s), `heli` (keys the
## helicopter flies; only `at`, `up` and `t` count; its nose along its path).
const FLIGHTS := {
	# The Royal Castle, Zygmunt's Column and the Old Town's roofs, from over the Vistula's bank up
	# Plac Zamkowy to the Market Square, turning as it goes.
	"old_town_fly": {"len": 9.0, "time": "day", "keys": [
		{"t": 0.0, "at": Vector2(-520.0, -1470.0), "up": 30.0, "size": 430.0, "yaw": 70.0, "pitch": -31.0},
		{"t": 4.5, "at": Vector2(-650.0, -1560.0), "up": 20.0, "size": 340.0, "yaw": 42.0, "pitch": -32.0},
		{"t": 9.0, "at": Vector2(-770.0, -1690.0), "up": 15.0, "size": 280.0, "yaw": 18.0, "pitch": -34.0},
	]},
	# The Old Town at night in the rain, the lit Castle and Column, slowly.
	"castle_night": {"len": 8.0, "time": "night", "rain": 0.0, "keys": [
		{"t": 0.0, "at": Vector2(-640.0, -1500.0), "up": 20.0, "size": 300.0, "yaw": 12.0, "pitch": -32.0},
		{"t": 8.0, "at": Vector2(-690.0, -1560.0), "up": 20.0, "size": 250.0, "yaw": 32.0, "pitch": -33.0},
	]},
	# The towers of the new centre at golden hour, the helicopter flying east past them: from Rondo
	# Daszyńskiego's cluster (Warsaw Spire, Skyliner, Warsaw Unit) over Rondo ONZ to Złota 44 and
	# the Palace.
	"skyline": {"len": 10.0, "time": "day", "light": 0.55, "keys": [
		{"t": 0.0, "at": Vector2(-2620.0, 330.0), "up": 70.0, "size": 430.0, "yaw": 205.0, "pitch": -27.0},
		{"t": 5.0, "at": Vector2(-2050.0, 260.0), "up": 70.0, "size": 450.0, "yaw": 190.0, "pitch": -27.0},
		{"t": 10.0, "at": Vector2(-1420.0, 290.0), "up": 70.0, "size": 470.0, "yaw": 172.0, "pitch": -27.0},
	]},
	# The time-lapse: the Palace with Złota 44 and Varso behind it, from the north-east, nearly
	# locked off; day -> golden hour -> dusk -> night, then the rain comes in.
	"time_lapse": {"len": 14.0, "time": "day", "scrub": [1.5, 2.6], "rain": 9.5, "keys": [
		{"t": 0.0, "at": Vector2(-1330.0, 330.0), "up": 70.0, "size": 560.0, "yaw": 128.0, "pitch": -27.0},
		{"t": 14.0, "at": Vector2(-1340.0, 340.0), "up": 70.0, "size": 470.0, "yaw": 146.0, "pitch": -27.0},
	]},
	# The helicopter in from over the Vistula at Most Świętokrzyski to the lit Stadion Narodowy and
	# round its rim; the camera rides behind it and pulls out to the whole bowl.
	"heli_stadium": {"len": 10.0, "time": "dusk", "keys": [
		{"t": 0.0, "at": Vector2(1381.0, -262.0), "up": 70.0, "size": 34.0, "yaw": 344.0, "pitch": -26.0},
		{"t": 3.5, "at": Vector2(1430.0, -415.0), "up": 85.0, "size": 80.0, "yaw": 348.0, "pitch": -27.0},
		{"t": 7.0, "at": Vector2(1475.0, -540.0), "up": 50.0, "size": 210.0, "yaw": 352.0, "pitch": -29.0},
		{"t": 10.0, "at": Vector2(1488.0, -600.0), "up": 25.0, "size": 330.0, "yaw": 358.0, "pitch": -31.0},
	], "heli": [
		{"t": 0.0, "at": Vector2(1380.0, -260.0), "up": 70.0},
		{"t": 3.5, "at": Vector2(1428.0, -420.0), "up": 88.0},
		{"t": 7.0, "at": Vector2(1478.0, -560.0), "up": 100.0},
		{"t": 10.0, "at": Vector2(1505.0, -650.0), "up": 110.0},
	]},
}
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
const LENGTH := {"palace_time": 14.0, "heli_dive": 10.0, "palace_drift": 10.0, "card": 5.0, "old_town": 6.0, "play": 10.0}
const Weather := preload("res://scripts/weather.gd")
const TAIL := 0.5
## palace_drift's own camera (the first Mac render's follow camera sat wide over the square and
## lost the car): the car in the middle of a DRIFT_VIEW m view, turning slowly round it, widened
## by main.gd raid_view_extra while the patrols close in.
const DRIFT_VIEW := 70.0
const DRIFT_MAX := 110.0
const DRIFT_YAW := 20.0
const DRIFT_SPIN := 5.0
const DRIFT_PITCH := -32.0
## The takes' far plane (m): far enough that the view never ends in the clip plane's straight line.
const FAR := 6000.0
const CARD_IN := 0.6
const CARD_FADE := 0.8
const SAY_IN := 0.2
const SAY_FADE := 0.25
## The end card's lines (F 2026-11-10: "not Free beta, but just join beta").
## The title big in neon pink with a cyan shadow (an 80s sleeve, no palms), then the call.
const CARD := ["AROUND WARSAW", "JOIN THE BETA", "iPhone · Android · aroundwarsaw.app"]

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
## --trailer-len=S: the play take's length in seconds.
var play_len := 10.0
## --trailer-say=PL|EN: a caption over the take (the day-two cut's lines, F 2026-11-10), in from
## SAY_IN s.
var say := PackedStringArray()
## --trailer-at=X,Z,HEADING: the play take puts the car there (a close, free shot anywhere in the city).
var at := Vector3(INF, 0.0, 0.0)
## --trailer-view=M: the play take's camera view size in metres (a close chase view; 0 = the game's own).
var view := 0.0
## --trailer-clean: a play take with no quest or job markers.
var clean := false
## --trailer-cam=SIZE,YAW,PITCH[,SPIN[,LEAD[,OX,OZ]]]: a play take's own camera (the second cut, F
## 2026-11-11: "work on the camera"): SIZE m tall at a fixed YAW and PITCH (degrees), turning SPIN
## degrees a second (CHASE_SPIN: behind the vehicle, YAW an offset), its centre LEAD s ahead of the vehicle and OX, OZ m off it (a bank or a
## landmark in the frame with it), eased so a bump doesn't shake it.
var cam_set := PackedFloat32Array()
## --trailer-rain-at=S: the rain comes in at S s into any take (weather.gd blends it in 4 s).
var rain_at := -1.0
## --trailer-boat=LI: the boat race (--boat-race=auto) jumps to its line point LI once it is on
## (boat_race.gd warp), so a take can start just before the Bulwary's ramp.
var boat_li := -1
## --trailer-hud=clean[,notoast][,nobanner][,nostatus]: the HUD on, but only what reads in a
## trailer (_clean_hud), kept so every frame.
var hud_clean := false
var hud_hide := PackedStringArray()
## --trailer-bubble=NAME: only the speech bubbles of a speaker whose name holds NAME stay up (one
## joke a shot, F 2026-11-11: "what bubble with what text, not to overload"); "none" clears all.
var bubble_only := ""
## --trailer-look=X,Z: the play take's camera centred on that ground point instead of the vehicle
## (the club's ring, with the car parked in it).
var look := Vector2.INF
## --trailer-hold: the car stays where the take put it, parked (the club's ring).
var hold := false
var _boat_warped := false
var _rained := false
var _cam_focus := Vector3.INF
var _cam_vel := Vector3.ZERO
var _cam_prev := Vector3.INF
var _chase_yaw := INF
## --trailer-cam's SPIN at or over this: the chase camera (behind the vehicle, following its turns).
const CHASE_SPIN := 900.0
var _say_box: Control
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


## The light a take starts in (main.gd start_time), "" for the game's own.
static func start_light(name: String) -> String:
	return String(FLIGHTS[name].get("time", "")) if FLIGHTS.has(name) else ""


## Starts the take. `host` is main.gd (its camera, car, helicopter, HUD, police, streamer, light).
func begin(main: Node) -> void:
	host = main
	t = 0.0
	playing = true
	seed(SEED)
	# The quest markers and their light columns off in the scripted takes (F 2026-11-10); a play take
	# keeps the job's beacon, which its card points at.
	Beacon.hide_all = take != "play" or clean
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
	if not say.is_empty():
		_make_say()
	if take == "play":
		if at.x != INF:
			var y: float = host.map.ground_height(at.x, at.z)
			var car: CharacterBody3D = host.car
			car.global_position = Vector3(at.x, y + 0.3, at.z)
			car.rotation = Vector3(0.0, deg_to_rad(at.y), 0.0)
			car.vel = Vector3.ZERO
			car.forward_speed = 0.0
			car.reset_physics_interpolation()
			car.visible = true
			car.parked = false
			host.cam_focus = car.global_position
			host.streamer.finish_view(car.global_position, host.cam)
		if view > 0.0:
			host.base_size = view
			host._view_size = view
		if hud_clean:
			_clean_hud()
		print("trailer: %s starts at frame %d" % [take, Engine.get_process_frames()])
		return
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
	if FLIGHTS.has(take) and FLIGHTS[take].has("heli"):
		var hl: Node3D = host.heli
		hl.visible = true
		hl.process_mode = Node.PROCESS_MODE_DISABLED
		hl.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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
	if t >= _length() + TAIL:
		playing = false
		print("trailer: %s done at frame %d" % [take, Engine.get_process_frames()])
		if take == "palace_drift":
			var p: Vector3 = host.car.global_position
			print("trailer: the car ends %.0f m from its start, %.1f m/s, view %.0f m" % [
					Vector2(p.x, p.z).distance_to(Vector2(DRIFT_AT.x, DRIFT_AT.z)), absf(host.car.forward_speed), _drift_size])
		host.get_tree().quit()
		return
	if _say_box != null:
		_say_box.modulate.a = clampf((t - SAY_IN) / SAY_FADE, 0.0, 1.0)
	var rain_t: float = float(FLIGHTS[take].get("rain", -1.0)) if FLIGHTS.has(take) else rain_at
	if not _rained and rain_t >= 0.0 and t >= rain_t and host.weather != null:
		_rained = true
		host.weather.set_state(Weather.RAIN, rain_t == 0.0)
		print("trailer: rain at %.1f s" % t)
	if FLIGHTS.has(take):
		_flight(dt)
		return
	match take:
		"play":
			if boat_li >= 0 and not _boat_warped and host.boat_race != null and host.boat_race.state == host.boat_race.State.RACE:
				_boat_warped = true
				host.boat_race.warp(boat_li)
			var who: Node3D = host.heli if host.flying else host.car
			if hud_clean:
				_clean_hud()
			if bubble_only != "":
				_only_bubbles()
			if cam_set.size() >= 3:
				_follow(who, dt)
			_fill(who.global_position, host.cam)
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
				var k := clampf((t - CARD_IN) / CARD_FADE, 0.0, 1.0)
				_card_box.modulate.a = k
				# A punch in on the final hit: from 115 % down to size as it fades in.
				_card_box.pivot_offset = _card_box.size * 0.5
				_card_box.scale = Vector2.ONE * lerpf(1.15, 1.0, ease(k, 0.4))
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
	_fill(focus, cam)
	return v


## The sectors under the view built at once when it has moved on or once a second (a capture: a
## stall costs a movie frame, not a hitch).
func _fill(focus: Vector3, cam: Camera3D) -> void:
	if host.streamer != null and (focus.distance_to(_last_view) > 120.0 or t - _last_fill >= 1.0):
		_last_view = focus
		_last_fill = t
		host.streamer.finish_view(focus, cam)


func _length() -> float:
	if FLIGHTS.has(take):
		return float(FLIGHTS[take]["len"])
	return play_len if take == "play" else float(LENGTH[take])


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
	if playing and take == "play" and hold:
		_hold_car()
		return true
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
	# Capped at DRIFT_MAX (the first 160 m view lost the car): the nearest patrols come into the
	# frame first, the car stays readable.
	var want: float = minf(DRIFT_VIEW + float(host.raid_view_extra(b, DRIFT_VIEW)), DRIFT_MAX)
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
	var title := _label(CARD[0], big, h * 0.13, Color("#ff4fd8"))
	title.add_theme_color_override("font_shadow_color", Color("#29e7ff"))
	title.add_theme_constant_override("shadow_offset_x", int(h * 0.008))
	title.add_theme_constant_override("shadow_offset_y", int(h * 0.008))
	box.add_child(title)
	box.add_child(_label(CARD[1], big, h * 0.075, Color("#ffd23f")))
	box.add_child(_label(CARD[2], ThemeDB.fallback_font, h * 0.035, Color("#ffe6f6")))


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


## The caption: a dark band across the lower third, the Polish line big, the English small under
## it, like the day-two cut's "PRAWDZIWA WARSZAWA. W WERSJI KIESZONKOWEJ."
func _make_say() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var size := get_viewport().get_visible_rect().size
	var h := size.y
	var panel := PanelContainer.new()
	var band := StyleBoxFlat.new()
	band.bg_color = Color(0.02, 0.02, 0.06, 0.62)
	band.set_content_margin_all(h * 0.022)
	panel.add_theme_stylebox_override("panel", band)
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.66
	panel.anchor_bottom = 0.66
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.modulate.a = 0.0
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", int(h * 0.006))
	panel.add_child(box)
	var big := FontVariation.new()
	big.base_font = ThemeDB.fallback_font
	big.variation_embolden = 1.0
	big.spacing_glyph = int(h * 0.006)
	box.add_child(_label(say[0].to_upper(), big, h * 0.06, Color.WHITE))
	if say.size() > 1:
		box.add_child(_label(say[1], ThemeDB.fallback_font, h * 0.03, Color("#ffd23f")))
	_say_box = panel


## A flight take (FLIGHTS): the camera along its keys, the light scrubbed, the helicopter on its path.
func _flight(dt: float) -> void:
	var f: Dictionary = FLIGHTS[take]
	if f.has("light"):
		host.tod.scrub(float(f["light"]))
	if f.has("scrub"):
		var sc: Array = f["scrub"]
		host.tod.scrub(clampf((t - float(sc[0])) / float(sc[1]), 0.0, 3.0))
	_fly(f["keys"])
	if f.has("heli"):
		var g := func(x: float, z: float) -> float: return host.map.ground_height(x, z)
		var at: Vector3 = CameraShots.path_view(_heli_keys(f["heli"]), t, g)["focus"]
		var ahead: Vector3 = CameraShots.path_view(_heli_keys(f["heli"]), t + 0.25, g)["focus"]
		var heli: Node3D = host.heli
		var d := ahead - at
		if Vector2(d.x, d.z).length() > 0.3:
			var want := atan2(-d.x, -d.z)
			_heli_yaw = want if dt == 0.0 else lerp_angle(_heli_yaw, want, minf(1.0, dt * 3.0))
		# Nose down a little in forward flight, level as it slows into the hover.
		var tilt := clampf(Vector2(d.x, d.z).length() / 0.25 / 40.0, 0.0, 1.0) * -0.16
		heli.global_position = at
		heli.rotation = Vector3(tilt, _heli_yaw, 0.0)
		if heli.get("_rotor") != null:
			heli._rotor.rotate_y(27.0 * dt)
			heli._tail_rotor.rotate_x(40.0 * dt)


## Helicopter keys filled out for path_view (it reads size, yaw and pitch from every key).
func _heli_keys(keys: Array) -> Array:
	var out: Array = []
	for k: Dictionary in keys:
		out.append({"t": k["t"], "at": k["at"], "up": k["up"], "size": 100.0, "yaw": 0.0, "pitch": -30.0})
	return out


## --trailer-cam: the play take's camera on `who`, at the set size, yaw and pitch, its centre led
## ahead along the (eased) velocity.
func _follow(who: Node3D, dt: float) -> void:
	var p := who.global_position
	if look != Vector2.INF:
		p = Vector3(look.x, host.map.ground_height(look.x, look.y), look.y)
	if _cam_prev == Vector3.INF or dt <= 0.0:
		_cam_prev = p
		_cam_focus = p
	var v := (p - _cam_prev) / maxf(dt, 0.001)
	_cam_prev = p
	# A jump (the boat race's warp, a teleport): no speed from it, the camera cuts there.
	if v.length() > 60.0:
		v = Vector3.ZERO
		_cam_vel = Vector3.ZERO
		_cam_focus = p
	_cam_vel = _cam_vel.lerp(Vector3(v.x, 0.0, v.z), minf(1.0, dt * 1.5))
	var lead := float(cam_set[4]) if cam_set.size() > 4 else 0.6
	var want := p + _cam_vel * lead
	if cam_set.size() > 6:
		want += Vector3(cam_set[5], 0.0, cam_set[6])
	_cam_focus = want if dt <= 0.0 else _cam_focus.lerp(want, minf(1.0, dt * 3.0))
	var spin := float(cam_set[3]) if cam_set.size() > 3 else 0.0
	var yaw := float(cam_set[1]) + spin * t
	if spin >= CHASE_SPIN:
		# Chase: behind the vehicle, turning after it slowly (YAW is then an offset from behind).
		var back := who.global_transform.basis.z
		var want_yaw := rad_to_deg(atan2(back.x, back.z)) + float(cam_set[1])
		_chase_yaw = want_yaw if dt <= 0.0 or _chase_yaw == INF else rad_to_deg(lerp_angle(deg_to_rad(_chase_yaw), deg_to_rad(want_yaw), minf(1.0, dt * 1.2)))
		yaw = _chase_yaw
	var cam: Camera3D = host.cam
	cam.size = cam_set[0]
	cam.global_transform = CameraShots._view(_cam_focus, cam_set[0], yaw, cam_set[2])
	cam.far = FAR
	host.cam_focus = _cam_focus


## --trailer-hold: the car stands still where the take put it.
func _hold_car() -> void:
	var car: CharacterBody3D = host.car
	car.throttle = 0.0
	car.steer = 0.0
	car.braking = true
	car.target_dir = Vector3.ZERO


## --trailer-hud=clean (F 2026-11-11: "show the interface so it reads as a real game, but not
## overloaded"): the gear and the speed, the minimap with the wallet, the job's or race's status
## card, the countdown banner and the toasts stay; the radio and zoom chips, the radio ticker, the
## district and note cards, the landmark card and the performance overlay go. `hud_hide` adds
## "toast", "banner", "status", "heli" (the HELI chip). Run every frame: the HUD shows its cards
## again as they come.
func _clean_hud() -> void:
	var hud: CanvasLayer = host.hud
	var names := ["_radio_button", "_zoom_in_button", "_zoom_out_button", "_skip_button", "_ticker",
			"_note", "_info_card", "_perf", "_bench_card", "_pill"]
	for h: String in hud_hide:
		names.append({"toast": "_toast_box", "banner": "_banner", "status": "_status", "heli": "_vehicle_button",
				"card": "_card"}.get(h, "_" + h))
	for name: String in names:
		var c: Variant = hud.get(name)
		if c is CanvasItem:
			(c as CanvasItem).visible = false


## --trailer-bubble: every other speaker's bubble off the screen.
func _only_bubbles() -> void:
	var b: Node = host.bubbles
	var list: Array = b._bubbles
	for i in range(list.size() - 1, -1, -1):
		if bubble_only == "none" or not String(list[i]["speaker"]).to_lower().contains(bubble_only.to_lower()):
			list.remove_at(i)
			b.queue_redraw()
