## The command-line flags of a debug run (TD-4 a): `parse()` reads `Release.game_args()` once,
## at the start of main.gd's `_ready`, and `parse_stream()` the streaming ones after it. main.gd
## reads each value as `flags.NAME`. A value the game also changes later stays main's own and is
## written here as `m.NAME` (its doc comment in main.gd says so). In a release build
## `Release.game_args()` is empty, so every value keeps its default.
## Made by td4a-codemod 3 from main.gd; `check_dev_flags.gd` (verify step `devflags`) holds the rules.
extends RefCounted

const Main := preload("res://scripts/main.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const Car := preload("res://scripts/car.gd")
const Heli := preload("res://scripts/heli.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const Notebook := preload("res://scripts/notebook.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Tape := preload("res://scripts/tape.gd")
const Fotka := preload("res://scripts/fotka.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Weather := preload("res://scripts/weather.gd")
const Controls := preload("res://scripts/drive_controls.gd")
const FollowCamera := preload("res://scripts/follow_camera.gd")
const Settings := preload("res://scripts/settings.gd")
const Tiers := preload("res://scripts/tiers.gd")
const MacMode := preload("res://scripts/mac_mode.gd")
const Police := preload("res://scripts/police.gd")
const CityBarriers := preload("res://scripts/city_barriers.gd")
const Solidity := preload("res://scripts/solidity.gd")

## The game (main.gd), for the values and functions that stay its own.
var m: Main

## The follow-camera loop: --size= was given (the saved zoom doesn't apply), and the pinch's span
## ratio since its last zoom step.
var _flag_size := false
## --grade=NAME: a colour look (grades.gd NAMES) for this run, over the saved setting ("": the
## setting's); --grade-sweep=TIME,TIME[:LOOK,LOOK]: the harness shoots every --spots spot at each
## time in each look (comparison sheets).
var grade := ""
var grade_sweep: Array = []
## --pitch= was given: the saved camera angle (Settings → Obraz) doesn't override it.
var _flag_pitch := false
var zone_cap_flag := -1
## --train=X,Z: a train put on the track nearest that point at the start (shots).
var train_at := Vector2.INF
## --promo-at=X,Z[,T] (videos, F 2026-11-19 "run the tram and the bus on one video"): two trams
## (one up Marszałkowska, one along the Aleje) and a bus put so they reach that point T s (default 6)
## after the start, rolling.
var promo_at := Vector2.INF
## --promo-parts=LIST (F 2026-11-21, the palm teaser): which of --promo-at's actors come: tram-up,
## tram-east, bus, police (default all; "police" alone leaves the trams and buses to the traffic).
var promo_parts := PackedStringArray(["tram-up", "tram-east", "bus", "police"])
var promo_t := 6.0
## --promo-delay=S (F 2026-11-21, the palm reel): place --promo-at's actors S s after the start
## instead of at load, so they still cross a clip whose head (--skip) is long.
var promo_delay := 0.0
## --pigeons-at=T (videos, F 2026-11-19 "the pigeons fly up during the video"): Plac Zamkowy's
## square stays awake wherever the player is, and its flock bursts up T s after the start.
var pigeons_at := -1.0
## --scoot-gang=X,Z[,T[,DIR]] (videos, F 2026-11-21): a Kukuryźnik pack on the footway nearest
## (X, Z), T s after the start (default 3), riding the path's way or against it (DIR -1).
var scoot_gang := Vector3(0.0, 0.0, -1.0)
var scoot_gang_dir := 1.0
## --people=N (videos, F 2026-11-21: "more pedestrians"): the walkers' target, whatever the
## quality and traffic level say (never above pedestrians.gd MAX); -1: the settings decide.
var people := -1
## --season=summer|autumn (videos, F 2026-11-20 "trees can be green like summer not yellow"): the
## trees' shader global `tree_season` until the season module (trees plan S1) sets it from the date.
var season := ""
## --train=X,Z,K: that train of kind K (trains.gd KINDS: 0 Koleje Mazowe, 1 SKiM, 2 the
## long-distance one).
var train_kind := -1
var no_traffic := false
var start_race := 0
var start_rival := 0
## --bench: drive a ghost route through the traffic, then print frame times.
var bench := false
var _bench_frames := 600
var probe := false
var _exp: PackedStringArray = []
## Loop 2b: the measured part of a bench or probe ends after this many seconds even if the
## frames aren't done (a slow phone), and settling after SETTLE_SECONDS; --fps=N caps the frame
## rate for this run (0: uncapped; else the setting's 60 or 30).
var _bench_seconds := 30.0
var _flag_fps := -1
var _phone_seconds := Main.PHONE_SECONDS
## --bench-button: press BENCH at frame 60 (testing aid; the same run as the button's).
var bench_button := false
var start_flying := false
## Loop 3d-2b, --heli-alt=M: the height over the ground the helicopter starts at (0: the usual take-off).
var _start_alt := 0.0
var start_mission := 0
var autopilot := false
## Street races (2026-11-04): --ghost-pace=X, the autopilot's speed factor in a race (rivals.gd
## `ghost_pace`, default 1.8: an average player; 2.4 a quick one; "racer" (99): a skilled player who
## uses the whole car on the roads, traffic.gd's racer mode at the car's top), for the race-AI runs.
var ghost_pace := 0.0
## --race-debug: traffic.gd prints what holds a racer that stands still (once a second), and
## rivals.gd a `race trace:` line a second of a race (the rival's speed, the band, both gaps).
var race_debug := false
## --no-ghost (2026-10-31, the landing's screenshots): no occlusion ghost and no see-through hole
## round the car, so a
## wide framed shot centred on a spot behind a building keeps that building whole.
var no_ghost := false
## --yaw= was given (the follow camera then doesn't start behind the vehicle).
var _flag_yaw := false
var cinematic_flyin := false
var cinematic_look := false
var _flag_cinematic := ""
var demo := false
## The L-shaped map loop (2026-10-31), --heli-stick=X,Z: the helicopter's stick held towards that
## world direction (x east, z south) the whole run, for screenshots of the clamp along the map's
## outline (ZERO: off).
var heli_stick := Vector2.ZERO
## Teaser 5 (F, 2026-11-21), --promo-heli=X,Z,TX,TZ,ALT[,SHARE[,SCALE]]: a second helicopter for a
## promo shot, starting ALT m over (X, Z) and flying itself towards (TX, TZ) at SHARE of top speed
## (0.6), drawn SCALE times its size (1), its beacon, strobe and searchlight on at night. Empty: none.
var promo_heli := PackedFloat32Array()
var out_dir := "user://"
## --spots: [name, Vector2 x/z, heading or INF] per camera; one run shoots them all, the city
## built once (a street pass needs 6-10 cameras; a launch per camera cost ~70 s each).
var shot_spots: Array = []
var lines_override := 0
var hide_hud := false
## Desktop: --no-touch (trailer loop, 2026-10-29): the HUD without its touch-only controls (the
## pedals, the stick, the helicopter's pads) and the title without its "tap to drive" prompt,
## for recording on the computer (hud.gd `set_touch_off`, title.gd `touch_off`).
var no_touch := false
var sun_pitch := -50.0
var debug_ao := false
## Landmarks 0.3 (2026-10-31): `--solo=KEY` builds that landmark site alone (map_builder.solo_site),
## `--solo-look=lit|flat|sil` draws it lit, unlit in its own colours, or as a dark silhouette on a
## plain background (shaders/solo.gdshader).
var solo_site := ""
var solo_look := "flat"
## Loop 3a: --debug-roads draws the decks, approaches, tunnels, lane heights and piers round
## the car (debug_roads.gd, with the Debug Draw add-on).
var debug_roads := false
var collider_view := false
## GAMEPLAY_PLAN 0.3: --under starts the car (with --at) on the road under a bridge or viaduct deck
## there, not on top of it (the deck x-ray's shots).
var start_under := false
## Loop 1: --ghost-debug=N paints the occlusion ghost for measuring (1: the ghosted
## fragments magenta and every other building green; 2: the ghost cut fully, no dither)
## and prints the ghost's ellipse in screen pixels with every screenshot.
var ghost_debug := 0
## --left-handed: the left-handed layout for this run (Settings → DOSTĘP keeps it otherwise).
var _flag_left_handed := false
## --color-safe: colour-safe markers for this run (Settings → DOSTĘP keeps it otherwise): the HUD's
## tint and the race and rescue rings' shapes (beacon.gd), for shots.
var _flag_color_safe := false
## --lang=pl|en: the language for this run (not saved), over the saved choice and the phone's.
var _flag_lang := ""
## --lift=M: aim the camera M metres above the vehicle (close-ups of tall landmarks).
var cam_lift := 0.0
## --cam=X,Z or X,Y,Z (tests and screenshots, not for players): the free camera. It looks at that
## world point (Y left out: the ground there), turned by --yaw= and --pitch=, --size= tall, and
## stays there whatever the car does: no follow, no lead, no zoom. The car stands where --at puts
## it (default: under the camera, so the city streams in around the view) and is hidden unless
## --cam-car; no occlusion ghost. follow_camera.gd parse_free / free_view.
var free_cam := false
var _free_cam_car := false
## --cams=NAME:X,Y,Z,YAW,PITCH,SIZE+NAME2:...: one run, several free cameras, one shot each
## (files NAME_FFFF.png; the --spots machinery moves the car under each). follow_camera.gd parse_cams.
var _cams: Array = []
var no_ao := false
## Load the prebuilt sectors like the exported game does (loop 3c: map/sectors/*.scn, index.res,
## proxies.scn; only rebuilt by tools/bake_city.gd), not build them from their files.
var prebuilt := false
## --no-map-edge: without the land past the map's edge (map_edge.gd), for a before/after probe.
var _flag_no_map_edge := false
## --no-edge-roadworks: without the roadworks closing the roads at the map's edge (edge_roadworks.gd;
## their colliders go too, the edge wall stays), for a before/after probe.
var _flag_no_edge_roadworks := false
var start_time := 0
var start_station := 0
var show_title := true
var force_title := false
var notebook_open := ""
var found_spec := ""
var place_flag := ""
var notes_log := false
var district_card := ""
## --pop=<zl>: pays that much two seconds into the run, to see the money pop (money_pop.gd).
var pop_flag := 0
var districts_spec := ""
var districts_log := false
var syrenki_log := false
var syrenki_spec := ""
var syrenka_flag := ""
## Loop 3h slice 3: the rival ladder and the final "Trzy mosty" (rivals.gd, ladder.gd,
## trzy_mosty.gd): --ladder=N (the first N rungs beaten for this run, respect raised to fit; -1: the
## save's) and --trzy-mosty (the car at Rondo Daszyńskiego at night, the final at once).
var ladder_flag := -1
var trzy_mosty_flag := false
var trzy_mosty_bridge := 0
var first10_flag := false
var end_card_flag := false
var first_race_flag := false
## First hour step 6: --hint=ID puts that hint up at once (hints.gd IDS: a shot of the spotlight),
## --no-hints keeps every hint down.
var hint_flag := ""
var no_hints := false
## 2026-11-16 (--map-coach): the full map's coach marks show as if never seen (hints.gd `use_flags`).
var map_coach := false
var egg_flag := ""
var egg_log := false
var found_eggs := ""
var tape_flag := ""
var tape_log := false
var fotka_flag := false
## --promo[=free,grid,ghost,nohud,clean,panel,9:16,4:5,1:1,16:9]: Promo Mode on for the run
## (promo_mode.gd `use_flag`; the DEV setting's "promo"), with those of its switches set.
var promo_flag := ""
var kadr_flag := ""
var photo_log := false
## --egg=e37: the street today's roadworks must be on (eggs.gd `force_street`).
var barrier_force := ""
## Loop MW-5: PÓŁNOC FM's flags: --station=<id|name|N> (a station by id, short id or name),
## --radio-log (the radio's and the city sounds' log), --unlock=all|N[,N] (all tracks for this
## run, or open track N as an egg would); `radio_picked`: --radio= or --station= was given (the
## radio then doesn't follow the clock).
var station_flag := ""
var radio_log := false
var unlock_flag := ""
var radio_picked := false
var crowd_flag := 1
var night_log := false
var night_hub_flag := false
var bus_log := false
var honk_frames: Array[int] = []
var crash_flag := ""
var crash_log := false
## Road life (road_life.gd): --ambulance=now (one comes up behind in 2 s, 40-60 m back), =0 (none;
## the honk at a green stays), =on (on in a test run too); --road-log prints its log.
var ambulance_flag := ""
## Road life (2026-11-26): --wedding=now (a wedding convoy just ahead in 2 s), =0 (none), =on (on in
## a test run too); --elka=X (that share of the band's cars are an Elka, 0..1; default ELKA_CHANCE
## in a normal launch, none in a test run).
var wedding_flag := ""
var elka_flag := -1.0
var road_log := false
var crawl_flag := ""
var crawl_route := ""
var crawl_group := ""
var crawl_log := false
## THE TAPCZAN (tapczan.gd): --tapczan=0|in|taps|pong|drunk, --tapczan-log.
var tapczan_flag := ""
var tapczan_log := false
var _crawl_auto := false
var ev_flag := ""
var ev_log := false
var _ev_auto := false
var _crash_auto := false
var meet_flag := ""
var meet_at := ""
var meet_log := false
var _meet_auto := false
var rave_flag := ""
var rave_spot := ""
var rave_log := false
var _rave_auto := false
## Za deckami (smola-decks loop, stage B; club.gd `wire`): --decks goes straight into a set in Smoła's
## room (it sets --rave-club too, so the room's own test start takes the run in); --decks-bot=perfect|
## mid|poor|none lets a bot play it (decks_sim.gd's bots); --decks-log prints the set's lines (the
## `decks: over:` line, a frame note 3 s in).
var decks_flag := ""
var decks_bot := ""
var decks_log := false
var dekalog_flag := ""
var dekalog_log := false
var stories_log := false
## --story=ID: that questline starts from the beta list 1.5 s into the drive (its friend phones).
var story_flag := ""
## --story-meet: the friend's WCHODZĘ pressed by itself a second after they walk up.
var story_meet_flag := false
var boat_flag := ""
var boat_log := false
var kino_flag := ""
var kino_log := false
var shisha_flag := ""
var padel_flag := -1.0
var padel_log := false
var shisha_log := false
var _shisha_auto := false
var old_tram_flag := ""
var tram_log := false
var loud_flag := 3
var loud_log := false
var crazy_flag := 3
var crazy_log := false
var packs_flag := 1
var packs_now := false
var packs_log := false
var event_flag := -1
var event_smoke := 1
## --event-t=SEC: with --cinematic=event, freeze the take at that second (stills for the path check).
var event_t := -1.0
var event_log := false
## --stats=log|send|off: the play stats (play_stats.gd) for this run: log prints every event and
## sends none (the check), send sends from a debug build (a test against the PostHog project), off
## none. Without it a debug build sends nothing and a release build follows the setting.
var stats_flag := ""
var fans_flag := 1
var fans_now := false
var fans_log := false
## --fans-phase=arrive|match|leave and --fans-result=win|draw: the match day's walkers for shots.
var fans_phase := ""
var fans_result := ""
var wellness_flag := 1
var wellness_now := false
var wellness_log := false
var tamka_log := false
var paint_flag := ""
var garage_flag := false
## --garage=ring: the car 16 m short of the ring (the ring in view, no card).
var garage_ring_only := false
## G13: --garage=parts opens the card on the parts tab; --upgrades=all|tt|nitro starts with them.
var garage_parts := false
var upgrades_flag := ""
var garage_log := false
var life_flag := 1
var dogs_log := false
var trend_log := false
var life_log := false
var life_soak := false
## --blvd-t=S: the Vistula steps' life (boulevard_life.gd) starts S s into its loops.
var blvd_t0 := 0.0
var zajac_flag := false
var trend_day_flag := -1
var trend_job_flag := 0
## --dzemini: Mrożulo's MLASK already on DŻEMINI KEBAB (the queue for good, the sticker), the car by
## the shop (trend_job.gd "Dżemini"; shots without driving the job).
var dzemini_flag := false
## --tajny[=palm|race|0]: the Tajny klient opening (tajny_klient.gd) on, whatever the DEV setting:
## Kebabulo's call 2 s in; =palm: the order made, the car at the Palm's kerb; =race: the tasting done,
## the race back to Kemal's on; =0: off, even with the setting on.
var tajny_flag := ""
var start_kebab := -1
## Loop jobs-2: --courier-race[=N] (kebab order N, default 0, with the courier's challenge forced).
var courier_race := false
## Loop jobs-2: --roundup (the car at the nearest Leżak depot, the round-up's card up, day or night).
var roundup_flag := false
## Loop jobs-2: --courier-v=M (the courier's speed in m/s, for a test run; 6.5 by default).
var courier_v := -1.0
## Loop couriers: --pedzik-log (city life's `pedzik:` lines: the minute's riders on the paths and the
## kerb, the couriers waiting, each swerve, hop and near miss, a courier taken by the race).
var pedzik_log := false
## Loop couriers: --pedzik-kerb (a testing aid for shots: the kerb riders start 8-35 m from the view).
var pedzik_kerb := false
## Loop jobs-2: --armchair (the armchair man out today at any hour, the car on the lane by him).
var armchair_flag := false
var start_sloik := -1
## --sloik-station=N: the station of --sloik (0 Dworzec Centralny, 1 Dworzec Gdański).
var start_sloik_station := 0
var start_heat := -1.0
## Testing (loop Zagłębie): --craft=plain, the autopilot takes the plain kebab at the craft shop.
var craft_plain := false
## --ride=N: ride N's request, the car by its passenger; --ride-quirk=, --passenger=, --stars=X
## (the live rating's start), --ignore-app (the autopilot drives the shortest road, not the
## app's), --parody-log (`ride:` and `gps:` lines). Story rides (taxi_stories.json): --ride-story=ID
## (that passenger, "none" for no story), --ride-answer=0|1 (the autopilot's answer to the question).
var start_ride := -1
var ride_quirk := ""
var ride_passenger := ""
var ride_story := ""
var ride_answer := -1
var ride_stars := -1.0
var ignore_app := false
var parody_log := false
## --gps-in=S: the first GPS moment of the app-taxis in traffic from S seconds in (screenshots).
var gps_in := -1.0
var no_parodies := false
var rechotka_flag := false
var stamps_flag := -1
var host_in := -1.0
var barrier_day := 0
var reset_save := false
var no_save := false
## Safer saves (TD-8): `--save-note=restored|lost|blocked` shows the damaged-save note without a
## damaged file (the shots and a headless run of the note's path; with the title forced on).
var save_note_flag := ""
var report_flag := false
var crash_note_flag := false
## --free: free roam (loop 2e: no call card at the start anyway; the first call then comes in
## 90 s into play instead of 60).
var free_roam := false
## Loop 2e: the first rescue call comes in after this many seconds of play (--call-in=S;
## missions.gd FIRST_CALL by default); --style= wins over the saved settings.
var call_in := -1.0
## Loop 2e: --settings-tab=NAME opens the settings panel at that page for screenshots: a name of
## settings_panel.gd PAGES (driving, world, picture, sound, notebook, access, credits, tips, dev) or,
## as before, its number.
var settings_tab := "game"
var _flag_style := -1
## --tap=X,Y: tap that screen pixel at frame 60, as if a finger did (landmark cards).
var tap_at := Vector2.INF
var start_weather := 0
var live_clock := ""
var live_date := 0
## F 2026-11-19: the game clock (time_of_day.gd `start_clock`, 30x, the sun by the date): on in a
## normal launch, or with --game-clock in a test run (--time=, --clock=, --date= then set its start).
var game_clock := false
## --palace-lights=ID: the Palace's event lighting forced to one row of data/palace_lights.json
## ("gold" for the nightly gold), whatever the date (shots).
var palace_lights_id := ""
var _flag_model := ""
var _image_write := true
var _flag_last_session := ""
var _flag_governor := -1
var _governor_on := true
var _governor_log := false
## Loop G1 testing aid (--stress=cpu:N|wait:N, --stress-from=S, --stress-to=S): N × 0.5 ms of busy
## work a frame from S to S2 seconds after the city is up: in _process (`cpu`: the CPU's extras go
## first) or in the draw phase (`wait`: what waiting for the GPU looks like to the main thread,
## so the GPU's extras go first).
var _stress_kind := ""
var _stress_n := 0
var _stress_from := 0.0
var _stress_to := INF
## -2: no --quality= (Tiers.AUTO is -1).
var _flag_quality := -2
var _flag_controls := -1
## F 2026-11-13: --pads=arrows|slider: Classic's touch controls for the run (settings.gd `pads`).
var _flag_pads := -1
## --handling=cruise|sport|grounded (or 0..2): the run drives that profile whatever the settings say.
var _flag_handling := -1
## The city objects plan, step 6: --collide=v1|soft|mid|firm, the car's collision answer
## (collide_rules.gd; the car and traffic get it) for the run, over Settings → Świat → Zderzenia
## (settings.gd `collide`, v1 by default); &"" when not given.
var _flag_collide := &""
## Beta values: --lane-assist=on|off overrides Settings → Jazda → Asysta pasa for the run; the
## lane's direction is looked up every LANE_EVERY s (lane_assist.gd).
var _flag_lane := -1
var contacts_to := ""
var _no_soft := false
## Settings rows (F 2026-11-14): --soft makes the fences and hedges break for the run whatever
## Settings → Świat → Łamliwe płoty says (off by default; the checks and drive logs that measure step
## 7 pass it). --no-soft wins over it and over the setting for the whole run (its sectors are built
## with no soft list, so nothing could turn them breakable).
var _flag_soft := false
## W2 of the walls look: --barriers=classic|typed (&"" when not given), set into solidity.gd before
## the city is built.
var _flag_barriers := &""
## --push-parked=X,Z (step 8a, for shots; needs --soft): the parked car nearest X,Z slides off its bay
## sideways as a push would send it, once its sector is in (main.gd, `soft_things.gd` `push_near`).
var _flag_push_parked := Vector2.INF
## --smash-fence=X,Z[,FRAME[,DEG]][+X,Z...] (W6 of the walls look, for shots; needs --soft): at frame
## FRAME (default 60) the soft fence or hedge nearest X,Z (within 15 m) breaks as a car crossing it
## there would break it (two panels, the debris, the sound), thrown toward DEG degrees (0 +x, 90 +z;
## default 90), so a `--shots=` strip shows before, just after and what stays (main.gd,
## `soft_things.gd` `smash_near`). With --cams, the k-th smash is the k-th camera's, its FRAME counted
## from that camera's start as its shots are.
var _flag_smash_fence: Array[Vector4] = []
var _flag_traffic := -1
var _flag_fixed := false
var _flag_perf := false
var open_settings_at_start := false
## F's asks (2026-10-30): --fullmap opens the full-screen map at the start (screenshots).
var open_map_at_start := false
## --quest-quit=S (F 2026-11-08): S s into the run, open the full map and tap its quit button twice
## (the quest under way gives up; Autopilot and test runs).
var quest_quit_flag := -1.0
var map_jump := Vector2.INF
## GAMEPLAY_PLAN 0.1, --teleport-test (verify step `teleport`): teleports to each of
## TELEPORT_TESTS in turn and fails (push_error) if the car lands in a tunnel, off the level of the
## ground or a deck there, or far from where it was asked; prints "teleport test: OK n/n".
var teleport_test := false
var hold_stick := Vector2.INF
var hold_pedal := ""
## Testing aid (--clicks=X:Y:F,...): a mouse click (a touch, with the project's touch
## emulation) at screen pixel X,Y on frame F, released two frames later.
var clicks: Array[Vector3i] = []
## Testing aid (--drag=X:Y:F:DX:DY:F2): a finger down at X,Y on frame F, moved by DX,DY over
## ten frames, held, and lifted on frame F2 (the stick through the real touch path).
var drags: Array[PackedInt32Array] = []
## --sound-check: play every sound once and print the bus meters (sfx.gd).
var sound_check := false
var _water_test_at := Vector2.INF
## --traffic-overlaps (testing aid): traffic counts its cars' overlapping boxes, printed at the end.
var _traffic_overlaps := false
## The traffic loop, --tram-watch=N (testing aid): the car (no collisions, standing still) is put
## beside tram N, ahead of it, again and again, so the view, the traffic and
## the tram's cars come with that tram through the city (with --traffic-overlaps: how often a
## tram and a car touch). -1: off.
var tram_watch := -1
## Loop 2c, --lineup (testing aid): every vehicle model standing round the car, no traffic, for
## close-up screenshots (with --size=25 or so).
var lineup := false
var cam_log := false
var title_choice := ""
var resume_flag: Array = []
## --stops=FILE (with --shots= far ahead): the camera stops at each [x, z, yaw, pitch, size, name]
## of the JSON list and saves <name>.png in --out, so one run shoots a whole street.
var stops: Array = []
var monolithic := false
var _sectors_all := false
var _sectors_proxies := false
var _stream_log := false
## Loop 3d-2b: --stream-ahead=0, --stream-slow=MS (sector_streamer.gd look_ahead, slow_ms).
var _stream_ahead := true
var _stream_slow := 0
var _stream_gate := true
var _spots: Array[Vector3] = []
## Loop 3d-2b, --stream-pass=heli|car: one fast pass across the map instead of the soak's tour
## (the helicopter at its highest and fastest, or the car at PASS_CAR_SPEED in its widest view).
## The loading fix (2026-10-31), the passes that look for a proxy close up: heli-low (the helicopter
## at its usual 45 m, full speed, four turns from the spawn), start (the same from the first frame,
## no waiting for the ring round the start), switch (the car at PASS_CAR_SPEED, then the helicopter
## takes off and flies on), look (hovering at the spawn, a look at a target 0.6-3 km away every
## PASS_EVENT_S, as a new rescue or delivery target gets) and jump (the car put somewhere new every
## PASS_EVENT_S, as a tow or a race start does).
var _pass_kind := ""


## W2 of the walls look: on the prebuilt path the barriers are what bake_city.gd baked
## (map/sectors/city.stamp "barrier_look"); when the run's look (the palette's key or
## --barriers=) is another, one line says so and the run goes on. Nothing when the stamp is not
## there (an exported game carries none).
func note_barrier_look(use_prebuilt: bool) -> void:
	if not use_prebuilt or not FileAccess.file_exists("res://map/sectors/city.stamp"):
		return
	var stamp: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/sectors/city.stamp"))
	var baked := StringName(str((stamp as Dictionary).get("barrier_look", "classic"))) if stamp is Dictionary else &"classic"
	if baked != Solidity.barrier_look():
		print("barriers: the prebuilt city is baked %s; %s is ignored on this path" % [baked,
				"--barriers" if _flag_barriers != &"" else "the palette's barrier_look"])


## Reads the command line: main.gd's `_ready`, first thing.
func parse() -> void:
	parse_with(Main.game_args())


## The test flags whose runs call the test harness (TD-4 a2, dev_harness.gd), by the value each sets:
## --bench, --probe, --cam-log, --cam-test=, --lineup, --teleport-test, --quest-quit=, --contacts=,
## --tram-watch=, --drive-into-water=, --clicks=, --drag=, --stops=, --spots=, --stream-pass=,
## --stream-soak=, --shots=, --ram-test, --egg=, --push-parked= and --smash-fence=. main.gd loads the harness once both parsers
## have run (`parse()`, then `parse_stream()`), only when one of them is on. --nosave, --notitle,
## --clock=, --autopilot and every other flag set none of them, so those runs play with no harness,
## as a release build always does (its list is empty, release.gd). `check_dev_flags` checks this
## list against every harness call's tests in main.gd.
func wants_harness() -> bool:
	return bench or probe or cam_log or lineup or teleport_test or quest_quit_flag >= 0.0 \
			or contacts_to != "" or tram_watch >= 0 or _water_test_at != Vector2.INF \
			or not clicks.is_empty() or not drags.is_empty() or not stops.is_empty() or not _spots.is_empty() \
			or _pass_kind != "" or m._soak_minutes > 0.0 or not m.shots.is_empty() or m.cam_test != "" \
			or m.ram_test != 0 or not m._egg.is_empty() or _flag_push_parked != Vector2.INF or _flag_smash_fence.size() > 0


## The flags of `args`, in their order.
func parse_with(args: PackedStringArray) -> void:
	start_station = 1
	for arg in args:
		if arg == "--demo":
			demo = true
		elif arg.begins_with("--lang="):
			_flag_lang = arg.trim_prefix("--lang=")  # pl or en, for shots and checks
		elif arg == "--left-handed":
			_flag_left_handed = true  # accessibility (2026-11-01): the mirrored controls, for shots
		elif arg == "--color-safe":
			_flag_color_safe = true  # accessibility (2026-11-03): colour-safe rings and tint, for shots
		elif arg.begins_with("--shots="):
			for s in arg.trim_prefix("--shots=").split(","):
				m.shots.append(int(s))
			# A shots run is a scripted render: its window never takes the keyboard focus, as with
			# --no-input (night --nohud shots had come out in the helicopter or at dusk: keys typed
			# in another app landed in the freshly opened game window).
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		elif arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--spots="):
			# NAME:X,Z[,HEADING];NAME:X,Z... : one run shoots every spot (street passes, before/after).
			for item in arg.trim_prefix("--spots=").split(";", false):
				var nv := item.split(":")
				var v := nv[1].split(",") if nv.size() > 1 else PackedStringArray()
				if v.size() < 2:
					push_error("--spots: '%s' is not NAME:X,Z[,HEADING]" % item)
					continue
				shot_spots.append([nv[0], Vector2(float(v[0]), float(v[1])), float(v[2]) if v.size() > 2 else INF])
			if not shot_spots.is_empty():
				m.start_at = Vector3(shot_spots[0][1].x, 0.0, shot_spots[0][1].y)
				if shot_spots[0][2] != INF:
					m.start_heading = shot_spots[0][2]
		elif arg.begins_with("--style="):
			_flag_style = posmod(int(arg.trim_prefix("--style=")), Main.STYLES.size())
		elif arg.begins_with("--stops="):
			stops = JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--stops=")))
		elif arg.begins_with("--at="):
			var xz := arg.trim_prefix("--at=").split(",")
			m.start_at = Vector3(float(xz[0]), 0.0, float(xz[1]))
		elif arg.begins_with("--heading="):
			m.start_heading = float(arg.trim_prefix("--heading="))
		elif arg.begins_with("--pitch="):
			m.camera_pitch = float(arg.trim_prefix("--pitch="))
			_flag_pitch = true
		elif arg.begins_with("--lines="):
			lines_override = int(arg.trim_prefix("--lines="))
		elif arg.begins_with("--sun="):
			sun_pitch = float(arg.trim_prefix("--sun="))
		elif arg == "--debug-ao":
			debug_ao = true
		elif arg.begins_with("--palace="):
			# The Blender trial (2026-11-13): code, blender (LOD 0) or blender1 (LOD 1).
			preload("res://scripts/landmarks.gd").palace_flag = arg.trim_prefix("--palace=")
		elif arg.begins_with("--solo="):
			solo_site = arg.trim_prefix("--solo=")
			MapBuilder.solo_site = solo_site
			no_traffic = true
			crowd_flag = 0  # nothing but the site in the picture (the turntable): no crowds, packs, fans, circles
			life_flag = 0
			no_parodies = true  # no Leżak scooters, frogs or venue neon beside the model
		elif arg.begins_with("--solo-look="):
			solo_look = arg.trim_prefix("--solo-look=")
		elif arg == "--tunnel":
			m.start_in_tunnel = true
		elif arg == "--under":
			start_under = true
		elif arg == "--debug-roads":
			debug_roads = true
		elif arg == "--colliders":
			collider_view = true
		elif arg.begins_with("--lift="):
			cam_lift = float(arg.trim_prefix("--lift="))
		elif arg.begins_with("--cam="):
			var fc := FollowCamera.parse_free(arg.trim_prefix("--cam="))
			if fc.is_empty():
				push_error("--cam: '%s' is not X,Z or X,Y,Z" % arg)
			else:
				free_cam = true
				m._free_cam_at = Vector3(fc[0], fc[1], fc[2])
				no_ghost = true
				if not _has_arg("--at="):
					m.start_at = Vector3(fc[0], 0.0, fc[2])
		elif arg == "--cam-car":
			_free_cam_car = true
		elif arg.begins_with("--cams="):
			_cams = FollowCamera.parse_cams(arg.trim_prefix("--cams="))
			if _cams.is_empty():
				push_error("--cams: '%s' is not NAME:X,Y,Z[,YAW[,PITCH[,SIZE]]] joined with +" % arg)
			else:
				free_cam = true
				no_ghost = true
				for c: Dictionary in _cams:
					shot_spots.append([c["name"], Vector2(c["at"].x, c["at"].z), INF])
					_flag_yaw = _flag_yaw or not is_nan(c["yaw"])
					_flag_pitch = _flag_pitch or not is_nan(c["pitch"])
					_flag_size = _flag_size or not is_nan(c["size"])
				m.start_at = Vector3(_cams[0]["at"].x, 0.0, _cams[0]["at"].z)
				m._apply_cam(0)
		elif arg.begins_with("--ghost-debug="):
			ghost_debug = int(arg.trim_prefix("--ghost-debug="))
		elif arg == "--prebuilt":
			prebuilt = true
		elif arg == "--no-ao":
			no_ao = true
		elif arg == "--lite-shaders":
			GpuQuirks.forced = true  # the Adreno 6xx shaders on any GPU (gpu_quirks.gd)
		elif arg == "--nohud":
			hide_hud = true
		elif arg == "--no-touch":
			no_touch = true  # desktop: --no-touch
		elif arg == "--mac" or arg == "--mac=on":
			MacMode.forced = 1  # Mac step 1: the Mac rules on any computer (mac_mode.gd)
		elif arg == "--mac=off":
			MacMode.forced = 0
		elif arg == "--no-input":
			# Loop 3d-1: a test render ignores every key, click and touch (check_streaming's windows
			# take the focus for minutes: keys typed elsewhere toggled the time, the overlay, the radio).
			# The window never takes the focus, so keys typed elsewhere stay there.
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		elif arg.begins_with("--size="):
			m.base_size = float(arg.trim_prefix("--size="))
			_flag_size = true
		elif arg == "--fixed":
			_flag_fixed = true
		elif arg.begins_with("--yaw="):
			m.cam_yaw = float(arg.trim_prefix("--yaw="))
			m.cam_yaw_target = m.cam_yaw
			_flag_yaw = true
		elif arg == "--cinematic" or arg.begins_with("--cinematic="):
			_flag_cinematic = arg.trim_prefix("--cinematic=") if arg.contains("=") else "all"
		elif arg.begins_with("--stats="):
			stats_flag = arg.trim_prefix("--stats=")
		elif arg == "--heli":
			start_flying = true
		elif arg.begins_with("--promo-heli="):
			for v in arg.trim_prefix("--promo-heli=").split(","):
				promo_heli.append(float(v))
		elif arg.begins_with("--heli-stick="):
			var hs := arg.trim_prefix("--heli-stick=").split(",")
			if hs.size() == 2:
				heli_stick = Vector2(float(hs[0]), float(hs[1]))
		elif arg.begins_with("--heli-alt="):
			# Loop 3d-2b: start flying this high over the ground, placed there at once (the
			# helicopter at its highest, Heli.MAX_HEIGHT 360, for the memory and far-level probes).
			start_flying = true
			_start_alt = clampf(float(arg.trim_prefix("--heli-alt=")), 6.0, Heli.MAX_HEIGHT)
		elif arg.begins_with("--mission="):
			start_mission = maxi(1, int(arg.trim_prefix("--mission=")))
		elif arg == "--autopilot":
			autopilot = true
		elif arg.begins_with("--contacts="):
			contacts_to = arg.trim_prefix("--contacts=")
		elif arg == "--no-soft":
			# Step 7: before the city is built (the builder reads it: every fence and hedge hard).
			_no_soft = true
			CityBarriers.soft_off = true
		elif arg == "--soft":
			_flag_soft = true
		elif arg.begins_with("--barriers="):
			# W2 of the walls look: before the city is built (the wall builder reads it): the runtime
			# city's walls, fences and hedges in that look (classic, typed or panels) over the palette's
			# barrier_look. The prebuilt city is the look it was baked in (`note_barrier_look`).
			_flag_barriers = StringName(arg.trim_prefix("--barriers="))
			Solidity.set_barrier_look(_flag_barriers)
		elif arg.begins_with("--smash-fence="):
			for one in arg.trim_prefix("--smash-fence=").split("+"):
				var sf := one.split_floats(",")
				if sf.size() < 2:
					push_error("--smash-fence: '%s' is not X,Z[,FRAME[,DEG]] joined with +" % arg)
					break
				_flag_smash_fence.append(Vector4(sf[0], sf[1], sf[2] if sf.size() > 2 else 60.0, sf[3] if sf.size() > 3 else 90.0))
		elif arg.begins_with("--push-parked="):
			var pp := arg.trim_prefix("--push-parked=").split_floats(",")
			_flag_push_parked = Vector2(pp[0], pp[1])
		elif arg == "--race-debug":
			race_debug = true
		elif arg.begins_with("--ghost-pace="):
			var gp := arg.trim_prefix("--ghost-pace=")
			ghost_pace = 99.0 if gp == "racer" else float(gp)
		elif arg == "--no-traffic":
			no_traffic = true
		elif arg == "--lineup":
			lineup = true
			no_traffic = true
			free_roam = true
		elif arg.begins_with("--race="):
			start_race = maxi(1, int(arg.trim_prefix("--race=")))
		elif arg.begins_with("--rival="):
			start_rival = maxi(1, int(arg.trim_prefix("--rival=")))
		elif arg == "--bench":
			bench = true
		elif arg.begins_with("--bench-frames="):
			_bench_frames = maxi(60, int(arg.trim_prefix("--bench-frames=")))
		elif arg.begins_with("--bench-seconds="):
			_bench_seconds = maxf(5.0, float(arg.trim_prefix("--bench-seconds=")))
			_phone_seconds = _bench_seconds
		elif arg == "--bench-button":
			bench_button = true
		elif arg.begins_with("--fps="):
			_flag_fps = maxi(0, int(arg.trim_prefix("--fps=")))
		elif arg == "--probe":
			probe = true
			free_roam = true
		elif arg == "--no-map-edge":
			_flag_no_map_edge = true
		elif arg == "--no-edge-roadworks":
			_flag_no_edge_roadworks = true
		elif arg.begins_with("--exp="):
			_exp = arg.trim_prefix("--exp=").split(",")
		elif arg.begins_with("--time="):
			start_time = TimeOfDay.parse(arg.trim_prefix("--time="))
		elif arg.begins_with("--grade="):
			grade = arg.trim_prefix("--grade=")
		elif arg.begins_with("--grade-sweep="):
			# TIME,TIME:GRADE,GRADE : every --spots spot is shot at each time in each look.
			var tg := arg.trim_prefix("--grade-sweep=").split(":")
			for t in tg[0].split(","):
				for g in (tg[1].split(",") if tg.size() > 1 else PackedStringArray(Grades.NAMES)):
					grade_sweep.append([t, g])
			start_time = TimeOfDay.parse(grade_sweep[0][0])
			grade = grade_sweep[0][1]
		elif arg.begins_with("--call-in="):
			call_in = maxf(0.0, float(arg.trim_prefix("--call-in=")))
		elif arg.begins_with("--radio="):
			var v := arg.trim_prefix("--radio=")
			# Loop MW-5: clamped to radio.json's stations when the radio is tuned (_ready).
			start_station = 0 if v == "off" else clampi(int(v), 0, 99)
			radio_picked = true
		elif arg.begins_with("--station="):
			station_flag = arg.trim_prefix("--station=")
			radio_picked = true
		elif arg == "--radio-log":
			radio_log = true
		elif arg.begins_with("--unlock="):
			unlock_flag = arg.trim_prefix("--unlock=")
		elif arg == "--notitle":
			show_title = false
		elif arg == "--title":
			force_title = true
		elif arg.begins_with("--kebab="):
			start_kebab = maxi(0, int(arg.trim_prefix("--kebab=")))
		elif arg == "--courier-race" or arg.begins_with("--courier-race="):
			# Loop jobs-2: kebab order N with the courier's challenge (day or night).
			courier_race = true
			start_kebab = maxi(0, int(arg.trim_prefix("--courier-race="))) if arg.contains("=") else 0
		elif arg == "--pedzik-log":
			pedzik_log = true  # loop couriers
		elif arg == "--pedzik-kerb":
			pedzik_kerb = true  # loop couriers
		elif arg.begins_with("--courier-v="):
			courier_v = clampf(float(arg.trim_prefix("--courier-v=")), 0.5, 30.0)
		elif arg == "--roundup":
			roundup_flag = true
		elif arg == "--armchair":
			armchair_flag = true
		elif arg.begins_with("--sloik-station="):
			start_sloik_station = maxi(0, int(arg.trim_prefix("--sloik-station=")))
		elif arg == "--sloik" or arg.begins_with("--sloik="):
			start_sloik = maxi(0, int(arg.trim_prefix("--sloik="))) if arg.contains("=") else 0
		elif arg.begins_with("--heat="):
			start_heat = clampf(float(arg.trim_prefix("--heat=")), 0.0, 1.0)
		elif arg == "--craft=plain":
			craft_plain = true
		# --- loop 2d-1: Łuber's flags ---
		elif arg.begins_with("--ride="):
			start_ride = maxi(0, int(arg.trim_prefix("--ride=")))
		elif arg.begins_with("--ride-quirk="):
			ride_quirk = arg.trim_prefix("--ride-quirk=").to_lower()
		elif arg.begins_with("--passenger="):
			ride_passenger = arg.trim_prefix("--passenger=").to_lower()
		elif arg.begins_with("--ride-story="):
			ride_story = arg.trim_prefix("--ride-story=").to_lower()
		elif arg.begins_with("--ride-answer="):
			ride_answer = clampi(int(arg.trim_prefix("--ride-answer=")), 0, 1)
		elif arg.begins_with("--stars="):
			ride_stars = clampf(float(arg.trim_prefix("--stars=")), 1.0, 5.0)
		elif arg == "--ignore-app":
			ignore_app = true
		elif arg == "--parody-log":
			parody_log = true
		elif arg.begins_with("--gps-in="):
			gps_in = maxf(0.0, float(arg.trim_prefix("--gps-in=")))
		# --- end loop 2d-1 ---
		elif arg == "--no-parodies":
			no_parodies = true
		elif arg == "--rechotka":
			rechotka_flag = true
		elif arg.begins_with("--stamps="):
			stamps_flag = maxi(0, int(arg.trim_prefix("--stamps=")))
		elif arg.begins_with("--host-in="):
			host_in = maxf(0.0, float(arg.trim_prefix("--host-in=")))
		elif arg.begins_with("--barriers="):
			barrier_day = int(arg.trim_prefix("--barriers="))
		elif arg == "--reset-save":
			reset_save = true
		elif arg == "--boot":
			pass  # the boot scene (boot.gd, TD-15): this run starts as a player's launch does
		elif arg == "--report":
			report_flag = true  # the error trap (TD-14): the report printed when the run ends
		elif arg == "--crash-note":
			crash_note_flag = true  # the note after a session that closed by itself
		elif arg.begins_with("--save-note="):
			save_note_flag = arg.trim_prefix("--save-note=")  # safer saves (TD-8): restored|lost|blocked
		elif arg.begins_with("--title-choice="):
			title_choice = arg.trim_prefix("--title-choice=")  # save and resume: continue|new
			force_title = true
		elif arg.begins_with("--resume="):
			# Save and resume: --resume=x,z[,heading°] a kept spot in memory (with --nosave: the test of
			# the resume path without a real save).
			var r := arg.trim_prefix("--resume=").split(",")
			if r.size() >= 2:
				resume_flag = [Vector3(float(r[0]), 0.0, float(r[1])), -deg_to_rad(float(r[2])) if r.size() > 2 else 0.0]
			force_title = true
		elif arg == "--nosave":
			no_save = true
		elif arg == "--free":
			free_roam = true
		elif arg == "--no-ghost":
			no_ghost = true
		elif arg == "--topdown":
			m.top_down = true
		elif arg.begins_with("--tap="):
			var xy := arg.trim_prefix("--tap=").split(",")
			tap_at = Vector2(float(xy[0]), float(xy[1]))
		elif arg.begins_with("--weather="):
			start_weather = Weather.parse(arg.trim_prefix("--weather="))
		elif arg.begins_with("--clock="):
			live_clock = arg.trim_prefix("--clock=")
		elif arg.begins_with("--date="):
			live_date = int(arg.trim_prefix("--date="))
		elif arg == "--game-clock":
			game_clock = true
		elif arg.begins_with("--palace-lights="):
			palace_lights_id = arg.trim_prefix("--palace-lights=")
		elif arg == "--perf":
			_flag_perf = true
		elif arg == "--sound-check":
			sound_check = true
		elif arg.begins_with("--quality="):
			_flag_quality = Tiers.parse(arg.trim_prefix("--quality="))
		elif arg.begins_with("--gfx="):
			# Perf thread (2026-11-19): per-option overrides on top of the quality level,
			# "key=value,..." (tiers.gd value, parse_overrides): --gfx=scale=2,msaa=4,shadow_size=2048.
			Tiers.overrides = Tiers.parse_overrides(arg.trim_prefix("--gfx="))
		elif arg.begins_with("--model="):
			_flag_model = arg.trim_prefix("--model=")
		elif arg.begins_with("--last-session="):
			# Loop G1b: Auto as if the last session at the sharp image struggled or was calm.
			_flag_last_session = arg.trim_prefix("--last-session=")
		elif arg.begins_with("--governor="):
			_flag_governor = 0 if arg.trim_prefix("--governor=") in ["off", "0", "no"] else 1
			_governor_log = arg == "--governor=log"
		elif arg.begins_with("--stress="):
			var st := arg.trim_prefix("--stress=").split(":")
			_stress_kind = st[0] if st[0] in ["cpu", "wait"] else ""
			_stress_n = maxi(0, int(st[1])) if st.size() > 1 else 0
		elif arg.begins_with("--stress-from="):
			_stress_from = maxf(0.0, float(arg.trim_prefix("--stress-from=")))
		elif arg.begins_with("--stress-to="):
			_stress_to = maxf(0.0, float(arg.trim_prefix("--stress-to=")))
		elif arg.begins_with("--controls="):
			_flag_controls = Controls.parse(arg.trim_prefix("--controls="))
		elif arg.begins_with("--pads="):
			_flag_pads = 1 if arg.trim_prefix("--pads=") in ["slider", "strip", "1"] else 0
		elif arg.begins_with("--handling="):
			_flag_handling = Car.parse_handling(arg.trim_prefix("--handling="))
		elif arg.begins_with("--collide="):
			_flag_collide = Car.CollideRules.parse(arg.trim_prefix("--collide="))
		elif arg.begins_with("--lane-assist="):
			_flag_lane = 1 if arg.trim_prefix("--lane-assist=") in ["on", "1", "true"] else 0
		elif arg.begins_with("--traffic="):
			_flag_traffic = Settings.parse_traffic(arg.trim_prefix("--traffic="))
		elif arg == "--settings":
			open_settings_at_start = true
		elif arg == "--teleport-test":
			teleport_test = true
		elif arg.begins_with("--map-jump="):
			# 2026-10-31: the full map's hold-to-teleport to x,z once the drive starts (tests).
			var xz := arg.trim_prefix("--map-jump=").split(",")
			map_jump = Vector2(float(xz[0]), float(xz[1]))
		elif arg.begins_with("--quest-quit="):
			quest_quit_flag = float(arg.trim_prefix("--quest-quit="))
		elif arg.begins_with("--quest-pick="):
			m.quest_pick_flag = int(arg.trim_prefix("--quest-pick="))
			open_map_at_start = true
		elif arg == "--fullmap" or arg.begins_with("--fullmap="):
			open_map_at_start = true
			# --fullmap=M (2026-10-31): open it M metres across the screen's height (shots).
			if arg.contains("="):
				m.fullmap_span = maxf(1.0, float(arg.trim_prefix("--fullmap=")))
		elif arg == "--notebook" or arg.begins_with("--notebook="):
			# Loop MW-1: the notebook's tab at the start (a chapter, or a place's card).
			open_settings_at_start = true
			settings_tab = "notebook"
			notebook_open = arg.trim_prefix("--notebook").trim_prefix("=")
		elif arg.begins_with("--found="):
			found_spec = arg.trim_prefix("--found=")
		elif arg.begins_with("--place="):
			place_flag = arg.trim_prefix("--place=")
		elif arg == "--notes-log":
			notes_log = true
		elif arg.begins_with("--crowd="):
			crowd_flag = clampi(int(arg.trim_prefix("--crowd=")), 0, 2)
		elif arg == "--night-log":
			night_log = true
		elif arg == "--night-hub":
			night_hub_flag = true
		elif arg == "--bus-log":
			bus_log = true
		elif arg.begins_with("--crash="):
			crash_flag = arg.trim_prefix("--crash=")
		elif arg in ["--rave-call", "--rave-smola", "--rave-club", "--rave-patio"]:
			rave_flag = arg.trim_prefix("--rave-")
		elif arg.begins_with("--rave-spot="):
			rave_spot = arg.trim_prefix("--rave-spot=")
		elif arg.begins_with("--rave="):
			rave_flag = arg.trim_prefix("--rave=")
		elif arg == "--crawl-call":
			crawl_flag = "call"
		elif arg.begins_with("--crawl-route="):
			crawl_route = arg.trim_prefix("--crawl-route=")
		elif arg.begins_with("--crawl-group="):
			crawl_group = arg.trim_prefix("--crawl-group=")
		elif arg.begins_with("--crawl="):
			crawl_flag = arg.trim_prefix("--crawl=")
		elif arg == "--crawl-log":
			crawl_log = true
		elif arg.begins_with("--tapczan="):
			tapczan_flag = arg.trim_prefix("--tapczan=")
		elif arg == "--tapczan-log":
			tapczan_log = true
		elif arg == "--rave-log":
			rave_log = true
		elif arg == "--decks":
			decks_flag = "on"
			rave_flag = "club"
		elif arg.begins_with("--decks-bot="):
			decks_bot = arg.trim_prefix("--decks-bot=")
		elif arg == "--decks-log":
			decks_log = true
		elif arg in ["--shisha-call", "--shisha-meet", "--shisha-door", "--shisha-arrive", "--shisha-lounge", "--shisha-terrace", "--shisha-hold"]:
			shisha_flag = arg.trim_prefix("--shisha-")
		elif arg.begins_with("--shisha="):
			shisha_flag = arg.trim_prefix("--shisha=")
		elif arg == "--shisha-log":
			shisha_log = true
		elif arg == "--padel-match":
			padel_flag = 12.0
		elif arg.begins_with("--padel-match="):
			padel_flag = float(arg.trim_prefix("--padel-match="))
		elif arg == "--padel-log":
			padel_log = true
		elif arg == "--meet-call":
			meet_flag = "call"
		elif arg.begins_with("--meet-at="):
			meet_at = arg.trim_prefix("--meet-at=")
		elif arg.begins_with("--meet="):
			meet_flag = arg.trim_prefix("--meet=")
		elif arg == "--meet-log":
			meet_log = true
		elif arg == "--stories-log":
			stories_log = true
		elif arg == "--story-meet":
			story_meet_flag = true
		elif arg.begins_with("--story="):
			story_flag = arg.trim_prefix("--story=")
		elif arg.begins_with("--quest-tab="):
			m.quest_tab_flag = int(arg.trim_prefix("--quest-tab="))
			open_map_at_start = true
		elif arg == "--quests":
			m.quests_flag = true  # 2026-11-17: the QUESTS screen up at the start (shots)
			open_map_at_start = true
		elif arg.begins_with("--boat-race"):
			boat_flag = arg.trim_prefix("--boat-race=") if arg.contains("=") else "call"
		elif arg == "--boat-log":
			boat_log = true
		elif arg.begins_with("--dekalog"):
			if arg == "--dekalog-log":
				dekalog_log = true
			else:
				dekalog_flag = arg.trim_prefix("--dekalog=") if arg.contains("=") else "call"
		elif arg.begins_with("--kino-tour"):
			kino_flag = arg.trim_prefix("--kino-tour=") if arg.contains("=") else "call"
		elif arg == "--kino-log":
			kino_log = true
		elif arg == "--ev-call" or arg == "--ev-tow" or arg == "--ev-stranded":
			ev_flag = arg.trim_prefix("--ev-")
		elif arg.begins_with("--ev-tow="):
			ev_flag = "tow=" + arg.trim_prefix("--ev-tow=")
		elif arg == "--ev=0":
			ev_flag = "0"
		elif arg == "--ev-log":
			ev_log = true
		elif arg == "--crash-log":
			crash_log = true
		elif arg.begins_with("--ambulance="):
			ambulance_flag = arg.trim_prefix("--ambulance=")
		elif arg.begins_with("--wedding="):
			wedding_flag = arg.trim_prefix("--wedding=")
		elif arg.begins_with("--elka="):
			elka_flag = clampf(float(arg.trim_prefix("--elka=")), 0.0, 1.0)
		elif arg == "--road-log":
			road_log = true
		elif arg.begins_with("--loud="):
			loud_flag = clampi(int(arg.trim_prefix("--loud=")), 0, 16)
		elif arg == "--loud-log":
			loud_log = true
		elif arg.begins_with("--crazy="):
			crazy_flag = clampi(int(arg.trim_prefix("--crazy=")), 0, 12)
		elif arg == "--crazy-log":
			crazy_log = true
		elif arg == "--old-tram" or arg.begins_with("--old-tram="):
			old_tram_flag = "follow" if arg == "--old-tram=follow" else "now"
		elif arg.begins_with("--promo-delay="):
			promo_delay = float(arg.trim_prefix("--promo-delay="))
		elif arg.begins_with("--promo-parts="):
			promo_parts = PackedStringArray(arg.trim_prefix("--promo-parts=").split(","))
		elif arg.begins_with("--promo-at="):
			var pa := arg.trim_prefix("--promo-at=").split(",")
			if pa.size() >= 2:
				promo_at = Vector2(float(pa[0]), float(pa[1]))
			if pa.size() >= 3:
				promo_t = float(pa[2])
		elif arg.begins_with("--season="):
			season = arg.trim_prefix("--season=")
			# x the summer-to-autumn turn, y the fall of leaves (project.godot holds mid-November).
			var look := Vector4(0, 0, 0, 0) if season == "summer" else Vector4(1, 0.5, 0, 0)
			RenderingServer.global_shader_parameter_set("tree_season", look)
		elif arg.begins_with("--people="):
			people = int(arg.trim_prefix("--people="))
		elif arg.begins_with("--scoot-gang="):
			var sg := arg.trim_prefix("--scoot-gang=").split(",")
			if sg.size() >= 2:
				scoot_gang = Vector3(float(sg[0]), float(sg[1]), float(sg[2]) if sg.size() > 2 else 3.0)
				scoot_gang_dir = float(sg[3]) if sg.size() > 3 else 1.0
		elif arg.begins_with("--pigeons-at="):
			pigeons_at = maxf(0.01, float(arg.trim_prefix("--pigeons-at=")))
		elif arg.begins_with("--train="):
			var xz := arg.trim_prefix("--train=").split(",")
			if xz.size() >= 2:
				train_at = Vector2(float(xz[0]), float(xz[1]))
			if xz.size() == 3:
				train_kind = int(xz[2])
		elif arg == "--tram-log":
			tram_log = true
		elif arg.begins_with("--packs="):
			packs_flag = clampi(int(arg.trim_prefix("--packs=")), 0, 1)
		elif arg == "--packs-now":
			packs_now = true
		elif arg == "--packs-log":
			packs_log = true
		elif arg.begins_with("--fans="):
			fans_flag = clampi(int(arg.trim_prefix("--fans=")), 0, 1)
		elif arg == "--fans-now":
			fans_now = true
		elif arg == "--fans-log":
			fans_log = true
		elif arg == "--event-day":
			event_flag = 1
		elif arg.begins_with("--event-day="):
			event_flag = clampi(int(arg.trim_prefix("--event-day=")), 0, 1)
		elif arg.begins_with("--event-smoke="):
			event_smoke = clampi(int(arg.trim_prefix("--event-smoke=")), 0, 1)
		elif arg == "--event-log":
			event_log = true
		elif arg.begins_with("--event-t="):
			event_t = maxf(0.0, float(arg.trim_prefix("--event-t=")))
		elif arg.begins_with("--fans-phase="):
			fans_phase = arg.trim_prefix("--fans-phase=")
		elif arg.begins_with("--fans-result="):
			fans_result = arg.trim_prefix("--fans-result=")
		elif arg.begins_with("--wellness="):
			wellness_flag = clampi(int(arg.trim_prefix("--wellness=")), 0, 1)
		elif arg == "--wellness-now":
			wellness_now = true
		elif arg == "--wellness-log":
			wellness_log = true
		elif arg == "--tamka-log":
			tamka_log = true  # tamka.gd: the bollards' count, KEBONAFIDE's place and lines
		elif arg.begins_with("--honk="):
			for f in arg.trim_prefix("--honk=").split(",", false):
				honk_frames.append(int(f))
		elif arg.begins_with("--life="):
			life_flag = clampi(int(arg.trim_prefix("--life=")), 0, 2)
		elif arg == "--dogs-log":
			dogs_log = true
		elif arg == "--trend-log":
			trend_log = true
		elif arg.begins_with("--blvd-t="):
			blvd_t0 = float(arg.trim_prefix("--blvd-t="))
		elif arg == "--life-log":
			life_log = true
		elif arg == "--life-soak":
			life_soak = true
			life_log = true
		elif arg == "--dzemini":
			dzemini_flag = true
			trend_log = true
		elif arg == "--tajny" or arg.begins_with("--tajny="):
			tajny_flag = arg.trim_prefix("--tajny=") if arg.contains("=") else "on"
		elif arg == "--zajac":
			zajac_flag = true
			life_log = true
		elif arg.begins_with("--trend-day="):
			trend_day_flag = maxi(0, int(arg.trim_prefix("--trend-day=")))
		elif arg == "--trend-job" or arg.begins_with("--trend-job="):
			trend_job_flag = clampi(int(arg.trim_prefix("--trend-job=")) if arg.contains("=") else 1, 1, 9)
			trend_log = true
		elif arg.begins_with("--club="):
			# Loop MW-3: the car at a club's door (places.json id or name), no title.
			m.club_flag = arg.trim_prefix("--club=")
			show_title = false
			free_roam = true
		elif arg.begins_with("--paint="):
			paint_flag = arg.trim_prefix("--paint=")  # the garage loop
		elif arg == "--garage" or arg == "--garage=ring" or arg == "--garage=parts":
			garage_flag = true
			garage_ring_only = arg == "--garage=ring"
			garage_parts = arg == "--garage=parts"
			garage_log = true
			show_title = false
			free_roam = true
		elif arg == "--garage-log":
			garage_log = true
		elif arg.begins_with("--upgrades="):
			upgrades_flag = arg.trim_prefix("--upgrades=")  # G13: all | tt | nitro, for this run
		elif arg.begins_with("--egg="):
			egg_flag = arg.trim_prefix("--egg=")
		elif arg.begins_with("--district="):
			district_card = arg.trim_prefix("--district=")
		elif arg.begins_with("--pop="):
			pop_flag = int(arg.trim_prefix("--pop="))
		elif arg.begins_with("--districts="):
			districts_spec = arg.trim_prefix("--districts=")
		elif arg == "--districts-log":
			districts_log = true
		elif arg == "--syrenki-log":
			syrenki_log = true
		elif arg.begins_with("--syrenki="):
			syrenki_spec = arg.trim_prefix("--syrenki=")
		elif arg.begins_with("--syrenka="):
			syrenka_flag = arg.trim_prefix("--syrenka=")
		elif arg == "--first10":
			first10_flag = true  # loop 3h slice 4
		elif arg == "--end-card":
			end_card_flag = true
		elif arg == "--first-race":
			first_race_flag = true
		elif arg.begins_with("--hint="):
			hint_flag = arg.trim_prefix("--hint=")
		elif arg == "--no-hints":
			no_hints = true
		elif arg == "--map-coach":
			map_coach = true
		elif arg.begins_with("--ladder="):
			ladder_flag = clampi(int(arg.trim_prefix("--ladder=")), 0, Ladder.FINAL + 1)  # loop 3h slice 3
		elif arg == "--trzy-mosty" or arg.begins_with("--trzy-mosty="):
			trzy_mosty_flag = true
			trzy_mosty_bridge = clampi(int(arg.trim_prefix("--trzy-mosty=")), 0, 3) if arg.contains("=") else 0
			start_time = TimeOfDay.NIGHT
		elif arg == "--egg-log":
			egg_log = true
		elif arg.begins_with("--found-eggs="):
			found_eggs = arg.trim_prefix("--found-eggs=")
		elif arg.begins_with("--tape="):
			tape_flag = arg.trim_prefix("--tape=")
		elif arg == "--tape-log":
			tape_log = true
		elif arg == "--zone-cap":
			zone_cap_flag = 1
		elif arg == "--no-zone-cap":
			zone_cap_flag = 0
		elif arg == "--promo" or arg.begins_with("--promo="):
			promo_flag = "on" if arg == "--promo" else arg.trim_prefix("--promo=")
		elif arg == "--fotka" or arg == "--photo":
			fotka_flag = true
		elif arg.begins_with("--kadr="):
			kadr_flag = arg.trim_prefix("--kadr=")
			fotka_flag = true
		elif arg.begins_with("--fotka-shot="):
			m.fotka_shot = float(arg.trim_prefix("--fotka-shot="))
		elif arg == "--photo-log":
			photo_log = true
		elif arg.begins_with("--settings-tab="):
			open_settings_at_start = true
			settings_tab = arg.trim_prefix("--settings-tab=")
		elif arg.begins_with("--stick="):
			var sv2 := arg.trim_prefix("--stick=").split(",")
			hold_stick = Vector2(float(sv2[0]), float(sv2[1])).limit_length(1.0)
		elif arg.begins_with("--pedal="):
			hold_pedal = arg.trim_prefix("--pedal=")
		elif arg.begins_with("--drag="):
			var dv := arg.trim_prefix("--drag=").split(":")
			var d := PackedInt32Array()
			for v in dv:
				d.append(int(v))
			if d.size() == 6:
				drags.append(d)
		elif arg.begins_with("--drive-into-water="):
			var wz := arg.trim_prefix("--drive-into-water=").split(",")
			_water_test_at = Vector2(float(wz[0]), float(wz[1]))
		elif arg == "--ram-test":
			m.ram_test = 1
		elif arg == "--first-life":
			m.first_life = true
		elif arg == "--traffic-overlaps":
			_traffic_overlaps = true
		elif arg.begins_with("--tram-watch="):
			tram_watch = int(arg.trim_prefix("--tram-watch="))
		elif arg == "--cam-log":
			cam_log = true
		elif arg.begins_with("--cam-test="):
			m.cam_test = arg.trim_prefix("--cam-test=")
			cam_log = true
			no_traffic = true
			free_roam = true
		elif arg.begins_with("--clicks="):
			for c in arg.trim_prefix("--clicks=").split(","):
				var xyf := c.split(":")
				clicks.append(Vector3i(int(xyf[0]), int(xyf[1]), int(xyf[2])))
		# Loop 3g-1: the police's flags (_police_flag, below).
		elif arg == "--no-police" or arg.begins_with("--police") or arg.begins_with("--trap=") or arg.begins_with("--pullover") \
				or arg in ["--escort", "--guards", "--guards=talk", "--first-contact", "--clamp"] or arg.begins_with("--clamp="):
			_police_flag(arg)
	# Test runs go straight to the city (--title brings the title screen back).
	if demo or not m.shots.is_empty() or autopilot or start_race > 0 or start_mission > 0 or start_rival > 0 or bench or probe \
			or start_kebab >= 0 or start_sloik >= 0 or sound_check or open_settings_at_start or open_map_at_start or hold_stick != Vector2.INF or bench_button \
			or _water_test_at != Vector2.INF or m.cam_test != "" or m.ram_test > 0 or tram_watch >= 0 or old_tram_flag != "" or m.first_life:
		show_title = false
	if start_ride >= 0 or place_flag != "" or roundup_flag or district_card != "" or syrenka_flag != "" or trzy_mosty_flag:
		show_title = false  # loop 2d-1: --ride is a test run too (loop MW-1: and --place; loop 3h: --district=)
	# Loop MW-6: and the eggs', the tape's and Fotka's flags; --egg sets its moment's time.
	if egg_flag != "" or tape_flag != "" or fotka_flag or pop_flag > 0:
		show_title = false
	if first10_flag or end_card_flag or first_race_flag or (tajny_flag != "" and tajny_flag != "0"):
		show_title = false  # loop 3h slice 4: --first10 and --end-card are test runs
	# Loop MW-4: --zajac is Kolka's Wednesday evening (Live), --life-soak a Friday dusk.
	if zajac_flag or life_soak or trend_job_flag > 0 or armchair_flag or dzemini_flag:
		show_title = false
		free_roam = true
	if zajac_flag:
		# Kolka's start (19:00 Wednesday, Live); the car goes to the club once its route is known
		# (_life_start: the place's own pin is off the boulevard).
		start_time = TimeOfDay.LIVE
		if live_clock == "":
			live_clock = "19:00"
		if live_date == 0 or not Main._is_wednesday(live_date):
			live_date = 20261028
	elif life_soak and start_time == TimeOfDay.DAY:
		start_time = TimeOfDay.DUSK
	_egg_moment()
	if force_title:
		show_title = true
	# Camera loop: the cinematic moments in a normal launch only (never with screenshots or a bench).
	var normal := show_title and m.shots.is_empty() and not bench and not probe and not bench_button and not demo
	game_clock = (game_clock or normal) and start_time != TimeOfDay.LIVE
	if _flag_cinematic == "event":
		# The 15 s video: the event day on, the clock 16:40 in the dusk look unless --clock says other.
		if event_flag < 0:
			event_flag = 1
		if live_clock == "":
			live_clock = "16:40"
		if start_time == TimeOfDay.DAY:
			start_time = TimeOfDay.DUSK
	cinematic_flyin = normal or _flag_cinematic in ["all", "flyin", "opening", "event"]
	cinematic_look = normal or _flag_cinematic in ["all", "look"]
	# Loop G1: the governor runs in a normal launch; test runs hold it so they repeat.
	var test_run := DisplayServer.get_name() == "headless" or not m.shots.is_empty() or bench or probe or autopilot \
			or demo or m.cam_test != "" or _water_test_at != Vector2.INF or m.ram_test > 0 or tram_watch >= 0
	_governor_on = _flag_governor == 1 if _flag_governor >= 0 else not test_run
	# The crash scenes' timer: a normal launch only (a test run with --crash=on or =now too).
	_crash_auto = not test_run
	_rave_auto = not test_run
	_shisha_auto = not test_run
	_meet_auto = not test_run
	_ev_auto = not test_run
	_crawl_auto = not test_run
	# Loop G1b: test runs (and --last-session=) never write Auto's image state, even with the
	# governor on and without --nosave.
	_image_write = not test_run and _flag_last_session == ""


func parse_stream() -> void:
	for arg in Main.game_args():
		if arg == "--monolithic":
			monolithic = true
		elif arg == "--sectors=all":
			_sectors_all = true
		elif arg == "--sectors=proxies":
			_sectors_proxies = true
		elif arg == "--stream-log":
			_stream_log = true
		elif arg == "--stream-gate=0":
			_stream_gate = false  # loop 3d-2b: a sector's pieces with its scene at once (the before)
		elif arg == "--stream-ahead=0":
			_stream_ahead = false  # loop 3d-2b: no look-ahead (the before of a before/after)
		elif arg.begins_with("--stream-slow="):
			_stream_slow = int(arg.trim_prefix("--stream-slow="))  # loop 3d-2b: a phone's slower loads
		elif arg.begins_with("--spots="):
			for s in arg.trim_prefix("--spots=").split("/"):
				var v := s.split(",")
				if v.size() >= 3:
					_spots.append(Vector3(float(v[0]), float(v[1]), float(v[2])))
		elif arg.begins_with("--stream-soak="):
			m._soak_minutes = float(arg.trim_prefix("--stream-soak="))
			no_traffic = true
			free_roam = true
			show_title = false
		elif arg.begins_with("--stream-pass="):
			_pass_kind = arg.trim_prefix("--stream-pass=")
			m._soak_minutes = 30.0  # the pass ends at its route's end
			no_traffic = true
			free_roam = true
			show_title = false
			if _pass_kind == "heli":
				start_flying = true
				_start_alt = Heli.MAX_HEIGHT
			elif _pass_kind in ["heli-low", "start", "look"]:
				# The loading fix: the helicopter at its usual height (where the player saw the proxies),
				# or at --heli-alt's.
				start_flying = true
				if _start_alt <= 0.0:
					_start_alt = Heli.CRUISE
			if _pass_kind == "start":
				m._pass_frames = -1  # counted from the first frame: no waiting for the ring round the start
				m._soak_leg = 1


## The police's testing flags (README's flags table): --no-police, --police=1|2|3, --trap=N,
## --pullover=routine|trap|kebab|sloik|generic, --police-auto=escape|stop|hold, --police-now,
## --police-log, --police-offence=FRAME:kind,... Loop 3g-2: --escort, --guards, --clamp[=sorry],
## --first-contact (police.md 14).
func _police_flag(arg: String) -> void:
	if arg == "--no-police":
		m.police_opts["off"] = true
	elif arg == "--escort":
		m.police_opts["escort"] = true
	elif arg == "--first-contact":
		m.police_opts["first_contact"] = true
		show_title = false
		free_roam = true
	elif arg == "--guards" or arg == "--guards=talk":
		# The Krakowskie Przedmieście end of the zone, heading north into it (police.gd drives;
		# =talk stops by the gate's guards).
		m.police_opts["guards"] = "talk" if arg == "--guards=talk" else "drive"
		m.start_at = Vector3(-696.0, 0.0, -1279.0)
		m.start_heading = 345.0
		show_title = false
		free_roam = true
	elif arg == "--clamp" or arg.begins_with("--clamp="):
		# Parked on Plac Zamkowy 15 m from a guard; the clamp's countdown starts at frame 60.
		m.police_opts["clamp"] = arg.trim_prefix("--clamp=") if arg.begins_with("--clamp=") else "wait"
		m.start_at = Vector3(-690.0, 0.0, -1490.0)
		m.start_heading = 250.0
		show_title = false
		free_roam = true
	elif arg == "--police-now":
		m.police_opts["now"] = true
	elif arg == "--police-log":
		m.police_opts["log"] = true
	elif arg.begins_with("--police-auto="):
		m.police_opts["auto"] = arg.trim_prefix("--police-auto=")
	elif arg.begins_with("--police-offence="):
		m.police_opts["offences"] = arg.trim_prefix("--police-offence=")
	elif arg.begins_with("--police="):
		m.police_opts["level"] = clampi(int(arg.trim_prefix("--police=")), 1, 3)
		show_title = false
		free_roam = true
	elif arg.begins_with("--trap="):
		var n := int(arg.trim_prefix("--trap="))
		m.police_opts["trap"] = n
		var start := Police.trap_start(n)
		if not start.is_empty():
			m.start_at = start[0]
			m.start_heading = start[1]
		show_title = false
		free_roam = true
	elif arg.begins_with("--pullover="):
		m.police_opts["pullover"] = arg.trim_prefix("--pullover=")
		show_title = false
		free_roam = true
	elif arg.begins_with("--pullover-frame="):
		# Loop 2d-1: the --pullover conversation at frame N (default 60), e.g. during a --ride.
		m.police_opts["pullover_frame"] = maxi(1, int(arg.trim_prefix("--pullover-frame=")))


## --egg=<id>: before the city is built, the egg's moment (time of day, clock and date, dry
## weather, the station; the roadworks' street) and the start near its place.
func _egg_moment() -> void:
	if egg_flag == "" and tape_flag == "" and kadr_flag == "":
		return
	# Each moment's flag brings its log (the runs read these lines).
	egg_log = egg_log or egg_flag != ""
	tape_log = tape_log or tape_flag != ""
	photo_log = photo_log or kadr_flag != ""
	var pid := ""
	if egg_flag != "":
		var book := EggBook.new()
		if book.load_eggs() and book.by_id.has(egg_flag):
			m._egg = book.eggs[book.by_id[egg_flag]]
		book.free()
		if m._egg.is_empty():
			push_warning("--egg=%s: no such egg in eggs.json" % egg_flag)
			return
		pid = str(m._egg["place"])
		var t: Dictionary = m._egg["trigger"]
		if bool(t.get("night", false)) or t.has("after"):
			start_time = TimeOfDay.NIGHT
		if str(t.get("look", "")) == "Dusk":
			start_time = TimeOfDay.DUSK
		if t.has("hours") and not (t.has("weekday") or t.has("date")):
			var h: Array = t["hours"]
			var a := float(h[0])
			var b := float(h[1])
			var inside := func(x: float) -> bool: return (x >= a and x < b) if a <= b else (x >= a or x < b)
			if inside.call(19.5):
				start_time = TimeOfDay.DUSK
			elif inside.call(1.5):
				start_time = TimeOfDay.NIGHT
			elif inside.call(14.0):
				start_time = TimeOfDay.DAY
		if t.has("weekday") or t.has("date"):
			start_time = TimeOfDay.LIVE
			var hours: Array = t.get("hours", [12, 13])
			live_clock = "%02d:15" % int(hours[0])
			# The week of Monday 26 October 2026, or of Monday 28 June 2027 for a summer egg (Live's
			# summer is June-August); Fat Thursday by the computus. At dusk: the sun on the horizon.
			var summer := bool(t.get("summer", false))
			var monday := 20270628 if summer else 20261026
			live_date = monday + int((t.get("weekday", [4]) as Array)[0]) - 1
			if not summer and live_date > 20261031:
				live_date = 20261101
			elif summer and live_date > 20270630:
				live_date = 20270701 + live_date - 20270631
			if str(t.get("look", "")) == "Dusk":
				live_clock = "21:00" if summer else "16:25"
			if str(t.get("date", "")) == "fat_thursday":
				live_date = EggBook.fat_thursday(2027)
		if bool(t.get("dry", false)):
			start_weather = 0
		if t.has("station"):
			station_flag = str(t["station"])
			radio_picked = true
		if t.has("roadworks"):
			barrier_force = str(t["roadworks"])
		if t.has("paint") and paint_flag == "":
			paint_flag = str(t["paint"])  # the garage loop: E01 black, E21 green
		if str(t.get("kind", "")) == "tape":
			tape_flag = str(t["card"])
		print("egg: --egg=%s %s: %s; the moment: %s%s%s" % [egg_flag, m._egg["name"][0], t,
				TimeOfDay.NAMES[start_time], " %s %d" % [live_clock, live_date] if live_clock != "" else "",
				", station %s" % station_flag if station_flag != "" else ""])
	if tape_flag != "" and pid == "":
		var tp := Tape.new()
		if tp.load_cards() and tp.index_of(tape_flag) >= 0:
			pid = str(tp.spots[tp.index_of(tape_flag)]["place"])
		tp.free()
	if kadr_flag != "" and pid == "":
		var f := Fotka.new()
		if f.load_spots():
			var i := m._kadr_index(f, kadr_flag)
			if i >= 0:
				pid = str(f.spots[i]["place"])
				var want := str(f.spots[i].get("look", ""))
				if want != "":
					start_time = TimeOfDay.parse(want.to_lower())
		f.free()
	# The sectors round the place first (its hint; eggs.gd's spots come once the city is up).
	var nb := Notebook.new()
	if nb.load_places() and nb.by_id.has(pid):
		var near: Array = nb.places[nb.by_id[pid]]["near"]
		var at := Notebook.project([52.234, 21.024], float(near[0]), float(near[1]))
		m.start_at = Vector3(at.x, 0.0, at.y)
	nb.free()


## True when a game flag begins with `prefix` (--cam leaves the car's place to --at when it is given).
func _has_arg(prefix: String) -> bool:
	for a in Main.game_args():
		if a.begins_with(prefix):
			return true
	return false
