# Systems: who owns what

Every script in `game/scripts/` by system. The city's AI (traffic, police, people) has its own page,
[city-ai.md](city-ai.md); its scripts are listed there, not here. `tools/check_architecture.py`
fails if a script is in neither page, so add a row when you add a file.

"Owner" is the one script that makes a decision. Others call it; they don't copy it.

## 1. Composition and lifecycle

| Script | Owns |
| --- | --- |
| `main.gd` | The composition root. Parses flags, loads settings and save, shows the title, builds the city and every system (`_build_*`), runs the frame (`_process`), routes input, decides what may start (`_free_block`). |
| `release.gd` | Release builds read no command-line flags. |
| `error_trap.gd` | **The error trap**: a `Logger` that keeps the kinds of error with counts, places and what the game was doing, the last printed lines, and the session file whose end mark shows whether the last session closed by itself. `report()` is what Settings → RAPORT copies. The file, the button and the after-crash note are a debug build's (our own test runs); a release build has no trap at all (`ErrorTrap.make` gives none: testers' builds run none of it). `main.gd` starts it (`_trap_start`), marks it when the app goes to the background and refreshes its context once a second (`_trap_frame`). |
| `load_yield.gd` | `LoadYield.tick(step)`: lets one frame through during the long build so the loading bar moves. Every new `_build_*` step calls it. |
| `title.gd` | The title screen, language pick, loading bar. |
| `credits.gd` | Credits and licences screen. |
| `bench.gd` | Frame cost sampling for `--bench`, `--probe` and the phone's BENCH card. |
| `debug_roads.gd` | `--debug-roads` overlay (Debug Draw add-on). |

## 2. World: the map and what stands on it

| Script | Owns |
| --- | --- |
| `map_builder.gd` | The city from map data: terrain, roads, markings, rails, buildings, trees, colliders, the height, roof and picking grids. The global map index (heights, decks, tunnels, water test). |
| `sector_streamer.gd` | 512 m sectors streamed round the camera (prebuilt `.scn` or built at runtime). |
| `sector_proxies.gd` | One low-detail mesh per sector while it loads and in far views. |
| `city_maps.gd` | AO, lamp-light and surface maps per sector, fed to shaders. |
| `chunked_surface.gd` | SurfaceTool that files triangles into tiles so off-screen tiles are culled. |
| `index_pack.gd` | Packs the map index smaller in memory once the city is open. |
| `instance_buffers.gd` | Writes MultiMesh buffers the same on every renderer. |
| `lane_graph.gd` | The road network (lanes, junction curves, lights, distances). See city-ai.md. |
| `landmarks.gd` | Landmark buildings built in code from real footprints (the largest file, ~35k lines). |
| `models.gd` | Meshes of everything that moves (cars, buses, trams, people) and shared materials. |
| `props.gd`, `park_props_life.gd`, `park_props_play.gd`, `park_props_water.gd` | Box-built props in the actors' material, one surface. |
| `park_details.gd`, `street_details.gd`, `first_scene.gd`, `skwer_zlota.gd`, `plac_pieciu_rogow.gd`, `ratusz_hub.gd`, `tamka.gd`, `centralny_ramp.gd` | Hand-placed dressing for named places the map data lacks. |
| `storefronts.gd`, `neon_signs.gd`, `pixel_font.gd` | Shop fronts and parody signs, night neon, the 5x7 world font. |
| `roof_dress.gd`, `osm_roofs.gd`, `old_town_roofs.gd`, `tenement_trim.gd`, `powisle_houses.gd`, `small_buildings.gd` | Building detail on top of LoD2 and OSM shapes. |
| `monuments.gd` | Statues, plaques and benches from OSM. |
| `map_edge.gd`, `edge_roadworks.gd` | Land past the map edge, roadworks closing roads at the edge. |
| `rail_cut.gd`, `rail_yard.gd`, `station_lines.gd` | Railway cutting, platforms, platform centre lines. |
| `spire_motion.gd`, `tarasy_screen.gd`, `palace_lights.gd` | Animated landmark parts (Spire ticker and fountains, Złote Tarasy screen, Palace lighting by date). |
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
| `follow_camera.gd` | The follow camera's rules (shared with tests). |
| `camera_shots.gd` | Cinematic moments on Phantom Camera. |
| `tunnel_xray.gd` | The car seen through the ground in tunnels. |
| `skids.gd`, `crash_fx.gd`, `splash.gd`, `money_pop.gd`, `haptics.gd` | Juice: tyre marks, sparks, splash, "+54 zł", vibration (every buzz goes through `haptics.gd`). |

## 4. Activities: things the player does

Each runs on its own and answers `busy()`. `main.gd` `_free_block()` decides whether one may start
(tech-debt TD-1).

| Script | Owns |
| --- | --- |
| `missions.gd`, `beacon.gd`, `route_line.gd` | Rescue missions (call, pickup, hospital); the ground ring and light column marker; the road route as a polyline for the minimap. |
| `jobs.gd`, `zaglebie.gd` | Kebab and słoiki deliveries; the kebab cluster's data. |
| `rides.gd`, `ride_rules.gd`, `taxi_stories.gd` | Podwózka app-taxi job; its numbers; story passengers. |
| `courier_race.gd`, `roundup_job.gd` | Courier race challenge; the Leżak round-up. |
| `trend_job.gd` | "Na czasie" trend courier job (and calls for padel). |
| `ladder.gd`, `trzy_mosty.gd`, `race_cuts.gd` | The rival ladder order; the final race route; racers' shortcuts. (Races themselves: `rivals.gd`, city-ai.md.) |
| `boat_race.gd` | The Vistula boat race. |
| `street_meet.gd` | The night racing club (calls, meets, drag). |
| `dekalog_tour.gd`, `kino_tour.gd`, `coffee_run.gd`, `bar_crawl.gd`, `ev_tow.gd` | Story tours and call-in jobs. |
| `shisha.gd`, `lounge.gd`, `rave.gd`, `club.gd` | Hidden and night quests; cutaway interiors. |
| `padel_match.gd`, `padel_sim.gd` | Padel match view; its pure rules. |
| `event_day.gd` | 11 November day event. |
| `story_quests.gd` | The questline registry (`stories.add({...})`): start spots, hours, call, meet, busy, idle. The closest thing to an activity director today. |
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
