extends RefCounted
## Mac step 1 (F 2026-11-20, "optimize to the mac"): the iPhone app already runs on Apple silicon
## Macs from the App Store ("Designed for iPhone"); this tells the game it is on one, so it can
## play like a computer game there instead of a phone stretched over a laptop screen:
## - tiers.gd: Auto picks Ultra (High on a base M1 / M2), the 3D image at 2 screen pixels a pixel
##   (a 14" MacBook's 3024x1964 window draws 1512x982, not the phone's 4x-upscaled 491 lines)
##   with MSAA 4x (`mac_scale`, the `mac` rules in own_scale / image_scale / extra);
## - screen_points.gd: the HUD in points of a screen about MAC_POINTS_TALL tall, so a laptop seen
##   from 60 cm reads like the phone from 30 cm (the window's own 982 pt left it half the size);
## - hud.gd `set_keys_mode` (any mobile build, so an iPad or phone keyboard too): a driving or
##   command key hides the touch pads and the hints speak of the keys; a touch or click brings them back.
## Native macOS (the editor, the shots, the benches) is not this: there the Mac rules stay off
## unless --mac asks for them (--mac=off forces them off on a Mac). A native macOS build, a
## desktop HUD and the store work are step 2 (docs/BACKLOG.md).
##
## Detection, unproved until a Mac run reads the `mac:` log line: the app reports OS "iOS"; its
## model id (`OS.get_model_name()`, sysctl hw.machine) is no iPhone / iPad / iPod id ("arm64" or
## a Mac's "MacBookPro18,3"), or its Metal device is a Mac chip ("Apple M4 Pro"; an iPhone's
## reads "Apple A17 Pro GPU"). An M-chip iPad keeps its iPad id, so it stays an iPad.

## The HUD's points on a Mac: the window's height is taken as this many points at least.
const MAC_POINTS_TALL := 600.0

## --mac (1) / --mac=off (0) / -1: detect (dev_flags.gd).
static var forced := -1
static var _detected := -1


## Whether an app with this OS name, model id and GPU name is the iPhone app on a Mac.
static func detect(os_name: String, model: String, adapter: String) -> bool:
	if os_name != "iOS":
		return false
	for phone: String in ["iPhone", "iPad", "iPod"]:
		if model.begins_with(phone):
			return false
	return adapter.begins_with("Apple M") or model.begins_with("Mac") or model in ["arm64", "arm64e", "x86_64"]


## This run is on a Mac (the iPhone app there, or --mac). Read once and kept: the model and the GPU
## don't change while the game runs.
static func active() -> bool:
	if forced >= 0:
		return forced == 1
	if _detected < 0:
		_detected = int(detect(OS.get_name(), OS.get_model_name(), RenderingServer.get_video_adapter_name()))
	return _detected == 1


## The log line every launch prints (main.gd), so a Mac run shows what the detection saw.
static func describe() -> String:
	return "mac: %s · OS %s · model %s · GPU %s%s" % ["on" if active() else "off", OS.get_name(),
			OS.get_model_name(), RenderingServer.get_video_adapter_name(),
			" (forced by --mac)" if forced >= 0 else ""]


## Whether a key on the keyboard hides the touch pads: on a phone, tablet or Mac build (a keyboard
## there is a choice the player made), and on the computer only with --mac (the dev runs keep
## their pads, or --no-touch).
static func keys_hide_pads() -> bool:
	return OS.has_feature("mobile") or active()


## A key that plays the game: a letter (WASD and the commands, M K H Q E ...), an arrow or the
## space bar, pressed, not a repeat. Not the system keys a phone sends (Android's back, volume)
## nor Escape, Tab or a modifier on its own.
static func is_play_key(event: InputEvent) -> bool:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return false
	var code := k.physical_keycode
	return (code >= KEY_A and code <= KEY_Z) or code in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SPACE]


## A press that brings the touch pads back: a finger, or a click (not the wheel).
static func is_touch(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.is_pressed()
	var b := event as InputEventMouseButton
	return b != null and b.pressed and b.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
