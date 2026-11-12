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

const CameraShots := preload("res://scripts/camera_shots.gd")
const Sfx := preload("res://scripts/sfx.gd")
const LINE_FILE := "res://audio/opening/opening_line.ogg"
const LINE_DB := 0.0

var _t0 := 0.0
var _voice: AudioStreamPlayer
var _flight_over := false
var _line_over := true


## Starts the line and the dip.
func start(_radio: Node) -> void:
	_t0 = Time.get_ticks_msec() * 0.001
	_flight_over = false
	_line_over = true
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
