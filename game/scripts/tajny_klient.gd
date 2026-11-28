extends "res://scripts/activity.gd"
## **"Tajny klient"** (F 2026-11-26; plan doc "First 10 minutes: Tajny klient"): the opening
## mission that replaces the first-ten-minutes guide on a fresh save, behind a flag (DEV →
## "Tajny klient", or --tajny) until its 2D stand and river diorama are real.
##
## Phase 1, the playable slice in 3D and cards:
##   1. BUY. 25-35 s into the first drive Kebabulo (Mrożulo on screen since F's rename; the ids
##      stay `mrozulo`) phones: be his secret customer at KEBAB U KEMALA, the new kebab on Aleje
##      Jerozolimskie. Turned down, he rings again a minute later. Taken: the sting (the banner
##      TAJNY KLIENT, the start sound, a buzz), 50 zł on BLIP for the kebab, the arrow to the shop.
##      At the door WEJDŹ, and the 2D stand (phase 2: kebab_stand.gd's rules, kebab_stand_ui.gd's
##      view, the city's 3D off): the dish, the sauce, "Dla kogo?" (for me / for a mate with a
##      camera: the cover blown, the KEBAB DLA KAMERY badge and Kemal's VIP kebab), Kemal builds
##      it, the player pours the sauce (dry, just right or on the jacket: it shows in the grade).
##   2. TASTE. To the Palm at Rondo de Gaulle'a while it's warm; on the way DŻEMINI KEBAB's AI
##      agent offers 100 zł on COTAM to say it was bad (take it: the money and the SPRZEDAWCZYK
##      badge; show it to the camera: Kebabulo roasts DŻEMINI). Kebabulo is never bribed. At the
##      Palm the tasting is Zbyszek's livestream (phase 3: palm_tasting.gd's beats,
##      palm_tasting_ui.gd's pixel view, the city's 3D off): he bites, chews in close-up, MLASK,
##      then his verdict (F's phrases: "ale dobry", "buła taka nie za sucha", "jak z Berlina"),
##      the drumroll and the grade from the player's own run (the dish, how warm it came, the
##      bumps, the pour), an 11/10 for a perfect one, and the RECENZJA card.
##   3. PAYOFF. "Kto pierwszy pod Kemalem, ten przykleja!": a race back to the shop against his
##      Porsza on the race session (race_session.gd: one racer, Halina's gentle profile). At the
##      door SZYBA, the 2D payoff (Fable's critique 2026-11-26: kemal_window.gd's beats,
##      kemal_window_ui.gd's view, the city's 3D off): Kemal's window from the pavement, the
##      winner's hand slaps the round MLASK sticker on the glass (one tap; the high five when
##      Kebabulo won), the street queues at the door, Kemal cries, and PARAGON, the receipt (the
##      order, the grade, +120 zł, +30 respect, the badges, the leak line). After it, for good, the
##      queue at Kemal's door in the city (crowds.gd `kemal_mlask`, the save's `keep` KEEP), the
##      sticker on the 3D window, KEBAB FM's line and CO DALEJ?: the three featured quests (F 11:52:
##      the night meet, Rave na Smolnej, TESŁO) and a button to the QUESTS screen.
## Everyone gets the race, the sticker and the queue; the choices give badges (Fable's director
## pass: no bad endings).
##
## Chapter saves in the save's [intro] (STAGE_KEY: 1 taken, 2 bought, 3 done; the order's picks
## beside it): a session that ends mid-chapter is called again and resumes at its chapter. The
## HELI chip stays hidden until the payoff (F: the phone and the helicopter come after the first
## quest). Every beat reaches the stats as a `guide_beat` ("tk_*", `beat`).
##
## Words: dialogue.json group "tajny_klient" (one line per tag). Times: pacing.json "tajny".
## Add-ons: Dialogue Manager not used (a straight line of cards with two-way picks, the kit's
## cards hold it; the stand's order is the stand's own phases; the tasting has no replies, a tap
## each, so palm_tasting.gd's beats hold it), Beehave not used.

signal beat(id: String, how: String, at: float)

const Crowds := preload("res://scripts/crowds.gd")
const TrendJob := preload("res://scripts/trend_job.gd")
const StreetMeet := preload("res://scripts/street_meet.gd")
const RaceSession := preload("res://scripts/race_session.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")
const RacePlanner := preload("res://scripts/race_planner.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Messages := preload("res://scripts/messages.gd")
const Models := preload("res://scripts/models.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const KebabStand := preload("res://scripts/kebab_stand.gd")
const KebabStandUi := preload("res://scripts/kebab_stand_ui.gd")
const PalmTastingUi := preload("res://scripts/palm_tasting_ui.gd")
const KemalWindowUi := preload("res://scripts/kemal_window_ui.gd")

const SITE := Crowds.KEMAL_ID
const KEEP := "kemal_mlask"
## The save's [intro] keys (ints): the chapter reached and the order's picks.
const STAGE_KEY := "tajny"
const DISH_KEY := "tajny_dish"
const SAUCE_KEY := "tajny_sauce"
const CAM_KEY := "tajny_cam"
const BRIBE_KEY := "tajny_bribe"
const POUR_KEY := "tajny_pour"
## The pour's verdicts as the save keeps them (POUR_KEY).
const POURS := ["good", "dry", "jacket"]
enum Saved {NONE, TAKEN, BOUGHT, DONE}

const WORDS := "tajny_klient"
const COLOUR := Color("#ff7a2a")
const DARK := Color("#7a2a08")
const COTAM_COLOUR := Color("#2fd36b")
const PALM := Vector2(-213.9, 238.5)
## Where the meeting's kerb is looked for round the Palm (the roundabout's own lanes are not a
## place to park): a little way up each street, the first with free pavement.
const PALM_TRIES := [Vector2(0, -70), Vector2(70, 0), Vector2(-70, 0), Vector2(0, 70), Vector2(50, -50), Vector2(-50, 50)]
const PORSZA_SIZE := Vector3(1.85, 1.3, 4.4)
## The race back's start (F 2026-11-26): both cars side by side on the Palm's kerb, 3, 2, 1, START!
## (COUNT_S s; the Porsza held still, the player's car held on the brake until the start).
const COUNT_S := 3.6
## A one-lane kerb: the player's car this far behind the Porsza, in its lane.
const GRID_BEHIND := 7.5
const ARRIVE_R := 9.0
const STOP_KMH := 12.0
const HOLD := 0.8
## Faster than this the player is driving, and the call's clock counts (km/h).
const MOVING_KMH := 5.0
## Kemal's stand (data/kebab_stand.json "kemal"): its dishes' grade bonuses come from there.
const STAND := "kemal"
## A bump at this speed or more shakes the bag (m/s).
const BUMP_SPEED := 5.0
const ADVANCE := 50
const BRIBE := 100
const PAY := 120
const RESPECT := 30

static var CALL_AT: Vector2 = Pacer.span("tajny", "call_at")
static var RETRY: float = Pacer.num("tajny", "retry")
static var RING_LIFE: float = Pacer.num("tajny", "ring_life")
static var WARM: float = Pacer.num("tajny", "warm")
static var BRIBE_AT: float = Pacer.num("tajny", "bribe_at")
static var BRIBE_LIFE: float = Pacer.num("tajny", "bribe_life")
static var BANNER: float = Pacer.num("tajny", "banner")

enum Stage {NONE, TO_SHOP, COUNTER, TO_PALM, TASTE, RACE, PAYOFF}

var dialogue_node: Node
var graph: LaneGraph
var traffic: Node3D
var crowds: Node
var storefronts: Node
var jobs: Node
## The QUESTS screen (main.gd, the same as the guide's beta card).
var open_quests: Callable
## On for this run (the DEV setting or --tajny); `active`: and the save has the mission ahead.
var on := false
var active := false
## --tajny: the call 2 s in; --tajny=palm / =race: straight to the tasting / the race.
var test_jump := ""

var stage := Stage.NONE
var step := ""
var saved := Saved.NONE
var dish := 0
var sauce := 0
var cam := false
## 0 no message (yet), 1 taken, 2 shown to the camera, 3 ignored.
var bribe := 0
## The sauce's pour at the stand: "good", "dry" or "jacket".
var pour := "good"
var grade := 0.0
var bumps := 0
var won := false
var declines := 0

var _world: Node3D
var _rng := RandomNumberGenerator.new()
var _played := 0.0
## Seconds driven while free (the call's clock, `_idle_tick`).
var _drove := 0.0
var _due := INF
var _hold_t := 0.0
var _stage_t := 0.0
var _bag_t := 0.0
var _shop_kerb := {}
var _palm_kerb := {}
var _porsza: Node3D
var _porsza_d = null
var _race: RaceSession
var _racer: RaceSession.Racer
var _race_dist := PackedFloat32Array()
var _race_t := 0.0
## The countdown before the race back (COUNT_S down to 0, then the start); 0 while racing.
var _count := 0.0
var _count_said := 0
## Puts the car at (position, yaw) at once, the camera cut too (main.gd `_place_car`, set after
## the join, as street_meet.gd's).
var place_car: Callable
var _rank_t := 0.0
var _sticker: MeshInstance3D
var _stand_ui: KebabStandUi
var _palm_ui: PalmTastingUi
var _window_ui: KemalWindowUi
var _city_drawn: Callable
var _hud_was := true
var _banner_t := 0.0


# --- the wiring -----------------------------------------------------------------------------------

func install(ctx: GameCtx) -> bool:
	var flag: String = ctx.flags.tajny_flag
	var setting_on: bool = ctx.settings != null and bool(ctx.settings.get("tajny"))
	if flag == "0" or ctx.graph == null or ctx.traffic == null or ctx.crowds == null:
		return false
	super(ctx)
	name = "TajnyKlient"
	on = flag != "" or setting_on
	test_jump = flag if flag in ["palm", "race"] else ""
	dialogue_node = ctx.dialogue
	graph = ctx.graph as LaneGraph
	traffic = ctx.traffic
	crowds = ctx.crowds
	storefronts = ctx.storefronts
	jobs = ctx.jobs
	car = ctx.car
	vehicle = ctx.vehicle
	_city_drawn = ctx.city_drawn
	log_on = flag != ""
	autopilot = ctx.flags.autopilot
	return true


func setup(world: Node3D) -> void:
	tag = "tajny klient"
	colour = COLOUR
	dark = DARK
	rescue_calls = RescueCalls.HOLD  # the opening holds the rescue line and lets it go on after
	card_life = RING_LIFE
	first_call = INF  # its own call clock (`_idle_tick`)
	super.setup(world)
	_world = world
	_rng.randomize()
	saved = _saved()
	active = on and is_due(wallet)
	if wallet != null and bool(wallet.keep.get(KEEP, false)) and crowds != null:
		crowds.kemal_mlask()
	if active:
		dish = int(wallet.intro.get(DISH_KEY, 0))
		sauce = int(wallet.intro.get(SAUCE_KEY, 0))
		cam = int(wallet.intro.get(CAM_KEY, 0)) == 1
		bribe = int(wallet.intro.get(BRIBE_KEY, 0))
		pour = POURS[clampi(int(wallet.intro.get(POUR_KEY, 0)), 0, POURS.size() - 1)]
		_due = _rng.randf_range(CALL_AT.x, CALL_AT.y) if saved == Saved.NONE else CALL_AT.x * 0.5
		if hud != null and hud.has_method("set_vehicle_shown"):
			hud.set_vehicle_shown(false)
	if car != null and car.has_signal("impact"):
		car.impact.connect(_on_impact)
	_porsza = Node3D.new()
	_porsza.name = "KebabuloPorsza"
	var mi := MeshInstance3D.new()
	mi.mesh = StreetMeet.car_mesh("porsze")
	mi.material_override = Models.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_porsza.add_child(mi)
	_porsza.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_porsza.visible = false
	world.add_child(_porsza)
	_log("%s, saved chapter %d, call in %.0f s" % ["on" if active else ("on, done" if on else "off"), saved, _due])


func joined(_ctx: GameCtx) -> void:
	if not active:
		return
	if test_jump == "palm" or test_jump == "race":
		get_tree().create_timer(2.0).timeout.connect(func() -> void: _jump(test_jump))
	elif log_on:
		_due = 2.0


## The mission is ahead on this save: not done, and a fresh save (the guide's own rule) or one
## where it was taken (STAGE_KEY).
static func is_due(w: Node) -> bool:
	if w == null:
		return false
	var st := int(w.intro.get(STAGE_KEY, 0))
	if st >= Saved.DONE:
		return false
	if st > Saved.NONE:
		return true
	return not w.intro.has("done") and w.jobs_done() == 0 and int(w.zl) == 0 and w.ladder.is_empty()


func _saved() -> Saved:
	return int(wallet.intro.get(STAGE_KEY, 0)) as Saved if wallet != null else Saved.NONE


func _save(st: Saved) -> void:
	saved = st
	if wallet == null:
		return
	wallet.intro[STAGE_KEY] = int(st)
	wallet.intro[DISH_KEY] = dish
	wallet.intro[SAUCE_KEY] = sauce
	wallet.intro[CAM_KEY] = 1 if cam else 0
	wallet.intro[BRIBE_KEY] = bribe
	wallet.intro[POUR_KEY] = maxi(0, POURS.find(pour))
	wallet.save()


## A line of the group by its tag: [Polish, English] (["", ""] and a warning when it is missing).
func w(t: String) -> Array:
	var l: Array = dialogue_node.line(WORDS, t, true) if dialogue_node != null else []
	if l.size() < 2:
		push_warning("tajny_klient.gd: no line '%s'" % t)
		return ["", ""]
	return [str(l[0]), str(l[1])]


## A card button from a line: "PL|EN".
func _b(t: String) -> String:
	var l := w(t)
	return "%s|%s" % [l[0], l[1]]


func _beat(id: String, how := "") -> void:
	beat.emit("tk_" + id, how, _played)
	_log("beat %s %s at %.1f s" % [id, how, _played])


# --- the call -------------------------------------------------------------------------------------

func _tick(dt: float) -> void:
	_played += dt
	if _banner_t > 0.0:
		_banner_t -= dt
		if _banner_t <= 0.0:
			hud.hide_banner()
	if wallet != null and bool(wallet.keep.get(KEEP, false)) and _sticker == null and int(_played * 2.0) != int((_played - dt) * 2.0):
		_place_sticker()


## Its own call clock: Kebabulo rings once the player has driven `_due` s (free and moving, so not
## on the title, the loading or a parked car; any free time on a test run), and a minute after a
## "not now"; the director's gate and turn as for every call (`_ring_turn`). Twice a second.
func _idle_tick(dt: float) -> void:
	if not active or int(_played * 2.0) == int((_played - dt) * 2.0):
		return
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	if bool(v[2]):
		return  # not in the air: the secret customer drives
	if not free_now.call():
		return
	if float(v[1]) > MOVING_KMH or log_on:
		_drove += 0.5
	if _drove < _due:
		return
	if _ring_turn(""):
		_due = INF
		ring()
		_beat("call", "resume" if saved > Saved.NONE else "")


func _call_card() -> Dictionary:
	var a := w("call_about")
	return {"who": "Kebabulo", "about": a}


func _offer_card() -> Dictionary:
	return {"title": w("offer_title"), "body": w("offer_resume" if saved >= Saved.BOUGHT else "offer_body"),
			"face": "Kebabulo", "buttons": PackedStringArray([_b("btn_in"), _b("btn_not_now")])}


func _refused(timed_out: bool) -> void:
	declines += 1
	_due = _drove + RETRY
	var l := w("retry")
	hud.toast(l[0], l[1])
	_beat("declined", "timeout" if timed_out else "button")


func _ended() -> void:
	_close_stand()
	_close_palm()
	_close_window()
	if active and stage != Stage.NONE:
		# Dropped with the ✕ (or the clock): the call comes again, the chapter kept.
		_due = _drove + RETRY
	_race_end()
	stage = Stage.NONE


func _quit_words() -> Array:
	return w("quit")


func grounded() -> Array:
	return w("grounded") if phase == Phase.RUN else []


# --- the run --------------------------------------------------------------------------------------

func _begin() -> void:
	_beat("accepted", str(declines))
	if saved == Saved.NONE:
		_save(Saved.TAKEN)
	hud.show_banner(w("banner")[0], COLOUR)
	_banner_t = BANNER
	hud.cue("sting")
	Access.buzz(120, 0.9)
	if saved >= Saved.BOUGHT:
		_to_palm(true)
		return
	if wallet != null:
		wallet.pay(ADVANCE, 0)
	var a := w("advance")
	hud.toast(a[0], a[1], Messages.INFO)
	_to_shop()


func _to_shop() -> void:
	_shop_kerb = _kerb_at(SITE)
	if _shop_kerb.is_empty():
		push_warning("tajny_klient.gd: no kerb by KEBAB U KEMALA")
		drop(false)
		return
	stage = Stage.TO_SHOP
	_hold_t = 0.0
	var r: Vector3 = _shop_kerb["ring"]
	set_target(Vector2(r.x, r.z))
	_log("to KEBAB U KEMALA: %.0f m" % Vector2(car.global_position.x, car.global_position.z).distance_to(Vector2(r.x, r.z)))


## The kerb in front of a crowd site's door: {"ring": Vector3 on the road, "edge", "s", "heading"}.
func _kerb_at(id: String) -> Dictionary:
	if crowds == null or not crowds.by_id.has(id) or jobs == null:
		return {}
	var site: Dictionary = crowds.sites[crowds.by_id[id]]
	if not site.has("door") or not site.has("out"):
		return {}
	var door: Vector2 = site["door"]
	return _kerb_near(door, door - (site["out"] as Vector2) * 4.0)


func _kerb_near(door: Vector2, toward: Vector2) -> Dictionary:
	var k: Dictionary = jobs._kerb(door, toward, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		return {}
	var p: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
	return {"ring": Vector3(p.x, graph.surface(k["edge"], p), p.y), "edge": k["edge"], "s": k["s"], "heading": k["heading"],
			"side": k["side"]}


func _run_tick(dt: float) -> void:
	_stage_t += dt
	var v: Array = vehicle.call()
	var at: Vector3 = v[0]
	var kmh: float = v[1]
	match stage:
		Stage.TO_SHOP:
			var r: Vector3 = _shop_kerb["ring"]
			_status("st_shop", r, at, 0.0)
			if _arrived(dt, at, kmh, r):
				_counter()
		Stage.TO_PALM:
			_bag_t += dt
			var r: Vector3 = _palm_kerb["ring"]
			_status("st_palm", r, at, clampf(1.0 - _bag_t / WARM, 0.0, 1.0))
			if bribe == 0 and _bag_t >= BRIBE_AT:
				_bribe()
			elif _arrived(dt, at, kmh, r):
				_taste()
		Stage.RACE:
			_race_tick(dt, at)


func _status(t: String, goal: Vector3, at: Vector3, heat: float) -> void:
	var m := roundi(Vector2(at.x, at.z).distance_to(Vector2(goal.x, goal.z)))
	var l := w(t)
	var icons := {"heat": heat} if stage == Stage.TO_PALM else {}
	status(w("banner")[0], "", "%d m" % m, l, heat if stage == Stage.TO_PALM else 0.0, Color(0, 0, 0, 0), "", icons)


func _arrived(dt: float, at: Vector3, kmh: float, to: Vector3) -> bool:
	if Vector2(at.x, at.z).distance_to(Vector2(to.x, to.z)) <= ARRIVE_R and kmh < STOP_KMH:
		_hold_t += dt
	else:
		_hold_t = 0.0
	if _hold_t >= HOLD:
		_hold_t = 0.0
		return true
	return false


# --- chapter 1: the counter -------------------------------------------------------------------------

func _counter() -> void:
	stage = Stage.COUNTER
	hide_status()
	_beat("shop")
	step = "door"
	card_face = "Kemal"
	show_card(w("menu_title"), w("shop_door"), PackedStringArray([_b("btn_enter")]), 0.0)


## WEJDŹ: the 2D stand over everything (the root's viewport, as the pub's pong), the city's 3D off,
## the car held and the HUD away until WYJDŹ.
func _open_stand() -> void:
	step = "stand"
	if _stand_ui == null:
		_stand_ui = KebabStandUi.new()
		_stand_ui.name = "KebabStand"
		var host: Node = hud.get_parent() if hud != null and hud.get_parent() != null else self
		host.add_child(_stand_ui)
		_stand_ui.finished.connect(_stand_done)
	_stand_ui.auto_play = autopilot
	_stand_ui.auto_pour = Access.auto_pour
	_stand_ui.log_on = log_on
	_stand_ui.zl = int(wallet.zl) if wallet != null else 0
	_stand_ui.pay_tip = func() -> bool:
		if wallet == null or int(wallet.zl) < KebabStand.TIP:
			return false
		wallet.spend(KebabStand.TIP)
		_stand_ui.zl = int(wallet.zl)
		return true
	_stand_ui.cue = func(n: String) -> void:
		if hud != null:
			hud.cue(n)
	_hold_world(true)
	_stand_ui.open(STAND, true)
	_beat("stand")


## The world held while the stand is up, and let go after.
func _hold_world(held: bool) -> void:
	if held:
		_hud_was = hud.visible if hud != null else true
	if hud != null:
		hud.visible = _hud_was if not held else false
	if _city_drawn.is_valid():
		_city_drawn.call(not held)
	if car != null:
		if held:
			if "vel" in car:
				car.set("vel", Vector3.ZERO)
			if "forward_speed" in car:
				car.set("forward_speed", 0.0)
		car.process_mode = Node.PROCESS_MODE_DISABLED if held else Node.PROCESS_MODE_INHERIT


func _close_stand() -> void:
	if _stand_ui != null and _stand_ui.inside:
		_stand_ui.hide_now()
		_hold_world(false)


## WYJDŹ: the order, paid; to the Palm.
func _stand_done(r: Dictionary) -> void:
	_hold_world(false)
	if phase != Phase.RUN or stage != Stage.COUNTER:
		return
	dish = int(r.get("dish", 0))
	sauce = int(r.get("sauce", 0))
	cam = bool(r.get("cam", false))
	pour = str(r.get("pour", "good"))
	var price := int(r.get("price", 0))
	if price > 0 and wallet != null:
		wallet.spend(mini(price, int(wallet.zl)))
	_beat("order", "cam" if cam else "self")
	_beat("pour", pour)
	_save(Saved.BOUGHT)
	_to_palm(false)


func _card_pressed(index: int) -> void:
	match step:
		"door":
			_open_stand()
		"bribe":
			_bribe_answer(index)
		"race_call":
			_start_race()
		"next":
			_done(index == 0)
		_:
			pass


func _card_expired() -> void:
	if step == "bribe":
		_bribe_answer(-1)
	else:
		_card_pressed(0)


# --- chapter 2: the Palm --------------------------------------------------------------------------

func _to_palm(resumed: bool) -> void:
	_palm_kerb = _find_palm_kerb()
	if _palm_kerb.is_empty():
		push_warning("tajny_klient.gd: no kerb by the Palm")
		drop(false)
		return
	stage = Stage.TO_PALM
	step = ""
	_bag_t = WARM * 0.25 if resumed else 0.0  # a new session's kebab: Kemal made another, a bit later
	bumps = 0
	_hold_t = 0.0
	var r: Vector3 = _palm_kerb["ring"]
	_park_porsza(_palm_kerb)
	set_target(Vector2(r.x, r.z), true)
	var l := w("to_palm")
	hud.toast(l[0], l[1], Messages.QUEST_LINE)
	_beat("bought", "resume" if resumed else "")


## The meeting's kerb near the Palm: the first street round the roundabout with free pavement.
func _find_palm_kerb() -> Dictionary:
	for off: Vector2 in PALM_TRIES:
		var k := _kerb_near(PALM + off, PALM + off * 1.4)
		if not k.is_empty():
			var r: Vector3 = k["ring"]
			if Vector2(r.x, r.z).distance_to(PALM) > 25.0:
				return k
	return {}


## Kebabulo's Porsza parked a car's length ahead of the ring, nose along the kerb.
func _park_porsza(k: Dictionary) -> void:
	var h: Vector2 = k["heading"]
	var r: Vector3 = k["ring"]
	var p := Vector3(r.x, r.y, r.z) + Vector3(h.x, 0.0, h.y) * 6.5
	_porsza.global_transform = Transform3D(Basis(Vector3.UP, atan2(-h.x, -h.y)), p)
	_porsza.visible = true


func _on_impact(_collider: Object, speed: float) -> void:
	if stage == Stage.TO_PALM and speed >= BUMP_SPEED:
		bumps += 1


## DŻEMINI KEBAB's agent on COTAM, beside the road: 100 zł to say it was bad.
func _bribe() -> void:
	step = "bribe"
	bribe = 3
	show_side_card(w("bribe_title"), w("bribe_body"), PackedStringArray([_b("btn_take"), _b("btn_show")]), BRIBE_LIFE,
			COTAM_COLOUR, true)
	hud.cue("offer")
	_beat("bribe_offered")


func _bribe_answer(index: int) -> void:
	step = ""
	if index == 0:
		bribe = 1
		if wallet != null:
			wallet.pay(BRIBE, 0)
		var l := w("bribe_taken")
		hud.toast(l[0], l[1], Messages.QUEST_LINE)
	elif index == 1:
		bribe = 2
		var l := w("bribe_shown")
		hud.toast(l[0], l[1], Messages.QUEST_LINE)
	else:
		bribe = 3
	_beat("bribe", ["", "take", "show", "ignore"][bribe])


## At the Palm: Kebabulo bites, on Zbyszek's livestream (palm_tasting_ui.gd over everything, the
## city's 3D off, the car held, as the stand).
func _taste() -> void:
	stage = Stage.TASTE
	hide_status()
	clear_target()
	grade = grade_of(dish, _bag_t / WARM, bumps, cam, pour)
	_beat("palm", "%.1f" % grade)
	step = "taste"
	if _palm_ui == null:
		_palm_ui = PalmTastingUi.new()
		_palm_ui.name = "PalmTasting"
		var host: Node = hud.get_parent() if hud != null and hud.get_parent() != null else self
		host.add_child(_palm_ui)
		_palm_ui.finished.connect(_palm_done)
	_palm_ui.auto_play = autopilot
	_palm_ui.log_on = log_on
	_palm_ui.cue = func(n: String) -> void:
		if hud != null:
			hud.cue(n)
	_hold_world(true)
	_palm_ui.open(tasting_spec())
	_beat("tasting")


## What the livestream shows, from this run: his lines, the grade and its roast, the order, the
## badge so far.
func tasting_spec() -> Dictionary:
	var order := KebabStand.say("dish_%d" % dish)
	var sc := KebabStand.say("sauce_%d" % sauce)
	var b := badges()
	return {
		"hello": w("palm_hello"),
		"verdict": _verdict(),
		"roast": w("roast_" + roast_of(_bag_t / WARM, bumps, cam, grade, pour)),
		"grade": grade,
		"grade_label": grade_text(grade),
		"cam": cam,
		"order": ["%s · %s" % [order[0], sc[0]], "%s · %s" % [order[1], sc[1]]],
		"badge": b[0] if not b.is_empty() else [],
		"dish": KebabStand.dish_id(STAND, dish),
		"caption": w("mlask_caption"),
		"seed": int(grade * 10.0) + dish * 7 + bumps,
	}


func _close_palm() -> void:
	if _palm_ui != null and _palm_ui.inside:
		_palm_ui.hide_now()
		_hold_world(false)


## The livestream over: MLASK reached the stats, and the race call.
func _palm_done(r: Dictionary) -> void:
	_hold_world(false)
	if phase != Phase.RUN or stage != Stage.TASTE:
		return
	var roast := roast_of(_bag_t / WARM, bumps, cam, grade, pour)
	_beat("mlask", roast)
	if bool(r.get("skipped", false)):
		_beat("tasting_skip")
	step = "race_call"
	card_face = "Kebabulo"
	show_card(w("kebabulo"), w("race_call"), PackedStringArray([_b("btn_race")]), 0.0)


## His grade from the run (pure: the check tests it): 8.0, the dish's bonus (the stand's menu), up
## to +1.4 for a warm kebab (`cool` 0 hot .. 1 cold), -0.3 a bump (four at most), -0.2 for the VIP
## kebab's extra meat, -0.4 for a dry pour and -0.2 for sauce on the jacket; 6.0-9.8, and 11 for a
## perfect run (the biggest dish, hot, not one bump, for himself, the sauce just right).
static func grade_of(dish_i: int, cool: float, bump_n: int, for_cam: bool, poured := "good") -> float:
	var dishes: Array = KebabStand.stand_of(STAND).get("dishes", [])
	var bonus := 0.0
	if not dishes.is_empty():
		bonus = float((dishes[clampi(dish_i, 0, dishes.size() - 1)] as Dictionary).get("bonus", 0.0))
	var g := 8.0 + bonus
	g += 1.4 * (1.0 - clampf(cool, 0.0, 1.0))
	g -= 0.3 * mini(bump_n, 4)
	if for_cam:
		g -= 0.2
	if poured == "dry":
		g -= 0.4
	elif poured == "jacket":
		g -= 0.2
	if dish_i == dishes.size() - 1 and cool <= 0.35 and bump_n == 0 and not for_cam and poured == "good":
		return 11.0
	return clampf(snappedf(g, 0.1), 6.0, 9.8)


## What cost the most tenths, for the roast: "perfect", "bumps", "cold", "dry", "jacket", "cam" or
## "fine".
static func roast_of(cool: float, bump_n: int, for_cam: bool, g: float, poured := "good") -> String:
	if g >= 11.0:
		return "perfect"
	if bump_n >= 2:
		return "bumps"
	if cool > 0.6:
		return "cold"
	if poured == "dry" or poured == "jacket":
		return poured
	if for_cam:
		return "cam"
	return "fine"


## His verdict, line by line: the sparklers if the camera saw Kemal, the bun, Berlin, and DŻEMINI if
## the camera saw the bribe (or the quiet one if the player took it). The bite's "…ale dobry" is the
## MLASK panel's caption now (`mlask_caption`; Fable's critique: one tap fewer).
func _verdict() -> Array:
	var out: Array = [w("bite_cam")] if cam else []
	out.append_array([w("bun"), w("berlin")])
	if bribe == 2:
		out.append(w("dzemini_roast"))
	elif bribe == 1:
		out.append(w("quiet"))
	return out


static func grade_text(g: float) -> String:
	if g >= 11.0:
		return "11 / 10"
	return ("%.1f / 10" % g).replace(".", ",")


# --- chapter 3: the race back and the sticker --------------------------------------------------------

func _start_race() -> void:
	_shop_kerb = _kerb_at(SITE)
	if _shop_kerb.is_empty() or _palm_kerb.is_empty():
		_payoff(true)
		return
	stage = Stage.RACE
	step = ""
	var goal: Vector3 = _shop_kerb["ring"]
	var node: int = graph.e_b[int(_shop_kerb["edge"])]
	_race_dist = graph.distances_to(node)
	var e := int(_palm_kerb["edge"])
	var lane: int = maxi(graph.e_lanes[e] - 1, 0)
	var s := float(_palm_kerb["s"])
	_porsza_d = traffic.add_node_driver(_porsza, PORSZA_SIZE, e, lane, s)
	if _porsza_d == null:
		_payoff(true)
		return
	_porsza_d.persistent = true
	_porsza_d.stun = COUNT_S + 0.5
	_grid(e, lane, s)
	_race = RaceSession.new()
	_race.setup(graph, traffic, RacePlanner.new(graph), RaceCuts.new(), {node: _race_dist})
	_race.course(PackedInt32Array([node]), Vector2(goal.x, goal.z), RaceSession.FINISH_RADIUS)
	var pc := 0
	if "top_mult" in car and "accel_mult" in car:
		pc = Ladder.car_class(float(car.top_mult), float(car.accel_mult))
	_racer = _race.add(_porsza_d, "Kebabulo", Ladder.FIRST_RACER, Ladder.pace(0),
			{"top": Ladder.class_top(Ladder.race_class(0), pc), "cuts": false, "dice": _rng.randi()})
	_race.prepare()
	_race_t = 0.0
	_rank_t = 0.0
	_count = COUNT_S
	_count_said = 0
	set_target(Vector2(goal.x, goal.z))
	_beat("grid")
	_log("the grid at the Palm, race to Kemal: %.0f m by road" % _player_left())


## The player's car beside the Porsza on the next lane in (behind it on a one-lane kerb).
func _grid(e: int, lane: int, s: float) -> void:
	if not place_car.is_valid():
		return
	var d: Vector2 = graph.direction(e, s)
	var at: Vector2
	if lane >= 1:
		at = graph.point_at(e, s, graph.lane_offset(e, lane - 1))
	else:
		at = graph.point_at(e, maxf(0.0, s - GRID_BEHIND), graph.lane_offset(e, lane))
	place_car.call(Vector3(at.x, graph.surface(e, at), at.y), atan2(-d.x, -d.y))


## The race's start, after the countdown: GO for him and for the player.
func _go() -> void:
	_count = 0.0
	if _porsza_d != null:
		_porsza_d.stun = 0.0
	_race.start(_racer)
	_race_t = 0.0
	hud.show_banner(w("race_go")[0], COLOUR)
	_banner_t = BANNER
	hud.cue("go")
	Access.buzz(80, 0.8)
	_beat("race")


## The countdown's frame: a number a second, the cue once a number.
func _count_tick(dt: float) -> void:
	_count -= dt
	_race.plan_tick(false)
	var n := ceili(_count - 0.6)
	if n >= 1:
		if n != _count_said:
			_count_said = n
			hud.cue("count")
			Access.buzz(30, 0.4)
		hud.show_banner(str(n), COLOUR)
	else:
		_go()


## The player's car held on the brake on the grid (main.gd calls it each frame, as rivals.gd's).
func hold_car(c: Node) -> void:
	if c == null or stage != Stage.RACE or _count <= 0.0 or phase != Phase.RUN:
		return
	c.target_dir = Vector3.ZERO
	c.steer = 0.0
	c.throttle = 0.0
	c.nitro_on = false
	c.braking = true


func _player_left() -> float:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var goal: Vector3 = _shop_kerb["ring"]
	var hit: Array = graph.snap(p, 25.0)
	if hit.is_empty():
		return p.distance_to(Vector2(goal.x, goal.z)) * 1.3
	var e: int = hit[0]
	var best: float = graph.remaining(_race_dist, e, float(hit[2]))
	var rev: int = graph.e_reverse[e]
	if rev >= 0:
		best = minf(best, graph.remaining(_race_dist, rev, graph.e_len[e] - float(hit[2])) + 25.0)
	return best


func _race_tick(dt: float, at: Vector3) -> void:
	if _race == null:
		return
	if _count > 0.0:
		_count_tick(dt)
		return
	_race_t += dt
	_race.plan_tick(false)
	_race.advance(_race_t)
	_rank_t -= dt
	if _rank_t <= 0.0:
		_rank_t = 0.2
		_race.rank(_player_left())
	var goal: Vector3 = _shop_kerb["ring"]
	var place := _race.place_of(_player_left())
	var m := roundi(Vector2(at.x, at.z).distance_to(Vector2(goal.x, goal.z)))
	status(w("race_banner")[0], "", "%d m" % m, w("st_race"), 0.0, Color(0, 0, 0, 0), "1ST" if place == 1 else "2/2")
	if Vector2(at.x, at.z).distance_to(Vector2(goal.x, goal.z)) <= RaceSession.FINISH_RADIUS:
		_payoff(not _racer.home)
	elif _racer.home and _race_t > 0.0 and not won and step == "":
		# He is there first: he waits by the door (the race ends when the player arrives).
		step = "waiting"


func _race_end() -> void:
	if _race != null:
		_race.end()
		_race = null
	if _porsza_d != null:
		traffic.remove(_porsza_d)
		_porsza_d = null


## At Kemal's door: SZYBA, the 2D payoff (the winner's slap, the queue, Kemal's tears, PARAGON).
func _payoff(player_first: bool) -> void:
	won = player_first
	_race_end()
	stage = Stage.PAYOFF
	hide_status()
	clear_target()
	if not _shop_kerb.is_empty():
		_park_porsza({"ring": _shop_kerb["ring"], "heading": _shop_kerb["heading"]})
	_beat("race_end", "won" if won else "lost")
	_open_window()


## SZYBA over everything (the root's viewport, as the stand and the tasting), the city's 3D off.
func _open_window() -> void:
	step = "slap"
	if _window_ui == null:
		_window_ui = KemalWindowUi.new()
		_window_ui.name = "KemalWindow"
		var host: Node = hud.get_parent() if hud != null and hud.get_parent() != null else self
		host.add_child(_window_ui)
		_window_ui.finished.connect(_window_done)
	_window_ui.auto_play = autopilot
	_window_ui.log_on = log_on
	_window_ui.cue = func(n: String) -> void:
		if hud != null:
			hud.cue(n)
	_hold_world(true)
	_window_ui.open(window_spec())
	_beat("szyba")


## What SZYBA shows, from this run: who won, the winner's line, Kemal's, and the receipt's rows.
func window_spec() -> Dictionary:
	var order := KebabStand.say("dish_%d" % dish)
	var sc := KebabStand.say("sauce_%d" % sauce)
	return {
		"won": won,
		"line": w("race_won" if won else "race_lost"),
		"cry": w("kemal_cry"),
		"title": w("result_title"),
		"order": ["%s · %s" % [order[0], sc[0]], "%s · %s" % [order[1], sc[1]]],
		"grade": grade_text(grade),
		"pay": PAY,
		"respect": RESPECT,
		"badges": badges(),
		"leak": w("leak") if bribe == 1 else [],
	}


func _close_window() -> void:
	if _window_ui != null and _window_ui.inside:
		_window_ui.hide_now()
		_hold_world(false)


## SZYBA over: the sticker for good (the queue in the city, the 3D sticker), the pay, KEBAB FM, and
## CO DALEJ?.
func _window_done(r: Dictionary) -> void:
	_hold_world(false)
	if phase != Phase.RUN or stage != Stage.PAYOFF:
		return
	if wallet != null:
		wallet.keep[KEEP] = true
	if crowds != null:
		crowds.kemal_mlask()
	_place_sticker()
	var radio := w("radio")
	hud.toast(radio[0], radio[1], Messages.RADIO)
	if wallet != null:
		wallet.pay(PAY, RESPECT, "tajny")
	_beat("sticker", "player" if won else "kebabulo")
	if bool(r.get("skipped", false)):
		_beat("szyba_skip")
	_beat("paragon")
	step = "next"
	show_card(w("next_title"), w("next_body"), PackedStringArray([_b("btn_quests"), _b("btn_drive")]), 0.0, true)


## The badges of this run, [Polish, English] names.
func badges() -> Array:
	var out: Array = []
	if won and not cam and bribe != 1:
		out.append(w("badge_gold"))
	if cam:
		out.append(w("badge_cam"))
	if bribe == 1:
		out.append(w("badge_sold"))
	return out


func _done(quests: bool) -> void:
	_save(Saved.DONE)
	if wallet != null:
		wallet.intro["done"] = 1  # the old guide's end too: it does not start after this
		wallet.save()
	active = false
	if hud.has_method("set_vehicle_shown"):
		hud.set_vehicle_shown(true)
	_beat("done", "quests" if quests else "drive")
	finish()
	if quests and open_quests.is_valid():
		open_quests.call()


## The MLASK sticker on Kemal's window beside his sign, once the shop's sector has placed it.
func _place_sticker() -> void:
	if _sticker != null or _world == null or storefronts == null or not storefronts.has_method("venue_wall"):
		return
	var wall: Dictionary = storefronts.venue_wall(SITE)
	if wall.is_empty():
		return
	var n: Vector3 = wall["n"]
	var t: Vector3 = wall["t"]
	_sticker = MeshInstance3D.new()
	_sticker.name = "KemalSticker"
	_sticker.mesh = TrendJob.sticker_mesh()
	_sticker.material_override = Models.material()
	_sticker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sticker.visibility_range_end = 260.0
	_world.add_child(_sticker)
	var at: Vector3 = (wall["p"] as Vector3) + Vector3.UP * maxf(float(wall["up"]) - 0.9, 1.5) - t * 1.8 + n * 0.16
	_sticker.global_transform = Transform3D(Basis(t, Vector3.UP, n), at)


# --- test jumps -----------------------------------------------------------------------------------

## --tajny=palm: the order made (an XXL, garlic, for himself), the car by the Palm's kerb, the run
## on; --tajny=race: and the tasting done, the race starts.
func _jump(to: String) -> void:
	if phase != Phase.IDLE:
		return
	dish = 3
	sauce = 0
	cam = false
	pour = "good"
	_save(Saved.BOUGHT)
	start()
	if stage != Stage.TO_PALM:
		return
	var r: Vector3 = _palm_kerb["ring"]
	car.global_position = Vector3(r.x, r.y + 0.5, r.z) - Vector3((_palm_kerb["heading"] as Vector2).x, 0.0, (_palm_kerb["heading"] as Vector2).y) * 4.0
	if "vel" in car:
		car.vel = Vector3.ZERO
	if to == "race":
		_bag_t = 0.0
		bribe = 2
		grade = grade_of(dish, 0.0, 0, false, pour)
		stage = Stage.TASTE
		hide_status()
		clear_target()
		_start_race()
