extends RefCounted
## G13 (F, 2026-11-01: "add some mechanic where with money you can buy upgrades, like a new
## fastest car, one should be like an Audi TT, or an improvement to the current car, nitro or
## what"): the rules and the numbers of the garage's second tab, "Części i auta" (Warsztat u Mirka,
## garage.gd; its card garage_card.gd). Static and map-free, so check_garage.gd tests them:
##  - **Cars** (CARS): the striped hatch (free, the default) and the "Ołdi TT" (a parody of a
##    certain Bavarian coupe; 1,500 zł): a lower, wider coupe with more top speed, pull and grip.
##    Both drive on the player's profile, Cruise or Sport (car.gd PROFILES).
##  - **Nitro** (NITRO, 350 zł): "Kebab Boost", N1 (2026-11-22): two bottles; a tap fires one, which
##    opens the gas and lifts the top speed and the pull for 2.5 s; a bottle refills in 12 s (car.gd
##    NITRO_*; hud.gd draws the disc above GAS with a segment a bottle once it is owned; Shift on a
##    keyboard, LB or RB on a pad).
##  - **Parts** (PARTS): tyres (grip) and engine (top speed and pull), levels 1 to 3, each level
##    dearer than the last (100-320 zł), kept for any car.
##  - **Looks** (LOOKS, F 2026-11-24: "you can buy, for example, add a spoiler"): the GT wing and the
##    underglow, bought once and kept for any car; they change nothing in the numbers (Mirek says so).
##    Owned looks are in `tune` as level 1 (save and rules as the parts'), so no new save section.
## Prices follow the jobs' pay (a kebab run about 35 zł, a First step 50 zł). Beta prices (F
## 2026-11-17: "a lot less, it's a beta"): the first part (100 zł) is two runs away, the nitro
## (350) about ten minutes of jobs, the coupe (1,500) the long-term goal.

## id, kind, name [pl, en], the card tile's short name ("short", when the name is long), what it is
## [pl, en], price (zł), and the model's multipliers (cars).
const CARS: Array[Dictionary] = [
	{"id": "hatch", "name": ["Hatchback z paskami", "Striped hatch"], "short": ["Hatchback", "Hatch"],
			"blurb": ["Mały, czerwony, uczciwy. Skręca tam, gdzie patrzysz.", "Small, red, honest. Turns where you look."],
			"price": 0, "top": 1.0, "pull": 1.0, "grip": 1.0},
	{"id": "tt", "name": ["Ołdi TT", "Owdy TT"],
			"blurb": ["Niski, szybki, trochę za drogi. Cztery kółka, żadne się nie zazębia.", "Low, fast, a bit overpriced. Four wheels, none interlocking."],
			"price": 1500, "top": 1.2, "pull": 1.2, "grip": 1.1},
	# C1a (F 2026-11-27: "a few different cars at Mirek's, meme cars, each drives its own way";
	# parodies, no badges). Classes (ladder.gd car_class): Łanos and Bolonez D, Paszat C, Szupra B,
	# the TT and the Bawarka A. `feel` is car.gd `feel` (turn, steer lag, tail slide on the sporty
	# end, the gas's bite, the pull's fade, the engine's note).
	{"id": "lanos", "name": ["Dejwu Łanos", "Dayvoo Wanos"], "short": ["Łanos", "Wanos"],
			"blurb": ["Emerytowana taksówka z Okęcia. W zakręcie płynie jak wersalka.", "A retired airport cab. Floats through a bend like a sofa bed."],
			"price": 200, "top": 0.97, "pull": 0.85, "grip": 0.95,
			"feel": {"turn": 0.93, "steer": 1.3, "slide": 1.25, "onset": 0.8, "note": 1.16}},
	{"id": "bolonez", "name": ["FSŁ Bolonez Karo", "FSW Bolonez Karo"], "short": ["Bolonez", "Bolonez"],
			"blurb": ["Ciężki jak PRL, skręca po namyśle. Tył ma swoje zdanie.", "Heavy as the old regime, turns after a think. The rear has opinions."],
			"price": 300, "top": 1.0, "pull": 0.88, "grip": 1.0,
			"feel": {"turn": 0.84, "steer": 1.5, "slide": 1.35, "onset": 0.85, "note": 0.8}},
	{"id": "paszat", "name": ["Paszat B5 TDI", "Pashat B5 TDI"], "short": ["Paszat", "Pashat"],
			"blurb": ["Diesel, kombi, 600 tys. km. Ciągnie z dołu, góra to plotka.", "Diesel estate, 600k km. Pulls from the bottom; the top is a rumour."],
			"price": 600, "top": 1.03, "pull": 1.35, "grip": 1.0,
			"feel": {"turn": 0.95, "steer": 1.1, "slide": 0.85, "onset": 1.6, "fade": 0.85, "note": 0.7}},
	{"id": "szupra", "name": ["Tojota Szupra", "Toyoda Shoopra"], "short": ["Szupra", "Shoopra"],
			"blurb": ["Dwa turbo, jeden spojler, zero pokory. Tył chętnie wyprzedza przód.", "Two turbos, one wing, zero humility. The rear likes to overtake the front."],
			"price": 1100, "top": 1.17, "pull": 1.15, "grip": 1.0,
			"feel": {"turn": 1.06, "steer": 0.9, "slide": 1.5, "onset": 1.1, "note": 1.08}},
	# The night meet's prize (story fix-plan-v2, F 2026-11-27): gold in the drag gives it free,
	# a lost drag opens it here (`open`: street_meet.gd sets wallet.keep "car_open_bawarka").
	{"id": "bawarka", "name": ["Bawarka Darka", "Darek's Bawarka"], "short": ["Bawarka", "Bawarka"],
			"blurb": ["Srebrno-niebieska legenda Nocnego spotu. Pije olej jak wodę.", "The silver-blue legend of the night meet. Drinks oil like water."],
			"price": 2500, "top": 1.28, "pull": 1.3, "grip": 1.15, "open": "drag",
			"feel": {"turn": 1.08, "steer": 0.85, "slide": 1.2, "onset": 1.2, "note": 0.94}},
]
## The keep flag that opens a car with `open` for sale (wallet.gd `keep`): OPEN_KEY + id.
const OPEN_KEY := "car_open_"
## The night meet's prize car.
const MEET_CAR := "bawarka"
const DEFAULT_CAR := "hatch"
const NITRO := {"id": "nitro", "name": ["Nitro „Kebab Boost”", "Nitro: Kebab Boost"], "short": ["Nitro", "Nitro"],
		"blurb": ["Dwie butle. Stuknij: 2,5 s mocy. Pusta butla ładuje się 12 s.", "Two bottles. Tap: 2.5 s of power. An empty bottle refills in 12 s."],
		"price": 350}
## The part's id, name, what a level adds, and the price of each level.
const PARTS: Array[Dictionary] = [
	{"id": "tyres", "name": ["Opony „Przyczep”", "Grip tyres"], "short": ["Opony", "Tyres"],
			"blurb": ["Przyczepność +8 % za poziom: trzyma zakręt.", "Grip +8 % a level: it holds the corner."],
			"prices": [100, 180, 280], "grip": 0.08},
	{"id": "engine", "name": ["Silnik „Mirek Stage”", "Mirek Stage engine"], "short": ["Silnik", "Engine"],
			"blurb": ["Prędkość +4 %, przyspieszenie +8 % za poziom.", "Top speed +4 %, pull +8 % a level."],
			"prices": [120, 220, 320], "top": 0.04, "pull": 0.08},
]
## The looks: id, name, price (Mirek's words on them are dialogue.json "garage" tags `wing`, `neon`
## and `wing_buy`, `neon_buy`).
const LOOKS: Array[Dictionary] = [
	{"id": "wing", "name": ["Spojler GT", "GT wing"], "price": 250},
	{"id": "neon", "name": ["Neon pod autem", "Underglow"], "price": 300},
]
const MAX_LEVEL := 3
## Order of the rows on the card (every shop id; the card's tabs, `TABS`, group them).
const ORDER := ["hatch", "lanos", "bolonez", "paszat", "szupra", "tt", "bawarka", "engine", "tyres", "nitro", "wing", "neon"]
## The card's tabs (F 2026-11-24: AUTA, TUNING, STYL; the paints are on STYL too).
const TABS := {"cars": ["hatch", "lanos", "bolonez", "paszat", "szupra", "tt", "bawarka"], "tune": ["engine", "tyres", "nitro"], "style": ["wing", "neon"]}


## The car row `id`, or {}.
static func car(id: String) -> Dictionary:
	for c in CARS:
		if str(c["id"]) == id:
			return c
	return {}


static func look(id: String) -> Dictionary:
	for l in LOOKS:
		if str(l["id"]) == id:
			return l
	return {}


static func part(id: String) -> Dictionary:
	for p in PARTS:
		if str(p["id"]) == id:
			return p
	return {}


## The row for any shop id (a car, nitro or a part), or {}.
static func find(id: String) -> Dictionary:
	if id == "nitro":
		return NITRO
	var c := car(id)
	if not c.is_empty():
		return c
	var l := look(id)
	return l if not l.is_empty() else part(id)


## "car", "nitro", "part", "look" or "".
static func kind(id: String) -> String:
	if id == "nitro":
		return "nitro"
	if not car(id).is_empty():
		return "car"
	if not look(id).is_empty():
		return "look"
	return "part" if not part(id).is_empty() else ""


## A look owned (bought once, then on the car).
static func has_look(tune: Dictionary, id: String) -> bool:
	return int(tune.get(id, 0)) >= 1


## The level of part `id` in `tune` (id -> level), 0 to MAX_LEVEL.
static func level(tune: Dictionary, id: String) -> int:
	return clampi(int(tune.get(id, 0)), 0, MAX_LEVEL)


## What the shop asks for `id` now: a car's or nitro's price, a part's next level (0 when maxed).
static func price(id: String, tune: Dictionary) -> int:
	var p := part(id)
	if not p.is_empty():
		var lv := level(tune, id)
		return 0 if lv >= MAX_LEVEL else int((p["prices"] as Array)[lv])
	return int(find(id).get("price", 0))


## The night meet's prize (story fix-plan-v2, F 2026-11-27): a real drag run (not a false start
## or off the strip) ended `won` gives the Bawarka (in `cars`, the day `day`: "given"), a lost one
## opens it for sale at Mirek's (`keep` OPEN_KEY: "opened"); "" when nothing changed (already
## owned, or already open on a loss). street_meet.gd `_drag_end` calls it and says what happened.
static func meet_prize(cars: Dictionary, keep: Dictionary, won: bool, day: int) -> String:
	if cars.has(MEET_CAR):
		return ""
	if won:
		cars[MEET_CAR] = day
		keep[OPEN_KEY + MEET_CAR] = true
		return "given"
	if bool(keep.get(OPEN_KEY + MEET_CAR, false)):
		return ""
	keep[OPEN_KEY + MEET_CAR] = true
	return "opened"


## A car's own feel for car.gd `set_feel` ({} for the hatch and the TT: the plain feel).
static func feel(car_id: String) -> Dictionary:
	return car(car_id).get("feel", {})


## What a tap on `id` would do. `st` is {car, cars (id -> day), nitro (bool), tune (id -> level),
## open (ids of cars with `open` that are for sale now)}:
## cars: "on" (on the road now), "switch" (owned: free), "locked" (an `open` car not opened yet),
## "buy", "short"; nitro and looks: "owned",
## "buy", "short"; parts: "max", "buy" (the next level), "short"; "" for an unknown id.
static func rule(id: String, zl: int, st: Dictionary) -> String:
	match kind(id):
		"car":
			if id == str(st.get("car", DEFAULT_CAR)):
				return "on"
			if id == DEFAULT_CAR or (st.get("cars", {}) as Dictionary).has(id):
				return "switch"
			if car(id).has("open") and not (st.get("open", []) as Array).has(id):
				return "locked"
		"nitro":
			if bool(st.get("nitro", false)):
				return "owned"
		"look":
			if has_look(st.get("tune", {}), id):
				return "owned"
		"part":
			if level(st.get("tune", {}), id) >= MAX_LEVEL:
				return "max"
		_:
			return ""
	return "buy" if zl >= price(id, st.get("tune", {})) else "short"


## The numbers the car drives with: {top (m/s, from the model's 30 m/s base), top_kmh, pull
## (multiplier), grip (multiplier), nitro (bool)}. `car_id` and `tune` as in `rule`'s state.
static func stats(car_id: String, tune: Dictionary, nitro := false) -> Dictionary:
	var c := car(car_id)
	if c.is_empty():
		c = car(DEFAULT_CAR)
	var eng := float(level(tune, "engine"))
	var tyr := float(level(tune, "tyres"))
	var top_m: float = float(c["top"]) * (1.0 + float(part("engine")["top"]) * eng)
	var pull_m: float = float(c["pull"]) * (1.0 + float(part("engine")["pull"]) * eng)
	var grip_m: float = float(c["grip"]) * (1.0 + float(part("tyres")["grip"]) * tyr)
	return {"top_mult": top_m, "top_kmh": roundi(30.0 * top_m * 3.6), "pull": pull_m, "grip": grip_m, "nitro": nitro}


## The stats the car would have after buying `id` (for the card's before / after), as `stats`.
static func stats_after(id: String, st: Dictionary) -> Dictionary:
	var car_id := str(st.get("car", DEFAULT_CAR))
	var tune: Dictionary = (st.get("tune", {}) as Dictionary).duplicate()
	var nitro := bool(st.get("nitro", false))
	match kind(id):
		"car":
			car_id = id
		"nitro":
			nitro = true
		"part":
			tune[id] = mini(level(tune, id) + 1, MAX_LEVEL)
	return stats(car_id, tune, nitro)
