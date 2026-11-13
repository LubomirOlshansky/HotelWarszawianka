extends RefCounted
## Stand-ins the checks share (tech-debt TD-11; started with the activity kit, whose checks use it:
## check_activity.gd, check_kino_tour.gd, check_dekalog_tour.gd, and the check of each activity that
## joins the kit): a HUD that remembers the card, the status line and the toasts, and sends a
## card's press to its owner as hud.gd does (tech-debt TD-16), with the context button, the
## banner, the notes, the quest's dots and the quiet screen (the street meet uses them), the card's
## colour, the small toasts and the minimap's dots (the boat race uses them), whether the card
## sits at the bottom of the screen, the words on its buttons, both languages of a card, a toast
## and a hint, how long each bubble stays, the minimap's job pins and the challenge taken down (the round-up uses them), the
## status line's small pictures (`icons`: the deliveries use them), the buttons' words changed on a card that is up
## (`set_card_button`, with the English kept apart: `button_words_en`), the courier's challenge (`show_challenge`), the
## minimap's route with its owner (`clear_minimap_route`), a wallet's `best_time` and a dialogue's `notes` and `line_notes`
## (added with the check of the deliveries, check_job_play.gd), whether
## a card is up (`cards_up`, as `card_showing`) and the message director's word on a call (`calls_ok`,
## `call_ok()`; the trend job's check uses them), how often the news ticker went out (`tickers`); a
## dialogue that remembers what was said, where and how, and the lines asked for (and whether each
## was the preferred one, `line_prefers`; `no_lines` makes the bag empty); the bubbles over the
## car; a wallet; the rescue calls' switch and how often the line was closed; a flat map; a car
## that can be hit and has a speed. A check that needs one of these takes it from here, so a new parameter on `hud.toast`
## is changed in one place.
##
## The rules (check_fakes.gd holds both, step `fakes`): a function here that the game's own script has too takes the
## same arguments as the game's (so a new parameter on `hud.toast` fails one step with the function's name, not the
## checks that reach it); and no check writes its own stand-in for the HUD, the dialogue or the bubbles: it takes
## the one here, and extends it for what only that check needs.
##
## With the checks that carried private copies (2026-11-13): every note's title and text (`note_titles`,
## `note_texts`), every card's title (`cards`), the English of the small toasts (`ambient_en`), how often the
## notebook's mark was asked for (`notebook_changes`); the dialogue's `say` as dialogue.gd has it (the line's
## class and key: `kinds`, `keys`; `say_reaction`), what `say` answers (`say_words`), each line's group and tag
## (`groups`, `tags`), `count` and `forget`; the bubbles' `say` as bubbles.gd has it, with `say_ambient`, `say_reaction`,
## `allows` and `muted`.

const Chatter := preload("res://scripts/chatter.gd")


class Hud extends CanvasLayer:
	signal card_pressed(index: int)
	signal abort_pressed
	signal challenge_pressed
	## The context button's tap, with whose button it was (a check emits it).
	signal context_pressed(who: String)
	## The card that is up: its title ("" when none), its text, how many buttons, and the words on
	## them in order.
	var card := ""
	var body := ""
	var buttons := 0
	var button_words := PackedStringArray()
	## Whether the card that is up has its buttons one under the other, its colour, and whether it
	## sits at the bottom of the screen (hud.gd `show_card`'s `bottom`).
	var stacked := false
	var accent := Color.WHITE
	var low := false
	## Whether the card that is up sits beside the road (hud.gd `show_side_card`; a call does too),
	## and the face named for it or for the call ("" when none was).
	var side := false
	var face := ""
	## The English of the card that is up (hud.gd shows one language; a check reads both).
	var card_en := ""
	var body_en := ""
	## The status line's hint ("" when it is down), its count ("2/4"), its title, its colour and the
	## badge beside the title ("" when none); its distance ("140 m"), how far its bar is filled, and
	## how many status lines were drawn so far (a line drawn again counts again).
	var status := ""
	var count := ""
	var distance := ""
	var progress := 0.0
	var lines := 0
	var status_title := ""
	var tint := Color.WHITE
	var badge := ""
	## The status line's hint in English.
	var hint_en := ""
	var toasts: Array[String] = []
	## The English of each toast, in step with `toasts`.
	var toasts_en: Array[String] = []
	## The minimap's job pins (hud.gd `set_minimap_pois`): how many, their places, colours and
	## shapes, and how often they were set; how often the pill and the courier's challenge were
	## taken down.
	var pois := 0
	var poi_points := PackedVector2Array()
	var poi_colours := PackedColorArray()
	var poi_shapes := PackedInt32Array()
	var pois_set := 0
	var pills_hidden := 0
	var challenges_hidden := 0
	## The small toasts that wait their turn (hud.gd `ambient_toast`), and how many dots the minimap
	## has for the others in a race.
	var ambient: Array[String] = []
	var mini_dots := 0
	## The context button: whose it is ("" when down) and its word; `pill_free`: what
	## `pill_free_for` answers (nobody else holds the button).
	var pill := ""
	var pill_word := ""
	## The button's word in English.
	var pill_en := ""
	## How often the ticker had gone out when the last side card was put up (the order of the two).
	var tickers_at_card := 0
	var pill_free := true
	## The banner that is up ("" when none) and every banner shown so far.
	var banner := ""
	var banners: Array[String] = []
	## Every note shown ("title: text"), how many quest dots the minimap has, the quiet screen.
	var notes: Array[String] = []
	## Each note's title and its text apart, in step with `notes`.
	var note_titles: Array[String] = []
	var note_texts: Array[String] = []
	var dots := 0
	var hush := false
	## Cards and calls shown so far, and presses that went to every listener (no owner).
	var shown := 0
	## The title of every card and call shown so far, in order (`shown` of them).
	var cards: Array[String] = []
	var broadcast := 0
	var _owner: Object = null

	func show_card(title: String, text: String, btn: PackedStringArray, a: Color, bottom := false, te := "", be := "", s := false) -> void:
		_up(title, text, btn)
		stacked = s
		accent = a
		low = bottom
		card_en = te
		body_en = be

	func show_side_card(title: String, text: String, btn: PackedStringArray, a: Color, te := "", be := "", s := false, f := "") -> void:
		_up(title, text, btn)
		tickers_at_card = tickers
		stacked = s
		accent = a
		side = true
		face = f
		card_en = te
		body_en = be

	func show_call(who: String, about: String, a: Color, be := "", f := "", btn := PackedStringArray(["ODBIERZ|ANSWER", "ODRZUĆ|DECLINE"])) -> void:
		_up("📞 %s DZWONI" % who.to_upper(), about, btn)
		accent = a
		side = true
		face = f
		body_en = be

	func _up(title: String, text: String, btn: PackedStringArray) -> void:
		_owner = null
		card = title
		body = text
		buttons = btn.size()
		button_words = btn
		button_words_en = PackedStringArray()
		for w in btn:
			var parts := String(w).split("|")
			button_words_en.append(parts[parts.size() - 1])
		stacked = false
		low = false
		side = false
		face = ""
		card_en = ""
		body_en = ""
		shown += 1
		cards.append(title)

	func hide_card() -> void:
		_owner = null
		card = ""
		body = ""
		buttons = 0
		button_words = PackedStringArray()

	func toast(a: String, b := "", _priority := 0) -> void:
		toasts.append(a)
		toasts_en.append(b)

	## The English of each small toast, in step with `ambient`.
	var ambient_en: Array[String] = []

	func ambient_toast(a: String, b := "") -> void:
		ambient.append(a)
		ambient_en.append(b)

	func set_minimap_dots(points: PackedVector2Array, _colours: PackedColorArray) -> void:
		mini_dots = points.size()

	## The status line's small pictures as they were last given (hud.gd `show_status`'s `icons`:
	## the kebab's heat, the jars); {} when the line has none.
	var icons := {}

	func show_status(t: String, c: String, d: String, h: String, p: float, a: Color, b := "", i := {}, he := "") -> void:
		icons = i
		status = h
		hint_en = he
		count = c
		distance = d
		progress = p
		lines += 1
		status_title = t
		tint = a
		badge = b

	func hide_status() -> void:
		icons = {}
		status = ""
		count = ""
		distance = ""
		progress = 0.0
		status_title = ""
		badge = ""
		hint_en = ""

	## How often the news ticker was sent off (hud.gd `ticker_out`: a call or a request takes its place).
	var tickers := 0

	func ticker_out() -> void:
		tickers += 1

	## hud.gd's `set_minimap_route`: the line the minimap draws now, its colour, and how often it was set.
	var route := PackedVector2Array()
	var route_colour := Color.WHITE
	var routes_set := 0

	## Whose the route is (hud.gd's owner rule) and how often a `clear_minimap_route` came.
	var route_owner := ""
	var routes_cleared := 0

	func set_minimap_route(points: PackedVector2Array, colour: Color, who := "") -> void:
		route = points
		route_colour = colour
		route_owner = who
		routes_set += 1

	## hud.gd's `clear_minimap_route`: the route goes only when `who` owns it.
	func clear_minimap_route(who: String) -> void:
		routes_cleared += 1
		if who == route_owner:
			route = PackedVector2Array()
			route_owner = ""

	func set_minimap_pois(points: PackedVector2Array, colours: PackedColorArray, shapes := PackedInt32Array()) -> void:
		pois = points.size()
		poi_points = points
		poi_colours = colours
		poi_shapes = shapes
		pois_set += 1

	func hide_challenge() -> void:
		challenge = ""
		challenges_hidden += 1

	## The English of the buttons' words (as the card gave them; `set_card_button` changes them), how
	## often `set_card_button` changed one and how often it found no card or no such button.
	var button_words_en := PackedStringArray()
	var buttons_set := 0
	var buttons_lost := 0

	## hud.gd's `set_card_button`: relabels button `i` of the card that is up.
	func set_card_button(i: int, pl: String, en: String) -> void:
		if card == "" or i < 0 or i >= button_words.size():
			buttons_lost += 1
			return
		button_words[i] = pl
		button_words_en[i] = en
		buttons_set += 1

	## hud.gd's `show_challenge`: the courier's challenge (its text, colour and the two sub lines).
	var challenge := ""
	var challenge_accent := Color.WHITE
	var challenge_sub := ""
	var challenge_sub_en := ""

	func show_challenge(text: String, accent_: Color, _gloss := "flash your lights to race (L)", sub := "", sub_en := "") -> void:
		challenge = text
		challenge_accent = accent_
		challenge_sub = sub
		challenge_sub_en = sub_en

	func show_pill(pl: String, en := "", who := "call") -> void:
		pill = who
		pill_word = pl
		pill_en = en

	func hide_pill() -> void:
		pill = ""
		pill_word = ""
		pills_hidden += 1

	func pill_shown(who: String) -> bool:
		return pill == who

	func pill_free_for(_who: String) -> bool:
		return pill_free

	func show_banner(text: String, _a: Color) -> void:
		banner = text
		banners.append(text)

	func hide_banner() -> void:
		banner = ""

	func show_note(title: String, text: String, _a: Color, _priority := 0) -> void:
		notes.append(title + ": " + text)
		note_titles.append(title)
		note_texts.append(text)

	## hud.gd's `notebook_changed` (the notebook's button gets its mark): how often it was asked for.
	var notebook_changes := 0

	func notebook_changed() -> void:
		notebook_changes += 1

	func set_quest_dots(points: PackedVector2Array, _colours: PackedColorArray) -> void:
		dots = points.size()

	func set_hush(on: bool) -> void:
		hush = on

	# The card's owner, as in hud.gd.
	func own_card(o: Object) -> void:
		_owner = o

	func card_is(o: Object) -> bool:
		return _owner == o and card != ""

	func card_showing() -> bool:
		return card != ""

	## hud.gd's `cards_up`: true while a card is up (a job asks before it offers).
	func cards_up() -> bool:
		return card != ""

	## What `call_ok` answers (hud.gd: whether a call may ring now); a check sets it to false.
	var calls_ok := true

	func call_ok() -> bool:
		return calls_ok

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
	## Where each was said, in step with `said`: the anchor as it was given (a node, a place, or
	## a Callable that names the place), and the speaker's name.
	var anchors: Array = []
	var speakers: Array[String] = []
	## How each was said, in step with `said`: [seconds, colour, height, prefer].
	var hows: Array = []
	## Each line's group and its tag apart, its class in the chatter budget (chatter.gd: QUEST, POLICE,
	## REACTION, AMBIENT) and its key ("bump", "near_miss"; "" for most), in step with `said`.
	var groups: Array[String] = []
	var tags: Array[String] = []
	var kinds: Array[int] = []
	var keys: Array[String] = []
	## What `say` answers (dialogue.gd: the line, or [] when the group has none or the budget dropped it).
	var say_words: Array = []
	## dialogue.gd's bubbles (a script that speaks its own lines over the car uses them).
	var bubbles: Control
	## dialogue.gd's `line`: "group:tag" of every line taken as words (for a card), and what it
	## answers ([Polish, English]; [] for a group with no line).
	var line_asks: Array[String] = []
	var line_words: Array = ["…", "…"]
	## Whether each of those lines was asked for as the preferred one (`line`'s third argument), in step with `line_asks`.
	var line_prefers: Array[bool] = []
	## What `line` answers when it is switched off: an empty bag, as dialogue.gd's for a group it has no line for.
	var no_lines := false
	## "group:tag" to a Dictionary `line` appends to the words it answers (dialogue.gd's note on a line).
	var line_notes := {}

	func say(anchor: Variant, who: String, group: String, tag := "", s := 4.0, c := Color.WHITE, h := 2.6, p := false, k := Chatter.QUEST, key := "") -> Array:
		said.append(group + ":" + tag)
		groups.append(group)
		tags.append(tag)
		kinds.append(k)
		keys.append(key)
		anchors.append(anchor)
		speakers.append(who)
		hows.append([s, c, h, p])
		return say_words

	## Forgets every line said and asked for so far (a check that starts a new part with a clean record); the
	## words `say` and `line` answer stay as they are.
	func forget() -> void:
		said.clear()
		groups.clear()
		tags.clear()
		kinds.clear()
		keys.clear()
		anchors.clear()
		speakers.clear()
		hows.clear()
		line_asks.clear()
		line_prefers.clear()

	## How often the line of `group` with `tag` was said or taken as words (`say` and its kin, and `line`).
	func count(group: String, tag: String) -> int:
		var key := group + ":" + tag
		return said.count(key) + line_asks.count(key)

	func line(group: String, tag := "", prefer := false) -> Array:
		line_asks.append(group + ":" + tag)
		line_prefers.append(prefer)
		if no_lines:
			return []
		var key := group + ":" + tag
		if line_notes.has(key):
			return line_words + [line_notes[key]]
		return line_words

	## dialogue.gd's `notes`: the line's third entry when it is a Dictionary.
	func notes(l: Array) -> Dictionary:
		return l[2] if l.size() > 2 and l[2] is Dictionary else {}

	## dialogue.gd's ambient chatter (a bystander's line): remembered the same way, as an AMBIENT line.
	func say_ambient(anchor: Variant, who: String, group: String, tag := "", s := 4.0, c := Color.WHITE, h := 2.6, p := false) -> Array:
		return say(anchor, who, group, tag, s, c, h, p, Chatter.AMBIENT)

	## dialogue.gd's line of someone reacting to the player (a shout, a near miss): a REACTION line with its key.
	func say_reaction(anchor: Variant, who: String, group: String, tag := "", s := 4.0, c := Color.WHITE, h := 2.6, p := false, key := "") -> Array:
		return say(anchor, who, group, tag, s, c, h, p, Chatter.REACTION, key)


## bubbles.gd: the lines said over the car (Polish), and whether the chatter budget lets one out.
class Bubbles extends Control:
	var said: Array[String] = []
	var ok := true
	## bubbles.gd's switch that hushes every bubble, how often they were all cleared, and what
	## `is_talking` answers.
	var quiet_all := false
	var cleared := 0
	var talking := false

	func clear() -> void:
		cleared += 1

	func is_talking(_anchor: Variant) -> bool:
		return talking

	func say(_anchor: Variant, _who: String, pl: String, _en := "", s := 4.0, c := Color.WHITE, _h := 2.6, k := Chatter.QUEST, key := "") -> bool:
		if ok:
			said.append(pl)
			durations.append(s)
			colours.append(c)
			kinds.append(k)
			keys.append(key)
		return ok

	## Each bubble's class in the chatter budget and its key, in step with `said`.
	var kinds: Array[int] = []
	var keys: Array[String] = []

	## bubbles.gd's `say_ambient` and `say_reaction`: the same bubble, as an AMBIENT or a REACTION line.
	func say_ambient(anchor: Variant, who: String, pl: String, en := "", s := 4.0, c := Color.WHITE, h := 2.6) -> bool:
		return say(anchor, who, pl, en, s, c, h, Chatter.AMBIENT)

	func say_reaction(anchor: Variant, who: String, pl: String, en := "", s := 4.0, c := Color.WHITE, h := 2.6, key := "") -> bool:
		return say(anchor, who, pl, en, s, c, h, Chatter.REACTION, key)

	## bubbles.gd's `allows` (would a line of this class show now: `ok`) and `muted` (the player drives too
	## fast for ambient chatter: `mute`).
	var mute := false

	func allows(_kind: int, _key := "") -> bool:
		return ok

	func muted() -> bool:
		return mute

	## The colour of each of those bubbles, in step with `said`.
	var colours: Array[Color] = []

	## How long each of those bubbles stays (seconds), in step with `said`.
	var durations: Array[float] = []

	## bubbles.gd's `hush`: the anchors whose bubble was taken down, in order.
	var hushed: Array = []

	func hush(anchor: Variant) -> void:
		hushed.append(anchor)


## missions.gd's switch for the rescue calls, and how often the rescue line was closed (`close`).
class Calls extends Node:
	var paused := false
	var closed := 0

	func close() -> void:
		closed += 1


class Wallet extends Node:
	var money := 0
	var respect := 0
	## wallet.gd's own name for the money (a script's log line reads it).
	var zl: int:
		get:
			return money
	var kinds: Array[String] = []
	## wallet.gd's kept facts (a club card, a count of wins) and the best time under each key.
	var keep := {}
	var best := {}

	## Every payment as [amount, gain, kind], in step with `kinds` (a check that tells two payments of one delivery apart).
	var payments: Array = []

	func pay(amount: int, gain := 0, kind := "") -> void:
		money += amount
		respect += gain
		kinds.append(kind)
		payments.append([amount, gain, kind])

	## wallet.gd's `spend`: false (and nothing taken) when there is not enough.
	func spend(amount: int) -> bool:
		if amount < 0 or amount > money:
			return false
		money -= amount
		return true

	## wallet.gd's `best_time`: the best time under the key, -1.0 when there is none.
	func best_time(key: String) -> float:
		return float(best.get(key, -1.0))

	## wallet.gd's `record`: true if the time beats the best (or is the first).
	func record(key: String, seconds: float) -> bool:
		if best.has(key) and float(best[key]) <= seconds:
			return false
		best[key] = seconds
		return true

	## wallet.gd's `save`: how often it was asked for.
	var saves := 0

	func save() -> void:
		saves += 1


## map_builder.gd's heights for a check with no city: the ground, the terrain, every deck and tunnel floor and
## the top of whatever stands at a point lie flat at 0, no point is under a roof and none is in a tunnel.
## It has no shore and no edge (`shore_distance`, `in_map`, `bounds`), and must not grow them: the game asks a
## map for those only when it has them (landmarks.gd, lane_graph.gd), so every check on the flat map would
## play something else. A check that needs a slope, a shore or its own roofs writes a class that extends
## this one with those functions only; they must take the game's arguments (check_fakes.gd A and B).
class FlatMap extends Node3D:
	## What `roof_height` answers: far under everything, so no point is under a roof (-INF for a check whose
	## map said so).
	var roof_level := -1000.0

	func ground_height(_x: float, _z: float) -> float:
		return 0.0

	func terrain_height(_x: float, _z: float) -> float:
		return 0.0

	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0

	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0

	func roof_height(_x: float, _z: float) -> float:
		return roof_level

	func top_height(_x: float, _z: float, _radius := 0.0) -> float:
		return 0.0

	func in_tunnel(_x: float, _z: float, _y: float) -> bool:
		return false


class Car extends Node3D:
	signal bumped(collider: Object, speed: float)
	## car.gd's speed (m/s) and what the test flags set when they put the car somewhere.
	var vel := Vector3.ZERO
	var forward_speed := 0.0
	var throttle := 0.0
