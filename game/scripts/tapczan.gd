extends "res://scripts/activity.gd"
## THE TAPCZAN's door (F's ask 2026-11-24, docs/design/tapczan-pub.md): the craft-beer pub on
## Sienkiewicza 4 (landmarks site `tapczan`, PR #1046) can be walked into any time, no quest
## needed. An activity of the kit with no call (`start` from the pill, as the round-up starts from a
## pull-in):
##   - idle: within MARK_R m the door's ring glows on the pavement in front of the bay with the door
##     (`set_mark`, amber), and once the car stops at the kerb within PILL_R m of it the context pill
##     says WEJDŹ / GO IN;
##   - the run: inside (tapczan_room.gd): the HUD aside, the car waiting with its process off, the
##     camera on the room (main.gd asks `room_view`); WYPIJ PIWKO (the TAP LIST: a beer's price on
##     the bill and out of the wallet, its strength into the tipsy spell), ZAGRAJ (beer pong,
##     beer_pong.gd) and WYJDŹ; a won game pays its stake (wallet kind "pong"); the run ends at WYJDŹ;
##   - after: every pint and every cup the rival took makes the drive after it tipsy (tipsy.gd,
##     about a minute, fading).
## The bar crawl's "Kraftowa" starts at the same door (bar_crawl.gd); QUESTS lists the pub under
## SIDE JOBS as "Rajd Kraftowy · THE TAPCZAN" (quest_book.gd JOB_KINDS "crawl", `quest_entry`) and the
## maps show its mark (SERVICE layer, group "crawl").
##
## Flags (dev_flags.gd): --tapczan=0 (none), --tapczan=in (straight in, the room's panel to use),
## --tapczan=taps (straight in with the TAP LIST open, for shots),
## --tapczan=pong (straight in, a pint and a self-playing game against the first rival, then out:
## the tipsy drive), --tapczan=drunk (the tipsy minute at once), --tapczan-log.
##
## Cost idle: a distance test 4 times a second; the ring (one beacon) only within MARK_R m.

const Room := preload("res://scripts/tapczan_room.gd")
const Tipsy := preload("res://scripts/tipsy.gd")
const MapMarkers := preload("res://scripts/map_markers.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const QuestLines := preload("res://scripts/quest_lines.gd")

## The front of Sienkiewicza 4 (landmarks/srodmiescie.gd TPZ_FRONT_A, _B: map x, z) and the door's
## place along it (u m from the west corner; the east bay is the door) and the ring's, out on the
## terrace's edge by the kerb (v m out of the front).
const FRONT_A := Vector2(-789.1, -46.2)
const FRONT_B := Vector2(-763.1, -56.4)
const DOOR_U := 9.3
const RING_V := 6.6
const MARK_R := 120.0
const PILL_R := 11.0
const STOP_KMH := 6.0
const AMBER := Color("#ffb347")
const AMBER_D := Color("#7a4a12")
const PILL := "tapczan"

var room: Room
var tipsy: Tipsy
var cam: Camera3D
var world_node: Node3D
var _car_body: Node3D
var _hud_was := true
var _poll := 0.0
var _flag := ""
var _mark_on := false
var _pong_won := 0
var _ctx_hide_hud := false


func install(ctx: GameCtx) -> bool:
	_flag = str(ctx.flags.tapczan_flag) if "tapczan_flag" in ctx.flags else ""
	# None with --tapczan=0, and none in a landmark's solo shots (its beam stood in the turntables).
	if _flag == "0" or str(ctx.flags.solo_site) != "":
		return false
	super(ctx)
	name = "Tapczan"
	tag = "tapczan"
	colour = AMBER
	dark = AMBER_D
	rescue_calls = RescueCalls.HOLD
	log_on = bool(ctx.flags.tapczan_log) if "tapczan_log" in ctx.flags else false
	_ctx_hide_hud = bool(ctx.flags.hide_hud) if "hide_hud" in ctx.flags else false
	autopilot = ctx.flags.autopilot
	vehicle = ctx.vehicle
	clock = ctx.hour
	dialogue = ctx.dialogue
	_car_body = ctx.car
	world_node = ctx.world
	return true


func setup(world: Node3D) -> void:
	super.setup(world)
	room = Room.new()
	room.name = "TapczanRoom"
	room.hud = hud
	room.wallet = wallet
	room.log_on = log_on
	# --nohud (shots of the room alone): the room's own panel stays hidden too.
	room.panel_off = bool(_ctx_hide_hud)
	add_child(room)
	room.left.connect(_on_left)
	room.drank.connect(func(drinks: float) -> void: tipsy.add(drinks))
	room.pong_over.connect(_on_pong)
	tipsy = Tipsy.new()
	tipsy.name = "Tipsy"
	tipsy.hud = hud
	tipsy.car = _car_body
	add_child(tipsy)
	tipsy.setup(world)
	hud.context_pressed.connect(func(who: String) -> void:
		if who == PILL and phase == Phase.IDLE:
			hud.hide_pill()
			start())
	if hud.get("markers") != null:
		var d := door()
		# F 2026-11-24: a permanent mark on both maps, a beer mug named THE TAPCZAN (SERVICE layer).
		hud.markers.put_all("tapczan", [{"key": "door", "layer": MapMarkers.Layer.SERVICE, "at": d, "colour": AMBER,
				"shape": MapIcons.POI_MUG, "group": "crawl", "extra": {"name": "THE TAPCZAN"}}])


## Test starts at the join: straight in, a self-playing game, or the tipsy minute.
func joined(ctx: GameCtx) -> void:
	cam = ctx.world.get_viewport().get_camera_3d() if ctx.world != null else null
	room.cam = cam
	match _flag:
		"in", "pong", "taps":
			room.auto_play = _flag == "pong"
			get_tree().create_timer(1.5).timeout.connect(func() -> void:
				if phase == Phase.IDLE:
					start()
				if _flag == "taps":
					room.drink())
		"drunk":
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				tipsy.add(3.0)
				tipsy.go())


# --- places ----------------------------------------------------------------------------------------

static func _front_point(u: float, v: float) -> Vector2:
	var a := (FRONT_B - FRONT_A).normalized()
	var b := Vector2(-a.y, a.x)
	return FRONT_A + a * u + b * v


## The pub's door on the map (x, z).
static func door() -> Vector2:
	return _front_point(DOOR_U, 0.0)


## The ring at the terrace's kerb edge in front of the door.
static func ring_point() -> Vector2:
	return _front_point(DOOR_U, RING_V)


## The SIDE JOBS row's entry (quest_lines.gd), for QUESTS and its SHOW ON MAP pin.
func quest_entry() -> Dictionary:
	var t := Room.pair("quest_title")
	return QuestLines.entry("crawl_tapczan", "crawl", QuestLines.Line.CAR, str(t[0]), str(t[1]), door(), AMBER)


# --- idle: the ring and the pill -----------------------------------------------------------------

func _idle_tick(dt: float) -> void:
	_poll -= dt
	if _poll > 0.0 or not vehicle.is_valid():
		return
	_poll = 0.25
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	var flying := bool(v[2])
	var ring := ring_point()
	var d := Vector2(p.x, p.z).distance_to(ring)
	var want_mark := d < MARK_R and not flying
	if want_mark != _mark_on:
		_mark_on = want_mark
		if want_mark:
			set_mark(Vector3(ring.x, _ground(ring), ring.y), 2.2, AMBER)
		elif _mark != null:
			_mark.visible = false
	var near := d < PILL_R and not flying and absf(float(v[1])) < STOP_KMH
	# Our own pill up counts as free (pill_free_for is about taking it from someone else).
	if near and free_now.call() and (hud.pill_shown(PILL) or hud.pill_free_for(PILL)):
		if not hud.pill_shown(PILL):
			var w := Room.pair("enter")
			hud.show_pill(str(w[0]), str(w[1]), PILL)
	elif hud.pill_shown(PILL):
		hud.hide_pill()


# --- the run: inside ---------------------------------------------------------------------------

func _begin() -> void:
	if hud.pill_shown(PILL):
		hud.hide_pill()
	if _mark != null:
		_mark.visible = false
	_mark_on = false
	_pong_won = 0
	_hud_was = hud.visible
	hud.visible = false
	if _car_body != null:
		_car_body.set("vel", Vector3.ZERO)
		_car_body.set("forward_speed", 0.0)
		_car_body.process_mode = Node.PROCESS_MODE_DISABLED
	if cam == null and world_node != null and world_node.is_inside_tree():
		cam = world_node.get_viewport().get_camera_3d()
	room.cam = cam
	room.enter(world_node)
	_log("in")


func _on_pong(won: bool, stake: int, drinks: int) -> void:
	tipsy.add(drinks)
	if won and stake > 0 and wallet != null:
		wallet.pay(stake, 5, "pong")
		_pong_won += stake


func _on_left() -> void:
	if phase != Phase.RUN:
		return
	finish()


func _ended() -> void:
	if room.inside:
		room.inside = false
	hud.visible = _hud_was
	if _car_body != null:
		_car_body.process_mode = Node.PROCESS_MODE_INHERIT
	tipsy.go()
	_log("out: won %d zl, tipsy %.2f" % [_pong_won, tipsy.amount])


## The ✕ is hidden with the HUD; WYJDŹ is the way out.
func _can_abort() -> bool:
	return false


func grounded() -> Array:
	return Room.pair("leave") if phase == Phase.RUN else []


## No arrow, no stop assist: the door's ring is a mark, not a target.
func stop_spot() -> Vector3:
	return Vector3.INF


## Inside: main.gd's camera looks at the room from its open corner (true: placed).
func room_view(c: Camera3D, pitch: float) -> bool:
	if room == null or not room.inside:
		return false
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(room.yaw), 0.0))
	c.size = room.view_size
	c.global_transform = Transform3D(b, room.centre + b.z * 120.0)
	c.far = 300.0
	return true


## The drive after it: main.gd passes the camera through the tipsy sway.
func sway(xf: Transform3D) -> Transform3D:
	return tipsy.sway(xf) if tipsy != null else xf


## Inside the pub (main.gd: on foot for the sounds, no helicopter).
func inside() -> bool:
	return room != null and room.inside
