extends Node
## Crash scenes (stłuczki, 2026-11-01, F's ask): now and then, somewhere on a main road ahead of
## the player, two traffic cars have had a fender bender and stand in the kerb lane. A police car
## with its light bar flashing guards the scene from behind, an ambulance (karetka) stands ahead
## with its blue lamps going; the two drivers argue, an officer and a paramedic stand by and a few
## onlookers film it all. The traffic in that lane queues behind the scene and goes round it into
## the next lane (traffic.gd PARKED_LOOK / PARKED_WAIT); KEBAB FM's host reads it out on the
## ticker, and close by the people talk in speech bubbles (dialogue.json `crash_scene`).
##
## Everything is reused, so a scene costs +0 draw calls: the wrecks are two cars of the CAR
## MultiMesh parked in the lane (traffic.gd add_parked_car), the police car and the ambulance are
## the POLICE MultiMesh's shapes 0 and 2 (models.gd police_mesh, bound as police units of role
## "crash": police.gd scene_car; their halos light the road at night), the people are pedestrians'
## SCENE figures (pedestrians.gd set_scene) and the bubbles are the HUD's.
##
## One scene at a time: the first FIRST s into the drive, the next GAP s after one clears. A scene
## is placed AHEAD m ahead of the player (main and secondary roads with 2+ lanes, off any bridge
## or tunnel, out of sight), lives LIFE s and is taken away only when the view can't see it (or
## the player is past FAR m from it). Nothing runs per frame but a timer: one tick every TICK s.
##
## Road life (F, 2026-11-23, docs/design/road-life.md): a scene is now one of two kinds. TAXI_SHARE
## of them are a taxi check (kontrola taksówki): a city taxi or a Podwózka stopped in the kerb lane
## (traffic.gd add_parked_car, kind TAXI: +0 draw calls), the patrol car behind it with its lights
## on, an officer at the driver's window with the papers, a second by the patrol car, the driver
## out on the kerb explaining, the passenger on the footway late for the airport and an onlooker
## (dialogue.json `taxi_check`, KEBAB FM's `radio_host` tag "taxi_check"). No ambulance and no
## siren at a taxi check. No new scene while `hushed` says so (road_life.gd: a race, a chase, the
## first minutes' guide), so a race or the guide's drive never meets one.
##
## Road life stage 2: TOW_SHARE of scenes are an "Odholowanie": a car left half on the pavement
## (the CAR pool's hatch in Models.TOW_LOAD_PAINT), a laweta stopped in the kerb lane ahead of it
## (the VAN pool's shape Models.VAN_TOW: +0 draw calls), its operator at the platform, a city guard
## writing it up and the owner running back in a bathrobe with a Frogs bag ("Byłem pięć minut!";
## dialogue.json `tow_scene`, KEBAB FM's "tow"). When the player comes within TALK_REACH m the car
## is pulled up onto the platform over TOW_LOAD_TIME s (moved frame by frame, `_load_step`) and
## the laweta takes its place as the loaded shape (Models.VAN_TOW_LOADED, the car drawn where the
## lifted one ended: no jump), then after TOW_LEAVE s it pulls out and drives off with the traffic.

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Models := preload("res://scripts/models.gd")

const TICK := 0.5
## The share of scenes that are a taxi check (the rest are fender benders).
const TAXI_SHARE := 0.4
## The taxi check along the kerb lane, metres from its rear end: the patrol car, the taxi.
const AT_TAXI_POLICE := 4.0
const AT_TAXI := 10.6
## The taxi check's people: [tag in `taxi_check`, shirt, trousers 0..1]: 0 the officer at the
## window, 1 the officer by the patrol car, 2 the taxi's driver, 3 the passenger, 4 an onlooker.
const TAXI_PEOPLE := [["officer", "#e8f23a", 0.1], ["officer", "#e8f23a", 0.1], ["driver", "#3a3d42", 0.4],
		["passenger", "#b0413e", 0.75], ["gawker", "#3b8f5a", 0.9]]
## Who talks at a taxi check, in turn (indices into TAXI_PEOPLE).
const TAXI_TURNS := [0, 2, 3, 0, 2, 4, 1, 3, 2, 0, 3, 4]
const TAXI_LINES := "taxi_check"
const TAXI_RADIO_TAG := "taxi_check"
const TAXI_BUBBLE := Color("#ffd23f")
## The share of scenes that are an Odholowanie (a tow).
const TOW_SHARE := 0.25
## Along the kerb lane from the scene's rear end: the abandoned car, the laweta (its middle; the
## truck is 6.6 m long, so its rear is 3.1 m ahead of the car's front).
const AT_TOW_CAR := 4.2
const AT_TOW := 12.6
## The abandoned car stands this far right of the kerb line's inside (half on the footway), this
## high (the kerb), turned this much (radians).
const TOW_CAR_SIDE := 0.05
const TOW_CAR_UP := 0.08
const TOW_CAR_TURN := -0.09
## The lift: TOW_LOAD_TIME s from the kerb onto the platform; TOW_LEAVE s later the laweta goes.
const TOW_LOAD_TIME := 5.0
const TOW_LEAVE := 7.0
## Where the car goes on its way up, in the laweta's own frame (its front is -z): behind the ramp
## tips, at the platform's end, on the platform (Models.TOW_LOAD_AT).
const TOW_FOOT := Vector3(0.0, 0.0, 5.85)
const TOW_LIP := Vector3(0.0, 1.27, 4.3)
## The Odholowanie's people: 0 the laweta's operator, 1 the city guard, 2 the owner, 3 an onlooker.
const TOW_PEOPLE := [["operator", "#e8f23a", 0.3], ["guard", "#26324a", 0.1], ["owner", "#d98fb0", 0.6],
		["gawker", "#7a4fa8", 0.5]]
const TOW_TURNS := [1, 0, 2, 1, 2, 3, 0, 2, 1, 3, 2]
const TOW_LINES := "tow_scene"
const TOW_RADIO_TAG := "tow"
const TOW_BUBBLE := Color("#ffc21a")
## Seconds to the first scene, between one clearing and the next, and a scene's life.
const FIRST := Vector2(80.0, 150.0)
const GAP := Vector2(180.0, 330.0)
const LIFE := Vector2(150.0, 240.0)
## Where a scene goes: this many metres from the player, within ±SPREAD radians of the way they
## are going (anywhere round them when standing still).
const AHEAD := Vector2(130.0, 260.0)
const SPREAD := 0.8
## The scene's layout along the kerb lane, metres from its rear end: the police car, the car that
## ran into the other, the car it hit, the ambulance; SPAN is the whole scene. Each wreck is
## turned and pushed off the lane's line a little (radians, metres right).
const AT_POLICE := 2.4
const AT_HITTER := 9.6
const AT_HIT := 14.8
const AT_AMBULANCE := 22.4
const SPAN := 25.0
const HITTER_TURN := 0.32
const HITTER_OFF := -0.35
const HIT_TURN := -0.14
const HIT_OFF := 0.3
## The scene keeps this far clear of either end of its edge (the queue needs room to go round:
## traffic.gd's lane change needs 18 m left on the edge).
const END_ROOM := 28.0
## The player within TALK_REACH m of the scene's middle hears it: a line every TALK_GAP s.
const TALK_REACH := 50.0
const TALK_GAP := Vector2(2.6, 4.2)
## Past FAR m (and out of sight) the scene goes early.
const FAR := 650.0
## The radio's line once per scene when placed (if a station plays).
const RADIO_GROUP := "radio_host"
const RADIO_TAG := "crash"
const LINES := "crash_scene"
## The people: [tag in `crash_scene`, shirt, trousers 0..1]. 0-1 the drivers, 2 the officer,
## 3 the paramedic, 4-6 the onlookers with their phones up.
const PEOPLE := [["driver", "#2f6fb5", 0.3], ["driver", "#c96b2c", 0.8], ["officer", "#e8f23a", 0.1],
		["medic", "#e8572a", 0.6], ["gawker", "#7a4fa8", 0.5], ["gawker", "#3b8f5a", 0.9], ["gawker", "#e8e4d8", 0.2]]
## Who talks, in turn: indices into PEOPLE (the drivers most).
const TURNS := [0, 1, 2, 0, 4, 1, 3, 5, 0, 1, 2, 6, 3]
const BUBBLE := Color("#ff6b5a")
## The wrecks' paints (the traffic's own palette, models.gd TRAFFIC[0]).
const WRECK_SHAPES := 4

var traffic: Node3D
var graph: LaneGraph
var map: Node3D
var walkers: Node3D
var dialogue: Node
var police: Node
var radio: Node
## The sound (sfx.gd scene_siren) and the HUD (set_scene_mark); both optional.
var sfx: Node
var hud: Node
## The view's focus and the player's vehicle: [position, km/h, flying].
var focus: Callable
var vehicle: Callable
var log_on := false
## Scenes on or off (--crash=0).
var enabled := true
## Road life: true while no new scene may come (a race, a chase, the guide); empty: never.
var hushed: Callable
## The share of taxi checks (TAXI_SHARE; a check sets 0 or 1 for a kind of its own).
var taxi_share := TAXI_SHARE
## The share of Odholowanie scenes (TOW_SHARE; a check sets 0 or 1).
var tow_share := TOW_SHARE
## Odholowanie: lawetas that loaded a car and left (the checks, the log).
var towed := 0

## Seconds to the next scene; the scene now ({} = none).
var wait := 0.0
var scene := {}
## Scenes placed and cleared this session (the checks, the log).
var placed := 0
var cleared := 0
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _clock := 0.0
var _heading := Vector2.ZERO
var _last_at := Vector2.INF
var spent_usec := 0


func setup(seed_value := -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	wait = _rng.randf_range(FIRST.x, FIRST.y)
	_log("first scene in %.0f s" % wait)


func _process(dt: float) -> void:
	if dt <= 0.0 or not enabled:
		return
	var t0 := Time.get_ticks_usec()
	if not scene.is_empty() and scene.has("load_t"):
		_load_step(dt)
	_t += dt
	if _t >= TICK:
		step(_t)
		_t = 0.0
	spent_usec += Time.get_ticks_usec() - t0


func _exit_tree() -> void:
	if log_on:
		_log("end (%d placed, %d cleared%s)" % [placed, cleared, ", 1 out" if not scene.is_empty() else ""])


## One tick, `dt` seconds after the last.
func step(dt: float) -> void:
	_clock += dt
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var at := Vector2((v[0] as Vector3).x, (v[0] as Vector3).z)
	if _last_at != Vector2.INF and at.distance_to(_last_at) > 0.5:
		_heading = (at - _last_at).normalized()
	_last_at = at
	if scene.is_empty():
		wait -= dt
		if wait <= 0.0:
			if hushed.is_valid() and bool(hushed.call()):
				wait = 5.0  # a race, a chase or the guide: later
			elif not place(at, _heading, false):
				wait = 3.0  # nowhere fitting now: soon again
		return
	scene["age"] = float(scene["age"]) + dt
	var dist := at.distance_to(scene["mid"])
	var over: bool = float(scene["age"]) >= float(scene["life"]) or dist > FAR
	if over and not seen():
		clear()
		wait = _rng.randf_range(GAP.x, GAP.y)
		_log("next scene in %.0f s" % wait)
		return
	_report(over)
	if scene.get("kind", "") == "tow":
		_tow_step(dt, dist)
	if dist < TALK_REACH and not bool(v[2]):
		scene["talk"] = float(scene["talk"]) - dt
		if float(scene["talk"]) <= 0.0:
			_talk()
	else:
		scene["talk"] = minf(float(scene["talk"]), 0.8)


## A spot for a scene: an edge of a main or secondary road (class 0-1) with 2+ lanes, not on a
## bridge or in a tunnel, long enough for the scene and END_ROOM at both ends, crossing a point
## AHEAD m from `from` towards `heading` (± SPREAD; anywhere round a still player): {e, lane, s0}
## (the scene's rear end at s0, its front at s0 + SPAN), or {} after `tries` misses. Static: the
## check runs it on the real lane graph.
static func pick_spot(g: LaneGraph, from: Vector2, heading: Vector2, rng: RandomNumberGenerator, tries := 24) -> Dictionary:
	for k in tries:
		var ang := rng.randf_range(-SPREAD, SPREAD) if heading != Vector2.ZERO else rng.randf_range(-PI, PI)
		var dir := (heading if heading != Vector2.ZERO else Vector2.UP).rotated(ang)
		var q := from + dir * rng.randf_range(AHEAD.x, AHEAD.y)
		var edges: PackedInt32Array = g.grid.get(LaneGraph.cell_key(q), PackedInt32Array())
		if edges.is_empty():
			continue
		# Every edge through the cell, from a random one on: the first that fits.
		var e := -1
		var k0 := rng.randi() % edges.size()
		for j in edges.size():
			if fits(g, edges[(k0 + j) % edges.size()]):
				e = edges[(k0 + j) % edges.size()]
				break
		if e < 0:
			continue
		var lo := g.e_s0[e] + END_ROOM
		var hi := g.e_s1[e] - END_ROOM - SPAN
		var s0 := clampf(g.project(e, q) - SPAN * 0.5, lo, hi)
		# The whole scene stays off the map's edge (lane_graph.gd `in_play`).
		if not g.in_play(g.point_at(e, s0)) or not g.in_play(g.point_at(e, s0 + SPAN)):
			continue
		return {"e": e, "lane": g.e_lanes[e] - 1, "s0": s0}
	return {}


## Edge e can hold a scene (pick_spot's rules).
static func fits(g: LaneGraph, e: int) -> bool:
	if g.e_class[e] > 1 or g.e_lanes[e] < 2 or g.e_tn[e] >= 0 or g.e_dk[e] >= 0 or g.e_bridge[e] != 0:
		return false
	return g.e_s1[e] - g.e_s0[e] >= SPAN + 2.0 * END_ROOM


## The scene's pieces at spot {e, lane, s0}: [what, position, yaw] for the four vehicles (what:
## "police", "hitter", "hit", "ambulance"; position on the road at s's height) and the people's
## [position (y 0: the caller puts it on the ground), yaw]. Static: the check reads it. `kind`
## "taxi": the taxi check's two vehicles ("police", "taxi") and its five people.
static func layout(g: LaneGraph, spot: Dictionary, kind := "crash") -> Dictionary:
	if kind == "taxi":
		return taxi_layout(g, spot)
	if kind == "tow":
		return tow_layout(g, spot)
	var e: int = spot["e"]
	var lane: int = spot["lane"]
	var s0: float = spot["s0"]
	var lo := g.lane_offset(e, lane)
	var cars: Array = []
	for row: Array in [["police", AT_POLICE, 0.0, 0.0], ["hitter", AT_HITTER, HITTER_TURN, HITTER_OFF],
			["hit", AT_HIT, HIT_TURN, HIT_OFF], ["ambulance", AT_AMBULANCE, 0.0, 0.35]]:
		var s: float = s0 + float(row[1])
		var p := g.point_at(e, s, lo + float(row[3]))
		var d := g.direction(e, s)
		cars.append([row[0], Vector3(p.x, g.height(e, s), p.y), atan2(-d.x, -d.y) + float(row[2])])
	# The people: the drivers face to face by the kerb between the wrecks, the officer by the
	# police car, the paramedic between the car that was hit and the ambulance, the onlookers on
	# the footway, turned to the road.
	var kerb := lo + g.e_lw[e] * 0.5
	var mid := s0 + (AT_HITTER + AT_HIT) * 0.5
	var people: Array = []
	for row: Array in [[mid - 0.7, kerb + 0.5, 1.0], [mid + 0.7, kerb + 0.5, -1.0], [s0 + AT_POLICE + 1.2, kerb + 0.7, 1.0],
			[s0 + AT_AMBULANCE - 4.1, lo + 0.6, -1.0], [s0 + AT_HITTER - 1.0, kerb + 2.4, 0.0],
			[mid + 1.4, kerb + 2.6, 0.0], [s0 + AT_HIT + 3.2, kerb + 2.3, 0.0]]:
		var s: float = row[0]
		var p := g.point_at(e, s, float(row[1]))
		var d := g.direction(e, s)
		var face := d * float(row[2]) if float(row[2]) != 0.0 else Vector2(d.y, -d.x)
		people.append([Vector3(p.x, 0.0, p.y), atan2(-face.x, -face.y)])
	var m := g.point_at(e, s0 + SPAN * 0.5, lo)
	return {"cars": cars, "people": people, "mid": m}


## The taxi check at spot {e, lane, s0}: the patrol car behind the taxi in the kerb lane, both
## straight (a pull-over, not a crash), the taxi a little towards the kerb. The officer stands at
## the taxi's driver window (the lane's traffic side, inside the lane: the queue goes round the
## whole scene), the second officer by the patrol car's kerb side, the driver out on the kerb by
## the taxi's front, the passenger and an onlooker on the footway.
static func taxi_layout(g: LaneGraph, spot: Dictionary) -> Dictionary:
	var e: int = spot["e"]
	var lane: int = spot["lane"]
	var s0: float = spot["s0"]
	var lo := g.lane_offset(e, lane)
	var cars: Array = []
	for row: Array in [["police", AT_TAXI_POLICE, 0.0], ["taxi", AT_TAXI, 0.3]]:
		var s: float = s0 + float(row[1])
		var p := g.point_at(e, s, lo + float(row[2]))
		var d := g.direction(e, s)
		cars.append([row[0], Vector3(p.x, g.height(e, s), p.y), atan2(-d.x, -d.y)])
	var kerb := lo + g.e_lw[e] * 0.5
	var people: Array = []
	# [s, metres right of the centreline, facing: 1 along, -1 back, 0 the road, 2 the kerb].
	for row: Array in [[s0 + AT_TAXI - 0.6, lo - 1.25, 2.0], [s0 + AT_TAXI_POLICE + 1.0, kerb + 0.6, 0.0],
			[s0 + AT_TAXI + 2.9, kerb + 0.5, -1.0], [s0 + AT_TAXI + 0.4, kerb + 2.3, 0.0],
			[s0 + AT_TAXI_POLICE - 1.5, kerb + 2.6, 0.0]]:
		var s: float = row[0]
		var p := g.point_at(e, s, float(row[1]))
		var d := g.direction(e, s)
		var face: Vector2
		match int(row[2]):
			1, -1:
				face = d * float(row[2])
			2:
				face = Vector2(-d.y, d.x)
			_:
				face = Vector2(d.y, -d.x)
		people.append([Vector3(p.x, 0.0, p.y), atan2(-face.x, -face.y)])
	var m := g.point_at(e, s0 + (AT_TAXI_POLICE + AT_TAXI) * 0.5, lo)
	return {"cars": cars, "people": people, "mid": m}


## The Odholowanie at spot {e, lane, s0}: the abandoned car half on the footway, the laweta
## ahead of it in the kerb lane on the lane's line (so it pulls straight out). The operator stands
## by the ramp tips on the traffic side, the guard on the footway by the car with the ticket, the
## owner running back along the footway from behind, an onlooker ahead.
static func tow_layout(g: LaneGraph, spot: Dictionary) -> Dictionary:
	var e: int = spot["e"]
	var lane: int = spot["lane"]
	var s0: float = spot["s0"]
	var lo := g.lane_offset(e, lane)
	var kerb := lo + g.e_lw[e] * 0.5
	var cars: Array = []
	var cs := s0 + AT_TOW_CAR
	var cp := g.point_at(e, cs, kerb + TOW_CAR_SIDE)
	var cd := g.direction(e, cs)
	cars.append(["car", Vector3(cp.x, g.height(e, cs) + TOW_CAR_UP, cp.y), atan2(-cd.x, -cd.y) + TOW_CAR_TURN])
	var ts := s0 + AT_TOW
	var tp := g.point_at(e, ts, lo)
	var td := g.direction(e, ts)
	cars.append(["tow", Vector3(tp.x, g.height(e, ts), tp.y), atan2(-td.x, -td.y)])
	var people: Array = []
	# [s, metres right of the centreline, facing: 1 along, -1 back, 0 the road, 2 the kerb].
	for row: Array in [[ts - 4.4, lo - 1.3, 2.0], [cs + 0.6, kerb + 1.7, 0.0], [cs - 5.5, kerb + 2.0, 1.0],
			[ts + 1.5, kerb + 2.6, 0.0]]:
		var s: float = row[0]
		var p := g.point_at(e, s, float(row[1]))
		var d := g.direction(e, s)
		var face: Vector2
		match int(row[2]):
			1, -1:
				face = d * float(row[2])
			2:
				face = Vector2(-d.y, d.x)
			_:
				face = Vector2(d.y, -d.x)
		people.append([Vector3(p.x, 0.0, p.y), atan2(-face.x, -face.y)])
	var m := g.point_at(e, s0 + (AT_TOW_CAR + AT_TOW) * 0.5, lo)
	return {"cars": cars, "people": people, "mid": m}


## Where the abandoned car is on its way onto the laweta at `tow` (its position and yaw), `f`
## from 0 (still at the kerb, `start`, `start_yaw`) to 1 (on the platform, as the loaded shape
## draws it): a slide in line behind the ramp tips, up to the platform's end, along it. Static:
## the check follows it.
static func load_path(start: Vector3, start_yaw: float, tow: Vector3, tow_yaw: float, f: float) -> Array:
	var b := Basis(Vector3.UP, tow_yaw)
	var foot := tow + b * TOW_FOOT
	var lip := tow + b * TOW_LIP
	var on := tow + b * Models.TOW_LOAD_AT
	f = clampf(f, 0.0, 1.0)
	if f < 0.3:
		var k := smoothstep(0.0, 1.0, f / 0.3)
		return [start.lerp(foot, k), lerp_angle(start_yaw, tow_yaw, k)]
	if f < 0.65:
		return [foot.lerp(lip, (f - 0.3) / 0.35), tow_yaw]
	return [lip.lerp(on, smoothstep(0.0, 1.0, (f - 0.65) / 0.35)), tow_yaw]


## The people of a scene of `kind` ("crash", "taxi" or "tow").
static func people_of(kind: String) -> Array:
	match kind:
		"taxi":
			return TAXI_PEOPLE
		"tow":
			return TOW_PEOPLE
	return PEOPLE


## Makes a scene near `from` (out of sight; `near`: for a test's shot, 45-80 m ahead and maybe in
## view; `at`: for a shot, on the fitting road nearest that point). True if one was placed.
func place(from: Vector2, heading: Vector2, near: bool, at := Vector2.INF, kind := "") -> bool:
	if not scene.is_empty():
		clear()
	if kind == "":
		var r := _rng.randf()
		kind = "taxi" if r < taxi_share else "tow" if r < taxi_share + tow_share else "crash"
	var spot := {}
	for attempt in 6:
		if at != Vector2.INF:
			spot = _spot_at(at)
		else:
			spot = _near_spot(from, heading) if near else pick_spot(graph, from, heading, _rng)
		if spot.is_empty():
			continue
		var e: int = spot["e"]
		var lane: int = spot["lane"]
		var s0: float = spot["s0"]
		if not traffic.lane_free(e, lane, s0, s0 + SPAN, 10.0):
			spot = {}
			continue
		var lay := layout(graph, spot, kind)
		var hidden := true
		for c: Array in lay["cars"]:
			if traffic.on_screen(c[1], 2.6):
				hidden = false
		if not hidden and not near:
			spot = {}
			continue
		spot["lay"] = lay
		break
	if spot.is_empty():
		return false
	var lay: Dictionary = spot["lay"]
	var e: int = spot["e"]
	var lane: int = spot["lane"]
	var s0: float = spot["s0"]
	var drivers: Array = []
	var paints: Array = Models.TRAFFIC[0][0]["paint"]
	var at_s: Dictionary = {"police": AT_TAXI_POLICE, "taxi": AT_TAXI, "car": AT_TOW_CAR, "tow": AT_TOW,
			"hitter": AT_HITTER, "hit": AT_HIT, "ambulance": AT_AMBULANCE}
	at_s["police"] = AT_TAXI_POLICE if kind == "taxi" else AT_POLICE
	for c: Array in lay["cars"]:
		var s: float = s0 + float(at_s[c[0]])
		var d = null
		if c[0] == "taxi":
			# A city taxi or a Podwózka (models.gd TAXI_CITY, TAXI_APP) in its own paints.
			var shape := _rng.randi() % 2
			var tp: Array = Models.TRAFFIC[1][shape]["paint"]
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, shape, Color(tp[_rng.randi() % tp.size()]), 1)
		elif c[0] == "car":
			# The abandoned car: the hatch in the paint the loaded laweta's car is drawn in.
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, 0, Models.TOW_LOAD_PAINT)
		elif c[0] == "tow":
			var tw: Array = Models.TRAFFIC[2][Models.VAN_TOW]["paint"]
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, Models.VAN_TOW, Color(tw[_rng.randi() % tw.size()]), 2)
		elif c[0] in ["hitter", "hit"]:
			var paint := Color(paints[_rng.randi() % paints.size()])
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, _rng.randi() % WRECK_SHAPES, paint)
		elif police != null:
			d = police.scene_car(e, lane, s, c[1], c[2], 0 if c[0] == "police" else 2)
		if d == null and c[0] in ["hitter", "hit", "taxi", "car", "tow"]:
			for o in drivers:
				_drop(o)
			return false
		if d != null:
			drivers.append(d)
	var who := people_of(kind)
	if walkers != null:
		for i in who.size():
			var p: Vector3 = lay["people"][i][0]
			p.y = map.ground_height(p.x, p.z) if map != null else 0.0
			walkers.set_scene(i, p, lay["people"][i][1], Color(who[i][1]), float(who[i][2]))
	var street := graph.e_name[e]
	scene = {"e": e, "lane": lane, "s0": s0, "mid": lay["mid"], "drivers": drivers, "people": lay["people"],
			"age": 0.0, "life": _rng.randf_range(LIFE.x, LIFE.y), "talk": 0.6, "turn": 0, "street": street, "kind": kind}
	placed += 1
	var m: Vector2 = lay["mid"]
	_log("scene %d (%s) at %d,%d (%s, lane %d of %d, %d vehicles, %.0f m away, lives %.0f s)" % [placed, kind, roundi(m.x), roundi(m.y),
			street if street != "" else "a nameless road", lane, graph.e_lanes[e], drivers.size(), from.distance_to(m), scene["life"]])
	_announce(street, {"taxi": TAXI_RADIO_TAG, "tow": TOW_RADIO_TAG}.get(kind, RADIO_TAG))
	return true


## A test's spot: the first fitting edge crossing 45-80 m ahead (the car's lane graph near it).
func _near_spot(from: Vector2, heading: Vector2) -> Dictionary:
	var dir := heading if heading != Vector2.ZERO else Vector2.UP
	var best := {}
	var best_d := INF
	for dist: float in [45.0, 60.0, 80.0, 100.0, 130.0]:
		for ang: float in [0.0, -0.4, 0.4, -0.9, 0.9]:
			var q := from + dir.rotated(ang) * dist
			for e in graph.grid.get(LaneGraph.cell_key(q), PackedInt32Array()):
				if not fits(graph, e):
					continue
				var s := clampf(graph.project(e, q) - SPAN * 0.5, graph.e_s0[e] + END_ROOM, graph.e_s1[e] - END_ROOM - SPAN)
				var m := graph.point_at(e, s + SPAN * 0.5)
				var far := m.distance_to(from)
				var dd := absf(far - 60.0)
				if far > 35.0 and dd < best_d:
					best_d = dd
					best = {"e": e, "lane": graph.e_lanes[e] - 1, "s0": s}
		if not best.is_empty():
			return best
	return best


## A shot's spot: the fitting edge passing nearest `p` (within a cell round it), the scene's
## middle by p.
func _spot_at(p: Vector2) -> Dictionary:
	var best := {}
	var best_d := INF
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			for e in graph.grid.get(LaneGraph.cell_key(p + Vector2(dx, dz) * LaneGraph.CELL), PackedInt32Array()):
				if not fits(graph, e):
					continue
				var s := clampf(graph.project(e, p) - SPAN * 0.5, graph.e_s0[e] + END_ROOM, graph.e_s1[e] - END_ROOM - SPAN)
				var dd := graph.point_at(e, s + SPAN * 0.5, graph.lane_offset(e, graph.e_lanes[e] - 1)).distance_to(p)
				if dd < best_d:
					best_d = dd
					best = {"e": e, "lane": graph.e_lanes[e] - 1, "s0": s}
	return best


## The scene now in view (any of its vehicles or its middle)?
func seen() -> bool:
	if scene.is_empty():
		return false
	for d in scene["drivers"]:
		if d.active and traffic.on_screen(d.pos, d.size.y):
			return true
	var m: Vector2 = scene["mid"]
	return traffic.on_screen(Vector3(m.x, graph.height(int(scene["e"]), float(scene["s0"]) + SPAN * 0.5), m.y), 2.0)


## Tells the minimap and the sound where the scene is (the siren stops when the scene is over).
func _report(over: bool) -> void:
	var m: Vector2 = scene["mid"]
	if hud != null:
		hud.set_scene_mark(m)
	if sfx != null:
		if over or scene.get("kind", "crash") != "crash":
			sfx.scene_siren(Vector3.INF)
		else:
			var amb = scene["drivers"][-1] if not scene["drivers"].is_empty() else null
			sfx.scene_siren(amb.pos if amb != null else Vector3(m.x, 1.5, m.y))


## Takes the scene away (its vehicles back to their pools, its people gone).
func clear() -> void:
	if scene.is_empty():
		return
	if hud != null:
		hud.set_scene_mark(Vector2.INF)
	if sfx != null:
		sfx.scene_siren(Vector3.INF)
	for d in scene["drivers"]:
		_drop(d)
	var who := people_of(scene.get("kind", "crash"))
	if walkers != null:
		for i in who.size():
			walkers.clear_scene(i)
	if dialogue != null and dialogue.bubbles != null:
		for i in who.size():
			dialogue.bubbles.hush(_anchor(i))
	cleared += 1
	_log("scene cleared after %.0f s" % float(scene["age"]))
	scene = {}


## The Odholowanie's timeline, each tick: the lift starts when the player comes within
## TALK_REACH m (on foot or driving; not flying over), and TOW_LEAVE s after the car is on the
## platform the laweta pulls out into its lane and drives on as ordinary traffic.
func _tow_step(dt: float, dist: float) -> void:
	var stage: int = scene.get("tow_stage", 0)
	if stage == 0 and dist < TALK_REACH and float(scene["age"]) > 2.0:
		_start_load()
	elif stage == 2:
		scene["tow_wait"] = float(scene["tow_wait"]) - dt
		if float(scene["tow_wait"]) <= 0.0:
			_tow_leave()


func _start_load() -> void:
	var car = scene["drivers"][0] if scene["drivers"].size() == 2 else null
	if car == null:
		scene["tow_stage"] = 3
		return
	scene["tow_stage"] = 1
	scene["load_t"] = 0.0
	scene["load_from"] = [car.pos, car.yaw]
	_log("the laweta starts loading")


## The lift, every frame while it runs: the car moves along load_path; at the end it leaves the
## CAR pool and the laweta becomes the loaded shape.
func _load_step(dt: float) -> void:
	var car = scene["drivers"][0]
	var tow = scene["drivers"][1]
	scene["load_t"] = float(scene["load_t"]) + dt
	var f := float(scene["load_t"]) / TOW_LOAD_TIME
	var from: Array = scene["load_from"]
	var at := load_path(from[0], from[1], tow.pos, tow.yaw, f)
	car.pos = at[0]
	car.yaw = at[1]
	if f < 1.0:
		return
	traffic.drop_parked(car)
	scene["drivers"].remove_at(0)
	tow.shape = Models.VAN_TOW_LOADED
	tow.size = Models.TRAFFIC[2][Models.VAN_TOW_LOADED]["size"]
	scene.erase("load_t")
	scene["tow_stage"] = 2
	scene["tow_wait"] = TOW_LEAVE
	_log("the car is on the laweta")


## The loaded laweta pulls out and joins the traffic (no longer the scene's: the traffic takes it
## back to the pool when it is far and out of sight, like any van).
func _tow_leave() -> void:
	var tow = scene["drivers"][-1]
	scene["tow_stage"] = 3
	scene["drivers"].erase(tow)
	traffic.unpark(tow, int(scene["e"]), int(scene["lane"]), float(scene["s0"]) + AT_TOW)
	tow.persistent = false
	towed += 1
	_log("the laweta drives off")


func _drop(d) -> void:
	if d == null:
		return
	if d.kind == 4 and police != null:
		police.scene_leave(d)  # the police car, the ambulance (traffic.gd Kind.POLICE)
	else:
		traffic.drop_parked(d)


## The next person in TURNS says a line of theirs (dialogue.json `crash_scene`).
func _talk() -> void:
	scene["talk"] = _rng.randf_range(TALK_GAP.x, TALK_GAP.y)
	if dialogue == null:
		return
	var turn: int = scene["turn"]
	scene["turn"] = turn + 1
	var kind: String = scene.get("kind", "crash")
	var turns: Array = {"taxi": TAXI_TURNS, "tow": TOW_TURNS}.get(kind, TURNS)
	var i: int = turns[turn % turns.size()]
	var tag: String = people_of(kind)[i][0]
	var l: Array = dialogue.say_ambient(_anchor(i), "", {"taxi": TAXI_LINES, "tow": TOW_LINES}.get(kind, LINES), tag, 3.4,
			{"taxi": TAXI_BUBBLE, "tow": TOW_BUBBLE}.get(kind, BUBBLE), 1.9, true)
	if not l.is_empty():
		_log("%s: %s" % [tag, l[0]])


## Person i's anchor: a callable giving their head (one per person, so a new line replaces theirs).
func _anchor(i: int) -> Callable:
	var key := "anchor_%d" % i
	if not scene.has(key):
		var p: Vector3 = scene["people"][i][0]
		var y: float = map.ground_height(p.x, p.z) if map != null else 0.0
		var at := Vector3(p.x, y, p.z)
		scene[key] = func() -> Vector3: return at
	return scene[key]


## KEBAB FM's host reads the scene out (radio_host lines tagged `tag`: "crash", or "taxi_check"
## for a taxi check; {street} is the road's name, "this street" without one).
func _announce(street: String, tag := RADIO_TAG) -> void:
	if radio == null or dialogue == null or radio.station < 0:
		return
	var l: Array = dialogue.line(RADIO_GROUP, tag, true)
	if l.is_empty() or dialogue.notes(l).get("only", "") != tag:
		return
	var pl := street if street != "" else "Ulica bez nazwy"
	var en := street if street != "" else "A street with no name"
	radio.announce(String(l[0]).replace("{street}", pl), String(l[1]).replace("{street}", en))
	_log("radio: %s" % String(l[0]).replace("{street}", pl))


func _log(text: String) -> void:
	if log_on:
		print("crash: %s (%.1f s)" % [text, _clock])
