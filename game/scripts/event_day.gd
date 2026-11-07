extends Node3D
## 11 listopada (F, 2026-11-07, docs plan /mnt/project-files/events/11-listopad-plan.md): the day
## event of the Independence Day. On 11 November (the Warsaw date) the city around Rondo
## Dmowskiego and Al. Jerozolimskie to Rondo de Gaulle'a celebrates: a crowd of people with
## white-and-red flags, grey police barriers shutting the four arms so a car cannot get in (the
## helicopter flies over), the Palace of Culture and Złota 44 lit white and red, and at dusk a
## red-lit haze over the crowd. Colours and flags only: no banners with words, no slogans, no
## group names, no chants (docs plan, section 1). Every piece is optional through Settings-style
## flags: `--event-day` forces it on (any date, any hour, full strength), `--event-day=0` turns it
## off, `--event-smoke=0` leaves out the glow pots and the haze, `--event-log` prints a summary.
##
## Pieces (each one reuses a system that already ships):
##  - **the gate**: `active()` = the calendar says 11 November (live clock), or `force`; the hours
##    (`crowd_share`) follow the real day: nobody before 10:00, full 13:00-18:30, thinning to 21:00;
##  - **the crowd**: ONE MultiMesh of the pedestrians' person mesh (Models.person_mesh) laid
##    along the mapped roads of the corridor (the carriageways and pavements of Al. Jerozolimskie
##    and Marszałkowska, denser at the rondo), one more for the flags; both written once, only the
##    visible count changes. +2 draw calls;
##  - **the barriers**: four lines of grey steel crowd barriers with white-red tape and a police van
##    behind each, one mesh in the models' material, one box collider per line (the car stops at
##    it like at edge_roadworks.gd's closures); the traffic and the trams are kept out of the
##    cross-shaped zone (`in_zone`: traffic.gd and trams.gd `keep_out`), a car that is inside when
##    the event starts (or comes in by a side street) is set down outside the nearest barrier.
##    +1 draw call;
##  - **the light**: white and red bands round the Palace's tiers and Złota 44 (the Level 26 band
##    trick of crowds.gd: Models.LIT_SIGN, so they glow while the city's lights are on), +1 draw call;
##  - **the glow and the haze**: red glow pots and big soft pink-red blobs at lamp-post height
##    (the additive glow material: they show at dusk and at night), and pink-grey smoke puffs
##    (fans.gd's puff mesh) rising from the pots. +3 draw calls. Off with `--event-smoke=0`.
## No real light node anywhere (the Mobile renderer): everything is mesh, additive glow or vertex
## colour. NPC/agent behaviour: none (Beehave / Dialogue Manager not used: the crowd stands).

const Models := preload("res://scripts/models.gd")
const Props := preload("res://scripts/props.gd")
const CityLife := preload("res://scripts/city_life.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Crowds := preload("res://scripts/crowds.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const Fans := preload("res://scripts/fans.gd")

## The rondo's frame (landmarks.gd RONDO_*): V east along Al. Jerozolimskie (towards Rondo de
## Gaulle'a), U south along Marszałkowska. All in game metres.
const C := Landmarks.RONDO_C
const V := Landmarks.RONDO_V
const U := Landmarks.RONDO_U

## The zone: the Jerozolimskie corridor from V_WEST to V_EAST (just past Rondo de Gaulle'a), the
## Marszałkowska corridor ±ARM, both CORRIDOR m either side of the axis.
const V_WEST := -95.0
const V_EAST := 650.0
const ARM := 95.0
const CORRIDOR := 30.0
## A car this far inside the zone is set down outside (the barrier line is the edge itself).
const KICK_DEPTH := 3.0

## The crowd: figures built, the flag share, the hours (hour -> share of the crowd out).
const CROWD_MAX := 6000
const FLAG_SHARE := 0.6
const BIG_FLAG_SHARE := 0.12
## Share of the flags that are giant sector banners (5 m cloth on a 5 m pole), seen from the helicopter.
const BANNER_SHARE := 0.06
const ROAD_PAD := 2.5

const WHITE := Color("#f4f1ea")
const RED := Color("#d8262b")
const STEEL := Color("#9aa0a6")
const STEEL_DARK := Color("#5b6066")
const POLE := Color("#c9ccd0")
const VAN_BODY := Color("#eef0f2")
const VAN_STRIPE := Color("#2c63b8")
const GLASS := Color("#2c333b")
const BLUE_LIGHT := Color("#4aa3ff")

## Shirts of the crowd: mostly everyday dark and neutral, a third in the national colours.
const SHIRTS: Array[Color] = [Color("#f4f1ea"), Color("#d8262b"), Color("#f4f1ea"), Color("#2b2c2f"), Color("#1c2230"),
		Color("#d8262b"), Color("#6d7178"), Color("#3a4a63"), Color("#8c5a3c"), Color("#f4f1ea")]

## The glow pots and the haze (smoke on): counts, haze height and size.
const POTS := 200
const HAZE := 160
## The standing smoke (event_fog.gdshader): big see-through blobs over the crowd, day and night.
const FOG := 520
const FOG_SIZE := Vector2(30.0, 74.0)
const FOG_Y := Vector2(2.0, 24.0)
const HAZE_Y := Vector2(9.0, 16.0)
const PUFFS := 700
## The lit puff boxes read as dark crates against the fog, which does the smoke now (event_fog.gdshader).
const PUFFS_ON := false
const PUFF_LIFE := 7.0

## The Palace's bands: heights as shares of the tower (bottom to top), the colours (0 red, 1 white);
## Złota 44 is lit as in the photos F sent (white on one side fading to red, `_tower_gradient`) and
## Stadion Narodowy gets a ring of white and red panels (`_stadium_bands`).
const PALACE_LEVELS: Array = [[0.07, 0], [0.14, 0], [0.21, 0], [0.28, 0], [0.35, 0], [0.42, 0], [0.49, 1], [0.56, 1], [0.63, 1], [0.70, 1], [0.77, 1], [0.84, 1], [0.91, 1]]
const PALACE_AT := Vector2(-1214.0, 247.0)
const ZLOTA_AT := Vector2(-1466.0, 311.0)
const RING_RAYS := 64

var map: Node3D
var hud: Node
## The game clock -> {hour, weekday}; the calendar -> {live, month, date, ...} (main.gd).
var clock: Callable
var calendar: Callable
var focus: Callable
## Whether the city's lights are on (tod.lights_on > 0).
var lit: Callable
## The player's vehicle -> [position, km/h, flying] (main.gd).
var vehicle: Callable
## Sets the car down: (position Vector3, yaw float, toast String) (main.gd).
var kick: Callable
var traffic: Node
var trams: Node
var force := false
var smoke_on := true
var amount := 1.0
var log_on := false

var on := false
var share := 0.0
var _data: Dictionary = {}
var _built := false
var _slots: Array = []
var _crowd_mm: MultiMesh
var _crowd_mmi: MultiMeshInstance3D
var _flag_mm: MultiMesh
var _flag_mmi: MultiMeshInstance3D
var _flag_n := 0
var _crowd_buf := PackedFloat32Array()
var _flag_buf := PackedFloat32Array()
var _shown := -1
var _crowd_aabb := AABB()
## Rewrites the buffers on the next few ticks too: the first ones can land before the renderer has the instances.
var _resend := 6
var _flags_shown := -1
var _dbg := 0.0
var _static: MeshInstance3D
var _bodies: StaticBody3D
var _pots_mmi: MultiMeshInstance3D
var _haze_mmi: MultiMeshInstance3D
var _fog_mmi: MultiMeshInstance3D
var _fog_mat: ShaderMaterial
var _puff_mm: MultiMesh
var _puff_mmi: MultiMeshInstance3D
var _puff_buf := PackedFloat32Array()
var _pot_pos: Array[Vector3] = []
var _bands: MeshInstance3D
var _bands_tries := 0
var _bands_ok := false
var _band_quads := 0
var _t := 0.0
var _tick := 0.0
var _kicks := 0
var _hours := 12.0


## Is it the day? The live calendar says 11 November, or the flag forces it.
func active() -> bool:
	if force:
		return true
	if not calendar.is_valid():
		return false
	var cal: Dictionary = calendar.call()
	return bool(cal.get("live", false)) and int(cal.get("date", 0)) % 10000 == 1111


## The share of the crowd out at `hour` (0..1): nobody before 10:00, up to full by 13:00, full to
## 18:30, thinning to a few by 21:00 (the barriers and the lights stay until 23:00).
static func crowd_share(hour: float) -> float:
	if hour < 10.0 or hour > 23.0:
		return 0.0
	if hour < 13.0:
		return (hour - 10.0) / 3.0
	if hour <= 18.5:
		return 1.0
	return clampf(1.0 - (hour - 18.5) / 2.5, 0.1, 1.0) if hour < 21.0 else 0.1


## The corridor frame: (v, u) of a game-plane point, and back.
static func to_vu(p: Vector2) -> Vector2:
	var d := p - C
	return Vector2(d.dot(V), d.dot(U))


static func from_vu(v: float, u: float) -> Vector2:
	return C + V * v + U * u


## Is the game-plane point inside the cross-shaped zone, `shrink` m in from its edge (negative:
## out from it)?
static func in_zone(p: Vector2, shrink := 0.0) -> bool:
	var q := to_vu(p)
	var w := CORRIDOR - shrink
	if q.x >= V_WEST + shrink and q.x <= V_EAST - shrink and absf(q.y) <= w:
		return true
	return absf(q.x) <= w and absf(q.y) <= ARM - shrink


## The four barrier lines: [centre (v, u), the direction along the line, the road direction out of the zone].
static func cordon() -> Array:
	return [
		{"id": "west", "at": from_vu(V_WEST, 0.0), "line": U, "out": -V},
		{"id": "east", "at": from_vu(V_EAST, 0.0), "line": U, "out": V},
		{"id": "north", "at": from_vu(0.0, -ARM), "line": V, "out": -U},
		{"id": "south", "at": from_vu(0.0, ARM), "line": V, "out": U},
	]


func setup(data: Dictionary) -> void:
	_data = data
	visible = false
	set_process(true)


# --- the build (once, when the day first comes) ----------------------------------------------

func _build() -> void:
	_built = true
	var t0 := Time.get_ticks_msec()
	_build_crowd()
	_build_barriers()
	if smoke_on:
		_build_glow()
	_build_bands()
	if traffic != null:
		traffic.keep_out = func(p: Vector2) -> bool: return on and in_zone(p)
	if trams != null:
		trams.keep_out = func(p: Vector2) -> bool: return on and in_zone(p)
	if log_on:
		print("event day: built in %d ms: %d people, %d flags, %d glow pots, bands %s (%d quads)" % [Time.get_ticks_msec() - t0,
				_slots.size(), _flag_n, _pot_pos.size(), str(_bands_ok), _band_quads])


func _ground(p: Vector2) -> float:
	return map.ground_height(p.x, p.y) if map != null else 0.0


## Roads of the zone: [{a, b, w}] segments of Al. Jerozolimskie, Marszałkowska and the rondo's ring.
func _zone_segments() -> Array:
	var segs: Array = []
	for r: Dictionary in _data.get("roads", []):
		var nm := str(r.get("name", ""))
		if not (nm == "Aleje Jerozolimskie" or nm == "Marszałkowska" or nm.begins_with("Rondo Romana")):
			continue
		if bool(r.get("bridge", false)):
			continue
		var flat: Array = r["p"]
		var w := float(r.get("w", 8.0))
		for i in range(0, flat.size() - 3, 2):
			var a := Vector2(flat[i], flat[i + 1])
			var b := Vector2(flat[i + 2], flat[i + 3])
			if in_zone(a, 4.0) or in_zone(b, 4.0):
				segs.append({"a": a, "b": b, "w": w})
	return segs


func _build_crowd() -> void:
	var segs := _zone_segments()
	var weights := PackedFloat32Array()
	var total := 0.0
	for s: Dictionary in segs:
		var a: Vector2 = s["a"]
		var b: Vector2 = s["b"]
		var mid := (a + b) * 0.5
		var near := clampf(1.0 - (mid - C).length() / 260.0, 0.0, 1.0)
		var far := clampf(to_vu(mid).x / V_EAST, 0.0, 1.0)
		total += a.distance_to(b) * (0.35 + 4.0 * near * near + 0.6 * (1.0 - far))
		weights.append(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1111
	var east := Vector2(V.x, V.y)
	if segs.is_empty() or total <= 0.0:
		print("event day: no roads of the zone in the data: no crowd")
	var tries := 0
	while _slots.size() < CROWD_MAX and tries < CROWD_MAX * 4 and total > 0.0:
		tries += 1
		var k := mini(weights.bsearch(rng.randf() * total), segs.size() - 1)
		var s: Dictionary = segs[k]
		var a: Vector2 = s["a"]
		var b: Vector2 = s["b"]
		var along := (b - a).normalized()
		var side := Vector2(-along.y, along.x)
		var half := float(s["w"]) * 0.5 + ROAD_PAD
		var p := a.lerp(b, rng.randf()) + side * rng.randf_range(-half, half)
		if not in_zone(p, 1.0):
			continue
		# A knot of people round the spot (3-9 of them), the way a crowd stands.
		var knot := rng.randi_range(3, 9)
		for j in knot:
			if _slots.size() >= CROWD_MAX:
				break
			var q := p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 2.6)
			if not in_zone(q, 1.0):
				continue
			var y := _ground(q)
			var face := east.rotated(rng.randf_range(-0.7, 0.7)) if rng.randf() < 0.85 else Vector2.from_angle(rng.randf() * TAU)
			var kid := rng.randf() < 0.1
			_slots.append({"p": Vector3(q.x, y, q.y), "yaw": atan2(-face.x, -face.y),
					"shirt": (WHITE if rng.randf() < 0.5 else RED) if kid else SHIRTS[rng.randi() % SHIRTS.size()],
					"flag": kid or rng.randf() < FLAG_SHARE, "big": rng.randf() < BIG_FLAG_SHARE, "banner": rng.randf() < BANNER_SHARE,
					"s": 0.8 if kid else rng.randf_range(1.12, 1.3), "ph": rng.randf() * TAU})
	var cap := _slots.size()
	var mat := Models.material().duplicate() as ShaderMaterial
	mat.set_shader_parameter("walk", 0.0)
	_crowd_mm = _new_mm(Models.person_mesh(), cap)
	_crowd_mmi = _new_mmi(_crowd_mm, "EventCrowd", mat)
	var buf := PackedFloat32Array()
	buf.resize(maxi(cap, 1) * 16)
	var flags_cap := 0
	for s: Dictionary in _slots:
		if bool(s["flag"]):
			flags_cap += 1
	_flag_mm = _new_mm(flag_mesh(), maxi(flags_cap, 1))
	_flag_mmi = _new_mmi(_flag_mm, "EventFlags", Models.material())
	var fbuf := PackedFloat32Array()
	fbuf.resize(maxi(flags_cap, 1) * 16)
	var fi := 0
	var box := AABB()
	for i in cap:
		var s: Dictionary = _slots[i]
		var p: Vector3 = s["p"]
		var sc := float(s["s"])
		CityLife.put(buf, i, p, float(s["yaw"]), Vector3(sc, sc, sc), s["shirt"], 0.0)
		if bool(s["flag"]):
			var yaw := float(s["yaw"])
			var right := Vector3(cos(yaw), 0.0, -sin(yaw))
			var fsc := 1.7 if not bool(s["big"]) else 3.2
			var fv := Vector3(fsc, fsc, fsc)
			if bool(s["banner"]):
				fv = Vector3(6.0, 2.4, 2.0)
			# The flag rides on a raised arm: next to the head, a little behind.
			var fp := p + right * 0.28 * sc
			CityLife.put(fbuf, fi, fp, yaw + sin(float(s["ph"])) * 0.35, fv * sc, Color.WHITE, 0.0)
			fi += 1
		box = AABB(p, Vector3.ZERO) if i == 0 else box.expand(p)
	_flag_n = fi
	_crowd_buf = buf
	_flag_buf = fbuf
	_crowd_aabb = box.grow(4.0).expand(box.end + Vector3(0, 10.0, 0))
	_crowd_mm.visible_instance_count = 0
	_flag_mm.visible_instance_count = 0


## A flag on a pole, 2.3 m: white over red, the cloth 0.95 × 0.6 m, hanging to +x. Vertex colours
## (Models.FIXED), so the instance colour does not repaint it.
static func flag_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Models.box(st, Vector3(0, 1.15, 0), Vector3(0.04, 2.3, 0.04), POLE, Models.FIXED)
	Models.box(st, Vector3(0.5, 2.0, 0), Vector3(0.95, 0.3, 0.03), WHITE, Models.FIXED)
	Models.box(st, Vector3(0.5, 1.7, 0), Vector3(0.95, 0.3, 0.03), RED, Models.FIXED)
	return st.commit()


func _new_mm(mesh: Mesh, cap: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = mesh
	mm.instance_count = cap
	return mm


func _new_mmi(mm: MultiMesh, n: String, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = n
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mmi.ignore_occlusion_culling = true
	add_child(mmi)
	return mmi


# --- the barriers ------------------------------------------------------------------------------

func _build_barriers() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_bodies = StaticBody3D.new()
	_bodies.name = "EventBarriers"
	add_child(_bodies)
	for c: Dictionary in cordon():
		var at: Vector2 = c["at"]
		var line: Vector2 = c["line"]
		var out: Vector2 = c["out"]
		var yaw := atan2(-line.y, line.x)  # the box's x along the line: (cos, 0, -sin) = (line.x, 0, line.y)
		var van_yaw := atan2(-out.y, out.x)
		var g := _ground(at)
		var half := CORRIDOR if str(c["id"]) in ["west", "east"] else CORRIDOR
		# A box collider across the road, car height, a metre thick.
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(half * 2.0, 3.0, 1.0)
		cs.shape = bx
		cs.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(at.x, g + 1.5, at.y))
		_bodies.add_child(cs)
		# The barriers: 2.5 m panels, each a frame of two posts, a top rail, two bars and feet.
		var n := int(half * 2.0 / 2.5)
		for i in n:
			var s := -half + 1.25 + i * 2.5
			var p := at + line * s
			var py := _ground(p)
			_panel(st, Vector3(p.x, py, p.y), yaw, i)
		# Tape across, a double white-red line at 1.15 m, and a few cones behind.
		for i in int(half * 2.0 / 1.0):
			var s := -half + 0.5 + i
			var p := at + line * s
			var py := _ground(p)
			var col := RED if i % 2 == 0 else WHITE
			_oriented_box(st, Vector3(p.x, py + 1.18, p.y), Vector3(1.0, 0.14, 0.05), yaw, col)
		# The police van behind the line, nose to the crowd's side, its blue light on the roof.
		var vp := at - out * 6.5 + line * (half * 0.45)
		_van(st, Vector3(vp.x, _ground(vp), vp.y), van_yaw + 0.22)
		var vp2 := at - out * 6.5 - line * (half * 0.45)
		_van(st, Vector3(vp2.x, _ground(vp2), vp2.y), van_yaw - 0.22)
	_static = MeshInstance3D.new()
	_static.name = "EventBarrierMesh"
	_static.mesh = st.commit()
	_static.material_override = Models.material()
	_static.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_static.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_static)


## One crowd barrier at the origin `at` (y up), its length along the line's direction `yaw`.
func _panel(st: SurfaceTool, at: Vector3, yaw: float, i: int) -> void:
	var along := Vector3(cos(yaw), 0.0, -sin(yaw))
	var across := Vector3(sin(yaw), 0.0, cos(yaw))
	for sgn in [-1.0, 1.0]:
		var p: Vector3 = at + along * 1.15 * sgn
		_oriented_box(st, p + Vector3(0, 0.55, 0), Vector3(0.09, 1.1, 0.09), yaw, STEEL)
		# A foot, across the line.
		_oriented_box(st, p + Vector3(0, 0.03, 0), Vector3(0.05, 0.06, 0.7), yaw, STEEL_DARK)
	_oriented_box(st, at + Vector3(0, 1.08, 0), Vector3(2.4, 0.1, 0.1), yaw, STEEL)
	for h in [0.3, 0.55, 0.8]:
		_oriented_box(st, at + Vector3(0, h, 0), Vector3(2.4, 0.07, 0.07), yaw, STEEL)
	# A panel of vertical bars, every second one a sign board (plain grey: no words).
	if i % 2 == 1:
		_oriented_box(st, at + Vector3(0, 0.62, 0) + across * 0.05, Vector3(2.2, 0.8, 0.04), yaw, Color("#c9ced3"))


func _oriented_box(st: SurfaceTool, centre: Vector3, size: Vector3, yaw: float, col: Color) -> void:
	# The box's x along `yaw`'s line direction (cos, -sin), its z across it.
	var b := Basis(Vector3.UP, yaw)
	var h := size * 0.5
	var faces := [
		[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
		[Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)]]
	for f: Array in faces:
		for sgn in [-1.0, 1.0]:
			var n: Vector3 = b * (f[0] as Vector3) * sgn
			var u: Vector3 = b * (f[1] as Vector3)
			var w: Vector3 = b * (f[2] as Vector3)
			var hu := absf((f[1] as Vector3).dot(h))
			var hw := absf((f[2] as Vector3).dot(h))
			var hn := absf((f[0] as Vector3).dot(h))
			var o := centre + n * hn
			var q := [o - u * hu - w * hw, o + u * hu - w * hw, o + u * hu + w * hw, o - u * hu + w * hw]
			if (q[1] - q[0]).cross(q[2] - q[0]).dot(n) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(col)
				st.set_normal(n)
				st.set_uv(Vector2(Models.FIXED, 0.0))
				st.add_vertex(q[idx])


## A police van, 5.2 × 2.0 × 2.3 m, its length along `yaw`'s direction: white body, a blue stripe,
## dark windows, a blue light bar on the roof (LIT_SIGN: lit while the city's lights are).
func _van(st: SurfaceTool, at: Vector3, yaw: float) -> void:
	var fwd := Vector3(cos(yaw), 0.0, -sin(yaw))
	var side := Vector3(sin(yaw), 0.0, cos(yaw))
	_oriented_box(st, at + Vector3(0, 1.15, 0), Vector3(5.0, 1.9, 2.0), yaw, VAN_BODY)
	_oriented_box(st, at + Vector3(0, 0.55, 0), Vector3(5.04, 0.5, 2.04), yaw, STEEL_DARK)
	for sgn in [-1.0, 1.0]:
		_oriented_box(st, at + Vector3(0, 1.25, 0) + side * 1.01 * sgn, Vector3(5.02, 0.22, 0.02), yaw, VAN_STRIPE)
		_oriented_box(st, at + Vector3(0, 1.85, 0) + side * 1.01 * sgn + fwd * 1.1, Vector3(1.6, 0.55, 0.02), yaw, GLASS)
	_oriented_box(st, at + Vector3(0, 1.85, 0) + fwd * 2.51, Vector3(0.02, 0.6, 1.7), yaw, GLASS)
	# The light bar.
	for sgn in [-1.0, 1.0]:
		var p: Vector3 = at + Vector3(0, 2.2, 0) + side * 0.5 * sgn + fwd * 0.9
		_oriented_box_lit(st, p, Vector3(0.5, 0.14, 0.3), yaw, BLUE_LIGHT if sgn < 0.0 else Color("#ff5a4a"))


func _oriented_box_lit(st: SurfaceTool, centre: Vector3, size: Vector3, yaw: float, col: Color) -> void:
	# The same box with the lit sign part.
	var b := Basis(Vector3.UP, yaw)
	var h := size * 0.5
	for ax in 3:
		for sgn in [-1.0, 1.0]:
			var nl := Vector3.ZERO
			nl[ax] = sgn
			var ul := Vector3.ZERO
			ul[(ax + 1) % 3] = 1.0
			var wl := Vector3.ZERO
			wl[(ax + 2) % 3] = 1.0
			var n: Vector3 = b * nl
			var u: Vector3 = b * ul
			var w: Vector3 = b * wl
			var o := centre + n * absf(nl.dot(h))
			var hu := absf(ul.dot(h))
			var hw := absf(wl.dot(h))
			var q := [o - u * hu - w * hw, o + u * hu - w * hw, o + u * hu + w * hw, o - u * hu + w * hw]
			if (q[1] - q[0]).cross(q[2] - q[0]).dot(n) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(col)
				st.set_normal(n)
				st.set_uv(Vector2(Models.LIT_SIGN, 0.0))
				st.add_vertex(q[idx])


# --- the glow pots, the haze and the puffs ----------------------------------------------------

func _build_glow() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var pts: Array[Vector3] = []
	var n := mini(POTS, _slots.size())
	for i in n:
		var s: Dictionary = _slots[rng.randi() % _slots.size()]
		var p: Vector3 = s["p"]
		pts.append(p + Vector3(rng.randf_range(-1.0, 1.0), 1.7, rng.randf_range(-1.0, 1.0)))
	_pot_pos = pts
	# The pots: small bright red-orange halos.
	var pm := MultiMesh.new()
	pm.transform_format = MultiMesh.TRANSFORM_3D
	pm.mesh = Props.halo(13.0, Color(1.0, 0.22, 0.14, 0.95))
	pm.instance_count = pts.size()
	for i in pts.size():
		pm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pts[i]))
	_pots_mmi = MultiMeshInstance3D.new()
	_pots_mmi.name = "EventPots"
	_pots_mmi.multimesh = pm
	_pots_mmi.material_override = Props.glow_material(true, 0.5)
	_pots_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pots_mmi)
	# The haze: big soft pink-red blobs at lamp-post height over the crowd.
	var hm := MultiMesh.new()
	hm.transform_format = MultiMesh.TRANSFORM_3D
	hm.mesh = Props.halo(36.0, Color(1.0, 0.36, 0.34, 0.2))
	hm.instance_count = HAZE
	for i in HAZE:
		var s: Dictionary = _slots[rng.randi() % maxi(_slots.size(), 1)] if not _slots.is_empty() else {"p": Vector3(C.x, 0, C.y)}
		var p: Vector3 = s["p"]
		hm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p + Vector3(0, rng.randf_range(HAZE_Y.x, HAZE_Y.y), 0)))
	_haze_mmi = MultiMeshInstance3D.new()
	_haze_mmi.name = "EventHaze"
	_haze_mmi.multimesh = hm
	_haze_mmi.material_override = Props.glow_material(true, 0.0)
	_haze_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_haze_mmi)
	# The standing fog: soft blobs, grey-pink by day, lit red from inside at night.
	var fm := MultiMesh.new()
	fm.transform_format = MultiMesh.TRANSFORM_3D
	fm.mesh = Props.halo(1.0, Color.WHITE)
	fm.instance_count = FOG
	for i in FOG:
		var fs: Dictionary = _slots[rng.randi() % maxi(_slots.size(), 1)] if not _slots.is_empty() else {"p": Vector3(C.x, 0, C.y)}
		var fp: Vector3 = fs["p"]
		var fz := rng.randf_range(FOG_SIZE.x, FOG_SIZE.y)
		fm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(fz, fz * 0.7, fz)), fp + Vector3(rng.randf_range(-6, 6), rng.randf_range(FOG_Y.x, FOG_Y.y), rng.randf_range(-6, 6))))
	fm.custom_aabb = AABB(Vector3(C.x - 900.0, -20.0, C.y - 600.0), Vector3(1800.0, 120.0, 1200.0))
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = load("res://shaders/event_fog.gdshader")
	_fog_mat.render_priority = 1
	_fog_mmi = MultiMeshInstance3D.new()
	_fog_mmi.name = "EventFog"
	_fog_mmi.multimesh = fm
	_fog_mmi.material_override = _fog_mat
	_fog_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fog_mmi)
	# The puffs: fans.gd's smoke clump, rising from the pots, pink fading to grey.
	_puff_mm = _new_mm(Fans.puff_mesh(), PUFFS)
	_puff_mmi = _new_mmi(_puff_mm, "EventPuffs", Models.material())
	_puff_buf.resize(PUFFS * 16)
	_puff_buf.fill(0.0)
	_puff_mm.visible_instance_count = 0


## A puff's pose `age` (0..1) of its life above pot `k`: [position, size, colour].
func _puff(k: int, j: int, age: float) -> Array:
	var pot := _pot_pos[k % _pot_pos.size()]
	var wind := Vector3(0.9, 0.0, 0.4)
	var rise := 1.0 + age * 24.0
	var sz := lerpf(0.9, 3.0, age)
	var jx := sin(float(k * 7 + j) * 1.7) * 0.9
	var jz := cos(float(k * 5 + j) * 2.3) * 0.9
	var pos := pot + Vector3(jx, 0.0, jz) + wind * (age * 9.0) + Vector3(0, rise, 0)
	var col := Color("#ff6a7a").lerp(Color("#e9d6d6"), clampf(age * 1.4, 0.0, 1.0))
	return [pos, sz, col]


# --- the light bands -------------------------------------------------------------------------

func _build_bands() -> void:
	_bands_tries += 1
	if map == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 0
	n += _tower_bands(st, PALACE_AT, PALACE_LEVELS, 13.0, 1.6)
	n += _tower_gradient(st, ZLOTA_AT, 11.0, 0.7)
	n += _stadium_bands(st)
	if n == 0:
		return
	_band_quads = n
	_bands_ok = true
	_bands = MeshInstance3D.new()
	_bands.name = "EventBands"
	_bands.mesh = st.commit()
	_bands.material_override = Models.material()
	_bands.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bands.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_bands.visible = false
	add_child(_bands)


## Bands round a tower at the `levels` (share of its height over the ground, colour 0 red / 1
## white), each from crowds.gd's roof_ring at that height. Returns the quads added.
func _tower_bands(st: SurfaceTool, at: Vector2, levels: Array, band_h: float, out: float) -> int:
	var ground := _ground(at)
	var top: float = map.roof_height(at.x, at.y)
	if top - ground < 50.0:
		if log_on:
			print("event day: no tall roof at %s (%.0f m)" % [str(at), top - ground])
		return 0
	var roof := func(x: float, z: float) -> float: return map.roof_height(x, z)
	var count := 0
	for lv: Array in levels:
		var y1: float = ground + (top - ground) * float(lv[0])
		var ring := Crowds.roof_ring(at, y1 + 4.0, roof, RING_RAYS)
		if ring.size() < RING_RAYS / 2:
			continue
		var col := WHITE if int(lv[1]) == 1 else RED
		var pts: Array[Vector2] = []
		for k in ring.size():
			var d := 0.0
			for o in range(-1, 2):
				d += ((ring[(k + o + ring.size()) % ring.size()][0] as Vector2) - at).length()
			pts.append(at + (ring[k][1] as Vector2) * (d / 3.0 + out))
		for k in ring.size():
			var a: Vector2 = pts[k]
			var b: Vector2 = pts[(k + 1) % ring.size()]
			if a.distance_to(b) > 40.0:
				continue
			var n2 := Vector2((b - a).y, -(b - a).x).normalized()
			if n2.dot(ring[k][1] as Vector2) < 0.0:
				n2 = -n2
			var nrm := Vector3(n2.x, 0.0, n2.y)
			var q := [Vector3(a.x, y1 - band_h, a.y), Vector3(b.x, y1 - band_h, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y)]
			if (q[1] - q[0]).cross(q[2] - q[0]).dot(nrm) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(col)
				st.set_normal(nrm)
				st.set_uv(Vector2(Models.LIT_SIGN, 0.0))
				st.add_vertex(q[idx])
			count += 1
	return count


## Złota 44 as in F's photo: the whole shaft in contiguous bands (`band_h` m), the colour by the
## side: white on the north-west, through pink, to red on the south-east.
func _tower_gradient(st: SurfaceTool, at: Vector2, band_h: float, out: float) -> int:
	var ground := _ground(at)
	var top: float = map.roof_height(at.x, at.y)
	if top - ground < 50.0:
		if log_on:
			print("event day: no tall roof at %s (%.0f m)" % [str(at), top - ground])
		return 0
	var roof := func(x: float, z: float) -> float: return map.roof_height(x, z)
	var count := 0
	var y1 := ground + band_h * 2.0
	while y1 < top - 2.0:
		var ring := Crowds.roof_ring(at, y1 + 4.0, roof, RING_RAYS)
		if ring.size() >= RING_RAYS / 2:
			var pts: Array[Vector2] = []
			for k in ring.size():
				var d := 0.0
				for o in range(-1, 2):
					d += ((ring[(k + o + ring.size()) % ring.size()][0] as Vector2) - at).length()
				pts.append(at + (ring[k][1] as Vector2) * (d / 3.0 + out))
			for k in ring.size():
				var a: Vector2 = pts[k]
				var b: Vector2 = pts[(k + 1) % ring.size()]
				if a.distance_to(b) > 40.0:
					continue
				var dir: Vector2 = ring[k][1]
				var low := clampf(1.0 - (y1 - ground) / maxf(top - ground, 1.0) * 2.2, 0.0, 0.5)
				var t := smoothstep(-0.9, 0.7, dir.x) * (1.0 - low)
				var col := WHITE.lerp(RED, t)
				count += _quad(st, a, b, y1 - band_h, y1, dir, col)
		y1 += band_h
	return count


## Stadion Narodowy: alternating white and red panels round the bowl at 10-30 m (the skin's own
## red-and-white weave stays under them), from the mapped masts like landmarks.gd `_find_stadium`.
func _stadium_bands(st: SurfaceTool) -> int:
	var inner: Array[Vector2] = []
	var outer: Array[Vector2] = []
	var area := Rect2(1250, -820, 450, 450)
	for bld: Dictionary in _data.get("buildings", []):
		var flat: Array = bld["p"]
		if flat.size() < 6:
			continue
		var c := Vector2.ZERO
		for i in range(0, flat.size() - 1, 2):
			c += Vector2(flat[i], flat[i + 1])
		c /= float(flat.size() / 2)
		if not area.has_point(c):
			continue
		if absf(float(bld["h"]) - 50.0) < 0.5 and float(bld["mh"]) < 0.5:
			inner.append(c)
		elif absf(float(bld["h"]) - 60.0) < 0.5 and absf(float(bld["mh"]) - 44.0) < 0.5:
			outer.append(c)
	if inner.size() < 24 or outer.size() < 24:
		return 0
	var centre := Vector2.ZERO
	for v in inner:
		centre += v
	centre /= inner.size()
	outer.sort_custom(func(a: Vector2, b: Vector2) -> bool: return (a - centre).angle() < (b - centre).angle())
	var count := 0
	for k in outer.size():
		var a := centre + (outer[k] - centre) * 1.05
		var b := centre + (outer[(k + 1) % outer.size()] - centre) * 1.05
		var dir := ((a + b) * 0.5 - centre).normalized()
		# From the ground by the mast (the bowl sits in an embankment; the skin rises from its crest
		# to the roof's rim at about 44 m): two rows of panels, red and white alternating.
		var g := _ground(outer[k])
		for row in 2:
			var col := RED if (k + row) % 2 == 0 else WHITE
			count += _quad(st, a, b, g + 15.0 + row * 12.0, g + 26.0 + row * 12.0, dir, col)
	return count


## One lit quad between two game-plane points, from y0 to y1, facing `out`.
func _quad(st: SurfaceTool, a: Vector2, b: Vector2, y0: float, y1: float, out: Vector2, col: Color) -> int:
	var n2 := Vector2((b - a).y, -(b - a).x).normalized()
	if n2.dot(out) < 0.0:
		n2 = -n2
	var nrm := Vector3(n2.x, 0.0, n2.y)
	var q := [Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y)]
	if (q[1] - q[0]).cross(q[2] - q[0]).dot(nrm) > 0.0:
		q = [q[0], q[3], q[2], q[1]]
	for idx in [0, 1, 2, 0, 2, 3]:
		st.set_color(col)
		st.set_normal(nrm)
		st.set_uv(Vector2(Models.LIT_SIGN, 0.0))
		st.add_vertex(q[idx])
	return 1


# --- the running day -------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0:
		return
	_t += dt
	_tick -= dt
	if _tick <= 0.0:
		_tick = 0.5
		_update()
	if on and _puff_mmi != null and _puff_mmi.visible:
		_move_puffs()
	if log_on and on:
		_dbg -= dt
		if _dbg <= 0.0:
			_dbg = 5.0
			print("event day: ", summary(), " · aabb ", _crowd_mm.custom_aabb if _crowd_mm != null else "-")


func _update() -> void:
	var was := on
	on = active()
	if on and not _built:
		_build()
	if not _built:
		return
	if clock.is_valid():
		_hours = float((clock.call() as Dictionary).get("hour", 12.0))
	share = 1.0 if force else crowd_share(_hours)
	var show_all := on
	visible = show_all
	if not show_all:
		if was:
			_crowd_mm.visible_instance_count = 0
		return
	var tier := clampf(amount, 0.25, 1.0)
	var n := int(_slots.size() * share * tier)
	# The count first, then the whole buffer (fans.gd's order: the renderer takes the instances up to
	# the visible count), only when the count changes.
	if n != _shown or _resend > 0:
		_resend = maxi(_resend - 1, 0)
		_shown = n
		_crowd_mm.visible_instance_count = n
		InstanceBuffers.send(_crowd_mm.get_rid(), _crowd_buf)
		_crowd_mm.custom_aabb = _crowd_aabb
	_crowd_mmi.visible = n > 0
	var fn := mini(int(_flag_n * share * tier), _flag_n)
	if fn != _flags_shown or _resend > 0:
		_flags_shown = fn
		_flag_mm.visible_instance_count = fn
		if _flag_n > 0:
			InstanceBuffers.send(_flag_mm.get_rid(), _flag_buf)
		_flag_mm.custom_aabb = _crowd_aabb
	_flag_mmi.visible = fn > 0
	# Barriers all day (they go up before the crowd gathers), glow and haze from the afternoon.
	var dusk := force or (_hours >= 14.5 and _hours <= 22.0)
	var smoky := smoke_on and dusk and share > 0.3
	if _pots_mmi != null:
		_pots_mmi.visible = smoky
		_haze_mmi.visible = smoky
		_puff_mmi.visible = smoky and PUFFS_ON
		if smoky and _puff_mm.visible_instance_count == 0:
			_puff_mm.visible_instance_count = PUFFS
	if _fog_mmi != null:
		var in_dark := lit.is_valid() and bool(lit.call())
		_fog_mmi.visible = smoke_on and share > 0.3
		_fog_mmi.multimesh.visible_instance_count = int(FOG * tier)
		_fog_mat.set_shader_parameter("glow", 1.0 if in_dark else 0.0)
		_fog_mat.set_shader_parameter("density", 0.085 if in_dark else 0.06)
	if _bands != null:
		var dark := lit.is_valid() and bool(lit.call())
		_bands.visible = dark and _hours >= 14.0 or (force and dark)
	elif _bands_tries < 12 and int(_t) % 3 == 0:
		_build_bands()
	_keep_player_out()


func _move_puffs() -> void:
	if _pot_pos.is_empty():
		return
	var f := Vector3.ZERO
	if focus.is_valid():
		f = focus.call()
	if Vector2(f.x, f.z).distance_to(C) > 900.0:
		return
	var box := AABB()
	var first := true
	for i in PUFFS:
		var k := i % _pot_pos.size()
		var j := i / _pot_pos.size()
		var age := fposmod(_t / PUFF_LIFE + float(i) * 0.137, 1.0)
		var pf := _puff(k, j, age)
		var p: Vector3 = pf[0]
		var sz: float = pf[1]
		CityLife.put(_puff_buf, i, p, float(i) * 0.7 + _t * 0.1, Vector3(sz, sz * 0.8, sz), pf[2], 0.0)
		box = AABB(p, Vector3.ZERO) if first else box.expand(p)
		first = false
	InstanceBuffers.send(_puff_mm.get_rid(), _puff_buf)
	_puff_mm.custom_aabb = box.grow(14.0)


## The car is never in the zone: one that got in (the event began under it, or a side street led
## in) is set down outside the nearest barrier, with a toast.
func _keep_player_out() -> void:
	if not vehicle.is_valid() or not kick.is_valid():
		return
	var v: Array = vehicle.call()
	if bool(v[2]):
		return
	var pos: Vector3 = v[0]
	var p := Vector2(pos.x, pos.z)
	if not in_zone(p, KICK_DEPTH):
		return
	var best := {}
	var best_d := INF
	for c: Dictionary in cordon():
		var at: Vector2 = c["at"]
		var d := p.distance_to(at)
		if d < best_d:
			best_d = d
			best = c
	var out: Vector2 = best["out"]
	var line: Vector2 = best["line"]
	var at2: Vector2 = best["at"]
	var along := clampf((p - at2).dot(line), -CORRIDOR * 0.5, CORRIDOR * 0.5)
	var spot := at2 + line * along + out * 9.0
	var yaw := atan2(-out.x, -out.y)
	_kicks += 1
	kick.call(Vector3(spot.x, _ground(spot), spot.y), yaw)


## A one-line summary for --event-log.
func summary() -> String:
	return "%s · %02d:%02d · crowd %d/%d (%d flags) · barriers %s · smoke %s · bands %s · kicks %d" % [
			"ON" if on else "off", int(_hours), int(fmod(_hours, 1.0) * 60.0), _crowd_mm.visible_instance_count if _crowd_mm != null else 0,
			_slots.size(), _flag_n, "up" if on else "-", "on" if (smoke_on and _puff_mmi != null and _puff_mmi.visible) else "off",
			"lit" if (_bands != null and _bands.visible) else "off", _kicks]
