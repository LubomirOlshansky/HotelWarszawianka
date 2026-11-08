# Around Warsaw: the demo plan

Written 2026-10-28, after the user played on an iPhone 16 Pro Max and asked for "the top indie
game", starting with a really good demo of the centre: **from Rondo Daszyńskiego to Stadion
Narodowy and from Arkadia to Łazienki Królewskie**, with the overpasses and roads fixed and
some police added.

This is a plan. It changes nothing by itself: every step is an agent loop in section 7, and
every download in section 3 waits for the user's yes.

Conventions. Coordinates are map metres, +x east, +z south, origin 52.2340 N 21.0240 E (the
centre of today's map), the same numbers `--at=x,z` takes. Numbers marked *survey* come from a
read-only pass over `game/map/centrum.json` (baked 2026-10-28 10:06), `terrain.json`,
`lod2.json` and the deck rules in `map_builder.gd` / `bake_roads.py`, run on 2026-10-28 while
loop 2b was cutting the frame cost. Phone budgets refer to README's "Performance budgets"
(loop 2b); until that section lands, the provisional budget **P** in section 7 applies.

---

## 0. In one screen

- **Area.** S 52.2085, W 20.9780, N 52.2595, E 21.0560: 5.32 × 5.64 km, **30.0 km², 4.8× today's
  6.3 km²**. It holds the Old Town, the Royal Route, three road bridges and the railway bridge with
  both banks, the Sejm, most of Łazienki, the Rondo Daszyńskiego towers and Arkadia. The origin
  stays where it is, so every coordinate in the code and docs stays valid.
- **One map, streamed.** At today's density the area would be ~30 M vertices and ~2 GB of video
  memory, so it cannot be resident on a phone. It becomes one continuous city cut into
  **512 m sectors** (about 140): the 3 × 3 around the camera at full detail, a
  one-draw-call proxy for every other sector, and the lane graph, decks, roof grid and points of
  interest held globally. There are no loading screens.
- **Roads.** The survey found nine defect classes on today's map, from three root causes:
  bridge ends are pinned to a 10 m bare-earth elevation grid that blurs abutments into humps;
  the deck solver cannot honour clearance once an end is pinned low; and tunnels are thrown
  away. The user's screenshot is the **east** end of Most Poniatowskiego, where the deck crosses
  Wybrzeże Szczecińskie only **1.3 m** above it. The 1.3 m concrete slab therefore sits in the
  roadway, and buses drive through it. A pier also stands 0.4 m from that road's centreline.
- **Police.** Affectionate and family-friendly: patrol cars in traffic, a "suszarka" speed trap,
  city guards with wheel clamps. 1 to 3 "koguty" (light-bar levels), a chase you can always
  escape, and a "mandat" of 30 to 150 zł. The first offence is always a caution ("pouczenie").
  On a rescue run, police escort you instead of chasing you.
- **Order.** River fix and perf skill (already queued), then roads and overpasses, the HUD at
  phone size, sector streaming on today's map, the demo data and bake, the new landmarks, cars,
  police, jokes and side jobs, the demo loop, polish, then the device pass and TestFlight.
  Open-source publication can follow any time after the data loop.
- **Downloads waiting for approval** (section 3). OpenStreetMap ~130 MB. Orthophoto ~120 MB.
  10 m elevation ~2 MB in about 1,200 small requests. Surface model and 1 m terrain for the
  bridge corridors only, ~60 MB. The 3D-tree package re-streamed (8.6 GB through the pipe,
  +1.4 GB kept). No LoD2 download: the Warsaw package is already on disk.

---

## 1. The quality bar

### 1.1 What the best-reviewed small driving and city games do

| Game | What reviewers and developers single out | What it means here |
| --- | --- | --- |
| art of rally | Handling rebuilt from the studio's earlier drift game; a pulled-back top-down camera; an 80s synth soundtrack; free roam with cassettes that unlock songs and letters that unlock maps. One reviewer found free roam the best mode, another found it aimless. | Our camera is right for the genre. Collectibles must **unlock something you hear or drive** (songs, cars, districts), not just fill a counter. |
| Absolute Drift | Handling is the star: "easy to pick up, hard to master", rewarding patience. A reviewer could not see obstacles in the stark minimalist look. | The car is the game. Obstacles and the road edge must contrast with the ground, by day and at night. |
| Crazy Taxi | The time-extension loop: a goal is always on offer, good play buys more play, and the arrow always points to the next drop. Music is central. | A next thing to do within seconds, everywhere; guidance that never makes you read a map; a radio worth leaving on. |
| A Short Hike | A tiny open world built in four months. Curiosity landmarks pull you off the obvious path, with mini-games on side paths. Music layers change with the place. Low-res pixels kept readable with flat shading, no anti-aliasing and soft outlines; the pixel size is adjustable. | Our pixel pass and outlines are the same recipe; keep STYLE (pixel size). Build district ambience. Plan for players going the "wrong" way. |
| Little Kitty, Big City | A compact district with a map that shows what's left, ~200 shinies, hats and 4 to 5 hours of content. The writing is the most praised part. Criticised for loose collision and a thin core loop. | The jokes are our hats. Collision must feel tight (no driving through things). The demo needs a loop under the collectibles. |
| Mini Motorways | Minimal look; **colour coding carries the readability** (houses and cars matched by colour); a colour-blind mode; responsive ambient sound. | A reserved palette for interactive things: job rings, rivals, police and collectibles never share colours with the city. Shape as well as colour. |
| Tiny Glade | Every action answers with sound and animation; no fail state; satisfying in short sessions. | Every touch and every bump gets a sound. Failure costs seconds, never progress. |
| Islanders | Short sessions with a score that unlocks the next pack. | A ten-minute session should end with something unlocked. |
| "Juice it or lose it" (GDC 2012) and later game-feel notes | Feedback makes a flat prototype feel alive. Shakes 50 to 300 ms, decaying, on the world not the UI; particles for impacts; 50 to 100 ms hit-stop on heavy hits; used sparingly. | Sparks, dust, money pops and short camera nudges, with no hit-stop while driving (it reads as lag). A Reduce Motion switch. |
| John Nesky, "50 Camera Mistakes" (GDC 2014) | Cameras fail when they break the sense of direction, misjudge distance, lose line of sight or cause motion sickness. | Loop 2a's hold-then-ease follow camera is the right base. The occlusion ghost keeps line of sight. Never rotate faster than ~64°/s. |
| Mobile first-session guidance | Real play within about a minute; no forms, prompts or tours before the first good moment. | Driving within seconds of the first tap, with no rescue card or settings in the way. |
| Demo guidance (Steam Next Fest talks) | 15 to 30 minutes; show your best level, not your first; one question: "is it fun?"; ship it before the festival, not at it. | The demo starts in the best part of the map, shows the river, a bridge, a race, the police and the stadium in the first 15 minutes, and ends on a card. |

### 1.2 The bar for this game

"Really good quality" means every line below holds. *Today* is the state on 2026-10-28.

| # | The bar | Measured by | Today |
| --- | --- | --- | --- |
| **First minute** | | | |
| A1 | Cold launch to the title in ≤ 4 s and title to driving in ≤ 2 s on an iPhone 11 | Device stopwatch, BENCH log | Unmeasured |
| A2 | Nothing between the first tap and driving: no card, prompt, tour or "prototype" label | Screenshot at +1 s | ✗ (RESCUE CALLS card, label) |
| A3 | A goal is on screen or at the minimap's edge within 15 s of the first touch | Replay of the first minute (`--autopilot` off, scripted `--drag`) | Partly (kebab stand nearby) |
| A4 | First reward (money pop, line and sound) within 90 s; first joke within 60 s | Same replay, event log | ✗ |
| A5 | One hint only: a ghost finger if there is no input for 4 s | Replay | ✗ |
| **Feel** | | | |
| B1 | Loop 2a's steering numbers hold (settle ≤ 1.2 s, 0° overshoot, never pinned) | `check_steering.gd` | ✓ |
| B2 | Touch to visible motion ≤ 3 frames at 60 fps | `--drag` frame stamps against the car's position | Unmeasured |
| B3 | Every hit gets sound, haptic, sparks or dust and a ≤ 150 ms camera nudge (≤ 0.4 m); scraping loops a scrape | Event list in the bench log | Sound and haptic only |
| B4 | The car never comes within 20 % of a screen edge; ≥ 3 s of road visible ahead at 90 km/h | Replay of the turns | ✓ (loop 2a) |
| **Readability and art** | | | |
| C1 | A fresh viewer finds the player's car in under 1 s in 10 random default-zoom frames, by day and at night | User test | Unknown |
| C2 | Interactive things use a reserved palette (jobs orange and teal, police blue and red, collectibles gold, rivals their own colours) with ≥ 3:1 contrast against what lies under them; shape as well as colour | Pixel sampling on the screenshot set | Partly |
| C3 | A Warsaw local names ≥ 8 of 10 landmark screenshots | User test | Untested |
| C4 | Zero world errors: no road through a solid, no slab across a road, no pier in a lane, no floating part, no lump inside a landmark, no seam at a sector border | `tools/check_roads.py`, `check_drive.gd`, the render spots (4.5) | ✗ (section 4) |
| C5 | One art language: flat low-poly, pixel pass, outlines, the existing materials; no photo textures | Review | ✓ |
| **Sound** | | | |
| D1 | Every player action and game event has a sound; nothing is silent | An event list played by `--sound-check` | Mostly |
| D2 | The radio keeps priority, voices stay ≤ 6, peaks ≤ −3 dBFS | Bench bus meters | ✓ |
| D3 | Each district has a sound of its own (Old Town bells and buskers, the river, Łazienki's birds and peacocks, the stadium's hum), crossfading over ~100 m | Listening pass | ✗ |
| **Goals and loop** | | | |
| F1 | Anywhere in a hero district, an activity starts within 400 m (≤ 30 s at 50 km/h), and the minimap shows the nearest three | A grid check over the road network | ✗ (7 kebab stands, 1 station) |
| F2 | ≥ 7 activity types in the demo, each 1 to 4 minutes | Content list | 4 (rescue, race, kebab, słoiki) |
| F3 | Retry within 2 s and never lose progress | Replay | ✓ |
| F4 | Every reward feeds something: the garage, radio songs, the rival ladder, district completion | Content list | ✗ (wallet only) |
| **Exploration** | | | |
| G1 | ≥ 80 discoverables in the demo, with something within ~300 m of any main road in a hero district | Grid check | 41 (5 eggs, 5 billboards, 24 posters, 7 cards) |
| G2 | Every tier-A landmark has a card and something to do (finish line, egg or job) | List | Partly |
| G3 | District completion shows on the map | Screenshot | ✗ |
| **Performance and stability** | | | |
| H1 | Loop 2b's budgets at every view: 60 fps at the default view on an iPhone 11 at the default quality; ≥ 30 fps at the worst view; no frame over 50 ms in a 10-minute drive outside a load | BENCH on the phone | ✗ (13 to 16 fps) |
| H2 | Memory ≤ 1.2 GB (roadmap ceiling 1.5) | Perf overlay | 0.67 GB on today's map |
| H3 | 20 minutes of play without thermal throttling (the 30 fps cap from 2b allowed) | Xcode energy gauge | Unmeasured |
| H4 | Zero script errors in a 30-minute autopilot soak; the save survives a kill | Soak log | Unmeasured |
| **Demo shape** | | | |
| I1 | 30 to 60 minutes of directed play, an end card, then free roam | Playthrough | ✗ |
| I2 | The first 15 minutes show the Palace, the river, a bridge, a race, the police and the stadium | Playthrough | ✗ |
| **Comfort** | | | |
| J1 | Touch targets ≥ 44 pt and text ≥ 11 pt (loop 2e) | Screenshots at three phone sizes | ✗ (24 pt, 8 pt) |
| J2 | Polish with English subtitles; colour is never the only cue | Review | Partly |
| J3 | Left-handed layout; Reduce Motion (no shakes, no VHS wobble) | Settings | ✗ |

---

## 2. The demo area

### 2.1 The box

**Decision (the user, 2026-10-29): a smaller demo at higher quality, with the Old Town.** The
demo box is **south 52.2183, west 20.9780, north 52.2525, east 21.0560** (the east edge moved
from 21.0500 in loop 3d-1, the user's yes, so Most Łazienkowski and Trasa Łazienkowska's east end
are whole): map metres (today's origin) x −3,136 to +2,182, z −2,046 (north) to +1,736 (south),
**5,318 × 3,782 m = 20.1 km²** (3.2× today, 67 % of the 30 km² below), 12 × 8 = 96 sectors of
512 m. It is today's map
grown west to Rondo Daszyńskiego (its towers, Warsaw Spire, the Uprising Museum, Hala
Mirowska), south to MDM (Plac Konstytucji, Hala Koszyki, Plac Zbawiciela, the Sejm) and north
to just past the Barbakan: Centrum Nauki Kopernik and the boulevards' steps, the university
library, the whole of Most Świętokrzyski (which today ends at the rim) and Most
Śląsko-Dąbrowski with the W-Z tunnel, Krakowskie Przedmieście, Plac Zamkowy and the Royal
Castle, the Old Town and its walls, Muranów (POLIN, Plac Bankowy) and on the Praga side the
bears by Al. Solidarności and Ząbkowska. The east edge is 21.056, past the stadium, Most
Łazienkowski's east end (21.053) and Rondo Waszyngtona; no bridge is cut (Most Gdański begins at
52.2599). The user first chose a 14.5 km² box (north
52.2450), then moved the whole north edge up for the Old Town rather than a tip over it alone.
All of it lies inside the data already downloaded for the box below (no new downloads).
**Tier A** becomes: Warsaw Spire, MDM's Plac Konstytucji, St Alexander's at Plac Trzech Krzyży,
Kopernik and its planetarium, Most Świętokrzyski's pylon, the Sejm, the Royal Castle with Plac
Zamkowy and Sigismund's Column, the Old Town Market Square and the Mermaid, the Barbakan and
the walls, St Anne's and the Copernicus statue (10); the bears are the cheap egg. **Structures
(4.6) inside**: the W-Z tunnel and Most Śląsko-Dąbrowski join the list. **After the demo**
(section 9): Łazienki, Arkadia, the zoo (Most Łazienkowski and Trasa Łazienkowska are inside
since the east edge moved; their structures are loop 3e's). The police
spec's city guards keep the Old Town as their zone. The table and notes below are the earlier
30 km² plan, kept for its research; where they differ, this paragraph wins.

| | South | West | North | East |
| --- | --- | --- | --- | --- |
| Latitude / longitude | 52.2085 | 20.9780 | 52.2595 | 21.0560 |
| Map metres (today's origin) | z = +2,820 | x = −3,136 | z = −2,820 | x = +2,182 |
| What sets it | Łazienki: the Palace on the Isle is 720 m inside; only the park's southern tip with Belweder (~150 m) stays out (see the notes below) | Rondo Daszyńskiego (−2,727, 420) + ~400 m for its towers and the Warsaw Uprising Museum | Arkadia (−2,686, −2,565; its outline ends at 52.2587) + ~90 m. Most Gdański's ways begin at 52.2599, so the edge stops just short of it and no bridge is cut | Rondo Waszyngtona and Most Łazienkowski's east end (21.053) + ~200 m |

Size: **5,318 × 5,639 m = 30.0 km²**, against today's 3,545 × 1,769 m = 6.3 km² (4.8×).

Notes.

- **The origin stays at 52.2340 N 21.0240 E.** Today the bake sets it to the bounding box's centre
  (`bake_osm.py` LAT0/LON0). Uncoupling the two (an `ORIGIN` constant) keeps every hard-coded
  coordinate valid: `GUGIK_NOT_TREES`, `EXTRA_KEBAB`, landmark search boxes such as the
  Poniatowski towers' `Rect2(910, -165, 40, 60)`, test `--at=` spots and the README. The
  flat projection's error at the far corners is under 2 m.
- **South edge.** 52.2085 keeps the area inside the GUGiK sheets on disk (the 1:5000 sheet row
  boundary lies at 52.2083). Moving it to 52.2065 would take in all of Łazienki and Belweder, at
  the cost of 3 more LoD2 sheets (already in the zip) and 6 more tree sheets (+1.2 GB). This is
  an open question.
- **Every river bridge is whole inside the box**: Śląsko-Dąbrowski, Świętokrzyski,
  Poniatowskiego, the railway bridge and Łazienkowski. That retires the backlog item about Most
  Świętokrzyski ending in the air at the rim.

**Baked in loop 3d-1 (2026-10-29)** from the data on disk (README "Map data" and "Loop 3d-1: the
demo map"): `bake_osm.py` `BBOX` is this box and `ORIGIN` the old origin; 99 sectors (i −7..3,
j −5..3; 88 for the box and a sliver row for what reaches past its north edge); every check's finding in the new area is fixed by an existing rule or allowlisted with
its place and reason (most of them "loop 3e", the structures of 4.6). The first bake (east edge
21.050) cut Most Łazienkowski mid-river; the user moved the edge to 21.056. The ground is the
1 m NMT of the whole box (fetched with the user's yes; README "Loop 3d-1").

**Map north (2026-10-31, the user's ask: Rondo Radosława with its flag, Arkadia and the Forest
tower).** The map grows north on its west side only: `bake_osm.py` `BBOX_NORTH` = south 52.2525
(the box's north edge), west 20.9780, north 52.2591, east x −1,706.12 (20.99897, a column of the 10 m
terrain lattice): map metres x −3,136 to −1,706, z −2,775 to −2,046, 1,430 × 730 m = 1.04 km² on
top of the box (21.2 km² in all, 112 sectors: i −7..−4 of row j −6 are new). The map is the box's
bounding rectangle without its north-east corner (centrum.json `outside`, `tools/map_shape.py`).
North: Arkadia's outline (52.2587) and its ring road Kłopot + 20 m, short of the ring railway and
Dworzec Gdański's platforms; the viaducts of Jana Pawła II and Andersa over the railway are cut at
the edge (check_roads C6 allows the rim), Dworzec Gdański's footbridges, which the edge cuts, are
left out. East: past Andersa, so Słomińskiego closes the street net (the roundabout, Słomińskiego,
Andersa, back south into the box). Inside: Rondo Radosława, Arkadia, Forest, Okopowa,
Powązkowska and Burakowska to the west edge, Jana Pawła II from the box to its viaduct,
Słomińskiego to Andersa, Inflancka, Stawki's north side, Muranów north. docs/DEVELOPMENT.md "Map north".

**Hand-over for the landmarks lane (map north).** The map draws these from LoD2/OSM today; each
is registered so a site can replace it (`bake_sectors.py` `SITE_NAMES` / `SITE_AREAS`: their
parts are in the index's `site_parts` for the prebuilt city). Heights: GUGiK's 0.5 m surface model
(`data/raw/demo/gugik/nmpt05_sites/`, `tools/fetch_demo.py nmptsites`) over the 1 m NMT.

| Site | OpenStreetMap | Where (map metres) | Height (NMPT) | Drawn today |
| --- | --- | --- | --- | --- |
| Arkadia | way 41927532 "Westfield Arkadia" (building=retail, 3 levels, layer 1, roof:shape many) | outline x −2,844..−2,539, z −2,730..−2,402; centre (−2,708, −2,520) | ground 106.8 m a.s.l.; roof ~21 m (p90), top 37 m at (−2,778, −2,470) | one LoD2 model (2018); the OSM outline hidden |
| Arkadia's roof car park | way 91341678 (service=parking_aisle on the roof, no layer) and its ramps 91341665, 1343067224, 1343067227 (bridge=yes) | along the roof, x −2,836..−2,535 | on the roof | left out of the bake (drawn flat it ran through the mall); the ramps' feet on Błońska stay. DEMO 6.4's car-park race needs it modelled |
| Forest (tower and office block) | office block way 1507720304 (building=office, unnamed; landuse "Forest" 1087209842); parts 923445779 (the tower: 28 levels, height 120, glass, flat roof), 923445778 (8 levels), 923445777 and 923445776 (6 levels) | block x −3,097..−2,931, z −2,447..−2,346, centre (−3,011, −2,392); the tower x −2,990..−2,938, z −2,384..−2,346, centre (−2,959, −2,366) | ground 105.6 m; the tower's roof ~120 m, top 124.7 m at (−2,971, −2,357); the 8-storey part's roof 44 m (a 107 m spike on it at (−2,948, −2,380), a crane or a mast), the others' 33 and 32 m | the parts as OSM blocks (the 2018 LoD2 sheds there are left out: `bake_gugik.py` NEWER_SHARE) |
| Rondo Radosława | ring ways 4840968, 228882920, 228882922, 228882925, 229104868, 229104869, 303165578, 306462714 (junction=circular, secondary, 2-3 lanes); trams cross the island | ring centre (−2,833, −2,292), the ring x −2,890..−2,777, z −2,348..−2,236 (~55 m radius) | ground 106.2 m | road, lanes and trams; the island is bare ground |
| The flag mast | not in OpenStreetMap | (−2,850, −2,295), in the island's west part, beside the trams | a 57.8 m thin column in the surface model (cells at 52-58 m within 2 m of it) | nothing: the island is left for the landmarks lane (no placeholder from OSM) |

### 2.2 What is inside, and what exists today

Positions are approximate map metres. *Built* means hand-built in `landmarks.gd`; *lump* means a
LoD2 or OSM extrusion; *outside* means beyond today's map. Tiers: **A** must be hand-built for the
demo, **B** next, **C** keep the LoD2/OSM shape with a better material.

| Landmark | Where | Today | Demo |
| --- | --- | --- | --- |
| Palace of Culture, Złote Tarasy, Rotunda, Varso, Warszawa Centralna | centre | Built | Keep (check against the new streaming) |
| Stadion Narodowy | 1,459, −641 | Built | Keep; the stands are the final race's finish |
| Most Poniatowskiego and its four towers | 186 to 1,450, 104 to −320 | Built, with the defects in 4.3 | Fix (loops 3a and 3b) |
| Royal Castle, Plac Zamkowy, Sigismund's Column | −600, −1,537 | Outside | **A** |
| Old Town Market Square and the Mermaid | −804, −1,736 | Outside | **A** (pedestrian zone, see 5.2) |
| Barbakan and the walls | −1,029, −1,902 | Outside | **A** (cheap: walls and towers) |
| Krakowskie Przedmieście: St Anne's, Presidential Palace, University gate, Copernicus statue | −614 to −389, −1,393 to −509 | South part inside as lumps | St Anne's and the Copernicus statue **A**, the rest **B** |
| Nowy Świat | −150, −200 to 400 | Inside, lumps | **C** + shop-front neon |
| Plac Trzech Krzyży and St Alexander's rotunda church | −82, 630 | Inside, lump | **A** (small and iconic) |
| The Sejm | 307, 984 | Just outside | **A** (the semicircular hall) |
| Łazienki: Palace on the Isle, the amphitheatre, the ponds | 770, 2,101 | Outside | Palace and water **A**, amphitheatre **B** |
| Chopin monument, Ujazdowski Castle, the Botanic Garden | 218, 1,902 / 477, 1,659 | Outside | **B** |
| Copernicus Science Centre with the planetarium, the boulevards and their steps | 320, −874 | Cut by today's north rim | **A** |
| University library's green roof | 61, −907 | At the rim | **B** |
| Most Śląsko-Dąbrowski + the W-Z tunnel under Plac Zamkowy | −170, −1,659 | Outside | Structure work (4.6) + **B** look |
| Most Świętokrzyski and its single pylon | 852, −940 | Cut at the rim | Pylon **A** |
| Most Łazienkowski and Trasa Łazienkowska | 1,704, 962 | Outside | Structure work (4.6) |
| Rondo Daszyńskiego towers: Warsaw Spire, The Warsaw HUB, Skyliner, Warsaw UNIT, Mennica Legacy, Generation Park | around −2,700, 130 to 550 | Outside | Spire **A**; the rest **B** (OSM parts + curtain-wall material, as Varso was) |
| Warsaw Uprising Museum | −2,925, 188 | Outside | **B** |
| Arkadia and Dworzec Gdański | −2,686, −2,565 / −2,045, −2,621 | Inside since map north (2026-10-31): Arkadia as LoD2; the station's platforms just past the north edge | Arkadia **B** (a big low mall and its car parks); the station **C** |
| Rondo Radosława and its flag, the Forest tower | −2,833, −2,292 / −2,959, −2,366 | Inside since map north: the ring drivable, the island bare; Forest as OSM parts | The flag **A** (cheap: a mast and a flag), Forest **B** (2.1 "Map north" hand-over) |
| Hala Mirowska, Hala Koszyki | −1,909, −299 / −770, 1,238 | Outside | **B** (brick halls; kebab and market jokes) |
| POLIN museum, Plac Bankowy, Teatr Wielki | −2,113, −1,714 / −1,568, −1,106 / −948, −1,039 | Outside | **C** |
| Plac Zbawiciela | −648, 1,592 | Outside | **B** (the round plaza, a café-district egg) |
| Praga: the zoo, the bear enclosure by Al. Solidarności, Ząbkowska | −68, −2,433 / 170, −1,824 / 1,159, −1,902 | Outside | The bears **A** (an egg), the rest **C** |
| Muzeum Narodowe | ~0, 120 | Inside, lump | **C** |

Tier A is 12 landmarks. Budget: building material only (no new draw calls; UV2.x codes as in
v0.8), ≤ 40k vertices each, ≤ 400k in total.

### 2.3 Districts

The districts are used for content, completion and naming sectors. **Hero** districts get the
full density of jobs and discoverables.

| District | Roughly | Character for the game |
| --- | --- | --- |
| Śródmieście Centrum (hero) | the Palace to Rondo Dmowskiego | Today's heart: towers, Patelnia, trams, the Palm |
| Trakt Królewski (hero) | Krakowskie Przedmieście, Nowy Świat, Plac Trzech Krzyży | Old façades, mostly closed to private cars: city guards |
| Stare Miasto (hero) | Old Town, New Town, Plac Zamkowy | Pedestrian lanes, the W-Z tunnel, tourists, horse carriages as a joke |
| Powiśle and the boulevards (hero) | the escarpment to the river | Bars on the river, the Wisłostrada tunnel, Copernicus |
| Praga and the stadium (hero) | the right bank | Seba's home turf, the stadium, the bears, old tenements |
| Ujazdów and Łazienki | the Sejm, embassies, the park | Quiet, rich, park guards, peacocks |
| Wola: Rondo Daszyńskiego | the new towers | Glass towers and "new Mordor" office jokes |
| Muranów and Arkadia | blocks, the mall, Dworzec Gdański | Shopping-mall car park races, the second station for słoiki |

### 2.4 One map or sectors: one map, streamed in sectors

**Why it cannot stay one resident map.** Today's 6.3 km² is 6.07 M vertices, a 36 MB `city.scn`,
248 MB static plus 423 MB video memory on the iPhone, and 6,700 to 7,700 draw calls before loop
2b. At 4.8× the area and the same density that becomes ~30 M vertices, ~175 MB of scene and ~2 GB
of video memory. That is over the 1.5 GB ceiling, and the runtime (editor) build would grow from
6.6 s to over 30 s. Draw calls grow with what is on screen, not with the map, but only if
off-screen sectors are not in the scene at all.

**The layout.**

- **Sectors of 512 m**, keyed `floor(x / 512), floor(z / 512)` from the origin. The demo needs
  12 × 12 = 144, about 10 of them slivers or open water. 512 m matches loop 2b's
  `INSTANCE_TILE` (512 m) and holds 2 × 2 of its 256 m `chunked_surface` tiles.
- **Full detail**: the 3 × 3 sectors around the camera's focus, plus any sector the view's
  ground footprint touches (grown by 128 m). That is 9 to 12 sectors, about 2.4 to 3.1 km²,
  half of today's resident map. Hysteresis: load when the focus comes within 192 m of a sector
  edge; unload two sectors away.
- **Proxy for every sector**: one mesh and one material each. Buildings are footprint prisms with
  roof colours (~12 triangles each), the ground is a coloured 32 m grid, plus water and main roads
  as flat strips, simplified landmark silhouettes and tree "blobs" merged in. No shadows, no
  props, no colliders. Expected ≤ 15k triangles and ≤ 0.3 MB per sector: at most 144 draw calls
  if all were on screen, ~20 to 40 in practice. Hand-off by Godot visibility ranges with fade
  mode **Disabled** (hysteresis only): alpha fades force transparent rendering, which the
  Mobile renderer pays for.
- **Global, always loaded** (`map/index` resource): the lane graph (~5k nodes, ~7.5k edges),
  deck and tunnel pieces, the 10 m terrain (~300k heights), the helicopter's 4 m roof grid (1.9 M
  cells: 3.8 MB as decimetres in uint16), the landmark pick grid, points of interest, addresses
  and the minimap. The minimap becomes a pre-rendered image at 4 m per pixel, ~1.3k × 1.4k,
  instead of 2b's single 2D mesh, which would be 5× bigger.
- **Per sector, streamed**: meshes (ground, roads and markings, buildings, landmarks), the
  MultiMeshes (trees, lamps, parked cars, props), colliders (walls, rails, parapets, piers) and
  the sector's slices of the AO, light and water maps. Those maps are 61, 61 and 30 MB for the
  whole area: no longer one texture each, but 0.25 to 0.5 MB per sector.

**What changes in the code.**

| Part | Change |
| --- | --- |
| `bake_osm.py` | Writes `index.json` (global) and `sectors/<i>_<j>.json` (features by sector; a way crossing a border goes to both with its full geometry, so kerbs and markings meet) |
| `map_builder.gd` | `build_sector(i, j)` builds one sector from its JSON. Triangles are filed by centre as now, so geometry may overhang a border by a few metres, invisible because neighbours load together. Landmarks go to the sector of their centre; colliders are per sector |
| `game/tools/bake_city.gd` | Loops over sectors and writes `map/sectors/s_<i>_<j>.scn` + `map/proxies.scn` + `map/index.res` instead of one `city.scn` |
| New `sector_streamer.gd` | `ResourceLoader.load_threaded_request` for the next ring; `instantiate()` and `add_child()` spread so the main thread spends ≤ 3 ms a frame on streaming; unload with `queue_free`; never stall: draw the proxy until the sector is in |
| The editor path | The same streamer, with a build-on-demand back end: builds the sectors around the spawn from JSON (about 9 × 0.26 km², so ~2.5 s instead of over 30 s) |
| Traffic, rivals, missions | Unchanged in shape. They already live on the global lane graph and only put cars in a band round the view. A rival far away is simulated on the graph without geometry |
| Physics | Colliders exist only in loaded sectors; the car is always inside the full-detail ring. The helicopter uses the global roof grid, as now |

**Costs.** ~140 sector scenes of ~1.5 MB each ≈ 210 MB in the app (today 36 MB). Target app size
≤ 300 MB. Resident memory, with ~10 full sectors + 144 proxies + the index, should land below
today's 0.67 GB. That is the H2 check.

**Risks.**

1. Instancing hitches on the phone: measure with the BENCH card, and split big sector scenes into
   2 to 4 parts if needed.
2. Seams in kerbs, markings and AO at borders: render spots straddling borders, pixel-diffed
   against a monolithic build of today's map.
3. The helicopter at 58 m sees much further than the car: the proxies carry that view; check
   against image 4 of the user's screenshots.

**Done in loop 3c (2026-10-29), on today's map** (README "Sectors and streaming"):

- The split is `tools/bake_sectors.py` (after the chain; bake_osm.py unchanged): `index.json` and
  32 `sectors/<i>_<j>.json` (ways, areas and buildings within 48 m, point things within 8 m, a
  floating part's supports and each building's shop-sign surroundings, LoD2 buildings as vertex
  ranges of `lod2.bin`). The invariants hold over the sectors (`check_map_data.py`).
- `map_builder.gd` `build_sector` keeps the triangles, instances and collider faces whose centre
  lies in the sector: the 32 sectors are the whole city vertex for vertex
  (`game/tools/check_streaming.gd`). Landmarks are built in every sector they reach, triangles
  filed by tile like the rest (not whole in the sector of their centre), with one global site
  list and info card ids.
- `tools/bake_city.gd` writes `sectors/s_<i>_<j>.scn`, `proxies.scn`, `index.res` and
  `shared/*.res`; `city.scn` is gone; the export carries no JSON map data.
- Proxies: one mesh, one material per sector, from the index (32 m ground grid, main roads, a
  roof-grid skyline, tree blobs), ≤ 14.7k triangles and 84 KB.
- `sector_streamer.gd`: as above, with one change: **the view needs a sector when its box up to
  its tallest roof (grown by 128 m) meets the frustum**, not only its ground footprint, so a
  tower two sectors off is in full detail; proxies only cover a sector while it loads.
- The AO, lamp-light and surface maps are **not** sliced: one texture each, shared (the post
  pass and the vehicles sample them anywhere on screen). Loop 3d needs the resident window
  (docs/BACKLOG.md "From loop 3c").
- The minimap stays one 2D mesh (today's map); the image is loop 3d's.
- Risks: (1) instancing hitches: on the Mac a MultiMesh node costs 0.1–4 ms to add (by how busy
  the Mac is), the phone must measure it; (2) seams: 10 spots, 5 on borders, ≤ 0.015 % of the
  pixels differ at 2868×1320 (the minimap's random markers), ≤ 0.2 % at 1792×828 (a few
  shadow-edge texels); (3) the helicopter: the view test loads what it sees.

---

## 3. The data it needs

The bounding box is wider in every direction, so every source is fetched again. Nothing has been
downloaded. **Each line needs the user's yes.** Sizes are estimates scaled from today's files.

### 3.1 Downloads to approve

| # | What | Source | Size | Time | Licence | Re-run after it |
| --- | --- | --- | --- | --- | --- | --- |
| D1 | OpenStreetMap, everything in the box: roads, buildings, trees, lamps, signals, POIs (police stations, kebab places, addresses), relations with their members | Overpass API `https://overpass-api.de/api/interpreter`, as **9 tiles** (3 × 3, ~3.4 km² each) merged by element id. Per tile: `[out:json][timeout:300]; nwr(S,W,N,E); (._;>;); out body;` | ~130 MB JSON (today 25 MB for 6.3 km²), ~1 M elements | 10 to 25 min with back-off (the public server often answers 502/504) | ODbL (credit already in game) | bake_osm, then everything below |
| D2 | Aerial photo (roof colours, the overlay checks) | GUGiK WMS `https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/HighResolution`, as in `fetch_gugik.py`, in **2 × 2 tiles** of ≤ 4,096 px (the service's limit) at today's ~0.87 m per pixel | ~120 MB as BMP (~6,100 × 6,500 px); ~40 MB if fetched as PNG | 3 to 10 min | GUGiK, free use (Prawo geodezyjne art. 40a) | bake_gugik |
| D3 | 10 m elevation grid (the terrain mesh) | GUGiK `https://services.gugik.gov.pl/nmt/?request=GetHByPointList`, as in `fetch_gugik.py` | ~300k points in ~1,200 requests of 250; ~2 MB JSON | 10 to 20 min | as D2 | bake_gugik (terrain), bake_osm (decks) |
| D4 | **New: surface model (NMPT, DSM) at 0.5 m for bridge, viaduct and tunnel-portal corridors only** (~30 structures, ~3 km²). It holds the true deck and abutment heights the bare-earth grid lacks (4.4) | GUGiK NMPT WCS, GeoTIFF, ≤ 10 km² a request. The endpoint is published on `https://geoportal.gov.pl/en/data/digital-surface-model-dsm`; take the EVRF2007 layer, the same height system as the NMT service | ~50 MB (12 M floats) | 5 to 15 min, ~15 requests | as D2 | bake_roads (deck heights) |
| D5 | **New: 1 m bare-earth (NMT) for the same corridors and the escarpment streets** (abutment edges, retaining walls, ramp starts) | GUGiK NMT WCS, GeoTIFF; endpoint on `https://www.geoportal.gov.pl/en/dane/numeryczny-model-terenu` | ~15 MB | 5 min | as D2 | bake_roads |
| D6 | GUGiK 3D trees, LoD1 2023: **7 more sheets** at 1:2500 (the six south quarters of N-34-138-B-b-4-4, N-34-139-A-a-3-3 and -3-4, and the missing N-34-138-B-d-2-2-3) | `opendata.geoportal.gov.pl/InneDane/Drzewa3D/LOD1/2023/14/1465.zip`, streamed through `tar` keeping only those sheets, as before | **8.6 GB through the pipe** (no resume; the last run timed out once), +~1.4 GB kept (23 sheets today: 4.6 GB) | 10 to 60 min, line-dependent | CC BY 4.0 (credit in game) | bake_trees_gugik, then bake_osm |

Total kept on disk: ~1.8 GB more. Total transfer: ~9 GB, of which 8.6 GB is the tree package.
Without D6 the north strip (Old Town north, Muranów, Arkadia) and Rondo Daszyńskiego's west side
fall back to OSM trees. The code supports that, but it looks thinner.

Optional, not recommended now: the 1 m NMT for the whole area (~125 MB, four requests), worth it
only if loop 3d shows the 10 m terrain is too coarse beyond the corridors.

### 3.2 No download needed

- **LoD2 buildings.** `data/raw/gugik/1465_gml.zip` (112 MB, all of Warsaw) is on disk. Unpack
  3 more 1:5000 sheets (N-34-138-B-b-4-4, N-34-139-A-a-3-3, N-34-139-A-a-3-4; ~120 MB) with
  `tools/find_sheets.py` given the new box, which it already accepts as arguments 3 to 6.
- Audio, music and every other asset are made by the tools in `tools/`.

### 3.3 Bake order after the downloads

`bake_osm.py` reads `terrain.json` for the decks, and `bake_gugik.py` reads `centrum.json` to
decide which OSM buildings LoD2 covers and writes `terrain.json`. With a new box this is a
circle. Loop 3d should split the terrain out into its own step (`bake_terrain.py` from
`terrain_10m.json`). Then the order is:

1. `fetch_gugik.py`, extended to D2 tiles, D3, D4 and D5.
2. `bake_terrain.py`.
3. `bake_trees_gugik.py`.
4. `bake_osm.py`, including `bake_roads.py`.
5. `bake_gugik.py`.
6. `bake_ao.py`, `bake_lights.py`, `bake_water.py`.
7. `bake_city.gd`, now per sector.
8. `check_roads.py` and `check_landmarks.gd`.

Expect the Python bakes to take minutes, not seconds. Some loops in `bake_roads.py` are
quadratic, for example deck grouping and footway-to-deck matching; give them a spatial grid.

---

## 4. Roads and overpasses

### 4.1 How heights work today

*(Before loop 3a. What loop 3a changed is in 4.7.)*

- The terrain is GUGiK's bare-earth model sampled every **10 m** (`terrain.json`). Bridges and
  viaducts are not in it, but abutments, embankments and the open ramps of tunnels are.
- Every OSM way tagged `bridge=*` becomes a **deck piece**. Its height is the larger of two
  things: the straight line between its two end heights, or the clearance envelope (5 m over
  roads, rails and trams, 7.5 m over water, falling away at 6 %). An end that touches a ground
  road is **pinned to the terrain height at that point**, and the deck may leave it at most 12 %
  (`bake_roads.py` `solve_decks`).
- Ways between two bridge ways that are not tagged `bridge` are ground roads and follow the
  10 m terrain. OSM splits bridges exactly at the abutments.
- The car drives the highest surface it can step onto (`drive_height`). Traffic lanes use the
  highest deck over the point on bridge edges and the terrain elsewhere (`lane_graph.gd`
  `_sample_heights`). Tunnels (`tunnel=yes`, or a negative `layer`) are dropped from the roads
  and from the lane graph (`bake_osm.py` lines 151 and 1065).
- Under every deck there is a **1.3 m** concrete slab. Piers stand every 38 m wherever the deck
  is more than 2.5 m up, whatever is below them, and have no collider
  (`_build_bridge_structures`).

### 4.2 The user's screenshot is the east end of Most Poniatowskiego

The brief places it at the west end over Wybrzeże Kościuszkowskie. Three things say it is the
**east (Praga) end over Wybrzeże Szczecińskie**:

- The minimap shows the river to the **left** of the car with the default camera's north (the
  same orientation as the render at `--at=1445,-301`).
- The orange stand marker to the car's right is the Narodowy kebab stand at (1,554, −327).
- The green median with tram tracks to the right is Al. Poniatowskiego's.

What it shows is defect classes 1, 2, 3 and 5 below, all at that spot:

- The river span's end is pinned at −13.5 m, while the abutment road east of the towers is at
  −6.3 m (70 % over 6 m).
- Wybrzeże Szczecińskie passes under the deck with **1.3 m clearance**, so the bus drives through
  the slab.
- A pier stands 0.4 m from that road's centreline.
- The towers stand on the 10 m grid's slope.

The west end has the same classes, slightly milder (renders: `--at=905,-128` and
`--at=1445,-301`, default zoom, Fixed camera).

### 4.3 Defects found (survey of today's map)

| Class | Where (map m) | What | Count |
| --- | --- | --- | --- |
| **1. Abutment humps** | Poniatowski west abutment, 850 to 940, −90 to −150 | The viaduct ends at −10.6 / −10.9 m, the abutment roads sit at −4.7 to −5.1 m and the river span starts at −11.9 / −12.2 m. Al. Jerozolimskie climbs 5.5 m in 14 m at (855, −101); Most Poniatowskiego drops 7.2 m in 28 m at (913, −122); 64 % over 7 m at (857, −123) | 7 roads |
| | Poniatowski east abutment, 1,417 to 1,450, −290 to −305 | Span end at −13.5 m, Al. Poniatowskiego 70 % over 6 m at (1,429, −295); links at (1,488, −302) 38 % and (1,535, −158) 19 % (deck 3) | 4 roads |
| | The viaduct's west end at the escarpment, (187, 118) | Al. Jerozolimskie 77 % over 4 m (3.3 → 0.1 m); two footway decks end 2.1 to 2.3 m in the air at (185, 100) and (191, 120) | 1 road, 2 footways |
| | Most Świętokrzyski, (503, −725) | 20 % at the deck's foot | 1 |
| **2. Decks too low: slab across the road** | (1,410, −285) Wybrzeże Szczecińskie under the Poniatowski span | Clearance 1.3 m | 29 samples |
| | (943, −145) the link under the span's west end | 2.0 m | 24 |
| | (425, −73) Kruczkowskiego and (534, −177) Solec under the railway bridges (decks 17, 16) | 1.9 m each | 17 + 8 |
| | (822, −86) Aleja 3 Maja under a footway deck coming down from the viaduct; (970, −99) Wioślarska under a footway deck by the ramps | 1.3 m; 0.5 m | 6 + 10 |
| | (671, −336) and (761, −399) Wybrzeże Kościuszkowskie under the railway decks 15 and 14 | 3.1 m; 4.6 m | 9 + 1 |
| | (−1,485, 773) a service road under the Jana Pawła II viaduct; (−1,356, 754) under footbridge 9; (840, −122) a link under deck 5 | 3.1, 0.5 and 4.0 m | 18 + 3 + 1 |
| | Total | 126 samples in 11 places (rule: 0.4 m < clearance < 4.6 m, where a 3.2 m bus meets the slab) | |
| **3. Piers in roads and tracks** | (470, 10) **in the middle of Kruczkowskiego** (0.0 m off its line); (1,394, −298) Wybrzeże Szczecińskie (0.4 m); (417, −54) Kruczkowskiego (railway bridge); (546, −175) Solec; (762, −402) and (679, −332) Wybrzeże Kościuszkowskie; (1,145, −714) Wybrzeże Szczecińskie; (958, −139) Wioślarska; (1,322, −274) a service road; (−1,504, 672) Rondo Czterdziestolatka; (−1,493, 750) a service road | Piers have no collider, so cars pass through them | **25 of 161 piers** |
| **4. Tunnels dropped** | The Wisłostrada tunnel (OSM ways 4840733 and 4937130). South portal at (637, −554): Wybrzeże Kościuszkowskie dives into a 6 m deep, 10 m wide trench in the terrain and stops dead | No road, no lane graph, no traffic | 2 carriageways |
| | The short link under the west abutment (way 237351918, at 838, −122) | A gap in the ramp system | 1 |
| | Service ways with `layer=-1` (garage ramps) | Dropped | 5 |
| **5. Landmark seating** | The Poniatowski towers | Bases on the 10 m grid (−9.9 to −13.2 m at their centres) while the roads beside them sit at −4.7 to −13.5 m. Plinth to "the highest surface within 14 m" + 1.2 m. Each tower is mapped twice (outlines ~6 m apart). Outlines touch the carriageway corridors (0.4 to 1.4 m, plus a 0.6 m plinth). A curved grey building is fused into the south-east tower's base (render at `--at=1445,-301`) | 4 towers |
| **6. Deck ends at the rim** | Most Świętokrzyski at z = −884.6 | Six pieces end 6 to 7.7 m in the air | 6 |
| **7. Steep ramps from the terrain** | Garage entrances: the service way follows the terrain into the ramp | 78 service roads over 15 % (worst 86 % at 1,627, −690); non-service, besides class 1: Złota 30 % at (−808, 100) and Oboźna 17 % at (−114, −617) | 78 + 2 |
| **8. Traffic hops** | Lane edges with a > 1 m step inside 4 m, all at the class-1 spots | Cars visibly jump | 14 edges |
| | A latent trap: bridge lanes take the *highest* deck over the point, not their own | None today; a sure bug in stacked interchanges (Trasa Łazienkowska) | 0 |
| **9. Buildings through decks** | Centrum Handlowe Arkada under the Poniatowski viaduct at (577, −19) | The 7.6 m arcade stands under a deck only 5.3 m up, so its roof pokes 2.3 m through Al. Jerozolimskie | 1 |

Found clean: shared road joints (0 jumps over 0.3 m, because ends are pinned), lanes on bridges
(0 of 2,084 samples fall off a deck), carriageway areas on decks (0 floating).

### 4.4 Root causes and the fixes

Loop 3a status: **R1, R3, R4, R8, R9 done in the bakes** (see 4.7). Loop 3b: **R2, R5, R6, R7,
buildings under decks and the tunnels done** (see 4.8); the rim's walls wait for the bigger map
(no bridge crosses the new box's rim).

| Root cause | Classes | Fix | Where |
| --- | --- | --- | --- |
| **R1. Ends pinned to a blurred grid.** OSM ends `bridge=*` at the abutment, where the 10 m grid is half-way down the abutment's wall, so the pins are too low and the abutment between them is a hump | 1, 2, 5, 8 | **Structure chains**: a bridge way plus the non-bridge drivable ways that join it to another bridge way within 150 m, or that lie on `embankment=yes`, or where the terrain under the way stands > 2 m above the terrain 15 to 25 m to either side, solved as **one profile**. Pins only where the chain meets ordinary streets, taken from a robust ground value (the median of the 1 m NMT in a 6 m disc, D5) instead of the bilinear 10 m value | `bake_roads.py` |
| **R2. No true deck heights.** The solver guesses: the line between pins, lifted by clearance | 1, 2, 9 | **Sample the surface model (D4) along each deck**: every 2 m, the 30th percentile over the carriageway's width (the deck is the low envelope; cars, lamps and parapets stand above it), rejecting cells where surface ≈ bare earth (no structure) or where trees are scanned. Smooth to ≤ 6 % with ±1 m tolerance, then apply clearance as a **hard** minimum. Fallback without D4: the chain solver alone | `bake_roads.py` |
| **R3. Clearance is soft.** `min(h, pin + 12 % × s)` overrides the clearance envelope | 2 | When clearance cannot be met within the end grade, **lower the road underneath** (an underpass dip up to 2 m, 8 % ramps, as real underpasses do) and log it; any remaining case fails the bake | `bake_roads.py` + a road height profile for ground roads under decks |
| **R4. Tunnels and cuttings are dropped** | 4 | Keep `tunnel=yes` drivable ways as **tunnel pieces** (like decks, below the terrain: profile = terrain − 6 m cover, portal ramps ≤ 8 %, pinned where they meet open road). Keep `layer<0` ways that are not tunnels (cuttings) as ordinary roads. Write `tunnels` to the map file and `tn` on roads and graph edges | `bake_osm.py`, `bake_roads.py` |
| **R5. Piers placed blind** | 3 | Slide each pier candidate up to ±12 m to the nearest spot where its footprint is ≥ 1 m clear of every ground road (half-width), tram and rail bed and kerb. If none is clear, skip it, or span a wide road with a **portal frame** (two legs outside the road, a cross-beam). Piers get colliders | `map_builder.gd` `_build_bridge_structures` |
| **R6. Abutments have no walls** | 1, 5 | Where a chain meets the ground at an abutment, draw retaining walls from the deck edge to the terrain. The hump becomes a believable stone or concrete wall, and the towers stand on it | `map_builder.gd` |
| **R7. Towers seated on the grid** | 5 | Dedupe the outlines. The base sits at the lower road level beside the tower (the boulevard); the shaft starts at the deck height + 1.2 m from the chain profile. Keep the footprint ≥ 0.5 m outside the deck corridor (l/r + parapet) by trimming the side that faces it. Grow the landmark zone 6 m so fused OSM and LoD2 lumps are removed | `landmarks.gd` |
| **R8. Lanes don't know their deck** | 8 | Write each graph edge's deck group (`dk`) or tunnel (`tn`), and sample lane heights from that piece only, never "the highest deck over the point" | `bake_osm.py` `bake_graph`, `lane_graph.gd` |
| **R9. Garage ramps follow the terrain** | 7 | End a service way where the terrain falls > 2 m below its start within 30 m (it is entering a garage): put a garage-door prop there and drop the rest | `bake_osm.py` |
| Buildings under decks | 9 | Cut a building to the slab's bottom − 0.5 m where its footprint lies under a deck corridor; drop it if under 2.5 m remains | `map_builder.gd` buildings |
| The rim | 6 | With the new box no bridge crosses the rim. Rule for the future: a deck crossing the rim ends in a clean cut face (the diorama's style) and a wall for the car | `map_builder.gd` |

**Tunnels in a top-down game.**

- **Inside a tunnel the ground above stays drawn.** The car shows as an outlined silhouette
  through it: the occlusion ghost's region, applied to the ground and roofs over a tunnel
  corridor. The camera does not dive.
- Portals get a frame and retaining walls along the open ramp.
- Traffic is simulated through the tunnel, but cars are hidden more than 15 m inside.
- The minimap draws tunnels dashed.
- Inside a tunnel corridor and more than 2 m below the terrain, the car's `drive_height` uses the
  tunnel profile.

### 4.5 The check that proves it

**`tools/check_roads.py`** (new; Python like the bakes; reads `centrum.json` or the sector files,
plus `terrain.json`, `lod2.json` and the raw OSM). It mirrors `map_builder.gd`'s height rules
(the terrain's two triangles per cell, deck corridors, `deck_height`, `drive_height`). It runs
over the whole map in under 10 s and prints each finding with map coordinates and a ready
`--at=` command. It writes `shots/check_roads.png` (findings over the orthophoto, reusing
`overlay_ortho.py`) and a JSON report, and exits 1 on any finding not in
`tools/check_roads_allow.json` (each allowed entry carries a reason). The survey behind 4.3 is a
prototype of rules C1 to C9.

| Rule | Fails when | Baseline today |
| --- | --- | --- |
| C1 Grade | A drivable road's own surface (deck or terrain) rises more than 12 % over any 6 m (service roads 20 %). The defects are 40 to 86 %; a real street steeper than 12 % goes in the allowlist with its source | 25 non-service + 78 service roads over 15 % |
| C2 Joints | Roads sharing a vertex differ by > 0.15 m in surface height there | 0 |
| C3 Clearance | A ground road, tram or rail lies under a deck with 0.3 m < clearance < 4.7 m (footways: < 2.5 m) | 126 samples, 11 places |
| C4 Piers | A pier footprint is within 1 m of a road (half-width), tram or rail | 25 |
| C5 Solids | A road or lane runs ≥ 4 m inside a building, landmark or tower footprint whose base is below the road + 3 m and whose top is above it (building passages go in the allowlist) | 2 main-road runs (the Arkada case) + 26 service runs |
| C6 Ends in the air | A deck piece ends > 1 m above the terrain with nothing continuing (rim cut faces allowed) | 8 pieces |
| C7 Dropped ways | The raw OSM has a drivable way (tunnel or cutting) that the map file doesn't | 3 drivable + 5 service |
| C8 Lanes | A lane's height steps > 0.5 m within 4 m, or edges meeting at a node differ by > 0.2 m | 14 edges / 0 |
| C9 Through decks | A building's top is above the deck's slab bottom inside a deck corridor | 1 |
| C10 Towers and landmarks | A landmark collider comes within 0.5 m of a lane corridor (lane offset ± 1.2 m) | 0 lanes within 1.5 m of the tower outlines |

**`game/tools/check_drive.gd`** (new, headless, uses the real builder and colliders). A
car-sized and a bus-sized box (2.0 × 1.6 × 4.4 m and 2.6 × 3.2 × 12 m) is swept along every lane
of the lane graph at the lane's own height, every 4 m, with `intersect_shape` against the static
colliders (walls, parapets, guard rails, piers, landmarks). It lists every lane spot in
collision. Then the player's car is driven by the autopilot over 20 fixed routes across bridges
and tunnels, and every frame where its height jumps > 0.3 m is listed. It exits 1 on any finding.

**Render spots** (`tools/road_spots.txt`): 12 fixed views, rendered before and after each road
loop with `--no-traffic --nosave --fixed --size=70 --shots=90`. Today's map: both Poniatowski
ends (`905,-128`, `1445,-301`), the viaduct's west end (`190,110`), the Wisłostrada portal
(`637,-554`), the railway bridges over Solec and Kruczkowskiego (`540,-175`, `420,-60`), the Jana
Pawła II viaduct (`-1500,700`) and Most Świętokrzyski (`500,-730`). The new area adds Plac
Zamkowy and the W-Z tunnel, both ends of Śląsko-Dąbrowski, Trasa Łazienkowska at Agrykola and
both ends of Most Łazienkowski.

Every road loop is done when `check_roads.py` and `check_drive.gd` pass over the whole map (with
reasoned allowlist entries only), the render spots look right, and loop 2b's budgets still hold.

### 4.6 Structures in the new area to watch

Run `check_roads.py` on the first bake of the demo area before fixing anything. Expect at least
these (loop 3e, 2026-10-30: marked **done** or **left**, docs/DEVELOPMENT.md "Loop 3e"):

- **Trasa W-Z**: the tunnel under Plac Zamkowy, its portal and the viaduct over Wybrzeże Gdańskie
  onto Most Śląsko-Dąbrowski (R1, R4). **Done** (portals on the trench floor, the tube straight
  between them, the block over its west end open); **left**: Nowy Zjazd's pits and one wall by a lane,
  the Praga end's deck 4 parapet.
- **The Wisłostrada tunnel** in full, with both portals (R4). **Done** (both south portals and the
  north portal under the Copernicus Science Centre).
- **Trasa Łazienkowska**: a trench or tunnel at Plac na Rozdrożu and Al. Ujazdowskie, the
  viaduct over Agrykola and the park, the interchange with Czerniakowska and the Wisłostrada, and
  the bridge. This is the first **stacked interchange**, where R8 matters (C8). **Done**: the
  cutting and tubes at Plac Na Rozdrożu (but the tubes end short of the street over them); **left**:
  the interchange and Most Łazienkowski's Praga end (R8). Check the OSM
  `layer` tags: ways with `layer<0` and no `tunnel` are dropped today (5 service ways in today's
  map), and here they may be the Trasa itself.
- **Most Świętokrzyski**: the deck plus its single pylon and cables (the pylon is a tier-A
  landmark).
- **Wiadukt Markiewicza** on Karowa, down the escarpment (R1, curved). **Done** (no wall in Karowa's lanes).
- **The railway at Dworzec Gdański** and the Jana Pawła II viaducts near Arkadia (R1, R5). The rail
  cutting west of Centralna: **left** on the 10 m grid (its 1 m level costs +0.5 M vertices without a
  ground cut).
- **Pedestrian zones**: the Old Town, Plac Zamkowy and parts of Krakowskie Przedmieście. They are
  drivable for the player (section 5) but not for traffic, so keep them out of the lane graph via
  `access`, `motor_vehicle` and `highway=pedestrian`.

### 4.7 Done in loop 3a (2026-10-28)

- `tools/check_roads.py` (C1-C10 above, allowlist `tools/check_roads_allow.json`, image
  `shots/check_roads.png`, `tools/verify.sh` step `roads`). Its baseline on today's map differs
  from the survey's numbers in 4.3 by the rules' thresholds, which 4.5 sets tighter or wider
  than the survey used: C1 85 roads (12 % / service 20 %, not 15 % for both), C3 249 samples in 17
  places (adds trams, rails and footways, < 4.7 m), C4 31 of 161 piers (the pier's footprint
  within 1 m of the road's edge), C5 46 (lanes, LoD2 heights, landmarks), C6 4 + 6 at the rim (over
  1 m, not 2), C7 9 (the survey's 3 + 5, and a 7 m tunnel on Warecka), C8 19 edges + 12 nodes
  (0.5 m and 0.2 m), C9 58 (LoD2 heights and the 48 mapped pillars under the Jana Pawła II
  viaduct, which the survey didn't read), C10 1.
- After: C1, C3, C8 only allowlisted findings (each with its reason and source), C2, C6, C7 at 0;
  C4 31, C5 50, C9 57, C10 1 left for loop 3b. README "Loop 3a" has the table.
- R1 as **structure chains** solved as one graph per family (rails, roads, tracks, footways):
  bridge ways plus the ways between two bridges within 150 m, embankments, and the approaches
  whose terrain within 40 m is steeper than 12 % (the grid's blur). The approaches are **fills**
  (the ground corrected under their corridor), not decks. Pins only where a structure meets an
  ordinary way, at the 10 m grid's value (so the joints stay exact; the 1 m NMT's robust value
  needs the surface model).
- R3 as hard lower bounds; no underpass dip was needed on today's map; a cutting under a deck
  (the WKD) is skipped and logged.
- R4: tunnels kept as tunnel pieces (`tunnels`: pieces, roads with `tn`, portals); cuttings kept
  as roads. Not drawn or driven yet: loop 3b (the lane graph has the edges but keeps them out of
  routing until then).
- R8: graph edges carry `dk` / `tn`; lane heights come from that piece only.
- R9: 27 service ways end at a garage ramp's top; `garages` marks the doors for loop 3b.
- Also: the 10 m grid's narrow pits under streets are filled (98 stretches).

### 4.8 Done in loop 3b (2026-10-28)

The builder's side, placed in the bake (`tools/bake_structures.py`, run at the end of
`bake_osm.py`) so the game, `check_roads.py` and `check_drive.gd` read the same data.

- **R5 piers** (`decks.piers`): 171 places under the road and rail decks: 131 in place, 35 slid
  up to 12 m along the deck to a footprint 1.1 m clear of every road, tram and rail bed, kerb,
  carriageway area, lower deck and lane's drive corridor, 4 portal frames (two legs outside the
  road, the slab as the cross-head, a cap beam out to a leg past the deck's edge), 1 left out.
  Solid. C4 31 → 0.
- **R6 retaining walls** (`walls`): 3.3 km along the approaches' sides and across their ends
  where they stand over the ground beside them (stone on roads, concrete on tracks; a parapet
  from 1 m up; solid from 0.6 m, not where a way joins the approach).
- **R7 towers** (`towers`): per tower the outline by the deck (the other one, a rounded stair
  annex, was drawn as a 14 m building fused into the tower: now inside the zone, grown 6 m),
  trimmed 0-1.2 m to stand 0.5 m clear of the road decks, approaches, roads and lanes (not the
  footways: the pavements pass through the towers), base at the boulevard (-12.4 to -14.1 m),
  shaft from the solved deck + 1.2 m. C10 1 → 0.
- **Buildings under decks** (`cut` / `cutd` / `pil`, `lod2_cuts`): cut to the slab's bottom -
  0.5 m where a road, rail or tram structure stands over at least 20 % of the footprint (the
  Poniatowski viaduct's LoD2 arcades and the Arkada: 4 LoD2 + 2 OSM buildings); the Jana Pawła II
  viaduct's 46 mapped pillars fitted to the slab they carry (10 that stood in a lane under it left
  out).
  Footbridge-only structures cut nothing. C9 57 → 4, all allowed (a footway deck grazing two
  buildings at the viaduct's west end and one beside the viaduct, the science centre's roof
  ramps); C5 50 → 18, all allowed (courtyard driveways ending in a gate, each with its way id).
- **R2 true deck heights**: `tools/geotiff.py` (standard library: strips or tiles, none / Deflate
  / LZW, predictors) reads the 17 corridor windows in this map; the deck solver follows the
  measured deck (the 30th percentile across the carriageway every 2 m, no-structure and tree
  cells out, an opening against pylons and gantries, smoothed to 6 % within 1 m), faded in over
  40 m from the pins; mapped pillars are lower bounds where nothing was measured. Road and rail
  families only (a footbridge's measurement often sees the viaduct over it). The Jana Pawła II
  viaduct rose 1-2 m onto its pillars: C9 there 48 → 0; Most Poniatowskiego's river span got its
  camber (+2 m mid-river).
- **Tunnels**: drawn (the floor's road and centre line, dark side walls solid inside, a portal
  frame at the 4 portals, concrete walls along the open ramps, 369 m); driven
  (`lane_graph.gd TUNNELS_DRIVEN = true`, the graph's off-map links and connected part include
  them; `map_builder.drive_height` drives a tunnel's floor when the car is at it); traffic
  simulated through them and hidden more than 15 m from a portal (graph edges' `po`); the car
  shows through the ground as a silhouette (`tunnel_xray.gd`; the plan's dithered ghost would
  need `discard` in the ground shader); the Wisłostrada trench at (637, -554) is its portal.
  Warecka's 7 m `tunnel=yes` is a gate (left out like the building passages). 27 garage doors
  drawn and solid. The minimap's dashed tunnels are a hud.gd change left for the HUD's owner.
- **`game/tools/check_drive.gd`** (4.5) and the `roads` step FAILing on any rule. What the sweep
  found and how the class was fixed: tram-stop platforms solid (now kerb-height, not solid),
  fences, walls, hedges and mapped guard rails across lanes (cut out of carriageways and lanes,
  2.2 km), benches, racks, shelters, parked cars and kiosks in lanes (left out: 169 + 408 + 34),
  pillars' colliders reaching over their tops, deck parapets solid at grade (solid only over a
  1 m drop), a viaduct ramp's slab in the lane beside it (6 deck sides narrowed ≤ 0.4 m), LoD2
  walls a metre into a lane (not solid there, 17 places), lanes wider than their approach (21
  fill sides widened), structure ends on the grid's cross slope (15 aprons), a pit fill in the
  Wisłostrada's open ramp (none within 80 m of a portal).

---

## 5. Police

**Superseded by `docs/design/police.md`** (2026-10-28, game-designer) for the gentler police the
user chose: warnings and jokes, no fines or respect taken, short chases that end by themselves,
city guards in the Old Town, escorts on rescues; beehave, Dialogue Manager and Phantom Camera
as the approved add-ons. The text below is the first draft, kept for its research.

### 5.1 Who they are

- **Patrol cars** ("POLICJA" in the 5×7 pixel font on the doors, no real badge or crest) driving
  in traffic: 2 to 4 inside the traffic band, on main roads.
- **The speed trap** ("suszarka": Warsaw slang for the radar gun, literally "hair dryer"): a
  parked patrol car and an officer pointing the gun, at 6 fixed spots on the long straights:
  - Al. Jerozolimskie by the Museum
  - the Wisłostrada
  - Al. Solidarności
  - Al. Jana Pawła II by Arkadia
  - Trasa Łazienkowska
  - Al. Ujazdowskie
  
  Three of them are active on a given day, picked by the date like the roadworks.
- **City guards** ("Straż Miejska") on foot with notepads in the Old Town, on Krakowskie
  Przedmieście and in Łazienki, and one small guard car. Their invented colours must never be
  confused with the police.
- Characters for the lines: an older sergeant who has seen everything, and a young officer who
  reads the rules aloud.

### 5.2 What they react to

| Offence | Seen when | Level ("koguty", 1 to 3) |
| --- | --- | --- |
| Speeding | Over the limit by > 20 km/h within 40 m of a speed trap, or passing a patrol car | 1 |
| Running a red light | Crossing a stop line on red within 60 m of police, with line of sight | 1 |
| Hitting a police car | Any contact over 2 m/s | 1, or +1 if already chased |
| Driving where cars may not go | Pavements, the boulevard promenade, park paths (Łazienki), the Old Town lanes, within sight of police or guards | Guards: a fine on the spot if you stop, 1 if you drive off |
| Wrong way on a one-way street | Within sight, for > 3 s | 1 |
| Parking on the pavement | Stopped on a footway for > 20 s near a guard | A wheel clamp ("blokada"), see 5.3 |
| Racing | A street race in sight of police | The chase joins at 1 |
| The river | After loop 10a the car can't reach the water. If a beach or a slip gets it wet, a river rescue tows it out for a fee (a joke, no chase) | None |

Line of sight comes from the helicopter's 4 m roof grid (a short walk through the cells, no
physics query), 180° in front of the officer, within 60 m. Perception runs 5 times a second.
Never in the first 3 minutes of play. Never more than one chase every 3 minutes unless the player
hits a police car.

### 5.3 What happens

- **Level 1**: siren, the light bar flashes, one car follows. A blue-red pulse at the screen
  edges (≤ 10 % opacity), and three small rooster icons next to the wallet ("koguty",
  roosters: Warsaw slang for the light bar) fill up to the level.
- **Level 2**: a second car tries to cut you off at the next junction ahead on the lane graph.
- **Level 3**: three cars and a roadblock of cones and a car at a junction ahead, using the
  roadworks props. At night the police helicopter's searchlight sweeps (the helicopter model,
  re-coloured).
- **Escape**: get more than 150 m away, or out of sight for 6 s. Then 10 s of "searching", when
  hiding helps: tunnels, under bridges, multi-storey car parks. A chase that lasts 60 s
  always ends ("Koniec zmiany!", end of shift).
- **Caught**: you stop within 12 m of a police car for 2 s, or a police car overtakes and stops
  in front of you and you stop. A short card with the officer's line and the fine. Nobody is
  arrested, nothing is crashed on purpose, there are no weapons, and you keep the car.
  - **First offence of the day**: a caution ("pouczenie") and no fine.
  - Then **30 / 80 / 150 zł** by level.
  - If the wallet can't cover it: another caution plus a chore joke ("go and tidy up the
    e-scooters": a mini job from loop 2d).
  - Penalty points as a running joke counter that resets each day.
- **Wheel clamp**: the car can't move. Pay 50 zł or wait 30 s while the guard writes a very long
  note.

A few original lines (Polish, then English):

- "Kontrola drogowa. Wie pan, ile pan jechał? Bo ja nie, suszarka się zawiesiła."
  *Traffic check. Do you know how fast you were going? Me neither, the hair dryer froze.*
- "Pouczenie. Następnym razem mandat. Albo znowu pouczenie, zobaczymy."
  *A caution. Next time, a fine. Or another caution, we'll see.*
- "Panie, tu jest deptak, a nie Wisłostrada!"
  *Sir, this is a promenade, not the Wisłostrada!*
- "Koniec zmiany. Ma pan szczęście."
  *End of shift. Lucky you.*
- "Blokada na koło. Taka tradycja."
  *A wheel clamp. It's tradition.*
- "Jedziemy na sygnale, proszę się trzymać!"
  *Lights on, hold tight!* (escort)

### 5.4 How it ties in

- **Rescues**: no chase. A patrol car escorts you to the hospital with its lights on, clearing
  traffic: a reward and a joke, not a threat.
- **Races**: a race seen by police pulls in a level-1 chase. Escaping it before the finish pays
  +20 % and +50 respect. Rivals get lines about the police; Taksiarz Zbyszek knows every hiding
  spot.
- **Side jobs**: a chase cools the kebab faster; jars rattle in a chase (słoiki); the app-taxi
  passenger knocks a star off for a pull-over.
- **Wallet**: fines come out of the złoty; the respect stays.
- **Radio**: the host announces the day's speed traps ("Suszarki dziś na Wisłostradzie").
- **Collectibles**: one egg is a police car stuck in its own roadworks.

### 5.5 Art and readability at the default zoom

At the default 80 m view in the Sharp style (480-line pixel image) a car is ~24 image pixels
long (~58 screen pixels on 1,170 lines).

- The patrol car is an **estate or SUV silhouette** (bigger than the player's hatch), white with
  a blue band. The light bar is ~10 × 2 image pixels, flashing blue left and right at 2.5 Hz, so
  it reads by day as a blinking blue dot.
- At night, blue and red halos on the road (the glow pass's quads, as the head lamps have).
- The speed-trap officer is a pixel figure in a high-visibility vest; the gun is a 2-pixel dark
  stub.
- City guards wear a different, invented colour pair (for example teal and yellow) and use a
  smaller car.

### 5.6 Sound

A two-tone siren synthesised by `make_sfx.py` (no samples), on one of the six positional
voices, with a Doppler-free pitch wobble and ducked under the radio by 3 dB. A short "whoop" when
a car joins. A clipboard-scribble sound for the clamp.

### 5.7 Cost on the phone

- Police cars are traffic cars with a paint flag in the same MultiMesh: **+0 draw calls**.
- Light-bar halos: **+1** (one glow MultiMesh). The roadblock uses the pooled roadworks props:
  **+1**.
- Scripts ≤ 0.15 ms per frame on the Mac (≤ 0.5 ms on the phone): perception at 5 Hz, chasers on
  the rivals' lane-graph pursuit, no raycasts.
- Memory: +1 MB.

### 5.8 Tuning (first guesses, flags to test)

| | Value |
| --- | --- |
| Patrol cars in the band | 2 at Normal traffic, 4 at Busy |
| Chase speed | the player's top speed −5 %, so you can always win on straights |
| Escape distance / out of sight | 150 m / 6 s, then 10 s searching |
| Chase cap | 60 s |
| Fines | caution / 30 / 80 / 150 zł |
| Cool-down between chases | 3 min |
| Flags | `--police=1..3` (start a chase), `--trap=N` (put the car before trap N), `--no-police` |

---

## 6. The demo's content and loop

### 6.1 Keep, polish, cut

| | What |
| --- | --- |
| **Keep** | Point steering and the hold-then-ease camera; day, dusk, night and Live; the radio and its host; rain; rescue calls (car and helicopter); the six rivals and their races; kebab delivery; the słoiki run; the wallet; eggs, billboards and posters; landmark cards; the occlusion ghost |
| **Polish** | Pay rates and rescue time limits (first guesses); traffic overlapping in junctions and trams nose to nose (backlog); kerbs that are flat to the car (a small bump); race finishes reachable from more places (backlog); speech-bubble readability on the phone; the car models (loop 2c) |
| **Cut from the first screen** | The RESCUE CALLS card at start (calls arrive during play instead); the "prototype" label; STYLE, VHS, RAIN and CAM out of the top row into Settings (loop 2e). The top row keeps the gear, HELI or CAR and one context button |
| **Gate** | The helicopter is unlocked by the first rescue ("the air ambulance lends you its old one"). It is a reward, not a button on screen one |

### 6.2 The first 10 minutes

| Time | Beat | Built from |
| --- | --- | --- |
| 0:00 | Title, tap anywhere. The car on Marszałkowska by the Palace, day, the radio playing | Exists |
| 0:05 | Driving. A ghost finger only if there is no touch for 4 s | New hint |
| 0:15 | A dashed ring and a kebab steam icon ahead (the Marszałkowska/Świętokrzyska stand; 2026-10-31, the first-10 polish: a new save starts on the northbound side by the Museum of Modern Art, facing the stand ~350 m up the street) | Exists, plus a guaranteed first order |
| 0:30 | The first order: ~~a hand-picked 700 m delivery past the Rotunda~~ a short, easy one (2026-10-31, the first-10 polish: ~230 m straight on up Marszałkowska, no turn to find; the first one was 926 m with a U-turn). The customer's punchline, money pops | New "first order" |
| 1:30 | ~~Seba~~ **Pani Halina** rolls up behind and flashes: FLASH LIGHTS back. An 800 m race to the Palm, which she is tuned to lose narrowly (2026-10-31, loop 3h slice 4: Halina is the ladder's first rung, so the first race counts on the ladder and Seba stays the final's boss, making "Trzy mosty" the payoff) | Exists + a first-race tuning (rivals.gd `first_band`) |
| 3:00 | The first speed trap on the way back: a caution, two jokes, the roosters explained in one line | New (police) |
| 4:00 | A rescue call (street, car): the hospital, the escort, and the helicopter unlocked | Exists + gating |
| 6:00 | Helicopter over the river: a cassette on the boulevard roof, a new song (2026-10-31: the first mixtape lies on the University Library's roof by the boulevards, cassettes.gd) | New collectible |
| 8:00 | "Powiśle discovered": the district card, 3 question marks on the map | New district system |
| 10:00 | The garage marker appears in Praga ("Warsztat u Mirka"): spend the złoty on a paint job | New garage |

The first 15 minutes then cross a bridge to the stadium (the final race's ground) and pass
through the Old Town, where the city guards meet you.

### 6.3 The first hour

The main line through the first hour (the guide, the ladder, the final), its markers and its
pacing: docs/design/main-line.md (2026-10-31).

| Activity | Demo content | Exists? |
| --- | --- | --- |
| Rival ladder | The 6 rivals in order of stake (Halina 60 → Mordor Mike 300 zł), each unlocking the next; a **final race "Trzy mosty"** (three bridges) against Seba at night, from Rondo Daszyńskiego to the stadium's stands | Races exist; ladder and final are new |
| Kebab | 7 stands → ~14 across the demo area (Praga, Muranów, Hala Mirowska, the Old Town's edge, Plac Zbawiciela, Arkadia's car park, the stadium) | Extend |
| Słoiki | A second station, Dworzec Gdański → Muranów and Praga flats | Extend |
| App-taxi | Star ratings (smoothness, time, no pull-overs); passengers who insist on following the GPS into the river or the Old Town; 5-star streaks pay bonuses | New (loop 2d) |
| Couriers | Race a square-backpack bike courier to a door: they can cut through parks and you can't | New (loop 2d) |
| E-scooter round-up | At night, collect 10 dumped scooters with a van | New (loop 2d) |
| Rescues | As now, over the whole area; new kinds: an Old Town tourist with a sprained ankle, a Łazienki peacock on a roof (helicopter) | Extend |
| Police | 5.2 to 5.4 | New |
| Collectibles | **20 Syrenki** (little invented mermaid figurines hidden round the city; the real statues count too), **10 cassettes** (7 new radio loops from `make_music.py`), **15 eggs** (5 exist + the Praga bears, Łazienki's peacocks, the pigeons of Plac Zamkowy, the "best view of Warsaw" joke on the Palace, a police car stuck in its own roadworks, a race up and down a multi-storey car park by Arkadia, the Old Town's horse carriage, a tram fan at Plac Bankowy, Plac Zbawiciela's café queue, the "new Mordor" commuter march at Rondo Daszyńskiego), billboards 5 → 10, posters 24 | 5 eggs exist |
| Landmark cards | ~25 (72 now, 2026-11-01) | Done |

**Progression.**

- Złoty buy paint jobs and 3 cars at the garage (the hatchback, a boxy estate and a tiny
  1970s-style city car; invented, no real models).
- Respect unlocks rivals and the final race.
- Collectibles unlock songs, a gold paint and a horn tune.
- District completion (jobs done, eggs and mermaids found) shows on the map and in a pause card.
- The save gets a version number, so later builds can migrate it.

**Night, radio and weather.**

- Day first (the user's choice). Night pays ×1.5 for kebab (exists) and is when the final race,
  the scooter round-up and the police helicopter happen.
- The radio gets the 7 cassette songs, the host's speed-trap and roadworks news, and a night show
  (KEBAB FM only after dusk).
- Rain stays a button. Rain days by date are an idea for later.

**The end of the demo.** Win "Trzy mosty" and finish 10 jobs. A card ("Dzięki! / Thanks for
playing"), the credits and the open-source link. Then free roam continues with everything
unlocked.

### 6.4 Invented names (suggestions for loop 2d; no real brands)

| Joke | Suggested name and look |
| --- | --- |
| The 24h corner shop chain | ~~Rechotka 24~~ → **Frogs** (the user's pick, 2026-10-30; an English word, not the real brand's name or logo): frog green with a lily-pad sign of our own |
| App-taxi | **Podwózka**, with a star bar and a phone-shaped roof sign |
| Couriers | **Pędzik**: magenta square backpacks |
| E-scooters | ~~Hulajka~~ → **Leżak** (deckchair): violet, lying in odd places ("Hulaj" was a real Polish scooter-sharing brand) |
| Kebab | Stand names in pixel letters: "U Zdzicha", "Na cienkim" (~~"Nocny Marek"~~: one letter from Warsaw's "Nocny Market") |

**Superseded by `docs/design/parodies.md`** (2026-10-28, game-designer): the final names
(Rechotka 24 with a lily-pad sign and no frog figure, renamed **Frogs** by the user on 2026-10-30; Podwózka, Pędzik, Leżak, U Zdzicha, Na
cienkim) after a web and domain check; a trademark-register search (UPRP/EUIPO) belongs to
loop 3k's brand audit.

**Direction "Moja Warszawa"** (the user, 2026-10-29, `docs/design/vision.md`): the city as the main
character. It adds a notebook of 72 places and 40 eggs, the night and techno scene, the river steps,
viral spots, metro and buses, then-and-now spots (KASETA), PÓŁNOC FM, Fotka and Spacer. Jobs, police
and races stay as flavour. Its loops MW-0 to MW-6 come after 3d/3e/3f, and loop 2d-2 is folded into MW-2.

---

## 7. Milestones

**Provisional budget P** (it applies until README's "Performance budgets" from loop 2b lands;
where they differ, loop 2b's numbers win):

- 60 fps (≤ 16.7 ms) at the default view on an iPhone 11-class phone (A13) at the default quality.
- ≥ 30 fps at the worst view (the helicopter over the centre).
- ≤ 800 draw calls (all passes) at the default view and ≤ 1,200 at the worst; ≤ 1.0 M triangles
  drawn (1.5 M at the worst).
- Scripts ≤ 2.5 ms on the phone (~1 ms on the Mac).
- Memory ≤ 1.2 GB.
- Streaming ≤ 3 ms of main-thread work a frame, with no frame over 33 ms from a load.
- Cold launch to the title ≤ 4 s.

Each loop below states its own change against P.

The order follows the user's rule: roads and the performance architecture before anything that
adds content. One agent at a time, as in ROADMAP's "How the work is run".

| # | Loop | Goal | Acceptance | Phone budget |
| --- | --- | --- | --- | --- |
| 0 | **Loop 2b** (running) | Per-frame cost and the budgets | README "Performance budgets"; the BENCH card on the phone | Sets P |
| 1 | **10a** (queued in ROADMAP) | The river is off-limits | No water entry from 50 test spots round the shore, the beaches and under every bridge (a headless check); the car stops or is towed with a joke | +0 |
| 2 | **10c** (queued in ROADMAP) | The Godot mobile performance skill from 2b's numbers | The skill exists; every later brief points to it | n/a |
| 3 | **Loop 3a: Roads I, the check and the bake** | `check_roads.py` (C1 to C10) and its baseline; fixes R1 to R4, R8 and R9 on today's map; D4 and D5 for today's map if approved, else the chain solver alone | `check_roads.py` green (reasoned allowlist only); the Wisłostrada joined to the lane graph through its tunnel (the strongly connected part grows); render spots before and after | +0 draw calls; vertices ±2 % |
| 4 | **Loop 3b: Roads II, the builder** | R5 to R7, buildings under decks, tunnel portals, the X-ray car in tunnels, `check_drive.gd` | `check_drive.gd` green; no bus through a slab, pier or tower in a 10-minute traffic soak; the user's screenshot spot re-rendered from the same angle | ≤ +2 draw calls (pier and wall colliders and meshes in existing tiles); scripts +0 |
| 5 | **Loop 2e, moved up: the HUD at phone size** | Points-based HUD; the top row thinned (6.1 "Cut") | Every control ≥ 44 pt and text ≥ 11 pt on 375-, 390- and 440-pt-wide phones (screenshots at each); no overlap with the bubbles | HUD ≤ 0.3 ms, ≤ 30 2D draw calls |
| 6 | **Loop 3c: Sector streaming on today's map** | 2.4's architecture with the current data: sector bake, proxies, streamer, global index, both city paths | Pixel diff against today's monolithic build at 10 spots ≤ 0.5 % (`--no-traffic`); a 15-minute autopilot over the whole map with no missing sector; streaming ≤ 3 ms a frame; memory at least 30 % lower; all checks still green | Meets P at every view |
| 7 | **Loop 3d: Demo data and bake** (needs D1 to D6 approved) | The new box with the fixed origin; `bake_terrain.py`; all bakes; ~140 sectors | `check_roads.py` run over the demo area and every finding listed; lane graph ≥ 95 % strongly connected; cold load ≤ 4 s; app ≤ 300 MB; BENCH at 8 spots (centre, Old Town, Łazienki, Praga, Rondo Daszyńskiego, Arkadia, the stadium, the helicopter over the river) | P at all 8 |
| 8 | **Loop 3e: Structures of the new area** | 4.6: W-Z tunnel, the Wisłostrada tunnel, Trasa Łazienkowska, the Śląsko-Dąbrowski, Świętokrzyski and Łazienkowski bridges, Wiadukt Markiewicza, pedestrian zones out of the lane graph | `check_roads.py` and `check_drive.gd` green over the demo area; render spots for the new structures | +0 draw calls per sector |
| 9 | **Loop 3f: Landmarks, tier A** | The 12 tier-A landmarks (2.2) with info cards | Each recognisable from 3 angles; `check_landmarks.gd` extended (walls, roof grid, taps); orthophoto overlays | Building material only; ≤ 400k vertices in total; +0 draw calls |
| 10 | **Loop 2c: Car models** | The player's hatch, traffic, and the police estate and guard car | They read at the default zoom (C1 test); silhouettes distinct | Traffic MultiMeshes unchanged in count; ≤ +20 % vertices for vehicles |
| 11 | **Loop 3g: Police** | Section 5 | Flags drive every flow (chase 1 to 3, escape, caught, caution, clamp, escort); a 10-minute soak with police on, no police car through geometry; lines in `dialogue.json` | ≤ +3 draw calls; scripts ≤ 0.15 ms on the Mac |
| 12 | **Loop 2d: Warsaw jokes and side jobs** | Frogs (was Rechotka) shops, app-taxi with stars, couriers, scooters, more kebab, 10 billboards, 15 eggs | Counts in 6.3; every new prop instanced; lines original and brand-free | Props in MultiMeshes per sector (≤ +4 draw calls per sector) |
| 13 | **Loop 3h: The demo loop** (hand-over brief: `docs/design/loop-3h-handover.md`) | 6.2 and 6.3: the first-10-minutes script, rival ladder and final race, Syrenki and cassettes, the garage, district cards, the end card, save v2 | A scripted replay hits every 6.2 beat on time; checklist A1 to A5, F1 to F4, G1 to G3 and I1 to I2 green | Scripts ≤ +0.2 ms |
| 14 | **Loop 3i: Juice, sound and night pass** | Sparks and dust, money pops, scrape loop, district ambiences, siren, the night look in the new districts, Reduce Motion, left-handed layout | B3, D1, D3 and J3 green; the night render spots | Particles ≤ 1 draw call, ≤ 64 alive |
| 15 | **Loop 3j: Device pass and TestFlight** (10b folded in) | Real numbers on the user's iPhone 11 and 16 Pro Max; debug flags stripped; an archive ready | H1 to H4 green on device; a 30-minute soak; the credits and licences screen (ODbL, GUGiK, CC BY for the trees); a privacy statement of no data collection. The user signs and uploads to TestFlight | Meets P on device |
| 16 | **Loop 3k: Open-source publication** (any time after loop 3d) | A public repo | Licence chosen (MIT, done 2026-10-28; first commit after loop 2b); the raw data replaced by fetch scripts; the derived map database offered under ODbL (its share-alike applies to `centrum.json`); README for contributors; a brand audit (no real names or logos in game content) | n/a |

Rows 3 to 8 are map and engine work, all before the content (row 9 onward). Loop 2e (the HUD,
row 5) moves up from ROADMAP's position 13: every later device test needs a usable HUD, and it
adds no content. The new loops continue ROADMAP's naming as loop 3a to 3k; ROADMAP's agent order
should list them when the user accepts this plan.

---

## 8. Open questions (each with the default this plan uses)

**Answered by the user on 2026-10-28** (these override the defaults below):
- **Downloads: all approved** (D1 OSM, D2 + D3 aerial and elevation, D4 + D5 bridge-corridor
  surface and terrain models, D6 the 3D-tree package).
- **South edge: 52.2065**: all of Łazienki including Belweder (+6 tree sheets, +~1.2 GB on
  disk). The box is now S 52.2065, W 20.9780, N 52.2595, E 21.0560.
- **The helicopter stays available from the start** (not gated by the first rescue).
- **Police: gentler.** Warnings and funny lines only; **no fines** are taken from the wallet.
  Chases stay short and always escapable. Section 5.3's fines and the "mandat" money flow are
  out; keep the caution and the jokes.

1. **South edge**: 52.2085 (Belweder's tip stays out, no extra tree sheets) or 52.2065 (all of
   Łazienki, +6 tree sheets, +1.2 GB)? *Default: 52.2085.*
2. **The downloads D1 to D6** (section 3.1): which are approved? *Default: none until the user
   says yes; recommended all six. D4 and D5 are the new ones (they fix the bridges properly).
   D6 is the big one (8.6 GB streamed).*
3. **Driving into pedestrian zones** (the Old Town, Plac Zamkowy, Krakowskie Przedmieście):
   allowed with the city guards reacting, or blocked with bollards? *Default: allowed, guards
   react, traffic stays out.*
4. **Police look**: the generic word "POLICJA" in our pixel font, white with a blue band, no real
   emblem. Acceptable? *Default: yes.*
5. **Fines take money** (caution first, then 30 / 80 / 150 zł, never below zero)? *Default: yes.*
6. **The helicopter unlocked by the first rescue** instead of being available from the start?
   *Default: gated.*
7. **The start spot**: keep Marszałkowska by the Palace, or start at Plac Zamkowy? *Default: keep
   the Palace.*
8. **Invented names** in 6.4 (Rechotka 24, Podwózka, Pędzik, Hulajka): fine as working names for
   loop 2d? *Default: yes, final names in loop 2d.*
9. **Moving the HUD loop (2e) ahead of the car models (2c) and jokes (2d)**? *Default: yes.*
10. **The screenshot's location**: this plan reads it as the east end. Both ends share the
    defects and both get fixed. *Default: no action needed.*
11. **Licence**: changed by the user on 2026-11-06 to source-available, non-commercial:
    PolyForm Noncommercial 1.0.0 for the code (`LICENSE`), CC BY-NC 4.0 for the game's own art,
    sounds, music and text (`LICENSE-ASSETS.md`); the map data keeps ODbL (OSM), CC BY 4.0 (the
    trees) and the GUGiK terms (`CREDITS.md`). The repo is not linked from public pages.
12. **TestFlight**: agents prepare a signed-ready archive and the user uploads it from Xcode or
    Transporter. *Default: yes.*

---

## 9. Beyond the demo: how big the app gets (estimate, 2026-10-28)

The user asked what the app would weigh with the inner districts, or all of Warsaw (517 km²;
GUGiK and OSM hold about 198,000 buildings and 1.9 million trees for the city). Measured
today (after loop 2b): the game's data pack is **45 MB for 6.3 km²**, about **7 MB per km²** of
city centre (36 MB of it the ready-made 3D city), and the engine binary is 103 MB in a debug
build (a release build is roughly half that, and the App Store compresses it further).
Outside the centre a km² holds fewer and simpler buildings (houses, blocks), forests and
fields, so it costs about half as much. Anchor: GUGiK's LoD2 package for **all of Warsaw** is
112 MB zipped.

| Area | km² | Data pack at today's formats | With compact formats (estimate) | App download, roughly |
| --- | --- | --- | --- | --- |
| Today's map | 6.3 | 45 MB | — | ~100 MB |
| The demo (this plan) | ~31 | ~220 MB | 120–170 MB | 180–280 MB |
| Inner districts: Śródmieście, Wola, Ochota, Mokotów, Żoliborz, Praga-Północ, Praga-Południe | ~122 | ~600 MB | 300–400 MB | 350–650 MB |
| All of Warsaw (18 districts) | 517 | 1.6–2.0 GB (3.6 GB at centre density) | 0.8–1.2 GB | 0.9–2 GB |

"Compact formats": store the sources (footprints, heights, roof shapes, tree points) and build
each 512 m sector on the phone as you drive towards it instead of shipping a ready-made mesh;
ship the baked ground shade, street-light and water maps compressed and at 2–4 m outside the
centre; quantise vertices. Trees are cheap either way (1.9 M trees × ~16 bytes ≈ 31 MB).

What this means:
- **Memory and frame rate don't grow with the map.** The sector streaming in 2.4 keeps only the
  3×3 sectors round the camera in full detail, so the phone's memory and draw calls stay as
  today wherever you are; only storage grows.
- **App Store:** the limit is 4 GB, so even all of Warsaw fits. Over **200 MB** the iPhone asks
  before downloading on mobile data. A good shape: the app ships the demo area (~200 MB) and
  downloads more districts after install as background asset packs (Apple's Background Assets);
  check Apple's current limits and hosting options when that loop starts.
- **Work, not size, is the real cost:** every district needs its roads and overpasses correct
  (S8, Trasa Toruńska, Wisłostrada, Trasa Siekierkowska…), its landmarks, its lanes and its
  content. Plan: the demo first, then the inner districts as an update, then the rest.
- **Raw data to bake all of Warsaw** (not shipped): OSM ~0.5 GB, the whole 3D-tree package
  ~8.6 GB, orthophoto ~2 GB at today's resolution, LoD2 already on disk.

---

## Sources

Research for section 1 (read 2026-10-28):

- art of rally: [God is a Geek preview](https://godisageek.com/2020/04/the-art-of-rally-demo-shows-incredible-promise-hands-on-preview/), [Push Square review](https://www.pushsquare.com/reviews/ps5/art-of-rally), [KeenGamer review](https://www.keengamer.com/articles/reviews/switch-reviews/art-of-rally-review-a-stylish-love-letter-switch/), [Entertainium review](https://entertainium.co/2020/10/07/art-of-rally-review/)
- Absolute Drift: [Traxion](https://traxion.gg/absolute-drift-zen-edition-nintendo-switch-review), [Bonus Stage](https://www.bonusstage.co.uk/archives/180339), [Nintendo World Report](https://nintendoworldreport.com/review/55658/absolute-drift-zen-edition-switch-review)
- Crazy Taxi: [Wikipedia](https://en.wikipedia.org/wiki/Crazy_Taxi_(video_game)), [core-loop breakdown on itch.io](https://itch.io/blog/530882/breaking-down-elements-related-to-core-loop-of-crazy-taxi)
- A Short Hike: [PlayStation Blog, "Crafting a tiny open world"](https://blog.playstation.com/2021/08/05/crafting-a-tiny-open-world-a-look-behind-the-scenes-at-the-creation-of-a-short-hike/), [GDC Vault listing](https://gdcvault.com/play/1026613/Independent-Games-Summit-Crafting-A)
- Little Kitty, Big City: [TheSixthAxis](https://thesixthaxis.com/2024/05/09/little-kitty-big-city-review), [Game Informer](https://gameinformer.com/review/little-kitty-big-city/feline-fun), [Games Asylum](https://www.gamesasylum.com/2024/05/17/little-kitty-big-city-review/)
- Mini Motorways: [Wikipedia](https://en.wikipedia.org/wiki/Mini_Motorways), [KeenGamer](https://www.keengamer.com/articles/reviews/pc-reviews/mini-motorways-review-control-the-open-road-pc/), [IGF](https://igf.com/mini-motorways)
- Tiny Glade: [Shacknews](https://shacknews.com/article/141431/tiny-glade-review-score), [GamingOnLinux](https://gamingonlinux.com/2024/06/tiny-glade-is-a-gorgeous-castle-doodling-game-thats-real-clever-to-relax-with), [Aftermath](https://aftermath.site/tiny-glade-is-a-lovely-stress-free-builder/)
- Islanders: [OpenCritic](https://opencritic.com/game/7545/islanders/reviews)
- Game feel: [AIIDE paper on juice](https://ojs.aaai.org/index.php/AIIDE/article/download/18889/18654/22655), [screen-shake and hit-stop notes](https://slicker.me/python/game_feel_pygame.htm)
- Camera: [John Nesky, 50 Game Camera Mistakes](https://gamedeveloper.com/design/video-50-common-game-camera-mistakes----and-how-to-fix-them)
- First session: [mobile onboarding and retention](https://blog.playio.co/mobile-game-onboarding-retention)
- Demos: [Unity, Steam Next Fest tips](https://unity.com/blog/steam-next-fest-developer-tips-unity), [presskit.gg, how to build a demo](https://presskit.gg/field-guides/how-to-build-game-demo)
- Pursuit design: [StrategyWiki, Most Wanted pursuit system](https://strategywiki.org/wiki/Need_for_Speed:_Most_Wanted/Pursuit_system), [Guru3D review](https://guru3d.com/review/need-for-speed-most-wanted/page-4)
- Godot: [visibility ranges (HLOD)](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html), [background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html), [MultiMesh](https://docs.godotengine.org/de/4.3/classes/class_multimesh.html)
- GUGiK: [surface model (NMPT)](https://geoportal.gov.pl/en/data/digital-surface-model-dsm), [terrain model (NMT)](https://www.geoportal.gov.pl/en/dane/numeryczny-model-terenu)
- Coordinates of the box's anchors: [Nominatim](https://nominatim.openstreetmap.org/) (Rondo Daszyńskiego, Arkadia, Łazienki Królewskie, Stadion Narodowy, Rondo Waszyngtona, Most Łazienkowski, Most Śląsko-Dąbrowski, The Warsaw HUB)
