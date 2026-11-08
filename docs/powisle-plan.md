# Powiśle, more real: the plan (F, 2026-11-08)

F rode the coffee-run bike through Powiśle and said it has too little detail: it needs real
houses, details on the streets, and the power plant (Elektrownia Powiśle). This file lists what
to do, ordered by what the player sees most, so one thread can take one item at a time (each is
a BACKLOG line "Powiśle P1..P12" and a ROADMAP v1.0 line). Written in the cloud from `centrum.json`
and the specs; no photo was looked at yet (see "Photos").

## What the map has there now (measured 2026-11-08)

Box x -100..800, z -1000..120 (Aleje Jerozolimskie to Dobra, Nowy Świat's escarpment to the river), 0.99 km².

- **508 OSM buildings**: 175 apartments, 104 plain `yes`, 43 outbuildings, 37 offices, 27 retail.
  162 are 4 m sheds and 71 are 14 m. **Only 33 carry a name**, 43 a mapped colour.
- **Street dress exists only on Tamka and Dobra** (`_powisle_house`, `tenement_trim.gd`: plasters, cornice,
  string course, shop panes; spec `dobra_tamka.md`). Solec, Browarna, Radna, Leszczyńska, Lipowa,
  Smolna, Topiel, Zajęcza, Drewniana, Oboźna and Aleja 3 Maja get none of it.
- **Landmarks built**: Elektrownia (a generic works block, spec `elektrownia.md`), Ostrogski + Chopin
  Institute, Teresy, Piano House, Cube House, Hortus, Moderna, Młotek, BUW, the boulevards (`bulwary`),
  Syrenka, Dworzec Wodny, Kaskada, the UFO pavilion with jazz, the Poniatowski viaduct.
- **Furniture density is the city average**, not better: lamps 220/km² (city 223), benches 176 (161),
  bins 53 (64), shelters 13, signals 53. Powiśle is a place people stroll in, so average reads empty.
- **Shops**: 8 neon signs in `Storefronts.POWISLE`, 10 convenience POIs, 7 bike docks, 3 kebab, 197 addresses.
- Not built at all (CITY_INVENTORY ✗): Barceló, Carpathia Office House, RPZ Powiśle substation,
  Klub Bankowca, Autoreduta, Arkada centre, Nordic Park, Orlen, the UW faculties on Dobra
  (Artes Liberales, Collegium Iuridicum IV), Pawilon Tańca, Zamoyski school, Chopin Museum's own front.

## The list, by impact

### P1. Elektrownia Powiśle rebuilt from photos (Opus, map geometry; biggest single gain)
It is F's named ask and the bike dock and the EV tow end there, so it is seen every run. Today it
is a T of brick walls with two 48 m chimneys and arched windows (spec `elektrownia.md`, "photo check" open).
Facts gathered: the plant was built from 1904, a second chimney in 1910, a rail spur in 1924, power
stopped in 2001, reopened 2020 (APA Wojciechowski; elektrowniapowisle.com). Per the architects the
old boiler house, engine room, coal chute frame (supports up to 12 m) and switchroom are kept; the
boiler house's **30 m stacks were recreated**, dormers rebuilt, the coal crane became a panoramic
lift, and new office/hotel/flat blocks stand beside it in steel frame with brick or glass infill
(archilovers). To do:
1. Get photos (Mapillary, Panoramax, any web) of Dobra 42 from Dobra, Browarna, Wiślana/Elektryczna and
   the yard; write a photo report `docs/landmarks/photo-reports/elektrownia.md`.
2. **Chimney count and height** (game has 2 at 48 m; sources say 30 m recreated stacks): fix from photos.
3. Separate the halls: boiler house, engine room (food hall), switchroom, with their own roof shapes,
   dormers, the arched windows' real rhythm, the dark steel frames and the lit food hall at night.
4. The coal chute frame and the lift tower; the yard to the east (it already holds the chill crowd).
5. The new blocks around (hotel, offices, flats) as real, different massings, not OSM's flat boxes.
6. A bench with the bench shot `--solo=elektrownia --solo-look=lit` plus the city shot from the bike route.

### P2. Real houses on all the Powiśle streets, from photos (Sonnet for batches, Opus accepts)
Extend the Tamka/Dobra dress to **Solec, Browarna, Radna, Leszczyńska, Lipowa, Smolna, Zajęcza,
Topiel, Drewniana, Oboźna, Czerwonego Krzyża, Aleja 3 Maja**. Per street: fetch photos, list the
houses (address pois exist: Radna 1-17, Solec 30-109, Tamka 1-23, Smolna 8-20 ...), set each one's
plaster, floors, roof, shop fronts and gate, and mark the post-war slabs and gaps correctly. Use the
`docs/streets/*.md` format (see `emilii-plater.md`). Split into threads: Tamka+Dobra check, Solec,
Smolna+Zajęcza+Topiel, Radna+Leszczyńska+Lipowa+Browarna, Aleja 3 Maja.

### P3. The missing buildings of the inventory (one short spec each, Sonnet)
Barceló and Carpathia Office House (Zajęcza), RPZ Powiśle substation (brick, Zajęcza), Klub Bankowca (Smolna),
Autoreduta and the Arkada centre and Orlen (Aleja 3 Maja), Nordic Park, UW Artes Liberales and Collegium
Iuridicum IV (Dobra), Pawilon Tańca, XVIII LO Zamoyski, the Chopin Museum front on Tamka. Each is
"from photos or from LoD2 with the right facade type", not a flat OSM box.

### P4. Ground, kerbs and the street surface (Opus, map)
Real Powiśle has granite setts and old cobbles on the side streets (Browarna, Radna, Lipowa
are the usual photo subjects), tram-less narrow streets, parked cars on both kerbs, and kerbs
with ramps at crossings. Check `road-design-system.md`; add cobble or sett patches by street, kerb
lines, zebra crossings that meet paths, and the Aleja 3 Maja underpass edge. Quality gate: continuous
paths, crossings meet paths.

### P5. Street furniture above the city average (Sonnet, `street_details.gd`)
Target for Powiśle roughly 1.5 x the city's density: lamps in the older cast-iron/arm style on the
tenement streets, benches and bins on Tamka, Dobra and the boulevard, bike racks at the cafés,
kiosks, advertising columns, bollards, planters, street-name plates, tree guards. The numbers above
are the baseline to beat; report them before/after.

### P6. Shops, cafés and bars with parody names (Sonnet, content)
Grow `Storefronts.POWISLE` from 8 to ~40 with real kinds of places, not real brands: Centrala,
Champs, Gatsby, Kakadu Karaoke (Zajęcza bars, parodies only), cafés, bakeries, vinyl shops,
the Dobra/Tamka student kiosks, the bookshop under the library, a Żabka-type frog shop. Pavement
cafés with umbrellas and chairs on Browarna and Tamka (a summer set and a winter set).

### P7. Courtyards, greenery and parks (Sonnet)
Skwer Kahla, Park Odkrywców, Park Beyera, Skwer Wodiczko, the Złota Kaczka corner, the BUW garden's
surroundings, the Smolna steps and the escarpment stairs (CITY_INVENTORY lists 145 steps in the box).
Make each park a place: paths, benches, a playground where the real one is, the right trees.

### P8. Life: people and traffic (Sonnet, `crowds.gd`)
Students on Dobra (UW faculties) at class times, runners and cyclists on the boulevards, dog walkers,
a morning queue at the bakery, evening crowd at Zajęcza bars, the Poniatowski beach. Hook to the
existing district card ("Odkryto: Powiśle").

### P9. Night look (Opus, because of lights budget)
Lit shop windows on the dressed streets, warm sodium vs cold LED lamps per street, the Elektrownia
lit from inside, the viaduct bars' glow. Bench before and after: lights add draw calls.

### P10. Roofs and rooftops (Opus; RF4b already in ROADMAP)
Powiśle's roof terraces, L-shaped hips, chimneys and dormers on the tenement roofs seen from the
helicopter. Takes over ROADMAP "RF4b".

### P11. Wybrzeże Kościuszkowskie and the water edge (Opus)
The road, the flood wall, the stairs down to the boulevard, the Syrenka plinth, moorings and the
bridge abutments. Check against the bridges audit (photo lists in /mnt/project-files/bridges-audit/).

### P12. Mac and phone look pass (F's yes for device)
After each of the above: Mac shots at phone size, then the iPhone. Phone-only: draw calls near
Elektrownia and the boulevard, jazz level, night readability.

## Photos
The shoot list with every address: `docs/powisle-photos-needed.txt`.
Fetch them in the thread that takes the item (Mapillary, Panoramax, any web source, any licence;
reference only, never committed; note the source in the photo report). The Mapillary token is not on
the Mac and Wikimedia Commons is blocked from the cloud, so Panoramax and web search come first.
Sources read for this plan: elektrowniapowisle.com/en/o-elektrowni (history), archilovers.com
project 325096 (APA Wojciechowski, structure, stacks, coal chutes, lift).

## Rules for every item
Parody brand names only. Both city paths (runtime and prebuilt sectors). Light definition of done for
content and signs; full (verify, shots, bench, `--ios`) for geometry and anything per-frame. Tick the
ROADMAP line and BACKLOG in the same PR.
