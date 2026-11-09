extends Node3D
## Nocny spot (F's ask 2026-11-06, docs/design/night-meet.md): the WARSAW NIGHT RACING CLUB.
##
## **The call.** At night (NIGHT_HOURS, the game clock) with nothing else on, Darek „Bawarka"
## (his car: the Bawarka 3.2, a parody of a Bavarian saloon) rings: the club meets tonight on Plac
## Defilad. ODBIERZ / ODRZUĆ, then JADĘ! / NIE DZIŚ.
##
## **Meet 1, Plac Defilad** (MEETS[0], the plaza east of the Palace). Six tuned cars parked in a
## ring with neon under them, Darek's Bawarka, a ring of people with their phones out, and in the
## middle Lena „Bokiem" spinning donuts in her Porszę 912 (a parody of a Stuttgart coupe): tyre
## smoke and a circle of black marks. Stop in the gap of the ring (the beacon): the club talks
## (MEET_LINES) for MEET_TALK s.
##
## **Raid 1.** Sirens: police.gd `raid` sends RAID_CARS patrol cars in from the roads round the
## plaza with a chase at koguty 2 on the player. The crowd runs, every car scatters (a glide off the
## plaza to the road, then racer mode away). Escape it (or let it end: the end of the shift, a
## caution: the night goes on either way).
##
## **The pin and the race.** A TYGRAM message: the next meet, the car park by the National Stadium
## (MEETS[1]). Every racer heads there too, from wherever it fled: first there gets the most
## (PLACE_PAY by place). The status shows the place live. The racers who get there park in the
## new ring.
##
## **Meet 2 and raid 2.** The club talks again; the police come again; the pin: the drag on Aleja
## Zieleniecka (STRIP: a straight 900 m, four lanes, by the Stadion station).
##
## **The drag.** Stop at the start (the beacon by the line): two pairs launch in front of you
## (kinematic cars down the strip), then START DRAG (the context button) puts you on the line next
## to Tadek's tinted Nisan Skajlajner (a parody of a Japanese GT). The tree (TREE_*): three ambers,
## green; moving before green is FALSTART (a loss). Four gears (GEARS, a share of the drag top,
## DRAG_TOP × the car's): at the top of each the button says BIEG!: on time (PERFECT s) is a burst
## (SHIFT_BOOST), late is just a shift, never is an auto-shift after AUTO_SHIFT s. The nitro button
## works (a bottle on loan, LOAN, without the garage's). Tadek's run is the "ok" run of the same car
## (sim_run) sped up to between it and a clean run (RIVAL_SKILL), so clean shifts or the nitro
## win. On the line and in the run the car holds the strip's line and any gas is full gas
## (hold_car): a drag is the launch and the shifts, not the steering (PT-33: the point-to-steer
## stick's aim and a part push lost 1.4 s against the sums). 402 m. A win: RESPECT, the club card (wallet.keep `wnrc_member`), the best time; a loss:
## REWANŻ.
##
## **F's pass, 2026-11-08** ("the car mission is lame"): the second meet moved to clear paving
## north-east of the stadium (the old one had two fences through the ring) and Lena and Darek
## drift a tandem there; the first meet talks 9 s, not 15; a raid drives CORDON patrol cars in
## across the plaza to box you in (the road chasers still come); the racers show on the minimap
## and race at about your own pace with every shortcut; the drag has a start gate over the line
## (stop on it to stage), a big 3-2-1-START! count, and a rev counter (DragTacho) you shift on
## yourself. Then, as in the CSR-style drag games: on the line the gas only revs the engine (keep the
## needle in the blue launch zone at green: a perfect launch; over it wheelspin, under it a bog;
## no false start by gas any more), and a shift in the yellow is "good", in the green "perfect",
## before the yellow "early", long on the limiter "late". During the drag the radio ticker,
## info notes and flavour toasts wait (hud.set_hush) and the bubbles are cleared.
##
## Nothing here per frame when idle (a TICK s look). During the quest: the meet's few draw calls
## (marks, smoke, glow, the crowd, three own cars and their lights, the start gate at the drag), the
## parked racers and the cordon are the traffic's pool cars (no new draw calls).
##
## Flags (main.gd): --meet-call (Darek rings now), --meet=on (night rules at any hour), --meet=0,
## --meet-at=raid|race|meet2|drag|stage (jump to that beat), --meet-log.

const Models := preload("res://scripts/models.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Beacon := preload("res://scripts/beacon.gd")
const Access := preload("res://scripts/access.gd")
const Notebook := preload("res://scripts/notebook.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Rave := preload("res://scripts/rave.gd")
const Lang := preload("res://scripts/lang.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")

const CLUB := "WARSAW NIGHT RACING CLUB"
const FRIEND := "Darek „Bawarka”"
const DRIFTER := "Lena „Bokiem”"
const BOSS := "Tadek"
const COLOUR := Color("#ff3d6e")        ## the club's colour: hot neon red
const PIN_COLOUR := Color("#38f6ff")    ## TYGRAM's pin
const BUBBLE := Color("#ff8aa8")
const MOTTO := ["Ćwiartka nie kłamie.", "The quarter mile doesn't lie."]

## The meets: [lat, lon] of the ring's middle (map/centrum.json's plazas: Plac Defilad east of the
## Palace; the paved square at the National Stadium's north foot, under its facade: F 2026-11-08
## found the old spot south of the stadium cut by two fences through the ring, so the second meet
## moved to the paving round the stadium with the most room from fences, roads, trees and the car
## park's parked cars, about 15 m; check_street_meet.gd keeps both rings clear of fences and walls).
const MEETS := [
	{"id": "defilad", "name": ["Plac Defilad", "Plac Defilad"], "ll": [52.232327, 21.008892]},
	{"id": "narodowy", "name": ["Parking pod Narodowym", "The car park by the National Stadium"], "ll": [52.241117, 21.043449]},
]
## The drag strip: Aleja Zieleniecka's straight, north end `a` to south end `b`; the line START_AT m
## from `a`, the finish QUARTER m on.
const STRIP := {"id": "zieleniecka", "name": ["Aleja Zieleniecka", "Aleja Zieleniecka"],
		"a": [52.24683, 21.04752], "b": [52.23900, 21.05132]}
const START_AT := 80.0
const QUARTER := 402.0
## The beacon where you stop to watch: this far before the line, on the kerb lane.
const WATCH_BACK := 30.0

## Night: 21:00 to 04:00.
const NIGHT_HOURS := Vector2(21.0, 4.0)
## Free-play seconds before the first call of a night and between calls.
const FIRST_CALL := Vector2(240.0, 480.0)
const NEXT_CALL := Vector2(1500.0, 2400.0)
const RING_LIFE := 25.0
## The ring of parked cars and the people at a meet.
const RING_CARS := 6
const RING_R := 13.0
const CROWD := 16
const CROWD_R := 9.5
## The donut: radius (m), turn rate (rad/s), the tail out (rad).
const DONUT_R := 5.6
const DONUT_W := 1.15
const DONUT_SLIP := 0.62
## The tandem at meet 2 (F 2026-11-08: "on the second car park they stand among barriers and don't
## drift"): Darek's Bawarka chases Lena round the same circle, TANDEM_LAG rad behind, TANDEM_OUT m
## wider.
const TANDEM_LAG := 0.8
const TANDEM_OUT := 0.9
const SMOKE := 22
const SMOKE_LIFE := 1.7
## Stopping in the ring's gap: within MEET_R m, under STOP_KMH, for HOLD s.
const MEET_R := 9.0
const STOP_KMH := 9.0
const HOLD := 0.8
## The club talks this long at a meet before the sirens (F 2026-11-08: the first meet's drift ran
## too long at 15 s).
const MEET_TALK := 9.0
## The raid: patrol cars sent in, the chase's koguty, and how long the quest waits for a chase that
## never started (then the pin comes anyway).
const RAID_CARS := 3
const RAID_LEVEL := 2
const RAID_WAIT := 6.0
## The cordon (F 2026-11-08: "you don't see the cops coming in from every side and boxing you in,
## only icons"): CORDON patrol cars drive in across the plaza from CORDON_FROM m out, CORDON_STAGGER
## s apart, each over CORDON_T s, and stop CORDON_R m round the player, noses in, lights on (police.gd
## `scene_car`: parked, solid, never a chaser), with the gaps between them the way out. They leave
## out of sight once the player is CORDON_GONE m away.
const CORDON := 4
const CORDON_R := 9.5
const CORDON_FROM := 34.0
const CORDON_T := 2.4
const CORDON_STAGGER := 0.5
const CORDON_GONE := 90.0
## The pin comes only once the player is this far from the raided meet (a meet off the road is
## no hiding place: sitting still there is not an escape).
const PIN_AWAY := 220.0
## The scatter: each car glides off the plaza to the road at GLIDE_V m/s, STAGGER s apart.
const GLIDE_V := 9.0
const STAGGER := 0.35
## The race to meet 2: arriving within ARRIVE_R m counts (any speed); the racers' racer stats.
const ARRIVE_R := 22.0
## F 2026-11-08 ("they drive dumb and slow"; "the other racers too"): at least the player's own top
## speed (as the ladder's rivals now), a sports car's pull, corners near the ladder's best rivals,
## and every shortcut in the city (race_cuts.gd: they are locals).
const RACE_SHARE := Vector2(1.0, 1.06)
const RACE_ACCEL := Vector2(6.0, 8.0)
const RACE_LAT := 7.6
## [złoty, respect] by place (1st, 2nd, 3rd, the rest).
const PLACE_PAY := [[200, 40], [120, 25], [60, 12], [0, 5]]
## The drag win and the loss.
const DRAG_PAY := [300, 80]
const DRAG_LOSE := [0, 10]
## The drag car: top speed × DRAG_TOP (Darek's map on the ECU), four gears as shares of it.
const DRAG_TOP := 1.5
const GEARS := [0.34, 0.57, 0.79, 1.0]
## The BIEG! button: shown from SHIFT_SHOW of the gear's top, "TERAZ" from SHIFT_AT; pressed within
## PERFECT s of that, a perfect shift (accel × SHIFT_BOOST for BOOST_S s); before SHIFT_AT, early
## (accel × EARLY_BOG for BOG_S s); nothing for AUTO_SHIFT s, the box shifts itself.
const SHIFT_SHOW := 0.82
const SHIFT_AT := 0.96
const PERFECT := 0.35
const SHIFT_BOOST := 1.7
const BOOST_S := 1.1
const EARLY_BOG := 0.6
const BOG_S := 0.6
## F 2026-11-08 ("a gearbox you shift yourself, with a rev counter and its zones"): the box never
## shifts for you on time; only after AUTO_SHIFT s bouncing on the limiter it saves a sleeping run
## (a late, slow shift). The tacho (DragTacho) shows the zones: yellow from SHIFT_SHOW, green from
## SHIFT_AT, red the limiter.
const AUTO_SHIFT := 2.5
## The genre's grades (CSR-style drag games, F 2026-11-08 "look how arcade games do the shifting"):
## a press in the yellow (from SHIFT_SHOW) or up to GOOD_LATE s past the green is "good" (no burst,
## no bog); before the yellow "early" (a bog); later than GOOD_LATE on the limiter "late".
const GOOD_LATE := 0.8
## The launch (the same games): on the line the car is held and the gas only revs the engine; the
## needle climbs REV_UP a second with the gas, falls REV_DOWN without. At green the needle in the
## launch zone LAUNCH (shares of the dial's 0-1 rev range) is a perfect start (a burst); over
## it the tyres spin (accel × SPIN for SPIN_S s); under it a bog.
const REV_UP := 0.9
const REV_DOWN := 1.4
const LAUNCH := Vector2(0.55, 0.78)
const SPIN := 0.55
const SPIN_S := 0.9
## The tree: the pre-stage, the three ambers TREE_STEP apart, then green after up to TREE_JITTER s
## more; moving FALSE_M m before green is a false start.
## F 2026-11-08 ("no 3, 2, 1 before the drag"): each amber is a big 3, 2, 1 on screen, a second's
## beat apart, and green is START! on the beat (an arcade count, no random hold).
const TREE_PRE := 1.0
const TREE_STEP := 0.8
const TREE_JITTER := 0.0
const FALSE_M := 1.2
## The start gate over the line (F 2026-11-08: "the START DRAG icon at the top is hard to see"):
## seen from the watch spot and from the road in; stopping in its lane on the line (within
## LINE_R m) stages the run. GATE_H m tall.
const GATE_H := 7.0
const LINE_R := 6.0
## Off the strip sideways by this much: out of the race.
const STRIP_HALF := 9.0
## Tadek: his reaction, and how far between the "ok" run and a perfect one his time sits.
const RIVAL_REACT := 0.28
const RIVAL_SKILL := 0.5
## The clean run Tadek is measured against: a human reaction and shifts on time (not a robot's).
const CLEAN_REACT := 0.35
const CLEAN_DELAY := 0.15
## A nitro bottle on loan (with no garage nitro): one full tank.
const LOAN := true
const RESULT_LIFE := 30.0
const TICK := 0.25

## What people say, [Polish, English] (each under 90 characters).
const MEET_LINES := [
	[FRIEND, "Jesteś! Stań tu, przy mnie. Tylko nie na krawężniku, Lena go za chwilę potrzebuje.", "You made it! Park here by me. Not on the kerb, Lena needs it in a second."],
	[DRIFTER, "Kółko numer czterdzieści. Opony mówią, że mają dość. Ja nie.", "Lap forty. The tyres say they've had enough. I haven't."],
	["Widz", "Ten dym to jej perfumy. Serio, tak mówi.", "That smoke is her perfume. Seriously, that's what she says."],
	[BOSS, "Nowy? Zobaczymy na Zielenieckiej. Ćwiartka nie kłamie.", "New guy? We'll see on Zieleniecka. The quarter mile doesn't lie."],
]
const MEET2_LINES := [
	[FRIEND, "Ty to masz nogę. Psy jeszcze szukają nas na Marszałkowskiej.", "What a right foot. The cops are still looking for us on Marszałkowska."],
	[DRIFTER, "Darek, trzymaj się mojego zderzaka! Tandem, nie wycieczka!", "Darek, stay on my bumper! It's a tandem, not a sightseeing tour!"],
	[BOSS, "Dobra, nowy. Po tym wszystkim: ty i ja. Drag.", "Fine, new guy. After all this: you and me. A drag."],
	["Widz", "Tu jest ciszej. Tylko stadion patrzy.", "It's quieter here. Only the stadium's watching."],
]
const RAID_LINES := [
	["Widz", "PSY! Zwijamy się!", "COPS! We're out!"],
	[FRIEND, "Rozjazd! Pin wrzucę na TYGRAMA!", "Split up! I'll drop a pin on TYGRAM!"],
	[DRIFTER, "Znowu? Przecież nikt jeszcze nie przegrał!", "Again? Nobody's even lost yet!"],
]
const RACE_LINES := [
	[FRIEND, "Kto pierwszy na miejscu, ten stawia. Znaczy: nie stawia.", "First one there buys. I mean: doesn't buy."],
	[DRIFTER, "Bokiem przez rondo, prosto przez most!", "Sideways through the roundabout, straight over the bridge!"],
]
const DRAG_LINES := {
	"watch": [FRIEND, "Patrz na start. Zielone i noga w podłogę. Biegi na czas!", "Watch the line. Green, then floor it. Shift on time!"],
	"boss": [BOSS, "Ćwiartka nie kłamie. Ty też nie kłam, że się nie boisz.", "The quarter mile doesn't lie. Don't lie that you're not scared."],
	"win": [BOSS, "Dobra. Respekt. Następnym razem przywiozę dwa turbo.", "Fine. Respect. Next time I'm bringing two turbos."],
	"lose": [BOSS, "Wróć, jak nauczysz się zmieniać biegi.", "Come back when you've learned to shift."],
	"false": [BOSS, "Za szybko! Światło jest zielone, nie żółte.", "Too soon! The light's green, not yellow."],
}
## The cars at a meet: paints of the six parked cars (traffic's pool shapes).
const RING_PAINTS := [Color("#ff4fd8"), Color("#3ad8ff"), Color("#7cff3a"), Color("#ffb03a"), Color("#f2f2f2"), Color("#7b2fbf")]
const GLOWS := [Color("#ff4fd8"), Color("#38f6ff"), Color("#7cff3a"), Color("#ffb03a"), Color("#b44cff"), Color("#38f6ff"),
		Color("#38f6ff"), Color("#ff3d6e")]

enum State { IDLE, RING, OFFER, TO_MEET, MEET, RAID, RACE, MEET2, RAID2, TO_DRAG, WATCH, STAGE, RUN, RESULT }
const STATES := ["idle", "ring", "offer", "to_meet", "meet", "raid", "race", "meet2", "raid2", "to_drag", "watch",
		"stage", "run", "result"]

var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var missions: Node
var map: Node3D
var graph: LaneGraph
var traffic: Node3D
var police: Node
var car: CharacterBody3D
var flat_mat: Material
## [position, km/h, flying] of the player's vehicle.
var vehicle: Callable
## {hour, weekday} (time_of_day.gd local_clock).
var clock: Callable
## True when nothing else is on (main.gd).
var free_now: Callable
## Puts the car at (position, yaw) at once (main.gd `_place_car`: the camera cut too).
var place_car: Callable
var log_on := false
var auto := true
## --meet=on: night rules at any hour.
var force := false
var origin := [52.234, 21.024]

var state := State.IDLE
var call_in := 0.0
## The meets found: MEETS' keys plus at: Vector3 (the middle), door: kerb (Rave.kerb_near), gap:
## Vector3 (the player's place in the ring, towards the door), slots: Array[Vector3] (the ring).
var meets: Array[Dictionary] = []
## The strip: {a: Vector2, dir: Vector2, side: Vector2 (right of dir), start: Vector2 (the line,
## the player's lane), lane_gap: float (the rival's lane to the left), watch: Vector3, ok: bool}.
var strip := {}
var meet_i := 0
var place := 0
var last_pay := []
var drag_time := 0.0
var drag_won := false
var nights := 0

var _rng := RandomNumberGenerator.new()
var _tick := 0.0
var _t := 0.0
var _hold_t := 0.0
var _talk_i := 0
var _talk_t := 0.0
var _calls_were := false
var _chase_seen := false

## The racers: {d: traffic Driver, node: Node3D or null, name, glide: {} (from, to, yaw, t, then)}.
var _racers: Array[Dictionary] = []
var _race_dist := PackedFloat32Array()
var _race_node := -1
var _there: Array[int] = []

## The scene's own nodes.
var _scene: Node3D
var _marks: MeshInstance3D
var _smoke: MultiMeshInstance3D
var _glow: MultiMeshInstance3D
var _crowd: MultiMeshInstance3D
var _bawarka: Node3D
var _porsze: Node3D
var _skajlajner: Node3D
var _show_cars: Array[Node3D] = []
var _beacon: Node3D
var _crowd_at: Array[Vector3] = []
var _crowd_run := 0.0
var _smoke_t: Array[float] = []
var _smoke_at: Array[Vector3] = []
var _smoke_next := 0
var _drift_a := 0.0
var _drifting := false
## Meet 2's tandem: Darek's Bawarka on Lena's bumper.
var _tandem := false
## The raid's cordon: {d: police Driver, from, to: Vector3, yaw, t, dur, e, s}; leaving once the
## player is away (out of sight, one a tick).
var _cordon: Array[Dictionary] = []
var _cordon_leaving := false
## Red and blue light pools on the ground under the cordon's cars (one draw call, raids only), so
## the box-in reads at night and from the far camera.
var _flash: MultiMeshInstance3D
var _flash_t := 0.0
## The race's distances with the club's shortcuts (race_cuts.gd), and the cuts' table.
var _cuts: RaceCuts
var _cut_table := {}
var _race_cut_dist := PackedFloat32Array()

## The drag: the exhibition pairs ({cars: [Node3D, Node3D], t, profile, lanes}), the run.
var _shows: Array[Dictionary] = []
var _rival_profile := PackedFloat32Array()
var _rival_k := 1.0
## His run\'s time from the line (s): shown on the card when you beat him before he crossed.
var _rival_time := 0.0
var _tree: DragTree
var _tacho: DragTacho
var _gate: MeshInstance3D
var _tree_t := 0.0
var _green_at := 0.0
var _run_t := 0.0
var _react := -1.0
var _gear := 0
var _shift_w := -1.0
var _boost_t := 0.0
var _bog_t := 0.0
## The launch: the revs on the line (0-1 of the gear's range) and the gas held now.
var _revs := 0.0
var _spin_t := 0.0
var _rev_gas := false
var _top_was := 1.0
var _accel_was := 1.0
var _nitro_was := false
var _nitro_charge_was := 1.0
var _gentle_was := false
var _rival_s := 0.0
var _player_s := 0.0
var _rival_done := -1.0
var _clear_t := 0.0
var spent_usec := 0


func setup(world: Node3D, seed_value := -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	call_in = _rng.randf_range(FIRST_CALL.x, FIRST_CALL.y)
	if graph != null:
		meets = find_meets(graph, map, origin)
		strip = find_strip(graph, map, origin)
	_scene = Node3D.new()
	_scene.name = "NightMeet"
	_scene.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_scene.visible = false
	world.add_child(_scene)
	_build_scene()
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(COLOUR, Color("#1a1a1e"))
	_beacon.waving = false
	_beacon.visible = false
	if hud != null:
		hud.card_pressed.connect(_on_card)
		hud.context_pressed.connect(_on_context)
		hud.abort_pressed.connect(func() -> void:
			if state in [State.TO_MEET, State.RACE, State.TO_DRAG, State.WATCH]:
				_give_up())
	if police != null and police.has_signal("chase_ended"):
		police.chase_ended.connect(_on_chase_ended)
	var names := PackedStringArray()
	for m in meets:
		names.append("%s %d,%d" % [m["id"], roundi(m["at"].x), roundi(m["at"].z)])
	_log("%d meets (%s), strip %s; Darek in %.0f s" % [meets.size(), ", ".join(names),
			"%d,%d" % [roundi(strip["start"].x), roundi(strip["start"].y)] if bool(strip.get("ok", false)) else "none", call_in])


# --- the rules (static: check_street_meet.gd runs them) --------------------------------------

## Within hours [from, to) that may wrap past midnight.
static func night_on(hour: float) -> bool:
	return Rave.in_hours(hour, NIGHT_HOURS)


## [złoty, respect] for finishing the race to meet 2 in place `p` (1 the first).
static func place_pay(p: int) -> Array:
	return PLACE_PAY[clampi(p - 1, 0, PLACE_PAY.size() - 1)]


## The shift's grade: pressed `w` s after the gear's top came (negative: before it): "early",
## "perfect" or "late".
static func shift_grade(w: float) -> String:
	if w < 0.0:
		return "early"
	return "perfect" if w <= PERFECT else "late"


## A press's grade with the needle at `k` of the gear's cap and `w` s since the green (negative:
## not there yet): "perfect", "good", "early" or "late".
static func shift_grade_at(k: float, w: float) -> String:
	if w >= 0.0:
		return shift_grade(w) if w <= PERFECT else ("good" if w <= GOOD_LATE else "late")
	return "good" if k >= SHIFT_SHOW else "early"


## The launch's grade from the revs at green: "perfect", "spin" or "bog".
static func launch_grade(revs: float) -> String:
	if revs > LAUNCH.y:
		return "spin"
	return "perfect" if revs >= LAUNCH.x else "bog"


## One 402 m run of a car with `accel` (m/s²) and `top` (m/s, the drag top), the car.gd equation,
## at 120 Hz: `react` s at the line, then each gear's cap until a shift `delay` s after reaching
## it (a perfect shift with `boost`), `nitro` s of the nitro from `nitro_at` s. Returns
## [time (s), the distance at each 1/30 s as a PackedFloat32Array].
static func sim_run(accel: float, top: float, react: float, delay: float, boost: bool, nitro := 0.0,
		nitro_at := 2.0, nitro_top := 1.3, nitro_accel := 2.2) -> Array:
	var dt := 1.0 / 120.0
	var t := 0.0
	var s := 0.0
	var v := 0.0
	var gear := 0
	var at_cap := -1.0
	var boost_t := 0.0
	var samples := PackedFloat32Array([0.0])
	var next_sample := 1.0 / 30.0
	while s < QUARTER and t < 60.0:
		t += dt
		if t > react:
			var n := nitro > 0.0 and t - react >= nitro_at and t - react < nitro_at + nitro
			var cap: float = top * float(GEARS[gear]) * (nitro_top if n else 1.0)
			var a := accel * (nitro_accel if n else 1.0) * (SHIFT_BOOST if boost_t > 0.0 else 1.0)
			if v < cap:
				v = minf(cap, v + a * dt * (1.0 - 0.6 * clampf(v / cap, 0.0, 1.0)))
			else:
				v = move_toward(v, cap, 4.0 * dt)
			boost_t = maxf(0.0, boost_t - dt)
			if gear < GEARS.size() - 1 and v >= cap * SHIFT_AT:
				if at_cap < 0.0:
					at_cap = t
				if t - at_cap >= minf(delay, AUTO_SHIFT):
					gear += 1
					at_cap = -1.0
					if boost and delay <= PERFECT:
						boost_t = BOOST_S
		s += v * dt
		if t >= next_sample:
			samples.append(s)
			next_sample += 1.0 / 30.0
	return [t, samples]


## Tadek's run against a car of `accel`/`top`: the "ok" run's profile and the factor that speeds it
## up to RIVAL_SKILL of the way to a clean run's time: [profile, k, his time, ok, perfect].
static func rival_run(accel: float, top: float) -> Array:
	var ok: Array = sim_run(accel, top, RIVAL_REACT, 0.6, false)
	var best: Array = sim_run(accel, top, CLEAN_REACT, CLEAN_DELAY, true)
	var target := lerpf(float(ok[0]), float(best[0]), RIVAL_SKILL)
	return [ok[1], float(ok[0]) / target, target, float(ok[0]), float(best[0])]


## Distance along a 30 Hz profile at time `t` (past its end: the last speed carried on).
static func profile_at(profile: PackedFloat32Array, t: float) -> float:
	var f := t * 30.0
	var i := int(f)
	if i >= profile.size() - 1:
		var n := profile.size()
		var v := (profile[n - 1] - profile[n - 2]) * 30.0 if n >= 2 else 0.0
		return profile[n - 1] + v * (t - (n - 1) / 30.0)
	return lerpf(profile[i], profile[i + 1], f - i)


## The meets on this map: MEETS projected, each with its door (a ground road within 160 m), the
## player's gap in the ring (towards the door) and RING_CARS slots round the rest of it.
static func find_meets(g: LaneGraph, m: Node3D, org: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Dictionary in MEETS:
		var ll: Array = row["ll"]
		var at := Notebook.project(org, float(ll[0]), float(ll[1]))
		var door := Rave.kerb_near(g, at, 160.0)
		if door.is_empty():
			continue
		var y: float = m.terrain_height(at.x, at.y) if m != null and m.has_method("terrain_height") else 0.0
		var d3: Vector3 = door["at"]
		var to_door := (Vector2(d3.x, d3.z) - at).normalized()
		var meet := row.duplicate(true)
		meet["at"] = Vector3(at.x, y, at.y)
		meet["door"] = door
		var gp := at + to_door * RING_R
		meet["gap"] = Vector3(gp.x, y, gp.y)
		var slots: Array[Vector3] = []
		var a0 := atan2(to_door.y, to_door.x)
		for k in RING_CARS + 2:
			var a := a0 + TAU * float(k + 1) / float(RING_CARS + 3)
			var p := at + Vector2(cos(a), sin(a)) * RING_R
			slots.append(Vector3(p.x, y, p.y))
		meet["slots"] = slots
		out.append(meet)
	return out


## The drag strip on this map: the line START_AT m from the north end on the southbound lane
## nearest the kerb; {} without a road there.
static func find_strip(g: LaneGraph, m: Node3D, org: Array) -> Dictionary:
	var a := Notebook.project(org, float(STRIP["a"][0]), float(STRIP["a"][1]))
	var b := Notebook.project(org, float(STRIP["b"][0]), float(STRIP["b"][1]))
	var dir := (b - a).normalized()
	var at := a + dir * START_AT
	var hit: Array = g.snap(at, 25.0, dir, false, true)
	if hit.is_empty() or graph_dir_ok(g, hit, dir) == false:
		return {"ok": false, "start": at}
	var e: int = hit[0]
	var s: float = hit[2]
	var lanes: int = g.e_lanes[e]
	var kerb := g.lane_offset(e, lanes - 1)
	var inner := g.lane_offset(e, lanes - 2) if lanes >= 2 else kerb - 3.4
	var start := g.point_at(e, s, kerb)
	var right := Vector2(-dir.y, dir.x)
	if (g.point_at(e, s, kerb + 1.0) - start).dot(right) < 0.0:
		right = -right
	var gap := absf(kerb - inner)
	var w := start - dir * WATCH_BACK
	var y: float = m.terrain_height(w.x, w.y) if m != null and m.has_method("terrain_height") else 0.0
	return {"ok": (b - a).length() >= START_AT + QUARTER + 60.0, "a": a, "dir": dir, "right": right, "start": start,
			"lane_gap": gap, "watch": Vector3(w.x, y, w.y), "e": e, "length": (b - a).length()}


static func graph_dir_ok(g: LaneGraph, hit: Array, dir: Vector2) -> bool:
	return g.direction(int(hit[0]), float(hit[2])).dot(dir) > 0.9


## A point on the strip: `s` m past the line, `lat` m to the right of the player's lane.
func strip_at(s: float, lat := 0.0) -> Vector3:
	var p: Vector2 = strip["start"] + strip["dir"] * s + strip["right"] * lat
	return Vector3(p.x, _ground(p.x, p.y), p.y)


func strip_yaw() -> float:
	var d: Vector2 = strip["dir"]
	return atan2(-d.x, -d.y)


## The start gate over both lanes at the line (built the first time).
func _show_gate(on: bool) -> void:
	if _gate == null or not bool(strip.get("ok", false)):
		return
	if on and _gate.mesh == null:
		_gate.mesh = gate_mesh(float(strip["lane_gap"]) + 9.0)
	if on:
		_gate.global_transform = Transform3D(Basis(Vector3.UP, strip_yaw()), strip_at(0.0, -float(strip["lane_gap"]) * 0.5))
	_gate.visible = on


# --- the meshes -------------------------------------------------------------------------------

## The quest's own cars: "bawarka" Darek's dark saloon (a two-part grille, M-ish stripes), "porsze"
## Lena's silver coupe (round lamps, a duck tail), "skajlajner" Tadek's black coupe (tinted glass,
## a tall wing, violet stripes), "show_a"/"show_b" the exhibition pair's (lime hatch, orange saloon).
static func car_mesh(kind: String) -> ArrayMesh:
	var s := Models.Shape.new()
	match kind:
		"bawarka":
			var p := Models.spec("saloon")
			Models._vehicle(s, p, Models.fin(Color("#1d2a44")), [], Models.fin(Color("#151a24")))
			var hl: float = -float(p["L"]) * 0.5
			for x: float in [-0.17, 0.17]:
				s.box(Vector3(x, 0.66, hl + 0.02), Vector3(0.24, 0.16, 0.05), Models.fin(Color("#c9ced6")))
			var stripes := [Color("#2e7fd6"), Color("#1d2a6b"), Color("#e2342c")]
			for k in 3:
				s.box(Vector3(-0.12 + 0.12 * k, float(p["roof_y"]) + 0.012, 0.2), Vector3(0.1, 0.02, 1.0), Models.fin(stripes[k]))
		"porsze":
			var p := Models.spec("coupe")
			p.merge({"roof_z1": 1.2, "tail_y": 0.86}, true)
			Models._vehicle(s, p, Models.fin(Color("#c8ccd2")))
			var tail: float = float(p["L"]) * 0.5
			s.box(Vector3(0.0, 0.98, tail - 0.25), Vector3(1.5, 0.06, 0.3), Models.fin(Color("#a9aeb6")))
			for x: float in [-0.62, 0.62]:
				s.box(Vector3(x, 0.78, -tail + 0.35), Vector3(0.22, 0.2, 0.22), Models.fin(Color("#fff6d8"), Models.LIT_SIGN))
		"skajlajner":
			var p := Models.spec("coupe")
			p.merge({"L": 4.6, "roof_y": 1.28}, true)
			Models._vehicle(s, p, Models.fin(Color("#111114")), [], Models.fin(Color("#07070a")))
			var tail: float = float(p["L"]) * 0.5 - 0.3
			for x: float in [-0.72, 0.72]:
				s.box(Vector3(x, 1.08, tail), Vector3(0.08, 0.34, 0.1), Models.fin(Color("#1c1c1e")))
			s.box(Vector3(0.0, 1.27, tail + 0.04), Vector3(2.0, 0.06, 0.48), Models.fin(Color("#1c1c1e")))
			var w: float = p["W"]
			for sg: float in [-1.0, 1.0]:
				s.side_rect(sg * (w + 0.012), sg, 0.55, 0.7, -1.6, 1.6, Models.fin(Color("#9b4cff")))
		"show_a":
			var p := Models.spec("hatch")
			Models._vehicle(s, p, Models.fin(Color("#9cff3a")))
			s.box(Vector3(0.0, float(p["roof_y"]) + 0.02, float(p["roof_z1"]) + 0.1), Vector3(1.6, 0.06, 0.34), Models.fin(Color("#1c1c1e")))
		_:
			var p := Models.spec("saloon")
			Models._vehicle(s, p, Models.fin(Color("#ff8a1e")))
			var tail: float = float(p["L"]) * 0.5 - 0.3
			s.box(Vector3(0.0, 1.2, tail), Vector3(1.9, 0.05, 0.4), Models.fin(Color("#1c1c1e")))
	return s.mesh()


## The drag's start gate (F 2026-11-08), `width` m across the two lanes, the line at z 0, the cars
## coming from +z: a chequered line on the road, two posts, a lit club-red banner with a chequered
## band each side, and a small tree of lights between the lanes. One surface.
static func gate_mesh(width: float) -> ArrayMesh:
	var s := Models.Shape.new()
	var white := Models.fin(Color("#f2f2f2"))
	var black := Models.fin(Color("#151517"))
	var n := maxi(4, int(width / 0.5))
	var sq := width / float(n)
	for i in n:
		for row in 2:
			var col := white if (i + row) % 2 == 0 else black
			s.box(Vector3(-width * 0.5 + sq * (i + 0.5), 0.03, (row - 0.5) * sq), Vector3(sq, 0.03, sq), col)
	var post := Models.fin(Color("#2a2a30"))
	for sg: float in [-1.0, 1.0]:
		s.box(Vector3(sg * (width * 0.5 + 0.45), GATE_H * 0.5, 0.0), Vector3(0.4, GATE_H, 0.4), post)
	s.box(Vector3(0.0, GATE_H - 0.8, 0.0), Vector3(width + 1.4, 1.6, 0.34), Models.fin(COLOUR, Models.LIT_SIGN))
	var m := maxi(6, int((width + 1.2) / 0.7))
	var bs := (width + 1.2) / float(m)
	for i in m:
		for row in 2:
			var col := white if (i + row) % 2 == 0 else black
			for face: float in [-1.0, 1.0]:
				s.box(Vector3(-(width + 1.2) * 0.5 + bs * (i + 0.5), GATE_H - 0.35 - row * bs * 0.9, face * 0.18),
						Vector3(bs, bs * 0.9, 0.02), col)
	s.box(Vector3(0.0, 0.8, 0.6), Vector3(0.22, 1.6, 0.22), post)
	for k in 3:
		s.box(Vector3(0.0, 1.75 + k * 0.3, 0.6), Vector3(0.34, 0.22, 0.3), Models.fin(Color("#ffb21e"), Models.LIT_SIGN))
	s.box(Vector3(0.0, 2.65, 0.6), Vector3(0.34, 0.22, 0.3), Models.fin(Color("#3cff6a"), Models.LIT_SIGN))
	return s.mesh()


## The donut marks: two rings of tyre marks (the rear wheels' tracks) and a few loose loops, flat
## on the ground (the skids' colour and depth bias: one surface).
static func marks_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var loops := [[DONUT_R - 0.8, Vector2.ZERO], [DONUT_R + 0.8, Vector2.ZERO], [DONUT_R - 0.5, Vector2(0.7, -0.4)],
			[DONUT_R + 0.4, Vector2(-0.6, 0.5)], [DONUT_R + 1.1, Vector2(0.3, 0.8)]]
	var n := 40
	for l: Array in loops:
		var r: float = l[0]
		var c: Vector2 = l[1]
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var q := [Vector3(c.x + cos(a0) * (r - 0.13), 0, c.y + sin(a0) * (r - 0.13)), Vector3(c.x + cos(a1) * (r - 0.13), 0, c.y + sin(a1) * (r - 0.13)),
					Vector3(c.x + cos(a1) * (r + 0.13), 0, c.y + sin(a1) * (r + 0.13)), Vector3(c.x + cos(a0) * (r + 0.13), 0, c.y + sin(a0) * (r + 0.13))]
			for k in [0, 2, 1, 0, 3, 2]:
				st.set_color(Color("#2f3135"))
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(0.45, 7.0))
				st.add_vertex(q[k])
	return st.commit()


func _car_node(kind: String, size_z: float) -> Node3D:
	var node := Node3D.new()
	node.name = kind
	var mi := MeshInstance3D.new()
	mi.mesh = car_mesh(kind)
	mi.material_override = Models.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)
	var beams := MeshInstance3D.new()
	beams.mesh = Models.headlight_pools(size_z * 0.5)
	beams.material_override = Models.glow_material()
	beams.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(beams)
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	node.visible = false
	return node


func _build_scene() -> void:
	_marks = MeshInstance3D.new()
	_marks.name = "Marks"
	_marks.mesh = marks_mesh()
	if flat_mat != null:
		_marks.material_override = flat_mat
	_marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marks.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_scene.add_child(_marks)
	# Smoke: grey puffs, alpha per instance.
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.vertex_color_use_as_albedo = true
	smat.albedo_color = Color(0.85, 0.85, 0.88, 1.0)
	var puff := SphereMesh.new()
	puff.radius = 0.9
	puff.height = 1.4
	puff.radial_segments = 8
	puff.rings = 4
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = puff
	mm.instance_count = SMOKE
	_smoke = MultiMeshInstance3D.new()
	_smoke.name = "Smoke"
	_smoke.multimesh = mm
	_smoke.material_override = smat
	_smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_smoke.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_scene.add_child(_smoke)
	_smoke_t.resize(SMOKE)
	_smoke_t.fill(99.0)
	_smoke_at.resize(SMOKE)
	for i in SMOKE:
		mm.set_instance_color(i, Color(1, 1, 1, 0))
	# Neon under the cars: one glow slab per car (ring cars, Darek, Lena).
	var slab := BoxMesh.new()
	slab.size = Vector3(2.4, 0.04, 4.8)
	var gm := MultiMesh.new()
	gm.transform_format = MultiMesh.TRANSFORM_3D
	gm.use_colors = true
	gm.mesh = slab
	gm.instance_count = GLOWS.size()
	_glow = MultiMeshInstance3D.new()
	_glow.name = "Underglow"
	_glow.multimesh = gm
	_glow.material_override = Models.glow_material()
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glow.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_scene.add_child(_glow)
	# The crowd.
	var cmat := Models.material().duplicate() as ShaderMaterial
	cmat.set_shader_parameter("walk", 0.0)
	var cm := MultiMesh.new()
	cm.transform_format = MultiMesh.TRANSFORM_3D
	cm.use_custom_data = true
	InstanceBuffers.prepare(cm)
	cm.mesh = Models.person_mesh()
	cm.instance_count = CROWD
	InstanceBuffers.whiten(cm)
	var crng := RandomNumberGenerator.new()
	crng.seed = 4021
	var clothes := [Color("#1a1a1e"), Color("#2b2b33"), Color("#3a3a46"), Color("#ff3d6e"), Color("#38f6ff"), Color("#f2f2f2"), Color("#141416")]
	for i in CROWD:
		var c: Color = clothes[crng.randi() % clothes.size()]
		cm.set_instance_custom_data(i, Color(c.r, c.g, c.b, float(crng.randi() % 4) / 4.0))
	_crowd = MultiMeshInstance3D.new()
	_crowd.name = "Crowd"
	_crowd.multimesh = cm
	_crowd.material_override = cmat
	_crowd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_crowd.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_scene.add_child(_crowd)
	var world := _scene.get_parent()
	_bawarka = _car_node("bawarka", 4.6)
	_porsze = _car_node("porsze", 4.4)
	_skajlajner = _car_node("skajlajner", 4.6)
	for k: String in ["show_a", "show_b", "show_a", "show_b"]:
		var n := _car_node(k, 4.4)
		_show_cars.append(n)
	for n: Node3D in [_bawarka, _porsze, _skajlajner] + _show_cars:
		world.add_child(n)
	_tree = DragTree.new()
	_tree.name = "DragTree"
	_tree.visible = false
	_tacho = DragTacho.new()
	_tacho.name = "DragTacho"
	_tacho.visible = false
	_tacho.shift.connect(func() -> void:
		if state == State.RUN:
			_shift_pressed())
	if hud != null:
		hud.add_child(_tree)
		hud.add_child(_tacho)
	var disc := CylinderMesh.new()
	disc.top_radius = 3.6
	disc.bottom_radius = 3.6
	disc.height = 0.03
	disc.radial_segments = 16
	disc.rings = 1
	var fm := MultiMesh.new()
	fm.transform_format = MultiMesh.TRANSFORM_3D
	fm.use_colors = true
	fm.mesh = disc
	fm.instance_count = CORDON
	_flash = MultiMeshInstance3D.new()
	_flash.name = "CordonFlash"
	_flash.multimesh = fm
	_flash.material_override = Models.glow_material()
	_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_flash.visible = false
	world.add_child(_flash)
	_gate = MeshInstance3D.new()
	_gate.name = "DragGate"
	_gate.material_override = Models.material()
	_gate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_gate.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_gate.visible = false
	world.add_child(_gate)


## The tree of lights over the screen's top middle: three ambers, a green, and red for FALSTART;
## beside it the count as a big number (3, 2, 1, START!) in the middle of the screen.
class DragTree extends Control:
	## How many ambers are lit (0-3), green, red.
	var ambers := 0
	var green := false
	var red := false
	## Seconds since green (START! shows for a moment).
	var since_green := 0.0
	## The launch's word shown in START!'s place (street_meet `_launch`), and its colour.
	var word := ""
	var word_colour := Color("#3cff6a")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		# The offsets too (F 2026-11-08: with the anchors alone the control stayed 0 × 0 under the
		# HUD's CanvasLayer and the tree drew as a sliver in the top-left corner).
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	## The big word now: "3", "2", "1", "START!", "FALSTART" or "".
	func count_text() -> String:
		if red:
			return "FALSTART"
		if green:
			return ("START!" if word == "" else word) if since_green < 1.3 else ""
		return ["", "3", "2", "1"][clampi(ambers, 0, 3)]

	func _draw() -> void:
		if size.y < 50.0:
			return
		var r := clampf(size.y * 0.03, 10.0, 40.0)
		var cx := size.x * 0.5
		var y0 := size.y * 0.12
		var x0 := cx - size.y * 0.32
		draw_rect(Rect2(x0 - r * 1.6, y0 - r * 1.6, r * 3.2, r * 11.6), Color(0.05, 0.05, 0.06, 0.82))
		for k in 3:
			var on := ambers > k
			draw_circle(Vector2(x0, y0 + k * r * 2.6), r, Color("#ffb21e") if on else Color("#3a2c12"))
		draw_circle(Vector2(x0, y0 + 3 * r * 2.6), r, Color("#3cff6a") if green else (Color("#ff2a2a") if red else Color("#123a1c")))
		var word := count_text()
		if word == "":
			return
		var font := get_theme_default_font()
		var fs := int(size.y * (0.2 if word.length() <= 1 else 0.11))
		var col := (word_colour if word != "" else Color("#3cff6a")) if green else (Color("#ff2a2a") if red else Color("#ffb21e"))
		var w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var at := Vector2(cx - w * 0.5, size.y * 0.42 + fs * 0.35)
		draw_string_outline(font, at, word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(4, fs / 9), Color(0.03, 0.03, 0.04, 0.9))
		draw_string(font, at, word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## The drag's manual gearbox (F 2026-11-08): a rev counter at the bottom middle, 0-9 thousand, its
## zones (yellow: get ready; green: shift now, a perfect shift; red: the limiter), the needle, the
## gear and the speed in the middle. A tap anywhere on it shifts up (a second finger, the gas held);
## the context button (keyboard, pad A) still does too.
class DragTacho extends Control:
	signal shift
	## The needle: the speed over the gear's cap (0-1), the gear (0-based), gears in all, km/h.
	var k := 0.0
	var gear := 0
	var gears := 4
	var kmh := 0.0
	## Show / green from the street_meet constants (shares of the gear's cap).
	var show_at := 0.82
	var green_at := 0.96
	var limiter := false
	## On the line: the launch zone (shares of the rev range) shown instead of the shift zones.
	var staging := false
	var launch := Vector2(0.55, 0.78)
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		# The offsets too (F 2026-11-08: with the anchors alone the control stayed 0 × 0 under the
		# HUD's CanvasLayer and the tree drew as a sliver in the top-left corner).
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func radius() -> float:
		return clampf(size.y * 0.15, 64.0, 200.0)

	func centre() -> Vector2:
		return Vector2(size.x * 0.5, size.y - radius() * 1.12)

	## The needle's share of the dial for a share `x` of the gear's cap (1000 rpm at rest, 8000 at
	## the cap, the dial to 9000).
	static func dial(x: float) -> float:
		return (1000.0 + 7000.0 * clampf(x, 0.0, 1.1)) / 9000.0

	func _process(dt: float) -> void:
		if visible:
			_t += dt
			queue_redraw()

	func _input(event: InputEvent) -> void:
		if not visible:
			return
		if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
			if (event as InputEventScreenTouch).position.distance_to(centre()) <= radius() * 1.2:
				get_viewport().set_input_as_handled()
				shift.emit()

	func _arc(c: Vector2, r: float, f0: float, f1: float, w: float, col: Color) -> void:
		var a0 := deg_to_rad(135.0) + deg_to_rad(270.0) * f0
		var a1 := deg_to_rad(135.0) + deg_to_rad(270.0) * f1
		draw_arc(c, r, a0, a1, maxi(4, int(48.0 * (f1 - f0))), col, w, true)

	func _draw() -> void:
		if size.y < 50.0:
			return
		var r := radius()
		var c := centre()
		var top := gear >= gears - 1
		var in_green := not top and not staging and k >= green_at
		var flash := limiter and fmod(_t, 0.2) < 0.1
		draw_circle(c, r * 1.08, Color(0.04, 0.04, 0.05, 0.86))
		var w := r * 0.13
		_arc(c, r * 0.9, 0.0, 1.0, w, Color(1, 1, 1, 0.14))
		if staging:
			var in_l := k >= launch.x and k <= launch.y
			_arc(c, r * 0.9, dial(launch.x), dial(launch.y), w * (1.35 if in_l else 1.0), Color("#38f6ff"))
		elif not top:
			_arc(c, r * 0.9, dial(show_at), dial(green_at), w, Color("#ffb21e"))
			_arc(c, r * 0.9, dial(green_at), dial(1.0), w * (1.35 if in_green else 1.0), Color("#3cff6a"))
		_arc(c, r * 0.9, dial(1.0), 1.0, w, Color("#ff2a2a"))
		var font := get_theme_default_font()
		for n in 10:
			var a := deg_to_rad(135.0) + deg_to_rad(270.0) * n / 9.0
			var dir := Vector2(cos(a), sin(a))
			draw_line(c + dir * r * 0.72, c + dir * r * 0.8, Color(1, 1, 1, 0.7), maxf(2.0, r * 0.02))
			var fs := int(r * 0.13)
			var tw := font.get_string_size(str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, c + dir * r * 0.6 + Vector2(-tw * 0.5, fs * 0.35), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.6))
		var f := dial(k)
		if k >= 0.995:
			f += 0.012 * sin(_t * 70.0) + 0.015  # bouncing on the limiter
		var a := deg_to_rad(135.0) + deg_to_rad(270.0) * f
		var nd := Vector2(cos(a), sin(a))
		draw_line(c - nd * r * 0.12, c + nd * r * 0.86, Color("#ff3d6e"), maxf(3.0, r * 0.045), true)
		draw_circle(c, r * 0.24, Color(0.1, 0.1, 0.12))
		var g := str(gear + 1)
		var gs := int(r * 0.42)
		var gw := font.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, gs).x
		draw_string(font, c + Vector2(-gw * 0.5, gs * 0.36), g, HORIZONTAL_ALIGNMENT_LEFT, -1, gs, Color("#3cff6a") if in_green else Color.WHITE)
		var sp := "%d km/h" % roundi(kmh)
		var ss := int(r * 0.13)
		var sw := font.get_string_size(sp, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x
		draw_string(font, c + Vector2(-sw * 0.5, r * 0.5), sp, HORIZONTAL_ALIGNMENT_LEFT, -1, ss, Color(1, 1, 1, 0.8))
		# PT-50: the shift word only from the yellow.
		if (top or k < show_at) and not staging:
			return
		var word := Lang.pick("BIEG ⬆ TERAZ!", "SHIFT ⬆ NOW!") if in_green or limiter else Lang.pick("BIEG ⬆", "SHIFT ⬆")
		if staging:
			word = Lang.pick("GAZ: OBROTY W NIEBIESKIM", "GAS: REVS IN THE BLUE")
		var ws := int(r * 0.2)
		var ww := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, ws).x
		var col := Color("#ff2a2a") if flash else (Color("#3cff6a") if in_green else Color(1, 1, 1, 0.75))
		draw_string_outline(font, c + Vector2(-ww * 0.5, -r * 1.16), word, HORIZONTAL_ALIGNMENT_LEFT, -1, ws, maxi(3, ws / 6), Color(0.03, 0.03, 0.04, 0.9))
		draw_string(font, c + Vector2(-ww * 0.5, -r * 1.16), word, HORIZONTAL_ALIGNMENT_LEFT, -1, ws, col)


# --- the frame ------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0:
		return
	var t0 := Time.get_ticks_usec()
	if _scene.visible:
		_scene_frame(dt)
	if not _racers.is_empty():
		_glides(dt)
		_racer_dots()
	if not _cordon.is_empty():
		_cordon_frame(dt)
	if not _shows.is_empty():
		_shows_frame(dt)
	if state == State.STAGE or state == State.RUN:
		_drag_frame(dt)
	_tick += dt
	if _tick >= TICK:
		step(_tick)
		_tick = 0.0
	spent_usec += Time.get_ticks_usec() - t0


## The slow part, every TICK s.
func step(dt: float) -> void:
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var at: Vector3 = v[0]
	var kmh: float = v[1]
	if not _cordon.is_empty():
		var c0: Vector3 = (_cordon[0]["to"] as Vector3)
		if _cordon_leaving or Vector2(at.x, at.z).distance_to(Vector2(c0.x, c0.z)) > CORDON_GONE or not (state == State.RAID or state == State.RAID2):
			_cordon_leaving = true
			_cordon_leave()
	match state:
		State.IDLE:
			if auto and _free() and (force or night_on(_hour())):
				call_in -= dt
				if call_in <= 0.0 and not ring():
					call_in = 20.0
		State.RING, State.OFFER:
			_t_ring(dt)
		State.TO_MEET:
			var m: Dictionary = meets[0]
			_status("%s · SPOT" % String(m["name"][0]).to_upper(), "Stań w luce między autami", "Park in the gap between the cars",
					at, m["gap"], COLOUR)
			if _arrived(dt, at, kmh, m["gap"], MEET_R):
				_start_meet(0)
		State.MEET, State.MEET2:
			_talk_t -= dt
			var lines: Array = MEET_LINES if state == State.MEET else MEET2_LINES
			if _talk_t <= 0.0 and _talk_i < lines.size():
				_line(lines[_talk_i])
				_talk_i += 1
				_talk_t = MEET_TALK / float(lines.size())
			elif _talk_t <= 0.0:
				_raid()
		State.RAID, State.RAID2:
			_t_raid(dt)
		State.RACE:
			_t_race(dt, at)
		State.TO_DRAG:
			_status("ZIELENIECKA · DRAG", "Zatrzymaj się przy starcie", "Stop by the start line", at, strip["watch"], COLOUR)
			if _arrived(dt, at, kmh, strip["watch"], MEET_R * 1.6):
				_watch()
		State.WATCH:
			if _shows.is_empty():
				if not hud.pill_shown("drag"):
					hud.show_pill("START DRAG", "START DRAG", "drag")
					_beacon.place(strip_at(0.0), LINE_R * 0.6, true, false)
					_beacon.visible = true
				_status("ZIELENIECKA · DRAG", "Stań na linii pod bramą", "Stop on the line under the gate", at, strip_at(0.0), COLOUR)
				if _arrived(dt, at, kmh, strip_at(0.0), LINE_R):
					hud.hide_pill()
					_stage()
		State.RUN:
			_clear_strip()
		State.RESULT:
			_t_result(dt)


func _hour() -> float:
	var c: Dictionary = clock.call() if clock.is_valid() else {"hour": 23.0}
	return float(c.get("hour", 23.0))


func _free() -> bool:
	return free_now.is_valid() and bool(free_now.call()) and meets.size() >= 2 and bool(strip.get("ok", false))


func busy() -> bool:
	return state != State.IDLE and state != State.RING and state != State.OFFER


func has_target() -> bool:
	return state in [State.TO_MEET, State.RACE, State.TO_DRAG] or (state == State.WATCH and _shows.is_empty())


func target_position() -> Vector3:
	match state:
		State.TO_MEET:
			return meets[0]["gap"]
		State.RACE:
			return meets[1]["at"]
		State.TO_DRAG:
			return strip["watch"]
		State.WATCH:
			return strip_at(0.0)
	return Vector3.ZERO


func target_colour() -> Color:
	return PIN_COLOUR if state == State.RACE else COLOUR


func _status(title: String, hint: String, hint_en: String, at: Vector3, to: Vector3, colour: Color, badge := "") -> void:
	var m := roundi(Vector2(at.x, at.z).distance_to(Vector2(to.x, to.z)))
	hud.show_status(title, "", "%d m" % m, hint, _hold_t / HOLD, colour, badge, {}, hint_en)


func _arrived(dt: float, at: Vector3, kmh: float, to: Vector3, r: float) -> bool:
	if Vector2(at.x, at.z).distance_to(Vector2(to.x, to.z)) <= r and kmh < STOP_KMH:
		_hold_t += dt
	else:
		_hold_t = 0.0
	if _hold_t >= HOLD:
		_hold_t = 0.0
		return true
	return false


func _ground(x: float, z: float) -> float:
	return map.terrain_height(x, z) if map != null and map.has_method("terrain_height") else 0.0


func _log(text: String) -> void:
	if log_on:
		print("meet: " + text)


func _line(l: Array, seconds := 4.5) -> void:
	if dialogue == null or dialogue.bubbles == null:
		return
	var who := String(l[0])
	var anchor: Variant = car
	match who:
		FRIEND:
			anchor = _bawarka if _bawarka.visible else car
		DRIFTER:
			anchor = _porsze if _porsze.visible else car
		BOSS:
			anchor = _skajlajner if _skajlajner.visible else car
		_:
			if _crowd.visible and not _crowd_at.is_empty():
				anchor = _crowd_at[_rng.randi() % _crowd_at.size()] + _scene.position
	dialogue.bubbles.say(anchor, who, String(l[1]), String(l[2]), seconds, BUBBLE)


# --- the call ---------------------------------------------------------------------------------

## The phone rings (--meet-call too). False with no meets or while busy.
func ring() -> bool:
	if meets.size() < 2 or not bool(strip.get("ok", false)) or state != State.IDLE:
		return false
	state = State.RING
	_hold_t = 0.0
	_t = 0.0
	hud.show_side_card("📞 DAREK „BAWARKA” DZWONI", "Kumpel od aut. Jeździ Bawarką 3.2 i mówi o niej „ona”.",
			PackedStringArray(["ODBIERZ|ANSWER", "ODRZUĆ|DECLINE"]), COLOUR, "Darek \"Bawarka\" is calling",
			"Your car mate. Drives a Bawarka 3.2 and calls it \"she\".")
	hud.ticker_out()
	Access.buzz(60, 0.6)
	_log("call ringing")
	return true


func _t_ring(dt: float) -> void:
	_t += dt
	if _t > RING_LIFE:
		hud.hide_card()
		hud.toast("Nieodebrane połączenie: %s" % FRIEND, "Missed call: %s" % FRIEND)
		_reset()


func _offer() -> void:
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("📞 DAREK", "„Siema! Dziś spot %s na Placu Defilad. Lena kręci bączki, Tadek przywiózł Skajlajnera. Wpadasz? Tylko cicho, bo psy też czytają internet.”" % CLUB,
			PackedStringArray(["JADĘ!|ON MY WAY", "NIE DZIŚ|NOT TONIGHT"]), COLOUR, FRIEND,
			"\"Hey! The %s meets tonight on Plac Defilad. Lena's doing donuts, Tadek brought the Skajlajner. You in? Keep it quiet, the cops read the internet too.\"" % CLUB)


func _on_card(i: int) -> void:
	match state:
		State.RING:
			if i == 0:
				_offer()
			else:
				hud.hide_card()
				hud.toast("Odrzucono. Darek pojedzie sam. Bokiem.", "Declined. Darek goes alone. Sideways.")
				_reset()
		State.OFFER:
			hud.hide_card()
			if i == 0:
				accept()
			else:
				hud.toast("„Dobra. Ale jak Lena zrobi sto kółek, to nie płacz, że nie widziałeś.”", "\"Fine. But when Lena does a hundred laps, don't cry you missed it.\"")
				_reset()
		State.RESULT:
			hud.hide_card()
			if i == 0 and not drag_won:
				_stage()
			else:
				_finish()


func _on_context(owner: String) -> void:
	if owner == "drag" and state == State.WATCH:
		hud.hide_pill()
		_stage()
	elif owner == "drag_shift" and state == State.RUN:
		_shift_pressed()


## Darek in person at the start spot (story_quests.gd's WCHODZĘ!): the same as JADĘ! on the call.
func meet_in_person() -> bool:
	if meets.size() < 2 or not bool(strip.get("ok", false)) or state != State.IDLE:
		return false
	accept()
	return true


## True when the night may start (not ringing, not running): story_quests.gd skips the greeting otherwise.
func idle() -> bool:
	return state == State.IDLE


## JADĘ!: the meet goes up on Plac Defilad, the beacon in the ring's gap.
func accept() -> void:
	_calls_were = missions.paused if missions != null else false
	if missions != null:
		missions.paused = true
	nights += 1
	_show_meet(0)
	var g: Vector3 = meets[0]["gap"]
	_beacon.place(g, MEET_R * 0.7, true, false)
	_beacon.visible = true
	state = State.TO_MEET
	_hold_t = 0.0
	hud.toast("Jedź na spot: %s" % meets[0]["name"][0], "Drive to the meet: %s" % meets[0]["name"][1])
	_log("accepted: to %s" % meets[0]["id"])


# --- the meets --------------------------------------------------------------------------------

## The scene at meet `i`: the marks and the drift in the middle (meet 0 only), the crowd, the ring
## of parked racers (traffic's pool cars, or the racers who got here), Darek's car.
func _show_meet(i: int) -> void:
	meet_i = i
	var m: Dictionary = meets[i]
	var c: Vector3 = m["at"]
	_scene.position = c
	_scene.visible = true
	_marks.visible = true
	_marks.position = Vector3(0, 0.02, 0)
	_smoke.visible = true
	_drifting = true
	_tandem = i == 1
	_porsze.visible = true
	if _tandem:
		_bawarka.visible = true
	_crowd_run = 0.0
	_crowd_at.clear()
	var cm := _crowd.multimesh
	var a0 := _rng.randf() * TAU
	for k in CROWD:
		var a := a0 + TAU * k / CROWD + _rng.randf_range(-0.12, 0.12)
		var r := CROWD_R + _rng.randf_range(-0.8, 0.8)
		var p := Vector3(cos(a) * r, 0.0, sin(a) * r)
		_crowd_at.append(p)
		cm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, atan2(p.x, p.z)), p))
	_crowd.visible = true
	var slots: Array = m["slots"]
	if i == 0:
		_racers.clear()
		var e: int = m["door"]["e"]
		var s: float = m["door"]["s"]
		for k in RING_CARS:
			var at: Vector3 = slots[k]
			var yaw := atan2(at.x - c.x, at.z - c.z)  # nose to the middle
			var d = traffic.add_parked_car(e, s, at, yaw, 0, _rng.randi() % 4, RING_PAINTS[k])
			if d == null:
				continue
			traffic.park(d, e, s, at, yaw, -1)
			_racers.append({"d": d, "node": null, "name": "racer %d" % k, "glide": {}, "glow": k})
		_put_node(_bawarka, slots[RING_CARS], atan2(slots[RING_CARS].x - c.x, slots[RING_CARS].z - c.z))
		_racers.append({"d": null, "node": _bawarka, "name": FRIEND, "glide": {}, "glow": 6, "size": Vector3(1.8, 1.45, 4.6)})
		_racers.append({"d": null, "node": _porsze, "name": DRIFTER, "glide": {}, "glow": 7, "size": Vector3(1.85, 1.3, 4.4)})
	_glow_frame()
	_log("meet %s up: %d racers" % [m["id"], _racers.size()])


func _put_node(n: Node3D, at: Vector3, yaw: float) -> void:
	n.global_transform = Transform3D(Basis(Vector3.UP, yaw), at)
	n.visible = true


## Stopped in the ring: the club talks.
func _start_meet(i: int) -> void:
	hud.hide_status()
	_beacon.visible = false
	state = State.MEET if i == 0 else State.MEET2
	_talk_i = 0
	_talk_t = 0.5
	_log("at meet %s" % meets[i]["id"])


## The sirens: police.gd's raid on the meet, the crowd runs, every racer scatters.
func _raid() -> void:
	var m: Dictionary = meets[meet_i]
	state = State.RAID if meet_i == 0 else State.RAID2
	_t = 0.0
	_chase_seen = false
	_line(RAID_LINES[0], 3.0)
	get_tree().create_timer(1.2).timeout.connect(func() -> void: _line(RAID_LINES[1 + (meet_i % 2)], 3.5))
	hud.show_banner("NALOT!", COLOUR)
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		if hud != null:
			hud.hide_banner())
	var sent := 0
	if police != null and police.has_method("raid"):
		sent = int(police.raid(m["at"], RAID_CARS, RAID_LEVEL))
	_crowd_run = 0.01
	_drifting = false
	_tandem = false
	_scatter()
	var boxed := _cordon_in()
	_log("raid at %s: %d patrol cars, %d in the cordon" % [m["id"], sent, boxed])


func _t_raid(dt: float) -> void:
	_t += dt
	var chasing: bool = police != null and police.has_method("chasing") and police.chasing()
	if chasing:
		_chase_seen = true
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var at: Vector3 = v[0]
	var m: Vector3 = meets[meet_i]["at"]
	var away := Vector2(at.x, at.z).distance_to(Vector2(m.x, m.z))
	if chasing:
		# The police pill says it all while they chase (PT-34: the two together pushed the pill
		# down over the car).
		hud.hide_status()
	elif away < PIN_AWAY:
		hud.show_status("NALOT! · UCIEKAJ", "", "%d / %d m" % [roundi(away), roundi(PIN_AWAY)], "Odjedź od spotu", away / PIN_AWAY,
				COLOUR, "", {}, "Get away from the meet")
	elif (not _chase_seen and _t > RAID_WAIT) or (_chase_seen and _t > 2.0):
		hud.hide_status()
		_pin()


func _on_chase_ended(how: String) -> void:
	if state == State.RAID or state == State.RAID2:
		_log("chase ended: %s" % how)
		_chase_seen = true


# --- the cordon -------------------------------------------------------------------------------

## The raid's cordon: CORDON patrol cars (police.gd `scene_car`, lights on) placed CORDON_FROM m out
## round the player, the gaps facing the meet's door, and driven in over the plaza to CORDON_R m
## (`_cordon_frame`). Returns how many came (the police pool may be short; none in Spacer).
func _cordon_in() -> int:
	_cordon_leave(true)
	_cordon_leaving = false
	if police == null or not police.has_method("scene_car") or graph == null or ("gentle" in police and bool(police.gentle)):
		return 0
	var v: Array = vehicle.call() if vehicle.is_valid() else [car.global_position, 0.0, false]
	if bool(v[2]):
		return 0
	var c: Vector3 = v[0]
	var door: Dictionary = meets[meet_i]["door"]
	var e: int = door["e"]
	var s: float = door["s"]
	var lane: int = graph.e_lanes[e] - 1
	var d3: Vector3 = door["at"]
	var a0 := atan2(d3.z - c.z, d3.x - c.x) + PI / float(CORDON)
	for k in CORDON:
		var a := a0 + TAU * float(k) / float(CORDON)
		var out := Vector3(cos(a), 0.0, sin(a))
		var from := c + out * CORDON_FROM
		var to := c + out * CORDON_R
		from.y = _ground(from.x, from.z)
		to.y = _ground(to.x, to.z)
		# Nose in, a little across (they swerve in to block, not park in a neat star).
		var yaw := atan2(out.x, out.z) + (0.35 if k % 2 == 0 else -0.35)
		var d = police.scene_car(e, lane, s, from, yaw, 0)
		if d == null:
			break
		traffic.park(d, e, s, from, yaw, -1)
		_cordon.append({"d": d, "from": from, "to": to, "yaw": yaw, "t": -k * CORDON_STAGGER, "dur": CORDON_T, "e": e, "s": s})
	return _cordon.size()


## Per frame: the cordon's cars coming in (fast, braking hard at the end), their light pools.
func _cordon_frame(dt: float) -> void:
	_flash_t += dt
	var fm := _flash.multimesh
	for i in CORDON:
		fm.set_instance_color(i, Color(0, 0, 0, 0))
	for i in _cordon.size():
		var d0 = _cordon[i]["d"]
		if d0 == null or not d0.active or i >= CORDON:
			continue
		var red := fmod(_flash_t * 3.0 + i * 0.5, 1.0) < 0.5
		var on := 0.0 if Access.calm else 1.0
		fm.set_instance_transform(i, Transform3D(Basis(), d0.pos + Vector3(0, 0.06, 0)))
		fm.set_instance_color(i, (Color("#ff2a3a") if red else Color("#2a6bff")) * Color(1, 1, 1, 0.75 * on))
	_flash.visible = true
	for cd in _cordon:
		var d = cd["d"]
		if d == null or not d.active:
			continue
		var t: float = float(cd["t"]) + dt
		cd["t"] = t
		if t < 0.0 or t > float(cd["dur"]) + dt:
			continue
		var k := clampf(t / float(cd["dur"]), 0.0, 1.0)
		k = 1.0 - pow(1.0 - k, 3.0)
		var p: Vector3 = (cd["from"] as Vector3).lerp(cd["to"], k)
		p.y = _ground(p.x, p.z)
		traffic.park(d, int(cd["e"]), float(cd["s"]), p, float(cd["yaw"]), -1)


## The cordon goes: each car out of sight leaves (all of them with `now`).
func _cordon_leave(now := false) -> void:
	var kept: Array[Dictionary] = []
	for cd in _cordon:
		var d = cd["d"]
		if d == null or not d.active:
			continue
		if now or not traffic.on_screen(d.pos, 2.0):
			police.scene_leave(d)
		else:
			kept.append(cd)
	_cordon = kept
	if _cordon.is_empty():
		_cordon_leaving = false
		if _flash != null:
			_flash.visible = false


## The club on the minimap (F 2026-11-08: "you can't see the other racers on the map"): every racer
## while they scatter and race, in its neon.
func _racer_dots() -> void:
	if hud == null or not hud.has_method("set_quest_dots"):
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	if state in [State.RAID, State.RAID2, State.RACE]:
		for r in _racers:
			if r["d"] == null and r["node"] == null:
				continue
			var p := _racer_pos(r)
			pts.append(Vector2(p.x, p.z))
			cols.append(GLOWS[clampi(int(r.get("glow", 0)), 0, GLOWS.size() - 1)])
	hud.set_quest_dots(pts, cols)


## The TYGRAM pin after a raid: meet 2 (and the race to it), or the drag.
func _pin() -> void:
	_scene.visible = false
	if meet_i == 0:
		var m: Dictionary = meets[1]
		hud.show_note("TYGRAM · WNRC", Lang.pick("📍 %s. Kto pierwszy, ten lepszy. Psy szukają nas tutaj, nie tam." % m["name"][0],
				"📍 %s. First there wins. The cops are looking for us here, not there." % m["name"][1]), PIN_COLOUR)
		_start_race()
	else:
		hud.show_note("TYGRAM · WNRC", Lang.pick("📍 Zieleniecka, pod dworcem Stadion. Drag. %s" % MOTTO[0],
				"📍 Zieleniecka, by Stadion station. Drag. %s" % MOTTO[1]), PIN_COLOUR)
		_release_racers()
		_show_gate(true)
		state = State.TO_DRAG
		_beacon.place(strip["watch"], MEET_R, true, false)
		_beacon.visible = true
		_hold_t = 0.0
	Access.buzz(40, 0.4)
	_log("pin: %s" % ("race to %s" % meets[1]["id"] if meet_i == 0 else "the drag"))


# --- the racers -------------------------------------------------------------------------------

func _racer_by(name: String) -> Dictionary:
	for r in _racers:
		if String(r["name"]) == name:
			return r
	return {}


## Every racer glides off the plaza to the road (STAGGER s apart), then drives away fast.
func _scatter() -> void:
	var m: Dictionary = meets[meet_i]
	var door: Dictionary = m["door"]
	var k := 0
	for r in _racers:
		var from := _racer_pos(r)
		var e: int = door["e"]
		var s: float = clampf(float(door["s"]) + (k - _racers.size() * 0.5) * 7.0, graph.e_s0[e] + 3.0, graph.e_s1[e] - 3.0)
		var to2 := graph.point_at(e, s, graph.lane_offset(e, graph.e_lanes[e] - 1))
		var to := Vector3(to2.x, graph.height(e, s), to2.y)
		r["glide"] = {"from": from, "to": to, "t": -k * STAGGER, "dur": maxf(1.2, from.distance_to(to) / GLIDE_V), "e": e, "s": s,
				"then": "drive"}
		k += 1


func _racer_pos(r: Dictionary) -> Vector3:
	if r["d"] != null:
		return r["d"].pos
	return (r["node"] as Node3D).global_position


## Per frame: the gliding racers (and the drift, crowd and smoke in `_scene_frame`).
func _glides(dt: float) -> void:
	for r in _racers:
		var g: Dictionary = r["glide"]
		if g.is_empty():
			continue
		g["t"] = float(g["t"]) + dt
		var t: float = g["t"]
		if t < 0.0:
			continue
		var k := clampf(t / float(g["dur"]), 0.0, 1.0)
		var from: Vector3 = g["from"]
		var to: Vector3 = g["to"]
		var p := from.lerp(to, k * k * (3.0 - 2.0 * k))
		var dir := to - from
		var yaw := atan2(-dir.x, -dir.z)
		if r["d"] != null:
			traffic.park(r["d"], int(g["e"]), float(g["s"]), p, yaw, -1)
		else:
			(r["node"] as Node3D).global_transform = Transform3D(Basis(Vector3.UP, yaw), p)
		if k >= 1.0:
			r["glide"] = {}
			_hand_over(r, String(g["then"]), int(g["e"]), float(g["s"]))
	if _scene.visible:
		_glow_frame()


## A racer at the road: into traffic (a pool car unparks, Darek's and Lena's cars become node
## drivers) and away, fast; or parked in the new ring ("park").
func _hand_over(r: Dictionary, then: String, e: int, s: float) -> void:
	if then != "drive":
		return
	var lane: int = graph.e_lanes[e] - 1
	if r["d"] == null:
		var size: Vector3 = r.get("size", Vector3(1.8, 1.4, 4.4))
		r["d"] = traffic.add_node_driver(r["node"], size, e, lane, s)
	else:
		traffic.unpark(r["d"], e, lane, s)
	var d = r["d"]
	if d == null:
		return
	d.persistent = true
	d.race_top = _player_top() * _rng.randf_range(RACE_SHARE.x, RACE_SHARE.y)
	d.race_accel = _rng.randf_range(RACE_ACCEL.x, RACE_ACCEL.y)
	d.race_lat = RACE_LAT
	d.race_band = 1.0
	d.speed_factor = 1.4
	d.accel_factor = 1.6
	if state == State.RACE and not _race_dist.is_empty():
		_race_off(d)


## A racer off to meet 2 by the club's shortcuts.
func _race_off(d) -> void:
	d.cuts = _cut_table
	traffic.race_to(d, _race_node, _race_cut_dist)


func _player_top() -> float:
	if car != null and "max_speed" in car and "top_mult" in car:
		return float(car.max_speed) * float(car.top_mult)
	return 30.0


## The race to meet 2: every racer (those still gliding join when they reach the road).
func _start_race() -> void:
	var m: Dictionary = meets[1]
	var door: Dictionary = m["door"]
	_race_node = graph.e_b[int(door["e"])]
	_race_dist = graph.distances_to(_race_node)
	_race_cut_dist = _race_dist
	_cut_table = {}
	if _cuts == null:
		_cuts = RaceCuts.new()
		_cuts.load_cuts(graph)
	if _cuts.a.size() > 0:
		var both: Array = _cuts.links(1.0, 873)
		_cut_table = both[0]
		_race_cut_dist = graph.distances_to(_race_node, INF, true, both[1])
	_there.clear()
	for r in _racers:
		var d = r["d"]
		if d != null and r["glide"].is_empty() and not d.parked:
			_race_off(d)
	state = State.RACE
	_t = 0.0
	_line(RACE_LINES[_rng.randi() % RACE_LINES.size()], 3.5)
	if _beacon.has_method("recolour"):
		_beacon.recolour(PIN_COLOUR)
	_beacon.place(m["at"], ARRIVE_R * 0.6, true, false)
	_beacon.visible = true
	_log("race to %s: %d m by road from the meet" % [m["id"], roundi(graph.remaining(_race_dist, int(meets[0]["door"]["e"]), float(meets[0]["door"]["s"])))])


func _player_left() -> float:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var goal: Vector3 = meets[1]["at"]
	var hit: Array = graph.snap(p, 25.0)
	if hit.is_empty():
		return p.distance_to(Vector2(goal.x, goal.z)) * 1.3
	var e: int = hit[0]
	var s: float = hit[2]
	var best := graph.remaining(_race_dist, e, s)
	var rev: int = graph.e_reverse[e]
	if rev >= 0:
		best = minf(best, graph.remaining(_race_dist, rev, graph.e_len[e] - s) + 25.0)
	return best


## The race's place now: 1 + the racers already there + those with less road left.
func _place_now() -> int:
	var mine := _player_left()
	var p := 1 + _there.size()
	for i in _racers.size():
		var d = _racers[i]["d"]
		if i in _there or d == null or d.parked:
			continue
		if traffic.remaining(d) < mine:
			p += 1
	return p


func _t_race(dt: float, at: Vector3) -> void:
	_t += dt
	var goal: Vector3 = meets[1]["at"]
	for i in _racers.size():
		var d = _racers[i]["d"]
		if d == null or i in _there:
			continue
		if d.arrived or (not d.parked and traffic.remaining(d) < 12.0):
			_there.append(i)
			_log("%s there (%d.)" % [_racers[i]["name"], _there.size()])
	var p := _place_now()
	var n := _racers.size() + 1
	_status("%s · WYŚCIG" % String(meets[1]["name"][0]).to_upper(), "Bądź pierwszy na miejscu", "Be first there",
			at, goal, PIN_COLOUR, "%d/%d" % [p, n] if p > 1 else "1ST")
	if Vector2(at.x, at.z).distance_to(Vector2(goal.x, goal.z)) <= ARRIVE_R:
		_race_done(1 + _there.size())


## Arrived at meet 2 in place `p`: the pay, the new ring (racers who are there park in it; the rest
## come in out of sight), the club talks.
func _race_done(p: int) -> void:
	place = p
	last_pay = place_pay(p)
	if wallet != null:
		wallet.pay(int(last_pay[0]), int(last_pay[1]), "meet_race")
	var title := "PIERWSZY!" if p == 1 else "%d. MIEJSCE" % p
	var title_en := "FIRST!" if p == 1 else "PLACE %d" % p
	hud.toast("%s  +%d zł  +%d" % [title, last_pay[0], last_pay[1]], "%s  +%d zł  +%d RESPECT" % [title_en, last_pay[0], last_pay[1]])
	hud.hide_status()
	_beacon.visible = false
	_log("race done: place %d of %d, +%d zł +%d" % [p, _racers.size() + 1, last_pay[0], last_pay[1]])
	_show_meet(1)
	var slots: Array = meets[1]["slots"]
	var c: Vector3 = meets[1]["at"]
	var door: Dictionary = meets[1]["door"]
	for i in _racers.size():
		var r: Dictionary = _racers[i]
		var d = r["d"]
		var slot: Vector3 = slots[i % slots.size()]
		var yaw := atan2(slot.x - c.x, slot.z - c.z)
		if r["node"] == _porsze or r["node"] == _bawarka:
			# The tandem in the middle (_scene_frame drives both).
			r["glide"] = {}
			if d != null:
				traffic.remove(d)
				r["d"] = null
			continue
		if d == null:
			if r["node"] != null:
				_put_node(r["node"], slot, yaw)
			continue
		r["glide"] = {}
		traffic.stop_racing(d)
		traffic.park(d, int(door["e"]), float(door["s"]), slot, yaw, -1)
		if r["node"] != null:
			_put_node(r["node"], slot, yaw)
	_glow_frame()
	state = State.MEET2
	_talk_i = 0
	_talk_t = 1.5
	_skajlajner.visible = true
	var last: Vector3 = slots[slots.size() - 1]
	_put_node(_skajlajner, c + (last - c) * 0.6, atan2(-(c.x - last.x), -(c.z - last.z)))


## The racers leave the quest: back to ordinary traffic (released out of sight), Darek's and Lena's
## node drivers gone.
func _release_racers() -> void:
	for r in _racers:
		var d = r["d"]
		if d != null and d.active:
			if r["node"] != null:
				traffic.remove(d)
			else:
				d.persistent = false
				if d.parked:
					traffic.unpark(d, int(meets[meet_i]["door"]["e"]), 0, float(meets[meet_i]["door"]["s"]))
				traffic.stop_racing(d)
		if r["node"] != null:
			(r["node"] as Node3D).visible = false
	_racers.clear()
	_scene.visible = false
	if hud != null and hud.has_method("set_quest_dots"):
		hud.set_quest_dots(PackedVector2Array(), PackedColorArray())


# --- the meet's frame -------------------------------------------------------------------------

func _scene_frame(dt: float) -> void:
	if _drifting:
		_drift_a += DONUT_W * dt
		var p := Vector3(cos(_drift_a) * DONUT_R, 0.0, sin(_drift_a) * DONUT_R)
		var tangent := Vector3(-sin(_drift_a), 0.0, cos(_drift_a))
		var yaw := atan2(-tangent.x, -tangent.z) + DONUT_SLIP
		var c: Vector3 = _scene.position
		_porsze.global_transform = Transform3D(Basis(Vector3.UP, yaw), c + p)
		_porsze.visible = true
		var back := Basis(Vector3.UP, yaw) * Vector3(0, 0, 1.6)
		_puff(c + p + back + Vector3(0, 0.5, 0))
		if _tandem:
			var a2 := _drift_a - TANDEM_LAG
			var r2 := DONUT_R + TANDEM_OUT
			var p2 := Vector3(cos(a2) * r2, 0.0, sin(a2) * r2)
			var t2 := Vector3(-sin(a2), 0.0, cos(a2))
			var yaw2 := atan2(-t2.x, -t2.z) + DONUT_SLIP + 0.08
			_bawarka.global_transform = Transform3D(Basis(Vector3.UP, yaw2), c + p2)
			_puff(c + p2 + Basis(Vector3.UP, yaw2) * Vector3(0, 0, 1.7) + Vector3(0, 0.5, 0))
	if _smoke.visible:
		var mm := _smoke.multimesh
		for i in SMOKE:
			if _smoke_t[i] >= SMOKE_LIFE:
				continue
			_smoke_t[i] += dt
			var k := _smoke_t[i] / SMOKE_LIFE
			var sc := 0.6 + 1.8 * k
			var at: Vector3 = _smoke_at[i] + Vector3(0, 1.2 * k, 0) - _scene.position
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(sc, sc, sc)), at))
			mm.set_instance_color(i, Color(1, 1, 1, 0.42 * (1.0 - k) * (0.0 if Access.calm else 1.0)))
	if _crowd_run > 0.0:
		_crowd_run += dt
		var cm := _crowd.multimesh
		for k in CROWD:
			var p: Vector3 = _crowd_at[k] * (1.0 + _crowd_run * 0.6)
			cm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, atan2(-p.x, -p.z)), p))
		if _crowd_run > 4.0:
			_crowd.visible = false
			_crowd_run = 0.0


func _puff(at: Vector3) -> void:
	if _smoke_t[_smoke_next] < SMOKE_LIFE * 0.35:
		return
	_smoke_t[_smoke_next] = 0.0
	_smoke_at[_smoke_next] = at
	_smoke_next = (_smoke_next + 1) % SMOKE


## The neon slabs under the cars of the ring (where they are now).
func _glow_frame() -> void:
	var mm := _glow.multimesh
	var n := 0
	for r in _racers:
		var k: int = int(r.get("glow", n))
		if k >= mm.instance_count:
			continue
		var p := _racer_pos(r)
		var yaw: float = r["d"].yaw if r["d"] != null else (r["node"] as Node3D).global_rotation.y
		var on: bool = r["d"] == null or r["d"].parked
		mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, yaw), p - _scene.position + Vector3(0, 0.08, 0)))
		mm.set_instance_color(k, GLOWS[k] if on else Color(0, 0, 0, 0))
		n += 1
	for k in range(n, mm.instance_count):
		if k >= _racers.size():
			mm.set_instance_color(k, Color(0, 0, 0, 0))


# --- the drag ---------------------------------------------------------------------------------

## At the start: two exhibition pairs launch down the strip, then START DRAG comes up.
func _watch() -> void:
	state = State.WATCH
	hud.hide_status()
	_beacon.visible = false
	_line(DRAG_LINES["watch"], 4.0)
	var prof: Array = sim_run(float(car.accel) * float(car.accel_mult), _player_top() * DRAG_TOP, 0.3, 0.5, false)
	_shows.clear()
	for k in 2:
		var cars := [_show_cars[k * 2], _show_cars[k * 2 + 1]]
		_shows.append({"cars": cars, "t": -2.5 - k * 9.0, "profile": prof[1], "k": [1.0 + 0.04 * k, 0.97 - 0.03 * k]})
		for j in 2:
			_put_node(cars[j], strip_at(0.0, -float(strip["lane_gap"]) * j), strip_yaw())
	_put_node(_skajlajner, strip_at(-12.0, -float(strip["lane_gap"])), strip_yaw())
	get_tree().create_timer(5.0).timeout.connect(func() -> void:
		if state == State.WATCH:
			_line(DRAG_LINES["boss"], 4.0))
	_log("watch: two pairs, then START DRAG")


func _shows_frame(dt: float) -> void:
	var done: Array[Dictionary] = []
	for sh in _shows:
		sh["t"] = float(sh["t"]) + dt
		var t: float = sh["t"]
		var cars: Array = sh["cars"]
		for j in 2:
			var s := 0.0 if t < 0.0 else profile_at(sh["profile"], t * float(sh["k"][j]))
			(cars[j] as Node3D).global_transform = Transform3D(Basis(Vector3.UP, strip_yaw()), strip_at(s, -float(strip["lane_gap"]) * j))
		if t > -1.4 and t < -1.0 and dialogue != null and dialogue.bubbles != null and not dialogue.bubbles.is_talking(cars[0]):
			dialogue.bubbles.say(cars[0], "Start", "3… 2… 1…", "", 1.4, BUBBLE)
		if t > 0.0 and profile_at(sh["profile"], t) > QUARTER + 140.0:
			done.append(sh)
	for sh in done:
		for c: Node3D in sh["cars"]:
			c.visible = false
		_shows.erase(sh)


## START DRAG (and REWANŻ): the car on the line next to Tadek, the tree, drag tune, nitro on loan.
func _stage() -> void:
	for sh in _shows:
		for c: Node3D in sh["cars"]:
			c.visible = false
	_shows.clear()
	state = State.STAGE
	hud.hide_status()
	_beacon.visible = false
	_show_gate(true)
	_tree_t = 0.0
	_green_at = TREE_PRE + 3.0 * TREE_STEP + _rng.randf_range(0.0, TREE_JITTER)
	_react = -1.0
	_gear = 0
	_shift_w = -1.0
	_boost_t = 0.0
	_bog_t = 0.0
	_spin_t = 0.0
	_player_s = 0.0
	_rival_s = 0.0
	_rival_done = -1.0
	drag_time = 0.0
	if place_car.is_valid():
		place_car.call(strip_at(0.0), strip_yaw())
	_put_node(_skajlajner, strip_at(0.0, -float(strip["lane_gap"])), strip_yaw())
	_top_was = float(car.top_mult)
	_accel_was = float(car.accel_mult)
	_nitro_was = bool(car.nitro_owned)
	_nitro_charge_was = float(car.nitro_charge)
	if LOAN:
		car.nitro_owned = true
		car.nitro_charge = 1.0
	car.top_mult = _top_was * DRAG_TOP * float(GEARS[0])
	var rr := rival_run(float(car.accel) * _accel_was, float(car.max_speed) * _top_was * DRAG_TOP)
	_rival_profile = rr[0]
	_rival_k = rr[1]
	_rival_time = float(rr[2])
	if police != null and "gentle" in police:
		_gentle_was = bool(police.gentle)
		police.gentle = true
	_clear_strip(true)
	_tree.visible = true
	_tree.ambers = 0
	_tree.green = false
	_tree.red = false
	_tree.since_green = 0.0
	_tree.word = ""
	_tree.queue_redraw()
	_revs = 0.0
	_rev_gas = false
	_tacho.launch = LAUNCH
	_tacho.staging = true
	_quiet(true)
	hud.hide_status()
	if dialogue != null and dialogue.bubbles != null:
		dialogue.bubbles.clear()
	_tacho.show_at = SHIFT_SHOW
	_tacho.green_at = SHIFT_AT
	_tacho.gears = GEARS.size()
	_tacho.gear = 0
	_tacho.k = 0.0
	_tacho.kmh = 0.0
	_tacho.limiter = false
	_tacho.visible = true
	_log("stage: Tadek's run %.2f s (ok %.2f, perfect %.2f)" % [rr[2], rr[3], rr[4]])


## Called by main.gd after the controls set the car's inputs: on the line and in the run the car
## points down the strip (back to its line if it drifted) and any gas is full gas. On the line the
## gas still moves it (a false start stays possible).
func hold_car(c: Node) -> void:
	if c == null or not (state == State.STAGE or state == State.RUN) or not bool(strip.get("ok", false)):
		return
	hold_inputs(c, strip)
	if state == State.STAGE:
		# The launch: the gas revs the engine, the car stays on the line (no false start by gas).
		_rev_gas = float(c.throttle) > 0.05 or bool(c.nitro_on)
		c.throttle = 0.0
		c.nitro_on = false


## hold_car's inputs for a car on a strip ({start, dir, right} as Vector2s), static for the check.
static func hold_inputs(c: Node, on: Dictionary) -> void:
	var p := Vector2(c.global_position.x, c.global_position.z)
	var rel: Vector2 = p - (on["start"] as Vector2)
	var lat := rel.dot(on["right"])
	var d: Vector2 = (on["dir"] as Vector2) - (on["right"] as Vector2) * clampf(lat * 0.04, -0.15, 0.15)
	c.target_dir = Vector3(d.x, 0.0, d.y).normalized()
	c.steer = 0.0
	if float(c.throttle) > 0.05 or bool(c.nitro_on):
		c.throttle = 1.0


## Per frame on the line and in the run.
func _drag_frame(dt: float) -> void:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var rel: Vector2 = p - (strip["start"] as Vector2)
	_player_s = rel.dot(strip["dir"])
	var lat := rel.dot(strip["right"])
	if state == State.STAGE:
		_tree_t += dt
		var a := clampi(int((_tree_t - TREE_PRE) / TREE_STEP) + 1, 0, 3) if _tree_t >= TREE_PRE else 0
		if a != _tree.ambers:
			_tree.ambers = a
			_tree.queue_redraw()
			if a > 0:
				Access.buzz(30, 0.4)
		if _player_s > FALSE_M or absf(lat) > 3.0:
			_tree.red = true
			_tree.queue_redraw()
			_line(DRAG_LINES["false"], 3.0)
			_drag_end(false, "false")
			return
		_revs = clampf(_revs + (REV_UP if _rev_gas else -REV_DOWN) * dt, 0.0, 1.0)
		_tacho.k = _revs
		_tacho.kmh = 0.0
		if _tree_t >= _green_at:
			_tree.green = true
			_tree.queue_redraw()
			state = State.RUN
			_run_t = 0.0
			_tacho.staging = false
			_launch(launch_grade(_revs))
			Access.buzz(80, 0.8)
		return
	_run_t += dt
	if _react < 0.0 and _player_s > 0.5:
		_react = _run_t
	# Tadek.
	var rt := maxf(0.0, _run_t - RIVAL_REACT)
	_rival_s = 0.0 if _run_t < RIVAL_REACT else profile_at(_rival_profile, rt * _rival_k + RIVAL_REACT)
	_skajlajner.global_transform = Transform3D(Basis(Vector3.UP, strip_yaw()), strip_at(_rival_s, -float(strip["lane_gap"])))
	if _rival_done < 0.0 and _rival_s >= QUARTER:
		_rival_done = _run_t
	# The gears: yours to shift (the tacho, or the context button); the box only saves a run
	# left on the limiter AUTO_SHIFT s.
	_boost_t = maxf(0.0, _boost_t - dt)
	_bog_t = maxf(0.0, _bog_t - dt)
	_spin_t = maxf(0.0, _spin_t - dt)
	car.accel_mult = _accel_was * (SHIFT_BOOST if _boost_t > 0.0 else 1.0) * (EARLY_BOG if _bog_t > 0.0 else 1.0) \
			* (SPIN if _spin_t > 0.0 else 1.0)
	car.top_mult = _top_was * DRAG_TOP * float(GEARS[_gear])
	var cap := float(car.max_speed) * float(car.top_mult)
	var v: float = car.vel.length()
	if _gear < GEARS.size() - 1:
		if v >= cap * SHIFT_AT:
			_shift_w = 0.0 if _shift_w < 0.0 else _shift_w + dt
			if _shift_w >= AUTO_SHIFT:
				_shift("auto")
		# PT-50: the button only from the yellow (it was up from green, the needle at 1,500).
		if v >= cap * SHIFT_SHOW:
			if not hud.pill_shown("drag_shift"):
				hud.show_pill("⬆ BIEG", "⬆ SHIFT", "drag_shift")
		elif hud.pill_shown("drag_shift"):
			hud.hide_pill()
	elif hud.pill_shown("drag_shift"):
		hud.hide_pill()
	_tacho.k = v / maxf(cap, 0.1)
	_tacho.gear = _gear
	_tacho.kmh = v * 3.6
	_tacho.limiter = _shift_w > PERFECT
	_tree.since_green += dt
	if _tree.visible and _run_t > 1.5:
		_tree.visible = false
	elif _tree.visible:
		_tree.queue_redraw()
	if absf(lat) > STRIP_HALF or _player_s < -10.0:
		_drag_end(false, "off")
		return
	if _player_s >= QUARTER:
		drag_time = _run_t
		_drag_end(_rival_done < 0.0 or _run_t < _rival_done, "line")
	elif _rival_done > 0.0 and _run_t > _rival_done + 6.0:
		_drag_end(false, "slow")


## The drag's quiet screen on or off: the HUD's ticker, notes and toasts, and every bubble.
func _quiet(on: bool) -> void:
	if hud != null and hud.has_method("set_hush"):
		hud.set_hush(on)
	if dialogue != null and dialogue.bubbles != null and "quiet_all" in dialogue.bubbles:
		dialogue.bubbles.quiet_all = on


## Green: the launch's effect, and its word in the count's place (PT-48: a banner under the green
## START! was lost in it; now the launch's word replaces START!, in its own colour).
func _launch(grade: String) -> void:
	match grade:
		"perfect":
			_boost_t = BOOST_S
			_tree.word = Lang.pick("IDEALNY START!", "PERFECT LAUNCH!")
			_tree.word_colour = Color("#38f6ff")
		"spin":
			_spin_t = SPIN_S
			_tree.word = Lang.pick("BUKSOWANIE!", "WHEELSPIN!")
			_tree.word_colour = Color("#ffb21e")
		_:
			_bog_t = BOG_S
			_tree.word = Lang.pick("ZA MAŁO OBROTÓW", "BOGGED DOWN")
			_tree.word_colour = Color("#ffb21e")
	_tree.queue_redraw()
	_log("launch: %s (revs %.2f)" % [grade, _revs])


func _shift_pressed() -> void:
	if _gear >= GEARS.size() - 1:
		return
	var cap := float(car.max_speed) * float(car.top_mult)
	_shift(shift_grade_at(float(car.vel.length()) / maxf(cap, 0.1), _shift_w))


## A shift: "perfect" (a burst), "late" (just the gear), "early" (a bog), "auto" (the box did it).
func _shift(how: String) -> void:
	_gear += 1
	_shift_w = -1.0
	hud.hide_pill()
	match how:
		"perfect":
			_boost_t = BOOST_S
			hud.show_banner(Lang.pick("IDEALNIE!", "PERFECT!"), Color("#3cff6a"))
			Access.buzz(40, 0.6)
		"early":
			_bog_t = BOG_S
			hud.show_banner(Lang.pick("ZA WCZEŚNIE", "TOO EARLY"), Color("#ffb21e"))
		"good":
			hud.show_banner(Lang.pick("DOBRZE", "GOOD"), Color("#f2f2f2"))
		"late":
			hud.show_banner(Lang.pick("ZA PÓŹNO", "LATE"), Color("#ffb21e"))
		"auto":
			hud.show_banner(Lang.pick("SPÓŹNIONY BIEG", "MISSED SHIFT"), Color("#ffb21e"))
		_:
			hud.show_banner("BIEG %d" % (_gear + 1), Color("#f2f2f2"))
	get_tree().create_timer(0.7).timeout.connect(func() -> void:
		if hud != null and state == State.RUN:
			hud.hide_banner())
	_log("shift to %d: %s" % [_gear + 1, how])


## The run is over: the card. `how`: "line" (crossed it), "false", "off", "slow".
func _drag_end(won: bool, how: String) -> void:
	state = State.RESULT
	_t = 0.0
	drag_won = won
	_restore_car()
	hud.hide_pill()
	hud.hide_banner()
	_tacho.visible = false
	_quiet(false)
	_tree.visible = how == "false"
	if _tree.visible:
		get_tree().create_timer(2.0).timeout.connect(func() -> void: _tree.visible = false)
	var pay: Array = DRAG_PAY if won else DRAG_LOSE
	if wallet != null:
		wallet.pay(int(pay[0]), int(pay[1]), "meet_drag")
		if won:
			wallet.keep["wnrc_member"] = true
			wallet.keep["wnrc_wins"] = int(wallet.keep.get("wnrc_wins", 0)) + 1
			wallet.record("drag_402", drag_time)
	var react := "%.2f s" % _react if _react >= 0.0 else "—"
	# Not across yet: his run's own time (he finishes it behind you).
	var tad := "%.2f s" % (_rival_done if _rival_done > 0.0 else maxf(_rival_time, drag_time + 0.01))
	var body := ""
	var body_en := ""
	var title := ""
	var title_en := ""
	match how:
		"false":
			title = "FALSTART"
			title_en = "FALSE START"
			body = "Ruszyłeś przed zielonym. %s" % MOTTO[0]
			body_en = "You went before the green. %s" % MOTTO[1]
		"off":
			title = "POZA PASEM"
			title_en = "OFF THE STRIP"
			body = "Drag jedzie się prosto. Prawie jak życie."
			body_en = "A drag goes straight. Almost like life."
		_:
			title = "RESPEKT!" if won else "TADEK WYGRAŁ"
			title_en = "RESPECT!" if won else "TADEK WON"
			body = "Ty %s · reakcja %s · Tadek %s. %s" % ["%.2f s" % drag_time if drag_time > 0.0 else "—", react, tad,
					"Karta klubu %s jest twoja." % CLUB if won else MOTTO[0]]
			body_en = "You %s · reaction %s · Tadek %s. %s" % ["%.2f s" % drag_time if drag_time > 0.0 else "—", react, tad,
					"The %s card is yours." % CLUB if won else MOTTO[1]]
	body += "  +%d zł  +%d" % [pay[0], pay[1]]
	body_en += "  +%d zł  +%d respect" % [pay[0], pay[1]]
	var buttons := PackedStringArray(["OK|OK"]) if won else PackedStringArray(["REWANŻ|REMATCH", "KONIEC|DONE"])
	hud.show_card(title, body, buttons, COLOUR, false, title_en, body_en)
	_line(DRAG_LINES["win" if won else ("false" if how == "false" else "lose")], 4.0)
	_log("drag %s (%s): you %.2f s, reaction %s, Tadek %s" % ["won" if won else "lost", how, drag_time, react, tad])


func _t_result(dt: float) -> void:
	_t += dt
	if _t > RESULT_LIFE:
		hud.hide_card()
		_finish()


func _restore_car() -> void:
	if car == null:
		return
	car.top_mult = _top_was
	car.accel_mult = _accel_was
	if LOAN and not _nitro_was:
		car.nitro_owned = false
		car.nitro_on = false
	car.nitro_charge = maxf(_nitro_charge_was, 0.0) if not _nitro_was else car.nitro_charge
	if police != null and "gentle" in police:
		police.gentle = _gentle_was


## Ordinary traffic off the strip (out of the cars' way): all of it at the line, then any car that
## wanders in ahead.
func _clear_strip(all := false) -> void:
	if traffic == null or not bool(strip.get("ok", false)):
		return
	for d in traffic.drivers().duplicate():
		if d.persistent or d.parked or d.ghost:
			continue
		var rel := Vector2(d.pos.x, d.pos.z) - (strip["start"] as Vector2)
		var along := rel.dot(strip["dir"])
		var side := rel.dot(strip["right"])
		if along > (-40.0 if all else _player_s + 15.0) and along < QUARTER + 80.0 and absf(side + float(strip["lane_gap"]) * 0.5) < 9.0:
			traffic.remove(d)


# --- the end ----------------------------------------------------------------------------------

func _give_up() -> void:
	hud.hide_status()
	hud.toast("„Spoko, następnym razem.” Darek odjeżdża bokiem.", "\"No worries, next time.\" Darek leaves sideways.")
	_log("gave up in %s" % STATES[state])
	_finish()


func _finish() -> void:
	if state == State.STAGE or state == State.RUN:
		_restore_car()
	hud.hide_status()
	hud.hide_pill()
	_release_racers()
	_beacon.visible = false
	_tree.visible = false
	_tacho.visible = false
	_quiet(false)
	_show_gate(false)
	for n: Node3D in [_bawarka, _porsze, _skajlajner] + _show_cars:
		n.visible = false
	_shows.clear()
	_cordon_leave(true)
	if missions != null:
		missions.paused = _calls_were
	_reset()
	call_in = _rng.randf_range(NEXT_CALL.x, NEXT_CALL.y)


func _reset() -> void:
	state = State.IDLE
	_hold_t = 0.0
	_t = 0.0
	if call_in <= 0.0:
		call_in = _rng.randf_range(NEXT_CALL.x, NEXT_CALL.y)


## --meet-at=raid|race|meet2|drag|stage: jump to that beat (tests and screenshots).
func jump(beat: String) -> void:
	if state == State.IDLE:
		accept()
	match beat:
		"meet":
			if place_car.is_valid():
				place_car.call(meets[0]["gap"], 0.0)
			_start_meet(0)
		"raid":
			_start_meet(0)
			_raid()
		"race":
			_start_meet(0)
			_scatter()
			_pin()
		"meet2":
			_start_meet(0)
			_scatter()
			meet_i = 0
			_start_race()
			if place_car.is_valid():
				place_car.call(meets[1]["gap"], 0.0)
			_race_done(1)
		"drag", "stage":
			_release_racers()
			_scene.visible = false
			meet_i = 1
			_beacon.visible = false
			if place_car.is_valid():
				place_car.call(strip["watch"], strip_yaw())
			_show_gate(true)
			_watch()
			if beat == "stage":
				_stage()
	_log("jump to %s" % beat)
