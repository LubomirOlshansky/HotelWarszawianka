extends SceneTree
## The trend courier's job on the activity kit (scripts/trend_job.gd, tech-debt TD-1), played headless:
## the real TrendJob on the shared stand-ins of tools/fakes.gd (a HUD, a dialogue, a wallet, the
## rescue calls) and a few of its own (a flat world with two ground heights, a road 10 m east of any
## door, a kerb and an address picker, the city's slots, the crowds' sites), a fixed seed, its own
## `_process` a frame at a time, no map data, no await. Numbers and words are literals here, the
## roads and doors come from the rig's own data (what the stand-ins gave), never read back from
## `order`. It states, per fact, what the old script did and the kit's job must still do:
##   A. the settings (tag, job, card life, arrow, colour, the save's Dżemini);
##   B. the look: where and when a slot offers, the 18 things that hold it back, the cool-downs and
##      the rest after a card, `offer_places()`;
##   C. the request at a slot: its card, its order, its 10 s, the keys, taken back, a foreign card over it;
##   D. a slot's run: the queue, the door, the status line, the pay on time and late, day 5 and 6,
##      the ✕, the card put back;
##   E. Limitka (Friday's drop), F. Czwarty (PADELNIA), G. the DESKA call, its way, the card match, the
##      arcade court, every line of the rallies and the quest map's hooks;
##   H. Mlask (the van, the fans, the egg, the review, the sticker, the dice draw for draw);
##   I. Dżemini (Mrożulo's call, the bite, the sticker, the TYGRAM card); J. the coffee run (Zuzia's
##      call, the bike, four stamps, the glow, the late run, the ✕, the rest, the quest hooks);
##   K. one order over another and the seven answers "no" during a run; L. the autopilot to the end of
##      every kind; N. what deliberate breaks of the script showed (which comes first, the hours' ends,
##      the pay's two conditions one at a time, the door's hint, the DESKA call's way, the court, the
##      van by a road aslant, the forced orders, a hook over a request, the sticker once, the ring as
##      built, the grades' words); O. more of the same, from the breaks the parts above let by (the
##      tables of names and words by literal, each friend's first call, the ring, the pill and the
##      challenge at each accept, each result's ring, status line and side, the egg's clock, the
##      fans' bubble, the car back, the coffee run's status line, hints and holds, the look's order
##      and rests, the ticker, the map's list, the sticker's beat and its place on the wall).
## Prints "check_trend_job: OK (N checks; ...)" or one "  problem: ..." line per failed fact under
## "check_trend_job: PROBLEMS" (exit 1).
##   godot --headless --path game --script res://tools/check_trend_job.gd

const Trend := preload("res://scripts/trend_job.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Fakes := preload("res://tools/fakes.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Crowds := preload("res://scripts/crowds.gd")
const CityLife := preload("res://scripts/city_life.gd")
const CoffeeRun := preload("res://scripts/coffee_run.gd")
const DT := 1.0 / 60.0
const SEED := 20261114
const PINK := Color("#ff7ac8")
const GREEN := Color("#8fc46a")
const TEAL := Color("#2fd0e0")
const ORANGE := Color("#ffbf5f")
const BROWN := Color("#c98a4b")
const RED := Color("#e2574c")
const BLUE := Color("#3aa0e8")
const HOME := Vector2(5000.0, 5000.0)
const SLOT_A := Vector2(0.0, 0.0)
const SLOT_B := Vector2(300.0, 0.0)
const PISTACJA := Vector2(-300.0, 300.0)
const PADEL := Vector2(-600.0, 300.0)
const DZEMINI := Vector2(-900.0, 300.0)
const KUKLA_1 := Vector2(500.0, 900.0)
const KUKLA_2 := Vector2(1000.0, 900.0)
const DEST := Vector2(-2000.0, 0.0)
const GATE := Vector2(1475.0, 985.0)
const PLACES := {
	"rondo_daszynskiego": DEST,
	"plac_zbawiciela": Vector2(500.0, 500.0),
	"hala_koszyki": Vector2(700.0, 500.0),
	"kebab_palma": Vector2(900.0, 500.0),
	"plac_trzech_krzyzy": Vector2(1100.0, 500.0),
	"glon_dobra": Vector2(120.0, -600.0),
}
## The doors the address picker knows: [name, door].
const ADDRESSES := [
	["Prosta 51", Vector2(-2100.0, 50.0)], ["Towarowa 28", Vector2(-1900.0, -80.0)], ["Grzybowska 78", Vector2(-2050.0, 200.0)],
	["Kasprzaka 2", Vector2(-1800.0, 100.0)], ["Karolkowa 30", Vector2(-2000.0, 310.0)], ["Wilcza 9", Vector2(-300.0, 1100.0)],
	["Hoża 41", Vector2(300.0, 900.0)], ["Krucza 16", Vector2(-1200.0, 800.0)], ["Piękna 20", Vector2(-600.0, 1000.0)],
	["Mokotowska 12", Vector2(-100.0, 700.0)], ["Koszykowa 55", Vector2(-1000.0, -300.0)], ["Lwowska 3", Vector2(-450.0, 1500.0)],
]
const CUSTOMERS := ["Ania z HR", "Tomek z IT", "Kasia z marketingu", "Paweł z finansów", "Ola z działu prawnego", "Michał ze sprzedaży"]
const CZ_PLAYERS := ["Prezes z Mokotowa", "Pani Basia", "Trener Dominik", "kuzyn Kuby", "Ola z recepcji", "Michał od Excela"]
const FRIENDS := ["Zuzia", "Bartek", "Magda", "Kuba", "Iga", "Olek"]
const INJURED := ["Marta", "Ola", "Michał od Excela", "Prezes z Mokotowa"]
const BIOS := {
	"Kuba": ["Kumpel z liceum. Trzy rakiety, zero meczów.", "School mate. Three rackets, zero matches."],
	"Zuzia": ["Z pracy. Bluza klubowa przed pierwszym meczem.", "From work. Club hoodie before her first match."],
	"Bartek": ["Z osiedla. Rezerwuje korty na 6:00 rano.", "From the estate. Books courts for 6 a.m."],
	"Iga": ["Z salsy. Teraz mówi tylko „bandeja”.", "From salsa class. Now only says \"bandeja\"."],
	"Olek": ["Kuzyn. Grał w tenisa, więc myśli, że umie.", "Cousin. Played tennis, so he thinks he can."],
	"Magda": ["Sąsiadka. Prowadzi grupę „Padel Powiśle”.", "Neighbour. Runs the \"Padel Powiśle\" group."],
}
## The rallies' best shots, in the table's order (LOB 0, ZE ŚCIANY 1, SMECZ 2).
const BEST := [2, 0, 1, 0, 1]
const GRADES := [7.5, 8.0, 8.5, 9.0, 9.5]
const GRADE_WORDS := [["7,5 MLASKA", "7.5 SMACKS"], ["8 MLASKÓW", "8 SMACKS"], ["8,5 MLASKA", "8.5 SMACKS"], ["9 MLASKÓW", "9 SMACKS"], ["9,5 MLASKA", "9.5 SMACKS"]]
## Every rally of the match as the player reads it: [situation], the best shot, the winning words, the losing words (pl, en).
const RALLY_WORDS := [
	[["Piłka odbija się od tylnej szyby i wraca wysoko na środek kortu.", "The ball comes off the back glass and floats high over the middle."], 2,
		["Smecz! Piłka wylatuje za kort. Kibice z kawiarni klaszczą.", "Smash! The ball flies off the court. The café crowd claps."],
		["Lob z takiej piłki? Rywale dziękują i kończą punkt.", "A lob off that ball? The other pair says thanks and finishes it."]],
	[["Rywale stoją przy siatce. Prezes z Mokotowa macha rakietą jak packą na muchy.", "The other pair is up at the net. Prezes z Mokotowa swats like it's a fly."], 0,
		["Lob nad Prezesem! Odwraca się, piłka już leży za nim.", "A lob over Prezes! By the time he turns, it's down behind him."],
		["Prosto w Prezesa. Odbija, nawet nie wiedząc jak.", "Straight at Prezes. He gets it back without knowing how."]],
	[["Szybka piłka w róg, prosto w szybę za tobą.", "A fast ball into the corner, straight at the glass behind you."], 1,
		["Czekasz, piłka wraca od szyby, kontra po linii. Ściana jest częścią gry!", "You wait, it comes off the glass, a counter down the line. The wall is part of the game!"],
		["Bierzesz ją z powietrza i trafiasz w siatkę. Ściana by ci pomogła.", "You take it on the volley and hit the net. The wall would have helped."]],
	[["Krótka, niska piłka tuż za siatką. Trener Dominik krzyczy: „Nie biegaj, ustaw się!”", "A short, low ball just over the net. Trener Dominik shouts: \"Don't run, get in place!\""], 0,
		["Podbijasz lobem wysoko. Rywale cofają się do szyby i gubią rytm.", "You lift it high. The other pair backs off to the glass and loses the rhythm."],
		["Smecz z kolan? Piłka ląduje w siatce, Dominik łapie się za głowę.", "A smash from your knees? Into the net, and Dominik holds his head."]],
	[["Lob rywali leci nad tobą i spada za linią, przy samej szybie.", "Their lob sails over you and drops behind the line, right by the glass."], 1,
		["Odwracasz się, piłka odbija od szyby, odgrywasz spokojnie. Pani Basia z recepcji kiwa głową.", "You turn, it comes off the glass, you play it back calmly. Pani Basia from reception nods."],
		["Gonisz piłkę jak w tenisie i wpadasz na szybę. To nie tenis.", "You chase it like tennis and run into the glass. It isn't tennis."]],
]
## Coffee run: the four stops' names, prices, drinks as the toasts say them.
const CAFES := [["KROPKA.", 29, "matcha latte z kropką", "a matcha latte with a dot"], ["GLON NA POWIŚLU", 31, "ceremonialna matcha", "ceremonial matcha"],
		["STORCZYK", 27, "przelew V60, Etiopia", "a V60 pour-over, Ethiopia"], ["MANTRA", 34, "kawa z chmurką", "cloud coffee"]]


## A world that has two heights that never agree: one taken from the wrong place shows.
class SlopeMap extends Fakes.FlatMap:
	func ground_height(x: float, z: float) -> float:
		return 2.0 + 0.001 * x + 0.0005 * z
	func terrain_height(x: float, z: float) -> float:
		return 5.0 + 0.0007 * x - 0.0003 * z


## rides.gd's `idle()` (by `state`: 0 idle, 1 a request up, 2 a ride on) and `busy()`, rivals.gd's `busy()`.
class PlayBusy extends Node:
	var state := 0
	var on := false
	func busy() -> bool:
		return on
	func idle() -> bool:
		return state == 0


class PlayCar extends CharacterBody3D:
	var vel := Vector3.ZERO
	var in_water := false
	var model := "hatch"
	var throttle := 0.0
	var forward_speed := 0.0
	## Every model the job set, the times it stopped the car, the copies of it left standing.
	var models: Array[String] = []
	var resets := 0
	var copies := 0
	func set_model(id: String) -> void:
		model = id
		models.append(id)
	func reset_motion() -> void:
		resets += 1
	func parked_copy() -> Node3D:
		copies += 1
		return Node3D.new()


## lane_graph.gd as far as the job asks it: a road `off` away from the point asked about (10 m east),
## but for the places in `no_road`; its height is not the map's.
class PlayGraph extends LaneGraph:
	var no_road: Array[Vector2] = []
	var roads := {}
	var off := Vector2(10.0, 0.0)
	func _init() -> void:
		super({"nodes": [], "scc": [], "edges": [], "ctrl": []}, null)
	func snap(p: Vector2, reach: float, _heading := Vector2.ZERO, _scc_only := false, _ground_only := false, _no_tunnel := false) -> Array:
		for q: Vector2 in no_road:
			if q.distance_to(p) < 60.0:
				return []
		if reach < off.length():
			return []
		var e := posmod(roundi(p.x) * 31 + roundi(p.y) * 17, 9973)
		roads[e] = p + off
		return [e, 0, 4.0]
	func point_at(e: int, _s: float, _off := 0.0) -> Vector2:
		return roads[e]
	func surface(e: int, p: Vector2) -> float:
		return 1.0 + 0.0001 * e + 0.002 * p.x - 0.001 * p.y


## jobs.gd's side the job uses: its own busy, the kerb by a door, an address by road. It keeps every
## door asked (`kerbs`), what it answered (`answers`, with the door), every pick `[lo, hi, seed]`
## and the address it gave last.
class PlayJobs extends Node:
	var own := false
	## No kerb within 30 m of these.
	var no_kerb: Array[Vector2] = []
	var no_address := false
	var map: Node3D
	var kerbs: Array = []
	var answers: Array = []
	var picks: Array = []
	var last := {}
	func own_busy() -> bool:
		return own
	func _kerb(door: Vector2, at: Vector2, _half: float, _offsets: Array) -> Dictionary:
		kerbs.append(door)
		for q: Vector2 in no_kerb:
			if q.distance_to(door) < 30.0:
				return {}
		var dir := (at - door).normalized() if at.distance_to(door) > 0.01 else Vector2(1.0, 0.0)
		var out := {"centre": door + dir * 9.0, "side": Vector2(-dir.y, dir.x), "heading": dir,
				"edge": posmod(roundi(door.x) * 13 + roundi(door.y) * 7, 997), "s": 12.5, "spot": door + dir * 3.0}
		var rec := out.duplicate()
		rec["door"] = door
		answers.append(rec)
		return out
	func _pick_address(_e: int, _s: float, from: Vector2, lo: float, hi: float, rng: RandomNumberGenerator, test: Callable, _aim := 0.0) -> Dictionary:
		picks.append([lo, hi, rng.seed])
		if no_address:
			return {}
		var list: Array = []
		for a: Array in ADDRESSES:
			var entry := {"name": a[0], "door": a[1], "at": (a[1] as Vector2) + Vector2(0.0, 6.0)}
			if test.call(entry):
				list.append(entry)
		for k in range(list.size() - 1, 0, -1):
			var j := rng.randi() % (k + 1)
			var t: Dictionary = list[k]
			list[k] = list[j]
			list[j] = t
		for a: Dictionary in list:
			var door: Vector2 = a["door"]
			var road := door.distance_to(from) * 1.3
			if road < lo or road > hi:
				continue
			var out: Dictionary = a.duplicate()
			out["ring"] = Vector3(door.x, map.terrain_height(door.x, door.y + 2.0), door.y + 2.0)
			out["road"] = road
			last = out
			return out
		return {}


## city_life.gd's side: the three slots, the hour, the weekday.
class PlayLife extends Node3D:
	var slots_now: Array = []
	var slot_doors: Array = [SLOT_A, SLOT_B, Vector2.INF]
	var slot_out: Array = [Vector2(0.0, 1.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0)]
	var hour := 12.0
	var weekday := 1
	func hour_now() -> float:
		return hour
	func weekday_now() -> int:
		return weekday


## crowds.gd's side: the sites by id, Mrożulo's effect (the sites boosted), DŻEMINI's line (how often).
class PlayCrowds extends Node:
	var by_id := {}
	var sites: Array = []
	var boosts: Array[String] = []
	var mlasks := 0
	func add(id: String, door: Vector2, out: Vector2) -> void:
		by_id[id] = sites.size()
		sites.append({"id": id, "door": door, "out": out})
	func mrozulo_boost(id: String) -> void:
		boosts.append(id)
	func dzemini_mlask() -> void:
		mlasks += 1


## storefronts.gd's side: a venue's wall once its sector has put it there.
class PlayFronts extends Node:
	var placed := true
	func venue_wall(id: String) -> Dictionary:
		if not placed:
			return {}
		var h := float(id.hash() % 100)
		return {"p": Vector3(h, 1.0, -h), "n": Vector3(0, 0, 1), "t": Vector3(1, 0, 0), "up": 3.2, "front": true}


var problems: Array[String] = []
var _n := 0
var _sec_name := ""
var _smap: SlopeMap
var world: Node3D
var hud: Fakes.Hud
var dlg: Fakes.Dialogue
var wallet: Fakes.Wallet
var calls: Fakes.Calls
var rivals: PlayBusy
var rides: PlayBusy
var jobs: PlayJobs
var car: PlayCar
var life: PlayLife
var crowds: PlayCrowds
var fronts: PlayFronts
var graph: PlayGraph
var tj: Trend
var director: Activities
var other: Activity
## What the play hands in each frame, as main.gd does.
var flying := false
var heli := Vector3.ZERO
var mission := false
var auto := false
var eggs: Array[String] = []
## The mirror of the job's dice for the Mlask part: every draw seen is drawn here too.
var _mirror: RandomNumberGenerator
var _mirror_on := false
var _said_n := 0
var _fan_lines := 0
## The parts of the play that ran to their last line (a script error ends one early).
var _marks: Array[String] = []
## The three call clocks as the job builds them (before `_calls_off`): when each friend first rings (s of play).
var first_at := {}
## Frames the play has run (an independent clock: the job's own seconds are checked against it).
var _frames := 0
const PARTS := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "O1", "O2", "O3", "O4", "O5", "O6", "O7", "O8", "N1", "N2", "N3", "N4", "N5", "N6", "N7", "N8", "N9"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	_smap = SlopeMap.new()
	root.add_child(_smap)
	_sec("A. settings")
	_a_settings()
	_sec("B. the look")
	_b_look()
	_sec("C. the request")
	_c_request()
	_sec("D. a slot's run")
	_d_run()
	_sec("E. limitka")
	_e_limitka()
	_sec("F. czwarty")
	_f_czwarty()
	_sec("G. the DESKA call")
	_g_deska()
	_sec("H. mlask")
	_h_mlask()
	_sec("I. dzemini")
	_i_dzemini()
	_sec("J. the coffee run")
	_j_kawa()
	_sec("K. one order over another")
	_k_over()
	_sec("L. the autopilot")
	_l_auto()
	_sec("O. what the player gets, run by run")
	_o_gaps()
	_sec("N. the breaks")
	_n_gaps()
	for part: String in PARTS:
		if not _marks.has(part):
			problems.append("part %s did not run to its end (a script error?)" % part)
	if problems.is_empty():
		print("check_trend_job: OK (%d checks; A-O, %.1f s)" % [_n, (Time.get_ticks_msec() - t0) / 1000.0])
		quit(0)
	else:
		print("check_trend_job: PROBLEMS")
		for p in problems:
			print("  problem: " + p)
		quit(1)


func _sec(name: String) -> void:
	_sec_name = name


func _mark(part: String) -> void:
	_marks.append(part)


func _ok(cond: bool, what: String) -> void:
	_n += 1
	if not cond:
		problems.append("[%s] %s" % [_sec_name, what])


# --- the rig ------------------------------------------------------------------------------------

## A fresh world: the job as main.gd makes it, the director with a second, empty activity, Monday noon,
## the car at HOME, the three calls' clocks far away.
func _rig(kept := {}) -> void:
	if world != null:
		world.free()
	world = Node3D.new()
	root.add_child(world)
	hud = Fakes.Hud.new()
	dlg = Fakes.Dialogue.new()
	dlg.line_words = ["WIRAL PL", "VIRAL EN"]
	wallet = Fakes.Wallet.new()
	wallet.money = 100
	wallet.keep = kept.duplicate()
	calls = Fakes.Calls.new()
	rivals = PlayBusy.new()
	rides = PlayBusy.new()
	jobs = PlayJobs.new()
	jobs.map = _smap
	car = PlayCar.new()
	life = PlayLife.new()
	crowds = PlayCrowds.new()
	fronts = PlayFronts.new()
	graph = PlayGraph.new()
	for nd: Node in [hud, dlg, wallet, calls, rivals, rides, jobs, car, life, crowds, fronts]:
		world.add_child(nd)
	life.slots_now = [_slot(2, 5, "DUBAJSKA"), _slot(6, 5, "MATCHA"), _slot(8, 5, "WKRÓTCE NOWE MIEJSCE")]
	crowds.add(Crowds.PISTACJA_ID, PISTACJA, Vector2(0.0, 1.0))
	crowds.add(Crowds.PADEL_ID, PADEL, Vector2(1.0, 0.0))
	crowds.add("dzemini_kebab", DZEMINI, Vector2(0.0, -1.0))
	crowds.add(Crowds.KUKLA[0], KUKLA_1, Vector2(0.0, 1.0))
	crowds.add(Crowds.KUKLA[1], KUKLA_2, Vector2(1.0, 0.0))
	graph.no_road = [PLACES["kebab_palma"]]
	jobs.no_kerb = [PLACES["plac_trzech_krzyzy"] + Vector2(9.5, 0.0)]
	flying = false
	heli = Vector3.ZERO
	mission = false
	auto = false
	eggs.clear()
	_mirror_on = false
	_said_n = 0
	_at(HOME)
	# The job as main.gd makes it.
	tj = Trend.new()
	tj.hud = hud
	tj.dialogue = dlg
	tj.wallet = wallet
	tj.rivals = rivals
	tj.jobs = jobs
	tj.rides = rides
	tj.graph = graph
	tj.map = _smap
	tj.car = car
	tj.life = life
	tj.crowds = crowds
	tj.storefronts = fronts
	tj.places = PLACES.duplicate()
	world.add_child(tj)
	tj.set_process(false)
	tj.setup(world)
	tj._rng.seed = SEED
	tj.egg = func(id: String) -> bool:
		eggs.append(id)
		return true
	tj.hour_now = func() -> float: return life.hour
	tj.log_on = false
	# The director as main.gd makes it, and a second, empty activity.
	director = Activities.new()
	director.add(tj, func() -> bool: return true)
	other = Activity.new()
	other.hud = hud
	other.dialogue = dlg
	other.wallet = wallet
	other.map = _smap
	other.car = car
	world.add_child(other)
	other.set_process(false)
	other.setup(world)
	director.add(other, func() -> bool: return true)
	director.add(calls)
	first_at = {"kawa": tj._kawa_at, "dz": tj._dz_at, "deska": tj._deski_at}
	_calls_off()


func _slot(day: int, cycle: int, word: String) -> Dictionary:
	return {"day": day, "trend": 1, "cycle": cycle, "queue": 12, "word": word, "tag": "new"}


## No call by itself: the three call clocks far away.
func _calls_off() -> void:
	tj._dz_at = 1.0e9
	tj._kawa_at = 1.0e9
	tj._deski_at = 1.0e9


## Every cool-down and rest over: the next look may offer.
func _rested() -> void:
	tj._cool = {}
	tj._card_rest = 0.0
	tj._call_rest = 0.0


# --- frames and keys ------------------------------------------------------------------------------

## main.gd `_slide_car`: the autopilot's car for an activity of the kit (22 m/s, straight there).
func _slide() -> void:
	if not tj.has_target() or flying:
		return
	var t: Vector3 = tj.target_position()
	var to := Vector3(t.x - car.global_position.x, 0.0, t.z - car.global_position.z)
	var d := to.length()
	car.vel = Vector3.ZERO
	car.throttle = 0.0
	if d > 0.5:
		var m := minf(d, 22.0 * DT)
		car.global_position += to / d * m
		car.rotation.y = atan2(-to.x, -to.z)


## One frame, as main.gd hands things in before the job's own.
func _frame() -> void:
	tj.autopilot = auto
	if auto:
		_slide()
	tj.player_pos = heli if flying else car.global_position
	tj.flying = flying
	tj.mission_on = mission or tj.busy()
	car.velocity = car.vel
	tj._process(DT)
	_frames += 1
	if _mirror_on:
		_watch_fans()


func _secs(s: float) -> void:
	for i in roundi(s * 60.0):
		_frame()


## Frames until `f` is true, at most `s` seconds; whether it got there.
func _until(f: Callable, s: float) -> bool:
	for i in roundi(s * 60.0):
		if f.call():
			return true
		_frame()
	return bool(f.call())


func _until_phase(ph: int, s: float) -> bool:
	return _until(func() -> bool: return tj.phase == ph, s)


func _until_stage(st: int, s: float) -> bool:
	return _until(func() -> bool: return tj.stage == st, s)


func _until_idle(s: float) -> bool:
	return _until_phase(Activity.Phase.IDLE, s)


## Nothing went up for `s` seconds: idle all the way and no card or call shown.
func _quiet(s: float) -> bool:
	var s0 := hud.shown
	for i in roundi(s * 60.0):
		_frame()
		if tj.phase != Activity.Phase.IDLE or hud.shown != s0:
			return false
	return true


## Still in `ph` after `s` seconds, all the way.
func _stays(ph: int, s: float) -> bool:
	for i in roundi(s * 60.0):
		_frame()
		if tj.phase != ph:
			return false
	return true


func _press(i: int) -> void:
	hud.press(i)


func _abort() -> void:
	hud.abort_pressed.emit()


func _ph() -> int:
	return tj.phase


func _is_phase(ph: int) -> bool:
	return tj.phase == ph


func _in_stage(st: int) -> bool:
	return tj.phase == Activity.Phase.RUN and tj.stage == st


func _idle() -> bool:
	return tj.phase == Activity.Phase.IDLE and tj.stage == Trend.Stage.NONE


func _sub() -> String:
	return str(tj.order.get("stage", ""))


## The car on the ground at `p`, at `speed` m/s.
func _at(p: Vector2, speed := 0.0) -> void:
	car.global_position = Vector3(p.x, _smap.ground_height(p.x, p.y), p.y)
	car.vel = Vector3(0.0, 0.0, -speed)


## The car `d` m east of the ring `r`.
func _by(r: Vector3, d: float, speed := 0.0) -> void:
	_at(Vector2(r.x + d, r.z), speed)


func _hour(h: float, weekday := -1) -> void:
	life.hour = h
	if weekday > 0:
		life.weekday = weekday


func _near(a: Vector3, b: Vector3) -> bool:
	return a.distance_to(b) < 0.001


## Is the last toast these words?
func _toast(pl: String, en: String) -> bool:
	return not hud.toasts.is_empty() and hud.toasts[-1] == pl and hud.toasts_en[-1] == en


func _status(title: String, hint: String, hint_en: String) -> bool:
	return hud.status_title == title and hud.status == hint and hud.hint_en == hint_en


## What the ring looks like now.
func _look() -> Dictionary:
	var b: Node3D = tj._beacon
	return {"vis": b.visible, "pos": b.global_position, "r": b._ring_radius, "col": b._colour, "ring": b._ring.visible,
			"column": b._column.visible, "person": b._person.visible, "wave": b.waving}


## The ring at `at`, in `col`, `waving` or not, with its column (a pickup/delivery ring: radius 12.5).
func _ring_is(at: Vector3, col: Color, waving: bool) -> bool:
	var l := _look()
	return bool(l["vis"]) and _near(l["pos"], at) and is_equal_approx(float(l["r"]), 12.5) and l["col"] == col \
			and bool(l["ring"]) and bool(l["column"]) and bool(l["wave"]) == waving


## The ring after the result: dimmed (no ring, no column), the person left, not waving.
func _ring_dimmed(at: Vector3) -> bool:
	var l := _look()
	return bool(l["vis"]) and _near(l["pos"], at) and not bool(l["ring"]) and not bool(l["column"]) and bool(l["person"]) and not bool(l["wave"])


## The kerb answer for a door asked of the stand-in (the last one), or {}.
func _ans(door: Vector2) -> Dictionary:
	for i in range(jobs.answers.size() - 1, -1, -1):
		if (jobs.answers[i] as Dictionary)["door"] == door:
			return jobs.answers[i]
	return {}


## The point 2 m off the kerb's centre at the graph's height: where a request's ring stands.
func _kerb_ring(a: Dictionary) -> Vector3:
	var kerb: Vector2 = (a["centre"] as Vector2) + (a["side"] as Vector2) * 2.0
	return Vector3(kerb.x, graph.surface(a["edge"], kerb), kerb.y)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _terrain(p: Vector2) -> Vector3:
	return Vector3(p.x, _smap.terrain_height(p.x, p.y), p.y)


## `got` is `template` with "<c>" replaced by one of `names`.
func _one_of(template: String, names: Array, got: String) -> bool:
	for c: String in names:
		if got == template.replace("<c>", c):
			return true
	return false


## In `st` of the run for `s` seconds, all the way.
func _stays_stage(st: int, s: float) -> bool:
	for i in roundi(s * 60.0):
		_frame()
		if not _in_stage(st):
			return false
	return true


# --- scenario helpers -----------------------------------------------------------------------------

## Takes the request at slot `slot` (0 A, 1 B): the car 30 m from the door until the card, then ACCEPT.
func _take_slot(slot: int) -> Dictionary:
	_rested()
	_at((SLOT_A if slot == 0 else SLOT_B) + Vector2(0.0, 30.0))
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "the card came at slot %d" % slot)
	var pick: Dictionary = jobs.last.duplicate()
	_press(0)
	_ok(_in_stage(Trend.Stage.PICKUP), "ACCEPT started the pickup at slot %d" % slot)
	return pick


## Stands in the pickup ring until the way begins.
func _pick_up(hold: float) -> void:
	_by(tj.order["ring"], 3.0)
	_ok(_until_stage(Trend.Stage.DELIVER, hold + 0.3), "picked up")


## At the door: the result.
func _arrive() -> void:
	_by(tj.order["door_ring"], 12.0, 5.9)
	_ok(_until_stage(Trend.Stage.RESULT, 0.1), "arrived at the door")


## A slot, the queue and the door in one go; `late` sets the clock past the limit before the door.
func _slot_run(slot: int, late := false) -> Dictionary:
	var pick := _take_slot(slot)
	_pick_up(1.5)
	if late:
		tj._clock = 361.0
	_arrive()
	return pick


# --- A. the settings -----------------------------------------------------------------------------

func _a_settings() -> void:
	_rig()
	_ok(tj.tag == "trend job" and tj.is_job and not tj.offer_busy and not tj.cards_low and not tj.flown, "the tag, a job, the request leaves the player free, cards beside the road, not flown")
	_ok(tj.card_life == 10.0, "the request's life is 10 s")
	_ok(tj.idle() and not tj.busy() and not tj.has_target() and tj.stop_spot() == Vector3.INF and tj.grounded() == [], "idle, not busy, no target, no stop spot, nothing grounds the helicopter")
	_ok(tj.target_arrow() and tj.target_label(123) == "123 m" and tj.target_colour() == PINK, "the arrow shows, its metres, the pink")
	_ok(not tj._van_node.visible, "the van's node is hidden before the first look")
	_ok(tj.done == 0 and not tj.dz_done, "nothing done, Dżemini not done")
	var l := _look()
	_ok(tj._beacon._colour == PINK and not bool(l["vis"]), "the ring as built is pink and hidden")
	var shirt := ((tj._beacon._person.get_child(2) as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
	_ok(shirt.albedo_color == Color("#2f6fb5"), "the ring's person wears a blue shirt")
	# A save that has the MLASK on DŻEMINI.
	_rig({"dzemini_mlask": true})
	_ok(tj.dz_done and crowds.mlasks == 1, "the save's Dżemini: done, the crowds told once right after setup")
	_secs(1.2)
	_ok(_stickers() == 1, "the sticker's node is on the wall within 1.2 s")
	tj._dz_at = 0.0
	_hour(12.0, 4)
	_ok(_quiet(2.0), "Mrożulo never rings on a save that has the MLASK")
	_mark("A")


## The MLASK stickers in the world: its mesh instances that are neither the van nor a glow (a node
## that shares a name with one on its way out is renamed, so the name is not what is counted).
func _sticker_nodes() -> Array:
	var out: Array = []
	for ch: Node in world.get_children():
		if ch is MeshInstance3D and ch != tj._van_node and not (ch as MeshInstance3D).mesh is QuadMesh and not ch.is_queued_for_deletion():
			out.append(ch)
	return out


func _stickers() -> int:
	return _sticker_nodes().size()


# --- B. the look ----------------------------------------------------------------------------------

func _gate(name: String, on: bool) -> void:
	match name:
		"flying":
			flying = on
			heli = Vector3(car.global_position.x, 60.0, car.global_position.z)
		"away", "quiet", "guide_hold":
			tj.set(name, on)
		"mission":
			mission = on
		"water":
			car.in_water = on
		"rescue target":
			calls.put(Activity.Phase.RUN if on else Activity.Phase.IDLE, on)
		"rescue offer":
			calls.put(Activity.Phase.OFFER if on else Activity.Phase.IDLE)
		"own job":
			jobs.own = on
		"a ride":
			rides.state = 1 if on else 0
		"a ride on":
			rides.state = 2 if on else 0
			rides.on = on
		"a race":
			rivals.on = on
		"a card":
			if on:
				hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
			else:
				hud.hide_card()
		"no slots":
			life.slots_now = [] if on else [_slot(2, 5, "DUBAJSKA"), _slot(6, 5, "MATCHA"), _slot(8, 5, "WKRÓTCE NOWE MIEJSCE")]
		"closed early":
			_hour(7.9 if on else 12.0)
		"closed late":
			_hour(20.0 if on else 12.0)
		"day 8":
			life.slots_now[0]["day"] = 8 if on else 2
		"no kerb":
			if on:
				jobs.no_kerb.append(SLOT_A)
			else:
				jobs.no_kerb.erase(SLOT_A)
		"no address":
			jobs.no_address = on
		_:
			_ok(false, "no gate %s" % name)


func _b_look() -> void:
	_rig()
	_hour(12.0, 1)
	_ok(_quiet(2.0), "far from everything, nothing is shown in 2 s")
	_ok(tj._van_node.visible and str(tj.van.get("spot", "")) == "hala_koszyki", "the van is out on a Monday noon, parked at hala_koszyki")
	_at(SLOT_A + Vector2(0.0, 61.0))
	_ok(_quiet(1.1), "no card from 61 m")
	_at(SLOT_A + Vector2(0.0, 59.0))
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "the card within 0.6 s from 59 m")
	var p0: float = tj._played
	_ok(is_equal_approx(float(tj._cool.get(0, -1.0)), p0 + 240.0), "the slot cools down 240 s from the offer")
	_press(1)
	_ok(_idle() and not tj.order.is_empty(), "SKIP: idle")
	_ok(_quiet(1.1), "no second card from the slot that cools down")
	for gate: String in ["flying", "away", "quiet", "guide_hold", "mission", "water", "rescue target", "rescue offer", "own job", "a ride", "a race",
			"a card", "no slots", "closed early", "closed late", "day 8", "no kerb", "no address"]:
		_rested()
		_gate(gate, true)
		_ok(_quiet(1.1), "an offer in spite of: %s" % gate)
		_gate(gate, false)
		_rested()
		_ok(_until_phase(Activity.Phase.OFFER, 0.6), "no card within 0.6 s once lifted: %s" % gate)
		_press(1)
		_ok(_idle(), "SKIP closed it after: %s" % gate)
	# A rescue call ringing does not hold a request back.
	_rested()
	calls.put(Activity.Phase.RING)
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "a ringing rescue call does not hold a request back")
	calls.put(Activity.Phase.IDLE)
	_press(1)
	# The director's word counts, with a function and with another activity on.
	_rested()
	var keep: Callable = tj.free_now
	tj.free_now = func() -> bool: return false
	_ok(_quiet(1.1), "no card when the director says no")
	tj.free_now = keep
	other.start()
	_ok(not director.may_start(tj) and director.current() == other, "the director refuses the job while another activity is on")
	_ok(_quiet(1.1), "no card while another activity is on")
	other.finish()
	_rested()
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "the card is back when the other activity is over")
	_press(1)
	# The play clock stands while away.
	var t1: float = tj._played
	tj.away = true
	_secs(1.0)
	_ok(tj._played == t1, "the play clock stands while away")
	tj.away = false
	_secs(0.5)
	_ok(tj._played > t1 + 0.4, "and runs again when back")
	# After a skip: 240 s for the same slot.
	_rested()
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "the card again after a rest")
	p0 = tj._played
	_ok(is_equal_approx(float(tj._cool.get(0, -1.0)), p0 + 240.0), "the slot's cool-down is the offer's moment + 240 s")
	_press(1)
	tj._played = p0 + 239.0
	_ok(_quiet(0.4), "239 s after the offer: none")
	tj._played = p0 + 241.0
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "241 s after the offer: the card")
	# After a ✕ 2.5 s of rest, after a skip none.
	_press(0)
	_abort()
	_ok(_idle() and is_equal_approx(tj._card_rest, tj._played + 2.5), "the ✕ starts 2.5 s of rest")
	tj._cool = {}
	_ok(_quiet(2.4), "2.4 s after a card closed: no new card")
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "then the card")
	_press(1)
	tj._cool = {}
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "a skip starts no rest: the card within 0.6 s")
	_press(1)
	# offer_places().
	_rested()
	_at(HOME)
	_secs(0.6)
	var pl: Array = tj.offer_places()
	var vr: Vector3 = tj.van["ring"]
	_ok(pl.size() == 3, "idle at noon: two slots and the van (%d)" % pl.size())
	if pl.size() == 3:
		_ok(pl[0]["group"] == "trend" and pl[0]["at"] == SLOT_A and pl[0]["colour"] == PINK and pl[0]["name"] == ["Na czasie · DUBAJSKA", "On trend · DUBAJSKA"], "the first slot in the map's list")
		_ok(pl[1]["group"] == "trend" and pl[1]["at"] == SLOT_B and pl[1]["name"] == ["Na czasie · MATCHA", "On trend · MATCHA"], "the second slot in the map's list")
		_ok(pl[2]["group"] == "mlask" and pl[2]["at"] == Vector2(vr.x, vr.z) and pl[2]["colour"] == ORANGE and pl[2]["name"] == ["Mlask · van Mrożula", "Smack · Mrożulo's van"], "the van in the map's list")
	tj._cool[0] = tj._played + 100.0
	pl = tj.offer_places()
	_ok(pl.size() == 2 and pl[0]["at"] == SLOT_B, "a slot that cools down is not listed")
	tj._cool = {}
	_hour(17.0, 5)
	pl = tj.offer_places()
	_ok(pl.size() == 4 and pl[3]["group"] == "drop" and pl[3]["at"] == PISTACJA and pl[3]["colour"] == GREEN \
			and pl[3]["name"] == ["Limitka · PISTACJA DO KOŃCA", "Limited drop · PISTACJA DO KOŃCA"], "on Friday 17:00 the drop is listed too")
	_hour(12.0, 1)
	_ok(tj.offer(0) and tj.offer_places().is_empty(), "empty while a request is up")
	_press(0)
	_ok(_in_stage(Trend.Stage.PICKUP) and tj.offer_places().is_empty(), "empty during a run")
	_abort()
	_mark("B")


# --- C. the request ---------------------------------------------------------------------------------

## A request at `slot` by the direct call (a test flag), after a rest.
func _req(slot := 0) -> void:
	_rested()
	_ok(tj.offer(slot) and _is_phase(Activity.Phase.OFFER), "offer(%d) asks" % slot)


func _c_request() -> void:
	_rig()
	_hour(12.0, 1)
	_rested()
	var c0 := calls.closed
	_at(SLOT_A + Vector2(0.0, 30.0))
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "the card within 0.6 s at 30 m")
	var a := _ans(SLOT_A)
	var pick: Dictionary = jobs.last.duplicate()
	_ok(tj.phase == Activity.Phase.OFFER and tj.stage == Trend.Stage.NONE and not tj.busy() and director.current() == null \
			and director.may_start(other) and not tj.idle() and not tj.has_target(), "a request: OFFER, no stage, not busy, nobody on, the director lets another start, not idle, no target")
	_ok(hud.side and hud.card_is(tj) and hud.card == "NA CZASIE · DUBAJSKA" and hud.card_en == "On trend · DUBAJSKA", "the card beside the road, its own, titled")
	_ok(hud.body == "Biuro z Ronda Daszyńskiego chce trend, zanim minie. Dowóz w 6 min." and hud.body_en == "Rondo Daszyńskiego wants it before it's over. 6 min to deliver.", "the request's words")
	_ok(hud.button_words == PackedStringArray(["ACCEPT", "SKIP"]) and hud.accent == PINK and hud.face == "", "the buttons, the pink, no face")
	var o: Dictionary = tj.order
	_ok(int(o["slot"]) == 0 and str(o["word"]) == "DUBAJSKA" and int(o["day"]) == 2, "the order: slot 0, DUBAJSKA, day 2")
	_ok(not a.is_empty() and _near(o["ring"], _kerb_ring(a)), "the order's ring is the kerb's point 2 m off its centre at the graph's height")
	_ok(o["door_ring"] == pick["ring"] and float(o["road"]) == float(pick["road"]) and str(o["name"]) == str(pick["name"]), "the door, the road and the name are the address's")
	var door: Vector2 = pick["door"]
	_ok(door.distance_to(DEST) <= 300.0, "the address is within 300 m of Rondo Daszyńskiego")
	_ok(jobs.picks[-1] == [0.0, 9000.0, tj.done * 7919 + 0 * 31 + 5 * 3], "the address picked from 0 to 9000 m with the slot's seed")
	_ok(not calls._held() and calls.closed == c0, "the rescue line is not touched by a request")
	var toasts0 := hud.toasts.size()
	_abort()
	_ok(_is_phase(Activity.Phase.OFFER) and hud.card_is(tj), "the ✕ does nothing on a request")
	_ok(_stays(Activity.Phase.OFFER, 9.9), "still up 9.9 s after it went up")
	_ok(_until_idle(0.2), "gone by 10.1 s")
	_ok(hud.card == "" and hud.toasts.size() == toasts0 and wallet.kinds.is_empty() and wallet.money == 100 and int(tj.order["slot"]) == 0, "nobody answered: no card, no toast, no pay, the order is still the slot's")
	# The keys.
	_req()
	_ok(tj.secondary() and _idle(), "secondary() skips")
	_ok(not tj.primary() and not tj.secondary(), "no key does anything while idle")
	_req()
	_ok(tj.primary() and _in_stage(Trend.Stage.PICKUP), "primary() takes the request: the pickup starts")
	_ok(not tj.primary() and not tj.secondary(), "no key does anything on the way")
	_abort()
	# Taken back at the next frame.
	for gate: String in ["flying", "away", "mission", "own job", "a ride on"]:
		_req()
		var n := hud.toasts.size()
		_gate(gate, true)
		_frame()
		_ok(_idle() and hud.card == "" and hud.toasts.size() == n, "the request is taken back at the next frame, without a toast: %s" % gate)
		_gate(gate, false)
		_frame()
	# Somebody else's card over the request.
	_req()
	var b0 := hud.broadcast
	hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	_press(0)
	_ok(hud.broadcast == b0 + 1 and _is_phase(Activity.Phase.OFFER), "a press of the other card goes to every listener, the request is still on")
	_ok(_stays(Activity.Phase.OFFER, 9.9), "and still on 9.9 s after")
	_ok(_until_idle(0.2), "its 10 s run out to idle")
	_mark("C")


# --- D. a slot's run ----------------------------------------------------------------------------------

func _d_run() -> void:
	_rig()
	_hour(12.0, 1)
	_rested()
	var c0 := calls.closed
	var ph0 := hud.pills_hidden
	var ch0 := hud.challenges_hidden
	_at(SLOT_A + Vector2(0.0, 30.0))
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "the card at 30 m")
	var a := _ans(SLOT_A)
	var pick: Dictionary = jobs.last.duplicate()
	var ring := _kerb_ring(a)
	var door: Vector3 = pick["ring"]
	var road: float = pick["road"]
	_press(0)
	_ok(tj.phase == Activity.Phase.RUN and tj.stage == Trend.Stage.PICKUP and tj.busy(), "ACCEPT: RUN, PICKUP, busy")
	_ok(director.current() == tj and director.busy_tag() == "trend job" and not director.may_start(other) and director.targeted() == tj, "the director: it is on, named, nobody else may start, it has the target")
	_ok(hud.card == "", "no card up")
	_ok(calls._held() and calls.closed == c0 + 1 and hud.pills_hidden == ph0 + 1 and hud.challenges_hidden == ch0 + 1, "the rescue line paused and closed once, the pill and the challenge taken down")
	_ok(_toast("Na czasie: odbiór przy kolejce", "On trend: pick up by the queue"), "the toast")
	_ok(_ring_is(ring, PINK, false), "the ring at the kerb, radius 12.5, pink, not waving")
	_ok(tj.has_target() and _near(tj.target_position(), ring) and _near(tj.stop_spot(), ring), "the target and the stop spot are the pickup")
	_frame()
	_ok(_status("NA CZASIE · ODBIÓR", "Stań przy kolejce", "Stop by the queue") and hud.count == "" and hud.distance == "%d m" % roundi(_flat(car.global_position, ring)) \
			and hud.progress == 0.0 and hud.tint == PINK, "the pickup's status line")
	_by(ring, 14.0)
	_ok(_stays_stage(Trend.Stage.PICKUP, 0.5), "not picked up from 14 m")
	_by(ring, 12.0, 6.5)
	_ok(_stays_stage(Trend.Stage.PICKUP, 0.5), "not picked up at 6.5 m/s")
	_by(ring, 3.0)
	flying = true
	heli = ring + Vector3(0.0, 40.0, 0.0)
	_ok(_stays_stage(Trend.Stage.PICKUP, 0.5), "not picked up from the air over it")
	flying = false
	_by(ring, 12.0, 5.9)
	_secs(0.75)
	_ok(absf(hud.progress - 0.5) < 0.02, "the bar is the hold over 1.5 s (%.3f)" % hud.progress)
	_by(ring, 14.0)
	_frame()
	_ok(tj._hold == 0.0, "leaving the ring sets the hold back")
	_by(ring, 12.0, 5.9)
	_ok(_stays_stage(Trend.Stage.PICKUP, 1.4), "not picked up before 1.4 s")
	_ok(_until_stage(Trend.Stage.DELIVER, 0.2), "picked up by 1.6 s")
	_ok(_toast("Odbiór na aplikację: kolejka przepuszcza kuriera", "App pickup: the queue lets the courier through"), "the pickup's toast")
	_ok(_ring_is(door, PINK, true) and tj.has_target() and _near(tj.target_position(), door) and _near(tj.stop_spot(), door), "the ring and the target move to the door, waving")
	_by(door, 200.0, 12.0)
	_secs(0.5)
	_ok(_status("NA CZASIE → %s" % pick["name"], "Jedź do różowego światła", "Head for the pink beacon") and hud.count == "5:59" \
			and hud.distance == "%d m" % roundi(_flat(car.global_position, door)) and hud.tint == PINK and absf(hud.progress - 0.5 / 360.0) < 0.001, "the way: title, 5:59, metres, hint, tint, bar")
	tj._clock = 400.0
	_frame()
	_ok(hud.count == "+0:40" and _status("NA CZASIE → %s" % pick["name"], "Spóźnione, ale dowieź", "Late, but deliver it") and hud.tint == RED and hud.progress == 1.0, "late: +0:40, the late hint, red, full bar")
	tj._clock = 10.0
	_by(door, 14.0)
	_ok(_stays_stage(Trend.Stage.DELIVER, 0.3), "not there from 14 m")
	_by(door, 12.0, 6.5)
	_ok(_stays_stage(Trend.Stage.DELIVER, 0.3), "not there at 6.5 m/s")
	_by(door, 3.0)
	flying = true
	heli = door + Vector3(0.0, 40.0, 0.0)
	_ok(_stays_stage(Trend.Stage.DELIVER, 0.3), "not there from the air")
	flying = false
	_by(door, 12.0, 5.9)
	_frame()
	_ok(_in_stage(Trend.Stage.RESULT) and tj.busy() and not tj.has_target(), "12 m at 5.9 m/s: the result at the next frame, still busy, no target")
	_ok(hud.status == "" and hud.status_title == "" and _ring_dimmed(door), "the status line down, the ring dimmed")
	var pay := 25 + roundi(8.0 * road / 1000.0) + 10
	_ok(wallet.money == 100 + pay and wallet.respect == 15 and wallet.kinds == ["trend"] and tj.done == 1, "paid %d zł and 15 respect, kind trend, once" % pay)
	_ok(hud.side and hud.card_is(tj) and hud.card == "NA CZASIE · +%d zł" % pay and hud.card_en == "On trend · +%d zł" % pay, "the result card, beside the road, its own, titled")
	_ok(_one_of("„Jeszcze ciepłe i jeszcze modne. Dziękuję!” · <c>\n+%d zł (napiwek 10 zł), +15 szacunku" % pay, CUSTOMERS, hud.body), "the result's body")
	_ok(hud.body_en == "\"Still warm and still trendy. Thank you!\"\n+%d zł (tip 10 zł), +15 respect" % pay, "the result's English")
	_ok(hud.button_words == PackedStringArray(["OK"]), "one button, OK")
	_abort()
	_ok(not tj.secondary() and _in_stage(Trend.Stage.RESULT) and hud.card_is(tj), "the ✕ and secondary() do nothing on the result")
	# Somebody else's card over the result: back at the next frame after it is taken down.
	var title: String = hud.card
	hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	_frame()
	_ok(hud.card == "INNA", "somebody else's card stays while it is up")
	hud.hide_card()
	_frame()
	_ok(hud.card == title and hud.side and hud.card_is(tj), "the result card is back beside the road, still the job's own")
	var c1 := calls.closed
	_press(0)
	_ok(_idle() and not calls._held() and calls.closed == c1 + 1 and tj.order == {} and hud.card == "" and not _look()["vis"] \
			and is_equal_approx(tj._card_rest, tj._played + 2.5), "OK: idle, the rescue line free and closed once more, no order, no card, no ring, 2.5 s rest")
	# Left alone: 10 s.
	_slot_run(0)
	_ok(_stays_stage(Trend.Stage.RESULT, 9.9), "the result still up 9.9 s after")
	_ok(_until_idle(0.2), "gone by 10.1 s")
	# Late.
	var m0 := wallet.money
	var r0 := wallet.respect
	pick = _slot_run(0, true)
	var base := 25 + roundi(8.0 * float(pick["road"]) / 1000.0)
	var half := roundi(base * 0.5)
	_ok(wallet.money == m0 + half and wallet.respect == r0, "late: half the base (%d), no tip, no respect" % half)
	_ok(_one_of("„Spóźnione. Trend poszedł dalej beze mnie.” · <c>\n+%d zł (napiwek 0 zł), +0 szacunku" % half, CUSTOMERS, hud.body) \
			and hud.body_en == "\"Late. The trend moved on without me.\"\n+%d zł (tip 0 zł), +0 respect" % half, "late: the line")
	_press(0)
	# Slot B (day 6) on time: no tip, 15 respect, the bag's line.
	m0 = wallet.money
	r0 = wallet.respect
	var n_asks := dlg.line_asks.size()
	pick = _slot_run(1)
	base = 25 + roundi(8.0 * float(pick["road"]) / 1000.0)
	_ok(wallet.money == m0 + base and wallet.respect == r0 + 15, "day 6 on time: the base %d, no tip, 15 respect" % base)
	_ok(dlg.line_asks.size() > n_asks and dlg.line_asks[-1] == "viral:late" and "WIRAL PL" in hud.body and "(napiwek 0 zł), +15 szacunku" in hud.body, "day 6: the bag's line viral:late, no tip")
	_press(0)
	dlg.line_words = []
	pick = _slot_run(1)
	_ok(hud.body.begins_with("„” · "), "day 6 with no line in the bag: the quote is empty")
	_press(0)
	dlg.line_words = ["WIRAL PL", "VIRAL EN"]
	# The ✕ at the queue and on the way.
	for where: String in ["at the queue", "on the way"]:
		m0 = wallet.money
		var d0 := tj.done
		_take_slot(0)
		if where == "on the way":
			_pick_up(1.5)
			_by(tj.order["door_ring"], 100.0, 10.0)
			_secs(0.5)
		_abort()
		_ok(_idle() and _toast("Anulowane", "Cancelled") and wallet.money == m0 and not calls._held() and tj.done == d0 and not _look()["vis"] \
				and hud.status == "" and is_equal_approx(tj._card_rest, tj._played + 2.5), "the ✕ %s: idle, Anulowane, no pay, the line free, the ring and the status down, 2.5 s rest" % where)
	_mark("D")


# --- E. limitka ---------------------------------------------------------------------------------------

## Friday 17:00, the car 50 m from PISTACJA's door: the drop's request up; accepted. Returns the pick.
func _take_drop() -> Dictionary:
	_rested()
	_hour(17.0, 5)
	_at(PISTACJA + Vector2(0.0, 50.0))
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "the drop's card came")
	var pick: Dictionary = jobs.last.duplicate()
	_press(0)
	_ok(_in_stage(Trend.Stage.PICKUP), "ACCEPT started the drop's pickup")
	return pick


func _e_limitka() -> void:
	_rig()
	var by := PISTACJA + Vector2(0.0, 50.0)
	_rested()
	_hour(17.0, 4)
	_at(by)
	_ok(_quiet(1.1), "no drop on a Thursday")
	_hour(15.9, 5)
	_ok(_quiet(1.1), "no drop at 15.9 h")
	_hour(18.5, 5)
	_ok(_quiet(1.1), "no drop at 18.5 h")
	_hour(17.0, 5)
	_at(PISTACJA + Vector2(0.0, 61.0))
	_ok(_quiet(1.1), "no drop from 61 m")
	_at(by)
	jobs.no_kerb.append(PISTACJA)
	_rested()
	_ok(_quiet(1.1) and not tj.offer_drop(), "no kerb by PISTACJA: no request, false")
	jobs.no_kerb.erase(PISTACJA)
	jobs.no_address = true
	_rested()
	_ok(_quiet(1.1) and not tj.offer_drop(), "no address: no request, false")
	jobs.no_address = false
	_rested()
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "Friday 17:00, 50 m: the card")
	var a := _ans(PISTACJA)
	var pick: Dictionary = jobs.last.duplicate()
	_ok(is_equal_approx(float(tj._cool.get(-1, -1.0)), tj._played + 240.0), "the drop cools down 240 s")
	_ok(hud.side and hud.card_is(tj) and hud.card == "LIMITKA · PISTACJA" and hud.card_en == "Limited drop · PISTACJA", "the drop's card")
	_ok(hud.body == "Dropu jest tylko do 18:30. Znajomy chce pudełko, zanim się roztopi. Dowóz w 5 min." \
			and hud.body_en == "A friend wants a box before it melts. The drop ends at 18:30. 5 min to deliver." and hud.accent == GREEN, "the drop's words and green")
	_ok(jobs.picks[-1] == [500.0, 1800.0, tj.done * 6007 + 17], "the address picked from 500 to 1800 m with the drop's seed")
	var ring := _kerb_ring(a)
	_press(0)
	_ok(_toast("Limitka: stań w kolejce po pudełko", "Limited drop: join the queue for a box") and _ring_is(ring, GREEN, false), "ACCEPT: the toast, the green ring at the kerb")
	_by(ring, 3.0)
	_secs(1.0)
	_ok(_status("LIMITKA · KOLEJKA", "Stań w kolejce", "Wait in the queue") and absf(hud.progress - 0.2) < 0.02 and hud.tint == GREEN, "the queue's status: title, hint, bar by the hold over 5 s, green")
	_ok(_stays_stage(Trend.Stage.PICKUP, 3.9), "4.9 s in the queue: not yet")
	_ok(_until_stage(Trend.Stage.DELIVER, 0.2), "5.1 s in the queue: through")
	_ok(_toast("Ostatnie pudełko! Zanim się roztopi", "The last box! Before it melts"), "the last box's toast")
	_secs(0.5)
	_ok(_status("LIMITKA → %s" % pick["name"], "Jedź do zielonego światła", "Head for the green beacon") and hud.count == "4:59" and hud.tint == GREEN, "the way: title, the green beacon, 4:59")
	var m0 := wallet.money
	var r0 := wallet.respect
	_arrive()
	var road: float = pick["road"]
	var pay := 40 + roundi(10.0 * road / 1000.0) + 15
	_ok(wallet.money == m0 + pay and wallet.respect == r0 + 12, "on time: %d zł and 12 respect" % pay)
	_ok(hud.card == "LIMITKA · +%d zł" % pay and hud.card_en == "Limited drop · +%d zł" % pay, "the drop's result title")
	_ok(_one_of("„Jeszcze zimne i jeszcze pistacjowe. Zdjęcie zrobione, dziękuję!” · <c>\n+%d zł (napiwek 15 zł), +12 szacunku" % pay, FRIENDS, hud.body) \
			and hud.body_en.begins_with("\"Still cold and still pistachio. Photo taken, thank you!\"\n+%d zł (tip 15 zł), +12 respect" % pay), "the drop's line")
	_press(0)
	# Late.
	pick = _take_drop()
	_pick_up(5.0)
	tj._clock = 301.0
	m0 = wallet.money
	r0 = wallet.respect
	_arrive()
	road = pick["road"]
	var half := roundi((40 + roundi(10.0 * road / 1000.0)) * 0.5)
	_ok(wallet.money == m0 + half and wallet.respect == r0, "late: half the base (%d), no tip, no respect" % half)
	_ok(_one_of("„Roztopiło się. Wrzucę jako „vibe”.” · <c>\n+%d zł (napiwek 0 zł), +0 szacunku" % half, FRIENDS, hud.body) \
			and hud.body_en.begins_with("\"It melted. I'll post it as a \"vibe\".\"\n+%d zł (tip 0 zł), +0 respect" % half), "late: the melted line")
	_press(0)
	# Sold out in the queue.
	_take_drop()
	_by(tj.order["ring"], 3.0)
	_secs(1.0)
	m0 = wallet.money
	_hour(18.6, 5)
	_frame()
	_ok(_idle() and _toast("Wyprzedane! Drop się skończył.", "Sold out! The drop is over.") and wallet.money == m0, "the hour at 18.6 in the queue: idle, sold out, no pay")
	# With the test flag the drop goes on.
	_take_drop()
	tj.force_drop = true
	_hour(18.6, 5)
	_by(tj.order["ring"], 3.0)
	_ok(_stays_stage(Trend.Stage.PICKUP, 4.9) and _until_stage(Trend.Stage.DELIVER, 0.2), "force_drop: the queue goes on at 18.6 h")
	_abort()
	tj.force_drop = false
	_mark("E")


# --- F. czwarty ---------------------------------------------------------------------------------------

## Monday 17:30, the car 50 m from PADELNIA's door: the request up and taken. Returns the pick.
func _take_cz() -> Dictionary:
	_rested()
	_hour(17.5, 1)
	_at(PADEL + Vector2(0.0, 50.0))
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "the fourth player's card came")
	var pick: Dictionary = jobs.last.duplicate()
	_press(0)
	_ok(_in_stage(Trend.Stage.PICKUP), "ACCEPT started the fourth player's pickup")
	return pick


func _f_czwarty() -> void:
	_rig()
	_rested()
	_hour(16.9, 1)
	_at(PADEL + Vector2(0.0, 50.0))
	_ok(_quiet(1.1), "no fourth player at 16.9 h")
	_hour(17.5, 1)
	_at(PADEL + Vector2(0.0, 61.0))
	_ok(_quiet(1.1), "no fourth player from 61 m")
	_at(PADEL + Vector2(0.0, 50.0))
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "17:30, 50 m: the card")
	var a := _ans(PADEL)
	var pick: Dictionary = jobs.last.duplicate()
	var from := str(pick["name"])
	_ok(hud.side and hud.card_is(tj) and hud.card == "CZWARTY · PADELNIA" and hud.card_en == "Fourth player · PADELNIA" and hud.accent == TEAL, "the card, teal")
	_ok(_one_of("Grają we trzech. Zabierz <c> spod %s i dowieź na kort w 7 min." % from, CZ_PLAYERS, hud.body) \
			and _one_of("Three players are waiting. Fetch <c> from %s and bring them to the court in 7 min." % from, CZ_PLAYERS, hud.body_en), "the request's words")
	_ok(jobs.picks[-1] == [400.0, 1500.0, tj.done * 4001 + 29], "the player picked from 400 to 1500 m with the seed")
	_ok(_near(tj.order["ring"], pick["ring"]) and _near(tj.order["door_ring"], _kerb_ring(a)), "the pickup is the address, the delivery the court's kerb")
	_press(0)
	_ok(_toast("Czwarty: jedź po gracza", "Fourth player: go and fetch them") and _ring_is(pick["ring"], TEAL, false), "ACCEPT: the toast, the teal ring at the player's door")
	_frame()
	_ok(_status("CZWARTY · ODBIÓR", "Stań pod drzwiami gracza", "Stop at the player's door") and hud.tint == TEAL, "the pickup's status")
	_pick_up(1.5)
	_ok(_toast("Jest! Na kort, grają bez ciebie", "Got them! To the court, they're starting without you") and _ring_is(_kerb_ring(a), TEAL, true), "picked up: the toast, the ring at the court")
	_secs(0.5)
	_ok(_status("CZWARTY → PADELNIA", "Jedź do turkusowego światła", "Head for the teal beacon") and hud.count == "6:59" and hud.tint == TEAL, "the way: title, hint, 6:59")
	var m0 := wallet.money
	var r0 := wallet.respect
	_arrive()
	var road: float = pick["road"]
	var pay := 45 + roundi(8.0 * 2.0 * road / 1000.0) + 15
	_ok(wallet.money == m0 + pay and wallet.respect == r0 + 14, "on time: %d zł and 14 respect" % pay)
	_ok(hud.card == "CZWARTY · +%d zł" % pay and hud.card_en == "Fourth player · +%d zł" % pay, "the result's title")
	_ok(_one_of("„Jesteśmy w czterech! Ściana nas nie zje.” · <c>\n+%d zł (napiwek 15 zł), +14 szacunku" % pay, CZ_PLAYERS, hud.body) \
			and hud.body_en.begins_with("\"Four of us! The wall won't eat us.\"\n+%d zł (tip 15 zł), +14 respect" % pay), "the result's line")
	_press(0)
	# Late.
	pick = _take_cz()
	_pick_up(1.5)
	tj._clock = 421.0
	m0 = wallet.money
	r0 = wallet.respect
	_arrive()
	road = pick["road"]
	var half := roundi((45 + roundi(8.0 * 2.0 * road / 1000.0)) * 0.5)
	_ok(wallet.money == m0 + half and wallet.respect == r0, "late: half the base (%d), no tip, no respect" % half)
	_ok(_one_of("„Zagraliśmy w trzech. Piłka i tak wróciła.” · <c>\n+%d zł (napiwek 0 zł), +0 szacunku" % half, CZ_PLAYERS, hud.body) \
			and hud.body_en.begins_with("\"We played three-a-side. The ball came back anyway.\"\n+%d zł (tip 0 zł), +0 respect" % half), "late: the line")
	_press(0)
	_mark("F")


# --- G. the DESKA call ----------------------------------------------------------------------------------

const SCORES := [["2:6, 1:6", "2-6, 1-6"], ["4:6, 6:7", "4-6, 6-7"], ["6:4, 4:6, 10:8 w tie-breaku", "6-4, 4-6, 10-8 in the tie-break"], ["6:2, 6:3", "6-2, 6-3"]]
const END_LINES := [["Przegraliśmy, ale zdjęcie na story wyszło świetnie.", "We lost, but the story photo came out great."],
		["Przegraliśmy po walce. <h> z gipsem mówi, że to przez kort.", "We lost after a fight. <h> in plaster says it was the court."],
		["Wygrane w tie-breaku! <h> stuka gipsem w ławkę.", "Won in the tie-break! <h> bangs the cast on the bench."],
		["Wygrane! Bluza klubowa twoja. Od poniedziałku grasz z nami na stałe.", "We won! The club hoodie is yours. From Monday you're our regular fourth."]]
var _rally_won := {}
var _rally_lost := {}
var court: Array = []


## The DESKA call is due at hour `h` (a Monday): does it ring within `s` seconds? (Declines it if so.)
func _deski_try(h: float, s: float) -> bool:
	_hour(h, 1)
	_rested()
	tj._deski_at = tj._played
	if _until_phase(Activity.Phase.RING, s):
		_press(1)
		return true
	return false


## The caller of the call that rings now (from its card), or "".
func _caller() -> String:
	for c: String in FRIENDS:
		if hud.card == "📞 %s DZWONI" % c.to_upper():
			return c
	return ""


## The DESKA call rings now, answered, JADĘ! taken, the car at HOME: on the way to the gate. Returns
## the road the order should have (1.3 times the straight way from the car).
func _deska_go() -> float:
	_at(HOME)
	flying = false
	_secs(0.1)
	_rested()
	tj._deski_at = tj._played
	_ok(_until_phase(Activity.Phase.RING, 0.6), "the call rings")
	_press(0)
	_ok(_is_phase(Activity.Phase.OFFER) and _sub() == "offer", "ODBIERZ: the friend's card")
	_press(0)
	_ok(_in_stage(Trend.Stage.DELIVER), "JADĘ!: the way to the court")
	return 1.3 * Vector2(car.global_position.x, car.global_position.z).distance_to(GATE)


## The cards' match, point by point: `plan[i]` is "best", "wrong", "first" (the key) or "none" (left
## 25 s). Checks every card and the pay; returns the points won.
func _match(plan: Array, road: float, flew := false) -> int:
	var who := str(tj.order["customer"])
	var rl: Array = Trend.match_rallies(int(tj.order["seed"]))
	_ok(tj.order["rallies"] == rl and rl.size() == 3 and rl[0] != rl[1] and rl[1] != rl[2] and rl[0] != rl[2], "the rallies are match_rallies(seed): three different ones")
	var m0 := wallet.money
	var r0 := wallet.respect
	var d0: int = tj.done
	var won := 0
	var said := ""
	var said_en := ""
	for i in 3:
		var rally: Array = RALLY_WORDS[int(rl[i])]
		var lead := said + " "
		var lead_en := said_en + " "
		if i == 0:
			lead = "Pani Basia z recepcji: „Parking dla helikopterów jest od strony Wisły.” " if flew else "%s podaje ci rakietę. " % who
			lead_en = "Pani Basia from reception: \"The helicopter parking is on the river side.\" " if flew else "%s hands you a racket. " % who
		_ok(hud.card == "PADEL · PUNKT %d/3 · %d:%d" % [i + 1, won, i - won] and hud.card_en == "Padel · point %d/3 · %d-%d" % [i + 1, won, i - won], "point %d: the title and the score" % (i + 1))
		_ok(hud.body == lead + str(rally[0][0]) and hud.body_en == lead_en + str(rally[0][1]), "point %d (rally %d): the lead and the rally's words" % [i + 1, int(rl[i])])
		_ok(not hud.side and not hud.low and hud.card_is(tj) and hud.accent == TEAL \
				and hud.button_words == PackedStringArray(["LOB|Lob", "ZE ŚCIANY|OFF THE GLASS", "SMECZ|SMASH"]), "point %d: in the middle, its own, teal, three shots" % (i + 1))
		_ok(int(rally[1]) == BEST[int(rl[i])], "rally %d: the best shot is %d" % [int(rl[i]), BEST[int(rl[i])]])
		var shot := 0
		match str(plan[i]):
			"best":
				shot = BEST[int(rl[i])]
			"wrong":
				shot = (BEST[int(rl[i])] + 1) % 3
			"first":
				shot = 0
			_:
				shot = -1
		var win: bool = shot == int(BEST[int(rl[i])])
		if i == 0:
			_abort()
			_ok(hud.card_is(tj) and _sub() == "match", "the ✕ does nothing during the match")
		if shot < 0:
			_ok(_stays_stage(Trend.Stage.RESULT, 24.9) and _sub() == "match" and hud.card.begins_with("PADEL · PUNKT %d/3" % (i + 1)), "a point left 24.9 s is still up, on its own card")
			_secs(0.2)
		elif str(plan[i]) == "first":
			_ok(tj.primary(), "primary() plays the first shot")
		else:
			_press(shot)
		if win:
			won += 1
			_rally_won[int(rl[i])] = true
			said = str(rally[2][0])
			said_en = str(rally[2][1])
		else:
			if shot >= 0:
				_rally_lost[int(rl[i])] = true
			said = str(rally[3][0]) if shot >= 0 else "Piłka przeleciała obok. Rywale nawet nie czekali."
			said_en = str(rally[3][1]) if shot >= 0 else "The ball went by. The other pair didn't wait."
	var zl := 45 + roundi(8.0 * 2.0 * road / 1000.0) + 15 + 6 * won
	var resp := 14 + 2 * won + (5 if flew else 0)
	var sc: Array = SCORES[won]
	_ok(hud.card == "PADEL · %s · +%d zł" % [sc[0], zl] and hud.card_en == "Padel · %s · +%d zł" % [sc[1], zl], "the result's title: the score line of %d points and %d zł" % [won, zl])
	_ok(not hud.side and hud.card_is(tj) and hud.button_words == PackedStringArray(["OK"]) and _in_stage(Trend.Stage.RESULT), "the result in the middle, its own, OK")
	var body_ok := false
	var en_ok := false
	for h: String in INJURED:
		var line_pl := str(END_LINES[won][0]).replace("<h>", h)
		var line_en := str(END_LINES[won][1]).replace("<h>", h)
		if hud.body == "%s\n„%s” · %s\n+%d zł (napiwek 15 zł, punkty %d zł), +%d szacunku" % [said, line_pl, who, zl, 6 * won, resp]:
			body_ok = true
		if hud.body_en == "%s\n\"%s\"\n+%d zł (tip 15 zł, points %d zł), +%d respect" % [said_en, line_en, zl, 6 * won, resp]:
			en_ok = true
	_ok(body_ok and en_ok, "the result's body: the last point's words, the end line, the pay")
	_ok(wallet.money == m0 + zl and wallet.respect == r0 + resp and tj.done == d0 + 1, "paid %d zł and %d respect, one more job done" % [zl, resp])
	return won


func _g_deska() -> void:
	_rig()
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.6)
	_ok(_deski_try(8.0, 0.6), "the call rings at 8.0 h")
	_ok(not _deski_try(7.9, 1.1), "no call at 7.9 h")
	_ok(not _deski_try(22.0, 1.1), "no call at 22.0 h")
	_ok(_deski_try(12.0, 0.6), "the call rings at noon")
	# A mission, 20 s after it, a rescue call ringing, no word from the message director, by the court.
	_hour(12.0, 1)
	_rested()
	tj._deski_at = tj._played
	mission = true
	_ok(_quiet(1.1), "no call during a mission")
	mission = false
	_ok(_quiet(19.0), "no call for 19 s after a mission")
	_ok(_until_phase(Activity.Phase.RING, 1.6), "the call rings once the 20 s are over")
	_press(1)
	_rested()
	tj._deski_at = tj._played
	calls.put(Activity.Phase.RING)
	_ok(_quiet(1.1), "no call while a rescue call rings")
	calls.put(Activity.Phase.IDLE)
	_ok(_until_phase(Activity.Phase.RING, 0.6), "the call rings when the rescue line is quiet")
	_press(1)
	_rested()
	tj._deski_at = tj._played
	hud.calls_ok = false
	_ok(_quiet(1.1), "no call when the message director says no")
	hud.calls_ok = true
	_ok(_until_phase(Activity.Phase.RING, 0.6), "the call rings when the message director agrees")
	_press(1)
	_rested()
	tj._deski_at = tj._played
	_at(GATE + Vector2(0.0, 249.0))
	_ok(_quiet(1.1), "no call within 250 m of the gate")
	_at(GATE + Vector2(0.0, 251.0))
	tj._deski_at = tj._played
	_ok(_until_phase(Activity.Phase.RING, 0.6), "the call rings from 251 m")
	_press(1)
	# Ringing.
	_at(HOME)
	_rested()
	tj._deski_at = tj._played
	_ok(_until_phase(Activity.Phase.RING, 0.6), "rings")
	var who := _caller()
	_ok(who != "", "the caller is one of the six")
	_ok(tj.phase == Activity.Phase.RING and not tj.busy() and tj.idle() == false and hud.card == "📞 %s DZWONI" % who.to_upper(), "RING, not busy, the call's title")
	_ok(hud.body == BIOS[who][0] and hud.body_en == BIOS[who][1] and hud.face == Trend._deski_face(who) and hud.accent == TEAL and hud.card_is(tj) and hud.side, "the caller's bio, face, teal, its own, beside the road")
	_ok(is_equal_approx(tj._deski_at, tj._played + 1200.0), "the next call is 1200 s away")
	_press(1)
	_ok(_idle(), "ODRZUĆ: idle")
	_rested()
	tj._deski_at = tj._played
	_ok(_until_phase(Activity.Phase.RING, 0.6) and tj.secondary() and _idle(), "secondary() declines the call")
	_rested()
	tj._deski_at = tj._played
	_ok(_until_phase(Activity.Phase.RING, 0.6) and _stays(Activity.Phase.RING, 9.9) and _until_idle(0.2), "nobody answers: it goes after 10 s")
	# Answered.
	_rested()
	tj._deski_at = tj._played
	_ok(_until_phase(Activity.Phase.RING, 0.6), "rings again")
	who = _caller()
	var face := str(hud.face)
	_press(0)
	_ok(_is_phase(Activity.Phase.OFFER) and _sub() == "offer", "ODBIERZ: the offer, stage offer")
	_ok(hud.card == "%s: „BRAKUJE CZWARTEGO!”" % who.to_upper() and hud.card_en == "%s: \"We need a fourth!\"" % who, "the friend's card title")
	_ok(_one_of("„Halo? Gramy na Desce w padla, a <c> ma nogę w gipsie po pole dance i wypadło z gry! Dojedź albo doleć na kort przy Zaruskiego, 8 minut. Kort opłacony do pełnej godziny!”", INJURED, hud.body) \
			and _one_of("\"Hello? We're playing padel at DESKA, but <c> has a leg in plaster after pole dance and dropped out! Drive or fly to the court on Zaruskiego, 8 minutes. The court is paid till the hour!\"", INJURED, hud.body_en), "the friend's words name the injured and 8 minutes")
	_ok(hud.button_words == PackedStringArray(["JADĘ!|ON MY WAY", "NIE DZIŚ|NOT TODAY"]) and hud.face == face, "the buttons, the same face")
	_press(1)
	_ok(_idle(), "NIE DZIŚ: idle")
	var c0 := calls.closed
	var road := _deska_go()
	var gr := _terrain(GATE)
	_ok(tj.has_target() and _near(tj.target_position(), gr) and _ring_is(gr, TEAL, true), "JADĘ!: the target is the gate at the terrain height, the ring teal and waving")
	_ok(_toast("Czwarty: na kort Deski, jedź albo leć", "Fourth player: to the DESKA court, drive or fly") and calls._held() and calls.closed == c0 + 1, "the toast, the rescue line paused and closed")
	_ok(tj.padel_busy() and not tj.padel_idle(), "padel_busy() from JADĘ! on")
	_ok(is_equal_approx(float(tj.order["road"]), road), "the road is 1.3 times the straight way at the call")
	_secs(0.5)
	_ok(_status("CZWARTY → WTS DESKA", "Jedź lub leć do turkusowego światła", "Drive or fly to the teal beacon") and hud.count == "7:59" and hud.tint == TEAL, "the way: title, hint, 7:59")
	_by(gr, 200.0, 12.0)
	_ok(_stays_stage(Trend.Stage.DELIVER, 0.5) and not tj.primary(), "not at the court from 200 m")
	# By car: the match on cards, one point won, one lost, one left.
	_by(gr, 3.0)
	_frame()
	_ok(_in_stage(Trend.Stage.RESULT) and _sub() == "match", "at the court on time: the match")
	_ok(_match(["best", "wrong", "none"], road) == 1, "the match by car: one point")
	_press(0)
	_ok(_idle() and not tj.padel_busy(), "OK closes the match")
	# The key plays the first shot; the card closes by itself after 10 s.
	road = _deska_go()
	_by(gr, 3.0)
	_frame()
	_ok(_sub() == "match", "the second match")
	_match(["first", "first", "first"], road)
	_ok(_stays_stage(Trend.Stage.RESULT, 9.9) and _until_idle(0.2), "the match's card closes by itself after 10 s")
	# By air: 29 m is not there, 27 m is; three best shots; the receptionist's remark.
	road = _deska_go()
	flying = true
	heli = Vector3(gr.x + 29.0, 50.0, gr.z)
	_ok(_stays_stage(Trend.Stage.DELIVER, 0.5), "in the air 29 m from the gate: not there")
	heli = Vector3(gr.x + 27.0, 50.0, gr.z)
	_frame()
	flying = false
	_ok(_in_stage(Trend.Stage.RESULT) and _sub() == "match", "in the air 27 m from the gate: the match")
	_ok(_match(["best", "best", "best"], road, true) == 3, "three best shots win the match from the air")
	_press(0)
	# Late.
	road = _deska_go()
	who = str(tj.order["customer"])
	_by(gr, 200.0, 12.0)
	tj._clock = 481.0
	_secs(0.5)
	_by(gr, 3.0)
	_frame()
	var half := roundi((45 + roundi(8.0 * 2.0 * road / 1000.0)) * 0.5)
	_ok(_in_stage(Trend.Stage.RESULT) and _sub() == "offer" and hud.side and hud.card == "CZWARTY · +%d zł" % half and hud.card_en == "Fourth player · +%d zł" % half, "late at the court: no match, the card beside the road, half the base")
	_ok(hud.body == "„Zagraliśmy w trzech, ale piłka i tak wróciła. Dzięki, że dojechałeś.” · %s\n+%d zł (napiwek 0 zł), +0 szacunku" % [who, half] \
			and hud.body_en == "\"We played three-a-side, the ball came back anyway. Thanks for coming.\"\n+%d zł (tip 0 zł), +0 respect" % half, "late at the court: the line")
	_press(0)
	# On the court.
	tj.enter_padel = func(d: Dictionary) -> void: court.append(d)
	_hour(18.25, 1)
	var wins := [[2, 0, {"your_hits": 7, "longest": 5, "smashes": 2}, 3], [2, 1, {"your_hits": 20, "longest": 11}, 2], [1, 2, {}, 1], [0, 2, {}, 0]]
	for w: Array in wins:
		court.clear()
		road = _deska_go()
		who = str(tj.order["customer"])
		_by(gr, 3.0)
		_frame()
		_ok(court.size() == 1 and court[0]["partner"] == who and court[0]["rivals"] == ["Prezes", "Zbyszek"] and court[0]["flew"] == false \
				and court[0]["seed"] == tj.order["seed"] and is_equal_approx(float(court[0]["hour"]), 18.25), "the court is entered once with the partner, the rivals, flew, the seed and the hour")
		_ok(_sub() == "arcade" and hud.card == "" and tj.busy() and not tj.has_target(), "on the court: stage arcade, no card, busy, no target")
		_abort()
		_ok(_sub() == "arcade", "the ✕ does nothing on the court")
		var m0 := wallet.money
		var r0 := wallet.respect
		tj.arcade_done(int(w[0]), int(w[1]), w[2])
		var won: int = w[3]
		var zl := 45 + roundi(8.0 * 2.0 * road / 1000.0) + 15 + 6 * won
		_ok(hud.card == "PADEL · gemy %d:%d · +%d zł" % [w[0], w[1], zl] and hud.card_en == "Padel · games %d-%d · +%d zł" % [w[0], w[1], zl], "the court's end %d:%d pays as %d points (%d zł)" % [w[0], w[1], won, zl])
		_ok(wallet.money == m0 + zl and wallet.respect == r0 + 14 + 2 * won, "the court's pay and respect")
		if int(w[0]) == 2 and int(w[1]) == 0:
			_ok(hud.body.begins_with("Twoje uderzenia: 7, najdłuższa wymiana: 5. Smecze: 2."), "the court's stats line")
		_press(0)
	tj.arcade_done(2, 0, {})
	_ok(_idle() and hud.card == "", "arcade_done while idle does nothing")
	tj.enter_padel = Callable()
	# Every line of the rallies: play matches until each is a point won and a point lost.
	var k := 0
	while k < 40 and (_rally_won.size() < 5 or _rally_lost.size() < 5):
		road = _deska_go()
		_by(gr, 3.0)
		_frame()
		_match(["best" if (k % 2) == 0 else "wrong", "wrong" if (k % 3) == 0 else "best", "best" if (k % 2) == 1 else "wrong"], road)
		_press(0)
		k += 1
	_ok(_rally_won.size() == 5 and _rally_lost.size() == 5 and Trend.RALLIES.size() == 5, "every rally was played, won and lost (%d matches)" % k)
	# The quest map's hooks.
	_at(HOME)
	_secs(0.1)
	_rested()
	_ok(tj.padel_idle() == tj.idle() and tj.padel_ring() and _is_phase(Activity.Phase.RING), "padel_ring() from idle rings")
	_ok(not tj.padel_ring() and not tj.padel_meet() and _is_phase(Activity.Phase.RING), "padel_ring() and padel_meet() are false while it rings")
	_press(1)
	c0 = calls.closed
	flying = false
	_ok(tj.padel_meet() and _in_stage(Trend.Stage.RESULT) and _sub() == "match" and hud.card.begins_with("PADEL · PUNKT 1/3") and not tj.order["flew"], "padel_meet() from idle: the match at once, on cards")
	_ok(calls._held() and calls.closed == c0 + 1 and tj.padel_busy(), "met: the rescue line paused and closed, padel_busy()")
	_press(0)
	_press(0)
	_press(0)
	_press(0)
	_ok(_idle() and not tj.padel_busy(), "the met match ended")
	flying = true
	heli = Vector3(HOME.x, 50.0, HOME.y)
	_frame()
	_ok(tj.padel_meet() and tj.order["flew"] == true and hud.body.begins_with("Pani Basia z recepcji"), "padel_meet() in the air: the order says it flew, the receptionist remarks")
	flying = false
	for i in 4:
		_press(0)
	_ok(_idle(), "the met match from the air ended")
	tj.enter_padel = func(d: Dictionary) -> void: court.append(d)
	court.clear()
	_ok(tj.padel_meet() and court.size() == 1 and _sub() == "arcade" and hud.card == "", "padel_meet() with a court: onto the court, no card")
	tj.arcade_done(2, 0, {})
	_press(0)
	tj.enter_padel = Callable()
	# padel_busy() never during a slot's run.
	_ok(tj.offer(0), "a slot's request")
	_press(0)
	_ok(tj.busy() and not tj.padel_busy() and not tj.kawa_busy(), "padel_busy() is false during a slot's run")
	_abort()
	_mark("G")


# --- H. mlask -------------------------------------------------------------------------------------------

## The fans' lines seen since the last look: each is one draw of the dice, the mirror draws it too.
func _watch_fans() -> void:
	while _said_n < dlg.said.size():
		if dlg.said[_said_n] == "viral:mrozulo":
			var gap := _mirror.randf_range(14.0, 26.0)
			_fan_lines += 1
			_ok(is_equal_approx(tj._fan_t, gap) and gap >= 14.0 and gap <= 26.0, "a fan's line sets the next gap to the dice's next draw (%.3f / %.3f)" % [tj._fan_t, gap])
			_ok(dlg.hows[_said_n] == [4.0, ORANGE, 2.2, true], "a fan's line is 4 s, orange, 2.2 high, preferred")
		_said_n += 1


## A Mlask run from Mrożulo's request (the car 20 m from his ring) to the sticker's result card.
## `cold`: the bring takes over 300 s; `late`: the sticker takes over 240 s. Checks the pay.
func _mlask_run(cold: bool, late: bool, close_by_clock := false) -> void:
	_rested()
	var vr: Vector3 = tj.van["ring"]
	_by(vr, 20.0)
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "Mrożulo's request at 20 m")
	var place := _kerb_ring(_ans(SLOT_A))
	_press(0)
	_ok(_in_stage(Trend.Stage.PICKUP) and _toast("Mlask: na wynos dla Mrożula", "Smack: a takeaway for Mrożulo") and _ring_is(place, ORANGE, false), "ACCEPT: the toast, the orange ring at the new place")
	_frame()
	_ok(_status("MLASK · DUBAJSKA", "Stań przy kolejce", "Stop by the queue") and hud.tint == ORANGE, "the pickup's status")
	_pick_up(1.5)
	_ok(_toast("Kolejka przepuszcza: to dla Mrożula! Wieź, póki ciepłe", "The queue lets you through: it's for Mrożulo! Bring it warm") and _ring_is(vr, ORANGE, true), "picked up: the toast, the ring at the van")
	_secs(0.5)
	_ok(_status("MLASK → MROŻULO", "Do vana Mrożula, póki ciepłe", "To Mrożulo's van while it's warm") and hud.count == "4:59" and hud.tint == ORANGE, "the way to the van: title, hint, 4:59")
	tj._clock = 301.0
	_frame()
	_ok(_status("MLASK → MROŻULO", "Stygnie… jedź dalej", "It's going cold… keep going") and hud.tint == RED, "past 300 s: it's going cold, in red")
	tj._clock = 301.0 if cold else 10.0
	var m0 := wallet.money
	var r0 := wallet.respect
	_arrive()
	_ok(_sub() == "review" and hud.side and hud.card_is(tj), "at the van: the review card beside the road")
	var gw: Array = ["3 MLASKI", "3 SMACKS"]
	if not cold:
		var idx := _mirror.randi() % 5
		gw = GRADE_WORDS[idx]
	_ok(hud.card == "RECENZJA · %s" % gw[0] and hud.card_en == "Review · %s" % gw[1], "the review's grade by the dice: %s" % gw[0])
	_ok(hud.body == "„WIRAL PL”\nZawieź naklejkę do DUBAJSKA w 4 min." and hud.body_en == "\"VIRAL EN\"\nTake the sticker to DUBAJSKA in 4 min." \
			and hud.button_words == PackedStringArray(["NAKLEJKA"]), "the review's words and its one button")
	_ok(dlg.line_asks[-1] == "mrozulo_review:%s" % ("cold" if cold else "warm"), "the review asks the bag for the %s line" % ("cold" if cold else "warm"))
	_ok(_stays_stage(Trend.Stage.RESULT, 30.0) and hud.card_is(tj) and wallet.money == m0, "the review never closes by itself, and nothing is paid yet")
	_press(0)
	_ok(_in_stage(Trend.Stage.DELIVER) and _sub() == "sticker" and _near(tj.target_position(), place), "NAKLEJKA: the sticker's leg, the place is the target again")
	_ok(_toast("Naklejka MLASK: do DUBAJSKA", "The MLASK sticker: to DUBAJSKA"), "the sticker's toast")
	_secs(0.5)
	_ok(_status("MLASK → DUBAJSKA", "Stań przy drzwiach", "Stop at the door") and hud.count == "3:59", "the sticker's way: title, hint, 3:59")
	tj._clock = 241.0 if late else 10.0
	var b0 := crowds.boosts.size()
	var d0: int = tj.done
	_arrive()
	var road := 1.3 * _flat(vr, place)
	var base := 40 + roundi(10.0 * 2.0 * road / 1000.0)
	var good := not cold and not late
	var zl := (base + 15) if good else roundi(base * 0.5)
	_ok(wallet.money == m0 + zl and wallet.respect == r0 + (15 if good else 0) and tj.done == d0 + 1, "the pay: %d zł, %d respect (%s)" % [zl, 15 if good else 0, "base + tip" if good else "half"])
	_ok(crowds.boosts.size() == b0 + 1 and crowds.boosts[-1] == "wiralek_zbawiciela", "the queue grows at the slot's site, whatever the pay")
	_ok(hud.card == "MLASK · +%d zł" % zl and hud.card_en == "Smack · +%d zł" % zl and dlg.line_asks[-1] == "mrozulo_owner:", "the result's title, the owner's line asked")
	_ok(hud.body == "„WIRAL PL” · DUBAJSKA\n%s · +%d zł (napiwek %d zł), +%d szacunku" % [gw[0], zl, 15 if good else 0, 15 if good else 0] \
			and hud.button_words == PackedStringArray(["OK"]), "the result's body with the grade")
	if close_by_clock:
		_ok(_stays_stage(Trend.Stage.RESULT, 9.9) and _until_idle(0.2), "the result closes by itself after 10 s")
	else:
		_press(0)
		_ok(_idle(), "OK closes the result")


func _h_mlask() -> void:
	_rig()
	_mirror = RandomNumberGenerator.new()
	_mirror.seed = SEED
	_mirror_on = true
	_fan_lines = 0
	_ok(tj._fan_t == 8.0, "the first fan's line is 8 s away")
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.6)
	# The van's hours and its spot by the weekday.
	_ok(tj._van_node.visible and tj.van["spot"] == "hala_koszyki", "Monday noon: the van at hala_koszyki")
	_hour(10.9, 1)
	_secs(0.6)
	_ok(not tj._van_node.visible, "the van is hidden at 10.9 h")
	_hour(21.0, 1)
	_secs(0.6)
	_ok(not tj._van_node.visible, "the van is hidden at 21.0 h")
	_hour(12.0, 1)
	_secs(0.6)
	for e: Array in [[1, "hala_koszyki"], [2, ""], [3, ""], [4, "plac_zbawiciela"], [5, "hala_koszyki"], [6, ""], [7, ""]]:
		_hour(12.0, int(e[0]))
		_secs(0.6)
		_ok(str(tj.van.get("spot", "")) == str(e[1]), "weekday %d: the van's spot is '%s' (no road or kerb for the others)" % [e[0], e[1]])
	# Its ring 2 m and its node 4.4 m off the kerb's centre; the node at the ground height.
	_hour(12.0, 1)
	jobs.answers.clear()
	tj._van_day = -1
	_secs(0.6)
	var va: Dictionary = jobs.answers[0]
	var c: Vector2 = va["centre"]
	var side: Vector2 = va["side"]
	var node_at := Vector3(c.x + side.x * 4.4, _smap.ground_height(c.x + side.x * 4.4, c.y + side.y * 4.4), c.y + side.y * 4.4)
	_ok(_near(tj.van["ring"], _kerb_ring(va)) and _near(tj.van["at"], node_at) and _near(tj._van_node.global_position, node_at), "the van's ring is 2 m and its node 4.4 m off the kerb's centre, the node at the ground height")
	var vr: Vector3 = tj.van["ring"]
	var at: Vector3 = tj.van["at"]
	# The reach: 31 m no, 29 m yes; the words; the cool-down; the stage.
	_rested()
	_by(vr, 31.0)
	_ok(_quiet(1.1), "no request from 31 m")
	_by(vr, 29.0)
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "Mrożulo's request from 29 m")
	_ok(hud.side and hud.card_is(tj) and hud.card == "MLASK · MROŻULO" and hud.card_en == "Smack · Mrożulo" and hud.accent == ORANGE, "the request's title and orange")
	_ok(hud.body == "Siema, tu Mrożulo! DUBAJSKA, nowe miejsce. Weź mi coś, tylko ma być ciepłe." \
			and hud.body_en == "Hi, Mrożulo here! DUBAJSKA, a new place. Grab me something, and keep it warm.", "the request's words name the new place")
	_ok(is_equal_approx(float(tj._cool.get(-3, -1.0)), tj._played + 300.0) and _sub() == "fetch", "the van cools down 300 s, the stage is fetch")
	_ok(_near(tj.order["ring"], _kerb_ring(_ans(SLOT_A))), "the new place is the nearest open slot on its days 1 to 3")
	_press(1)
	# On a slot's day 4 the new place is KUKŁA's nearer door.
	life.slots_now[0]["day"] = 4
	_rested()
	_by(vr, 20.0)
	_ok(_until_phase(Activity.Phase.OFFER, 0.6) and "KUKŁA, nowe miejsce" in hud.body and tj.order["site"] == "kukla_marszalkowska", "slot A on day 4: KUKŁA's nearer door")
	_press(1)
	var ids := crowds.by_id.duplicate()
	crowds.by_id.erase(Crowds.KUKLA[0])
	crowds.by_id.erase(Crowds.KUKLA[1])
	_rested()
	_ok(_quiet(1.1), "no place open and no crowds site: no request")
	crowds.by_id = ids
	life.slots_now[0]["day"] = 2
	# The fans: a line after 8 s within 22 m, then by the dice; none from 23 m. The egg.
	tj._cool[-3] = 1.0e9
	tj._fan_t = 8.0
	_by(at, 15.0)
	var n0 := _fan_lines
	_secs(7.4)
	_ok(_fan_lines == n0, "no fan's line before 8 s")
	_secs(1.2)
	_ok(_fan_lines == n0 + 1, "a fan's line after 8 s within 22 m")
	var n1 := _fan_lines
	_by(at, 23.0)
	_secs(30.0)
	_ok(_fan_lines == n1, "no fan's line from 23 m")
	eggs.clear()
	tj._egg_t = 0.0
	_by(at, 10.0)
	_secs(4.0)
	_ok(eggs.is_empty(), "no egg from 10 m")
	_at(Vector2(at.x + 8.5, at.z), 2.0)
	_secs(4.0)
	_ok(eggs.is_empty(), "no egg at 2 m/s")
	_at(Vector2(at.x + 8.5, at.z))
	_secs(2.4)
	_ok(eggs.is_empty(), "no egg before 3 s")
	_secs(1.2)
	_ok(eggs == ["easter_mlask"], "the egg after 3 s within 9 m")
	_secs(20.0)
	_ok(eggs == ["easter_mlask"], "the egg comes once however long the car stays")
	tj._cool.erase(-3)
	# The runs: warm and on time; cold; warm with a late sticker.
	_mlask_run(false, false)
	_mlask_run(true, false)
	_mlask_run(false, true, true)
	_ok(tj._rng.state == _mirror.state, "the dice: the job's rng is where the mirror is after the fans' gaps and the grades")
	_mirror_on = false
	_mark("H")


# --- I. dzemini -----------------------------------------------------------------------------------------

func _dz_due() -> void:
	_rested()
	tj._dz_at = tj._played


func _i_dzemini() -> void:
	_rig()
	_hour(12.0, 4)
	_at(HOME)
	_secs(0.6)
	# The gates: the van away, a mission and its 20 s.
	_dz_due()
	_hour(10.9, 4)
	_ok(_quiet(1.1), "no call with the van away (10.9 h)")
	_hour(12.0, 4)
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "the call at noon")
	_press(1)
	_dz_due()
	mission = true
	_ok(_quiet(1.1), "no call during a mission")
	mission = false
	_ok(_quiet(19.0), "no call for 19 s after a mission")
	_ok(_until_phase(Activity.Phase.OFFER, 1.6), "the call once the 20 s are over")
	_ok(not hud.card.is_empty(), "the call card is up")
	_ok(hud.side and hud.card_is(tj) and hud.card == "📞 MROŻULO DZWONI" and hud.card_en == "Mrożulo is calling" and tj.phase == Activity.Phase.OFFER, "Mrożulo's call is a request card")
	_ok(hud.body == "„Siema, tu Mrożulo! Na Świętokrzyskiej otworzyli DŻEMINI KEBAB, mięso kroi agent AI. Kup mi jednego i przywieź do vana, póki ciepły!”" \
			and hud.body_en == "\"Hi, Mrożulo here! DŻEMINI KEBAB just opened on Świętokrzyska, an AI agent carves the meat. Get me one and bring it to my van while it's warm!\"", "the call's words")
	_ok(hud.button_words == PackedStringArray(["JADĘ", "NIE TERAZ"]) and hud.face == "Mrożulo" and hud.accent == ORANGE and is_equal_approx(tj._dz_at, tj._played + 900.0), "the buttons, his face, orange, the next call 900 s away")
	_press(1)
	# Not when quiet (unforced), nor with no kerb by the shop (forced).
	tj.quiet = true
	_rested()
	_ok(not tj.offer_dzemini() and _idle(), "offer_dzemini() while quiet: false")
	tj.quiet = false
	jobs.no_kerb.append(DZEMINI)
	_ok(not tj.offer_dzemini(true) and _idle(), "offer_dzemini(true) with no kerb by the shop: false")
	jobs.no_kerb.erase(DZEMINI)
	# The warm run, the wall not there yet.
	_dz_due()
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "the call again")
	var shop := _kerb_ring(_ans(DZEMINI))
	var m0 := wallet.money
	var r0 := wallet.respect
	_press(0)
	_ok(_in_stage(Trend.Stage.PICKUP) and _toast("Dżemini: kebab dla Mrożula, Świętokrzyska", "Dżemini: a kebab for Mrożulo, on Świętokrzyska") and _ring_is(shop, ORANGE, false), "JADĘ: the toast, the orange ring at the shop's kerb")
	_frame()
	_ok(_status("DŻEMINI · ODBIÓR", "Stań przy kolejce", "Stop by the queue"), "the pickup's status")
	_pick_up(1.5)
	_ok(_toast("Agent: „Na pewno kebab? Mogę też napisać o nim wiersz.”", "The agent: \"Sure about the kebab? I can also write a poem about it.\""), "picked up: the agent's toast")
	_secs(0.5)
	_ok(_status("DŻEMINI → MROŻULO", "Do vana Mrożula, póki ciepłe", "To Mrożulo's van while it's warm"), "the way: DŻEMINI → MROŻULO")
	var vr: Vector3 = tj.van["ring"]
	fronts.placed = false
	_arrive()
	var road := 1.3 * _flat(shop, vr)
	var pay := 60 + roundi(10.0 * road / 1000.0) + 20
	_ok(wallet.money == m0 + pay and wallet.respect == r0 + 25 and tj.dz_done and wallet.keep.get("dzemini_mlask", false) == true and crowds.mlasks == 1, "the bite: %d zł, 25 respect, done, kept in the save, the crowds told" % pay)
	_ok(_sub() == "review" and hud.side and hud.card == "MROŻULO · +%d zł" % pay and hud.card_en == "Mrożulo · +%d zł" % pay, "the bite's card")
	_ok(hud.body == "„*mlask* … Wjeżdżam w to.”\n+%d zł (napiwek 20 zł), +25 szacunku" % pay and hud.body_en == "\"*smack* … I'm going in.\"\n+%d zł (tip 20 zł), +25 respect" % pay, "the bite's words")
	_ok(_stickers() == 0, "no sticker while the wall is not there")
	fronts.placed = true
	_secs(0.6)
	var wall: Vector3 = fronts.venue_wall("dzemini_kebab")["p"]
	var sticker := _sticker_node()
	_ok(_stickers() == 1 and sticker != null and sticker.global_position.distance_to(wall) < 5.0, "the sticker is on the wall within 0.6 s of it being there")
	_press(0)
	_ok(_sub() == "tygram" and tj.busy() and hud.side and hud.card == "TYGRAM · MROŻULO" and hud.card_en == "TYGRAM · Mrożulo" and hud.accent == BLUE, "OK: the TYGRAM card in blue, still busy")
	_ok(hud.body == "„DŻEMINI: MLASK! Naklejka już wisi na szybie. Jutro kolejka do Marszałkowskiej. Dzięki, kierowco!”" \
			and hud.body_en == "\"DŻEMINI: SMACK! The sticker's on the window. Tomorrow the queue reaches Marszałkowska. Thanks, driver!\"", "the TYGRAM text")
	_press(0)
	_ok(_idle(), "OK: idle")
	# Not once done.
	_at(HOME)
	_dz_due()
	_ok(_quiet(1.1), "Mrożulo does not ring again once the MLASK is on DŻEMINI")
	# Forced again, cold, the TYGRAM card by the clock; the van stays shown out of its hours.
	_rested()
	_ok(tj.offer_dzemini(true), "the forced call")
	_press(0)
	_hour(22.0, 4)
	_pick_up(1.5)
	_secs(0.6)
	_ok(tj._van_node.visible, "the van stays shown through a Dżemini run out of its hours")
	tj._clock = 301.0
	m0 = wallet.money
	r0 = wallet.respect
	_arrive()
	var half := roundi((60 + roundi(10.0 * 1.3 * _flat(_kerb_ring(_ans(DZEMINI)), vr) / 1000.0)) * 0.5)
	_ok(wallet.money == m0 + half and wallet.respect == r0 and crowds.mlasks == 2, "cold: half the base (%d), no tip, no respect, the MLASK all the same" % half)
	_ok(hud.body == "„Letni, ale… *mlask* … wjeżdżam w to.”\n+%d zł (napiwek 0 zł), +0 szacunku" % half \
			and hud.body_en == "\"Lukewarm, but… *smack* … I'm going in.\"\n+%d zł (tip 0 zł), +0 respect" % half, "cold: the lukewarm line")
	_ok(_stays_stage(Trend.Stage.RESULT, 9.9) and _sub() == "review", "the bite's card is still up 9.9 s after")
	_secs(0.2)
	_ok(_sub() == "tygram", "the TYGRAM card after 10 s")
	_ok(_stays_stage(Trend.Stage.RESULT, 9.7) and _until_idle(0.6), "and the TYGRAM card closes by itself after 10 s")
	_mark("I")


## The MLASK sticker's node, or null.
func _sticker_node() -> Node3D:
	var l := _sticker_nodes()
	return null if l.is_empty() else l[0] as Node3D


# --- J. the coffee run ------------------------------------------------------------------------------------

const DOCK := Vector2(284.7, -805.8)
const STOP_DOORS := [Vector2(178.1, -769.8), Vector2(120.0, -600.0), Vector2(49.0, -326.6), Vector2(378.9, -595.7)]
const VENUES := ["kawa_kropka", "glon_dobra", "kawa_storczyk", "kawa_mantra"]


## Zuzia's call is due at hour `h` with the car at `p`: does it come within `s` seconds? (Declines it.)
func _kawa_try(h: float, p: Vector2, s: float) -> bool:
	_hour(h, 1)
	_at(p)
	_rested()
	tj._kawa_at = tj._played
	if _until_phase(Activity.Phase.OFFER, s):
		_press(1)
		return true
	return false


## The glows over the cafés that are up now (quads in the world).
func _glows() -> Array:
	var out: Array = []
	for ch: Node in world.get_children():
		if ch is MeshInstance3D and (ch as MeshInstance3D).mesh is QuadMesh and not ch.is_queued_for_deletion():
			out.append(ch)
	return out


## Is the one glow up over café `i`'s wall?
func _glow_over(i: int) -> bool:
	var g := _glows()
	if g.size() != 1:
		return false
	var w: Dictionary = fronts.venue_wall(VENUES[i])
	return _near((g[0] as Node3D).global_position, (w["p"] as Vector3) + Vector3.UP * 1.45 + (w["n"] as Vector3) * 0.16)


## From JADĘ (the dock leg) to the dock again: the dock, the bike, four stamps, the way back. `short`:
## the café where the wallet is empty (-1: none); `late`: the clock past 240 s at the last café.
func _kawa_ride(late: bool, glow_after_wall: bool) -> void:
	var dock := _terrain(DOCK)
	var m_start := wallet.money
	var d0: int = tj.done
	var n_models := car.models.size()
	var resets0 := car.resets
	var copies0 := car.copies
	_by(dock, 200.0, 12.0)
	_ok(_stays_stage(Trend.Stage.DELIVER, 0.5) and _sub() == "dock", "the dock is not reached from 200 m")
	_ok(_status("KAWOWY RAJD → ROWERILO", "Jedź do brązowego światła: stacja ROWERILO", "Head for the brown beacon: the ROWERILO dock") and hud.count == "", "the dock's status from afar, no clock")
	_by(dock, 30.0, 8.0)
	_ok(_stays_stage(Trend.Stage.DELIVER, 0.5) and _sub() == "dock", "the dock is not reached at 8 m/s")
	_ok(_status("KAWOWY RAJD → ROWERILO", "Stań przy stacji, weź rower", "Stop by the dock, take a bike") and hud.count == "", "the dock's status near")
	_by(dock, 35.0)
	_secs(0.3)
	_ok(_status("KAWOWY RAJD → ROWERILO", "Stań przy stacji, weź rower", "Stop by the dock, take a bike"), "the dock's near hint from 35 m")
	_by(dock, 45.0)
	_secs(0.3)
	_ok(_status("KAWOWY RAJD → ROWERILO", "Jedź do brązowego światła: stacja ROWERILO", "Head for the brown beacon: the ROWERILO dock"), "the dock's far hint from 45 m")
	_by(dock, 3.0)
	flying = true
	heli = dock + Vector3(0.0, 40.0, 0.0)
	_ok(_stays_stage(Trend.Stage.DELIVER, 1.0) and _sub() == "dock" and car.models.size() == n_models and hud.status_title == "KAWOWY RAJD → ROWERILO", "flying in the car to the dock: nothing, the status goes on")
	flying = false
	if glow_after_wall:
		fronts.placed = false
	_by(dock, 3.0)
	_ok(_until(func() -> bool: return car.model == "bike", 0.7), "0.5 s at the dock: the bike")
	var f_bike := _frames
	_ok(car.models.slice(n_models) == ["bike"] and car.resets == resets0 + 1 and car.copies == copies0 + 1 and tj._parked != null and tj._parked.get_parent() == world \
			and _near(tj._parked.global_position, car.global_position), "the bike: the car stopped once, one copy of it left standing at its place in the world")
	_ok(_toast("Rower z ROWERILO! Zuzia czeka w KROPCE.", "A ROWERILO bike! Zuzia's waiting at KROPKA."), "the bike's toast")
	_ok(_sub() == "stop" and _near(tj.target_position(), _terrain(STOP_DOORS[0])), "the first café is the target")
	_secs(0.5)
	_ok(hud.count == "3:59" and hud.status_title == "KAWA 0/4 → KROPKA.", "the clock from 4:00, the first café's status")
	_ok(tj.kawa_busy() and not tj.kawa_ring() and not tj.kawa_meet(), "kawa_busy() during the run, no ring or meeting over it")
	if glow_after_wall:
		_ok(_glows().is_empty(), "no glow while the wall is not there")
		fronts.placed = true
		_secs(0.1)
	var paid_expect := 0
	var f_last := 0
	for i in 4:
		var ring := _terrain(STOP_DOORS[i])
		_ok(_in_stage(Trend.Stage.DELIVER) and _sub() == "stop" and int(tj.order["i"]) == i and _near(tj.target_position(), ring) and _ring_is(ring, BROWN, true), "café %d: the ring is brown and waving at its door" % i)
		_ok(tj.order["name"] == CAFES[i][0], "café %d: the order carries its name" % i)
		_ok(_glow_over(i), "the glow is over café %d" % i)
		if i == 0:
			var gm: StandardMaterial3D = tj._kawa_glow.material_override
			_ok(Color(gm.albedo_color.r, gm.albedo_color.g, gm.albedo_color.b).is_equal_approx(Color("#c98a4b").lightened(0.35)), "the glow is the café brown, lightened by 0.35")
			# Fast in the ring is no stamp; leaving starts the hold over; the door's hint stands.
			_by(ring, 3.0, 8.0)
			_ok(_stays_stage(Trend.Stage.DELIVER, 2.0) and int(tj.order["i"]) == 0, "café 0: no stamp at 8 m/s")
			_by(ring, 3.0)
			_secs(1.0)
			_by(ring, 40.0)
			_frame()
			_by(ring, 3.0)
			_secs(0.8)
			_ok(int(tj.order["i"]) == 0 and _status("KAWA 0/4 → KROPKA.", "Stań przy drzwiach po pieczątkę", "Stop at the door for the stamp"), "café 0: 1.0 s, away, 0.8 s is no stamp; the door's hint")
			_by(ring, 40.0)
			_frame()
		if i == 3:
			f_last = _frames
		if i == 0 and glow_after_wall:
			_ok(str(tj._kawa_glow.name) == "KawaGlow" and tj._kawa_glow.get_parent() == world, "the first glow is a child of the world named KawaGlow")
		if late and i == 3:
			tj._clock = 241.0
		_by(ring, 3.0)
		_secs(1.4)
		_ok(int(tj.order["i"]) == i and _sub() == "stop", "café %d: not yet at 1.4 s" % i)
		var m := wallet.money
		var price: int = CAFES[i][1]
		_secs(0.2)
		var own := m >= price
		if own:
			paid_expect += price
		_ok(wallet.money == (m - price if own else m), "café %d: the coffee is paid for from the wallet" % i)
		_ok(_toast("Pieczątka %d/4! %s, %s: %s" % [i + 1, CAFES[i][0], CAFES[i][2], ("-%d zł" % price) if own else "na koszt Zuzi"],
				"Stamp %d/4! %s, %s: %s" % [i + 1, CAFES[i][0], CAFES[i][3], ("-%d zł" % price) if own else "Zuzia's treat"]), "café %d: the stamp's toast" % i)
		if i == 0:
			var joke: Array = CoffeeRun.STOPS[0]["line"]
			_ok(hud.status == joke[0] and hud.hint_en == joke[1], "the café's joke is the status hint")
			_secs(11.0)
			_ok(hud.status == joke[0], "the joke still holds 11 s after")
			_secs(1.5)
			_ok(hud.status != joke[0], "and is over after 12 s: the ride's lines")
	_ok(_sub() == "return" and _glows().is_empty(), "after the fourth: the way back, no glow")
	_frame()
	_ok(tj.order["name"] == "ROWERILO" and _ring_is(_terrain(DOCK), BROWN, true), "after the fourth: the dock's name, the ring at the dock")
	_ok(hud.status == "Chmurka to piana z cukru. Płacisz za pogodę: 34 zł." and hud.hint_en == "The cloud is sugar foam. You're paying for the weather: 34 zł.", "after the fourth: the last café's joke on the way back")
	var stamp_t := (241.0 if late else float(f_last - f_bike) * DT) + 1.5
	_ok(absf(float(tj.order["time"]) - stamp_t) < 0.3 + (0.0 if late else 0.0), "the time is kept at the fourth stamp (%.1f s)" % stamp_t)
	_secs(13.0)
	_ok(_status("KAWOWY RAJD → ROWERILO", "Odstaw rower, auto czeka", "Return the bike, the car's waiting"), "the way back: return the bike")
	_by(dock, 3.0)
	_ok(_until_stage(Trend.Stage.RESULT, 0.7), "0.5 s at the dock: the result")
	_ok(car.models.slice(n_models) == ["bike", "hatch"] and tj._parked == null and car.copies == copies0 + 1, "the car again, the parked copy gone")
	_ok(_ring_dimmed(_terrain(DOCK)) and hud.status_title == "", "the result: the ring at the dock dimmed, its person not waving, the status line gone")
	var back := paid_expect if not late else roundi(paid_expect * 0.5)
	var zl := (paid_expect + 40) if not late else back
	var resp := 20 if not late else 0
	_ok(wallet.money == m_start - paid_expect + zl and tj.done == d0 + 1, "the pay: what was paid back %s (%d zł of %d)" % ["+ 40 zł" if not late else "by half", zl, paid_expect])
	var t: float = tj.order["time"]
	var line_pl := "Pełny paszport! Dziesiąta kawa gratis… w dni robocze 6:00-6:05." if not late else "Twoja kawa wystygła, to ją wypiłam. Oddaję połowę."
	var line_en := "Full passport! Tenth coffee free… weekdays 6:00-6:05." if not late else "Your coffee went cold, so I drank it. Here's half back."
	_ok(hud.side and hud.card == "KAWOWY RAJD · +%d zł" % zl and hud.card_en == "Coffee run · +%d zł" % zl, "the result's title")
	_ok(hud.body == "„%s” · Zuzia\nPASZPORT KAWOWY 4/4 w %d:%02d\n+%d zł BLIKiem (zwrot %d zł), +%d szacunku" % [line_pl, int(t) / 60, int(t) % 60, zl, back, resp] \
			and hud.body_en == "\"%s\"\nCOFFEE PASSPORT in %d:%02d\n+%d zł by BLIK (%d zł back), +%d respect" % [line_en, int(t) / 60, int(t) % 60, zl, back, resp], "the result's body: the passport, the time, the BLIK")
	_press(0)
	_ok(_idle(), "OK closes the coffee run")


func _j_kawa() -> void:
	_rig()
	var near := DOCK + Vector2(0.0, 300.0)
	_hour(12.0, 1)
	_at(near)
	_secs(0.6)
	_ok(_kawa_try(8.0, near, 0.6), "the call at 8.0 h")
	_ok(_kawa_try(18.99, near, 0.6), "the call at 18.99 h")
	_ok(not _kawa_try(19.0, near, 1.1), "no call at 19.0 h (the cafés are shut)")
	_ok(not _kawa_try(7.9, near, 1.1), "no call at 7.9 h")
	_ok(not _kawa_try(12.0, DOCK + Vector2(0.0, 1801.0), 1.1), "no call from 1801 m")
	tj.places.erase("glon_dobra")
	_hour(12.0, 1)
	_at(near)
	_rested()
	tj._kawa_at = tj._played
	_ok(_quiet(1.1) and not tj.kawa_ring() and not tj.offer_kawa_call(true), "a café with no place: no call, false")
	tj.places["glon_dobra"] = PLACES["glon_dobra"]
	_rested()
	tj._kawa_at = tj._played
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "Zuzia's call at noon, 300 m from the dock")
	var txt: Array = CoffeeRun.call_text()
	_ok(hud.side and hud.card_is(tj) and hud.card == "📞 ZUZIA DZWONI" and hud.card == txt[0] and hud.card_en == "Zuzia is calling" and hud.body == txt[1] and hud.body_en == txt[2], "the call card: Zuzia's text")
	_ok(hud.button_words == PackedStringArray(["JADĘ", "NIE TERAZ"]) and hud.face == "Zuzia" and hud.accent == BROWN and is_equal_approx(tj._kawa_at, tj._played + 1500.0), "the buttons, her face, brown, the next call 1500 s away")
	var c0 := calls.closed
	_press(0)
	_ok(_in_stage(Trend.Stage.DELIVER) and _sub() == "dock" and _near(tj.target_position(), _terrain(DOCK)) and tj.target_colour() == BROWN, "JADĘ: the dock leg, the dock at the terrain height, the brown target")
	_ok(_toast("Kawowy rajd: jedź do stacji ROWERILO przy Elektrowni", "Coffee run: drive to the ROWERILO dock by Elektrownia") and calls._held() and calls.closed == c0 + 1, "the toast, the rescue line paused and closed")
	wallet.money = 500
	_kawa_ride(false, true)
	_ok(not tj.kawa_idle() and tj.idle(), "after a run Zuzia rests: idle() but not kawa_idle()")
	var r: float = tj._played
	tj._played = r + 298.0
	_ok(not tj.kawa_idle(), "still resting 298 s after")
	tj._played = r + 302.0
	_ok(tj.kawa_idle(), "kawa_idle() after 300 s")
	# Late, the wallet short at the last café.
	_rested()
	_ok(tj.kawa_ring() and _is_phase(Activity.Phase.OFFER) and _sub() == "dock", "kawa_ring() from idle: the call card")
	_ok(not tj.kawa_ring(), "kawa_ring() is false while the card is up")
	_press(0)
	wallet.money = 100
	_kawa_ride(true, false)
	tj._played += 400.0
	# Flying on the bike.
	_rested()
	_ok(tj.kawa_ring(), "kawa_ring() again")
	_press(0)
	_by(_terrain(DOCK), 3.0)
	_ok(_until(func() -> bool: return car.model == "bike", 0.7), "the bike again")
	var m := wallet.money
	var n_models := car.models.size()
	flying = true
	heli = car.global_position + Vector3(0.0, 30.0, 0.0)
	_frame()
	flying = false
	_ok(_idle() and _toast("Rower nie lata. Rajd przerwany.", "Bikes don't fly. The run is off.") and car.models.size() == n_models + 1 and car.model == "hatch" and tj._parked == null \
			and wallet.money == m and not calls._held(), "flying on the bike: idle, the words, the car again, the copy gone, no pay")
	tj._played += 400.0
	# The ✕ on the bike.
	_rested()
	_ok(tj.kawa_ring(), "kawa_ring()")
	_press(0)
	_by(_terrain(DOCK), 3.0)
	_ok(_until(func() -> bool: return car.model == "bike", 0.7), "the bike for the ✕")
	_abort()
	_ok(_idle() and car.model == "hatch" and tj._parked == null and _toast("Anulowane", "Cancelled"), "the ✕ on the bike: idle, the car again, Anulowane")
	tj._played += 400.0
	# Met in person at the dock.
	_rested()
	_at(DOCK + Vector2(3.0, 0.0))
	_ok(tj.kawa_meet() and hud.card == "" and _in_stage(Trend.Stage.DELIVER) and _sub() == "dock", "kawa_meet() from idle: no call card, straight to the dock's leg")
	_ok(tj.kawa_busy() and not tj.padel_busy(), "kawa_busy() during the run, padel_busy() not")
	_abort()
	tj._played += 400.0
	_ok(tj.offer(0) and not tj.kawa_busy(), "kawa_busy() is false over a slot's request")
	_press(0)
	_ok(tj.busy() and not tj.kawa_busy(), "kawa_busy() is false during a slot's run")
	_abort()
	_mark("J")


# --- K. one order over another -----------------------------------------------------------------------------

## The seven forced orders, in a row: each should say no during a run.
func _seven() -> Array:
	return [tj.offer(0), tj.offer_drop(), tj.offer_czwarty(), tj.offer_deski_call(true), tj.offer_mlask(true), tj.offer_dzemini(true), tj.offer_kawa_call(true)]


func _snap() -> Array:
	return [tj.order.duplicate(true), tj.stage, tj.phase, hud.card, hud.status, hud.shown, hud.toasts.size(), tj.van.duplicate(), wallet.money, hud.status_title]


func _k_over() -> void:
	_rig()
	_hour(12.0, 1)
	_at(HOME)
	_secs(2.6)
	_ok(tj.offer(0) and _is_phase(Activity.Phase.OFFER) and int(tj.order["slot"]) == 0, "offer(0) asks")
	_secs(4.0)
	_ok(tj.offer_drop() and _is_phase(Activity.Phase.OFFER) and hud.card == "LIMITKA · PISTACJA" and hud.card_is(tj), "the drop's request takes the slot's place")
	_ok(_stays(Activity.Phase.OFFER, 9.9) and _until_idle(0.2), "and has its own 10 s from now")
	_rested()
	_ok(tj.offer(1), "offer(1) asks")
	_secs(3.0)
	jobs.no_kerb.append(PISTACJA)
	_ok(not tj.offer_drop() and _is_phase(Activity.Phase.OFFER) and hud.card == "NA CZASIE · MATCHA" and hud.card_is(tj), "the drop with no kerb: false, slot B's card is still up")
	jobs.no_kerb.erase(PISTACJA)
	_ok(_stays(Activity.Phase.OFFER, 6.9) and _until_idle(0.2), "slot B's card is gone 10 s after it went up")
	_rested()
	_ok(tj.offer(0), "a request")
	_secs(2.0)
	_ok(tj.offer_deski_call(true) and _is_phase(Activity.Phase.RING), "the DESKA call takes the request's place: it rings")
	_ok(_stays(Activity.Phase.RING, 9.9) and _until_idle(0.2), "and rings for 10 s from now")
	_rested()
	_ok(tj.offer_deski_call(true) and _is_phase(Activity.Phase.RING), "a ringing call")
	_secs(1.0)
	_ok(tj.offer(0) and _is_phase(Activity.Phase.OFFER) and hud.card == "NA CZASIE · DUBAJSKA", "a request takes the ringing call's place")
	_press(0)
	_ok(_in_stage(Trend.Stage.PICKUP), "ACCEPT starts the pickup")
	_abort()
	_secs(2.6)
	_rested()
	_ok(tj.offer_deski_call(true), "the call")
	_press(0)
	_ok(_sub() == "offer", "the friend's card")
	_secs(1.0)
	_ok(tj.offer_kawa_call(true) and hud.card == "📞 ZUZIA DZWONI" and _sub() == "dock", "Zuzia's call takes the friend's card's place")
	_secs(1.0)
	_at(SLOT_B + Vector2(0.0, 200.0))
	_ok(tj.offer_mlask(true) and hud.card == "MLASK · MROŻULO" and _sub() == "fetch", "Mrożulo's request takes Zuzia's call's place")
	_secs(1.0)
	_ok(tj.offer_deski_call(true) and _is_phase(Activity.Phase.RING), "the DESKA call takes Mrożulo's place")
	_press(0)
	_ok(tj.offer_dzemini(true) and hud.card == "📞 MROŻULO DZWONI" and _sub() == "fetch", "Mrożulo's call takes the friend's card's place")
	_press(1)
	_ok(_idle(), "NIE TERAZ: idle")
	# During a run every one of the seven says no and changes nothing.
	_at(HOME)
	_secs(2.6)
	_take_slot(0)
	var before := _snap()
	_ok(_seven() == [false, false, false, false, false, false, false] and _snap() == before, "on the way to the queue: all seven say no and change nothing")
	_pick_up(1.5)
	before = _snap()
	_ok(_seven() == [false, false, false, false, false, false, false] and _snap() == before, "on the way to the door: all seven say no and change nothing")
	_arrive()
	before = _snap()
	_ok(_seven() == [false, false, false, false, false, false, false] and _snap() == before, "on the result card: all seven say no and change nothing")
	_press(0)
	_mark("K")


# --- L. the autopilot ----------------------------------------------------------------------------------------

## Runs the autopilot until the job is idle, at most `s` seconds; the seconds it took, or -1.
func _auto_end(s: float) -> float:
	for i in roundi(s * 60.0):
		if tj.phase == Activity.Phase.IDLE and tj.stage == Trend.Stage.NONE:
			return i * DT
		_frame()
	return -1.0


func _l_auto() -> void:
	_rig()
	_hour(12.0, 1)
	_at(SLOT_A + Vector2(0.0, 30.0))
	_secs(0.1)
	auto = true
	# Na czasie: the request taken 1.5 s after it went up.
	_rested()
	_ok(tj.offer(0), "offer(0)")
	var pick: Dictionary = jobs.last.duplicate()
	_secs(1.4)
	_ok(_is_phase(Activity.Phase.OFFER), "the autopilot has not taken the request at 1.4 s")
	_ok(_until_phase(Activity.Phase.RUN, 0.2), "and has by 1.6 s")
	var m0 := wallet.money
	_ok(_until_stage(Trend.Stage.RESULT, 400.0), "Na czasie reaches its result")
	var pay := 25 + roundi(8.0 * float(pick["road"]) / 1000.0) + 10
	_ok(wallet.money == m0 + pay, "the autopilot's Na czasie pays %d zł" % pay)
	_ok(_stays_stage(Trend.Stage.RESULT, 9.7) and _auto_end(0.6) >= 0.0, "a plain result card waits out its 10 s")
	# Limitka.
	_secs(2.6)
	_rested()
	tj.force_drop = true
	m0 = wallet.money
	_ok(tj.offer_drop(), "offer_drop()")
	pick = jobs.last.duplicate()
	_ok(_auto_end(400.0) >= 0.0, "Limitka reaches idle within 400 s")
	pay = 40 + roundi(10.0 * float(pick["road"]) / 1000.0) + 15
	_ok(wallet.money == m0 + pay, "the autopilot's Limitka pays %d zł" % pay)
	tj.force_drop = false
	# Czwarty.
	_secs(2.6)
	_rested()
	m0 = wallet.money
	_ok(tj.offer_czwarty(), "offer_czwarty()")
	pick = jobs.last.duplicate()
	_ok(_auto_end(400.0) >= 0.0, "Czwarty reaches idle within 400 s")
	pay = 45 + roundi(8.0 * 2.0 * float(pick["road"]) / 1000.0) + 15
	_ok(wallet.money == m0 + pay, "the autopilot's Czwarty pays %d zł" % pay)
	# The DESKA call: answered after 1.5 s, the friend's card taken 1.5 s after that, three best shots.
	_at(HOME)
	_secs(2.6)
	_rested()
	m0 = wallet.money
	var road := 1.3 * Vector2(car.global_position.x, car.global_position.z).distance_to(GATE)
	_ok(tj.offer_deski_call(true), "offer_deski_call(true)")
	_secs(1.4)
	_ok(_is_phase(Activity.Phase.RING), "the call still rings at 1.4 s")
	_ok(_until_phase(Activity.Phase.OFFER, 0.2), "and is answered by 1.6 s")
	_secs(1.4)
	_ok(_is_phase(Activity.Phase.OFFER), "the friend's card is still up 1.4 s after")
	_ok(_until_phase(Activity.Phase.RUN, 0.2), "and taken by 1.6 s")
	_ok(_until(func() -> bool: return _sub() == "match", 400.0), "the autopilot reaches the court")
	_secs(2.4)
	_ok(int(tj.order.get("point", -1)) == 0, "a point is not played before 2.5 s")
	_secs(0.3)
	_ok(int(tj.order.get("point", -1)) == 1 and int(tj.order.get("won", -1)) == 1, "and is played with the best shot by 2.8 s")
	_ok(_until_stage(Trend.Stage.RESULT, 0.1) and _until(func() -> bool: return _sub() == "done", 8.0), "the match reaches its result")
	pay = 45 + roundi(8.0 * 2.0 * road / 1000.0) + 15 + 18
	_ok(wallet.money == m0 + pay and int(tj.order.get("won", -1)) == 3, "three best shots: the autopilot's DESKA pays %d zł" % pay)
	_ok(_stays_stage(Trend.Stage.RESULT, 9.7) and _auto_end(0.6) >= 0.0, "the match's result waits out its 10 s")
	# Mlask: the review's button tapped 2.5 s after it went up.
	_at(SLOT_B + Vector2(0.0, 200.0))
	_secs(2.6)
	_rested()
	m0 = wallet.money
	_ok(tj.offer_mlask(true), "offer_mlask(true)")
	var place := _kerb_ring(_ans(SLOT_A))
	var vr: Vector3 = tj.van["ring"]
	_ok(_until(func() -> bool: return _sub() == "review", 400.0), "the autopilot brings the takeaway to the van")
	_secs(2.4)
	_ok(_sub() == "review", "the review is not tapped before 2.5 s")
	_secs(0.3)
	_ok(_sub() == "sticker", "and is tapped by 2.8 s")
	_ok(_auto_end(400.0) >= 0.0, "Mlask reaches idle within 400 s")
	var base := 40 + roundi(10.0 * 2.0 * 1.3 * _flat(vr, place) / 1000.0)
	_ok(wallet.money == m0 + base + 15, "the autopilot's Mlask pays %d zł" % (base + 15))
	# Dżemini: the bite's card tapped, the TYGRAM waits out its 10 s.
	_at(DZEMINI + Vector2(0.0, 100.0))
	_secs(2.6)
	_rested()
	m0 = wallet.money
	_ok(tj.offer_dzemini(true), "offer_dzemini(true)")
	var shop := _kerb_ring(_ans(DZEMINI))
	vr = tj.van["ring"]
	_ok(_until(func() -> bool: return _sub() == "tygram", 400.0), "the autopilot brings the kebab and taps the bite's card")
	_ok(_stays_stage(Trend.Stage.RESULT, 9.7) and _auto_end(0.6) >= 0.0, "the TYGRAM message waits out its 10 s")
	pay = 60 + roundi(10.0 * 1.3 * _flat(shop, vr) / 1000.0) + 20
	_ok(wallet.money == m0 + pay, "the autopilot's Dżemini pays %d zł" % pay)
	# The coffee run.
	_at(DOCK + Vector2(0.0, 300.0))
	_secs(2.6)
	_rested()
	wallet.money = 500
	m0 = wallet.money
	_ok(tj.offer_kawa_call(true), "offer_kawa_call(true)")
	_ok(_auto_end(400.0) >= 0.0, "the coffee run reaches idle within 400 s")
	_ok(wallet.money == m0 + 40, "the autopilot's coffee run: the 121 zł paid back and 40 zł on top")
	auto = false
	_mark("L")


# --- N. what deliberate breaks of the script showed -----------------------------------------------------------

func _door_b(p: Vector2) -> void:
	life.slot_doors[1] = p


## Exactly one card or call goes up at the next look, and it is `title` ("DESKA": a DESKA friend's
## call); it is turned down.
func _first(title: String, what: String) -> void:
	var s0 := hud.shown
	var got := _until(func() -> bool: return hud.shown > s0, 0.6)
	var right := hud.card == title
	if title == "DESKA":
		right = hud.card.begins_with("📞 ") and hud.card.ends_with(" DZWONI") and _caller() != ""
	_ok(got and hud.shown == s0 + 1 and right, "%s comes first, and alone (shown %d -> %d, '%s')" % [what, s0, hud.shown, hud.card])
	if got:
		_press(1)


func _n_gaps() -> void:
	_n_first()
	_n_ends()
	_n_pay()
	_n_door()
	_n_deska()
	_n_van()
	_n_forced()
	_n_hooks_and_sticker()
	_n_words()


## Which comes first when two are due at the same look (slot B's door 10 to 25 m from the car).
func _n_first() -> void:
	_rig()
	_hour(12.0, 1)
	_at(HOME)
	_secs(2.6)
	var ring: Vector3 = tj.van["ring"]
	_door_b(Vector2(ring.x + 20.0, ring.z + 10.0))
	_by(ring, 20.0)
	_rested()
	_first("MLASK · MROŻULO", "Mrożulo's request before the slot's")
	_door_b(SLOT_B)
	_hour(12.0, 4)
	_at(HOME)
	_door_b(HOME + Vector2(15.0, 0.0))
	_rested()
	tj._dz_at = tj._played
	_first("📞 MROŻULO DZWONI", "Mrożulo's call before the slot's")
	_door_b(SLOT_B)
	_hour(17.0, 5)
	_at(PISTACJA + Vector2(0.0, 50.0))
	_door_b(PISTACJA + Vector2(20.0, 50.0))
	_rested()
	_first("LIMITKA · PISTACJA", "the drop's request before the slot's")
	_door_b(SLOT_B)
	_hour(12.0, 1)
	_at(DOCK + Vector2(0.0, 300.0))
	_door_b(DOCK + Vector2(20.0, 300.0))
	_rested()
	tj._kawa_at = tj._played
	_first("📞 ZUZIA DZWONI", "Zuzia's call before the slot's")
	_door_b(SLOT_B)
	tj._kawa_at = 1.0e9
	_at(HOME)
	_door_b(HOME + Vector2(15.0, 0.0))
	_rested()
	tj._deski_at = tj._played
	_first("DESKA", "the DESKA call before the slot's")
	_door_b(SLOT_B)
	tj._deski_at = 1.0e9
	_hour(17.5, 1)
	_at(PADEL + Vector2(0.0, 50.0))
	_door_b(PADEL + Vector2(20.0, 50.0))
	_rested()
	_first("CZWARTY · PADELNIA", "the fourth player's request before the slot's")
	_door_b(SLOT_B)
	_ok(_quiet(1.6), "no second fourth player's request within 240 s of a skip")
	_hour(12.0, 1)
	_door_b(SLOT_A + Vector2(20.0, 0.0))
	_at(SLOT_A + Vector2(0.0, 30.0))
	_rested()
	_first("NA CZASIE · DUBAJSKA", "of two slots in reach, the lower number")
	_door_b(SLOT_B)
	_mark("N1")


## The ends of the hours and of the reaches.
func _n_ends() -> void:
	_rig()
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.6)
	_ok(not _deski_try(7.99, 1.1), "no DESKA call at 7.99 h")
	_ok(_deski_try(8.0, 0.6), "the DESKA call at 8.0 h")
	_ok(_deski_try(21.99, 0.6), "the DESKA call at 21.99 h")
	_ok(not _deski_try(22.0, 1.1), "no DESKA call at 22.0 h")
	tj._deski_at = 1.0e9
	for e: Array in [[11.0, true], [20.99, true], [10.99, false], [21.0, false]]:
		_hour(float(e[0]), 1)
		_at(HOME)
		_secs(0.6)
		_ok(tj._van_node.visible == bool(e[1]), "the van at %.2f h is %s" % [e[0], "out" if e[1] else "away"])
	_ok(_kawa_try(12.0, DOCK + Vector2(0.0, 1799.0), 0.6), "Zuzia's call from 1799 m")
	_ok(not _kawa_try(12.0, DOCK + Vector2(0.0, 1801.0), 1.1), "no call from 1801 m")
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.6)
	var at: Vector3 = tj.van["at"]
	tj._cool[-3] = 1.0e9
	eggs.clear()
	tj._egg_t = 0.0
	_at(Vector2(at.x + 10.5, at.z))
	_secs(6.0)
	_ok(eggs.is_empty(), "no egg from 10.5 m")
	_at(Vector2(at.x + 8.5, at.z), 2.0)
	_secs(6.0)
	_ok(eggs.is_empty(), "no egg rolling at 2 m/s")
	_at(Vector2(at.x + 8.5, at.z))
	_secs(3.6)
	_ok(eggs == ["easter_mlask"], "the egg after 3 s from 8.5 m")
	_secs(30.0)
	_ok(eggs == ["easter_mlask"], "and once only however long the car stays")
	_mark("N2")


## The pay's two conditions, one at a time.
func _n_pay() -> void:
	_rig()
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.6)
	life.slots_now[1]["day"] = 5
	var m0 := wallet.money
	var r0 := wallet.respect
	var pick := _slot_run(1)
	var base := 25 + roundi(8.0 * float(pick["road"]) / 1000.0)
	_ok(wallet.money == m0 + base + 10 and wallet.respect == r0 + 15 and _one_of("„Jeszcze ciepłe i jeszcze modne. Dziękuję!” · <c>\n+%d zł (napiwek 10 zł), +15 szacunku" % (base + 10), CUSTOMERS, hud.body), "day 5 on time: the tip and the respect")
	_press(0)
	life.slots_now[1]["day"] = 6
	m0 = wallet.money
	r0 = wallet.respect
	pick = _slot_run(1)
	base = 25 + roundi(8.0 * float(pick["road"]) / 1000.0)
	_ok(wallet.money == m0 + base and wallet.respect == r0 + 15 and "WIRAL PL" in hud.body and "(napiwek 0 zł)" in hud.body and dlg.line_asks[-1] == "viral:late", "day 6 on time: no tip, 15 respect, the bag's late line")
	_press(0)
	m0 = wallet.money
	r0 = wallet.respect
	pick = _slot_run(1, true)
	base = 25 + roundi(8.0 * float(pick["road"]) / 1000.0)
	_ok(wallet.money == m0 + roundi(base * 0.5) and wallet.respect == r0 and "WIRAL PL" in hud.body and not ("Trend poszedł dalej" in hud.body), "day 6 and late: half, no respect, the bag's line and not the late one")
	_press(0)
	# Mlask: cold with the sticker on time, warm with the sticker late (half the base, no tip, no respect).
	_rig()
	_mirror = RandomNumberGenerator.new()
	_mirror.seed = SEED
	_mirror_on = true
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.6)
	_mlask_run(true, false)
	_mlask_run(false, true)
	_mirror_on = false
	_mark("N3")


## The door's hint and the metres.
func _n_door() -> void:
	_rig()
	_hour(12.0, 1)
	_take_slot(0)
	var ring: Vector3 = tj.order["ring"]
	_by(ring, 14.6)
	_frame()
	_ok(hud.distance == "15 m", "14.6 m shows 15 m (rounded, not cut): '%s'" % hud.distance)
	_by(ring, 14.4)
	_frame()
	_ok(hud.distance == "14 m", "14.4 m shows 14 m")
	_pick_up(1.5)
	var door: Vector3 = tj.order["door_ring"]
	_by(door, 41.0, 10.0)
	_frame()
	_ok(_status("NA CZASIE → %s" % tj.order["name"], "Jedź do różowego światła", "Head for the pink beacon") and hud.distance == "41 m", "41 m from the door: the beacon's hint")
	_by(door, 39.0, 10.0)
	_frame()
	_ok(_status("NA CZASIE → %s" % tj.order["name"], "Stań pod drzwiami", "Stop at the door") and hud.distance == "39 m", "39 m from the door: the door's hint")
	_abort()
	_mark("N4")


## The DESKA call's way and the court.
func _n_deska() -> void:
	_rig()
	_hour(12.0, 1)
	var gr := _terrain(GATE)
	var road := _deska_go()
	_by(gr, 20.0)
	_ok(_stays_stage(Trend.Stage.DELIVER, 0.5), "by car 20 m from the gate at a standstill is not there")
	_by(gr, 12.9)
	_frame()
	_ok(_sub() == "match", "12.9 m from the gate is the ring")
	var before := _snap()
	tj.arcade_done(2, 0, {})
	_ok(_snap() == before and _sub() == "match", "arcade_done during the cards' match changes nothing")
	for i in 3:
		_press(0)
	_press(0)
	_ok(_idle(), "the match ended and closed")
	# A forced call in the air measures the way from the helicopter and is taken back.
	_at(HOME)
	_rested()
	flying = true
	heli = Vector3(HOME.x + 300.0, 50.0, HOME.y)
	_frame()
	_ok(tj.offer_deski_call(true) and _is_phase(Activity.Phase.RING), "the forced call rings in the air")
	_ok(is_equal_approx(float(tj.order["road"]), 1.3 * Vector2(heli.x, heli.z).distance_to(GATE)) and not is_equal_approx(float(tj.order["road"]), road), "its way is 1.3 times the helicopter's distance to the gate")
	_frame()
	_ok(_idle(), "and is taken back at the next frame: the player flies")
	flying = false
	_mark("N5")


## The van by a road aslant, and the forced orders.
func _n_van() -> void:
	_rig()
	graph.off = Vector2(36.0, 48.0)
	_hour(12.0, 4)
	_at(HOME)
	jobs.answers.clear()
	_secs(0.6)
	_ok(not tj.van.is_empty() and tj.van["spot"] == "plac_zbawiciela", "Thursday: the van by a road 60 m away")
	if not jobs.answers.is_empty():
		var side: Vector2 = jobs.answers[0]["side"]
		var yaw := atan2(side.y, -side.x)
		_ok(is_equal_approx(float(tj.van["yaw"]), yaw) and absf(absf(yaw) - PI * 0.5) > 0.1, "the van's yaw is atan2(side.y, -side.x) for the kerb's side, aslant")
		_ok(tj._van_node.global_transform.basis.is_equal_approx(Basis(Vector3.UP, yaw)), "the node's basis is that yaw about UP")
	graph.off = Vector2(81.0, 0.0)
	tj._van_day = -1
	_secs(0.6)
	_ok(tj.van.is_empty(), "a road 81 m away: no van (the reach is 80 m)")
	graph.off = Vector2(10.0, 0.0)
	_mark("N6")


func _n_forced() -> void:
	_rig()
	var here := SLOT_B + Vector2(0.0, 200.0)
	_hour(3.0, 1)
	_at(here)
	_secs(0.6)
	_ok(not tj._van_node.visible, "the van is away at 3.0 h")
	tj._van_day = -1
	_rested()
	jobs.answers.clear()
	_ok(tj.offer_mlask(true) and tj._van_node.visible and tj.van["spot"] == "here" and tj._van_day == 1, "offer_mlask(true) at 3.0 h: the van comes out, parked by the car, today's weekday")
	_ok(not jobs.answers.is_empty() and jobs.answers[0]["door"] == here + Vector2(0.0, -12.0) + Vector2(9.5, 0.0), "the van is parked 12 m north of the car")
	_ok("KUKŁA, nowe miejsce" in hud.body and tj.order["site"] == Crowds.KUKLA[0], "the new place is KUKŁA: slot A's shop is shut at 3.0 h")
	_press(1)
	jobs.no_kerb.append(here + Vector2(0.0, -12.0))
	_ok(not tj.offer_mlask(true) and tj.van.is_empty() and not tj._van_node.visible and _idle(), "offer_mlask(true) with no kerb by the car: false, no van, the node hidden, idle")
	jobs.no_kerb.erase(here + Vector2(0.0, -12.0))
	_hour(12.0, 4)
	tj.van = {}
	tj._van_day = -1
	_ok(tj.offer_dzemini(true) and tj.van["spot"] == "plac_zbawiciela" and tj._van_day == 4, "offer_dzemini(true) before the first look: the van at today's spot")
	_press(1)
	tj.quiet = true
	var s0 := hud.shown
	_ok(not tj.offer_deski_call() and not tj.offer_kawa_call() and not tj.offer_dzemini() and hud.shown == s0 and _idle(), "not forced and quiet: no DESKA call, no coffee run, no Dżemini; nothing shown")
	tj.quiet = false
	_mark("N7")


func _n_hooks_and_sticker() -> void:
	_rig()
	_hour(12.0, 1)
	_at(HOME)
	_secs(2.6)
	_rested()
	_ok(tj.offer(0), "a request")
	_ok(not tj.kawa_meet() and not tj.kawa_ring() and not tj.padel_meet() and not tj.padel_ring(), "a quest's hook over a request: all four say no")
	_ok(_is_phase(Activity.Phase.OFFER) and int(tj.order["slot"]) == 0 and hud.card == "NA CZASIE · DUBAJSKA", "and the request stays as it was")
	_press(1)
	# The sticker goes up in the very frame he bites, and only once.
	_hour(12.0, 4)
	_secs(0.6)
	_ok(_stickers() == 0, "no sticker yet")
	_rested()
	_ok(tj.offer_dzemini(true), "Mrożulo's call")
	_press(0)
	_pick_up(1.5)
	_ok(_stickers() == 0, "no sticker before the bite")
	_arrive()
	_ok(_stickers() == 1 and str(_sticker_node().name) == "DzeminiSticker", "one sticker, named DzeminiSticker, in the very frame he bites")
	_press(0)
	_press(0)
	_ok(_idle(), "the TYGRAM message closed")
	_rested()
	_ok(tj.offer_dzemini(true), "a second forced call")
	_press(0)
	_pick_up(1.5)
	_arrive()
	_secs(1.2)
	_ok(_stickers() == 1, "a second forced run adds no second sticker")
	_press(0)
	_press(0)
	_mark("N8")


func _n_words() -> void:
	for e: Array in [[7.5, "7,5 MLASKA", "7.5 SMACKS"], [8.0, "8 MLASKÓW", "8 SMACKS"], [8.5, "8,5 MLASKA", "8.5 SMACKS"], [9.0, "9 MLASKÓW", "9 SMACKS"],
			[9.5, "9,5 MLASKA", "9.5 SMACKS"], [3.0, "3 MLASKI", "3 SMACKS"], [1.0, "1 MLASK", "1 SMACK"], [2.0, "2 MLASKI", "2 SMACKS"],
			[5.0, "5 MLASKÓW", "5 SMACKS"], [22.0, "22 MLASKI", "22 SMACKS"]]:
		_ok(Trend.grade_words(float(e[0])) == [e[1], e[2]], "the words of grade %s: %s" % [e[0], e[1]])
	_mark("N9")


# --- O. what the player gets, run by run (the breaks the parts above let by) ---------------------------

## The six friends who phone from DESKA, in the order the job draws them (a literal, not the script's).
const O_CALLERS := ["Kuba", "Zuzia", "Bartek", "Iga", "Olek", "Magda"]


func _o_gaps() -> void:
	_o_head()
	_o_accept()
	_o_results()
	_o_van()
	_o_kawa()
	_o_look()
	_o_offers()
	_o_beat()


## The job's own tables (names, words, the first call of each friend) as the player meets them.
func _o_head() -> void:
	_rig()
	_ok(first_at["kawa"] == 420.0 and first_at["dz"] == 300.0 and first_at["deska"] == 660.0, "the first calls are due after 420 s (Zuzia), 300 s (Mrożulo) and 660 s (DESKA) of play")
	# ...and they ring then, not before.
	_hour(12.0, 1)
	_at(DOCK + Vector2(0.0, 300.0))
	tj._kawa_at = first_at["kawa"]
	tj._played = 418.0
	_ok(_quiet(1.4), "Zuzia does not ring before 420 s of play")
	_ok(_until_phase(Activity.Phase.OFFER, 1.0) and hud.card == "📞 ZUZIA DZWONI", "Zuzia rings at 420 s of play")
	_press(1)
	_rig()
	_hour(12.0, 4)
	_secs(0.6)
	tj._dz_at = first_at["dz"]
	tj._played = 298.0
	_rested()
	_ok(_quiet(1.4), "Mrożulo does not ring before 300 s of play")
	_ok(_until_phase(Activity.Phase.OFFER, 1.0) and hud.card == "📞 MROŻULO DZWONI", "Mrożulo rings at 300 s of play")
	_press(1)
	_rig()
	_hour(12.0, 1)
	_secs(0.6)
	tj._deski_at = first_at["deska"]
	tj._played = 658.0
	_rested()
	_ok(_quiet(1.4), "DESKA does not ring before 660 s of play")
	_ok(_until_phase(Activity.Phase.RING, 1.0), "DESKA rings at 660 s of play")
	_press(1)
	# A mission, however long, then 20 s: the rest runs from its end.
	_rested()
	tj._deski_at = tj._played
	mission = true
	_ok(_quiet(5.0), "no call during a 5 s mission")
	mission = false
	_ok(_quiet(19.0), "no call for 19 s after the mission, however long it was")
	_ok(_until_phase(Activity.Phase.RING, 1.6), "the call rings once the 20 s after the mission's end are over")
	_press(1)
	# The tables, by literal.
	_ok(Trend.DESKI_BIOS == BIOS, "every caller's bio, both languages")
	_ok(Trend.RALLIES == RALLY_WORDS, "every rally's situation, best shot, winning and losing words, both languages")
	_ok(Trend.DESKI_CALLERS == O_CALLERS and Trend.DESKI_INJURED == INJURED and Trend.DROP_FRIENDS == FRIENDS, "the callers, the injured and the drop's friends, in order")
	_ok(Trend.CUSTOMERS == CUSTOMERS and Trend.CZ_PLAYERS == CZ_PLAYERS, "the office customers and the fourth players, in order")
	_ok(Trend.ML_GRADES == GRADES, "Mrożulo's grades")
	# The lowest grade reaches the card: a seed whose first draw is index 0.
	var s0 := 1
	var probe := RandomNumberGenerator.new()
	while true:
		probe.seed = s0
		if probe.randi() % 5 == 0:
			break
		s0 += 1
	_rig()
	_mirror = RandomNumberGenerator.new()
	_mirror.seed = s0
	_mirror_on = true
	_fan_lines = 0
	tj._rng.seed = s0
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.6)
	_mlask_run(false, false)
	_mirror_on = false
	_mark("O1")


## Taking a call: the ring the player is sent to and what the screen drops (the pill, the courier's challenge).
func _o_accept() -> void:
	# DESKA: the gate, teal, the person waving.
	_rig()
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.1)
	_rested()
	tj._deski_at = tj._played
	_ok(_until_phase(Activity.Phase.RING, 0.6), "the call rings")
	_press(0)
	hud.show_pill("call")
	var c0 := hud.challenges_hidden
	var p0 := hud.pills_hidden
	tj._beacon.waving = false
	_press(0)
	_ok(_in_stage(Trend.Stage.DELIVER), "JADĘ!: the way to the court")
	_ok(_ring_is(_terrain(GATE), TEAL, true), "the call taken: the teal ring at the gate, its person waving")
	_ok(hud.challenges_hidden == c0 + 1, "the call taken: the courier's challenge is taken down")
	_ok(hud.pills_hidden == p0 + 1 and hud.pill == "", "the call taken: the pill is taken down")
	_abort()
	# Zuzia: the dock, brown, waving; the car still at the dock takes the bike only after 0.5 s, whatever hold the last job left.
	_rig()
	_hour(12.0, 1)
	_at(DOCK + Vector2(0.0, 300.0))
	_secs(0.6)
	_by(_terrain(DOCK), 3.0)
	_rested()
	_ok(tj.offer_kawa_call(true) and _is_phase(Activity.Phase.OFFER), "Zuzia's call at the dock")
	tj._hold = 3.0
	tj._beacon.waving = false
	hud.show_pill("kawa")
	c0 = hud.challenges_hidden
	p0 = hud.pills_hidden
	_press(0)
	_ok(_in_stage(Trend.Stage.DELIVER) and _sub() == "dock", "JADĘ: the dock leg")
	_ok(_ring_is(_terrain(DOCK), BROWN, true), "kawa taken: the brown ring at the dock, its person waving")
	_ok(hud.challenges_hidden == c0 + 1, "kawa taken: the courier's challenge is taken down")
	_ok(hud.pills_hidden == p0 + 1 and hud.pill == "", "kawa taken: the pill is taken down")
	_secs(0.3)
	_ok(car.model != "bike" and _sub() == "dock", "kawa taken: 0.3 s at the dock is not enough, whatever hold the last job left")
	_ok(_until(func() -> bool: return car.model == "bike", 0.4), "kawa taken: 0.5 s at the dock: the bike")
	_abort()
	_mark("O2")


## The results: what each ends with, for the ring, the status line, the card and the count.
func _o_results() -> void:
	# A slot on its trend's last day: the out-of-fashion line asked for as the preferred one.
	_rig()
	life.slots_now[0]["day"] = 6
	_slot_run(0)
	_ok(dlg.line_asks[-1] == "viral:late" and dlg.line_prefers[-1] == true, "the out-of-fashion line is asked for as the preferred one")
	_ok(_ring_dimmed(tj.order["door_ring"]) and hud.status_title == "", "a slot's result: the ring dimmed, the status line gone")
	_press(0)
	# The fourth player: counted, the card beside the road.
	var d0: int = tj.done
	_take_cz()
	_pick_up(1.5)
	_arrive()
	_ok(tj.done == d0 + 1 and hud.side, "the fourth player's result: counted, beside the road")
	_ok(_ring_dimmed(tj.order["door_ring"]) and hud.status_title == "", "the fourth player's result: the ring dimmed, the status line gone")
	_press(0)
	# The drop: counted, beside the road.
	d0 = tj.done
	_take_drop()
	_pick_up(5.0)
	_arrive()
	_ok(tj.done == d0 + 1 and hud.side, "the drop's result: counted, beside the road")
	_ok(_ring_dimmed(tj.order["door_ring"]) and hud.status_title == "", "the drop's result: the ring dimmed, the status line gone")
	_press(0)
	# The call: in time up to 480 s, not up to 420 s.
	_at(HOME)
	_secs(0.1)
	_deska_go()
	tj._clock = 450.0
	_arrive()
	_ok(_sub() == "match", "a call that takes 450 s is in time for the match (480 s)")
	_ok(_match(["best", "best", "best"], tj.order["road"]) == 3, "...and it is played")
	_press(0)
	_hour(12.0, 1)
	# A match without a point: the lost-story line, both languages.
	var road := _deska_go()
	_by(_terrain(GATE), 3.0)
	_frame()
	_ok(_sub() == "match", "at the court on time: the match")
	_ok(_match(["wrong", "wrong", "wrong"], road) == 0, "a match without a point")
	_press(0)
	# A job measured from the car, not from the air: the distance is the car's.
	_rested()
	_take_slot(0)
	_pick_up(1.5)
	var door: Vector3 = tj.order["door_ring"]
	_by(door, 300.0)
	flying = true
	heli = Vector3(door.x + 50.0, 60.0, door.z)
	_secs(0.2)
	_ok(hud.distance == "300 m" and _in_stage(Trend.Stage.DELIVER), "a slot's delivery measures from the car even with the helicopter up (300 m, not 50 m)")
	flying = false
	_abort()
	_ok(tj.kawa_idle(), "a slot's end does not make Zuzia rest")
	# Dżemini, warm and cold: counted, noted, the ring dimmed, the status line gone.
	_rig()
	_hour(12.0, 4)
	_at(HOME)
	_secs(0.6)
	for warm: bool in [true, false]:
		_rested()
		_ok(tj.offer_dzemini(true), "Mrożulo's call")
		_press(0)
		_pick_up(1.5)
		if not warm:
			tj._clock = 301.0
		d0 = tj.done
		_arrive()
		_ok(tj.done == d0 + 1, "Dżemini: counted")
		_ok(_ring_dimmed(tj.van["ring"]) and hud.status_title == "", "Dżemini's result: the ring dimmed, its person not waving, the status line gone")
		_ok(tj.order.get("warm") == warm, "Dżemini's result: warm noted (%s)" % warm)
		_press(0)
		_press(0)
	# Mlask with an empty bag: the job's own words, the review and the sticker.
	_rig()
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.6)
	dlg.no_lines = true
	_rested()
	var vr: Vector3 = tj.van["ring"]
	_by(vr, 20.0)
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "Mrożulo's request")
	var place := _kerb_ring(_ans(SLOT_A))
	_press(0)
	_pick_up(1.5)
	_arrive()
	_ok(_sub() == "review" and hud.status_title == "" and not bool(_look()["wave"]), "the review: the status line gone, the person not waving")
	_ok(hud.body == "„Je się. Mlaska się.”\nZawieź naklejkę do DUBAJSKA w 4 min." and hud.body_en == "\"One eats. One smacks.\"\nTake the sticker to DUBAJSKA in 4 min.", "the review with an empty bag: the job's own words")
	_ok(dlg.line_prefers[-1] == true, "the review's line is asked for as the preferred one")
	var g: float = tj.order["grade"]
	var gw: Array = GRADE_WORDS[GRADES.find(g)]
	_press(0)
	_ok(_in_stage(Trend.Stage.DELIVER), "the sticker's leg")
	_ok(_ring_is(place, ORANGE, true), "the sticker's leg: the orange ring at the place, its person waving")
	_secs(0.5)
	tj._clock = 241.0
	_frame()
	_ok(_status("MLASK → DUBAJSKA", "Spóźnione, ale dowieź", "Late, but deliver it") and hud.tint == RED, "a late sticker: the hint and the red")
	_arrive()
	_ok(_sub() == "done" and hud.side, "the sticker's result: its stage is named done, beside the road")
	_ok(_ring_dimmed(place) and hud.status_title == "" and wallet.kinds[-1] == "trend", "the sticker's result: the ring dimmed, its person not waving, the status line gone, paid as trend")
	_ok(dlg.line_prefers[-1] == false and dlg.line_asks[-1] == "mrozulo_owner:", "the owner's line is not asked for as the preferred one")
	_ok(hud.body.begins_with("„Mrożulo nas polecił? Otwieram drugą kasę.” · DUBAJSKA\n%s" % gw[0]) and hud.body_en.begins_with("\"Mrożulo recommends us? Opening a second till.\"\n%s" % gw[1]), "the sticker with an empty bag: the job's own words")
	_press(0)
	_mark("O3")


## The van and the car that goes and comes back: the fans' bubble, the egg's stop clock, the car after a ride.
func _o_van() -> void:
	_rig()
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.6)
	var at: Vector3 = tj.van["at"]
	var fwd: Vector3 = tj._van_node.global_transform.basis.z
	# A fan's bubble stands behind the van (4 m opposite to where it faces).
	tj._cool[-3] = 1.0e9
	tj._fan_t = 0.5
	_by(at, 15.0)
	_secs(0.6)
	_ok(dlg.said.size() > 0 and dlg.said[-1] == "viral:mrozulo", "a fan speaks")
	var back: Vector3 = (dlg.anchors[-1] as Callable).call()
	_ok(is_equal_approx((back - at).length(), 4.0) and is_equal_approx((back - at).dot(fwd), -4.0), "the fans' bubble stands 4 m behind the van, not in front of it")
	# The egg: 3 s of standing still by the van; the clock starts over when the car leaves or the van does.
	eggs.clear()
	tj._egg_t = 0.0
	_at(Vector2(at.x + 8.5, at.z))
	_secs(2.0)
	_by(at, 30.0)
	_secs(0.6)
	_at(Vector2(at.x + 8.5, at.z))
	_secs(2.0)
	_ok(eggs.is_empty(), "the egg's clock starts over when the car has left (2 s and 2 s are not 3 s)")
	_hour(21.5, 1)
	_secs(0.6)
	_hour(12.0, 1)
	_secs(2.0)
	_ok(eggs.is_empty(), "the egg's clock starts over when the van has left (2 s and 2 s are not 3 s)")
	_secs(1.2)
	_ok(eggs == ["easter_mlask"], "...and 3 s in all, the egg")
	# The car comes back as it was.
	_rig()
	_hour(12.0, 1)
	_at(DOCK + Vector2(0.0, 300.0))
	_secs(0.6)
	car.model = "taxi"
	_rested()
	_ok(tj.offer_kawa_call(true), "Zuzia's call")
	_press(0)
	_by(_terrain(DOCK), 3.0)
	_ok(_until(func() -> bool: return car.model == "bike", 0.7), "the bike")
	_abort()
	_ok(car.model == "taxi" and car.models[-1] == "taxi" and not tj.kawa_idle(), "the ✕ on the bike: the car is the one it was, and Zuzia rests")
	_mark("O4")


## Zuzia's ride on the bike: the status line, the bar, the lines and the glow, run after run.
func _o_kawa() -> void:
	_rig()
	_hour(12.0, 1)
	_at(DOCK + Vector2(0.0, 300.0))
	_secs(0.6)
	_rested()
	wallet.money = 500
	_ok(tj.offer_kawa_call(true), "Zuzia's call")
	_press(0)
	var dock := _terrain(DOCK)
	# The bike is taken standing still in the ring for 0.5 s: not fast, and leaving starts the hold over.
	_by(dock, 3.0, 8.0)
	_ok(_stays_stage(Trend.Stage.DELIVER, 1.0) and car.model != "bike", "the dock: no bike at 8 m/s")
	_by(dock, 3.0)
	_secs(0.3)
	_by(dock, 30.0)
	_frame()
	_by(dock, 3.0)
	_secs(0.3)
	_ok(car.model != "bike" and _sub() == "dock", "the dock: 0.3 s, away, 0.3 s is no bike")
	_ok(_until(func() -> bool: return car.model == "bike", 0.4), "the dock: the bike after 0.5 s in all")
	_secs(0.5)
	_ok(hud.status == "Trzecia fala? Ja jestem przy czwartej kawie." and hud.hint_en == "Third wave? I'm on my fourth coffee.", "the ride's first line")
	_ok(_glow_over(0), "the glow over the first café")
	# The bar fills with the clock; late is red with the cold-coffee line.
	tj._clock = 120.0
	_frame()
	_ok(absf(hud.progress - 0.5) < 0.01 and hud.tint == BROWN, "the bar is half full at 120 s, in brown")
	tj._clock = 241.0
	_frame()
	_ok(_status("KAWA 0/4 → KROPKA.", "Zuzia: „Moja kawa stygnie!”", "Zuzia: \"My coffee's going cold!\"") and hud.tint == RED and hud.count == "+0:01", "late: Zuzia's coffee is going cold, in red")
	tj._clock = 10.0
	_secs(22.0)
	_ok(hud.status == "Barista pyta: V60, Chemex czy Aeropress? Mówisz: kawa." and hud.hint_en == "Barista asks: V60, Chemex or Aeropress? You say: coffee.", "after 22 s the ride's next line")
	# A stamp, then the ✕: the glow goes with the ride.
	var ring0 := _terrain(STOP_DOORS[0])
	_by(ring0, 3.0)
	_secs(1.8)
	_ok(int(tj.order["i"]) == 1, "the first stamp")
	_secs(1.0)
	_abort()
	_ok(_idle() and car.model == "hatch", "the ✕ on the bike: idle, the car again")
	_ok(_glows().is_empty(), "the ✕ takes the glow down")
	tj._played += 400.0
	# A new ride starts clean: the first line, the glow over the first café again.
	_rested()
	_ok(tj.offer_kawa_call(true), "Zuzia's call again")
	_press(0)
	_by(dock, 3.0)
	_ok(_until(func() -> bool: return car.model == "bike", 0.7), "the bike again")
	_secs(0.5)
	_ok(hud.status == "Trzecia fala? Ja jestem przy czwartej kawie." and hud.hint_en == "Third wave? I'm on my fourth coffee.", "the new ride: the first line, not the old joke and not the old count")
	_ok(_glow_over(0), "the new ride: the glow over the first café")
	_abort()
	# Two cafés on one square: the stamp at the first leaves the car standing in the second's ring, and
	# the second stamp wants its own 1.5 s.
	_rig()
	_hour(12.0, 1)
	tj.places["glon_dobra"] = STOP_DOORS[0] + Vector2(3.0, 0.0)
	_at(DOCK + Vector2(0.0, 300.0))
	_secs(0.6)
	_rested()
	_ok(tj.offer_kawa_call(true), "Zuzia's call, the second café beside the first")
	_press(0)
	_by(dock, 3.0)
	_ok(_until(func() -> bool: return car.model == "bike", 0.7), "the bike")
	_by(_terrain(STOP_DOORS[0]), 1.0)
	_secs(1.7)
	_ok(int(tj.order["i"]) == 1, "the first stamp, the car stands in the second café's ring")
	_secs(0.5)
	_ok(int(tj.order["i"]) == 1, "the second café's stamp wants its own 1.5 s")
	_secs(1.5)
	_ok(int(tj.order["i"]) == 2, "...and gets it")
	_abort()
	_mark("O5")


## Who goes first at a look, what a refused call leaves behind, what the calls wait for.
func _o_look() -> void:
	# Mrożulo's call and a slot's request due at one look: the call, and the look ends there.
	_rig()
	_hour(12.0, 4)
	_at(SLOT_A + Vector2(0.0, 30.0))
	_secs(0.1)
	_dz_due()
	_ok(_until_phase(Activity.Phase.OFFER, 0.6) and hud.card == "📞 MROŻULO DZWONI" and str(tj.order["kind"]) == "dzemini", "Mrożulo's call comes first and the slot's request does not take its place")
	_press(1)
	# DESKA's call, the same.
	_rested()
	tj._deski_at = tj._played
	_ok(_until_phase(Activity.Phase.RING, 0.6) and hud.card.begins_with("📞 ") and hud.card.ends_with(" DZWONI") and bool(tj.order.get("call", false)), "DESKA's call comes first and the slot's request does not take its place")
	_ok(tj.primary() and _is_phase(Activity.Phase.OFFER) and _sub() == "offer", "the key answers the ringing call")
	_ok(not tj.padel_busy() and not tj.padel_idle(), "padel_busy() is false while the answered call's card is up, padel_idle() too")
	_press(1)
	# A call put off near the gate stays put off: leaving the gate does not bring it at once.
	_rested()
	_at(GATE + Vector2(0.0, 100.0))
	tj._deski_at = tj._played
	_ok(_quiet(1.1), "no call within 250 m of the gate")
	_at(HOME)
	_ok(_quiet(8.0), "...and the call that was due waits its 1200 s, it does not ring once the car is away")
	# The forced call rings by the court too, and puts the next one off.
	_at(GATE + Vector2(0.0, 10.0))
	_frame()
	tj._deski_at = 0.0
	_ok(tj.padel_ring() and _is_phase(Activity.Phase.RING), "padel_ring() by the court: it rings")
	_ok(is_equal_approx(tj._deski_at, tj._played + 1200.0), "...and the next call is 1200 s away")
	_press(1)
	# The dice of the call: caller, injured and the match's seed by the done jobs and the seconds played.
	for e: Array in [[0, 0.0], [2, 130.4], [3, 777.6], [1, 1500.0]]:
		_rest_call()
		tj.done = int(e[0])
		tj._played = float(e[1])
		var rng := RandomNumberGenerator.new()
		rng.seed = int(e[0]) * 7001 + 53 + roundi(float(e[1]))
		var who: String = O_CALLERS[rng.randi() % 6]
		var hurt: String = INJURED[rng.randi() % 4]
		var seed_next := rng.randi()
		_ok(tj.offer_deski_call(true) and tj.order["customer"] == who and tj.order["hurt"] == hurt and tj.order["seed"] == seed_next, "the call's caller, injured and seed come from the done jobs and the seconds played (%s, %s)" % [who, hurt])
		_press(1)
	# Zuzia waits for the calls too.
	_rig()
	_hour(12.0, 1)
	_at(DOCK + Vector2(0.0, 300.0))
	_secs(0.6)
	_rested()
	tj._kawa_at = tj._played
	hud.calls_ok = false
	_ok(_quiet(1.1), "no Zuzia when the message director says no")
	hud.calls_ok = true
	mission = true
	_ok(_quiet(1.1), "no Zuzia during a mission")
	mission = false
	_ok(_quiet(19.0), "no Zuzia for 19 s after the mission")
	_ok(_until_phase(Activity.Phase.OFFER, 1.6) and hud.card == "📞 ZUZIA DZWONI", "...and then Zuzia rings")
	_ok(not tj.kawa_busy() and not tj.busy(), "kawa_busy() is false while Zuzia's call is up")
	_press(1)
	# A van that is away asks for nothing; a drop that cooled down does not ask at once.
	_rig()
	_hour(22.0, 1)
	_at(HOME)
	_secs(0.6)
	_rested()
	var vr: Vector3 = tj.van["ring"]
	_by(vr, 20.0)
	_ok(_quiet(1.1), "the van is away at 22:00: no request from 20 m")
	_hour(17.0, 5)
	_at(PISTACJA + Vector2(0.0, 50.0))
	_rested()
	_ok(_until_phase(Activity.Phase.OFFER, 0.6) and hud.card == "LIMITKA · PISTACJA", "the drop's request")
	_press(1)
	_ok(_quiet(12.0), "a drop turned down does not ask again for 240 s")
	# The static rule of the calls' wait.
	_ok(Trend.hold_calls(true, 500.0, 0.0, false) and Trend.hold_calls(false, 505.0, 520.0, false) and Trend.hold_calls(false, 600.0, 0.0, true) \
			and not Trend.hold_calls(false, 520.0, 520.0, false), "hold_calls(): a mission, the 20 s, a rescue ringing; and free")
	_mark("O6")


## The call's clocks forgotten: nothing resting.
func _rest_call() -> void:
	_rested()
	tj._deski_at = 1.0e9


## Every offer: the ticker goes out once, the order is what the player is told.
func _o_offers() -> void:
	_rig()
	_hour(12.0, 1)
	_at(HOME)
	_secs(0.6)
	var t0 := hud.tickers
	_ok(tj.offer(0) and hud.tickers == t0 + 1, "a slot's request: the ticker goes out once")
	_ok(tj.offer_czwarty() and hud.tickers == t0 + 2 and hud.card == "CZWARTY · PADELNIA" and _is_phase(Activity.Phase.OFFER), "the fourth player's request takes the place of the slot's that nobody answered, the ticker goes out")
	_ok(tj.offer_drop() and hud.tickers == t0 + 3 and tj.order["word"] == "PISTACJA", "the drop's request: the ticker, the order's word")
	_ok(tj.offer_mlask() and hud.tickers == t0 + 4, "Mrożulo's request: the ticker goes out")
	_ok(tj.offer_dzemini(true) and hud.tickers == t0 + 5, "Mrożulo's call: the ticker goes out")
	_ok(tj.offer_kawa_call(true) and hud.tickers == t0 + 6 and bool(tj.order["call"]) == true, "Zuzia's call: the ticker, the order is a call")
	_press(1)
	# Mrożulo's call tries the next of his spots when today's has no kerb, and shows the van when it is away.
	_rig()
	_hour(12.0, 2)
	_secs(0.6)
	_ok(tj.van.is_empty(), "Tuesday: no spot for the van")
	_rested()
	_ok(tj.offer_dzemini(true) and tj.van["spot"] == "plac_zbawiciela", "the call tries the next spots in turn: Tuesday's has none, Wednesday's has none, Thursday's is plac_zbawiciela")
	_press(1)
	_rig()
	_hour(22.0, 4)
	_secs(0.6)
	_ok(not tj._van_node.visible, "the van is away at 22:00")
	_ok(tj.offer_dzemini(true) and tj._van_node.visible, "Mrożulo's call shows the van, out of its hours")
	_press(1)
	# The van is parked once a day, not at every look.
	_rig()
	_hour(12.0, 1)
	_secs(0.6)
	var asked := jobs.kerbs.size()
	_secs(5.0)
	_ok(jobs.kerbs.size() == asked, "the van is parked once for the day, the kerb is not asked at every look")
	# The map's list: the slots, the van while it is out and not cooling, the drop while it runs and not cooling.
	_rig()
	_hour(17.0, 5)
	_secs(0.6)
	_rested()
	var groups: Array = []
	for e: Dictionary in tj.offer_places():
		groups.append(e["group"])
	_ok(groups == ["trend", "trend", "mlask", "drop"], "Friday 17:00: both open slots, the van and the drop are listed")
	tj._cool[-1] = tj._played + 100.0
	groups.clear()
	for e: Dictionary in tj.offer_places():
		groups.append(e["group"])
	_ok(groups == ["trend", "trend", "mlask"], "a drop that cools down is not listed")
	tj._cool[-1] = 0.0
	tj._cool[-3] = tj._played + 100.0
	groups.clear()
	for e: Dictionary in tj.offer_places():
		groups.append(e["group"])
	_ok(groups == ["trend", "trend", "drop"], "a van that cools down is not listed")
	tj._cool[-3] = 0.0
	_hour(22.0, 5)
	groups.clear()
	for e: Dictionary in tj.offer_places():
		groups.append(e["group"])
	_ok(not groups.has("mlask") and not groups.has("drop"), "the van is away at 22:00 and the drop is over")
	# The fourth player's run is not the DESKA call's.
	_rig()
	_take_cz()
	_ok(tj.busy() and not tj.padel_busy() and not tj.padel_idle(), "padel_busy() is false during the fourth player's run")
	_abort()
	_rig()
	_hour(12.0, 1)
	_rested()
	_at(SLOT_A + Vector2(0.0, 30.0))
	_ok(_until_phase(Activity.Phase.OFFER, 0.6) and not tj.padel_idle() and not tj.padel_busy(), "padel_idle() is false while a request is up")
	_press(1)
	# The helicopter lands on the court: the arcade is told.
	var court2: Array = []
	_rig()
	tj.enter_padel = func(d: Dictionary) -> void: court2.append(d)
	flying = true
	heli = Vector3(HOME.x, 50.0, HOME.y)
	_frame()
	_ok(tj.padel_meet() and court2.size() == 1 and court2[0]["flew"] == true, "padel_meet() from the air: the court is told the player flew")
	flying = false
	tj.arcade_done(2, 0, {})
	_press(0)
	_mark("O7")


## The sticker looked for twice a second, from the moment the state's clock was last set.
func _o_beat() -> void:
	# After the pickup of a slot's job.
	_rig({"dzemini_mlask": true})
	fronts.placed = false
	_hour(12.0, 1)
	_at(HOME)
	_secs(1.2)
	_take_slot(0)
	_secs(0.2)
	_by(tj.order["ring"], 3.0, 8.0)
	_ok(_stays_stage(Trend.Stage.PICKUP, 2.0), "the pickup is not made at 8 m/s")
	_pick_up(1.5)
	fronts.placed = true
	var n := 0
	while _stickers() == 0 and n < 45:
		_frame()
		n += 1
	_ok(n >= 29 and n <= 32, "the sticker goes up on the wall half a second after the way began (frame %d), not at the next frame" % n)
	var wall: Vector3 = fronts.venue_wall("dzemini_kebab")["p"]
	_ok(_sticker_node().global_position.is_equal_approx(wall + Vector3(1.8, 2.3, 0.16)), "the sticker hangs 2.3 m above the wall's foot, 1.8 m along, 0.16 m out")
	_abort()
	# After the review card.
	_rig({"dzemini_mlask": true})
	fronts.placed = false
	_hour(12.0, 1)
	_at(HOME)
	_secs(1.2)
	_rested()
	var vr: Vector3 = tj.van["ring"]
	_by(vr, 20.0)
	_ok(_until_phase(Activity.Phase.OFFER, 0.6), "Mrożulo's request")
	_press(0)
	_pick_up(1.5)
	_arrive()
	_secs(0.2)
	_press(0)
	_ok(_in_stage(Trend.Stage.DELIVER) and _sub() == "sticker", "the sticker's leg")
	fronts.placed = true
	n = 0
	while _stickers() == 0 and n < 45:
		_frame()
		n += 1
	_ok(n >= 29 and n <= 32, "the sticker goes up half a second after the sticker's leg began (frame %d)" % n)
	_abort()
	_mark("O8")
