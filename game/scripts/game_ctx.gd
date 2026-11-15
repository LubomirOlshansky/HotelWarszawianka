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
var hud: CanvasLayer
## The talk (dialogue.gd): the call and card lines.
var dialogue: Node
var bubbles: Control
var wallet: Node
var map: Node3D
## The radio (radio.gd): an activity's news and stings.
var radio: Node
## The traffic's lane graph, null with --no-traffic.
var graph: RefCounted
## The traffic, null with --no-traffic.
var traffic: Node3D
var car: CharacterBody3D
## The helicopter (heli.gd).
var heli: Node3D
## [position, km/h, flying, forward speed] of what the player drives now: the helicopter in the
## air, the car on the ground.
var vehicle: Callable
## The hour of the local clock (time_of_day.gd), 0 to 24.
var hour: Callable
## Takes the player up in the helicopter from where the car stands, at cruise height.
var take_off: Callable
## Puts the camera's focus at a point (a test start that moves the player at once).
var focus_at: Callable
