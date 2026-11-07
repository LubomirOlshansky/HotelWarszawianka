# Backlog — issues found along the way

Small problems that agents reported or that showed up in screenshots. They are fixed in the
"loop" stage after the roadmap versions (or earlier, when an agent is already in that file).


## The Palace of Culture's grounds and venues (F, 2026-11-07, with F's aerial photo)

Built: the walls OSM maps round the Palace's beds and raised lawns (59 retaining walls, planters)
are knee-high granite planters (0.65 m, 1 m balustrade at steps) instead of 1.9 m grey walls; the
five shrub beds (natural=scrub, folded into lawn by the bake) are clipped bushes on dark soil; the
Plac Defilad lot is asphalt with its 168 mapped bays painted, the 43 kerbside lots along the
service roads are grey pavers (game/data/pkin_grounds.json, `tools/bake_pkin_grounds.py` from the
raw OSM, Mac only). The venues at their OSM doors: KINOTEKA (its storefront sign stood 130 m west,
across Emilii Plater; moved to the Palace's own), KULTURALNA, TEATR DRAMATYCZNY, MUZEUM TECHNIKI,
SALA KONGRESOWA, TARAS 30 PIĘTRO under the terrace ledge. Teatr Studio's front from F's six photos
(the portico by day and at dusk, Bar Studio in the colonnade, the corten planters): the six-column
portico in the north-east wing's east recess with its steps, TEATR STUDIO cut in the entablature and
the neon THE FUTURE SHOULD ALWAYS BE BETTER over it, poster banners, lights between the columns;
Bar Studio's tables in the colonnade and under nine pale-blue umbrellas at the steps' foot with
potted palms and the lit BAR on the north cheek; the forecourt in light granite with Plac Defilad's
dark bands every 6 m (OSM's old TR Warszawa fence along the Palace dropped there, the 2025 photos
show the square open), seven corten planters with bench tops and round-crowned trees or spiral
topiary, and the 40 m² flower bed with its ginkgo ("Zieleń nad betonem", Teatr Studio 2022).
Sitters at the tables (jazz café curve) and the evening audiences outside four stages (crowds.gd
THEATRES, `theatre` curve, dark on Mondays). Left:
- Mac/phone look check: the planters' height and colour against the real granite, the signs' size;
  the planters' and the flower bed's exact spots (from photos, not a plan).
- The north courtyard's car park and the Muzeum Ewolucji / Pałac Młodzieży doors (north side, faces
  the camera never sees) have no sign; the terrace has no ticket queue at the east portico yet.
- Joke billboard "UWAGA:" by the pigeons on Plac Defilad shows the camera its dark back.
- The bake still turns scrub into plain lawn city-wide; only the Palace's beds are bushes.

## Ratusz Arsenał interchange and passengers (F, 2026-11-07, six photos)

Built: `ratusz_hub.gd` (the arched tram canopies on the two Solidarności platforms, stops 09 and 10, lit arches at
night, benches, departure boards; stop 03 on Andersa keeps its ordinary shelters; Gruba Kaśka na Tłomackiem between
the two tracks: grey base, cream ashlar drum, roundel frieze, cornice, stepped roof, green copper spire, gold ball,
tall wooden door; railings), the
station's own entrances in `Props._metro_ratusz` (glass escalator pavilion, stone M1 entrance with the white canopy,
stone stairwells, yellow roundels), seated passengers in every tram window (`Models.passengers`), and people
waiting on every tram platform (crowds.gd `stop` sites; the bus stops already had buses.gd's waiting figures).
Check `ratuszhub`. Left:
- Bus passengers: call `Models.passengers` inside `bus_shape` once PR #511 (solo bus family) has merged; the old
  tram (old_tram.gd) and the new fleet (PR #487, tram_fleet.gd) want the same call.
- Other M1 stations (Politechnika, Centrum's side exits, Świętokrzyska's plain stairs, Dworzec Gdański) have the
  same stone stairwells: `metro_form` can give them "stone_steps" once someone checks photos of each.
- Gruba Kaśka's info card (the 18th-century well house of the city waterworks); its spot is read off F's satellite
  view, since the cloud can't reach the GUGiK ortho or Overpass (proxy 403): a Mac check against the ortho should
  confirm it, the canopies' east ends and the pavilion's footprint (OSM's entrance 5 is its stair); Mac look check
  of the canopies' curve against F's photos.
- buses.gd's waiting figures (≤ 10 near the view, 06-22) could sit on the shelter benches too.
## Metro entrances by station (F, 2026-11-07; photos: Mapillary street photos, shoot list /mnt/project-files/metro/metro-photos-needed.txt)

Audit of the 84 mapped entrances (M1 + M2). Own look from photos: Centrum (blue tubes, glass barrels), Świętokrzyska M2 tents,
Rondo Daszyńskiego (red butterfly, PR #479, not in main yet), and new here: Stadion Narodowy (teal glass crystal, `crystal`),
Kopernik (pale aqua crystal, `crystal_aqua`), Dworzec Gdański (clear glass in dark steel, `crystal_clear`), Nowy Świat-Uniwersytet
(violet glass box, `box`), Rondo ONZ (the A-frame `tent`, its 14 canopies). Ratusz-Arsenał is another thread's. Left:
- Politechnika's canopies stay the generic vaulted glass (photos only far away; blue-tinted glass in them); Centrum's 3 canopy
  entrances and 7 stairwells, Świętokrzyska's plain stairwells and every passage mouth (`footway`) have no photo: shoot list for F.
- Rondo ONZ's tent is read from one street photo (a gabled glass pavilion with the roundel): close photos would confirm it.
- The stairs thread (PR #517) lists metro stairwells the 10 m grid flattens (Rondo ONZ at -1805,110 / -1690,101 / -1798,48,
  Jana Pawła II, Marszałkowska by Dmowskiego, Dworzec Gdański): each needs a SUNKEN entry after this PR.
- Not done here: people crossing at Rondo Daszyńskiego and the real tram stops (F's same message): tram stops are PR #518.


## Night racing club: Darek, Lena, Tadek (F, 2026-11-06; docs/design/night-meet.md)

Built: Darek's call, the meet on Plac Defilad with Lena's donuts, two police raids, the TYGRAM pin
and the race to the National Stadium's car park, the drag on Aleja Zieleniecka with START DRAG,
the tree, BIEG! shifts and nitro. Left:
- [ ] Voice for Darek, Lena and Tadek (F: later)
- [ ] Autopilot re-run on the Mac after PT-33/PT-34 (first run 2026-11-07: every beat ran; drag unwinnable and chase pill over the car, fixed in #499; the result card's REWANŻ/KONIEC showed in the cloud at 1280×720, so watch whether Autopilot lists them)
- [ ] Phone check: smoke and marks at night, the tree's size, the BIEG! button under a thumb; bench at the meet
- [ ] A stake to enter the drag? (parked for F, built without)
- [ ] Meet 2 stands on a small plaza with a few trees inside the ring: check the look, move it if it clashes
- [ ] Later: the club card in the notebook, more meet places (Browary, Wał Miedzeszyński), underglow paint in the garage after a win
## Coffee run (F, 2026-11-06)

Built 2026-11-06 (docs/design/coffee-run.md): Zuzia's call, the ROWERILO dock by Elektrownia, the
player's bike, four café stamps against the clock, the BLIK back. Left:
- **Phone check**: the bike's readability at the 80 m view, the clock, the hint lines.
- **Café signs**: the four doors are beacons only; signs on existing shells or from photos.
- **Zuzia on screen**: she is a phone voice and a hint line; no figure rides along.
- **Bike sound**: the engine loop still plays on the bike; a bell and pedalling instead.
- **Free ROWERILO**: taking a bike at any dock outside the run.
- **Zuzia's own look at the dock**: the quest map's in-person start uses the beacon's generic figure.
- **Garage while biking**: entering the garage mid-run turns the bike back into the car's model.
## Closer zoom and the camera angle (F, 2026-11-07)
Done: + goes one step closer (40 m view, follow_camera.gd VIEWS) and Settings → Obraz → "Kąt kamery ·
Camera angle" picks 30° (default), 40° or 50° (follow_camera.gd PITCHES, settings.gd `pitch`).
- [ ] Phone check: does 40 m read well while driving fast (about 1.6 s of road ahead at 90 km/h), and
  do the steeper angles look right on the iPhone (roof detail, street furniture, the dithered fades).
- [ ] Parked: a lower angle than 30° (more horizon) was not added: it shows more ground per frame,
  so more draw calls; needs a bench on the iPhone 11 first if F wants it.
- [ ] Some tuning still assumes 30°: the helicopter's aim (main.gd AIM_*) and check_drape's
  PITCH_SIN. Fine in the shots at 40° and 50°; revisit if something looks off on the phone.
## Flickering textures from the helicopter (F, 2026-11-07, two phone screen recordings)

Fixed: over the rail yard by Warszawa Główna and the cutting to Ochota the beige ground tore through
the ballast in jagged, crawling patches and the rails broke into dashes. Two causes: the cutting's
floor had the gravel shoulders' depth bias (same layer, same height: z-fighting), and the railway's
flat layers were laid in 10 m pieces that sagged up to a metre under the cutting's 2 m ground. Now
the floor sits under the shoulders (bias 0.16), the railway layers keep their corners on the drawn
ground and bend with the cutting's sub-cells (`map_builder._drape_edge`); check_drape's rail pass
(ground over them in the cutting: 6,589 m2 before, 330 m2 after, +137k flat triangles map-wide, +4 %). Left:
- Rail beds outside the cutting still sag under the 10 m grid in places (~3,300 m2 of gravel
  shoulders, ~700 m2 of beds, mostly by bridges and aprons); a phone look decides if it shows.
- The second recording (Rondo Daszyńskiego area, by car) shows a shimmer on the long window rows of
  slab blocks while the camera moves: the shader's window grid near the pixel size (aliasing), not
  z-fighting. Candidate fix: fade the window pattern by fwidth like the roofs do; needs a phone look.

## Open-PR audit (F, 2026-11-07; docs/PR_AUDIT.md)

- [x] 17 orphan PRs (owner thread gone, green, conflicting for 1-2 days) merged to main, 12 of them as one merge train
- [x] Test flags: the coffee run moved to `--trend-job=9` (8 is Mrożulo's Dżemini call; both PRs had taken 8)
- [ ] Map PRs left to their owners (they touch centrum.json and need a re-bake): #485, #511, #515, #517, #518
- [ ] ~330 merged `claude/*` branches to delete: the cloud proxy blocks it; F runs `delete-merged-branches.sh` (project files, audit/) on the Mac
- [ ] Closed #455 (bump to 1.0.2, Android code 9) never reached main; F decided to drop it (branch on the delete list)
- [ ] Docs conflicts: many PRs edit CHANGELOG/BACKLOG/ROADMAP/CITY_INVENTORY and verify.sh's step lists at once, so every merge conflicts the next; a PR left 12 h with conflicts gets re-pinged

## Warsaw's trams, new and old (F, 2026-11-06)

F's six photos (newest tram, old pair, rebuilt pair; /mnt/project-files/new-trams/f-photos/). Built:
`tram_fleet.gd` (kinds CLASSIC, SMILE "Uśmiech", PAIR "Akwarium", PAIR_NEW), trams.gd `FLEET` per
tram, per-tram car length (the pair's 13.5 m cars), the vintage swap restoring each tram's own look;
check `tramfleet`. No maker's or model name anywhere: nicknames only.
- [ ] Phone look of the three new looks (day and night lamps), and the old pairs' share of the 8
- [ ] The newest tram's short three-section version, and the newest one's own bell/hum sound
- [ ] Old pairs: a squeal and a heavier rumble than the low-floor trams (sfx)

## Batch 4: Rondo ONZ towers, Platinum, Ilmet, Spektrum, Teatr Wielki (2026-11-06)

Cloud pass with Mapillary street photos only (refs/<site>/street/ on the cloud box; Commons and the orthophoto are Mac-only). Done: Ilmet (terracotta shaft `#8a5e4c`, `chamfer` stepped top; photos 2025-2026). Left, needs a Mac photo pass (street photos were night/rain, too far or the wrong building):
- [ ] Q22: only night-rain frames; needs daylight Commons photos of the sail crown and skin
- [ ] Rondo 1: street frames show curved blue glass, balcony ledges at the base volume and a dark-glass entrance pavilion; crown frame and base not rebuilt
- [ ] Cosmopolitan, WTT (the OSM building at (-2838,-154) is a 14 m podium; the Mapillary frames there show another building), Platinum A/B (frames 100+ m away), Spektrum
- [ ] Teatr Wielki: the Plac Teatralny frames show the side colonnade and the Jabłonowski palace; the side wings' colonnades are not built

## Warsaw Spire, Spire B and C from F's photos (F, 2026-11-06)

Rebuilt from F's ten photos (spec `docs/landmarks/specs/spire.md`, site `spire`, `spire_motion.gd`):
the swelling shaft and saddle crown, spines, steel columns, bow canopy, B and C's top storeys, the
crown's LED ticker (SAMSONG parody adverts), the plaza's pools, channel, islands, jets and trees. Left:
- Phone look and bench (+2 draw calls in view: the ticker and the jets); the ticker's text size from
  the follow camera, the jets' bob.
- The real canopy's double curve and the crown's points are approximations of the photos.
- The paving half disc north of the lobby is the first rebuild's; the plaza's own paving pattern
  (pale slabs, curved walks, hedge beds in IMG_7334) is the map's.

## Prosta 32, Prosta 28 and Łucka City from F's photos (F, 2026-11-06)

Built from F's photos (specs `prosta32.md`, `prosta28.md`, `lucka.md`). Left open:
- P28-1: Prosta 28's height. OSM says 80.2 m (tagged while it was being built); the photos and the
  render put it near 92 m, so the model is scaled to 82 / 89 / 93.5 m. Check against a published
  figure or a Mac photo with a known neighbour.
- P28-2: the tenant logos (a small red mark high on the tower, a logo on the annex) are one PROSTO
  word for now; the annex has none.
- P32-1: the lattice's diamonds are straight-sided; the real ones are rounded at the joints (the
  close-up of the arches). Rounding would cost about three times the triangles.
- LC-1: Łucka City's balconies are not modelled (the wings wear the white punched-window skin;
  balcony bands read blue from above); the tower's dark top is one colour where the photos show a
  grid of dark panels.

## Mrożulo's "Dżemini" call (F, 2026-11-06; docs/design/gaulle-and-food-hype.md G5b)
- Mac look check: DŻEMINI KEBAB's door on Świętokrzyska (52.23595, 21.0105 is a guess), the sticker's
  height beside the sign, and whether the 40-person queue blocks the pavement there.
- Phone: does the call come at a good moment (5 min in, van hours only)? Maybe tie it to the main
  line's first chapter instead.
- A TYGRAM inbox: the card is a one-off now; a phone screen with past messages could gather it,
  the DESKA call and Mrożulo's other news.
- A voice line for "Wjeżdżam w to" (radio takes tooling, Mac only).
- Found while building it: Mrożulo's van spot `hala_koszyki` has no road within 80 m of its place
  pin, so on that weekday the Mlask van never parks (trend_job.gd `_park_van` logs it with
  `--trend-log`). The Dżemini call falls back to his next spot; the Mlask job still needs the pin
  moved or a `near` hint.

## SOWA CLUB and CITY 25 (F, 2026-11-06)

F's three photos of the Sogo Club / City 24 pavilion. Done 2026-11-06 (site `sowa`, landmarks.gd
`_build_sowa`; crowds.gd `SOWA`, lines `sowa_club`): the pavilion on the lawn in front of
Al. Jerozolimskie 4-6, every name a parody (SOWA CLUB, CITY 25, PEPSZY, KACBERG). Left:
- **Where it stood**: the 2026 street photos and the GUGiK orthophoto show lawns there now and OSM
  has no outline, so the footprint (36 x 10 m plus the terrace) is placed from the photos against
  the block. A Mac photo gather (Commons, older orthophotos) would pin its real size and spot.
- **The printed glass**: the upper storey's car and city pictures, the round "24h / 7 dni" discs
  and the terrace's printed banner are plain colour; a texture pass would add them.
- **Phone**: the look of the pink glass and tubes at night, and a bench there (1,298 triangles,
  one shader branch for the pink glow).
## Novotel Warszawa Centrum from F's photos (F, 2026-11-07; docs/landmarks/novotel.md)

Built: the white tiled slab with its paired windows and the lift core's blank strip, the blank narrow ends round
their core bays with NOWOTEL in blue neon letter over letter, the orange rule and ACORN HOTELS, the top storey's
blue band, the plant room and the two white light boxes with the name on the roof, the glazed podium with its lit
fascia and canopies, and the east entrance (bowed cream bay, revolving door, blue NOWOTEL board, stone pier,
planters). Left:
- Which face the entrance is on: built on the east face (the mapped canopy is there); F's entrance photo does not show
  the street. Check on the Mac or with one more photo of the corner.
- The window rhythm (pairs in 6.2 m bays, 31 floors of 2.95 m) is read from one daytime photo; the lift core strip's
  place along the face is a guess (the middle bay).
- The podium's Marszałkowska front has no photo: built as two glazed storeys under a lit fascia.

## Zachodnia offices and BLUZOFT (F, 2026-11-06)

Done: Brama Zachodnia, Equator and Equator II re-skinned from street photos (refs/brama, refs/equator, refs/equator2, gitignored), BLUZOFT on Equator II's roof edge, the jokes (the real firm's name is in brand_denylist.json; only the parody appears). Open:
- Equator and Equator II keep the OSM footprints and heights (53.8 m and 50.5 m); the photos show stepped, curved faces, the perforated-metal car-park screen and the green-glazed Brama ground floor, none modelled yet. Needs a Mac photo pass from the tracks side (F's screenshot angle).
- An office crowd site at the Equator doors (the jokes only reach the Rondo Daszyńskiego crowd now).
## Miodowa's palaces from F's photos (F, 2026-11-07; spec docs/landmarks/specs/miodowa.md)

Built: seven palaces in photo-read skins (Branickich, Młodziejowskiego, Szaniawskich, Chodkiewiczów, Arcybiskupi,
Paca, Collegium Nobilium) and Pałac Branickich's modelled Miodowa front. Left, photos in F's `warsaw-other-buildings-part-1` (M197-M204):
- Pałac Młodziejowskiego: the pediment block and the two voluted wing gables round the cour d'honneur, the iron fence (M198).
- Pałac Paca: the round gate court and the green-copper roofs' shapes (M197); Collegium Nobilium: the tower block and the roof balustrade (M202).
- Pałac Szaniawskich's pediment and arched ground floor (M204); Pałac Prymasowski and Pałac Blanka on Senatorska have no ground photo yet.
- Branickich: Mac look check of the storey count under the cornice and the end pavilions.

## Centrum LIM's podium from F's night photos (F, 2026-11-06)

Done 2026-11-06 (spec `docs/landmarks/specs/lim-podium.md`, site `lim`). Left:
- **The tower's night look**: the photos show the hotel's name and the phone maker's name on all
  four faces; the game has them on two (south and east), and the lit cells are random.
- **A day look check**: only night photos so far; the panel colour and the signs by day are a guess.
- **The screens are still pictures**: real ones cycle adverts; a moving screen would need a script
  like Warsaw Spire's ticker.
- **Phone**: look and bench by Centralna at night (the signs are in the landmark signs' MultiMesh,
  the screens and marks a few hundred triangles in the building mesh).

## Street blocks across the city (F, 2026-11-06)

512 plain blocks are modelled, 50 of them along Nowy Świat with colours checked against street
photos (`game/data/street_blocks/`, one gzipped file each; sites `blk_<id>`, `_find_blocks`,
`_build_block`; panes M_PANE). They join the city mesh, are no landmarks (no card, no icon), and
collide on our outline. Blocks with real window openings bring their own roofs; the others keep
LoD2's measured roof over their walls (`keeps_lod2_roof`). Bench, prebuilt: Nowy Świat 131 draw
calls before and after, triangles 0.57 M to 1.10 M, video memory 323 MB to 405 MB, sectors 164 MB
to 185 MB. Left:
- **Phone**: the triangle total and memory on the iPhone.
- **#29 Nowy Świat**: still its old block; its LoD2 is one mesh with the wing behind.
- **Detail worth adding**: the long iron balconies of Nowy Świat 54/56 and 58.
- **Outside Nowy Świat** the blocks had a look for breakage, not a house-by-house photo check.
- **Photo fronts (2026-11-06)**: 17 houses keep LoD2's mass under street fronts read from F's photos (`game/data/photo_fronts.json`, `_build_photo_fronts`; styles classic, plain, ribbon, glass, fins). Weak evidence, check again: Aleje Jerozolimskie 11/19 (no facade photo), Solec 24 (photo shows the small house beside it).
- **Photo fronts, Marszałkowska (2026-11-07)**: 16 more houses from F's photos (Hotel Saski, Saski Park, Marszałkowska 41 to 140, ids `b<building index>`). Left: rows M015 to M019 and M023 to M035 have aerial photos only, so their fronts wait for street photos; Hotel Saski's curve and arcade are not modelled yet.
- **Photo fronts, Aleje Jerozolimskie (2026-11-07)**: 21 more houses along the avenue, Hotel Polonia's block and Nordic Park among them. Left: rows without street photos, and the murals at numbers 8 and 12, which are blank walls in the game.
- **Photo fronts, Świętokrzyska to Ujazdowskie (2026-11-07)**: 25 more houses on Świętokrzyska, Warecka, Chmielna, Nowy Świat and Aleje Ujazdowskie. Left: rows whose photo shows only a gateway, a courtyard or a detail (Mariańska 1, Chmielna 102, 126, 128, Żelazna 22) need a street front photo.
- **Photo fronts, Krakowskie Przedmieście, Senatorska, Miodowa (2026-11-07)**: 41 more houses, including the coloured row from number 37 to 67. Collegium Nobilium and Pałac Chodkiewiczów are left to the Miodowa palaces work. Left: Pałac Jabłonowskich and Małachowskich need their own builds.
- **Photo fronts, Długa, Aleja Jana Pawła II, Krucza (2026-11-07)**: 41 more houses, Freta and the Muranów blocks among them. Left: Aleja Jana Pawła II 32 has no usable front edge in its outline and stays as it is.
- **Photo fronts, Mokotowska and Hoża (2026-11-07)**: 61 more houses. Left: the small Mokotowska 69 rotunda and the shrine at 65, which fronts can't show; Hoża 1's bare firewall.
- **Photo fronts, Wilcza, Piękna, Targowa (2026-11-07)**: 83 more houses, which closes part 1 of the list (305 houses with street fronts in all). Left: part 2 (named buildings) and part 3 of the photo folder, and rows with aerial photos only.
- **Photo fronts, named buildings (2026-11-07)**: 46 more across the centre, 351 houses in all. Left for their own builds: Mała PAST-a, Pałac Przezdzieckich, the Elektoralna 12 portico, Mokotowska 25; Old Town rows 778 and 795 stay as they are; 189 named rows have no street photo yet.
## Quest map and starts (F, 2026-11-07; docs/design/quest-map.md)

Built: three map tiers (the main star's glow, questline "!" badges, street job icons), quest focus
(the map goes quiet while anything runs), the friend in person at a questline's start, and the
full map's WĄTKI tab that starts any questline now. Boat race, rave and the coffee run are in. Left:
- [ ] Padel, cinema tour and night meet: one `stories.add` each in `main.gd` `_build_stories` (their own threads)
- [ ] Phone look: the badge's "!" at minimap size, the glow under the main star, the WĄTKI tab with ten rows scrolling
- [ ] The friend at the start is the beacon's generic waving figure; give each friend their own look (Szymek's shirt, Ziomek in black)
- [ ] A speech bubble over the friend as they walk up, besides the card
- [ ] Bench by a start (the beacon: about 10 draw calls expected) on the phone

## Secret rave: LEKTI, Ziomek, Smoła (F, 2026-11-06; docs/design/secret-rave.md)

Built: night and day raves, LEKTI's voiced break-in on MORDOR FM, Ziomek's call and ride, the
strict three-question door, Smoła's cutaway room (option A). Left:
- [ ] Portraits and icons in one style (PixelLab, on the Mac with F's OK, about 50 generations): Ziomek, Bartek, LEKTI, Pan Kołek and the doorman on the call cards, icons for the door's questions
- [ ] Techno tracks for MORDOR FM (it has one mall track, so "pick a track" in the room is not built yet); ElevenLabs Music on F's Creator plan, then a track button in the room
- [ ] Phone check: the rig's beams and strobe at night, the room's look and the TAŃCZ timing on the iPhone; bench by an active spot (4 draw calls expected) and inside the room (3-4)
- [x] Other cards held during the quest (2026-11-07): no Podwózka request or "Na czasie" card while the rave run, the club or Bartek's tow is on (`main.gd`, `rides.away`); the calls were already held
- [ ] The dawn after: leaving at 05:00-06:00, Ziomek's last line, the city in the dawn look
- [ ] Opaski (wristbands) collected per spot, a card in the notebook
- [ ] Option B: a walk-around room (a person controller inside), only if A plays well

## Cinema tour "Kino objazdowe" (F, 2026-11-07; docs/design/kino-tour.md)

Built: Wiktor's call, the pickup on Plac Zbawiciela, four cinemas (Amondo, Atlantic, Kinoteka,
Muranów) with pitch cards, the reel's five frames, four optional shots, 30 lines of banter about
niche cinema (parody names), the pay; Kino Muranów rebuilt from F's four photos (spec
`docs/landmarks/specs/kino_muranow.md`); KINO ATLANTIC moved onto its OSM point.
Left:
- [ ] Photos from F: Kino Atlantic's front (Chmielna 33) and Kino Amondo's entrance (Żurawia 20), for poster facades like Muranów's; Amondo has no sign yet (a `Storefronts.CINEMAS` marquee there drops a Frogs shop below check_parodies' 80 % floor: give it a landmark sign instead)
- [ ] Phone look at Muranów: the letters' size, the festoons at night, whether the default camera sees the front (it faces east-north-east)
- [ ] The premiere as a scene: a queue in berets under the festoons at Muranów 20:30-21:00, a lasting evening crowd at its café garden (crowds.gd)
- [ ] A voice for Wiktor (later, like the night racing club's); a notebook card for the cinemas
- [ ] The Atlantic stop is on Widok, 70 m from the door (Chmielna is car-free there): a walk-round line, or a stop on Zgoda
- [ ] Autopilot run of the whole tour on the Mac (`--kino-tour=go`)

## Padel call at WTS DESKA (coordinator, 2026-11-07; docs/design/padel.md)

Built: the call opens like the boat race and the rave (ringing card with the caller's bio,
ODBIERZ / ODRZUĆ, a buzz, then the ask), a three-point match on arrival (LOB / ZE ŚCIANY / SMECZ,
five rallies), the helicopter landing remark, English on the call's buttons; fixed the late line
at DESKA (the generic three-a-side line overwrote it). Left:
- [ ] Phone check: the three-shot card fits beside the car at 2532x1170 with large text, the ring buzz
- [ ] hud.gd: a card with no spot that fits (a side card wider or taller than the room beside the car, a centred one taller than the screen) is never placed and stays hidden, so a quest waits on an invisible card (PT-30, 2026-11-07). Fall back to any spot, or log it
- [ ] PT-31 (map lane): the Solec-Zaruskiego service road is mapped as a bridge the car can't drive onto, so DESKA is reachable by car only from Czerniakowska (or by helicopter); Mac Autopilot 2026-11-07
- [ ] PT-32 (suspect): a district discovery card during the ringing call may end the call
- [ ] Hook the call into the quest map (PR #504's `stories.add`, docs/design/quest-map.md "Adding a questline") once it is on main
- [ ] A racket detour: the friend calls back mid-drive ("masz rakietę?"), a stop at a pro shop "Rakieta w Cenie" for +1 point's head start
- [ ] The court booked till the hour: the 8 min limit becomes the minutes to the full hour (at least 5), shown as "KORT DO 18:00"
- [ ] Ściana Płaczu, the rooftop glass court (padel.md idea), as a second venue for the call
- [ ] The DESKA players animate (a racket swing loop) while a match is on; now they stand
- [ ] PADELNIA's "Czwarty" (the proximity job) could open with a call too; it stays a queue offer for now, since the queue is the joke
- [ ] A match record in the notebook (won / played) and the hoodie as a cosmetic after 3/3
- [ ] Portraits for the callers on the ringing card (PixelLab, with the other call cards' portraits)

## Boat race "Wiślana Szprotka" (F, 2026-11-06; docs/design/boat-race.md)

Built: Szymek's call, the start pontoon at the mouth of Port Czerniakowski, the 3.2 km course of 26
rings under four bridges, three misses and you're out (JESZCZE RAZ / WYJDŹ), the rhythm and gold
rings, the planing physics with wakes and jumps, three rivals with their own temperaments, the sand
barge and its wake. Left:
- [ ] Phone feel (F): the turn and slide on the plane, the jump off the barge's wake, whether 16 m rings are too easy or too hard at the iso scale, the rings' readability at night
- [ ] The race panel (top right) covers rings and rivals ahead in some frames (Mac Autopilot, 2026-11-06): shift the boat lower in the frame while racing, or a slimmer race panel. The fail path (3 misses, ODPADASZ, JESZCZE RAZ, WYJDŹ back to the car) passed on the Mac
- [ ] A tall dark wedge at the top of the frame 11-13 s into the race (Mac frames): find what it is (a lamp post or a bridge pylon seen from above?)
- [ ] Ring 7 by Most Poniatowskiego's pier: a straight line from ring 6 brushes the pier (52 → 26 km/h in the Mac run); the rivals' curved line clears it. Maybe move ring 7 a few metres off
- [ ] `--boat-race=call` rings under the title screen and the 12 s card expires before the first tap (flag only; the real call waits 5 min of driving)
- [ ] A boat engine sound (the car's engine plays now) and a splash on landing; a rooster tail of spray behind the jet ski
- [ ] The ring's light at night (now bright unshaded colour, no glow); the rivals' boats are dark at night apart from their hulls
- [ ] Bench on the phone during a race (expected about +10 draw calls)
- [ ] A best-time record and a leaderboard line ("Ranking ulicy" has a place for it)
- [ ] More courses: upstream to Łazienkowski and back, a night course with lit buoys, the Port Czerniakowski channel as a slow slalom
- [ ] The marina (PR #251) as the start once the harbour's 8 m entrance can be widened or raced in single file
- [ ] Pan Zdzisiek fishing from the Złota Rybka after the race; Kamil's "relacja" as a ticker joke

## Walls, fences and the city walls from the map's data (F, 2026-11-07)

F after the stairs: "what else can you improve in the city environment?". Done 2026-11-07
(`tools/barrier_tags.py`, `map_builder.gd` `_mapped_style`, `_build_city_walls`): 1,100 walls,
fences and hedges carry OSM's height, material or fence type; walls coloured by material (brick,
stone, concrete, gabion, glass, wood, noise barrier at 4 m); 719 railing fences open steel railings;
chain-link fences and the 6 m ball-stop nets an open mesh (a solid fence is at most 2.5 m); hedges
their height (at most 3 m). The Old Town's city walls (22 OSM city_wall areas) were not on the map at
all: brick walls at their mapped heights (Baszta Rycerska 13.5 m, curtain walls 5-6 m by default).
Left:
- **City walls look check** from photos gathered on the Mac (batch2-old-town): battlements, the
  coping, the gates, the międzymurze's ground; heights where OSM has none are the 5 m default.
- **Most walls and fences still carry no OSM tags** (about 1,900 walls, 4,200 fences): a street
  pass from photos (Mapillary) can tag them in `game/data/road_objects.json`.

## Stairs across the city (F, 2026-11-07)

F: "look on the map to the places where we have stairs, map them and improve; if you need photos,
give me the list". Done 2026-11-07: `tools/stairs.py` copies every flight's OSM tags onto the map
(step count, width, which end is the top, handrails, pram/bike ramps, surface; 2,014 of 2,262
flights; the tags came from the Mac's OSM export, the cloud can't reach Overpass) and the walls'
mapped heights (179 walls); `bake_osm.py` keeps both on a re-bake; `stairs.py report` writes the
ranked inventory; verify step `stairs`. `map_builder.gd` `_build_stair_flights`: every flight that
drops at least 0.35 m over the drawn ground (or off a deck its step count says it climbs to) is a
stone flight (treads and ~0.16 m risers, landings where the ground levels off, cheek walls, OSM's
handrails, pram channels), in the building meshes (no draw call, no collider). The walls: OSM
heights used, fountain basin rings and small rings by a flight a 0.45 m rim, a wall across a flight
opened (not at a stairwell's dead end), short walls wrapping a stairwell a balustrade.
Photo list: `/mnt/project-files/stairs/stairs-photo-list.md`. Left:
- **Flights deeper than the ground shows** (about 400: the 10 m grid smooths any drop narrower than
  ~20 m): the Skarpa's long flights by the Muzeum Narodowe and Smolna (82 steps, 13 m mapped, 3.6 m
  on the grid), Karowa, Tamka, Dynasy, the BUW roof garden. Each needs a SUNKEN-like ground cut or a
  terrace, best from F's photos.
- **Stairwells to the underpasses and the metro** still flat under their walls/tubes (Rondo ONZ,
  Rondo Dmowskiego's twelve, Świętokrzyska, Ratusz Arsenał, Dworzec Gdański): the next SUNKEN entries.
- **Escalators** (`cv`, 50 flights, all in stations) are left as painted strips.
- **Collisions**: the stone flights don't collide (the car drives the ground under them, as before).
  Whether a long flight's cheek walls should redirect the car is a driving call for F.
- **Small wall rings away from stairs** (about 380 under 6 m across, many planters) still stand 1.9 m
  unless OSM maps a height: a pass by photos.

### Free ride and the marina's access (F, 2026-11-07)

Built: three boats from F's photos moored by the start pontoon, each with its own physics (jet ski
"Rekin X", electric "Srebrna Strzała", offshore "Czarna Pantera"), the PRZYSTAŃ pill and the marina
card (pick one or WYŚCIG), the free ride (no rings, clock or rivals; the barge passes for its wake)
with ✕ back to the car, the boat mark on the minimap and the full map. Left:
- [x] F's photos came in on 2026-11-07: 53 photos, kept in /mnt/project-files/port-czerniakowski/photos. From them the spit and the basin were rebuilt (sites `port_majami`, `port_wtw`, `port_halls`, `port_basin`):
  - MAJAMI WAWA, the parody of the open-air club at the tip: a timber terrace, two tents, festoons, fire pits and its white pontoon;
  - WTW's boathouse with its blue roof, gate, hexagon sign and anchors;
  - low halls in place of the 14 m blocks;
  - boats moored stern-to along both quays, with houseboats.
- [ ] The rest of F's port photos, still to build:
  - the mouth footbridge's green steel edges;
  - Pomnik Saperów's bar deck at the mouth;
  - the new arched footbridge over the basin;
  - the rental pier with its blue solar cabin;
  - the HERBATNIK barge on the slipway;
  - Przystań Warszawa's timber pavilions;
  - Monkey Love (Bulwar Flotylli Pińskiej 1A, south of Most Łazienkowski). Only interior photos exist; an exterior photo is needed.
- [ ] The MAJAMI WAWA and WTW neon signs did not show in the cloud's night frames. Check them on the Mac.
- [ ] The PRZYSTAŃ pill is up (logged, on screen at the top centre) but missing from the cloud's
  `--shots` frames; check on the Mac that it shows when the car stops by the pontoon
- [ ] Phone feel of the three (jet steering off the gas, the offshore's slow start), a way back to
  the mooring that parks it (now ✕ anywhere), an engine sound each (the electric one near silent)
- [ ] Free-ride Autopilot run on the Mac, 2026-11-07. Fixed in the same PR:
  - Czarna Pantera got pinned on the bank: added a push-off after 1.2 s.
  - The free-ride camera is now closer.
  - The card no longer says "almost 100 km/h"; the real top speed is about 75.
  Still open:
  - The wake breaks into "tyre track" pieces in turns.
  - Srebrna Strzała stops hard when the throttle is let go (43 km/h to 0 in 5 s).
  - Autopilot's ui() does not list the ✕ chip.
  - Not yet tested by driving: the PRZYSTAŃ pill when the car arrives from Solec, and reverse.

## Złote Tarasy 3D screen (F, 2026-11-05)
Built from F's photos (`tarasy_screen.gd`, `led_screen.gdshader`). Open:
- Phone look and bench check (the shader follows a ray into a box per pixel; cost is bounded by the
  strip's size on screen, 1 draw call). Wipe/scene timings, glow strength at night, the flowers' and
  the cat's drawing are first guesses to tune against F's videos.
- Rebuilt after F's photos and the Mac gather (refs/skylight/REPORT.md, 2026-11-05): the screen hangs on
  a graphite box over the entrance (the mapped plate raised to 38 m), an L in plan (south face + curved
  west return); Skylight (`_tarasy_skylight`) is silver-grey cladding with a dark window dash per floor,
  a dark lobby with a 5 m canopy, the 4-floor glazed belt at 20-33 m, and a roof scooped on the west
  half with an oval glass cap. Still to do from the report: slim round piers at the foot and the gold
  stair slits (the foot is plain dark glass), the podium's louvres and pink brick curved end, the roof
  crane, the Palace-side look. The Mac's photos show printed advert panels (older); F's photos show the
  LED screen, which we follow.
- More scenes for the loop (F's ideas: sea, a car driving out of the screen) and a day/night level pass.
## The Emilii Plater underpass entrances (F, 2026-11-06)

F's screenshots: walled boxes with steps on flat ground. Done 2026-11-06 (spec
`docs/landmarks/specs/underpass-emilii-plater.md`, site `underpass`, SUNKEN `epl_*`): the five
entrances within ~100 m of the crossing are sunk with stairs and passage mouths, and walkers go in
and come out (pedestrians.gd `_portals`). Left:
- **Look check from photos gathered on the Mac**: the parapet heights, the canopies' size and
  colour (only street photos from Mapillary so far), and whether the north pavement stair's dark
  glass box is a lift or a canopy.
- **The NW box's stair** is not mapped (only footway 8754 ends at its open side): built as one
  flight south. Check that its direction is right.
- **Further entrances not reworked**: the Śródmieście WKD ones west of Emilii Plater (steps 1665,
  224, 225, wall 485, about 120 m out), and the points the street pass named at (-1150, 575) and
  (-975, 545) on Jerozolimskie, which have no stairs mapped. The next SUNKEN entries.
- **The passages themselves** are not modelled: a walker goes in at one mouth and is gone, with no
  link to another entrance.

## The Patelnia sunk, the Rotunda's stair, the Wars wall (F, 2026-11-05)

F's screenshots and aerial (Operation Unslop thread): the Patelnia was drawn flat, the Rotunda's
stair to the underpass stood as a walled box, a grey slab stood before Wars. Done 2026-11-05 (spec
`docs/landmarks/specs/patelnia.md`, site `sunken`, `map_builder.gd` SUNKEN):
- **Sunken places in the ground**: a ring's floor wins over the 10 m grid in terrain_height, and the
  drawn ground is lowered in sub-cells over the ring grown by a sub-cell's diagonal (no slope inside
  the walls). The Patelnia at 10.0 m (3.4 m under Marszałkowska), its north-east and Kokota stairs,
  the Rotunda's stair (3.6 m down). Wall lines on a ring are the site's.
- **The site**: retaining faces, coping, a paving band over the trench outside, dark railings and the
  car's collision on every dropping edge; treads on the stairs; Metro Centrum's two smoky glass
  barrels (their OpenStreetMap boxes go) and dark wells; the Rotunda's glazed door at the stair's foot.
  The Patelnia's three metro canopies (storefronts) go: the barrels are the entrances.
- **Low walls** (`map_builder.gd` LOW_WALLS): Wars's 25 m planter edge on Widok and the Rotunda stair's
  planters at 0.55 m instead of 1.9 m.
Left:
- Mac/phone look check (QUESTIONS): the floor level, the railing's look, the barrels' glass tone, the
  Rotunda stair's door and whether the wedge is all stair.
- The stairs to the underpass by the Patelnia's south-east corner (`steps` by the mural's east end and
  along the east wall) keep their blue tubes at street level; F's aerial shows the corner one open,
  with treads. Sinking them needs the underpass level (deeper than the square) and their tubes'
  ground; parked.
- The other eleven stairwells round the roundabout are still flat under their tubes (sinking them is
  the same SUNKEN entry each, with the tube's base kept at the street).
- `tools/street_pass.py` (PR #441) was not on main when this landed: its `--check` runs once it merges.

## Autopilot findings on recent work (2026-11-06; docs/PLAYTEST.md)

- [ ] Bump the Autopilot add-on again once upstream releases past v1.0.0-753232a (HEAD has unreleased fixes #36 and #31).

- PT-23 (S2): the tow offer never comes while the ride button is up; a pinned car gets no help.
- PT-24 (suspect): backing off a wall resets the stall timer, so the offer may never come.
- Found 2026-11-07: `check_edge_roadworks` W3 reports lane 0 of edge 4520 (Bonifraterska) running off the
  map at -1727,-2317 past the barriers, on plain main too with the cloud's map pack (CI's map job skips it).
- Found 2026-11-07: at 1266x585 (the Autopilot's window) Settings' 'Średnio' fills its button to the
  pixel (check_hud flags it if that size joins SCREENS); desktop only, phones pass.

## Road design rollout: every street on the map (F, 2026-11-06; docs/design/road-design-rollout.md)

**Decision (F, 2026-11-07): main as base, small fixes.** F compared the area 3-7 redesigns with main
scene by scene and found main better in every one (Królewska, Świętokrzyska × Mazowiecka and Jasna,
Rondo Dmowskiego's arms, Jerozolimskie east, Nowy Świat south, Marszałkowska south). The redesigns
were measured truer to the photo but dropped what made main's streets read well: grass medians,
turn arrows, islands, slip lanes and lay-bys, cycle paths and crossings. They are taken out
(docs/roads/ keeps only palace.json, areas 1-2, which F approved; the dropped specs are in git
history at 0cfc1ff). Areas and progress: docs/plan/road-areas.json, `python3 -I tools/road_progress.py`.

- Areas 3-12 and tiers B and C: keep main's roads and fix only real bugs against the photo
  (ribbons overlapping in junction boxes, zebras shorter than the carriageway, tram beds paved to
  the stop line, broken mouths), never removing main's medians, arrows, islands or cycle paths.
  One area per round, before/after per fix.
- Lesson for any future design: carry over every OSM detail the photo cannot show (turn arrows,
  cycle paths and crossings, islands, slip lanes, lay-bys) and compare each scene with main before
  calling it better.
- Apply the Palace design (areas 1-2) to the shipped map after a phone bench.
- Main's real bugs, seen on the photo vs main at Marszałkowska × Królewska, Świętokrzyska ×
  Mazowiecka and × Jasna (2026-11-07), the same across the map, so they are fixed once in the bake,
  not per area: (1) zebras cover only part of the carriageway (often one lane or one direction);
  they should run kerb to kerb, or kerb to median; (2) cycle crossings are short red bars across a
  single lane, not the band across the street beside the zebra; (3) lane lines run on through the
  junction box; they should stop at the stop line or the zebra; (4) overlapping ribbons show darker
  patches in the junction boxes. Each fix keeps main's medians, arrows, islands and cycle paths.

## Road design system: round 2 (F, 2026-11-06; docs/design/road-design-palace-results.md)

- Seams where a designed street ends in the middle of a block: the old lane lines carry on up to 2.4 m
  to the side (7 line jogs for `road_smooth --check`, and street_pass K2/L2 rise). Close the area on
  junctions before applying it to the shipped map.
- Emilii Plater × Świętokrzyska and × Jerozolimskie (IMG_7264 "Y", IMG_7266 stepped widening) still
  come from the OSM ribbons.
- Marszałkowska's two U-turns through the tram bed (s 191, 283-291 from the junction): the spec has no
  paved gap in a tram median yet.
- The traffic lane graph still follows the OSM ways; make it from the spec's lanes.
- The GUGiK ortho predates the Marszałkowska crossings at Sienkiewicza and by the metro (taken from OSM).

## Loading bar on the title screen (F, 2026-11-05)

Built: `main.gd` loads `index.res` and `proxies.scn` with threaded requests under the title, the
build yields a frame (tree paused, 3D view hidden) after each of its 8 steps, and the start's
sectors fill the last stretch; `title.gd` draws the bar and the share ("loading bar:" lines in the
log give each step's ms). Test runs (no title) build in one go as before. Left:
- **Phone timing not measured yet**: the bar's step shares come from the cloud's software
  renderer (the city 10 %, the core 16 %, traffic and life 27 %, jobs and places 13 %, police and
  crowds 19 %, the rest 14 %); a run on the iPhone 16 Pro Max (and the 11) should read the
  "loading bar:" lines and retune `_load_mark`'s shares and LOAD_FILES / LOAD_BUILT.
- **The yields cost a frame each** (8 frames, ~0.15 s on the phone at most, the title only); in
  the cloud the threaded load of the two files took ~0.5 s longer than the plain load (the
  software renderer competes for the CPU there); check on the phone, else load them in place.
- **The engine's own start** (the light-blue boot splash before the title, while main.tscn and its
  scripts load) has no progress; the title's art as the boot splash image would hide it.

## Landmark look-check fixes (F's answers, 2026-11-03)
F's answers on the reviewed look-check page (look-check-answers.md in the project files), the smaller
ones. Shots in the project files, look-check-fixes/. Done:
- ~~Hotel Warszawa: wings-to-base join, portal, crown cornice~~: one granite plinth, stone ground-floor
  face and string course across wings and shaft; the wings rise to the back U's 25 m under cornices that
  turn the corner; the portal has dark reveals and a cornice slab; both cornices step out (1.5 / 1.1 m)
  over a shadow line (`_hw_cornice`).
- ~~Poczta's colonnade~~: a shallow recess between two piers, columns half in the front's plane, the red
  band as a canopy over the pavement; pale warm stone with a pink cast (`#ecd2c2`, skin too).
- ~~PAST-a's colour~~: darker weathered grey-brown (`#877667`), base and trim darker. OSM footprint kept.
- ~~MPW's pale bannered wing and deeper arches~~: MPW_LOW is a three-storey pale wing (12.5 m) with two
  hung banners and four flags; W2's arches get a wide archivolt and a dark reveal, piers 0.6 m out.
- ~~Norblin~~ (F's photos + the Mac's read of them): copper base (lit warm at night on the south faces),
  dark office storeys with fine fins, the top two set back behind planters; the glass-roofed passage
  between Galwan and Plater; the white workshops and the glazed hall on Prosta as white walls under dark
  zinc hips (they were generic boxes; `tools/bake_sectors.py` SITE_AREAS has their area). Card text: no
  chimney.
- ~~Browary's garden~~: the 17 young trees replanted in four clumps (`tools/planted_trees.py` "groups",
  an old map unplants and replants once: `browary@groups`; AO re-baked, 850 bytes changed), the path
  edged in dark steel, the clearings in pale stone.
- ~~Wschodnia~~: pleats 2.3 m deep and 0.9 m out, struts 0.42 m every 6 m spread 2.4 m; the two short
  suburban platforms roofed from x 2020 east (WSC_SUBURBAN_X).
- ~~Bazar Różyckiego~~: three units a side always; most old stalls get a patched sheet or tarp.
- ~~Pasaż Wiecha~~: the slabs light warm grey with a balcony ledge every storey; the Y masts stand to
  11 m with 2.2 m blades.
Found and left:
- Norblin: the glass roof's real extent and both court links (built: the gap between the two outlines);
  the gate through the white house on Żelazna with its lit sign; café tables in the lane; the
  rust-clad pavilion at the lane's far end; the lit stage pavilion at the glazed hall's west end.
- Wschodnia: the ortho shows the main platforms' rust roofs much shorter (about x 1878-1966, two
  pairs) than the built x 1860-2120 run; check with a photo before cutting them.
- Pasaż Wiecha: a Christmas tree on the pasaż for a winter event (F: yes; needs a season flag).
- MPW: the platform's overhang direction (west/south) stays provisional.
- The Norblin copper glow at night is flat and strong at phone size; a phone look should say if it
  needs toning down.

## The Bridge and Grzybowska 77 from F's photos (F, 2026-11-06)

Done (spec `docs/landmarks/specs/bridge.md`; photos in the project files, `bridge/photos/`).
Left open:
- The folds are drawn as seams over facets shaded a step apart; the real faces tilt in and out by
  a metre or more (the base corner tapers): a true folded mesh if the look check asks for it.
- The atrium's timber slats are only seen as the lobby glass's warm tone; no interior.
- Grzybowska 77's attic height (3 m over the cornice) is estimated from the aerial; OSM says 20.8 m in all.
- Phone look check: the tower and the block by day and night, the blue ERZATZ from the Towarowa side.

## Foksal 13 and 15 from F's photos (F, 2026-11-05)

Built (site `foksal`, spec docs/landmarks/specs/foksal.md). Open:
- Night: the warm uplights on the stone frames and under the balconies, and the glowing ground floor, as in the developer's night render (needs a lamp strip or a floodlit code for small fronts; measure the bench).
- F's look check on the phone or the Mac: the brick tones in the north front's shade, the gables' height, Foksal 15's dormers (LoD2's as they stand; no ortho was gathered).

## Lessons from Tiny Warsaw (F, 2026-11-04; docs/design/tiny-warsaw-comparison.md)

- **PWSM 1967 point blocks as one kit** (Jerozolimskie 135-141, Niemcewicza 24-25, Spiska 4A/16A, Grójecka 14A): candidate for the modernism lane, needs Mac photos first.
- **Infrastructure tier in CITY_INVENTORY**: Wisłostrada footbridges, Marszałkowska and Niepodległości tunnels, Czterdziestolatka flyovers.
- **Look lessons wait for screenshots** of their gallery (the cloud cannot render WebGL): F attaches 4-8 or a Mac browser pass.

## Developer console follow-ups (F, 2026-11-04)

Built: `tools/console.py` (README in `console/`). Open: C-1 road-objects census layer (tools/road_objects.py, PR #429) and
Mapillary-derived points once that lane lands; C-2 render pairs (before/after, A/B) from `tools/shot_sheet.py` with a
"pick one" state kept in the page; C-3 a Story tab (dialogue lines, quest chains, radio) and a Gameplay tab (tuning
constants by system, with the Settings screens); C-4 per-place data fields in CITY_INVENTORY (approach, sources) so
the "data used" colour is exact; C-5 a per-building design layer for the 115 hand-built sites (needs their positions
baked into a small JSON); C-6 deploy decision (subdomain, access) for F.

## Smoother roads, road objects, then buildings: the plan for the next days (F, 2026-11-04)

Research and plan: docs/design/roads-and-objects-plan.md; the items with status in
docs/plan/city-plan.json (dev console "Plan" tab). Builds on docs/design/road-objects.md (#429).
Found (measured on main): roads are OSM-centreline ribbons with a disc at every bend; only 38 of
461 km lie under a mapped carriageway area; 86 % of street junctions (2,262 of 2,639) are
overlapping ribbons with no kerb returns; 3,700 polyline kinks over 20°; OSM `surface` is not read.
Mapillary map features answer from the cloud (`tools/street_features.py`): the game has no traffic
signs, poles, junction boxes, hydrants or manholes; detection positions are 10-20 m off, so they are
evidence per street and junction, never coordinates.
- [ ] RS1 junction shapes with kerb returns + RS2 kink fillets (pilot: Marszałkowska × Świętokrzyska,
      Krucza × Hoża, Nowy Świat × Świętokrzyska), then city-wide; Mac re-bake
- [ ] RS3 width that varies along a street: tapers between ways done (road_smooth.py, 2026-11-05); ortho width profiles on the Mac left
- [ ] RS4 surfaces from OSM tags (setts, paving, concrete) by id in the ground shader
- [ ] RS5 tram beds and medians that read
- [ ] RS6 crossings with kerb drops, zebras aligned to the crossing way
- [ ] RS7 asphalt history (wheel tracks, seams, patches, manholes) in the shader; bench
- [ ] RS8 road height profile smoothed along the centreline
- [ ] RS9 markings from evidence (Mapillary presence, ortho look) per junction
- [x] Street-objects log per street (`tools/street_objects.py` → docs/inventory/street_objects.md) and
      the object budget (plan 3a, F 2026-11-04: log everything, add only what earns its place;
      signs, poles, boxes, cones are log only)
- [ ] Lamp density look test (Marszałkowska; Hoża has no game lamps), F picks
- [ ] Traffic-light poles A/B: all as now, or only at main junctions and the places that matter
- [ ] Open for F: a handful of gameplay signs (STREFA ZAMIESZKANIA, a trap's speed sign), or none
- [ ] Mapillary no-entry / one-way detections against the game's `oneway` (lane-graph check, no signs added)
- [ ] osm2streets (Apache 2.0, npm osm2streets-js) compared with RS1 on the pilot junctions (Mac)
- [ ] Open for F: Warsaw's city geoportal (base map 1:500 kerbs) licence before any use beyond looking

## Towarowa 22 and the Rondo Daszyńskiego towers (F, 2026-11-03)

- **Towarowa 22 built as finished** (site `towarowa22`, spec `docs/landmarks/specs/towarowa22.md`, from F's
  renders and photos): the tower row, the tanks block, Gutenberga, the printing hall's yellow frame over a
  garden, Pawilon DSP, Park Słowa, Nowa Wronia's paving, the drone port and the gilded last crane. Open:
  T22-1 the block over the Srebrna-end car park (the map's 31 parked cars and service road are in the
  way); T22-2 (none: every new block stands free of the kept buildings, so no pocket rings are needed); T22-3 a Mac/phone look check (the hall
  frame's density, the wavy crown, the signs' faces); T22-4 a photo pass once the towers stand.
- **Rondo Daszyńskiego towers by photo** (CITY_INVENTORY 60): rebuilt from the Mac's reports (2026-11-03).
  Second pass 2026-11-06 (reports plus Mapillary street photos): Unit's shaft tapers to 90 % at
  168.8 m under its crown, its base wings stand 9 m up over a glass hall set 6 m in (the gate);
  Mennica's 13 m ground storeys are an arcade of round stainless columns before a copper lobby;
  GPY has its black spandrel patches and dark top storeys, and decked terraces with trees and red
  tables on the Z and X wings; the HUB's towers have parapets and roof plant blocks and the podium
  its glazed skylight. From F's photos the same day: the seven Rondo Daszyńskiego metro entrances
  are the red glass butterfly canopies (props.gd `_metro_wings`, red lifts too), Unit's podium is
  warm grey stone panels, Mennica carries the bank's name as the parody MBĄK, Skyliner's fin is
  bronze-gold (photos in /mnt/project-files/daszynskiego-rd/f-photos/). Left: Skyliner's full-height
  gold strip and its recess band; Mennica's slanted crown with the open steel screen; the hotel's
  name band (a parody); GPY's grey stone grid and the Z/X wings' dark bands. RD-2b Mennica's plaza (the fountain and the steel ring: where they
  stand, from F's photos), its bulging plan and the west building's curved glass front; RD-4b the
  HUB's darker north-east faces; RD-5 a Mac/phone look check of all five, night photos (F offered
  photos 2026-11-06); RD-6 not found: a scan of every mesh round Skyliner and the HUB from 90 to
  175 m shows nothing floating, so it was probably something far beyond the loaded edge (close it
  if F doesn't see it again).

## Forest rebuilt from F's photos (F, 2026-11-03)

Built (spec `docs/landmarks/specs/forest.md`): the three-slab tower with crown bands, colour fins and PEPEO ŻUBR, the finned wings with black top storeys and roof gardens, the courtyard's amphitheatre, pavilion and 43 young trees. Left:

- **Wing heights** (F, 2026-11-03: estimate from the photos): the low wings are 31 m, eight storeys under the black top storey, against OSM's 20.8 m; the 27.4 m terrace wing keeps OSM's height so its crowd's deck (crowds.gd `forest_terrace`) stays put.
- **The roof boat** (F, 2026-11-06): a 10 m cobalt-blue bowrider on a cradle on the tallest slab's roof (`_forest_boat`), clear of the sign. Left: a crane or sling to explain it, a night glow.
- **The roof crane and the tower's lobby**: the window-cleaning crane on the crown and the glazed double-height lobby are not modelled.
- **Older docs still name the real tenant** in a few places (CITY_INVENTORY, LANDMARKS, QUESTIONS, MUSIC, inventory candidates, wiki_build.py): a sweep to the parody is open.

## Ground check holes in the far west

`check_ground` fails with 13 holes around `--at=-2591,905` to `-2861,1015`, and one at `-1711,-2765`, found 2026-11-05 on the modernism branch. They are far from anything that branch touches, so they came from elsewhere; not chased there.

## Warsaw modernism and brutalism (F, 2026-11-03, high priority)

F loves Warsaw modernism and asked for every modernist and brutalist building as good as photos allow
(Karowa 18, Kozia 9 and the Hammer building by name), a collect-them-all quest, and high priority.
Plan, ranking, facts with sources and the quest: docs/design/modernism-collection.md. Docs only so far.

- **Photo builds, in order** (CITY_INVENTORY 147-153, LANDMARKS P1b): M1 Młotek, M2 Kozia 9 and M3 Karowa 18a
  built 2026-11-05 (sites `mlotek`, `kozia9`, `karowa18a`); open on them: the Moliera side of Kozia 9 and
  Młotek's north face want street photos (Mapillary needs `MAPILLARY_TOKEN` on the Mac), Karowa's rear
  terraces; Kozia 9 did not reach L3 in review (see `docs/landmarks/kozia9.md`). Next: M4 Żyletkowiec, M5 Dom Chłopa, M6 NBP, M7 the Kopernika skyscraper, M8 Osiedle Za
  Żelazną Bramą (one slab kit), M9 Torwar, M10 BGK (built 2026-11-03, site `bgk`), M11 Ministerstwo Komunikacji, M12 Dom Słowa Polskiego.
  Each starts with a Mac gather (`refs/<slug>/`, REPORT with the outline's x, z) and F's "go" for the
  Remote Control session; Opus spec, Sonnet build, art-director against the photos, bench before/after.
- **Photo re-passes** that join the set: M13 Sofitel Victoria, M14 Plac Defilad's pavilions, M15 Muzeum
  Narodowe, M16 the Sejm's hall, M17 Warszawa Wschodnia.
- **"Betonowy album"** (Opus design pass, gameplay-dev build): Pani Wanda's lost slides as Kadr shots
  (`fotka.gd`), bundles of three, five story slides (Młotek from the helicopter, Kozia at walking pace,
  the Karowa bend's last slide, Centralna from above, the Rotunda at dusk), the Emilia KASETA then card,
  the "Betonowa" car paint for the whole album, its own map icon. Not before minute 10. Dialogue Manager
  not used (no branching). Needs `check_album.gd` in verify.sh and the flags in the archive's table.
- Facts marked *(confirm)* in the plan (Dom Chłopa's architect, NBP's years, the ministry, Torwar,
  the Emilia demolition year) are checked in each REPORT before a spec.
- Out of the map box, not planned: Supersam, the Ruda and Bródno estates, Hotel Felix, Żoliborz and
  Saska Kępa villas. Sezam and the Eastern Wall towers are the Ściana Wschodnia thread's.
## Starting street shop fronts (F, 2026-11-05)

Done from F's ten photos and the trade press (state Nov 2026): the stores' shops and ads come from
`game/data/eastern_wall_shops.json` (banners on the curtain walls incl. the street face, lit shop
fasciae on the recessed glass, pavement furniture), so a shop that closes is one line to change plus
a prebuilt re-bake; its words join the neon atlas by themselves. UNIKAT (Uniqlo, on Zara's old floor
in Junior since Oct 2025), LUKA bakery (LUCA, Sawa, Oct 2026), TAK MAKS (TK Maxx, 7,000 m2 on four
floors, Sep 2026; also the red box on `tower75`'s roof), FROGS XXL two storeys on H&M's corner with
green seats and cream parasols, KURCZAKI WKRÓTCE (the chicken chain coming next door). Metro
Świętokrzyska's mapped canopies are now M2's steel-and-glass triangle tents (`Props._metro_tent`).
Buildings from F's aerials: sedum strips along the main roofs (`roof_green`), TAK MAKS's red
portal, and `tower75`'s crown now PRALKA PLUS (the appliance maker's parody) beside the red TAK MAKS box;
KOKA-KOLKA is off the tower until the Sezam corner is built (Eastern Wall photo pass below).
Left:
- Phone look of the street-face signs (the camera sees the street faces edge-on when driving along
  Marszałkowska; they show when turning or rotating the view).
- When the chicken chain opens, give it a parody name in the file (KURCZAKI WKRÓTCE until then).
- Which Świętokrzyska entrances are the M2 tents is a guess (the mapped canopies); check on the Mac.
- Where exactly TAK MAKS's and LUKA's doors are along the fronts (press: "in Sawa"): Mac gather.

## Eastern Wall photo pass: Marszałkowska fronts, Sezam WACZEK, Coca-Cola sign (F, 2026-11-03)

Plan only, nothing built (F paused new work; this wants his "go" for the Mac photo gather). Scope F set:
- **Fronts of Junior, Sawa and Wars on Marszałkowska only.** Pasaż Wiecha's frontage is covered by
  `dt_pawilony` (site `wiecha`). Today site `dtc` is a cloud model corrected by one Mac photo check
  (2026-11-01); there is no `refs/dt_centrum/` REPORT, so redo it the photo way: Mac gather into
  `refs/dt_centrum/` with SOURCES.md and a REPORT in game coordinates, then the build.
- **Corner and glazing at Widok:** F's photo "Dawne Domy Towarowe Centrum, ul. Marszałkowska" (Wars's south corner on Widok,
  H&M corner, huge printed banners over the glass, the rounded cornice with CCC / H&M / C&A / TK Maxx on the roof band)
  is the reference where the Wars and Sawa models meet. Also the two aerials (Varso view, drone view): HalfPrice, adidas,
  TK Maxx, H&M banners, green roof strips, plant on the roofs, the Amica tower behind.
- **McDonald's = WACZEK at the former Sezam**, Świętokrzyska corner (the glass block with the SEZAM sign and the McDonald's
  on its ground floor, F's photos), NOT on the Junior-Sawa-Wars fronts. Its own yellow wordmark and sign shape
  (Storefronts.HYPE `waczek_*`, upside-down W). Add a `waczek_sezam` site; the Sezam block itself (the old Sezam
  department store, now the glass office with the SEZAM name) is part of the same pass.
- **Cola sign (F answered 2026-11-03):** put it on the rooftop at the Sezam/Centrum corner (Marszałkowska x Świętokrzyska), as an
  original parody wordmark (real brand never used; the existing KOKA-KOLKA on `tower75` is the style to check against so the
  two do not repeat). **Amica** gets a fictional appliance-brand name on its tower roof too (pick one, e.g. AMIKA is too close:
  use something like ZMYWAKA or PRALKA PLUS, Polish, affectionate). Both are lit roof signs, `_dtc_sign` style.
- **Chmielna:** keep the street clean, no excavation or roadworks. **Pasaż slabs:** the report's grey-white #D8D8D4 with a
  slightly warm tint (palette change in the existing `wiecha` model).
- Open for the gather: the Sezam corner's exact outline, the Żabka corner on Wars. (2026-11-05: the Amica parody PRALKA PLUS is on `tower75`; the cola sign is off the tower and waits for this Sezam build.)

## The helicopter high up (F's playtest, 2026-11-03; GAMEPLAY_PLAN 0.4 / 3.1)

The framing, the far plane and the height cap are fixed (heli-view PR, `check_heli_view`; the
cause and numbers are in GAMEPLAY_PLAN 3.1). Left:
- Phone check (P15 on the Mac, F's yes): fly to the cap over the Palace, Varso and the east edge;
  feel of the 220 m cap (it pulls the helicopter down at -11 m/s when it leaves a tower).
- Horizon haze (plan fix 4) not built: no cut ground showed after the far fix; build it only if the
  phone still shows a hard line. The far half of a 360 m view shows sector proxies for a few
  seconds while they stream in.

## Open courtyards (F, 2026-11-03)

F: "some kamienica from the top have the hole in the center, I want it where it has one". Found: the
GUGiK LoD2 blocks (most of the centre) already show their courts, since each model is roofed only
where the building stands (shots from above at Hoża). The gap was the hand-built landmark models that
lift a mapped outline: bake_osm keeps only a multipolygon's outer ring, so the Ministry of Finance,
the National Museum and Hotel Bristol had one solid roof over real courts. Done: `tools/bake_courts.py`
traces every closed-in, roofless patch of 30 m² or more inside a mapped outline from lod2.bin (187
courts, `game/data/courts.json`, verify step `courts` checks it against today's map files);
landmarks.gd `COURT_SITES` (mf, muzeum, bristol) cuts them out of the site's flat tops and walls them
in, with window bays every 3.6 m and storey. The Palace already had its courts (`P_COURTS`). Open:
- OSM-only buildings (no LoD2 model, mostly newer blocks: Oxygen, offices with atria) still lose their
  inner rings in bake_osm (`main`'s multipolygon loop reads only `outer` members). Keep the inner rings
  in centrum.json and let map_builder `_build_buildings` draw them (walls facing in, roof cut); needs
  the raw OSM export, so a Mac re-bake (the cloud has no OSM access).
- Hotel Europejski: its LoD2 model (2018, mid-renovation) is roofed over the court, so no court is
  traced; the photo rebuild (PR #402) hand-models it (a 14 m ring, inner walls, glass roof at
  8.5 m), so "europejski" stays out of `COURT_SITES` (no double court).
- Other sites the trace finds courts in, left as built: Złota 44 (127 m², a gap of the 2018 survey
  by the tower), Pasaż Wiecha (152 m²), St Anthony's and the Reformed church (64 and 37 m², small
  cloister or light-well courts). Add a key to `COURT_SITES` after a look check.
- Mac look check: the three courts from the helicopter and the game's angle, day and night (the court
  walls' windows light like the model's own bays).

## Trybunał Konstytucyjny, al. Szucha 12a (F, 2026-11-06: parked until the map grows south)

F asked for the Constitutional Tribunal as a landmark. The building is OSM way 30871847 (52.215631 N
21.023906 E), game x -6, z 2031, footprint x -35..22, z 2013..2049 (about 57 x 35 m, 3 levels, hipped
roof). The baked map ends at z 1736, so there is no ground, street, LoD2 or neighbour there (the Prime
Minister's Chancellery, way 30871838 near x 38, z 2012, and the modern semicircular hall south of the
Tribunal are missing too). F chose to park it (2026-11-06). The job: grow the map south by about 330 m
(map lane: bake_osm BBOX and tools/map_shape.py, the whole chain, check_map_data counts on purpose, new
map pack, bench before and after), then build it from the photos gathered on the Mac (refs/trybunal/:
6 Commons photos, GUGiK ortho, osm_way.json, REPORT.md). What the photos show: ground floor, tall upper
floor with a Greek-key frieze, dark metal mansard roof with 5 round dormers, bowed corner bays, a
sandstone portal with an arched door and a stair each side, a flagpole at the roof centre, a round
cobbled drive. Open: which face of the U carries the entrance (the ortho shows a planted courtyard with
no drive); heights are estimates (eaves about 11-12 m, ridge 17-18 m). Landmark model needs
`_collide_raw` and pocket_rings.

## Grow the map north-east (F, 2026-11-03: not now)

Koneser (1426, -2355), Park Fontann (the Multimedia Fountain Park, -868, -2208) and Ząbkowska's bar
strip (x 1020-1080, z -2080 to -2110) lie in the map box's cut north-east corner (`centrum.json`
"outside": z < -2045 east of x -1706). F (2026-11-03): add to the backlog, don't build yet. The job
(map lane): grow bake_osm's map shape (tools/map_shape.py), re-bake the chain and the LoD2/terrain
on the Mac, publish a new map pack, then build Koneser, the fountain park and Ząbkowska's bars from
the photo reports already in (QUESTIONS 2026-11-02 and 2026-11-03).

## Driving first: the gameplay plan (F, 2026-11-03)

F's playtest (13:22): "the map and buildings are good now; I want to make the driving the best
experience". The plan, the road audit and the causes are in docs/GAMEPLAY_PLAN.md; its phases:
- [x] 0.1 Map teleport and tow land in a tunnel (2026-11-03): `_same_level` took a tunnel's floor as
  "the ground"; now tunnels only from inside one, main-network lanes first, the teleport checks the
  car's box, a hold over the river lands on the bridge; verify step `teleport` (11 spots; 2 failed
  before). Autopilot P12 checks the drive-off
- [x] 0.2 Chatter budget (2026-11-03, `chatter.gd`, `check_chatter`): every bubble has a class (quest,
  police, reaction, ambient); at most 2 up and one new every 4 s; one reaction in 20 s, none for a
  bump under 15 km/h, a near miss once a minute; city lines silent while the car is pinned, pressing
  into something, stalled or offered the tow, and 5 s after; ambient waits while a card or the full
  map is up; the ride's star toasts merge into one; Settings → ŚWIAT → Gadatliwość miasta. Phone
  feel parked (QUESTIONS)
- [x] 0.3 The car shows through Trasa Łazienkowska and other decks (2026-11-03): the tunnel x-ray
  whenever a deck stands between the car and the camera (`map_builder.gd` `deck_hides`,
  `check_deck_xray`); phone look open. 2026-11-07 (F: "only a halo under the bridges"): the
  occlusion ghost now cuts the decks too, the same dithered circle as behind buildings, so the car
  and the traffic under the Trasa, Most Łazienkowski's land spans and the viaducts show as they
  are (`ground.gdshader` deck ghost: a deck's surface 2.5 m or more over the car's ground, from the
  surface map's deck height; the slab, piers and rails were already ghosted by `building.gdshader`).
  The silhouette stays for tunnels (and decks with --no-ghost). Phone bench (iPhone 16 Pro Max, iOS
  27.0.1, Ultra, A/B alternated): no cost from the ground shader's new discard: 60 fps everywhere,
  1 % low 55.5-56.9 both builds under the Trasa and the Poniatowski viaduct, bench route 51.2 / 50.5,
  one draw call fewer under decks (the silhouette's). Open: the iPhone 11 bench (its developer
  certificate wasn't trusted) and F's look on the phone
- [ ] 0.4 Helicopter high up: heli framed at the top, far plane clips the ground (floating buildings,
  blue sky), height cap, horizon haze
- [ ] 0.5 Plac Piłsudskiego's paving reads as a chessboard: lower the panel contrast, speckle
- [x] Classic controls the default (F, 2026-11-04: "driving with left, right, gas and brake should be
  the default"): settings.gd `DEFAULT_CONTROLS`; a save from before (no `[controls] classic_default`)
  that says Point loads as Classic once, a Point picked since stays; the first-10 ghost finger and
  its hint show the GAZ pedal and the steering strip (pad and keyboard lines too). Open: F's phone
  feel; the Autopilot harness on the Mac now gets Classic's keys (A / D steer, W gas, S brake) in
  editor runs unless it passes `--controls=point`
- [x] Walls redirect in Classic too (2026-11-04, collision rework v2 step 1, road-objects.md 7.1):
  the wall follow lived only in Point's aim, so with Classic the default a head-on wall stopped the
  car dead and the unstick turned it out after 1.5 s. `car.gd` `_classic_wall_steer`: gas on and
  the nose into a wall (a car or tram after CAR_PUSH_TIME), the steering turns it along the wall,
  the side the strip leans (past 0.2) or else the nose; a harder turn of the player's own wins.
  `check_steering` head-on Classic: 0 → 19 km/h a second after the touch, pinned 1.4 → 0.4 s,
  no unstick (now a gate: `wall_headon` pin 1 s, no unstick, all schemes; `wall_headon_right`:
  the strip picks the side; `car_behind` now asks Classic too). Found on the way: the unstick
  could turn a 4 m car across a 3 m gap, half into the walls, and driving on pushed it out
  through one (Point escaped `check_stuck_offer`'s pen; Classic now did too): the unstick only
  picks headings the car fits in (`_fits`, under 0.15 m into anything). Open: F's phone feel
  (how firmly it turns off a wall), the same for buildings and traffic in rework v2
- [ ] 1.1 `check_drivability.gd`: every lane, turn and dead end with the player's car; per-street score
- [ ] 1.2 Lane graph data: 101 nodes off the main network, 15 kinks over 45°, ~300 lanes under 2.5 m
- [ ] 1.3 Autopilot rows P11-P16 (PLAYTEST.md)
  2026-11-04: P12 drive-off works (43-55 m in 3 s); P14 and the three Trzy mosty legs drive clean
  steered (`check_lane_drive`, verify step `lanedrive`; PT-21 closed, not a road bug). Left on the
  Mac: a harness that follows a route (P15 flights to Varso and x 2100, P16 frames at race speed)
  and the map hold at -700,900 that left the car in place twice (PT-19, intermittent)
- [ ] 2.x Road fixes by street, forgiveness bevels, trap dead ends gated, score baseline in CI
- [ ] 3.x ~~Lane assist~~ (built 2026-11-04 behind a switch, see "Beta values"), wall look-ahead, junction pick, ~~deck cut in the ghost~~ (done 2026-11-07, see 0.3), F's phone run
- [ ] 4.1 Running clubs read as a blue blob at crossings: mixed kit, pairs, spread out
- [ ] 4.2 Varso Place masses from photos (the gap between the tower and Varso 1/2)

## Dead electric cars: Bartek's TESŁO and stranded EVs (F, 2026-11-06)

Built (`game/scripts/ev_tow.gd`, check `evtow`): a call from Bartek (ODBIERZ / ODRZUĆ, then LECĘ!),
the helicopter takes off, the TESŁO Model Ś (parody: white fastback, green plates) hooks on a 10 m
sling (damped pendulum, the loaded helicopter 25 % slower), set down on a charger bay by
Elektrownia Powiśle, Hala Koszyki, Złote Tarasy or the Palace (Marszałkowska); 180 zł + 30
respect, +60 zł under 150 s. Bartek's lines (`ev_tow`), stranded drivers (`ev_stranded`), KEBAB FM
(`radio_host` tag `ev`); "tesla", "elon musk", "supercharger", "cybertruck" on the brand denylist.
Stranded TESŁOs (every 3-5 min, kerb lane of a main road, hazards blinking, traffic goes round an
invisible parked car) can be carried from the helicopter for a 60 zł tip. Open:
- [ ] Phone feel of the swing and the slower loaded helicopter (QUESTIONS), and of the first call at 5-8 min
- [ ] A ringtone and a winch sound (sfx.gd has none; Access.buzz only)
- [ ] The charger bays are the kerb lane by each place: real charger spots from OSM (`amenity=charging_station` is not in our extracts) and a Mac photo check
- [ ] The car hangs through roofs lower than it (it rides over them): fine for arcade, check it reads on the phone
- [ ] A QUESTS list row for the call (quest_lines.gd) and a map marker for stranded cars
- [ ] An egg-book card "Zielone tablice" after three carries

## Crazy drivers in traffic (F, 2026-11-05)

Built (spec `docs/design/crazy-drivers.md`): Szkoda Oktawia taxis, Szprynter couriers and one Pasatini 1.9 TDJ drive in racer mode with no route (traffic.gd `CRAZY_*`, `crazy_drivers.gd`, check `crazy`). Open:
- [ ] Phone feel of the speeds and cut-ins (QUESTIONS), and an Autopilot run on a busy street
- [ ] Couriers stopping with hazard lights in the lane for a drop, then racing off (the meme; needs a parked-in-lane state like the crash scenes)
- [ ] A Pasatini egg-book card ("everyone has seen it, nobody has caught it") and a chase side job
- [ ] Black smoke puffs from the Pasatini when it pulls away (one particle draw call: bench first)
- [ ] Headless overlap count with crazy drivers: about 120 frame-pairs in 90 s, all off screen (one stopped Pasatini beside a car of a neighbouring edge at Marszałkowska x Świętokrzyska); check on the Mac in view

## Street races: rivals that race (F, 2026-11-04)

F: racers like Pani Halina drive very slowly and by the rules, never take a shorter way; races
don't look competitive or fun. Research, code audit and plan: `docs/design/street-races.md`.
Causes found: race rivals are town cars with pace 1.25-1.5 x the speed limit (62-75 km/h vs the
player's 108), 3.3-3.9 m/s² vs 15, 20 km/h right angles, stop for 40 % of reds and every crossing
car, queue behind buses and the player, legal shortest-by-metres routes only; the first race's band
holds Halina 25 m behind the player (pace 0.4-0.85). F (2026-11-04): "make the racers and the
police smarter, then test with Autopilot": R1, R2, R4's numbers and the police chasers built
(street-races.md section 6), measured with `tools/race_ai.sh`.
- [x] R1 racer driving mode: race top speed from the player's car, 7-10 m/s², corners by radius, through reds, overtake traffic and the player, slip out of junction knots (2026-11-04)
- [x] R2 fair rubber band: the first race with Halina in front to chase, every race's band by rung, boosts only off screen (2026-11-04)
- [x] R3 part 1: shortcuts across plazas, verges, yards and car parks (`tools/race_cuts.py` -> `game/data/race_cuts.json`, 600 cuts; `race_cuts.gd`; knowledge per rival; routing counts only cuts the racer takes; verify step `racecuts`) (F, 2026-11-05; street-races.md section 9)
- [ ] R3 part 2: wrong-way hops along one-way streets (needs oncoming-car checks on a cut), routes by time, the rival's shortcut shown after a loss
- [x] R4 part 1: racing share, pull, corner grip, band and aim per rung (2026-11-04)
- [x] R4 part 2: rivals lead (aim ahead from Słoik up, Mike at the player's top speed, 12 s opening burst, higher side-street caps, grip in the band), mistakes near the player, Słoik's wrong turn, Mike's phone, blocking (one lateral move) and cutting in, their lines (F, 2026-11-05)
- [ ] Contact nudges from aggressive rivals (Seba) beyond the block; phone feel of the new rivals (Autopilot P17 rerun)
- [x] Police chasers in racer mode: quicker pull, corners by radius, careful through reds, round traffic; top speed still 0.8 of the player's (2026-11-04)
- [ ] Phone feel of the races and chases (F's next device run); Autopilot row P17
- [x] R5 part 1 (2026-11-04, beta values): the route to the finish on the minimap (Trzy mosty: to the next bridge), the gap in seconds, a lead-change toast and tick, the finish margin on the card (`check_ladder`)
- [ ] R5 part 2: the rival's own edge arrow; slipstream (A/B 9 in QUESTIONS)
- [ ] R3 note (beta values R-4): rivals still route with the off-map links (`rivals.gd _distances`); the player can't drive them. Fix with routes by time
- [ ] R6 the city reacts (honks, police on the rival); R7 race kinds (later)
- [x] Race-AI runs: `tools/race_ai.sh` (every rival vs an average and a skilled autopilot), `--race-debug` (2026-11-04)
- [ ] A headless `check_race_ai.gd` in verify (the runs take ~25 min: too long for verify; a short fixed-route version)
- [ ] Street racer leaderboard "Ranking ulicy" (F, 2026-11-04; design in street-races.md section 8): 20 made-up drivers ranked by street points, win to climb, defence challenges, tier unlocks, an APKA: WYŚCIGI screen and best times per route; local first, online best times only with F's yes (L1-L5)

## Beta values: deliveries, races and steering (F, 2026-11-04)

F: test the gameplay and improve its two main beta values, the delivery mechanic and the racing with
the steering. Review, findings and the A/B list: `docs/design/beta-values.md`.
- [x] Deliveries: the route to the door on the minimap (`route_line.gd`, re-walked from the car every second); road lengths for orders, rides and "Na czasie" without the off-map links (~1 order in 30 counted a closed road out); the heat's clock in words; NASTĘPNE on the delivered card points at the stand nearest by road (`check_delivery`, verify step `delivery`, in CI) (2026-11-04)
- [x] The police runs P3 and R1 failed on main since #426: the escape test car rode a town-car ghost; it now drives in racer mode (2026-11-04)
- [x] Races: R5 part 1 (see "Street races") (2026-11-04)
- [ ] F's phone A/B 1-11 (QUESTIONS "Beta values A/B", four entries)
- [x] Lane assist "Asysta pasa" (GAMEPLAY_PLAN 1.5 item 1, test D2): Settings → Jazda, Classic only, off by default; pure pursuit 0.9 s ahead on the lane, a pull of 1.5 × the heading error while the strip is near the middle (`lane_assist.gd`, `check_lane_assist`, verify step `laneassist`, `--lane-assist=on|off`) (2026-11-04)
- [ ] A real-map hands-off drive with the lane assist (Wisłostrada, Trasa Łazienkowska, the bridges): `check_lane_drive` with a Classic driver
- [ ] GAMEPLAY_PLAN 1.5 items 2, 3, 5: wall look-ahead, junction pick, camera lead at junctions
- [ ] If F picks them: the delivery streak "Seria", a smooth tip, slipstream, a shorter card wait

## Main's road bugs (F, 2026-11-07: main as base, small fixes)

Checked on the photo against main at Marszałkowska × Królewska, Świętokrzyska × Mazowiecka and × Jasna,
then whole-map in `tools/road_fixes.py` (run after road_smooth; verify step `fixes`, ratchets).
- [x] Lane, centre, solid and bus lines ran on past the zebra or stop line into the junction: cut in 1,682
  mouths (7.7 km), and on another main street's ribbon (90 m); a line whose cut would read as a jog stays
- [x] Turn arrows painted past the zebra (some on the stripes): 406 moved behind the stop line, 60 dropped
  (the lane already had an arrow there, or no asphalt behind)
- [x] 61 zebras under 1 m (dots left by the asphalt clip) dropped; zebra ends short of the kerb run on (158 m)
- [x] Dark patches in junction boxes: not in the game (every ribbon and area is one colour at one height);
  they came from the flat comparison pictures, which draw ribbons half transparent over the photo
Found:
- [ ] Zebras and cycle crossings already run kerb to kerb (or kerb to median) on the data: no dual
  carriageway crossed on one side only, 1 cycle crossing shorter than its zebra. What still reads as
  "short" on the photo is the stripe length: the game paints 3.6 m everywhere, the photo shows 4-6 m on
  main streets (a map_builder change, not done: F's call, main as base)
- [ ] Lane lines through a junction where the same street turns (one name both ways) are kept
- [ ] Unsignalled crossings more than 12 m from the junction's ribbons count as mid-block (lines kept)

## Operation Unslop: streets that don't look generated (F, 2026-11-05)

F: "unslop the roads and the objects on them, make the streets prettier, street by street, using
every workflow we have (maps, real street maps, photos), with Marszałkowska between Centrum and
Świętokrzyska as the test, so it then improves the other places by itself; classify every object
to a model we have, model the missing ones, and keep a database of models in the CRM". Plan:
docs/design/operation-unslop.md (merges roads-and-objects-plan.md and road-objects.md). Tools:
`tools/street_pass.py`, `tools/model_library.py`; records in docs/streets/, library in docs/models/;
skill `street-pass`, agent `street-unslopper`; console tabs Streets and Models.
Found: the test street's west carriageway changes lane count between OSM ways (2/3/2 lanes,
6/10/6 m) where the street is the same; 16 lane lines end mid-block; no balustrade, tram railing,
canopy-on-posts, Jersey barrier, yard gate or park fence model exists (library "wanted").
Found: only 559 of 45,192 scanned trees stand inside a lane, none on the test street; trees on the
road in F's shots are the drawn strip covering a real median (check T1 looks at the drawn surface).
- [x] Pipeline, checks, records, model library, agent, skill, console tabs (2026-11-05)
- [x] Lane lines cut at zebras (bake_roads `_crossed`, whole map; 643 of 2,177 zebras had a line across), L2 reads a zebra cut as intentional (2026-11-05, Mac re-bake)
- [x] Smooth joins (F, 2026-11-05 "smooth, like hand designed"): `tools/road_smooth.py` (run by bake_osm, also on a baked map) tapers the asphalt where two ways of a carriageway change width (799 joins: the narrower way flares to the wider one over 20-30 m, no round cap bulging past the kerb), moves kerbs and edge lines that jogged with the step, stitches lane lines across joins (2,483) and rounds small line kinks (3,116); edge steps 727 → 12, line jogs 969 → 16 ; where a smooth kerb runs past a flare the asphalt follows the kerb, and no flare beside a driveway mouth; streets drawn 0.3-3 m short of a tram bed go out onto its ballast (23 ways, Mapillary 2026-08-30 shows the asphalt meeting the tracks) and kerb breaks along a tram bed are closed; service roads always drawn under streets; a way narrower than its street at both ends takes the street's kerb line (64 ways, F's satellite lesson: kerbs run straight, lanes change by paint) (verify step `smooth`; street_pass K1, K2)
- [x] Workflow speed-ups from the first street's logs (probe, evidence pack, rule-bug alarm, multi-spot shots, roads-only bake, Haiku scout) (2026-11-05)
- [ ] `overlay_ortho.py --plain` (no overlay lines, to read paint) and the flight date in its notes; raw OSM extract in the map pack so bake-rule changes can be baked in the cloud
- [ ] Chained-carriageway lane painting with tapers (L1, 354 joins city-wide); today's lanes override; `lane_split` width sanity
- [ ] Lane changes as paint (F's satellite shots 2026-11-05): within one street's kerbs a new lane starts as a line out of the edge line with hatching in the spare width, instead of the edge moving; lane widths from the street's width, not each way's count
- [ ] Crossing kit poles (road_smooth crossing_kit, 82 at 79 zebras across main streets with no mapped signal) have no lit lamps and no controller: give them a ped/vehicle cycle, and check the places on Mapillary (some may be unsignalled)
- [ ] Lane changes inside straight kerbs: a widened way spreads its lanes over the chain's width (spread_lanes); F's round 3 asks for 3.25 m lanes from one edge with chevron hatching in the spare width (round 4 asked again: edge-connected white chevrons where the lane count changes; not built yet, the reference view at Złota has no such change left in sight)
- [ ] Tram medians have no collision: a car can cross the gravel bed anywhere, so the U-turn opening is a look, not a route the car needs (decide whether medians get kerb collision outside openings)
- [ ] The 10 joins left with a step have no room for a taper (ways shorter than 8 m between joins): merge such stubs in the bake
- [ ] Test street fixes and F's look (see the street record docs/streets/marszalkowska-centrum.md)
- [x] Barrier overrides by stable id: `street_pass.py --apply` writes game/data/road_objects.json from the records and hand `decisions`, map_builder draws REMOVE / styles; `tram_railing`, `balustrade`, `balustrade_rail` styles (2026-11-05)
- [ ] The other wanted models
- [ ] More classify rules from the test street's hand calls; then the next streets
- [x] Lessons from the smooth-roads thread (2026-11-05): `verify.sh --roads` (the road-loop set instead of ~100 steps), fixed cameras per street (`cameras`, `street_pass.py --spots`), target image step (Codex on the Mac, a target never evidence), rounds and one thread per round with a handoff note, guesses tagged template-default
- [x] The four streets round the Palace of Culture (F, 2026-11-05): Marszałkowska 70 → 83 (#441), Świętokrzyska east 83 → 92 / west 80 → 82 (#461, lines cut at zebras and edge lines seated after the smoothing, island walls as 0.2 m granite kerbs), Emilii Plater 85 → 93 (#462, lane and centre lines carry on past bus-bay and driveway mouths), Jerozolimskie 90 → 91 (#463, zebra reach 5 m, cameras at yaw 135); before/after pairs in project files unslop/palace-before-after
- [ ] Palace streets, left from the pass: the Świętokrzyska median kerb near (-1495, 11); bus-lane line ends on Jerozolimskie (L2 at s 121, 136, 367); O1 parked cars on Jerozolimskie (15); L1 lines inside junctions; the Rondo Dmowskiego approach apron; Złote Tarasy bus loops and ramps (need a photo)
- [ ] Underpass and metro entrances at Emilii Plater / Jerozolimskie drawn as walled boxes on flat ground (F, 2026-11-06: sink them, real stairs, people going in and out; every entrance within ~120 m of (-1250, 580)); handed to the metro entrances thread (sunken places)
- [ ] One road layout per street chain (kerbs, asphalt, lanes as paint, bays from one cross-section) and junction templates (tram-median crossing, U-turn, driveway mouth, T), replacing the road_smooth repair passes; after #447 merges, own map thread (Opus)

## Road objects and collisions (F, 2026-11-04)

F: "a lot of objects on the roads make the arcade driving harder, and you can't tell what many of
them are for; check every object street by street (real object to draw, leave out, a wall that
matters on a bridge or estacade, better texture, the real object), and rework the collisions:
walls redirect, never stop, for buildings and other cars too". Research and plan:
`docs/design/road-objects.md`. Census tool `tools/road_objects.py` (3,553 solid objects within 3 m
of a lane's edge: fences 410 and parked cars 412 within 1 m, deck rails and structure walls on the
bridges and estacades, ~100 stairwell walls at 1.9 m, 64 canopies as solid 4 m blocks). Skill
`road-objects-sweep`, agent `road-auditor`.
Found: since Classic became the default controls (2026-11-04) the wall follow (point-to-steer only)
is gone, so a head-on hit stops the car dead again (road-objects.md 1.1).
- [x] Research, object audit, census, pipeline, collision targets, skill and agent (2026-11-04, docs + tool)
- [ ] 1 Collision rework v2: response by impact angle, wall follow for Classic, head-on kick, corner pivot, traffic shove (4.2-4.3) behind `--collide=v2` and a setting; RO3/RO4 cases. F: 97 % kept on a graze feels too arcade: presets (97 / 90 / 80 %), A/B from the middle, F picks on the phone
- [ ] 2 `check_lane_drive` contact log, `--street=`, sloppy driver, the 4.5 numbers (after #427)
- [ ] 3 First sweep: Marszałkowska, Świętokrzyska, Jerozolimskie (S1-S3 cloud, S4-S5 Mac batch)
- [ ] 4 Stairwell balustrades (1 m) and metro canopies city-wide; canopies on posts (rules B5, B6)
- [ ] 5 Soft colliders for fences, hedges, parked-car corners; A/B on Marszałkowska's median fences (bench)
- [ ] 6 Narrow streets: drive hull 0.3-0.5 m behind facades, parked cars every other one, no kerb jolt under 8 m
- [ ] 7 The override file `game/data/road_objects.json`, `--classify`, the baseline in `check_map_data.py`
- [ ] Census: apply `_by_road` to platforms (over-counted now); 48 lanes through buildings (gateways) to look at
- [x] Street-level photos in the cloud (2026-11-04): F allowed the hosts and made a Mapillary app (`MAPILLARY_TOKEN`); `tools/street_photos.py` finds the photos facing a point; added to the model-from-photos skill, object-modeler and road-auditor
- [x] `panoramax.openstreetmap.fr` allowed too (F, 2026-11-04)

## After the beta: driving extras and the city economy (F, 2026-11-03, plan only)

F asked for research on arcade driving games and on business and economy games, for a layer after the
beta: arrive broke, work, buy and run businesses (kebab stand, matcha bar, bistro, running club, a
corner-shop parody that loses money), rent then buy cars and homes, end in a flat in Złota 44. Plan:
`docs/design/city-economy.md`; designer summary: https://claude.ai/artifact/NR9RQ95srALR6rZ8GSF49h.
Not before GAMEPLAY_PLAN phases 0-3. Role briefs for skills: `docs/roles/` (F adds them in claude.ai).
- [ ] D1 driving extras: style tips on rides, traffic-light challenges, Sport-only drift, a 30-minute comfort playtest row
- [ ] E1 game-day clock, save v3, bunk/room/studio, home spawn, car rental; `check_economy.gd`
- [ ] E2 kebab stand, matcha bar, running club: tills, collection drives, managers, map icons
- [ ] E3 levels with sign swaps, street sets, bistro, padel, Ropucha 24/7, inspector and influencer events
- [ ] E4 the rival developer: bids and race takeovers
- [ ] E5 Złota 44 endgame, penthouse postgame

## Landmarks from photos: Chmielna 89, "Piramida" (F, 2026-11-03, later)

F: "PKO Piramida looks bad". Chmielna 89 (~80 m, 2021-22), the glass wedge on V-shaped steel legs by
the railway cutting next to Warta Tower; today an OSM extrusion. Later, photo way: a Mac gather
`refs/chmielna89/` plus F's four photos (project files), then the wedge, the zigzag frame on the
sloped face, the V legs, blue-grey glass. No bank name or logo (brands only as parodies).

## Bar-crawl taxi quests (F, 2026-11-04, plan only)

F: "quests about a bar crawl: you drive a company through famous bars in Warsaw for a limited amount of time."
Nothing is built (PAUSE; Opus for the quest design, Sonnet for the lines). Plan first in `docs/design/` (a
short `bar-crawl.md`), then build on the Podwózka rides (`rides.gd`, `ride_rules.gd`), the ZADANIA list
(`main.gd` `_quest_entries`, quest-lists) and `StopAssist`. Same pattern as the ride stories above.
- **The shape.** A group of 3-5 (a hen party, a stag night, students on a last-night-of-term, office
  colleagues after a deal; each a named passenger group with its own voice lines) books the car for the
  night. Three to five stops in a row, each a bar with a stop ring (9 m, `StopAssist`). The clock is the
  limit: a hard budget for the whole crawl (for example 25 game minutes, or one real 8-10 minutes) and a
  per-stop "stay" the group wants (they sit for a round, then pile back in, so you wait at the kerb with
  the engine running). Late means the mood bar drops, a bar closes ("ostatnie zamówienia"), the crawl ends
  early with a smaller tip; on time with a happy group is a bigger tip and a stamp. Mood: bumps, police
  and sudden braking lower it, drift-free driving and shortcuts raise it.
- **Routes from places already on the map** (all names are the existing parodies; real bars never
  named, per the parodies rule):
  1. *Nowogrodzka → Mazowiecka → Wilcza* (the "klasyczna"): KWARTA, KRAFTOWNIA IPA DO DNA, SCHRON PIWNY
     (`Storefronts.NOWOGRODZKA`), TYGRYS JAZZ or SZKIC NOCĄ (`MAZOWIECKA`), MUZA NA BIS or GORĄCZKA PIĄTKOWA
     (`WILCZA`). Dense, short hops: a skill route for tight streets and one-way grids.
  2. *Powiśle and the river* (the "nad wodą"): Q-BAR POD WIADUKTEM and WINO POD ŁUKIEM in the viaduct's bays,
     then the boulevard pavilions CUDAK, POMOSTEK, RZECZKA, ending on a bar barge (the `barka_*` sites).
     Scenic, longer drives; the ending is the water's edge with the stop ring on the quay.
  3. *Dom Partii and the Śródmieście clubs* (the "dla odważnych"): NEWTWICE, ZAMĘT, PRZEGRYWKI (the
     G2 neons), then a Mazowiecka club at 01:00-03:00 when the `club` curve is full.
  4. *Praga* (the "na drugą stronę", later): ŚWIAT PO PRASKU, POD KUFLEM ZA ROGIEM, KIJOWSKA DWÓJKA
     (`Storefronts.PRAGA`) with a bridge crossing (Trzy mosty, Poniatowskiego) in the middle of the clock.
  Ząbkowska stays out until the map grows north-east ("Grow the map north-east").
- **Rules.** Night only (the quest is offered 20:00-04:00, Fri/Sat busiest, like the `pub` curve). Open
  one at a time, not on the main line; the intro is a phone call or a flag at a kerb outside the first
  bar. Drop-off ends at a Syrena-friendly address (a hotel, a night bus stop). Group chatter uses the
  chatter budget (class `quest`); the passenger story format is the one from "Vitkac quests and ride
  stories". Bars are reached by street, not teleported; stop assist applies. Colour-safe rings apply.
- **Add-ons check** (when built): NPC conversation → Dialogue Manager is for authored branching scenes; a
  linear crawl with set lines per stop is plain tables, "not used, because the stops are linear".
- **Open to decide when built:** the clock (game vs real minutes), whether a crawl can be failed outright,
  whether the tip feeds the post-beta economy ("Od słoika do Złotej"), a "Barowa karta" stamp collection
  (all four routes) next to the notebook, and a phone feel test of the waiting at the kerb.

## Vitkac quests and ride stories (F, 2026-11-03)

F asked for two things; both are plan only, nothing is built (Sonnet for the lines, Opus for the quest design; docs/design/ gets the plan first).

- **Vitkac quests.** Quests that start or end at the Vitkac block on Bracka (the photo-built landmark, PR #385; CITY_INVENTORY #80). Ideas to design: a personal-shopper job (carry bags from the door to a car or hotel on time), a "queue for the drop" gag outside the doors, a Podwózka stop with its own result card. Hook into the ZADANIA list (`main.gd` `_quest_entries`, quest-lists) and `StopAssist`. The name on screen: Vitkac is a real place name and fine; any shop or label inside is a parody (warsaw-tone, never a real brand). Add-ons check at build time (NPC talk: Dialogue Manager or not).
- **Ride stories: what's left** (the stories themselves were built 2026-11-07: `data/taxi_stories.json`, `scripts/taxi_stories.gd`, 15 passengers, 3 lines + a two-answer question each, `--ride-story=ID --ride-answer=0|1`). Each story has its real destination (`to`, 2026-11-07); the big sites with no address door (Pałac Kultury, Dworzec Centralny, the Castle, the Stadium) end at the junction nearest them, not a modelled drop-off bay. Left: drop-off bays at those four; F's example couple from Wilanów to Vitkac (needs a pickup `from` too); a story told by two passengers (the couple bickering); recorded voices for the question line; more stories past 15 so the rotation is longer (the format is in the file's `_about`); the phone look of the question card while driving (stacked buttons beside the car).

## Loud cars at Browary (F, 2026-11-02)

City-life satire #1 built (`loud_cars.gd`, `check_loud_cars`): seven generic supercars at the Browary
gate square on Haberbuscha i Schielego, the `meet` crowd round them, up to three loud supercars in
traffic (the taxis' MultiMesh, no draw call), the `loud_rev` one-shot, `car_meet` / `loud_driver`
bubbles and KEBAB FM's "Sąsiedzi znów liczą obroty". Open:
- Phone check: the rev's level next to the horns and the radio (set by RMS, -11 dB), the meet's look.
- The meet's spot is the paved gate square read off the map's outlines; a photo check on the Mac.
- A continuous loud-engine loop on a loud car while it is near (now one rev per pass, 7-12 s apart),
  and exhaust flames on the overrun at night (the meet already has its headlights on).
- Done 2026-11-02: when the player's car stands still within 16 m of the meet for 2.5 s the crowd says a `car_meet` line tagged "stop" (4 lines, once per 45 s; `loud_cars.gd` `_stop_step`). Left: the cars are solid boxes you can drive into.

## City inventory (F, 2026-11-02)

docs/CITY_INVENTORY.md lists every characteristic place in the box, ranked, with its status; Part 3
is the order of the next threads. Found while building it:
- ~~**Monuments are almost missing.**~~ Fixed 2026-11-02 (monuments pass, part 1): `tools/bake_monuments.py`
  bakes the OSM cache (`docs/inventory/osm_candidates.json`) into `game/data/monuments.json`: 818 generic
  pieces (75 statues, 32 busts, 68 steles, 66 stones, 26 sculptures, 9 talking benches, a cross, two
  obelisks, Ogród Saski's 19 allegories at their real spots instead of 16 random ones) and 520 sandstone
  wall plaques with candles (Tchorek's Uprising plaques and the rest), built in park_details' per-cell
  meshes (+3 draw calls on the bench route). Checks `monuments` and `monumentmesh`.
- ~~**Monuments pass, part 2:** photo builds of Nike, Słowacki, Starzyński, Mały Powstaniec, Kiliński, the Eastern
  memorial and Umschlagplatz~~ Done 2026-11-02 from the Mac's photo reports (docs/landmarks/photo-reports/):
  sites `nike`, `slowacki`, `starzynski`, `maly_powstaniec`, `kilinski`, `umschlagplatz`, `pomnik_wschod` in
  landmarks.gd (120-1064 tris each, no draw call of their own), all in `bake_monuments.SKIP` (808 generic pieces
  left). Low ones get their own heli height in check_landmarks (LOW_MONUMENTS). Open: F's look on the Mac
  (QUESTIONS); Nike's facing is the photos' best guess (north-east); the reliefs (Umschlagplatz's broken trees,
  the names inside, the sleepers' place names) are plain fields, not lettering.
- **Monuments pass, part 3 (open):** rows 113-116 and 142. Plac Piłsudskiego's (Piłsudski, Smolensk, Kaczyński) was
  done 2026-11-02 (sites `smolensk`, `pilsudski`, `kaczynski`, `plac_maszty`, the paving's chequer in ground.gdshader; spec
  `plac_pilsudskiego.md`; the chequer softened 2026-11-03 after the playtest read it as a chess board, phone look check open).
- **Plaques without a wall:** 49 OSM plaques have no drawn wall within 12 m (free-standing ones, courtyards)
  and are left out; a post-mounted plaque piece would place them. A plaque's wall is the LoD2 footprint, so
  a deep shop recess can leave it on a pier rather than the door's wall (fine so far in shots).
- **Rule:** a tier S or A model starts from photos (F's or `refs/` on the Mac). About 50 outline builds wait
  for their Mac photo check (QUESTIONS); their photo re-pass is Part 3 item 9.
- 455 named OSM outlines (tier C: tenements, offices, embassies) are plain blocks; street passes take them
  street by street from Part 2. Done: Nowogrodzka's bar strip, pass 1 (2026-11-03, section below).

## Site analytics (F, 2026-11-02)

- After the next `wrangler deploy`: F checks Cloudflare -> Websites -> aroundwarsaw.app -> Analytics & Logs -> Traffic shows visits. If the Worker deploy fails on the Analytics Engine binding (needs it enabled once in the dashboard: Workers & Pages -> Analytics Engine), enable it and redeploy.
- The landing's store buttons do not exist yet: when the apps are listed, set `IOS_URL`/`ANDROID_URL` in site/wrangler.jsonc and link the buttons to `/go/ios` and `/go/android`.

## Beta radio (F, 2026-11-02)

- PÓŁNOC FM is out of the beta lineup, but the tape, the cassettes and eggs still unlock "a PÓŁNOC FM track" the player can't tune to (QUESTIONS, default: leave it).
- KEBAB FM and MORDOR FM still play one synth loop each until F's songs arrive (docs/MUSIC.md "The beta radio"); remove the loops from radio.json then.
## Rondo Dmowskiego and the metro entrances (F, 2026-11-02)

F sent two aerials, a night aerial and the city's traffic plan of Rondo Dmowskiego and asked for the
roundabout and the metro entrances round it. Done 2026-11-02 (cloud thread, site `rondo`, spec
`docs/landmarks/specs/rondo-dmowskiego.md`):
- **The island**: grey granite paving in concentric bands over the four mapped lawns between the tram
  cross, a crescent flower bed per quarter (red or purple in a yellow rim) and a shrub bed in an
  orange rim; the laser scan's trees on it removed (`tree_free`); the PRASA kiosk and two planters the
  street-details bake had put on the island moved off (`DISCS`).
- **The underpass stairs**: Metro Centrum's blue polycarbonate "tubes" over all twelve walled
  stairwells (blue arches, closed deep end, red M post at the mouth glowing at night), and the same
  `tube` form for the three Centrum `subway_entrance` stairs by the Patelnia (`Props`, storefronts).
- **The Patelnia mural**: an original colourful pattern on the north face of its 1.9 m south wall.
- **Street furniture**: a PRASA kiosk by the Patelnia stairs, an ice-cream cart in the south-west and
  a tram shelter on the east Jerozolimskie island (`bake_street_details.py` RONDO; new kind `shelter`).
- **Drive test**: the ring's four sides and Marszałkowska by the south-east stairs (playtest suspect
  PT-4) are SPOTS in `check_drive.gd`.
Left:
- Mac look check (QUESTIONS): bed colours and sizes against the orthophoto, the tubes' height and
  blue, whether every stairwell really has a tube (some may be open stairs), the mural's place.
- The underpass itself (shops, the passage to the metro) is not modelled: the camera never sees it.
- The crossings the city added in 2022 at the four arms are the road bake's; a zebra check against
  the plan (Widok, Poznańska, Nowogrodzka, Parkingowa) belongs with "Roads against real Warsaw".
- The occlusion ghost cuts the island's paving and beds on the camera's side when a tower hides the car
  (they are in the building material, like every landmark): the lawn shows through in the ghost's
  circle. A ground-level exemption in `building.gdshader` (by UV2.y, the height above ground) would
  fix it for every site's ground dressing (Dom Partii's court, Plac Defilad).
- ~~The stairwell walls are the map's 1.9 m walls~~: the Patelnia's and the Rotunda stair's are now
  retaining walls with railings (site `sunken`, 2026-11-05); the wells under the tubes keep theirs.
## Map checks in GitHub CI (2026-11-02)

- Done: the `map` job in `.github/workflows/verify.yml`. The GUGiK-derived files (lod2.bin, lod2.json,
  terrain.json) are a release asset, the map pack (`tools/map_pack.py make|fetch|check`,
  `tools/map_pack.json` pins its hash); CI fetches it, builds the split and the prebuilt sectors
  (`tools/setup_map.sh` with lavapipe under Xvfb) and runs the map, road, street, drape, drive,
  landmark and water checks and the plain, prebuilt and ram runs. `tools/setup_map.sh` fetches the
  pack itself when the files are missing, so cloud threads get the real map too. Main pushes no
  longer cancel each other (one concurrency group per commit). `spec` joined the quick job.
- Found and fixed on the way (both red on main, unseen): `legia.md` missed six spec sections
  (check_spec), and #258's cycle-path snap folded 35 short links onto one point, one of them under a
  zebra at (-92, 1720) (check_streets S2); `tools/cycleways.py` now never snaps a way's two ends
  together, and centrum.json's cycle paths are re-tidied from the pre-#258 input
  (street_details.json's source hash follows). check_landmarks failed the four bar barges (rays
  from the water side, the heli at 6 m over 6.7 m decks): barges now need 5 of 12 rays and the
  heli flies at 4 m. Before CI these stayed unseen since #205/#248/#258. After merging today's main:
  archikatedra.md and ostrogski.md had no parts table, a Plac Zbawiciela café set stood off its
  shopfront (check_stops K5; `square_terraces` now uses the same CAFE_FRONT rule, 45 sets), Dworzec
  Wodny needs the barges' bank-side rays, and the heli aims at Zamek Ostrogskich's tallest cell (its
  box's middle is the courtyard). 2026-11-02, verify --quick in the cloud with the pack (still
  unseen in CI while the map job skips): check_landmarks failed K7's splash pool (`bulwary_basen`,
  all under 2 m: a heli has nothing to hit), now in its FLY_OVER list (flown over, never inside);
  park_details.json's source stamp was stale since map review C's re-bakes (items unchanged),
  re-stamped and `parkdetails` joined the quick job; street_details.json's stamp went stale the
  same way with K6's planted trees (items unchanged), re-stamped, and `streetdetails` and `stops`
  moved from the skipped map job to the quick job (all three are Python on the committed map); the prebuilt bake failed with no display, so
  `tools/verify.sh` now runs it under xvfb-run, or skips the prebuilt steps as a WARN without one.
- Open: F publishes release `map-pack-1` (until then the map job skips with a warning). A required
  check: GitHub Settings → Rules → a ruleset on main requiring `quick` and `map`, so a PR can't merge
  on red or before its run ends (#261 did). After a full bake that changes lod2 or terrain:
  `python3 -I tools/map_pack.py make`, publish, commit `tools/map_pack.json`.
## Rondo Daszyńskiego office crowd (F, 2026-11-02)

Built (`crowds.gd` OFFICE, `office_level`, `_office`; dialogue group `office`, 65 lines tagged
morning, lunch, evening, rain; check_crowds step 10): the office crowd on weekday rush hours.
Crossing waves (F, 2026-11-07, done): all seven metro entrances have a standing crowd (five more
sites), up to 104 walkers (was 56), and each walker stops at the kerb of a zebra whose walk phase is
off (60 s cycle, 24 s walk, three offset phases, a queue up to 2.4 m deep), so the flow crosses in
waves. The phases are a guess and not the cars' signals (those controllers exist only with the
traffic). Open:
- Phone look check and a bench on the rondo at 08:30 (QUESTIONS); the cloud measured only the
  crowd's CPU tick (check_crowds), no phone bench.
- Tie the zebra phases to the real signal controllers (lane_graph.gd) so cars stop when the wave
  crosses.
- Waiting walkers keep their walking pose in place (one shared mesh).
- Rondo Daszyńskiego's metro entrance models are checked only by F's red-wing photos; the other
  stations' entrances (audit and missing designs) and real tram stops across the map are in their own threads (F, 2026-11-07).
- Props: lanyards, laptop bags and coffee cups are only in the lines; a figure with a bag or cup
  needs a variant of the shared person mesh (a mesh/draw-call decision, not done).
- The walkers' routes end at a kerb and restart elsewhere (the dawn crowd's behaviour), so a pop
  is possible in view; a looping or two-way route would hide it.
- The Spire's and the HUB's foyers: no footway links the rondo's exits to the Spire's foyer in the
  map data, so no route ends there (the HUB's does). A pass over the footways round Plac
  Europejski would add it.
- Office life elsewhere: Rondo ONZ and Rondo 1, Plac Europejski's lunch queues.
## Krajobraz places (F, 2026-11-02)

F's ask: research the RS Architektura Krajobrazu projects inside the map (krajobraz.com.pl
"wybrane": Bracka, Chmielna, Muzeum Historii Polski, Varso Place and the rest) with news and
photos as well as the studio's pages, and bring each place up to how it looks now. Research,
sources, the game's state and the build plan per place: docs/design/krajobraz-places.md. One
fresh thread per item; ul. Złota and Zgoda stay with the Skwer Linearny thread.
- [x] K1 ul. Bracka (Al. Jerozolimskie to Krucza, the 2024 woonerf): 22 young trees planted in
  its mapped beds (`tools/planted_trees.py`, 33 young trees in all, as the article counts).
  Open for the Mac (QUESTIONS): the paving's colour, the beds' planting, a matched street photo.
- [x] K2 ul. Chmielna, Nowy Świat to Pasaż Wiecha (2024): 65 young trees in its mapped tree pits
  (85 in all with the 20 scanned; elms on the narrow stretches, planes on the two squares), its
  pedestrian areas re-tagged as grey granite, Ali's memorial stone and a SKWER BROWNE'A plate at
  Pasaż Wiecha (first_scene.gd). The fountain by Kino Atlantic was already in the OSM data.
  Open for the Mac (QUESTIONS): orthophoto check of the trees, the granite's tone, the stone's spot.
- [x] K2b Chmielna's furniture: 60 benches added to the 4 OSM has, 64 in the street's band, one
  every ~7.5 m on alternate sides, facing the street's middle (`planted_trees.py furnish`; the game
  has one bench model, so the urban chairs and long benches are all benches). The Atlantic
  fountain already had its stone rim (the shore edge round every fountain, 0.45 m). Open for the
  Mac (QUESTIONS): where the real benches stand; a long-bench model if wanted.
- [x] K3 Varso Place (spec docs/landmarks/specs/varso_place.md): the sky garden on the tower's
  205 m roof (16 hawthorns, dwarf pines, benches, glass balustrade), planted terraces on Varso 1's
  71 m and Varso 2's 80 and 72 m roofs (site `varso_place`), the VERSO PLACE name stone and the
  60 t erratic on the corner plaza by Al. Jana Pawła II, 6 young trees in Chmielna's bare beds
  (`planted_trees.py` PLACE `varso`). Open for the Mac (QUESTIONS): the photo check of every
  part; not built: the lobby's 12 olive trees, Varso 1's 7th-floor terrace, the raised crossing.
- [x] K4 Zielona Świętokrzyska (2018): built, see docs/design/krajobraz-places.md (open for the Mac: a street photo
  compare of the planters' places; trees stay as scanned).
- [x] K5 Rondo Daszyńskiego plazas (2026-11-02): 121 young trees (birch, linden, hornbeam, a few
  pines, rowan), 51 shrub beds and 11 benches in the open ground round Skyliner, Generation Park
  and Mennica Legacy Tower (`tools/plaza_gardens.py`, spec docs/design/rondo-plazas.md). Open for
  the Mac (QUESTIONS): the groves against photos, the wooden benches on terraces (flat ground here).
- [x] K6 (2026-11-02, `planted_trees.py` kind `garden`): 5 candelabra planes (broad heads on short
  trunks) in Fabryka Norblina's court and 12 lindens, birches and maples in Browary's Central Garden
  yard, at spots clear of walls, roads, lamps and the scanned trees. Left (Mac photo check, QUESTIONS):
  the real positions (the Leżakownia's vaults, the candelabras' places), the climbers on the walls
  and the garden terraces upstairs (not modelled), and the tree count in the Browary yard.
  **Rebuilt 2026-11-02 from the Mac's photo reports** (docs/landmarks/photo-reports/norblin.md,
  browary.md, GUGiK ortho): the first pass had put Norblin (model and planes) on the wrong block,
  OSM's "Modsen" north of Łucka. Now the site stands on "Plater" and "Galwan", their two courts are
  carved open (`planted_trees.py` COURTS), 4 candelabra planes stand in the court north of the glass
  street with young trees on Żelazna, along the glass street and in the west court; green sedum roofs
  with plant rooms and the terraces upstairs; the guessed chimney is gone. Browary's Central Garden
  has 22 crowns (the scan's 5 and 17 young ones) round an S-shaped gravel path with two café
  clearings (white tables, dark-blue parasols), 4 trees by Willa Schielego, sedum roofs on the office
  blocks and a roof garden on the north slab; the 12 trees misplaced on the yard west of the lawn are
  gone. Left: climbers (no photo), the glass street's roof (the map's 2018 LoD2 halls stand where the
  ortho shows the street), the AK memorial boulder (not located), the Grzybowska plaza's granite grid.
- [x] K7 Bulwary Wiślane stages 1-2 (2026-11-02, site `bulwary_basen`, spec bulwary_basen.md): the
  splash pool and 3 fish (the 6 pavilions are the boulevard dressing, PR #310). Left: the amphitheatre, trampolines and the "living river"
  garden (not in OSM, need the orthophoto), and the Mac look check (QUESTIONS).
- [x] K8 Arkadia's playground (Al. Jana Pawła II 82, 2018), 2026-11-02: one new park piece
  `ropecourse` (ribbon rope course, three flush trampolines, timber bench-sculpture, three lamps on
  a cable; ~520 tris, solid) in the green strip west of Arkadka (new park "arkadia" in
  `bake_park_details.py`, 207 park items). Left: the real layout (slide, climbing frame, swings,
  the water-play corner) is not modelled, only the rope course's look; position is a guess at the
  strip, check against the orthophoto on the Mac (QUESTIONS).
- [x] K9 Stadion Narodowy's grounds: 80 young trees (lime and plane rows down both sides of the
  four entrance avenues, groups of pollarded willows on the lawns between them), `planted_trees.py`
  place `stadion`; shrub belts and the avenues' paving colour left for the Mac look check.
- [ ] K10 Muzeum Historii Polski (Cytadela) lies ~0.7 km north of the map's north edge: parked
  in QUESTIONS (grow the map or a skyline stand-in).

## The estate, the halls and Jana Pawła II (F, 2026-11-01)

F asked for Osiedle Za Żelazną Bramą, Hala Mirowska and every building along Aleja Jana Pawła II to
be modelled, (Norblin, Browary, Koszyki and Elektrownia are the next section). Done 2026-11-01
(cloud thread, spec `docs/landmarks/specs/zelazna.md`):
- **Osiedle Za Żelazną Bramą**: site `zelazna`, eleven OpenStreetMap blocks (five 43.9 m slabs and
  the 60.4 m high block between Żelazna and Sienna, five 37-41 m slabs with saw-toothed long faces
  on Sienna's east end), the estate skin S_ESTATE (3 m panel bays, ribbon windows, coloured loggia
  stacks), blank end walls with a stair slot, entrances with canopies, lift houses, a card. 855 tris.
- **Hala Mirowska**: it was already a model; added ten market stalls with awnings on the square
  side of the east front.
  Photo pass 2026-11-07 added the glazed east gallery. Left: the lattice-glazed gable arch, the HALA MIROWSKA letters (a neon atlas word), Hala Gwardii.
- **Aleja Jana Pawła II**: every plain LoD2 building within 42 m of the boulevard takes a mid-century
  plaster by its position (`map_builder._boulevard_dress`, both city paths). Towers and the
  landmarks along it keep their own models.
Left:
- Mac photo checks, parked in QUESTIONS: the estate's real panel colours and loggia stacks (stack
  or band), the slabs' heights against the photos, the high block's shape (its outline is a wedge),
  the low pavilions between the slabs; the stalls' place on Plac Mirowski.
- The boulevard's buildings are a palette, not models: next pass is street by street, the real
  facade of each block along Jana Pawła II (Kaskada, the 1950s blocks near Rondo Daszyńskiego, the
  Żelazna Brama corner) from the orthophoto and photos.
## Roadworks at the map's edges (F, 2026-11-02)
F: "add some roadworks at the ends of the city where now the map ends". **Built** (`scripts/edge_roadworks.gd`,
both city paths): every road that leaves the map is closed 12 m inside the outline: 237 closures from 393 road ends
(42 big, 60 medium, the rest service lanes), each a line of red-and-white barriers with blinking amber lamps (a
halo each at night), a B-1 no-entry disc and cones; on streets a yellow ROBOTY DROGOWE board and OBJAZD →; on
avenues the A-14 triangle 18 m ahead, a cone taper, and behind the barriers a dug trench, sand, an orange pipe, a
yellow excavator with a beacon, a site cabin or a TOJ TOJ (our parody of the blue toilet) and a 2 m tarp fence that
hides the road running on past the edge. Solid: one box collider per barrier line, in front of the edge wall. The
traffic stops at the barriers (`lane_graph.gd` `e_shut` / `e_open`: never through them, no starts behind them, a
closed road only when nothing else is open; a waiting car leaves once out of sight; a rival or the autopilot takes
the off-map link from the barriers). Check `check_edge_roadworks` (verify `roadworks`, CI too); `check_drive` leaves
the closed stretches out and finds exactly what main finds. Meshes on a worker thread (0.34 M triangles in 39
pieces of 512 m, ~1.5 s of GDScript on the cloud CPU, added within a 3 ms budget a frame). Probe at Jerozolimskie's
west end: 90 → 93 draw calls (main 34 → 36, shadow 17 → 18), 0.39 → 0.41 M triangles.
- [ ] Mac look check (QUESTIONS): the barriers' scale at phone zoom, the boards' text, the excavator and the fence
      against real Warsaw roadworks; whether the big closures feel like too many of the same (55 kits, 3 tarps,
      cabin or TOJ TOJ by a coin toss).
- [ ] Phone: drive into a closure (the hit, the haptics, POMOC DROGOWA if wedged); the meshes' arrival a second or
      so after the start (the player starts far from any edge).
- [ ] A road meeting the edge at a shallow slant gets a barrier line across the road, not along the edge; a few
      long ones look odd from above. 34 roads that run along the edge are closed 6.5 m in, just before the wall,
      barriers and a fence only.
- [ ] 14 service lanes that leave the map right beside a street are left to the edge wall (their barriers would
      stand in the street's lanes); 4 short stubs in the edge band lead to no closure.
- [ ] Traffic queues at a closure while it is on screen (a closed road is picked only when nothing else is open);
      real drivers would turn round. A U-turn at the barriers would need a turning lane in the graph.
- [ ] `--no-edge-roadworks` removes the meshes and colliders but the traffic still stops at the lines.
- ~~Invisible on the phone~~ (F, 2026-11-05): bake_city never yields to the worker thread, so `map/index.res` held the
  238 colliders with no meshes: phones and TestFlight had invisible barriers. The streamer now rebuilds them on opening
  the prebuilt city (`EdgeRoadworks.rebuild`). New check `check_edge_prebuilt` (verify `roadworks-prebuilt`): the meshes,
  and the real car rammed at 42 m/s into all 238: none through, none off the map.
- [ ] That ram: 7 narrow closures let a car thrown aside by a kerb past the barrier's end, and at Andersa
  (-1961, -2763) it rides a level 7.5 m above the barriers; all stop at the edge wall, 7 m on. Widen the lines to the
  kerbs or walls beside them?
- [ ] `check_streaming` fails on the Mac (2026-11-05, on 550c3f03 plus this fix): the pixel pairs show two different
  places (the two runs no longer land on the same spot), and identity finds 38 building tiles and 402 collider faces
  differing between the whole city and the sectors. Not from this fix (no mesh touched); needs its own look.
- [ ] Phone: the meshes now cost the worker thread and ~30 MB at the start on the iPhone 11; bench it there.
- ~~English boards~~ (satire doc #10, 2026-11-02): in English the boards read ROAD WORKS / DETOUR → (the
  British words, as wide as the Polish, so the board keeps its size); a language change in Settings builds the
  roadworks again (`EdgeRoadworks.rebuild`, colliders at once, meshes over the next frames). Check W5.

## Playtest bugs (Autopilot, 2026-11-02)

The free-play bug log is `docs/PLAYTEST.md` "The bug log" (PT-n ids, severity, status); fix
threads take its confirmed rows one by one. After two runs: PT-1 fixed 2026-11-02 (a dead stop on
Marszałkowska at Centrum's tram stop; every new PT spot joins `game/tools/check_stuck_spots.gd`), PT-2 (NE of Plac Defilad) and PT-5 (side
streets west of Marszałkowska) not reproduced by ~680 swept road lines, now guarded in the check (2026-11-02), PT-4 (Rondo Dmowskiego) not reproduced after the rebuild, PT-3 closed (low ground, not a bug). Run 3 (the Śródmieście grid): PT-6 the guide's bubble
covers the minimap and +/- buttons (not reproduced on main: check_hud sweep clean; needs the frame, 2026-11-02). Design question for the driving lane: a hit from 108 km/h
stops the car dead in 0.2-0.4 s with no slide; is that the arcade feel we want, or should it
bounce or slide off a wall? Runs 4-8 (Krucza, Mokotowska,
Świętokrzyska, Królewska): no wall bugs on the streets themselves (the on-road stops were bumps
into traffic cars); PT-7 fixed 2026-11-02 (a notch and a slit in the block's front at the Chmielna square; low collider walls
across slits and notches city-wide), PT-8 (a 6 km/h crawl during Pani Halina's prompt: she was put in front of the car,
fixed 2026-11-02); PT-9 HUD overlaps confirmed.
- PT-11 follow-up (2026-11-02): the first race's start hold and GAZ! nudges are in (check_first10);
  watch on the next P2 run that the nudge reads at phone size and that a red light mid-race (under
  5 s) never triggers the stall line. The heli/tape/garage beats pass headless only; P2 by hand
  (flying to the BUW roof, driving to Mirek) waits for an Autopilot run on the Mac.
- Found with PT-7: the camera's see-through ghost hides the wall the car is about to hit when it
  drives towards the camera (south on the default view): a player pushing into it sees no wall.
  A design question for the visuals lane (a ground outline or a faint base under the ghost?).
- Found with PT-1: a free spot (`main.gd _free_car_spot`, a tow) only tests the box against the
  wall faces, so a spot fully inside a solid outline (a building, now a 0.9 m platform) counts as
  free. Not seen in play; reject spots inside platforms and footprints if it shows up.
- Found with PT-1: head on into a solid platform's end the car stops like at any wall and is
  turned out after 1.5 s (Centrum's north tip faces the left lane of Marszałkowska).
PT-9 (bubbles) fixed 2026-11-02: the tail of a bubble kept clear of the HUD ended in the air (a 22 pt stub) and pointed down even when its speaker was above; it now runs to the speaker, and a half-typed line keeps the wrapping of the whole line. The radio ticker's cut-off at the left edge (run 10, 1266x585) fixed 2026-11-02: it slid in from off screen; now it eases a few points inside the safe area and fades (`check_hud` checks every step of the slide). Still open: the KEBAB status label over BRAKE and the sound button did not reproduce in `check_hud` at 6 sizes nor in run 10 (`pt` is fixed when the HUD is built and not updated by a later window resize: a suspect, not shown); needs a frame with the window size.
PT-13 (the order card went away without a tap) fixed 2026-11-02: it was the order's designed start after 9 s, unexplained; the card's GO now counts those seconds down.
PT-10 (the order tracker over bubbles) fixed 2026-11-02: the target pointer draws under the speech bubbles and the panels and goes faint under the banner or a bubble; the edge arrow slides along the edge clear of bubbles and panels, and its distance sits past the arrow by the label's own size (`check_hud`: draw order, 72 directions, a bubble in the arrow's spot). Phone look open.
Run 11 (P2, the flying half, 2026-11-02) timed out after the heli beat (the Mac sandbox ended, no frames): PT-14 (the helicopter stuck at ground height after landing), PT-15 (a taxi card over the race flash-back) and PT-16 (one order driven six times) are suspects. Design question for the guide: every beat waits while an order is on, so a new player who keeps delivering meets the race at 203 s instead of ~75 s; should the race or a later beat cut in after the first delivery?
Run 12 (2026-11-03): PT-14 closed (the helicopter climbs after landing; run 11's harness mixed its keys); PT-17 suspect, a car circling on Plac Dąbrowskiego until the tow. The rescue beat waited 83 s past its window while a ride and a chase were on (the same hold as the race above).
Runs 13-14 (2026-11-03): Powiśle met at 283 s; PT-17 not seen on one pass. Every Autopilot run on F's Mac is killed (-9) at about 6 minutes of play, so beats after that (the tape pickup, the garage at 570 s, the end card) can't be playtested with it yet: find the cause (memory with the editor, the game and the agent service on one Mac?) before the next long row.
PT-15, PT-16, PT-17 fixed 2026-11-03 (PLAYTEST.md): no ride request over Halina's call or a rival's prompt (and none of those over a request card); the delivered / order-dropped card goes by itself after 12 s or 25 m (it waited for OK for ever, the likely reason one order looked driven six times and the race waited until 203 s); Jasna's 24 m shallow bay by Plac Dąbrowskiego bridged (bays up to 30 x 2.5 m city-wide). Verify all three on the next P2 run.
PT-18 fixed 2026-11-03 (P11 run 20261103-152948, Solec under the Trasa): on the ramp up to the Trasa the mapped guard rail comes in pieces 0.9 m apart and the car's corner caught a piece's end (pinned at 1307, 959); under the ramp its pier stood 2 m off Solec's west kerb. Guard-rail gaps under 1.5 m on a deck now get a shallow collider V behind the rail line, so the bus cuts stay clear (map_builder GUARD_JOIN, GUARD_POCKET; 122 in the sectors round Solec) and the bake keeps piers 2 m further from a main road wherever their slide finds room (bake_structures PIER_ROADSIDE; 44 of 359 piers moved 1-2 m in centrum.json, the rest as baked). Six spots in `check_stuck_spots` (five fail on the old map). PLAYTEST.md's PT-18 row (PR #420) should read fixed. Still open from the same row: the car hidden by the deck (GAMEPLAY_PLAN 3.5, x-ray).
The guide's beats behind jobs, built 2026-11-03 (default, QUESTIONS): while a beat that waits for a free moment (race, trap, rescue, tape, Powiśle, garage) is due or within 45 s (`first10.gd` `due`, HOLD_AHEAD), the guide holds what comes by itself: Podwózka requests (rides.gd `guide_hold`, the next one at least 30 s after the hold lets go) and the "Na czasie" offers (trend_job.gd). A job already under way runs on and the PODWÓZKA button still asks for a ride. `check_first10` "rider": a player who takes every request meets every beat in its window (without the hold the tape and Powiśle came at 546 s). Left: a player who chains kebab orders at the stand still holds the beats (the stand is the player's own choice; not held), and a ride taken just over 45 s before a beat still pushes it back up to ~2.5 min (inside the windows in the toy); the next P2 run should show both.

## Hotel Warszawa and Cedet (city inventory item 4, 2026-11-02)
Built from photos gathered on the Mac (`refs/hotel_warszawa/`, `refs/cedet/`) and the LoD2 heights, specs
`hotel_warszawa.md` and `cedet.md`. Found and left:
- Hotel: the shaft's corner pilasters are single (the photos show doubled, stepped strips); the U behind is
  one 25 m height (LoD2 has lower bits); the glazed pavilion and rounded corner at the block's south-east
  foot belong to the next outline south (not built); the lift head and masts are placed from the report.
- Cedet: the cornice's fine vertical ribbing and the 3-pane / 2-sash split of each bay are the shader's
  generic 1.5 m mullions; the north wing has no crown pavilion of its own; the glazed lantern and link roof
  plant are not modelled; the ground-floor tenants' fascias (parodies) and the red neon at the east corner
  are not there.
- Cedet after F's look check (2026-11-03): the east end's radius is unclear (4 m kept; check against a
  straight-on photo of the Bracka corner); the wings' tips stand ~1 m over LoD2's 31.5 m so the sweep reads
  from the street (lower them if a photo shows a flatter curve); the plant screen at the back of the
  pavilion is LoD2's 35 m box, its louvres and colour are guesses.

## Most Poniatowskiego (F, 2026-11-02)
Built from photos gathered on the Mac (`refs/poniatowski/`, report `docs/landmarks/photo-reports/poniatowski.md`),
spec `poniatowski.md`: the four tower groups (arcaded pavilions, 20 m shafts, south stair turrets) and the river
spans (granite piers, steel arch ribs, red fascia, black railing, pier pedestals). Found and left:
- 2026-11-03 (F's answer, the Mac's check of photos 22 and 1): 8 spans, 7 piers (`PN_PIERS`): the west-bank pier at
  s 64 (estimate s ~58 ±8, moved to clear the promenade's footway and cycle path), the 7th at s 467. Three of the
  seven (s 335.7, 411.6, 467) are floodplain estimates (±15 m) until a photo from the Wał Miedzeszyński side.
- 2026-11-03 (F: "strengthen the shafts and pavilion arcades"): `_pt_group` adds the shafts' corner piers (0.25 m
  proud, full height), string courses at 6.6 and 10.9 m, a corbel table under the cornice, a bigger arched window
  and a pair over it, taller belfry slits and crown; the arcade bays between piers 0.35 m proud with keystones, an
  impost band and a plinth. Colliders unchanged (everything stays inside them). Mesh 2556 -> 4574 triangles over the
  four groups (check_mesh_quality budget 2700 -> 4800), +0 draw calls. Mac/phone look open.
- Not modelled: the small arcade beyond each shaft, the merlon scrolls and the insets over the arches, the
  bases' brick panels and balconies, the real tram catenary masts.
- 2026-11-03: the Powiśle viaduct's arcade (`map_builder._build_powisle`: pilasters every ~19 m, segmental arches
  with archivolts, ribbed spandrels and a cornice, big arches over Kruczkowskiego, Solec and Wybrzeże, the pier
  buildings kept as the big piers) and the north groups' switchback stairs with lanterns (`landmarks._pt_ramp`;
  lanterns on the south turrets too) are built. The pier layout is measured clear of every street and footway
  under the edges; the real arches' count and span, the spandrel ribs and whether the arches are open or
  filled in are not in the report (the photos stay on the Mac): QUESTIONS. Along Al. 3 Maja (s 296-430) the
  south arcade stands 3-5 m back under the deck, because the street runs under the deck's edge there.
- 2026-11-03 (F's answer): the spandrel walls are gone. Each row is now 31 spans (the north row got piers at
  s -19.1 and 404.5, measured clear): 4 beam spans by the west abutment on a 1.9 m steel girder, 27 open
  reinforced-concrete arch ribs (1.6 m wide, 0.9 m deep at the crown to 1.8 m at the springings) with square
  struts every ~3.2 m up to a 1.1 m steel edge girder with stiffeners (`_pv_span`). The 9 bays per row between
  Kruczkowskiego's and Solec's pier buildings are closed by rendered walls 0.9 m behind the ribs with an arched
  door and windows (solid; `_pv_infill`); five of them are parody bars (`PV_BARS`; storefronts.gd `VIADUKT`
  neon, crowds.gd `VIADUKT` people, warm glass that glows at night, café tables with parasols). Open: which
  spans and bays are really which, and the bars' real doors (QUESTIONS); a phone bench of the struts (each
  strut is a box in the city mesh: +0 draw calls, ~+25k vertices).
- The approaches between the towers have been lit since map round 2 (D7, `bake_lights` approach lamps); the
  night shots of 2026-11-03 show both abutments lit.

## Bracka and Plac Trzech Krzyży: Vitkac, Jabłkowski's, the Sheraton (CITY_INVENTORY 80-82, 2026-11-03)
- The BGK building (CITY_INVENTORY 146, F asked 2026-11-03) built too (site `bgk`). Left: its three
  light wells, the stepped south side's real heights, the balconettes; the block behind it on
  Mysia, Mysia 2 (OSM landmark 'Polska Grupa Energetyczna'), is still plain.
- Built from the Mac photo reports (sites `vitkac`, `jablkowscy`, `sheraton`). Left: the Mac look
  check (QUESTIONS); Jabłkowski's stained-glass windows lit at night through the front; the Sheraton's
  glazed restaurant pavilion with white umbrellas on the forecourt (its spot needs the photo).
- Found and fixed: a landmark model's car walls skipped the slit and notch bridging (map_builder
  `_bridge_pockets` only saw kept buildings), so the PT-7 slit by Jabłkowski's corner came back;
  a site can now hand its outline over (`landmarks.gd` `pocket_rings`, opt-in, these three use it).
  Older models (Dom pod Orłami, POLIN, the Bankowy palaces...) don't: worth a sweep with
  `check_stuck_spots` along their fronts.

## Plac Krasińskich: the Uprising Monument and the palace (CITY_INVENTORY 22 and 79, 2026-11-02)
Built from photos gathered on the Mac (`refs/pomnik_powstania/`, `refs/krasinski/`) and LoD2, specs
`pomnik_powstania.md` and `krasinski.md` (sites `pomnik_powstania` 1514 tris, `krasinski` 1508). Found and left:
- Sąd Najwyższy's colonnade fixed 2026-11-02 (site `sad_najwyzszy`, spec `sad_najwyzszy.md`): the 54 OSM columns and their beams are green and ribbed, with the lettering band and rosette capitals. Left: the court's main block (LoD2) keeps its map look; its fronts, the roof garden, the caryatids and the night glass need a Mac photo gather (QUESTIONS).
- The monument's heights and the groups' facing are estimates from photos (no published height, no aerial); the bronze is simplified to blocky figures. The plaza's dark granite bands, the blue-green light strips, the floor plaque, the juniper beds and the brick wall with the Kotwica on the Długa side are not drawn; the 1 August candles are not there.
- The palace's pediment relief is a flat recessed field, the cartouche over the central window and the roof statues of the garden front are not modelled; the dormer and chimney counts are rough (the report says so). The garden's round parterre and the pond's sculpture are the park's (the fountain is already there).
- F's look check on the Mac or the phone: the slabs' lean, the fighters' size, the roof's green.

## Poczta Główna and PAST-a (CITY_INVENTORY 76 and 78, 2026-11-03)
Built from the Mac photo reports (`refs/poczta/`, `refs/pasta/`) and LoD2, specs `poczta.md` and
`pasta.md` (sites `poczta` 588 tris, `pasta` 476). Found and left:
- Poczta: the colonnade's place on the Świętokrzyska face (on the hall's axis) and the columns
  standing 2 m out from LoD2's wall are estimates (a real colonnade may be recessed into the front);
  LoD2 already has a raised lump at the corner, the drum and dome are sunk round it. The wall reads
  grey-pink in the cloud's renderer: check the salmon on the phone. The back (the street to the south)
  and the courtyard are LoD2's as they are.
- PAST-a: OSM's outline (21 x 26 m with a notch at the south-west) is taken as the tower; the ortho
  puts its roof ~8 m further west. The lower wings north and south are LoD2's, not the report's steep
  roofs and tall chimneys of 1910 (they are gone today). The plaque's text and the Virtuti cross are a
  plain white stone; the flags on poles are not drawn, only the two long banners.
- F's look check on the Mac or the phone: the dome's size, the band's red, the tower's colour.

## POLIN and the Ghetto Heroes Monument (F, 2026-11-02)
Built from photos gathered on the Mac (`refs/polin/`) and the LoD2 roof, spec `polin.md`. Found and left:
- The east front's two long dark band windows (~10 m, 4-5 m up) and the small lit slot south of the canyon are not drawn.
- The fins' letter frit and their 1.35 m rows: no skin draws them (S_FINS is the nearest; the 16 skins are full).
- The canyon's interior (the main hall, the bridge) and the lens's mullions are not modelled; the plaza's dark inlay line, the yellow bollards and the sunken SE service stair are the map's or missing.
- The monument's lions under the menorahs and the plaques at the relief's foot are not modelled.
- LoD2 shows a 3 m hump over the west roof that the ortho does not: a LoD2 artefact, not built.

## Muzeum Powstania Warszawskiego (F, 2026-11-02)
Built from photos gathered on the Mac (`refs/mpw/`: 25 Commons photos, the GUGiK ortho, REPORT.md and PARTS.md) and LoD2, site `mpw`, spec `mpw.md`. Found and left:
- W2's stepped gable at its mid-point (about 17 m), the corbel-table friezes and blind lancets (one cream band stands for them), the brick courses, the roof terrace railing.
- The white four-storey wing with the red-white banners north of W1 (about x -2960..-2948, z 148..160): the report could not place it, so it is not built.
- Freedom Park's objects: the photo screens, the armoured car and black granite monument at the wall's north end, the B-24 Liberator replica, the airmen's memorials, the pink-grey terrace and the gravel court; the wall's names (plates) are plain granite; the wall's south end under the trees is a guess (ortho 105 m, sources say 156 m).
- The Tobruk stands at OSM's spot (-2926, 117); the museum's own bunker may be elsewhere in the park.
- OSM leftovers seen on the ortho: pale pavilion roofs at x -2890..-2865, z 125..140 have no outline; a thin-triangle outline at x -2851..-2841, z 285..320 is a bad polygon.
- The fence's return along Grzybowska is not built (its line was uncertain).

## Skwer Linearny na Złotej and Dom pod Orłami (F, 2026-11-02)

- Built: Złota between Marszałkowska and Jasna is the linear park that opened on 3 August 2026
  (`tools/car_free.py`: the old car loop, its stubs and road-bed walls out, traffic edges `cf`, a
  20 km/h pedestrian zone, 36 young limes; `skwer_zlota.gd`: stone blocks, the rock fountain's jets,
  benches, the curved bench by the fountain, café gardens, bollards at Jasna). Dom pod Orłami is a
  model (site `orly`, spec orly.md): corner towers with bronze eagles, pediment, parody letters.
- Open: Mac look check (QUESTIONS); the square in front of Dom pod Orłami and Zgoda's own
  rebuild (pergolas, tree rows, the Philharmonic's square) are not modelled: Zgoda stays as the map
  has it; the new trees have no baked shade in ao.bin until the next full bake on the Mac.
- Found: OpenStreetMap already maps the 2026 lawns, tree pits, walks and both fountains, but still
  draws the old one-way loop as a living street; any later OSM fix of the loop leaves car_free a
  no-op (it is idempotent and matches by name and box).

## Pokorna 2 (F, 2026-11-02)

- Pokorna 2 remodelled as flats (site `pokorna2`, spec pokorna2.md). Open: Mac look check (QUESTIONS); the Gdański Business Center thread works nearby (Dworzec Gdański), keep its site zone clear of the outline at (-2123, -2217).

## Level 26 rooftop club (F, 2026-11-01)

Built: the club's furniture on the Atlas Tower crown (site `level26_club`); the crowd, band, queue,
bass and hours were already there. Open: Mac look check (deck size against the real roof, the
sign's side), the bass is a ground-level emitter (a rooftop one would reach the heli), laser beams
at night were skipped (they read as poles by day).
## Stadion Leguminy (F, 2026-11-01)
- Built from the mapped outline only (spec legia.md). Left: Mac photo check (QUESTIONS), the real stands' shape and the concourse side, entrances and tickets booths, club shop, the car park on the east side, the 20 m west stand as its own mass.

## Kibice by Stadion Leguminy (F, 2026-11-02)
Built (`fans.gd`, design docs/design/kibice.md): three friendly groups (north gate, north-east corner,
south side) on match evenings, scarves up on the drum, pink smoke puffs, banners, a kid with a foam
finger, a patrol car whose officer drinks a coffee, the `fan_chant` loop, the horn starts a chant.
Left:
- Phone look and cost near the stadium (+5 draw calls in the cloud bench); banner readability at phone size.
- The north groups stand between the pavement and the road edge on the forecourt; check against
  photos of the real gate (Mac photo check of the stadium is already parked).
- Match day built (2026-11-02): walkers in bunches on four routes (the bus stops by the Trasa,
  Łazienkowska from the west, Czerniakowska from the south) to the groups before kick-off, late
  runners, home the other way after full time; a win (chants twice as often, scarves up, `win`
  lines, a toast) or a draw (`draw` lines). Left: the real stop names and whether trams or buses
  serve the stadium (the map has no tram near it; QUESTIONS), a phone look of the walkers' size
  and the cost on the phone (+1 draw call while they walk, 0.09 ms fans scripts in the cloud
  probe, was 0.05).
- Making way and the match built (2026-11-02): walkers and the standing groups step out of the
  car's path (2.6 m clear, a hop with scarves up and a `dodge` line above 30 km/h), walk round a
  stopped car and step back after; during the match the groups file in until 15 % stay (the
  drummer and a few with a radio, `match` lines, no smoke) and come back out just before full
  time. Left: the feel on the phone (step speed, is the hop readable at the default zoom), a fan
  stepping aside can end up against a wall or on the road edge (no obstacle test, capped at
  3.2 m), the walkers don't step aside for the AI traffic, only the player's car.

## Police chases and radiowozy (F, 2026-11-02)

- Built: chasers at 0.8 of the player's top speed and an escape at 100 m (the old 0.92 opened a gap of only 2.4 m/s, so 120 m was out of reach inside the 30-45 s cap); the patrol estate is silver with the blue band, checker strips and bonnet panel, and a silver Crafter-style van (shape 3 of the police family, every third patrol car). Open: the roadblock and blockers still use the estate (a van across the road would read better); the lizak officer's car; a phone look and the feel of the new chase speed (QUESTIONS).
## Language choice follow-ups (F, 2026-11-02)

The game shows one language, Polish or English (`lang.gd`, Settings → DŹWIĘK → Język, the title's POLSKI / ENGLISH). Left:
- Polish-only text that has no English yet shows as it is in English mode: mission-status titles beyond `Lang.TITLE_WORDS`, the drawn pedal words in Polish-only tests, the Polish world signs (shop names are places, meant to stay).
- The notebook page, the pedals' words and the full map's labels are drawn text: `check_language` does not read them; look at them on the phone (QUESTIONS).
- A new `hud.show_*` call must pass both languages (Polish, English); `Lang.pick` shows one. A text with an inline "A · B" pair is a bug.
## All churches and Plac Zamkowy's houses (F, 2026-11-01)

F: "improve the houses near the plac; all the churches should be designed with best practices;
add it to the plan." Rules and the full inventory (39 named religious buildings, status each):
`docs/design/churches.md`. Built in a cloud thread (Sonnet), no photos:
- **Church kit** (`landmarks.gd` `CHURCHES`, spec `churches.md`): 22 churches as models, 250-950
  tris each, a card each. The older fronts (Anna, Krzyż, Wszystkich Świętych, Wizytki, Karmelici,
  Aleksander, Trójca, Zbawiciela, Teresy, Archikatedra) keep their own builders.
- **Plac Zamkowy's houses**: `HISTORIC` has a third circle (the column, 105 m), so the plac's
  west side and Krakowskie Przedmieście's first houses take the Old Town dress; within 110 m a
  house takes a pastel from `PLAC_PASTELS` (a quarter of the mapped colour kept); every front
  facing the column within 92 m gets an attic gable of one of three kinds by seed
  (`OldTownRoofs.plac_gable`: stepped, pediment, curved). The cloud has no LoD2, so the gables
  were tested as geometry (`check_old_town_roofs`), not seen on real walls.
- **Open, Mac:** the front end and tower count of every kit church; the gables on the real LoD2
  walls (do they stand on the right edges, z-fight, read at phone zoom); the palette against
  photos of Plac Zamkowy's west side (Kamienica pod Messalką, Baryczków).
- **Open, build:** Archikatedra's tower and apse, the Dominican, Capuchin,
  Franciscan and Pallotine monasteries; lit belfries at night; the Kościół Niepokalanego Poczęcia
  outline is only 20 x 14 m (a chapel, check its name).
- **Roofs (owned by the gameplay pass thread):** F's "roofs on the old city look strange, a lot of
  the same elements" is about `OldTownRoofs.dress` (one dormer per slope, the same chimney);
  this thread did not touch it, only the gables at the plac. Ideas for that thread: vary the
  dormer kind (hipped, round, none) and size by house seed, group dormers on a ridge line, drop
  them where a slope is under 8 m.

## City-life satire ideas (F, 2026-11-02)

Twelve ideas, plans in docs/design/city-life-satire.md. Built: #11 MIESZANE MIESZANE neon (HYPE
`kebab_mieszane`; evening queue `Crowds.MIESZANE`, "mieszane" lines in `viral`, one vendor line in `kebab_vendor`), #12 NOSE AGENCY crown sign on the Skyliner. Done before: #10 (PR #309). Open, each its own thread:
- **Loud cars (#1, Opus)**: sports-car meet at Browary Warszawskie (generic bodies, no marques) and revving cars in traffic with a louder engine layer.
- **Wellness circles (#2 sound healing, #3 techno yoga with hamsters, #4 women's club 40+, #8 park yoga and kung-fu; Sonnet, ONE thread)**: one new crowd spot kind `circle`.
- Queues (#5) and KRINGULA PIZZA (#6): built, with the "kolejka w kolejce" lines (2026-11-02). Left: F rewrites the joke text if he likes (QUESTIONS), Mac look check of the queue spots.
- Legia fans (#7): built (PR #336); what is left is in "Kibice by Stadion Leguminy".
- **Bike paths (#9, Opus)**: compare with the real network, fill gaps by data, rider density on the main ones.
- Small: English "UNDER CONSTRUCTION" on the edge roadworks boards; Mac look check of both new signs (the shop's door is a guess 40 m west of KEBAB KRÓL; Godot did not run in the cloud for this change).

## Bike paths (F, 2026-11-02)

- Fixed: gaps under 3 m between cycle path ends, ways split into pieces, spikes and sharp corners (`tools/cycleways.py`; riders turned back at every gap).
- Fixed (idea #9, 2026-11-02): the cycle crossings get Warsaw's white square edges (P-11, `map_builder.gd` `_build_crossings`) and the paths 660 white bike pictograms (P-23), 282 just past a crossing facing the riders coming off it, the rest every ~110 m (`tools/bike_marks.py`, run by bake_osm after car_free, idempotent CLI).
- Measured (2026-11-02): counting cycle crossings as joins, only 41 path ends stop 3-8 m from the next path (the old "600" counted paths only), 90 stop 8-20 m, 124 more than 20 m (map edge, or the path goes on as a footway).
- Measured against OSM (2026-11-02, the Mac's export, `tools/compare_cycleways.py --list`): separate paths 100 % of 65.8 km, crossings 100 %, painted lanes 97 % of 9.8 km; the gap was the on-street network: 33.3 km of contraflow one-ways (`oneway:bicycle=no`), 850 m of bus lanes open to bikes, 574 m of sharrows.
- Fixed (2026-11-02): `tools/bike_network.py` (bake_osm, or the CLI with `--osm`) paints 524 contraflow bikes with an arrow against the one-way by the car's left kerb, 14 bikes in the bus lanes, 23 sharrows with chevrons: contraflow 91 %, bus lanes 100 %, sharrows 58 %.
- Open: the rest of the contraflow (narrow streets under 2 m per side, junction-only ways: Grzymały-Siedleckiego, Oczki, part of Hoża); sharrows on the map-north bridge ways; the two shared foot-and-bike paths (684 m, grey pavers like Warsaw's, a `segregated=yes` one has a red half in reality).
- Fixed (2026-11-05): couriers rode the car lane's kerb edge beside the red cycle paths; roads with a cycle path within 14 m of that line are no kerb roads now. Open: the map has no `cycle` path on the east side of central Marszałkowska (27 of 64 kerb edges there stay open): a data gap for the bike lane (map thread); the path riders' own routes unchanged.
- Open: more riders on the main routes (Wisłostrada, Marszałkowska, Świętokrzyska; city-life-satire.md #9); riders' side offset jumps at a join; the 19 deck paths untouched by cycleways.py.

## Gdański Business Center (F, 2026-11-02)

- Built (PR in this change, site `gbc`). Open: Mac photo check (QUESTIONS); the plaza's planters, the lit lobby's glazing detail and the KPMG-style second logo on the tower are not built. Found: `bake_city` failed on main for the church of the Saviour (its SITE_AREAS box was missing); fixed in `tools/bake_sectors.py`.

## Gameplay pass (F, 2026-11-01, six phone screenshots)

F played on the phone and asked for an easier, calmer, more open beta: "a city, not racing; most
users will just explore". Each item: what F saw, what the code does today, the task, acceptance,
files, model. Order = priority. G1-G3 are quick wins (own PRs); the rest are separate threads.

**G1 · Heli and teleport open from the start (P0, Sonnet, quick win).** Today `first10.gd`
`heli_locked()` blocks the HELI chip and H key until the first rescue (or 7:00), and
`main.gd _teleport_refusal()` refuses the full map's hold-to-teleport during the guide ("Finish the
first drive first"). F: it's a beta, let explorers use both. Task: no gate on a fresh save for
either; the guide's heli beat (toast, tape arrow) stays as a hint. Races, jobs, rescues and police
chases still refuse the teleport. Accept: fresh save shows HELI in the top row at 0:00, H takes
off, a map hold teleports; `check_hud`, `check_first10`, `check_settings` pass. Files: first10.gd,
main.gd, hud.gd, game/tools/check_hud.gd.

**G2 · Traffic: calmer default and a findable control (done 2026-11-02: Low by default, stepped slider in Settings → Świat).** The setting
exists (Settings → Świat → "Ruch uliczny", four steps) but defaults to Normal (about 17 cars on
screen) and F did not find it. Task: default to Low for new saves (`Settings.NORMAL_TRAFFIC` → 1;
old saves keep their choice); change the control to a stepped slider with a live label. Accept:
fresh save reads "Mało"; a slider drag changes density at once; saved. Files: settings.gd,
settings_panel.gd, main.gd `_apply_traffic`, check_settings.gd. Note: police opts take
`traffic_level` as an index, so the slider stays stepped.

**G3 · +/- zoom buttons (P0, Sonnet, quick win).** Zoom is pinch only (`main.gd _zoom_view(±1)`,
5 view steps in `follow_camera.gd`; the on-screen buttons left in loop 2e). Pinch is not
discoverable. Task: two small round buttons under the speed readout, touch size, safe-area edge,
hidden in cinematic moments and photo mode; they call `_zoom_view`. Accept: five taps each way walk
the five steps and save; no overlap with the pill, wallet or minimap at 2532x1170 and 2868x1320
(shots). Files: hud.gd (new signals), main.gd.

**G5 · Flicker and "lag wall" audit (DONE 2026-11-01).** Finding: the flicker in IMG 7138, 7137
and 7135 is the occlusion ghost's halftone rim on building walls beside the car, not z-fighting.
The Bayer pattern is fixed on screen while the band slides over the wall, so it strobes. Fix
(`ghost.gdshaderinc`, mirrored in `main.gd` `_pick_unghosted`): the rim is 0.74-0.84 of the radius
(was 0.65-0.9) and the depth ramp 1-2 m (was 1-4 m), a thin seam instead of a wide halftone band.
The 7136 block is a sunken metro stair; metro canopies and stairs have no collider at all
(`Props.add_metro_entrance` is mesh only), so the car never stops on them. Collision table:

| Kind | Decision | Why |
| --- | --- | --- |
| Buildings, LoD2 walls, viaduct piers, garage doors | solid | real walls |
| Cutting and retaining walls (`_build_walls`) | solid | a drop beside the road |
| Barrier `wall` 1.9 m, `hedge` 1.2 m, `fence` 1.6 m | solid | they bound yards; a car through them looks wrong |
| Barrier `platform` (stop, 0.25 m) | no collision | kerb height, already so |
| Metro entrances, stairs, canopies, lifts | no collision (mesh only) | beside the road, pure dressing |
| Kiosk, stall, ice-cream cart | solid (small boxes) | stand on the pavement edge |
| Bollards, posts, ticket machines, columns | no collision | already so |
| Trees (trunk 1.3 m+), parked cars | solid | already so |
| Guard rails, bridge parapets | solid only over a drop | already so |

Open: a phone check of the thinner seam (the cloud has no phone); whether the 1.2 m hedges should
also go non-colliding is F's call.

**G6 · Going under bridges at entries: done (2026-11-02).** Found: on the lanes no bridge entry
drops the car (check_drive's routes now also flag a car more than 1 m under its deck lane: 0). Off
the lanes it did: the ground beside an approach's fill lies 1.5-2.4 m under the slab's end, so a
car coming onto the ramp at an angle (20°, 3-4 m off the middle) was over the 1.2 m it may climb
and drove on under the slab: Most Poniatowskiego's north ramps (875, −161) and (900, −89), Towarowa
over the rail cutting (−2383, 968), Wybrzeże Szczecińskie by Śląsko-Dąbrowski (494, −1450). Fix
(`map_builder.gd` `drive_height`, `_index_deck_feet`): on a ramp's foot (the first `DECK_FOOT`
10 m of a road piece's end that is no joint and stands within 1.2 m of the ground) a car up to
`DECK_FOOT_UP` 3 m under the slab climbs on (a small hop where the ground beside is low). New
check_drive pass "entries": from every such foot, 2,190 straight drives across the deck's width at
0° and ±20° (±40° tried: 0 too): 4 → 0 on both city paths. Left: the feel of the hop on the phone
(F's playthrough). Was: F: "when I was entering the bridge I went down under it". For that thread:
reproduce at the ramps of the Poniatowski, Świętokrzyski, Śląsko-Dąbrowski, Gdański and
Łazienkowski bridges and the Średnicowy flyover (7138 shows a flyover with a road below): the lane
graph's or the ground's height at the approach lets the car under the deck. Accept: the car stays
on the ramp across every bridge entry in check_drive's bridge pass.

**G8/G9 · Bus stops, buses and street furniture (done 2026-11-01).** Cause found: the OSM shelters
got their yaw from the road's direction, so roofs ran across the road (half with their glass back to
the lane) and many stood on the lawn. Now tools/snap_props.py (run by bake_osm after structures)
puts each bus-road shelter 1.7 m past its kerb lane, roof along the road, and turns the benches to
face the footway; buses.gd serves the stops by day (8-12 s stand, 1-3 step off, up to 2 board,
2-5 wait); cafe sets stand only against a shopfront. Open: look check on the phone (do the
people read as passengers, is 10 s right with Low traffic); 11 shelters had no clear spot and stay
where they were (turned only), 7 inside a lane or a building were left out; tram-stop shelters
and the first scene's authored cafe tables are unchanged; night service (N buses) is still only
the Centralny hub.


**G12 part 2 · The two quest lists: done (2026-11-02).** The full map's ZADANIA card (right, under
✕ and ≡; the ≡ cards take its place): tabs ZADANIA AUTO / ZADANIA HELI, the vehicle's own first,
at most four 44 pt rows (quest_lines.gd `rows`: requests first, then places nearest first, one per
group, three cassettes). AUTO: the nearest kebab stand, słoiki station and Leżak depot (night),
Warsztat u Mirka, "Podwózka · ask for a ride" (PODWÓZKA's rule). HELI: "a rescue call by
helicopter" (missions.gd `request_call`: a roof or sandbar call on the card now) and the three
nearest cassettes not taken. A tapped place becomes the quest pin (main.gd `quest_pin`: the arrow
and minimap dot in its colour while nothing else is on; gone within 25 m, a cassette when taken);
tapped again it goes. Empty while a race, job or rescue is on. `--quest-pick=N` for runs. Left:
- **G12b: done (2026-11-02).** The pad's way into the card (full_map.gd `pad_quest`): X switches
  the tab (its first row picked out), the D-pad up / down moves the pick in the pad's yellow ring (a
  place's row centres the map on it), Y takes it as a tap; A stays the teleport hold. The card shows
  the keys while the pad is used. Left: phone look (are four rows enough, is the card in the map's way).
- **G12c: done (2026-11-02).** AUTO also lists the open "Na czasie" slots, Mrożulo's van (Mlask) and
  the Friday PISTACJA drop (trend_job.gd `offer_places`, only places not cooling down), the ladder's
  next rival where they cruise now (the pin follows them, quest_lines.gd `MOVING`) or Seba's start for
  "Trzy mosty" at night; HELI the peacock's roof call while Pan Paw is up (missions.gd
  `request_peacock`, from anywhere). The quest under way is one "Teraz · ..." row on the vehicle's
  tab; tapped, the map looks at its target. Left: PADELNIA's "Czwarty" and the Deski calls are not
  listed (they come by phone or need a queue); a row per running job kind (now one generic name).

**G13 · Upgrade shop: done (2026-11-02).** Warsztat u Mirka's card has a second tab, "Części i auta":
the Ołdi TT (2,500 zł, faster, a lower coupe model), the nitro "Kebab Boost" (600 zł; a bolt disc left
of the horn or the N key: 3.5 s of boost, 20 s refill), tyres (grip) and engine (top speed and pull),
levels 1-3 at 150-400 zł. Saved in the [garage] section (no version bump). Left, found on the way:
- **G13a (P2, phone).** Is the pricing right (first part after a few jobs, the nitro after about 15
  minutes, the TT as the goal), does the nitro feel good and is the bolt easy to hit with the thumb,
  does the TT read as a coupe from the 80 m view? Tune `upgrades.gd` and car.gd `NITRO_*` after F's run.
- **G13b (P3, Sonnet).** Done 2026-11-02: two tail flames (one see-through mesh, only while it burns), a `nitro_whoosh` and a buzz when it lights (`car.nitro_started`; `--pedal=nitro` for shots); the phone must judge the flame size and the buzz.
- **G13c (done 2026-11-02).** The chasers and the escort drive at 0.8 of the player's own top
  speed (police.gd `chase_top`: model x engine; was a fixed 24 m/s, which a TT at engine 3,
  145 km/h, left standing); the nitro's lift is left out, so a burn opens a quick gap
  (check_police "chase pace"). The pad's nitro is LB or RB held; the view's turn moved from the
  shoulders to right-stick flicks (check_gamepad P9). The keyboard's nitro is Shift only: N also
  switched the time of day. ~~Left: the pad's nitro has no tank ring while the touch HUD is hidden
  (pad mode)~~ Done 2026-11-03: in pad mode the nitro's disc stays in its place as the tank's
  gauge with "LB / RB" under it (hud.gd `_pad_nitro_shown`, `check_gamepad` P16). Left: the phone feel of a TT chase (QUESTIONS).

**G14 · Unstuck and reset easy to find (P0, quick win).** F: "in Settings there should be reset
game, and unstuck: if the user is stuck in textures, click and move to the main road". POMOC
DROGOWA (PR #231) lived at the bottom of the Jazda tab. Task: both buttons in a row at the top of
Settings → Jazda (the first tab); NOWA GRA asks a second tap within 4 s, then wipes the save
(`_on_new_game`). Files: settings_panel.gd, main.gd. The "later" is done (2026-11-03): trying to
drive (gas, brake or the stick) for 8 s and still within 4 m of one spot, whatever holds the car (a
wall nothing pins it against, a gap inside a building), POMOC DROGOWA comes up on the context button
with one toast and a tap tows (car.gd `stalled`, main.gd `_stuck_offer_frame`, `check_stuck_offer`).
Fixed 2026-11-06 (PT-23/PT-24, Autopilot run 2026-11-05): the offer never came up while the ride
app's PODWÓZKA held the context button (it waited for a free button, and PODWÓZKA is up whenever a
ride could be taken); the button now has ranks (hud.gd PILL_RANK: call > POMOC DROGOWA > KASETA,
START KURS > PODWÓZKA), so KASETA by a tape also shows over PODWÓZKA. And the spot is 10 m, not 4 m:
backing off a wall for another run reset the count every try.
Not while parked by the game, held by the stop assist, in the water or flying; the pinned car's own
turn-out and tow still come first. Left: the phone look. ~~A pad has no button for the context
button~~ Done (2026-11-03): the pad's A presses it (see "The Mac App Store version and gamepads").

**G15 · Stop assist and quest rings (P0, quick win).** F: "pomoc przy zatrzymaniu is not working
well; make the start and end points bigger and add assistance to pickup". Task: ring 9 → 13 m,
"stopped" under 6 m/s, look-ahead 60 m, aim 3 m inside. Left for the phone: is it enough, or
should a pickup start by driving through the ring without stopping (G10). Files: stop_assist.gd.


**G18 · Ujazdów and the castle (P1, Opus, landmark thread).** F: improve Ujazdów and Zamek
Ujazdowski. One landmark thread: compare the castle's model and the park with the orthophoto and
photos, per the landmark recipe in docs/LANDMARKS.md.

Split for parallel threads: G4 (driving), G5 (collisions and flicker), G8+G9 (street life),
G10+G12 (quests), G13 (shop, done), G16 (text), G17 (traffic), G18 (Ujazdów). G1-G4, G14 and G15 are done by this thread.

## Plac Bankowy as in real life (F, 2026-11-02)

Pass 1 (cloud, Sonnet, light definition of done): the Blue Skyscraper (OSM "Błękitny Wieżowiec")
is blue reflective float glass (S_MIRROR, glass #5f94c6, grey roof, cool podium), the gold was its
copper first cladding; kept skins with cards for the Treasury palace / city hall (`ratusz`, the
OSM name "Urząd Miasta Stołecznego Warszawy", cream-yellow, grey-green roof), its Voivodeship wing
(`wojewodzki`; OSM maps it teal, now palace yellow), the old Stock Exchange and Bank of Poland
(`gielda`), the Arsenal (`arsenal`), Pałac Mniszchów, Dom Bankowy Landaua. The OSM already maps
the Treasury palace's portico columns and wing pavilions; they now read in yellow with pale columns.
- Pass 2 DONE 2026-11-02 from the Mac photo report (`photo-reports/ratusz.md`, spec `bankowy.md`):
  pale ochre-cream walls under green copper on the three palaces; the Ratusz's colonnaded wings on
  the 34 mapped columns (stylobates, entablatures), the six-column giant portico on its arcaded base
  under an attic with no pediment (the report: no pediment); the Bank Polski's rounded corner (piers,
  the upper tier of arches, the drum and its shallow green dome). Filharmonia's Jasna front and
  Teatr Polski's Karasia front from their reports too (specs `filharmonia.md`, `teatr_polski.md`).
- Left: the Voivodeship wing's own front on the square (skin only), the Arsenal's real front
  (central risalit, tall roof; the report has no photo of it), the Akcja pod Arsenałem boulder on
  Długa (report photos 9-11, a quiet card), the Bankowa tenements (unnamed in OSM: a site by point,
  like `_tallest_at`); Teatr Powszechny. Mac look checks in QUESTIONS.
- Pałac Jabłonowskich (the old Ratusz with the clock tower) is on Plac Teatralny, not here, and is
  not modelled yet (OSM "Pałac Jabłonowskich", 39 points near (-990, -1185)); next to `teatr`.
- Overlaps Za Żelazną Bramą (PR #215): none; it works west of Al. Jana Pawła II.

## Nowogrodzka street by street (2026-11-03), pass 1
The first tier C street pass (CITY_INVENTORY Part 2, Śródmieście): every Part 3 place with a Mac photo
report was taken by an open thread or blocked (NBP: one photo; Koneser, the fountain park and Gdańska
off the map), so this pass takes the bar strip between Marszałkowska and Bracka, 14 OSM bars and the
street nearest the start area with no pass yet. Built (cloud, Opus):
- Eight parody bar fascias at the OSM points of the real bars (`Storefronts.NOWOGRODZKA`: KWARTA at 4,
  U HALINKI BAR at 10, ZA BARDZO at 11's gate, KRAFTOWNIA IPA DO DNA at 12, SCHRON PIWNY at 20,
  PODWÓRKO 22 SZOTY at 22's gate, NALEWALNIA KIEDYŚ PO 4 at 27, DŻINIARNIA at 31); check_parodies 115 venues.
- Pavement crowds outside them (`Crowds.NOWOGRODZKA`, seven spots, 8-14 people each, standing) on a
  new `pub` curve (16:00 a few, 23:00-01:00 full, gone by 04:00) × `PUB_WEEKDAY` (Fri/Sat full, a
  Tuesday 45 %), winter 60 %, rain 30 % (`pub_level`, check_crowds).
Open:
- Mac look check (QUESTIONS): the signs on the right walls and doors, the crowds on the pavement.
- The yards of nos. 11 and 22 (the real bars sit 60-70 m in, in courtyards): a gate arch and a lit yard.
- The houses (plaster, cornices, shop storeys) need photos. Mazowiecka's club street followed (below).

## Mazowiecka's club street (2026-11-03), pass 1
Tier C street pass, same pattern as Nowogrodzka (cloud, Sonnet). Built:
- Five parody club fascias at the OSM points of the real clubs (`Storefronts.MAZOWIECKA`: TYGRYS JAZZ at
  6/8, SZOTOWNIA at 9, SZKIC NOCĄ at 11A, ENKLAWKA at 12, POKÓJ 12,5 at 13). One sign per address: La Pose
  shares 6/8 with Tygmont, Mazo 9 with Czupito, Ritual 12 with Enklawa; Bank Club and Blu Club (no. 14)
  are the existing LOMBARD of places.json. check_parodies counts the new table.
- Pavement queues and smokers (`Crowds.MAZOWIECKA`, five spots, 10-14 people, standing) on a new `club`
  curve (the clubs' own: fullest 01:00-03:00, gone by 06:00) × the clubs' `WEEKDAY` (Fri/Sat full, a
  weekday a fifth), winter 60 %, rain 30 % (`club_level`, check_crowds).
Open: Mac look check (QUESTIONS); a bouncer-and-rope dressing at the doors; the northern pedestrian
stretch toward Królewska; the houses need photos.

## Wilcza and Poznańska's bars (2026-11-03), pass 1
Tier C street pass, same pattern as Nowogrodzka and Mazowiecka (cloud, Sonnet): the next densest OSM bar cluster
(13 bars on Wilcza, Poznańska, Hoża). Built:
- Seven parody bar fascias (`Storefronts.WILCZA`: MUZA NA BIS at Wilcza 17, CYGARNIA DYMEK at 26, GORĄCZKA PIĄTKOWA at
  27/29 (two bars, one door), AURA PO PRACY at Hoża 27, MACKI I KUFLE at Poznańska 12, KASETA PRZEWIJANA at
  Poznańska 7, REPUBLIKA BANANOWA at Wilcza 51A). An eighth sign cost a plain Frogs (check_parodies' 80 % floor), so
  Rausz shares the Gorączka door.
- Pavement crowds (`Crowds.WILCZA`, six spots, 8-14 people, standing) on the existing `pub` curve (`pub_level`).
Open: Mac look check (QUESTIONS); Wilcza 73 (a nightclub and a sake bar) and the Żurawia/Chmielna cluster (33 bars,
partly covered by Nowy Świat and the Chmielna passes) are next; the houses need photos.

## Praga's old streets (2026-11-03), pass 1
Asked as "Ząbkowska" (about 7 bars in OSM). Ząbkowska's bars (x 1020-1080, z about -2080 to -2110) and Moxy lie in
the map's cut north-east corner (z < -2045), so there is nothing to put them on (QUESTIONS). Built instead the bars
that are on the map in Praga's tenement streets (cloud, Sonnet):
- Six parody fascias (`Storefronts.PRAGA`: ŚWIAT PO PRASKU at Okrzei 26, BARISTA Z PODWÓRKA at Okrzei 8, WINO ZE
  SKRZYNKI at Sierakowskiego 4A, KRAINA WINA at Wrzesińska 4, KIJOWSKA DWÓJKA at Kijowska 2, POD KUFLEM ZA ROGIEM at
  Targowa 1), parodies of the real bars' trades; check_parodies counts the new table.
- Pavement crowds (`Crowds.PRAGA`, six spots, 6-10 people, standing) on the `pub` curve, smaller than the centre's.
Open: Mac look check (QUESTIONS); courtyard life (benches, the yards of Okrzei and Sierakowskiego) and the
tenement fronts need photos; Ząbkowska waits for the map to grow north-east.

## Nowy Świat street by street (F, 2026-11-02), pass 1
Built (cloud, Sonnet): eight parody shopfronts (`Storefronts.NOWY_SWIAT`, check_parodies 68 venues). Open:
- Mac look check of the eight signs (QUESTIONS); move them to real doors.
- Pass 2 (cloud, Sonnet, 2026-11-02): per-house plaster (`NOWY_PASTELS` within 30 m of the street south of Jerozolimskie, walls only, both paths), patio heaters (13, `heater` kind), chill crowds at four terraces (`Crowds.NOWY_SWIAT`, 10-12 people each on the chill curve). Cloud shot checked the plain path only (no LoD2 in the cloud).
- Houses: the plaster palette and the tenements' cornices against photos; the north end (Staszic Palace, Visitation) and the Palm end.
- Café gardens: shop awnings (need photos), pavement setts, night lighting ("From map review B"); heaters have no glow yet.
- People: the crowd spots are read off the café sets; no evening-only or rain behaviour beyond the chill curve.

## Marszałkowska street by street (F, 2026-11-01)

Order: plac Bankowy to plac Zbawiciela. Pass 1 (cloud, Sonnet): Kościół Najświętszego Zbawiciela
modelled (site `zbawiciela`, spec `zbawiciela.md`, 1029 tris).
- Mac photo check of the church: plaster and roof colours, belfry and spire shapes, the dome's
  height, whether the porch is a portico or a recess (all estimated; towers' 76 m is mapped).
- Pass 2 (cloud, Sonnet, 2026-11-01): MDM modelled on the kept skin (site `mdm`, spec `mdm.md`,
  2002 tris) then reworked 2026-11-05 after F's Street View shots (the spired towers were wrong):
  cream plaster over a sand-stone base with shopfronts, ring arcades only, four stepped attic
  pavilions with finials, roof neons MDM, XIAOMY, BYDŁO and HOTEL MDM (3403 tris). Mac look
  check parked (QUESTIONS): which facades have arcades, sign spots, balconies, the pavilions.
- Pass 5 (cloud, Sonnet, 2026-11-02): Plac Zbawiciela's cafés and the church at night. Four neon cafés
  (`Storefronts.ZBAWICIELA`: KAWA ZBAWIENIE, SZARLOTKA NA ROGU, PLAN Z, PO MSZY SPRITZ) and six parasol
  terraces round the ring (`bake_street_details.py` TERRACES, 16 café sets, planters at the row ends);
  the church gets lit gilt crosses and balls, a stained rose that glows, four porch lanterns and 12
  floodlamps (1199 tris, budget 1250). Open: Mac look check (QUESTIONS), the signs on the real doors,
  heaters and awnings on the terraces, a café crowd (crowds.gd zone), the floodlit plaster wash.
  Fixed 2026-11-02: verify `stops` failed on main since this pass (K5, a set 5 m off the east-end
  shopfront). #282 added the shopfront test (two sets dropped); #302 uses `Placer.frontage` and moves
  two rows 1 m in, so all 16 sets stand again.
- Next on the street: the reliefs' real subjects, Marszałkowska's houses, roads and street life
  street by street.
- Pass 2 (cloud, Sonnet): people waiting on Marszałkowska's 12 mapped tram platforms (`crowds.gd`
  `stop` sites, commute curve). Mac/phone look check: do the groups read as commuters at the
  stops, facing is random (not toward the track), the density on the narrow islands, and
  whether the `ped_zones` walkers also fill them.
- Pass 3 (cloud, Sonnet, 2026-11-02): street details (`bake_street_details.py`) now cover the
  whole street: corridors C9 (Bankowy side to Świętokrzyska) and C10 (the Rotunda to Zbawiciela)
  add planters, bollards, kiosks and columns; tram islands with no mapped shelter within 25 m get
  a bench, a stop post and a ticket machine on the slab (`street_details.gd` lifts them 1 m).
  Plac Bankowy itself is left to its own item. Mac/phone look check parked in QUESTIONS. Still
  open on the street: facade, shopfront and roof polish house by house (needs photos), crossings
  against real photos, the island kits only fit where the slab is wide enough (most islands
  got no kit: a fence, wall or the tracks leave no room).
- Pass 4 (cloud, Sonnet, 2026-11-02): eight neon shopfronts on mapped house numbers (`Storefronts.MARSZALKOWSKA`:
  milk bar, dry cleaner, watchmaker, pastry shop, optician, florist, haberdashery, herbalist; check_parodies OK).
  Needs F's photos / Mac look check (QUESTIONS): doors at the real shops, per-house plaster colours and
  cornices, the crossings against real photos; Plac Bankowy's end.
- Next on the street: houses and roads street by street (the church's night lighting and the
  square's cafés are done, pass 5).

## Nowy Świat (F, 2026-11-01)

Done (N1): `bake_street_details.py` DENSE puts a café cluster every 11-17 m on Nowy Świat (was every
70-110 m): 12 to 33 cafés and 19 to 49 planters on the street, and the per-sector cap is 85 (100
with stop kits). Skins and cards for Pałac Zamoyskich, Kamienice Mikulskiego 53 and 55, Kamienica
Bürgera, Kamienica Jasińskiego and Pałac Kossakowskich (landmarks.gd SKINS, INFO).
- **N2 (open):** colours and card texts are estimates, no photos in the cloud (Mac look check);
  shops done 2026-11-02 (BLIKLINA OD 1869 near no. 35, Chmielna, Foksal; positions estimated, move to real doors);
  the tenement fronts and café gardens' real extent from orthophoto; a night look of the terraces.
- Not benched (cloud, no GPU): +68 props in the street-details batch, no new material or draw call.

## Parks (F, 2026-11-01)

Built in the cloud (flat ground, no Mac photos): `park_details.gd` from `tools/bake_park_details.py`
(206 items, 8 cells, 0 new materials). Open:
- Łazienki Królewskie lies south of the map's edge (z ~ 1740+): the Palace on the Isle, the Chopin
  monument, the peacocks and the squirrels need the map extended south first (map-engineer, Opus).
  The prop `peacock` is built and waits.
- Placement is by rule on the OSM geometry (statues along alleys, anchors snapped to free spots):
  the carousel stands about 40 m from the plaza circle it was aimed at; check real spots with photos.
- People and animals are still pieces (no walking, no bobbing ducks): moving ones go through the
  city_life guests if the look check asks for them.
- Phone bench of the park cells (one draw call a cell in view) not run.

## Old Town Market Square, the Syrenka and the decks (F, 2026-11-01)

Built in a cloud thread with no photos (spec docs/landmarks/specs/rynek.md, LANDMARKS 2.12).
Open:
- **Photo check on the Mac** (QUESTIONS): the paving, the umbrella colours, the statue's pose and
  pedestal, the rim wall against the mapped pond.
- The houses' plaster colours: the Rynek's four sides use the generic historic palette; real
  fronts (Dekert, Fukier, the Museum of Warsaw's houses) need photos for per-house colours,
  sgraffito and the real stepped gables on the other three sides (`OldTownRoofs.gable` does the
  east side only).
- The umbrellas are one row on the 7 m line, drive-through, with no night light; a second row,
  café lights at night and a few people sitting under them would make the square busier.
- The statue is 6.4 m tall (taller than life, for the camera); if the photos say she should be
  smaller, scale `_syrenka_figure` and the pedestal heights together.
- The fountain's rim is a collider now (the car meets a wall, not the pond); the pedestrians
  still wade through the pond's map polygon (they avoid water by a distance rule): make them walk
  round the rim.
- Varso's deck: visitors stand on the crown's roof ring (roof grid, spire flattened away); the real
  Varso Observation Deck is glazed at ~230 m. St Anne's terrace is at the tower's cornice (25 m);
  the real one is at ~40 m. Opening hours are guesses (10-22, 10-19 and 10-18). PKiN's 30th-floor
  terrace (114 m) has up to 16 visitors on a 1.9 m ledge with a balustrade round the shaft (the
  real gallery runs inside the walls, so the ledge is a stand-in; Mac look check parked: ledge
  depth, spacing, whether it reads as a step in the silhouette).
## Norblin, Browary, Koszyki, Elektrownia (F, 2026-11-01)

Built (specs `docs/landmarks/specs/norblin.md`, `browary.md`, `koszyki.md`, `elektrownia.md`):
the four sites as L2 models on their mapped outlines, `chill_*` crowds in their yards
(`crowds.gd` CHILL, `chill_level`) and KROWA 2.0, the milk bar queue on Norblin's Żelazna front
(`MILK`, `milk_queue`, venue sign in `storefronts.gd`). Open, for the Mac look check (no photos in
the cloud, the cloud's picture of each place is thin):
- Norblin: which wings are historic brick and which new; the door of the milk bar (moved with the
  site onto Plater's Żelazna front, 2026-11-02, still a guess). The chimney was dropped (the photo
  report's ortho shows none); Verit, the low block on Prosta, is still the map's plain building.
- Browary: roofs (pitched, not flat), the Brama's arch, the chimney's count and place, the real
  heights (OSM gives 37 m for the gate block, built at 30).
- Koszyki: the real roof (iron truss under glass) and the 1909 facade's details on Koszykowa.
- Elektrownia: the hall roofs, the chimneys' number and place, the heights (OSM 14 m, built 19 m).
- The chill spots: the yards' spot coordinates (CHILL in `crowds.gd`) and the look of the groups
  on the Mac; bubbles for the chill crowds (none yet).
- KROWA 2.0 is our parody name; F may want another (QUESTIONS).

## Roofs across the map (F, 2026-11-01)

Plan and lane file: docs/design/roofs.md. The LoD2 roof shapes and their aerial-photo colours
were already real; what they lacked was material and edge detail.
- [x] RF1 roof materials in building.gdshader: tile courses on red pitches, standing-seam sheet
      metal on other pitches, zinc on steep mansard faces, tar-paper strips on slabs and dark
      flat roofs, welded membrane and gravel on offices and pale ones, sedum where the photo is
      green; detail fades with distance.
- [x] RF2 parapets with a light coping on every flat LoD2 roof of 60 m² or more (outer edges of
      2 m or more, not round plant boxes), RF3 chimney stacks on pre-war tenements (party-wall
      rows on flat roofs, one on some pitches; mansard dormers outside the Old Town were tried
      and dropped: they read as black holes) (`roof_dress.gd`, `check_roof_dress`; no new draw call).
- [x] RF4 (2026-11-01, `osm_roofs.gd`, `check_osm_roofs`): OpenStreetMap-only buildings (no LoD2)
      that are small (30-520 m²), low (3.5-16 m), convex and not a hall/office/school/church get a
      hip roof, or a gable on a plain rectangle (pitch ~29°, walls stop at the eave, the ridge is
      where the flat lid was, so the roof grid is unchanged). Colour where OSM has none: Royal
      Route aged copper (55 %) or red sheet, MDM (430 m round Plac Konstytucji) dark red sheet,
      houses tile red, the rest tile / red sheet / grey. Same material, no new draw call.
- [ ] RF4b: Powiśle's roof terraces (decking, planters) and concave footprints (L-shapes stay
      flat; needs a straight skeleton); a Mac look at the phone size on real LoD2 coverage (in the
      cloud there is no LoD2, so every small OSM house showed it).
- [x] Mac check on today's bake (2026-11-01): 130 draw calls before and after, 0.61 → 0.62 M
      triangles, no shimmer; tile courses show close up and fade at the default zoom.
- [ ] The phone bench and a look on the phone (needs F's yes for a device run).

## Crash scenes (F, 2026-11-01)

Lane file: [docs/design/crash-scenes.md](design/crash-scenes.md). Built: `crash_scenes.gd` (a
fender bender every 3-5 minutes ahead on a main road: two wrecks, the police car, the ambulance as
the police family's shape 2, seven people, the `crash_scene` lines, KEBAB FM's `crash` lines),
traffic queueing and going round parked cars (traffic.gd PARKED_LOOK / PARKED_WAIT),
`check_crash_scenes.gd` in verify and CI, `--crash=now|X,Z|on|0`, `--crash-log`. Left:
- The phone's look (the ambulance's lettering and band at phone size, the halos at night) and a
  bench on the device with a scene in view (+0 draw calls by construction; cloud bench below).
- Phone check of the new scene siren (sfx.scene_siren, the chase siren at -20 dB from the
  ambulance, a voice of its own) and the amber minimap / full-map dot (hud.set_scene_mark):
  level, and whether the dot reads at phone size. No hazard-light tick yet.
- Wrecks have no hazard lights or broken glass; nobody waves the traffic on.
- The scene's people stand still (no gestures); the onlookers' phones are not modelled.
- A scene on a one-lane road (none today: they need 2+ lanes so the traffic can go round).

## Ujazdowski Castle (2026-11-01)
- Done: site `ujazdowski` (landmarks.gd `_build_ujazdowski`, spec `ujazdowski.md`) and the notebook place
  `zamek_ujazdowski` (district Ujazdów i Łazienki had none).
- Left: Mac photo check (colour, tower caps, entrance side, courtyard); the district still has no egg and
  only this one place besides the padel court; Ujazdowski Park (paths, benches, the pond), the Botanic Garden,
  Chopin's monument and the Trasa Łazienkowska trench are the next steps (DEMO 2.3 rows B).
- The cloud's bake_city prints the same site mismatches as main (now 17 with `ujazdowski`): the Mac's
  full re-bake settles them.

## Grand hotels (2026-11-01, hotels pass)
- Done: Hotel Bristol's body (`bristol`: plinth, courses, cornice, slate mansard, dormers, canopied
  door with BRISTOL in gold neon on the Krakowskie front, pediment) and Hotel Polonia Palace (`polonia`,
  built whole, red canopy on Al. Jerozolimskie, shares its east wall with Metropol), both through
  `_palace_hotel` (landmarks.gd), specs `bristol.md` section 9 and `polonia.md`, cards.
- Left, all for the Mac photo check: real colours of both facades, the real storey count (Polonia 25.5 m
  and Bristol 27.4 m are mapped or estimated), where the entrances are, the mansards' true profile;
  the other grand hotels (Hotel Metropol 1960s block, Mercure Grand, Hotel Saski) stay generic;
  Hilton, Holiday Inn and the Ibises are plain OSM extrusions (the Sheraton is a model since 2026-11-03).
- Radisson Blu Sobieski (Plac Zawiszy 1) done 2026-11-02 as "Radysław Blu" (`sobieski`, spec `sobieski.md`) from the
  OSM outline, no photo: Mac check of band colours and order, storey count (31 m assumed), entrance. The Atlas Tower
  (-2230,1015) next door is a separate thread and untouched here.

## Old Town hotels (2026-11-01)
- Done: `hotel_kasztel` (Castle Inn, Plac Zamkowy), `hotel_canaletto` (Hotel Bellotto), `hotel_starowka`
  (an aparthotel on the Rynek): fronts on tenements, parody names, cards. Spots are estimates from the
  published addresses, no photos. Left: Mac look check (which house, which street face, the board's
  size against the lane), real facade photos, Le Régina/Mamaison and the other New Town hotels (the
  map has no New Town data north of Freta), PURO Stare Miasto (-1094,-1018) has a mapped hotel
  building but no front, the unnamed 4.3 m hotel at (-819,-1419).

## Royal Castle and its gardens (F, 2026-11-02)

F asked to bring the castle in line with Ogród Park Krajobraz's garden project
(krajobraz.com.pl/projekt/zamek-krolewski) and to look for more sources. Pass 2 done (spec
`docs/landmarks/specs/zamek.md`): Clock Tower, turrets, terracotta roofs, the cream Vistula front
and dome, Kubicki's Arcades (site `arkady`), tubs, fountains, vases, the Lower Garden's lawn
carpet (`map_builder.LAWN_CARPETS`) and the gardens' low basin rings (`GARDEN_RINGS`).
- Z1 Mac look check: the arcades' top and gravel walk against the terrace, and the tubs and the Upper Garden
  fountain on it. (LoD2's tower and eave: answered by F 2026-11-03 and fixed: LoD2's Clock Tower cut under the
  model's cornice, LoD2's steep roof slopes in tile, its walls along the river front in the front's cream.)
- Z2 The courtyard (Dziedziniec Wielki): fan-pattern setts, a granite walk from the gate, the
  yard walls pinkish-beige on the east and north wings.
- Z3 The Vistula front's two gabled side risalits (14 m, pediment, corner statues) and the
  four-arch loggias with balustraded balconies; dormers on the whole roof ring.
- Z4 The south quarter garden: the embroidered parterre (gravel and box scrollwork) by the SE
  corner, x -581..-568, z -1522..-1492; the Lower Garden's L-shaped bosket and hedge fan.
- Z5 Pałac pod Blachą as a model (copper-green hipped roof, cream walls, attic statues).
- Z6 Plac Zamkowy's granite slab paving round the Column.

## Mariensztat and Krakowskie Przedmieście: review (F, 2026-11-01)

F asked whether Mariensztat and Krakowskie Przedmieście are modelled well. Cloud shots (OSM
buildings only, no LoD2 or terrain in the cloud) compared with what the places are known to look like.

**Mariensztat** (Rynek Mariensztacki at (-482,-1366)): the street plan is right (Rynek, Mariensztat,
Sowia, Garbarska, Furmańska, lower Bednarska), the square has its paving, planters and fountain
ring, but the houses were generic: modern facade colours and grey roofs, no landmark card, nothing
that says "1949 estate". Real Mariensztat is small 2-3 storey houses in pastel plaster under steep
red tile roofs with dormers.
- ~~M1 Mariensztat dressed like the Old Town~~ Done 2026-11-01: `map_builder` MARIENSZTAT polygon
  joins `_historic`, so its 47 houses take the tenement palette, red tiles, dormers and chimneys
  (LoD2 path; load time only, +0 draw calls). Left: Mac look check (roof pitch from LoD2, the
  palette against photos, the 20.8 m house at (-388,-1362) that OSM tags taller than its neighbours).
- ~~M2 Rynek Mariensztacki's card and reliefs~~ Done 2026-11-01 (site `mariensztat`, spec
  `mariensztat.md`, 540 tris): six relief panels (frame, terracotta field, sun, two figures) on the
  south row's faces, and the card. Left: Mac photos for the real reliefs' subjects, number and
  places, and the square's well or fountain (the map's fountain ring stays).
- M3 the escarpment, the W-Z tunnel's mouth and Nowy Zjazd's viaduct over the estate: check on the
  Mac with real terrain (the cloud has none).

**Krakowskie Przedmieście** (x -717..-434, z -1333..-465): well covered. Models: the Castle and
Sigismund's Column at the north end, St Anne's (portico and bell tower), the Visitationists, the
Presidential Palace, Hotel Europejski, Staszic Palace with Copernicus, Holy Cross; historic
lanterns and street furniture along the whole street. 2026-11-01 (K1-K5, K6 in part; all from
the OSM outlines, no photos; specs in docs/landmarks/specs/):
- ~~K1 the Carmelite church~~ the front on the kept skin (`karmelici`, 374 tris).
- ~~K2 Mickiewicz's monument~~ (`mickiewicz`, 282 tris). Left: the exact spot on the lawn (today
  the lawn's centre), its facing, the fence and corner lanterns' real shape (Mac photo).
- ~~K3 the University gate~~ (`brama_uw`, 458 tris; Pałac Kazimierzowski is a kept skin with a
  card, `kazimierzowski`). Left: the gate's true spot and width (today a guess at the campus
  entrance in the east frontage near (-494,-684)), the palace's own model.
- ~~K4 Pałac Potockich~~ the court front (`potocki`, 166 tris) and the Kordegarda built whole
  (`kordegarda`, 466 tris, was a 4.3 m shed). Left: the second (southern) guardhouse is not mapped;
  Pałac Czapskich (-609,-597) stays a box.
- ~~K5 Hotel Bristol's corner dome~~ (`bristol`, tower 334 tris; its body done in the hotels pass,
  see "Grand hotels"). Left: Mac photo check that the dome is on this corner, its profile and the
  facade's colours.
- **Photo rebuild (2026-11-02)** from `refs/krakowskie/` (29 Commons photos, three orthos; report
  docs/landmarks/photo-reports/krakowskie.md): Mickiewicz moved to (-626, -1078) and rebuilt facing the
  street on his 16 x 10 m terrace (balustrade, two flights, four gilt-flame candelabra, 13.5 m pedestal
  and poet); the University gate moved to (-462, -642) and rebuilt (white pavilions with statues in
  niches, curved gables, lanterns, the crowned-eagle gate, side gates, urn piers); Pałac Kazimierzowski
  ochre with a red roof and its white portico; Pałac Czapskich built whole (brick-red, white trim,
  pediment, red hips, facing east); Pałac Potockich cream under orange-red roofs, its two street gates;
  the Kordegarda in white stone with arched windows and a statued attic (no portico); the Carmelite
  front in sandstone with its paired columns, temple front, copper globe and lantern turrets (2.2 m
  further out, on the outline's risalit); Bristol cream with a zinc mansard and the open belvedere;
  Europejski paler. The "southern guardhouse" is the south wing's end, now in the skin's colours.
  Left: Mac/phone look check (QUESTIONS), café gardens/bollards/awnings (below), the setts south of
  Kopernik, Prus's and Wyszyński's spots.
- ~~K6 small things~~ done 2026-11-01: the black Chopin benches (`map_builder`
  `_split_chopin_benches`), Prus's and Wyszyński's statues (`prus` 100 tris, `wyszynski` 122;
  spots from their published coordinates, facings guessed), the carriageway's granite setts
  (`ground.gdshader` `kp_setts_at`: a 15-point centreline of Krakowskie Przedmieście, 7 m
  half-width, asphalt fragments only, box test first; no draw call) and Pałac Czapskich as a
  kept skin with a card (`czapski`). Left: Mac look check (QUESTIONS), the Czapski palace's
  own model (its outline is far west of the street line, so the front's direction needs a
  photo), the setts' extent beyond Nowy Świat's top.

## The railway: stations, the cross-city line, trains (F, 2026-11-01)

Plan: docs/design/railway.md. One PR per item, in this order:
- ~~S1 Warszawa Ochota and S2 Warszawa Powiśle as landmarks~~ Done 2026-11-01 (sites `ochota`,
  `powisle`, specs in docs/landmarks/specs/). Left: Mac photo checks (Ochota's stripes, supports and
  stairs; Powiśle's arches, the canopies' length); the stairs from the round pavilion up to the
  platforms; a WARSZAWA OCHOTA sign if the real one has it. The round pavilion's saucer and letters
  were rebuilt from F's photos on 2026-11-06 (jazz nights, below).
- Powiśle jazz nights (F, 2026-11-06, spec `powisle.md` 9), open: the phone's look of the letter
  boxes and the bulbs (draw calls unchanged, triangles up), the jazz loop's level against the radio on
  the phone's speaker, the coloured light washes under the saucer (the game's camera never sees the
  underside, so none were built), the projected line patterns of F's night photo, planters.

## Krakowskie Przedmieście street by street (F, 2026-11-02), pass 1
Built (cloud, Sonnet): eight shopfronts (`Storefronts.KRAKOWSKIE`, 93 venue signs in check_parodies), original names, at the mapped house numbers 20/22, 19, 27, 56, 45, 58/60, 64, 69. Open:
- Mac look check of the eight signs (QUESTIONS); move them to real doors.
- Shop awnings, café gardens (Bristol, Europejski, Czytelnik-style), pavement details: photos 26-29 of
  `refs/krakowskie/` now describe them (low black or wooden barriers, white and dark-red umbrellas, wooden
  decks, planters; white awnings on the west row near Bednarska; granite bollards ~0.8 m every ~4 m along
  the walk edge; black cast-iron lamps every ~25 m): next item. No carriage rank in the photos or the ortho.
- ~~Left from K1-K6: the second Potocki guardhouse, Pałac Czapskich's own model~~ done 2026-11-02 (photo rebuild above).

## Powiśle street by street (F, 2026-11-01)
- Built: Ostrogski Castle + Chopin Institute, the Teresy church, the boulevard Syrenka, Dworzec
  Wodny, Kaskada, DALEJ DALLA GELATO (specs in docs/landmarks/specs/).
- Mac look checks: the gelateria's door on Tamka (a guessed spot, 52.237885 21.027375) and its sign;
  the castle's turret corner and entrance; the church's front, tower and colours; the Syrenka's
  plinth against the flood wall (its corner touches the plinth in the cloud render); what Kaskada
  is; a tree on Kaskada's deck.
- ~~Tamka's and Dobra's tenements~~ DONE 2026-11-02 (street dress: per-house plaster, cornice, string course, shop fronts; spec `dobra_tamka.md`; Mac look check: the real plasters, whether the shops sit where the real ones do, the gaps where houses are missing). Boulevard dressing DONE 2026-11-02 (spec `bulwary.md`: the six bar pavilions, 14 containers and kiosks, 17 deck strips with leżaki; Mac photo check: the pavilions' fronts and roofs, what the Karowa boxes are, the decks' spots; not built: the stepped timber seating down to the water, beach volleyball, containers OSM does not map). Left: Dobra and Tamka kerbs, trees and furniture. (Piano House and Cube House DONE 2026-11-02, specs `piano_house.md`, `cube_house.md`;
  Mac photo check: Piano House's real facade rhythm and whether its top floor is set back; where
  Cube House's real bays or loggias are and its colours. Hortus and Moderna DONE 2026-11-02, specs
  `hortus.md`, `moderna.md`; Mac photo check: Hortus's glass and frame colours, its piers, the
  Drewniana flats' plaster and roof; which part of Moderna is the old tenement and their heights.)
- `check_landmarks` stops in the cloud (no terrain data); run it on the Mac.
- ~~L1~~ done 2026-11-02: track that reads as railway: sleepers, raised rails, ballast shoulders (no new draw calls).
- ~~L2 catenary, L3 the tunnel's mouths~~ Done 2026-11-01 (`map_builder` `_build_catenary`,
  `_build_rail_portals`, in the walls surface: +0 draw calls). Left: portal frames over the station
  fans; the museum sidings by Towarowa get wires too (real ones mostly have none); Mac check that
  trains at the west mouth pass under the Towarowa junction (the cloud's terrain shows them at grade).
- ~~T1 trains~~ Done 2026-11-01 (`trains.gd`, `check_trains.gd` in verify, `--train=X,Z`). Left:
  the parody names on the cars' sides (no text on vehicle meshes yet); a horn and the rumble on
  the bridge (sfx); headlight pools at night; a timetable (today: a new train every 8-30 s after one leaves, 5 at most).
- ~~S3a Warszawa Stadion~~ Done 2026-11-01 (site `stadion_pkp`, spec `stadion_pkp.md`, 1294 tris).
  Left: Mac photo check (the sail's shape and height, the glazing, the canopies' length, the
  mosaic's pattern).
- ~~S3b Warszawa Śródmieście~~ Done 2026-11-01 (site `srodmiescie`, spec `srodmiescie.md`, 476 tris).
  Left: Mac photo check (the glazing, the fascia, the lettering).
- ~~S3c-e the WKD stops~~ Done 2026-11-02 from F's Mac photo gather (`refs/wkd_srodmiescie/`,
  `refs/wkd_ochota/`, reports in `docs/landmarks/photo-reports/`): sites `wkd_srodmiescie` (the two
  concrete "propellers" on a raked wedge pier and a post over the stairs, white parapet boxes, the
  ŚRÓDMIEŚCIE board, an arrows logo; 378 tris) and `wkd_ochota` (the slab on V legs over the island
  platform, replacing OSM's 5 m "retail" box there, blue benches, red-brown edge strips, a stair up
  at the west end; ~540 tris). Left: Mac/phone look (the propellers' twist and pier, the parapet
  boxes' open end, Ochota's stair: the report guessed its spot; the report's ortho reading put the
  slab ~10 m south of OSM's platform, built on OSM's).
- S3c Warszawa Wschodnia built 2026-11-03 from the Mac photo report (site `wschodnia`, spec
  `wschodnia.md`). Left for the Mac or the phone: the hall's height (10.4 m is a guess, no LoD2),
  the fascia's pleat size and depth, the struts' spacing and colours, whether the letters sit on a
  plain board, which platforms have roofs (the five long ones are roofed; the two short ones east
  of them by the suburban hall are bare) and the roofs' length. Gdańska (S3d) is still open: at
  the map's north edge, the ortho shows it being rebuilt.
- ~~L4 Most Średnicowy's look, after a Mac photo check.~~ Built 2026-11-01 (below).
- Photo checks on the Mac for every station model (built from published descriptions).
  **Mac photo check, 2026-11-01** (main 03a26dc; Commons photos in refs/ochota, powisle,
  stadion_station, most_srednicowy, wschodnia, gdanska, each with SOURCES.md):
  - **Ochota:** the glass hall, the deck over the cutting and the black-and-white band read right.
    The roof is wrong. The model is one tilted plane (a wedge), but the real shell is a deep saddle:
    two opposite corners shoot up, the middle sags well below them, and the grey-and-white stripes
    on its underside are the station's signature from the street. Fix: a real hyperbolic
    paraboloid with a clear sag, stripes visible from the game camera; the blue WARSZAWA OCHOTA
    letters on their frame by the entrance. From the default camera the hall hides behind the
    tower next to it (look at it from the south-west).
    **Fixed 2026-11-01:** the saddle (high corners 10.6 m, a 1.1 m sag), stripes on top too, the
    blue letters on their frame. Left: the camera hides it behind the tower.
  - **Powiśle, upper pavilion:** the roof curves the wrong way. The model's roof is a barrel
    (convex, up in the middle); the real "kite" sags (concave, dark fascia, the two ends up),
    over a fully glazed front. The model's grey solid base should be glass with the blue
    WARSZAWA POWIŚLE letters over the doors. The small white tower beside it is in the photos.
    **Fixed 2026-11-01:** the sagging kite with a dark fascia, the glass base, the blue letters.
    Left: the small white tower.
  - **Powiśle, round pavilion:** reads right at night (lit drum, saucer, neon). The real saucer
    overhangs the drum far more (about twice its radius), and the neon is yellow tube letters on
    top of the rim, not red on the disc. Hidden by trees from the low south view.
    **Fixed 2026-11-01:** saucer r 14.6 m, yellow letters standing on the rim's edge, no trees
    under the saucer.
  - **Stadion:** the platform canopies with red-and-white glass walls match the photos well. The
    pavilion reads as a plain white box; the sail and mosaic still to compare.
    **Fixed 2026-11-01:** the hall's roof sweeps up 1.5 m towards the sail, which now stands
    8.2 m at its tips over the raised end, with a glass clerestory under the rising slab and
    bigger STADION letters. Left for the Mac: the sail's real shape and the mosaic against refs.
  - **Most Średnicowy (L4):** the model is a flat deck on many thin paired posts. The real bridge
    is steel arch-truss spans (shallow arches with diagonal webs under the deck) on a few massive
    stone piers, with catenary masts along it. Model those spans and fewer, wider piers.
    **Fixed 2026-11-01:** `map_builder._build_srednicowy`: six granite piers with cutwaters
    (the bake's pier rows at 96-476 m along the bridge) and five 69 m arch-truss spans between
    them (four truss planes, Pratt diagonals, an arched bottom chord 8 m deep over the piers and
    2.4 m at the crown); the thin posts there are skipped, the bank approaches keep theirs.
    Left for the Mac: the spans' count and depth against refs/most_srednicowy, the paint colour.
  - **Map edges:** at Warszawa Wschodnia the yard runs straight into the blue void (looking east
    from the station the world visibly ends a few tracks away), and the platforms show as pale
    strips with odd shadow patches. At Gdańska the north edge reads as a flat brown band ending at
    the sky behind the footbridge. Both need an edge treatment (ground and track running on past
    the edge, or the camera kept back from it); low priority, both stations are mostly off-map.
    **Fixed 2026-11-01:** `scripts/map_edge.gd` rings the whole outline (both city paths): the
    ground runs on 700 m (the river where the edge cuts it) and fades into the background's
    colour (`edge_haze`, set by time_of_day.gd), a tree line 10-70 m out, three loose rows of
    blocks 90-400 m out (windows, some lit at night), and the rails (83 ends) and main roads
    running on past the edge. 100k triangles in 1 km pieces, no shadows: at the edge +1-2 draw
    calls (`--probe --no-map-edge` for the before), nothing in the centre. Left for the Mac: the
    look with the real terrain (the ring takes the ground's height at the nearest outline point),
    the tan-to-scrub ground beside the real edge ground, the blocks' scale.
  - **Bench with trains and wires:** the bench route does not pass the railway (130 draw calls,
    0.61 M triangles, no late frames; trains 0.03 ms of script). `--bench --at=` near Ochota
    gives the same route. A bench spot on the line (with a train in view) is still to add.
    **Fixed 2026-11-01:** two `--probe` spots with a train in view (`--at=X,Z --train=X,Z`):
    Powiśle (171,89) and Most Średnicowy (1148,-720); cloud 158 / 119 draw calls (archive
    "Performance budgets", the godot-mobile-perf skill). Left: the same two on the Mac and phone.

## The river's barges (F, 2026-11-01)

- ~~The bar barges and houseboats were 14 m office blocks standing in the water~~ Done 2026-11-01
  (sites `barka_wieczor`, `barka_biala`, `barka_marina`, `barka_kaskada`, `houseboats`, spec
  docs/landmarks/specs/barki.md, 900-1866 tris each, +0 draw calls).
- Mac photo check: hull colours, where the deckhouse sits and how long, the terraces' furniture,
  which barge is which (the unnamed `boat` north of Wieczór is taken as the white BarKa).
- OSM maps only four of the boulevards' barges: River Cafe, Dworzec Wodny, Dzień i Noc, Kalima,
  Nowa Fala, WIR and the others are missing; add them as map points (a bake) or by hand.
- ~~The unnamed 14 m "building" in Port Czerniakowski's water~~ Done 2026-11-02: it is the marina's club house (site `marina`, spec przystan.md) with sailboats; Marinka is a two-deck white barge. Mac photo check: club house colours and storeys, the real berth count, whether the finger piers hold the boats the way the model has them (OSM maps the piers only as footpaths).
- The marina's boats float with no wake or reflection; masts have no lights at night (only the pier lamps glow).
- The 12 `boathouse` sheds by the harbours (Port Czerniakowski, the Praga side) and the "yes"
  building at the harbour's mouth still stand 14 m tall (OSM gives no height): a sensible height
  in the bake, or small models.
- The barges' festoons and stall hatches glow (M_LAMP) but cast no light on the water; a warm
  reflection under each lit barge at night would sell it.

## The Mac App Store version and gamepads (F, 2026-11-01)

Lane file: [docs/store/mac-and-gamepad.md](store/mac-and-gamepad.md). F wants the game ready for
the Mac and for gamepads, and the Mac in the beta plan. Built: gamepad support (`gamepad.gd`,
`check_gamepad.gd`): Xbox / PlayStation / MFi pads drive, fly, press the mission card, open
Settings (focus ring, LB / RB tabs) and the full map; the title takes A / Y / B; the touch pedals
hide while the pad is used and come back on a touch. Left:
- Gamepad on real pads (iPhone and Mac): the button indices are checked on synthetic events only.
- ~~Gamepad gaps: no per-family glyphs (A / cross) in the hints; no rumble.~~ Done (2026-11-02):
  `Gamepad.fmt` names the buttons per pad family, haptics.gd rumbles the pad while it is in use.
  Left: the rumble's strength and the Nintendo button order on a real pad (beta).
- **The context button by pad (2026-11-03).** Found with G14: the top row's context button
  (KASETA, START KURS, POMOC DROGOWA, PODWÓZKA's request, WEZWANIE) had no pad button, so a pad
  player could not play the first ten minutes' tape beat at the boulevards, start a ride by button
  or take the stuck offer's tow. Now A presses it when no card is on screen (main.gd `_primary`: a
  ride, job, trend or rescue card first, then the context button, then the rescue line's own A),
  the button reads "A · KASETA" while the pad is in use (the family's face: × on PlayStation,
  B on Nintendo) and the stuck offer's and the rescue call's toasts name it (`check_gamepad` P15).
  Left: on a real pad, whether A for both cards and the context button ever surprises (a card and
  the button up at once: the card wins). (The volume bars, the
  notebook page, the garage card and the full map's stick pan / zoom / A teleport were done
  2026-11-01, check_gamepad P9-P12; the map's pad hint is one line in the player's language
  since the language work, 2026-11-02.)
- Mac App Store version (post-v1.0 by default, QUESTIONS): macOS export preset, sandbox
  entitlements and signing, keyboard and mouse controls (a keys card, click-to-point, `--no-touch`
  by default), window and resolution settings, Mac store screenshots (2880 × 1800), the Mac's
  bench (Apple Silicon and Intel).
- Beta plan for the Mac: macOS TestFlight builds, the export and signing, a universal purchase on
  the existing record (recommended) or a separate Mac record, the .pkg upload through Transporter
  or Xcode (notarization only for outside the store); gamepad testing in every round.

## Accessibility follow-ups (2026-11-01)

Built: Settings → DOSTĘP (`game/scripts/access.gd`, kept in `[access]` of settings.cfg): larger HUD
text (x1.25, read when the HUD is built: shows after a restart), calm (patrol-car lights steady, no
VHS pulse), colour-safe markers (drop-off beacon blue, patrol lights white/blue), vibration on/off
(every buzz goes through `Access.buzz`), stop assist on/off. Left:
- ~~Left-handed control layout~~ Done (2026-11-01): Settings → DOSTĘP → "Dla leworęcznych"
  (`access.gd left_handed`, `hud.gd set_left_handed`, at once, no restart; flag `--left-handed`):
  BRAKE, GAS, the horn and the helicopter's pads bottom left, the stick's side (the right 60 %)
  and Classic's strip on the right, the credit line bottom right; `check_hud` runs a left-handed
  pass (10 states x 6 screens). Left: the feel on the phone; in this layout the bottom card can
  sit lower (nothing on the right pushes it up), so the radio ticker waits for room more often.
- Text size that follows the phone's own setting (the toggle itself is live since 2026-11-01).
  **Two parts found 2026-11-02.** (1) Reading iOS Dynamic Type / Android font scale needs a native
  call; Godot 4.7 has no API for it, so it waits for a small iOS/Android plugin (Mac work).
  (2) ~~The HUD at x1.25 doesn't fit the small phones~~ Done (2026-11-02): a panel that must show
  (status, cards, banner) and finds no room at the larger text steps its own text down 0.05 at a
  time, never below normal (hud.gd `_fit_text`); the ride's side card also keeps off the car's
  spot. `check_hud`'s large-text pass is a gate and lists each step-down (11 of 84 states: the
  rescue status x1.10-1.20, the race banner x1.05-1.20, the ride cards x1.00-1.20 on 667x375).
  Left: the look on the phone at x1.25.
  Also fixed: `apply_text_scale` errored on a freed label after a setting change.
- Subtitles: nothing is voiced yet; revisit when speech or radio talk with words lands.
- ~~Crash sparks buzz through `Access.buzz`~~ Done (2026-11-01: crash_fx.gd shakes nothing; the
  car's knock goes through haptics.gd, which keeps `Access.vibration`). ~~Colour-safe still to cover the HUD's green badges and the red fail colour.~~ Done
  (2026-11-01): `Access.tint` turns the success green blue and the fail red a lighter vermilion in
  the cards, the status panel and its 1ST badge, banners, notes, the ticker, the target arrow, the
  minimap target and the speech bubbles (`check_settings` "colour-safe tint" covers every script's
  green and red constant). ~~Left: 3D markers other than the drop-off beacon (race and rescue
  rings)~~ Done (2026-11-03, `beacon.gd`): with colour-safe on, the ring's shape is the second cue,
  so the race and rescue rings no longer differ by hue alone: the rescue pickup (someone waiting) is
  16 dashes, the race finish and checkpoints a chequer of ~1.2 m blocks in the race colour and white,
  the drop-off a full ring tinted blue; a placed beacon re-draws when the setting changes mid-call
  (the drop-off's colour was fixed at load before). `check_settings` "colour-safe beacons" (fails
  with the shapes off). Not done: the side jobs' rings (kebab, słoiki, rides, roundup, Mlask) stay
  full rings; they differ from each other by colour only but never show two at once. Left: a look
  on the phone (does the chequer read at the iso camera's scale, is a dash gap clear on dark asphalt).

## Ground vertex compression, to re-apply on the Mac (stale PR #53 triage, 2026-11-01)
- PR #53 (commit b343d60, branch `claude/project-thread-ldyr9u`) stores the ground's meshes with
  `Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES` (`chunked_surface.gd` `meshes(flags)`, `map_builder.gd`
  `_add_mesh(..., flags)` for the flat layer; `bake_city.gd` skips empty sectors' proxies when
  counting). On the Mac then: sectors 95.7 -> 75.0 MB, vertex buffers 147 -> 120 MB, frame time the
  same. The branch has an unrelated history (from before the repo was rewritten), so it cannot be
  merged; the diff is 3 small hunks and no longer applies cleanly to `map_builder.gd`. Left: re-apply
  by hand on a Mac session (full definition of done: re-bake, `verify.sh`, shots and bench), then
  close #53. Buildings stay uncompressed (windows come from UVs in metres).

## Rondo de Gaulle'a, Dom Partii and the food-hype lore (F, 2026-11-01)

Spec: `docs/design/gaulle-and-food-hype.md` (F's three photos; parody names in its section 2, the
real ones added to `brand_denylist.json`). One PR each:
- [x] G1 the de Gaulle statue by the roundabout (site `gaulle`: curved steps, cobbled rings, the
      granite cone, the dark plinth, the marching bronze general, a card), 2026-11-01.
- [x] G2 part 1: Dom Partii as a white stone skin with a card, ROBUR over the north-west corner,
      the courtyard's paving with its key border and the long fountain with five jets, 2026-11-01.
- [x] G2 part 2: the bars NEWTWICE, ZAMĘT and PRZEGRYWKI as neons (`Storefronts.HYPE`), 2026-11-01.
- [x] G3 HOTEL PIURE's door neon, LORETKA in pink on its roof (landmarks site `loretka`), the
      evening line for the lift up to the date bar (crowds.gd, 10-16 people 18:00-01:00, tag
      `timber`), TIMBER on a billboard and a column poster, 10 date lines, radio lines, 2026-11-01.
- [x] G4 KOSZTA COFFEE ×3, GREEN CAFFE NERWO ×2 (one on the mapped pavilion), KUKŁA ×2 with its
      all-day queue (8-30, tag `kolejka`), 8 queue lines, radio lines, a KUKŁA poster, 2026-11-01.
- [x] G5 Mrożulo: his cream van at one of four spots by weekday (11-21), the "Mlask" job in
      `trend_job.gd` (`--trend-job=6`): fetch from a new place, bring it warm in 5 min, his review
      card with a MLASK grade, the sticker back in 4 min, the place's queue at its longest for the
      day (crowds.gd `mrozulo_boost`); 9 review lines, 4 owner lines, 6 fan lines, MROŻULO PIZZA
      sold out at Frogs (3 till lines, a poster), radio news; rules in `check_city_life.gd`, 2026-11-01.
- [x] F's follow-up: the rooftop bar is LORETKA (was LUŹNO) with its summer terrace on the roof
      (deck, planters, eight tables with poufs, pink parasols, the bar, string lights; landmarks
      `loretka_plan`), couples on its poufs May-September on dry evenings (crowds.gd `terrace`,
      10-16); the board-game bar is PRZEGRYWKI (Zagrywki parody, was PIONEK); WACZEK ×5, the burger
      chain with an upside-down golden W, at the real chain's central restaurants, 2026-11-01.
- [x] The notebook card "Kolejki" (place `kolejki`, chapter Kolejka po trend, at KUKŁA on Nowy Świat), 2026-11-02.
- [x] Left from G3-G5, done 2026-11-02: Podwózka `timber` passengers (evenings 18-01, 20 % of
      normal rides, 3 request and 4 ride lines; `rides.gd`), five fans behind Mrożulo's van with
      `viral` "mrozulo" bubbles, and the egg `easter_mlask` (the car stopped within 9 m of the van
      for 3 s while he is out; `trend_job.gd`, 48 cards now).
- [x] The van's MROŻULO TV lettering (pixel font, dark, both flanks under the pink band; a second
      surface, +424 tris, check budget 800), 2026-11-02.
- [ ] Still left: Mac look check of the lettering's size and the fans' spot behind the van
      (the side of the kerb), the egg's wording; phone checks of every sign's size, the queues and
      the job's legs.
- [ ] Mac checks: the statue's spot and facing against the orthophoto; Dom Partii's height and the
      skin on the LoD2 model; KUKŁA/KOSZTA/NERWO spots on the real streets.
- [x] `Tinder` in a run-club line replaced by TIMBER (it would fail the new denylist entry).

## Zagłębie Kebabowe and Kino Femina (F, 2026-11-02)

Spec: `docs/design/zaglebie-kebabowe.md`. Built: five parody kebab shops by Kino Femina (stands,
neon fascias, twists), the craft kebab's choice card, Szlak Szpili, the welcome lore. Left:
- Mac photo check: Femina's real front (colour, marquee) and the shops' real frontage; a marquee
  or poster board over Femina's door would make it read as a cinema from the car.
- ~~A queue outside ZAKWAS I ROŻEN~~ Done 2026-11-02 (`crowds.gd` `zakwas_queue`: 12:00-24:00, 8 in line, 14-18 on evenings, tag `zakwas` with four bubble lines; the phone's look is open). (KEBAB FM lines about the basin done 2026-11-02.)
- The phone: feel of the craft kebab's 6 s wait, the five stands' spacing (23 m apart).

## Trends 2025–26 (F, 2026-11-01)

Spec and sources: `docs/design/trends-2025-26.md`. Built: eight parody trend spots (`Storefronts.TRENDY`).
- [ ] Wykop/X/TikTok skim (cloud could not fetch them); adjust the trend list.
- [ ] Phone check of the PISTACJA queue (Friday 16:00-18:30 drop, 36 people) and the "Limitka" job (`--trend-job=4`): line on the footway, 5 s wait, 5 min delivery. Built 2026-11-01.
- [ ] Padel thread (F, 2026-11-01; docs/design/padel.md): built: PADELNIA queue, 11 lines (Trener Dominik, Pani Basia, Prezes z Mokotowa speak in the queue), a notebook place, the "Czwarty" job (`--trend-job=5`). DESKA (2026-11-02, parody of WTS DeSki): built on Zaruskiego (a closed tennis hall over four mapped pitches, one outdoor glass padel court with 4 players, floodlights, DESKA neon, notebook place `deski`, 3 padel lines, "Czwarty" as a friend's phone call that sends you by car or helicopter to its gate, `--trend-job=7`); phone check of the look and of the gate offer, Mac photo check of the court colours and the clubhouse, the call rings after 150 s of play then every 20 min, 8:00-22:00 (feel open); the lane graph has no road at the gate. Still to build: more notebook lore, the roof court "Ściana Płaczu", the Pro Shop. Phone check of the queue and the job.
- [ ] E-scooter 12 km/h zones: four discs built (Złota, Zgody, Bracka, Plac Centralny; `scooter_zones.gd`, centres *guess*, toast on entry, car not capped). Still open: check the centres against the real streets, scooter riders that slow down, a zone pill.
- [x] Lines about matcha, padel, natural wine, queue, scooter rules: 8 column posters and 5 signs in dialogue.json (PL + EN).
- [ ] Phone check: do the new column posters read (rows ≤ 8 letters)? Not run, no Godot in the cloud.
- [ ] Phone check: sign sizes and placement of the eight new spots (not run: no Godot in the cloud).

## Audit: what is verified beyond the landmarks (2026-11-01)

F asked whether the roads, the street details and the start of the game are really checked, or
whether only the landmarks are left. They are not: most of the game is **built and passes its
headless checks**, but much of it was **never seen on the phone or compared with the real city**,
and two finished pieces of the opening never merged. Three kinds of status below: *verified* (a
check or F's eyes confirmed it), *built, not verified* (works in a check, never played on the
phone or compared with photos), *gap* (not built). Items in the order to take them; the lane and
model are the coordinator's suggestion. Older sections below keep their detail; this list points
to them instead of repeating it.

**State of the evidence.** The last real iPhone numbers are from 2026-10-29 (loop G0+, iPhone 11),
before the map north, ~45 landmark sites, MW-2..MW-6, the night buses, the ladder and the guide.
GitHub CI ran only the map-free checks until 2026-11-02 (now a `map` job, top section); the cloud's map data was stale, so
cloud threads have run the roads, drape, drive and landmarks checks against a failing baseline and
compared with main instead of passing them (memory note, PRs #117 #125). No full
`tools/verify.sh` on the Mac is recorded since the landmark lane began (~195 commits on main since
2026-10-31).

### P0: the start of the game (gameplay, Opus)
- **Merge the unmerged opening.** PR #115 (start facing the Świętokrzyska stand, a 226 m first
  order instead of 926 m with a U-turn, the first roof cassette on BUW) and PR #121 (the 7.5 s
  opening flyover over the Palace, stacked on #115) were finished on 2026-10-31 and are still
  open. Main today starts facing south with the stand behind the car. Rebase both on main, re-run
  their checks (`first10`, `first10-run`, `opening`, `cassettes`, `save`, `hud`), merge #115 then
  #121. Built, not verified on the phone.
- **The first scene's open items** (design/first-scene.md items 4-5; BACKLOG "High priority: the
  first scene"): the pavilions and Pasaż Wiecha behind the Eastern Wall stores were built
  2026-11-02 from the Mac photo report (site `wiecha`, first_scene.gd PASAZ; the phone look and
  the open points are in QUESTIONS "Pasaż Wiecha"). The park strip's benches and lamps and the lowered kerbs were built 2026-11-02. The paving, the crossings' tactile pads and the
  tram platforms' edges were built 2026-11-02 (first-scene.md "Items 4 and 5 as built"); items 6-7
  (pedestrians and sound at the start) built 2026-11-02; both phone checks parked.

### P0: the whole build checked again (map and performance, Opus; needs the Mac)
- **A full `tools/verify.sh` and `tools/verify.sh --ios` on the Mac on today's main**, both city
  paths (runtime and `--prebuilt`), plus `python3 -I tools/check_roads.py` and
  `python3 -I tools/check_map_data.py`. Every landmark PR since 2026-10-31 changed geometry next to
  roads (zones, plinths, forecourts) and only `check_mesh_quality` ran on them. **Done on the Mac
  2026-11-01** (main 00a90fb): the first run had 5 FAILs, all fixed in one PR: the prebuilt bake
  refused (the slabs and tower behind the stores and Hotel Metropol's roof sign had no
  SITE_AREAS / SITE_NAMES line), the sectors' Old Town buildings differed from the whole map's
  (dormers seeded by triangle index), the Copernicus Centre's collision ring reached the buses in
  Tunel Wisłostrady, check_landmarks failed PZU (hidden behind Q22 from the camera), BUW (its
  tallest cell a neighbour's roof) and Złote Tarasy (flown over at 45 m), and five specs (anna,
  gwardii, wizytki, wszystkich, zamek) missed sections. After the fix 69 of 70 steps pass (places
  WARN as before; roads, map data, first10, first10-run, endcard, opening, cassettes, parodies,
  both city paths PASS; `--ios` export and unsigned build PASS). Left: the next item.
  The same day on the Mac: bench (M4 Pro, pinned at 120 fps) 130 draw calls, 0.61 M triangles,
  no late frames of 600; the opening flyover renders (over the Palace, down to the car, Halina's
  first line); the ten roof cassettes on the real map all have a spot, each roof within 0.81 m
  over 6 m, and the helicopter lands on every one at the spot's height (Teatr Wielki's is the fly
  tower, 47 m up). Street details rendered by day at Nowy Świat and the boulevards (stalls, cafés,
  planters read at the default zoom); Tamka and Praga need closer framing. The trend signs (#157)
  did not show at their projected points from 55 m: their wall spots still need a framed night
  shot. PR #183's head passes the look pass on the Mac (0 missing, no proxies in the view).
  check_streaming's pixels failed on main e0e02b8 (spots 3-4, 2.2-4.4 %, differing between runs):
  the speech bubbles' lines, not the city; the pixel runs now pass `--nohud` (0.24 % on 03a26dc).
  PR #194 (roof dress) on the Mac: draw calls 130 before and after, triangles 0.61 to 0.62 M,
  2 frames of 600 at 17.7-25 ms (0 before); at phone size (2532x1170) the tile courses show on
  the Old Town's pitched roofs up close and fade out at the default zoom, flat roofs get faint
  seams and lighter parapet rims; no shimmer seen in stills (motion is for the phone).
- ~~**Map checks in CI**~~ **Done (2026-11-02)**: the map pack as a release asset and the `map` job
  (section "Map checks in GitHub CI" at the top); waits on F publishing `map-pack-1`.

### P0: the phone pass (performance, Opus; needs F's yes for a device run)
- **Bench on the iPhone 11 and the 16 Pro Max on today's main**: default view, zoomed out, the
  helicopter over the centre, day and night, against budget P (DEMO.md 7): frame time, draw calls,
  memory line, plus a `--stream-soak`. The parked phone questions ride along: the sector-load
  hitch, static memory before the beta, the compressed map textures (QUESTIONS 2026-10-30). Not
  verified since 2026-10-29.
- **A timed fresh-save playthrough by F** (after #115/#121 merge): the first 10 minutes beat by
  beat (DEMO 6.2), then the main line toward the final (~1 h is an estimate from the pay tables).
  It answers the parked feel questions at once: Halina's rubber band, the ghost finger's place,
  the stop assist's glide-in, the cassette's size from the helicopter, the flyover's length, the
  Rotunda's teeth and the store signs' size. Not verified.

### P1: roads against real Warsaw (map, Opus)
- ~~**Map review C, the streets of the demo box.**~~ Done 2026-11-02 (Opus; "From map review C"): the
  game's roads over the GUGiK orthophoto in every district of the box and map north (district sheets
  and a width measure across every street), and the worst mismatch fixed in the bake: one-lane one-way
  streets were 3 m strips (505 ways, 31 km: Mokotowska, Wilcza, Hoża, Żurawia, Noakowskiego...) and are
  now the street's default width, 5.5 m (6.5 m tertiary), split legs round an island kept at one lane;
  two-lane two-way streets 6 → 7 m (423 ways, F's yes).
- Already listed and still open: lines inside junctions not checked against photos ("From map
  review B"; the dark Jerozolimskie / Nowy Świat at night fixed 2026-11-02); the loop 3e structures (Łazienkowski's
  Praga end R8, the rail cutting, deck 4, the Karowa footbridge's Praga end; Rozdroże's tubes and
  Nowy Zjazd's wall done); ~~Most Łazienkowski cut by the east edge~~ settled 2026-11-02 (the river
  crossing is whole since the box reached 21.056). Both lines wait on the Mac: the junction lines
  need the GUGiK orthophoto and the structures a re-bake from data/raw (QUESTIONS, 2026-11-02).

### P1: street details beyond the start (content/map, Sonnet with an Opus spec)
- **Landed** (2026-11-01, thread "Add street details along the main route", spec
  docs/design/street-details.md): `tools/bake_street_details.py` places ~370 kiosks (PRASA), flower
  stalls (KWIATY), café sets, planters, ad columns, bollards, two ice-cream carts (LODY) and stop
  posts / a ticket machine (BILETY) on the pavements of eight corridors (Marszałkowska,
  Jerozolimskie, Nowy Świat, Tamka and Karowa, the boulevards, Prosta, Praga, Poniatowskiego) into
  `game/data/street_details.json`; `street_details.gd` builds one shadowless mesh per 512 m cell on
  both city paths. Checks: `streetdetails` (placement against the map) and `streetmesh`.
  **Left:** not seen in a render yet (no GPU/terrain in the cloud): shots at Nowy Świat, Tamka, the
  boulevards and Targowa on the Mac; the bench and the phone look (size, clutter, night); the
  corridor waypoints are the spec's rough lines (Praga gets few props); the camera rule (props on
  east-side pavements are hidden) is not applied; stop kits are only at the map's shelters.
- Knocking light furniture about like the cones; parked cars and shelters solid ("From the
  driving-feel loop"). Gap, low.

### P1: driving and collisions (gameplay, Opus)
- Built and checked headless (`check_steering`, `check_drive` 98 routes, `check_stop_assist`,
  `check_water`), tuned on the flat test ground; the corner slip, the shove and the stop assist were
  never felt on the phone ("From the driving-feel loop", QUESTIONS 2026-10-31). Comes with F's
  playthrough above.
- ~~The NaN car is unexplained~~ (2026-11-02: not reproduced, guarded and checked by `check_finite`; "From loop 3h slice 4").
- On the phone: Fotka by a wall for a minute leaves the car where it stood, and JAZDA's POMOC
  DROGOWA tows it onto the road (fixed and checked headless 2026-11-01; QUESTIONS). Every hold of
  the car (title, Fotka, flying, police) now parks it, so none reverses at 7 m/s any more.

### P1: main line and side quests (game-designer, Opus for the review)
- Every activity has a headless check (rides, side jobs, couriers, ladder, syrenki, eggs, garage,
  police, main line, end card); none has been played end to end by a person on the phone, and the
  pay tables are first guesses (BACKLOG-TRIAGE "Decisions"). The guide's lines, Halina's lines and
  the end card are unreviewed ("From loop 3h slice 4"); the end card's "10 jobs" definition and the
  trap's koguty line are open. A designer pass over all player-facing text and pay, then F's run.
- The DEMO 6.3 counts are done (2026-11-01): 10 roof cassettes, 72 landmark cards, the second
  słoiki station (Dworzec Gdański, `--sloik --sloik-station=1`) and the Łazienki peacock rescue. Not
  seen in a run yet (the cloud has no city): the Gdański ring and person on the kerb, the
  Muranów drive, and the peacock's roof (Zamek Ujazdowski, else the nearest roof); the peacock call
  needs the player within 2.6 km of it, so it never shows from the north; Łazienki itself is off the map.
  pay tables were first guesses. **Designer pass done (2026-11-01, docs/design/pay-tables.md)**: a
  desk model of złoty and respect a minute per activity; a rematch now gives +20 respect (was +100,
  a shortcut past every gate), słoiki pay 40 + 30 a jar (was 50 + 35); the guide's, Halina's, the
  end card's and the final's words made player-neutral; "10 jobs" kept as every paid job kind; the
  koguty line was already in the first contact. Left: F's timed run on the phone (the hour, the
  pay). The police's "pan" lines outside the first contact are player-neutral now (2026-11-01).
- The DEMO 6.3 counts left: the second słoiki station (jobs.gd has one) and the Łazienki peacock
  rescue (none yet; the Old Town tourist is a "fainted" street rescue in missions.gd). The 10 roof
  cassettes and the landmark cards (72 vs ~25) are done (2026-11-01).

### P2: UI
- The HUD was sized on 2026-10-28; since then the ≡ map button, the goal star, district cards,
  the ladder and the end card arrived. Re-run `check_hud` sizes and shots at 375, 390 and 440 pt
  wide. Not verified.
- The full map: street names close in, icons judged on the phone ("Top priority: a game-like full
  map"). Gap / not verified.

### P2: store release (store lane, Sonnet; F's forms)
- **Done (2026-11-01):** the release build reads no command-line flags (`release.gd`: an export with
  the release template, the TestFlight archive or the Play AAB, ignores `--at=`, `--shots=`,
  `--bench` and the rest; the debug export and the checks keep them), and Settings → DŹWIĘK →
  LICENCJE shows the credits and licences (`credits.gd`: OpenStreetMap ODbL, GUGiK, the trees'
  CC BY 4.0, Godot and the four shipped add-ons, every radio track from radio.json).
  `check_credits` (verify and CI) keeps the page, the add-on folders, radio.json and CREDITS.md in
  step. Left: the page seen on the phone (scrolling with a finger at 375 pt).
- TestFlight is paused until F fills App Information in App Store Connect; no build is uploaded.
  iPad kept or dropped; the support page needs a deploy; the store screenshots predate the demo
  map, the new HUD and the opening and need a re-shoot after #115/#121 ("From the store listings").
  Waiting on F, then the Mac.

## Quest pickups and drop-offs too hard to stop on (the user, 2026-10-31)
- **Landed** (thread "Make quest pickup and dropoff easier"): stop_assist.gd, one shared 9 m
  ring and ~16 km/h "stopped" for every car stop zone, and car.gd's stop assist (brakes into the
  ring when heading in, holds for the quest's hold, never touches a car passing by;
  check_stop_assist.gd). Left: F to feel it on the phone (is the glide-in too firm or too
  soft: StopAssist.DECEL 9 m/s²; does a 9 m ring reach across the road at narrow doors).

## Top priority: a game-like full map with teleport (the user, 2026-10-31)
- **Landed** (thread "Make the map fun and game-like"): the full map in its own poster style
  (map_art.gd), 25 landmark pins (map_icons.gd), hold 0.6 s to teleport, the cards behind ≡.
  Left: street names along the main roads close in; F to judge the icons and colours on the
  phone (maybe hand-drawn or PixelLab icon art later); the first open on an older phone (the
  art is made on a worker thread at start, ~0.1-0.7 s on a computer).

## High priority: the main line and quest markers (the user, 2026-10-31)
- **Landed** (thread "Shape main line and quest markers", docs/design/main-line.md): the main line
  in three chapters (the guide, the ladder, the final) as `main_line.gd`; its marker a gold star on
  the minimap (pinned to the rim at any distance) and the full map (a goal card under the title, a
  legend); side quests keep a ringed dot in their colour and the start squares (now on the full map
  too); the ladder's gates lowered to 0/100/220/340/480/640/850 for a ~1 h main line.
  Left: a timed fresh-save run on the phone (the hour is an estimate). ~~The edge arrow on the
  screen could carry the star too; maybe a short goal line on the driving screen~~ Done
  (2026-11-03, `main_nudge.gd`): when the step changes (the guide ends, a rung is beaten, the
  final opens) a goal line toast "★ Znajdź i mrugnij: …" 4 s later, and for 25 s the screen-edge
  arrow in the main line's gold ("★ 2489 m") to the next rival or, at night, the final's start;
  it comes back for 25 s after every 150 s of free driving. Only while nothing else is on (job,
  race, rescue, ride, quest pin, guide hint); held on the title, in camera moments and in Spacer;
  hidden while flying (the races are car quests). Found on the way and fixed: the screen-edge
  arrow (any target's) could sit under the minimap, the wallet or the pedals; it now slides along
  the edge clear of them (`check_hud`, fails on the old code at 3 screen sizes). Left: the phone
  feel (is 150 s right, is the toast enough of a goal line).

## High priority: landmark and skyscraper models (the user, 2026-10-30)
- **Złota 44 rebuilt from F's photos** (2026-11-02, spec `docs/landmarks/specs/zlota44.md`):
  the old blue box with diagonal "exoskeleton" lines and its top high at the wrong (north) end is
  gone; the wing, the tip at the south-east, the crown box, the white staggered cladding and the
  podium garden are built. Left: the Mac photo check (QUESTIONS), and a look at the tower's far
  skyline stand-in (not checked in this pass).
- **The user dislikes how several models look** (2026-10-30): Złote Tarasy, Złota 44 and the
  other skyscrapers (Varso, Pałac Kultury, Warsaw Spire, Q22), Muzeum Narodowe (and Stadion
  Narodowy), the bus stops, and other weak models. Goal: keep the game's own pixel and
  low-poly style, but with colours, proportions and silhouettes that clearly read as the real
  buildings. Before/after shots at phone size. Lane "landmarks/models" (docs/QUESTIONS.md).
  **First pass landed (2026-10-30, ROADMAP "landmark models")**: 18 towers in their own
  colours, skins and crowns (Złota 44's white exoskeleton and sloped top, Warsaw Spire's
  diamonds, Rondo 1's open crown, Q22 at its real 155 m, Chałubińskiego 8's white ribs and the
  rest), each with an info card; Złote Tarasy's glass golden; Muzeum Narodowe in its pale stone
  with tall windows and a card; new bus shelters (glass roof, poster box lit at night, the
  blue D-15 sign). The Palace and the stadium were already detailed models and keep their look.
  **Second pass landed (2026-10-30)**: 9 more (Grzybowska 63, Jana Pawła II 21, Marszałkowska
  94/98: the hotels, now under parody names Chilton, Westynka and Nowotel; Central Tower, Ilmet, the Platinum Towers, Łucka City,
  Widok Towers): 27 towers in all. **Third pass (2026-10-30)**: 15 low-rise landmarks
  (Teatr Wielki, Zamek, Barbakan, Kopernik, BUW, churches, Sejm, Zachęta…) in their real colours.
  **Street furniture**: historic lanterns on the Royal Route and in the Old Town (2026-10-30). MDM's blocks and
  Plac Konstytucji's candelabras (2026-10-30).
  **Muzeum Narodowe and Plac Piłsudskiego (2026-10-31, the museum and Plac loop)**: ~~the museum
  only recoloured~~ is a real model (straightened outline, tall window bays, the raised entrance
  block with its portal, a parapet, a tank and a gun in the east courtyard); Hotel Europejski
  (rusticated base, cornice, hipped roof, central bays) and the Tomb of the Unknown Soldier
  (three arches, the eternal flame) are built, each with a card (`check_sites`). ~~Left there:
  the Metropolitan's fin skin, Sofitel Victoria and Królewska LoD2 only, the museum at 14.2 m~~
  **Plac Piłsudskiego part 2 (2026-10-31)**: the Metropolitan is a model (glass behind real
  granite fins, the round courtyard and fountain, three passages, the set-back seventh storey);
  the hotel on Królewska is **Hotel Wiktoria** (a slab of ribbon windows on a dark podium, a
  card under the parody name); the Królewska edge (Dom bez Kantów, the Departament, the unnamed
  south-east block) in its own stone; the museum's wings 18.5 m and entrance block 25 m.
  **Left**: Hotel Wiktoria's heights (slab 30 m, podium 8 m, 18 m deep), the museum's ~~and
  Europejski's~~ are estimates to set from photos (Europejski rebuilt from F's photos 2026-11-03); the Królewska-edge colours are guesses; the
  unnamed south-east block has no card (its name isn't mapped); the Metropolitan's passages are
  dark panels, not open; the army museum's yard placement is a guess (east courtyard).
  Next candidates: tram stop platforms, kiosks (not in the baked data yet), Warsaw's green bins. **Left**: PZU Tower and JM Tower are towers since 2026-11-01 (first pass, colours to check on a Mac photo), and any model the user names next (docs/QUESTIONS.md).
  **Landmarks lane, hand-over (2026-10-31)**: since the first passes the lane also landed: the Rondo
  Daszyńskiego towers (The Warsaw HUB found by a point, `_tallest_at`; sloped crowns), the Old
  Town's and New Town's tenements split into their OSM houses' colours and tile roofs
  (`map_builder._tenement_facades`), brick Gothic for the Cathedral and the Barbican
  (`M_GOTHIC`), Sigismund's Column, map north (Arkadka with its lit sign, the Forest tower, the
  flag on Rondo Radosława) and Most Świętokrzyski's pylon and stays. **Left, for fresh threads** (the Barbican DONE 2026-11-02: model, spec barbakan.md, Mac photo check parked: wall height, turret spots, gate):
  St Anne's classical facade (DONE 2026-11-01: `_build_anna`, spec anna.md, portico, wings and the bell tower's trim, Mac photo check parked: column count, door, tower cap; was: a portico of four columns and a pediment on its west face; it is
  a kept skin today, outline in `centrum.json` landmarks "Kościół pw. Świętej Anny", centre
  (−658, −1350), the free-standing bell tower is a separate building to its north-east), the other
  churches (Holy Cross DONE 2026-11-01: front and towers, spec krzyz.md, Mac photo check parked; All Saints (DONE 2026-11-01: front and twin towers on the kept skin, spec wszystkich.md, 788 tris, heights estimated, Mac photo check parked: tower height and dome shape, portal count), St Alexander's rotunda (DONE 2026-11-01: model, spec aleksander.md, Mac photo check parked: which end has the portico, column count, bell towers), the Visitationists DONE 2026-11-01: facade, stepped wing and turret on the kept skin, spec wizytki.md, 566 tris, heights estimated, Mac photo check parked: gable shape, towers or none, turret) and the Palace
  on the Isle's neighbours, the Sejm's hall colonnade (DONE 2026-11-01: curved colonnade, entablature and cornice on the kept skin, spec sejm.md, Mac photo check parked: column count, eave height, entrance, wings), Hala Mirowska (DONE 2026-11-01: model from the mapped parts, spec mirowska.md, Mac photo check parked: the real brick colour, the front's door count, whether the lantern shows; the Cathedral's front DONE 2026-11-01 (`_build_archikatedra`, spec archikatedra.md, Mac photo check parked: gable height and steps, window shape, whether a tower stands at the front; the Barbican is still open); Hala Gwardii DONE 2026-11-01: symmetric twin, bays measured from its outline, spec gwardii.md, 1212 tris, Mac photo check parked: real brick colour, door count on the long sides, lantern glow), Staszic's facade (DONE 2026-11-01: portico, cornice and Copernicus's statue on the kept skin, spec staszic.md, Mac photo check parked: portico centre, column and door count, real eave height; Zachęta, Holy Trinity
  on the Isle's neighbours, the Ministry of Finance (DONE 2026-11-01: model, spec mf.md, 1555 tris, from the outline and public facts, Mac photo check parked: real colour, pavilions and entrance rise, bay rhythm), the Sejm's hall colonnade (DONE 2026-11-01: curved colonnade, entablature and cornice on the kept skin, spec sejm.md, Mac photo check parked: column count, eave height, entrance, wings), Hala Mirowska (DONE 2026-11-01: model from the mapped parts, spec mirowska.md, Mac photo check parked: the real brick colour, the front's door count, whether the lantern shows; Hala Gwardii DONE 2026-11-01: symmetric twin, bays measured from its outline, spec gwardii.md, 1212 tris, Mac photo check parked: real brick colour, door count on the long sides, lantern glow), Staszic's facade (DONE 2026-11-01: portico, cornice and Copernicus's statue on the kept skin, spec staszic.md, Mac photo check parked: portico centre, column and door count, real eave height; Zachęta, Holy Trinity
  and the Presidential Palace became models on 2026-10-31, specs in docs/landmarks/specs/) (PZU/JM Tower done 2026-11-01). (The Old Town's dormers and chimneys, 2026-11-01: `old_town_roofs.gd`, one per big roof slope, no new draw call; a Mac look on the real roofs is still open. The market square's east side got stepped attic gables, 2026-11-01: `OldTownRoofs.gable`, one per ~8 m house bay on walls facing the square, skipped where LoD2 has its own gable end; no new draw call; Mac look open: stage proportions, the volute scrolls a real gable has, and whether the dormers show, since the first dress arrays were copies and are now written back.) How the
  lane works: `landmarks.gd` sites (`TOWERS`, `SKINS`, fixed-position circle zones like
  `_find_zygmunt`), each needs a card in `INFO` and `check_landmarks`; a site found in
  `data["buildings"]` also needs its box in `bake_sectors.py` `SITE_AREAS`; after a change
  rebuild the prebuilt sectors with `bake_city.gd` (a renderer, never `--headless`); render
  before/after with the Mobile renderer on lavapipe (docs/DEVELOPMENT.md "Cloud rendering").

- **From the dusk loop (2026-10-31)**: still unlit after the user's 16:20 photos: Rondo 1's
  tenant names, PHN and the Bank Polski tower's crown (not sure which building wears which; the
  cloud has no network to check), Złote Tarasy's dome lit from inside, Varso's antenna lattice,
  Chałubińskiego 8's antenna and dark-glass refit (photo IMG_7104), the screens on the Marriott's
  podium. The canopy lamps and the crown names are small at the widest zoom; look on the phone.
  Art review (art-director, Opus): Centrum LIM's lit cells (the `S_GRID` skin, shared with the
  InterContinental and the Westin) are cold white and many, the photos show sparse warm ones
  (`#ffcf7a`, ~12 %, upper third); the landmark signs still glow inside the occlusion ghost.

## The start area as real Warsaw (F, 2026-11-01)

F: improve every landmark in the start area, add street details, make the shop signs (Ściana
Wschodnia above all) like the real ones, rework the ordinary buildings to look real, match the
road and pavement materials to photos, and add trendy 2025/26 places and jokes. Research and
plan: docs/design/start-area-real.md (items R1-R8, ticked in ROADMAP "v1.0 checklist").
- **R1 done 2026-11-01**: the neon atlas draws words with Polish letters through pixel_font.gd;
  the stores' banners are now the 2025/26 mix (DO WYNAJĘCIA boards where H&M, Zara and C&A
  left, FROGS XXL on Wars's south corner where H&M's space becomes a two-storey Żabka, KAPCIE for
  the shoe chains on Zara's floor, WYPRZEDAŻ and ORANŻADA with their real letters); SCENA RELAX
  on the old Kino Relax behind Junior. Only the phone shows the boards' size at the default zoom.
- **R4 done 2026-11-01**: ordinary buildings outside the Old Town are drawn by type
  (map_builder.gd `_building_type`, building.gdshader `typed_facade`): pre-war tenements (a
  rusticated shop floor, a string course, tall windows in light surrounds, a heavy cornice),
  1960s-80s slabs and point blocks (pale panels, dark joints, loggia stacks), post-war offices
  (ribbon windows). The type comes from the OSM kind, height and footprint (a guess, not a
  survey). Left: a socialist-realist type for MDM and Marszałkowska south, per-street checks
  against photos on the Mac, and the tenements' own plaster colours outside the Old Town.
- **R2 done 2026-11-01**: Plac Centralny's paving in ground.gdshader (`centralny`): inside the
  square (Marszałkowska's frame, south and west of the museum) the plazas show the lost
  tenements as plots outlined in red and grey slabs, pale slabs where the houses stood and warm
  setts in their courtyards; the mapped walks are granite setts. The pond and lawns were
  already in the map. The plots follow the old grid's rhythm, not a survey: the orthophoto on
  the Mac should set the real outlines (and the square's edge, now a straight cut).
- **R3 part 1 done 2026-11-01**: footways are light grey concrete pavers in running bond (map
  builder COL "foot" #dddcd6, ground.gdshader layer 4), as Warsaw's pavements are, not sand;
  cycle paths were already brick red. Plazas keep their granite beige. Parked in QUESTIONS: the
  wider pavements drawn as ground/plaza areas are still beige.
- **R6 done 2026-11-01**: the trends thread's MACZA already stands in Pasaż Wiecha behind Sawa;
  four KEBAB FM host lines and two passenger lines joined dialogue.json (the stores to let, the
  two-storey Frogs, Plac Centralny's vanished tenements, the matcha queue, Scena Relax).
- **R5 done 2026-11-01**: the Cepelia pavilion at Rondo Dmowskiego is a site (landmarks.gd
  "cepelia"): a recessed glass shop floor, a frame band, a glass upper storey with mullions, a
  white edge and the red EMPIRYK sign (the book and vinyl store, a parody). Zodiak in Pasaż
  Wiecha is a low glass room under a thin overhanging roof slab on posts with its ZODIAK sign.
  Scena Relax keeps R1's pink sign on its mapped building. Both have info cards. Only the phone
  shows the signs' size at the default zoom.
- **R7 done 2026-11-01**: first_scene.gd ITEMS gained Warsaw's street name plates (navy, white
  letters, the red district strip, on poles at Widok, Sienkiewicza and Fangora), the tram island
  north of the museum (two glass shelters, a stop post, a ticket machine; the map had the
  platform but no shelter), a city bike dock (ROWERY,
  a parody, on Plac Centralny's edge) and three bollard rows along the west kerb. Same mesh (one
  draw call), but it now reaches the spawn end, so the bench's opening view counts it and its
  shadow: draw calls 130 -> 132. Props: add_street_plates, add_bike_dock, add_tram_shelter. The plates on the
  buildings' corners (where Warsaw mostly hangs them) wait for the Mac photo check.
- **R3 part 2, in part, 2026-11-02** (first-scene items 4-5): the start box's wide pavements and
  bare ground grey, tactile pads at the crossings, the tram platforms' edge lines. The three new
  crossings were already mapped zebras.
- **Open:** R3 part 2: lowered kerbs and Złota's setts (Złota itself is now the 2026 linear park
  with its fountain on the old tunnel ramp, see "Skwer Linearny na Złotej" above), orthophoto check
  on the Mac; R8 the museum's ribbon in stretches and the stepped roofline.
- Found: the cloud can't read Wykop (login wall) or Commons (403); the trends come from Google's
  2025 year in search and the trade press. A Mac pass could add Wykop's own tags.

## High priority: the first scene and the Museum of Modern Art (the user, 2026-10-31)
- **Found 2026-11-02 (Pasaż Wiecha build):** the default camera looks north-west, so the
  pavilions' shopfronts on the pasaż (their west faces) face away from it: from the start the
  player sees their roofs, south ends and the masts; the fronts show when the camera turns
  (`--yaw=225`). The strip in front of Scena Relax is one LoD2 mass with the theatre, so it was
  left in that model. The 1960s slabs above the pasaż are cream-ochre (spec D, 2026-11-01) but
  the photo report calls them grey-white #D8D8D4: parked in QUESTIONS.
- **Muzeum Sztuki Nowoczesnej as it is** (the user, 2026-10-31): the new white box on Plac
  Defilad's east edge (Thomas Phifer, opened 2024). Today it is plain white LoD2 parts with no
  model and no card. Wanted: one long, low, matte white box, the arcade of square columns at its
  base with the glazed lobby behind, one long ribbon of windows at mid-height, a few big upper
  windows, long skylights on the flat roof, a card. Spec and the values still to set:
  docs/design/first-scene.md "Spec for item 1". Landmarks lane: Opus spec, `object-modeler`
  builds, `art-director` accepts. **Built 2026-10-31** (site `msn`, spec
  `docs/landmarks/specs/msn.md`, from the museum's OSM 3D parts). Photo-checked on the Mac
  2026-11-01: the roof is one gridded glass field with two small wells, and the Marszałkowska
  window is a deep recess at mid-face. Found then, left open: the mid-height dark ribbon runs only
  in stretches on both long faces (photos 2 and 4), not all round as built; the Marszałkowska
  face's lower box has two small windows; the upper roofline steps down near the south end.
- **TR Warszawa's building site** (F, 2026-10-31): built as site `tr` on the empty plot west of
  the museum (a messy site: hoarding, dirt, heaps, old foundations, cabins, a digger, one
  crane). Left for the map lane: a mapped tree stands on the hoarding's north corner.
- **Złote Tarasy, the museum's way** (the user, 2026-10-31): **Built 2026-10-31** (site
  `tarasy`, spec `docs/landmarks/specs/tarasy.md`): the whole complex from its OSM 3D parts,
  the glass wave, the terraced sandstone podium, Lumen's crescent, Skylight with a lit crown,
  the drum, the planted south terraces. Left: the photo check on the Mac (Lumen's ribbons,
  Skylight's crown, the red entrance boxes), `tools/check_roads.py` on the Mac (needs
  terrain.json; its tarasy zone now mirrors the outline).
- **Recheck with the museum's approach** (the user, 2026-10-31): rebuild each from its real 3D
  map data, a spec in `docs/landmarks/specs/` passing `tools/check_spec.py`, the `--solo`
  silhouette and flat renders, zero defects in `check_mesh_quality`, a photo check on the Mac.
  In this order unless the user says otherwise: Pałac Kultury i Nauki, Warszawa Centralna, the
  Warsaw University Library (BUW, its green roof garden and the copper-green facade panels),
  the Copernicus Science Centre, Stadion Narodowy. **Warszawa Centralna built 2026-10-31**
  (site `centralna`, spec `docs/landmarks/specs/centralna.md`): the glass hall, the wings, the
  flat slab overhanging to 140 x 86 m and the hyperbolic paraboloid shells under it, all from
  the OSM parts. Photo-checked on the Mac 2026-11-01: the shells show far more than a zigzag,
  so the underside now falls from 16 m at the long edges to 12 m at the pillar rows and arches
  to 14.2 m over the hall, the winged shape the ends show. Still open: the wings' walls (the
  photos show a dark band with a window strip on the hall's end, not grey glass), warm or cool
  hall light, and the slight hypar curve along the long sides. **Stadion Narodowy built 2026-11-01** (site `stadium`, spec
  `docs/landmarks/specs/stadium.md`, PR #103's eyeball flag): the pitch was a 60 m blob under
  stands too deep; now a 105 x 68 m striped pitch along the masts' axis in two tiers with the
  boxes between, the skin red below and white above (the mapped rings), the raised rim, a
  rounded opening, the needle's hub and folded-roof drum from the OSM parts. The Mac photo
  check (same day) is applied: staggered red and silver panels on a smooth ramp, the dark
  glass concourse under the skin, a polycarbonate ring round the opening, thicker spikes.
  **The Copernicus Science Centre built 2026-11-01** (site `kopernik`,
  spec `docs/landmarks/specs/kopernik.md`, log `docs/landmarks/kopernik.md`): the long dark
  block to LoD2's 13 m with windows scattered like pixels, the river corner hanging over a
  glazed ground floor, the low glass wings, the roof garden, and the black faceted
  planetarium. Left: the photo check on the Mac (the panels and windows, the overhang's depth,
  the planetarium's height, the garden's real paths). **The University Library built 2026-10-31** (site `buw`, spec
  `docs/landmarks/specs/buw.md`, log `docs/landmarks/buw.md`): the copper plates with their
  lines of text on Dobra, the four philosophers on columns, the roof garden from the mapped
  lawns, the glass roofs and the band; the roof redone from the orthophoto on 2026-11-01.
  Pass 3 (2026-11-01, the Mac's LoD2 check): the deck at 15 m, the hill, the vents, the south
  garden's paths and beds, the court on Collegium Iuridicum II. Left: the north corner's four
  vents (outside the outline, the city's drums).
  The others not started.
- **Models from real photos, more detail** (the user, 2026-10-31): specs were written from the
  OSM outline, LoD2 heights and memory; nobody compared a model with a photo. Now: reference
  photos per building in `refs/` (Wikimedia Commons, gitignored; fetched on the Mac, the cloud
  gets 403), specs written from them at a detail level (L2 for named landmarks, L3 for the
  heroes), triangle budgets instead of minimal geometry, and `art-director` scoring matched
  shots against the photos (the model-from-photos skill). Next: re-pass the hero landmarks
  (the first scene's buildings, the Palace, the Old Town square, the Castle, the towers, the
  stadium, the bridges) against their photos, worst score first. Wanted later: an automatic
  check for coplanar faces (z-fighting) in a site's mesh.
- **Model checks from the research** (2026-10-31; item (1) DONE the same day as `check_mesh_quality.gd`, the z-fighting, zero-area, floating and budget parts; its `KNOWN` ratchet is empty since 2026-10-31 (the z-fighting in the towers and the Palace is fixed); parts inside parts and T gaps are still open, report in the project files "Детальніші моделі
  будівель"): (1) `game/tools/check_mesh_quality.gd`, run on each landmark site's mesh arrays:
  coplanar overlapping faces (z-fighting: group triangles by plane, test 2D overlap, ~0.01 m²),
  zero-area and flipped triangles, parts touching neither the ground nor another part (FAIL);
  parts inside parts and T-junction gaps (WARN, for the art-director); per-site allow-lists;
  joins `tools/verify.sh`. (2) A game flag that renders one landmark alone, unlit and as a
  silhouette, for the judge's shots. (3) DONE 2026-10-31: `tools/check_spec.py`, which checks a landmark spec has every section and parts-table
column filled and a triangle budget, so a Sonnet build never starts from an open spec.
(4) OPEN (plan in the skill, section 7): evals for the model-from-photos skill: the Palace, the Rotunda and the Museum of Modern
Art (their photos exist) built with and without the skill, scored the same way. (5) Later:
golden-image shots runtime vs `--prebuilt`,
  a flicker probe (two frames, a tiny camera move, diff), the Old Town's gables and a
  straight-skeleton roof bake (map lane), fewer directional shadow splits (perf lane). The
  rubric anchors, photo-first judging, the parts table and the two-round cap are in the
  model-from-photos skill already.
- **The first scene, polished to the maximum** (the user, 2026-10-31): the place the player sees
  first must make a "wow". Default place: Marszałkowska by Plac Defilad (the Palace, the museum,
  the Eastern Wall, the towers), where the spawn and DEMO 6.2's first minutes already are; the
  choice is parked in docs/QUESTIONS.md. The plan, its eight items (the museum, the opening shot,
  the Eastern Wall and Rotunda, Plac Defilad's ground, Marszałkowska's street, life, sound,
  light), the `first` shot set, performance and the order of work: docs/design/first-scene.md.
  The dusk and night look there belongs to the thread "Match landmarks to Warsaw at dusk"; the
  hints, first order and first race to loop 3h item 6.
  **Item 2 (the opening shot) built 2026-10-31, merged 2026-11-01**: the start (PR #115) and the
  first launch's flyover over the Palace down to the car (docs/design/opening-flyover.md), both
  on main together after the start-area rebuild (same start spot, so the trams and street
  furniture of the first scene are in the flyover's last frames). Left: its length and
  the stand's arrow timing on the phone (QUESTIONS), and whether the wide views hitch while the
  proxies swap to sectors on an older iPhone.
  **2026-11-01 (items 3-6, part):** the Eastern Wall's stores built (site `dtc`, spec
  `docs/landmarks/specs/dtc.md`); a start in the first scene's box (main.gd `FIRST_SCENE`) puts
  two trams on Marszałkowska, one passing the car, one coming down the street; street furniture
  by the start (`first_scene.gd`: kiosk, flower stall, cafés, ad columns, planters). Found: the
  game's camera sees the east side's stores from behind their street faces, so furniture on
  their pavements never shows (it stands on the museum's side instead). **2026-11-01 (Mac photo
  check, spec B):** the Rotunda re-pass done (spec `docs/landmarks/specs/rotunda.md`: green-grey
  glass between 52 silver mullions, the folded-plate crown with its teeth, the oculus, the
  canopies, Widok Towers' green grid); only the phone can show the teeth and the signs' size. Left: Plac Defilad's paving and park strip (the pavilions behind the stores done 2026-11-02, site `wiecha`),
  the tram stops and kerbs (item 5), the photo check on the Mac. **Items 6-7 (life and sound) built
  2026-11-02** (first-scene.md "Items 6 and 7 as built"). Found then, open: the café sitters sit on
  the footway by the tables, not on the chairs (a seat list per café set would fix it); the
  "a few cars" part of item 6 is left to the Low traffic default (G2), no boost at the start; the
  title screen itself still shows the trams wherever they went while it was up.
  **Items 4-5, paving and kerbs, built 2026-11-02** (first-scene.md "Items 4 and 5 as built"):
  the start box's pavements, paving and bare ground in Warsaw grey (ground.gdshader `START_BOX`),
  yellow tactile pads where every crossing meets a kerb (city-wide, map_builder `_build_tactile`),
  a light edge and a tactile line on the two tram platforms in the box (first_scene.gd). Found then:
  OSM draws the stores' frontage and the square south of the museum as bare ground (they were
  sand-coloured); a zebra's mapped end can stop 2.5 m short of the kerb (the pads look for the kerb
  line, not the end).

## Packs: running clubs, cycling packs, coffee raves, big guys with tiny dogs (F, 2026-11-01)
Built (`packs.gd`, docs/design/packs.md): three parody running clubs and two road-cycling packs out
and back on real pavements and cycle paths, coffee raves outside the COFFEECHAIR cafés (booth, DJ
Espresso, dancers), a third of the dog walkers big guys with tiny dogs, 58 new lines with parody
gear names (WĄWÓZ, CEGŁA, SPECJAŁ, GARNEK, SZPAN). Left:
- Only the phone can show whether a pack reads at the default zoom and what it costs there
  (bench in the cloud: llvmpipe only).
- Packs ignore the car (no swerve, no bump; the dawn crowd's rule); TEMPO NA KAWĘ's loop zigzags
  between the pavements on either side in places (corners joined within 4 m).
- A beat from the rave booth (sfx.gd positional voice), a rave notebook card or egg, a DJ crate
  courier job, a radio mention.

## Wellness circles: sound healing, techno yoga, the 40+ club, park kung-fu (F, 2026-11-02)
Built (`wellness.gd`, docs/design/wellness.md; ideas 2, 3, 4 and 8 of docs/design/city-life-satire.md): eight lawn
spots (Park Świętokrzyski, Skwer Kościuszki, Rondo Daszyńskiego, Browary Warszawskie, Ogród Saski, Park Ujazdowski,
Ogród Krasińskich) in daylight hours, 58 lines (`sound_healing`, `techno_yoga`, `club_40`, `park_kungfu`), check
`wellness`. Left:
- ~~No sound yet~~ DONE (2026-11-02): `gong_bowls` (gong every 6 s, singing bowl between, 12 s loop) at each sound-healing
  ring and `techno_thump` (muffled 128 BPM four-on-the-floor, 7.5 s loop) at each techno row, through city_sounds.gd's new
  `gong` and `thump` kinds (reach 60 and 70 m, sounding while the spot is on); `check_sfx` covers both loops. Only a phone
  or Mac listen can judge the levels (-13 / -12 dB, cloud has no ears).
- Mac look check (QUESTIONS): the spots are read off the baked lawns, not seen; Łazienki Królewskie, Pole
  Mokotowskie and Skaryszak (the design doc's other park spots) lie outside the map.
- Only the phone can show whether the 7-10 figures, the signs' text and the hamster balls read at the default
  zoom and what they cost there (cloud: llvmpipe only).
- Not rain-aware (the clock only); no notebook card or egg; the groups ignore the car (no scatter).

## Powiśle streets (F, 2026-11-02)
Built: eight original-name neon shop signs (`Storefronts.POWISLE`, same venue code as the cinemas)
on Tamka, Dobra, Browarna, Topiel and Solec. Left:
- Mac look check (QUESTIONS); doors, window light and a terrace for Flat Biały, the stairwell bar behind Altana.
- The tenements' ground floors, the Dobra and Tamka kerbs and pavements, trees and street furniture street by street; Czerwonego Krzyża and Ludna have no sign yet.
- Syrenka's statue by the foot of Tamka still only an egg (3h-syrenki).
- Doors, terraces and ground floors need a props pass (café tables and umbrellas as one MultiMesh, doors with window glow); no terrace helper exists yet and it adds geometry, so full definition of done (bench, shots): an Opus thread with a renderer, not a light cloud change.

## Vistula boulevards: life (F, 2026-11-01)
Built: nine `chill_bulwary_*` spots (`Crowds.BULWARY`) along the river edge from Karowa past Kopernik,
twice the dog walkers there, twice the cyclists (cap 16) and 45 % of them fast. Left:
- E-scooters on the bike path (the bike MultiMesh family has four shapes in the shader; a fifth
  needs actor.gdshader's shape channel widened). The marina thread owns the water side.
- Spot coordinates are read off the baked steps/benches, not placed by eye; a phone look check
  (QUESTIONS) may move some. Seating on the actual steps (snap a third of the sitters to
  `steps` polylines) instead of footways.

## Lore: coffee raves and arthouse cinemas (the user, 2026-10-31)
- **Shisha lounges** built (five parody signs, `Storefronts.LOUNGES`): only the phone can show the sign size on each wall and whether the spots read as lounges. Not notebook places; add smoky window glow or a door scene if wanted.
- **Asked**: add *coffee raves* and *arthouse cinemas* to Warsaw's lore. Content item, not built;
  the designer (`game-designer`, Sonnet for the text) specs it, `warsaw-tone` rules apply (real
  brands only as parodies, affectionate, Polish with English).
- **Coffee raves** (built 2026-11-01 at the COFFEECHAIR cafés, see Packs above; the venues, queue,
  notebook card and DJ job ideas here are still open) (poranne kawowe imprezy): daytime, sober-ish dance mornings, a flat white in
  one hand and a DJ on a pallet stage. Real Warsaw has them in cafes, courtyards and on the
  Vistula boulevards (Sunday 10:00-14:00). Fiction: a morning counterpart to the five clubs. Two
  or three parody venues, e.g. **Kawa Zero** (a courtyard in Praga), **Flat Biały** (a
  Powiśle cafe with a terrace) and a pop-up on the Bulwary. Crowd: cargo bikes, oat-milk jokes,
  strollers with headphones, a queue for the barista rather than the door. Shut at night.
- **Classic cinemas BUILT 2026-11-02** (F: "add all classic cinemas, Kino Muranów, Kino Atlantic and
  others"): seven neon marquees (`Storefronts.CINEMAS`, same venue code as the cafés, `check_parodies`
  counts them): Kino Muranów (Andersa), Atlantic (Chmielna), Luna (Marszałkowska), Kultura
  (Krakowskie Przedmieście), Elektronik (Czerwonego Krzyża), Femina (Al. Solidarności, beside the
  kebab district) and the Kinoteka at the Palace's west wing. Independent halls keep their real names
  (place names, not brands); the multiplex chains stay out. Left: Iluzjon (Narbutta, Mokotów, south of
  the map), Kino Wisła (location unverified), the evening queue and repertory board, notebook cards,
  poster-board facades. (KEBAB FM radio lines about the cinemas and the Basin done 2026-11-02, 8 untagged `radio_host` lines.)
- **Arthouse cinemas** (kina studyjne): small screens in old halls, a bar, a repertory board.
  Parody names for the real ones: **Kino Muranek** (for Muranów), **Iluzja** (Iluzjon),
  **Kultura 24** (Kultura), **Elektroniczne** (Elektronik), **Kinoteka Pałacowa** (Kinoteka, in
  the Palace of Culture). Facade = a hand-painted poster board and a neon title strip; a hush
  rather than a crowd; a small queue before the evening show (18:00-21:00).
- **Fit with existing systems** (no new system needed):
  - *Notebook places*: each venue is a `places.json` entry with a card (`hours`, `district`,
    a note line), unlocked when you stop at it, like the Wiralek and the clubs.
  - *Venues with queues*: reuse MW-3's queue and hour curves: coffee raves peak Sun/Sat
    morning, cinemas in the evening. Neon fascia through `storefronts.gd`.
  - *Day/night schedule*: raves open 08:00-14:00 and are dark at night; cinemas the reverse.
    That gives the day a nightlife of its own, so a Day run is not empty.
  - *Eggs*: a DJ who plays only the horn tune; a film that is "three hours of a pigeon" on a
    Kino Muranek board; a cinema bar that only serves coffee at a rave and wine at a premiere.
  - *Radio / dialogue*: a morning DJ spot on the radio and one-liners in `dialogue.json`
    (rave-goers, ushers).
  - *Jobs*: a possible courier or taxi run: carry a DJ's crate to the rave, or a film reel to
    the cinema before the show (uses `rides.gd` finishes).
- **Open**: the final parody names (F's pick), whether raves are Sunday-only, and the
  locations (map lane: pick real addresses from `centrum.json` POIs). Default if unanswered:
  the names above, daily 08:00-14:00 at weekends only.

## From v0.6 (traffic, trams, pedestrians, rivals)
- ~~Cars can overlap briefly in complex junctions~~ (fewer by three quarters, the traffic loop
  2026-10-30: junction cars watch each other's body and path, `--traffic-overlaps` counts them;
  left: two cars entering a short merging curve in the same frame); a racing rival stuck in
  traffic passes through other cars when off screen.
- ~~Trams and crossing cars can touch nose to nose.~~ Down by nine tenths (the traffic loop
  2026-10-30: trams follow their rails ahead for cars' boxes, cars stop clear at any angle, no
  spawning beside a tram; `--tram-watch=N` with `--traffic-overlaps`); about 70 tram-car frames in
  three minutes remain near -1830, -220.
- ~~Name tags and bubbles show faintly through the translucent WIN/LOSE card.~~ Fixed by loop 2e:
  the result card is one of the HUD's floating panels, so it is in `hud.gd` `panel_rects()`, and
  `bubbles.gd` skips a name tag that touches one and places bubbles clear of them (checked
  2026-10-30 in the code; `check_hud` covers the layout).
- From the spawn point only two race finishes (the Palace, Złote Tarasy) fall inside the
  600–1800 m road window; add more finish places or widen the window by rival.
- The race and tail autopilots leave the car's collision off (like the mission autopilot);
  fine for screenshots, but autopilot runs can't test crashes.
- ~~Races pay respect only; the v0.65 side jobs add a shared złoty wallet (races, tips, rescues).~~
  Fixed in v0.65: races pay the rival's stake into the saved wallet.

## From earlier versions
- Rescue mission time limits are untuned. **Measured 2026-10-30** (a cloud thread, Linux headless,
  `--mission=N --autopilot --fixed-fps 60` from the spawn, calls 1-12): the car autopilot used
  31-39 % of the limit (call 4 Autonomia 50 of 145 s, call 3 Vistula shore 128 of 325 s), the
  helicopter 41-51 % on the roofs (call 6 Sheraton 59 of 135 s, call 2 Nowogrodzka Square 120 of
  235 s) and 31 % on street calls. The autopilot ghosts through traffic and drives the best line, so
  a player at 1.5-2x its time still lands at 50-80 %: the car's limits are generous, the roofs
  fair. Left as they are until the 3h playtests say a call feels slack (then tighten the car's
  9.5 m/s pace in `missions.gd` `_limit_for` first; the helicopter's 17 m/s has the least slack).
- ~~iPhone frame time is unmeasured~~: measured in loop 2b on an iPhone 16 Pro Max: 60 fps (the
  cap) at the default, zoomed-out and helicopter views; GDScript there takes 4–5× the Mac's time
  at 60 Hz (iOS runs the CPU slower when there is time to spare).
- GUGiK terms checked 2026-10-28: the LoD2 buildings page says free for any use; the elevation
  model (NMT) and the orthophoto are free under Prawo geodezyjne art. 40a ust. 2 pkt 1 lit. d/e;
  the trees are CC BY 4.0. Keep the in-game GUGiK credit. Optional before release: a written
  confirmation from foto@gugik.gov.pl.

## From v0.65 (side jobs, dialogue, easter eggs)
- Five of the seven kebab stands are added corners, not mapped places.
- No Syrenka statue is mapped inside the area: she stands on the Powiśle boulevard by the foot
  of Tamka; the flood wall there is not in the roof grid, so placement relies on a short step
  towards the water.
- ~~Roadwork barriers are pushed by a distance check, not physics: the helicopter's downwash and
  traffic don't move them, and AI cars drive through the ones knocked into the lane.~~ Fixed in
  the roadworks loop (2026-10-30): moving traffic knocks the ones under its box (along at 75 %
  of its speed, out to the side), and the helicopter under 14 m blows the ones within 9 m out.
  Still a distance check, not physics; the AI still never brakes for them.
- The kebab/słoiki autopilot (like the race one) ghosts through traffic, so autopilot runs can't
  test jar breaks from real crashes (`--sloik=K` starts with K broken for screenshots).
- Pay rates (kebab 30–110 zł, słoiki 50–260, races 60–300, rescues ~120–200) are first guesses.
- Kebab stands and the station person are drawn on top of whatever the bake put on the pavement
  (a bench or a bin can poke through the kiosk).

## From v0.75 (real roads)
- The Praga streets join the network only through an off-map link at the east edge (they meet
  the rest of the city out there): route planning and the autopilot (which jumps it) use it, but
  the player has to drive in the wrong way down a one-way street or across the lot at the west
  end of Jakubowska. A real in-map way in needs a design call (a drawn link road?).
- The terrain grid stops ~9 m short of the map's south edge and ~5 m short of the east edge;
  carriageway areas and kerbs are cut there, but road strips, footways and areas (as before)
  run on to the map's edge and hang over the diorama's earth wall.
- Bus lanes only where the lanes are tagged per lane or counted on one-way roads; AI traffic
  doesn't keep the bus lanes free.
- Medians are found only between pairs of one-way roads; a two-way road with a median mapped
  as one line gets none. Loop 3b-2 counted the class: 0 on today's map (no `divider`, no kerb,
  barrier or hedge line along a two-way road's centre; the 3 gaps between a two-way road's
  carriageway areas, on Ludna and Czerniakowska, are not medians). Build it when the bigger map
  (loop 3d) brings one.
- Most Świętokrzyski is cut by the map's edge mid-river: its deck ends in the air at the rim.
- 13 signal controllers still run as lone crossing lights; they look like real mid-block
  crossings, but a few (Emilii Plater, Świętokrzyska by Mazowiecka) may be unmapped junction
  approaches.
- `--kebab=N` maps to stand N mod 7 now (seven stands), so the same N gives a different order
  than in v0.65.

## Seen in screenshots (orchestrator, 2026-10-28)
- Fixed in loop 1: the barriers and cones read (red-and-white 2 m barriers, bigger cones,
  blinking amber lamps); joke posters on one column in six; the occlusion ghost's dark stain;
  Varso I/II's floating part.

## Decided after v0.8 (orchestrator defaults, 2026-10-28; the user may still change them)
- Done in loop 1: the Palm stands where the scanned "tree" stood (the record is left out of
  the bake); the ghost stays a dither with its dark patch fixed (judge the dither size on the
  phone); the Palace clock shows the time in Warsaw.
- The info-card facts are confirmed as written (Varso Tower at 310 m is the tallest building
  in the EU).
- The renamed race finish ("Stadion Narodowy") may drop old best times; nobody has saved one
  yet, so no migration.

## From v0.8 (landmarks)
- The ghosted tower's shadow still lies on the street (the shadow pass is unchanged, by
  design): behind the Palace the car's surroundings stay in its shade (ghost/ring 0.83 there,
  loop 1). Worth a device look: on an iPhone screen the 4 x 4 dither may want a coarser
  pattern.
- ~~Tapping walks the roof grid, so a tap on the cut-away part of a tower in front of the car picks
  that tower, not what shows through the cut.~~ Done in sweep 2: the walk steps on through what
  the ghost has made see-through (main.gd `_pick_unghosted`; behind the Palace, a tap on the
  street seen through its cut tower picked the Palace, now nothing).
- The Palace's roof rescue now lands on the 30 m north block's roof (since the 2026-11-01 re-pass built it whole): every tier is crowned by attics and
  pinnacles, so no 3 x 3 cells are flat up the tower. A rescue from the 30th-floor terrace would
  need a landing spot designed in.
- The baked ground AO and the lamp light map still use the LoD2 footprints: Centralna's canopy
  (wider than the LoD2 hall) casts no AO, and lamp pools are not cut by the stadium's skin.
- Varso I and II stay OSM extrusions (loop 1 lowered Varso 2's floating
  80-90 m top to the ground; Varso 1's 71-81 m top rests on its 71 m part for a little over
  half its footprint and overhangs a 10 m part for the rest, so it stays).
- The title skyline's Varso stays shorter than the Palace (in the city it is 310 m to 237 m).

## From v0.9 (water, weather, sound)
- Fixed in v0.9: lamp pools lit the water and the ground under bridge decks (the surface map
  knows the deck heights; the water gets reflections instead of pools).
- The sounds were judged by numbers only (peaks, RMS, loop seams, spectra, bus meters); nobody
  has heard them on a phone. The engine is tuned for a phone speaker (little below 150 Hz).
- ~~Puddles are a noise mask on the road layer: lane markings and stop lines are drawn over them,
  so a painted line crosses a puddle unbroken.~~ Fixed 2026-10-30 (loop 3i item, a cloud thread):
  the markings layer gets the same puddle mask as the asphalt in `ground.gdshader`, so a line goes
  dark and mirrors the sky where it crosses a puddle (the post pass already reflected on them).
- The mirror reflections are screen-space: only what stands on screen above a surface
  reflects (nothing past the top edge), and thin posts reflect as broken dashes. (By day the
  water now shows a bridge as a darker band, loop 1.) The light concrete slab edges of Most
  Poniatowskiego still draw thin pale lines along the deck by day.
- Rain streaks are screen-space: they fall inside the Rotunda's glass and under bridges, and
  keep their pixel size at every zoom.
- No spray or splashes behind cars in the rain (at the default zoom a car is ~18 pixels long;
  a convincing spray needs particles: not cheap enough for this pass).
- Medium quality's render scale (0.85) gives the same whole-pixel image as High on a 1080-line
  Mac screen and an iPhone's 1170 lines: only Low makes the image smaller there. Quality and
  weather are not saved (settings are v1.0).
- Live mode: at night the moon keeps the Night look's fixed direction.
- The perf overlay's CPU "process" time is Godot's whole idle step (it includes waiting on the
  render thread on some frames), not only the scripts; GPU time is n/a on Metal.
- `--race=0` maps to rival 1 (the flag takes 1-6; 0 is clamped up), as before.

## Decided after v0.9 (orchestrator defaults, 2026-10-28; the user may still change them)
- Weather stays a RAIN toggle beside VHS; QUALITY stays on the hidden perf overlay until the
  v1.0 settings screen (the device pass decides whether Low is needed by default).
- The iOS audio session stays Ambient: the silent switch mutes the game, radio included, and
  the player's own music keeps playing.
- Live keeps the sun's pitch between 20° and 55° and is not the starting mode (daytime first).
- Rain starts only from the button or flag for now. Idea for later: rain on some days, picked
  by the date like the roadworks street, never by the network.
- Seen in screenshots: the river camouflage, the white flecks, the bridge's pale "wake" and the
  ghost over the glass tower in Live 08:00: fixed in loop 1.

## From loop 1 (polish)
- The v0.8 Palace shots (`--at=-1170,300`, `--at=-1180,300`) put the car inside the Palace's
  footprint, which driving never does; the real spawn is on Marszałkowska by the glass tower
  east of Plac Defilad. Loop 1 measured the Palace from the north-west (`--at=-1290,170`).
- The ghost keeps 3 pixels in 16 in its core: thin enough to see the street, enough to keep a
  tower's shape. Judge it on the phone (and whether a coarser 2-pixel dither reads better).
- A ghosted footprint gets its sunlight back by the sun's height, a guess at how much of the
  street round it is sunlit; in a low sun a footprint can read a little lighter or darker than
  the shaded street beside it (Live 08:00: ghost/ring 1.06).
- The post pass leaves out the ghost's outlines from the same region test; the inner faces of
  a cut building (dropped a little past the car) still get outlined at their edges.
- Floating parts: parts that start below 10 m with nothing under them (canopies, passages,
  pilotis, a few probably unmapped podiums: at -939,-751, -1511,-867, -93,-305) stay as mapped.
- The roadwork lamps all blink in one beat (simple, and their halos keep in step); real ones
  often run in sequence.
- Column posters hold four lines of eight letters (4 cm letter pixels); the letters read only
  close up, so the passing bubble carries the joke. Lines repeat across the 24 columns
  (16 lines).
- The AO map is twice the size (two channels: 12.5 MB as a texture); `city.scn` grew 0.8 MB.
- ~~Night water is a flat deep navy away from the lamps: calm, maybe too plain at the widest
  zoom; a faint sky sheen could come back if the device pass wants it.~~ Done 2026-10-30 (loop 3i
  item, a cloud thread): after dark the river gets a faint sky sheen as light (broad 40-80 m
  patches along the flow, so it reads at 320 m, plus the slow crests) and a warm city glow within
  ~40 m of the banks; off above dusk's daylight, so dusk is unchanged. Judge it on the phone.
- The bench ran uncapped (220-280 fps) for most of loop 1 instead of at the display's 120 Hz:
  frame times and GPU readings are not comparable with earlier sessions' numbers, so loop 1
  ran the v0.9 code alongside for its before/after. Fewer cars fill in over 600 faster frames.

## From loop 2a (controls and settings)
- Only the user can judge the feel on the phone: the hold-then-ease camera in Point, the turn
  rates (calmer at speed than before: 23.5 m full-lock radius at 90 km/h), the 0.15 dead zone
  and full gas from three quarters out on the stick (70 HUD units, ~38 pt radius on an iPhone
  13), the 80 m default view, and whether the 44 pt panel controls feel right. Touch was emulated from the mouse and driven by
  `--clicks` / `--drag` / `--stick` on the Mac; nothing ran on a device.
- ~~Point with a finger that never lifts behaves like a fixed camera at whatever angle the
  camera had (it only comes round after a release). The zoom (− + / pinch) is not saved.~~ The
  follow-camera loop (2026-10-30): Point's camera turns with the car while held, the zoom has five
  saved steps. Not tested headless: the 20° re-aim, and how it feels on the phone.
- In a dense spot the car can be pinned between a wall and a stopped traffic car that waits for
  it; the unstick turns it out after 1.5 s, and a second pin within 5 s tows it back onto the
  nearest lane on its level (next to a kerb that can be almost where it was, turned the lane's
  way).
  ~~Traffic still stops for a player that only brushes it.~~ A brush dazes it for 0.4 s, a
  real hit up to 2.5 s (the traffic loop, 2026-10-30).
- Busy's traffic target is more than the spawner can place in the band round the view (70 vs
  ~44 at 80 m): the levels are calibrated on real counts. If the spawner changes, re-measure
  (bench `--traffic=`).
- The like-with-like GPU reading (110 m, Busy, Classic) was 2.43 ms by day against 2.27 before
  (night 2.20 vs 2.21): within the run-to-run spread (2.06-2.90 ms for one code), and the 3D
  view's GPU time can't include the HUD; the new defaults read 2.24 / 2.01.
- ~~The keyboard in Point points in screen directions: on the diagonal opening view, W turns the
  car off the road's line (it goes up the screen). Classic keeps the old car-relative keys.~~
  Sweep 2: already fixed by the camera loop, which starts a following camera behind the car
  (`--cam-log` at a normal start: heading 159.7°, camera 159.7°, so W is straight ahead along
  the road). The 45° view stays only where it is meant to: the Fixed scheme (following off,
  W up the screen by design) and the test views (`--shots`, `--bench`, `--probe`, `--yaw=`).
- The old `--fixed` flag now picks the Fixed camera scheme in Point (as CAM does).

## From loop 2b (frame rate on the iPhone)
- The device log starts with `ERROR: Mouse is not supported by this display server`
  (display_server.cpp:536), once, from the engine before any game script runs (no script asks
  for the mouse; switching touch-from-mouse emulation off on mobile didn't stop it). Harmless.
- The phone's GPU time can't be read (Metal has no timestamps in Godot 4.7), and at 60 Hz the
  main thread waits for the display inside "draw" (2–12 ms depending on the run), so the headroom
  under 16.7 ms isn't visible. A build that allows 120 Hz would show it as fps above 60 (not made
  this round; the old build did 64 fps from the helicopter with four times the GPU work). Loop G1: a Metal System Trace reads the GPU (From loop G1).
- The Mac's worst single frame in the bench reads 17–20 ms after against 9–20 before (the
  averages fell by half): one-off spikes, probably first-sight pipeline compiles (2–3 a run).
- With the 60 cap on the Mac's 120 Hz display (`Engine.max_fps`) frames alternate unevenly
  (~20 % a little late); on the iPhone the display itself runs at 60 Hz and paces it.
- The shadow's texels follow the zoom now (the far plane is set from the view): pinching or
  zooming changes their size; the speed zoom doesn't (held constant on purpose).
- Medium and Low share the pixel size (one step coarser than High); they differ by shadows
  (1024, buildings and trees, vs none), glow, reflections, rain, traffic and people.
- The user's 13–16 fps came from Xcode's Run (debugger + Metal API validation, ~9 µs per draw
  call): the old build read 18.9 fps with validation on and 120 Hz without; the new one 60 either
  way. `tools/export_ios.sh` now turns
  validation and GPU frame capture off in the scheme; the debugger is still attached under Run.
- Thermal state isn't readable from Godot; the BENCH card shows fps per 10 s instead.
- Device runs launched with `devicectl`: the launcher may eat the `--` before the game's
  options, so `main.gd` also reads them from the engine's own arguments. On iOS `quit()` doesn't
  end the app at once: `--bench` / `--probe` print once and stop measuring (the old code printed
  its result every frame after, 20 MB of log).

## Decided in loop 2b (orchestrator-free defaults; the user may still change them)
- 60 fps is the default cap, 30 the battery saver; no 120 Hz option.
- ~~High stays the default quality on the phone~~ Loop G1: Auto is the default (the level for the device); Medium is still the first step down from High.
- The BENCH runs at the current settings and cap (not uncapped) from the spawn at the default
  view, 5 s settle + 55 s measured; the card's numbers are in English (Polish header/buttons).
- Shadow edges are a little finer than before (0.37 m texels on High instead of 0.49 m).

## From the project setup (agents, skills, checks; 2026-10-28)
- ~~`check_landmarks.gd` exits 0 even when a check fails.~~ Fixed: it ends with
  `quit(0 if _check() == 0 else 1)` (tidied 2026-10-30, checked in the code).
- ~~README gives two different `bake_osm.py` command lines.~~ Gone: the map chain moved to
  DEVELOPMENT.md and `tools/setup_map.sh`; README has no bake line (tidied 2026-10-30, checked in the code).
- ~~README names the Apple team ID.~~ README no longer does; the ID stays in
  `export_presets.cfg` (not a secret, decided: BACKLOG-TRIAGE "Decided since") (tidied 2026-10-30, checked in the code).
- Device-run permission in CLAUDE.md stays per loop ("when the user said so for the current
  loop"); the user allowed phone test builds on 2026-10-28.
- ~~Haptics fail on the phone~~ Fixed in code 2026-11-01: Godot 4.7.2's iOS template
  (apple_embedded.mm) logs `Could not vibrate using haptic engine: %@` after every buzz, so
  `(null)` means no error. The buzzes were 25-40 ms at 0.3-0.5 as continuous events, too faint to
  feel. haptics.gd now floors every buzz at 45 ms / 0.55 (cap 220 ms), merges buzzes 70 ms apart,
  scales the car's knock 50-160 ms by the hit, and starts the engine without waiting at load, on
  resume and every 6 s while driving. Still to check on the phones (device run): the feel, and
  no hitch on the first crash after a pause. If still not felt: a `UIImpactFeedbackGenerator`
  plugin (needs Xcode on the Mac).
- Crash sparks and dust (crash_fx.gd, 2026-11-01): checked by screenshots on the cloud's
  software renderer (day: an orange burst and dust, night: a white glow). Not seen yet: the
  prebuilt city path (the cloud's map data is stale: bake_city fails on the site slabs, not this
  change), the phone's frame during a crash (2 draw calls and ~77 µs of script on a desktop
  core while particles live; zero when idle).
- ~~The once-only `ERROR: Mouse is not supported by this display server.`~~ Duplicate of the
  loop 2b entry above (tidied 2026-10-30, checked in the code).

## From loop 10a (the river is off-limits)
- The splash, the tow and the stone's look were judged on the Mac (screenshots, logs); the feel
  on the phone (does the splash read at the default view, is 1 s the right wait, is the toast
  readable) is the user's to say. The splash's sound (the hard knock pitched down + the rain
  bed's noise) was never heard: headless runs have no audio.
- The bake still leaves the shore open within 6 m of every bridge deck (`tools/bake_roads.py`
  `bake_shore`); the map builder fills those stretches at build time where the deck is at
  least 3.2 m up (`_shore_under_decks`). Moving the rule into the bake (map-engineer) would
  make `shore` in centrum.json say what the game builds.
- Godot's `cast_motion` misses some thin walls of the city's one big concave collision shape
  (`check_water.gd` steps an overlap test every 0.5 m instead). The car's own `move_and_slide`
  holds (0 of 631 cars through at 91 km/h), but any future check that sweeps shapes should
  step too.
- A car that gets less than 2.5 m past the edge (the shallow first metres; only reachable past
  the stone through a glitch) doesn't count as in the water, so it isn't towed until it rolls
  further in.
- The tow goes to the nearest lane to where the car last stood on dry land; from the middle of
  a wide beach that can be a junction ~100-200 m inland (the check's worst case, from mid-river
  with no bank known, is 491 m).
- A beach path's paving still draws past the stone into the water where OpenStreetMap maps it
  so; people now turn back a metre short of the water.
- ~~The helicopter's roof toast is still English only.~~ Fixed: "Wyląduj na otwartym terenie,
  żeby wziąć auto." over the English (`main.gd`) (tidied 2026-10-30, checked in the code).
- ~~`map_builder.bounds` isn't stored in `city.scn`.~~ Fixed: `bounds` is `@export_storage`
  in `map_builder.gd`, so the prebuilt index carries it (tidied 2026-10-30, checked in the code).
- The bench route's ghost car drives with its collision off, so the water test never runs on
  the bench; it was measured with the probe (car physics 0.05 → 0.05 ms at the river) and a
  micro-benchmark (0.8 µs a call, one call per physics frame).
- ~~Windowed `--prebuilt --shots=` runs sometimes end with "8 ObjectDB instances were leaked at
  exit" / "4 resources still in use" (seen on the code before this loop too; not in headless
  runs).~~ Done in sweep 2: `--verbose` named them, the four sounds playing at the quit (the
  radio's station, the engine's idle and mid loops, the city bed: an AudioStreamWAV and its
  playback each), still held by the audio server when the tree went (1 run in 4 before); a
  shots run now stops its sounds and quits 0.15 s later (main.gd `_quit_quietly`; 0 in 6).
  The bench's and `--quit-after`'s quits are unchanged (they may show the same race).

## From loop 3a (roads I: the check and the bake)
- Fixed in loop 3b: R2 (the GeoTIFF corridors are read), decks too low over the Jana Pawła II
  viaduct's pillars and the Poniatowski viaduct's arcades, the approaches' plain faces (retaining
  walls), tunnels and garage doors data only (drawn and driven), C4/C5/C9/C10. Kept below for
  the record; still open: the minor service ways' and junction pits' steep bits (C1 allowlist),
  the schematic footbridges (C3 allowlist), C10's other landmarks by their outlines, the runtime
  build's time.
- ~~**R2 is waiting for its data.**~~ `bake_roads.SurfaceModel` reads the 0.5 m surface model and the
  1 m terrain as ASCII grids once `data/raw/demo/MANIFEST.md` exists; the corridors arriving in
  `data/raw/demo/gugik/nmpt05/` and `nmt1/` are GeoTIFF, which it doesn't read yet (a small
  stdlib TIFF reader, or a one-off conversion to .asc in the fetch). Untested on real data.
- **Decks still too low where something stands under them** (C9 57, C5 50): the Jana Pawła II
  viaduct's 48 mapped pillars (OSM buildings 4 m high) poke through its ramps, so the real
  viaduct is level further out; the Poniatowski viaduct over Powiśle sits ~5 m over the streets
  while the Arkada (7.6 m) and the LoD2 arcades under it are taller. Either the surface model
  (R2) or mapped pillars as lower bounds in the solver; then loop 3b's building cut.
- The approaches' sides where they stand above the 10 m grid are plain concrete faces (no
  collider): loop 3b's retaining walls (R6). The sidewalks beside an approach stay on the grid,
  so at an abutment's blur they sit lower than the road.
- Tunnels are data only: not drawn, not driven, not on the minimap; their lane-graph edges stay
  out of routing and traffic (`lane_graph.gd` `TUNNELS_DRIVEN`). The Wisłostrada trench at
  (637, -554) is still a dead end for the car (marked: `tunnels.portals`). The tunnel on
  Warecka (OSM `tunnel=yes`, 7 m under a building) may be a gate, not a tunnel.
- Garage doors (`garages`, 27) are written but not drawn: the service way just ends at the ramp's
  top. 21 minor service ways still have a steep bit of the 10 m grid (C1, allowed with one shared
  reason, not looked at one by one); 5 pits at junctions too (the pit fill stops where another
  way enters a road's corridor). Both want the 1 m terrain.
- Footbridges mapped schematically keep short clearance (Centralna's access=no footbridge over a
  covered aisle, the science centre's roof-garden ramps, one footbridge whose stairs don't touch
  it); the WKD cutting by Centralna has no known depth (C3 allowlist).
- check_roads' C10 knows Most Poniatowskiego's towers' colliders exactly; the other landmarks'
  colliders are approximated by their outlines.
- The runtime city build is ~0.5 s slower (7.3 → 7.8 s on the Mac): every draped vertex asks
  `terrain_height`, which now looks the fills up; the prebuilt path doesn't build.
- CLAUDE.md still says no add-on is installed: Debug Draw is (game/addons/debug_draw, CREDITS.md).

## From loop 2e (the HUD at phone size)
- Everything was judged on the Mac at the phones' sizes (the window stands in for the phone:
  `screen_points.gd` gives 2868×1320 the Pro Max's points and insets); nothing ran on a device.
  The safe area on the phone comes from iOS (`get_display_safe_area`): if a model's landscape
  insets differ from the table, the phone wins and the Mac shots differ.
- On a 390-pt-tall phone (the 6.1" class) the screen is full when a card, a status and the
  radio host's long line coincide: the ticker, a note or landmark card, a speech bubble or the
  performance overlay then waits for room (`check_hud.gd` lists 26 such waits over its 96
  states, none on the Pro Max without the overlay). A waiting bubble is dropped after 6 s;
  the vendor's line at a kebab stand usually waits until the job card goes.
  Landmark card fix (2026-10-29): the note and landmark cards now take the right-hand column
  first, so a tapped landmark's card shows beside the car with the ticker up (`check_hud.gd`
  checks it on all four screens); they no longer count among the waits above.
- The passing panels keep out of a 110×84 pt box in the middle of the screen; at speed the view
  leads and the car can sit outside it (up to a fifth of the view off centre), so a toast can
  still cover a fast car for a moment. Cards and the status may cover the car on a 390-pt phone.
- First rescue call 60 s into play, then 90 s after each (`missions.gd` `FIRST_CALL`,
  `NEXT_CALL`): first guesses; DEMO.md 6.2's scripted first ten minutes put it at 4:00.
- The two-finger twist (40° for a 90° turn) works only with the fixed camera; with following
  on it does nothing (an accidental twist while pinching would otherwise switch the saved
  scheme). Not tried on glass.
- The stick's reach is 42 pt everywhere (it was 43 pt on the Pro Max, 38 on a 6.1"): the
  6.1" gets 11 % more travel for full lock and full gas.
- The DEMO.md loop-2e row asked for ≤ 30 2D draw calls; the 2D pass is 38–46 at the four probe
  views (README's budget: 80). The bubbles, the minimap's overlay and the labels are most of it.
- Most mission, job and race text now has Polish over an English gloss written in this loop
  (not yet reviewed by the game designer); the radio host's lines, the rivals' and customers'
  lines come from `dialogue.json` as before. The egg note's Polish names are in `eggs.gd`
  `EGGS_PL`. A few toasts still carry both languages on one line ("Najpierw wyląduj · Land
  first").
- `tools/export_ios.sh` doesn't create `build/ios/`: in a fresh checkout or worktree
  `tools/verify.sh --ios` fails with "Target folder does not exist" until `mkdir -p build/ios`
  (a one-line fix in the script, left for its owner). It also re-bakes `game/map/city.scn` on
  every run, so a loop that must not touch the map puts the committed city.scn back afterwards.
- The TWIST, the 6 s bubble wait and the 110×84 pt car box are first guesses (`hud.gd`
  `TWIST`, `CAR_ZONE`; `bubbles.gd` `MAX_WAIT`).
- The art bible's "Phone sizes" line still says the HUD is in 720-line units (left as is: the
  art bible changes only with the user's yes).
- The landmark info card and the egg note use 13 pt for both languages; the speech bubbles 15 /
  13 / 11 pt. A "Text size" setting (Small / Normal / Large) was not built.

## From the first-minute look (2026-10-28, after the art review)
- The gold wall the review saw "inside the cut tower" at the Palace by night is the shaft's
  own floodlit north-west face beyond the car (a debug render: front faces past the car, not
  back faces); the cut's real inner faces (back faces) are now unlit and flat. Dimming walls
  beyond the car inside the ghost would need to know that something is ghosted there (else a
  dark hole would follow the car along every street at night): main.gd could pass it.
- ~~The neon sign quads (`neon.gdshader`, 361 signs) are not ghosted (they never were): a sign on
  a ghosted wall stays lit, mirrored, over the ghost. Feeding them the ghost's uniforms is one
  more material in main.gd `_update_ghost` (outside this loop's main.gd scope).~~ Done in sweep
  2: neon.gdshader includes ghost.gdshaderinc and `_update_ghost` feeds it (a mirrored BAR
  MLECZNY over the ghost is gone, both city paths; draw calls unchanged).
- On a lamp-lit bridge deck the car's paint reads ~20 luma under the lit deck: a saturated red
  tops out at ~110-130 luma, and the value ladder puts lit ground above the car. It stands out
  there by chroma (paint saturation ~0.85 against ~0.35). A brighter hero would have to turn
  orange (the jobs' colour) or pink.
- Inside-out LoD2 walls (the few the building shader is double-sided for) that fall inside
  the ghost's region on screen go flat and dark like a cut building's inner faces.
- The pools' bands are concentric rings; on big lawns (the Rondo's islands) they read as
  targets. Judge on the phone (options: three bands, or less contrast between them).
- Lumpy crowns are shader lumps on the 12-vertex icosahedron: irregular crowns, not 2-3
  separate blobs; real blobs need a new crown mesh (map side, with the crown sizes near roads).
  Conifers share the material and get gentle lumps too.
- Cycle lanes under sodium at night still read red (dimmer, tinted, not added), under the car.
- ~~The minimap still shows the azure water and lime parks (HUD side).~~ Done 2026-10-30: the
  water is the river's grey-green-blue (`#70a0ac`, was azure `#7fb8de`); the parks were measured
  against the lawns by day (`#a9cf7c` vs `#9fca6a` in sun) and match, so they stay.
- Buses and trams keep their Warsaw red-and-yellow livery and the rivals their looks (loop 2c:
  Słoik's stripe is pickle green now; his orange name tag stays): street-level Warsaw is on the
  review's protect list.
- Half the LoD2 walls now run the facade code instead of the roof grain: the bench numbers are
  in README (The first-minute look); the phone's 60 fps is the orchestrator's to confirm.

## From the camera loop (follow camera, Phantom Camera)
- Only the phone can tell the feel: the 64°/s Classic camera (it lags up to ~40° behind the car
  in a 90° turn at 50 km/h, more in a full-lock circle), Point's 2.9 s return, the look-ahead
  that builds up over ~4–5 s from a standing start to 90 km/h (capped at 3.5 % of the view a
  second, so the car never slides fast across the screen), the car resting ~46 px below the
  middle after a hard stop, and the cinematic moments.
- Classic's camera rests up to 1° off the car's heading after a turn (the yaw dead zone).
- The Fixed camera's 90° turns (`<` `>`, Q / E, switching CAM off) are still a quick 8/s lerp
  (up to ~360°/s at the start), as before: they are the player's own command.
- The look at a target only plays under 30 km/h with nothing held; a target that appears while
  driving fast or steering gets none (the minimap and the arrow show it as before). A rescue's
  timer runs during the ~2.9 s look.
- The moments' widest views draw ~217–219 draw calls for a second or two at the spawn (the
  zoomed-out budget view is 190–215); the shadow's texels change size during them (the view's
  height changes), and benches, bins and racks pop in as the fly-in passes 153 m.
- Phantom Camera's editor plugin is not switched on (it checks GitHub for updates whenever the
  editor starts, headless exports included). The add-on's two Nunito fonts crashed Godot 4.7.2
  once in this worktree's first headless import after the copy (a threaded font import touching
  the scene tree); a second `--import` finished, and a later re-import of just the fonts was fine.
- Phantom Camera's manager sets `Engine.physics_jitter_fix = 0` when it starts (no effect with
  physics interpolation on).
- `--cam-test` ghosts the car through walls; on Marszałkowska (the README's spot) the Point
  release drives through buildings, so its frames show the occlusion ghost.
- `check_steering.gd`'s px/s numbers changed meaning: every test now starts with the camera
  settled for the starting speed (loop 2a's README numbers started it at the car).

## From loop 3b (roads II: the builder)
- **The minimap doesn't draw the tunnels yet** (DEMO 4.4: dashed). It is `hud.gd`
  `_minimap_mesh` (the HUD agent's file): after the roads loop, the `tunnels.roads` as 8 m
  dashes in the road colour. The snippet is in the loop 3b report.
- **The car in a tunnel is a silhouette, not the plan's dithered ghost.** `tunnel_xray.gd` draws
  the car's meshes once more with an unshaded material that ignores depth (after the post pass);
  the ground over the tunnel stays whole. A dither in `ground.gdshader` would need `discard` in
  the ground's shader (a cost on the phone's tile GPU for the whole ground); the look is the
  user's to judge on the phone.
- The portal frames are simple (a headwall, two posts, a dark mouth 3 m in); the 10 m grid's
  slope over the first metres of a tunnel covers part of the mouth. The open ramp's walls stand
  on the grid's blurred trench sides.
- Tunnel 2 (the link under Most Poniatowskiego's west abutment) is shallow (30 m long, ramps of
  8 % from both portals, ~1.5 m under the grid): it passes under the abutment's approach fill,
  whose retaining walls open over it (the wall's foot at the mouth's top).
- The bus is swept on main roads and links only (lane classes 0-1): traffic sends a bus into a
  residential or living street with a 5 % weight (`traffic.gd _choose_next`), where a rigid
  12 m box at OpenStreetMap's square corners hits walls. For gameplay-dev: keep buses to classes
  0-1 when there is a choice.
- check_drive's routes cover every deck and tunnel edge (17 routes) plus 3 outer-lane repeats;
  20 distinct structures don't exist on today's map.
- Clearing the lanes left out 169 benches, racks, columns and shelters, 408 parked cars, 34
  kiosks (< 30 m2) and cut 2.2 km of fences, walls, hedges and mapped guard rails where they
  stood in a carriageway or a lane (OpenStreetMap's fences across gates, a car park mapped over a
  street's edge). Some may be real (a gate's fence); the lane graph wins.
- LoD2 walls a metre into a lane (17 places, `lod2_open`) are drawn but not solid there; the car
  drives through the corner of the building (the lane is where OpenStreetMap's road is).
- R2 uses the surface model for road and rail decks only; footbridges keep the chain solver.
  The surface model also gives the 1 m bare earth (`SurfaceModel.ground`), not used yet for
  pins or approaches (the 10 m grid keeps the joints with the ordinary streets exact).
- Aprons blend the ground at 15 structure ends; a fill's (approach's or pit's) own ends were
  tried and dropped (their side edges made new steps).
- Not done in loop 3b (the triage's 3b row and item 9): done in loop 3b-2 (README "Loop 3b-2"),
  except medians on two-way roads (none mapped on today's map, under "From v0.75").

## From loop 2c (car models)
- **Parked cars are one shape** (a small saloon, `models.gd` `parked_mesh()`, 40 triangles): the
  traffic's kinds would need a MultiMesh per kind per 512 m tile (+1 draw call per tile in view,
  per pass) or `foliage.gdshader` (outside this loop) learning the actors' shape morph. The three
  512 m tiles round the spawn hold ~550 of them, so they stay cheap. Default: one shape, the
  traffic's paints.
- **The prebuilt city.scn held the old parked boxes** until loop 3b-2 re-baked it (now native,
  no red; `foliage.gdshader`'s red remap removed). `main.gd`'s `Models.renew_parked` swap is
  harmless now and can go in a main.gd loop.
- **Police and guards** (`Models.police_mesh()`, for loop 3g): one family, shape 0 the patrol
  estate (paint `POLICE_WHITE`), shape 1 the guards' car at 0.88 (paint `GUARD_MUSTARD`), so 3g's
  POLICE kind can draw both in one MultiMesh. The light bar's lamps use BLINK (alternating by
  UV.y): they glow and blink only when the city's lights are on; a daytime chase needs police.md's
  SIREN part, whose code must be **9** (8 is the player's HERO since the look loop), driven by the
  instance's custom data, not by UV.y. "POLICJA" reads from ~6–15 m views only (5 cm pixels).
- **Podwózka shares the TAXI MultiMesh** (pool 16) with the city taxi, half each (~5 % of cars
  each on main and secondary roads): parodies.md planned a kind of its own (pool 12, +2 draw
  calls) for loop 2d; as a shape it costs nothing. 2d's GPS moments can key on `shape == 1`.
- **Mirrors were left out** (one image pixel at the 80 m view); the player's car has round head
  lamps, a spoiler and hub caps instead, which read zoomed in.
- `check_water.gd` 5a counted every roof refusal as "refused on dry land" (5517) after sweep 1
  gave that refusal an English line; it now tells the water's by its words. `verify.sh --quick`
  doesn't run the water steps, which is how it slipped through.
- DEMO.md row 10 asks "≤ +20 % vertices for vehicles": a model grew more than that (a traffic
  car 144 → 194 triangles, a van 144 → 228, the player's 240 → 292), but the pools now draw only
  the cars in use, so the frame's triangles fell at the default view (README "Loop 2c");
  README's per-model caps (≤ 800, ≤ 3,000) were followed.
- The bus has doors on its right only; the tram cars on both sides (Warsaw's newer trams are
  two-sided).
- A traffic car's shape is picked by its own random stream, so where and which kind of car
  spawns is as before; its size (and the gap it keeps) is now the shape's.

## From loop 3b-2 (map art and road details)
- **The main checkout's Godot class cache had lost Phantom Camera's classes**
  (`game/.godot/global_script_class_cache.cfg` held only DebugDraw3D, dated before this loop):
  every Godot step of `verify.sh` failed with "Could not find type PhantomCameraHost" until
  `godot --headless --path game --import` rebuilt it. Worth a line in the verify-game skill (or a
  check in verify.sh) if it recurs after merges.
- The natural/built split is OpenStreetMap's: a stretch of the west bank south of Most
  Poniatowskiego reads natural (no promenade or wall mapped along it), the park ponds with grass
  banks get a dark-earth band; `bake_banks.py` prints the km and `shots/loop3b2/ov_banks_overview.png`
  shows them over the photo. If the art director wants a third kind (riprap, timber), the
  classifier has the place for it.
- The beaches are only sand where OpenStreetMap maps sand (Poniatówka, Plaża Saska, the shoals);
  elsewhere the bank is the bare ground's colour with the wet bands.
- Sandbars stay river for the car and the helicopter (water.bin unchanged): a car can't reach
  one and the helicopter won't put the car down on one. The sandbar rescue's place (a sandbar
  outside the drawn river, the POI bake) is unchanged.
- Kerbs are felt at street level only (not on decks or in tunnels), and pavements are not raised
  (only the kerb's hop); the player's car only (traffic and rivals follow their lanes).
- Joined deck gaps keep the parapet's collider on each piece's edge (with a low kerb drawn there),
  so the car can't drive across from the road deck to the tram bed on Most Poniatowskiego; the
  gap's slab is drawn, not driveable.
- The spiral rule (3+ lanes, radius 25 m+) also caught the 4-lane ring by Centralna at
  (-1505, 695); Warsaw paints its big rondos that way, but it wasn't checked against the photo.
- 8 mapped pavements by Centralna and the Jana Pawła II viaduct lie under road decks (not on a
  footway deck) and stay on the ground; they look right in the shots, not checked one by one.
- The runtime city build is ~2.4 s slower (8.3 → ~10.7 s: the areas, footways, cycle paths and
  steps clipped to the grid's cells, in GDScript); the prebuilt city (the phone) is unchanged at
  0.9 s. A faster clip (whole runs of cells along a strip) is possible if the Mac's build time
  matters.
- The sand gap fills (`bake_banks.sand_gaps`, up to 6 m) also bridge a few gaps that are real:
  a path mapped only as a line between two beach polygons now has sand under it (its own strip
  is drawn on top). check_drape's footway part allows 2 m2: one footbridge ramp at (-18, -281)
  ends 0.46 m under the park it lands in (the deck solver's end, not the drape's).
- The chevrons' direction (points towards the oncoming traffic) follows the Polish P-21 drawings
  as remembered; if they should point the other way it is one sign in `bake_roads._hatch_flow`'s
  caller (`flow < 0` flips).

## From loop G1 (device tiers and the frame governor)
- ~~**The first rescue call's arrival is a hitch**~~: 61 ms on the iPhone 11, 100–117 ms on the Pro
  Max (one frame, 3–6 refreshes), 60 s into play (`missions.gd` `_ring`, the context button and
  what comes with it; the BENCH minute's "3 pipeline compilations" may be it). The BENCH minute
  now holds the call clock, so cards don't show it; play does. Gameplay lane: warm the call's
  pieces up at the start, or build them a frame or two before they show.
  Sweep 2: on the Mac the call is 0.3 ms of script (pill 0.02-0.06, toast 0.27-0.37 ms), no
  pipeline compiles (85 before and after) and an ordinary frame (8.3-8.8 ms against medians of
  8.35-8.39, uncapped, Mobile, 2868×1320); the only part that differs on the phone is the buzz:
  Godot's iOS template builds CHHapticEngine on the first `vibrate_handheld` (initAndReturnError,
  auto-shutdown on) and starts it inside that player's startAtTime. Fixed at that cause, unproven
  on the phone: missions.gd `warm_haptics` builds and starts the engine (without waiting) at
  load and 2 s before each call; the log shows `haptics: engine built and starting in N ms` and
  `rescue call ringing (buzz N ms)`. If the call still hitches on the phone with a buzz under
  a millisecond, the buzz wasn't it: time `_ring`'s pieces there. Other buzzes (bumps) after a
  long quiet may still restart the engine inside their frame (auto-shutdown).
- **The iPhone's frame pacing has two modes per launch**: the main thread waits for the display
  inside "draw" (11.6 ms of it, frames jittering 1–8 ms either way, 1.6–16 % of frames over
  17.7 ms with every refresh still drawn) or outside the frame's phases ("draw" 1.1–1.9 ms, no
  jitter). Which one varies by launch, at either image size. Harmless to the eye as far as the
  numbers go (no refresh missed); it made "draw" useless as a GPU reading and "% over 16.7 ms"
  useless as a stutter reading, hence the missed-refresh count.
- **The orchestrator's 25 fps 1 % low at ×1 didn't come back** in nine runs on a cool iPhone 11
  (thermal state nominal; ×1 held 60 with 0 missed refreshes for 3 minutes). It was probably a
  warm phone or the first call's hitch inside the minute. G0's 20-minute SOAK on the iPhone 11 at
  Auto (High ×2) is what proves the heat margin.
- **The GPU's time on the phone** comes from `xcrun xctrace record --template 'Metal System
  Trace' --device ID --all-processes --time-limit 6s` while a `--probe` runs, then `xctrace
  export --xpath '…/table[@schema="metal-gpu-intervals"]'` and `gpu-performance-state-intervals`
  (the A13: Medium state 95 % at ×1, Minimum 99.9 % at ×2). Attaching by name or pid fails on
  both phones, and starting the trace stalls the app ~11 s on iOS 27. G0 should script it.
- The governor's GPU levels hold only two things today (reflection steps × 0.6, then the small
  things' shadows); G2–G5's extras (FX count, lamp cones, dusk glow) join them as they land.
  Glow at night stays out of it (the night lights).
- The view rule takes the small things' shadows off in views over 150 m and in the helicopter
  (0.4 % of pixels from the helicopter at 2868×1320; shadow pass −11 to −15 draw calls). A
  zoom across 150 m switches them at once (no fade), masked by the zoom itself.
- `--stress=wait:N` busy-waits in the draw phase: on the phone it shows only from N ≈ 40 (20 ms),
  because the wait for the display shrinks to make room. G0's `--stress=gpu:N` (real GPU work)
  is still to build.
- The SE 2 / 3 (1334×750, 1.0 MP at ×1) land at ×2 (667×375) at High, by 4 % over High's
  budget; nobody has run them. The 11 Pro and 11 Pro Max (A13, ×2 at 0.68 / 0.83 MP) keep their
  ×2 image at High: the same GPU as the iPhone 11 with twice its ×2 pixels, unmeasured.
- Mac windows over 0.96 MP at a scale of 1 (e.g. 1366×768) now draw at 2 at High.

## Decided in loop G1 (perf-engineer defaults; the user may still change them)
- The iPhone 11 at High (and so at Auto) draws 896×414 (×2), as the brief asked; ×1 (1792×828)
  is Ultra on that phone (it held 60 on a cool phone, at a higher GPU clock). **Loop G1b:** the
  user chose ×1 under Auto (High's effects) with a ×2 fallback; Wysoka stays ×2.
- Ultra is High + the 4096 shadow map + 16 reflection steps; Auto picks it on A17 Pro and newer
  (and the 16 / 16 Plus, A18), the 16e stays High (4-core GPU). The iPhone 17e's id isn't in the
  table (unknown → treated by its family: `iPhone18,x` → Ultra).
- A saved "High" from before G1 becomes Auto once (the file then carries `tiers=1`).
- The governor counts missed refreshes, not frames over the interval + 1 ms (the card shows
  both); a raise needs under 0.5 % missed over 30 s.
- The BENCH minute holds the governor (the card is the level's own cost) and the rescue calls;
  `--governor=on` lets the governor act during a bench or probe.

## From loop G1b (Auto's sharp image with a fallback)
- **The ×1 drive was by day only**: 17.7 minutes of autopilot, traffic Normal, at room
  temperature, 60.0 fps every minute, 5 missed refreshes, no governor change. Night, rain at
  night (the river's reflections, glow), Busy traffic and the helicopter at ×1 are unmeasured,
  and so is a warm room; G0's 20-minute SOAK (DEMO H3) should now run at Auto = ×1 on the
  iPhone 11, since that is the default. Every content loop (2d, police, 3c streaming, G2) now
  costs the iPhone 11 its sharp default if it pushes the A13 over: its bench at Auto ×1 is the
  number to watch.
- **Nobody has run the SE 2 / 3 at Auto**: since G1b they draw 1334×750 at ×1 (1.0 MP, the A13 /
  A15 with fewer pixels than the iPhone 11's 1.48 MP), with the same fallback. The iPhone 11 is
  the only phone measured at ×1.
- **The fallback is per launch, never live**: a session that struggles keeps its sharp image
  until the next launch (the governor's extras guard it meanwhile), since switching the pixel
  size mid-drive is a visible pop and reallocates the image. If a long first session on a hot
  phone turns out to look bad, a live switch at a natural cut (a load, the settings panel, the
  helicopter) is the next step.
- ~~**No toast** says the fallback came in (the brief made it optional): the Obraz tab's
  `auto · High ×2` and the `quality:` log line say it. A one-time toast ("Obraz prostszy, bo
  telefon się grzał · A coarser picture: the phone was struggling") is a game-designer call.~~
  Built (2026-10-30): a one-time toast at the first fallback launch, wording in QUESTIONS.md.
- **Thermal state** is still not readable from Godot 4.7.2 (checked: no OS, DisplayServer, Engine,
  RenderingServer or Performance method); graphics.md 4.4's plugin would add it to the struggle
  rule as a third signal.
- The Mac counts too: a window under 960 lines over 0.96 MP (1366×768, 1440×900, the shots'
  1792×828) draws Sharp at ×1 under Auto since G1b (screenshots at 1792×828 show the iPhone 11's
  sharp look; `--last-session=struggled` shows its fallback).

## Decided in loop G1b (perf-engineer defaults; the user may still change them)
- **Struggled** = GPU extras down (GPU-bound drops only, outside wide views) for 60 s and a tenth
  of the counted play, or 3 counted minutes in a row over 2 % of refreshes missed GPU-bound.
  **Calm** = 3 counted minutes without that. Counted only at Auto's sharp image or its fallback,
  past the settle, outside loads, pauses and wide views.
- **Back-off**: 2 calm sessions at the fallback, then the sharp image on trial; a struggle on
  trial doubles the wait (to 16); a passed trial (as many calm sessions as the wait) resets it
  to 2; a struggle at the fallback restarts its count.
- The Auto button's English line reads `auto · High ostry` (the brief's wording; "ostry" is the
  Sharp style's Polish name, on the row above) and `auto · High ×2`.

## From loop 3g-1 (the police, part one)

- ~~**Part two (loop 3g-2)**: the guards, the guard car, the zone cap and the clamp, the escort,
  the race and side-job ties, the sounds, the first contact, the `police_escort` and `guard`
  lines.~~ Done in loop 3g-2 (Phantom Camera's chase framing stays: the camera is the driving
  lane's).
- **PixelLab assets for part two** (police.md section 9, ≤ 38 generations): the three 64 px
  portraits (Sierżant Bogdan, Posterunkowy Kacper, Strażnik Henio; the card draws simple faces
  now), the 24 px rooster icon lit and outlined (the koguty draw light-bar domes now), the 24 px
  lizak (drawn as discs now), the 16 px hair-dryer minimap icon (a small blue mark now).
- **Trap spots in the bake** (loop 3d): `pois` kind `trap` replaces `game/data/police_traps.json`;
  spots 5-7 come with the demo area. The Wisłostrada trap sits on `graph` edge 502 at the
  carriageway named Wybrzeże Kościuszkowskie, east of police.md's guessed x 400-650 (that stretch
  is the tunnel), and 40 m north of the cross-city rail bridge, which hid the officer.
- **The parked trap car's kerb offset** (outer lane's edge + 1.5 m) is from the lane graph; where
  the drawn carriageway is narrower than its lanes the car stands half on the road, where a cycle
  lane runs by the kerb (Wybrzeże Szczecińskie) it stands on the cycle lane. Loop 3d's `trap` POI
  should carry a spot checked against the kerbs.
- **The officer's legs swing** (the guards' too, loop 3g-2) like a walker's (the people's shader swings every instance's legs;
  the swing is about one image pixel at 80 m). A standing pose would need a constant in
  `actor.gdshader` (part two, with the guards). (Loop MW-3's crowds stand still without a shader
  change: their own copy of the material with `walk = 0`. The trap officer and the guards ride the
  walkers' MultiMesh and still swing; moving them into a still MultiMesh is +1 draw call.)
- **The trap's car turns round when it pulls out** (it parks facing the traffic, as police.md
  asks, and joins its lane the traffic's way; the turn takes ~10 frames behind the passing car).
- **The 2D pass**: the minimap's marks are now one triangle array (they were a draw call each);
  the rival dots, side-job places and target look the same. The pill (a panel and two labels) is
  three 2D draw calls while shown.
- **Memory**: Dialogue Manager's scripts are ~4 MB of static memory, loaded at the start (on first
  use they were a ~70 ms hitch on the Mac, likely ~0.3 s on the phone, as the card opened).
- **The soak's B4 check** logs the car's place on screen each second during a chase; the camera
  follows the car, so it stays near the middle (closest to an edge 0.46 of the screen in the soaks).

## From loop 3g-2 (the police, part two)

- **Phantom Camera's chase framing** (police.md 11.3) is still owed: the camera is the driving
  lane's.
- **PixelLab assets** (above) still owed: the PixelLab server wasn't connected in the cloud
  session; Strażnik Henio's face on the card is drawn from shapes (mustard jacket, round glasses).
- **The guards' trousers** are the people's near-black palette entry: police.md's dark red needs a
  palette entry in `actor.gdshader` (visuals lane), and so does a standing pose.
- **The guard posts** live in `game/data/police_guards.json` (four posts, two guards each) until
  loop 3d's `guard_post` POIs; the Krakowskie Przedmieście zone in today's map is only the
  pedestrian way's ~8 m strip, so the cap there holds only on that strip.
- **The escort waits at the hospital's lane-graph node**, which can be 100-200 m short of the
  hospital's ring when the hospital sits back from the road (rescue 9: ~180 m); it leaves when the
  rescue ends. A node nearer the door (or the ring's own edge) would bring it to the door.
- **The escort in Normal traffic** keeps behind the cars ahead like a chaser (it doesn't push
  through): on a crowded road it can sit at 18 km/h for a minute (rescue 9 failed by the clock in
  one headless run with traffic; it made it with the road empty). Cars ahead giving way to a light
  bar (3g-1) is the traffic lane's; check on the phone whether it needs more.
- **The speech bubble's tail** can't reach a guard right next to the car: the bubble steps aside
  from the car and its tail points at the bubble's edge (the bubbles are shared with the police).
- **The clamp box** (a yellow box on the front left wheel, +1 draw call while shown) is a few
  pixels at the default zoom; the card says it.
- **Pedestrians stepping aside** from a car in the zone (police.md 5.6) is not built: the walkers
  are the city lane's.
- **The first contact** is its own parked car 150 m ahead (not one of the day's traps): the lizak
  log line names it "trap 0".

## Decided in loop 3g-1 (gameplay-dev defaults; the user may still change them)

- police.md section 17's open questions went with the spec's defaults (the brief): +15 respect
  for an escape; the helicopter allowed mid-chase and ending it; guard colours mustard and dark
  red; no roof marking; seven trap spots.
- **The start grace ends once the police have met the player** (a chase or a pull-over), so a
  scripted chase isn't followed by 3 minutes in which a ram can't start one. police.md says only
  "in the first 180 s of a session".
- **A second unit raises the level only after the level has held 5 s** (*guess*): a patrol that
  happens to be near when a chase starts would otherwise make it koguty 2 at once.
- **Patrol pacing**: 90-180 s after a patrol you met leaves the band, 10 s after one you never met
  (police.md gives only the count per Traffic level; with the band alone, two patrols would be
  in view all the time at Normal). They spawn ahead of a moving player.
- **The pedals step aside during the pull-over** (the car is held; the card needs the bottom of a
  375 pt tall screen).
- **Megaphone lines** keep the 20 s per unit of police.md, so the "every 10 to 12 s" chase lines
  come every ~20 s from one chaser.
- **The halos** are 5 m pools, blue at full and red at 0.8 brightness (4 m at half read too faint
  at night in the shots).

## From loop 3c (sector streaming on today's map)
- ~~**Adding a MultiMesh node costs the main thread 0.1–4 ms** on the Mac, whatever its instance
  count~~ Fixed in loop G0+: the cost was **physics interpolation** (on project-wide; the sectors
  inherited it). On the iPhone 11 a MultiMesh add cost 14 ms on average (37 ms at worst), a
  sector 188 ms, 490 frames of a 6-minute soak over the 3 ms budget and the governor dropped to
  GPU 0/2 · CPU 0/2; with `Sectors` and `Proxies` set to `PHYSICS_INTERPOLATION_MODE_OFF`,
  0.002 ms and 0.35 ms, 0 frames over budget, 0 governor changes (README "Loop G0+").
- **The AO, lamp-light and surface maps stay one texture each** (24 MB of video memory today,
  ~150 MB at the demo's 6 × 6 km). Per-sector slices can't be per-sector material uniforms:
  the post pass's water reflections and the moving vehicles sample the light and surface maps
  anywhere on screen. Loop 3d: a resident window texture (e.g. 2048 m at 1 m, ~20 MB for the
  three) composed from per-sector slices on a worker thread when the focus moves half a sector,
  uploaded one map a frame, the rects updated with it; or a texture array with a slot per loaded
  sector and an instance uniform (a shader change in ground, building, foliage, actor, poster,
  post).
- **Resident memory at the spawn**: video 336 → 263 MB (−22 %), the city's own buffers 158 →
  86 MB; static 140 → 140 MB (the index's game data, 32 proxies and the per-sector nodes and
  colliders cost what the whole city's unloaded part saved; `--sectors=all` is 165 MB static).
  The brief's "≥ 30 % lower" holds for the city's own share (~155 → ~85 MB), not the process.
  Loop 3d: the index's game data (roads, paths, areas, trees3d as Variant arrays of floats, ~20
  MB) should move into the sectors or packed arrays; the minimap into the pre-rendered image.
- **The runtime path's start** (5.7–6.0 s, was 10.9): ~2 s is the roof pass over every
  sector's file (missions, eggs and the helicopter read the roof grid over the whole map at the
  start). A cached roof grid (written by bake_city, checked against its inputs) or a lazy one
  would make it ~3.8 s; at the demo's 144 sectors the pass alone would be ~9 s.
- **Residual pixel differences** (≤ 0.2 %, at most 0.015 % at 2868×1320): the minimap's random
  markers (job offers), and a few sun-shadow edge pixels where fewer sectors are loaded (the
  directional shadow fits its depth range to the casters it sees).
- **Proxies** are a lag cover (shown only while a sector loads, or with `--sectors=proxies`):
  one wall and one roof colour, landmarks tinted. With the view test counting each sector's
  tallest roof, the far view loads sectors in full rather than showing proxies; at the demo's
  size the helicopter may need a cheaper far tier (proxies in view past ~1 km).
- The streamer's worker is a `Thread` per sector, not WorkerThreadPool: a GDScript callable run
  on a pool thread leaves one RefCounted per pool thread at exit (`ObjectDB instances were
  leaked`), which `tools/verify.sh` reads as a failure; a joined `Thread` doesn't.
- ~~The sector files and the prebuilt sectors are committed~~ Loop 3d-1 (the user's decision,
  2026-10-29): no longer committed (the pack grew 194 → 340 MB in a day of re-bakes); a fresh
  clone runs `tools/setup_map.sh` once, freshness is by content (README "Map data").

## Decided in loop 3c (map-engineer defaults; the user may still change them)
- The split is a new `tools/bake_sectors.py` after the chain (bake_osm.py is unchanged); the
  margins are 48 m for ways, areas and buildings (a road's reach), 8 m for point things, plus a
  floating part's supports and each building's shop-sign surroundings.
- The view needs a sector when its box up to its tallest roof meets the frustum, grown by 128 m
  (DEMO 2.4 said the ground footprint): no proxy ever stands where the whole city had detail.
- `--monolithic` keeps the whole-city build as the reference; `city.scn` is removed.
- The minimap stays one global mesh (brief item 7).

## From map review A (bridges, flyovers and tunnels, 2026-10-29)
- **Aprons sink the road under the drawn ground** at structure ends where the 10 m grid stands
  above the end's height: `terrain_height` lowers the ground there (`min` under an apron), but
  `_build_ground` draws the raw grid, so the road, its carriageway area, kerbs and rail beds lie
  under the ground mesh: the viaduct's west end (road 52 m², up to 0.65 m, the beige wedge on the
  westbound carriageway at `--at=188,104`; tram 28 m²), the west abutment's north ramp foot (991, -2: 52 m²,
  0.25 m), the Kruczkowskiego rail viaduct's west end (394, -55: 45 m², 0.45 m), and the four
  tunnel portals (20-89 m², hidden by the trench walls as far as the shots show). Fix (bake, the
  default): the chain solver's lower bound at a deck's end = the highest grid value across its
  carriageway, so the end stands at or above the ground across its width and no apron has to
  lower it; or (builder, after loop 3c) subdivide the grid cells an apron touches with
  `min(grid, terrain_height)`, with the draped areas and footways in them following. A check:
  a drawn road or rail corridor more than 0.05 m under the raw grid.
- **Lamp pools under and beside decks at night**: `lights.bin` is 2D, so a deck lamp's pool also
  lands on the water and shoals beside and under the bridge (orange arcs on Most Poniatowskiego's
  gravel shoals). Fix (shader, after loop 3c): scale the lamp light by whether the fragment is
  within ~2 m of the deck height `water.bin` already holds for that pixel.
- ~~**Most Poniatowskiego's approaches are unlit at night**~~: fixed in map round 2 (D7: lamps along a
  structure's approaches every 20 m); checked at night 2026-11-03.
- **Rail tracks ending at different heights**: at the Solec viaduct's west end one track's deck
  starts 1.2 m under its neighbours (piece of OSM 1480623763), at Kruczkowskiego 0.5 m (each
  track's measured R2 profile). Fix: hold the parallel tracks of one deck group to a common
  profile at their ends.
- **The Tamka footbridge dips 2.2 m** 4 m from its north end (`--at=-20,-288`): an interior node
  shared with the footway under it is pinned to the ground. Fix: in the path family a node where
  a lower way passes under is a crossing, not a pin.
- **The Praga ramp's joint** (1493, -301): the ground strip and the ramp's strip meet at an angle
  and leave a ~3 m² sliver outlined by edge lines (C2 allowed). Fix: strips meeting at a deck
  joint share one end line.
- **Tram stop shelters** left out where mapped on the rails (14): place them on the stop's
  platform instead (the nearest `platforms` edge on the track's side).
- Most Świętokrzyski, the Jana Pawła II viaduct and the Wisłostrada tunnel end at the map's rim
  (the diorama's void beyond): the bigger map moves the rim past them (known, DEMO.md 4.4).

## From map review C (the streets against the orthophoto, 2026-11-02)
- **Fixed**: `bake_roads.py` `road_width`: a `lanes=1` one-way residential, unclassified or tertiary
  street (not a bridge or tunnel) is at least `DEFAULT_WIDTH` wide (283 ways widened); the legs of a
  street split round an island or a narrow median (another one-way the other way within 14 m along
  30 % of it, `mark_split_legs`, 222 ways) stay one lane. Zebras 12,215 → 12,701 m of asphalt.
  check_roads 0 not allowed, check_streets S1 0.
- **Fixed**: the bake crashed on main in `_blurred` (a joined bike path of one point); skipped.
- **Fixed (F said yes, 2026-11-02)**: two-way streets with `lanes=2` (residential, tertiary,
  unclassified; not bridges or tunnels) were 6.0 m and measure ~7.5 m over the photo: now at least
  `TWO_LANE_STREET` 7.0 m (423 ways). Zebras on the asphalt 12,701 → 12,982 m; medians unchanged; young Krajobraz trees on ul. Pereca by Skyliner no longer fit beside the wider carriageway (two trees).
- **Measured, open**: one-lane links (`*_link`, 3.25 m) read 4.5-5 m (shoulders); left, they ride the
  deck solver.
- **Alignment**: OSM sits on the photo within ~2 m everywhere looked at (Praga, Powiśle, Łazienki's edge,
  Muranów, map north); no street needed moving. Tram tracks, islands and junction shapes match.
- **Can't be judged from this photo**: lane lines, zebra stripes, kerbs and arrows. The demo's photo is
  0.87 m/px and not a true orthophoto (towers lean over the streets, deep shadows). Needs GUGiK's
  0.1 m tiles (the WMS answers 403 to the cloud and to the Mac's sandbox; the Mac's own shell may reach it).
- **Bakes in the cloud**: with the Mac's `data/work/demo`, `lod2.*`, `terrain.json` and the 1 m
  `data/raw/demo/gugik` copied in, the cloud's bake differs from the Mac's in small ways before any
  change (cycle paths 20,459 vs 20,460 pieces, a few walls and fills): a floating-point difference in
  `cycleways.py` / the structures, not traced.

- **Found on main, not fixed here**: `check_landmarks` fails on `bulwary_basen` (the splash pool): the
  helicopter at 6 m is not blocked over it (main's own centrum too, 2026-11-02). Also: a corner shop on
  car-free Złota (-831, 96) has its door on Złota in main's committed bake, but a fresh bake puts it on
  Zgoda (car_free runs before the street POIs); check_parodies' 80 % is now rounded down for that.

## From map review B (the streets, 2026-10-29)
- Lines inside junctions mapped without a junction-box area: ~1.6 km of edge line and 0.4 km of
  lane line lie inside the clusters of junction nodes (most at Plac Trzech Krzyży (-77, 670), the
  Poniatowski ramps (1381, -344), Wał Miedzeszyński (1514, -147)); measured, not yet checked
  against the photo one by one (many are a real edge line along a wide junction's side).
  2026-11-02: blocked in the cloud (mapy.geoportal.gov.pl and every other imagery host are refused
  by the cloud's network, and data/work/demo/ortho.bmp is Mac-only); the Mac brief is in QUESTIONS.
  Note for that pass: a cloud measure of lane lines inside crossing strips also counts Rondo
  Dmowskiego's spiral lines (real) and the multi-lane fans at Jerozolimskie/Plater, so judge by the
  overlay, not by metres.
- ~~At night Al. Jerozolimskie at (-615, 394) and Nowy Świat at (-331, 18) read much darker than
  Marszałkowska.~~ Fixed 2026-11-02 in `tools/bake_lights.py`: the lamps it adds on unlit stretches
  stood 34 m apart a side, so the pools (lit bands 9-12 m) left gaps on the wide avenues; primary and
  secondary streets now get one every 26 m (gap 16 m), Nowy Świat and Krakowskie Przedmieście are lit
  from both pavements (Nowy Świat was one side, the other side's spots fell inside the 22 m gap of
  the lamp across), and a kerb spot on asphalt steps out up to 4 m (Nowy Świat's parking bays).
  2004 → 2455 added street lamps (lamp posts are one MultiMesh: +0 draw calls). Share of the
  carriageway in a lit band at the review spots: Nowy Świat 52 → 88 %, Jerozolimskie 32 → 48 %.
  Open: a phone look at night on both streets; Jerozolimskie's far pavements stay dimmer than the
  carriageway (lamps stand at the kerb, 30 m dual carriageway).
- `check_streets` S3 also counts real median noses at a junction's edge (Świętokrzyska by Mariańska,
  18 cross-sections): reported, not failed.

## From loop 2d-1 (Podwózka, the app-taxi side job)
- **The pull-over is wired** (merge with 3g-1): `police.gd` `_talk_done` calls
  `rides.on_pulled_over()`; one star, verify step `ride-police`. 3g-2 may want its own opener for
  a pull-over with a passenger on board (police.gd `_opener` knows kebab and słoiki only).
- **The request card lost "your rating"** to fit beside the car on 390-pt phones (five lines of
  text above the pedals); the rating is on the result card. A request could show it on the
  PODWÓZKA button instead.
- ~~**Loop 2d-2 (after 3c's streaming)**: the `rechotka` quirk joins the random pool once the
  Frogs shops exist (was Rechotka 24; renamed 2026-10-30) (today it is flag-only and names a shop nobody can see), and the `detour`
  passenger (a stop at any Frogs, +½) needs them too; Pędzik, Leżak, the kebab stands and the
  billboards are 2d-2's; the `signs` and `column_posters` Podwózka lines (parodies.md 7) wait for
  the billboards.~~ Done in loop MW-2 (2d-2 folded in; "From loop MW-2"). `oldtown` falls back
  to a park until the map has the Old Town square.
- **PixelLab (not in this session)**: the Podwózka pickup icon (16 px), the "Nawigacja" avatar
  (32 px, it speaks as a plain bubble now), a believer and a student passenger portrait, the
  Podwózka billboard (parodies.md 9). The passenger figure is `props.gd`'s person with a hop and
  a bobbing "!" (2 draw calls), no waving arm.
- **River spots are few** (10, along Wybrzeże Kościuszkowskie and by Most Poniatowskiego): the
  river quirk only happens on rides from Powiśle and Solec (it must add at most 1.5 km). The
  waypoints are 30–70 m off the road across the boulevard; whether a player can actually drive
  there (steps, walls, benches) is unchecked: the autopilot ghosts through. Worth a look in the
  device pass; the map engineer could flag drivable promenade.
- **The ETA (road / 9 m/s + 20 s) is tight** with the lights: the test drive at 1.3× traffic
  speed took 178–190 s of a 195 s ETA. A careful player may often be late (−½ per 15 s). Tune on
  the phone with how long a ride feels.
- **Rivals' Centrum Nauki Kopernik finish lies on the map's north edge** (the landmark's
  centroid at 324,-879; the nearest node 328,-885): rides skip it; the race finish is probably
  odd too.
- **GPS moments on today's map are mostly "you have arrived"**: around the spawn the app-taxis
  drive dual carriageways (no U-turn), and the river moment needs the view by the river. A
  5-minute busy run at the spawn: 4 moments, all stops.
- **Driving penalties aren't measured under `--autopilot`** (the ghost's turns are steps, not
  driving); the rules are covered by `check_rides.gd`, the measuring copies the słoiki's.
- `hud.gd`'s context button is shared now (`pill_owner`: "call" or "ride"); a third owner
  (police?) should use the same `show_pill(pl, en, owner)` and `context_pressed`.

## Decided in loop 2d-1 (gameplay-dev defaults; the user may still change them)
- A rescue call ringing (WEZWANIE on the button) doesn't stop a ride request card; taking the
  ride puts the call off (90 s), as any job does. An ignored call would otherwise block rides
  for the whole session.
- A 4½-star ride keeps the 5-star streak (the spec: "below 4.5 or a cancel ends it").
- The tip is a share of the fare after the MNOŻNIK.
- Your rating counts the rides a save hasn't driven as 4,87, so one perfect ride makes 4,88,
  twenty make 5,00.
- The passenger gives up after 3 × the ETA in the pickup (the pickup's own ETA) and in the ride.
- The request card sits at the bottom, the result card top centre (the longest result didn't fit
  beside the pedals on a 390-pt screen).
- `podwozka_driver`'s two untagged lines are tagged `arrive` and `reroute` so each moment says
  its own; the offset pickup line ("the pin was a bit off") is tagged `offset`; "No widzisz,
  aplikacja wie" (the design's table) is a `followed` line.

## From map round 2 (2026-10-29)
- Done: D5 (the drawn ground follows the aprons; `check_roads` C11), the 14 tram-stop shelters
  beside their tracks (13; 1 with no clear spot), L3 (lamps on the main streets' unlit
  stretches), D6 (deck lamps light their deck only), D7 (the abutments lit). README "Map round 2".
- **Mapped lamps change colour along one street**: a mapped lamp whose nearest road is an unnamed
  way (a ramp, a service road) is LED by `bake_lights`' name rule even on a sodium street (seen on
  Al. Poniatowskiego by the towers). Fix: take the kind from the nearest *named* street within 14 m.
- **L1** (review B): lines inside junctions mapped as one carriageway area without `junction=yes`
  (Plac Trzech Krzyży, the Poniatowski ramps, Wał Miedzeszyński); orthophoto overlays drawn
  (`shots/review_structures/round2/ov_p3k.png`, `ov_ponir.png`, `ov_walm.png`), not judged or fixed.
- **D8** rail track ends at different heights (Solec 1.2 m, Kruczkowskiego), **D9** the Tamka
  footbridge's dip, **D10** the Praga ramp joint's sliver, **L4**, **L5**, **L2** (review B):
  not done this round; specs in `.handoff/review/structures_2026-10-29.md` and B's report.
- **The Podwózka river spots** (loop 2d-1 `rides.gd`, not merged): a waypoint 5 m in from the
  water, a straight line to a lane within 70 m over dry ground with no building. Not checked
  against the colliders yet: the line can cross a retaining wall, a shore stone, a fence or a
  boulevard's 3-5 m drop (the Bulwary below Wybrzeże Kościuszkowskie). Spec: a `drivable_bank`
  list in the index (bake_structures: dry points 3-8 m from the water whose straight line to the
  nearest lane crosses no solid wall, barrier line or shore stone and no height step over 0.5 m
  in 2 m), that `rides.gd` reads instead of scanning `shore_distance`.

## From map round 2b (2026-10-29)
- Done: the Podwózka river spots from the bake (`drivable_bank`, 19), the lamp colour along a
  street from a bridge, D9 (Tamka), L5 (Krucza), L1 judged and kept. README "Map round 2b".
- **Only 19 river spots** (most lines to a lane cross a guard rail along the Wisłostrada and
  Wybrzeże Szczecińskie, a retaining wall or a boulevard's drop): river rides cluster by Most
  Poniatowskiego's west abutment and south of it. More need a way in (service roads to the
  beaches) or a passenger who walks the last metres.
- **L4** Emilii Plater's three mapped median walls (`barrier=wall`, 41 barrier pairs over the map
  cross each other twice or more) still weave as dark lines; the orthophoto can't show low walls.
  Spec: draw a `barrier=wall` inside a median as a 0.4 m planter edge, or leave weaving walls out.
- **L2** kerbs within 0.9 m of a lane centre: not judged (kerbs are not solid for traffic,
  `check_drive` 0); spec as in review B.
- **D8** rail track ends 1.2 m apart (Solec) and **D10** the Praga ramp joint's sliver: as in map
  review A's specs.

## From loop 3d-1 (the demo map, the 18.6 km² box, 2026-10-29)
- ~~**Loop 3e's structures, all allowlisted with place and reason**~~ Loop 3e: W-Z's tunnel and
  portals, the Wisłostrada's portals (and the two Wybrzeże Kościuszkowskie steps), Plac Na
  Rozdrożu's tubes, Wiadukt Markiewicza and the Copernicus building done; what is left is in
  "From loop 3e". Was: **Loop 3e's structures, all allowlisted with place and reason** (`tools/check_roads_allow.json`,
  `tools/check_drive_allow.json`, README "Loop 3d-1"): Trasa W-Z's tunnel and portals (Aleja
  Solidarności, Grodzka, Nowy Zjazd, the tram's abutment), Trasa Łazienkowska's trench at Plac Na
  Rozdrożu (its ways are layer -1 with no tunnel tag: a cutting the grid doesn't show; 0.3-0.8 m
  height steps a frame in its tunnels) and its interchange with Czerniakowska, the Wisłostrada
  tunnel's north portal under the Copernicus Science Centre, Most Śląsko-Dąbrowski's Praga end,
  Wiadukt Markiewicza, the railway cutting west of Centralna (Żelazna, Towarowa, Kasprzaka and
  their footbridges, whose stairs aren't mapped), the Praga viaducts by the zoo (0.1-0.7 m short of
  the clearance).
- **The new 10 m grid moved the old map's ground** (the demo fetch samples the NMT 3.5 m east and
  5 m south of the old grid's nodes; ±0.7 m at p1/p99, up to 3 m on embankments): 27 allowlist
  entries no longer matched and went, new ones came, and two main-road spots now step: Wybrzeże
  Kościuszkowskie by Tamka (625, −453) 2.4 m in 6 m and (642, −548) (~~fixed in loop 3e: the
  Wisłostrada's south portals on the 1 m trench floor~~). A rule for a road's end on a
  hump of the grid, or the 1 m NMT along the river (one download, ~125 MB for the whole box,
  DEMO 3.1's optional line), would fix the class.
- ~~**The AO, lamp-light and surface maps** are 37 + 37 + 19 MB (93 MB of video memory as whole
  textures; the probe's textures 24 → 87 MB). Over the brief's 60 MB, but a window kept in RAM
  saves nothing on the iPhone's shared memory: it needs per-sector slices read from disk as the
  focus moves (the streamer's job, where the perf loop works now). Loop 3d-2.~~ Done in loop 3d-2b:
  per-sector slices in 24 array layers, textures 94 → 38 MB, video at the spawn 406 → 300 MB.
- **Static memory at the spawn 147 → ~220-315 MB** (the index's game data: roads, paths, areas,
  trees3d as Variant arrays, now 3× bigger; index.json 9.6 MB): packed arrays or per-sector game
  data (3c's note). Loop 3d-2.
- **The runtime path's start**: the roof pass over 88 sector files (3c measured 2 s for 32) and the
  monolithic build (`count_vertices.gd` 36 s): a cached roof grid. Loop 3d-2.
- ~~**Most Łazienkowski is cut by the east edge** (x 1,773 mid-river)~~ **Settled 2026-11-02**: the
  box's east edge is 21.056 now (x 2,182), so the whole river crossing is in the map (the main
  deck runs x 1,306-1,976); only the Praga approach viaducts over Wał Miedzeszyński (deck groups
  9-11) end at the outline (x 2,182, z 744-934), where the edge roadworks (PR #309) close them on
  the deck. No change; taking the Praga end in whole needs a fetch past 21.056 (not planned).
- **Speed traps 5-7** (`tools/bake_traps.py`): Warsaw's blocks give straight runs of 157-195 m
  (police.md asks 250 m with no junction within 80 m: the officer stands mid-run, the junctions
  78-98 m away); trap 6's road is named Aleja Armii Ludowej in OSM (radio phrase unchanged),
  its graph speed 79 km/h. police.md 13 wants them as `pois` kind `trap` in the bake.
- **Pedestrian zones**: `ped_zones` (83 polygons, the Old Town box) and the 20 km/h cap are in;
  the pill, guards, clamp and the guard car (police.md 5.6) are loop 3g-2's; Łazienki and the
  boulevards (police.md 13) are outside the box or need their own `PED_ZONES` line.
- **Scanned crowns into decks** (C9, 4 places: by Most Świętokrzyski's pylon one 15 m tree
  reaches 8.9 m into the slab at the 0.40 floor of trim_crowns): leave such a tree out, or let the
  floor go lower.
- **Police P3 on the demo map** (fixed): the test escape's random turns looped back past the
  chaser's side, a traffic patrol saw it within 60 m at 20 s (the second-unit rule: L2, cap 40 s)
  and the escape came at 34.2 s. The test autopilot (`--police-auto=escape`) now rides a route to a
  node ~900 m away from the chaser (`police.gd` `_escape_route`): escaped after 23.2 s at L1.
- `verify.sh` kebab: 15000 frames (order 0 goes 1,023 m on the demo map, delivered at 219.8 s).
- **CI after the merge (2026-10-30)**: the map is no longer in git (lod2.bin alone is 87 MB), so
  GitHub's `verify` job runs only the steps that need no map (steering, settings, tiers, governor,
  hud, rides, sfx, radio, police); the map, road, drape and drive checks and the game runs stay on
  the Mac. To bring them back: a release asset with the derived pack that CI downloads, or a small
  test map. `shots.sh`'s `settings_panel` shot is MISSING (the paused game never reaches the shot
  frame): a shot-script issue, not the map.

## From the Mac pass (2026-11-03)
- **Oboźna's lane edge steps (C8)**: 0.77 m within 4 m at (-184, -605) and 0.50 m at (-97, -623), on the
  slope down to Powiśle; the same on a fresh bake of origin/main, so not from the junction-median change.
  Allowlisted in `tools/check_roads_allow.json` with this reason; judge on the 1 m terrain.
- **check_gamepad P12** ("the full map's hint doesn't speak of the pad") fails on the merged main code
  (2026-11-03), not from this PR: the full map's hint text needs its gamepad wording back (gameplay lane).

## From loop 3e (the structures, 2026-10-30)
- **Most Łazienkowski's Praga end and the Czerniakowska interchange (R8)**: ~~where two ramps of one
  deck group part, a ramp's guard rail runs into the other's lanes~~ **Fixed (the joins loop,
  2026-11-01)**: `bake_structures.py` `_clear_guards` also cuts a deck's guard rail where a bus box
  (check_drive's 12 x 2.6 m, placed every metre on the main roads' deck lanes, `BUS_BOX`) would touch
  it, not only within 1.4 m of a lane or 8 m of a deck's end (+100 m of rails cut over the map; check_drive
  `--no-allow` 51 → 26 lane spots with the other fixes). **Left** (the rest of the 26 lane spots, allowlisted with
  the reason): the loop ramps' R about 25 m bends on 4 m slabs (the 12 m box swings 0.7 m out into the
  deck's parapet, `map_builder.gd` `_build_bridge_structures`), the neighbouring piece's slab at the
  joint of the ramp group's pieces (slabs 0.3 m apart in height at (2116, 811)) and the ground gap lane
  (edge 4250) between the loop ramp and the main deck: a 0.8 m step at (2125, 805). Spec for it: each
  ramp's slab from its own piece, cut where another piece's lanes run, lanes sampled on their own piece.
- **The rail cutting west of Centralna** stays on the 10 m grid (C3 72 under its footbridges and
  Żelazna/Towarowa, Towarowa's deck joint 0.3 m). On its 1 m level (the WKD 7 m under the grid) it is
  24,000 m² of 1 m ground sub-cells (+0.5 M vertices), and its 8 m service bridges are shorter than
  the cutting the 1 m data shows. Needs the ground cut along a corridor (below) and "a way that
  crosses a cutting with no shared node holds its own level over it".
- **The ground cut along a corridor**: the trenches lower the drawn ground in 1 m sub-cells (633
  cells, +0.89 % vertices); the deck seeds (every structure's way) would fix Nowy Zjazd's pits and
  ~40 abutment findings more for +0.4 M vertices. Draw a lowered corridor's floor as one strip and
  clip the grid's triangles round it (a few triangles a cell) instead.
- ~~**Plac Na Rozdrożu's tubes end short of the street over them**~~ **Fixed (the joins loop,
  2026-11-01)**, but not by extending the tubes (no way crosses an open road within 15 m of a portal
  in the data): the 9 lane spots at the west portals were a trench wall (`place_walls`, the cutting
  profile of footway 127683235) whose foot stood 2 m under the tube's mouth at (45, 1641); a trench
  wall no longer stands inside a tube's mouth. C8 2 and C1 1 stay allowed (they are the cutting
  profile's 0.6 m steps at the rim, (−134, 1705) and (3, 1619)); check_drive's 4 jumps at the rim
  (−143, 1719) stay allowed too.
- **Joins follow-up (2026-11-02, cloud)**: `check_landmarks` Warszawa Stadion and Elektrownia Powiśle
  failed the helicopter test only because it aimed at the box middle (open air): it now aims at the
  tallest cell (the check, not the map). `check_places` WARN for most_slasko_dabrowski (65 m from a
  lane) fixed by moving its `near` onto the bridge. The three geometry leftovers below were NOT
  touched: the cloud has no terrain.json, so `drop` (the parapet collider's test) and the deck
  heights differ from the Mac and check_drive cannot confirm a fix there; do them on the Mac.
- ~~**Wybrzeże Szczecińskie's deck over the Port Praski inlet (deck 4)**~~ **Fixed 2026-11-03 (Mac):** the bus
  hit OSM `barrier=wall` lines mapped to the kerb at the deck's at-grade ends, not the parapet; `bake_structures.py`
  now cuts barrier lines in a deck road's corridor where the deck runs below ground + `BARRIER_TOP` (2.5 m);
  check_drive `--no-allow` 9/28 → 7/21 (also the fence at deck 76's ramp end, (2118, 743)). Was: by Most Śląsko-Dąbrowski's
  Praga end: a bus on the outer lane at its west end brushes the neighbouring piece's parapet (the
  gap between pieces keeps a collider where there is a drop): ~~6~~ 2 places left ((409, −1519) and
  (426, −1519), 6 spots: the 2 of them at the lane edge 1272 went with the wall change, not with a
  fix aimed at them; the rest is `map_builder.gd`'s parapet collider, 0.7 m inside the slab's
  edge). The footbridge to Karowa (deck 21 now, mapped `living_street`) still ends 2.2 m in the
  air at its Praga end, (304, −1554) (C6, allowed): its deck is smoothed to DECK_GRADE 6 % and its
  last 20 m cannot reach the ground; it needs stairs or a longer ramp (the solver pins a road
  family's lone end to the terrain but the 6 % smoothing wins).
- ~~**Nowy Zjazd under the W-Z approach**: a bus on its inner lane brushes the tram approach's 0.6 m
  side wall at (−357, −1419) (6 lane spots).~~ **Fixed (the joins loop, 2026-11-01)**: a low wall no
  longer stands where a lane runs at its foot (`place_walls` `in_lane(..., top - WALL_MIN * 0.8)`:
  the lane's ground is a WALL_MIN under the wall's top, not half a metre).
- **check_drive's routes**: 98 now (every deck group and tunnel both ways); they found jumps at Most
  Poniatowskiego's north ramps (deck 13: 0.4-0.6 m at (920, 16) and (988, −13)), allowed with that
  reason.
- **The W-Z tunnel's trams**: OpenStreetMap's tram tracks through the tunnel are not drawn (tram
  tunnels are left out); the tram approach ends at the east portal.
- Build time: the monolithic build 58 → 75 s (the set fills' corridor tests in `terrain_height`).

## From map north (Rondo Radosława, Arkadia, Forest; 2026-10-31)
- ~~Arkadia roof car park and the Forest's look~~ **Done 2026-11-01** (F's ask): Arkadka redesigned and its roof car park modelled (static cars), the Forest wears BANK PEPEO and has a roof terrace with a crowd (spec `arkadia.md`). Left: a drivable deck for DEMO 6.4; the terrace's bar kiosk and lounge.
- ~~Arkadia's photo check (colours, skylights, entrances)~~ **Done 2026-11-03** from F's ten photos: the round fountain plaza kept clear, a curved glass entrance between four stone piers with canopies and a fan of six glass gables, the square sign tower (ZACHODNIE POLE crown, KARFUREK / MERLINEK / KINO SITKO panels, a pink screen), the dark glass office wing, the brick wing with render pilasters and yellow awnings, the rotunda corner, the letter sign on the lawns (spec `arkadia.md`). Found, open:
  - Arkadia's plaza paving (dark radial stripes) and the dry fountain's jets: the map draws OSM's fountain as water (map lane).
  - K8's rope course stands west of the mall; the real green "worm" is south-east of the plaza (OSM `playground` at (−2738, −2387)), whose `park` polygon is self-crossing, so `bake_park_details.py` can't place it there yet.
  - The OSM service road across Arkadia's plaza: check traffic never uses it.
  - Arkadia's summer open-air cinema on the lawns (F's photo): a content idea.
- **For the landmarks lane** (docs/DEMO.md 2.1 "Hand-over"): Rondo Radosława's flag mast (not in
  OpenStreetMap; the surface model has a 57.8 m column at (−2,850, −2,295)) and the island round it,
  Forest's tower (OSM part 923445779, 120 m; drawn today as OSM blocks), Arkadia (LoD2 today; its roof
  car park, OSM way 91341678 and ramps, is left out of the bake: the car-park race of DEMO 6.4 needs
  it modelled). Their parts are in the index's `site_parts` (`bake_sectors.py` SITE_NAMES "Westfield
  Arkadia", a SITE_AREAS box for Forest).
- ~~**For the gameplay lanes** (not built here; the map has a corner left `outside` since map north):
  the helicopter's clamp (`heli.gd`, `bounds.grow(-12)`), the car's off-map test (`main.gd`
  `_node_spot`), Podwózka's named finishes and river scan (`rides.gd`), the missions' and eggs'
  random spots (`missions.gd`, `eggs.gd`) and the minimap's frame (`hud.gd`, `full_map.gd`) still
  use the bounding rectangle: the helicopter can fly over the empty north-east corner (nothing is
  drawn there; the edge walls stop the car), and a random spot there snaps to the nearest road.
  `map_builder.gd` `in_map(p, pad)`, `map_outline()` and `clip_to_map()` give the shape. A notebook
  place for Rondo Radosława / Arkadia is the content lane's (`game/data` places).~~ **Done (the
  L-shaped map loop, 2026-10-31)**: all of them use the outline (DEVELOPMENT.md "The L-shaped map in
  gameplay"); the minimap and full map shade the corner as off the map; Rondo Radosława, Arkadia and
  Forest are notebook places (a ninth card in `kiedys`, `codziennie` and `bary`: the 9 x 8 rule is
  now 8 to 10 a chapter, QUESTIONS); `check_edge` proves the clamp, the spots and the mask.
- **From the L-shaped map loop**: the barriers' day street (eggs.gd) may differ near the corner for
  some dates (the pool of segments 120 m inside the outline is smaller); the helicopter's clamp is
  only in heli.gd: an autopilot target in the corner (none today) would be chased along the edge.
- **Rondo Radosława's ring has no spiral lane lines** (`bake_roads._spiral_rings`: its pieces carry 2
  and 3 lanes, and the first piece decides): plain lane lines; cosmetic.
- **The committed maps grow with the bounding box** (ao.bin and lights.bin 40 → 48 MB, water.bin
  20 → 24 MB, most of the growth zeros over the corner left outside): the export leaves them out
  (the prebuilt sectors carry their slices); a per-part layout would save ~16 MB in the repository.
- **The looser LoD2 match is cautious**: half the footprint in OSM outlines (8 models); at 30 % it
  would be 27 models touching 44 plain blocks (the diagnostic's 59 counted any touch). What stays:
  L1 15 OSM blocks drawn inside a model whose centroid misses them (towers' podiums, courtyard
  wings), L2 73 big outlines a small model's centroid falls in (the outline hidden, the model
  small); `tools/check_lod2.py` lists them with `--at=`.
- ~~**check_police P12 "guard car follows 15 s" failed once** in the full `verify.sh --ios` run
  (map north, 2026-10-31) and passed 3 of 3 alone: a timing-sensitive case under load (gameplay lane).~~
  **Fixed (the L-shaped map loop)**: not load but chance (1 run in 12 alone): the guards' car's
  random spot missed the check's one road 4 tries running; each case now seeds the random numbers
  (`FRESH_SEED`): 20/20 alone, 21/21 three at a time.
- **The viaducts at the north edge**: Jana Pawła II's and Andersa's decks over the ring railway end
  in the air at the edge (C6 allows the rim; the edge walls stop the car 5 m before). The ring railway
  and Dworzec Gdański's platforms lie just past it; the next growth north takes them in whole
  (needs the ortho, trees and OSM past 52.2595: a new fetch).

## From loop 3d-2a (the ground, part one, 2026-10-30)
- **The full cut under roads** (clip the ground along the road surface, close it with skirts) is
  not built: of the ground under roads only whole 10 m triangles go (1,109 under the road surface
  alone, the rest under areas). Cutting the partly covered cells adds triangles on every one of them
  to save overdraw the iPhone's tile GPU mostly hides already (the flat mesh is opaque, one draw
  call a tile). Worth it only if a Metal System Trace on the phone shows the ground's fill under
  the streets: measure first (perf-engineer), then `_build_ground` can clip by the same cover lists.
- **Coarser ground needs the terrain cleaned** (Slop New York's "survey pits and bumps removed"):
  the 10 m grid has almost no flat blocks within the 2 cm that keeps the heights (1.9 % of the
  cells in 20 m blocks), but 47 % within 15 cm. Snapping near-planar blocks in `bake_terrain.py`
  changes the driving heights by up to that, so the whole chain re-bakes (decks, lanes, check_roads
  allowlists). A decision for the user (docs/QUESTIONS.md); it would also merge the areas laid on
  the grid.
- **The flat mesh's big layers now**: footways and paving 1.88 M vertices (exact strips clipped to
  every grid triangle since loop 3b-2), grass and parks 1.39 M, roads 1.21 M, islands and kerbs
  0.80 M, markings 0.68 M; the ground 0.99 M. The footways are the next one to look at (10 m
  pieces where the grid under them is flat, as roads are laid).
- **Build time**: the cover tests cost the monolithic build 44 → 58 s and bake_city 75 → 90 s
  (~0.13 s a sector on the runtime path's streaming thread). A per-sector cover cache in the split,
  or Clipper on a cell's union once, would win it back.
- `check_ground` leaves 6 triangles it calls covered (a test point on a seam between two pieces;
  `HIDDEN_MAX` 30).
- Fixed on the way: `bake_city.gd` printed 12 `ERROR`s counting the empty proxies of sectors with
  nothing to show (since loop 3d-1).
- The brief's 18.19 M vertices was the 18.6 km² box; the demo box since Q3's re-bake counts
  19,488,688 (now 19,052,803).
- `shots.sh`'s `settings_panel` shot (3d-1: MISSING) came out in 8 of 9 runs this loop, one MISSING
  then fine on a rerun: flaky, not broken. Three prebuilt spot shots with `--time=day` once came out
  at night while other Godot runs were going; fine on a rerun.

## From the loading fix (the view's sectors first, city-coloured proxies, 2026-10-31)
- **A look at a far target still shows proxies in passing on the iPhone 11** (25 frames over 5 %
  of the view in six looks, 0 on the Mac): the camera flies over sectors on its way that load only
  as it reaches them. Expecting the whole way too was tried and dropped: the 24 map slots fill
  (265 slot waits on the Mac) and the target's own sectors then wait. A shorter or cut look for
  targets past ~1.5 km, or more map slots (QUESTIONS 3d-2b), would end it: the camera's lane.
- **Jumps load the view's sectors at once** (the frame of the cut): on the iPhone 11 the jump pass
  has 15 frames over 33 ms against 11 (one or two at each cut); the alternative is a second of
  proxies at the new place.
- **Fotka's camera isn't the streamer's**: `fotka.gd` orbits its own camera while
  `sector_streamer.gd` is fed the main one; its views stay within the 704 m square loaded round the
  car today, but a wider Fotka zoom would show proxies (content lane: feed the streamer the current
  camera).
- **The proxies at night** use a plain lit material: no lamp light or lit windows (the city's
  night look comes from its own shaders). Rarely seen now; a night tint is the next step if it is.
- **The proxies' boxes are 8 m cells**: a building reads as a stack of coloured blocks up close
  (`shots/loadfix/proxy_close_after`). LoD2 outlines would be truer but cost triangles (15,000 a
  sector).
- **Turning-aware look-ahead not built**: the helicopter at 360 m turning shows a proxy's edge at
  499 m (0.3 % of the view) at worst; the 704 m square round the focus already covers any turn.

## From loop 3d-2b (the map engine, part two, 2026-10-30)
- **Far levels are not built** (measured: with the orthographic camera every sector drawn has its
  ground on screen; the proxies show only while a sector loads). A far level by zoom, the
  helicopter's highest views drawn as painted proxies (357 → a few dozen draw calls over the
  centre), changes the look of those views: the user's call (docs/QUESTIONS.md). Landmarks would
  need a LOD1 from `landmarks.gd` (the landmarks lane).
- **The helicopter is ~33 draw calls a pass** (26 boxes and the lights under its body,
  `heli.gd`): one mesh with vertex colours (rule 2 of "Performance budgets") would save ~60 draws
  in every flying view, more than any far level. Gameplay or performance lane.
- **Map slots**: `CityMaps.SLOTS` 24 (32 MB); the 3-minute soak reached 24 sectors in full at once
  (the 220 m view with the hysteresis), the passes 15-20; a load with no free slot takes one from a
  sector kept only by the hysteresis (`evictions`), else waits (`slot_waits`; 0 in every run). A
  bigger map or wider views may want 28-32.
- **The runtime path** (the editor) still builds a sector's meshes and colliders on the worker and
  hands them over at once (its load-end frame keeps the old cost); its start still runs the roof
  pass over every sector file (23 s on the demo map: BACKLOG "From loop 3d-1"). The phone's path
  is the prebuilt one.
- **check_streaming spot 8** came down to 0.015 % (it was 0.789 %, `SPOT_MAX` 1 %); the limit is
  left until a few more runs agree.
- `verify.sh` streaming takes ~8 minutes now (the two passes).

## From the radio playlists loop (2026-10-29)
- Done: radio.json, shuffled playlists, `tools/add_music.py`, the radio check, README "Adding music",
  CREDITS "Music".
- **No libvorbis in this Mac's ffmpeg** (Homebrew's build lacks it): `add_music.py` falls back to
  ffmpeg's built-in `vorbis` encoder, which ignores the bitrate and writes about 185 kb/s (4.1 MB
  for a 3-minute song instead of 2 MB). Fix: an ffmpeg with libvorbis (the brief's `-c:a libvorbis
  -b:a 96k` is already what the tool uses when it finds one), or `oggenc`; nothing else changes.
- **Licences before a release**: any track whose licence is `unknown` (a WARN in the radio check)
  must be cleared; AI music tools' free plans may not allow a published game.
- ~~**No skip button**: `radio.next_track()` exists, but hud.gd and main.gd (not touched in this loop)
  have no control for it; a tap on the ticker, or a key, would do.~~ Shift+R skips on the desktop,
  and holding RADIO for 0.5 s skips on the phone (2026-10-30; a tap still changes the station;
  `check_hud.gd` covers it). Nothing on screen says so yet (QUESTIONS.md).
- ~~**`--radio=N`** clamps to the built-in three stations (`Radio.STATIONS.size()` in main.gd): a
  fourth station added to radio.json is reached with R, not by the flag.~~ Fixed (2026-10-30): the flag
  clamps to radio.json's stations once they are read.
- **A station's order restarts a track on re-tune**: tuning away and back starts the track it was
  on from its beginning (a looping single track still joins in the middle). A real radio would
  have moved on; a decision for the user if it grates.
- **The three original loops exist only as Ogg now**: their raw WAVs were in the repo and are gone;
  `tools/make_music.py data/raw/music/<station_id> shots` regenerates them, then
  `add_music.py --force`. The Ogg files are lossy copies of the lossless loops.

## From loop G0+ (streaming and heat on the iPhone 11)
- **A sector's load still makes one slow frame on the iPhone 11** (loop 3d-2b: on the Mac the cause
  was the collider, built by the physics server on the main thread at once; now 1,000-face patches
  and every piece one a frame, the slowest load frame 23.8 → 13.0 ms; the phone's numbers are still
  to measure with a `--stream-soak` device run) (19-22 frames over 33 ms in a
  6-minute soak, 25-65 ms each, none with any of the streamer's own work in it): the render
  server creates the sector's meshes and MultiMeshes (its GPU buffers) on the main thread when the
  worker's load ends (with `--render-thread separate` the same time moves into the frame's draw,
  the main thread waiting for the render thread: no better). A frame-sized piece would need the
  sector's resources split so the worker can load them one a frame: each tile mesh and
  MultiMesh of `s_<i>_<j>.scn` as its own resource (or the sector as four 256 m scenes), a
  `bake_city.gd` change (map-engineer; loop G0+ didn't touch the bakes). Other options: keep the
  last few unloaded sectors' roots (not freed, out of the tree) so a sector seen again minutes
  later comes back without a load (memory against hitches), or load further ahead so the hitch
  falls while the view is calm (it doesn't remove it).
- ~~**`tools/device_run.sh` copies `Documents/bench_result.txt` from any earlier bench** when the
  run made none.~~ Fixed (performance lane, 2026-10-30): a bench (`--bench` or the BENCH
  button) removes the last result when it starts.
- ~~**The night bench sometimes has a sun-shadow pass** (on the Mac, 2 of 6 `--time=night`
  benches: 57-69 shadow draws where the others have 0).~~ Not reproducible on main 81de932
  (performance lane, 2026-10-30): 12 night benches (runtime and prebuilt, 1920×1080 and the
  default window) with a watcher on the sun's shadow, every light's shadow and the shadow pass's
  draws per frame: the sun's shadow off from frame 1, no light casting one, 0 shadow draws in
  every run. The code path hasn't changed since; those runs likely had other flags or a saved
  time. If it shows again, the watcher's shape: print `sun.shadow_enabled`, `tod.mode`, `tod._t`
  and the shadow pass's `VIEWPORT_RENDER_INFO_TYPE_SHADOW` draws per frame.
- The streamer's `(unload)` time is only the call to `queue_free()`; freeing a sector's nodes
  happens at the end of that frame and isn't in the streaming numbers (no slow frame showed it).
- **check_streaming spot 8 (512, −740) at 0.789 % of its pixels** (the limit is 0.5 %; 0.472 % with
  the east edge at 21.050 and the 10 m terrain). Deterministic. The differing pixels are ragged
  shadow-edge patches on the ground, as many darker on each side (1,208 vs 959 sampled): the
  directional shadow fits its depth range to the casters it sees, and the whole city (the
  reference) has more of them than the streamed one, not a sector missing geometry (the identity
  part passes). Judged in the game (shots/spot8: the streamed sectors against all of them, 0.07 %
  visible, single texels of lamp-pole shadow edges, nothing moves): spot 8 has its own limit of
  1 % in `check_streaming.gd` `SPOT_MAX`, the reason there.
- `verify.sh` ride: 30000 frames (the river quirk's legs run 1.7-1.8 km on the demo map).

## From the first Android build (2026-10-29)

- **Nothing has run on an Android phone.** The AAB is built and signed, but the game has never
  started on Android: touch, haptics (`Input.vibrate_handheld`), the save path, the frame rate,
  the governor's tiers (`tiers.gd` knows iPhone model ids only, so an Android phone gets its
  default level) and the HUD's safe area round a camera cutout are all unseen.
- ~~**Vulkan is "not required" in the manifest**~~ **Decided and done (code 2)**: the user chose
  to require Vulkan; `game/addons/nw_android_export` marks both Vulkan uses-features required and
  `tools/export_android.sh` checks it (README, "Android (Google Play)"). `fallback_to_opengl3`
  stays off. The version is Godot 4.7's own, 0x401000 (Vulkan 1.1.0), not 1.0.3: on a Godot
  upgrade, match the plugin's `VERSION` to what Godot writes (the script fails until it does).
  Whether a phone with Vulkan 1.1 but a weak driver runs the game well is still unseen.
- ~~**The export prints Dialogue Manager's C# errors** (`No loader found for resource:
  ...DialogueLabel.cs`, `ExampleBalloon.tscn` parse errors).~~ Fixed (store-release lane,
  2026-10-30): the iOS, Android and Web presets exclude the add-on's `.cs` files, its C#
  `DialogueLabel.tscn` and `example_balloon/*` (the game uses its own balloon; the add-on's
  editor plugin, the only reader of the example, is off).
- ~~**The city step rewrites 34 tracked files with byte noise**~~ Moot since loop 3d-1: the
  prebuilt sectors are derived and gitignored, and `setup_map.sh --if-needed` rebuilds them
  only when their inputs' digests change (tidied 2026-10-30).
- ~~**Store graphics are not made yet**~~ Done 2026-10-30: `docs/store/graphics/` (the 512 px
  icon, the 1024 × 500 feature graphic) and `docs/store/screenshots/play-phone/` (ROADMAP "play
  graphics").

## From the website (aroundwarsaw.app, 2026-10-29)

- The design wiki (`tools/wiki_build.py`) still links to the repo on GitHub (✎ edit chips, spec links, `REPO`); they break once the repo is private. Drop them or decide the wiki goes down (F, 2026-11-04).
- ~~The four beta links say "soon"~~ (website v2: the form collects emails for invites; add the
  public TestFlight and Play links to the beta section when they exist).
- The site's form posts to the Stillplace Formspree form (`mykaeqjp`); give Around Warsaw its own
  form, and check the form isn't restricted to stillplace.app.
- ~~The game still calls its station NOCNA FM (`radio.gd`); the site says Kebab FM, as the user
  asked on 2026-10-29.~~ Renamed in the game too (KEBAB FM, 2026-10-30).
- ~~The screenshots are from the prototype~~ (website v2: eight new `--nohud` shots, 2026-10-30).
- From the landing's screenshot session (2026-10-30, runtime city, 2868×1320): the map's edge
  shows in wide views (about `--size=220` and up): a flat light-blue void by day east of the
  stadium and west/south of Varso, a sunset band at dusk, a dark slab at night, and a brown
  streaked "skirt" south of Varso (`--at=-1602,717 --yaw=0 --size=240`). It matters for any
  wide or marketing camera and for the helicopter high up.
- ~~`--time=night --nohud` runs quit without writing the shot about one time in three (the log
  ends after "city built", clean exit); by day, or without `--nohud`, every run wrote it.
  `tools/shots.sh` would report MISSING.~~ Not reproduced on the big map (2026-10-30, 37 runs on
  the Mac, the landing's own flags included: all saved). Suspected cause: keys typed in another
  app landing in the freshly focused game window (two renders came out in the helicopter or at
  dusk). `--shots=` now keeps the window from taking the focus, as `--no-input` does, and a run
  that ends without a requested shot prints `shots: missing [...]` with the frame and pause state.
- The occlusion dither cuts a visible hole in towers in stills (Rondo Dmowskiego
  `--at=-806.3,446.4 --heading=335`, Varso with `--yaw=250`, the Palace's wing looking north
  from Emilii Plater).
- A thin dark crack-like line across the plaza at the Palace's south-east corner at night
  (`--at=-1410,159 --yaw=90 --size=260 --time=night`, visible at full size).

## From the store listings (2026-10-30)

- `https://aroundwarsaw.app/support/` exists in the repo (`docs/support.md`) but goes live only
  with the next deploy; the store forms link to it.
- iPad: the iOS preset targets iPhone and iPad (`targeted_device_family=2`); keep or drop
  before the first App Store release (QUESTIONS.md). Nobody has played on an iPad yet.
- ~~The App Store wants a privacy manifest~~ (checked 2026-10-30: Godot's export writes
  `PrivacyInfo.xcprivacy` with file timestamps, boot time and disk space, no tracking, no
  collected data; app-store-connect.md section 4). Still read App Store Connect's email after
  the first upload for an ITMS-91053 warning.
- The store screenshots show the HUD; they need redoing when the HUD changes  (re-rendered with KEBAB FM
  on 2026-10-30; shot 07 from the bigger demo map, because on main's map Varso stands about
  140 m from the edge and every wide framing shows the cliff).
- The occlusion dither shows as a dark dotted patch in store shots 01 (bottom left) and 07
  (iPhone and Play, left of Varso); re-take them when the dither is fixed or loop 3d-1 lands.
- ~~**On a 4:3 screen (iPad) the pull-over's dialogue panel never appears**~~ (fixed
  2026-10-30: a 4:3 window was taken as a phone 390 pt tall, so only 520 pt wide, and the
  ~610 pt card found no room; `screen_points.gd` now takes a narrow window as 667 pt wide and
  knows the iPads. A real iPad, 1376 pt wide, never had it.) The iPad's fifth store shot is the pull-over again.
- On the ride HUD at 4:3 the distance marker ("1597 m" and its arrow) can sit on the HAMULEC
  button (`--ride=2`).
- Varso's crown runs off the top of store shot 7 (all three sizes); most shots show 0 km/h.
- The iPad set is rendered at 2440×1830 and scaled to 2752×2064 (the Mac can't open a
  2064-pixel-tall window).

## From the performance baseline (2026-10-30)

- ~~Loop 3d-1's map left +0.4–0.6 ms of main-thread process on the Mac after the lamp fix
  (traffic about 0.5 ms): find what in traffic scales with the map.~~ Timed (2026-10-30):
  nothing does; ~10 µs a car, 0.31 ms on the prebuilt path. Two small cuts landed. Left:
  `_count_target` and the first spawn fill are rare one-frame spikes (0.4–0.7 and ~1 ms) when
  the view moves far; spread them over frames if a hitch shows on the phone.
- Static memory doubled with the bigger map (173 → ~330 MB runtime, 241 MB prebuilt): check
  it on the iPhone 11 (TEST · BENCH's memory line) before the beta. The index packing cut it
  by ~20 MB on the phone path (2026-10-30, DEVELOPMENT.md "Performance budgets").
- Memory still on the table (2026-10-30, measured on the Mac):
  - The index's dictionaries (83 MB prebuilt after the packing): ~60 k small Dictionaries with
    a String kind each. Columns per list (one PackedFloat32Array of outlines with offsets, kinds
    as ints) would cut most of it, but every reader (hud, missions, eggs, pedestrians, rides)
    changes with it.
  - The three map-wide textures (~96 MB video): the light map (5318×3782 RG8, 1 m) could go to
    2 m (lamp pools are 12–15 m wide, but they stop at walls at 1 m), or AO and lights to ASTC
    4×4 at bake time (half the size, lossy). Both change the look a little: the visual lane's
    call with shots. The surface map holds data (deck heights, flow angle) and must stay exact.
    **Tried 2026-10-30 (performance lane), held back for one phone bench**: AO and lights imported
    VRAM-compressed (EAC RG11 on the phones, BC5 on desktops, a byte a texel instead of RG8's two),
    attached when the prebuilt city opens (the phones take the imports, the web keeps the RG8 .res:
    both formats in its pack would be +62 MB in the browser's memory). The code is on branch
    `claude/project-thread-ldyr9u` at 70faaca (with f613944), reverted before landing. On the Mac:
    the look is the same (by day 0 pixels differ by more than 8; at night 0.75 %, one-pixel
    outlines on the lamp pools' band edges), "textures" 138 → 96 MB, but "video" 393 → 416 MB:
    the first VRAM-compressed texture brings a one-time +65 MB of other video memory (the same
    for one map as for two; three runs each, identical). Only the phone's BENCH card can say
    whether the iPhone pays that too (−42 MB if not, +23 MB if so): QUESTIONS.md.
  - Side jobs hold 17 MB at start (rides 7.5): look for whole-map tables built from the index.

## From the driving-feel loop (less sticky, 2026-10-30)

- ~~Street furniture is still solid and unknockable: benches, bike racks, advertising columns,
  shelters and parked cars.~~ Benches, bins, bike racks and columns are driven through since the
  easy-driving loop (2026-10-30); shelters and parked cars stay solid (3 shelters overlapped a
  carriageway on the old map). Knocking them about like the roadworks' cones is still open.
- Corner slip and the shove are tuned on the flat test ground (`check_steering`) and by reading
  the numbers, not yet on the phone: how a 35 % bump feels, whether 7 m/s of sidestep reads as a
  jump at 60 fps, and whether shoved traffic overlapping the next lane looks wrong.
- A shoved car slides off its line only on a lane, not on a junction's curve.

## From loop MW-0 (Moja Warszawa: data and lines, 2026-10-30)

- ~~`game/data/brand_denylist.json` lists real business names for the audits; the export presets'
  `include_filter` (`data/*.json`) ships it inside the app.~~ Done in MW-0: both presets'
  `exclude_filter` leave it out of the bundle (the checks read it from the project).
- Title-collision rule (vision.md): an older `police_warn` line's English gloss says "the patrol
  car", and "Patrol" is the title of one of the artist's singles. Not changed in MW-0 (existing
  lines stay); reword the gloss ("the police car") in the next content pass if the rule is read
  strictly.
- `places.json` `near` hints are rough (about ±150 m), from memory of the map, not measured: the
  MW-1 bake resolves each address or anchor and should print the distance from the hint, so a
  wrong anchor shows at once.
- The places' `hours` are the game's own hours for the parody venues, not the real ones; MW-3's
  queues use vision.md 4.5's hour curves, not these strings.
- Two places share an address with another on purpose (Miłość Hipoteczna and Żwir at Kredytowa 9,
  Pawilony and Apteczka at Nowy Świat 22/28): the notebook may find both at once. If that reads as
  one find, MW-1 can offset Żwir to the upstairs door and Apteczka 30 m into the courtyard.

## From loop MW-1 (the MOJA WARSZAWA notebook, 2026-10-30)

- ~~**The minimap opens full screen** (F, 2026-10-30): a tap on the minimap opens a full-screen map
  with the notebook's "?" marks and found places; another tap or the back gesture closes it.
  HUD, content lane; 0 cost when closed.~~ Done (F's asks, 2026-10-30: `full_map.gd`).
- **The real bake resolution (map lane).** The notebook resolves the places at load from the
  `near` hints (`notebook.gd` `resolve`: the bake's projection, then an address poi, a named
  square, park or landmark, or the place's own poi kind, within 300-600 m of the hint). The 3d
  bake should resolve every `address` / `osm` anchor into `pois` kind `place` (with the place id),
  print the distance from the hint, and `notebook.gd` then take that point first. Today 45 of 72
  places sit on their rough hint (the 48 `osm` anchors mostly), and the address matches are up to
  359 m from their hints (Smoła, Smolna 38; Stara elektrownia, Dobra 42), so either the hint or
  the anchor is wrong there.
- `check_places` reachability (a lane or footway within radius + 10 m): 70 of 72. Not reached:
  Most Śląsko-Dąbrowski (65 m, on its hint) and Stadion Narodowy (115 m: the `stadium` poi is the
  bowl's middle; the helicopter's 60 m doesn't reach either). The bake's point (the west gate)
  fixes the stadium.
- ~~**PÓŁNOC FM track unlocks (MW-5).**~~ Done in loop MW-5: `notebook.gd` emits
  `chapter_done`, `radio.gd` `sync_chapters` opens the next locked track (saved in `[polnoc]`).
- The finding rule's "stop inside for 1 s" never decides anything with the car: a car stopped
  inside the radius is under 30 km/h and found at the next 2 Hz check anyway. Kept as specified
  (`Notebook.finds`, checked); if the stop is meant for a wider reach (parked at the kerb just
  outside), it needs a number.
- The shared addresses: Miłość Hipoteczna and Żwir both sit on their hint today (Kredytowa 9 is not
  an address point in the map), 18 m apart; Apteczka and Pawilony both matched Nowy Świat 22/28
  (the same point): one pass finds both, two toasts in a row (the second replaces the first).
  Not offset in MW-1 (the bake's anchors will separate them).
- ~~The minimap's "?" shows undiscovered places within 400 m of the car (vision.md: "in a
  discovered district"; there are no districts yet). Switch to districts when DEMO 6.3's exist.~~
  Loop 3h slice 1: each discovered district adds its first three unfound places as "?" anywhere
  (the 400 m marks stay).
- The card shows no district (~~places.json has none~~: loop 3h slice 1 added `district` to every
  place; notebook_page.gd doesn't show it yet) and no address for a venue (an address can name the
  real business: "Jasna 1" on the denylist).
- Chapter icons are the chapter's number on the notebook's chips until the PixelLab icons
  (vision.md section 9) exist.
- The tap-a-place-within-80-m way of finding (vision.md 4.1, the landmark card's tap) is not
  built: the landmark tap (`main.gd` `_on_tap`) doesn't know the places yet.

## From loop MW-5 (PÓŁNOC FM and the city's sounds, 2026-10-30)

- Done: the 7 PÓŁNOC FM tracks (`tools/make_music.py --set=polnoc`, 3.93 MB of Ogg at 22.05 kHz,
  40 kbps), the station (86,0; on air 22:00-06:00 and in the Night/Dawn looks, reruns at 70 % by
  day, Kuba's `radio_polnoc` lines every 60-120 s, the ident first), the unlocks (tracks 1-2 free,
  a chapter opens the next, `radio.unlock_track(n)` for the eggs), the city's sounds
  (`city_sounds.gd`: club leaks by their hours, the metro chime, the bells at the hour, the
  Patelnia busker 19:00-22:00, the 02:00 beat on Plac Trzech Krzyży), `check_radio`'s PÓŁNOC FM
  part, `check_city_sounds` (verify step `sounds`, CI too), `--station=`, `--radio-log`, `--unlock=`.
- **Judged by numbers only**: no speakers in the container. Loudness -13.8 to -14.0 LUFS, true peak
  ≤ -1.5 dBTP, seams clean, band energy like the other three loops. The levels of the city's
  sounds (`city_sounds.gd` KINDS: club -10, metro -12, bells -6, busker -11 dB on SFX) and the
  70 % rerun level are guesses until heard on the phone. A phone speaker drops most of the club
  leak's kick and the sub bass: the bass carries harmonics for that, but check by ear.
- **Chapters 6-9 open nothing yet**: vision 4.1 gives the last two a horn tune and the gold
  notebook cover (later loops); chapters 6 and 7 have no reward beyond the złoty and respect
  (7 tracks, 2 free, so 5 chapters open tracks). An egg's track (E14: 5, E31: 2, which is free
  already) is skipped by the chapters, so then one more chapter opens nothing.
- ~~**The eggs E14 and E31** only need `radio.unlock_track(5, "egg")` / `(2, ...)` (MW-6); E31's track
  2 is free from the start, so its reward is a no-op as written: a design question for MW-6.~~
  Done in loop MW-6: E14 opens track 5; E31 opens the next locked track when its own is free
  (the default built; an Open Question of the loop).
- **Skipped (their crowds are MW-3 / MW-4's)**: ~~the steps crowd's murmur, the guitarist on the
  steps, the queue murmur~~ (done in loop MW-3: `crowd_murmur` and `steps_guitar`), ~~dog barks at
  horns~~ (done in loop MW-4: three barks at the AI cars' horns), Jasna 0's grate rumble, dawn birds and the first tram's bell, the metro's ventilation
  hum, the club door "closing" between admissions.
- **The fixed looks' clock** (`time_of_day.gd` `local_clock`: Day 14:00, Dusk 19:30, Night 01:30,
  Friday night) runs on in real time from when the look was set, so the bells strike after an
  hour of play and the 02:00 beat comes 30 minutes into a Night run. MW-3's city clock should
  take this over. (Loop MW-3: `--clock=HH:MM` now sets a fixed look's start and Dawn is
  Saturday's 05:45; the clock still runs at real time and the look doesn't follow it: still open,
  "From loop MW-3".)
- **The radio follows the clock** (PÓŁNOC FM on air, KEBAB FM by day) until the player presses R or
  RADIO in the session; a station change by the clock shows the ticker. Not saved between sessions.
- **The host speaks text only** (vision Open Question 6).

## From loop MW-6 (Fotka, Spacer, KASETA and the eggs, 2026-10-30)

- Done: the 45 egg cards (`data/eggs.json`, `egg_book.gd`; 26 reachable, 19 waiting), KASETA
  (`tape.gd`, the 20 then cards with a dithered ghost each), Spacer (`spacer.gd`), Fotka
  (`fotka.gd`, `data/kadr.json`'s 15 Kadr spots), the notebook's SEKRETY / KASETA / KADR pages,
  `check_eggs` and `check_tape` (verify steps `eggs`, `tape`; quick set and CI), `check_hud`'s
  new pages and Fotka's controls, the flags (DEVELOPMENT.md "Fotka, Spacer, KASETA and the eggs").
- **The 19 waiting eggs** and what wakes each: ~~E01 E21 the garage's paint~~ (woken in the garage
  loop: 1 waits now, E35); ~~E03 the dawn crowd
  and the Dawn look (MW-3); E04 the patrol cars parked by the clubs (MW-3); E15 the guitarist
  on the steps (MW-3)~~ (woken in loop MW-3: 16 wait now); ~~E16 E27 the dog walkers (MW-4); E18 E19
  Wiralek's trend cycle (MW-4)~~; ~~E23 E25 the night buses at Centralny (MW-3 skipped them: "From
  loop MW-3"); E24 the player's horn and buses pulling in at stops~~ (woken in the night-buses
  loop: 4 wait now);
  ~~E28 the Rowerilo riders (MW-4); E29 E30 Kolka and Hyrax (MW-4)~~ (woken in loop MW-4: 9 wait
  now); ~~E34 the armchair man (MW-4 skipped it: "From loop MW-4")~~;
  E35 KASETA's older decades (T1); ~~E39 a tram in old livery~~ (woken in the vintage-tram loop: 3
  wait now; T13 stays waiting: "From the vintage-tram loop"); ~~E40 the payphone prop (with T17)~~
  (E34 and E40 woken in loop jobs-2: 7 wait now; T17 is not a then card: "From loop jobs-2").
  Each needs only its trigger in `eggs.json` (drop `waits`) once its piece exists.
  ~~The Frogs shop's two eggs are not cards yet (MW-2).~~ Done in MW-2: `easter_rechotka`,
  `easter_lezak`.
- **Words to review (designer)**: the egg lines vision's table doesn't quote and every English
  name are this loop's (marked in the generator); the 15 Kadr spots (`kadr.json`: names, places,
  looks) are this loop's picks; the KASETA ghosts are boxes from the then cards' ghost notes.
- **The ghost is dim at night**: it reuses `building.gdshader` (no new shader), whose emission
  is scaled by the same dither fade, so the then-building glows less than the city around it.
  A visuals-lane tweak (a `ghost_glow` uniform) would fix it; until then KASETA reads best by day.
- **E09's place** (`most_poniatowskiego`) resolves 330 m south of the bridge, in the river (its
  `near` hint, 52.2337, 21.044). The egg anchors on the bridge's road instead (`road` in its
  trigger); the notebook's own card still sits on the hint: map lane (the bake's anchors).
- ~~**E10 (Plac Zbawiciela)**: vision's "a crowd outside" became hours 18-02 in summer (no crowds
  yet); MW-3/MW-4's crowd can join the condition.~~ Done in loop MW-3: E10 needs Plan C's crowd
  out (`crowd: plan_c`), E14 the steps at 0.8.
- **Hocki Bloki's music rise (E09) and the fountain show (E17)** are not built: the egg finds
  and pays, the show itself is a later visual.
- **Kadr k06 wants a morning**: the fixed looks have no morning (Day is 14:00); it takes Day
  until MW-3's Dawn look. (Loop MW-3 built Świt · Dawn; k06's `look` in `kadr.json` is the
  designer's to switch to `Dawn`: not changed, existing data.)
- **Sharing a photo** waits for the Share plugin (its own yes); the photos stay in `user://photos/`
  (no cap on their number yet: a cap or a gallery is a later item).
- **Spacer's hint arrow** reuses the job target arrow; while a job's or rescue's arrow shows, that arrow wins and the hint's 15 s run out unseen.
- **The --egg rig** teleports the vehicle along its path (laps, streets, circles) at 90 % of the
  limit: it proves the trigger, not that a player can drive it in traffic. Phone check.

## From loop MW-3 (the night and the river, 2026-10-30)

- Done: the Dawn look (`--time=dawn`, Settings → TIME's Świt) and `--clock` on the fixed looks;
  the queues at the five clubs and the door (rejections, the car line); the dawn crowd (20-40
  walkers on footway routes, the `dawn_crowd` bubble, Podwózka's `club` requests at dawn); the
  steps crowd and the guitarist with their two sounds; Plac Zbawiciela's summer crowd; the
  police parked by Lusterko and Smoła; eggs E03 E04 E15 woken, E10 E14 with their crowd
  conditions (29 reachable, 16 waiting); `check_crowds` (verify step `crowds`, quick and CI);
  `--crowd=`, `--night-log`, `--club=` (DEVELOPMENT.md "The night and the river").
- ~~**Night buses at Centralny (vision 3.5) not built**: `traffic.gd` (driving lane) has no way to
  gather its buses at a stop or give one an N route and sign within a one-line hook. Needs a
  small traffic API (`spawn_bus(route, sign)` or a bus "layover" mode) from the driving lane;
  then E23 and E25 only need their triggers (drop `waits`).~~ Done in the night-buses loop
  (`buses.gd`; traffic.gd `send_to_stop`, `add_bus`, `let_go`, `night_sign`; "From the night
  buses loop").
- ~~**E01 and `car_black`** wait for the garage's paint (the car line fires; the black car's line
  and the egg need a paint the player chose).~~ Done in the garage loop ("From the garage loop").
- ~~**Level 26's roof crowd**: the roof grid (`map.roof_height`) has nothing over 40 m at
  level_26's resolved point, so no roof crowd is built.~~ Done (F's asks, 2026-10-30): the hint
  was 520 m west of the tower; `near` now on it.
- **A real sitting pose**: sitters are a lower, longer instance of the standing figure (y × 0.6,
  z × 1.35), legs still. A bent-knees pose needs `actor.gdshader` (visuals lane) or a second mesh
  (+1 draw call at the steps). Open Question of the loop.
- **Smoła's queue anchor**: the notebook resolves Smoła at its address 359 m from the places.json
  hint (MW-1's note), so its queue and door stand at (-156, 156) by the Palm's side of Smolna.
  The bake's anchors (map lane) settle it; the queue follows the place. There the queue stands in
  a passage between two blocks: from `--club=smola`'s spot the block hides it (seen through the
  occlusion dither from the north: `--at=-150,150 --yaw=180 --size=50`).
- **Not built from vision 4.5**: the bouncer's sunglasses band, the rejected one walking off down
  the street (they rejoin the queue's end or vanish "for a kebab"), the queue shuffling forward
  between admissions, the club door's light. Small visuals for a later pass.
- **The fixed looks' clock still runs in real time** and the look doesn't follow it (MW-5's note):
  a Night run's queues follow the clock from 01:00 on, but the sky stays Night after 05:00.
  Making the look follow the clock is the visuals lane's call.
- **Curves that are guesses**: Plan C's hour curve (vision gives only "up to 40, Fri/Sat
  21:00-02:00"), the dawn crowd's (20 at the window's edges, 40 at 06-07), the weekday factors,
  the guitarist's 16:00-01:00 and rain's 0.1 on the steps and Plan C. Tune on the phone.
- **The steps' rows** face the river along the shore's normal found from the water distance; in
  the dusk shots the 80 read as a scattered crowd on the boulevard by the water, not as rows on
  the steps (the map has no steps mesh there yet). Check on the phone; a landmarks-lane steps
  model would give them seats.
- **The police by the clubs**: when their window ends at 08:00 the parked car is dismissed (it
  drives off as a patrol). Their `police_club` lines go to a slow car within 15 m; they never
  start a chase and the trap's koguty rules don't apply to them.
- **Phone check**: the queue figures at 80 m are 2-3 image pixels wide; whether a queue of 24
  reads as a queue (and the dawn walkers as a crowd) only the phone shows.

## From loop MW-4 (everyday life and trends, 2026-10-30)

- Done: dog walkers (three dogs, the trees, the horn's bark and line), the influencer dog and
  E16's ball; cyclists (commuters, Rowerilo, cargo) on the cycle paths, the dock, the bell at a
  car parked on a cycle path; runners, KOLKA on Wednesdays and the Zając; Hyrax on Saturdays
  and Podwózka's `hurry` riders; the Wiralek cycle (three slots, queues, fascias), the "Na
  czasie" job, Fat Thursday's queue; eight procedural sounds; eggs E16 E18 E19 E27 E28 E29 E30
  woken (the `event` kind), E20 with the `lukrownia` crowd (36 reachable, 9 waiting);
  `check_city_life` (verify `life`, quick and CI) and the `life-soak` run; `--life=`,
  `--dogs-log`, `--trend-log`, `--life-log`, `--zajac`, `--trend-day=`, `--trend-job`,
  `--life-soak` (DEVELOPMENT.md "Everyday life and trends").
- ~~**The player has no horn** (vision's horn reactions, E24): the dogs bark at the AI cars' horns
  (`traffic.gd` signals, connected in `main.gd`). A horn button (the driving lane: a HUD
  control and `car.gd` / `sfx.horn`) then needs one line: `life.horn(car.global_position)`.~~
  Done in the night-buses loop: the HUD's horn left of the brake and B (`buses.gd` `honk`, no
  `car.gd` change).
- ~~**No Rowerilo docks in the map data**~~ Done (2026-11-01): the 92 `bicycle_rental` pois each get
  a dock (`storefronts.gd` `_load_docks`, `Props.add_bike_dock`, 4-8 bikes from `l`, 6 unmapped) in the
  sector's StreetProps mesh (+0 draw calls where it stands, +1 in a sector with no other prop).
  `check_parodies` counts them. Open: Mac look check (row direction and kerb clearance against the
  real stands; headless check only, no render in the cloud), and the old single `rowerilo_dock`
  place in `city_life.gd` can now go or move to a real dock.
- **E28's "to a dock"** is simplified to "follow a Rowerilo rider 400 m" (the rider then docks
  off screen): with docks in the data the rider could ride to the nearest one. Open Question.
- ~~**No rider MultiMesh to share** (MW-2's Pędzik riders aren't built): the bikes are their own
  MultiMesh (+1 draw call in view). When Pędzik lands, its riders can join it (a fourth bike
  shape) or the reverse.~~ MW-2: the bike family already holds its four morph shapes (commuter,
  Rowerilo, cargo, parked), so Pędzik has its own MultiMesh (+1 in view, "From loop MW-2").
- **PixelLab pictograms on the Wiralek fascias** (vision 3.4's table: a croissant cube, a cracked
  chocolate bar, …): PixelLab wasn't available this loop; the fascia shows the word only. Eight
  pictograms, then a textured quad beside the word (+0 draws if in the fascia's mesh).
- ~~**The armchair man (E34)** isn't built: the dogs' MultiMesh has no spare shape and a chair
  prop on a guest needs a fifth shape or its own mesh. Small; MW-2 or a later life pass.~~ Done in
  loop jobs-2: a guest with the chair as its own small mesh (+1 near him).
- **No running stride**: runners, Kolka and Hyrax use the walking legs (`actor.gdshader`'s `walk`;
  visuals lane). Waiting walkers and the still photographers swing their legs too (guests share
  the walkers' material); a `walk` per instance would need the shader.
- **Not built from vision 3.4 / 3.7**: one queuer in five holding a phone up (a pose), the pigeon
  on days 6-7, the influencer at the window, the courier with the square backpack, MERDAK pet
  shops (no `shop=pet` anchors in places.json), scooters (Leżak, MW-2), the cargo bike's child
  laughing and the Hyrax finish's whistle (sounds), the traffic behind honking at the Zając
  (one car horn plays instead).
- **Kolka's start**: the `kolka_start` place's pin resolves about 490 m from the boulevard (by
  the projection; in the water by the tow's test) and the footway A* from it detours north; the
  club gathers at the route's last point within 500 m of the pin (on the boulevard), 1,261 m
  from Most Poniatowskiego. Map lane: the bake's anchors (like E09's bridge pin).
- **The clock is the wall clock** (MW-3/MW-5's note): in a headless run with `--fixed-fps` the
  game runs faster than the clock, so Kolka (and every clocked thing) moves at real time while
  the car moves at game time. `--zajac --autopilot` therefore needs about 4 minutes of real time
  to pay. A game-time clock is the visuals/time lane's call.
- **Hyrax and Kolka need Live** (or `--zajac`): a fixed look is always Friday (Saturday before
  noon), so Kolka never runs and Hyrax only before 12:00 in a fixed Day look started in the
  morning (`--clock=10:00`). Open Question.
- **Guesses to tune on the phone**: the dog and rider counts, the rider mix, 3 m/s runners,
  the Hyrax ring (26 m, 24 barriers), the fascia's size, the job's tip and late rule, the 240 s
  per-slot offer cooldown.
- ~~**Script cost over budget at the busiest spots**: "city life" 0.08-0.10 ms against 0.05.~~
  Done in the MW-4 cost cut (DEVELOPMENT "Everyday life and trends", Cost): 0.04 ms at Plac
  Zbawiciela 07:30, 0.03-0.04 with Kolka running, 0.02 on the bench route. Left: the phone's
  own number (the performance lane's device bench); full packed arrays for the movers would cut
  the step again if the phone needs it.
- **Phone check**: whether a 120-triangle dog reads at 80 m (2-3 image pixels), the bikes' cream
  and basket, the fascia's word at phone size, the bark and bell levels in the mix.

## From the web build (2026-10-30)

- **Try it in a phone's browser** (iOS Safari, Android Chrome): memory with the ~140 MB pack in
  memory, the touch controls for real, the safe area (`OS.has_feature("mobile")` is false on the
  web, so the HUD uses the desktop layout rules), the frame rate.
- **Smaller download** (web loop 2 did the sectors: 141 → 59 MB at the start). What is left: the
  pack's 40 MB (shared meshes and textures 20, proxies 8.5, index 7.7), the engine's 10.
- **A sector the car reaches before its pack** shows its proxy and has no colliders; on a slow
  link a fast helicopter could outrun the downloads. Not seen in tests.
- **The Compatibility renderer's look**: compare the web against the phone shot for shot
  (night lights, water, shadows); only the green traffic was fixed.
- **Prebuilt MultiMeshes with custom data and no colours** would show the same Compatibility bug
  if a shader reads COLOR; none looked wrong in the browser (trees, parked cars).

## From F's asks (2026-10-30: Frogs, the zones' switch, LEVEL 26, the full-screen map)

- ~~**Frogs' shops** are still words only (MW-2 builds them): the fascia spec is FROGS at a 0.12 m
  letter pixel (parodies.md 2.1); the ids stay `rechotka` / `easter_rechotka`.~~ Built in MW-2.
- **The zones' switch off** also silences the guards' whistle, run and car (only the pill and the
  cap were asked about); the clamp keeps its "in a zone or on a footway" rule. If F wants the
  whistle as flavour with no cap, it is one condition in `guards.gd` `_zone_tick`.
- **LEVEL 26's band** follows the roof grid's 4 m cells (smoothed over five rays, put 0.5 m out),
  so it sits on the facade or up to a few metres out of it; the parapet figures stand 4.6 m in
  from the grid's edge. A tower-top outline from the map lane (the top floor's footprint as a poi
  or in `landmarks`) would put both exactly on the glass. The figures are dark on a dark roof and
  hard to see from the helicopter; a light shirt or two would read better (art direction).
- **LEVEL 26's cost** in view at night is +2 draw calls: the band (+1) and the crowd MultiMesh of
  its 512 m cell (+1, the roof crowd and the door queue; before, the roof crowd was never built
  and the cell stayed hidden). 0 by day and beyond 350 m.
- **The full-screen map** shows the "?" marks the minimap shows (unfound places within 400 m of
  the car), not every unfound place (that would spoil the finding). The 3D view still renders
  under it while open (the game is paused); stopping the view's updates while the map is open
  would save the phone's GPU (performance lane).
- **Android's back gesture**: `full_map.gd` closes on `NOTIFICATION_WM_GO_BACK_REQUEST`, but
  `application/config/quit_on_go_back` is Godot's default (true): check on a phone whether the
  back gesture quits the app first (store-release lane).

## From loop MW-2 (storefronts and parodies, 2026-10-30)

- ~~**What the map lane should bake** (none of it is in `centrum.json`; MW-2 places from addresses
  and the lane graph at runtime, DEVELOPMENT.md "Storefronts and parodies"): `shop=convenience`
  (the Frogs could stand where real corner shops are), `railway=subway_entrance` (the metro
  entrances are put on the pavement round nine station places, not at the real stairs: at
  Centrum one canopy stands over the map's own sunken stairs), `amenity=bicycle_rental` (the
  docks), the `scooter` / `scooter_zone` pois of parodies.md 5.2 (the odd places: grass, bench
  fronts, hedges, 1 in 40 on a shelter roof), and an address for **Kruczkowskiego 3B** (Kasa
  Biletowa resolves to Aleja 3 Maja 7A, the nearest address within 140 m).~~ Baked in the
  content-POIs loop (2026-10-31, DEVELOPMENT.md "Content POIs"): `convenience` 260 (`fr` the
  Frogs' chain, 163), `subway_entrance` 84 (`yaw` the way down, `st` the station), `bicycle_rental`
  92, `scooter_zone` 56 (one `egg`), `scooter` 468 (poses), and Kruczkowskiego 3B with 10 more
  places' addresses (`address` with `v`). **The content lane's switch** is "From the content-POIs
  loop" below. Still open: an outline per facade with its street side would replace the
  sector-load wall rays.
- **What the landmarks lane could add**: nothing blocks. The venue neon sits 0.14 m off the
  collider's face; on a LoD2 facade (no `lod2.*` in this container) the rays meet the LoD2
  walls, untested here. A real shop front (door recess, glass) on the Frogs' walls would beat
  our 5 m fascia box.
- **Wall rays at sector load**: 248 Frogs picked, ~200 find a straight 5.2 m wall with a 5 m
  roof (the rest are skipped: a Frogs needs a wall). The rays run once per sector on the main
  thread (`storefronts.gd` `_physics_process`, ~1-3 ms a sector in the headless run); the phone
  should be checked for a hitch at sector load.
- **Setup** costs ~230 ms at the city's start (headless, desktop): the address and venue lists,
  the shop picks, the Leżak and metro picks, the neon atlas. Could move to a worker thread.
- **Not built (cheap later)**: ~~Pędzik on the road's kerb edge (they ride the cycle paths and
  footways only), the 1-2 couriers waiting at each kebab stand at night, the hop over a car~~
  (done in loop couriers: "From loop couriers"),
  ~~**the courier race** (parodies.md 4.3), **the Leżak round-up** (5.3: depot, pins, boot of 5)~~
  (done in loop jobs-2: "From loop jobs-2"), Leżaks on shelter roofs.
- **PixelLab pictograms** (parodies.md 6.2 / 9): the ten billboards are text only (the five new
  ones: FROGS · TU TEŻ, PODWÓZKA · GPS WIE LEPIEJ, PĘDZIK, LEŻAK, WIRALEK); a frog, a pin, a
  backpack, a scooter and a phone pictogram each would be a textured quad beside the word.
- **Two older `kebab_order` lines** are over the Polish bubbles' 70 characters (72 and 75:
  "Zamówienie dla pana Krzysztofa…", "Powiśle, kamienica bez windy…"); `check_parodies` lists them
  as known. A designer's trim.
- **An older column poster** "CISZA NOCNA 3:00–3:05" has an en dash the pixel font lacks (it
  draws a gap); a `–` glyph in `pixel_font.gd` or a hyphen in the line.
- **Stamp reach** is 8 m from the door point (parodies.md 2.4 says 6): the door point is 1 m out
  from the wall and a car on the near lane stops a pavement's width plus half a lane away
  (`--rechotka` stops 6.4 m from Krucza 51's door). Open Question in the MW-2 report.
- ~~**The metro M** is a cream M on a navy square~~ (done 2026-11-01: a red lit square on a 3.4 m
  post, plus a red fascia on the canopies; still our own shape, no operator logo).

## From the content-POIs loop (map lane, 2026-10-31)

- **check_streaming's `look` pass depends on the Mac's frame rate** (found 2026-10-31): the look
  waits `LOOK_WAIT_MS` (1.5 s) of wall-clock time while the sectors load a slice a frame, so on a
  busy Mac whose frames ran at 16.7 ms (the iOS Simulator of another project running) s_-6_0 was
  still loading when the camera arrived (24 frames over 5 %, frame 1338); at 8.4 ms and 1.5 ms
  frames the same code passed. Fix (map lane): wait in frames, or run the pass on a frame budget
  that doesn't change with the machine; the iPhone 11's 60 Hz is the case that counts.

- **The content lane's switch** (storefronts.gd, 2026-10-31: **built** in loop content-POIs-switch, see ROADMAP; bike docks and the other `convenience` shops are not used yet; roundup_job.gd and props.gd needed no change):
  the Leżaks from the `scooter` pois (`p` the pose: `lie` on its side as today; `stand` upright;
  `roof` at `h` 2.6 m over the ground; `grass`, `bench`, `hedge`, `frogs` lie like `lie`) instead
  of `_pick_scooters`, the zones' paint from `scooter_zone` (3 m along `yaw`), the standing one
  and `easter_lezak` from the zone with `egg`; the round-up's depots at zones as today. The metro
  canopies at the `subway_entrance` pois facing `yaw` (skip `u`: underground passages), with
  `st` instead of the nine notebook places. The Frogs from the `convenience` pois with `fr` (their
  `door` is the road point, `x, z` the shop: the wall rays still find the facade), the other
  `convenience` free for other parody shops. Bike docks (`bicycle_rental`, `yaw`, `l`) for a rack
  row of parody bikes. Today's runtime picks fail the bake's rules often (`tools/check_pois.py
  --points=`: 108 of 277 Leżaks on a carriageway, crossing, kerb ramp or something solid, 14 of 25
  metro canopies), so the switch also fixes those.
- **`address` with `v`** (11): places' addresses the job pool didn't have; `jobs.gd` and `rides.gd`
  take every `address`, so their shuffles changed (the kebab run's order 0 is now 1,266 m by road:
  verify `kebab` 15000 → 21000 frames). Skipping `v` in the two jobs gives back the old picks
  (gameplay lane), if wanted.
- **Hala Gwardii's address** (Plac Żelaznej Bramy 1) is in no OSM element: the notebook keeps
  its hint.
- `check_pois.py` isn't in CI (`.github/workflows/verify.yml`): it reads only centrum.json (and
  lod2.json and the OSM export when they are there), so it could join the CI list.

## From loop jobs-2 (the courier race, the Leżak round-up, the payphone, the armchair man, 2026-10-31)

- Done: the courier race (`courier_race.gd`, parodies.md 4.3), the Leżak round-up
  (`roundup_job.gd`, 5.3), the payphone at Plac Konstytucji (E40) and the armchair man on
  Mokotowska (E34): 40 eggs reachable, 7 waiting. `check_side_jobs` (verify `jobs2`, quick and CI);
  `--courier-race[=N]`, `--courier-v=`, `--roundup`, `--armchair` (DEVELOPMENT.md "The courier race,
  the round-up, the payphone and the armchair man").
- ~~**The courier rarely wins in play**: on today's map the footway network follows the streets, so
  his way is about as long as the road (stand 0 → Oboźna 1: 1,013 m against 1,023 m); at 6.5 m/s
  a player driving at 30-50 km/h beats him by a minute. parodies.md's "25 % shorter" needs park and
  courtyard paths the bake doesn't have, or a faster rider. The autopilot (the job's ghost: 222 s
  for 1 km with the lights) loses. Tune on the phone (Open Question: speed).~~ Loop couriers: his pace
  is the order's road at 10 m/s (6.5-11 m/s), a decent drive wins about 2 in 3 ("From loop couriers").
- ~~**The courier appears when he challenges**: parodies.md 4.2's 1-2 couriers waiting at each stand
  at night are still not built, so the challenger is drawn by the kiosk only from the challenge.~~
  Loop couriers: the challenger is one of the couriers waiting there.
- **The round-up follows parodies.md 5.3** (collect into a boot of 5, unload at the depot), not
  pushing scooters into the zone with the knock: the brief's wording; Open Question.
- **Leżaks round a depot are picked up and unloaded at once** (the zone's 2-3 lie within the 7 m
  ring): a free one or two to start. Kept (the zone's joke works: they lie round the zone).
- **A fixed Night look keeps collected Leżaks gone** for the session (they come back when the
  look leaves night: Live's morning, or a switch to Day); a session restart brings them back.
- **The autopilot round-up slides through buildings** (as the trend job's): it proves the flow,
  not that a player can reach each Leżak; some lie on footways behind railings. Phone check.
- **T17 isn't a KASETA then card**: the 20-card set covers 2010 to today and its words are the
  designer's; E40's card carries T17's line ("Karta na 25 impulsów…") and +10. A 21st then card
  (a payphone ghost, a year such as 2010) is the designer's call (Open Question).
- **The armchair man's hours** are the shops' (08-20) and his days the trend cycle's day number
  (Live's date, else the session's), so a fixed look sees him in 1 session in 3. No line of his
  own (vision quotes none); E34's card line only.
- **The payphone** stands where the pavement test finds room nearest Plac Konstytucji's point
  (32 m off its point); the real square has none today. Its look is the art
  director's to judge (no operator colours on purpose).
- **The kebab order's distance can be half the drive**: jobs.gd measures "1,023 m by road" from
  the stand's nearest lane, which can be the other carriageway; the car starting the other way
  drove about 2.3 km to Oboźna 1 (the race's gap read 2,292 m at 20 s, honest, the car's own
  lane). The race reads the car's lane, so it can say 2ND at the start of an order the card calls
  short. Snapping the stand by the car's heading in `_make_kebab_order` would fix the card.

## From loop couriers (Pędzik at the kebab stands and on the road, 2026-10-31)

- Done: 1-2 couriers waiting by each kebab stand at night (the race's challenger is one of them),
  3 / 5 kerb riders (day / night) on the roads' kerb edge, the swerve onto the footway or the hop,
  the near miss's line, the courier race's pace; `check_couriers` (verify `couriers`, quick and CI),
  `--pedzik-log`, `--pedzik-kerb` (DEVELOPMENT.md "The Pędzik couriers at the stands and on the kerb").
- **The race's pace is a model, not a measurement**: a decent player is taken as 30-50 km/h door to
  door (BACKLOG's own range above); the rider's time is the road's at 10 m/s, so such a player wins
  2 in 3. On the default route the rider rides 9.9 m/s (36 km/h, 102 s for 1,015 m). Nobody has
  timed real players: count wins on the phone (`courier:` lines) and move `CourierRace.V_ROAD`
  (Open Question). The shortcut through courtyards needs footways the bake doesn't have (map lane).
- **The kerb line is 0.45 m in, not parodies.md's 0.6 m**: a traffic car's side is 0.63 m from the
  kerb on a 3 m lane, so at 0.6 m the AI cars on the kerb lane would pass through the rider's
  handlebars. The AI traffic doesn't see the riders (a bus pulling in at a stop, or a car on a
  narrower 2.9-3 m lane, can still brush one); lanes under 2.9 m and living streets have none.
- **The waiting couriers stand still**: the car driven onto the pavement at a stand passes through
  them (they are not movers; the riders and walkers step aside). Small; a shove like the walkers'.
- **"He gets on his bike"** is a cut: at ŚCIGAJ the standing instance in the Pedzik MultiMesh goes
  and the race's own rider (riding) appears on his spot; no mounting animation. The race's rider is
  still its own MeshInstance3D (+1 draw call while a race is in view, as in jobs-2); folding it into
  the Pedzik MultiMesh would make that +0.
- **Hops are rare**: a kerb rider hops only where the footway past the kerb is a roof, another road
  or a bridge (its railing); elsewhere he swerves. The phone should say whether a hop reads at all
  (0.3 s, 0.55 m up, at the movers' 15 Hz step: ~5 frames).
- **`--courier-race` at night by a stand with nobody waiting** still draws the rider at the kiosk (forced);
  unforced, no courier waiting means no challenge (parodies.md 4.3).

## From the night buses loop (the N sign, Centralny's ring, the bus stops, the horn, 2026-10-31)

- Done: the N sign 22:30-05:00 (the BUS MultiMesh's mesh swapped, +0 draw calls), the night hub
  at Dworzec Centralny (a ring of 5-8 every half hour, 22:30-04:30, recruited from the traffic's
  buses), waiting figures at the bus stops by day and a `bus_stop` bubble, the player's horn (the
  HUD button left of the brake, B on the Mac), E23 E24 E25: 43 eggs reachable, 4 waiting.
  `check_buses` (verify `buses`, quick and CI); `--night-hub`, `--bus-log`, `--honk=`
  (DEVELOPMENT.md "The night buses, the bus stops and the horn").
- **Map lane: the shelters aren't in the index**: `tools/bake_sectors.py` keeps `shelters` sector-only
  (SECTOR_ONLY), so `buses.gd` learns a sector's stops when it loads. It reads the sector's
  `sectors/i_j.json` where that exists (the editor, the Mac), else the shelter MultiMesh's
  instance transforms (the exported game: a GPU read-back once per sector load, tested on
  software Vulkan, not on the phone). Moving `shelters` (points only) into `index.json` /
  `index.res` would give every stop at start, with no read-back.
- **Map lane: no `highway=bus_stop` / `public_transport=platform` data of its own**: the stops are
  the shelters that stand right of a bus road's kerb lane (188 of 351). A stop without a
  shelter has no figures; a shelter on a side street has none either. Baking the stop points
  (with their `name` and `route_ref` if wanted) would make the stops exact.
- **Map lane: Centralny has no bus loop or bays in the lane graph**: the ring stands in two
  rows of 4 at the kerb lanes of Aleje Jerozolimskie by the station's shelters (`HUB_ROWS`), about
  1 m over the kerb line (BAY_PULL), not in real bays. A bay or layover lane on both
  carriageways (or the real Dworzec Centralny stops' platforms) would let them pull off the road.
- **The horn is B, not H**: H was already the car ↔ helicopter key. Open Question.
- **E24's line**: vision 3.5 says "line 3", eggs.json's `line_ref` says index 2: the same line
  (the third, "Stoję na przystanku na żądanie. Żądam."), the request line; built that way.
- **A stop's own bubble can say the request line**: `dialogue.gd` picks a `bus_stop` line at
  random, so the waiting figure can say "Stoję na przystanku na żądanie…" without a honk. Harmless,
  but a `kind` to keep the request line for E24 would be the designer's call.
- **E25 has no race card**: the race starts quietly when a bus leaves the eastbound row with the
  car at the ring, and `--bus-log` is the only place that says so. A status pill ("WYŚCIG Z NOCNYM ·
  RACE THE NIGHT BUS") is the designer's call (vision gives none).
- **A bus on a route never chances a red**: `traffic.gd` lets a driver on a route (the rivals' races)
  run 60 % of reds; a bus routed to a stop, the hub or the Palm doesn't (E25 would be unfair, and a
  bus jumping a red reads wrong). Rivals are unchanged.
- **Stop figures swing their legs a little** (the walkers' MultiMesh, the trap officers' trick):
  standing figures in the walkers' buffer share their `walk` value. A per-instance stand flag is
  the visuals lane's (actor.gdshader), if it shows on the phone.
- **The prebuilt city in this container was stale** (`check_map_data.py`: the sector files and
  prebuilt sectors from another bake): the `prebuilt` step logged 1,647 `_fill_height` errors on
  main too. A scratch copy re-split and rebuilt with a renderer ran with 0 errors.
  `tools/setup_map.sh --if-needed` fixes it in place (map lane).

## From the vintage-tram loop (the old two-car set, E39, 2026-10-31)

- Done: the old set (a rounded 1960s-style motor car and trailer, red and cream, our own shape) on
  the trams' tracks, one of the eight trams recruited out of sight (its meshes swapped, the third
  car hidden: -1 draw call in view); Saturdays and Sundays 09:00-19:00 (Live: June-September), one
  25-min run an hour; its creak and its own bell; E39 (300 m followed within 40 m, +30, the egg's
  line over the tram): 44 eggs reachable, 3 waiting. `check_old_tram` (verify `oldtram`, quick and
  CI); `--old-tram[=follow]`, `--tram-log` (DEVELOPMENT.md "The vintage tram and E39").
- **T13 waits**: vision's E39 reward names the then card T13 (the rounded 1960s tram and the boxy
  1970s one), but the then cards start in 2010 (QUESTIONS, answered 2026-10-30): E39 gives +30
  and its line only. When the older decades come (with T1), T13 can be added to
  `then_cards.json` and to E39's reward (`"then": "t13_..."`).
- **Without Live the set is rare**: the fixed looks' clock is "always Friday" (Day 14:00), so the
  set runs only on the game's Saturday: Dawn's clock after 09:00 (3+ hours of play) or the Day look
  from `--clock=` before noon. Open Question: also run it in the plain Day look (e.g. one run an
  hour whatever the day) so that E39 is findable without Live? Built as the brief says.
- **The hours are a guess**: 09:00-19:00, one run an hour starting in the first half hour, 25 min
  each; the set at 29 km/h. Tune with F on the phone.
- **No boxy 1970s set**: vision's T13 pairs the rounded tram with a boxy 1970s one; only the
  rounded one runs. A second look (an old boxy set) is a mesh swap away if wanted.
- **The rails don't change**: it runs the modern trams' pieces, stops and lights; no heritage
  route (Warsaw's tourist line T) of its own. A route would need the map lane's track pieces
  named by line.
- **Night**: it runs by day only, so its hidden third car's tail glow isn't missed; with
  `--old-tram` at night the trailer shows its tail lamps but no red glow on the rails.

## From the garage loop (Warsztat u Mirka and the paint jobs, 2026-10-31)

- Done: the garage on Brzeska in Praga (a dashed blue ring, a diamond on the minimap and the full
  map; shown after the first earnings, a toast the first time), the paint card (pauses the game;
  8 paints: factory red free, cream 150, pea green 180, blue 200, yellow 250, black 300, pink 350,
  gold free at 5 egg cards), owned paints kept and switched free, saved in `[garage]`; `car.gd`
  `set_paint`; Mirek's lines (dialogue.json `garage`); E01 (black at Lusterko's door, Fri/Sat
  23-06, +50, `car_black`) and E21 (green, 2 s at Glon, +15): 46 eggs reachable, 1 waiting (E35).
  `check_garage` (verify `garage`, quick and CI); `check_hud` lays the card out; `--paint=`,
  `--garage[=ring]`, `--garage-log` (DEVELOPMENT.md "The garage").
- **The 3 cars** (DEMO 6.3: the hatchback, a boxy estate and a tiny 1970s-style city car, invented
  shapes) are not built: a later loop (models.gd's shapes, the card's second row, their feel in
  car.gd: driving lane).
- **The horn tune** (DEMO 6.3: collectibles unlock a horn tune) is not built: a later item with
  the horn's sound (buses.gd's horn button).
- **No sign on the workshop**: the venue neon fascias (storefronts.gd) come from places.json
  places; a "WARSZTAT" sign needs a place (or a sign hook of its own) and the letters in the neon
  atlas. Until then the ring and the diamond mark it.
- **Prices are a guess** (150-350 zł, black 300; the gold one at 5 egg cards): tune with F on the
  phone against how fast the złoty come in the first 15 minutes.
- **The unlock is "after the first earnings"**, not the beat's clock (10:00 of play): with the demo
  script's first order at 0:30 it shows within the first minute. Open Question for the designer.
- **The bouncer's `car` lines name a red hatchback** ("Czerwony hatchback. Dziś wchodzi tylko
  czerń.") whatever the paint: with another non-black paint it is a white lie. A `car_red` tag (the
  designer's words) would fix it.
- **Brzeska is one-way and narrow** (3 m, one lane): the ring covers the street; a car coming the
  other way still drives in. The workshop could move to a wider kerb (map lane: a service way's
  mouth on Brzeska) if F finds it awkward.

## From loop 3h slice 1 (save v2 and the districts, 2026-10-31)

Closed: save v2 (a version, the v1 migration and backup, settings' version), districts as data with
discovery, "?" marks and completion on the full map (DEMO G3). Left for the later 3h slices:
- ~~**Syrenki** (slice 2): 20 collectibles; register each with `districts.gd` `add_syrenka(id,
  district)` and mark finds in `wallet.syrenki` (saved already); then they count in completion.~~
  Done in slice 2 (see below).
- ~~**Rival ladder and "Trzy mosty"**~~ (done in slice 3, see below), ~~**the first 10 minutes** (the
  hint finger, the first order, the first race, the `--first10` replay check), **the end card** (can
  read `percent_total()` and the discovered count)~~ (done in slice 4, see below; the end card doesn't
  show the districts' %).
- Ujazdów i Łazienki has one notebook place (Ujazdów Castle, 2026-11-01) besides the padel court and no egg (the park lies south of the map; only the Sejm is
  in it): completion there is its 2 jobs, and it shows no "?" marks. The designer (places for the
  Sejm, Ujazdowski Castle, Plac na Rozdrożu) or the map lane (the park) would fill it. Wola has 2
  places, Stare Miasto 4: thin for "3 ?" for long.
- The notebook's place card doesn't show the place's district yet (notebook_page.gd).
- Jobs done before save v2 have no district (v1 counted jobs by kind only): they don't count
  towards any district.
- The district polygons are hand-drawn from the stale water data and the embankment roads; the
  river line north of Most Śląsko-Dąbrowski is extrapolated (the map lane could bake a river line).
- The discovery card uses the note card (5.5 s); a bigger centred card or a sound of its own
  would make it a moment.

## From loop 3h slice 2 (the 20 Syrenki, 2026-10-31)

Closed: the Syrenki (syrenki.gd: 20 figurines by the kerb, the find, the reward ladder, the paints
"Łuska Syreny" and "Srebro Syreny", the "Syrenki n/20" line on the full map). Left:
- No hint for the Syrenki: no "?" marks, no minimap dot, no radar. A player finds them by chance or
  by a guide. A counter in the pause card or the notebook, and a sound of their own near one
  (a chime under ~40 m), would help; the designer decides how much to give away.
- The words in `data/syrenki.json` were written in this slice: the game-designer should review them.
- The figurine is `Props.mermaid()` scaled to 3 m with a cyan diamond over her (it read badly at
  1.7 m): check it on the phone; a dedicated figurine mesh (props.gd, another thread's file) and a
  slow spin or bob for the diamond (a shader: the visuals lane) would read better still.
- Placed by rule, not by eye: look at each on the street (the kerb side, trees, benches, a
  building's wall in a narrow street); `--syrenka=<id>` puts the car in front of one.
- No Syrenka on a bridge or in a tunnel (ground streets only); the figurines are small kerb
  Syrenki, not the statue (the Old Town Market Square's bronze Syrenka is a landmark model since
  2026-11-01, `syrenka` site).
- The reward cards queue in `syrenki.gd`; the HUD's note card shows one at a time (a find while
  another card is up waits for it).
- Garage card: ten paints in two rows of five; on the smallest phone check it still fits.

## From loop 3h slice 3 (the rival ladder and "Trzy mosty", 2026-10-31)

Closed: the rival ladder (ladder.gd: six rungs in order of stake, opened by the rung before and by
respect 0/100/250/400/600/850, the locked prompt and the refusal lines, a pace per rival, the toast
for a new rung, the DRABINKA card on the full map, the save's `[ladder]`) and the final "Trzy mosty"
(trzy_mosty.gd: Rondo Daszyńskiego east over Śląsko-Dąbrowski, west over Świętokrzyski, east over
Poniatowskiego to the stadium; at night; three ordered checkpoints; +500 zł +250 respect;
`trzy_mosty` saved for the end card). Left:
- ~~**Slice 4: the first 10 minutes** (the hint finger after 4 s, the guaranteed first order past the
  Rotunda, the first race at 800 m to the Palm with Seba losing narrowly, the Powiśle card at ~8:00,
  the `--first10` replay check) and **the end card** (win "Trzy mosty" = `wallet.ladder` has
  `trzy_mosty` / `Ladder.final_won()`, and 10 jobs; "free roam" after). The first race in 6.2 is
  against Seba, but the ladder opens with Halina: slice 4 decides whether the scripted first race is
  Halina (the ladder's first rung) or a Seba race outside the ladder.~~ Done in slice 4 (below): the
  first race is Halina's.
- ~~The paces are guesses (Halina 1.25 … Mike 1.5, the final 1.45): tune on the phone (A-checks: the
  first race is won narrowly by an ordinary player).~~ The first race has its own rubber band now
  (slice 4); the ladder's paces are still guesses for the phone.
- The final is long: 10.1 km by road (3.8 km from Rondo Daszyńskiego to the first bridge alone). The
  autopilot's ghost (pace 1.8) needs about 14.5 minutes of game time with the city's lights and traffic
  (867 s, Seba 30 s behind);
  a player on the phone should judge whether it is an epic or a slog. A shorter cut (a start nearer
  the river, e.g. Rondo ONZ, or one bridge fewer) is one constant in `trzy_mosty.gd`.
- Players with race wins from before the ladder start at rung one (the old wins didn't record the
  rival).
- Seba waits at the start held still: no idle animation, and while he waits he isn't cruising for a
  re-race of his rung (at night only, once the final is open).
- The finish line is a beacon ring, not a set piece: a crowd or a banner by the stands (the stadium is
  the landmarks lane's) would make the end a moment.
- The refusal and final lines were written in this slice: the game-designer should review them.

## From loop 3h slice 4 (the first 10 minutes and the end card, 2026-10-31)

Closed: the guided first 10 minutes (first10.gd: a director on a fresh save, the ghost finger, the
arrow to the Świętokrzyska stand, the guided order past the Rotunda, Pani Halina's first race to the
Palm with a rubber band, the first contact's fallback, the held first call, the helicopter after the
first rescue, the boulevard tape and its song, the Powiśle arrow, the garage at 10:00; the save's
`[intro]`) and the end card ("Dzięki za grę!", free roam after). Left:
- ~~**The opening shot is the other thread's**: the spawn faces south on Marszałkowska while the
  Świętokrzyska stand is ~530 m north of it (behind the car).~~ Done in the first-10 polish: a run
  that gets the guide starts at `First10.START` (northbound, level with the Museum of Modern Art,
  facing the stand ~350 m ahead); the map's spawn is unchanged for the bench and the other runs. The
  first-scene thread can still move that start point and heading by eye (`First10.START`,
  `START_HEADING`).
- ~~The first order is 926 m (Aleje Jerozolimskie 33, past the Rotunda, a U-turn away).~~ Done in the
  first-10 polish: Marszałkowska 142, 226 m straight on from the stand; Halina waits until 1:15
  (`RACE_EARLIEST`) so the race stays in 6.2's window.
- **Feel on the phone**: the rubber band's numbers (pace 1.15, 25 m, 0.4-1.5) come from a 1-D model;
  F's runs should say whether Halina is close enough to feel like a race and never obviously
  waiting. The ghost finger's place and gesture likewise (it sits on the stick's side, lower left).
- ~~**No "6.2" beat for "two jokes, the roosters explained in one line"** of the trap~~: the first
  contact already says it ("Koguty na dachu to my…", police.dialogue); checked in the designer pass.
- ~~**The cassette is KASETA's then card** on the boulevards (a ground spot, not a roof).~~ Done in the
  first-10 polish: a mixtape on the University Library's roof (cassettes.gd, cassettes.json), taken
  from the helicopter, opens the next PÓŁNOC FM track; the beat's arrow points there. The other nine
  of DEMO 6.3's "10 cassettes" are in (2026-11-01: c02 to c10, roofs found by `missions.roof_spot`,
  not placed by any map-free check: an unplaced one logs `cassettes: ...no flat roof`, look for it on
  the phone; only five songs are locked, so the later tapes give respect and a card); the
  cassette is a static box model (a slow spin or bob would be a shader, the visuals lane's); the
  words of c01_buw and the new tape line were written in that thread (the game-designer should review).
- ~~The guide's words (`first10.gd` LINES, Halina's FIRST_LINES, the end card) need a designer
  review~~ (done 2026-11-01: grammar fixes (stary śmigłowiec), "To już koniec dema", tone kept;
  only text changed, not run in Godot here).
- ~~The end card counts every paid job kind but races and the courier bonus; DEMO's "10 jobs" might
  mean kebab-style jobs only.~~ Kept as it is by the designer pass (docs/design/pay-tables.md).
- **The NaN car (unexplained)**: once in ~10 headless replays the player car's position went NaN at
  the first rescue's pickup (~248 s, right as Powiśle was discovered); 20 later replays were clean.
  car.gd `_keep_finite` now puts the car back at its last good transform and logs `car: state not a
  number` (`nan_recoveries`); the replay also fails fast on a NaN. If that line ever shows up in a
  log, its position and velocity are the lead.
  The first-10 polish: 30 more replays (18 on the new start, order and cassette) showed no NaN. Read
  and ruled out: the terrain, apron, deck and tunnel heights (no division by a zero length on the
  committed map's aprons), the autopilots' slides (each divides by a length > 0.5 m). The warning
  now also prints the state the physics step began with (transform, velocity, target_dir, steer,
  steer_now, yaw_rate, throttle, braking, parked, collision mask, in water): a NaN going in means
  another script wrote it, a finite one means car.gd's own step made it.
  2026-11-02 (NaN car thread): 5 more replays clean, and the replay is now frame-for-frame the same
  each run (same beats to the tenth of a second, the car's collision off from 19 s), so the ~1 in 10
  of 2026-10-31 came from code since changed or from a source a fixed replay no longer varies.
  `check_finite` (verify step `finite`, quick set and CI map job, ~2 min) found no source in the
  data: 950k height samples (terrain, ground, drive height at street, deck and tunnel level, tunnel
  floors) on an 8 m grid and densely in every deck, tunnel, fill and apron corridor; every lane and
  junction curve; the car's step at every input. It did find a hole in the safety net: one NaN in
  the stick, the steering, the pedal or the speed left `steer_now` NaN, so every later step went NaN
  and the car was put back at the same spot every frame, frozen for good. Now car.gd
  `_clean_inputs` drops a NaN input before the step and `_keep_finite` clears the steering state;
  the check poisons four cars and wants each driving on. Left: if `car: state not a number` or
  `car: an input was not a number` ever shows in a log, its `_pre_step` is the lead (the traffic
  ghosts the autopilots ride were read, not swept: a NaN there would show as a position going in).
- The end card first didn't show at all: its four Polish lines plus English were taller than the
  HUD's room, so the layout left it unplaced. Now two Polish lines (the credits and the repo as one
  shared line) and the English paragraph; a layout assertion in check_end_card would catch it again.
- `first10-run` takes ~5 min in the container (3.4× real time headless); it stays out of `--quick`.
## From the Pawilony loop (landmarks lane, 2026-10-31)

- The Pawilony are a site now (`landmarks.gd` `_build_pawilony`, spec `docs/landmarks/specs/pawilony.md`):
  37 pavilions cut from the two OpenStreetMap strips, 1740 triangles (budget 2100). Built without
  photos (the cloud has none): the art-director's check against `refs/pawilony/` on the Mac is open,
  and the gate sign's spot (-285.0, 111.5) is measured from the OSM outline, not the LoD2 front.
- Not built: string lights across the passages (they would hang in the air: the FLOAT check), the
  courtyard's own tables and crowd at night, graffiti.
- **F's ask (2026-10-31): shisha lounges.** Small night spots with neon, like the Pawilony: a few
  hookah lounges (under made-up names, no real ones) on the centre's night streets, each a lit
  front with a neon word (a new word like SZISZA in the neon font, which has no Ł/Ó/Ś yet) and maybe
  a notebook place in `places.json`. Content lane (game-designer for names and spots).

- **Railway look (F, 2026-11-05, reworked 2026-11-06):** Plac Zawiszy tunnel stretch fixed (#438). The Ochota cutting is shaped at load from the tracks (`rail_cut.gd`: flat bed at the lowest grid level beside the tracks, straight banks to the rims, concrete walls where it is narrow and deep and by the tunnel mouth), gantries replace the per-track masts over multi-track runs, Główna's island platforms are built (`rail_yard.gd`) and its footbridge is level with stairs and lifts. Still open: the second spot F found (night, a highway with a rail/tram overpass) is not located; Kładka nad Książęcą (deck 58) waits for F's description; `tools/check_roads.py`'s Python mirror of the heights does not know the cut (it reads the grid there, so C11 cannot see a mismatch); the footbridge's end towers are OSM's plain buildings and its stairs/lifts are generic (Mac photo pass: refs/kladka from Mapillary 2021 shows concrete towers); a Warszawa Główna station building / canopy is not built; trains turn back at Główna's buffers instantly (no driver walk); the wire spans of single tracks are still per-track masts.

- **Stations (F, 2026-11-06, "infrastructure for all stations, with people"):** every open-air station's platforms (Główna, Ochota, Powiśle, Stadion, Wschodnia; `station_lines.gd`) get lamps, glass shelters (none under Wschodnia's and Stadion's roofs or Ochota's saddle), benches, bins and blue name boards, and people who walk in, wait facing the track and board the next train (trains.gd `_gather`). Centralna, Śródmieście and both WKD stops are underground; Gdańska's tracks lie past the map's north edge (its 0.9 m "platforms" are the tram stops on the Most Gdański approach). Still open: the name boards carry a white band, not the station's name; Stadion's east island reads sand-coloured (the landmark site's ground over the slab: Mac look); a car driven down onto the tracks in the Ochota cutting stops dead on the platform's end and needs the rescue (~4 s); a train stops 6 m short of a car parked on its track and waits there (no horn, no reversing).

- **Sagging footbridges (F, 2026-11-05):** the bake's path-deck heights sag 4-6 m onto the floor of a trench they cross (10 m grid): fixed at load by `map_builder._lift_sagging_deck` for 6 pieces (decks 37, 43, 48, 55). The Kładka nad Książęcą was probably not this (deck 58 (262,500)-(228,426) has no sag); F's report was the Armii Ludowej one. Piers under the lifted decks are the bake's (placed for the sagged profile): Mac look check for floating or missing supports; the proper fix is in `bake_roads._solve` (deck over a trench takes the rim level).

- **Footbridges, bridges and stairs survey (F, 2026-11-05):** `docs/design/footbridges-stairs-survey.md`: 11 of 23 footbridges end 2.6-10.5 m above ground, all 36 path pieces have no rails or lamps, 2,262 stairs are flat strips. Ranked fix list (footbridge kit, stair kit, footbridge ends, bake sag fix, named footbridges, vehicle-bridge dressing); none started.

## Batch 3 photo findings (2026-11-06)

From the Mac photo reports (`docs/landmarks/photo-reports/`): done are the Zygmunt column, All Saints and the Staszic colours. Left: Staszic front as a rusticated arcade with a central avant-corps, attic, griffins and the green dome, and Copernicus about 75 m away on the round brick plaza (orientation check first); Plac Grzybowski planter wall, bollard pairs and tram tracks; Zygmunt cross and sabre sides; Świętokrzyski A-frame pylon (two legs 26 m apart, joined ~80 m up, foot near (747, -915)), denser stay fan, deck struts and white lattice railing, twin-block piers.

- **Batch 2 photo pass (2026-11-06, Museum, Cathedral, Barbican, St Anne's, Holy Cross, from refs/ and the Commons photos):** the five are rebuilt or extended from their photos (before/after sheets in the PR). Found and left: the museum's forecourt paving (pink-red stone with a pool) is still the map's; the real Cathedral's nave roof, the south tower and apse are LoD2 only; the Barbican's gate passage and the long curtain walls toward the river (photo refs/barbakan 1) are not modelled; St Anne's side wing arcades (Biblioteka Rolnicza, photo st_anne 2) and the real height of its attic are estimates; Holy Cross: the crossing dome and the real side-nave facades are not modelled. All five wait for a Mac/phone look check.
