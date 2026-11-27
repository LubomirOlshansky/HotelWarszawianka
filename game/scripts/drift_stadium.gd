extends "res://scripts/activity.gd"
## Bokiem na Narodowym, the grey box (F's ask 2026-11-22 and 2026-11-26, docs/design/drift-narodowy.md
## 0b; scoped by docs/design/critique-drift.md section 4: "a grey box that F can hold on the phone"):
## the drift practice on the stadium floor, far off the map at PLACE (the club, the lounge and THE
## TAPCZAN hold the other three corners). An activity of the kit with no call: it starts from the DEV
## page's BOKIEM button or `--drift=osemka`, and the run is the whole visit (✕ leaves).
##   - Inside: the city's HUD aside, the player's car waiting at its spot with its process off, sfx.gd's
##     engine and tyres on the stadium's own car (drift_car.gd, posed from drift_model.gd on the line of
##     drift_line.gd), the camera through the venue owner (venues.gd `view`, main.gd's first camera line).
##   - The floor (one mesh, the actors' material): the asphalt, two grass islands, the painted ideal
##     line, the kick boxes (30 m before each bend), the crossovers' flick gates, the start and finish,
##     the zones' boards (ZONA) and cones (KLIP), the low wall round it.
##   - Change 4: the angle wedge painted under the car, turning with the course: green 25-50° on the
##     bend's side, a bright rim at 45-55°, red past 65° (one mesh, +1 draw call).
##   - Change 5: the angle in the ear (drift_car.gd's wheel speed and limiter) and in the hand
##     (`Access.buzz` ticks at BUZZ_HZ past BUZZ_DEG); the kit's cues for a bank, a loss, a zone.
##   - Change 6: the loop camera: the current loop's centre + LOOP_PULL × (car - centre), no lead,
##     sliding to the next loop over SLIDE_S s at the crossover's flick spot; the straights follow the
##     car. WIDOK Z GÓRY (TOP_PITCH, TOP_VIEW m) and back.
##   - Change 12: smoke from the outer rear wheel, one puff per PUFF_EVERY m of path, alpha SMOKE_A,
##     SMOKE_CAP puffs; skids.gd's marks along the path, 8,192 kept.
##   - PR 2 (2026-11-27), the Stadion Narodowy round the floor (drift_venue.gd builds it on the first
##     visit): the two tiers in red and white as a cutaway (the near quadrant keeps its lower tier), the
##     roof ring and the spire with its screen cube, the crowd (one MultiMesh, the tier's cap, phones at
##     night, a wave round the bowl on a bank or a zone), the LED ring and banners with parody sponsors
##     (drift_tracks.json `boards`), the islands with their stages, screens and flame jets (FLAME_* , a
##     pool fired by a zone), the track wall and tyre stacks along the loops (visual only).
##   - Light (change 14): the bowl, crowd and boards are unshaded (drift_venue.gdshader: no light, the
##     time of day from the city's globals); the floor and the cars, in the actors' lit material, get the
##     venue's own floodlight at night (a DirectionalLight3D with no shadow, FLOOD_* , on only inside); the
##     city's sun lights them by day. Only the cars cast shadows.
##   - Tiers (tiers.gd DRIFT, read on each run): smoke 64 / 40 / 24, crowd 1,500 / 900 / 400, flames.
## Flags (dev_flags.gd): --drift=osemka (straight in), --drift=osemka:bot (the decent bot drives, for
## shots and the run step), --drift=osemka:pose:H:B (the car stands posed at the first point of the
## line whose course is H° with B° of slip on the bend's side, the clock still: the wedge's shots),
## a last `:top` starts in WIDOK Z GÓRY (shots), `:wide` frames the whole bowl from the iso side (shots of
## the venue; with `:top` from above); --drift=0 (none). With any of them the run's lines are logged ("drift: ...").
## Add-ons: Beehave and Dialogue Manager not used (taps and a score; no NPC, no conversation).

const DriftLine := preload("res://scripts/drift_line.gd")
const DriftModel := preload("res://scripts/drift_model.gd")
const DriftScore := preload("res://scripts/drift_score.gd")
const DriftInput := preload("res://scripts/drift_input.gd")
const DriftBot := preload("res://scripts/drift_bot.gd")
const DriftCar := preload("res://scripts/drift_car.gd")
const DriftUi := preload("res://scripts/drift_ui.gd")
const Skids := preload("res://scripts/skids.gd")
const DriftVenue := preload("res://scripts/drift_venue.gd")
const Tiers := preload("res://scripts/tiers.gd")
const Models := preload("res://scripts/models.gd")
const UiKit := preload("res://scripts/ui_kit.gd")

const PLACE := Vector3(-9000.0, 0.0, -9000.0)
const TRACK := "osemka"
## The floor (m), centred on PLACE.
const FLOOR := Vector2(150.0, 90.0)
## The iso camera (0b.4): pitch, view (m), yaw; WIDOK Z GÓRY.
const ISO_PITCH := -40.0
const ISO_VIEW := 34.0
const YAW := 45.0
const TOP_PITCH := -85.0
const TOP_VIEW := 60.0
## The `:wide` shot camera (the whole bowl): pitch and view (m), from the iso side and from above.
const WIDE_PITCH := -30.0
const WIDE_VIEW := 150.0
const WIDE_TOP_VIEW := 200.0
## Change 6: the loop camera's pull towards the car and its slide between loops (s).
const LOOP_PULL := 0.35
const SLIDE_S := 1.2
## Change 5: the hand's ticks past BUZZ_DEG.
const BUZZ_DEG := 60.0
const BUZZ_HZ := 6.0
## Change 12: the smoke. SMOKE_CAP is the pool; the tier's cap (tiers.gd drift_smoke) uses its first N.
const SMOKE_CAP := 64
const SMOKE_A := 0.16
const SMOKE_LIFE := 1.2
const PUFF_EVERY := 1.0
const PUFF_FROM := 2.5
const PUFF_TO := 5.0
## Change 12: the marks kept.
const MARKS := 8192
## PR 2: the flame jets on a zone: each jet two instances (core and outer), FLAME_LIFE s, FLAME_H m high.
const FLAME_LIFE := 0.6
const FLAME_H := 5.0
## PR 2: the crowd's wave (drift_venue.gdshader WAVE_LIFE) and the venue's floodlight at night (change 14).
const WAVE_LIFE := 2.4
const FLOOD_ENERGY := 0.85
const FLOOD_COLOUR := Color("#fff1dc")
## A run gives up after this (s, 0b.2).
const RUN_LIMIT := 45.0
## The wedge (change 4): its radii (m) and bands (°).
const WEDGE_R0 := 2.3
const WEDGE_R1 := 6.0
## The floor's colours and their night glow (the actors' HERO part's UV.y).
const ASPHALT := Color("#3b3d42")
const GRASS := Color("#4f7d3c")
const PAINT := Color("#ece6d6")
const KICK := Color("#e0b63a")
const GATE := Color("#5fd4ff")
## The speed the floor's flick band is painted for (m/s, the follower's on the crossovers).
const GATE_V := 13.0
const BOARD_RED := Color("#d23a35")
const BOARD_WHITE := Color("#f1ede4")
const CONE := Color("#ff8a2a")
const WEDGE_GREEN := Color("#3fcf73")
const WEDGE_RIM := Color("#e8ff7a")
const WEDGE_RED := Color("#ff4f5e")
const GLOW_FLOOR := 0.35
const GLOW_PAINT := 0.9

var sfx: Node
var cam: Camera3D
var world_node: Node3D
var line: RefCounted
var st: DriftModel.State
var score: DriftScore.Score
var thumb := DriftInput.new()
var params: Dictionary = DriftModel.params()
var top := false
var best := 0
var runs := 0

var _flag := ""
var _bot: RefCounted
var _pose := Vector2.INF
var _built := false
var _inside := false
var _root: Node3D
var _floor: MeshInstance3D
var _wedge: MeshInstance3D
var _wedge_meshes: Array[ArrayMesh] = []
var _smoke: MultiMeshInstance3D
var _smoke_t: Array[float] = []
var _smoke_at: Array[Vector3] = []
var _smoke_next := 0
var _smoke_cap := SMOKE_CAP
var _bowl: MeshInstance3D
var _spire: MeshInstance3D
var _crowd: MultiMeshInstance3D
var _crowd_mat: ShaderMaterial
var _flames: MultiMeshInstance3D
var _flame_spots: Array[Vector3] = []
var _flame_t: Array[float] = []
var _flame_cap := 16
var _wave_t := 99.0
var _flood: DirectionalLight3D
var _tod: Node
var _wide := false
var _puff_s := 0.0
var _skids: Node
var _car: DriftCar
var _player_car: Node3D
var _sfx_car: Node
var _hud_was := true
var _ui_layer: CanvasLayer
var _ui: DriftUi
var _clock := 0.0
var _over := false
var _buzz_t := 0.0
var _cam_anchor := Vector2.INF
var _cam_from := Vector3.INF
var _cam_slide := SLIDE_S
var _cam_last := Vector3.INF
var _frame_noted := false
var _fr := DriftModel.Frame.new()


func install(ctx: GameCtx) -> bool:
	_flag = str(ctx.flags.drift_flag) if "drift_flag" in ctx.flags else ""
	if _flag == "0" or str(ctx.flags.solo_site) != "":
		return false
	super(ctx)
	name = "DriftStadium"
	tag = "drift"
	colour = UiKit.GO
	dark = UiKit.CARD_SOLID
	rescue_calls = RescueCalls.HOLD
	log_on = _flag != ""
	autopilot = ctx.flags.autopilot
	vehicle = ctx.vehicle
	clock = ctx.hour
	sfx = ctx.sfx
	_tod = ctx.tod
	_player_car = ctx.car
	world_node = ctx.world
	return true


func setup(world: Node3D) -> void:
	super.setup(world)
	line = DriftLine.load_track(TRACK)
	var panel: Variant = hud.get("settings_panel")
	if panel is Control and (panel as Control).has_signal("changed"):
		(panel as Control).connect("changed", func(key: String, _v: Variant) -> void:
			if key == "drift":
				_ask_in.call_deferred())


## The DEV page's BOKIEM: in only when the director says the player is free (its `free_now`: no other
## activity on, nothing of main.gd's `_free_block`); refused with a toast saying why (the PR review).
## Not from the air: the helicopter has no stadium car to swap with.
func _ask_in() -> void:
	if phase != Phase.IDLE:
		return
	var why := ""
	if vehicle.is_valid() and bool(vehicle.call()[2]):
		why = "air"
	elif not free_now.call():
		why = "busy"
	if why != "":
		var words := DriftLine.word(why)
		hud.toast(str(words[0]), str(words[1]))
		_log("refused: " + why)
		return
	start()


func joined(ctx: GameCtx) -> void:
	cam = ctx.world.get_viewport().get_camera_3d() if ctx.world != null else null
	var parts := _flag.split(":")
	if parts.is_empty() or parts[0] != TRACK:
		return
	if parts.size() >= 2 and parts[1] == "bot":
		_bot = DriftBot.make("decent", 1)
	if parts.size() >= 4 and parts[1] == "pose":
		_pose = Vector2(float(parts[2]), float(parts[3]))
	if parts[parts.size() - 1] == "top":
		top = true  # WIDOK Z GÓRY from the start (shots)
	_wide = parts.has("wide")  # the whole bowl (shots of the venue)
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if phase == Phase.IDLE:
			start())


## No call: the DEV page or the flag starts it.
func _idle_tick(_dt: float) -> void:
	pass


# --- the visit ---------------------------------------------------------------------------------

func _begin() -> void:
	if not _built:
		_build()
	_inside = true
	_hud_was = hud.visible
	hud.visible = false
	if _player_car != null:
		_player_car.set("vel", Vector3.ZERO)
		_player_car.set("forward_speed", 0.0)
		_player_car.set("slip", 0.0)
		_player_car.process_mode = Node.PROCESS_MODE_DISABLED
		_car.set_model(str(_player_car.get("model")) if str(_player_car.get("model")) == "tt" else "hatch")
		var p: Variant = _player_car.get("paint")
		var s: Variant = _player_car.get("stripe")
		if p is Color and s is Color:
			_car.set_paint(p, s)
	if sfx != null:
		_sfx_car = sfx.get("car")
		sfx.set("car", _car)
	if cam == null and world_node != null and world_node.is_inside_tree():
		cam = world_node.get_viewport().get_camera_3d()
	_root.visible = true
	_skids.visible = true
	_flood.visible = true
	_ui_layer.visible = true
	_set_awake(true)
	_new_run()
	_ui.show_tips()
	_log("in: %s, %.0f m, %d zones, %d flick spots" % [line.key, line.length, line.zones.size(), line.flips.size()])


func _ended() -> void:
	_inside = false
	if _root != null:
		_root.visible = false
		_skids.visible = false
		_flood.visible = false
	if _ui_layer != null:
		_ui_layer.visible = false
	_set_awake(false)
	hud.visible = _hud_was
	if sfx != null and _sfx_car != null:
		sfx.set("car", _sfx_car)
	if _player_car != null:
		_player_car.process_mode = Node.PROCESS_MODE_INHERIT
	_log("out: %d runs, best %d" % [runs, best])


## The stadium's nodes process only on a visit (the PR review: after one visit the car, the marks and
## the UI kept running in the city); the hidden HUD takes no touch meanwhile (hud.gd `away`).
func _set_awake(on: bool) -> void:
	var mode := Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	for n: Node in [_root, _skids, _ui_layer]:
		if n != null:
			n.process_mode = mode
	hud.set("away", on)


## The ✕ is the stadium's own (the city's HUD is hidden).
func _can_abort() -> bool:
	return false


func grounded() -> Array:
	return DriftLine.word("grounded") if phase == Phase.RUN else []


func stop_spot() -> Vector3:
	return Vector3.INF


## The player is on the stadium's floor (venues.gd).
func inside() -> bool:
	return _inside and phase == Phase.RUN


func _new_run() -> void:
	st = DriftModel.State.new()
	score = DriftScore.Score.new()
	thumb.reset()
	_clock = 0.0
	_over = false
	_puff_s = 0.0
	_cam_anchor = Vector2.INF
	_cam_from = Vector3.INF
	_cam_slide = SLIDE_S
	if _bot != null:
		_bot = DriftBot.make("decent", runs + 1)
	if _pose != Vector2.INF:
		_place_pose(_pose.x, _pose.y)
	_car.state = st
	_ui.hide_result()
	_apply_tiers()
	hud.cue("go")


## The pose for the wedge's shots: the first line point whose course is `heading`° (mod 360) on a bend,
## with `slip`° on the bend's side.
func _place_pose(heading: float, slip: float) -> void:
	var s := 0.0
	var best_d := INF
	var best_s := 0.0
	while s < line.length:
		if absf(float(line.kappa_at(s))) > 0.0:
			var d := absf(wrapf(rad_to_deg(float(line.yaw_at(s))) - heading, -180.0, 180.0))
			if d < best_d - 0.01:
				best_d = d
				best_s = s
		s += 0.5
	st.s = best_s
	st.v = 15.0
	st.gas = 1.0
	st.mode = DriftModel.Mode.DRIFT
	st.beta = slip * float(line.bend_sign(best_s))
	_log("pose: s %.1f, course %.0f°, slip %.0f°" % [best_s, rad_to_deg(float(line.yaw_at(best_s))), st.beta])


func _retry() -> void:
	if inside():
		_new_run()


func _leave() -> void:
	if phase == Phase.RUN:
		finish()


func _toggle_top() -> void:
	top = not top
	_ui.set_top(top)
	_cam_from = Vector3.INF


# --- the frame ---------------------------------------------------------------------------------

func _physics_process(dt: float) -> void:
	if not inside() or st == null:
		return
	if _pose != Vector2.INF or _over:
		return
	_clock += dt
	if _bot != null:
		_bot.tick(_clock, st, line, thumb)
	_fr.gas = thumb.gas()
	_fr.kick = thumb.take_kick()
	_fr.chain = score.chain
	DriftModel.step(st, _fr, line, params, dt)
	DriftScore.tick(score, st, line, dt)
	for e in st.events:
		if e == "kick":
			Access.buzz(15, 0.35)
			for k in 3:
				_puff(_wheel_point())
	for said in score.said:
		_on_said(said)
	if st.mode == DriftModel.Mode.DRIFT and absf(st.beta) > BUZZ_DEG:
		_buzz_t += dt
		if _buzz_t >= 1.0 / BUZZ_HZ:
			_buzz_t = 0.0
			Access.buzz(10, 0.2)
	else:
		_buzz_t = 0.0
	if not st.finished and _clock >= RUN_LIMIT:
		score.said.clear()  # this step's words are said above; the bank's alone now
		DriftScore.bank(score)
		for said in score.said:
			_on_said(said)
		_end_run()
	elif st.finished:
		_end_run()


func _on_said(said: String) -> void:
	var what := said.get_slice(":", 0)
	match what:
		"bank":
			_ui.flash("bank", "+" + DriftUi.num(int(said.get_slice(":", 1))), UiKit.GO)
			_wave()
			hud.cue("checkpoint")
			Access.buzz(20, 0.5)
			get_tree().create_timer(0.09).timeout.connect(func() -> void: Access.buzz(20, 0.5))
		"lost":
			_ui.flash("lost", DriftUi.num(int(said.get_slice(":", 1))), UiKit.ALERT)
			hud.cue("fail")
			Access.buzz(60, 1.0)
		"zona", "klip":
			_ui.flash(what)
			hud.cue("ping")
			Access.buzz(30, 0.6)
			if what == "zona":
				_fire_flames()
				_wave()
		"flick", "perfect":
			_ui.flash(what)
			hud.cue("step")
		"wrong", "slow":
			_ui.flash(what, "", UiKit.ALERT)
		"spin":
			_ui.flash("spin", "", UiKit.ALERT)
	_log(said)


func _end_run() -> void:
	_over = true
	# The car rolls to a stop under the card: no slide, no smoke, the engine back to idle (the review).
	st.v = 0.0
	st.beta = 0.0
	st.gas = 0.0
	st.mode = DriftModel.Mode.GRIP
	runs += 1
	var total := roundi(score.total)
	best = maxi(best, total)
	_ui.show_result(total, score.cards, best)
	hud.cue("win")
	_log("run over: total %d (linia %d, kat %d, styl %d), %.1f s, %d spins, %d flicks, %d banks, %d zones%s" % [total,
			roundi(score.cards["linia"]), roundi(score.cards["kat"]), roundi(score.cards["styl"]), _clock, score.spins,
			score.flicks, score.banks, score.zones_done.size(), ", bot" if _bot != null else ""])


func _process(dt: float) -> void:
	super(dt)
	if not inside() or st == null:
		return
	_frame_visuals(dt)
	if log_on and not _frame_noted and _clock > 6.0:
		_frame_noted = true
		_log("frame: %d draw calls, %d objects, %d primitives, %d puffs alive, %d marks · %s: smoke cap %d, crowd %d, flames %d" % [int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
				_smoke_t.filter(func(x: float) -> bool: return x < SMOKE_LIFE).size(), (_skids as MultiMeshInstance3D).multimesh.visible_instance_count,
				Tiers.NAMES[Tiers.level], _smoke_cap, _crowd.multimesh.visible_instance_count, _flame_cap])


func _frame_visuals(dt: float) -> void:
	var at := _car.get_global_transform_interpolated().origin
	# The wedge: under the car, along the course, on the side the slip belongs on.
	var side: int = line.bend_sign(st.s)
	var show: bool = side != 0 and (st.mode != DriftModel.Mode.GRIP or line.bend_ahead(st.s) != 0)
	_wedge.visible = show
	if show:
		_wedge.mesh = _wedge_meshes[0 if side > 0 else 1]
		_wedge.global_transform = Transform3D(Basis(Vector3.UP, float(line.yaw_at(st.s))), Vector3(at.x, PLACE.y + 0.035, at.z))
	# Smoke from the outer rear wheel, one puff a metre while it slides.
	var sliding := not _over and _pose == Vector2.INF and st.mode in [DriftModel.Mode.DRIFT, DriftModel.Mode.FLIP, DriftModel.Mode.SPIN] and absf(st.beta) > 12.0
	if sliding:
		_puff_s += st.v * dt
		if _puff_s >= PUFF_EVERY:
			_puff_s = 0.0
			_puff(_wheel_point())
	_smoke_frame(dt)
	_venue_frame(dt)
	# The UI's numbers and the pile over the car.
	_ui.total = roundi(score.total)
	_ui.best = best
	_ui.pile = roundi(score.pile)
	_ui.chain = score.chain
	_ui.clock = _clock
	_ui.pile_at = _project(at + Vector3(0.0, 1.5, 0.0))
	# The flick cue: while drifting towards a sign change (not once flicked, not posed).
	_ui.car_at = _project(at)
	_ui.cue_dt = float(line.flip_dt(st.s, st.v)) if st.mode == DriftModel.Mode.DRIFT and not _over else INF
	_ui.cue_before = float(params.get("flick_before", DriftModel.FLICK_BEFORE))
	_ui.cue_after = float(params.get("flick_after", DriftModel.FLICK_AFTER))
	_ui.cue_perfect = DriftModel.FLICK_PERFECT
	_ui.arc_beta = st.beta
	_ui.arc_side = side if st.mode != DriftModel.Mode.GRIP else 0


func _wheel_point() -> Vector3:
	var side := signf(st.beta) if st.beta != 0.0 else 1.0
	return _car.global_transform * Vector3(0.78 * side, 0.4, 1.3)


func _puff(at: Vector3) -> void:
	_smoke_t[_smoke_next] = 0.0
	_smoke_at[_smoke_next] = at
	_smoke_next = (_smoke_next + 1) % _smoke_cap


## The tiers (tiers.gd DRIFT at the level main.gd applies): the smoke's pool, the crowd, the flames.
func _apply_tiers() -> void:
	_smoke_cap = clampi(int(Tiers.value(Tiers.level, "drift_smoke", Tiers.DRIFT["drift_smoke"])), 1, SMOKE_CAP)
	_smoke_next = _smoke_next % _smoke_cap
	var mm := _crowd.multimesh
	mm.visible_instance_count = mini(int(Tiers.value(Tiers.level, "drift_crowd", Tiers.DRIFT["drift_crowd"])), mm.instance_count)
	_flame_cap = clampi(int(Tiers.value(Tiers.level, "drift_flames", Tiers.DRIFT["drift_flames"])), 0, _flames.multimesh.instance_count)


## A zone: the jets on the island nearest the car fire for FLAME_LIFE s (as many as the tier's cap allows).
func _fire_flames() -> void:
	var at := _car.global_position - PLACE
	var best_d := INF
	var best_i := 0
	for i in _flame_spots.size():
		var d := Vector2(_flame_spots[i].x, _flame_spots[i].z).distance_to(Vector2(at.x, at.z))
		if d < best_d:
			best_d = d
			best_i = i
	var per := DriftVenue.FLAMES_PER_ISLAND
	var first := best_i - best_i % per
	# Two instances a jet: Low's cap of 4 fires two of the island's jets.
	for k in mini(per, _flame_cap >> 1):
		_flame_t[first + k] = 0.0
	_flames.visible = _flame_cap > 0


## A bank or a zone: the crowd's wave starts at the car's side of the bowl.
func _wave() -> void:
	var at := _car.global_position - PLACE
	_wave_t = 0.0
	_crowd_mat.set_shader_parameter("wave_from", atan2(at.z, at.x))


## The venue's frame: the flames' pool, the wave's clock, the floodlight by the time of day.
func _venue_frame(dt: float) -> void:
	if _wave_t < WAVE_LIFE:
		_wave_t += dt
		_crowd_mat.set_shader_parameter("wave_age", _wave_t)
	if _flames.visible:
		var mm := _flames.multimesh
		var alive := false
		for i in _flame_spots.size():
			var t := _flame_t[i]
			var on := t < FLAME_LIFE
			if on:
				_flame_t[i] = t + dt
				alive = true
			var k := clampf(t / 0.08, 0.0, 1.0) * clampf((FLAME_LIFE - t) / 0.15, 0.0, 1.0) if on else 0.0
			var flick := 0.85 + 0.15 * sin(t * 60.0 + i)
			var p := _flame_spots[i]
			for layer in 2:
				var h := FLAME_H * k * flick * (1.0 if layer == 0 else 0.6)
				var w := (2.2 if layer == 0 else 1.2) * maxf(k, 0.01)
				mm.set_instance_transform(i * 2 + layer, Transform3D(Basis().scaled(Vector3(w, maxf(h, 0.01), w)), p))
		_flames.visible = alive
	if _tod != null:
		var night := 1.0 - clampf(float(_tod.get("daylight")), 0.0, 1.0)
		_flood.light_energy = FLOOD_ENERGY * night
		_flood.visible = _inside and night > 0.02


func _smoke_frame(dt: float) -> void:
	var mm := _smoke.multimesh
	var a := SMOKE_A * (0.0 if Access.calm else 1.0)
	for i in SMOKE_CAP:
		if _smoke_t[i] >= SMOKE_LIFE:
			continue
		_smoke_t[i] += dt
		var k := minf(_smoke_t[i] / SMOKE_LIFE, 1.0)
		var sc := lerpf(PUFF_FROM, PUFF_TO, k)
		var p: Vector3 = _smoke_at[i] + Vector3(0.0, 1.0 * k, 0.0) - PLACE
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(sc, sc * 0.7, sc)), p))
		mm.set_instance_color(i, Color(1, 1, 1, a * (1.0 - k)))


## A floor point on the root viewport (the city image is scaled up to it, as THE TAPCZAN's UI).
func _project(p: Vector3) -> Vector2:
	if cam == null or not cam.is_inside_tree() or cam.is_position_behind(p):
		return Vector2(-1000, -1000)
	var k := 1.0
	var root := get_tree().root
	var own := cam.get_viewport()
	if own != root:
		k = float(root.get_visible_rect().size.y) / maxf(1.0, float(own.get_visible_rect().size.y))
	return cam.unproject_position(p) * k


# --- the camera (venues.gd asks) -----------------------------------------------------------------

## Change 6: the loop camera; WIDOK Z GÓRY. True: placed.
func view(c: Camera3D, _pitch: float, dt: float) -> bool:
	if not inside() or _car == null:
		return false
	var car_at := _car.get_global_transform_interpolated().origin
	var centre: Vector2 = line.loop_centre(st.s)
	var raw := car_at
	if centre != Vector2.INF:
		var cw := PLACE + Vector3(centre.x, 0.0, centre.y)
		raw = cw + (car_at - cw) * LOOP_PULL
	raw.y = PLACE.y
	if centre != _cam_anchor:
		_cam_anchor = centre
		_cam_from = _cam_last if _cam_last != Vector3.INF else raw
		_cam_slide = 0.0
	_cam_slide = minf(_cam_slide + dt, SLIDE_S)
	var target := raw
	if _cam_from != Vector3.INF:
		target = _cam_from.lerp(raw, smoothstep(0.0, 1.0, _cam_slide / SLIDE_S))
	_cam_last = target
	var b := Basis.from_euler(Vector3(deg_to_rad(TOP_PITCH if top else ISO_PITCH), deg_to_rad(YAW), 0.0))
	c.size = TOP_VIEW if top else ISO_VIEW
	if _wide:
		b = Basis.from_euler(Vector3(deg_to_rad(TOP_PITCH if top else WIDE_PITCH), deg_to_rad(YAW), 0.0))
		c.size = WIDE_TOP_VIEW if top else WIDE_VIEW
		target = PLACE + Vector3(0.0, 10.0, 0.0)
	c.global_transform = Transform3D(b, target + b.z * (260.0 if _wide else 120.0))
	c.far = 600.0 if _wide else 300.0
	# WIDOK Z GÓRY: the spire's cube would hang over the crossover.
	_spire.visible = _wide or not top
	return true


# --- touches -------------------------------------------------------------------------------------

## The thumb's edges from the UI (drift_ui.gd reads the pad on the root viewport): down is gas,
## tap-tap kicks (drift_input.gd). None while the bot drives, the car is posed or the run is over.
func _thumb(down: bool, index: int) -> void:
	if not inside() or _over or _pose != Vector2.INF or _bot != null:
		return
	if down:
		thumb.press(_clock, index)
	else:
		thumb.release(_clock, index)


# --- the build (on the first visit) --------------------------------------------------------------

func _build() -> void:
	_built = true
	_root = Node3D.new()
	_root.name = "DriftFloor"
	_root.position = PLACE
	add_child(_root)
	_floor = MeshInstance3D.new()
	_floor.name = "Floor"
	_floor.mesh = floor_mesh(line)
	_floor.material_override = Models.material()
	_floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # only the cars cast (0b.4)
	_root.add_child(_floor)
	_build_venue()
	_wedge_meshes = [wedge_mesh(1), wedge_mesh(-1)]
	_wedge = MeshInstance3D.new()
	_wedge.name = "Wedge"
	_wedge.mesh = _wedge_meshes[0]
	_wedge.material_override = Models.material()
	_wedge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_wedge.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_root.add_child(_wedge)
	_car = DriftCar.new()
	_car.name = "DriftCar"
	_car.line = line
	_car.origin = PLACE
	_car.floor_y = PLACE.y
	_root.add_child(_car)
	_skids = Skids.new()
	_skids.name = "DriftMarks"
	_skids.car = _car
	_skids.max_marks = MARKS
	_skids.along_velocity = true
	_skids.ground_height = func(_x: float, _z: float) -> float: return PLACE.y
	_skids.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ctx_mat: Variant = _ground_mat()
	if ctx_mat is Material:
		_skids.material_override = ctx_mat
	# The marks are stamped in world coordinates: the node sits at the world's origin, not under _root.
	add_child(_skids)
	_skids.visible = false
	_build_smoke()
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "DriftUiLayer"
	_ui_layer.layer = 20
	var parent: Node = hud.get_parent() if hud != null and hud.get_parent() != null else self
	parent.add_child(_ui_layer)
	_ui = DriftUi.new()
	_ui.name = "DriftUi"
	_ui_layer.add_child(_ui)
	_ui.build(float(hud.get("pt")) if hud.get("pt") != null else 1.0)
	_ui.top_pressed.connect(_toggle_top)
	_ui.retry_pressed.connect(_retry)
	_ui.leave_pressed.connect(_leave)
	_ui.thumb.connect(_thumb)
	_ui.set_top(top)
	_root.visible = false
	_ui_layer.visible = false


## PR 2: the Stadion Narodowy round the floor (drift_venue.gd): the bowl and the spire in the venue's
## unshaded material, the crowd, the flame jets' pool, the floodlight. Nothing of it casts a shadow.
func _build_venue() -> void:
	var tex := DriftVenue.atlas()
	var mat := DriftVenue.material(tex, false)
	_bowl = MeshInstance3D.new()
	_bowl.name = "Bowl"
	_bowl.mesh = DriftVenue.bowl_mesh(line)
	_bowl.material_override = mat
	_bowl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(_bowl)
	_spire = MeshInstance3D.new()
	_spire.name = "Spire"
	_spire.mesh = DriftVenue.spire_mesh()
	_spire.material_override = mat
	_spire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(_spire)
	_crowd_mat = DriftVenue.material(tex, true)
	_crowd = MultiMeshInstance3D.new()
	_crowd.name = "Crowd"
	_crowd.multimesh = DriftVenue.crowd(int(Tiers.DRIFT["drift_crowd"]))
	_crowd.material_override = _crowd_mat
	_crowd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(_crowd)
	_flame_spots = DriftVenue.flame_spots(line)
	_flame_t.resize(_flame_spots.size())
	_flame_t.fill(99.0)
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA  # mixed, not added: a lit floor washed added flames white
	fmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fmat.vertex_color_use_as_albedo = true
	fmat.render_priority = 1  # after the post-process quad, as the smoke
	var fm := MultiMesh.new()
	fm.transform_format = MultiMesh.TRANSFORM_3D
	fm.mesh = DriftVenue.flame_mesh()
	fm.instance_count = _flame_spots.size() * 2
	for i in fm.instance_count:
		fm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.01), _flame_spots[i >> 1]))
	fm.custom_aabb = AABB(Vector3(-FLOOR.x * 0.5, 0.0, -FLOOR.y * 0.5), Vector3(FLOOR.x, 8.0, FLOOR.y))
	_flames = MultiMeshInstance3D.new()
	_flames.name = "Flames"
	_flames.multimesh = fm
	_flames.material_override = fmat
	_flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flames.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_flames.visible = false
	_root.add_child(_flames)
	# Change 14: the floodlight from the roof for the lit floor and cars, at night, inside only; no shadow.
	_flood = DirectionalLight3D.new()
	_flood.name = "Floodlight"
	_flood.light_color = FLOOD_COLOUR
	_flood.light_energy = 0.0
	_flood.shadow_enabled = false
	_flood.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_flood.rotation = Vector3(deg_to_rad(-62.0), deg_to_rad(20.0), 0.0)
	_flood.visible = false
	add_child(_flood)
	_apply_tiers()


## The marks' material: the actors' (dark vertex colour, lit like the floor).
func _ground_mat() -> Material:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	# Lit by the day sun the marks' vertex colour reads lighter than the floor's shader: darkened.
	m.albedo_color = Color(0.45, 0.45, 0.45)
	m.roughness = 0.9
	return m


func _build_smoke() -> void:
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.vertex_color_use_as_albedo = true
	smat.albedo_color = Color(0.88, 0.88, 0.9, 1.0)
	# After the post-process quad, which repaints the screen from a copy taken before the
	# transparent pass (beacon.gd, heli.gd): at the default priority the puffs are painted over.
	smat.render_priority = 1
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 8
	puff.rings = 4
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = puff
	mm.instance_count = SMOKE_CAP
	# The puffs move every frame: a fixed box over the floor, so a stale bound never culls them.
	mm.custom_aabb = AABB(Vector3(-FLOOR.x * 0.5, -2.0, -FLOOR.y * 0.5), Vector3(FLOOR.x, 12.0, FLOOR.y))
	_smoke = MultiMeshInstance3D.new()
	_smoke.name = "Smoke"
	_smoke.multimesh = mm
	_smoke.material_override = smat
	_smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_smoke.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_root.add_child(_smoke)
	_smoke_t.resize(SMOKE_CAP)
	_smoke_t.fill(99.0)
	_smoke_at.resize(SMOKE_CAP)
	for i in SMOKE_CAP:
		mm.set_instance_color(i, Color(1, 1, 1, 0))
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.01), Vector3(0, -50, 0)))


# --- meshes (static: check_drift builds them with no scene) --------------------------------------

## One face of a quad, wound so it faces `n` (Godot's front faces are clockwise).
static func _quad(st: SurfaceTool, q: Array, n: Vector3, colour: Color, glow: float) -> void:
	var pts := q.duplicate()
	if ((pts[1] as Vector3) - (pts[0] as Vector3)).cross((pts[2] as Vector3) - (pts[0] as Vector3)).dot(n) > 0.0:
		pts = [pts[0], pts[3], pts[2], pts[1]]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_color(colour)
		st.set_normal(n)
		st.set_uv(Vector2(Models.HERO, glow))
		st.add_vertex(pts[k])


## A box turned by `yaw` about its centre (the boards along a bend).
static func _box(st: SurfaceTool, c: Vector3, size: Vector3, yaw_r: float, colour: Color, glow: float) -> void:
	var b := Basis(Vector3.UP, yaw_r)
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			if axis == 1 and sgn < 0.0:
				continue  # no bottom
			var m := n * h[axis]
			_quad(st, [c + b * (m - u - v), c + b * (m + u - v), c + b * (m + u + v), c + b * (m - u + v)], b * n, colour, glow)


## A flat strip along the line from s0 to s1 between lateral offsets a and b (m, + left), at height y.
static func _strip(st: SurfaceTool, ln: RefCounted, s0: float, s1: float, a: float, b: float, y: float, colour: Color, glow: float) -> void:
	var s := s0
	while s < s1 - 0.01:
		var s2 := minf(s + 1.0, s1)
		var p0: Vector2 = ln.at(s)
		var p1: Vector2 = ln.at(s2)
		var l0: Vector2 = DriftLine.left(float(ln.yaw_at(s)))
		var l1: Vector2 = DriftLine.left(float(ln.yaw_at(s2)))
		var q := [p0 + l0 * a, p0 + l0 * b, p1 + l1 * b, p1 + l1 * a]
		_quad(st, [Vector3(q[0].x, y, q[0].y), Vector3(q[1].x, y, q[1].y), Vector3(q[2].x, y, q[2].y), Vector3(q[3].x, y, q[3].y)],
				Vector3.UP, colour, glow)
		s = s2


## The floor in the stadium's own coordinates (PLACE is its 0): one mesh, one draw call.
static func floor_mesh(ln: RefCounted) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := FLOOR.x * 0.5
	var hz := FLOOR.y * 0.5
	_quad(st, [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)], Vector3.UP, ASPHALT, GLOW_FLOOR)
	# Grass islands (ellipses).
	for isl: Array in ln.islands:
		var c := Vector3(float(isl[0]), 0.01, float(isl[1]))
		var n := 28
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var e0 := c + Vector3(cos(a0) * float(isl[2]), 0, sin(a0) * float(isl[3]))
			var e1 := c + Vector3(cos(a1) * float(isl[2]), 0, sin(a1) * float(isl[3]))
			_quad(st, [c, e0, e1, c.lerp(e1, 0.001)], Vector3.UP, GRASS, GLOW_FLOOR)
	# The kick boxes: a tinted band 30 m before each bend, with bright edges.
	for kb: Vector2 in ln.kick_boxes:
		_strip(st, ln, kb.x, kb.y, -2.4, 2.4, 0.006, ASPHALT.lerp(KICK, 0.28), GLOW_FLOOR)
		_strip(st, ln, kb.x, kb.y, 2.25, 2.45, 0.008, KICK, GLOW_PAINT)
		_strip(st, ln, kb.x, kb.y, -2.45, -2.25, 0.008, KICK, GLOW_PAINT)
	# The ideal line.
	_strip(st, ln, 0.0, ln.length, -0.13, 0.13, 0.012, PAINT, GLOW_PAINT)
	# The flick gates (change 9): a bar across the line at each sign change, on a tinted band where the
	# window is open at the follower's 13 m/s (FLICK_BEFORE s before it, FLICK_AFTER s after).
	for f in ln.flips:
		_strip(st, ln, f - DriftModel.FLICK_BEFORE * GATE_V, f + DriftModel.FLICK_AFTER * GATE_V, -3.2, 3.2, 0.010, ASPHALT.lerp(GATE, 0.3), GLOW_FLOOR)
		for e in [-1.0, 1.0]:
			_strip(st, ln, f - DriftModel.FLICK_BEFORE * GATE_V, f + DriftModel.FLICK_AFTER * GATE_V, 3.05 * e - 0.1, 3.05 * e + 0.1, 0.012, GATE, GLOW_PAINT)
		_strip(st, ln, f - 0.35, f + 0.35, -3.2, 3.2, 0.014, GATE, GLOW_PAINT)
	# Start and finish: a checker across the line.
	for s0 in [0.4, ln.length - 1.4]:
		for i in 8:
			for j in 2:
				var col := PAINT if (i + j) % 2 == 0 else ASPHALT.darkened(0.4)
				_strip(st, ln, s0 + j * 0.5, s0 + j * 0.5 + 0.5, -3.2 + i * 0.8, -3.2 + (i + 1) * 0.8, 0.016, col, GLOW_PAINT)
	# The zones: ZONA boards (red and white, 2 m panels) and KLIP cones.
	for z: Dictionary in ln.zones:
		var pts: PackedVector2Array = z["points"]
		if z["kind"] == "zona":
			for i in pts.size() - 1:
				if i % 2 == 1:
					continue
				var a := pts[i]
				var b := pts[mini(i + 2, pts.size() - 1)]
				var mid := (a + b) * 0.5
				var yaw_r := atan2(-(b - a).x, -(b - a).y)
				_box(st, Vector3(mid.x, 0.35, mid.y), Vector3(0.3, 0.7, a.distance_to(b)), yaw_r,
						BOARD_RED if (i >> 1) % 2 == 0 else BOARD_WHITE, GLOW_PAINT)
		else:
			for i in range(0, pts.size(), 2):
				var p := pts[i]
				_box(st, Vector3(p.x, 0.3, p.y), Vector3(0.4, 0.6, 0.4), 0.0, CONE, GLOW_PAINT)
				_box(st, Vector3(p.x, 0.62, p.y), Vector3(0.26, 0.06, 0.26), 0.0, BOARD_WHITE, GLOW_PAINT)
	# PR 2: the apron to the stands, the track wall, tyres, kerbs, stages and flame posts (drift_venue.gd).
	DriftVenue.dress(st, ln, GLOW_FLOOR)
	st.index()
	return st.commit()


## Change 4's wedge for a bend on `side` (+1 left, -1 right): its apex at the car, 0° along the course.
static func wedge_mesh(side: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bands := [[25.0, 50.0, WEDGE_R0, WEDGE_R1, WEDGE_GREEN, 0.0], [45.0, 55.0, WEDGE_R1 - 0.55, WEDGE_R1 + 0.35, WEDGE_RIM, 0.004],
			[65.0, 80.0, WEDGE_R0, WEDGE_R1, WEDGE_RED, 0.0]]
	for band: Array in bands:
		var a0: float = band[0]
		var a1: float = band[1]
		var steps := maxi(2, int((a1 - a0) / 5.0))
		for i in steps:
			var b0 := deg_to_rad(lerpf(a0, a1, float(i) / steps)) * side
			var b1 := deg_to_rad(lerpf(a0, a1, float(i + 1) / steps)) * side
			var d0 := Vector3(-sin(b0), 0.0, -cos(b0))
			var d1 := Vector3(-sin(b1), 0.0, -cos(b1))
			var y: float = band[5]
			var r0: float = band[2]
			var r1: float = band[3]
			_quad(st, [d0 * r0 + Vector3(0, y, 0), d0 * r1 + Vector3(0, y, 0), d1 * r1 + Vector3(0, y, 0), d1 * r0 + Vector3(0, y, 0)],
					Vector3.UP, band[4], GLOW_PAINT)
	st.index()
	return st.commit()
