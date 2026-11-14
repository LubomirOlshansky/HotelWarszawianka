extends "res://scripts/activity.gd"
## Named rival drivers cruising the city in their own cars, and street races
## against them. Pull up close behind a rival while both of you are moving and a
## FLASH LIGHTS button appears (key L). Flash, and the rival names a finish at a
## real place in the map, counts down 3-2-1 and races there along the shortest
## path on the lane graph, chancing some red lights. Take any route you like. The
## race shows a beacon, the edge arrow, the distance and who is in front; a card
## and a trash-talk bubble end it. A win pays the rival's stake in złoty and
## respect (wallet.gd). Only one activity at a time: no race while a rescue
## mission or another activity of the kit runs, and rescue calls wait while a race is on.
##
## All characters are made up; the jokes are about the city, not about anyone.
##
## An activity of the kit (activity.gd, tech-debt TD-1): CRUISE and PROMPT are its idle phase (no
## call: a rival is met on the road), CHALLENGE to RESULT its run, the result card the kit's own; the
## director (activities.gd) says whether another activity is on (`free_now`) or a job's request card
## is up (`request_up`).
##
## Loop 3h slice 3: the rival ladder (ladder.gd: the order Halina 60 -> Mike 300 zł, each rung opened
## by the one before and by respect) and the final race "Trzy mosty" (trzy_mosty.gd: the route).
## A locked rival still shows the prompt behind it, labelled with what is missing, and flashing
## gets a refusal bubble. Each rung's rival races at its own pace. Once the final is open, at
## night Seba waits at Rondo Daszyńskiego (the race beacon there and a diamond on the minimap);
## drive into it for his challenge and the countdown, then over three bridges (ordered checkpoints:
## the beacon on the next one) to the National Stadium. Checked at 5 Hz (START_EVERY), no per-frame
## scans. The win pays Ladder.FINAL_ZL and FINAL_GAIN and records `trzy_mosty` in the save.

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const Lang := preload("res://scripts/lang.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Models := preload("res://scripts/models.gd")
const Ladder := preload("res://scripts/ladder.gd")
const TrzyMosty := preload("res://scripts/trzy_mosty.gd")
const Districts := preload("res://scripts/districts.gd")
const RouteLine := preload("res://scripts/route_line.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")
const RacePlanner := preload("res://scripts/race_planner.gd")
const RaceSignals := preload("res://scripts/race_signals.gd")
const RaceReport := preload("res://scripts/race_report.gd")
const RaceSession := preload("res://scripts/race_session.gd")

const CHALLENGE_RANGE := 15.0
## The finish margin's metres are at most the straight line to the finish times this.
const MARGIN_DETOUR := 1.4
const RACE_COLOUR := Color("#ff4fd8")
const WIN_COLOUR := Color("#56d68a")
const LOSE_COLOUR := Color("#e2574c")
## Loop 3h slice 3: a locked rival's prompt, the final's colour (beacon, diamond, cards), the start
## marker's ring (m) and how often the start and the checkpoints are looked at (5 Hz).
const LOCKED_COLOUR := Color("#9a93ab")
const FINAL_COLOUR := Color("#ffcf3a")
const START_RADIUS := 10.0
const START_EVERY := 0.2
## Seba is moved to the start only when the player is at least this far from both spots (unseen).
const WAIT_UNSEEN := 180.0
## Loop 3h slice 3: Seba's words for the final, [Polish, English] (each at most 70 characters).
const FINAL_LINES := {
	"wait": ["Czekam, mordo. Trzy mosty, jedna noc. Wjedź w światło.", "Waiting, buddy. Three bridges, one night. Drive into the light."],
	"challenge": ["Trzy mosty, mordo. Kto pierwszy pod Narodowym, ten król.", "Three bridges, buddy. First to the Stadium is king."],
	"win": ["Wisła jest moja, mordo. Trzy razy ci to pokazałem.", "The Vistula's mine, buddy. Showed you three times."],
	"lose": ["Szacun, mordo. Dziś cała Warszawa jest twoja.", "Respect, buddy. Tonight the whole of Warsaw is yours."],
}

## Loop 3h slice 4 (docs/DEMO.md 6.2, 1:30): the guided first race. After the first delivery Pani
## Halina (the ladder's first rung) rolls up behind the player and flashes (`call_first`); flash
## back and she races to the Palm (FIRST_FINISH, ~800 m from the Rotunda's side of the centre).
## The racer AI rebuild, step 2 (docs/design/race-ai.md 6, 2026-11-10; F three times, last on
## 2026-11-09: "she was still going very slow, and like the mob"): she used to pace off the
## player's own progress so that an ordinary drive won narrowly, and that script was the crawl.
## Now she drives the gentlest skill in the game (ladder.gd FIRST_RACER, her gentle day) at her
## own pace from the line to the Palm, whatever the player does. A player who races beats her; one
## who drives at town pace or stops loses, as to any racer (the guide counts the beat as done
## either way), and every loss in a row makes the next race against her a little easier (ladder.gd
## `ease_of`), on the gentle day until she has been beaten once (`gentle`). The win counts as her
## rung beaten (ladder.gd).
const FIRST_FINISH := "Rondo de Gaulle'a (the Palm)"
## The last stretch to the Palm: no stall nudge on it (`first_stall_due`), the finish is in sight.
const FIRST_EASE := 140.0
## Effort, the finish's circle and the race's mechanics are the race session's (race_session.gd,
## racer AI step 6b): one `_race_session` a race, its one racer the rival (`_racer`).
## A plan made for another traffic than the town has now is made again before the start
## (RaceSession.PLAN_STALE, `_plan_tick`), no later than this many seconds into the countdown (a
## plan is up to 52 slices: a second at 60 frames a second, and the countdown is three).
const PLAN_STALE_UNTIL := 1.0
## What a rival says when it does something human (traffic.gd counts it), [Polish, English] (each
## at most 70 characters), only within HUMAN_NEAR m of the player and HUMAN_QUIET s after its last line.
const HUMAN_NEAR := 120.0
const HUMAN_QUIET := 6.0
const HUMAN_LINES := {
	"cut": [["Skrótem, kierowniku!", "Shortcut, boss!"], ["Kto zna miasto, ten nie jeździ ulicami!", "Know the city, skip the streets!"]],
	"cut_zbyszek": [["Ten skrót znam od osiemdziesiątego siódmego!", "Known this shortcut since '87!"], ["Przez plac, szefie, jak za dawnych lat!", "Across the square, chief, like the old days!"]],
	"cut_halina": [["Babcia zna drogę na bazar na skróty!", "Granny knows the shortcut to the bazaar!"], ["Przepraszam, gołąbki! Babcia się spieszy!", "Sorry, pigeons! Granny's in a hurry!"]],
	"wrong": [["Nawigacja mówi: zawróć. Mama mówi: jedź prosto!", "Satnav says turn back. Mum says go straight!"], ["To nie ta ulica? Wszystkie tu takie same!", "Wrong street? They all look the same here!"]],
	"mistake": [["Ups, za szybko!", "Whoops, too fast!"], ["Ten zakręt wczoraj był łagodniejszy!", "That corner was gentler yesterday!"]],
	"mistake_halina": [["Jezus Maria, ten zakręt!", "Good Lord, that corner!"], ["Za moich czasów zakręty były prostsze!", "In my day the corners were straighter!"]],
	"block": [["Nie tędy, mordo!", "Not this way, buddy!"], ["Zajęte, mordo, szukaj innej drogi!", "Taken, buddy, find another way!"]],
	"phone": [["Halo? Nie teraz, jestem na wyścigu… znaczy na callu!", "Hello? Not now, I'm in a race... I mean a call!"]],
}
## The Palm is the finish when it is at most this far by road from her; else an ordinary one.
const FIRST_FAR := 1600.0
## She rolls up from about FIRST_BACK m behind; the prompt waits FIRST_WAIT s for the flash, or
## until the player is FIRST_AWAY m from her; she gives up rolling up after FIRST_ROLL s.
const FIRST_BACK := 45.0
const FIRST_WAIT := 20.0
const FIRST_AWAY := 90.0
const FIRST_ROLL := 12.0
## PT-8 (2026-11-02): she is put only on a lane within FIRST_SNAP m that runs the way the car
## faces, at a point really behind it; with none (the wrong way up a one-way, off the road, or a
## lane that starts just ahead) `call_first` waits and first10.gd asks again. At the end of
## one-way Hoża by Mokotowska, facing west, it snapped (40 m reach) to two-way Hoża's westbound
## lane starting 9 m AHEAD; `_behind` found no way in behind that lane's start and stopped there,
## so she stood held 12 m in front of the car on the 3 m street (no room to pass) and the car
## crawled into her at a wall's 6-7 km/h for the whole 20 s prompt.
const FIRST_SNAP := 15.0
## PT-11 (the design half): after START! in the first race she waits at the line until the player
## moves (faster than FIRST_MOVE m/s) or FIRST_HOLD s pass, so a new player who doesn't yet know to
## drive is not left behind. Still after FIRST_IDLE s: the GO nudge (the banner GAZ!, the ghost
## finger on the stick, her line "go"). Stopped (slower than FIRST_STOP m/s) for FIRST_STALL s
## mid-race, more than FIRST_EASE m from the Palm: the "stall" nudge, at most FIRST_STALLS times.
const FIRST_HOLD := 12.0
const FIRST_IDLE := 2.0
const FIRST_MOVE := 3.0
const FIRST_STOP := 1.5
const FIRST_STALL := 5.0
const FIRST_STALLS := 2
## The nudge banner's words (Polish only, like WYŚCIG and START!) and how long it stays (s).
const FIRST_GO_BANNER := "GAZ! JEDŹ ZA STRZAŁKĄ"
const FIRST_GO_BANNER_S := 3.0
## Her words for it, [Polish, English] (each at most 70 characters).
const FIRST_LINES := {
	"call": ["Dziecko drogie! Babcia mruga. Do Palmy, kto pierwszy?", "Kiddo! Granny's flashing you. Race you to the Palm?"],
	"nudge": ["Mrugnij, dziecko. Babcia nie ma całego dnia.", "Flash back, kiddo. Granny hasn't got all day."],
	"gone": ["Ech, ta młodzież. To innym razem.", "Kids these days. Another time, then."],
	"go": ["No jedź, dziecko! Gaz i za różową strzałką!", "Go on, kiddo! Step on it and follow the pink arrow!"],
	"stall": ["Co tak stoisz? Palma sama nie przyjdzie!", "Why have you stopped? The Palm won't come to you!"],
}

## Each rival: name, tag colour, car style (models.gd), box size, and lines as
## [Polish, English]. Challenges carry the finish: {pl} / {en}.
const RIVALS := [
	{"name": "Seba z Pragi", "colour": Color("#b45cff"), "style": 0, "size": Vector3(1.9, 1.3, 4.4), "stake": 150,
		"about": "lowered purple coupe, tracksuit, Praga born and bred",
		"refuse": ["Mordo, najpierw zrób sobie nazwisko na mieście.", "Buddy, make a name for yourself in town first."],
		"approach": ["Co tak siedzisz mi na zderzaku? Mrugnij, jak masz odwagę.", "Why are you on my bumper? Flash your lights if you dare."],
		"challenge": [["Ej, kierowniku, ścigamy się {pl}?", "Hey boss, race you {en}?"],
			["Mordo, {pl}. Kto ostatni, ten stawia kebaba.", "Buddy, {en}. Last one there buys the kebab."]],
		"win": [["Na Pradze się tak jeździ, mordo!", "That's how we drive in Praga, buddy!"],
			["Spoko, następnym razem dam ci fory. Może.", "Chill, next time I'll give you a head start. Maybe."]],
		"lose": [["Ej no, gołąb mi wleciał na maskę!", "Come on, a pigeon landed on my bonnet!"],
			["Szacun. Ale po naszej stronie Wisły nikt mnie nie dogoni.", "Respect. But on our side of the Vistula nobody catches me."]]},
	{"name": "Mordor Mike", "colour": Color("#9fc2e8"), "style": 1, "size": Vector3(1.9, 1.9, 4.7), "stake": 300,
		"about": "office guy from Mordor on Domaniewska, races like it's a deadline",
		"refuse": ["Nie mam cię w kalendarzu. Umów się przez asystentkę.", "You're not in my calendar. Book it through my assistant."],
		"approach": ["Sorry, mam call. Ale jak mrugniesz, to wchodzę w to.", "Sorry, I'm on a call. But flash me and I'm in."],
		"challenge": [["Szybki sprint {pl}? Mam okienko między spotkaniami.", "Quick sprint {en}? I've got a gap between meetings."],
			["Zróbmy z tego deliverable: {pl}, ASAP.", "Let's make it a deliverable: {en}, ASAP."]],
		"win": [["Target dowieziony. Wpisuję to sobie do OKR-ów.", "Target delivered. That goes in my OKRs."],
			["Wyślę ci podsumowanie mailem. Szef w kopii.", "I'll email you a summary. My boss in CC."]],
		"lose": [["Na Domaniewskiej nauczyłem się stać w korku, nie jeździć.", "Domaniewska taught me to sit in traffic, not to drive."],
			["Okej, wrzucam to na retro. Lesson learned.", "Okay, that goes in the retro. Lesson learned."]]},
	{"name": "Pani Halina", "colour": Color("#86d3b0"), "style": 2, "size": Vector3(1.6, 1.9, 3.4), "stake": 60,
		"about": "a pensioner who drives far too fast, late for the bazaar",
		"refuse": ["Dziecko, najpierw obiad, potem wyścigi.", "Kiddo, dinner first, then racing."],
		"approach": ["Dziecko, nie siedź mi tak na ogonie, babcia się spieszy!", "Kiddo, don't tailgate me, Granny's in a hurry!"],
		"challenge": [["Spieszę się {pl}. Dogonisz babcię?", "I'm in a hurry {en}. Can you catch Granny?"],
			["Promocja na ogórki się kończy! Jedziemy {pl}!", "The pickle sale is ending! We're going {en}!"]],
		"win": [["W moich czasach to się jeździło, a nie wlokło!", "In my day we drove, we didn't crawl!"],
			["Zjedz coś, dziecko, bo blade jesteś i wolne.", "Eat something, kiddo, you're pale and slow."]],
		"lose": [["Ech, to przez te nowe progi zwalniające.", "Oh, it's those new speed bumps."],
			["Dobre dziecko. Masz tu pierogi na drogę.", "Good kid. Here, have some pierogi for the road."]]},
	{"name": "Słoik z Radomia", "colour": Color("#ffb05a"), "style": 3, "size": Vector3(2.0, 3.0, 5.2), "stake": 90,
		"about": "a newcomer from Radom with his mum's jars in the van",
		"refuse": ["Mama mówi, żebym się nie ścigał z byle kim. Sorry.", "Mum says not to race just anyone. Sorry."],
		"approach": ["Przepraszam, którędy na Rondo Dmowskiego? Kręcę się od rana.", "Sorry, which way to Rondo Dmowskiego? I've been going round since morning."],
		"challenge": [["W Radomiu nikt by się nie ścigał. Ale dobra: {pl}!", "Nobody races back in Radom. But fine: {en}!"],
			["Mam w bagażniku słoiki od mamy. Ostrożnie, ale szybko: {pl}!", "Mum's jars are in the back. Carefully, but fast: {en}!"]],
		"win": [["Słoik też potrafi! Mama będzie dumna.", "A słoik can do it too! Mum will be proud."],
			["Warszawka myśli, że zna skróty. A ja mam nawigację i bigos.", "You Warsaw lot think you know the shortcuts. I've got a satnav and bigos."]],
		"lose": [["Zgubiłem się na Rondzie Dmowskiego. Trzy razy.", "I got lost on Rondo Dmowskiego. Three times."],
			["Dobra, wracam na weekend do Radomia odpocząć.", "Fine, I'm off to Radom for the weekend to recover."]]},
	{"name": "Taksiarz Zbyszek", "colour": Color("#f3c72b"), "style": 4, "size": Vector3(1.9, 1.9, 4.8), "stake": 200,
		"about": "a taxi driver since 1987 who knows every shortcut",
		"refuse": ["Szefie, z amatorami nie jeżdżę. Nawet na liczniku.", "Chief, I don't race amateurs. Not even on the meter."],
		"approach": ["Kurs, szefie? Bo jak nie, to ja nie trąbię, tylko jadę.", "Need a ride, chief? If not, I don't honk, I drive."],
		"challenge": [["Kurs {pl}? Na liczniku czy na wyścigi?", "A fare {en}? On the meter, or racing?"],
			["Znam każdy skrót od osiemdziesiątego siódmego. Jedziemy {pl}!", "I've known every shortcut since '87. Let's go {en}!"]],
		"win": [["Należy się: zero złotych i lekcja jazdy.", "That'll be zero złoty and a driving lesson."],
			["Marszałkowską znowu rozkopali, a ja i tak pierwszy.", "They've dug up Marszałkowska again, and I'm still first."]],
		"lose": [["Pierwszy raz od lat ktoś mnie przegonił. Szacunek.", "First time in years someone beat me. Respect."],
			["Gdyby nie korek na Moście Poniatowskiego, byłoby inaczej.", "If not for the jam on Poniatowski Bridge, it'd be a different story."]]},
	{"name": "Bulwar Bartek", "colour": Color("#7cff3a"), "style": 5, "size": Vector3(1.8, 1.9, 3.9), "stake": 120,
		"about": "a party guy from the Vistula boulevards with a speaker on the roof",
		"refuse": ["Nie ma cię na liście gości, ziomek. Wpadnij później.", "You're not on the guest list, mate. Come back later."],
		"approach": ["Słyszysz ten bas? Mrugnij, to podkręcę.", "Hear that bass? Flash me and I'll turn it up."],
		"challenge": [["Impreza na bulwarach się zaczyna! Ścigamy się {pl}?", "The party on the boulevards is starting! Race you {en}?"],
			["Najlepszy widok na Warszawę jest z Pałacu, bo nie widać Pałacu. Jedziemy {pl}!", "The best view of Warsaw is from the Palace, because you can't see the Palace. Let's go {en}!"]],
		"win": [["Bas siedzi, wynik siedzi!", "The bass hits, and so does the result!"],
			["Wygrałem, a gołębie z Placu Defilad biły brawo.", "I won, and the pigeons on Plac Defilad applauded."]],
		"lose": [["Muzyka była za głośno, nie słyszałem startu.", "The music was too loud, I didn't hear the start."],
			["Dobra, dobra. Rewanż nad Wisłą, o wschodzie słońca.", "Fine, fine. Rematch by the Vistula, at sunrise."]]},
]

## Race finishes at real places. `find`: a landmark outline, a road name (the
## middle of its nodes), a road's east end, or a point of interest.
const FINISHES := [
	{"name": "Pałac Kultury i Nauki", "pl": "do Pałacu", "en": "to the Palace", "landmark": "Pałac Kultury i Nauki"},
	{"name": "Rondo Dmowskiego", "pl": "na Rondo Dmowskiego", "en": "to Rondo Dmowskiego", "road": "Rondo Romana Dmowskiego"},
	{"name": "Stadion Narodowy", "pl": "pod Narodowy", "en": "to the National Stadium", "poi": "stadium"},
	{"name": "Most Poniatowskiego, east end", "pl": "na koniec Mostu Poniatowskiego", "en": "to the far end of Poniatowski Bridge", "road_east": "Most Księcia Józefa Poniatowskiego"},
	{"name": "Rondo de Gaulle'a (the Palm)", "pl": "pod Palmę", "en": "to the Palm", "road": "Rondo Generała Charles'a de Gaulle'a"},
	{"name": "Plac Trzech Krzyży", "pl": "na Plac Trzech Krzyży", "en": "to Plac Trzech Krzyży", "road": "Plac Trzech Krzyży"},
	{"name": "Centrum Nauki Kopernik", "pl": "pod Kopernika", "en": "to the Copernicus Science Centre", "landmark": "Centrum Nauki Kopernik"},
	{"name": "Złote Tarasy", "pl": "pod Złote Tarasy", "en": "to Złote Tarasy", "landmark": "Złote Tarasy"},
	{"name": "Rondo ONZ", "pl": "na Rondo ONZ", "en": "to Rondo ONZ", "road": "Rondo ONZ"},
	{"name": "Varso Tower", "pl": "pod Varso", "en": "to Varso Tower", "landmark": "Varso Tower"},
	{"name": "Dworzec Powiśle", "pl": "pod Dworzec Powiśle", "en": "to Powiśle station", "landmark": "Dworzec PKP Powiśle"},
]

enum State { CRUISE, PROMPT, CHALLENGE, COUNTDOWN, RACE, RESULT }

var graph: LaneGraph
var traffic: Traffic
var bubbles: Control
var missions: Node
var state := State.CRUISE
## Rival in the current prompt or race.
var rival := -1
## Testing (--autopilot, the kit's `autopilot`): the player's car follows a ghost driver in
## races, and tails `tail` (a rival index) before one.
## The autopilot's speed factor in a race (main.gd --ghost-pace): 1.8 an average player; over 10
## (--ghost-pace=racer) a skilled player in racer mode.
var ghost_pace := 1.8
var tail := -1
## Set by the game each frame.
var flying := false
## Loop MW-6: Spacer (spacer.gd): the rivals don't call out their challenge (the prompt still
## shows behind one; flashing the lights still starts the race).
var quiet := false
## Loop 3g-2 (police.md 8.2): the player escaped the police during this race: a win pays the
## stake x 1.2 (police.gd sets it; start_race clears it).
var escape_bonus := false
const ESCAPE_BONUS := 1.2
## Loop 3h slice 3: the rival ladder (its order, gating and record: wallet.gd `ladder`), the time of
## day (time_of_day.gd: the final waits for the night; null: never night) and the final's route
## (null if the map has no such bridges).
var ladder: Ladder
var tod: Node
var final_route: TrzyMosty
## The race on now is the final "Trzy mosty".
var final_on := false

## Loop 3h slice 3: the final's state: checkpoints the player has passed (0-3) and the ghost's leg
## (index into final_route.legs). Seba's leg, the legs' distances (computed one a frame during the
## challenge and the countdown) and the metres left after each leg are the session's racer's.
var _cp := 0
var _ghost_leg := 0
## Seba's index in RIVALS; he waits at the start (held there); the start marker (beacon and
## diamond) is shown; the 5 Hz clock.
var _seba := -1
var _seba_waiting := false
var _marker_on := false
var _start_t := 0.0
## The first start look after setup may move Seba in sight (nothing is on screen yet); the leg the
## final starts on (0; --trzy-mosty=N: the span of bridge N, 2N - 1).
var _first_look := true
var _start_leg := 0
## --trzy-mosty=N: the ghost's lane spot on the span ([edge, lane, s]; a snap could pick the
## embankment road under the bridge).
var _ghost_spot: Array = []
## The ladder's open count last seen (a new rung's toast when it grows; -1: not looked yet).
var _open_seen := -1

var _drivers: Array = []
var _nodes: Array[Node3D] = []
## Racer AI step 6a (race_signals.gd): each rival's body (the car's meshes: it swings on a
## mistake while the driver's own place and heading stay the traffic's) and its lamps; the racing
## rival's lights this race, and whether any lamp may be lit (so they are put out once).
var _bodies: Array[Node3D] = []
var _signals: Array[Node3D] = []
var _sig := RaceSignals.State.new()
var _sig_on := false
## Step 6a: this race's report (race_report.gd: both cars' ways and what decided the race), for
## the result card; and the size of the card's picture of the two ways (points).
var _report := RaceReport.new()
## Whether the result card carries the report's lines too (off: F, 2026-11-13; the picture stays).
const REPORT_LINES := false
const REPORT_ART := Vector2(150.0, 104.0)
var _cooldown := PackedFloat32Array()
var _said := PackedFloat32Array()
var _finishes: Array[Dictionary] = []
var _finish: Dictionary = {}
## A street race's distances to its finish (the session's racer's, for the player's metres).
var _dist := PackedFloat32Array()
## Finish node -> driving distances to it from every node (computed once each; the sessions share it).
var _dist_to := {}
## The city's shortcuts (race_cuts.gd) and the route planner (race_planner.gd, docs/design/race-ai.md
## 5), one each for the map.
var _cuts: RaceCuts
var _planner: RacePlanner
## Racer AI step 6b: this race's session (race_session.gd: the course, the rival's shortcuts,
## distances, plans, effort and lights; its plans searched a slice a frame from the challenge on, so
## the start costs no frame) and its one racer, the rival (null: no race yet).
var _race_session: RaceSession
var _racer: RaceSession.Racer
## The roads through this race's finish circle (RacePlanner.ends; in the final its last leg's,
## the finish by the stadium: a checkpoint has its own rule): the rival's plan ends on them, the
## metres left and the route on the minimap go to where each one enters the circle, and a car on
## one is home level with the circle (`home_at`), for both cars.
var _ends := {}
var _seen_cuts := 0
var _seen_mistakes := 0
var _seen_wrong := 0
var _seen_blocks := 0
var _phone_at := INF
## Seconds since the race's last step (the challenge, the countdown, the start); the rivals' lines
## are timed by it too (`_said`), as before.
var _stage_t := 0.0
var _race_time := 0.0
var _races := 0
var _lost_sight := 0.0
var _player_left := 0.0
var _rival_left := 0.0
var _rank_timer := 0.0
var _ghost = null
var _rng := RandomNumberGenerator.new()
## Loop 3h slice 4: the rival rolling up for the guided first race (-1: none), how long it has
## been (s), and whether the prompt has nudged; `first_race` while that race runs, and
## `first_result` ("won", "lost", "declined") once it is over (first10.gd reads it).
var _caller := -1
## How much an easier rematch slowed this race's rival (0 .. EASE_MAX; its stats and effort are
## the session's racer's).
var _race_ease := 0.0
## Beta values (2026-11-04, docs/design/beta-values.md): the race shown better (street races R5):
## the way to the finish (or the next bridge) on the minimap, the gap in seconds, a lead change said
## once, and the finish's margin in seconds on the card.
var _route: RouteLine
var _route_cp := -1
## Who leads now (true: the player) as last said, the seconds since, and the two speeds smoothed (m/s).
var _lead_player := true
var _lead_known := false
var _lead_said := 0.0
var _v_player := 0.0
var _v_rival := 0.0
## A lead changes hands only past this many metres the other way (no flicker side by side), and is
## said at most once in LEAD_GAP s.
const LEAD_MARGIN := 8.0
const LEAD_GAP := 6.0
## Side by side: the gap reads "łeb w łeb" under this many metres.
const LEVEL_M := 6.0
## The time gap's speed floor (m/s): standing still, the trailing car would never get there.
const GAP_FLOOR := 8.0
var _call_t := 0.0
var _call_up := false
var _nudged := false
var first_race := false
var first_result := ""
## PT-11: the first race's start hold and nudges: she waits at the line (`_first_hold`), the GO
## nudge given, how long the car has stood still mid-race (s), the stall nudges given, and the
## seconds left on the nudge banner.
var _first_hold := false
var _go_nudged := false
var _stall_t := 0.0
var _stalls := 0
var _nudge_banner_t := 0.0


## The kit's `_init`: the log's name, the race's colour and the beacon's dark.
func _init() -> void:
	tag = "rival race"
	colour = RACE_COLOUR
	dark = Color("#2b2c2f")


## main.gd sets graph, traffic, hud, bubbles, missions, map, car, wallet, tod, autopilot and
## ghost_pace before this.
func setup(world: Node3D, data := {}) -> void:
	_rng.seed = 7
	_find_finishes(data)
	_cuts = RaceCuts.new()
	_cuts.load_cuts(graph)
	print("rivals: %d shortcuts (%d of %d unmatched)" % [_cuts.a.size(), _cuts.missed, _cuts.total])
	_planner = RacePlanner.new(graph)
	# Loop 3h slice 3: the ladder and the final's route.
	ladder = Ladder.new()
	ladder.wallet = wallet
	final_route = TrzyMosty.new()
	if not final_route.build(graph, data):
		push_warning("rivals: no route for Trzy mosty: %s" % final_route.error)
		final_route = null
	else:
		print("rivals: Trzy mosty: %s, start %.0f, %.0f, finish %.0f, %.0f" % [" → ".join(final_route.checkpoints.map(
				func(c: Dictionary) -> String: return str(c["pl"]))), final_route.start_pos.x, final_route.start_pos.z,
				final_route.finish["pos"].x, final_route.finish["pos"].z])
	if wallet != null:
		_open_seen = ladder.open_count()
		wallet.changed.connect(func(_zl: int, _r: int, _g: int) -> void: _check_ladder())
	super.setup(world)
	_beacon.pattern = Beacon.Pattern.CHEQUER  # colour-safe: a finish line (beacon.gd)
	_beacon.waving = true
	_cooldown.resize(RIVALS.size())
	for i in RIVALS.size():
		if RIVALS[i]["name"] == "Seba z Pragi":
			_seba = i
	_said.resize(RIVALS.size())
	_said.fill(-100.0)
	var spawn := Vector2(car.global_position.x, car.global_position.z)
	var taken := PackedVector2Array([spawn])
	for i in RIVALS.size():
		var r: Dictionary = RIVALS[i]
		var node := Node3D.new()
		var body := Node3D.new()
		body.name = "body"
		node.add_child(body)
		var mi := MeshInstance3D.new()
		mi.mesh = Models.rival_mesh(r["style"])
		mi.material_override = Models.material()
		body.add_child(mi)
		if r["style"] == 0:
			# Seba's neon underglow.
			var glow := MeshInstance3D.new()
			var slab := BoxMesh.new()
			slab.size = Vector3(2.1, 0.05, 4.5)
			glow.mesh = slab
			var neon := StandardMaterial3D.new()
			neon.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			neon.albedo_color = Color("#38f6ff")
			glow.material_override = neon
			glow.position.y = 0.09
			glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			body.add_child(glow)
			# At night it spills onto the road.
			var spill := MeshInstance3D.new()
			spill.mesh = _underglow_pool()
			spill.material_override = Models.glow_material()
			spill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			spill.visible = false
			spill.add_to_group("night_lights")
			body.add_child(spill)
		# Headlights and tail lights on the road at night.
		var beams := MeshInstance3D.new()
		beams.mesh = Models.headlight_pools((r["size"] as Vector3).z * 0.5)
		beams.material_override = Models.glow_material()
		beams.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beams.visible = false
		beams.add_to_group("night_lights")
		body.add_child(beams)
		# Step 6a: its brake lights, indicators and headlight flash (hidden until one is lit).
		var lamps := RaceSignals.build(r["size"])
		body.add_child(lamps)
		_bodies.append(body)
		_signals.append(lamps)
		world.add_child(node)
		_nodes.append(node)
		# The first rival cruises near the start so the race is easy to find.
		var spot := _spot(spawn, 140.0, 320.0) if i == 0 else _spot_apart(taken)
		taken.append(graph.point_at(spot[0], spot[2]))
		var d = traffic.add_node_driver(node, r["size"], spot[0], spot[1], spot[2])
		_drivers.append(d)
	hud.challenge_pressed.connect(flash)
	traffic.bumped_driver.connect(_on_bumped)
	traffic.turned_back.connect(_on_turned_back)
	traffic.hop_refused.connect(_on_hop_refused)


## Seba's underglow on the road: a cyan oval round the car.
func _underglow_pool() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 16
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		for v in [[Vector3(0, 0.1, 0), 0.5], [Vector3(cos(a0) * 2.4, 0.1, sin(a0) * 3.6), 0.0], [Vector3(cos(a1) * 2.4, 0.1, sin(a1) * 3.6), 0.0]]:
			st.set_color(Color(0.1, 0.85, 1.0, v[1]))
			st.set_normal(Vector3.UP)
			st.add_vertex(v[0])
	return st.commit()


## A lane on a main road between `lo` and `hi` metres from p: [edge, lane, s].
func _spot(p: Vector2, lo: float, hi: float) -> Array:
	for attempt in 400:
		var e := _rng.randi() % graph.e_a.size()
		if graph.e_class[e] > 1 or graph.node_scc[graph.e_a[e]] == 0 or graph.node_scc[graph.e_b[e]] == 0:
			continue
		if graph.e_s1[e] - graph.e_s0[e] < 20.0:
			continue
		var s := _rng.randf_range(graph.e_s0[e] + 5.0, graph.e_s1[e] - 5.0)
		var d := graph.point_at(e, s).distance_to(p)
		if d >= lo and d <= hi:
			return [e, _rng.randi() % graph.e_lanes[e], s]
	return _spot(p, 0.0, 1e9)


func _spot_apart(taken: PackedVector2Array) -> Array:
	var best: Array = []
	var best_d := -1.0
	for attempt in 30:
		var cand := _spot(Vector2.ZERO, 0.0, 1e9)
		var near := INF
		for q in taken:
			near = minf(near, graph.point_at(cand[0], cand[2]).distance_to(q))
		if near > best_d:
			best_d = near
			best = cand
	return best


## The lane graph node of finish `f` (a FINISHES entry) on `graph`, from the map's `data` (its
## landmarks and points of interest), or -1 if the map has no such place. Static for the race bench.
static func finish_node(graph: LaneGraph, data: Dictionary, f: Dictionary) -> int:
	var target := Vector2.INF
	var node := -1
	if f.has("landmark"):
		var sum := Vector2.ZERO
		var n := 0
		for l in data.get("landmarks", []):
			if l["name"] == f["landmark"]:
				var flat: Array = l["p"]
				for k in range(0, flat.size() - 1, 2):
					sum += Vector2(flat[k], flat[k + 1])
					n += 1
		if n > 0:
			target = sum / n
	elif f.has("poi"):
		for p in data.get("pois", []):
			if p["k"] == f["poi"]:
				target = Vector2(p["x"], p["z"])
	else:
		var key: String = f.get("road", f.get("road_east", ""))
		var sum := Vector2.ZERO
		var n := 0
		var east := -INF
		for e in graph.e_a.size():
			if graph.e_name[e] != key:
				continue
			for m in [graph.e_a[e], graph.e_b[e]]:
				if graph.node_scc[m] == 0:
					continue
				sum += graph.node_pos[m]
				n += 1
				if f.has("road_east") and graph.node_pos[m].x > east:
					east = graph.node_pos[m].x
					node = m
		if n > 0 and not f.has("road_east"):
			target = sum / n
	if node < 0 and target != Vector2.INF:
		node = graph.nearest_node(target)
	return node


func _find_finishes(data: Dictionary) -> void:
	for f in FINISHES:
		var node := finish_node(graph, data, f)
		if node < 0:
			continue
		var p := graph.node_pos[node]
		var entry: Dictionary = f.duplicate()
		entry["node"] = node
		entry["pos"] = Vector3(p.x, map.ground_height(p.x, p.y), p.y)
		_finishes.append(entry)


# --- the flow ------------------------------------------------------------------------

func racing() -> bool:
	return state == State.CHALLENGE or state == State.COUNTDOWN or state == State.RACE


## A race or its result card is up (other activities wait).
## Loop 3g-2: a race is on (past the countdown): the police can see it.
func in_race() -> bool:
	return state == State.RACE


## Loop 3g-2: a race has been run this session and its card is closed (the first contact waits
## for it).
func raced() -> bool:
	return _races > 0 and state == State.CRUISE


## The kit's question: the race's finish is the target from the countdown to the end of the race.
func has_target() -> bool:
	return state == State.COUNTDOWN or state == State.RACE


## The kit's question: the finish, or in the final the next bridge's checkpoint.
func target_position() -> Vector3:
	if final_on:
		return final_target()
	return _finish["pos"]


## The kit's question: the final's own colour, else the race's.
func target_colour() -> Color:
	return FINAL_COLOUR if final_on else RACE_COLOUR


## The kit's question: no stop ring in a race (main.gd gave none).
func stop_spot() -> Vector3:
	return Vector3.INF


## The kit's question: a race's target gets no camera look (main.gd's old call).
func target_source() -> String:
	return "race"


## The kit's question: the race's target is the main line's while the guide runs or for the
## ladder's next rung (main.gd's old `_guide_on() or rivals.main_race()`).
func main_target(guide: bool) -> bool:
	return guide or main_race()


## The kit's question: why the helicopter is refused, [Polish, English], while a race is on.
func grounded() -> Array:
	if racing():
		return ["Najpierw dokończ wyścig", "Finish the race first"]
	return []


## The kit's question: a test run never pressed the race's result card.
func _auto_button() -> int:
	return -1


## The kit's question: the ✕ drops a race only from the countdown to the finish.
func _can_abort() -> bool:
	return state == State.COUNTDOWN or state == State.RACE


## The ✕ (or the clock): given up by the player in the countdown or the race it is the lose card
## (the run ends when it is pressed); otherwise the kit's.
func drop(by_player: bool) -> void:
	if by_player and (state == State.COUNTDOWN or state == State.RACE):
		_finish_race(false, "You gave up.")
		return
	super.drop(by_player)


## Loop 3h slice 3: the final's next point for the player: the next bridge's checkpoint, then the
## stadium.
func final_target() -> Vector3:
	if _cp < final_route.checkpoints.size():
		return final_route.checkpoints[_cp]["pos"]
	return final_route.finish["pos"]


## The L key / FLASH LIGHTS button: challenge the rival in front.
func flash() -> void:
	if state != State.PROMPT:
		return
	car.flash_lights()
	# Loop 3h slice 3: a rival above the ladder's open rungs says no, in their own words.
	if not rung_open(rival):
		var no: Array = RIVALS[rival]["refuse"]
		_say(rival, no[0], no[1], 3.5)
		print("race: %s refused (%s)" % [RIVALS[rival]["name"], ladder.missing(Ladder.rung_of(RIVALS[rival]["name"]))[1]])
		_cooldown[rival] = 8.0
		state = State.CRUISE
		hud.hide_challenge()
		return
	start_race(rival)


## Loop 3h slice 3: rival `i`'s rung is open (a rival outside the ladder, or no wallet: always).
func rung_open(i: int) -> bool:
	if ladder == null or wallet == null:
		return true
	var r := Ladder.rung_of(RIVALS[i]["name"])
	return r < 0 or ladder.is_open(r)


## Challenges rival i at once (also the --race flag): they name a finish, count
## down and go.
func start_race(i: int) -> void:
	_marker(false)
	_release_seba()
	final_on = false
	_beacon.recolour(RACE_COLOUR)
	rival = i
	# Loop 3h slice 4: the rival who rolled up for the guided first race races to the Palm.
	first_race = i == _caller
	_caller = -1
	var d = _drivers[i]
	var t0 := Time.get_ticks_usec()
	_finish = _first_finish() if first_race else {}
	if not _finish.is_empty() and graph.remaining(_distances(_finish["node"]), d.edge, d.s) > FIRST_FAR:
		_finish = {}  # the player is far from the Palm (another stand's order): a nearer finish, the same tuning
	if _finish.is_empty():
		_finish = _pick_finish(d)
	# A course of one leg to the finish's circle; the plan made now, for the town's traffic as it is.
	_new_session(PackedInt32Array([_finish["node"]]))
	_dist = _race_session.distances(_racer, 0)
	_race_session.plan(_racer, 0)
	print("race: %s to %s, %d m by road (picked in %.1f ms)" % [RIVALS[i]["name"], _finish["name"],
			roundi(graph.remaining(_dist, d.edge, d.s)), (Time.get_ticks_usec() - t0) / 1000.0])
	_races += 1
	escape_bonus = false
	state = State.CHALLENGE
	_stage_t = 0.0
	start()
	hud.hide_challenge()
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_card()
	d.held = true
	var r: Dictionary = RIVALS[i]
	var line: Array = r["challenge"][_rng.randi() % 2]
	_say(i, String(line[0]).format(_finish), String(line[1]).format(_finish), 3.0)
	hud.show_banner("WYŚCIG " + String(_finish["pl"]).to_upper(), RACE_COLOUR)


## A finish 600-1800 m away by road (one-way streets can make a near place a long
## drive) and not right next door; failing that, the one nearest to 1.2 km.
func _pick_finish(d) -> Dictionary:
	var from := Vector2(d.pos.x, d.pos.z)
	var fits: Array[Dictionary] = []
	var nearest: Dictionary = _finishes[0]
	var nearest_off := INF
	for f in _finishes:
		var route := graph.remaining(_distances(f["node"]), d.edge, d.s)
		var far := Vector2(f["pos"].x, f["pos"].z).distance_to(from)
		if route >= 600.0 and route <= 1800.0 and far >= 350.0:
			fits.append(f)
		if absf(route - 1200.0) < nearest_off:
			nearest_off = absf(route - 1200.0)
			nearest = f
	if fits.is_empty():
		return nearest
	return fits[(_races * 7 + rival * 3) % fits.size()]


## The roads' own distances to `node` (cached; the race sessions share the cache).
func _distances(node: int) -> PackedFloat32Array:
	if not _dist_to.has(node):
		_dist_to[node] = graph.distances_to(node)
	return _dist_to[node]


## This race's rung (Ladder.FINAL in the final), whether its rival drives Halina's gentle day
## (ladder.gd FIRST_RACER: the guided first race, and every race against her until the player has
## beaten her once), and how much slower an easier rematch makes it (Ladder.ease_of: the races
## the player has lost to this rival in a row): [rung, gentle, ease].
func _tuning() -> Array:
	var rung := Ladder.FINAL if final_on else Ladder.rung_of(RIVALS[rival]["name"])
	var ease := Ladder.ease_of(ladder.lost_streak(rung)) if ladder != null else 0.0
	var gentle := not final_on and (first_race or (ladder != null and ladder.gentle(rung)))
	return [rung, gentle, ease]


## A new race session (race_session.gd) on the junctions `legs`, the last the finish with its
## circle of RaceSession.FINISH_RADIUS m round `_finish_at()`, and rival `rival` its one racer:
## this race's rung (`_tuning`: Halina's gentle day drives ladder.gd FIRST_RACER, an easier rematch
## is eased), the player's car's top speed, the shortcuts its rung knows.
func _new_session(legs: PackedInt32Array) -> void:
	var tuning := _tuning()
	var rung: int = tuning[0]
	_race_session = RaceSession.new()
	_race_session.setup(graph, traffic, _planner, _cuts, _dist_to)
	_race_session.course(legs, _finish_at(), RaceSession.FINISH_RADIUS)
	_racer = _race_session.add(_drivers[rival], String(RIVALS[rival]["name"]), Ladder.FIRST_RACER if tuning[1] else Ladder.racer(rung),
			Ladder.pace(rung), {"top": player_top(), "ease": tuning[2], "cuts_of": Ladder.racer(rung)})
	_ends = _race_session.ends


## The ground point of this race's finish (the final's: its last leg's), the centre of its circle.
func _finish_at() -> Vector2:
	var at: Vector3 = final_route.finish["pos"] if final_on else _finish["pos"]
	return Vector2(at.x, at.z)


## A slice of the race's plan a frame (RaceSession.plan_tick), from the challenge on; a plan made
## for another traffic than the town has now is made again only through the challenge and the
## countdown's first PLAN_STALE_UNTIL s (the traffic setting, the quality's share or the governor
## moved it, or the race was called before they were applied: `--race=`). From then on, and all
## through the race, a rival keeps the plan it has.
func _plan_tick() -> void:
	_race_session.plan_tick(state == State.CHALLENGE or (state == State.COUNTDOWN and _stage_t < PLAN_STALE_UNTIL))


## Racer AI step 5b: a racing rival found the one-way street of a wrong-way hop not empty and
## takes another way (traffic.gd `hop_refused`: its plan has dropped the hop): the metres it has
## left, which the gap on the HUD reads, are counted without that hop from here on.
func _on_hop_refused(d) -> void:
	if state != State.RACE or _race_session == null or _race_session.hop_refused(d) == null:
		return
	var street := graph.e_name[d.edge]
	print("race: %s does not hop the wrong way from %s at %.1f s (the street was not empty)" % [RIVALS[rival]["name"], street if street != "" else "a street", _race_time])


## A racing rival found its street blocked and turns back (traffic.gd `turned_back`: its plan has
## shut the street and looks for another way): the metres it has left, which the gap on the HUD
## reads, are counted without that street from here on.
func _on_turned_back(d) -> void:
	if state != State.RACE or _race_session == null or _race_session.turned_back(d) == null:
		return
	var street := graph.e_name[d.edge]
	print("race: %s turns back on %s at %.1f s (%d streets shut to it)" % [RIVALS[rival]["name"], street if street != "" else "a street", _race_time, d.plan.shut.size()])


## The kit's frame, with the script's own time counted round it.
func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	super._process(dt)
	spent_usec += Time.get_ticks_usec() - t0


# --- beta values: the race shown better (street races R5) ------------------------------------------

## The route on the minimap from COUNTDOWN to the finish: to the finish, or in the final to the
## next bridge's checkpoint (again when the checkpoint is passed).
func _route_tick(dt: float) -> void:
	if graph == null or car == null:
		return
	if _route == null:
		_route = RouteLine.new(graph)
	if final_on:
		if not _race_session.ready():
			return
		if _route_cp != _cp:
			_route_cp = _cp
			var j := mini(2 * _cp + 1, final_route.legs.size() - 1)
			var goal: Vector3 = final_target()
			_route.to_node(final_route.legs[j], Vector2(goal.x, goal.z), _race_session.distances(_racer, j), _final_ends(j))
	elif not _route.active():
		if _ends.is_empty():
			_route.to_node(int(_finish["node"]), _finish_at())
		else:
			# A finish whose circle a road runs through: the line goes to where that road enters it
			# (the player's own way: no off-map links, none of the rival's shortcuts).
			_route.to_node(int(_finish["node"]), _finish_at(),
					graph.distances_to(_finish["node"], INF, false, _planner.links(_finish["node"], _ends)), _ends)
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	if _route.update(Vector2(car.global_position.x, car.global_position.z), heading, dt):
		hud.set_minimap_route(_route.points, FINAL_COLOUR if final_on else RACE_COLOUR, "race")


func _route_off() -> void:
	if _route != null:
		_route.clear()
	_route_cp = -1
	if hud != null and hud.has_method("clear_minimap_route"):
		hud.clear_minimap_route("race")


## Seconds between the two cars: the metres between them over the trailing car's speed (at least
## GAP_FLOOR m/s), so 40 m at 80 km/h reads 1.8 s.
static func time_gap(gap_m: float, trailing_speed: float) -> float:
	return absf(gap_m) / maxf(trailing_speed, GAP_FLOOR)


## The status line's gap [pl, en]: "Pani Halina 2,4 s za tobą", or level under LEVEL_M m.
static func gap_words(who: String, gap_m: float, seconds: float, first: bool) -> Array:
	if absf(gap_m) < LEVEL_M:
		return ["%s: łeb w łeb!" % who, "%s: neck and neck!" % who]
	var s := ("%.1f" % seconds)
	return ["%s %s s %s" % [who, s.replace(".", ","), "za tobą" if first else "przed tobą"],
			"%s %s s %s" % [who, s, "behind" if first else "ahead"]]


## The lead changes hands (from the 5 Hz ranking): a toast and a tick, once in LEAD_GAP s.
func _lead_tick(dt: float) -> void:
	_lead_said += dt
	var margin := _rival_left - _player_left  # > 0: the player is in front
	var now := _lead_player
	if _lead_player and margin < -LEAD_MARGIN:
		now = false
	elif not _lead_player and margin > LEAD_MARGIN:
		now = true
	if not _lead_known or now == _lead_player:
		return
	_lead_player = now
	if _lead_said < LEAD_GAP or _race_time < 3.0:
		return
	_lead_said = 0.0
	var who: String = RIVALS[rival]["name"]
	if now:
		hud.toast("PROWADZISZ! %s za tobą" % who, "YOU LEAD! %s is behind" % who)
	else:
		hud.toast("%s cię wyprzedza!" % who, "%s takes the lead!" % who)
	Access.buzz(40, 0.5)
	print("race: lead change at %.1f s, %s in front" % [_race_time, "the player" if now else who])


## The two speeds for the gap, smoothed over about a second (5 Hz).
func _speeds(d) -> void:
	_v_player = lerpf(_v_player, Vector2(car.vel.x, car.vel.z).length(), 0.25)
	_v_rival = lerpf(_v_rival, float(d.v), 0.25)
	if not _lead_known:
		# The first ranking sets who leads, quietly.
		_lead_known = true
		_lead_player = _player_left <= _rival_left


## The finish's margin in seconds: the one still driving needs this long at their speed now.
## The metres are capped by the straight line to the finish x MARGIN_DETOUR (PT-22: a route left
## that loops round a dual carriageway made an 11 m gap read "by 47.1 s").
func _finish_margin(won: bool) -> float:
	if final_on:
		return time_gap(_rival_left if won else _player_left, _v_rival if won else _v_player)
	var goal := Vector2(_finish["pos"].x, _finish["pos"].z)
	if won:
		var d = _drivers[rival]
		return time_gap(minf(_rival_left, Vector2(d.pos.x, d.pos.z).distance_to(goal) * MARGIN_DETOUR), _v_rival)
	var at := Vector2(car.global_position.x, car.global_position.z)
	return time_gap(minf(_player_remaining(), at.distance_to(goal) * MARGIN_DETOUR), _v_player)


## The trailing car's speed for the gap: the player's when behind, the rival's when in front.
func _gap_seconds(first: bool) -> float:
	return time_gap(_rival_left - _player_left, _v_rival if first else _v_player)


## Every frame, whatever the state: the rivals' own clock, the cooldowns, the tags, the lamps.
func _tick(dt: float) -> void:
	if graph == null:
		return
	_stage_t += dt
	for i in _cooldown.size():
		_cooldown[i] = maxf(0.0, _cooldown[i] - dt)
	_update_tags()
	if state == State.RACE:
		_signal_tick(dt)
	elif _sig_on:
		_signals_off()


## CRUISE and PROMPT (the kit's idle phase): looking for a challenge and for Seba's start.
func _idle_tick(dt: float) -> void:
	if graph == null:
		return
	if _caller >= 0 and (state == State.CRUISE or state == State.PROMPT):
		_first_call_tick(dt)  # loop 3h slice 4: Halina rolling up for the first race
		return
	match state:
		State.CRUISE:
			_look_for_challenge()
			_look_for_start(dt)
		State.PROMPT:
			if not _can_challenge(rival):
				_lost_sight += dt
				if _lost_sight > 1.2:
					state = State.CRUISE
					hud.hide_challenge()
			else:
				_lost_sight = 0.0
			_look_for_start(dt)


## CHALLENGE, COUNTDOWN and RACE (the kit's run; the result card holds it).
func _run_tick(dt: float) -> void:
	match state:
		State.CHALLENGE:
			if final_on:
				_prepare_final_step()
			_plan_tick()
			if _stage_t > 2.6:
				state = State.COUNTDOWN
				_stage_t = 0.0
				if final_on:
					_beacon.place(final_target(), TrzyMosty.CHECK_RADIUS - 6.0)
				else:
					_beacon.place(_finish["pos"], RaceSession.FINISH_RADIUS - 4.0)
				if autopilot:
					_start_ghost()
		State.COUNTDOWN:
			if final_on:
				_prepare_final_step()
			_plan_tick()
			var n := 3 - int(_stage_t)
			hud.show_banner(str(n) if n > 0 else "START!", Color.WHITE if n > 0 else WIN_COLOUR)
			_show_status()
			_route_tick(dt)
			if _stage_t >= 3.0:
				_go()
		State.RACE:
			_race_time += dt
			if first_race:
				_first_start(dt)
			if _stage_t > 1.0 and _nudge_banner_t <= 0.0:
				hud.hide_banner()
			_track(dt)
			if state == State.RACE:
				_route_tick(dt)
				if final_on:
					_plan_tick()


func _look_for_challenge() -> void:
	# PT-15: not while another activity of the kit is on, nor over a ride request's card either.
	if flying or missions.has_target() or not bool(free_now.call()) or bool(request_up.call()):
		return
	if hud != null and hud.cards_up():
		return  # no prompt over a result or win card (2026-11-08)
	for i in _drivers.size():
		if _cooldown[i] <= 0.0 and _can_challenge(i):
			rival = i
			state = State.PROMPT
			_lost_sight = 0.0
			var r: Dictionary = RIVALS[i]
			if not rung_open(i):
				# Loop 3h slice 3: locked on the ladder: the prompt says what is missing.
				var miss := ladder.missing(Ladder.rung_of(r["name"]))
				hud.show_challenge("%s · ZAMKNIĘTE" % r["name"].to_upper(), LOCKED_COLOUR, "%s · LOCKED" % r["name"].to_upper(),
						String(miss[0]), String(miss[1]))
				return
			hud.show_challenge("WYŚCIG · %s" % r["name"].to_upper(), r["colour"], "RACE · %s" % r["name"].to_upper(),
					"Dotknij albo L: mrugnij światłami", "Tap or L: flash your lights")
			if _stage_t - _said[i] > 40.0 and not quiet:
				_say(i, r["approach"][0], r["approach"][1], 3.5)
			return


## Close behind the rival (within 15 m, roughly in its lane), both moving.
func _can_challenge(i: int) -> bool:
	if flying or missions.has_target() or not bool(free_now.call()):
		return false
	var d = _drivers[i]
	var rel := Vector2(d.pos.x - car.global_position.x, d.pos.z - car.global_position.z)
	if rel.length() > CHALLENGE_RANGE or car.vel.length() < 2.0 or d.v < 1.0:
		return false
	var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
	return rel.dot(fwd) > 0.0 and absf(rel.cross(fwd)) < 4.0


func _go() -> void:
	state = State.RACE
	_stage_t = 0.0
	_race_time = 0.0
	_rank_timer = 0.0
	var d = _drivers[rival]
	d.held = false
	# PT-11: in the first race she waits at the line until the player moves (`_first_start`).
	_first_hold = first_race
	_go_nudged = false
	_lead_known = false
	_lead_said = 0.0
	_v_player = 0.0
	_v_rival = 0.0
	_stall_t = 0.0
	_stalls = 0
	_nudge_banner_t = 0.0
	if _first_hold:
		d.held = true
	# Its rung, Pani Halina's gentle day and an easier rematch (`_tuning`).
	var tuning := _tuning()
	var rung: int = tuning[0]
	var gentle: bool = tuning[1]
	_race_ease = tuning[2]
	# The session arms it (RaceSession.arm_racer: its stats as added, `_new_session`) and sends it off,
	# every leg's distances made first in the final; its dice are drawn here, as before the phone's.
	if final_on:
		_prepare_final()
	_racer.dice = _rng.randi()
	_race_session.start(_racer)
	var stats := _racer.stats
	if gentle and not first_race:
		print("race: %s on a gentle day (not beaten yet)" % RIVALS[rival]["name"])
	if _race_ease > 0.0:
		print("race: an easier rematch, %s drives %d %% slower (%d lost in a row)" % [RIVALS[rival]["name"], roundi(_race_ease * 100.0), ladder.lost_streak(rung)])
	_seen_cuts = 0
	_seen_mistakes = 0
	_seen_wrong = 0
	_seen_blocks = 0
	_phone_at = _rng.randf_range(0.3, 0.6) if bool(stats.get("phone", false)) else INF
	_sig = _racer.sig
	_report = RaceReport.new()
	if d.plan != null:
		print("race: %s plans %.0f s to the finish (traffic x%.2f, %d junction ways searched)" % [RIVALS[rival]["name"], d.plan.left(d.edge, d.s, d.v), d.plan.density, d.plan.settled])
	if _ghost != null:
		_ghost.held = false
	Access.buzz(80, 0.7)


## What the first race's start does now, from the seconds since START! and the car's speed (m/s):
## "release" (she goes), "nudge" (still: tell the player to drive) or "wait".
static func first_start_step(t: float, speed: float) -> String:
	if speed >= FIRST_MOVE or t >= FIRST_HOLD:
		return "release"
	if t >= FIRST_IDLE:
		return "nudge"
	return "wait"


## A stall nudge is due mid-race: stopped for FIRST_STALL s, fewer than FIRST_STALLS given, and
## more than FIRST_EASE m left (on the last stretch the finish is in sight).
static func first_stall_due(stopped_s: float, given: int, left: float) -> bool:
	return stopped_s >= FIRST_STALL and given < FIRST_STALLS and left > FIRST_EASE


## PT-11: every frame of the first race: the start hold, the GO nudge, the stall nudges.
func _first_start(dt: float) -> void:
	_nudge_banner_t = maxf(0.0, _nudge_banner_t - dt)
	var speed := Vector2(car.vel.x, car.vel.z).length()
	if _first_hold:
		match first_start_step(_stage_t, speed):
			"release":
				_first_hold = false
				_drivers[rival].held = false
				if hud.finger_shown():
					hud.ghost_finger(false)
				print("first race: %s goes at %.1f s (%s)" % [RIVALS[rival]["name"], _stage_t, "the player moved" if speed >= FIRST_MOVE else "the wait ran out"])
			"nudge":
				if not _go_nudged:
					_go_nudged = true
					_nudge(FIRST_LINES["go"], true)
		return
	# A held car (a police stop, a card) is not a stall.
	_stall_t = _stall_t + dt if speed < FIRST_STOP and not car.parked else 0.0
	if first_stall_due(_stall_t, _stalls, _player_left):
		_stalls += 1
		_stall_t = 0.0
		_nudge(FIRST_LINES["stall"], false)


## The nudge: her line, the GAZ! banner for FIRST_GO_BANNER_S s and (at the start) the ghost
## finger on the stick, which the first touch takes away (hud.gd).
func _nudge(line: Array, finger: bool) -> void:
	_say(rival, line[0], line[1], 3.5)
	hud.show_banner(FIRST_GO_BANNER, RACE_COLOUR)
	_nudge_banner_t = FIRST_GO_BANNER_S
	if finger:
		hud.ghost_finger(true)
	Access.buzz(60, 0.5)
	print("first race: nudge (%s) at %.1f s" % ["go" if finger else "stall", _race_time])


## PT-11: the first race's GO nudge shows the ghost finger (first10.gd leaves it up meanwhile).
func first_nudging() -> bool:
	return first_race and _first_hold and _go_nudged


## Who is in front and the race status; the finish decides it.
func _track(dt: float) -> void:
	if final_on:
		_track_final(dt)
		return
	var d = _drivers[rival]
	# One finish for both cars (`home_at`): the circle (PT-22: a finish node across a dual
	# carriageway routed the rival round a 500 m loop from 30 m away), and on a road that runs
	# through it the line across that road, in whichever lane (the rival's `arrived`: its plan's
	# `ends`, traffic.gd `race_to`; inside the circle: the session's `arrived`).
	if not flying and RaceSession.home_at(graph, car.global_position, _finish["pos"], _ends):
		_finish_race(true, "")
		return
	_race_session.advance(_race_time)
	if _racer.home:
		_finish_race(false, "")
		return
	_rank_timer -= dt
	if _rank_timer <= 0.0:
		_rank_timer = 0.2
		_player_left = _player_remaining()
		_race_session.rank(_player_left)
		_rival_left = _racer.left
		_effort(d)
		_speeds(d)
		_lead_tick(0.2)
		_human_tick(d)
	_show_status()


## The player's driving distance to the finish: from the nearest lane (either
## direction of the road), or the straight line if the car is off the roads.
func _player_remaining() -> float:
	return RaceSession.remaining_from(graph, _dist, Vector2(car.global_position.x, car.global_position.z), _finish["pos"], _ends)


## The player's driving distance to the node of `dist` (at `goal`): see _player_remaining.
func _remaining_by(dist: PackedFloat32Array, goal: Vector3, ends := {}) -> float:
	return RaceSession.remaining_from(graph, dist, Vector2(car.global_position.x, car.global_position.z), goal, ends)


func _show_status() -> void:
	if final_on:
		_show_final_status()
		return
	var r: Dictionary = RIVALS[rival]
	var first := _player_left <= _rival_left
	var gap := absf(_rival_left - _player_left)
	var at := car.global_position
	var metres := roundi(Vector2(at.x, at.z).distance_to(Vector2(_finish["pos"].x, _finish["pos"].z)))
	# PT-11: the card names the goal in short ("pod Palmę"), and the hint says what to do: drive there
	# (the pink arrow shows the way), with the rival's gap after it.
	var goal_pl: String = _finish["pl"]
	var goal_en: String = _finish["en"]
	var hint := ["Jedź %s! Różowa strzałka pokaże drogę." % goal_pl, "Drive %s! The pink arrow shows the way." % goal_en]
	if state == State.RACE:
		# Beta values (R5): the gap in seconds ("Pani Halina 2,4 s za tobą"); it was metres.
		var g := gap_words(r["name"], gap, _gap_seconds(first), first)
		hint = ["Jedź %s! %s." % [goal_pl, g[0]], "Drive %s! %s." % [goal_en, g[1]]]
	status("WYŚCIG · " + Lang.pick(goal_pl, goal_en).to_upper(), _clock(_race_time), "%d m" % metres,
			hint, 0.0, RACE_COLOUR, ("1ST" if first else "2ND") if state == State.RACE else "")


func _finish_race(won: bool, why: String) -> void:
	if final_on:
		_finish_final(won, why)
		return
	state = State.RESULT
	_route_off()
	hud.hide_banner()
	hide_status()
	if first_race and hud.finger_shown():
		hud.ghost_finger(false)
	_first_hold = false
	_nudge_banner_t = 0.0
	_beacon.visible = false
	var d = _drivers[rival]
	_race_log(d, won)
	var margin := _finish_margin(won) if why == "" else 0.0
	var told: Array = _report_told(d, rival, won, margin) if why == "" else ["", ""]
	_race_session.end()
	_cruise(d)
	_cooldown[rival] = 25.0
	if _ghost != null:
		traffic.remove(_ghost)
		_ghost = null
	var r: Dictionary = RIVALS[rival]
	# Beta values (R5): a close finish shows as close: "o 0,8 s".
	var by_pl := " (o %s s)" % ("%.1f" % margin).replace(".", ",")
	var by_en := " (by %.1f s)" % margin
	print("race: finish margin %.1f s" % margin)
	# The rival talks back: a grudging line when they lose, a gloat when they win.
	var line: Array = r["lose" if won else "win"][_rng.randi() % 2]
	_say(rival, line[0], line[1], 5.0)
	var who: String = r["name"]
	print("race %s: %s to %s in %.1f s" % ["won" if won else "lost", who, _finish["name"], _race_time])
	# An easier rematch (ladder.gd `ease_of`): a race driven to its end counts, one given up does not.
	if ladder != null and why == "":
		ladder.note_result(Ladder.rung_of(who), won)
	if first_race:
		# Loop 3h slice 4: the guided first race is over (first10.gd's race beat).
		first_race = false
		first_result = "won" if won else "lost"
		print("first race %s: %s, %.0f m between them at the end" % [first_result, who, absf(_rival_left - _player_left)])
	if won:
		var stake: int = r["stake"]
		# Loop 3g-2: escaping the police during the race: +20 % on the stake.
		var bonus_pl := ""
		var bonus_en := ""
		if escape_bonus:
			var base := stake
			stake = roundi(stake * ESCAPE_BONUS)
			bonus_pl = " · +20 % ZA UCIECZKĘ"
			bonus_en = " · +20 % FOR THE ESCAPE"
			print("race: +20 %% for the escape: %d → %d zł" % [base, stake])
		var record := ""
		var gain := Ladder.WIN_GAIN
		if wallet != null:
			var key := "race:%s" % _finish["name"]
			var best: float = wallet.best_time(key)
			if wallet.record(key, _race_time):
				record = " · new best!" if best > 0.0 else ""
			else:
				record = " · best %s" % _clock(best)
		# Loop 3h slice 3: the ladder's rung beaten (the first time, when it was open). The designer
		# pass: only that first win gives the full respect; a rematch gives Ladder.REMATCH_GAIN.
		var rung := Ladder.rung_of(who)
		var first_win := ladder != null and wallet != null and ladder.win(rung, Districts.today())
		gain = Ladder.race_gain(rung, first_win or ladder == null)
		if wallet != null:
			wallet.pay(stake, gain, "race")
		if first_win:
			print("ladder: %s beaten (%d/%d), next: %s" % [who, rung + 1, Ladder.RUNGS.size(), _rung_name(ladder.next_rung())])
			_check_ladder()
		var total := (" · wallet %s · respect %d" % [_money(wallet.zl), wallet.respect]) if wallet != null else ""
		var total_pl := (" · w portfelu %s · szacunek %d" % [_money(wallet.zl), wallet.respect]) if wallet != null else ""
		var record_pl := record.replace("new best!", "nowy rekord!").replace("best", "rekord")
		show_card(["WYGRANA · 1. MIEJSCE", "Win · 1st"], [("Meta: %s, czas %s%s. %s za tobą%s.\n„%s”\n+%d zł (stawka%s) · szacunek +%d%s\n%s" % [
				_finish["name"], _clock(_race_time), record_pl, who, by_pl, line[0], stake, bonus_pl, gain, total_pl, told[0]]).strip_edges(),
				("You beat %s to %s in %s%s%s. %s +%d zł (the stake%s) · respect +%d%s\n%s" % [
				who, _finish["name"], _clock(_race_time), by_en, record, line[1], stake, bonus_en, gain, total, told[1]]).strip_edges()],
				PackedStringArray(["OK"]), 0.0, false, WIN_COLOUR)
		_report_art(rival, _finish["pos"])
		Access.buzz(150, 0.9)
	else:
		var short := roundi(_player_remaining())
		var reason := why if why != "" else "%s got to %s first. You were %d m short%s after %s." % [who, _finish["name"], short, by_en, _clock(_race_time)]
		var reason_pl := "Wyścig poddany." if why != "" else "%s pierwszy na mecie: %s. Zabrakło ci %d m%s, czas %s." % [
				who, _finish["name"], short, by_pl, _clock(_race_time)]
		show_card(["PRZEGRANA · 2. MIEJSCE", "Lose · 2nd"], [("%s\n„%s”\n%s" % [reason_pl, line[0], told[0]]).strip_edges(),
				("%s %s\n%s" % [reason, line[1], told[1]]).strip_edges()], PackedStringArray(["OK"]), 0.0, false, LOSE_COLOUR)
		_report_art(rival, _finish["pos"])


## The result card's OK (the kit's `_card_pressed`): the race is over.
func _card_pressed(_index: int) -> void:
	finish()


## The kit's end of a run (its card is already down): cruising again, the rescue calls free.
func _ended() -> void:
	state = State.CRUISE
	missions.paused = false
	missions.close()


## Bumped mid-race (or just bumped): the rival complains.
func _on_bumped(d) -> void:
	var i := _drivers.find(d)
	if i < 0 or bubbles.is_talking(_nodes[i]):
		return
	_say(i, "Ej! Uważaj na lakier!", "Hey! Mind the paint!", 2.0)


func _say(i: int, pl: String, en: String, seconds: float) -> void:
	var r: Dictionary = RIVALS[i]
	bubbles.say(_nodes[i], r["name"], pl, en, seconds, r["colour"], float(r["size"].y) + 1.0)
	_said[i] = _stage_t


## Name tags over rivals near the player, and their dots on the minimap.
func _update_tags() -> void:
	var p := car.global_position
	var dots := PackedVector2Array()
	var colours := PackedColorArray()
	for i in _drivers.size():
		var d = _drivers[i]
		var r: Dictionary = RIVALS[i]
		var near: bool = d.pos.distance_to(p) < 90.0 or (i == rival and state != State.CRUISE)
		if near:
			bubbles.tag(_nodes[i], r["name"], r["colour"], float(r["size"].y) + 0.9)
		else:
			bubbles.untag(_nodes[i])
		dots.append(Vector2(d.pos.x, d.pos.z))
		colours.append(r["colour"])
	hud.set_minimap_dots(dots, colours)


# --- loop 3h slice 4: the guided first race ------------------------------------------------

## The Palm's finish (FIRST_FINISH), or {} if the map has none.
func _first_finish() -> Dictionary:
	for f in _finishes:
		if f["name"] == FIRST_FINISH:
			return f
	return {}


## The player's car's top speed (m/s, its model and engine; nitro left out), as police.gd's chase_top.
func player_top() -> float:
	if car == null or not ("top_mult" in car and "max_speed" in car):
		return 30.0
	return float(car.max_speed) * float(car.top_mult)


## 5 times a second in a race, after the session's `rank` set the rival's effort from the time gap
## (RaceSession.pace_tick): with --race-debug its trace.
func _effort(d) -> void:
	var effort: float = d.race_effort
	if traffic.race_debug and fmod(_race_time, 1.0) < 0.2:
		# --race-debug: once a second, what the rival does and what its effort follows (the audit's trace).
		var lead := _player_left - _rival_left
		print("race trace: t %.0f s · rival %.1f m/s, share %.2f, effort %.2f, class %d, left %.0f m · player %.1f m/s, left %.0f m · rival's lead %.0f m (%.1f s) · seen %s" % [
				_race_time, d.v, d.race_share, effort, graph.e_class[d.edge], _rival_left, Vector2(car.vel.x, car.vel.z).length(), _player_left,
				lead, lead / RaceSession.own_pace(d.race_top, d.race_share), d.visible])


## Step 6a, every frame of a race: the racing rival's lights and its body's swing (race_signals.gd).
func _signal_tick(dt: float) -> void:
	var i := _seba if final_on else rival
	if i < 0:
		return
	_race_session.signals(dt)
	RaceSignals.show(_signals[i], _sig)
	_bodies[i].rotation.y = _sig.yaw
	_sig_on = true
	# ... and both cars' ways, for the result card.
	var d = _drivers[i]
	_report.tick(dt, Vector2(car.global_position.x, car.global_position.z), Vector2(car.vel.x, car.vel.z).length(), Vector2(d.pos.x, d.pos.z), d.v)


## Step 6a: the race driven to its end: its report closed (race_report.gd `close`) with what rival
## `d` did, before the driver's counts go. Returns the result card's extra lines [Polish, English].
func _report_close(d, i: int, won: bool, margin: float) -> Array:
	var yards: int = d.links_taken - d.hops_taken
	_report.close(won, margin, _rival_left if won else _player_left, {
			"cuts": d.cuts_taken - d.links_taken, "yards": yards, "hops": d.hops_taken, "wrong": d.wrong_turns,
			"mistakes": d.mistakes, "passes": d.race_passes, "blocks": d.blocks})
	print("race report: %s · route %+.1f s, standing %+.1f s, pace %+.1f s · you %.0f m, rival %.0f m · lights: %d brakes, %d indications, %d flashes, %d hazards" % [
			["even", "route", "standing", "pace"][_report.cause], _report.route_s, _report.still_s, _report.pace_s, _report.player_way, _report.rival_way,
			_sig.brakes, _sig.indications, _sig.flashes, _sig.hazards])
	return _report.texts(RIVALS[i]["name"])


## The report's words for the result card. F, 2026-11-13: "detailed info about lose or win is not
## needed", so the card keeps its own short lines and the picture of both routes, and the
## report's lines (what decided it, the kilometres, the rival's moments) go to the log only
## (REPORT_LINES false). The report is still closed here: the picture and the log read it.
func _report_told(d: Traffic.Driver, i: int, won: bool, margin: float) -> Array:
	var told := _report_close(d, i, won, margin)
	return told if REPORT_LINES else ["", ""]


## ... and its picture on the card just shown: both ways over the streets, to `goal`.
func _report_art(i: int, goal: Vector3) -> void:
	if not _report.closed:
		return
	var art := RaceReport.Sketch.new()
	art.report = _report
	art.graph = graph
	art.finish = Vector2(goal.x, goal.z)
	art.rival_colour = Access.tint(RIVALS[i]["colour"])
	art.you = Lang.pick("TY", "YOU")
	# The ladder's short name (SEBA, not the "Z" of "Seba z Pragi"); a rival off the ladder: its
	# first word.
	var rung := Ladder.rung_of(RIVALS[i]["name"])
	art.them = String(Ladder.RUNGS[rung]["short"]) if rung >= 0 else String(RIVALS[i]["name"]).get_slice(" ", 0).to_upper()
	art.points = hud.pt
	art.custom_minimum_size = REPORT_ART * hud.pt
	hud.set_card_art(art)


## Every rival's lamps out and its body straight (the race is over, however it ended).
func _signals_off() -> void:
	_sig_on = false
	_sig.clear()
	for i in _signals.size():
		RaceSignals.show(_signals[i], null)
		_bodies[i].rotation.y = 0.0


## Human rivals, 5 times a second: the phone call (Mike) and a line for what the rival just did
## (traffic.gd's counts: a shortcut, a wrong turn, a mistake, a block), if the player is near.
func _human_tick(d) -> void:
	if _phone_at < INF and _racer.effort.route_total > 0.0 and _rival_left < INF and 1.0 - _rival_left / _racer.effort.route_total >= _phone_at:
		_phone_at = INF
		d.daze = 1.2  # lifts off for the call (coasting, not a stop)
		_sig.weave(1.2)  # step 6a: and wanders in his lane meanwhile
		_human_say("phone")
	var kind := ""
	if d.cuts_taken > _seen_cuts:
		_seen_cuts = d.cuts_taken
		kind = "cut"
	if d.wrong_turns > _seen_wrong:
		_seen_wrong = d.wrong_turns
		kind = "wrong"
	if d.mistakes > _seen_mistakes:
		_seen_mistakes = d.mistakes
		kind = "mistake"
	if d.blocks > _seen_blocks:
		_seen_blocks = d.blocks
		kind = "block"
	if kind != "":
		_human_say(kind)


func _human_say(kind: String) -> void:
	var d = _drivers[rival]
	if quiet or Vector2(d.pos.x - car.global_position.x, d.pos.z - car.global_position.z).length() > HUMAN_NEAR \
			or _stage_t - _said[rival] < HUMAN_QUIET:
		return
	var lines: Array = HUMAN_LINES[kind]
	for w in String(RIVALS[rival]["name"]).to_lower().split(" "):
		if HUMAN_LINES.has(kind + "_" + w):
			lines = HUMAN_LINES[kind + "_" + w]
	var line: Array = lines[_rng.randi() % lines.size()]
	_say(rival, line[0], line[1], 2.5)


## Street races: one line on how the rival raced (for tuning and check_race_ai's runs).
func _race_log(d, won: bool) -> void:
	print("race ai: %s %s in %.1f s · route %.0f m · top %.1f m/s, share %.2f (eased %d %%) · effort %.2f-%.2f · stopped %.1f s · %d passes · %d cuts · %d mistakes · %d wrong · %d blocks · gap %.0f m" % [
			RIVALS[rival]["name"], "lost to the player" if won else "won", _race_time, _racer.effort.route_total, d.race_top, d.race_share, roundi(_race_ease * 100.0), _racer.effort.lo, _racer.effort.hi,
			d.race_still, d.race_passes, d.cuts_taken, d.mistakes, d.wrong_turns, d.blocks, _rival_left - _player_left])


## Back to cruising after a race: the town car's pace, no racer mode.
func _cruise(d) -> void:
	d.held = false
	d.speed_factor = 1.08
	d.accel_factor = 1.3
	d.race_top = 0.0
	d.race_accel = 0.0
	d.race_brake = 0.0
	d.race_share = 1.0
	d.race_effort = 1.0
	d.race_corner = 1.0
	d.cuts = {}
	d.race_mistake = 0.0
	d.race_wrong = 0
	d.race_block = 0.0
	d.race_rng = null


## Loop 3h slice 4: Halina (rival `name`) rolls up behind the player for the guided first race:
## put about FIRST_BACK m back on the player's road (out of sight if it can be), she drives up and
## stops behind, flashes and the prompt asks for a flash back. False if a race or a prompt is on,
## the rival is unknown or no lane is near the car.
func call_first(name := "Pani Halina") -> bool:
	if state != State.CRUISE or _caller >= 0 or flying:
		return false
	var i := -1
	for k in RIVALS.size():
		if RIVALS[k]["name"] == name:
			i = k
	if i < 0:
		return false
	var spot := _spot_behind(FIRST_BACK)
	if spot.is_empty():
		return false
	var d = _drivers[i]
	traffic.teleport(d, spot[0], spot[1], spot[2])
	d.held = false
	d.speed_factor = 1.3
	d.accel_factor = 1.6
	var goal: int = graph.e_b[int(spot[3])]  # the end of the car's own edge
	traffic.race_to(d, goal, _distances(goal))
	_caller = i
	_call_t = 0.0
	_call_up = false
	_nudged = false
	rival = i
	print("first race: %s rolls up %.0f m behind (edge %d)" % [name, FIRST_BACK, spot[0]])
	return true


## PT-8: a lane point about `back` m behind the car, on a lane within FIRST_SNAP m that runs the
## way the car faces ([edge, lane, s, the car's edge]), or [] when there is none or the point
## would not be behind the car by at least half of `back` (the lane snapped to starts just ahead
## of it, or its road has no way in from behind: `_behind` stops at the edge's start).
func _spot_behind(back: float) -> Array:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var heading := _car_heading()
	var hit := graph.snap(p, FIRST_SNAP, heading, true)
	if hit.is_empty():
		return []
	var spot := _behind(int(hit[0]), int(hit[1]), float(hit[2]), back)
	var e: int = spot[0]
	var q: Vector2 = graph.point_at(e, float(spot[2]), graph.lane_offset(e, int(spot[1])))
	if (q - p).dot(heading) > -0.5 * back:
		return []
	return spot + [int(hit[0])]


func _car_heading() -> Vector2:
	return Vector2(-sin(car.rotation.y), -cos(car.rotation.y))


## A lane point `back` m behind (e, lane, s) along the road (into the edge before when this one
## is too short): [edge, lane, s].
func _behind(e: int, lane: int, s: float, back: float) -> Array:
	return lane_behind(graph, e, lane, s, back)


## `_behind` on `graph`; static for the race bench (the first race's grid).
static func lane_behind(graph: LaneGraph, e: int, lane: int, s: float, back: float) -> Array:
	if s - back >= graph.e_s0[e] + 2.0:
		return [e, lane, s - back]
	var left := back - (s - graph.e_s0[e])
	var here := graph.direction(e, graph.e_s0[e])
	var best := -1
	var best_turn := 0.9
	for f in graph.node_in[graph.e_a[e]]:
		if f == graph.e_reverse[e] or graph.node_scc[graph.e_a[f]] == 0:
			continue
		var turn := absf(here.angle_to(graph.direction(f, graph.e_s1[f])))
		if turn < best_turn:
			best_turn = turn
			best = f
	if best < 0:
		return [e, lane, graph.e_s0[e] + 2.0]
	return [best, mini(lane, graph.e_lanes[best] - 1), maxf(graph.e_s1[best] - left, graph.e_s0[best] + 2.0)]


## Every frame while Halina rolls up and waits (a distance and a timer, no scan): she stops behind
## the car, flashes, the prompt waits for the flash back (or she gives up: a job or a rescue
## started, the player drove off, the wait ran out).
func _first_call_tick(dt: float) -> void:
	_call_t += dt
	var d = _drivers[_caller]
	var gap := Vector2(d.pos.x - car.global_position.x, d.pos.z - car.global_position.z).length()
	var other: bool = missions.has_target() or not bool(free_now.call()) or flying
	if not _call_up and not other:
		# PT-8: she stops only behind the car (a player who turned round has her in front).
		var rel := Vector2(d.pos.x - car.global_position.x, d.pos.z - car.global_position.z)
		var close := gap < 14.0 and rel.dot(_car_heading()) < 0.0
		if close or _call_t > FIRST_ROLL:
			if not close:
				# Stuck in a knot of cars, turned off or passed: she is just there, behind, on a
				# lane the car's way; with none (turned round up a one-way) she gives up quietly.
				var spot := _spot_behind(12.0)
				if spot.is_empty():
					if _call_t > FIRST_ROLL + FIRST_WAIT:
						_first_give_up(false)
					return
				traffic.teleport(d, spot[0], spot[1], spot[2])
			traffic.stop_racing(d)
			d.held = true
			_call_up = true
			_call_t = 0.0
			state = State.PROMPT
			var r: Dictionary = RIVALS[_caller]
			hud.show_challenge("WYŚCIG · %s" % String(r["name"]).to_upper(), r["colour"], "RACE · %s" % String(r["name"]).to_upper(),
					"Mruga do ciebie! Dotknij albo L", "Flashing you! Tap or L to race")
			_say(_caller, FIRST_LINES["call"][0], FIRST_LINES["call"][1], 4.0)
			print("first race: %s flashed, waiting for the flash back" % r["name"])
		return
	if _call_up and not _nudged and _call_t > 8.0:
		_nudged = true
		_say(_caller, FIRST_LINES["nudge"][0], FIRST_LINES["nudge"][1], 3.5)
	if _call_t > FIRST_WAIT or (_call_up and gap > FIRST_AWAY) or other:
		print("first race: %s gave up waiting (%.0f s, %.0f m)" % [RIVALS[_caller]["name"], _call_t, gap])
		_first_give_up(true)


## The first race's call ends unanswered (`say`: her parting line; not when she never got there).
func _first_give_up(say: bool) -> void:
	var d = _drivers[_caller]
	if say:
		_say(_caller, FIRST_LINES["gone"][0], FIRST_LINES["gone"][1], 3.5)
	d.held = false
	traffic.stop_racing(d)
	_cooldown[_caller] = 25.0
	_caller = -1
	first_result = "declined"
	state = State.CRUISE
	hud.hide_challenge()


## PT-15 (2026-11-03): a prompt is up (a rival's FLASH LIGHTS, or Halina's flash back) or Halina
## is rolling up for it: rides.gd offers no ride over it.
func calling() -> bool:
	return state == State.PROMPT or _caller >= 0


## Loop 3h slice 4: the guided first race is waiting for its flash back.
func first_waiting() -> bool:
	return _caller >= 0


## The main line (main_line.gd): the race on now is the final or the next rung's (a beaten rival
## re-raced is a side race).
func main_race() -> bool:
	if not has_target():
		return false
	if final_on:
		return true
	if ladder == null or wallet == null or rival < 0:
		return false
	return Ladder.rung_of(str(RIVALS[rival]["name"])) == ladder.next_rung()


## The map point (x, z) of the rival called `name` (RIVALS' name), INF if not on the map.
func rival_at(name: String) -> Vector2:
	for i in mini(_drivers.size(), RIVALS.size()):
		if RIVALS[i]["name"] == name:
			var p: Vector3 = _drivers[i].pos
			return Vector2(p.x, p.z)
	return Vector2.INF


# --- loop 3h slice 3: the ladder and the final "Trzy mosty" ---------------------------------

## It is night for the final: the Night look, or the live clock with the lights well on (rides.gd's
## rule). The clock is never changed here.
func night() -> bool:
	return tod != null and (int(tod.mode) == 2 or (int(tod.mode) == 3 and float(tod.lights_on) > 0.5))


## The final is open on the ladder and has a route.
func final_open() -> bool:
	return final_route != null and ladder != null and wallet != null and ladder.is_open(Ladder.FINAL)


## The ladder's rows for the full map's card (ladder.gd `rows`).
func ladder_rows() -> Array:
	return ladder.rows(night()) if ladder != null and wallet != null else []


## The start marker's map point (INF: not shown), for the full map.
func start_marker() -> Vector2:
	return Vector2(final_route.start_pos.x, final_route.start_pos.z) if _marker_on else Vector2.INF


static func _rung_name(i: int) -> String:
	if i < Ladder.RUNGS.size():
		return str(Ladder.RUNGS[i]["rival"])
	return "Trzy mosty" if i == Ladder.FINAL else "-"


## A rung (or the final) opened since the last look: a toast. Called when the wallet changes and
## after a rung is beaten.
func _check_ladder() -> void:
	if ladder == null or wallet == null:
		return
	var n := ladder.open_count()
	if _open_seen >= 0 and n > _open_seen:
		var i := n - 1
		if i == Ladder.FINAL:
			hud.toast("Finał otwarty: Trzy mosty · w nocy", "The final is open: Three bridges · at night")
		elif i < Ladder.RUNGS.size():
			hud.toast("Nowy rywal: %s" % Ladder.RUNGS[i]["rival"], "New rival: %s · %d zł" % [Ladder.RUNGS[i]["rival"], Ladder.RUNGS[i]["stake"]])
		print("ladder: open %d -> %d: %s" % [_open_seen, n, _rung_name(i)])
	_open_seen = n


## Five times a second while cruising: Seba waits at the start when the final is open at night;
## the marker shows when nothing else runs; driving into it starts the final.
func _look_for_start(dt: float) -> void:
	_start_t += dt
	if _start_t < START_EVERY:
		return
	_start_t = 0.0
	var first := _first_look
	_first_look = false
	var want := final_open() and night()
	if want and not _seba_waiting:
		_park_seba(first)
	elif not want and _seba_waiting:
		_release_seba()
	var free: bool = _seba_waiting and not flying and not missions.has_target() and bool(free_now.call())
	_marker(free)
	if free:
		var at := car.global_position
		var sp := final_route.start_pos
		if Vector2(at.x - sp.x, at.z - sp.z).length() < START_RADIUS and absf(at.y - sp.y) < 6.0:
			start_final()
		elif Vector2(at.x - sp.x, at.z - sp.z).length() < 60.0 and _stage_t - _said[_seba] > 30.0 and not quiet:
			_say(_seba, FINAL_LINES["wait"][0], FINAL_LINES["wait"][1], 4.0)


## Seba to his spot at the start, held there. Only out of the player's sight (WAIT_UNSEEN from both
## Seba and the spot) unless `force` (--trzy-mosty).
func _park_seba(force: bool) -> void:
	if _seba < 0 or final_route == null:
		return
	if rival == _seba and state != State.CRUISE and state != State.PROMPT:
		return
	var d = _drivers[_seba]
	var at := car.global_position
	if not force and (d.pos.distance_to(at) < WAIT_UNSEEN or final_route.start_pos.distance_to(at) < WAIT_UNSEEN):
		return
	var spot: Array = final_route.seba_lane
	traffic.teleport(d, spot[0], spot[1], spot[2])
	d.held = true
	_seba_waiting = true
	print("rivals: Seba waits at Rondo Daszyńskiego for Trzy mosty")


func _release_seba() -> void:
	if not _seba_waiting:
		return
	_seba_waiting = false
	_drivers[_seba].held = false


## The start marker on (the race beacon at the start and the diamond on the minimap) or off.
func _marker(on: bool) -> void:
	if on == _marker_on:
		return
	_marker_on = on
	if on:
		_beacon.recolour(FINAL_COLOUR)
		_beacon.place(final_route.start_pos, START_RADIUS - 2.0)
		hud.set_minimap_final(Vector2(final_route.start_pos.x, final_route.start_pos.z), FINAL_COLOUR)
	else:
		_beacon.visible = false
		hud.set_minimap_final(Vector2.INF, FINAL_COLOUR)


## The final: Seba's challenge, then the countdown and the race over three bridges (also
## --trzy-mosty, which first puts the car at the start).
func start_final() -> void:
	if final_route == null or _seba < 0:
		return
	_marker(false)
	_park_seba(true)
	_seba_waiting = false
	final_on = true
	rival = _seba
	# The course is the route's legs (a checkpoint is a junction to drive through). The finish by
	# the stadium is a circle too: the avenue's other carriageway runs through it, 130 m from the
	# last bridge where the finish's own junction is 680 m round. Seba's last leg ends where the
	# player's does; he is home on arriving (no circle of his own round the junction).
	_new_session(final_route.legs)
	_race_session.home_circle = false
	_racer.leg = _start_leg
	_cp = _start_leg >> 1
	_ghost_leg = _start_leg
	_beacon.recolour(FINAL_COLOUR)
	var d = _drivers[_seba]
	d.held = true
	_races += 1
	escape_bonus = false
	state = State.CHALLENGE
	_stage_t = 0.0
	start()
	hud.hide_challenge()
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_card()
	_say(_seba, FINAL_LINES["challenge"][0], FINAL_LINES["challenge"][1], 3.5)
	hud.show_banner("TRZY MOSTY", FINAL_COLOUR)
	print("trzy mosty: start at Rondo Daszyńskiego (%.0f, %.0f) against %s" % [final_route.start_pos.x, final_route.start_pos.z, RIVALS[_seba]["name"]])


## The roads through the circle of the final's leg `j`: the finish's for the last leg (`_ends`,
## set by start_final), none for a checkpoint.
func _final_ends(j: int) -> Dictionary:
	return _ends if j == final_route.legs.size() - 1 else {}


## One leg's distances a frame (about 8 ms each on the Linux container) during the challenge
## (RaceSession.prepare_step).
func _prepare_final_step() -> void:
	if _race_session.prepare_step() and _race_session.ready():
		_legs_log()


## Every leg's distances now (the start of the race, or the ghost).
func _prepare_final() -> void:
	var was := _race_session.ready()
	_race_session.prepare()
	if not was:
		_legs_log()


## The final's course in the log: its legs and the metres by road from the leg it starts on.
func _legs_log() -> void:
	var n := final_route.legs.size()
	var first := 0.0
	var d = _drivers[_seba]
	if d.active:
		first = graph.remaining(_race_session.distances(_racer, _start_leg), d.edge, d.s)
	print("trzy mosty: %d legs, %.0f m by road from leg %d" % [n, first + _racer.after[_start_leg], _start_leg])


func _track_final(dt: float) -> void:
	var d = _drivers[_seba]
	# Seba (the session) and the ghost move on to their next leg on reaching each target.
	var was := _racer.leg
	_race_session.advance(_race_time)
	if _racer.home:
		_finish_race(false, "")
		return
	if _racer.leg != was and _racer.leg % 2 == 0:
		print("trzy mosty: %s over %s at %.1f s" % [RIVALS[_seba]["name"], final_route.checkpoints[_racer.leg / 2 - 1]["pl"], _race_time])
	if _ghost != null and _ghost.arrived and _ghost_leg < final_route.legs.size() - 1:
		_ghost_leg += 1
		traffic.race_to(_ghost, final_route.legs[_ghost_leg], _distances(final_route.legs[_ghost_leg]))
	_rank_timer -= dt
	if _rank_timer <= 0.0:
		# 5 Hz: the checkpoint, the finish and who is in front.
		_rank_timer = 0.2
		var at := car.global_position
		if _cp < final_route.checkpoints.size():
			if not flying and final_route.passed(_cp, at):
				print("trzy mosty: checkpoint %d/%d %s at %.1f s" % [_cp + 1, final_route.checkpoints.size(), final_route.checkpoints[_cp]["pl"], _race_time])
				_cp += 1
				Access.buzz(40, 0.5)
				hud.toast("MOST %d/3 · %s" % [_cp, final_route.checkpoints[_cp - 1]["pl"]], "bridge %d/3 · %s" % [_cp, final_route.checkpoints[_cp - 1]["en"]])
				if _cp < final_route.checkpoints.size():
					_beacon.place(final_target(), TrzyMosty.CHECK_RADIUS - 6.0)
				else:
					_beacon.place(final_target(), RaceSession.FINISH_RADIUS - 4.0)
		else:
			if not flying and RaceSession.home_at(graph, at, final_route.finish["pos"], _ends):
				_finish_race(true, "")
				return
		var j := mini(2 * _cp + 1, final_route.legs.size() - 1)
		var goal: Vector3 = final_target()
		_player_left = _remaining_by(_race_session.distances(_racer, j), goal, _final_ends(j)) + _racer.after[j]
		_race_session.rank(_player_left)
		_rival_left = _racer.left
		_effort(d)
		_speeds(d)
		_lead_tick(0.2)
	_show_status()


func _show_final_status() -> void:
	var r: Dictionary = RIVALS[_seba]
	var first := _player_left <= _rival_left
	var gap := absf(_rival_left - _player_left)
	var at := car.global_position
	var goal := final_target()
	var metres := roundi(Vector2(at.x, at.z).distance_to(Vector2(goal.x, goal.z)))
	# The status title is cut at ~20 characters: the leg first (the bridge's name is on the toast).
	var leg_pl := "META"
	if _cp < final_route.checkpoints.size():
		leg_pl = "MOST %d/3" % (_cp + 1)
	var hint := ["Uwaga…", "Get ready…"]
	if state == State.RACE:
		hint = gap_words(r["name"], gap, _gap_seconds(first), first)
	status("%s · TRZY MOSTY" % leg_pl, _clock(_race_time), "%d m" % metres,
			hint, 0.0, FINAL_COLOUR, ("1ST" if first else "2ND") if state == State.RACE else "")


func _finish_final(won: bool, why: String) -> void:
	state = State.RESULT
	_route_off()
	var margin := _finish_margin(won)
	final_on = false
	_start_leg = 0
	_ghost_spot = []
	hud.hide_banner()
	hide_status()
	_beacon.visible = false
	_beacon.recolour(RACE_COLOUR)
	var d = _drivers[_seba]
	_race_log(d, won)
	var told: Array = _report_told(d, _seba, won, margin) if why == "" else ["", ""]
	var goal: Vector3 = final_route.finish["pos"]
	_race_session.end()
	_cruise(d)
	_cooldown[_seba] = 25.0
	if _ghost != null:
		traffic.remove(_ghost)
		_ghost = null
	var who: String = RIVALS[_seba]["name"]
	var line: Array = FINAL_LINES["lose" if won else "win"]
	_say(_seba, line[0], line[1], 5.0)
	print("trzy mosty %s: %s in %.1f s, %d/3 bridges" % ["won" if won else "lost", who, _race_time, _cp])
	if ladder != null and why == "":
		ladder.note_result(Ladder.FINAL, won)
	if won:
		var first := ladder != null and wallet != null and not ladder.final_won()
		var stake := Ladder.FINAL_ZL
		var gain := Ladder.race_gain(Ladder.FINAL, first or ladder == null)
		if escape_bonus:
			stake = roundi(stake * ESCAPE_BONUS)
		var record := ""
		if wallet != null:
			var best: float = wallet.best_time("race:Trzy mosty")
			if wallet.record("race:Trzy mosty", _race_time):
				record = " · new best!" if best > 0.0 else ""
			else:
				record = " · best %s" % _clock(best)
			wallet.pay(stake, gain, "race")
			ladder.win(Ladder.FINAL, Districts.today())
			_check_ladder()
		var total := (" · wallet %s · respect %d" % [_money(wallet.zl), wallet.respect]) if wallet != null else ""
		var total_pl := (" · w portfelu %s · szacunek %d" % [_money(wallet.zl), wallet.respect]) if wallet != null else ""
		var record_pl := record.replace("new best!", "nowy rekord!").replace("best", "rekord")
		var crown_pl := "KORONA NOCNEJ WARSZAWY TWOJA!\n" if first else ""
		var crown_en := "The crown of Warsaw by night is yours! " if first else ""
		show_card(["TRZY MOSTY · WYGRANA", "Three bridges · Win"], ["%sTrzy razy przez Wisłę i pierwsze miejsce pod Narodowym, czas %s%s, o %s s przed Sebą.\n„%s”\n+%d zł · szacunek +%d%s" % [
				crown_pl, _clock(_race_time), record_pl, ("%.1f" % margin).replace(".", ","), line[0], stake, gain, total_pl] + ("\n" + told[0] if told[0] != "" else ""),
				"%sThree times over the Vistula and first to the Stadium in %s%s, %.1f s ahead of Seba. %s +%d zł · respect +%d%s" % [
				crown_en, _clock(_race_time), record, margin, line[1], stake, gain, total] + ("\n" + told[1] if told[1] != "" else "")],
				PackedStringArray(["OK"]), 0.0, false, FINAL_COLOUR)
		_report_art(_seba, goal)
		Access.buzz(200, 1.0)
	else:
		var gave_up := why != ""
		show_card(["TRZY MOSTY · PRZEGRANA", "Three bridges · Lose"], [("%s\n„%s”\nRewanż: Rondo Daszyńskiego, w nocy.\n%s" % [
				"Finał poddany." if gave_up else "%s pierwszy pod Narodowym (mosty: %d/3, czas %s, zabrakło %s s)." % [who, _cp, _clock(_race_time), ("%.1f" % margin).replace(".", ",")], line[0], told[0]]).strip_edges(),
				("%s %s Rematch: Rondo Daszyńskiego, at night.\n%s" % [
				"You gave up the final." if gave_up else "%s got to the Stadium first (bridges %d/3, %s, %.1f s short)." % [who, _cp, _clock(_race_time), margin], line[1], told[1]]).strip_edges()],
				PackedStringArray(["OK"]), 0.0, false, LOSE_COLOUR)
		_report_art(_seba, goal)


## --ladder=N: the first N rungs beaten for this run (in memory; use with --nosave).
func preset_ladder(n: int) -> void:
	if ladder == null or wallet == null:
		return
	ladder.preset(n, Districts.today())
	_open_seen = ladder.open_count()
	hud.set_wallet(wallet.zl, wallet.respect)
	print("ladder: --ladder=%d: next %s, respect %d, open %d" % [n, _rung_name(ladder.next_rung()), wallet.respect, _open_seen])


## --trzy-mosty: the car at the start, Seba ahead, and the final at once (the clock is the
## caller's: main.gd starts the run at night). --trzy-mosty=N (1-3): from the river span of bridge N
## instead, the bridges before it counted, Seba 12 m behind in the next lane (screenshots, a quick
## finish: from a standing start on a short leg his head start decided it).
func start_final_now(bridge := 0) -> bool:
	if final_route == null:
		push_warning("--trzy-mosty: the lane graph has no route for the final")
		return false
	var k := clampi(bridge, 0, final_route.checkpoints.size()) - 1
	_start_leg = 2 * k + 1 if k >= 0 else 0
	var e := -1
	var s := 0.0
	if k >= 0:
		e = final_route.checkpoints[k]["edge"]
		s = minf(graph.e_s0[e] + 150.0, graph.e_len[e] * 0.5 - 30.0)
		_ghost_spot = [e, 0, s]
		var q := graph.point_at(e, s, graph.lane_offset(e, 0))
		var dir := graph.direction(e, s)
		car.global_position = Vector3(q.x, graph.height(e, s), q.y)
		car.rotation.y = atan2(-dir.x, -dir.y)
	else:
		car.global_position = final_route.start_pos
		car.rotation.y = final_route.start_yaw
	car.vel = Vector3.ZERO
	car.reset_physics_interpolation()
	start_final()
	if e >= 0:
		traffic.teleport(_drivers[_seba], e, mini(1, graph.e_lanes[e] - 1), s - 12.0)
		_drivers[_seba].held = true
	return true


# --- testing aids ------------------------------------------------------------------

## --rival=n: puts rival i just ahead of the player's car on its lane.
## Returns false if no lane is near the car.
func put_ahead(i: int, gap := 14.0) -> bool:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit := graph.snap(p, 40.0, heading, true)
	if hit.is_empty():
		hit = graph.snap(p, 120.0, Vector2.ZERO, true)
	if hit.is_empty():
		return false
	var e: int = hit[0]
	var lane: int = hit[1]
	var s := clampf(hit[2], graph.e_s0[e] + 2.0, maxf(graph.e_s1[e] - gap - 6.0, graph.e_s0[e] + 2.0))
	traffic.teleport(_drivers[i], e, lane, s + gap)
	var q := graph.point_at(e, s, graph.lane_offset(e, lane))
	var dir := graph.direction(e, s)
	car.global_position = Vector3(q.x, graph.height(e, s), q.y)
	car.rotation.y = atan2(-dir.x, -dir.y)
	car.vel = Vector3.ZERO
	car.reset_physics_interpolation()
	return true


## The autopilot drives the player's car (returns true while it does): along the
## race route on a ghost driver, or 9 m behind the rival it is told to tail. A race whose ghost
## could not be made: nothing drives the car, as before the kit; the director's slide would take
## it to the finish.
func drive_player() -> bool:
	if _ghost != null and (state == State.COUNTDOWN or state == State.RACE):
		_follow(_ghost.pos, _ghost.yaw, _ghost.v)
		return true
	if tail >= 0 and (state == State.CRUISE or state == State.PROMPT):
		var d = _drivers[tail]
		var fwd := Vector3(-sin(d.yaw), 0.0, -cos(d.yaw))
		_follow(d.pos - fwd * 9.0, d.yaw, maxf(d.v, 3.0))
		return true
	return has_target()


func _start_ghost() -> void:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit := graph.snap(p, 40.0, heading, true)
	if final_on and not _ghost_spot.is_empty():
		hit = _ghost_spot
	if hit.is_empty():
		return
	_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])
	_ghost.held = true
	_ghost.speed_factor = ghost_pace
	_ghost.accel_factor = 2.2 * ghost_pace / 1.8
	if ghost_pace > 10.0:
		# --ghost-pace=racer: a skilled player, racer mode at the car's own top on the roads.
		_ghost.speed_factor = 1.8
		_ghost.race_top = player_top()
		_ghost.race_accel = 12.0
		_ghost.race_lat = 8.5
	if final_on:
		_prepare_final()
		traffic.race_to(_ghost, final_route.legs[_ghost_leg], _distances(final_route.legs[_ghost_leg]))
		return
	# Roads only (the ghost knows no shortcuts: a route counting cuts would send it round them).
	traffic.race_to(_ghost, _finish["node"], _distances(_finish["node"]))


func _follow(at: Vector3, yaw: float, speed: float) -> void:
	car.collision_mask = 0
	car.global_position = at
	car.rotation.y = yaw
	car.vel = Vector3(-sin(yaw), 0.0, -cos(yaw)) * speed
	car.throttle = 0.0
	car.braking = false
	car.target_dir = Vector3.ZERO
	car.reset_physics_interpolation()


static func _money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out + " zł"


static func _clock(seconds: float) -> String:
	var tenths := maxi(0, int(seconds * 10.0))
	return "%d:%02d.%d" % [tenths / 600, (tenths / 10) % 60, tenths % 10]
