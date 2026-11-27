extends Node3D
## The garage loop (2026-10-31; docs/DEMO.md 6.2's 10:00 beat and 6.3 "Progression", checklist
## F4): "Warsztat u Mirka", a tuning workshop on Grzybowska in Wola (an invented business on a
## real street; Mirek is an invented type). It moved from Brzeska in Praga, 3 km from the start, to
## Twarda on 2026-11-22 (F: "капец далеко"), and on 2026-11-24 off the street into a building of
## its own on the empty plot on Grzybowska's south side by Q22 (F: "a real garage, lit up, supercars
## and stripped cars beside it; drive up, press a button, buy upgrades; always on the map"). The
## building is the landmark site `warsztat_mirka` (landmarks/mirek.gd). The złoty buy paint jobs,
## cars and parts; the eggs found open a gold paint.
##  - **The place**: the forecourt in front of the open door (SPOT, off the carriageway, so waiting
##    there never blocks traffic), a diamond on the minimap and the full map from the very start
##    (F: "always on the map"). The first earnings still bring the toast that says where
##    (`open_rule`, the guide's garage beat: `is_shown`).
##  - **The way in** (F 2026-11-24): roll onto the forecourt (within RING of SPOT, under STOP_SPEED
##    m/s, no job, race, rescue or chase on, not flying) and a side card asks: WJEŻDŻAM / NIE TERAZ
##    (Enter on a keyboard is the first). WJEŻDŻAM opens the card (garage_card.gd): the game pauses
##    under it like the settings card. The paints, their prices, Mirek's line; buy one (the wallet
##    pays), or switch to one owned (free). NIE TERAZ: the question waits until the car has left.
##  - **The paints** (PAINTS): factory red (free, the default), six more for 50-150 zł (beta prices,
##    F 2026-11-17: the first delivery's money buys one; black 120: egg E01 at Lusterko's door; pea
##    green 60: egg E21 at Glon) and gold, free once GOLD_EGGS
##    egg cards are found. Owned paints are kept (wallet.gd `paints`, the day each was bought) and
##    the one on the car (`paint`): the save's [garage] section. car.gd `set_paint` rebuilds the
##    body's one mesh once (the same material: no new draw call).
## Nothing runs per frame but a 4 Hz look at the forecourt (`spent_usec`: the bench's "garage" line).

signal opened
signal closed
## A paint went on the car (bought or switched): its id.
signal painted(id: String)
## G13: a car, the nitro or a part was bought (or a car switched to): its shop id.
signal upgraded(id: String)

const MapMarkers := preload("res://scripts/map_markers.gd")
const GarageCard := preload("res://scripts/garage_card.gd")
## G13: the second tab, "Części i auta" (a faster car, nitro, tyres and engine): upgrades.gd.
const Upgrades := preload("res://scripts/upgrades.gd")

## The workshop's forecourt (map metres): the middle of the apron in front of the open door, in
## mirek.gd's frame (WM_O, WM_A) at u -6, v 14 (checked by check_garage.gd), ~14 m off Grzybowska's
## eastbound carriageway: ~820 m from the guided start, ~230 m north-west of the old ring on Twarda.
const SPOT := Vector2(-1730.0, -238.3)
## Which way the door looks into the workshop from the forecourt (mirek.gd's v axis): the car
## --garage puts there faces it.
const FACE := Vector2(0.5018, 0.8650)
const NAME := ["Warsztat u Mirka", "Mirek's garage"]
const STREET := "Grzybowska"
## The district on the card under the name (garage_card.gd).
const DISTRICT := "Wola"
const GARAGE_COLOUR := Color("#5aa0ff")
## Roll onto the forecourt (within RING m of SPOT) under this speed (m/s) and the card asks; leave
## COOL m for it to ask again.
const RING := 8.0
const STOP_SPEED := 2.5
const COOL := 20.0
const CHECK_EVERY := 0.25
## Egg cards found that open the gold paint (DEMO 6.3: collectibles unlock a gold paint).
const GOLD_EGGS := 5
const DEFAULT := "red"
## id, name [pl, en], the body's colour and glow (car.gd HERO_PAINT is 1.4), the stripes' colour
## and glow (HERO_STRIPE 0.3), the price (zł), `eggs`: egg cards needed instead of money (loop 3h
## slice 2: `syrenki`: Syrenki found needed, the same way: "scale" at 5, "silver" at 20). Black
## glows more than its colour gives (a near-black lit by 1.4 stays near-black at night) and wears
## silver stripes that glow, so the car reads on a dark street.
const PAINTS: Array[Dictionary] = [
	{"id": "red", "name": ["Fabryczna czerwień", "Factory red"], "paint": Color("#d8432f"), "glow": 1.4,
			"stripe": Color("#f4efe4"), "stripe_glow": 0.3, "price": 0},
	{"id": "cream", "name": ["Kremowy", "Cream"], "paint": Color("#e9dfc6"), "glow": 0.9,
			"stripe": Color("#c43b2c"), "stripe_glow": 0.6, "price": 50},
	{"id": "green", "name": ["Zielony groszek", "Pea green"], "paint": Color("#5aa83a"), "glow": 1.4,
			"stripe": Color("#f4efe4"), "stripe_glow": 0.3, "price": 60},
	{"id": "blue", "name": ["Wiślany błękit", "Vistula blue"], "paint": Color("#2f72c8"), "glow": 1.5,
			"stripe": Color("#f4efe4"), "stripe_glow": 0.3, "price": 80},
	{"id": "yellow", "name": ["Żółty jak tramwaj", "Tram yellow"], "paint": Color("#ecc02a"), "glow": 1.2,
			"stripe": Color("#23211f"), "stripe_glow": 0.0, "price": 100},
	{"id": "black", "name": ["Czarny lakier", "Black paint"], "paint": Color("#1d1e24"), "glow": 4.5,
			"stripe": Color("#b9bec8"), "stripe_glow": 0.9, "price": 120},
	{"id": "pink", "name": ["Różowy pączek", "Doughnut pink"], "paint": Color("#e87aa6"), "glow": 1.3,
			"stripe": Color("#f4efe4"), "stripe_glow": 0.3, "price": 150},
	{"id": "gold", "name": ["Złoto Syrenki", "Mermaid gold"], "paint": Color("#d6a630"), "glow": 1.5,
			"stripe": Color("#2b2620"), "stripe_glow": 0.0, "price": 0, "eggs": GOLD_EGGS},
	{"id": "scale", "name": ["Łuska Syreny", "Mermaid scale"], "paint": Color("#2a9d8f"), "glow": 1.4,
			"stripe": Color("#f4efe4"), "stripe_glow": 0.3, "price": 0, "syrenki": 5},
	{"id": "silver", "name": ["Srebro Syreny", "Mermaid silver"], "paint": Color("#c9ced6"), "glow": 1.1,
			"stripe": Color("#2b2620"), "stripe_glow": 0.0, "price": 0, "syrenki": 20},
]

var wallet: Node
var hud: CanvasLayer
var dialogue: Node
var car: CharacterBody3D
var map: Node3D
## lane_graph.gd (unused since the forecourt left the street; main.gd still hands it over).
var graph
## Is anything else on (a job, a race, a rescue, the police, the helicopter)? -> bool.
var busy: Callable
## The egg cards found, -> int (egg_book.gd found_total; unset: the wallet's eggs).
var eggs_found: Callable
## Loop 3h slice 2: the Syrenki found, -> int (unset: the wallet's `syrenki`).
var syrenki_found: Callable
## --garage: shown whatever the wallet says (no toast), and the card opens without the question.
var force := false
## Loop 3h slice 4: the guided first 10 minutes (first10.gd) keep the "it's open" toast back until
## their garage beat, earnings or not. The place itself is on the map and open the whole time.
var held := false
## --garage=parts: the card opens on the parts tab (G13).
var start_tab := "paint"
## --garage-log: the card, the buys and the paints.
var log_on := false
## Time spent in this script since the bench last read it (µs).
var spent_usec := 0
## The forecourt's middle, on the ground.
var at := Vector3.INF
## The card (built at the first open).
var card: Control
var _shown := false
## The side card's question (WJEŻDŻAM / NIE TERAZ) is up and this garage's.
var _asking := false
var _cool := false
var _t := 0.0
var _open := false


# --- the rules (static: check_garage.gd) -----------------------------------------------------

## The paint `id`'s row, or {} if there is none.
static func find(id: String) -> Dictionary:
	for p in PAINTS:
		if str(p["id"]) == id:
			return p
	return {}


## What a tap on `id` would do with `zl` złoty, `owned` (id -> day) and `eggs` egg cards found:
## "on" (on the car now), "switch" (owned: free), "buy" (affordable), "short" (too little money),
## "locked" (gold, too few eggs; loop 3h slice 2: or too few `syrenki`), "" (no such paint).
static func rule(id: String, current: String, zl: int, owned: Dictionary, eggs: int, syrenki := 0) -> String:
	var p := find(id)
	if p.is_empty():
		return ""
	if id == current:
		return "on"
	if owned.has(id) or id == DEFAULT:
		return "switch"
	if p.has("eggs"):
		return "switch" if eggs >= int(p["eggs"]) else "locked"
	if p.has("syrenki"):
		return "switch" if syrenki >= int(p["syrenki"]) else "locked"
	return "buy" if zl >= int(p["price"]) else "short"


## The garage shows once the player has earned anything: a job done, złoty in hand or a paint
## bought.
static func open_rule(jobs: Dictionary, zl: int, owned: Dictionary) -> bool:
	var n := 0
	for k in jobs:
		n += int(jobs[k])
	return n > 0 or zl > 0 or not owned.is_empty()


# --- setup -----------------------------------------------------------------------------------

## The forecourt on the ground at SPOT, its diamond on the maps from the start; the car's saved paint.
func setup(_world: Node3D) -> void:
	var y: float = map.ground_height(SPOT.x, SPOT.y) if map != null else 0.0
	at = Vector3(SPOT.x, y, SPOT.y)
	if hud != null:
		hud.markers.put("garage:workshop", MapMarkers.Layer.SERVICE, SPOT, GARAGE_COLOUR, 0, "garage")
	apply_saved()
	apply_car()
	_refresh(true)
	print("garage: %s at %.0f, %.0f (%s); paint %s, %d owned%s" % [NAME[0], at.x, at.z, STREET,
			current(), owned().size() + 1, ", told" if _shown else ", not told yet"])


# --- the paints --------------------------------------------------------------------------------

func current() -> String:
	return str(wallet.paint) if wallet != null and not find(str(wallet.paint)).is_empty() else DEFAULT


func owned() -> Dictionary:
	return wallet.paints if wallet != null else {}


func eggs_now() -> int:
	if eggs_found.is_valid():
		return int(eggs_found.call())
	return wallet.eggs_found() if wallet != null else 0


func syrenki_now() -> int:
	if syrenki_found.is_valid():
		return int(syrenki_found.call())
	return wallet.syrenki.size() if wallet != null else 0


## What a tap on `id` would do now (`rule`).
func rule_now(id: String) -> String:
	return rule(id, current(), int(wallet.zl) if wallet != null else 0, owned(), eggs_now(), syrenki_now())


## Buys or switches to `id` when the rule allows: the wallet pays a buy, the paint is owned and on
## the car, saved. Returns the rule that applied ("buy", "switch"), or why not.
func choose(id: String) -> String:
	var r := rule_now(id)
	match r:
		"buy":
			var p := find(id)
			if not wallet.spend(int(p["price"])):
				return "short"
			wallet.paints[id] = today()
			_put_on(id)
			print("garage: bought %s for %d zł -> %d zł left" % [id, int(p["price"]), wallet.zl])
		"switch":
			if id != DEFAULT and not wallet.paints.has(id):
				wallet.paints[id] = today()  # the gold paint, opened by the eggs
			_put_on(id)
			print("garage: switched to %s (owned, free)" % id)
	return r


func _put_on(id: String) -> void:
	wallet.paint = id
	wallet.save()
	paint_car(id)
	painted.emit(id)
	_refresh(true)


## The car wears paint `id` (car.gd `set_paint`: the body mesh made again once).
func paint_car(id: String) -> void:
	var p := find(id)
	if p.is_empty() or car == null:
		return
	car.set_paint(p["paint"], p["stripe"], float(p["glow"]), float(p["stripe_glow"]))


## The saved paint on the car (at the start; --paint sets the wallet's first).
func apply_saved() -> void:
	if current() != DEFAULT:
		paint_car(current())


## --paint=<id>: the car starts with that paint, owned for this run (with --nosave nothing stays).
func preset(id: String) -> bool:
	if find(id).is_empty() or wallet == null:
		push_warning("--paint=%s: no such paint (%s)" % [id, ", ".join(PAINTS.map(func(p: Dictionary) -> String: return str(p["id"])))])
		return false
	if id != DEFAULT:
		wallet.paints[id] = today()
	wallet.paint = id
	paint_car(id)
	print("garage: --paint=%s" % id)
	return true


static func today() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])


## Mirek's line for `tag` (dialogue.json "garage": hello, buy, black, green, gold, switch, short,
## locked, plus G13's parts, tt, nitro, part, max) as [pl, en].
func line(tag: String) -> Array:
	if dialogue == null:
		return ["", ""]
	var l: Array = dialogue.line("garage", tag, true)
	return [str(l[0]), str(l[1])] if l.size() >= 2 else ["", ""]


# --- the shop: cars, nitro, parts (G13) -------------------------------------------------------

## The shop's state for upgrades.gd's rules.
func shop_state() -> Dictionary:
	if wallet == null:
		return {"car": Upgrades.DEFAULT_CAR, "cars": {}, "nitro": false, "tune": {}}
	var open: Array = []
	for c: Dictionary in Upgrades.CARS:
		if c.has("open") and bool(wallet.keep.get(Upgrades.OPEN_KEY + str(c["id"]), false)):
			open.append(str(c["id"]))
	return {"car": wallet.car, "cars": wallet.cars, "nitro": wallet.nitro, "tune": wallet.tune, "open": open, "respect": wallet.respect}


## What a tap on shop item `id` would do now (upgrades.gd `rule`).
func item_rule_now(id: String) -> String:
	return Upgrades.rule(id, int(wallet.zl) if wallet != null else 0, shop_state())


## Buys or switches to shop item `id` when the rule allows (the wallet pays; a car is bought once and
## then switched to for free, a part's next level is bought, the nitro once), saved and put on the
## car. Returns the rule that applied ("buy", "switch") or why not.
func choose_item(id: String) -> String:
	var r := item_rule_now(id)
	if r == "buy":
		var price := Upgrades.price(id, wallet.tune)
		if not wallet.spend(price):
			return "short"
		match Upgrades.kind(id):
			"car":
				wallet.cars[id] = today()
				wallet.car = id
			"nitro":
				wallet.nitro = true
			"look":
				wallet.tune[id] = 1
			"part":
				wallet.tune[id] = Upgrades.level(wallet.tune, id) + 1
		print("garage: bought %s for %d zł -> %d zł left" % [id, price, wallet.zl])
	elif r == "switch":
		wallet.car = id
		print("garage: switched to the %s (owned, free)" % id)
	else:
		return r
	wallet.save()
	apply_car()
	upgraded.emit(id)
	return r


## The car wears the wallet's model, tuning and nitro (at the start, and after every purchase).
func apply_car() -> void:
	if car == null or wallet == null:
		return
	var st := Upgrades.stats(str(wallet.car), wallet.tune, bool(wallet.nitro))
	if car.has_method("set_feel"):
		car.feel = car.FEEL_PLAIN.merged(Upgrades.feel(str(wallet.car)), true)
	car.set_tuning(float(st["top_mult"]), float(st["pull"]), float(st["grip"]))
	car.nitro_owned = bool(wallet.nitro)
	if str(wallet.car) != car.model:
		car.set_model(str(wallet.car))
	if car.has_method("set_looks"):
		car.set_looks(Upgrades.has_look(wallet.tune, "wing"), Upgrades.has_look(wallet.tune, "neon"))
	if hud != null and hud.has_method("set_nitro"):
		hud.set_nitro(car.nitro_owned, car.nitro_charge, car.nitro_bottles, car.nitro_on)


## --upgrades=all: every car, the nitro and every part at level 3, for this run (with --nosave nothing
## stays); --upgrades=tt|nitro (or any car id of upgrades.gd CARS): just that.
func preset_upgrades(what: String) -> void:
	if wallet == null:
		return
	if what in ["all", "tt"]:
		wallet.cars["tt"] = today()
		wallet.car = "tt"
	elif not Upgrades.car(what).is_empty():
		# --upgrades=bolonez|paszat|mjata|kadilak|gr86|porsza|bawarka|mruczelago: that car, owned and on the road.
		wallet.cars[what] = today()
		wallet.car = what
	if what in ["all", "nitro"]:
		wallet.nitro = true
	if what == "all":
		wallet.tune = {"tyres": 3, "engine": 3}
	apply_car()
	print("garage: --upgrades=%s" % what)


# --- the forecourt -----------------------------------------------------------------------------

func is_shown() -> bool:
	return _shown


func is_open() -> bool:
	return _open


## The rule says the player has earned something (the first time: a toast saying where). The
## diamond on the maps does not wait for it (F 2026-11-24: always on the map; put in `setup`).
func _refresh(quiet := false) -> void:
	var on := force or (not held and wallet != null and open_rule(wallet.jobs, int(wallet.zl), wallet.paints))
	if on == _shown:
		return
	_shown = on
	if on and not quiet and not force and hud != null and wallet != null and not bool(wallet.keep.get("garage_told", false)):
		wallet.keep["garage_told"] = true
		wallet.save()
		hud.toast("Warsztat u Mirka otwarty: Grzybowska, ten z neonem. Lakier i tuning za złotówki.",
				"Mirek's garage is open: on Grzybowska, the one with the neon. Paint and tuning for złoty.")
		if log_on:
			print("garage: shown (the first earnings)")


func _process(dt: float) -> void:
	_t += dt
	if _t < CHECK_EVERY:
		return
	_t = 0.0
	var t0 := Time.get_ticks_usec()
	tick()
	spent_usec += Time.get_ticks_usec() - t0


## One look: the rule, and the car on the forecourt, slow, nothing else on -> the question (with
## --garage: the card at once). The question goes when the car leaves or something else starts.
func tick() -> void:
	_refresh()
	if _open or car == null or at == Vector3.INF:
		return
	var p := car.global_position
	var d := Vector2(p.x - at.x, p.z - at.z).length()
	if _asking:
		if hud == null or not hud.card_is(self):
			_asking = false  # another card took its place: asked again when it has gone
		elif d > RING + 3.0 or (busy.is_valid() and bool(busy.call())):
			_drop_question()
		return
	if _cool:
		_cool = d < COOL
		return
	if d > RING or car.vel.length() > STOP_SPEED:
		return
	if busy.is_valid() and bool(busy.call()):
		return
	if force:
		open_card(start_tab)
		return
	if hud == null or hud.card_showing():
		return
	_ask()


## The side card at the door: WARSZTAT U MIRKA, Mirek's call, WJEŻDŻAM / NIE TERAZ; its buttons
## come to `card_pressed` (hud.gd `own_card`).
func _ask() -> void:
	var say := line("ask")
	var yes := line("ask_yes")
	var no := line("ask_no")
	_asking = true
	hud.show_side_card(str(NAME[0]).to_upper(), str(say[0]), PackedStringArray(["%s|%s" % yes, "%s|%s" % no]),
			GARAGE_COLOUR, str(NAME[1]), str(say[1]))
	hud.own_card(self)
	if log_on:
		print("garage: asked at the door")


func _drop_question() -> void:
	_asking = false
	if hud != null and hud.card_is(self):
		hud.hide_card()


func is_asking() -> bool:
	return _asking


## A button of the question: 0 drives in (the card opens), 1 not now (asked again once the car
## has left the forecourt).
func card_pressed(index: int) -> void:
	_drop_question()
	if index == 0:
		open_card(start_tab)
	else:
		_cool = true


## Enter on a keyboard answers the question with its first button (F: "press enter").
func _unhandled_key_input(event: InputEvent) -> void:
	if not _asking:
		return
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo and k.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		card_pressed(0)


## The card opens (main.gd pauses the game under it: `opened`).
## G2: "garage" at Mirek's (buy, tune, paint), "mine" from the full map's MOJE AUTO (look and
## switch what is owned; buying waits for the workshop), "lot" for the car lot (later).
var mode := "garage"


func open_card(start_tab := "paint", how := "garage") -> void:
	if _open or hud == null:
		return
	_open = true
	if card == null:
		card = GarageCard.new()
		card.name = "garage_card"
		card.garage = self
		card.pt = hud.pt
		card.safe = hud.safe_rect()
		hud.add_child(card)
		card.closed.connect(close_card)
	hud.release_all()
	hud.move_child(card, -1)
	card.pt = hud.pt
	card.safe = hud.safe_rect()
	mode = how
	card.open(start_tab, how)
	if log_on:
		print("garage: the card open (%d zł, paint %s, owned %s, eggs %d)" % [wallet.zl, current(), owned().keys(), eggs_now()])
	opened.emit()


func close_card() -> void:
	if not _open:
		return
	_open = false
	_cool = true
	if card != null and card.is_open():
		card.close()
	if log_on:
		print("garage: the card closed (paint %s)" % current())
	closed.emit()
