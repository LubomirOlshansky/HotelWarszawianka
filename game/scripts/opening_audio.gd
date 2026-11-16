extends Node
## The opening's sound (F, 2026-11-03): the announcer's line ("Opening_line_a") plays once with the
## opening flyover, over the radio turned right down as a quiet music bed; when the flyover is over
## and the line has finished, the radio swells to its normal level. A tap that skips the flyover
## cuts the line short and brings the radio up at once. Without the file nothing plays and the
## radio is left alone.
##
## Levels: the line at LINE_DB on the Voice bus; the radio 20 dB under its normal level (about a
## tenth of the loudness: heard, not listened to) and back over 3 s: the mixer's "opening" row
## (sfx.gd DUCKS).
##
## The morning (F, 2026-11-16): the flight is as long as the line and the city wakes up on the way
## (time_of_day.gd `wake`). The city's beds follow the daylight by themselves (sfx.gd: the night bed
## into the day bed, birds by day); CUES add a few one-shots at the line's pauses so each stage is
## heard as well as seen. A skip drops the ones still to come.

const CameraShots := preload("res://scripts/camera_shots.gd")
const Sfx := preload("res://scripts/sfx.gd")
const LINE_FILE := "res://audio/opening/opening_line.ogg"
const LINE_DB := 0.0
## [seconds after the start, the one-shot, gain dB, bus]: a far dog in the night, the church bell at
## first light (the host's weather line), birds, the tram's bell at sunrise (the Marszałkowska line),
## birds again by day.
const CUES := [
	[0.8, "dog_far", -4.0, &"Ambience"],
	[3.0, "church_bell", 0.0, &"Ambience"],
	[4.8, "birds_a", -2.0, &"Ambience"],
	[7.4, "tram_bell", -6.0, &"SFX"],
	[9.4, "birds_b", 0.0, &"Ambience"],
]

var _t0 := 0.0
var _voice: AudioStreamPlayer
var _flight_over := false
var _line_over := true
## The sound engine (sfx.gd), for CUES; none in a check.
var sounds: Node
var _cue := 0


## Starts the line and the dip.
func start(_radio: Node) -> void:
	_t0 = Time.get_ticks_msec() * 0.001
	_flight_over = false
	_line_over = true
	_cue = 0
	Sfx.duck("opening")
	var silent := DisplayServer.get_name() == "headless"
	if silent or not ResourceLoader.exists(LINE_FILE):
		_line_over = true
		return
	_voice = AudioStreamPlayer.new()
	_voice.stream = load(LINE_FILE)
	_voice.volume_db = LINE_DB
	_voice.bus = &"Voice"
	add_child(_voice)
	_voice.finished.connect(_on_line_finished, CONNECT_ONE_SHOT)
	_line_over = false
	_voice.play()


func _process(_dt: float) -> void:
	if _flight_over or sounds == null or _cue >= CUES.size():
		return
	var t := Time.get_ticks_msec() * 0.001 - _t0
	while _cue < CUES.size() and t >= float(CUES[_cue][0]):
		var c: Array = CUES[_cue]
		sounds.play(c[1], c[2], 1.0, c[3])
		_cue += 1


## The flyover ended (done or skipped by a tap).
func flight_ended() -> void:
	_flight_over = true
	# A flight that ends well before its length was skipped by a tap (the signal does not say).
	var skipped := (Time.get_ticks_msec() * 0.001 - _t0) < CameraShots.OPEN_TIME - 0.8
	if skipped and _voice != null and _voice.playing:
		var t := create_tween()
		t.tween_property(_voice, "volume_db", -40.0, 0.3)
		t.tween_callback(_voice.stop)
		t.tween_callback(_on_line_finished)
		return
	_maybe_swell()


func _on_line_finished() -> void:
	_line_over = true
	_maybe_swell()


func _maybe_swell() -> void:
	if _flight_over and _line_over:
		Sfx.release("opening")


## Freed mid-line (a new game, the quit): the radio is not left turned down.
func _exit_tree() -> void:
	Sfx.release("opening")
