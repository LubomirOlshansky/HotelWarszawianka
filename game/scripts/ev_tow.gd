extends "res://scripts/activity.gd"
## Dead electric cars (F's ask, 2026-11-06): range anxiety, Warsaw edition.
##
## **The call.** Now and then, with nothing else on, the phone rings: BARTEK DZWONI. Answer it and
## Bartek, a mate from school, explains that his TESŁO Model Ś (our parody: a white electric
## fastback with green plates) stands at 0 % on a street across town. LECĘ! takes the player up
## in the helicopter at once (the car is left where it stands, as with the vehicle button). Fly
## to the car (Bartek waves next to it: the dashed pickup ring), come down until the sling hooks
## on, then carry the car on its rope to a charger by a real place (Elektrownia Powiśle, Hala
## Koszyki, Złote Tarasy, the Palace's car park), lower it onto the bay and it is set down and
## plugged in. On the way Bartek, who climbed in beside the pilot, talks: winter range, green
## plates and free parking, a diesel Pasatini blocking the charger, door handles that hide,
## updates, "ironic, burning kerosene to save the planet" (dialogue.json `ev_tow`). Swing the car
## too hard and he begs you to stop. ✕ sets the car down where it hangs (no pay).
##
## **The stranded ones.** Every few minutes a dead TESŁO stands with its hazards blinking in the
## kerb lane of a main road ahead (the crash scenes' spot rules: crash_scenes.gd `pick_spot`),
## traffic going round it (an invisible parked traffic car holds the lane: traffic.gd
## add_parked_car), its driver complaining in bubbles (`ev_stranded`) and KEBAB FM reading it
## out (`radio_host`, tag `ev`). From the helicopter, with nothing else on, come down over one
## and it hooks on as well: a shorter carry to the nearest charger for a tip.
##
## The car on the rope is a damped pendulum under the helicopter (`swing_step`, static: the check
## runs it), resting on whatever is under it (ground, deck or roof: map `top_height`). Cost: the
## car is one mesh (one draw call, the models' material) plus its hazards (one more, blinking),
## the rope a thin box (one), the charger a totem (one); only while a car is out. Idle: a timer.
##
## An activity of the kit (activity.gd, tech-debt TD-1): the call's two cards and their buttons,
## the target the arrow leads to, the ✕ and the end are the kit's. This script keeps what is the
## tow's own: Bartek's call clock (it stands while something else is on), the stranded cars, the
## sling, the carry and the pay. It is the kit's first activity that is flown (`flown`).
##
## Flags (main.gd): --ev-call (the call rings at once), --ev-tow (accepted at once, the
## helicopter over the car), --ev-tow=carry (the car already on the rope), --ev-stranded (a
## stranded car about 30 m ahead now), --ev=0 (none of it), --ev-log.

const Models := preload("res://scripts/models.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const CrashScenes := preload("res://scripts/crash_scenes.gd")

const NAME := "TESŁO"
const MODEL := "Model Ś"
const CALLER := "Bartek"
const COLOUR := Color("#3fd17a")        ## the job's colour: charger green
const PICK_COLOUR := Color("#ffc23a")   ## the car to pick up (the rescues' amber)
const FAIL_COLOUR := Color("#e2574c")
const BUBBLE := Color("#3fd17a")

## The call: seconds of free play before the first, then between calls (declined or done).
const FIRST_CALL := Vector2(300.0, 480.0)
const NEXT_CALL := Vector2(720.0, 1080.0)
## The ringing card waits this long before Bartek gives up.
const RING_LIFE := 25.0
## Where his car stands: a main road this far from the player.
const CAR_FROM := 450.0
const CAR_TO := 1050.0
## The sling: rope length (helicopter skids to the car's roof), hooking reach and speed.
const ROPE := 10.0
const HOOK_R := 7.0
const HOOK_SPEED := 8.0      ## m/s, the helicopter no faster than this
const HOOK_HOLD := 0.8
## Setting down: the car this close to the bay, resting on the ground, for DROP_HOLD s.
const DROP_R := 9.0
const DROP_HOLD := 0.6
const REST := 0.35           ## the car's floor this close to the ground counts as resting
## The pendulum: the air's drag on the car (per second: what makes it trail behind a flying
## helicopter, about 25° at full speed), the swing's own damping (its motion relative to the hook,
## so it doesn't add to the trail) and how far (radians) counts as a wild swing.
const AIR_DRAG := 0.15
const SWING_DAMP := 0.9
const SWING_WILD := 0.6
const SWING_GAP := 9.0
## Bartek talks every TALK_GAP s during the carry.
const TALK_GAP := Vector2(7.5, 11.0)
## Pay: the call, a stranded stranger's tip; a quick carry (under QUICK s from hooking) adds BONUS.
const PAY := 180
const RESPECT := 30
const TIP := 60
const TIP_RESPECT := 10
const QUICK := 150.0
const BONUS := 60
const RESULT_LIFE := 10.0
## The stranded cars: the first after FIRST_STRAND s, the next GAP_STRAND s after one clears.
const FIRST_STRAND := Vector2(110.0, 220.0)
const GAP_STRAND := Vector2(170.0, 320.0)
const STRAND_LIFE := Vector2(170.0, 280.0)
const STRAND_TALK_R := 45.0
const STRAND_FAR := 650.0
const TICK := 0.25

## The chargers: next to these real places (map metres of a point of the landmark; the bay is the
## kerb lane of the nearest road, `setup`). Elektrownia Powiśle is the old power station: Bartek
## likes the name.
const CHARGERS := [
	{"id": "elektrownia", "place": "Elektrownia Powiśle", "at": Vector2(247.4, -772.6)},
	{"id": "koszyki", "place": "Hala Koszyki", "at": Vector2(-896.6, 1334.9)},
	{"id": "tarasy", "place": "Złote Tarasy", "at": Vector2(-1558.6, 461.2)},
	{"id": "palac", "place": "Pałac Kultury", "at": Vector2(-1080.0, 250.0)},
]

## The car's size (x wide, y high, z long) and the paints.
const SIZE := Vector3(1.95, 1.44, 4.7)
const WHITE := Color("#eef0f2")
const GLASS := Color("#1d242c")
const TYRE := Color("#1a1a1c")
const RIM := Color("#8a9097")
const PLATE := Color("#3fa34d")   ## Polish EV plates are green
const TAIL := Color("#c8202a")
const AMBER := Color("#ffae1a")

## The run's own stages (the kit has the call and the offer): flying to the car, the car on the
## rope, the car on the bay with the result card.
enum Stage { NONE, FLY, CARRY, RESULT }

var graph: LaneGraph
var traffic: Node3D
var radio: Node
var heli: Node3D
## Takes the player up in the helicopter (main.gd `_take_off`).
var take_off: Callable
var enabled := true
## The call (and the stranded cars) on their timers (off in test runs but for the flags).
var auto := true

var stage := Stage.NONE
var call_in := 0.0
var strand_in := 0.0
## The car on the job: {at: Vector3, yaw, e, lane, s, driver, street, stranger: bool}; {} none.
var job := {}
## The stranded car out now (same keys), {} none.
var strand := {}
## The chargers found on the map: {id, place, at: Vector3 (the bay), yaw, side: Vector3 (the
## totem's spot)}.
var chargers: Array[Dictionary] = []
var target := -1
## Calls answered and carries finished this session (the check, the log).
var calls := 0
var carried := 0
var last_pay := {}

## The pendulum: the car's rope point (its roof) and velocity.
var hang := Vector3.ZERO
var hang_v := Vector3.ZERO
var _hook_t := 0.0
var _drop_t := 0.0
var _carry_clock := 0.0
var _talk_t := 0.0
var _swing_t := 0.0
var _result_t := 0.0
## The quarter-second step's own time, and the session's clock for the log.
var _acc := 0.0
var _clock := 0.0
var _blink := 0.0
var _said_low := false
## A tow is on (from LECĘ! or the hook on a stranger's car to the end): `_ended` clears it.
var _towing := false
var _rng := RandomNumberGenerator.new()
var _heli_anchor := func() -> Vector3: return heli.global_position

var _car: MeshInstance3D
var _hazards: MeshInstance3D
var _body: StaticBody3D
var _rope: MeshInstance3D
var _totem: MeshInstance3D
var _strand_car: MeshInstance3D
var _strand_hazards: MeshInstance3D
var _strand_body: StaticBody3D
var spent_usec := 0


func _init() -> void:
	tag = "ev"
	colour = COLOUR
	rescue_calls = RescueCalls.HOLD  # the rescue calls wait for a tow and go on after it (the director)
	dark = Color("#2f6fb5")  # Bartek's shirt, in the pickup ring
	card_life = RING_LIFE
	flown = true


func setup(world: Node3D, seed_value := -1) -> void:
	super.setup(world)
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	call_in = _rng.randf_range(FIRST_CALL.x, FIRST_CALL.y)
	strand_in = _rng.randf_range(FIRST_STRAND.x, FIRST_STRAND.y)
	var mesh := car_mesh()
	var lights := hazard_mesh()
	_car = _node(world, mesh)
	_hazards = _node(_car, lights)
	_body = _collider(_car)
	_strand_car = _node(world, mesh)
	_strand_hazards = _node(_strand_car, lights)
	_strand_body = _collider(_strand_car)
	_rope = _node(world, rope_mesh())
	_totem = _node(world, charger_mesh())
	if graph != null:
		chargers = find_chargers(graph, map)
	var names := PackedStringArray()
	for c in chargers:
		names.append("%s %d,%d" % [c["id"], roundi(c["at"].x), roundi(c["at"].z)])
	_log("%d chargers (%s); first call in %.0f s, first stranded car in %.0f s" % [chargers.size(), ", ".join(names), call_in, strand_in])


func _node(parent: Node, mesh: Mesh) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = Models.material()
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	m.visible = false
	parent.add_child(m)
	return m


## The car's box for the player's car to bump into (layer 1, as the walls), off while it hangs.
func _collider(parent: Node3D) -> StaticBody3D:
	var b := StaticBody3D.new()
	var s := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SIZE
	s.shape = box
	s.position = Vector3(0, SIZE.y * 0.5, 0)
	b.add_child(s)
	b.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(b)
	return b


func _set_body(b: StaticBody3D, on: bool) -> void:
	b.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	b.collision_layer = 1 if on else 0


# --- meshes ---------------------------------------------------------------------------------

## The TESŁO Model Ś: a white fastback, a dark glass roof running into the rear window, no grille
## (it has nothing to cool), green plates front and back, a full-width red tail strip. Local
## frame: +Z forward, origin on the ground (the rope ties on at the roof's middle, SIZE.y).
static func car_mesh() -> ArrayMesh:
	var st := Models._begin()
	var w := SIZE.x
	var l := SIZE.z
	Models.box(st, Vector3(0, 0.55, 0), Vector3(w, 0.62, l), WHITE)                       # the body
	Models.box(st, Vector3(0, 0.82, 1.55), Vector3(w - 0.08, 0.12, 1.5), WHITE)            # the long smooth bonnet
	Models.box(st, Vector3(0, 0.78, -1.75), Vector3(w - 0.08, 0.1, 1.1), WHITE)            # the boot lid
	Models.box(st, Vector3(0, 1.12, -0.15), Vector3(w - 0.2, 0.62, 2.3), GLASS)            # the glass cabin
	Models.box(st, Vector3(0, 1.1, 1.05), Vector3(w - 0.3, 0.42, 0.5), GLASS)              # the raked windscreen
	Models.box(st, Vector3(0, 1.0, -1.45), Vector3(w - 0.3, 0.36, 0.55), GLASS)            # the fastback's rear glass
	Models.box(st, Vector3(0, SIZE.y - 0.02, -0.15), Vector3(0.12, 0.04, 2.0), WHITE)      # the roof seam
	Models.box(st, Vector3(0, 0.62, -l * 0.5 - 0.01), Vector3(w - 0.1, 0.07, 0.04), TAIL, Models.TAIL_LAMP)  # the tail strip
	Models.box(st, Vector3(0, 0.42, -l * 0.5 - 0.02), Vector3(0.52, 0.12, 0.03), PLATE)    # green plates
	Models.box(st, Vector3(0, 0.42, l * 0.5 + 0.02), Vector3(0.52, 0.12, 0.03), PLATE)
	Models.box(st, Vector3(0, 0.66, l * 0.5 + 0.01), Vector3(w - 0.2, 0.05, 0.04), Color("#dfe6ee"))  # the light bar
	for z: float in [-1.45, 1.45]:
		for x: float in [-1.0, 1.0]:
			var sx := x * (w * 0.5 - 0.12)
			Models.box(st, Vector3(sx, 0.34, z), Vector3(0.26, 0.68, 0.68), TYRE)
			Models.box(st, Vector3(sx + x * 0.135, 0.34, z), Vector3(0.02, 0.42, 0.42), RIM)
	return st.commit()


## The hazard lights: four amber corners (a second node, blinked by toggling it).
static func hazard_mesh() -> ArrayMesh:
	var st := Models._begin()
	for z: float in [-SIZE.z * 0.5 - 0.02, SIZE.z * 0.5 + 0.02]:
		for x: float in [-1.0, 1.0]:
			Models.box(st, Vector3(x * (SIZE.x * 0.5 - 0.2), 0.68, z), Vector3(0.36, 0.14, 0.06), AMBER, Models.LIT_SIGN)
	return st.commit()


## The rope: a dark 12 cm box (thick enough to read from the follow camera) one metre long from y 0 down to -1 (scaled to the length).
static func rope_mesh() -> ArrayMesh:
	var st := Models._begin()
	Models.box(st, Vector3(0, -0.5, 0), Vector3(0.12, 1.0, 0.12), Color("#2b2620"))
	return st.commit()


## The charger: a white totem 2.4 m tall, a dark screen, a green lightning bolt and band, the
## cable's holster. Local frame: +Z towards the bay.
static func charger_mesh() -> ArrayMesh:
	var st := Models._begin()
	Models.box(st, Vector3(0, 1.2, 0), Vector3(0.7, 2.4, 0.42), Color("#f4f4f2"))
	Models.box(st, Vector3(0, 2.42, 0), Vector3(0.78, 0.06, 0.5), COLOUR)
	Models.box(st, Vector3(0, 1.55, 0.22), Vector3(0.48, 0.42, 0.03), GLASS)
	# The bolt: three slanted steps in green.
	Models.box(st, Vector3(0.06, 2.12, 0.22), Vector3(0.12, 0.16, 0.03), COLOUR)
	Models.box(st, Vector3(0.0, 2.0, 0.22), Vector3(0.22, 0.06, 0.03), COLOUR)
	Models.box(st, Vector3(-0.06, 1.88, 0.22), Vector3(0.12, 0.16, 0.03), COLOUR)
	Models.box(st, Vector3(0.3, 1.0, 0.24), Vector3(0.12, 0.3, 0.1), Color("#2b2c2f"))
	Models.box(st, Vector3(0, 0.05, 0), Vector3(0.9, 0.1, 0.6), Color("#8f9499"))
	return st.commit()


# --- static rules (check_ev_tow.gd runs them) ---------------------------------------------------

## One step of the car on the rope: `p` the rope's end (the car's roof), `v` its velocity, the
## helicopter's hook at `anchor` moving at `anchor_v`, `rope` long; `floor_y` is the top of whatever is under the car
## (its roof can't go below floor_y + SIZE.y). Gravity, damping, the rope's pull (it never
## stretches), the ground's push and friction. Returns [p, v, resting].
static func swing_step(p: Vector3, v: Vector3, anchor: Vector3, anchor_v: Vector3, rope: float, dt: float, floor_y: float) -> Array:
	v += Vector3(0, -9.8, 0) * dt
	v *= exp(-AIR_DRAG * dt)
	v = anchor_v + (v - anchor_v) * exp(-SWING_DAMP * dt)
	p += v * dt
	var d := p - anchor
	var len := d.length()
	if len > rope and len > 0.001:
		var n := d / len
		p = anchor + n * rope
		var out := v.dot(n)
		if out > 0.0:
			v -= n * out
	var resting := false
	var low := floor_y + SIZE.y
	if p.y <= low:
		p.y = low
		if v.y < 0.0:
			v.y = 0.0
		v.x *= exp(-6.0 * dt)
		v.z *= exp(-6.0 * dt)
		resting = true
	return [p, v, resting]


## The swing's angle from straight down (radians), 0 when the rope is slack or the car rests.
static func swing_angle(p: Vector3, anchor: Vector3) -> float:
	var d := p - anchor
	if d.length() < 0.5:
		return 0.0
	return d.angle_to(Vector3.DOWN)


## An edge that can hold a dead car: the crash scenes' rule (a main or secondary road of 2+ lanes,
## off bridges, decks and tunnels, long enough), so the traffic can go round it.
static func fits(g: LaneGraph, e: int) -> bool:
	return CrashScenes.fits(g, e)


## A spot for Bartek's car: a fitting edge crossing a point `lo`..`hi` m from `from` (any way),
## its kerb lane, the car in the middle of the edge's free part: {e, lane, s} or {}.
static func pick_car_spot(g: LaneGraph, from: Vector2, lo: float, hi: float, rng: RandomNumberGenerator, tries := 40) -> Dictionary:
	for k in tries:
		var q := from + Vector2.UP.rotated(rng.randf_range(-PI, PI)) * rng.randf_range(lo, hi)
		var edges: PackedInt32Array = g.grid.get(LaneGraph.cell_key(q), PackedInt32Array())
		if edges.is_empty():
			continue
		var k0 := rng.randi() % edges.size()
		for j in edges.size():
			var e := edges[(k0 + j) % edges.size()]
			if not fits(g, e):
				continue
			var s := clampf(g.project(e, q), g.e_s0[e] + CrashScenes.END_ROOM, g.e_s1[e] - CrashScenes.END_ROOM)
			return {"e": e, "lane": g.e_lanes[e] - 1, "s": s}
	return {}


## The car's pose at spot {e, lane, s}: [position (on the road), yaw], nudged 0.4 m to the kerb.
static func pose(g: LaneGraph, spot: Dictionary) -> Array:
	var e: int = spot["e"]
	var s: float = spot["s"]
	var p := g.point_at(e, s, g.lane_offset(e, int(spot["lane"])) + 0.4)
	var d := g.direction(e, s)
	return [Vector3(p.x, g.height(e, s), p.y), atan2(d.x, d.y)]


## The chargers on this map: for each of CHARGERS, the kerb lane of the nearest ground road (off
## tunnels and bridges) within 180 m of its place; the totem stands on the pavement beside the bay.
static func find_chargers(g: LaneGraph, m: Node3D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c: Dictionary in CHARGERS:
		# snap() looks about a cell round its point: rings of points round the place, the hit
		# nearest the place wins.
		var hit: Array = []
		var best := INF
		for r: float in [0.0, 40.0, 80.0, 120.0, 160.0]:
			for k in (1 if r == 0.0 else 8):
				var q: Vector2 = c["at"] + Vector2(r, 0).rotated(TAU * k / 8.0)
				var h: Array = g.snap(q, 60.0, Vector2.ZERO, false, true, true)
				if h.is_empty() or g.e_dk[h[0]] >= 0 or g.e_s1[h[0]] - g.e_s0[h[0]] < 16.0:
					continue
				var d: float = g.point_at(h[0], h[2]).distance_to(c["at"])
				if d < best:
					best = d
					hit = h
			if not hit.is_empty():
				break
		if hit.is_empty():
			continue
		var e: int = hit[0]
		var lane := g.e_lanes[e] - 1
		var s := clampf(float(hit[2]), g.e_s0[e] + 6.0, g.e_s1[e] - 6.0)
		var lo := g.lane_offset(e, lane)
		var p := g.point_at(e, s, lo + 0.4)
		var side := g.point_at(e, s, lo + g.e_lw[e] * 0.5 + 1.1)
		var d := g.direction(e, s)
		var y := g.height(e, s)
		var sy: float = m.ground_height(side.x, side.y) if m != null and m.has_method("ground_height") else y
		out.append({"id": c["id"], "place": c["place"], "at": Vector3(p.x, y, p.y), "yaw": atan2(d.x, d.y), "e": e, "lane": lane, "s": s,
				"side": Vector3(side.x, maxf(sy, y), side.y), "face": atan2(p.x - side.x, p.y - side.y)})
	return out


## The charger for a car at `from`: the nearest at least `lo` m away (else the farthest), the
## stranger's tow (`near`) the nearest of all. -1 if there are none.
static func pick_charger(list: Array, from: Vector2, lo: float, near := false) -> int:
	var best := -1
	var best_d := INF
	var far := -1
	var far_d := -1.0
	for i in list.size():
		var at: Vector3 = list[i]["at"]
		var d := from.distance_to(Vector2(at.x, at.z))
		if d > far_d:
			far_d = d
			far = i
		if (near or d >= lo) and d < best_d:
			best_d = d
			best = i
	return best if best >= 0 else far


## The pay for a carry: [złoty, respect, bonus], a stranger's tip or Bartek's, quick or not.
static func pay(stranger: bool, secs: float) -> Array:
	var bonus := BONUS if secs <= QUICK else 0
	if stranger:
		return [TIP + bonus / 2, TIP_RESPECT, bonus / 2]
	return [PAY + bonus, RESPECT, bonus]


# --- the frame ------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not enabled or dt <= 0.0:
		return
	var t0 := Time.get_ticks_usec()
	super._process(dt)
	spent_usec += Time.get_ticks_usec() - t0


## Every frame, whatever the phase: the hazards' blink, the pendulum, and the quarter-second step.
func _tick(dt: float) -> void:
	_clock += dt
	_blink += dt
	var on := fmod(_blink, 0.9) < 0.45
	if _hazards.visible != on and _car.visible and stage != Stage.RESULT:
		_hazards.visible = on
	if _strand_car.visible and _strand_hazards.visible != on:
		_strand_hazards.visible = on
	if stage == Stage.CARRY:
		_carry(dt)
	_acc += dt
	if _acc >= TICK:
		step(_acc)
		_acc = 0.0


## The slow part, every TICK s: the stranded cars, Bartek's own call clock, the run's stages.
func step(dt: float) -> void:
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var at: Vector3 = v[0]
	var flying: bool = v[2]
	_strand_tick(dt, at, flying)
	if phase == Phase.IDLE:
		if auto and _free():
			call_in -= dt
			if call_in <= 0.0 and not ring():
				call_in = 20.0
		_stranger_hook(dt, at, flying)
		return
	match stage:
		Stage.FLY:
			_fly(dt, at, flying)
		Stage.CARRY:
			_carry_status()
		Stage.RESULT:
			# The car stays on the bay for a moment, the card up or already closed, then it goes.
			_result_t += dt
			if _result_t > RESULT_LIFE or Vector2(at.x, at.z).distance_to(Vector2(job["at"].x, job["at"].z)) > 220.0:
				finish()


## The kit's call clock is not used: Bartek's own (`call_in`, in `step`) stands while something
## else is on, and the stranded cars share the step.
func _idle_tick(_dt: float) -> void:
	pass


func _free() -> bool:
	return free_now.is_valid() and bool(free_now.call()) and chargers.size() > 0


## The car hangs on the rope: the vehicle button can't land (main.gd).
func carrying() -> bool:
	return stage == Stage.CARRY


## The arrow's point: the car to pick up, then the charger's bay, at their own height (a car on
## a bridge deck stands above the ground the kit's target is put on).
func target_position() -> Vector3:
	if stage == Stage.CARRY and target >= 0:
		return chargers[target]["at"]
	return job.get("at", Vector3.ZERO)


func target_colour() -> Color:
	return COLOUR if stage == Stage.CARRY else PICK_COLOUR


## No stop assist: the rings are for the helicopter.
func stop_spot() -> Vector3:
	return Vector3.INF


# --- the call -------------------------------------------------------------------------------

## The phone rings (--ev-call too): the first card, ANSWER / DECLINE. False with no chargers.
func ring() -> bool:
	if chargers.is_empty() or graph == null:
		return false
	return super.ring()


func _call_card() -> Dictionary:
	return {"who": CALLER, "about": ["Kumpel z liceum. Ma elektryka. Mówi tylko o nim.", "School mate. Went electric. Talks of nothing else."]}


## He talks: where the car is and where it must go; LECĘ! / NIE TERAZ. Nothing ({}: no offer)
## when no road has room for his car.
func _offer_card() -> Dictionary:
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var from := Vector2((v[0] as Vector3).x, (v[0] as Vector3).z)
	var spot := pick_car_spot(graph, from, CAR_FROM, CAR_TO, _rng)
	if spot.is_empty():
		spot = pick_car_spot(graph, from, 150.0, CAR_TO * 1.6, _rng)
	if spot.is_empty():
		return {}
	var p := pose(graph, spot)
	job = {"at": p[0], "yaw": p[1], "e": spot["e"], "lane": spot["lane"], "s": spot["s"], "street": graph.e_name[spot["e"]],
			"stranger": false, "driver": null}
	target = pick_charger(chargers, Vector2(p[0].x, p[0].z), 600.0)
	var street: String = job["street"] if job["street"] != "" else "jakiejś bocznej"
	var street_en: String = job["street"] if job["street"] != "" else "some side street"
	var place: String = chargers[target]["place"]
	_log("offer: car on %s at %d,%d, charger %s %.0f m on" % [street_en, roundi(p[0].x), roundi(p[0].z), chargers[target]["id"],
			Vector2(p[0].x, p[0].z).distance_to(Vector2(chargers[target]["at"].x, chargers[target]["at"].z))])
	return {"title": ["📞 %s" % CALLER.to_upper(), CALLER], "face": CALLER, "buttons": ["LECĘ!|ON MY WAY", "NIE TERAZ|NOT NOW"],
			"body": ["„Siema! Słuchaj, mam sprawę… Moje %s stanęło na %s. Zero procent. Aplikacja mówiła, że dojadę, ale chyba liczyła latem. Podepniesz go helikopterem na linę i zaniesiesz pod ładowarkę przy %s? Stawiam kawę. Dwie. Ładowanie i tak potrwa.”" % [NAME, street, place],
			"\"Hey! Listen, I need a favour… My %s died on %s. Zero percent. The app said I'd make it, but I think it was counting in summer. Can you hook it on a rope under the helicopter and fly it to the charger by %s? Coffee's on me. Two. Charging takes ages anyway.\"" % [NAME, street_en, place]]}


## Bartek's words when the call or the offer is turned down, or nobody answers.
func _refused(timed_out: bool) -> void:
	if timed_out:
		hud.toast("Nieodebrane połączenie: %s" % CALLER, "Missed call: %s" % CALLER)
	elif phase == Phase.RING:
		hud.toast("Odrzucono. %s napisze SMS-a. Długiego." % CALLER, "Declined. %s will text. A long one." % CALLER)
	else:
		hud.toast("„Spoko, poczekam. Mam 0 %%, czasu mam dużo.”", "\"No worries, I'll wait. I've got 0 %%, I've got time.\"")


## The run begins: LECĘ! (--ev-tow too), his car on the road, the helicopter up, the pickup ring
## with Bartek; or a stranger's car already hooked on (`_stranger_hook`), straight to the carry.
func _begin() -> void:
	_towing = true
	if bool(job.get("stranger", false)):
		_hook()
		return
	calls += 1
	_show_car(_car, _hazards, _body, job)
	job["driver"] = _hold_lane(job)
	var car_at: Vector3 = job["at"]
	_beacon.pattern = Beacon.Pattern.DASHED
	_beacon.waving = true
	_beacon.recolour(PICK_COLOUR)
	set_target(Vector2(car_at.x, car_at.z), true, car_at + Vector3(-1.6, 0, 1.2).rotated(Vector3.UP, float(job["yaw"])), HOOK_R)
	stage = Stage.FLY
	_hook_t = 0.0
	_said_low = false
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	if not bool(v[2]) and take_off.is_valid():
		take_off.call()
	hud.toast("Do śmigłowca! Leć do %s i zniż się nad auto" % NAME, "To the helicopter! Fly to the %s and come down over it" % NAME)
	_log("accepted: flying to the car")


# --- flying to the car and hooking ------------------------------------------------------------

func _fly(dt: float, at: Vector3, flying: bool) -> void:
	var car_at: Vector3 = job["at"]
	var flat := Vector2(at.x, at.z).distance_to(Vector2(car_at.x, car_at.z))
	var above := at.y - (car_at.y + SIZE.y)
	var hint := "Zniż się nad %s (▼), aż lina zaczepi" % NAME
	var hint_en := "Come down over the %s (▼) until the sling hooks on" % NAME
	if not flying:
		hint = "Do śmigłowca! (przycisk pojazdu)"
		hint_en = "Take the helicopter (the vehicle button)"
		_hook_t = 0.0
	elif can_hook(flat, above, heli.speed()):
		_hook_t += dt
		if _hook_t >= HOOK_HOLD:
			_hook()
			return
	else:
		_hook_t = maxf(0.0, _hook_t - dt)
		if flat < 40.0 and not _said_low:
			_said_low = true
			_say("hello")
	status("%s %s · 0%%" % [NAME, MODEL], "", "%d m" % roundi(flat), [hint, hint_en], _hook_t / HOOK_HOLD, PICK_COLOUR)


## The sling hooks on: the helicopter within HOOK_R m of the car, its hook no more than the rope
## above the roof (and not inside it), going no faster than HOOK_SPEED.
static func can_hook(flat: float, above: float, speed: float) -> bool:
	return flat <= HOOK_R and above >= 0.5 and above <= ROPE + 2.0 and speed <= HOOK_SPEED


func _hook() -> void:
	_release_lane(job)
	_set_body(_body, false)
	hang = job["at"] + Vector3(0, SIZE.y, 0)
	hang_v = Vector3.ZERO
	_rope.visible = true
	heli.sling = 1.0
	stage = Stage.CARRY
	_carry_clock = 0.0
	_talk_t = 5.0
	_swing_t = 5.0  # the first yank is expected
	_drop_t = 0.0
	var c: Dictionary = chargers[target]
	_totem.global_transform = Transform3D(Basis(Vector3.UP, float(c["face"])), c["side"])
	_totem.visible = true
	var bay: Vector3 = c["at"]
	_beacon.pattern = Beacon.Pattern.SOLID
	_beacon.waving = false
	_beacon.recolour(COLOUR)
	set_target(Vector2(bay.x, bay.z), false, bay, DROP_R)
	_say("elektrownia" if c["id"] == "elektrownia" and not bool(job["stranger"]) else "hook", true)
	Access.buzz(30, 0.4)
	_log("hooked (%s) -> %s" % ["a stranger's car" if job["stranger"] else "Bartek's car", c["id"]])


# --- the carry --------------------------------------------------------------------------------

## Every frame while the car hangs: the pendulum, the car's pose, the rope.
func _carry(dt: float) -> void:
	var anchor := _anchor()
	var before := hang
	var floor_y := _floor(hang, anchor)
	var hv: Vector3 = heli.vel
	var r := swing_step(hang, hang_v, anchor, Vector3(hv.x, heli.vy, hv.z), ROPE, minf(dt, 0.05), floor_y)
	hang = r[0]
	hang_v = r[1]
	# A roof the car can't sit on under the hook is a wall (Autopilot run, 2026-11-06: swung over
	# a 108 m tower's footprint the car "rested" on its roof, 50 m above the helicopter): the car
	# stays where it was across, losing its sideways speed.
	if map != null and is_wall(map.top_height(hang.x, hang.z, 1.2), anchor.y):
		hang.x = before.x
		hang.z = before.z
		hang_v.x = 0.0
		hang_v.z = 0.0
	var resting: bool = r[2]
	job["resting"] = resting
	# The car turns with the helicopter, slowly, and tilts with the rope while it hangs.
	var yaw := lerp_angle(float(job["yaw"]), heli.rotation.y + PI, 1.0 - exp(-1.2 * dt))
	job["yaw"] = yaw
	var up := Vector3.UP if resting else (anchor - hang).normalized().lerp(Vector3.UP, 0.6).normalized()
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	var right := up.cross(fwd).normalized()
	fwd = right.cross(up).normalized()
	var b := Basis(right, up, fwd)
	_car.global_transform = Transform3D(b, hang - up * SIZE.y)
	job["at"] = hang - Vector3(0, SIZE.y, 0)
	var d := anchor - hang
	var len := d.length()
	if len > 0.05:
		var ry := d / len
		var rz := (Vector3.RIGHT if absf(ry.x) < 0.9 else Vector3.FORWARD).cross(ry).normalized()
		var rx := ry.cross(rz).normalized()
		# rope_mesh runs from 0 down to -1: its local +y is the way up the rope (car to hook).
		_rope.global_transform = Transform3D(Basis(rx, ry, rz) * Basis.from_scale(Vector3(1, len, 1)), anchor)
	_carry_clock += dt


## The floor under the hanging car at `p`: the top of whatever is there (ground, deck, roof),
## or the ground where that top is a wall (`is_wall`).
func _floor(p: Vector3, anchor: Vector3) -> float:
	if map == null:
		return 0.0
	var top: float = map.top_height(p.x, p.z, 1.2)
	return map.ground_height(p.x, p.z) if is_wall(top, anchor.y) else top


## A surface `top` high is a wall for a car hanging from a hook at `anchor_y`, not a floor: the
## car on it would stand level with the hook or above it.
static func is_wall(top: float, anchor_y: float) -> bool:
	return top + SIZE.y > anchor_y - 0.5


## The rope's top: under the helicopter's belly, drawn where the helicopter is drawn.
func _anchor() -> Vector3:
	var t: Transform3D = heli.get_global_transform_interpolated() if heli.is_inside_tree() else heli.global_transform
	return t.origin + Vector3(0, 0.2, 0)


func _carry_status() -> void:
	var c: Dictionary = chargers[target]
	var car_at: Vector3 = job["at"]
	var flat := Vector2(car_at.x, car_at.z).distance_to(Vector2(c["at"].x, c["at"].z))
	var resting := bool(job.get("resting", false))
	if flat <= DROP_R and resting:
		_drop_t += TICK
		if _drop_t >= DROP_HOLD:
			_set_down()
			return
	else:
		_drop_t = 0.0
	var dist := "%d m" % roundi(flat) if flat < 1000.0 else "%.1f km" % (flat / 1000.0)
	var hint := "Ładowarka przy: %s" % c["place"]
	var hint_en := "Charger by %s" % c["place"]
	if flat < 60.0:
		hint = "Opuść %s na stanowisko (▼)" % NAME
		hint_en = "Lower the %s onto the bay (▼)" % NAME
	status("%s %s · 0%%" % [NAME, MODEL], "%d:%02d" % [int(_carry_clock) / 60, int(_carry_clock) % 60], dist, [hint, hint_en],
			_drop_t / DROP_HOLD)
	# Bartek talks; a wild swing gets its own line.
	_swing_t -= TICK
	if swing_angle(hang, _anchor()) > SWING_WILD and _swing_t <= 0.0:
		_swing_t = SWING_GAP
		_say("swing", true)
		return
	_talk_t -= TICK
	if _talk_t <= 0.0:
		_talk_t = _rng.randf_range(TALK_GAP.x, TALK_GAP.y)
		_say("carry")


## On the bay: the car straightens up on it, plugged in; the pay and the card.
func _set_down() -> void:
	var c: Dictionary = chargers[target]
	_rope.visible = false
	clear_target()
	heli.sling = 0.0
	hide_status()
	job["at"] = c["at"]
	job["yaw"] = c["yaw"]
	job["e"] = c["e"]
	job["lane"] = c["lane"]
	job["s"] = c["s"]
	job["driver"] = _hold_lane(job)
	_car.global_transform = Transform3D(Basis(Vector3.UP, float(c["yaw"])), c["at"])
	_hazards.visible = false
	_set_body(_body, true)
	var p := pay(bool(job["stranger"]), _carry_clock)
	last_pay = {"zl": p[0], "respect": p[1], "bonus": p[2], "secs": _carry_clock}
	if wallet != null:
		wallet.pay(p[0], p[1], "ev_tow")
	carried += 1
	_said_low = false
	var title := "NAŁADOWANE: 3 %"
	var bonus_pl := " (+%d zł za szybki lot)" % p[2] if p[2] > 0 else ""
	var bonus_en := " (+%d zł for a quick flight)" % p[2] if p[2] > 0 else ""
	stage = Stage.RESULT
	_result_t = 0.0
	if bool(job["stranger"]):
		show_card([title, "CHARGED: 3 %"], ["Kierowca obcego %s płaci %d zł%s. „Pan z nieba! Napiszę na grupie, że diesle nie mają takiego serwisu.”" % [NAME, p[0], bonus_pl],
				"The stranger pays %d zł%s. \"A man from the sky! I'm posting in the group that diesels get no service like this.\"" % [p[0], bonus_en]],
				PackedStringArray(["OK"]))
	else:
		show_card([title, "CHARGED: 3 %"], ["%s płaci %d zł%s i +%d szacunku. „40 minut i jestem jak nowy. Kawa i rogal na mnie. A szwagrowi z Pasatini ani słowa!”" % [CALLER, p[0], bonus_pl, p[1]],
				"%s pays %d zł%s and +%d respect. \"40 minutes and I'm good as new. Coffee and a croissant on me. And not a word to my brother-in-law with the Pasatini!\"" % [CALLER, p[0], bonus_en, p[1]]],
				PackedStringArray(["OK"]))
	_log("set down at %s after %.0f s: +%d zł" % [c["id"], _carry_clock, p[0]])


## The ✕ only while flying to the car or carrying it (not over the result card).
func _can_abort() -> bool:
	return stage == Stage.FLY or stage == Stage.CARRY


## ✕: the car is set down where it is (on the ground under it), no pay; Bartek sighs.
func drop(_by_player: bool) -> void:
	if stage == Stage.CARRY:
		_say("drop", true)
	_log("given up")
	_end(call_cool)


## Back to idle (the kit's `_end` has taken down the status line, the card and the ring): after
## a tow the car, the rope and the charger's totem go and the rescue calls come back; after a
## call or an offer nobody took, only the next call's time is drawn.
func _ended() -> void:
	var was_stranger := bool(job.get("stranger", false))
	stage = Stage.NONE
	if not _towing:
		job = {}
		call_in = _rng.randf_range(NEXT_CALL.x, NEXT_CALL.y)
		_log("next call in %.0f s" % call_in)
		return
	_towing = false
	_release_lane(job)
	heli.sling = 0.0
	_car.visible = false
	_hazards.visible = false
	_set_body(_body, false)
	_totem.visible = false
	_rope.visible = false
	job = {}
	target = -1
	if not was_stranger:
		call_in = _rng.randf_range(NEXT_CALL.x, NEXT_CALL.y)


# --- the stranded cars -------------------------------------------------------------------------

func _strand_tick(dt: float, at: Vector3, flying: bool) -> void:
	if traffic == null or graph == null:
		return
	if strand.is_empty():
		if not auto:
			return
		strand_in -= dt
		if strand_in <= 0.0 and not place_stranded(Vector2(at.x, at.z), _heading(at), false):
			strand_in = 5.0
		return
	strand["age"] = float(strand["age"]) + dt
	var m: Vector3 = strand["at"]
	var dist := Vector2(at.x, at.z).distance_to(Vector2(m.x, m.z))
	if (float(strand["age"]) > float(strand["life"]) or dist > STRAND_FAR) and not traffic.on_screen(m, 2.0):
		clear_stranded()
		strand_in = _rng.randf_range(GAP_STRAND.x, GAP_STRAND.y)
		return
	if dist < STRAND_TALK_R and not flying and dialogue != null:
		strand["talk"] = float(strand["talk"]) - dt
		if float(strand["talk"]) <= 0.0:
			strand["talk"] = _rng.randf_range(4.0, 6.5)
			if not strand.has("anchor"):
				var head := m
				strand["anchor"] = func() -> Vector3: return head
			dialogue.say_ambient(strand["anchor"], "", "ev_stranded", "", 3.6, BUBBLE, 2.2)


var _last_at := Vector3.INF
var _head := Vector2.ZERO


func _heading(at: Vector3) -> Vector2:
	if _last_at != Vector3.INF and Vector2(at.x - _last_at.x, at.z - _last_at.z).length() > 0.5:
		_head = Vector2(at.x - _last_at.x, at.z - _last_at.z).normalized()
	_last_at = at
	return _head


## A stranded TESŁO ahead of `from` (out of sight; `near`: about 30 m ahead for shots), in the kerb
## lane of a main road with the traffic going round. True if one was placed.
func place_stranded(from: Vector2, heading: Vector2, near: bool) -> bool:
	if not strand.is_empty():
		clear_stranded()
	for attempt in 6:
		var spot: Dictionary
		if near:
			spot = pick_car_spot(graph, from + (heading if heading != Vector2.ZERO else Vector2.UP) * 32.0, 0.0, 10.0, _rng)
		else:
			var cs := CrashScenes.pick_spot(graph, from, heading, _rng)
			if cs.is_empty():
				continue
			spot = {"e": cs["e"], "lane": cs["lane"], "s": float(cs["s0"]) + CrashScenes.SPAN * 0.5}
		if spot.is_empty():
			continue
		var p := pose(graph, spot)
		if not near and traffic.on_screen(p[0], 2.0):
			continue
		var s: float = spot["s"]
		if not traffic.lane_free(spot["e"], spot["lane"], s - 4.0, s + 4.0, 8.0):
			continue
		strand = {"at": p[0], "yaw": p[1], "e": spot["e"], "lane": spot["lane"], "s": s, "street": graph.e_name[spot["e"]],
				"stranger": true, "driver": null, "age": 0.0, "life": _rng.randf_range(STRAND_LIFE.x, STRAND_LIFE.y), "talk": 0.5}
		_show_car(_strand_car, _strand_hazards, _strand_body, strand)
		strand["driver"] = _hold_lane(strand)
		_announce(str(strand["street"]))
		_log("stranded car at %d,%d (%s, %.0f m away)" % [roundi(p[0].x), roundi(p[0].z), strand["street"], from.distance_to(Vector2(p[0].x, p[0].z))])
		return true
	return false


func clear_stranded() -> void:
	if strand.is_empty():
		return
	_release_lane(strand)
	_strand_car.visible = false
	_strand_hazards.visible = false
	_set_body(_strand_body, false)
	if dialogue != null and dialogue.bubbles != null and strand.has("anchor"):
		dialogue.bubbles.hush(strand["anchor"])
	strand = {}


## From the helicopter, with nothing else on: low over the stranded car it hooks on (a stranger's
## tow to the nearest charger).
func _stranger_hook(dt: float, at: Vector3, flying: bool) -> void:
	if strand.is_empty() or not flying or chargers.is_empty() or not (free_now.is_valid() and bool(free_now.call())):
		_hook_t = 0.0
		return
	var m: Vector3 = strand["at"]
	var flat := Vector2(at.x, at.z).distance_to(Vector2(m.x, m.z))
	if flat < 60.0 and not bool(strand.get("hinted", false)):
		strand["hinted"] = true
		hud.toast("Rozładowane %s! Zniż się nad nie, żeby je podczepić" % NAME, "A dead %s! Come down over it to hook it on" % NAME)
	if can_hook(flat, at.y - (m.y + SIZE.y), heli.speed()):
		_hook_t += dt
		if _hook_t >= HOOK_HOLD:
			# The stranded car becomes the job's car.
			job = strand.duplicate()
			strand = {}
			_strand_car.visible = false
			_strand_hazards.visible = false
			_set_body(_strand_body, false)
			_show_car(_car, _hazards, _body, job)
			target = pick_charger(chargers, Vector2(m.x, m.z), 0.0, true)
			start()  # the kit's run, with no call: `_begin` hooks the car on
			strand_in = _rng.randf_range(GAP_STRAND.x, GAP_STRAND.y)
	else:
		_hook_t = 0.0


# --- shared bits --------------------------------------------------------------------------------

func _show_car(node: MeshInstance3D, lights: MeshInstance3D, body: StaticBody3D, c: Dictionary) -> void:
	node.global_transform = Transform3D(Basis(Vector3.UP, float(c["yaw"])), c["at"])
	node.visible = true
	lights.visible = true
	_set_body(body, true)


## An invisible parked traffic car in the dead car's lane, so the traffic queues and goes round.
func _hold_lane(c: Dictionary):
	if traffic == null or int(c.get("e", -1)) < 0:
		return null
	var d = traffic.add_parked_car(int(c["e"]), float(c["s"]), c["at"], float(c["yaw"]) + PI, int(c["lane"]), 1, WHITE)
	if d != null:
		d.ghost = true
		d.visible = false
	return d


func _release_lane(c: Dictionary) -> void:
	if c.is_empty() or c.get("driver") == null or traffic == null:
		return
	traffic.drop_parked(c["driver"])
	c["driver"] = null


## Bartek's line (dialogue.json `ev_tow`, tag), over the helicopter (he's in it) or by his car.
func _say(kind: String, prefer := true) -> void:
	if dialogue == null:
		return
	# One anchor per place he talks from, so his next line replaces the last (bubbles.gd).
	if stage == Stage.FLY:
		var at: Vector3 = job["at"]
		if not job.has("anchor"):
			job["anchor"] = func() -> Vector3: return at
	var anchor: Callable = job["anchor"] if stage == Stage.FLY else _heli_anchor
	var who := "Kierowca" if bool(job.get("stranger", false)) else CALLER
	var t := kind
	if bool(job.get("stranger", false)) and kind in ["hook", "carry"]:
		t = "stranger"
	var l: Array = dialogue.say(anchor, who, "ev_tow", t, 4.6, BUBBLE, 3.0, prefer)
	if not l.is_empty():
		_log("%s: %s" % [who, l[0]])


## KEBAB FM reads a stranded car out (radio_host lines tagged "ev"; {street}).
func _announce(street: String) -> void:
	if radio == null or dialogue == null or radio.station < 0:
		return
	var l: Array = dialogue.line("radio_host", "ev", true)
	if l.is_empty() or dialogue.notes(l).get("only", "") != "ev":
		return
	var pl := street if street != "" else "Ulica bez nazwy"
	var en := street if street != "" else "A street with no name"
	radio.announce(String(l[0]).replace("{street}", pl), String(l[1]).replace("{street}", en))


func _log(text: String) -> void:
	if log_on:
		print("ev: %s (%.1f s)" % [text, _clock])
