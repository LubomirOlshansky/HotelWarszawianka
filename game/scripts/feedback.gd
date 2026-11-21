## In-game feedback (F 2026-11-21): Settings → Dźwięk → NAPISZ DO AUTORA opens this card; the player writes a
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
## Where the card posts. Today the Formspree form "In-game feedback"; the site's own Worker
## (site/forms.js, D1 + email) takes the same JSON at OWN_URL once it is deployed: change FORM_URL to it.
const OWN_URL := "https://aroundwarsaw.app/api/feedback"
const FORM_URL := "https://formspree.io/f/maeodgey"
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
	_text.grab_focus()


func close() -> void:
	if _http != null:
		_http.cancel_request()
	visible = false
	closed.emit()


func _build() -> void:
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = UiKit.SCRIM
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.card(pt, 14.0))
	var width := 440.0 * pt
	if safe.has_area():
		width = minf(width, safe.size.x - 24.0 * pt)
	card.custom_minimum_size.x = width
	center.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", _px(8))
	card.add_child(col)

	col.add_child(_label(w("title"), 20.0, UiKit.GOLD))
	var lead := _label(w("lead"), 13.0, UiKit.SUB)
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(lead)

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
	col.add_child(_email)

	var note := _label(w("note"), 11.0, UiKit.FAINT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)

	_status = _label("", 13.0, UiKit.GOLD)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _px(8))
	col.add_child(row)
	var back := Button.new()
	back.text = w("close")
	UiKit.style_button(back, UiKit.Kind.SECONDARY, pt)
	back.pressed.connect(close)
	row.add_child(back)
	_send = Button.new()
	_send.text = w("send")
	_send.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.style_button(_send, UiKit.Kind.PRIMARY, pt)
	_send.pressed.connect(send)
	row.add_child(_send)

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
