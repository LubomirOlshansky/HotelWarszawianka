#!/bin/zsh
# The Around Warsaw verification set in one run, ending in one PASS / WARN / FAIL table.
#
#   tools/verify.sh            map data, the check scripts and the headless runs (~1-2 min)
#   tools/verify.sh --quick    map data, the check scripts, the plain and prebuilt runs (~30 s)
#   tools/verify.sh --ios      also tools/export_ios.sh and the unsigned xcodebuild. Note:
#                              export_ios.sh splits the map into sectors and rebuilds the
#                              prebuilt city (game/map/sectors/*.scn, index.res, proxies.scn:
#                              with a renderer, so a window opens for a moment).
#   tools/verify.sh --only=steering,plain   just those steps (--list prints the names)
#   tools/verify.sh --roads    the road-loop set (STEPS_ROADS, a few minutes): map data, road rules,
#                              street records, models, smoothing ratchet, drive and stuck spots.
#                              For iterating on a road or marking rule; run --quick once before a PR.
#   tools/verify.sh --logs=DIR              keep the logs there (default build/verify/<time>)
#
# `roads` runs tools/check_roads.py (loop 3a): the road and deck rules C1-C10 over the whole
# map; any finding not in tools/check_roads_allow.json FAILs (loop 3b; C4, C5, C9, C10 were a
# WARN before). `drive` runs game/tools/check_drive.gd (loop 3b): a car and a bus along every
# lane against the colliders, the autopilot over the bridges and tunnels. `drape` runs
# game/tools/check_drape.gd (loop 3b-2): the ground poking through the water, grass and plazas.
# `ground` runs game/tools/check_ground.gd (loop 3d-2a, ~2 min, not in --quick): no ground left
# under what covers it whole, no hole where it was left out, the ground on the height rule.
# `streets` runs tools/check_streets.py (map review B): poles on the asphalt, zebras off it,
# grass medians on tram tracks (S1, S2, S4 FAIL; S3, medians in a junction, is reported).
# `handling` runs game/tools/check_handling.gd (G4, 2026-11-01): Cruise's lane change and corner keep
# the slip under a set value, Sport keeps the old feel, the gas is softer (no map; CI too).
# `stopassist` runs game/tools/check_stop_assist.gd (2026-10-31): the car brakes itself into a
# quest's ring from 30-90 km/h and holds for the quest's hold, never touches a car passing or driving
# away, lets BRAKE reverse out; the quests share the ring and "stopped" (no map; CI too).
# `spec` runs tools/check_spec.py (LANDMARKS 0.4): the landmark specs are complete.
# `pois` runs tools/check_pois.py (content POIs, 2026-10-31): the baked corner shops, metro
# entrances, bike docks, Leżaks and zones (Q1-Q6: none on the carriageway, a crossing, a kerb ramp,
# in anything solid or off the map; the density, the egg zone, the odd shares).
# `deckxray` runs game/tools/check_deck_xray.gd (GAMEPLAY_PLAN 0.3, 2026-11-03): the car's x-ray is on
# under a bridge or viaduct deck (Trasa Łazienkowska) and off on top of one and on open streets.
# `lanedrive` runs game/tools/check_lane_drive.gd (PT-21, 2026-11-04): the real car steered along
# lane-graph routes (the P14 narrow streets both ways, the three Trzy mosty legs), no traffic; a stall,
# an unstick, leaving the route or sinking fails it. About 3.5 min (44 sectors built).
# `stuckspots` runs game/tools/check_stuck_spots.gd (PT-1, 2026-11-02): the real car with the gas
# held through the playtest's dead-stop spots; none may stall, need an unstick or lose its speed.
# `stuckoffer` runs game/tools/check_stuck_offer.gd (2026-11-03): the car counts the time spent
# trying to drive in one spot (boxed in, idle, parked, driving on, the tows' reset); no map, CI too.
# `finite` runs game/tools/check_finite.gd (the NaN car, 2026-11-02): every map height, lane and
# junction curve the car and the traffic read is a number, the car's own step stays finite, and a
# NaN written into its stick, steering, pedal or position is dropped or put back (~2 min, map index).
# `tiers` and `governor` (loop G1): the device tiers and the pixel image's size rule, and the
# frame governor's rules on scripted frames. `heliview` (GAMEPLAY_PLAN 3.1): the helicopter's framing
# at every height, the view's widening cap and the height cap (check_heli_view.gd, no map).
# Loop MW-1: `places` runs game/tools/check_places.gd: MOJA WARSZAWA's 78 places (Polish +
# English, the 70 characters, the demo box, the brand denylist, reachability as a WARN) and the
# notebook's finding and reward rules on synthetic inputs; it reads only centrum.json (CI too).
# The L-shaped map loop: `edge` runs game/tools/check_edge.gd: the helicopter's clamp along the
# map's outline (random moves, four flights past the inner corner), the rescue spots inside the
# outline, the minimap's mesh over the corner left outside; centrum.json only (CI too).
# The edge roadworks (2026-11-02): `roadworks` runs game/tools/check_edge_roadworks.gd: every road
# leaving the map closed by roadworks, the traffic shut there, rays through the barriers, the budget;
# centrum.json only (CI too). `roadworks-prebuilt` runs game/tools/check_edge_prebuilt.gd: the prebuilt
# city (the phone's) has the closures' meshes, and the real car rammed into each one stops.
# Loop MW-5: `radio` also checks PÓŁNOC FM (its 7 tracks and seams, the hours, reruns, the host,
# the unlocks); `sounds` runs game/tools/check_city_sounds.gd: the city's sounds at the notebook's
# places (the emitters, the hours, the cap of 8, the bells, the 02:00 beat); centrum.json only (CI too).
# Loop MW-6: `eggs` runs game/tools/check_eggs.gd: the 47 egg cards (words, places, rewards), each
# reachable egg's trigger on synthetic inputs (fires with its conditions, not without), the
# waiting ones listed; `tape` runs game/tools/check_tape.gd: KASETA's 20 then cards, the ghosts
# (one draw call, built only within 150 m), the button, the first-play reward and the dither;
# both read only centrum.json (CI too). Loop MW-3: `crowds` runs game/tools/check_crowds.gd: the
# city clock and the Dawn look, the queues, the door, the steps, Plan C, the police's hours, the
# dawn crowd's routes and walkers, the crowd eggs (E03 E04 E10 E14 E15); centrum.json only (CI too).
# Loop MW-2: `parodies` runs game/tools/check_parodies.gd: the stamp card, the detour, the couriers'
# counts, the Frogs' and venues' picks and walls (2D), the Leżaks and metro entrances off the
# lanes, no real brand, the lines and the font, the wall ray on a synthetic facade, the stamps,
# the knock and the two Frogs/Leżak eggs once, the cost; centrum.json only (CI too).
# Loop jobs-2: `jobs2` runs game/tools/check_side_jobs.gd: the courier race (night, 1 in 4, the
# 1.6 × detour rule, the rider's way and speed, a win's +30 zł +30 respect once), the Leżak round-up
# (the pay, the boot of 5, the depots, ten Leżaks on the real map, late, ✕, back by morning), the
# payphone by Plac Konstytucji and E40 once; centrum.json only (CI too).
# Beta values (2026-11-04): `laneassist` runs game/tools/check_lane_assist.gd: the lane assist on
# the real car (a 6° start, a 300 m curve, a deliberate turn, when it must not pull) and the lane's
# direction on the committed map (~10 s).
# Beta values (2026-11-04): `delivery` runs game/tools/check_delivery.gd: the deliveries' minimap
# route from the stands to 60 doors (and from the reverse lane), the heat's words, NASTĘPNE's
# nearest stand and the route's owner rule (the committed centrum.json, headless, ~20 s).
# Loop couriers: `couriers` runs game/tools/check_couriers.gd: the Pędzik couriers waiting at the kebab
# stands at night (1 or 2, none by day, the race's take), the kerb riders on the real lane graph (the
# count in the band, on the kerb line, through the junctions), the swerve / hop on synthetic inputs and
# a car driven at one (never in its footprint), the near miss's line once per 30 s; centrum.json only (CI too).
# Loop MW-4: `life` runs game/tools/check_city_life.gd: the dogs' hours and caps, the horn's rate
# limits, the Wiralek cycle on synthetic dates, the "Na czasie" pay, the Zając, Fat Thursday, the
# life eggs, the meshes and the tick's cost; centrum.json only (CI too). `life-soak` (not in
# --quick, ~3 min) drives the car at the walkers and riders for 10 minutes of play: no overlaps.
# Loop night-buses: `buses` runs game/tools/check_buses.gd: the N sign's hours and mesh, the
# Centralny gatherings on a synthetic clock (rings of 5-8), the bays and stops, the stop figures'
# cap, the horn's rate limit, E23/E24/E25 once each; centrum.json only (CI too).
# Zagłębie Kebabowe (2026-11-02): `zaglebie` runs game/tools/check_zaglebie.gd: the five shops' data,
# signs and words, places on the real lane graph, the pay twists, Szlak Szpili; centrum.json only (CI too).
# The crash scenes (2026-11-01): `crashes` runs game/tools/check_crash_scenes.gd: the police family's
# three shapes in one surface (the ambulance), the `crash_scene` and KEBAB FM lines, spots on the real
# lane graph (main roads, 2+ lanes, no overlaps), the real traffic queueing and going round a scene,
# the timer (first, life, gap); centrum.json only (CI too).
# Sekretny rave (2026-11-06): `rave` runs game/tools/check_rave.gd: the cone, booth and club-room meshes,
# LEKTI's, Ziomek's, the door's and the club's lines (no brand), the rave clock, the door's three
# questions, the lights' poses, the spots and Smoła on the real lane graph; centrum.json only (CI too).
# Nocny spot (2026-11-06): `meet` runs game/tools/check_street_meet.gd: the club's five cars and the
# donut marks (one surface each), every line (no brand, no film names), the night clock, the race's pay
# and the shift grades, the drag's times (perfect < Tadek < ok, lazy loses, nitro wins), both meets and
# the Zieleniecka strip on the real lane graph; centrum.json only (CI too).
# Cinema tour (2026-11-07): `kinotour` runs game/tools/check_kino_tour.gd: the stops on drivable roads by
# their cinemas, the call, the pickup, the pitches, the shots, the scratches on the reel and the pay.
# Boat race (2026-11-06): `boatrace` runs game/tools/check_boat_race.gd: the course from water.bin
# (every ring in open water, in order, the finish last), the boat's pull, turn and banks, a whole race
# with the four boats driven by the rivals' driver (all finish or drop out, the careful one with no
# miss, times spread), three misses -> ODPADASZ -> JESZCZE RAZ / WYJDŹ, the rivals' lines; water.bin only (CI too).
# Dead electric cars (2026-11-06): `evtow` runs game/tools/check_ev_tow.gd: the TESŁO's meshes, Bartek's
# and the stranded drivers' lines (no brand), the sling's pendulum, hook and pay rules, the chargers and
# car spots on the real lane graph; centrum.json only (CI too).
# City-life satire #1, loud cars (2026-11-02): `loud` runs game/tools/check_loud_cars.gd: the taxis'
# family (four shapes, one surface: the supercar), the Browary meet clear of buildings and roads, the
# car_meet / loud_driver / KEBAB FM lines and the rev sound, the real traffic's loud cars (never over
# the cap), the revs and the radio line once; centrum.json only (CI too).
# Crazy drivers (2026-11-05): `crazy` runs game/tools/check_crazy_drivers.gd: the taxis' family (four
# shapes: the Pasatini), the crazy_taxi / crazy_courier / crazy_pasatini / KEBAB FM lines (no real
# marque), 60 s of real traffic through the centre (crazy drivers in racer mode on the lanes, never over
# the cap or two Pasatinis, faster than town cars), the cut-in horn and one line; centrum.json only (CI too).
# The vintage-tram loop: `oldtram` runs game/tools/check_old_tram.gd: the old set's window (weekends
# 09-19, Live Jun-Sep) and one run an hour, the follow count and its reset, the look's draw-call
# budget (2 car meshes, no node added), a run on the real tracks finding E39 once; centrum.json only
# (CI too).
# The tram fleet (2026-11-06): `tramfleet` runs game/tools/check_tram_fleet.gd: the four looks' meshes
# (one surface, size, vertex cap), the eight trams carrying FLEET's looks (never more car meshes than
# three), the vintage swap on an old pair and back, a minute of running; centrum.json only (CI too).
# The railway (docs/design/railway.md T1): `trains` runs game/tools/check_trains.gd: the track graph's
# ways in and out (the map's edges, both tunnel mouths), the cars' meshes (one surface, 400 tris), 40
# simulated minutes: trains come and go, stop at Ochota, Powiśle and Stadion (the long-distance kind
# never), never two on one track piece; centrum.json only (CI too).
# Packs (docs/design/packs.md): `packs` runs game/tools/check_packs.gd: the clubs' and raves' hours on
# synthetic clocks, the formation, the out-and-back loops on a grid and on the real footways and
# cycle paths, the meshes' budgets, the lines (no real brand), a node drawing the packs only near
# the view and its cost, the big guys with tiny dogs; centrum.json only (CI too).
# Kawowy rajd (docs/design/coffee-run.md): `coffeerun` runs game/tools/check_coffee_run.gd: no real
# brand in the run's words, the Polish lines ≤ 70, the dock and café doors real map points near a
# road, the stops close and the clock fair, the pay, the bike's speed cap and meshes; centrum.json
# only (CI too). `coffee` plays the whole run with the autopilot (--trend-job=9): Zuzia's call, the
# ROWERILO dock, the four stamps, the bike back and the BLIK.
# Kibice (docs/design/city-life-satire.md 7): `fans` runs game/tools/check_fans.gd: the match
# evenings, the chant's jump and the smoke, the three groups' room on the real pavements (off the
# roads, out of the buildings), the meshes' budgets, the lines (no brand, no club, no rivals), a
# node drawing the fans only near the stadium, the horn starting a chant; centrum.json only (CI too).
# The garage loop: `garage` runs game/tools/check_garage.gd: Warsztat u Mirka's paints and rules,
# buying and switching (10 seeded walks), the save, the car's paint, Mirek's lines, E01 and E21
# once; no map at all (CI too).
# Loop 3h slice 1: `save` runs game/tools/check_save.gd: save v2 (a version-1 fixture built in the
# check migrates keeping every section, a backup of the old file, the round trip, a newer file never
# overwritten, --nosave writes nothing, settings.cfg's version; save and resume: the [session] spot,
# NOWA GRA's wipe and its save.prev.cfg copy, the title's KONTYNUUJ / NOWA GRA / TAK / NIE); `districts` runs
# game/tools/check_districts.gd: the districts' data, coverage and ties, discovery, the "?" marks,
# completion and the full map's fog; neither needs a map (CI too). Loop 3h slice 2: `syrenki` runs
# game/tools/check_syrenki.gd: the 20 Syrenki's data and words, a find, the reward ladder (the paints
# "scale" at 5 and "silver" at 20, 150 zł at 10, once each), the save round trip and the districts'
# completion; no map (CI too). Loop 3h slice 3: `ladder` runs game/tools/check_ladder.gd: the rival
# ladder's order, thresholds and pace, the gating and the locked prompt's words, the refusal and
# final lines, the save (round trip, a v2/v1 file without [ladder], --nosave writes nothing,
# --ladder=N) and, from the committed centrum.json's lane graph, the final "Trzy mosty"'s three
# bridges (east, west, east), its legs and its start and finish (CI too). Human rivals (2026-11-05):
# `racecuts` runs game/tools/check_race_cuts.gd: the racers' shortcuts (game/data/race_cuts.json from
# tools/race_cuts.py) snap to the lane graph, knowledge per rival, the routing with them never longer,
# 60 races driven with traffic.gd's own cut choice all arrive and some take a cut, the rivals' human
# lines (CI too, map part skipped without centrum.json). Loop 3h slice 4: `first10`
# runs game/tools/check_first10.gd: the guide's ten beats and windows, who gets the guide, three
# synthetic players through the director's rules (each beat in its window, the fallbacks, a beat
# waiting for a job), the first race's rubber band in a 1-D race, the words; `endcard` runs
# game/tools/check_end_card.gd: the end card's trigger on fixture wallets (final + 9 jobs no, + 10
# yes, seen no), the card and its button, the save's [intro]; neither needs a map (CI too).
# `first10-run` (not in --quick, ~12 min) is the headless replay: --first10 --autopilot plays the
# first 10 minutes on the real city (the stand, the guided order, Halina's race, the trap, the
# call, the helicopter, the cassette, Powiśle, the garage) and passes on `first10: OK`. The first-10
# polish: `cassettes` runs game/tools/check_cassettes.gd: the mixtapes on roofs (cassettes.json), the
# helicopter's pickup rule, a pickup's card, respect and PÓŁNOC FM track, the save; no map (CI too).
# The opening flyover: `opening` runs game/tools/check_opening.gd: the first launch's camera flight
# (camera_shots.gd `open_view`) is short, starts on the Palace, ends exactly on the follow view and
# moves smoothly frame to frame; no map (CI too).
# Smooth roads (2026-11-05): `smooth` runs tools/road_smooth.py --check (the map is smoothed: the
# width steps at the joins tapered, the lane lines stitched; its steps and jogs never grow).
# Stairs across the city (2026-11-07): `stairs` runs tools/stairs.py --check (the map's flights carry
# their OSM tags: step count, width, handrails, ramps; map_builder.gd builds the stone flights from them)
# and tools/barrier_tags.py --check (walls, fences and hedges carry their mapped heights, materials and
# fence types, and the Old Town's city walls are on the map).
# Main's road bugs (2026-11-07): `fixes` runs tools/road_fixes.py --check (the map is fixed: no lane
# line or arrow in a junction's mouth, no dot zebras; its ratchets never grow).
# Operation Unslop (2026-11-05): `streetpass` runs tools/street_pass.py --check (the street records in
# docs/streets/ may never get worse), `models` runs tools/model_library.py --check (every model a
# street record names is in the library or on its wanted list), `overrides` runs
# game/tools/check_object_overrides.gd (every id in game/data/road_objects.json names a barrier).
# Road design (2026-11-06): `design` runs tools/road_design.py --check-all (every area applied to the
# map, docs/roads/AREA.json, still builds with no problems: kerbs closed, lanes inside, crossings fit;
# footways and cycle tracks continuous: every path end the new asphalt cut is on a crossing of its kind).
# Street details (2026-11-01): `streetdetails` runs tools/check_street_details.py (the baked props along
# the main line against the map: stale file, blocked spots, budget, kiosk spacing); `streetmesh` runs
# game/tools/check_street_details.gd (every kind builds as one surface, a cell's triangle budget); CI too.
# Ratusz Arsenał (2026-11-07): `ratuszhub` runs game/tools/check_ratusz_hub.gd (the hub's canopies, tower and
# railings against the committed map, its one mesh's budget, the station's entrance forms, tram passengers); CI too.
# Park details (2026-11-01): `parkdetails` runs tools/check_park_details.py (the baked park pieces against the map: stale file,
# blocked spots, budget); `parkmesh` runs game/tools/check_park_details.gd (every kind builds as one surface); CI too.
# Monuments (2026-11-02): `monuments` runs tools/check_monuments.py (the OSM monuments and wall plaques against
# the map: stale file, blocked spots, plaques on walls, hand-built monuments left alone); `monumentmesh` runs
# game/tools/check_monuments.gd (every kind builds as one surface, a cell's triangle budget with the park pieces); CI too.
# The Złote Tarasy 3D corner screen (2026-11-05): `tarasyscreen` runs game/tools/check_tarasy_screen.gd (one surface, 40-60 m, on Skylight's wall, over the plate).
# The Warsaw Spire (2026-11-06): `spiremotion` runs game/tools/check_spire_motion.gd (the crown's ticker and the plaza jets: one surface each, the ticker on the crown's ring, the jets in the water, the shaders load).
# Bus stops (G8/G9, 2026-11-01): `stops` runs tools/check_stops.py (every bus-road shelter on the kerb and
# turned to the road, benches facing the walk, none in a building or the water, cafe sets on a shopfront).
# The main line (2026-10-31): `mainline` runs game/tools/check_main_line.gd: main_line.gd's step from
# the facts in each chapter (the guide, the ladder, the final, the jobs to the end card), its words
# and the ladder's pacing (the side quests' respect to the final); no map (CI too).
# The chatter budget (docs/GAMEPLAY_PLAN.md 0.2, 2026-11-03): `chatter` runs game/tools/check_chatter.gd:
# 60 s pinned with traffic and people near gives no city line (quest lines still show), at most 2
# bubbles and a gap between new ones, one reaction in 20 s, the setting's gaps, the ride's merged
# star toast; no map (CI too).
# `streaming` runs game/tools/check_streaming.gd
# (loop 3c) WITH a renderer (a window opens for a minute or two): every sector built from its
# file is the whole city, vertex for vertex; 10 spots rendered with --monolithic and with the
# prebuilt sectors streamed differ in at most 0.5 % of their pixels; a 3-minute soak over every
# sector misses no sector the car or the view needs (the 15-minute soak: README "Sectors and
# streaming"); loop 3d-2b: and two fast passes (the helicopter at its highest, the car at 45 m/s)
# miss none either; the loading fix (2026-10-31): five more (the helicopter low with turns, a car to
# helicopter switch, the start, looks at far targets, jumps): no proxy close up (~13 min in all).
# Loop 3g-1 (police, docs/design/police.md section 15): `police` runs game/tools/check_police.gd
# (P11 lines and flow, P12 the state machine with synthetic inputs); `police-runs` the scripted
# game runs P1-P7 on the prebuilt city (the lizak, the trap stop, an escape, caught, the three
# caps, the start grace, the cooldown), each judged by its `police:` lines, the złoty the same
# before and after, then (loop 3g-2) part two's runs: the escort, the guards, the clamp, the
# first contact, the kebab's frozen heat, a race's escape; `police-soak` P13, the autopilot roaming Busy traffic with the police on at
# once (NW_SOAK_MINUTES of play, default 3; the full soak is 10: NW_SOAK_MINUTES=10
# tools/verify.sh --only=police-soak, ~70 s).
# Every game run is headless, passes --nosave and quits by itself (--quit-after; Godot also
# gets --fixed-fps 60 so a run covers the same game time on any Mac and its outcome repeats).
# A run passes when Godot exits 0 and prints no ERROR / WARNING lines; autopilot runs also
# report their outcome (WARN if the job, race or rescue hadn't finished when the run ended).
# Nothing here writes the save or settings or talks to a phone; the only download is the map pack
# (tools/setup_map.sh, when game/map has no lod2/terrain files; NW_MAP_PACK=off skips it).
# What it can't check: screenshots (tools/shots.sh, then look), the bench, the phone.
#
# Exit code: 0 when nothing FAILED (WARN is allowed), 1 otherwise, 2 for a usage error.

emulate -L zsh
setopt pipe_fail
zmodload zsh/datetime

ROOT=${0:A:h:h}
GAME=$ROOT/game
GODOT=${GODOT:-godot}
STEPS_ALL=(map roads smooth fixes stairs streets outline pois streetdetails streetpass design models overrides stops streetmesh ratuszhub parkdetails parkmesh monuments monumentmesh spiremotion tarasyscreen spec lod2 courts drape ground drive drive-prebuilt deckxray stuckspots stuckspots-prebuilt lanedrive finite steering laneassist stuckoffer handling stopassist questlines stories settings credits language tiers governor heliview hud places edge roadworks roadworks-prebuilt eggs tape crowds life buses zaglebie crashes rave meet boatrace kinotour evtow loud crazy oldtram tramfleet trains packs wellness fans coffeerun garage save districts syrenki cassettes ladder racecuts first10 mainline chatter endcard opening parodies jobs2 rescues couriers delivery rides cost landmarks oldtownroofs roofdress tenementtrim osmroofs sites meshq sfx juice gamepad radio sounds water water-prebuilt streaming police plain ram teleport firstlife heli race trzy-mosty first10-run kebab coffee ride ride-police splash rain prebuilt classic police-runs police-soak life-soak)
STEPS_QUICK=(map roads smooth fixes stairs streets outline pois streetdetails streetpass design models overrides stops streetmesh ratuszhub parkdetails parkmesh monuments monumentmesh spiremotion tarasyscreen spec drape drive deckxray stuckspots finite steering laneassist stuckoffer handling stopassist questlines stories settings credits language tiers governor heliview hud places edge roadworks eggs tape crowds life buses zaglebie crashes rave meet boatrace kinotour evtow loud crazy oldtram tramfleet trains packs wellness fans coffeerun garage save districts syrenki cassettes ladder racecuts first10 mainline chatter endcard opening parodies jobs2 rescues couriers delivery rides cost landmarks oldtownroofs roofdress tenementtrim osmroofs sites meshq sfx juice gamepad radio sounds police plain ram teleport firstlife prebuilt)
# Operation Unslop review (2026-11-05): the road loop ran the whole --quick (~100 steps, most start
# the game) after every tweak. --roads keeps only the steps a road rule can break; steps not in
# STEPS_ALL on this branch (e.g. `smooth` before the smooth-roads PR) are skipped.
STEPS_ROADS=(map roads streets streetdetails streetpass design models overrides smooth fixes drive stuckspots)
# Loop 3g-1: minutes of play in the police soak (P13; the full one is 10).
SOAK_MINUTES=${NW_SOAK_MINUTES:-3}
# Longest a single step may take, in seconds, before it is stopped (macOS has no `timeout`).
STEP_LIMIT=${NW_STEP_LIMIT:-900}

# A fresh clone or worktree has no game/.godot class cache yet: every script step then fails
# with "Could not find type PhantomCameraHost" (or hangs). Import once first (~3 s).
if [[ ! -f $GAME/.godot/global_script_class_cache.cfg ]]; then
	print "verify: importing the project first (no game/.godot yet)"
	$GODOT --headless --path $GAME --import > /dev/null 2>&1
fi

want=()
quick=0
roadset=0
ios=0
logs=""
for arg in "$@"; do
	case $arg in
		--quick) quick=1 ;;
		--roads) roadset=1 ;;
		--ios) ios=1 ;;
		--logs=*) logs=${arg#--logs=} ;;
		--only=*) want=(${(s:,:)${arg#--only=}}) ;;
		--list) print -r -- "steps: ${STEPS_ALL[*]} ios"; exit 0 ;;
		-h|--help) sed -n '2,25p' $0; exit 0 ;;
		*) print -r -- "unknown option $arg (try --help)"; exit 2 ;;
	esac
done
if (( ${#want} == 0 )); then
	if (( roadset )); then want=(${STEPS_ROADS:*STEPS_ALL})
	elif (( quick )); then want=($STEPS_QUICK); else want=($STEPS_ALL); fi
	(( ios )) && want+=(ios)
fi
for s in $want; do
	if (( ! ${STEPS_ALL[(Ie)$s]} )) && [[ $s != ios ]]; then
		print -r -- "unknown step '$s' (try --list)"; exit 2
	fi
done

if ! command -v $GODOT > /dev/null; then
	print -r -- "FAIL: '$GODOT' not found (Godot 4.7.2; set GODOT=/path/to/godot)"; exit 1
fi
[[ -z $logs ]] && logs=$ROOT/build/verify/$(strftime %Y%m%d-%H%M%S $EPOCHSECONDS)
mkdir -p $logs || exit 1

# Another Godot running (a bench, screenshots, another agent) makes this run slower and
# disturbs its frame times: say so, don't wait. (pgrep -x matches the process name only,
# so it never matches this script's own command line.)
others=$(pgrep -x Godot | wc -l | tr -d ' ')

rows=()
fails=0
warns=0
passes=0

# row RESULT NAME SECONDS DETAIL
row() {
	local res=$1 name=$2 secs=$3 detail=$4
	case $res in
		PASS) (( passes++ )) ;;
		WARN) (( warns++ )) ;;
		*) (( fails++ )) ;;
	esac
	rows+=("$(printf '%-24s %-5s %5ss  %s' "$name" "$res" "$secs" "$detail")")
	printf '%-24s %-5s %5ss  %s\n' "$name" "$res" "$secs" "$detail"
}

# limited SECONDS CMD...: run CMD, stop it after SECONDS (exit code 142 = stopped).
limited() {
	local secs=$1; shift
	perl -e 'alarm shift; exec @ARGV or die "cannot run $ARGV[0]: $!\n"' $secs "$@"
}

# problems LOG: the ERROR / WARNING lines Godot printed (push_error, push_warning, script
# errors, engine errors), one per line.
problems() {
	grep -E '^(ERROR|WARNING|SCRIPT ERROR|SCRIPT WARNING|USER ERROR|USER WARNING|Parse Error)' $1
}

# check NAME OKLINE GODOTARGS...: a SceneTree check script that prints an OK line.
check() {
	local name=$1 okline=$2; shift 2
	local logf=$logs/$name.log t0=$EPOCHREALTIME code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . "$@" ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local last=$(grep -E "$okline" $logf | tail -1)
	if (( code == 142 )); then
		row FAIL $name $secs "stopped after ${STEP_LIMIT}s: $logf"
	elif [[ -n $last ]] && grep -qE "${okline}.*OK" <<< $last && (( code == 0 && np == 0 )); then
		# Loop radio-playlists: a "<name>: WARN ..." line before the OK line makes the row a WARN.
		local warn=$(grep -m1 -E "^${name}: WARN" $logf)
		if [[ -n $warn ]]; then
			row WARN $name $secs "${warn[1,140]}"
		else
			row PASS $name $secs "$last"
		fi
	else
		local first=$(problems $logf | head -1)
		[[ -z $first ]] && first=${last:-"no result line"}
		row FAIL $name $secs "exit $code, $np error/warning lines: ${first[1,140]} ($logf)"
	fi
}

# shown NAME OKLINE GODOTARGS...: like check, with a renderer (loop 3c: pixels and meshes' data).
shown() {
	local name=$1 okline=$2; shift 2
	local logf=$logs/$name.log t0=$EPOCHREALTIME code
	( cd $GAME && limited $STEP_LIMIT $GODOT --path . --resolution 1280x720 "$@" ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local last=$(grep -E "$okline" $logf | tail -1)
	if (( code == 142 )); then
		row FAIL $name $secs "stopped after ${STEP_LIMIT}s: $logf"
	elif [[ -n $last ]] && grep -qE "${okline}.*OK" <<< $last && (( code == 0 && np == 0 )); then
		row PASS $name $secs "$last"
	else
		local first=$(problems $logf | head -1)
		[[ -z $first ]] && first=$(grep -m1 'PROBLEM' $logf)
		[[ -z $first ]] && first=${last:-"no result line"}
		row FAIL $name $secs "exit $code, $np error/warning lines: ${first[1,140]} ($logf)"
	fi
}

# game NAME FRAMES OUTCOME GAMEARGS...: a headless game run with --nosave that quits after
# FRAMES frames; OUTCOME is a regex for the line that says the activity finished ("" = none).
game() {
	local name=$1 frames=$2 outcome=$3; shift 3
	local logf=$logs/run_$name.log t0=$EPOCHREALTIME code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . --fixed-fps 60 --quit-after $frames \
		-- --nosave --notitle "$@" ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local built=$(grep -m1 '^city built in' $logf)
	local label="run: $name"
	if (( code == 142 )); then
		row FAIL "$label" $secs "stopped after ${STEP_LIMIT}s ($logf)"
	elif (( code != 0 || np > 0 )); then
		local first=$(problems $logf | head -1)
		row FAIL "$label" $secs "exit $code, $np error/warning lines: ${${first:-crash, see log}[1,140]} ($logf)"
	elif [[ -z $built ]]; then
		row FAIL "$label" $secs "no 'city built' line: the city never finished building ($logf)"
	elif [[ -n $outcome ]]; then
		local fin=$(grep -E -m1 "$outcome" $logf)
		if [[ -n $fin ]]; then
			row PASS "$label" $secs "0 errors · ${fin[1,110]}"
		else
			row WARN "$label" $secs "0 errors, but no '$outcome' line in $frames frames ($(( frames / 60 )) s of play)"
		fi
	else
		row PASS "$label" $secs "0 errors · ${built[1,110]}"
	fi
}

# Loop 3g-1: one police run (prebuilt city, --police-log); its log is $RUN_LOG and the caller
# judges its lines. P_FAIL collects what went wrong, P_NOTE what each run showed.
P_FAIL=()
P_NOTE=()
police_run() {
	local tag=$1 frames=$2; shift 2
	local logf=$logs/police_$tag.log code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . --fixed-fps 60 --quit-after $frames \
		-- --nosave --notitle --prebuilt --police-log "$@" ) > $logf 2>&1
	code=$?
	local np=$(problems $logf | wc -l | tr -d ' ')
	if (( code != 0 || np > 0 )); then
		P_FAIL+=("$tag: exit $code, $np error/warning lines: $(problems $logf | head -1 | cut -c1-100)")
	fi
	# The złoty never change: every "wallet A zł → B zł" line has A = B.
	local bad=$(grep -E '^police: wallet [0-9]+ zł → [0-9]+ zł' $logf | awk '{ if ($3 != $6) print }' | head -1)
	[[ -n $bad ]] && P_FAIL+=("$tag: the złoty changed: $bad")
	RUN_LOG=$logf
}

# frame_of PATTERN LOG: the frame of the first `police:` line matching PATTERN (-1 if none).
frame_of() {
	local line=$(grep -E -m1 "$1" $2)
	[[ -z $line ]] && { print -- -1; return; }
	print -- ${${line##*\(frame }%%,*}
}

# expect TAG PATTERN LOG [NOTE]: the run printed a line matching PATTERN.
expect() {
	if grep -qE "$2" $3; then
		[[ -n $4 ]] && P_NOTE+=("$1 $4")
	else
		P_FAIL+=("$1: no line matching '$2' ($3)")
	fi
}

police_runs() {
	local t0=$EPOCHREALTIME f a b l
	P_FAIL=()
	P_NOTE=()
	# P1: the lizak within 0.4 s of the radar's 40 m (≥ 28 m before the officer at ~30 m/s), and
	# koguty 1 at most 1 s after passing the officer by 30 m (≤ 60 m past).
	police_run p1 900 --trap=2 --pedal=gas --police-now; f=$RUN_LOG
	expect P1 '^police: lizak \(trap 2, [0-9]+ km/h in 50, (2[89]|3[0-9]|40)\.[0-9] m before' $f "lizak"
	expect P1 '^police: L1 \(lizak ignored, [3-5][0-9]\.[0-9] m past' $f "L1"
	# P2: stopped by the officer: the pull-over (trap), the caution ≤ 10 s later, no chase.
	police_run p2 1500 --trap=2 --pedal=gas --police-auto=stop --police-now; f=$RUN_LOG
	expect P2 '^police: stopped 1?[0-9]\.[0-9] m from the officer' $f "stopped"
	a=$(frame_of '^police: pull-over trap' $f); b=$(frame_of '^police: caution n=1' $f)
	(( a > 0 && b > a && b - a <= 600 )) && P_NOTE+=("P2 caution $(printf '%.1f' $(( (b - a) / 60.0 )))s") || P_FAIL+=("P2: pull-over at frame $a, caution at $b ($f)")
	grep -qE '^police: L1' $f && P_FAIL+=("P2: a chase started ($f)")
	# P3: an escape ≤ 30 s after the start, +15 respect.
	police_run p3 2400 --police=1 --police-auto=escape; f=$RUN_LOG
	expect P3 '^police: escaped after ([0-9]|[12][0-9]|30)\.[0-9] s' $f "escaped"
	expect P3 '^wallet: \+15 respect' $f "+15"
	# P4: stopped by the chaser: the pull-over ≤ 2.5 s later, the caution ≤ 10 s after it.
	police_run p4 1300 --police=1 --police-auto=stop; f=$RUN_LOG
	a=$(frame_of '^police: stopped by unit' $f); b=$(frame_of '^police: pull-over' $f); l=$(frame_of '^police: caution' $f)
	(( a > 0 && b >= a && b - a <= 150 && l > b && l - b <= 600 )) && P_NOTE+=("P4 pull-over $(printf '%.1f' $(( (b - a) / 60.0 )))s, caution $(printf '%.1f' $(( (l - b) / 60.0 )))s") \
		|| P_FAIL+=("P4: stopped at frame $a, pull-over $b, caution $l ($f)")
	# P5: the caps, 30 / 40 / 45 s ± 0.5 s (no other traffic: no second unit raises the level).
	police_run p5_1 2100 --police=1 --police-auto=hold --traffic=empty; f=$RUN_LOG
	expect P5 '^police: end of shift after (29\.[5-9]|30\.[0-5]) s \(L1\)' $f "30s"
	police_run p5_2 2700 --police=2 --police-auto=hold --traffic=empty; f=$RUN_LOG
	expect P5 '^police: end of shift after (39\.[5-9]|40\.[0-5]) s \(L2\)' $f "40s"
	police_run p5_3 3000 --police=3 --police-auto=hold --traffic=empty; f=$RUN_LOG
	expect P5 '^police: end of shift after (44\.[5-9]|45\.[0-5]) s \(L3\)' $f "45s"
	# P6: the start grace: speeding through the trap gives nothing (before 60 s), never a chase.
	police_run p6 900 --trap=2 --pedal=gas; f=$RUN_LOG
	expect P6 '^police: trap 2: .*\(grace\)' $f "grace"
	grep -qE '^police: (L1|lizak)' $f && P_FAIL+=("P6: a lizak or a chase in the grace ($f)")
	# P7: after a chase (caught), two offences 60 s apart warn in the cooldown; a ram chases.
	police_run p7 7800 --police=1 --police-auto=stop --police-offence=4000:speed,7600:speed,7700:ram; f=$RUN_LOG
	a=$(grep -cE '^police: warn speed \(cooldown\)' $f)
	(( a == 2 )) && P_NOTE+=("P7 2 warnings") || P_FAIL+=("P7: $a 'warn speed (cooldown)' lines, want 2 ($f)")
	expect P7 '^police: L1 \(ram\)' $f "ram→L1"
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	if (( ${#P_FAIL} == 0 )); then
		row PASS "run: police P1-P7" $secs "0 errors · ${(j:, :)P_NOTE}"
	else
		row FAIL "run: police P1-P7" $secs "${P_FAIL[1][1,150]} (+$(( ${#P_FAIL} - 1 )) more)"
		print -rl -- "  ${^P_FAIL}"
	fi
	police_runs2
}

# Loop 3g-2 (police, part two): the escort on rescue 9 (joins +10 s, leads 12-26 m ahead), the
# guards (the whistle and the 3 s run, no chase; the talk on stopping by one), the clamp (on 10 s
# after the countdown, off 10 s later or at once on Przepraszam), the first contact (the routine
# check), the kebab's heat frozen on the card, a race's escape marked +20 %. Same judging as P1-P7.
police_runs2() {
	local t0=$EPOCHREALTIME f
	P_FAIL=()
	P_NOTE=()
	police_run e1 2400 --mission=9 --escort --police-auto=follow --traffic=empty; f=$RUN_LOG
	expect E1 '^police: escort joined \(unit [0-9]+, .*rescue clock \+10 s' $f "joined +10s"
	expect E1 '^police: escort status: lead, (1[2-9]|2[0-6]) m ahead' $f "leads"
	police_run g1 1500 --guards --zone-cap; f=$RUN_LOG
	expect G1 '^guard: whistle \(post ' $f "whistle"
	expect G1 '^guard: gave up ' $f "run 3s"
	grep -qE '^guard: guard car following' $f && P_NOTE+=("G1 car follows")
	grep -qE '^police: (L1|L2|L3|warn)' $f && P_FAIL+=("G1: the police reacted to the guards' zone ($f)")
	police_run g2 1500 --guards=talk; f=$RUN_LOG
	expect G2 '^police: guard talk done' $f "talk"
	police_run c1 1500 --clamp; f=$RUN_LOG
	expect C1 '^guard: clamp on \(10\.0 s' $f "on"
	expect C1 '^guard: clamp off \(10 s\)' $f "off 10s"
	police_run c2 900 --clamp=sorry; f=$RUN_LOG
	expect C2 '^guard: clamp off \(sorry' $f "sorry"
	police_run f1 1500 --first-contact --pedal=gas --police-auto=stop; f=$RUN_LOG
	expect F1 '^police: first contact done \(routine check\)' $f "routine"
	grep -qE '^police: L1' $f && P_FAIL+=("F1: a chase started ($f)")
	police_run k1 900 --kebab=1 --pullover=kebab --police-auto=stop; f=$RUN_LOG
	expect K1 '^police: kebab heat frozen' $f "frozen"
	expect K1 '^police: kebab heat runs again' $f "runs again"
	police_run r1 2400 --race=1 --police=1 --police-auto=escape; f=$RUN_LOG
	expect R1 '^police: race marked \+20 %' $f "+20%"
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	if (( ${#P_FAIL} == 0 )); then
		row PASS "run: police part two" $secs "0 errors · ${(j:, :)P_NOTE}"
	else
		row FAIL "run: police part two" $secs "${P_FAIL[1][1,150]} (+$(( ${#P_FAIL} - 1 )) more)"
		print -rl -- "  ${^P_FAIL}"
	fi
}

# Loop 3g-1, P13: the autopilot roams Busy traffic with the police on from the start (runtime
# city). Passes with no errors, every chase that started ended (one may still run at the end),
# the złoty unchanged, the car never within 20 % of a screen edge in a chase (B4), the police
# cars within 1.5 m of a lane.
police_soak() {
	local t0=$EPOCHREALTIME frames=$(( SOAK_MINUTES * 3600 )) logf=$logs/run_police-soak.log code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . --fixed-fps 60 --quit-after $frames \
		-- --nosave --notitle --autopilot --traffic=busy --police-now --police-log ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local end=$(grep -m1 -E '^police: wallet [0-9]+ zł → [0-9]+ zł \(end' $logf)
	local label="run: police soak ${SOAK_MINUTES} min"
	if (( code != 0 || np > 0 )); then
		row FAIL "$label" $secs "exit $code, $np error/warning lines: $(problems $logf | head -1 | cut -c1-100) ($logf)"
		return
	fi
	if [[ -z $end ]]; then
		row FAIL "$label" $secs "no end line ($logf)"
		return
	fi
	local zl0=${${end#police: wallet }%% zł*} zl1=${${end#*→ }%% zł*}
	local started=${${end#*chases }%% started*} ended=${${end#*started, }%% ended*}
	local running=0
	[[ $end == *"1 running"* ]] && running=1
	local b4=${${end#*edge }%%;*} lanes=${${end#*lanes worst }%% m*}
	if (( zl0 != zl1 )); then
		row FAIL "$label" $secs "the złoty changed: $zl0 → $zl1 ($logf)"
	elif (( started != ended + running )); then
		row FAIL "$label" $secs "$started chases started, $ended ended ($logf)"
	elif (( b4 < 0.2 )); then
		row FAIL "$label" $secs "B4: the car came within $b4 of a screen edge in a chase ($logf)"
	elif (( lanes > 1.5 )); then
		row FAIL "$label" $secs "a police car $lanes m off its lane ($logf)"
	else
		row PASS "$label" $secs "0 errors · $started chases ($ended ended), wallet $zl0 zł → $zl1 zł, B4 ≥ $b4, lanes ≤ $lanes m"
	fi
}

# Loop MW-4 (vision 5's acceptance): the car driven at the dog walkers and riders for
# NW_LIFE_SOAK_MINUTES of play (default 10) on a Friday dusk; passes with no errors, some met and
# no dog, walker or rider ever inside the car's footprint (`life: soak done ... overlaps 0`).
life_soak() {
	local mins=${NW_LIFE_SOAK_MINUTES:-10}
	local t0=$EPOCHREALTIME frames=$(( mins * 3600 )) logf=$logs/run_life-soak.log code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . --fixed-fps 60 --quit-after $frames \
		-- --nosave --notitle --life-soak ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local end=$(grep -m1 '^life: soak done' $logf)
	local label="run: life soak $mins min"
	if (( code != 0 || np > 0 )); then
		row FAIL "$label" $secs "exit $code, $np error/warning lines: $(problems $logf | head -1 | cut -c1-100) ($logf)"
	elif [[ -z $end ]]; then
		row FAIL "$label" $secs "no 'life: soak done' line ($logf)"
	elif [[ $end != *"overlaps 0 "* ]]; then
		row FAIL "$label" $secs "${end[1,140]} ($logf)"
	elif [[ $end == *"dogs met 0 "* ]]; then
		row WARN "$label" $secs "met no dog: ${end[1,120]}"
	else
		row PASS "$label" $secs "0 errors · ${end[7,130]}"
	fi
}

# Loop 2d-1 x 3g-1: ride 8 with a pull-over at frame 1500; passes with no errors, exactly one
# `ride: stars 4.0 (police −1.0)` line and the pull-over done.
ride_police() {
	local logf=$logs/run_ride-police.log t0=$EPOCHREALTIME code
	( cd $GAME && limited $STEP_LIMIT $GODOT --headless --path . --fixed-fps 60 --quit-after 2400 \
		-- --nosave --notitle --prebuilt --ride=8 --passenger=believer --ride-quirk=river --autopilot --parody-log \
		--police-log --pullover=generic --pullover-frame=1500 ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	local np=$(problems $logf | wc -l | tr -d ' ')
	local stars=$(grep -c -- '(police −' $logf)
	local one=$(grep -m1 '^ride: stars 4\.0 (police −1\.0)' $logf)
	if (( code == 0 && np == 0 && stars == 1 )) && [[ -n $one ]] && grep -q '^police: pull-over done' $logf; then
		row PASS "run: ride-police" $secs "0 errors · $one, once"
	else
		row FAIL "run: ride-police" $secs "exit $code, $np error lines, $stars police star lines, '${one:-none}' ($logf)"
	fi
}

run_ios() {
	local t0=$EPOCHREALTIME logf=$logs/ios.log code
	( limited $STEP_LIMIT $ROOT/tools/export_ios.sh && cd $ROOT && limited $STEP_LIMIT xcodebuild \
		-project build/ios/NocnaWarszawa.xcodeproj -scheme NocnaWarszawa \
		-destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build ) > $logf 2>&1
	code=$?
	local secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
	if (( code == 0 )) && grep -q 'BUILD SUCCEEDED' $logf; then
		row PASS "ios export + build" $secs "BUILD SUCCEEDED (unsigned, generic iOS); sectors rebuilt"
	else
		local first=$(grep -m1 -E 'error:|BUILD FAILED|ERROR' $logf)
		row FAIL "ios export + build" $secs "exit $code: ${${first:-see log}[1,140]} ($logf)"
	fi
}

print -r -- "Around Warsaw verify · $(strftime '%Y-%m-%d %H:%M' $EPOCHSECONDS) · $($GODOT --version 2>/dev/null | tail -1) · logs $logs"
(( others > 0 )) && print -r -- "note: $others other Godot process(es) running: timings here are slower, and a bench running beside this is disturbed"
print -r -- ""

# Loop 3d-1: the sector split and the prebuilt sectors are derived and not committed (a fresh
# clone has none): make them first when they are missing (tools/setup_map.sh, ~20 s, a window
# opens). Stale ones (made from other inputs) stay a WARN of the map step, as before.
# The prebuilt bake needs a window: on Linux with no display (a cloud container) it runs under
# xvfb-run when there is one; with neither, the steps that need the prebuilt city are skipped as a
# WARN instead of failing on files that were never made (2026-11-02).
no_prebuilt=0
if ! python3 -I $ROOT/tools/check_map_data.py --fresh > $logs/setup_map.log 2>&1 && grep -q 'missing' $logs/setup_map.log; then
	print -r -- "note: $(head -1 $logs/setup_map.log); running tools/setup_map.sh (a window opens)"
	local -a wrap=()
	if [[ $OSTYPE == linux* && -z $DISPLAY && -z $WAYLAND_DISPLAY ]]; then
		if (( $+commands[xvfb-run] )); then
			wrap=(xvfb-run -a -s "-screen 0 1280x720x24")
		else
			no_prebuilt=1
			print -r -- "note: no display and no xvfb-run: the prebuilt city can't be baked here, its steps are skipped (install xvfb)"
		fi
	fi
	if (( no_prebuilt )); then
		python3 -I $ROOT/tools/bake_sectors.py >> $logs/setup_map.log 2>&1 \
			|| print -r -- "note: tools/bake_sectors.py failed ($logs/setup_map.log): the game runs below will fail"
	elif ! $wrap $ROOT/tools/setup_map.sh >> $logs/setup_map.log 2>&1; then
		print -r -- "note: tools/setup_map.sh failed ($logs/setup_map.log): the game runs below will fail"
	fi
fi
## skip_prebuilt NAME: true (and a WARN row) when the prebuilt city could not be baked here.
skip_prebuilt() {
	(( no_prebuilt )) || return 1
	row WARN "$1" 0 "skipped: no display to bake the prebuilt city (install xvfb, or run on the Mac)"
	return 0
}

for s in $want; do
	case $s in
		map)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_map_data.py > $logs/map.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			stale=$(grep '^WARN' $logs/map.log | head -1)
			if (( code != 0 )); then
				row FAIL "map data" $secs "$(grep -m1 '^FAIL' $logs/map.log) ($logs/map.log)"
			elif [[ -n $stale ]]; then
				row WARN "map data" $secs "counts OK; ${stale[1,150]}"
			else
				row PASS "map data" $secs "trees3d, pois, graph, palm as expected, over the sectors too; the prebuilt sectors up to date"
			fi ;;
		# Loop 3a: roads, decks, tunnels and the lane graph over the whole map (C1-C10, docs/DEMO.md 4.5).
		roads)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_roads.py --png=$logs/check_roads.png \
				--json=$logs/check_roads.json > $logs/roads.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_roads counts:' $logs/roads.log)
			counts=${counts#check_roads counts: }
			case $code in
				0) row PASS "roads" $secs "check_roads: OK · not allowed/found: $counts" ;;
				*) row FAIL "roads" $secs "$(grep -m1 '^check_roads:' $logs/roads.log) · $counts ($logs/roads.log)" ;;
			esac ;;
		# Map review B (2026-10-29): the streets at grade (poles on the asphalt, zebras off it,
		# grass medians on tram tracks; tools/check_streets.py S1-S4).
		streets)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_streets.py > $logs/streets.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_streets counts:' $logs/streets.log)
			counts=${counts#check_streets counts: }
			case $code in
				0) row PASS "streets" $secs "check_streets: OK · $counts" ;;
				*) row FAIL "streets" $secs "$(grep -m1 '^check_streets:' $logs/streets.log) · $counts ($logs/streets.log)" ;;
			esac ;;
		# Map north (2026-10-31): nothing of the map where the map isn't (its bounds without the
		# corner left `outside`), every sector on the map (tools/check_outline.py O1-O5; O6, dead
		# ends on the extension's edge, reported).
		outline)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_outline.py > $logs/outline.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_outline counts:' $logs/outline.log)
			counts=${counts#check_outline counts: }
			case $code in
				0) row PASS "outline" $secs "check_outline: OK · $counts" ;;
				*) row FAIL "outline" $secs "$(grep -m1 '^check_outline:' $logs/outline.log | tail -1) · $counts ($logs/outline.log)" ;;
			esac ;;
		# Content POIs (2026-10-31): the street pois of tools/bake_street_pois.py (corner shops, metro
		# entrances, bike docks, the Leżaks and their zones): Q1-Q6 of tools/check_pois.py over the whole
		# map (no scooter on a carriageway, crossing or kerb ramp, in anything solid, off the map; ~4 s).
		pois)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_pois.py > $logs/pois.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_pois counts:' $logs/pois.log)
			counts=${counts#check_pois counts: }
			case $code in
				0) row PASS "pois" $secs "check_pois: OK · $counts" ;;
				*) row FAIL "pois" $secs "$(grep '^check_pois: ' $logs/pois.log | tail -1) · $counts ($logs/pois.log)" ;;
			esac ;;
		streetdetails)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_street_details.py > $logs/streetdetails.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_street_details counts:' $logs/streetdetails.log)
			counts=${counts#check_street_details counts: }
			case $code in
				0) row PASS "streetdetails" $secs "check_street_details: OK · $counts" ;;
				*) row FAIL "streetdetails" $secs "$(grep '^check_street_details: ' $logs/streetdetails.log | tail -1) · $counts ($logs/streetdetails.log)" ;;
			esac ;;
		fixes)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/road_fixes.py --check > $logs/fixes.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			case $code in
				0) row PASS "fixes" $secs "$(grep '^road_fixes: ' $logs/fixes.log | tail -1)" ;;
				*) row FAIL "fixes" $secs "$(grep '^road_fixes: ' $logs/fixes.log | tail -1) ($logs/fixes.log)" ;;
			esac ;;
		smooth)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/road_smooth.py --check > $logs/smooth.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			case $code in
				0) row PASS "smooth" $secs "$(grep '^road_smooth: ' $logs/smooth.log | tail -1)" ;;
				*) row FAIL "smooth" $secs "$(grep '^road_smooth: ' $logs/smooth.log | tail -1) ($logs/smooth.log)" ;;
			esac ;;
		stairs)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/stairs.py --check > $logs/stairs.log 2>&1 && \
				python3 -I $ROOT/tools/barrier_tags.py --check >> $logs/stairs.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			case $code in
				0) row PASS "stairs" $secs "$(grep '^stairs: ' $logs/stairs.log | tail -1) · $(grep '^barrier_tags: ' $logs/stairs.log | tail -1)" ;;
				*) row FAIL "stairs" $secs "$(grep '^stairs: ' $logs/stairs.log | tail -1) ($logs/stairs.log)" ;;
			esac ;;
		streetpass)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/street_pass.py --check > $logs/streetpass.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			case $code in
				0) row PASS "streetpass" $secs "$(grep '^street_pass: ' $logs/streetpass.log | tail -1)" ;;
				*) row FAIL "streetpass" $secs "$(grep '^street_pass: ' $logs/streetpass.log | tail -1) ($logs/streetpass.log)" ;;
			esac ;;
		design)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/road_design.py --check-all > $logs/design.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			case $code in
				0) row PASS "design" $secs "$(grep '^road_design: ' $logs/design.log | tail -1)" ;;
				*) row FAIL "design" $secs "$(grep '^road_design: ' $logs/design.log | tail -1) ($logs/design.log)" ;;
			esac ;;
		models)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/model_library.py --check > $logs/models.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^model_library counts:' $logs/models.log)
			counts=${counts#model_library counts: }
			case $code in
				0) row PASS "models" $secs "model_library: OK · $counts" ;;
				*) row FAIL "models" $secs "$(grep '^model_library: ' $logs/models.log | tail -1) ($logs/models.log)" ;;
			esac ;;
		parkdetails)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_park_details.py > $logs/parkdetails.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			case $code in
				0) row PASS "parkdetails" $secs "$(tail -1 $logs/parkdetails.log)" ;;
				*) row FAIL "parkdetails" $secs "$(tail -1 $logs/parkdetails.log) ($logs/parkdetails.log)" ;;
			esac ;;
		parkmesh) check parkmesh '^park_details:' --script res://tools/check_park_details.gd ;;
		overrides) check overrides '^check_object_overrides:' --script res://tools/check_object_overrides.gd ;;
		monuments)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_monuments.py > $logs/monuments.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			case $code in
				0) row PASS "monuments" $secs "$(tail -1 $logs/monuments.log)" ;;
				*) row FAIL "monuments" $secs "$(tail -1 $logs/monuments.log) ($logs/monuments.log)" ;;
			esac ;;
		monumentmesh) check monumentmesh '^monuments:' --script res://tools/check_monuments.gd ;;
		tarasyscreen) check tarasyscreen '^tarasy_screen:' --script res://tools/check_tarasy_screen.gd ;;
		spiremotion) check spiremotion '^spire_motion:' --script res://tools/check_spire_motion.gd ;;
		stops)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_stops.py > $logs/stops.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_stops counts:' $logs/stops.log)
			counts=${counts#check_stops counts: }
			case $code in
				0) row PASS "stops" $secs "check_stops: OK · $counts" ;;
				*) row FAIL "stops" $secs "$(grep '^check_stops: ' $logs/stops.log | tail -1) · $counts ($logs/stops.log)" ;;
			esac ;;
		streetmesh) check streetmesh '^street_details:' --script res://tools/check_street_details.gd ;;
		ratuszhub) check ratuszhub '^ratusz_hub:' --script res://tools/check_ratusz_hub.gd ;;
		# Landmark specs (LANDMARKS 0.4): every docs/landmarks/specs/*.md has all eight sections, a
		# detail level, a triangle budget and a filled parts table (tools/check_spec.py; ~0.1 s).
		spec)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_spec.py --selftest > $logs/spec.log 2>&1 && python3 -I $ROOT/tools/check_spec.py >> $logs/spec.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_spec counts:' $logs/spec.log)
			counts=${counts#check_spec counts: }
			case $code in
				0) row PASS "spec" $secs "check_spec: OK · $counts" ;;
				*) row FAIL "spec" $secs "$(grep '^check_spec: ' $logs/spec.log | tail -1) · $counts ($logs/spec.log)" ;;
			esac ;;
		# Map north: the LoD2 models and the OSM blocks never both (L1), never neither (L2), at most
		# the counts recorded in tools/check_lod2.py (not in --quick: ~35 s; needs lod2.json).
		lod2)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/check_lod2.py --quiet > $logs/lod2.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			counts=$(grep -m1 '^check_lod2 counts:' $logs/lod2.log)
			counts=${counts#check_lod2 counts: }
			case $code in
				0) row PASS "lod2" $secs "$(grep -m1 -E '^check_lod2: (OK|no )' $logs/lod2.log) · $counts" ;;
				*) row FAIL "lod2" $secs "$(grep -m1 '^check_lod2: ' $logs/lod2.log | tail -1) · $counts ($logs/lod2.log)" ;;
			esac ;;
		# Courtyards (2026-11-03): game/data/courts.json is what tools/bake_courts.py makes from
		# today's lod2.bin and centrum.json (the courts landmarks.gd cuts out of its models; ~75 s).
		courts)
			t0=$EPOCHREALTIME
			python3 -I $ROOT/tools/bake_courts.py --check > $logs/courts.log 2>&1
			code=$?
			secs=$(printf '%.0f' $(( EPOCHREALTIME - t0 )))
			case $code in
				0) row PASS "courts" $secs "$(grep -m1 '^courts: ' $logs/courts.log)" ;;
				*) row FAIL "courts" $secs "$(grep -m1 '^courts: ' $logs/courts.log) ($logs/courts.log)" ;;
			esac ;;
		# Loop 3b-2: the bare ground poking through the areas laid on it (water, grass, plazas, sand).
		drape) check drape '^check_drape:' --script res://tools/check_drape.gd ;;
		# Loop 3d-2a: the ground left out under the layers that cover it, no holes, on the heights.
		ground) check ground '^check_ground:' --script res://tools/check_ground.gd ;;
		# Loop 3b: every lane for a car and a bus against the colliders; the autopilot over the
		# bridges and tunnels (height jumps). The runtime city (the prebuilt one: --prebuilt).
		drive) check drive '^check_drive:' --script res://tools/check_drive.gd ;;
		drive-prebuilt) skip_prebuilt drive-prebuilt || check drive-prebuilt '^check_drive:' --script res://tools/check_drive.gd -- --prebuilt ;;
		# PT bug log (docs/PLAYTEST.md): the real car through the spots a playtest found it stopping
		# dead (PT-1: Marszałkowska's Centrum tram stop); the sectors round them, both city paths.
		deckxray) check deckxray '^check_deck_xray:' --script res://tools/check_deck_xray.gd ;;
		lanedrive) check lanedrive '^check_lane_drive:' --fixed-fps 60 --script res://tools/check_lane_drive.gd ;;
		stuckspots) check stuckspots '^check_stuck_spots:' --fixed-fps 60 --script res://tools/check_stuck_spots.gd ;;
		stuckspots-prebuilt) skip_prebuilt stuckspots-prebuilt || check stuckspots-prebuilt '^check_stuck_spots:' --fixed-fps 60 --script res://tools/check_stuck_spots.gd -- --prebuilt ;;
		finite) check finite '^check_finite:' --fixed-fps 60 --script res://tools/check_finite.gd ;;
		steering) check steering 'check_steering:' --fixed-fps 60 --script res://tools/check_steering.gd ;;
		laneassist) check laneassist '^check_lane_assist:' --fixed-fps 60 --script res://tools/check_lane_assist.gd ;;
		# G14's "later" (2026-11-03): trying to drive and going nowhere for 8 s offers the tow.
		stuckoffer) check stuckoffer '^check_stuck_offer:' --fixed-fps 60 --script res://tools/check_stuck_offer.gd ;;
		# The quest stop assist: the car brakes itself into a quest's ring and holds for the hold.
		handling) check handling '^check_handling:' --fixed-fps 60 --script res://tools/check_handling.gd ;;
		stopassist) check stopassist '^check_stop_assist:' --fixed-fps 60 --script res://tools/check_stop_assist.gd ;;
		# G12: the car and heli quest lines (quest_lines.gd) and G10's START RIDE reach.
		questlines) check questlines '^check_quest_lines:' --script res://tools/check_quest_lines.gd ;;
		# Wątki (2026-11-07): the questlines' hours, starts, map badges, quest focus, the WĄTKI tab and
		# the friend walking up in person (story_quests.gd; no map, CI too).
		stories) check stories '^check_story_quests:' --script res://tools/check_story_quests.gd ;;
		settings) check settings '^settings:' --script res://tools/check_settings.gd ;;
		# DEMO 3j: no testing flags in a release build; the credits and licences page (no map; CI too).
		credits) check credits '^check_credits:' --script res://tools/check_credits.gd ;;
		# 2026-11-02: the language choice (lang.gd): one language on every screen, in Polish and in English.
		language) check language '^check_language:' --script res://tools/check_language.gd ;;
		# Loop G1: model id -> tier, the pixel image at the phones' sizes; the governor's rules.
		tiers) check tiers '^check_tiers:' --script res://tools/check_tiers.gd ;;
		governor) check governor '^check_governor:' --script res://tools/check_governor.gd ;;
		heliview) check heliview '^check_heli_view:' --script res://tools/check_heli_view.gd ;;
		# Loop 2e: the HUD at phone size: 44 pt controls, 11 / 13 pt text, the safe area, no overlaps.
		hud) check hud '^check_hud:' --script res://tools/check_hud.gd ;;
		places) check places '^check_places:' --script res://tools/check_places.gd ;;
		edge) check edge '^check_edge:' --script res://tools/check_edge.gd ;;
		# The edge roadworks (2026-11-02): every road leaving the map closed, traffic stopped there, solid.
		roadworks) check roadworks '^check_edge_roadworks:' --script res://tools/check_edge_roadworks.gd ;;
		roadworks-prebuilt) skip_prebuilt roadworks-prebuilt || check roadworks-prebuilt '^check_edge_prebuilt:' --fixed-fps 60 --script res://tools/check_edge_prebuilt.gd ;;
		# Loop MW-6: the egg cards and their triggers; KASETA's then cards and ghosts.
		eggs) check eggs '^check_eggs:' --script res://tools/check_eggs.gd ;;
		tape) check tape '^check_tape:' --script res://tools/check_tape.gd ;;
		# Loop MW-3: the night and the river's crowds, their rules on synthetic clocks, the crowd eggs.
		crowds) check crowds '^check_crowds:' --script res://tools/check_crowds.gd ;;
		# Loop MW-2: the storefronts and parodies (Frogs, venues, Leżaks, metro, stamps, eggs).
		parodies) check parodies '^check_parodies:' --script res://tools/check_parodies.gd ;;
		# Loop jobs-2: the courier race, the Leżak round-up, the payphone and E40.
		jobs2) check jobs2 '^check_side_jobs:' --script res://tools/check_side_jobs.gd ;;
		# DEMO 6.3: the second słoiki station (Dworzec Gdański) and the Łazienki peacock rescue.
		rescues) check rescues '^check_rescues:' --script res://tools/check_rescues.gd ;;
		# Loop couriers: the waiting couriers, the kerb riders, the dodge, the near miss's line.
		couriers) check couriers '^check_couriers:' --script res://tools/check_couriers.gd ;;
		# Beta values: the deliveries' route, the heat's words, NASTĘPNE.
		delivery) check delivery '^check_delivery:' --script res://tools/check_delivery.gd ;;
		# Loop MW-4: everyday life and trends: dogs, riders, runners, Kolka, the Wiralek cycle, the
		# "Na czasie" pay, the Zając, Fat Thursday, the life eggs (E16 E18-E20 E27-E30).
		life) check life '^check_city_life:' --script res://tools/check_city_life.gd ;;
		buses) check buses '^check_buses:' --script res://tools/check_buses.gd ;;
		# The crash scenes: the ambulance in the police family, the lines, the spots on the real
		# graph, the traffic going round a scene, the timer.
		# Zagłębie Kebabowe (docs/design/zaglebie-kebabowe.md): the five shops, their words, places on the
		# real lane graph, the pay twists and Szlak Szpili.
		zaglebie) check zaglebie '^check_zaglebie:' --script res://tools/check_zaglebie.gd ;;
		crashes) check crashes '^check_crash_scenes:' --script res://tools/check_crash_scenes.gd ;;
		# Sekretny rave: LEKTI's lines, the door's questions, the rigs and the club's room, the spots on the real graph.
		rave) check rave '^check_rave:' --script res://tools/check_rave.gd ;;
		# Nocny spot: the club's cars, lines, clock, pay, the drag's times, the meets and the strip on the real graph.
		meet) check meet '^check_street_meet:' --fixed-fps 60 --script res://tools/check_street_meet.gd ;;
		# Boat race: the course in open water, the boat, a whole race, the three-miss rule, the lines.
		boatrace) check boatrace '^check_boat_race:' --script res://tools/check_boat_race.gd ;;
		kinotour) check kinotour '^check_kino_tour:' --script res://tools/check_kino_tour.gd ;;
		# Dead electric cars: the TESŁO, the lines, the sling, the chargers on the real graph.
		evtow) check evtow '^check_ev_tow:' --script res://tools/check_ev_tow.gd ;;
		# City-life satire #1: the loud cars and the Browary meet.
		loud) check loud '^check_loud_cars:' --script res://tools/check_loud_cars.gd ;;
		# Crazy drivers: Szkoda taxis, Szprynter couriers, the Pasatini.
		crazy) check crazy '^check_crazy_drivers:' --script res://tools/check_crazy_drivers.gd ;;
		oldtram) check oldtram '^check_old_tram:' --script res://tools/check_old_tram.gd ;;
		# The tram fleet: the newest tram, the old pairs and today's, on the real tracks.
		tramfleet) check tramfleet '^check_tram_fleet:' --script res://tools/check_tram_fleet.gd ;;
		# The railway (docs/design/railway.md T1): the trains on the rail tracks.
		trains) check trains '^check_trains:' --script res://tools/check_trains.gd ;;
		# Packs: running clubs, cycling packs, coffee raves, the big guys with tiny dogs.
		packs) check packs '^check_packs:' --script res://tools/check_packs.gd ;;
		# Kibice: the friendly fans by Stadion Leguminy on match evenings.
		fans) check fans '^check_fans:' --script res://tools/check_fans.gd ;;
		# Kawowy rajd: Zuzia's coffee run on a ROWERILO bike (the data, the places, the bike).
		coffeerun) check coffeerun '^check_coffee_run:' --script res://tools/check_coffee_run.gd ;;
		# Wellness circles (docs/design/city-life-satire.md): sound healing, techno yoga, the 40+ club, park kung-fu.
		wellness) check wellness '^check_wellness:' --script res://tools/check_wellness.gd ;;
		garage) check garage '^check_garage:' --script res://tools/check_garage.gd ;;
		save) check save '^check_save:' --script res://tools/check_save.gd ;;
		districts) check districts '^check_districts:' --script res://tools/check_districts.gd ;;
		syrenki) check syrenki '^syrenki:' --script res://tools/check_syrenki.gd ;;
		cassettes) check cassettes '^cassettes:' --script res://tools/check_cassettes.gd ;;
		ladder) check ladder '^ladder:' --script res://tools/check_ladder.gd ;;
		racecuts) check racecuts '^race_cuts:' --script res://tools/check_race_cuts.gd ;;
		first10) check first10 '^first10:' --script res://tools/check_first10.gd ;;
		mainline) check mainline '^main_line:' --script res://tools/check_main_line.gd ;;
		chatter) check chatter '^check_chatter:' --script res://tools/check_chatter.gd ;;
		endcard) check endcard '^end_card:' --script res://tools/check_end_card.gd ;;
		opening) check opening '^opening:' --script res://tools/check_opening.gd ;;
		life-soak) life_soak ;;
		# Loop 2d-1: Podwózka's star and pay tables, the streak and the cancel rules, its lines.
		rides) check rides '^check_rides:' --script res://tools/check_rides.gd ;;
		cost) check cost '^check_cost_cuts:' --script res://tools/check_cost_cuts.gd ;;
		# The Old Town's dormers and chimneys (scripts/old_town_roofs.gd): on the slope, outward, small.
		oldtownroofs) check oldtownroofs '^check_old_town_roofs:' --script res://tools/check_old_town_roofs.gd ;;
		# The roofs lane (scripts/roof_dress.gd): parapets on outer edges only, tenement chimneys, the budget.
		roofdress) check roofdress '^check_roof_dress:' --script res://tools/check_roof_dress.gd ;;
		# Dobra and Tamka's tenement trim (scripts/tenement_trim.gd): cornice, string course, shop fronts, on the wall, within budget.
		tenementtrim) check tenementtrim '^check_tenement_trim:' --script res://tools/check_tenement_trim.gd ;;
		# RF4 (scripts/osm_roofs.gd): pitched roofs for small OSM-only houses: shapes, cover, what stays flat.
		osmroofs) check osmroofs '^check_osm_roofs:' --script res://tools/check_osm_roofs.gd ;;
		landmarks) check landmarks '^landmark check:' --script res://tools/check_landmarks.gd ;;
		# The museum and Plac loop: Muzeum Narodowe, Hotel Europejski and the Tomb from centrum.json
		# alone (found, what they replace, triangles, one material, cards; no terrain or sectors).
		sites) check sites '^check_sites:' --script res://tools/check_sites.gd ;;
		meshq) check meshq '^check_mesh_quality:' --script res://tools/check_mesh_quality.gd ;;
		sfx) check sfx '^sfx:' --script res://tools/check_sfx.gd ;;
		# v1.0 juice: crash sparks and dust (crash_fx.gd), the buzzes' floor and switch (haptics.gd).
		juice) check juice '^check_juice:' --script res://tools/check_juice.gd ;;
		# The gamepad loop: Xbox / PlayStation / MFi pads (gamepad.gd) on synthetic joypad events.
		gamepad) check gamepad '^check_gamepad:' --script res://tools/check_gamepad.gd ;;
		radio) check radio '^radio:' --script res://tools/check_radio.gd ;;
		sounds) check sounds '^city_sounds:' --script res://tools/check_city_sounds.gd ;;
		# Loop 10a: where a car can get into the water (whole map), and the game's tow decisions.
		water) check water '^check_water:' --script res://tools/check_water.gd ;;
		water-prebuilt) skip_prebuilt water-prebuilt || check water-prebuilt '^check_water:' --script res://tools/check_water.gd -- --prebuilt ;;
		# Loop 3c: the sectors are the whole city (meshes, pixels at 10 spots), streaming misses nothing.
		# The loading fix (2026-10-31): seven passes now, ~13 min: at least 25 min before it's stopped.
		streaming) STEP_LIMIT=$(( STEP_LIMIT > 1500 ? STEP_LIMIT : 1500 )) shown streaming '^check_streaming:' --script res://tools/check_streaming.gd -- --keep=$logs/streaming ;;
		# Loop 3g-1: the police's lines, flow and state machine (P11, P12), the runs P1-P7, the soak P13.
		police) check police '^check_police:' --script res://tools/check_police.gd ;;
		police-runs) police_runs ;;
		police-soak) police_soak ;;
		plain) game plain 600 "" ;;
		heli) game heli 6000 '^rescue (done|failed):' --mission=1 --heli --autopilot ;;
		race) game race 8000 '^race (won|lost):' --race=0 --autopilot ;;
		# Loop 3h slice 3: the final "Trzy mosty" from its last bridge (the whole race is ~14 min of play).
		# Kawowy rajd: the whole coffee run with the autopilot, ~60 s of play.
		coffee) game coffee 6000 '^trend job: coffee run done in' --trend-job=9 --autopilot ;;
		trzy-mosty) game trzy-mosty 9000 '^trzy mosty (won|lost):' --trzy-mosty=3 --autopilot ;;
		# Loop 3h slice 4: the first 10 minutes replayed (the director quits after the garage, ~575 s).
		first10-run) STEP_LIMIT=$(( STEP_LIMIT > 1500 ? STEP_LIMIT : 1500 )) game first10-run 48000 '^first10: OK' --first10 --autopilot ;;
		# Loop 3d-1: 15000 frames: on the demo map order 0 goes 1,023 m by road (Oboźna 1) and is
		# delivered at 219.8 s of play (9000 frames = 150 s ended it on the way). Content POIs
		# (2026-10-31): 11 places' addresses joined the address list, so the order's shuffle picks
		# Emiliana Konopczyńskiego 3, 1,266 m by road: 21000 frames (350 s of play).
		kebab) game kebab 21000 '^kebab delivered:' --kebab=0 --autopilot ;;
		# Loop 2d-1: a Podwózka ride by the app's route: a passenger 34 m off the pin, a GPS believer,
		# the river quirk (its waypoint on dry land, the `ride: quirk river` line says how far from
		# the water), the stars and the pay (`ride: pay`, the wallet before and after).
		# Loop 3d-1: 30000 frames: on the demo map (east edge 21.056) the river quirk's legs run
		# 1.7-1.8 km by road and the pay came after 20000 frames (333 s of play).
		ride) game ride 30000 '^ride: pay' --ride=8 --passenger=believer --ride-quirk=river --autopilot --parody-log ;;
		# Loop 2d-1 x 3g-1: a pull-over 25 s into that ride takes exactly one star (police.gd calls
		# rides.on_pulled_over() when the conversation ends), on the prebuilt city.
		ride-police) ride_police ;;
		# Loop 10a: into the river from the boulevard by Most Poniatowskiego with a delivery on:
		# the splash, then the tow onto a lane on dry land within 2 s, the job still running.
		splash) game splash 420 '^water: towed after [01][.][0-9]+ s .* m from a lane, dry; job on' \
			--drive-into-water=1015,-85 --kebab=0 ;;
		# The driving-feel loop: the car rams the back of a traffic car in the real city and must
		# get past it within 10 s (the hit, the shove and the time are in the line).
		ram) game ram 1000 '^ram test: past it' --ram-test --no-police ;;
		teleport) game teleport 3000 '^teleport test: OK' --teleport-test --no-police ;;
		# First scene items 6-7: at the start, after 15 s of play: walkers on Marszałkowska's busy
		# pavements, people at the start's furniture, a tram's bell as it passes, the square's bed.
		firstlife) game firstlife 1200 '^first life: OK' --first-life --at=-961.6,95 --heading=339.8 ;;
		rain) game rain-night 600 "" --weather=rain --time=night ;;
		prebuilt) skip_prebuilt "run: prebuilt-night" || game prebuilt-night 600 "" --prebuilt --time=night ;;
		classic) game classic 600 "" --controls=classic ;;
		ios) run_ios ;;
	esac
done

print -r -- ""
print -r -- "check                    result   time  detail"
print -r -l -- $rows
total=$(( passes + warns + fails ))
if (( fails > 0 )); then
	print -r -- "RESULT: FAIL ($fails failed, $warns warned, $passes passed of $total)"
else
	print -r -- "RESULT: PASS ($passes passed, $warns warned of $total)"
fi
missing="screenshots (tools/shots.sh, then look at them), the bench before/after"
(( ${want[(Ie)ios]} )) || missing+=", the iOS build (--ios)"
print -r -- "Not covered: $missing, the phone."
(( fails == 0 ))
