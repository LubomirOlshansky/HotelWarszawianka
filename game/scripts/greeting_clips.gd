extends Node
## The host's spoken greeting on every launch after the first (F, 2026-11-05): "hello", the weather
## and "bye" for the hour and the weather, three ElevenLabs clips one after another over the
## radio turned down (the same choice the ticker's greeting text makes, Dialogue.greeting_parts).
## The first start and a new game do NOT use this: they have the opening line (opening_audio.gd).
## Only KEBAB FM (her voice) says it; a missing file ends the greeting early and never errors.
## Files: res://audio/voice/radio/{hello_<part>,weather_<sky>,bye_<part>}.ogg

const DIR := "res://audio/voice/radio/"
const CLIP_DB := -2.0
const BED_DB := -16.0
const DIP_S := 0.5
const SWELL_S := 2.5

var _radio: Node
var _player: AudioStreamPlayer
var _queue: Array[String] = []
var _tween: Tween


## The clip files for a greeting (`parts` is Dialogue.greeting_parts), existing ones only.
static func clips_for(parts: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for name: String in ["hello_" + String(parts["part"]), "weather_" + String(parts["sky"]), "bye_" + String(parts["part"])]:
		var f := DIR + name + ".ogg"
		if ResourceLoader.exists(f):
			out.append(f)
	return out


## Starts the greeting; false when there is nothing to play (headless, no files).
func start(radio: Node, parts: Dictionary) -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	_queue = clips_for(parts)
	if _queue.is_empty():
		return false
	_radio = radio
	_player = AudioStreamPlayer.new()
	_player.volume_db = CLIP_DB
	_player.bus = &"SFX"
	add_child(_player)
	_player.finished.connect(_next)
	_tween = create_tween()
	_tween.tween_property(_radio, "bed_db", BED_DB, DIP_S)
	_next()
	return true


func _next() -> void:
	if _queue.is_empty():
		_end()
		return
	_player.stream = load(_queue.pop_front())
	_player.play()


func _end() -> void:
	if _radio == null or not is_instance_valid(_radio):
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_radio, "bed_db", 0.0, SWELL_S)
	_tween.tween_callback(queue_free)
