# Systems: who owns what

Every script in `game/scripts/` by system. The city's AI (traffic, police, people) has its own page,
[city-ai.md](city-ai.md); its scripts are listed there, not here. `tools/check_architecture.py`
fails if a script is in neither page, so add a row when you add a file.

"Owner" is the one script that makes a decision. Others call it; they don't copy it.

## 1. Composition and lifecycle

| Script | Owns |
| --- | --- |
| `main.gd` | The composition root. Parses flags, loads settings and save, shows the title, builds the city and every system (`_build_*`), runs the frame (`_process`), routes input, decides what may start (`_free_block`). |
| `boot.gd` | **The boot scene** (`boot.tscn`, the project's main scene; TD-15): the first thing the engine loads. It starts the error trap (a debug build's; a release build has none). In a player's launch (no flags: every release build) it puts the title up in the first frames and loads `main.tscn`, which pulls in every other script, on a thread behind it; with flags it loads the game's scene at once (`player_launch`; `--boot` asks for the player's way). The game's scene then takes its place, and `main.gd` takes over the title and the trap (`take_title`, `take_trap`). If the game's scene does not load, the title says so. Its preloads are a short fixed list (`check_boot`). `wait_frame` paces a frame spent waiting for a thread under the title when there is no display (its own wait and `main.gd`'s two), so a headless run counts those waits in frames as a screen does. |
| `release.gd` | Release builds read no command-line flags. |
| `error_trap.gd` | **The error trap**: a `Logger` that keeps the kinds of error with counts, places and what the game was doing, the last printed lines, and the session file whose end mark shows whether the last session closed by itself. `report()` is what Settings → RAPORT copies. The file, the button and the after-crash note are a debug build's (our own test runs); a release build has no trap at all (`ErrorTrap.make` gives none: testers' builds run none of it). `boot.gd` starts it and `main.gd` takes it over (`_trap_start`), marks it when the app goes to the background and refreshes its context once a second (`_trap_frame`). |
| `load_yield.gd` | `LoadYield.tick(step)`: lets one frame through during the long build so the loading bar moves. Every new `_build_*` step calls it. |
| `pause_reasons.gd` | **The game's pause** (TD-20): the reasons that hold the game paused (the loading bar, the settings card, the full map, the garage card). `hold(reason)`, `release(reason)`, `release_all()`; the tree is paused while any reason is held, so a card that closes does not start the game under one still up. `main.gd` owns the one instance (`_pause`); no other script writes the tree's pause (`check_pause`). |
| `title.gd` | The title screen, language pick, loading bar. The boot scene puts it up under the root and `main.gd` takes it over (a run with flags makes its own). It loads before the game does, so what it preloads is on `check_boot`'s list. |
| `credits.gd` | Credits and licences screen. |
| `bench.gd` | Frame cost sampling for `--bench`, `--probe` and the phone's BENCH card. |
| `debug_roads.gd` | `--debug-roads` overlay (Debug Draw add-on). |

## 2. World: the map and what stands on it

| Script | Owns |
| --- | --- |
| `map_builder.gd` | The city from map data: terrain, roads, markings, rails, buildings, trees, colliders, the height, roof and picking grids. The global map index (heights, decks, tunnels, water test). |
| `sector_streamer.gd` | 512 m sectors streamed round the camera (prebuilt `.scn` or built at runtime). |
| `solidity.gd` | **The solid classes** (the city objects plan, step 1): the class list every collider face is filed under (`building`, `lod2`, `fence`, `hedge`, `wall`, `pier`, `parked`, `landmark`, `edge`, ...) and the answer each gets (H, S, P, R, G; all H today), read once from `game/data/object_palette.json`, the one source. Pure and static. `map_builder.gd` `_solid(class, faces)` files the faces, one `Solid_<class>` body per class per sector with meta `solid`; the dressing scripts' bodies carry the same meta (`check_solids`). |
| `sector_proxies.gd` | One low-detail mesh per sector while it loads and in far views. |
| `city_maps.gd` | AO, lamp-light and surface maps per sector, fed to shaders. |
| `chunked_surface.gd` | SurfaceTool that files triangles into tiles so off-screen tiles are culled. |
| `index_pack.gd` | Packs the map index smaller in memory once the city is open. |
| `facade_kit.gd` | What every landmark is built from: the emitting core (material codes, triangle, wall, prism), the local frame, the shared facade parts (`kit_*`) and the palette (`PAL_*`). `landmarks.gd` extends it. docs/design/facade-kit.md. |
| `instance_buffers.gd` | Writes MultiMesh buffers the same on every renderer. |
| `lane_graph.gd` | The road network (lanes, junction curves, lights, distances). See city-ai.md. |
| `landmarks.gd` | Landmark buildings built in code from real footprints (the largest file, ~35k lines). |
| `models.gd` | Meshes of everything that moves (cars, buses, trams, people) and shared materials. |
| `props.gd`, `park_props_life.gd`, `park_props_play.gd`, `park_props_water.gd` | Box-built props in the actors' material, one surface. |
| `places.gd` | The owner of the place scripts (2026-11-13): `Places.TABLE` (one row per place: key, script, node, triangle budget, own draw items, optional `--solo` sites), built by main.gd's one `_build_places`, which merges every poured mesh into one MeshInstance3D per 512 m sector (`places_<cx>_<cz>`). No distance range (decisions.md). Checked by `check_place_scripts.gd`. |
| `place.gd` | The base of a place script: `map`, `ctx` (data, dialogue, clock, focus, vehicle, logs), `pour(mesh, shadows)` for static dressing in the actors' material, `part(node)` for anything else (own material, a mover, a StaticBody3D). |
| `park_details.gd`, `street_details.gd`, `first_scene.gd`, `skwer_zlota.gd`, `plac_pieciu_rogow.gd`, `ratusz_hub.gd`, `tamka.gd`, `centralny_ramp.gd`, `patelnia.gd` | Places (extend `place.gd`, a row in `Places.TABLE`): hand-placed dressing for named spots the map data lacks. |
| `storefronts.gd`, `neon_signs.gd`, `pixel_font.gd` | Shop fronts and parody signs, night neon, the 5x7 world font. |
| `roof_dress.gd`, `osm_roofs.gd`, `old_town_roofs.gd`, `tenement_trim.gd`, `powisle_houses.gd`, `small_buildings.gd` | Building detail on top of LoD2 and OSM shapes. |
| `monuments.gd` | Statues, plaques and benches from OSM. |
| `map_edge.gd`, `edge_roadworks.gd` | Land past the map edge, roadworks closing roads at the edge. |
| `rail_cut.gd`, `rail_yard.gd`, `station_lines.gd` | Railway cutting, platforms, platform centre lines. |
| `spire_motion.gd`, `tarasy_screen.gd`, `palace_lights.gd` | Animated landmark parts (Spire ticker and fountains, Złote Tarasy screen: both places with `part` meshes in their own material; Palace lighting by date). |
| `ped_zones.gd`, `scooter_zones.gd` | Pedestrian zones and e-scooter zones as point tests. |
| `districts.gd` | Which district a point is in; district discovery. |
| `map_art.gd`, `map_icons.gd` | The full map's own drawing and landmark icons. |

## 3. Player vehicles and camera

| Script | Owns |
| --- | --- |
| `car.gd` | The player's car physics, signals `bumped`, `impact`, `scraped`, `stuck`, `nitro_started`. |
| `drive_controls.gd` | Touch and key controls to throttle and steering (shared with `check_steering.gd`). |
| `lane_assist.gd`, `stop_assist.gd` | Lane assist; how forgiving every stop zone is. |
| `heli.gd` | The helicopter. |
| `boat.gd` | Boats for the boat race. |
| `gamepad.gd` | Controllers. |
| `follow_camera.gd` | The follow camera's rules (shared with tests), and the test-only free camera's flag text and view (`--cam=X,Y,Z`, main.gd `_update_free_camera`; check `check_free_cam`, verify step `freecam`). |
| `camera_shots.gd` | Cinematic moments on Phantom Camera. |
| `tunnel_xray.gd` | The car seen through the ground in tunnels. |
| `skids.gd`, `crash_fx.gd`, `splash.gd`, `money_pop.gd`, `haptics.gd` | Juice: tyre marks, sparks, splash, "+54 zł", vibration (every buzz goes through `haptics.gd`). |

## 4. Activities: things the player does

An activity of **the kit** extends `activity.gd` and joins the director, which knows which one is
on. Two have not moved yet (`rivals.gd` and `missions.gd`, one per PR, tech-debt TD-1): each runs on
its own and answers `busy()`, and `main.gd` `_free_block()` decides whether one may start.

| Script | Owns |
| --- | --- |
| `activity.gd` | **The activity kit's base class** (TD-1, with TD-2 and TD-16): the phases (idle, the phone rings, the offer, the run), the call's clock, the cards (a card it shows is its own; the press comes to it alone), the target (its beacon; the arrow, the metres, the minimap's dot and the stop assist read it through the director), the ✕, the autopilot's taps, the log, and one end that takes down everything it put up. A subclass gives the words and the play. |
| `activities.gd` | **The activity director**: an activity of the kit joins with `add`. `current()`, `busy()`, `busy_tag()`; `may_start(a)` (one of the kit at a time, and `world_free`, main.gd's test for everything not in the kit yet, or the activity's own test given as `add`'s second argument: the EV tow's, which may start from the air); `targeted()`; `grounded()` (why the helicopter is refused). Not built yet: who may interrupt whom, and the context for `messages.gd`. |
| `tour.gd` | A guided tour, the kit's first activity: a guest phones, the pickup, a list of stops with a card at each, one shot asked for on each leg, hits against the pay, a question at the end. The tours are data files: `game/data/kino_tour.json` ("Kino objazdowe") and `game/data/dekalog_tour.json` ("Dekalog na kółkach"). |
| `bar_crawl.gd` | The bar crawl ("Rajd po barach"), an activity of the kit: a night group phones, the pickup at a kerb, three bars against a clock with a stay at the first two, the group's mood (knocks and hard stops), pay by bars, mood and time. The kit holds its call, cards, target and end; the script keeps the groups, the routes, the clock and the mood. Groups' lines: `game/data/bar_crawl.json`. |
| `missions.gd`, `beacon.gd`, `route_line.gd` | Rescue missions (call, pickup, hospital); the ground ring and light column marker; the road route as a polyline for the minimap. |
| `jobs.gd`, `zaglebie.gd` | Kebab and słoiki deliveries, an activity of the kit and its fourth side job (`is_job`); the kebab cluster's data. No call: a pull-in at a kebab stand or a station starts it; the order card (it goes by itself when the car drives off, or when its count-down ends), the drive to the door with the heat or the jars, and the result card are the stages of the kit's run (`stage`). Its cards sit at the bottom of the screen with the drive going on under them (`cards_low`, `cards_hold` off). The door is the kit's target only while delivering (`has_target`); the pointer to the next stand after a result card's NASTĘPNE (`pointing`) is no run, and main.gd shows it apart, after every activity's target. The kit holds the cards, the status line (with the heat's or the jars' small pictures: `status`'s `icons`), the ✕, the door's ring and the end; the script keeps the stands, the stations and the address book (the other jobs ask it for a kerb and a door: `_kerb`, `_pick_address`), the heat and the jars, the pay, the minimap's squares and the route, the guided first order, the test flags and the autopilot's ghost car (`drive_player`). "Is a side job on?" is the director's answer now (`activities.job_on()`), and the M and K keys go to the cards through the director (`primary`, `secondary`); `own_busy`, `side_busy`, `round_busy` and `ride_offered` stay here for the other three jobs and the first minutes' guide, and the police ask it by name (the kebab on board, the heat frozen at a pull-over). Checks: `check_job_play` (the play, verify step `jobplay`), `check_delivery` (the route, the heat's words, NASTĘPNE), `check_side_jobs` (verify step `jobs2`) and `check_zaglebie`. |
| `rides.gd`, `ride_rules.gd`, `taxi_stories.gd` | Podwózka, the app-taxi job, an activity of the kit and its third side job (`is_job`); its numbers; the story passengers. A request card beside the road every 75-120 s of free driving (or the PODWÓZKA button) leaves the player free until it is taken (`offer_busy` off); the way to the passenger, the ride and the result are the stages of the kit's run. It is the first whose cards of the run sit beside the road with the drive going on under them (`cards_hold` off: a story passenger's question, the result card that goes by itself), the first that takes a card down by itself (`close_card`), and the first that drives the autopilot's car itself on a test run (`drive_player`: the app's dotted line, a ghost car ahead, the squeeze out of a jam). The kit holds the request, the cards, the status line, the ring, the ✕ and the end; the script keeps the rides (the pin that is a bit off, the passenger types, the quirks and their plans, the Frogs stop, the stories), the stars and the pay, the river spots and the GPS moments (`gps_moments.gd`). `jobs.gd` (for `side_busy` and `ride_offered`), the police and the first minutes' guide still ask it by name. Checks: `check_rides` (the rules' tables, verify step `rides`) and `check_ride_play` (the play, verify step `rideplay`). |
| `courier_race.gd` | The courier who races a kebab order (by night, one order in four when a courier waits by the stand): the challenge, the rider on the footways, who is first at the door, the extra pay. No activity of its own: it has no call, offer or result card, it is the deliveries' child and a part of their run (`jobs.gd` steps it in `_tick`, starts the drive when the challenge is taken and adds its line to the result card); its `State` is the rider's. Its route comes from a worker thread. Checks: `check_couriers`, `check_side_jobs`, and where the two scripts meet `check_job_play`. |
| `roundup_job.gd` | The Leżak round-up, an activity of the kit and its first side job (`is_job`): no call, a pull-in at a depot by night starts it; the offer at the depot (it goes when the car drives off), ten Leżaks into a boot of five, the unloads at the depot, the pay and the bonus for all within six minutes, the ✕ that pays what was unloaded; the Leżaks lie about again by the morning. The kit holds its cards (at the bottom of the screen: `cards_low`), the ✕, the depot's ring and the end; the script keeps the depots and their rings by night, the pick-up rules, the pins and the pay. Its target is the nearest Leżak, not the ring. The director answers for it now (`job_on`, the target, the card keys); `jobs.gd` keeps `round_busy()` for its own minimap squares and its pointer, and main.gd asks that for the round-up's row in the map's list of what is under way. |
| `trend_job.gd` | The trend courier's job, an activity of the kit, its second side job (`is_job`) and the first with several kinds of order in one script: "Na czasie" (a request by a place in fashion, the queue, an office door by Rondo Daszyńskiego), "Limitka" (Friday's drop at PISTACJA), "Czwarty" (PADELNIA's fourth player), the DESKA call (a friend phones; by car or by air to the club, then the match on cards or on the court: `padel_match.gd`), "Mlask" (Mrożulo's van, the review, the sticker), "Dżemini" (Mrożulo's call, once per save, the TYGRAM message) and Zuzia's coffee run (`coffee_run.gd` holds its numbers). The look twice a second of play asks which is due; a request beside the road leaves the player free until it is taken (`offer_busy` off). The kit holds the call, the request, the cards, the status line, the ring, the ✕ and the end; the script keeps the orders, their clocks and cool-downs, the pay, the van and its fans, the sticker and the café's glow. Check: `check_trend_job` (verify step `trendjob`). |
| `ladder.gd`, `trzy_mosty.gd`, `race_cuts.gd` | The rival ladder order; the final race route; racers' shortcuts. (Races themselves: `rivals.gd`, city-ai.md.) |
| `boat_race.gd` | The Vistula boat race ("Wiślana Szprotka"), an activity of the kit and its first the player leaves the car for: Szymek's call (or Szymek met at the pontoon), the pontoon's ring, the grid and its 3-2-1, the race down the river through the rings against three rivals (three misses and out), the result card with REWANŻ; and the marina's card with the free ride in one of three boats, which are stages of a run that leave Szymek's next call where it was. The kit holds its call, cards, the pontoon's ring, ✕ and end; the script keeps the boats, the course, the rules, the rivals, the water, the wakes and the PRZYSTAŃ pill. On the water it sets `flown` and takes the arrow down (`target_arrow`): the rings lead. |
| `street_meet.gd` | The night racing club, an activity of the kit: Darek's call at night, the meet on Plac Defilad (the ring of parked cars, Lena's donuts, the crowd), the raid and its cordon, the race to the second meet (the place is the status line's badge), the second raid, and the drag on Aleja Zieleniecka (two exhibition pairs, the tree of lights, the launch by the revs, the shifts, Tadek, the result card with REWANŻ). The kit holds its call, cards, status line, target, ✕ and end; the script keeps Darek's own clock (it counts only at night and stands while something else is on), the stages, the scene, the racers it hands to the traffic (the club's eight profiles, `ladder.gd` `CLUB`, on one race session, `race_session.gd`), the cordon, and the drag's tree, tacho and context button. |
| `coffee_run.gd` | The coffee run. |
| `ev_tow.gd` | The EV tow ("Stanęło TESŁO"), an activity of the kit and its first that is flown (`flown`): Bartek phones, the helicopter goes to his dead car (the dashed ring), the sling hooks on, the car is carried on its rope to a charger's bay, the pay. A stranded stranger's car hooks on with no call (`start`). The kit holds its call, cards, target and end; the script keeps Bartek's call clock (it stands while something else is on), the stranded cars, the sling's pendulum, the chargers and the pay. |
| `shisha.gd` | The shisha night ("Dym u Senatorka"), an activity of the kit: Ivan phones ("+" held), the two pickups at a kerb, the lounge's entrance (the kerb's ring and the door's gold one), the evening inside (`lounge.gd`), the two drop-offs, the pay. The kit holds its call, cards, target and end; the script keeps the places, the lines over the car, the votes and the pay. Lines: `game/data/shisha.json`. |
| `rave.gd` | Mati's nights (the secret rave and Smoła), an activity of the kit: LEKTI's invite on MORDOR FM, Mati's call, the pickup at his block, the meeting point (the arrow says "???", the hooded man gives the place), the door's three questions, the pay and the way into the club (`club.gd`). The kit holds its call, cards, target, ✕ and end; the script keeps LEKTI's and Mati's clocks (they stand while something else is on), the two kinds of night, the door's quiz and the rave's rig of lights and dancers, which runs whether a night is on or not. |
| `lounge.gd`, `club.gd` | The cutaway interiors of the shisha lounge and the club. |
| `padel_match.gd`, `padel_sim.gd` | Padel match view; its pure rules. |
| `event_day.gd` | 11 November day event. |
| `story_quests.gd` | The questline registry (`stories.add({...})`): start spots, hours, call, meet, busy, idle. It lists the questlines; which activity is on is the director's (`activities.gd`). |
| `quest_lines.gd` | Car and helicopter quest lines, marker colours. |
| `main_line.gd`, `main_nudge.gd` | The main story thread and its on-screen nudge. |
| `first10.gd` | The fresh-save guide and the end card. |
| `spacer.gd`, `fotka.gd` | Wander mode (nothing comes by itself); photo mode. |

## 5. Feedback: HUD, words and sound

| Script | Owns |
| --- | --- |
| `hud.gd` | Every on-screen control and panel, sized in points. Cards, toasts, notes, status, minimap, banners. |
| `messages.gd` (PR #652) | **The one decision for HUD text**: SHOW, DEFER or DROP by context (FREE, QUEST, CHASE, FOCUS) and priority (AMBIENT to ALERT); call spacing (`call_ok`). |
| `bubbles.gd`, `chatter.gd` | Speech bubbles over the world; the chatter budget (QUEST, POLICE, REACTION, AMBIENT classes). |
| `dialogue.gd` | Lines from `data/dialogue.json` by group, without repeats. |
| `lang.gd` | One language on screen (Polish or English). |
| `portraits.gd` | The speakers' faces (`art/portraits/<name>.png`) for the phone call view (`hud.show_call`), quest cards, quest and police bubbles (`bubbles.gd`) and the lounge and club talk panels (`badge`); the initial on a disc when there is no art, none for non-people (`NO_FACE`). |
| `screen_points.gd`, `access.gd` | Points, safe area, tap sizes; accessibility options. |
| `settings.gd`, `settings_panel.gd` | Settings in `user://settings.cfg`; the panel. |
| `full_map.gd` | Full-screen map. |
| `notebook_page.gd`, `garage_card.gd` | Notebook tab; garage card. |
| `radio.gd`, `greeting_clips.gd`, `opening_audio.gd` | The radio stations and host; launch greeting; opening line. |
| `sfx.gd` | Audio buses and every effect (engine, tyres, crashes); the mixer: who turns whom down (`DUCKS`, `Sfx.duck` / `Sfx.release`). |
| `city_sounds.gd` | Positional sounds at places (club bass, bells). |
| `gps_moments.gd` | App-taxi GPS jokes in traffic. |

## 6. Progress and the save

| Script | Owns |
| --- | --- |
| `wallet.gd` | **The save** (`user://save.cfg`, versioned with `migrate`): złoty, respect, jobs, records, eggs, notes, session spot. Signal `changed(zl, respect, gained)`. A damaged file is moved aside and the last launch's copy loaded (`load_note`, `damage`, `keep_copy`). |
| `safe_file.gd` | The one way a kept file reaches the disk: a temp file, read back, then one rename (`write`, `copy`). Only `wallet.gd` and `settings.gd` call it. |
| `upgrades.gd`, `garage.gd` | Parts and cars rules; the workshop. |
| `notebook.gd` | MOJA WARSZAWA, 72 places found. |
| `eggs.gd`, `egg_book.gd` | Easter eggs; their cards. |
| `syrenki.gd`, `cassettes.gd`, `tape.gd` | Collectibles: mermaids, mixtapes, then-cards. |

## 7. Look: light, weather and quality

See [graphics.md](graphics.md).

| Script | Owns |
| --- | --- |
| `time_of_day.gd` | Dawn, day, dusk, night; sun, sky, grade, city lights; global shader uniforms. |
| `weather.gd` | Rain and wetness. |
| `tiers.gd` | Quality levels and what Auto picks per device. |
| `governor.gd` | Steps extras down when frames run late, back up when calm. |
| `gpu_quirks.gd` | Per-GPU workarounds (Adreno 6xx lite building shader). |
