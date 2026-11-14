extends SceneTree
## The street races on the activity kit (scripts/rivals.gd, tech-debt TD-1), played headless: the real Rivals
## and the real Traffic on the real lane graph (map/centrum.json; skipped without it), the real director
## (activities.gd) with a probe activity beside it, and the shared stand-ins of tools/fakes.gd (extended below
## where rivals.gd asks for more: the result card's picture, the minimap's final diamond, the ghost finger, a
## wallet's ladder, a car that flashes). A fresh world (traffic, rivals, stand-ins) for every part. What it
## pins is what the player sees, from the kit's side (phase, busy, the director's answers, the card and whose
## it is, the status line, the target, the end) and from the race's (the prompt, the stages, the pay, the
## words); never a race's time, route or margin, and a winner only where the pace or the finish line makes it
## certain (the autopilot's ghost at a racer's pace, or at half a car's; a car put on the finish).
##   A. a ladder race, won: the prompt, the flash, the stages in order, what the race asks of the kit while it
##      runs, the win card and its pay, the autopilot's tap off for it, the OK that ends it, the cool-down;
##   B. the result card is the race's own: another card over it and its press change nothing, and the race's
##      card is back when the screen is free;
##   C. lost: the lose card, no pay, the lost streak; D. given up with the ✕ (prompt, challenge, countdown,
##      race, under the result card, idle);
##   E. what holds a challenge back, one by one (and Spacer's quiet), each released again;
##   F. Halina's roll-up for the guided first race: rolling up, the flash back, the start hold, declined, a job
##      on at the call;
##   I-N (the gaps the deliberate breaks of rivals.gd found): I. the kit's fields and what setup connects
##   (the flag, the HUD's button, bumps, the ladder's wallet, the dice); J. the start and the stages (the flag's
##   colour and size, the held rival and ghost, the lamps, the route, the banner's colours, the clock, the place,
##   a car in the air); K. the prompt's sight, the approach line, who can be challenged; L. the result (the rival
##   let go, the escape bonus, the lose card that stays, the cool-downs, the first race's result); M. Halina's
##   roll-up (from the air or a prompt, her pace, what stops her, the nudge, how near she stops); N. Trzy mosty's
##   start look, Seba's line, the bridges counted from the first, Seba not home in the circle, and the autopilot's
##   car (the tail, the ghost, the collisions).
##   G. a locked rival: the prompt says what is missing, a flash is refused; H. Trzy mosty at night: Seba at the
##      start, the marker, the final's stages, won and given up.
## Prints "check_rivals: OK (N checks; A-H, S s)" or one "  problem: ..." line per failed fact under
## "check_rivals: PROBLEMS" (exit 1). `-- --only=A,C` runs some of the parts (a debugging aid).
##   godot --headless --path game --script res://tools/check_rivals.gd

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Rivals := preload("res://scripts/rivals.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Fakes := preload("res://tools/fakes.gd")
const Beacon := preload("res://scripts/beacon.gd")
const RaceSession := preload("res://scripts/race_session.gd")
const FollowCamera := preload("res://scripts/follow_camera.gd")

const DT := 1.0 / 60.0
const MAP_FILE := "res://map/centrum.json"
## Where the car stands at the start of every part (Marszałkowska by the first scene).
const HOME := Vector2(-961.6, 95.0)
const NIGHT := 2
const INF3 := Vector3.INF
## The ghost's pace: a racer's (a sure win) and half a car's (a sure loss).
const WIN_PACE := 12.0
const LOSE_PACE := 0.5
## The rivals' indexes in rivals.gd RIVALS.
const SEBA := 0
const MIKE := 1
const HALINA := 2
const SLOIK := 3
const ZBYSZEK := 4
const BARTEK := 5
const PINK := Color("#ff4fd8")
const WIN_GREEN := Color("#56d68a")
const LOSE_RED := Color("#e2574c")
const LOCKED_GREY := Color("#9a93ab")
const GOLD := Color("#ffcf3a")
const PARTS := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N"]
const GROUNDED := ["Najpierw dokończ wyścig", "Finish the race first"]
const HALINA_APPROACH := "Dziecko, nie siedź mi tak na ogonie, babcia się spieszy!"
const HALINA_CHALLENGE := ["Spieszę się %s. Dogonisz babcię?", "Promocja na ogórki się kończy! Jedziemy %s!"]
const HALINA_WIN := ["W moich czasach to się jeździło, a nie wlokło!", "Zjedz coś, dziecko, bo blade jesteś i wolne."]
const HALINA_LOSE := ["Ech, to przez te nowe progi zwalniające.", "Dobre dziecko. Masz tu pierogi na drogę."]
const SLOIK_CHALLENGE := ["W Radomiu nikt by się nie ścigał. Ale dobra: %s!", "Mam w bagażniku słoiki od mamy. Ostrożnie, ale szybko: %s!"]
const MIKE_REFUSE := "Nie mam cię w kalendarzu. Umów się przez asystentkę."
const MIKE_APPROACH := "Sorry, mam call. Ale jak mrugniesz, to wchodzę w to."
const SEBA_CHALLENGE := "Trzy mosty, mordo. Kto pierwszy pod Narodowym, ten król."
const SEBA_WAIT := "Czekam, mordo. Trzy mosty, jedna noc. Wjedź w światło."
const SEBA_LOSE := "Szacun, mordo. Dziś cała Warszawa jest twoja."
const SEBA_WIN := "Wisła jest moja, mordo. Trzy razy ci to pokazałem."


## hud.gd as rivals.gd asks of it beyond the shared stand-in: the card's picture (freed at once), the
## minimap's final diamond, the ghost finger, the wallet's numbers, the full map (`cards_up`), the pixel size.
class PlayHud extends Fakes.Hud:
	var pt := 2.0
	var map_open := false
	var finger := false
	var finger_calls: Array[bool] = []
	var finals: Array[Vector2] = []
	var arts := 0
	var wallets: Array = []
	## Each banner as [text, colour], every call.
	var banner_cols: Array = []

	func show_banner(text: String, a: Color) -> void:
		super(text, a)
		banner_cols.append([text, a])

	func cards_up() -> bool:
		return super() or map_open

	func set_card_art(art: Control) -> void:
		arts += 1
		art.free()

	func set_minimap_final(p: Vector2, _colour: Color) -> void:
		finals.append(p)

	func ghost_finger(on: bool) -> void:
		finger = on
		finger_calls.append(on)

	func finger_shown() -> bool:
		return finger

	func set_wallet(zl: int, respect: int, _gained := 0) -> void:
		wallets.append([zl, respect])


## bubbles.gd's name tags (rivals.gd tags the rivals near the player): who is tagged now, by anchor.
class PlayBubbles extends Fakes.Bubbles:
	var tagged := {}

	func tag(anchor: Variant, text: String, _colour: Color, _height := 2.6) -> void:
		tagged[anchor] = text

	func untag(anchor: Variant) -> void:
		tagged.erase(anchor)


## wallet.gd's ladder (the rungs beaten, by id) and its `changed` signal, which rivals.gd listens to.
class PlayWallet extends Fakes.Wallet:
	signal changed(zl: int, respect: int, gained: int)
	var ladder := {}

	func pay(amount: int, gain := 0, kind := "") -> void:
		super(amount, gain, kind)
		changed.emit(money, respect, amount)


## missions.gd's `has_target` (the rescue calls have somebody to go to).
class PlayCalls extends Fakes.Calls:
	var target := false

	func has_target() -> bool:
		return target


## car.gd as rivals.gd drives and asks it: the lights, the autopilot's fields, the top speed.
class PlayCar extends Fakes.Car:
	var flashes := 0
	var braking := false
	var parked := false
	var max_speed := 30.0
	var top_mult := 1.0
	var target_dir := Vector3.ZERO
	var collision_mask := 1

	func flash_lights() -> void:
		flashes += 1


## time_of_day.gd's `mode` and `lights_on`.
class PlayTod extends Node:
	var mode := 0
	var lights_on := 0.0


## Another activity of the kit beside the race: on (a job, a tour), or with a request card up.
class Probe extends Activity:
	pass


var problems: Array[String] = []
var _n := 0
var _part := ""
var _counts := {}
var _marks: Array[String] = []
var _only := PackedStringArray()
var _data: Dictionary = {}
var _graph: LaneGraph
var _map: Fakes.FlatMap
var _traffic: Traffic
var _world: Node3D
var _cam: Camera3D
var _hud: PlayHud
var _bub: PlayBubbles
var _calls: PlayCalls
var _wallet: PlayWallet
var _tod: PlayTod
var _car: PlayCar
var _rv: Rivals
var _dir: Activities
var _probe: Probe
var _auto := false
var _flying := false
var _vel := Vector3.ZERO
var _frames := 0
## Every state rivals.gd's `state` took, in order, without repeats; and the banners shown, the same way.
var _seq: Array[int] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_only = a.trim_prefix("--only=").split(",", false)
	var text := FileAccess.get_file_as_string(MAP_FILE)
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	if not parsed is Dictionary:
		# A clone without the map data has no street to race on (as check_race_planner.gd).
		print("check_rivals: OK (skipped: no %s)" % MAP_FILE)
		quit(0)
		return
	_data = parsed
	_map = Fakes.FlatMap.new()
	root.add_child(_map)
	_graph = LaneGraph.new(_data["graph"], _map)
	_part_run("A", _a_win)
	_part_run("B", _b_card)
	_part_run("C", _c_lose)
	_part_run("D", _d_give_up)
	_part_run("E", _e_holds)
	_part_run("F", _f_first)
	_part_run("G", _g_locked)
	_part_run("H", _h_final)
	_part_run("I", _i_setup)
	_part_run("J", _j_stages)
	_part_run("K", _k_prompt)
	_part_run("L", _l_result)
	_part_run("M", _m_rollup)
	_part_run("N", _n_final_drive)
	for part: String in PARTS:
		if (_only.is_empty() or part in _only) and not _marks.has(part):
			problems.append("part %s did not run to its end (a script error?)" % part)
	if problems.is_empty():
		print("check_rivals: OK (%d checks; A-N, %.1f s)" % [_n, (Time.get_ticks_msec() - t0) / 1000.0])
		quit(0)
	else:
		print("check_rivals: PROBLEMS")
		for p in problems:
			print("  problem: " + p)
		quit(1)


func _part_run(name: String, fn: Callable) -> void:
	if not _only.is_empty() and not (name in _only):
		return
	_part = name
	var t0 := Time.get_ticks_msec()
	var n0 := _n
	fn.call()
	_free_world()
	_marks.append(name)
	if not _only.is_empty():
		print("part %s: %d facts, %.1f s" % [name, _n - n0, (Time.get_ticks_msec() - t0) / 1000.0])


func _ok(cond: bool, what: String) -> void:
	_n += 1
	if not cond:
		problems.append("%s: %s" % [_part, what])


func _eq(got: Variant, want: Variant, what: String) -> void:
	_n += 1
	if typeof(got) != typeof(want) or got != want:
		problems.append("%s: %s (got %s, wanted %s)" % [_part, what, str(got), str(want)])


# --- the world -------------------------------------------------------------------------------------

## A fresh world: the traffic, the rivals on the kit with the probe beside them, the stand-ins, the car on
## a lane at `at`. `auto`: the autopilot's ghost, at `pace`. `night`: the time of day.
func _new_world(auto: bool, pace := WIN_PACE, night := false, at := HOME) -> void:
	_free_world()
	_graph.clock = 0.0
	_world = Node3D.new()
	root.add_child(_world)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = FollowCamera.DEFAULT_SIZE
	root.add_child(_cam)
	_traffic = Traffic.new()
	root.add_child(_traffic)
	_traffic.setup(_graph, _map, _cam, {})
	_traffic.set_process(false)
	_traffic.set_physics_process(false)
	_traffic.spawning = false
	_hud = PlayHud.new()
	root.add_child(_hud)
	_bub = PlayBubbles.new()
	root.add_child(_bub)
	_calls = PlayCalls.new()
	root.add_child(_calls)
	_wallet = PlayWallet.new()
	root.add_child(_wallet)
	_tod = PlayTod.new()
	_tod.mode = NIGHT if night else 0
	root.add_child(_tod)
	_car = PlayCar.new()
	root.add_child(_car)
	var hit := _graph.snap(at, 120.0, Vector2.ZERO, true)
	var e: int = hit[0]
	var q := _graph.point_at(e, float(hit[2]), _graph.lane_offset(e, int(hit[1])))
	var dir := _graph.direction(e, float(hit[2]))
	_car.global_position = Vector3(q.x, _graph.height(e, float(hit[2])), q.y)
	_car.rotation.y = atan2(-dir.x, -dir.y)
	_auto = auto
	_flying = false
	_vel = Vector3.ZERO
	_frames = 0
	_seq.clear()
	_rv = Rivals.new()
	root.add_child(_rv)
	_rv.set_process(false)
	_rv.autopilot = auto
	_rv.ghost_pace = pace
	_rv.wallet = _wallet
	_rv.tod = _tod
	_rv.graph = _graph
	_rv.traffic = _traffic
	_rv.hud = _hud
	_rv.bubbles = _bub
	_rv.missions = _calls
	_rv.map = _map
	_rv.car = _car
	_rv.setup(_world, _data)
	_dir = Activities.new()
	_dir.add(_rv, func() -> bool: return true)
	_probe = Probe.new()
	_probe.tag = "probe"
	root.add_child(_probe)
	_probe.set_process(false)
	_dir.add(_probe)


func _free_world() -> void:
	for n: Node in [_rv, _probe, _traffic, _world, _cam, _hud, _bub, _calls, _wallet, _tod, _car]:
		if n != null and is_instance_valid(n):
			n.free()
	_rv = null
	_probe = null
	_traffic = null
	_world = null
	_cam = null
	_hud = null
	_bub = null
	_calls = null
	_wallet = null
	_tod = null
	_car = null
	_dir = null


## One frame of the game in main.gd's order: the autopilot moves the car, the traffic and the rivals step.
func _frame() -> void:
	var driven := false
	if _auto:
		driven = _rv.drive_player()
	if not driven:
		_car.vel = _vel
		_car.global_position += _car.vel * DT
	_traffic.player_pos = _car.global_position
	_traffic.player_vel = _car.vel if not _flying else Vector3.ZERO
	_traffic.player_on_road = not _flying
	_rv.flying = _flying
	var basis := Basis(Vector3.UP, deg_to_rad(45.0)) * Basis(Vector3.RIGHT, deg_to_rad(-FollowCamera.DEFAULT_PITCH))
	_cam.global_transform = Transform3D(basis, _car.global_position + basis.z * 150.0)
	_traffic._process(DT)
	_rv._process(DT)
	_frames += 1
	var st := int(_rv.state)
	if _seq.is_empty() or _seq[_seq.size() - 1] != st:
		_seq.append(st)


func _run_frames(n: int) -> void:
	for i in n:
		_frame()


## Frames until `cond` holds (at most `cap`); the frames it took, or -1 and a problem.
func _until(cond: Callable, cap: int, what: String) -> int:
	for i in cap:
		if cond.call():
			return i
		_frame()
	if cond.call():
		return cap
	problems.append("%s: never came: %s (%d frames)" % [_part, what, cap])
	_n += 1
	return -1


## The state is `st` now or within `cap` frames.
func _reach(st: int, cap: int) -> bool:
	return _until(func() -> bool: return int(_rv.state) == st, cap, "state %d" % st) >= 0


## The world as the player's first minutes have it, the rival `i` put ahead and tailed by the autopilot.
func _tail(i: int) -> void:
	_frame()
	_rv.put_ahead(i)
	_rv.tail = i


## Every banner text the HUD showed, in order, without repeats.
func _banners() -> Array[String]:
	var out: Array[String] = []
	for b in _hud.banners:
		if out.is_empty() or out[out.size() - 1] != b:
			out.append(b)
	return out


## Whether the rival's own challenge line is the last thing said (one of two, finish filled in).
func _said_one_of(lines: Array, finish: String) -> bool:
	for l in lines:
		if _bub.said.size() > 0 and _bub.said[_bub.said.size() - 1] == String(l) % finish:
			return true
	return false


## The card up is rivals.gd's, in the shape of a result card of the race.
func _card_is_result(title_start: String, en: String, accent: Color) -> void:
	_ok(_hud.card_is(_rv), "the result card is the race's own (the HUD sends its press to rivals)")
	_ok(_hud.card.begins_with(title_start), "the result card's title begins %s (is %s)" % [title_start, _hud.card])
	_eq(_hud.card_en, en, "the result card's English title")
	_eq(_hud.buttons, 1, "the result card has one button")
	_eq(Array(_hud.button_words), ["OK"], "the result card's button")
	_eq(_hud.accent, accent, "the result card's colour")
	_ok(not _hud.low, "the result card sits in the middle of the screen")
	_ok(not _hud.stacked, "the result card's button is not stacked")


## Everything the race put up is down and the kit is idle (the card pressed, or the race dropped).
func _ended(what: String) -> void:
	_eq(int(_rv.state), 0, "%s: the state is CRUISE" % what)
	_eq(_rv.phase, Activity.Phase.IDLE, "%s: the kit's phase is IDLE" % what)
	_ok(not _rv.busy(), "%s: busy() is false" % what)
	_ok(_rv.idle(), "%s: idle() is true" % what)
	_ok(not _dir.busy(), "%s: the director has nothing on" % what)
	_ok(_dir.current() == null, "%s: the director names nobody" % what)
	_eq(_dir.busy_tag(), "", "%s: the director's tag is empty" % what)
	_ok(not _hud.card_showing(), "%s: no card is up" % what)
	_eq(_hud.status, "", "%s: the status line is down" % what)
	_eq(_hud.status_title, "", "%s: the status line's title is down" % what)
	_ok(not _rv._beacon.visible, "%s: the beacon is hidden" % what)
	_ok(_dir.targeted() == null, "%s: nothing is the target" % what)
	_ok(not _rv.has_target(), "%s: has_target() is false" % what)
	_ok(not _calls.paused, "%s: the rescue calls are free again" % what)
	_ok(not _rv.racing(), "%s: racing() is false" % what)
	_ok(not _rv.in_race(), "%s: in_race() is false" % what)
	_eq(_dir.grounded(), [], "%s: the helicopter is not refused" % what)
	_ok(_probe.free_now.call(), "%s: another activity may start" % what)
	_eq(_hud.banner, "", "%s: no banner is up" % what)


# --- A. a ladder race, won -------------------------------------------------------------------------

func _a_win() -> void:
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	_ok(not _wallet.ladder.is_empty() and _hud.wallets.size() == 1, "the preset beat the rungs and told the HUD's wallet")
	_tail(HALINA)
	# The prompt behind a rival: nothing is on, the phase stays idle.
	_ok(_reach(1, 900), "tailing Halina brings a PROMPT")
	_eq(_rv.rival, HALINA, "the prompt is Halina's")
	_eq(_rv.phase, Activity.Phase.IDLE, "the prompt: the kit's phase is still IDLE")
	_ok(not _rv.busy(), "the prompt: busy() is false")
	_ok(_rv.idle(), "the prompt: idle() is true")
	_ok(not _dir.busy() and _dir.current() == null, "the prompt: the director has nothing on")
	_ok(_probe.free_now.call(), "the prompt: another activity may still start")
	_ok(_hud.challenge.begins_with("WYŚCIG · PANI HALINA"), "the HUD shows Halina's challenge (%s)" % _hud.challenge)
	_eq(_hud.challenge_sub, "Dotknij albo L: mrugnij światłami", "the challenge's hint")
	_eq(_hud.challenge_sub_en, "Tap or L: flash your lights", "the challenge's English hint")
	_eq(_hud.challenge_accent, Color("#86d3b0"), "the challenge in Halina's colour")
	_ok(_rv.calling(), "the prompt counts as calling()")
	_ok(not _rv.first_waiting(), "the prompt is not the first race's roll-up")
	_ok(not _rv.has_target() and _dir.targeted() == null, "the prompt has no target")
	_ok(_bub.said.has(HALINA_APPROACH), "Halina says her approach line")
	_ok(_bub.tagged.has(_rv._nodes[HALINA]) and _bub.tagged[_rv._nodes[HALINA]] == "Pani Halina", "Halina wears her name tag")
	_eq(_hud.mini_dots, 6, "the minimap has a dot for each of the six rivals")
	_eq(_hud.cards.size(), 0, "no card was shown by a prompt")
	_run_frames(20)
	_eq(int(_rv.state), 1, "the prompt waits for the flash (20 frames on)")
	_eq(_car.flashes, 0, "the car did not flash by itself")
	# The flash: the race is on at once.
	var closed0 := _calls.closed
	var pills0 := _hud.pills_hidden
	var said0 := _bub.said.size()
	_rv.flash()
	_eq(_car.flashes, 1, "the flash flashed the car's lights once")
	_eq(int(_rv.state), 2, "the flash starts the CHALLENGE")
	_eq(_rv.phase, Activity.Phase.RUN, "the challenge: the kit's phase is RUN")
	_ok(_rv.busy() and not _rv.idle(), "the challenge: busy() and not idle()")
	_ok(_dir.current() == _rv, "the challenge: the director names rivals")
	_eq(_dir.busy_tag(), "rival race", "the challenge: the director's tag")
	_ok(_dir.busy(), "the challenge: the director is busy")
	_ok(not _dir.job_on(), "the challenge: no side job is on")
	_ok(not _probe.free_now.call(), "the challenge: another activity may not start")
	_ok(not _dir.may_start(_probe), "the challenge: the director refuses another's start")
	_eq(_hud.challenge, "", "the challenge: the HUD's prompt is down")
	_ok(_hud.challenges_hidden > 0, "the challenge: the prompt was taken down")
	_ok(_hud.banner.begins_with("WYŚCIG "), "the challenge: the banner names the race (%s)" % _hud.banner)
	_ok(_calls.paused, "the challenge: the rescue calls wait")
	_eq(_calls.closed, closed0 + 1, "the challenge: the rescue line was closed once")
	_ok(_hud.pills_hidden > pills0, "the challenge: the context button was taken down")
	_ok(not _hud.card_showing(), "the challenge: no card is up")
	_eq(_hud.cards.size(), 0, "the challenge: no card was shown")
	_ok(_rv.racing() and not _rv.in_race(), "the challenge: racing() but not in_race()")
	_eq(_dir.grounded(), GROUNDED, "the challenge: the helicopter is refused")
	_ok(not _rv.has_target(), "the challenge: no target yet")
	_ok(not _rv.calling(), "the challenge: no longer calling()")
	_ok(_bub.said.size() == said0 + 1 and _said_one_of(HALINA_CHALLENGE, _rv._finish["pl"]), "the challenge: Halina names the finish (%s)" % str(_bub.said.back()))
	var finish_pos: Vector3 = _rv._finish["pos"]
	_rv.flash()
	_eq(_car.flashes, 1, "a second flash in the challenge does nothing")
	_eq(int(_rv.state), 2, "a second flash leaves the challenge as it is")
	# CHALLENGE, COUNTDOWN, RACE in order, with the stages' lengths (the countdown is 3, 2, 1, START!).
	var in2 := _until(func() -> bool: return int(_rv.state) == 3, 400, "COUNTDOWN")
	_ok(in2 > 140 and in2 < 175, "the challenge lasts about 2.6 s (%d frames)" % in2)
	_ok(_rv.has_target() and _dir.targeted() == _rv, "the countdown: the finish is the target")
	_ok(_rv._beacon.visible, "the countdown: the beacon stands at the finish")
	_ok(_rv._beacon.global_position.distance_to(finish_pos) < 3.0, "the countdown: the beacon is at the finish")
	_ok(_rv.racing() and not _rv.in_race(), "the countdown: racing() but not in_race()")
	_eq(_dir.grounded(), GROUNDED, "the countdown: the helicopter is refused")
	_eq(_rv.target_position(), finish_pos, "the countdown: target_position is the finish")
	_eq(_rv.target_colour(), PINK, "the race's colour is pink")
	_ok(not _hud.finger and _hud.finger_calls.is_empty(), "no ghost finger in an ordinary race")
	_run_frames(2)
	_ok(_hud.status != "" and _hud.status_title.begins_with("WYŚCIG · "), "the countdown: the status line is up (%s)" % _hud.status_title)
	_eq(_hud.tint, PINK, "the status line is pink")
	_ok(_hud.distance.ends_with(" m"), "the status line gives the metres")
	_ok(_hud.status.begins_with("Jedź "), "the countdown's hint says where to drive (%s)" % _hud.status)
	var in3 := _until(func() -> bool: return int(_rv.state) == 4, 400, "RACE")
	_ok(in3 > 170 and in3 < 190, "the countdown lasts 3 s (%d frames)" % in3)
	var banners := _banners()
	var at3 := banners.find("3")
	_ok(at3 >= 0 and banners.find("2") == at3 + 1 and banners.find("1") == at3 + 2 and banners.find("START!") == at3 + 3,
			"the countdown reads 3, 2, 1, START! (%s)" % str(banners))
	_eq(_seq, [0, 1, 2, 3, 4], "the states came in order")
	_run_frames(60)
	_ok(_hud.banner != "START!", "START! goes after a second")
	# The race: what it asks of the kit.
	_ok(_rv.racing() and _rv.in_race(), "the race: racing() and in_race()")
	_ok(_rv.busy() and _dir.current() == _rv, "the race: busy, and the director's current")
	_ok(_rv.has_target(), "the race: has_target()")
	_ok(_dir.targeted() == _rv, "the race: the director's target is rivals")
	_ok(_rv._beacon.visible, "the race: the beacon is up")
	_ok(_hud.status != "" and _hud.status_title.begins_with("WYŚCIG · "), "the race: the status line is up")
	_ok(_hud.badge == "1ST" or _hud.badge == "2ND", "the race: the status line carries the place (%s)" % _hud.badge)
	_ok(_hud.count.contains(":") and _hud.count.contains("."), "the race: the status line carries the clock (%s)" % _hud.count)
	_eq(_rv.grounded(), GROUNDED, "the race: grounded()")
	_eq(_dir.grounded(), GROUNDED, "the race: the director refuses the helicopter the same")
	_eq(_rv.stop_spot(), INF3, "the race: no stop ring")
	_eq(_rv.target_source(), "race", "the race: its target gets no camera look")
	_ok(_rv.main_target(true), "the race: the guide's main target")
	_eq(_rv.main_target(false), _rv.main_race(), "the race: main_target(false) is main_race()")
	_ok(not _rv.main_race(), "Halina on a ladder of six beaten is a side race")
	_ok(_rv.drive_player(), "the race: the ghost drives the player")
	_eq(_rv.target_position(), finish_pos, "the race: target_position is the finish")
	_eq(_rv.target_label(120), "120 m", "the race: the arrow's words")
	_ok(_rv.target_arrow(), "the race: the arrow shows")
	_ok(not _rv.calling() and not _rv.first_waiting(), "the race: not calling")
	_ok(_hud.route.size() > 1 and _hud.route_owner == "race", "the race: the minimap shows the way (%d points)" % _hud.route.size())
	_ok(not _dir.job_on(), "the race: no side job")
	_ok(not _probe.free_now.call(), "the race: another activity may not start")
	_eq(_hud.shown, 0, "the race: no card was shown")
	_ok(_rv.phase == Activity.Phase.RUN, "the race: the phase is RUN")
	# The win.
	_ok(_reach(5, 14000), "the ghost wins the race (the result card)")
	_eq(_seq, [0, 1, 2, 3, 4, 5], "the states came in order to RESULT")
	_eq(_rv.phase, Activity.Phase.RUN, "the result: the kit's phase is still RUN")
	_ok(_rv.busy() and _dir.current() == _rv and _dir.busy_tag() == "rival race", "the result: the race is still the one that is on")
	_card_is_result("WYGRANA", "Win · 1st", WIN_GREEN)
	_ok(_hud.body.begins_with("Meta: "), "the win card's text starts with the finish (%s)" % _hud.body)
	_ok(_hud.body.contains("Pani Halina za tobą"), "the win card names Halina behind the player")
	_ok(_hud.body.contains("+60 zł"), "the win card gives the stake")
	_ok(_hud.body.contains("szacunek +20"), "the win card gives a rematch's respect")
	_ok(_hud.body_en.begins_with("You beat Pani Halina to "), "the win card's English (%s)" % _hud.body_en)
	_ok(_hud.body_en.contains("+60 zł") and _hud.body_en.contains("respect +20"), "the win card's English gives the pay")
	_ok(HALINA_LOSE.any(func(l: String) -> bool: return _hud.body.contains("„%s”" % l)), "the win card quotes Halina's grudging line")
	_ok(HALINA_LOSE.has(_bub.said.back()), "the rival talks back with a grudging line (%s)" % str(_bub.said.back()))
	_eq(_wallet.payments, [[60, 20, "race"]], "the win pays Halina's stake and a rematch's respect, once")
	_eq(_wallet.money, 60, "the wallet has the stake")
	_ok(_wallet.best.has("race:" + String(_rv._finish["name"])), "the win records the time on the finish")
	_eq(_hud.arts, 1, "the win card has the picture of both ways")
	_eq(_hud.status, "", "the result: the status line is down")
	_ok(not _rv._beacon.visible, "the result: the beacon is down")
	_eq(_hud.banner, "", "the result: no banner")
	_ok(not _rv.has_target() and _dir.targeted() == null, "the result: no target")
	_ok(not _rv.racing() and not _rv.in_race(), "the result: not racing")
	_ok(not _rv.raced(), "the result: not yet raced() (the card is open)")
	_ok(_hud.routes_cleared > 0 and _hud.route.is_empty(), "the result: the minimap's way is gone")
	_eq(_dir.grounded(), [], "the result: the helicopter is free again")
	_ok(not _rv.main_race(), "the result: no main race")
	_ok(_calls.paused, "the result: the rescue calls still wait")
	_ok(not _probe.free_now.call(), "the result: another activity may not start under the card")
	_ok(not _rv.drive_player(), "the result: nobody drives the player")
	_eq(_rv.stop_spot(), INF3, "the result: no stop ring")
	var after_win_closed := _calls.closed
	# The autopilot's tap is off for the card: ten seconds on it is still up.
	_run_frames(600)
	_eq(int(_rv.state), 5, "ten seconds on, the result card is still up (the autopilot does not tap it)")
	_ok(_hud.card_is(_rv), "ten seconds on, the card is still the race's")
	_eq(_hud.shown, 1, "ten seconds on, still one card shown")
	_eq(_wallet.payments.size(), 1, "ten seconds on, still one payment")
	_eq(_rv._auto_button(), -1, "the autopilot has no button on the result card")
	_ok(not _rv.raced(), "ten seconds on, not raced() yet")
	# OK ends it.
	_hud.press(0)
	_ended("OK")
	_frame()
	_eq(_seq, [0, 1, 2, 3, 4, 5, 0], "the states ended with CRUISE")
	_ok(_rv.raced(), "after OK the rival counts as raced")
	_eq(_calls.closed, after_win_closed + 1, "OK closed the rescue line once more")
	_eq(_hud.broadcast, 0, "no press went to every listener")
	_eq(_wallet.payments.size(), 1, "OK pays nothing more")
	_eq(_hud.cards, ["WYGRANA · 1. MIEJSCE"], "one card in the whole race")
	# The cool-down (25 s from the finish, ten of them went under the card): the same rival does not
	# challenge again at once, and does after a while.
	var again := false
	for i in 480:
		_frame()
		if int(_rv.state) == 1:
			again = true
			break
	_ok(not again, "Halina does not challenge again in the 8 s after OK")
	_ok(_until(func() -> bool: return int(_rv.state) == 1, 1500, "the next prompt") >= 0, "Halina challenges again later")
	_ok(not _rv.raced(), "a new prompt after a race: not raced() (it asks the state)")


# --- shared by the parts ---------------------------------------------------------------------------

## A world with rival `i` tailed and the race on its way to the RACE state: the ladder's first `rungs` rungs beaten.
func _race_on(i: int, rungs: int, pace := WIN_PACE) -> void:
	_new_world(true, pace)
	if rungs > 0:
		_rv.preset_ladder(rungs)
	_tail(i)
	_reach(1, 1500)
	_run_frames(10)
	_rv.flash()
	_reach(4, 600)
	_run_frames(30)


## The autopilot off and the car on the finish (the next frames: home, a certain win).
func _finish_now() -> void:
	_auto = false
	_vel = Vector3.ZERO
	_car.global_position = _rv.target_position()
	_car.vel = Vector3.ZERO
	_run_frames(3)


# --- B. the result card is the race's own ----------------------------------------------------------

func _b_card() -> void:
	_race_on(SLOIK, 6)
	_finish_now()
	_ok(_reach(5, 60), "a car on the finish wins the race")
	_card_is_result("WYGRANA", "Win · 1st", WIN_GREEN)
	var title := _hud.card
	var body := _hud.body
	_eq(_wallet.payments, [[90, 20, "race"]], "Słoik's stake was paid once")
	# Someone else's card over it, and its press.
	_hud.show_card("INNA KARTA", "tekst", PackedStringArray(["OK"]), Color.WHITE, false, "OTHER CARD", "text")
	_ok(not _hud.card_is(_rv), "another card is over the result card")
	_hud.press(0)
	_eq(_hud.broadcast, 1, "the press of the other card went to every listener")
	_eq(int(_rv.state), 5, "its press does not end the race")
	_run_frames(120)
	_eq(int(_rv.state), 5, "the race stays in RESULT under the other card")
	_eq(_hud.card, "INNA KARTA", "the other card stays up (the race does not take it down)")
	_ok(not _hud.card_is(_rv), "the other card is not the race's")
	_eq(_hud.shown, 2, "the race does not put its card over the other")
	_ok(_rv.busy() and _dir.current() == _rv, "the race is still on under the other card")
	_eq(_wallet.payments.size(), 1, "nothing was paid again")
	# Taken down: the race's own card is back.
	_hud.hide_card()
	_run_frames(3)
	_ok(_hud.card_is(_rv), "the race's card is back when the screen is free")
	_eq(_hud.card, title, "the card that is back has the same title")
	_eq(_hud.body, body, "the card that is back has the same text")
	_eq(_hud.card_en, "Win · 1st", "the card that is back has its English title")
	_eq(_hud.shown, 3, "the card was shown once more")
	_eq(int(_rv.state), 5, "still in RESULT")
	_run_frames(120)
	_eq(_hud.shown, 3, "the card is put back once, not every frame")
	_hud.press(0)
	_ended("OK after the card came back")
	_ok(_rv.raced(), "the race counts as raced")
	_eq(_wallet.payments.size(), 1, "still one payment")


# --- C. lost ---------------------------------------------------------------------------------------

func _c_lose() -> void:
	_race_on(HALINA, 0, LOSE_PACE)
	_eq(int(_rv.state), 4, "Halina's race is on")
	_ok(_rv.main_race(), "Halina is the ladder's next rung: the race is the main line's")
	_ok(_rv.main_target(false), "main_target(false) is true for the next rung")
	_ok(not _rv.first_race, "an ordinary race is not the guided first one")
	_ok(_reach(5, 16000), "the slow ghost loses the race")
	_card_is_result("PRZEGRANA", "Lose · 2nd", LOSE_RED)
	_eq(_hud.card, "PRZEGRANA · 2. MIEJSCE", "the lose card's title")
	_ok(_hud.body.begins_with("Pani Halina pierwszy na mecie: "), "the lose card names who got there first (%s)" % _hud.body)
	_ok(_hud.body.contains("Zabrakło ci "), "the lose card says how far short")
	_ok(HALINA_WIN.any(func(l: String) -> bool: return _hud.body.contains("„%s”" % l)), "the lose card quotes Halina's gloat")
	_ok(_hud.body_en.begins_with("Pani Halina got to "), "the lose card's English (%s)" % _hud.body_en)
	_ok(_hud.body_en.contains(" m short"), "the lose card's English says how far short")
	_ok(HALINA_WIN.has(_bub.said.back()), "Halina gloats in a bubble")
	_eq(_wallet.payments.size(), 0, "no stake is paid for a loss")
	_eq(_wallet.money, 0, "the wallet is empty")
	_ok(_wallet.ladder.is_empty(), "no rung is beaten")
	_eq(_rv.ladder.lost_streak(0), 1, "the loss counts toward the easier rematch")
	_ok(_wallet.saves > 0, "the loss was saved")
	_eq(_hud.arts, 1, "the lose card has the picture of both ways")
	_eq(_hud.status, "", "the status line is down")
	_ok(not _rv._beacon.visible, "the beacon is down")
	_ok(not _rv.racing() and not _rv.has_target(), "no longer racing")
	_ok(_rv.busy() and _dir.current() == _rv, "the lose card still holds the kit")
	_eq(_rv.first_result, "", "an ordinary race says nothing about the first race")
	_run_frames(600)
	_eq(int(_rv.state), 5, "the lose card is still up ten seconds on")
	_ok(_hud.card_is(_rv), "the lose card is still the race's ten seconds on")
	_hud.press(0)
	_ended("OK on the lose card")
	_ok(_rv.raced(), "a lost race counts as raced")
	_eq(_wallet.payments.size(), 0, "still nothing paid")
	_eq(_hud.cards, ["PRZEGRANA · 2. MIEJSCE"], "one card in the whole race")


# --- D. given up with the cross ----------------------------------------------------------------------

## The ✕ on the status line, as hud.gd's tap sends it.
func _cross() -> void:
	_hud.abort_pressed.emit()


## The lose card of a race given up.
func _gave_up_card(what: String) -> void:
	_card_is_result("PRZEGRANA", "Lose · 2nd", LOSE_RED)
	_ok(_hud.body.contains("Wyścig poddany."), "%s: the card says the race was given up (%s)" % [what, _hud.body])
	_ok(_hud.body_en.begins_with("You gave up."), "%s: the English says so (%s)" % [what, _hud.body_en])
	_eq(_wallet.payments.size(), 0, "%s: nothing is paid" % what)
	_eq(_rv.ladder.lost_streak(Ladder.rung_of(String(Rivals.RIVALS[_rv.rival]["name"]))), 0, "%s: a given-up race is not a loss on the ladder" % what)
	_eq(_hud.status, "", "%s: the status line is down" % what)
	_ok(not _rv._beacon.visible, "%s: the beacon is down" % what)
	_ok(_rv._ghost == null, "%s: the ghost is gone" % what)
	_ok(not _rv.has_target() and not _rv.racing(), "%s: no longer racing" % what)
	_eq(_rv.phase, Activity.Phase.RUN, "%s: the phase is RUN until OK" % what)
	_eq(_hud.toasts.size(), 0, "%s: no toast" % what)


func _d_give_up() -> void:
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	_tail(SLOIK)
	_cross()
	_eq(int(_rv.state), 0, "the cross when nothing is on does nothing")
	_eq(_rv.phase, Activity.Phase.IDLE, "the cross when nothing is on: IDLE")
	_ok(_reach(1, 1500), "a prompt")
	_cross()
	_eq(int(_rv.state), 1, "the cross in a prompt does nothing")
	_ok(_hud.challenge != "", "the cross in a prompt leaves the challenge on the HUD")
	_run_frames(10)
	_rv.flash()
	_run_frames(30)
	_eq(int(_rv.state), 2, "in the challenge")
	_cross()
	_eq(int(_rv.state), 2, "the cross in the challenge does nothing")
	_eq(_rv.phase, Activity.Phase.RUN, "the cross in the challenge: still RUN")
	_ok(not _hud.card_showing(), "the cross in the challenge: no card")
	_ok(_calls.paused, "the cross in the challenge: the rescue calls still wait")
	_ok(_hud.banner != "", "the cross in the challenge: the banner stays")
	_ok(_reach(3, 400), "the countdown")
	_run_frames(50)
	_cross()
	_eq(int(_rv.state), 5, "the cross in the countdown gives the race up")
	_gave_up_card("countdown")
	_cross()
	_cross()
	_eq(int(_rv.state), 5, "the cross under the result card does nothing")
	_ok(_hud.card_is(_rv), "the cross under the result card leaves the card")
	_eq(_hud.shown, 1, "the cross under the result card shows nothing")
	_hud.press(0)
	_ended("OK after the countdown's cross")
	_ok(_rv.raced(), "a race given up counts as raced")
	# A second race, given up in the race itself.
	_rv.put_ahead(BARTEK)
	_rv.tail = BARTEK
	_ok(_reach(1, 1500), "a second prompt")
	_eq(_rv.rival, BARTEK, "the second is Bartek's")
	_run_frames(10)
	_rv.flash()
	_ok(_reach(4, 600), "the second race")
	_run_frames(600)
	_eq(int(_rv.state), 4, "ten seconds into the race")
	_cross()
	_eq(int(_rv.state), 5, "the cross in the race gives it up")
	_gave_up_card("race")
	_hud.press(0)
	_ended("OK after the race's cross")
	_eq(_hud.cards.size(), 2, "two cards in the two races")
	_run_frames(1)
	_eq(_seq.back(), 0, "back to CRUISE")


# --- E. what holds a challenge back ------------------------------------------------------------------

## A world with `apply` on from the start and Słoik tailed: no prompt for four seconds; `release` taken, the
## prompt comes. `extra`: more facts while it holds.
func _hold(what: String, apply: Callable, release: Callable, extra := Callable()) -> void:
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	apply.call()
	_tail(SLOIK)
	var seen := false
	for i in 240:
		_frame()
		if int(_rv.state) != 0:
			seen = true
	_ok(not seen, "%s: no prompt while it holds" % what)
	_eq(_hud.challenge, "", "%s: no challenge on the HUD while it holds" % what)
	_eq(_rv.phase, Activity.Phase.IDLE, "%s: the race stays idle" % what)
	if extra.is_valid():
		extra.call()
	release.call()
	_ok(_until(func() -> bool: return int(_rv.state) == 1, 900, "%s: the prompt after it is released" % what) >= 0,
			"%s: the prompt comes back when it is released" % what)
	_ok(_hud.challenge.begins_with("WYŚCIG · SŁOIK"), "%s: Słoik's challenge is on the HUD" % what)


func _e_holds() -> void:
	_hold("another activity on", func() -> void: _probe.phase = Activity.Phase.RUN,
			func() -> void: _probe.phase = Activity.Phase.IDLE,
			func() -> void:
				_ok(not _rv.free_now.call(), "another activity on: free_now is false")
				_ok(not _rv.request_up.call(), "another activity on: no request card is up"))
	_hold("a side job on", func() -> void:
				_probe.is_job = true
				_probe.phase = Activity.Phase.RUN,
			func() -> void: _probe.phase = Activity.Phase.IDLE)
	_hold("another activity's offer card", func() -> void: _probe.phase = Activity.Phase.OFFER,
			func() -> void: _probe.phase = Activity.Phase.IDLE)
	_hold("a request card that leaves the player free", func() -> void:
				_probe.offer_busy = false
				_probe.phase = Activity.Phase.OFFER,
			func() -> void: _probe.phase = Activity.Phase.IDLE,
			func() -> void:
				_ok(not _probe.busy() and not _dir.busy(), "a request card: nothing is on")
				_ok(_rv.free_now.call(), "a request card: free_now is true")
				_ok(_rv.request_up.call(), "a request card: request_up is true"))
	_hold("flying", func() -> void: _flying = true, func() -> void: _flying = false)
	_hold("a rescue call with a target", func() -> void: _calls.target = true, func() -> void: _calls.target = false)
	_hold("a card up", func() -> void: _hud.show_card("INNA KARTA", "tekst", PackedStringArray(["OK"]), Color.WHITE),
			func() -> void: _hud.hide_card())
	_hold("the full map open", func() -> void: _hud.map_open = true, func() -> void: _hud.map_open = false)
	# A prompt that is up is withdrawn when another activity starts.
	_probe.phase = Activity.Phase.RUN
	_run_frames(150)
	_eq(int(_rv.state), 0, "a prompt is withdrawn when another activity starts")
	_eq(_hud.challenge, "", "the withdrawn prompt is off the HUD")
	_probe.phase = Activity.Phase.IDLE
	# Spacer's quiet: the prompt shows, the rival says nothing, the flash still starts the race.
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	_rv.quiet = true
	_tail(SLOIK)
	_ok(_reach(1, 1500), "quiet: the prompt shows")
	_ok(_hud.challenge.begins_with("WYŚCIG · SŁOIK"), "quiet: the challenge is on the HUD")
	_eq(_bub.said.size(), 0, "quiet: the rival says nothing")
	_run_frames(10)
	_rv.flash()
	_eq(int(_rv.state), 2, "quiet: the flash still starts the race")
	_ok(_said_one_of(SLOIK_CHALLENGE, _rv._finish["pl"]), "quiet: the challenge line is still said")


# --- F. Halina's roll-up -----------------------------------------------------------------------------

const FIRST_CALL := "Dziecko drogie! Babcia mruga. Do Palmy, kto pierwszy?"
const FIRST_NUDGE := "Mrugnij, dziecko. Babcia nie ma całego dnia."
const FIRST_GONE := "Ech, ta młodzież. To innym razem."
const FIRST_GO := "No jedź, dziecko! Gaz i za różową strzałką!"


func _f_first() -> void:
	# Nothing on: she rolls up, flashes, the flash back starts the guided race.
	_new_world(false)
	_frame()
	_ok(_rv.call_first(), "call_first() with nothing on")
	_ok(_rv.first_waiting(), "she is rolling up")
	_ok(_rv.calling(), "rolling up counts as calling()")
	_eq(_rv.rival, HALINA, "it is Halina")
	_eq(int(_rv.state), 0, "rolling up: still CRUISE")
	_eq(_rv.phase, Activity.Phase.IDLE, "rolling up: the phase is IDLE")
	_ok(not _rv.busy(), "rolling up: not busy")
	_eq(_hud.challenge, "", "rolling up: nothing on the HUD yet")
	_ok(not _rv.call_first(), "a second call_first() while she rolls up is refused")
	_ok(_reach(1, 1500), "Halina flashes: the PROMPT")
	_ok(_rv.first_waiting(), "the prompt waits for the flash back")
	_ok(_rv.calling(), "the prompt is calling()")
	_eq(_rv.phase, Activity.Phase.IDLE, "the prompt: IDLE")
	_ok(not _rv.busy() and not _dir.busy(), "the prompt: nothing is on")
	_ok(_hud.challenge.begins_with("WYŚCIG · PANI HALINA"), "the HUD shows her challenge (%s)" % _hud.challenge)
	_eq(_hud.challenge_sub, "Mruga do ciebie! Dotknij albo L", "her challenge's hint")
	_eq(_hud.challenge_sub_en, "Flashing you! Tap or L to race", "her challenge's English hint")
	_ok(_bub.said.has(FIRST_CALL), "she says her call line")
	_run_frames(10)
	_rv.flash()
	_eq(_car.flashes, 1, "the flash back flashes the car")
	_eq(int(_rv.state), 2, "the flash back starts the race")
	_ok(_rv.first_race, "it is the guided first race")
	_ok(not _rv.first_waiting() and not _rv.calling(), "she is no longer rolling up")
	_ok(_reach(3, 400), "the countdown")
	_ok(_reach(4, 400), "the race")
	_ok(not _hud.finger, "no ghost finger at the start")
	_run_frames(100)
	_ok(not _hud.finger, "no ghost finger in the first two seconds")
	_run_frames(60)
	_ok(_hud.finger, "a car that stands still gets the ghost finger")
	_ok(_hud.banners.has("GAZ! JEDŹ ZA STRZAŁKĄ"), "and the GAZ banner")
	_ok(_bub.said.has(FIRST_GO), "and Halina's go line")
	_ok(_rv._drivers[HALINA].held, "Halina waits at the line while the player stands still")
	_vel = Vector3(6.0, 0.0, 0.0)
	_run_frames(5)
	_ok(not _hud.finger, "the car moving takes the finger away")
	_ok(not _rv._drivers[HALINA].held, "the car moving lets Halina go")
	_cross()
	_eq(int(_rv.state), 5, "the cross gives the first race up")
	_hud.press(0)
	_ended("OK after the first race")
	_ok(not _hud.finger, "no finger after the race")
	# Declined: nobody flashes back.
	_new_world(false)
	_frame()
	_rv.call_first()
	_ok(_reach(1, 1500), "declined: the prompt")
	_run_frames(450)
	_ok(not _bub.said.has(FIRST_NUDGE), "declined: no nudge before 8 s")
	_run_frames(110)
	_ok(_bub.said.has(FIRST_NUDGE), "declined: she nudges after a few seconds")
	_eq(int(_rv.state), 1, "declined: still waiting")
	_run_frames(700)
	_eq(int(_rv.state), 0, "declined: the wait runs out and the prompt goes")
	_ok(not _rv.first_waiting() and not _rv.calling(), "declined: she is gone")
	_eq(_rv.first_result, "declined", "declined: first_result")
	_eq(_hud.challenge, "", "declined: the HUD's challenge is down")
	_ok(_bub.said.has(FIRST_GONE), "declined: her parting line")
	_ok(not _rv.first_race, "declined: no first race")
	_eq(_car.flashes, 0, "declined: the car never flashed")
	# Another activity already on when she is called: she gives up on the next frame.
	_new_world(false)
	_probe.phase = Activity.Phase.RUN
	_frame()
	_rv.call_first()
	_run_frames(2)
	_ok(not _rv.first_waiting(), "a probe on at the call: she does not wait")
	_eq(_rv.first_result, "declined", "a probe on at the call: declined")
	_eq(int(_rv.state), 0, "a probe on at the call: CRUISE")
	_eq(_hud.challenge, "", "a probe on at the call: no challenge")
	_probe.phase = Activity.Phase.IDLE
	_ok(_rv.call_first(), "the probe off: she can be called again")
	_ok(_reach(1, 1500), "the probe off: she rolls up and flashes")
	_ok(_rv.first_waiting(), "the probe off: waiting for the flash back")
	# Another activity starts while she rolls up, and again once she has flashed.
	_new_world(false)
	_frame()
	_rv.call_first()
	_run_frames(30)
	_ok(_rv.first_waiting(), "rolling up")
	_probe.phase = Activity.Phase.RUN
	_run_frames(2)
	_ok(not _rv.first_waiting(), "a probe starts while she rolls up: she gives up")
	_eq(_rv.first_result, "declined", "a probe starts while she rolls up: declined")
	_ok(_rv._cooldown[HALINA] > 24.0, "giving up puts a 25 s cool-down on her (%.1f)" % _rv._cooldown[HALINA])
	_eq(int(_rv.state), 0, "a probe starts while she rolls up: CRUISE")
	_new_world(false)
	_frame()
	_rv.call_first()
	_ok(_reach(1, 1500), "the prompt, for a probe to come after")
	_probe.phase = Activity.Phase.RUN
	_run_frames(2)
	_eq(int(_rv.state), 0, "a probe starts under her prompt: the prompt goes")
	_ok(not _rv.first_waiting(), "a probe starts under her prompt: she gives up")
	_eq(_rv.first_result, "declined", "a probe starts under her prompt: declined")
	_eq(_hud.challenge, "", "a probe starts under her prompt: the HUD's challenge is down")
	_ok(_bub.said.has(FIRST_GONE), "she says her parting line after flashing")
	_ok(not _rv.busy(), "she gave up: nothing is on")


# --- G. a locked rival ---------------------------------------------------------------------------------

func _g_locked() -> void:
	_new_world(true, WIN_PACE)
	_tail(MIKE)
	_ok(_reach(1, 1500), "a prompt behind Mike")
	_eq(_rv.rival, MIKE, "it is Mike's")
	_ok(_hud.challenge.begins_with("MORDOR MIKE · ZAMKNIĘTE"), "the prompt says he is locked (%s)" % _hud.challenge)
	_eq(_hud.challenge_accent, LOCKED_GREY, "the locked prompt is grey")
	_eq(_hud.challenge_sub, "NAJPIERW ZBYSZEK", "it says what is missing")
	_eq(_hud.challenge_sub_en, "beat Taksiarz Zbyszek first", "and in English")
	_ok(not _bub.said.has(MIKE_APPROACH), "a locked rival does not call out his approach line")
	_run_frames(10)
	_rv.flash()
	_eq(_car.flashes, 1, "the flash flashed the lights")
	_eq(int(_rv.state), 0, "a flash at a locked rival starts nothing")
	_eq(_rv.phase, Activity.Phase.IDLE, "the refusal: IDLE")
	_ok(not _rv.busy() and not _dir.busy(), "the refusal: nothing is on")
	_eq(_hud.challenge, "", "the refusal takes the prompt down")
	_eq(_bub.said.back() if _bub.said.size() > 0 else "", MIKE_REFUSE, "Mike refuses in his own words")
	_eq(_wallet.payments.size(), 0, "nothing is paid")
	_eq(_calls.closed, 0, "the rescue line was left alone")
	_ok(not _calls.paused, "the rescue calls are free")
	_eq(_hud.shown, 0, "no card")
	_eq(_rv._races, 0, "no race was begun")
	_ok(not _rv.has_target() and not _rv.racing(), "no target, not racing")
	var again := false
	for i in 360:
		_frame()
		if int(_rv.state) != 0:
			again = true
	_ok(not again, "he does not offer again for six seconds")
	_ok(_until(func() -> bool: return int(_rv.state) == 1, 900, "the next locked prompt") >= 0, "the locked prompt comes back")


# --- H. Trzy mosty ---------------------------------------------------------------------------------------

func _start_xz() -> Vector2:
	return Vector2(_rv.final_route.start_pos.x, _rv.final_route.start_pos.z)


func _h_final() -> void:
	_new_world(false, WIN_PACE, true)
	_rv.preset_ladder(6)
	_ok(_rv.final_route != null, "the map has a route for Trzy mosty")
	_ok(_rv.final_open() and _rv.night(), "the final is open and it is night")
	_probe.phase = Activity.Phase.RUN
	_run_frames(60)
	_eq(_rv.start_marker(), Vector2.INF, "another activity on: no start marker")
	_ok(not _rv._beacon.visible, "another activity on: no beacon at the start")
	_eq(_hud.finals.size(), 0, "another activity on: nothing on the minimap")
	_probe.phase = Activity.Phase.IDLE
	_run_frames(30)
	_eq(_rv.start_marker(), _start_xz(), "nothing on: the start marker is set")
	_ok(_rv._beacon.visible and _rv._beacon.global_position.distance_to(_rv.final_route.start_pos) < 3.0, "the beacon stands at the start")
	_eq(_hud.finals.back() if _hud.finals.size() > 0 else Vector2.INF, _start_xz(), "the minimap's diamond is at the start")
	_ok(_rv._seba_waiting, "Seba waits at the start")
	_eq(_rv._beacon._colour, GOLD, "the start marker's flag is gold")
	_eq(_rv._beacon._ring_radius, 8.0, "the start marker's ring is 8 m")
	_eq(_rv._beacon.global_position.y, _rv.final_route.start_pos.y, "the marker stands on the start")
	_flying = true
	_run_frames(30)
	_eq(_rv.start_marker(), Vector2.INF, "flying: no start marker")
	_flying = false
	_run_frames(30)
	_eq(_rv.start_marker(), _start_xz(), "landed: the marker is back")
	# After what held it back goes, the marker is back at the next look (every 0.2 s), whenever that goes.
	for k in 13:
		_probe.phase = Activity.Phase.RUN
		_run_frames(30 + k)
		_probe.phase = Activity.Phase.IDLE
		_run_frames(13)
		_eq(_rv.start_marker(), _start_xz(), "the marker is back within 13 frames of the probe going (after %d frames on)" % (30 + k))
	_probe.phase = Activity.Phase.RUN
	_run_frames(30)
	_eq(_rv.start_marker(), Vector2.INF, "another activity starts: the marker goes")
	_ok(not _rv._beacon.visible, "another activity starts: the beacon goes")
	_eq(_hud.finals.back(), Vector2.INF, "another activity starts: the diamond goes")
	_probe.phase = Activity.Phase.IDLE
	_run_frames(30)
	_eq(_rv.start_marker(), _start_xz(), "the marker is back")
	_tod.mode = 0
	_run_frames(30)
	_eq(_rv.start_marker(), Vector2.INF, "day: no marker")
	_ok(not _rv._seba_waiting, "day: Seba leaves")
	_tod.mode = NIGHT
	_run_frames(30)
	_eq(_rv.start_marker(), _start_xz(), "night again: the marker is back")
	_rv.flying = false
	# Into the marker: the final starts.
	_car.global_position = _rv.final_route.start_pos
	_car.rotation.y = _rv.final_route.start_yaw
	_run_frames(30)
	_eq(int(_rv.state), 2, "driving into the marker starts the final")
	_ok(_rv.final_on and _rv.rival == SEBA, "the final is on against Seba")
	_eq(_rv.phase, Activity.Phase.RUN, "the final: RUN")
	_ok(_rv.busy() and _dir.current() == _rv and _dir.busy_tag() == "rival race", "the final: the director names rivals")
	_eq(_rv.start_marker(), Vector2.INF, "the final: the marker is gone")
	_eq(_hud.banner, "TRZY MOSTY", "the final: the banner")
	_ok(_bub.said.has(SEBA_CHALLENGE), "Seba challenges")
	_ok(_calls.paused and _calls.closed == 1, "the final: the rescue calls wait")
	_ok(not _probe.free_now.call(), "the final: another activity may not start")
	_eq(_dir.grounded(), GROUNDED, "the final: the helicopter is refused")
	_cross()
	_eq(int(_rv.state), 2, "the cross in the final's challenge does nothing")
	_ok(_reach(3, 400), "the final's countdown")
	_run_frames(2)
	var cps: Array = _rv.final_route.checkpoints
	_ok(_hud.status != "" and _hud.status_title == "MOST 1/3 · TRZY MOSTY", "the final's status line names the first bridge (%s)" % _hud.status_title)
	_eq(_hud.tint, GOLD, "the final's colour is gold")
	_eq(_hud.status, "Uwaga…", "the countdown's hint")
	_ok(_rv.has_target() and _dir.targeted() == _rv, "the final's target is the first bridge")
	_eq(_rv.target_position(), cps[0]["pos"], "the target is the first checkpoint")
	_ok(_rv._beacon.visible and Vector2(_rv._beacon.global_position.x - cps[0]["pos"].x, _rv._beacon.global_position.z - cps[0]["pos"].z).length() < 3.0,
			"the final's flag stands at the first bridge, not at the stadium")
	_eq(_rv._beacon._ring_radius, 14.0, "a bridge's ring is 14 m")
	_eq(_rv._beacon._colour, GOLD, "the final's flag is gold")
	_ok(_hud.routes_set > 0, "the final's way is on the minimap in the countdown")
	_eq(_rv.target_colour(), GOLD, "the target is gold")
	_ok(_rv.main_target(false), "the final is the main line's")
	_eq(_rv.stop_spot(), INF3, "no stop ring")
	_ok(_reach(4, 400), "the final's race")
	_run_frames(30)
	_ok(_hud.status_title == "MOST 1/3 · TRZY MOSTY" and (_hud.badge == "1ST" or _hud.badge == "2ND"), "the race's status line has the place (%s)" % _hud.badge)
	# The three bridges and the finish, by putting the car on each (Seba cannot be there in the time).
	for k in cps.size():
		var routes0 := _hud.routes_set
		_car.global_position = cps[k]["pos"]
		_run_frames(20)
		_ok(_hud.routes_set > routes0, "a new way is drawn on the minimap after bridge %d" % (k + 1))
		_ok(_hud.toasts.has("MOST %d/3 · %s" % [k + 1, cps[k]["pl"]]), "bridge %d is counted and toasted" % (k + 1))
		_ok(_rv.target_position() == (cps[k + 1]["pos"] if k + 1 < cps.size() else _rv.final_route.finish["pos"]), "the target moves on after bridge %d" % (k + 1))
		_eq(int(_rv.state), 4, "still racing after bridge %d" % (k + 1))
	_eq(_rv.target_colour(), GOLD, "the finish is gold")
	_car.global_position = _rv.final_route.finish["pos"]
	_run_frames(20)
	_eq(int(_rv.state), 5, "the finish wins the final")
	_card_is_result("TRZY MOSTY · WYGRANA", "Three bridges · Win", GOLD)
	_ok(_hud.body.begins_with("KORONA NOCNEJ WARSZAWY TWOJA!"), "the first win is crowned (%s)" % _hud.body)
	_ok(_hud.body.contains("+500 zł"), "the final's stake is on the card")
	_ok(_hud.body_en.begins_with("The crown of Warsaw by night is yours!"), "the English crown")
	_eq(_wallet.payments, [[500, 250, "race"]], "the final pays 500 zł and 250 respect once")
	_ok(_rv.ladder.final_won(), "the final is on the ladder as won")
	_ok(not _rv.final_on, "final_on is cleared")
	_ok(_bub.said.has(SEBA_LOSE), "Seba says his respect")
	_eq(_hud.status, "", "the status line is down")
	_ok(not _rv._beacon.visible, "the beacon is down")
	_ok(not _rv.has_target() and _dir.targeted() == null, "no target")
	_eq(_hud.arts, 1, "the card has the picture")
	_eq(_rv._beacon._colour, PINK, "after the final the flag is the race's pink again")
	_ok(_rv._cooldown[SEBA] > 24.0, "Seba has a 25 s cool-down (%.1f)" % _rv._cooldown[SEBA])
	_hud.press(0)
	_ended("OK after the final")
	_ok(_rv.raced(), "the final counts as raced")
	_eq(_wallet.payments.size(), 1, "one payment in all")
	# Given up.
	_new_world(true, WIN_PACE, true)
	_rv.preset_ladder(6)
	_hud.show_card("INNA KARTA", "tekst", PackedStringArray(["OK"]), Color.WHITE)
	_ok(_rv.start_final_now(0), "--trzy-mosty starts the final at once")
	_ok(not _hud.card_showing(), "the final takes a card that was up down")
	_run_frames(5)
	_eq(int(_rv.state), 2, "the final is in its challenge")
	_ok(_rv.final_on and _dir.current() == _rv, "the final is the director's current")
	_ok(_reach(3, 400), "the countdown")
	_run_frames(50)
	_ok(_hud.status != "" and _hud.status_title.ends_with("TRZY MOSTY"), "the status line is up")
	_cross()
	_eq(int(_rv.state), 5, "the cross gives the final up")
	_card_is_result("TRZY MOSTY · PRZEGRANA", "Three bridges · Lose", LOSE_RED)
	_ok(_hud.body.contains("Finał poddany."), "the card says the final was given up (%s)" % _hud.body)
	_ok(_hud.body_en.contains("You gave up the final."), "and in English (%s)" % _hud.body_en)
	_ok(_hud.body.contains("Rewanż: Rondo Daszyńskiego, w nocy."), "the card says where the rematch is")
	_eq(_wallet.payments.size(), 0, "nothing is paid")
	_eq(_rv.ladder.lost_streak(Ladder.FINAL), 0, "a given-up final is not a loss on the ladder")
	_ok(not _rv.final_on, "final_on is cleared")
	_ok(_bub.said.has(SEBA_WIN), "Seba gloats")
	_eq(_hud.status, "", "the status line is down")
	_ok(not _rv._beacon.visible and _rv._ghost == null, "the beacon and the ghost are down")
	_ok(not _rv.has_target(), "no target")
	_run_frames(600)
	_eq(int(_rv.state), 5, "the final's lose card is still up ten seconds on")
	_ok(_hud.card_is(_rv), "the final's lose card is still the race's ten seconds on")
	_cross()
	_eq(int(_rv.state), 5, "the cross under the card does nothing")
	_hud.press(0)
	_ended("OK after the final given up")


# --- shared by the gap parts -----------------------------------------------------------------------

## The car out of reach of every rival: the autopilot off, standing, for `n` frames.
func _stand(n: int) -> void:
	_auto = false
	_vel = Vector3.ZERO
	_run_frames(n)


## The car put `back` m behind rival `i`'s driver and `side` m to its side, moving at `speed`, every frame for `n`
## frames (the autopilot's own place, moved about).
func _keep_near(i: int, back: float, side: float, speed: float, n: int) -> void:
	_auto = false
	_vel = Vector3(speed, 0.0, 0.0)
	for k in n:
		var d = _rv._drivers[i]
		var fwd := Vector3(-sin(d.yaw), 0.0, -cos(d.yaw))
		_rv._follow(d.pos - fwd * back + Vector3.UP.cross(fwd) * side, d.yaw, speed)
		_frame()


func _xz(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## No lamp of any rival is lit.
func _lamps_out() -> bool:
	for lamps: Node3D in _rv._signals:
		for n in ["brake", "left", "right", "flash"]:
			if lamps.get_node(n).visible:
				return false
	return true


# --- I. the kit's fields and what setup connects ---------------------------------------------------------

func _i_setup() -> void:
	_new_world(true, WIN_PACE)
	_eq(_rv.colour, PINK, "the race's colour is pink")
	_eq(_rv.dark, Color("#2b2c2f"), "the flag's dark is the race's")
	_ok(_rv._beacon.waving, "the flag waves")
	_eq(_rv._beacon.pattern, Beacon.Pattern.CHEQUER, "the flag is a chequered finish line")
	_eq(_rv._beacon._colour, PINK, "the flag is pink")
	_rv.preset_ladder(6)
	# A bump is heard: the rival complains.
	_traffic.bumped_driver.emit(_rv._drivers[HALINA])
	_eq(_bub.said, ["Ej! Uważaj na lakier!"], "a bumped rival complains")
	# The HUD's FLASH LIGHTS button.
	_tail(HALINA)
	_ok(_reach(1, 1500), "a prompt")
	_hud.challenge_pressed.emit()
	_eq(int(_rv.state), 2, "the HUD's FLASH LIGHTS button starts the race")
	_eq(_car.flashes, 1, "the button flashes the lights")
	# The dice are seeded with 7, so a world plays its races the same way each time. The seed is
	# read rather than a first draw: how many draws the spawns take depends on the lane graph, which
	# main moves.
	_eq(int(_rv._rng.seed), 7, "the dice are seeded with 7")
	_ok(_said_one_of(HALINA_CHALLENGE, _rv._finish["pl"]), "the challenge line is one of Halina's (%s)" % _bub.said.back())
	_ok(_reach(4, 800), "the race")
	var dice1: int = _rv._racer.dice
	_hud.abort_pressed.emit()
	_hud.press(0)
	_rv.put_ahead(SLOIK)
	_rv.tail = SLOIK
	_auto = true
	_ok(_reach(1, 1500), "a second prompt")
	_rv.flash()
	_ok(_reach(4, 800), "a second race")
	_ok(_rv._racer.dice != dice1, "the second race has other dice than the first (%d, %d)" % [dice1, _rv._racer.dice])
	# The ladder's wallet is heard: the pay that opens the next rung says so.
	_new_world(false)
	_wallet.ladder[Ladder.id_of(0)] = 1
	_wallet.pay(0, 100, "test")
	_ok(_hud.toasts.has("Nowy rywal: Słoik z Radomia"), "a pay that opens a rung toasts the new rival (%s)" % str(_hud.toasts))


# --- J. the start and the stages -------------------------------------------------------------------------

func _j_stages() -> void:
	_race_on(HALINA, 6)
	_eq(_rv._beacon._colour, PINK, "the race's flag is pink")
	_eq(_rv._beacon._ring_radius, RaceSession.FINISH_RADIUS - 4.0, "the finish's flag is 12 m")
	_ok(_rv._ghost != null and not _rv._ghost.held, "the ghost is let go at GO")
	_ok(not _rv._drivers[HALINA].held, "the rival is let go at GO")
	_ok(_rv._sig_on, "in the race the rival's lamps may be lit")
	_ok(_hud.routes_set > 0, "the minimap's way is drawn")
	var cols: Array = []
	for b: Array in _hud.banner_cols:
		if cols.is_empty() or cols[cols.size() - 1] != b:
			cols.append(b)
	for t in ["3", "2", "1"]:
		_ok(cols.any(func(b: Array) -> bool: return b[0] == t and b[1] == Color.WHITE), "the countdown's %s is white" % t)
	_ok(cols.any(func(b: Array) -> bool: return b[0] == "START!" and b[1] == WIN_GREEN), "START! is green")
	var clock0: String = _hud.count
	_run_frames(60)
	_ok(_hud.count != clock0, "the race's clock runs (%s, %s)" % [clock0, _hud.count])
	# The player's metres left are refreshed five times a second, the way redrawn as the car moves.
	var routes0 := _hud.routes_set
	_auto = false
	_vel = Vector3(10.0, 0.0, 0.0)
	var changes := 0
	var last: float = _rv._player_left
	for i in 60:
		_frame()
		if _rv._player_left != last:
			changes += 1
			last = _rv._player_left
	_ok(changes >= 4, "the metres left are refreshed about five times a second (%d changes in a second)" % changes)
	_ok(_hud.routes_set > routes0, "the minimap's way is redrawn as the car moves")
	# The place: first when nearer the finish than the rival, second when farther; the hint gives the gap.
	var fin: Vector3 = _rv._finish["pos"]
	_vel = Vector3.ZERO
	_car.global_position = fin + Vector3(50.0, 0.0, 0.0)
	_run_frames(30)
	_eq(int(_rv.state), 4, "50 m from the finish is not home")
	_eq(_hud.badge, "1ST", "nearer the finish than the rival: first")
	_ok(_hud.status.contains("Pani Halina") and _hud.status.contains(" za tobą"), "first: the hint says how far behind she is (%s)" % _hud.status)
	_car.global_position = fin + Vector3(6000.0, 0.0, 0.0)
	_run_frames(30)
	_eq(_hud.badge, "2ND", "farther than the rival: second")
	_ok(_hud.status.contains("Pani Halina") and _hud.status.contains(" przed tobą"), "second: the hint says she is ahead (%s)" % _hud.status)
	# In the air the finish does not count; landed, it does.
	_car.global_position = fin
	_flying = true
	_run_frames(20)
	_eq(int(_rv.state), 4, "the car on the finish in the air does not win")
	_flying = false
	_run_frames(20)
	_eq(int(_rv.state), 5, "landed on the finish, the race is won")

	# The challenge and the countdown, stage by stage.
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	_tail(HALINA)
	_reach(1, 1500)
	_hud.show_card("INNA KARTA", "tekst", PackedStringArray(["OK"]), Color.WHITE)
	_rv.escape_bonus = true
	_rv.flash()
	_ok(not _hud.card_showing(), "the race takes a card that was up down")
	_ok(not _rv.escape_bonus, "an old escape is forgotten when a race starts")
	_ok(_rv._drivers[HALINA].held, "the rival is held in the challenge")
	_eq(_rv._beacon._colour, PINK, "the race's flag is pink from the challenge")
	_reach(3, 400)
	_run_frames(10)
	_ok(not _rv._sig_on and _lamps_out(), "no lamp is lit in the countdown")
	_eq(_hud.badge, "", "no place in the countdown")
	_eq(_rv._beacon._ring_radius, RaceSession.FINISH_RADIUS - 4.0, "the finish's flag is 12 m in the countdown")
	_ok(_rv._ghost != null and _rv._ghost.held, "the ghost waits for GO")
	_ok(_rv._drivers[HALINA].held, "the rival waits for GO")
	_car.global_position += Vector3(20.0, 0.0, 0.0)
	_ok(_rv.drive_player(), "the countdown: the ghost drives the player")
	_ok(_xz(_car.global_position, _rv._ghost.pos) < 0.5, "the countdown: the car is put where the ghost waits")
	_eq(_car.collision_mask, 0, "a driven car has no collisions")
	_run_frames(60)
	_ok(_hud.routes_set > 0, "the way is on the minimap before GO")
	# The start marker at night goes when a street race starts; the race's flag is pink.
	_new_world(true, WIN_PACE, true)
	_rv.preset_ladder(6)
	_tail(SLOIK)
	_until(func() -> bool: return _rv.start_marker() != Vector2.INF, 600, "the start marker")
	_ok(_reach(1, 1500), "a prompt at night")
	_ok(_rv.start_marker() != Vector2.INF, "the marker stays under a prompt")
	_rv.flash()
	_eq(_rv.start_marker(), Vector2.INF, "a street race takes the start marker down")
	_eq(_hud.finals.back(), Vector2.INF, "and the minimap's diamond")
	_ok(not _rv._seba_waiting, "and Seba is let go")
	_reach(3, 400)
	_run_frames(5)
	_eq(_rv._beacon._colour, PINK, "the street race's flag is pink, not the final's gold")
	_eq(_rv._beacon._ring_radius, 12.0, "and 12 m")
	_ok(_xz(_rv._beacon.global_position, _rv._finish["pos"]) < 3.0, "and at the finish")
	# The day under a prompt takes the marker down.
	_new_world(true, WIN_PACE, true)
	_rv.preset_ladder(6)
	_tail(SLOIK)
	_until(func() -> bool: return _rv.start_marker() != Vector2.INF, 600, "the start marker")
	_ok(_reach(1, 1500), "a prompt at night, again")
	_tod.mode = 0
	_run_frames(40)
	_eq(int(_rv.state), 1, "the prompt is still up")
	_eq(_rv.start_marker(), Vector2.INF, "the day under a prompt takes the start marker down")


# --- K. the prompt -----------------------------------------------------------------------------------------

func _k_prompt() -> void:
	# Sight: out of reach 1.0 s the prompt stays, back in reach the count starts again, 1.2 s and it goes.
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	_tail(HALINA)
	_ok(_reach(1, 1500), "a prompt")
	_stand(60)
	_eq(int(_rv.state), 1, "out of reach for 1.0 s the prompt is still up")
	_auto = true
	_run_frames(5)
	_stand(60)
	_eq(int(_rv.state), 1, "out of reach again for 1.0 s after being in reach the prompt is still up")
	_run_frames(40)
	_eq(int(_rv.state), 0, "out of reach for 1.4 s the prompt goes")
	_eq(_hud.challenge, "", "the prompt is off the HUD")
	# The approach line comes only every 40 s.
	_stand(840)
	_auto = true
	_ok(_reach(1, 600), "a second prompt behind the same rival")
	_eq(_bub.said.count(HALINA_APPROACH), 1, "the approach line is not said again 15 s later")
	# In the air the prompt goes.
	_flying = true
	_run_frames(100)
	_eq(int(_rv.state), 0, "a player who takes off loses the prompt")
	_eq(_hud.challenge, "", "and the HUD's challenge")
	# Standing still behind the rival is no challenge.
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	_tail(HALINA)
	_ok(_reach(1, 1500), "a prompt, for the car to stand")
	_keep_near(HALINA, 9.0, 0.0, 0.0, 100)
	_eq(int(_rv.state), 0, "a car standing right behind the rival is no challenge")
	# From beside is none either.
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	_tail(HALINA)
	_ok(_reach(1, 1500), "a prompt, for the car to move beside")
	_keep_near(HALINA, 5.0, 6.0, 8.0, 100)
	_eq(int(_rv.state), 0, "a car 6 m to the side of the rival's line is no challenge")
	# Control: behind in its lane and moving it is.
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	_tail(HALINA)
	_ok(_reach(1, 1500), "a prompt, for the control")
	_keep_near(HALINA, 9.0, 0.0, 8.0, 100)
	_eq(int(_rv.state), 1, "a car right behind the rival and moving keeps the prompt")
	# A prompt that ended with sight partly lost: a new prompt starts its count afresh.
	_new_world(true, WIN_PACE)
	_tail(MIKE)
	_ok(_reach(1, 1500), "a locked prompt behind Mike")
	_stand(60)
	_rv.flash()
	_eq(int(_rv.state), 0, "the flash at a locked rival is refused")
	_rv.put_ahead(HALINA)
	_rv.tail = HALINA
	_auto = true
	_ok(_reach(1, 1500), "a prompt behind Halina")
	_eq(_rv.rival, HALINA, "it is Halina's")
	_stand(60)
	_eq(int(_rv.state), 1, "the new prompt survives 1.0 s out of reach (the old count is forgotten)")


# --- L. the result -----------------------------------------------------------------------------------------

func _l_result() -> void:
	_race_on(HALINA, 6)
	_ok(_rv._sig_on, "the lamps may be lit in the race")
	_rv.escape_bonus = true
	_finish_now()
	_ok(_reach(5, 60), "won")
	_run_frames(2)
	_ok(not _rv._sig_on and _lamps_out(), "after the race every lamp is out")
	_eq(_wallet.payments, [[72, 20, "race"]], "an escape in the race pays the stake and a fifth")
	_ok(_hud.body.contains("+20 % ZA UCIECZKĘ"), "the card says so (%s)" % _hud.body)
	_ok(_hud.body_en.contains("+20 % FOR THE ESCAPE"), "and in English")
	var d = _rv._drivers[HALINA]
	_ok(not d.held, "the rival is let go after the race")
	_eq(d.speed_factor, 1.08, "the rival cruises at the town's pace again")
	_eq(d.race_top, 0.0, "the rival is out of racer mode")
	_ok(_rv._cooldown[HALINA] > 24.0, "the rival has a 25 s cool-down (%.1f)" % _rv._cooldown[HALINA])
	_hud.press(0)
	_ended("OK after the escape")


# --- M. Halina's roll-up -------------------------------------------------------------------------------------

func _m_rollup() -> void:
	_new_world(false)
	_frame()
	_rv.flying = true
	_ok(not _rv.call_first(), "nobody rolls up while the player flies")
	_ok(not _rv.first_waiting(), "and nobody is waiting")
	_rv.flying = false
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	_tail(HALINA)
	_ok(_reach(1, 1500), "a prompt")
	_ok(not _rv.call_first(), "nobody rolls up under a prompt")
	_ok(not _rv.first_waiting(), "and nobody is waiting")
	_new_world(false)
	_frame()
	_ok(_rv.call_first(), "call_first()")
	_eq(_rv._drivers[HALINA].speed_factor, 1.3, "she rolls up quickly")
	_eq(_rv._drivers[HALINA].accel_factor, 1.6, "and takes off fast")
	_run_frames(30)
	_flying = true
	_run_frames(2)
	_ok(not _rv.first_waiting(), "the player takes off: she gives up")
	_eq(_rv.first_result, "declined", "the air: declined")
	_new_world(false)
	_frame()
	_rv.call_first()
	_run_frames(30)
	_calls.target = true
	_run_frames(2)
	_ok(not _rv.first_waiting(), "a rescue starts: she gives up")
	_eq(_rv.first_result, "declined", "the rescue: declined")
	# She flashes only within 14 m and behind the car.
	_new_world(false)
	_frame()
	_rv.call_first()
	var spot: Array = _rv._spot_behind(20.0)
	_ok(not spot.is_empty(), "a place 20 m behind the car")
	_traffic.teleport(_rv._drivers[HALINA], spot[0], spot[1], spot[2])
	_run_frames(3)
	_ok(not _rv._call_up and int(_rv.state) == 0, "20 m behind the car she has not flashed")
	_new_world(false)
	_frame()
	_rv.call_first()
	spot = _rv._spot_behind(10.0)
	_traffic.teleport(_rv._drivers[HALINA], spot[0], spot[1], spot[2])
	_run_frames(3)
	_ok(_rv._call_up and int(_rv.state) == 1, "10 m behind the car she flashes")
	_new_world(false)
	_frame()
	_rv.call_first()
	_rv.put_ahead(HALINA, 8.0)
	_run_frames(3)
	_ok(not _rv._call_up and int(_rv.state) == 0, "8 m in front of the car she has not flashed")
	# Won: the guided first race's result is kept.
	_new_world(false)
	_frame()
	_rv.call_first()
	_ok(_reach(1, 1500), "the first race's prompt")
	_run_frames(10)
	_rv.flash()
	_ok(_reach(4, 800), "the first race")
	_finish_now()
	_ok(_reach(5, 60), "the first race is won")
	_eq(_rv.first_result, "won", "the guided first race's result is kept")
	_ok(not _rv.first_race, "and it is over")


# --- N. Trzy mosty's start look and the autopilot's car --------------------------------------------------------

func _n_final_drive() -> void:
	# Seba's line when the car is near the start (not in its ring): once, and again after 30 s.
	_new_world(false, WIN_PACE, true)
	_rv.preset_ladder(6)
	_run_frames(30)
	_car.global_position = _rv.final_route.start_pos + Vector3(30.0, 0.0, 0.0)
	_run_frames(1200)
	_eq(_bub.said.count(SEBA_WAIT), 1, "Seba says his wait line once in 20 s")
	_eq(int(_rv.state), 0, "outside the ring the final does not start")
	_run_frames(700)
	_eq(_bub.said.count(SEBA_WAIT), 2, "and again after 30 s")
	# The bridges before the one it starts on are counted.
	_new_world(true, WIN_PACE, true)
	_rv.preset_ladder(6)
	_ok(_rv.start_final_now(2), "the final from the second bridge")
	_eq(_rv._cp, 1, "one bridge is counted before it")
	_ok(_reach(3, 400), "the countdown")
	_run_frames(2)
	_eq(_hud.status_title, "MOST 2/3 · TRZY MOSTY", "the status line names the second bridge")
	# Seba inside the stadium's circle is not home, but at the end of his plan.
	_ok(_reach(4, 400), "the race")
	_run_frames(10)
	var last: int = _rv._race_session.legs.size() - 1
	_rv._racer.leg = last
	var at: Vector2 = _rv._race_session.at
	var hit := _graph.snap(at, 8.0, Vector2.ZERO, true)
	_ok(not hit.is_empty(), "a lane inside the finish's circle")
	if not hit.is_empty():
		_traffic.teleport(_rv._drivers[SEBA], hit[0], hit[1], hit[2])
		_run_frames(5)
		_ok(_xz(_rv._drivers[SEBA].pos, Vector3(at.x, 0.0, at.y)) < _rv._race_session.radius, "Seba is inside the finish's circle")
		_ok(not _rv._racer.home and int(_rv.state) == 4, "Seba in the circle, off the line his plan ends on, is not home")
	# The autopilot's car: the tail behind a prompt, the ghost, the collisions.
	_new_world(true, WIN_PACE)
	_rv.preset_ladder(6)
	_tail(HALINA)
	_ok(_reach(1, 1500), "a prompt")
	_ok(_rv.drive_player(), "the autopilot drives the car behind the rival under a prompt")
	var d9: float = _xz(_car.global_position, _rv._drivers[HALINA].pos)
	_ok(d9 > 8.5 and d9 < 9.5, "9 m behind the rival (%.2f)" % d9)
	_eq(_car.collision_mask, 0, "a driven car has no collisions")
	_rv.flash()
	_ok(_reach(4, 800), "the race")
	_run_frames(30)
	_traffic.remove(_rv._ghost)
	_rv._ghost = null
	_ok(_rv.drive_player(), "a race without its ghost: the director still slides the car")
