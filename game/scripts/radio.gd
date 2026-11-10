extends Node
## The car radio: made-up stations, each with a playlist, and Off. The stations and their
## tracks come from data/radio.json (tools/add_music.py puts songs there: README, "Adding
## music"); a station with several tracks plays them in a shuffled order, each to its end,
## and one with a single track loops it. R or the RADIO button tunes to the next station;
## a short burst of static covers the switch. Every change emits station_changed, every
## new track track_changed, and announce() puts any line (the radio host's, dialogue.gd)
## on the HUD's now-playing ticker.
##
## Loop radio-playlists: the stations moved from a const with one WAV loop each to
## radio.json with Ogg Vorbis tracks (streamed: the compressed file is decoded as it plays,
## never as a whole in memory) and playlists shuffled by the date.
##
## Loop MW-5 (docs/design/vision.md 4.6): PÓŁNOC FM, 86,0, the late-night station. On air
## 22:00-06:00 by the game clock (`clock`) and always in the Night and Dawn looks; by day it
## plays reruns at 70 % level and its host is silent (host_group). A station with "free": N in
## radio.json has locked tracks: its first N are free, the rest open one a finished notebook
## chapter, in order (sync_chapters), or by unlock_track(n) (the eggs E14 and E31 later); a
## locked track never plays. The unlocks live in the save (wallet.gd `tracks`). Until the player
## picks a station this session (`picked`), the radio follows the clock: PÓŁNOC FM on air, KEBAB
## FM otherwise. --radio-log prints the tunes, tracks, host lines, unlocks and air changes.

const Lang := preload("res://scripts/lang.gd")

signal station_changed(index: int, station: Dictionary)
## A line for the now-playing ticker: a station change, a new track, or a host's line with
## its English subtitle (held longer).
signal ticker(text: String, colour: Color, subtitle: String)
## A track has started on the tuned station. `natural` is true when the last one ran out on
## its own (not a tune or a skip): dialogue.gd's host may speak between the two.
signal track_changed(info: Dictionary, track: Dictionary, natural: bool)
## Loop MW-5: a locked track was opened: its number on the station (1 = the first in
## radio.json), the track, and why ("chapter", "egg", "flag").
signal track_unlocked(number: int, track: Dictionary, why: String)
## Loop MW-5: PÓŁNOC FM went on air (true) or to its daytime reruns (false).
signal air_changed(on_air: bool)
## Loop MW-5: the host should speak now (the 02:00 beat on Plac Trzech Krzyży; dialogue.gd).
signal host_wanted

const PATH := "res://data/radio.json"
## The built-in stations, used when radio.json is missing or unreadable: names, frequencies
## and colours only (the music lives in radio.json, so these have no tracks and play only the
## tuning static).
const STATIONS := [
	{"id": "nocna_fm", "name": "KEBAB FM", "freq": "87,3", "colour": Color("#ff5fc8")},
	{"id": "rondo_fm", "name": "RONDO FM", "freq": "86,6", "colour": Color("#4ff0ff")},
	{"id": "mordor_fm", "name": "MORDOR FM", "freq": "108,8", "colour": Color("#b98cff")},
]
## First scene item 7 (docs/design/first-scene.md, 2026-11-02): the first launch's radio starts its
## song at the beginning under the title (main.gd sets it for a fresh save), not somewhere in the
## middle as a single-track station otherwise joins; cleared after the first tune.
var from_top := false
## Moderate: under the (future) engine and city sounds.
const VOLUME_DB := -9.0
## Loop MW-5: the late-night station's id, and the station the radio falls back to by day
## until the player picks one (KEBAB FM).
const POLNOC := "polnoc_fm"
const DAY_DEFAULT := "nocna_fm"
## Loop MW-5: on air in these looks whatever the clock says, else from AIR_FROM to AIR_TO
## o'clock; reruns at 70 % level (linear_to_db(0.7)).
const AIR_LOOKS := ["Night", "Dawn"]
const AIR_FROM := 22.0
const AIR_TO := 6.0
const RERUN_DB := -3.1
## Loop MW-5: the music under the host's moment (the 02:00 beat), dB.
const MOMENT_DB := -10.0

## -1 = off, else an index into `stations`.
var station := -1
## The stations as read from radio.json: {id, name, freq, colour: Color, tracks: [{file,
## title, artist, seconds, gain_db, licence, source}]}.
var stations: Array[Dictionary] = []
## Beta radio (2026-11-02): the stations R and the RADIO button cycle through, by index in
## `stations` ("lineup" in radio.json: station ids, in order; all of them when it is missing).
## The rest stay loaded, so --station= and the tape and cassette unlocks still reach them.
var lineup: Array[int] = []
## Loop 3g-1: dB under the station's level while a conversation is on (the pull-over: -6).
var duck_db := 0.0:
	set(value):
		duck_db = value
		_apply_level()
## Opening sound (2026-11-03): dB under the station's level while the announcer's line plays over
## the flyover (opening_audio.gd moves it: down to a quiet bed, then back up to 0).
var bed_db := 0.0:
	set(value):
		bed_db = value
		_apply_level()
## Loop MW-5: the save (wallet.gd `tracks`, `track_chapters`, `chapters_done`); null: only the
## free tracks play.
var wallet: Node
## Loop MW-5: the game clock, -> [look name (TimeOfDay.NAMES), hour 0..24]; unset: always on air.
var clock: Callable
## Loop MW-5: the player chose a station this session (R, RADIO, --radio=, --station=): the
## radio stops following the clock.
var picked := false
## Loop MW-5: --radio-log.
var log_on := false
## Loop MW-5: --unlock=all: every track plays (this run only, nothing saved).
var unlock_all := false
var _air := true
var _air_t := 0.0
var _moment_t := 0.0
## Loop MW-5: seconds of play (frame deltas, so --fixed-fps runs log game time) and the host's
## last line then (the log's gaps).
var _play_s := 0.0
var _last_host_s := -1.0
## Loop MW-5: headless runs play nothing, so a track never ends there; this counts its time
## and ends it on schedule instead, so a headless --radio-log run shows the playlist moving.
var _track_t := 0.0
var _player: AudioStreamPlayer
var _static: AudioStreamPlayer
## Station jingles (F, 2026-11-05): a short ElevenLabs clip in the station's voice that plays
## between two songs, after every JINGLE_EVERY-th natural track end, so about one per 4-6 minutes.
## The next song waits until the clip is over. A station without jingles, a skip or a tune-in
## never plays one.
const JINGLE_EVERY := 2
const JINGLE_DB := -3.0
var _jingle: AudioStreamPlayer
var _since_jingle := 0
var _last_jingle := -1
## The jingle is on air now (the next song starts when it ends).
var jingle_playing := false
## Per station: its tracks' indices in the order they play today (a shuffle seeded by the
## date and the station, so a day has its own order and every run of it is the same).
var _orders: Array = []
## Per station: where it is in its order. Tuning back to a station starts that track again.
var _pos: Array[int] = []
## Loaded track streams by file (the resource cache keeps them; this skips the lookup).
var _streams := {}
## Headless runs (tests) have no audio device: the dummy driver never mixes, so a
## playing stream would never be released. The radio keeps its state but stays silent.
var _silent := DisplayServer.get_name() == "headless"


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = VOLUME_DB
	# The Music bus (sfx.gd setup_buses); the ambience dips while a station plays.
	_player.bus = &"Music"
	add_child(_player)
	_player.finished.connect(_on_finished)
	_jingle = AudioStreamPlayer.new()
	_jingle.bus = &"Music"
	add_child(_jingle)
	_jingle.finished.connect(_on_jingle_finished)
	_static = AudioStreamPlayer.new()
	_static.volume_db = VOLUME_DB - 4.0
	_static.bus = &"Music"
	if ResourceLoader.exists("res://audio/ui/tune.wav"):
		_static.stream = load("res://audio/ui/tune.wav")
	add_child(_static)
	_load_stations()


func _exit_tree() -> void:
	# Quitting while a stream plays would leave its playback behind.
	_player.stop()
	_player.stream = null
	_jingle.stop()
	_jingle.stream = null
	_static.stop()


# --- the stations ---------------------------------------------------------------------

## Reads data/radio.json into `stations` (the built-in list when it is missing or has no
## stations) and shuffles each station's order.
func _load_stations() -> void:
	stations = []
	var data: Variant = null
	if FileAccess.file_exists(PATH):
		data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if data is Dictionary and data.get("stations") is Array:
		for s: Variant in data["stations"]:
			if s is Dictionary and s.has("name") and s.has("freq"):
				stations.append(_station_from(s))
	if stations.is_empty():
		for s: Dictionary in STATIONS:
			var d := s.duplicate(true)
			d["tracks"] = []
			stations.append(d)
	lineup = []
	if data is Dictionary and data.get("lineup") is Array:
		for id: Variant in data["lineup"]:
			var i := station_index(String(id))
			if i >= 0 and not lineup.has(i):
				lineup.append(i)
	if lineup.is_empty():
		for i in stations.size():
			lineup.append(i)
	_orders = []
	_pos = []
	for i in stations.size():
		_orders.append(_shuffled(stations[i]["tracks"].size(), i))
		_pos.append(0)


func _station_from(s: Dictionary) -> Dictionary:
	var tracks: Array = []
	for t: Variant in s.get("tracks", []):
		if not (t is Dictionary) or not t.has("file"):
			continue
		if not ResourceLoader.exists(String(t["file"])):
			push_warning("radio: %s's track file %s is missing" % [s["name"], t["file"]])
			continue
		tracks.append({
			"file": String(t["file"]), "title": String(t.get("title", "")),
			"artist": String(t.get("artist", "")), "seconds": float(t.get("seconds", 0.0)),
			"gain_db": float(t.get("gain_db", 0.0)), "licence": String(t.get("licence", "unknown")),
			"source": String(t.get("source", "")),
		})
	# Loop MW-5: "free": the station's first N tracks play from the start, the rest are locked
	# (-1: none locked).
	return {"id": String(s.get("id", "")), "name": String(s["name"]), "freq": String(s["freq"]),
			"colour": Color(String(s.get("colour", "#c9c4d8"))), "tracks": tracks, "free": int(s.get("free", -1)),
			"jingles": _existing(s.get("jingles", []))}


## The files of a list that exist (a missing jingle is skipped, never an error).
func _existing(files: Variant) -> Array:
	var out: Array = []
	if files is Array:
		for f: Variant in files:
			if ResourceLoader.exists(String(f)):
				out.append(String(f))
	return out


## A Fisher-Yates shuffle of 0..n-1, seeded by today's date and the station's number.
func _shuffled(n: int, station_index: int) -> Array[int]:
	var order: Array[int] = []
	for i in n:
		order.append(i)
	var rng := RandomNumberGenerator.new()
	var day := Time.get_date_dict_from_system()
	rng.seed = (int(day["year"]) * 10000 + int(day["month"]) * 100 + int(day["day"])) * 31 + station_index * 7919
	for i in range(n - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[j]
		order[j] = swap
	return order


## The tuned station's order of tracks (indices into its tracks), empty when Off. Loop MW-5:
## only the unlocked ones.
func playlist() -> Array[int]:
	var out: Array[int] = []
	if station >= 0:
		for i: int in _orders[station]:
			if is_unlocked(station, i):
				out.append(i)
	return out


## The track on the air now ({} when Off or the station has none). Loop MW-5: never a locked one.
func current_track() -> Dictionary:
	if station < 0:
		return {}
	var order: Array = _orders[station]
	if order.is_empty() or not is_unlocked(station, order[_pos[station]]):
		return {}
	return stations[station]["tracks"][order[_pos[station]]]


# --- tuning and playing ---------------------------------------------------------------

## Tunes to a station (-1 = off). `quiet` skips the static and the ticker.
func tune(index: int, quiet := false) -> void:
	station = index if index >= 0 and index < stations.size() else -1
	_stop_jingle()
	_settle()
	_play_current(true)
	from_top = false
	if not quiet and _static.stream != null and not _silent:
		_static.play()
	var info: Dictionary = stations[station] if station >= 0 else {}
	if log_on:
		_log("tune %s" % (("%s %s%s, %s" % [info["freq"], info["name"], _air_note(), _track_note()]) if station >= 0 else "off"))
	station_changed.emit(station, info)
	if not quiet:
		if station >= 0:
			ticker.emit(caption(), info["colour"], caption_sub())
		else:
			ticker.emit("RADIO OFF", Color("#c9c4d8"), "")
	if station >= 0 and not current_track().is_empty():
		track_changed.emit(info, current_track(), false)


## Starts the current track of the tuned station (or stops the player when Off). A single
## track is a loop and joins in the middle, like switching a real radio on; a playlist
## track starts at its beginning and plays to its end.
func _play_current(join_middle: bool) -> void:
	var track := current_track()
	if station < 0 or track.is_empty():
		_player.stop()
		_player.stream = null
		return
	var stream := _stream_of(track)
	var single: bool = unlocked_count(station) == 1
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = single
	_player.stream = stream
	_track_t = 0.0
	_apply_level()
	if _silent or stream == null:
		return
	var from := 0.0
	if single and join_middle and not from_top:
		from = fmod(Time.get_ticks_msec() * 0.001 * 7.3, maxf(stream.get_length() - 1.0, 1.0))
	_player.play(from)


func _stream_of(track: Dictionary) -> AudioStream:
	var file: String = track["file"]
	if not _streams.has(file):
		_streams[file] = load(file)
	return _streams[file]


## The track ran out (never emitted for a looping single track): the next one starts.
func _on_finished() -> void:
	if station >= 0:
		_advance(true)


## Skips to the next track of the tuned station (a single track starts over). A natural end
## is `natural`; the caption goes up and track_changed fires for the host.
func next_track() -> void:
	if station >= 0:
		_advance(false)


func _advance(natural: bool) -> void:
	var order: Array = _orders[station]
	if order.is_empty():
		return
	# Loop MW-5: the next unlocked track (a locked one never plays).
	for k in order.size():
		_pos[station] = (_pos[station] + 1) % order.size()
		if is_unlocked(station, order[_pos[station]]):
			break
	_stop_jingle()
	if natural and _jingle_due():
		_player.stop()
		_play_jingle()
	else:
		_play_current(false)
	var info: Dictionary = stations[station]
	if log_on:
		_log("%s %s" % ["next" if natural else "skip", _track_note()])
	ticker.emit(caption(), info["colour"], caption_sub())
	track_changed.emit(info, current_track(), natural)


## True when this natural track end is a jingle's turn: the station has jingles, a real audio
## device is there, and JINGLE_EVERY songs have played since the last one.
func _jingle_due() -> bool:
	_since_jingle += 1
	var files: Array = stations[station].get("jingles", [])
	return not files.is_empty() and not _silent and _since_jingle >= JINGLE_EVERY


func _play_jingle() -> void:
	var files: Array = stations[station]["jingles"]
	# Not the same clip twice in a row.
	var k := randi() % files.size()
	if files.size() > 1 and k == _last_jingle:
		k = (k + 1) % files.size()
	_last_jingle = k
	_since_jingle = 0
	_jingle.stream = load(files[k])
	_jingle.volume_db = VOLUME_DB + duck_db + bed_db + JINGLE_DB
	jingle_playing = true
	_jingle.play()
	if log_on:
		_log("jingle %s" % files[k])


func _on_jingle_finished() -> void:
	if not jingle_playing:
		return
	jingle_playing = false
	if station >= 0:
		_play_current(false)


func _stop_jingle() -> void:
	jingle_playing = false
	if _jingle != null:
		_jingle.stop()


## "87,3 KEBAB FM  ·  Title (Artist)": the tuned station and the track on the air.
func caption() -> String:
	if station < 0:
		return ""
	var info: Dictionary = stations[station]
	var text := "%s %s" % [info["freq"], info["name"]]
	var track := current_track()
	if track.is_empty():
		return text
	if is_rerun():
		text += "  ·  " + Lang.pick("powtórka, Kuba wraca o 22:00", "rerun, Kuba is back at 22:00")  # loop MW-5: PÓŁNOC FM by day
	text += "  ·  " + String(track["title"])
	if String(track["artist"]) != "":
		text += " (%s)" % track["artist"]
	return text


## Puts the current station on the ticker (when the game starts).
func now_playing() -> void:
	if station >= 0:
		ticker.emit(caption(), stations[station]["colour"], caption_sub())


## The next station, after the last one Off, then the first again. Loop MW-5: the player's
## choice (R, RADIO): the radio stops following the clock for this session.
## Beta radio: only the stations in the lineup (a station tuned from outside it, by a flag, goes
## to the lineup's first).
func next() -> void:
	picked = true
	var k := lineup.find(station)
	if station < 0:
		tune(lineup[0] if not lineup.is_empty() else -1)
	elif k < 0:
		tune(lineup[0])
	else:
		tune(lineup[k + 1] if k + 1 < lineup.size() else -1)


## Beta radio: the tuned station has more than one track to skip to (the HUD's DALEJ button).
func can_skip() -> bool:
	return station >= 0 and unlocked_count(station) > 1


## The short name for the HUD button.
func label() -> String:
	return stations[station]["name"] if station >= 0 else "OFF"


## Puts a line on the ticker in the current station's colour, with an optional
## English subtitle: the radio host between the tracks (dialogue.gd).
func announce(text: String, subtitle := "") -> void:
	var info: Dictionary = stations[station] if station >= 0 else {}
	if log_on:
		var gap := "first" if _last_host_s < 0.0 else "+%.1f s" % (_play_s - _last_host_s)
		_last_host_s = _play_s
		_log("host (%s, %s): %s" % [gap, info.get("name", "off"), text])
	var head := "%s %s:  " % [info["freq"], info["name"]] if station >= 0 else ""
	ticker.emit(head + Lang.pick(text, subtitle), info["colour"] if station >= 0 else Color("#c9c4d8"), "")


# --- loop MW-5: PÓŁNOC FM, the clock and the locked tracks --------------------------------

func _process(dt: float) -> void:
	_play_s += dt
	_air_t += dt
	if _silent and station >= 0 and unlocked_count(station) > 1:
		_track_t += dt
		var t := current_track()
		if not t.is_empty() and _track_t >= float(t["seconds"]):
			_on_finished()
	if _moment_t > 0.0:
		_moment_t -= dt
		if _moment_t <= 0.0:
			_apply_level()
	if _air_t >= 1.0:
		_air_t = 0.0
		check_air()


## On air at `look` (a TimeOfDay name) and `hour` (0..24 by the game clock)? Always in the
## Night and Dawn looks; otherwise from 22:00 to 06:00.
static func on_air_at(look: String, hour: float) -> bool:
	if look in AIR_LOOKS:
		return true
	return hour >= AIR_FROM or hour < AIR_TO


## PÓŁNOC FM's state by the game clock now (always on air without a clock: the checks).
func on_air() -> bool:
	if not clock.is_valid():
		return true
	var c: Array = clock.call()
	return on_air_at(String(c[0]), float(c[1]))


## Rereads the clock (once a second, and at once with `force`): the level follows (reruns at
## 70 %), and while the player hasn't picked a station the radio goes to PÓŁNOC FM on air and
## back to KEBAB FM off air (`force`: quietly, the game's start).
func check_air(force := false) -> void:
	var a := on_air()
	var changed := a != _air
	if not changed and not force:
		return
	_air = a
	_apply_level()
	if changed:
		if log_on:
			_log("PÓŁNOC FM %s" % ("on air" if a else "reruns (powtórki, 70 %, no host)"))
		air_changed.emit(a)
	if not picked:
		var want := polnoc_index() if a else station_index(DAY_DEFAULT)
		if not lineup.has(want):
			want = station_index(DAY_DEFAULT)  # beta radio: PÓŁNOC FM out of the lineup
		if want >= 0 and want != station:
			tune(want, force)
			return
	if changed and station >= 0 and station == polnoc_index():
		now_playing()


## The tuned station is PÓŁNOC FM off air: its reruns.
func is_rerun() -> bool:
	return station >= 0 and station == polnoc_index() and not _air


## The ticker's English line under the caption (reruns only).
func caption_sub() -> String:
	return ""  # one language: the rerun note is in the caption itself


## Which group of dialogue.json the host reads on the tuned station: "radio_polnoc" on PÓŁNOC
## FM on air, "" (silent) on its reruns or Off, "radio_host" elsewhere.
func host_group() -> String:
	if station < 0:
		return ""
	if station == polnoc_index():
		return "radio_polnoc" if _air else ""
	return "radio_host"


## A station by its id ("polnoc_fm"), its id without "_fm" ("polnoc"), its name (any case, "PÓŁNOC
## FM") or its number from 1; -1 if none.
func station_index(key: String) -> int:
	var k := key.strip_edges().to_lower()
	for i in stations.size():
		var id := String(stations[i]["id"])
		if k == id or k == id.trim_suffix("_fm") or k == String(stations[i]["name"]).to_lower() or k == str(i + 1):
			return i
	return -1


func polnoc_index() -> int:
	for i in stations.size():
		if stations[i]["id"] == POLNOC:
			return i
	return -1


## Track `ti` (an index into the station's tracks) may play: the station has no locks, it is
## one of the free ones, --unlock=all, or the save has its number.
func is_unlocked(si: int, ti: int) -> bool:
	var free := int(stations[si].get("free", -1))
	if free < 0 or unlock_all or ti < free:
		return true
	return wallet != null and wallet.tracks.has(ti + 1)


func unlocked_count(si: int) -> int:
	var n := 0
	for i in stations[si]["tracks"].size():
		n += int(is_unlocked(si, i))
	return n


## The lowest locked track number on PÓŁNOC FM, 0 if every one is open.
func next_locked() -> int:
	var si := polnoc_index()
	if si < 0:
		return 0
	for i in stations[si]["tracks"].size():
		if not is_unlocked(si, i):
			return i + 1
	return 0


## Opens PÓŁNOC FM's track `n` (1 = the first): saved, logged, track_unlocked (main.gd's toast).
## For the eggs (E14: track 5, E31: track 2) and --unlock=N. False if it was open already.
func unlock_track(n: int, why := "egg") -> bool:
	var si := polnoc_index()
	if si < 0 or wallet == null or n < 1 or n > stations[si]["tracks"].size() or is_unlocked(si, n - 1):
		return false
	wallet.tracks[n] = _today()
	wallet.save()
	var track: Dictionary = stations[si]["tracks"][n - 1]
	if log_on:
		_log("unlock track %d %s (%s)" % [n, track["title"], why])
	track_unlocked.emit(n, track, why)
	return true


## Each notebook chapter finished since the last call opens the next locked track, in order
## (wallet `track_chapters` counts the chapters already turned into tracks, so a save from
## before this loop catches up once). Chapters past the last track open nothing (yet: the horn
## tune and the gold cover are later loops'). Returns the numbers opened.
func sync_chapters() -> Array[int]:
	var out: Array[int] = []
	if wallet == null or polnoc_index() < 0:
		return out
	while int(wallet.track_chapters) < wallet.chapters_done.size():
		wallet.track_chapters += 1
		var n := next_locked()
		if n > 0 and unlock_track(n, "chapter %d" % wallet.track_chapters):
			out.append(n)
	wallet.save()
	return out


## The toast for a new track: [Polish, English], each ≤ 70 characters.
static func unlock_toast(title: String) -> Array:
	return ["Kuba ma nową płytę: „%s”" % title, "PÓŁNOC FM 86.0 · Kuba has a new record: %s" % title]


## The 02:00 beat on Plac Trzech Krzyży: the radio (unless it is Off) goes to PÓŁNOC FM, the
## music drops under the host for `seconds` and he speaks at once (dialogue.gd). False when Off.
func host_moment(seconds := 10.0) -> bool:
	if station < 0 or polnoc_index() < 0:
		return false
	if station != polnoc_index():
		tune(polnoc_index(), true)
	_moment_t = seconds
	_apply_level()
	if log_on:
		_log("host moment: the music down %.0f dB for %.0f s" % [MOMENT_DB, seconds])
	host_wanted.emit()
	return true


## A voice on air (LEKTI's break-in, rave.gd): the music drops MOMENT_DB under it for `seconds`,
## on whatever station is tuned; the host is not asked to speak.
func voice_moment(seconds: float) -> void:
	_moment_t = maxf(_moment_t, seconds)
	_apply_level()
	if log_on:
		_log("voice moment: the music down %.0f dB for %.1f s" % [MOMENT_DB, seconds])


## The current position moved onto an unlocked track, if the station has any.
func _settle() -> void:
	if station < 0:
		return
	var order: Array = _orders[station]
	for k in order.size():
		if is_unlocked(station, order[_pos[station]]):
			return
		_pos[station] = (_pos[station] + 1) % order.size()


## The player's level: the station's, the pull-over's duck, the reruns' 70 %, the host's moment.
func _apply_level() -> void:
	if _player == null:
		return
	var db := VOLUME_DB + duck_db + bed_db
	if is_rerun():
		db += RERUN_DB
	if _moment_t > 0.0:
		db += MOMENT_DB
	_player.volume_db = db
	if _jingle != null:
		_jingle.volume_db = VOLUME_DB + duck_db + bed_db + JINGLE_DB


## The level the player is set to (the checks read it; headless never plays).
func level_db() -> float:
	return _player.volume_db if _player != null else VOLUME_DB


## A track's number on the tuned station (1 = the first in radio.json), 0 if none.
func track_number() -> int:
	if station < 0 or current_track().is_empty():
		return 0
	return int(_orders[station][_pos[station]]) + 1


func _air_note() -> String:
	if station != polnoc_index() or station < 0 or not clock.is_valid():
		return ""
	return " (on air)" if _air else " (reruns, 70 %, no host)"


func _track_note() -> String:
	var t := current_track()
	if t.is_empty():
		return "no track"
	return "track %d %s (%.0f s), %d/%d unlocked" % [track_number(), t["title"], float(t["seconds"]),
			unlocked_count(station), stations[station]["tracks"].size()]


func _log(text: String) -> void:
	print("radio: %7.1f s  %s" % [_play_s, text])


static func _today() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])
