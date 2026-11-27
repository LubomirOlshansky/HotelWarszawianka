extends "res://scripts/activity.gd"
## "Wiślana Szprotka": the boat race down the Vistula (docs/design/boat-race.md; F's ask 2026-11-06:
## a friend phones and asks for a boat race through rings; miss three and you lose, then go again
## or quit; fun rivals and physics).
##
## Szymek phones (daytime, once the player has driven a while, then every CALL_COOL s; or the
## pill WYŚCIG ŁODZI by the start pontoon): ODBIERZ, then PŁYNĘ! puts a beacon on the pontoon at
## the mouth of Port Czerniakowski. Stop there and the car stays on the bank: the player takes the
## runabout "Szprotka" on the grid with three rivals (Szymek's red runabout, Pan Zdzisiek's old
## "Złota Rybka", Kamil's jet ski), 3-2-1, and races 3.1 km downstream under four bridges through
## 25 rings to the finish arch below Most Śląsko-Dąbrowski.
##
## Rules: every ring must be passed through (gold rings are extra: a boost, no penalty). A ring
## passed outside its opening, or left behind, is a miss (PUDŁO); the third miss is ODPADASZ!
## with JESZCZE RAZ (the grid again) or WYJDŹ (back to the car). Rings in a row build the rhythm
## (RYTM, +3 % top speed a ring, up to +15 %; a miss resets it). The rivals play by the same rules
## and can drop out. A sand barge pushed upstream throws big wake rings across the course.
##
## The boats (boat.gd) share one model; the rivals drive it through `steer` / `throttle` from a
## racing line through each ring at their own offset, slow for sharp rings, avoid and block, make
## mistakes by temperament, and are rubber-banded only off screen. Waves: a low chop plus wake
## rings each boat and the barge drop as they go (`wave`), felt by every hull.
##
## Free ride (F 2026-11-07): three boats of his photos stay moored along the pontoon, each with its
## own feel (boat.gd SPECS): the jet ski "Rekin X", the electric runabout "Srebrna Strzała" and the
## offshore "Czarna Pantera". Stop there and the pill PRZYSTAŃ opens the marina card: pick one and
## take it out with nobody else (no rings, no clock; the sand barge passes for its wake), ✕ on the
## panel ends the ride and the car is where it was left; WYŚCIG starts the race as before.
##
## While the race is on, the game shadows the car on the player's boat (main.gd `_boat_frame`), so
## the camera, the streamer and the minimap follow it; the car itself waits on the bank.
##
## Cost: nothing per frame while idle but a timer. During the race: 4 boats + the barge (5 draw
## calls), the next 3 rings and the finish (up to 4), one foam mesh (1): about +10 draw calls; four
## sphere tests a frame against the world; the wave sum ~1k cheap terms a frame.
##
## The activity kit (activity.gd, TD-1; the eighth moved): the call, the offer, the phases, the
## cards' owner, the pontoon's beacon and its arrow, the ✕, the autopilot's taps and the log are the
## kit's now. What stays here is the boats, the course, the rules, the rivals, the water, the
## marina's card and the free ride (the run's own `Stage`s), and the result cards' words.

const Boat := preload("res://scripts/boat.gd")
const BoatSpray := preload("res://scripts/boat_spray.gd")
const BoatStreaks := preload("res://scripts/boat_streaks.gd")
const Gamepad := preload("res://scripts/gamepad.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Models := preload("res://scripts/models.gd")
const FirstSteps := preload("res://scripts/first_steps.gd")

const COURSE := "res://data/boat_race.json"
const COLOUR := Color("#2fb8e0")      # the Vistula's blue: the race's accent
const RING := Color("#ff7a1a")
const RING_NEXT := Color("#ffb347")
const GOLD := Color("#ffd23f")
const FAIL := Color("#e2574c")
const NAME := "Wiślana Szprotka"

## The start pontoon on the left bank at the harbour's mouth, and where the car stops by it.
const PONTOON := [Vector2(1464.0, 703.0), Vector2(1500.0, 690.0)]
## The pontoon's deck is 3.2 m wide: solid for the boats (solid_at), a capsule along PONTOON.
const PONTOON_HALF_W := 1.8
const CAR_SPOT := Vector2(1446.0, 716.0)
## The free-ride fleet, moored alongside the pontoon on its upstream (south) side, bows to the river
## (MOOR_YAW): `along` m out along the deck from its bank end, `off` m off its centre line
## (the deck's half width + the boat's radius + a metre or so: the current sets them on the deck).
## Their places are worked out from PONTOON in `_fleet_spot`.
const FLEET := [
	{"kind": Boat.Kind.SKUTER, "name": "Rekin X", "short": "REKIN X", "what": ["skuter", "jet ski"], "along": 7.0, "off": 4.0},
	{"kind": Boat.Kind.ELECTRIC, "name": "Srebrna Strzała", "short": "STRZAŁA", "what": ["elektryczna", "electric"], "along": 17.0, "off": 5.0},
	{"kind": Boat.Kind.OFFSHORE, "name": "Czarna Pantera", "short": "PANTERA", "what": ["offshore", "offshore"], "along": 30.0, "off": 7.0},
]
## Bows 35° off the deck towards the open river, in echelon: each boat leaves clear of the ones
## moored further out.
const MOOR_YAW := 1.31
const FREE_COLOUR := Color("#1f4fa8")
const ARRIVE := 9.0
const PILL_R := 45.0

## The call: daytime, after FIRST_CALL s of play, then every CALL_COOL s; the card's life.
static var HOURS: Array = Pacer.pair("boat", "hours")
static var FIRST_CALL: float = Pacer.num("boat", "first_call")
static var CALL_COOL: float = Pacer.num("boat", "call_cool")
const CARD_LIFE := 12.0
const PLAY_LIMIT := 1800.0

## The rules.
const MISSES := 3
const RHYTHM_STEP := 0.025
const RHYTHM_MAX := 8
const MISS_COST := 4   # rhythm lost on a miss (was a reset to 0)
const GOLD_BOOST := 1.18
const GOLD_TIME := 2.5
const COUNT := 3.0
## Pay by place *guess*: [złoty, respect].
const PAY := [[150, 40], [60, 15], [25, 5], [0, 0]]

## The river.
const FLOW := 1.0            # m/s downstream
const CHOP := 0.07           # m
const WAKE_EVERY := 0.32     # s between a boat's wake rings
const WAKE_N := 10           # rings kept per source
const WAKE_LIFE := 3.4       # s
const WAKE_SPREAD := 5.0     # m/s the ring grows
const WAKE_W := 1.6          # m, a crest's half width when new
const BARGE_SPEED := 2.4     # m/s upstream
const BARGE_LEN := 72.0
const BARGE_HALF_W := 5.6
const BARGE_WAKE := 0.8      # m
const OWN_WAKE := 0.7        # s: a boat does not feel its own newest rings

## The rivals: name, kind, paint, shirt, hair, line offset share, mistake chance a ring, block,
## pace (share of the kind's top), start delay (s), the dialogue tag; `stunt`: the chance at each
## ring, with the player close behind, that he shows off for his camera (STUNT_TIME s of spins and
## a wheelie at half throttle: Kamil films everything, and the player gets past).
const RIVALS := [
	{"name": "Szymek", "kind": Boat.Kind.RUNABOUT, "paint": "#c8302c", "shirt": "#2f6fb5", "hair": "#4a3426",
		"line": 0.15, "miss": 0.02, "block": 0.3, "pace": 1.03, "delay": 0.35, "tag": "szymek"},
	{"name": "Pan Zdzisiek", "kind": Boat.Kind.TUB, "line": 0.0, "miss": 0.0, "block": 0.0, "pace": 1.04,
		"delay": 0.8, "tag": "zdzisiek"},
	{"name": "Kamil", "kind": Boat.Kind.JETSKI, "line": 0.35, "miss": 0.035, "block": 0.8, "pace": 1.01,
		"delay": 0.15, "tag": "kamil", "stunt": 0.35},
]
const STUNT_TIME := 1.0   # was 1.8; the boats are 1.9x faster (2026-11-10), a long show-off runs him out of the course
const STUNT_MAX := 3
const PLAYER_PAINT := Color("#ff8a1a")
const RUBBER := 0.08
const RUBBER_GAP := 45.0
## F 2026-11-26 ("the other boat is far ahead"): the pack waits for a slow player. A rival ahead
## eases off by up to RUBBER_AHEAD (off screen) or RUBBER_AHEAD_SEEN (in view) from RUBBER_NEAR m
## ahead, in full at RUBBER_FAR m; one behind pushes up to RUBBER_BEHIND (in view half of it).
const RUBBER_AHEAD := 0.17
const RUBBER_AHEAD_SEEN := 0.05
const RUBBER_BEHIND := 0.08
const RUBBER_NEAR := 25.0
const RUBBER_FAR := 150.0
## The inside buoy (docs/design/critique-boat-race.md 3.1): the last INSIDE_R m of each ring's opening,
## on the side of the next ring, is the fast line (+rhythm, a boost) and sits next to a miss.
const INSIDE_R := 5.0
## Up to CLIP_W m past the inside edge is a clip (ŚCINKA!): no miss, a little speed lost.
const CLIP_W := 1.5
const INSIDE_BOOST := 1.07
const INSIDE_TIME := 1.5
## Slipstream (F 2026-11-08, "it's boring, the jet ski is always in front"): a boat running in
## another's wake, DRAFT_AHEAD m behind it and within DRAFT_SIDE m of its line, pulls up to
## DRAFT more top speed after DRAFT_BUILD s there: the catch-up is in the player's hands and on
## screen, and the leader is never safe. Every boat gets it, the rivals too.
const DRAFT := 0.11
const DRAFT_AHEAD := Vector2(3.0, 40.0)
const DRAFT_SIDE := 3.4
const DRAFT_BUILD := 0.6
## Floating jump ramps on the crossings (tools/boat_course.py `ramps`): a boat over one at more
## than RAMP_MIN m/s takes off (up at RAMP_UP x its speed, RAMP_VY limits), lands soft and gets
## JUMP_BOOST top speed for JUMP_TIME s (Hydro Thunder's ramps; the gold ring is past the landing).
const RAMP_MIN := 7.0
const RAMP_UP := 0.28
const RAMP_VY := Vector2(3.5, 6.0)
const RAMP_H := 1.1
## The rivals' driver (and the player's autopilot) steers over a ramp this close to its line.
const RAMP_PULL := 6.0
const JUMP_BOOST := 1.12
const JUMP_TIME := 1.8

## Kaczki (F 2026-11-26, "Szprotka is boring, make it funnier"): DUCK_N families of a mother and
## four ducklings pace across the river between two rings, one mesh each (3 draw calls). A boat
## closer than DUCK_HIT to the mother scatters them (they fly off, nobody is hurt) and loses
## DUCK_BRAKE of its speed, and the player a rhythm pip: "ducks have right of way". Passing the
## family within DUCK_NEAR m without a scare is a clean pass (a toast the first time a race).
const DUCK_SPOTS := [0.22, 0.5, 0.77]    # where in the course (share of the ordinary rings)
const DUCK_SWING := 11.0                 # m: how far across the line a family paces
const DUCK_RATE := 0.33                  # rad/s of the pacing
const DUCK_HIT := 4.8
const DUCK_NEAR := 11.0
const DUCK_BRAKE := 0.88
const DUCK_FLY := 1.6                    # s the scattered family stays in the air

## The arcade pass (Fable's plan, 2026-11-26). DOPALACZ: the player's nitro tank (0..1) fills
## from the race (rings, the buoy line, gold rings, jumps, crates, a slipstream, hugging a bank,
## a clean pass of the ducks) and is burnt by holding the HUD's nitro disc (Shift, LB / RB):
## NITRO_BOOST top speed and NITRO_PULL pull, NITRO_TURN of the rudder, NITRO_BURN a second; it
## lights from NITRO_MIN. A miss and a duck scare take some back. The rivals have none.
const NITRO_START := 0.35
const NITRO_BOOST := 1.32
const NITRO_BURN := 0.33
const NITRO_MIN := 0.2
const NITRO_PULL := 1.8
const NITRO_TURN := 0.85
const FILL_RING := 0.06
const FILL_BUOY := 0.18
const FILL_GOLD := 0.25
const FILL_JUMP := 0.15
const FILL_CRATE := 0.12
const FILL_DRAFT := 0.05     # a second in full slipstream
const FILL_HUG := 0.08       # a second hugging a bank
const FILL_DUCKS := 0.10     # a family passed close without a scare
const FILL_SHOAL := 0.15     # three crates inside SHOAL_T s
const COST_MISS := 0.15
const COST_DUCK := 0.10
## The start: gas pressed within START_WINDOW s after START! is a rocket start (START_INSIDE s of
## the buoy line's boost, FILL_ROCKET nitro); gas held from more than FALSE_EARLY s before it is a
## false start (FALSE_T s at FALSE_SURGE of the pull).
const START_WINDOW := 0.25
const START_INSIDE := 2.0
const FILL_ROCKET := 0.25
const FALSE_EARLY := 0.6
const FALSE_T := 0.4
const FALSE_SURGE := 0.5
## Near the banks: between HUG_IN and HUG_D m off a bank at HUG_SPEED of the top for HUG_BUILD s,
## HUG_BOOST top speed and the tank fills; a touch of the bank ends it.
const HUG_IN := 2.5
const HUG_D := 9.0
const HUG_SPEED := 0.6
const HUG_BUILD := 0.5
const HUG_BOOST := 1.05
## Szymek likes the inside: his line through a ring leans this share of the half-opening that way.
const SZYMEK_INSIDE := 0.3
## Skrzynki szprotek (parody tins, a gold lid): three (CRATE_AT) on the chord between two ordinary
## rings, pushed towards the ring's inside until the bank is CRATE_BANK m away (at most
## CRATE_CAP of the river's half width), CRATE_N at most, one MultiMesh. The player takes one
## within CRATE_R m: FILL_CRATE nitro, CRATE_PAY zł at the finish; SHOAL_N within SHOAL_T s is a shoal.
const CRATE_AT := [0.3, 0.5, 0.7]
const CRATE_BANK := 7.0
const CRATE_CAP := 0.45
## Rivals run this much faster all race, standing for the nitro the player burns (2026-11-26: the autopilot won by 3-9 s).
const RIVAL_NITRO := 1.06
const CRATE_OFF_MAX := 16.0   # m off the chord at most: a crate is a nudge, not a detour
const CRATE_N := 64
const CRATE_R := 3.2
const CRATE_PAY := 2
const SHOAL_N := 3
const SHOAL_T := 4.0
## The spray (boat_spray.gd): drops a second from a fast hull (over SPRAY_SPEED of its top), on
## nitro, and in a burst.
const SPRAY_RATE := 20.0
const SPRAY_NITRO := 60.0
const SPRAY_BURST := 16
const SPRAY_SPEED := 0.55
const SPRAY_NEAR := 60.0
## The camera (main.gd `_update_camera` through `view_k`): the view opens to NITRO_VIEW of its size
## while the nitro burns, eased in at NITRO_VIEW_IN and out at NITRO_VIEW_OUT a second.
const NITRO_VIEW := 1.08
const NITRO_VIEW_IN := 6.0
const NITRO_VIEW_OUT := 2.0

## The run's own stages (the kit's `phase` is RUN for all of them; the marina's card and a free
## ride are stages of a run too).
enum Stage { NONE, MENU, FREE, TO_PIER, COUNTDOWN, RACE, OUT, DONE }

## Set by the game.
## (Vector3) -> bool: the point is on screen (the rubber band only works off it).
var seen: Callable = func(_p: Vector3) -> bool: return true
## The game's sounds (sfx.gd; null in the checks): the race's one-shots, the nitro's roar.
var sfx: Node
## The player's controls this frame (main.gd): the nitro held, the gas held (the start's timing).
var nitro_hold := false
var gas_hold := false
## A stop at the pontoon hands the race the controls; leaving hands them back (main.gd).
signal boarded
signal left_boat

var stage := Stage.NONE
## Seconds in this stage of the run (the kit's `_t` is the card's).
var _stage_t := 0.0
## How the next run begins (`_begin`): the way to the pontoon unless the pill or a test flag
## named another stage first; `_pick`: the marina's boat then.
var _first := Stage.TO_PIER
var _pick := 1
## Szymek's next call as it stood when the run began: the marina is not his call, so a run that
## ends on its card or in a free ride puts it back.
var _call_was := 0.0
var line: PackedVector2Array = PackedVector2Array()
var half_w: PackedFloat32Array = PackedFloat32Array()
var rings: Array = []
var grid: Array = []
var ramps: Array = []
## Ramp take-offs this race (check_boat_race.gd).
var jumps := 0
var _ramp_nodes: Array[MeshInstance3D] = []
var barge_cfg: Dictionary = {}
var flow_dir := Vector2(-0.36, -0.93)
var water_y := 0.0

var player: Boat
## The free-ride fleet (FLEET order; moored, or one of them the player's while Stage.FREE), each
## with its two looks [parked, ridden], and the one out now (-1: none).
var fleet: Array[Boat] = []
var _fleet_meshes: Array = []
var riding := -1
var free_boat: Boat
var _free_status_t := 0.0
var boats: Array[Boat] = []          # player first, then the rivals
var racers: Array = []         # per boat: {name, next, misses, rhythm, gold_t, out, finished, place, time, li, ...}
var clock_t := 0.0
## The water's own clock (runs on after the finish, so the wakes keep moving).
var wave_t := 0.0
var _count := 0.0
var _finish_order: Array = []
var _rng := RandomNumberGenerator.new()
var rng_seed := -1
var _ring_nodes: Array[MeshInstance3D] = []
var _mats := {}
var _barge: MeshInstance3D
## The duck families: {node, at (Vector2), across (Vector2), phase, state 0 pacing / 1 flying / 2 gone, t}.
var _ducks: Array = []
var ducks_scared := 0
var _ducks_ok_said := false
## The arcade pass: the tank (0..1), burning now, burns this race (check_boat_race.gd), the latch
## after it ran dry (let go of the disc to light it again), the false start's clock, the start judged.
var nitro := NITRO_START
var nitro_on := false
var nitro_burns := 0
var _nitro_latch := false
var _false_t := 0.0
var _start_judged := false
var _gas_was := false
var _gas_early := false
## Hugging a bank: seconds built, on, the side of the bank (+1 the boat's right), hugs this race.
var hug_t := 0.0
var hugging := false
var _hug_side := 1.0
var _hug_side_t := 0.0
var hugs := 0
var _bank_said := -9.0
## The crates: centres (x, z), taken, the MultiMesh, their count got this race, the pickups' times.
var crates: PackedVector2Array = PackedVector2Array()
var _crate_taken: Array[bool] = []
var _crate_mm: MultiMeshInstance3D
var _crate_buf := PackedFloat32Array()
var sprats := 0
var _crate_times: Array[float] = []
var shoals := 0
## The spray pool and its emission clocks (one a boat), the nitro flame at the player's stern.
var _spray: BoatSpray
var _spray_acc: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _flame: MeshInstance3D
## The speed streaks and the rank tag on the HUD (boat_streaks.gd; made on the first race frame in
## the game, none in the checks' stand-in HUD), and the nitro's view share now.
var _streaks: BoatStreaks
var _view_k := 1.0
## The Szprotka look (view only, main.gd's camera): smoothed pitch lift and roll, see `look`.
var _look := Vector2.ZERO
var _barge_pos := Vector2.ZERO
var _barge_dir := Vector2.ZERO
var _barge_li := 0.0
var _foam: MeshInstance3D
var _foam_mesh: ImmediateMesh
var _pontoon: MeshInstance3D
## Wake rings: per source (boats, then the barge's bow and stern) a ring buffer.
var _wakes: Array = []
var _wake_t: Array = []
var _query: PhysicsShapeQueryParameters3D
## The hull's band for the world test: a flat cylinder from HULL_BAND.x to HULL_BAND.y m over the
## water's rest level, whatever height the boat asks at. A sphere round the boat reached 3.1 m up
## and caught the fascias of the bridge decks (Most Świętokrzyski's is 2.9 m over the water), so
## every boat stopped dead under the bridge (F, 2026-11-08); a deck, a beam or a footbridge over
## the hull is not in the boat's way, only what stands in the water.
const HULL_BAND := Vector2(-0.4, 1.3)
var _hull: CylinderShape3D
var _car_spot := Vector3.ZERO
var _car_yaw := 0.0
var _result: Dictionary = {}
var _last_line_t := 0.0
var _solid_log := -10.0
var _piers := {}
const PIER_CELL := 40.0
## The WYŚCIG ŁODZI pill by the pontoon; off when story_quests.gd's in-person start owns the spot.
var walk_up_pill := true


## Wires the boat race from the game (activity.gd `install`; main.gd's `_build_boat_race` until TD-4
## b5). None with --boat-race=0. `autopilot` is on with --autopilot or --boat-race=auto. The ride's
## two signals (`boarded`, `left_boat`) go to main.gd, which hands over the controls: its hooks,
## connected after the join.
func install(ctx: GameCtx) -> bool:
	if ctx.flags.boat_flag == "0":
		return false
	super(ctx)
	name = "BoatRace"
	dialogue = ctx.dialogue
	car = ctx.car
	log_on = ctx.flags.boat_log
	autopilot = ctx.flags.autopilot or ctx.flags.boat_flag == "auto"
	force_hours = ctx.flags.boat_flag != ""
	vehicle = ctx.vehicle
	seen = ctx.seen
	sfx = ctx.sfx
	clock = ctx.life_hour
	return true


## After the join (main.gd's `_build_boat_race` until TD-4 b5): the free-ride boat's mark among the
## jobs' places (the minimap and the full map), and the test starts a second into the drive:
## --boat-race=race / =auto (the car at the pontoon, aboard), =free[N] / =marina (the car there,
## a free ride or the marina's card) and =call (Szymek rings).
func joined(ctx: GameCtx) -> void:
	var jobs: Node = ctx.jobs
	if jobs != null:
		jobs.boat_spot = fleet_spot(1)
		jobs._show_places(jobs._places_shown, true)
	var how: String = ctx.flags.boat_flag
	if how in ["race", "auto"]:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			var at := CAR_SPOT
			car.global_position = Vector3(at.x, map.ground_height(at.x, at.y), at.y)
			car.reset_physics_interpolation()
			board())
	elif how.begins_with("free") or how == "marina":
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			var at := CAR_SPOT
			car.global_position = Vector3(at.x, map.ground_height(at.x, at.y), at.y)
			car.reset_physics_interpolation()
			if how.begins_with("free"):
				free_ride(int(how.trim_prefix("free")) if how.length() > 4 else 1)
			else:
				_marina_card())
	elif how == "call":
		get_tree().create_timer(1.0).timeout.connect(func() -> void: ring())


func setup(world: Node3D) -> void:
	tag = "boat race"
	colour = COLOUR
	dark = Color("#1f3a5f")
	hours = Vector2(HOURS[0], HOURS[1])
	first_call = FIRST_CALL
	call_cool = CALL_COOL
	card_life = CARD_LIFE
	arrive = ARRIVE
	super.setup(world)
	# rng_seed >= 0 (check_boat_race.gd) makes the race repeatable; the game leaves it at -1.
	if rng_seed >= 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	_load_course()
	water_y = map.terrain_height(line[0].x, line[0].y) if map != null and map.has_method("terrain_height") else 0.0
	_build_materials()
	_build_pontoon(world)
	_hull = CylinderShape3D.new()
	_hull.height = HULL_BAND.y - HULL_BAND.x
	_query = PhysicsShapeQueryParameters3D.new()
	_query.shape = _hull
	_build_boats()
	_build_free_boat()
	_build_rings()
	_build_ramps()
	_build_barge()
	_build_ducks()
	_build_crates()
	_spray = BoatSpray.new()
	_spray.name = "Spray"
	add_child(_spray)
	_build_flame()
	_foam_mesh = ImmediateMesh.new()
	_foam = MeshInstance3D.new()
	_foam.mesh = _foam_mesh
	_foam.material_override = _mats["foam"]
	_foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_foam)
	_show_race(false)
	hud.context_pressed.connect(func(who: String) -> void:
		if who == "boat" and phase == Phase.IDLE:
			hud.hide_pill()
			_marina_card())


func _load_course() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COURSE))
	for p: Array in data["line"]:
		line.append(Vector2(float(p[0]), float(p[1])))
		half_w.append(float(p[2]))
	rings = data["rings"]
	for i in rings.size():
		# Which side of this ring the next ring lies on: the inside buoy's side (gold cap).
		var g: Dictionary = rings[i]
		var yaw := float(g["yaw"])
		var across := Vector2(cos(yaw), -sin(yaw))
		var j := i + 1
		while j < rings.size() and bool(rings[j]["gold"]):
			j += 1
		var side := 0.0
		if j < rings.size():
			side = (Vector2(float(rings[j]["x"]) - float(g["x"]), float(rings[j]["z"]) - float(g["z"]))).dot(across)
		g["in"] = 1.0 if side >= 0.0 else -1.0
	grid = data["grid"]
	barge_cfg = data["barge"]
	ramps = data.get("ramps", [])
	flow_dir = Vector2(float(data["flow"][0]), float(data["flow"][1]))
	# The bridge piers in the water (tools/boat_course.py, circles): solid whether or not their
	# sector's colliders are loaded, bucketed by PIER_CELL m.
	for c: Array in data.get("piers", []):
		var key := Vector2i(floori(float(c[0]) / PIER_CELL), floori(float(c[1]) / PIER_CELL))
		if not _piers.has(key):
			_piers[key] = []
		_piers[key].append(Vector3(float(c[0]), float(c[1]), float(c[2])))


## The player is in the boat (the game drives it and shadows the car on it).
func boating() -> bool:
	return phase == Phase.RUN and stage in [Stage.COUNTDOWN, Stage.RACE, Stage.OUT, Stage.DONE, Stage.FREE]


## In the race the next ring is the target (the minimap's dot; no arrow, see `target_arrow`).
func has_target() -> bool:
	return super.has_target() or (phase == Phase.RUN and stage == Stage.RACE)


func target_position() -> Vector3:
	if phase == Phase.RUN and stage == Stage.RACE:
		var r: Dictionary = rings[mini(int(racers[0]["next"]), rings.size() - 1)] if not racers.is_empty() else rings[0]
		return Vector3(float(r["x"]), water_y, float(r["z"]))
	return super.target_position()


func target_colour() -> Color:
	return RING_NEXT if phase == Phase.RUN and stage == Stage.RACE else colour


## On the water the rings themselves lead (the next three stand in view): no arrow over the boat.
func target_arrow() -> bool:
	return not boating()


## No stop assist at the pontoon's ring (there was none before the kit).
func stop_spot() -> Vector3:
	return Vector3.INF


## No helicopter while the race, the marina's card or a free ride is on.
func grounded() -> Array:
	return ["Najpierw dokończ wyścig łodzi (albo ✕)", "Finish the boat race first (or ✕)"]


func _car_spot_3d() -> Vector3:
	return Vector3(CAR_SPOT.x, map.ground_height(CAR_SPOT.x, CAR_SPOT.y), CAR_SPOT.y)


# --- the call and the pontoon ----------------------------------------------------------------------

func _process(dt: float) -> void:
	super._process(dt)
	# The marina's card goes when the car drives off (the kit knows only a card's life). After
	# the kit's frame, so nothing else of this frame runs once it is down.
	if phase == Phase.RUN and stage == Stage.MENU:
		var mv: Array = vehicle.call() if vehicle.is_valid() else []
		if not mv.is_empty() and Vector2(mv[0].x, mv[0].z).distance_to(CAR_SPOT) > PILL_R:
			finish()


## Every frame, whatever the phase: the stage's clock. Behind a result card (the kit does not
## call `_run_tick` while a card of the run is up) the boats still out there run on.
func _tick(dt: float) -> void:
	_stage_t += dt
	if phase == Phase.RUN and (stage == Stage.OUT or stage == Stage.DONE):
		_idle_boats(dt)


## Every frame while idle: the PRZYSTAŃ pill by the pontoon, then the kit's call clock.
func _idle_tick(dt: float) -> void:
	if not vehicle.is_valid():
		return
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	var near := walk_up_pill and Vector2(p.x, p.z).distance_to(CAR_SPOT) < PILL_R and not bool(v[2])
	if near and free_now.call() and hud.pill_free_for("boat"):
		if not hud.pill_shown("boat"):
			hud.show_pill("PRZYSTAŃ", "MARINA", "boat")
	elif hud.pill_shown("boat"):
		hud.hide_pill()
	super._idle_tick(dt)


func _run_tick(dt: float) -> void:
	match stage:
		Stage.TO_PIER:
			_pier_tick()
		Stage.COUNTDOWN:
			_countdown_tick(dt)
		Stage.RACE:
			_race_tick(dt)
		Stage.FREE:
			_free_tick(dt)


## Szymek's call: who rings and what he is to the player.
func _call_card() -> Dictionary:
	return {"who": "Szymek", "about": ["Kumpel z przystani. Ma motorówkę i zero cierpliwości.",
			"Your marina mate. Has a motorboat and zero patience."]}


func _offer_card() -> Dictionary:
	return {"title": ["SZYMEK: „ŚCIGAMY SIĘ?”", "Szymek: \"Race you?\""],
			"body": ["„Słuchaj, %s! Pan Zdzisiek wyciągnął Złotą Rybkę, Kamil swój skuter. Płyniemy z Portu Czerniakowskiego pod Śląsko-Dąbrowski, przez kółka. Trzy pudła i odpadasz. Wchodzisz?”" % NAME,
			"\"Listen, the %s! Pan Zdzisiek got the Złota Rybka out, Kamil his jet ski. We go from Port Czerniakowski down to Śląsko-Dąbrowski, through the rings. Three misses and you're out. You in?\"" % NAME], "face": "Szymek",
			"buttons": ["PŁYNĘ!|I'M IN!", "NIE DZIŚ|NOT TODAY"]}


## Szymek met in person at the pontoon (story_quests.gd: he walks up, the player said WCHODZĘ):
## no call, straight to the start. False unless idle.
func meet() -> bool:
	if phase == Phase.IDLE and hud.pill_shown("boat"):
		hud.hide_pill()
	return super.meet()


func _met_words() -> String:
	return "met Szymek at the pontoon"


## The run begins: the way to the pontoon (the offer taken, Szymek met), or the stage the pill
## or a test flag named first (the marina's card, a free ride, the grid at once).
func _begin() -> void:
	_call_was = _next_call
	var first := _first
	_first = Stage.TO_PIER
	match first:
		Stage.MENU:
			_show_marina()
		Stage.FREE:
			_free_start(_pick)
		Stage.COUNTDOWN:
			_board()
		_:
			_go_to_pier()


## The pill PRZYSTAŃ (and --boat-race=marina): the marina's card. Only when idle.
func _marina_card() -> void:
	if phase != Phase.IDLE:
		return
	_first = Stage.MENU
	start()


## --boat-race=race: straight onto the grid (the car is at the pontoon). Only when idle.
func board() -> void:
	if phase != Phase.IDLE:
		return
	_first = Stage.COUNTDOWN
	start()


## Out on the river in FLEET[i] (--boat-race=free): no rings, no rivals, no clock; ✕ ends it.
## Only when idle (the marina card's pick goes straight to `_free_start`).
func free_ride(i := 1) -> void:
	if phase != Phase.IDLE:
		return
	_first = Stage.FREE
	_pick = i
	start()


## A button on a card of the run: the result (JESZCZE RAZ / REWANŻ: the grid again; WYJDŹ: back
## to the car) or the marina's (a boat, or WYŚCIG).
func _card_pressed(index: int) -> void:
	match stage:
		Stage.OUT, Stage.DONE:
			if index == 0:
				_start_grid()
			else:
				finish()
		Stage.MENU:
			if index < FLEET.size():
				_free_start(index)
			elif index == FLEET.size():
				_board()
			else:
				finish()


## The marina's card nobody answered goes by itself (the only card of the run with a life).
func _card_expired() -> void:
	finish()


## The autopilot leaves a result card by WYJDŹ (a test run would race for ever), and does not
## pick a boat on the marina's card.
func _auto_button() -> int:
	return -1 if stage == Stage.MENU else 1


## Back to free play (the kit calls this at every end: a call or an offer turned down or not
## answered, the ✕, WYJDŹ, the marina's card closed). The boats go, the car is the player's again.
func _ended() -> void:
	var was := stage
	stage = Stage.NONE
	_stage_t = 0.0
	flown = false
	match was:
		Stage.NONE:
			pass
		Stage.MENU:
			_next_call = _call_was
		Stage.FREE:
			_next_call = _call_was
			_barge.visible = false
			_foam_mesh.clear_surfaces()
			player = boats[0]
			_park(riding)
			riding = -1
			left_boat.emit()
			_log("free ride over")
		_:
			hud.hide_banner()
			_show_race(false)
			if was != Stage.TO_PIER:
				left_boat.emit()
			_log("back to the car")


func _go_to_pier() -> void:
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	if Vector2(p.x, p.z).distance_to(CAR_SPOT) < ARRIVE * 2.0 and not bool(v[2]):
		_board()
		return
	stage = Stage.TO_PIER
	_stage_t = 0.0
	set_target(CAR_SPOT, true)
	hud.toast("Na przystań: start przy ujściu Portu Czerniakowskiego", "To the pontoon: the start at the mouth of Port Czerniakowski")
	_log("to the pontoon")


func _pier_tick() -> void:
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	var d := Vector2(p.x, p.z).distance_to(CAR_SPOT)
	if not bool(v[2]) and d < ARRIVE and float(v[1]) < 12.0:
		_board()
	elif _stage_t > PLAY_LIMIT:
		drop(false)


## The car stays on the bank; the boats go on the grid.
func _board() -> void:
	clear_target()
	_car_spot = car.global_position if car != null else _car_spot_3d()
	_car_yaw = car.rotation.y if car != null else 0.0
	flown = true
	boarded.emit()
	_start_grid()


func _start_grid() -> void:
	_hide_own_card()
	hud.hide_pill()
	var f := flow_dir
	var heading := atan2(f.x, f.y)
	racers.clear()
	_finish_order.clear()
	jumps = 0
	_arcade_reset()
	for k in boats.size():
		var b: Boat = boats[k]
		var g: Array = grid[k]
		b.place(Vector2(float(g[0]), float(g[1])), heading)
		b.visible = true
		var r := {"name": "Ty" if k == 0 else String(RIVALS[k - 1]["name"]), "next": 0, "misses": 0, "rhythm": 0,
				"gold_t": 0.0, "out": false, "finished": false, "time": 0.0, "li": 0.0, "prev": b.pos,
				"aim": _rng.randf_range(-1.0, 1.0), "mistake": false, "block_t": 0.0, "said": 0.0,
				"draft": 0.0, "draft_said": -99.0, "jump_t": 0.0, "jumping": false, "ramp_cd": 0.0,
				"stunt_t": 0.0, "stunts": 0, "inside_t": 0.0}
		racers.append(r)
	_place_barge()
	_reset_ducks()
	for w: Array in _wakes:
		w.clear()
	for k in _wake_t.size():
		_wake_t[k] = 0.0
	_show_race(true)
	_update_rings()
	stage = Stage.COUNTDOWN
	_count = COUNT + 0.6
	clock_t = 0.0
	_stage_t = 0.0
	_log("grid: 4 boats, %d rings, water at %.2f m" % [rings.size(), water_y])


## The countdown's number that sounded last (hud.gd `cue("count")` once a number).
var _count_said := 0

func _countdown_tick(dt: float) -> void:
	_count -= dt
	# The start's timing: gas pressed (and held) from more than FALSE_EARLY s before START! is early.
	if gas_hold and not _gas_was and _count - 0.6 > FALSE_EARLY:
		_gas_early = true
	if not gas_hold:
		_gas_early = false
	_gas_was = gas_hold
	_hold_boats(dt)
	_draw_crates()
	_streaks_tick(dt)
	_status()
	var n := ceili(_count - 0.6)
	if n >= 1:
		if n != _count_said:
			_count_said = n
			hud.cue("count")
		hud.show_banner(str(n), COLOUR)
	else:
		_count_said = 0
		hud.show_banner("START!", Access.GREEN)
		hud.cue("go")
		stage = Stage.RACE
		_stage_t = 0.0
		_say(1, "start")
		Access.buzz(80, 0.8)
		_log("start")
		if gas_hold and _gas_early:
			# FALSTART: the boat sits a moment with half its pull.
			_start_judged = true
			_false_t = FALSE_T
			boats[0].vel = Vector2.ZERO
			_toast_words("hud_false_start")
			_log("false start")


## Before the start: the boats sit on the grid, bobbing.
func _hold_boats(dt: float) -> void:
	_tick_wakes(dt)
	for b: Boat in boats:
		var keep: Vector2 = b.pos
		b.throttle = 0.0
		b.steer = 0.0
		b.braking = false
		b.target_dir = Vector3.ZERO
		b.step(dt)
		b.pos = keep
		b.vel = Vector2.ZERO


func _idle_boats(dt: float) -> void:
	if stage == Stage.DONE:
		clock_t += dt  # the rivals still out there get their times
	_tick_wakes(dt)
	_barge_tick(dt)
	for k in boats.size():
		var b: Boat = boats[k]
		if k > 0 and not bool(racers[k]["finished"]) and not bool(racers[k]["out"]):
			racers[k]["prev"] = b.pos
			_drive_rival(k, dt)
			b.step(dt)
			_check_rings(k)
			_progress(k)
			continue
		else:
			b.throttle = 0.0
			b.target_dir = Vector3.ZERO
			b.braking = b.forward_speed() > 1.0
		b.step(dt)
	_spray_tick(dt)
	_draw_crates()
	_draw_foam()


# --- free ride ---------------------------------------------------------------------------------------

## The pill PRZYSTAŃ: the marina's card (one of the three boats, or the race).
func _show_marina() -> void:
	stage = Stage.MENU
	_stage_t = 0.0
	# Short names in one row (a name reads the same in both languages: one line a button), so the
	# card fits a phone beside the other panels; no NIE TERAZ: the card goes by itself
	# (CARD_LIFE) or when the car drives off.
	var buttons := PackedStringArray()
	for f: Dictionary in FLEET:
		buttons.append(String(f["short"]))
	buttons.append("WYŚCIG")
	show_card(["PRZYSTAŃ · wybierz łódź", "MARINA · pick a boat"], ["Rekin X: skuter. Srebrna Strzała: elektryczna. Czarna Pantera: offshore, najszybsza, ponad 70 km/h.",
			"Rekin X: jet ski. Srebrna Strzała: electric. Czarna Pantera: offshore, the fastest, over 70 km/h."], buttons, CARD_LIFE, false, FREE_COLOUR)
	_log("marina card")


## The mooring of FLEET[i] (x, z).
static func fleet_spot(i: int) -> Vector2:
	var a: Vector2 = PONTOON[0]
	var dir: Vector2 = (PONTOON[1] - PONTOON[0]).normalized()
	var south := Vector2(-dir.y, dir.x)
	if south.y < 0.0:
		south = -south
	return a + dir * float(FLEET[i]["along"]) + south * float(FLEET[i]["off"])


## Out on the river in FLEET[i]: no rings, no rivals, no clock; ✕ ends it.
func _free_start(i: int) -> void:
	i = clampi(i, 0, FLEET.size() - 1)
	clear_target()
	hud.hide_pill()
	_car_spot = car.global_position if car != null else _car_spot_3d()
	_car_yaw = car.rotation.y if car != null else 0.0
	stage = Stage.FREE
	_stage_t = 0.0
	_free_status_t = 0.0
	riding = i
	free_boat = fleet[i]
	free_boat.set_mesh(_fleet_meshes[i][1])
	free_boat.place(fleet_spot(i), MOOR_YAW)
	player = free_boat
	for w: Array in _wakes:
		w.clear()
	_place_barge()
	flown = true
	boarded.emit()
	var name: String = FLEET[i]["name"]
	hud.toast("%s jest twoja. ✕ na panelu: z powrotem do auta" % name, "The %s is yours. ✕ on the panel: back to the car" % name)
	_free_status()
	_log("free ride: %s" % name)


func _free_tick(dt: float) -> void:
	_tick_wakes(dt)
	_barge_tick(dt)
	var b := free_boat
	_wake_t[0] = float(_wake_t[0]) + dt
	var v: float = b.speed()
	if v > 4.0 and not b.air and float(_wake_t[0]) >= WAKE_EVERY:
		_wake_t[0] = 0.0
		_drop(0, b.pos - b.forward() * float(b.spec["len"]) * 0.45, float(b.spec["wake"]) * clampf(v / float(b.spec["top"]), 0.0, 1.2), b.forward())
	b.boost = 1.0
	b.step(dt)
	if b.bumped > 2.5 or b.landed > Boat.HARD_LANDING:
		Access.buzz(40, clampf(maxf(b.bumped, b.landed) / 10.0, 0.3, 0.9))
	_draw_foam()
	_free_status_t -= dt
	if _free_status_t <= 0.0:
		_free_status()


func _free_status() -> void:
	_free_status_t = 0.25
	var kmh := roundi(free_boat.forward_speed() * 3.6)
	var home := roundi(free_boat.pos.distance_to(fleet_spot(riding)))
	status("Rejs · %s" % FLEET[riding]["name"], _clock_text(_stage_t), "%d km/h" % maxi(kmh, 0),
			["Przystań %d m · ✕ do auta" % home, "Marina %d m · ✕ to the car" % home], 0.0, FREE_COLOUR)


func _park(i: int) -> void:
	var b: Boat = fleet[i]
	b.set_mesh(_fleet_meshes[i][0])
	b.place(fleet_spot(i), MOOR_YAW)
	b.visible = true


## The fleet: hulls on the same water as the race's boats (slot 0's wakes while one is ridden: the
## race's boat 0 is not out then); the moored ones are solid for the boat out (solid_at).
func _build_free_boat() -> void:
	var mat := Models.material()
	for i in FLEET.size():
		var k := int(FLEET[i]["kind"])
		var looks: Array
		match k:
			Boat.Kind.SKUTER:
				looks = [Boat.skuter_mesh(false), Boat.skuter_mesh(true)]
			Boat.Kind.ELECTRIC:
				looks = [Boat.electric_mesh(false), Boat.electric_mesh(true)]
			_:
				looks = [Boat.offshore_mesh(false), Boat.offshore_mesh(true)]
		_fleet_meshes.append(looks)
		var b := Boat.new()
		b.name = "Fleet%d" % i
		add_child(b)
		b.setup(k, looks[0], mat)
		b.water_y = water_y
		b.flow = flow_dir * FLOW
		b.wave = func(x: float, z: float) -> float: return wave(x, z, 0)
		if map != null:
			b.shore = map.shore_distance
		b.solid = solid_at
		fleet.append(b)
		_park(i)
	free_boat = fleet[1]


# --- the race --------------------------------------------------------------------------------------

func _race_tick(dt: float) -> void:
	clock_t += dt
	shake = maxf(0.0, shake - dt * 2.2)
	if _stage_t > 1.0:
		hud.hide_banner()
	_tick_wakes(dt)
	_barge_tick(dt)
	_ducks_tick(dt)
	_start_tick()
	_nitro_tick(dt)
	for k in boats.size():
		var b: Boat = boats[k]
		var r: Dictionary = racers[k]
		r["prev"] = b.pos
		if k > 0:
			if bool(r["out"]) or bool(r["finished"]):
				b.throttle = 0.0
				b.braking = b.forward_speed() > 1.0
			elif clock_t < float(RIVALS[k - 1]["delay"]):
				b.throttle = 0.0
			else:
				_drive_rival(k, dt)
		elif autopilot or bool(r["finished"]):
			_drive_rival(0, dt)
		r["gold_t"] = maxf(0.0, float(r["gold_t"]) - dt)
		r["jump_t"] = maxf(0.0, float(r["jump_t"]) - dt)
		r["inside_t"] = maxf(0.0, float(r["inside_t"]) - dt)
		b.boost = (1.0 + RHYTHM_STEP * mini(int(r["rhythm"]), RHYTHM_MAX)) * (GOLD_BOOST if float(r["gold_t"]) > 0.0 else 1.0)
		b.boost *= JUMP_BOOST if float(r["jump_t"]) > 0.0 else 1.0
		b.boost *= INSIDE_BOOST if float(r["inside_t"]) > 0.0 else 1.0
		var dr := _draft(k, dt)
		b.boost *= 1.0 + DRAFT * dr
		if k == 0:
			if not bool(r["out"]) and not bool(r["finished"]):
				_fill(FILL_DRAFT * dr * dt)
			b.boost *= NITRO_BOOST if nitro_on else 1.0
			b.boost *= HUG_BOOST if hugging else 1.0
		if k > 0:
			b.boost *= _rubber(k) * RIVAL_NITRO  # the rivals have a little nitro of their own (the player's is the disc)
		b.step(dt)
		_ramps_tick(k, dt)
		_check_rings(k)
		_progress(k)
		if k == 0:
			_hug_tick(dt)
			_crates_tick()
		if k == 0 and (b.bumped > 2.5 or b.landed > Boat.HARD_LANDING):
			Access.buzz(40, clampf(maxf(b.bumped, b.landed) / 10.0, 0.3, 0.9))
			shake = maxf(shake, clampf(maxf(b.bumped, b.landed) / 12.0, 0.25, 1.0))
			if b.bumped > 2.5:
				_play("thump_soft", 0.8)
		if k == 0 and b.landed > 1.5 and not bool(r["jumping"]) and float(r["jump_t"]) <= 0.0:
			# A hop off a wake: a slap of spray.
			_play("boat_spray")
			_spray.burst(Vector3(b.pos.x, water_y + 0.2, b.pos.y), SPRAY_BURST / 2, 0.7)
	_update_rings()
	_spray_tick(dt)
	_streaks_tick(dt)
	_draw_crates()
	_draw_foam()
	_status()
	_chatter(dt)
	if bool(racers[0]["finished"]) and stage == Stage.RACE:
		_finish()


## Did boat k go through its next ring this step?
func _check_rings(k: int) -> void:
	var r: Dictionary = racers[k]
	if bool(r["out"]) or bool(r["finished"]):
		return
	var b: Boat = boats[k]
	var p0: Vector2 = r["prev"]
	var p1: Vector2 = b.pos
	var i := int(r["next"])
	# Gold rings in the way: a pass is a boost, a miss nothing; then the next real ring.
	while i < rings.size():
		var g: Dictionary = rings[i]
		var hit := _crossing(g, p0, p1)
		if hit == 0:
			# Left behind: the boat has crossed a later ring's line already.
			if i + 1 < rings.size() and _crossing(rings[i + 1], p0, p1) != 0:
				if not bool(g["gold"]):
					_miss(k, i)
				i += 1
				r["next"] = i
				continue
			return
		if hit > 0:
			if bool(g["finish"]):
				r["finished"] = true
				r["time"] = clock_t
				_finish_order.append(k)
				_log("%s finishes %d. in %.1f s" % [r["name"], _finish_order.size(), clock_t])
				if k > 0:
					_say(k, "finish")
			elif bool(g["gold"]):
				r["gold_t"] = GOLD_TIME
				if k == 0:
					_fill(FILL_GOLD)
					hud.toast("ZŁOTE KÓŁKO! Dopalacz", "GOLD RING! Boost")
					Access.buzz(30, 0.5)
					hud.cue("checkpoint")
			else:
				r["rhythm"] = int(r["rhythm"]) + 1
				if k == 0:
					_fill(FILL_RING)
				if _last_across * float(g["in"]) >= float(g["w"]) * 0.5 - 0.4 - INSIDE_R:
					# The buoy line: a bonus step and a short boost, a hair from a miss.
					r["rhythm"] = int(r["rhythm"]) + 1
					r["inside_t"] = INSIDE_TIME
					if k == 0:
						_fill(FILL_BUOY)
						hud.toast("PO BOI! Dopalacz", "BUOY LINE! Boost")
						shake = maxf(shake, 0.5)
				if k == 0:
					hud.cue("checkpoint")
				_maybe_stunt(k)
				if k == 0 and int(r["rhythm"]) > 1 and int(r["rhythm"]) <= RHYTHM_MAX:
					hud.ambient_toast("Rytm ×%d" % int(r["rhythm"]), "Rhythm ×%d" % int(r["rhythm"]))
		elif bool(g["finish"]) and k == 0:
			# Over the finish line but beside the arch (the river is ~4x wider than it): not a miss
			# that ends the rings for good (nothing was left to check, so the race never finished
			# and only the ✕ got out); the player turns and goes through the arch.
			var w: Array = FirstSteps.words("finish_arch")
			hud.toast(str(w[0]), str(w[1]))
			return
		elif not bool(g["gold"]) and _last_across * float(g["in"]) > 0.0 \
				and _last_across * float(g["in"]) <= float(g["w"]) * 0.5 - 0.4 + CLIP_W:
			# Clipped the inside buoy: not a miss, a scrape.
			r["rhythm"] = maxi(0, int(r["rhythm"]) - 1)
			b.vel *= 0.85
			if k == 0:
				_toast_words("hud_clip")
				shake = maxf(shake, 0.6)
				Access.buzz(40, 0.6)
		elif not bool(g["gold"]):
			_miss(k, i)
		i += 1
		r["next"] = i
		return


var _last_across := 0.0  ## the last `_crossing`'s offset from the ring's middle (+ towards local +x)
## Camera shake 0..1 (bumps, landings, the buoy line); main.gd reads it and eases it down.
var shake := 0.0


## +1 through the opening, -1 over the ring's line but outside the opening, 0 not crossed.
func _crossing(g: Dictionary, p0: Vector2, p1: Vector2) -> int:
	var c := Vector2(float(g["x"]), float(g["z"]))
	var yaw := float(g["yaw"])
	var f := Vector2(sin(yaw), cos(yaw))
	var s0 := (p0 - c).dot(f)
	var s1 := (p1 - c).dot(f)
	if not (s0 < 0.0 and s1 >= 0.0):
		return 0
	var x := p0 + (p1 - p0) * (s0 / (s0 - s1))
	_last_across = (x - c).dot(Vector2(f.y, -f.x))
	var across := absf(_last_across)
	if across > 260.0:
		return 0
	return 1 if across <= float(g["w"]) * 0.5 - 0.4 else -1


func _miss(k: int, i: int) -> void:
	var r: Dictionary = racers[k]
	r["misses"] = int(r["misses"]) + 1
	r["rhythm"] = maxi(0, int(r["rhythm"]) - MISS_COST)
	_log("%s misses ring %d (%d/%d)" % [r["name"], i, int(r["misses"]), MISSES])
	if k == 0:
		Access.buzz(90, 0.9)
		_fill(-COST_MISS)
		if int(r["misses"]) >= MISSES:
			_out()
		else:
			hud.toast("PUDŁO! %d/%d" % [int(r["misses"]), MISSES], "MISSED! %d/%d" % [int(r["misses"]), MISSES])
			_say(-1, "player_miss")
	else:
		if int(r["misses"]) >= MISSES:
			r["out"] = true
			hud.ambient_toast("%s odpada! Trzy pudła." % r["name"], "%s is out! Three misses." % r["name"])
			_say(k, "out")
		else:
			_say(k, "miss")


## The player's third miss.
func _out() -> void:
	racers[0]["out"] = true
	stage = Stage.OUT
	_stage_t = 0.0
	_nitro_set(false)
	hugging = false
	if _streaks != null:
		_streaks.off()
	hide_status()
	hud.show_banner("ODPADASZ!", FAIL)
	hud.cue("fail")
	show_card(["ODPADASZ! Trzy pudła.", "YOU'RE OUT! Three misses."],
			["Szymek: „No to klasyk. Kółka, nie bojki do omijania! Jeszcze raz?”", "Szymek: \"A classic. Rings, not buoys to dodge! Once more?\""],
			PackedStringArray(["JESZCZE RAZ|AGAIN", "WYJDŹ|QUIT"]), 0.0, false, FAIL)
	_log("player out after %.1f s" % clock_t)


func _finish() -> void:
	stage = Stage.DONE
	_stage_t = 0.0
	var place := _finish_order.find(0) + 1
	var pay: Array = PAY[clampi(place - 1, 0, PAY.size() - 1)]
	# The crates are paid with the place, once (CRATE_PAY zł a tin).
	var cash := int(pay[0]) + CRATE_PAY * sprats
	if wallet != null and cash > 0:
		wallet.pay(cash, int(pay[1]), "boat_race")
	_nitro_set(false)
	hugging = false
	if _streaks != null:
		_streaks.off()
	if place == 1:
		_play("crowd_cheer")
	hide_status()
	hud.hide_banner()
	var t := _clock_text(float(racers[0]["time"]))
	var words := ["Pierwszy! Szymek stawia lody na bulwarach.", "Drugi. Szymek: „Rewanż, ale już!”", "Trzeci. Pan Zdzisiek kiwa głową z uznaniem.", "Ostatni. Stawiasz lody, a Kamil już nagrywa relację."]
	var words_en := ["First! Szymek buys the ice cream on the boulevards.", "Second. Szymek: \"Rematch, right now!\"", "Third. Pan Zdzisiek nods his approval.", "Last. You're buying the ice cream, and Kamil is already filming his story."]
	var w := clampi(place - 1, 0, 3)
	hud.cue("win" if place == 1 else "step")  # first wins; any other place is a finish, not a loss
	# A time to beat (critique 2026-11-25): the record is kept, the card says when it falls.
	var old_best: float = wallet.best_time("boat_szprotka") if wallet != null else -1.0
	var fresh: bool = wallet != null and wallet.record("boat_szprotka", float(racers[0]["time"]))
	var rec_pl := ""
	var rec_en := ""
	if fresh and old_best > 0.0:
		rec_pl = "  REKORD! −%.1f s" % (old_best - float(racers[0]["time"]))
		rec_en = "  RECORD! −%.1f s" % (old_best - float(racers[0]["time"]))
	elif fresh:
		rec_pl = "  Pierwszy czas: %s" % t
		rec_en = "  First time on the board: %s" % t
	elif old_best > 0.0:
		rec_pl = "  Rekord: %s" % _clock_text(old_best)
		rec_en = "  Record: %s" % _clock_text(old_best)
	var duck_pl := ""
	var duck_en := ""
	if ducks_scared == 0:
		duck_pl = "  Kaczki zdrowe i zadowolone."
		duck_en = "  The ducks are fine and delighted."
	else:
		var dw: Array = words("card_ducks_scared")
		duck_pl = "  " + str(dw[0]) % ducks_scared
		duck_en = "  " + str(dw[1]) % ducks_scared
	var tins_pl := "  Szprotki %d/%d" % [sprats, crates.size()]
	var tins_en := "  Sprats %d/%d" % [sprats, crates.size()]
	show_card(["META! %d. miejsce · %s" % [place, t], "FINISH! Place %d · %s" % [place, t]],
			["%s%s%s%s%s" % [words[w], "  +%d zł  +%d szacunu" % [cash, int(pay[1])] if cash > 0 else "", tins_pl, rec_pl, duck_pl],
			"%s%s%s%s%s" % [words_en[w], "  +%d zł  +%d respect" % [cash, int(pay[1])] if cash > 0 else "", tins_en, rec_en, duck_en]],
			PackedStringArray(["REWANŻ|REMATCH", "WYJDŹ|QUIT"]))
	_result = {"place": place, "time": float(racers[0]["time"]), "misses": int(racers[0]["misses"]), "sprats": sprats,
			"cash": cash, "nitro_burns": nitro_burns}
	_log("player finishes %d. in %.1f s, %d misses" % [place, float(racers[0]["time"]), int(racers[0]["misses"])])


func last_result() -> Dictionary:
	return _result


# --- the rivals --------------------------------------------------------------------------------------

## Boat k drives itself down the racing line (a rival, or the player's boat on autopilot or after
## the finish): it aims at its next ring at its own offset, looks ahead along the line between the
## rings, slows for a sharp one, keeps off the boat in front, blocks a boat close behind.
func _drive_rival(k: int, dt: float) -> void:
	var b: Boat = boats[k]
	var r: Dictionary = racers[k]
	var cfg: Dictionary = RIVALS[k - 1] if k > 0 else {"line": 0.1, "miss": 0.0, "block": 0.0, "pace": 1.0}
	var i := mini(int(r["next"]), rings.size() - 1)
	if bool(r["finished"]):
		# Ease off down the river after the line.
		b.target_dir = Vector3(flow_dir.x, 0.0, flow_dir.y) * 0.3
		return
	var g: Dictionary = rings[i]
	var aim := _ring_aim(k, i, cfg)
	var to := aim - b.pos
	var d := to.length()
	# Look past the ring once close: the line from this ring to the next.
	var want := aim
	if i + 1 < rings.size():
		var aim2 := _ring_aim(k, i + 1, cfg)
		var look := 6.0 + b.speed() * 0.55
		if d < look:
			want = aim.lerp(aim2, clampf((look - d) / look, 0.0, 0.6))
	# A jump ramp on the way to the ring: through it (PT-53: lines passed beside the pads).
	var rp := _ramp_ahead(b.pos, aim)
	if rp != Vector2.INF:
		want = rp
	# Keep clear of a boat just ahead; block a boat close behind. Both fade out in the last
	# metres before a ring: a boat commits to the opening instead of swerving out of it.
	var commit := clampf((d - 8.0) / 14.0, 0.0, 1.0)
	var f: Vector2 = b.forward()
	var right := Vector2(f.y, -f.x)
	for j in boats.size():
		if j == k:
			continue
		var o: Boat = boats[j]
		var rel: Vector2 = o.pos - b.pos
		var ahead := rel.dot(f)
		var side := rel.dot(right)
		if ahead > 0.0 and ahead < 14.0 and absf(side) < 4.5:
			want += right * (-signf(side) if side != 0.0 else 1.0) * 5.0 * commit
		elif ahead < -3.0 and ahead > -22.0 and absf(side) < 7.0 and float(cfg["block"]) > 0.0 and j == 0:
			r["block_t"] = float(r["block_t"]) + dt
			if float(r["block_t"]) < 2.5 * float(cfg["block"]):
				want += right * side * 0.6 * commit
		else:
			r["block_t"] = maxf(0.0, float(r["block_t"]) - dt * 0.5)
	# The turn at this ring: slow before a sharp one.
	var turn := 0.0
	if i + 1 < rings.size():
		var nxt := Vector2(float(rings[i + 1]["x"]), float(rings[i + 1]["z"]))
		var a1 := (aim - b.pos)
		var a2 := (nxt - aim)
		if a1.length() > 1.0 and a2.length() > 1.0:
			turn = absf(a1.angle_to(a2))
	var top: float = b.top() * float(cfg["pace"])
	var corner := top * (1.0 - 0.5 * clampf((turn - 0.5) / 1.0, 0.0, 1.0))
	var vf: float = b.forward_speed()
	var brake_d := maxf(0.0, (vf * vf - corner * corner) / (2.0 * Boat.BRAKE * 0.6)) + 8.0
	var go := 1.0
	if d < brake_d and vf > corner + 0.5:
		# A jet-steered hull (Kamil's ski) turns only with thrust: it brakes with the gas still on.
		go = 0.35 if bool(b.spec.get("jet", false)) else 0.0
	# The barge's wake ahead: Pan Zdzisiek takes it slow.
	if b.kind == Boat.Kind.TUB and _barge.visible and b.pos.distance_to(_barge_pos) < 70.0:
		go = minf(go, 0.6)
	var err := wrapf(atan2(want.x - b.pos.x, want.y - b.pos.y) - b.yaw, -PI, PI)
	b.target_dir = Vector3.ZERO
	b.steer = clampf(err * 2.4, -1.0, 1.0)
	b.throttle = go
	b.braking = go < 0.4 and vf > corner + 3.0
	if absf(err) > 1.4 and vf > 8.0:
		b.throttle = 0.3
	if float(r.get("stunt_t", 0.0)) > 0.0:
		# Showing off for the camera: weaving and a wheelie at half throttle.
		r["stunt_t"] = float(r["stunt_t"]) - dt
		b.throttle = 0.45
		b.braking = false
		b.steer = clampf(err * 1.2 + sin(float(r["stunt_t"]) * 9.0) * 0.9, -1.0, 1.0)


## Kamil after a ring, the player close behind and the next ring straight on: sometimes he
## shows off for his camera (a line, STUNT_TIME s at half throttle), at most STUNT_MAX a race.
func _maybe_stunt(k: int) -> void:
	if k == 0 or not RIVALS[k - 1].has("stunt"):
		return
	var r: Dictionary = racers[k]
	if int(r["stunts"]) >= STUNT_MAX or bool(racers[0]["out"]):
		return
	var gap := (float(r["li"]) - float(racers[0]["li"])) * 10.0
	if gap < 0.0 or gap > 70.0:
		return
	if _rng.randf() >= float(RIVALS[k - 1]["stunt"]):
		return
	r["stunt_t"] = STUNT_TIME
	r["stunts"] = int(r["stunts"]) + 1
	_say(k, "stunt")
	_log("%s shows off for the camera" % r["name"])


## Boat k's slipstream share 0..1 now: in another boat's wake (behind it, on its line, both
## heading the same way at speed) it builds over DRAFT_BUILD s; out of it, it fades twice as fast.
func _draft(k: int, dt: float) -> float:
	var r: Dictionary = racers[k]
	var b: Boat = boats[k]
	var f: Vector2 = b.forward()
	var right := Vector2(f.y, -f.x)
	var inside := false
	var leader := -1
	if not b.air and b.forward_speed() > 8.0:
		for j in boats.size():
			if j == k or bool(racers[j]["finished"]) or bool(racers[j]["out"]):
				continue
			var o: Boat = boats[j]
			var rel: Vector2 = o.pos - b.pos
			var ahead := rel.dot(f)
			if ahead > DRAFT_AHEAD.x and ahead < DRAFT_AHEAD.y and absf(rel.dot(right)) < DRAFT_SIDE \
					and o.forward().dot(f) > 0.85 and o.forward_speed() > 8.0:
				inside = true
				leader = j
				break
	var d := float(r["draft"])
	d = minf(d + dt, DRAFT_BUILD * 2.0) if inside else maxf(0.0, d - dt * 2.0)
	r["draft"] = d
	var share := clampf((d - DRAFT_BUILD * 0.5) / (DRAFT_BUILD * 0.5), 0.0, 1.0)
	if k == 0 and share >= 1.0 and leader > 0 and clock_t - float(r["draft_said"]) > 12.0:
		r["draft_said"] = clock_t
		var who := String(RIVALS[leader - 1]["name"])
		hud.ambient_toast("W ŚLADZIE! Ciągnie cię %s" % who, "SLIPSTREAM! %s pulls you along" % who)
	return share


## The floating ramps: boat k over one at speed takes off, lands soft with a short boost.
func _ramps_tick(k: int, dt: float) -> void:
	var r: Dictionary = racers[k]
	var b: Boat = boats[k]
	r["ramp_cd"] = maxf(0.0, float(r["ramp_cd"]) - dt)
	if bool(r["jumping"]) and not b.air:
		r["jumping"] = false
		r["jump_t"] = JUMP_TIME
		if k == 0:
			hud.ambient_toast("SKOK! Dopalacz", "JUMP! Boost")
			Access.buzz(30, 0.4)
			_fill(FILL_JUMP)
			if sfx != null:
				sfx.splash(b.forward_speed())
			_spray.burst(Vector3(b.pos.x, water_y + 0.2, b.pos.y), SPRAY_BURST)
	if b.air or float(r["ramp_cd"]) > 0.0 or b.forward_speed() < RAMP_MIN:
		return
	for rp: Dictionary in ramps:
		var c := Vector2(float(rp["x"]), float(rp["z"]))
		var yaw := float(rp["yaw"])
		var f := Vector2(sin(yaw), cos(yaw))
		var rel := b.pos - c
		var along := rel.dot(f)
		var across := absf(rel.dot(Vector2(f.y, -f.x)))
		if absf(along) > float(rp["len"]) * 0.5 or across > float(rp["w"]) * 0.5 or b.forward().dot(f) < 0.5:
			continue
		var vf := b.forward_speed()
		b.air = true
		b.soft_landing = true
		b.vy = clampf(vf * RAMP_UP, RAMP_VY.x, RAMP_VY.y)
		b.y = maxf(b.y, RAMP_H)
		r["jumping"] = true
		r["ramp_cd"] = 1.5
		jumps += 1
		_log("%s jumps a ramp at %.0f km/h" % [r["name"], vf * 3.6])
		return


## The centre of a ramp lying ahead on the run from `from` to `to` (at most RAMP_PULL m off that
## straight line and before its end), or INF.
func _ramp_ahead(from: Vector2, to: Vector2) -> Vector2:
	var run := to - from
	var l := run.length()
	if l < 1.0:
		return Vector2.INF
	var u := run / l
	for r: Dictionary in ramps:
		var c := Vector2(float(r["x"]), float(r["z"]))
		var along := (c - from).dot(u)
		if along > 3.0 and along < l and absf((c - from).dot(Vector2(u.y, -u.x))) < RAMP_PULL:
			return c
	return Vector2.INF


## Where boat k aims through ring i: the ring's centre at its own share of the opening (fixed per
## race, `aim`), or past the opening when this ring is its mistake.
func _ring_aim(k: int, i: int, cfg: Dictionary) -> Vector2:
	var g: Dictionary = rings[i]
	var c := Vector2(float(g["x"]), float(g["z"]))
	var yaw := float(g["yaw"])
	var across := Vector2(cos(yaw), -sin(yaw))
	var r: Dictionary = racers[k]
	var half := float(g["w"]) * 0.5 - 2.4
	var off := float(r["aim"]) * float(cfg["line"]) * half
	if k == 1:
		# Szymek takes the inside (the buoy's side): a bolder line through every ring.
		off = clampf(off + float(g["in"]) * half * SZYMEK_INSIDE, -half, half)
	# A gold ring is a detour: the careful skip it when it is off their line.
	var key := "m%d" % i
	if not r.has(key):
		r[key] = _rng.randf() < float(cfg["miss"]) and not bool(g["finish"])
	if bool(r[key]):
		off = (half + 4.0 + float(g["w"]) * 0.3) * (1.0 if float(r["aim"]) >= 0.0 else -1.0)
	return c + across * off


## The pack stays with the player: a rival far ahead eases off, one far behind pushes. Stronger out
## of sight, gentler (and only up to a point) in view.
func _rubber(k: int) -> float:
	var gap := (float(racers[k]["li"]) - float(racers[0]["li"])) * 10.0
	var seen_now: bool = seen.call(boats[k].position)
	if gap > RUBBER_NEAR:
		var x := clampf((gap - RUBBER_NEAR) / (RUBBER_FAR - RUBBER_NEAR), 0.0, 1.0)
		return 1.0 - (RUBBER_AHEAD_SEEN if seen_now else RUBBER_AHEAD) * x
	if gap < -RUBBER_GAP:
		var x := clampf((-gap - RUBBER_GAP) / (RUBBER_FAR - RUBBER_GAP), 0.0, 1.0)
		return 1.0 + RUBBER_BEHIND * (0.5 if seen_now else 1.0) * x
	return 1.0


## How far down the line boat k is (line points, fractional), searched round the last value.
func _progress(k: int) -> void:
	var r: Dictionary = racers[k]
	var b: Boat = boats[k]
	var li := int(r["li"])
	var best := li
	var bd := INF
	for j in range(maxi(0, li - 3), mini(line.size(), li + 8)):
		var dd: float = b.pos.distance_squared_to(line[j])
		if dd < bd:
			bd = dd
			best = j
	var frac := 0.0
	if best + 1 < line.size():
		var seg := line[best + 1] - line[best]
		frac = clampf((b.pos - line[best]).dot(seg) / maxf(seg.length_squared(), 0.01), 0.0, 1.0)
	r["li"] = float(best) + frac


## The player's place now (1-4): finished first, then the out last, then by the line.
func place_now() -> int:
	var mine: Dictionary = racers[0]
	var p := 1
	for k in range(1, racers.size()):
		var o: Dictionary = racers[k]
		if bool(mine["finished"]):
			if bool(o["finished"]) and _finish_order.find(k) < _finish_order.find(0):
				p += 1
		elif bool(o["finished"]):
			p += 1
		elif bool(o["out"]):
			continue
		elif float(o["li"]) > float(mine["li"]):
			p += 1
	return p


func _status() -> void:
	var r: Dictionary = racers[0]
	var place := place_now()
	var marks := ""
	for m in MISSES:
		marks += "✕" if m < int(r["misses"]) else "○"
	var next := mini(int(r["next"]), rings.size() - 1)
	var done := 0
	var total := 0
	for k in rings.size():
		if not bool(rings[k]["gold"]) and not bool(rings[k]["finish"]):
			total += 1
			if k < next:
				done += 1
	var rh := mini(int(r["rhythm"]), RHYTHM_MAX)
	status(NAME, _clock_text(clock_t), "%d/%d" % [done, total],
			["Pudła %s · Rytm ×%d · Szprotki %d" % [marks, rh, sprats], "Misses %s · Rhythm ×%d · Sprats %d" % [marks, rh, sprats]],
			float(r["li"]) / float(line.size() - 1), Color(0, 0, 0, 0), ["1ST", "2ND", "3RD", "4TH"][place - 1])
	var dots := PackedVector2Array()
	var cols := PackedColorArray()
	for k in range(1, boats.size()):
		dots.append(boats[k].pos)
		cols.append(Color(RIVALS[k - 1].get("paint", "#e9dfc4")) if k != 3 else Color("#a6d63a"))
	hud.set_minimap_dots(dots, cols)


static func _clock_text(t: float) -> String:
	return "%d:%02d.%d" % [int(t) / 60, int(t) % 60, int(t * 10.0) % 10]


# --- what they say -------------------------------------------------------------------------------------

func _say(k: int, what: String) -> void:
	if dialogue == null:
		return
	if k < 0:
		# Someone near the player answers a miss.
		k = _nearest_rival()
		if k < 0:
			return
	if k == 0:
		return
	var key := "%s_%s" % [RIVALS[k - 1]["tag"], what]
	dialogue.say(boats[k], String(RIVALS[k - 1]["name"]), "boat_race", key, 3.0, COLOUR, 2.4, true)
	racers[k]["said"] = clock_t


func _nearest_rival() -> int:
	var best := -1
	var bd := 60.0
	for k in range(1, boats.size()):
		var d: float = boats[k].pos.distance_to(boats[0].pos)
		if d < bd and not bool(racers[k]["out"]):
			bd = d
			best = k
	return best


## Overtakes and bumps get a line now and then.
func _chatter(_dt: float) -> void:
	if clock_t - _last_line_t < 7.0:
		return
	var me: Boat = boats[0]
	for k in range(1, boats.size()):
		var b: Boat = boats[k]
		if b.pos.distance_to(me.pos) > 25.0 or bool(racers[k]["out"]):
			continue
		if me.bumped > 2.0 or b.bumped > 2.0:
			_say(k, "bump")
			_last_line_t = clock_t
			return
		var ahead: bool = float(racers[k]["li"]) > float(racers[0]["li"])
		var was: bool = racers[k].get("ahead", ahead)
		racers[k]["ahead"] = ahead
		if was != ahead:
			_say(k, "passed" if not ahead else "pass")
			_last_line_t = clock_t
			return


# --- the arcade pass: the nitro, the start, the banks, the crates, the spray --------------------------

## A fresh grid: a part-filled tank, no burn, the crates back, nobody hugging.
func _arcade_reset() -> void:
	_nitro_set(false)
	nitro = NITRO_START
	nitro_burns = 0
	_nitro_latch = false
	_false_t = 0.0
	_start_judged = false
	_gas_was = false
	_gas_early = false
	hug_t = 0.0
	hugging = false
	hugs = 0
	sprats = 0
	shoals = 0
	_crate_times.clear()
	for i in _crate_taken.size():
		_crate_taken[i] = false
	for k in _spray_acc.size():
		_spray_acc[k] = 0.0
	if _spray != null:
		_spray.clear()
	_draw_crates()


## The race's own HUD words (dialogue.json group "boat_race", tagged "only": hud_*, card_*), [Polish,
## English]; the tag itself when it is missing.
static var _words := {}


static func words(key: String) -> Array:
	if _words.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
		for l: Variant in (d.get("boat_race", []) if d is Dictionary else []):
			if l is Array and l.size() >= 3 and l[2] is Dictionary and l[2].has("only"):
				_words[str(l[2]["only"])] = [str(l[0]), str(l[1])]
	return _words.get(key, [key, key])


func _toast_words(key: String) -> void:
	var w: Array = words(key)
	hud.toast(str(w[0]), str(w[1]))


## main.gd's boat input, after the controls drove the player's boat: the nitro on the car's disc,
## Shift and LB / RB; the gas held (the start's timing); with `auto_gas` (main.gd BOAT_AUTO_GAS in
## the Classic scheme) the race's gas stays on unless the brake is held; and the HUD's disc shows
## the race's tank on the grid and in the race (the car's own otherwise).
func pad_frame(gas: bool, auto_gas: bool) -> void:
	nitro_hold = hud.nitro_held or Input.is_physical_key_pressed(KEY_SHIFT) or Gamepad.nitro()
	gas_hold = gas
	if auto_gas and stage == Stage.RACE and not autopilot and player != null and not player.braking:
		player.throttle = 1.0
	var racing := stage in [Stage.COUNTDOWN, Stage.RACE]
	if racing:
		hud.set_nitro(true, nitro, 1, nitro_on)
	elif car != null:
		hud.set_nitro(car.nitro_owned, car.nitro_charge, car.nitro_bottles, car.nitro_on)


## The camera's share of its size now (1.0 off the water): NITRO_VIEW while the nitro burns, eased.
func view_k(dt: float) -> float:
	var want := NITRO_VIEW if nitro_on and boating() else 1.0
	_view_k = lerpf(_view_k, want, 1.0 - exp(-(NITRO_VIEW_IN if want > _view_k else NITRO_VIEW_OUT) * dt))
	return _view_k


## The streaks and the rank tag over the boat just ahead (view only), every frame of the grid and
## the race; made on the first one under the HUD's panels. Only in the game (a CanvasLayer HUD with
## a camera to project through).
func _streaks_tick(dt: float) -> void:
	if _streaks == null:
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		if cam == null or not (hud is CanvasLayer) or not ("pt" in hud):
			return
		_streaks = BoatStreaks.new()
		_streaks.name = "BoatStreaks"
		_streaks.pt = float(hud.get("pt"))
		hud.add_child(_streaks)
		hud.move_child(_streaks, 0)
	var me: Boat = boats[0]
	_streaks.set_speed(me.forward_speed() / maxf(float(me.spec["top"]), 1.0), nitro_on, dt)
	var k := rival_ahead()
	var view := get_viewport().get_camera_3d()
	if k > 0 and stage == Stage.RACE and view != null:
		var at := boats[k].global_position + Vector3.UP * 3.0
		if not view.is_position_behind(at):
			_streaks.set_tag(["1ST", "2ND", "3RD", "4TH"][clampi(place_now() - 2, 0, 3)], view.unproject_position(at))
			return
	_streaks.set_tag("", Vector2.ZERO)


## The tank: + fills, - costs; always 0..1.
func _fill(amount: float) -> void:
	nitro = clampf(nitro + amount, 0.0, 1.0)


func _play(n: String, pitch := 1.0, gain_db := 0.0) -> void:
	if sfx != null:
		sfx.play(n, gain_db, pitch)


## The first START_WINDOW s of the race: gas pressed now (not held through START!) is a rocket
## start. The autopilot always gets it (a test run shows the start).
func _start_tick() -> void:
	if _start_judged:
		return
	if clock_t > START_WINDOW:
		_start_judged = true
		return
	var gas := gas_hold or autopilot
	if gas and (not _gas_was or autopilot):
		_start_judged = true
		racers[0]["inside_t"] = START_INSIDE
		_fill(FILL_ROCKET)
		shake = maxf(shake, 0.5)
		_toast_words("hud_rocket")
		_play("loud_rev", 1.1, -4.0)
		Access.buzz(50, 0.7)
		_log("rocket start")
	_gas_was = gas


## Lights or puts out the nitro: the hull's pull and rudder, the flame, the roar, the motor's pitch.
func _nitro_set(on: bool) -> void:
	if on != nitro_on:
		nitro_on = on
		if on:
			nitro_burns += 1
			shake = maxf(shake, 0.45)
			_play("nitro_whoosh")
			Access.buzz(40, 0.5)
			_log("nitro lit at %.2f" % nitro)
	if not boats.is_empty():
		boats[0].surge = (NITRO_PULL if nitro_on else 1.0) * (FALSE_SURGE if _false_t > 0.0 else 1.0)
		boats[0].turn_mult = NITRO_TURN if nitro_on else 1.0
	if _flame != null:
		_flame.visible = nitro_on
	if sfx != null:
		sfx.set("boat_nitro", nitro_on)
		sfx.set("motor_pitch", 1.15 if nitro_on else 1.0)


## Every race frame before the boats move: the player's disc (or the autopilot) burns the tank.
func _nitro_tick(dt: float) -> void:
	var r: Dictionary = racers[0]
	_false_t = maxf(0.0, _false_t - dt)
	var want := nitro_hold
	if autopilot:
		want = _auto_nitro()
	if bool(r["out"]) or bool(r["finished"]):
		want = false
	if not want:
		_nitro_latch = false
	if nitro_on:
		nitro = maxf(0.0, nitro - NITRO_BURN * dt)
		shake = maxf(shake, 0.18)
		if nitro <= 0.0:
			_nitro_latch = true
			hud.cue("tick")
			_nitro_set(false)
		elif not want:
			_nitro_set(false)
	elif want and not _nitro_latch and nitro >= NITRO_MIN:
		_nitro_set(true)
	else:
		_nitro_set(nitro_on)  # the false start's surge runs out
	if _flame != null and nitro_on:
		_flame.scale = Vector3(1.0, 1.0, 0.75 + 0.35 * absf(sin(wave_t * 31.0)))


## The autopilot burns a full tank on a straight: the next ring far and dead ahead, then to empty.
func _auto_nitro() -> bool:
	if nitro_on:
		return true
	if nitro < 0.99:
		return false
	var b: Boat = boats[0]
	var i := mini(int(racers[0]["next"]), rings.size() - 1)
	var c := Vector2(float(rings[i]["x"]), float(rings[i]["z"]))
	var to := c - b.pos
	return to.length() > 90.0 and absf(b.forward().angle_to(to)) < 0.2


## Near the banks: one shore sample a frame; the side of the bank, two more, four times a second.
func _hug_tick(dt: float) -> void:
	var b: Boat = boats[0]
	var r: Dictionary = racers[0]
	if map == null or not map.has_method("shore_distance") or bool(r["out"]) or bool(r["finished"]):
		hugging = false
		hug_t = 0.0
		return
	var d: float = map.shore_distance(b.pos.x, b.pos.y)
	var fast := not b.air and b.forward_speed() > HUG_SPEED * float(b.spec["top"])
	if b.bumped > 0.0:
		hug_t = 0.0
	elif d > HUG_IN and d < HUG_D and fast:
		hug_t = minf(hug_t + dt, HUG_BUILD + 1.0)
	else:
		hug_t = maxf(0.0, hug_t - dt * 3.0)
	var was := hugging
	hugging = hug_t >= HUG_BUILD
	if not hugging:
		return
	_fill(FILL_HUG * dt)
	_hug_side_t -= dt
	if not was or _hug_side_t <= 0.0:
		_hug_side_t = 0.25
		var f: Vector2 = b.forward()
		var right := Vector2(f.y, -f.x) * 3.0
		_hug_side = 1.0 if float(map.shore_distance(b.pos.x + right.x, b.pos.y + right.y)) < float(map.shore_distance(b.pos.x - right.x, b.pos.y - right.y)) else -1.0
	if not was:
		hugs += 1
		if clock_t - _bank_said > 6.0:
			_bank_said = clock_t
			hud.ambient_toast("BRZEG ×%d" % hugs, "BANK ×%d" % hugs)


## The crates, once at setup: three (CRATE_AT) a chord between two ordinary rings, pushed towards the
## ring's inside until the bank is CRATE_BANK m away (or CRATE_CAP of the river's half width).
func _build_crates() -> void:
	var ord: Array[int] = []
	for i in rings.size():
		if not bool(rings[i]["gold"]) and not bool(rings[i]["finish"]):
			ord.append(i)
	var shore_ok: bool = map != null and map.has_method("shore_distance")
	# More chords than CRATE_N allows: every other one, evenly down the whole course.
	var pairs := ord.size() - 1
	var use := mini(pairs, CRATE_N / CRATE_AT.size())
	for u in use:
		var j := int(float(u) * float(pairs) / float(use))
		var ga: Dictionary = rings[ord[j]]
		var gb: Dictionary = rings[ord[j + 1]]
		var pa := Vector2(float(ga["x"]), float(ga["z"]))
		var pb := Vector2(float(gb["x"]), float(gb["z"]))
		var chord := pb - pa
		if chord.length() < 20.0:
			continue
		var n := Vector2(-chord.y, chord.x).normalized()
		var yaw := float(ga["yaw"])
		if n.dot(Vector2(cos(yaw), -sin(yaw)) * float(ga["in"])) < 0.0:
			n = -n
		for t: float in CRATE_AT:
			if crates.size() >= CRATE_N:
				break
			var p := pa.lerp(pb, t)
			var cap := minf(CRATE_CAP * _half_w_at(p), CRATE_OFF_MAX)
			var off := 0.0
			if shore_ok:
				while off + 1.0 < cap:
					var q := p + n * (off + 1.0)
					if float(map.shore_distance(q.x, q.y)) <= CRATE_BANK:
						break
					off += 1.0
			crates.append(p + n * off)
			_crate_taken.append(false)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = crate_mesh()
	mm.instance_count = crates.size()
	_crate_mm = MultiMeshInstance3D.new()
	_crate_mm.name = "Crates"
	_crate_mm.multimesh = mm
	_crate_mm.material_override = Models.material()
	_crate_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_crate_mm.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_crate_mm.visible = false
	add_child(_crate_mm)
	_crate_buf.resize(crates.size() * 16)
	for i in crates.size():
		_crate_buf[i * 16 + 12] = 1.0
		_crate_buf[i * 16 + 13] = 1.0
		_crate_buf[i * 16 + 14] = 1.0
	if crates.size() > 0:
		var lo := Vector2(INF, INF)
		var hi := -lo
		for c in crates:
			lo = Vector2(minf(lo.x, c.x), minf(lo.y, c.y))
			hi = Vector2(maxf(hi.x, c.x), maxf(hi.y, c.y))
		mm.custom_aabb = AABB(Vector3(lo.x - 3.0, water_y - 2.0, lo.y - 3.0), Vector3(hi.x - lo.x + 6.0, 6.0, hi.y - lo.y + 6.0))
	_draw_crates()


## The river's half width at the line point nearest p.
func _half_w_at(p: Vector2) -> float:
	var best := 0
	var bd := INF
	for i in line.size():
		var d := p.distance_squared_to(line[i])
		if d < bd:
			bd = d
			best = i
	return half_w[best] if best < half_w.size() else 40.0


## "Szprotki w oleju": a parody sprat tin (no real brand) on a float, a gold lid with its ring pull,
## a blue body with a cream label and a little red fish; +Z forward, the waterline at y = 0.
static func crate_mesh() -> ArrayMesh:
	var st := Models._begin()
	var blue := Color("#2f5fa0")
	var cream := Color("#f2e6c4")
	Models.box(st, Vector3(0, 0.05, 0), Vector3(1.9, 0.3, 1.4), Color("#26282b"))
	Models.box(st, Vector3(0, 0.45, 0), Vector3(1.7, 0.55, 1.2), blue)
	Models.box(st, Vector3(0, 0.45, 0), Vector3(1.74, 0.26, 1.24), cream)
	Models.box(st, Vector3(0, 0.78, 0), Vector3(1.78, 0.12, 1.28), GOLD)
	Models.box(st, Vector3(0.55, 0.88, 0), Vector3(0.36, 0.06, 0.3), GOLD.darkened(0.25))
	# the fish on the label, both sides
	for s2: float in [-1.0, 1.0]:
		Models.box(st, Vector3(0, 0.45, s2 * 0.63), Vector3(0.7, 0.16, 0.04), Color("#c8302c"))
		Models.box(st, Vector3(-0.45, 0.45, s2 * 0.63), Vector3(0.16, 0.24, 0.04), Color("#c8302c"))
	return st.commit()


## The crates bobbing and turning (one buffer upload); a taken one is a scale of 0.
func _draw_crates() -> void:
	if _crate_mm == null or crates.is_empty() or not _crate_mm.visible:
		return
	for i in crates.size():
		var c: Vector2 = crates[i]
		var b := i * 16
		var sc := 0.0 if _crate_taken[i] else 1.0
		var yaw := wave_t * 0.9 + float(i) * 1.3
		var cy := cos(yaw) * sc
		var sy := sin(yaw) * sc
		_crate_buf[b] = cy
		_crate_buf[b + 1] = 0.0
		_crate_buf[b + 2] = sy
		_crate_buf[b + 3] = c.x
		_crate_buf[b + 4] = 0.0
		_crate_buf[b + 5] = sc
		_crate_buf[b + 6] = 0.0
		_crate_buf[b + 7] = water_y + 0.08 * sin(wave_t * 2.6 + float(i))
		_crate_buf[b + 8] = -sy
		_crate_buf[b + 9] = 0.0
		_crate_buf[b + 10] = cy
		_crate_buf[b + 11] = c.y
	if _crate_mm.is_inside_tree():
		InstanceBuffers.send(_crate_mm.multimesh.get_rid(), _crate_buf)


## The player over a crate takes it: nitro, a coin's ting climbing with the chain, a shoal of three.
func _crates_tick() -> void:
	var r: Dictionary = racers[0]
	if bool(r["out"]) or bool(r["finished"]):
		return
	var b: Boat = boats[0]
	var reach := CRATE_R * CRATE_R
	for i in crates.size():
		if _crate_taken[i] or b.pos.distance_squared_to(crates[i]) > reach:
			continue
		_crate_taken[i] = true
		sprats += 1
		_fill(FILL_CRATE)
		while not _crate_times.is_empty() and clock_t - _crate_times[0] > SHOAL_T:
			_crate_times.pop_front()
		_crate_times.append(clock_t)
		var chain := _crate_times.size()
		_play("coin", 1.0 + 0.05 * float(chain))
		_spray.burst(Vector3(crates[i].x, water_y + 0.4, crates[i].y), SPRAY_BURST, 0.8)
		if chain >= SHOAL_N:
			_crate_times.clear()
			shoals += 1
			_fill(FILL_SHOAL)
			_toast_words("hud_shoal")
			Access.buzz(30, 0.5)
		_log("crate %d (%d this race)" % [i, sprats])


## Spray off every fast hull near the player (more on nitro), then the pool's frame.
func _spray_tick(dt: float) -> void:
	if _spray == null or player == null:
		return
	var me: Boat = boats[0]
	for k in boats.size():
		var b: Boat = boats[k]
		if not b.visible or b.air or b.pos.distance_to(me.pos) > SPRAY_NEAR:
			_spray_acc[k] = 0.0
			continue
		var rate := SPRAY_RATE if b.forward_speed() > SPRAY_SPEED * float(b.spec["top"]) else 0.0
		if k == 0 and nitro_on:
			rate = SPRAY_NITRO
		if rate <= 0.0:
			_spray_acc[k] = 0.0
			continue
		_spray_acc[k] += rate * dt
		var f: Vector2 = b.forward()
		var right := Vector2(f.y, -f.x)
		var half := float(b.spec["len"]) * 0.5
		while _spray_acc[k] >= 1.0:
			_spray_acc[k] -= 1.0
			var side := 1.0 if _spray.rand(-1.0, 1.0) >= 0.0 else -1.0
			var at2: Vector2 = b.pos + f * half * _spray.rand(0.0, 0.5) + right * side * b.radius() * 0.7
			var out: Vector2 = right * side * _spray.rand(2.0, 4.5) + b.vel * 0.35
			if k == 0 and nitro_on:
				at2 = b.pos - f * half * _spray.rand(0.9, 1.1) + right * _spray.rand(-0.5, 0.5)
				out = -f * _spray.rand(1.0, 3.0) + b.vel * 0.6 + right * _spray.rand(-1.5, 1.5)
			_spray.emit(Vector3(at2.x, water_y + 0.3, at2.y), Vector3(out.x, _spray.rand(2.5, 5.5), out.y))
	_spray.step(dt, Vector3(me.pos.x, water_y, me.pos.y))


## The nitro's flame: one bright box at the player's stern, shown while it burns (one draw call).
func _build_flame() -> void:
	var bm := BoxMesh.new()
	bm.size = Vector3(0.55, 0.4, 1.4)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("#ffb13b")
	bm.material = m
	_flame = MeshInstance3D.new()
	_flame.name = "NitroFlame"
	_flame.mesh = bm
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flame.position = Vector3(0.0, 0.55, -float(boats[0].spec["len"]) * 0.5 - 0.6)
	_flame.visible = false
	boats[0].add_child(_flame)


## The rival just ahead of the player in the standings (main.gd's rank tag), -1 when leading.
func rival_ahead() -> int:
	if racers.is_empty() or bool(racers[0]["finished"]) or bool(racers[0]["out"]):
		return -1
	var mine := float(racers[0]["li"])
	var best := -1
	var bl := INF
	for k in range(1, racers.size()):
		var o: Dictionary = racers[k]
		if bool(o["out"]) or bool(o["finished"]):
			continue
		var li := float(o["li"])
		if li > mine and li < bl:
			bl = li
			best = k
	return best


# --- the ducks and the camera's look ------------------------------------------------------------------

## Three families, placed between ordinary rings by their share of the course.
func _build_ducks() -> void:
	var ord: Array = []
	for i in rings.size():
		if not bool(rings[i]["gold"]) and not bool(rings[i]["finish"]):
			ord.append(i)
	for share: float in DUCK_SPOTS:
		var a := int(ord[clampi(int(float(ord.size() - 2) * share), 0, ord.size() - 2)])
		var b := int(ord[clampi(int(float(ord.size() - 2) * share) + 1, 0, ord.size() - 1)])
		var pa := Vector2(float(rings[a]["x"]), float(rings[a]["z"]))
		var pb := Vector2(float(rings[b]["x"]), float(rings[b]["z"]))
		var mid := pa.lerp(pb, 0.5)
		var along := (pb - pa).normalized()
		var node := MeshInstance3D.new()
		node.mesh = _duck_mesh()
		node.material_override = Models.material()
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visible = false
		add_child(node)
		_ducks.append({"node": node, "at": mid, "across": Vector2(-along.y, along.x), "along": along,
				"phase": float(_ducks.size()) * 2.1, "state": 0, "t": 0.0, "pos": mid})


## A mother (yellow bill, brown) and four ducklings in a line behind her, +Z forward.
static func _duck_mesh() -> ArrayMesh:
	var st := Models._begin()
	var brown := Color("#6b4a2b")
	var cream := Color("#efe3b8")
	var fluff := Color("#f2cf3f")
	var bill := Color("#ee8b1d")
	Models.box(st, Vector3(0, 0.22, 0), Vector3(0.7, 0.4, 1.0), brown)
	Models.box(st, Vector3(0, 0.45, 0.45), Vector3(0.36, 0.4, 0.36), Color("#2f6b3a"))
	Models.box(st, Vector3(0, 0.42, 0.72), Vector3(0.18, 0.1, 0.22), bill)
	Models.box(st, Vector3(0, 0.1, -0.1), Vector3(0.74, 0.1, 0.9), cream)
	for j in 4:
		var z := -1.6 - 0.9 * float(j)
		var x := 0.15 * float(j % 2) - 0.07
		Models.box(st, Vector3(x, 0.12, z), Vector3(0.3, 0.2, 0.4), fluff)
		Models.box(st, Vector3(x, 0.26, z + 0.2), Vector3(0.18, 0.18, 0.18), fluff)
		Models.box(st, Vector3(x, 0.24, z + 0.32), Vector3(0.08, 0.05, 0.1), bill)
	return st.commit()


func _reset_ducks() -> void:
	ducks_scared = 0
	_ducks_ok_said = false
	for d: Dictionary in _ducks:
		d["state"] = 0
		d["t"] = 0.0
		d["near"] = false
		d["clean"] = false
		(d["node"] as MeshInstance3D).visible = true
	_ducks_tick(0.0)


## Pacing across the line, the scare (any boat near the mother), the flight.
func _ducks_tick(dt: float) -> void:
	for d: Dictionary in _ducks:
		var node: MeshInstance3D = d["node"]
		d["t"] = float(d["t"]) + dt
		var st := int(d["state"])
		if st == 2:
			node.visible = false
			continue
		if st == 0:
			var swing := sin(wave_t * DUCK_RATE + float(d["phase"]))
			var c: Vector2 = d["at"]
			var across: Vector2 = d["across"]
			var p: Vector2 = c + across * swing * DUCK_SWING
			d["pos"] = p
			var heading: Vector2 = across * (1.0 if cos(wave_t * DUCK_RATE + float(d["phase"])) >= 0.0 else -1.0)
			node.position = Vector3(p.x, water_y + 0.05 + 0.05 * sin(wave_t * 3.0 + float(d["phase"])), p.y)
			node.rotation = Vector3(0.0, atan2(heading.x, heading.y), 0.0)
			if stage != Stage.RACE:
				continue
			for k in boats.size():
				var r: Dictionary = racers[k]
				if bool(r["out"]) or bool(r["finished"]):
					continue
				var b: Boat = boats[k]
				var dist := b.pos.distance_to(p)
				if dist < DUCK_HIT:
					_scare(d, k)
					break
				if k == 0 and dist < DUCK_NEAR and float(d["t"]) > 2.0:
					d["near"] = true
					if not _ducks_ok_said:
						_ducks_ok_said = true
						hud.ambient_toast("Kaczki bezpieczne!", "Ducks safe!")
				elif k == 0 and bool(d.get("near", false)) and not bool(d.get("clean", false)) and dist > DUCK_NEAR * 1.6:
					# Past the family close and nobody scared: a clean pass fills the tank.
					d["clean"] = true
					_fill(FILL_DUCKS)
		else:
			# Flying off: up and away, flapping.
			var tt := float(d["t"])
			var c2: Vector3 = node.position
			c2.y += (5.0 - tt * 2.0) * dt
			c2.x += float(d.get("vx", 0.0)) * dt
			c2.z += float(d.get("vz", 0.0)) * dt
			node.position = c2
			node.rotation.z = sin(tt * 28.0) * 0.5
			node.rotation.x = -0.35
			if tt > DUCK_FLY:
				d["state"] = 2
				node.visible = false


func _scare(d: Dictionary, k: int) -> void:
	d["state"] = 1
	d["t"] = 0.0
	var b: Boat = boats[k]
	var away: Vector2 = ((d["pos"] as Vector2) - b.pos).normalized()
	d["vx"] = away.x * 9.0
	d["vz"] = away.y * 9.0
	b.vel *= DUCK_BRAKE
	ducks_scared += 1
	_log("%s scatters the ducks" % racers[k]["name"])
	if k == 0:
		racers[0]["rhythm"] = maxi(int(racers[0]["rhythm"]) - 1, 0)
		_fill(-COST_DUCK)
		_play("quack")
		_play("pigeons", 1.3)
		Access.buzz(40, 0.6)
		_toast_words("hud_duck_scare")
		_say(-1, "duck")
	else:
		_say(k, "duck")
		if sfx != null:
			var dp: Vector2 = d["pos"]
			sfx.play_at("quack", Vector3(dp.x, water_y, dp.y))


## The camera's look in the race (view only; main.gd `_update_camera` reads it): the camera drops
## a few degrees as the boat comes up to speed (the horizon climbs: speed you can see), leans with
## the turn (a dutch roll) and kicks on a boost. Returns (extra pitch down in degrees, roll in degrees).
func look(dt: float) -> Vector2:
	var want := Vector2.ZERO
	if boating() and player != null and stage in [Stage.RACE, Stage.COUNTDOWN, Stage.OUT, Stage.DONE]:
		var top: float = maxf(float(player.spec["top"]), 1.0)
		var sp := clampf(player.forward_speed() / top, 0.0, 1.2)
		want.x = LOOK_PITCH * sp + (LOOK_KICK_NITRO if nitro_on else (LOOK_KICK if boost_now() else 0.0))
		want.y = clampf(-player.yaw_rate * LOOK_ROLL_PER_RAD, -LOOK_ROLL, LOOK_ROLL) * clampf(sp * 1.5, 0.0, 1.0)
	_look = _look.lerp(want, 1.0 - exp(-3.2 * dt))
	return _look


const LOOK_PITCH := 7.0       # deg lower at full speed (30 -> 23: more water ahead, the horizon up)
const LOOK_KICK := 2.5        # deg more while a boost runs
const LOOK_KICK_NITRO := 4.0  # deg more while the nitro burns
const LOOK_ROLL := 5.5        # deg of dutch roll at most
const LOOK_ROLL_PER_RAD := 6.0


func boost_now() -> bool:
	if racers.is_empty():
		return false
	return float(racers[0]["gold_t"]) > 0.0 or float(racers[0]["jump_t"]) > 0.0 or float(racers[0]["inside_t"]) > 0.0 or nitro_on


# --- the river: waves, wakes, the barge, the solid world -----------------------------------------------

## The water's height over its rest level at (x, z): the chop and the wake rings.
func wave(x: float, z: float, skip := -1) -> float:
	var h := CHOP * (sin(0.31 * x + 1.7 * wave_t) * 0.6 + sin(0.23 * z - 1.3 * wave_t + 0.11 * x) * 0.4)
	for s in _wakes.size():
		var ws: Array = _wakes[s]
		for w: Array in ws:
			var age: float = wave_t - float(w[1])
			if age > WAKE_LIFE or (s == skip and age < OWN_WAKE):
				continue
			var p: Vector2 = w[0]
			var r := 2.0 + age * WAKE_SPREAD
			var dx := x - p.x
			var dz := z - p.y
			var d2 := dx * dx + dz * dz
			var width := WAKE_W + age * 0.9
			var lo := r - width
			var hi := r + width
			if d2 < lo * lo or d2 > hi * hi:
				continue
			var u := (sqrt(d2) - r) / width
			h += float(w[2]) * exp(-age / 1.4) * (1.0 - u * u)
	return h


func _tick_wakes(dt: float) -> void:
	wave_t += dt
	for k in boats.size():
		var b: Boat = boats[k]
		_wake_t[k] = float(_wake_t[k]) + dt
		var v: float = b.speed()
		if b.visible and v > 4.0 and not b.air and float(_wake_t[k]) >= WAKE_EVERY:
			_wake_t[k] = 0.0
			var amp: float = float(b.spec["wake"]) * clampf(v / float(b.spec["top"]), 0.0, 1.2)
			if b.kind == Boat.Kind.TUB:
				amp = maxf(amp, 0.5)  # Pan Zdzisiek's tub: a wake worth hopping
			_drop(k, b.pos - b.forward() * float(b.spec["len"]) * 0.45, amp, b.forward())
	if _barge.visible:
		var s := boats.size()
		_wake_t[s] = float(_wake_t[s]) + dt
		if float(_wake_t[s]) >= WAKE_EVERY * 1.6:
			_wake_t[s] = 0.0
			_drop(s, _barge_pos + _barge_dir * BARGE_LEN * 0.45, BARGE_WAKE, _barge_dir)
			_drop(s + 1, _barge_pos - _barge_dir * BARGE_LEN * 0.45, BARGE_WAKE * 0.7, _barge_dir)


func _drop(s: int, p: Vector2, amp: float, dir: Vector2) -> void:
	var ws: Array = _wakes[s]
	ws.append([p, wave_t, amp, atan2(-dir.y, -dir.x)])
	if ws.size() > WAKE_N:
		ws.pop_front()


func _place_barge() -> void:
	var a := int(barge_cfg.get("from", 175))
	_barge_li = float(a)
	_barge_at()
	_barge.visible = true


func _barge_at() -> void:
	var i := clampi(int(_barge_li), 1, line.size() - 2)
	var n := line[i + 1] - line[i - 1]
	var dir := -n.normalized()   # upstream
	var across := Vector2(-n.y, n.x).normalized()
	# Its lane (tools/boat_course.py: off the right bank, round the bridge piers), metres across.
	var lane: Array = barge_cfg.get("lane", [])
	var off: float = float(lane[i]) if i < lane.size() else float(barge_cfg.get("side", 0.55)) * half_w[i]
	var off2: float = float(lane[i + 1]) if i + 1 < lane.size() else off
	off = lerpf(off, off2, _barge_li - floorf(_barge_li))
	_barge_pos = line[i].lerp(line[i + 1], _barge_li - floorf(_barge_li)) + across * off
	_barge_dir = dir
	_barge.position = Vector3(_barge_pos.x, water_y, _barge_pos.y)
	_barge.rotation.y = atan2(dir.x, dir.y)


func _barge_tick(dt: float) -> void:
	if not _barge.visible:
		return
	_barge_li -= BARGE_SPEED * dt / 10.0
	if _barge_li <= float(barge_cfg.get("to", 20)):
		_barge.visible = false
		return
	_barge_at()


## The physics test for a boat: the bridge piers, the moored barges and the marina (whatever has a
## collider), and the moving barge (a capsule): the push out, ZERO when clear.
func solid_at(centre: Vector3, r: float) -> Vector2:
	var out := Vector2.ZERO
	if _barge.visible:
		var p := Vector2(centre.x, centre.z)
		var a := _barge_pos - _barge_dir * (BARGE_LEN * 0.5 - BARGE_HALF_W)
		var b := _barge_pos + _barge_dir * (BARGE_LEN * 0.5 - BARGE_HALF_W)
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := p.distance_to(q)
		if d < BARGE_HALF_W + r and d > 0.001:
			out += (p - q) / d * (BARGE_HALF_W + r - d)
	var p2 := Vector2(centre.x, centre.z)
	var pq := Geometry2D.get_closest_point_to_segment(p2, PONTOON[0], PONTOON[1])
	var pd := p2.distance_to(pq)
	if pd < PONTOON_HALF_W + r and pd > 0.001:
		out += (p2 - pq) / pd * (PONTOON_HALF_W + r - pd)
	# The moored fleet (not the one out).
	for i in fleet.size():
		if i == riding:
			continue
		var mq := p2 - fleet_spot(i)
		var mr := float(fleet[i].spec["r"]) + r
		if mq.length_squared() < mr * mr and mq.length_squared() > 0.0001:
			out += mq.normalized() * (mr - mq.length())
	var cell := Vector2i(floori(p2.x / PIER_CELL), floori(p2.y / PIER_CELL))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for c: Vector3 in _piers.get(cell + Vector2i(dx, dz), []):
				var q := p2 - Vector2(c.x, c.y)
				var reach := c.z + r
				var l2 := q.length_squared()
				if l2 < reach * reach and l2 > 0.0001:
					var l := sqrt(l2)
					out += q / l * (reach - l)
	if not is_inside_tree():
		return out
	var space := _foam.get_world_3d().direct_space_state
	_hull.radius = r
	_query.transform = Transform3D(Basis.IDENTITY, Vector3(centre.x, water_y + (HULL_BAND.x + HULL_BAND.y) * 0.5, centre.z))
	if car != null and car is CollisionObject3D:
		_query.exclude = [(car as CollisionObject3D).get_rid()]
	var info := space.get_rest_info(_query)
	if not info.is_empty():
		var n: Vector3 = info["normal"]
		var pt: Vector3 = info["point"]
		var flat := Vector2(centre.x - pt.x, centre.z - pt.z)
		var d := flat.length()
		var nn := Vector2(n.x, n.z)
		if d > 0.001:
			nn = flat / d
		if nn.length_squared() > 0.0001:
			out += nn.normalized() * maxf(0.0, r - d + 0.05)
			if log_on and wave_t - _solid_log > 1.0:
				_solid_log = wave_t
				_log("solid at %.0f, %.0f, contact %.1f m over the water (%s)" % [centre.x, centre.z, pt.y - water_y, str(info.get("collider_id", ""))])
	return out


# --- the look -------------------------------------------------------------------------------------------

func _build_materials() -> void:
	for key: String in ["ring", "next", "gold", "finish"]:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var c: Color = {"ring": RING, "next": RING_NEXT, "gold": GOLD, "finish": Color("#f4f2ea")}[key]
		m.albedo_color = c
		_mats[key] = m
	var foam := StandardMaterial3D.new()
	foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam.vertex_color_use_as_albedo = true
	foam.cull_mode = BaseMaterial3D.CULL_DISABLED
	foam.render_priority = 1
	_mats["foam"] = foam


## A ring: an upright half torus standing in the water (the boats go through under its arch),
## orange with white bands and a float at each foot. Width w, tube 0.45 m.
static func ring_mesh(w: float, paint: Color, band: Color, inside := 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var big := w * 0.5
	var tube := 0.45 if w < 30.0 else 0.8
	var segs := 18
	var sides := 6
	for i in segs:
		var a0 := PI * float(i) / segs
		var a1 := PI * float(i + 1) / segs
		var c := band if i % 3 == 1 else paint
		for j in sides:
			var b0 := TAU * float(j) / sides
			var b1 := TAU * float(j + 1) / sides
			var q := [_torus(big, tube, a0, b0), _torus(big, tube, a1, b0), _torus(big, tube, a1, b1), _torus(big, tube, a0, b1)]
			var n: Vector3 = (q[1] - q[0]).cross(q[3] - q[0]).normalized()
			for v: Vector3 in [q[0], q[1], q[2], q[0], q[2], q[3]]:
				st.set_color(c)
				st.set_normal(n)
				st.set_uv(Vector2(Models.FIXED, 0.0))
				st.add_vertex(v)
	for s: float in [-1.0, 1.0]:
		Models.box(st, Vector3(s * big, 0.2, 0.0), Vector3(1.6, 0.7, 1.6), paint)
	if inside != 0.0:
		# The inside buoy: a taller gold cap on the side of the next ring.
		Models.box(st, Vector3(inside * big, 1.1, 0.0), Vector3(1.9, 1.6, 1.9), GOLD)
	return st.commit()


static func _torus(big: float, tube: float, a: float, b: float) -> Vector3:
	var centre := Vector3(cos(a) * big, sin(a) * big, 0.0)
	var out := Vector3(cos(a), sin(a), 0.0)
	return centre + out * cos(b) * tube + Vector3(0, 0, 1) * sin(b) * tube


func _build_rings() -> void:
	for g: Dictionary in rings:
		var mi := MeshInstance3D.new()
		var w := float(g["w"])
		if bool(g["finish"]):
			mi.mesh = ring_mesh(w, Color("#f4f2ea"), Color("#c8202c"))
		elif bool(g["gold"]):
			mi.mesh = ring_mesh(w, GOLD, Color("#fff6c8"))
		else:
			mi.mesh = ring_mesh(w, RING, Color("#fff4ea"), float(g["in"]))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(float(g["x"]), water_y, float(g["z"]))
		# The ring's plane is across the course: its forward (sin, cos)(yaw) is its normal.
		mi.rotation.y = float(g["yaw"])
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		mi.material_override = m
		mi.visible = false
		add_child(mi)
		_ring_nodes.append(mi)


## The floating ramps (one mesh each, shown only while racing).
func _build_ramps() -> void:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.8
	for rp: Dictionary in ramps:
		var mi := MeshInstance3D.new()
		mi.mesh = ramp_mesh(float(rp["w"]), float(rp["len"]))
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(float(rp["x"]), water_y, float(rp["z"]))
		mi.rotation.y = float(rp["yaw"])
		mi.visible = false
		add_child(mi)
		_ramp_nodes.append(mi)


## A floating ski-jump ramp: a wedge w wide and l long rising to RAMP_H at its far end (+Z), white
## with orange chevrons pointing the way, on two orange pontoon floats, a red lip.
static func ramp_mesh(w: float, l: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := RAMP_H
	var hw := w * 0.5
	var strips := 6
	for i in strips:
		var z0 := -l * 0.5 + l * float(i) / strips
		var z1 := -l * 0.5 + l * float(i + 1) / strips
		var y0 := h * float(i) / strips + 0.08
		var y1 := h * float(i + 1) / strips + 0.08
		var c := Color("#ff7a1a") if i % 2 == 1 else Color("#f4f2ea")
		var n := Vector3(0.0, l / strips, -(y1 - y0)).normalized()
		for v: Vector3 in [Vector3(-hw, y0, z0), Vector3(hw, y0, z0), Vector3(hw, y1, z1),
				Vector3(-hw, y0, z0), Vector3(hw, y1, z1), Vector3(-hw, y1, z1)]:
			st.set_color(c)
			st.set_normal(n)
			st.set_uv(Vector2(Models.FIXED, 0.0))
			st.add_vertex(v)
	# The sides and the back face.
	for s: float in [-1.0, 1.0]:
		for v: Vector3 in [Vector3(s * hw, 0.0, -l * 0.5), Vector3(s * hw, 0.0, l * 0.5), Vector3(s * hw, h + 0.08, l * 0.5)]:
			st.set_color(Color("#d8d4c8"))
			st.set_normal(Vector3(s, 0.0, 0.0))
			st.set_uv(Vector2(Models.FIXED, 0.0))
			st.add_vertex(v)
	for v: Vector3 in [Vector3(-hw, 0.0, l * 0.5), Vector3(hw, h + 0.08, l * 0.5), Vector3(hw, 0.0, l * 0.5),
			Vector3(-hw, 0.0, l * 0.5), Vector3(-hw, h + 0.08, l * 0.5), Vector3(hw, h + 0.08, l * 0.5)]:
		st.set_color(Color("#d8d4c8"))
		st.set_normal(Vector3(0.0, 0.0, 1.0))
		st.set_uv(Vector2(Models.FIXED, 0.0))
		st.add_vertex(v)
	Models.box(st, Vector3(0.0, h + 0.12, l * 0.5 - 0.15), Vector3(w + 0.2, 0.18, 0.3), Color("#c8202c"))
	for s: float in [-1.0, 1.0]:
		Models.box(st, Vector3(s * (hw + 0.45), 0.2, 0.0), Vector3(0.9, 0.6, l + 0.6), Color("#ff7a1a"))
		# Details (F 2026-11-10: "a lot of details"): a mast with a red-and-white pennant at the lip
		# of each float so the ramp reads from far at the new speed, a white strip along each edge,
		# a black "tyre" bumper at the nose and a stripe of lights (small boxes) up the middle.
		Models.box(st, Vector3(s * (hw + 0.45), 1.9, l * 0.5 - 0.3), Vector3(0.12, 3.0, 0.12), Color("#d8d4c8"))
		Models.box(st, Vector3(s * (hw + 0.45), 3.15, l * 0.5 - 0.3), Vector3(0.9, 0.5, 0.06), Color("#c8202c"))
		Models.box(st, Vector3(s * (hw + 0.45), 3.15, l * 0.5 - 0.3), Vector3(0.45, 0.5, 0.08), Color("#f4f2ea"))
		Models.box(st, Vector3(s * (hw - 0.2), h * 0.5 + 0.12, 0.0), Vector3(0.2, 0.06, l * 0.96), Color("#f4f2ea"))
		Models.box(st, Vector3(s * (hw + 0.45), 0.0, -l * 0.5 - 0.2), Vector3(0.9, 0.5, 0.4), Color("#26282b"))
	for i in 5:
		var z := -l * 0.5 + l * (float(i) + 0.5) / 5.0
		Models.box(st, Vector3(0.0, h * (float(i) + 0.5) / 5.0 + 0.12, z), Vector3(0.35, 0.05, 0.35), Color("#ffd23a"))
	return st.commit()


## The player's next ring bright, the two after it dim, the finish when near; the rest hidden.
func _update_rings() -> void:
	if racers.is_empty():
		return
	var nxt := int(racers[0]["next"])
	var shown := 0
	for i in _ring_nodes.size():
		var mi := _ring_nodes[i]
		var g: Dictionary = rings[i]
		var on: bool = i >= nxt and (shown < 3 or bool(g["finish"]) and boats[0].pos.distance_to(Vector2(float(g["x"]), float(g["z"]))) < 500.0)
		if on and i >= nxt and not bool(g["finish"]):
			shown += 1
		mi.visible = on and stage in [Stage.COUNTDOWN, Stage.RACE]
		var m := mi.material_override as StandardMaterial3D
		var tint := Color(1, 1, 1) if i == nxt else Color(0.72, 0.72, 0.72)
		if not m.albedo_color.is_equal_approx(tint):
			m.albedo_color = tint


func _build_boats() -> void:
	var mat := Models.material()
	var meshes := [
		Boat.runabout_mesh(PLAYER_PAINT, Color("#f2f2ee"), Color("#ff8a1a"), Color("#3a2a1c"), 0.55),
		Boat.runabout_mesh(Color(RIVALS[0]["paint"]), Color("#a0a4aa"), Color(RIVALS[0]["shirt"]), Color(RIVALS[0]["hair"])),
		Boat.tub_mesh(),
		Boat.jetski_mesh(),
	]
	var kinds := [Boat.Kind.RUNABOUT, RIVALS[0]["kind"], RIVALS[1]["kind"], RIVALS[2]["kind"]]
	for k in 4:
		var b := Boat.new()
		b.name = "Boat%d" % k
		add_child(b)
		b.setup(int(kinds[k]), meshes[k], mat)
		b.water_y = water_y
		b.flow = flow_dir * FLOW
		var kk := k
		b.wave = func(x: float, z: float) -> float: return wave(x, z, kk)
		if map != null:
			b.shore = map.shore_distance
		b.solid = solid_at
		boats.append(b)
		_wakes.append([])
		_wake_t.append(0.0)
	for b: Boat in boats:
		b.others = boats
	_wakes.append([])
	_wakes.append([])
	_wake_t.append(0.0)
	_wake_t.append(0.0)
	player = boats[0]


## The sand barge pushed upstream by its pusher tug (a Vistula sight): 72 m, the heap of sand in
## the hold, the tug's wheelhouse up high at the back.
func _build_barge() -> void:
	var st := Models._begin()
	var hull := Color("#2d3138")
	var rust := Color("#7a3b25")
	var sand := Color("#d9c08a")
	var L := BARGE_LEN
	var W := BARGE_HALF_W * 2.0
	# the barge (front 54 m)
	Models.box(st, Vector3(0, 0.5, L * 0.5 - 27.0), Vector3(W, 1.8, 54.0), hull)
	Models.box(st, Vector3(0, 0.0, L * 0.5 - 27.0), Vector3(W + 0.1, 0.5, 54.1), rust)
	Models.box(st, Vector3(0, 1.8, L * 0.5 - 27.0), Vector3(W - 1.6, 1.4, 48.0), sand)
	Models.box(st, Vector3(0, 2.6, L * 0.5 - 27.0), Vector3(W - 4.0, 0.8, 36.0), sand.lightened(0.08))
	# the pusher tug (back 16 m)
	Models.box(st, Vector3(0, 0.6, -L * 0.5 + 8.0), Vector3(W - 1.0, 2.0, 16.0), Color("#1d4b7a"))
	Models.box(st, Vector3(0, 2.6, -L * 0.5 + 7.0), Vector3(W - 4.0, 2.2, 7.0), Color("#efeee8"))
	Models.box(st, Vector3(0, 5.0, -L * 0.5 + 7.5), Vector3(W - 5.0, 2.4, 4.0), Color("#efeee8"))
	Models.box(st, Vector3(0, 5.3, -L * 0.5 + 9.55), Vector3(W - 5.2, 0.8, 0.08), Boat.GLASS)
	Models.box(st, Vector3(0, 6.6, -L * 0.5 + 7.5), Vector3(W - 4.6, 0.25, 4.6), Color("#1d4b7a"))
	Models.box(st, Vector3(1.6, 7.6, -L * 0.5 + 6.0), Vector3(0.5, 2.0, 0.5), Color("#c8202c"))
	Models.box(st, Vector3(0, 0.5, L * 0.5 - 0.5), Vector3(W, 2.2, 1.0), Color("#f2c230"))
	_barge = MeshInstance3D.new()
	_barge.mesh = st.commit()
	_barge.material_override = Models.material()
	_barge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_barge.visible = false
	add_child(_barge)


## The start pontoon at the mouth of Port Czerniakowski: a floating deck on pontoon floats, a
## gangway to the bank, bollards, the race's flags and a banner "WIŚLANA SZPROTKA · START".
func _build_pontoon(world: Node3D) -> void:
	var st := Models._begin()
	var a: Vector2 = PONTOON[0]
	var b: Vector2 = PONTOON[1]
	var mid := (a + b) * 0.5
	var along := (b - a)
	var length := along.length()
	var dir := along / length
	var yaw := atan2(dir.x, dir.y)
	var deck := Color("#8a6a48")
	var float_c := Color("#3a3d44")
	var gy: float = water_y
	# Local frame: +Z along the pontoon (bank to river), x across.
	Models.box(st, Vector3(0, 0.55, 0), Vector3(3.2, 0.18, length), deck)
	for z in range(int(-length * 0.5) + 2, int(length * 0.5), 4):
		Models.box(st, Vector3(-1.2, 0.2, float(z)), Vector3(0.8, 0.6, 3.2), float_c)
		Models.box(st, Vector3(1.2, 0.2, float(z)), Vector3(0.8, 0.6, 3.2), float_c)
	# bollards and the railing on the river end
	for z: float in [-length * 0.5 + 3.0, 0.0, length * 0.5 - 1.0]:
		for x: float in [-1.45, 1.45]:
			Models.box(st, Vector3(x, 0.85, z), Vector3(0.25, 0.4, 0.25), Color("#26282b"))
	# the flag masts: blue and white race flags
	for k in 4:
		var z := -length * 0.5 + 6.0 + float(k) * (length - 8.0) / 3.0
		Models.box(st, Vector3(1.5, 3.0, z), Vector3(0.08, 4.8, 0.08), Color("#d8d8d2"))
		Models.box(st, Vector3(1.5, 5.0, z + 0.55), Vector3(0.04, 0.8, 1.0), COLOUR if k % 2 == 0 else Color("#f4f2ea"))
	# the banner arch over the river end
	var e := length * 0.5 - 2.0
	Models.box(st, Vector3(-1.5, 2.4, e), Vector3(0.18, 3.6, 0.18), Color("#d8d8d2"))
	Models.box(st, Vector3(1.5, 2.4, e), Vector3(0.18, 3.6, 0.18), Color("#d8d8d2"))
	Models.box(st, Vector3(0, 4.0, e), Vector3(3.6, 0.9, 0.12), COLOUR)
	Boat._part = Models.FIXED
	Boat._glow = 0.0
	# The gangway: from the deck's bank end up to the top of the bank (found along the pontoon's
	# line, where the water ends), a sloped plank with a rail on each side.
	var edge := a
	if map != null:
		for k in 40:
			edge = a - dir * float(k)
			if map.shore_distance(edge.x, edge.y) <= 0.0:
				break
	var reach := (a - edge).length() + 1.5
	var bank_y: float = map.ground_height(edge.x - dir.x * 1.5, edge.y - dir.y * 1.5) if map != null else gy + 1.0
	var top := Vector3(0, clampf(bank_y - gy, 0.3, 4.0) + 0.05, -length * 0.5 - reach)
	var foot := Vector3(0, 0.66, -length * 0.5)
	for s2: float in [-1.0, 1.0]:
		Boat._quad(st, foot + Vector3(-0.7, 0, 0), foot + Vector3(0.7, 0, 0), top + Vector3(0.7, 0, 0), top + Vector3(-0.7, 0, 0), deck.darkened(0.15), s2)
		Boat._quad(st, foot + Vector3(s2 * 0.7, 0, 0), top + Vector3(s2 * 0.7, 0, 0), top + Vector3(s2 * 0.7, 0.9, 0), foot + Vector3(s2 * 0.7, 0.9, 0), Color("#26282b"), 1.0)
	var mesh := st.commit()
	_pontoon = MeshInstance3D.new()
	_pontoon.mesh = mesh
	_pontoon.material_override = Models.material()
	_pontoon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pontoon.position = Vector3(mid.x, gy, mid.y)
	_pontoon.rotation.y = yaw
	world.add_child(_pontoon)


## The foam: every wake ring as two arcs (the V behind the boat), white fading with age; a short
## spray strip behind each fast boat.
func _draw_foam() -> void:
	_foam_mesh.clear_surfaces()
	var any := false
	var y := water_y + 0.12
	for s in _wakes.size():
		for w: Array in _wakes[s]:
			var age: float = wave_t - float(w[1])
			if age > WAKE_LIFE:
				continue
			if not any:
				_foam_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
				any = true
			var p: Vector2 = w[0]
			var r := 2.0 + age * WAKE_SPREAD
			var alpha := clampf(float(w[2]) * 1.6, 0.15, 0.85) * (1.0 - age / WAKE_LIFE)
			var c := Color(0.95, 0.97, 1.0, alpha)
			var thick := 0.3 + float(w[2]) * 0.5
			var back: float = w[3]
			# The two arms of the V behind the boat (the Kelvin wake's look), a gap down the middle.
			for side: float in [-1.0, 1.0]:
				for k in 4:
					var a0: float = back + side * deg_to_rad(18.0 + 13.0 * k)
					var a1: float = back + side * deg_to_rad(18.0 + 13.0 * (k + 1))
					var i0 := Vector3(p.x + cos(a0) * (r - thick), y, p.y + sin(a0) * (r - thick))
					var o0 := Vector3(p.x + cos(a0) * (r + thick), y, p.y + sin(a0) * (r + thick))
					var i1 := Vector3(p.x + cos(a1) * (r - thick), y, p.y + sin(a1) * (r - thick))
					var o1 := Vector3(p.x + cos(a1) * (r + thick), y, p.y + sin(a1) * (r + thick))
					for v: Vector3 in [i0, o0, o1, i0, o1, i1]:
						_foam_mesh.surface_set_color(c)
						_foam_mesh.surface_add_vertex(v)
	if hugging and stage == Stage.RACE:
		# Near the bank: up to 8 short white dashes along the hull's bank side (the same draw call).
		if not any:
			_foam_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			any = true
		var hb: Boat = boats[0]
		var hf: Vector2 = hb.forward()
		var hr := Vector2(hf.y, -hf.x) * _hug_side
		var hl := float(hb.spec["len"])
		var edge: Vector2 = hb.pos + hr * (hb.radius() * 0.85 + 0.2)
		for k in 8:
			var along := hl * 0.45 - hl * 1.4 * float(k) / 8.0
			var flick := 0.5 + 0.5 * sin(wave_t * 23.0 + float(k) * 1.7)
			var a2: Vector2 = edge + hf * along + hr * (0.15 * float(k))
			var b2: Vector2 = a2 - hf * (0.6 + 0.4 * flick)
			var wv := hr * (0.22 + 0.05 * float(k))
			var col := Color(0.97, 0.99, 1.0, 0.85 * (1.0 - float(k) / 9.0) * (0.6 + 0.4 * flick))
			var q0 := Vector3(a2.x, y + 0.03, a2.y)
			var q1 := Vector3(a2.x + wv.x, y + 0.03, a2.y + wv.y)
			var q2 := Vector3(b2.x + wv.x, y + 0.03, b2.y + wv.y)
			var q3 := Vector3(b2.x, y + 0.03, b2.y)
			for v: Vector3 in [q0, q1, q2, q0, q2, q3]:
				_foam_mesh.surface_set_color(col)
				_foam_mesh.surface_add_vertex(v)
	if any:
		_foam_mesh.surface_end()


func _show_race(on: bool) -> void:
	for b: Boat in boats:
		b.visible = on
	for mi in _ramp_nodes:
		mi.visible = on
	_crate_mm.visible = on
	if not on:
		if _streaks != null:
			_streaks.off()
		_nitro_set(false)
		hugging = false
		hug_t = 0.0
		_spray.clear()
		for mi in _ring_nodes:
			mi.visible = false
		_barge.visible = false
		for d: Dictionary in _ducks:
			(d["node"] as MeshInstance3D).visible = false
		_foam_mesh.clear_surfaces()
		if hud != null:
			hud.set_minimap_dots(PackedVector2Array(), PackedColorArray())
