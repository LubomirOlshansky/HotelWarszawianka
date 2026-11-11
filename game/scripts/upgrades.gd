extends RefCounted
## G13 (F, 2026-11-01: "add some mechanic where with money you can buy upgrades, like a new
## fastest car, one should be like an Audi TT, or an improvement to the current car, nitro or
## what"): the rules and the numbers of the garage's second tab, "Części i auta" (Warsztat u Mirka,
## garage.gd; its card garage_card.gd). Static and map-free, so check_garage.gd tests them:
##  - **Cars** (CARS): the striped hatch (free, the default) and the "Ołdi TT" (a parody of a
##    certain Bavarian coupe; 2,500 zł): a lower, wider coupe with more top speed, pull and grip.
##    Both drive on the player's profile, Cruise or Sport (car.gd PROFILES).
##  - **Nitro** (NITRO, 600 zł): "Kebab Boost", a button that opens the gas and lifts the top speed
##    and the pull for a few seconds, then refills (car.gd NITRO_*; hud.gd draws the button and its
##    tank once it is owned; Shift on a keyboard, LB or RB on a pad).
##  - **Parts** (PARTS): tyres (grip) and engine (top speed and pull), levels 1 to 3, each level
##    dearer than the last (150-400 zł), kept for any car.
## Prices follow the jobs' pay (a kebab run about 35 zł): the first part (150 zł) is a few runs
## away, the nitro about a quarter of an hour of jobs, the coupe the long-term goal.

## id, kind, name [pl, en], what it is [pl, en], price (zł), and the model's multipliers (cars).
const CARS: Array[Dictionary] = [
	{"id": "hatch", "name": ["Hatchback z paskami", "Striped hatch"],
			"blurb": ["Mały, czerwony, uczciwy. Skręca tam, gdzie patrzysz.", "Small, red, honest. Turns where you look."],
			"price": 0, "top": 1.0, "pull": 1.0, "grip": 1.0},
	{"id": "tt", "name": ["Ołdi TT", "Owdy TT"],
			"blurb": ["Niski, szybki, trochę za drogi. Cztery kółka, żadne się nie zazębia.", "Low, fast, a bit overpriced. Four wheels, none interlocking."],
			"price": 2500, "top": 1.2, "pull": 1.2, "grip": 1.1},
]
const DEFAULT_CAR := "hatch"
const NITRO := {"id": "nitro", "name": ["Nitro „Kebab Boost”", "Nitro: Kebab Boost"],
		"blurb": ["Przycisk obok hamulca: 3,5 s mocy, potem 20 s ładowania.", "A button by the brake: 3.5 s of power, then 20 s to refill."],
		"price": 600}
## The part's id, name, what a level adds, and the price of each level.
const PARTS: Array[Dictionary] = [
	{"id": "tyres", "name": ["Opony „Przyczep”", "Grip tyres"],
			"blurb": ["Przyczepność +8 % za poziom: trzyma zakręt.", "Grip +8 % a level: it holds the corner."],
			"prices": [150, 250, 350], "grip": 0.08},
	{"id": "engine", "name": ["Silnik „Mirek Stage”", "Mirek Stage engine"],
			"blurb": ["Prędkość +4 %, przyspieszenie +8 % za poziom.", "Top speed +4 %, pull +8 % a level."],
			"prices": [200, 300, 400], "top": 0.04, "pull": 0.08},
]
const MAX_LEVEL := 3
## Order of the rows on the card.
const ORDER := ["tt", "nitro", "tyres", "engine", "hatch"]


## The car row `id`, or {}.
static func car(id: String) -> Dictionary:
	for c in CARS:
		if str(c["id"]) == id:
			return c
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
	return c if not c.is_empty() else part(id)


## "car", "nitro", "part" or "".
static func kind(id: String) -> String:
	if id == "nitro":
		return "nitro"
	if not car(id).is_empty():
		return "car"
	return "part" if not part(id).is_empty() else ""


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


## What a tap on `id` would do. `st` is {car, cars (id -> day), nitro (bool), tune (id -> level)}:
## cars: "on" (on the road now), "switch" (owned: free), "buy", "short"; nitro: "owned", "buy",
## "short"; parts: "max", "buy" (the next level), "short"; "" for an unknown id.
static func rule(id: String, zl: int, st: Dictionary) -> String:
	match kind(id):
		"car":
			if id == str(st.get("car", DEFAULT_CAR)):
				return "on"
			if id == DEFAULT_CAR or (st.get("cars", {}) as Dictionary).has(id):
				return "switch"
		"nitro":
			if bool(st.get("nitro", false)):
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
