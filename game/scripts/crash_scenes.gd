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
## of them are a taxi check (kontrola taksówki): a city taxi or a Łuber stopped in the kerb lane
## (traffic.gd add_parked_car, kind TAXI: +0 draw calls), the patrol car behind it with its lights
## on, an officer at the driver's window with the papers, a second by the patrol car, the driver
## out on the kerb explaining, the passenger on the footway late for the airport and an onlooker
## (dialogue.json `taxi_check`, KEBAB FM's `radio_host` tag "taxi_check"). No ambulance and no
## siren at a taxi check. No new scene while `hushed` says so (road_life.gd: a race, a chase, the
## first minutes' guide), so a race or the guide's drive never meets one.
##
## Road life stage 3, "Pan wolny?!": at HAIL_SHARE of the taxi checks, when the player comes past
## slowly (under HAIL_SPEED m/s, within HAIL_REACH m of the passenger), the passenger waves them
## down ("hail" in `taxi_check`) and Łuber offers their ride from right there (rides.gd
## `offer_stranded`, through `stranded`); once it is taken the passenger leaves the scene (the
## ride's own figure waits there).
##
## Road life stage 2: TOW_SHARE of scenes are an "Odholowanie": a car left half on the pavement
## (the CAR pool's hatch in Models.TOW_LOAD_PAINT), a laweta stopped in the kerb lane ahead of it
## (the VAN pool's shape Models.VAN_TOW: +0 draw calls), its operator at the platform, a city guard
## writing it up and the owner running back in a bathrobe with a Frogs bag ("Byłem pięć minut!";
## dialogue.json `tow_scene`, KEBAB FM's "tow"). When the player comes within TALK_REACH m the car
## is pulled up onto the platform over TOW_LOAD_TIME s (moved frame by frame, `_load_step`) and
## the laweta takes its place as the loaded shape (Models.VAN_TOW_LOADED, the car drawn where the
## lifted one ended: no jump), then after TOW_LEAVE s it pulls out and drives off with the traffic.
## Stage 3: WRECK_TOW_SHARE of the fender benders ("crash_tow") have a laweta where the ambulance
## would stand, its operator in the paramedic's place; the car that was hit (then the hatch in
## TOW_LOAD_PAINT) is pulled onto it the same way, and the laweta takes the wreck away.
##
## Road life (2026-11-26, F's Thursday list): two more kinds.
## **Dostawczak na awaryjnych** ("delivery", DELIVERY_SHARE): a courier's van (the VAN pool's panel
## or box van) stands in the kerb lane on its hazard lights (traffic.gd Driver.hazard, models.gd's
## corner lamps: +0 draw calls), the courier at its back doors with a parcel, the customer on the
## footway ("Tylko na chwilkę!", dialogue.json `delivery_scene`). The player's horn near it gets an
## answer (`honk`). After DELIVERY_STAY s the courier gets in, the hazards go off and the van pulls
## out into the traffic.
## **Kontrola trzeźwości** ("sober", night only, SOBER_HOURS; once a session): a patrol car with its
## lights on in the kerb lane, a car pulled in behind it with an officer and the breathalyser at its
## window, a second officer standing at the lane's edge waving cars in (`sober_check`). The player
## who comes by in that lane or the next is waved in (a toast); stopping by the officer is a breath
## test ("Dmuchamy!"), 0,00 is +2 respect ("Szerokości!"), after THE TAPCZAN (tipsy.gd `amount`,
## through `tipsy`) a fine and a floored respect loss; driving on past the officer costs 3 respect
## (road_rules.gd; F 2026-11-23: no chase).

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Models := preload("res://scripts/models.gd")
const Rules := preload("res://scripts/road_rules.gd")
const Messages := preload("res://scripts/messages.gd")

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
## "Pan wolny?!": the share of taxi checks whose passenger hails the player, how near and how slow
## the car must come, and the passenger's index in TAXI_PEOPLE.
const HAIL_SHARE := 0.6
const HAIL_REACH := 16.0
const HAIL_SPEED := 4.5
const PASSENGER := 3
## The share of scenes that are an Odholowanie (a tow).
const TOW_SHARE := 0.25
## Road life (2026-11-26): the dostawczak's share of scenes, where its van stands from the scene's
## rear (m), how long it stays (s), its people (the courier, the customer), their turns, lines and
## bubble colour, and the gap between the courier's answers to a horn (s) and how near it is heard.
const DELIVERY_SHARE := 0.15
const AT_VAN := 10.0
const DELIVERY_STAY := Vector2(40.0, 70.0)
const DELIVERY_PEOPLE := [["courier", "#c8452c", 0.1], ["customer", "#7fa7c9", 0.6]]
const DELIVERY_TURNS := [0, 1, 0, 0, 1]
const DELIVERY_LINES := "delivery_scene"
const DELIVERY_BUBBLE := Color("#ffb347")
const HONK_REPLY_GAP := 5.0
const HONK_REACH := 35.0
## Kontrola trzeźwości: its share of the scenes at night (SOBER_HOURS: from x in the evening to y
## in the morning), where the checked car, the patrol car and the waving officer stand (m from the
## scene's rear), its people (the officer at the window, the one waving), turns, lines, bubble
## colour, the breath test's seconds and the fine (zł) when it is not 0,00.
const SOBER_SHARE := 0.4
const SOBER_HOURS := Vector2(21.0, 5.0)
const AT_SOBER_POLICE := 17.0
const AT_SOBER_CAR := 10.0
const AT_SOBER_WAVE := 4.0
const SOBER_PEOPLE := [["officer", "#e8f23a", 0.1], ["waver", "#e8f23a", 0.1]]
const SOBER_TURNS := [0, 1, 0, 1, 1]
const SOBER_LINES := "sober_check"
const SOBER_RADIO_TAG := "sober"
const SOBER_BLOW := 2.2
const SOBER_FINE := 500
## The share of fender benders where a laweta takes the wreck away (no ambulance), and where it
## stands along the lane (its middle: its rear 3.1 m ahead of the hit car's front).
const WRECK_TOW_SHARE := 0.5
const AT_WRECK_TOW := 22.2
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
## The share of fender benders with a laweta (WRECK_TOW_SHARE; a check sets 0 or 1).
var wreck_tow_share := WRECK_TOW_SHARE
## Odholowanie: lawetas that loaded a car and left (the checks, the log).
var towed := 0
## "Pan wolny?!": the passenger's ride offered at a point (rides.gd offer_stranded: true if its
## card is up), and whether that ride was taken (rides.gd stranded_on); empty: no hails.
var stranded: Callable
var stranded_on: Callable
## The share of taxi checks whose passenger hails (HAIL_SHARE; a check sets 0 or 1), and the
## hails made and rides offered (the checks, the log).
var hail_share := HAIL_SHARE
var hails := 0
var hail_offers := 0
var _hail_rng := RandomNumberGenerator.new()
## Road life (2026-11-26): the dostawczak's and the sobriety check's shares (a check sets 0 or 1);
## the wallet (respect, the fine), the hour now (0-24; empty: noon) and how tipsy the player is
## (tipsy.gd `amount`, 0..1; empty: sober); the counts (the log, check_crash_scenes).
var delivery_share := DELIVERY_SHARE
var sober_share := SOBER_SHARE
var wallet: Node
var hour: Callable
var tipsy: Callable
var sobers := 0
var sober_tests := 0
var sober_passed := 0
var sober_fines := 0
var deliveries := 0
var honk_replies := 0

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


## The kinds a test flag may ask for (--crash=KIND, --crash=KIND,X,Z).
const KINDS := ["taxi", "tow", "delivery", "sober"]


## Copies what it needs from the ctx (game_ctx.gd), as road_life.gd does: the traffic and its
## graph, the map, the words, the police, the radio, the sound, the HUD, the wallet, the clock,
## the view's focus, the player's vehicle and the test flags (--crash=..., --crash-log). main.gd
## adds the walkers and the callables to other systems.
func install(ctx) -> void:
	traffic = ctx.traffic
	graph = ctx.graph
	map = ctx.map
	dialogue = ctx.dialogue
	police = ctx.police
	radio = ctx.radio
	sfx = ctx.sfx
	hud = ctx.hud
	wallet = ctx.wallet
	hour = ctx.hour
	focus = ctx.focus
	vehicle = ctx.vehicle
	var f = ctx.flags
	if f != null:
		log_on = f.crash_log
		enabled = f._crash_auto or f.crash_flag != ""


## --crash=now, =KIND, =X,Z or =KIND,X,Z (dev_flags.gd): a scene (of that kind) ahead of the car
## now (`from`, `heading`; it may be in view), or on the fitting road nearest X,Z.
func test_flag(flag: String, from: Vector2, heading: Vector2) -> void:
	var xz := flag.split(",")
	var kind: String = xz[0] if xz[0] in KINDS else ""
	if kind != "" and xz.size() == 3:
		xz = xz.slice(1)
	if flag == "now" or kind == flag or xz.size() == 2:
		place(from, heading, true, Vector2(float(xz[0]), float(xz[1])) if xz.size() == 2 else Vector2.INF, kind)


func setup(seed_value := -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
		_hail_rng.seed = seed_value + 73
	else:
		_rng.randomize()
		_hail_rng.randomize()
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
	if scene.has("tow_truck"):
		_tow_step(dt, dist)
	if scene.has("hail"):
		_hail_step(v)
	if scene.has("van"):
		_delivery_step()
	if scene.has("sober"):
		_sober_step(dt, v)
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
	if kind == "delivery":
		return delivery_layout(g, spot)
	if kind == "sober":
		return sober_layout(g, spot)
	var e: int = spot["e"]
	var lane: int = spot["lane"]
	var s0: float = spot["s0"]
	var lo := g.lane_offset(e, lane)
	var cars: Array = []
	var last: Array = ["tow", AT_WRECK_TOW, 0.0, 0.0] if kind == "crash_tow" else ["ambulance", AT_AMBULANCE, 0.0, 0.35]
	for row: Array in [["police", AT_POLICE, 0.0, 0.0], ["hitter", AT_HITTER, HITTER_TURN, HITTER_OFF],
			["hit", AT_HIT, HIT_TURN, HIT_OFF], last]:
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


## The hour `h` (0-24) is the sobriety checks' (SOBER_HOURS, over midnight).
static func is_night(h: float) -> bool:
	return h >= SOBER_HOURS.x or h < SOBER_HOURS.y


## People at [s, metres right of the centreline, facing: 1 along, -1 back, 0 the road, 2 the kerb]
## on edge e: [position (y 0), yaw] each.
static func _stand(g: LaneGraph, e: int, rows: Array) -> Array:
	var people: Array = []
	for row: Array in rows:
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
	return people


## The dostawczak at spot {e, lane, s0}: the van in the kerb lane, a little towards the kerb; the
## courier at its back doors on the kerb side, turned to the footway, the customer on the footway.
static func delivery_layout(g: LaneGraph, spot: Dictionary) -> Dictionary:
	var e: int = spot["e"]
	var lane: int = spot["lane"]
	var s0: float = spot["s0"]
	var lo := g.lane_offset(e, lane)
	var s := s0 + AT_VAN
	var p := g.point_at(e, s, lo + 0.3)
	var d := g.direction(e, s)
	var kerb := lo + g.e_lw[e] * 0.5
	var people := _stand(g, e, [[s - 3.4, kerb - 0.1, 2.0], [s - 3.1, kerb + 1.6, 0.0]])
	return {"cars": [["van", Vector3(p.x, g.height(e, s), p.y), atan2(-d.x, -d.y)]], "people": people,
			"mid": g.point_at(e, s, lo)}


## The sobriety check at spot {e, lane, s0}: the checked car pulled in behind the patrol car in the
## kerb lane, both straight; the officer with the breathalyser at the car's driver window (the
## lane's traffic side), the one waving cars in at the lane's traffic edge behind it, facing the
## traffic. `wave` is where the waving officer stands (the rules' mark).
static func sober_layout(g: LaneGraph, spot: Dictionary) -> Dictionary:
	var e: int = spot["e"]
	var lane: int = spot["lane"]
	var s0: float = spot["s0"]
	var lo := g.lane_offset(e, lane)
	var cars: Array = []
	for row: Array in [["checked", AT_SOBER_CAR, 0.3], ["police", AT_SOBER_POLICE, 0.2]]:
		var s: float = s0 + float(row[1])
		var p := g.point_at(e, s, lo + float(row[2]))
		var d := g.direction(e, s)
		cars.append([row[0], Vector3(p.x, g.height(e, s), p.y), atan2(-d.x, -d.y)])
	var people := _stand(g, e, [[s0 + AT_SOBER_CAR - 0.5, lo - 1.25, 2.0], [s0 + AT_SOBER_WAVE, lo - 0.9, -1.0]])
	var w := g.point_at(e, s0 + AT_SOBER_WAVE, lo - 0.9)
	return {"cars": cars, "people": people, "mid": g.point_at(e, s0 + AT_SOBER_CAR, lo), "wave": w}


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


## The people of a scene of `kind` ("crash", "crash_tow", "taxi" or "tow"); at a crash_tow the
## laweta's operator stands in the paramedic's place.
static func people_of(kind: String) -> Array:
	match kind:
		"taxi":
			return TAXI_PEOPLE
		"tow":
			return TOW_PEOPLE
		"delivery":
			return DELIVERY_PEOPLE
		"sober":
			return SOBER_PEOPLE
		"crash_tow":
			var out := PEOPLE.duplicate()
			out[3] = TOW_PEOPLE[0]
			return out
	return PEOPLE


## Makes a scene near `from` (out of sight; `near`: for a test's shot, 45-80 m ahead and maybe in
## view; `at`: for a shot, on the fitting road nearest that point). True if one was placed.
func place(from: Vector2, heading: Vector2, near: bool, at := Vector2.INF, kind := "") -> bool:
	if not scene.is_empty():
		clear()
	if kind == "":
		var r := _rng.randf()
		kind = "taxi" if r < taxi_share else "tow" if r < taxi_share + tow_share else \
				"delivery" if r < taxi_share + tow_share + delivery_share else "crash"
		if kind == "crash" and _rng.randf() < wreck_tow_share:
			kind = "crash_tow"
		# Road life: at night, now and then a sobriety check instead (once a session).
		if sobers == 0 and is_night(float(hour.call()) if hour.is_valid() else 12.0) and _rng.randf() < sober_share:
			kind = "sober"
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
			"hitter": AT_HITTER, "hit": AT_HIT, "ambulance": AT_AMBULANCE, "van": AT_VAN, "checked": AT_SOBER_CAR}
	at_s["police"] = AT_TAXI_POLICE if kind == "taxi" else AT_SOBER_POLICE if kind == "sober" else AT_POLICE
	if kind == "crash_tow":
		at_s["tow"] = AT_WRECK_TOW
	for c: Array in lay["cars"]:
		var s: float = s0 + float(at_s[c[0]])
		var d = null
		if c[0] == "taxi":
			# A city taxi or a Łuber (models.gd TAXI_CITY, TAXI_APP) in its own paints.
			var shape := _rng.randi() % 2
			var tp: Array = Models.TRAFFIC[1][shape]["paint"]
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, shape, Color(tp[_rng.randi() % tp.size()]), 1)
		elif c[0] == "car":
			# The abandoned car: the hatch in the paint the loaded laweta's car is drawn in.
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, 0, Models.TOW_LOAD_PAINT)
		elif c[0] == "tow":
			var tw: Array = Models.TRAFFIC[2][Models.VAN_TOW]["paint"]
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, Models.VAN_TOW, Color(tw[_rng.randi() % tw.size()]), 2)
		elif c[0] == "van":
			# The dostawczak: the panel or the box van in its own paints, on its hazard lights.
			var shape := _rng.randi() % 2
			var vp: Array = Models.TRAFFIC[2][shape]["paint"]
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, shape, Color(vp[_rng.randi() % vp.size()]), 2)
			if d != null:
				d.hazard = true
		elif c[0] == "checked":
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, _rng.randi() % WRECK_SHAPES, Color(paints[_rng.randi() % paints.size()]))
		elif c[0] == "hit" and kind == "crash_tow":
			# The wreck the laweta takes: the hatch in the loaded laweta's car paint.
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, 0, Models.TOW_LOAD_PAINT)
		elif c[0] in ["hitter", "hit"]:
			var paint := Color(paints[_rng.randi() % paints.size()])
			d = traffic.add_parked_car(e, s, c[1], c[2], lane, _rng.randi() % WRECK_SHAPES, paint)
		elif police != null:
			d = police.scene_car(e, lane, s, c[1], c[2], 0 if c[0] == "police" else 2)
		if d == null and c[0] in ["hitter", "hit", "taxi", "car", "tow", "van", "checked"]:
			for o in drivers:
				_drop(o)
			return false
		if d != null:
			drivers.append(d)
	var who := people_of(kind)
	var load_car = null
	var tow_truck = null
	if kind in ["tow", "crash_tow"]:
		load_car = drivers[0] if kind == "tow" else drivers[drivers.size() - 2]
		tow_truck = drivers[drivers.size() - 1]
	if walkers != null:
		for i in who.size():
			var p: Vector3 = lay["people"][i][0]
			p.y = map.ground_height(p.x, p.z) if map != null else 0.0
			walkers.set_scene(i, p, lay["people"][i][1], Color(who[i][1]), float(who[i][2]))
	var street := graph.e_name[e]
	scene = {"e": e, "lane": lane, "s0": s0, "mid": lay["mid"], "drivers": drivers, "people": lay["people"],
			"age": 0.0, "life": _rng.randf_range(LIFE.x, LIFE.y), "talk": 0.6, "turn": 0, "street": street, "kind": kind}
	if kind == "taxi" and stranded.is_valid() and _hail_rng.randf() < hail_share:
		scene["hail"] = true
	if kind == "delivery":
		scene["van"] = drivers[0]
		scene["stay"] = _rng.randf_range(DELIVERY_STAY.x, DELIVERY_STAY.y)
		scene["life"] = maxf(float(scene["life"]), float(scene["stay"]) + 30.0)
		deliveries += 1
	elif kind == "sober":
		scene["wave"] = lay["wave"]
		scene["sober"] = 0  # 0 not met, 1 waved in, 2 blowing, 3 done
		sobers += 1
	if tow_truck != null:
		scene["tow_car"] = load_car
		scene["tow_truck"] = tow_truck
		scene["tow_at"] = s0 + float(at_s["tow"])
	placed += 1
	var m: Vector2 = lay["mid"]
	_log("scene %d (%s) at %d,%d (%s, lane %d of %d, %d vehicles, %.0f m away, lives %.0f s)" % [placed, kind, roundi(m.x), roundi(m.y),
			street if street != "" else "a nameless road", lane, graph.e_lanes[e], drivers.size(), from.distance_to(m), scene["life"]])
	if kind != "delivery":
		_announce(street, {"taxi": TAXI_RADIO_TAG, "tow": TOW_RADIO_TAG, "sober": SOBER_RADIO_TAG}.get(kind, RADIO_TAG))
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
	var car = scene["tow_car"]
	if car == null or not car.active:
		scene["tow_stage"] = 3
		return
	scene["tow_stage"] = 1
	scene["load_t"] = 0.0
	scene["load_from"] = [car.pos, car.yaw]
	_log("the laweta starts loading")


## The lift, every frame while it runs: the car moves along load_path; at the end it leaves the
## CAR pool and the laweta becomes the loaded shape.
func _load_step(dt: float) -> void:
	var car = scene["tow_car"]
	var tow = scene["tow_truck"]
	scene["load_t"] = float(scene["load_t"]) + dt
	var f := float(scene["load_t"]) / TOW_LOAD_TIME
	var from: Array = scene["load_from"]
	var at := load_path(from[0], from[1], tow.pos, tow.yaw, f)
	car.pos = at[0]
	car.yaw = at[1]
	if f < 1.0:
		return
	traffic.drop_parked(car)
	scene["drivers"].erase(car)
	scene["tow_car"] = null
	tow.shape = Models.VAN_TOW_LOADED
	tow.size = Models.TRAFFIC[2][Models.VAN_TOW_LOADED]["size"]
	scene.erase("load_t")
	scene["tow_stage"] = 2
	scene["tow_wait"] = TOW_LEAVE
	_log("the car is on the laweta")


## The loaded laweta pulls out and joins the traffic (no longer the scene's: the traffic takes it
## back to the pool when it is far and out of sight, like any van).
func _tow_leave() -> void:
	var tow = scene["tow_truck"]
	scene["tow_stage"] = 3
	scene["drivers"].erase(tow)
	traffic.unpark(tow, int(scene["e"]), int(scene["lane"]), float(scene["tow_at"]))
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
	var turns: Array = {"taxi": TAXI_TURNS, "tow": TOW_TURNS, "delivery": DELIVERY_TURNS, "sober": SOBER_TURNS}.get(kind, TURNS)
	var i: int = turns[turn % turns.size()]
	if i == PASSENGER and kind == "taxi" and bool(scene.get("gone", false)):
		return  # the passenger left in the player's car
	if kind == "delivery" and i == 0 and scene.get("van") == null:
		return  # the courier drove off
	if kind == "sober" and int(scene.get("sober", 0)) in [1, 2]:
		return  # the officers are busy with the player
	var tag: String = people_of(kind)[i][0]
	var group: String = {"taxi": TAXI_LINES, "tow": TOW_LINES, "delivery": DELIVERY_LINES, "sober": SOBER_LINES}.get(kind,
			TOW_LINES if tag == "operator" else LINES)
	var l: Array = dialogue.say_ambient(_anchor(i), "", group, tag, 3.4, _bubble(kind), 1.9, true)
	if not l.is_empty():
		_log("%s: %s" % [tag, l[0]])


## "Pan wolny?!": the player's car comes past slowly near the passenger: they wave it down and
## Łuber offers the ride; once it is taken the passenger leaves the scene.
func _hail_step(v: Array) -> void:
	if bool(scene.get("gone", false)):
		return
	if bool(scene.get("hailed", false)):
		if stranded_on.is_valid() and bool(stranded_on.call()):
			scene["gone"] = true
			if walkers != null:
				walkers.clear_scene(PASSENGER)
			if dialogue != null:
				dialogue.say_ambient(_anchor(PASSENGER), "", TAXI_LINES, "hail_thanks", 3.4, TAXI_BUBBLE, 1.9, true)
			_log("the passenger took the player's ride")
		return
	if bool(v[2]) or float(v[1]) / 3.6 > HAIL_SPEED:
		return
	var p: Vector3 = scene["people"][PASSENGER][0]
	var me: Vector3 = v[0]
	if Vector2(p.x, p.z).distance_to(Vector2(me.x, me.z)) > HAIL_REACH:
		return
	scene["hailed"] = true
	hails += 1
	if dialogue != null:
		dialogue.say_ambient(_anchor(PASSENGER), "", TAXI_LINES, "hail", 3.4, TAXI_BUBBLE, 2.4, true)
	if bool(stranded.call(Vector2(p.x, p.z))):
		hail_offers += 1
		scene["talk"] = maxf(float(scene["talk"]), 4.0)  # the card's turn: the others hush a moment
		_log("the passenger hailed the player: a ride offered")
	else:
		_log("the passenger hailed the player: busy, no ride")


## The bubble colour of a scene of `kind`.
static func _bubble(kind: String) -> Color:
	return {"taxi": TAXI_BUBBLE, "tow": TOW_BUBBLE, "delivery": DELIVERY_BUBBLE, "sober": TAXI_BUBBLE}.get(kind, BUBBLE)


## A line of `tag` from the scene's person i (its own group and bubble).
func _say(i: int, tag: String) -> void:
	if dialogue == null:
		return
	var kind: String = scene.get("kind", "crash")
	var group: String = {"delivery": DELIVERY_LINES, "sober": SOBER_LINES}.get(kind, LINES)
	var l: Array = dialogue.say_ambient(_anchor(i), "", group, tag, 3.4, _bubble(kind), 2.4, true)
	scene["talk"] = maxf(float(scene["talk"]), 3.0)
	if not l.is_empty():
		_log("%s: %s" % [tag, l[0]])


## The dostawczak's timeline, each tick: after its stay the courier gets in, the hazards go off and
## the van pulls out into its lane and drives on as ordinary traffic.
func _delivery_step() -> void:
	var van = scene["van"]
	if van == null or float(scene["age"]) < float(scene["stay"]):
		return
	scene["van"] = null
	if not van.active:
		return
	van.hazard = false
	scene["drivers"].erase(van)
	traffic.unpark(van, int(scene["e"]), int(scene["lane"]), float(scene["s0"]) + AT_VAN)
	van.persistent = false
	if walkers != null:
		walkers.clear_scene(0)
	if dialogue != null and dialogue.bubbles != null:
		dialogue.bubbles.hush(_anchor(0))
	_log("the courier drives off")


## The player's horn (main.gd `_honk`) at `at`: a courier still at their van within HONK_REACH m
## answers (at most every HONK_REPLY_GAP s).
func honk(at: Vector3) -> void:
	if scene.is_empty() or scene.get("van") == null:
		return
	var van = scene["van"]
	if Vector2(at.x, at.z).distance_to(Vector2(van.pos.x, van.pos.z)) > HONK_REACH:
		return
	if _clock - float(scene.get("honk_at", -INF)) < HONK_REPLY_GAP:
		return
	scene["honk_at"] = _clock
	honk_replies += 1
	_say(0, "honked")


## The sobriety check's part for the player, each tick (road_rules.gd sober_*): waved in when they
## come near in its lane or the next; stopping by the waving officer is a breath test; driving on
## past them costs respect (once).
func _sober_step(dt: float, v: Array) -> void:
	var stage: int = scene["sober"]
	if stage == 3 or bool(v[2]):
		return
	if stage == 2:
		scene["blow"] = float(scene["blow"]) - dt
		if float(scene["blow"]) <= 0.0:
			_sober_result()
		return
	var e: int = scene["e"]
	var wave: Vector2 = scene["wave"]
	var dir := graph.direction(e, float(scene["s0"]) + AT_SOBER_WAVE)
	var me3: Vector3 = v[0]
	# [metres past the officer along the road (coming up from behind: < 0), metres to the side].
	var rel := Rules.relative(wave, dir, Vector2(me3.x, me3.z))
	var pv: float = float(v[3]) if v.size() > 3 else float(v[1]) / 3.6
	if not Rules.sober_near(rel.x, rel.y):
		if stage == 1 and Rules.sober_passed(rel.x, rel.y):
			scene["sober"] = 3
			sober_passed += 1
			var took: int = wallet.lose_respect(Rules.SOBER_PASS_LOSS, Rules.respect_floor(int(wallet.respect))) if wallet != null else 0
			_say(1, "passed")
			_toast("passed", took)
			_log("drove past the sobriety check: -%d respect" % took)
		return
	if stage == 0:
		scene["sober"] = 1
		_say(1, "wave")
		_toast("wave", 0)
		_log("the player is waved in")
	if Rules.sober_stopped(rel.x, absf(pv)):
		scene["sober"] = 2
		scene["blow"] = SOBER_BLOW
		sober_tests += 1
		_say(0, "blow")
		_toast("blow", 0)
		_log("breath test")


## The breath test's result: 0,00 is respect; after the pub (tipsy.gd) a fine and a respect loss.
func _sober_result() -> void:
	scene["sober"] = 3
	var amount: float = float(tipsy.call()) if tipsy.is_valid() else 0.0
	var promil := Rules.promil(amount)
	if promil <= 0.0:
		if wallet != null:
			wallet.add_respect(Rules.SOBER_GAIN)
		_say(0, "sober")
		_toast("sober", Rules.SOBER_GAIN)
		_log("blew 0,00: +%d respect" % Rules.SOBER_GAIN)
		return
	sober_fines += 1
	var fine := 0
	var took := 0
	if wallet != null:
		fine = mini(SOBER_FINE, int(wallet.zl))
		if fine > 0:
			wallet.spend(fine)
		took = wallet.lose_respect(Rules.SOBER_DRUNK_LOSS, Rules.respect_floor(int(wallet.respect)))
	_say(0, "drunk")
	_toast("drunk", took, fine, promil)
	_log("blew %.2f per mille: -%d zl, -%d respect" % [promil, fine, took])


## A toast from the `sober_check` lines tagged "toast_<what>": {n} the respect, {zl} the fine, {p}
## the per mille (a comma in Polish). None for a loss of nothing (at the floor).
func _toast(what: String, n: int, zl := 0, promil := 0.0) -> void:
	if hud == null or dialogue == null:
		return
	if what == "passed" and n <= 0:
		return
	var l: Array = dialogue.line(SOBER_LINES, "toast_" + what, true)
	if l.is_empty():
		return
	var p := "%.2f" % promil
	var pl := String(l[0]).replace("{n}", str(n)).replace("{zl}", str(zl)).replace("{p}", p.replace(".", ","))
	var en := String(l[1]).replace("{n}", str(n)).replace("{zl}", str(zl)).replace("{p}", p)
	hud.toast(pl, en, Messages.INFO)


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
