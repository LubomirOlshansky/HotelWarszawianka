extends Node
## Sets up the pixel-art view, the daytime world, the city, the car and the
## helicopter, the isometric follow camera, the controls and the rescue missions.
##
## Command-line options (after `--`): --demo drives the car (or circles the
## helicopter) by itself, --shots=60,240 saves screenshots at those frames and
## quits, --out=DIR sets where they go (made if missing), --spots=NAME:X,Z[,HEADING];...
## shoots each spot in one run (files NAME_FFFF.png), --style=N picks a style, --yaw=N rotates
## the camera, --heli starts in the helicopter, --mission=N starts rescue call N
## at once, --autopilot flies or drives to the mission targets (for testing; the
## car ghosts through buildings) or drives the race route, --no-traffic leaves the
## city empty, --race=N races rival N at once, --rival=N puts rival N just ahead,
## --bench drives through the traffic and prints the average frame time,
## --time=day|dusk|night sets the time of day, --vhs turns the tape overlay on,
## --radio=0..4 picks the station (0 = off; loop MW-5: --station=polnoc by name), --notitle skips the title screen and
## --title shows it even with the testing flags. Side jobs and easter eggs (v0.65):
## --kebab=N starts kebab order N, --sloik[=K] the słoiki run (K jars already
## broken), --heat=X the kebab's starting heat, --host-in=S the radio host's first
## line after S seconds, --barriers=YYYYMMDD the day the roadworks are placed for,
## --reset-save wipes the wallet, --nosave neither reads nor writes it (save and resume:
## --title-choice=continue|new|ask, --resume=x,z[,heading]), --free
## starts in free roam (no rescue call card). v0.8: --tap=X,Y taps that screen pixel
## at frame 60 (a landmark's info card). v0.9: --weather=clear|rain, --time=live with
## --clock=HH:MM and --date=YYYYMMDD (Warsaw time), --perf shows the performance
## overlay, --quality=low|medium|high. Loop 1: --ghost-debug=1|2 paints or fully cuts the
## occlusion ghost (and prints its ellipse with each screenshot), --lift=M aims the camera
## M metres above the vehicle. Loop 2a: --controls=point|classic|fixed, --traffic=empty|low|
## normal|busy (or 0-3), --settings opens the settings panel, --stick=X,Y holds the stick at
## that deflection and --pedal=gas|brake a pedal (screenshots, replays in the real city),
## --clicks=X:Y:F,... clicks and --drag=X:Y:F:DX:DY:F2 drags a finger through the real input path.
## Loop 10a: --drive-into-water=X,Z starts the car there and drives it flat out into the nearest
## water as if it had jumped the edge (the splash and the tow, printed as `water:` lines).
## The driving-feel loop: --ram-test drives the car into the back of a traffic car and logs the
## hit, the shove and how soon it gets past (`ram test:` lines).
## Loop 2e: --call-in=S brings the first rescue call after S seconds of play, --settings-tab=N
## opens the settings panel at tab N.
## Camera loop: --cam-log prints the camera every 0.25 s (`cam:` lines), --cam-test=classic_turn|
## point_release|brake drives one camera moment in the real city (frame strips).
## Loop G1: --quality=auto|low|medium|high|ultra (Auto: the level for this device, tiers.gd),
## --model=ID picks as if on that device (iPhone12,1), --governor=on|off, --stress=cpu:N|wait:N
## with --stress-from=S --stress-to=S (load that makes the governor step down and back up).
## Loop G1b: --last-session=struggled|calm starts Auto as if the last session at the sharp image
## struggled (the ×2 fallback) or was calm (the sharp image), and writes nothing of it.

const Lang := preload("res://scripts/lang.gd")  # one language at a time (2026-11-02)
const EdgeRoadworks := preload("res://scripts/edge_roadworks.gd")  # rebuilt on a language change
const Release := preload("res://scripts/release.gd")  # DEMO 3j: no flags in a release build
const Access := preload("res://scripts/access.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const Car := preload("res://scripts/car.gd")
const TunnelXray := preload("res://scripts/tunnel_xray.gd")
const PedZones := preload("res://scripts/ped_zones.gd")
const ScooterZones := preload("res://scripts/scooter_zones.gd")
const LaneAssist := preload("res://scripts/lane_assist.gd")
const Heli := preload("res://scripts/heli.gd")
const Hud := preload("res://scripts/hud.gd")
const Missions := preload("res://scripts/missions.gd")
const Skids := preload("res://scripts/skids.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Trams := preload("res://scripts/trams.gd")
const Trains := preload("res://scripts/trains.gd")
const Pedestrians := preload("res://scripts/pedestrians.gd")
const Rivals := preload("res://scripts/rivals.gd")
const Bubbles := preload("res://scripts/bubbles.gd")
const Chatter := preload("res://scripts/chatter.gd")
const Models := preload("res://scripts/models.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const Radio := preload("res://scripts/radio.gd")
const OpeningAudio := preload("res://scripts/opening_audio.gd")
const GreetingClips := preload("res://scripts/greeting_clips.gd")
const Title := preload("res://scripts/title.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
const Jobs := preload("res://scripts/jobs.gd")
## Loop 2d-1: Podwózka, the app-taxi side job.
const Rides := preload("res://scripts/rides.gd")
const Lines := preload("res://scripts/quest_lines.gd")
const Eggs := preload("res://scripts/eggs.gd")
## Loop MW-1: MOJA WARSZAWA, the city notebook.
const Notebook := preload("res://scripts/notebook.gd")
## Loop MW-6: the eggs as notebook cards, KASETA, Spacer and Fotka.
const EggBook := preload("res://scripts/egg_book.gd")
const Tape := preload("res://scripts/tape.gd")
const Spacer := preload("res://scripts/spacer.gd")
const Fotka := preload("res://scripts/fotka.gd")
## Loop 3h slice 1: the demo's districts (discovery, "?" marks, completion).
const Districts := preload("res://scripts/districts.gd")
## Loop 3h slice 2: the 20 Syrenki (collectibles).
const Syrenki := preload("res://scripts/syrenki.gd")
const Cassettes := preload("res://scripts/cassettes.gd")
## First scene items 4-5: the kiosk, stall, cafés and planters by the start (first_scene.gd).
const FirstScene := preload("res://scripts/first_scene.gd")
## Skwer Linearny na Złotej (2026-11-02): the park's stone blocks, benches, cafés (skwer_zlota.gd).
const SkwerZlota := preload("res://scripts/skwer_zlota.gd")
## The 3D corner screen on Skylight at Złote Tarasy (2026-11-05, tarasy_screen.gd).
const TarasyScreen := preload("res://scripts/tarasy_screen.gd")
## The Warsaw Spire's LED ticker and plaza jets (2026-11-06, spire_motion.gd).
const SpireMotion := preload("res://scripts/spire_motion.gd")
## Street details along the main line (street_details.gd, tools/bake_street_details.py).
const StreetDetails := preload("res://scripts/street_details.gd")
## The Ratusz Arsenał interchange's canopies, tower and railings (ratusz_hub.gd).
const RatuszHub := preload("res://scripts/ratusz_hub.gd")
## Park details: statues, a carousel, ducks, people on the benches (park_details.gd, tools/bake_park_details.py).
const ParkDetails := preload("res://scripts/park_details.gd")
## Loop 3h slice 3: the final race's route (the start's hint for --trzy-mosty).
const TrzyMosty := preload("res://scripts/trzy_mosty.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Sfx := preload("res://scripts/sfx.gd")
## Loop MW-5: the city's sounds at the notebook's places.
const CitySounds := preload("res://scripts/city_sounds.gd")
## Loop MW-3: the night and the river's crowds.
const Crowds := preload("res://scripts/crowds.gd")
## Loop MW-4: everyday life and trends, and the "Na czasie" job.
const CityLife := preload("res://scripts/city_life.gd")
## Loop MW-2: storefronts and parodies (Frogs, the venues' neon, Leżak, the metro entrances).
const Storefronts := preload("res://scripts/storefronts.gd")
const TrendJob := preload("res://scripts/trend_job.gd")
const CoffeeRun := preload("res://scripts/coffee_run.gd")
const RoundupJob := preload("res://scripts/roundup_job.gd")
const Weather := preload("res://scripts/weather.gd")
const Controls := preload("res://scripts/drive_controls.gd")
const Gamepad := preload("res://scripts/gamepad.gd")  # the gamepad loop
const FollowCamera := preload("res://scripts/follow_camera.gd")
const CameraShots := preload("res://scripts/camera_shots.gd")
const Settings := preload("res://scripts/settings.gd")
const BenchStats := preload("res://scripts/bench.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")
const Splash := preload("res://scripts/splash.gd")
const CrashFx := preload("res://scripts/crash_fx.gd")
const MoneyPop := preload("res://scripts/money_pop.gd")
const Haptics := preload("res://scripts/haptics.gd")
const Tiers := preload("res://scripts/tiers.gd")
const Governor := preload("res://scripts/governor.gd")
## Loop 3g-1: the police (police.gd; its block below, "loop 3g-1: the police").
const Police := preload("res://scripts/police.gd")
const Buses := preload("res://scripts/buses.gd")
const OldTram := preload("res://scripts/old_tram.gd")
const CrashScenes := preload("res://scripts/crash_scenes.gd")
## Sekretny rave (rave.gd, F's ask 2026-11-06): LEKTI on MORDOR FM, Ziomek's call, the raves' rigs.
const Rave := preload("res://scripts/rave.gd")
## Nocny spot (street_meet.gd, F's ask 2026-11-06): the WARSAW NIGHT RACING CLUB's meets, raids and drag.
const StreetMeet := preload("res://scripts/street_meet.gd")
## "Wiślana Szprotka", the boat race down the Vistula (boat_race.gd, F's ask 2026-11-06).
const BoatRace := preload("res://scripts/boat_race.gd")
## "Kino objazdowe", the director friend's cinema tour (kino_tour.gd, F's ask 2026-11-07).
const KinoTour := preload("res://scripts/kino_tour.gd")
## Wątki (story_quests.gd, F's ask 2026-11-07): the questlines' starts on the map, the friend in
## person at the start, the beta list; quest focus (the map goes quiet while a quest runs).
const StoryQuests := preload("res://scripts/story_quests.gd")
## Inside the club after the door (club.gd): the cutaway room.
const Club := preload("res://scripts/club.gd")
const EvTow := preload("res://scripts/ev_tow.gd")
## Packs (docs/design/packs.md): running clubs, cycling packs and coffee raves.
const Packs := preload("res://scripts/packs.gd")
## Kibice (docs/design/city-life-satire.md 7): friendly fans by Stadion Leguminy on match evenings.
const Fans := preload("res://scripts/fans.gd")
const LoudCars := preload("res://scripts/loud_cars.gd")
const CrazyDrivers := preload("res://scripts/crazy_drivers.gd")
## Wellness circles (docs/design/city-life-satire.md): sound healing, techno yoga, the 40+ club, park kung-fu.
const Wellness := preload("res://scripts/wellness.gd")
## The garage loop: Warsztat u Mirka and its paint jobs (garage.gd, its card garage_card.gd).
const Garage := preload("res://scripts/garage.gd")
## Loop 3h slice 4: the guided first 10 minutes and the end card.
const First10 := preload("res://scripts/first10.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")
const MainLine := preload("res://scripts/main_line.gd")
const MainNudge := preload("res://scripts/main_nudge.gd")
const MAP_PATH := "res://map/centrum.json"

## Visual styles to compare on the phone. lines = vertical resolution of the pixel image.
const STYLES := [
	{"name": "Sharp", "lines": 480, "outline": 0.5, "levels": 0.0, "saturation": 1.15},
	{"name": "Fine", "lines": 360, "outline": 0.55, "levels": 0.0, "saturation": 1.12},
	{"name": "Clean", "lines": 240, "outline": 0.6, "levels": 0.0, "saturation": 1.1},
	{"name": "Chunky", "lines": 170, "outline": 0.8, "levels": 9.0, "saturation": 1.2},
]
## The camera's tilt in degrees (minus the angle over the ground): Settings → Obraz "Kąt kamery"
## (settings.gd pitch, follow_camera.gd PITCHES) or --pitch=.
var camera_pitch := -FollowCamera.DEFAULT_PITCH
const CAMERA_DISTANCE := 500.0
## Height of the view in metres (orthographic size): wide enough to read the city.
var base_size := FollowCamera.DEFAULT_SIZE
## The follow-camera loop: --size= was given (the saved zoom doesn't apply), and the pinch's span
## ratio since its last zoom step.
var _flag_size := false
## --pitch= was given: the saved camera angle (Settings → Obraz) doesn't override it.
var _flag_pitch := false
var _pinch_run := 1.0
## The helicopter's view is this much wider than the car's (as before loop 2a: 1.3 × 110 m).
const HELI_VIEW := 1.3 * 110.0 / FollowCamera.DEFAULT_SIZE

var view: SubViewportContainer
var sv: SubViewport
var cam: Camera3D
var car: CharacterBody3D
## Loop 3d-1: the pedestrian zones (ped_zones.gd), where the car is capped at 20 km/h.
var ped_zones: RefCounted
## The 12 km/h e-scooter streets (scooter_zones.gd): a toast on entering one.
var scooter_zones := ScooterZones.new()
var _scooter_zone := ""
var _scooter_toast_at := -999.0
var _zone := ""
## F's asks (2026-10-30): whether the zones cap the car at all (Settings → JAZDA, off by default:
## settings.gd `zone_cap`), and --zone-cap / --no-zone-cap for one run (-1: the setting).
var zone_cap_on := false
var zone_cap_flag := -1
## Loop 3b: the car seen through the ground inside a tunnel (tunnel_xray.gd).
var _xray: Node3D
## GAMEPLAY_PLAN 0.3: a deck hides the car from the camera (map_builder.gd `deck_hides`, ~0.1 ms
## under a deck in the cloud check, 1 µs elsewhere), asked every DECK_XRAY_EVERY frames (the
## silhouette a few frames late).
const DECK_XRAY_EVERY := 4
var _deck_hid := false
var heli: Node3D
var missions: Node
var hud: CanvasLayer
## The living city (absent with --no-traffic): lane graph, traffic, trams,
## pedestrians, rivals and their speech bubbles.
var graph: LaneGraph
var traffic: Traffic
var trams: Trams
## The railway (docs/design/railway.md T1): trains on the cross-city line and the ring line.
var trains: Trains
## --train=X,Z: a train put on the track nearest that point at the start (shots).
var train_at := Vector2.INF
## --train=X,Z,K: that train of kind K (trains.gd KINDS: 0 Koleje Mazowe, 1 SKiM, 2 the
## long-distance one).
var train_kind := -1
var walkers: Pedestrians
var rivals: Rivals
## Loop 3g-1: the police (null with --no-police or no traffic) and their flags.
var police: Police
var police_opts := {}
var bubbles: Bubbles
var no_traffic := false
var start_race := 0
var start_rival := 0
## --bench: drive a ghost route through the traffic, then print frame times.
var bench := false
var _bench_ghost = null
## Loop 2b: the bench's numbers (bench.gd), frames to settle and to measure (--bench-frames=),
## --probe (stand still where --at puts the car and measure the view there), --exp=a,b
## (switch single costs off to rank them), and main.gd's own share of the frame.
var _stats: BenchStats
var _bench_settle := 300
var _bench_frames := 600
var probe := false
var _exp: PackedStringArray = []
var _main_usec := 0
## Loop 2b: the measured part of a bench or probe ends after this many seconds even if the
## frames aren't done (a slow phone), and settling after SETTLE_SECONDS; --fps=N caps the frame
## rate for this run (0: uncapped; else the setting's 60 or 30).
var _bench_seconds := 30.0
const SETTLE_SECONDS := 8.0
var _bench_t0 := 0
var _measure_t0 := 0
var _flag_fps := -1
## The frame-rate cap in force (0: none).
var _cap := 60
## The result is out (on iOS the app doesn't stop at once after quit()).
var _bench_done := false
## Loop 2b: the BENCH button's run (the overlay or Settings): about a minute on the bench route
## at the current settings, then the result card. What it changes is put back afterwards.
const PHONE_SETTLE := 5.0
const PHONE_SECONDS := 55.0
var _phone_bench := false
var _phone_seconds := PHONE_SECONDS
## --bench-button: press BENCH at frame 60 (testing aid; the same run as the button's).
var bench_button := false
var _phone_saved := {}
var _phone_next_toast := 0
var _spawn := Transform3D.IDENTITY
## The overlay's text is rebuilt twice a second.
const PERF_EVERY := 0.5
## In the helicopter; the car waits, parked, where it was left.
var flying := false
var start_flying := false
## Loop 3d-2b, --heli-alt=M: the height over the ground the helicopter starts at (0: the usual take-off).
var _start_alt := 0.0
var start_mission := 0
var autopilot := false
## Street races (2026-11-04): --ghost-pace=X, the autopilot's speed factor in a race (rivals.gd
## `ghost_pace`, default 1.8: an average player; 2.4 a quick one; "racer" (99): a skilled player who
## uses the whole car on the roads, traffic.gd's racer mode at the car's top), for the race-AI runs.
var ghost_pace := 0.0
## --race-debug: traffic.gd prints what holds a racer that stands still (once a second).
var race_debug := false
var _wash_on := false
var building_mat: ShaderMaterial
var post_mat: ShaderMaterial
var map: Node3D

var style_index := 0
var cam_yaw := 45.0
## --no-ghost (2026-10-31, the landing's screenshots): no occlusion ghost and no see-through hole
## round the car, so a
## wide framed shot centred on a spot behind a building keeps that building whole.
var no_ghost := false
var cam_yaw_target := 45.0
## --yaw= was given (the follow camera then doesn't start behind the vehicle).
var _flag_yaw := false
## Camera loop: the follow camera's laws (follow_camera.gd: the turn, the look-ahead, the dead
## zone, the speed zoom), its view height (cam.size is the host's during a cinematic moment), and
## the cinematic moments on Phantom Camera (camera_shots.gd): the fly-in when the title screen
## goes and a look at a new rescue or delivery target, on in a normal launch, off in test runs
## (show_title false: --notitle and every testing flag), forced on by --cinematic[=flyin|look].
var fcam := FollowCamera.new()
var _view_size := FollowCamera.DEFAULT_SIZE
var moments: CameraShots
var cinematic_flyin := false
var cinematic_look := false
var _flag_cinematic := ""
var _last_target_source := ""
var _last_target := Vector3.INF
## Follow: the camera turns to stay behind the car. Fixed: it turns only with the rotate buttons.
var follow := true
var cam_focus := Vector3.ZERO
var demo := false
## The L-shaped map loop (2026-10-31), --heli-stick=X,Z: the helicopter's stick held towards that
## world direction (x east, z south) the whole run, for screenshots of the clamp along the map's
## outline (ZERO: off).
var heli_stick := Vector2.ZERO
var shots: Array[int] = []
## The shots saved so far: the frames of `shots` that reached their PNG (a run that ends
## without one says so in _exit_tree).
var _shots_saved: Array[int] = []
var out_dir := "user://"
## --spots: [name, Vector2 x/z, heading or INF] per camera; one run shoots them all, the city
## built once (a street pass needs 6-10 cameras; a launch per camera cost ~70 s each).
var shot_spots: Array = []
var _spot_i := 0
var frame := 0
var start_at := Vector3.INF
## --heading=deg: the car's heading at the start (0 = north, 90 = east), for testing.
var start_heading := INF
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
## Loop 3b: --tunnel starts the car (with --at) on the floor of a tunnel under that point.
var start_in_tunnel := false
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
## The ghosted footprint's sunlight: given back in full above GHOST_SUN_HIGH degrees of
## sun, none below GHOST_SUN_LOW; GHOST_SUN_SCALE matches it to the renderer's sun
## (measured: with 1.8 a ghosted footprint behind the Palace read 154.7 against 159.3 for
## the same pixels with no shadows at all, 93.9 with nothing given back).
const GHOST_SUN_LOW := 15.0
const GHOST_SUN_HIGH := 40.0
const GHOST_SUN_SCALE := 1.9
var _ghost_px := Vector4.ZERO
var no_ao := false
## Load the prebuilt sectors like the exported game does (loop 3c: map/sectors/*.scn, index.res,
## proxies.scn; only rebuilt by tools/bake_city.gd), not build them from their files.
var prebuilt := false
## --no-map-edge: without the land past the map's edge (map_edge.gd), for a before/after probe.
var _flag_no_map_edge := false
## --no-edge-roadworks: without the roadworks closing the roads at the map's edge (edge_roadworks.gd;
## their colliders go too, the edge wall stays), for a before/after probe.
var _flag_no_edge_roadworks := false
var _started := false
## Time of day (N / TIME / --time=), the radio (R / RADIO / --radio=), the VHS
## overlay (V / VHS / --vhs) and the title screen (skipped by the testing flags).
var tod: TimeOfDay
var radio: Radio
var title: Title
var start_time := 0
var start_station := 0
var vhs := false
var _vhs_mat: ShaderMaterial
var show_title := true
var force_title := false
var env: Environment
var sun: DirectionalLight3D
var _blip: AudioStreamPlayer
## v0.65: the wallet (and save), everybody's lines, the side jobs, the easter eggs.
var wallet: Wallet
var dialogue: Dialogue
var jobs: Jobs
var eggs: Eggs
## Loop MW-1: the notebook and its flags: --notebook[=chapter|place id] (open it; "" none),
## --found=, --place=<id> (the car at the place), --notes-log.
var notes: Notebook
var notebook_open := ""
var found_spec := ""
var place_flag := ""
var notes_log := false
## Loop MW-6: the egg cards (egg_book.gd), KASETA (tape.gd), Spacer (spacer.gd), Fotka (fotka.gd),
## and their flags: --egg=<id> (the vehicle at the egg, in its time, weather and day; a motion
## trigger driven by the rig, _egg_rig), --egg-log, --found-eggs=, --tape=<id|n> (the car at the
## then card, the tape played), --tape-log, --spacer (or --wander), --spacer-hint=S (the first
## hint after S s), --fotka (Fotka open at the start), --kadr=<n|id> (Fotka aimed at a Kadr spot,
## a photo after 2 s), --fotka-shot=S (a photo S s after --fotka opens), --photo-log.
var egg_book: EggBook
## Loop 3h slice 1: the districts (districts.gd) and their flags: --district=<id> (that district's
## "discovered" card at the first check), --districts=all|none|<id>[:jobs],... (the record, in
## memory), --districts-log.
var districts: Districts
var district_card := ""
## --pop=<zl>: pays that much two seconds into the run, to see the money pop (money_pop.gd).
var pop_flag := 0
var districts_spec := ""
var districts_log := false
## Loop 3h slice 2: the Syrenki (syrenki.gd) and their flags: --syrenki-log (placements and finds),
## --syrenki=all|none|<n>|<id>,... (the record, in memory), --syrenka=<id|n>[:m] (the car on the street
## next to that Syrenka, facing it, m metres before it: 25 by default; :0 finds it at once).
var syrenki: Syrenki
## The first-10 polish: the mixtapes on roofs (cassettes.gd).
var cassettes: Cassettes
var syrenki_log := false
var syrenki_spec := ""
var syrenka_flag := ""
## Loop 3h slice 3: the rival ladder and the final "Trzy mosty" (rivals.gd, ladder.gd,
## trzy_mosty.gd): --ladder=N (the first N rungs beaten for this run, respect raised to fit; -1: the
## save's) and --trzy-mosty (the car at Rondo Daszyńskiego at night, the final at once).
var ladder_flag := -1
var trzy_mosty_flag := false
var trzy_mosty_bridge := 0
## Loop 3h slice 4 (first10.gd): the guide on a fresh save in a normal launch; --first10 runs it in
## a test run too and scripts its triggers (with --autopilot: the headless replay); --end-card
## shows the end card at once (screenshots); --first-race has Halina roll up for the first race a
## second in.
var first10: First10
var first10_flag := false
var end_card_flag := false
var first_race_flag := false
var tape: Tape
var spacer: Spacer
var fotka: Fotka
## Where the car stood when Fotka opened (Transform3D.IDENTITY: not open): put back on close, so
## nothing that happened while the camera was away (a push from traffic) leaves it elsewhere.
var _fotka_car := Transform3D.IDENTITY
var egg_flag := ""
var egg_log := false
var found_eggs := ""
var tape_flag := ""
var tape_log := false
var spacer_flag := -1
var spacer_hint := -1.0
var fotka_flag := false
var kadr_flag := ""
var fotka_shot := -1.0
var photo_log := false
var _egg: Dictionary = {}
var _rig_t := 0.0
var _rig_path := PackedVector2Array()
var _rig_s := 0.0
var _moment_at := -1.0
var _vhs_until := -1.0
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
var city_sounds: CitySounds
## Loop MW-3: the crowds (crowds.gd) and their flags: --crowd=0|1|2 (none, normal, double; the
## Low tier halves them), --night-log (queues, rejections, the dawn walkers each minute, every
## event), --club=<id|name> (the car at that club's door).
var crowds: Crowds
var crowd_flag := 1
var night_log := false
var club_flag := ""
## Live's sunset hour by date (yyyymmdd -> hour), for the steps crowd.
var _sunsets := {}
## Loop MW-4: everyday life (city_life.gd) and the "Na czasie" job (trend_job.gd), and their flags:
## --life=0|1|2 (none, normal, double; the Low tier halves it), --dogs-log, --trend-log,
## --life-log, --life-soak (the car driven at the dogs and riders, overlaps counted), --zajac
## (Live, Wednesday 28 October 2026 at 18:59, the car by Kolka's start; with --autopilot it paces
## the club), --trend-day=N (the trend cycle's day number), --trend-job[=slot, 5 padel court, 6 van, 7 the DeSki call, 8 Mrożulo's Dżemini call, 9 Zuzia's coffee run with the car by its ROWERILO dock] (the request at a
## Wiralek slot, 1-3).
var life: CityLife
var trend_job: TrendJob
## The night-buses loop (buses.gd): the N sign, the night hub at Centralny, the bus stops' people,
## the player's horn, E23-E25; flags --night-hub (a gathering now, parked at once), --bus-log,
## --honk=F1,F2 (the horn at those frames).
var buses: Buses
var night_hub_flag := false
var bus_log := false
var honk_frames: Array[int] = []
## The vintage-tram loop (old_tram.gd): the old two-car set on summer weekends, E39; flags
## --old-tram (the set now near the car; =follow: and the car kept behind it), --tram-log.
var old_tram: OldTram
## Crash scenes (crash_scenes.gd, 2026-11-01): a fender bender with a police car and an ambulance
## now and then on a road ahead; in a normal launch only (test runs repeat). Flags --crash=now (a
## scene 45-80 m ahead at the start, for shots), --crash=X,Z (one on the fitting road nearest that
## point), --crash=on (the timer in a test run too), --crash=0 (none), --crash-log.
var crash_scenes: CrashScenes
var crash_flag := ""
var crash_log := false
## Dead electric cars (ev_tow.gd, F's ask 2026-11-06): Bartek's call to carry his TESŁO to a charger
## under the helicopter, and stranded ones in the kerb lane. Flags --ev-call (the call rings now),
## --ev-tow (accepted, the helicopter over his car), --ev-tow=carry (his car already on the rope),
## --ev-stranded (one about 30 m ahead now), --ev=0 (none), --ev-log.
var ev_tow: EvTow
var ev_flag := ""
var ev_log := false
var _ev_auto := false
var _crash_auto := false
## Sekretny rave (rave.gd): flags --rave-call (LEKTI and Ziomek's call now), --rave-smola (Ziomek's
## Smoła night now), --rave=on / --rave=day (that rave on at any hour), --rave-spot=ID, --rave=0,
## --rave-log.
var rave: Rave
## Nocny spot (street_meet.gd): flags --meet-call (Darek rings now), --meet=on (night rules at any
## hour), --meet=0, --meet-at=meet|raid|race|meet2|drag|stage (jump to that beat), --meet-log.
var meet: StreetMeet
var meet_flag := ""
var meet_at := ""
var meet_log := false
var _meet_auto := false
## The ground's material (the skids' and the meet's tyre marks).
var _ground_mat: Material
var club: Club
var rave_flag := ""
var rave_spot := ""
var rave_log := false
var _rave_auto := false
## The boat race (boat_race.gd): --boat-race=call (Szymek phones now), =race (the car at the
## pontoon, straight onto the grid), =auto (that, with the player's boat driven by the rivals'
## driver), =free / free0..2 (the car at the pontoon, out in a free-ride boat: 0 the jet ski,
## 1 the electric (default), 2 the offshore), =marina (the car there, the
## marina card up), =0 (none); --boat-log.
var boat_race: BoatRace
## The questlines (story_quests.gd); --stories-log prints what they do.
var stories: StoryQuests
var stories_log := false
## --story=ID: that questline starts from the beta list 1.5 s into the drive (its friend phones).
var story_flag := ""
## --story-meet: the friend's WCHODZĘ pressed by itself a second after they walk up.
var story_meet_flag := false
## --quest-tab=N: the full map's ZADANIA card opens on tab N (0 AUTO, 1 HELI, 2 WĄTKI; shots).
var quest_tab_flag := -1
var _story_t := 0.0
var _story_key := ""
var boat_flag := ""
var boat_log := false
var _boat_mask := Vector2i.ZERO
var _boat_paused := false
## The cinema tour (kino_tour.gd): --kino-tour=call (Wiktor phones now), =go (the tour starts with
## the car at the pickup), =auto (that, the cards answered by themselves), =0 (none); --kino-log.
var kino_tour: KinoTour
var kino_flag := ""
var kino_log := false
var old_tram_flag := ""
var tram_log := false
## Packs (packs.gd): running clubs, cycling packs, coffee raves; flags --packs=0 (none), --packs-now
## (every club and rave on whatever the clock, the packs near the car timed to pass it), --packs-log.
var packs: Packs
## City-life satire #1 (loud_cars.gd): the car meet at Browary and the loud supercars in traffic.
## --loud=N: at most N loud cars at once (default 3; 0: none, and no meet); --loud-log prints
## their revs and lines.
var loud_cars: LoudCars
var loud_flag := 3
var loud_log := false
## Crazy drivers (crazy_drivers.gd, traffic.gd CRAZY_*): Szkoda Oktawia taxis, Szprynter couriers
## and the Pasatini in traffic. --crazy=N: at most N at once (default 3; 0: none); --crazy-log
## prints their cut-ins and KEBAB FM's sightings.
var crazy_drivers: CrazyDrivers
var crazy_flag := 3
var crazy_log := false
var packs_flag := 1
var packs_now := false
var packs_log := false
## Kibice (fans.gd): the fans by Stadion Leguminy; flags --fans=0 (none), --fans-now (out whatever the
## clock), --fans-log, --fans-phase= and --fans-result= (the match day's walkers).
var fans: Fans
var fans_flag := 1
var fans_now := false
var fans_log := false
## --fans-phase=arrive|match|leave and --fans-result=win|draw: the match day's walkers for shots.
var fans_phase := ""
var fans_result := ""
## Wellness circles (wellness.gd); flags --wellness=0 (none), --wellness-now (every spot on at any hour), --wellness-log.
var wellness: Wellness
var wellness_flag := 1
var wellness_now := false
var wellness_log := false
## The garage loop (garage.gd): Warsztat u Mirka on Brzeska; flags --paint=<id> (the car starts in
## that paint, owned for the run), --garage (the car in the garage's ring, the card open; the
## garage shown whatever the wallet), --garage-log (`garage:` lines).
var garage: Garage
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
var zajac_flag := false
var trend_day_flag := -1
var trend_job_flag := 0
## --dzemini: Mrożulo's MLASK already on DŻEMINI KEBAB (the queue for good, the sticker), the car by
## the shop (trend_job.gd "Dżemini"; shots without driving the job).
var dzemini_flag := false
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
# --- loop 2d-1: Podwózka (rides.gd) and its testing flags ---
var rides: Rides
## G12 part 2: the quest pin, a place picked on the full map's ZADANIA card (quest_lines.gd entry;
## {} none): the arrow and minimap dot point at it while nothing else is on, until it is reached.
var quest_pin: Dictionary = {}
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
# --- end loop 2d-1 ---
## Loop MW-2: the storefronts (storefronts.gd) and their flags: --no-parodies (none of MW-2's
## shops, signs, scooters or entrances, for an A/B), --rechotka (the car by the nearest Frogs
## door, stopped: a stamp), --stamps=K (the card starts at K: the 10th stamp's free hot dog).
var storefronts: Storefronts
var no_parodies := false
var rechotka_flag := false
var stamps_flag := -1
var host_in := -1.0
var barrier_day := 0
var reset_save := false
var no_save := false
## --free: free roam (loop 2e: no call card at the start anyway; the first call then comes in
## 90 s into play instead of 60).
var free_roam := false
## Loop 2e: the first rescue call comes in after this many seconds of play (--call-in=S;
## missions.gd FIRST_CALL by default); --style= and --vhs win over the saved settings.
var call_in := -1.0
## Loop 2e: --settings-tab=N opens the settings panel at that tab (0 Driving, 1 World, 2 Picture,
## 3 Sound) for screenshots.
var settings_tab := 0
var _flag_style := -1
var _flag_vhs := false
## --tap=X,Y: tap that screen pixel at frame 60, as if a finger did (landmark cards).
var tap_at := Vector2.INF
## v0.9: sound, weather (RAIN / O / --weather=), the Live clock (--clock= --date=), the
## performance overlay (--perf, P, a three-finger tap) and the quality (--quality=, U,
## the QUALITY button on the overlay).
var sfx: Sfx
var weather: Weather
var start_weather := 0
var live_clock := ""
var live_date := 0
var show_perf := false
## Low, Medium, High, Ultra (loop G1: tiers.gd QUALITY): the pixel size (loop 2b: "step" whole
## screen pixels coarser than High's; the old 0.85 / 0.7 render scales gave Medium High's image
## on a 1170-line phone and Low's on a 1320-line one; G1: and a budget in megapixels), shadows,
## glow, rain, reflection steps, traffic and pedestrians. Loop 2b: the sun's shadow map is 2048
## on High and 1024 on Medium (4096 / 2048 before): the shadow now covers only the view (see
## _camera_far), so 2048 gives finer texels than 4096 did (0.37 m against 0.49). Medium casts
## sun shadows from buildings and trees only (lamps, signals, parked cars, columns and shelters,
## map_builder.gd SMALL_CASTERS, don't), Low none.
const QUALITY := Tiers.QUALITY
## The level in force (Tiers.LOW..ULTRA); loop G1: the player's choice (Tiers.AUTO, the default,
## or a level), the level Auto picks for this device and the model id it read (--model= for tests).
var quality := Tiers.HIGH
var quality_choice := Tiers.AUTO
var auto_quality := Tiers.HIGH
var model_name := ""
var _flag_model := ""
# --- Loop G1b: Auto's sharp image and its fallback (tiers.gd SHARP_*, governor.gd tally) ---
## The back-off state as this launch started it (Tiers.sharp_launch of the saved one), whether
## this launch draws the sharp image where the budget binds, what this session has recorded
## ("", "calm", "struggled": once each, struggled last), whether it may write it (not with
## --last-session=, and settings.gd writes nothing with --nosave), and the quality line last
## printed (the `quality:` line comes again only when it changes).
var auto_image := Tiers.sharp_state()
var auto_sharp := true
var _image_verdict := ""
var _image_write := true
var _flag_last_session := ""
var _quality_line := ""
# --- end loop G1b ---
## Loop G1: the frame governor (governor.gd) and the fixed view rule: in a view wider than
## WIDE_VIEW metres (back under 0.9 of it) or flying, the small things' sun shadows are off
## (lamps, signals, parked cars, columns, shelters: a pixel or two wide there, and a shadow-pass
## draw call per kind and 512 m tile). The governor runs in a normal launch; test runs (headless,
## --shots, --bench, --probe, --autopilot, --demo, the camera and water tests) and the BENCH
## button's minute hold it; --governor=on|off overrides.
const WIDE_VIEW := 150.0
var governor := Governor.new()
var _flag_governor := -1
var _governor_on := true
## --governor=log: on, and a `governor status:` line every GOVERNOR_LOG_EVERY seconds.
const GOVERNOR_LOG_EVERY := 5.0
var _governor_log := false
var _governor_log_next := 0.0
var _wide := false
## What _apply_extras last set (-1: nothing yet).
var _small_cast := -1
## Loop G1 testing aid (--stress=cpu:N|wait:N, --stress-from=S, --stress-to=S): N × 0.5 ms of busy
## work a frame from S to S2 seconds after the city is up: in _process (`cpu`: the CPU's extras go
## first) or in the draw phase (`wait`: what waiting for the GPU looks like to the main thread,
## so the GPU's extras go first).
var _stress_kind := ""
var _stress_n := 0
var _stress_from := 0.0
var _stress_to := INF
var _stress_t0 := 0
## Loop 2a: the driving controls (drive_controls.gd), the saved settings (settings.gd), the
## traffic level, and the command-line values that win over the saved ones (-1: none).
var controls := Controls.new()
var settings := Settings.new()
var traffic_level := Settings.DEFAULT_TRAFFIC
## -2: no --quality= (Tiers.AUTO is -1).
var _flag_quality := -2
var _flag_controls := -1
## Beta values: --lane-assist=on|off overrides Settings → Jazda → Asysta pasa for the run; the
## lane's direction is looked up every LANE_EVERY s (lane_assist.gd).
var _flag_lane := -1
var _lane_t := 0.0
const LANE_EVERY := 0.1
var _flag_traffic := -1
var _flag_fixed := false
var _flag_perf := false
var open_settings_at_start := false
## F's asks (2026-10-30): --fullmap opens the full-screen map at the start (screenshots).
var open_map_at_start := false
var fullmap_span := 0.0
## G12 part 2, --quest-pick=N (tests, shots): the full map opens at the start and row N of the
## ZADANIA tab shown (the vehicle's) is tapped; a place's pick then closes the map.
var quest_pick_flag := -1
var map_jump := Vector2.INF
## GAMEPLAY_PLAN 0.1, --teleport-test (verify step `teleport`): teleports to each of
## TELEPORT_TESTS in turn and fails (push_error) if the car lands in a tunnel, off the level of the
## ground or a deck there, or far from where it was asked; prints "teleport test: OK n/n".
var teleport_test := false
## [x, z, what]: above the four driven tunnels (the bug: a hold over a tunnel put the car on its
## floor), by a portal, and plain streets.
const TELEPORT_TESTS := [
	[429.0, -800.0, "over Tunel Wisłostrady, north"],
	[594.0, -586.0, "over Tunel Wisłostrady, south"],
	[116.0, 1619.0, "over Aleja Armii Ludowej's tunnel under Trasa Łazienkowska"],
	[42.0, 1618.0, "over Armii Ludowej's link tunnel"],
	[-761.0, -1399.0, "over Aleja Solidarności's tunnel"],
	[-315.0, -905.0, "over Karowa's short tunnel"],
	[850.0, -94.0, "over an unnamed link tunnel"],
	[1347.0, 1077.0, "under Trasa Łazienkowska's deck on Solec"],
	[1700.0, 973.0, "over the river by Most Łazienkowski"],
	[-1013.0, -45.0, "Marszałkowska at the start"],
	[-387.0, -187.0, "Nowy Świat"],
	[-700.0, 900.0, "PT-19: the hold that twice left the car in place"],
]
var hold_stick := Vector2.INF
var hold_pedal := ""
## Testing aid (--clicks=X:Y:F,...): a mouse click (a touch, with the project's touch
## emulation) at screen pixel X,Y on frame F, released two frames later.
var clicks: Array[Vector3i] = []
## Testing aid (--drag=X:Y:F:DX:DY:F2): a finger down at X,Y on frame F, moved by DX,DY over
## ten frames, held, and lifted on frame F2 (the stick through the real touch path).
var drags: Array[PackedInt32Array] = []
## The helicopter's stick or keys are held (the follow camera waits, like Point).
var _heli_held := false
var _heli_release := 99.0
## The held stick's screen direction and the camera's yaw when it was set (as drive_controls.gd's).
var _heli_set_aim := Vector2.ZERO
var _heli_set_yaw := 0.0
var _perf_wait := 0.0
var _clock_minute := -1
## --sound-check: play every sound once and print the bus meters (sfx.gd).
var sound_check := false
var _meters := {"Master": 0.0, "Music": 0.0, "SFX": 0.0, "Ambience": 0.0}
var _meter_top := {"Master": -200.0, "Music": -200.0, "SFX": -200.0, "Ambience": -200.0}
## Loop 10a: the river is off-limits. The car that still gets into the water (a glitch, a gap
## nobody found) splashes, settles, and after TOW_DELAY s the tow puts it back on the nearest
## lane on dry land, with a line from dialogue.json's water_tow; no money taken, whatever was
## running (a rescue, a delivery, a race) carries on.
const TOW_DELAY := 1.0
var splash: Splash
## v1.0 juice: sparks and dust where the car hits or scrapes (crash_fx.gd).
var crash_fx: CrashFx
## v1.0 juice: the "+54 zł" that floats up over the vehicle on a payment (money_pop.gd).
var money_pop: MoneyPop
## Seconds left until the tow (< 0: no tow waiting); when the car went in (the clock, s).
var _tow_wait := -1.0
var _splash_at := 0.0
var _clock := 0.0
## Where the car last was on dry land or a deck (the tow goes back to that level), INF: never.
var _last_dry := Vector3.INF
var _last_dry_yaw := 0.0
## --drive-into-water=X,Z (testing aid): 0 off, 1 driving at the water with its collision off
## (as if it had jumped the edge), 2 collision back on past the edge, 3 splashed, 4 towed.
var water_test := 0
var _water_test_at := Vector2.INF
## The driving-feel loop, --ram-test (testing aid): 0 off, 1 waiting for a traffic car to pick,
## 2 driving into the back of it, 3 done. The car rammed, the clock, when it was hit (s, -1: not
## yet) and the unsticks before the test.
var ram_test := 0
## First scene items 6-7 (2026-11-02), --first-life: after FIRST_LIFE_S s of play at the start, logs
## the start's life and sound (the busy pavements' walkers, the street sites' people, the trams'
## greeting bell, the square's bed) as "first life: OK (...)" or its problems (tools/verify.sh
## `firstlife`, with --at= and --heading= on the start).
var first_life := false
var _first_life_t := 0.0
const FIRST_LIFE_S := 15.0
var _ram_driver: RefCounted
var _ram_t := 0.0
var _ram_hit := -1.0
var _ram_unsticks := 0
var _ram_dir := Vector3.ZERO
## --traffic-overlaps (testing aid): traffic counts its cars' overlapping boxes, printed at the end.
var _traffic_overlaps := false
## The traffic loop, --tram-watch=N (testing aid): the car (no collisions, standing still) is put
## beside tram N, ahead of it, again and again, so the view, the traffic and
## the tram's cars come with that tram through the city (with --traffic-overlaps: how often a
## tram and a car touch). -1: off.
var tram_watch := -1
var _tram_watch_at := Vector2.INF
## Loop 2c, --lineup (testing aid): every vehicle model standing round the car, no traffic, for
## close-up screenshots (with --size=25 or so).
var lineup := false
## The river's outlines (water bodies of 20,000 m² or more, as tools/bake_water.py counts it):
## which tow lines fit.
var _rivers: Array[PackedVector2Array] = []
## Camera loop testing aids. --cam-log prints the camera's state every CAM_LOG_EVERY frames
## (`cam:` lines: scheme, finger, speed, the car's and the camera's compass headings, the
## camera's turn rate (the fastest since the last line), the car's place on screen, the view).
## --cam-test=NAME drives one camera moment in the real city with scripted inputs through the
## scheme's own mapping (drive_controls.gd), the car ghosting through walls, no traffic, after
## CAM_TEST_SETTLE s parked with the camera behind it (it implies --cam-log; frame strips are
## --shots= every 15 frames): `classic_turn` (Classic with the camera following: up to 50 km/h,
## a 90° right turn held near 50, then straight on), `point_release` (Point: up to 50 km/h,
## the stick held 90° right for 2.5 s, then let go), `brake` (Classic following: flat out to
## 90 km/h, then braking to a stop).
const CAM_LOG_EVERY := 15
const CAM_TEST_SETTLE := 1.0
var cam_log := false
var cam_test := ""
var _cam_t := 0.0
var _cam_phase := 0
var _cam_phase_t := 0.0
var _cam_aim := 0.0
var _cam_last_yaw := INF
var _cam_turn_max := 0.0


func _ready() -> void:
	_parse_args()
	Gamepad.install()  # the gamepad loop: the pad's stick and trigger actions
	_parse_stream_args()  # loop 3c (the sectors block at the end of this file)
	_load_settings()
	# The audio buses first: the radio plays on Music from the title screen on.
	Sfx.setup_buses()
	Sfx.set_levels(settings.master, settings.music, settings.effects)
	# The title screen (or, for test runs, a plain loading card) covers the second
	# or two the city takes to build; the radio already plays.
	var loading: CanvasLayer = null
	if show_title:
		title = Title.new()
		title.touch_off = no_touch  # desktop: --no-touch
		title.language_chosen.connect(_on_language_chosen)
		# The loading bar: the title runs while the tree is paused for the build (_load_step).
		title.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(title)
	else:
		loading = _loading_card()
	radio = Radio.new()
	# Loop 2a: the radio keeps playing under the settings panel (the game is paused).
	radio.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(radio)
	radio.log_on = radio_log
	wallet = Wallet.new()
	wallet.persistent = not no_save
	add_child(wallet)
	if reset_save:
		wallet.reset()
	# Loop MW-5: PÓŁNOC FM's locked tracks read the save; chapters finished before this loop
	# open their tracks once, quietly. --station= by name; --radio= now reaches every station.
	radio.wallet = wallet
	radio.unlock_all = unlock_flag == "all"
	radio.sync_chapters()
	radio.picked = radio_picked
	var start_index := mini(start_station, radio.stations.size()) - 1
	if station_flag != "":
		start_index = radio.station_index(station_flag)
		if start_index < 0:
			push_warning("--station=%s: no such station in radio.json" % station_flag)
	# First scene item 7: a first launch hears the song from its first bar.
	radio.from_top = show_title and First10.guide_due(wallet)
	radio.tune(start_index, true)
	print("save: %s (%s)" % [wallet.summary(), ProjectSettings.globalize_path(Wallet.PATH) if not no_save else "not saved"])
	_resume_start()  # save and resume: the car where the last session left it
	_start_preloads()  # the loading bar: the big map files load on threads under the title
	await get_tree().process_frame
	await get_tree().process_frame
	var t0 := Time.get_ticks_msec()
	await _wait_preloads()
	_place_start()  # loop MW-1: --place=<id>, the sectors round the place
	_syrenka_start()  # loop 3h slice 2: --syrenka=<id|n>
	if trzy_mosty_flag:
		# Loop 3h slice 3: --trzy-mosty[=N]: the city built round the start (or bridge N) first.
		var hint: Vector2 = TrzyMosty.START_HINT if trzy_mosty_bridge <= 0 else TrzyMosty.BRIDGES[trzy_mosty_bridge - 1]["hint"]
		start_at = Vector3(hint.x, 0.0, hint.y)
	_club_start()  # loop MW-3: --club=<id>, the same
	if garage_flag:
		start_at = Vector3(Garage.SPOT.x, 0.0, Garage.SPOT.y)  # the garage loop: --garage
	_guide_start()  # the first-10 polish: a guided run starts facing the first stand
	var no_map := _missing_map()
	if no_map != "":
		# Loop 3d-1: the split and the prebuilt sectors are not committed; a fresh clone makes
		# them once with tools/setup_map.sh. Say so plainly instead of failing deep in the builder.
		push_error(no_map)
		get_tree().quit(1)
		return
	if title != null:
		get_tree().paused = true  # the loading bar: nothing half-built moves between the build's steps
	await _build_world()
	if title != null:
		get_tree().paused = false
	view.visible = true
	_preloaded.clear()
	_put_at_resume()
	print("city built in %d ms, %s" % [Time.get_ticks_msec() - t0, _scene_stats()])
	if loading != null:
		loading.queue_free()
	if title != null:
		hud.visible = false
		dialogue.host_on = false
		title.dismissed.connect(_on_title_dismissed)
		title.new_game.connect(_on_new_game)
		title.can_resume = (wallet.has_progress() and wallet.persistent and not wallet.newer) or title_choice in ["ask", "new"] or not resume_flag.is_empty()
		title.resume_line = _resume_line()
		title.auto_go = _new_game_pending
		_new_game_pending = false
		# The loading fix: "tap to drive" once the sectors round the start are in (_title_frame).
		_title_wait_t = Time.get_ticks_msec()
		_title_pending = streamer.pending() if streamer != null else 0
	else:
		radio.now_playing()
		_fallback_toast()
		if first10 != null and not _opening_on:
			first10.begin()  # loop 3h slice 4: no title: the guide's clock starts now
	_started = true


func _exit_tree() -> void:
	# A shots run that ends before its last shot (--quit-after, a closed window) says which
	# frames are missing and where it was, instead of ending quietly after "city built".
	var missing: Array[int] = []
	for n in shots:
		if n not in _shots_saved:
			missing.append(n)
	if not missing.is_empty():
		print("shots: missing %s (game frame %d, engine frame %d, paused %s, started %s)" % [
				missing, frame, Engine.get_process_frames(), get_tree().paused, _started])
	if _stats != null:
		_stats.unhook()
	if RenderingServer.frame_pre_draw.is_connected(_stress_wait):
		RenderingServer.frame_pre_draw.disconnect(_stress_wait)


## The loading fix (2026-10-31): the title screen waits (at most TITLE_WAIT_MS) for the sectors
## round the start to be in before it offers "tap to drive", and the streamer loads them
## unthrottled meanwhile (nothing on screen moves that could hitch): the first seconds of play
## show no proxies. -1: the prompt is up.
const TITLE_WAIT_MS := 8000
var _title_wait_t := -1
## The loading bar: the most sectors the title has waited for at once.
var _title_pending := 0


## The loading bar (F, 2026-11-05: "it freezes, later I see the road"): the title screen showed a
## still "building the city…" for the second or two the build blocked the main thread, then the
## city. Now the title shows a bar that moves: the big map files (the prebuilt index and the
## proxies) load on threads first (ResourceLoader's threaded requests, LOAD_FILES of the bar),
## the build yields a frame between its steps with the tree paused (up to LOAD_BUILT), and the
## start's sectors fill the rest (_title_frame). Test runs (no title) build in one go, as before.
const LOAD_FILES := 0.12
const LOAD_BUILT := 0.6
## The threaded requests' paths, and what they loaded (held until the build has used them, so the
## streamer's own `load` takes them from the cache).
var _preload_paths: PackedStringArray = []
var _preloaded: Array[Resource] = []


func _start_preloads() -> void:
	if title == null or monolithic or not ((prebuilt or not OS.has_feature("editor")) and solo_site == ""):
		return
	for path in [SectorStreamer.INDEX_SCENE, SectorStreamer.PROXY_SCENE]:
		if ResourceLoader.exists(path) and ResourceLoader.load_threaded_request(path, "", true) == OK:
			_preload_paths.append(path)


func _wait_preloads() -> void:
	var t0 := Time.get_ticks_msec()
	var frames := 0
	while not _preload_paths.is_empty():
		var sum := 0.0
		var busy := false
		for path in _preload_paths:
			var at := []
			if ResourceLoader.load_threaded_get_status(path, at) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				busy = true
				sum += float(at[0]) if not at.is_empty() else 0.0
			else:
				sum += 1.0
		if title != null:
			title.progress = maxf(title.progress, LOAD_FILES * sum / float(_preload_paths.size()))
		if not busy:
			break
		frames += 1
		await get_tree().process_frame
	if not _preload_paths.is_empty():
		print("loading bar: %s on threads in %d ms (%d frames)" % [", ".join(_preload_paths), Time.get_ticks_msec() - t0, frames])
	for path in _preload_paths:
		var r := ResourceLoader.load_threaded_get(path)
		if r != null:
			_preloaded.append(r)
	_preload_paths = []


## The loading bar: the build's start (ticks, moved on by the frames shown), then each step's ms,
## printed under the title as "loading bar: the build's steps".
var _load_ms: Array[int] = []


## A build step done: its ms noted, the bar moved and a frame shown (under the title only).
func _load_mark(share: float) -> void:
	var now := Time.get_ticks_msec()
	_load_ms.append(now - _load_ms[0] - _load_ms.slice(1).reduce(func(a: int, b: int) -> int: return a + b, 0))
	await _load_step(share)
	_load_ms[0] += Time.get_ticks_msec() - now  # the frames shown don't count in the next step


## The loading bar: the build's share so far (LOAD_FILES..LOAD_BUILT) and a frame to show it, under
## the title only (test runs build in one go).
func _load_step(share: float) -> void:
	if title == null:
		return
	title.progress = maxf(title.progress, lerpf(LOAD_FILES, LOAD_BUILT, share))
	await get_tree().process_frame


func _title_frame() -> void:
	if streamer != null:
		streamer.hurry = title != null
	if title == null or _title_wait_t < 0:
		return
	if streamer != null and _title_pending > 0:
		# The loading bar's last stretch: the start's sectors still to come.
		_title_pending = maxi(_title_pending, streamer.pending())
		title.progress = maxf(title.progress, LOAD_BUILT + (1.0 - LOAD_BUILT) * (1.0 - float(streamer.pending()) / float(_title_pending)))
	if streamer == null or streamer.idle() or Time.get_ticks_msec() - _title_wait_t > TITLE_WAIT_MS:
		print("title: the start's sectors in after %d ms%s" % [Time.get_ticks_msec() - _title_wait_t,
				"" if streamer == null or streamer.idle() else " (not all: the wait's limit)"])
		_title_wait_t = -1
		title.set_ready()
		if title != null and title_choice != "":
			# Save and resume: --title-choice= picks for the player (continue, new, or ask: the question up).
			print("title: --title-choice=%s" % title_choice)
			match title_choice:
				"new":
					title.choose("new")
					title.choose("yes")
				"ask":
					title.choose("new")
				_:
					title.choose("continue")


## Save and resume (2026-10-31): the car goes back to where the last session left it on a normal
## launch (the title screen up, no flag that places it); "NOWA GRA" on the title wipes the save
## (wallet.gd `start_over`, a copy kept as save.prev.cfg) and starts the scene again, the title
## going by itself once the start is in (`_new_game_pending` survives the reload: a static).
## `--title-choice=continue|new` picks on the title once it is ready (the shots and checks).
## The spot is kept every REMEMBER_EVERY seconds of driving (moved 5 m or more), and when the app
## goes to the background or the window closes; never by test runs or --nosave.
const REMEMBER_EVERY := 5.0
static var _new_game_pending := false
var title_choice := ""
var resume_flag: Array = []
var _resume_yaw := INF
var _remember_on := false
var _remember_t := 0.0


func _resume_start() -> void:
	_remember_on = show_title and wallet.persistent and not wallet.newer
	if not resume_flag.is_empty():
		wallet.session = {"x": resume_flag[0].x, "z": resume_flag[0].z, "yaw": resume_flag[1], "tunnel": 0, "at": 0}
	if not show_title or start_at != Vector3.INF:
		return
	var spot := wallet.resume_spot()
	if spot.is_empty():
		return
	start_at = spot[0]
	start_in_tunnel = spot[2]
	_resume_yaw = spot[1]
	print("resume: the last session's spot (%.0f, %.0f)%s" % [start_at.x, start_at.z, " in a tunnel" if start_in_tunnel else ""])


## Once the city is built: the kept spot onto the nearest lane on its level (facing the kept way
## where the lane allows); a spot with no lane near, or in the water, goes back to the start.
func _put_at_resume() -> void:
	if _resume_yaw == INF or car == null:
		return
	var lane := _lane_spot(car.global_position, _resume_yaw)
	if lane.is_empty() or Vector2((lane[0] as Vector3).x, (lane[0] as Vector3).z).distance_to(Vector2(start_at.x, start_at.z)) > 60.0:
		print("resume: no lane near the kept spot, back to the start")
		car.global_transform = _spawn
	else:
		car.global_position = lane[0]
		car.rotation.y = lane[1]
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	cam_focus = car.global_position


## Every REMEMBER_EVERY s (and on the way to the background): the car's spot into the save, when
## it is on the ground (not flying, not in the water, not mid-air off a kerb).
func _remember_frame(dt: float, now := false) -> void:
	if not _remember_on or not _started or title != null or _phone_bench or car == null or map == null:
		return
	_remember_t += dt
	if not now and _remember_t < REMEMBER_EVERY:
		return
	_remember_t = 0.0
	var p := car.global_position
	if map.in_water(p.x, p.z, p.y) or absf(p.y - map.drive_height(p.x, p.z, p.y)) > 1.5:
		return
	wallet.remember_spot(p, car.rotation.y, map.in_tunnel(p.x, p.z, p.y), int(Time.get_unix_time_from_system()), 1.0 if now else 5.0)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST]:
		_remember_frame(0.0, true)
	elif what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		# iOS stops the haptic engine in the background: start it again now, not in a crash's frame.
		Haptics.warm()


func _on_new_game() -> void:
	if not wallet.start_over():
		return
	_remember_on = false
	_new_game_pending = true
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")


func _on_title_dismissed() -> void:
	hud.visible = not hide_hud
	dialogue.host_on = true
	title = null
	radio.now_playing()
	_radio_greeting()
	_fallback_toast()
	if cinematic_flyin:
		_fly_in()
	if first10 != null and not _opening_on:
		first10.begin()  # loop 3h slice 4: the guide's clock starts with the first tap


## The opening flyover (docs/design/opening-flyover.md): the first launch's camera flight over
## Plac Defilad down to the car, in place of the short fly-in. Due when the guide runs in a normal
## launch (a fresh save), or forced by --cinematic=opening. While it plays the HUD is hidden and
## the guide's clock waits; both start when it ends (done or skipped by a tap).
var _opening_on := false
var _opening_audio: Node

func _opening_due() -> bool:
	if _flag_cinematic == "opening":
		return true
	return cinematic_flyin and not flying and _flag_cinematic == "" and first10 != null and first10.guide


## Camera loop: the fly-in from over the city down to the car (camera_shots.gd), or the opening
## flyover on a first launch.
func _fly_in() -> void:
	var vehicle: Node3D = heli if flying else car
	# First scene items 6-7: the start's trams where the first frame wants them when the camera lands.
	_first_scene_trams(CameraShots.OPEN_TIME if _opening_due() else CameraShots.FLY_TIME)
	if _opening_due():
		_opening_on = true
		hud.visible = false
		moments.ended.connect(_on_opening_ended, CONNECT_ONE_SHOT)
		_opening_audio = OpeningAudio.new()
		add_child(_opening_audio)
		_opening_audio.start(radio)
		moments.opening(vehicle.global_position, cam_yaw, camera_pitch,
				PackedStringArray(["Śródmieście · Plac Defilad", "the centre of Warsaw"]))
		return
	var ahead := -vehicle.global_transform.basis.z
	moments.fly_in(vehicle.global_position, ahead, cam_yaw, camera_pitch, _view_size)


func _on_opening_ended(_what: String) -> void:
	_opening_on = false
	if _opening_audio != null:
		_opening_audio.flight_ended()
	hud.visible = not hide_hud
	if first10 != null:
		first10.begin()


## Camera loop: the car was put somewhere else (a tow): the view goes there at once, and a
## following camera turns behind it at once (not while Point's finger is down: the held direction
## would turn with it).
func _cut_camera() -> void:
	cam_focus = car.global_position
	fcam.reset_lead()
	if follow and not controls.held:
		cam_yaw = rad_to_deg(car.rotation.y)
		cam_yaw_target = cam_yaw
		fcam.stop_turning()


## Camera loop: any touch, click, key or pad button skips a cinematic moment.
func _input(event: InputEvent) -> void:
	_note_pad(event)
	if moments == null or not moments.playing():
		return
	var go := false
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventJoypadButton:
		go = event.is_pressed()
	elif event is InputEventKey:
		go = event.is_pressed() and not event.is_echo()
	if go:
		moments.skip()


func _scene_stats() -> String:
	var vertices := 0
	var instances := 0
	for c in _city_nodes():  # loop 3c: the map's own nodes and the loaded sectors'
		if c is MeshInstance3D and c.mesh.get_surface_count() > 0:
			vertices += c.mesh.surface_get_array_len(0)
		elif c is MultiMeshInstance3D:
			instances += c.multimesh.instance_count
			var m: Mesh = c.multimesh.mesh
			var per := 0
			for surface in m.get_surface_count():
				per += (m.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			vertices += c.multimesh.instance_count * per
	return "%d vertices, %d instances" % [vertices, instances]


func _loading_card() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 10
	var bg := ColorRect.new()
	bg.color = Color("#a8cde6")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var label := Label.new()
	label.text = Title.WORDMARK + "\nbudujemy miasto…\nbuilding the city…"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Loop 2e: in points like the HUD (screen_points.gd), Polish above English.
	var pt: float = ScreenPoints.measure(get_viewport().get_visible_rect().size)["pt"]
	label.add_theme_font_size_override("font_size", roundi(20.0 * pt))
	label.add_theme_color_override("font_color", Color("#fbf7ee"))
	label.add_theme_color_override("font_outline_color", Color("#2a2622"))
	label.add_theme_constant_override("outline_size", roundi(4.0 * pt))
	layer.add_child(label)
	add_child(layer)
	return layer


func _build_world() -> void:
	view = SubViewportContainer.new()
	view.stretch = true
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	# The loading bar: the 3D view isn't drawn under the title until the build is done (the frames
	# the build yields then cost only the title's draw).
	view.visible = title == null
	add_child(view)
	sv = SubViewport.new()
	sv.msaa_3d = Viewport.MSAA_DISABLED
	sv.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	sv.physics_object_picking = false
	# The sound's listener (sfx.gd) lives in this viewport's 3D world.
	sv.audio_listener_enable_3d = true
	view.add_child(sv)

	var world := Node3D.new()
	sv.add_child(world)
	_add_environment(world)

	building_mat = ShaderMaterial.new()
	building_mat.shader = load("res://shaders/building.gdshader")
	if solo_site != "" and solo_look != "lit":
		building_mat.shader = load("res://shaders/solo.gdshader")
		building_mat.set_shader_parameter("look", 1 if solo_look == "sil" else 0)
	var flat_mat := ShaderMaterial.new()
	flat_mat.shader = load("res://shaders/ground.gdshader")
	flat_mat.set_shader_parameter("debug_ao", debug_ao)
	_ground_mat = flat_mat
	flat_mat.set_shader_parameter("ao_strength", 0.0 if no_ao else 1.0)

	var data: Dictionary
	# Loop 3c: the city in 512 m sectors, streamed round the camera (sector_streamer.gd): the
	# exported game (and --prebuilt) loads the sectors tools/bake_city.gd built on the Mac, the
	# editor builds them from their files. --monolithic builds the whole city at once from
	# centrum.json, as before loop 3c (the pixel diff's reference; city.scn is gone).
	_load_ms = [Time.get_ticks_msec()]
	if not monolithic:
		data = _open_streamed_city(world, flat_mat)
		flat_mat = map.flat_material
		if _flag_no_map_edge:
			var edge := map.get_node_or_null("MapEdge")
			if edge != null:
				edge.free()
		if _flag_no_edge_roadworks:
			var works := map.get_node_or_null("EdgeRoadworks")
			if works != null:
				works.free()
	else:
		map = MapBuilder.new()
		world.add_child(map)
		data = map.build(MAP_PATH, building_mat, flat_mat)
		map.open_maps_whole()  # loop 3d-2b: every sector's map slices on the GPU at once
	await _load_mark(0.1)

	for a in data["areas"]:
		if a["k"] == "water":
			var ring := PackedVector2Array()
			var flat: Array = a["p"]
			for k in range(0, flat.size() - 1, 2):
				ring.append(Vector2(flat[k], flat[k + 1]))
			if absf(MapBuilder._ring_area(ring)) >= 20000.0:
				_rivers.append(ring)
	ped_zones = PedZones.new(data.get("ped_zones", []))
	car = Car.new()
	car.ground_height = map.drive_height
	car.set_sensitivity(settings.sensitivity)
	car.set_handling(settings.handling)  # G4: Cruise by default, Sport from Settings → Jazda
	car.lane_assist = settings.lane_assist if _flag_lane < 0 else _flag_lane == 1
	world.add_child(car)
	_xray = TunnelXray.new()
	world.add_child(_xray)
	_xray.setup(car)
	car.stuck.connect(_on_car_stuck)
	car.jammed.connect(_on_car_stuck)  # G17: 8 s among traffic cars
	car.water_at = map.in_water
	car.kerb_feel = map.kerb_feel  # loop 3b-2: kerbs, islands and medians the car feels
	car.splashed.connect(_on_car_splashed)
	var spawn: Dictionary = data["spawn"]
	car.global_position = Vector3(spawn["x"], 0.0, spawn["z"])
	car.rotation.y = spawn["yaw"]
	_spawn = Transform3D(Basis(Vector3.UP, spawn["yaw"]), Vector3(spawn["x"], map.ground_height(spawn["x"], spawn["z"]), spawn["z"]))
	if start_at != Vector3.INF:
		car.global_position = start_at
		car.global_position.y = map.ground_height(start_at.x, start_at.z)
		if start_in_tunnel and not is_nan(map.tunnel_floor_under(start_at.x, start_at.z)):
			car.global_position.y = map.tunnel_floor_under(start_at.x, start_at.z)
		elif start_under:
			car.global_position.y = map.drive_height(start_at.x, start_at.z, map.terrain_height(start_at.x, start_at.z))
	if start_heading != INF:
		car.rotation.y = -deg_to_rad(start_heading)
	cam_focus = car.global_position

	var skids := Skids.new()
	skids.car = car
	skids.ground_height = func(x: float, z: float) -> float: return map.drive_height(x, z, car.global_position.y)
	skids.material_override = flat_mat
	world.add_child(skids)
	splash = Splash.new()
	world.add_child(splash)
	crash_fx = CrashFx.new()
	world.add_child(crash_fx)
	money_pop = MoneyPop.new()
	money_pop.anchor = func() -> Vector3: return _vehicle_position()
	world.add_child(money_pop)
	car.impact.connect(_on_car_impact)
	car.scraped.connect(func(at: Vector3, normal: Vector3, speed: float) -> void:
		crash_fx.scrape(at, normal, car.vel, speed, car.global_position.y))

	heli = Heli.new()
	heli.ground_height = map.ground_height
	heli.top_height = map.top_height
	heli.tallest_near = map.tallest_near
	heli.set_map(map)  # map north: the L-shaped outline, not the bounding box
	world.add_child(heli)
	heli.landed.connect(_on_heli_landed)

	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = base_size
	cam.near = 1.0
	cam.far = 1400.0
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	world.add_child(cam)
	_add_post_pass()
	# After the post pass's quad (the camera's first child, --exp=nopost hides it).
	_view_size = base_size
	moments = CameraShots.new()
	add_child(moments)
	moments.setup(cam, world)

	tod = TimeOfDay.new()
	add_child(tod)
	if live_clock != "":
		tod.clock_start = TimeOfDay.warsaw_to_utc(live_clock, live_date)
	tod.setup(env, sun, post_mat, sun_pitch)
	tod.lights_switched.connect(_show_night_nodes)
	weather = Weather.new()
	weather.tod = tod
	weather.post = post_mat
	add_child(weather)

	hud = Hud.new()
	# Loop 2a: the HUD (and the settings panel in it) works while the game is paused.
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	hud.set_scheme(controls.scheme)
	hud.set_left_handed(Access.left_handed)  # accessibility (2026-11-01)
	hud.set_touch_off(no_touch)  # desktop: --no-touch
	hud.settings_pressed.connect(_open_settings)
	hud.context_pressed.connect(_on_context_pressed)  # the stuck offer's tow (2026-11-03)
	hud.settings_panel.changed.connect(_on_setting)
	hud.settings_panel.closed.connect(_close_settings)
	hud.map_pressed.connect(_open_full_map)  # F's asks: a tap on the minimap
	# Loop 2e: TIME, VHS, RAIN, STYLE, CAM, QUALITY and the rotate and zoom buttons left the
	# driving screen (Settings has them; the keys stay; zoom is a pinch, a twist turns a fixed
	# camera).
	hud.radio_pressed.connect(radio.next)
	hud.radio_skip_pressed.connect(radio.next_track)
	hud.perf_gesture.connect(func(): _set_perf(not show_perf); settings.perf = show_perf; settings.save())
	radio.station_changed.connect(_on_station_changed)
	# Beta radio: the next key beside RADIO while the station has another song.
	radio.track_changed.connect(func(_i: Dictionary, _t: Dictionary, _n: bool): hud.set_radio_skip(radio.can_skip()))
	radio.track_unlocked.connect(func(_n: int, _t: Dictionary, _w: String): hud.set_radio_skip(radio.can_skip()))
	_on_station_changed(radio.station, radio.stations[radio.station] if radio.station >= 0 else {})
	radio.ticker.connect(hud.ticker)
	hud.set_radio_name(radio.label())
	hud.visible = not hide_hud and title == null  # the loading bar: not over the title between the build's steps
	hud.rotate_pressed.connect(func(d: int):
		if not follow:
			_rotate_camera(d))
	hud.pinched.connect(_on_pinch)
	hud.setup_minimap(data, map.map_outline(), map.outside)  # map north: the L, not the box
	hud.map_landmarks = map.landmark_info  # the full map's landmark icons (map_icons.gd)
	hud.vehicle_pressed.connect(_toggle_vehicle)
	hud.zoom_pressed.connect(_zoom_view)  # G3: the − and + buttons
	hud.tapped.connect(_on_tap)
	_set_flying(false)

	missions = Missions.new()
	missions.line_split = start_mission == 0  # G12: calls follow the vehicle (quest_lines.gd)
	add_child(missions)
	missions.setup(map, data, world, hud)
	missions.player = car.global_position
	# Speech bubbles (anyone can talk) and everybody's lines.
	bubbles = Bubbles.new()
	bubbles.pt = hud.pt
	bubbles.kmh = func() -> float: return absf(car.forward_speed) * 3.6
	# Phase 0.2 (docs/GAMEPLAY_PLAN.md): one chatter budget (chatter.gd). Quiet while the car
	# struggles or the stuck offer is up; ambient lines wait while a card is up; a driver's shout
	# at a bump needs a real hit (car.bumped's closing speed); the level is the setting.
	bubbles.struggle = func() -> bool: return not flying and (car.struggling() or hud.pill_shown("unstuck"))
	bubbles.cards_up = hud.cards_up
	bubbles.chatter.level = settings.chatter
	car.bumped.connect(func(_c: Object, speed: float) -> void: bubbles.chatter.hit(speed * 3.6))
	hud.chatter = bubbles.chatter
	bubbles.project = func(p: Vector3) -> Vector2: return cam.unproject_position(p) * float(view.stretch_shrink)
	hud.add_speech(bubbles)  # above the target pointer, below the panels (PT-10)
	bubbles.process_mode = Node.PROCESS_MODE_PAUSABLE
	dialogue = Dialogue.new()
	dialogue.host_first = host_in
	dialogue.bubbles = bubbles
	dialogue.radio = radio
	add_child(dialogue)
	radio.station_changed.connect(dialogue.on_station_changed)
	missions.wallet = wallet
	missions.dialogue = dialogue
	missions.vehicle_anchor = func() -> Vector3: return _vehicle_position() + Vector3(0, 4.0 if flying else 2.2, 0)
	hud.set_wallet(wallet.zl, wallet.respect)
	wallet.changed.connect(hud.set_wallet)
	wallet.changed.connect(func(_zl: int, _respect: int, gained: int) -> void:
		if gained > 0:
			money_pop.pop(gained)
			if sfx != null:
				sfx.coin())
	if pop_flag > 0:
		get_tree().create_timer(2.0).timeout.connect(func() -> void: wallet.pay(pop_flag))
	await _load_mark(0.26)
	if data.has("graph"):
		graph = LaneGraph.new(data["graph"], map)
	if debug_roads:
		var dr: Node3D = load("res://scripts/debug_roads.gd").new()
		world.add_child(dr)
		dr.setup(map, graph, _vehicle_position, data)
	if not no_traffic and graph != null:
		_build_life(data, world)
	await _load_mark(0.53)
	if graph != null:
		_build_side_jobs(data, world)
	_build_notebook(data)
	_build_moments(data, world)
	_build_districts()
	_build_syrenki(world)
	_build_cassettes(world)
	_build_first_scene(world)
	_build_skwer_zlota(world)
	_build_tarasy_screen(world)
	_build_spire_motion(world)
	_build_street_details(world)
	_build_ratusz_hub(data, world)
	_build_park_details(world)
	_build_garage(world)
	await _load_mark(0.66)
	# Loop MW-5: a PÓŁNOC FM track opened (a chapter, an egg, --unlock=N): a toast.
	radio.track_unlocked.connect(func(_n: int, track: Dictionary, _why: String) -> void:
		var t := Radio.unlock_toast(String(track["title"]))
		hud.toast(t[0], t[1]))
	if unlock_flag != "" and unlock_flag != "all":
		for n in unlock_flag.split(",", false):
			radio.unlock_track(int(n), "flag")
	if lineup:
		_build_lineup(world)
	if start_flying:
		_take_off(Heli.CRUISE)
		if _start_alt > 0.0:
			var p := heli.global_position
			heli.place(Vector3(p.x, map.ground_height(p.x, p.z) + _start_alt, p.z), heli.rotation.y, _start_alt)
	# Loop 2e: no call card at the start (docs/DEMO.md 6.1): calls come in during play.
	if start_mission > 0:
		missions.start(start_mission)
	elif demo or start_race > 0 or start_rival > 0 or trzy_mosty_flag or bench or start_kebab >= 0 or start_sloik >= 0 or free_roam or roundup_flag:
		missions.close()
	else:
		missions.quiet_start(call_in)
	if jobs != null and start_kebab >= 0:
		jobs.courier.force = courier_race  # loop jobs-2
		if courier_v > 0.0:
			jobs.courier.speed = courier_v
			jobs.courier.fixed_speed = true  # loop couriers
		jobs.start_kebab(start_kebab)
		cam_focus = car.global_position
	elif jobs != null and start_sloik >= 0:
		jobs.start_sloik(start_sloik, start_sloik_station)
		cam_focus = car.global_position
	elif rides != null and start_ride >= 0:
		rides.start_ride(start_ride)  # loop 2d-1
		cam_focus = car.global_position
	if rivals != null and (start_race > 0 or start_rival > 0):
		var i := (maxi(start_race, start_rival) - 1) % Rivals.RIVALS.size()
		rivals.put_ahead(i)
		cam_focus = car.global_position
		if start_race > 0:
			rivals.start_race(i)
		elif autopilot:
			rivals.tail = i
	elif rivals != null and trzy_mosty_flag:
		# Loop 3h slice 3: --trzy-mosty: the final at once from its start (the run is at night).
		if rivals.start_final_now(trzy_mosty_bridge):
			cam_focus = car.global_position

	if _water_test_at != Vector2.INF:
		_start_water_test()
	if cam_test != "":
		_start_cam_test()
	_build_sound(data, world)
	await _load_mark(0.67)
	# Loop 3g-1: the police, on the traffic's lane graph (none with --no-police).
	if traffic != null and not police_opts.get("off", false):
		_build_police(data, world)
	_build_crowds(data, world)
	_build_city_life(data, world)
	await _load_mark(0.85)
	_build_buses(data, world)
	_build_old_tram(world)
	_build_crash_scenes()
	_build_rave(data, world)
	_build_meet(data, world)
	_build_boat_race(world)
	_build_kino_tour(world)
	_build_ev_tow(world)
	_build_stories(world)
	_build_storefronts(data, world)
	_build_packs(data, world)
	_build_fans(data, world)
	_build_loud_cars(world)
	_build_crazy_drivers(world)
	_build_wellness(world)
	_build_first10()
	await _load_mark(0.99)
	_set_quality(quality_choice)
	get_tree().root.size_changed.connect(_apply_style)
	_apply_style()
	_show_night_nodes(false)
	tod.set_mode(start_time, true)
	if solo_site != "" and solo_look != "lit":
		tod.plain_background = Color("#f0f0f0") if solo_look == "sil" else Color("#8a8f96")
		tod.refresh()
	# Loop MW-3: --clock=HH:MM with a fixed look (--time=night --clock=01:00) starts its clock there.
	if live_clock != "" and start_time != TimeOfDay.LIVE:
		var hm := live_clock.split(":")
		tod.fixed_start = clampf(float(hm[0]) + (float(hm[1]) / 60.0 if hm.size() > 1 else 0.0), 0.0, 23.99)
	# Loop MW-5: PÓŁNOC FM reads the game clock; the radio follows it until the player picks.
	radio.clock = func() -> Array:
		var c := tod.local_clock()
		return [TimeOfDay.NAMES[tod.mode], c["hour"]]
	radio.check_air(true)
	weather.set_state(start_weather, true)
	_set_vhs(vhs)
	_set_perf(show_perf)
	_blip = AudioStreamPlayer.new()
	_blip.process_mode = Node.PROCESS_MODE_ALWAYS
	_blip.bus = &"SFX"
	_blip.volume_db = -11.0
	if ResourceLoader.exists("res://audio/ui/blip.wav"):
		_blip.stream = load("res://audio/ui/blip.wav")
	add_child(_blip)
	# Camera loop: a following camera starts behind the vehicle (it used to start on the 45°
	# diagonal and, in Classic, swung ~155° round at up to 182°/s as soon as the car moved).
	# Screenshots, the bench and the probe keep the 45° start: their views are the reference
	# pictures (tools/shots.sh) and the performance budgets' (--cinematic screenshots start as a
	# normal launch does).
	if follow and not _flag_yaw and (shots.is_empty() or _flag_cinematic != "") and not bench and not probe:
		var start_yaw := rad_to_deg((heli if flying else car).rotation.y)
		cam_yaw = start_yaw
		cam_yaw_target = start_yaw
	fcam.reset_lead()
	_update_camera(1.0)
	if cinematic_flyin and title == null and cam_test == "":
		_fly_in()
	# Loop 2a: the frame count and screenshots go on while the game is paused (settings).
	get_tree().process_frame.connect(_paused_frame)
	if hold_stick != Vector2.INF:
		var screen := get_viewport().get_visible_rect().size
		hud.hold_stick(Vector2(screen.x * 0.17, screen.y * 0.7), hold_stick)
	if hold_pedal != "":
		hud.hold_pedal(hold_pedal)
	if open_settings_at_start:
		hud.settings_panel.set_tab(settings_tab)
		if settings_tab == 4:
			hud.settings_panel.show_notebook(notebook_open)
		_open_settings.call_deferred()
	elif open_map_at_start:
		_open_full_map.call_deferred()
	if map_jump != Vector2.INF:
		var why := _teleport_refusal()
		print("teleport: --map-jump refusal: %s" % ("none" if why.is_empty() else why[1]))
		_teleport_from_map.call_deferred(map_jump)
	if teleport_test:
		_teleport_test.call_deferred()
	_stats = _make_stats()
	# Loop 3g-1: the police's script time among the bench's lines.
	if police != null:
		_stats.systems["police"] = [police, "spent_usec", true]
	_stats.hook(get_tree())
	# Loop G1, --stress=wait:N: after bench.gd's own frame_pre_draw, so it counts as "draw".
	_stress_t0 = Time.get_ticks_msec()
	if _stress_kind == "wait":
		RenderingServer.frame_pre_draw.connect(_stress_wait)
	_apply_experiments()
	_apply_fps()
	await _load_mark(1.0)
	if title != null:
		print("loading bar: the build's steps %s ms" % [_load_ms.slice(1)])
	_bench_t0 = Time.get_ticks_msec()
	if bench or probe:
		# The macOS driver may keep vsync on anyway (the frame rate then tops out at
		# the display's refresh), so the bench also prints what the scripts cost and
		# the GPU and render-thread time of the 3D view.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		RenderingServer.viewport_set_measure_render_time(sv.get_viewport_rid(), true)
		if probe:
			_bench_settle = 240


## Traffic, trams, pedestrians and the rivals, all on the lane graph baked into
## the map data; the speech bubbles live in the HUD.
func _build_life(data: Dictionary, world: Node3D) -> void:
	var t0 := Time.get_ticks_msec()
	traffic = Traffic.new()
	traffic.race_debug = race_debug
	traffic.count_overlaps = _traffic_overlaps
	world.add_child(traffic)
	traffic.setup(graph, map, cam, data)
	traffic.player_pos = car.global_position
	car.bumped.connect(traffic.on_player_bump)
	trams = Trams.new()
	world.add_child(trams)
	trams.setup(graph, map, data)
	trams.traffic = traffic
	traffic.trams = trams
	_first_scene_trams()
	trains = Trains.new()
	world.add_child(trains)
	trains.setup(map, data)
	# The railway audit (2026-11-07): the trains' rumble, horn and platform gong.
	trains.sfx = sfx
	if train_at != Vector2.INF:
		trains.place_near(train_at, train_kind)
	walkers = Pedestrians.new()
	world.add_child(walkers)
	walkers.setup(map, cam, traffic, data)
	# First scene item 6: busier pavements on Marszałkowska by the start.
	var busy := walkers.set_busy(FirstScene.FRAME_O, FirstScene.FRAME_S, FirstScene.FRAME_T, FirstScene.BUSY_BANDS, FIRST_SCENE)
	print("first scene: %d busy pavement points" % busy)
	# F's LIM photos (2026-11-06): the pavement under Centrum LIM's arcade and the Dworzec Centralny
	# tram stop in front of it, busy at every hour.
	busy = walkers.add_busy(LIM_BUSY_O, LIM_BUSY_S, LIM_BUSY_T, LIM_BUSY_BANDS, LIM_BUSY_BOX)
	print("centrum lim: %d busy pavement points" % busy)
	traffic.bumped_driver.connect(dialogue.on_driver_bumped)
	traffic.blocked_by_player.connect(dialogue.on_driver_blocked)
	rivals = Rivals.new()
	add_child(rivals)
	rivals.autopilot = autopilot
	if ghost_pace > 0.0:
		rivals.ghost_pace = ghost_pace
	rivals.wallet = wallet
	rivals.tod = tod  # loop 3h slice 3: the final waits for the night
	rivals.setup(graph, traffic, hud, bubbles, missions, map, world, car, data)
	if ladder_flag >= 0 or trzy_mosty_flag:
		rivals.preset_ladder(ladder_flag if ladder_flag >= 0 else Ladder.RUNGS.size())  # loop 3h slice 3
	print("living city: %d lanes, %d trams in %d ms" % [graph.lane_count, trams.trams.size(), Time.get_ticks_msec() - t0])
	if bench:
		_clear_bench_result()
		var p := Vector2(car.global_position.x, car.global_position.z)
		var hit := graph.snap(p, 60.0, Vector2(-sin(car.rotation.y), -cos(car.rotation.y)), true)
		if not hit.is_empty():
			_bench_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])


## First scene items 4-5 (first_scene.gd): the street furniture on Marszałkowska's east
## pavement by the start, on both city paths.
func _build_first_scene(world: Node3D) -> void:
	if solo_site != "":
		return
	var fs := FirstScene.new()
	fs.name = "FirstScene"
	fs.map = map
	world.add_child(fs)
	fs.build()


## Skwer Linearny na Złotej (skwer_zlota.gd): the linear park's furniture, on both city paths.
func _build_skwer_zlota(world: Node3D) -> void:
	if solo_site != "":
		return
	var sz := SkwerZlota.new()
	sz.name = "SkwerZlota"
	sz.map = map
	world.add_child(sz)
	sz.build()


## The 3D corner screen at Złote Tarasy (tarasy_screen.gd), on both city paths.
func _build_tarasy_screen(world: Node3D) -> void:
	if solo_site != "":
		return
	var ts := TarasyScreen.new()
	ts.name = "TarasyScreen"
	ts.map = map
	world.add_child(ts)
	ts.build()


## The Warsaw Spire's moving parts (spire_motion.gd): the crown's LED ticker and the plaza's jets,
## on both city paths.
func _build_spire_motion(world: Node3D) -> void:
	if solo_site != "" and solo_site != "spire":
		return
	var sm := SpireMotion.new()
	sm.name = "SpireMotion"
	sm.map = map
	world.add_child(sm)
	sm.build()


## Street details along the main line (street_details.gd): kiosks, stalls, cafés, planters and
## stop kits on the pavements of the streets the main line uses, on both city paths.
func _build_street_details(world: Node3D) -> void:
	if solo_site != "":
		return
	var sd := StreetDetails.new()
	sd.name = "StreetDetails"
	sd.map = map
	world.add_child(sd)
	sd.build()


## The Ratusz Arsenał interchange (ratusz_hub.gd, F's photos 2026-11-07): the arched tram canopies,
## their benches and boards, the round stone tower and its railings, on both city paths.
func _build_ratusz_hub(d: Dictionary, world: Node3D) -> void:
	if solo_site != "":
		return
	var hub := RatuszHub.new()
	hub.name = "RatuszHub"
	hub.map = map
	world.add_child(hub)
	hub.build(d)


## Park details (park_details.gd): the pieces of Ogród Saski, Ogród Krasińskich and Park
## Ujazdowski, on both city paths.
func _build_park_details(world: Node3D) -> void:
	if solo_site != "":
		return
	var pd := ParkDetails.new()
	pd.name = "ParkDetails"
	pd.map = map
	world.add_child(pd)
	pd.build()


## First scene (docs/design/first-scene.md item 6): a start on Marszałkowska between
## Świętokrzyska and the Eastern Wall's stores puts a tram in the first frame: one northbound
## rolling up from behind the car (it passes in the first seconds), one southbound coming down
## the street ahead. They are two of the city's trams, taken from where they were.
## 2026-11-02 (items 6-7): placed again when play begins (the title's tap starts the fly-in or the
## opening flyover, a camera cut), `lead` seconds earlier along their rails, so they are where the
## first frame wants them when the camera reaches the car, not long gone while the title was up;
## the first of them to pass the car rings its bell (trams.gd greet).
const FIRST_SCENE := Rect2(-1080.0, -160.0, 200.0, 420.0)
## F's LIM photos (2026-11-06): Centrum LIM's street face (its west corner, along it eastwards,
## out towards Aleje Jerozolimskie) and the busy bands [s0, s1, t0, t1] in that frame: the arcade
## and the pavement, then the Dworzec Centralny tram platforms; the box where the boost applies.
const LIM_BUSY_O := Vector2(-1427.8, 702.2)
const LIM_BUSY_S := Vector2(0.946, -0.325)
const LIM_BUSY_T := Vector2(-0.325, -0.946)
const LIM_BUSY_BANDS := [[-15.0, 160.0, -7.0, 14.0], [-45.0, 70.0, 14.0, 45.0]]
const LIM_BUSY_BOX := Rect2(-1480.0, 600.0, 230.0, 130.0)
const MARSZALKOWSKA_NORTH := Vector2(-0.349, -0.937)
const FIRST_UP_V := 7.0
const FIRST_DOWN_V := 8.0
## How long the first seconds' bell may wait for a tram to pass the car, after the camera lands.
const FIRST_BELL_S := 20.0
func _first_scene_trams(lead := 0.0) -> void:
	var at := Vector2(car.global_position.x, car.global_position.z)
	if flying or not FIRST_SCENE.has_point(at) or trams == null or trams.trams.size() < 2:
		return
	var up_ok := trams.place_near(trams.trams[0], at, -18.0 - FIRST_UP_V * lead, MARSZALKOWSKA_NORTH, FIRST_UP_V)
	var down_ok := trams.place_near(trams.trams[1], at + MARSZALKOWSKA_NORTH * (110.0 + FIRST_DOWN_V * lead), 0.0,
			-MARSZALKOWSKA_NORTH, FIRST_DOWN_V)
	var greet: Array[Trams.Tram] = []
	if up_ok:
		greet.append(trams.trams[0])
	if down_ok:
		greet.append(trams.trams[1])
	trams.greet(greet, lead + FIRST_BELL_S)
	print("first scene: trams up %s, down %s, %.1f s ahead of the first frame" % [up_ok, down_ok, lead])


## v0.9: the sound (sfx.gd), fed by the car's knocks, the trams' bells, the drivers'
## horns, the pigeons and the jars.
func _build_sound(data: Dictionary, world: Node3D) -> void:
	sfx = Sfx.new()
	sfx.car = car
	sfx.heli = heli
	sfx.tod = tod
	sfx.weather = weather
	sfx.radio = radio
	sfx.square_box = FIRST_SCENE  # first scene item 7: the square's talk at the start
	world.add_child(sfx)
	sfx.setup(data)
	car.impact.connect(sfx.impact)
	# G13b: the nitro lights with a whoosh and a short strong buzz.
	car.nitro_started.connect(func() -> void:
		sfx.play_at("nitro_whoosh", car.global_position)
		Access.buzz(90, 0.8))
	if trams != null:
		trams.bell.connect(sfx.tram_bell)
	if traffic != null:
		traffic.blocked_by_player.connect(func(d): sfx.horn(d.pos))
		traffic.bumped_driver.connect(func(d): sfx.horn(d.pos))
	if eggs != null:
		eggs.flushed.connect(sfx.pigeons)
	if jobs != null:
		jobs.jars.connect(sfx.jars)
	# Loop MW-5: the city's sounds at the notebook's places (the clubs, the metro, the bells, the
	# busker, the 02:00 beat), heard by sfx.gd's listener.
	if notes != null and notes.ready_ok:
		city_sounds = CitySounds.new()
		city_sounds.name = "CitySounds"
		city_sounds.log_on = radio_log
		city_sounds.radio = radio
		city_sounds.sfx = sfx
		world.add_child(city_sounds)
		city_sounds.setup(notes.places, func(x: float, z: float) -> float: return map.ground_height(x, z))
		city_sounds.clock = tod.local_clock
		city_sounds.ear = func() -> Vector3: return cam_focus
	if sound_check:
		missions.close()
		sfx.sound_check()


## Quality (U, Settings, --quality=): loop G1: Auto (Tiers.AUTO: the level Auto picked for this
## device) or Low, Medium, High, Ultra. The governor starts again from the top.
func _set_quality(choice: int) -> void:
	quality_choice = clampi(choice, Tiers.AUTO, Tiers.ULTRA)
	quality = auto_quality if quality_choice == Tiers.AUTO else quality_choice
	if settings.quality != quality_choice and _started:
		settings.quality = quality_choice
		settings.save()
	var qs: Dictionary = QUALITY[quality]
	tod.shadows_allowed = qs["shadows"]
	tod.glow_allowed = qs["glow"]
	if crowds != null:
		crowds.amount = _crowd_scale()
		crowds.refresh()
	if packs != null:
		packs.amount = _crowd_scale()
	if fans != null:
		fans.amount = _crowd_scale()
	if wellness != null:
		wellness.amount = _crowd_scale()
	if life != null:
		life.amount = float(life_flag) * (0.5 if quality == Tiers.LOW else 1.0)
	RenderingServer.directional_shadow_atlas_set_size(qs["shadow_size"], true)
	tod.refresh()
	weather.density = qs["rain"]
	weather.refresh()
	governor.restart(_clock_s())
	_apply_extras()
	if hud != null:
		_apply_style()


## Loop G1: the quality's extras as they are now: the level's own, less what the governor took
## (governor.gd: GPU, mirror-reflection steps and then the small things' sun shadows; CPU,
## traffic and pedestrians), and in a wide view or flying no small things' shadows (the fixed
## view rule, WIDE_VIEW). Never the pixel size, the shadow map, glow, landmarks, the ghost, the
## river or the night lights.
func _apply_extras() -> void:
	var qs: Dictionary = QUALITY[quality]
	post_mat.set_shader_parameter("reflect_steps", ceili(int(qs["reflect"]) * float(Governor.REFLECT[governor.gpu])))
	var cast: bool = qs["small_shadows"] and Governor.SMALL_SHADOWS[governor.gpu] and not _wide
	if int(cast) != _small_cast:
		_small_cast = int(cast)
		get_tree().call_group(MapBuilder.SMALL_CASTERS, "set_cast_shadows_setting",
				GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_apply_traffic()


## Loop 2a: traffic = the level (Settings → Traffic) × the quality's share; the
## pedestrians follow the level more gently (settings.gd PEOPLE). Loop G1: × what the governor's
## CPU level keeps.
func _apply_traffic() -> void:
	if traffic != null:
		var density := float(Settings.TRAFFIC[traffic_level]) * float(QUALITY[quality]["traffic"]) * float(Governor.TRAFFIC[governor.cpu])
		if not is_equal_approx(traffic.density, density):
			traffic.density = density
	if walkers != null:
		walkers.limit = maxi(4, roundi(float(QUALITY[quality]["people"]) * float(Settings.PEOPLE[traffic_level]) * float(Governor.PEOPLE[governor.cpu])))


## Loop G1: the governor's clock, seconds since the game started.
func _clock_s() -> float:
	return Time.get_ticks_msec() / 1000.0


## Loop G1: once a frame (in the game loop's own time): the fixed view rule and the governor (fed
## the last frame's time and CPU work from bench.gd), held where it should be.
func _govern() -> void:
	var wide := flying or cam.size > (WIDE_VIEW * 0.9 if _wide else WIDE_VIEW)
	if wide != _wide:
		_wide = wide
		print("governor: view %s (%.0f m%s) · small things' sun shadows %s" % ["wide" if wide else "back in",
				cam.size, ", flying" if flying else "", "off" if wide else "as the quality sets them"])
		_apply_extras()
	governor.held = not _governor_on or title != null or _phone_bench or ((bench or probe) and _flag_governor != 1)
	governor.frame(_stats.last_ms, _stats.last_cpu)
	var now := _clock_s()
	var line := governor.tick(now, _wide)
	if line != "":
		print("%s · at %.1f s" % [line, now - _stress_t0 / 1000.0])
		_apply_extras()
	# Loop G1b: the session's verdict on Auto's image (cheap until one is due); with
	# --governor=log the tally's minutes too.
	if governor.track and _image_verdict != "struggled" and (governor.struggled()
			or (_image_verdict == "" and governor.calm())):
		_image_session_verdict()
	if governor.minute_line != "":
		if _governor_log:
			print("governor %s · at %.1f s" % [governor.minute_line, now - _stress_t0 / 1000.0])
		governor.minute_line = ""
	if _governor_log and now >= _governor_log_next:
		_governor_log_next = now + GOVERNOR_LOG_EVERY
		print("governor status: %s · %.1f%% of refreshes missed in the last %.0f s · at %.1f s%s%s%s" % [governor.state(),
				governor.late_share * 100.0, Governor.WINDOW, now - _stress_t0 / 1000.0, " · held" if governor.held else "",
				" · stress on" if _stressing() else "", " · " + governor.tally() if governor.track else ""])


# --- Loop G1b: Auto's sharp image and its fallback ---------------------------------------------
## "sharp" or "fallback" where Auto's rule decides the image (Auto, the level's budget binds at
## this screen and style, no --lines=), else "".
func _image_mode() -> String:
	if quality_choice != Tiers.AUTO or lines_override > 0:
		return ""
	var screen := get_viewport().get_visible_rect().size
	if not Tiers.budget_binds(screen, STYLES[style_index]["lines"], quality):
		return ""
	return "sharp" if auto_sharp else "fallback"


## 2026-10-30: the first launch at Auto's fallback says so once, with a toast when the city
## shows (the Obraz tab's `auto · High ×2` and the `quality:` line said it before, nothing on
## the driving screen). `told` goes into the saved state at once, so the next launch at the
## fallback stays quiet even if this session never reaches its verdict.
func _fallback_toast() -> void:
	if _image_mode() != "fallback" or bool(auto_image["told"]) or not shots.is_empty():
		return  # screenshots stay clean
	# Two frames on: the first frame after the build has the build's whole time as its delta,
	# which would use up the toast's seconds at once.
	await get_tree().process_frame
	await get_tree().process_frame
	hud.toast("Obraz prostszy, żeby było płynnie", "A coarser picture for a smoother ride · Settings → Obraz")
	print("quality: the fallback's toast shown")
	auto_image["told"] = true
	if _image_write and settings.persistent:
		settings.auto_image["told"] = true
		settings.save()


## The session struggled or was calm at Auto's image: the state the next launch starts from
## (computed from this launch's own, so a struggle after a calm verdict replaces it), written
## when this run may (a normal launch without --nosave or --last-session=), and a `quality:` line.
func _image_session_verdict() -> void:
	var sharp := auto_sharp
	var next: Dictionary
	var what := ""
	if governor.struggled():
		_image_verdict = "struggled"
		what = "struggled (%s)" % governor.struggle()
		next = Tiers.sharp_struggled(auto_image, sharp, governor.struggle())
	else:
		_image_verdict = "calm"
		what = "was calm"
		next = Tiers.sharp_calm(auto_image, sharp)
	var saved := _image_write and settings.persistent
	if saved:
		settings.auto_image = next
		settings.save()
	print("quality: this session at %s ×%d %s %s · %s · the next launch: %s%s" % [QUALITY[quality]["name"],
			view.stretch_shrink, "sharp" if sharp else "fallback", what, governor.tally(),
			"sharp" if not Tiers.sharp_launch(next)["fallback"] else "fallback (calm %d of %d before the sharp image again)" % [
			next["calm"], next["wait"]], "" if saved else " (not saved: %s)" % ("--nosave" if not settings.persistent else "a test run or --last-session=")])
# --- end loop G1b --------------------------------------------------------------------------------


## Loop G1, --stress: inside the load's time window (seconds after the city is up).
func _stressing() -> bool:
	var t := (Time.get_ticks_msec() - _stress_t0) / 1000.0
	return _stress_n > 0 and t >= _stress_from and t < _stress_to


func _busy(n: int) -> void:
	var end := Time.get_ticks_usec() + n * 500
	while Time.get_ticks_usec() < end:
		pass


func _stress_wait() -> void:
	if _stressing():
		_busy(_stress_n)


## The performance overlay (P, a three-finger tap, --perf): GPU time needs the
## viewport's render-time measurement on.
func _set_perf(on: bool) -> void:
	show_perf = on
	RenderingServer.viewport_set_measure_render_time(sv.get_viewport_rid(), on or bench or probe or _phone_bench)
	hud.show_perf(on and not _phone_bench)
	_perf_wait = 0.0


## Twice a second (loop 2b; four times before, with a timestamp every frame): fps, frame time
## and the worst frame since the last update, the main thread's split (physics, process, draw;
## bench.gd times them from the engine's frame signals: Godot's own "process" monitor is the
## slowest whole frame of the last second, rendering included), the 3D view's GPU time (not on
## Metal), draw calls by pass (the pixel image's 3D and shadow passes, the 2D one), objects,
## triangles, memory, the image size, time and weather, the frame-rate cap.
func _update_perf(dt: float) -> void:
	_perf_wait -= dt
	if _perf_wait > 0.0:
		return
	_perf_wait = PERF_EVERY
	var live := _stats.take_live()
	var p := _stats.passes()
	var gpu := RenderingServer.viewport_get_measured_render_time_gpu(sv.get_viewport_rid())
	# Loop 2e: four short lines (11 pt on the phone) so the overlay fits beside the HUD's
	# panels; the time of day and the weather are on screen anyway, memory is in the BENCH card.
	# Loop G1: the last line is the quality, its pixel scale and the governor's levels (objects
	# and the shadow pass's triangles are on the BENCH card).
	var lines := PackedStringArray([
		"%.0f fps · %.1f ms · worst %.1f · cap %s" % [1000.0 / maxf(live["ms"], 0.01), live["ms"], live["worst"], _cap_name()],
		"CPU %.1f + %.1f + %.1f ms · GPU %s · %.0f MB" % [live["process"], live["physics"], live["draw"],
				"%.2f" % gpu if gpu > 0.0 else "n/a", Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0],
		"draws %d = %d + %d + %d · %.2f M tris" % [p["all_draws"], p["main_draws"], p["shadow_draws"], p["canvas_draws"],
				p["all_tris"] / 1e6],
		# Loop G1b: "High ×1 sharp" / "High ×2 fallback" where Auto's rule decides the image.
		"%s ×%d%s · gov %s%s" % [QUALITY[quality]["name"], view.stretch_shrink, (" " + _image_mode()).rstrip(" "),
				governor.state(), " · wide" if _wide else ""],
	])
	hud.set_perf("\n".join(lines))


## Loop 2b: the frame-rate cap: Settings (60 or 30, saved), --fps=N for one run, none for the
## bench and probe flags. On iOS project.godot keeps the display at 60 Hz
## (display/window/ios/allow_high_refresh_rate = false: a ProMotion phone would run at 120 and
## warm up), and 60 is left to it: measured on an iPhone 16 Pro Max, Engine.max_fps = 60 on top
## of it paced worse (7.8 % of frames a little late against 4.6 %); 30 uses Engine.max_fps.
func _apply_fps() -> void:
	var cap: int = settings.fps
	if _flag_fps >= 0:
		cap = _flag_fps
	if bench or probe or DisplayServer.get_name() == "headless":
		cap = 0
	_cap = cap
	Engine.max_fps = 0 if cap == 60 and OS.has_feature("ios") else cap
	# Loop G1: a frame is late against the cap's interval (60 fps when uncapped).
	governor.interval_ms = 1000.0 / (cap if cap > 0 else 60)
	governor.reset(_clock_s())


func _cap_name() -> String:
	return "%d fps" % _cap if _cap > 0 else "off"


## The bench's header lines: when, the device, the screen and image, the settings.
func _bench_header(kind: String) -> PackedStringArray:
	var screen := get_viewport().get_visible_rect().size
	var hz := DisplayServer.screen_get_refresh_rate()
	return PackedStringArray([
		"%s bench (loop 2b) · %s · %s" % [Title.WORDMARK, kind, Time.get_datetime_string_from_system(false, true)],
		"device %s · %s %s · %s (%s, %s) · %s" % [OS.get_model_name(), OS.get_name(), OS.get_version(),
				RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_driver_name(),
				RenderingServer.get_current_rendering_method(), OS.get_processor_name()],
		"screen %dx%d @ %.0f Hz · image %dx%d (×%d) · view %.0f m · quality %s · traffic %s · %s · %s · cap %s · %s" % [
				screen.x, screen.y, hz, sv.size.x, sv.size.y, view.stretch_shrink, base_size,
				Tiers.describe(quality_choice, quality, model_name, 0, _image_mode()),
				Settings.TRAFFIC_NAMES[traffic_level], TimeOfDay.NAMES[tod.mode], Weather.NAMES[weather.state],
				_cap_name(), Controls.NAMES[controls.scheme]],
		"thermal state: not readable from Godot; a phone that warms up shows it as falling fps per 10 s",
	])


## The performance lane (2026-10-30): a bench starts by removing the last one's result, so a run
## that ends before its card (a crash, a quit) leaves no file and tools/device_run.sh copies none
## (it used to copy whatever an earlier bench had left).
func _clear_bench_result() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://bench_result.txt"))


## Loop 2b: the bench's result also goes to user://bench_result.txt (on the iPhone the app's
## Documents folder), not the save or the settings.
func _write_bench_result(text: String) -> void:
	var f := FileAccess.open("user://bench_result.txt", FileAccess.WRITE)
	if f != null:
		f.store_string(text + "\n")
		f.close()
		print("bench: result written to %s" % ProjectSettings.globalize_path("user://bench_result.txt"))


## Loop G1: the governor's line on the card: its levels, whether it was held for the run (the
## run then measures the quality's own cost), the view rule's state, its changes so far.
func _governor_notes() -> PackedStringArray:
	var how := "held" if governor.held else ("on" if _governor_on else "off")
	return PackedStringArray(["governor %s: %s%s, %d changes" % [how, governor.state(), ", wide" if _wide else "",
			governor.changes]])


## Loop G1: loop 2b's late measure (0.5 ms past the interval), in the log only, so a card from
## before G1 compares.
func _print_old_late(r: Dictionary) -> void:
	print("bench: %.1f%% of frames over %.1f ms (the measure before loop G1)" % [r["old_over"],
			r["budget"] + BenchStats.OLD_MARGIN])
	print("bench: %s" % _stats.late_detail(r["budget"]))


## Loop 2b, the BENCH button: the car rides the bench route's ghost driver from the spawn at
## the default view for PHONE_SETTLE + PHONE_SECONDS, at the current settings and frame-rate
## cap; the wallet is put back as it was and not saved (like --nosave), the car where it was.
func _start_phone_bench() -> void:
	if _phone_bench or not _started or title != null or bench or probe:
		return
	var busy := ""
	if flying:
		busy = "Najpierw wyląduj · Land first"
	elif rivals != null and rivals.racing():
		busy = "Najpierw skończ wyścig · Finish the race first"
	elif jobs != null and jobs.busy():
		busy = "Najpierw skończ zlecenie · Finish the job first"
	elif missions.has_target():
		busy = "Najpierw skończ akcję · Finish the rescue first"
	elif traffic == null or graph == null:
		busy = "Bez ruchu nie ma trasy · No traffic, no route"
	var hit := []
	if busy == "":
		var yaw := _spawn.basis.get_euler().y
		hit = graph.snap(Vector2(_spawn.origin.x, _spawn.origin.z), 60.0, Vector2(-sin(yaw), -cos(yaw)), true)
		if hit.is_empty():
			busy = "Brak trasy · No route"
	if busy != "":
		hud.toast(Lang.split(busy))
		return
	_phone_saved = {"at": car.global_transform, "mask": car.collision_mask, "size": base_size, "pitch": camera_pitch,
			"wallet": [wallet.zl, wallet.respect, wallet.jobs.duplicate(true), wallet.best.duplicate(true),
					wallet.eggs.duplicate(true), wallet.district_jobs.duplicate(true), wallet.ladder.duplicate(true)], "persistent": wallet.persistent,
			"calls": missions.paused}
	wallet.persistent = false
	# Loop G1: no rescue call comes in during the minute (its clock waits, as during a race): the
	# first call, 60 s into play, landed inside it and was the card's worst frame (61 ms on the
	# iPhone 11, 100-117 ms on the Pro Max).
	missions.paused = true
	hud.hide_bench_card()
	moments.stop()
	base_size = FollowCamera.DEFAULT_SIZE
	camera_pitch = -FollowCamera.DEFAULT_PITCH  # the bench's numbers at the game's look, whatever the player chose
	car.global_transform = _spawn
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	cam_focus = car.global_position
	_bench_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])
	_phone_bench = true
	_clear_bench_result()
	_set_perf(show_perf)
	_stats.header = _bench_header("BENCH button")
	_bench_t0 = Time.get_ticks_msec()
	_measure_t0 = 0
	_phone_next_toast = _bench_t0
	print("bench: BENCH started (%.0f s settle + %.0f s measured, cap %s)" % [PHONE_SETTLE, _phone_seconds, _cap_name()])


func _phone_bench_frame() -> void:
	var now := Time.get_ticks_msec()
	var elapsed := (now - _bench_t0) / 1000.0
	if _measure_t0 == 0:
		if elapsed >= PHONE_SETTLE:
			_measure_t0 = now
			_stats.start()
	else:
		_stats.sample()
	if now >= _phone_next_toast:
		_phone_next_toast += 1000
		hud.toast("TEST %d s · nie dotykaj, proszę" % ceili(PHONE_SETTLE + _phone_seconds - elapsed), "hands off")
	if elapsed >= PHONE_SETTLE + _phone_seconds:
		_end_phone_bench(true)


func _end_phone_bench(done: bool) -> void:
	_phone_bench = false
	if _bench_ghost != null:
		traffic.remove(_bench_ghost)
		_bench_ghost = null
	car.global_transform = _phone_saved["at"]
	car.collision_mask = _phone_saved["mask"]
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	cam_focus = car.global_position
	base_size = _phone_saved["size"]
	camera_pitch = _phone_saved["pitch"]
	var w: Array = _phone_saved["wallet"]
	wallet.zl = w[0]
	wallet.respect = w[1]
	wallet.jobs = w[2]
	wallet.best = w[3]
	wallet.eggs = w[4]
	wallet.district_jobs = w[5]  # loop 3h slice 1
	wallet.ladder = w[6]  # loop 3h slice 3
	wallet.persistent = _phone_saved["persistent"]
	missions.paused = _phone_saved["calls"]
	hud.set_wallet(wallet.zl, wallet.respect)
	_set_perf(show_perf)
	if not done or _measure_t0 == 0:
		hud.toast("Test przerwany", "Bench cancelled")
		print("bench: BENCH cancelled")
		return
	var r := _stats.report(1000.0 / (_cap if _cap > 0 else 60))
	_stats.notes = _governor_notes()
	var text := _stats.text(r)
	for line in text.split("\n"):
		print("bench detail: %s" % line)
	_print_old_late(r)
	_write_bench_result(text)
	hud.show_bench_card(text)


## The side jobs (kebab stands, the słoiki run) and the easter eggs.
func _build_side_jobs(data: Dictionary, world: Node3D) -> void:
	var nodes := {"hud": hud, "bubbles": bubbles, "dialogue": dialogue, "wallet": wallet, "missions": missions,
			"rivals": rivals, "graph": graph, "traffic": traffic, "map": map, "car": car, "tod": tod}
	jobs = Jobs.new()
	jobs.autopilot = autopilot
	jobs.craft_plain = craft_plain
	if start_heat >= 0.0:
		jobs.start_heat = start_heat
	add_child(jobs)
	jobs.setup(nodes, data, world)
	if rivals != null:
		rivals.jobs = jobs
	# --- loop 2d-1: Podwózka, the app-taxi side job (and the GPS moments of the app-taxis) ---
	rides = Rides.new()
	rides.autopilot = autopilot
	rides.ignore_app = ignore_app
	rides.log_on = parody_log
	rides.force_quirk = ride_quirk
	rides.force_passenger = ride_passenger
	rides.force_story = ride_story
	rides.force_answer = ride_answer
	rides.start_stars = ride_stars
	rides.gps_first = gps_in
	add_child(rides)
	nodes["jobs"] = jobs
	nodes["weather"] = weather
	rides.setup(nodes, data, world)
	jobs.rides = rides
	# --- end loop 2d-1 ---
	eggs = Eggs.new()
	eggs.day = barrier_day
	eggs.force_street = barrier_force
	world.add_child(eggs)
	eggs.setup(nodes, data)


# --- loop MW-1: MOJA WARSZAWA, the notebook --------------------------------------------------

## The notebook (notebook.gd): the places put on the map once, found at 2 Hz through `probe`,
## kept in the wallet's save; its page is the settings card's fifth tab. --found= presets the
## record (in memory), --place= puts the car at a place.
func _build_notebook(data: Dictionary) -> void:
	notes = Notebook.new()
	notes.name = "Notebook"
	notes.wallet = wallet
	notes.hud = hud
	notes.log_on = notes_log
	notes.blip = _blip_sound
	add_child(notes)
	if not notes.setup(data, notes_log):
		return
	hud.settings_panel.notebook = notes
	if found_spec != "":
		notes.preset(found_spec)
	# Loop MW-5: a chapter finished opens the next PÓŁNOC FM track (and --found= presets do too).
	radio.sync_chapters()
	notes.chapter_done.connect(func(_id: String) -> void: radio.sync_chapters())
	notes.probe = func() -> Array:
		# Not on the title screen or during TEST · BENCH (its wallet is put back after); --bench's
		# route does find places, so its scripts' time includes the checks.
		var away := title != null or _phone_bench
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true, heli.height_above, away]
		return [car.global_position, car.vel.length() * 3.6, false, 0.0, away]
	if place_flag != "":
		_put_at_place(place_flag)


# --- loop MW-2: storefronts and parodies ------------------------------------------------------

## The storefronts (storefronts.gd) on the notebook's places and the lane graph; their walls come
## when each sector is in (_on_sector_ready). None with --no-parodies.
func _build_storefronts(data: Dictionary, world: Node3D) -> void:
	if no_parodies or notes == null or not notes.ready_ok or graph == null:
		return
	storefronts = Storefronts.new()
	storefronts.name = "Storefronts"
	storefronts.map = map
	storefronts.graph = graph
	storefronts.dialogue = dialogue
	storefronts.hud = hud
	storefronts.wallet = wallet
	storefronts.sfx = sfx
	storefronts.egg_book = egg_book
	storefronts.jobs = jobs
	storefronts.eggs = eggs
	storefronts.car = car
	storefronts.log_on = parody_log
	storefronts.rig_rechotka = rechotka_flag
	storefronts.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	storefronts.lit = func() -> bool: return tod != null and tod.lights_on > 0.001
	storefronts.fine_shown = func() -> bool: return _fine_shown
	world.add_child(storefronts)
	storefronts.setup(data, notes.places)
	if stamps_flag >= 0:
		storefronts.preset_stamps(stamps_flag)
	if rides != null:
		rides.frogs = storefronts
	# "Dżemini" (trend_job.gd): the MLASK sticker goes on DŻEMINI KEBAB's wall.
	if trend_job != null:
		trend_job.storefronts = storefronts
	# Loop jobs-2: the Leżak round-up, at the zones storefronts.gd painted (jobs.gd steps it).
	if jobs != null:
		var ru := RoundupJob.new()
		ru.name = "RoundupJob"
		ru.hud = hud
		ru.dialogue = dialogue
		ru.wallet = wallet
		ru.missions = missions
		ru.map = map
		ru.car = car
		ru.tod = tod
		ru.jobs = jobs
		ru.store = storefronts
		ru.autopilot = autopilot
		ru.force = roundup_flag
		ru.log_on = parody_log or roundup_flag
		ru.set_process(false)
		jobs.add_child(ru)
		ru.setup(world)
		jobs.roundup = ru
		if roundup_flag:
			ru.start_at_nearest()
			cam_focus = car.global_position


# --- loop MW-3: the night and the river's crowds --------------------------------------------

## The crowds (crowds.gd) at the notebook's places, after the police (their cars by the clubs)
## and the city's sounds (the crowds' murmur and the guitar). None with --crowd=0 or without the
## notebook's places.
func _build_crowds(data: Dictionary, world: Node3D) -> void:
	if crowd_flag == 0 or notes == null or not notes.ready_ok:
		return
	crowds = Crowds.new()
	crowds.name = "Crowds"
	crowds.map = map
	crowds.dialogue = dialogue
	crowds.police = police
	crowds.sounds = city_sounds
	crowds.log_on = night_log
	crowds.amount = _crowd_scale()
	crowds.meet_on = loud_flag != 0
	crowds.clock = tod.local_clock
	crowds.focus = func() -> Vector3: return cam_focus
	crowds.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	if traffic != null:
		crowds.on_screen = traffic.on_screen
	crowds.calendar = _crowd_calendar
	# The garage loop: the car's paint at the doors, and E01 at Lusterko's.
	crowds.paint = func() -> String: return str(wallet.paint)
	crowds.egg = func(id: String) -> bool: return egg_book != null and egg_book.fire(id, _egg_state())
	world.add_child(crowds)
	crowds.setup(notes.places, data)
	tod.changed.connect(func(_m: int) -> void: crowds.refresh())
	# The crowds' sounds: each queue's and the steps' murmur, the guitarist.
	if city_sounds != null:
		for st: Dictionary in crowds.sites:
			var site := st
			if site["kind"] in ["queue", "steps", "plan_c", "chill", "office"]:
				var at: Vector2 = site["door"]
				city_sounds.add_crowd(str(site["id"]), "murmur", Vector3(at.x, map.ground_height(at.x, at.y), at.y),
						func() -> bool: return int(site["n"]) >= 4)
			if site["kind"] == "jazz_cafe":
				var at: Vector2 = site["door"]
				city_sounds.add_crowd(str(site["id"]), "murmur", Vector3(at.x, map.ground_height(at.x, at.y), at.y),
						func() -> bool: return int(site["n"]) >= 4)
			if site["kind"] == "jazz":
				var sc: Vector2 = site["at"]
				city_sounds.add_crowd(str(site["id"]), "jazz", Vector3(sc.x, map.ground_height(sc.x, sc.y), sc.y),
						func() -> bool: return int(site["n"]) > 0)
			if site["kind"] == "steps":
				var g: Vector2 = site["guitar"]
				city_sounds.add_crowd(str(site["id"]), "guitar", Vector3(g.x, map.ground_height(g.x, g.y), g.y),
						func() -> bool: return bool(site.get("guitar_on", false)))
	# Podwózka at dawn: requests from the club doors.
	if rides != null:
		rides.club_doors = func() -> Array:
			var out: Array = []
			if crowds.dawn_on:
				for st: Dictionary in crowds.sites:
					if bool(st.get("dawn", false)):
						out.append([st["id"], st["door"]])
			return out
	if club_flag != "":
		_put_at_club(club_flag)


# --- the garage loop ---------------------------------------------------------------------------

## The first-10 polish: a run that will get the guide (a normal launch or --first10 on a fresh
## save, with no other start asked for) starts at First10.START, facing north up Marszałkowska to
## the first stand. Set before the city is built, so the sectors round it come in first.
func _guide_start() -> void:
	if start_at != Vector3.INF or start_heading != INF or not (first10_flag or show_title):
		return
	if not First10.guide_due(wallet):
		return
	start_at = Vector3(First10.START.x, 0.0, First10.START.y)
	start_heading = First10.START_HEADING


## Loop 3h slice 4: the director of the first 10 minutes and the end card (first10.gd). The guide
## runs in a normal launch on a fresh save, or with --first10; never in other test runs.
## The packs (packs.gd) after the storefronts (the COFFEECHAIR cafés' pavements for the raves).
## None with --packs=0 or --crowd=0.
func _build_packs(data: Dictionary, world: Node3D) -> void:
	if packs_flag == 0 or crowd_flag == 0:
		return
	packs = Packs.new()
	packs.name = "Packs"
	packs.map = map
	packs.dialogue = dialogue
	packs.hud = hud
	packs.log_on = packs_log
	packs.amount = _crowd_scale()
	packs.force = packs_now
	if packs_now:
		packs.force_near = Vector2(car.global_position.x, car.global_position.z)
	packs.clock = tod.local_clock
	packs.focus = func() -> Vector3: return cam_focus
	packs.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	if traffic != null:
		packs.on_screen = traffic.on_screen
	world.add_child(packs)
	packs.setup(data, storefronts.venues if storefronts != null else [])


## The fans by Stadion Leguminy (fans.gd), after the police (the patrol car by the gate) and the
## city's sounds (the chant). None with --fans=0 or --crowd=0.
func _build_fans(data: Dictionary, world: Node3D) -> void:
	if fans_flag == 0 or crowd_flag == 0:
		return
	fans = Fans.new()
	fans.name = "Fans"
	fans.map = map
	fans.dialogue = dialogue
	fans.hud = hud
	fans.police = police
	fans.sounds = city_sounds
	fans.log_on = fans_log
	fans.amount = _crowd_scale()
	fans.force = fans_now
	fans.force_phase = fans_phase
	fans.force_result = fans_result
	fans.clock = tod.local_clock
	fans.focus = func() -> Vector3: return cam_focus
	fans.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	if traffic != null:
		fans.on_screen = traffic.on_screen
	world.add_child(fans)
	fans.setup(data)
	hud.horn_pressed.connect(func() -> void:
		if fans != null and not flying:
			fans.honk(car.global_position))
## City-life satire #1 (loud_cars.gd): the meet at Browary on both city paths, and the loud
## cars in traffic (none with --no-traffic). None at all with --loud=0.
func _build_loud_cars(world: Node3D) -> void:
	if traffic != null:
		traffic.loud_target = loud_flag
	if loud_flag == 0:
		return
	loud_cars = LoudCars.new()
	loud_cars.name = "LoudCars"
	loud_cars.traffic = traffic
	loud_cars.sfx = sfx
	loud_cars.dialogue = dialogue
	loud_cars.radio = radio
	loud_cars.map = map
	loud_cars.log_on = loud_log
	loud_cars.focus = func() -> Vector3: return cam_focus
	world.add_child(loud_cars)
	loud_cars.setup()


## Crazy drivers (crazy_drivers.gd): wild taxis, couriers and the Pasatini in traffic, their
## horns and lines (none with --no-traffic or --crazy=0).
func _build_crazy_drivers(world: Node3D) -> void:
	if traffic == null:
		return
	traffic.crazy_target = crazy_flag
	if crazy_flag == 0:
		return
	crazy_drivers = CrazyDrivers.new()
	crazy_drivers.name = "CrazyDrivers"
	crazy_drivers.traffic = traffic
	crazy_drivers.sfx = sfx
	crazy_drivers.dialogue = dialogue
	crazy_drivers.radio = radio
	crazy_drivers.log_on = crazy_log
	crazy_drivers.focus = func() -> Vector3: return cam_focus
	world.add_child(crazy_drivers)


## The wellness circles (wellness.gd): none with --wellness=0 or --crowd=0.
func _build_wellness(world: Node3D) -> void:
	if wellness_flag == 0 or crowd_flag == 0:
		return
	wellness = Wellness.new()
	wellness.name = "Wellness"
	wellness.map = map
	wellness.dialogue = dialogue
	wellness.sounds = city_sounds
	wellness.hud = hud
	wellness.log_on = wellness_log
	wellness.amount = _crowd_scale()
	wellness.force = wellness_now
	wellness.clock = tod.local_clock
	wellness.focus = func() -> Vector3: return cam_focus
	wellness.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	if traffic != null:
		wellness.on_screen = traffic.on_screen
	world.add_child(wellness)
	wellness.setup()


func _build_first10() -> void:
	first10 = First10.new()
	first10.name = "First10"
	first10.wallet = wallet
	first10.hud = hud
	first10.map = map
	first10.car = car
	first10.jobs = jobs
	first10.rivals = rivals
	first10.missions = missions
	first10.police = police
	first10.tape = tape
	first10.radio = radio
	first10.districts = districts
	first10.garage = garage
	first10.cassettes = cassettes
	first10.flying = func() -> bool: return flying
	first10.scripted = first10_flag and autopilot
	add_child(first10)
	first10.setup(first10_flag or show_title)
	if end_card_flag:
		first10.end_at = 1.0
	if first_race_flag:
		first10.race_at = 1.0


## Warsztat u Mirka (garage.gd): its ring on Brzeska, the car's saved paint (or --paint), the card
## that pauses the game like the settings card.
func _build_garage(world: Node3D) -> void:
	garage = Garage.new()
	garage.name = "Garage"
	garage.wallet = wallet
	garage.hud = hud
	garage.dialogue = dialogue
	garage.car = car
	garage.map = map
	garage.graph = graph
	garage.log_on = garage_log
	if egg_book != null:
		garage.eggs_found = egg_book.found_total
		# E21: the café's `viral` glon line over the green car (E01's line is the bouncer's: crowds.gd).
		egg_book.found.connect(func(id: String) -> void:
			if id == "e21" and dialogue != null:
				dialogue.say(func() -> Vector3: return car.global_position + Vector3(0, 2.2, 0), "Glon", "viral", "glon", 4.5,
						Color("#7ad36a"), 2.2, true))
	garage.busy = func() -> bool:
		return flying or title != null or _phone_bench or hud.settings_open() or hud.full_map_open() \
				or (fotka != null and fotka.is_open()) or missions.has_target() \
				or (jobs != null and jobs.busy()) or (rivals != null and rivals.busy()) \
				or (police != null and not police.calm())
	world.add_child(garage)
	if paint_flag != "":
		garage.preset(paint_flag)
	garage.force = garage_flag
	if garage_parts:
		garage.start_tab = "parts"
	garage.setup(world)
	if upgrades_flag != "":
		garage.preset_upgrades(upgrades_flag)
	garage.upgraded.connect(func(id: String) -> void:
		if id == "nitro":
			hud.toast(Gamepad.fmt("Nitro gotowe: przytrzymaj błyskawicę przy klaksonie (Shift, {lb} / {rb} na padzie)."),
					Gamepad.fmt("Nitro fitted: hold the bolt by the horn (Shift, {lb} / {rb} on a pad).")))
	if garage_flag:
		_put_at_garage()
	garage.opened.connect(func() -> void:
		car.vel = Vector3.ZERO
		car.forward_speed = 0.0
		get_tree().paused = true
		_blip_sound())
	garage.closed.connect(func() -> void:
		get_tree().paused = false
		_blip_sound())


## --garage: the car in the ring, still (the card opens at the garage's next look); --garage=ring:
## 16 m short of it along the lane, facing it.
func _put_at_garage() -> void:
	if garage == null or garage.at == Vector3.INF:
		return
	var lane := _lane_spot(garage.at, car.rotation.y)
	var spot := garage.at
	var yaw := car.rotation.y
	if not lane.is_empty() and Vector2((lane[0] as Vector3).x, (lane[0] as Vector3).z).distance_to(Vector2(garage.at.x, garage.at.z)) < Garage.RING - 1.0:
		spot = lane[0]
		yaw = lane[1]
	if garage_ring_only:
		var back := Vector3(sin(yaw), 0.0, cos(yaw)) * 16.0  # the car's front is -Z
		spot = Vector3(spot.x + back.x, map.ground_height(spot.x + back.x, spot.z + back.z), spot.z + back.z)
	car.global_position = spot
	car.rotation.y = yaw
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	cam_focus = car.global_position
	_cut_camera()
	print("garage: --garage: the car at %.0f, %.0f heading %.0f, %.1f m from the ring's centre" % [spot.x, spot.z,
			_compass_yaw(yaw), Vector2(spot.x, spot.z).distance_to(Vector2(garage.at.x, garage.at.z))])


# --- the night-buses loop ----------------------------------------------------------------------

## The buses (buses.gd) on the traffic's lane graph, after everyday life (the dogs hear the horn);
## the HUD's horn. None with --no-traffic.
func _build_buses(data: Dictionary, world: Node3D) -> void:
	if traffic == null:
		return
	buses = Buses.new()
	buses.name = "Buses"
	buses.traffic = traffic
	buses.graph = graph
	buses.map = map
	buses.walkers = walkers
	buses.dialogue = dialogue
	buses.sfx = sfx
	buses.life = life
	buses.police = police
	buses.egg_book = egg_book
	buses.log_on = bus_log
	buses.clock = tod.local_clock
	buses.focus = func() -> Vector3: return cam_focus
	buses.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	buses.probe = _egg_state
	world.add_child(buses)
	buses.setup(data)
	hud.horn_pressed.connect(func() -> void: buses.honk())
	if night_hub_flag:
		buses.force()


# --- the crash scenes -------------------------------------------------------------------------

## The crash scenes (crash_scenes.gd) on the traffic's lane graph, with the police's cars and the
## pedestrians' scene figures. None with --no-traffic or --crash=0.
func _build_crash_scenes() -> void:
	if traffic == null or crash_flag == "0":
		return
	crash_scenes = CrashScenes.new()
	crash_scenes.name = "CrashScenes"
	crash_scenes.traffic = traffic
	crash_scenes.graph = graph
	crash_scenes.map = map
	crash_scenes.walkers = walkers
	crash_scenes.dialogue = dialogue
	crash_scenes.police = police
	crash_scenes.radio = radio
	crash_scenes.sfx = sfx
	crash_scenes.hud = hud
	crash_scenes.log_on = crash_log
	crash_scenes.enabled = _crash_auto or crash_flag != ""
	crash_scenes.focus = func() -> Vector3: return cam_focus
	crash_scenes.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	add_child(crash_scenes)
	crash_scenes.setup()
	var xz := crash_flag.split(",")
	if crash_flag == "now" or xz.size() == 2:
		var p := car.global_position
		var f := -car.global_transform.basis.z
		var at := Vector2(float(xz[0]), float(xz[1])) if xz.size() == 2 else Vector2.INF
		crash_scenes.place(Vector2(p.x, p.z), Vector2(f.x, f.z).normalized(), true, at)


# --- the boat race ---------------------------------------------------------------------------

## Szymek's call, the start pontoon and the race down the river (boat_race.gd). None with --boat-race=0.
func _build_boat_race(world: Node3D) -> void:
	if boat_flag == "0":
		return
	boat_race = BoatRace.new()
	boat_race.name = "BoatRace"
	boat_race.hud = hud
	boat_race.dialogue = dialogue
	boat_race.wallet = wallet
	boat_race.map = map
	boat_race.car = car
	boat_race.log_on = boat_log
	boat_race.autopilot = autopilot or boat_flag == "auto"
	boat_race.force_hours = boat_flag != ""
	boat_race.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	boat_race.seen = func(p: Vector3) -> bool: return cam.is_position_in_frustum(p)
	boat_race.clock = func() -> float: return life.hour_now() if life != null else 12.0
	boat_race.free_now = _boat_free
	world.add_child(boat_race)
	boat_race.setup(world)
	boat_race.boarded.connect(_on_boat_boarded)
	boat_race.left_boat.connect(_on_boat_left)
	if jobs != null:
		# The free-ride boat's mark on the minimap and the full map, with the job places.
		jobs.boat_spot = BoatRace.fleet_spot(1)
		jobs._show_places(jobs._places_shown, true)
	if boat_flag in ["race", "auto"]:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			var at := BoatRace.CAR_SPOT
			car.global_position = Vector3(at.x, map.ground_height(at.x, at.y), at.y)
			car.reset_physics_interpolation()
			boat_race._board())
	elif boat_flag.begins_with("free") or boat_flag == "marina":
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			var at := BoatRace.CAR_SPOT
			car.global_position = Vector3(at.x, map.ground_height(at.x, at.y), at.y)
			car.reset_physics_interpolation()
			if boat_flag.begins_with("free"):
				boat_race.free_ride(int(boat_flag.trim_prefix("free")) if boat_flag.length() > 4 else 1)
			else:
				boat_race._marina_card())
	elif boat_flag == "call":
		get_tree().create_timer(1.0).timeout.connect(func() -> void: boat_race.ring())


# --- the cinema tour ---------------------------------------------------------------------------

## Wiktor's call and the drive round the cinemas (kino_tour.gd). None with --kino-tour=0.
func _build_kino_tour(world: Node3D) -> void:
	if kino_flag == "0":
		return
	kino_tour = KinoTour.new()
	kino_tour.name = "KinoTour"
	kino_tour.hud = hud
	kino_tour.dialogue = dialogue
	kino_tour.wallet = wallet
	kino_tour.map = map
	kino_tour.car = car
	kino_tour.log_on = kino_log
	kino_tour.autopilot = autopilot or kino_flag == "auto"
	kino_tour.force_hours = kino_flag != ""
	kino_tour.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true, 0.0]
		return [car.global_position, car.vel.length() * 3.6, false, float(car.forward_speed)]
	kino_tour.clock = func() -> float: return life.hour_now() if life != null else 12.0
	kino_tour.free_now = _kino_free
	world.add_child(kino_tour)
	kino_tour.setup(world)
	if kino_flag in ["go", "auto"]:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			var at: Vector2 = KinoTour.PICKUP["at"]
			car.global_position = Vector3(at.x, map.ground_height(at.x, at.y), at.y)
			car.reset_physics_interpolation()
			kino_tour.start())
	elif kino_flag == "call":
		get_tree().create_timer(1.0).timeout.connect(func() -> void: kino_tour.ring())


## Nothing else on, on the ground (the rave's test, no rave and no boat race either).
func _kino_free() -> bool:
	if boat_race != null and boat_race.busy():
		return false
	return _boat_free()
## The questlines (story_quests.gd): each big quest joins with one `stories.add` here. A new quest
## thread adds its own block (id, names, friend, words, start spot, colour, hours, call / meet /
## busy / idle); nothing else changes.
func _build_stories(world: Node3D) -> void:
	stories = StoryQuests.new()
	stories.name = "Stories"
	stories.hud = hud
	stories.log_on = stories_log
	stories.auto_yes = story_meet_flag or autopilot
	stories.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	stories.free_now = _boat_free
	stories.ground = func(x: float, z: float) -> float: return map.ground_height(x, z)
	stories.clock = func() -> Array:
		var c: Dictionary = tod.local_clock()
		return [float(c["hour"]), int(c["weekday"])]
	add_child(stories)
	stories.setup(world)
	if jobs != null:
		jobs.others_busy = _quest_running  # one activity at a time: no kebab rings during a questline
	if boat_race != null:
		boat_race.walk_up_pill = false  # Szymek walks up instead (the pill was the old walk-up)
		stories.add({"id": "boat", "pl": BoatRace.NAME, "en": BoatRace.NAME, "who": ["Szymek", "Szymek"],
				"hello": ["„O, jesteś! Pan Zdzisiek już grzeje Złotą Rybkę, Kamil zakłada kask. Trzy kółka pudła i odpadasz. Płyniemy pod Śląsko-Dąbrowski?”",
						"\"Oh, you're here! Pan Zdzisiek is warming up the Złota Rybka, Kamil's putting his helmet on. Three missed rings and you're out. Down to Śląsko-Dąbrowski?\""],
				"closed": ["„Po ciemku nie pływamy, policja wodna nie śpi. Wpadnij za dnia”", "\"No racing in the dark, the river police never sleep. Come by in the daytime\""],
				"at": BoatRace.CAR_SPOT, "colour": BoatRace.COLOUR, "hours": Vector2(BoatRace.HOURS[0], BoatRace.HOURS[1]),
				"call": boat_race.ring, "meet": boat_race.meet, "busy": boat_race.busy, "idle": boat_race.idle})
	if rave != null and not rave.home.is_empty():
		var h: Vector3 = rave.home["at"]
		stories.add({"id": "rave", "pl": "Sekretny rave", "en": "Secret rave", "who": ["Ziomek", "Ziomek"],
				"hello": ["„Siema! Słyszałeś? Lekti robi dziś sekretny rave. Ja wiem, jak tam trafić. Wsiadam?”",
						"\"Hey! Did you hear? Lekti's throwing a secret rave tonight. I know how to get there. Can I get in?\""],
				"closed": ["„Rave? Dziś cisza. Lekti gra od czwartku do soboty, wpadnij wieczorem”",
						"\"A rave? Nothing tonight. Lekti plays Thursday to Saturday, come by in the evening\""],
				"at": Vector2(h.x, h.z), "colour": Rave.COLOUR, "hours": Rave.TEASE_HOURS, "days": Rave.NIGHT_DAYS,
				"call": func() -> bool: return rave.ring(), "meet": rave.meet_in_person, "busy": rave.busy, "idle": rave.idle})
	if trend_job != null:
		stories.add({"id": "kawa", "pl": "Kawowy rajd", "en": "Coffee run", "who": [CoffeeRun.CALLER, CoffeeRun.CALLER],
				"hello": CoffeeRun.HELLO, "closed": CoffeeRun.CLOSED,
				"at": CoffeeRun.DOCK, "colour": CoffeeRun.COLOUR, "hours": Vector2(CoffeeRun.HOURS[0], CoffeeRun.HOURS[1]), "days": [],
				"call": trend_job.kawa_ring, "meet": trend_job.kawa_meet, "busy": trend_job.kawa_busy, "idle": trend_job.kawa_idle})
	# The night racing club (street_meet.gd): Darek at Plac Defilad, 21:00-4:00. Null with
	# --no-traffic or --meet=0.
	if meet != null and meet.meets.size() > 0:
		var g: Vector3 = meet.meets[0]["at"]
		stories.add({"id": "meet", "pl": "Nocny spot", "en": "Night meet", "who": [StreetMeet.FRIEND, StreetMeet.FRIEND],
				"hello": ["„Siema! Dziś spot na Defiladzie. Wbijasz?”", "\"Hey! Meet's on Plac Defilad tonight. You in?\""],
				"closed": ["„Za dnia tu tylko turyści. Wpadnij po 21.”", "\"By day it's all tourists here. Come after nine.\""],
				"at": Vector2(g.x, g.z), "colour": StreetMeet.COLOUR, "hours": StreetMeet.NIGHT_HOURS, "days": [],
				"call": meet.ring, "meet": meet.meet_in_person, "busy": meet.busy, "idle": meet.idle})
	if kino_tour != null:
		stories.add({"id": "kino", "pl": KinoTour.NAME, "en": "Cinema tour", "who": ["Wiktor", "Wiktor"],
				"hello": ["„Jesteś! Mam film, jedną kopię na 35 mm i cztery kina do objechania. Amondo, Atlantic, Kinoteka, Muranów. Wsiadam?”",
						"\"You're here! I've got the film, one 35 mm print and four cinemas to see. Amondo, Atlantic, Kinoteka, Muranów. Can I get in?\""],
				"closed": ["„Kina już śpią. Dystrybutorzy też. Wpadnij po czternastej, zaczniemy od Amondo”",
						"\"The cinemas are asleep. So are the distributors. Come by after two in the afternoon, we'll start with Amondo\""],
				"at": KinoTour.PICKUP["at"], "colour": KinoTour.COLOUR, "hours": Vector2(KinoTour.HOURS[0], KinoTour.HOURS[1]),
				"call": kino_tour.ring, "meet": kino_tour.meet, "busy": kino_tour.busy, "idle": kino_tour.idle})
	if story_flag != "":
		get_tree().create_timer(1.5).timeout.connect(func() -> void: stories.start(story_flag))
	print("stories: %d questlines (%s)" % [stories.defs.size(), ", ".join(stories.defs.map(func(d: Dictionary) -> String:
			return "%s %s" % [d["id"], "%.0f,%.0f" % [d["at"].x, d["at"].y] if d["at"] != Vector2.INF else "no start"]))])


## Something runs: a race, a job, a ride, a rescue, a questline, a tow (quest focus: the map goes quiet).
func _quest_running() -> bool:
	if (rivals != null and rivals.busy()) or (jobs != null and jobs.busy()) or (missions != null and missions.has_target()):
		return true
	if (boat_race != null and boat_race.busy()) or (rave != null and rave.busy()) or (ev_tow != null and ev_tow.busy()):
		return true
	if stories != null:
		for d: Dictionary in stories.defs:
			var b: Callable = d.get("busy", Callable())
			if b.is_valid() and bool(b.call()):
				return true
	return false


## A few times a second: quest focus and the starts on the minimap and the full map (sent only when
## they change).
func _story_tick() -> void:
	if stories == null or hud == null:
		return
	var focus := _quest_running()
	stories.focus = focus
	var m: Array = StoryQuests.marks(stories.defs, focus or flying)
	var names := PackedStringArray()
	if not (focus or flying):
		for d: Dictionary in stories.defs:
			if d["at"] != Vector2.INF:
				names.append(Lang.pick(str(d["pl"]), str(d["en"])))
	var key := "%s %d %s" % [focus, (m[0] as PackedVector2Array).size(), Lang.pick("pl", "en")]
	if key == _story_key:
		return
	_story_key = key
	hud.set_story(m[0], m[1], focus, names)
	if stories_log:
		print("stories: focus %s, %d starts on the map" % ["on" if focus else "off", (m[0] as PackedVector2Array).size()])


## Nothing else on, on the ground (the rave's test, and no rave either).
func _boat_free() -> bool:
	if rave != null and rave.busy():
		return false
	return _rave_free()


## The boat race's share of the car's speed zoom (the river is open: the rest of the zoom only
## shrank the boats).
const BOAT_ZOOM := 0.45
## A free ride's view (one boat, no rings to read): this share of the base view, so the hull's
## lean and pitch read on the phone (Autopilot, 2026-11-07: the boat was a few pixels long).
const BOAT_FREE_VIEW := 0.7


## The player takes the boat: the car waits on the bank, out of the world (no process, no
## collisions, hidden); every frame the car's spot follows the boat (`_boat_frame`) so the camera,
## the streamer, the minimap and the speed read it as they read the car.
func _on_boat_boarded() -> void:
	_boat_mask = Vector2i(car.collision_layer, car.collision_mask)
	car.collision_layer = 0
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.process_mode = Node.PROCESS_MODE_DISABLED
	car.visible = false
	_boat_paused = not missions.paused
	missions.paused = true
	missions.close()
	hud.hide_pill()
	_boat_frame()
	car.reset_physics_interpolation()
	_cut_camera()


## Back on the bank where the car was left.
func _on_boat_left() -> void:
	var at: Vector3 = boat_race._car_spot
	car.global_position = Vector3(at.x, map.ground_height(at.x, at.z), at.z)
	car.rotation.y = boat_race._car_yaw
	car.collision_layer = _boat_mask.x
	car.collision_mask = _boat_mask.y
	car.process_mode = Node.PROCESS_MODE_INHERIT
	car.visible = true
	car.reset_motion()
	car.reset_physics_interpolation()
	if _boat_paused:
		missions.paused = false
	_cut_camera()


## While boating: the car's spot, heading and speed are the boat's.
func _boat_frame() -> void:
	if boat_race == null or not boat_race.boating():
		return
	var b: Node3D = boat_race.player
	car.global_position = b.global_position
	car.rotation.y = float(b.yaw) + PI
	var v: Vector2 = b.vel
	car.vel = Vector3(v.x, 0.0, v.y)
	car.forward_speed = float(b.forward_speed())


# --- the secret raves ---------------------------------------------------------------------------

## LEKTI's invites, Ziomek's calls and the raves' rigs (rave.gd). None with --no-traffic or --rave=0.
func _build_rave(data: Dictionary, world: Node3D) -> void:
	if traffic == null or graph == null or rave_flag == "0":
		return
	rave = Rave.new()
	rave.name = "Rave"
	rave.hud = hud
	rave.dialogue = dialogue
	rave.wallet = wallet
	rave.missions = missions
	rave.map = map
	rave.graph = graph
	rave.radio = radio
	rave.city_sounds = city_sounds
	rave.origin = data.get("origin", [52.234, 21.024])
	rave.log_on = rave_log
	rave.auto = _rave_auto
	rave.force = rave_flag if rave_flag in ["on", "day"] else ""
	rave.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	rave.focus = func() -> Vector3: return cam_focus
	rave.clock = tod.local_clock
	rave.free_now = _rave_free
	rave.enter_club = _enter_club
	world.add_child(rave)
	rave.setup(world)
	if rave_spot != "":
		for i in rave.spots.size():
			if String(rave.spots[i]["id"]) == rave_spot:
				rave.night_spot = i
	if rave_flag in ["club", "patio"]:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			_enter_club("SMOŁA", "SMOŁA")
			if rave_flag == "patio":
				club.go_patio())
	if rave_flag in ["call", "smola"]:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if rave_flag == "smola":
				rave.ring("smola")
			else:
				rave.tease()
				rave.ring())


## Into the club's room (club.gd): the HUD aside, the car waiting (its process off), the camera
## on the room (`_update_camera`).
func _enter_club(pl: String, en: String) -> void:
	if club == null:
		club = Club.new()
		club.name = "Club"
		club.hud = hud
		club.dialogue = dialogue
		club.wallet = wallet
		club.radio = radio
		club.cam = cam
		club.log_on = rave_log
		add_child(club)
		club.left.connect(_on_club_left)
	club.enter(car.get_parent(), pl, en, radio.station_index("mordor_fm"))
	hud.visible = false
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.process_mode = Node.PROCESS_MODE_DISABLED


func _on_club_left() -> void:
	hud.visible = not hide_hud
	car.process_mode = Node.PROCESS_MODE_INHERIT
	_cut_camera()


## Nothing else on: no title, bench, Spacer, guide, card, call, ride, job, race; on the ground.
func _rave_free() -> bool:
	if club != null and club.inside:
		return false
	if meet != null and meet.busy():
		return false
	if ev_tow != null and ev_tow.busy():
		return false
	if title != null or _phone_bench or _bench_ghost != null or (spacer != null and spacer.on):
		return false
	if first10 != null and first10.guide_on():
		return false
	if hud.cards_up() or missions.state != Missions.State.CLOSED or missions.has_target():
		return false
	if (rides != null and rides.busy()) or (jobs != null and jobs.busy()) or (trend_job != null and trend_job.busy()):
		return false
	if rivals != null and rivals.busy():
		return false
	if boat_race != null and boat_race.busy():
		return false
	if kino_tour != null and kino_tour.busy():
		return false
	return not flying and not car.in_water


# --- the night racing club -------------------------------------------------------------------

## Darek's calls, the meets, the raids and the drag (street_meet.gd). None with --no-traffic or --meet=0.
func _build_meet(data: Dictionary, world: Node3D) -> void:
	if traffic == null or graph == null or meet_flag == "0":
		return
	meet = StreetMeet.new()
	meet.name = "StreetMeet"
	meet.hud = hud
	meet.dialogue = dialogue
	meet.wallet = wallet
	meet.missions = missions
	meet.map = map
	meet.graph = graph
	meet.traffic = traffic
	meet.police = police
	meet.car = car
	meet.flat_mat = _ground_mat
	meet.origin = data.get("origin", [52.234, 21.024])
	meet.log_on = meet_log
	meet.auto = _meet_auto
	meet.force = meet_flag == "on"
	meet.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	meet.clock = tod.local_clock
	meet.free_now = _meet_free
	meet.place_car = _place_car
	world.add_child(meet)
	meet.setup(world)
	if rivals != null:
		rivals.meet = meet
	if meet_flag == "call":
		get_tree().create_timer(1.0).timeout.connect(func() -> void: meet.ring())
	if meet_at != "":
		get_tree().create_timer(1.0).timeout.connect(func() -> void: meet.jump(meet_at))


## Nothing else on (as the rave's), and no rave night under way.
func _meet_free() -> bool:
	return _rave_free() and not (rave != null and rave.busy())


## Puts the car at `at` heading `yaw` at once (the meet's START DRAG), the camera cut with it.
func _place_car(at: Vector3, yaw: float) -> void:
	car.global_position = at + Vector3(0, 0.05, 0)
	car.rotation.y = yaw
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	_cut_camera()
	print("teleport: the car to %.0f, %.0f for the meet" % [at.x, at.z])


# --- dead electric cars ----------------------------------------------------------------------

## Bartek's call and the stranded TESŁO cars (ev_tow.gd). None with --no-traffic or --ev=0.
func _build_ev_tow(world: Node3D) -> void:
	if traffic == null or ev_flag == "0":
		return
	ev_tow = EvTow.new()
	ev_tow.name = "EvTow"
	ev_tow.hud = hud
	ev_tow.dialogue = dialogue
	ev_tow.wallet = wallet
	ev_tow.missions = missions
	ev_tow.map = map
	ev_tow.graph = graph
	ev_tow.traffic = traffic
	ev_tow.radio = radio
	ev_tow.heli = heli
	ev_tow.log_on = ev_log
	ev_tow.auto = _ev_auto
	ev_tow.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	ev_tow.free_now = _ev_free
	ev_tow.take_off = func() -> void: _take_off(Heli.CRUISE)
	add_child(ev_tow)
	ev_tow.setup(world)
	if ev_flag != "":
		get_tree().create_timer(1.0).timeout.connect(_ev_start)


## Nothing else on: no title, bench, Spacer, guide, card, rescue, ride, job, race or tow.
func _ev_free() -> bool:
	if (rave != null and rave.busy()) or (club != null and club.inside):
		return false
	if meet != null and meet.busy():
		return false
	if title != null or _phone_bench or _bench_ghost != null or (spacer != null and spacer.on):
		return false
	if first10 != null and first10.guide_on():
		return false
	if hud.cards_up() or missions.state != Missions.State.CLOSED or missions.has_target():
		return false
	if (rides != null and rides.busy()) or (jobs != null and jobs.busy()) or (trend_job != null and trend_job.busy()):
		return false
	if rivals != null and rivals.busy():
		return false
	if boat_race != null and boat_race.busy():
		return false
	if kino_tour != null and kino_tour.busy():
		return false
	return flying or not car.in_water


## The --ev-* test flags, a second into the drive.
func _ev_start() -> void:
	match ev_flag:
		"call":
			ev_tow.ring()
		"stranded":
			var p := car.global_position
			var f := -car.global_transform.basis.z
			ev_tow.place_stranded(Vector2(p.x, p.z), Vector2(f.x, f.z).normalized(), true)
		_:
			ev_tow.ring()
			ev_tow._on_card(0)
			ev_tow._on_card(0)
			if ev_tow.job.is_empty():
				return
			var at: Vector3 = ev_tow.job["at"]
			if not flying:
				_take_off(Heli.CRUISE)
			var carry := ev_flag == "tow=carry"
			# Over the car, low enough to hook; for the carry 22 m up, the rope lifting it.
			heli.place(at + Vector3(-3.0, 0.0, 2.0), heli.rotation.y, 22.0 if carry else EvTow.ROPE + EvTow.SIZE.y - 0.5)
			cam_focus = heli.global_position
			if carry:
				ev_tow._hook()


# --- the vintage-tram loop --------------------------------------------------------------------

## The old tram (old_tram.gd) on the trams' tracks, after the buses. None with --no-traffic.
func _build_old_tram(world: Node3D) -> void:
	if trams == null:
		return
	old_tram = OldTram.new()
	old_tram.name = "OldTram"
	old_tram.trams = trams
	old_tram.sfx = sfx
	old_tram.dialogue = dialogue
	old_tram.egg_book = egg_book
	old_tram.log_on = tram_log
	old_tram.clock = tod.local_clock
	old_tram.calendar = _crowd_calendar
	old_tram.focus = func() -> Vector3: return cam_focus
	old_tram.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true]
		return [car.global_position, car.vel.length() * 3.6, false]
	old_tram.probe = _egg_state
	world.add_child(old_tram)
	old_tram.setup()
	if sfx != null:
		trams.old_bell.connect(func(at: Vector3) -> void: sfx.play_at("old_tram_bell", at))
	if old_tram_flag != "":
		old_tram.force(Vector2(car.global_position.x, car.global_position.z))


## --old-tram=follow: the car (no collisions) kept 22 m behind the old set's tail on its rails,
## facing along them, so the view goes with it and E39's count runs.
func _old_tram_follow_frame() -> void:
	if old_tram == null or old_tram.tram == null:
		return
	var t: Trams.Tram = old_tram.tram
	var back := Trams.length_of(t) + 22.0
	var p := trams.body_point(t, back)
	var q := trams.body_point(t, back - 4.0)
	var dir := (q - p).normalized() if q.distance_to(p) > 0.01 else t.dir
	car.collision_layer = 0
	car.collision_mask = 0
	car.global_position = Vector3(p.x, t.pos.y + 0.5, p.y)
	car.rotation = Vector3(0.0, atan2(-dir.x, -dir.y), 0.0)
	car.vel = Vector3(dir.x, 0.0, dir.y) * t.v
	car.forward_speed = t.v
	car.target_dir = Vector3.ZERO
	car.throttle = 0.0
	cam_focus = car.global_position


# --- loop MW-4: everyday life and trends -------------------------------------------------------

## Everyday life (city_life.gd) at the notebook's places, after the crowds (the trend queues are
## their sites) and the sound; the "Na czasie" job (trend_job.gd) beside the side jobs. None with
## --life=0 or without the notebook's places.
func _build_city_life(data: Dictionary, world: Node3D) -> void:
	if life_flag == 0 or notes == null or not notes.ready_ok:
		return
	life = CityLife.new()
	life.name = "CityLife"
	life.map = map
	life.dialogue = dialogue
	life.sfx = sfx
	life.walkers = walkers
	life.egg_book = egg_book
	life.wallet = wallet
	life.hud = hud
	life.car = car
	life.amount = float(life_flag) * (0.5 if quality == Tiers.LOW else 1.0)
	life.dogs_log = dogs_log
	life.trend_log = trend_log
	life.life_log = life_log
	life.pedzik_on = not no_parodies
	# Loop couriers: the kerb riders ride the lane graph; the couriers wait at the kebab stands; the
	# courier race's challenger is one of them.
	life.graph = graph
	life.pedzik_log = pedzik_log
	life.kerb_close = pedzik_kerb
	if jobs != null:
		life.stands = jobs.stand_frames()
		jobs.courier.life = life
	life.soak = life_soak
	life.zajac_rig = zajac_flag and autopilot
	life.armchair_flag = armchair_flag  # loop jobs-2
	life.trend_day_flag = trend_day_flag
	life.clock = tod.local_clock
	life.calendar = _crowd_calendar
	life.focus = func() -> Vector3: return cam_focus
	life.vehicle = func() -> Array:
		if flying:
			return [heli.global_position, heli.speed() * 3.6, true, heli.rotation.y, heli.global_position.y - map.ground_height(heli.global_position.x, heli.global_position.z)]
		return [car.global_position, car.vel.length() * 3.6, false, car.rotation.y, 0.0, car.vel]
	life.probe = _egg_state
	if traffic != null:
		life.on_screen = traffic.on_screen
		life.view = traffic  # loop MW-4's cost cut: its view rectangle for who is on screen
		# The player has no horn yet (BACKLOG): the AI cars' horns at the player make the dogs bark.
		traffic.blocked_by_player.connect(func(d): life.horn(d.pos))
		traffic.bumped_driver.connect(func(d): life.horn(d.pos))
	# Sessions played: the trend cycle's day without Live (saved like the rest of the keep).
	life.session = int(wallet.keep.get("life_sessions", 0))
	wallet.keep["life_sessions"] = life.session + 1
	wallet.save()
	world.add_child(life)
	life.setup(notes.places, data)
	# The Wiralek slots' doors: the trend queues' (crowds.gd), else the places themselves.
	var at := {}
	for p: Dictionary in notes.places:
		at[str(p["id"])] = p["at"]
	for id: String in CityLife.SLOTS:
		var door: Vector2 = at.get(id, Vector2.INF)
		var out := Vector2.DOWN
		if crowds != null and crowds.by_id.has(id):
			var site: Dictionary = crowds.sites[crowds.by_id[id]]
			door = site["door"]
			out = site["out"]
		life.slot_doors.append(door)
		life.slot_out.append(out)
	if crowds != null:
		crowds.trend = life.trend_queue
		if city_sounds != null:
			for id: String in Crowds.TRENDS:
				if crowds.by_id.has(id):
					var site: Dictionary = crowds.sites[crowds.by_id[id]]
					var d2: Vector2 = site["door"]
					city_sounds.add_crowd(id, "queue", Vector3(d2.x, map.ground_height(d2.x, d2.y), d2.y),
							func() -> bool: return int(site["n"]) >= 2)
	if rides != null:
		rides.hurry_to = life.hurry_target
	if jobs != null:
		trend_job = TrendJob.new()
		trend_job.name = "TrendJob"
		trend_job.autopilot = autopilot
		trend_job.log_on = trend_log
		add_child(trend_job)
		trend_job.setup({"hud": hud, "dialogue": dialogue, "wallet": wallet, "missions": missions, "rivals": rivals, "jobs": jobs,
				"rides": rides, "graph": graph, "map": map, "car": car, "life": life, "crowds": crowds}, at, world)
		jobs.trend = trend_job
		trend_job.egg = func(id: String) -> bool: return egg_book != null and egg_book.fire(id, _egg_state())
		if spacer != null:
			trend_job.quiet = spacer.on
	if zajac_flag or trend_job_flag > 0 or armchair_flag or dzemini_flag:
		_life_start.call_deferred()


## --zajac: the car on the lane nearest Kolka's start; --trend-job=N: by slot N with its request
## (once the city has its first tick).
func _life_start() -> void:
	await get_tree().create_timer(1.5).timeout
	if zajac_flag and notes != null and notes.by_id.has("kolka_start"):
		# Where the club gathers (its route's start, on the boulevard), once the index is built.
		var waited := 0.0
		while life.kolka_start_at() == Vector2.INF and waited < 20.0:
			await get_tree().create_timer(0.5).timeout
			waited += 0.5
		var at: Vector2 = life.kolka_start_at()
		if at == Vector2.INF:
			at = notes.places[notes.by_id["kolka_start"]]["at"]
		_put_car_near(at, 80.0)
		print("life: --zajac: the car at %.0f, %.0f (Kolka's start %.0f m away), %s" % [car.global_position.x, car.global_position.z,
				Vector2(car.global_position.x, car.global_position.z).distance_to(at), life.life_summary()])
	if armchair_flag:
		# Loop jobs-2: once his way is known, the car on the lane nearest the armchair man.
		var waited_a := 0.0
		while (life.get("_arm") as Dictionary).is_empty() and waited_a < 30.0:
			await get_tree().create_timer(0.5).timeout
			waited_a += 0.5
		var pose: Array = life.armchair_pose()
		var ap: Vector3 = pose[0]
		if ap == Vector3.INF:
			print("life: --armchair: no way on %s" % CityLife.ARMCHAIR_STREET)
		else:
			_put_car_near(Vector2(ap.x, ap.z), 60.0)
			cam_focus = car.global_position
			print("life: --armchair: the man at %.0f, %.0f, the car %.0f m from him" % [ap.x, ap.z,
					Vector2(car.global_position.x, car.global_position.z).distance_to(Vector2(ap.x, ap.z))])
	if dzemini_flag and trend_job != null and crowds != null and crowds.by_id.has(Crowds.DZEMINI_ID):
		trend_job.dz_done = true
		crowds.dzemini_mlask()
		var dsite: Dictionary = crowds.sites[crowds.by_id[Crowds.DZEMINI_ID]]
		_put_car_near(dsite.get("door", dsite["at"]), 40.0)
		print("trend job: --dzemini: the MLASK on DŻEMINI, the car %.0f m from its door" % [
				Vector2(car.global_position.x, car.global_position.z).distance_to(dsite.get("door", dsite["at"]))])
	if trend_job_flag > 0 and trend_job != null:
		var i := trend_job_flag - 1
		if trend_job_flag == 6:
			# "Mlask" (G5): Mrożulo's van parked by the car, his request at once (KUKŁA by Nowy
			# Świat if no Wiralek slot is new enough).
			if crowds != null and crowds.by_id.has(Crowds.KUKLA[1]):
				_put_car_near(crowds.sites[crowds.by_id[Crowds.KUKLA[1]]]["door"], 120.0)
			life.tick(0.0)
			if not trend_job.offer_mlask(true):
				print("trend job: --trend-job=6: no request (no van spot or new place)")
			return
		if trend_job_flag == 8:
			# "Dżemini" (G5b): Mrożulo's call at once, the car by DŻEMINI KEBAB on Świętokrzyska.
			if crowds != null and crowds.by_id.has(Crowds.DZEMINI_ID):
				_put_car_near(crowds.sites[crowds.by_id[Crowds.DZEMINI_ID]]["at"], 80.0)
			life.tick(0.0)
			await get_tree().create_timer(1.0).timeout
			if not trend_job.offer_dzemini(true):
				print("trend job: --trend-job=8: no request (no shop door, kerb or van spot)")
			return
		if trend_job_flag == 9:
			# "Kawowy rajd" (coffee_run.gd): the car near the ROWERILO dock in Powiśle, Zuzia's call at once.
			_put_car_near(CoffeeRun.DOCK, 80.0)
			life.tick(0.0)
			if not trend_job.offer_kawa_call(true):
				print("trend job: --trend-job=9: no request (a café has no position)")
			return
		if trend_job_flag == 7:
			# "Czwarty" at WTS DeSki's padel courts (landmarks.gd DESKI), whatever the clock.
			life.tick(0.0)
			if not trend_job.offer_deski_call(true):
				print("trend job: --trend-job=7: no request (no kerb or door fits)")
			return
		if trend_job_flag == 5 and crowds != null and crowds.by_id.has(Crowds.PADEL_ID):
			var cd: Vector2 = crowds.sites[crowds.by_id[Crowds.PADEL_ID]]["door"]
			_put_car_near(cd, 60.0)
			life.tick(0.0)
			if not trend_job.offer_czwarty():
				print("trend job: --trend-job=5: no request (no kerb or door fits)")
			return
		if trend_job_flag == 4 and crowds != null and crowds.by_id.has(Crowds.PISTACJA_ID):
			# The limited drop at PISTACJA, whatever the clock (no "sold out").
			var pd: Vector2 = crowds.sites[crowds.by_id[Crowds.PISTACJA_ID]]["door"]
			_put_car_near(pd, 60.0)
			life.tick(0.0)
			trend_job.force_drop = true
			if not trend_job.offer_drop():
				print("trend job: --trend-job=4: no request (no kerb or door fits)")
			return
		var door: Vector2 = life.slot_doors[i] if i < life.slot_doors.size() else Vector2.INF
		if door == Vector2.INF:
			push_warning("--trend-job=%d: no such slot" % trend_job_flag)
			return
		_put_car_near(door, 60.0)
		life.tick(0.0)
		if not trend_job.offer(i):
			print("trend job: --trend-job=%d: no request (the slot is on day %d)" % [trend_job_flag, int(life.slots_now[i]["day"])])


## --zajac: is yyyymmdd a Wednesday (Kolka's day)?
static func _is_wednesday(ymd: int) -> bool:
	var t := Time.get_unix_time_from_datetime_dict({"year": ymd / 10000, "month": (ymd / 100) % 100, "day": ymd % 100, "hour": 12})
	return int(Time.get_datetime_dict_from_unix_time(int(t))["weekday"]) == 3


## --crowd= × the Low tier's half.
func _crowd_scale() -> float:
	return float(crowd_flag) * (0.5 if quality == Tiers.LOW else 1.0)


## The crowds' calendar: Live or not, the month and date, the look, rain, and the sunset's hour
## (Live: of its date, found once a day; the fixed looks: the Dusk look's 19:30).
func _crowd_calendar() -> Dictionary:
	var live := tod.mode == TimeOfDay.LIVE
	var month := 7
	var ymd := 0
	var sunset := 19.5
	if live:
		var t := tod.now_utc()
		var off := TimeOfDay.warsaw_offset(t)
		var d := Time.get_datetime_dict_from_unix_time(int(t) + off)
		month = int(d["month"])
		ymd = int(d["year"]) * 10000 + month * 100 + int(d["day"])
		if not _sunsets.has(ymd):
			# The first minute after 15:00 (Warsaw) with the sun under the horizon.
			var noon := t - (float(d["hour"]) * 3600.0 + float(d["minute"]) * 60.0 + float(d["second"]))
			var h := 15.0
			while h < 23.0 and TimeOfDay.sun_position(noon + h * 3600.0).x > 0.0:
				h += 1.0 / 12.0
			_sunsets[ymd] = h
		sunset = float(_sunsets[ymd])
	return {"live": live, "month": month, "date": ymd, "look": TimeOfDay.NAMES[tod.mode], "rain": weather.state != 0,
			"sunset": sunset}


## The places.json id of a club for --club= (an id, or a name: "smoła", "Jasna 0").
func _club_id(name: String) -> String:
	var want := Notebook.norm(name)
	var book := Notebook.new()
	var id := ""
	if book.load_places():
		for p: Dictionary in book.places:
			if not "club" in p.get("tags", []) and str(p["id"]) != Crowds.ROOF_ID:
				continue
			if str(p["id"]) == name or Notebook.norm(str(p["id"])) == want or Notebook.norm(str(p["name_pl"])) == want:
				id = str(p["id"])
	book.free()
	return id


## --club=, before the city opens: the sectors round the club first (as --place=).
func _club_start() -> void:
	if club_flag == "":
		return
	var id := _club_id(club_flag)
	if id == "":
		push_warning("--club=%s: no such club in places.json" % club_flag)
		return
	club_flag = id
	var book := Notebook.new()
	if book.load_places():
		var near: Array = book.places[book.by_id[id]]["near"]
		var at := Notebook.project([52.234, 21.024], float(near[0]), float(near[1]))
		start_at = Vector3(at.x, 0.0, at.y)
	book.free()


## The car on the lane nearest the club's door, facing along it.
func _put_at_club(id: String) -> void:
	if crowds == null or not crowds.by_id.has(id):
		push_warning("--club=%s: no crowd there" % id)
		return
	var site: Dictionary = crowds.sites[crowds.by_id[id]]
	var door: Vector2 = site["door"]
	var spot := Vector3(door.x, map.ground_height(door.x, door.y), door.y)
	var yaw := car.rotation.y
	var lane := _lane_spot(spot, yaw)
	if not lane.is_empty() and Vector2((lane[0] as Vector3).x, (lane[0] as Vector3).z).distance_to(door) < 60.0:
		spot = lane[0]
		yaw = lane[1]
	car.global_position = spot
	car.rotation.y = yaw
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	cam_focus = car.global_position
	print("night: --club=%s: the car at %.0f, %.0f, %.0f m from the door" % [id, spot.x, spot.z, Vector2(spot.x, spot.z).distance_to(door)])


## --place=<id>, before the city opens: start where places.json's hint says, so the sectors
## round the place are built first (the exact spot comes after, _put_at_place).
func _place_start() -> void:
	if place_flag == "":
		return
	var book := Notebook.new()
	if book.load_places() and book.by_id.has(place_flag):
		var near: Array = book.places[book.by_id[place_flag]]["near"]
		var at := Notebook.project([52.234, 21.024], float(near[0]), float(near[1]))
		start_at = Vector3(at.x, 0.0, at.y)
	else:
		push_warning("--place=%s: no such place in places.json" % place_flag)
	book.free()


## The car on the lane nearest the place when that is inside its radius, else on the place.
func _put_at_place(id: String) -> void:
	if not notes.by_id.has(id):
		return
	var place: Dictionary = notes.places[notes.by_id[id]]
	var at: Vector2 = place["at"]
	var spot := Vector3(at.x, map.ground_height(at.x, at.y), at.y)
	var yaw := car.rotation.y
	var lane := _lane_spot(spot, yaw)
	if not lane.is_empty() and Vector2((lane[0] as Vector3).x, (lane[0] as Vector3).z).distance_to(at) < float(place["radius"]) * 0.8:
		spot = lane[0]
		yaw = lane[1]
	car.global_position = spot
	car.rotation.y = yaw
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	cam_focus = car.global_position
	print("notes: --place=%s: the car at %.0f, %.0f, %.0f m from the place" % [id, spot.x, spot.z, Vector2(spot.x, spot.z).distance_to(at)])


# --- loop MW-6: the eggs in the notebook, KASETA, Spacer and Fotka ----------------------------

## The egg cards (egg_book.gd), the time tape (tape.gd), wander mode (spacer.gd) and the photo
## mode (fotka.gd): built after the notebook (they stand on its places), each checked at 2 Hz;
## their pages are the notebook's three extra chips.
func _build_moments(data: Dictionary, world: Node3D) -> void:
	var places := {}
	if notes != null:
		for p: Dictionary in notes.places:
			places[str(p["id"])] = p["at"]
	var spots: Dictionary = eggs.spots if eggs != null else {}
	egg_book = EggBook.new()
	egg_book.name = "EggBook"
	egg_book.wallet = wallet
	egg_book.hud = hud
	egg_book.radio = radio
	egg_book.log_on = egg_log
	egg_book.blip = _blip_sound
	add_child(egg_book)
	if egg_book.load_eggs():
		egg_book.setup(places, spots, data)
		if eggs != null:
			eggs.book = egg_book
		egg_book.probe = _egg_state
		if found_eggs != "":
			egg_book.preset(found_eggs)
	tape = Tape.new()
	tape.name = "Tape"
	tape.wallet = wallet
	tape.hud = hud
	tape.map = map
	tape.book = egg_book
	tape.log_on = tape_log
	tape.blip = _blip_sound
	tape.vhs = _vhs_pulse
	tape.state = _egg_state
	world.add_child(tape)
	if tape.setup(places):
		egg_book.tape = tape
		tape.probe = func() -> Array:
			return [_vehicle_position(), (heli.speed() if flying else car.vel.length()) * 3.6, flying,
					title != null or _phone_bench or (fotka != null and fotka.is_open())]
		hud.context_pressed.connect(tape.on_context)
	spacer = Spacer.new()
	spacer.name = "Spacer"
	spacer.notebook = notes
	spacer.probe = func() -> Array: return [_vehicle_position(), title != null or _phone_bench]
	add_child(spacer)
	spacer.changed.connect(_apply_spacer)
	spacer.set_on(spacer_flag == 1 if spacer_flag >= 0 else settings.wander, spacer_hint)
	_apply_spacer(spacer.on)
	hud.tapped.connect(func(_at: Vector2) -> void:
		if spacer.hint_shown():
			print("spacer: hint to %s tapped away" % spacer.hint_id)
			spacer.dismiss())
	fotka = Fotka.new()
	fotka.name = "Fotka"
	fotka.wallet = wallet
	fotka.hud = hud
	fotka.map = map
	fotka.world = world
	fotka.main_cam = cam
	fotka.log_on = photo_log
	fotka.blip = _blip_sound
	fotka.pt = hud.pt
	fotka.safe = hud.safe_rect()
	fotka.look = _look_now
	for c in cam.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_override == post_mat:
			fotka.post_quad = c
	add_child(fotka)
	fotka.setup(places, spots)
	fotka.closed.connect(_on_fotka_closed)
	if hud.settings_panel != null:
		var page: Control = hud.settings_panel.get("notebook_page")
		hud.settings_panel.set("notebook_eggs", egg_book)
		hud.settings_panel.set("notebook_tape", tape)
		hud.settings_panel.set("notebook_kadr", fotka)
		if page != null:
			page.eggs = egg_book
			page.tape = tape
			page.kadr = fotka
	if egg_flag != "" or tape_flag != "" or fotka_flag:
		_moment_at = 1.0


## Loop 3h slice 1: the districts (districts.gd) on the notebook's places, checked at 3 Hz through
## the notebook's probe; their "?" marks join the notebook's (notebook.gd `extra_marks`).
func _build_districts() -> void:
	districts = Districts.new()
	districts.name = "Districts"
	districts.wallet = wallet
	districts.hud = hud
	districts.log_on = districts_log
	districts.blip = _blip_sound
	if sfx != null:
		districts.entered.connect(sfx.set_district)
	districts.force_card = district_card
	add_child(districts)
	var points := {}
	if notes != null:
		for p: Dictionary in notes.places:
			points[str(p["id"])] = p["at"]
	if not districts.setup(points):
		return
	if districts_spec != "":
		districts.preset(districts_spec)
	if notes != null:
		districts.probe = notes.probe
		notes.extra_marks = districts.marks
	if districts_log:
		print("districts: %s" % districts.summary())


## The first-10 polish: the mixtapes (cassettes.gd) on their landmarks' roofs (the rescue's
## flat-roof spots), picked up from the helicopter; each opens the next PÓŁNOC FM track.
func _build_cassettes(world: Node3D) -> void:
	cassettes = Cassettes.new()
	cassettes.name = "Cassettes"
	cassettes.wallet = wallet
	cassettes.hud = hud
	cassettes.radio = radio
	cassettes.world = world
	cassettes.blip = _blip_sound
	add_child(cassettes)
	if not cassettes.load_data():
		return
	cassettes.place_all(missions.roof_spot)
	if notes != null:
		cassettes.probe = notes.probe


## Loop 3h slice 2: the 20 Syrenki (syrenki.gd) on the notebook's places and the lane graph; the
## find is checked at 5 Hz through the notebook's probe.
func _build_syrenki(world: Node3D) -> void:
	syrenki = Syrenki.new()
	syrenki.name = "Syrenki"
	syrenki.wallet = wallet
	syrenki.hud = hud
	syrenki.districts = districts
	syrenki.world = world
	syrenki.log_on = syrenki_log
	syrenki.blip = _blip_sound
	add_child(syrenki)
	var points := {}
	if notes != null:
		for p: Dictionary in notes.places:
			points[str(p["id"])] = p["at"]
	if not syrenki.load_data(points):
		return
	if graph != null:
		syrenki.place_all(map, graph)
	if syrenki_spec != "":
		syrenki.preset(syrenki_spec)
	if notes != null:
		syrenki.probe = notes.probe
	if syrenka_flag != "":
		var parts := syrenka_flag.split(":")
		var i := syrenki.index_of(parts[0])
		var back := float(parts[1]) if parts.size() > 1 else 25.0
		var spot := syrenki.drive_in(graph, i, back) if i >= 0 else []
		if spot.is_empty():
			push_warning("--syrenka=%s: no such Syrenka or no street" % syrenka_flag)
		else:
			car.global_position = spot[0]
			car.rotation.y = spot[1]
			car.vel = Vector3.ZERO
			car.forward_speed = 0.0
			car.reset_physics_interpolation()
			cam_focus = car.global_position
			print("syrenki: --syrenka=%s: the car at %.1f, %.1f facing it" % [syrenka_flag, car.global_position.x, car.global_position.z])


## --syrenka=<id|n>, before the city opens: start at the Syrenka's anchor (map-free), so the
## sectors round it are built first (the exact spot comes after, _build_syrenki).
func _syrenka_start() -> void:
	if syrenka_flag == "":
		return
	var sy := Syrenki.new()
	if sy.load_data():
		var i := sy.index_of(syrenka_flag.get_slice(":", 0))
		if i >= 0 and sy.entries[i]["anchor"] != Vector2.INF:
			var at: Vector2 = sy.entries[i]["anchor"]
			start_at = Vector3(at.x, 0.0, at.y)
	sy.free()


## Spacer on or off: what comes by itself stops (or starts again).
func _apply_spacer(on: bool) -> void:
	if missions != null:
		missions.calls_off = on
	if rides != null:
		rides.quiet = on
	if trend_job != null:
		trend_job.quiet = on
	if rivals != null:
		rivals.quiet = on
	if police != null:
		police.gentle = on


## Beta radio: the RADIO chip follows the station: its name, its colour, the next key.
func _on_station_changed(_index: int, info: Dictionary) -> void:
	hud.set_radio_name(radio.label())
	hud.set_radio_skip(radio.can_skip())
	hud.set_radio_colour(info.get("colour", Color.WHITE) if not info.is_empty() else Color("#c9c4d8"))


## Beta radio (2026-11-02): when the title goes, the host says good morning (or evening) to
## Warsaw with the weather and the temperature for the game's hour and month, 4 s after the
## station's caption: as ticker text on a first start or a new game (with the opening line), and
## on every later launch as her three voice clips plus the same text (greeting_clips.gd).
func _radio_greeting() -> void:
	# F (2026-11-02): only on the first start and after a new game (the same launches as the
	# opening flyover: the first-10 guide is due), never on every launch.
	# F (2026-11-05): every later launch gets her spoken greeting (greeting_clips.gd) instead; the
	# first start and a new game keep the opening line only.
	var later := first10 == null or not first10.guide
	await get_tree().create_timer(4.0).timeout
	if not is_inside_tree() or radio == null or dialogue == null:
		return
	var st := _egg_state()
	var day: int = int(st["date"]) % 100 if int(st["date"]) > 0 else int(Time.get_date_dict_from_system()["day"])
	if not later:
		dialogue.greet(float(st["hour"]), bool(st["rain"]), int(st["month"]), day)
		return
	# Her voice is KEBAB FM's: another station (or none) stays quiet.
	if radio.station < 0 or str(radio.stations[radio.station]["id"]) != "nocna_fm":
		return
	var clips := GreetingClips.new()
	add_child(clips)
	if clips.start(radio, dialogue.greeting_parts(float(st["hour"]), bool(st["rain"]), int(st["month"]), day)):
		dialogue.greet(float(st["hour"]), bool(st["rain"]), int(st["month"]), day)
	else:
		clips.queue_free()


## The eggs' probe (egg_book.gd `tick`, tape.gd's E36/E37): the vehicle and the game clock.
func _egg_state() -> Dictionary:
	var pos := _vehicle_position()
	var c := tod.local_clock()
	var live := tod.mode == TimeOfDay.LIVE
	var ymd := 0
	var month := 7
	if live:
		var t := tod.now_utc()
		var d := Time.get_datetime_dict_from_unix_time(int(t) + TimeOfDay.warsaw_offset(t))
		ymd = int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])
		month = int(d["month"])
	var roof := 0.0
	if flying:
		roof = heli.surface - map.ground_height(pos.x, pos.z)
	var station := ""
	if radio.station >= 0 and radio.station < radio.stations.size():
		station = str(radio.stations[radio.station]["id"])
	return {"pos": pos, "kmh": (heli.speed() if flying else car.vel.length()) * 3.6, "flying": flying,
			"alt": heli.global_position.y - map.ground_height(pos.x, pos.z) if flying else 0.0,
			"skids": heli.height_above if flying else 0.0, "roof": roof,
			"away": title != null or _phone_bench or (fotka != null and fotka.is_open()),
			"look": TimeOfDay.NAMES[tod.mode], "hour": float(c["hour"]), "weekday": int(c["weekday"]), "month": month,
			"live": live, "sun": tod.sun_elevation, "rain": weather.state != 0, "station": station, "date": ymd,
			"roadworks": eggs.barrier_street if eggs != null else "", "crowds": _crowd_levels(), "paint": str(wallet.paint)}


## The crowds' levels for the eggs (crowds.gd's, loop MW-4: and city_life.gd's).
func _crowd_levels() -> Dictionary:
	var out: Dictionary = crowds.levels.duplicate() if crowds != null else {}
	if life != null:
		out.merge(life.levels, true)
	return out


## The time of day's look for a Kadr: Day, Dusk or Night (Live by the sun's height).
func _look_now() -> String:
	if tod.mode != TimeOfDay.LIVE:
		return TimeOfDay.NAMES[tod.mode]
	if tod.sun_elevation > 6.0:
		return "Day"
	return "Dusk" if tod.sun_elevation > -6.0 else "Night"


## KASETA: the VHS overlay for `seconds`, then the setting again.
func _vhs_pulse(seconds: float) -> void:
	if Access.calm:
		return  # access.gd: no flashing
	_vhs_until = _clock + seconds
	var keep := vhs
	_set_vhs(true)
	vhs = keep


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
			_egg = book.eggs[book.by_id[egg_flag]]
		book.free()
		if _egg.is_empty():
			push_warning("--egg=%s: no such egg in eggs.json" % egg_flag)
			return
		pid = str(_egg["place"])
		var t: Dictionary = _egg["trigger"]
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
		print("egg: --egg=%s %s: %s; the moment: %s%s%s" % [egg_flag, _egg["name"][0], t,
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
			var i := _kadr_index(f, kadr_flag)
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
		start_at = Vector3(at.x, 0.0, at.y)
	nb.free()


func _kadr_index(f: Node, key: String) -> int:
	var spots: Array = f.get("spots")
	for i in spots.size():
		if str(spots[i]["id"]) == key:
			return i
	if key.is_valid_int() and int(key) >= 1 and int(key) <= spots.size():
		return int(key) - 1
	return -1


## The --egg, --tape and --fotka moments, a second into the run (the city's time and the radio
## are set by then), and the --egg rig after.
func _moment_frame(dt: float) -> void:
	if _vhs_until >= 0.0 and _clock >= _vhs_until:
		_vhs_until = -1.0
		_set_vhs(vhs)
	if _moment_at >= 0.0:
		_moment_at -= dt
		if _moment_at < 0.0:
			_start_moment()
	if not _egg.is_empty() and _rig_t >= 0.0:
		_egg_rig(dt)
	if fotka != null and fotka.is_open() and fotka_shot >= 0.0:
		fotka_shot -= dt
		if fotka_shot < 0.0:
			fotka.shoot()


func _start_moment() -> void:
	if not _egg.is_empty():
		_egg_place()
	# A tape egg (E36, E37) plays its then card here too.
	if tape_flag != "" and tape != null:
		var i := tape.index_of(tape_flag)
		if i >= 0:
			_put_car_near(tape.spots[i]["at"], 20.0)
			print("tape: --tape=%s, the car at %.1f, %.1f heading %.0f" % [tape_flag, car.global_position.x, car.global_position.z,
					fposmod(rad_to_deg(car.rotation.y), 360.0)])
			tape.play(i)
		else:
			push_warning("--tape=%s: no such then card" % tape_flag)
	if fotka_flag and fotka != null:
		if kadr_flag != "":
			var i := _kadr_index(fotka, kadr_flag)
			if i >= 0:
				_put_car_near(fotka.spots[i]["at"], 60.0)
				_open_fotka()
				fotka.aim_at(i)
				if fotka_shot < 0.0:
					fotka_shot = 2.0
		else:
			_open_fotka()


## Fotka from the settings card (or --fotka): the car stopped, the HUD away.
func _open_fotka() -> void:
	if fotka == null or not _started or title != null:
		return
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	fotka.safe = hud.safe_rect()
	fotka.pt = hud.pt
	_fotka_car = car.global_transform
	fotka.open(_vehicle_position(), cam_yaw, camera_pitch, cam.size)


## Fotka closed (2026-11-01, F stuck in a building after a photo on the iPhone): the car back
## where it stood when Fotka opened, stopped, then the camera cut to it. The hold parks the car
## now (_read_input), so it no longer reverses while the camera is away; this is the backstop.
func _on_fotka_closed() -> void:
	if _fotka_car != Transform3D.IDENTITY and not flying:
		var moved := car.global_position.distance_to(_fotka_car.origin)
		car.global_transform = _fotka_car
		car.vel = Vector3.ZERO
		car.velocity = Vector3.ZERO
		car.forward_speed = 0.0
		car.reset_physics_interpolation()
		if photo_log:
			print("fotka: car put back (it had moved %.2f m)" % moved)
	_fotka_car = Transform3D.IDENTITY
	_cut_camera()


## The car on the lane nearest `at` (within `reach` m), else on the point itself.
func _put_car_near(at: Vector2, reach: float) -> void:
	if at == Vector2.INF:
		return
	var spot := Vector3(at.x, map.ground_height(at.x, at.y), at.y)
	var yaw := car.rotation.y
	var lane := _lane_spot(spot, yaw)
	if not lane.is_empty() and Vector2((lane[0] as Vector3).x, (lane[0] as Vector3).z).distance_to(at) < reach:
		spot = lane[0]
		yaw = lane[1]
	if flying:
		_set_flying(false)
	car.global_position = spot
	car.rotation.y = yaw
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	cam_focus = car.global_position
	_cut_camera()
	if streamer != null:
		streamer.finish_view(cam_focus, cam)


## --egg: the vehicle at the egg, for its kind of trigger; a motion trigger gets a path the rig
## drives at its pace (the 2 Hz checks judge it as they would a player).
func _egg_place() -> void:
	var t: Dictionary = _egg["trigger"]
	var kind := str(t.get("kind", ""))
	var id := str(_egg["id"])
	var e: Dictionary = egg_book.eggs[egg_book.by_id[id]] if egg_book != null and egg_book.by_id.has(id) else _egg
	_egg = e
	var at: Vector2 = e.get("at", Vector2.INF)
	if e.has("waits"):
		print("egg: --egg=%s waits for %s: its card is in the notebook, nothing finds it yet" % [id,
				egg_book.waits.get(str(e["waits"]), e["waits"])])
		_rig_t = -1.0
		return
	match kind:
		"stop", "pass", "lap", "legacy":
			# A legacy egg (eggs.gd) fires within 26-30 m of its spot: a lane within 18 m of it, else
			# 12 m off it (the palm's island, the crowd).
			var off := Vector2.ZERO
			if kind == "legacy" and eggs != null and eggs.spots.has(id):
				var v: Vector3 = eggs.spots[id]
				at = Vector2(v.x, v.z)
				off = Vector2(12.0, 0.0)
			var reach := 18.0 if kind == "legacy" else float(t.get("within", 30.0)) * 0.8
			if kind == "lap":
				var r: Array = t["r"]
				var mid := (float(r[0]) + float(r[1])) * 0.5
				_rig_path = PackedVector2Array()
				for k in 73:
					var a := TAU * k / 72.0
					_rig_path.append(at + Vector2(cos(a), sin(a)) * mid)
				_put_car_near(_rig_path[0], 1.0)
			else:
				_put_car_near(at, reach)
				if Vector2(car.global_position.x, car.global_position.z).distance_to(at) > reach:
					_put_car_near(at + off, 0.0)
				# A place on a bridge (E09): the lane on the deck, whatever the ground under it.
				var deck := _egg_deck(at, reach)
				if not deck.is_empty() and map.in_water(car.global_position.x, car.global_position.z, car.global_position.y):
					car.global_position = deck[0]
					car.rotation.y = deck[1]
					car.reset_physics_interpolation()
		"street":
			_rig_path = _street_path(e.get("pieces", PackedVector2Array()))
			if _rig_path.size() > 1:
				_put_car_near(_rig_path[0], 1.0)
		"hover", "land", "between", "circle":
			if kind == "between" and e.has("a"):
				at = (e["a"] as Vector2).lerp(e["b"], 0.5)
			var h := float(t.get("min_alt", 0.0)) + 12.0
			if kind == "circle":
				var r2: Array = t["r"]
				_rig_path = PackedVector2Array()
				var mid2 := (float(r2[0]) + float(r2[1])) * 0.5
				for k in 73:
					var a2 := TAU * k / 72.0
					_rig_path.append(at + Vector2(cos(a2), sin(a2)) * mid2)
				at = _rig_path[0]
				h = 70.0
			_put_car_near(at, 40.0)
			_take_off(h)
			var g: float = map.ground_height(at.x, at.y)
			if kind == "land":
				g = map.top_height(at.x, at.y, Heli.RADIUS)
				h = 6.0
			heli.place(Vector3(at.x, g + h, at.y), heli.rotation.y, h if kind != "land" else g + h - map.ground_height(at.x, at.y))
			_cut_camera()
		"tape":
			pass  # _start_moment plays the tape (_egg_moment set --tape)
		"event":
			# The garage loop: E01 at a club's door (crowds.gd fires it): the car at the door.
			if t.has("door") and crowds != null and crowds.by_id.has(str(t["door"])):
				var site: Dictionary = crowds.sites[crowds.by_id[str(t["door"])]]
				var door: Vector2 = site["door"]
				_put_car_near(door, Crowds.CAR_NEAR - 1.0)
				at = door
	# The start point (the place's hint) may have been in the river (E09): no tow once the car
	# stands on dry land or a deck.
	var cp := car.global_position
	if not flying and car.in_water and not map.in_water(cp.x, cp.z, cp.y):
		car.leave_water()
		_tow_wait = -1.0
	_rig_s = 0.0
	_rig_t = 0.0
	print("egg: --egg=%s %s at %.0f, %.0f (%s)" % [id, kind, at.x, at.y, egg_book.describe_state(_egg_state())])


## --egg: the lane nearest `at` within `reach` m on any level (a bridge's deck over the river),
## not in the water: [position, yaw], or [] if none.
func _egg_deck(at: Vector2, reach: float) -> Array:
	if graph == null:
		return []
	var hit := graph.snap(at, reach, Vector2.ZERO)
	if hit.is_empty():
		return []
	var e: int = hit[0]
	var lane_s: float = hit[2]
	var h := graph.height(e, lane_s)
	var q := graph.point_at(e, lane_s, graph.lane_offset(e, hit[1]))
	if map.in_water(q.x, q.y, h):
		return []
	var d := graph.direction(e, lane_s)
	return [Vector3(q.x, h, q.y), atan2(-d.x, -d.y)]


## The named street's pieces in order along it (from one end to the other).
func _street_path(pieces: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	if pieces.size() < 2:
		return out
	# The two pieces furthest apart are the ends; the rest by their distance along that line.
	var a := pieces[0]
	var b := pieces[1]
	var far := -1.0
	for p in pieces:
		for q in pieces:
			var d := p.distance_squared_to(q)
			if d > far:
				far = d
				a = p
				b = q
	var dir := (b - a).normalized()
	var order: Array = []
	for p in pieces:
		order.append([(p - a).dot(dir), p])
	order.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	for o: Array in order:
		out.append(o[1])
	return out


## The --egg rig, each frame: a lap or a street driven at 90 % of its speed limit, the
## helicopter round its circle, sinking onto its roof, or holding still.
func _egg_rig(dt: float) -> void:
	_rig_t += dt
	var t: Dictionary = _egg["trigger"]
	var kind := str(t.get("kind", ""))
	if egg_book != null and egg_book.is_found(str(_egg["id"])):
		if _rig_t < 1e6:
			print("egg: --egg=%s found %.1f s after the start" % [_egg["id"], _rig_t])
			_rig_t = 1e7
		if kind in ["lap", "street", "circle"]:
			car.vel = Vector3.ZERO
		return
	if egg_log and int(_rig_t / 10.0) != int((_rig_t - dt) / 10.0):
		print("egg: --egg=%s not yet after %.0f s (%s)" % [_egg["id"], _rig_t, egg_book.describe_state(_egg_state())])
	match kind:
		"lap", "street", "circle":
			if _rig_path.size() < 2:
				return
			var speed := float(t.get("max_kmh", 72.0)) * 0.9 / 3.6
			_rig_s += speed * dt
			var i := 0
			var left := _rig_s
			while i < _rig_path.size() - 1 and left > _rig_path[i].distance_to(_rig_path[i + 1]):
				left -= _rig_path[i].distance_to(_rig_path[i + 1])
				i += 1
			if i >= _rig_path.size() - 1:
				_rig_s = 0.0
				i = 0
				left = 0.0
			var a := _rig_path[i]
			var b := _rig_path[i + 1]
			var dir := (b - a).normalized()
			var p := a + dir * left
			var v := Vector3(dir.x, 0.0, dir.y) * speed
			if kind == "circle":
				heli.global_position = Vector3(p.x, heli.global_position.y, p.y)
				heli.vel = v
			else:
				car.global_position = Vector3(p.x, map.ground_height(p.x, p.y) + 0.05, p.y)
				car.rotation.y = atan2(-dir.x, -dir.y)
				car.vel = v
		"land":
			heli.climb = -1.0
		"hover", "between":
			heli.input_dir = Vector3.ZERO
		_:
			car.vel = Vector3.ZERO


# --- loop 3g-1: the police ---------------------------------------------------------------------

## The police (police.gd, docs/design/police.md): patrol cars in the traffic, the day's speed
## traps, chases that end by themselves and the pull-over. Built after the sound.
func _build_police(data: Dictionary, world: Node3D) -> void:
	police = Police.new()
	police_opts["traffic_level"] = traffic_level
	# --barriers=YYYYMMDD places the day's speed traps too (like the roadworks).
	police_opts["day"] = barrier_day
	var nodes := {"map": map, "graph": graph, "traffic": traffic, "car": car, "cam": cam, "hud": hud,
			"bubbles": bubbles, "dialogue": dialogue, "wallet": wallet, "walkers": walkers, "radio": radio, "sfx": sfx,
			"jobs": jobs, "missions": missions, "tod": tod, "opts": police_opts, "pedal": hold_pedal, "autopilot": autopilot,
			"rivals": rivals, "ped_zones": ped_zones,
			"level_now": func() -> int: return traffic_level,
			"project": func(p: Vector3) -> Vector2: return cam.unproject_position(p) * float(view.stretch_shrink)}
	add_child(police)
	police.setup(nodes, data, world)


## The police's testing flags (README's flags table): --no-police, --police=1|2|3, --trap=N,
## --pullover=routine|trap|kebab|sloik|generic, --police-auto=escape|stop|hold, --police-now,
## --police-log, --police-offence=FRAME:kind,... Loop 3g-2: --escort, --guards, --clamp[=sorry],
## --first-contact (police.md 14).
func _police_flag(arg: String) -> void:
	if arg == "--no-police":
		police_opts["off"] = true
	elif arg == "--escort":
		police_opts["escort"] = true
	elif arg == "--first-contact":
		police_opts["first_contact"] = true
		show_title = false
		free_roam = true
	elif arg == "--guards" or arg == "--guards=talk":
		# The Krakowskie Przedmieście end of the zone, heading north into it (police.gd drives;
		# =talk stops by the gate's guards).
		police_opts["guards"] = "talk" if arg == "--guards=talk" else "drive"
		start_at = Vector3(-696.0, 0.0, -1279.0)
		start_heading = 345.0
		show_title = false
		free_roam = true
	elif arg == "--clamp" or arg.begins_with("--clamp="):
		# Parked on Plac Zamkowy 15 m from a guard; the clamp's countdown starts at frame 60.
		police_opts["clamp"] = arg.trim_prefix("--clamp=") if arg.begins_with("--clamp=") else "wait"
		start_at = Vector3(-690.0, 0.0, -1490.0)
		start_heading = 250.0
		show_title = false
		free_roam = true
	elif arg == "--police-now":
		police_opts["now"] = true
	elif arg == "--police-log":
		police_opts["log"] = true
	elif arg.begins_with("--police-auto="):
		police_opts["auto"] = arg.trim_prefix("--police-auto=")
	elif arg.begins_with("--police-offence="):
		police_opts["offences"] = arg.trim_prefix("--police-offence=")
	elif arg.begins_with("--police="):
		police_opts["level"] = clampi(int(arg.trim_prefix("--police=")), 1, 3)
		show_title = false
		free_roam = true
	elif arg.begins_with("--trap="):
		var n := int(arg.trim_prefix("--trap="))
		police_opts["trap"] = n
		var start := Police.trap_start(n)
		if not start.is_empty():
			start_at = start[0]
			start_heading = start[1]
		show_title = false
		free_roam = true
	elif arg.begins_with("--pullover="):
		police_opts["pullover"] = arg.trim_prefix("--pullover=")
		show_title = false
		free_roam = true
	elif arg.begins_with("--pullover-frame="):
		# Loop 2d-1: the --pullover conversation at frame N (default 60), e.g. during a --ride.
		police_opts["pullover_frame"] = maxi(1, int(arg.trim_prefix("--pullover-frame=")))


## The game's own options. Loop 2b: a launcher can swallow the "--" (devicectl on an iPhone):
## then they arrive among the engine's own; ours never share a name with those. Every parser of
## game flags reads this (loop G0+: the streaming flags read only the user args, so on the phone
## --stream-soak and --stream-log did nothing and the soak never ran). A release build reads none
## (release.gd: the testing flags are stripped from what players get).
static func game_args() -> PackedStringArray:
	return Release.game_args()


func _parse_args() -> void:
	start_station = 1
	for arg in game_args():
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
				shots.append(int(s))
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
				start_at = Vector3(shot_spots[0][1].x, 0.0, shot_spots[0][1].y)
				if shot_spots[0][2] != INF:
					start_heading = shot_spots[0][2]
		elif arg.begins_with("--style="):
			_flag_style = posmod(int(arg.trim_prefix("--style=")), STYLES.size())
		elif arg.begins_with("--stops="):
			stops = JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--stops=")))
		elif arg.begins_with("--at="):
			var xz := arg.trim_prefix("--at=").split(",")
			start_at = Vector3(float(xz[0]), 0.0, float(xz[1]))
		elif arg.begins_with("--heading="):
			start_heading = float(arg.trim_prefix("--heading="))
		elif arg.begins_with("--pitch="):
			camera_pitch = float(arg.trim_prefix("--pitch="))
			_flag_pitch = true
		elif arg.begins_with("--lines="):
			lines_override = int(arg.trim_prefix("--lines="))
		elif arg.begins_with("--sun="):
			sun_pitch = float(arg.trim_prefix("--sun="))
		elif arg == "--debug-ao":
			debug_ao = true
		elif arg.begins_with("--solo="):
			solo_site = arg.trim_prefix("--solo=")
			MapBuilder.solo_site = solo_site
			no_traffic = true
		elif arg.begins_with("--solo-look="):
			solo_look = arg.trim_prefix("--solo-look=")
		elif arg == "--tunnel":
			start_in_tunnel = true
		elif arg == "--under":
			start_under = true
		elif arg == "--debug-roads":
			debug_roads = true
		elif arg.begins_with("--lift="):
			cam_lift = float(arg.trim_prefix("--lift="))
		elif arg.begins_with("--ghost-debug="):
			ghost_debug = int(arg.trim_prefix("--ghost-debug="))
		elif arg == "--prebuilt":
			prebuilt = true
		elif arg == "--no-ao":
			no_ao = true
		elif arg == "--nohud":
			hide_hud = true
		elif arg == "--no-touch":
			no_touch = true  # desktop: --no-touch
		elif arg == "--no-input":
			# Loop 3d-1: a test render ignores every key, click and touch (check_streaming's windows
			# take the focus for minutes: keys typed elsewhere toggled the time, the overlay, the radio).
			# The window never takes the focus, so keys typed elsewhere stay there.
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		elif arg.begins_with("--size="):
			base_size = float(arg.trim_prefix("--size="))
			_flag_size = true
		elif arg == "--fixed":
			_flag_fixed = true
		elif arg.begins_with("--yaw="):
			cam_yaw = float(arg.trim_prefix("--yaw="))
			cam_yaw_target = cam_yaw
			_flag_yaw = true
		elif arg == "--cinematic" or arg.begins_with("--cinematic="):
			_flag_cinematic = arg.trim_prefix("--cinematic=") if arg.contains("=") else "all"
		elif arg == "--heli":
			start_flying = true
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
		elif arg == "--vhs":
			_flag_vhs = true
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
		# --- loop 2d-1: Podwózka's flags ---
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
		elif arg.begins_with("--tap="):
			var xy := arg.trim_prefix("--tap=").split(",")
			tap_at = Vector2(float(xy[0]), float(xy[1]))
		elif arg.begins_with("--weather="):
			start_weather = Weather.parse(arg.trim_prefix("--weather="))
		elif arg.begins_with("--clock="):
			live_clock = arg.trim_prefix("--clock=")
		elif arg.begins_with("--date="):
			live_date = int(arg.trim_prefix("--date="))
		elif arg == "--perf":
			_flag_perf = true
		elif arg == "--sound-check":
			sound_check = true
		elif arg.begins_with("--quality="):
			_flag_quality = Tiers.parse(arg.trim_prefix("--quality="))
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
		elif arg.begins_with("--quest-pick="):
			quest_pick_flag = int(arg.trim_prefix("--quest-pick="))
			open_map_at_start = true
		elif arg == "--fullmap" or arg.begins_with("--fullmap="):
			open_map_at_start = true
			# --fullmap=M (2026-10-31): open it M metres across the screen's height (shots).
			if arg.contains("="):
				fullmap_span = maxf(1.0, float(arg.trim_prefix("--fullmap=")))
		elif arg == "--notebook" or arg.begins_with("--notebook="):
			# Loop MW-1: the notebook's tab at the start (a chapter, or a place's card).
			open_settings_at_start = true
			settings_tab = 4
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
		elif arg == "--rave-log":
			rave_log = true
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
			quest_tab_flag = int(arg.trim_prefix("--quest-tab="))
		elif arg.begins_with("--boat-race"):
			boat_flag = arg.trim_prefix("--boat-race=") if arg.contains("=") else "call"
		elif arg == "--boat-log":
			boat_log = true
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
		elif arg.begins_with("--honk="):
			for f in arg.trim_prefix("--honk=").split(",", false):
				honk_frames.append(int(f))
		elif arg.begins_with("--life="):
			life_flag = clampi(int(arg.trim_prefix("--life=")), 0, 2)
		elif arg == "--dogs-log":
			dogs_log = true
		elif arg == "--trend-log":
			trend_log = true
		elif arg == "--life-log":
			life_log = true
		elif arg == "--life-soak":
			life_soak = true
			life_log = true
		elif arg == "--dzemini":
			dzemini_flag = true
			trend_log = true
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
			club_flag = arg.trim_prefix("--club=")
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
		elif arg == "--spacer" or arg == "--wander":
			spacer_flag = 1
		elif arg == "--no-spacer":
			spacer_flag = 0
		elif arg == "--zone-cap":
			zone_cap_flag = 1
		elif arg == "--no-zone-cap":
			zone_cap_flag = 0
		elif arg.begins_with("--spacer-hint="):
			spacer_hint = float(arg.trim_prefix("--spacer-hint="))
		elif arg == "--fotka" or arg == "--photo":
			fotka_flag = true
		elif arg.begins_with("--kadr="):
			kadr_flag = arg.trim_prefix("--kadr=")
			fotka_flag = true
		elif arg.begins_with("--fotka-shot="):
			fotka_shot = float(arg.trim_prefix("--fotka-shot="))
		elif arg == "--photo-log":
			photo_log = true
		elif arg.begins_with("--settings-tab="):
			open_settings_at_start = true
			settings_tab = int(arg.trim_prefix("--settings-tab="))
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
			ram_test = 1
		elif arg == "--first-life":
			first_life = true
		elif arg == "--traffic-overlaps":
			_traffic_overlaps = true
		elif arg.begins_with("--tram-watch="):
			tram_watch = int(arg.trim_prefix("--tram-watch="))
		elif arg == "--cam-log":
			cam_log = true
		elif arg.begins_with("--cam-test="):
			cam_test = arg.trim_prefix("--cam-test=")
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
	if demo or not shots.is_empty() or autopilot or start_race > 0 or start_mission > 0 or start_rival > 0 or bench or probe \
			or start_kebab >= 0 or start_sloik >= 0 or sound_check or open_settings_at_start or open_map_at_start or hold_stick != Vector2.INF or bench_button \
			or _water_test_at != Vector2.INF or cam_test != "" or ram_test > 0 or tram_watch >= 0 or old_tram_flag != "" or first_life:
		show_title = false
	if start_ride >= 0 or place_flag != "" or roundup_flag or district_card != "" or syrenka_flag != "" or trzy_mosty_flag:
		show_title = false  # loop 2d-1: --ride is a test run too (loop MW-1: and --place; loop 3h: --district=)
	# Loop MW-6: and the eggs', the tape's and Fotka's flags; --egg sets its moment's time.
	if egg_flag != "" or tape_flag != "" or fotka_flag or spacer_hint >= 0.0 or pop_flag > 0:
		show_title = false
	if first10_flag or end_card_flag or first_race_flag:
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
		if live_date == 0 or not _is_wednesday(live_date):
			live_date = 20261028
	elif life_soak and start_time == TimeOfDay.DAY:
		start_time = TimeOfDay.DUSK
	_egg_moment()
	if force_title:
		show_title = true
	# Camera loop: the cinematic moments in a normal launch only (never with screenshots or a bench).
	var normal := show_title and shots.is_empty() and not bench and not probe and not bench_button and not demo
	cinematic_flyin = normal or _flag_cinematic in ["all", "flyin", "opening"]
	cinematic_look = normal or _flag_cinematic in ["all", "look"]
	# Loop G1: the governor runs in a normal launch; test runs hold it so they repeat.
	var test_run := DisplayServer.get_name() == "headless" or not shots.is_empty() or bench or probe or autopilot \
			or demo or cam_test != "" or _water_test_at != Vector2.INF or ram_test > 0 or tram_watch >= 0
	_governor_on = _flag_governor == 1 if _flag_governor >= 0 else not test_run
	# The crash scenes' timer: a normal launch only (a test run with --crash=on or =now too).
	_crash_auto = not test_run
	_rave_auto = not test_run
	_meet_auto = not test_run
	_ev_auto = not test_run
	# Loop G1b: test runs (and --last-session=) never write Auto's image state, even with the
	# governor on and without --nosave.
	_image_write = not test_run and _flag_last_session == ""


## Loop 2a: the saved settings (not with --nosave), then the command-line flags over them.
## Loop G1: the quality the player chose (Auto by default) and the level Auto picks here.
func _load_settings() -> void:
	settings.persistent = not no_save
	settings.load_file()
	Lang.set_code(_flag_lang if _flag_lang in Lang.CODES else Lang.resolve(settings.lang))
	Access.apply(settings)
	if _flag_left_handed:
		Access.left_handed = true
	if _flag_color_safe:
		Access.color_safe = true
	if not _flag_size:
		base_size = settings.view
	if not _flag_pitch:
		camera_pitch = -settings.pitch
	model_name = _flag_model if _flag_model != "" else OS.get_model_name()
	auto_quality = Tiers.for_model(model_name)
	quality_choice = _flag_quality if _flag_quality != -2 else settings.quality
	quality = auto_quality if quality_choice == Tiers.AUTO else quality_choice
	print("quality: %s · Auto picks %s for %s" % [Tiers.describe(quality_choice, quality, model_name),
			Tiers.NAMES[auto_quality], model_name])
	# Loop G1b: Auto's sharp image or its fallback, from the saved state (or --last-session=).
	var image := settings.auto_image
	if _flag_last_session == "struggled":
		image = Tiers.sharp_struggled(Tiers.sharp_state(), true, "--last-session=struggled")
	elif _flag_last_session == "calm":
		image = Tiers.sharp_state()
	elif _flag_last_session != "":
		push_warning("--last-session=%s: struggled or calm" % _flag_last_session)
	auto_image = Tiers.sharp_launch(image)
	auto_sharp = not auto_image["fallback"]
	print("quality: Auto's image state (where the budget binds) %s → this launch %s%s" % [settings.image_summary(), "sharp" if auto_sharp else "fallback",
			" (%s)" % ("--last-session=" + _flag_last_session) if _flag_last_session != "" else ""])
	traffic_level = _flag_traffic if _flag_traffic >= 0 else settings.traffic
	show_perf = _flag_perf or settings.perf
	zone_cap_on = zone_cap_flag == 1 if zone_cap_flag >= 0 else settings.zone_cap
	var scheme := _flag_controls if _flag_controls >= 0 else settings.controls
	if _flag_fixed and scheme == Controls.POINT:
		scheme = Controls.FIXED
	controls.scheme = scheme
	follow = scheme == Controls.POINT or (scheme == Controls.CLASSIC and settings.classic_follow and not _flag_fixed)
	# 2026-11-01 (F): no style picker any more, always Sharp (--style= stays for tests).
	style_index = _flag_style if _flag_style >= 0 else 0
	vhs = _flag_vhs or settings.vhs
	print("settings: %s (%s)" % [settings.summary(), ProjectSettings.globalize_path(Settings.PATH) if not no_save else "not saved"])


## The day's light; time_of_day.gd changes it for dusk and night.
func _add_environment(world: Node3D) -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#a8cde6")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b6c6db")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	sun = DirectionalLight3D.new()
	sun.light_color = Color("#ffe8c8")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 900.0
	sun.shadow_bias = 0.06
	sun.rotation_degrees = Vector3(sun_pitch, -20.0, 0.0)
	world.add_child(sun)


func _add_post_pass() -> void:
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2, 2)
	mesh.flip_faces = true
	quad.mesh = mesh
	quad.extra_cull_margin = 16384.0
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	post_mat = ShaderMaterial.new()
	post_mat.shader = load("res://shaders/post.gdshader")
	quad.material_override = post_mat
	cam.add_child(quad)
	quad.position = Vector3(0, 0, -2)


## Night-only things (neon signs, lamp halos, vehicle light cones, signal halos,
## the helicopter's lights) show only while the city's lights are on, so the day
## renders exactly as before.
func _show_night_nodes(on: bool) -> void:
	for holder in ["Neon", "LampHalos"]:
		var n := map.get_node_or_null(holder) as Node3D
		if n != null:
			n.visible = on
	get_tree().call_group("night_lights", "set_visible", on)


## The VHS overlay runs on the container that scales the pixel image up to the
## screen, so its scanlines are sharp screen pixels.
func _set_vhs(on: bool) -> void:
	vhs = on
	if on:
		if _vhs_mat == null:
			_vhs_mat = ShaderMaterial.new()
			_vhs_mat.shader = load("res://shaders/vhs.gdshader")
		var screen := get_viewport().get_visible_rect().size
		_vhs_mat.set_shader_parameter("line_px", maxf(2.0, roundf(screen.y / 360.0)))
		view.material = _vhs_mat
	else:
		view.material = null


func _blip_sound() -> void:
	if _blip != null and _blip.stream != null:
		_blip.play()


func _rotate_camera(direction: int) -> void:
	if follow:
		_toggle_follow()
	# Fixed mode keeps the classic diagonal views: 45°, 135°, 225°, 315°.
	cam_yaw_target = 45.0 + 90.0 * roundf((cam_yaw - 45.0) / 90.0) + 90.0 * direction


## C (and Settings → Kamera za autem): the camera follows the car or stays put. Loop 2e: a toast
## says which, so it never switches off unnoticed (it did with the old CAM button).
func _toggle_follow() -> void:
	_set_follow(not follow)
	hud.toast("Kamera: za autem" if follow else "Kamera: stała", "Camera: follows the car" if follow else "Camera: fixed")
	# Loop 2a: in the point schemes the camera is the scheme (Point follows, Fixed doesn't).
	if controls.scheme != Controls.CLASSIC:
		_set_scheme(Controls.POINT if follow else Controls.FIXED, false)
	else:
		settings.classic_follow = follow
		settings.save()


func _set_follow(on: bool) -> void:
	follow = on
	if not follow:
		cam_yaw_target = 45.0 + 90.0 * roundf((cam_yaw - 45.0) / 90.0)


## Loop 2a: a control scheme (drive_controls.gd); Point turns the follow camera on, Fixed off,
## Classic takes its saved camera. Saved.
func _set_scheme(scheme: int, set_camera := true) -> void:
	controls.scheme = scheme
	settings.controls = scheme
	settings.save()
	hud.set_scheme(scheme)
	if set_camera:
		_set_follow(scheme == Controls.POINT or (scheme == Controls.CLASSIC and settings.classic_follow))


## Loop 2a: the settings panel (the gear, Esc, --settings). The game pauses under it.
func _open_settings() -> void:
	if not _started or title != null or hud.settings_open():
		return
	if _phone_bench:
		_end_phone_bench(false)
	print("settings panel: open (paused)")
	_blip_sound()
	get_tree().paused = true
	hud.open_settings(_settings_state())


## F's asks (2026-10-30): the full-screen map (hud.gd, full_map.gd) on the car or the helicopter,
## the notebook's places found on it. The game pauses under it, like the settings card.
func _open_full_map() -> void:
	if not _started or title != null or hud.settings_open() or hud.full_map_open():
		return
	if _phone_bench:
		_end_phone_bench(false)
	var pos := _vehicle_position()
	var yaw: float = heli.rotation.y if flying else car.rotation.y
	var found := PackedVector2Array()
	if notes != null:
		notes._update_minimap(Vector2(pos.x, pos.z))  # the "?" marks as they are here now
		for place: Dictionary in notes.places:
			if notes.is_found(str(place["id"])):
				found.append(place["at"])
	hud.set_night(tod.lights_on)  # its palette (the minimap's), even before the first frame
	_main_t = 0.0
	_main_line_tick(0.0)  # the main line's step as it is now (the map can open before the first look)
	_story_key = ""
	_story_tick()  # the questlines' starts and quest focus as they are now (the same)
	print("full map: open (paused), %d places found on it" % found.size())
	_blip_sound()
	get_tree().paused = true
	if hud.full_map != null:
		hud.full_map.hospitals = missions != null and missions.has_target()  # only a rescue needs them
	hud.open_full_map(Vector2(pos.x, pos.z), yaw, found)
	hud.full_map.hospitals = missions != null and missions.has_target()
	if fullmap_span > 0.0:
		hud.full_map.show_span(fullmap_span)
		fullmap_span = 0.0
	if districts != null and districts.ready_ok:
		hud.full_map.set_districts(districts.view(), districts.percent_total(), syrenki.found_count() if syrenki != null else 0,
				syrenki.entries.size() if syrenki != null else 0)  # loop 3h slice 1 (+ slice 2: the Syrenki line)
	if rivals != null:
		hud.full_map.set_ladder(rivals.ladder_rows())  # loop 3h slice 3: the DRABINKA card
	hud.full_map.set_quests(_quest_entries(), Lines.Line.HELI if flying else Lines.Line.CAR,
			str(quest_pin.get("id", "")))  # G12 part 2: the ZADANIA card
	if quest_tab_flag >= 0:
		hud.full_map.show_line(quest_tab_flag)
		quest_tab_flag = -1
	_wire_full_map()
	if quest_pick_flag >= 0:
		var rows: Array = hud.full_map.quest_rows
		print("quest list: %d rows on the %s tab: %s" % [rows.size(), "HELI" if flying else "AUTO",
				", ".join(rows.map(func(r: Dictionary) -> String: return "%s %s" % [r["id"], r["far"][1]]))])
		hud.full_map.pick_row(quest_pick_flag)
		quest_pick_flag = -1
		if hud.full_map.is_open():
			hud.full_map.close()


## The full map's signals and its refusal, once. PT-19 (2026-11-07): `can_teleport` sat under
## the quest-pick test flag since G12 part 2, so in play a hold teleported mid-race, mid-job or
## mid-chase with no "not now".
func _wire_full_map() -> void:
	if hud.full_map.closed.is_connected(_close_full_map):
		return
	hud.full_map.closed.connect(_close_full_map)
	hud.full_map.teleport.connect(_teleport_from_map)
	hud.full_map.quest_picked.connect(_on_quest_picked)
	hud.full_map.can_teleport = _teleport_refusal


## G12 part 2: what the ZADANIA card lists now (quest_lines.gd entries). AUTO: the kebab stands,
## the słoiki stations and the Leżak depots (jobs.gd `offer_places`), Warsztat u Mirka, and "ask for
## a ride" (Podwózka's rule). HELI: the cassettes on the roofs not taken, and "a rescue call" (one
## only the helicopter reaches). Nothing while a race, a job or a rescue is on.
## G12c: AUTO also lists the open "Na czasie" slots, Mrożulo's van (Mlask) and the Friday drop
## (trend_job.gd `offer_places`), and the ladder's next rival where they cruise now (or Seba's start
## for "Trzy mosty" at night); HELI the peacock's roof call while Pan Paw is still up there. While a
## race, a job, a ride or a rescue is on, its one row ("Teraz · ...") leads the vehicle's tab.
func _quest_entries() -> Array:
	var out: Array = []
	var now := _quest_now()
	if not now.is_empty():
		return [now]
	if (rivals != null and rivals.busy()) or (missions != null and missions.has_target()):
		return out
	var places: Array = jobs.offer_places() if jobs != null else []
	if trend_job != null and (jobs == null or not jobs.busy()) and (rides == null or not rides.busy()):
		places.append_array(trend_job.offer_places())
	for p: Dictionary in places:
		out.append(Lines.entry("%s_%.0f_%.0f" % [p["group"], p["at"].x, p["at"].y], str(p["group"]), Lines.Line.CAR,
				str(p["name"][0]), str(p["name"][1]), p["at"], p["colour"]))
	if jobs != null and jobs.busy():
		return out
	if rivals != null and rivals.ladder != null and wallet != null:
		var nxt: int = rivals.ladder.next_rung()
		# Pani Halina (rung 0) comes to the player in the guided first race, so she is listed only
		# once that race is behind them.
		if nxt < Ladder.FINAL and rivals.ladder.is_open(nxt) and (nxt > 0 or str(rivals.first_result) != ""):
			var who := str(Ladder.RUNGS[nxt]["rival"])
			var r_at: Vector2 = rivals.rival_at(who)
			if r_at != Vector2.INF:
				var re := Lines.entry("rival", "rival", Lines.Line.CAR, "Rywal · %s" % who, "Rival · %s" % who, r_at,
						Rivals.RACE_COLOUR)
				re["who"] = who
				out.append(re)
		elif nxt == Ladder.FINAL and rivals.start_marker() != Vector2.INF:
			out.append(Lines.entry("final", "final", Lines.Line.CAR, "Trzy mosty · Seba czeka", "Three bridges · Seba waits",
					rivals.start_marker(), Rivals.FINAL_COLOUR))
	if rides != null and rides.can_request():
		out.append(Lines.entry("ride", "ride", Lines.Line.CAR, "Podwózka · poproś o kurs", "Podwózka · ask for a ride",
				Vector2.INF, Rides.COLOUR, "ride"))
	if garage != null and garage.at != Vector3.INF:
		out.append(Lines.entry("garage", "garage", Lines.Line.CAR, "Warsztat u Mirka", "Mirek's garage",
				Vector2(garage.at.x, garage.at.z), Garage.GARAGE_COLOUR))
	if missions != null and missions.can_request():
		out.append(Lines.entry("call", "call", Lines.Line.HELI, "Wezwanie · ratunek z helikoptera",
				"Rescue call · by helicopter", Vector2.INF, Lines.HELI_COLOUR, "call"))
		if missions.peacock_open():
			out.append(Lines.entry("peacock", "peacock", Lines.Line.HELI, "Pan Paw · utknął na dachu",
					"Mr Peacock · stuck on a roof", Vector2.INF, Lines.HELI_COLOUR, "peacock"))
	if stories != null:
		var c: Array = stories.clock.call()
		out.append_array(StoryQuests.entries(stories.defs, float(c[0]), int(c[1])))  # the WĄTKI tab
	if cassettes != null and cassettes.ready_ok:
		for c: Dictionary in cassettes.entries:
			var at: Vector3 = c.get("pos", Vector3.INF)
			if at == Vector3.INF or cassettes.is_taken(str(c["id"])):
				continue
			var nm: Array = c.get("name", ["", ""])
			out.append(Lines.entry("cassette_" + str(c["id"]), "cassette", Lines.Line.HELI, "Kaseta · %s" % nm[0],
					"Cassette · %s" % nm[1], Vector2(at.x, at.z), Cassettes.COLOUR))
	return out


## G12c: the row for what is under way ({} when nothing is): a race, a job (Na czasie, Mlask,
## Limitka, Czwarty...), a ride, a side job or a rescue, on the vehicle's own tab, with its target.
func _quest_now() -> Dictionary:
	var what: Array = []
	var at := Vector3.INF
	var colour := Color.WHITE
	if rivals != null and rivals.has_target():
		what = ["Teraz · Trzy mosty", "Now · Three bridges"] if rivals.final_on else ["Teraz · wyścig do mety", "Now · race to the finish"]
		at = rivals.target_position()
		colour = rivals.target_colour()
	elif trend_job != null and trend_job.has_target():
		what = ["Teraz · zlecenie na czasie", "Now · on-trend job"]
		at = trend_job.target_position()
		colour = trend_job.target_colour()
	elif rides != null and rides.has_target():
		what = ["Teraz · Podwózka", "Now · Podwózka ride"]
		at = rides.target_position()
		colour = rides.target_colour()
	elif jobs != null and jobs.has_target():
		what = ["Teraz · zlecenie", "Now · job"]
		at = jobs.target_position()
		colour = jobs.target_colour()
	elif missions != null and missions.has_target():
		what = ["Teraz · akcja ratunkowa", "Now · rescue"]
		at = missions.target_position()
		colour = missions.target_colour()
	if what.is_empty():
		return {}
	var line := Lines.Line.HELI if flying else Lines.Line.CAR
	var xz := Vector2(at.x, at.z) if at != Vector3.INF else Vector2.INF
	return Lines.entry("now", "now", line, str(what[0]), str(what[1]), xz, colour, Lines.NOW)


## G12 part 2: a row of the ZADANIA card: a request starts now (the map has closed: a ride's
## request, or a heli rescue call's card), a place becomes the quest pin ({}: the pin goes).
func _on_quest_picked(e: Dictionary) -> void:
	match str(e.get("action", "")):
		"ride":
			rides.request()
			quest_pin = {}
		"call":
			missions.request_call(true)
			quest_pin = {}
		"peacock":
			missions.request_peacock()
			quest_pin = {}
		"story":
			# The beta list: the questline's friend phones now, any hour (story_quests.gd `start`).
			quest_pin = {}
			if not stories.start(str(e.get("story", ""))):
				hud.toast("Nie teraz: najpierw skończ to, co trwa", "Not now: finish what's on first")
		Lines.NOW:
			return  # G12c: the quest under way keeps its own arrow
		_:
			quest_pin = e
	print("quest list: %s" % (str(e["id"]) if not e.is_empty() else "pin off"))


## F's ask (2026-10-31): why a hold on the full map can't teleport now ([pl, en]), or [] when it
## can. Not in the middle of something the jump would skip or cheat: a race, a job or a ride, a
## rescue, a police chase, the first 10 minutes' guide.
func _teleport_refusal() -> Array:
	if rivals != null and rivals.racing():
		return ["Nie teraz: trwa wyścig", "Not now: you're racing"]
	if (jobs != null and jobs.busy()) or (jobs != null and jobs.courier != null and jobs.courier.racing()):
		return ["Nie teraz: masz zlecenie", "Not now: you're on a job"]
	if missions != null and missions.has_target():
		return ["Nie teraz: trwa akcja ratunkowa", "Not now: a rescue is on"]
	if police != null and police.chasing():
		return ["Nie teraz: policja siedzi ci na ogonie", "Not now: the police are on your tail"]
	return []


## F's ask (2026-10-31): the full map's hold, held: the car onto the lane nearest that spot (in its
## direction of travel), or the nearest lane anywhere when none is within reach; the helicopter
## keeps its height. The camera cuts there; the city streams in round it as on any drive.
func _teleport_from_map(p: Vector2) -> void:
	if flying:
		heli.global_position = Vector3(p.x, heli.global_position.y, p.y)
		heli.vel = Vector3.ZERO
		heli.reset_physics_interpolation()
		cam_focus = heli.global_position
		fcam.reset_lead()
		print("teleport: the helicopter to %.0f, %.0f" % [p.x, p.y])
		return
	var at := Vector3(p.x, map.terrain_height(p.x, p.y), p.y)
	# GAMEPLAY_PLAN 0.1: a hold over the river, by a bridge, lands on the bridge (its deck's
	# level), not on a bank road hundreds of metres away.
	if graph != null and map.in_water(at.x, at.z, at.y):
		var deck := graph.snap(p, 80.0, Vector2.ZERO, true, false, true)
		if not deck.is_empty() and graph.e_dk[deck[0]] >= 0:
			at.y = graph.height(deck[0], deck[2])
	var spot := _lane_spot(at, car.rotation.y)
	if spot.is_empty():
		spot = _node_spot(at)
	if spot.is_empty():
		print("teleport: no lane near %.0f, %.0f" % [p.x, p.y])
		return
	# GAMEPLAY_PLAN 0.1: the lane point, or the nearest spot to it where the car's box is free
	# (a parked car, a shelter, a tunnel portal's wall), as the tow does.
	var to := _free_car_spot(spot[0], spot[1])
	car.global_position = Vector3(to.x, to.y + 0.05, to.z)
	car.rotation.y = spot[1]
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	_cut_camera()
	print("teleport: the car to %.0f, %.0f (asked %.0f, %.0f), heading %.0f" % [to.x, to.z, p.x, p.y, _compass_yaw(spot[1])])


## GAMEPLAY_PLAN 0.1: --teleport-test (see TELEPORT_TESTS).
func _teleport_test() -> void:
	var bad := 0
	# PT-19: the map's hold asks main.gd first (a race, a job, a rescue, a chase say no).
	if hud.full_map == null:
		hud.open_full_map(Vector2.ZERO, 0.0, PackedVector2Array())  # makes the map (the title may be up)
	_wire_full_map()
	if hud.full_map == null or not hud.full_map.can_teleport.is_valid():
		bad += 1
		push_error("teleport test: the full map has no refusal (can_teleport), so a hold teleports mid-race")
	if hud.full_map != null and hud.full_map.is_open():
		hud.full_map.close()
	for t: Array in TELEPORT_TESTS:
		var asked := Vector2(t[0], t[1])
		_teleport_from_map(asked)
		var p := car.global_position
		var ground: float = map.terrain_height(p.x, p.z)
		var level: float = map.drive_height(p.x, p.z, p.y)
		var why := ""
		if map.in_tunnel(p.x, p.z, p.y) or p.y < ground - 1.0:
			why = "in a tunnel (%.1f m under the ground)" % (ground - p.y)
		elif absf(p.y - level) > 1.0:
			why = "off the road's level (%.1f m)" % (p.y - level)
		elif Vector2(p.x, p.z).distance_to(asked) > 110.0:
			why = "%.0f m from where it was asked" % Vector2(p.x, p.z).distance_to(asked)
		if why != "":
			bad += 1
			push_error("teleport test: %s: the car at %.0f, %.1f, %.0f is %s" % [t[2], p.x, p.y, p.z, why])
		else:
			print("teleport test: %s: %.0f, %.0f, %.1f m over the ground" % [t[2], p.x, p.z, p.y - ground])
	if bad == 0:
		print("teleport test: OK %d/%d" % [TELEPORT_TESTS.size(), TELEPORT_TESTS.size()])
	get_tree().quit(1 if bad > 0 else 0)


func _close_full_map() -> void:
	print("full map: closed")
	get_tree().paused = false
	_blip_sound()


## What the settings panel shows (loop 2e: also the camera, time of day, weather, style, VHS).
func _settings_state() -> Dictionary:
	# Loop G1: the panel's quality row is Auto, then Low..Ultra (the choice + 1).
	# Loop G1b: what Auto draws here: "High ostry" (the sharp image), "High ×2" (the fallback)
	# where its budget binds, else the level.
	var auto_name: String = Tiers.NAMES[auto_quality]
	if lines_override <= 0 and Tiers.budget_binds(get_viewport().get_visible_rect().size, STYLES[style_index]["lines"], auto_quality):
		auto_name += " ostry" if auto_sharp else " ×%d" % Tiers.image_scale(get_viewport().get_visible_rect().size,
				STYLES[style_index]["lines"], auto_quality)
	return {"controls": controls.scheme, "follow": follow, "traffic": traffic_level, "quality": quality_choice + 1,
			"auto": auto_name,
			"master": settings.master, "music": settings.music, "effects": settings.effects, "perf": int(show_perf),
			"fps": maxi(0, Settings.FPS.find(settings.fps)), "style": style_index, "vhs": int(vhs),
			"angle": maxi(0, FollowCamera.PITCHES.find(-camera_pitch)),
			"weather": weather.state, "time": tod.mode, "wander": int(spacer != null and spacer.on), "zones": int(zone_cap_on), "handling": settings.handling, "chatter": settings.chatter, "sensitivity": settings.sensitivity,
			"text_large": int(settings.text_large), "calm": int(settings.calm), "color_safe": int(settings.color_safe),
			"vibration": int(settings.vibration), "stop_assist": int(settings.stop_assist),
			"lane_assist": int(car.lane_assist if car != null else settings.lane_assist),
			"left_handed": int(settings.left_handed), "lang": maxi(0, Lang.CODES.find(Lang.code))}


## The save's line on the title screen: "1 240 zł · respekt 87" in the chosen language.
func _resume_line() -> String:
	return "%s · %s %d" % [Wallet.money(wallet.zl), Lang.pick("respekt", "respect"), wallet.respect]


## The title's POLSKI / ENGLISH buttons: keep the choice (a --nosave run keeps it for the session
## only) and renew the line under the prompt.
func _on_language_chosen(code: String) -> void:
	_set_language(code)
	if title != null and wallet != null:
		title.resume_line = _resume_line()


## One language at a time (lang.gd): the choice is saved and every surface that was built in the
## old language is made again (the settings panel at once; the full map when it next opens).
func _set_language(code: String) -> void:
	Lang.set_code(code)
	settings.lang = code
	settings.save()
	print("language: %s" % code)
	if hud != null:
		hud.language_changed(_settings_state())
	# The roadworks' boards at the map's edge carry their words in the meshes (edge_roadworks.gd).
	if map != null:
		EdgeRoadworks.rebuild(map)


func _close_settings() -> void:
	print("settings panel: closed")
	get_tree().paused = false
	_blip_sound()
	# Loop MW-6 (Open Question 7): Spacer offered once, after the first pause.
	if not settings.wander_offered and spacer != null and not spacer.on:
		settings.wander_offered = true
		settings.save()
		hud.toast("Spróbuj trybu Spacer: Ustawienia → Jazda", "Try Wander mode: Settings → Driving → Game mode")


func _on_setting(key: String, value: Variant) -> void:
	print("setting: %s = %s" % [key, value])
	match key:
		"controls":
			_set_scheme(int(value))
		"drive":
			# Loop 2e: Point or Classic; Point keeps the camera row's choice (off: Fixed camera).
			if int(value) == 1:
				_set_scheme(Controls.CLASSIC)
			else:
				_set_scheme(Controls.POINT if controls.scheme == Controls.POINT or (controls.scheme == Controls.CLASSIC and follow) else Controls.FIXED)
			hud.settings_panel.sync(_settings_state())
		"camera":
			if (int(value) == 0) != follow:
				_toggle_follow()
			hud.settings_panel.sync(_settings_state())
		"vhs":
			_set_vhs(int(value) == 1)
			settings.vhs = vhs
		"weather":
			weather.set_state(int(value))
		"time":
			tod.set_mode(int(value))
		"traffic":
			traffic_level = int(value)
			settings.traffic = traffic_level
			_apply_traffic()
		"quality":
			_set_quality(int(value) - 1)
		"perf":
			settings.perf = int(value) == 1
			_set_perf(settings.perf)
		"fps":
			settings.fps = Settings.FPS[clampi(int(value), 0, Settings.FPS.size() - 1)]
			_apply_fps()
		"angle":
			# F (2026-11-07): the camera's angle (follow_camera.gd PITCHES); the camera follows next frame.
			settings.pitch = FollowCamera.PITCHES[clampi(int(value), 0, FollowCamera.PITCHES.size() - 1)]
			camera_pitch = -settings.pitch
		"bench":
			_start_phone_bench.call_deferred()
			return
		"fotka":
			_open_fotka.call_deferred()
			return
		"unstuck":
			_unstuck.call_deferred()
			return
		"new_game":
			_on_new_game.call_deferred()  # G14: NOWA GRA in the settings (confirmed by two taps)
			return
		"wander":
			settings.wander = int(value) == 1
			if spacer != null:
				spacer.set_on(settings.wander)
		"sensitivity":
			settings.sensitivity = clampf(float(value), 0.0, 1.0)
			car.set_sensitivity(settings.sensitivity)
		"handling":
			settings.handling = clampi(int(value), 0, 1)
			car.set_handling(settings.handling)
		"lane_assist":
			settings.lane_assist = int(value) == 1
			car.lane_assist = settings.lane_assist
			car.lane_dir = Vector3.ZERO
		"chatter":
			settings.chatter = clampi(int(value), 0, Chatter.GAPS.size() - 1)
			bubbles.chatter.level = settings.chatter
		"zones":
			settings.zone_cap = int(value) == 1
			zone_cap_on = settings.zone_cap
		"text_large", "calm", "color_safe", "vibration", "stop_assist", "left_handed":
			# Accessibility (access.gd): all of it shows at once, text size included.
			settings.set(key, int(value) == 1)
			Access.apply(settings)
			hud.set_left_handed(Access.left_handed)
			hud.apply_text_scale()
		"lang":
			_set_language(Lang.CODES[clampi(int(value), 0, Lang.CODES.size() - 1)])
		"master", "music", "effects":
			settings.set(key, float(value))
			Sfx.set_levels(settings.master, settings.music, settings.effects)
	settings.save()
	_blip_sound()


## Beta values: the lane assist's lane direction for the car (lane_assist.gd), every LANE_EVERY s
## while it is on and the car is in Classic.
func _lane_tick(dt: float) -> void:
	if not car.lane_assist or car.target_dir != Vector3.ZERO:
		car.lane_dir = Vector3.ZERO
		return
	_lane_t -= dt
	if _lane_t > 0.0:
		return
	_lane_t = LANE_EVERY
	var fwd := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var h := LaneAssist.lane_heading(graph, Vector2(car.global_position.x, car.global_position.z), fwd, car.vel.length())
	car.lane_dir = Vector3(h.x, 0.0, h.y)


## Loop 2a: the car was pinned against something twice in a few seconds (car.gd): put it on
## the nearest free spot.
func _on_car_stuck() -> void:
	if flying or autopilot or car.in_water:
		return
	_tow_to_lane("car stuck")


## The pause card's POMOC DROGOWA · unstuck button (JAZDA tab, 2026-11-01): the same tow as a
## pinned car's, asked for by the player (stuck inside a wall, where nothing pins it). In the
## water the water's own tow does it; in the air there is nothing to free.
func _unstuck() -> void:
	if flying or title != null or not _started:
		return
	if car.in_water:
		_tow_out_of_water()
		return
	car.reset_motion()
	_tow_to_lane("unstuck")


## The stuck offer (G14's "later", 2026-11-03; F: "if the user is stuck in textures, click and
## move to the main road"): driven for Car.STALL_TIME s and still in one spot (car.gd `stalled`,
## whatever holds it: a wall nothing pins it against, a gap inside a building), POMOC DROGOWA comes
## up on the context button once it is free, with one toast; a tap tows (`_unstuck`). It goes when
## the car leaves the spot, takes to the air or is towed. The pinned car's own turn-out and tow
## (car.gd) still come first: this is for what they miss.
func _stuck_offer_frame() -> void:
	var want: bool = not flying and not autopilot and _bench_ghost == null and title == null \
			and not car.in_water and car.stalled >= Car.STALL_TIME \
			and not (fotka != null and fotka.is_open())
	if want and not hud.pill_shown("unstuck") and hud.pill_free_for("unstuck"):
		hud.show_pill("POMOC DROGOWA", "tow truck", "unstuck")
		if Gamepad.in_use():
			hud.toast(Gamepad.fmt("Utknąłeś? {a}: pomoc drogowa."), Gamepad.fmt("Stuck? {a}: tow truck."))
		else:
			hud.toast("Utknąłeś? Stuknij POMOC DROGOWA.", "Stuck? Tap TOW TRUCK.")
		print("stuck offer: %.0f s trying at %.1f, %.1f, frame %d" % [car.stalled, car.global_position.x, car.global_position.z, frame])
	elif not want and hud.pill_shown("unstuck"):
		hud.hide_pill()


## The context button's press (hud.context_pressed): the stuck offer's tow is the game's own.
func _on_context_pressed(owner: String) -> void:
	if owner == "unstuck":
		hud.hide_pill()
		_unstuck()


## The car onto the nearest lane facing its way (else just the nearest free spot), stopped.
func _tow_to_lane(why: String) -> void:
	var at := car.global_position
	var yaw := car.rotation.y
	var lane := _lane_spot(at, yaw)
	if not lane.is_empty():
		at = lane[0]
		yaw = lane[1]
	var spot := _free_car_spot(at, yaw)
	car.global_position = spot
	car.rotation.y = yaw
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	car.reset_stall()
	if hud.pill_shown("unstuck"):
		hud.hide_pill()
	hud.toast("Pomoc drogowa: wyciągnięci!", "Towed free")
	_cut_camera()
	print("%s: moved to %.1f, %.1f" % [why, spot.x, spot.z])


## The nearest lane to `at` on its level (not a deck overhead, nor a road under the bridge it is
## on), a lane the car's way first, then any: [position, yaw], or [] when there is none within
## the lane graph's reach. Loop 2a's tow; loop 10a shares it with the tow out of the water,
## never gives a lane point in the water, and takes "its level" as the ground (any lane on the
## terrain: the river's bank is metres below the roads above it) or, on a deck, within 4 m.
func _lane_spot(at: Vector3, yaw: float) -> Array:
	if graph == null:
		return []
	var p := Vector2(at.x, at.z)
	# GAMEPLAY_PLAN 0.1 (F, 2026-11-03: a map teleport left the car on a tunnel): tunnel edges
	# only when `at` is itself inside a tunnel, and lanes of the main network (traffic's strongly
	# connected part) before the pockets off it, so the car can drive away from where it lands.
	var no_tunnel: bool = not map.in_tunnel(at.x, at.z, at.y)
	for heading in [Vector2(-sin(yaw), -cos(yaw)), Vector2.ZERO]:
		for scc_only in [true, false]:
			var hit := graph.snap(p, 80.0, heading, scc_only, false, no_tunnel)
			if hit.is_empty():
				continue
			var e: int = hit[0]
			var lane_s: float = hit[2]
			var h := graph.height(e, lane_s)
			var q := graph.point_at(e, lane_s, graph.lane_offset(e, hit[1]))
			if not _same_level(at, q, h) or map.in_water(q.x, q.y, h):
				continue
			var d := graph.direction(e, lane_s)
			return [Vector3(q.x, h, q.y), atan2(-d.x, -d.y)]
	return []


## Loop 10a: the lane nearest to `at` anywhere on the map, on its level and inside the edge
## walls, from the lane graph's junctions (the start of each lane out of one): [position, yaw],
## or [] (no graph). For a tow from far out in the water or a wide beach, where no lane is
## within the lane graph's snapping reach.
func _node_spot(at: Vector3) -> Array:
	if graph == null:
		return []
	var best: Array = []
	var best_d := INF
	for n in graph.node_pos.size():
		var d := graph.node_pos[n].distance_squared_to(Vector2(at.x, at.z))
		if d >= best_d or graph.node_scc[n] == 0:
			continue
		for e in graph.node_out[n]:
			var s := graph.e_s0[e]
			var q := graph.point_at(e, s, graph.lane_offset(e, 0))
			var h := graph.height(e, s)
			if not map.in_map(q, -12.0) or not _same_level(at, q, h) or map.in_water(q.x, q.y, h):
				continue
			var dir := graph.direction(e, s)
			best = [Vector3(q.x, h, q.y), atan2(-dir.x, -dir.y)]
			best_d = d
			break
	return best


## Loop 10a: a lane point q at height h is on the level of `at`: both on the ground (the
## terrain, however high), or within 4 m of each other on a deck. GAMEPLAY_PLAN 0.1: on the
## ground means within a metre of the terrain both ways (a tunnel's floor, metres under it, was
## "on the ground" too); inside a tunnel, the level is the tunnel's (within 4 m, as on a deck).
func _same_level(at: Vector3, q: Vector2, h: float) -> bool:
	if map.in_tunnel(at.x, at.z, at.y):
		return absf(h - at.y) <= 4.0
	if at.y < map.terrain_height(at.x, at.z) + 0.5:
		var g: float = map.terrain_height(q.x, q.y)
		return h < g + 1.0 and h > g - 1.0
	return absf(h - at.y) <= 4.0


## Loop 10a: keeps where the car last stood on dry land or a deck (the tow goes back to that
## level), and tows it out TOW_DELAY s after a splash.
func _water_frame(dt: float) -> void:
	_clock += dt
	if car.in_water:
		if _tow_wait > 0.0:
			_tow_wait -= dt
			if _tow_wait <= 0.0:
				_tow_out_of_water()
	elif not flying and car.collision_mask != 0:
		_last_dry = car.global_position
		_last_dry_yaw = car.rotation.y


## v1.0 juice: the car hit something (car.impact): sparks and dust at the contact; a car, a
## tram or a guard rail is metal (more sparks, less dust).
func _on_car_impact(collider: Object, speed: float) -> void:
	var metal := collider is AnimatableBody3D or (sfx != null and sfx.near_rail(car.hit_point))
	crash_fx.crash(car.hit_point, car.hit_normal, car.vel, speed, car.global_position.y, metal)
	print("crash fx: %s hit at %d km/h, %d sparks so far, frame %d" % ["metal" if metal else "solid", roundi(speed * 3.6), crash_fx.sparks_thrown, frame])


## Loop 10a: the car rolled into the water (car.splashed): the splash, its sound and a buzz,
## and the tow on its way.
func _on_car_splashed(speed: float) -> void:
	var p := car.global_position
	splash.burst(p, speed, car.vel)
	if sfx != null:
		sfx.splash(speed)
	Access.buzz(80, clampf(speed / 15.0, 0.4, 1.0))
	_tow_wait = TOW_DELAY
	_splash_at = _clock
	if water_test == 2:
		water_test = 3
	print("water: splash at %.1f, %.1f at %d km/h (%s), frame %d" % [p.x, p.z, roundi(speed * 3.6), _water_kind(p), frame])


## Loop 10a: the tow lifts the car out of the water onto the nearest lane on dry land (back
## on the level it came from), with a line from the tow crew. Nothing else changes: no money,
## no fail; a rescue, a delivery or a race carries on.
func _tow_out_of_water() -> void:
	_tow_wait = -1.0
	var at := car.global_position
	var spot := _water_tow_spot(at, _last_dry, _last_dry_yaw)
	var where: Vector3 = spot[0]
	car.global_position = where
	car.rotation.y = spot[1]
	car.leave_water()
	car.reset_physics_interpolation()
	cam_focus = where
	_cut_camera()
	var kind := _water_kind(at)
	var l: Array = dialogue.line("water_tow", kind) if dialogue != null else []
	if l.size() < 2:
		l = ["Pomoc drogowa: wyciągnięci z wody!", "Roadside assistance: out of the water!"]
	hud.toast(l[0], l[1])
	var lane_off := -1.0
	if graph != null:
		var hit := graph.snap(Vector2(where.x, where.z), 8.0)
		if not hit.is_empty():
			lane_off = graph.point_at(hit[0], hit[2], graph.lane_offset(hit[0], hit[1])).distance_to(Vector2(where.x, where.z))
	print("water: towed after %.2f s from %.0f, %.0f to %.1f, %.1f, %.0f m away, %s from a lane, %s; %s, frame %d · %s" % [
			_clock - _splash_at, at.x, at.z, where.x, where.z, Vector2(at.x, at.z).distance_to(Vector2(where.x, where.z)),
			("%.1f m" % lane_off) if lane_off >= 0.0 else "far", "dry" if map.shore_distance(where.x, where.z) == 0.0 else "WET",
			_activity(), frame, l[0]])
	if water_test == 3:
		water_test = 4


## Loop 10a: where the tow puts a car that is in the water at `at`: the nearest lane to where it
## last was on dry land or a deck (`from`, on that level), else the lane nearest to the nearest
## dry land, else the nearest junction; then the free spot there (never in the water).
## [position, yaw].
func _water_tow_spot(at: Vector3, from: Vector3, yaw: float) -> Array:
	var ref := from
	if ref == Vector3.INF or Vector2(ref.x, ref.z).distance_to(Vector2(at.x, at.z)) > 150.0:
		var dry: Vector2 = map.nearest_dry(at.x, at.z)
		ref = Vector3(dry.x, map.terrain_height(dry.x, dry.y), dry.y)
	var spot := _lane_spot(ref, yaw)
	if spot.is_empty():
		spot = _node_spot(ref)
	if spot.is_empty():
		spot = [ref, yaw]
	return [_free_car_spot(spot[0], spot[1]), spot[1]]


## Loop 10a: "river" or "pond" (which tow lines fit).
func _water_kind(p: Vector3) -> String:
	for r in _rivers:
		if Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), r):
			return "river"
	return "pond"


## Loop 10a: what is running, for the water test's lines.
func _activity() -> String:
	return "job %s, rescue %s, race %s, wallet %d zł" % ["on" if jobs != null and jobs.busy() else "none",
			"on" if missions.has_target() else "none", "on" if rivals != null and rivals.racing() else "none", wallet.zl]


## Loop 2c, --lineup: every vehicle model standing round the car, all facing its way: beside it
## the taxi, Podwózka, the police car, the guards' car and the two vans; a row ahead the cars'
## four shapes; a row behind the six rivals; further back the bus and a tram cab car.
## Family shapes go through a MultiMesh with the shape in the custom alpha, as traffic draws
## them. Prints each model's triangles.
func _build_lineup(parent: Node3D) -> void:
	var b := car.global_transform.basis
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var ahead := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	var origin := car.global_position
	var yaw := car.rotation.y
	var spot := func(x: float, z: float, turn: float) -> Transform3D:
		var q := origin + right * x + ahead * z
		q.y = map.ground_height(q.x, q.z)
		return Transform3D(Basis(Vector3.UP, yaw + turn), q)
	var cars := Models.traffic_mesh(0)
	var taxis := Models.traffic_mesh(1)
	var vans := Models.traffic_mesh(2)
	var police := Models.police_mesh()
	# [mesh, shape, paint, x, z, turn, name]
	var rows := [
		[taxis, 0, "#f2f2ee", -10.0, 0.0, 0.0, "taxi"], [taxis, 1, "#2b2c2f", -6.6, 0.0, 0.0, "podwozka"],
		[police, 0, Models.POLICE_WHITE.to_html(false), -3.3, 0.0, 0.0, "police"],
		[police, 1, Models.GUARD_MUSTARD.to_html(false), 3.3, 0.0, 0.0, "guard"],
		[police, 2, Models.AMBULANCE_YELLOW.to_html(false), 0.0, -4.7, 0.0, "ambulance"],
		[vans, 0, "#e9e9e6", 6.7, 0.0, 0.0, "panel van"], [vans, 1, "#d8d2c2", 10.3, 0.0, 0.0, "box van"],
		[cars, 0, "#b8bcc0", -4.8, 7.5, 0.0, "hatch"], [cars, 1, "#24324a", -1.6, 7.5, 0.0, "saloon"],
		[cars, 2, "#4c6650", 1.6, 7.5, 0.0, "estate"], [cars, 3, "#2b2c2f", 4.8, 7.5, 0.0, "suv"],
		[Models.traffic_mesh(3), 0, "#ffffff", -4.0, -17.5, 0.0, "bus"],
	]
	for r: Array in rows:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = r[0]
		mm.instance_count = 1
		mm.set_instance_transform(0, spot.call(r[3], r[4], r[5]))
		var paint := Color(r[2])
		mm.set_instance_custom_data(0, Color(paint.r, paint.g, paint.b, float(r[1])))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Models.material()
		parent.add_child(mmi)
		print("lineup: %s %d triangles" % [r[6], _triangles(r[0])])
	for i in Rivals.RIVALS.size():
		var mi := MeshInstance3D.new()
		mi.mesh = Models.rival_mesh(Rivals.RIVALS[i]["style"])
		mi.material_override = Models.material()
		mi.transform = spot.call(-8.0 + i * 3.2, -8.0, 0.0)
		parent.add_child(mi)
		print("lineup: rival %s %d triangles" % [Rivals.RIVALS[i]["name"], _triangles(mi.mesh)])
	var tram := MeshInstance3D.new()
	tram.mesh = Models.tram_mesh(true)
	tram.material_override = Models.material()
	tram.transform = spot.call(4.0, -17.0, 0.0)
	parent.add_child(tram)
	print("lineup: tram cab car %d triangles" % _triangles(tram.mesh))
	var own := 0
	for c in car.get_children():
		for m in c.get_children():
			if m is MeshInstance3D and (m as MeshInstance3D).mesh is ArrayMesh \
					and (m as MeshInstance3D).material_override != Models.glow_material():
				own += _triangles((m as MeshInstance3D).mesh)
	print("lineup: the player's car %d triangles" % own)


static func _triangles(mesh: Mesh) -> int:
	var n := 0
	for k in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(k)
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		n += (idx.size() if not idx.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n


## Loop 10a, --drive-into-water=X,Z: the car at X,Z, facing the nearest water at least 4 m past
## its edge (within 120 m), flat out, its collision off as if it had jumped the edge (a ramp, a
## glitch); the collision comes back on 3 m past the edge, and the splash and the tow follow.
func _start_water_test() -> void:
	var p := _water_test_at
	var best := Vector2.ZERO
	var best_r := 120.0
	for k in 72:
		var d := Vector2.from_angle(TAU * k / 72.0)
		var r := 2.0
		while r < best_r:
			var q := p + d * r
			if map.shore_distance(q.x, q.y) >= 4.0:
				best_r = r
				best = d
				break
			r += 1.0
	if best == Vector2.ZERO:
		print("water test: no water within 120 m of %.0f, %.0f" % [p.x, p.y])
		return
	car.global_position = Vector3(p.x, map.drive_height(p.x, p.y, map.terrain_height(p.x, p.y)), p.y)
	car.rotation.y = atan2(-best.x, -best.y)
	car.vel = Vector3.ZERO
	car.reset_physics_interpolation()
	car.collision_mask = 0
	cam_focus = car.global_position
	water_test = 1
	print("water test: from %.0f, %.0f towards the water %.0f m away (heading %03.0f°); %s" % [p.x, p.y, best_r,
			fposmod(rad_to_deg(atan2(best.x, -best.y)), 360.0), _activity()])


## Loop 10a: the water test drives flat out, straight on; collision back on past the edge.
func _water_test_frame() -> void:
	car.target_dir = Vector3.ZERO
	car.steer = 0.0
	car.throttle = 1.0
	car.braking = false
	var p := car.global_position
	if water_test == 1 and map.shore_distance(p.x, p.z) >= 3.0:
		car.collision_mask = 1
		water_test = 2


## First scene items 6-7, --first-life: the start's life and sound after FIRST_LIFE_S s (see `first_life`).
func _first_life_frame(dt: float) -> void:
	_first_life_t += dt
	if _first_life_t < FIRST_LIFE_S:
		return
	first_life = false
	var problems: Array[String] = []
	var at := Vector2(car.global_position.x, car.global_position.z)
	if not FIRST_SCENE.has_point(at):
		problems.append("the car at (%.0f, %.0f) is not in the start's box" % [at.x, at.y])
	var on_pavements := walkers.busy_count()
	if not walkers.busy_now():
		problems.append("the walkers' boost is off over the start")
	if on_pavements < 6:
		problems.append("%d walkers on Marszałkowska's pavements (want 6+)" % on_pavements)
	var standing := 0
	if crowds != null:
		for fid: String in Crowds.FIRST_SCENE:
			if crowds.by_id.has(fid):
				standing += int(crowds.sites[int(crowds.by_id[fid])]["want"])
		if standing < 8:
			problems.append("%d people at the start's furniture (want 8+)" % standing)
	if trams.greeted < 1:
		problems.append("no tram bell in the first %.0f s" % FIRST_LIFE_S)
	if sfx != null and sfx.bed_now() != Sfx.SQUARE_BED:
		problems.append("the bed at the start is '%s' (want %s)" % [sfx.bed_now(), Sfx.SQUARE_BED])
	var line := "%d walkers (%d on the pavements, limit %d), %d standing, %d tram bell, bed %s" % [
			walkers.alive_count(), on_pavements, walkers.limit, standing, trams.greeted, sfx.bed_now() if sfx != null else "-"]
	if problems.is_empty():
		print("first life: OK (%s)" % line)
	else:
		for pr in problems:
			push_error("first life: %s" % pr)
		print("first life: %d problems (%s)" % [problems.size(), line])


## The driving-feel loop, --ram-test: after 2 s of traffic, the moving car (not police, not a bus)
## with the longest straight run left on its lane gets the player's car put 14 m behind it, going
## 6 m/s faster; the stick then points along that lane (Point) at 65 km/h. Logs the hit (`traffic`'s
## daze), the rammed car's speed after the shove and how soon the player's car gets past it (its
## centre a car's length ahead along the lane), or that it never did in 10 s.
func _ram_test_frame(dt: float) -> void:
	_ram_t += dt
	if ram_test == 1:
		car.target_dir = Vector3.ZERO
		car.throttle = 0.0
		if _ram_t < 2.0 or traffic == null:
			return
		var best: Traffic.Driver = null
		var best_run := 60.0
		for d in traffic.drivers():
			if d.ghost or d.in_conn or d.parked or d.kind >= Traffic.Kind.BUS or d.v < 3.0 or d.s < 20.0:
				continue
			var run: float = graph.e_len[d.edge] - d.s
			if run > best_run:
				best_run = run
				best = d
		if best == null:
			if _ram_t > 12.0:
				print("ram test: no traffic car with 60 m of lane ahead in 12 s")
				ram_test = 3
			return
		var behind := graph.point_at(best.edge, best.s - 14.0, best.off)
		car.global_position = Vector3(behind.x, map.drive_height(behind.x, behind.y, best.pos.y), behind.y)
		car.rotation.y = best.yaw
		car.reset_physics_interpolation()
		car.vel = Vector3(-sin(best.yaw), 0.0, -cos(best.yaw)) * (best.v + 6.0)
		car.forward_speed = best.v + 6.0
		cam_focus = car.global_position
		_ram_driver = best
		_ram_dir = Vector3(-sin(best.yaw), 0.0, -cos(best.yaw))
		_ram_t = 0.0
		_ram_unsticks = car.unsticks
		ram_test = 2
		print("ram test: behind a traffic car at %.0f, %.0f going %.0f km/h (%.0f m of lane ahead)" % [best.pos.x,
				best.pos.z, best.v * 3.6, best_run])
		return
	var d: Traffic.Driver = _ram_driver
	# The lane's way at the start (the rammed car's own heading turns as it is shoved aside).
	var fwd := _ram_dir
	car.target_dir = fwd
	car.throttle = 0.6
	car.steer = 0.0
	car.braking = false
	if _ram_hit < 0.0 and d.daze > 0.0:
		_ram_hit = _ram_t
		print("ram test: hit at %.0f km/h, the car shoved to %.0f km/h" % [car.vel.length() * 3.6, d.v * 3.6])
	var ahead := (car.global_position - d.pos).dot(fwd)
	if _ram_hit >= 0.0 and ahead > d.length:
		print("ram test: past it %.1f s after the hit, unstuck %d×, the car at %.0f km/h" % [_ram_t - _ram_hit,
				car.unsticks - _ram_unsticks, car.vel.length() * 3.6])
		ram_test = 3
	elif _ram_t > 10.0 or not d.active:
		print("ram test: %s after 10 s (%.1f m behind, unstuck %d×)" % ["never hit it" if _ram_hit < 0.0 else "NEVER PAST it",
				-ahead, car.unsticks - _ram_unsticks])
		ram_test = 3


## The traffic loop, --tram-watch=N: keeps the car (and so the view) 30 m ahead of tram N and 20 m
## to its side, moved on as the tram draws level with that spot or gets 60 m from it.
func _tram_watch_frame() -> void:
	if trams == null or tram_watch >= trams.trams.size():
		return
	var t: Trams.Tram = trams.trams[tram_watch]
	var head := Vector2(t.pos.x, t.pos.z)
	if _tram_watch_at == Vector2.INF or head.distance_to(_tram_watch_at) < 22.0 or head.distance_to(_tram_watch_at) > 60.0:
		_tram_watch_at = head + t.dir * 30.0 + Vector2(-t.dir.y, t.dir.x) * 20.0
		car.collision_layer = 0
		car.collision_mask = 0
	car.global_position = Vector3(_tram_watch_at.x, t.pos.y + 0.5, _tram_watch_at.y)
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.target_dir = Vector3.ZERO
	car.throttle = 0.0
	cam_focus = car.global_position


## Camera loop, --cam-test=NAME: the scheme, the camera behind the car, the car ghosting through
## walls (the camera is what is tested; a building in the way would end the moment early).
func _start_cam_test() -> void:
	if not cam_test in ["classic_turn", "point_release", "brake"]:
		print("cam test: unknown test '%s' (classic_turn, point_release, brake)" % cam_test)
		cam_test = ""
		return
	controls.scheme = Controls.POINT if cam_test == "point_release" else Controls.CLASSIC
	hud.set_scheme(controls.scheme)
	_set_follow(true)
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	cam_yaw = rad_to_deg(car.rotation.y)
	cam_yaw_target = cam_yaw
	cam_focus = car.global_position
	print("cam test: %s, %s, from %.0f, %.0f heading %03.0f°, %.1f s parked first" % [cam_test,
			Controls.NAMES[controls.scheme], car.global_position.x, car.global_position.z, _compass_yaw(car.rotation.y),
			CAM_TEST_SETTLE])


## The camera test's inputs for this frame, through the scheme's own mapping (as a finger on the
## stick or the pedals would give them).
func _cam_test_frame(dt: float) -> void:
	_cam_t += dt
	_cam_phase_t += dt
	var stick := Vector2.ZERO
	var gas := false
	var brake := false
	var kmh := absf(car.forward_speed) * 3.6
	var heading := _compass_yaw(car.rotation.y)
	if _cam_t < CAM_TEST_SETTLE:
		controls.drive(car, stick, false, {}, false, false, cam_yaw, dt)
		return
	var phase := _cam_phase
	match cam_test:
		"classic_turn":
			# Up to 50 km/h straight on, then a 90° right turn (a driver's hands: full lock until
			# 25° short, easing back to the middle), the gas keeping it near 50.
			gas = kmh < 50.0
			if _cam_phase == 0 and kmh >= 50.0:
				_cam_phase = 1
				_cam_aim = heading + 90.0
			if _cam_phase >= 1:
				var err := wrapf(_cam_aim - heading, -180.0, 180.0)
				stick = Vector2(clampf(err / 25.0, -1.0, 1.0), 0.0)
				if _cam_phase == 1 and absf(err) < 3.0:
					_cam_phase = 2
		"point_release":
			# Up to 50 km/h pointing straight up the screen, then the stick held to the screen's right
			# (90° right of the car: the camera is behind it) for 2.5 s, then let go.
			if _cam_phase == 0:
				stick = Vector2(0.0, -1.0)
				if kmh >= 50.0:
					_cam_phase = 1
			if _cam_phase == 1:
				stick = Vector2(1.0, 0.0)
				if _cam_phase_t >= 2.5:
					_cam_phase = 2
		"brake":
			# Flat out to 90 km/h, then the brake to a stop.
			if _cam_phase == 0:
				gas = true
				if kmh >= 90.0:
					_cam_phase = 1
			if _cam_phase == 1:
				# (Held on at a standstill the brake would reverse: let go once stopped.)
				brake = true
				if kmh < 0.5:
					_cam_phase = 2
					brake = false
	if _cam_phase != phase:
		_cam_phase_t = 0.0
		print("cam test: phase %d at %.2f s (frame %d), %.0f km/h, heading %03.0f°" % [_cam_phase, _cam_t - CAM_TEST_SETTLE,
				frame, kmh, heading])
	controls.drive(car, stick, stick != Vector2.ZERO, {}, gas, brake, cam_yaw, dt)


## Camera loop, --cam-log: one `cam:` line every CAM_LOG_EVERY frames (the turn rate is the
## fastest since the last line).
func _cam_log_frame(dt: float) -> void:
	if _cam_last_yaw != INF and dt > 0.0:
		_cam_turn_max = maxf(_cam_turn_max, absf(wrapf(cam_yaw - _cam_last_yaw, -180.0, 180.0)) / dt)
	_cam_last_yaw = cam_yaw
	# This frame's number as the screenshots count it (frame is counted up after the camera).
	var f := frame + 1
	if f % CAM_LOG_EVERY != 0:
		return
	var vehicle: Node3D = heli if flying else car
	var pos := vehicle.get_global_transform_interpolated().origin
	var screen := get_viewport().get_visible_rect().size
	var on := cam.unproject_position(pos) * float(view.stretch_shrink)
	var kmh: float = (heli.speed() if flying else absf(car.forward_speed)) * 3.6
	var held: bool = _heli_held if flying else controls.held or hud.stick_active()
	print("cam: frame %d %s %s%s finger %s | %3.0f km/h heading %05.1f° camera %05.1f° (off %+5.1f°) turning %3.0f°/s | car on screen %4.0f,%4.0f px (%+4.0f,%+4.0f from the middle) | view %5.1f m" % [
			f, "heli" if flying else Controls.KEYS[controls.scheme], "follow" if follow else "fixed",
			" test %s/%d" % [cam_test, _cam_phase] if cam_test != "" else "", "down" if held else "up", kmh,
			_compass_yaw(vehicle.rotation.y), _compass_yaw(deg_to_rad(cam_yaw)),
			wrapf(_compass_yaw(deg_to_rad(cam_yaw)) - _compass_yaw(vehicle.rotation.y), -180.0, 180.0), _cam_turn_max,
			on.x, on.y, on.x - screen.x * 0.5, on.y - screen.y * 0.5, cam.size])
	_cam_turn_max = 0.0


## A yaw (radians, rotation.y) as a compass heading in degrees (0 north, 90 east).
static func _compass_yaw(yaw: float) -> float:
	return fposmod(-rad_to_deg(yaw), 360.0)


## While the game is paused (settings) main.gd doesn't process: the frame count and the
## screenshots carry on here.
func _paused_frame() -> void:
	if not get_tree().paused or not _started:
		return
	frame += 1
	_inject_clicks()
	if frame in shots:
		_capture(frame)


## --clicks: press on frame F, release on F + 2 (through Input, as a real click would come).
func _inject_clicks() -> void:
	for c in clicks:
		if frame != c.z and frame != c.z + 2:
			continue
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = Vector2(c.x, c.y)
		e.global_position = e.position
		e.pressed = frame == c.z
		e.button_mask = MOUSE_BUTTON_MASK_LEFT if e.pressed else 0
		Input.parse_input_event(e)
		print("click %s at %d,%d (frame %d)" % ["down" if e.pressed else "up", c.x, c.y, frame])
	for d in drags:
		var at := Vector2(d[0], d[1])
		var step := frame - d[2]
		if step < 0 or frame > d[5]:
			continue
		if step == 0 or frame == d[5]:
			var b := InputEventMouseButton.new()
			b.button_index = MOUSE_BUTTON_LEFT
			b.pressed = step == 0
			b.position = at + (Vector2(d[3], d[4]) if frame == d[5] else Vector2.ZERO)
			b.global_position = b.position
			b.button_mask = MOUSE_BUTTON_MASK_LEFT if b.pressed else 0
			Input.parse_input_event(b)
		elif step <= 10:
			var m := InputEventMouseMotion.new()
			m.button_mask = MOUSE_BUTTON_MASK_LEFT
			m.position = at + Vector2(d[3], d[4]) * (step / 10.0)
			m.global_position = m.position
			m.relative = Vector2(d[3], d[4]) / 10.0
			Input.parse_input_event(m)


func _apply_style() -> void:
	var style: Dictionary = STYLES[style_index]
	var screen := get_viewport().get_visible_rect().size
	# Loop G1: the quality's step and budget (tiers.gd image_scale); --lines= is exact.
	if lines_override > 0:
		view.stretch_shrink = maxi(1, floori(screen.y / lines_override))
	elif quality_choice == Tiers.AUTO:
		# Loop G1b: Auto draws the style's own scale where the budget binds, unless this launch
		# is the fallback.
		view.stretch_shrink = Tiers.auto_scale(screen, style["lines"], quality, auto_sharp)
	else:
		view.stretch_shrink = Tiers.image_scale(screen, style["lines"], quality)
	post_mat.set_shader_parameter("outline_strength", style["outline"])
	post_mat.set_shader_parameter("levels", style["levels"])
	post_mat.set_shader_parameter("saturation", style["saturation"])
	# Loop G1b: the governor's tally counts only at Auto's image; the `quality:` line when it changes.
	var mode := _image_mode()
	governor.track = mode != ""
	var line := Tiers.describe(quality_choice, quality, model_name, view.stretch_shrink, mode)
	if mode == "fallback":
		line = line.replace("(%s)" % model_name, "(last session: %s) · %s · the sharp image again after %d calm sessions (%d so far)" % [
				auto_image["why"], model_name, auto_image["wait"], auto_image["calm"]])
	elif mode == "sharp" and int(auto_image["trial"]) >= 0:
		line += " · on trial: calm %d of %d (a struggle first doubles the wait)" % [auto_image["trial"], auto_image["wait"]]
	line += " · image %dx%d" % [int(screen.x) / view.stretch_shrink, int(screen.y) / view.stretch_shrink]
	if line != _quality_line:
		_quality_line = line
		print("quality: " + line)


func _process(dt: float) -> void:
	if not _started:
		return
	var t_main := Time.get_ticks_usec()
	if bench or probe:
		_bench_frame()
	_read_input(dt)
	_moment_frame(dt)  # loop MW-6: --egg, --tape, --fotka and the VHS of a tape
	_water_frame(dt)
	_stuck_offer_frame()  # G14's "later": POMOC DROGOWA on the context button when stuck
	Haptics.tick(dt, not flying and absf(car.forward_speed) > 3.0)
	if autopilot or _bench_ghost != null:
		_autopilot(dt)
	_boat_frame()
	_update_camera(dt)
	_stream_frame(dt)  # loop 3c: the sectors round the camera
	_title_frame()  # the loading fix: the title's prompt once the start is in
	_remember_frame(dt)  # save and resume: the car's spot for the next launch
	_look_frame()  # the loading fix: a look at a new target once its sectors are in
	if cam_log:
		_cam_log_frame(dt)
	var pos := _vehicle_position()
	# GAMEPLAY_PLAN 0.3: in a tunnel, or a bridge or viaduct deck between the car and the camera
	# (Trasa Łazienkowska over the streets under it).
	if Engine.get_process_frames() % DECK_XRAY_EVERY == 0:
		_deck_hid = not flying and map.deck_hides(pos + Vector3.UP * 0.8, cam.global_transform.basis.z)
	# F (2026-11-07): under a deck the occlusion ghost now cuts the deck itself (ground.gdshader's
	# deck ghost, building.gdshader for its slab), so the car and the traffic round it show as
	# they are; the silhouette stays for the tunnels, and for decks with --no-ghost.
	_xray.show_through(not flying and (map.in_tunnel(pos.x, pos.z, pos.y) or (_deck_hid and no_ghost)))
	# Loop 3d-1: the pedestrian zones cap the player's car (police.md 5.6); the log says when.
	# F's asks (2026-10-30): only with the Settings switch on (off by default).
	var zone: String = ped_zones.at(car.global_position.x, car.global_position.z) if ped_zones != null and not flying else ""
	car.zone_cap = PedZones.CAP if zone != "" and zone_cap_on else INF
	if zone != _zone:
		print("zone: %s at %.0f km/h" % [(zone + (" (20 km/h)" if zone_cap_on else " (no cap)")) if zone != "" else "left " + _zone,
				absf(car.forward_speed) * 3.6])
		_zone = zone
	var sz: String = scooter_zones.at(car.global_position.x, car.global_position.z) if not flying else ""
	if sz != _scooter_zone:
		_scooter_zone = sz
		var now := Time.get_ticks_msec() / 1000.0
		if sz != "" and hud != null and now - _scooter_toast_at >= ScooterZones.COOLDOWN:
			_scooter_toast_at = now
			var tw: Array = ScooterZones.toast_for(sz)
			hud.ambient_toast(str(tw[0]), str(tw[1]))
			print("zone: scooter %s (12 km/h for scooters)" % sz)
	_feed_life(pos)
	var boating := boat_race != null and boat_race.busy()
	# The cinema tour: no side job is offered while Wiktor rides along (the jobs read it as flying).
	var touring := kino_tour != null and kino_tour.busy()
	if police != null:
		police.flying = flying or boating  # loop 3g-1: the police ignore the helicopter (and the boat race)
		police.zone = zone  # loop 3g-2: the city guards' zone pill and whistle
		police.zone_cap = zone_cap_on  # F's asks: the pill and the whistle only with the cap on
	if jobs != null:
		# Loop 2b: no side job starts on the bench route (the ghost stops at red lights).
		jobs.flying = flying or _bench_ghost != null or boating or touring
		# Loop 2d-1: no ride is offered from the helicopter, on the title screen or the bench.
		rides.flying = flying or boating or touring
		rides.away = title != null or _bench_ghost != null or _phone_bench
		# 2026-11-07 (BACKLOG "Secret rave"): no ride or "Na czasie" card while Ziomek's rave run,
		# the club or Bartek's tow is on (their calls already held the rescue calls).
		rides.away = rides.away or (rave != null and rave.busy()) or (club != null and club.inside) \
				or (ev_tow != null and ev_tow.busy())
		if trend_job != null:
			trend_job.flying = flying or boating or touring
			trend_job.player_pos = pos
			trend_job.away = rides.away
		eggs.player = pos
		eggs.player_vel = heli.vel if flying else car.vel
		eggs.flying = flying
	car.lights = tod.lights_on
	heli.lights = tod.lights_on
	car.wet = weather.wet
	if sfx != null:
		sfx.flying = flying
		sfx.focus = cam_focus
		sfx.yaw = cam_yaw
	if weather.amount > 0.0:
		# The rain streaks drift with the view a little (parallax), in image pixels.
		var px := float(maxi(sv.size.y, 1)) / cam.size
		var b := cam.global_transform.basis
		post_mat.set_shader_parameter("rain_shift", Vector2(cam_focus.dot(b.x), -cam_focus.dot(b.y)) * px)
	var minute := int(tod.now_utc() / 60.0)
	if minute != _clock_minute:
		_clock_minute = minute
		_set_palace_clock()
	# Loop 2e: the minimap's night palette follows the lamps (dusk is half way).
	hud.set_night(tod.lights_on)
	if _phone_bench:
		_phone_bench_frame()
	if show_perf:
		_update_perf(dt)
	# Loop 2e: the speed beside the gear (the "prototype" label is gone).
	if flying:
		hud.set_speed(roundi(heli.speed() * 3.6), roundi(heli.height_above))
		missions.tick(dt, pos, heli.speed(), true)
	else:
		hud.set_speed(roundi(absf(car.forward_speed) * 3.6))
		missions.tick(dt, pos, car.vel.length(), false)
	_show_target()
	_stop_assist()
	_main_line_tick(dt)
	_story_t -= dt
	if _story_t <= 0.0:
		_story_t = StoryQuests.TICK
		_story_tick()
	var heading: float = heli.rotation.y if flying else car.rotation.y
	hud.update_minimap(Vector2(pos.x, pos.z), heading, deg_to_rad(cam_yaw))
	# The see-through hole: aimed at the cabin and smaller for the helicopter, which is
	# rarely hidden; a full-size one cuts into the roof edge it has landed on.
	var car_view := cam.global_transform.affine_inverse() * (pos + Vector3(0, 3.5 if flying else 1.0, 0))
	var hole := clampf(cam.size * 0.11, 7.0, 20.0) * (0.55 if flying else 1.0)
	if no_ghost:
		hole = 0.0  # --no-ghost: the see-through hole is off too
	building_mat.set_shader_parameter("fade_radius", hole)
	_update_ghost(pos, car_view)
	for m in map.fade_materials:
		m.set_shader_parameter("car_view", car_view)
		m.set_shader_parameter("fade_radius", hole * 0.8)
	# Loop MW-6: Fotka's photo shows the city whole (no see-through hole, no ghost).
	if fotka != null and fotka.is_open():
		building_mat.set_shader_parameter("fade_radius", 0.0)
		for m: ShaderMaterial in [building_mat, map.flat_material, post_mat] + _neon_materials():
			m.set_shader_parameter("occlusion_radius", 0.0)
		for m in map.fade_materials:
			m.set_shader_parameter("fade_radius", 0.0)
	_rotor_wash()
	_fine_detail()
	# A small marker over the vehicle once the view is wide enough to lose it.
	var marker := cam.unproject_position(pos + Vector3(0, 4.5 if flying else 2.0, 0)) * float(view.stretch_shrink)
	hud.set_car_marker(marker, cam.size > 55.0)

	frame += 1
	_stop_step()
	_inject_clicks()
	if frame == 60 and tap_at != Vector2.INF:
		_on_tap(tap_at)
	if frame == 60 and bench_button:
		_start_phone_bench()
	if buses != null and frame in honk_frames:
		buses.honk()  # the night-buses loop: --honk=F
	if frame in shots:
		_capture(frame)
	_govern()
	_main_usec = Time.get_ticks_usec() - t_main
	# Loop G1, --stress=cpu: after the game loop's own time is taken (the load isn't the game's).
	if _stress_kind == "cpu" and _stressing():
		_busy(_stress_n)


## The occlusion ghost (ghost.gdshaderinc, loop 1): what stands on the camera's side of
## the vehicle and covers it and its surroundings on screen keeps only a thin dither
## (building.gdshader); the ground lifts the buildings' baked shade there and gives a
## ghosted footprint the sunlight its building takes (ground.gdshader); the post pass
## leaves the ghost's pixels without outlines. The same values go to all three.
func _update_ghost(pos: Vector3, car_view: Vector3) -> void:
	var ahead := -cam.global_transform.basis.z
	var ahead_xz := Vector2(ahead.x, ahead.z).normalized()
	var occ := Vector4(pos.x, pos.z, ahead_xz.x, ahead_xz.y)
	var ghost_r := clampf(cam.size * 0.22, 14.0, 50.0) * (0.6 if flying else 1.0)
	if no_ghost:
		ghost_r = 0.0
	for m: ShaderMaterial in [building_mat, map.flat_material, post_mat] + _neon_materials():  # sweep 2: + neon
		m.set_shader_parameter("car_view", car_view)
		m.set_shader_parameter("occluder", occ)
		m.set_shader_parameter("occlusion_radius", ghost_r)
	# The sun a ghosted footprint gets back: none without shadows (the night's moon, Low
	# quality: it is lit already), all of it with a high sun, less when it is low (the
	# streets round it lie in long shadows then).
	var to_sun := sun.global_transform.basis.z
	var elevation := rad_to_deg(asin(clampf(to_sun.y, -1.0, 1.0)))
	var give := 0.0
	if sun.visible and sun.shadow_enabled:
		give = sun.shadow_opacity * smoothstep(GHOST_SUN_LOW, GHOST_SUN_HIGH, elevation)
	var lc := sun.light_color.srgb_to_linear()
	map.flat_material.set_shader_parameter("ghost_sun", Vector3(lc.r, lc.g, lc.b) * sun.light_energy * give * GHOST_SUN_SCALE)
	map.flat_material.set_shader_parameter("ghost_sun_dir", to_sun)
	# The deck ghost (ground.gdshader): the car's ground height; off for the helicopter.
	map.flat_material.set_shader_parameter("ghost_car_y", -10000.0 if flying else pos.y)
	if ghost_debug > 0:
		building_mat.set_shader_parameter("ghost_debug", ghost_debug)
		var ppm := float(sv.size.y) / cam.size * float(view.stretch_shrink)
		var c := cam.unproject_position(pos + Vector3(0, 3.5 if flying else 1.0, 0)) * float(view.stretch_shrink)
		_ghost_px = Vector4(c.x, c.y - 0.2 * ghost_r * ppm, ghost_r / 0.78 * ppm, ghost_r * ppm)


# --- sweep 2: the neon signs are ghosted too ------------------------------------------------
## The neon signs' material (neon.gdshader, shared by the map node "Neon"'s tiles), found on
## the first ghost update on either city path; empty when the map has no signs.
var _neon_mats: Array[ShaderMaterial] = []
var _neon_found := false


func _neon_materials() -> Array[ShaderMaterial]:
	if not _neon_found:
		_neon_found = true
		var holder := map.get_node_or_null("Neon")
		if holder != null:
			for c in holder.get_children():
				var g := c as GeometryInstance3D
				var m := g.material_override as ShaderMaterial if g != null else null
				if m != null and not _neon_mats.has(m):
					_neon_mats.append(m)
	return _neon_mats
# --- end sweep 2 ---------------------------------------------------------------------------


## Loop 1: the Palace of Culture's four dials show the time in Warsaw (the device's clock,
## or --clock= / --date=), drawn by building.gdshader; called when the minute changes.
func _set_palace_clock() -> void:
	var t := tod.now_utc()
	var local := Time.get_datetime_dict_from_unix_time(int(t) + TimeOfDay.warsaw_offset(t))
	var minutes := float(local["minute"])
	var hours := float(int(local["hour"]) % 12) + minutes / 60.0
	building_mat.set_shader_parameter("clock_hands", Vector2(TAU * hours / 12.0, TAU * minutes / 60.0))


## Where the player is, for traffic (obstacle, spawn band), trams and rivals.
func _feed_life(pos: Vector3) -> void:
	if traffic == null:
		return
	var ground: Vector3 = car.global_position if not flying else Vector3(pos.x, map.ground_height(pos.x, pos.z), pos.z)
	traffic.player_pos = ground
	traffic.player_vel = car.vel if not flying else Vector3.ZERO
	traffic.player_on_road = not flying
	trams.player_pos = ground
	trams.player_on_road = not flying
	if trains != null:
		trains.player_pos = ground
		trains.player_on_road = not flying
		trains.view_at = traffic.view_centre
		trains.view_reach = maxf(traffic.view_half.x, traffic.view_half.y) * 1.5 + 150.0
	rivals.flying = flying


## --bench: 300 frames to settle (traffic fills in), then the average of 600 (--bench-frames=)
## on the ghost route; --probe: the same where the car stands. Wall-clock time between frames,
## not dt (delta smoothing snaps dt to the display's refresh interval). The first line keeps
## the format of the bench before loop 2b, so old and new code compare like with like.
func _bench_frame() -> void:
	if _bench_done:
		return
	if _measure_t0 == 0:
		if frame < _bench_settle and Time.get_ticks_msec() - _bench_t0 < SETTLE_SECONDS * 1000.0:
			return
		_measure_t0 = Time.get_ticks_msec()
		_stats.start()
		return
	_stats.sample()
	if sfx != null:
		var peaks := Sfx.bus_peaks()
		for bus in _meters:
			_meters[bus] += peaks[bus]
			_meter_top[bus] = maxf(_meter_top[bus], peaks[bus])
	if _stats.frames.size() < _bench_frames and Time.get_ticks_msec() - _measure_t0 < _bench_seconds * 1000.0:
		return
	_bench_done = true
	var r := _stats.report()
	var n := float(_stats.frames.size())
	var us := func(k: String) -> float: return r.get("us:" + k, 0.0) / 1000.0
	var what := "probe" if probe else "bench"
	print("%s: %.2f ms/frame (%.0f fps, worst %.1f ms) over %d frames · scripts: traffic %.2f + trams %.2f + people %.2f = %.2f ms, side jobs + eggs %.3f ms, sound %.3f ms · 3D view: GPU %.2f ms, render CPU %.2f ms · %.0f cars on screen, %.0f driving · %s · %s · %s · quality %s" % [
			what, r["ms"], r["fps"], r["worst"], r["frames"],
			us.call("traffic"), us.call("trams"), us.call("people"), us.call("traffic") + us.call("trams") + us.call("people"),
			us.call("jobs+eggs"), us.call("sound"), r["gpu"], r["render_cpu"],
			r.get("n:cars on screen", 0.0), r.get("n:driving", 0.0), "no traffic" if traffic == null else "traffic on", TimeOfDay.NAMES[tod.mode],
			Weather.NAMES[weather.state], QUALITY[quality]["name"] + " · traffic " + Settings.TRAFFIC_NAMES[traffic_level]])
	_stats.header = _bench_header("probe" if probe else "bench route (--bench)")
	_stats.notes = _governor_notes()
	var text := _stats.text(r)
	for line in text.split("\n"):
		print("%s detail: %s" % [what, line])
	_print_old_late(r)
	if probe:
		print("probe view: %s" % _view_census())
	_write_bench_result(text)
	print("bench audio peaks, mean / loudest dBFS (-200 = silent or no audio device): Master %.1f / %.1f · Music (radio) %.1f / %.1f · SFX %.1f / %.1f · Ambience %.1f / %.1f" % [
			_meters["Master"] / n, _meter_top["Master"], _meters["Music"] / n, _meter_top["Music"],
			_meters["SFX"] / n, _meter_top["SFX"], _meters["Ambience"] / n, _meter_top["Ambience"]])
	get_tree().quit()


## Loop 2b: the bench's sources: what each system's script costs a frame, how many cars and
## people there are.
func _make_stats() -> BenchStats:
	var b := BenchStats.new()
	b.view_rid = sv.get_viewport_rid()
	b.screen_rid = get_viewport().get_viewport_rid()
	if traffic != null:
		b.systems["traffic"] = [traffic, "last_usec", false]
		b.systems["traffic bodies"] = [traffic, "spent_usec", true]
		b.systems["trams"] = [trams, "last_usec", false]
		if trains != null:
			b.systems["trains"] = [trains, "last_usec", false]
		b.systems["people"] = [walkers, "last_usec", false]
		b.systems["rivals"] = [rivals, "spent_usec", true]
		b.counts["cars on screen"] = func() -> int: return traffic.visible_count
		b.counts["driving"] = func() -> int: return traffic.drivers().size()
		b.counts["people"] = func() -> int: return walkers.alive_count()
	if jobs != null:
		b.systems["jobs+eggs"] = [self, "_jobs_usec", false]
		b.systems["jobs physics"] = [jobs, "spent_usec", true]
		b.systems["rides physics"] = [rides, "spent_usec", true]  # loop 2d-1
	if notes != null:
		b.systems["notebook"] = [notes, "spent_usec", true]  # loop MW-1
	if city_sounds != null:
		b.systems["city sounds"] = [city_sounds, "spent_usec", true]  # loop MW-5
	if crowds != null:
		b.systems["crowds"] = [crowds, "spent_usec", true]  # loop MW-3
	if life != null:
		b.systems["city life"] = [life, "spent_usec", true]  # loop MW-4
	if buses != null:
		b.systems["buses"] = [buses, "spent_usec", true]  # the night-buses loop
	if crash_scenes != null:
		b.systems["crash scenes"] = [crash_scenes, "spent_usec", true]
	if old_tram != null:
		b.systems["old tram"] = [old_tram, "spent_usec", true]  # the vintage-tram loop
	if storefronts != null:
		b.systems["storefronts"] = [storefronts, "spent_usec", true]  # loop MW-2
	if packs != null:
		b.systems["packs"] = [packs, "spent_usec", true]  # running clubs, cycling packs, raves
	if meet != null:
		b.systems["meet"] = [meet, "spent_usec", true]  # the night racing club
	if fans != null:
		b.systems["fans"] = [fans, "spent_usec", true]  # the fans by Stadion Leguminy
	if wellness != null:
		b.systems["wellness"] = [wellness, "spent_usec", true]  # sound healing, techno yoga, 40+ club, kung-fu
	if egg_book != null:
		b.systems["eggs+tape+spacer"] = [self, "_moments_usec", false]  # loop MW-6
	if districts != null:
		b.systems["districts"] = [districts, "spent_usec", true]  # loop 3h slice 1
	if syrenki != null:
		b.systems["syrenki"] = [syrenki, "spent_usec", true]  # loop 3h slice 2
	if garage != null:
		b.systems["garage"] = [garage, "spent_usec", true]  # the garage loop
	if first10 != null:
		b.systems["first10"] = [first10, "spent_usec", true]  # loop 3h slice 4
	if cassettes != null:
		b.systems["cassettes"] = [cassettes, "spent_usec", true]  # the first-10 polish
	b.systems["sound"] = [sfx, "last_usec", false]
	b.systems["hud+minimap"] = [hud, "spent_usec", true]
	b.systems["bubbles"] = [bubbles, "spent_usec", true]
	b.systems["dialogue"] = [dialogue, "spent_usec", true]
	b.systems["weather+time"] = [self, "_sky_usec", false]
	b.systems["car physics"] = [car, "spent_usec", true]
	b.systems["heli"] = [heli, "spent_usec", true]
	b.systems["game loop"] = [self, "_main_usec", false]
	return b


## jobs.gd and eggs.gd, weather.gd and time_of_day.gd, read as one each.
var _jobs_usec: int:
	get:
		return (jobs.last_usec + eggs.last_usec + (rides.last_usec if rides != null else 0)) if jobs != null else 0
## Loop MW-6: egg_book.gd, tape.gd and spacer.gd, read as one (and cleared).
var _moments_usec: int:
	get:
		if egg_book == null:
			return 0
		var t: int = egg_book.spent_usec + (tape.spent_usec if tape != null else 0) + (spacer.spent_usec if spacer != null else 0)
		egg_book.spent_usec = 0
		if tape != null:
			tape.spent_usec = 0
		if spacer != null:
			spacer.spent_usec = 0
		return t
var _sky_usec: int:
	get:
		var t: int = weather.spent_usec + tod.spent_usec
		weather.spent_usec = 0
		tod.spent_usec = 0
		return t


## Loop 2b, --exp=a,b: switch one cost off to see what it costs (ranking the frame).
func _apply_experiments() -> void:
	for e in _exp:
		match e:
			"nohud":
				hud.visible = false
			"nominimap":
				hud.get("_minimap").visible = false
			"nobubbles":
				bubbles.visible = false
			"noshadow":
				tod.shadows_allowed = false
				tod.refresh()
			"nopost":
				cam.get_child(0).visible = false
			"notrees", "noprops", "nosmallcasters":
				for c in map.get_children():
					var mmi := c as MultiMeshInstance3D
					if mmi == null:
						continue
					var leaf: bool = mmi.material_override == map.leaf_material
					if e == "notrees" and leaf:
						mmi.visible = false
					elif e == "noprops" and not leaf:
						mmi.visible = false
					elif e == "nosmallcasters":
						mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			"nocasters":
				for c in map.get_children():
					if c is GeometryInstance3D:
						(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_:
				if e.begins_with("shadowdist="):
					sun.directional_shadow_max_distance = float(e.trim_prefix("shadowdist="))
				elif e.begins_with("shadowsize="):
					RenderingServer.directional_shadow_atlas_set_size(int(e.trim_prefix("shadowsize=")), true)
		print("experiment: ", e)


## Loop 2b, --probe: what stands in the camera's view: nodes and instances, shadow casters,
## distinct materials and shaders (each shader brings its own pipelines).
func _view_census() -> String:
	var planes := cam.get_frustum()
	var mats := {}
	var shaders := {}
	var nodes := 0
	var instances := 0
	var casters := 0
	var caster_instances := 0
	var kinds := {}
	var proxy_n := 0
	var proxy_tris := 0
	var tower_only := 0
	var tower_keys := {}
	var stack: Array[Node] = [sv]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var g := n as GeometryInstance3D
		if g == null or not g.is_visible_in_tree():
			continue
		var box: AABB = g.global_transform * g.get_aabb()
		var inside := true
		for pl: Plane in planes:
			# Outside when every corner lies in front of one of the frustum's planes.
			var out := true
			for k in 8:
				if not pl.is_point_over(box.get_endpoint(k)):
					out = false
					break
			if out:
				inside = false
				break
		if not inside:
			continue
		# Loop 3d-2b: a node past its visibility range isn't drawn.
		if g.visibility_range_end > 0.0 and cam.global_position.distance_to(box.get_center()) > g.visibility_range_end:
			continue
		nodes += 1
		var count := 1
		var mesh: Mesh = (g as MeshInstance3D).mesh if g is MeshInstance3D else null
		# Loop 3d-2b: what a far level could take: draws of sectors in view only by their towers.
		var sector_root := g.get_parent()
		while sector_root != null and sector_root.get_parent() != null and sector_root.get_parent().name != "Sectors":
			sector_root = sector_root.get_parent()
		if streamer != null and sector_root != null and sector_root.get_parent() != null and sector_root.get_parent().name == "Sectors":
			var parts := String(sector_root.name).trim_prefix("s_").split("_")
			var key := Vector2i(int(parts[0]), int(parts[1]))
			if not streamer.ground_in_view(key, 0.0, 25.0, planes):
				tower_only += 1
				tower_keys[key] = true
		# Loop 3d-2b: the far level (the sectors' proxies) on its own line.
		if g.get_parent().name == "Proxies" and mesh != null and mesh.get_surface_count() > 0:
			proxy_n += 1
			for k in mesh.get_surface_count():
				proxy_tris += mesh.surface_get_array_index_len(k) / 3
		if g is MultiMeshInstance3D:
			var mm := (g as MultiMeshInstance3D).multimesh
			count = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			mesh = mm.mesh
		var mat_name := "-"
		if g.material_override is ShaderMaterial:
			mat_name = (g.material_override as ShaderMaterial).shader.resource_path.get_file().get_basename()
		elif g.material_override != null:
			mat_name = g.material_override.get_class()
		var kind := "%s %s %s %d" % ["MMI" if g is MultiMeshInstance3D else g.get_class(), mat_name,
				g.get_parent().name.left(12), mesh.get_surface_count() if mesh != null else 0]
		if mesh is ArrayMesh and mesh.get_surface_count() > 0 and g is MultiMeshInstance3D:
			kind += " v%d" % mesh.surface_get_array_len(0)
		kinds[kind] = kinds.get(kind, 0) + 1
		instances += count
		if g.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			casters += 1
			caster_instances += count
		var list: Array[Material] = []
		if g.material_override != null:
			list.append(g.material_override)
		elif g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var mi := g as MeshInstance3D
			for k in mi.mesh.get_surface_count():
				var m := mi.get_active_material(k)
				if m != null:
					list.append(m)
		for m in list:
			mats[m.get_instance_id()] = true
			shaders[(m as ShaderMaterial).shader.resource_path.get_file() if m is ShaderMaterial else m.get_class()] = true
	var parts := PackedStringArray()
	for k in kinds:
		parts.append("%s ×%d" % [k, kinds[k]])
	var far := ""
	if streamer != null:
		far = "\nprobe far level: %d proxies in view, %d triangles; %d sectors in full detail; %d nodes in view from %d sectors whose ground and low buildings are out of it" % [proxy_n, proxy_tris,
				streamer.loaded().size(), tower_only, tower_keys.size()]
	return "%d nodes (%d instances) in view, %d shadow-casting nodes (%d instances), %d materials, %d shaders: %s\nprobe kinds: %s%s" % [
			nodes, instances, casters, caster_instances, mats.size(), shaders.size(), ", ".join(PackedStringArray(shaders.keys())),
			" | ".join(parts), far]


func _vehicle_position() -> Vector3:
	return heli.global_position if flying else car.global_position


## The quest stop assist (stop_assist.gd): hands the car the ring of the errand on now, in the
## arrow's order (a race has none), so it brakes itself into it.
func _stop_assist() -> void:
	var at := Vector3.INF
	if flying or (rivals != null and rivals.has_target()):
		pass
	elif kino_tour != null and kino_tour.has_target():
		at = kino_tour.stop_spot()
	elif trend_job != null and trend_job.has_target():
		at = trend_job.stop_spot()
	elif rides != null and rides.has_target():
		at = rides.stop_spot()
	elif jobs != null and jobs.has_target():
		at = jobs.stop_spot()
	elif missions.has_target():
		at = missions.stop_spot()
	car.assist_at = at
	car.assist_reach = StopAssist.RING


## The main line (main_line.gd): the active target is the main line's (_put_target), and its step
## (looked at every MainLine.STEP_EVERY s: the marker, the full map's goal line).
var _main_target := Vector2.INF
var _main_t := 0.0
var main_step: Dictionary = {}
## The main line on the driving screen (main_nudge.gd): its goal line and gold edge arrow, shown
## when nothing else is on (`_free_now`, from `_show_target`).
var _nudge := MainNudge.new()
var _nudge_arrow := false
var _free_now := false


func _guide_on() -> bool:
	return first10 != null and first10.guide_on()


## The active target on the minimap: a side quest's dot in its colour, or (`main`) the main line's
## star (hud.gd `set_main_line`, from `_main_line_tick`).
func _put_target(xz: Vector2, colour: Color, main: bool) -> void:
	hud.set_minimap_target(Vector2.INF if main else xz, colour)
	_main_target = xz if main else Vector2.INF


## The main line's step now (main_line.gd `step`), at most every MainLine.STEP_EVERY s.
func _main_line_tick(dt: float) -> void:
	_main_t -= dt
	if _main_t > 0.0 or hud == null:
		return
	_main_t = MainLine.STEP_EVERY
	var f := {"guide": _guide_on(), "target": _main_target, "target_main": _main_target != Vector2.INF}
	if first10 != null and first10.hint_shown():
		f["guide_at"] = Vector2(first10.hint_at.x, first10.hint_at.z)
		f["guide_word"] = first10.hint_word
	if rivals != null and rivals.ladder != null and wallet != null:
		var nxt: int = rivals.ladder.next_rung()
		f["next"] = nxt
		f["open"] = rivals.ladder.is_open(nxt)
		f["respect"] = int(wallet.respect)
		f["need"] = Ladder.threshold(mini(nxt, Ladder.FINAL))
		if nxt < Ladder.FINAL:
			f["rival"] = str(Ladder.RUNGS[nxt]["rival"])
			f["rival_at"] = rivals.rival_at(f["rival"])
		f["night"] = rivals.night()
		f["final_at"] = rivals.start_marker()
		f["jobs"] = wallet.jobs_done()
		f["end_jobs"] = First10.END_JOBS
		f["end_seen"] = wallet.intro.has("end_seen")
	else:
		f["next"] = Ladder.FINAL + 1
		f["end_seen"] = true
	main_step = MainLine.step(f)
	hud.set_main_line(main_step["at"], str(main_step["pl"]), str(main_step["en"]))
	# Nothing comes by itself on the title, in a camera moment or in Spacer (spacer.gd).
	var quiet := title != null or (moments != null and moments.playing()) or (spacer != null and spacer.on)
	var n := _nudge.tick(MainLine.STEP_EVERY, main_step, _free_now, quiet)
	_nudge_arrow = bool(n["arrow"])
	if bool(n["toast"]):
		hud.toast("★ " + str(main_step["pl"]), "★ " + str(main_step["en"]))
		print("main line: goal line %s" % main_step["id"])


## The arrow and minimap dot for the mission target.
func _show_target() -> void:
	_free_now = false
	if boat_race != null and boat_race.has_target():
		var bp: Vector3 = boat_race.target_position()
		var at_b := _vehicle_position()
		var mb := roundi(Vector2(bp.x - at_b.x, bp.z - at_b.z).length())
		var on_b := cam.unproject_position(bp + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		# The next ring stands bright in view: the arrow only when it is off screen.
		# On the water the rings themselves lead (the next three stand in view): no arrow over the boat.
		hud.set_target(on_b, "%d m" % mb, boat_race.target_colour(), mb > 12 and not boat_race.boating())
		_put_target(Vector2(bp.x, bp.z), boat_race.target_colour(), false)
		_new_target("job", bp)
		return
	if kino_tour != null and kino_tour.has_target() and not flying:
		var kp: Vector3 = kino_tour.target_position()
		var at_k := _vehicle_position()
		var mk := roundi(Vector2(kp.x - at_k.x, kp.z - at_k.z).length())
		var on_k := cam.unproject_position(kp + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on_k, "%d m" % mk, kino_tour.target_colour(), mk > 12)
		_put_target(Vector2(kp.x, kp.z), kino_tour.target_colour(), false)
		_new_target("job", kp)
		return
	if rave != null and rave.has_target() and not flying:
		var vp: Vector3 = rave.target_position()
		var at_v := _vehicle_position()
		var mv := roundi(Vector2(vp.x - at_v.x, vp.z - at_v.z).length())
		var on_v := cam.unproject_position(vp + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on_v, rave.target_label(mv), rave.target_colour(), mv > 12)
		_put_target(Vector2(vp.x, vp.z), rave.target_colour(), false)
		_new_target("job", vp)
	if meet != null and meet.has_target() and not flying:
		var kp: Vector3 = meet.target_position()
		var at_k := _vehicle_position()
		var mk := roundi(Vector2(kp.x - at_k.x, kp.z - at_k.z).length())
		var on_k := cam.unproject_position(kp + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on_k, "%d m" % mk, meet.target_colour(), mk > 12)
		_put_target(Vector2(kp.x, kp.z), meet.target_colour(), false)
		_new_target("job", kp)
		return
	if ev_tow != null and ev_tow.has_target():
		var ep: Vector3 = ev_tow.target_position()
		var at_e := _vehicle_position()
		var me := roundi(Vector2(ep.x - at_e.x, ep.z - at_e.z).length())
		var on_e := cam.unproject_position(ep + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on_e, "%d m" % me, ev_tow.target_colour(), me > 12)
		_put_target(Vector2(ep.x, ep.z), ev_tow.target_colour(), false)
		_new_target("job", ep)
		return
	if rivals != null and rivals.has_target():
		var f: Vector3 = rivals.target_position()
		var p := _vehicle_position()
		var m := roundi(Vector2(f.x - p.x, f.z - p.z).length())
		var on := cam.unproject_position(f + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on, "%d m" % m, rivals.target_colour(), m > 12)
		_put_target(Vector2(f.x, f.z), rivals.target_colour(), _guide_on() or rivals.main_race())
		_new_target("race", f)
		return
	# Loop MW-4: the "Na czasie" job's queue, then its door.
	if trend_job != null and trend_job.has_target() and Lines.shows(Lines.Line.CAR, flying):
		var tp: Vector3 = trend_job.target_position()
		var at_t := _vehicle_position()
		var mt := roundi(Vector2(tp.x - at_t.x, tp.z - at_t.z).length())
		var on_t := cam.unproject_position(tp + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on_t, "%d m" % mt, trend_job.target_colour(), mt > 12)
		_put_target(Vector2(tp.x, tp.z), trend_job.target_colour(), _guide_on())
		_new_target("job", tp)
		return
	# Loop 2d-1: a Podwózka ride's pin, passenger or door.
	if rides != null and rides.has_target() and Lines.shows(Lines.Line.CAR, flying):
		var rp: Vector3 = rides.target_position()
		var at_r := _vehicle_position()
		var mr := roundi(Vector2(rp.x - at_r.x, rp.z - at_r.z).length())
		var on_r := cam.unproject_position(rp + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on_r, "%d m" % mr, rides.target_colour(), mr > 12)
		_put_target(Vector2(rp.x, rp.z), rides.target_colour(), _guide_on())
		_new_target("job", rp)
		return
	if jobs != null and jobs.has_target() and Lines.shows(Lines.Line.CAR, flying):
		var j: Vector3 = jobs.target_position()
		var at_j := _vehicle_position()
		var mj := roundi(Vector2(j.x - at_j.x, j.z - at_j.z).length())
		var on_j := cam.unproject_position(j + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on_j, "%d m" % mj, jobs.target_colour(), mj > 12)
		_put_target(Vector2(j.x, j.z), jobs.target_colour(), _guide_on())
		_new_target("job", j)
		return
	# G12 part 2: the quest pin picked on the full map, while nothing else is on; reached, it goes.
	if not quest_pin.is_empty() and not missions.has_target():
		var qp: Vector2 = quest_pin["at"]
		var at_q := _vehicle_position()
		var cassette := str(quest_pin["group"]) == "cassette"
		var cid := str(quest_pin["id"]).trim_prefix("cassette_")
		if str(quest_pin["group"]) in Lines.MOVING and rivals != null:
			# G12c: the rival's pin follows them through traffic.
			var moved: Vector2 = rivals.rival_at(str(quest_pin.get("who", "")))
			if moved != Vector2.INF:
				quest_pin["at"] = moved
				qp = moved
		if (cassettes.is_taken(cid) if cassette else Lines.pin_reached(quest_pin, Vector2(at_q.x, at_q.z))):
			print("quest list: pin %s reached" % quest_pin["id"])
			quest_pin = {}
		elif Lines.shows(int(quest_pin["line"]), flying):
			var mq := roundi(Vector2(qp.x - at_q.x, qp.y - at_q.z).length())
			var yq: float = map.ground_height(qp.x, qp.y) + 3.5
			if cassette:
				yq = cassettes.at(cassettes.index_of(cid)).y + 3.5
			var on_q := cam.unproject_position(Vector3(qp.x, yq, qp.y)) * float(view.stretch_shrink)
			var cq: Color = quest_pin["colour"]
			hud.set_target(on_q, "%d m" % mq, cq, mq > 12)
			_put_target(qp, cq, false)
			return
	# Loop 3h slice 4: the guide's arrow (the first stand, the boulevard tape, Powiśle, the garage).
	if not missions.has_target() and first10 != null and first10.hint_shown():
		var fp: Vector3 = first10.hint_at
		var at_f := _vehicle_position()
		var mf := roundi(Vector2(fp.x - at_f.x, fp.z - at_f.z).length())
		var on_f := cam.unproject_position(fp + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on_f, "%s %d m" % [first10.hint_word, mf], First10.HINT_COLOUR, mf > 12)
		_put_target(Vector2(fp.x, fp.z), First10.HINT_COLOUR, true)
		return
	# Loop MW-6: Spacer's soft hint, the edge arrow to the nearest notebook place not found yet.
	if not missions.has_target() and spacer != null and spacer.hint_shown():
		var hp := spacer.hint_at
		var at_h := _vehicle_position()
		var mh := roundi(Vector2(hp.x - at_h.x, hp.y - at_h.z).length())
		var on_h := cam.unproject_position(Vector3(hp.x, map.ground_height(hp.x, hp.y) + 3.5, hp.y)) * float(view.stretch_shrink)
		hud.set_target(on_h, "? %d m" % mh, Spacer.HINT_COLOUR, mh > 25)
		_put_target(hp, Spacer.HINT_COLOUR, false)
		if notes != null and notes.is_found(spacer.hint_id):
			spacer.dismiss()
		return
	# The main line's nudge (main_nudge.gd): now and then, while nothing else is on, the gold edge
	# arrow to the next rival or the final's start; the minimap keeps its star (no side pin).
	var ma: Vector2 = main_step.get("at", Vector2.INF)
	if not missions.has_target() and _nudge_arrow and ma != Vector2.INF and Lines.shows(Lines.Line.CAR, flying):
		var at_m := _vehicle_position()
		var mm := roundi(Vector2(ma.x - at_m.x, ma.y - at_m.z).length())
		var on_m := cam.unproject_position(Vector3(ma.x, map.ground_height(ma.x, ma.y) + 3.5, ma.y)) * float(view.stretch_shrink)
		hud.set_target(on_m, "★ %d m" % mm, MainLine.COLOUR, mm > 12)
		_put_target(Vector2.INF, Color.WHITE, false)
		_free_now = not _quest_running()
		return
	if not missions.has_target():
		hud.set_target(Vector2.ZERO, "", Color.WHITE, false)
		_put_target(Vector2.INF, Color.WHITE, false)
		_last_target_source = ""
		_free_now = not _quest_running()  # quest focus: no main-line toast over a countdown or a door
		return
	var t: Vector3 = missions.target_position()
	var colour: Color = missions.target_colour()
	var pos := _vehicle_position()
	var metres := roundi(Vector2(t.x - pos.x, t.z - pos.z).length())
	var at := cam.unproject_position(t + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
	# Up close the ring says enough, and the pointer would sit on the vehicle's own marker.
	hud.set_target(at, "%d m" % metres, colour, metres > 12)
	_put_target(Vector2(t.x, t.z), colour, _guide_on())
	_new_target("rescue", t)


## Camera loop: a new rescue or delivery target (not a race's: they come one after another) gets a
## short look and back (camera_shots.gd), when the vehicle is slow (under LOOK_SPEED) and no
## finger or pedal is down (a held stick keeps the camera on the car), and not straight after
## the fly-in or another look.
const LOOK_SPEED := 30.0 / 3.6


func _new_target(source: String, t: Vector3) -> void:
	var fresh := source != _last_target_source or _last_target == Vector3.INF \
			or Vector2(t.x - _last_target.x, t.z - _last_target.z).length() > 30.0
	_last_target_source = source
	_last_target = t
	if not fresh or not cinematic_look or source == "race" or moments == null or moments.playing():
		return
	if title != null or _phone_bench or cam_test != "":
		return
	var p := _vehicle_position()
	var speed: float = heli.speed() if flying else absf(car.forward_speed)
	var busy: bool = hud.stick_active() or controls.held or hud.gas or hud.brake or _heli_held
	if speed > LOOK_SPEED or busy or Vector2(t.x - p.x, t.z - p.z).length() < CameraShots.NEAR:
		return
	var ground := Vector3(p.x, map.ground_height(p.x, p.z), p.z) if flying else p
	_queue_look(ground, t)


## Loop 2b: benches, bins and bike racks (map_builder.gd FINE_GROUP) hide in a view wider than
## FINE_VIEW metres (a bin is under two pixels there), back below 0.9 of it.
const FINE_VIEW := 170.0
var _fine_shown := true


func _fine_detail() -> void:
	var show := cam.size < (FINE_VIEW if _fine_shown else FINE_VIEW * 0.9)
	if show != _fine_shown:
		_fine_shown = show
		get_tree().call_group(MapBuilder.FINE_GROUP, "set_visible", show)


## Tree crowns near a low helicopter shake in the downwash.
func _rotor_wash() -> void:
	var strength := 0.0
	if flying:
		strength = clampf(1.0 - heli.height_above / 30.0, 0.0, 1.0)
	if strength > 0.0 or _wash_on:
		var p := heli.global_position
		map.leaf_material.set_shader_parameter("wash", Vector3(p.x, p.z, strength))
		_wash_on = strength > 0.0


func _read_input(dt: float) -> void:
	if title != null:
		# The title screen is up: the car waits, parked (loop 2b: it no longer reverses).
		car.target_dir = Vector3.ZERO
		car.steer = 0.0
		car.throttle = 0.0
		car.braking = true
		car.parked = true
		controls.release()
		return
	# Loop MW-6: Fotka holds the car (and the helicopter) still; the city goes on. Parked, not
	# just braking: a held brake at a standstill reverses (car.gd), and the car backed into the
	# buildings behind it for as long as Fotka was open (F, 2026-11-01).
	if fotka != null and fotka.is_open():
		car.target_dir = Vector3.ZERO
		car.steer = 0.0
		car.throttle = 0.0
		car.braking = true
		car.parked = true
		controls.release()
		heli.input_dir = Vector3.ZERO
		heli.climb = 0.0
		return
	car.parked = flying
	var left := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	var gas := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	var down := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	var space := Input.is_physical_key_pressed(KEY_SPACE)
	if Input.is_action_just_pressed("ui_page_up"):
		cam_yaw_target -= 90.0

	if boat_race != null and boat_race.boating():
		# The boat race: the stick, keys and pedals drive the boat as they drive the car.
		controls.release()
		if not boat_race.autopilot:
			var bkeys := {"left": left, "right": right, "up": gas, "down": down, "brake": space}
			var bstick: Vector2 = hud.stick
			var bon: bool = hud.stick_active()
			if not bon and Gamepad.stick() != Vector2.ZERO:
				bstick = Gamepad.stick()
				bon = true
			controls.drive(boat_race.player, bstick, bon, bkeys, hud.gas or Gamepad.gas(), hud.brake or Gamepad.brake(), cam_yaw, dt)
		return
	if flying:
		# The car waits where it was left.
		car.target_dir = Vector3.ZERO
		car.steer = 0.0
		car.throttle = 0.0
		car.braking = true
		controls.release()
		_read_heli_input(left, right, gas, down, dt)
		return

	if cam_test != "":
		_cam_test_frame(dt)
		return
	# Loop 2a: the scheme maps the stick, keys and pedals (drive_controls.gd): Point / Fixed
	# point in screen space (the camera waits while held), Classic steers car-relative.
	var keys := {"left": left, "right": right, "up": gas, "down": down, "brake": space}
	# The gamepad loop: the pad's left stick stands in for the touch stick while no finger is on it;
	# RT is GAS, LT or B is BRAKE (gamepad.gd).
	var stick: Vector2 = hud.stick
	var stick_on: bool = hud.stick_active()
	var pad_stick := Gamepad.stick()
	if not stick_on and pad_stick != Vector2.ZERO:
		stick = pad_stick
		stick_on = true
	controls.drive(car, stick, stick_on, keys, hud.gas or Gamepad.gas(), hud.brake or Gamepad.brake(), cam_yaw, dt)
	# The drag (street_meet.gd): the car holds the strip and any gas is full gas.
	if meet != null:
		meet.hold_car(car)
	_lane_tick(dt)
	# G13: the nitro (bought at the garage): the disc by the horn, Shift on a keyboard, LB or RB on a
	# pad. Not N: N switches the time of day, so holding it for the nitro also turned day to dusk.
	car.nitro_hold = car.nitro_owned and (hud.nitro_held or Input.is_physical_key_pressed(KEY_SHIFT) or Gamepad.nitro())
	hud.set_nitro(car.nitro_owned, car.nitro_charge)
	# Loop 3g-1: a pull-over holds the car; the police's test drivers (--police-auto, --trap with
	# --pedal=gas, the soak's roaming autopilot) drive it.
	if police != null and police.control_car(car, dt):
		return

	if demo:
		car.target_dir = Vector3.ZERO
		car.throttle = 0.8
		car.steer = 0.0 if frame < 200 else 0.5 * sin(frame * 0.02)
	if water_test == 1 or water_test == 2:
		_water_test_frame()
	if ram_test == 1 or ram_test == 2:
		_ram_test_frame(dt)
	if tram_watch >= 0:
		_tram_watch_frame()
	if first_life:
		_first_life_frame(dt)
	if old_tram_flag == "follow":
		_old_tram_follow_frame()  # the vintage-tram loop


## The stick and W A S D both point in screen space (W is up the screen); Space /
## Shift (or F) or the ▲ ▼ pads climb and sink.
func _read_heli_input(left: bool, right: bool, up: bool, down: bool, dt: float) -> void:
	var stick: Vector2 = hud.stick
	var pad_stick := Gamepad.stick()  # the gamepad loop
	if not hud.stick_active() and pad_stick != Vector2.ZERO:
		stick = pad_stick
	var aim := Vector2(float(right) - float(left), float(down) - float(up))
	_heli_held = hud.stick_active() or pad_stick != Vector2.ZERO or aim != Vector2.ZERO
	_heli_release = 0.0 if _heli_held else _heli_release + dt
	if stick.length() > 0.2:
		aim = stick.normalized() * clampf((stick.length() - 0.2) / 0.8, 0.0, 1.0)
	elif aim != Vector2.ZERO:
		aim = aim.normalized()
	# The camera follows the helicopter while the stick is held (as the car's Point does), so a
	# held direction keeps the world direction it meant when it was set; pointing REAIM° or more
	# away means the screen as it is now.
	var yaw := cam_yaw
	if aim == Vector2.ZERO:
		_heli_set_aim = Vector2.ZERO
	else:
		if _heli_set_aim == Vector2.ZERO or absf(rad_to_deg(aim.angle_to(_heli_set_aim))) >= Controls.REAIM:
			_heli_set_aim = aim
			_heli_set_yaw = cam_yaw
		yaw = _heli_set_yaw
	heli.input_dir = Controls.screen_to_world(aim, yaw) if aim != Vector2.ZERO else Vector3.ZERO
	var climb := float(Input.is_physical_key_pressed(KEY_SPACE)) \
			- float(Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_F))
	heli.climb = clampf(climb + hud.climb + Gamepad.climb(), -1.0, 1.0)  # the pad: RT up, LT down
	if heli_stick != Vector2.ZERO:
		heli.input_dir = Vector3(heli_stick.x, 0.0, heli_stick.y).limit_length(1.0)
	if demo and not autopilot:
		# A slow circle at cruise height, for screenshots.
		var a := frame * 0.0035
		heli.input_dir = Vector3(cos(a), 0.0, sin(a)) * 0.55
		heli.climb = 0.0


## Testing aid (--autopilot): heads for the mission target. The helicopter climbs
## over whatever blocks it and comes straight down onto the target; the car slides
## there in a straight line, ignoring walls.
func _autopilot(dt: float) -> void:
	if _bench_ghost != null:
		_follow(_bench_ghost)
		return
	if rivals != null and rivals.drive_player():
		return
	if rides != null and rides.drive_player():
		return  # loop 2d-1
	if trend_job != null and trend_job.drive_player():
		return  # loop MW-4
	if jobs != null and jobs.drive_player():
		return
	if not missions.has_target():
		if flying:
			heli.input_dir = Vector3.ZERO
		return
	if missions.needs_heli() and not flying:
		_take_off(Heli.CRUISE)
	var t: Vector3 = missions.target_position()
	var pos := _vehicle_position()
	var to := Vector3(t.x - pos.x, 0.0, t.z - pos.z)
	var d := to.length()
	if flying:
		heli.input_dir = to / maxf(d, 0.001) * clampf(d / 80.0, 0.0, 1.0)
		var ground: float = map.ground_height(pos.x, pos.z)
		var cruise := maxf(Heli.CRUISE, t.y - ground + 20.0)
		if heli.blocked or (d > 6.0 and heli.alt_target < cruise - 1.0):
			heli.climb = 1.0
		elif d < 6.0:
			heli.climb = -1.0
		else:
			heli.climb = 0.0
		return
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.throttle = 0.0
	if d > 0.5:
		var step := minf(d, 22.0 * dt)
		car.global_position += to / d * step
		car.rotation.y = atan2(-to.x, -to.z)


## The player's car rides on a ghost driver (the bench route).
func _follow(d) -> void:
	car.collision_mask = 0
	car.global_position = d.pos
	car.rotation.y = d.yaw
	car.vel = Vector3(-sin(d.yaw), 0.0, -cos(d.yaw)) * d.v
	car.throttle = 0.0
	car.braking = false
	car.target_dir = Vector3.ZERO
	car.reset_physics_interpolation()


## H or the HELI / CAR button: take off from the car, or land and take the car back.
func _toggle_vehicle() -> void:
	if _phone_bench:
		return
	if flying and ev_tow != null and ev_tow.carrying():
		hud.toast("Najpierw odstaw %s pod ładowarkę (albo ✕)" % EvTow.NAME, "Set the %s down at the charger first (or ✕)" % EvTow.NAME)
		return
	if rivals != null and rivals.racing():
		hud.toast("Najpierw dokończ wyścig", "Finish the race first")
		return
	if boat_race != null and boat_race.busy():
		hud.toast("Najpierw dokończ wyścig łodzi (albo ✕)", "Finish the boat race first (or ✕)")
		return
	if kino_tour != null and kino_tour.busy():
		hud.toast("Wiktor nie lata: najpierw kina (albo ✕)", "Wiktor doesn't fly: the cinemas first (or ✕)")
		return
	if jobs != null and jobs.busy() and not flying:
		hud.toast("Najpierw dokończ kurs: zamówienie jedzie autem", "Finish the job first: it rides in the car")
		return
	if not flying and car.in_water:
		return  # loop 10a: the tow is on its way
	if not flying and first10 != null and first10.heli_locked():
		first10.heli_refused()  # loop 3h slice 4: the helicopter comes with the first rescue
		return
	if not flying:
		_take_off(Heli.CRUISE)
		if Gamepad.in_use():
			hud.toast(Gamepad.fmt("Helikopter: lewa gałka kieruje, {rt} / {lt} to wysokość"), Gamepad.fmt("Helicopter: steer with the left stick, {rt} / {lt} for height"))
		else:
			hud.toast("Helikopter: kieruj palcem, ▲ ▼ to wysokość", "Helicopter: steer with the stick, ▲ ▼ (Space / Shift) for height")
		return
	if heli.landing:
		heli.landing = false
		hud.toast("Lądowanie odwołane", "Landing cancelled")
		return
	var why := _landing_problem(heli.global_position)
	if not why.is_empty():
		hud.toast(why[0], why[1])
		return
	heli.landing = true
	hud.toast("Lądujemy…", "Landing…")


## Why the helicopter can't come down at `p` to give the car back: [] if it can, else the toast
## [text, gloss, "roof" | "water"]. Over a roof (v0.5), or, loop 10a, over the water (the car would come back in
## the river; a bridge deck over it is fine, and so is the shallow first metres by the bank:
## the car is put on dry ground next to it).
func _landing_problem(p: Vector3) -> Array:
	if map.top_height(p.x, p.z, Heli.RADIUS) > map.ground_height(p.x, p.z) + 1.0:
		return ["Wyląduj na otwartym terenie, żeby wziąć auto.", "Land on open ground to take the car.", "roof"]
	if map.in_water(p.x, p.z, map.ground_height(p.x, p.z)):
		return ["Tu nie wylądujesz: to woda. Szukaj brzegu.", "No landing on the water: find the bank.", "water"]
	return []


## The helicopter starts just above the car and rises to `height` above the ground.
func _take_off(height: float) -> void:
	var p := car.global_position
	# From the ground, not the car's y: with --at the car hasn't been set down yet.
	var ground: float = map.ground_height(p.x, p.z)
	heli.place(Vector3(p.x, ground + minf(height, 6.0), p.z), car.rotation.y, height)
	_set_flying(true)


## Touched down: the car comes back on a free spot next to the helicopter.
func _on_heli_landed() -> void:
	var p: Vector3 = heli.global_position
	var spot := _free_car_spot(p, heli.rotation.y)
	car.global_position = spot
	car.rotation.y = heli.rotation.y
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	_set_flying(false)


func _set_flying(on: bool) -> void:
	flying = on
	heli.visible = on
	heli.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	heli.input_dir = Vector3.ZERO
	heli.climb = 0.0
	hud.set_flying(on)


## The nearest spot to `p` where the car's box touches no wall, parked car or
## prop: rings of candidates 4 m apart, checked with one shape query each. Loop 10a: on the
## level of `p` (it was the top deck over each candidate: a tow under a bridge put the car up
## on it), and never in the water.
func _free_car_spot(p: Vector3, yaw: float) -> Vector3:
	var space := car.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 4.4)
	query.shape = box
	query.exclude = [car.get_rid()]
	var r := 0.0
	while r <= 24.0:
		var steps := 1 if r == 0.0 else 12
		for k in steps:
			var a := TAU * k / steps
			var x := p.x + cos(a) * r
			var z := p.z + sin(a) * r
			var y: float = map.drive_height(x, z, p.y + 0.5)
			if map.in_water(x, z, y):
				continue
			query.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y + 0.9, z))
			if space.intersect_shape(query, 1).is_empty():
				return Vector3(x, y, z)
		r += 4.0
	# Nothing free and dry within 24 m (out in the water): once more round the nearest dry ground.
	var dry: Vector2 = map.nearest_dry(p.x, p.z)
	if dry != Vector2(p.x, p.z):
		return _free_car_spot(Vector3(dry.x, map.terrain_height(dry.x, dry.y), dry.y), yaw)
	return Vector3(p.x, map.drive_height(p.x, p.z, p.y + 0.5), p.z)


## v0.8: a tap (or click) on a landmark shows its info card. The ray from the tapped
## pixel walks the roof grid (map_builder.pick_landmark) until it meets something
## standing; only a landmark answers.
func _on_tap(at: Vector2) -> void:
	if not _started or title != null:
		return
	var p := at / float(view.stretch_shrink)
	var k: int = _pick_unghosted(cam.project_ray_origin(p), cam.project_ray_normal(p))  # sweep 2
	if k < 0 or k >= map.landmark_info.size():
		return
	print("landmark tapped: ", map.landmark_info[k]["name"])
	var card: Dictionary = map.landmark_info[k]
	hud.show_info(card["name"], card["pl"], card["en"])


# --- sweep 2: a tap sees through the ghost --------------------------------------------------
## A roof-grid cell counts as see-through for a tap where the ghost takes at least this share
## of its pixels (building.gdshader keeps ghost_keep, 19 %, in the core).
const GHOST_PICK := 0.5


## Sweep 2: map_builder.pick_landmark's walk (1 m steps against the roof grid and the
## ground), stepping on through whatever the occlusion ghost has made see-through, so a tap
## on the cut-away part of a tower in front of the car picks what shows through the cut, not
## the tower. The ghost's test is ghost.gdshaderinc's, on the values _update_ghost gave
## building_mat; the camera is orthographic, so every point of the ray has the tapped
## pixel's view x, y and only the side of the car changes along it.
func _pick_unghosted(origin: Vector3, dir: Vector3) -> int:
	var radius := float(_shader_value(building_mat, "occlusion_radius", 0.0))
	var region := 0.0
	if radius > 0.0:
		var v := cam.global_transform.affine_inverse() * origin
		var car_v: Vector3 = _shader_value(building_mat, "car_view", Vector3(0, 0, -100000))
		var dv := (Vector2(v.x, v.y) - Vector2(car_v.x, car_v.y)) / radius \
				- Vector2(0.0, float(_shader_value(building_mat, "occlusion_lift", 0.2)))
		dv.x *= 0.78
		if dv.y > 0.0:
			dv.y /= float(_shader_value(building_mat, "occlusion_up", 1.35))
		region = 1.0 - smoothstep(0.74, 0.84, dv.length())
	if region < GHOST_PICK or dir.y > -0.01:
		return map.pick_landmark(origin, dir)
	var occ: Vector4 = _shader_value(building_mat, "occluder", Vector4(0, 0, 0, -1))
	var t := maxf(0.0, (origin.y - 340.0) / -dir.y)
	var end := t + 2600.0
	while t < end:
		var q := origin + dir * t
		var top: float = map.roof_height(q.x, q.z)
		if top != MapBuilder.NO_ROOF and q.y <= top:
			var side := (Vector2(q.x, q.z) - Vector2(occ.x, occ.y)).dot(Vector2(occ.z, occ.w))
			if region * smoothstep(1.0, 2.0, -side) < GHOST_PICK:
				return map.landmark_at(q.x, q.z)
		if q.y < map.terrain_height(q.x, q.z) - 0.5:
			return -1
		t += 1.0
	return -1


## A shader parameter's value on a material, or its shader's default when it was never set.
static func _shader_value(m: ShaderMaterial, key: String, fallback: Variant) -> Variant:
	var v: Variant = m.get_shader_parameter(key)
	if v == null and m.shader != null:
		v = RenderingServer.shader_get_parameter_default(m.shader.get_rid(), key)
	return fallback if v == null else v
# --- end sweep 2 ---------------------------------------------------------------------------


## The follow-camera loop: the player's zoom, one VIEWS step wider (+1) or closer (-1), saved.
func _zoom_view(steps: int) -> void:
	base_size = FollowCamera.view_step(base_size, steps)
	settings.view = base_size
	settings.save()


## The follow-camera loop: a pinch (`ratio`: the fingers' span now / before) steps the zoom each
## time the span has changed by PINCH_STEP since the last step.
func _on_pinch(ratio: float) -> void:
	_pinch_run *= ratio
	if _pinch_run >= FollowCamera.PINCH_STEP:
		_pinch_run = 1.0
		_zoom_view(-1)
	elif _pinch_run <= 1.0 / FollowCamera.PINCH_STEP:
		_pinch_run = 1.0
		_zoom_view(1)


func _unhandled_input(event: InputEvent) -> void:
	if not _started or title != null:
		return
	var pad := Gamepad.command(event)
	if pad != "":
		_pad_command(pad)
		get_viewport().set_input_as_handled()
		return
	var flick := Gamepad.view_flick(event)
	if flick != 0:
		_rotate_camera(flick)
		get_viewport().set_input_as_handled()
		return
	var wheel := event as InputEventMouseButton
	if wheel and wheel.pressed:
		if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_view(-1)
		elif wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_view(1)


func _unhandled_key_input(event: InputEvent) -> void:
	if not _started or title != null:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		match key.physical_keycode:
			KEY_Q:
				_rotate_camera(-1)
			KEY_E:
				_rotate_camera(1)
			KEY_C:
				_toggle_follow()
			KEY_H:
				_toggle_vehicle()
			KEY_B:
				# The night-buses loop: the horn (H was the helicopter's already).
				if buses != null and not flying:
					buses.honk()
			KEY_M:
				_primary()
			KEY_K:
				_secondary()
			KEY_N:
				_blip_sound()
				tod.next()
			KEY_R:
				# Shift+R skips to the station's next track (2026-10-30: radio.next_track() had no control).
				if key.shift_pressed:
					radio.next_track()
				else:
					radio.next()
			KEY_V:
				_blip_sound()
				_set_vhs(not vhs)
				settings.vhs = vhs
				settings.save()
			KEY_O:
				_blip_sound()
				weather.toggle()
			KEY_P:
				_set_perf(not show_perf)
				settings.perf = show_perf
				settings.save()
			KEY_ESCAPE:
				_open_settings()
			KEY_U:
				# Loop G1: Auto → Low → Medium → High → Ultra → Auto.
				_blip_sound()
				_set_quality(Tiers.AUTO if quality_choice >= Tiers.ULTRA else quality_choice + 1)
			KEY_L:
				_flash()
			KEY_MINUS:
				_zoom_view(1)
			KEY_EQUAL:
				_zoom_view(-1)


## M / the pad's A: the mission card's first button (loop 2d-1: a Podwózka request or result first).
## The context button comes after the cards (a card on screen is what A answers first) and before
## the rescue line's own A (which offers the next call): the pad had no way to press KASETA, START
## KURS or POMOC DROGOWA (2026-11-03).
func _primary() -> void:
	if (rides != null and rides.primary()) or (jobs != null and jobs.primary()) \
			or (trend_job != null and trend_job.primary()):
		return
	if missions.state == missions.State.OFFER or missions.state == missions.State.RESULT:
		missions.primary()
	elif not hud.press_pill():
		missions.primary()


## K / the pad's X: the mission card's second button.
func _secondary() -> void:
	if (rides == null or not rides.secondary()) and (jobs == null or not jobs.secondary()) \
			and (trend_job == null or not trend_job.secondary()):
		missions.secondary()


## L / the D-pad's left: flash the lights (loop jobs-2: the courier's challenge first, only while
## it is up).
func _flash() -> void:
	if (jobs == null or not jobs.flash()) and rivals != null:
		rivals.flash()


## The gamepad loop: a button press (gamepad.gd `command`) does what its key does.
func _pad_command(what: String) -> void:
	match what:
		"primary":
			_primary()
		"secondary":
			_secondary()
		"vehicle":
			_toggle_vehicle()
		"follow":
			_toggle_follow()
		"horn":
			if buses != null and not flying:
				buses.honk()
		"zoom_in":
			_zoom_view(-1)
		"zoom_out":
			_zoom_view(1)
		"radio":
			radio.next()
		"flash":
			_flash()
		"map":
			_open_full_map()
		"settings":
			_open_settings()


## The gamepad loop: the pad used last hides the touch pedals and pads (and the HUD speaks of the
## pad's buttons); a finger on the screen brings them back at once (hud.gd `_input`).
func _note_pad(event: InputEvent) -> void:
	var was := Gamepad.in_use()
	Gamepad.note(event)
	if hud != null and Gamepad.in_use() != was:
		hud.set_pad_mode(Gamepad.in_use(), no_touch)


func _screen_to_world(s: Vector2) -> Vector3:
	var right := cam.global_transform.basis.x
	right.y = 0.0
	var ahead := -cam.global_transform.basis.z
	ahead.y = 0.0
	return right.normalized() * s.x + ahead.normalized() * -s.y


func _update_camera(dt: float) -> void:
	if club != null and club.inside:
		# The club's room (club.gd): a fixed cutaway view from its open corner.
		var cb := Basis.from_euler(Vector3(deg_to_rad(camera_pitch), deg_to_rad(club.yaw), 0.0))
		cam.size = club.view_size
		cam.global_transform = Transform3D(cb, club.centre + cb.z * 120.0)
		cam.far = 300.0
		return
	var vehicle: Node3D = heli if flying else car
	var speed: float = heli.speed() if flying else absf(car.forward_speed)
	if follow:
		# Camera loop (follow_camera.gd): the helicopter waits while the stick is held and 0.6 s
		# after, then eases round; Classic turns with the car; never faster than 64°/s. The
		# follow-camera loop: Point turns with the car too, finger down or not, more gently
		# (drive_controls.gd FOLLOW_HELD keeps a held direction from turning with it).
		var heading := rad_to_deg(vehicle.rotation.y)
		if flying:
			cam_yaw = fcam.follow_yaw(cam_yaw, heading, speed, false, _heli_held, _heli_release,
					FollowCamera.FULL_SPEED_HELI, dt, FollowCamera.RETURN_GAIN)
		else:
			var classic := controls.scheme == Controls.CLASSIC
			cam_yaw = fcam.follow_yaw(cam_yaw, heading, speed, controls.camera_waits(), controls.held,
					controls.since_release, FollowCamera.FULL_SPEED if classic else FollowCamera.FULL_SPEED_POINT, dt,
					FollowCamera.TURN_GAIN if classic else FollowCamera.RETURN_GAIN)
		cam_yaw_target = cam_yaw
	else:
		fcam.stop_turning()
		cam_yaw = lerpf(cam_yaw, cam_yaw_target, 1.0 - exp(-8.0 * dt))
	var basis := Basis.from_euler(Vector3(deg_to_rad(camera_pitch), deg_to_rad(cam_yaw), 0.0))
	var focus := vehicle.get_global_transform_interpolated().origin
	focus.y += cam_lift
	var size: float
	var focus_rate := FollowCamera.FOCUS_RATE
	if flying:
		# Aim between the helicopter and its shadow so both stay in view near the usual height;
		# higher up aim nearer the helicopter (the shadow leaves the view), so it stays in the
		# middle of the screen, and widen the view a little, up to HELI_WIDEN_MAX.
		focus.y -= heli.above_ground * heli_aim_share(heli.above_ground)
		var heli_view := base_size * HELI_VIEW + heli_widen(heli.above_ground)
		var heli_zoom := base_size * HELI_VIEW * 0.2 * clampf(speed / Heli.MAX_SPEED, 0.0, 1.0)
		size = heli_view + heli_zoom
		_view_size = fcam.zoom_step(_view_size, heli_view, heli_zoom, dt)
		focus_rate = 3.5
	else:
		# The coffee run's bike (car.gd model "bike", Autopilot playtest 2026-11-06: at the car's view
		# it could not be told from a car): the view closes in to BIKE_VIEW of the player's, eased
		# by zoom_step like the speed zoom, and back out when the car returns.
		var bike: bool = car.model == "bike"
		var view := base_size * (CoffeeRun.BIKE_VIEW if bike else 1.0)
		var zoom := view * FollowCamera.SPEED_ZOOM * clampf(speed / (car.top_speed() if bike else car.max_speed * car.top_mult), 0.0, 1.0)
		if boat_race != null and boat_race.boating():
			zoom *= BOAT_ZOOM  # the boat race: the rings and the rivals stay big enough to read
			if boat_race.state == BoatRace.State.FREE:
				view *= BOAT_FREE_VIEW
				zoom *= BOAT_FREE_VIEW
		size = view + zoom
		_view_size = fcam.zoom_step(_view_size, view, zoom, dt)
	# The look-ahead along the way it goes, and the dead zone's window (follow_camera.gd).
	var forward := Vector3(-basis.z.x, 0.0, -basis.z.z).normalized() \
			if follow and not flying and controls.scheme == Controls.CLASSIC else Vector3.ZERO
	var lead := fcam.lead_step(heli.vel if flying else car.vel, Heli.MAX_SPEED if flying else car.max_speed * car.top_mult,
			_view_size, dt, forward)
	cam_focus = fcam.focus_step(cam_focus, focus + lead, basis, _view_size, focus_rate, dt)

	var distance := maxf(CAMERA_DISTANCE, _view_size * 1.6)
	var view_xf := Transform3D(basis, _snap_to_pixels(cam_focus, basis, _view_size) + basis.z * distance)
	if moments != null and moments.frame(view_xf, _view_size, dt):
		# A cinematic moment (camera_shots.gd) placed the camera: snap where it put it.
		var b := cam.global_transform.basis
		cam.global_transform = Transform3D(b, _snap_to_pixels(cam.global_transform.origin, b, cam.size))
	else:
		cam.size = _view_size
		cam.global_transform = view_xf
	cam.far = _camera_far(maxf(CAMERA_DISTANCE, cam.size * 1.6), size)


## A point moved onto the pixel grid of a view `size` m tall turned `basis` (across and up the
## screen), so the city doesn't shimmer while the camera moves.
func _snap_to_pixels(p: Vector3, basis: Basis, size: float) -> Vector3:
	var texel := size / float(maxi(sv.size.y, 1))
	var r := p.dot(basis.x)
	var u := p.dot(basis.y)
	return p - basis.x * (r - snappedf(r, texel)) - basis.y * (u - snappedf(u, texel))


## Loop 2b: the camera's far plane, just past the lowest ground the view can show (the
## slab's walls, the river below the city: FAR_MARGIN). Godot's sun shadow covers an
## orthographic camera's whole depth, near to far (it ignores the light's max distance for
## them), so this sizes the shadow: far was 1,500 m past the view, a shadow map ~2 km across
## drawing every caster in it (the shadow pass had twice the main pass's draw calls) at
## ~0.5 m a texel. The depth is also chosen so the shadow's bounding sphere (Godot fits the
## near-far box's diagonal) keeps one size while the view widens with speed: texels that
## change size make the shadows' pixel edges crawl. It changes only when the player zooms.
const FAR_MARGIN := 130.0

## The helicopter's framing (GAMEPLAY_PLAN 3.1, 2026-11-03). The camera aims this share of the
## height down from the helicopter: half way to the shadow up to AIM_LOW_TOP, AIM_HIGH from
## AIM_HIGH_FROM up. At the 30° pitch the helicopter and its shadow are h·cos 30° apart on screen,
## so the old fixed half put it at the top edge from ~250 m (12 % from the top at 330 m).
const AIM_LOW_TOP := 50.0
const AIM_HIGH_FROM := 140.0
const AIM_HIGH := 0.1
## The view widens 0.8 m a metre over cruise height, never more than this (m): wider showed the
## map's edge and the sky past it from mid-map.
const HELI_WIDEN_MAX := 140.0


static func heli_aim_share(above_ground: float) -> float:
	return lerpf(0.5, AIM_HIGH, smoothstep(AIM_LOW_TOP, AIM_HIGH_FROM, above_ground))


static func heli_widen(above_ground: float) -> float:
	return minf(maxf(above_ground - Heli.CRUISE, 0.0) * 0.8, HELI_WIDEN_MAX)


func _camera_far(distance: float, size: float) -> float:
	var t := 1.0 / tan(deg_to_rad(maxf(absf(camera_pitch), 5.0)))
	var aspect := float(sv.size.x) / float(maxi(sv.size.y, 1))
	# The view's centre ray meets the ground this far past the focus: the focus's height over the
	# ground under it along the ray (1 / sin pitch), the camera's own aim over the helicopter's
	# ground, not the roof under it (that cut the ground at the screen's top over tall buildings,
	# leaving their upper floors floating over the sky's colour).
	var above := 0.0
	if flying:
		above = maxf(cam_focus.y - minf(map.ground_height(cam_focus.x, cam_focus.z), heli.global_position.y - heli.above_ground), 0.0)
	var low: float = FAR_MARGIN + above / sin(deg_to_rad(maxf(absf(camera_pitch), 5.0)))
	# The widest this zoom gets: the car's view at top speed, the helicopter's as it is.
	var widest := maxf(cam.size, size if flying else base_size * (1.0 + FollowCamera.SPEED_ZOOM))
	var reach: float = maxf(CAMERA_DISTANCE, widest * 1.6) + 0.5 * widest * t + low
	var diagonal := reach * reach + widest * widest * (aspect * aspect + 1.0)
	var need: float = distance + 0.5 * cam.size * t + low
	var depth := sqrt(maxf(diagonal - cam.size * cam.size * (aspect * aspect + 1.0), need * need))
	return cam.near + depth


## --stops=FILE (with --shots= far ahead): the camera stops at each [x, z, yaw, pitch, size, name]
## of the JSON list and saves <name>.png in --out, so one run shoots a whole street.
var stops: Array = []
var _stop_at := 0
var _stop_busy := false
const STOP_DRAWS := 24


func _stop_step() -> void:
	if stops.is_empty() or frame < 120 or _stop_busy or _stop_at >= stops.size():
		return
	_stop_busy = true
	var s: Array = stops[_stop_at]
	car.global_position = Vector3(s[0], map.ground_height(s[0], s[1]), s[1])
	car.vel = Vector3.ZERO
	cam_yaw = s[2]
	cam_yaw_target = s[2]
	camera_pitch = s[3]
	base_size = s[4]
	_view_size = s[4]
	cam.size = s[4]
	cam_focus = car.global_position
	# Count drawn frames, not game frames: a hidden window can draw far less often than it runs.
	for i in STOP_DRAWS:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s.png" % s[5]))
	_stop_at += 1
	_stop_busy = false
	print("stops: %d / %d %s at %.0f,%.0f" % [_stop_at, stops.size(), s[5], car.global_position.x, car.global_position.z])
	if _stop_at >= stops.size():
		_quit_quietly()


func _capture(n: int) -> void:
	await RenderingServer.frame_post_draw
	if ghost_debug > 0:
		print("ghost: frame %d centre %.1f %.1f radii %.1f %.1f (screen px)" % [n, _ghost_px.x, _ghost_px.y, _ghost_px.z, _ghost_px.w])
	var img := get_viewport().get_texture().get_image()
	# A missing --out folder used to end the run with code 0 and no PNG: make it, and fail loudly.
	var dir := ProjectSettings.globalize_path(out_dir)
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var name := "shot_%04d.png" % n
	if not shot_spots.is_empty():
		name = "%s_%04d.png" % [shot_spots[_spot_i][0], n - _spot_base]
	var err := img.save_png(out_dir.path_join(name))
	if err != OK:
		printerr("shots: could not write %s (error %d)" % [out_dir.path_join(name), err])
		get_tree().quit(1)
		return
	_shots_saved.append(n)
	if n == shots.max():
		if _spot_i + 1 < shot_spots.size():
			_next_spot()
			return
		_quit_quietly()  # sweep 2: was get_tree().quit()


## --spots: the frame the current spot's shot frames count from.
var _spot_base := 0


## --spots: moves the car (and the camera, with no blend) to the next spot and shifts the shot
## frames by the frames spent so far, so each spot gets the same settle time as the first.
func _next_spot() -> void:
	_spot_i += 1
	var sp: Array = shot_spots[_spot_i]
	var p: Vector2 = sp[1]
	car.global_position = Vector3(p.x, map.ground_height(p.x, p.y), p.y)
	if sp[2] != INF:
		car.rotation.y = -deg_to_rad(sp[2])
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	cam_focus = car.global_position
	# The same view as the first spot (and as a single --at run): keep the camera's yaw, since
	# _cut_camera turns a following camera behind the car.
	var yaw := cam_yaw
	var yaw_target := cam_yaw_target
	_cut_camera()
	cam_yaw = yaw
	cam_yaw_target = yaw_target
	var shift: int = frame - _spot_base
	_spot_base = frame
	for i in shots.size():
		shots[i] += shift
	print("shots: spot %s at %.0f, %.0f (frame %d, shots %s)" % [sp[0], p.x, p.y, frame, str(shots)])


# --- sweep 2: a shots run quits without leaking its sounds ---------------------------------
## Real milliseconds the audio server gets to let the stopped sounds go before the quit.
const QUIET_QUIT_MS := 150


## Sweep 2: windowed `--shots` runs sometimes ended with "8 ObjectDB instances were leaked at
## exit" / "4 resources still in use": the sounds playing at the quit (an AudioStreamWAV and
## its playback each: the radio's station, the engine's idle and mid loops, the city bed),
## still held by the audio server because the tree went before its mixing thread let them
## go (headless runs have no audio device, so they never showed it). The game stops updating
## (sfx.gd would start a loop again), every player is stopped, and the server gets
## QUIET_QUIT_MS of real time before the quit.
func _quit_quietly() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	for kind: String in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for p: Node in get_tree().root.find_children("*", kind, true, false):
			p.call("stop")
	var until := Time.get_ticks_msec() + QUIET_QUIT_MS
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
	get_tree().quit()
# --- end sweep 2 ---------------------------------------------------------------------------


# --- Loop 3c: the city in sectors ---------------------------------------------------------
# Kept in one block so other loops' changes to this file merge cleanly. The streamer
# (sector_streamer.gd) owns the map node and the sectors; this block opens it, feeds it the
# camera every frame, gives new sectors the game's state (the time of day, the quality's
# shadows, the fine detail, --exp) and runs the streaming test aids: --monolithic (the whole
# city built at once from centrum.json, as before loop 3c: the pixel diff's reference),
# --sectors=all (every sector loaded and kept), --sectors=proxies (only the sectors the car stands
# in, everything else as its proxy, to look at them), --stream-log (each load and unload with its
# frame and main-thread ms), --spots=X,Z,H/X,Z,H/... with --shots=F1,F2,... (spot k: the car
# jumps there, heading H degrees, 90 frames before shot k, and the sectors the view needs are
# finished 30 frames before it; tools/check_streaming.gd), --stream-soak=MINUTES (the car on
# autopilot over the whole map, the view widening and narrowing, the helicopter for the last
# third; then the streaming numbers, and the game quits).

const SectorStreamer := preload("res://scripts/sector_streamer.gd")
var streamer: SectorStreamer
var monolithic := false
var _sectors_all := false
var _sectors_proxies := false
var _stream_log := false
## Loop 3d-2b: --stream-ahead=0, --stream-slow=MS (sector_streamer.gd look_ahead, slow_ms).
var _stream_ahead := true
var _stream_slow := 0
var _stream_gate := true
var _spots: Array[Vector3] = []
var _soak_minutes := 0.0
var _soak_route: Array[Vector2] = []
var _soak_leg := 0
var _soak_t := 0.0
## Loop 3d-2b, --stream-pass=heli|car: one fast pass across the map instead of the soak's tour
## (the helicopter at its highest and fastest, or the car at PASS_CAR_SPEED in its widest view).
## The loading fix (2026-10-31), the passes that look for a proxy close up: heli-low (the helicopter
## at its usual 45 m, full speed, four turns from the spawn), start (the same from the first frame,
## no waiting for the ring round the start), switch (the car at PASS_CAR_SPEED, then the helicopter
## takes off and flies on), look (hovering at the spawn, a look at a target 0.6-3 km away every
## PASS_EVENT_S, as a new rescue or delivery target gets) and jump (the car put somewhere new every
## PASS_EVENT_S, as a tow or a race start does).
var _pass_kind := ""
const PASS_CAR_SPEED := 45.0
const PASS_EVENT_S := 7.0
## Frames since the pass put the vehicle at its start (-1 once the pass runs: the numbers count
## from the first frame at least 180 frames on with nothing left to load).
var _pass_frames := 0


func _parse_stream_args() -> void:
	for arg in game_args():
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
			_soak_minutes = float(arg.trim_prefix("--stream-soak="))
			no_traffic = true
			free_roam = true
			show_title = false
		elif arg.begins_with("--stream-pass="):
			_pass_kind = arg.trim_prefix("--stream-pass=")
			_soak_minutes = 30.0  # the pass ends at its route's end
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
				_pass_frames = -1  # counted from the first frame: no waiting for the ring round the start
				_soak_leg = 1


## Loop 3d-1: "" when the city this run needs is there, else what is missing and how to make it
## (the sector split and the prebuilt sectors are derived, not committed: tools/setup_map.sh).
func _missing_map() -> String:
	if monolithic:
		return "" if FileAccess.file_exists(MAP_PATH) else "map: no %s (the committed map data)" % MAP_PATH
	var use_prebuilt := (prebuilt or not OS.has_feature("editor")) and solo_site == ""
	if use_prebuilt and not ResourceLoader.exists("res://map/index.res"):
		return "map: the prebuilt sectors are missing (map/index.res, sectors/*.scn): run tools/setup_map.sh once (docs/DEVELOPMENT.md \"Map data\")"
	if not use_prebuilt and not FileAccess.file_exists("res://map/index.json"):
		return "map: the sector split is missing (map/index.json, sectors/*.json): run tools/setup_map.sh once (docs/DEVELOPMENT.md \"Map data\")"
	return ""


func _open_streamed_city(world: Node3D, flat_mat: ShaderMaterial) -> Dictionary:
	streamer = SectorStreamer.new()
	streamer.name = "SectorStreamer"
	streamer.load_all = _sectors_all
	streamer.proxies_only = _sectors_proxies
	streamer.log = _stream_log
	streamer.look_ahead = _stream_ahead
	streamer.slow_ms = _stream_slow
	streamer.gate_pieces = _stream_gate
	add_child(streamer)
	streamer.sector_ready.connect(_on_sector_ready)
	var use_prebuilt := (prebuilt or not OS.has_feature("editor")) and solo_site == ""
	var data := streamer.open(world, use_prebuilt, building_mat, flat_mat, start_at)
	map = streamer.map
	building_mat = map.building_material
	# The ground's AO flags (--debug-ao, --no-ao) on either path's material.
	map.flat_material.set_shader_parameter("debug_ao", debug_ao)
	map.flat_material.set_shader_parameter("ao_strength", 0.0 if no_ao else 1.0)
	if _pass_kind != "":
		_soak_route = _pass_route(data)
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://stream_soak_result.txt"))
	elif _soak_minutes > 0.0:
		_soak_route = _soak_tour(data)
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://stream_soak_result.txt"))
	return data


## The map's own nodes and every loaded sector's (not the proxies).
func _city_nodes() -> Array[Node]:
	var out: Array[Node] = []
	for c in map.get_children():
		if c.name == "Sectors":
			for s in c.get_children():
				out.append_array(s.get_children())
		elif c.name != "Proxies":
			out.append(c)
	return out


## A sector's nodes take what the rest of the city has: the night-only ones shown with the
## lights, small casters' shadows as _apply_extras last set them (the quality, the governor's
## GPU level, the wide view; loop G1), fine detail by the view's width, --exp.
func _on_sector_ready(root: Node3D) -> void:
	# Loop MW-2: the storefronts first (the neon atlas, a Neon holder of their own goes in below).
	if storefronts != null:
		storefronts.on_sector_ready(root)
	if buses != null:
		buses.on_sector_ready(root)  # the night-buses loop: the sector's shelters become stops
	var lit := tod != null and tod.lights_on > 0.001
	var small: bool = _small_cast == 1 if _small_cast >= 0 else bool(QUALITY[quality]["small_shadows"])
	var cast := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if small else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Sweep 2 x loop 3c: each sector holds its own "Neon" node (not the map's root, where
	# _neon_materials looks), so its signs' shared material joins the ghost's list here.
	var neon := root.get_node_or_null("Neon")
	if neon != null:
		for c in neon.get_children():
			var ng := c as GeometryInstance3D
			var nm := ng.material_override as ShaderMaterial if ng != null else null
			if nm != null and not _neon_mats.has(nm):
				_neon_mats.append(nm)
	for n in root.find_children("*", "", true, false):
		if n.is_in_group("night_lights"):
			(n as Node3D).visible = lit
		if n.is_in_group(MapBuilder.SMALL_CASTERS):
			(n as GeometryInstance3D).cast_shadow = cast
		if n.is_in_group(MapBuilder.FINE_GROUP):
			(n as Node3D).visible = _fine_shown
		var g := n as GeometryInstance3D
		if g == null:
			continue
		for e in _exp:
			var mmi := n as MultiMeshInstance3D
			var leaf: bool = mmi != null and mmi.material_override == map.leaf_material
			if (e == "notrees" and leaf) or (e == "noprops" and mmi != null and not leaf):
				g.visible = false
			elif (e == "nosmallcasters" and mmi != null) or e == "nocasters":
				g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _stream_frame(dt: float) -> void:
	if streamer != null:
		if _soak_minutes > 0.0:
			_soak_frame(dt)
		var forced := streamer.forced
		streamer.update(cam_focus, _vehicle_position(), cam)
		# A sector loaded at once (a jump: a tow, a race start) stalls this frame: the governor
		# (loop G1) counts afresh rather than read it as the frames running late. Streamed loads
		# stay inside the frame's budget and count as any other work.
		if streamer.forced > forced:
			governor.reset(_clock_s())
	if _spots.is_empty() or shots.is_empty():
		return
	var sorted := shots.duplicate()
	sorted.sort()
	for k in mini(_spots.size(), sorted.size()):
		if frame == sorted[k] - 90:
			_jump_to_spot(_spots[k])
		elif frame == sorted[k] - 30 and streamer != null:
			streamer.finish_view(cam_focus, cam)


## --spots: the car to a spot (x, z, heading in degrees), standing, the view on it.
func _jump_to_spot(s: Vector3) -> void:
	car.global_position = Vector3(s.x, map.ground_height(s.x, s.y), s.y)
	car.rotation.y = -deg_to_rad(s.z)
	car.vel = Vector3.ZERO
	car.reset_physics_interpolation()
	_cut_camera()
	# The sectors round the spot in at once, colliders and all, as the whole city has them.
	if streamer != null:
		streamer.finish_view(cam_focus, cam)
	print("spot: %.1f, %.1f heading %.0f at frame %d" % [s.x, s.y, s.z, frame])


## --stream-soak: a serpentine over every sector's middle (row by row), inside the map.
func _soak_tour(data: Dictionary) -> Array[Vector2]:
	var b: Array = data["bounds"]
	var inner := Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1]).grow(-60.0)
	var rows := {}
	for key in streamer.keys:
		var c := (Vector2(key) + Vector2(0.5, 0.5)) * SectorStreamer.SECTOR
		c = c.clamp(inner.position, inner.end)
		if not map.in_map(c, -60.0):
			continue  # map north: a sector's middle in the corner left outside
		if not rows.has(key.y):
			rows[key.y] = []
		rows[key.y].append(c)
	var route: Array[Vector2] = []
	var ys := rows.keys()
	ys.sort()
	for r in ys.size():
		var row: Array = rows[ys[r]]
		row.sort_custom(func(a: Vector2, c: Vector2) -> bool: return a.x < c.x if r % 2 == 0 else a.x > c.x)
		for p: Vector2 in row:
			route.append(p)
	return route


## Loop 3d-2b, --stream-pass: the helicopter west to east across the map's middle north of the
## centre (the Palace, the river, Praga); the car east to west south of it.
func _pass_route(data: Dictionary) -> Array[Vector2]:
	var b: Array = data["bounds"]
	var inner := Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1]).grow(-120.0)
	if _pass_kind == "heli":
		return [Vector2(inner.position.x, -300.0), Vector2(inner.end.x, -300.0)]
	if _pass_kind == "car":
		return [Vector2(inner.end.x, 250.0), Vector2(inner.position.x, 250.0)]
	# The loading fix's passes start at the spawn (route[0]); look's points are its targets, jump's
	# where the car is put.
	var spawn: Dictionary = data.get("spawn", {})
	var route: Array[Vector2] = [Vector2(float(spawn.get("x", 0.0)), float(spawn.get("z", 0.0)))]
	var points: Array = []
	match _pass_kind:
		"heli-low", "start", "switch":
			points = [[300, 279], [300, -800], [-1400, -800], [-1400, 900]]
			# start: the first two legs (the first minute matters); switch: the car's leg and two flown.
			points = points.slice(0, {"heli-low": 4, "start": 2, "switch": 3}[_pass_kind])
		"look":
			points = [[-300, 280], [-900, -750], [-2400, 600], [1000, -500], [1900, -900], [-2900, 1500]]
		"jump":
			points = [[500, -300], [-2500, -1200], [1500, 900], [-300, 1300], [-1500, -1700], [1200, -1500]]
		_:
			push_warning("--stream-pass=%s: no such pass (heli, car, heli-low, start, switch, look, jump)" % _pass_kind)
	for q: Array in points:
		route.append(Vector2(float(q[0]), float(q[1])).clamp(inner.position, inner.end))
	return route


## --stream-soak, each frame: the car (then the helicopter) along the tour at 22 m/s, through
## buildings like the mission autopilot; the view 1x, then wide (220 m), every 20 s.
func _soak_frame(dt: float) -> void:
	_soak_t += dt
	if _pass_kind in ["look", "jump"]:
		if _pass_frames < 0 and _soak_t >= PASS_EVENT_S * _soak_route.size():
			_soak_minutes = _soak_t / 60.0  # the last look or jump had its PASS_EVENT_S: report
	elif _pass_kind != "" and _soak_leg >= _soak_route.size():
		_soak_minutes = _soak_t / 60.0  # the pass is over: report as the soak does
	if _soak_t >= _soak_minutes * 60.0:
		print("stream soak: %.0f s over %d sectors: %s" % [_soak_t, streamer.keys.size(), streamer.summary()])
		var numbers := streamer.stats()
		numbers["governor"] = "%s, %d changes%s" % [governor.state(), governor.changes, ", held" if governor.held else ""]
		print("stream soak stats: " + JSON.stringify(numbers))
		# Loop G0+: the numbers also go to a file (as the bench's card does), written and closed
		# here: on the iPhone get_tree().quit() does nothing and the app is stopped from outside,
		# so the log's tail is never certain; tools/device_run.sh copies this file back.
		var f := FileAccess.open("user://stream_soak_result.txt", FileAccess.WRITE)
		if f != null:
			f.store_string("stream soak: %.0f s over %d sectors: %s\nstream soak stats: %s\n" % [
					_soak_t, streamer.keys.size(), streamer.summary(), JSON.stringify(numbers)])
			f.close()
		_soak_minutes = 0.0
		get_tree().quit()
		return
	if _soak_route.is_empty():
		return
	if _pass_kind != "" and _pass_frames >= 0:
		# The pass starts at its route's start: the vehicle put there, the view finished once the
		# camera has caught up (its zoom too) and the streamer has nothing left to load, and the
		# numbers counted from then on.
		_pass_frames += 1
		var s0: Vector2 = _soak_route[0]
		if _pass_frames == 1:
			# Facing along the route, so the camera has turned there before the numbers count.
			var d: Vector2 = _soak_route[1] - s0
			var yaw := atan2(-d.x, -d.y)
			car.rotation.y = yaw
			if flying:
				var alt := _start_alt if _start_alt > 0.0 else Heli.CRUISE
				heli.place(Vector3(s0.x, map.ground_height(s0.x, s0.y) + alt, s0.y), yaw, alt)
			else:
				car.collision_mask = 0
				car.global_position = Vector3(s0.x, map.drive_height(s0.x, s0.y, 0.0), s0.y)
				car.reset_physics_interpolation()
			_cut_camera()
			if flying:
				cam_focus = heli.global_position
			_soak_leg = 1
		elif _pass_frames >= 180 and (streamer.idle() or _pass_frames >= 1200):
			streamer.finish_view(cam_focus, cam)
			streamer.reset_stats()
			_soak_t = 0.0
			_pass_frames = -1
		return
	if _pass_kind == "car":
		base_size = FollowCamera.DEFAULT_SIZE * (1.0 + FollowCamera.SPEED_ZOOM)  # the view at top speed
	elif _pass_kind == "heli":
		base_size = FollowCamera.DEFAULT_SIZE
		heli.alt_target = Heli.MAX_HEIGHT
	elif _pass_kind != "":
		base_size = FollowCamera.DEFAULT_SIZE  # the helicopter keeps its height (it climbs over a tower)
	else:
		base_size = FollowCamera.DEFAULT_SIZE if int(_soak_t / 20.0) % 2 == 0 else 220.0
		if not flying and _soak_t > _soak_minutes * 40.0:
			_take_off(Heli.CRUISE)
	if _pass_kind in ["look", "jump"]:
		_pass_event()
		return
	if _pass_kind != "" and _soak_leg >= _soak_route.size():
		return
	if _pass_kind == "switch" and not flying and _soak_leg >= 2:
		_take_off(Heli.CRUISE)  # the loading fix: the car's first leg done, the helicopter flies on
	var target: Vector2 = _soak_route[_soak_leg % _soak_route.size()]
	var pos := _vehicle_position()
	var to := Vector2(target.x - pos.x, target.y - pos.z)
	if to.length() < 25.0:
		_soak_leg += 1
		if _pass_kind != "":
			print("stream pass: leg %d done at frame %d (%.0f s)" % [_soak_leg - 1, frame, _soak_t])
		return
	if flying:
		heli.input_dir = Vector3(to.x, 0.0, to.y).normalized()
		heli.climb = 1.0 if heli.blocked else 0.0
		return
	var step := to.normalized() * (PASS_CAR_SPEED if _pass_kind in ["car", "switch"] else 22.0) * dt
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.global_position = Vector3(pos.x + step.x, map.drive_height(pos.x + step.x, pos.z + step.y, pos.y), pos.z + step.y)
	car.rotation.y = atan2(-to.x, -to.y)


## The loading fix: a look at a new target (camera_shots.gd) is about to show the target and the
## way there: the streamer loads the target's sectors (its view, as it could turn) and the halfway
## view's next, while the camera is still on its way.
## The look waits for them, at most LOOK_WAIT_MS (the camera stays on the vehicle meanwhile): a
## target 2-3 km off needs 5-8 sectors, ~1.2 s of loading on the iPhone 11. [from, to, since (ms)];
## empty: none waiting.
const LOOK_WAIT_MS := 1500
## The look's own length once it starts (camera_shots.gd's legs, and half a second to spare), and
## the most between two views of its way the streamer loads for (the west-sectors fix).
const LOOK_TIME := CameraShots.OUT_TIME + CameraShots.HOLD_TIME + CameraShots.BACK_TIME + 0.5
const LOOK_STEP := 60.0
var _look_queued: Array = []


func _queue_look(from: Vector3, to: Vector3) -> void:
	if streamer == null:
		var screen := get_viewport().get_visible_rect().size
		moments.look_at_target(from, to, cam_yaw, camera_pitch, _view_size, screen.x / maxf(screen.y, 1.0))
		return
	var time := LOOK_WAIT_MS / 1000.0 + LOOK_TIME
	# The west-sectors fix (2026-11-01): the sectors each view of the look will show (its frustum,
	# towers and all), not a square round the target: the target's view first, then the way there
	# (the views between the car's, MID's and the target's, at most LOOK_STEP m apart).
	var screen := get_viewport().get_visible_rect().size
	var aspect := screen.x / maxf(screen.y, 1.0)
	var kf := CameraShots.look_keys(from, to, cam_yaw, camera_pitch, _view_size, aspect)
	var way: Array = []
	for i in kf.size() - 1:
		var a: Array = kf[i]
		var c: Array = kf[i + 1]
		var n := clampi(ceili((a[0] as Vector3).distance_to(c[0]) / LOOK_STEP), 1, 40)
		for j in n + 1:
			var t := float(j) / float(n)
			way.append([(a[0] as Vector3).lerp(c[0], t), lerpf(a[1], c[1], t)])
	streamer.expect_shot([kf[-1]], cam_yaw, camera_pitch, aspect, time)
	streamer.expect_shot(way, cam_yaw, camera_pitch, aspect, time, 1)
	_look_queued = [from, to, Time.get_ticks_msec()]


## Each frame: a queued look starts once its sectors are in (or the wait is over); a finger on the
## stick or the pedals meanwhile cancels it, as it would have kept the camera on the car.
func _look_frame() -> void:
	if _look_queued.is_empty():
		return
	var waited := Time.get_ticks_msec() - int(_look_queued[2])
	if _pass_kind == "" and (hud.stick_active() or controls.held or hud.gas or hud.brake or _heli_held):
		_look_queued = []
		return
	if not streamer.expected_in(1) and waited < LOOK_WAIT_MS:
		return
	var screen := get_viewport().get_visible_rect().size
	moments.look_at_target(_look_queued[0], _look_queued[1], cam_yaw, camera_pitch, _view_size, screen.x / maxf(screen.y, 1.0))
	streamer.hold_expected(LOOK_TIME)  # the west-sectors fix: kept for the whole look, however long the wait
	print("camera: the look waited %d ms for its %d sectors%s" % [waited, streamer.expected_keys(1).size(),
			"" if streamer.expected_in(1) else " (not all in)"])
	_look_queued = []


## The loading fix: the frames with a proxy in the view since the last look or jump (printed at
## each: the one before's share).
var _pass_missing := 0


func _pass_tally() -> String:
	var n := streamer.missing_frames - _pass_missing
	_pass_missing = streamer.missing_frames
	return "%d frames with a proxy in the view since the last" % n


## The loading fix, --stream-pass=look|jump: every PASS_EVENT_S (from the pass's start) the next
## route point: a look at it (camera_shots.gd, as a new target gets; the helicopter hovers), or the
## car put there (as a tow does: no view finished first). The car stays where it was put.
func _pass_event() -> void:
	var due := int(_soak_t / PASS_EVENT_S) + 1
	if flying:
		heli.input_dir = Vector3.ZERO
		heli.climb = 0.0
	if _pass_kind == "jump":
		var at: Vector2 = _soak_route[mini(_soak_leg - 1, _soak_route.size() - 1)]
		if _soak_leg < due and _soak_leg < _soak_route.size():
			at = _soak_route[_soak_leg]
			_soak_leg += 1
			car.global_position = Vector3(at.x, map.drive_height(at.x, at.y, 0.0), at.y)
			car.reset_physics_interpolation()
			_cut_camera()
			print("stream pass: jump to %.0f, %.0f at frame %d (%s)" % [at.x, at.y, frame, _pass_tally()])
		car.collision_mask = 0
		car.vel = Vector3.ZERO
		car.forward_speed = 0.0
		car.global_position = Vector3(at.x, map.drive_height(at.x, at.y, 0.0), at.y)
		return
	if _soak_leg < due and _soak_leg < _soak_route.size() and not moments.playing() and _look_queued.is_empty():
		var t: Vector2 = _soak_route[_soak_leg]
		_soak_leg += 1
		var p := _vehicle_position()
		_queue_look(Vector3(p.x, map.ground_height(p.x, p.z), p.z), Vector3(t.x, map.ground_height(t.x, t.y), t.y))
		print("stream pass: look at %.0f, %.0f at frame %d (%s)" % [t.x, t.y, frame, _pass_tally()])
