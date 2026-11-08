extends Node3D
## Loop MW-3 (docs/design/vision.md 3.1-3.3, 3.2's Plac Zbawiciela, 4.5): the night and the river's
## people. Standing and sitting figures in the pedestrians' mesh and material (Models.person_mesh,
## actor.gdshader: the legs' swing off for the still ones, a lower, longer instance for a sitter;
## no new shader, no sun shadow):
##  - **the queues** at the clubs of vision 4.5's table (`CLUBS`, places.json ids): `max_len ×
##    hour curve × weekday`, rounded, rewritten every 20-40 s, in a line 0.7 m apart on the
##    footway nearest the place (no storefronts yet: MW-2), dark clothes, the bouncer at the head;
##    the door turns one away every 30-60 s while a queue of 4 or more is on screen (a `club_door`
##    `reject` bubble); the car at the door (< 10 km/h within 8 m) gets the bouncer's `car` line
##    once per club per night (the garage loop: painted black, the `car_black` line; at Lusterko's
##    door on a Friday or Saturday night, 23:00-06:00, egg E01 through `egg`, `door_egg`);
##  - **Level 26's roof crowd** on the tower's top at its place (vision's roof curve), when the
##    roof grid says the tower is there; F's asks (2026-10-30): the place's anchor moved onto the
##    tower (places.json `near`), the figures stand by the parapet of the roof grid's outline
##    (`roof_ring`: 48 rays round the top floors), a short queue waits at the
##    ground-floor door (`level_26_door`, a queue site with the `club_door` lines), and while the
##    club is open (the roof curve's hours) and near, a violet band of light rings the top floor
##    (one mesh in Models.material(), LIT_SIGN: +1 draw call, hidden by day and far);
##  - **the observation decks** (F, 2026-11-01): visitors on the Varso Tower's roof deck (the
##    tallest in the EU, 230 m; a ring of figures at the crown's parapet, from the roof grid like
##    Level 26) and on St Anne's bell tower terrace (the gallery round the octagon, 25 m up, the
##    model's balustrade): open 10-22 and 10-19, the afternoon and evening busier, weekends,
##    summer and dry weather fuller (`deck_level`); standing, facing out over the city;
##  - **Marszałkowska's tram platforms** (F, 2026-11-01): people waiting on every mapped platform
##    beside the street (`stop` sites, `stop_level`: the commute curve 7-9 and 15-18, thin on a
##    weekend, fuller in rain), standing figures in the same MultiMeshes;
##  - **the office crowd at Rondo Daszyńskiego** (F, 2026-11-02): office workers (white shirts, navy,
##    grey; a lanyard, a laptop bag and a coffee are the jokes of their lines, not meshes) in groups
##    at the metro exits and zebra crossings (`OFFICE`, kind `office`: standing figures in the
##    same cell MultiMeshes) and walking the footways, over the crossings, between the metro exits
##    and the towers (the walkers of the dawn crowd, mode `office`: the same MultiMesh, +0 draw
##    calls, routes found once by A* when the view comes near). Weekday rush hours (`office_level`),
##    `amount` scales both; their lines are the `office` group (KPIs, OKRs, "spotkanie które mogło być
##    mailem"), a bubble every 12-25 s on screen;
##  - **the dawn crowd** (Sat/Sun 05:00-09:00, Live or the Dawn look): 20-40 walkers in twos and
##    threes on footway routes from Lusterko, Smoła and Jasna 0 to the Palm, Metro Nowy
##    Świat-Uniwersytet, the nearest tram platforms and two kebab stands (A* over the footways
##    and crossings, in a worker thread once); a `dawn_crowd` bubble once per 25 s in view;
##  - **the steps crowd** by Kopernik (vision 3.3): max 80 × hour × month × rain, groups of 2-6 in
##    rows facing the river (sitters, standers at the water's edge), the guitarist (egg E15);
##    without Live the season is summer (vision Open Question 5);
##  - **Plac Zbawiciela's summer crowd** (up to 40 standing in groups, Fri/Sat 21:00-02:00);
##  - loop MW-4 (vision 3.4): **the trend queues** at the three Wiralek slots and Lukrownia
##    (`TRENDS`): their length and the line's tag come from `trend` (city_life.gd's cycle and Fat
##    Thursday), bright clothes, no bouncer, a `viral` line now and then;
##  - **the police by the clubs** (Fri/Sat 00:00-08:00, Lusterko and Smoła): a parked patrol car
##    (police.gd `club_park`, the existing police units, never a chase) and an officer standing by
##    it (`police_club` lines).
## Drawing: one MultiMesh per 512 m sector cell for every still figure in it, rewritten only when a
## crowd in it changes, its AABB the figures' box (so a cell out of view costs nothing), hidden
## while empty; the dawn walkers one more MultiMesh, moved at 10 Hz while near the view. Crowds
## more than ACTIVE_R m from the view's focus have no figures at all. The logic ticks at 2 Hz.
## The rules are static functions (check_crowds.gd runs them on synthetic clocks).

const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Storefronts := preload("res://scripts/storefronts.gd")
const Zaglebie := preload("res://scripts/zaglebie.gd")
const LoudCars := preload("res://scripts/loud_cars.gd")

## Seconds between two ticks of the logic.
const TICK := 0.5
## The sector size: one still crowd MultiMesh per cell.
const CELL := 512.0
## A crowd has figures only while the view's focus is this near its place (m).
const ACTIVE_R := 350.0
## The walkers move this often (s), while the dawn crowd is near the view.
const WALK_TICK := 0.1
const QUEUE_GAP := 0.7
## Seconds between two rewrites of a crowd's size (vision 4.5: "rewritten every 20-40 s").
const REWRITE := Vector2(20.0, 40.0)
## The door: one rejection every 30-60 s with a queue of DOOR_MIN or more on screen.
const DOOR_GAP := Vector2(30.0, 60.0)
const DOOR_MIN := 4
## The car at the door: within CAR_NEAR m under CAR_KMH.
const CAR_NEAR := 8.0
const CAR_KMH := 10.0
## A dawn_crowd bubble once per DAWN_GAP s in view; a clubber's line every CHAT_GAP s.
const DAWN_GAP := 25.0
const CHAT_GAP := Vector2(35.0, 60.0)
## The police by a club: their lines to a slow car within POLICE_NEAR m, at most every POLICE_GAP s.
const POLICE_NEAR := 15.0
const POLICE_GAP := 45.0
## A queue starts on the footway within this of its place.
const FOOT_REACH := 40.0
const STEPS_MAX := 80
const PLAN_C_MAX := 40
## City-life satire #1 (loud_cars.gd, 2026-11-02): the car meet at Browary's gate square, people
## standing round the parked supercars with their phones (kind `meet`, loud_cars.gd meet_slots():
## PER_CAR a car, facing it), on `meet_level`; their `car_meet` lines every CHAT_GAP s on screen.
## Off (`meet_on` false) with --loud=0, as the cars are.
const MEET_ID := "car_meet_browary"
const MEET_MAX := 21
## F's asks (2026-11-01): the observation decks (Varso, St Anne's, PKiN). `at` is where the roof grid is read (Varso) or
## the terrace's centre (`top`: the deck's height over the ground, so a mast over it is
## flattened away; St Anne's: a square ring, `half` m from the centre along `axis`, at
## `up` m over the ground, the bell tower of landmarks.gd `_anna_tower`); `open`/`close` the
## hours (*guess*), `max` the most at once.
const DECKS := {
	"varso_deck": {"at": Vector2(-1622.0, 583.0), "max": 14, "open": 10.0, "close": 22.0, "in": 1.6, "top": 234.0},
	"anna_deck": {"at": Vector2(-689.275, -1379.575), "max": 8, "open": 10.0, "close": 19.0,
			"half": 5.0, "axis": Vector2(0.985, -0.174), "up": 25.1, "gap": 1.9},
	# The Palace of Culture's 30th-floor terrace (114 m), the ledge round the shaft of landmarks.gd
	# `_build_palace`; open 10-18 (*guess*), the busiest of the three.
	"pkin_terrace": {"at": Vector2(-1214.25, 247.3), "max": 16, "open": 10.0, "close": 18.0,
			"half": 22.4, "axis": Vector2(0.9403, -0.3404), "up": 114.0, "gap": 3.0},
	# The Forest's roof terrace (F, 2026-11-01) on its 27.4 m wing, landmarks.gd `_forest_terrace`;
	# open 11-23 (*guess*), people inside the glass balustrade and the planters.
	"forest_terrace": {"at": Vector2(-2947.0, -2407.0), "max": 14, "open": 11.0, "close": 23.0, "in": 2.6, "top": 27.4},
}
const ROOF_MAX := 16
## F's ask (2026-11-02): the office crowd round Rondo Daszyńskiego (the Spire, the HUB and Plac
## Europejski's towers). `OFFICE` is id -> [spot, most people, radius]: the standing groups at
## the metro exits and at the zebra crossings' kerbs, read off centrum.json's `paths` (k "zebra")
## and `pois` (subway_entrance) *guess*; the walkers use every subway exit within OFFICE_REACH of
## OFFICE_AT and the towers' foyers in OFFICE_ENDS.
const OFFICE := {
	"office_metro_w": [Vector2(-2832.0, 470.0), 16, 14.0],
	"office_metro_e": [Vector2(-2760.0, 458.0), 16, 14.0],
	"office_zebra_n": [Vector2(-2752.0, 402.0), 14, 12.0],
	"office_zebra_s": [Vector2(-2742.0, 445.0), 14, 12.0],
	"office_zebra_e": [Vector2(-2650.0, 425.0), 14, 12.0],
	"office_hub": [Vector2(-2672.0, 366.0), 14, 12.0],
	# F's ask (2026-11-07): the other five of the station's seven entrances (OSM refs 5, 6, 7, 2, 1),
	# so every mouth has its crowd, not two.
	"office_metro_5": [Vector2(-2878.4, 485.1), 10, 10.0],
	"office_metro_6": [Vector2(-2890.5, 440.1), 10, 10.0],
	"office_metro_7": [Vector2(-2845.5, 424.8), 10, 10.0],
	"office_metro_2": [Vector2(-2771.8, 416.4), 10, 10.0],
	"office_metro_1": [Vector2(-2786.5, 400.2), 10, 10.0],
}
const OFFICE_AT := Vector2(-2795.0, 442.0)
const OFFICE_REACH := 230.0
const OFFICE_ENDS := [["office_spire", Vector2(-2700.0, 195.0)], ["office_hub_b", Vector2(-2670.0, 565.0)]]
## Most walkers at once (before `amount`), and how far from their box the view wakes them.
const OFFICE_MAX := 104
## F's ask (2026-11-07): waves at the crossings. A walker reaching a zebra's kerb on a red waits
## there (a queue XING_QUEUE m deep) and the whole bunch crosses when it turns green, so the
## flow comes in waves like the real rondo. Each zebra has a XING_CYCLE s cycle with XING_WALK s
## of walk, offset by one of XING_PHASES (so the approaches take turns); nobody steps out in the
## last XING_LATE s of the walk. All *guesses*; not the cars' signals (lane_graph.gd), whose
## controllers are only built with the traffic.
const XING_CYCLE := 60.0
const XING_WALK := 24.0
const XING_LATE := 5.0
const XING_PHASES := 3
const XING_QUEUE := 2.4
const OFFICE_NEAR := 450.0
## A bubble from an office walker or group every OFFICE_GAP seconds on screen.
const OFFICE_GAP := Vector2(12.0, 25.0)
## Shirts, jackets and blouses: white, pale blue, grey, navy, beige, black.
const OFFICE_SHIRTS := ["#f2efe8", "#bcd3e6", "#8c9199", "#1c2a45", "#d9c9ad", "#25272d", "#e8e4d8", "#6f8ea4"]
## F's ask (2026-11-01, Marszałkowska street by street): people waiting on the tram platforms of
## Marszałkowska. A platform (centrum.json `platforms`) within STOP_REACH m of a road named
## `STOP_STREET` gets a site; its most people = area / STOP_AREA, at most STOP_MAX.
## F's ask (2026-11-07, "people at tram and bus stops and so on"): every tram platform in the city
## gets one (ids `stop_N`; Marszałkowska's keep `stop_marsz_N`), standing on the platform's top
## (not sunk into a 0.9 m slab). Only crowds within ACTIVE_R of the view have figures, so the
## city-wide sites cost a distance check each per tick. The bus stops' people are buses.gd's own
## (they board the buses).
const STOP_STREET := "Marszałkowska"
const STOP_REACH := 25.0
const STOP_AREA := 22.0
const STOP_MAX := 12
## F's LIM photos (2026-11-06): the Dworzec Centralny tram stop on Aleje Jerozolimskie, in front
## of Centrum LIM, is full at all hours (the station across the street). Its platforms (centres
## within STOP_CENTRALNY_REACH m of the point) get `stop` sites too, up to STOP_CENTRALNY_MAX
## people each, never under STOP_CENTRALNY_FLOOR of that even at night.
const STOP_CENTRALNY := Vector2(-1410.0, 660.0)
const STOP_CENTRALNY_REACH := 40.0
const STOP_CENTRALNY_MAX := 16
const STOP_CENTRALNY_FLOOR := 0.4
const DAWN_MIN := 20
const DAWN_MAX := 40
## The night's minute log (--night-log).
const LOG_EVERY := 60.0

## vision.md 4.5's clubs (places.json ids): max_len, the hour curve, the police and the dawn crowd.
const CLUBS := {
	"lusterko": {"max": 24, "curve": "after", "police": true, "dawn": true},
	"smola": {"max": 24, "curve": "club", "police": true, "dawn": true},
	"jasna_0": {"max": 16, "curve": "club", "dawn": true},
	"lombard": {"max": 16, "curve": "club"},
	"milosc_hipoteczna": {"max": 16, "curve": "club"},
}
## Loop MW-4: the trend queues (places.json ids) and their longest line (vision 3.4: day 1's 30,
## Fat Thursday's 60 at Lukrownia).
const TRENDS := {"wiralek_zbawiciela": 30, "wiralek_chmielna": 30, "wiralek_tamka": 30, "lukrownia": 60}
## Trend follow-up (docs/design/trends-2025-26.md): PISTACJA DO KOŃCA's queue is a site of its own
## (a storefront venue, not a places.json id): `PISTACJA_BASE` people in the shop's hours, and
## `PISTACJA_MAX` in the Friday "limited drop" (`PISTACJA_DROP` hours *guess*).
const PISTACJA_ID := "trend_pistacja"
const PISTACJA_BASE := 7
const PISTACJA_MAX := 36
const PISTACJA_HOURS := [10.0, 22.0]
const PISTACJA_DROP_DAY := 5
const PISTACJA_DROP := [16.0, 18.5]
## PADELNIA's line (docs/design/padel.md): people waiting for a court on weekday evenings
## (17-23) and weekend mornings (9-13), tag "padel" (its `viral` lines). It is a storefront
## venue like PISTACJA, so a site of its own.
const PADEL_ID := "trend_padelnia"
const PADEL_MAX := 14
## The food hype (docs/design/gaulle-and-food-hype.md G3, G4): KUKŁA's crêpe queue (storefront
## venues, Storefronts.HYPE) is never short while it is open, 9:00-21:00: 8 in the morning, 30 at
## lunch (12-15) and on weekend afternoons, 14 otherwise; tag "kolejka". HOTEL PIURE's door has
## the evening line for the lift up to LORETKA, the date bar on its roof: 18:00-01:00, 10 (16 on
## Friday and Saturday), in twos, tag "timber".
const KUKLA := ["kukla_marszalkowska", "kukla_nowy_swiat"]
## G5: the "Mrożulo effect" (trend_job.gd's "Mlask"): a reviewed place's queue at its longest
## while it's open, for the rest of that game day, tag "mrozulo" (the fans' `viral` lines).
const KUKLA_MAX := 30
const PIURE_ID := "hotel_piure"
const PIURE_MAX := 16
## F (2026-11-01): LORETKA's summer terrace on HOTEL PIURE's roof, couples on its poufs
## (landmarks.gd `loretka_plan`, the same seats the model builds): May to September, dry
## evenings 17:00-01:00, every seat on Friday and Saturday, 10 otherwise.
const LORETKA_ID := "loretka_terrace"
## F (2026-11-06): the jazz evenings under the Powiśle saucer (landmarks.gd powisle_jazz_plan):
## the band on the stage (four, while the concert is on), sitters in the deck chairs and an
## audience standing in front, 18:30-23:30 every evening, fuller on Friday and Saturday and in
## the summer, thinner in rain; and the café's tables round the terrace from noon.
const JAZZ_ID := "powisle_jazz"
const JAZZ_CAFE_ID := "powisle_cafe"
const JAZZ_HOURS := Vector2(18.5, 23.5)
const JAZZ_BAND := 4
## The band's shirts: black, white, a mustard jacket, a burgundy one.
const JAZZ_SHIRTS := ["#1b1b1e", "#f1efe9", "#c99a2e", "#6e2230"]
const LORETKA_WEEKNIGHT := 10
const Landmarks := preload("res://scripts/landmarks.gd")
const FirstScene := preload("res://scripts/first_scene.gd")
const ROOF_ID := "level_26"
## F's asks (2026-10-30): Level 26's queue at the tower's ground-floor door (a queue site of its
## own, not a places.json id), its longest line (short: the lift takes eight at a time), the
## roof ring's rays, the band's place under the roof (m) and its colour.
const ROOF_DOOR_ID := "level_26_door"
const ROOF_DOOR_MAX := 8
const RING_RAYS := 48
const RING_TOP := 1.0
const RING_H := 2.0
const RING_OUT := 0.25
## The roof crowd stands this far inside the grid's edge: the facade is at most a cell (4 m)
## inside it, so they are on the roof, a step or two from the parapet.
const RING_IN := 4.6
const RING_COLOUR := Color("#a35cff")
const STEPS_ID := "schodki_kopernik"
const PLAN_C_ID := "plan_c"
## F's ask (2026-11-01): people chilling round the four food-and-culture yards of the west and
## south, Norblin, Browary Warszawskie, Hala Koszyki and Elektrownia Powiśle. id -> [spot (the
## yard), most people, radius to look for footways (m)]. A spot that finds no footway puts its
## people in a loose spiral round the point.
const CHILL := {
	"chill_norblin": [Vector2(-2236.0, 204.0), 30, 34.0],  # the court's mouth on the glass street (photo report)
	"chill_browary": [Vector2(-2503.0, -100.0), 36, 36.0],
	"chill_koszyki": [Vector2(-884.0, 1266.0), 30, 30.0],
	"chill_elektrownia": [Vector2(285.0, -738.0), 34, 36.0],
}
## F's ask (2026-11-01): the Vistula boulevards (Bulwary Wiślane, Karowa to Most Świętokrzyski and on
## past Kopernik) full of people chilling: groups on the granite steps and benches along the river
## edge, about 40-60 m apart, bigger by the Kopernik steps' neighbours. id -> [spot, most people,
## radius]. Same machinery as CHILL (their level is `chill_level`: the long summer evening). The
## spots lie on the boulevard's river edge read off the baked steps and benches *guess* (a photo
## check on the phone is parked in QUESTIONS). city_life.gd's fast riders and dog walkers use the
## same spots (`BULWARY_R`).
const BULWARY := {
	"chill_bulwary_1": [Vector2(250.0, -1010.0), 18, 30.0],
	"chill_bulwary_2": [Vector2(330.0, -970.0), 16, 30.0],
	"chill_bulwary_3": [Vector2(385.0, -925.0), 18, 30.0],
	"chill_bulwary_4": [Vector2(440.0, -872.0), 20, 30.0],
	"chill_bulwary_5": [Vector2(480.0, -835.0), 20, 28.0],
	"chill_bulwary_6": [Vector2(540.0, -705.0), 18, 30.0],
	"chill_bulwary_7": [Vector2(590.0, -680.0), 24, 32.0],
	"chill_bulwary_8": [Vector2(640.0, -632.0), 18, 30.0],
	"chill_bulwary_9": [Vector2(690.0, -590.0), 16, 30.0],
}
## Nowy Świat pass 2 (2026-11-02): the café street's pavements, people at the terraces and between
## the shops, on the chill curve (a lunch crowd that fills towards a long evening). id -> [spot (the
## café terraces the street details put on its pavement), most people, radius]. The same machinery
## as CHILL. Spots read off street_details.json's café sets.
const NOWY_SWIAT := {
	"chill_nowy_1": [Vector2(-412.0, -296.0), 12, 20.0],
	"chill_nowy_2": [Vector2(-380.0, -331.0), 12, 20.0],
	"chill_nowy_3": [Vector2(-386.0, -231.0), 10, 20.0],
	"chill_nowy_4": [Vector2(-356.0, -72.0), 12, 22.0],
}
## Nowogrodzka's bar strip (street-by-street, 2026-11-03): people with a glass and a cigarette on
## the pavement in front of the bars between Marszałkowska and Bracka, on the `pub` curve (a few
## after work, fullest 22-01, thinning by 03; `pub_level`). id -> [spot (the pavement in front of
## the real bars' OSM points, game coordinates; the yards of nos. 11 and 22 at their gates), most
## people, radius]. The same machinery as CHILL, standing more than
## sitting; the bars' parody fascias are storefronts.gd's NOWOGRODZKA.
const NOWOGRODZKA := {
	"pub_nowo_kwarta": [Vector2(-383.0, 423.0), 8, 12.0],
	"pub_nowo_bardzo": [Vector2(-423.0, 455.0), 12, 14.0],
	"pub_nowo_halinka": [Vector2(-502.0, 475.0), 10, 14.0],
	"pub_nowo_kraft": [Vector2(-553.0, 480.0), 8, 12.0],
	"pub_nowo_23": [Vector2(-625.0, 520.0), 12, 14.0],
	"pub_nowo_22": [Vector2(-680.0, 528.0), 14, 16.0],
	"pub_nowo_27": [Vector2(-695.0, 547.0), 10, 14.0],
}
## Wilcza and Poznańska's bars (street-by-street, 2026-11-03): people with a glass and a cigarette on the
## pavement in front of the bars, on the `pub` curve like NOWOGRODZKA. id -> [spot (game coordinates),
## most people, radius]. The fascias are storefronts.gd's WILCZA.
const WILCZA := {
	"pub_wil_muza": [Vector2(-409.1, 958.5), 10, 14.0],
	"pub_wil_goraczka": [Vector2(-505.9, 1005.2), 14, 14.0],
	"pub_wil_aura": [Vector2(-548.1, 831.8), 8, 12.0],
	"pub_wil_macki": [Vector2(-799.0, 1031.9), 12, 14.0],
	"pub_wil_kaseta": [Vector2(-794.9, 1122.0), 8, 12.0],
	"pub_wil_banany": [Vector2(-805.8, 1108.7), 10, 12.0],
}
## Praga's bars (street-by-street, 2026-11-03): people with a glass and a cigarette outside the bars of
## Okrzei, Wrzesińska, Kijowska and Targowa, on the `pub` curve (Praga's evenings are milder than the
## centre's, the maxima are smaller). id -> [spot (game coordinates), most people, radius]. The fascias are
## storefronts.gd's PRAGA.
const PRAGA := {
	"pub_praga_swiat": [Vector2(768.9, -1897.7), 10, 12.0],
	"pub_praga_barista": [Vector2(511.1, -1659.5), 6, 10.0],
	"pub_praga_skrzynka": [Vector2(645.0, -1717.0), 6, 10.0],
	"pub_praga_kraina": [Vector2(758.5, -1744.0), 8, 12.0],
	"pub_praga_kijowska": [Vector2(1380.7, -1770.0), 8, 12.0],
	"pub_praga_kufel": [Vector2(1475.1, -1567.3), 10, 12.0],
}
## The Powiśle viaduct's bars (F, 2026-11-03): people with a glass at the café tables and the doors of
## the five bars in the closed bays under Most Poniatowskiego (map_builder PV_BARS, storefronts.gd VIADUKT),
## on the `pub` curve. id -> [spot 2 m out of the arcade's face, most people, radius].
const VIADUKT := {
	"pub_via_qbar": [Vector2(537.5, -21.1), 8, 7.0],
	"pub_via_luk": [Vector2(588.7, -38.1), 6, 7.0],
	"pub_via_nity": [Vector2(529.1, 11.6), 8, 7.0],
	"pub_via_beton": [Vector2(563.3, 0.2), 6, 7.0],
	"pub_via_filar": [Vector2(614.5, -16.9), 5, 7.0],
}
## Mazowiecka's club street (street-by-street, 2026-11-03): people in the queues and smokers on the
## pavement outside the clubs of Mazowiecka between Świętokrzyska and Królewska, on the `club` curve
## (`club_level`: the existing clubs' curve, fullest 01-02, thinning by 05, the clubs' own WEEKDAY factor, so
## Friday and Saturday nights). id -> [spot (the pavement in front of the doors, game coordinates),
## most people, radius]. The fascias are storefronts.gd's MAZOWIECKA.
const MAZOWIECKA := {
	"club_maz_tygmont": [Vector2(-745.0, -342.0), 10, 10.0],
	"club_maz_sketch": [Vector2(-748.0, -413.0), 14, 12.0],
	"club_maz_room": [Vector2(-754.0, -440.0), 12, 12.0],
	"club_maz_bank": [Vector2(-751.0, -460.0), 12, 12.0],
	"club_maz_lombard": [Vector2(-760.0, -497.0), 10, 10.0],
}
## SOWA CLUB and CITY 25 (F's photos, 2026-11-06; landmarks.gd `_build_sowa`): night owls on the
## pavement in front of the neon pavilion's terrace on Al. Jerozolimskie, on the `club` curve like
## MAZOWIECKA, with their own lines (`sowa_club`, `talk`). id -> [spot, most people, radius].
const SOWA := {
	"club_sowa": [Vector2(56.6, 134.2), 10, 4.5],
}
## The pub crowd's weekday factor *guess*, Monday first, by the night's day (01:00 Saturday is
## Friday's night): milder than the clubs', the strip is never empty after work.
const PUB_WEEKDAY := [0.45, 0.45, 0.55, 0.75, 1.0, 1.0, 0.4]
## First scene item 6 (docs/design/first-scene.md, 2026-11-02): the start's own street life, people at
## first_scene.gd's furniture on Marszałkowska by Plac Defilad, so the first frame of play has
## people standing on both pavements and not only walkers. id -> [s, t in first_scene.gd's frame
## (s north along the street, t east of it), most people, radius (m), some sit]. The museum's café
## tables and the pavilions' under the towers seat a third of theirs; the kiosk and flower stall
## and the paving north of the museum have standers (a newspaper, a bunch of tulips, a chat). Same
## machinery as CHILL, on the `street` curve (a city centre by day, never empty from 8 to 21).
const FIRST_SCENE := {
	"street_msn_cafes": [104.0, -19.0, 10, 9.0, true],
	"street_kiosk": [145.0, -18.5, 7, 8.0, false],
	"street_pavilions": [194.5, 31.0, 10, 10.0, true],
	"street_north": [196.0, -26.0, 8, 10.0, false],
	# Pasaż Wiecha behind the stores (2026-11-02): its north café garden (the one on the square by
	# Chmielna lies past the start box's edge).
	"street_wiecha_north": [90.0, 69.0, 8, 8.0, true],
}
## The Palace of Culture's venues (F, 2026-11-07): Bar Studio's garden (landmarks.gd
## pkin_studio_plan, sitters in its deck chairs on the jazz café's curve: a summer evening's
## garden) and the evening audiences outside the Palace's stages (Landmarks.pkin_theatre_doors):
## id -> most people. Same machinery as CHILL on the `theatre` curve (theatre_level).
const STUDIO_ID := "bar_studio"
const THEATRES := {"theatre_dramatyczny": 16, "theatre_studio": 12, "theatre_kinoteka": 14, "theatre_kongresowa": 22}
## The stages' weekday factor *guess*, Monday first: most are dark on Mondays, full at weekends.
const THEATRE_WEEKDAY := [0.15, 0.7, 0.75, 0.8, 1.0, 1.0, 0.85]
## The boulevard's reach (m) round a BULWARY spot: the view this near it is "on the boulevards".
const BULWARY_R := 90.0
## KROWA 2.0, the milk bar in Norblin (our parody; a bar mleczny rebuilt as a start-up): it opens
## 8:00-18:00 and its line is long at lunch. Same trend-queue machinery as KUKŁA, tag "kolejka".
const MILK := ["krowa_norblin"]
const MILK_MAX := 26
## DALEJ DALLA GELATO, the Powiśle ice-cream parlour (F, 2026-11-01; "dalej" = move along, the
## queue's word): the joke is that Poland queues for lody all year. Open 11:00-21:00, never under
## 12 in the queue even in snow (tag "lody_zima", the crowd in winter coats), 24 on summer
## afternoons and weekends (tag "lody"). Same trend-queue machinery as KUKŁA.
const GELATO := ["dalej_gelato"]
const GELATO_MAX := 24
const GELATO_WINTER_MIN := 12
## The winter queue's coats: black and navy puffers, a mustard one, a cream one, a red scarf's worth.
const COATS := ["#1f1f22", "#1c2230", "#2b2c2f", "#3a3b3f", "#c9a23a", "#e8e4d8", "#8a2b2b", "#2f4f4a"]
## ZAKWAS I ROŻEN, the craft kebab in the Zagłębie Kebabowe (docs/design/zaglebie-kebabowe.md): the
## hand-carved one is worth a wait. Open 12:00-24:00, 8 in the queue most of the day, 18 on
## Friday and Saturday evenings (18-23), 14 on the other evenings; tag "zakwas". Same trend-queue
## machinery as KUKŁA; the shop's spot comes from `Zaglebie.SHOPS`.
const ZAKWAS_TAG := "zag_rozen"
const ZAKWAS_ID := "trend_zakwas"
const ZAKWAS_MAX := 18
## KRINGULA PIZZA (F's list of ideas #6, 2026-11-02; a parody of the Neapolitan pizzeria Warsaw
## queues for): the hype shop, open 12:00-23:00, never under 24 in the line, 40 at the Friday and
## Saturday dinner hours and on a Sunday afternoon; tag "kringula" (ecstatic fans, placeholder copy,
## the real joke is F's to write: QUESTIONS). Same trend-queue machinery as KUKŁA, so the
## "Mrożulo effect" lifts it too.
const KRINGULA := ["kringula_pizza"]
const KRINGULA_MAX := 40
const KRINGULA_MIN := 24
## MIESZANE MIESZANE (F's #11, 2026-11-02): the kebab window beside the Zagłębie where the order is
## the same word twice. A short evening line (18:00-04:00, longest after the clubs close, 3-4 am),
## tag "mieszane" (the people in it say the two words; no new system, trend-queue machinery).
const MIESZANE := ["kebab_mieszane"]
const MIESZANE_MAX := 14
## DŻEMINI KEBAB (F, 2026-11-06; trend_job.gd "Dżemini"): the new kebab an AI agent carves, open
## round the clock. Before Mrożulo's MLASK a handful wait (tag "dzemini_new"); after it (the save's
## `keep` "dzemini_mlask", `dzemini_hype`) the city's longest line for good: DZEMINI_MAX by day,
## DZEMINI_NIGHT 02:00-07:00, tag "dzemini" (the jokes about the agent).
const DZEMINI_ID := "dzemini_kebab"
const DZEMINI_MAX := 40
const DZEMINI_NIGHT := 26
const DZEMINI_NEW := 3
## The other hyped chains' morning lines (F's #5, huge queues everywhere): the green-café's pavilion
## and KOSZTA on Marszałkowska, 7:00-11:00 on a working day 16 and a half-length line later, tag "kolejka".
const COFFEE := ["nerwo_pawilon", "koszta_marszalkowska"]
const COFFEE_MAX := 16
## vision 4.5's hour curves (the hour's whole part; missing hours are 0). Lusterko's 09-12 is 0.5
## on a Sunday only (`queue_factor`).
const CURVES := {
	"club": {22: 0.1, 23: 0.3, 0: 0.6, 1: 1.0, 2: 1.0, 3: 0.7, 4: 0.4, 5: 0.1},
	"after": {0: 0.2, 1: 0.4, 2: 0.6, 3: 0.9, 4: 1.0, 5: 1.0, 6: 0.8, 7: 0.8, 8: 0.8},
	"roof": {22: 0.3, 23: 0.6, 0: 1.0, 1: 1.0, 2: 0.8, 3: 0.4},
	# *guess* (vision gives only "up to 40, Fri/Sat 21:00-02:00")
	"plan_c": {21: 0.5, 22: 0.8, 23: 1.0, 0: 1.0, 1: 0.7},
	# *guess*: lunch crowd, the long summer evening on the benches, thinning after 23:00
	"chill": {11: 0.25, 12: 0.4, 13: 0.5, 14: 0.5, 15: 0.55, 16: 0.7, 17: 0.85, 18: 1.0, 19: 1.0, 20: 1.0, 21: 0.9,
			22: 0.7, 23: 0.45, 0: 0.2},
	# *guess*: the commute, 7-9 and 15-18 on a working day, a thin shopping day on a weekend
	"commute": {5: 0.15, 6: 0.4, 7: 0.9, 8: 1.0, 9: 0.7, 10: 0.4, 11: 0.35, 12: 0.4, 13: 0.4, 14: 0.5, 15: 0.8,
			16: 1.0, 17: 1.0, 18: 0.8, 19: 0.5, 20: 0.35, 21: 0.25, 22: 0.2, 23: 0.1},
	# *guess*: the first scene's pavements (FIRST_SCENE): a city centre by day, lunch and the
	# after-work hours fullest, never empty from 8 to 21
	"street": {7: 0.3, 8: 0.5, 9: 0.6, 10: 0.65, 11: 0.75, 12: 0.9, 13: 1.0, 14: 0.95, 15: 0.9, 16: 0.95, 17: 1.0,
			18: 1.0, 19: 0.85, 20: 0.7, 21: 0.5, 22: 0.35, 23: 0.2, 0: 0.1},
	# *guess*: Nowogrodzka's bars (NOWOGRODZKA): a few after work, fullest 22-01, gone by 04
	"pub": {16: 0.1, 17: 0.15, 18: 0.25, 19: 0.4, 20: 0.55, 21: 0.75, 22: 0.9, 23: 1.0, 0: 1.0, 1: 0.85, 2: 0.55,
			3: 0.25},
	# *guess*: 20 walkers at the edges of 05-09, 40 at the peak
	"dawn": {5: 0.5, 6: 1.0, 7: 1.0, 8: 0.4},
	# *guess*: the Palace's stages (THEATRES): the audience gathers from 18:30 for a 19:00 curtain,
	# smokes at the interval near 20:30 and pours out at 21:30-22:00
	"theatre": {17: 0.1, 18: 0.55, 19: 0.9, 20: 0.35, 21: 0.6, 22: 0.8, 23: 0.15},
}
## vision 4.5's weekday factor *guess*, Monday first, by the night's day (01:00 Saturday is
## Friday's night).
const WEEKDAY := [0.2, 0.2, 0.2, 0.6, 1.0, 1.0, 0.3]
## The steps' hour curve (vision 4.5): [hour, level], the sunset's hour in between (`steps_curve`).
const STEPS_HOURS := [[10.0, 0.1], [14.0, 0.3], [18.0, 0.6], [23.0, 0.7], [25.0, 0.3], [27.0, 0.05]]
## The queue's and the dawn crowd's blacks; the steps' and the square's colours (pedestrians').
const DARK := ["#1f1f22", "#2b2c2f", "#33302e", "#25272d", "#3a3b3f", "#1c2230", "#2a2433"]
const BRIGHT := ["#d8432f", "#2f6fb5", "#e0b23a", "#3b8f5a", "#f2efe8", "#7a4fa8", "#e57aa0", "#c96b2c", "#5aa9c9", "#e8e4d8"]
const OFFICER_SHIRT := Color("#e8f23a")
const OFFICER_TROUSERS := 0.1
const BOUNCER_SHIRT := Color("#141416")
const GUITAR_SHIRT := Color("#ff9a3c")
const BUBBLE := Color("#c9a6ff")
const POLICE_BUBBLE := Color("#8fb0ff")

## The pose of a figure.
enum { STAND, SIT, BROAD }

## The "Mrożulo effect": trend site id -> the weekday it was reviewed on (mrozulo_boost).
var mrozulo := {}
## DŻEMINI KEBAB has had Mrożulo's MLASK (trend_job.gd sets it, from the save too): its line for good.
var dzemini_hype := false
var _weekday_now := 0
var _month_now := 7
## The view's focus (the camera's), -> Vector3.
var focus: Callable
## The game clock, -> {hour, weekday} (time_of_day.gd local_clock).
var clock: Callable
## The calendar, -> {live: bool, month, date (yyyymmdd or 0), look (TimeOfDay.NAMES), rain: bool,
## sunset: the hour of sunset (Live's date; the Dusk look's 19.5 without Live)}.
var calendar: Callable
## The vehicle, -> [position, km/h, flying].
var vehicle: Callable
## Is a world point on screen (traffic.gd on_screen), -> bool; unset: always.
var on_screen: Callable
var map: Node3D
var dialogue: Node
## police.gd (club_park, club_leave); may be null.
var police: Node
## city_sounds.gd (add_crowd); may be null.
var sounds: Node
## Loop MW-4: a trend queue's length now and its line's tag, (id) -> [n, tag] (city_life.gd
## `trend_queue`); unset: the trend queues stay empty.
var trend: Callable
## The garage loop: the car's paint now (garage.gd's id), -> String; unset: the factory red.
var paint: Callable
## The garage loop: an egg at a door (egg_book.gd `fire` with the probe's state), (id) -> bool:
## true on its first find.
var egg: Callable
## --crowd=: 0 none (this node isn't built), 1 normal, 2 double; the Low tier halves it.
var amount := 1.0
## City-life satire #1: the car meet's crowd (main.gd: off with --loud=0).
var meet_on := true
## --night-log: queues, rejections, the dawn walkers each minute and every event.
var log_on := false
## Time spent in this script since the bench last read it (µs).
var spent_usec := 0
## Counters (the log, the check).
var rejections := 0
var car_lines := 0
var dawn_lines := 0
## The crowds' sites: {id, kind (queue, roof, steps, plan_c, chill, deck, stop), at, n, want, max, ...}.
var sites: Array[Dictionary] = []
var by_id := {}
## The dawn crowd: its routes (after the worker thread) and walkers.
var routes: Array[Dictionary] = []
var walkers: Array[Dictionary] = []
var dawn_on := false
## The office crowd (2026-11-02): its routes, whether it is out, and which crowd the walkers are
## ("", "dawn" or "office"; `routes` stay the dawn's).
var office_routes: Array[Dictionary] = []
var office_on := false
var walk_mode := ""
var office_lines := 0
var police_on := false
## The levels for the eggs (egg_book.gd `crowd`): name -> 0..1.
var levels := {}
## Seconds of play (the logic's clock).
var t := 0.0

var _cells := {}
var _rng := RandomNumberGenerator.new()
var _tick_t := 0.0
var _walk_t := 0.0
var _log_t := 0.0
var _dawn_bubble := 0.0
var _mesh: ArrayMesh
var _still_mat: ShaderMaterial
var _walk_mat: ShaderMaterial
var _walk_mm: MultiMesh
var _walk_mmi: MultiMeshInstance3D
var _walk_buf := PackedFloat32Array()
var _walk_box := Rect2()
## The footways near the crowds: {pts: PackedVector2Array, dk: int, w: float, k: String}.
var _foot: Array[Dictionary] = []
var _route_task := -1
var _route_out: Array = []
var _route_in := {}
var _office_in := {}
var _office_box := Rect2()
var _route_mode := "dawn"
var _dawn_asked := false
var _office_asked := false
var _office_bubble := 0.0
## The zebras (polylines) the office walkers may cross; a route's `xs` index into this.
var _office_zebras: Array[PackedVector2Array] = []
## Walker-ticks spent waiting at a red kerb (for the check).
var held_ticks := 0
var _night_key := -1
var _last_hour := 0.0
## F's asks: Level 26's violet band (null until built: no tall roof there, or no map).
var _ring: MeshInstance3D


# --- the rules (static: check_crowds.gd) ---------------------------------------------------

## The weekday whose night `hour` belongs to: before noon, the day before (01:00 on Saturday is
## Friday's night). 1 Monday .. 7 Sunday.
static func night_day(hour: float, weekday: int) -> int:
	return (weekday + 5) % 7 + 1 if hour < 12.0 else weekday


## A curve's value at `hour` (its whole hour).
static func curve_at(curve: String, hour: float) -> float:
	return float((CURVES[curve] as Dictionary).get(int(floor(fmod(hour + 24.0, 24.0))), 0.0))


## A club's queue factor at `hour` on `weekday` (the calendar's): hour curve × weekday factor.
static func queue_factor(curve: String, hour: float, weekday: int) -> float:
	var h := curve_at(curve, hour)
	var w := float(WEEKDAY[night_day(hour, weekday) - 1])
	if curve == "after":
		if hour >= 9.0 and hour < 12.0:
			h = 0.5 if weekday == 7 else 0.0
		if weekday == 7 and hour < 12.0:
			w = 1.0  # Lusterko on Sunday morning
	return h * w


## vision 4.5: a club's queue (or the roof crowd) = max_len × hour curve × weekday, rounded.
static func queue_len(max_len: int, curve: String, hour: float, weekday: int, k := 1.0) -> int:
	return roundi(max_len * k * queue_factor(curve, hour, weekday))


## The steps' hour curve at `hour` with the sun setting at `sunset` (vision 4.5: 10:00 0.1, 14:00
## 0.3, 18:00 0.6, sunset 1.0, 23:00 0.7, 01:00 0.3, 03:00 0.05), straight lines between.
static func steps_curve(hour: float, sunset: float) -> float:
	var pts: Array = [[3.0, 0.05]]
	var sun := clampf(sunset, 18.25, 22.75)
	for p: Array in STEPS_HOURS:
		if float(p[0]) > sun and float(pts[pts.size() - 1][0]) < sun:
			pts.append([sun, 1.0])
		pts.append(p)
	var h := hour if hour >= 3.0 else hour + 24.0
	for i in pts.size() - 1:
		var a: Array = pts[i]
		var b: Array = pts[i + 1]
		if h >= float(a[0]) and h <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (h - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001))
	return 0.05


## The month's factor (vision 4.5: Jun-Aug 1.0, May and Sep 0.7, Apr and Oct 0.3, Nov-Mar 0.05).
static func month_factor(month: int) -> float:
	if month in [6, 7, 8]:
		return 1.0
	if month in [5, 9]:
		return 0.7
	if month in [4, 10]:
		return 0.3
	return 0.05


## The steps crowd's level 0..1 (hour × month × rain 0.1).
static func steps_level(hour: float, month: int, rain: bool, sunset: float) -> float:
	return steps_curve(hour, sunset) * month_factor(month) * (0.1 if rain else 1.0)


static func steps_count(hour: float, month: int, rain: bool, sunset: float, k := 1.0) -> int:
	return roundi(STEPS_MAX * k * steps_level(hour, month, rain, sunset))


## The guitarist plays while the steps hold 8 or more, 16:00-01:00 *guess*.
static func guitar_on(steps_n: int, hour: float) -> bool:
	return steps_n >= 8 and (hour >= 16.0 or hour < 1.0)


## Plac Zbawiciela's summer crowd: Fri/Sat nights 21:00-02:00, summer, dry (rain 0.1 *guess*).
## City-life satire #1: the car meet's level 0..1 (*guesses*): a few by day, the most from 20:00
## to 01:00, Friday and Saturday nights fuller, a third in the rain, nobody 04:00-10:00.
## Is the jazz concert on at `hour`? Every evening, JAZZ_HOURS.
static func jazz_on(hour: float) -> bool:
	var h := fmod(hour + 24.0, 24.0)
	return h >= JAZZ_HOURS.x and h < JAZZ_HOURS.y


## How full the jazz audience is (0..1 of the deck chairs and the standing places): half on a
## weeknight, full on Friday and Saturday (weekday 5, 6), fuller from May to September, a third
## off in rain (the saucer keeps the stage dry, not the audience); filling over the first hour.
static func jazz_level(hour: float, weekday: int, month: int, rain: bool) -> float:
	if not jazz_on(hour):
		return 0.0
	var h := fmod(hour + 24.0, 24.0)
	var lvl := 1.0 if weekday == 5 or weekday == 6 else 0.55
	if month < 5 or month > 9:
		lvl *= 0.7
	if rain:
		lvl *= 0.65
	return lvl * clampf(0.35 + (h - JAZZ_HOURS.x) * 0.65, 0.35, 1.0)


## The café's tables (0..1 of the seats): from noon, busiest in the evening, empty after 01:00
## and in the morning; summer fuller, rain nearly empty (the tables stand in the open).
static func jazz_cafe_level(hour: float, month: int, rain: bool) -> float:
	var h := fmod(hour + 24.0, 24.0)
	var lvl := 0.0
	if h >= 12.0 and h < 17.0:
		lvl = 0.45
	elif h >= 17.0:
		lvl = 0.85
	elif h < 1.0:
		lvl = 0.5
	if month < 5 or month > 9:
		lvl *= 0.5
	return lvl * (0.15 if rain else 1.0)


static func meet_level(hour: float, weekday: int, rain: bool) -> float:
	var h := int(floor(fmod(hour + 24.0, 24.0)))
	var lvl := 0.0
	if h >= 20 or h < 1:
		lvl = 1.0
	elif h >= 17:
		lvl = 0.7
	elif h >= 10:
		lvl = 0.35
	elif h < 4:
		lvl = 0.6
	if not night_day(hour, weekday) in [5, 6]:
		lvl *= 0.75
	return lvl * (0.3 if rain else 1.0)


static func plan_c_level(hour: float, weekday: int, month: int, rain: bool) -> float:
	if not night_day(hour, weekday) in [5, 6] or not month in [6, 7, 8]:
		return 0.0
	return curve_at("plan_c", hour) * (0.1 if rain else 1.0)


## An observation deck's level 0..1 (F's asks, 2026-11-01): 0 outside `open`..`close`, a ramp over
## the first and last 90 minutes, busiest round 17:00; weekends (6, 7) fuller than weekdays,
## summer fuller than winter, rain a fifth of dry (all *guesses*).
static func deck_level(hour: float, weekday: int, month: int, rain: bool, open: float, close: float) -> float:
	if hour < open or hour >= close:
		return 0.0
	var ramp := clampf(minf(hour - open, close - hour) / 1.5, 0.2, 1.0)
	var peak := lerpf(0.6, 1.0, clampf(1.0 - absf(hour - 17.0) / 7.0, 0.0, 1.0))
	var days := 1.0 if weekday in [6, 7] else 0.7
	var season := 0.4 + 0.6 * month_factor(month)
	return ramp * peak * days * season * (0.2 if rain else 1.0)


static func deck_count(max_n: int, hour: float, weekday: int, month: int, rain: bool, open: float, close: float, k := 1.0) -> int:
	return roundi(max_n * k * deck_level(hour, weekday, month, rain, open, close))
## The office crowd's level 0..1: working days only, three waves (the morning rush 7-10, lunch
## 11:30-14, the evening rush 16-19, all *guesses*); weekends are empty; rain thins it to 0.7
## (umbrellas, taxis).
static func office_level(hour: float, weekday: int, rain: bool) -> float:
	if weekday > 5:
		return 0.0
	var h := fmod(hour + 24.0, 24.0)
	var v := 0.0
	if h >= 7.0 and h < 10.0:
		v = 1.0 if h >= 8.0 and h < 9.5 else 0.6
	elif h >= 11.5 and h < 14.0:
		v = 0.8 if h >= 12.0 and h < 13.5 else 0.4
	elif h >= 16.0 and h < 19.0:
		v = 1.0 if h >= 16.5 and h < 18.0 else 0.6
	return v * (0.7 if rain else 1.0)


static func office_count(max_n: int, hour: float, weekday: int, rain: bool, k := 1.0) -> int:
	return roundi(max_n * k * office_level(hour, weekday, rain))


## The tag the office lines are drawn with (they also include the untagged ones): "rain" in the
## rain, else `morning` (before 10:30), `lunch` (before 15:00) or `evening`.
static func office_tag(hour: float, rain: bool) -> String:
	if rain:
		return "rain"
	if hour < 10.5:
		return "morning"
	if hour < 15.0:
		return "lunch"
	return "evening"


## Marszałkowska's tram platforms: the commute curve, a weekend (Sat 0.6, Sun 0.4) and rain
## (people wait, so the platforms fill: x1.2, capped at 1).
static func stop_level(hour: float, weekday: int, rain: bool) -> float:
	var w := 1.0 if weekday <= 5 else (0.6 if weekday == 6 else 0.4)
	return minf(curve_at("commute", hour) * w * (1.2 if rain else 1.0), 1.0)


## A polygon's area (m², flat x, z pairs).
static func poly_area(flat: Array) -> float:
	var n := flat.size() / 2
	var a := 0.0
	for i in n:
		var j := (i + 1) % n
		a += float(flat[2 * i]) * float(flat[2 * j + 1]) - float(flat[2 * j]) * float(flat[2 * i + 1])
	return absf(a) * 0.5


## The chill yards' level 0..1 (hour curve; winter keeps a third of the summer, rain 0.15 *guess*).
static func chill_level(hour: float, month: int, rain: bool) -> float:
	return curve_at("chill", hour) * maxf(month_factor(month), 0.35) * (0.15 if rain else 1.0)


## Nowogrodzka's pub crowd level 0..1: the `pub` curve × PUB_WEEKDAY (past midnight counts as the
## evening before, as the clubs do); winter keeps 60 % (they smoke outside in the snow), rain 0.3
## (under the doorways) *guess*.
static func pub_level(hour: float, weekday: int, month: int, rain: bool) -> float:
	return minf(curve_at("pub", hour) * float(PUB_WEEKDAY[night_day(hour, weekday) - 1]) * maxf(month_factor(month), 0.6)
			* (0.3 if rain else 1.0), 1.0)


## Mazowiecka's club crowd level 0..1: the `club` curve × WEEKDAY (past midnight counts as the
## evening before); winter keeps 60 % (the queue stands in the snow), rain 0.3 (under the awnings) *guess*.
static func club_level(hour: float, weekday: int, month: int, rain: bool) -> float:
	return minf(curve_at("club", hour) * float(WEEKDAY[night_day(hour, weekday) - 1]) * maxf(month_factor(month), 0.6)
			* (0.3 if rain else 1.0), 1.0)


## The Palace stages' audience level 0..1: the `theatre` curve x THEATRE_WEEKDAY (no night-day
## shift: the last show ends before midnight); the season runs all year, rain keeps a half under
## the porticoes *guess*.
static func theatre_level(hour: float, weekday: int, rain: bool) -> float:
	return curve_at("theatre", hour) * float(THEATRE_WEEKDAY[clampi(weekday, 1, 7) - 1]) * (0.5 if rain else 1.0)


## First scene item 6: the start's street level 0..1 (FIRST_SCENE): the `street` curve, winter keeps
## 60 % (people still buy papers and coffee), rain a third *guess*.
static func street_level(hour: float, month: int, rain: bool) -> float:
	return curve_at("street", hour) * maxf(month_factor(month), 0.6) * (0.35 if rain else 1.0)


## KROWA 2.0's line now: [people, "kolejka"]. Open 8:00-18:00, 26 at lunch (12-15), 10 otherwise.
static func milk_queue(hour: float, weekday: int) -> Array:
	if hour < 8.0 or hour >= 18.0:
		return [0, ""]
	if hour >= 12.0 and hour < 15.0:
		return [MILK_MAX if weekday < 6 else MILK_MAX * 2 / 3, "kolejka"]
	return [10, "kolejka"]


## ZAKWAS I ROŻEN's line now: [people, "zakwas"]. 12:00-24:00; see ZAKWAS_MAX.
static func zakwas_queue(hour: float, weekday: int) -> Array:
	if hour < 12.0:
		return [0, ""]
	if hour >= 18.0 and hour < 23.0:
		return [ZAKWAS_MAX if weekday == 5 or weekday == 6 else 14, "zakwas"]
	return [8, "zakwas"]


## KRINGULA PIZZA's line now: [people, "kringula"]. 12:00-23:00; see KRINGULA_MAX.
static func kringula_queue(hour: float, weekday: int) -> Array:
	if hour < 12.0 or hour >= 23.0:
		return [0, ""]
	var dinner := hour >= 18.0 and hour < 22.0
	if (dinner and (weekday == 5 or weekday == 6)) or (weekday == 7 and hour >= 14.0 and hour < 20.0):
		return [KRINGULA_MAX, "kringula"]
	return [34 if dinner else KRINGULA_MIN, "kringula"]


## MIESZANE MIESZANE's line now: [people, "mieszane"]. 18:00-04:00; fullest 02:00-04:00 and on
## Friday/Saturday evenings, a handful otherwise.
static func mieszane_queue(hour: float, weekday: int) -> Array:
	if hour >= 4.0 and hour < 18.0:
		return [0, ""]
	if hour < 4.0 and hour >= 2.0:
		return [MIESZANE_MAX, "mieszane"]
	if weekday == 5 or weekday == 6:
		return [MIESZANE_MAX * 2 / 3, "mieszane"]
	return [MIESZANE_MAX / 3, "mieszane"]


## DŻEMINI KEBAB's line now: [people, tag]. Open round the clock; a few before the MLASK
## ("dzemini_new"), the longest line in town after it ("dzemini"), a little shorter 02:00-07:00.
static func dzemini_queue(hour: float, hype: bool) -> Array:
	if not hype:
		return [DZEMINI_NEW, "dzemini_new"]
	if hour >= 2.0 and hour < 7.0:
		return [DZEMINI_NIGHT, "dzemini"]
	return [DZEMINI_MAX, "dzemini"]


## The hyped coffee chains' line now: [people, "kolejka"]. 7:00-18:00, the working-day morning rush
## fullest; half-length otherwise.
static func coffee_queue(hour: float, weekday: int) -> Array:
	if hour < 7.0 or hour >= 18.0:
		return [0, ""]
	if weekday < 6 and hour < 11.0:
		return [COFFEE_MAX, "kolejka"]
	return [COFFEE_MAX / 2, "kolejka"]


## DALEJ DALLA GELATO's line now: [people, tag]. 11:00-21:00; a winter month (Nov-Mar) keeps at
## least GELATO_WINTER_MIN and peaks at 18 on a weekend afternoon (tag "lody_zima"); summer peaks
## at GELATO_MAX in the afternoon (tag "lody").
static func gelato_queue(hour: float, weekday: int, month: int) -> Array:
	if hour < 11.0 or hour >= 21.0:
		return [0, ""]
	var winter := month >= 11 or month <= 3
	var peak := (hour >= 14.0 and hour < 19.0) or weekday >= 6
	if winter:
		return [18 if peak and weekday >= 6 else GELATO_WINTER_MIN, "lody_zima"]
	return [GELATO_MAX if peak else 14, "lody"]


## The dawn crowd is out: 05:00-09:00 on a Saturday or Sunday in Live, or in the Dawn look.
static func dawn_time(hour: float, weekday: int, live: bool, look: String) -> bool:
	if hour < 5.0 or hour >= 9.0:
		return false
	return look == "Dawn" or (live and weekday in [6, 7])


## How many walk at dawn (20-40, the dawn curve).
static func dawn_count(hour: float, k := 1.0) -> int:
	return roundi((DAWN_MIN + (DAWN_MAX - DAWN_MIN) * curve_at("dawn", hour)) * k)


## The police by the clubs: Fri/Sat nights, 00:00-08:00.
static func police_time(hour: float, weekday: int) -> bool:
	return hour < 8.0 and night_day(hour, weekday) in [5, 6]


## Is PISTACJA's limited drop on (Friday, 16:00-18:30)?
static func pistacja_drop(hour: float, weekday: int) -> bool:
	return weekday == PISTACJA_DROP_DAY and hour >= float(PISTACJA_DROP[0]) and hour < float(PISTACJA_DROP[1])


## PISTACJA's line now: [people, the `viral` tag]. Nobody before 10:00 or after 22:00; a short
## "queue" line by day; the drop's full line, tag "drop", with a ramp over its first half hour.
static func pistacja_queue(hour: float, weekday: int) -> Array:
	if hour < float(PISTACJA_HOURS[0]) or hour >= float(PISTACJA_HOURS[1]):
		return [0, ""]
	if pistacja_drop(hour, weekday):
		var ramp := clampf((hour - float(PISTACJA_DROP[0])) / 0.5, 0.0, 1.0)
		return [roundi(lerpf(float(PISTACJA_BASE), float(PISTACJA_MAX), ramp)), "drop"]
	return [PISTACJA_BASE, "queue"]


## PADELNIA's line now: [people, "padel"]. Booked-out evenings (Monday-Friday 17-23), a weekend
## morning wave (Saturday and Sunday 9-13), and three at the desk the rest of the open hours.
static func padel_queue(hour: float, weekday: int) -> Array:
	if hour < 8.0 or hour >= 23.0:
		return [0, ""]
	if weekday <= 5 and hour >= 17.0:
		return [PADEL_MAX, "padel"]
	if weekday >= 6 and hour >= 9.0 and hour < 13.0:
		return [PADEL_MAX * 3 / 4, "padel"]
	return [3, "padel"]


## DŻEMINI KEBAB got Mrożulo's MLASK (trend_job.gd "Dżemini", or the save at start): its line for
## good, rewritten at the next tick.
func dzemini_mlask() -> void:
	dzemini_hype = true
	if by_id.has(DZEMINI_ID):
		sites[by_id[DZEMINI_ID]]["next"] = 0.0


## The "Mrożulo effect" on a trend site (a Wiralek slot or KUKŁA) for today: its queue at its
## longest while it is open, and the fans' lines (trend_job.gd's "Mlask").
func mrozulo_boost(id: String) -> void:
	if by_id.has(id):
		mrozulo[id] = _weekday_now
		var s: Dictionary = sites[by_id[id]]
		s["next"] = 0.0
		if log_on:
			print("night: the Mrożulo effect at %s" % id)


## KUKŁA's line now: [people, "kolejka"]. Warsaw queues: never under 8 while it's open.
static func kukla_queue(hour: float, weekday: int) -> Array:
	if hour < 9.0 or hour >= 21.0:
		return [0, ""]
	if hour < 11.0:
		return [8, "kolejka"]
	if (hour >= 12.0 and hour < 15.0) or (weekday >= 6 and hour >= 13.0 and hour < 18.0):
		return [KUKLA_MAX, "kolejka"]
	return [14, "kolejka"]


## HOTEL PIURE's line for the lift to LORETKA now: [people, "timber"]. Evenings 18:00 to 01:00
## (hours past midnight count from the evening before: 24-25), longer on Friday and Saturday.
static func piure_queue(hour: float, weekday: int) -> Array:
	var late := hour < 1.0
	if not late and hour < 18.0:
		return [0, ""]
	var day := (weekday + 5) % 7 + 1 if late else weekday
	return [PIURE_MAX if day == 5 or day == 6 else 10, "timber"]


## LORETKA's terrace now: how many sit there (an even number: they come in twos), of `seats`.
static func loretka_terrace(hour: float, weekday: int, month: int, rain: bool, seats: int) -> int:
	if rain or month < 5 or month > 9:
		return 0
	var late := hour < 1.0
	if not late and hour < 17.0:
		return 0
	var day := (weekday + 5) % 7 + 1 if late else weekday
	return seats if day == 5 or day == 6 else mini(LORETKA_WEEKNIGHT, seats)


## The car at the door: near and slow, on the ground.
static func car_at_door(dist: float, kmh: float, flying: bool) -> bool:
	return not flying and dist <= CAR_NEAR and kmh < CAR_KMH


## The garage loop: the egg a car painted `paint_id` finds at club `site`'s door ("" none): E01,
## the black car at Lusterko (its night and hours are the egg's own conditions, egg_book.gd).
static func door_egg(site: String, paint_id: String) -> String:
	return "e01" if site == "lusterko" and paint_id == "black" else ""


# --- setup ---------------------------------------------------------------------------------

## The sites at the notebook's resolved places (notebook.gd `places`, each with `at`), the
## footways near them from the map data (`paths`), the dawn crowd's destinations (`pois` kebab,
## `platforms`). Builds no figures: they come with the first tick near each crowd.
func setup(places: Array, data: Dictionary, seed_value := 1703) -> void:
	_rng.seed = seed_value
	var at := {}
	for p: Dictionary in places:
		at[str(p["id"])] = p["at"]
	for id: String in CLUBS:
		if at.has(id):
			var c: Dictionary = CLUBS[id]
			_add_site({"id": id, "kind": "queue", "at": at[id], "max": int(c["max"]), "curve": str(c["curve"]),
					"police": bool(c.get("police", false)), "dawn": bool(c.get("dawn", false))})
	for id: String in TRENDS:
		if at.has(id):
			_add_site({"id": id, "kind": "trend", "at": at[id], "max": int(TRENDS[id]), "tag": ""})
	for vid: String in [PISTACJA_ID, PADEL_ID]:
		var ll: Array = Storefronts.TRENDY[vid]
		_add_site({"id": vid, "kind": "trend", "max": PISTACJA_MAX if vid == PISTACJA_ID else PADEL_MAX, "tag": "",
				"at": Notebook.project(data.get("origin", [52.234, 21.024]), float(ll[0]), float(ll[1]))})
	for vid: String in KUKLA + [PIURE_ID] + MILK + GELATO + KRINGULA + MIESZANE + COFFEE + [DZEMINI_ID]:
		var ll: Array = Storefronts.HYPE[vid]
		var vmax := KUKLA_MAX
		if vid == PIURE_ID:
			vmax = PIURE_MAX
		elif vid in MILK:
			vmax = MILK_MAX
		elif vid in GELATO:
			vmax = GELATO_MAX
		elif vid in KRINGULA:
			vmax = KRINGULA_MAX
		elif vid in MIESZANE:
			vmax = MIESZANE_MAX
		elif vid in COFFEE:
			vmax = COFFEE_MAX
		elif vid == DZEMINI_ID:
			vmax = DZEMINI_MAX
		_add_site({"id": vid, "kind": "trend", "max": vmax, "tag": "",
				"at": Notebook.project(data.get("origin", [52.234, 21.024]), float(ll[0]), float(ll[1]))})
	var zak: Dictionary = Zaglebie.shop(ZAKWAS_TAG)
	if not zak.is_empty():
		var zl: Array = zak["ll"]
		_add_site({"id": ZAKWAS_ID, "kind": "trend", "max": ZAKWAS_MAX, "tag": "",
				"at": Notebook.project(data.get("origin", [52.234, 21.024]), float(zl[0]), float(zl[1]))})
	var lor := Landmarks.loretka_plan(data)
	if not lor.is_empty():
		var lo: PackedVector2Array = lor["outline"]
		var mid := Vector2.ZERO
		for q in lo:
			mid += q
		_add_site({"id": LORETKA_ID, "kind": "terrace", "at": mid / float(lo.size()), "max": (lor["seats"] as Array).size(),
				"plan": lor})
	var jazz := Landmarks.powisle_jazz_plan()
	_add_site({"id": JAZZ_ID, "kind": "jazz", "at": jazz["centre"], "max": JAZZ_BAND + (jazz["chairs"] as Array).size()
			+ (jazz["standing"] as Array).size(), "plan": jazz})
	_add_site({"id": JAZZ_CAFE_ID, "kind": "jazz_cafe", "at": Landmarks.POW_LOW_C, "max": (jazz["seats"] as Array).size(), "plan": jazz})
	if at.has(ROOF_ID):
		_add_site({"id": ROOF_ID, "kind": "roof", "at": at[ROOF_ID], "max": ROOF_MAX, "curve": "roof"})
		_add_site({"id": ROOF_DOOR_ID, "kind": "queue", "at": at[ROOF_ID], "max": ROOF_DOOR_MAX, "curve": "roof",
				"police": false, "dawn": false})
	for id: String in DECKS:
		var d: Dictionary = DECKS[id]
		var site := {"id": id, "kind": "deck", "at": d["at"], "max": int(d["max"]), "open": float(d["open"]), "close": float(d["close"])}
		for key: String in ["in", "top", "half", "axis", "up", "gap"]:
			if d.has(key):
				site[key] = d[key]
		_add_site(site)
	if at.has(STEPS_ID):
		_add_site({"id": STEPS_ID, "kind": "steps", "at": at[STEPS_ID], "max": STEPS_MAX})
	var yards := CHILL.duplicate()
	yards.merge(BULWARY)
	yards.merge(NOWY_SWIAT)
	for cid: String in yards:
		var cs: Array = yards[cid]
		_add_site({"id": cid, "kind": "chill", "at": cs[0], "max": int(cs[1]), "radius": float(cs[2])})
	for pid: String in NOWOGRODZKA:
		var ps: Array = NOWOGRODZKA[pid]
		_add_site({"id": pid, "kind": "chill", "pub": true, "sit": false, "at": ps[0], "max": int(ps[1]), "radius": float(ps[2])})
	for wid: String in WILCZA:
		var ws: Array = WILCZA[wid]
		_add_site({"id": wid, "kind": "chill", "pub": true, "sit": false, "at": ws[0], "max": int(ws[1]), "radius": float(ws[2])})
	for gid: String in PRAGA:
		var gs: Array = PRAGA[gid]
		_add_site({"id": gid, "kind": "chill", "pub": true, "sit": false, "at": gs[0], "max": int(gs[1]), "radius": float(gs[2])})
	for vid: String in VIADUKT:
		var vs: Array = VIADUKT[vid]
		_add_site({"id": vid, "kind": "chill", "pub": true, "sit": false, "at": vs[0], "max": int(vs[1]), "radius": float(vs[2])})
	for kid: String in MAZOWIECKA:
		var ks: Array = MAZOWIECKA[kid]
		_add_site({"id": kid, "kind": "chill", "club": true, "sit": false, "at": ks[0], "max": int(ks[1]), "radius": float(ks[2])})
	for sid: String in SOWA:
		var ss: Array = SOWA[sid]
		_add_site({"id": sid, "kind": "chill", "club": true, "sit": false, "at": ss[0], "max": int(ss[1]), "radius": float(ss[2]),
				"talk": "sowa_club"})
	var studio := Landmarks.pkin_studio_plan()
	_add_site({"id": STUDIO_ID, "kind": "jazz_cafe", "at": studio["centre"], "max": (studio["seats"] as Array).size(), "plan": studio})
	var doors := Landmarks.pkin_theatre_doors()
	for tid: String in THEATRES:
		_add_site({"id": tid, "kind": "chill", "theatre": true, "sit": false, "at": doors[tid], "max": int(THEATRES[tid]), "radius": 10.0})
	for fid: String in FIRST_SCENE:
		var fs: Array = FIRST_SCENE[fid]
		_add_site({"id": fid, "kind": "chill", "street": true, "sit": bool(fs[4]), "at": first_scene_at(float(fs[0]), float(fs[1])),
				"max": int(fs[2]), "radius": float(fs[3])})
	if meet_on:
		var slots: Array = []
		var mrng := RandomNumberGenerator.new()
		mrng.seed = 2030
		for sl: Dictionary in LoudCars.meet_slots():
			var shirt: String = DARK[mrng.randi() % DARK.size()] if mrng.randf() < 0.5 else BRIGHT[mrng.randi() % BRIGHT.size()]
			slots.append({"p": sl["p"], "yaw": float(sl["yaw"]) + mrng.randf_range(-0.3, 0.3), "pose": STAND, "shirt": shirt})
		_add_site({"id": MEET_ID, "kind": "meet", "at": LoudCars.meet_centre(), "max": mini(MEET_MAX, slots.size()), "slots": slots})
	_add_stops(data)
	for oid: String in OFFICE:
		var os: Array = OFFICE[oid]
		_add_site({"id": oid, "kind": "office", "at": os[0], "max": int(os[1]), "radius": float(os[2])})
	_setup_office(data)
	if at.has(PLAN_C_ID):
		_add_site({"id": PLAN_C_ID, "kind": "plan_c", "at": at[PLAN_C_ID], "max": PLAN_C_MAX})
	# The dawn crowd's ends: the palm, the metro, kebab stands and tram platforms near the clubs.
	var from: Array = []
	for s in sites:
		if bool(s.get("dawn", false)):
			from.append(s)
	var ends: Array = []
	# The Palm (the map's own point, as eggs.gd's), then the metro.
	var palm: Array = data.get("palm", [])
	if palm.size() >= 2:
		ends.append(["palma", Vector2(float(palm[0]), float(palm[1]))])
	elif at.has("palma"):
		ends.append(["palma", at["palma"]])
	if at.has("nowy_swiat_uniwersytet"):
		ends.append(["nowy_swiat_uniwersytet", at["nowy_swiat_uniwersytet"]])
	var mid := Vector2.ZERO
	for s in from:
		mid += s["at"]
	if not from.is_empty():
		mid /= float(from.size())
		var kebabs: Array = []
		for poi: Dictionary in data.get("pois", []):
			if str(poi.get("k", "")) == "kebab":
				var q := Vector2(float(poi["x"]), float(poi["z"]))
				kebabs.append([q.distance_to(mid), q])
		kebabs.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		for k in mini(2, kebabs.size()):
			ends.append(["kebab_%d" % k, kebabs[k][1]])
		var plats: Array = []
		for pl: Dictionary in data.get("platforms", []):
			var flat: Array = pl.get("p", [])
			if flat.size() < 4:
				continue
			var c := Vector2.ZERO
			for i in range(0, flat.size() - 1, 2):
				c += Vector2(float(flat[i]), float(flat[i + 1]))
			c /= float(flat.size() / 2)
			plats.append([c.distance_to(mid), c])
		plats.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		for k in mini(2, plats.size()):
			if float(plats[k][0]) < 900.0:
				ends.append(["tram_%d" % k, plats[k][1]])
	_route_in = {"from": from.map(func(s: Dictionary) -> Array: return [s["id"], s["at"]]), "to": ends}
	_scan_paths(data, from, ends)
	for s in sites:
		_place_site(s)
	_build_drawing()
	var kinds := {}
	for s in sites:
		kinds[s["kind"]] = int(kinds.get(s["kind"], 0)) + 1
	print("crowds: %d sites %s, %d footways near them, the dawn crowd %d clubs → %d ends, amount %.2f" % [
			sites.size(), kinds, _foot.size(), from.size(), ends.size(), amount])


## The office walkers' routes' ends: every subway exit round the rondo (the `from` list) to the
## other exits and the towers' foyers, and the box they walk in (the view wakes them near it).
func _setup_office(data: Dictionary) -> void:
	var exits: Array = []
	for poi: Dictionary in data.get("pois", []):
		if str(poi.get("k", "")) == "subway_entrance":
			var q := Vector2(float(poi["x"]), float(poi["z"]))
			if q.distance_to(OFFICE_AT) <= OFFICE_REACH:
				exits.append(["office_exit_%d" % exits.size(), q])
	if exits.is_empty():
		return
	var to: Array = exits.duplicate()
	to.append_array(OFFICE_ENDS)
	# Both kerbs of every zebra crossing round the rondo: a route from an exit to the far kerb
	# has to cross the road, so the walkers use the crossings.
	var zi := 0
	_office_zebras.clear()
	for p: Dictionary in data.get("paths", []):
		if str(p.get("k", "")) != "zebra":
			continue
		var flat: Array = p["p"]
		var a := Vector2(float(flat[0]), float(flat[1]))
		var b := Vector2(float(flat[flat.size() - 2]), float(flat[flat.size() - 1]))
		if a.distance_to(OFFICE_AT) <= OFFICE_REACH + 40.0:
			var line := PackedVector2Array()
			for i in range(0, flat.size() - 1, 2):
				line.append(Vector2(float(flat[i]), float(flat[i + 1])))
			_office_zebras.append(line)
			to.append(["office_zebra_%d_a" % zi, a])
			to.append(["office_zebra_%d_b" % zi, b])
			zi += 1
	_office_in = {"from": exits, "to": to}
	var box := Rect2(OFFICE_AT, Vector2.ZERO)
	for e: Array in to:
		box = box.expand(e[1])
	_office_box = box.grow(80.0)


## First scene item 6: a point in first_scene.gd's Marszałkowska frame (`s` m north, `t` m east).
static func first_scene_at(s: float, t: float) -> Vector2:
	return FirstScene.FRAME_O + FirstScene.FRAME_S * s + FirstScene.FRAME_T * t


## Every tram platform (poly, centre, most people, its top): one `stop` site each.
func _add_stops(data: Dictionary) -> void:
	var segs: Array = []
	for r: Dictionary in data.get("roads", []):
		if str(r.get("name", "")) != STOP_STREET:
			continue
		var p: Array = r["p"]
		for i in range(0, p.size() - 3, 2):
			segs.append([Vector2(float(p[i]), float(p[i + 1])), Vector2(float(p[i + 2]), float(p[i + 3]))])
	var idx := 0
	var other := 0
	for pl: Dictionary in data.get("platforms", []):
		var flat: Array = pl.get("p", [])
		if flat.size() < 6:
			continue
		var c := Vector2.ZERO
		var poly := PackedVector2Array()
		for i in range(0, flat.size() - 1, 2):
			var v := Vector2(float(flat[i]), float(flat[i + 1]))
			poly.append(v)
			c += v
		c /= float(poly.size())
		var near := false
		for sg: Array in segs:
			var cp := Geometry2D.get_closest_point_to_segment(c, sg[0], sg[1])
			if cp.distance_to(c) <= STOP_REACH:
				near = true
				break
		var cap := clampi(roundi(poly_area(flat) / STOP_AREA), 0, STOP_MAX)
		var centralny := not near and c.distance_to(STOP_CENTRALNY) <= STOP_CENTRALNY_REACH
		if centralny:
			cap = clampi(roundi(poly_area(flat) / STOP_AREA), 3, STOP_CENTRALNY_MAX)
		if cap < 3:
			continue
		# The platform's walking top (map_builder's slab: the outline's lowest ground + h + 0.1).
		var top := INF
		if map != null:
			for v in poly:
				top = minf(top, map.terrain_height(v.x, v.y))
			top += float(pl.get("h", 0.25)) + 0.1
		var id := "stop_%d" % other
		if near:
			id = "stop_marsz_%d" % idx
		elif centralny:
			id = "stop_centralny_%d" % idx
		var site := {"id": id, "kind": "stop", "at": c, "poly": poly, "max": cap}
		if centralny:
			site["floor"] = STOP_CENTRALNY_FLOOR
		if top != INF:
			site["top"] = top
		_add_site(site)
		if near or centralny:
			idx += 1
		else:
			other += 1


func _add_site(s: Dictionary) -> void:
	s["n"] = 0
	s["want"] = 0
	s["next"] = 0.0
	s["door_t"] = _rng.randf_range(DOOR_GAP.x, DOOR_GAP.y)
	s["chat_t"] = _rng.randf_range(CHAT_GAP.x, CHAT_GAP.y)
	s["active"] = false
	s["dirty"] = false
	s["car_night"] = -1
	s["police_t"] = 0.0
	s["sober_night"] = -1
	s["officer"] = Vector3.INF
	s["inst"] = []
	s["cell"] = Vector2i(floori(float(s["at"].x) / CELL), floori(float(s["at"].y) / CELL))
	by_id[str(s["id"])] = sites.size()
	sites.append(s)


## The footways and crossings near the sites (their 128 m cells and the next ones) and over the
## dawn crowd's box: a path is kept when its first, middle or last point is in one of them.
func _scan_paths(data: Dictionary, from: Array, ends: Array) -> void:
	var cells := {}
	var mark := func(p: Vector2, r: int) -> void:
		var c := Vector2i(floori(p.x / 128.0), floori(p.y / 128.0))
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				cells[c + Vector2i(dx, dz)] = true
	for s in sites:
		mark.call(s["at"], 1)
	if not from.is_empty() and not ends.is_empty():
		var box := Rect2(from[0]["at"], Vector2.ZERO)
		for s: Dictionary in from:
			box = box.expand(s["at"])
		for e: Array in ends:
			box = box.expand(e[1])
		box = box.grow(150.0)
		_walk_box = box
		for x in range(floori(box.position.x / 128.0), floori(box.end.x / 128.0) + 1):
			for z in range(floori(box.position.y / 128.0), floori(box.end.y / 128.0) + 1):
				cells[Vector2i(x, z)] = true
	if _office_box.size != Vector2.ZERO:
		var ob := _office_box.grow(60.0)
		for x in range(floori(ob.position.x / 128.0), floori(ob.end.x / 128.0) + 1):
			for z in range(floori(ob.position.y / 128.0), floori(ob.end.y / 128.0) + 1):
				cells[Vector2i(x, z)] = true
	for p: Dictionary in data.get("paths", []):
		var k := str(p.get("k", ""))
		if k != "foot" and k != "zebra":
			continue
		var flat: Array = p["p"]
		var n := flat.size() / 2
		if n < 2:
			continue
		var hit := false
		for i in [0, n / 2, n - 1]:
			if cells.has(Vector2i(floori(float(flat[i * 2]) / 128.0), floori(float(flat[i * 2 + 1]) / 128.0))):
				hit = true
				break
		if not hit:
			continue
		var pts := PackedVector2Array()
		for i in n:
			pts.append(Vector2(float(flat[i * 2]), float(flat[i * 2 + 1])))
		_foot.append({"pts": pts, "dk": int(p.get("dk", -1)), "w": float(p.get("w", 2.0)), "k": k})


## The footway point nearest `p` within `reach`: [path index, segment, the point], or [].
func nearest_foot(p: Vector2, reach: float) -> Array:
	var best: Array = []
	var best_d := reach
	for i in _foot.size():
		var f: Dictionary = _foot[i]
		if f["k"] != "foot" or int(f["dk"]) >= 0:
			continue
		var pts: PackedVector2Array = f["pts"]
		for j in pts.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(p, pts[j], pts[j + 1])
			var d := q.distance_to(p)
			if d < best_d:
				best_d = d
				best = [i, j, q]
	return best


## Where a site's figures go: a queue's line on its footway, the steps' rows, the square's groups,
## the roof's ring.
func _place_site(s: Dictionary) -> void:
	var at: Vector2 = s["at"]
	match str(s["kind"]):
		"queue", "trend":
			var hit := nearest_foot(at, FOOT_REACH)
			var line := PackedVector2Array()
			var out := Vector2.RIGHT
			var door := at
			if hit.is_empty():
				# No footway near: the line runs east from the place.
				for k in 40:
					line.append(at + Vector2(k * 1.0, 0.0))
				out = Vector2.DOWN
			else:
				var f: Dictionary = _foot[hit[0]]
				var pts: PackedVector2Array = f["pts"]
				var j: int = hit[1]
				var q: Vector2 = hit[2]
				var along := (pts[j + 1] - pts[j]).normalized()
				out = Vector2(-along.y, along.x)
				if (q - at).dot(out) < 0.0:
					out = -out  # from the facade to the street
				# Facade side of the footway, then along it the longer way.
				var w := float(f["w"])
				door = q - out * maxf(w * 0.5 - 0.45, 0.0)
				var fwd := _walk(pts, j, q, 1)
				var back := _walk(pts, j, q, -1)
				var run := fwd if _run_len(fwd) >= _run_len(back) else back
				for v in run:
					line.append(v - out * maxf(w * 0.5 - 0.45, 0.0))
			s["door"] = door
			s["out"] = out
			s["line"] = _resample(line, QUEUE_GAP, int(s["max"]) * 2 + 2)
		"steps":
			_place_steps(s)
		"plan_c", "chill", "office":
			_place_square(s)
		"stop":
			_place_stop(s)
		"roof":
			_place_roof(s)
		"terrace":
			_place_terrace(s)
		"jazz", "jazz_cafe":
			_place_jazz(s)
		"deck":
			_place_deck(s)
		"meet":
			s["door"] = s["at"]


## The points of a polyline from q (on segment j) one way along it, then straight on past its end.
static func _walk(pts: PackedVector2Array, j: int, q: Vector2, way: int) -> PackedVector2Array:
	var out := PackedVector2Array([q])
	var k := j + 1 if way > 0 else j
	while k >= 0 and k < pts.size():
		out.append(pts[k])
		k += way
	var last := out[out.size() - 1]
	var dir := (last - out[out.size() - 2]).normalized() if out.size() > 1 else Vector2.RIGHT
	out.append(last + dir * 40.0)
	return out


static func _run_len(pts: PackedVector2Array) -> float:
	var l := 0.0
	for i in pts.size() - 1:
		l += pts[i].distance_to(pts[i + 1])
	return l - 40.0


## `count` points every `gap` m along a polyline.
static func _resample(pts: PackedVector2Array, gap: float, count: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	if pts.size() < 2:
		return out
	var k := 0
	var into := 0.0
	for n in count:
		var want := n * gap
		while k < pts.size() - 2 and into + pts[k].distance_to(pts[k + 1]) < want:
			into += pts[k].distance_to(pts[k + 1])
			k += 1
		var seg := pts[k].distance_to(pts[k + 1])
		out.append(pts[k].lerp(pts[k + 1], clampf((want - into) / maxf(seg, 0.001), 0.0, 1.5)))
	return out


## The steps: the river's direction (the nearest wet ground in 24 directions), rows from the
## water's edge back, groups of 2-6 along them; each slot a seeded order so a bigger crowd only
## adds people. Row 0 stands (by the rail), the rest sit; one guitarist.
func _place_steps(s: Dictionary) -> void:
	var at: Vector2 = s["at"]
	var face := Vector2.RIGHT
	var reach := 120.0
	if map != null:
		var best := INF
		for a in 24:
			var dir := Vector2.from_angle(a * TAU / 24.0)
			var r := 4.0
			while r < 300.0:
				if map.shore_distance(at.x + dir.x * r, at.y + dir.y * r) > 0.5:
					if r < best:
						best = r
						face = dir
					break
				r += 4.0
		reach = best if best < INF else 30.0
	var side := Vector2(-face.y, face.x)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3303
	var slots: Array = []
	for row in 8:
		var back := maxf(reach - 3.0 - row * 1.3, -20.0)
		var x := -28.0
		while x < 28.0:
			var g := rng.randi_range(2, 6)
			for i in g:
				var p := at + face * back + side * (x + i * 0.75) + Vector2(rng.randf_range(-0.15, 0.15), rng.randf_range(-0.15, 0.15))
				if map == null or map.shore_distance(p.x, p.y) <= 0.0:
					slots.append({"p": p, "pose": STAND if row == 0 else SIT, "yaw": atan2(-face.x, -face.y) + rng.randf_range(-0.35, 0.35),
							"key": rng.randf(), "shirt": BRIGHT[rng.randi() % BRIGHT.size()]})
			x += g * 0.75 + rng.randf_range(1.0, 2.6)
	slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["key"] < b["key"])
	s["slots"] = slots
	s["face"] = face
	# The guitarist: the middle of the third row, sitting, in orange.
	var g_at := at + face * maxf(reach - 3.0 - 2.0 * 1.3, -20.0)
	s["guitar"] = g_at
	s["door"] = at + face * maxf(reach - 6.0, 0.0)


## Plac Zbawiciela: groups of 2-5 standing round points on the footways within 30 m, facing their
## group's middle.
func _place_square(s: Dictionary) -> void:
	var at: Vector2 = s["at"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2203
	var spots: Array = []
	var radius := float(s.get("radius", 36.0))
	var cap := int(s.get("max", PLAN_C_MAX))
	var office := str(s["kind"]) == "office"
	# First scene item 6: the street's standers at the kiosk and on the paving don't sit.
	var chill := str(s["kind"]) == "chill" and bool(s.get("sit", true))
	for f in _foot:
		if f["k"] != "foot":
			continue
		var pts: PackedVector2Array = f["pts"]
		for j in pts.size() - 1:
			var l := pts[j].distance_to(pts[j + 1])
			var u := 0.0
			while u < l:
				var p := pts[j].lerp(pts[j + 1], u / maxf(l, 0.001))
				if p.distance_to(at) < radius:
					spots.append([rng.randf(), p])
				u += 2.5
	spots.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var slots: Array = []
	for sp: Array in spots:
		if slots.size() >= cap * 2:
			break
		var mid: Vector2 = sp[1]
		var g := rng.randi_range(2, 5)
		for i in g:
			var a := TAU * i / g + rng.randf_range(-0.3, 0.3)
			var p := mid + Vector2.from_angle(a) * 0.55
			# Chilling: a third of a group sits (on a step, a kerb, the ground), the rest lean and talk.
			var pose := SIT if chill and rng.randf() < 0.35 else STAND
			var shirt: String = OFFICE_SHIRTS[rng.randi() % OFFICE_SHIRTS.size()] if office else BRIGHT[rng.randi() % BRIGHT.size()]
			slots.append({"p": p, "pose": pose, "yaw": atan2(-(mid - p).x, -(mid - p).y), "shirt": shirt})
	if slots.is_empty():
		for i in cap:
			var p := at + Vector2.from_angle(i * 2.4) * (2.0 + i * 0.3)
			slots.append({"p": p, "pose": SIT if chill and i % 3 == 0 else STAND, "yaw": i * 1.3,
					"shirt": OFFICE_SHIRTS[i % OFFICE_SHIRTS.size()] if office else BRIGHT[i % BRIGHT.size()]})
	if office and slots.size() < cap:
		# Few footway points in reach (a median, a kerb): the rest stand in a ring on the spot.
		for i in cap - slots.size():
			var p := at + Vector2.from_angle(i * 2.4) * (1.5 + i * 0.35)
			slots.append({"p": p, "pose": STAND, "yaw": i * 1.3, "shirt": OFFICE_SHIRTS[i % OFFICE_SHIRTS.size()]})
	s["slots"] = slots
	s["door"] = at


## A tram platform: groups of 1-3 waiting people at seeded points inside the polygon (0.8 m from
## its edge is not checked: the polygons are the mapped islands, narrower than they look), all
## facing the platform's long axis' nearer side, as people watch for the tram.
func _place_stop(s: Dictionary) -> void:
	var poly: PackedVector2Array = s["poly"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(s["id"]))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for v in poly:
		lo = lo.min(v)
		hi = hi.max(v)
	var slots: Array = []
	var cap := int(s["max"])
	var tries := 0
	while slots.size() < cap and tries < 600:
		tries += 1
		var mid := Vector2(rng.randf_range(lo.x, hi.x), rng.randf_range(lo.y, hi.y))
		if not Geometry2D.is_point_in_polygon(mid, poly):
			continue
		var g := rng.randi_range(1, 3)
		var yaw := rng.randf() * TAU
		for i in g:
			var p := mid + Vector2.from_angle(TAU * i / g + yaw) * 0.5
			if slots.size() < cap * 2 and Geometry2D.is_point_in_polygon(p, poly):
				var slot := {"p": p, "yaw": yaw + rng.randf_range(-0.6, 0.6), "shirt": BRIGHT[rng.randi() % BRIGHT.size()]}
				if s.has("top"):
					slot["y"] = float(s["top"])
				slots.append(slot)
		if slots.size() >= cap * 2:
			break
	s["slots"] = slots
	s["door"] = s["at"]


## F's asks (2026-10-30): the tower's outline round `at` from the roof grid (`roof`: (x, z) ->
## the grid's height; the city's grid on both paths, LoD2's or OpenStreetMap's, whichever is
## drawn): `rays` rays out in 0.5 m steps to where the grid drops under the top floors (`top`
## − 6 m), as [the first point past the edge, the direction, the roof's height at the edge] each
## (rays that find nothing are left out). A grid cell is marked when anything of the building
## touches it, so the point is on the facade or up to a cell (4 m) outside it, never inside.
static func roof_ring(at: Vector2, top: float, roof: Callable, rays: int) -> Array:
	var out: Array = []
	for a in rays:
		var dir := Vector2.from_angle(a * TAU / rays)
		var last := -1.0
		var h := top
		var r := 0.0
		while r < 60.0:
			var y: float = roof.call(at.x + dir.x * r, at.y + dir.y * r)
			if y >= top - 6.0:
				last = r
				h = y
			elif r - last > 6.0:
				break
			r += 0.5
		if last >= 0.0:
			out.append([at + dir * (last + 0.5), dir, h])
	return out


## LORETKA's terrace: a seat each from the plan, on the deck (the hotel's height over its lowest
## ground, as landmarks.gd builds it, + the deck's 0.12 m), table by table, in bright clothes.
func _place_terrace(s: Dictionary) -> void:
	var plan: Dictionary = s["plan"]
	s["door"] = s["at"]
	var g := INF
	for q: Vector2 in plan["outline"]:
		g = minf(g, map.terrain_height(q.x, q.y) if map != null else 0.0)
	var y := g + float(plan["h"]) + 0.12
	var slots: Array = []
	var k := 0
	for st: Array in plan["seats"]:
		slots.append({"p": st[0], "y": y, "pose": SIT, "yaw": float(st[1]), "shirt": BRIGHT[(k * 3 + 1) % BRIGHT.size()]})
		k += 1
	s["slots"] = slots


## The jazz evenings (landmarks.gd powisle_jazz_plan): the band first (on the stage, the pianist
## and the drummer sitting), then the deck chairs' sitters and the standing audience mixed in a
## seeded order (so a thin evening is spread out, not only the front row); the café's sitters at
## its tables. Bright clothes, the band in its own.
func _place_jazz(s: Dictionary) -> void:
	var plan: Dictionary = s["plan"]
	s["door"] = s["at"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1955
	var slots: Array = []
	if s["kind"] == "jazz_cafe":
		var k := 0
		for st: Array in plan["seats"]:
			slots.append({"p": st[0], "pose": SIT, "yaw": float(st[1]), "shirt": BRIGHT[(k * 7 + 3) % BRIGHT.size()]})
			k += 1
		var order := range(slots.size())
		_shuffle(order, rng)
		var mixed: Array = []
		for i: int in order:
			mixed.append(slots[i])
		s["slots"] = mixed
		return
	var top := Landmarks.powisle_floor(map) + Landmarks.POW_STAGE_H
	var i := 0
	for b: Array in plan["band"]:
		slots.append({"p": b[0], "y": top, "pose": SIT if int(b[2]) == 1 else STAND, "yaw": float(b[1]), "shirt": JAZZ_SHIRTS[i % JAZZ_SHIRTS.size()]})
		i += 1
	var rest: Array = []
	for ch: Array in plan["chairs"]:
		var to: Vector2 = ch[1]
		rest.append({"p": (ch[0] as Vector2) - to * 0.1, "pose": SIT, "yaw": atan2(-to.x, -to.y), "shirt": BRIGHT[rng.randi() % BRIGHT.size()]})
	for st: Array in plan["standing"]:
		rest.append({"p": st[0], "pose": STAND, "yaw": float(st[1]), "shirt": BRIGHT[rng.randi() % BRIGHT.size()] if rng.randf() < 0.6 else DARK[rng.randi() % DARK.size()]})
	var order := range(rest.size())
	_shuffle(order, rng)
	for j: int in order:
		slots.append(rest[j])
	s["slots"] = slots


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t


## Level 26: the tower's outline (`roof_ring`), the figures RING_IN m inside it (on the roof
## whatever the grid's cell did), every second ray, in a seeded order. Without a tall roof there
## (under 40 m): no crowd.
func _place_roof(s: Dictionary) -> void:
	var at: Vector2 = s["at"]
	s["slots"] = []
	s["door"] = at
	if map == null:
		return
	var top: float = map.roof_height(at.x, at.y)
	var ground: float = map.ground_height(at.x, at.y)
	if top - ground < 40.0:
		print("crowds: no tall roof at %s (%.0f m over the ground): no roof crowd" % [s["id"], top - ground])
		return
	var ring := roof_ring(at, top, func(x: float, z: float) -> float: return map.roof_height(x, z), RING_RAYS)
	var slots: Array = []
	for k in range(0, ring.size(), 2):
		var r: Array = ring[k]
		var dir: Vector2 = r[1]
		var p: Vector2 = r[0] - dir * RING_IN
		if p.distance_to(at) < 1.0:
			p = at + dir
		var y: float = map.roof_height(p.x, p.y)
		slots.append({"p": p, "pose": STAND, "yaw": atan2(-dir.x, -dir.y), "shirt": DARK[(k / 2) % DARK.size()],
				"y": y if y >= top - 6.0 else float(r[2])})
	# A seeded order, so a small crowd is spread round the roof, not bunched on one side.
	var rng := RandomNumberGenerator.new()
	rng.seed = 2626
	for k in range(slots.size() - 1, 0, -1):
		var m := rng.randi_range(0, k)
		var tmp: Dictionary = slots[k]
		slots[k] = slots[m]
		slots[m] = tmp
	s["slots"] = slots
	s["top"] = top
	if ring.size() >= RING_RAYS / 2:
		_build_ring(ring, at)
	print("crowds: %s on a roof %.0f m over the ground, %d spots at the parapet, %s" % [s["id"], top - ground, slots.size(),
			"the band of light round %d m of facade" % roundi(_ring_len(ring)) if _ring != null else "no band (%d rays)" % ring.size()])


## An observation deck's spots (F's asks, 2026-11-01), every second one in a seeded order, each
## `slot` facing out over the view. A square terrace (`half`): along its four sides `gap` m
## apart, `up` m over the terrain. A tower's roof (`in`): the roof ring as `_place_roof`'s, the
## figures `in` m inside the parapet, on the roof grid's height. No map or no tall roof: none.
func _place_deck(s: Dictionary) -> void:
	var at: Vector2 = s["at"]
	s["slots"] = []
	s["door"] = at
	if map == null:
		return
	var slots: Array = []
	if s.has("half"):
		var axis: Vector2 = (s["axis"] as Vector2).normalized()
		var half := float(s["half"])
		var y: float = map.terrain_height(at.x, at.y) + float(s["up"])
		var per_side := maxi(int(floor(2.0 * half / float(s["gap"]))), 1)
		var k := 0
		for side in 4:
			var out := axis.rotated(side * PI * 0.5)
			var along := Vector2(-out.y, out.x)
			for i in per_side:
				var t := (i + 0.5) / per_side * 2.0 - 1.0
				var p := at + out * half + along * (t * (half - 0.5))
				slots.append({"p": p, "pose": STAND, "yaw": atan2(-out.x, -out.y), "shirt": BRIGHT[k % BRIGHT.size()], "y": y})
				k += 1
	else:
		var ground: float = map.ground_height(at.x, at.y)
		var top := ground + float(s["top"])
		var seen: float = map.roof_height(at.x, at.y)
		if seen < top - 6.0:
			print("crowds: no roof at %s (%.0f m over the ground, the deck is %.0f): no deck crowd" % [s["id"], seen - ground, float(s["top"])])
			return
		# A mast over the deck (Varso's spire) is flattened to the deck's height, so the ring
		# stays on the crown and a figure never stands on the mast.
		var roof := func(x: float, z: float) -> float: return minf(map.roof_height(x, z), top + 2.0)
		var ring := roof_ring(at, top, roof, RING_RAYS)
		for k in range(0, ring.size(), 2):
			var r: Array = ring[k]
			var dir: Vector2 = r[1]
			var p: Vector2 = r[0] - dir * float(s["in"])
			var y: float = minf(map.roof_height(p.x, p.y), top)
			slots.append({"p": p, "pose": STAND, "yaw": atan2(-dir.x, -dir.y), "shirt": BRIGHT[(k / 2 + 3) % BRIGHT.size()],
					"y": y if y >= top - 6.0 else top})
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(s["id"]))
	for k in range(slots.size() - 1, 0, -1):
		var m := rng.randi_range(0, k)
		var tmp: Dictionary = slots[k]
		slots[k] = slots[m]
		slots[m] = tmp
	s["slots"] = slots
	print("crowds: %s, %d spots on the deck" % [s["id"], slots.size()])


## F's asks: the violet band round the top floor, one quad per pair of rays, RING_OUT m off the
## smoothed outline, RING_TOP m under the body's roof; Models.material()'s LIT_SIGN (it glows only while
## the city's lights are on). Hidden until the club opens near the view (`tick`).
func _build_ring(ring: Array, at: Vector2) -> void:
	# One height all round (the lowest of the top floors' roofs: the tower's body, not a crown
	# on it), and the outline smoothed over five rays (the grid's 4 m steps), half a metre out.
	var lowest := INF
	for r: Array in ring:
		lowest = minf(lowest, float(r[2]))
	var y1 := lowest - RING_TOP
	var y0 := y1 - RING_H
	var pts: Array[Vector2] = []
	var n_r := ring.size()
	for k in n_r:
		var d := 0.0
		for o in range(-2, 3):
			d += ((ring[(k + o + n_r) % n_r][0] as Vector2) - at).length()
		pts.append(at + (ring[k][1] as Vector2) * (d / 5.0 + 0.5 + RING_OUT))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in n_r:
		var r0: Array = ring[k]
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[(k + 1) % n_r]
		if a.distance_to(b) > 30.0:
			continue
		var n2 := Vector2((b - a).y, -(b - a).x).normalized()
		if n2.dot(r0[1] as Vector2) < 0.0:
			n2 = -n2
		var n := Vector3(n2.x, 0.0, n2.y)
		var q := [Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y)]
		if (q[1] - q[0]).cross(q[2] - q[0]).dot(n) > 0.0:
			q = [q[0], q[3], q[2], q[1]]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_color(RING_COLOUR)
			st.set_normal(n)
			st.set_uv(Vector2(Models.LIT_SIGN, 0.0))
			st.add_vertex(q[i])
	_ring = MeshInstance3D.new()
	_ring.name = "Level26Ring"
	_ring.mesh = st.commit()
	_ring.material_override = Models.material()
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_ring.visible = false
	add_child(_ring)


static func _ring_len(ring: Array) -> float:
	var l := 0.0
	for k in ring.size():
		l += (ring[k][0] as Vector2).distance_to(ring[(k + 1) % ring.size()][0] as Vector2)
	return l


## F's asks: whether the band is shown now (for check_crowds and the log).
func ring_on() -> bool:
	return _ring != null and _ring.visible


# --- drawing -------------------------------------------------------------------------------

func _build_drawing() -> void:
	_mesh = Models.person_mesh()
	_still_mat = Models.material().duplicate() as ShaderMaterial
	_still_mat.set_shader_parameter("walk", 0.0)
	_walk_mat = Models.material().duplicate() as ShaderMaterial
	_walk_mat.set_shader_parameter("walk", 0.16)
	var cap := {}
	for s in sites:
		var c: Vector2i = s["cell"]
		cap[c] = int(cap.get(c, 0)) + ceili(int(s["max"]) * maxf(amount, 1.0)) + 3
	for c: Vector2i in cap:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		InstanceBuffers.prepare(mm)
		mm.mesh = _mesh
		mm.instance_count = int(cap[c])
		mm.visible_instance_count = 0
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Crowd_%d_%d" % [c.x, c.y]
		mmi.multimesh = mm
		mmi.material_override = _still_mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		mmi.visible = false
		add_child(mmi)
		var buf := PackedFloat32Array()
		buf.resize(int(cap[c]) * 16)
		buf.fill(0.0)
		_cells[c] = {"mmi": mmi, "mm": mm, "buf": buf, "cap": int(cap[c]), "dirty": false}
	var wcap := ceili(maxi(DAWN_MAX, OFFICE_MAX) * maxf(amount, 1.0)) + 4
	_walk_mm = MultiMesh.new()
	_walk_mm.transform_format = MultiMesh.TRANSFORM_3D
	_walk_mm.use_custom_data = true
	InstanceBuffers.prepare(_walk_mm)
	_walk_mm.mesh = _mesh
	_walk_mm.instance_count = wcap
	_walk_mm.visible_instance_count = 0
	_walk_buf.resize(wcap * 16)
	_walk_buf.fill(0.0)
	_walk_mmi = MultiMeshInstance3D.new()
	_walk_mmi.name = "DawnCrowd"
	_walk_mmi.multimesh = _walk_mm
	_walk_mmi.material_override = _walk_mat
	_walk_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_walk_mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_walk_mmi.visible = false
	add_child(_walk_mmi)


## Writes one figure into `buf` at instance `i`: standing, sitting (lower and longer) or broad.
static func put(buf: PackedFloat32Array, i: int, at: Vector3, yaw: float, pose: int, shirt: Color, trousers: float) -> void:
	var b := i * 16
	var c := cos(yaw)
	var s := sin(yaw)
	var sx := 1.0
	var sy := 1.0
	var sz := 1.0
	if pose == SIT:
		sy = 0.6
		sz = 1.35
	elif pose == BROAD:
		sx = 1.3
		sz = 1.15
		sy = 1.06
	buf[b] = c * sx
	buf[b + 1] = 0.0
	buf[b + 2] = s * sz
	buf[b + 3] = at.x
	buf[b + 4] = 0.0
	buf[b + 5] = sy
	buf[b + 6] = 0.0
	buf[b + 7] = at.y
	buf[b + 8] = -s * sx
	buf[b + 9] = 0.0
	buf[b + 10] = c * sz
	buf[b + 11] = at.z
	buf[b + 12] = shirt.r
	buf[b + 13] = shirt.g
	buf[b + 14] = shirt.b
	buf[b + 15] = trousers


## A site's figures now: [position, yaw, pose, shirt, trousers] each.
func _figures(s: Dictionary) -> Array:
	var out: Array = []
	var n := int(s["n"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(s["id"]))
	match str(s["kind"]):
		"queue":
			var line: PackedVector2Array = s["line"]
			var out_v: Vector2 = s["out"]
			var door: Vector2 = s["door"]
			if n > 0:
				var head := door - out_v * 0.0
				var bp := head + (line[1] - line[0]).normalized() * -0.9 + out_v * 0.3 if line.size() > 1 else head
				out.append([_ground(bp), atan2(-out_v.x, -out_v.y), BROAD, BOUNCER_SHIRT, 0.3])
			for k in mini(n, line.size() - 1):
				var p := line[k] + Vector2(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12))
				var to := (line[maxi(k - 1, 0)] - line[k + 1]).normalized()
				out.append([_ground(p), atan2(-to.x, -to.y) + rng.randf_range(-0.4, 0.4), STAND,
						Color(DARK[rng.randi() % DARK.size()]), rng.randf_range(0.25, 0.5)])
		"trend":
			# Loop MW-4: the trend's queue, bright clothes, nobody at the door.
			var line: PackedVector2Array = s["line"]
			for k in mini(n, line.size() - 1):
				var p := line[k] + Vector2(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12))
				var to := (line[maxi(k - 1, 0)] - line[k + 1]).normalized()
				var shirt := Color(BRIGHT[rng.randi() % BRIGHT.size()])
				if str(s["id"]) in GELATO and (_month_now >= 11 or _month_now <= 3):
					shirt = Color(COATS[rng.randi() % COATS.size()])
				out.append([_ground(p), atan2(-to.x, -to.y) + rng.randf_range(-0.5, 0.5), STAND, shirt, rng.randf() * 0.99])
		"steps":
			var slots: Array = s["slots"]
			for k in mini(n, slots.size()):
				var sl: Dictionary = slots[k]
				out.append([_ground(sl["p"]), sl["yaw"], sl["pose"], Color(sl["shirt"]), rng.randf() * 0.99])
			if bool(s.get("guitar_on", false)):
				var face: Vector2 = s["face"]
				out.append([_ground(s["guitar"]), atan2(-face.x, -face.y), SIT, GUITAR_SHIRT, 0.0])
		"plan_c", "roof", "terrace", "chill", "deck", "stop", "office", "meet", "jazz", "jazz_cafe":
			var slots: Array = s["slots"]
			for k in mini(n, slots.size()):
				var sl: Dictionary = slots[k]
				var p: Vector2 = sl["p"]
				var y := float(sl["y"]) if sl.has("y") else _ground(p).y
				out.append([Vector3(p.x, y, p.y), sl["yaw"], int(sl.get("pose", STAND)), Color(sl["shirt"]), rng.randf() * 0.99])
	if s.get("officer", Vector3.INF) != Vector3.INF:
		out.append([s["officer"], float(s.get("officer_yaw", 0.0)), STAND, OFFICER_SHIRT, OFFICER_TROUSERS])
	return out


func _ground(p: Vector2) -> Vector3:
	return Vector3(p.x, map.deck_height(-1, p.x, p.y) if map != null else 0.0, p.y)


## Rewrites the cells whose crowds changed: each figure of each active site in the cell.
func _redraw() -> void:
	for c: Vector2i in _cells:
		var cell: Dictionary = _cells[c]
		if not bool(cell["dirty"]):
			continue
		cell["dirty"] = false
		var buf: PackedFloat32Array = cell["buf"]
		var n := 0
		var box := AABB()
		for s in sites:
			if s["cell"] != c or not bool(s["active"]):
				continue
			for f: Array in s["inst"]:
				if n >= int(cell["cap"]):
					break
				put(buf, n, f[0], f[1], f[2], f[3], f[4])
				box = AABB(f[0], Vector3.ZERO) if n == 0 else box.expand(f[0])
				n += 1
		var mm: MultiMesh = cell["mm"]
		if n > 0:
			InstanceBuffers.send(mm.get_rid(), buf)
			mm.custom_aabb = box.grow(1.0).expand(box.end + Vector3(0, 2.5, 0))
		mm.visible_instance_count = n
		(cell["mmi"] as MultiMeshInstance3D).visible = n > 0


# --- the logic -----------------------------------------------------------------------------

## Every crowd takes its size at the next tick (the look or the clock changed).
func refresh() -> void:
	for s in sites:
		s["next"] = 0.0


func _process(dt: float) -> void:
	if dt <= 0.0 or not clock.is_valid():
		return
	var t0 := Time.get_ticks_usec()
	t += dt
	_tick_t += dt
	if _route_task >= 0 and WorkerThreadPool.is_task_completed(_route_task):
		WorkerThreadPool.wait_for_task_completion(_route_task)
		_route_task = -1
		_finish_routes()
	if _tick_t >= TICK:
		var step := _tick_t
		_tick_t = 0.0
		tick(step)
	if (dawn_on or office_on) and not walkers.is_empty():
		_walk_t += dt
		if _walk_t >= WALK_TICK:
			_walk_t = 0.0
			_move_walkers()
	spent_usec += Time.get_ticks_usec() - t0


## One tick of the logic, `step` seconds after the last.
func tick(step: float) -> void:
	var now: Dictionary = clock.call()
	var cal: Dictionary = calendar.call() if calendar.is_valid() else {}
	var hour := float(now["hour"])
	var weekday := int(now["weekday"])
	_weekday_now = weekday
	var live := bool(cal.get("live", false))
	var month := int(cal.get("month", 7)) if live else 7
	_month_now = month
	var rain := bool(cal.get("rain", false))
	var look := str(cal.get("look", "Day"))
	var sunset := float(cal.get("sunset", 19.5))
	var eye: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var eye2 := Vector2(eye.x, eye.z)
	var veh: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF, 0.0, false]
	var night := night_day(hour, weekday) * 100 + (0 if hour >= 12.0 else 1)
	if night != _night_key:
		_night_key = night
	_last_hour = hour
	var k := amount
	police_on = police_time(hour, weekday)
	var steps_lvl := 0.0
	var plan_lvl := 0.0
	for s in sites:
		var kind := str(s["kind"])
		var want := 0
		match kind:
			"queue", "roof":
				# A roof without its ring (no tall roof found) stays empty.
				if kind == "roof" and (s["slots"] as Array).is_empty():
					want = 0
				else:
					want = queue_len(int(s["max"]), str(s["curve"]), hour, weekday, k)
			"terrace":
				var seats := int(s["max"])
				want = loretka_terrace(hour, weekday, month, rain, seats)
				want = mini(2 * roundi(want * k * 0.5), seats)
			"steps":
				steps_lvl = steps_level(hour, month, rain, sunset)
				want = roundi(STEPS_MAX * k * steps_lvl)
			"plan_c":
				plan_lvl = plan_c_level(hour, weekday, month, rain)
				want = roundi(PLAN_C_MAX * k * plan_lvl)
			"deck":
				want = 0 if (s["slots"] as Array).is_empty() else deck_count(int(s["max"]), hour, weekday, month, rain,
						float(s["open"]), float(s["close"]), k)
			"chill":
				var lvl := street_level(hour, month, rain) if bool(s.get("street", false)) else chill_level(hour, month, rain)
				if bool(s.get("pub", false)):
					lvl = pub_level(hour, weekday, month, rain)
				if bool(s.get("club", false)):
					lvl = club_level(hour, weekday, month, rain)
				if bool(s.get("theatre", false)):
					lvl = theatre_level(hour, weekday, rain)
				want = roundi(int(s["max"]) * k * lvl)
			"stop":
				want = roundi(int(s["max"]) * k * maxf(stop_level(hour, weekday, rain), float(s.get("floor", 0.0))))
			"office":
				want = office_count(int(s["max"]), hour, weekday, rain, k)
			"meet":
				want = roundi(int(s["max"]) * k * meet_level(hour, weekday, rain))
			"jazz":
				want = 0
				if jazz_on(hour):
					want = mini(JAZZ_BAND + roundi((int(s["max"]) - JAZZ_BAND) * k * jazz_level(hour, weekday, month, rain)), int(s["max"]))
			"jazz_cafe":
				want = mini(roundi(int(s["max"]) * k * jazz_cafe_level(hour, month, rain)), int(s["max"]))
			"trend":
				var q: Array = [0, ""]
				if s["id"] == PISTACJA_ID:
					q = pistacja_queue(hour, weekday)
				elif s["id"] == PADEL_ID:
					q = padel_queue(hour, weekday)
				elif s["id"] in KUKLA:
					q = kukla_queue(hour, weekday)
				elif s["id"] in MILK:
					q = milk_queue(hour, weekday)
				elif s["id"] in GELATO:
					q = gelato_queue(hour, weekday, month)
				elif s["id"] in KRINGULA:
					q = kringula_queue(hour, weekday)
				elif s["id"] in MIESZANE:
					q = mieszane_queue(hour, weekday)
				elif s["id"] in COFFEE:
					q = coffee_queue(hour, weekday)
				elif s["id"] == PIURE_ID:
					q = piure_queue(hour, weekday)
				elif s["id"] == ZAKWAS_ID:
					q = zakwas_queue(hour, weekday)
				elif s["id"] == DZEMINI_ID:
					q = dzemini_queue(hour, dzemini_hype)
				elif trend.is_valid():
					q = trend.call(str(s["id"]))
				if int(q[0]) > 0 and int(mrozulo.get(str(s["id"]), -1)) == weekday:
					q = [int(s["max"]), "mrozulo"]
				want = mini(roundi(int(q[0]) * k), int(s["max"]) * 2)
				s["tag"] = str(q[1])
		s["want"] = want
		if t >= float(s["next"]):
			s["next"] = t + _rng.randf_range(REWRITE.x, REWRITE.y)
			if int(s["n"]) != want:
				s["n"] = want
				s["dirty"] = true
		if kind == "steps":
			var g := guitar_on(int(s["n"]), hour)
			if g != bool(s.get("guitar_on", false)):
				s["guitar_on"] = g
				s["dirty"] = true
		var near := eye2.distance_to(s["at"]) <= ACTIVE_R
		if near != bool(s["active"]):
			s["active"] = near
			s["dirty"] = true
		_police_site(s, eye2)
		if bool(s["dirty"]):
			s["dirty"] = false
			s["inst"] = _figures(s) if near else []
			(_cells[s["cell"]] as Dictionary)["dirty"] = true
		if kind == "roof" and _ring != null:
			# F's asks: the band while the club is open (the roof's hours) and near the view.
			var lit := near and want > 0
			if lit != _ring.visible:
				_ring.visible = lit
				if log_on:
					print("night: Level 26's band of light %s" % ("on" if lit else "off"))
		if near and kind == "queue":
			_door(s, step, veh)
		elif near and kind in ["steps", "plan_c"]:
			_chatter(s, step, veh)
		elif near and kind == "trend":
			_trend_talk(s, step)
		elif near and kind == "office":
			_office_talk(s, step, hour, rain)
		elif near and kind == "meet":
			_meet_talk(s, step)
		elif near and kind == "chill" and s.has("talk"):
			_site_talk(s, step)
	_redraw()
	_dawn(hour, weekday, live, look, step, eye2)
	_office(hour, weekday, rain, step, eye2)
	levels = {"dawn": 1.0 if dawn_on and not walkers.is_empty() else 0.0,
			"office": 1.0 if office_on and not walkers.is_empty() else 0.0, "police_club": 1.0 if police_on else 0.0,
			"steps": steps_lvl, "guitar": 1.0 if by_id.has(STEPS_ID) and bool(sites[by_id[STEPS_ID]].get("guitar_on", false)) else 0.0,
			"plan_c": plan_lvl}
	for s in sites:
		if s["kind"] == "trend":
			levels[str(s["id"])] = float(s["n"]) / float(s["max"])
	if log_on:
		_log_t -= step
		if _log_t <= 0.0:
			_log_t = LOG_EVERY
			print("night: %s" % summary(hour, weekday))


## "02:00 day 6 · queues smola 24, ... · rejections 1 · dawn walkers 30 · steps 19 · plan_c 0 · police on".
func summary(hour: float, weekday: int) -> String:
	var q := PackedStringArray()
	var other := PackedStringArray()
	for s in sites:
		if s["kind"] == "queue":
			q.append("%s %d" % [s["id"], s["n"]])
		else:
			other.append("%s %d" % [s["kind"], s["n"]])
	return "%02d:%02d day %d · queues %s · rejections %d · car lines %d · dawn walkers %d%s · %s · police %s" % [
			int(hour), int(fmod(hour, 1.0) * 60.0), weekday, ", ".join(q), rejections, car_lines, walkers.size(),
			"" if routes.size() > 0 or not dawn_on else " (routes %s)" % ("being found" if _route_task >= 0 else "none"),
			", ".join(other), "on" if police_on else "off"]


## The door: a rejection every 30-60 s while the queue (4+) is on screen; the car at the door.
func _door(s: Dictionary, step: float, veh: Array) -> void:
	var door: Vector2 = s["door"]
	var door3 := _ground(door)
	var seen: bool = on_screen.call(door3, 2.0) if on_screen.is_valid() else true
	if int(s["n"]) >= DOOR_MIN and seen:
		s["door_t"] = float(s["door_t"]) - step
		if float(s["door_t"]) <= 0.0:
			s["door_t"] = _rng.randf_range(DOOR_GAP.x, DOOR_GAP.y)
			reject(s)
		s["chat_t"] = float(s["chat_t"]) - step
		if float(s["chat_t"]) <= 0.0:
			s["chat_t"] = _rng.randf_range(CHAT_GAP.x, CHAT_GAP.y)
			_say_from_queue(s)
	var p: Vector3 = veh[0]
	var at_door := p != Vector3.INF and car_at_door(Vector2(p.x, p.z).distance_to(door), float(veh[1]), bool(veh[2]))
	var paint_id: String = str(paint.call()) if paint.is_valid() else "red"
	# The garage loop: the black car at Lusterko's door finds E01 (once; the egg's conditions are
	# its night and hours) and gets the black line then, queue or not.
	var key := door_egg(str(s["id"]), paint_id) if at_door else ""
	if key != "" and egg.is_valid() and bool(egg.call(key)):
		s["car_night"] = _night_key
		car_lines += 1
		_say(func() -> Vector3: return door3 + Vector3(0, 2.0, 0), "Bramka", "club_door", "car_black", BUBBLE)
		if log_on:
			print("night: the black car at %s's door (%.0f km/h): egg %s and the car_black line" % [s["id"], float(veh[1]), key])
	elif at_door and int(s["car_night"]) != _night_key and int(s["n"]) > 0:
		s["car_night"] = _night_key
		car_lines += 1
		var tag := "car_black" if paint_id == "black" else "car"
		_say(_anchor(s, 0), "Bramka", "club_door", tag, BUBBLE)
		if log_on:
			print("night: the car at %s's door (%.0f km/h, paint %s): the bouncer's %s line" % [s["id"], float(veh[1]), paint_id, tag])


## The door turns the head of the queue away: the bouncer's `reject` line; half of them rejoin the
## end ("try again"), half go (to the kebab).
func reject(s: Dictionary) -> void:
	rejections += 1
	s["rejected"] = int(s.get("rejected", 0)) + 1
	var gone := _rng.randf() < 0.5
	if gone and int(s["n"]) > 0:
		s["n"] = int(s["n"]) - 1
		s["inst"] = _figures(s) if bool(s["active"]) else []
		(_cells[s["cell"]] as Dictionary)["dirty"] = true
	_say(_anchor(s, 0), "Bramka", "club_door", "reject", BUBBLE)
	if log_on:
		print("night: rejection at %s (%s; queue %d)" % [s["id"], "goes for a kebab" if gone else "back to the end", int(s["n"])])


## A queue member's line now and then (a clubber, or the bouncer on the queue; at Lusterko after
## 08:00 the morning's door line).
func _say_from_queue(s: Dictionary) -> void:
	var n := int(s["n"])
	if n < 2:
		return
	var i := 1 + _rng.randi() % mini(n, 8)
	if str(s["id"]) == "lusterko" and _last_hour >= 8.0 and _last_hour < 12.0:
		_say(_anchor(s, 0), "Bramka", "club_door", "dawn", BUBBLE)
	elif _rng.randf() < 0.25:
		_say(_anchor(s, 0), "Bramka", "club_door", "queue", BUBBLE)
	else:
		_say(_anchor(s, i), "", "clubbers", "", BUBBLE)


## The steps and the square talk too: `schodki` (the guitarist's, the sunset's), `clubbers` Plan C.
func _chatter(s: Dictionary, step: float, veh: Array) -> void:
	if int(s["n"]) < 4:
		return
	var at3 := _ground(s["door"])
	if on_screen.is_valid() and not on_screen.call(at3, 2.0):
		return
	s["chat_t"] = float(s["chat_t"]) - step
	if float(s["chat_t"]) > 0.0:
		return
	s["chat_t"] = _rng.randf_range(CHAT_GAP.x, CHAT_GAP.y)
	var i := _rng.randi() % maxi(int(s["n"]), 1)
	if s["kind"] == "plan_c":
		_say(_anchor(s, i), "", "clubbers", "", BUBBLE)
		return
	var p: Vector3 = veh[0]
	if bool(s.get("guitar_on", false)) and p != Vector3.INF and Vector2(p.x, p.z).distance_to(s["guitar"]) < 25.0:
		_say(func() -> Vector3: return _ground(s["guitar"]) + Vector3(0, 1.6, 0), "", "schodki", "guitar", BUBBLE, true)
	elif str(calendar.call().get("look", "")) == "Dusk" if calendar.is_valid() else false:
		_say(_anchor(s, i), "", "schodki", "sunset", BUBBLE, true)
	else:
		_say(_anchor(s, i), "", "schodki", "", BUBBLE)


## Loop MW-4: a trend queue's `viral` line every 35-60 s on screen (the tag: day 1 "new", the
## queue's "queue", the last days' "gone").
func _trend_talk(s: Dictionary, step: float) -> void:
	if int(s["n"]) < 1 or str(s["tag"]) == "":
		return
	if on_screen.is_valid() and not on_screen.call(_ground(s["door"]), 2.0):
		return
	s["chat_t"] = float(s["chat_t"]) - step
	if float(s["chat_t"]) > 0.0:
		return
	s["chat_t"] = _rng.randf_range(CHAT_GAP.x, CHAT_GAP.y)
	_say(_anchor(s, _rng.randi() % maxi(int(s["n"]), 1)), "", "viral", str(s["tag"]), BUBBLE, true)


## City-life satire #1: a line from the car meet's crowd every CHAT_GAP s while it is on screen.
func _meet_talk(s: Dictionary, step: float) -> void:
	if int(s["n"]) < 2:
		return
	if on_screen.is_valid() and not on_screen.call(_ground(s["door"]), 2.0):
		return
	s["chat_t"] = float(s["chat_t"]) - step
	if float(s["chat_t"]) > 0.0:
		return
	s["chat_t"] = _rng.randf_range(CHAT_GAP.x, CHAT_GAP.y)
	_say(_anchor(s, _rng.randi() % maxi(int(s["n"]), 1)), "", "car_meet", "", BUBBLE)


## A chill spot with lines of its own (`talk`: SOWA's night owls): one every CHAT_GAP s on screen.
func _site_talk(s: Dictionary, step: float) -> void:
	if int(s["n"]) < 2:
		return
	if on_screen.is_valid() and not on_screen.call(_ground(s["door"]), 2.0):
		return
	s["chat_t"] = float(s.get("chat_t", 0.0)) - step
	if float(s["chat_t"]) > 0.0:
		return
	s["chat_t"] = _rng.randf_range(CHAT_GAP.x, CHAT_GAP.y)
	_say(_anchor(s, _rng.randi() % maxi(int(s["n"]), 1)), "", str(s["talk"]), "", BUBBLE)


## An office group's overheard line every 12-25 s while it is on screen (the `office` lines).
func _office_talk(s: Dictionary, step: float, hour: float, rain: bool) -> void:
	if int(s["n"]) < 3:
		return
	if on_screen.is_valid() and not on_screen.call(_ground(s["door"]), 2.0):
		return
	s["chat_t"] = float(s["chat_t"]) - step
	if float(s["chat_t"]) > 0.0:
		return
	s["chat_t"] = _rng.randf_range(OFFICE_GAP.x, OFFICE_GAP.y)
	office_lines += 1
	_say(_anchor(s, _rng.randi() % maxi(int(s["n"]), 1)), "", "office", office_tag(hour, rain), BUBBLE)


## A bubble anchor on figure `i` of site `s` (0: the bouncer at a queue).
func _anchor(s: Dictionary, i: int) -> Callable:
	return func() -> Vector3:
		var inst: Array = s["inst"]
		if inst.is_empty():
			return Vector3.INF
		var f: Array = inst[clampi(i, 0, inst.size() - 1)]
		return (f[0] as Vector3) + Vector3(0, 2.0, 0)


func _say(anchor: Callable, speaker: String, group: String, tag: String, accent: Color, prefer := false) -> void:
	if dialogue == null:
		return
	var l: Array = dialogue.say_ambient(anchor, speaker, group, tag, 4.0, accent, 2.2, prefer or tag != "")
	if log_on and not l.is_empty():
		print("night: line %s/%s: %s" % [group, tag, l[0]])


## The police by a club (Lusterko, Smoła), Fri/Sat 00:00-08:00: the parked car through police.gd,
## the officer standing by it in this crowd; their lines to a slow car.
func _police_site(s: Dictionary, eye2: Vector2) -> void:
	if not bool(s.get("police", false)):
		return
	var want := police_on and eye2.distance_to(s["at"]) <= ACTIVE_R
	var has: bool = s["officer"] != Vector3.INF
	if want and not has:
		var spot := {}
		if police != null and police.has_method("club_park"):
			spot = police.club_park(str(s["id"]), s["door"])
		if spot.is_empty():
			# No police (or no lane): the officer stands across the footway from the door.
			var o: Vector2 = (s["door"] as Vector2) + (s["out"] as Vector2) * 4.0 + (s["line"][1] - s["line"][0]).normalized() * 6.0
			spot = {"officer": _ground(o), "officer_yaw": atan2((s["out"] as Vector2).x, (s["out"] as Vector2).y)}
		s["officer"] = spot["officer"]
		s["officer_yaw"] = spot["officer_yaw"]
		s["dirty"] = true
		if log_on:
			print("night: police by %s (%s)" % [s["id"], "a parked patrol car and an officer" if spot.has("car") else "an officer"])
	elif not want and has:
		s["officer"] = Vector3.INF
		if police != null and police.has_method("club_leave"):
			police.club_leave(str(s["id"]))
		s["dirty"] = true
	if not want:
		return
	s["police_t"] = float(s["police_t"]) - TICK
	var veh: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF, 0.0, false]
	var p: Vector3 = veh[0]
	if p == Vector3.INF or bool(veh[2]):
		return
	var o3: Vector3 = s["officer"]
	var d := Vector2(p.x, p.z).distance_to(Vector2(o3.x, o3.z))
	if d > POLICE_NEAR or float(veh[1]) >= CAR_KMH:
		return
	var anchor := func() -> Vector3: return (s["officer"] as Vector3) + Vector3(0, 2.0, 0) if s["officer"] != Vector3.INF else Vector3.INF
	if float(veh[1]) < 1.0 and int(s["sober_night"]) != _night_key:
		s["sober_night"] = _night_key
		s["police_t"] = POLICE_GAP
		_say(anchor, "Sierżant Bogdan", "police_club", "sober", POLICE_BUBBLE, true)
	elif float(s["police_t"]) <= 0.0:
		s["police_t"] = POLICE_GAP
		_say(anchor, "Sierżant Bogdan", "police_club", "", POLICE_BUBBLE)


# --- the dawn crowd ------------------------------------------------------------------------

func _dawn(hour: float, weekday: int, live: bool, look: String, step: float, eye2: Vector2) -> void:
	var on: bool = dawn_time(hour, weekday, live, look) and not (_route_in.get("to", []) as Array).is_empty()
	if on != dawn_on:
		dawn_on = on
		if on:
			walkers.clear()  # the office crowd, if it was out
			walk_mode = "dawn"
			office_on = false
		elif walk_mode == "dawn":
			walk_mode = ""
		if log_on:
			print("night: the dawn crowd %s" % ("comes out" if on else "goes home"))
		if not on:
			walkers.clear()
			_walk_mm.visible_instance_count = 0
			_walk_mmi.visible = false
	if not on:
		return
	if routes.is_empty():
		if _route_task < 0 and not _dawn_asked:
			_start_routes("dawn")
		return
	var want := dawn_count(hour, amount)
	while walkers.size() < want:
		_spawn_walkers(want - walkers.size(), true)
	while walkers.size() > want:
		walkers.pop_back()
	# Each walker at its end starts again at a club.
	for w in walkers:
		if float(w["s"]) + float(w["v"]) * (t - float(w["t"])) >= float(routes[int(w["r"])]["len"]):
			_restart(w)
	_dawn_bubble -= step
	var near := _walk_box.grow(100.0).has_point(eye2)
	if near and _dawn_bubble <= 0.0:
		for i in walkers.size():
			var p := walker_pos(i)
			if on_screen.is_valid() and not on_screen.call(p, 2.0):
				continue
			_dawn_bubble = DAWN_GAP
			dawn_lines += 1
			var at_palm := str(routes[int(walkers[i]["r"])]["to"]) == "palma" and Vector2(p.x, p.z).distance_to(routes[int(walkers[i]["r"])]["end"]) < 40.0
			_say(func() -> Vector3: return walker_pos(i) + Vector3(0, 2.0, 0) if i < walkers.size() else Vector3.INF,
					"", "dawn_crowd", "palm" if at_palm else "", BUBBLE, at_palm)
			break


# --- the office crowd ---------------------------------------------------------------------

## Rondo Daszyńskiego's office workers walking between the metro exits and the towers, over the
## zebra crossings: out while the view is within OFFICE_NEAR of their box, on a working day's
## rush hours (`office_level`), and never over the dawn crowd. The walkers are the dawn crowd's
## (one MultiMesh); the routes are found the first time the view comes near.
func _office(hour: float, weekday: int, rain: bool, step: float, eye2: Vector2) -> void:
	var count := office_count(OFFICE_MAX, hour, weekday, rain, amount)
	var has_ends := not (_office_in.get("to", []) as Array).is_empty()
	var on := has_ends and not dawn_on and count > 0 and _office_box.grow(OFFICE_NEAR).has_point(eye2)
	if on != office_on:
		office_on = on
		if on:
			walkers.clear()
			walk_mode = "office"
		elif walk_mode == "office":
			walk_mode = ""
			walkers.clear()
			_walk_mm.visible_instance_count = 0
			_walk_mmi.visible = false
		if log_on:
			print("night: the office crowd %s" % ("comes out" if on else "goes home"))
	if not on:
		return
	if office_routes.is_empty():
		if _route_task < 0 and not _office_asked:
			_start_routes("office")
		return
	while walkers.size() < count:
		_spawn_walkers(count - walkers.size(), true)
	while walkers.size() > count:
		walkers.pop_back()
	for w in walkers:
		if float(w["s"]) + float(w["v"]) * (t - float(w["t"])) >= float(office_routes[int(w["r"])]["len"]):
			_restart(w)
	_gate_office(step)
	_office_bubble -= step
	if _office_bubble > 0.0:
		return
	for i in walkers.size():
		var p := walker_pos(i)
		if on_screen.is_valid() and not on_screen.call(p, 2.0):
			continue
		_office_bubble = _rng.randf_range(OFFICE_GAP.x, OFFICE_GAP.y) * 0.6
		office_lines += 1
		_say(func() -> Vector3: return walker_pos(i) + Vector3(0, 2.0, 0) if i < walkers.size() and walk_mode == "office" else Vector3.INF,
				"", "office", office_tag(hour, rain), BUBBLE)
		break


## The routes, found once in a worker thread (pure data: the footways near the clubs).
func _start_routes(mode := "dawn") -> void:
	var paths: Array = []
	var area := _office_box.grow(100.0)
	for f in _foot:
		# The office crowd's graph is only the footways near the rondo (the dawn crowd's is all).
		if mode == "office" and not area.has_point((f["pts"] as PackedVector2Array)[0]):
			continue
		paths.append([f["pts"], int(f["dk"])])
	var rin: Dictionary = _office_in if mode == "office" else _route_in
	var from: Array = rin["from"]
	var to: Array = rin["to"]
	_route_mode = mode
	if mode == "office":
		_office_asked = true
	else:
		_dawn_asked = true
	_route_out = [null]
	var out := _route_out
	_route_task = WorkerThreadPool.add_task(func() -> void: out[0] = build_routes(paths, from, to), false, "crowd routes")
	if log_on:
		print("night: finding the dawn crowd's routes (%d footways, %d clubs → %d ends)" % [paths.size(), from.size(), to.size()])


## Heights (the ground under each corner, or its deck) and lengths for the thread's routes.
func _finish_routes() -> void:
	var found: Variant = _route_out[0] if not _route_out.is_empty() else null
	var raw: Array = found if found is Array else []
	var office := _route_mode == "office"
	var made: Array[Dictionary] = []
	for r: Dictionary in raw:
		if office and (str(r["from"]) == str(r["to"])):
			continue
		var pts: PackedVector2Array = r["pts"]
		var dk: PackedInt32Array = r["dk"]
		var h := PackedFloat32Array()
		var cum := PackedFloat32Array()
		var run := 0.0
		for i in pts.size():
			if i > 0:
				run += pts[i].distance_to(pts[i - 1])
			cum.append(run)
			h.append(map.deck_height(dk[i], pts[i].x, pts[i].y) if map != null else 0.0)
		if office and run < 40.0:
			continue
		made.append({"pts": pts, "h": h, "cum": cum, "len": run, "from": r["from"], "to": r["to"], "end": pts[pts.size() - 1],
				"xs": _route_crossings(pts, cum) if office else []})
	if office:
		office_routes = made
		if log_on:
			print("night: %d office routes" % made.size())
		if made.is_empty():
			_office_in["to"] = []  # nothing to walk: the office stays on the kerbs
		_route_mode = "dawn"
		return
	routes = made
	if log_on:
		var lens := PackedStringArray()
		for r in routes:
			lens.append("%s→%s %.0f m" % [r["from"], r["to"], r["len"]])
		print("night: %d dawn routes: %s" % [routes.size(), ", ".join(lens)])
	if routes.is_empty():
		_route_in["to"] = []  # nothing to walk: the dawn crowd stays home


## The zebras a route walks over: [[from s, to s, zebra index], ...] in order along it, found
## from the route's pieces that lie on a zebra and run along it.
func _route_crossings(pts: PackedVector2Array, cum: PackedFloat32Array) -> Array:
	var out: Array = []
	for k in pts.size() - 1:
		var d := pts[k + 1] - pts[k]
		if d.length() < 0.5:
			continue
		var m := (pts[k] + pts[k + 1]) * 0.5
		for zi in _office_zebras.size():
			var z := _office_zebras[zi]
			var best := INF
			var along := 0.0
			for j in z.size() - 1:
				var cp := Geometry2D.get_closest_point_to_segment(m, z[j], z[j + 1])
				var dd := cp.distance_to(m)
				if dd < best:
					best = dd
					along = absf(d.normalized().dot((z[j + 1] - z[j]).normalized()))
			if best < 1.3 and along > 0.9:
				if not out.is_empty() and int(out[out.size() - 1][2]) == zi and absf(float(out[out.size() - 1][1]) - cum[k]) < 0.5:
					out[out.size() - 1][1] = cum[k + 1]
				else:
					out.append([cum[k], cum[k + 1], zi])
				break
	return out


## Is zebra `zi`'s walk phase on (and, for someone about to step out, not nearly over)?
func xing_walk(zi: int, entering: bool) -> bool:
	var ph := fposmod(t + float(zi % XING_PHASES) * XING_CYCLE / XING_PHASES, XING_CYCLE)
	return ph < XING_WALK - (XING_LATE if entering else 0.0)


## Holds the office walkers at the kerb of a zebra whose walk phase is off: their clock is put
## back by `dt`, so they stand where they are and the next walkers pile up behind them.
func _gate_office(dt: float) -> void:
	for w in walkers:
		var xs: Array = office_routes[int(w["r"])]["xs"]
		var s := float(w["s"]) + float(w["v"]) * (t - float(w["t"]))
		for x: Array in xs:
			if s >= float(x[1]):
				continue
			if s < float(x[0]) - 0.8 - float(w["q"]):
				break
			if s < float(x[0]) + 0.3 and not xing_walk(int(x[2]), true):
				w["t"] = float(w["t"]) + dt
				held_ticks += 1
			break


func _spawn_walkers(count: int, spread: bool) -> void:
	var left := count
	while left > 0:
		var g := mini(_rng.randi_range(1, 3), left)
		var r := _rng.randi() % _walk_routes().size()
		var s0 := _rng.randf_range(0.0, float(_walk_routes()[r]["len"]) * 0.9) if spread else 0.0
		var v := _rng.randf_range(0.9, 1.25)
		for i in g:
			walkers.append({"r": r, "s": s0 - i * 0.9, "t": t, "v": v, "off": (i - (g - 1) * 0.5) * 0.7 + _rng.randf_range(-0.1, 0.1),
					"k": 0, "shirt": _walker_shirt(), "q": _rng.randf() * XING_QUEUE,
					"tr": _rng.randf() * 0.99})
		left -= g


## The routes the walkers walk now: the office crowd's in mode "office", else the dawn crowd's.
func _walk_routes() -> Array[Dictionary]:
	return office_routes if walk_mode == "office" else routes


func _walker_shirt() -> Color:
	if walk_mode == "office":
		return Color(OFFICE_SHIRTS[_rng.randi() % OFFICE_SHIRTS.size()])
	return Color(DARK[_rng.randi() % DARK.size()] if _rng.randf() < 0.7 else BRIGHT[_rng.randi() % BRIGHT.size()])


func _restart(w: Dictionary) -> void:
	w["r"] = _rng.randi() % _walk_routes().size()
	w["s"] = -_rng.randf_range(0.0, 3.0)
	w["t"] = t
	w["k"] = 0


## Where walker `i` is now (its route, its distance along it, its side offset).
func walker_pos(i: int) -> Vector3:
	var w: Dictionary = walkers[i]
	var r: Dictionary = _walk_routes()[int(w["r"])]
	var s := clampf(float(w["s"]) + float(w["v"]) * (t - float(w["t"])), 0.0, float(r["len"]))
	var cum: PackedFloat32Array = r["cum"]
	var pts: PackedVector2Array = r["pts"]
	var h: PackedFloat32Array = r["h"]
	var k := int(w["k"])
	while k < cum.size() - 2 and cum[k + 1] < s:
		k += 1
	w["k"] = k
	var seg := maxf(cum[k + 1] - cum[k], 0.001)
	var f := clampf((s - cum[k]) / seg, 0.0, 1.0)
	var dir := (pts[k + 1] - pts[k]) / seg
	var q := pts[k].lerp(pts[k + 1], f) + Vector2(-dir.y, dir.x) * float(w["off"])
	return Vector3(q.x, lerpf(h[k], h[k + 1], f), q.y)


## The walkers' figures, 10 times a second while the view is near their box.
func _move_walkers() -> void:
	var eye: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var box_now := _office_box if walk_mode == "office" else _walk_box
	if not box_now.grow(ACTIVE_R).has_point(Vector2(eye.x, eye.z)):
		if _walk_mmi.visible:
			_walk_mmi.visible = false
		return
	var n := mini(walkers.size(), _walk_mm.instance_count)
	var box := AABB()
	for i in n:
		var w: Dictionary = walkers[i]
		var p := walker_pos(i)
		var r: Dictionary = _walk_routes()[int(w["r"])]
		var k := int(w["k"])
		var dir: Vector2 = (r["pts"][k + 1] - r["pts"][k]).normalized()
		put(_walk_buf, i, p, atan2(-dir.x, -dir.y), STAND, w["shirt"], float(w["tr"]))
		box = AABB(p, Vector3.ZERO) if i == 0 else box.expand(p)
	_walk_mm.visible_instance_count = n
	if n > 0:
		InstanceBuffers.send(_walk_mm.get_rid(), _walk_buf)
		_walk_mm.custom_aabb = box.grow(1.0).expand(box.end + Vector3(0, 2.5, 0))
	_walk_mmi.visible = n > 0


## The dawn crowd's routes: A* over the footways and crossings (`paths`: [PackedVector2Array,
## deck], their corners joined where they meet, ends within 3 m of another path joined too) from
## each club door (`from`: [id, Vector2]) to each end (`to`: [name, Vector2]). Pure (a worker
## thread runs it; check_crowds.gd runs it on a grid): [{pts, dk, from, to}].
static func build_routes(paths: Array, from: Array, to: Array) -> Array:
	var key_of := {}
	var pos := PackedVector2Array()
	var dks := PackedInt32Array()
	var adj: Array[PackedInt32Array] = []
	var node := func(p: Vector2, dk: int) -> int:
		var key := Vector2i(roundi(p.x * 2.0), roundi(p.y * 2.0))
		if key_of.has(key):
			return key_of[key]
		key_of[key] = pos.size()
		pos.append(p)
		dks.append(dk)
		adj.append(PackedInt32Array())
		return pos.size() - 1
	var ends: Array[int] = []
	for path: Array in paths:
		var pts: PackedVector2Array = path[0]
		var prev := -1
		for i in pts.size():
			var n: int = node.call(pts[i], int(path[1]))
			if prev >= 0 and prev != n:
				adj[prev].append(n)
				adj[n].append(prev)
			if i == 0 or i == pts.size() - 1:
				ends.append(n)
			prev = n
	# Loose ends within 3 m of another node: joined (a crossing drawn a little short).
	var grid := {}
	for i in pos.size():
		var c := Vector2i(floori(pos[i].x / 4.0), floori(pos[i].y / 4.0))
		if not grid.has(c):
			grid[c] = PackedInt32Array()
		grid[c].append(i)
	for a in ends:
		if adj[a].size() > 1:
			continue
		var c := Vector2i(floori(pos[a].x / 4.0), floori(pos[a].y / 4.0))
		var best := -1
		var best_d := 3.0
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				for b: int in grid.get(c + Vector2i(dx, dz), PackedInt32Array()):
					if b != a and not b in adj[a] and pos[a].distance_to(pos[b]) < best_d:
						best_d = pos[a].distance_to(pos[b])
						best = b
		if best >= 0:
			adj[a].append(best)
			adj[best].append(a)
	# The nodes within 80 m of a point, nearest first (up to 6: the nearest can be on a little island
	# of footway, a crossing or a courtyard, joined to nothing).
	var nearest := func(p: Vector2) -> Array:
		var near: Array = []
		for i in pos.size():
			var d := pos[i].distance_to(p)
			if d < 80.0 and adj[i].size() > 0:
				near.append([d, i])
		near.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		return near.slice(0, 6).map(func(x: Array) -> int: return x[1])
	# Connected pieces of the graph: a start and a goal in different pieces never get an A* run
	# (a failing search explores its whole piece, up to 36 times per pair).
	var comp := PackedInt32Array()
	comp.resize(pos.size())
	comp.fill(-1)
	var piece := 0
	for root in pos.size():
		if comp[root] >= 0:
			continue
		var stack := PackedInt32Array([root])
		comp[root] = piece
		while not stack.is_empty():
			var u: int = stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			for v in adj[u]:
				if comp[v] < 0:
					comp[v] = piece
					stack.append(v)
		piece += 1
	var out: Array = []
	var goals_of := {}
	for f: Array in from:
		var starts: Array = nearest.call(f[1])
		for e: Array in to:
			if not goals_of.has(e[0]):
				goals_of[e[0]] = nearest.call(e[1])
			var goals: Array = goals_of[e[0]]
			var route := PackedInt32Array()
			for a: int in starts:
				for b: int in goals:
					if a != b and comp[a] == comp[b]:
						route = _astar(pos, adj, a, b)
					if route.size() >= 2:
						break
				if route.size() >= 2:
					break
			if route.size() < 2:
				continue
			var pts := PackedVector2Array()
			var dk := PackedInt32Array()
			for n in route:
				pts.append(pos[n])
				dk.append(dks[n])
			out.append({"pts": pts, "dk": dk, "from": str(f[0]), "to": str(e[0])})
	return out


## A* from node a to node b over `adj` (straight-line distances): the nodes, or [] if none.
static func _astar(pos: PackedVector2Array, adj: Array[PackedInt32Array], a: int, b: int) -> PackedInt32Array:
	var n := pos.size()
	var g := PackedFloat32Array()
	g.resize(n)
	g.fill(INF)
	var came := PackedInt32Array()
	came.resize(n)
	came.fill(-1)
	var done := PackedByteArray()
	done.resize(n)
	done.fill(0)
	var heap_f := PackedFloat32Array()
	var heap_n := PackedInt32Array()
	g[a] = 0.0
	_push(heap_f, heap_n, pos[a].distance_to(pos[b]), a)
	var goal := pos[b]
	var pops := 0
	while not heap_n.is_empty():
		var u := _pop(heap_f, heap_n)
		if done[u] == 1:
			continue
		done[u] = 1
		pops += 1
		if u == b or pops > 60000:
			break
		for v in adj[u]:
			if done[v] == 1:
				continue
			var nd := g[u] + pos[u].distance_to(pos[v])
			if nd < g[v]:
				g[v] = nd
				came[v] = u
				_push(heap_f, heap_n, nd + pos[v].distance_to(goal), v)
	var out := PackedInt32Array()
	if came[b] < 0:
		return out
	var c := b
	while c >= 0:
		out.append(c)
		c = came[c]
	out.reverse()
	return out


static func _push(hf: PackedFloat32Array, hn: PackedInt32Array, f: float, n: int) -> void:
	hf.append(f)
	hn.append(n)
	var i := hf.size() - 1
	while i > 0:
		var p := (i - 1) / 2
		if hf[p] <= hf[i]:
			break
		var tf := hf[p]
		hf[p] = hf[i]
		hf[i] = tf
		var tn := hn[p]
		hn[p] = hn[i]
		hn[i] = tn
		i = p


static func _pop(hf: PackedFloat32Array, hn: PackedInt32Array) -> int:
	var top := hn[0]
	var last := hf.size() - 1
	hf[0] = hf[last]
	hn[0] = hn[last]
	hf.resize(last)
	hn.resize(last)
	var i := 0
	while true:
		var l := i * 2 + 1
		var r := l + 1
		var m := i
		if l < last and hf[l] < hf[m]:
			m = l
		if r < last and hf[r] < hf[m]:
			m = r
		if m == i:
			break
		var tf := hf[m]
		hf[m] = hf[i]
		hf[i] = tf
		var tn := hn[m]
		hn[m] = hn[i]
		hn[i] = tn
		i = m
	return top


func _exit_tree() -> void:
	if _route_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_route_task)
		_route_task = -1
