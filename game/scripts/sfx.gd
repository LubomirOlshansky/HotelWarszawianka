extends Node3D
## The game's sound (v0.9), all from tools/make_sfx.py (original synthesis, no samples):
## the car's engine (three loops at 850, 2400 and 4500 rpm, crossfaded and pitched by a
## five-speed gearbox, with a short dip at every upshift), the tyres (rolling on dry
## asphalt, hissing on a wet road, squealing in a slide or under hard braking), the
## helicopter's rotor, collisions (thumps, a crash, a guard rail's clang), the słoiki
## run's jars, the city's day and night beds, rain, and positional one-shots: trams'
## bells, the AI cars' horns, the pigeons. Birds now and then by day; a far siren or a
## dog, rarely, at night.
##
## Buses (setup_buses, before the radio is made): Master (with a limiter), Music (the radio),
## SFX, Ambience and Voice (the announcer's and LEKTI's spoken clips). Who turns whom down is
## one table, DUCKS (the mixer, TD-5): a script asks by name, `Sfx.duck("police_talk")`, and
## gives it back with `Sfx.release("police_talk")`; nobody writes a level directly.
## One-shots have one door: `play(name)` (no place), `play_at(name, at)` (in the world) and
## `Sfx.ui(name)` (the interface), with a priority, a voice limit, takes and a pitch spread per
## sound (SHOT_RULES); a name that isn't in the tables is an error.
## Positional sounds go through a pool of AudioStreamPlayer3D (a hard cap on voices)
## heard by a listener that follows the camera's focus a few metres up, with a short
## reach so the map isn't a wall of noise. Per frame this only sets a few volumes and
## pitches. Headless runs (tests) have no audio device and play nothing.

const DIR := "res://audio/sfx/"
## The rpm each engine loop was recorded at (tools/make_sfx.py prints them).
const ENGINE_RPM := [850.0, 2397.0, 4500.0]
## Gearbox: the speed (m/s) where each gear tops out; first gear starts at rest.
const GEAR_TOP := [0.0, 6.5, 12.5, 19.0, 25.5, 40.0]
const RPM_IDLE := 850.0
const RPM_SHIFTED := 1900.0
const RPM_TOP := 4600.0
## Bus levels (dB). The radio player sits at -9 dB on Music (radio.gd).
## Voice sits where the spoken clips sat when they were on SFX, so they sound as before.
const BUSES := {"Music": 0.0, "SFX": -3.0, "Ambience": -9.0, "Voice": -3.0}
## The Master bus's limiter: the loudest the sum may get (dBFS), so the engine, a crash and the
## radio together never clip. It does nothing below that.
const LIMIT_DB := -0.5
## The mixer (TD-5): every duck in the game, name -> [what it turns down, dB, seconds to fade
## down, seconds to come back] (0 s: at once). What it turns down is "radio" (the station's
## player and jingle, radio.gd) or a bus name. Ducks stack: while several hold the same target
## the deepest one counts, and releasing one never undoes another. A new duck is a new row here.
const DUCKS := {
	# The city's beds dip while a station plays, so the radio keeps priority.
	"radio_on": ["Ambience", -4.0, 0.67, 0.67],
	# The pull-over and the guard's talk (police.gd).
	"police_talk": ["radio", -6.0, 0.0, 0.0],
	# Smolna's own loops (club.gd) and the padel court's music (padel_match.gd): the radio is off.
	"club": ["radio", -60.0, 0.0, 0.0],
	"padel": ["radio", -60.0, 0.0, 0.0],
	# The host's greeting on a launch (greeting_clips.gd) and the opening line over the flyover
	# (opening_audio.gd): the radio is a quiet bed under the voice, then swells back.
	"greeting": ["radio", -16.0, 0.5, 2.5],
	"opening": ["radio", -20.0, 0.6, 3.0],
	# The 02:00 beat's host (radio.gd host_moment) and LEKTI's break-in (rave.gd).
	"host_moment": ["radio", -10.0, 0.0, 0.0],
	"rave_voice": ["radio", -10.0, 0.0, 0.0],
}
## Loops: name, bus, level (dB) at full.
const LOOPS := {
	"engine_idle": ["SFX", -10.0], "engine_mid": ["SFX", -10.0], "engine_high": ["SFX", -10.0],
	"tyre_roll": ["SFX", -14.0], "tyre_wet": ["SFX", -11.5], "tyre_squeal": ["SFX", -15.0],
	"rotor": ["SFX", -3.0],
	# The coffee run's bike (PT 2026-11-08: the car's engine kept on after the swap): the ride's
	# tyres and chain, and the hub's ratchet while coasting (tools/make_sfx.py).
	"bike_roll": ["SFX", -16.0], "bike_freewheel": ["SFX", -11.0],
	# Recorded beds (ElevenLabs, tools/add_sfx.py, audio/sfx/sources.json): 24 to 29 s loops at the
	# loudness of the synth beds they replaced; the night and the river peak early, so they sit higher here.
	"city_day": ["Ambience", -7.0], "city_night": ["Ambience", -12.4], "rain": ["Ambience", -7.0],
	# v1.0 juice: one bed per kind of district (DISTRICT_BEDS), set ~13 dB under the city bed by the
	# files' RMS so they colour it and never cover it.
	"amb_river": ["Ambience", -9.6], "amb_park": ["Ambience", -14.0], "amb_square": ["Ambience", -10.0],
	"amb_yard": ["Ambience", -16.0],
	# Senatorek's lift ride (lounge.gd, tools/make_sfx.py): a hum felt more than heard.
	"lift_hum": ["SFX", -24.0],
}
## v1.0 juice: the district's own bed (districts.json ids): the river at Powiśle, trees in the
## park, a square's talk in the Old Town and on the Royal Route, courtyards and trams in Praga
## and Muranów. The centre, Wola and the south keep the city bed alone.
const DISTRICT_BEDS := {
	"powisle": "amb_river", "lazienki": "amb_park", "stare_miasto": "amb_square", "trakt": "amb_square",
	"praga": "amb_yard", "muranow": "amb_yard",
}
## First scene item 7 (docs/design/first-scene.md, 2026-11-02): the start's box (main.gd FIRST_SCENE,
## Plac Defilad and Marszałkowska by the museum) has the square's talk under the city bed while the
## view is on it, though Śródmieście has no district bed of its own (a district's bed wins).
var square_box := Rect2()
const SQUARE_BED := "amb_square"
## How fast a district bed fades in and out (per second; ~3 s to settle).
const BED_RATE := 0.8
## One-shots: level (dB).
const SHOTS := {
	"thump_soft": -8.0, "thump_hard": -6.0, "crash": -4.0, "clang": -9.0, "jar_clink": -12.0, "jar_break": -6.0,
	"tram_bell": -8.0, "horn": -16.0, "horn_double": -16.0, "pigeons": -6.0,
	"birds_a": -13.0, "birds_b": -15.0, "siren_far": -20.0, "dog_far": -10.0,
	# Loop 3g-2 (police.md 10, tools/make_sfx.py): the police's and the guards' own sounds, each
	# set to land where its 3g-1 placeholder sat (by the files' RMS).
	"police_whoop": -26.0, "megaphone": -14.0, "whistle": -18.0, "scribble": -14.0, "stamp": -17.0, "clank": -9.0,
	# Loop MW-4 (city_life.gd, tools/make_sfx.py): the barks in three sizes, the bike bell, the
	# running watch, the phone's shutter and the café's door bell.
	"bark_small": -12.0, "bark_mid": -11.0, "bark_big": -10.0, "bike_bell": -13.0, "watch_beep": -20.0,
	"phone_shutter": -17.0, "cafe_bell": -15.0,
	# Loop MW-2 (storefronts.gd): the Frogs door's croak chime, a Leżak knocked over.
	"frog_chime": -15.0, "scooter_clatter": -12.0,
	# The night-buses loop (buses.gd, tools/make_sfx.py): the player's own horn.
	"horn_player": -12.0,
	# v1.0 juice: the ting of a payment (money_pop.gd).
	"coin": -11.0,
	# Senatorek's arrival (lounge.gd): the revolving door and the lift's ding.
	"door_swish": -7.0, "lift_ding": -13.0,
	# G13b: the nitro lighting (car.gd nitro_started).
	"nitro_whoosh": -8.0,
	# The vintage-tram loop (old_tram.gd, tools/make_sfx.py): the old set's creak (under the bell)
	# and its own bell (set to land where tram_bell does, by the files' RMS).
	"tram_creak": -8.0, "old_tram_bell": -9.5,
	# City-life satire #1 (loud_cars.gd, tools/make_sfx.py): a loud car's rev and crackle as it
	# passes (loud on purpose: a little over the horns by the files' RMS).
	"loud_rev": -11.0,
	# The railway audit (trains.gd, tools/make_sfx.py, 2026-11-07): a train's wheels going by (on
	# a bridge, with the girders' drone), its horn out of a tunnel mouth, the platform gong.
	"train_rumble": -5.0, "train_bridge": -4.0, "train_horn": -13.0, "station_gong": -12.0,
}
## Loop 3g-2: the siren loop (one positional voice) and its level there.
const SIREN := "police_siren"
const SIREN_DB := -13.0
## A crash scene's ambulance: the same wail, quieter (it stands still, nobody is chasing).
const SCENE_SIREN_DB := -20.0
const VOICES_3D := 6
const VOICES_2D := 6
## The one door for one-shots (sound engine step 2): `play(name)` for a sound with no place,
## `play_at(name, at)` for one in the world, `Sfx.ui(name)` for the interface. Each sound's rule:
## name -> [priority, the most voices of it at once, pitch spread]. With every voice busy a new
## sound takes the least important one, and only if it matters at least as much, so a coin never
## cuts a crash. The spread is a random pitch of that share either way, so a sound heard often is
## not the same every time. A sound without a row gets RULE_DEFAULT.
const LOW := 0
const NORMAL := 1
const HIGH := 2
const RULE_DEFAULT := [NORMAL, 2, 0.0]
const SHOT_RULES := {
	"crash": [HIGH, 1, 0.05], "thump_hard": [HIGH, 2, 0.06], "thump_soft": [NORMAL, 2, 0.08], "clang": [HIGH, 1, 0.05],
	"jar_break": [HIGH, 1, 0.05], "jar_clink": [LOW, 1, 0.08], "scooter_clatter": [NORMAL, 1, 0.06],
	"police_whoop": [HIGH, 1, 0.0], "megaphone": [HIGH, 1, 0.0], "whistle": [NORMAL, 1, 0.03], "stamp": [NORMAL, 1, 0.0],
	"scribble": [LOW, 1, 0.0], "clank": [NORMAL, 1, 0.04],
	"coin": [NORMAL, 2, 0.0], "horn_player": [NORMAL, 1, 0.0], "nitro_whoosh": [NORMAL, 1, 0.04],
	"door_swish": [NORMAL, 1, 0.0], "lift_ding": [NORMAL, 1, 0.0],
	"birds_a": [LOW, 1, 0.06], "birds_b": [LOW, 1, 0.06], "siren_far": [LOW, 1, 0.0], "dog_far": [LOW, 1, 0.08],
	"horn": [NORMAL, 2, 0.05], "horn_double": [NORMAL, 2, 0.05], "pigeons": [NORMAL, 1, 0.06],
	"bark_small": [LOW, 1, 0.1], "bark_mid": [LOW, 1, 0.1], "bark_big": [LOW, 1, 0.1], "bike_bell": [LOW, 1, 0.03],
	"cafe_bell": [LOW, 1, 0.03], "frog_chime": [LOW, 1, 0.0], "phone_shutter": [LOW, 1, 0.0], "watch_beep": [LOW, 1, 0.0],
	"loud_rev": [NORMAL, 1, 0.06], "tram_bell": [NORMAL, 2, 0.0], "old_tram_bell": [NORMAL, 1, 0.0], "tram_creak": [LOW, 1, 0.05],
	"train_rumble": [NORMAL, 1, 0.04], "train_bridge": [NORMAL, 1, 0.04], "train_horn": [NORMAL, 1, 0.0], "station_gong": [NORMAL, 1, 0.0],
}
## A sound may have more than one take: `name.wav`, then `name_2.wav` up to `name_4.wav` beside
## it. A take is picked at random, never the same one twice running.
const MAX_TAKES := 4
## The interface's sounds (Sfx.ui): name -> [file, dB on the SFX bus]. They play under the pause
## and before the city is built (the title), so they have their own players, one per sound.
const UI := {
	"blip": ["res://audio/ui/blip.wav", -11.0],
	"ring": ["res://audio/ui/ring.wav", -9.0],
	# The title's tap. It sat on Master at -8 dB; on SFX (-3 dB) this keeps its level.
	"start": ["res://audio/ui/start.wav", -5.0],
}
## Positional sounds: full level within UNIT metres of the listener, gone past REACH.
const UNIT := 14.0
const REACH := 85.0
const LISTENER_UP := 12.0

var car: CharacterBody3D
var heli: Node3D
var tod: Node
var weather: Node
var radio: Node
var flying := false
## The camera's focus and yaw (degrees), set by the game each frame.
var focus := Vector3.ZERO
var yaw := 45.0
## How long the last update took, for --bench.
var last_usec := 0

var _silent := DisplayServer.get_name() == "headless"
var _streams := {}
var _loops := {}
var _level := {}
var _quiet := {}
var _pool2: Array[AudioStreamPlayer] = []
## What each 2D voice is playing ("" when free) and when it started (s of play).
var _voice2: Array[String] = []
var _started2: Array[float] = []
## Per sound: its takes (streams) and the take played last.
var _takes := {}
var _last_take := {}
var _pool3: Array[AudioStreamPlayer3D] = []
var _listener: AudioListener3D
var _gear := 1
var _rpm := RPM_IDLE
var _dip := 0.0
var _last_v := 0.0
var _load := 0.0
var _rotor := 0.0
var _lift_on := false
var _hit_wait := 0.0
var _horn_wait := 0.0
var _jar_wait := 0.0
var _event_wait := 12.0
## The district bed now (a LOOPS name, "" for none): set_district.
var _bed := ""
var _t := 0.0
var _rng := RandomNumberGenerator.new()
## Loop 10a: the splash's wash of water (the rain bed's noise, faded out over WASH s).
const WASH := 0.9
var _wash: AudioStreamPlayer
var _wash_t := 0.0
## Guard rails on a 4 m grid (data["guards"]): a hit there clangs.
var _rails := {}
## What the player is in now (main.gd `_sound_mode`): "car", "bike" (the coffee run's ROWERILO),
## "boat" (a petrol boat: the engine stays as its motor, no tyres), "electric" (Srebrna Strzała:
## silent) or "foot" (the club's, the lounge's room or the padel court: the parked car is quiet).
## The helicopter is `flying`.
var mode := "car"
## Loop MW-5: seconds left of the softer engine (the 02:00 beat on Plac Trzech Krzyży).
var _soft_t := 0.0
## Loop MW-5: the engine's level while softened (×0.45, about -7 dB).
const ENGINE_SOFT := 0.45


## Loop 2a: the player's volumes (Settings → Sound) as dB on top of the bus levels.
static var user_db := {"Master": 0.0, "Music": 0.0, "SFX": 0.0, "Ambience": 0.0, "Voice": 0.0}
## The mixer's state: the ducks held now (name -> seconds left, INF: until released), each
## target's level now (dB, eased) and how fast it is moving (dB per second).
static var _held := {}
static var _mix := {}
static var _fade := {}
static var _mix_frame := -1


## Turns down what `name` (a DUCKS row) says, until release(name) or for `seconds`. Asking again
## while it is held only makes a timed one last longer. An unknown name is an error, not silence.
static func duck(name: String, seconds := INF) -> void:
	if not DUCKS.has(name):
		push_error("sfx: no duck named \"%s\" (add a row to Sfx.DUCKS)" % name)
		return
	if _held.has(name):
		_held[name] = maxf(float(_held[name]), seconds)
		return
	var row: Array = DUCKS[name]
	var target: String = row[0]
	var was := mix_target(target)
	_held[name] = seconds
	if mix_target(target) < was:
		_fade_to(target, absf(float(row[1])), float(row[2]))


## Gives back what duck(name) took. Whatever else still holds the target keeps it down.
static func release(name: String) -> void:
	if not _held.has(name):
		return
	var row: Array = DUCKS[name]
	var target: String = row[0]
	var was := mix_target(target)
	_held.erase(name)
	if mix_target(target) > was:
		_fade_to(target, absf(float(row[1])), float(row[3]))


static func _fade_to(target: String, span_db: float, seconds: float) -> void:
	if seconds <= 0.0:
		_fade[target] = INF
		_mix[target] = mix_target(target)
	else:
		_fade[target] = span_db / seconds


## Is duck `name` held now?
static func ducked(name: String) -> bool:
	return _held.has(name)


## Where `target` ("radio" or a bus) is heading: the deepest duck held on it, 0 dB with none.
static func mix_target(target: String) -> float:
	var db := 0.0
	for name: String in _held:
		if DUCKS[name][0] == target:
			db = minf(db, float(DUCKS[name][1]))
	return db


## `target`'s level now (dB under its normal level), eased by mix_step.
static func mix_db(target: String) -> float:
	return float(_mix.get(target, 0.0))


## Moves every target towards its duck and ends the timed ducks; `dt` seconds have passed.
static func mix_step(dt: float) -> void:
	for name: String in _held.keys():
		if float(_held[name]) != INF:
			_held[name] = float(_held[name]) - dt
			if float(_held[name]) <= 0.0:
				release(name)
	for target: String in _fade:
		var want := mix_target(target)
		var rate: float = _fade[target]
		_mix[target] = want if rate == INF else move_toward(mix_db(target), want, rate * dt)


## mix_step once per frame, whoever asks first (the radio, which also runs under the pause and
## the title, and this node): two callers never move the levels twice as fast.
static func mix_frame(dt: float) -> void:
	var f := Engine.get_process_frames()
	if f == _mix_frame:
		return
	_mix_frame = f
	mix_step(dt)


## Forgets every duck (a new game reloads the scene; the checks start clean).
static func mix_reset() -> void:
	_held.clear()
	_mix.clear()
	_fade.clear()
	_mix_frame = -1


## The interface's players, under the tree's root (they outlive a scene reload): name -> player.
static var _ui_root: Node
static var _ui_players := {}
static var _ui_extra := {}


## An interface sound (UI, or one added with ui_add): the menu blip, the ringtone, the title's tap.
## Plays under the pause; asking again starts it over. An unknown name is an error.
static func ui(n: String, gain_db := 0.0) -> void:
	var row: Array = UI.get(n, _ui_extra.get(n, []))
	if row.is_empty():
		push_error("sfx: no interface sound named \"%s\" (add it to Sfx.UI)" % n)
		return
	if DisplayServer.get_name() == "headless":
		return
	var p := _ui_player(n, row)
	if p != null and p.stream != null and p.is_inside_tree():
		p.volume_db = float(row[1]) + gain_db
		p.play()


## Stops interface sound `n` if it is sounding (the ringtone when the call is answered).
static func ui_stop(n: String) -> void:
	var p: AudioStreamPlayer = _ui_players.get(n)
	if p != null and is_instance_valid(p) and p.playing:
		p.stop()


## A sound made in code joins the interface's sounds (the tape's rewind): its stream and dB.
static func ui_add(n: String, stream: AudioStream, db: float) -> void:
	_ui_extra[n] = [stream, db]


## Makes the interface's players ahead of the first sound (setup_buses): a player can only
## sound once it is in the tree, and the root takes a new child at the frame's end.
static func _ui_warm() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for n: String in UI:
		_ui_player(n, UI[n])


static func _ui_player(n: String, row: Array) -> AudioStreamPlayer:
	var have: AudioStreamPlayer = _ui_players.get(n)
	if have != null and is_instance_valid(have):
		return have
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	if _ui_root == null or not is_instance_valid(_ui_root):
		_ui_root = Node.new()
		_ui_root.name = "SfxUi"
		_ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child.call_deferred(_ui_root)
	var p := AudioStreamPlayer.new()
	p.name = n
	if AudioServer.get_bus_index(&"SFX") >= 0:
		p.bus = &"SFX"
	if row[0] is AudioStream:
		p.stream = row[0]
	elif ResourceLoader.exists(String(row[0])):
		p.stream = load(String(row[0]))
	_ui_root.add_child(p)
	_ui_players[n] = p
	return p


## Master (its limiter), Music, SFX, Ambience and Voice, and a clean mixer. Call it once, before
## the radio is made (main.gd); calling it again is safe but drops the ducks held.
static func setup_buses() -> void:
	mix_reset()
	_ui_warm()
	if AudioServer.get_bus_effect_count(0) == 0:
		var limiter := AudioEffectHardLimiter.new()
		limiter.ceiling_db = LIMIT_DB
		AudioServer.add_bus_effect(0, limiter)
	for bus in BUSES:
		var i := AudioServer.get_bus_index(bus)
		if i < 0:
			AudioServer.add_bus()
			i = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, &"Master")
		AudioServer.set_bus_volume_db(i, BUSES[bus] + user_db[bus])


## Loop 2a: the player's volumes, 0..1 each: everything, the radio, the effects (engine,
## tyres, knocks, the city's beds, the spoken clips). Zero mutes the bus.
static func set_levels(master: float, music: float, effects: float) -> void:
	var levels := {"Master": master, "Music": music, "SFX": effects, "Ambience": effects, "Voice": effects}
	for bus in levels:
		var v: float = levels[bus]
		user_db[bus] = linear_to_db(maxf(v, 0.001))
		var i := AudioServer.get_bus_index(bus)
		if i < 0:
			continue
		AudioServer.set_bus_mute(i, v <= 0.001)
		AudioServer.set_bus_volume_db(i, BUSES.get(bus, 0.0) + user_db[bus])


func setup(data: Dictionary) -> void:
	_rng.seed = 909
	for g in data.get("guards", []):
		var p: Array = g["p"]
		for k in range(0, p.size() - 3, 2):
			var a := Vector2(p[k], p[k + 1])
			var b := Vector2(p[k + 2], p[k + 3])
			var steps := maxi(1, ceili(a.distance_to(b) / 2.0))
			for s in steps + 1:
				var q := a.lerp(b, float(s) / steps)
				_rails[Vector2i(floori(q.x / 4.0), floori(q.y / 4.0))] = true
	# By name, not by listing the folder: an exported game holds only the imports.
	for n in LOOPS.keys() + SHOTS.keys() + [SIREN]:
		_streams[n] = load(DIR + n + ".wav")
	for n in LOOPS:
		var p := AudioStreamPlayer.new()
		p.stream = _streams.get(n)
		p.bus = LOOPS[n][0]
		p.volume_db = -80.0
		add_child(p)
		_loops[n] = p
		_level[n] = 0.0
		_quiet[n] = 0.0
	for n: String in SHOTS:
		var takes: Array = [_streams[n]]
		for k in range(2, MAX_TAKES + 1):
			var f := "%s%s_%d.wav" % [DIR, n, k]
			if not ResourceLoader.exists(f):
				break
			takes.append(load(f))
		_takes[n] = takes
	for k in VOICES_2D:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool2.append(p)
		_voice2.append("")
		_started2.append(0.0)
	for k in VOICES_3D:
		var p := AudioStreamPlayer3D.new()
		p.bus = &"SFX"
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.unit_size = UNIT
		p.max_distance = REACH
		p.panning_strength = 0.7
		p.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		add_child(p)
		_pool3.append(p)
	_listener = AudioListener3D.new()
	add_child(_listener)
	_listener.make_current()
	_wash = AudioStreamPlayer.new()
	_wash.stream = _streams.get("rain")
	_wash.bus = &"SFX"
	add_child(_wash)


func _exit_tree() -> void:
	for p in _loops.values():
		p.stop()
	for p in _pool2:
		p.stop()
	for p in _pool3:
		p.stop()


func _process(dt: float) -> void:
	if dt <= 0.0 or car == null:
		return
	var t0 := Time.get_ticks_usec()
	_t += dt
	_hit_wait -= dt
	_horn_wait -= dt
	_jar_wait -= dt
	_soft_t = maxf(0.0, _soft_t - dt)
	_listener.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), focus + Vector3.UP * LISTENER_UP)
	var wet: float = weather.wet if weather != null else 0.0
	var raining: float = weather.amount if weather != null else 0.0
	_engine(dt, wet)
	# The rotor winds up with the blades and down again after landing.
	var spin: float = heli.rotor_speed() if flying else 0.0
	_rotor = move_toward(_rotor, spin, dt / (1.0 if flying else 2.5))
	var climb := clampf(float(heli.vy) / 8.0, -1.0, 1.0) if flying else 0.0
	var fast := clampf(heli.speed() / 35.0, 0.0, 1.0) if flying else 0.0
	_drive("rotor", _rotor, 0.55 + 0.45 * _rotor + 0.05 * fast + 0.04 * climb, dt, 4.0)
	# Ambience: day and night beds by the light, rain on top; dips under the radio.
	var daylight: float = tod.daylight if tod != null else 1.0
	_drive("city_day", daylight * (1.0 - 0.5 * raining), 1.0, dt, 1.5)
	_drive("city_night", (1.0 - daylight) * (1.0 - 0.4 * raining), 1.0, dt, 1.5)
	_drive("rain", raining, 1.0, dt, 1.5)
	_drive("lift_hum", 1.0 if _lift_on else 0.0, 1.0, dt, 3.0)
	# The district's bed: fades under rain, at night and in the helicopter (the ground is far).
	var bed_level := (1.0 - 0.6 * raining) * (0.5 + 0.5 * daylight) * (0.4 if flying else 1.0)
	var bed := bed_now()
	for b in DISTRICT_BEDS.values():
		_drive(b, bed_level if b == bed else 0.0, 1.0, dt, BED_RATE)
	if radio != null and radio.station >= 0:
		duck("radio_on")
	else:
		release("radio_on")
	mix_frame(dt)
	if not _silent:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Ambience"), BUSES["Ambience"] + mix_db("Ambience") + user_db["Ambience"])
	_events(dt, daylight, raining)
	if _wash_t > 0.0:
		_wash_t -= dt
		_wash.volume_db = -4.0 + linear_to_db(maxf(_wash_t / WASH, 0.001))
		if _wash_t <= 0.0:
			_wash.stop()
	last_usec = Time.get_ticks_usec() - t0


## Engine and tyres. The rpm comes from the speed through a five-speed box (a launch
## slips the clutch up to ~2400 rpm); load from the throttle or, for the autopilot,
## how hard the car is speeding up.
func _engine(dt: float, wet: float) -> void:
	# What the player is in decides which loops speak: the car's engine and tyres only in the car,
	# the engine alone (an outboard stand-in) in a petrol boat, the bike's own loops on the bike,
	# nothing of the car's in the electric boat, on foot (a room, the court) or in the helicopter.
	var say := speaks(mode, flying)
	var on: bool = say[1]
	var motor: bool = say[0]
	var v := absf(car.forward_speed)
	var accel := (v - _last_v) / dt
	_last_v = v
	_load = lerpf(_load, clampf(maxf(car.throttle, accel / 3.0), 0.0, 1.0), 1.0 - exp(-6.0 * dt))
	if _gear < 5 and v > GEAR_TOP[_gear] + 0.3:
		_gear += 1
		_dip = 0.22
	elif _gear > 1 and v < GEAR_TOP[_gear - 1] - 1.5:
		_gear -= 1
	var lo: float = GEAR_TOP[_gear - 1]
	var hi: float = GEAR_TOP[_gear]
	var target := lerpf(RPM_IDLE if _gear == 1 else RPM_SHIFTED, RPM_TOP, clampf((v - lo) / (hi - lo), 0.0, 1.0))
	if _gear == 1 and v < 4.0:
		target = maxf(target, RPM_IDLE + 1550.0 * _load)
	if v < 0.6 and _load < 0.05:
		target = RPM_IDLE + 35.0 * sin(_t * 4.3) + 20.0 * sin(_t * 1.7)  # a tired idle hunts a little
	_dip -= dt
	_rpm = lerpf(_rpm, target, 1.0 - exp(-(16.0 if _dip > 0.0 else 7.0) * dt))
	var w_idle := clampf((1500.0 - _rpm) / 650.0, 0.0, 1.0)
	var w_high := clampf((_rpm - 3100.0) / 1100.0, 0.0, 1.0)
	var w_mid := clampf(1.0 - w_idle - w_high, 0.0, 1.0)
	var level := (0.5 + 0.5 * _load) * (0.45 if _dip > 0.0 else 1.0) * float(motor) * (ENGINE_SOFT if _soft_t > 0.0 else 1.0)
	var names := ["engine_idle", "engine_mid", "engine_high"]
	var weights := [w_idle, w_mid, w_high]
	for k in 3:
		_drive(names[k], level * sqrt(weights[k]), clampf(_rpm / ENGINE_RPM[k], 0.5, 2.2), dt, 14.0)
	var fast := clampf(v / 28.0, 0.0, 1.0)
	_drive("tyre_roll", pow(fast, 0.8) * (1.0 - 0.6 * wet) * float(on), 0.75 + 0.5 * fast, dt, 6.0)
	_drive("tyre_wet", pow(fast, 0.9) * wet * float(on), 0.85 + 0.35 * fast, dt, 6.0)
	var slide := clampf((car.slip - 2.5) / 5.0, 0.0, 1.0)
	if car.brakes_on and car.forward_speed > 9.0:
		slide = maxf(slide, 0.55 * clampf((v - 9.0) / 10.0, 0.0, 1.0))
	slide *= (1.0 - 0.6 * wet) * float(on)
	_drive("tyre_squeal", slide, 0.92 + 0.15 * slide + 0.05 * fast, dt, 12.0)
	# The bike: tyres and chain by speed (full at its top, car.gd BIKE_TOP); the hub ticks off
	# the pedals while it still rolls.
	var bike: bool = say[2]
	var ride := clampf(v / maxf(car.top_speed(), 1.0), 0.0, 1.0) if bike else 0.0
	_drive("bike_roll", pow(ride, 0.7) * (1.0 - 0.4 * wet) * float(bike), 0.6 + 0.6 * ride, dt, 6.0)
	var coast := float(bike and car.throttle < 0.05 and v > 1.0)
	_drive("bike_freewheel", coast * (0.4 + 0.6 * ride), 0.55 + 0.75 * ride, dt, 10.0)


## Which of the player's own loops speak for `mode` (see `mode`): [the engine, the car's tyres,
## the bike's ride]. Static so check_sfx.gd can hold every vehicle swap to it.
static func speaks(what: String, in_heli: bool) -> Array[bool]:
	if in_heli:
		return [false, false, false]
	return [what == "car" or what == "boat", what == "car", what == "bike"]


## Eases a loop towards `level` (0..1, `rate` per second) and pitch; starts it when it
## is needed and stops it after half a second of silence.
func _drive(n: String, level: float, pitch: float, dt: float, rate: float) -> void:
	var cur: float = _level[n]
	cur = lerpf(cur, level, 1.0 - exp(-rate * dt))
	_level[n] = cur
	var p: AudioStreamPlayer = _loops[n]
	if _silent or p.stream == null:
		return
	if cur > 0.003:
		p.volume_db = LOOPS[n][1] + linear_to_db(cur)
		p.pitch_scale = pitch
		_quiet[n] = 0.0
		if not p.playing:
			p.play(_rng.randf() * p.stream.get_length() * 0.9)
	elif p.playing:
		p.volume_db = -80.0
		_quiet[n] += dt
		if _quiet[n] > 0.5:
			p.stop()


## The district bed the ear is under now (a LOOPS name, "" for none): the district's, else the
## start box's square (first scene item 7).
func bed_now() -> String:
	if _bed == "" and square_box.has_point(Vector2(focus.x, focus.z)):
		return SQUARE_BED
	return _bed


## v1.0 juice: the vehicle is in district `id` ("" outside them all): its bed fades in, the
## last one fades out (districts.gd `current`).
func set_district(id: String) -> void:
	_bed = str(DISTRICT_BEDS.get(id, ""))


## v1.0 juice: the ting of a payment, once per call (money_pop.gd).
func coin() -> void:
	play("coin", 0.0)


## Senatorek (lounge.gd): one of its arrival one-shots ("door_swish", "lift_ding"), not positional.
func lounge_shot(n: String) -> void:
	play(n, 0.0)


## Senatorek's lift ride: the cabin's hum fades in while `on` and out after.
func lift_hum(on: bool) -> void:
	_lift_on = on


## Birds now and then by day (not in the rain); at night, rarely, a far siren or a dog.
func _events(dt: float, daylight: float, raining: float) -> void:
	_event_wait -= dt
	if _event_wait > 0.0:
		return
	if daylight > 0.55 and raining < 0.3:
		play("birds_a" if _rng.randf() < 0.6 else "birds_b", _rng.randf_range(-4.0, 0.0), 1.0, &"Ambience")
		_event_wait = _rng.randf_range(7.0, 16.0)
	elif daylight < 0.3:
		play("siren_far" if _rng.randf() < 0.45 else "dog_far", _rng.randf_range(-3.0, 0.0), 1.0, &"Ambience")
		_event_wait = _rng.randf_range(45.0, 110.0)
	else:
		_event_wait = 10.0


## Loop MW-5: the engine's sound softer for `seconds` (the 02:00 beat; city_sounds.gd).
func soften_engine(seconds: float) -> void:
	_soft_t = maxf(_soft_t, seconds)


func engine_softened() -> bool:
	return _soft_t > 0.0


## The player's car hit something at `speed` m/s (car.gd, where the haptics are).
func impact(collider: Object, speed: float) -> void:
	if _hit_wait > 0.0:
		return
	_hit_wait = 0.3
	var gain := linear_to_db(clampf(speed / 12.0, 0.35, 1.0))
	if not collider is AnimatableBody3D and _near_rail(car.global_position):
		play("clang", gain)
		if speed > 6.0:
			play("thump_soft", gain - 4.0)
		return
	if speed < 5.0:
		play("thump_soft", gain)
	elif speed < 10.5:
		play("thump_hard", gain)
	else:
		play("crash", gain)


## v1.0 juice: true near a guard rail (crash_fx.gd's sparks: metal throws more of them).
func near_rail(p: Vector3) -> bool:
	return _near_rail(p)


func _near_rail(p: Vector3) -> bool:
	var c := Vector2i(floori(p.x / 4.0), floori(p.z / 4.0))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if _rails.has(c + Vector2i(dx, dz)):
				return true
	return false


## Loop 10a: the car went into the water at `speed` m/s: a deep plunge (the hard knock pitched
## down) and a short wash of water (the rain bed's noise, fading out); no new sound file.
func splash(speed: float) -> void:
	if _silent:
		return
	var gain := linear_to_db(clampf(speed / 14.0, 0.4, 1.0))
	play("thump_hard", gain, 0.6)
	_wash.volume_db = -4.0 + gain
	_wash.play(_rng.randf() * 2.0)
	_wash_t = WASH


## The słoiki run: 0 = the jars clink (a bump, a warning), 1 = one broke.
func jars(kind: int) -> void:
	if _jar_wait > 0.0 and kind == 0:
		return
	_jar_wait = 0.45
	play("jar_break" if kind == 1 else "jar_clink", _rng.randf_range(-3.0, 0.0))


## A tram rings as it leaves a stop or at a car on its track.
func tram_bell(at: Vector3) -> void:
	_play3("tram_bell", at, 0.0)


## An AI car held up by (or hit by) the player sounds its horn, sometimes.
func horn(at: Vector3) -> void:
	if _horn_wait > 0.0 or _rng.randf() > 0.7:
		return
	_horn_wait = 2.5
	_play3("horn_double" if _rng.randf() < 0.5 else "horn", at, _rng.randf_range(-3.0, 0.0))


func pigeons(at: Vector3) -> void:
	_play3("pigeons", at, 0.0)


## Loop MW-4: one of the city's one-shots (SHOTS) at `at` (city_life.gd: barks, bells, beeps).
## The night-buses loop: the player's horn (not positional: it is the player's own car).
func horn_player() -> void:
	play("horn_player", 0.0)


func play_at(n: String, at: Vector3, gain_db := 0.0) -> void:
	_play3(n, at, gain_db)


## The rule of sound `n`: [priority, most voices at once, pitch spread].
static func rule_of(n: String) -> Array:
	return SHOT_RULES.get(n, RULE_DEFAULT)


## Which 2D voice sound `n` gets, -1 for none. `playing[i]` is what voice i plays ("" when free),
## `started[i]` when it began. A sound already on all the voices it may have starts its oldest one
## again; else a free voice; else the least important busy voice (the oldest of those), and only
## when `n` matters at least as much.
static func pick_voice(playing: Array[String], started: Array[float], n: String) -> int:
	var rule := rule_of(n)
	var free := -1
	var same := -1
	var same_n := 0
	var weak := -1
	for i in playing.size():
		if playing[i] == "":
			if free < 0:
				free = i
			continue
		if playing[i] == n:
			same_n += 1
			if same < 0 or started[i] < started[same]:
				same = i
		var pri: int = rule_of(playing[i])[0]
		if weak < 0 or pri < int(rule_of(playing[weak])[0]) or (pri == int(rule_of(playing[weak])[0]) and started[i] < started[weak]):
			weak = i
	if same_n >= int(rule[1]):
		return same
	if free >= 0:
		return free
	if weak >= 0 and int(rule_of(playing[weak])[0]) <= int(rule[0]):
		return weak
	return -1


## True for a sound in SHOTS; anything else is reported once (a typo used to play nothing, silently).
func _known(n: String) -> bool:
	if SHOTS.has(n):
		return true
	if not _unknown.has(n):
		_unknown[n] = true
		push_error("sfx: no one-shot named \"%s\" (add it to Sfx.SHOTS)" % n)
	return false


var _unknown := {}


## A take of `n` (not the one played last, when there are several) and the pitch for it.
func _take(n: String) -> AudioStream:
	var takes: Array = _takes.get(n, [])
	if takes.size() <= 1:
		return _streams.get(n)
	var k := _rng.randi() % takes.size()
	if k == int(_last_take.get(n, -1)):
		k = (k + 1) % takes.size()
	_last_take[n] = k
	return takes[k]


func _spread(n: String, pitch: float) -> float:
	var w: float = rule_of(n)[2]
	return pitch * (1.0 + _rng.randf_range(-w, w)) if w > 0.0 else pitch


## A one-shot with no place (the player's own car, a cue): SHOTS name, dB on top of its level,
## pitch, bus. The door every such sound goes through (pick_voice).
func play(n: String, gain_db := 0.0, pitch := 1.0, bus := &"SFX") -> void:
	if not _known(n) or _silent:
		return
	for i in _pool2.size():
		if not _pool2[i].playing:
			_voice2[i] = ""
	var i := pick_voice(_voice2, _started2, n)
	if i < 0:
		return
	var p := _pool2[i]
	p.stream = _take(n)
	p.bus = bus
	p.volume_db = float(SHOTS[n]) + gain_db
	p.pitch_scale = _spread(n, pitch)
	p.play()
	_voice2[i] = n
	_started2[i] = _t


## A positional one-shot: skipped out of reach; a free voice, or the farthest busy
## one if the new sound is nearer (the cap on voices).
func _play3(n: String, at: Vector3, gain_db: float) -> void:
	if not _known(n) or _silent:
		return
	var ear := focus + Vector3.UP * LISTENER_UP
	var d := at.distance_to(ear)
	if d > REACH * 0.95:
		return
	var pick: AudioStreamPlayer3D = null
	var far := d
	for p in _pool3:
		if not p.playing:
			pick = p
			break
		var dp := p.global_position.distance_to(ear)
		if dp > far:
			far = dp
			pick = p
	if pick == null:
		return
	pick.stop()
	pick.stream = _take(n)
	pick.global_position = at
	pick.volume_db = float(SHOTS[n]) + gain_db
	pick.pitch_scale = _spread(n, 1.0)
	pick.play()


## The loudest peak (dBFS) of each bus in the last mix, for the meters (--bench,
## --sound-check). Needs an audio device: headless runs read -200.
static func bus_peaks() -> Dictionary:
	var out := {}
	for bus in ["Master", "Music", "SFX", "Ambience", "Voice"]:
		var i := AudioServer.get_bus_index(bus)
		out[bus] = maxf(AudioServer.get_bus_peak_volume_left_db(i, 0), AudioServer.get_bus_peak_volume_right_db(i, 0))
	return out


## --sound-check: plays every one-shot in turn (the positional ones 15 m from the
## listener's spot, as a horn across the street) and prints the loudest peak per bus
## while it sounds, over whatever the beds and the radio are doing. Then quits.
func sound_check() -> void:
	var tree := get_tree()
	await tree.create_timer(2.0).timeout
	print("sound check: the beds alone, then each one-shot; peaks in dBFS (radio on Music, beds on Ambience)")
	await _meter("(beds and engine idling)", 2.0)
	for n in SHOTS:
		var at := focus + Vector3(15.0, 0.0, 0.0)
		if n in ["tram_bell", "horn", "horn_double", "pigeons", "tram_creak", "old_tram_bell", "loud_rev",
				"train_rumble", "train_bridge", "train_horn", "station_gong"]:
			_play3(n, at, 0.0)
		elif n in ["birds_a", "birds_b", "siren_far", "dog_far"]:
			play(n, 0.0, 1.0, &"Ambience")
		else:
			play(n, 0.0)
		await _meter(n, minf(_streams[n].get_length() + 0.2, 3.0))
	tree.quit()


func _meter(label: String, seconds: float) -> void:
	var top := {"Master": -200.0, "Music": -200.0, "SFX": -200.0, "Ambience": -200.0}
	var t := 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()
		var p := bus_peaks()
		for bus in top:
			top[bus] = maxf(top[bus], p[bus])
	print("  %-26s Master %6.1f  Music %6.1f  SFX %6.1f  Ambience %6.1f" % [label, top["Master"], top["Music"], top["SFX"], top["Ambience"]])


# --- loop 3g-1: the police (loop 3g-2: their own sounds) -------------------------------------
# The two-tone siren, the whoop, the megaphone chirp, the whistle, the stamp, the scribble and
# the clamp's clank from tools/make_sfx.py (police.md section 10; 3g-1 borrowed the far siren,
# the tram bell and the soft knock). The escape's chord is still the tram bell, pitched.

var _siren_voice: AudioStreamPlayer3D
var _scene_voice: AudioStreamPlayer3D


## The siren on the nearest chaser: one positional voice of the six (taken like a one-shot's,
## the farthest busy one if none is free), following `at`; Vector3.INF stops it.
func police_siren(at: Vector3) -> void:
	if _silent or _pool3.is_empty():
		return
	if at == Vector3.INF:
		if _siren_voice != null and _siren_voice.stream == _streams.get(SIREN):
			_siren_voice.stop()
		_siren_voice = null
		return
	if _siren_voice == null or _siren_voice.stream != _streams.get(SIREN):
		var ear := focus + Vector3.UP * LISTENER_UP
		var far := -1.0
		for p in _pool3:
			if not p.playing:
				_siren_voice = p
				break
			var dp := p.global_position.distance_to(ear)
			if dp > far:
				far = dp
				_siren_voice = p
		_siren_voice.stop()
		_siren_voice.stream = _streams.get(SIREN)
		_siren_voice.volume_db = SIREN_DB
		_siren_voice.pitch_scale = 1.0
	_siren_voice.global_position = at
	if not _siren_voice.playing:
		_siren_voice.play()

## The crash scene's siren (crash_scenes.gd): a voice of its own at `at`, Vector3.INF stops it.
func scene_siren(at: Vector3) -> void:
	if _silent or _pool3.is_empty():
		return
	if at == Vector3.INF:
		if _scene_voice != null and _scene_voice.stream == _streams.get(SIREN):
			_scene_voice.stop()
		_scene_voice = null
		return
	if _scene_voice == null or _scene_voice.stream != _streams.get(SIREN):
		var ear := focus + Vector3.UP * LISTENER_UP
		var far := -1.0
		for p in _pool3:
			if p == _siren_voice:
				continue
			if not p.playing:
				_scene_voice = p
				break
			var dp := p.global_position.distance_to(ear)
			if dp > far:
				far = dp
				_scene_voice = p
		if _scene_voice == null:
			return
		_scene_voice.stop()
		_scene_voice.stream = _streams.get(SIREN)
		_scene_voice.volume_db = SCENE_SIREN_DB
		_scene_voice.pitch_scale = 1.0
	_scene_voice.global_position = at
	if not _scene_voice.playing:
		_scene_voice.play()


## A police cue (2D): "whoop" (a unit warns or joins), "megaphone" (before its line), "whistle"
## (the lizak, a city guard), "stamp" (the end of a caution), "scribble" (the clamp's
## countdown), "clank" (the clamp on and off), "chord" (escaped).
func police_cue(kind: String) -> void:
	match kind:
		"whoop":
			play("police_whoop", 0.0, 1.0)
		"megaphone", "whistle", "stamp", "scribble", "clank":
			play(kind, 0.0, 1.0)
		"chord":
			play("tram_bell", -6.0, 1.5)


## Voices playing now (loops and one-shots), for the perf overlay.
func voices() -> int:
	var n := 0
	for p in _loops.values():
		n += int(p.playing)
	for p in _pool2:
		n += int(p.playing)
	for p in _pool3:
		n += int(p.playing)
	return n
