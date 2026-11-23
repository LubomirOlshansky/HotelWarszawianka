## In-game feedback (F 2026-11-21): Settings → the gold button at the top of the first tab opens this card; the player writes a
## message (and, if they like, an email to be answered at), and it is posted as JSON to the
## Formspree form "In-game feedback" of the Around Warsaw project, which mails it to the author.
## The payload carries the build, the device model, the language and where in the city the player
## was (`where`, from main.gd `_settings_state`), and nothing else: no name, no save, no ids.
## The form id is public by design (it only accepts posts); it lives here, the one place that
## knows it (the website's forms have their own, site/src/index.html).
## `payload` and `accepts` are pure (game/tools/check_feedback.gd); `send` needs the tree.
extends Control

const UiKit := preload("res://scripts/ui_kit.gd")
const Lang := preload("res://scripts/lang.gd")

signal closed

const WORDS := "res://data/feedback.json"
## Where the card posts: the site's own Worker (site/forms.js, D1 + email). The Formspree form
## "In-game feedback" (maeodgey) took the same JSON before the Worker was deployed (2026-11-21).
const OWN_URL := "https://aroundwarsaw.app/api/feedback"
const FORM_URL := OWN_URL
const MESSAGE_MIN := 3
const MESSAGE_MAX := 2000
const EMAIL_MAX := 200
## Seconds between two sends: a double tap or a loop of presses sends once.
const GAP := 20.0

## "where" (a district, the position and the vehicle), set by the settings panel before `open`.
var where := ""
var pt := 1.0
var safe := Rect2()

var _http: HTTPRequest
var _text: TextEdit
var _email: LineEdit
var _status: Label
var _send: Button
var _card: PanelContainer
var _lead: Label
var _note: Label
var _last_send_ms := -1000000
var _built := false


## The JSON body Formspree gets. `email` stays out when it is empty (Formspree then has no reply-to).
static func payload(message: String, email: String, where_: String, lang: String, build: String, device: String) -> Dictionary:
	var d := {
		"message": message.strip_edges().left(MESSAGE_MAX),
		"_subject": "Around Warsaw: in-game feedback",
		"source": "in-game",
		"build": build,
		"device": device,
		"where": where_,
		"language": lang,
	}
	var mail := email.strip_edges().left(EMAIL_MAX)
	if mail != "":
		d["email"] = mail
	return d


## Null when the message and email may be sent, else the reason as "short" (a key for `reason_words`).
static func accepts(message: String, email: String) -> String:
	if message.strip_edges().length() < MESSAGE_MIN:
		return "short"
	var mail := email.strip_edges()
	if mail != "" and (mail.length() > EMAIL_MAX or not _looks_like_email(mail)):
		return "email"
	return ""


static func _looks_like_email(s: String) -> bool:
	if s.contains(" "):
		return false
	var at := s.find("@")
	return at > 0 and s.rfind(".") > at + 1 and not s.ends_with(".")


## The card's words in the player's language (data/feedback.json: {key: {pl, en}}).
static func w(key: String) -> String:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORDS))
	var row: Variant = (d as Dictionary).get(key) if d is Dictionary else null
	if not row is Dictionary:
		push_warning("feedback.gd: no words for '%s'" % key)
		return ""
	return Lang.pick(str((row as Dictionary).get("pl", "")), str((row as Dictionary).get("en", "")))


static func reason_words(reason: String) -> String:
	match reason:
		"short":
			return w("short")
		"email":
			return w("email")
		"wait":
			return w("wait")
		"fail":
			return w("fail")
		"sending":
			return w("sending")
		"ok":
			return w("ok")
	return ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # the settings card pauses the tree; the post must go on


func _px(points: float) -> int:
	return UiKit.px(points, pt)


## Builds the card (once) and shows it over the settings panel.
func open() -> void:
	if not _built:
		_build()
	_text.text = ""
	_status.text = ""
	_send.disabled = false
	visible = true
	_layout()
	_text.grab_focus()


func close() -> void:
	_hide_keyboard()
	if _http != null:
		_http.cancel_request()
	visible = false
	closed.emit()


## Puts the on-screen keyboard away (F 2026-11-22: it covered the card and there was no way out).
func _hide_keyboard() -> void:
	if _text != null:
		_text.release_focus()
	if _email != null:
		_email.release_focus()
	DisplayServer.virtual_keyboard_hide()


## The keyboard's height in viewport units (0 on desktop and when it is down).
func _keyboard_height() -> float:
	var kb := float(DisplayServer.virtual_keyboard_get_height())
	if kb <= 0.0:
		return 0.0
	var win := maxf(float(DisplayServer.window_get_size().y), 1.0)
	return kb * get_viewport().get_visible_rect().size.y / win


func _process(_delta: float) -> void:
	if visible and _built:
		_layout()


## F 2026-11-22: the card sits in the room above the keyboard. With the keyboard up the long
## lead and the note go, the message box shrinks and the card is scaled to fit; the header
## (title, SEND, ✕) is always on screen, so the card can always be sent or left.
func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var area := safe if safe.has_area() else Rect2(Vector2.ZERO, vp)
	var kb := _keyboard_height()
	var compact := kb > 0.0
	if compact:
		var bottom := minf(area.end.y, vp.y - kb)
		area = Rect2(area.position, Vector2(area.size.x, maxf(bottom - area.position.y, 80.0)))
	_lead.visible = not compact
	_note.visible = not compact
	_status.visible = _status.text != ""
	_text.custom_minimum_size.y = (52.0 if compact else 130.0) * pt
	_card.scale = Vector2.ONE
	_card.reset_size()
	var need := _card.get_combined_minimum_size()
	var room := area.grow(-6.0 * pt).size
	var k := minf(1.0, minf(room.x / maxf(need.x, 1.0), room.y / maxf(need.y, 1.0)))
	_card.scale = Vector2(k, k)
	_card.size = need
	var pos := area.get_center() - need * k * 0.5
	if compact:
		pos.y = area.position.y + 6.0 * pt
	_card.position = pos


func _build() -> void:
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = UiKit.SCRIM
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	# A tap beside the card puts the keyboard away first, and closes the card when it is already down.
	shade.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			if _keyboard_height() > 0.0 or _text.has_focus() or _email.has_focus():
				_hide_keyboard()
			else:
				close())
	add_child(shade)
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UiKit.card(pt, 14.0))
	var width := 440.0 * pt
	if safe.has_area():
		width = minf(width, safe.size.x - 24.0 * pt)
	_card.custom_minimum_size.x = width
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", _px(8))
	_card.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", _px(8))
	col.add_child(head)
	var title := _label(w("title"), 20.0, UiKit.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	_send = Button.new()
	_send.name = "send"
	_send.text = w("send")
	_send.custom_minimum_size = Vector2(0.0, 40.0 * pt)
	UiKit.style_button(_send, UiKit.Kind.PRIMARY, pt)
	_send.pressed.connect(send)
	head.add_child(_send)
	var back := Button.new()
	back.name = "close"
	back.text = "✕"
	back.custom_minimum_size = Vector2(40.0 * pt, 40.0 * pt)
	UiKit.style_button(back, UiKit.Kind.SECONDARY, pt, 18.0)
	back.pressed.connect(close)
	head.add_child(back)

	_lead = _label(w("lead"), 13.0, UiKit.SUB)
	_lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_lead)

	_text = TextEdit.new()
	_text.placeholder_text = w("placeholder")
	_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_text.custom_minimum_size = Vector2(0.0, 130.0 * pt)
	_text.add_theme_font_size_override("font_size", _px(15.0))
	_text.text_changed.connect(func():
		if _text.text.length() > MESSAGE_MAX:
			_text.text = _text.text.left(MESSAGE_MAX))
	col.add_child(_text)

	_email = LineEdit.new()
	_email.placeholder_text = w("email_placeholder")
	_email.max_length = EMAIL_MAX
	_email.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
	_email.add_theme_font_size_override("font_size", _px(15.0))
	_email.text_submitted.connect(func(_t: String): _hide_keyboard())  # the return key puts the keyboard away
	col.add_child(_email)

	_note = _label(w("note"), 11.0, UiKit.FAINT)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_note)

	_status = _label("", 13.0, UiKit.GOLD)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)

	_http = HTTPRequest.new()
	_http.timeout = 15.0
	_http.process_mode = Node.PROCESS_MODE_ALWAYS
	_http.request_completed.connect(_on_done)
	add_child(_http)


func _label(s: String, points: float, colour: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", _px(points))
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Checks, then posts. The status line says what happened.
func send() -> void:
	var reason := accepts(_text.text, _email.text)
	if reason == "" and Time.get_ticks_msec() - _last_send_ms < int(GAP * 1000.0):
		reason = "wait"
	if reason != "":
		_status.text = reason_words(reason)
		return
	var body := JSON.stringify(payload(_text.text, _email.text, where, Lang.code, _build_name(), _device()))
	var err := _http.request(FORM_URL, PackedStringArray(["Content-Type: application/json", "Accept: application/json"]),
			HTTPClient.METHOD_POST, body)
	if err != OK:
		push_warning("feedback.gd: request failed to start (%d)" % err)
		_status.text = reason_words("fail")
		return
	_last_send_ms = Time.get_ticks_msec()
	_hide_keyboard()
	_send.disabled = true
	_status.text = reason_words("sending")


func _on_done(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_send.disabled = false
	if result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300:
		_status.text = reason_words("ok")
		_text.text = ""
	else:
		push_warning("feedback.gd: post failed (result %d, http %d)" % [result, code])
		_last_send_ms = -1000000  # a failed post may be tried again at once
		_status.text = reason_words("fail")


static func _build_name() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev"))


static func _device() -> String:
	return "%s · %s %s" % [OS.get_model_name(), OS.get_name(), OS.get_version()]
