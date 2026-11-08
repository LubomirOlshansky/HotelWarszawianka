extends RefCounted
## "Kawowy rajd" · the coffee run (F, 2026-11-06; docs/design/coffee-run.md). Zuzia, your bestie
## (psiapsi), phones: a coffee run in Powiśle, now. Drive to the ROWERILO dock by Elektrownia, leave
## the car there and take a city bike, then ride to four specialty cafés below the escarpment and
## get a stamp (pieczątka) in the PASZPORT KAWOWY at each, buying an overpriced coffee every time,
## all in COFFEE_LIMIT. Then ride the bike back to the dock and get the car back. On time: Zuzia
## pays you back for the coffees by BLIK, plus a bit for the company; late: she drank yours.
##
## The cafés are parodies of real new specialty places in Powiśle (2025-26 openings; the real names
## are in brand_denylist.json and never shown): KROPKA. (a coffee & matcha bar on Leszczyńska),
## STORCZYK (Tamka's filter-coffee place), MANTRA (the cloud-coffee and matcha bar by the metro on
## Elektryczna); GLON NA POWIŚLU is the game's own matcha place (places.json `glon_dobra`).
## Doors are the OSM address points' doors (centrum.json pois `address`); Glon's is its place.
## This script is the data and the arithmetic only; trend_job.gd runs the job (kind "kawa").

## The run's tint: a latte brown, unlike the other jobs' pinks, greens and teals.
const COLOUR := Color("#c98a4b")
## The ROWERILO dock by Elektrownia Powiśle (centrum.json pois `bicycle_rental`).
const DOCK := Vector2(284.7, -805.8)
## Seconds for the four stamps, from the bike leaving the dock (about 1.6 km by road at
## BIKE_TOP 8.5 m/s is ~190 s, plus the stamps and the corners) *guess*.
const COFFEE_LIMIT := 300.0
## The camera's view on the bike, a share of the player's own (main.gd's follow camera): the bike
## is a small thing at the car's 80 m view.
const BIKE_VIEW := 0.55
## Stand this long in a café's ring for the stamp (the car's stop rules).
const STAMP_HOLD := 1.5
## The call: 8:00-19:00 (cafés close early, the third wave sleeps in), after FIRST s of play, then
## every COOL s.
const HOURS := [8.0, 19.0]
const FIRST := 420.0
const COOL := 1500.0
## After a run Zuzia rests this long before she walks up at the dock again (the quest map).
const REST := 300.0
## Pay: Zuzia returns what you paid (on time) plus THANKS zł and RESPECT; late, half back, nothing
## more. A stamp the wallet can't afford is "na koszt Zuzi" (she BLIKs it there and then).
const THANKS := 40
const RESPECT := 20
const CALLER := "Zuzia"

## The stops in order: id, name on the card, the drink [pl, en], its price (zł), the door (map x, z;
## Vector2.INF: the place `place`'s position), the stamp's line [pl, en].
const STOPS := [
	{"id": "kropka", "name": "KROPKA.", "place": "", "door": Vector2(178.1, -769.8), "price": 29,
		"drink": ["matcha latte z kropką", "a matcha latte with a dot"],
		"line": ["Kropka nad i. I kropka na rachunku: 29 zł.", "A dot over the i. And a dot on the bill: 29 zł."]},
	{"id": "glon", "name": "GLON NA POWIŚLU", "place": "glon_dobra", "door": Vector2.INF, "price": 31,
		"drink": ["ceremonialna matcha", "ceremonial matcha"],
		"line": ["Ceremonia trwa sześć minut. Masz trzy. Barista płacze.", "The ceremony takes six minutes. You have three. The barista cries."]},
	{"id": "storczyk", "name": "STORCZYK", "place": "", "door": Vector2(49.0, -326.6), "price": 27,
		"drink": ["przelew V60, Etiopia", "a V60 pour-over, Ethiopia"],
		"line": ["Nuty jaśminu i bergamotki. Smakuje jak herbata. Tak ma być.", "Notes of jasmine and bergamot. Tastes like tea. It's meant to."]},
	{"id": "mantra", "name": "MANTRA", "place": "", "door": Vector2(378.9, -595.7), "price": 34,
		"drink": ["kawa z chmurką", "cloud coffee"],
		"line": ["Chmurka to piana z cukru. Płacisz za pogodę: 34 zł.", "The cloud is sugar foam. You're paying for the weather: 34 zł."]},
]

## Zuzia's lines while you ride, one every LINE_EVERY s, in order (third-wave jokes) [pl, en].
const LINE_EVERY := 22.0
const RIDE_LINES := [
	["Trzecia fala? Ja jestem przy czwartej kawie.", "Third wave? I'm on my fourth coffee."],
	["Barista pyta: V60, Chemex czy Aeropress? Mówisz: kawa.", "Barista asks: V60, Chemex or Aeropress? You say: coffee."],
	["Mleko owsiane +4 zł. Owies kosztuje 3 zł za kilo.", "Oat milk +4 zł. Oats cost 3 zł a kilo."],
	["Jasne palenie. Smakuje jak cytryna. Podobno tak ma być.", "Light roast. Tastes like lemon. Apparently that's the point."],
	["Single origin: jedna farma, jeden krzak, jedno ziarenko.", "Single origin: one farm, one bush, one bean."],
	["Przelew parzy się 4 minuty. Twój czas leci szybciej.", "A pour-over brews for 4 minutes. Your clock runs faster."],
	["Kubek z przegródką na ego. Gratis.", "A cup with a sleeve for your ego. Free."],
	["Filtrowana, bo espresso jest dla boomerów.", "Filter, because espresso is for boomers."],
]

## The quest map (story_quests.gd): Zuzia waits at the dock and walks up, in person [pl, en].
const HELLO := ["„Psiapsi, jesteś! Rowery stoją, paszport kawowy mam. Cztery kawiarnie, pięć minut. Jedziemy?”",
		"\"Bestie, you made it! The bikes are here, I've got the coffee passport. Four cafés, five minutes. Shall we?\""]
const CLOSED := ["„Kawiarnie już zamknięte, trzecia fala śpi. Wpadnij rano, od ósmej”",
		"\"The cafés are shut, the third wave's asleep. Come by in the morning, from eight\""]

## The call card's text [title, body pl, body en].
static func call_text() -> Array:
	return ["📞 %s DZWONI" % CALLER.to_upper(),
		"„Psiapsi! Kawowy rajd po Powiślu, teraz! Weź rower z ROWERILO przy Elektrowni, zbieramy pieczątki w czterech kawiarniach. Kawa droga, ale jaka estetyka!”",
		"\"Bestie! A coffee run round Powiśle, now! Grab a ROWERILO bike by Elektrownia, we collect stamps at four cafés. The coffee's pricey, but the aesthetic!\""]


## Where stop `i` is (map x, z), given the places' positions (main.gd's places dict).
static func stop_at(i: int, places: Dictionary) -> Vector2:
	var st: Dictionary = STOPS[i]
	var door: Vector2 = st["door"]
	if door == Vector2.INF:
		return places.get(str(st["place"]), Vector2.INF)
	return door


## What the four coffees cost together (zł).
static func bill() -> int:
	var n := 0
	for st: Dictionary in STOPS:
		n += int(st["price"])
	return n


## The pay at the end: {zl, respect, back}. `paid` what the wallet paid for the coffees itself.
static func pay(paid: int, on_time: bool) -> Dictionary:
	if on_time:
		return {"zl": paid + THANKS, "respect": RESPECT, "back": paid}
	var back := roundi(paid * 0.5)
	return {"zl": back, "respect": 0, "back": back}


## The stamp count for the cards: "2/4" (the HUD's font has no circles).
static func stamps(n: int) -> String:
	return "%d/%d" % [n, STOPS.size()]
