extends RefCounted
## Stand-ins the checks share (tech-debt TD-11; started with the activity kit, whose checks use it:
## check_activity.gd, check_kino_tour.gd, check_dekalog_tour.gd, and the check of each activity that
## joins the kit): a HUD that remembers the card, the status line and the toasts, and sends a
## card's press to its owner as hud.gd does (tech-debt TD-16); a dialogue that remembers what was
## said; the bubbles over the car; a wallet; the rescue calls' switch; a flat map; a car that can
## be hit. A check that needs one of these takes it from here, so a new parameter on `hud.toast`
## is changed in one place.


class Hud extends CanvasLayer:
	signal card_pressed(index: int)
	signal abort_pressed
	## The card that is up: its title ("" when none), its text, how many buttons.
	var card := ""
	var body := ""
	var buttons := 0
	## Whether the card that is up has its buttons one under the other.
	var stacked := false
	## The status line's hint ("" when it is down), its count ("2/4"), its title and its colour.
	var status := ""
	var count := ""
	var status_title := ""
	var tint := Color.WHITE
	var toasts: Array[String] = []
	## Cards and calls shown so far, and presses that went to every listener (no owner).
	var shown := 0
	var broadcast := 0
	var _owner: Object = null

	func show_card(title: String, text: String, btn: PackedStringArray, _a: Color, _bottom := false, _te := "", _be := "", s := false) -> void:
		_up(title, text, btn.size())
		stacked = s

	func show_side_card(title: String, text: String, btn: PackedStringArray, _a: Color, _te := "", _be := "", s := false, _f := "") -> void:
		_up(title, text, btn.size())
		stacked = s

	func show_call(who: String, about: String, _a: Color, _be := "", _f := "", btn := PackedStringArray(["ODBIERZ|ANSWER", "ODRZUĆ|DECLINE"])) -> void:
		_up("📞 %s DZWONI" % who.to_upper(), about, btn.size())

	func _up(title: String, text: String, n: int) -> void:
		_owner = null
		card = title
		body = text
		buttons = n
		stacked = false
		shown += 1

	func hide_card() -> void:
		_owner = null
		card = ""
		body = ""
		buttons = 0

	func toast(a: String, _b := "") -> void:
		toasts.append(a)

	func show_status(t: String, c: String, _d: String, h: String, _p: float, a: Color, _badge := "", _i := {}, _he := "") -> void:
		status = h
		count = c
		status_title = t
		tint = a

	func hide_status() -> void:
		status = ""
		count = ""
		status_title = ""

	func ticker_out() -> void:
		pass

	# The card's owner, as in hud.gd.
	func own_card(o: Object) -> void:
		_owner = o

	func card_is(o: Object) -> bool:
		return _owner == o and card != ""

	func card_showing() -> bool:
		return card != ""

	## A tap on the card's button `i`: to the card's owner, else to every listener.
	func press(i: int) -> void:
		if _owner != null and is_instance_valid(_owner):
			_owner.card_pressed(i)
		else:
			broadcast += 1
			card_pressed.emit(i)


class Dialogue extends Node:
	## "group:tag" of every line asked for.
	var said: Array[String] = []
	## dialogue.gd's bubbles (a script that speaks its own lines over the car uses them).
	var bubbles: Control

	func say(_anchor: Variant, _who: String, group: String, tag := "", _s := 4.0, _c := Color.WHITE, _h := 2.6, _p := false) -> Array:
		said.append(group + ":" + tag)
		return []

	## dialogue.gd's ambient chatter (a bystander's line): remembered the same way.
	func say_ambient(anchor: Variant, who: String, group: String, tag := "", s := 4.0, c := Color.WHITE, h := 2.6, p := false) -> Array:
		return say(anchor, who, group, tag, s, c, h, p)


## bubbles.gd: the lines said over the car (Polish), and whether the chatter budget lets one out.
class Bubbles extends Control:
	var said: Array[String] = []
	var ok := true

	func say(_anchor: Variant, _who: String, pl: String, _en: String, _s := 4.0, _c := Color.WHITE, _h := 2.6) -> bool:
		if ok:
			said.append(pl)
		return ok


## missions.gd's switch for the rescue calls.
class Calls extends Node:
	var paused := false


class Wallet extends Node:
	var money := 0
	var respect := 0
	var kinds: Array[String] = []

	func pay(amount: int, gain := 0, kind := "") -> void:
		money += amount
		respect += gain
		kinds.append(kind)


class FlatMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0


class Car extends Node3D:
	signal bumped(collider: Object, speed: float)
