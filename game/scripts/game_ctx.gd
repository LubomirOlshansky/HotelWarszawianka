extends RefCounted
## What an activity of the kit may use from the game (tech-debt TD-4 b,
## docs/design/wiring-out-of-main.md): the services, and one copy each of the small functions
## main.gd once wrote out for every activity it wired by hand.
##
## main.gd fills it (`_build_ctx`) just before each activity installs itself (activity.gd
## `install`), so an activity sees what exists at its place in the build: `traffic` is null with
## --no-traffic, as it was when main.gd read its own field there. It holds no reference to main.gd
## itself. An activity copies what it needs into its own fields in `install` and does not keep the
## ctx. A field joins when the next activity that moves needs it.

## The 3D world the activities put their rings and beacons in.
var world: Node3D
## centrum.json, the city's data (`origin`: the map's [lat, lon] at 0, 0).
var data := {}
## The run's flags (dev_flags.gd): an activity reads its own test flags here. Untyped on purpose:
## dev_flags.gd preloads main.gd, which preloads every activity, so a typed field would load all of
## main.gd with the kit's base (and into every check that builds an activity).
var flags: Variant
## The player's settings (settings.gd): an activity behind an A/B switch of the DEV page reads it
## here (tajny_klient.gd: `tajny`). Untyped for the same reason as `flags`.
var settings: Variant
var hud: CanvasLayer
## The talk (dialogue.gd): the call and card lines.
var dialogue: Node
var bubbles: Control
var wallet: Node
var map: Node3D
## The radio (radio.gd): an activity's news and stings.
var radio: Node
## The city's sounds (city_sounds.gd): an activity's crowds and their beat at its spots. Null when
## the notebook's places did not load.
var city_sounds: Node
## The game's sounds (sfx.gd): road life's siren and horns.
var sfx: Node
## The rescue line (missions.gd): its `places` (the hospitals road life's ambulance drives to).
var missions: Node
## The lane graph (centrum.json's `graph`): there with --no-traffic too (the side jobs ride it).
var graph: RefCounted
## The traffic, null with --no-traffic.
var traffic: Node3D
## The side jobs (jobs.gd), null without a lane graph: their places on the map carry other
## activities' marks too (the free-ride boat's).
var jobs: Node
## The police (police.gd), null with --no-police.
var police: Node
## Łuber (rides.gd), null without a lane graph: the trend job keeps out of its rides.
var rides: Node
## The street racers (rivals.gd), null with --no-traffic: the side jobs ask who is racing.
var rivals: Node
## The weather (weather.gd): Łuber's passengers and its pay read the rain.
var weather: Node
## Everyday life (city_life.gd): the trend slots and their doors. Null with --life=0 or without the
## notebook's places.
var life: Node3D
## The trend queues (crowds.gd): the PISTACJA drop, the padel court and DŻEMINI's line. May be null.
var crowds: Node
## The notebook (notebook.gd): its places (`places`, each with its `id` and its point `at`).
var notes: Node
## The storefronts (storefronts.gd): their parking zones are the round-up's depots and their Leżaks
## what it rounds up. Null with --no-parodies or without the notebook's places.
var storefronts: Node
var car: CharacterBody3D
## The helicopter (heli.gd).
var heli: Node3D
## The time of day (time_of_day.gd): `local_clock()` is the local hour and weekday.
var tod: Node
## The ground's material (map_builder.gd's flat ground): the skids' and the night meet's tyre marks.
var ground_mat: Material
## [position, km/h, flying, forward speed] of what the player drives now: the helicopter in the
## air, the car on the ground.
var vehicle: Callable
## The hour of the local clock (time_of_day.gd), 0 to 24.
var hour: Callable
## The hour of the city's life (city_life.gd `hour_now`; 12.0 when there is none, as with
## --no-traffic).
var life_hour: Callable
## (Vector3) -> bool: the point is on screen (the camera's frustum).
var seen: Callable
## Takes the player up in the helicopter from where the car stands, at cruise height.
var take_off: Callable
## The camera's focus now (main.gd's `cam_focus`): the point the view follows, where an activity
## draws what is near the player.
var focus: Callable
## Puts the camera's focus at a point (a test start that moves the player at once).
var focus_at: Callable
## The clock to 22:00 at once, as CZEKAM DO 21:00 does it (main.gd's story skip): the street
## racers' sixth win offers the night (NOC).
var night_now: Callable
## (bool) -> void: the city's 3D drawn or not (main.gd `set_city_drawn`): off while a full-screen
## pixel game covers it (padel, the pub's beer pong), so the frame is the 2D canvas alone.
var city_drawn: Callable
