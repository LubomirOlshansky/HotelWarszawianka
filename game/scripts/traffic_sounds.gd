extends Node3D
## Sound engine plan, "traffic you can hear" (F, 2026-11-19; review step 5, built first by F's
## pick): the traffic near the ear is heard as vehicles, not only as the city bed. The nearest
## moving cars (traffic.gd drivers: cars, taxis, vans, patrols, rivals), the nearest city bus
## (traffic.gd kind BUS_KIND) and the nearest tram (trams.gd) each carry a looping sound that
## moves with them: `traffic_car`, `traffic_bus`, `traffic_tram` (ElevenLabs Sound Effects, put
## in with tools/add_sfx.py, sources in audio/sfx/sources.json). The distance does the pass-by
## (the 3D player's fall-off and panning); the pitch follows the speed with a mild Doppler shift
## (the speed towards or away from the ear), and the level follows the speed, so a car waiting at
## a light only hums.
##
## Who is heard is chosen TICK times a second: per kind the `want` nearest within its reach. A
## kind has one voice more than it wants, so a new vehicle fades in while the one leaving fades
## out; a voice keeps its vehicle while it stays among the nearest. Per frame only the voices that
## sound are moved (at most 8 players), with no search. The players are on the Ambience bus: the
## title holds them with the beds (sfx.gd world_hold) and the radio's duck dips them like the city
## bed. Headless runs (the checks) choose, fade and pitch the same but play nothing.

const Sfx := preload("res://scripts/sfx.gd")

const DIR := "res://audio/sfx/"
## traffic.gd's kinds are car, taxi, van, bus, police: the bus is the one with its own sound.
const BUS_KIND := 3
## Seconds between two choices of who is heard.
const TICK := 0.2
## How fast a voice fades in or out (share of full level per second: about 0.6 s).
const FADE := 1.6
## Per kind: the sound, its level at full speed (dB on the Ambience bus), the distance it is at
## full level (the player's unit_size, m), how far it is chosen (m on the ground), how many are
## heard at once, the speed at full level and full pitch (m/s), the level when standing (a share
## of full: a tram stands silent) and the sound's height over the vehicle's point (m).
const KINDS := {
	"car": {"file": "traffic_car", "db": -17.0, "unit": 10.0, "reach": 40.0, "want": 3, "full": 14.0, "idle": 0.25, "up": 0.6},
	"bus": {"file": "traffic_bus", "db": -14.0, "unit": 12.0, "reach": 55.0, "want": 1, "full": 11.0, "idle": 0.45, "up": 1.2},
	"tram": {"file": "traffic_tram", "db": -11.0, "unit": 14.0, "reach": 70.0, "want": 1, "full": 11.0, "idle": 0.0, "up": 0.8},
}
## The pitch standing and at full speed.
const PITCH_LOW := 0.82
const PITCH_HIGH := 1.12
## The Doppler shift per m/s towards the ear (sound's 343 m/s, made 1.5 times stronger so a
## pass-by reads at city speeds), and its limit either way.
const DOPPLER := 1.5 / 343.0
const DOPPLER_MAX := 0.08
## A vehicle that moved farther than this in one frame was reused for another car or put back on
## its line elsewhere: its voice stops at once instead of flying across the map.
const JUMP := 12.0


class Voice:
	var kind := ""
	var player: AudioStreamPlayer3D
	## The vehicle heard (a traffic.gd Driver or a trams.gd Tram), null when free.
	var src: Object
	var leaving := false
	var level := 0.0
	var pitch := 1.0
	var at := Vector3.ZERO
	## The distance to the ear last frame (-1: not yet) and the smoothed speed away from it (m/s).
	var last_d := -1.0
	var away := 0.0


## Where the ear is, -> Vector3 (the camera's focus, as sfx.gd's listener).
var ear: Callable
## The traffic's drivers, -> Array (traffic.gd drivers()); the trams, -> Array (trams.gd trams).
var drivers: Callable
var trams: Callable
var voices: Array[Voice] = []
## Voices sounding now (for the check and --bench).
var live := 0
## Time spent here since the bench last read it (µs).
var spent_usec := 0

var _t := 0.0
var _silent := DisplayServer.get_name() == "headless"
var _rng := RandomNumberGenerator.new()


## Makes the node under `world` and its players (main.gd's _build_sound). It is made with no
## traffic and no trams too (it then hears nothing), so the bench can always read it.
static func build(world: Node3D, traffic: Node3D, trams_node: Node3D, ear_at: Callable) -> Node3D:
	var ts: Node3D = load("res://scripts/traffic_sounds.gd").new()
	ts.name = "TrafficSounds"
	ts.ear = ear_at
	if traffic != null:
		ts.drivers = func() -> Array: return traffic.drivers()
	if trams_node != null:
		ts.trams = func() -> Array: return trams_node.trams
	world.add_child(ts)
	ts.setup()
	return ts


func setup() -> void:
	for kind: String in KINDS:
		var k: Dictionary = KINDS[kind]
		var stream: AudioStream = load(DIR + str(k["file"]) + ".wav")
		for i in int(k["want"]) + 1:
			var v := Voice.new()
			v.kind = kind
			var p := AudioStreamPlayer3D.new()
			p.stream = stream
			p.bus = &"Ambience"
			p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
			p.unit_size = float(k["unit"])
			p.max_distance = float(k["reach"]) + Sfx.LISTENER_UP + 10.0
			p.panning_strength = 0.7
			p.volume_db = -80.0
			add_child(p)
			v.player = p
			voices.append(v)


func _process(dt: float) -> void:
	if dt <= 0.0 or not ear.is_valid():
		return
	var t0 := Time.get_ticks_usec()
	_t += dt
	if _t >= TICK:
		_t = 0.0
		tick()
	step(dt)
	spent_usec += Time.get_ticks_usec() - t0


## Picks who is heard: per kind the nearest within reach. A voice whose vehicle is no longer
## among them starts leaving; a new one takes a free voice (none free: it waits for the next tick).
func tick() -> void:
	var e3: Vector3 = ear.call()
	var e := Vector2(e3.x, e3.z)
	var found := {"car": [], "bus": [], "tram": []}
	# Plain arrays: a packed array read out of a dictionary is a copy, and an append to it is lost.
	var dist := {"car": [], "bus": [], "tram": []}
	if drivers.is_valid():
		# A square around the ear first (the bus's reach, the longer of the two): most drivers are
		# far, and the square costs less than the distance and the appends.
		var r: float = KINDS["bus"]["reach"]
		for d in drivers.call():
			if absf(d.pos.x - e.x) > r or absf(d.pos.z - e.y) > r:
				continue
			if not d.active or d.ghost or d.parked:
				continue
			var kind := "bus" if d.kind == BUS_KIND else "car"
			found[kind].append(d)
			dist[kind].append(e.distance_to(Vector2(d.pos.x, d.pos.z)))
	if trams.is_valid():
		for tr in trams.call():
			found["tram"].append(tr)
			dist["tram"].append(e.distance_to(tram_point(tr, e)))
	for kind: String in KINDS:
		var k: Dictionary = KINDS[kind]
		var chosen: Array = []
		for i in nearest(PackedFloat32Array(dist[kind]), int(k["want"]), float(k["reach"])):
			chosen.append(found[kind][i])
		for v in voices:
			if v.kind != kind or v.src == null:
				continue
			if chosen.has(v.src):
				chosen.erase(v.src)
				v.leaving = false
			else:
				v.leaving = true
		for src in chosen:
			for v in voices:
				if v.kind == kind and v.src == null:
					_take(v, src)
					break


## Moves, fades and pitches the voices that sound.
func step(dt: float) -> void:
	var e3: Vector3 = ear.call()
	var listener := e3 + Vector3.UP * Sfx.LISTENER_UP
	live = 0
	for v in voices:
		if v.src == null:
			continue
		var k: Dictionary = KINDS[v.kind]
		var speed := 0.0
		var at := Vector3.ZERO
		if v.kind == "tram":
			var tp := tram_point(v.src, Vector2(e3.x, e3.z))
			at = Vector3(tp.x, v.src.pos.y, tp.y)
			speed = absf(v.src.v)
		else:
			if not v.src.active or v.src.parked:
				_free(v)
				continue
			at = v.src.pos
			speed = absf(v.src.v)
		if v.last_d >= 0.0 and at.distance_to(v.at) > JUMP:
			_free(v)
			continue
		v.at = at
		var full := clampf(speed / float(k["full"]), 0.0, 1.0)
		var want := 0.0 if v.leaving else lerpf(float(k["idle"]), 1.0, full)
		v.level = move_toward(v.level, want, FADE * dt)
		if v.leaving and v.level <= 0.0:
			_free(v)
			continue
		var pos := at + Vector3.UP * float(k["up"])
		var d := pos.distance_to(listener)
		if v.last_d >= 0.0:
			v.away = lerpf(v.away, (d - v.last_d) / dt, minf(1.0, dt * 8.0))
		v.last_d = d
		v.pitch = lerpf(PITCH_LOW, PITCH_HIGH, full) * doppler(v.away)
		live += 1
		if _silent:
			continue
		v.player.global_position = pos
		v.player.volume_db = float(k["db"]) + linear_to_db(maxf(v.level, 0.0001))
		v.player.pitch_scale = v.pitch


## The indices of up to `n` of `dist` that are under `reach`, nearest first.
static func nearest(dist: PackedFloat32Array, n: int, reach: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in dist.size():
		if dist[i] >= reach:
			continue
		var at := out.size()
		while at > 0 and dist[out[at - 1]] > dist[i]:
			at -= 1
		if at < n:
			out.insert(at, i)
			if out.size() > n:
				out.resize(n)
	return out


## The pitch factor for a source moving `away` m/s from the ear (negative: coming closer).
static func doppler(away: float) -> float:
	return 1.0 - clampf(away * DOPPLER, -DOPPLER_MAX, DOPPLER_MAX)


## The point of a tram nearest to `e` on the ground: along the line from its rear to its front.
static func tram_point(tr: Object, e: Vector2) -> Vector2:
	var front := Vector2(tr.pos.x, tr.pos.z)
	var rear: Vector2 = tr.rear
	return Geometry2D.get_closest_point_to_segment(e, rear, front)


func _take(v: Voice, src: Object) -> void:
	v.src = src
	v.leaving = false
	v.level = 0.0
	v.last_d = -1.0
	v.away = 0.0
	if not _silent:
		v.player.volume_db = -80.0
		v.player.play(_rng.randf() * v.player.stream.get_length())


func _free(v: Voice) -> void:
	v.src = null
	v.leaving = false
	v.level = 0.0
	if not _silent:
		v.player.stop()


## Stop and drop the players before the tree goes (a sounding player's playback outlived it and
## leaked at exit on the Mac, as the tape's rewind did).
func _exit_tree() -> void:
	for v in voices:
		v.src = null
		if v.player != null:
			v.player.stop()
			v.player.stream = null
