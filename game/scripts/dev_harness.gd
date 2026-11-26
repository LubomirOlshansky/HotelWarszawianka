## The test-only functions of a debug run (TD-4 a2): the bench's frame, the soak and the passes,
## the cam, ram, water, tram, teleport and quest-quit tests, the line-up, the contact log, --clicks,
## the shots and --stops, and the --egg rigs. main.gd loads this script only when one of those test
## flags is on (`flags.wants_harness()`; never in a release build) and calls it from the same places as
## before, always behind `harness != null`. Main's own state is reached as `m.NAME`.
## Made by td4a2-codemod 3 from main.gd; `check_dev_flags.gd` (verify step `devflags`) holds the rules.
extends RefCounted

const Main := preload("res://scripts/main.gd")
const Heli := preload("res://scripts/heli.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Trams := preload("res://scripts/trams.gd")
const Rivals := preload("res://scripts/rivals.gd")
const Models := preload("res://scripts/models.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const Sfx := preload("res://scripts/sfx.gd")
const Crowds := preload("res://scripts/crowds.gd")
const Weather := preload("res://scripts/weather.gd")
const Controls := preload("res://scripts/drive_controls.gd")
const FollowCamera := preload("res://scripts/follow_camera.gd")
const Settings := preload("res://scripts/settings.gd")
const SectorStreamer := preload("res://scripts/sector_streamer.gd")

## The game (main.gd).
var m: Main

## The result is out (on iOS the app doesn't stop at once after quit()).
var _bench_done := false
var _spot_i := 0
## --push-parked: the shot's push was made (once); --smash-fence: the smashes made so far.
var _push_parked_done := false
var _smash_done := 0
var _sweep_i := 0
var _rig_path := PackedVector2Array()
var _rig_s := 0.0
var _contact_names := PackedStringArray()
var _meters := {"Master": 0.0, "Music": 0.0, "SFX": 0.0, "Ambience": 0.0}
var _meter_top := {"Master": -200.0, "Music": -200.0, "SFX": -200.0, "Ambience": -200.0}
var _ram_driver: RefCounted
var _ram_t := 0.0
var _ram_hit := -1.0
var _ram_unsticks := 0
var _ram_dir := Vector3.ZERO
var _tram_watch_at := Vector2.INF
var _cam_t := 0.0
var _cam_phase := 0
var _cam_phase_t := 0.0
var _cam_aim := 0.0
var _cam_last_yaw := INF
var _cam_turn_max := 0.0
var _stop_at := 0
var _stop_busy := false
## --spots: the frame the current spot's shot frames count from.
var _spot_base := 0
var _soak_t := 0.0
## The loading fix: the frames with a proxy in the view since the last look or jump (printed at
## each: the one before's share).
var _pass_missing := 0


## --egg: the vehicle at the egg, for its kind of trigger; a motion trigger gets a path the rig
## drives at its pace (the 2 Hz checks judge it as they would a player).
func _egg_place() -> void:
	var t: Dictionary = m._egg["trigger"]
	var kind := str(t.get("kind", ""))
	var id := str(m._egg["id"])
	var e: Dictionary = m.egg_book.eggs[m.egg_book.by_id[id]] if m.egg_book != null and m.egg_book.by_id.has(id) else m._egg
	m._egg = e
	var at: Vector2 = e.get("at", Vector2.INF)
	if e.has("waits"):
		print("egg: --egg=%s waits for %s: its card is in the notebook, nothing finds it yet" % [id,
				m.egg_book.waits.get(str(e["waits"]), e["waits"])])
		m._rig_t = -1.0
		return
	match kind:
		"stop", "pass", "lap", "legacy":
			# A legacy egg (eggs.gd) fires within 26-30 m of its spot: a lane within 18 m of it, else
			# 12 m off it (the palm's island, the crowd).
			var off := Vector2.ZERO
			if kind == "legacy" and m.eggs != null and m.eggs.spots.has(id):
				var v: Vector3 = m.eggs.spots[id]
				at = Vector2(v.x, v.z)
				off = Vector2(12.0, 0.0)
			var reach := 18.0 if kind == "legacy" else float(t.get("within", 30.0)) * 0.8
			if kind == "lap":
				var r: Array = t["r"]
				var mid := (float(r[0]) + float(r[1])) * 0.5
				_rig_path = PackedVector2Array()
				for k in 73:
					var a := TAU * k / 72.0
					_rig_path.append(at + Vector2(cos(a), sin(a)) * mid)
				m._put_car_near(_rig_path[0], 1.0)
			else:
				m._put_car_near(at, reach)
				if Vector2(m.car.global_position.x, m.car.global_position.z).distance_to(at) > reach:
					m._put_car_near(at + off, 0.0)
				# A place on a bridge (E09): the lane on the deck, whatever the ground under it.
				var deck := _egg_deck(at, reach)
				if not deck.is_empty() and m.map.in_water(m.car.global_position.x, m.car.global_position.z, m.car.global_position.y):
					m.car.global_position = deck[0]
					m.car.rotation.y = deck[1]
					m.car.reset_physics_interpolation()
		"street":
			_rig_path = _street_path(e.get("pieces", PackedVector2Array()))
			if _rig_path.size() > 1:
				m._put_car_near(_rig_path[0], 1.0)
		"hover", "land", "between", "circle":
			if kind == "between" and e.has("a"):
				at = (e["a"] as Vector2).lerp(e["b"], 0.5)
			var h := float(t.get("min_alt", 0.0)) + 12.0
			if kind == "circle":
				var r2: Array = t["r"]
				_rig_path = PackedVector2Array()
				var mid2 := (float(r2[0]) + float(r2[1])) * 0.5
				for k in 73:
					var a2 := TAU * k / 72.0
					_rig_path.append(at + Vector2(cos(a2), sin(a2)) * mid2)
				at = _rig_path[0]
				h = 70.0
			m._put_car_near(at, 40.0)
			m._take_off(h)
			var g: float = m.map.ground_height(at.x, at.y)
			if kind == "land":
				g = m.map.top_height(at.x, at.y, Heli.RADIUS)
				h = 6.0
			m.heli.place(Vector3(at.x, g + h, at.y), m.heli.rotation.y, h if kind != "land" else g + h - m.map.ground_height(at.x, at.y))
			m._cut_camera()
		"tape":
			pass  # _start_moment plays the tape (_egg_moment set --tape)
		"event":
			# The garage loop: E01 at a club's door (crowds.gd fires it): the car at the door.
			if t.has("door") and m.crowds != null and m.crowds.by_id.has(str(t["door"])):
				var site: Dictionary = m.crowds.sites[m.crowds.by_id[str(t["door"])]]
				var door: Vector2 = site["door"]
				m._put_car_near(door, Crowds.CAR_NEAR - 1.0)
				at = door
	# The start point (the place's hint) may have been in the river (E09): no tow once the car
	# stands on dry land or a deck.
	var cp := m.car.global_position
	if not m.flying and m.car.in_water and not m.map.in_water(cp.x, cp.z, cp.y):
		m.car.leave_water()
		m._tow_wait = -1.0
	_rig_s = 0.0
	m._rig_t = 0.0
	print("egg: --egg=%s %s at %.0f, %.0f (%s)" % [id, kind, at.x, at.y, m.egg_book.describe_state(m._egg_state())])


## --egg: the lane nearest `at` within `reach` m on any level (a bridge's deck over the river),
## not in the water: [position, yaw], or [] if none.
func _egg_deck(at: Vector2, reach: float) -> Array:
	if m.graph == null:
		return []
	var hit := m.graph.snap(at, reach, Vector2.ZERO)
	if hit.is_empty():
		return []
	var e: int = hit[0]
	var lane_s: float = hit[2]
	var h := m.graph.height(e, lane_s)
	var q := m.graph.point_at(e, lane_s, m.graph.lane_offset(e, hit[1]))
	if m.map.in_water(q.x, q.y, h):
		return []
	var d := m.graph.direction(e, lane_s)
	return [Vector3(q.x, h, q.y), atan2(-d.x, -d.y)]


## The named street's pieces in order along it (from one end to the other).
func _street_path(pieces: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	if pieces.size() < 2:
		return out
	# The two pieces furthest apart are the ends; the rest by their distance along that line.
	var a := pieces[0]
	var b := pieces[1]
	var far := -1.0
	for p in pieces:
		for q in pieces:
			var d := p.distance_squared_to(q)
			if d > far:
				far = d
				a = p
				b = q
	var dir := (b - a).normalized()
	var order: Array = []
	for p in pieces:
		order.append([(p - a).dot(dir), p])
	order.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	for o: Array in order:
		out.append(o[1])
	return out


## The --egg rig, each frame: a lap or a street driven at 90 % of its speed limit, the
## helicopter round its circle, sinking onto its roof, or holding still.
func _egg_rig(dt: float) -> void:
	m._rig_t += dt
	var t: Dictionary = m._egg["trigger"]
	var kind := str(t.get("kind", ""))
	if m.egg_book != null and m.egg_book.is_found(str(m._egg["id"])):
		if m._rig_t < 1e6:
			print("egg: --egg=%s found %.1f s after the start" % [m._egg["id"], m._rig_t])
			m._rig_t = 1e7
		if kind in ["lap", "street", "circle"]:
			m.car.vel = Vector3.ZERO
		return
	if m.flags.egg_log and int(m._rig_t / 10.0) != int((m._rig_t - dt) / 10.0):
		print("egg: --egg=%s not yet after %.0f s (%s)" % [m._egg["id"], m._rig_t, m.egg_book.describe_state(m._egg_state())])
	match kind:
		"lap", "street", "circle":
			if _rig_path.size() < 2:
				return
			var speed := float(t.get("max_kmh", 72.0)) * 0.9 / 3.6
			_rig_s += speed * dt
			var i := 0
			var left := _rig_s
			while i < _rig_path.size() - 1 and left > _rig_path[i].distance_to(_rig_path[i + 1]):
				left -= _rig_path[i].distance_to(_rig_path[i + 1])
				i += 1
			if i >= _rig_path.size() - 1:
				_rig_s = 0.0
				i = 0
				left = 0.0
			var a := _rig_path[i]
			var b := _rig_path[i + 1]
			var dir := (b - a).normalized()
			var p := a + dir * left
			var v := Vector3(dir.x, 0.0, dir.y) * speed
			if kind == "circle":
				m.heli.global_position = Vector3(p.x, m.heli.global_position.y, p.y)
				m.heli.vel = v
			else:
				m.car.global_position = Vector3(p.x, m.map.ground_height(p.x, p.y) + 0.05, p.y)
				m.car.rotation.y = atan2(-dir.x, -dir.y)
				m.car.vel = v
		"land":
			m.heli.climb = -1.0
		"hover", "between":
			m.heli.input_dir = Vector3.ZERO
		_:
			m.car.vel = Vector3.ZERO


## --quest-quit: the full map open, its quit button tapped twice (if it shows).
func _quest_quit_test() -> void:
	print("quest quit test: running %s, %s" % [m._quest_running(), m._quest_quit_name()])
	m._open_full_map()
	if not m.hud.full_map_open():
		# The map can't open here (the title is up, a settings card...): quit the way its button does.
		print("quest quit test: the map didn't open, quitting directly")
		m._quit_quest()
		print("quest quit test: after, running %s" % m._quest_running())
		return
	m.hud.full_map.open_screen()  # 2026-11-17: QUIT is on the QUESTS screen's NOW line
	var qb := m.hud.full_map.find_child("quit_quest", true, false) as Button
	if qb == null:
		print("quest quit test: no quit button")
		m.hud.full_map.close()
		return
	print("quest quit test: button \"%s\"" % qb.text)
	qb.pressed.emit()
	qb = m.hud.full_map.find_child("quit_quest", true, false) as Button
	print("quest quit test: armed \"%s\"" % (qb.text if qb != null else "?"))
	if qb != null:
		qb.pressed.emit()
	print("quest quit test: after, running %s, map open %s" % [m._quest_running(), m.hud.full_map.is_open()])


## GAMEPLAY_PLAN 0.1: --teleport-test (see TELEPORT_TESTS).
func _teleport_test() -> void:
	var bad := 0
	# PT-19: the map's hold asks main.gd first (a race, a job, a rescue, a chase say no).
	if m.hud.full_map == null:
		m.hud.open_full_map(Vector2.ZERO, 0.0, PackedVector2Array())  # makes the map (the title may be up)
	m._wire_full_map()
	if m.hud.full_map == null or not m.hud.full_map.can_teleport.is_valid():
		bad += 1
		push_error("teleport test: the full map has no refusal (can_teleport), so a hold teleports mid-race")
	if m.hud.full_map != null and m.hud.full_map.is_open():
		m.hud.full_map.close()
	for t: Array in Main.TELEPORT_TESTS:
		var asked := Vector2(t[0], t[1])
		m._teleport_from_map(asked)
		var p := m.car.global_position
		var ground: float = m.map.terrain_height(p.x, p.z)
		var level: float = m.map.drive_height(p.x, p.z, p.y)
		var why := ""
		if m.map.in_tunnel(p.x, p.z, p.y) or p.y < ground - 1.0:
			why = "in a tunnel (%.1f m under the ground)" % (ground - p.y)
		elif absf(p.y - level) > 1.0:
			why = "off the road's level (%.1f m)" % (p.y - level)
		elif Vector2(p.x, p.z).distance_to(asked) > 110.0:
			why = "%.0f m from where it was asked" % Vector2(p.x, p.z).distance_to(asked)
		if why != "":
			bad += 1
			push_error("teleport test: %s: the car at %.0f, %.1f, %.0f is %s" % [t[2], p.x, p.y, p.z, why])
		else:
			print("teleport test: %s: %.0f, %.0f, %.1f m over the ground" % [t[2], p.x, p.z, p.y - ground])
	if bad == 0:
		print("teleport test: OK %d/%d" % [Main.TELEPORT_TESTS.size(), Main.TELEPORT_TESTS.size()])
	m.get_tree().quit(1 if bad > 0 else 0)


## --contacts=FILE (step 3): the log starts once the car and the lane graph are there; it watches
## the car once a physics frame, before the car's step, as check_lane_drive does.
func _start_contact_log(data: Dictionary) -> void:
	var log_script := load(Main.CONTACT_LOG) as GDScript
	m._contacts = log_script.new()
	_contact_names = log_script.street_names(data["graph"]) if data.has("graph") else PackedStringArray()
	m._contacts.street_at = _contact_street
	if not m._contacts.open(m.flags.contacts_to):
		m._contacts = null
		return
	m.get_tree().physics_frame.connect(_observe_contacts)
	print("contacts: the car's contacts go to %s" % m.flags.contacts_to)


func _observe_contacts() -> void:
	if m._contacts != null and m.car != null and is_instance_valid(m.car) and not m.get_tree().paused:
		m._contacts.observe(m.car, m.get_physics_process_delta_time())


## The contact log's street: the nearest lane's name and limit within 8 m, else none.
func _contact_street(x: float, z: float) -> Array:
	var hit: Array = m.graph.snap(Vector2(x, z), 8.0) if m.graph != null else []
	if hit.is_empty():
		return ["(off the lanes)", 0.0]
	var e: int = hit[0]
	return [_contact_names[e] if e < _contact_names.size() else m.graph.e_name[e], m.graph.e_speed[e]]


## Loop 2c, --lineup: every vehicle model standing round the car, all facing its way: beside it
## the taxi, Łuber, the police car, the guards' car and the two vans; a row ahead the cars'
## four shapes; a row behind the six rivals; further back the articulated and the solo bus (and the
## solo one with its night sign) and a tram cab car.
## Family shapes go through a MultiMesh with the shape in the custom alpha, as traffic draws
## them. Prints each model's triangles.
func _build_lineup(parent: Node3D) -> void:
	var b := m.car.global_transform.basis
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var ahead := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	var origin := m.car.global_position
	var yaw := m.car.rotation.y
	var spot := func(x: float, z: float, turn: float) -> Transform3D:
		var q := origin + right * x + ahead * z
		q.y = m.map.ground_height(q.x, q.z)
		return Transform3D(Basis(Vector3.UP, yaw + turn), q)
	var cars := Models.traffic_mesh(0)
	var taxis := Models.traffic_mesh(1)
	var vans := Models.traffic_mesh(2)
	var police := Models.police_mesh()
	# [mesh, shape, paint, x, z, turn, name]
	var rows := [
		[taxis, 0, "#f2f2ee", -10.0, 0.0, 0.0, "taxi"], [taxis, 1, "#2b2c2f", -6.6, 0.0, 0.0, "podwozka"],
		[police, 0, Models.POLICE_WHITE.to_html(false), -3.3, 0.0, 0.0, "police"],
		[police, 1, Models.GUARD_MUSTARD.to_html(false), 3.3, 0.0, 0.0, "guard"],
		[police, 2, Models.AMBULANCE_YELLOW.to_html(false), 0.0, -4.7, 0.0, "ambulance"],
		[vans, 0, "#e9e9e6", 6.7, 0.0, 0.0, "panel van"], [vans, 1, "#d8d2c2", 10.3, 0.0, 0.0, "box van"],
		[cars, 0, "#b8bcc0", -4.8, 7.5, 0.0, "hatch"], [cars, 1, "#24324a", -1.6, 7.5, 0.0, "saloon"],
		[cars, 2, "#4c6650", 1.6, 7.5, 0.0, "estate"], [cars, 3, "#2b2c2f", 4.8, 7.5, 0.0, "suv"],
		[Models.traffic_mesh(3), 0, "#ffffff", -4.0, -17.5, 0.0, "bus"],
		[Models.traffic_mesh(3), 1, "#ffffff", 0.0, -14.5, 0.0, "solo bus"],
		[Traffic.night_bus_mesh(), 1, "#ffffff", 4.0, -14.5, 0.0, "solo bus, night sign"],
	]
	for r: Array in rows:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = r[0]
		mm.instance_count = 1
		mm.set_instance_transform(0, spot.call(r[3], r[4], r[5]))
		var paint := Color(r[2])
		mm.set_instance_custom_data(0, Color(paint.r, paint.g, paint.b, float(r[1])))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Models.material()
		parent.add_child(mmi)
		print("lineup: %s %d triangles" % [r[6], _triangles(r[0])])
	for i in Rivals.RIVALS.size():
		var mi := MeshInstance3D.new()
		mi.mesh = Models.rival_mesh(Rivals.RIVALS[i]["style"])
		mi.material_override = Models.material()
		mi.transform = spot.call(-8.0 + i * 3.2, -8.0, 0.0)
		parent.add_child(mi)
		print("lineup: rival %s %d triangles" % [Rivals.RIVALS[i]["name"], _triangles(mi.mesh)])
	var tram := MeshInstance3D.new()
	tram.mesh = Models.tram_mesh(true)
	tram.material_override = Models.material()
	tram.transform = spot.call(4.0, -17.0, 0.0)
	parent.add_child(tram)
	print("lineup: tram cab car %d triangles" % _triangles(tram.mesh))
	var own := 0
	for c in m.car.get_children():
		for m in c.get_children():
			if m is MeshInstance3D and (m as MeshInstance3D).mesh is ArrayMesh \
					and (m as MeshInstance3D).material_override != Models.glow_material():
				own += _triangles((m as MeshInstance3D).mesh)
	print("lineup: the player's car %d triangles" % own)


static func _triangles(mesh: Mesh) -> int:
	var n := 0
	for k in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(k)
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		n += (idx.size() if not idx.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n


## Loop 10a, --drive-into-water=X,Z: the car at X,Z, facing the nearest water at least 4 m past
## its edge (within 120 m), flat out, its collision off as if it had jumped the edge (a ramp, a
## glitch); the collision comes back on 3 m past the edge, and the splash and the tow follow.
func _start_water_test() -> void:
	var p := m.flags._water_test_at
	var best := Vector2.ZERO
	var best_r := 120.0
	for k in 72:
		var d := Vector2.from_angle(TAU * k / 72.0)
		var r := 2.0
		while r < best_r:
			var q := p + d * r
			if m.map.shore_distance(q.x, q.y) >= 4.0:
				best_r = r
				best = d
				break
			r += 1.0
	if best == Vector2.ZERO:
		print("water test: no water within 120 m of %.0f, %.0f" % [p.x, p.y])
		return
	m.car.global_position = Vector3(p.x, m.map.drive_height(p.x, p.y, m.map.terrain_height(p.x, p.y)), p.y)
	m.car.rotation.y = atan2(-best.x, -best.y)
	m.car.vel = Vector3.ZERO
	m.car.reset_physics_interpolation()
	m.car.collision_mask = 0
	m.cam_focus = m.car.global_position
	m.water_test = 1
	print("water test: from %.0f, %.0f towards the water %.0f m away (heading %03.0f°); %s" % [p.x, p.y, best_r,
			fposmod(rad_to_deg(atan2(best.x, -best.y)), 360.0), m._activity()])


## Loop 10a: the water test drives flat out, straight on; collision back on past the edge.
func _water_test_frame() -> void:
	m.car.target_dir = Vector3.ZERO
	m.car.steer = 0.0
	m.car.throttle = 1.0
	m.car.braking = false
	var p := m.car.global_position
	if m.water_test == 1 and m.map.shore_distance(p.x, p.z) >= 3.0:
		m.car.collision_mask = 1
		m.water_test = 2


## The driving-feel loop, --ram-test: after 2 s of traffic, the moving car (not police, not a bus)
## with the longest straight run left on its lane gets the player's car put 14 m behind it, going
## 6 m/s faster; the stick then points along that lane (Point) at 65 km/h. Logs the hit (`traffic`'s
## daze), the rammed car's speed after the shove and how soon the player's car gets past it (its
## centre a car's length ahead along the lane), or that it never did in 10 s.
func _ram_test_frame(dt: float) -> void:
	_ram_t += dt
	if m.ram_test == 1:
		m.car.target_dir = Vector3.ZERO
		m.car.throttle = 0.0
		if _ram_t < 2.0 or m.traffic == null:
			return
		var best: Traffic.Driver = null
		var best_run := 60.0
		for d in m.traffic.drivers():
			if d.ghost or d.in_conn or d.parked or d.kind >= Traffic.Kind.BUS or d.v < 3.0 or d.s < 20.0:
				continue
			var run: float = m.graph.e_len[d.edge] - d.s
			if run > best_run:
				best_run = run
				best = d
		if best == null:
			if _ram_t > 12.0:
				print("ram test: no traffic car with 60 m of lane ahead in 12 s")
				m.ram_test = 3
			return
		var behind := m.graph.point_at(best.edge, best.s - 14.0, best.off)
		m.car.global_position = Vector3(behind.x, m.map.drive_height(behind.x, behind.y, best.pos.y), behind.y)
		m.car.rotation.y = best.yaw
		m.car.reset_physics_interpolation()
		m.car.vel = Vector3(-sin(best.yaw), 0.0, -cos(best.yaw)) * (best.v + 6.0)
		m.car.forward_speed = best.v + 6.0
		m.cam_focus = m.car.global_position
		_ram_driver = best
		_ram_dir = Vector3(-sin(best.yaw), 0.0, -cos(best.yaw))
		_ram_t = 0.0
		_ram_unsticks = m.car.unsticks
		m.ram_test = 2
		print("ram test: behind a traffic car at %.0f, %.0f going %.0f km/h (%.0f m of lane ahead)" % [best.pos.x,
				best.pos.z, best.v * 3.6, best_run])
		return
	var d: Traffic.Driver = _ram_driver
	# The lane's way at the start (the rammed car's own heading turns as it is shoved aside).
	var fwd := _ram_dir
	m.car.target_dir = fwd
	m.car.throttle = 0.6
	m.car.steer = 0.0
	m.car.braking = false
	if _ram_hit < 0.0 and d.daze > 0.0:
		_ram_hit = _ram_t
		print("ram test: hit at %.0f km/h, the car shoved to %.0f km/h" % [m.car.vel.length() * 3.6, d.v * 3.6])
	var ahead := (m.car.global_position - d.pos).dot(fwd)
	if _ram_hit >= 0.0 and ahead > d.length:
		print("ram test: past it %.1f s after the hit, unstuck %d×, the car at %.0f km/h" % [_ram_t - _ram_hit,
				m.car.unsticks - _ram_unsticks, m.car.vel.length() * 3.6])
		m.ram_test = 3
	elif _ram_t > 10.0 or not d.active:
		print("ram test: %s after 10 s (%.1f m behind, unstuck %d×)" % ["never hit it" if _ram_hit < 0.0 else "NEVER PAST it",
				-ahead, m.car.unsticks - _ram_unsticks])
		m.ram_test = 3


## The traffic loop, --tram-watch=N: keeps the car (and so the view) 30 m ahead of tram N and 20 m
## to its side, moved on as the tram draws level with that spot or gets 60 m from it.
func _tram_watch_frame() -> void:
	if m.trams == null or m.flags.tram_watch >= m.trams.trams.size():
		return
	var t: Trams.Tram = m.trams.trams[m.flags.tram_watch]
	var head := Vector2(t.pos.x, t.pos.z)
	if _tram_watch_at == Vector2.INF or head.distance_to(_tram_watch_at) < 22.0 or head.distance_to(_tram_watch_at) > 60.0:
		_tram_watch_at = head + t.dir * 30.0 + Vector2(-t.dir.y, t.dir.x) * 20.0
		m.car.collision_layer = 0
		m.car.collision_mask = 0
	m.car.global_position = Vector3(_tram_watch_at.x, t.pos.y + 0.5, _tram_watch_at.y)
	m.car.vel = Vector3.ZERO
	m.car.forward_speed = 0.0
	m.car.target_dir = Vector3.ZERO
	m.car.throttle = 0.0
	m.cam_focus = m.car.global_position


## Camera loop, --cam-test=NAME: the scheme, the camera behind the car, the car ghosting through
## walls (the camera is what is tested; a building in the way would end the moment early).
func _start_cam_test() -> void:
	if not m.cam_test in ["classic_turn", "point_release", "brake"]:
		print("cam test: unknown test '%s' (classic_turn, point_release, brake)" % m.cam_test)
		m.cam_test = ""
		return
	m.controls.scheme = Controls.POINT if m.cam_test == "point_release" else Controls.CLASSIC
	m.hud.set_scheme(m.controls.scheme)
	m._set_follow(true)
	m.car.collision_mask = 0
	m.car.vel = Vector3.ZERO
	m.car.forward_speed = 0.0
	m.cam_yaw = rad_to_deg(m.car.rotation.y)
	m.cam_yaw_target = m.cam_yaw
	m.cam_focus = m.car.global_position
	print("cam test: %s, %s, from %.0f, %.0f heading %03.0f°, %.1f s parked first" % [m.cam_test,
			Controls.NAMES[m.controls.scheme], m.car.global_position.x, m.car.global_position.z, Main._compass_yaw(m.car.rotation.y),
			Main.CAM_TEST_SETTLE])


## The camera test's inputs for this frame, through the scheme's own mapping (as a finger on the
## stick or the pedals would give them).
func _cam_test_frame(dt: float) -> void:
	_cam_t += dt
	_cam_phase_t += dt
	var stick := Vector2.ZERO
	var gas := false
	var brake := false
	var kmh := absf(m.car.forward_speed) * 3.6
	var heading := Main._compass_yaw(m.car.rotation.y)
	if _cam_t < Main.CAM_TEST_SETTLE:
		m.controls.drive(m.car, stick, false, {}, false, false, m.cam_yaw, dt)
		return
	var phase := _cam_phase
	match m.cam_test:
		"classic_turn":
			# Up to 50 km/h straight on, then a 90° right turn (a driver's hands: full lock until
			# 25° short, easing back to the middle), the gas keeping it near 50.
			gas = kmh < 50.0
			if _cam_phase == 0 and kmh >= 50.0:
				_cam_phase = 1
				_cam_aim = heading + 90.0
			if _cam_phase >= 1:
				var err := wrapf(_cam_aim - heading, -180.0, 180.0)
				stick = Vector2(clampf(err / 25.0, -1.0, 1.0), 0.0)
				if _cam_phase == 1 and absf(err) < 3.0:
					_cam_phase = 2
		"point_release":
			# Up to 50 km/h pointing straight up the screen, then the stick held to the screen's right
			# (90° right of the car: the camera is behind it) for 2.5 s, then let go.
			if _cam_phase == 0:
				stick = Vector2(0.0, -1.0)
				if kmh >= 50.0:
					_cam_phase = 1
			if _cam_phase == 1:
				stick = Vector2(1.0, 0.0)
				if _cam_phase_t >= 2.5:
					_cam_phase = 2
		"brake":
			# Flat out to 90 km/h, then the brake to a stop.
			if _cam_phase == 0:
				gas = true
				if kmh >= 90.0:
					_cam_phase = 1
			if _cam_phase == 1:
				# (Held on at a standstill the brake would reverse: let go once stopped.)
				brake = true
				if kmh < 0.5:
					_cam_phase = 2
					brake = false
	if _cam_phase != phase:
		_cam_phase_t = 0.0
		print("cam test: phase %d at %.2f s (frame %d), %.0f km/h, heading %03.0f°" % [_cam_phase, _cam_t - Main.CAM_TEST_SETTLE,
				m.frame, kmh, heading])
	m.controls.drive(m.car, stick, stick != Vector2.ZERO, {}, gas, brake, m.cam_yaw, dt)


## Camera loop, --cam-log: one `cam:` line every CAM_LOG_EVERY frames (the turn rate is the
## fastest since the last line).
func _cam_log_frame(dt: float) -> void:
	if _cam_last_yaw != INF and dt > 0.0:
		_cam_turn_max = maxf(_cam_turn_max, absf(wrapf(m.cam_yaw - _cam_last_yaw, -180.0, 180.0)) / dt)
	_cam_last_yaw = m.cam_yaw
	# This frame's number as the screenshots count it (frame is counted up after the camera).
	var f := m.frame + 1
	if f % Main.CAM_LOG_EVERY != 0:
		return
	var vehicle: Node3D = m.heli if m.flying else m.car
	var pos := vehicle.get_global_transform_interpolated().origin
	var screen := m.get_viewport().get_visible_rect().size
	var on := m.cam.unproject_position(pos) * float(m.view.stretch_shrink)
	var kmh: float = (m.heli.speed() if m.flying else absf(m.car.forward_speed)) * 3.6
	var held: bool = m._heli_held if m.flying else m.controls.held or m.hud.stick_active()
	print("cam: frame %d %s %s%s finger %s | %3.0f km/h heading %05.1f° camera %05.1f° (off %+5.1f°) turning %3.0f°/s | car on screen %4.0f,%4.0f px (%+4.0f,%+4.0f from the middle) | view %5.1f m" % [
			f, "heli" if m.flying else Controls.KEYS[m.controls.scheme], "follow" if m.follow else "fixed",
			" test %s/%d" % [m.cam_test, _cam_phase] if m.cam_test != "" else "", "down" if held else "up", kmh,
			Main._compass_yaw(vehicle.rotation.y), Main._compass_yaw(deg_to_rad(m.cam_yaw)),
			wrapf(Main._compass_yaw(deg_to_rad(m.cam_yaw)) - Main._compass_yaw(vehicle.rotation.y), -180.0, 180.0), _cam_turn_max,
			on.x, on.y, on.x - screen.x * 0.5, on.y - screen.y * 0.5, m.cam.size])
	_cam_turn_max = 0.0


## --clicks: press on frame F, release on F + 2 (through Input, as a real click would come).
func _inject_clicks() -> void:
	for c in m.flags.clicks:
		if m.frame != c.z and m.frame != c.z + 2:
			continue
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = Vector2(c.x, c.y)
		e.global_position = e.position
		e.pressed = m.frame == c.z
		e.button_mask = MOUSE_BUTTON_MASK_LEFT if e.pressed else 0
		Input.parse_input_event(e)
		print("click %s at %d,%d (frame %d)" % ["down" if e.pressed else "up", c.x, c.y, m.frame])
	for d in m.flags.drags:
		var at := Vector2(d[0], d[1])
		var step := m.frame - d[2]
		if step < 0 or m.frame > d[5]:
			continue
		if step == 0 or m.frame == d[5]:
			var b := InputEventMouseButton.new()
			b.button_index = MOUSE_BUTTON_LEFT
			b.pressed = step == 0
			b.position = at + (Vector2(d[3], d[4]) if m.frame == d[5] else Vector2.ZERO)
			b.global_position = b.position
			b.button_mask = MOUSE_BUTTON_MASK_LEFT if b.pressed else 0
			Input.parse_input_event(b)
		elif step <= 10:
			var m := InputEventMouseMotion.new()
			m.button_mask = MOUSE_BUTTON_MASK_LEFT
			m.position = at + Vector2(d[3], d[4]) * (step / 10.0)
			m.global_position = m.position
			m.relative = Vector2(d[3], d[4]) / 10.0
			Input.parse_input_event(m)


## --bench: 300 frames to settle (traffic fills in), then the average of 600 (--bench-frames=)
## on the ghost route; --probe: the same where the car stands. Wall-clock time between frames,
## not dt (delta smoothing snaps dt to the display's refresh interval). The first line keeps
## the format of the bench before loop 2b, so old and new code compare like with like.
func _bench_frame() -> void:
	if _bench_done:
		return
	if m._measure_t0 == 0:
		if m.frame < m._bench_settle and Time.get_ticks_msec() - m._bench_t0 < Main.SETTLE_SECONDS * 1000.0:
			return
		m._measure_t0 = Time.get_ticks_msec()
		m._stats.start()
		return
	m._stats.sample()
	if m.sfx != null:
		var peaks := Sfx.bus_peaks()
		for bus in _meters:
			_meters[bus] += peaks[bus]
			_meter_top[bus] = maxf(_meter_top[bus], peaks[bus])
	if m._stats.frames.size() < m.flags._bench_frames and Time.get_ticks_msec() - m._measure_t0 < m.flags._bench_seconds * 1000.0:
		return
	_bench_done = true
	var r := m._stats.report()
	var n := float(m._stats.frames.size())
	var us := func(k: String) -> float: return r.get("us:" + k, 0.0) / 1000.0
	var what := "probe" if m.flags.probe else "bench"
	print("%s: %.2f ms/frame (%.0f fps, worst %.1f ms) over %d frames · scripts: traffic %.2f + trams %.2f + people %.2f = %.2f ms, side jobs + eggs %.3f ms, sound %.3f ms · 3D view: GPU %.2f ms, render CPU %.2f ms · %.0f cars on screen, %.0f driving · %s · %s · %s · quality %s" % [
			what, r["ms"], r["fps"], r["worst"], r["frames"],
			us.call("traffic"), us.call("trams"), us.call("people"), us.call("traffic") + us.call("trams") + us.call("people"),
			us.call("jobs+eggs"), us.call("sound"), r["gpu"], r["render_cpu"],
			r.get("n:cars on screen", 0.0), r.get("n:driving", 0.0), "no traffic" if m.traffic == null else "traffic on", TimeOfDay.NAMES[m.tod.mode],
			Weather.NAMES[m.weather.state], Main.QUALITY[m.quality]["name"] + " · traffic " + Settings.TRAFFIC_NAMES[m.traffic_level]])
	m._stats.header = m._bench_header("probe" if m.flags.probe else "bench route (--bench)")
	m._stats.notes = m._governor_notes()
	var text := m._stats.text(r)
	for line in text.split("\n"):
		print("%s detail: %s" % [what, line])
	m._print_old_late(r)
	if m.flags.probe:
		print("probe view: %s" % _view_census())
	m._write_bench_result(text)
	print("bench audio peaks, mean / loudest dBFS (-200 = silent or no audio device): Master %.1f / %.1f · Music (radio) %.1f / %.1f · SFX %.1f / %.1f · Ambience %.1f / %.1f" % [
			_meters["Master"] / n, _meter_top["Master"], _meters["Music"] / n, _meter_top["Music"],
			_meters["SFX"] / n, _meter_top["SFX"], _meters["Ambience"] / n, _meter_top["Ambience"]])
	m.get_tree().quit()


## Loop 2b, --probe: what stands in the camera's view: nodes and instances, shadow casters,
## distinct materials and shaders (each shader brings its own pipelines).
func _view_census() -> String:
	var planes := m.cam.get_frustum()
	var mats := {}
	var shaders := {}
	var nodes := 0
	var instances := 0
	var casters := 0
	var caster_instances := 0
	var kinds := {}
	var proxy_n := 0
	var proxy_tris := 0
	var tower_only := 0
	var tower_keys := {}
	var stack: Array[Node] = [m.sv]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var g := n as GeometryInstance3D
		if g == null or not g.is_visible_in_tree():
			continue
		var box: AABB = g.global_transform * g.get_aabb()
		var inside := true
		for pl: Plane in planes:
			# Outside when every corner lies in front of one of the frustum's planes.
			var out := true
			for k in 8:
				if not pl.is_point_over(box.get_endpoint(k)):
					out = false
					break
			if out:
				inside = false
				break
		if not inside:
			continue
		# Loop 3d-2b: a node past its visibility range isn't drawn.
		if g.visibility_range_end > 0.0 and m.cam.global_position.distance_to(box.get_center()) > g.visibility_range_end:
			continue
		nodes += 1
		var count := 1
		var mesh: Mesh = (g as MeshInstance3D).mesh if g is MeshInstance3D else null
		# Loop 3d-2b: what a far level could take: draws of sectors in view only by their towers.
		var sector_root := g.get_parent()
		while sector_root != null and sector_root.get_parent() != null and sector_root.get_parent().name != "Sectors":
			sector_root = sector_root.get_parent()
		if m.streamer != null and sector_root != null and sector_root.get_parent() != null and sector_root.get_parent().name == "Sectors":
			var parts := String(sector_root.name).trim_prefix("s_").split("_")
			var key := Vector2i(int(parts[0]), int(parts[1]))
			if not m.streamer.ground_in_view(key, 0.0, 25.0, planes):
				tower_only += 1
				tower_keys[key] = true
		# Loop 3d-2b: the far level (the sectors' proxies) on its own line.
		if g.get_parent().name == "Proxies" and mesh != null and mesh.get_surface_count() > 0:
			proxy_n += 1
			for k in mesh.get_surface_count():
				proxy_tris += mesh.surface_get_array_index_len(k) / 3
		if g is MultiMeshInstance3D:
			var mm := (g as MultiMeshInstance3D).multimesh
			count = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			mesh = mm.mesh
		var mat_name := "-"
		if g.material_override is ShaderMaterial:
			mat_name = (g.material_override as ShaderMaterial).shader.resource_path.get_file().get_basename()
		elif g.material_override != null:
			mat_name = g.material_override.get_class()
		var kind := "%s %s %s %d" % ["MMI" if g is MultiMeshInstance3D else g.get_class(), mat_name,
				g.get_parent().name.left(12), mesh.get_surface_count() if mesh != null else 0]
		if mesh is ArrayMesh and mesh.get_surface_count() > 0 and g is MultiMeshInstance3D:
			kind += " v%d" % mesh.surface_get_array_len(0)
		kinds[kind] = kinds.get(kind, 0) + 1
		instances += count
		if g.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			casters += 1
			caster_instances += count
		var list: Array[Material] = []
		if g.material_override != null:
			list.append(g.material_override)
		elif g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var mi := g as MeshInstance3D
			for k in mi.mesh.get_surface_count():
				var m := mi.get_active_material(k)
				if m != null:
					list.append(m)
		for m in list:
			mats[m.get_instance_id()] = true
			shaders[(m as ShaderMaterial).shader.resource_path.get_file() if m is ShaderMaterial else m.get_class()] = true
	var parts := PackedStringArray()
	for k in kinds:
		parts.append("%s ×%d" % [k, kinds[k]])
	var far := ""
	if m.streamer != null:
		far = "\nprobe far level: %d proxies in view, %d triangles; %d sectors in full detail; %d nodes in view from %d sectors whose ground and low buildings are out of it" % [proxy_n, proxy_tris,
				m.streamer.loaded().size(), tower_only, tower_keys.size()]
	return "%d nodes (%d instances) in view, %d shadow-casting nodes (%d instances), %d materials, %d shaders: %s\nprobe kinds: %s%s" % [
			nodes, instances, casters, caster_instances, mats.size(), shaders.size(), ", ".join(PackedStringArray(shaders.keys())),
			" | ".join(parts), far]


func _stop_step() -> void:
	if m.flags.stops.is_empty() or m.frame < 120 or _stop_busy or _stop_at >= m.flags.stops.size():
		return
	_stop_busy = true
	var s: Array = m.flags.stops[_stop_at]
	m.car.global_position = Vector3(s[0], m.map.ground_height(s[0], s[1]), s[1])
	m.car.vel = Vector3.ZERO
	m.cam_yaw = s[2]
	m.cam_yaw_target = s[2]
	m.camera_pitch = s[3]
	m.base_size = s[4]
	m._view_size = s[4]
	m.cam.size = s[4]
	m.cam_focus = m.car.global_position
	# Count drawn frames, not game frames: a hidden window can draw far less often than it runs.
	for i in Main.STOP_DRAWS:
		await RenderingServer.frame_post_draw
	m.get_viewport().get_texture().get_image().save_png(m.flags.out_dir.path_join("%s.png" % s[5]))
	_stop_at += 1
	_stop_busy = false
	print("stops: %d / %d %s at %.0f,%.0f" % [_stop_at, m.flags.stops.size(), s[5], m.car.global_position.x, m.car.global_position.z])
	if _stop_at >= m.flags.stops.size():
		_quit_quietly()


func _capture(n: int) -> void:
	await RenderingServer.frame_post_draw
	if m.flags.ghost_debug > 0:
		print("ghost: frame %d centre %.1f %.1f radii %.1f %.1f (screen px)" % [n, m._ghost_px.x, m._ghost_px.y, m._ghost_px.z, m._ghost_px.w])
	var img := m.get_viewport().get_texture().get_image()
	# A missing --out folder used to end the run with code 0 and no PNG: make it, and fail loudly.
	var dir := ProjectSettings.globalize_path(m.flags.out_dir)
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var name := "shot_%04d.png" % n
	if not m.flags.shot_spots.is_empty():
		name = "%s_%04d.png" % [m.flags.shot_spots[_spot_i][0], n - _spot_base]
		if not m.flags.grade_sweep.is_empty():
			var tg: Array = m.flags.grade_sweep[_sweep_i]
			name = "%s_%s_%s.png" % [m.flags.shot_spots[_spot_i][0], tg[0], tg[1]]
	var err := img.save_png(m.flags.out_dir.path_join(name))
	if err != OK:
		printerr("shots: could not write %s (error %d)" % [m.flags.out_dir.path_join(name), err])
		m.get_tree().quit(1)
		return
	m._shots_saved.append(n)
	if n == m.shots.max():
		if not m.flags.grade_sweep.is_empty():
			# The next [time, look] pair at this spot; after the last, the first again and on.
			_sweep_i = (_sweep_i + 1) % m.flags.grade_sweep.size()
			var tg: Array = m.flags.grade_sweep[_sweep_i]
			m.tod.set_mode(TimeOfDay.parse(tg[0]), true)
			m.tod.set_grade(tg[1])
			if _sweep_i > 0:
				var shift: int = m.frame - _spot_base
				_spot_base = m.frame
				for i in m.shots.size():
					m.shots[i] += shift
				return
		if _spot_i + 1 < m.flags.shot_spots.size():
			_next_spot()
			return
		_quit_quietly()  # sweep 2: was get_tree().quit()


## --spots: moves the car (and the camera, with no blend) to the next spot and shifts the shot
## frames by the frames spent so far, so each spot gets the same settle time as the first.
func _next_spot() -> void:
	_spot_i += 1
	var sp: Array = m.flags.shot_spots[_spot_i]
	if not m.flags._cams.is_empty():
		m._apply_cam(_spot_i)
	var p: Vector2 = sp[1]
	m.car.global_position = Vector3(p.x, m.map.ground_height(p.x, p.y), p.y)
	if sp[2] != INF:
		m.car.rotation.y = -deg_to_rad(sp[2])
	m.car.vel = Vector3.ZERO
	m.car.forward_speed = 0.0
	m.car.reset_physics_interpolation()
	m.cam_focus = m.car.global_position
	# The same view as the first spot (and as a single --at run): keep the camera's yaw, since
	# _cut_camera turns a following camera behind the car.
	var yaw := m.cam_yaw
	var yaw_target := m.cam_yaw_target
	m._cut_camera()
	m.cam_yaw = yaw
	m.cam_yaw_target = yaw_target
	var shift: int = m.frame - _spot_base
	_spot_base = m.frame
	for i in m.shots.size():
		m.shots[i] += shift
	print("shots: spot %s at %.0f, %.0f (frame %d, shots %s)" % [sp[0], p.x, p.y, m.frame, str(m.shots)])


## Sweep 2: windowed `--shots` runs sometimes ended with "8 ObjectDB instances were leaked at
## exit" / "4 resources still in use": the sounds playing at the quit (an AudioStreamWAV and
## its playback each: the radio's station, the engine's idle and mid loops, the city bed),
## still held by the audio server because the tree went before its mixing thread let them
## go (headless runs have no audio device, so they never showed it). The game stops updating
## (sfx.gd would start a loop again), every player is stopped, and the server gets
## QUIET_QUIT_MS of real time before the quit.
func _quit_quietly() -> void:
	m.process_mode = Node.PROCESS_MODE_DISABLED
	for kind: String in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for p: Node in m.get_tree().root.find_children("*", kind, true, false):
			p.call("stop")
	var until := Time.get_ticks_msec() + Main.QUIET_QUIT_MS
	while Time.get_ticks_msec() < until:
		await m.get_tree().process_frame
	m.get_tree().quit()


## --spots: the car to a spot (x, z, heading in degrees), standing, the view on it.
func _jump_to_spot(s: Vector3) -> void:
	m.car.global_position = Vector3(s.x, m.map.ground_height(s.x, s.y), s.y)
	m.car.rotation.y = -deg_to_rad(s.z)
	m.car.vel = Vector3.ZERO
	m.car.reset_physics_interpolation()
	m._cut_camera()
	# The sectors round the spot in at once, colliders and all, as the whole city has them.
	if m.streamer != null:
		m.streamer.finish_view(m.cam_focus, m.cam)
	print("spot: %.1f, %.1f heading %.0f at frame %d" % [s.x, s.y, s.z, m.frame])


## --stream-soak: a serpentine over every sector's middle (row by row), inside the map.
func _soak_tour(data: Dictionary) -> Array[Vector2]:
	var b: Array = data["bounds"]
	var inner := Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1]).grow(-60.0)
	var rows := {}
	for key in m.streamer.keys:
		var c := (Vector2(key) + Vector2(0.5, 0.5)) * SectorStreamer.SECTOR
		c = c.clamp(inner.position, inner.end)
		if not m.map.in_map(c, -60.0):
			continue  # map north: a sector's middle in the corner left outside
		if not rows.has(key.y):
			rows[key.y] = []
		rows[key.y].append(c)
	var route: Array[Vector2] = []
	var ys := rows.keys()
	ys.sort()
	for r in ys.size():
		var row: Array = rows[ys[r]]
		row.sort_custom(func(a: Vector2, c: Vector2) -> bool: return a.x < c.x if r % 2 == 0 else a.x > c.x)
		for p: Vector2 in row:
			route.append(p)
	return route


## Loop 3d-2b, --stream-pass: the helicopter west to east across the map's middle north of the
## centre (the Palace, the river, Praga); the car east to west south of it.
func _pass_route(data: Dictionary) -> Array[Vector2]:
	var b: Array = data["bounds"]
	var inner := Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1]).grow(-120.0)
	if m.flags._pass_kind == "heli":
		return [Vector2(inner.position.x, -300.0), Vector2(inner.end.x, -300.0)]
	if m.flags._pass_kind == "car":
		return [Vector2(inner.end.x, 250.0), Vector2(inner.position.x, 250.0)]
	# The loading fix's passes start at the spawn (route[0]); look's points are its targets, jump's
	# where the car is put.
	var spawn: Dictionary = data.get("spawn", {})
	var route: Array[Vector2] = [Vector2(float(spawn.get("x", 0.0)), float(spawn.get("z", 0.0)))]
	var points: Array = []
	match m.flags._pass_kind:
		"heli-low", "start", "switch":
			points = [[300, 279], [300, -800], [-1400, -800], [-1400, 900]]
			# start: the first two legs (the first minute matters); switch: the car's leg and two flown.
			points = points.slice(0, {"heli-low": 4, "start": 2, "switch": 3}[m.flags._pass_kind])
		"look":
			points = [[-300, 280], [-900, -750], [-2400, 600], [1000, -500], [1900, -900], [-2900, 1500]]
		"jump":
			points = [[500, -300], [-2500, -1200], [1500, 900], [-300, 1300], [-1500, -1700], [1200, -1500]]
		_:
			push_warning("--stream-pass=%s: no such pass (heli, car, heli-low, start, switch, look, jump)" % m.flags._pass_kind)
	for q: Array in points:
		route.append(Vector2(float(q[0]), float(q[1])).clamp(inner.position, inner.end))
	return route


## --stream-soak, each frame: the car (then the helicopter) along the tour at 22 m/s, through
## buildings like the mission autopilot; the view 1x, then wide (220 m), every 20 s.
func _soak_frame(dt: float) -> void:
	_soak_t += dt
	if m.flags._pass_kind in ["look", "jump"]:
		if m._pass_frames < 0 and _soak_t >= Main.PASS_EVENT_S * m._soak_route.size():
			m._soak_minutes = _soak_t / 60.0  # the last look or jump had its PASS_EVENT_S: report
	elif m.flags._pass_kind != "" and m._soak_leg >= m._soak_route.size():
		m._soak_minutes = _soak_t / 60.0  # the pass is over: report as the soak does
	if _soak_t >= m._soak_minutes * 60.0:
		print("stream soak: %.0f s over %d sectors: %s" % [_soak_t, m.streamer.keys.size(), m.streamer.summary()])
		if m.soft_things != null:
			print("stream soak: soft things hardened %d sectors, %.2f ms on average, %.2f ms the most" % [m.soft_things.harden_count,
					m.soft_things.harden_usec / 1000.0 / maxf(m.soft_things.harden_count, 1), m.soft_things.harden_most / 1000.0])
		var numbers := m.streamer.stats()
		numbers["governor"] = "%s, %d changes%s" % [m.governor.state(), m.governor.changes, ", held" if m.governor.held else ""]
		print("stream soak stats: " + JSON.stringify(numbers))
		# Loop G0+: the numbers also go to a file (as the bench's card does), written and closed
		# here: on the iPhone get_tree().quit() does nothing and the app is stopped from outside,
		# so the log's tail is never certain; tools/device_run.sh copies this file back.
		var f := FileAccess.open("user://stream_soak_result.txt", FileAccess.WRITE)
		if f != null:
			f.store_string("stream soak: %.0f s over %d sectors: %s\nstream soak stats: %s\n" % [
					_soak_t, m.streamer.keys.size(), m.streamer.summary(), JSON.stringify(numbers)])
			f.close()
		m._soak_minutes = 0.0
		m.get_tree().quit()
		return
	if m._soak_route.is_empty():
		return
	if m.flags._pass_kind != "" and m._pass_frames >= 0:
		# The pass starts at its route's start: the vehicle put there, the view finished once the
		# camera has caught up (its zoom too) and the streamer has nothing left to load, and the
		# numbers counted from then on.
		m._pass_frames += 1
		var s0: Vector2 = m._soak_route[0]
		if m._pass_frames == 1:
			# Facing along the route, so the camera has turned there before the numbers count.
			var d: Vector2 = m._soak_route[1] - s0
			var yaw := atan2(-d.x, -d.y)
			m.car.rotation.y = yaw
			if m.flying:
				var alt := m.flags._start_alt if m.flags._start_alt > 0.0 else Heli.CRUISE
				m.heli.place(Vector3(s0.x, m.map.ground_height(s0.x, s0.y) + alt, s0.y), yaw, alt)
			else:
				m.car.collision_mask = 0
				m.car.global_position = Vector3(s0.x, m.map.drive_height(s0.x, s0.y, 0.0), s0.y)
				m.car.reset_physics_interpolation()
			m._cut_camera()
			if m.flying:
				m.cam_focus = m.heli.global_position
			m._soak_leg = 1
		elif m._pass_frames >= 180 and (m.streamer.idle() or m._pass_frames >= 1200):
			m.streamer.finish_view(m.cam_focus, m.cam)
			m.streamer.reset_stats()
			_soak_t = 0.0
			m._pass_frames = -1
		return
	if m.flags._pass_kind == "car":
		m.base_size = FollowCamera.DEFAULT_SIZE * (1.0 + FollowCamera.SPEED_ZOOM)  # the view at top speed
	elif m.flags._pass_kind == "heli":
		m.base_size = FollowCamera.DEFAULT_SIZE
		m.heli.alt_target = Heli.MAX_HEIGHT
	elif m.flags._pass_kind != "":
		m.base_size = FollowCamera.DEFAULT_SIZE  # the helicopter keeps its height (it climbs over a tower)
	else:
		m.base_size = FollowCamera.DEFAULT_SIZE if int(_soak_t / 20.0) % 2 == 0 else 220.0
		if not m.flying and _soak_t > m._soak_minutes * 40.0:
			m._take_off(Heli.CRUISE)
	if m.flags._pass_kind in ["look", "jump"]:
		_pass_event()
		return
	if m.flags._pass_kind != "" and m._soak_leg >= m._soak_route.size():
		return
	if m.flags._pass_kind == "switch" and not m.flying and m._soak_leg >= 2:
		m._take_off(Heli.CRUISE)  # the loading fix: the car's first leg done, the helicopter flies on
	var target: Vector2 = m._soak_route[m._soak_leg % m._soak_route.size()]
	var pos := m._vehicle_position()
	var to := Vector2(target.x - pos.x, target.y - pos.z)
	if to.length() < 25.0:
		m._soak_leg += 1
		if m.flags._pass_kind != "":
			print("stream pass: leg %d done at frame %d (%.0f s)" % [m._soak_leg - 1, m.frame, _soak_t])
		return
	if m.flying:
		m.heli.input_dir = Vector3(to.x, 0.0, to.y).normalized()
		m.heli.climb = 1.0 if m.heli.blocked else 0.0
		return
	var step := to.normalized() * (Main.PASS_CAR_SPEED if m.flags._pass_kind in ["car", "switch"] else 22.0) * dt
	m.car.collision_mask = 0
	m.car.vel = Vector3.ZERO
	m.car.global_position = Vector3(pos.x + step.x, m.map.drive_height(pos.x + step.x, pos.z + step.y, pos.y), pos.z + step.y)
	m.car.rotation.y = atan2(-to.x, -to.y)


func _pass_tally() -> String:
	var n := m.streamer.missing_frames - _pass_missing
	_pass_missing = m.streamer.missing_frames
	return "%d frames with a proxy in the view since the last" % n


## The loading fix, --stream-pass=look|jump: every PASS_EVENT_S (from the pass's start) the next
## route point: a look at it (camera_shots.gd, as a new target gets; the helicopter hovers), or the
## car put there (as a tow does: no view finished first). The car stays where it was put.
func _pass_event() -> void:
	var due := int(_soak_t / Main.PASS_EVENT_S) + 1
	if m.flying:
		m.heli.input_dir = Vector3.ZERO
		m.heli.climb = 0.0
	if m.flags._pass_kind == "jump":
		var at: Vector2 = m._soak_route[mini(m._soak_leg - 1, m._soak_route.size() - 1)]
		if m._soak_leg < due and m._soak_leg < m._soak_route.size():
			at = m._soak_route[m._soak_leg]
			m._soak_leg += 1
			m.car.global_position = Vector3(at.x, m.map.drive_height(at.x, at.y, 0.0), at.y)
			m.car.reset_physics_interpolation()
			m._cut_camera()
			print("stream pass: jump to %.0f, %.0f at frame %d (%s)" % [at.x, at.y, m.frame, _pass_tally()])
		m.car.collision_mask = 0
		m.car.vel = Vector3.ZERO
		m.car.forward_speed = 0.0
		m.car.global_position = Vector3(at.x, m.map.drive_height(at.x, at.y, 0.0), at.y)
		return
	if m._soak_leg < due and m._soak_leg < m._soak_route.size() and not m.moments.playing() and m._look_queued.is_empty():
		var t: Vector2 = m._soak_route[m._soak_leg]
		m._soak_leg += 1
		var p := m._vehicle_position()
		m._queue_look(Vector3(p.x, m.map.ground_height(p.x, p.z), p.z), Vector3(t.x, m.map.ground_height(t.x, t.y), t.y))
		print("stream pass: look at %.0f, %.0f at frame %d (%s)" % [t.x, t.y, m.frame, _pass_tally()])


## --push-parked and --smash-fence (step 8a's and W6's shots; main.gd's frame): the push once the
## sector's cars are in; the next smash once its camera spot is on and its frame (from that spot's
## start) has come.
func _soft_shots_frame() -> void:
	if m.soft_things == null:
		return
	if not _push_parked_done and m.flags._flag_push_parked != Vector2.INF and m.soft_things.car_count() > 0:
		_push_parked_done = true
		var pushed_id := m.soft_things.push_near(m.flags._flag_push_parked, 7.0)
		print("push-parked: %s" % (pushed_id if pushed_id != "" else "no parked car near %s can move" % m.flags._flag_push_parked))
	var smashes: Array[Vector4] = m.flags._flag_smash_fence
	if _smash_done >= smashes.size() or _spot_i != _smash_done or m.frame - _spot_base < int(smashes[_spot_i].z):
		return
	var sf := smashes[_spot_i]
	_smash_done += 1
	var n := m.soft_things.smash_near(Vector2(sf.x, sf.y), Vector2.from_angle(deg_to_rad(sf.w)), 15.0)
	print("smash-fence: %d panels near %.0f, %.0f at frame %d (%d panel pieces written so far)" % [n, sf.x, sf.y, m.frame,
			m.panel_states.writes])
