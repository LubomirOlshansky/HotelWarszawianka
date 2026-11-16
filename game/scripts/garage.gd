extends Node3D
## The garage loop (2026-10-31; docs/DEMO.md 6.2's 10:00 beat and 6.3 "Progression", checklist
## F4): "Warsztat u Mirka", a street workshop on Brzeska in Praga (an invented business on a real
## street; Mirek is an invented type). The złoty buy paint jobs for the hatchback; the eggs found
## open a gold one.
##  - **The place**: a dashed ring on the street (jobs.gd's pull-in look, in GARAGE_COLOUR) at the
##    lane graph's point nearest SPOT, a diamond on the minimap and the full map. It shows once the
##    player has earned anything (`open_rule`: a job done, złoty in the wallet or a paint bought:
##    the default for the beat's "after the first earnings"); the first time, a toast says where.
##  - **The card** (garage_card.gd): drive into the ring and stop (under STOP_SPEED m/s, no job,
##    race, rescue or chase on, not flying): the game pauses under it like the settings card. The
##    paints, their prices, Mirek's line; buy one (the wallet pays), or switch to one owned (free).
##  - **The paints** (PAINTS): factory red (free, the default), six more for 150-350 zł (black 300:
##    egg E01 at Lusterko's door; pea green 180: egg E21 at Glon) and gold, free once GOLD_EGGS
##    egg cards are found. Owned paints are kept (wallet.gd `paints`, the day each was bought) and
##    the one on the car (`paint`): the save's [garage] section. car.gd `set_paint` rebuilds the
##    body's one mesh once (the same material: no new draw call).
## Nothing runs per frame but a 4 Hz look at the ring (`spent_usec`: the bench's "garage" line).

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

## The workshop's spot: a point on Brzeska (map metres) near which the ring goes on the street.
const SPOT := Vector2(1321.0, -1947.6)
const NAME := ["Warsztat u Mirka", "Mirek's garage"]
const STREET := "Brzeska"
const GARAGE_COLOUR := Color("#5aa0ff")
## Stop in this ring (m) under this speed (m/s) and the card opens; leave COOL m to open it again.
const RING := 6.0
const STOP_SPEED := 1.5
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
			"stripe": Color("#c43b2c"), "stripe_glow": 0.6, "price": 150},
	{"id": "green", "name": ["Zielony groszek", "Pea green"], "paint": Color("#5aa83a"), "glow": 1.4,
			"stripe": Color("#f4efe4"), "stripe_glow": 0.3, "price": 180},
	{"id": "blue", "name": ["Wiślany błękit", "Vistula blue"], "paint": Color("#2f72c8"), "glow": 1.5,
			"stripe": Color("#f4efe4"), "stripe_glow": 0.3, "price": 200},
	{"id": "yellow", "name": ["Żółty jak tramwaj", "Tram yellow"], "paint": Color("#ecc02a"), "glow": 1.2,
			"stripe": Color("#23211f"), "stripe_glow": 0.0, "price": 250},
	{"id": "black", "name": ["Czarny lakier", "Black paint"], "paint": Color("#1d1e24"), "glow": 4.5,
			"stripe": Color("#b9bec8"), "stripe_glow": 0.9, "price": 300},
	{"id": "pink", "name": ["Różowy pączek", "Doughnut pink"], "paint": Color("#e87aa6"), "glow": 1.3,
			"stripe": Color("#f4efe4"), "stripe_glow": 0.3, "price": 350},
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
## lane_graph.gd: where the ring meets the street (null: the ring sits on SPOT).
var graph
## Is anything else on (a job, a race, a rescue, the police, the helicopter)? -> bool.
var busy: Callable
## The egg cards found, -> int (egg_book.gd found_total; unset: the wallet's eggs).
var eggs_found: Callable
## Loop 3h slice 2: the Syrenki found, -> int (unset: the wallet's `syrenki`).
var syrenki_found: Callable
## --garage: shown whatever the wallet says (no toast).
var force := false
## Loop 3h slice 4: the guided first 10 minutes (first10.gd) keep the ring hidden until their
## 10:00 beat, earnings or not (the rule's "after the first earnings" waits for it).
var held := false
## --garage=parts: the card opens on the parts tab (G13).
var start_tab := "paint"
## --garage-log: the card, the buys and the paints.
var log_on := false
## Time spent in this script since the bench last read it (µs).
var spent_usec := 0
## The ring's centre (on the road).
var at := Vector3.INF
## The card (built at the first open).
var card: Control
var _ring: MeshInstance3D
var _shown := false
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

## The ring on the street nearest SPOT (on the lane graph, the ground level), hidden until it
## shows; the car's saved paint.
func setup(world: Node3D) -> void:
	var p := SPOT
	var y := 0.0
	if graph != null:
		var hit: Array = graph.snap(SPOT, 40.0, Vector2.ZERO, true, true)
		if hit.is_empty():
			hit = graph.snap(SPOT, 40.0, Vector2.ZERO, false, true)
		if not hit.is_empty():
			p = graph.point_at(int(hit[0]), float(hit[2]))
			y = graph.surface(int(hit[0]), p)
	elif map != null:
		y = map.ground_height(p.x, p.y)
	at = Vector3(p.x, y, p.y)
	_ring = _ring_node()
	world.add_child(_ring)
	_ring.global_position = at
	_ring.visible = false
	apply_saved()
	apply_car()
	_refresh(true)
	print("garage: %s at %.0f, %.0f (%s), %.1f m from its spot; paint %s, %d owned%s" % [NAME[0], at.x, at.z, STREET,
			p.distance_to(SPOT), current(), owned().size() + 1, ", shown" if _shown else ", not shown yet"])


## The dashed ring (jobs.gd `_marker`'s look, a little wider), unshaded, no shadow: one draw call
## while near, none away (culled).
func _ring_node() -> MeshInstance3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = GARAGE_COLOUR
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 28
	for i in n:
		if i % 2 == 1:
			continue
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var o0 := Vector3(cos(a0), 0.0, sin(a0))
		var o1 := Vector3(cos(a1), 0.0, sin(a1))
		var y := Vector3(0, 0.4, 0)
		for v in [o0 * RING, o1 * RING, o0 * (RING - 0.5), o1 * RING, o1 * (RING - 0.5), o0 * (RING - 0.5)]:
			st.add_vertex(v + y)
	var mi := MeshInstance3D.new()
	mi.name = "GarageRing"
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


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
	return {"car": wallet.car, "cars": wallet.cars, "nitro": wallet.nitro, "tune": wallet.tune}


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
	car.set_tuning(float(st["top_mult"]), float(st["pull"]), float(st["grip"]))
	car.nitro_owned = bool(wallet.nitro)
	if str(wallet.car) != car.model:
		car.set_model(str(wallet.car))
	if hud != null and hud.has_method("set_nitro"):
		hud.set_nitro(car.nitro_owned, car.nitro_charge)


## --upgrades=all: every car, the nitro and every part at level 3, for this run (with --nosave nothing
## stays); --upgrades=tt|nitro: just that.
func preset_upgrades(what: String) -> void:
	if wallet == null:
		return
	if what in ["all", "tt"]:
		wallet.cars["tt"] = today()
		wallet.car = "tt"
	if what in ["all", "nitro"]:
		wallet.nitro = true
	if what == "all":
		wallet.tune = {"tyres": 3, "engine": 3}
	apply_car()
	print("garage: --upgrades=%s" % what)


# --- the ring ----------------------------------------------------------------------------------

func is_shown() -> bool:
	return _shown


func is_open() -> bool:
	return _open


## The ring and the marks follow the rule (the first time: a toast).
func _refresh(quiet := false) -> void:
	var on := force or (not held and wallet != null and open_rule(wallet.jobs, int(wallet.zl), wallet.paints))
	if on == _shown:
		return
	_shown = on
	if _ring != null:
		_ring.visible = on
	if hud != null:
		# Its diamond on the minimap and the full map (map_markers.gd, TD-13).
		if on:
			hud.markers.put("garage:workshop", MapMarkers.Layer.SERVICE, Vector2(at.x, at.z), GARAGE_COLOUR, 0, "garage")
		else:
			hud.markers.remove("garage:workshop")
	if on and not quiet and not force and hud != null and wallet != null and not bool(wallet.keep.get("garage_told", false)):
		wallet.keep["garage_told"] = true
		wallet.save()
		hud.toast("Warsztat u Mirka otwarty: Brzeska, Praga. Lakier za złotówki.",
				"Mirek's garage is open: Brzeska, Praga. Paint jobs for złoty.")
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


## One look: the rule, and the car in the ring, stopped, nothing else on -> the card.
func tick() -> void:
	_refresh()
	if not _shown or _open or car == null or at == Vector3.INF:
		return
	var p := car.global_position
	var d := Vector2(p.x - at.x, p.z - at.z).length()
	if _cool:
		_cool = d < COOL
		return
	if d > RING or car.vel.length() > STOP_SPEED:
		return
	if busy.is_valid() and bool(busy.call()):
		return
	open_card(start_tab)


## The card opens (main.gd pauses the game under it: `opened`).
func open_card(start_tab := "paint") -> void:
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
	card.open(start_tab)
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
