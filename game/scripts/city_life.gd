extends Node3D
## Loop MW-4 (docs/design/vision.md 3.4, 3.7, 4.7 and section 5's MW-4 row): everyday life and
## trends.
##  - **Dog walkers** (06:30-09:00, 19:00-22:30; twice as many round Plac Zbawiciela and in
##    Powiśle): a walker (a pedestrian guest) on a footway with a dog on the lead ahead, three
##    dogs (long and low, squat and flat-faced, big and fluffy); the dog stops at the trees by the
##    footway for 3-6 s while the walker waits. A horn within 15 m (the player has none yet: the AI
##    cars' horns, traffic.gd's held-up and bumped drivers) makes the dog bark (three sizes) and
##    the walker say a `dog_walkers` `horn` line, at most once a minute. The influencer dog at Plac
##    Zbawiciela with three photographers (E27), the ball on the Kopernik roof (E16).
##  - **Cyclists** on the cycle paths (06:00-22:00, more at the rush hours): commuters, Rowerilo's
##    cream bikes with a grey basket, cargo bikes with a child; a row of parked Rowerilo bikes at
##    the dock (`rowerilo_dock`). A car parked on a cycle path for 3 s gets a bell and a `cyclists`
##    `lane` line (once per 45 s). A Rowerilo rider followed 400 m: E28.
##  - **Runners**: singles on the boulevards and in the parks (06-08, 18-21); KOLKA on Wednesdays
##    at 19:00 from Centrum Nauki Kopernik to Most Poniatowskiego and back (12-20 in pale yellow,
##    mint and white, a footway A* route); the Zając (the car beside the club, 9-14 km/h, 600 m:
##    the `runners` `zajac` cheer, E29's +40 respect once).
##  - **Hyrax** on Saturdays 09-17 on the stadium's forecourt: a cordon of barriers, a loop of
##    runners, a HYRAX banner, E30 (a lap); Podwózka's `hurry` riders go there that morning.
##  - **The Wiralek trend cycle**: three slots (Plac Zbawiciela, Chmielna, Tamka), a trend each
##    for 7 days and a WKRÓTCE day (`slot_state`); the queue (crowds.gd's `trend` sites) by the day;
##    a fascia per slot in the pixel font; E18, E19. Fat Thursday at Lukrownia (Live or --date):
##    a queue of 60 from 06:00 to 18:00 (E20 is egg_book's `pass` with the `lukrownia` crowd).
## Drawing: the walkers, runners, Kolka, the Hyrax loop and the photographers are pedestrians.gd's
## guests (+0 draw calls); the dogs, the cordon's barriers and the ball one city MultiMesh of a
## four-shape family (+1 in view); the riders and the parked bikes one more (+1: there is no
## rider MultiMesh to share yet); loop MW-2's Pędzik couriers (parodies.md 4: 4 by day, 6 at
## night, on the cycle paths and the footways, magenta, the square backpack) one more of their own
## (+1 in view: not in the bike family's four); loop couriers (parodies.md 4.2): 3 more by day, 5 at
## night ride the roads' kerb edge (the lane graph's outer lane, KERB_IN in from the kerb), 1 or 2
## couriers wait by each kebab stand near the view at night (the rider mesh's standing shape, their
## bikes parked beside them; courier_race.gd's challenger is one of them), and within 4 m of the car's
## path a rider swerves onto the footway or, with no room, hops; all in the same MultiMesh (+0); the fascias and the banner a
## mesh each, near them. No sun shadow. The logic ticks at 2 Hz; the movers step at 15 Hz
## (walkers, runners and far riders at 7.5 Hz) only while something is near the view; far from
## all of it nothing but the tick runs. The rules are static functions (check_city_life.gd runs them on synthetic clocks and dates).

const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const Crowds := preload("res://scripts/crowds.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Pedestrians := preload("res://scripts/pedestrians.gd")
const Props := preload("res://scripts/props.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")

## Seconds between two ticks of the logic, and between two moves of the movers.
const TICK := 0.5
const MOVE_TICK := 1.0 / 15.0
## Walkers and runners, and riders further than this from the view, step at half the rate
## unless within FAR_CAR of the car (15 m: at 50 km/h the car is 8 steps away; the steps
## between keep clear of where it will be).
const FAR_MOVE := 60.0
const FAR_CAR := 15.0
## A mover off screen at the last tick steps every OFF_EVERY-th step (3.75 Hz), the time saved
## up; within FAR_CAR of the car it steps every time.
const OFF_EVERY := 4
## Metres around the view's ground rectangle that still count as on screen (a mover walking in
## is at the full rate before it shows).
const VIS_MARGIN := 8.0
## The movers' kinds as ints for the step (`kd`; `kind` stays the word).
const DOG_K := 0
const RIDER_K := 1
const RUNNER_K := 2
## Loop MW-2: a Pędzik courier (a rider in its own MultiMesh).
const PEDZIK_K := 3
## Movers live within NEAR_R m of the view's focus; they start SPAWN_R m from it.
const NEAR_R := 200.0
const SPAWN_R := Vector2(25.0, 150.0)
## The footway and cycle path grid, the trees' grid (m).
const CELL := 64.0
const TREE_CELL := 32.0
## The car: no mover within CLEAR m of its middle (pushed aside), its footprint for the soak.
const CLEAR := 3.0
const CAR_HALF := Vector2(0.9, 2.0)
const BODY_R := 0.3

## Dogs (vision 3.7): the pool, the walkers by the view, twice in the zones.
const DOGS_MAX := 16
const DOG_BASE := 5
const DOG_ZONE := 2.0
const ZONE_R := 450.0
## F's ask (2026-11-01, docs/design/packs.md): a lunchtime walk too (12:30-14:30), so the Day
## look's afternoon has its walkers.
const DOG_HOURS := [[6.5, 9.0], [12.5, 14.5], [19.0, 22.5]]
const TREE_NEAR := 3.5
const TREE_WAIT := Vector2(3.0, 6.0)
const HORN_R := 15.0
## A walker's horn line at most once per LINE_GAP s; a dog barks at most every BARK_GAP s.
const LINE_GAP := 60.0
const BARK_GAP := 2.0
const LEAD := 1.6
## The walkers' dogs drawn a little bigger than life, to read at 80 m on the phone *guess*.
const DOG_SCALE := 1.35
const BARKS := ["bark_small", "bark_mid", "bark_big"]
const COATS := ["#7a4a2a", "#c9a46b", "#2b2622", "#e8e2d4", "#a0522d", "#d9c7a0", "#5b4636", "#f2efe8"]
## F's ask (2026-11-01, docs/design/packs.md): a share of the walkers are big guys (broader and
## taller, in a dark tracksuit) with a tiny dog (the fluffy shape at TINY_DOG of the walkers' dogs,
## pale coats); a slow car near one gets his `tiny` line, at most once per TINY_GAP s.
const BIG_SHARE := 0.35
const BIG_SCALE := Vector3(1.32, 1.1, 1.25)
const TINY_DOG := 0.42
const BIG_SHIRTS := ["#1c2230", "#2b2c2f", "#25272d", "#3a3b3f", "#1f2a44"]
const TINY_COATS := ["#f7f5ef", "#efe6cf", "#e8d3c0", "#f4e4ea"]
const TINY_NEAR := 12.0
const TINY_KMH := 15.0
const TINY_GAP := 40.0
## The family's shapes: three dogs, the cordon's barrier.
enum { LONG, SQUAT, FLUFFY, BARRIER }

## Cyclists (vision 3.7).
const RIDERS_MAX := 12
## Loop MW-2 (parodies.md 4.2): Pędzik couriers round the view, by day and at night (× 1.5), the
## pool, their speed (m/s), the near miss (m) and its bubble's gap (s); half ride the footways.
const PEDZIK_DAY := 4
const PEDZIK_NIGHT := 6
const PEDZIK_CAP := 16
const PEDZIK_V := Vector2(5.0, 7.0)
const PEDZIK_MISS := 4.0
const PEDZIK_GAP := 30.0
const PEDZIK_FOOT := 0.5
## Loop couriers (parodies.md 4.2): the kerb riders, on top of the path riders above: 3 round the
## view by day, 5 at night (× 1.5, rounded), on the outer lane's kerb edge of the lane graph's roads.
const KERB_DAY := 3
const KERB_NIGHT := 5
## A kerb rider's middle this far in from the kerb (m; parodies.md says 0.6 m: at 0.45 his bike's
## inner edge is 0.7 m out, clear of a car on a 3 m lane), and the lanes he rides: at least KERB_LW
## wide, no living street (class 3), no tunnel.
const KERB_IN := 0.45
const KERB_LW := 2.9
## A road with a cycle path this close to its kerb line (m) is no kerb rider's road: the bikes use the path.
const CYCLE_BESIDE := 14.0
## The dodge (parodies.md 4.2): a Pędzik rider whose closest approach to the car over the next
## DODGE_T s is within PEDZIK_MISS swerves SWERVE_OUT m past the kerb onto the footway (SWERVE_RATE
## m/s sideways), or hops (a HOP_T s cartoon jump, HOP_H m up) where there is no room; back to his
## line CALM_T s after the car is clear.
const DODGE_T := 1.0
const SWERVE_OUT := 1.4
const SWERVE_RATE := 3.0
const CALM_T := 1.0
const HOP_T := 0.3
const HOP_H := 0.55
const DODGE_NONE := 0
const DODGE_SWERVE := 1
const DODGE_HOP := 2
## Loop couriers (parodies.md 4.2): 1 or 2 couriers waiting by each kebab stand at night (21-06),
## standing beside their parked bikes (props.gd PEDZIK_STANDING) at the first WAIT_MAX free spots
## of WAIT_SPOTS (the kiosk's own x along the road, z towards it; m).
const WAIT_MAX := 2
const WAIT_SPOTS := [Vector2(2.75, -0.35), Vector2(-2.75, -0.35), Vector2(3.9, -0.6), Vector2(-3.9, -0.6)]
const RIDER_BASE := 4
## F's ask (2026-11-01): the Vistula boulevards (Crowds.BULWARY) full of fast cyclists: with the view
## within Crowds.BULWARY_R of a spot there, twice the riders (at most BLVD_RIDERS_MAX), and
## BLVD_FAST of them ride the boulevard hard (BLVD_V m/s, 30-41 km/h; the others 4-6 as ever).
const BLVD_RIDERS_MAX := 16
const BLVD_FAST := 0.45
const BLVD_V := Vector2(8.5, 11.5)
const RIDE_HOURS := [6.0, 22.0]
const RUSH := [[7.0, 9.5], [16.0, 19.0]]
## The bike family's shapes: a commuter, a Rowerilo bike, a cargo bike (each ridden), a parked
## Rowerilo bike.
enum { COMMUTER, ROWERILO, CARGO, PARKED }
const BELL_NEAR := 2.0
const BELL_HOLD := 3.0
const BELL_GAP := 45.0
const FOLLOW_M := 400.0
const FOLLOW_R := 25.0
const FOLLOW_KMH := 8.0
const DOCK_N := Vector2i(6, 10)
const SHIRTS := ["#d8432f", "#2f6fb5", "#e0b23a", "#3b8f5a", "#f2efe8", "#7a4fa8", "#e57aa0", "#2b2c2f", "#5aa9c9", "#9c2f3a"]

## Runners (vision 3.7).
const RUN_HOURS := [[6.0, 8.0], [18.0, 21.0]]
const RUN_MAX := 6
const RUN_ZONE_R := 300.0
const KOLKA_DAY := 3
const KOLKA_GATHER := 18.75
const KOLKA_START := 19.0
const KOLKA_END := 19.75
const KOLKA_V := 3.0
const KOLKA_N := Vector2i(12, 20)
## Kolka's start: the route's last point this near the place (the A*'s detours cut off).
const KOLKA_REACH := 500.0
## Loop jobs-2 (vision 3.7, egg E34): the man carrying a 1960s armchair down Mokotowska, one day in
## three (`armchair_day`, by the cycle's day) in the shops' hours: a guest walking the footways
## between two points of the street ARMCHAIR_HALF m each way of the place, there and back, the chair
## upside down on his head (one small mesh, +1 draw call near him). The car within ARMCHAIR_EGG m: E34.
const ARMCHAIR_PLACE := "mokotowska"
const ARMCHAIR_STREET := "Mokotowska"
const ARMCHAIR_HALF := 200.0
const ARMCHAIR_V := 0.9
const ARMCHAIR_EGG := 8.0
const ARMCHAIR_EVERY := 3
## His bit in `_shown` (out and near the view), clear of the docks' bits from 5 up.
const ARM_BIT := 1 << 30
const ARM_SHIRT := Color("#c96b2c")
## Pale yellow, mint, white (never the jobs' orange).
const KOLKA_TOPS := ["#fff3a6", "#b8f0d8", "#f7f7f2", "#fff8c9", "#c9f5e6", "#eef9b0"]
const ZAJAC_LAT := 25.0
const ZAJAC_KMH := Vector2(9.0, 14.0)
const ZAJAC_M := 600.0
const ZAJAC_GRACE := 2.0

## Hyrax (vision 3.7): Saturdays 09:00-17:00 *guess*.
const HYRAX_DAY := 6
const HYRAX_HOURS := [9.0, 17.0]
const CORDON_R := 26.0
const CORDON_N := 24
const HYRAX_RUNNERS := 14
const HYRAX_LOOP_R := 20.0
const HYRAX_V := 3.2
## Podwózka's hurry riders go to the stadium that morning *guess*.
const HURRY_HOURS := [7.0, 10.0]

## The Wiralek slots (vision 3.4): places.json ids, each one's offset in days, the cycle (7 trend
## days and the WKRÓTCE day), every SYNC_EVERY-th cycle the three start together (E19's rare
## overlap: ~1 in 13 weeks), the queue by the trend's day, the shop's hours *guess*.
const SLOTS := ["wiralek_zbawiciela", "wiralek_chmielna", "wiralek_tamka"]
const SLOT_OFFSET := [0, 2, 4]
const CYCLE := 8
const SYNC_EVERY := 12
const QUEUE_BY_DAY := [30, 20, 20, 8, 8, 2, 2, 0]
const SHOP_HOURS := [8.0, 20.0]
## Day 0 of the cycle (a Monday).
const EPOCH := {"year": 2026, "month": 1, "day": 5, "hour": 12}
## Without Live a trend moves on every fourth session, seen on its days 1, 4, 6 and 8.
const SESSION_DAYS := [0, 3, 5, 7]
## The trends: the sign's word (generic product words only), the English gloss.
const TRENDS := [["KWADRATOWY ROGAL", "the square croissant"], ["CZEKOLADA Z PUSTYNI", "desert chocolate"],
		["TRUSKAWKI W KUBKU", "strawberries in a cup"], ["MATCHA WSZYSTKO", "matcha everything"],
		["PĄCZEK 2.0", "the doughnut 2.0"], ["HERBATA Z KULKAMI", "bubble tea"], ["CIASTKO XXL", "the giant cookie"],
		["RÓŻOWA ŚCIANA", "the pink wall"]]
const LUKROWNIA := "lukrownia"
const FAT_HOURS := [6.0, 18.0]
const FAT_QUEUE := 60
## A slot counts as seen (E18, E19) with the car within SEEN_R m.
const SEEN_R := 70.0
const FASCIA_R := 320.0
const FASCIA_PX := 0.05

## The influencer dog at Plac Zbawiciela and the dog under the Kopernik roof *guess*.
const INFLUENCER_HOURS := [7.0, 21.0]
const APORT_HOURS := [7.0, 21.0]
const BALL_GRAB := 4.0
const BALL_DROP := 8.0
const BUBBLE := Color("#ffd23f")
const MINUTE := 60.0

## Refs, set by main.gd before setup.
## A dog walker, rider or runner. A typed object rather than a Dictionary (loop MW-4's cost cut:
## its fields are read and written at 15 Hz); `m["p2"]` still reads a field where speed doesn't
## matter (the logs, the check).
class Mover:
	var kind := ""
	## DOG_K, RIDER_K or RUNNER_K (`kind` as an int).
	var kd := 0
	## Time saved up by the steps it skipped.
	var acc := 0.0
	## On screen at the last tick.
	var vis := true
	## "foot" or "cyc", and the path's index in it.
	var pset := "foot"
	var i := 0
	var s := 0.0
	var dir := 1.0
	var wait := 0.0
	var shove := Vector2.ZERO
	var dshove := Vector2.ZERO
	var p2 := Vector2.ZERO
	var p3 := Vector3.ZERO
	var d2 := Vector2.ZERO
	var d3 := Vector3.ZERO
	var yaw := 0.0
	var follow := 0.0
	var near := false
	var v := 1.0
	var off := 0.0
	var shape := 0
	var coat := Color.WHITE
	var shirt := Color.WHITE
	var tr := 0.0
	## F's ask: a big guy with a tiny dog (dog_scales).
	var big := false
	var stops := PackedFloat32Array()
	var bark_t := 0.0
	## The path's points, running lengths and heights (`cached` false: read again), and the
	## segment the last step was on.
	var cached := false
	var pts := PackedVector2Array()
	var cum := PackedFloat32Array()
	var h := PackedFloat32Array()
	var k := 0
	## The path's length (cum's last).
	var length := 0.0
	## The last placing's segment (cum from ca to cb), its way per metre (udir, dy), and whether
	## a step inside it may just slide along (its shoves unchanged, a dog not at a tree).
	var fast := false
	var ca := 0.0
	var cb := 0.0
	var udir := Vector2.ZERO
	var dy := 0.0
	## Loop couriers: a kerb rider's lane graph edge (-1: a path rider), his dodge (DODGE_*), the
	## hop's time left, the time the car has been clear, and the side offset he steers to.
	var ke := -1
	var dodge := 0
	var hop := 0.0
	var calm := 0.0
	var want_off := 0.0


var map: Node3D
var dialogue: Node
var sfx: Node
## pedestrians.gd (the guests).
var walkers: Node3D
var egg_book: Node
var wallet: Node
var hud: CanvasLayer
## The player's car (the --zajac and --life-soak rigs move it).
var car: Node3D
## traffic.gd (its view's ground rectangle: view_centre, view_right, view_ahead, view_half), for who
## is on screen; null without traffic.
var view: Node
## The view's focus, -> Vector3.
var focus: Callable
## The game clock, -> {hour, weekday}.
var clock: Callable
## crowds.gd's calendar, -> {live, month, date (yyyymmdd or 0), look, rain}.
var calendar: Callable
## The vehicle, -> [position, km/h, flying, yaw, height over the ground].
var vehicle: Callable
## traffic.gd on_screen (p, height) -> bool; unset: always.
var on_screen: Callable
## The eggs' state (main.gd _egg_state), for egg_book.fire.
var probe: Callable
## --life=: 0 none (this node isn't built), 1 normal, 2 double; the Low tier halves it.
var amount := 1.0
## Loop MW-2: the Pędzik couriers (main.gd's --no-parodies turns them off).
var pedzik_on := true
## Loop couriers: the traffic's lane graph (the kerb riders ride its outer lanes; null: none) and the
## kebab stands' kiosks (jobs.gd stand_frames: [at, yaw] each; the couriers waiting there at night).
var graph: LaneGraph
var stands: Array = []
## Loop couriers: --pedzik-log (`pedzik:` lines: the minute's riders, the dodges, the waiting couriers).
var pedzik_log := false
## Loop couriers: --pedzik-kerb (a testing aid for shots): the kerb riders start 8-35 m from the view.
var kerb_close := false
## Loop couriers: dodges so far (the check, the log).
var pedzik_swerves := 0
var pedzik_hops := 0
## --dogs-log, --trend-log, --life-log (the riders, runners, Kolka, Hyrax, the soak).
var dogs_log := false
var trend_log := false
var life_log := false
## --life-soak: the car driven at the dogs and riders; every frame counts overlaps.
var soak := false
## --zajac with --autopilot: the car paces Kolka.
var zajac_rig := false
## Loop jobs-2: --armchair: the armchair man out today, at any hour.
var armchair_flag := false
## The map's roads (the armchair man's street), set before setup.
var roads: Array = []
## Loop jobs-2: times the car passed the armchair man (the check, the log).
var met_armchair := 0
## --trend-day=N: the trend cycle's day number (days since EPOCH), instead of the date.
var trend_day_flag := -1
## Sessions played (the save's `life_sessions`), for the trend cycle without Live.
var session := 0
## Time spent in this script since the bench last read it (µs).
var spent_usec := 0
## The levels for the eggs (egg_book.gd `crowd`): influencer, hyrax, kolka, dogs, riders.
var levels := {}
## Counters (the logs, the check).
var barks := 0
var horn_lines := 0
## F's ask: the big guys' `tiny` lines said.
var tiny_lines := 0
var bells := 0
var zajac_cheers := 0
var zajac_paid := 0
var overlaps := 0
var closest := INF
var met_dogs := 0
var met_riders := 0
## Loop MW-2: Pędzik couriers met (within 10 m) and their near-miss bubbles.
var met_pedzik := 0
var pedzik_lines := 0
## The slots' state now: {day, trend, cycle, queue, word} each (slot_state).
var slots_now: Array[Dictionary] = []
## The slots' doors and their facade's outward side (from crowds.gd's sites), Vector2 each.
var slot_doors: Array[Vector2] = []
var slot_out: Array[Vector2] = []
var fat_thursday := false
var t := 0.0

var _rng := RandomNumberGenerator.new()
var _at := {}
var _tags := {}
var _index_task := -1
var _index_out: Array = []
var _ready := false
var _foot: Array[PackedVector2Array] = []
var _foot_dk := PackedInt32Array()
var _cyc: Array[PackedVector2Array] = []
var _cyc_dk := PackedInt32Array()
var _cyc_w := PackedFloat32Array()
var _foot_grid := {}
var _cyc_grid := {}
var _tree_grid := {}
## Path ends: Vector2i(round x, round z) -> PackedInt32Array of (path * 2 + end), per set.
var _foot_ends := {}
var _cyc_ends := {}
var _cum := {}
var _heights := {}
## Tree stops by path (key as _cum).
var _stops := {}
var _dogs: Array[Mover] = []
var _riders: Array[Mover] = []
## The view is on the Vistula boulevards (Crowds.BULWARY): more and faster riders.
var _on_blvd := false
var _pedziks: Array[Mover] = []
## Loop couriers: the kerb riders (Pędzik too: their slots in the Pedzik MultiMesh follow _pedziks').
var _kerbers: Array[Mover] = []
## Road edge -> a cycle path runs beside it (_cycle_path_beside).
var _beside_cache := {}
## Loop couriers: the couriers waiting at the stands near the view ([stand, at, yaw] each, after the
## riders in the Pedzik MultiMesh), its signature (a change writes everything), each stand's free
## spots (worked out once), and the couriers the race took from a stand (back when it leaves the band).
var _waiting: Array = []
var _wait_sig := 0
var _wait_spots := {}
var _taken := {}
## Loop couriers: the car's velocity on the ground and its speed (km/h), read once a step.
var _car_v := Vector2.ZERO
var _car_kmh := 0.0
var _runners: Array[Mover] = []
var _docks: Array[Dictionary] = []
var _zones: Array[Vector2] = []
var _run_zones: Array[Vector2] = []
var _kolka := {}
var _hyrax := {}
var _infl := {}
var _aport := {}
var _tick_t := 0.0
var _move_t := 0.0
var _log_t := 0.0
var _line_t := -LINE_GAP
var _bell_t := -BELL_GAP
var _bell_hold := 0.0
var _zajac_m := 0.0
var _zajac_off := 0.0
var _zajac_last := Vector3.INF
var _seen_e18 := {}
var _guests_used := 0
var _dog_mm: MultiMesh
var _dog_mmi: MultiMeshInstance3D
var _dog_buf := PackedFloat32Array()
var _bike_mm: MultiMesh
var _bike_mmi: MultiMeshInstance3D
var _ped_mm: MultiMesh
var _ped_mmi: MultiMeshInstance3D
var _ped_buf := PackedFloat32Array()
var _ped_box := AABB()
var _peds_moved := false
var _pedzik_t := -INF
var _bike_buf := PackedFloat32Array()
var _fascias: Array[MeshInstance3D] = []
var _fascia_key: Array[String] = []
var _banner: MeshInstance3D
var _active := false
var _soak_t := 0.0
var _soak_target := Vector2.INF
var _soak_zone := 0
var _shutter_t := 0.0
var _hour := 12.0
var _weekday := 5
var _days := 0
var _cafe_t := 0.0
var _dn := 0
var _dbox := AABB()
var _move_n := 0
## How far Kolka's start is from the place (the A*'s detour cut off, m).
var _kolka_skip := 0.0
## Loop jobs-2: the armchair man's way {pts, h, cum, len} ({} until the index is built, or none),
## his guest slot in the step, the chair's mesh, whether he is out.
var _arm := {}
var _arm_ends: Array = []
var _arm_slot := -1
var _chair: MeshInstance3D
var _arm_on := false
## The date as the last tick read it (Kolka's members at 15 Hz without the calendar call).
var _date := 0
var _date_live := false
var _date_fat := false
## The day slots_now was made for.
var _slots_days := -999999
## The step's guest figures, packed (written to pedestrians.gd in one call).
var _g_pos := PackedVector3Array()
var _g_yaw := PackedFloat32Array()
var _g_shirt := PackedColorArray()
var _g_tr := PackedFloat32Array()
var _g_sc := PackedVector3Array()
var _tiny_t := -TINY_GAP
var _g_n := 0
## The docks in view (a bit each) whose parked bikes sit at the bike buffer's start; -1 unset.
var _dock_key := -1
var _dock_n := 0
var _dock_box := AABB()
var _bike_box := AABB()
## Between ticks a step writes only what moved (the stepped movers, Kolka's runners, the Hyrax
## loop, a carried ball); a tick, a change of what is shown, or more figures than GUESTS write
## everything (`_full`). The slots and the flags of the last full write:
var _full := true
var _shown := 0
## What the last tick saw shown (_shown_bits); _shown is what the last full write wrote.
var _shown_now := 0
## Instances the steps wrote since the last send.
var _dogs_moved := false
## The step's radius around the car (squared) inside which a mover is cleared of it.
var _reach2 := 0.0
var _bikes_moved := false
var _ball_slot := -1
var _bbox := AABB()
var _bikes_n := 0
var _kolka_slot := -1
var _hyrax_slot := -1
## Kolka's members as last written (each at 7.5 Hz, as the runners: half of them a step).
## The guests' instances (pedestrians.gd's layout: a figure at scale 1, its shirt, its trousers in
## the custom slot), handed over whole when any changed (`_gdirty`).
var _gbuf := PackedFloat32Array()
var _gdirty := false
var _kf_pos := PackedVector3Array()
var _kf_yaw := PackedFloat32Array()
## Kolka's members packed (made with them) and its route's arrays.
var _km_back := PackedFloat32Array()
var _km_lat := PackedFloat32Array()
var _km_a := PackedFloat32Array()
var _km_ring := PackedFloat32Array()
var _km_shirt := PackedColorArray()
var _km_tr := PackedFloat32Array()
var _kp_pts := PackedVector2Array()
var _kp_cum := PackedFloat32Array()
var _kp_h := PackedFloat32Array()
var _kp_len := 0.0

const DOG_CAP := 48
const BIKE_CAP := 24


# --- the rules (static: check_city_life.gd) -------------------------------------------------

## Inside any of the [from, to] windows (hours, may wrap midnight)?
static func in_hours(windows: Array, hour: float) -> bool:
	for w: Array in windows:
		var a := float(w[0])
		var b := float(w[1])
		if (a <= b and hour >= a and hour < b) or (a > b and (hour >= a or hour < b)):
			return true
	return false


## How many dog walkers by the view at `hour` (zone: the view in Powiśle or round Plac
## Zbawiciela), `k` the amount.
## A dog walker's figure and dog scales, [walker, dog]: a big guy's broad frame and tiny dog, or
## the plain walker and the walkers' dog size.
static func dog_scales(big: bool) -> Array:
	if big:
		return [BIG_SCALE, Vector3.ONE * DOG_SCALE * TINY_DOG]
	return [Vector3.ONE, Vector3.ONE * DOG_SCALE]


static func dog_count(hour: float, zone: bool, k := 1.0) -> int:
	if not in_hours(DOG_HOURS, hour):
		return 0
	return mini(roundi(DOG_BASE * (DOG_ZONE if zone else 1.0) * k), roundi(DOGS_MAX * maxf(k, 1.0)))


## A horn at `now`: a bark if the dog last barked BARK_GAP s ago; the walker's line if the last
## line was LINE_GAP s ago. [bark, line].
static func horn_reaction(now: float, last_bark: float, last_line: float) -> Array:
	return [now - last_bark >= BARK_GAP, now - last_line >= LINE_GAP]


## Cyclists by the view at `hour`.
static func rider_count(hour: float, k := 1.0, boulevard := false) -> int:
	if hour < float(RIDE_HOURS[0]) or hour >= float(RIDE_HOURS[1]):
		return 0
	var base := RIDER_BASE * (2 if in_hours(RUSH, hour) else 1) * (2 if boulevard else 1)
	return mini(roundi(base * k), roundi((BLVD_RIDERS_MAX if boulevard else RIDERS_MAX) * maxf(k, 1.0)))


## A rider's kind from a roll 0..1: 55 % commuters, 30 % Rowerilo, 15 % cargo *guess*.
static func rider_kind(roll: float) -> int:
	return COMMUTER if roll < 0.55 else (ROWERILO if roll < 0.85 else CARGO)


## Loop jobs-2: the armchair man's day (1 in ARMCHAIR_EVERY by the cycle's day number, seeded so the
## days don't come in a fixed beat).
static func armchair_day(day: int) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919 + 34
	return rng.randi() % ARMCHAIR_EVERY == 0


## Loop jobs-2: the armchair man's point `t` s into the day's walk on a way `length` m long: there
## and back at ARMCHAIR_V (the distance along the way, and +1 / -1 for the way he faces).
static func armchair_at(t_s: float, length: float) -> Vector2:
	if length <= 0.0:
		return Vector2.ZERO
	var run := fposmod(t_s * ARMCHAIR_V, length * 2.0)
	return Vector2(run, 1.0) if run <= length else Vector2(length * 2.0 - run, -1.0)


## Loop MW-2: Pędzik couriers round the view at `hour` (parodies.md 4.2: × 1.5 at night, 21-06).
static func pedzik_count(hour: float, k := 1.0) -> int:
	var night := hour >= 21.0 or hour < 6.0
	return mini(roundi((PEDZIK_NIGHT if night else PEDZIK_DAY) * k), PEDZIK_CAP)


## Loop couriers: Pędzik's night (parodies.md 4.2: 21-06).
static func pedzik_night(hour: float) -> bool:
	return hour >= 21.0 or hour < 6.0


## Loop couriers: the kerb riders round the view at `hour` (3 by day, 5 at night, × `k`).
static func kerb_count(hour: float, k := 1.0) -> int:
	return mini(roundi((KERB_NIGHT if pedzik_night(hour) else KERB_DAY) * k), PEDZIK_CAP)


## Loop couriers: the couriers waiting by stand `stand` on day `day` at `hour`: 1 or 2 at night
## (seeded by the stand and the day: the same night always has the same), none by day.
static func waiting_count(stand: int, day: int, hour: float) -> int:
	if not pedzik_night(hour):
		return 0
	var rng := RandomNumberGenerator.new()
	# The small hours belong to the night that began the evening before.
	rng.seed = stand * 7741 + (day - int(hour < 12.0)) * 131 + 5
	return 1 + rng.randi() % WAIT_MAX


## Loop couriers: the closest two points moving from `p` at `vp` and from `c` at `vc` (m/s) come
## within the next `horizon` s.
static func closest_approach(p: Vector2, vp: Vector2, c: Vector2, vc: Vector2, horizon: float) -> float:
	var d := p - c
	var w := vp - vc
	var w2 := w.length_squared()
	var at := clampf(-d.dot(w) / w2, 0.0, horizon) if w2 > 0.0001 else 0.0
	return (d + w * at).length()


## Loop couriers: a Pędzik rider's dodge for a closest approach `gap` (m) to the car's path: none
## beyond PEDZIK_MISS, a swerve onto the footway where there is `room`, else a hop.
static func dodge(gap: float, room: bool) -> int:
	if gap > PEDZIK_MISS:
		return DODGE_NONE
	return DODGE_SWERVE if room else DODGE_HOP


## Loop couriers: a near miss says a `pedzik` line when the car does 10 km/h or more and the last
## line was PEDZIK_GAP s ago or more.
static func says_near_miss(now: float, last: float, kmh: float) -> bool:
	return kmh >= 10.0 and now - last >= PEDZIK_GAP


## Loop couriers: the hop's height with `left` s of it to go (a parabola, HOP_H at its top).
static func hop_height(left: float) -> float:
	if left <= 0.0:
		return 0.0
	var x := clampf(1.0 - left / HOP_T, 0.0, 1.0)
	return 4.0 * HOP_H * x * (1.0 - x)


## Loop couriers: a road a kerb rider takes: lanes KERB_LW wide or more, no living street, no tunnel,
## and long enough to ride.
static func kerb_road(lw: float, road_class: int, tunnel: int, length: float) -> bool:
	return lw >= KERB_LW and road_class <= 2 and tunnel < 0 and length > 6.0


static func runner_count(hour: float, near_zone: bool, k := 1.0) -> int:
	if not near_zone or not in_hours(RUN_HOURS, hour):
		return 0
	return roundi(RUN_MAX * k)


## Kolka's phase at `hour` on `weekday`: "" (none), "gather", "run", "stretch".
static func kolka_phase(hour: float, weekday: int) -> String:
	if weekday != KOLKA_DAY or hour < KOLKA_GATHER or hour >= KOLKA_END:
		return ""
	return "gather" if hour < KOLKA_START else "run"


## How far along the out-and-back the leader is at `hour` (m, 0..2L); past 2L: back at the start.
static func kolka_run(hour: float, length: float) -> float:
	return clampf((hour - KOLKA_START) * 3600.0 * KOLKA_V, 0.0, 2.0 * length)


## Kolka's size on a date (12-20, the same all evening).
static func kolka_size(date: int) -> int:
	return KOLKA_N.x + posmod(hash(date * 7919 + 13), KOLKA_N.y - KOLKA_N.x + 1)


## The Zając: one step of pacing, `dt` s, the car `moved` m, `lateral` m from the club at
## `kmh`. mem {m, grace}: true when the 600 m are done (mem starts again).
static func zajac_step(mem: Dictionary, lateral: float, kmh: float, moved: float, dt: float) -> bool:
	if lateral <= ZAJAC_LAT and kmh >= ZAJAC_KMH.x and kmh <= ZAJAC_KMH.y:
		mem["m"] = float(mem.get("m", 0.0)) + moved
		mem["grace"] = 0.0
	else:
		mem["grace"] = float(mem.get("grace", 0.0)) + dt
		if float(mem["grace"]) > ZAJAC_GRACE:
			mem["m"] = 0.0
	if float(mem.get("m", 0.0)) >= ZAJAC_M:
		mem["m"] = 0.0
		return true
	return false


static func hyrax_on(hour: float, weekday: int) -> bool:
	return weekday == HYRAX_DAY and hour >= float(HYRAX_HOURS[0]) and hour < float(HYRAX_HOURS[1])


## Podwózka's hurry riders head to the stadium (Saturday morning).
static func hurry_to_stadium(hour: float, weekday: int) -> bool:
	return weekday == HYRAX_DAY and hour >= float(HURRY_HOURS[0]) and hour < float(HURRY_HOURS[1])


## Days since EPOCH of a date (yyyymmdd).
static func day_number(ymd: int) -> int:
	var t0 := Time.get_unix_time_from_datetime_dict(EPOCH)
	var t1 := Time.get_unix_time_from_datetime_dict({"year": ymd / 10000, "month": (ymd / 100) % 100, "day": ymd % 100, "hour": 12})
	return roundi((t1 - t0) / 86400.0)


## Without Live: the cycle's day number in session `n` (a trend lives four sessions).
static func session_days(n: int) -> int:
	return (n / 4) * CYCLE + int(SESSION_DAYS[n % 4])


## Slot `slot` (0-2) on day number `days`: {day 1..8 (8: WKRÓTCE), trend (index), cycle, queue,
## word (the fascia's), tag (the queue's line: new, queue, gone, "")}.
static func slot_state(days: int, slot: int) -> Dictionary:
	var c := floori(days / float(CYCLE))
	var off := 0 if posmod(c, SYNC_EVERY) == SYNC_EVERY - 1 else int(SLOT_OFFSET[slot])
	var k := days + off
	var day := posmod(k, CYCLE) + 1
	var cyc := floori(k / float(CYCLE))
	var trend := posmod(cyc * 3 + slot, TRENDS.size())
	var word := "WKRÓTCE NOWE MIEJSCE" if day == CYCLE else str(TRENDS[trend][0])
	var tag := "new" if day == 1 else ("queue" if day <= 5 else ("gone" if day < CYCLE else ""))
	return {"day": day, "trend": trend, "cycle": cyc, "queue": int(QUEUE_BY_DAY[day - 1]), "word": word, "tag": tag}


## The queue at a slot now (the shop's hours), `k` the amount.
static func slot_queue(state: Dictionary, hour: float, k := 1.0) -> int:
	if hour < float(SHOP_HOURS[0]) or hour >= float(SHOP_HOURS[1]):
		return 0
	return roundi(int(state["queue"]) * k)


## All three slots on day 1 (E19)?
static func all_new(days: int) -> bool:
	for i in SLOTS.size():
		if int(slot_state(days, i)["day"]) != 1:
			return false
	return true


## Fat Thursday's queue at Lukrownia: Live (or --date) on the day, 06:00-18:00.
static func fat_queue(live: bool, ymd: int, hour: float, k := 1.0) -> int:
	if not live or ymd <= 0 or ymd != EggBook.fat_thursday(ymd / 10000):
		return 0
	if hour < float(FAT_HOURS[0]) or hour >= float(FAT_HOURS[1]):
		return 0
	return roundi(FAT_QUEUE * k)


## E18: slot memory `mem` ({cycle, days}) after seeing the slot on `state`'s day: true when day 1,
## day 4 and the WKRÓTCE day of one trend have been seen.
static func e18_step(mem: Dictionary, state: Dictionary) -> bool:
	if int(mem.get("cycle", -999)) != int(state["cycle"]):
		mem["cycle"] = int(state["cycle"])
		mem["days"] = []
	var d := int(state["day"])
	if d in [1, 4, CYCLE] and not d in (mem["days"] as Array):
		(mem["days"] as Array).append(d)
	return 1 in (mem["days"] as Array) and 4 in (mem["days"] as Array) and CYCLE in (mem["days"] as Array)


## The ball (E16): mem {state: roof, carried, home}, the helicopter `heli` (or INF) and its
## height over the ground; true when the ball is dropped by the dog.
static func aport_step(mem: Dictionary, heli: Vector3, alt: float, ball: Vector3, dog: Vector3) -> bool:
	var st := str(mem.get("state", "roof"))
	if heli == Vector3.INF:
		return false
	if st == "roof" and heli.distance_to(ball) <= BALL_GRAB:
		mem["state"] = "carried"
	elif st == "carried" and Vector2(heli.x - dog.x, heli.z - dog.z).length() <= BALL_DROP and alt < 30.0:
		mem["state"] = "home"
		return true
	return false


## A point inside the car's footprint (`car` the middle, `yaw` its heading), grown by BODY_R?
static func overlaps_car(p: Vector2, car_at: Vector2, yaw: float) -> bool:
	var q := (p - car_at).rotated(yaw)
	return absf(q.x) < CAR_HALF.x + BODY_R and absf(q.y) < CAR_HALF.y + BODY_R


## Where a body at `p` goes to keep CLEAR of the car at `car_at` and of where it will be `ahead`
## of that before the next step (the movers step at 15 Hz, the car every frame): itself if clear.
static func clear_of_car(p: Vector2, car_at: Vector2, ahead := Vector2.ZERO) -> Vector2:
	var c := Geometry2D.get_closest_point_to_segment(p, car_at, car_at + ahead) if ahead != Vector2.ZERO else car_at
	var d := p.distance_to(c)
	if d >= CLEAR:
		return p
	var away := (p - c) / d if d > 0.01 else Vector2.RIGHT
	return c + away * CLEAR


# --- setup -----------------------------------------------------------------------------------

## The places (notebook.gd's, each with `at`), the map data (paths, trees, pois). The footway,
## cycle path and tree grids and Kolka's route are made in a worker thread; nothing moves before.
func setup(places: Array, data: Dictionary, seed_value := 4404) -> void:
	_rng.seed = seed_value
	for p: Dictionary in places:
		if p["at"] != Vector2.INF:
			_at[str(p["id"])] = p["at"]
			_tags[str(p["id"])] = p.get("tags", [])
	# Dog zones: Plac Zbawiciela and the Powiśle places.
	if _at.has("plac_zbawiciela"):
		_zones.append(_at["plac_zbawiciela"])
	for id: String in _at:
		if "powisle" in (_tags[id] as Array):
			_zones.append(_at[id])
		if "runners" in (_tags[id] as Array) or "promenade" in (_tags[id] as Array):
			_run_zones.append(_at[id])
	# F's ask: dog walkers (twice as many) and fast riders on the Vistula boulevards.
	for id: String in Crowds.BULWARY:
		_zones.append(Crowds.BULWARY[id][0])
	for poi: Dictionary in data.get("pois", []):
		if str(poi.get("k", "")) == "park":
			_run_zones.append(Vector2(float(poi["x"]), float(poi["z"])))
	var start: Vector2 = _at.get("kolka_start", Vector2.INF)
	var end: Vector2 = _at.get("most_poniatowskiego", Vector2.INF)
	var paths: Array = (data.get("paths", []) as Array).duplicate()
	var trees: Array = (data.get("trees3d", []) as Array).duplicate()
	# Loop jobs-2: the armchair man's two ends on Mokotowska.
	_arm_ends = armchair_ends(EggBook.street_pieces(data.get("roads", roads), ARMCHAIR_STREET), _at.get(ARMCHAIR_PLACE, Vector2.INF))
	var walk := _arm_ends.duplicate()
	_index_out = [null]
	var out := _index_out
	_index_task = WorkerThreadPool.add_task(func() -> void: out[0] = build_index(paths, trees, start, end, walk), false, "city life index")
	await LoadYield.tick("life zones")
	_build_drawing()
	print("life: %d dog zones, %d runner zones, the index being built (%d paths, %d trees), amount %.2f" % [
			_zones.size(), _run_zones.size(), paths.size(), trees.size() / 6, amount])


## Loop jobs-2: the armchair man's two ends: the street's pieces within ARMCHAIR_HALF m of the place,
## the one farthest from it and the one farthest from that ([] without the street or the place).
static func armchair_ends(pieces: PackedVector2Array, place: Vector2) -> Array:
	if place == Vector2.INF or pieces.is_empty():
		return []
	var a := Vector2.INF
	var ad := -1.0
	for q in pieces:
		var d := q.distance_to(place)
		if d <= ARMCHAIR_HALF and d > ad:
			ad = d
			a = q
	if a == Vector2.INF:
		return []
	var b := a
	var bd := -1.0
	for q in pieces:
		if q.distance_to(place) <= ARMCHAIR_HALF and q.distance_to(a) > bd:
			bd = q.distance_to(a)
			b = q
	if bd < 60.0:
		return []
	return [a, b]


## The index (pure: a worker thread runs it; check_city_life.gd too): footways (`foot`, on the
## ground) and cycle paths (`cycle`, any deck) with their 64 m grids and ends, the trees' 32 m grid,
## Kolka's route from `start` to `end` (A* over the footways in their box; [] without); loop jobs-2:
## the armchair man's way between `walk`'s two points (A* over the footways and crossings round them).
static func build_index(paths: Array, trees: Array, start: Vector2, end: Vector2, walk: Array = []) -> Dictionary:
	var out := {"foot": [], "foot_dk": PackedInt32Array(), "cyc": [], "cyc_dk": PackedInt32Array(), "cyc_w": PackedFloat32Array(),
			"foot_grid": {}, "cyc_grid": {}, "tree_grid": {}, "foot_ends": {}, "cyc_ends": {}, "kolka": {}, "armchair": {}}
	var box := Rect2()
	var has_box := start != Vector2.INF and end != Vector2.INF
	if has_box:
		box = Rect2(start, Vector2.ZERO).expand(end).grow(300.0)
	var walk_box := Rect2()
	var has_walk := walk.size() == 2
	if has_walk:
		walk_box = Rect2(walk[0], Vector2.ZERO).expand(walk[1]).grow(80.0)
	var walk_paths: Array = []
	var kolka_paths: Array = []
	var foot_dk := PackedInt32Array()
	var cyc_dk := PackedInt32Array()
	var cyc_w := PackedFloat32Array()
	for p: Dictionary in paths:
		var k := str(p.get("k", ""))
		var dk := int(p.get("dk", -1))
		var flat: Array = p["p"]
		var n := flat.size() / 2
		if n < 2:
			continue
		var pts := PackedVector2Array()
		for i in n:
			pts.append(Vector2(float(flat[i * 2]), float(flat[i * 2 + 1])))
		var pset := ""
		if k == "foot" and dk < 0:
			pset = "foot"
		elif k == "cycle":
			pset = "cyc"
		# The boulevard is footway, crossings and cycle path in turn: Kolka runs on all of them.
		if has_box and k in ["foot", "zebra", "cycle", "cyclecross"] and (box.has_point(pts[0]) or box.has_point(pts[n - 1])):
			kolka_paths.append([pts, dk])
		if has_walk and dk < 0 and k in ["foot", "zebra"] and (walk_box.has_point(pts[0]) or walk_box.has_point(pts[n - 1])):
			walk_paths.append([pts, dk])
		if pset == "":
			continue
		var list: Array = out[pset]
		var idx := list.size()
		list.append(pts)
		# Packed arrays are values: append to the locals, stored in `out` at the end.
		if pset == "cyc":
			cyc_dk.append(dk)
			cyc_w.append(float(p.get("w", 2.0)))
		else:
			foot_dk.append(dk)
		var grid: Dictionary = out[pset + "_grid"]
		for j in n - 1:
			var a := pts[j]
			var b := pts[j + 1]
			var steps := maxi(1, ceili(a.distance_to(b) / (CELL * 0.5)))
			for s in steps + 1:
				var q := a.lerp(b, float(s) / steps)
				var c := Vector2i(floori(q.x / CELL), floori(q.y / CELL))
				if not grid.has(c):
					grid[c] = PackedInt32Array()
				var cell: PackedInt32Array = grid[c]
				if cell.is_empty() or cell[cell.size() - 1] != idx:
					cell.append(idx)
					grid[c] = cell
		var ends: Dictionary = out[pset + "_ends"]
		for e in 2:
			var q := pts[0] if e == 0 else pts[n - 1]
			var key := Vector2i(roundi(q.x), roundi(q.y))
			if not ends.has(key):
				ends[key] = PackedInt32Array()
			var at_end: PackedInt32Array = ends[key]
			at_end.append(idx * 2 + e)
			ends[key] = at_end
	out["foot_dk"] = foot_dk
	out["cyc_dk"] = cyc_dk
	out["cyc_w"] = cyc_w
	var tg: Dictionary = out["tree_grid"]
	for i in range(0, trees.size() - 5, 6):
		var q := Vector2(float(trees[i]), float(trees[i + 1]))
		var c := Vector2i(floori(q.x / TREE_CELL), floori(q.y / TREE_CELL))
		if not tg.has(c):
			tg[c] = PackedVector2Array()
		var cell: PackedVector2Array = tg[c]
		cell.append(q)
		tg[c] = cell
	if has_box and not kolka_paths.is_empty():
		var routes := Crowds.build_routes(kolka_paths, [["kolka", start]], [["bridge", end]])
		if not routes.is_empty():
			out["kolka"] = routes[0]
	if has_walk and not walk_paths.is_empty():
		var wr := Crowds.build_routes(walk_paths, [["a", walk[0]]], [["b", walk[1]]])
		if not wr.is_empty():
			out["armchair"] = wr[0]
	return out


func _finish_index() -> void:
	var r: Variant = _index_out[0] if not _index_out.is_empty() else null
	if not r is Dictionary:
		return
	var d: Dictionary = r
	for p: PackedVector2Array in d["foot"]:
		_foot.append(p)
	_foot_dk = d["foot_dk"]
	for p: PackedVector2Array in d["cyc"]:
		_cyc.append(p)
	_cyc_dk = d["cyc_dk"]
	_cyc_w = d["cyc_w"]
	_foot_grid = d["foot_grid"]
	_cyc_grid = d["cyc_grid"]
	_tree_grid = d["tree_grid"]
	_foot_ends = d["foot_ends"]
	_cyc_ends = d["cyc_ends"]
	_ready = true
	var kr: Dictionary = d["kolka"]
	if not kr.is_empty():
		var pts: PackedVector2Array = kr["pts"]
		var dk: PackedInt32Array = kr["dk"]
		# The A* can leave the place by a detour (no crossing to the boulevard in the data, a loop
		# north and back): the club starts at the route's last point within KOLKA_REACH of the place.
		var first := 0
		for i in pts.size() - 1:
			if pts[i].distance_to(pts[0]) <= KOLKA_REACH:
				first = i
		pts = pts.slice(first)
		dk = dk.slice(first)
		_kolka_skip = kr["pts"][first].distance_to(kr["pts"][0])
		var h := PackedFloat32Array()
		var cum := PackedFloat32Array()
		var run := 0.0
		for i in pts.size():
			if i > 0:
				run += pts[i].distance_to(pts[i - 1])
			cum.append(run)
			h.append(map.deck_height(dk[i], pts[i].x, pts[i].y) if map != null else 0.0)
		_kolka = {"pts": pts, "h": h, "cum": cum, "len": run, "members": [], "date": -1, "beeped": false, "chat": 20.0}
	var ar: Dictionary = d.get("armchair", {})
	if not ar.is_empty():
		var apts: PackedVector2Array = ar["pts"]
		var acum := PackedFloat32Array()
		var ah := PackedFloat32Array()
		var arun := 0.0
		for i in apts.size():
			if i > 0:
				arun += apts[i].distance_to(apts[i - 1])
			acum.append(arun)
			ah.append(_ground(apts[i]))
		_arm = {"pts": apts, "cum": acum, "h": ah, "len": arun}
	_place_fixed()
	print("life: the armchair man's way on %s: %s" % [ARMCHAIR_STREET, "%.0f m" % float(_arm["len"]) if not _arm.is_empty() else "none"])
	print("life: %d footways, %d cycle paths, %d tree cells; Kolka's route %s; the dock %s; Hyrax %s; the influencer %s; the ball %s" % [
			_foot.size(), _cyc.size(), _tree_grid.size(), "%.0f m (from %.0f m off the place)" % [float(_kolka["len"]), _kolka_skip] if not _kolka.is_empty() else "none",
			"%d bikes" % int(_docks[0]["n"]) if not _docks.is_empty() else "none",
			"at %.0f, %.0f" % [_hyrax["at"].x, _hyrax["at"].y] if not _hyrax.is_empty() else "none",
			"at %.0f, %.0f" % [_infl["at"].x, _infl["at"].y] if not _infl.is_empty() else "none",
			"%.0f m up" % (float(_aport["ball"].y) - float(_aport["dog"].y)) if not _aport.is_empty() else "none"])


## The things that stand still: the dock's bikes, the Hyrax cordon, the influencer, the ball.
func _place_fixed() -> void:
	if _at.has("rowerilo_dock"):
		var hit := _nearest_on("foot", _at["rowerilo_dock"], 40.0)
		if hit.is_empty():
			hit = _nearest_on("cyc", _at["rowerilo_dock"], 40.0)
		if not hit.is_empty():
			var rng := RandomNumberGenerator.new()
			rng.seed = 2801
			var dir: Vector2 = hit[3]
			var side := Vector2(-dir.y, dir.x)
			_docks.append({"at": (hit[2] as Vector2) + side * 1.6, "dir": dir, "n": rng.randi_range(DOCK_N.x, DOCK_N.y)})
	if _at.has("hyrax_narodowy"):
		_place_hyrax(_at["hyrax_narodowy"])
	if _at.has("plac_zbawiciela"):
		var hit := _nearest_on("foot", _at["plac_zbawiciela"], 60.0)
		if not hit.is_empty():
			var at: Vector2 = hit[2]
			var dir: Vector2 = hit[3]
			_infl = {"at": at, "dir": dir, "line_t": 0.0}
			if egg_book != null:
				egg_book.move_egg("e27", at)
	if _at.has("centrum_nauki_kopernik") and map != null:
		var c: Vector2 = _at["centrum_nauki_kopernik"]
		var best := Vector3.INF
		for dx in range(-10, 11):
			for dz in range(-10, 11):
				var q := c + Vector2(dx, dz) * 6.0
				var top: float = map.roof_height(q.x, q.y)
				var up: float = top - map.ground_height(q.x, q.y)
				if up > 6.0 and (best == Vector3.INF or top > best.y):
					best = Vector3(q.x, top, q.y)
		if best != Vector3.INF:
			var hit := _nearest_open(Vector2(best.x, best.z), 120.0)
			if not hit.is_empty():
				var dog: Vector2 = hit[2]
				_aport = {"ball": best + Vector3(0, 0.15, 0), "dog": Vector3(dog.x, map.deck_height(-1, dog.x, dog.y), dog.y),
						"mem": {"state": "roof"}, "told": false}


## The Hyrax cordon: the open ground nearest the forecourt's point (no roof, no water, within
## 120 m), a ring of barriers, the banner on the side away from the stadium.
func _place_hyrax(p: Vector2) -> void:
	if map == null:
		return
	var best := Vector2.INF
	for r in range(0, 121, 8):
		for a in maxi(1, r / 4):
			var q := p + Vector2.from_angle(TAU * a / maxf(1.0, r / 4.0)) * r
			if _open_ring(q, CORDON_R + 4.0):
				best = q
				break
		if best != Vector2.INF:
			break
	if best == Vector2.INF:
		print("life: no open ground for the Hyrax cordon near %.0f, %.0f" % [p.x, p.y])
		return
	var stadium: Vector2 = _at.get("stadion_narodowy", p + Vector2.DOWN)
	var out := (best - stadium).normalized() if best.distance_to(stadium) > 1.0 else Vector2.UP
	var barriers: Array = []
	for i in CORDON_N:
		var a := TAU * i / CORDON_N
		var q := best + Vector2.from_angle(a) * CORDON_R
		# Each barrier along the ring: its boards (the mesh's x) along the tangent.
		barriers.append([Vector3(q.x, map.ground_height(q.x, q.y), q.y), atan2(-cos(a), -sin(a))])
	_hyrax = {"at": best, "out": out, "barriers": barriers, "chat": 15.0, "whistle": 30.0}
	_banner = _sign_mesh(["HYRAX"], 0.12, Color("#c9a46b"), Color("#1e2a36"), 2)
	var bp := best + out * (CORDON_R + 2.0)
	_banner.position = Vector3(bp.x, map.ground_height(bp.x, bp.y) + 2.6, bp.y)
	_banner.rotation.y = atan2(-out.x, -out.y)  # the words read from the -z side, facing `out`
	_banner.visible = false
	add_child(_banner)
	if egg_book != null:
		egg_book.move_egg("e30", best)


func _open_ring(q: Vector2, r: float) -> bool:
	for k in 12:
		var s := q + Vector2.from_angle(TAU * k / 12.0) * r
		if map.roof_height(s.x, s.y) - map.ground_height(s.x, s.y) > 1.0 or map.shore_distance(s.x, s.y) > 0.0:
			return false
	return map.roof_height(q.x, q.y) - map.ground_height(q.x, q.y) <= 1.0


## The nearest point on a set's paths within `reach`: [path, segment, point, direction], or [].
func _nearest_on(pset: String, p: Vector2, reach: float) -> Array:
	var grid: Dictionary = _foot_grid if pset == "foot" else _cyc_grid
	var list: Array[PackedVector2Array] = _foot if pset == "foot" else _cyc
	var best: Array = []
	var best_d := reach
	var c := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	var r := ceili(reach / CELL)
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			for i: int in grid.get(c + Vector2i(dx, dz), PackedInt32Array()):
				var pts := list[i]
				for j in pts.size() - 1:
					var q := Geometry2D.get_closest_point_to_segment(p, pts[j], pts[j + 1])
					var d := q.distance_to(p)
					if d < best_d:
						best_d = d
						best = [i, j, q, (pts[j + 1] - pts[j]).normalized()]
	return best


## The nearest footway point under open sky within `reach`.
func _nearest_open(p: Vector2, reach: float) -> Array:
	var c := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	var r := ceili(reach / CELL)
	var best: Array = []
	var best_d := reach
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			for i: int in _foot_grid.get(c + Vector2i(dx, dz), PackedInt32Array()):
				var pts := _foot[i]
				for j in pts.size() - 1:
					var q := Geometry2D.get_closest_point_to_segment(p, pts[j], pts[j + 1])
					var d := q.distance_to(p)
					if d < best_d and map.roof_height(q.x, q.y) - map.ground_height(q.x, q.y) < 1.0:
						best_d = d
						best = [i, j, q, (pts[j + 1] - pts[j]).normalized()]
	return best


# --- the meshes ------------------------------------------------------------------------------

## A box's 36 vertices (6 faces, 2 triangles each) and normals for a family: the winding comes
## from the unit box, so a box collapsed to nothing in one shape keeps its order.
static func _box_verts(centre: Vector3, size: Vector3) -> Array:
	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = 1.0
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = 1.0
			var q := [n - u - v, n + u - v, n + u + v, n - u + v]
			if ((q[1] as Vector3) - q[0]).cross((q[2] as Vector3) - q[0]).dot(n) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for k in [0, 1, 2, 0, 2, 3]:
				pos.append(centre + (q[k] as Vector3) * h)
				nrm.append(n)
	return [pos, nrm]


## A unit normal as one float (models.gd's octahedral packing, which actor.gdshader unpacks).
static func _pack(n: Vector3) -> float:
	var s := absf(n.x) + absf(n.y) + absf(n.z)
	var e := Vector2(n.x, n.y) / s
	if n.z < 0.0:
		e = Vector2((1.0 - absf(e.y)) * (1.0 if e.x >= 0.0 else -1.0), (1.0 - absf(e.x)) * (1.0 if e.y >= 0.0 else -1.0))
	return float(roundi((e.x * 0.5 + 0.5) * 4095.0) * 4096 + roundi((e.y * 0.5 + 0.5) * 4095.0))


## A family mesh (actor.gdshader's morph: INSTANCE_CUSTOM.a picks the shape): `parts` [colour,
## part code], `shapes` up to four lists of [centre, size], one per part (size zero: not in that
## shape).
static func family_mesh(parts: Array, shapes: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ch in 3:
		st.set_custom_format(ch, SurfaceTool.CUSTOM_RGBA_FLOAT)
	for b in parts.size():
		var per: Array = []
		for sh in 4:
			var box: Array = (shapes[mini(sh, shapes.size() - 1)] as Array)[b]
			per.append(_box_verts(box[0], box[1]))
		for k in 36:
			for ch in 3:
				var o: Array = per[ch + 1]
				st.set_custom(ch, Color(o[0][k].x, o[0][k].y, o[0][k].z, _pack(o[1][k])))
			st.set_color(parts[b][0])
			st.set_normal(per[0][1][k])
			st.set_uv(Vector2(float(parts[b][1]) + Models.MORPH, 0.0))
			st.add_vertex(per[0][0][k])
	st.index()
	return st.commit()


## The dogs (long and low, squat and flat-faced, big and fluffy; ≤ 120 triangles each) and the
## cordon's barrier, facing -z.
static func dog_mesh() -> ArrayMesh:
	var coat := [Color.WHITE, Models.PAINT]
	var nose := [Color("#241c18"), Models.FIXED]
	var parts := [coat, coat, nose, coat, coat, coat, coat, coat, coat, coat]
	var Z := Vector3.ZERO
	var long := [[Vector3(0, 0.2, 0), Vector3(0.18, 0.15, 0.62)], [Vector3(0, 0.3, -0.36), Vector3(0.14, 0.14, 0.18)],
			[Vector3(0, 0.27, -0.49), Vector3(0.08, 0.07, 0.1)],
			[Vector3(-0.06, 0.065, -0.22), Vector3(0.05, 0.13, 0.05)], [Vector3(0.06, 0.065, -0.22), Vector3(0.05, 0.13, 0.05)],
			[Vector3(-0.06, 0.065, 0.22), Vector3(0.05, 0.13, 0.05)], [Vector3(0.06, 0.065, 0.22), Vector3(0.05, 0.13, 0.05)],
			[Vector3(0, 0.27, 0.38), Vector3(0.03, 0.03, 0.16)],
			[Vector3(-0.08, 0.27, -0.33), Vector3(0.03, 0.11, 0.07)], [Vector3(0.08, 0.27, -0.33), Vector3(0.03, 0.11, 0.07)]]
	var squat := [[Vector3(0, 0.27, 0), Vector3(0.3, 0.24, 0.42)], [Vector3(0, 0.38, -0.27), Vector3(0.25, 0.22, 0.16)],
			[Vector3(0, 0.33, -0.36), Vector3(0.12, 0.07, 0.04)],
			[Vector3(-0.1, 0.08, -0.14), Vector3(0.08, 0.16, 0.08)], [Vector3(0.1, 0.08, -0.14), Vector3(0.08, 0.16, 0.08)],
			[Vector3(-0.1, 0.08, 0.14), Vector3(0.08, 0.16, 0.08)], [Vector3(0.1, 0.08, 0.14), Vector3(0.08, 0.16, 0.08)],
			[Vector3(0, 0.34, 0.23), Vector3(0.06, 0.06, 0.06)],
			[Vector3(-0.1, 0.5, -0.26), Vector3(0.06, 0.06, 0.03)], [Vector3(0.1, 0.5, -0.26), Vector3(0.06, 0.06, 0.03)]]
	var fluffy := [[Vector3(0, 0.62, 0), Vector3(0.44, 0.42, 0.82)], [Vector3(0, 0.86, -0.5), Vector3(0.32, 0.3, 0.3)],
			[Vector3(0, 0.8, -0.69), Vector3(0.14, 0.12, 0.12)],
			[Vector3(-0.13, 0.21, -0.28), Vector3(0.12, 0.42, 0.12)], [Vector3(0.13, 0.21, -0.28), Vector3(0.12, 0.42, 0.12)],
			[Vector3(-0.13, 0.21, 0.28), Vector3(0.12, 0.42, 0.12)], [Vector3(0.13, 0.21, 0.28), Vector3(0.12, 0.42, 0.12)],
			[Vector3(0, 0.84, 0.5), Vector3(0.13, 0.13, 0.3)],
			[Vector3(-0.13, 1.02, -0.48), Vector3(0.08, 0.12, 0.06)], [Vector3(0.13, 1.02, -0.48), Vector3(0.08, 0.12, 0.06)]]
	# The barrier: two boards across x, two legs, the rest folded away.
	var barrier := [[Vector3(0, 0.85, 0), Vector3(1.9, 0.24, 0.04)], [Vector3(0, 0.45, 0), Vector3(1.9, 0.18, 0.04)],
			[Z, Z], [Vector3(-0.88, 0.47, 0), Vector3(0.05, 0.94, 0.05)], [Vector3(0.88, 0.47, 0), Vector3(0.05, 0.94, 0.05)],
			[Vector3(-0.88, 0.02, 0), Vector3(0.06, 0.04, 0.5)], [Vector3(0.88, 0.02, 0), Vector3(0.06, 0.04, 0.5)],
			[Z, Z], [Z, Z], [Z, Z]]
	return family_mesh(parts, [long, squat, fluffy, barrier])


## The bikes, facing -z: a commuter, a Rowerilo bike (cream, a grey basket), a cargo bike with a
## child in the box, each ridden (the rider's shirt is the instance colour), and a parked Rowerilo
## bike.
static func bike_mesh() -> ArrayMesh:
	var tyre := [Models.TYRE, Models.FIXED]
	var dark := [Color("#2d3442"), Models.FIXED]
	var cream := [Color("#efe6cf"), Models.FIXED]
	var grey := [Color("#8a8d91"), Models.FIXED]
	var wood := [Color("#3b6e5a"), Models.FIXED]
	var skin := [Color("#e2b48c"), Models.FIXED]
	var shirt := [Color.WHITE, Models.PAINT]
	var trousers := [Color("#2d3442"), Models.FIXED]
	var hair := [Color("#4a3426"), Models.FIXED]
	var black := [Color("#202024"), Models.FIXED]
	var parts := [tyre, tyre, dark, cream, grey, wood, skin, black, black, shirt, skin, hair, trousers, trousers, shirt]
	var Z := [Vector3.ZERO, Vector3.ZERO]
	var wf := [Vector3(0, 0.33, -0.52), Vector3(0.05, 0.64, 0.64)]
	var wr := [Vector3(0, 0.33, 0.52), Vector3(0.05, 0.64, 0.64)]
	var frame := [Vector3(0, 0.62, 0), Vector3(0.05, 0.06, 0.98)]
	var basket := [Vector3(0, 0.85, -0.62), Vector3(0.36, 0.24, 0.3)]
	var bar := [Vector3(0, 1.0, -0.46), Vector3(0.5, 0.04, 0.04)]
	var seat := [Vector3(0, 0.88, 0.25), Vector3(0.12, 0.05, 0.2)]
	var rider := [[Vector3(0, 1.22, 0.12), Vector3(0.42, 0.55, 0.26)], [Vector3(0, 1.62, 0.02), Vector3(0.24, 0.24, 0.24)],
			[Vector3(0, 1.76, 0.04), Vector3(0.26, 0.07, 0.27)], [Vector3(-0.1, 0.62, 0.0), Vector3(0.14, 0.56, 0.16)],
			[Vector3(0.1, 0.62, 0.0), Vector3(0.14, 0.56, 0.16)], [Vector3(0, 1.1, -0.2), Vector3(0.52, 0.1, 0.42)]]
	var commuter := [wf, wr, frame, Z, Z, Z, Z, bar, seat] + rider
	var rowerilo := [wf, wr, Z, frame, basket, Z, Z, bar, seat] + rider
	var cargo := [[Vector3(0, 0.25, -1.0), Vector3(0.05, 0.5, 0.5)], wr, [Vector3(0, 0.55, -0.25), Vector3(0.05, 0.06, 1.5)],
			Z, Z, [Vector3(0, 0.62, -0.62), Vector3(0.62, 0.42, 0.62)], [Vector3(0, 0.98, -0.62), Vector3(0.2, 0.2, 0.2)],
			bar, seat] + rider
	var parked := [wf, wr, Z, frame, basket, Z, Z, bar, seat, Z, Z, Z, Z, Z, Z]
	return family_mesh(parts, [commuter, rowerilo, cargo, parked])


## A sign: a dark board with lines of the pixel font (lit at night: actor.gdshader's LIT_SIGN)
## and two posts, facing +z (the reader). `px` the pixel's size (m).
func _sign_mesh(lines: Array, px: float, ink: Color, board: Color, posts := 0) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := 0
	for l: String in lines:
		w = maxi(w, PixelFont.width(l))
	var bw := (w + 6) * px
	var bh := (lines.size() * PixelFont.LINE + 3) * px
	Models.box(st, Vector3(0, 0, -0.03), Vector3(bw, bh, 0.06), board)
	for i in lines.size():
		var l: String = lines[i]
		var lw := PixelFont.width(l) * px
		PixelFont.add_quads(st, l, Vector3(-lw * 0.5, bh * 0.5 - 1.5 * px - i * PixelFont.LINE * px, 0.0), Vector3.RIGHT, Vector3.DOWN,
				px, ink, Models.LIT_SIGN)
	for k in posts:
		var x := (bw * 0.5 - 0.06) * (-1.0 if k == 0 else 1.0)
		Models.box(st, Vector3(x, -1.3, -0.03), Vector3(0.08, 2.6, 0.08), Color("#3a3b3f"))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Models.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _build_drawing() -> void:
	_dog_mm = _new_mm(dog_mesh(), DOG_CAP)
	_dog_buf.resize(DOG_CAP * 16)
	_dog_buf.fill(0.0)
	_dog_mmi = _new_mmi(_dog_mm, "Dogs")
	_bike_mm = _new_mm(bike_mesh(), BIKE_CAP)
	_bike_buf.resize(BIKE_CAP * 16)
	_bike_buf.fill(0.0)
	_bike_mmi = _new_mmi(_bike_mm, "Bikes")
	_ped_mm = _new_mm(Props.pedzik_rider(), PEDZIK_CAP)
	_ped_buf.resize(PEDZIK_CAP * 16)
	_ped_buf.fill(0.0)
	_ped_mmi = _new_mmi(_ped_mm, "Pedzik")
	_gbuf.resize(Pedestrians.GUESTS * 16)
	_gbuf.fill(0.0)
	# Loop jobs-2: the armchair on the man's head (shown only near him).
	_chair = MeshInstance3D.new()
	_chair.name = "Armchair"
	_chair.mesh = Props.carried_armchair()
	_chair.material_override = Models.material()
	_chair.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_chair.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_chair.visible = false
	add_child(_chair)


func _new_mm(mesh: ArrayMesh, cap: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = mesh
	mm.instance_count = cap
	mm.visible_instance_count = 0
	return mm


func _new_mmi(mm: MultiMesh, n: String) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = n
	mmi.multimesh = mm
	mmi.material_override = Models.material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mmi.visible = false
	add_child(mmi)
	return mmi


## One instance into `buf` at `i`: at `at` facing `yaw` (as crowds.gd's), `scale`, the paint and
## the family's shape.
static func put(buf: PackedFloat32Array, i: int, at: Vector3, yaw: float, scale: Vector3, paint: Color, shape: float) -> void:
	var b := i * 16
	var c := cos(yaw)
	var s := sin(yaw)
	buf[b] = c * scale.x
	buf[b + 1] = 0.0
	buf[b + 2] = s * scale.z
	buf[b + 3] = at.x
	buf[b + 4] = 0.0
	buf[b + 5] = scale.y
	buf[b + 6] = 0.0
	buf[b + 7] = at.y
	buf[b + 8] = -s * scale.x
	buf[b + 9] = 0.0
	buf[b + 10] = c * scale.z
	buf[b + 11] = at.z
	buf[b + 12] = paint.r
	buf[b + 13] = paint.g
	buf[b + 14] = paint.b
	buf[b + 15] = shape


# --- the trend cycle (vision 3.4) -------------------------------------------------------------

## The cycle's day number now: --trend-day, Live's date, or the session's.
func days_now() -> int:
	if trend_day_flag >= 0:
		return trend_day_flag
	var cal: Dictionary = calendar.call() if calendar.is_valid() else {}
	if bool(cal.get("live", false)) and int(cal.get("date", 0)) > 0:
		return day_number(int(cal["date"]))
	return session_days(session)


## Where Kolka gathers (its route's start), INF before the index is built or without a route.
func kolka_start_at() -> Vector2:
	if _kolka.is_empty():
		return Vector2.INF
	return (_kolka["pts"] as PackedVector2Array)[0]


## The game clock's hour at the last tick (trend_job.gd).
func hour_now() -> float:
	return _hour


## The game weekday at the last tick, 1 Monday .. 7 Sunday (trend_job.gd's drop).
func weekday_now() -> int:
	return _weekday


## crowds.gd's `trend`: a slot's (or Lukrownia's) queue now, without the amount (crowds.gd
## applies it), and its line's tag.
func trend_queue(id: String) -> Array:
	if id == LUKROWNIA:
		return [FAT_QUEUE if fat_thursday else 0, "queue"]
	var i := SLOTS.find(id)
	if i < 0 or i >= slots_now.size():
		return [0, ""]
	return [slot_queue(slots_now[i], _hour), str(slots_now[i]["tag"])]


func _trend_tick() -> void:
	var cal: Dictionary = calendar.call() if calendar.is_valid() else {}
	var date := int(cal.get("date", 0))
	var live := bool(cal.get("live", false))
	# The day number and Fat Thursday hang on the date: read again when it (or Live) changes.
	if date != _date or live != _date_live or trend_day_flag >= 0 or not live:
		_days = days_now()
		_date_fat = fat_queue(live, date, float(FAT_HOURS[0])) > 0
	_date = date
	_date_live = live
	fat_thursday = _date_fat and _hour >= float(FAT_HOURS[0]) and _hour < float(FAT_HOURS[1])
	if not trend_log and _days == _slots_days and slots_now.size() == SLOTS.size():
		return  # the slots' states hang on the day only (the queues are read when needed)
	_slots_days = _days
	var changed := slots_now.size() != SLOTS.size()
	var now: Array[Dictionary] = []
	for i in SLOTS.size():
		var st := slot_state(_days, i)
		now.append(st)
		if not changed and (int(st["day"]) != int(slots_now[i]["day"]) or int(st["trend"]) != int(slots_now[i]["trend"])):
			changed = true
	var hour_q := PackedInt32Array()
	for i in now.size():
		hour_q.append(slot_queue(now[i], _hour))
	var old_q := PackedInt32Array()
	for i in slots_now.size():
		old_q.append(slot_queue(slots_now[i], _hour - TICK / 3600.0))
	slots_now = now
	if trend_log and (changed or hour_q != old_q):
		for i in now.size():
			print("trend: slot %d day %d queue %d (%s, %s)" % [i + 1, int(now[i]["day"]), hour_q[i], now[i]["word"], SLOTS[i]])
		if fat_thursday:
			print("trend: Lukrownia's Fat Thursday queue %d" % FAT_QUEUE)


## The fascias near the view: built when the slot's word changes, hidden further than FASCIA_R.
func _fascia_tick(eye: Vector2) -> void:
	if slot_doors.is_empty() or slots_now.is_empty():
		return
	while _fascias.size() < slot_doors.size():
		_fascias.append(null)
		_fascia_key.append("")
	for i in slot_doors.size():
		var near := eye.distance_to(slot_doors[i]) <= FASCIA_R and slot_doors[i] != Vector2.INF
		var st: Dictionary = slots_now[i]
		var key := "%s|%d" % [st["word"], 1 if int(st["day"]) == 1 else 0] if near else ""
		if near and key != _fascia_key[i]:
			if _fascias[i] != null:
				_fascias[i].queue_free()
			var lines: Array = ["WIRALEK · NOWOŚĆ!" if int(st["day"]) == 1 else "WIRALEK"]
			for l in PixelFont.wrap_lines(str(st["word"]), 100):
				lines.append(l)
			var mi := _sign_mesh(lines, FASCIA_PX, Color("#ff7ac8") if int(st["day"]) < CYCLE else Color("#c9c2d8"), Color("#1c1f26"))
			var door := slot_doors[i]
			var out := slot_out[i]
			var at := door - out * 0.6
			mi.position = Vector3(at.x, (map.ground_height(at.x, at.y) if map != null else 0.0) + 3.1, at.y)
			# The sign's words read from its -z side: turned so they face the street (`out`).
			mi.rotation.y = atan2(-out.x, -out.y)
			add_child(mi)
			_fascias[i] = mi
			_fascia_key[i] = key
		if _fascias[i] != null:
			_fascias[i].visible = near


## E18 and E19, seen from the car: a slot's day 1, 4 and WKRÓTCE of one trend; all three on day 1.
func _trend_eggs(p: Vector2) -> void:
	if egg_book == null or slots_now.is_empty():
		return
	for i in slot_doors.size():
		if p.distance_to(slot_doors[i]) > SEEN_R:
			continue
		var key := "trend_seen_%d" % i
		var mem: Dictionary = (wallet.keep.get(key, {}) as Dictionary).duplicate(true) if wallet != null else _seen_e18.get(key, {})
		var before := str(mem)
		var done := e18_step(mem, slots_now[i])
		if str(mem) != before:
			if wallet != null:
				wallet.keep[key] = mem
				wallet.save()
			else:
				_seen_e18[key] = mem
			if trend_log:
				print("trend: slot %d seen on day %d (trend %d, seen days %s)" % [i + 1, int(slots_now[i]["day"]), int(mem["cycle"]), mem["days"]])
		if done:
			_fire("e18")
		if all_new(_days):
			_fire("e19")


## Loop jobs-2: the armchair man now: [position, yaw] (his way's point at the session's time).
func armchair_pose() -> Array:
	if _arm.is_empty():
		return [Vector3.INF, 0.0]
	var at := armchair_at(t, float(_arm["len"]))
	var pts: PackedVector2Array = _arm["pts"]
	var cum: PackedFloat32Array = _arm["cum"]
	var h: PackedFloat32Array = _arm["h"]
	var i := cum.bsearch(at.x) - 1
	i = clampi(i, 0, pts.size() - 2)
	var span := maxf(cum[i + 1] - cum[i], 0.001)
	var k := clampf((at.x - cum[i]) / span, 0.0, 1.0)
	var p := pts[i].lerp(pts[i + 1], k)
	var dir := (pts[i + 1] - pts[i]) * at.y
	return [Vector3(p.x, lerpf(h[i], h[i + 1], k), p.y), atan2(-dir.x, -dir.y)]


## Loop jobs-2: he is out (his day, the shops' hours, or --armchair) and his way is known.
func armchair_out() -> bool:
	return not _arm.is_empty() and (armchair_flag or (armchair_day(days_now()) and in_hours([SHOP_HOURS], _hour)))


func _fire(id: String) -> bool:
	if egg_book == null or egg_book.is_found(id):
		return false
	var s: Dictionary = probe.call() if probe.is_valid() else {}
	if s.is_empty():
		return false
	return egg_book.fire(id, s)


# --- the logic -------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or not clock.is_valid():
		return
	var t0 := Time.get_ticks_usec()
	t += dt
	if _index_task >= 0 and WorkerThreadPool.is_task_completed(_index_task):
		WorkerThreadPool.wait_for_task_completion(_index_task)
		_index_task = -1
		_finish_index()
	_tick_t += dt
	if _tick_t >= TICK:
		var step := _tick_t
		_tick_t = 0.0
		tick(step)
	if _active:
		_move_t += dt
		if _move_t >= MOVE_TICK:
			var mstep := _move_t
			_move_t = 0.0
			_move(mstep)
	if soak:
		_soak_frame(dt)
	if zajac_rig:
		_zajac_rig_frame(dt)
	spent_usec += Time.get_ticks_usec() - t0


## One tick of the logic, `step` seconds after the last.
func tick(step: float) -> void:
	var now: Dictionary = clock.call()
	_hour = float(now["hour"])
	_weekday = int(now["weekday"])
	_trend_tick()
	var eye3: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var eye := Vector2(eye3.x, eye3.z)
	_fascia_tick(eye)
	var veh: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF, 0.0, false, 0.0, 0.0]
	var vp: Vector3 = veh[0]
	var p2 := Vector2(vp.x, vp.z)
	if vp != Vector3.INF:
		_trend_eggs(p2)
	# Loop couriers: the couriers waiting at the stands near the view (no index needed).
	_wait_tick(eye)
	if not _ready:
		if not _waiting.is_empty():
			_active = true
		return
	var zone := false
	for z in _zones:
		if eye.distance_to(z) < ZONE_R:
			zone = true
			break
	var blvd := false
	for id: String in Crowds.BULWARY:
		if eye.distance_to(Crowds.BULWARY[id][0]) < Crowds.BULWARY_R + float(Crowds.BULWARY[id][2]):
			blvd = true
			break
	_on_blvd = blvd
	var run_zone := false
	for z in _run_zones:
		if eye.distance_to(z) < RUN_ZONE_R:
			run_zone = true
			break
	# The movers: spawn up to the count near the view, drop the far ones.
	var car2 := p2 if vp != Vector3.INF and not bool(veh[2]) else Vector2.INF
	_keep(_dogs, dog_count(_hour, zone, amount), "dog", eye, car2)
	_keep(_riders, rider_count(_hour, amount, blvd), "rider", eye, car2)
	_keep(_pedziks, pedzik_count(_hour, amount) if pedzik_on else 0, "pedzik", eye, car2)
	_keep(_kerbers, kerb_count(_hour, amount) if pedzik_on and graph != null else 0, "kerb", eye, car2)
	_keep(_runners, runner_count(_hour, run_zone, amount), "runner", eye, car2)
	_shown_now = _shown_bits(eye)
	# Who is on screen, for the step's rate: inside the view's ground rectangle and VIS_MARGIN
	# (traffic.gd's, read once), else on_screen per mover (without either: all are).
	var test := on_screen.is_valid()
	var vc := Vector2.ZERO
	var vr := Vector2.RIGHT
	var va := Vector2.UP
	var vh := Vector2.ZERO
	if view != null:
		vc = view.view_centre
		vr = view.view_right
		va = view.view_ahead
		vh = (view.view_half as Vector2) + Vector2.ONE * VIS_MARGIN
	for list: Array[Mover] in [_dogs, _riders, _runners, _pedziks, _kerbers]:
		for m in list:
			if view != null:
				var q := m.p2 - vc
				m.vis = absf(q.dot(vr)) <= vh.x and absf(q.dot(va)) <= vh.y
			else:
				m.vis = not test or bool(on_screen.call(m.p3, 1.8))
	var kphase := kolka_phase(_hour, _weekday)
	var hyrax := hyrax_on(_hour, _weekday) and not _hyrax.is_empty()
	var infl := in_hours([INFLUENCER_HOURS], _hour) and not _infl.is_empty()
	var aport := in_hours([APORT_HOURS], _hour) and not _aport.is_empty() and str(_aport["mem"]["state"]) != "home"
	levels = {"influencer": 1.0 if infl else 0.0, "hyrax": 1.0 if hyrax else 0.0, "kolka": 1.0 if kphase != "" else 0.0,
			"dogs": float(_dogs.size()), "riders": float(_riders.size())}
	var near_fixed := false
	if not _docks.is_empty() and eye.distance_to(_docks[0]["at"]) < NEAR_R:
		near_fixed = true
	if hyrax and eye.distance_to(_hyrax["at"]) < NEAR_R + 100.0:
		near_fixed = true
	if infl and eye.distance_to(_infl["at"]) < NEAR_R:
		near_fixed = true
	if aport and eye.distance_to(Vector2(_aport["dog"].x, _aport["dog"].z)) < NEAR_R + 100.0:
		near_fixed = true
	# Loop jobs-2: the armchair man (near the view: he walks; the car beside him: E34).
	_arm_on = armchair_out()
	if _arm_on:
		var pose := armchair_pose()
		var ap: Vector3 = pose[0]
		if eye.distance_to(Vector2(ap.x, ap.z)) < NEAR_R:
			near_fixed = true
		if not veh[2] and vp != Vector3.INF and p2.distance_to(Vector2(ap.x, ap.z)) <= ARMCHAIR_EGG:
			met_armchair += 1
			if _fire("e34") and life_log:
				print("life: passed the armchair man at %.0f, %.0f" % [ap.x, ap.z])
	if _chair != null and _chair.visible and _shown_now & ARM_BIT == 0:
		_chair.visible = false
	var kolka_near := kphase != "" and not _kolka.is_empty() and eye.distance_to(_kolka_centre()) < NEAR_R + 200.0
	if _banner != null:
		_banner.visible = hyrax and eye.distance_to(_hyrax["at"]) < FASCIA_R
	var was := _active
	_active = not _dogs.is_empty() or not _riders.is_empty() or not _runners.is_empty() or not _pedziks.is_empty() or near_fixed or kolka_near \
			or not _kerbers.is_empty() or not _waiting.is_empty()
	if was and not _active:
		_hide_all()
	if not veh[2] and vp != Vector3.INF:
		_bell_tick(p2, float(veh[1]), step)
		_follow_tick(p2, float(veh[1]), step)
	if kphase == "run" and not _kolka.is_empty():
		_zajac_tick(vp, float(veh[1]), bool(veh[2]), step)
	if kphase != "" and kolka_near:
		_kolka_talk(eye, step)
	if hyrax and eye.distance_to(_hyrax["at"]) < NEAR_R:
		_hyrax_talk(step)
	if infl and vp != Vector3.INF:
		_infl_tick(p2, float(veh[1]), bool(veh[2]), step)
	if vp != Vector3.INF and not bool(veh[2]):
		_tiny_tick(p2, float(veh[1]))
	if aport:
		_aport_tick(veh)
	if dogs_log or life_log or soak or pedzik_log:
		_log_t -= step
		if _log_t <= 0.0:
			_log_t = MINUTE
			if dogs_log:
				print("dogs: %s" % dog_summary())
			if life_log:
				print("life: %s" % life_summary())
			if pedzik_log:
				print("pedzik: %s" % pedzik_summary())
			if soak:
				print("life: soak %.1f min · dogs %d near (%d met) · riders %d (%d met) · runners %d · overlaps %d · closest %s" % [
						t / 60.0, _dogs.size(), met_dogs, _riders.size(), met_riders, _runners.size(), overlaps,
						"%.2f m" % closest if closest < INF else "-"])


# --- loop couriers: the couriers waiting at the kebab stands -----------------------------------

## The couriers waiting at the stands within NEAR_R of `eye` at night (waiting_count, less the ones the
## race took): a change writes everything at the next step. The race's take comes back when its stand
## leaves the band (NEAR_R + 100 m) or the night ends.
func _wait_tick(eye: Vector2) -> void:
	var list: Array = []
	var sig := 0
	if pedzik_on and not stands.is_empty() and pedzik_night(_hour):
		var day := days_now()
		for i in stands.size():
			var at: Vector3 = stands[i][0]
			var d := eye.distance_to(Vector2(at.x, at.z))
			if d > NEAR_R:
				if d > NEAR_R + 100.0 and _taken.has(i):
					_taken.erase(i)
				continue
			var n := waiting_count(i, day, _hour) - int(_taken.get(i, 0))
			var spots := _spots_of(i)
			for k in mini(n, spots.size()):
				list.append([i, spots[k][0], spots[k][1]])
				sig = (sig * 31 + i * 4 + k + 1) % 1000000007
	elif not _taken.is_empty():
		_taken.clear()
	if sig != _wait_sig or list.size() != _waiting.size():
		_wait_sig = sig
		_waiting = list
		_full = true


## Stand i's free spots for its couriers (worked out once): WAIT_SPOTS beside the kiosk with no roof
## over them and no lane under them, the first WAIT_MAX; each [at, yaw] (the bike pointing at the road,
## as the counter faces).
func _spots_of(i: int) -> Array:
	if _wait_spots.has(i):
		return _wait_spots[i]
	var at: Vector3 = stands[i][0]
	var yaw: float = stands[i][1]
	var b := Basis(Vector3.UP, yaw)
	var out: Array = []
	for o: Vector2 in WAIT_SPOTS:
		if out.size() >= WAIT_MAX:
			break
		var p3 := at + b * Vector3(o.x, 0.0, o.y)
		if map != null:
			if map.roof_height(p3.x, p3.z) - map.ground_height(p3.x, p3.z) > 1.0:
				continue
			p3.y = map.ground_height(p3.x, p3.z)
		if graph != null and not graph.snap(Vector2(p3.x, p3.z), 1.8).is_empty():
			continue
		out.append([p3, yaw])
	_wait_spots[i] = out
	return out


## The couriers waiting at stand i now ([at, yaw] each; [] by day, or none there): courier_race.gd's
## challenger is one of them. By the rule, wherever the view is.
func waiting_at(i: int) -> Array:
	if not pedzik_on or i < 0 or i >= stands.size() or not clock.is_valid():
		return []
	var hour := float((clock.call() as Dictionary)["hour"])
	var n := waiting_count(i, days_now(), hour) - int(_taken.get(i, 0))
	var spots := _spots_of(i)
	var out: Array = []
	for k in mini(n, spots.size()):
		out.append(spots[k])
	return out


## The race took a courier from stand i (he gets on his bike: courier_race.gd draws him riding):
## one fewer waits there; his pose ([at, yaw], the last spot taken), [] when none was waiting.
func take_waiting(i: int) -> Array:
	var w := waiting_at(i)
	if w.is_empty():
		return []
	_taken[i] = int(_taken.get(i, 0)) + 1
	var eye3: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	_wait_tick(Vector2(eye3.x, eye3.z))
	if pedzik_log:
		print("pedzik: a courier waiting at stand %d gets on his bike for the race (%d left there)" % [i, w.size() - 1])
	return w[w.size() - 1]


## "07:30 day 6 · 10 walkers (zone) · 3 at trees · barks 2 · horn lines 1".
func dog_summary() -> String:
	var at_trees := 0
	for d in _dogs:
		at_trees += int(float(d["wait"]) > 0.0)
	var zone := false
	var eye3: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	for z in _zones:
		if Vector2(eye3.x, eye3.z).distance_to(z) < ZONE_R:
			zone = true
	var near := INF
	var near_at := Vector2.ZERO
	for d in _dogs:
		var dd := (d["d2"] as Vector2).distance_to(Vector2(eye3.x, eye3.z))
		if dd < near:
			near = dd
			near_at = d["d2"]
	return "%02d:%02d day %d · %d walkers%s · %d at trees · barks %d · horn lines %d · nearest %s" % [int(_hour), int(fmod(_hour, 1.0) * 60.0),
			_weekday, _dogs.size(), " (Powiśle / Plac Zbawiciela ×2)" if zone else "", at_trees, barks, horn_lines,
			"%.0f m (at %.0f, %.0f)" % [near, near_at.x, near_at.y] if near < INF else "-"]


func life_summary() -> String:
	return "%02d:%02d day %d · riders %d · runners %d · Kolka %s · Hyrax %s · bells %d · Zając %d (paid %d, pacing %.0f m)" % [int(_hour),
			int(fmod(_hour, 1.0) * 60.0), _weekday, _riders.size(), _runners.size(),
			kolka_phase(_hour, _weekday) if kolka_phase(_hour, _weekday) != "" else "off",
			"on" if hyrax_on(_hour, _weekday) else "off", bells, zajac_cheers, zajac_paid, _zajac_m]


## Loop couriers: "01:30 · 6 on the paths, 5 on the kerb · 3 waiting at 2 stands · swerves 4 · hops 1 · lines 1".
func pedzik_summary() -> String:
	var at := {}
	for w: Array in _waiting:
		at[w[0]] = true
	return "%02d:%02d · %d on the paths, %d on the kerb · %d waiting at %d stands · swerves %d · hops %d · lines %d" % [int(_hour),
			int(fmod(_hour, 1.0) * 60.0), _pedziks.size(), _kerbers.size(), _waiting.size(), at.size(), pedzik_swerves,
			pedzik_hops, pedzik_lines]


func _hide_all() -> void:
	if _chair != null:
		_chair.visible = false
	_dog_mm.visible_instance_count = 0
	_dog_mmi.visible = false
	_bike_mm.visible_instance_count = 0
	_bike_mmi.visible = false
	_ped_mm.visible_instance_count = 0
	_ped_mmi.visible = false
	_gbuf.fill(0.0)
	if walkers != null:
		walkers.take_guests(_gbuf)
	_guests_used = 0
	_dock_key = -1
	_full = true


## Keeps `list` at `want` movers of `kind` near the view: the far ones go, new ones start on a
## path SPAWN_R from the view.
func _keep(list: Array[Mover], want: int, kind: String, eye: Vector2, car2 := Vector2.INF) -> void:
	for i in range(list.size() - 1, -1, -1):
		var m: Mover = list[i]
		if m.p2.distance_to(eye) > NEAR_R or (list.size() > want and not _seen(m)) or m.v <= 0.0:
			list.remove_at(i)
			_full = true  # the slots move: the next step writes everything
	var tries := 4
	while list.size() < want and tries > 0:
		tries -= 1
		var m := _spawn(kind, eye)
		if m != null:
			# A path's random point can be where the car is: out of its way from the start.
			if car2 != Vector2.INF:
				_reach2 = maxf(_reach2, 10.5 * 10.5)
				_clear_mover(m, m.kd, car2, Vector2.ZERO, false)
			list.append(m)
			_full = true


func _seen(m: Mover) -> bool:
	if not on_screen.is_valid():
		return false
	return on_screen.call(m.p3, 1.8)


## A new mover on a footway (a dog walker, a runner) or a cycle path (a rider) SPAWN_R from `eye`.
func _spawn(kind: String, eye: Vector2) -> Mover:
	if kind == "kerb":
		return _spawn_kerb(eye)
	var pset := "cyc" if kind == "rider" or (kind == "pedzik" and _rng.randf() >= PEDZIK_FOOT) else "foot"
	var grid: Dictionary = _foot_grid if pset == "foot" else _cyc_grid
	var list: Array[PackedVector2Array] = _foot if pset == "foot" else _cyc
	var a := _rng.randf() * TAU
	var r := _rng.randf_range(SPAWN_R.x, SPAWN_R.y)
	var at := eye + Vector2.from_angle(a) * r
	var c := Vector2i(floori(at.x / CELL), floori(at.y / CELL))
	var cands: PackedInt32Array = grid.get(c, PackedInt32Array())
	if cands.is_empty():
		return null
	var i := cands[_rng.randi() % cands.size()]
	var pts := list[i]
	var cum := _cum_of(pset, i)
	var length := cum[cum.size() - 1]
	if length < 8.0:
		return null
	var m := Mover.new()
	m.kind = kind
	m.kd = DOG_K if kind == "dog" else (RIDER_K if kind == "rider" else (PEDZIK_K if kind == "pedzik" else RUNNER_K))
	m.pset = pset
	m.i = i
	m.s = _rng.randf_range(0.0, length)
	m.dir = 1.0 if _rng.randf() < 0.5 else -1.0
	m.p2 = pts[0]
	m.p3 = Vector3(pts[0].x, 0.0, pts[0].y)
	match kind:
		"dog":
			m.v = _rng.randf_range(0.9, 1.2)
			m.off = _rng.randf_range(-0.4, 0.4)
			m.shape = _rng.randi() % 3
			m.coat = Color(COATS[_rng.randi() % COATS.size()])
			m.shirt = Color(SHIRTS[_rng.randi() % SHIRTS.size()])
			m.tr = _rng.randf() * 0.99
			m.stops = _stops_of(pset, i)
			m.bark_t = -BARK_GAP
			m.d2 = pts[0]
			m.d3 = m.p3
			if _rng.randf() < BIG_SHARE:
				m.big = true
				m.shape = FLUFFY
				m.coat = Color(TINY_COATS[_rng.randi() % TINY_COATS.size()])
				m.shirt = Color(BIG_SHIRTS[_rng.randi() % BIG_SHIRTS.size()])
		"rider":
			m.v = _rng.randf_range(4.0, 6.0)
			if _on_blvd and _rng.randf() < BLVD_FAST:
				m.v = _rng.randf_range(BLVD_V.x, BLVD_V.y)
			m.off = _rng.randf_range(-0.3, 0.3)
			m.shape = rider_kind(_rng.randf())
			m.shirt = Color(SHIRTS[_rng.randi() % SHIRTS.size()])
		"pedzik":
			m.v = _rng.randf_range(PEDZIK_V.x, PEDZIK_V.y)
			m.off = _rng.randf_range(-0.3, 0.3)
			m.want_off = m.off
		"runner":
			m.v = _rng.randf_range(2.7, 3.3)
			m.off = _rng.randf_range(-0.5, 0.5)
			m.shirt = Color(KOLKA_TOPS[_rng.randi() % KOLKA_TOPS.size()] if _rng.randf() < 0.3 else SHIRTS[_rng.randi() % SHIRTS.size()])
			m.tr = _rng.randf() * 0.99
	_place_mover(m)
	return m


## Loop couriers: a kerb rider SPAWN_R from `eye`, on the kerb edge of a lane graph road there (null
## when the cell has none he takes).
func _spawn_kerb(eye: Vector2) -> Mover:
	var r := _rng.randf_range(8.0, 35.0) if kerb_close else _rng.randf_range(SPAWN_R.x, SPAWN_R.y)
	var at := eye + Vector2.from_angle(_rng.randf() * TAU) * r
	var cands: PackedInt32Array = graph.grid.get(LaneGraph.cell_key(at), PackedInt32Array())
	if cands.is_empty():
		return null
	var e := cands[_rng.randi() % cands.size()]
	if not _kerb_edge(e):
		return null
	var m := Mover.new()
	m.kind = "kerb"
	m.kd = PEDZIK_K
	m.pset = "kerb"
	m.v = _rng.randf_range(PEDZIK_V.x, PEDZIK_V.y)
	_kerb_path(m, e, Vector2.INF, 0.0)
	m.s = _rng.randf_range(0.0, m.length)
	_place_mover(m)
	return m


func _kerb_edge(e: int) -> bool:
	return kerb_road(graph.e_lw[e], graph.e_class[e], graph.e_tn[e], graph.e_s1[e] - graph.e_s0[e]) \
			and not _cycle_path_beside(e)


## F, 2026-11-05: a road with a cycle path running beside it (the red one on Marszałkowska) is not a
## kerb rider's: the bikes belong on the path. True when a cycle path within CYCLE_BESIDE m of the
## the kerb rider's line runs about parallel to it at its start, middle or end (cached per edge).
func _cycle_path_beside(e: int) -> bool:
	if _beside_cache.has(e):
		return _beside_cache[e]
	var g := graph
	var found := false
	var off := g.lane_offset(e, g.e_lanes[e] - 1) + g.e_lw[e] * 0.5 - KERB_IN
	var s0 := g.e_s0[e]
	var s1 := g.e_s1[e]
	for t in [0.1, 0.5, 0.9]:
		var s := lerpf(s0, s1, t)
		var at := g.point_at(e, s, off)
		var dir := g.direction(e, s)
		if cycle_path_near(_cyc, _cyc_grid, at, dir, CYCLE_BESIDE):
			found = true
			break
	_beside_cache[e] = found
	return found


## True when a cycle path passes within `reach` m of `at` heading about the same way as `dir`
## (within ~35 degrees, either sense): a path alongside, not one that only crosses.
static func cycle_path_near(cyc: Array, grid: Dictionary, at: Vector2, dir: Vector2, reach: float) -> bool:
	var c0 := Vector2i(floori((at.x - reach) / CELL), floori((at.y - reach) / CELL))
	var c1 := Vector2i(floori((at.x + reach) / CELL), floori((at.y + reach) / CELL))
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			for i: int in grid.get(Vector2i(cx, cy), PackedInt32Array()):
				var pts: PackedVector2Array = cyc[i]
				for j in pts.size() - 1:
					var seg := pts[j + 1] - pts[j]
					if seg.length() < 0.5:
						continue
					var q := Geometry2D.get_closest_point_to_segment(at, pts[j], pts[j + 1])
					if q.distance_to(at) <= reach and absf(seg.normalized().dot(dir)) > 0.82:
						return true
	return false


## Loop couriers: mover `m` onto edge `e`'s kerb line (its outer lane's kerb, KERB_IN in), from s0 to
## s1; from `from` (height `from_h`) first when given: the way across the junction.
func _kerb_path(m: Mover, e: int, from: Vector2, from_h: float) -> void:
	var g := graph
	var off := g.lane_offset(e, g.e_lanes[e] - 1) + g.e_lw[e] * 0.5 - KERB_IN
	var s0 := g.e_s0[e]
	var s1 := g.e_s1[e]
	var pts := PackedVector2Array()
	var h := PackedFloat32Array()
	if from != Vector2.INF:
		pts.append(from)
		h.append(from_h)
	var i := g.seek(e, s0, g.e_first[e])
	pts.append(g.point(e, s0, off, i))
	h.append(_kerb_h(e, s0))
	var last := g.e_first[e] + g.e_count[e] - 1
	for k in range(i + 1, last):
		if g.cum[k] >= s1:
			break
		if g.cum[k] > s0:
			pts.append(g.pts[k] + g.nrm[k] * off)
			h.append(_kerb_h(e, g.cum[k]))
	pts.append(g.point(e, s1, off, g.seek(e, s1, i)))
	h.append(_kerb_h(e, s1))
	var cum := PackedFloat32Array()
	var run := 0.0
	for k in pts.size():
		if k > 0:
			run += pts[k].distance_to(pts[k - 1])
		cum.append(run)
	m.ke = e
	m.i = e
	m.pts = pts
	m.cum = cum
	m.h = h
	m.k = 0
	m.length = maxf(run, 0.01)
	m.cached = true
	m.dir = 1.0


func _kerb_h(e: int, s: float) -> float:
	return graph.height(e, s) if map != null else 0.0


## Loop couriers: a kerb rider at his edge's end takes a road on from its end node (straight on or
## right before a left turn, the U-turn last); none: he stops (and _keep drops him).
func _next_kerb(m: Mover, over: float) -> void:
	var g := graph
	var e := m.ke
	var ahead := g.direction(e, g.e_s1[e])
	var best: Array[int] = []
	var rest: Array[int] = []
	for f in g.node_out[g.e_b[e]]:
		if not _kerb_edge(f):
			continue
		if f != g.e_reverse[e] and ahead.angle_to(g.direction(f, g.e_s0[f])) > -0.6:
			best.append(f)
		else:
			rest.append(f)
	var picks := best if not best.is_empty() else rest
	if picks.is_empty():
		m.v = 0.0
		m.s = m.length
		return
	var f: int = picks[_rng.randi() % picks.size()]
	_kerb_path(m, f, m.pts[m.pts.size() - 1], m.h[m.h.size() - 1])
	m.s = clampf(over, 0.0, m.length)


## The path's running lengths (cached).
func _cum_of(pset: String, i: int) -> PackedFloat32Array:
	var key := i * 2 + int(pset == "cyc")
	if _cum.has(key):
		return _cum[key]
	var pts: PackedVector2Array = (_foot if pset == "foot" else _cyc)[i]
	var cum := PackedFloat32Array()
	var run := 0.0
	for k in pts.size():
		if k > 0:
			run += pts[k].distance_to(pts[k - 1])
		cum.append(run)
	_cum[key] = cum
	return cum


## The ground (or deck) under each corner of a path (cached).
func _heights_of(pset: String, i: int) -> PackedFloat32Array:
	var key := i * 2 + int(pset == "cyc")
	if _heights.has(key):
		return _heights[key]
	var pts: PackedVector2Array = (_foot if pset == "foot" else _cyc)[i]
	var dk := _foot_dk[i] if pset == "foot" else _cyc_dk[i]
	var h := PackedFloat32Array()
	for q in pts:
		h.append(map.deck_height(dk, q.x, q.y) if map != null else 0.0)
	_heights[key] = h
	return h


## A path's tree stops (cached, as _cum_of: a dog walker takes the same paths again).
func _stops_of(pset: String, i: int) -> PackedFloat32Array:
	var key := i * 2 + int(pset == "cyc")
	if _stops.has(key):
		return _stops[key]
	var st := _tree_stops((_foot if pset == "foot" else _cyc)[i], _cum_of(pset, i))
	_stops[key] = st
	return st


## The distances along a footway where a tree stands within TREE_NEAR m of it.
func _tree_stops(pts: PackedVector2Array, cum: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var s := 1.0
	var length := cum[cum.size() - 1]
	var last := -10.0
	var k := 0
	while s < length - 1.0:
		# _point(pts, cum, s, 0.0), its segment search carried on from the last sample.
		while k < cum.size() - 2 and cum[k + 1] < s:
			k += 1
		var seg := maxf(cum[k + 1] - cum[k], 0.001)
		var q := pts[k].lerp(pts[k + 1], clampf((s - cum[k]) / seg, 0.0, 1.0))
		var c := Vector2i(floori(q.x / TREE_CELL), floori(q.y / TREE_CELL))
		for tr: Vector2 in _tree_grid.get(c, PackedVector2Array()):
			if tr.distance_to(q) < TREE_NEAR and s - last > 12.0:
				out.append(s)
				last = s
				break
		s += 2.0
	return out


static func _point(pts: PackedVector2Array, cum: PackedFloat32Array, s: float, off: float) -> Vector2:
	var k := 0
	while k < cum.size() - 2 and cum[k + 1] < s:
		k += 1
	var seg := maxf(cum[k + 1] - cum[k], 0.001)
	var f := clampf((s - cum[k]) / seg, 0.0, 1.0)
	var dir := (pts[k + 1] - pts[k]) / seg
	return pts[k].lerp(pts[k + 1], f) + Vector2(-dir.y, dir.x) * off


## Where mover `m` is: its point (p2, p3 with the height), its heading; a dog's dog (d2, d3).
func _place_mover(m: Mover) -> void:
	# The path's points, lengths and heights ride on the mover (read again when it changes path)
	# and the segment search starts from the last one: no lookups in the 15 Hz step.
	if not m.cached:
		m.pts = (_foot if m.pset == "foot" else _cyc)[m.i]
		m.cum = _cum_of(m.pset, m.i)
		m.h = _heights_of(m.pset, m.i)
		m.k = 0
		m.length = m.cum[m.cum.size() - 1]
		m.cached = true
	var pts := m.pts
	var cum := m.cum
	var h := m.h
	var s := m.s
	var last := cum.size() - 2
	var k := mini(m.k, last)
	while k > 0 and cum[k] > s:
		k -= 1
	while k < last and cum[k + 1] < s:
		k += 1
	m.k = k
	var seg := maxf(cum[k + 1] - cum[k], 0.001)
	var f := clampf((s - cum[k]) / seg, 0.0, 1.0)
	m.ca = cum[k]
	m.cb = cum[k + 1]
	m.udir = (pts[k + 1] - pts[k]) / seg
	m.dy = (h[k + 1] - h[k]) / seg
	m.fast = seg > 0.01 and s >= m.ca and s <= m.cb and (m.kd != DOG_K or m.wait <= 0.0)
	var dir := m.udir * m.dir
	var side := Vector2(-dir.y, dir.x)
	var p := pts[k].lerp(pts[k + 1], f) + side * m.off + m.shove
	var y := lerpf(h[k], h[k + 1], f)
	m.p2 = p
	m.p3 = Vector3(p.x, y, p.y)
	m.yaw = atan2(-dir.x, -dir.y)
	if m.kd == DOG_K:
		var lead := LEAD if m.wait <= 0.0 else 1.0
		var dp := p + dir * lead + side * 0.35 + m.dshove
		m.d2 = dp
		m.d3 = Vector3(dp.x, y, dp.y)


## Moves `m` along its path `dt` s: a dog waits at its trees; at a path's end the mover takes a
## path that joins there (a rider, a runner, a walker), or turns back.
func _advance(m: Mover, dt: float) -> void:
	if m.kd == DOG_K:
		if m.wait > 0.0:
			m.wait -= dt
			return
		var s0 := m.s
		var s1 := s0 + m.v * dt * m.dir
		# A tree stop strictly between s0 and s1 (the stops ascend): a binary search.
		var lo := minf(s0, s1)
		var j := m.stops.bsearch(lo, false)
		if j < m.stops.size() and m.stops[j] > lo and m.stops[j] < maxf(s0, s1):
			m.wait = _rng.randf_range(TREE_WAIT.x, TREE_WAIT.y)
	if m.ke >= 0:
		var ks := m.s + m.v * dt
		if ks > m.length:
			_next_kerb(m, ks - m.length)
		else:
			m.s = ks
		return
	var cum := m.cum if m.cached else _cum_of(m.pset, m.i)
	var length := cum[cum.size() - 1]
	var s := m.s + m.v * dt * m.dir
	if s < 0.0 or s > length:
		var end := 0 if s < 0.0 else 1
		var pts: PackedVector2Array = (_foot if m.pset == "foot" else _cyc)[m.i]
		var q := pts[0] if end == 0 else pts[pts.size() - 1]
		var ends: Dictionary = _foot_ends if m.pset == "foot" else _cyc_ends
		var joins: Array = []
		for code: int in ends.get(Vector2i(roundi(q.x), roundi(q.y)), PackedInt32Array()):
			if code / 2 != m.i:
				joins.append(code)
		if joins.is_empty():
			m.dir = -m.dir
			s = clampf(s, 0.0, length)
		else:
			var code: int = joins[_rng.randi() % joins.size()]
			m.i = code / 2
			m.cached = false
			var c2 := _cum_of(m.pset, m.i)
			if code % 2 == 0:
				s = 0.0
				m.dir = 1.0
			else:
				s = c2[c2.size() - 1]
				m.dir = -1.0
			if m.kd == DOG_K:
				m.stops = _stops_of(m.pset, m.i)
	m.s = s


## The movers' step (15 Hz near the view): each mover along its path and out of the car's way,
## then the dogs', the bikes' and the guests' instances. Within FAR_CAR of the car a mover steps
## every time; else walkers and runners (1-3 m/s: 7-40 cm a step) and far riders every other
## step, and a mover off screen (as the last tick saw it) every OFF_EVERY-th, the time saved up.
func _move(dt: float) -> void:
	var veh: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF, 0.0, false, 0.0, 0.0]
	var vp: Vector3 = veh[0]
	var car2 := Vector2(vp.x, vp.z) if vp != Vector3.INF and not bool(veh[2]) else Vector2.INF
	# Where the car will be by the next step (and a little more): the movers keep clear of that too.
	var ahead := Vector2.ZERO
	_car_v = Vector2.ZERO
	if veh.size() > 5 and veh[5] is Vector3:
		var v: Vector3 = veh[5]
		ahead = Vector2(v.x, v.z) * MOVE_TICK * 2.0
		_car_v = Vector2(v.x, v.z)
	_car_kmh = float(veh[1]) if veh.size() > 1 else 0.0
	var eye3: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var eye := Vector2(eye3.x, eye3.z)
	_move_n += 1
	# Everything is written after the steps when the lists or what is shown changed (the tick
	# says); else each step writes its mover's instances into the slots it already has.
	var full := _full or _shown_now != _shown
	# Clearing matters within CLEAR of the car's way ahead (for a dog its lead and shove more);
	# the met counts within 10 m.
	var reach := maxf(2.0 * CLEAR + ahead.length() + LEAD + 1.0, 10.5)
	_reach2 = reach * reach
	_step_dogs(dt, eye, car2, ahead, full)
	_step_list(_riders, RIDER_K, dt, eye, car2, ahead, full)
	_step_list(_runners, RUNNER_K, dt, eye, car2, ahead, full)
	_step_list(_pedziks, PEDZIK_K, dt, eye, car2, ahead, full)
	_step_list(_kerbers, PEDZIK_K, dt, eye, car2, ahead, full, _pedziks.size())
	# Loop jobs-2: the chair goes where the man is.
	if _shown_now & ARM_BIT and _arm_on and _chair != null:
		var pose := armchair_pose()
		_chair.global_position = pose[0]
		_chair.rotation.y = pose[1]
		_chair.visible = true
	if full:
		_write_all(eye, car2)
		return
	_write_moved(car2)


## The dog walkers' step: along the path (waits at the trees), out of the car's way, the dog's
## and the walker's instances into their slots.
func _step_dogs(dt: float, eye: Vector2, car2: Vector2, ahead: Vector2, full: bool) -> void:
	var dsc := Vector3.ONE * DOG_SCALE
	var moved := false
	var has_car := car2 != Vector2.INF
	var car_r2 := FAR_CAR * FAR_CAR
	for idx in _dogs.size():
		var m: Mover = _dogs[idx]
		# _due inline (walkers: every other step on screen).
		var p0 := m.p2
		if not (has_car and (p0.distance_squared_to(car2) <= car_r2 or m.d2.distance_squared_to(car2) <= car_r2)):
			if (_move_n + idx) % (2 if m.vis else OFF_EVERY) != 0:
				m.acc += dt
				continue
		var mdt := dt + m.acc
		m.acc = 0.0
		var s0 := m.s
		var dir0 := m.dir
		var wait0 := m.wait
		# Near the car (the walker or the dog) the shoves hold (the clearing below keeps them);
		# away from it they fade.
		var near := has_car and (p0.distance_squared_to(car2) < _reach2 or m.d2.distance_squared_to(car2) < _reach2)
		# Walking inside its path and past no tree stop: just along it (_advance for the rest).
		var s1 := s0 + m.v * mdt * dir0
		var stops := m.stops
		var j := stops.bsearch(minf(s0, s1), false)
		if wait0 <= 0.0 and m.cached and s1 >= 0.0 and s1 <= m.length and not (j < stops.size() and stops[j] > minf(s0, s1) and stops[j] < maxf(s0, s1)):
			m.s = s1
		else:
			_advance(m, mdt)
		var fade := not near and (m.shove != Vector2.ZERO or m.dshove != Vector2.ZERO)
		if wait0 > 0.0 and m.wait > 0.0 and not fade and not near:
			continue  # at its tree, nothing moved: its instances stand as written
		if fade:
			var decay := exp(-mdt * 0.8)
			m.shove *= decay
			m.dshove *= decay
			_place_mover(m)
		elif m.fast and m.cached and m.dir == dir0 and m.s >= m.ca and m.s <= m.cb and wait0 <= 0.0 and m.wait <= 0.0:
			# Still on the same segment: slide along it (what _place_mover would give).
			var ds := m.s - s0
			var dv := m.udir * ds
			var p := m.p2 + dv
			m.p2 = p
			var y := m.p3.y + m.dy * ds
			m.p3 = Vector3(p.x, y, p.y)
			var dp := m.d2 + dv
			m.d2 = dp
			m.d3 = Vector3(dp.x, y, dp.y)
		else:
			_place_mover(m)
		if near:
			_clear_mover(m, DOG_K, car2, ahead)
		if not full:
			put(_dog_buf, idx, m.d3, m.yaw, dsc * TINY_DOG if m.big else dsc, m.coat, m.shape)
			_dbox = _dbox.expand(m.d3)
			put(_gbuf, idx, m.p3, m.yaw, BIG_SCALE if m.big else Vector3.ONE, m.shirt, m.tr)
			moved = true
	if moved:
		_dogs_moved = true
		_gdirty = true


## The riders' or the runners' step: along the path (the next path at its end), out of the car's
## way, the instance into its slot (a rider's bike, a runner's guest).
## Loop couriers: `base` is a Pędzik list's first slot in the Pedzik MultiMesh (the kerb riders' come
## after the path riders'); a Pędzik rider dodges the car's path (_dodge_step) and may be in a hop.
func _step_list(list: Array[Mover], kd: int, dt: float, eye: Vector2, car2: Vector2, ahead: Vector2, full: bool, base := 0) -> void:
	var rider := kd == RIDER_K or kd == PEDZIK_K
	var ped := kd == PEDZIK_K
	var slot0 := base if ped else (_dock_n if rider else _dogs.size())
	var moved := false
	var has_car := car2 != Vector2.INF
	var car_r2 := FAR_CAR * FAR_CAR
	var far2 := FAR_MOVE * FAR_MOVE
	# Loop couriers: the car's path matters to a Pędzik within this (his and its way in DODGE_T s).
	var dodge_r := PEDZIK_MISS + (_car_v.length() + PEDZIK_V.y) * DODGE_T
	var dodge_r2 := dodge_r * dodge_r
	for idx in list.size():
		var m: Mover = list[idx]
		# _due inline.
		var p0 := m.p2
		if not (has_car and p0.distance_squared_to(car2) <= car_r2):
			var every := OFF_EVERY
			if m.vis:
				every = 1 if rider and p0.distance_squared_to(eye) <= far2 else 2
			if every > 1 and (_move_n + idx) % every != 0:
				m.acc += dt
				continue
		var mdt := dt + m.acc
		m.acc = 0.0
		var s0 := m.s
		var s1 := s0 + m.v * mdt * m.dir
		var near := has_car and p0.distance_squared_to(car2) < _reach2
		var fade := not near and m.shove != Vector2.ZERO
		# Loop couriers: a Pędzik's dodge (his side offset steering to its target, the hop's clock).
		var steer := false
		if ped:
			if has_car and p0.distance_squared_to(car2) < dodge_r2:
				_dodge_step(m, car2)
			elif m.dodge != DODGE_NONE:
				m.dodge = DODGE_NONE
				m.want_off = m.off if m.ke < 0 else 0.0
			if m.hop > 0.0:
				m.hop = maxf(0.0, m.hop - mdt)
			if m.off != m.want_off:
				m.off = move_toward(m.off, m.want_off, SWERVE_RATE * mdt)
				steer = true
		if m.fast and s1 >= m.ca and s1 <= m.cb and not fade and not steer:
			# Still on the same segment: slide along it (what _place_mover would give).
			m.s = s1
			var ds := s1 - s0
			var p := m.p2 + m.udir * ds
			m.p2 = p
			m.p3 = Vector3(p.x, m.p3.y + m.dy * ds, p.y)
		else:
			if m.cached and s1 >= 0.0 and s1 <= m.length:
				m.s = s1
			else:
				_advance(m, mdt)
			if fade:
				m.shove *= exp(-mdt * 0.8)
			_place_mover(m)
		if near:
			_clear_mover(m, kd, car2, ahead)
		if not full:
			if ped:
				if slot0 + idx < PEDZIK_CAP:
					var hp := m.p3 + Vector3(0.0, hop_height(m.hop), 0.0) if m.hop > 0.0 else m.p3
					put(_ped_buf, slot0 + idx, hp, m.yaw, Vector3.ONE, Color.WHITE, 0.0)
					_ped_box = _ped_box.expand(hp)
			elif rider:
				put(_bike_buf, slot0 + idx, m.p3, m.yaw, Vector3.ONE, m.shirt, m.shape)
				_bbox = _bbox.expand(m.p3)
			else:
				put(_gbuf, slot0 + idx, m.p3, m.yaw, Vector3.ONE, m.shirt, m.tr)
			moved = true
	if moved:
		if ped:
			_peds_moved = true
		elif rider:
			_bikes_moved = true
		else:
			_gdirty = true


## Loop couriers: a Pędzik rider near the car: his closest approach to it over DODGE_T s; within
## PEDZIK_MISS he swerves (a kerb rider SWERVE_OUT past the kerb onto the footway; a path rider is on
## it already and steps aside with the shove) or, with no room there, hops; a near miss may say a line.
## The car clear for CALM_T s: back to his line. _clear_mover stays the backstop (CLEAR of the car).
func _dodge_step(m: Mover, car2: Vector2) -> void:
	var gap := closest_approach(m.p2, m.udir * m.dir * m.v, car2, _car_v, DODGE_T)
	if gap > PEDZIK_MISS:
		if m.dodge != DODGE_NONE:
			m.calm += MOVE_TICK
			if m.calm >= CALM_T:
				m.dodge = DODGE_NONE
				if m.ke >= 0:
					m.want_off = 0.0
		return
	m.calm = 0.0
	if m.dodge != DODGE_NONE:
		return
	var d := dodge(gap, _room(m))
	m.dodge = d
	if d == DODGE_SWERVE:
		pedzik_swerves += 1
		if m.ke >= 0:
			m.want_off = KERB_IN + SWERVE_OUT
	else:
		pedzik_hops += 1
		m.hop = HOP_T
	if pedzik_log:
		print("pedzik: a %s %s at %.0f, %.0f (the car's path %.1f m off, %.0f km/h)" % ["kerb rider" if m.ke >= 0 else "rider",
				"swerves" if d == DODGE_SWERVE else "hops", m.p2.x, m.p2.y, gap, _car_kmh])
	_near_miss(m)


## Loop couriers: room for a kerb rider's swerve: the footway SWERVE_OUT past the kerb is open (no
## roof, no other road), and he is not on a bridge (its railing). A path rider always has it.
func _room(m: Mover) -> bool:
	if m.ke < 0 or graph == null:
		return true
	if graph.e_bridge[m.ke] == 1:
		return false
	var dir := m.udir * m.dir
	var q := m.p2 + Vector2(-dir.y, dir.x) * (KERB_IN + SWERVE_OUT - m.off)
	if map != null and map.roof_height(q.x, q.y) - map.ground_height(q.x, q.y) > 1.0:
		return false
	return graph.snap(q, 1.2).is_empty()


## Loop couriers: a near miss (a dodge with the car at 10 km/h or more) says a `pedzik` line, once
## per PEDZIK_GAP s.
func _near_miss(m: Mover) -> void:
	if not says_near_miss(t, _pedzik_t, _car_kmh):
		return
	_pedzik_t = t
	pedzik_lines += 1
	if dialogue != null:
		dialogue.say_reaction(func() -> Vector3: return m.p3 + Vector3(0, 2.2, 0), "Pędzik", "pedzik", "", 4.0, Color("#c23a7e"), 2.2, false, "near_miss")
	if life_log or pedzik_log:
		print("pedzik: a near miss at %.0f, %.0f: the line" % [m.p2.x, m.p2.y])


## Out of the car's way (only near it: CLEAR of its way ahead, for a dog its lead and shove more),
## and the met counts (within 10 m). A shove moves the walker and its dog by as much (what
## _place_mover gives: both carry it linearly), so no placing again.
func _clear_mover(m: Mover, kd: int, car2: Vector2, ahead: Vector2, count := true) -> void:
	var p := m.p2
	var pd2 := p.distance_squared_to(car2)
	if pd2 < _reach2 or (kd == DOG_K and m.d2.distance_squared_to(car2) < _reach2):
		# The walker's shove moves the dog too: twice round settles both.
		for k in 3:
			var q := m.p2
			var cleared := clear_of_car(q, car2, ahead)
			var moved := cleared != q
			if moved:
				var dq := cleared - q
				m.shove += dq
				m.p2 = cleared
				m.p3 += Vector3(dq.x, 0.0, dq.y)
				if kd == DOG_K:
					m.d2 += dq
					m.d3 += Vector3(dq.x, 0.0, dq.y)
			if kd == DOG_K:
				var dp := m.d2
				var dc := clear_of_car(dp, car2, ahead)
				if dc != dp:
					var dd := dc - dp
					m.dshove += dd
					m.d2 = dc
					m.d3 += Vector3(dd.x, 0.0, dd.y)
					moved = true
			if not moved:
				break
	if count and not m.near and pd2 < 100.0:
		m.near = true
		if kd == DOG_K:
			met_dogs += 1
		elif kd == RIDER_K:
			met_riders += 1
		elif kd == PEDZIK_K:
			met_pedzik += 1


## What is shown besides the movers (the tick's, as bits): the Hyrax cordon, the influencer, the
## ball (its hours, near), Kolka, the docks in view. A change writes everything.
func _shown_bits(eye: Vector2) -> int:
	var hyrax := hyrax_on(_hour, _weekday) and not _hyrax.is_empty() and eye.distance_to(_hyrax["at"]) < NEAR_R + 100.0
	var infl := in_hours([INFLUENCER_HOURS], _hour) and not _infl.is_empty() and eye.distance_to(_infl["at"]) < NEAR_R
	var aport := not _aport.is_empty() and in_hours([APORT_HOURS], _hour) and str(_aport["mem"]["state"]) != "home"
	var aport_near := aport and eye.distance_to(Vector2(_aport["dog"].x, _aport["dog"].z)) < NEAR_R + 100.0
	var docks_in := 0
	for di in _docks.size():
		if eye.distance_to(_docks[di]["at"]) <= NEAR_R:
			docks_in |= 1 << di
	var kolka_on := kolka_phase(_hour, _weekday) != "" and not _kolka.is_empty()
	# Loop jobs-2: the armchair man out and near.
	var arm := 0
	if _arm_on:
		var ap: Vector3 = armchair_pose()[0]
		arm = ARM_BIT if eye.distance_to(Vector2(ap.x, ap.z)) < NEAR_R else 0
	return int(hyrax) | int(infl) << 1 | int(aport) << 2 | int(aport_near) << 3 | int(kolka_on) << 4 | docks_in << 5 | arm


## After the steps that wrote their own slots: the sends, Kolka's half, the Hyrax loop, a carried
## ball, the guests handed over.
func _write_moved(car2: Vector2) -> void:
	if _ball_slot >= 0 and str(_aport["mem"]["state"]) == "carried":
		var veh: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF]
		if veh[0] != Vector3.INF:
			var ball := (veh[0] as Vector3) + Vector3(0, -1.2, 0)
			put(_dog_buf, _ball_slot, ball, 0.0, Vector3(0.6, 0.6, 0.45), Color("#e8f23a"), SQUAT)
			_dbox = _dbox.expand(ball)
			_dogs_moved = true
	if _dogs_moved:
		_dogs_moved = false
		InstanceBuffers.send(_dog_mm.get_rid(), _dog_buf)
		_dog_mm.custom_aabb = _dbox.grow(1.5).expand(_dbox.end + Vector3(0, 1.5, 0))
	if _bikes_moved:
		_bikes_moved = false
		InstanceBuffers.send(_bike_mm.get_rid(), _bike_buf)
		_bike_mm.custom_aabb = _bbox.grow(1.5).expand(_bbox.end + Vector3(0, 2.0, 0))
	if _peds_moved:
		_peds_moved = false
		InstanceBuffers.send(_ped_mm.get_rid(), _ped_buf)
		_ped_mm.custom_aabb = _ped_box.grow(1.5).expand(_ped_box.end + Vector3(0, 2.2, 0))
	if _kolka_slot >= 0:
		_kolka_step(car2)
	if _arm_slot >= 0:
		var pose := armchair_pose()
		put(_gbuf, _arm_slot, pose[0], pose[1], Vector3.ONE, ARM_SHIRT, 0.3)
		_gdirty = true
	if _hyrax_slot >= 0 and _shown & 1:
		_g_n = 0
		_hyrax_loop()
		for i in _g_n:
			put(_gbuf, _hyrax_slot + i, _g_pos[i], _g_yaw[i], Vector3.ONE, _g_shirt[i], _g_tr[i])
		_gdirty = true
	if _gdirty and walkers != null:
		walkers.take_guests(_gbuf)
	_gdirty = false


## Writes every instance: the dogs, the barriers and the ball; the dock's bikes and the riders;
## the guests; and where each sits, for the steps until the next change.
func _write_all(eye: Vector2, car2: Vector2) -> void:
	_full = false
	_dogs_moved = false
	_bikes_moved = false
	_shown = _shown_now
	var hyrax := _shown & 1 != 0
	var infl := _shown & 2 != 0
	var aport_near := _shown & 8 != 0
	var docks_in := (_shown & ~ARM_BIT) >> 5
	_dn = 0
	_dbox = AABB()
	_ball_slot = -1
	var dsc := Vector3.ONE * DOG_SCALE
	for d in _dogs:
		_add_dog(d.d3, d.yaw, dsc * TINY_DOG if d.big else dsc, d.coat, d.shape)
	if hyrax:
		for i in (_hyrax["barriers"] as Array).size():
			var b: Array = _hyrax["barriers"][i]
			_add_dog(b[0], b[1], Vector3.ONE, Color("#f4f1ea") if i % 2 == 0 else Color("#c8282a"), BARRIER)
	if infl:
		var idir: Vector2 = _infl["dir"]
		_add_dog(_infl_fixed(), atan2(idir.y, -idir.x), Vector3(1.0, 0.85, 1.0) * DOG_SCALE, Color("#f7f5ef"), FLUFFY)
	if aport_near:
		_add_dog(_aport["dog"], 0.6, Vector3.ONE, Color("#c9a46b"), FLUFFY)
		var ball: Vector3 = _aport["ball"]
		if str(_aport["mem"]["state"]) == "carried":
			var veh: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF]
			if veh[0] != Vector3.INF:
				ball = (veh[0] as Vector3) + Vector3(0, -1.2, 0)
		if _dn < DOG_CAP:
			_ball_slot = _dn
		_add_dog(ball, 0.0, Vector3(0.6, 0.6, 0.45), Color("#e8f23a"), SQUAT)
	_dog_mm.visible_instance_count = _dn
	if _dn > 0:
		InstanceBuffers.send(_dog_mm.get_rid(), _dog_buf)
		_dog_mm.custom_aabb = _dbox.grow(1.5).expand(_dbox.end + Vector3(0, 1.5, 0))
	_dog_mmi.visible = _dn > 0
	# The bikes: the docks' in view (fixed, written when that set changes) first, then the riders.
	var dock_bikes := 0
	for di in _docks.size():
		if docks_in & (1 << di):
			dock_bikes += int(_docks[di]["n"])
	var n := 0
	var bbox := AABB()
	if dock_bikes + _riders.size() <= BIKE_CAP:
		if docks_in != _dock_key:
			_dock_key = docks_in
			_dock_n = _put_docks(0, docks_in)
			_dock_box = _bike_box
		n = _dock_n
		bbox = _dock_box
		for r in _riders:
			put(_bike_buf, n, r.p3, r.yaw, Vector3.ONE, r.shirt, r.shape)
			bbox = AABB(r.p3, Vector3.ZERO) if n == 0 else bbox.expand(r.p3)
			n += 1
	else:
		# Over the cap: the riders first, as many of the docks' bikes as fit; every step writes all.
		_dock_key = -1
		_full = true
		for r in _riders:
			if n >= BIKE_CAP:
				break
			put(_bike_buf, n, r.p3, r.yaw, Vector3.ONE, r.shirt, r.shape)
			bbox = AABB(r.p3, Vector3.ZERO) if n == 0 else bbox.expand(r.p3)
			n += 1
		var first := n
		n = _put_docks(n, docks_in)
		if n > first:
			bbox = _bike_box if first == 0 else bbox.merge(_bike_box)
	_bbox = bbox
	_bike_mm.visible_instance_count = n
	if n > 0:
		InstanceBuffers.send(_bike_mm.get_rid(), _bike_buf)
		_bike_mm.custom_aabb = bbox.grow(1.5).expand(bbox.end + Vector3(0, 2.0, 0))
	_bike_mmi.visible = n > 0
	# Loop MW-2: the Pędzik couriers, their own MultiMesh; loop couriers: the kerb riders after the
	# path riders, then the couriers waiting at the stands (standing beside their bikes).
	var pn := 0
	var pbox := AABB()
	for list: Array[Mover] in [_pedziks, _kerbers]:
		for r in list:
			if pn >= PEDZIK_CAP:
				break
			var hp := r.p3 + Vector3(0.0, hop_height(r.hop), 0.0) if r.hop > 0.0 else r.p3
			put(_ped_buf, pn, hp, r.yaw, Vector3.ONE, Color.WHITE, 0.0)
			pbox = AABB(hp, Vector3.ZERO) if pn == 0 else pbox.expand(hp)
			pn += 1
	for w: Array in _waiting:
		if pn >= PEDZIK_CAP:
			break
		put(_ped_buf, pn, w[1], float(w[2]), Vector3.ONE, Color.WHITE, Props.PEDZIK_STANDING)
		pbox = AABB(w[1], Vector3.ZERO) if pn == 0 else pbox.expand(w[1])
		pn += 1
	_ped_box = pbox
	_ped_mm.visible_instance_count = pn
	if pn > 0:
		InstanceBuffers.send(_ped_mm.get_rid(), _ped_buf)
		_ped_mm.custom_aabb = pbox.grow(1.5).expand(pbox.end + Vector3(0, 2.2, 0))
	_ped_mmi.visible = pn > 0
	_write_guests(eye, car2, hyrax, infl, aport_near)


## The docks in `mask` (bit per dock) as parked bikes from instance `from`, up to BIKE_CAP: the
## instance after the last; their box in _bike_box.
func _put_docks(from: int, mask: int) -> int:
	var n := from
	_bike_box = AABB()
	for di in _docks.size():
		if mask & (1 << di) == 0:
			continue
		var dock: Dictionary = _docks[di]
		var dir: Vector2 = dock["dir"]
		for k in int(dock["n"]):
			if n >= BIKE_CAP:
				break
			var q: Vector2 = (dock["at"] as Vector2) + dir * (k - int(dock["n"]) * 0.5) * 0.75
			var at := Vector3(q.x, _ground(q), q.y)
			put(_bike_buf, n, at, atan2(dir.y, -dir.x), Vector3.ONE, Color.WHITE, PARKED)
			_bike_box = AABB(at, Vector3.ZERO) if n == from else _bike_box.expand(at)
			n += 1
	return n


## The influencer's dog's place (its ground read once).
func _infl_fixed() -> Vector3:
	if not _infl.has("p3"):
		var ia: Vector2 = _infl["at"]
		_infl["p3"] = Vector3(ia.x, _ground(ia), ia.y)
	return _infl["p3"]


func _add_dog(at: Vector3, yaw: float, sc: Vector3, paint: Color, shape: int) -> void:
	if _dn >= DOG_CAP:
		return
	put(_dog_buf, _dn, at, yaw, sc, paint, shape)
	_dbox = AABB(at, Vector3.ZERO) if _dn == 0 else _dbox.expand(at)
	_dn += 1


## One guest figure into the step's packed lists.
func _fig(at: Vector3, yaw: float, shirt: Color, tr: float, sc := Vector3.ONE) -> void:
	if _g_n >= _g_pos.size():
		var cap := _g_pos.size() + 32
		_g_pos.resize(cap)
		_g_yaw.resize(cap)
		_g_shirt.resize(cap)
		_g_tr.resize(cap)
		_g_sc.resize(cap)
	_g_pos[_g_n] = at
	_g_yaw[_g_n] = yaw
	_g_shirt[_g_n] = shirt
	_g_tr[_g_n] = tr
	_g_sc[_g_n] = sc
	_g_n += 1


## The people as pedestrians.gd's guests: the walkers, runners, Kolka, the Hyrax loop and its
## marshals, the photographers, the ball's owner; the nearest GUESTS when there are more. Built
## in packed lists and written in one call.
func _write_guests(eye: Vector2, car2: Vector2, hyrax: bool, infl: bool, aport: bool) -> void:
	if walkers == null:
		return
	_g_n = 0
	_kolka_slot = -1
	_hyrax_slot = -1
	_arm_slot = -1
	if _shown & ARM_BIT and _arm_on:
		var pose := armchair_pose()
		_arm_slot = _g_n
		_fig(pose[0], pose[1], ARM_SHIRT, 0.3)
	for d in _dogs:
		_fig(d.p3, d.yaw, d.shirt, d.tr, BIG_SCALE if d.big else Vector3.ONE)
	for r in _runners:
		_fig(r.p3, r.yaw, r.shirt, r.tr)
	if kolka_phase(_hour, _weekday) != "" and not _kolka.is_empty():
		_kolka_slot = _g_n
		_kolka_figs(car2)
	if hyrax:
		var c: Vector2 = _hyrax["at"]
		_hyrax_slot = _g_n
		_hyrax_loop()
		if not _hyrax.has("marshals"):
			var ms: Array = []
			for k in 4:
				var q := c + Vector2.from_angle(TAU * k / 4.0 + 0.4) * (CORDON_R + 1.5)
				ms.append([Vector3(q.x, _ground(q), q.y), atan2(-(c - q).x, -(c - q).y)])
			_hyrax["marshals"] = ms
		for f: Array in _hyrax["marshals"]:
			_fig(f[0], f[1], Color("#e8f23a"), 0.1)
	if infl:
		if not _infl.has("crew"):
			var ia: Vector2 = _infl["at"]
			var idir: Vector2 = _infl["dir"]
			var side := Vector2(-idir.y, idir.x)
			var crew: Array = []
			for k in 3:
				var q := ia + side * 1.8 + idir * (k - 1) * 1.1
				crew.append([Vector3(q.x, _ground(q), q.y), atan2(-(ia - q).x, -(ia - q).y)])
			_infl["crew"] = crew
		var crew: Array = _infl["crew"]
		for k in 3:
			_fig(crew[k][0], crew[k][1], Color(SHIRTS[(k * 3 + 1) % SHIRTS.size()]), 0.4)
	if aport and eye.distance_to(Vector2(_aport["dog"].x, _aport["dog"].z)) < NEAR_R + 100.0:
		var dg: Vector3 = _aport["dog"]
		_fig(dg + Vector3(1.0, 0.0, 0.6), 0.6, Color("#2f6fb5"), 0.3)
	var n := mini(_g_n, Pedestrians.GUESTS)
	if _g_n > Pedestrians.GUESTS:
		# More than fit: no fixed slots, so every step writes all.
		_full = true
		_kolka_slot = -1
		_hyrax_slot = -1
		_arm_slot = -1
		# The nearest GUESTS, in order of distance (stable as before: a sort of the indices).
		var order: Array[int] = []
		var dist := PackedFloat32Array()
		dist.resize(_g_n)
		for i in _g_n:
			order.append(i)
			dist[i] = Vector2(_g_pos[i].x, _g_pos[i].z).distance_squared_to(eye)
		order.sort_custom(func(a: int, b: int) -> bool: return dist[a] < dist[b])
		for i in n:
			var o := order[i]
			put(_gbuf, i, _g_pos[o], _g_yaw[o], _g_sc[o], _g_shirt[o], _g_tr[o])
	else:
		for i in n:
			put(_gbuf, i, _g_pos[i], _g_yaw[i], _g_sc[i], _g_shirt[i], _g_tr[i])
	for i in range(n, _guests_used):
		for k in 12:
			_gbuf[i * 16 + k] = 0.0
	walkers.take_guests(_gbuf)
	_gdirty = false
	_guests_used = n


## The Hyrax loop's runners into the step's guest lists.
func _hyrax_loop() -> void:
	var c: Vector2 = _hyrax["at"]
	var tt := t * HYRAX_V / HYRAX_LOOP_R
	for i in HYRAX_RUNNERS:
		var a := tt + TAU * i / HYRAX_RUNNERS
		var q := c + Vector2.from_angle(a) * (HYRAX_LOOP_R + (i % 2) * 1.2)
		var tangent := Vector2.from_angle(a + PI * 0.5)
		_fig(Vector3(q.x, _ground(q), q.y), atan2(-tangent.x, -tangent.y), Color(KOLKA_TOPS[i % KOLKA_TOPS.size()] if i % 3 else SHIRTS[i % SHIRTS.size()]), 0.2)


func _ground(p: Vector2) -> float:
	return map.deck_height(-1, p.x, p.y) if map != null else 0.0


# --- Kolka and the Zając -----------------------------------------------------------------------

## Where along Kolka's route `s` (0..2L, out and back) is: [point, heading].
func _kolka_at(s: float) -> Array:
	var length: float = _kolka["len"]
	var back := s > length
	var u := 2.0 * length - s if back else s
	var pts: PackedVector2Array = _kolka["pts"]
	var cum: PackedFloat32Array = _kolka["cum"]
	# Binary search: the segment holding u (20 members a step on a 166-point route).
	var k := clampi(cum.bsearch(u, true) - 1, 0, cum.size() - 2)
	var seg := maxf(cum[k + 1] - cum[k], 0.001)
	var f := clampf((u - cum[k]) / seg, 0.0, 1.0)
	var dir := (pts[k + 1] - pts[k]) / seg * (-1.0 if back else 1.0)
	var h: PackedFloat32Array = _kolka["h"]
	var p := pts[k].lerp(pts[k + 1], f)
	return [Vector3(p.x, lerpf(h[k], h[k + 1], f), p.y), dir]


func _kolka_centre() -> Vector2:
	if _kolka.is_empty():
		return Vector2.INF
	var a: Array = _kolka_at(kolka_run(_hour, float(_kolka["len"])))
	return Vector2((a[0] as Vector3).x, (a[0] as Vector3).z)


## The club's members now: gathered at the start, running in rows of three, back at the start.
func kolka_figures(car2: Vector2) -> Array:
	var cal: Dictionary = calendar.call() if calendar.is_valid() else {}
	_kolka_members(int(cal.get("date", 0)))
	var out: Array = []
	var phase := kolka_phase(_hour, _weekday)
	var length: float = _kolka["len"]
	var lead := kolka_run(_hour, length)
	var still := phase == "gather" or lead >= 2.0 * length
	for m: Dictionary in _kolka["members"]:
		if still:
			var a: Array = _kolka_at(0.0)
			var q := Vector2((a[0] as Vector3).x, (a[0] as Vector3).z) + Vector2.from_angle(float(m["a"])) * (1.5 + int(m["row"]) * 0.5)
			if car2 != Vector2.INF:
				q = clear_of_car(q, car2)
			out.append([Vector3(q.x, (a[0] as Vector3).y, q.y), float(m["a"]) + PI, m["shirt"], m["tr"]])
			continue
		var s := clampf(lead - int(m["row"]) * 1.3 - float(m["back"]), 0.0, 2.0 * length)
		var a: Array = _kolka_at(s)
		var dir: Vector2 = a[1]
		var q := Vector2((a[0] as Vector3).x, (a[0] as Vector3).z) + Vector2(-dir.y, dir.x) * float(m["lat"])
		if car2 != Vector2.INF:
			q = clear_of_car(q, car2)
		out.append([Vector3(q.x, (a[0] as Vector3).y, q.y), atan2(-dir.x, -dir.y), m["shirt"], m["tr"]])
	return out


## Kolka's members into the step's guest lists (kolka_figures without its arrays; the date as the
## last tick read it), each also kept in _kf_pos and _kf_yaw.
func _kolka_figs(car2: Vector2) -> void:
	_kolka_members(_date)
	var n := _km_back.size()
	_kf_pos.resize(n)
	_kf_yaw.resize(n)
	var lead := kolka_run(_hour, _kp_len)
	var still := kolka_phase(_hour, _weekday) == "gather" or lead >= 2.0 * _kp_len
	for j in n:
		_kolka_member(j, car2, lead, still)
		_fig(_kf_pos[j], _kf_yaw[j], _km_shirt[j], _km_tr[j])


## Between full writes: half the members a step (7.5 Hz each, as the runners), every one within
## FAR_CAR of the car; written straight to their guest slots.
func _kolka_step(car2: Vector2) -> void:
	var n := _km_back.size()
	if n != _kf_pos.size():
		_full = true
		return
	var has_car := car2 != Vector2.INF
	var car_r2 := FAR_CAR * FAR_CAR
	var lead := kolka_run(_hour, _kp_len)
	var still := kolka_phase(_hour, _weekday) == "gather" or lead >= 2.0 * _kp_len
	for j in range((_move_n + 1) % 2, n, 2):
		_kolka_member(j, car2, lead, still)
		put(_gbuf, _kolka_slot + j, _kf_pos[j], _kf_yaw[j], Vector3.ONE, _km_shirt[j], _km_tr[j])
	_gdirty = true
	if has_car:
		for j in range(_move_n % 2, n, 2):
			var at := _kf_pos[j]
			if Vector2(at.x, at.z).distance_squared_to(car2) <= car_r2:
				_kolka_member(j, car2, lead, still)
				put(_gbuf, _kolka_slot + j, _kf_pos[j], _kf_yaw[j], Vector3.ONE, _km_shirt[j], _km_tr[j])


## Member `j` now, into _kf_pos[j] and _kf_yaw[j]: gathered at the start, running in rows of
## three, back at the start; out of the car's way.
func _kolka_member(j: int, car2: Vector2, lead: float, still: bool) -> void:
	var pts := _kp_pts
	var h := _kp_h
	if still:
		var q0 := pts[0] + Vector2.from_angle(_km_a[j]) * _km_ring[j]
		if car2 != Vector2.INF:
			q0 = clear_of_car(q0, car2)
		_kf_pos[j] = Vector3(q0.x, h[0], q0.y)
		_kf_yaw[j] = _km_a[j] + PI
		return
	var cum := _kp_cum
	var length := _kp_len
	var s := clampf(lead - _km_back[j], 0.0, 2.0 * length)
	var back := s > length
	var u := 2.0 * length - s if back else s
	var k := clampi(cum.bsearch(u, true) - 1, 0, cum.size() - 2)
	var seg := maxf(cum[k + 1] - cum[k], 0.001)
	var f := clampf((u - cum[k]) / seg, 0.0, 1.0)
	var dir := (pts[k + 1] - pts[k]) / seg * (-1.0 if back else 1.0)
	var q := pts[k].lerp(pts[k + 1], f) + Vector2(-dir.y, dir.x) * _km_lat[j]
	if car2 != Vector2.INF:
		q = clear_of_car(q, car2)
	_kf_pos[j] = Vector3(q.x, lerpf(h[k], h[k + 1], f), q.y)
	_kf_yaw[j] = atan2(-dir.x, -dir.y)


## The club's members for `date` (made when the date changes).
func _kolka_members(date: int) -> void:
	if int(_kolka["date"]) != date or (_kolka["members"] as Array).is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = date * 31 + 7
		var members: Array = []
		for k in roundi(kolka_size(date) * minf(amount, 1.5)):
			members.append({"row": k / 3, "lat": (k % 3 - 1) * 0.9 + rng.randf_range(-0.15, 0.15), "back": rng.randf_range(-0.3, 0.3),
					"shirt": Color(KOLKA_TOPS[rng.randi() % KOLKA_TOPS.size()]), "tr": rng.randf() * 0.99, "a": rng.randf() * TAU})
		_kolka["members"] = members
		_kolka["date"] = date
		# The same, packed for the 15 Hz step: each one's distance behind the lead, its side,
		# its place in the gathering, its colours; the route's arrays at hand.
		var n := members.size()
		_km_back.resize(n)
		_km_lat.resize(n)
		_km_a.resize(n)
		_km_ring.resize(n)
		_km_shirt.resize(n)
		_km_tr.resize(n)
		for j in n:
			var m: Dictionary = members[j]
			_km_back[j] = int(m["row"]) * 1.3 + float(m["back"])
			_km_lat[j] = m["lat"]
			_km_a[j] = m["a"]
			_km_ring[j] = 1.5 + int(m["row"]) * 0.5
			_km_shirt[j] = m["shirt"]
			_km_tr[j] = m["tr"]
		_kp_pts = _kolka["pts"]
		_kp_cum = _kolka["cum"]
		_kp_h = _kolka["h"]
		_kp_len = _kolka["len"]


## The Zając at 2 Hz: the car beside the club (lateral ≤ 25 m from its run), 9-14 km/h, 600 m.
func _zajac_tick(vp: Vector3, kmh: float, flying: bool, step: float) -> void:
	if vp == Vector3.INF or flying:
		_zajac_last = Vector3.INF
		return
	var length: float = _kolka["len"]
	var lead := kolka_run(_hour, length)
	if lead <= 0.0 or lead >= 2.0 * length:
		return
	var rows := ceili(kolka_size(int(_kolka["date"])) / 3.0)
	var front: Array = _kolka_at(lead)
	var back: Array = _kolka_at(maxf(lead - rows * 1.3, 0.0))
	var a := Vector2((front[0] as Vector3).x, (front[0] as Vector3).z)
	var b := Vector2((back[0] as Vector3).x, (back[0] as Vector3).z)
	var p := Vector2(vp.x, vp.z)
	var lateral := Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p)
	var moved := 0.0 if _zajac_last == Vector3.INF else Vector2(vp.x - _zajac_last.x, vp.z - _zajac_last.z).length()
	_zajac_last = vp
	var mem := {"m": _zajac_m, "grace": _zajac_off}
	var done := zajac_step(mem, lateral, kmh, moved, step)
	_zajac_m = float(mem["m"])
	_zajac_off = float(mem["grace"])
	if not done:
		return
	zajac_cheers += 1
	var anchor := func() -> Vector3: return (_kolka_at(kolka_run(_hour, length))[0] as Vector3) + Vector3(0, 2.0, 0)
	if dialogue != null:
		dialogue.say_ambient(anchor, "Kolka", "runners", "zajac", 4.0, BUBBLE, 2.2, true)
	if sfx != null and car != null:
		sfx.horn(car.global_position + car.global_transform.basis.z * 18.0)
	var paid := _fire("e29")
	zajac_paid += int(paid)
	if life_log or zajac_rig:
		print("life: zajac %s after 600 m beside Kolka at %.0f km/h (%.0f m lateral)" % [
				"paid +40 respect (E29)" if paid else "cheered (E29 found already: no pay)", kmh, lateral])


## Kolka's line now and then and the running watch's beep as it passes the view.
func _kolka_talk(eye: Vector2, step: float) -> void:
	var c := _kolka_centre()
	if c == Vector2.INF:
		return
	var d := c.distance_to(eye)
	if d < 20.0 and not bool(_kolka["beeped"]) and kolka_phase(_hour, _weekday) == "run":
		_kolka["beeped"] = true
		if sfx != null:
			sfx.play_at("watch_beep", Vector3(c.x, _ground(c) + 1.2, c.y))
	elif d > 60.0:
		_kolka["beeped"] = false
	_kolka["chat"] = float(_kolka["chat"]) - step
	if float(_kolka["chat"]) <= 0.0 and d < 80.0:
		_kolka["chat"] = _rng.randf_range(40.0, 70.0)
		if dialogue != null:
			var anchor := func() -> Vector3:
				var q := _kolka_centre()
				return Vector3(q.x, _ground(q) + 2.0, q.y) if q != Vector2.INF else Vector3.INF
			dialogue.say_ambient(anchor, "Kolka", "runners", "", 4.0, BUBBLE, 2.2)


## --zajac --autopilot: the car beside the club's front at its pace, 10 m to the side.
func _zajac_rig_frame(_dt: float) -> void:
	if car == null or _kolka.is_empty() or kolka_phase(_hour, _weekday) != "run":
		return
	var length: float = _kolka["len"]
	var lead := kolka_run(_hour, length)
	if lead >= 2.0 * length:
		return
	var a: Array = _kolka_at(maxf(lead - 2.0, 0.0))
	var dir: Vector2 = a[1]
	var q := Vector2((a[0] as Vector3).x, (a[0] as Vector3).z) + Vector2(dir.y, -dir.x) * 10.0
	car.collision_mask = 0
	car.global_position = Vector3(q.x, map.ground_height(q.x, q.y) + 0.05, q.y)
	car.rotation.y = atan2(-dir.x, -dir.y)
	car.set("vel", Vector3(dir.x, 0.0, dir.y) * KOLKA_V)


# --- the dogs' horn, the influencer, the ball ---------------------------------------------------

## A horn sounded at `at` (an AI car held up or bumped: main.gd connects traffic.gd's signals):
## the dogs within 15 m bark, and one walker says a horn line at most once a minute.
func horn(at: Vector3) -> void:
	var a2 := Vector2(at.x, at.z)
	var said := false
	for d in _dogs:
		if (d["d2"] as Vector2).distance_to(a2) > HORN_R:
			continue
		var r := horn_reaction(t, float(d["bark_t"]), _line_t)
		if bool(r[0]):
			d["bark_t"] = t
			barks += 1
			if sfx != null:
				sfx.play_at(BARKS[int(d["shape"])], d["d3"])
			if dogs_log:
				print("dogs: a horn at %.0f, %.0f: a %s dog barks" % [at.x, at.z, ["long", "squat", "fluffy"][int(d["shape"])]])
		if bool(r[1]) and not said:
			said = true
			_line_t = t
			horn_lines += 1
			var m := d
			if dialogue != null:
				dialogue.say_reaction(func() -> Vector3: return (m["p3"] as Vector3) + Vector3(0, 2.0, 0), "", "dog_walkers", "horn", 4.0, BUBBLE, 2.2, true)
			if dogs_log:
				print("dogs: the walker's horn line")


## F's ask: a big guy with a tiny dog says his `tiny` line to a slow car within TINY_NEAR, at most
## once per TINY_GAP s.
func _tiny_tick(p: Vector2, kmh: float) -> void:
	if kmh >= TINY_KMH or t - _tiny_t < TINY_GAP:
		return
	for d in _dogs:
		if not d.big or d.p2.distance_to(p) > TINY_NEAR:
			continue
		_tiny_t = t
		tiny_lines += 1
		var m := d
		if dialogue != null:
			dialogue.say_reaction(func() -> Vector3: return m.p3 + Vector3(0, 2.3, 0), "", "dog_walkers", "tiny", 4.0, BUBBLE, 2.2, true)
		if dogs_log:
			print("dogs: a big guy's tiny-dog line")
		return


## The influencer dog: its photographers' shutter now and then, the walker's line to a slow car.
func _infl_tick(p: Vector2, kmh: float, flying: bool, step: float) -> void:
	var at: Vector2 = _infl["at"]
	var d := p.distance_to(at)
	_shutter_t -= step
	if d < 60.0 and _shutter_t <= 0.0 and sfx != null:
		_shutter_t = _rng.randf_range(5.0, 11.0)
		sfx.play_at("phone_shutter", Vector3(at.x, _ground(at) + 1.4, at.y))
	_infl["line_t"] = float(_infl["line_t"]) - step
	if not flying and d < 25.0 and kmh < 10.0 and float(_infl["line_t"]) <= 0.0:
		_infl["line_t"] = LINE_GAP
		if dialogue != null:
			var spot := Vector3(at.x, _ground(at) + 2.2, at.y)
			dialogue.say_ambient(func() -> Vector3: return spot, "", "dog_walkers", "influencer", 4.0, BUBBLE, 2.2, true)


## The ball on the Kopernik roof (E16): a call when the helicopter comes near, picked up within
## 4 m, dropped within 8 m of the dog.
func _aport_tick(veh: Array) -> void:
	var dog: Vector3 = _aport["dog"]
	var vp: Vector3 = veh[0]
	if not bool(veh[2]) or vp == Vector3.INF:
		return
	if not bool(_aport["told"]) and Vector2(vp.x - dog.x, vp.z - dog.z).length() < 300.0:
		_aport["told"] = true
		if hud != null:
			hud.ambient_toast("Pies zgubił piłkę na dachu Kopernika", "A dog's ball is up on the Kopernik roof")
	var mem: Dictionary = _aport["mem"]
	var was := str(mem["state"])
	if aport_step(mem, vp, float(veh[4]), _aport["ball"], dog):
		if dialogue != null:
			var spot := dog + Vector3(1.0, 2.2, 0.6)
			dialogue.say_ambient(func() -> Vector3: return spot, "", "dog_walkers", "", 4.0, BUBBLE, 2.2)
		if sfx != null:
			sfx.play_at("bark_big", dog)
		_fire("e16")
		if life_log:
			print("life: the ball is back with the dog (E16)")
	elif was != str(mem["state"]) and life_log:
		print("life: the ball is in the helicopter")


# --- the riders: the bell, Rowerilo followed ---------------------------------------------------

## A car parked on a cycle path for 3 s: a bell and a `cyclists` `lane` line (once per 45 s).
func _bell_tick(p: Vector2, kmh: float, step: float) -> void:
	if kmh >= 1.0 or not _on_cycle_path(p):
		_bell_hold = 0.0
		return
	_bell_hold += step
	if _bell_hold < BELL_HOLD or t - _bell_t < BELL_GAP:
		return
	_bell_t = t
	bells += 1
	var from := Vector3(p.x, _ground(p), p.y)
	var best := 60.0
	for r in _riders:
		var d := (r["p2"] as Vector2).distance_to(p)
		if d < best:
			best = d
			from = r["p3"]
	if sfx != null:
		sfx.play_at("bike_bell", from + Vector3(0, 1.0, 0))
	if dialogue != null:
		var at := from
		dialogue.say_reaction(func() -> Vector3: return at + Vector3(0, 2.2, 0), "", "cyclists", "lane", 4.0, BUBBLE, 2.2, true)
	if life_log:
		print("life: the car parked on a cycle path at %.0f, %.0f for %.0f s: the bell" % [p.x, p.y, _bell_hold])


func _on_cycle_path(p: Vector2) -> bool:
	var c := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	for i: int in _cyc_grid.get(c, PackedInt32Array()):
		var pts := _cyc[i]
		for j in pts.size() - 1:
			if Geometry2D.get_closest_point_to_segment(p, pts[j], pts[j + 1]).distance_to(p) <= BELL_NEAR + _cyc_w[i] * 0.5:
				return true
	return false


## E28: a Rowerilo rider with the car behind it (within 25 m, at 8 km/h or more) for 400 m docks
## (its 19:59 line) and leaves.
func _follow_tick(p: Vector2, kmh: float, step: float) -> void:
	for i in range(_riders.size() - 1, -1, -1):
		var r: Mover = _riders[i]
		if int(r["shape"]) != ROWERILO:
			continue
		var q: Vector2 = r["p2"]
		var behind := (p - q).dot(Vector2.from_angle(-float(r["yaw"]) - PI * 0.5)) < 0.0
		if q.distance_to(p) <= FOLLOW_R and kmh >= FOLLOW_KMH and behind:
			r["follow"] = float(r["follow"]) + float(r["v"]) * step
		elif q.distance_to(p) > FOLLOW_R * 1.6:
			r["follow"] = 0.0
		if float(r["follow"]) >= FOLLOW_M:
			if dialogue != null:
				var at: Vector3 = r["p3"]
				dialogue.say_ambient(func() -> Vector3: return at + Vector3(0, 2.2, 0), "", "cyclists", "", 4.0, BUBBLE, 2.2)
			var paid := _fire("e28")
			if life_log:
				print("life: a Rowerilo rider followed 400 m docks%s" % (" (E28)" if paid else ""))
			_riders.remove_at(i)


# --- Hyrax ---------------------------------------------------------------------------------

func _hyrax_talk(step: float) -> void:
	_hyrax["chat"] = float(_hyrax["chat"]) - step
	_hyrax["whistle"] = float(_hyrax["whistle"]) - step
	var c: Vector2 = _hyrax["at"]
	if float(_hyrax["chat"]) <= 0.0:
		_hyrax["chat"] = _rng.randf_range(40.0, 60.0)
		if dialogue != null:
			var q := c + Vector2.from_angle(t * HYRAX_V / HYRAX_LOOP_R) * HYRAX_LOOP_R
			var spot := Vector3(q.x, _ground(q) + 2.0, q.y)
			dialogue.say_ambient(func() -> Vector3: return spot, "", "runners", "hyrax", 4.0, BUBBLE, 2.2, true)
	if float(_hyrax["whistle"]) <= 0.0:
		_hyrax["whistle"] = _rng.randf_range(60.0, 90.0)
		if sfx != null:
			sfx.play_at("whistle", Vector3(c.x, _ground(c) + 1.5, c.y))


## Podwózka's `hurry` destination now (rides.gd `hurry_to`): the Hyrax forecourt on a Saturday
## morning, else INF.
func hurry_target() -> Vector2:
	if _hyrax.is_empty() or not hurry_to_stadium(_hour, _weekday):
		return Vector2.INF
	return _hyrax["at"]


# --- the soak --------------------------------------------------------------------------------

## --life-soak: every frame, any dog, walker, rider or runner inside the car's footprint counts;
## every 15 s the car heads for the nearest dog or rider (or the next busy place) at 25 km/h,
## through whatever is in the way (as the autopilot does).
func _soak_frame(dt: float) -> void:
	if car == null:
		return
	var cp := Vector2(car.global_position.x, car.global_position.z)
	var yaw: float = car.rotation.y
	for list: Array[Mover] in [_dogs, _riders, _runners, _pedziks, _kerbers]:
		for m in list:
			for key in (["p2", "d2"] if m["kind"] == "dog" else ["p2"]):
				var q: Vector2 = m[key]
				closest = minf(closest, q.distance_to(cp))
				if overlaps_car(q, cp, yaw):
					overlaps += 1
					if overlaps <= 5:
						print("life: OVERLAP %s at %.1f, %.1f, %.2f m from the car's middle" % [m["kind"], q.x, q.y, q.distance_to(cp)])
	_soak_t -= dt
	if _soak_t <= 0.0 or _soak_target == Vector2.INF or cp.distance_to(_soak_target) < 2.0:
		_soak_t = 15.0
		_soak_target = Vector2.INF
		var best := 120.0
		for list: Array[Mover] in [_dogs, _riders]:
			for m in list:
				var d := (m["p2"] as Vector2).distance_to(cp)
				if d < best and d > 4.0:
					best = d
					_soak_target = (m["d2"] if m["kind"] == "dog" else m["p2"])
		if _soak_target == Vector2.INF:
			var spots: Array[Vector2] = []
			for id in ["plac_zbawiciela", "wiralek_tamka", "rowerilo_dock", "merdak", "bulwary"]:
				if _at.has(id):
					spots.append(_at[id])
			if not spots.is_empty():
				_soak_zone = (_soak_zone + 1) % spots.size()
				_soak_target = spots[_soak_zone]
	if _soak_target == Vector2.INF:
		return
	var to := _soak_target - cp
	var d := to.length()
	car.collision_mask = 0
	car.set("vel", Vector3.ZERO)
	if d > 0.5:
		var stepm := minf(d, 7.0 * dt)
		var np := cp + to / d * stepm
		car.global_position = Vector3(np.x, map.ground_height(np.x, np.y) + 0.05, np.y)
		car.rotation.y = atan2(-to.x, -to.y)
		car.set("vel", Vector3(to.x / d, 0.0, to.y / d) * 7.0)


func _exit_tree() -> void:
	if soak:
		print("life: soak done %.1f min · dogs met %d · riders met %d · overlaps %d · closest %s" % [t / 60.0, met_dogs, met_riders,
				overlaps, "%.2f m" % closest if closest < INF else "-"])
	if _index_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_index_task)
		_index_task = -1
