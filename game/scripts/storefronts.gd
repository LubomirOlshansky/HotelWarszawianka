extends Node3D
## Loop MW-2 (docs/design/parodies.md 2, 5, 6; docs/design/vision.md 3.0-3.2, 3.5, section 5 row 3):
## storefronts and parodies, built at runtime from the data both city paths have (the lane graph,
## the `address` and `kebab` pois, the notebook's places), never baked into the sector scenes.
##  - **Frogs** (parodies.md 2; ids stay `rechotka`): frog-green corner shops on the ground floor
##    of the real corner shops of the chain (the bake's OSM `convenience` pois with `fr`, 70 m
##    apart, none on a landmark); the two triple corners (Marszałkowska × Świętokrzyska and
##    Plac Zbawiciela: three Frogs on one junction, the spacing waived, egg `easter_rechotka`).
##    The facade itself comes from the city's own wall colliders when the shop's sector has
##    loaded: a ray from the road point at the door towards the building (the wall and its
##    normal, exact on either path and with LoD2), two more 2.6 m to each side (the 5.5 m of
##    straight wall), a roof 5 m over the street just inside. The stamp card (2.3): stop within
##    STAMP_REACH m of a door under 2 m/s for 2 s: the croak chime, the till's `rechotka` `stamp`
##    line, +1 stamp (one a shop a day, 10 a day); the 10th: HOT DOG GRATIS and +10 respect.
##  - **The 17 venues' neon fascias** (vision 3.0: the parody names of places.json; Glon's two
##    cafés make 18 signs; Syreni Szept is closed and dark): rows added to neon_signs.gd's atlas
##    (this script's `venue_atlas`, so the sector scenes stay as baked), each sign an instance in
##    its sector's own Neon MultiMesh (+0 draw calls), 0.14 m off the wall the ray found.
##  - **Leżak** (5): dumped e-scooters from the bake's `scooter` pois (lying, on a bench, in the
##    grass, on a shelter roof; 1 in 30 Frogs doors also has one), the empty parking zones from
##    `scooter_zone` (the one by Metro Nowy Świat-Uniwersytet holds a standing Leżak: egg
##    `easter_lezak`); the car within 1.2 m pushes one 1-3 m (never onto a lane), a clatter and
##    the `lezak` `knock` aside once a minute.
##  - **Metro entrances** (vision 3.5): at each street `subway_entrance` poi, facing its `yaw`, in
##    the form its `f` says (glass-vault canopy, granite stairwell, footway passage mouth) with a
##    treaded opening, a red M post and, on 3 in 5, a glass lift (`Props.add_metro_entrance`).
##  - **Kebab** (6.1): U ZDZICHA and NA CIENKIM name boards on the stands nearest those places,
##    the vendors' `zdzich`, `cienkim`, `hala`, `stadium` tags (jobs.gd draws the other stands in
##    a MultiMesh per tile); **billboards** (6.2): the four new `signs` lines (eggs.gd's
##    billboards) by a triple corner, Dworzec Centralny, Hala Mirowska and Nowy Świat's metro,
##    and MW-4's WIRALEK line on Chmielna (10 billboards with eggs.gd's five).
## Drawing: per loaded sector one MultiMesh of Frogs, one of Leżaks (`fine_detail`) and one mesh of
## the street props (metro entrances, zones), children of the sector's root (gone with it); no sun
## shadow. Nothing runs per frame but a 2 Hz tick (stamps) and the car's 16 m cell of scooters.

const MapBuilderStatic := preload("res://scripts/map_builder.gd")
const Lang := preload("res://scripts/lang.gd")
const Models := preload("res://scripts/models.gd")
const Props := preload("res://scripts/props.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const Neon := preload("res://scripts/neon_signs.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Notebook := preload("res://scripts/notebook.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Zaglebie := preload("res://scripts/zaglebie.gd")

## The sector size (the city's 512 m tiles: map_builder.gd SECTOR).
const TILE := 512.0
const TICK := 0.5
## Frogs (parodies.md 2.2): a triple corner's address road point this near a junction node anchors a shop.
const JUNCTION_REACH := 26.0
const SPACING := 70.0
## The triple corners (place ids of the notebook: their junctions).
const TRIPLES := ["swietokrzyska_metro", "plac_zbawiciela"]
const TRIPLE_REACH := 40.0
## The facade: the ray's height over the road, how far it looks, the straight wall each side.
const RAY_UP := 1.2
const RAY_FAR := 45.0
## How far a triple corner's own sites look from its junction (Marszałkowska's corners are wide).
const CORNER_FAR := 80.0
const SHOP_SIDE := 2.6
const PLANE_TOL := 0.35
const SHOP_ROOF := 5.0
## The stamp card (2.3; *guess*: 6 m in the spec is often out of reach from the kerb lane).
const STAMP_REACH := 8.0
const STAMP_SPEED := 2.0
const STAMP_HOLD := 2.0
const STAMPS_DAY := 10
const STAMPS_CARD := 10
const FREE_RESPECT := 10
const LINE_GAP := 60.0
const FROGS_COLOUR := Color("#4fae3b")
const CAFE_TUBE := Color(1.0, 0.78, 0.45)
const SHISHA_TUBE := Color(0.72, 0.3, 1.0)
const SHISHA_TUBE_B := Color(0.2, 0.9, 0.95)
## The food-hype parodies' tubes (gaulle-and-food-hype.md 2): a dark red-brown cup café, a green
## café (not the real chain's shade), the crêpe place's warm yellow.
const KOSZTA_TUBE := Color(0.95, 0.35, 0.3)
const WACZEK_TUBE := Color(1.0, 0.78, 0.1)
const NERWO_TUBE := Color(0.35, 1.0, 0.55)
const KUKLA_TUBE := Color(1.0, 0.85, 0.35)
const KROWA_TUBE := Color(0.62, 0.86, 1.0)
const MIESZANE_TUBE := Color(1.0, 0.45, 0.12)
## DALEJ DALLA GELATO, the Powiśle ice-cream parlour with the all-year queue: pistachio mint.
const DALEJ_TUBE := Color(0.55, 1.0, 0.8)
## KRINGULA PIZZA, the hyped pizzeria (a parody; F's ideas #6): a tomato red.
const KRINGULA_TUBE := Color(1.0, 0.3, 0.22)
## DŻEMINI KEBAB (F, 2026-11-06): the kebab an AI agent carves, in the agent's blue-violet.
const DZEMINI_TUBE := Color(0.45, 0.55, 1.0)
## The cinemas' marquee tubes: amber, a deep red and a cool white-blue, so a street of them is not one colour.
const CINEMA_TUBE := Color(1.0, 0.72, 0.25)
const CINEMA_TUBE_B := Color(1.0, 0.25, 0.3)
const CINEMA_TUBE_C := Color(0.75, 0.88, 1.0)
## Nowy Świat's shopfront tubes (F's street-by-street pass, 2026-11-02): warm, soft shades, a café street.
const NOWY_CREAM := Color(1.0, 0.82, 0.5)
const NOWY_ROSE := Color(1.0, 0.55, 0.7)
const NOWY_SKY := Color(0.62, 0.86, 1.0)
const NOWY_WINE := Color(0.95, 0.3, 0.45)
## Powiśle's small shops: a leaf green, a brick orange and a soft lilac.
const POWISLE_TUBE_A := Color(0.5, 0.95, 0.55)
const POWISLE_TUBE_B := Color(1.0, 0.55, 0.3)
const POWISLE_TUBE_C := Color(0.8, 0.62, 1.0)
## Marszałkowska's shopfront tubes (pass 4, 2026-11-02): the old high street, sodium orange and PRL green.
const MARSZ_ORANGE := Color(1.0, 0.62, 0.2)
const MARSZ_GREEN := Color(0.4, 1.0, 0.55)
const MARSZ_BLUE := Color(0.5, 0.75, 1.0)
## Krakowskie Przedmieście's shopfront tubes (street-by-street pass, 2026-11-02): the royal route, candle gold and burgundy.
const KP_GOLD := Color(1.0, 0.8, 0.4)
const KP_WINE := Color(0.9, 0.35, 0.5)
const KP_BLUE := Color(0.6, 0.8, 1.0)
## Nowogrodzka's bar strip (street-by-street, 2026-11-03): between Marszałkowska and Bracka, the
## street of small bars and shot bars; late-night amber, magenta and teal so a row of them reads at night.
const NOWO_AMBER := Color(1.0, 0.7, 0.2)
const NOWO_MAGENTA := Color(1.0, 0.25, 0.7)
const NOWO_TEAL := Color(0.2, 0.95, 0.85)
## The venues' fascias (vision 3.0-3.2): place id -> [the lines of the sign, tube colour, metres
## up (the sign's bottom)]. The words are the parody names of places.json (Glon na Powiślu: GLON).
const VENUES := {
	"lusterko": [["LUSTERKO"], Color(1.0, 1.0, 1.0), 3.0],
	"smola": [["SMOŁA"], Color(1.0, 0.1, 0.55), 3.0],
	"jasna_0": [["JASNA 0"], Color(0.1, 0.9, 1.0), 3.0],
	"level_26": [["LEVEL 26"], Color(0.62, 0.25, 1.0), 3.2],
	"lombard": [["LOMBARD"], Color(1.0, 0.72, 0.12), 3.0],
	"milosc_hipoteczna": [["MIŁOŚĆ", "HIPOTECZNA"], Color(1.0, 0.1, 0.55), 3.0],
	"m2_1499": [["1499 M2"], Color(1.0, 1.0, 1.0), 3.2],
	"hocki_bloki": [["HOCKI BLOKI"], Color(1.0, 0.85, 0.35), 2.6],
	"plan_c": [["PLAN C"], Color(0.1, 0.9, 1.0), 3.0],
	"apteczka": [["APTECZKA"], Color(0.2, 1.0, 0.45), 2.8],
	"przegryzki_zagryzki": [["PRZEGRYZKI", "ZAGRYZKI"], Color(1.0, 0.1, 0.55), 3.0],
	"kasa_biletowa": [["KASA", "BILETOWA"], Color(0.85, 0.95, 1.0), 3.0],
	"zwir": [["ŻWIR"], Color(0.1, 0.9, 1.0), 6.5],
	"bar_pyzowy": [["BAR PYZOWY"], Color(1.0, 0.85, 0.35), 3.0],
	"lukrownia": [["LUKROWNIA"], Color(1.0, 0.45, 0.8), 3.0],
	"glon_mokotowska": [["GLON"], Color(0.2, 1.0, 0.45), 3.0],
	"glon_dobra": [["GLON"], Color(0.2, 1.0, 0.45), 3.0],
	"merdak": [["MERDAK"], Color(0.62, 0.25, 1.0), 3.0],
	"coffeechair_foksal": [["COFFEE", "CHAIR"], CAFE_TUBE, 2.8],
	"coffeechair_chmielna": [["COFFEE", "CHAIR"], CAFE_TUBE, 2.8],
	"coffeechair_krakowskie": [["COFFEE", "CHAIR"], CAFE_TUBE, 2.8],
	"coffeechair_trzech_krzyzy": [["COFFEE", "CHAIR"], CAFE_TUBE, 2.8],
	"coffeechair_hoza": [["COFFEE", "CHAIR"], CAFE_TUBE, 2.8],
	"shisha_dymek": [["DYMEK"], SHISHA_TUBE, 2.8],
	"shisha_opar": [["OPAR"], SHISHA_TUBE_B, 2.8],
	"shisha_chmurka": [["CHMURKA"], SHISHA_TUBE, 2.8],
	"shisha_mgielka": [["MGIEŁKA"], SHISHA_TUBE_B, 2.8],
	"shisha_zaduch": [["ZADYM"], SHISHA_TUBE, 2.8],
	"trend_macza": [["MACZA"], Color(0.45, 1.0, 0.4), 2.8],
	"trend_pistacja": [["PISTACJA", "DO KOŃCA"], Color(0.7, 1.0, 0.35), 2.8],
	"trend_zebus": [["ZĘBUŚ"], Color(1.0, 0.45, 0.8), 2.8],
	"trend_padelnia": [["PADELNIA"], Color(0.1, 0.9, 1.0), 2.8],
	"trend_kwasne_wino": [["KWAŚNE", "WINO"], Color(1.0, 0.1, 0.4), 2.8],
	"trend_nie_tutaj": [["NIE", "TUTAJ"], Color(1.0, 1.0, 1.0), 2.6],
	"trend_popup": [["POP-UP", "DO PIĄTKU"], Color(1.0, 0.85, 0.35), 2.8],
	"trend_rozgniot": [["ROZGNIOT"], Color(1.0, 0.55, 0.15), 2.8],
	# Rondo de Gaulle'a and the food hype (docs/design/gaulle-and-food-hype.md G2-G4).
	"bar_newtwice": [["NEWTWICE"], Color(1.0, 1.0, 1.0), 3.0],
	"bar_zamet": [["ZAMĘT"], Color(1.0, 0.72, 0.12), 3.0],
	"bar_przegrywki": [["PRZEGRYWKI"], Color(0.1, 0.9, 1.0), 2.8],
	"hotel_piure": [["HOTEL", "PIURE"], Color(1.0, 0.62, 0.84), 3.2],
	"koszta_marszalkowska": [["KOSZTA", "COFFEE"], KOSZTA_TUBE, 2.8],
	"koszta_krolewska": [["KOSZTA", "COFFEE"], KOSZTA_TUBE, 2.8],
	"koszta_krucza": [["KOSZTA", "COFFEE"], KOSZTA_TUBE, 2.8],
	"nerwo_pawilon": [["GREEN CAFFE", "NERWO"], NERWO_TUBE, 2.8],
	"nerwo_nowy_swiat": [["GREEN CAFFE", "NERWO"], NERWO_TUBE, 2.8],
	"kukla_marszalkowska": [["KUKŁA", "NALEŚNIKI"], KUKLA_TUBE, 2.8],
	"kukla_nowy_swiat": [["KUKŁA", "NALEŚNIKI"], KUKLA_TUBE, 2.8],
	# F (2026-11-01): the burger chain Warsaw calls "Maczek", ours WACZEK, its golden arches turned
	# upside down (a W over the name), at the real chain's central restaurants.
	"waczek_jp2": [["W", "WACZEK"], WACZEK_TUBE, 3.0],
	"waczek_marszalkowska": [["W", "WACZEK"], WACZEK_TUBE, 3.0],
	"waczek_swietokrzyska": [["W", "WACZEK"], WACZEK_TUBE, 3.0],
	"waczek_plater": [["W", "WACZEK"], WACZEK_TUBE, 3.0],
	"waczek_femina": [["W", "WACZEK"], WACZEK_TUBE, 3.0],
	# The milk bar in Norblin (F, 2026-11-01): a bar mleczny rebuilt as a start-up, cream and blue.
	"krowa_norblin": [["BAR MLECZNY", "KROWA 2.0"], KROWA_TUBE, 2.8],
	# F (2026-11-02): the kebab shop whose order is "mieszane" (mixed meat) and then "mieszane" (mixed
	# sauce), beside the Zagłębie Kebabowe (docs/design/city-life-satire.md #11).
	"kebab_mieszane": [["MIESZANE", "MIESZANE"], MIESZANE_TUBE, 2.8],
	# The Powiśle gelateria (F, 2026-11-01): Poles queue for lody in winter too.
	"dalej_gelato": [["DALEJ DALLA", "GELATO LODY"], DALEJ_TUBE, 2.8],
	# F's ideas #6 (2026-11-02): the pizzeria everyone queues and cries for; the sign is final, the joke is not.
	"kringula_pizza": [["KRINGULA", "PIZZA"], KRINGULA_TUBE, 3.0],
	# F (2026-11-06): the new kebab whose meat an AI agent carves; Mrożulo's MLASK makes it the
	# city's longest queue (trend_job.gd "Dżemini", crowds.gd DZEMINI_ID).
	"dzemini_kebab": [["DŻEMINI", "KEBAB 24H"], DZEMINI_TUBE, 2.8],
	# Warsaw's classic and arthouse cinemas (F, 2026-11-02): the real independent halls under their
	# own names (place names, not brands; the multiplex chains stay out), amber marquee tubes.
	"kino_atlantic": [["KINO", "ATLANTIC"], CINEMA_TUBE_B, 3.2],
	"kino_luna": [["KINO", "LUNA"], CINEMA_TUBE_C, 3.2],
	"kino_kultura": [["KINO", "KULTURA"], CINEMA_TUBE, 3.2],
	"kino_elektronik": [["KINO", "ELEKTRONIK"], CINEMA_TUBE_B, 3.2],
	# Powiśle's streets (F, 2026-11-02): the small shops of a student and cyclist quarter, original
	# names, one tube each, low over the door.
	"pow_flat_bialy": [["FLAT", "BIAŁY"], CAFE_TUBE, 2.8],
	"pow_rowerownia": [["ROWEROWNIA", "SERWIS"], POWISLE_TUBE_A, 2.8],
	"pow_winyle": [["WINYLE", "NA SKARPIE"], POWISLE_TUBE_B, 2.8],
	"pow_ksiegarnia": [["KSIĘGARNIA", "POD SYRENKĄ"], POWISLE_TUBE_C, 2.8],
	"pow_bar_topiel": [["BAR", "TOPIEL"], POWISLE_TUBE_A, 2.8],
	"pow_piekarnia": [["PIEKARNIA", "NA POWIŚLU"], CAFE_TUBE, 2.8],
	"pow_altana": [["ALTANA"], POWISLE_TUBE_B, 2.8],
	"pow_przy_solcu": [["PRZY SOLCU"], POWISLE_TUBE_C, 2.8],
	# Zagłębie Kebabowe on Al. Solidarności (zaglebie.gd): Kino Femina's fascia and the five shops'.
	# Nowy Świat's shopfronts (street-by-street pass, 2026-11-02): original names, no chains.
	# Nowogrodzka's bars (street-by-street, 2026-11-03): parodies of the real bars' names or trades,
	# never the names themselves.
	"nowo_kwarta": [["KWARTA"], NOWO_AMBER, 2.8],
	"nowo_halinka": [["U HALINKI", "BAR"], NOWO_MAGENTA, 2.8],
	"nowo_za_bardzo": [["ZA BARDZO"], NOWO_TEAL, 3.0],
	"nowo_kraftownia": [["KRAFTOWNIA", "IPA DO DNA"], NOWO_AMBER, 2.8],
	"nowo_schron": [["SCHRON", "PIWNY"], NOWO_TEAL, 2.8],
	"nowo_podworko": [["PODWÓRKO 22", "SZOTY"], NOWO_MAGENTA, 3.0],
	"nowo_nalewalnia": [["NALEWALNIA", "KIEDYŚ PO 4"], NOWO_AMBER, 2.8],
	"nowo_dziniarnia": [["DŻINIARNIA"], NOWO_TEAL, 2.8],
	# Mazowiecka's club street (street-by-street, 2026-11-03): parodies of the real clubs' names or
	# trades, one sign per address (Tygmont and La Pose share no. 6/8, Enklawa and Ritual no. 12).
	"maz_tygrys": [["TYGRYS", "JAZZ"], NOWO_AMBER, 2.8],
	"maz_szotownia": [["SZOTOWNIA"], NOWO_MAGENTA, 2.8],
	"maz_szkic": [["SZKIC", "NOCĄ"], NOWO_TEAL, 2.8],
	"maz_enklawka": [["ENKLAWKA"], NOWO_MAGENTA, 3.0],
	"maz_pokoj": [["POKÓJ 12,5"], NOWO_AMBER, 2.8],
	# Wilcza and Poznańska's bar strip (street-by-street, 2026-11-03): parodies of the real bars' names or
	# trades, never the names themselves (a muse, a cigar room, a gold-rush pub, an aura, a
	# kraken, a video tape, a banana republic).
	"wil_muza": [["MUZA", "NA BIS"], NOWO_AMBER, 2.8],
	"wil_cygarnia": [["CYGARNIA", "DYMEK"], NOWO_MAGENTA, 2.8],
	"wil_goraczka": [["GORĄCZKA", "PIĄTKOWA"], NOWO_TEAL, 2.8],
	"wil_aura": [["AURA", "PO PRACY"], NOWO_MAGENTA, 2.8],
	"wil_macki": [["MACKI", "I KUFLE"], NOWO_TEAL, 2.8],
	"wil_kaseta": [["KASETA", "PRZEWIJANA"], NOWO_AMBER, 2.8],
	"wil_banany": [["REPUBLIKA", "BANANOWA"], NOWO_MAGENTA, 3.0],
	# Praga's old streets (street-by-street, 2026-11-03): parodies of the real bars' trades near Okrzei,
	# Wrzesińska, Kijowska and Targowa; pre-war tenements, so warm amber and teal over the plaster.
	"praga_swiat": [["ŚWIAT", "PO PRASKU"], NOWO_AMBER, 2.8],
	"praga_barista": [["BARISTA", "Z PODWÓRKA"], NOWO_TEAL, 2.8],
	"praga_skrzynka": [["WINO ZE", "SKRZYNKI"], NOWO_MAGENTA, 2.8],
	"praga_kraina": [["KRAINA", "WINA"], NOWO_AMBER, 2.8],
	"praga_kijowska": [["KIJOWSKA", "DWÓJKA"], NOWO_MAGENTA, 2.8],
	"praga_kufel": [["POD KUFLEM", "ZA ROGIEM"], NOWO_TEAL, 2.8],
	# The Powiśle viaduct's closed bays (F, 2026-11-03: "a lot of gastronomy, the K-bar and others"):
	# parody names over the bays' arched doors (map_builder PV_BARS); a nod to the real bars, not them.
	"via_qbar": [["Q-BAR POD", "WIADUKTEM"], NOWO_TEAL, 3.7],
	"via_luk": [["WINO", "POD ŁUKIEM"], NOWY_WINE, 3.7],
	"via_nity": [["NITY", "I KUFLE"], NOWO_AMBER, 3.7],
	"via_beton": [["BETONIARNIA", "BISTRO"], NOWY_CREAM, 3.7],
	"via_filar": [["KAWA", "PRZY FILARZE"], NOWO_MAGENTA, 3.7],
	"nowy_paczki": [["PĄCZKARNIA", "TŁUSTE DNI"], NOWY_ROSE, 2.8],
	"nowy_lody": [["LODY", "BEZ KOLEJKI"], NOWY_SKY, 2.8],
	"nowy_ksiegarnia": [["KSIĘGARNIA", "PRZY KAWIE"], NOWY_CREAM, 2.8],
	"nowy_antykwariat": [["ANTYKWARIAT", "MA CENĘ"], NOWY_CREAM, 2.8],
	"nowy_butik": [["BUTIK", "ZOFIA"], NOWY_ROSE, 2.8],
	"nowy_winiarnia": [["WINIARNIA", "POD GRUSZĄ"], NOWY_WINE, 2.8],
	"nowy_galeria": [["GALERIA", "NIEPOJĘTA"], Color(1.0, 1.0, 1.0), 2.8],
	"nowy_kantor": [["KANTOR", "DOBRY KURS"], Color(0.2, 1.0, 0.45), 2.8],
	# N2 (2026-11-02): the old confectioner's near no. 35 (a parody of the famous one, no real name)
	# and the mouths of Chmielna and Foksal.
	"nowy_cukiernia": [["BLIKLINA", "OD 1869"], NOWY_ROSE, 2.8],
	"nowy_chmielna": [["CHMIELNA", "KAWA TUTAJ"], NOWY_CREAM, 2.8],
	"nowy_foksal": [["FOKSAL", "PRZY WINYLU"], NOWY_SKY, 2.8],
	# Marszałkowska's shopfronts (street-by-street pass 4, 2026-11-02): old-fashioned trades, original names.
	"marsz_bar": [["BAR MLECZNY", "KOTLET DNIA"], MARSZ_GREEN, 2.8],
	"marsz_pralnia": [["PRALNIA", "CHEMICZNA"], MARSZ_BLUE, 2.8],
	"marsz_zegarmistrz": [["ZEGARMISTRZ", "OD 1912"], MARSZ_ORANGE, 2.8],
	"marsz_cukiernia": [["CUKIERNIA", "SMAK PRL"], NOWY_ROSE, 2.8],
	"marsz_optyk": [["OPTYK", "DOBRY WZROK"], MARSZ_BLUE, 2.8],
	"marsz_kwiaciarnia": [["KWIACIARNIA", "PRZY TORACH"], MARSZ_GREEN, 2.8],
	"marsz_pasmanteria": [["PASMANTERIA", "GUZIK"], MARSZ_ORANGE, 2.8],
	# Krakowskie Przedmieście's shopfronts (street-by-street pass, 2026-11-02): the royal route's trades, original names.
	"kp_bursztyn": [["BURSZTYN", "I SREBRO"], KP_GOLD, 2.8],
	"kp_apteka": [["APTEKA", "POD KOLUMNĄ"], Color(0.2, 1.0, 0.45), 2.8],
	"kp_lody": [["LODY", "KRÓLEWSKIE"], KP_BLUE, 2.8],
	"kp_nuty": [["NUTY", "I PŁYTY"], KP_WINE, 2.8],
	"kp_czytelnia": [["CZYTELNIA", "KAWA I KSIĘGI"], KP_GOLD, 2.8],
	"kp_pierogi": [["PIEROGI", "U BONY"], KP_WINE, 2.8],
	"kp_pamiatki": [["PAMIĄTKI", "Z SYRENKĄ"], KP_BLUE, 2.8],
	"kp_kantor": [["KANTOR", "ZAMKOWY"], Color(0.2, 1.0, 0.45), 2.8],
	"marsz_zielarnia": [["ZIELARNIA", "NA WSZYSTKO"], MARSZ_GREEN, 2.8],
	# Plac Zbawiciela's four (F's street-by-street, 2026-11-02): the terraces' own names.
	"zb_zbawienie": [["KAWA", "ZBAWIENIE"], CAFE_TUBE, 2.8],
	"zb_szarlotka": [["SZARLOTKA", "NA ROGU"], Color(1.0, 0.62, 0.3), 2.8],
	"zb_plan_z": [["PLAN Z", "BAR NA PLACU"], Color(0.1, 0.9, 1.0), 2.8],
	"zb_po_mszy": [["PO MSZY", "SPRITZ"], Color(1.0, 0.45, 0.75), 2.8],
	"zag_femina": [["KINO", "FEMINA"], Color(1.0, 0.3, 0.35), 4.6],
	"zag_krol": [["KEBAB KRÓL", "MAZOWSZA"], Color(1.0, 0.72, 0.12), 2.8],
	"zag_stambul": [["STAMBUŁ 24"], Color(0.1, 0.9, 1.0), 2.8],
	"zag_pasza": [["DONER", "PASZA"], Color(1.0, 0.1, 0.4), 2.8],
	"zag_erdal": [["U WUJKA", "ERDALA"], Color(0.2, 1.0, 0.45), 2.8],
	"zag_rozen": [["ZAKWAS", "I ROŻEN", "CRAFT KEBAB"], Color(1.0, 0.85, 0.35), 2.8],
}
## COFFEECHAIR (BACKLOG, the user 2026-10-31): a parody of a real coffee-shop chain, our own name
## and a warm cream tube (no logo, no chair icon of anyone's). Small cafés that are not notebook
## places: id -> [lat, lon] in Śródmieście; their signs ride the venue code (venue_list).
const CAFES := {
	"coffeechair_foksal": [52.2330, 21.0200],
	"coffeechair_chmielna": [52.2312, 21.0170],
	"coffeechair_krakowskie": [52.2398, 21.0158],
	"coffeechair_trzech_krzyzy": [52.2201, 21.0243],
	"coffeechair_hoza": [52.2208, 21.0185],
}
## Shisha lounges (BACKLOG): original names (smoke, haze, cloud), violet or teal neon that glows
## at night, in Śródmieście side streets. Like the cafés, not notebook places; same venue code.
const LOUNGES := {
	"shisha_dymek": [52.2350, 21.0172],
	"shisha_opar": [52.2271, 21.0148],
	"shisha_chmurka": [52.2262, 21.0212],
	"shisha_mgielka": [52.2342, 21.0107],
	"shisha_zaduch": [52.2241, 21.0236],
}
## 2025-26 trend spots (docs/design/trends-2025-26.md): matcha, the pistachio-chocolate queue, the
## fanged plush, padel, natural wine, the secret bar, the pop-up, the smash burger. Original names,
## in Śródmieście side streets; like the cafés, not notebook places, same venue code.
const TRENDY := {
	"trend_macza": [52.2318, 21.0125],
	"trend_pistacja": [52.2287, 21.0189],
	"trend_zebus": [52.2362, 21.0140],
	"trend_padelnia": [52.2255, 21.0260],
	"trend_kwasne_wino": [52.2344, 21.0210],
	"trend_nie_tutaj": [52.2379, 21.0190],
	"trend_popup": [52.2296, 21.0137],
	"trend_rozgniot": [52.2270, 21.0235],
}
## Rondo de Gaulle'a and the food hype (docs/design/gaulle-and-food-hype.md G2-G4): the Party
## House's bars (NEWTWICE on its south front, ZAMĘT on its north-west corner, PRZEGRYWKI the board-game
## bar on the next block), HOTEL PIURE's door on Widok (its rooftop bar LORETKA is landmarks.gd's
## crown sign), the coffee chains' parodies (KOSZTA COFFEE, GREEN CAFFE NERWO: one on the mapped
## pavilion) and KUKŁA, the crêpe place with the queue (crowds.gd `KUKLA`). Like the cafés, not
## notebook places; same venue code.
const HYPE := {
	"bar_newtwice": [52.23065, 21.02253],
	"bar_zamet": [52.23140, 21.02195],
	"bar_przegrywki": [52.23045, 21.02205],
	"hotel_piure": [52.23102, 21.01510],
	"koszta_marszalkowska": [52.2305, 21.0110],
	"koszta_krolewska": [52.2370, 21.0165],
	"koszta_krucza": [52.2265, 21.0175],
	"nerwo_pawilon": [52.23313, 21.01307],
	"nerwo_nowy_swiat": [52.2355, 21.0185],
	"kukla_marszalkowska": [52.2375, 21.0110],
	"kukla_nowy_swiat": [52.2320, 21.0198],
	# WACZEK at the real chain's restaurants (their names on Wolt, 2026-11-01; corners approximate):
	# Aleje Jerozolimskie at Jana Pawła II, Marszałkowska by metro Świętokrzyska, Świętokrzyska by Nowy Świat-Uniwersytet,
	# Aleje Jerozolimskie at Emilii Plater, Aleja Solidarności by the Femina cinema.
	"waczek_jp2": [52.2292, 20.9992],
	"waczek_marszalkowska": [52.2352, 21.0088],
	"waczek_swietokrzyska": [52.2364, 21.0160],
	"waczek_plater": [52.2281, 21.0047],
	"waczek_femina": [52.2424, 20.9980],
	# KROWA 2.0, the milk bar on the Żelazna front of Norblin (the block of "Plater", moved off
	# "Modsen" with the factory's model, 2026-11-02; the Mac look check parks the door).
	"krowa_norblin": [52.23246, 20.99205],
	# MIESZANE MIESZANE, 40 m west of KEBAB KRÓL on the south pavement of Al. Solidarności (the Mac look check parks the door).
	"kebab_mieszane": [52.24176, 20.99345],
	# DALEJ DALLA GELATO on Tamka at Powiśle (the Mac look check parks the door).
	"dalej_gelato": [52.237885, 21.027375],
	# KRINGULA PIZZA on Poznańska, the street of the new places (corner approximate; Mac look check parked).
	"kringula_pizza": [52.22725, 21.01575],
	# DŻEMINI KEBAB, new on the north side of Świętokrzyska, its front to the camera (an invented shop; the Mac look check parks the door).
	"dzemini_kebab": [52.23595, 21.0105],
}
## Warsaw's classic and arthouse cinemas (F, 2026-11-02; BACKLOG "Lore: coffee raves and arthouse
## cinemas"): (Kino Muranów's letters are its landmark model's since 2026-11-07, landmarks.gd) Atlantic (Chmielna 33), Luna (Marszałkowska 28), Kultura
## (Krakowskie Przedmieście 21/23) and Elektronik (Czerwonego Krzyża 3/5). The Kinoteka's sign is the
## Palace's own (landmarks.gd PKIN_SIGNS, 2026-11-07: this table put it 130 m west, across Emilii
## Plater). (Kino Femina's fascia is zaglebie.gd's `zag_femina`). Like the cafés, not notebook places;
## same venue code, the nearest road snaps the sign. Iluzjon (Narbutta, Mokotów) is south of the map.
const CINEMAS := {
	"kino_atlantic": [52.23158, 21.01253],
	"kino_luna": [52.22830, 21.01360],
	"kino_kultura": [52.24060, 21.01680],
	"kino_elektronik": [52.23480, 21.02900],
}
## Powiśle's streets (F, 2026-11-02; BACKLOG "Powiśle streets"): a cafe on Tamka, a bike workshop and
## a bakery on Dobra, a record shop and a bookshop towards the Library, a bar on Topiel, a stairwell
## bar on Browarna and a corner shop on Solec. Original names; like the cafés, not notebook places,
## same venue code, the nearest road snaps the sign (the Mac look check moves the doors). Spots sit on the baked Tamka, Dobra, Browarna, Topiel and Solec.
const POWISLE := {
	"pow_flat_bialy": [52.23719, 21.02554],
	"pow_rowerownia": [52.23953, 21.02693],
	"pow_winyle": [52.24085, 21.02231],
	"pow_ksiegarnia": [52.23654, 21.02192],
	"pow_bar_topiel": [52.23878, 21.02489],
	"pow_piekarnia": [52.23780, 21.02893],
	"pow_altana": [52.24161, 21.02179],
	"pow_przy_solcu": [52.23463, 21.03380],
}
## Zagłębie Kebabowe's venue anchors: id -> [lat, lon] (Femina and the five shops' doors).
static func zaglebie_table() -> Dictionary:
	var t := {Zaglebie.FEMINA_ID: Zaglebie.FEMINA}
	for sh: Dictionary in Zaglebie.SHOPS:
		t[sh["id"]] = sh["ll"]
	return t


## Nowy Świat's shopfronts (F's street-by-street pass, 2026-11-02; docs/design/nowy-swiat.md):
## eleven small shops (N2 added three) on the café street between the Palm and Karowa, alternating sides, ~60 m
## apart, placed from the road line (the Mac look check moves them to real doors). Like the cafés,
## not notebook places; same venue code, the nearest road snaps each sign to a wall in reach.
const NOWY_SWIAT := {
	"nowy_paczki": [52.23246, 21.02019],
	"nowy_lody": [52.23296, 21.01953],
	"nowy_ksiegarnia": [52.23346, 21.01948],
	"nowy_antykwariat": [52.23424, 21.01879],
	"nowy_winiarnia": [52.23477, 21.01884],
	"nowy_butik": [52.23585, 21.01816],
	"nowy_galeria": [52.23622, 21.01831],
	"nowy_kantor": [52.23707, 21.01777],
	"nowy_cukiernia": [52.23377, 21.01911],
	"nowy_chmielna": [52.23318, 21.01951],
	"nowy_foksal": [52.23532, 21.01851],
}
## Marszałkowska's shopfronts (F's street-by-street pass 4, 2026-11-02): eight old-fashioned trades
## (milk bar, dry cleaner, watchmaker, pastry shop, optician, florist, haberdashery, herbalist) at
## the mapped house numbers 140, 124, 85, 83, 62, 58, 53 and 43, both sides, plac Bankowy to plac
## Zbawiciela. Like the cafés, not notebook places; the nearest address snaps each sign to a wall.
const MARSZALKOWSKA := {
	"marsz_bar": [52.23717, 21.00795],
	"marsz_pralnia": [52.23409, 21.01003],
	"marsz_zegarmistrz": [52.22656, 21.01309],
	"marsz_cukiernia": [52.22573, 21.01358],
	"marsz_optyk": [52.22433, 21.01568],
	"marsz_kwiaciarnia": [52.22392, 21.01590],
	"marsz_pasmanteria": [52.22317, 21.01497],
	"marsz_zielarnia": [52.22039, 21.01706],
}
## Krakowskie Przedmieście's shopfronts (F's street-by-street pass, 2026-11-02): eight trades on the
## royal route (amber, chemist, ice cream, sheet music, reading cafe, pierogi, souvenirs, exchange
## office) at the mapped house numbers 20/22, 19, 27, 56, 45, 58/60, 64 and 69, both sides, from Nowy
## Świat's top to the Castle. Like the cafés, not notebook places; the nearest address snaps each sign.
const KRAKOWSKIE := {
	"kp_bursztyn": [52.23930, 21.01761],
	"kp_apteka": [52.24322, 21.01426],
	"kp_lody": [52.24391, 21.01395],
	"kp_nuty": [52.24402, 21.01543],
	"kp_czytelnia": [52.24461, 21.01369],
	"kp_pierogi": [52.24442, 21.01512],
	"kp_pamiatki": [52.24547, 21.01448],
	"kp_kantor": [52.24575, 21.01334],
}
## Plac Zbawiciela's cafés (F's street-by-street, 2026-11-02): the roundabout's blocks carry four
## terraces (tools/bake_street_details.py TERRACES): KAWA ZBAWIENIE (coffee as salvation), SZARLOTKA
## NA ROGU (the apple-pie bakery on the corner), PLAN Z (the bar with the plan after the plan) and
## PO MSZY SPRITZ (the one for after the service). Like the cafés, not notebook places.
const ZBAWICIELA := {
	"zb_zbawienie": [52.21957, 21.01848],
	"zb_szarlotka": [52.21971, 21.01863],
	"zb_plan_z": [52.22013, 21.01848],
	"zb_po_mszy": [52.21967, 21.01722],
}
## Nowogrodzka's bars (street-by-street, 2026-11-03): eight parody fascias at the OpenStreetMap
## points of the real bars on the strip between Marszałkowska and Bracka (house numbers 4, 10, 11,
## 12, 20, 22, 27 and 31): a pint-and-quart pub, a bar run by Halinka, ZA BARDZO (one notch past
## "very very"), a craft-beer tap room, a cellar bar, the courtyard of shot bars at no. 22, the
## everything-at-one-price vodka bar (KIEDYŚ PO 4: it was 4 zł once) and a gin bar. Like the cafés, not notebook
## places; the nearest address snaps each sign to a wall. ZA BARDZO and PODWÓRKO 22 hang at their
## yards' gates on the street (OSM has the bars 60-70 m in, in the courtyards of nos. 11 and 22).
const NOWOGRODZKA := {
	"nowo_kwarta": [52.23017, 21.01838],
	"nowo_halinka": [52.22980, 21.01661],
	"nowo_za_bardzo": [52.22988, 21.01780],
	"nowo_kraftownia": [52.22966, 21.01590],
	"nowo_schron": [52.22941, 21.01470],
	"nowo_podworko": [52.22921, 21.01404],
	"nowo_nalewalnia": [52.22906, 21.01406],
	"nowo_dziniarnia": [52.22894, 21.01362],
}
## Mazowiecka's clubs (street-by-street, 2026-11-03): five parody fascias at the OpenStreetMap points
## of the real clubs (Tygmont, Czupito/Mazo, Sketch Nite, Enklawa/Ritual, Room 13); the nearest address
## snaps each sign to a wall. Bank Club and Blu Club (no. 14) are Lombard's, places.json.
const MAZOWIECKA := {
	"maz_tygrys": [52.236993, 21.013325],
	"maz_szotownia": [52.237075, 21.013000],
	"maz_szkic": [52.237760, 21.012753],
	"maz_enklawka": [52.237787, 21.013159],
	"maz_pokoj": [52.237889, 21.012811],
}
## Wilcza and Poznańska's bars (street-by-street, 2026-11-03): seven parody fascias at the OpenStreetMap
## points of the real bars on Wilcza (nos. 17, 26, 27/29 as one door, 51A), Hoża 27 and Poznańska (7, 12); the nearest
## address snaps each sign to a wall.
const WILCZA := {
	"wil_muza": [52.22540, 21.01868],
	"wil_cygarnia": [52.22537, 21.01739],
	"wil_goraczka": [52.22494, 21.01645],
	"wil_aura": [52.22652, 21.01596],
	"wil_macki": [52.22472, 21.01228],
	"wil_kaseta": [52.22391, 21.01234],
	"wil_banany": [52.22403, 21.01218],
}
## Praga's bars (street-by-street, 2026-11-03): six parody fascias at the OpenStreetMap points of the real bars
## on Stefana Okrzei (nos. 8 and 26, where two bars share one door), Sierakowskiego 4A, Wrzesińska 4,
## Kijowska 2 and Targowa 1. Ząbkowska's own bars lie outside the map (z < -2045).
const PRAGA := {
	"praga_swiat": [52.2510661, 21.0352787],
	"praga_barista": [52.2489048, 21.0314672],
	"praga_skrzynka": [52.249572, 21.0333065],
	"praga_kraina": [52.249752, 21.0352705],
	"praga_kijowska": [52.2498793, 21.0443072],
	"praga_kufel": [52.2480169, 21.0455613],
}
## The Powiśle viaduct's bars (F, 2026-11-03): the closed bays map_builder.gd builds (PV_INFILL, PV_BARS)
## under Most Poniatowskiego's deck between Kruczkowskiego and Solec, facing Al. 3 Maja. Game coordinates,
## not lat/lon: id -> [a point 5 m out of the arcade's face, one 4 m in behind the bay's wall], taken from
## the viaduct's frame (`_powisle_frame` at the bay's middle s); the sign's ray runs from the first to the
## second and meets the bay's wall (solid). The deck over it is not in the roof grid: no roof test.
const VIADUKT := {
	"via_qbar": [Vector2(536.5, -23.9), Vector2(539.3, -15.4)],
	"via_luk": [Vector2(587.8, -40.9), Vector2(590.6, -32.3)],
	"via_nity": [Vector2(530.1, 14.5), Vector2(527.3, 5.9)],
	"via_beton": [Vector2(564.2, 3.1), Vector2(561.4, -5.5)],
	"via_filar": [Vector2(615.5, -14.0), Vector2(612.7, -22.6)],
}
## A venue sign's letter pixel (m) and the smallest it shrinks to on a short wall.
const VENUE_PX := 0.12
const VENUE_PX_MIN := 0.08
const KNOCK_R := 1.2
const KNOCK_GAP := 60.0
const LEZAK_CELL := 16.0
## Loop jobs-2: the payphone's place (E40) and how far from its point it may stand (m).
const PHONE_PLACE := "plac_konstytucji"
const PHONE_REACH := 70.0
## The named kebab stands (6.1): place id -> [the board's words, the vendor's tag]; other tags by
## the stand's nearest place.
const NAMED_STANDS := {"u_zdzicha": ["U ZDZICHA", "zdzich"], "na_cienkim": ["NA CIENKIM", "cienkim"]}
const STAND_TAGS := {"hala_mirowska": "hala", "hala_gwardii": "hala", "hala_koszyki": "hala", "stadion_narodowy": "stadium"}
const STAND_TAG_REACH := 220.0
## The four new billboards (6.2): the line's first word -> the place they stand by, the colours.
const BILLBOARDS := {"FROGS": ["swietokrzyska_metro", "#4fae3b", "#fbf7ee"], "PODWÓZKA": ["dworzec_centralny", "#1f1f22", "#e8f4ff"],
		"PĘDZIK": ["hala_mirowska", "#c23a7e", "#fbf7ee"], "LEŻAK": ["nowy_swiat_uniwersytet", "#8e44d9", "#fbf7ee"],
		"WIRALEK": ["wiralek_chmielna", "#1c1f26", "#ff7ac8"],
		"KLATKA": ["hala_mirowska", "#1d3b5c", "#fbf7ee"], "METRAŻ": ["swietokrzyska_metro", "#f4f1ea", "#1d3b5c"],
		"KREDYT": ["dworzec_centralny", "#c8282a", "#fbf7ee"]}

var map: Node3D
var graph  # LaneGraph
var dialogue: Node
var hud: CanvasLayer
var wallet: Node
var sfx: Node
var egg_book: Node
var jobs: Node
var eggs: Node
var car: Node3D
## [position, km/h, flying] of the player's vehicle.
var vehicle: Callable
## Whether the night lights are on, and whether the fine detail is shown (main.gd's state).
var lit: Callable
var fine_shown: Callable
var log_on := false
## --rechotka: put the car by the nearest Frogs door once its sector has placed it.
var rig_rechotka := false
var spent_usec := 0

## Frogs: {road: Vector2 (the road point at the door), bld: Vector2 (the building's point),
## j: Vector2 (the junction), triple: place id or "", name, key: Vector2i, state: 0 waiting for its
## sector, 1 placed, 2 no wall; placed: xf (Transform3D on the wall), door: Vector2}.
var shops: Array[Dictionary] = []
## Venues: {id, lines, colour, up, road, bld, key, state, xfs: Array[Transform3D], off (m from the wall)}.
var venues: Array[Dictionary] = []
## Leżaks: {at: Vector3, yaw, up (standing), key, zone (index or -1)}.
var scooters: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var metros: Array[Dictionary] = []
## The city-bike docks (ROWERILO) from the bake's `bicycle_rental` pois: `at`, `yaw` along the row, `n` bikes.
var docks: Array[Dictionary] = []
## Loop jobs-2 (E40, vision 3.9 T17): the old card payphone at Plac Konstytucji {at: Vector3, yaw, key}
## ({} when the place or a pavement spot isn't found); in its sector's street-prop mesh.
var payphone := {}
## The triple corners' junctions: place id -> Vector2.
var triple_at := {}
var stamps := 0
var stamped_today := 0
var counts := {}

var _by_key := {}
var _roots := {}
## Frogs standing at each triple corner so far (three, then the spares stand down: state 3).
var _triple_placed := {}
var _pending: Array[Vector2i] = []
var _shop_mesh: ArrayMesh
var _lezak_mesh: ArrayMesh
var _atlas: ImageTexture
var _rows := 0
var _row_of := {}
var _upgraded := {}
var _neon_mat: ShaderMaterial
var _lezak_mmi := {}
var _lezak_grid := {}
var _door_grid := {}
var _t := 0.0
var _hold := 0.0
var _hold_shop := -1
var _line_t := -INF
var _knock_t := -INF
var _clock := 0.0
var _rig_done := false


# --- setup --------------------------------------------------------------------------------------

## Everything placed from the data once (the walls wait for their sectors). `places` is the
## notebook's resolved list.
func setup(data: Dictionary, places: Array) -> void:
	var t0 := Time.get_ticks_usec()
	var at := {}
	for p: Dictionary in places:
		at[str(p["id"])] = p
	var addrs := address_list(data.get("pois", []))
	var jpos := junctions(graph)
	for id: String in TRIPLES:
		if at.has(id):
			var tj := nearest_point(jpos, at[id]["at"], TRIPLE_REACH * 2.0)
			if tj != Vector2.INF:
				triple_at[id] = tj
	var avoid := PackedVector2Array()
	for p: Dictionary in data.get("pois", []):
		if str(p.get("k", "")) == "kebab":
			avoid.append(Vector2(float(p["x"]), float(p["z"])))
	var with_cafes: Array = places.duplicate()
	for table: Dictionary in [CAFES, LOUNGES, TRENDY, HYPE, CINEMAS, NOWY_SWIAT, POWISLE, MARSZALKOWSKA, KRAKOWSKIE, ZBAWICIELA, NOWOGRODZKA, MAZOWIECKA, WILCZA, PRAGA, zaglebie_table()]:
		for id: String in table:
			var ll: Array = table[id]
			with_cafes.append({"id": id, "at": Notebook.project(data.get("origin", [52.234, 21.024]), float(ll[0]), float(ll[1]))})
	for id: String in VIADUKT:
		with_cafes.append({"id": id, "at": VIADUKT[id][1], "road": VIADUKT[id][0], "bld": VIADUKT[id][1]})
	venues = venue_list(with_cafes, addrs, graph)
	for v in venues:
		avoid.append(v["road"])
	var polys := landmark_index(data.get("landmarks", []))
	shops = pick_shops(addrs, convenience_list(data.get("pois", [])), jpos, triple_at, polys, avoid)
	var nt := 0
	for s in shops:
		if s["triple"] != "" and not s["spare"]:
			nt += 1
	_load_scooters(data.get("pois", []))
	_load_metros(data.get("pois", []))
	_load_docks(data.get("pois", []))
	_pick_payphone(at)
	for i in shops.size():
		_add_to_key("shops", shops[i]["key"], i)
	for i in venues.size():
		_add_to_key("venues", venues[i]["key"], i)
	for i in scooters.size():
		_add_to_key("scooters", scooters[i]["key"], i)
	for i in zones.size():
		_add_to_key("zones", zones[i]["key"], i)
	for i in metros.size():
		_add_to_key("metros", metros[i]["key"], i)
	for i in docks.size():
		_add_to_key("docks", docks[i]["key"], i)
	if not payphone.is_empty() and not _by_key.has(payphone["key"]):
		_by_key[payphone["key"]] = {"shops": [], "venues": [], "scooters": [], "zones": [], "metros": [], "docks": []}
	_shop_mesh = Props.frogs_shop()
	_lezak_mesh = Props.lezak()
	_build_atlas()
	_kebab_boards(at)
	_billboards(at)
	_load_stamps()
	# The eggs where their things are: the first triple corner's junction, the standing Leżak's zone.
	if egg_book != null:
		if triple_at.has(TRIPLES[0]):
			egg_book.move_egg("easter_rechotka", triple_at[TRIPLES[0]])
		for z in zones:
			if z["standing"]:
				egg_book.move_egg("easter_lezak", Vector2(z["at"].x, z["at"].z))
		if not payphone.is_empty():
			egg_book.move_egg("e40", Vector2(payphone["at"].x, payphone["at"].z))
	counts = {"frogs": shops.size(), "triple": nt, "venues": venues.size(), "lezak": scooters.size(), "zones": zones.size(),
			"metro": metros.size(), "docks": docks.size()}
	print("storefronts: %d Frogs (%d on %d triple corners), %d venue signs, %d Leżaks, %d zones, %d metro entrances, in %.1f ms" % [
			shops.size(), nt, triple_at.size(), venues.size(), scooters.size(), zones.size(), metros.size(), (Time.get_ticks_usec() - t0) / 1000.0])
	# Sectors already in.
	var holder := map.get_node_or_null("Sectors") if map != null else null
	if holder != null:
		for r in holder.get_children():
			if r is Node3D and (r as Node3D).visible:
				on_sector_ready(r)


func _add_to_key(kind: String, key: Vector2i, i: int) -> void:
	if not _by_key.has(key):
		_by_key[key] = {"shops": [], "venues": [], "scooters": [], "zones": [], "metros": [], "docks": []}
	(_by_key[key][kind] as Array).append(i)


static func key_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


static func _pts(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(float(flat[i]), float(flat[i + 1])))
	return out


static func _hash(p: Vector2) -> float:
	return fposmod(sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453, 1.0)


# --- the pure parts (check_parodies.gd runs them) -------------------------------------------------

## The `address` pois: [{name, road (the road point at the door), bld (the building's point)}].
static func address_list(pois: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in pois:
		if str(p.get("k", "")) != "address" or not p.has("door"):
			continue
		var d: Array = p["door"]
		out.append({"name": str(p.get("name", "")), "road": Vector2(float(d[0]), float(d[1])), "bld": Vector2(float(p["x"]), float(p["z"]))})
	return out


## The `convenience` pois of the Frogs' chain (`fr`): [{name "", road (the road point at the door),
## bld (the shop), h (its shuffle key), triple "", spare false, real true}].
static func convenience_list(pois: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in pois:
		if str(p.get("k", "")) != "convenience" or int(p.get("fr", 0)) != 1 or not p.has("door"):
			continue
		var d: Array = p["door"]
		var r := Vector2(float(d[0]), float(d[1]))
		out.append({"name": "", "road": r, "bld": Vector2(float(p["x"]), float(p["z"])), "j": r, "triple": "", "h": _hash(r),
				"spare": false, "real": true})
	return out


## The lane graph's junctions: nodes with three or more ways, none on a bridge, deck or tunnel.
static func junctions(g) -> PackedVector2Array:
	var out := PackedVector2Array()
	if g == null:
		return out
	for n in g.node_pos.size():
		var other := {}
		var raised := false
		for e in g.node_out[n]:
			other[g.e_b[e]] = true
			raised = raised or g.e_bridge[e] == 1 or g.e_dk[e] >= 0 or g.e_tn[e] >= 0
		for e in g.node_in[n]:
			other[g.e_a[e]] = true
			raised = raised or g.e_bridge[e] == 1 or g.e_dk[e] >= 0 or g.e_tn[e] >= 0
		if other.size() >= 3 and not raised:
			out.append(g.node_pos[n])
	return out


static func nearest_point(pts: PackedVector2Array, p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var bd := reach
	for q in pts:
		var d := q.distance_to(p)
		if d < bd:
			bd = d
			best = q
	return best


## The landmarks' footprints in a 128 m grid: {"polys": [PackedVector2Array], "grid": {cell: [i]}}.
static func landmark_index(landmarks: Array) -> Dictionary:
	var polys: Array[PackedVector2Array] = []
	var grid := {}
	for l: Dictionary in landmarks:
		var pts := _pts(l.get("p", []))
		if pts.size() < 3:
			continue
		var lo := pts[0]
		var hi := pts[0]
		for q in pts:
			lo = lo.min(q)
			hi = hi.max(q)
		var i := polys.size()
		polys.append(pts)
		for cx in range(floori(lo.x / 128.0), floori(hi.x / 128.0) + 1):
			for cz in range(floori(lo.y / 128.0), floori(hi.y / 128.0) + 1):
				var c := Vector2i(cx, cz)
				if not grid.has(c):
					grid[c] = []
				(grid[c] as Array).append(i)
	return {"polys": polys, "grid": grid}


static func on_landmark(index: Dictionary, p: Vector2) -> bool:
	for i: int in index["grid"].get(Vector2i(floori(p.x / 128.0), floori(p.y / 128.0)), []):
		if Geometry2D.is_point_in_polygon(p, index["polys"][i]):
			return true
	return false


## The Frogs (parodies.md 2.2): the triple corners first (three addresses on different corners
## of the junction, each corner at least 60 degrees round from the others), then the real corner
## shops of the chain (`real`: `convenience_list`, the bake's OSM shop=convenience pois) in a fixed
## shuffled order, SPACING m apart, not on a landmark or by a kebab stand or a venue (`avoid`,
## 20 m). Content-POIs switch: the address fill by a junction, the density a km² and the Old Town
## cap are gone, the shops are where OSM has them.
static func pick_shops(addrs: Array[Dictionary], real: Array[Dictionary], jpos: PackedVector2Array, triples: Dictionary,
		lm: Dictionary, avoid: PackedVector2Array) -> Array[Dictionary]:
	var jgrid := {}
	for q in jpos:
		var c := Vector2i(floori(q.x / 64.0), floori(q.y / 64.0))
		if not jgrid.has(c):
			jgrid[c] = PackedVector2Array()
		var arr: PackedVector2Array = jgrid[c]
		arr.append(q)
		jgrid[c] = arr
	var cands: Array[Dictionary] = []
	for a in addrs:
		var r: Vector2 = a["road"]
		var c := Vector2i(floori(r.x / 64.0), floori(r.y / 64.0))
		var best := Vector2.INF
		var bd := JUNCTION_REACH
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				for q: Vector2 in jgrid.get(c + Vector2i(dx, dz), PackedVector2Array()):
					var d := q.distance_to(r)
					if d < bd:
						bd = d
						best = q
		if best == Vector2.INF or (a["bld"] as Vector2).distance_to(r) < 3.0:
			continue
		if on_landmark(lm, a["bld"]):
			continue
		var near_avoid := false
		for v in avoid:
			if v.distance_to(r) < 20.0:
				near_avoid = true
				break
		if near_avoid:
			continue
		cands.append({"name": a["name"], "road": r, "bld": a["bld"], "j": best, "triple": "", "h": _hash(r), "spare": false})
	var out: Array[Dictionary] = []
	var used := {}
	# The triple corners.
	for id: String in triples:
		var tj: Vector2 = triples[id]
		var near: Array = []
		for k in cands.size():
			var cd: Dictionary = cands[k]
			if (cd["road"] as Vector2).distance_to(tj) < TRIPLE_REACH and (cd["j"] as Vector2).distance_to(tj) < 30.0:
				near.append([(cd["road"] as Vector2).distance_to(tj), k])
		near.sort()
		# The corner buildings themselves when the addresses run short: a site on each diagonal,
		# placed by the wall ray like any other (the data has no shop=convenience to anchor to).
		for d12 in 12:
			var dir := Vector2.from_angle(PI * 0.25 + d12 * PI / 6.0)
			cands.append({"name": "", "road": tj + dir * 6.0, "bld": tj + dir * 80.0, "j": tj, "triple": "", "h": 2.0,
					"corner": true, "spare": false})
			near.append([1000.0 + d12, cands.size() - 1])
		var angles: Array[float] = []
		for nk: Array in near:
			var cd: Dictionary = cands[nk[1]]
			var ang := ((cd["bld"] as Vector2) - tj).angle()
			var clash := false
			for a0 in angles:
				if absf(angle_difference(a0, ang)) < deg_to_rad(60.0):
					clash = true
					break
			if clash:
				continue
			angles.append(ang)
			var s := cd.duplicate()
			s["triple"] = id
			# Past the first three, spares: one stands only if a first three's wall wasn't there.
			s["spare"] = angles.size() > 3
			out.append(s)
			used[nk[1]] = true
			if angles.size() == 6:
				break
	# The rest: the real corner shops of the Frogs' chain (`convenience` pois with `fr`), in a
	# fixed shuffled order, SPACING m from any Frogs already picked.
	var order: Array = []
	for k in real.size():
		order.append([real[k]["h"], k])
	order.sort()
	var sgrid := {}
	for s in out:
		_stand(sgrid, s["road"])
	for ok: Array in order:
		var cd: Dictionary = real[ok[1]]
		var r: Vector2 = cd["road"]
		if on_landmark(lm, cd["bld"]):
			continue
		var near_avoid := false
		for v in avoid:
			if v.distance_to(r) < 20.0:
				near_avoid = true
				break
		if near_avoid:
			continue
		var c := Vector2i(floori(r.x / SPACING), floori(r.y / SPACING))
		var close := false
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				for q: Vector2 in sgrid.get(c + Vector2i(dx, dz), []):
					if q.distance_to(r) < SPACING:
						close = true
		if close:
			continue
		var s := cd.duplicate()
		# For the GPS's turn: the nearest junction within 80 m (else the shop's own point).
		var bj := nearest_point(jpos, r, 80.0)
		s["j"] = bj if bj != Vector2.INF else r
		out.append(s)
		_stand(sgrid, r)
	for s in out:
		s["key"] = key_of(s["road"])
		s["state"] = 0
	return out


static func _stand(sgrid: Dictionary, r: Vector2) -> void:
	var c := Vector2i(floori(r.x / SPACING), floori(r.y / SPACING))
	if not sgrid.has(c):
		sgrid[c] = []
	(sgrid[c] as Array).append(r)


## The venues' anchors (vision 3.0-3.2): a place with an `address` takes the matching address
## poi (the same rule as notebook.gd: the number, the street's last word) nearest its hint; else
## the address poi nearest the place; else the road nearest it, looking at the place.
static func venue_list(places: Array, addrs: Array[Dictionary], g) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var split: Array = []
	for p: Dictionary in places:
		var id := str(p["id"])
		if not VENUES.has(id):
			continue
		var spec: Array = VENUES[id]
		var at: Vector2 = p["at"]
		var best: Dictionary = {}
		var bd := INF
		if p.has("address"):
			var sa := Notebook.split_address(str(p["address"]))
			if not sa.is_empty():
				var last: String = str(sa[0]).get_slice(" ", str(sa[0]).get_slice_count(" ") - 1)
				if split.is_empty():
					for a in addrs:
						split.append(Notebook.split_address(str(a["name"])))
				for ai in addrs.size():
					var a := addrs[ai]
					var asa: Array = split[ai]
					if asa.is_empty() or (asa[1] != sa[1] and not str(asa[1]).split("/").has(sa[1])):
						continue
					var st: String = asa[0]
					if st.get_slice(" ", st.get_slice_count(" ") - 1) != last:
						continue
					var d := (a["bld"] as Vector2).distance_to(at)
					if d < bd and d < 600.0:
						bd = d
						best = a
		if best.is_empty():
			for a in addrs:
				var d := (a["bld"] as Vector2).distance_to(at)
				if d < bd and d < 40.0:
					bd = d
					best = a
		var road := Vector2.INF
		var bld := Vector2.INF
		if p.has("road"):
			# Given outright (VIADUKT: no address, the nearest road is the deck's).
			road = p["road"]
			bld = p["bld"]
		elif not best.is_empty():
			road = best["road"]
			bld = best["bld"]
		elif g != null:
			# No address near: the nearest road, else the nearest address within 140 m (Kasa
			# Biletowa: Kruczkowskiego 3B isn't in the data, its pavilion sits back from the roads).
			var hit: Array = g.snap(at, 60.0)
			if not hit.is_empty():
				road = g.point_at(hit[0], hit[2])
				bld = at + (at - road).normalized() * 10.0 if at.distance_to(road) > 1.0 else at
			else:
				for a in addrs:
					var d := (a["bld"] as Vector2).distance_to(at)
					if d < bd and d < 140.0:
						bd = d
						road = a["road"]
						bld = a["bld"]
		if road == Vector2.INF:
			continue
		out.append({"id": id, "lines": spec[0], "colour": spec[1], "up": spec[2], "road": road, "bld": bld, "key": key_of(road),
				"state": 0, "xfs": [], "off": -1.0})
	return out


## A sign line's width in the atlas (pixels, the tube's PAD both sides).
static func line_px(line: String) -> int:
	return PixelFont.width(line) + 2 * Neon.PAD


# --- the neon atlas ---------------------------------------------------------------------------

## neon_signs.gd's atlas with the venues' lines as rows after its own (drawn with pixel_font.gd's
## glyphs, the accents in the row's top padding): the shop words' rows keep their place, so the
## baked signs read the same through the new texture.
func _build_atlas() -> void:
	var lines: Array[String] = []
	for v in venues:
		for l: String in v["lines"]:
			if not lines.has(l):
				lines.append(l)
	var base := Neon.atlas().get_image()
	var n0 := Neon.all_words().size()
	_rows = n0 + lines.size()
	var img := Image.create_empty(Neon.ATLAS_W, Neon.ROW_H * _rows, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	img.blit_rect(base, Rect2i(0, 0, base.get_width(), base.get_height()), Vector2i.ZERO)
	for k in lines.size():
		var r := n0 + k
		_row_of[lines[k]] = r
		var tube := {}
		PixelFont.each_pixel(lines[k], Neon.PAD, func(x: int, row: int) -> void:
			if x < Neon.ATLAS_W:
				tube[Vector2i(x, r * Neon.ROW_H + row)] = true)
		for p: Vector2i in tube:
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var q := Vector2i(p.x + dx, p.y + dy)
					if q.x < 0 or q.y < r * Neon.ROW_H or q.x >= Neon.ATLAS_W or q.y >= (r + 1) * Neon.ROW_H:
						continue
					var g := 1.0 - (absi(dx) + absi(dy)) / 4.0
					var c := img.get_pixelv(q)
					img.set_pixelv(q, Color(c.r, maxf(c.g, g), 0, 1))
		for p: Vector2i in tube:
			img.set_pixelv(p, Color(1, 1, 0, 1))
	_atlas = ImageTexture.create_from_image(img)


## A neon material (a sector's, the landmarks') reads the bigger atlas from now on.
func _upgrade(m: ShaderMaterial) -> void:
	if m == null or _upgraded.has(m.get_instance_id()):
		return
	_upgraded[m.get_instance_id()] = true
	m.set_shader_parameter("words", _atlas)
	m.set_shader_parameter("rows", float(_rows))
	if _neon_mat == null:
		_neon_mat = m


# --- a sector comes in ----------------------------------------------------------------------------

## main.gd's _on_sector_ready, first: the neon materials take the atlas; when the sector is in
## (visible), its Leżaks and street props now, its walls' rays at the next physics frame.
func on_sector_ready(root: Node3D) -> void:
	for holder in ["Neon", "LandmarkSigns"]:
		var h := root.get_node_or_null(holder)
		if h != null:
			for c in h.get_children():
				var g := c as GeometryInstance3D
				if g != null:
					_upgrade(g.material_override as ShaderMaterial)
	if not root.visible or root.has_meta("mw2"):
		return
	root.set_meta("mw2", true)
	var key := _root_key(root)
	if key == Vector2i(-99999, -99999) or not _by_key.has(key):
		return
	_roots[key] = root.get_instance_id()
	_build_props(key, root)
	_write_lezaks(key)
	_pending.append(key)


static func _root_key(root: Node3D) -> Vector2i:
	var n := str(root.name)
	if not n.begins_with("s_"):
		return Vector2i(-99999, -99999)
	var parts := n.split("_")
	if parts.size() < 3:
		return Vector2i(-99999, -99999)
	return Vector2i(int(parts[1]), int(parts[2]))


func _root(key: Vector2i) -> Node3D:
	if not _roots.has(key):
		return null
	var o := instance_from_id(int(_roots[key]))
	if o == null or not is_instance_valid(o) or not (o as Node).is_inside_tree():
		_roots.erase(key)
		return null
	return o as Node3D


func _physics_process(_dt: float) -> void:
	if _pending.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	var space := get_world_3d().direct_space_state
	var keys := _pending.duplicate()
	_pending.clear()
	for key in keys:
		var root := _root(key)
		if root == null:
			continue
		var b: Dictionary = _by_key[key]
		for i: int in b["shops"]:
			if int(shops[i]["state"]) == 0:
				_place_shop(i, space)
		for i: int in b["venues"]:
			if int(venues[i]["state"]) == 0:
				_place_venue(i, space)
		_build_shops(key, root)
		_venue_neon(key, root)
		_write_lezaks(key)
	_index_doors()
	spent_usec += Time.get_ticks_usec() - t0


## A ray along the ground at RAY_UP to the city's walls: {p, n (horizontal, towards `from`)} or {}.
## Only the sectors' (or the map's) own bodies count: cars, stands and people are looked through.
func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var ex: Array[RID] = []
	for k in 5:
		q.exclude = ex
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return {}
		var col: Object = hit["collider"]
		var par := (col as Node).get_parent() if col is Node else null
		if col is StaticBody3D and par != null and (str(par.name).begins_with("s_") or par == map):
			var n: Vector3 = hit["normal"]
			n.y = 0.0
			if n.length() < 0.5:
				return {}
			n = n.normalized()
			if n.dot(from - (hit["position"] as Vector3)) < 0.0:
				n = -n
			return {"p": hit["position"], "n": n}
		ex.append(hit["rid"])
	return {}


## The wall a site faces: the ray from its road point towards its building, `side` m of straight
## wall each way (rays from the road shifted along it), a roof `roof` m over the street just
## inside. Tries the middle shifted along the wall by up to 5 m. {} if none.
## `under` (VIADUKT): the wall stands under a deck, so heights are the terrain's, not the deck's.
func _wall(space: PhysicsDirectSpaceState3D, road: Vector2, bld: Vector2, side: float, roof: float, far := RAY_FAR, under := false) -> Dictionary:
	var y: float = (map.terrain_height(road.x, road.y) if under else map.ground_height(road.x, road.y)) + RAY_UP
	var dir := bld - road
	if dir.length() < 0.5:
		return {}
	dir = dir.normalized()
	var reach := minf(far, road.distance_to(bld) + 25.0)
	var first := _ray(space, Vector3(road.x, y, road.y), Vector3(road.x + dir.x * reach, y, road.y + dir.y * reach))
	if first.is_empty():
		return {}
	var n: Vector3 = first["n"]
	var t := Vector3(n.z, 0.0, -n.x)
	# The square-on rays start a little in front of the first hit, not at the road point: a corner's
	# first ray meets its wall at a slant, tens of metres along from the road point's foot.
	var hit0: Vector3 = first["p"]
	var back := clampf(Vector2(hit0.x, hit0.z).distance_to(road) * 0.8, 1.5, 6.0)
	var base := hit0 + n * back
	reach = back + 6.0
	for shift: float in [0.0, 2.5, -2.5, 5.0, -5.0]:
		var o := base + t * shift
		var mid := _ray(space, o, o - n * reach)
		if mid.is_empty() or (mid["n"] as Vector3).dot(n) < 0.9:
			continue
		var p: Vector3 = mid["p"]
		var ok := true
		for k: float in [-side, side]:
			var o2 := o + t * k
			var h := _ray(space, o2, o2 - n * (reach + 3.0))
			if h.is_empty() or (h["n"] as Vector3).dot(n) < 0.9 or absf(((h["p"] as Vector3) - p).dot(n)) > PLANE_TOL:
				ok = false
				break
		if not ok:
			continue
		var g: float = map.terrain_height(p.x, p.z) if under else map.ground_height(p.x, p.z)
		var inside := p - n * 2.0
		if map.top_height(inside.x, inside.z) < g + roof:
			continue
		return {"p": Vector3(p.x, g, p.z), "n": n, "t": t}
	return {}


func _place_shop(i: int, space: PhysicsDirectSpaceState3D) -> void:
	var s := shops[i]
	if s["triple"] != "" and int(_triple_placed.get(s["triple"], 0)) >= 3:
		s["state"] = 3
		return
	var far := CORNER_FAR if s.has("corner") else RAY_FAR
	var w := _wall(space, s["road"], s["bld"], SHOP_SIDE, SHOP_ROOF, far)
	# A triple-corner shop that misses its wall swings round its junction a little (the egg needs three).
	if w.is_empty() and s["triple"] != "":
		var j: Vector2 = s["j"]
		for turn: float in [0.35, -0.35, 0.7, -0.7]:
			var road := j + ((s["road"] as Vector2) - j).rotated(turn)
			w = _wall(space, road, j + ((s["bld"] as Vector2) - j).rotated(turn), SHOP_SIDE, SHOP_ROOF, far)
			if not w.is_empty():
				s["road"] = road
				break
	if w.is_empty():
		s["state"] = 2
		if log_on:
			print("storefronts: Frogs %d (%s%s): no wall from %.0f, %.0f" % [i, s["name"],
					", triple " + str(s["triple"]) if s["triple"] != "" else "", s["road"].x, s["road"].y])
		return
	var n: Vector3 = w["n"]
	var p: Vector3 = w["p"]
	s["xf"] = Transform3D(Basis(w["t"], Vector3.UP, n), p + n * 0.02)
	s["door"] = Vector2(p.x + n.x * 1.0, p.z + n.z * 1.0)
	s["state"] = 1
	if s["triple"] != "":
		_triple_placed[s["triple"]] = int(_triple_placed.get(s["triple"], 0)) + 1
	if log_on:
		print("storefronts: Frogs %d (%s%s) on the wall at %.1f, %.1f facing %d°" % [i, s["name"],
				", triple " + str(s["triple"]) if s["triple"] != "" else "", p.x, p.z, roundi(rad_to_deg(atan2(n.x, n.z)))])
	# One shop in 30 has a Leżak lying at its door (parodies.md 5.2's odd places).
	if _hash(s["road"] * 1.7) < 1.0 / 30.0:
		var at := p + n * 1.6 + (w["t"] as Vector3) * 1.2
		_add_scooter(Vector3(at.x, map.ground_height(at.x, at.z), at.z), _hash(s["road"]) * TAU, false, -1)


func _place_venue(i: int, space: PhysicsDirectSpaceState3D) -> void:
	var v := venues[i]
	var lines: Array = v["lines"]
	var widest := 0
	for l: String in lines:
		widest = maxi(widest, line_px(l))
	var px := VENUE_PX
	var w := {}
	while px >= VENUE_PX_MIN - 0.001:
		w = _wall(space, v["road"], v["bld"], widest * px * 0.5, 0.0 if VIADUKT.has(v["id"]) else 2.5, RAY_FAR, VIADUKT.has(v["id"]))
		if not w.is_empty():
			break
		px -= 0.02
	if w.is_empty() and not VIADUKT.has(v["id"]):
		px = VENUE_PX_MIN
		# Looked for a little to each side (a tree's trunk or a kiosk's wall in the first ray's way).
		var road: Vector2 = v["road"]
		for turn: float in [0.0, 0.3, -0.3, 0.6, -0.6, 1.0, -1.0, 1.57, -1.57, 2.2, -2.2, PI]:
			w = _wall(space, road, road + ((v["bld"] as Vector2) - road).rotated(turn), widest * px * 0.5, 2.0, CORNER_FAR)
			if not w.is_empty():
				break
	if w.is_empty():
		v["state"] = 2
		if log_on:
			print("storefronts: venue %s: no wall from %.0f, %.0f (its building %.0f, %.0f)" % [v["id"], v["road"].x, v["road"].y,
					v["bld"].x, v["bld"].y])
		return
	var n: Vector3 = w["n"]
	var t: Vector3 = w["t"]
	var p: Vector3 = w["p"]
	var h := Neon.ROW_H * px
	var xfs: Array[Transform3D] = []
	for k in lines.size():
		var length := line_px(lines[k]) * px
		var bottom := float(v["up"]) + (lines.size() - 1 - k) * h
		xfs.append(Transform3D(Basis(t * length, Vector3.UP * h, n), p + Vector3.UP * (bottom + h * 0.5) + n * 0.14))
	v["xfs"] = xfs
	v["px"] = px
	v["off"] = 0.14
	v["wall"] = Vector2(p.x, p.z)
	v["p"] = p
	v["n"] = n
	v["t"] = t
	v["state"] = 1
	if log_on:
		print("storefronts: venue %s \"%s\" on the wall at %.1f, %.1f, %.2f m out, letter pixel %.2f m" % [v["id"],
				" / ".join(lines), p.x, p.z, v["off"], px])


## The sector's Frogs: one MultiMesh under its root.
func _build_shops(key: Vector2i, root: Node3D) -> void:
	var placed: Array[Transform3D] = []
	for i: int in _by_key[key]["shops"]:
		if int(shops[i]["state"]) == 1:
			placed.append(shops[i]["xf"])
	if placed.is_empty() or root.get_node_or_null("Frogs") != null:
		return
	var mm := _static_mm(_shop_mesh, placed)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Frogs"
	mmi.multimesh = mm
	mmi.material_override = Models.material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	root.add_child(mmi)


func _static_mm(mesh: Mesh, xfs: Array[Transform3D]) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	InstanceBuffers.whiten(mm)
	var box := AABB(xfs[0].origin, Vector3.ZERO)
	for k in xfs.size():
		mm.set_instance_transform(k, xfs[k])
		mm.set_instance_custom_data(k, Color(0, 0, 0, 0))
		box = box.expand(xfs[k].origin)
	mm.custom_aabb = box.grow(6.0)
	return mm


## The sector's venue signs into its Neon MultiMesh (a copy with the signs appended: +0 draw
## calls); a sector without signs of its own gets a Neon holder of its own (+1 at night there).
func _venue_neon(key: Vector2i, root: Node3D) -> void:
	var adds: Array[Array] = []
	for i: int in _by_key[key]["venues"]:
		var v := venues[i]
		if int(v["state"]) != 1:
			continue
		var lines: Array = v["lines"]
		for k in lines.size():
			var c := Color(float(_row_of[lines[k]]), float(line_px(lines[k])) / Neon.ATLAS_W, 1.0, 0.3 + 0.05 * k)
			adds.append([v["xfs"][k], v["colour"], c])
	if adds.is_empty():
		return
	var holder := root.get_node_or_null("Neon") as Node3D
	var mmi: MultiMeshInstance3D = null
	if holder != null:
		for c in holder.get_children():
			if c is MultiMeshInstance3D:
				mmi = c
				break
	if mmi == null:
		if holder == null:
			holder = Node3D.new()
			holder.name = "Neon"
			holder.add_to_group("night_lights", true)
			holder.visible = bool(lit.call()) if lit.is_valid() else true
			root.add_child(holder)
		mmi = MultiMeshInstance3D.new()
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if _neon_mat == null:
			_neon_mat = ShaderMaterial.new()
			_neon_mat.shader = load("res://shaders/neon.gdshader")
			_upgrade(_neon_mat)
		mmi.material_override = _neon_mat
		holder.add_child(mmi)
	var old := mmi.multimesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = old.mesh if old != null else Neon.quad()
	var n0 := old.instance_count if old != null else 0
	mm.instance_count = n0 + adds.size()
	var box := old.custom_aabb if old != null and old.custom_aabb.size != Vector3.ZERO else AABB((adds[0][0] as Transform3D).origin, Vector3.ZERO)
	for k in n0:
		mm.set_instance_transform(k, old.get_instance_transform(k))
		mm.set_instance_color(k, old.get_instance_color(k) if old.use_colors else Color.WHITE)
		mm.set_instance_custom_data(k, old.get_instance_custom_data(k) if old.use_custom_data else Color())
	for k in adds.size():
		var a: Array = adds[k]
		mm.set_instance_transform(n0 + k, a[0])
		mm.set_instance_color(n0 + k, a[1])
		mm.set_instance_custom_data(n0 + k, a[2])
		box = box.expand((a[0] as Transform3D).origin)
	mm.custom_aabb = box.grow(6.0)
	mmi.multimesh = mm
	_upgrade(mmi.material_override as ShaderMaterial)


# --- Leżak, zones, metro ----------------------------------------------------------------------

## A point on the pavement beside lane graph edge e at s: past its outermost lane on its right,
## `extra` m on; INF on a lane or under a roof.
func _pavement(e: int, s: float, extra: float) -> Vector2:
	var k: int = graph.e_lanes[e] - 1
	var off: float = graph.lane_offset(e, maxi(k, 0)) + graph.e_lw[e] * 0.5 + extra
	var p: Vector2 = graph.point_at(e, s, off)
	if not graph.snap(p, 3.2).is_empty():
		return Vector2.INF
	var g: float = map.ground_height(p.x, p.y)
	if map.top_height(p.x, p.y, 1.0) > g + 0.5:
		return Vector2.INF
	return p


## The Leżaks and the zones from the bake's pois (content-POIs switch, DEVELOPMENT.md "Content POIs"):
## `scooter_zone` (the 3 m side along `yaw`; `egg` marks the easter_lezak one, which is `standing`)
## and `scooter` (`p` the pose: `stand` upright, `roof` at `h` m over the ground, every other lies;
## `zn` its zone's index in the zone list). The bake keeps them off carriageways, crossings, kerb
## ramps and solids (`tools/check_pois.py`), so no runtime test.
func _load_scooters(pois: Array) -> void:
	if map == null:
		return
	for p: Dictionary in pois:
		if str(p.get("k", "")) != "scooter_zone":
			continue
		var x := float(p["x"])
		var z := float(p["z"])
		zones.append({"at": Vector3(x, map.ground_height(x, z), z), "yaw": float(p["yaw"]), "key": key_of(Vector2(x, z)),
				"standing": str(p.get("egg", "")) == "easter_lezak", "d": 0.0})
	for p: Dictionary in pois:
		if str(p.get("k", "")) != "scooter":
			continue
		var x := float(p["x"])
		var z := float(p["z"])
		var y: float = map.ground_height(x, z) + (float(p.get("h", 0.0)) if str(p.get("p", "")) == "roof" else 0.0)
		var zn := int(p.get("zn", -1))
		_add_scooter(Vector3(x, y, z), float(p["yaw"]), str(p.get("p", "")) == "stand", zn if zn < zones.size() else -1)


func _add_scooter(at: Vector3, yaw: float, up: bool, zone: int) -> void:
	var i := scooters.size()
	var k := key_of(Vector2(at.x, at.z))
	scooters.append({"at": at, "yaw": yaw, "up": up, "key": k, "zone": zone})
	var c := Vector2i(floori(at.x / LEZAK_CELL), floori(at.z / LEZAK_CELL))
	if not _lezak_grid.has(c):
		_lezak_grid[c] = []
	(_lezak_grid[c] as Array).append(i)
	if not _by_key.is_empty():
		_add_to_key("scooters", k, i)


static func scooter_xf(s: Dictionary) -> Transform3D:
	var b := Basis(Vector3.UP, float(s["yaw"]))
	if not s["up"]:
		# On its side: turned 90 degrees about its length, the deck's edge on the pavement.
		b = b * Basis(Vector3.BACK, PI * 0.5)
		return Transform3D(b, s["at"] + Vector3.UP * 0.1)
	return Transform3D(b, s["at"])


## The sector's Leżaks (its MultiMesh made or rewritten; `fine_detail`, hidden in wide views).
func _write_lezaks(key: Vector2i) -> void:
	var root := _root(key)
	if root == null or not _by_key.has(key):
		return
	var xfs: Array[Transform3D] = []
	for i: int in _by_key[key]["scooters"]:
		if not scooters[i].get("gone", false):
			xfs.append(scooter_xf(scooters[i]))
	if xfs.is_empty() and not _lezak_mmi.has(key):
		return
	var mmi: MultiMeshInstance3D = null
	if _lezak_mmi.has(key) and is_instance_valid(instance_from_id(int(_lezak_mmi[key]))):
		mmi = instance_from_id(int(_lezak_mmi[key])) as MultiMeshInstance3D
	if xfs.is_empty():
		# Loop jobs-2: every Leżak of the sector is in a boot: nothing to draw.
		if mmi != null:
			mmi.multimesh = null
		return
	if mmi == null or not mmi.is_inside_tree():
		mmi = MultiMeshInstance3D.new()
		mmi.name = "Lezaks"
		mmi.material_override = Models.material()
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		mmi.add_to_group("fine_detail", true)
		mmi.visible = bool(fine_shown.call()) if fine_shown.is_valid() else true
		root.add_child(mmi)
		_lezak_mmi[key] = mmi.get_instance_id()
	mmi.multimesh = _static_mm(_lezak_mesh, xfs)


## The metro entrances from the bake's `subway_entrance` pois (content-POIs switch): `yaw` is the
## way down (the canopy's open front faces away from it), `st` the station's name; the ones that
## open off an underground passage only (`u`) have no street canopy. Metro Centrum's wear its blue
## 1990s tubes (F, 2026-11-02).
func _load_metros(pois: Array) -> void:
	if map == null:
		return
	for p: Dictionary in pois:
		if str(p.get("k", "")) != "subway_entrance" or int(p.get("u", 0)) == 1:
			continue
		var x := float(p["x"])
		var z := float(p["z"])
		var form := metro_form(str(p.get("st", "")), str(p.get("f", "canopy")))
		# On a sunken square (the Patelnia, map_builder SUNKEN) the landmark site's glass barrels are
		# the entrances: no canopy of our own.
		if MapBuilderStatic.in_sunken(x, z):
			form = "none"
		metros.append({"at": Vector3(x, map.ground_height(x, z), z), "yaw": float(p["yaw"]), "station": str(p.get("st", "")),
				"ref": str(p.get("ref", "")), "key": key_of(Vector2(x, z)), "form": form,
				"lift": (int(absf(x * 7.0 + z * 13.0)) % 5) < 3})


## The Ratusz-Arsenał station (OSM's name on its entrances).
const RATUSZ := "Ratusz-Arsenał"


## The entrance's look by station: Centrum's 1990s tubes (F, 2026-11-02); Świętokrzyska's mapped
## canopies are M2's steel-and-glass triangle tents (F's photo, Feb 2026), its plain stairs stay
## stairs; Rondo ONZ wears the same tents, Stadion Narodowy, Kopernik and Gdanski their glass
## crystals, Nowy Swiat-Uniwersytet its violet box; Ratusz-Arsenał's are its own (Props._metro_ratusz);
## elsewhere the bake's `f`.
static func metro_form(station: String, f: String) -> String:
	if station == "Centrum":
		return "tube"
	if station == "Świętokrzyska" and f == "canopy":
		return "tent"
	if station == "Rondo Daszyńskiego" and f == "canopy":
		return "wings"  # F's photos (2026-11-06): the red glass butterfly canopies
	# Street photos (Mapillary, 2026-11-07): M2's other stations, each with its own pavilion.
	if f == "canopy":
		match station:
			"Rondo ONZ":
				return "tent"  # the same steel-and-glass A-frame with the yellow roundel
			"Stadion Narodowy":
				return "crystal"
			"Centrum Nauki Kopernik":
				return "crystal_aqua"
			"Dworzec Gdański":
				return "crystal_clear"
			"Nowy Świat-Uniwersytet":
				return "box"
	if station == RATUSZ:
		# F's photos (2026-11-07): the glass escalator pavilion by the tram stop, stone M1 entrances
		# with a white canopy where OSM maps a canopy, stone stairwells elsewhere.
		if f == "footway":
			return "pavilion"
		return "stone" if f == "canopy" else "stone_steps"
	return f


## The Rowerilo docks from the bake's `bicycle_rental` pois (`yaw` along the rack row, `l` its length
## when mapped as an area): a row of 4-8 bikes (`l` / 0.85 m, 6 when unmapped) and a terminal. They are
## drawn into the sector's StreetProps mesh, so they add no draw call where that mesh already stands.
func _load_docks(pois: Array) -> void:
	if map == null:
		return
	for p: Dictionary in pois:
		if str(p.get("k", "")) != "bicycle_rental":
			continue
		var x := float(p["x"])
		var z := float(p["z"])
		var n := clampi(int(float(p["l"]) / 0.85) if p.has("l") else 6, 4, 8)
		docks.append({"at": Vector3(x, map.ground_height(x, z), z), "yaw": float(p.get("yaw", 0.0)), "n": n,
				"key": key_of(Vector2(x, z))})


## Loop jobs-2: the payphone's spot: on the pavement by Plac Konstytucji's nearest lanes (2.4 m past
## the outer lane's edge, within PHONE_REACH m of the place, the nearest such), 8 m clear of the
## metro entrances, facing the road.
func _pick_payphone(at: Dictionary) -> void:
	if graph == null or map == null or not at.has(PHONE_PLACE):
		return
	var c: Vector2 = at[PHONE_PLACE]["at"]
	if c == Vector2.INF:
		return
	var best := Vector2.INF
	var best_d := PHONE_REACH
	var best_e := -1
	var best_s := 0.0
	var seen := {}
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var key: int = graph.cell_key(c + Vector2(dx, dz) * 60.0)
			if seen.has(key) or not graph.grid.has(key):
				continue
			seen[key] = true
			for e: int in graph.grid[key]:
				if graph.e_bridge[e] == 1 or graph.e_dk[e] >= 0 or graph.e_tn[e] >= 0:
					continue
				var s0: float = graph.project(e, c)
				for ds in [-20.0, -10.0, 0.0, 10.0, 20.0]:
					var sv: float = clampf(s0 + ds, graph.e_s0[e] + 3.0, graph.e_s1[e] - 3.0)
					var q: Vector2 = graph.point_at(e, sv)
					if q.distance_to(c) > best_d + 10.0:
						continue
					var p := _pavement(e, sv, 2.4)
					if p == Vector2.INF or p.distance_to(c) >= best_d:
						continue
					var clash := false
					for m in metros:
						if Vector2(m["at"].x, m["at"].z).distance_to(p) < 8.0:
							clash = true
							break
					if not clash:
						best = p
						best_d = p.distance_to(c)
						best_e = e
						best_s = sv
	if best == Vector2.INF:
		print("storefronts: no pavement for the payphone at %s" % PHONE_PLACE)
		return
	# Facing the road: the lane's point at the same s is in front (-z).
	var road: Vector2 = graph.point_at(best_e, best_s)
	var to := road - best
	payphone = {"at": Vector3(best.x, map.ground_height(best.x, best.y), best.y), "yaw": atan2(-to.x, -to.y), "key": key_of(best)}
	if log_on:
		print("storefronts: the payphone at %.0f, %.0f (%.0f m from %s)" % [best.x, best.y, best_d, PHONE_PLACE])


## The sector's street props (metro entrances and the zones' paint): one mesh under its root.
func _build_props(key: Vector2i, root: Node3D) -> void:
	var b: Dictionary = _by_key[key]
	var phone: bool = not payphone.is_empty() and payphone["key"] == key
	if (b["metros"] as Array).is_empty() and (b["zones"] as Array).is_empty() and (b["docks"] as Array).is_empty() and not phone:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var box := AABB()
	var first := true
	for i: int in b["metros"]:
		var m := metros[i]
		if m["form"] == "none":
			continue
		Props.add_metro_entrance(st, Transform3D(Basis(Vector3.UP, float(m["yaw"])), m["at"]), m["form"], m["lift"])
		box = AABB(m["at"], Vector3.ZERO) if first else box.expand(m["at"])
		first = false
	for i: int in b["zones"]:
		var z := zones[i]
		Props.add_scooter_zone(st, Transform3D(Basis(Vector3.UP, float(z["yaw"])), z["at"]))
		box = AABB(z["at"], Vector3.ZERO) if first else box.expand(z["at"])
		first = false
	for i: int in b["docks"]:
		var d := docks[i]
		Props.add_bike_dock(st, Transform3D(Basis(Vector3.UP, float(d["yaw"])), d["at"]), int(d["n"]))
		box = AABB(d["at"], Vector3.ZERO) if first else box.expand(d["at"])
		first = false
	if phone:
		Props.add_payphone(st, Transform3D(Basis(Vector3.UP, float(payphone["yaw"])), payphone["at"]))
	var mi := MeshInstance3D.new()
	mi.name = "StreetProps"
	mi.mesh = st.commit()
	mi.material_override = Models.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	root.add_child(mi)


# --- kebab boards and billboards ------------------------------------------------------------------

func _kebab_boards(at: Dictionary) -> void:
	if jobs == null or not jobs.has_method("stand_points"):
		return
	var pts: PackedVector2Array = jobs.stand_points()
	for id: String in NAMED_STANDS:
		if not at.has(id):
			continue
		var i := _nearest_index(pts, at[id]["at"], 300.0)
		if i >= 0:
			jobs.name_stand(i, NAMED_STANDS[id][0], NAMED_STANDS[id][1])
			if log_on:
				print("storefronts: kebab stand %d is %s" % [i, NAMED_STANDS[id][0]])
	for id: String in STAND_TAGS:
		if not at.has(id):
			continue
		var i := _nearest_index(pts, at[id]["at"], STAND_TAG_REACH)
		if i >= 0 and jobs.stand_tag(i) == "":
			jobs.tag_stand(i, STAND_TAGS[id])


static func _nearest_index(pts: PackedVector2Array, p: Vector2, reach: float) -> int:
	var best := -1
	var bd := reach
	for i in pts.size():
		var d := pts[i].distance_to(p)
		if d < bd:
			bd = d
			best = i
	return best


func _billboards(at: Dictionary) -> void:
	if eggs == null or not eggs.has_method("billboard_line"):
		return
	for word: String in BILLBOARDS:
		var spec: Array = BILLBOARDS[word]
		var id: String = spec[0]
		var where: Vector2 = triple_at.get(id, at[id]["at"] if at.has(id) else Vector2.INF)
		if where == Vector2.INF:
			continue
		eggs.billboard_line(word, where, Color(spec[1]), Color(spec[2]))


# --- the stamp card -------------------------------------------------------------------------------

func _index_doors() -> void:
	_door_grid.clear()
	for i in shops.size():
		if int(shops[i]["state"]) != 1:
			continue
		var d: Vector2 = shops[i]["door"]
		var c := Vector2i(floori(d.x / 64.0), floori(d.y / 64.0))
		if not _door_grid.has(c):
			_door_grid[c] = []
		(_door_grid[c] as Array).append(i)


## The placed Frogs whose door is nearest `p`, within `reach` m (-1 if none): rides.gd's detour and
## the GPS's Frogs turn ask too.
func shop_near(p: Vector2, reach: float) -> int:
	var c := Vector2i(floori(p.x / 64.0), floori(p.y / 64.0))
	var best := -1
	var bd := reach
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			for i: int in _door_grid.get(c + Vector2i(dx, dz), []):
				var d := (shops[i]["door"] as Vector2).distance_to(p)
				if d < bd:
					bd = d
					best = i
	return best


## A Frogs (placed or not) by `p` within `reach`, by its junction: for the GPS's turn.
func frogs_at_junction(p: Vector2, reach: float) -> int:
	var best := -1
	var bd := reach
	for i in shops.size():
		if int(shops[i]["state"]) >= 2 or (shops[i]["spare"] and int(shops[i]["state"]) == 0):
			continue
		var d := (shops[i]["j"] as Vector2).distance_to(p)
		if d < bd:
			bd = d
			best = i
	return best


func _load_stamps() -> void:
	if wallet == null:
		return
	stamps = int(wallet.keep.get("frogs_stamps", 0))
	if int(wallet.keep.get("frogs_day", 0)) != EggBook.today():
		wallet.keep["frogs_day"] = EggBook.today()
		wallet.keep["frogs_today"] = []
	stamped_today = (wallet.keep.get("frogs_today", []) as Array).size()


## The stamp rule (static: check_parodies.gd runs it): {stamp: bool, free: bool} for a stop at
## shop `i` given today's stamped shops and the card's count.
static func stamp_rule(i: int, today: Array, card: int) -> Dictionary:
	if today.has(i) or today.size() >= STAMPS_DAY:
		return {"stamp": false, "free": false}
	return {"stamp": true, "free": card + 1 >= STAMPS_CARD}


func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_clock += dt
	_t += dt
	if not vehicle.is_valid():
		return
	var veh: Array = vehicle.call()
	var vp: Vector3 = veh[0]
	var flying: bool = veh[2]
	if not flying and vp != Vector3.INF:
		_knock_check(vp, float(veh[1]))
	if _t >= TICK:
		var step := _t
		_t = 0.0
		_tick(vp, float(veh[1]), flying, step)
	spent_usec += Time.get_ticks_usec() - t0


func _tick(vp: Vector3, kmh: float, flying: bool, step: float) -> void:
	if rig_rechotka and not _rig_done:
		_rig(vp)
	if flying or vp == Vector3.INF:
		_hold = 0.0
		return
	var i := shop_near(Vector2(vp.x, vp.z), STAMP_REACH)
	if i < 0 or kmh / 3.6 >= STAMP_SPEED:
		_hold = 0.0
		_hold_shop = -1
		return
	if i != _hold_shop:
		_hold_shop = i
		_hold = 0.0
	_hold += step
	if _hold < STAMP_HOLD or _hold - step >= STAMP_HOLD:
		return
	_stop_at(i)


## Stopped at shop i for STAMP_HOLD s.
func _stop_at(i: int) -> void:
	var door: Vector2 = shops[i]["door"]
	var at3 := Vector3(door.x, map.ground_height(door.x, door.y), door.y)
	if wallet != null and int(wallet.keep.get("frogs_day", 0)) != EggBook.today():
		_load_stamps()
	var today: Array = wallet.keep.get("frogs_today", []) if wallet != null else []
	var r := stamp_rule(i, today, stamps)
	if sfx != null:
		sfx.play_at("frog_chime", at3)
	if not r["stamp"]:
		if _clock - _line_t > LINE_GAP and dialogue != null:
			_line_t = _clock
			dialogue.say_ambient(func() -> Vector3: return at3, "Frogs", "rechotka", "", 4.0, FROGS_COLOUR, 2.6)
		return
	today.append(i)
	stamps += 1
	stamped_today = today.size()
	if r["free"]:
		print("rechotka: stamp %d, the free hot dog (+%d respect)" % [stamps, FREE_RESPECT])
		stamps = 0
		if wallet != null:
			wallet.add_respect(FREE_RESPECT)
		if hud != null:
			hud.show_note(Lang.pick("HOT DOG GRATIS!", "FREE HOT DOG!"), Lang.pick("Karta stałego klienta: 10/10 · +%d ★", "Loyalty card: 10/10 · +%d ★") % FREE_RESPECT, FROGS_COLOUR)
		if dialogue != null:
			dialogue.say_ambient(func() -> Vector3: return at3, "Frogs", "rechotka", "free", 4.5, FROGS_COLOUR, 2.6, true)
	else:
		print("rechotka: stamp %d (shop %d, %d today)" % [stamps, i, today.size()])
		if hud != null:
			hud.toast("FROGS · PIECZĄTKA %d/%d" % [stamps, STAMPS_CARD], "Frogs · stamp %d of %d" % [stamps, STAMPS_CARD])
		if dialogue != null:
			dialogue.say_ambient(func() -> Vector3: return at3, "Frogs", "rechotka", "stamp", 4.0, FROGS_COLOUR, 2.6, true)
	_line_t = _clock
	if wallet != null:
		wallet.keep["frogs_stamps"] = stamps
		wallet.keep["frogs_today"] = today
		wallet.save()


## --stamps=K: the card starts at K (for the free hot dog's check).
func preset_stamps(k: int) -> void:
	stamps = clampi(k, 0, STAMPS_CARD - 1)
	if wallet != null:
		wallet.keep["frogs_stamps"] = stamps


## --rechotka: the car on the lane nearest the door of the placed Frogs nearest it, stopped.
func _rig(vp: Vector3) -> void:
	var best := -1
	var bd := INF
	for i in shops.size():
		if int(shops[i]["state"]) != 1:
			continue
		var d := (shops[i]["door"] as Vector2).distance_to(Vector2(vp.x, vp.z))
		if d < bd:
			bd = d
			best = i
	if best < 0 or bd > 400.0 or car == null:
		return
	var door: Vector2 = shops[best]["door"]
	var hit: Array = graph.snap(door, 20.0, Vector2.ZERO, false, true)
	if hit.is_empty():
		return
	var p: Vector2 = graph.point(hit[0], hit[2], graph.lane_offset(hit[0], hit[1]), graph.seek(hit[0], hit[2], graph.e_first[hit[0]]))
	var d: Vector2 = graph.direction(hit[0], hit[2])
	car.global_position = Vector3(p.x, graph.surface(hit[0], p) + 0.1, p.y)
	car.rotation.y = atan2(-d.x, -d.y)
	car.set("vel", Vector3.ZERO)
	car.set("forward_speed", 0.0)
	car.reset_physics_interpolation()
	_rig_done = true
	print("rechotka: --rechotka: the car %.1f m from Frogs %d's door (%s)" % [p.distance_to(door), best, shops[best]["name"]])


# --- the knock-about ------------------------------------------------------------------------------

## The car within KNOCK_R m of a lying Leżak pushes it 1-3 m on (never onto a lane): the clatter,
## the `lezak` `knock` aside at most once a minute, its sector's MultiMesh rewritten once.
func _knock_check(vp: Vector3, kmh: float) -> void:
	if kmh < 3.0 or _lezak_grid.is_empty():
		return
	var c := Vector2i(floori(vp.x / LEZAK_CELL), floori(vp.z / LEZAK_CELL))
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			for i: int in _lezak_grid.get(c + Vector2i(dx, dz), []):
				var s := scooters[i]
				if s["up"]:
					continue
				var at: Vector3 = s["at"]
				var d := Vector2(at.x - vp.x, at.z - vp.z)
				if d.length() > KNOCK_R + 0.9:
					continue
				_knock(i, d, kmh)


func _knock(i: int, away: Vector2, kmh: float) -> void:
	var s := scooters[i]
	var at: Vector3 = s["at"]
	var dir := away.normalized() if away.length() > 0.01 else Vector2.RIGHT
	var push := clampf(kmh / 15.0, 1.0, 3.0)
	var to := Vector2.INF
	while push >= 0.5:
		var q := Vector2(at.x, at.z) + dir * push
		if graph == null or graph.snap(q, 2.6).is_empty():
			to = q
			break
		push -= 0.5
	if to == Vector2.INF:
		to = Vector2(at.x, at.z) + dir * 0.3
	var old_c := Vector2i(floori(at.x / LEZAK_CELL), floori(at.z / LEZAK_CELL))
	s["at"] = Vector3(to.x, map.ground_height(to.x, to.y), to.y)
	s["yaw"] = float(s["yaw"]) + 0.6
	var new_c := Vector2i(floori(to.x / LEZAK_CELL), floori(to.y / LEZAK_CELL))
	if new_c != old_c:
		(_lezak_grid[old_c] as Array).erase(i)
		if not _lezak_grid.has(new_c):
			_lezak_grid[new_c] = []
		(_lezak_grid[new_c] as Array).append(i)
	_write_lezaks(s["key"])
	if sfx != null:
		sfx.play_at("scooter_clatter", s["at"])
	if log_on:
		print("storefronts: Leżak %d knocked %.1f m to %.1f, %.1f" % [i, push, to.x, to.y])
	if _clock - _knock_t > KNOCK_GAP and dialogue != null and dialogue.bubbles != null:
		_knock_t = _clock
		var l: Array = dialogue.line("lezak", "knock", true)
		if not l.is_empty():
			var p3: Vector3 = s["at"]
			dialogue.bubbles.say_ambient(func() -> Vector3: return p3, "", l[0], l[1], 3.5, Color("#8e44d9"), 1.6)


# --- loop jobs-2: the round-up's side (roundup_job.gd) ----------------------------------------------

## The lying Leżaks still out within `reach` m of `p`, nearest first (at most `n`): a scan of the list,
## run once when a round-up starts.
func lying_near(p: Vector2, reach: float, n: int) -> Array[int]:
	var near: Array = []
	for i in scooters.size():
		var s := scooters[i]
		if s["up"] or s.get("gone", false):
			continue
		var d := Vector2(s["at"].x, s["at"].z).distance_to(p)
		if d <= reach:
			near.append([d, i])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var out: Array[int] = []
	for k in mini(n, near.size()):
		out.append(int(near[k][1]))
	return out


## Leżak i goes into the boot: off the map (its cell and its sector's MultiMesh), the clatter.
func collect(i: int) -> void:
	var s := scooters[i]
	if s.get("gone", false):
		return
	s["gone"] = true
	var at: Vector3 = s["at"]
	var c := Vector2i(floori(at.x / LEZAK_CELL), floori(at.z / LEZAK_CELL))
	if _lezak_grid.has(c):
		(_lezak_grid[c] as Array).erase(i)
	_write_lezaks(s["key"])
	if sfx != null:
		sfx.play_at("scooter_clatter", at)


## The collected Leżaks lie about again (by the next morning: roundup_job.gd calls it by day).
## Returns how many came back.
func restore_collected() -> int:
	var keys := {}
	var n := 0
	for i in scooters.size():
		var s := scooters[i]
		if not s.get("gone", false):
			continue
		s["gone"] = false
		n += 1
		var at: Vector3 = s["at"]
		var c := Vector2i(floori(at.x / LEZAK_CELL), floori(at.z / LEZAK_CELL))
		if not _lezak_grid.has(c):
			_lezak_grid[c] = []
		(_lezak_grid[c] as Array).append(i)
		keys[s["key"]] = true
	for k: Vector2i in keys:
		_write_lezaks(k)
	return n


## For the bench's and the check's counters.
## A placed venue's wall (trend_job.gd's MLASK sticker on DŻEMINI): {p: Vector3 on the wall's foot,
## n (out of the wall), t (along it), up (the sign's bottom, m)}, or {} until its sector placed it.
func venue_wall(id: String) -> Dictionary:
	for v: Dictionary in venues:
		if str(v["id"]) == id:
			if int(v["state"]) != 1 or not v.has("n"):
				return {}
			return {"p": v["p"], "n": v["n"], "t": v["t"], "up": float(v["up"])}
	return {}


func summary() -> String:
	var placed := 0
	var failed := 0
	for s in shops:
		placed += 1 if int(s["state"]) == 1 else 0
		failed += 1 if int(s["state"]) == 2 else 0
	var vp := 0
	for v in venues:
		vp += 1 if int(v["state"]) == 1 else 0
	return "Frogs %d placed, %d without a wall, %d waiting · venues %d of %d · stamps %d (%d today)" % [placed, failed,
			shops.size() - placed - failed, vp, venues.size(), stamps, stamped_today]
