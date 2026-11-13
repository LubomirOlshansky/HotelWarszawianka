extends Node3D
## Loop MW-5 (docs/design/vision.md 3.1, 3.5, 3.10, 4.6): the city's sounds at the notebook's
## places, positional, all from tools/make_sfx.py (original synthesis, no samples):
##  - **club**: a place tagged `club` with `hours` (places.json, "PT–SB 23:00–08:00"): its bass
##    leaking through the door (`club_leak`, a loop) while it is open by the game clock;
##  - **metro**: a place tagged `metro`: our own three-note chime (`metro_chime`) when a train
##    arrives below, every 3-4 minutes;
##  - **bells**: a place tagged `church`, or `old_town` but not a bridge: the hour struck on a
##    church bell (`church_bell`, 1-12 tolls);
##  - **busker**: a place tagged `buskers` (the Patelnia): a street-guitar loop (`busker`) from
##    19:00 to 22:00;
##  - **the 02:00 beat**: at the place tagged `quiet` (Plac Trzech Krzyży), between 02:00 and
##    02:15, the car within BEAT_RADIUS m: the radio drops to PÓŁNOC FM's host (radio.gd
##    host_moment) and the engine sounds softer for BEAT_SECONDS (sfx.gd soften_engine), once a
##    night.
## Loop MW-3: the crowds (crowds.gd `add_crowd`) add **murmur** (a queue's or the steps' talk,
## `crowd_murmur`) and the steps' **guitar** (`steps_guitar`, within 20 m), each sounding while
## its crowd says so (`when`). The dog barks wait for MW-4. F (2026-11-06): the Powiśle saucer's
## jazz band (**jazz**, `jazz_trio`) from its stage while the band is on it; THE WJU's DJ on
## Spektrum's roof (**rooftop**, `techno_thump`) while the DJ is at the booth.
## At most MAX_LIVE players sound at once: the nearest emitters that are sounding, each only
## within its kind's reach. Everything is decided twice a second (TICK) from the camera's focus
## and the game clock (time_of_day.gd local_clock); nothing runs per frame but a timer. Headless
## runs (the checks) choose and count the same but play nothing.

const DIR := "res://audio/sfx/"
const MAX_LIVE := 8
## Seconds between two ticks.
const TICK := 0.5
## Per kind: the sound, its level (dB on the SFX bus), the distance it is at full level (the
## player's unit_size), how far it reaches (m, on the ground) and the emitter's height (m).
const KINDS := {
	"club": {"file": "club_leak", "db": -10.0, "unit": 8.0, "reach": 70.0, "up": 1.5},
	"metro": {"file": "metro_chime", "db": -12.0, "unit": 10.0, "reach": 80.0, "up": 0.5},
	"bells": {"file": "church_bell", "db": -6.0, "unit": 30.0, "reach": 260.0, "up": 20.0},
	"busker": {"file": "busker", "db": -11.0, "unit": 8.0, "reach": 60.0, "up": 1.2},
	"murmur": {"file": "crowd_murmur", "db": -13.0, "unit": 10.0, "reach": 55.0, "up": 1.5},
	"guitar": {"file": "steps_guitar", "db": -12.0, "unit": 4.0, "reach": 25.0, "up": 1.0},
	# Loop MW-4: a trend queue's chatter (the Wiralek slots, Lukrownia), closer and smaller than
	# the murmur.
	"queue": {"file": "queue_chatter", "db": -15.0, "unit": 6.0, "reach": 40.0, "up": 1.5},
	# The fans by Stadion Leguminy (fans.gd): a drum and a wordless crowd chant on match evenings.
	"chant": {"file": "fan_chant", "db": -12.0, "unit": 10.0, "reach": 90.0, "up": 1.5},
	# The wellness circles (wellness.gd): a sound-healing ring's gong and bowls, the techno-yoga speaker's thump.
	"gong": {"file": "gong_bowls", "db": -13.0, "unit": 8.0, "reach": 60.0, "up": 1.0},
	"thump": {"file": "techno_thump", "db": -12.0, "unit": 8.0, "reach": 70.0, "up": 1.0},
	# F (2026-11-06): the jazz band under the Powiśle saucer (crowds.gd's `jazz` site), heard across
	# the square and from Kruczkowskiego while the concert is on.
	"jazz": {"file": "jazz_trio", "db": -9.0, "unit": 12.0, "reach": 95.0, "up": 2.0},
	# F (2026-11-13): THE WJU's DJ on Spektrum Tower's roof (crowds.gd's `view_dj` site), 125 m up:
	# a wide unit so the beat carries down to Twarda faintly and fills the helicopter by the roof.
	"rooftop": {"file": "techno_thump", "db": -8.0, "unit": 35.0, "reach": 150.0, "up": 1.5},
}
const LOOPING := ["club", "busker", "murmur", "guitar", "queue", "chant", "gong", "thump", "jazz", "rooftop"]
## A train below a metro entrance every 3-4 minutes (vision.md 3.5).
const METRO_GAP := Vector2(180.0, 240.0)
## The Patelnia's busker from 19:00 to 22:00 (vision.md 3.10: "at 19:00").
const BUSKER_HOURS := Vector2(19.0, 22.0)
## Seconds between two tolls of the hour.
const TOLL_GAP := 2.5
## The 02:00 beat (vision.md 3.10).
const BEAT_FROM := 2.0
const BEAT_TO := 2.25
const BEAT_RADIUS := 45.0
const BEAT_SECONDS := 10.0
const DAYS := {"PN": 1, "WT": 2, "ŚR": 3, "CZ": 4, "PT": 5, "SB": 6, "ND": 7}

## The emitters: {id, kind, at: Vector3, hours: {days, from, to} or {}, player (or null),
## next (metro: seconds of play to the next train)}.
var emitters: Array[Dictionary] = []
## The game clock, -> {hour, weekday} (time_of_day.gd local_clock).
var clock: Callable
## Where the ear is, -> Vector3 (the camera's focus, as sfx.gd's listener).
var ear: Callable
## The radio (host_moment) and the sound (soften_engine) for the 02:00 beat; may be null.
var radio: Node
var sfx: Node
## --radio-log: `sounds:` lines (emitters on and off, chimes, tolls, the beat).
var log_on := false
## Time spent in the ticks since the bench last read it (µs).
var spent_usec := 0
## How many players hold an emitter now.
var live := 0
## Reach multiplier (the check stretches it to test the cap).
var reach_scale := 1.0
## The beat fired this many times (the check reads it).
var beats := 0
## Where the 02:00 beat happens (the place tagged `quiet`), Vector3.INF if none.
var quiet_at := Vector3.INF

var _pool: Array[AudioStreamPlayer3D] = []
var _streams := {}
var _t := 0.0
var _play_t := 0.0
var _silent := DisplayServer.get_name() == "headless"
var _rng := RandomNumberGenerator.new()
var _hour_seen := -1
var _tolls_left := 0
var _toll_wait := 0.0
var _beat_night := -1


## The emitters from the notebook's places (notebook.gd `places`, each with `at`), and the
## players. `ground`: (x, z) -> the ground's height there.
func setup(places: Array, ground: Callable) -> void:
	_rng.seed = 2605
	emitters.clear()
	for place: Dictionary in places:
		var at2: Vector2 = place["at"]
		var y: float = float(ground.call(at2.x, at2.y)) if ground.is_valid() else 0.0
		if "quiet" in place.get("tags", []):
			quiet_at = Vector3(at2.x, y, at2.y)
		var hours := parse_hours(str(place["hours"])) if place.get("hours") != null else {}
		for kind in kinds_of(place):
			emitters.append({"id": str(place["id"]), "kind": kind, "at": Vector3(at2.x, y + float(KINDS[kind]["up"]), at2.y),
					"hours": hours, "player": null, "next": _rng.randf_range(20.0, METRO_GAP.y)})
	for k in KINDS:
		_streams[k] = load(DIR + str(KINDS[k]["file"]) + ".wav")
	for i in MAX_LIVE:
		var p := AudioStreamPlayer3D.new()
		p.bus = &"SFX"
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.panning_strength = 0.7
		p.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		add_child(p)
		_pool.append(p)
	var counts := {}
	for e in emitters:
		counts[e["kind"]] = int(counts.get(e["kind"], 0)) + 1
	print("sounds: %d emitters %s, the 02:00 beat %s" % [emitters.size(), counts, "at Plac Trzech Krzyży" if quiet_at != Vector3.INF else "(no quiet place)"])


## Loop MW-3: a crowd's sound at `at` (kind "murmur" or "guitar"; loop MW-4: "queue"), sounding
## while `when` says.
func add_crowd(id: String, kind: String, at: Vector3, when: Callable) -> void:
	emitters.append({"id": id, "kind": kind, "at": at + Vector3(0, float(KINDS[kind]["up"]), 0), "hours": {},
			"player": null, "next": 0.0, "when": when})


## Which sounds a place makes (the Patelnia: the busker and Metro Centrum's chime): see the
## class comment.
static func kinds_of(place: Dictionary) -> Array[String]:
	var tags: Array = place.get("tags", [])
	var out: Array[String] = []
	if "club" in tags and place.get("hours") != null:
		out.append("club")
	if "buskers" in tags:
		out.append("busker")
	if "metro" in tags:
		out.append("metro")
	if "church" in tags or ("old_town" in tags and not "bridge" in tags):
		out.append("bells")
	return out


## "PT–SB 23:00–08:00" -> {days: [5, 6], from: 23.0, to: 8.0}; {} if it doesn't parse.
static func parse_hours(text: String) -> Dictionary:
	var t := text.replace("–", "-").strip_edges()
	var parts := t.split(" ", false)
	if parts.size() != 2:
		return {}
	var dd := parts[0].split("-")
	var hh := parts[1].split("-")
	if hh.size() != 2 or not DAYS.has(dd[0]) or not DAYS.has(dd[dd.size() - 1]):
		return {}
	var a: int = DAYS[dd[0]]
	var b: int = DAYS[dd[dd.size() - 1]]
	var days: Array[int] = []
	var d := a
	while true:
		days.append(d)
		if d == b:
			break
		d = d % 7 + 1
	return {"days": days, "from": _h(hh[0]), "to": _h(hh[1])}


static func _h(hm: String) -> float:
	var p := hm.split(":")
	return float(p[0]) + (float(p[1]) / 60.0 if p.size() > 1 else 0.0)


## Open at `hour` on `weekday` (1 Monday .. 7 Sunday)? Hours past midnight belong to the day
## they started (Friday's 23:00-08:00 is open at 03:00 on Saturday).
static func is_open(hours: Dictionary, hour: float, weekday: int) -> bool:
	if hours.is_empty():
		return false
	var days: Array = hours["days"]
	var from: float = hours["from"]
	var to: float = hours["to"]
	if from < to:
		return weekday in days and hour >= from and hour < to
	if hour >= from:
		return weekday in days
	if hour < to:
		return ((weekday + 5) % 7 + 1) in days
	return false


## The emitter is sounding at `now` (bells only while the hour is being struck).
func sounding(e: Dictionary, now: Dictionary) -> bool:
	if e.has("when"):
		return (e["when"] as Callable).call()
	match String(e["kind"]):
		"club":
			return is_open(e["hours"], float(now["hour"]), int(now["weekday"]))
		"busker":
			return float(now["hour"]) >= BUSKER_HOURS.x and float(now["hour"]) < BUSKER_HOURS.y
		"metro":
			return true
		"bells":
			return _tolls_left > 0
	return false


func _process(dt: float) -> void:
	if emitters.is_empty() or not clock.is_valid() or not ear.is_valid():
		return
	_t += dt
	if _t < TICK:
		return
	var step := _t
	_t = 0.0
	var t0 := Time.get_ticks_usec()
	var e3: Vector3 = ear.call()
	tick(Vector2(e3.x, e3.z), clock.call(), step)
	spent_usec += Time.get_ticks_usec() - t0


## One tick: the ear at `ear2` (map x, z), the game clock `now` ({hour, weekday}), `step` s since
## the last. The hour's tolls, then who holds a player, then the chimes and the beat.
func tick(ear2: Vector2, now: Dictionary, step: float) -> void:
	_play_t += step
	var hour := float(now["hour"])
	var h := int(floor(hour))
	if _hour_seen >= 0 and h != _hour_seen:
		strike(h)
	_hour_seen = h
	if _tolls_left > 0:
		_toll_wait -= step
	_assign(ear2, now)
	if _tolls_left > 0 and _toll_wait <= 0.0:
		_tolls_left -= 1
		_toll_wait = TOLL_GAP
		for e in emitters:
			if e["kind"] == "bells" and e["player"] != null:
				_fire(e)
		if _tolls_left == 0 and log_on:
			print("sounds: %.1f s  the hour struck" % _play_t)
	for e in emitters:
		if e["kind"] == "metro" and _play_t >= float(e["next"]):
			e["next"] = float(e["next"]) + _rng.randf_range(METRO_GAP.x, METRO_GAP.y)
			if e["player"] != null:
				_fire(e)
				if log_on:
					print("sounds: %.1f s  metro chime at %s" % [_play_t, e["id"]])
	_beat(ear2, hour, int(now["weekday"]))


## The hour `h` (0-23) is struck: 1-12 tolls on every bell within reach.
func strike(h: int) -> void:
	_tolls_left = 12 if h % 12 == 0 else h % 12
	_toll_wait = 0.0
	if log_on:
		print("sounds: %.1f s  %02d:00, %d tolls" % [_play_t, h, _tolls_left])


## The nearest sounding emitters within reach get a player (at most MAX_LIVE); the rest give
## theirs back.
func _assign(ear2: Vector2, now: Dictionary) -> void:
	var want: Array = []
	for i in emitters.size():
		var e: Dictionary = emitters[i]
		var at: Vector3 = e["at"]
		var d := ear2.distance_to(Vector2(at.x, at.z))
		if d <= float(KINDS[e["kind"]]["reach"]) * reach_scale and sounding(e, now):
			want.append([d, i])
	want.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	if want.size() > MAX_LIVE:
		want.resize(MAX_LIVE)
	var keep := {}
	for w: Array in want:
		keep[w[1]] = true
	for i in emitters.size():
		var e: Dictionary = emitters[i]
		if e["player"] != null and not keep.has(i):
			var p: AudioStreamPlayer3D = e["player"]
			p.stop()
			e["player"] = null
			_pool.append(p)
			if log_on:
				print("sounds: %.1f s  off %s %s" % [_play_t, e["kind"], e["id"]])
	for w: Array in want:
		var e: Dictionary = emitters[w[1]]
		if e["player"] != null or _pool.is_empty():
			continue
		var p: AudioStreamPlayer3D = _pool.pop_back()
		var k: Dictionary = KINDS[e["kind"]]
		p.stream = _streams.get(e["kind"])
		p.unit_size = float(k["unit"])
		p.max_distance = float(k["reach"]) * 1.2
		p.volume_db = float(k["db"])
		p.position = e["at"]
		e["player"] = p
		if e["kind"] in LOOPING and not _silent and p.stream != null:
			p.play(_rng.randf() * p.stream.get_length() * 0.9)
		if log_on:
			print("sounds: %.1f s  on %s %s, %.0f m" % [_play_t, e["kind"], e["id"], w[0]])
	live = 0
	for e in emitters:
		live += int(e["player"] != null)


func _fire(e: Dictionary) -> void:
	var p: AudioStreamPlayer3D = e["player"]
	if p != null and not _silent and p.stream != null:
		p.play()


## The 02:00 beat on Plac Trzech Krzyży: once a night, the car on the square between BEAT_FROM
## and BEAT_TO o'clock.
func _beat(ear2: Vector2, hour: float, weekday: int) -> void:
	if quiet_at == Vector3.INF or hour < BEAT_FROM or hour >= BEAT_TO or _beat_night == weekday:
		return
	if ear2.distance_to(Vector2(quiet_at.x, quiet_at.z)) > BEAT_RADIUS:
		return
	_beat_night = weekday
	beats += 1
	var on_radio: bool = radio != null and radio.has_method("host_moment") and radio.host_moment(BEAT_SECONDS)
	if sfx != null and sfx.has_method("soften_engine"):
		sfx.soften_engine(BEAT_SECONDS)
	if log_on:
		print("sounds: %.1f s  02:00 on Plac Trzech Krzyży: %s, the engine softer for %.0f s" % [_play_t,
				"the radio drops to PÓŁNOC FM's host" if on_radio else "the radio is off", BEAT_SECONDS])


func _exit_tree() -> void:
	for p in _pool:
		p.stop()
	for e in emitters:
		if e["player"] != null:
			(e["player"] as AudioStreamPlayer3D).stop()
